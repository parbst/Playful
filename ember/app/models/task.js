import Ember from 'ember';
import DS from "ember-data";
import S from 'stringjs';

export default DS.Model.extend({
    type: DS.attr('string'),
    status: DS.attr('string'),
    error: DS.attr('string'),
    sequence: DS.attr('number'),
    createdAt: DS.attr('date'),
    updatedAt: DS.attr('date'),
    message: DS.attr('string'),
    backtrace: DS.attr('string'),
    overwrite_model_values: DS.attr('boolean'),
    order: DS.belongsTo('order', {inverse: 'tasks', async: true}),

    displayType: function(){
      return S(this.get('type')).humanize().s;
    }.property('type'),

    isFailed: function(){
      return this.get('status') === 'failed';
    }.property('status'),

    isRunning: function(){
      return this.get('status') === 'running';
    }.property('status'),

    isPending: function(){
      return this.get('status') === 'pending';
    }.property('status'),

    isCompleted: function(){
      return this.get('status') === 'completed';
    }.property('status'),

    displayStatus: function(){
      return Ember.String.capitalize(this.get('status') || '');
    }.property('status'),

    displayCreatedAt: function(){
      var t = moment(this.get('createdAt'));
      return t.format('MMMM Do YYYY, HH:mm:ss') + " (" + t.fromNow() + ")";
    }.property('createdAt'),

    displayUpdatedAt: function(){
      var t = moment(this.get('updatedAt'));
      return t.format('MMMM Do YYYY, HH:mm:ss') + " (" + t.fromNow() + ")";
    }.property('updatedAt')
});
