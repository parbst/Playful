App.OrderIndexController = Em.ArrayController.extend({
    actions: {
        approveOrder: function(order){
            var me = this;
            order.approve().then(function(){
                me.reloadOrder(order);
            }, function(){
                App.log.error("failed to approve order", arguments);
            });
        },
        reload: function(order){
            this.reloadOrder(order);
        },
        deleteOrder: function(order){
            if(confirm("Are you sure you want to delete order " + order.get('id') + "?")){
                order.deleteRecord();
                order.save().then(function(){
                    App.log.info("order " + order.get('id') + " deleted");
                }, function(){
                    App.log.error("failed to delete order " + order.get('id'), arguments);
                });
            }
        }
    },
    selectedQueryStatusElement: null,
    sortedContent: function(){
        var sortFunc = function(orderA, orderB){
            var result = 0;
            if(orderA.isSubOrder && orderA.isSubOrder(orderB)){
                result = -1
            }
            else if (orderB.isSubOrder && orderB.isSubOrder(orderA)){
                result = 1
            }
            else {
                result = Em.compare(orderA.get('createdAt'), orderB.get('createdAt'))
            }
            return result;
        };
        // have no clue why ember data structures the data this stupid way...
        var obj = this.get('content');
        while(!_.contains(['array', 'null'], Em.typeOf(obj))){
            obj = obj.get('content');
        }
        return _.isEmpty(obj) ? obj : obj.copy().sort(sortFunc);
//        return Em.A(_.sortBy(this.get('content.content'), sortFunc));
    }.property('content.content'),
    rootOrders: function(){
        return _.select(this.get('sortedContent'), function(o){ return o.get('isRootOrder') });
    }.property('sortedContent'),
    reloadOrder: function(order){
        var me = this;
        order.reload().then(function(){
            App.log.info("order " + order.get('id') + " reloaded, order in controller and order from store", order, me.store.find('order', order.get('id')));
            order.get('subOrders').forEach(function(subOrder){
                me.reloadOrder(subOrder);
            })
        }, function(){
            App.log.error("failed to reload order " + order.get('id'), arguments);
        });
    },
    changeModelQuery: function(){
        var map = {
            op_failed:      'failed',
            op_completed:   'completed',
            op_pending:     'pending',
            op_running:     'running'
        };
        var queryStatus = map[this.get('selectedQueryStatusElement').id];
        this.set('model', this.store.find('order', { status: queryStatus }));
    }.observes('selectedQueryStatusElement')
});
