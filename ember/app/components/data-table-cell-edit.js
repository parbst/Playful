import Ember from 'ember';
import DataTableCellComponent from 'playful/components/data-table-cell';

export default DataTableCellComponent.extend({
  inEditMode: false,
  classNames: ['data-table-cell-edit'],
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
