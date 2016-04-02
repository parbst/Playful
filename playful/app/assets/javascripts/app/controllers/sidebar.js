App.SidebarController = Em.ObjectController.extend({
    menuItems: Em.A([
        Em.Object.create({ title: 'Play' }),
        Em.Object.create({ title: 'Import', route: 'import.index' }),
        Em.Object.create({ title: 'Orders', route: 'order.index' })


/*
        Em.Object.create({ title: '1st item', children: Em.A([
            Em.Object.create({ title: 'nested item 1' }),
            Em.Object.create({ title: 'nested item 2' })
        ]) }),
        Em.Object.create({ title: '2nd item', children: Em.A([
            Em.Object.create({ title: 'nested item 1' }),
            Em.Object.create({ title: 'nested item 2', selected: true })
        ])}),
        Em.Object.create({ title: '3rd item' })
*/
    ]),
    actions: {
        menuItemClicked: function(clickedItem){
            var removeSelected = function(items){
                _.each(items, function(item){
                    item.set('selected', false);
                    removeSelected(item.get('children'));
                });
            };
            removeSelected(this.get('menuItems'));
            clickedItem.set('selected', true);

            var route = clickedItem.get('route');
            if(route){
                this.transitionToRoute(route);
            }
        }
    }
});