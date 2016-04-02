App.ImportIndexController = Em.ObjectController.extend({
    loading: false,
    loadingRequest: null,
    allSelectedFiles: Em.A(),
    infoGridColumns: [
        Grid.EditableColumn.create({propertyName: 'key'}),
        Grid.Column.create({propertyName: 'value'})
    ],
    infoGridRows: Em.A(),
    scanBrowser: App.ScanResultBrowser.create({
        rootPath: "C:/torquebox/testdata"
    }),
    selectedScanResult: null,
    orderLine: null,
    actions:{
        importAudio: function(){
            var ol = App.AudioImportOrderLine.create({
                importScans: this.get('allSelectedFiles'),
                store: this.store
            });
            this.set('orderLine', ol);
            this.send('nextStep')
        }
    },
    cancelCurrentLoad: function(){
        this.get('loadingRequest').abort();
        this.set('loadingRequest', null);
        this.set('loading', false);
    },
    clearSelections: function(){
        this.set('infoGridRows', Em.A());
        this.set('selectedScanResult', null);
    },
    selectedFilesDidChange: function(){
        if(this.get('loading')){
            this.cancelCurrentLoad();
        }

        this.set('loading', true);
        var sf = this.get('scanBrowser').get('selectedFiles'),
            isFolder = function(i){ return i.get('isFolder') },
            isFile = function(i){ return i.get('isFile') },
            folders = _.filter(sf, isFolder),
            files = _.filter(sf, isFile),
            exit = _.bind(function(result){
                this.set('loading', false);
                if(result){
                    var allFiles = _.filter(result, isFile).concat(files);
                    this.set('allSelectedFiles', allFiles)
                }
                this.set('loadingRequest', null);
            }, this);
        this.clearSelections();
        if(folders.length > 0){
            var descriptor = { dirs: _.map(folders, function(f){ return f.get('path') }), recursive: true },
                request = App.dataAccess.files.scanByDescriptor(descriptor, function(fileList){
                exit(fileList);
            }, function(xhr, errorMessage, thrownError) {
                if(thrownError != 'abort'){
                    App.log.error("file scan fetch failed " + xhr.statusText);
                    exit();
                }
            })
            this.set('loadingRequest', request);
        }
        else{
            exit([])
        }
    }.observes('scanBrowser.selectedFiles'),
    allSelectedFilesDidChange: function(){
        var allSelectedFiles = this.get('allSelectedFiles'),
            totalSize = _.reduce(allSelectedFiles, function(memo, file){ return memo + file.get('size') }, 0);
        this.set('infoGridRows', Em.A([
            Em.Object.create({ key: 'Files total', value: allSelectedFiles.length }),
            Em.Object.create({ key: 'Size total', value: Format.bytesToHuman(totalSize) })
        ]));

        var tree = _.object(_.map(allSelectedFiles, function(f){return [f.get('name'), f.toRawData()]}));
        this.set('selectedScanResult', tree);
    }.observes('allSelectedFiles')
});
