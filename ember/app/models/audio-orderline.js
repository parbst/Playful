import Ember from 'ember';
import Orderline from 'playful/models/orderline';
import _ from 'lodash';
import AudioFileModel from 'playful/models/audio-file';
import ImageFileModel from 'playful/models/image-file';

export default Orderline.extend({
  audioFiles: Ember.A(),
  imageFiles: Ember.A(),
  releaseMatches: Ember.A(),
  store: null,
  routeMap: {
    'import.index': 'import.audio.tag',
    'import.audio.tag': 'import.selectShare'
  },
  nextRoute: function(currentRoute){
    return this.get('routeMap')[currentRoute];
  },
  scansDidChange: function(){
    var store = this.get('store'),
        audioScans = _.filter(this.get('scans'), function(s){ return s.get('isAudio'); }),
        imageScans = _.filter(this.get('scans'), function(s){ return s.get('isImage'); }),
        audioFiles = _.map(audioScans, function(s){ return AudioFileModel.fromScan(s, store); }),
        imageFiles = _.map(imageScans, function(s){ return ImageFileModel.fromScan(s, store); });
    this.set('audioFiles', Ember.A(audioFiles));
    this.set('imageFiles', Ember.A(imageFiles));
  }.observes('scans').on('init')
});
