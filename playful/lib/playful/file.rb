module Playful
  module File
    class DriverError < StandardError; end
    class FileScannerError < StandardError; end

    # Audio
    FILE_FORMAT_MPEG_LAYER_3  = "MPEG-1 Audio Layer 3"
    FILE_FORMAT_MPEG_LAYER_2  = "MPEG-1 Audio Layer 2"
    FILE_FORMAT_MUSEPACK      = "Musepack audio"
    FILE_FORMAT_FLAC          = "FLAC audio bitstream data"
    FILE_FORMAT_VORBIS        = "Ogg Vorbis audio"
    FILE_FORMAT_MS_ASF        = "Microsoft Advanced Systems Format"
    FILE_FORMAT_MONKEY        = "Monkey's Audio"
    FILE_FORMAT_MIDI          = "Standard MIDI"
    FILE_FORMAT_WAVE          = "RIFF Waveform audio"
    FILE_FORMAT_REALMEDIA     = "RealMedia"
    # Image
    FILE_FORMAT_JPEG        = "JPEG image data"
    FILE_FORMAT_GIF         = "GIF image data"
    FILE_FORMAT_VISX        = "VISX image file"
    FILE_FORMAT_BITMAP      = "PC bitmap"
    FILE_FORMAT_ADOBE_IMAGE = "Adobe Photoshop Image"
    FILE_FORMAT_TARGA_IMAGE = "Targa image"
    FILE_FORMAT_PNG         = "PNG image"
    FILE_FORMAT_WIN_ICON    = "MS Windows icon resource"
    # Video
    FILE_FORMAT_QUICKTIME   = "Apple QuickTime movie"
    FILE_FORMAT_AVI         = "RIFF AVI"
    FILE_FORMAT_MATROSKA    = "Matroska"
    FILE_FORMAT_OGM         = "Ogg OGM video"
    FILE_FORMAT_THEORA      = "Ogg Theora video"
    FILE_FORMAT_MPEG1_VIDEO = "MPEG-1 video"
    FILE_FORMAT_MPEG4       = "MPEG4"
    FILE_FORMAT_DVD_IFO     = "Video title set IFO"
    # Text
    FILE_FORMAT_ASCII                   = "ASCII text"
    FILE_FORMAT_ISO8859                 = "ISO-8859"
    FILE_FORMAT_HTML                    = "HTML document text"
    FILE_FORMAT_M3U                     = "M3U playlist text"
    FILE_FORMAT_PLS                     = "PLS playlist text"
    FILE_FORMAT_XML                     = "XML document text"
    FILE_FORMAT_ASCII_NON_ISO_EXTENDED  = "Non-ISO extended-ASCII"
    FILE_FORMAT_UTF8                    = "UTF-8"
    FILE_FORMAT_UTF16                   = "UTF-16"
    # Documents
    FILE_FORMAT_PDF       = "PDF document"
    FILE_FORMAT_LATEX     = "LaTeX document"
    FILE_FORMAT_LATEX_TOC = "LaTeX table of contents"
    FILE_FORMAT_RTF       = "Rich Text Format"
    FILE_FORMAT_DVI       = "TeX DVI"
    FILE_FORMAT_CDF_DOC   = "CDF Document"
    FILE_FORMAT_WIN_HLP   = "MS Windows help file"
    FILE_FORMAT_MS_WORD   = "Microsoft Word Document"
    FILE_FORMAT_WIN_CHM   = "MS Windows HtmlHelp Data"
    # Archive
    FILE_FORMAT_ZIP       = "Zip archive data"
    FILE_FORMAT_RAR       = "RAR archive data"
    FILE_FORMAT_PARCHIVE  = "PARity archive data"
    FILE_FORMAT_ISO       = "ISO 9660 CD-ROM filesystem data"
    FILE_FORMAT_UDF       = "Universal Disk Format"
    FILE_FORMAT_CAB       = "Microsoft Cabinet archive data"
    FILE_FORMAT_IS_CAB    = "InstallShield CAB"
    FILE_FORMAT_MS_CPS    = "MS Compress archive data"
    FILE_FORMAT_PKZIP     = "PKZIP archive data"
    FILE_FORMAT_DBF       = "DBase data file"
    # Executables
    FILE_FORMAT_MS_AUTORUN  = "Microsoft Windows Autorun file"
    FILE_FORMAT_PHP         = "PHP script text"
    FILE_FORMAT_RUBY        = "Ruby script text"
    FILE_FORMAT_WIN_PE      = "Windows Portable Executable"
    FILE_FORMAT_DOS_EXE     = "MS-DOS executable"
    FILE_FORMAT_FLASH       = "Macromedia Flash"
    FILE_FORMAT_BAT         = "DOS batch file"
    # Windows
    FILE_FORMAT_WIN_REG = "MS Windows registry file"

    # Constants for the codecs the file scanner is able to distinguish
    # which are not covered implicitly in the file types

    # Video
    CODEC_VIDEO_MPEG4 = "MPEG 4"
    CODEC_VIDEO_MPEG4_H264 = "MPEG 4 (h264)"
    CODEC_VIDEO_MS_MPEG4 = "Microsoft MPEG 4"

    # Audio
    CODEC_AUDIO_MPEG1_LAYER3 = "MPEG-1 Layer 3 audio"
    CODEC_AUDIO_VORBIS = "Vorbis audio"

    # Collections of file formats
    FILE_FORMATS_AUDIO = [
        FILE_FORMAT_MPEG_LAYER_2, FILE_FORMAT_MPEG_LAYER_3, FILE_FORMAT_MUSEPACK, FILE_FORMAT_FLAC, FILE_FORMAT_VORBIS,
        FILE_FORMAT_MS_ASF, FILE_FORMAT_MONKEY, FILE_FORMAT_MIDI, FILE_FORMAT_WAVE, FILE_FORMAT_REALMEDIA
    ]

    FILE_FORMATS_VIDEO = [
        FILE_FORMAT_QUICKTIME, FILE_FORMAT_AVI, FILE_FORMAT_MATROSKA, FILE_FORMAT_OGM, FILE_FORMAT_MPEG1_VIDEO,
        FILE_FORMAT_MPEG4, FILE_FORMAT_THEORA
    ]

    FILE_FORMATS_ARCHIVE = [
        FILE_FORMAT_ZIP, FILE_FORMAT_RAR, FILE_FORMAT_PARCHIVE, FILE_FORMAT_ISO, FILE_FORMAT_UDF, FILE_FORMAT_CAB,
        FILE_FORMAT_IS_CAB, FILE_FORMAT_MS_CPS, FILE_FORMAT_PKZIP
    ]

    FILE_FORMATS_IMAGE = [
        FILE_FORMAT_JPEG, FILE_FORMAT_GIF, FILE_FORMAT_VISX, FILE_FORMAT_BITMAP, FILE_FORMAT_ADOBE_IMAGE,
        FILE_FORMAT_TARGA_IMAGE, FILE_FORMAT_PNG, FILE_FORMAT_WIN_ICON
    ]

    # util methods

    def self.audio?(file_format)
      Playful::File::FILE_FORMATS_AUDIO.include?(file_format)
    end

    def self.audio_extension?(extension)
      ["mp3", "flac", "mpc", "wav"].include?(extension.downcase)
    end

    def self.video?(file_format)
      Playful::File::FILE_FORMATS_VIDEO.include?(file_format)
    end

    def self.archive?(file_format)
      Playful::File::FILE_FORMATS_ARCHIVE.include?(file_format)
    end

    def self.image?(file_format)
      Playful::File::FILE_FORMATS_IMAGE.include?(file_format)
    end
=begin
    def self.get_default_file_driver
      Playful::File::Driver::FileDriver.new(:path => "C:/Program Files (x86)/GnuWin32/bin/file.exe")
    end

    def self.get_default_ffmpeg_driver
      Playful::File::Driver::FfmpegDriver.new(:path => "C:/Program Files (x86)/ffmpeg-0.5/bin/ffmpeg.exe")
    end

    def self.get_default_tag_driver
      Playful::File::Driver::TagDriver.new
    end

    def self.get_default_scanner
      Playful::File::Scanner.new(get_default_file_driver, get_default_ffmpeg_driver, get_default_tag_driver)
    end
=end
  end
end