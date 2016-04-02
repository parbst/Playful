# This is the driver module for the 'file' program telling basic information about a file
#
# It is built around the information we want, because file is so incredibly huge. Incorporating
# the library would be including a lot of not very interesting stuff.
require 'playful/file'

module Playful
  module File
    module Driver

      class FileDriver
        def initialize(conf)
          unless conf.class == Hash && conf.has_key?(:path) && ::File.exists?(conf[:path])
            raise DriverError.new 'Did not receive path to binary or file not present'
          end

          @path = conf[:path]
        end

        def scan_file(filepath)
          unless ::File.file?(filepath)
            raise DriverError.new "File #{filepath} is not a file"
          end

          fp = ::File.expand_path filepath
          exp_cmd = "\"#{@path}\" \"#{fp}\" 2>&1"
          start_time = Time.new
          output = `#{exp_cmd}`

          m = output.gsub(fp, '').match /. (.*)/
          unless m
            raise DriverError.new 'Could not parse output string'
          end

          file_scans = [create_scan_result(filepath, m[1])]
          create_result(file_scans, start_time)
        end

        def scan_files(file_paths)
          # make sure to chunk out commands so they don't exceed the max limit
          file_lists = chunk_file_list(file_paths)
          file_scans = []

          start_time = Time.new
          file_lists.each do |file_list|
            exp_cmd = "\"#{@path}\" #{file_list} 2>&1"
            begin
              output = `#{exp_cmd.encode("utf-8")}`
            rescue ArgumentError
              raise
            end
            file_scans.concat parse_output(output)
          end

          create_result(file_scans, start_time)
        end

        # use directory wild card to scan all files in a dir
        def scan_dir(dir_path)
          unless ::File.directory?(dir_path)
            raise DriverError.new "Directory #{dir_path} is not a directory"
          end
          fp = ::File.expand_path(dir_path)
          exp_cmd = "\"#{@path}\" \"#{::File.join(fp, '*')}\" 2>&1"
          start_time = Time.new
          output = `#{exp_cmd}`

          file_scans = parse_output(output)
          create_result(file_scans, start_time)
        end

        private

        def create_scan_result(filepath, raw)
          {}.tap do |o|
            o[:raw] = raw.strip
            o[:path] = filepath
            o[:extension] = filepath.split('.').last
            o.merge! annotate_result(o[:raw])
          end
        end

        def create_result(file_scans, start_time)
          {
            :files      => file_scans,
            :scan_time  => Time.new - start_time
          }
        end

        def parse_output(output)
          result = []
          output.split("\n").each do |s|
            sep = /#{::File::PATH_SEPARATOR} /
            if s.scan(sep).size > 1
              chunks = s.split(sep)
              # unambiguous separation. determine if file exists
              filename = chunks[0]
              i = 1
              while !::File.exists?(filename) || i < chunks.length - 1 do
                filename += "#{::File::PATH_SEPARATOR} " + chunks[i]
                i += 1
              end
              raw = chunks[i..chunks.length - 1].join("#{::File::PATH_SEPARATOR} ")
            else
              filename, raw = *s.split(sep)
            end
            result.push create_scan_result(filename, raw)
          end

          result
        end

        def annotate_result(raw)
          cutouts = split_raw(raw)

          result = strip_id3(cutouts)

          ########################################################################
          # Special cases
          ########################################################################
          # directory
          result[:directory] = false
          if cutouts[0] == 'directory'
            result[:directory] = true
          end

          # empty
          if cutouts[0] == 'empty'
            result[:empty] = true
          end

          # cannot open `X:/Malk De Koijn/Smash Hit In Aberdeen [CD]/Malk De Koijn - 02 - ├? ├?├Ñ M├ªio.mp3' (No such file or direct#ory)
          if raw =~ /^cannot open/
            result[:failed] = raw
          end

          ########################################################################
          # Audio
          ########################################################################
          case cutouts[0]
            when 'MPEG ADTS'
              if cutouts[1] == 'layer I'

            # MPEG ADTS, layer II, v1, 128 kbps, 44.1 kHz, Stereo
              elsif cutouts[1] == 'layer II'
                result[:format] = Playful::File::FILE_FORMAT_MPEG_LAYER_2
                result[:format_version] = cutouts[2]

                if cutouts[3] =~ /(\d+) kbps/
                  result[:kbps] = $1
                end

                result[:sample_rate] = cutouts[4] if cutouts[4]
                result[:channels] = cutouts[5] if cutouts[5]

            # MPEG ADTS, layer III, v1,  64 kbps, 44.1 kHz, Stereo
              elsif cutouts[1] == 'layer III'
                result[:format] = Playful::File::FILE_FORMAT_MPEG_LAYER_3
                result[:format_version] = cutouts[2]

                if cutouts[3] =~ /(\d+) kbps/
                  result[:kbps] = $1
                end

                result[:sample_rate] = cutouts[4] if cutouts[4]
                result[:channels] = cutouts[5] if cutouts[5]
              end
            when 'Musepack audio'
              # Musepack audio, SV 7.0, quality 7 (Insane), Beta 1.14
              result[:format] = Playful::File::FILE_FORMAT_MUSEPACK
              result[:format_version] = "#{cutouts[3]} (#{cutouts[1]})"
              result[:quality] = cutouts[2].gsub('quality', '')
            when 'FLAC audio bitstream data'
              # FLAC audio bitstream data, 16 bit, stereo, 44.1 kHz, 10330572 samples
              result[:format] = Playful::File::FILE_FORMAT_FLAC
              result[:sample_rate] = cutouts[3] if cutouts[3]
              result[:samples] = cutouts[4] if cutouts[4]
              result[:precision] = cutouts[1] if cutouts[1]
            when 'Ogg data'
              # Ogg data, Vorbis audio, stereo, 44100 Hz, ~128003 bps, created by: Xiph.Org libVorbis I (1.0)
              if cutouts[1] == 'Vorbis audio'
                result[:format] = Playful::File::FILE_FORMAT_VORBIS
                result[:sample_rate] = cutouts[3] if cutouts[3]
                result[:channels] = cutouts[2] if cutouts[2]
              end
              # Ogg data, Theora video
              if cutouts[1] == 'Theora video'
                result[:format] = Playful::File::FILE_FORMAT_THEORA
              end
            when 'Microsoft ASF'
              # Microsoft ASF
              result[:format] = Playful::File::FILE_FORMAT_MS_ASF
            when 'ISO Media'
              # ISO Media, MPEG v4 system, version 1
              # ISO Media, MPEG v4 system, version 2
              # ISO Media, MPEG v4 system, iTunes AAC-LC
              # ISO Media, Apple QuickTime movie

              if cutouts[1] == 'MPEG v4 system' && cutouts[2] =~ /version\s(\d)*/i
                result[:version] = $1
              end
              result[:format] = Playful::File::FILE_FORMAT_MPEG4
            when 'RealMedia file'
              # RealMedia file
              result[:format] = Playful::File::FILE_FORMAT_REALMEDIA
          end

          # Monkey's Audio compressed format version 3960 with normal compression, stereo, sample rate 44100
          if cutouts[0] =~ /Monkey's Audio compressed format version (\d*) with (.*)/
            result[:format] = Playful::File::FILE_FORMAT_MONKEY
            result[:format_version] = $1
            result[:compression_rate] = cutouts[1]
            result[:sample_rate] = cutouts[2].gsub("sample rate ", '')
          end

          # Standard MIDI data (format 1) using 13 tracks at 1/120
          if cutouts[0] =~ /Standard MIDI data (.*) using (\d+) tracks at (.*)/
            result[:format] = Playful::File::FILE_FORMAT_MIDI
            result[:format_version] = $1
            result[:tracks] = $2
            result[:bpm] = $3
          end

          # RIFF (little-endian) data, WAVE audio, Microsoft PCM, 16 bit, stereo 22050 Hz
          # RIFF (little-endian) data, WAVE audio, MPEG Layer 3, stereo 44100 Hz
          if cutouts[0] =~ /RIFF (\(([^\)]+)\)\s*)?data/ && cutouts[1] == 'WAVE audio'
            result[:format] = Playful::File::FILE_FORMAT_WAVE

            if $2
              result[:endian] = $2
            end

            result[:compression] = cutouts[2] if cutouts[2]
            (3..cutouts.length-1).each do |i|
              if cutouts[i] =~ /^\d+ bits$/
                result[:precision] = cutouts[i]
              end

              if cutouts[i] =~ /(\w+) (\d+) Hz/
                result[:sample_rate] = "#{$2} Hz"
                result[:channels] = $1
              end
            end
          end

          # RIFF (little-endian) data, MPEG Layer 3 audio
          if cutouts[0] =~ /RIFF (\(([^\)]+)\)\s*)?data/ && cutouts[1] == 'MPEG Layer 3 audio'
            result[:format] = Playful::File::FILE_FORMAT_MP3
          end

          ########################################################################
          # Image
          ########################################################################
          case cutouts[0]
            # JPEG image data, EXIF standard 2.2, baseline, precision 0, 4360x1700", comment: \"LEAD Technologies Inc.V1.01\", thumbnail 16x16
            when 'JPEG image data'
              result[:format] = Playful::File::FILE_FORMAT_JPEG

              result[:baseline] = false
              (1..cutouts.length-1).each do |i|
                if cutouts[i] =~ /([^\s]*)\sstandard(\s(.*))?/
                  result[:standard] = $1
                  result[:standard_version] = $3
                end

                if cutouts[i] == "baseline"
                  result[:baseline] = true
                end

                if cutouts[i] =~ /precision\s(.*)/
                  result[:precision] = $1
                end

                if cutouts[i] =~ /(\d+)x(\d+)/
                  result[:height] = $1
                  result[:width] = $2
                end

                if cutouts[i] =~ /comment: (.*)/
                  result[:comment] = $1
                end
              end
            # GIF image data, version 87a, 217 x 436
            when 'GIF image data'
              result[:format] = Playful::File::FILE_FORMAT_GIF

              (1..cutouts.length-1).each do |i|
                if cutouts[i] =~ /version (.*)/
                  result[:format_version] = $1
                end

                if cutouts[i] =~ /(\d+) x (\d+)/
                  result[:height] = $1
                  result[:width] = $2
                end
              end
            # VISX image file
            when 'VISX image file'
              result[:format] = Playful::File::FILE_FORMAT_VISX
            # PC bitmap, Windows 3.x format, 1789 x 1391 x 24
            when 'PC bitmap'
              result[:format] = Playful::File::FILE_FORMAT_BITMAP
            # Adobe Photoshop Image
            when 'Adobe Photoshop Image'
              result[:format] = Playful::File::FILE_FORMAT_ADOBE_IMAGE
            # PNG image, 90 x 72, 8-bit/color RGBA, non-interlaced
            when 'PNG image'
              result[:format] = Playful::File::FILE_FORMAT_PNG
              result[:interlaced] = true

              (1..cutouts.length-1).each do |i|
                if cutouts[i] == 'non-interlaced'
                  result[:interlaced] = false
                end

                if cutouts[i] =~ /(\d+) x (\d+)/
                  result[:height] = $1
                  result[:width] = $2
                end
              end
          end

          # Targa image data - Mono - RLE 27000 x 24941
          if cutouts[0] =~ /Targa image data - (\w*) - RLE (\d*) x (\d*)/
            result[:format] = Playful::File::FILE_FORMAT_TARGA_IMAGE
            result[:color] = $1
            result[:height] = $2
            result[:width] = $3
          end

          # MS Windows icon resource - 2 icons, 32x32, 16-colors
          if cutouts[0] =~ /MS Windows icon/
            result[:format] = Playful::File::FILE_FORMAT_WIN_ICON
          end

          ########################################################################
          # Video
          ########################################################################

          case cutouts[0]
            # Matroska data
            when 'Matroska data'
              result[:format] = Playful::File::FILE_FORMAT_MATROSKA
            # Ogg data, OGM video (DivX 5)
            when 'Ogg data'
              if cutouts[1] =~ /OGM video( \((.*)\))?/
                result[:format] = Playful::File::FILE_FORMAT_OGM
                result[:video_codec] = $2 if $2
              end
            # Video title set, v11
            when 'Video title set'
              result[:format] = Playful::File::FILE_FORMAT_DVD_IFO
              if cutouts[1] =~ /v(\d+)/
                result[:format_version] = $1
              end
          end

          # Apple QuickTime movie (fast start)
          if cutouts[0] =~ /Apple QuickTime movie/
            result[:format] = Playful::File::FILE_FORMAT_QUICKTIME
          end

          # RIFF (little-endian) data, AVI, 640 x 480, 25.00 fps, video: XviD, audio: Dolby AC3 (stereo, 48000 Hz)
          # RIFF (little-endian) data, AVI, 640 x 368, 23.98 fps, video: XviD, audio: MPEG-1 Layer 3 (stereo, 48000 Hz)
          if cutouts[0] =~ /RIFF (\((.*)\) )?data/ && cutouts[1] == 'AVI'
            result[:format] = Playful::File::FILE_FORMAT_AVI
            (1..cutouts.length - 1).each do |i|
              if cutouts[i] =~ /video: (.*)/
                result[:video_codec] = $1
              elsif cutouts[i] =~ /([^\s]*) fps/
                result[:fps] = $1
              elsif cutouts[i] =~ /audio: ([^\(]+)(\(([^,]+), ([^\)]+)\))?/
                result[:audio_codec] = $1.strip
                if $3
                  result[:audio_channels] = $3
                  result[:audio_samplerate] = $4
                end
              elsif cutouts[i] =~ /(\d+)x(\d+)/
                result[:height] = $1
                result[:width] = $2
              end
            end
          end

          # RIFF (little-endian) data, wrapped MPEG-1 (CDXA)
          if cutouts[0] =~ /RIFF (\((.*)\) )?data/
            if cutouts[1] =~ /wrapped MPEG-(\d)( \((.*)\))?/
              result[:format] = Playful::File::FILE_FORMAT_MPEG1_VIDEO
              result[:format_version] = $1
            end
          end

          ########################################################################
          # Archive
          ########################################################################
          case cutouts[0]
            # MS Compress archive data
            when 'MS Compress archive data'
              result[:format] = Playful::File::FILE_FORMAT_MS_CPS
            # RAR archive data, v1d, os:Win32
            when 'RAR archive data'
              result[:format] = Playful::File::FILE_FORMAT_RAR
            # Zip archive data, at least v2.0 to extract
            when 'Zip archive data'
              result[:format] = Playful::File::FILE_FORMAT_ZIP
            # Microsoft Cabinet archive data, 2380 bytes, 1 file' V:/NT server 4.0/I386/192.DN_
            when 'Microsoft Cabinet archive data'
              result[:format] = Playful::File::FILE_FORMAT_CAB
            when 'InstallShield CAB'
              result[:format] = Playful::File::FILE_FORMAT_IS_CAB
          end

          # PARity archive data - Index file
          if cutouts[0] =~ /^PARity archive data/
            result[:format] = Playful::File::FILE_FORMAT_PARCHIVE

            if cutouts[0] =~ /Index file/
              result[:type] = :index
            end
          end

          # ISO 9660 CD-ROM filesystem data 'MATHWORKS_R2009B               '
          if cutouts[0] =~ /ISO 9660 CD-ROM filesystem data( '([^'']+)')?/
            result[:format] = Playful::File::FILE_FORMAT_ISO
            result[:description] = $2.strip if $2
          end

          # UDF filesystem data (version 1.5) 'X16-81657VS2010ULTIMMSDN       '
          if cutouts[0] =~ /UDF filesystem data( \(version (.*)\))?( '([^'']+)')?/
            result[:format] = Playful::File::FILE_FORMAT_UDF
            result[:format_version] = $2 if $2
            result[:description] = $4.strip if $4
          end

          # Self-extracting PKZIP archive MS-DOS executable, MZ for MS-DOS, PKLITE compressed
          if cutouts[0] =~ /PKZIP archive/
            result[:format] = Playful::File::FILE_FORMAT_PKZIP

            if cutouts[0] =~ /Self-extracting/
              result[:self_extracting] = true
            end
          end

          # DBase 3 data file (14 records)
          if cutouts[0] =~ /DBase (\d )?data file/
            result[:format] = Playful::File::FILE_FORMAT_DBF
            result[:format_version] = $1.strip if $1
          end

          ########################################################################
          # Documents
          ########################################################################

          case cutouts[0]
            # PDF document, version 1.3
            when 'PDF document'
              result[:format] = Playful::File::FILE_FORMAT_PDF
              if cutouts[1] =~ /version\s(.*)/
                result[:version] = $1
              end
            # MS Windows HtmlHelp Data
            when 'MS Windows HtmlHelp Data'
              result[:format] = Playful::File::FILE_FORMAT_WIN_CHM
            # Microsoft Word Document
            when 'Microsoft Word Document'
              result[:format] = Playful::File::FILE_FORMAT_MS_WORD
            # LaTeX table of contents
            when "LaTeX table of contents"
              result[:format] = Playful::File::FILE_FORMAT_LATEX_TOC
            # # Rich Text Format data, version 1, ANSI
            when 'Rich Text Format data'
              result[:format] = Playful::File::FILE_FORMAT_RTF
              (1..cutouts.length-1).each do |i|
                if cutouts[i] =~ /version (.*)/
                  result[:format_version] = $1
                end
                if ["ANSI", "PC-8", "Macintosh", "IBM PC"].include?(cutouts[i])
                  result[:characterset] = cutouts[i]
                end
              end
            # CDF V2 Document, Little Endian, Os: Windows, Version 5.1, Code page: 1252,
            # Title: ½M_FNAVN╗ ½M_ENAVN╗, Author: dlf/a, Template: Normal.dot,
            # Last Saved By: Preferred Customer, Revision Number: 4,
            # Name of Creating Application: Microsoft Office Word,
            # Total Editing Time: 27:00, Last Printed: Wed Sep 10 11:00:00 2003,
            # Create Time/Date: Mon Aug 29 08:22:00 2005,
            # Last Saved Time/Date: Mon Aug 29 08:34:00 2005,
            # Number of Pages: 1, Number of Words: 121, Number of Characters: 742, Security: 0
            when "CDF V2 Document"
              result[:format] = Playful::File::FILE_FORMAT_CDF_DOC
          end

          # LaTeX 2e document text
          if cutouts[0] =~ /LaTeX\s([^\s]*)?\s?document text/
            result[:format] = Playful::File::FILE_FORMAT_LATEX
            if $1
              result[:format_version] = $1
            end
          end

          # TeX DVI file (TeX output 2011.05.08:1307\213)
          if cutouts[0] =~ /TeX DVI file/
            result[:format] = Playful::File::FILE_FORMAT_DVI
          end

          # MS Windows 3.x help file
          if cutouts[0] =~ /MS Windows ((.*) )?help file/
            result[:format] = Playful::File::FILE_FORMAT_WIN_HLP
          end

          ########################################################################
          # Text
          ########################################################################
          get_line_descriptors = lambda { |desc, res|
            res[:long_lines] = false
            res[:line_terminator] = "LF"
            desc.each do |d|
              case d
                when  "with very long lines"
                  res[:long_lines] = true
                when "with CRLF line terminators"
                  res[:line_terminator] = "CRLF"
                when "with NEL line terminators"
                  res[:line_terminator] = "NEL"
                when "with no line terminators"
                  res[:line_terminator] = "none"
              end
            end
          }

          # ASCII English text, with very long lines, with CRLF line terminators
          if cutouts[0] =~ /^ASCII\s((.*)\s)?text$/
            result[:format] = Playful::File::FILE_FORMAT_ASCII

            if $2
              result[:content] = $2
            end

            get_line_descriptors.call(cutouts.drop(1), result)
          end

          # ISO-8859 C++ program text, with CRLF line terminators
          if cutouts[0] =~ /^ISO-(\d+)\s(.*)?\s?text$/
            if $1 == '8859'
              result[:format] = Playful::File::FILE_FORMAT_ISO8859

              get_line_descriptors.call(cutouts.drop(1), result)
            end
          end

          # UTF-8 Unicode C program text, with very long lines, with CRLF line terminators
          if cutouts[0] =~ /^UTF-8 Unicode ((.*) )?text$/
            result[:format] = Playful::File::FILE_FORMAT_UTF8

            if $2
              result[:content] = $2
            end

            get_line_descriptors.call(cutouts.drop(1), result)
          end

          # Little-endian UTF-16 Unicode text, with very long lines, with CRLF, CR line terminators
          # Little-endian UTF-16 Unicode English text, with CRLF, CR line terminators
          if cutouts[0] =~ /UTF-16 Unicode ((.*) )?text/
            result[:format] = Playful::File::FILE_FORMAT_UTF16

            if $2
              result[:content] = $2
            end

            get_line_descriptors.call(cutouts.drop(1), result)
          end

          # Non-ISO extended-ASCII English text, with very long lines, with CRLF line terminators
          # Non-ISO extended-ASCII text, with NEL line terminators
          if cutouts[0] =~ /^Non-ISO extended-ASCII ((.*) )?text$/
            result[:format] = Playful::File::FILE_FORMAT_ASCII_NON_ISO_EXTENDED
            result[:content] = $2 if $2

            get_line_descriptors.call(cutouts.drop(1), result)
          end

          case cutouts[0]
            # HTML document text
            when "HTML document text"
              result[:format] = Playful::File::FILE_FORMAT_HTML
            # M3U playlist text
            when "M3U playlist text"
              result[:format] = Playful::File::FILE_FORMAT_M3U
            # PLS playlist text
            when "PLS playlist text"
              result[:format] = Playful::File::FILE_FORMAT_PLS
            # XML document text
            # XML  document text
            when "XML document text", "XML  document text"
              result[:format] = Playful::File::FILE_FORMAT_XML
          end

          ########################################################################
          # Executable
          ########################################################################

          case cutouts[0]
            # PHP script text
            when "PHP script text"
              result[:format] = Playful::File::FILE_FORMAT_PHP
            # a rake script text executable
            # a ruby script text executable
            when "a rake script text executable", "a ruby script text executable"
              result[:format] = Playful::File::FILE_FORMAT_RUBY
            # Microsoft Windows Autorun file.
            when "Microsoft Windows Autorun file."
              result[:format] = Playful::File::FILE_FORMAT_MS_AUTORUN
            # MS-DOS executable, NE for MS Windows 3.x (driver)
            # MS-DOS executable, NE for MS Windows 3.x
            when 'MS-DOS executable'
              result[:format] = Playful::File::FILE_FORMAT_DOS_EXE
            # Macromedia Flash data, version 4
            when 'Macromedia Flash data'
              result[:format] = Playful::File::FILE_FORMAT_FLASH
              if cutouts[1] =~ /version (.*)/
                result[:format_version] = $1
              end
            when 'DOS batch file text'
              result[:format] = Playful::File::FILE_FORMAT_BAT
          end

          # DOS executable (device driver)
          if cutouts[0] =~ /^DOS executable( \((.*)\))?/
            result[:format] = Playful::File::FILE_FORMAT_DOS_EXE
          end

          # PE32 executable for MS Windows (GUI) Intel 80386 32-bit
          # PE32+ executable for MS Windows (GUI) Mono/.Net assembly
          if cutouts[0] =~ /(PE32\+?) executable for MS Windows \(([^\)]*)\) (.*)/i
            result[:format] = Playful::File::FILE_FORMAT_WIN_PE
            result[:bits] = 32
            result[:bits] = 64 if $1.split('').last == ?+
            result[:application_type] = $2
            result[:binary_format] = $3
          end

          ########################################################################
          # Windows
          ########################################################################

          case cutouts[0]
            # MS Windows registry file, NT/2000 or above
            when 'MS Windows registry file'
              result[:format] = Playful::File::FILE_FORMAT_WIN_REG
          end

          # Windows Registry text (Win95 or above)
          if cutouts[0] =~ /Windows Registry text/
            result[:format] = Playful::File::FILE_FORMAT_WIN_REG
          end

          result
        end

        def strip_id3(cutouts)
          result = {}

          while cutouts[0] =~ /Audio file with ID3 version (.*)/
            result[:tag_type] = :id3

            tag_type_version = $1
            if !result.has_key?(:tag_type_version) || result[:tag_type_version] < tag_type_version
              result[:tag_type_version] = tag_type_version
            end
            cutouts.shift

            if cutouts[0] == 'unsynchronized frames'
              cutouts.shift

              if result[:tag_type_version] == tag_type_version
                result[:frames] = :unsynchronized
              end
            else
              result[:frames] = :synchronized
            end

            cutouts[0].gsub!(/\s*contains:\s*/, '')
          end

          result
        end

        def split_raw(raw)
          pieces = []
          piece = 0
          instring = false
          buffer = ''
          (0..raw.length-1).each do |i|
            char = raw[i]
            if char == ?, && !instring
              pieces[piece] = buffer.strip
              buffer = ''
              piece += 1
              next
            elsif char == ?" && i - 1 >= 0 && raw[i - 1] != ?\
              # toggle string mode
              instring = !instring
            end
            buffer << char
          end
          if buffer != ''
              pieces[piece] = buffer.strip
          end

          pieces
        end

        def chunk_file_list(file_path_list)
          result = []
          cur_list = ""
          file_path_list.each do |fp|
            if cur_list.length > 1800
              result << cur_list
              cur_list = ""
            else
              cur_list += "\"#{fp}\" "
            end
          end
          if cur_list != ""
            result << cur_list
          end

          result
        end
      end
    end
  end
end