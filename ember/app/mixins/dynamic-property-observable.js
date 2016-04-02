import Ember from 'ember';

export default Ember.Mixin.create({
    registerDynamicObserver: function(hostProperty, dynamicProperty, observer) {
      var me = this,
          dynProp = hostProperty + '.' + this.get(dynamicProperty);
      var placeObserver = function(){
        me.removeObserver(dynProp, observer);
        var dynamicPropertyValue = this.get(dynamicProperty);
        if(hostProperty && dynamicProperty && dynamicPropertyValue){
            dynProp = hostProperty + '.' + dynamicPropertyValue;
            me.addObserver(dynProp, observer);
        }
      };
      me.addObserver(dynamicProperty, placeObserver);
    },
    registerDynamicChange: function(hostProperty, dynamicProperty, notifyProperty){
      var me = this;
      this.registerDynamicObserver(hostProperty, dynamicProperty, function(){
        me.notifyPropertyChange(notifyProperty);
      });
    }
});
