App.Task = DS.Model.extend({
    type: DS.attr('string'),
    status: DS.attr('string'),
    error: DS.attr('string'),
    sequence: DS.attr('number'),
    createdAt: DS.attr('date'),
    updateAt: DS.attr('date'),
    order: DS.belongsTo('order')
});
