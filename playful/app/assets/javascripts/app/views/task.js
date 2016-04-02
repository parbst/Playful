App.TaskDetailsView = Em.View.extend({
    templateName: 'task/details',
    classNames: ['task'],
    task : null,
    isMoveTask: function(){
        return this.get('task') instanceof App.MoveFileTask;
    }.property('task'),
    isEditTagTask: function(){
        return this.get('task') instanceof App.EditTagFileTask;
    }.property('task'),
    isDownloadTask: function(){
        return this.get('task') instanceof App.DownloadFileTask;
    }.property('task'),
    isImportTask: function(){
        return this.get('task') instanceof App.ImportTask;
    }.property('task'),
    tags: function(){
        var result = null;
        if(this.get('isEditTagTask')){
            var keys = _.uniq(_.keys(this.get('task.oldTags')).concat(_.keys(this.get('task.newTags'))));
            result = _.map(keys, function(key){
                return {
                    key: key,
                    new: this.get('task.newTags')[key],
                    old: this.get('task.oldTags')[key]
                }
            }, this);
        }
        return result;
    }.property('task')
});