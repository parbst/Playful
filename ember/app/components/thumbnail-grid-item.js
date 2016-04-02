import Ember from 'ember';
import $ from 'jquery';
import _ from 'lodash';

export default Ember.Component.extend({
  classNameBindings: ['selected', 'staticClasses', 'clearLeft'],
  attributeBindings: ['href'],
  tagName: 'a',
  href: '#',
  model: null,
  selected: false,
  staticClasses: 'thumbnail-grid-item thumbnail',
  srcPropBinding: 'parentView.imageSrcProperty',
  descPropBinding: 'parentView.imageDescriptionProperty',
  isSelectableBinding: 'parentView.isSelectable',
  isSelectMultipleBinding: 'parentView.isSelectMultiple',
  _getProp: function(propName){
    var model = this.get('model'),
        prop = this.get(propName),
        notOk = !_.contains(['instance', 'object'], Ember.typeOf(model)) || Ember.isEmpty(prop);
    return notOk ? '' : model.get(prop);
  },
  src: function(){
    return this._getProp('srcProp');
  }.property('srcProp', 'model'),
  desc: function(){
    return this._getProp('descProp');
  }.property('descProp', 'model'),
  actions: {
    click: function() {
      this.sendAction('action', this, this.get('model'));
    }
  },
  clearfix: false,
  handleResize: function() {
    var childViews = this.get('parentView.childViews'),
        myIdx = _.indexOf(childViews, this),
        firstRowTop = null,
        topRow = _.takeWhile(childViews, function(cv){
          var top = cv.$().offset().top;
          if(firstRowTop === null){
            firstRowTop = top;
          }
          return top === firstRowTop;
        });
    this.set('clearLeft', myIdx !== 0 && myIdx % topRow.length === 0);
  }.on('didInsertElement'),
  bindResizeEvent: function() {
    $(window).on('resize', _.bind(this.set, this, 'clearLeft', false));
    $(window).on('resize', _.debounce(_.bind(this.handleResize, this), 300));
  }.on('init'),
  layout: Ember.Handlebars.compile(
    '<img {{action "click"}} {{bind-attr src="src"}} />' +
    '<div {{action "click"}} class="caption" >' +
      '{{#if desc}}' +
        '<p>{{desc}}</p>' +
      '{{/if}}' +
      '{{#if selected}}' +
        '<p>{{icon-fontawesome icon="check"}}</p>' +
      '{{/if}}' +
    '</div>'
  )
});

