import Ember from 'ember';
import DS from "ember-data";

export default DS.ActiveModelSerializer.extend({
  keyForAttribute: function(attr) {
    return Ember.String.underscore(attr);
  },
  normalizePayload: function(payload) {
    if(payload.task && payload.task.type){
      payload[payload.task.type] = payload.task;
    }
    return this._super.apply(this, arguments);
  }
});