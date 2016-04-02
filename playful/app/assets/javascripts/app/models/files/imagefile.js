App.ImageFile = App.BaseFile.extend({
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
        _.each(_.filter(properties, function(p){ return !!scan[_.str.underscored(p)] }), function(p){
            this.set(p, scan[_.str.underscored(p)]);
        }, this);
    }
});
