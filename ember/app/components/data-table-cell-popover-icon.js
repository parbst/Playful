import Ember from 'ember';
import DataTableCellComponent from 'playful/components/data-table-cell';

export default DataTableCellComponent.extend({
  iconDef: function(){
    return this.get('column.iconDefinition');
  }.property('column', 'column.iconDefinition'),
  icon: function(){
    return this.get('iconDef').icon(this.get('model'));
  }.property('iconDef', 'model'),
  popoverComponent: function(){
    return this.get('column.popoverComponent');
  }.property('column', 'column.popoverComponent'),
  iconType: function(){
    var result = null;
    if(this.get('iconDef.isBootstrap')){
      result = 'bootstrap';
    }
    if(this.get('iconDef.isFontAwesome')){
      result = 'fontawesome';
    }
    return result;
  }.property('icon'),
  layout: function(){
    return Ember.Handlebars.compile(
      '{{#popover-icon iconType=iconType icon=icon ' +
                      'size=iconDef.fontAwesomeIconSize spin=iconDef.fontAwesomeSpin}}' +
        '{{' + this.get('popoverComponent') + ' model=model }}' +
      '{{/popover-icon}}');
  }.property('popoverComponent'),
   
});
