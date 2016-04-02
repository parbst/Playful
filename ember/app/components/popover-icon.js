import Ember from 'ember';
import PopoverBase from 'playful/components/popover-base';
import IconBootstrap from 'playful/components/icon-bootstrap';
import IconFontAwesome from 'playful/components/icon-fontawesome';
import _ from 'lodash';

export default PopoverBase.extend({
  tagName: 'div',
  iconType: 'fontawesome',
  icon: 'question',
  size: null,
  spin: null,
  popoverAttachment: function(){
    var iconComponent = _.find(this.get('childViews'), function(childView){
      return childView instanceof IconBootstrap || childView instanceof IconFontAwesome;
    });
    return iconComponent.$();
  }.property('iconType'),
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
    '{{/if}}' +
    '<div class="popoverJs hide">{{yield}}</div>'
  )
});

