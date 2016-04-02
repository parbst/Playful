App.FileCollectionMixin = Em.Mixin.create(Em.NativeArray, {
    audioFiles: function(){
        return this._getByClass(App.AudioFile)
    }.property(),
    imageFiles: function(){
        return this._getByClass(App.ImageFile)
    }.property(),
    _getByClass: function(clazz){
        return App.FileCollection(_.filter(this, function(f){ return f instanceof clazz }));
    },
    where: function(propConditions){
        var keys = ['id'].concat(_.keys(propConditions)),
            matches = _.where(_.map(this, function(f){ return f.getProperties(keys) }), propConditions),
            matchIds = _.map(matches, function(m){ return m.get('id') });
        return App.Filecollection(
            _.filter(this, function(f){ return _.contains(matchIds, f.get('id')) })
        );
    },
    uniqValues: function(property){
        return _.compact(_.uniq(_.map(this, function(af){ return af.get(property) })));
    }
});

App.FileCollection = function(arr) {
    if (arr === undefined) { arr = []; }
    return App.FileCollectionMixin.apply(arr);
};

App.FileCollection.createFromScans = function(scanResultArray, store){
    return App.FileCollection(
        _.map(scanResultArray, function(sr){ return App.BaseFile.createFromScan(sr, store) })
    );
};
