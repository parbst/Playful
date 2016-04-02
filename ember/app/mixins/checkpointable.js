import Ember from 'ember';
import _ from 'lodash';
import JsonableMixin from 'playful/mixins/jsonable';

export default Ember.Mixin.create(JsonableMixin, {
  _checkPoints: Ember.A(),
  checkpoint: function(name){
    var checkPoints = this.get('_checkPoints'),
        currentVersion = this.getJson();
    checkPoints.pushObject(Ember.Object.create({
      name: name,
      values: currentVersion
    }));
  },
  rollbackToCheckpoint: function(nOrName){
    var checkPoints = this.get('_checkPoints'),
        rollTo = _.last(checkPoints);
    if(_.isNumber(nOrName)){
      throw "implement me";
    }
    if(typeof nOrName !== 'undefined'){
      var idx = _.indexOf(_.invoke(checkPoints, 'get', 'name'), nOrName);
      if(idx >= 0){
        rollTo = checkPoints[idx];
        // dropping later check points
        for(var i = checkPoints.length - 1; idx < i; i--){
          checkPoints.removeAt(i);
        } 
      }
    }
    var rollToValues = rollTo.get('values');
    _.each(_.keys(rollToValues), function(key){
      if(this.get(key) !== rollToValues[key]) {
        this.set(key, rollToValues[key]);
      }
    }, this);
  }
});
