import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.resource('orders');
  this.resource('ui');
  this.resource('import', function() {
    this.resource('import.audio', { path: '/audio' }, function() {
      this.route('tag');
    });
    this.route('selectShare');
  });
  this.resource('order', { path: '/order/:orderId' });
  this.resource('task', { path: '/task/:taskId' });
});

export default Router;
