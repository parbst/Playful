import Ember from 'ember';
import DataTableCellComponent from 'playful/components/data-table-cell';
import DynamicPropertyObservable from 'playful/mixins/dynamic-property-observable';

export default DataTableCellComponent.extend(DynamicPropertyObservable, {
  iconDef: function(){
    return this.get('column.iconDefinition');
  }.property('column', 'column.iconDefinition'),
  icon: function(){
    var iconDef = this.get('iconDef');
    return iconDef ? iconDef.icon(this.get('model')) : null;
  }.property('iconDef', 'model'),
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
  tooltipTextProperty: null,
  staticTooltipText: 'static text',
  isHidden: function(){
    return !this.get('model.validationMessage');
  }.property('model.validationMessage'),
  tooltipText: function(){
    var prop = this.get('tooltipTextProperty');
    return prop ? this.get('model').get(prop) : this.get('staticTooltipText');
  }.property('staticTooltipText', 'tooltipTextProperty'),
  init: function(){
    var me = this;
    this._super();
    this.registerDynamicChange('model', 'tooltipTextProperty', 'tooltipText');
  },
  layout: Ember.Handlebars.compile(
    '{{tooltip-icon ' +
       'iconType=iconType icon=icon ' +
       'size=iconDef.fontAwesomeIconSize ' +
       'spin=iconDef.fontAwesomeSpin ' +
       'text=tooltipText }}'
  )
});
