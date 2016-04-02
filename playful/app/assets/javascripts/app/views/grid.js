Grid = Em.Namespace.create();

Grid.doubleClickTime = 1000;
Grid.lastClick = null;

Grid.CellMixin = Em.Mixin.create({
    selectableBoolBinding: 'parentView.parentView.parentView.selectableBool',
    addColumnClass: function(){
        var columnClass = Convert.toArray(this.get('column').get('columnClass')), 
            classNames = this.get('classNames');
        this.set('classNames', _.uniq(_.union(classNames, columnClass)))
    },
    mouseDown: function(e){
        // jquery ui selectable breaks the double click event. this code simulates it
        if(this.get('selectableBool')){
            var curTime = new Date().getTime();
            var isDoubleClick = Grid.lastClick !== null && 
                curTime - Grid.lastClick.when < Grid.doubleClickTime &&
                e.pageX == Grid.lastClick.x && e.pageY == Grid.lastClick.y;
            Grid.lastClick = { x: e.pageX, y: e.pageY, when: curTime };
            if(isDoubleClick){
                this.$().dblclick();
                Grid.lastClick = null;
            }
        }
    },
    cellValue: null,
    updateCellValue: function(){
        this.set('cellValue', this.get('column').getValue(this.get('content')));
    }.observes('column', 'content').on('init'),
    propertyNameDidChange: function(){
        var prop = this.get('column.propertyName');
        if(prop){
            // which property to observe is dynamic (but practically static) so manually add observer
            this.get('content').addObserver(prop, this, 'updateCellValue');
        }
    }.observes('column.propertyName').on('init')
});

Grid.CellView = Ember.View.extend(Grid.CellMixin, {
    tagName: 'td',
    init: function() {
        this._super();
        this.addColumnClass();
    }
});

Grid.EditableCellTextField = Ember.TextField.extend({
    didInsertElement: function(){
        this.set('value', this.get('originalValue'));
        this.$().focus();
        // select may not happen before the value is propagated to the DOM
        var elem = this.get('element'); 
        setTimeout(function(){
            elem.select();
        }, 0);
    },
    focusOut: function(){
        this.get('parentView').inputSubmit();
    },
    keyUp: function(e){
        this._super();
        if(e.keyCode == 27){
            // hit the ESC button
            this.get('parentView').inputCancel();
        }
        else if (e.keyCode == 13){
            // hit the enter button
            this.get('parentView').inputSubmit();
        }
    }
});

Grid.EditableCellView = Ember.ContainerView.extend(Grid.CellMixin, {
    editEnabled: false,
    tagName: 'td',
    classNames: Em.A(),
    readOnlyBinding: 'parentView.content.readOnly',
    columnValidateBinding: 'column.validate',
    rowValidateBinding: 'parentView.content.validate',
    toTextMode: function(){
        this.set('textView', Ember.View.create({
            template: this.get('template'),
            content: this.get('content')
        }));
        this.removeAllChildren();
        this.pushObject(this.get('textView'));
        this.set('editEnabled', false);
    },
    setCellValue: function(value){
        return this.get('column').setValue(this.get('content'), value);
    },
    toEditMode: function(){
        this.set('inputView', Grid.EditableCellTextField.create({
            originalValue: this.get('cellValue'),
            size: this.get('cellValue').length || 20
        }));
        this.removeAllChildren();
        this.pushObject(this.get('inputView'));
    },
    init: function() {
        this._super();
        this.editableDidChange();
        this.readOnlyDidChange();
        this.addColumnClass();
    },
    editableDidChange: function(){
        if(this.get('editEnabled')){
            this.toEditMode();
        }
        else{
            this.toTextMode();
        }
    }.observes('editEnabled'),
    doubleClick: function(){
        if(!this.get('readOnly')){
            this.set('editEnabled', true);
        }
    },
    inputCancel: function(){
        this.set('editEnabled', false);
    },
    inputSubmit: function(){
        if(this.get('editEnabled')){
            var inputVal = this.get('inputView.value'),
                validate = this.get('rowValidate') || this.get('columnValidate');
            if(inputVal != this.get('cellValue')){
                var validationResult = validate && validate(inputVal),
                    validates = !validate || Validation.isOk(validationResult);
                if(validates){
                    this.setCellValue(inputVal);
                }
                else{
// TODO: this could be nicer i guess
                    alert("Validation failed for " + inputVal + ": " + validationResult.value.join(', '))
                }
            }
            this.set('editEnabled', false);
        }
    },
    readOnlyDidChange: function(){
        if(this.get('readOnly')){
            this.set('classNames', Em.A(_.without(this.get('classNames'), 'grid-cell-editable')));
        }
        else{
            this.get('classNames').push('grid-cell-editable')
        }
    }.observes('readOnly')
});

