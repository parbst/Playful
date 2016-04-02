import Ember from 'ember';

export default Ember.Object.extend({
  scans: Ember.A(),
  nextRoute: function(/* currentRoute */){
    throw "nextRoute must be implemented on child orderline!";
  }
});
