App.AudioImportOrderLine = App.ImportOrderLine.extend({
    audioFiles: Em.A(),
    fileCollection: null,
    coverArt: Em.A(),
    share: null,
    init: function(){
        this._super();
        this.set('transitionMap', {
            mapKeys: [
                App.ImportIndexController,
                App.AudioTagsController,
                App.AudioCoversController,
                App.ImportSelectShareController,
                App.AudioConfirmController
            ],
            mapValues: [
                'audio.tags',
                'audio.covers',
                'import.selectShare',
                'audio.confirm'
            ]
        });
    },
    transitionMap: {},
    importScansDidChange: function(){
        var importScans = this.get('importScans'),
            audioFiles = Em.A(),
            fileCollection = null;
        if(importScans){
            fileCollection = App.FileCollection.createFromScans(importScans, this.get('store'));
            audioFiles = fileCollection.get('audioFiles');
        }
        this.setProperties({
            audioFiles: audioFiles,
            fileCollection: fileCollection
        });
    }.observes('importScans').on('init'),
    orderCreationData: function(){
        var tags = {};
        _.each(this.get('audioFiles'), function(af){
            var tagDiff = af.tagDiff();
            if(!_.isEmpty(tagDiff)){
                var changedTags = {};
                _.each(tagDiff, function(prevValue, key){
                    changedTags[key] = {
                        new: af.get(key),
                        old: prevValue
                    };
                });
                tags[af.get('path')] = Format.underscoreKeysRecursively(changedTags);
            }
        });
        var result = Format.underscoreKeysRecursively({
            order_type: "import_audio",
            files: _.map(this.get('audioFiles'), function(af){ return af.get('path') }),
            import_to_share: this.get('share.id'),
            cover_art: _.map(this.get('coverArt'), function(ca){ return ca.getProperties('albumName', 'artistName', 'path', 'type', 'url') })
        });
        result.tags = tags;
        return result;
    }.property('audioFiles', 'audioFiles.@each.observeChange', 'coverArt', 'coverArt.@each', 'share'),
    getStepIndexForRoute: function(routeName){
        var transitionMap = this.get('transitionMap'),
            idx = transitionMap.mapValues.indexOf(routeName),
            result;
        if(idx >= 0){
            result = idx + 1;
        }
        return result;
    },
    totalSteps: function(){
        return this.get('transitionMap').mapValues.length;
    }.property(),
    getTransition: function(controller){
        var transitionMap = this.get('transitionMap'),
            cls = _.find(transitionMap.mapKeys, function(controllerClass){
                return controller instanceof controllerClass 
            }),
            result;
        if(cls){
            result = transitionMap.mapValues[transitionMap.mapKeys.indexOf(cls)]
        }
        return result;
    }
});