Grid.CellSortView = Grid.CellView.extend({
    tagName: 'td',
    classNames: ['grid-cell-sortable']
});

Grid.CellSelectView = Grid.CellView.extend({
    tagName: 'td',
    classNames: ['grid-cell-select']
});

Grid.CellRowTypeView = Grid.CellView.extend({
    tagName: 'td',
    classNames: ['grid-cell-row-type'],
    attributeBindings: ['style', 'title'],
    propertyNameBinding: 'column.propertyName',
    title: function(){
        var prop = this.get('column.propertyName');
        if(prop){ prop += ': '; }
        return _.str.humanize(prop) + this.get('cellValue');
    }.property('cellValue', 'propertyName'),
    style: function(){
        var value = this.get('cellValue'),
            myColor = this.get('column').getColorFor(value),
            result = '';
        if(myColor){
            result = 'background-color: ' + myColor + ';'
        }
        return result;
    }.property('column.colorMap', 'cellValue')
});

Grid.Column = Ember.Object.extend({
    visible: true,
    propertyName: 'constructor',
    title: null,
    formatter: '{{view.content.%@}}',
    columnClassNames: Em.A(),
    rows: Em.A(),
    template: function(){
        return this.get('formatter').fmt(this.get('propertyName'));
    }.property('formatter', 'propertyName'),
    getValue: function(rowContent){
        return rowContent.get(this.get('propertyName'));
    },
    setValue: function(rowContent, newValue){
        rowContent.set(this.get('propertyName'), newValue);
    },
    viewClass: function(){
        return Grid.CellView.extend({
            template: Ember.Handlebars.compile(this.get('template'))
        });
    }.property('template'),
    header: function(){
        var result = this.get('title');
        if(!result){
            result = this.get('propertyName')
        }
        return result;
    }.property('propertyName', 'title')
});

Grid.SortColumn = Grid.Column.extend({
    viewClass: function(){
        return Grid.CellSortView.extend({ template: '' });
    }.property()
});

Grid.SelectColumn = Grid.Column.extend({
    viewClass: function(){
        return Grid.CellSelectView.extend({ template: '' });
    }.property()
});

Grid.RowTypeColumn = Grid.Column.extend({
    viewClass: function(){
        return Grid.CellRowTypeView.extend({ template: '' });
    }.property(),
    staticColorMap: [
        'LightPink', 'Thistle', 'Orchid', 'MediumPurple', 'DarkSlateBlue', 'Olive', 'OliveDrab', 'SpringGreen',
        'SeaGreen', 'DarkGreen', 'Tomato', 'Gold', 'Moccasin', 'PaleGoldenrod', 'Khaki', 'DarkKhaki', 'DarkSalmon',
        'IndianRed', 'FireBrick', 'MediumAquamarine', 'PaleTurquoise', 'LightSeaGreen', 'CadetBlue', 'PowderBlue',
        'LightBlue', 'CornflowerBlue', 'Navy', 'Silver', 'DimGray', 'DarkSlateGray', 'RosyBrown', 'Wheat'
    ],
    colorMap: {},
    getColorFor: function(propertyValue){
        var colorMap = this.get('colorMap');
        if(!_.isEmpty(propertyValue) && _.isEmpty(colorMap[propertyValue])){
            var staticMap = this.get('staticColorMap');
            colorMap[propertyValue] = staticMap[_.keys(colorMap).length];
        }
        return colorMap[propertyValue];
    }
});

