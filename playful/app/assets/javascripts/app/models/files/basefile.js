App.BaseFile = DS.Model.extend({
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

    fileType:           DS.belongsTo('fileType'),
    share:              DS.belongsTo('share'),

    latestScan:         null,
    observeChange:      0,
    _checkPoint:        null,

    validate: function(){
        return true;
    },

    filename: function(){
        var m = /\/([^\/]+)\/?$/.exec(this.get('path')),
            result;
        if (m){
            result = m[1]
        }
        return result;
    }.property('path'),

    extension: function(){
        var fn = this.get('filename'),
            result;
        if(_.isString(fn)){
            result = _.last(fn.split('.'));
        }
        return result;
    }.property('path'),

    restEndpoint: function(){
        var id = this.get('id'),
            result;
        if(_.isNumber(id)){
            result = App.config.endpoint.get('files') + '/' + this.get('id')
        }
        return result;
    }.property('id'),

    downloadEndpoint: function(){
        var result = App.config.endpoint.get('files.download') + '?path=' + encodeURIComponent(this.get('path')),
            restEndpoint = this.get('restEndpoint');
        if(restEndpoint){
            result = restEndpoint + '/download'
        }
        return result;
    }.property('id', 'path'),

    updateFromScan: function(scan){
        this.set('path', scan.path);
        this.set('byteSize', scan.size);
        this.set('links', scan.stat.nlink);
        this.set('uid', scan.stat.uid);
        this.set('gid', scan.stat.gid);
        this.set('blocks', scan.stat.blocks);
        this.set('blockSize', scan.stat.blksize);
        this.set('accessTime', scan.stat.atime);
        this.set('changeTime', scan.stat.ctime);
        this.set('modificationTime', scan.stat.mtime);
    },

    latestScanDidChange: function(){
        var latestScan = this.get('latestScan');
        if(latestScan){
            this.updateFromScan(latestScan);
            this.checkPoint();
        }
    }.observes('latestScan'),

    init: function(){
        this._super();
        this.updateObserveChangeBuffered = _.debounce(this.updateObserveChange, 100);
    },

    updateObserveChange: function(){
        this.incrementProperty('observeChange');
    },

    checkPoint: function(){
        var properties = this.getCheckPointProperties(),
            checkPoint = _.reduce(properties, function(memo, prop){
                memo[prop] = this.get(prop);
                return memo;
            }, {}, this);
        this.set('_checkPoint', checkPoint);
    },

    rollBack: function(){
        var checkPoint = this.get('_checkPoint');
        _.each(checkPoint, function(value, prop){ this.set(prop, value) }, this);
    },

    diff: function(properties){
        var checkPoint = this.get('_checkPoint'),
            result = Em.copy(checkPoint);
        _.each(checkPoint, function(value, prop){
            var keyMatch = !_.isEmpty(properties) && _.contains(properties, prop);
            if(!keyMatch || value == this.get(prop)){
                delete result[prop];
            }
        }, this);
        return result;
    },

    getCheckPointProperties: function(){
        return ['path', 'uid', 'gid', 'inode', 'links', 
            'byteSize', 'blockSize', 'blocks', 'accessTime',
            'changeTime', 'modificationTime', 'md5hash',
            'createdAt', 'updatedAt'];
    }
});

App.BaseFile.reopenClass({
    createFromScan: function(scanResult, store){
        var result = null,
            msg = '';
        if(scanResult.get('isFile')){
            if(scanResult.get('isAudioFile')){
                result = store.createRecord('audioFile');
            }
            else if (scanResult.get('isImageFile')){
                result = store.createRecord('imageFile');
            }
            else{
                msg = "unknown file type, cannot create file object for file with extension " + scanResult.get('file').extension;
            }
        }
        else{
            msg = 'cannot create file, scan is a directory!';
        }

        if(msg){
            App.log.error('BaseFile.createFromScan: ' + msg, arguments)
        }
        if(result){
            result.set('latestScan', scanResult);
        }

        return result;
    }
});