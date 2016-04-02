import Ember from 'ember';
import AudioOrderline from 'playful/models/audio-orderline';
import OrderlineControllerMixin from 'playful/mixins/orderline-controller';
import _ from 'lodash';
import ScanAdapter from 'playful/adapters/scan';

export default Ember.Controller.extend(OrderlineControllerMixin, {
  actions: {
    startAudioOrderLine: function() {
      this.nextStep(AudioOrderline.create({
        scans: this.get('allSelectedFiles'),
        store: this.get('store')
      }));
    }
  },
  isLoading: false,
  selectedFiles: Ember.A(),
  allSelectedFiles: Ember.A(),
  _cachedDirs: {},
  hideLoadingSpinner: function(){
    return !this.get('isLoading');
  }.property('isLoading'),
  selectedFilesObserver: function(){
    var selectedFiles = this.get('selectedFiles'),
        allSelectedFiles = this.get('allSelectedFiles'),
        cachedDirs = this.get('_cachedDirs');

    allSelectedFiles.clear();
    allSelectedFiles.addObjects(selectedFiles);
    var dirsToBeLoaded = [];
    var directories = _.filter(allSelectedFiles, function(f){ return f.get('isDirectory'); });
    _.each(directories, function(directory){
      var c = cachedDirs[directory.get('path')];
      if(Ember.typeOf(c) === 'array'){
        allSelectedFiles.addObjects(c);
      }
      else if (Ember.typeOf(c) === 'undefined'){
        dirsToBeLoaded.push(directory.get('path'));
      }
    });
    if(dirsToBeLoaded.length){
      var me = this, adapter = ScanAdapter.create();
      me.set('isLoading', true);
      _.each(dirsToBeLoaded, function(dirPath){ cachedDirs[dirPath] = false; });
      adapter.findByDir(dirsToBeLoaded, true).done(function(loadedFiles){
        allSelectedFiles = me.get('allSelectedFiles');
        _.merge(cachedDirs, _.groupBy(loadedFiles, function(file){
          return _.find(dirsToBeLoaded, function(dirPath){
            return new RegExp('^' + _.escapeRegExp(dirPath), 'i').test(file.get('path'));
          });
        }));
        _.each(_.intersection(dirsToBeLoaded, _.invoke(allSelectedFiles, 'get', 'path')), function(dirPath){
          allSelectedFiles.addObjects(cachedDirs[dirPath]);
        });
      }).always(function(){
        me.set('isLoading', false);
      });
    }
  }.observes('selectedFiles', 'selectedFiles.length')
});
