import Ember from 'ember';
import _ from 'lodash';

/*
partial 

{
  identifier: {
    spotify: {
      release_id: "spotify:album:58nleds6QOiTMJUdyM6EdN"
      artist_id: "spotify:artist:64mPnRMMeudAet0E62ypkx"
    }
  }
  release_name: "Primus & The Chocolate Factory With The Fungi Ensemble"
  release_date: "2014"
}

full

{
  identifier: {
    spotify: {
      release_id: "spotify:album:0kOQO9vavKO2O6iUOusbMM"
      artist_id: "spotify:artist:64mPnRMMeudAet0E62ypkx"
    }
  }
  release_name: "Sailing The Seas Of Cheese"
  release_date: "1991"
  release_type: "album"
  tracks: [
    {
      identifier: {
        spotify: {
          track_id: "spotify:track:6JabPnsIvQngxLDu3qgtJk"
        }
      }
      disc_number: 1
      duration: 42.733
      title: "Seas Of Cheese"
      track_number: 1
      popularity: "0.23000"
      artists: [
        {
          identifier: {
            spotify: {
              artist_id: "spotify:artist:64mPnRMMeudAet0E62ypkx"
            }
          }
          artist_name: "Primus"
        }
      ]
    }
    .
    .
    .
  ]
  artists: [
    {
      identifier: {
        spotify: {
          artist_id: "spotify:artist:64mPnRMMeudAet0E62ypkx"
        }
      }
      artist_name: "Primus"
    }
  ]
}

*/

export default Ember.Object.extend({
  identifier:     {},
  releaseName:    null,
  releaseDate:    null,
  releaseType:    null,
  tracks:         null,
  artists:        null,
  frontCoverSrc:  null, 
  editable:       false,
  genre:          null,

  updateFrom: function(otherRelease){
    _.each(['tracks', 'artists', 'releaseType'], function(key){
      this.set(key, otherRelease.get(key));
    }, this);
  }
});
