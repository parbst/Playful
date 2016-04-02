App.Order = DS.Model.extend({
    type: DS.attr('string'),
    status: DS.attr('string'),
    message: DS.attr('string'),
    backtrace: DS.attr('string'),
    sequence: DS.attr('number'),
    createdAt: DS.attr('date'),
    updateAt: DS.attr('date'),

    parentOrder: DS.belongsTo('order'),
    subOrders: DS.hasMany('order', { inverse: 'parentOrder' }),
    tasks: DS.hasMany('task', { polymorphic: true }),

    displayType: function(){
        return _.str.humanize(this.get('type'));
    }.property('type'),

    displayStatus: function(){
        return _.str.capitalize(this.get('status'))
    }.property('status'),

    readyForApproval: function(){
        return this.get('status') == 'pending' && _.isEmpty(this.get('parentOrder'));
    }.property('status'),

    familyOrderIds: function(){
        var recurse = function(order){
            var subOrders = order.get('subOrders.content');
            return _.invoke(subOrders, 'get', 'id').concat(_.flatten(_.map(subOrders, recurse)));
        };
        return recurse(this)
    }.property('subOrders'),

    failed: function(){
        return this.get('status') == 'failed';
    }.property('status'),

    isRootOrder: function(){
        return Em.typeOf(this.get('parentOrder')) == 'null';
    }.property('parentOrder'),

    isSubOrder: function(couldBeSubOrder){
        var orderFamilyIds = this.get('familyOrderIds');
        return _.contains(orderFamilyIds, couldBeSubOrder.get('id'))
    },

    approve: function(){
        var result = null;
        if(this.get('readyForApproval')){
            this.set('status', 'approved');
            result = this.save();
        }
        return result;
    }
});
