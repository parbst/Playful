import Ember from 'ember';
import $ from 'jquery';
import _ from 'lodash';
import ENV from '../config/environment';
import ArtistMetadataModel from 'playful/models/artist-metadata';
import ReleaseMetadataModel from 'playful/models/release-metadata';
import humps from 'humps';

export default Ember.Object.extend({
  /* 
  {
    :text => {
      :artist_name => 'artist name',
    },
      :spotify => {
      :artist_id => 'driver specific id'
    }
  }
  */
  findArtists: function(input) {
    return $.ajax({
      url: ENV.APP.ENDPOINTS.metadata.artist,
      data: JSON.stringify(input),
      accepts: 'application/json',
      contentType: 'application/json; charset=UTF-8',
      method: 'POST',
      converters: {
        "text json": function(value) {
          var parsedResponse = $.parseJSON(value);
          return _.map(humps.camelizeKeys(parsedResponse), function(o){ return ArtistMetadataModel.create(o); });
        }
      }
    });
  },

  /*
  {
    :text => {
      :release_name => 'release name'
    },
    :spotify => {
      :release_id => 'driver specific id',
      :artist_id => 'driver specific artist id'
    }
  }
  */
  findReleases: function(input) {
    return $.ajax({
      contentType: 'application/json; charset=UTF-8',
      url: ENV.APP.ENDPOINTS.metadata.release,
      data: JSON.stringify(input),
      accepts: 'application/json',
      method: 'POST',
      converters: {
        "text json": function(value) {
          var parsedResponse = $.parseJSON(value);
          return _.map(humps.camelizeKeys(parsedResponse), function(o){ 
            var release = ReleaseMetadataModel.create(o);
            if(release.get('tracks')){
              release.set('tracks', _.map(release.get('tracks'), function(o){ 
                return Ember.Object.create(o); 
              }));
            }
            if(release.get('artists')){
              release.set('artists', _.map(release.get('artists'), function(o){ 
                return Ember.Object.create(o); 
              }));
            }
            return release;
          });
        }
      }
    });
  }
});
