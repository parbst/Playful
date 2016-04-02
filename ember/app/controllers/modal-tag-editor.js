import Ember from 'ember';
import _ from 'lodash';

export default Ember.Controller.extend({
  checkpointId: null,
  actions: {
    ok: function(){
      // do nothing, changes are automatically accepted
      this.set('checkpointId', null);
    },
    cancel: function(){
      var model = this.get('model'),
          checkpointId = this.get('checkpointId');
      if(model && checkpointId){
        _.invoke(model, 'rollbackToCheckpoint', checkpointId);
      }
      this.send('removeModal');
    }
  },
  modelObserver: function(){
    var model = this.get('model');
    if(model){
      this.set('checkpointId', _.uniqueId('edit_tags_'));
      _.invoke(model, 'checkpoint', this.get('checkpointId'));
    }
  }.observes('model').on('init')
});
