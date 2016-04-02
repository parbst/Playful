App.Share = DS.Model.extend({
    baseFiles: DS.hasMany('baseFile'),
    path: DS.attr('string'),
    name: DS.attr('string'),
    description: DS.attr('string'),
    createdAt: DS.attr('date')
});
