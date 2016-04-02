import Ember from 'ember';
import _ from 'lodash';
import S from 'stringjs';

var TwoColumnEditRowObject = Ember.Object.extend({
  prop: null,
  model: null,
  readOnly: false,
  name: function(){
    return S(this.get('prop')).humanize().s;
  }.property('prop'),
  value: function(key, value){
    var model = this.get('model'),
        property = this.get('prop');
    if (arguments.length > 1) {
      model.set(property, value);
    }
    var notOk = !_.contains(['instance', 'object'], Ember.typeOf(model)) || Ember.isEmpty(property);
    return notOk ? '' : model.get(property);
  }.property('prop', 'model'),
  removeCurObserver: function(){},
  modelValueObserver: function(){
    this.removeCurObserver();
    var model = this.get('model'),
        property = this.get('prop');
    if(!Ember.isEmpty(model) && !Ember.isEmpty(property)){
      Ember.addObserver(model, property, this, '_notifyValue');
      this.removeCurObserver = _.once(function(){
       Ember.removeObserver(model, property, this, '_notifyValue'); 
      });
    }
  }.observes('prop', 'model').on('init'),
  _notifyValue: function(){
    this.notifyPropertyChange('value');
  }
});

export default Ember.Component.extend({
  title: null,
  model: null,
  classNames: 'two-column-edit',
  properties: Ember.A(),
  readOnlyProperties: Ember.A(),
  displayProperties: function(){
    var model = this.get('model'),
        ro = this.get('readOnlyProperties');
    return _.map(this.get('properties'), function(prop){
      return TwoColumnEditRowObject.create({
        prop: prop,
        readOnly: _.contains(ro, prop),
        model: model
      });
    });
  }.property('properties', 'readOnlyProperties'),
  layout: Ember.Handlebars.compile(
    '<div class="outer">' +
      '{{#if title}}' +
        '{{title}}' +
      '{{/if}}' +
      '{{#each prop in displayProperties}}' +
        '<div class="rows clearfix">' +
          '<div>' +
            '{{prop.name}}' +
          '</div>' +
          '<div>' +
            '{{#if prop.readOnly }}' +
              '{{prop.value}}' +
            '{{else}}' + 
              '{{edit-in-place value=prop.value}}' +
            '{{/if}}' +
          '</div>' +
        '</div>' +
      '{{/each}}' +
    '</div>'
  )
});
