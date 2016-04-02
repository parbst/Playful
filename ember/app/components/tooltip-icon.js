import Ember from 'ember';
import IconBootstrap from 'playful/components/icon-bootstrap';
import IconFontAwesome from 'playful/components/icon-fontawesome';
import _ from 'lodash';

export default Ember.Component.extend({
  tagName: 'div',
  iconType: 'fontawesome',
  icon: 'question',
  size: null,
  spin: null,
  text: null,
  isFontAwesome: function(){ 
    return this.get('iconType') === 'fontawesome'; 
  }.property('iconType'),
  isBootstrap: function(){ 
    return this.get('iconType') === 'bootstrap'; 
  }.property('iconType'),
  layout:  Ember.Handlebars.compile(
    '{{#if isBootstrap}}' +
      '{{icon-bootstrap icon=icon}}' +
    '{{/if}}' +
    '{{#if isFontAwesome}}' +
      '{{icon-fontawesome icon=icon size=size spin=spin}}' +
    '{{/if}}'
  ),
  iconSelector: function(){
    var iconComponent = _.find(this.get('childViews'), function(childView){
      return childView instanceof IconBootstrap || childView instanceof IconFontAwesome;
    });
    return iconComponent.$();
  }.property('iconType'),
  willDestroyElement: function () {
    this._destroyBootstrapTooltip();
  },
  didInsertElement: function () {
    this._initBootstrapTooltip();
  },
  _initBootstrapTooltip: function(){
    this.get('iconSelector').tooltip({
      title: this.get('text')
    });
  },
  _destroyBootstrapTooltip: function(){
    this.get('iconSelector').tooltip('destroy');
  },
  _textObserver: function(){
    this.get('iconSelector').tooltip({
      title: this.get('text')
    });
  }.observes('text')
});

