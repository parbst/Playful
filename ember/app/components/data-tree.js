import Ember from 'ember';
import _ from 'lodash';

export default Ember.Component.extend({
  model: null,
  plainModel: null,
  displayProperty: 'label',
  childrenProperty: 'children',
  classNames: ['data-tree'],
  internalModel: function(){
    var model = this.get('model'),
        plainModel = this.get('plainModel'),
        convert = function(obj){
            return _.map(_.keys(obj), function(key){
              var val = obj[key];
              if(val instanceof Date){
                val = moment(val).format('MMMM Do YYYY, HH:mm:ss');
              }
              if(Ember.typeOf(val) === 'object'){
                return { label: key, children: convert(val) };
              }
              else {
                return { label: key + ": " + val };
              }
            });
          };
    return model ? model : { children: convert(plainModel) };
  }.property('model', 'plainModel'),
  children: function(){
    return this.get('internalModel.' + this.get('childrenProperty'));
  }.property('childrenProperty', 'internalModel'),
  layout: Ember.Handlebars.compile(
    '<ul>' +
      '{{#each child in children}}' +
        '{{data-tree-node model=child parent=internalModel}}' +
      '{{/each}}' +
    '</ul>'
  )
});
