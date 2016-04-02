import Ember from 'ember';
import DS from "ember-data";
import S from 'stringjs';
import _ from 'lodash';
 
export default DS.Model.extend({
	type: DS.attr('string'),
	status: DS.attr('string'),
	message: DS.attr('string'),
	backtrace: DS.attr('string'),
	sequence: DS.attr('number'),
	createdAt: DS.attr('date'),
	updatedAt: DS.attr('date'),

	parentOrder: DS.belongsTo('order'),
	subOrders: DS.hasMany('order', { inverse: 'parentOrder' }),
	tasks: DS.hasMany('task', { polymorphic: true, async: true, inverse: 'order' }),

	displayType: function(){
    return S(this.get('type')).humanize().s;
	}.property('type'),

	displayStatus: function(){
    return Ember.String.capitalize(this.get('status'));
	}.property('status'),

	readyForApproval: function(){
    return this.get('status') === 'pending' && _.isEmpty(this.get('parentOrder'));
	}.property('status'),

	familyOrderIds: function(){
    var recurse = function(order){
        var subOrders = order.get('subOrders.content');
        return _.invoke(subOrders, 'get', 'id').concat(_.flatten(_.map(subOrders, recurse)));
    };
    return recurse(this);
	}.property('subOrders'),

	isFailed: function(){
    return this.get('status') === 'failed';
	}.property('status'),

  isApproved: function(){
    return this.get('status') === 'approved';
  }.property('status'),

  isPending: function(){
    return this.get('status') === 'pending';
  }.property('status'),

  isCompleted: function(){
    return this.get('status') === 'completed';
  }.property('status'),

	isRootOrder: function(){
    return Ember.typeOf(this.get('parentOrder')) === 'null';
	}.property('parentOrder'),

	isSubOrder: function(couldBeSubOrder){
    var orderFamilyIds = this.get('familyOrderIds');
    return _.contains(orderFamilyIds, couldBeSubOrder.get('id'));
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
