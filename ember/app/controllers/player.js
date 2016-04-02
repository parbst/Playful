import Ember from 'ember';

export default Ember.Controller.extend({
  actions: {
    play: function(){
      console.log("play action triggered", this.get('stamp'));
    }
  },
  init: function(){
    this.set('stamp', new Date().getTime());
  }
});
