require 'units'
require 'playful/file'

module Playful
  module File
    module Driver

      class FfmpegDriver
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
          exp_cmd = "\"#{@path}\" -i \"#{fp}\" 2>&1"
          output = `#{exp_cmd}`
    
          result = {:raw => output}
          result[:extension] = filepath.split('.').last
          result.merge! annotate_result(result)
        end
    
        def annotate_result(result)
          # check if not recognized
          if result[:raw] =~ /: Unknown format/
            return
          end
    
          # Input #0, mpeg, from 'x:\Eddie Murphy - Delirious.avi':
          format = nil
          if result[:raw] =~ /Input #0, (.*), from '(.*)':/
            format = $1
            filename = $2
          end
    
          # Duration: 01:09:07.36, start: 0.733333, bitrate: 1411 kb/s
          if result[:raw] =~ /Duration: ([^,]+), start: ([^,]+), bitrate: ([^\n]+)\n/
            result[:bit_rate] = $3
            result[:bit_rate_in_kilo_bytes_per_sec] = Units.get_in_kilobytes_pr_sec($3).to_i

            d_split = $1.split(':')
            result[:duration] = d_split[0].to_i * 60 * 60 +
                                d_split[1].to_i * 60 +
                                d_split[2].to_f
          end
    
          # Stream #0.0[0x1e0]: Video: mpeg1video, yuv420p, 352x288 [PAR 178:163 DAR 1958:1467], 1150 kb/s, 25 tbr, 90k tbn, 25 tbc
          video = {}
          if result[:raw] =~ /Video: ([^\n]*)\n/
            v_split = $1.split(", ")
    
            video[:format] = v_split[0]
            video[:color_mode] = v_split[1]
            (2..v_split.length-1).each do |i|
              if v_split[i] =~ /(\d+)x(\d+)/
                video[:height] = $1.to_i
                video[:width] = $2.to_i
              elsif v_split[i] =~ /(.*) tbc/
                video[:fps] = $1.to_f
              elsif v_split[i] =~ /([^ ]*) kb\/s/
                video[:bit_rate] = $1
              end
            end
          end
    
          # Stream #0.1[0x1c0]: Audio: mp2, 44100 Hz, stereo, s16, 224 kb/s
          audio = {}
          if result[:raw] =~ /Audio: (.*), (.*), (.*), .*, (.*)/
            audio[:format] = $1
            audio[:sample_rate] = $2
            audio[:sample_rate_in_hz] = Units.get_in_hz($2).to_i

            audio[:channels] = $3
            audio[:bit_rate] = $4
          end
    
          format_conv = {
            'mpeg'                    => Playful::File::FILE_FORMAT_MPEG1_VIDEO,
            'avi'                     => Playful::File::FILE_FORMAT_AVI,
            'mov,mp4,m4a,3gp,3g2,mj2' => Playful::File::FILE_FORMAT_MPEG4,
            'matroska'                => Playful::File::FILE_FORMAT_MATROSKA,
            'ogg'                     => Playful::File::FILE_FORMAT_OGM,
            'mp3'                     => Playful::File::FILE_FORMAT_MPEG_LAYER_3,
          }
    
          result.merge!({
            :format => format_conv[format],
            :audio  => audio,
            :video  => video
          })
        end
      end

    end
  end
end
