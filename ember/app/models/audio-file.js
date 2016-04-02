import DS from "ember-data";
import _ from 'lodash';
import BaseFileModel from 'playful/models/base-file';
import CheckpointableMixin from 'playful/mixins/checkpointable';

var AudioFileModel = BaseFileModel.extend(CheckpointableMixin, {
    artist:         DS.attr('string'),
    albumArtist:    DS.attr('string'),
    composer:       DS.attr('string'),
    album:          DS.attr('string'),
    trackTitle:     DS.attr('string'),
    trackNumber:    DS.attr('int'),
    trackTotal:     DS.attr('int'),
    discTotal:      DS.attr('int'),
    discNumber:     DS.attr('int'),
    comment:        DS.attr('string'),
    year:           DS.attr('date'),
    genre:          DS.attr('string'),
    bitRateType:    DS.attr('string'),
    bitRate:        DS.attr('int'),
    sampleRate:     DS.attr('int'),
    channelMode:    DS.attr('string'),
    duration:       DS.attr('float'),

    updateFromScan: function(scan) {
      var properties = ['artist', 'albumArtist', 'composer', 'album', 'trackTitle', 
        'trackNumber', 'trackTotal','year', 'genre', 'discNumber', 
        'discTotal', 'comment', 'duration'];
      this._super(scan);
      if (scan.get('tag')){
        _.each(properties, function(p){
          this.set(p, scan.get('tag.' + p));
        }, this);
      }
      if(scan.ffmpeg){
        this.set('bitRate', scan.get('ffmpeg.bitRateInKiloBytesPerSec'));
        if(scan.ffmpeg.audio){
          this.set('sampleRate', scan.get('ffmpeg.audio.sampleRateInHz'));
          this.set('channelMode', scan.get('ffmpeg.audio.channels'));
        }
      }
    }
});

AudioFileModel.reopenClass({
  fromScan: function(audioFileScan, store) {
    var result = store.createRecord('audioFile');
    result.updateFromScan(audioFileScan);
    return result;
  }
});

export default AudioFileModel;
