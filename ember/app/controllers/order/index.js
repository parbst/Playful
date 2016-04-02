import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    toggleShowBacktrace: function(){
      this.set('showBacktrace', !this.get('showBacktrace'));
    }
  },

  init: function(){
    this.set('showBacktrace', false);
    window.store = this.store;
  },
});
