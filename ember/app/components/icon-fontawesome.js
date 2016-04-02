import Ember from 'ember';

export default Ember.Component.extend({
	icon: null,
  size: null,
  spin: false,
  pull: null,
  hide: false,
  additionalClasses: '',
  tagName: 'i',
  classNameBindings: ['_fontAwesomeClasses', 'hide'],
  click: function(){
    this.sendAction();
  },
  _fontAwesomeClasses: function(){
    var additionalClasses = this.get('additionalClasses'),
        fontSize = this.get('size'),
        pull = this.get('pull'),
        result = 'fa fa-' + this.get('icon');
    if(fontSize !== null){
      result += ' fa-' + fontSize;
    }
    if(this.get('spin')){
      result += ' fa-spin';
    }
    if(pull){
      result += ' pull-' + pull;
    }
    return result + ' ' + additionalClasses;
  }.property('icon'),
});
