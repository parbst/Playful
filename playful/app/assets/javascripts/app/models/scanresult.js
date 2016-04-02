App.ScanResult = Em.Object.extend({
    path: null,
    size: null,
    stat: null,
    type: null,
    file: null,
    conclusion: null,
    is_audio: null,
    is_video: null,
    is_image: null,
    is_archive: null,

    name: function(){
        var path = this.get('path'),
            m = /\/([^\/]+)\/?$/.exec(path);
        if (m){ m = m[1] }
        return m;
    }.property('path'),
    sizeForHumans: function(){
        return Format.bytesToHuman(this.get('size'))
    }.property('size'),
    isFolder: function(){
        return this.get('type') == 'directory'
    }.property('type'),
    isFile: function(){
        return this.get('type') == 'file'
    }.property('type'),
    isAudioFile: function(){
        return !!this.get('is_audio');
    }.property('is_audio'),
    isImageFile: function(){
        return !!this.get('is_image');
    }.property('is_audio'),
    toRawData: function(){
        var result = {}
        _.each(_.pairs(this), function(pair){ result[pair[0]] = pair[1]; });
        delete result.toString
        result.sizeForHumans = this.get('sizeForHumans');
        return result;
    }
});
