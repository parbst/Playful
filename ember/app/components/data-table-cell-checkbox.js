import Ember from 'ember';
import DataTableCellComponent from 'playful/components/data-table-cell';

export default DataTableCellComponent.extend({
  isSelected: false,
  name: '',
  classNames: ['data-table-cell-checkbox'],
  layout: Ember.Handlebars.compile(
  	'<div class="checkbox">' +
  	  '<label>' +
        '{{input type="checkbox" name=name checked=isSelected}} ' +
        '{{value}}' +
      '</label>' +
    '</div>'),
  actionObserver: function(){
    this.sendAction(this.get('isSelected') ? 'onSelected' : 'onUnSelected');
  }.observes('isSelected')
});
