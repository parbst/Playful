import Ember from 'ember';
import _ from 'lodash';
import DataTableCellComponent from 'playful/components/data-table-cell';

// TODO: make (local) group selectable by one click
export default DataTableCellComponent.extend({
  attributeBindings: ['rowSpan:rowspan'],
  classNameBindings: ['_staticClass', '_colorClass'],
  _staticClass: 'data-table-cell-group',
  _colorClasses: ['blue', 'red', 'purple', 'green', 'silver', 'yellow'],
  _colorClass: function(){
    var idx = this.get('groupIndex'),
        colorClasses = this.get('_colorClasses');
    return colorClasses[idx % (colorClasses.length - 1)];
  }.property('groupIndex'),
  rowSpan: function(){
    return this.get('localGroup').length;
  }.property('localGroup'),
  layout: Ember.Handlebars.compile('{{value}}'),
  groups: Ember.computed.alias('column.groups'),
  group: function(){
    return this.get('column').getGroupForModel(this.get('model'));
  }.property('column', 'column.groups.@each'),
  localGroup: function(){
    return this.get('column').getLocalGroupForModel(this.get('model'), this.get('rowIndex'));
  }.property('column', 'column.groups.@each', 'column.rows.@each', 'rowIndex'),
  groupIndex: function(){
    return _.indexOf(this.get('groups'), this.get('group'));
  }.property('group', 'groups.@each'),
  value: function(){
    return this.get('group').length + ' total in group, ' + this.get('localGroup').length + ' local.';
  }.property('group', 'localGroup'),
  isLocalGroupSelected: function(){
    var localGroup = this.get('localGroup');
    return _.intersection(this.get('selectedRows'), localGroup).length === localGroup.length;
  }.property('selectedRows', 'selectedRows.@each','group', 'groups.@each')
});
