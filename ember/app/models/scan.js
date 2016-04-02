import Ember from 'ember';
import _ from 'lodash';
import ENV from '../config/environment';

export default Ember.Object.extend({
  path: null,
  filename: function(){
    return _.last((this.get('path') || '').split('/'));
  }.property('path'),
  icon: function(){
    if(this.get('isDirectory')){
      return 'folder-o';
    }
    if(this.get('isArchive')){
      return 'file-archive-o';
    }
    if(this.get('isAudio')){
      return 'file-audio-o';
    }
    if(this.get('isImage')){
      return 'file-image-o';
    }
    if(this.get('isVideo')){
      return 'file-video-o';
    }
    return 'file-o';
  }.property('type'),
  isDirectory: function(){
    return this.get('type') === 'directory';
  }.property('type'),
  downloadUrl: function(){
    return ENV.APP.ENDPOINTS.download + "?path=" + encodeURIComponent(this.get('path'));
  }.property('path')
});
