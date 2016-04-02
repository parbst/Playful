App.AudioConfirmController = Em.ObjectController.extend(App.OrderLineControllerMixin, {
    actions: {
        stepCompleted: function(){
            App.dataAccess.orders.create(this.get('orderLine.orderCreationData'), function(){
                alert('successful order submit')
            }, function(){
                alert('order submit failed')
            });
        }
    },
    orderCreationData: function(){
        var ocd = this.get('orderLine.orderCreationData'), result;
        if(ocd){
            result = JSON.stringify(ocd, undefined, 2)
        }
        return result;
    }.property('orderLine')
});
