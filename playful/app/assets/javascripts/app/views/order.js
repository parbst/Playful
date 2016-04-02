App.OrderDetailsView = Em.View.extend({
    templateName: 'order/details',
    classNames: ['order'],
    order: null,
    isTasksExpanded: false,
    isSubOrdersExpanded: false,
    showBacktrace: false,
    actions: {
        toggleTasksExpanded: function(){
            this.set('isTasksExpanded', !this.get('isTasksExpanded'));
        },
        toggleSubOrdersExpanded: function(){
            this.set('isSubOrdersExpanded', !this.get('isSubOrdersExpanded'));
        },
        toggleBacktrace: function(){
            this.set('showBacktrace', !this.get('showBacktrace'));
        }
    },
    actionsDisabled: function(){
        return !this.get('order.readyForApproval');
    }.property('order.readyForApproval')
});
