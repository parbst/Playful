Tag = Em.Namespace.create();

Tag.properties = [
    Em.Object.create({ name: 'filename',        title: 'File name',     readOnly: true}),
    Em.Object.create({ name: 'artist',          title: 'Artist',        validate: Validation.Basic.nonEmptyString}),
    Em.Object.create({ name: 'albumArtist',     title: 'Album artist'}),
    Em.Object.create({ name: 'composer',        title: 'Composer'}),
    Em.Object.create({ name: 'album',           title: 'Album'}),
    Em.Object.create({ name: 'trackTitle',      title: 'Title',         validate: Validation.Basic.nonEmptyString}),
    Em.Object.create({ name: 'trackNumber',     title: 'Number',        validate: Validation.Basic.integer}),
    Em.Object.create({ name: 'trackTotal',      title: 'Total',         validate: Validation.Basic.integer}),
    Em.Object.create({ name: 'year',            title: 'Year',          validate: Validation.Basic.integer}),
    Em.Object.create({ name: 'genre',           title: 'Genre'}),
    Em.Object.create({ name: 'discNumber',      title: 'Disc',          validate: Validation.Basic.integer}),
    Em.Object.create({ name: 'discTotal',       title: 'Total discs',   validate: Validation.Basic.integer}),
    Em.Object.create({ name: 'comment',         title: 'Comment'}),
    Em.Object.create({ name: 'durationString',  title: 'Duration',      readOnly: true})
];

Tag.TagGridView = Grid.GridView.extend({
    audioFilesBinding: 'parentView.audioFiles',
    columns: Em.A([
        Grid.Column.create({propertyName: 'key'}),
        Grid.EditableColumn.create({propertyName: 'value'})
    ]),
    audioFilesDidChange: function(){
        this.updateGrid();
    }.observes('audioFiles', 'audioFiles.@each.observeChange'),
    rows: Em.A(),
    init: function(){
        this._super();
        this.audioFilesDidChange();
        this.audioFilesDidChangeBuffered = _.debounce(this.audioFilesDidChange, 100);
    },
    updateGrid: function(){
        var me = this,
            audioFiles = this.get('audioFiles'),
            rows = Em.A(),
            MyObserver = Em.Object.extend({
                value: null,
                rowTooltip: null,
                valueDidChange: function(){
                    var title = this.get('key'), value = this.get('value'),
                        propIdx = _.invoke(Tag.properties, 'get', 'title').indexOf(title);
                    me.rowUpdated(Tag.properties[propIdx].get('name'), value);
                }.observes('value')
            });
        _.each(Tag.properties, function(property){
            var propertyName = property.get('name'),
                propertyValues = _.map(audioFiles, function(a){ return a.get(propertyName) }),
                unique = _.uniq(propertyValues),
                value = '',
                rowTooltip = null;
            if(propertyValues.length > 0){
                if(unique.length == 1){
                    // all values for this property is identical
                    value = unique[0]
                }
                else if (unique.length > 3){
                    rowTooltip = unique.join(', ');
                    value = '<multiple values>';
                }
                else if (unique.length > 0){
                    value = '<' + unique.join(', ') + '>'
                }
            }

            rows.push(MyObserver.create({
                key: property.get('title'),
                value: value,
                rowTooltip: rowTooltip,
                readOnly: property.get('readOnly'),
                validate: property.get('validate')
            }));
        });

        this.set('rows', rows);
    },
    rowUpdated: function(propertyName, value){
        _.each(this.get('audioFiles'), function(af){
            af.set(propertyName, value);
        });
    }
});

Tag.TagEditorView = Ember.View.extend({
    audioFiles: Em.A(),
    defaultTemplate: Ember.Handlebars.compile(
        '{{view App.ComponentHeadlineView title="Tag editor"}} ' +
        '{{view Tag.TagGridView }}')
});
