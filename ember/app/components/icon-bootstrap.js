import Ember from 'ember';

export default Ember.Component.extend({
	icon: null,
  tagName: 'span',
  attributeBindings: ['ariaHidden:aria-hidden'],
  classNameBindings: ['_bootstrapClasses'],
  ariaHidden: 'true',
  _bootstrapClasses: function(){
    return 'glyphicon glyphicon-' + this.get('icon');
  }.property('icon')
});