import Ember from 'ember';
import DataTableCell from 'playful/components/data-table-cell';

export default DataTableCell.extend({
  tagName: 'th',
  column: null,
  draggable: false,
  sortedByColumnBinding: 'parentView.parentView.sortedByColumn',
  isSortedReverselyBinding: 'parentView.parentView.isSortedReversely',
  isSortableBinding: 'parentView.parentView.isSortable',
  classNameBindings: ['isSorted', 'defaultClass'],
  defaultClass: 'data-table-header-cell',
  isSorted: function(){
    return this.get('sortedByColumn') === this.get('column');
  }.property('column', 'sortedByColumn'),
  sortIcon: function(){
    return this.get('isSorted') && this.get('isSortedReversely') ? 'sort-asc' : 'sort-desc';
  }.property('isSorted', 'isSortedReversely'),
  canBeSortedBy: function(){
    return this.get('column.header') && this.get('isSortable');
  }.property('column.header', 'isSortable'),
  actions: {
    iconClicked: function(){
      this.sendAction('action', this.get('column'));
    }
  },
  layout: Ember.Handlebars.compile(
    '{{column.header}}' +
    '&nbsp;&nbsp;' +
    '{{#if canBeSortedBy}}' +
      '{{icon-fontawesome icon=sortIcon action="iconClicked"}}' +
    '{{/if}}' 
  )
});
