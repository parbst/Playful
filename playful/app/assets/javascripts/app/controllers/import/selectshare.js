App.ImportSelectShareController = Em.ArrayController.extend(App.OrderLineControllerMixin, {
    orderLine: null,
    actions: {
        selectShare: function(share){
            this.get('model').forEach(function(share){
                share.set('selected', false)
            });
            share.set('selected', true);

            var ol = this.get('orderLine');
            if(ol){
                ol.set('share', share);
            }
        }
    }
});
