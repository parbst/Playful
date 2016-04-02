import Ember from 'ember';
import DataTableCellComponent from 'playful/components/data-table-cell';

export default DataTableCellComponent.extend({
  iconDef: function(){
    return this.get('column.iconDefinition');
  }.property('column'),
  icon: function(){
    return this.get('iconDef').icon(this.get('model'));
  }.property('iconDef', 'model'),
  layout: Ember.Handlebars.compile(
    '{{#if iconDef.isBootstrap}}' +
      '{{icon-bootstrap icon=icon}}' +
    '{{/if}}' +
    '{{#if iconDef.isFontAwesome}}' +
      '{{icon-fontawesome icon=icon size=iconDef.fontAwesomeIconSize spin=iconDef.fontAwesomeSpin}}' +
    '{{/if}}' +
    '{{#if value}}' +
      '&nbsp;' +
    '{{/if}}' +
    '{{value}}')
});
