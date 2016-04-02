App.LoadSpinnerView = Ember.ContainerView.extend({
    tagName: 'div',
    attributeBindings: ['style'],
    style: '',
    display: false,
    displayDidChange: function(){
        var style = '';
        if(!this.get('display')){
            style = "display: none;"
        }
        this.set('style', style);
    }.observes('display'),
    classNames: ['followingBallsGParent load-spinner'],
    init: function(){
        this._super();
        this.displayDidChange();
    },
    childViews: [
        Ember.View.extend({
            classNames: ['followingBallsG_1', 'followingBallsG']
        }),
        Ember.View.extend({
            classNames: ['followingBallsG_2', 'followingBallsG']
        }),
        Ember.View.extend({
            classNames: ['followingBallsG_3', 'followingBallsG']
        }),
        Ember.View.extend({
            classNames: ['followingBallsG_4', 'followingBallsG']
        }),
    ]
})