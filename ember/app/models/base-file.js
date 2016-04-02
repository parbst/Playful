import DS from "ember-data";
import _ from 'lodash';
import ENV from '../config/environment';

export default DS.Model.extend({
  path:               DS.attr('string'),
  uid:                DS.attr('int'),
  gid:                DS.attr('int'),
  inode:              DS.attr('int'),
  links:              DS.attr('int'), 
  byteSize:           DS.attr('int'),
  blockSize:          DS.attr('int'),
  blocks:             DS.attr('int'),
  accessTime:         DS.attr('date'),
  changeTime:         DS.attr('date'),
  modificationTime:   DS.attr('date'),
  md5hash:            DS.attr('string'),
  createdAt:          DS.attr('date'),
  updatedAt:          DS.attr('date'),

  scan:               null,

//    fileType:           DS.belongsTo('fileType'),
//    share:              DS.belongsTo('share'),

  updateFromScan: function(scan) {
    this.set('scan', scan);
    this.set('path', scan.get('path'));
    this.set('byteSize', scan.get('size'));
    this.set('links', scan.get('stat.nlink'));
    this.set('uid', scan.get('stat.uid'));
    this.set('gid', scan.get('stat.gid'));
    this.set('blocks', scan.get('stat.blocks'));
    this.set('blockSize', scan.get('stat.blksize'));
    this.set('accessTime', scan.get('stat.atime'));
    this.set('changeTime', scan.get('stat.ctime'));
    this.set('modificationTime', scan.get('stat.mtime'));
  },

  fileName: function(){
    return _.last(this.get('path').split('/'));
  }.property('path'),

  directory: function(){
    var pieces = this.get('path').split('/');
    pieces.pop();
    return pieces.join('/');
  }.property('path'),

  downloadUrl: function(){
    var id = this.get('id'),
        scan = this.get('scan');
    if(_.isNumber(id)){
      return ENV.APP.ENDPOINTS.download + "?id=" + encodeURIComponent(id);
    }
    if (scan){
      return scan.get('downloadUrl');
    }
  }.property('scan', 'id')

});
