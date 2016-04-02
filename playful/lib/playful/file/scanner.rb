require 'playful/file'
require 'playful/file/driver/file_driver'
require 'playful/file/driver/ffmpeg_driver'
require 'playful/file/driver/tag_driver'

module Playful
  module File

    class Scanner
      def initialize(file_driver, ffmpeg_driver, tag_driver)
        @file_driver = file_driver
        @ffmpeg_driver = ffmpeg_driver
        @tag_driver = tag_driver
      end

      def scan_file(path)
        unless ::File.exist?(path)
          raise FileScannerError.new "Nothing exists on path #{path}"
        end

        file_results = @file_driver.scan_file(::File.expand_path(path))
        do_scan(file_results[:files].first)
      end

      def scan_files(paths)
        paths.each do |path|
          unless ::File.exist?(path)
            raise FileScannerError.new "Nothing exists on path #{path}"
          end
        end

        # expand_path makes ? for æøå
        #expanded_paths = paths.map { |fp| ::File.expand_path fp }
        file_results = @file_driver.scan_files(paths)

        file_results[:files].map do |f|
          do_scan(f)
        end
      end

      private

      def do_scan(file_result)
        path = file_result[:path]
        result = {
          :path => path,
          :size => ::File.size(path),
          :stat => stat_scan(path)
        }

        if ::File.file?(path)
          result[:type] = :file
          result[:file] = file_result
          complete_scan(result)
        else
          result[:type] = :directory
        end

        result
      end

      def stat_scan(path)
        file_stat = ::File.stat path
        {
          :dev     => file_stat.dev,
          :ino     => file_stat.ino,
          :mode    => file_stat.mode,
          :nlink   => file_stat.nlink,
          :uid     => file_stat.uid,
          :gid     => file_stat.gid,
          :rdev    => file_stat.rdev,
          :size    => file_stat.size,
          :blksize => file_stat.blksize,
          :blocks  => file_stat.blocks,
          :atime   => file_stat.atime,
          :mtime   => file_stat.mtime,
          :ctime   => file_stat.ctime,
        }
      end

      # given a result which contains the :file part, this method contains the
      # logic to complete the scan. it determines which other drivers to call and
      # makes the final conclusion, yielding a complete scan result
      def complete_scan(result)
        file_failed_to_recognize_audio =
            result[:file][:format].nil? && Playful::File::audio_extension?(result[:file][:extension])

        if result[:file][:format].nil? && !file_failed_to_recognize_audio
          # sometimes file cannot recognize audio files, but this is probably not
          # an audio file. In fact, it is not possible to conclude what it is
          result[:conclusion] = nil
          return result
        end

        do_ffmpeg = Playful::File::audio?(result[:file][:format]) ||
            Playful::File::video?(result[:file][:format]) ||
            Playful::File::image?(result[:file][:format]) ||
            file_failed_to_recognize_audio
        if do_ffmpeg
          result[:ffmpeg] = @ffmpeg_driver.scan_file(result[:path])
        end

        if result.has_key?(:ffmpeg) && Playful::File::audio?(result[:ffmpeg][:format])
          result[:tag] = @tag_driver.scan_file(result[:path])
        end

        if result[:file][:format]
          result[:conclusion] = result[:file][:format]
        elsif result[:ffmpeg][:format]
          result[:conclusion] = result[:ffmpeg][:format]
        elsif result[:stat][:size] != 0
          msg = "Could not draw conclusion based on scan:\n" + result.to_yaml
          raise FileScannerError.new msg
        end

        unless result[:conclusion].nil?
          result[:is_audio] = Playful::File.audio?(result[:conclusion])
          result[:is_video] = Playful::File.video?(result[:conclusion])
          result[:is_archive] = Playful::File.archive?(result[:conclusion])
          result[:is_image] = Playful::File.image?(result[:conclusion])
        end

        result
      end

    end

  end
end
