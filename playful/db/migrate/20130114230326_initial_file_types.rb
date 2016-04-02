class InitialFileTypes < ActiveRecord::Migration
  def up
    FileType.create!(name: 'MPEG3', subtype: FileType::AUDIO,
                     extension: 'mp3', ruby_class: 'BaseFile::AudioFile',
                     mime_type: 'audio/mpeg, audio/x-mpeg, audio/x-mpeg-3, audio/mpeg3', scan_type: 'MPEG-1 Audio Layer 3')

    FileType.create!(name: 'AVI', subtype: FileType::VIDEO,
                     extension: 'avi', ruby_class: 'BaseFile::VideoFile',
                     mime_type: 'video/avi', scan_type: 'RIFF AVI')

    FileType.create!(name: 'JPEG', subtype: FileType::IMAGE,
                     extension: 'jpg', ruby_class: 'BaseFile::ImageFile',
                     mime_type: 'image/jpeg', scan_type: 'JPEG image data')

    FileType.create!(name: 'PNG', subtype: FileType::IMAGE,
                     extension: 'png', ruby_class: 'BaseFile::ImageFile',
                     mime_type: 'image/png', scan_type: 'PNG image')

    FileType.create!(name: 'MPEG4', subtype: FileType::VIDEO,
                     extension: 'mp4', ruby_class: 'BaseFile::VideoFile',
                     mime_type: 'video/mp4', scan_type: 'MPEG4')
  end

  def down
    ['MPEG3', 'AVI', 'JPEG', 'PNG', 'MPEG4'].each do |ftn|
      ft = FileType.find_by_name ftn
      ft.delete unless ft.nil?
    end
  end
end
