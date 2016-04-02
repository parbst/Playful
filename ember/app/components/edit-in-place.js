import Ember from 'ember';

export default Ember.Component.extend({
  inEditMode: false,
  value: null,
  classNames: ['edit-in-place'],
  actions: {
    startEdit: function(){
      this.set('_inputValue', this.get('value'));
      this.toggleProperty('inEditMode');
    },
    cancelEdit: function(){
      this.toggleProperty('inEditMode');
    },
    stopEdit: function(){
      this.set('value', this.get('_inputValue'));
      this.toggleProperty('inEditMode');
    }
  },
  _inputValue: null,
  layout: Ember.Handlebars.compile(
    '{{#if inEditMode}}' +
      '{{input escape-press="cancelEdit" focus-out="cancelEdit" enter="stopEdit" value=_inputValue}}' +
    '{{else}}' +
      '{{value}}{{icon-fontawesome icon="pencil" pull="right" additionalClasses="clickable-icon" action="startEdit"}}' +
    '{{/if}}'
  ),
  focusInputFieldObserver: function(){
    if(this.get('inEditMode')){
      Ember.run.later(this, function(){
        var inputElement = this.get('childViews')[0].get('element');
        inputElement.focus();
        inputElement.select();
      }, 1);
    }
  }.observes('inEditMode')
});
