import Ember from 'ember';
import OrderlineControllerMixin from 'playful/mixins/orderline-controller';
import { DataTableColumn, DataTableColumnIconDefinition, DataTableGroupColumn } from 'playful/components/data-table';
import ReleaseMetadataModel from 'playful/models/release-metadata';
import _ from 'lodash';
import S from 'stringjs';

/* TODO:

- looking up metadata when selecting group that has artist/album
- sorting withing match by current track numbers/matches to match
- lookup artist if all tracks artist uniques to one
- playback from editing interface
- manual creation of album
- clear previous matches if starting new import
- make current tag values selectable by drop down
- highlight in editor if theres an album artist, when all artists are the same.

*/

var ImportTableEntry = Ember.Object.extend({
  audioFile: null,
  title: function(){
    return this.get('audioFile.trackTitle') || this.get('audioFile.fileName');
  }.property('audioFile', 'audioFile.trackTitle', 'audioFile.fileName'),
  audioFileAlbum: Ember.computed.alias('audioFile.album'),
  audioFileDirectory: Ember.computed.alias('audioFile.directory'),
  audioFileArtist: Ember.computed.alias('audioFile.artist'),
  audioFileAlbumArtist: Ember.computed.alias('audioFile.albumArtist'),
  validationMessage: function(){
    var res = [],
        album = this.get('audioFile.album'),
        artist = this.get('audioFile.artist'),
        trackTitle = this.get('audioFile.trackTitle'),
        trackNumber = this.get('audioFile.trackNumber');
    if(!trackTitle){
      res.push('missing track title');
    }
    if(!artist){
      res.push('missing artist');
    }
    if(album && !trackNumber){
      res.push('missing track number');
    }
    return _.map(res, function(s){ return S(s).capitalize().s; }).join(', ');
  }.property('audioFile.trackNumber', 'audioFile.album', 'audioFile.artist', 
             'audioFile.albumArtist', 'audioFile.trackTitle')
});

var ReleaseTableEntry = Ember.Object.extend({
  audioFile: null,
  number: function(){
    return this.get('audioFile.trackNumber') || '';
  }.property('audioFile', 'audioFile.trackNumber'),
  title: function(){
    return this.get('dummy') ? ' ' : this.get('audioFile.trackTitle');
  }.property('audioFile', 'audioFile.title', 'dummy'),
  dummy: false
});

var ReleaseMatch = Ember.Object.extend({
  releaseMetadata: null,
  audioFiles: Ember.A(),
  tableEntries: Ember.A(),
  selectedEntries: Ember.A(),
  updateTableEntries: function(){
    var audioFiles = this.get('audioFiles'),
        releaseMetadata = this.get('releaseMetadata'),
        tableEntries = _.map(audioFiles, function(af){ return ReleaseTableEntry.create({audioFile: af}); }),
        n = releaseMetadata && releaseMetadata.tracks ? releaseMetadata.tracks.length - tableEntries.length : 0;
    while(n--){
      tableEntries.pushObject(ReleaseTableEntry.create({dummy: true}));
    }
    this.set('tableEntries', tableEntries);
  }.observes('audioFiles', 'releaseMetadata').on('init')
});

var ImportTableGroupColumn = DataTableGroupColumn.extend({
  groupFn: function(model){
    // semantics: album > album artist > artist > dir
    var directory = model.get('audioFile.directory'),
        artist = (model.get('audioFile.albumArtist') || model.get('audioFile.artist')),
        album = model.get('audioFile.album');
    if(album && artist){
      return artist + ':' + album;
    }
    if(artist){
      return artist;
    }
    if(directory){
      return directory;
    }
    return false;
  },
  groupSortFn: function(modelA, modelB){
    return (modelA.get('audioFile.trackNumber') || 0) - (modelB.get('audioFile.trackNumber') || 0);
  },
  audioFiles: Ember.computed.mapBy('rows', 'audioFile'),
  modelObserver: function(){
    this.notifyPropertyChange('groups');
  }.observes('rows.@each.audioFileAlbum', 'rows.@each.audioFileDirectory',
             'rows.@each.audioFileArtist', 'rows.@each.audioFileAlbumArtist').on('init')
});

