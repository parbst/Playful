class InitialProperties < ActiveRecord::Migration
  def up
    Property.create!(category: 'configuration', name: 'file_exec_path', value: 'C:/Program Files (x86)/GnuWin32/bin/file.exe')
    Property.create!(category: 'configuration', name: 'ffmpeg_exec_path', value: 'C:/Program Files (x86)/ffmpeg-0.5/bin/ffmpeg.exe')
  end

  def down
    ['file_exec_path', 'ffmpeg_exec_path'].each do |pn|
      p = Property.find_by_name pn
      p.destroy unless p.nil?
    end
  end
end
