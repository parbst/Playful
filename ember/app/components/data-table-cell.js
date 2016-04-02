import Ember from 'ember';
import _ from 'lodash';

export default Ember.Component.extend({
  tagName: 'td',
  modelBinding: 'parentView.model',
  columnsBinding: 'parentView.columns',
  columnIndex: -1,
  rowIndexBinding: 'parentView.rowIndex',
  selectedRowsBinding: 'parentView.selectedRows',
  classNameBindings: ['isHidden:hidechild',':data-table-cell'],
  isHidden: false,
  removeCurObserver: function(){},
  column: function(){
    return this.get('columns').objectAt(this.get('columnIndex'));
  }.property('columns', 'columnIndex'),
  value: function(key, value) {
    var model = this.get('model'),
        property = this.get('column.property');
    if (arguments.length > 1) {
      model.set(property, value);
    }
    var notOk = !_.contains(['instance', 'object'], Ember.typeOf(model)) || Ember.isEmpty(property);
    return notOk ? '' : model.get(property);
  }.property('column.property'),
  layout: Ember.Handlebars.compile('{{value}}'),
  modelValueObserver: function(){
    this.removeCurObserver();
    var model = this.get('model'),
        property = this.get('column.property'),
        isOk = _.contains(['instance', 'object'], Ember.typeOf(model)) && !Ember.isEmpty(property);

    if(isOk){
      Ember.addObserver(model, property, this, '_notifyValue');
      this.removeCurObserver = _.once(function(){
       Ember.removeObserver(model, property, this, '_notifyValue'); 
      });
    }
  }.observes('column.property', 'model').on('init'),
  _notifyValue: function(){
    this.notifyPropertyChange('value');
  }
});
