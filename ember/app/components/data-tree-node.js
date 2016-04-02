import Ember from 'ember';

export default Ember.Component.extend({
  model: null,
  parent: null,
  tagName: 'li',
  expanded: false,
  displayPropertyBinding: 'parentView.displayProperty',
  childrenPropertyBinding: 'parentView.childrenProperty',
  display: function(){
    return this.get('model.' + this.get('displayProperty'));
  }.property('displayProperty', 'model'),
  children: function(){
    return this.get('model.' + this.get('childrenProperty'));
  }.property('childrenProperty', 'model'),
  actions:{
    toggleExpand: function(){
      this.toggleProperty('expanded');
    }
  },
  icon: function(){
    return this.get('expanded') ? 'minus-square-o': 'plus-square-o';
  }.property('expanded'),
  layout: Ember.Handlebars.compile(
    '{{#if children}}' +
      '{{icon-fontawesome icon=icon action="toggleExpand"}}' +
    '{{/if}}' +
    '<div class="display">{{display}}</div>' +
    '{{#if expanded}}' +
      '<ul>' +
        '{{#each child in children}}' +
          '{{data-tree-node model=child parent=model}}' +
        '{{/each}}' +
      '</ul>' +
    '{{/if}}'
  )

});
