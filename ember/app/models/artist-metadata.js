import Ember from 'ember';

/*

{
  identifier: {
    spotify: {
      artist_id: "spotify:artist:64mPnRMMeudAet0E62ypkx"
    }
  }
  artist_name: "Primus"
  popularity: "0.61"
}

*/

export default Ember.Object.extend({
  identifier:  null,
  artistName:   null
});
