require 'test_helper'

class Order::ChangeMovieTest < ActiveSupport::TestCase
  fixtures :properties, :base_files, :shares, :clips, :movies

  def setup
    prepare_files_for_fixtures
    @plain_files = []
    @scanner = Playful::Factory.file_scanner
    @plain_files << @image_file = get_test_image_file
  end

  def teardown
    @plain_files.each do |f|
      begin
        File.delete f
      rescue
        ;
      end
    end
  end

  test "change parameters and resolve" do
    @plain_files << video_file_1 = get_test_video_file
    overwrite_title = "the other title"
    overwrite_original_title = "the original title"
    genre = "the custom genre"
    character_name = "el gringo mucho mannas!"
    params = {
      movie: {
          movie_id: 1,
          title: overwrite_title,
          original_title: overwrite_original_title,
          tmdb_id:    550, # fight club
          genres: {
            add: [
              { name: genre }
            ]
          },
          languages: {
            add: [
              {
                iso_639_1: 'da-DK',
                name:      'Danish'
              }
            ]
          },
          poster_file_path: @image_file,
          poster_file_share_id: shares(:share_imported).id,
          video_clips: {
            add: [
              { path: video_file_1, share_id: shares(:share_imported).id },
              { video_file_id: base_files(:video_file2).id },
            ],
            delete: [
              {
                video_file_id: base_files(:video_file3).id
              }
            ]
          },
          casts: {
            add: [
              {
                actor_name:           'alfredo',
                actor_image_url:      'http://no.where',
                character_name:       character_name,
                character_image_url:  'http://no.where',
                order:                2
              }
            ]
          },
          update_from_metadata: true
        }
    }

    o = Order::Change::Movie.create_from_params(params)
    o = o.first
    assert_equal o.id, o.root_order_id
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    assert_equal Order::Status::COMPLETED, o.status

    ct = o.tasks.select {|t| t.is_a?(Task::Model::Movie::Change) }.first
    movie = ct.model
    assert_equal overwrite_title, movie.title
    assert_equal overwrite_original_title, movie.original_title
    assert_equal "550", movie.tmdb_id
    assert_not_equal 'Moving pictures!', movie.tagline
    assert movie.genres.any? {|g| g.name == genre}
    assert movie.genres.length > 1
    assert_equal 2, movie.video_clips.length
    assert movie.video_clips.any? {|vc| vc.video_file.id == base_files(:video_file2).id }
    assert !movie.video_clips.any? {|vc| vc.video_file.id == base_files(:video_file3).id }
    assert_not_nil movie.casts.find {|c| c.character_name == character_name }
    assert movie.languages.length > 1
    assert_not_nil movie.languages.find {|l| l.name == 'Danish' }

  end

  test "delete video file" do
    video_file_id = base_files(:video_file3).id
    params = {
      movies: [
        {
          movie_id: 1,
          video_clips: {
            delete: [
              {
                video_file_id:      video_file_id,
                delete_video_file:  true
              }
            ]
          }
        }
      ]
    }

    o = Order::Change::Movie.create_from_params(params)
    o = o.first
    assert_equal o.id, o.root_order_id
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    assert_equal Order::Status::COMPLETED, o.status
    assert_nil BaseFile::VideoFile.find_by_id(video_file_id)
  end

end
