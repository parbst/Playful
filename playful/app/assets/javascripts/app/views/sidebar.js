/*
App.SideMenuItemView = Em.View.extend({
    tagName: 'li',
    selected: false,
    classNameBindings: ['selected'],
    title: '',
    template: Ember.Handlebars.compile('{{title}}')
});

App.SideMenuView = Em.CollectionView.extend({
    tagName: 'ul',
    classNames: ['menu', 'active'],
    active: function(){
        this.get('childViews')
    }.property('childViews'),
    itemViewClass: 'App.SideMenuItemView',
    actions: {
    }
});
*/

App.SideMenuItemsView = Em.View.extend({
    items: Em.A(),
    parentItem: null,
    tagName: 'ul',
    classNames: ['menu'],
    classNameBindings: ['highlight:active'],
    isLeaf: function(){
        return _.isEmpty(_.flatten(_.invoke(this.get('items'), 'get', 'children')))
    }.property(),
    parentSelected: function(){
        return !this.get('parentItem') || this.get('parentItem.selected')
    }.property('parentItem', 'parentItem.selected'),
    display: function(){
        var recurse = function(items){
            return _.some(_.invoke(items, 'get', 'selected')) ||
                _.some(_.map(_.invoke(items, 'get', 'children'), recurse))
        };
        return this.get('parentSelected') || recurse(this.get('items'));
    }.property('items.@each.selected', 'parentSelected'),
    highlight: function(){
        return this.get('isLeaf') && this.get('display');
    }.property('isLeaf', 'display'),
    template: Ember.Handlebars.compile(
        '{{#if view.display}}' +
            '{{#each item in view.items}}' +
                '<li {{bindAttr class="item.selected:selected"}}>' +
                    '<span {{action menuItemClicked item}}>{{item.title}}</span>' +
                        '{{view App.SideMenuItemsView items=item.children parentItem=item}}' +
                '</li>' +
            '{{/each}}' +
        '{{/if}}')
});

App.SidebarView = Em.View.extend({
    expanded: true,
    classNameBindings: ['standardClass', 'collapsedClass'],
    standardClass: 'sidebar',
//    templateName: 'sidebar',
    actions: {
        toggleExpand: function(){
            this.set('expanded', !this.get('expanded'));
        }
    },
    collapsedClass: function(){
        if(!this.get('expanded')){
            return 'collapsed'
        }
    }.property('expanded')
});
