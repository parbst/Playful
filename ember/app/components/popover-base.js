import Ember from 'ember';
import $ from 'jquery';
import _ from 'lodash';

export default Ember.Component.extend({
  tagName: 'div',      //whatever default you want... div is default anyway here
  classNames: '',      //whatever default you want
  placement: 'auto', //whatever default you want
  visible: false,
  popoverTitle: null,
  popoverAttachmentSelector: null,
  _popoverAdjustedAtPosition: null,
  popoverAttachment: function(){
    var popoverAttachmentSelector = this.get('popoverAttachmentSelector');
    if(popoverAttachmentSelector){
      return $(popoverAttachmentSelector);
    }
    return this.$();
  }.property('popoverAttachmentSelector'),
  mostSpaceDirection: function(){
    var bodyRect = document.body.getBoundingClientRect(),
        attachmentElement = this.get('popoverAttachment');

    var attachmentElementRect = attachmentElement[0].getBoundingClientRect(),
        toTop = attachmentElementRect.top,
        toBottom = bodyRect.bottom - attachmentElementRect.bottom,
        toLeft = attachmentElementRect.left + bodyRect.left,
        toRight = bodyRect.right - attachmentElementRect.right,
        distances = [
          { direction: 'top', distance: toTop },
          { direction: 'bottom', distance: toBottom },
          { direction: 'left', distance: toLeft },
          { direction: 'right', distance: toRight }
        ];

    return _.max(distances, function(dist){ return dist.distance; }).direction;
  },
  direction: function(){
    var direction = this.get('placement');
    if(direction === 'auto'){
      direction = this.mostSpaceDirection();
    }
    return direction;
  }.property('placement'),
  didInsertElement: function () {
    this._initBootstrapPopover();
  },
  _visibleObserver: function(){
    if(this.get('visible')){
      this._show();
    }
    else {
      this._hide();
    }
  }.observes('visible'),
  willDestroyElement: function () {
    this._destroyBootstrapPopover();
  },
  layout:  Ember.Handlebars.compile('<div class="popoverJs hide">{{yield}}</div>'),
  _initBootstrapPopover: function(){
    var component = this,
        contents = this.$('.popoverJs'),
        attachmentElement = this.get('popoverAttachment');
    attachmentElement.popover({
      animation: false,
      placement: component.get('direction'),
      html: true,
      title: component.get('popoverTitle'),
      content: contents
    }).on('show.bs.popover', function () {
      component.set('visible', true);
      contents.removeClass('hide');
    }).on('hide.bs.popover', function(){
      component.set('visible', false);
    });
  },
  _destroyBootstrapPopover: function(){
    this.$('div.popover .popoverJs').addClass('hide').appendTo(this.$()); // move content to safe spot
    this.get('popoverAttachment').popover('destroy');
  },
  init: function(){
    this._super();
    var resizeFunc = _.bind(this._windowResized, this),
        debouncedFunc = _.debounce(resizeFunc, 1000),
        throttledFunc = _.throttle(function(){
          resizeFunc();
          debouncedFunc();
        }, 300);
    $(window).on('resize orientationchange', throttledFunc);
  },
  _windowResized: function(){
    var mostSpaceDirection = this.mostSpaceDirection();
    if(this.get('visible')){
      if(mostSpaceDirection !== this.get('direction')){
        this.set('placement', mostSpaceDirection);
        this._destroyBootstrapPopover();
        this._initBootstrapPopover();
        this.set('visible', false);
        this.set('visible', true);  
      }
      else if (!this._isAdjusted()){
        this._show();
      }
    }
  },
  _show: function(){
    this.get('popoverAttachment').popover('show');
    this.set('_popoverAdjustedAtPosition', this.get('popoverAttachment').offset());
  },
  _hide: function(){
    this.get('popoverAttachment').popover('hide');
  },
  _isAdjusted: function(){
    var offset = this.get('popoverAttachment').offset(),
        prevPosition = this.get('_popoverAdjustedAtPosition');
    return offset.top === prevPosition.top && offset.left === prevPosition.left;
  }
});
