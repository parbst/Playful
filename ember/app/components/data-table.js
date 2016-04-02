import Ember from 'ember';
import _ from 'lodash';
import $ from 'jquery';

export default Ember.Component.extend({
  actions: {
    rowSelected: function(){
      var selectedModels = _.chain(this.get('childViews'))
        .filter(function(cv){ return cv.get('isSelected'); })
        .map(function(cv){ return cv.get('model'); })
        .value();
      this.set('selectedRows', Ember.A(selectedModels));
    },
    sortByColumn: function(column){
      var reversed = this.get('sortedByColumn') === column && !this.get('isSortedReversely');
      var orderedRows = this.get('orderedRows');
      orderedRows.sort(_.bind(column.compare, column));
      if(reversed){
        orderedRows.reverse();
      }
      this.setProperties({
        orderedRows: Ember.copy(orderedRows), 
        'sortedByColumn': column, 
        'isSortedReversely': reversed
      });
    },
    dropRowOnRow: function(from, to, droppedAbove){
      var childViews = _.filter(this.get('childViews'), function(childView){
        return $(childView.get('element')).parent().is('tbody');
      });

      var fromIdx = childViews.indexOf(from),
          toIdx = childViews.indexOf(to);

      if(fromIdx < toIdx){
        toIdx--; // one less when from is removed
      }
      if(!droppedAbove){
        toIdx++;
      }

      var orderedRows = Ember.copy(this.get('orderedRows')),
          tmp = orderedRows.objectAt(fromIdx);
      orderedRows.removeAt(fromIdx);
      orderedRows.insertAt(toIdx, tmp);

      this.setProperties({
        '_draggedRow': null,
        orderedRows: orderedRows,
        sortedByColumn: null
      });
    },
    doubleClickRow: function(model, rowView){
      this.sendAction('doubleClickRow', model, rowView);
    },
    toggleSelectAll: function(){
      var selectedRows = this.get('selectedRows');
      if(this.get('allSelected')){
        selectedRows.clear();
      }
      else{
        selectedRows.addObjects(_.difference(this.get('rows'), selectedRows));
      }
    },
    toggleSelectSome: function(group){
      var selectedRows = this.get('selectedRows'),
          selected = _.intersection(selectedRows, group);
      if(selected.length === group.length){
        // deselect
        selectedRows.removeObjects(group);
      }
      else {
        selectedRows.addObjects(_.difference(group, selectedRows));
      }
    },
    sortGroup: function(column, group){
      if(column.groupSortFn){
        var rows = this.get('orderedRows'),
            sortedGroup = Ember.copy(group).sort(column.groupSortFn),
            rowsIndexMap = _.map(group, function(model){ return _.indexOf(rows, model); });
        _.each(sortedGroup, function(model, idx){
          rows.replace(rowsIndexMap[idx], 1, [model]);
        });
      }
    }
  },
  classNames: ['data-table'],
  rows: Ember.A(),
  columns: Ember.A(),
  selectable: false,
  sortable: false,
  selectedRows: Ember.A(),
  showToggleSelectButton: false,
  _showToggleSelectButton: function(){
    return this.get('isSelectable') && !!this.get('showToggleSelectButton');
  }.property('showToggleSelectButton', 'isSelectable'),
  layout: Ember.Handlebars.compile(
    '{{#if _showToggleSelectButton}}' +
      '<button type="button" {{action "toggleSelectAll"}} class="btn btn-link"> ' +
        '{{#if allSelected}}Deselect{{else}}Select{{/if}} all' +
      '</button> ' +
    '{{/if}}' +
    '<table class="table">' +
      '{{#if _hasHeader}}' + 
        '<thead>' +
          '{{data-table-header-row sortByColumn="sortByColumn"}}' +
        '</thead>' +
      '{{/if}}' +
      '<tbody>' +
        '{{#each orderedRows as |row index|}}' +
          '{{data-table-row ' +
              'dropRow="dropRowOnRow" ' +
              'doubleClick="doubleClickRow" ' +
              'selected="rowSelected" ' +
              'model=row ' +
              'rowIndex=index}}' +
        '{{/each}}' +
      '</tbody>' +
    '</table>'
  ),
  orderedRows: Ember.A(),
  orderedColumns: function(){
    var columns = Ember.copy(this.get('columns')),
        selectColumn;
    if(this.get('isSelectable')){
      selectColumn = DataTableColumn.create({ cellType: 'data-table-cell-checkbox' });
      columns.unshift(selectColumn);
    }
    _.invoke(columns, 'set', 'table', this);
    this.set('selectColumn', selectColumn);
    return columns;
  }.property('columns', 'isSelectable'),
  selectColumn: null,
  isSelectable: Ember.computed.bool('selectable'),
  isSortable: Ember.computed.bool('sortable'),
  sortedByColumn: null,
  isSortedReversely: false,
  allSelected: function(){
    var rows = this.get('rows');
    return this.get('selectedRows').length === rows.length && !!rows.length;
  }.property('selectedRows.[]', 'rows.[]'),
  _hasHeader: function(){
    return _.compact(_.invoke(this.get('columns'), 'get', 'header')).length > 0;
  }.property('columns'),
  _draggedRow: null,
  rowsDidUpdateObserver: function(){
    var rows = Ember.A(),
        selectedRows = this.get('selectedRows');
    _.each(this.get('rows'), function(row){ rows.push(row); });
    this.set('orderedRows', rows);
    selectedRows.removeObjects(_.difference(selectedRows, rows));
  }.observes('rows', 'rows.length').on('init'),
  selectedRowsObserver: function(){
    var selectedRows = this.get('selectedRows'),
        shouldBeSelected = _.select(this.get('childViews'), function(cv){ return _.contains(selectedRows, cv.get('model')); }),
        shouldNotBeSelected = _.difference(this.get('childViews'), shouldBeSelected);
     _.invoke(shouldBeSelected, 'set', 'isSelected', true);
     _.invoke(shouldNotBeSelected, 'set', 'isSelected', false);
   }.observes('selectedRows.[]').on('init')
});

