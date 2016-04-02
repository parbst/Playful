import Ember from 'ember';
import _ from 'lodash';
import DataTableCellGroupComponent from 'playful/components/data-table-cell-group';

export default DataTableCellGroupComponent.extend({
  actions: {
    toggleSelect: function(){
      this.sendAction("toggleSelect", this.get('localGroup'));
    },
    sort: function(){
      this.sendAction("sort", this.get('column'), this.get('localGroup'));
    }
  },
  folder: function(){
    var allDirectories = _.uniq(_.invoke(this.get('group'), 'get', 'audioFile.directory'));
    return allDirectories.length === 1 ? _.first(allDirectories) : false;
  }.property('group', 'group.@each.audioFile.directory'),
  artist: function(){
    var allArtists = _.uniq(_.map(this.get('group'), function(row){
      return row.get('audioFile.albumArtist') || row.get('audioFile.artist');
    }));
    return allArtists.length === 1 ? _.first(allArtists) : false;
  }.property('group', 'group.@each.audioFile.albumArtist', 'group.@each.audioFile.artist'),
  isSortedByTrackNumber: function(){
    var localGroup = this.get('localGroup');
    return localGroup.length === 1 || _.every(localGroup, function(row, index, array) {
      // either it is the first element, or otherwise this element should 
      // not be smaller than the previous element.
      // spec requires string conversion
      var tn = row.get('audioFile.trackNumber');
      return index === 0 && _.isNumber(tn) || 
        index !== 0 && String(array[index - 1].get('audioFile.trackNumber')) <= String(tn);
    });
  }.property('localGroup', 'localGroup.@each.audioFile.trackNumber'),
  album: function(){
    var allArtists = _.uniq(_.map(this.get('group'), function(row){
      return row.get('audioFile.albumArtist') || row.get('audioFile.artist');
    }));
    var allAlbums = _.uniq(_.invoke(this.get('group'), 'get', 'audioFile.album'));
    return allArtists.length === 1 && allAlbums.length === 1 ? _.first(allAlbums) : false;
  }.property('group', 'group.@each.audioFile.albumArtist', 'group.@each.audioFile.artist',
             'group.@each.audioFile.album'),
  layout: Ember.Handlebars.compile(
    '{{#if album}}Album: {{album}}<br />{{/if}}' +
    '{{#if artist}}Artist: {{artist}}<br />{{/if}}' +
    '{{#if folder}}Folder: {{folder}}<br />{{/if}}' +
    '<button type="button" {{action "toggleSelect"}} class="btn btn-link"> ' +
      '{{#if isLocalGroupSelected}}Deselect{{else}}Select{{/if}} group' +
    '</button> ' +
    '{{#unless isSortedByTrackNumber}}' +
      '<button type="button" {{action "sort"}} class="btn btn-link">Sort by track number</button> ' +
    '{{/unless}}' +
    '<br />' +
    '{{value}}')
});