import Ember from 'ember';

export default Ember.Controller.extend({
  model: Ember.A(),
  treeData: function(){
    return JSON.parse(JSON.stringify(this.get('model')[0] || {}));
  }.property('model'),
});
