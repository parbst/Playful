App.Mask = Em.View.extend({
    hidden: true,
    classNames: ['mask'],
    attributeBindings: ['style'],
    _previousParentPositionStyle: null,
    hiddenBool: function(){ return Convert.toBool(this.get('hidden')) }.property('hidden'),
    style: function(){
        if(this.get('hiddenBool')){
            return "display:none;"
        }
    }.property('hiddenBool'),
    hiddenBoolDidChange: function(){
        var hidden = this.get('hiddenBool'),
            parent = $(this.get('element').parentNode),
            cssPosition = 'relative';

        if(hidden){
            cssPosition = this.get('_previousParentPositionStyle');
        }
        else {
            this.set('_previousParentPositionStyle', parent.css('position'));
        }

        parent.css('position', cssPosition);
    }.observes('hiddenBool'),
    didInsertElement: function(){
        this.hiddenBoolDidChange();
    }
});
