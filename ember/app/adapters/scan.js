import Ember from 'ember';
import $ from 'jquery';
import _ from 'lodash';
import ENV from '../config/environment';
import ScanModel from 'playful/models/scan';
import humps from 'humps';

export default Ember.Object.extend({
  findByDir: function(dirs, recursive){
    return $.ajax({
      contentType: 'application/json; charset=UTF-8',
      method: 'POST',
      url: ENV.APP.ENDPOINTS.scan,
      data: JSON.stringify({ 
        dirs: Ember.typeOf(dirs) === 'array' ? dirs : [dirs], 
        recursive: !!recursive 
      }),
      accepts: 'application/json',
      converters: {
        "text json": function(value) {
          var parsedResponse = $.parseJSON(value);
          return _.map(humps.camelizeKeys(parsedResponse), function(o){ return ScanModel.create(o); });
        }
      }
    });
  }
});
