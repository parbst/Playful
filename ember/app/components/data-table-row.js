import Ember from 'ember';
import _ from 'lodash';

export default Ember.Component.extend({
  tagName: 'tr',
  columnsBinding: 'parentView.orderedColumns',
  selectColumnBinding: 'parentView.selectColumn',
  isSelected: false,
  isSortableBinding: 'parentView.isSortable',
  model: Ember.Object.create(),
  classNames: ['draggable-dropzone', 'draggable-item', 'data-table-row'],
  classNameBindings: ['dragOverClass', 'dragOverPosition:upper:lower'],
  attributeBindings: ['draggable'],
  dragOverClass: 'drag-over-deactivated',
  draggable: function(){ return this.get('isSortable').toString(); }.property('isSortable'),
  dragOverPosition: null,
  draggedRowBinding: 'parentView._draggedRow',
  rowIndex: null,
  selectedRowsBinding: 'parentView.selectedRows',

  eventManager: Ember.Object.create({
    doubleClick: function(event, view) {
      var trElem = view;
      while(trElem.get('tagName').toLowerCase() !== 'tr'){
        trElem = view.get('parentView');
      }
      trElem.sendAction('doubleClick', trElem.get('model'), trElem);
    }
  }),

  dragLeave: function(event) {
    if(this.get('draggable') === 'true'){
      event.preventDefault();
    }
    this.set('dragOverClass', 'drag-over-deactivated');
  },

  dragOver: function(event) {
    var dragY = event.originalEvent.pageY,
        elemRect = event.target.getBoundingClientRect(),
        halfway = elemRect.top + elemRect.height / 2;
    this.set('dragOverPosition', dragY < halfway);
    if(this.get('draggable') === 'true'){
      this.set('dragOverClass', 'drag-over-activated');
      event.preventDefault();
    }
  },

  drop: function() {
    this.set('dragOverClass', 'drag-over-deactivated');
    //var data = event.dataTransfer.getData('text/data');
    this.sendAction('dropRow', this.get('draggedRow'), this, this.get('dragOverPosition'));
  },

  dragStart: function(event) {
    this.set('draggedRow', this);
    event.dataTransfer.setData('text/data', 'data-table-row');
  },

  layout: function(){
    var selectColumn = this.get('selectColumn'),
        columnsString = _.map(this.get('columns'), function(column, idx){
          var cellLayout = column.getCellLayout(this.get('model'), this.get('rowIndex'), idx, column === selectColumn);
          return cellLayout || '';
        }, this).join('');
    return Ember.Handlebars.compile(columnsString);
  }.property('model', 'columns', 'selectColumn', 'groupCellColumns'),
  _rowSelectedObserver: function(){
    this.sendAction('selected', this);
  }.observes('isSelected'),
  rerenderObserver: function(){
    this.notifyPropertyChange('layout'); // this is, for some reason, necessary
    this.rerender();
  }.observes('columns', 'columns.@each.localGroups'),
  // returns the columns for which this row prints the group cell
  groupCellColumns: function(){
    var model = this.get('model');
    return _.filter(this.get('columns'), function(column){
      return _.any(column.get('localGroups'), function(localGroup){
        return _.first(localGroup) === model;
      });
    });
  }.property('columns.@each.localGroups')
});
