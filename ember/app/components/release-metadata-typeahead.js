import TwitterTypeaheadComponent from 'playful/components/twitter-typeahead';
import _ from 'lodash';
import Ember from 'ember';

export default TwitterTypeaheadComponent.extend({
  artistSelected: null,
  _filterContent: function(query) {
    var regex = new RegExp(query || '', 'i'),
        valueKey = this.get('valueToken'),
        artistSelected = this.get('artistSelected') || {},
        artistIdentifier = artistSelected.identifier || {};
    return this.get('content').sortBy(this.get('displayProperty')).filter(function(release){
      var releaseIdentifier = release.get('identifier') || {},
          releaseKeysWithArtistID = _.filter(_.keys(releaseIdentifier), function(k){ return !!releaseIdentifier[k].artistId; }),
          commonDrivers = _.intersection(_.keys(artistIdentifier), releaseKeysWithArtistID),
          commonArtist = _.find(commonDrivers, function(k){
            return releaseIdentifier[k].artistId === artistIdentifier[k].artistId;
          });
      return commonArtist && regex.test(Ember.get(release, valueKey));
    });
  }
});
