App.EditTagFileTask = App.FileTask.extend({
    path: DS.attr('string'),
    oldTags: DS.attr(),
    newTags: DS.attr(),
    coverArtFront: DS.belongsTo('task', { polymorphic: true }),
    baseFile: DS.belongsTo('baseFile')
});