export default Ember.Controller.extend(OrderlineControllerMixin, {
  actions: {
    matchToRelease: function(){
      this._createRelease(this.get('selectedMetadataRelease'));
      this.set('selectedMetadataRelease', null);
      this.set('selectedMetadataArtist', null);
    },
    changeCover: function(releaseMetadata){
      var modelObj = Ember.Object.create({
        releaseMetadata: releaseMetadata,
        result: null,
        imageFiles: this.get('orderline.imageFiles')
      });
      modelObj.addObserver('result', function(me){
        releaseMetadata.set('frontCoverSrc', me.get('result'));
      });
      this.send('showModal', 'modal-release-cover', modelObj);
    },
    editSelectedImportTableEntryTags: function(){
      var nonDummies = _.filter(this.get('selectedImportTableEntries'), function(ite){ return !ite.get('dummy'); }),
          audioFiles = _.invoke(nonDummies, 'get', 'audioFile');
      this.send('showModal', 'modal-tag-editor', audioFiles);
    },
    cancelMatch: function(releaseMatch){
      this.get('importTableEntries').pushObjects(_.map(releaseMatch.get('audioFiles'), function(af){
        return ImportTableEntry.create({ audioFile: af });
      }));
      this.get('releaseMatches').removeObject(releaseMatch);
    },
    editSelectedReleaseMatchTags: function(releaseMatch){
      var audioFiles = _.invoke(releaseMatch.get('selectedEntries'), 'get', 'audioFile');
      this.send('showModal', 'modal-tag-editor', audioFiles);
    },
    placeInEmptyRelease: function(){
      this._createRelease(ReleaseMetadataModel.create({
        editable: true,
      }));
    },
    nextStep: function(){
      this.get('orderline').set('releaseMatches', this.get('releaseMatches'));
      this.nextStep();
    },
    guessRelease: function(){
      var selectedItem = _.chain(this.get('selectedImportTableEntries'))
                          .invoke('get', 'audioFile').first().value();
      if(selectedItem){
        var artist = selectedItem.get('artist'),
            albumArtist = selectedItem.get('albumArtist'),
            useArtist = albumArtist ? albumArtist : artist,
            album = selectedItem.get('album');
      }
    },
    metadataArtistMatch: function(){
      console.log('metadataArtistMatch');
    }
  },
  _createRelease: function(releaseMetadata){
      var selectedEntries = this.get('selectedImportTableEntries'),
          selectedFiles = _.invoke(selectedEntries, 'get', 'audioFile');
      var newMatch =  ReleaseMatch.create({
        releaseMetadata: releaseMetadata,
        audioFiles: selectedFiles
      });
      this.get('importTableEntries').removeObjects(selectedEntries);
      this.get('releaseMatches').pushObject(newMatch);
    },
  importTableEntries: Ember.A([
    ImportTableEntry.create({audioFile: Ember.Object.create({ title: 'track 1' })}),
    ImportTableEntry.create({audioFile: Ember.Object.create({ title: 'track 2' })}),
    ImportTableEntry.create({audioFile: Ember.Object.create({ title: 'track 3' })}),
  ]),
  _importTableColumns: Ember.A([
    DataTableColumn.create({ property: 'title' }),
    DataTableColumn.create({
      cellType: 'data-table-cell-tooltip-icon', 
      iconDefinition: DataTableColumnIconDefinition.create({ 
        fontAwesomeIcon: 'warning' 
      }),
      staticAttributes: { tooltipTextProperty: 'validationMessage' }
    }),
    ImportTableGroupColumn.create({ cellType: 'data-table-cell-group-audio-import' })
  ]),
  selectedImportTableEntries: Ember.A(),
  _releaseTableColumns: Ember.A([
    DataTableColumn.create({ property: 'title' }),
    DataTableColumn.create({ cellType: 'data-table-cell-fixed' })
  ]),
  selectedMetadataRelease: null,
  selectedMetadataArtist: null,
  releaseMatches: Ember.A(),
  allImportTableEntriesSelected: null,
  orderlineDidChange: function(){
    this.set('importTableEntries', _.map(this.get('orderline.audioFiles'), function(af){
      return ImportTableEntry.create({ audioFile: af });
    }));
  }.observes('orderline'),
  _automatedMetadataLookup: function(){
    var selectedImportTableEntries = this.get('selectedImportTableEntries'),
        artists = _.uniq(_.compact(_.invoke(selectedImportTableEntries, 'get', 'audioFileArtist'))),
        albumArtists = _.uniq(_.compact(_.invoke(selectedImportTableEntries, 'get', 'audioFileAlbumArtist'))),
        albums = _.uniq(_.compact(_.invoke(selectedImportTableEntries, 'get', 'audioFileAlbum'))),
        canSearch = selectedImportTableEntries.length > 1 && albums.length === 1 && 
              (artists.length === 1 || albumArtists.length === 1);

    if(canSearch){
      var artist = albumArtists.length === 1 ? _.first(albumArtists) : _.first(artists);
      console.log('searching for album ' + _.first(albums) + " by " + artist);
    }
  }.observes('selectedImportTableEntries.[]', 'selectedImportTableEntries.@each.audioFileAlbum',
    'selectedImportTableEntries.@each.audioFileArtist', 'selectedImportTableEntries.@each.audioFileAlbumArtist')
});
