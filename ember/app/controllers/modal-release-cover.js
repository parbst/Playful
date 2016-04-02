import Ember from 'ember';
import _ from 'lodash';

export default Ember.Controller.extend({
  selectedImageUrl: null,
  selectedImageFile: null,
  userProvidedUrl: null,
  curImageHeight: null,
  curImageWidth: null,
  urlToSearch: function(){
    var metadata = this.get('model.releaseMetadata'),
        releaseName = metadata.get('releaseName'),
        firstArtist = _.first(metadata.get('artists')),
        firstArtistName = firstArtist ? firstArtist.get('artistName') : '';
    return "https://www.google.dk/search?q=" + 
      encodeURIComponent('cover ' + releaseName + ' ' + firstArtistName) + '&tbm=isch';
  }.property('model'),
  actions: {
    ok: function(){
      this.get('model').set('result', this.get('selectedImageUrl'));
      this.send('removeModal');
    }
  },
  _selectedThumbNails: Ember.A(),
  selectedThumbNailsObserver: function(){
    var imageFile = _.first(this.get('_selectedThumbNails'));
    if(imageFile){
        this.setProperties({
          selectedImageFile: imageFile,
          selectedImageUrl: imageFile.get('downloadUrl')
        });
    }
  }.observes('_selectedThumbNails.[]'),
  userProvidedUrlObserver: function(){
    var userProvidedUrl = this.get('userProvidedUrl');
    this.setProperties({
      selectedImageFile: null,
      selectedImageUrl: userProvidedUrl
    });
  }.observes('userProvidedUrl'),
  _curLoaderId: null,
  selectedImageUrlObserver: function(){
    var url = this.get('selectedImageUrl'),
        me = this,
        myId = _.uniqueId('find_cover_');
    this.set('_curLoaderId', myId);
    var newImg = new Image();
    newImg.onload = function() {
      if(myId === me.get('_curLoaderId')){
        me.setProperties({
          curImageHeight: newImg.height,
          curImageWidth: newImg.width
        });
      }
    };
    newImg.src = url; 
  }.observes('selectedImageUrl')
});
