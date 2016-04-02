App.BsRadioButtonPanel = Em.View.extend({
    classNames: ['btn-group'],
    attributeBindings: ['data-toggle'],
    'data-toggle': 'buttons',
    selectedInputElement: null,
    click: function(){
        var me = this;
        setTimeout(function(){ me.updateChecked() }, 0)
    },
    updateChecked: function(){
        var activeBtn = $('label.active', this.get('element')),
            activeBtnElem = activeBtn ? activeBtn[0].children[0] : null,
            curSelectedElem = this.get('selectedInputElement');
        if(activeBtn && activeBtnElem != curSelectedElem){
            this.set('selectedInputElement', activeBtn[0].children[0])
        }
    }.observes('selectedInputElement'),
    didInsertElement: function(){
        this.$('.btn').button();
    }
});
