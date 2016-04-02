Tree = Em.Namespace.create();

Tree.TreeView = Em.View.extend({
    nodes: Em.A(),
    classNames: Em.A(['tree']),
    didInsertElement: function(){
        $(this.get('element')).dynatree({
            children: this.get('nodes')
        })
    },
    nodesDidChange: function(){
        var nodes = this.get('nodes'),
            treeRoot = $(this.get('element')).dynatree('getRoot');
        treeRoot.removeChildren();
        _.each(nodes, function(node){
            treeRoot.addChild(node);
        });
    }.observes('nodes')
});

Tree.ObjectTree = Tree.TreeView.extend({
    object: null,
    objectDidChange: function(){
        var buildStructure = function(o){
                return _.map(_.pairs(o), function(pair){
                    var title = pair[0],
                        val = pair[1],
                        children = null;
                    if(val === null){
                        val = 'null'
                    }
                    else if(_.isObject(val)){
                        children = buildStructure(val);
                    }
                    else{
                        title += ': ' + val
                    }
                    var result = { title: title };
                    if(children){
                        result.children = children;
                        result.isFolder = true;
                    }
                    return result;
                });
            },
            object = this.get('object'),
            result = [];
        if(object){
            result = buildStructure(object);
        }
        this.set('nodes', result);
    }.observes('object')
});