var DataTableColumnIconDefinition = Ember.Object.extend({
  bootstrapIcon: null,
  fontAwesomeIcon: null,
  fontAwesomeIconSize: null,
  fontAwesomeSpin: false,
  modelProperty: null,
  propertyToIconMapping: null,
  isBootstrap: function(){
    return this.get('bootstrapIcon') !== null;
  }.property('bootstrapIcon'),
  isFontAwesome: function(){
    return this.get('fontAwesomeIcon') !== null;
  }.property('fontAwesomeIcon'),
  icon: function(rowModel){
    var modelProp = this.get('modelProperty'),
        propMapping = this.get('propertyToIconMapping');
    if(modelProp){
      var modelVal = rowModel.get(modelProp);
      if(!Ember.isEmpty(propMapping)){
        return propMapping[modelVal];
      }
      else {
        return modelVal;
      }
    }
    else {
      return this.get('isBootstrap') ? this.get('bootstrapIcon') : this.get('fontAwesomeIcon');
    }
  }
});

var DataTableColumn = Ember.Object.extend({
  header: null,
  property: null,
  table: null,
  rows: Ember.computed.alias('table.orderedRows'),
  cellType: 'data-table-cell',
  iconDefinition: DataTableColumnIconDefinition.create(),
  popoverComponent: null,
  staticAttributes: {},
  bindingAttributes: {},
  _componentTemplate: _.template(
    '{{<%= name %> ' +
      '<% _.each(staticAttrs, function(value, key) { %>' +
        '<%= key %>="<%= value %>" ' +
      '<% }); %>' +
      '<% _.each(bindingAttributes, function(value, key) { %>' +
        '<%= key %>=<%= value %> ' +
      '<% }); %>' +
    '}}'
  ),
  compare: function(modelA, modelB){
    var prop = this.get('property'),
        valA = modelA.get(prop),
        valB = modelB.get(prop);

    if (valA < valB){
      return -1;
    }
    if (valA > valB){
      return 1;
    }
    return 0;
  },
  _getAllTemplateAttributes: function(){

  },
  getCellLayout: function(model, rowIndex, columnIndex, isSelectColumn){
    var staticAttrs = Ember.copy(this.get('staticAttributes')),
        bindingAttributes = Ember.copy(this.get('bindingAttributes'));
    staticAttrs.columnIndex = columnIndex;
    if(isSelectColumn){
      bindingAttributes.isSelected = 'isSelected';
    }

    return this._componentTemplate({
      name: this.get('cellType'), 
      staticAttrs: staticAttrs,
      bindingAttributes: bindingAttributes
    });
  }
});

var DataTableGroupColumn = DataTableColumn.extend({
  cellType: 'data-table-cell-group',
  // signature currentModel, currentRowIdx
  groups: function(){
    var byGroup = _.groupBy(this.get('rows'), this.groupFn);
    delete byGroup[false];
    return _.values(byGroup);
  }.property('rows', 'groupFn'),
  localGroups: function(){
    var groups = this.get('groups');
    var curGroup, localGroup, result = Ember.A(), rowGroup;
    _.each(this.get('rows'), function(row){
      rowGroup = _.find(groups, function(group){
        return _.contains(group, row);
      });
      if(rowGroup){
        if(!curGroup){
          curGroup = rowGroup;
          localGroup = [];
        }
        if(curGroup !== rowGroup){
          result.push(localGroup);
          curGroup = rowGroup;
          localGroup = [];
        }
        localGroup.push(row);
      }
    });
    if(!_.isEmpty(localGroup)){
      result.push(localGroup);
    }
    return result;
  }.property('groups.[]', 'table.orderedRows.[]'),
  selectedGroups: function(){
    var selectedRows = this.get('table.selectedRows');
    return _.filter(this.get('groups'), function(group){
      return _.intersection(group, selectedRows).length === group.length;
    });
  }.property('groups.@each', 'table.selectedRows.@each'),
  groupFn: function(model){
    return false;
  },
  groupSortFn: function(){
    return 0;
  },
  getGroupForModel: function(model){
    return _.find(this.get('groups'), function(group){
      return _.contains(group, model);
    });
  },

  getLocalGroupForModel: function(model, rowIndex){
    return _.find(this.get('localGroups'), function(localGroup){
      return _.contains(localGroup, model);
    });
  },

  getCellLayout: function(model, rowIndex, columnIndex, isSelectColumn){
    var rows = this.get('rows'),
        group = this.getGroupForModel(model, rowIndex);
    if(!group){
      return false;
    }
    var localGroup = this.getLocalGroupForModel(model, rowIndex);
    if(_.first(localGroup) === model){
      this.get('staticAttributes').toggleSelect = "toggleSelectSome";
      this.get('staticAttributes').sort = 'sortGroup';
      this.get('bindingAttributes').targetObject = 'parentView';
      return this._super(model, rowIndex, columnIndex, isSelectColumn);
    }
    return false;
  }

});

export { DataTableColumn, DataTableColumnIconDefinition, DataTableGroupColumn };
