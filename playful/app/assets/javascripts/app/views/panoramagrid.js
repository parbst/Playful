App.PanoramaGrid = Em.View.extend({
    fraction: .5,
    classNames: ['panorama'],
    originalWidth: null,
    originalMarginLeft: 0,
    position: 'left',
    actions:{
        toggle: function(){ this.toggle(); }
    },
    didInsertElement: function(){
        this.adjustWindowWidth();
        this.goLeft();
        this.get('controller').on('togglePanorama', $.proxy(this.toggle, this) );
    },
    toggle: function(){
        var panWin = this.get('panoramaWindow');
        if(panWin){
            var ml = this.getCurrentMarginLeft();
            if(_.isNumber(ml) && ml != this.get('originalMarginLeft')){
                this.goLeft();
            }
            else {
                this.goRight();
            }
        }
    },
    panoramaWindow: function(){
        return  $('.row.window', this.get('element')).first();
    }.property(),
    goRight: function(){
        var elemMarginLeft = -Math.floor(this.get('originalWidth') * (this.get('fraction') - 0));
        this.scrollTo(elemMarginLeft);
        this.get('leftmostColumn').addClass('dimmed');
        this.get('rightmostColumn').removeClass('dimmed');
        this.set('position', 'right');
    },
    goLeft: function(){
        this.scrollTo(this.get('originalMarginLeft'));
        this.get('leftmostColumn').removeClass('dimmed')
        this.get('rightmostColumn').addClass('dimmed')        
        this.set('position', 'left');
    },
    leftmostColumn: function(){
        return this.get('allColumns').first();
    }.property('allColumns'),
    rightmostColumn: function(){
        return this.get('allColumns').last();
    }.property('allColumns'),
    allColumns: function(){
        var panWin = this.get('panoramaWindow');
        if(panWin){
            return $('div', panWin).filter(function() {  return this.className.match(/col-md-/) });
        }        
    }.property(),
    scrollTo: function(marginLeft){
        var panWin = this.get('panoramaWindow');
        if(panWin && _.isNumber(marginLeft)){
            panWin.css('marginLeft', marginLeft + 'px');
        }
    },
    getCurrentMarginLeft: function(){
        var panWin = this.get('panoramaWindow'),
            result = null;
        if(panWin){
            var ml = panWin.css('marginLeft');
            if(_.isEmpty(ml)){
                return 0;
            }
            else {
                return ml.replace('px', '') - 0;
            }
        }
    },
    adjustWindowWidth: function(){
        var factor = 1 + (this.get('fraction') - 0),
            panWin = this.get('panoramaWindow');
        if(panWin){
            var ow = panWin[0].clientWidth,
                ml = this.getCurrentMarginLeft();
            this.set('originalWidth', ow);
            this.set('originalMarginLeft', ml);
            if(_.isNumber(ow) && _.isNumber(factor)){
                panWin.width(ow * factor)
            }
        }
    }
});