Grid.EditableColumn = Grid.Column.extend({
    viewClass: function(){
        return Grid.EditableCellView.extend({
            template: Ember.Handlebars.compile(this.get('template'))
        });
    }.property()
});

Grid.DefaultSortColumn = Grid.SortColumn.create();
Grid.DefaultSelectColumn = Grid.SelectColumn.create();

Grid.GridView = Ember.View.extend({
    style: '',
    columns: Ember.A(),
    rows: Ember.A(),
    selectedRows: Ember.A(),
    sortable: false,
    selectable: false,
    displayHeader: true,
    emptyText: 'no data',
    doubleClickedRow: null,
    clickedRow: null,

    tagName: 'table',
    attributeBindings: ['style'],
    sortableBool: function(){ return Convert.toBool(this.get('sortable')) }.property('sortable'),
    selectableBool: function(){ return Convert.toBool(this.get('selectable')) }.property('selectable'),
    classNames: ['grid-table'],
    visibleColumns: function () {
        return this.get('columns').filterProperty('visible', true);
    }.property('columns.@each.visible'),
    defaultTemplate: Ember.Handlebars.compile('<thead>{{view Grid.HeaderView}}</thead>{{view Grid.BodyView}}'),
    updateSelectedRows: function(){
        var me = this,
            prevSelectedRows = this.get('selectedRows').toArray(),
            curSelectedRows = [];
        $('tr.ui-selectee', $(this.get('element'))).each(function(idx, trElement){
            if($(trElement).hasClass('ui-selected')){
                curSelectedRows.push(me.get('rows')[idx - 1])
            }
        });
        var intersection = _.intersection(curSelectedRows, prevSelectedRows)
        if(intersection.length != Math.max(prevSelectedRows.length, curSelectedRows.length)){
            // change occurred, update
            this.set('selectedRows', Em.A(curSelectedRows));
        }
    }.observes('rows.@each'),
    selectStop: function(){
        this.updateSelectedRows();
    },
    clearSelection: function(){
        $('.ui-selected', this.get('element')).removeClass('ui-selected');
        this.updateSelectedRows();
    },
    didInsertElement: function(){
        if(this.get('selectableBool')){
            var me = this, lastClick = null;
            $(this.get('element')).bind("mousedown", function (e) {
                // creates a toggle like deselecting behavior, but only if a single entry is selected
                var selectedElements = $("tr.ui-selected", $(me.get('element')));
                if(selectedElements.length == 1 && selectedElements[0] == e.target.parentNode){
                    e.metaKey = true;
                }
            }).selectable({
                stop: _.bind(this.selectStop, this),
                filter: 'tr',
                cancel: 'td.grid-cell-sortable,td.grid-cell-editable,input,textarea,button,select,option'
            })
        }
    },
    selectableDidChange: function(){
//        console.log("gridview selectableDidChange")
    }.observes('selectable'),
    getRowFromTdEvent: function(e){
        var parentRow = $(e.target).parents('tr').first(),
            selectedRowIdx = parentRow.index(),
            rows = this.get('rows');
        if(selectedRowIdx >= 0 && selectedRowIdx < rows.length){
            return rows[selectedRowIdx];
        }
    },
    doubleClick: function(e){
        this.set('doubleClickedRow', this.getRowFromTdEvent(e));
    },
    rowsDidChange: function(){
        if(this.get('selectableBool')){
            this.set('selectedRows', Em.A())
        }
    }.observes('rows'),
    click: function(e){
        this.set('clickedRow', this.getRowFromTdEvent(e));
    }
});

Grid.HeaderView = Ember.CollectionView.extend({
    tagName: 'tr',
    contentBinding: 'parentView.visibleColumns',
    displayBinding: 'parentView.displayHeader',
    classNameBindings: ['display:grid-hidden'],
    itemViewClass: Ember.View.extend({
        tagName: 'th',
        template: Ember.Handlebars.compile('{{view.content.header}}')
    })
});

