require 'playful/file'
require 'jars/jaudiotagger-2.2.0-20130321.162819-3.jar'
java_import org.jaudiotagger.audio.AudioFileIO
java_import org.jaudiotagger.tag.FieldKey
java_import org.jaudiotagger.tag.id3.ID3v24Tag
java_import org.jaudiotagger.tag.images.ArtworkFactory

module Playful
  module File
    module Driver

      class TagDriver
        def initialize
          @field_mapping = {
              :artist             => FieldKey::ARTIST,
              :album_artist       => FieldKey::ALBUM_ARTIST,
              :composer           => FieldKey::COMPOSER,
              :album              => FieldKey::ALBUM,
              :track_title        => FieldKey::TITLE,
              :track_number       => FieldKey::TRACK,
              :track_total        => FieldKey::TRACK_TOTAL,
              :year               => FieldKey::YEAR,
              :genre              => FieldKey::GENRE,
              :disc_number        => FieldKey::DISC_NO,
              :disc_total         => FieldKey::DISC_TOTAL,
              :comment            => FieldKey::COMMENT,
              :encoder            => FieldKey::ENCODER,
              :lyrics             => FieldKey::LYRICS,
              :lyricist           => FieldKey::LYRICIST,
              :album_artist_sort  => FieldKey::ALBUM_ARTIST_SORT,
              :album_sort         => FieldKey::ALBUM_SORT,
              :artist_sort        => FieldKey::ARTIST_SORT,
              :bpm                => FieldKey::BPM,
              :composer_sort      => FieldKey::COMPOSER_SORT,
              :conductor          => FieldKey::CONDUCTOR,
              :language           => FieldKey::LANGUAGE,
              :title_sort         => FieldKey::TITLE_SORT,
              :cover_art          => FieldKey::COVER_ART,
              :is_compilation     => FieldKey::IS_COMPILATION,
              :key                => FieldKey::KEY
          }

          # only the "meaningful" constants are transferred here. in v2.2 of jaudiotagger, look for the constants in
          # org.jaudiotagger.tag.reference.PictureTypes
          @cover_art_mapping = {
              :other              => 0,
              :front              => 3,
              :back               => 4,
              :leaflet_page       => 5,
              :media              => 6, # (e.g. label side of CD)
              :lead_artist        => 7,
              :artist             => 8,
              :band               => 10,
              :composer           => 11,
              :during_recording   => 14,
              :during_performance => 15,
          }
#          @scan_keys = [:artist, :album_artist, :composer, :album, :track_title, :track_number, :track_total, :year,
#                        :genre, :disc_number, :disc_total, :comment, :encoder, :lyrics]
        end

        def scan_file(file)
          unless ::File.file?(file)
            raise DriverError.new "File #{file} is not a file"
          end

          begin
            audio_file = AudioFileIO.read(java.io.File.new(file))
            tag = audio_file.get_tag # ruby syntax for the getTag method. SO sexy!
            header = audio_file.get_audio_header
          rescue Java::OrgJaudiotaggerAudioExceptions::CannotReadException
            raise DriverError.new "Cannot read tags for file #{file}. Maybe it's not an audio file?"
          end

          result = {
            :duration           => header.get_track_length,
            :sample_rate        => header.get_sample_rate_as_number,
            :bit_rate           => header.get_bit_rate_as_number,
            :format             => header.get_format,
            :encoding_type      => header.get_encoding_type,
            :channels           => header.get_channels,
            :variable_bit_rate  => header.is_variable_bit_rate
          }

          unless tag.nil?
            @field_mapping.each do |k, v|
              result[k] = tag.get_first(v)
            end
          end

          process_scan result
        end

        def write_tags(file, tags)
          unless ::File.file?(file)
            raise DriverError.new "File #{file} is not a file"
          end

          audio_file = AudioFileIO.read(java.io.File.new(file))
          header = audio_file.get_audio_header
          tag = audio_file.get_tag
          tags = tags.symbolize_keys

          if tag.nil?
            # a new tag must be created depending on which type the file has
            case header.get_format
              when "MPEG-1 Layer 3"
                tag = ID3v24Tag.new
              else
                raise DriverError.new "Unable to find tag type for format #{header.get_format}"
            end

            audio_file.set_tag(tag)
          end

          tags.reject { |name, value| name == :cover_art }.each do |name, value|
            unless @field_mapping.has_key?(name)
              raise DriverError.new "Unknown field #{name.to_s}"
            end

            if value.nil?
              tag.delete_field(@field_mapping[name])
            else
              tag.set_field(@field_mapping[name], value.to_s)
            end
          end

          if tags.has_key?(:cover_art)
            ca = tags[:cover_art]
            # to update the tag, the current artwork list must be deleted. therefore any change to this will
            # "reconstruct" it with the given changes
            awl = tag.get_artwork_list
            awh = Hash[awl.map { |aw| [aw.get_picture_type, aw] }]

            if ca.is_a?(Hash) && ca.any?
              ca.each do |cover_art_name, cover_art_data|
                if cover_art_data.is_a?(String) && ::File.file?(cover_art_data)
                  aw = ArtworkFactory.create_artwork_from_file(java.io.File.new(cover_art_data))
                  aw.set_picture_type(@cover_art_mapping[cover_art_name])
                  awh[aw.get_picture_type] = aw
                end
              end
              tag.delete_artwork_field
              awh.values.each { |aw| tag.set_field(aw) }
            elsif ca.nil?
              tag.delete_artwork_field
            end
          end

          audio_file.commit
        end

        private

        def process_scan(scan)
          number_fields = [:track_number, :track_total, :year, :disc_number, :disc_total, :bpm]

          scan.each do |k, v|
            if number_fields.include?(k)
              begin
                scan[k] = Integer(v)
              rescue ArgumentError
                # do nothing
              end
            end
          end
        end

      end

    end
  end
end
