import AbstractPlayfulRoute from '../routes/abstract/playful';

export default AbstractPlayfulRoute.extend({
  model: function() {
    return this.store.find('order');
  }
});