Grid.BodyView = Ember.CollectionView.extend({
    tagName: 'tbody',
    contentBinding: 'parentView.rows',
    itemViewClass: 'Grid.RowView',
    sortStop: function(){
        var domRows = $('tr', this.get('element')),
            rows = this.get('content'),
            startPosition = this.get('sortStartPosition'),
            endPosition = domRows.index(this.get('sortElement'));

        this.set('sortStartPosition', null);
        this.set('sortElement', null);
        if(endPosition != startPosition){
            var tmp = rows.objectAt(startPosition);
            rows.replace(startPosition, 1, []);
            rows.replace(endPosition, 1, [tmp, rows.objectAt(endPosition)]);
        }
        this.get('parentView').clearSelection();
    },
    sortStart: function(){
        var rows = $('tr', this.get('element')),
            placeholder = $('tr.ui-sortable-placeholder', this.get('element')),
            sortStartPosition = rows.index(placeholder) - 1;
        this.set('sortStartPosition', sortStartPosition);
        this.set('sortElement', placeholder.prev());
        this.get('childViews')[sortStartPosition].dismissTooltip();
    },
    sortStartPosition: null,
    sortElement: null,
    didInsertElement: function(){
        if(this.get('parentView').get('sortableBool')){
            $(this.get('element')).sortable({
                axis: 'y',
                handle: 'td.grid-cell-sortable',
                stop: _.bind(this.sortStop, this),
                start: _.bind(this.sortStart, this),
                // Hack to increase the placeholder width
                helper : function(e, ui) {
                    ui.children().each(function() {
                        $(this).width($(this).width());
                    });
                    return ui;
                }
            })
        }
    }
/*
    emptyView: Ember.View.extend({
        tagName: 'tr',
        template: Ember.Handlebars.compile('<td {{bindAttr colspan="parentView.columns.length"}}>{{gof}}.</td>')
    })
*/
});

Grid.RowView = Ember.ContainerView.extend({
    tagName: 'tr',
    columnsBinding: 'parentView.parentView.visibleColumns',
    classNameBindings: ['contentClass'],
    rowBinding: 'content',
    contentClass: function(){
        var content = this.get('content'),
            rowClass = content.get('rowClass');
        if(rowClass){
            return rowClass;
        }
    }.property('row.rowClass'),
    rowTooltipDidChange: function(){
        var content = this.get('content'),
            tooltip = content.get('rowTooltip'),
            jqElem = this.$();
        if(jqElem){
            try{
                jqElem.tooltip('hide');
                jqElem.tooltip('destroy');
            }
            catch(err){
                ; // silent catch
            }
        }
        if(tooltip && jqElem){
            if(_.isString(tooltip)){
                tooltip = { title: tooltip };
            }
            tooltip.delay = { show: 300, hide: 100 };
            jqElem.tooltip(tooltip);
        }
    }.observes('row.rowTooltip'),
    pushCell: function(column){
        var cell = column.get('viewClass').create({
            column: column,
            content: this.get('row')
        });
        this.pushObject(cell);
    },
    columnsDidChange: function(){
        if (this.get('columns')) {
            var sortable = this.get('parentView').get('parentView').get('sortableBool'),
                selectable = this.get('parentView').get('parentView').get('selectableBool');

            this.clear();

            if(selectable){
                // inject the first selectable solumn
                this.pushCell(Grid.DefaultSelectColumn);
            }

            this.get('columns').forEach(_.bind(this.pushCell, this));

            if(sortable){
                // inject the last sortable solumn
                this.pushCell(Grid.DefaultSortColumn);
            }
        }
    }.observes('columns.@each'),
    didInsertElement: function(){
        this.columnsDidChange();
        this.rowTooltipDidChange();
    },
    dismissTooltip: function(){
        var content = this.get('content'),
            tooltip = content.get('rowTooltip');
        if(tooltip){
            this.$().tooltip('hide');
        }        
    }
});
