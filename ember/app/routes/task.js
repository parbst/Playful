import AbstractPlayfulRoute from '../routes/abstract/playful';

export default AbstractPlayfulRoute.extend({
  model: function(params) {
    return this.store.find('task', params.taskId);
  }
});
