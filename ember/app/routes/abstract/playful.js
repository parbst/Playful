import Ember from 'ember';
import _ from 'lodash';

export default Ember.Route.extend({
  renderToPlayerOutlets: function(){
    var controller = this.controllerFor('player');

    _.each(['playerDesktop'], function(outletName){
	    this.render('player', { outlet: outletName, controller: controller });
    }, this);
  },

  renderTemplate: function() {
    this.render();
  	this.renderToPlayerOutlets();
  }
});
