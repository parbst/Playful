App.ImportTask = App.Task.extend({
    path: DS.attr('string'),
    share: DS.belongsTo('share'),
    baseFile: DS.belongsTo('baseFile'),
    inputTask: DS.belongsTo('task', { polymorphic: true })
});

App.AudioImportTask = App.ImportTask.extend({});
App.ImageImportTask = App.ImportTask.extend({});
