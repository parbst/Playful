App.OrderIndexRoute = Em.Route.extend({
    model: function() {
        return this.store.find('order', {status: 'pending'});
    }
});
