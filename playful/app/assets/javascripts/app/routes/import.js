App.OrderLineRouteMixin = Em.Mixin.create({
    initOrderLine: function(controller){
        if(App.transitionOrderLine){
            var ol = App.transitionOrderLine;
            delete App.transitionOrderLine;
            controller.set('orderLine', ol);
            controller.set('stepsTotal', ol.get('totalSteps'));
            controller.set('atStep', ol.getStepIndexForRoute(this.get('routeName')));
        }
    },
    setupController: function(controller, model){
        this._super(controller, model);
        this.initOrderLine(controller);
    },
    actions: {
        nextStep: function(){
            var orderLine = this.get('controller').get('orderLine');
            if(orderLine){
                App.transitionOrderLine = orderLine; 
                var target = orderLine.getTransition(this.get('controller'));
                this.transitionTo(target);
            }
        }
    }
});

App.OrderLineControllerMixin = Em.Mixin.create({
    orderLine: null,
    atStep: null,
    stepsTotal: null,
    actions: {
        stepCompleted: function(){
            this.send('nextStep')
        }
    }
});

App.ImportIndexRoute = Em.Route.extend(App.OrderLineRouteMixin, {});

App.ImportSelectShareRoute = Em.Route.extend(App.OrderLineRouteMixin, {
    model: function(){ return this.store.find('share'); }
});

App.AudioTagsRoute = Em.Route.extend(App.OrderLineRouteMixin, {});

App.AudioCoversRoute = Em.Route.extend(App.OrderLineRouteMixin, {});

App.AudioConfirmRoute = Em.Route.extend(App.OrderLineRouteMixin, {});
