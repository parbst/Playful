import AbstractPlayfulRoute from '../routes/abstract/playful';

export default AbstractPlayfulRoute.extend({
  model: function(params, transition) {
    console.log("a transition is?", transition);
    return this.store.find('order', params.orderId);
  }
});
