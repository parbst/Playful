import DS from "ember-data";
import _ from 'lodash';
import BaseFileModel from 'playful/models/base-file';

var ImageFileModel = BaseFileModel.extend({
  height:         DS.attr('int'),
  width:          DS.attr('int'),
  capturedAt:     DS.attr('date'),
  exifComment:    DS.attr('string'),
  cameraMake:     DS.attr('string'),
  cameraModel:    DS.attr('string'),
  title:          DS.attr('string'),

  updateFromScan: function(scan){
      var properties = ['height', 'width', 'capturedAt', 'exifComment', 'cameraMake', 'cameraModel', 'title'];
      this._super(scan);
      _.each(_.filter(properties, function(p){ return !!scan[p]; }), function(p){
          this.set(p, scan[p]);
      }, this);
  }
});

ImageFileModel.reopenClass({
  fromScan: function(imageFileScan, store) {
    var result = store.createRecord('imageFile');
    result.updateFromScan(imageFileScan);
    return result;
  }
});

export default ImageFileModel;
