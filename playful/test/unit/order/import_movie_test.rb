require 'test_helper'

class Order::ImportMovieTest < ActiveSupport::TestCase
  fixtures :properties, :base_files, :shares

  def setup
    prepare_files_for_fixtures
    @plain_files = []
    @scanner = Playful::Factory.file_scanner
    @free_path = get_available_file_path
    @base_files = []
    @plain_files << @image_file = get_test_image_file
  end

  def teardown
    (@plain_files + @base_files.map {|bf| bf.path }).each do |f|
      begin
        File.delete f
      rescue
        ;
      end
    end
  end

  test "create from params" do
    @plain_files << video_file_1 = get_test_video_file

    overwrite_title = "the other title"
    genre = "the custom genre"
    params = {
      movie:{
        title:      overwrite_title,
        tmdb_id:    550, # fight club
        genres: {
          add: [ { name: genre } ]
        },
        poster_file_path: @image_file,
        poster_file_share_id: 2,
        video_clips: {
          add: [
            { path: video_file_1, share_id: 2 },
            { video_file_id: base_files(:video_file2).id },
          ]
        },
        update_from_metadata: true
      }
    }

    oa = Order::Import::Movie.create_from_params(params)
    o = oa.first
    assert_equal o.id, o.root_order_id
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    assert_equal Order::Status::COMPLETED, o.status
    cmt = o.tasks.select {|t| t.is_a?(Task::Model::Movie::Create) }.first
    m = Movie.find(cmt.model_id)
    @base_files = m.video_clips.map { |vc| vc.video_file }

    assert_not_nil m.original_title
    assert_not_nil m.tagline
    assert_not_nil m.storyline
    assert_not_nil m.youtube_trailer_source
    assert_not_nil m.poster_url
    assert_not_nil m.tmdb_id
    assert_not_nil m.imdb_id
    assert_not_nil m.poster_file

    cit = o.tasks.select {|t| t.is_a?(Task::Model::BaseFile::ImageFile::Create) }.first
    cvt = o.tasks.select {|t| t.is_a?(Task::Model::BaseFile::VideoFile::Create) }.first

    assert_nil m.metacritic_id
    assert_nil m.rotten_tomatoes_id
    assert_equal cit.model.id, m.poster_file_id

    assert_equal 2, m.video_clips.length
    assert m.video_files.map(&:id).include?(base_files(:video_file2).id)
    assert m.video_files.map(&:id).include?(cvt.model.id)
  end
end
