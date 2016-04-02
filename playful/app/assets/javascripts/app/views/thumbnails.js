App.ThumbnailImage = Em.View.extend({
    tagName: 'li',
    classNames: ['pf-thumbnail'],
    selected: false,
    src: function(){
        return this.get('content.' + this.get('parentView.sourceKey'));
    }.property('content.src', 'content.downloadEndpoint'),
    caption: function(){
        return this.get('content.' + this.get('parentView.captionKey'));
    }.property('content'),
    title: function(){
        return this.get('content.' + this.get('parentView.titleKey'));
    }.property('content'),
    template: Ember.Handlebars.compile(
        '<a {{action selectThumbnail view target=view.parentView}} href="#" class="thumbnail">' +
        '<div {{bindAttr class="view.selected:thin-border-active: :fixed-square-140"}}>' +
                "{{#if view.src}}" +
                    '<img {{bindAttr src="view.src"}} {{bindAttr title="view.title"}}/>' +
                "{{else}}" +
                    "<p>No image</p>" +
                "{{/if}}" +
        "</div>" +
            '</a>' +
        "{{view.caption}}")
});

App.Thumbnails = Em.CollectionView.extend(Em.ViewTargetActionSupport, {
    tagName: 'ul',
    classNames: ['list-inline'],
    itemViewClass: 'App.ThumbnailImage',
    selectable: false,
    selectableBool: function(){ return Convert.toBool(this.get('selectable')) }.property('selectable'),
    sourceKey: 'src',
    captionKey: 'caption',
    titleKey: 'title',
    actions: {
        selectThumbnail: function(thumbnailView){
            _.each(this.get('childViews'), function(item){ item.set('selected', false) });
            if(this.get('selectableBool')){
                thumbnailView.set('selected', true)
            }
            this.triggerAction({ actionContext: thumbnailView.get('content'), action: 'selectThumbnail' });
        }
    }
});
