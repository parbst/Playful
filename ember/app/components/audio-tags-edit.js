import Ember from 'ember';
import TwoColumnEdit from 'playful/components/two-column-edit';
import _ from 'lodash';

var AudioTagsTwoColumnEditProperties = Ember.A([
  'artist', 'albumArtist', 'composer', 'album', 'trackTitle', 'trackNumber', 'trackTotal', 'discTotal', 
  'discNumber', 'comment', 'year', 'genre', 'bitRateType', 'bitRate', 'sampleRate', 'channelMode', 'duration', 'path'
]);

var AudioTagsTwoColumnEditModel = Ember.Object.extend({
  audioFiles: Ember.A(),
  get: function(propName){
    if(_.contains(AudioTagsTwoColumnEditProperties, propName)){
      var allVals = _.invoke(this.get('audioFiles'), 'get', propName),
          uniqVals = _.uniq(allVals);
      if(uniqVals.length === 1){
        return _.first(uniqVals);
      }
      else {
        return '<' + uniqVals.join(', ') + '>';
      }
    }
    else {
      return this._super.apply(this, arguments);
    }
  },
  set: function(propName, newValue){
    if(_.contains(AudioTagsTwoColumnEditProperties, propName)){
      _.invoke(this.get('audioFiles'), 'set', propName, newValue);
    }
    else {
      return this._super.apply(this, arguments);
    }
  }
});

export default TwoColumnEdit.extend({
  classNames: 'two-column-edit audio-tags-edit',
  audioFiles: Ember.A(),
  properties: AudioTagsTwoColumnEditProperties,
  model: function(){
    return AudioTagsTwoColumnEditModel.create({ audioFiles: this.get('audioFiles') });
  }.property('audioFiles'),
  readOnlyProperties: function(){
    return ['bitRateType', 'bitRate', 'sampleRate', 'channelMode', 'duration', 'path'];
  }.property(),
});
