App.MoveFileTask = App.FileTask.extend({
    fromPath: DS.attr('string'),
    toPath: DS.attr('string'),
    createMissingDirs: DS.attr('boolean'),
    overwriteExisting: DS.attr('boolean'),
    baseFile: DS.belongsTo('baseFile'),
    inputTask: DS.belongsTo('task', { polymorphic: true }),

    moveFromPath: function(){
        var result = null,
            fromPath = this.get('fromPath'),
            baseFilePath = this.get('baseFile.path');
        if(fromPath){
            result = fromPath;
        }
        else if(baseFilePath){
            result = baseFilePath;
        }
        return result
    }.property('fromPath', 'baseFile')
});
