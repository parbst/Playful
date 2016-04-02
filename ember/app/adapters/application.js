import DS from "ember-data";
import ENV from '../config/environment';

export default DS.ActiveModelAdapter.extend({
  host: ENV.APP.SERVER.host,
  namespace: ENV.APP.SERVER.apiNamespace,
  headers: {
    Accept: 'application/json'
  },
  pathForType: function(type) {
    var res = this._super(type);
    if(type.match(/Task$/)){
      res = 'tasks';
    }
    return res;
  }
});
