require 'test_helper'

class Order::ImportAudioTest < ActiveSupport::TestCase
  fixtures :properties, :base_files, :shares, :collections, :collection_items

  def setup
    prepare_files_for_fixtures
    @tag_driver = Playful::File::Driver::TagDriver.new
    @empty_audio_file = get_empty_audio_file
    @empty_audio_file2 = get_empty_audio_file
    @free_path = get_available_file_path
    @test_tags = {
        :artist             => "artist",
        :album_artist       => "album artist",
        :composer           => "composer",
        :album              => "album",
        :track_title        => "track title",
        :track_number       => 1,
        :track_total        => 2,
        :year               => 2013,
        :genre              => "Rockability",
        :disc_number        => 3,
        :disc_total         => 4,
        :comment            => "Banjo og Uve er hvor det kloer"
    }
  end

  def teardown
    [base_files(:audio_file1).path, @empty_audio_file, @empty_audio_file2, @free_path].each do |path|
      File.delete path if File.file? path
    end
  end

  test "create from params" do

    # add new stand alone track with new audio file
    # add existing audio file to existing track
    # change existing release, change existing track within release and add new audio file to that track
    # import entirely new album from metadata with one track and attach one existing audio track to that track

    test_params = {
      order_type: 'import_audio',
      tracks: [
        {
          artist:   'Great artist',
          composer: 'Some composer',
          title:    'Track title',
          comment:  'comments on tracks are almost never necessary',
          audio_files: [
            {
              audio_file_path:  @empty_audio_file,
              share_id:         2
            }
          ]
        }, {
          id:             collection_items(:track1).id,
          artist:         'The other artist',
          composer:       'The other composer',
          title:          'The title song',
          comment:        'A comment',
          audio_files: [
            {
              audio_file_id: base_files(:audio_file1).id, primary_track: true
            }
          ]
        }
      ],
      releases: [
        {
          id:                     collections(:audio_release1).id,
          artist:                 'Artist correction',
          track_total:            4,
          genre:                  'Another genre',
          is_compilation:         true,
          tracks: [
            {
              id:             collection_items(:track1_in_release1).id,
              artist:         nil,
              title:          'track 1 new title',
              audio_files: [
                {
                  audio_file_path:  @empty_audio_file2,
                  primary_track:    true,
                  share_id:         2
                }
              ]
            }
          ]
        }, {
          update_from_metadata:   true,
          spotify_id:             'spotify:album:6G9fHYDCoyEErUkHrFYfs4', # basement jaxx remedy
          tracks: [
              {
                track_number:   1,
                disc_number:    1,
                audio_files:    [ { audio_file_id:    base_files(:audio_file1).id } ]
              }
          ]
        }
      ]
    }

    import_order = Order::Import::Audio.create_from_params(test_params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    # check stand alone track
    new_stand_alone_track_params = test_params[:tracks][0]
    new_stand_alone_track_task = import_order.tasks.select { |t| t.is_a?(Task::Model::Track::Create) && t.artist == new_stand_alone_track_params[:artist] }.first
    assert_not_nil new_stand_alone_track_task
    new_stand_alone_track_model = new_stand_alone_track_task.model
    assert_equal new_stand_alone_track_params[:composer], new_stand_alone_track_model.composer
    assert_equal new_stand_alone_track_params[:title], new_stand_alone_track_model.title
    assert_equal new_stand_alone_track_params[:comment], new_stand_alone_track_model.comment
    assert_equal 1, new_stand_alone_track_model.audio_clips.length
    assert_equal new_stand_alone_track_params[:audio_files][0][:share_id], new_stand_alone_track_model.audio_clips.first.audio_file.share_id

    # existing track
    existing_stand_alone_track_params = test_params[:tracks][1]
    existing_stand_alone_track_task = import_order.tasks.select { |t| t.is_a?(Task::Model::Track::Change) && t.track_id == existing_stand_alone_track_params[:id] }.first
    assert_not_nil existing_stand_alone_track_task
    existing_stand_alone_track_model = existing_stand_alone_track_task.model
    assert_equal existing_stand_alone_track_params[:artist], existing_stand_alone_track_model.artist
    assert_equal existing_stand_alone_track_params[:composer], existing_stand_alone_track_model.composer
    assert_equal existing_stand_alone_track_params[:title], existing_stand_alone_track_model.title
    assert_equal existing_stand_alone_track_params[:comment], existing_stand_alone_track_model.comment
    assert_equal 1, existing_stand_alone_track_model.audio_clips.length
    assert_equal existing_stand_alone_track_params[:audio_files][0][:audio_file_id], existing_stand_alone_track_model.audio_clips.first.audio_file.id

    # existing release
    existing_release_params = test_params[:releases][0]
    existing_release_task = import_order.tasks.select { |t| t.is_a?(Task::Model::Release::Change) && t.model_id == existing_release_params[:id] }.first
    assert_not_nil existing_release_task
    existing_release_model = existing_release_task.model
    assert_equal existing_release_params[:artist], existing_release_model.artist
    assert_equal existing_release_params[:track_total], existing_release_model.track_total
    assert_equal existing_release_params[:genre], existing_release_model.genre
    assert_equal existing_release_params[:is_compilation], existing_release_model.is_compilation
    assert_equal 1, existing_release_model.tracks.length

    # new release
    new_release_params = test_params[:releases][1]
    new_release_task = import_order.tasks.select { |t| t.is_a?(Task::Model::Release::Create) && t.spotify_id == new_release_params[:spotify_id] }.first
    assert_not_nil new_release_task
    new_release_model = new_release_task.model
    assert_equal 'Remedy', new_release_model.title
    assert_equal 'Basement Jaxx', new_release_model.artist
    assert_equal 1, new_release_model.tracks.length

    # existing track in release
    existing_release_track_params = existing_release_params[:tracks][0]
    existing_release_track_task = import_order.tasks.select { |t| t.is_a?(Task::Model::Track::Change) && t.track_id == existing_release_track_params[:id] }.first
    assert_not_nil existing_release_track_task
    existing_release_track_model = existing_release_track_task.model
    assert_equal existing_release_track_params[:artist], existing_release_track_model.artist
    assert_equal existing_release_track_params[:title], existing_release_track_model.title
    assert_equal 2, existing_release_track_model.audio_clips.length

    # new track in release
    new_release_track_params = new_release_params[:tracks].first
    new_release_track_task = import_order.tasks.select { |t| t.is_a?(Task::Model::Track::Create) && t.model.collection_id == new_release_model.id }.first
    assert_not_nil new_release_track_task
    new_release_track_model = new_release_track_task.model
    assert_equal new_release_track_params[:track_number], new_release_track_model.track_number
    assert_equal new_release_track_params[:disc_number], new_release_track_model.disc_number
    assert_equal 'Rendez-vu', new_release_track_model.title
    assert_equal 1, new_release_track_model.audio_clips.length

    # stand alone track audio file
    new_stand_alone_track_audio_file_model = new_stand_alone_track_model.audio_files.first
    assert_equal new_stand_alone_track_params[:artist], new_stand_alone_track_audio_file_model.artist
    assert_equal new_stand_alone_track_params[:composer], new_stand_alone_track_audio_file_model.composer
    assert_equal new_stand_alone_track_params[:title], new_stand_alone_track_audio_file_model.track_title
    assert_equal new_stand_alone_track_params[:comment], new_stand_alone_track_audio_file_model.comment
    assert new_stand_alone_track_model.audio_clips.first.primary_track

    # existing stand alone track
    existing_stand_alone_track_audio_file_model = existing_stand_alone_track_model.audio_files.first
    assert_equal existing_stand_alone_track_params[:artist], existing_stand_alone_track_audio_file_model.artist
    assert_equal existing_stand_alone_track_params[:composer], existing_stand_alone_track_audio_file_model.composer
    assert_equal existing_stand_alone_track_params[:title], existing_stand_alone_track_audio_file_model.track_title
    assert_equal existing_stand_alone_track_params[:comment], existing_stand_alone_track_audio_file_model.comment
    assert existing_stand_alone_track_model.audio_clips.first.primary_track

    # existing track in existing release
    existing_release_track_audio_file_model = existing_release_track_model.audio_files.first
    assert_equal existing_release_params[:artist], existing_release_track_audio_file_model.album_artist
    assert_equal existing_release_params[:track_total], existing_release_track_audio_file_model.track_total
    assert_equal existing_release_model.title, existing_release_track_audio_file_model.album
    assert_equal existing_release_params[:genre], existing_release_track_audio_file_model.genre
    assert existing_release_track_audio_file_model.artist.blank?
    assert_equal existing_release_track_params[:title], existing_release_track_audio_file_model.track_title

    # new track in new release
    new_release_track_audio_file_model = new_release_track_model.audio_files.first
    assert_not_equal new_release_track_model, new_release_track_audio_file_model.reference_track

  end

  test "attach audio" do
    track = collection_items(:track1_in_release1)
    audio_file = base_files(:audio_file1)
    ac = AudioClip.ensure(audio_file: audio_file, set: 1, model: track)
    ac.save!
  end

end
