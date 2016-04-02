import Ember from 'ember';
import S from 'stringjs';

export default Ember.Mixin.create({
  needs: ['import/audio/tag', 'application', 'import/selectShare'],
  orderline: null,
  nextStep: function(orderline){
      orderline = orderline || this.get('orderline');
      var transitionTo = orderline.nextRoute(this.get('controllers.application.currentPath'));
      var ctlr = this.get('controllers.' + S(transitionTo).replaceAll('.', '/').s);
      ctlr.set('orderline', orderline);
      this.transitionToRoute(transitionTo);
  }
});
