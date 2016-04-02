require 'uri'
require 'tempfile'
require 'net/http'

class Task::File::Download < Task::File

  TYPE = 'downloadFileTask'

#  before_validation :ensure_to_path, :on => :create
  before_validation(on: :create) { ensure_to_path }

  validates :url, :format => {:with => URI::regexp, :message => 'Provided URL is invalid'}
  validates :to_path, :presence => true

  def execute
    ::File.open(to_path, 'ab') do |f|
      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.request(Net::HTTP::Get.new(uri.request_uri)) do |resp|
          resp.read_body do |segment|
            f.write(segment)
          end
        end
      ensure
        f.close
      end
    end
  end

  def output_file_path
    to_path
  end

  def guess_extension
    ::File.extname(URI.parse(url || '').path)
  end

  def guess_filename
    ::File.basename(URI.parse(url || '').path)
  end

  protected

  def ensure_to_path
    if to_path.blank?
      uri = URI.parse(url)
      uri_filename = ::File.basename(uri.path)
      uri_extension = ::File.extname(uri.path)
      t = Tempfile.new([uri_filename, uri_extension], Rails.root.join('tmp'))
      self.to_path = t.path
      t.close
      t.unlink
    end
  end
end
