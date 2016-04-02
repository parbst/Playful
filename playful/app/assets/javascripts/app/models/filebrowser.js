// TODO: make the decorator model so column / row specific fields aren't set on original models

App.ScanResultBrowser = Em.Object.extend({
    rootPath: null,
    currentPath: null,
    loading: false,
    loadedPath: null,
    itemList: Em.A(),
    doubleClickedRow: null,
    selectedFiles: Em.A(),
    itemColumns: Em.A([
        Grid.Column.create({propertyName: 'name'}),
        Grid.Column.create({propertyName: 'sizeForHumans', columnClass: ['column-right-justified']})
    ]),
    pathParts: Em.A(),
    selectedPathPart: null,

    currentPathDidChange: function(){
        var currentPath = this.get('currentPath'),
            exit = _.bind(function(result){
                this.set('loading', false);
                if(result){
                    this.set('itemList', result);
                    this.set('loadedPath', this.get('currentPath'))
                }
                else{
                    this.set('currentPath', this.get('loadedPath'))
                }
            }, this);
        if(currentPath && currentPath != this.get('loadedPath') && !this.get('loading')){
            this.set('loading', true);
            App.dataAccess.files.scanByDescriptor({ dir: currentPath }, function(fileList){
                exit(fileList);
            }, function(xhr, errorMessage, thrownError) {
                App.log.error("file scan fetch failed " + xhr.statusText);
                exit();
            })
        }
    }.observes('currentPath').on('init'),
    loadedPathDidChange: function(){
        var rootPath = this.get('rootPath'),
            loadedPath = this.get('loadedPath'),
            separators = ['/', '\\'],
            separator = _.find(separators, function(sep){ return new RegExp(sep).test(loadedPath)}),
            pathParts = [];
        if(separator && _.str.startsWith(loadedPath.toLowerCase(), rootPath.toLowerCase())){
            pathParts = _.compact(pathParts.concat(loadedPath.substr(rootPath.length).split(separator)))
        }

        var tmp = rootPath;
        pathParts = _.map(pathParts, function(pp){ 
            tmp += separator + pp;
            return Em.Object.create({ label: pp, value: tmp }) 
        });
        pathParts.unshift(Em.Object.create({ label: rootPath, value: rootPath}))

        this.set('pathParts', Em.A(pathParts));
        this.set('selectedPathPart', _.last(pathParts));
    }.observes('loadedPath'),
    selectedPathPartDidChange: function(){
        this.set('currentPath', this.get('selectedPathPart').get('value'));
    }.observes('selectedPathPart'),
    rootPathDidChange: function(){
        this.set('currentPath', this.get('rootPath'))
    }.observes('rootPath'),
    init: function(){
        this._super();
        this.rootPathDidChange();
    },
    itemListDidChange: function(){
        _.each(this.get('itemList'), function(item){
            if(item.get('isFolder')){
                item.set('rowClass', 'hb-folder')
            }
        });
        this.get('itemList').sort(function(a, b){ 
            return a.get('isFolder') && !b.get('isFolder') ? -1 :
                   !a.get('isFolder') && b.get('isFolder') ?  1 :
                   a < b ? -1 : 
                   a > b ? 1 : 0;
        });
    }.observes('itemList'),
    doubleClickedRowDidChange: function(){
        var clickedRow = this.get('doubleClickedRow');
        if(clickedRow.get('isFolder')){
            this.set('currentPath', clickedRow.get('path'));
        }
    }.observes('doubleClickedRow')
});
