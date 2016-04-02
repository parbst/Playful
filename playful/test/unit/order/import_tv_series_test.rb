require 'test_helper'

class Order::ImportTvSeriesTest < ActiveSupport::TestCase
  fixtures :properties, :file_types, :base_files, :shares

  def setup
    prepare_files_for_fixtures
    @video_files = []
    @scanner = Playful::Factory.file_scanner
    @free_path = get_available_file_path
    @plain_files = []
    @plain_files << @test_image = get_test_image_file
    @base_files = []
    @base_files << @test_imported_image = get_test_imported_image_file
  end

  def teardown
    (@video_files + @plain_files + @base_files.map(&:path)).each do |f|
      begin
        File.delete f
      rescue
        ;
      end
    end
  end

  test "create from params" do
    @video_files << video_file_1 = get_test_video_file

    params = {
      :tv_series => {
        :update_from_metadata => true,
        :original_name => 'override this',
        :description => 'override that',
        :poster_file_path => @test_image,
        :poster_file_share_id => 2,
        :tmdb_id => 456, # the simpsons
        :seasons => {
          :add => (1..10).map { |i| { season_number: i, update_from_metadata: true }  },
        },
        :episodes => {
          :add => (1..13).map { |i| {episode_number: i, season_number: 1, update_from_metadata: true} }
        },
        :video_clips => {
          add: [
            {
              :season_number => 1,
              :episode_number => 1,
              :set => 1,
              :item_order => 1,
              :path =>  video_file_1,
              :share_id => 2
            },
            {
              :set => 1,
              :item_order => 2,
              :season_number => 1,
              :episode_number => 1,
              :video_file_id =>  base_files(:video_file2).id,
              :share_id => 2
            }
          ]
        }
      }
    }
    params[:tv_series][:seasons][:add].first[:name] = 'override this'
    params[:tv_series][:seasons][:add].first[:poster_file_id] = @test_imported_image.id

    o = Order::Import::TvSeries.create_from_params(params)
    assert_equal o.id, o.root_order_id
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    puts message
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Create) }.first.model
    (1..10).each do |season_number|
      season = tv_series.seasons.select {|s| s.season_number == season_number}.first
      assert_not_nil season
      assert_not_nil season.name
      assert_not_nil season.description
      assert_not_nil season.season_number
      assert_not_nil season.poster_url
      assert_not_nil season.tmdb_id
      assert_not_nil season.air_date
    end

    season_1 = tv_series.seasons.select {|s| s.season_number == 1}.first
    (1..13).each do |episode_number|
      episode = season_1.episodes.select { |e| e.episode_number == episode_number }.first
      assert_not_nil episode
      assert_not_nil episode.name
      assert_not_nil episode.description
      assert_not_nil episode.episode_number
      assert_not_nil episode.item_order
      assert_not_nil episode.air_date
      assert_not_nil episode.poster_url
      assert_not_nil episode.tmdb_id
      assert_not_nil episode.freebase_id
    end

    assert_equal @test_imported_image.id, season_1.poster_file_id
    assert_not_nil tv_series.poster_file

    episode_1_1 = season_1.episodes.select { |e| e.episode_number == 1 }.first
    clip_1 = episode_1_1.video_clips.find { |vc| vc.video_file.id != base_files(:video_file2).id }
    clip_2 = episode_1_1.video_clips.find { |vc| vc.video_file.id == base_files(:video_file2).id }
    imported_video_file = o.tasks.select {|t| t.is_a?(Task::Model::BaseFile::VideoFile::Create) }.first.model
    assert_not_nil clip_1
    assert_not_nil clip_2

    assert_equal base_files(:video_file2).id, clip_2.video_file.id
    assert_equal imported_video_file.id, clip_1.video_file.id

  end
end