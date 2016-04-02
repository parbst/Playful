App.FileType = DS.Model.extend({
    baseFiles: DS.hasMany('baseFile'),
    name: DS.attr('string'),
    subtype: DS.attr('string'),
    extension: DS.attr('string'),
    mimeType: DS.attr('string'),
    scanType: DS.attr('string'),
    createdAt: DS.attr('date'),
    updatedAt: DS.attr('date')
});
