// http://ember.guru/2014/master-your-modals-in-ember-js
import Ember from 'ember';
import _ from 'lodash';

export default Ember.Component.extend({
  close: 'removeModal',
  size: null, // width
  actions: {
    ok: function() {
      this.$('.modal').modal('hide');
      this.sendAction('ok');
    }
  },
  _modalClass: function(){
    var result = 'modal-dialog',
        size = (this.get('size') || '').toLowerCase();
    if(_.contains(['lg', 'large'], size)){
      result += ' modal-lg';
    }
    if(_.contains(['sm', 'small'], size)){
      result += ' modal-sm';
    }
    return result;
  }.property('size'),
  _showOkButton: function(){
    return !!this.get('ok');
  }.property('ok'),
  show: function() {
    this.$('.modal').modal().on('hidden.bs.modal', function() {
      this.sendAction('close');
    }.bind(this));
  }.on('didInsertElement')
});
