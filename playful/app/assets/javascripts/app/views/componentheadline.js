App.ComponentHeadlineView = Ember.ContainerView.extend({
    loading: false,
    title: 'Title',
    tagName: 'div',
    classNames: ['component-header'],
    childViews: ['titleView', 'spinnerView', 'clearView'],
    titleView: Ember.View.extend({
        tagName: 'p',
        template  : Ember.Handlebars.compile('{{view.parentView.title}}')
    }),
    spinnerView: App.LoadSpinnerView.extend({
        displayBinding: 'parentView.loading',
    }),
    clearView: Ember.View.extend({
        tagName: 'div',
        classNames: ['clear'],
    })
})

