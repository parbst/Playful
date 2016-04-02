require 'test_helper'

class Order::ChangeAudioTest < ActiveSupport::TestCase
  fixtures :properties, :base_files, :shares, :collections, :collection_items, :clips

  def setup
    prepare_files_for_fixtures
  end

  def teardown
  end

  test "remove audio clip from track" do
    # track to change
    #   with audio_clip to remove (is it gone afterwards?)

    params = {
      order_type: "change_audio",
      tracks: {
        change: [
          {
            id: collection_items(:track1_in_release1).id,
            audio_clips: {
              delete: ["3"]
            }
          }
        ]
      }
    }

    t = Track.find(collection_items(:track1_in_release1).id)
    assert_equal 1, t.audio_files.length

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    t = Track.find(collection_items(:track1_in_release1).id)
    assert_equal 0, t.audio_files.length
  end

  test "delete track in release" do
    # track to delete
    #   appended to release (is it gone afterwards?)

    params = {
      order_type: "change_audio",
      tracks: {
        delete: [collection_items(:track1_in_release1).id]
      }
    }

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    r = Release.find(collections(:audio_release1).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    assert r.tracks.include?(t)
    assert !t.nil?

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    r = Release.find(collections(:audio_release1).id)
    t = Track.find_by_id(collection_items(:track1_in_release1).id)

    assert !r.tracks.include?(t)
    assert t.nil?
  end

  test "change release and update track and audio file tags" do
    # release to change
    #   with appended tracks. does the tracks and audio_files tagging change after changing the release?

    new_genre = 'changed genre'
    new_artist = 'changed artist'
    params = {
      order_type: "change_audio",
      releases: {
        change: [
          {
            id: collections(:audio_release1).id,
            artist: new_artist,
            genre: new_genre,
          }
        ]
      }
    }

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    r = Release.find(collections(:audio_release1).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    assert_not_equal new_genre, r.genre
    assert_not_equal new_artist, r.artist
    assert_equal r, t.release

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    r = Release.find(collections(:audio_release1).id)
    t = Track.find_by_id(collection_items(:track1_in_release1).id)

    assert_equal new_genre, r.genre
    assert_equal new_artist, r.artist

    t.audio_files.each do |af|
      assert_equal new_genre, af.genre
      assert_equal new_artist, af.album_artist
    end
  end

  test "delete release" do
    # release to delete
    #   with appended tracks. does the tracks know the release is deleted?

    params = {
      order_type: "change_audio",
      releases: {
        delete: [collections(:audio_release1).id]
      }
    }

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    r = Release.find(collections(:audio_release1).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    assert r.tracks.include?(t)
    assert_equal r, t.release

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    r = Release.find_by_id(collections(:audio_release1).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    assert t.release.nil?
    assert r.nil?
  end

  test "update release and tracks from metadata" do
    # release to update from metadata
    #   data must be different from updated metadata
    #   with tracks. are tracks updated properly after metadata update?

    params = {
      order_type: "change_audio",
      releases: {
        change: [
          {
              update_from_metadata: true,
              id: collections(:audio_release1).id,
              spotify_id: 'spotify:album:6G9fHYDCoyEErUkHrFYfs4' # basement jaxx remedy
          }
        ]
      }
    }

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    r = Release.find(collections(:audio_release1).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    new_artist = 'Basement Jaxx'
    new_year = 1999
    new_track1_title = 'Rendez-vu'
    new_track1_disc_number = 1
    new_track1_spotify_id = 'spotify:track:3zBhJBEbDD4a4SO1EaEiBP'

    assert_not_equal new_artist, r.artist
    assert_equal r, t.release

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    r = Release.find(collections(:audio_release1).id)
    t = Track.find_by_id(collection_items(:track1_in_release1).id)

    assert_equal new_artist, r.artist
    assert_equal new_year, r.year
    assert_equal new_track1_title, t.title
    assert_equal new_track1_disc_number, t.disc_number
    assert_equal new_track1_spotify_id, t.spotify_id

    af = t.audio_files[0]
    assert_equal new_artist, af.album_artist
    assert_equal 2517, af.year # from the track, not the release!
    assert_equal new_track1_title, af.track_title
    assert_equal new_track1_disc_number, af.disc_number
  end

  test "add primary track" do
    # audio file to delete
    #   is appended as clip to a track. does the track know, that the audio file is gone?

    params = {
      order_type: "change_audio",
      tracks: {
        change: [
          {
            id: collection_items(:track1_in_release1).id,
            audio_clips: {
              add: [
                {
                  audio_file_id: base_files(:audio_file1).id,
                  primary_track: true
                }
              ]
            }
          }
        ]
      }
    }

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    af_new = BaseFile::AudioFile.find(base_files(:audio_file1).id)
    af_cur = BaseFile::AudioFile.find(base_files(:audio_file2).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    assert_equal t, af_cur.reference_track
    assert af_new.reference_track.nil?

    import_order.run!

    puts import_order.backtrace
    puts import_order.message
    assert_equal Order::Status::COMPLETED, import_order.status

    t = Track.find_by_id(collection_items(:track1_in_release1).id)
    af_new = BaseFile::AudioFile.find(base_files(:audio_file1).id)

    assert_equal t, af_new.reference_track
  end

  test "delete audio file" do
    # audio file to append as primary track
    #   track with other audio file already appended as primary track

    params = {
      order_type: "change_audio",
      audio_files: {
        delete: [base_files(:audio_file2).id]
      }
    }

    import_order = Order::Change::Audio.create_from_params(params)
    import_order.status = Order::Status::APPROVED
    import_order.save!

    af = BaseFile::AudioFile.find(base_files(:audio_file2).id)
    af_id = base_files(:audio_file2).id
    t = Track.find(collection_items(:track1_in_release1).id)

    assert_equal t, af.reference_track
    assert t.audio_files.include?(af)

    import_order.run!

    af = BaseFile::AudioFile.find_by_id(base_files(:audio_file2).id)
    t = Track.find(collection_items(:track1_in_release1).id)

    assert af.nil?
    assert !t.audio_files.map(&:id).include?(af_id)
  end

end
