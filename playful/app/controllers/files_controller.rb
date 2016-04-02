require 'playful/file/scanner'
require 'find'

class FilesController < ApplicationController
  respond_to :json
  around_filter :handle_exceptions

  class FileNotFoundError < RuntimeError; end
  class ShareNotFound < RuntimeError; end

  # POST /search
  def search
    # should be able to find number of files only, no other data
    # should be able to look in a directory

    render :text => [].to_json
  end

  # GET /:id
  def show
    get_file_by_id
    respond_with(@file)
  end

  # GET  /:id/scan
  # POST /scan
  def scan
    # scans can be done on a single file, a directory listing or a directory recursively
    # TODO: add functionality: security, limiting the recursive scans, limiting scans to specific shares

    scanner = Playful::Factory.file_scanner
    files = get_scan_request_files()
    @scan_result = scanner.scan_files(files)

    # change real path to share relative path
    Array(@scan_result).each do |file_scan|
      share = Share.find_share_by_fs_path(file_scan[:path])
      file_scan[:path] = share.to_share_rel_path(file_scan[:path])
    end

    respond_with @scan_result do |format|
      format.json { render json: @scan_result.to_json }
    end
  end

  # GET  /:id/download
  def download
    options = { :disposition => "attachment" }
    file_path = nil

    if params.has_key?(:id)
      verify_and_get_file
      file_path = @file.path
      options[:type] = @file.file_type.mime_type
    elsif params.has_key?(:path)
      share_file_path = params[:path]
      share = Share.find_share_by_share_rel_path(share_file_path)
      raise ShareNotFound.new "Could not find a share for #{path}" if share.nil?
      file_path = share.to_fs_path(share_file_path)
    end

#    File.open(@file.path, 'rb') { |file| render :status => 200, :text => file.read }
    if file_path.nil? || !File.file?(file_path)
      raise FileNotFoundError.new
    end
    # TODO: add functionality: some security here is much needed as there is none whatsoever atm.
    send_file(file_path, options)
  end

  # DELETE /:id
  def destroy
    raise NotImplementedError.new "Deletion not supported yet"
  end

  private

  def handle_exceptions
    yield
=begin
	rescue FileScanner::FileScannerError,
	       FileOperation::FileOperationError => exception
    render :text => exception, :status => :server_error
  rescue NotImplementedError => exception
    render :text => exception, :status => :not_implemented
  rescue NoFilesFoundError, ActiveRecord::RecordNotFound => exception
    render :text => exception, :status => :not_found
  rescue ArgumentError => exception
    render :text => exception, :status => :bad_request
=end
  end

  def get_file_by_id(file_id = params[:id])
    unless file_id =~ /^\d+$/
      raise ArgumentError.new "File id not an integer '#{params[:id]}'"
    end
    @file = BaseFile.find(file_id)
  end

  def get_scan_request_files
    # GET and POST requests can hit the scan service, this method returns the file paths
    # GET requests have an id, POST can have :file, :files, :dir or :dirs. These are handled prioritized
    file_paths = []
    dir_paths = []
    recursive = params.has_key?(:recursive) && params[:recursive]
    if params.has_key?(:id)
      get_file_by_id()
      file_paths << @file.path
    end

    # pick up all dirs
    dir_paths << params[:dir] if params.has_key?(:dir)
    dir_paths += params[:dirs] if params.has_key?(:dirs) && params[:dirs].is_a?(Array)
    dir_paths.delete_if { |dp| !dp.is_a?(String) }

    # convert share paths to actual file paths
    dir_paths = dir_paths.map do |path|
      share = Share.find_share_by_share_rel_path(path)
      if share.nil?
        raise ShareNotFound.new "Could not find a share for #{path}"
      end
      share.to_fs_path(path)
    end

    # flatten dirs to files
   # TODO: this should really be commented in but can't be because of bug in jruby encoding on windows. only abs paths work!
   # dir_paths.map! { |path| File.expand_path(path) }
    dir_paths.each do |dp|
      dp = dp.encode('utf-8') # this is because of jruby + windows
      if File.directory?(dp)
        Find.find(dp) do |path|
          file_paths << path unless path == dp
          if dp != path && File.directory?(path) && !recursive
            Find.prune()
          end
        end
      end
    end

    # pick up specified files
    file_params_paths = []
# for some fucking reason, rails places a key named file in params...
#    file_params_paths << params[:file] if params.has_key?(:file)
    file_params_paths += params[:files] if params.has_key?(:files) && params[:files].is_a?(Array)
    file_paths += file_params_paths.map do |path|
      share = Share.find_share_by_share_rel_path(path)
      if share.nil?
        raise ShareNotFound.new "Could not find a share for #{path}"
      end
      share.to_fs_path(path)
    end

    # filter files
    file_paths.delete_if { |fp| !fp.is_a?(String) }
    file_paths.delete_if { |fp| !File.exists?(fp) }
    # TODO: add functionality: insert security here
    file_paths #.map { |fp| File.expand_path(fp) }.uniq
  end

end
