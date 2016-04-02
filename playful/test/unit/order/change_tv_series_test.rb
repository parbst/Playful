require 'test_helper'

class Order::ChangeTvSeriesTest < ActiveSupport::TestCase
  fixtures :properties, :file_types, :base_files, :shares, :tv_series

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

  test 'change tv series' do
    @plain_files << image_file_path = get_test_image_file

# poster url and imdb id change on update from tmdb
    changed_name = 'the other name'
    changed_original_name = 'the other original name'
    changed_description = 'changed description'
    genre_name = 'stoopid'
    params = {
      tv_series: {
        update_from_metadata:   true,
        name:                   changed_name,
        original_name:          changed_original_name,
        description:            changed_description,
        tmdb_id:                456, # the simpsons
        tv_series_id:           tv_series(:tv_series1).id,
        poster_file_path:       image_file_path,
        poster_file_share_id:   shares(:share_imported).id,
        genres: {
          add: [{ name:          genre_name }],
          delete: [{ name:       'Animation'}]
        },
        languages: {
          add: [
            {
              iso_639_1:        'da-dk',
              name:             'Dansk'
            }
          ]
        },
      }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    assert_equal changed_name, tv_series.name
    assert_equal changed_original_name, tv_series.original_name
    assert_equal changed_description, tv_series.description
    assert_not_nil tv_series.genres.find{|g| g.name == genre_name}
    assert_nil tv_series.genres.find{|g| g.name == 'Animation'}
    assert_not_nil tv_series.imdb_id
    assert_not_nil tv_series.poster_url
    assert_not_nil tv_series.poster_file_id
  end

  test 'add season' do
    season_name = 'The next season'
    description = 'a description for season'
    poster_url = 'http://url.to.nowhere'
    air_date = Date.new(2008, 12, 22)
    params = {
      tv_series: {
        tv_series_id:         tv_series(:tv_series1).id,
        seasons: {
          add:    [{
             name:             season_name,
             description:      description,
             poster_url:       poster_url,
             poster_file_id:   base_files(:image_file1).id,
             air_date:         air_date,
             season_number:    2
         }]
        }
      }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    season2 = o.tasks.select {|t| t.is_a?(Task::Model::Season::Create)}.first.model
    assert_not_nil season2
    assert_equal season_name, season2.name
    assert_equal description, season2.description
    assert_equal poster_url, season2.poster_url
    assert_equal 2, season2.season_number
    assert_equal air_date, season2.air_date
  end

  test 'delete season' do
    params = {
        tv_series: {
            tv_series_id:         tv_series(:tv_series1).id,
            seasons: {
                delete: [{season_number: 1}]
            }
        }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    assert_equal 0, tv_series.seasons.length
  end

  test 'change season' do
    season_name = 'the new season name'
    description = 'amnother descriptino'
    poster_url = 'http://no.where'
#    2008-01-19
    air_date = Date.new(2008, 1, 19)
    params = {
        tv_series: {
            tv_series_id:         tv_series(:tv_series1).id,
            tmdb_id:              1396,
            seasons: {
                change: [{
                   name:                  season_name,
                   description:           description,
                   poster_url:            poster_url,
#                   air_date:              air_date,
                   season_number:         1,
                   update_from_metadata:  true
                }]
            }
        }
    }
    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    season = tv_series.seasons.first
    assert_equal season_name, season.name
    assert_equal description, season.description
    assert_equal poster_url, season.poster_url
    assert_equal air_date, season.air_date
  end

  test 'add episode' do
    name = 'the new episode'
    description = 'jack gets a new dog'
    order = 2
    air_date = air_date = Date.new(2008, 1, 26)
    poster_url = 'http://no.where'
    poster_file_id = base_files(:image_file1).id
    episode_number = 2

    @plain_files << video_file_path_1 = get_test_video_file

    params = {
        tv_series: {
            tv_series_id:         tv_series(:tv_series1).id,
            tmdb_id:              1396, # breaking bad
            episodes: {
                add: [{
                    name:             name,
                    description:      description,
                    order:            order,
#                    air_date:         air_date,
                    poster_url:       poster_url,
                    poster_file_id:   poster_file_id,
                    episode_number:   episode_number,
                    season_number:    1,
                    update_from_metadata:  true
                }]
            },
            video_clips: {
              add: [
                {
                  season_number:    1,
                  episode_number:   episode_number,
                  path:             video_file_path_1,
                  share_id:         shares(:share_imported).id
                }
              ]
            }
        }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    season = tv_series.seasons.first
    assert_not_nil season
    episode = season.episodes.find {|e| e.episode_number == episode_number}
    assert_not_nil episode
    assert_equal name, episode.name
    assert_equal description, episode.description
    assert_equal order, episode.item_order
    assert_equal air_date, episode.air_date
    assert_equal poster_url, episode.poster_url
    assert_equal poster_file_id, episode.poster_file_id
    assert_equal 1, episode.video_clips.length

  end

  test 'delete episode' do
    params = {
        tv_series: {
            tv_series_id:         tv_series(:tv_series1).id,
            episodes: {
                delete: [
                    {
                        episode_number: collection_items(:episode1_in_season1).episode_number,
                        season_number: collections(:season1_in_tv_series1).season_number
                    }
                ]
            }
        }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    season = tv_series.seasons.first
    assert_equal 0, season.episodes.length
  end

  test 'change episode' do
    name = 'the change episode'
    description = 'jack gets a new cat'
    air_date = air_date = Date.new(2008, 11, 10)
    poster_url = 'http://no.where.too'
    poster_file_id = base_files(:image_file1).id

    video_file_id = clips(:video1_on_episode1).video_file.id

    params = {
        tv_series: {
            tv_series_id:         tv_series(:tv_series1).id,
            episodes: {
                change: [{
                    name:             name,
                    description:      description,
                    air_date:         air_date,
                    poster_url:       poster_url,
                    poster_file_id:   poster_file_id,
                    episode_number:   1,
                    season_number:    1,
               }]
            },
            video_clips: {
              delete: [
                {
                  season_number:      1,
                  episode_number:     1,
                  video_file_id:      clips(:video1_on_episode1).base_file_id,
                  delete_video_file:  true
                }
              ]
            }
        }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    season = tv_series.seasons.first
    episode = season.episodes.first
    assert_not_nil episode
    assert_equal 1, episode.episode_number
    assert_equal name, episode.name
    assert_equal description, episode.description
    assert_equal air_date, episode.air_date
    assert_equal poster_url, episode.poster_url
    assert_equal poster_file_id, episode.poster_file_id
    assert_nil BaseFile::VideoFile.find_by_id(video_file_id)
  end

  test 'add and remove video clip' do
    @video_files << video_file_1 = get_test_video_file
    params = {
        tv_series: {
            tv_series_id:             tv_series(:tv_series1).id,
            video_clips: {
                add: [
                    {
                        season_number:    1,
                        episode_number:   1,
                        set:              2,
                        order:            1,
                        video_file_id:    base_files(:video_file2).id,
                    },
                    {
                        season_number:    1,
                        episode_number:   1,
                        set:              2,
                        order:            2,
                        path:             video_file_1,
                        share_id:         shares(:share_imported).id
                    }
                ],
                delete: [{
                    season_number:    1,
                    episode_number:   1,
                    video_file_id:    clips(:video3_on_episode1).base_file_id,
                }],
                change: [
                    {
                        season_number:    1,
                        episode_number:   1,
                        set:              3,
                        order:            2,
                        video_file_id:    clips(:video1_on_episode1).base_file_id,
                    }
                ]
            }
        }
    }

    o = Order::Change::TvSeries.create_from_params(params)
    o.status = Order::Status::APPROVED
    o.save!
    o.run!

    message = o.message
    backtrace = o.backtrace
    assert_equal Order::Status::COMPLETED, o.status

    tv_series = o.tasks.select {|t| t.is_a?(Task::Model::TvSeries::Change) }.first.model
    season = tv_series.seasons.first
    episode = season.episodes.first
    clip_to_video2 = episode.video_clips.select {|vc| vc.video_file.id == base_files(:video_file2).id}.first
    clip_to_video1 = episode.video_clips.select {|vc| vc.video_file.id == base_files(:video_file1).id}.first
    clip_to_new_video = episode.video_clips.select {|vc| ![base_files(:video_file1).id, base_files(:video_file2).id].include?(vc.video_file.id)}.first

    assert_equal 3, episode.video_clips.length
    assert_equal 2, clip_to_video2.set
    assert_equal 1, clip_to_video2.order
    assert_equal 2, clip_to_new_video.set
    assert_equal 2, clip_to_new_video.order
    assert_nil episode.video_files.select {|vf| vf.id == base_files(:video_file3).id}.first
    assert_equal 3, clip_to_video1.set
    assert_equal 2, clip_to_video1.order

  end

end