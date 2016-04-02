App.IframeView = Ember.View.extend({
    iframeSource: '',
    defaultTemplate: Ember.Handlebars.compile('<iframe></iframe>'),
    loading: false,
    iframeDidLoad: function(){
        this.set('loading', false);
    },
    didInsertElement: function(){
        var me = this, iframe = this.get('iframe');
        iframe.load(function() {
            me.iframeDidLoad();
        });
        this.iframeSourceDidChange();
    },
    iframeSourceDidChange: function(){
        var iframe = this.get('iframe'),
            src = this.get('iframeSource');
        iframe.attr('src', src);
        if(src){
            this.set('loading', true);
        }
    }.observes('iframeSource'),
    iframe: function(){
        return $('iframe', $(this.get('element')));
    }.property()
});

App.HiddenIframeView = App.IframeView.extend({
    defaultTemplate: Ember.Handlebars.compile('<iframe width="800" height="1500" style="visibility: hidden; position: absolute;"></iframe>'),
});

/*
App.YahooImageSearch = App.HiddenIframeView.extend({
    query: '',
    results: Em.A(),
    iframeSource: function(){
        var query = this.get('query');
        if(query){
            return "http://images.search.yahoo.com/search/images?p=" + encodeURIComponent(this.get('query'))            
        }
    }.property('query'),
    iframeDidLoad: function(){
        this._super();
        var res = [],
            childWindow = this.getIframe()[0].contentWindow;
        if(childWindow.Y){
            childWindow.Y.all('img').each(function(imgNode){ 
                res.push( imgNode.get('src'))
            });            
        }
        this.set('results', Em.A(_.compact(res)));
    }
});
*/
