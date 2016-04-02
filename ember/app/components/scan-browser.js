import Ember from 'ember';
import _ from 'lodash';
import ScanAdapter from 'playful/adapters/scan';
import { DataTableColumn, DataTableColumnIconDefinition } from 'playful/components/data-table';

export default Ember.Component.extend({
  classNames: ['scan-browser'],
  root: null,
  dir: null,
  model: null,
  showModal: 'showModal',
  actions: {
    fileDoubleClick: function(scan){
      window.getSelection().removeAllRanges(); // remove text selection
      if(scan.get('type') === 'directory'){
        this.set('dir', scan.get('path'));
      }
    },
    levelUp: function(){
      var dirs = this.get('dirDropDownContent');
      this.set('dirDropDownSelection', dirs[dirs.length - 2]);
    },
    showScanDetails: function(){
      this.sendAction('showModal', 'modal-scan-details', this.get('selectedFiles'));
    }
  },
  rootDidChange: function(){
    this.set('dir', this.get('root'));
  }.observes('root').on('init'),
  dirDidChange: function(){
    var me = this,
        adapter = ScanAdapter.create();
    this.set('isLoading', true);
    adapter.findByDir(this.get('dir')).done(function(result){
      me.set('model', result);
    }).always(function(){
      me.set('isLoading', false);
    });
  }.observes('dir'),
  _columns: Ember.A([
    DataTableColumn.create({ 
      cellType: 'data-table-cell-icon', 
      iconDefinition: DataTableColumnIconDefinition.create({ 
        fontAwesomeIcon: true,
        modelProperty: 'icon',
        fontAwesomeIconSize: 'lg'
      }) 
    }),
    DataTableColumn.create({ property: 'filename' }),
  ]),
  _rows: function(){
    var compare = function(a, b){
      var aDir = a.get('isDirectory'),
          bDir = b.get('isDirectory'),
          aFn = a.get('filename'),
          bFn = b.get('filename'),
          strCmp = aFn === bFn ? 0 : aFn > bFn ? 1 : -1;
      if ((aDir ? 1 : 0) ^ (bDir ? 1 : 0)) {
        return aDir ? -1 : 1;
      }
      return strCmp;
    };

    var result = Ember.A();
    if(Ember.isArray(this.get('model'))) {
      result = this.get('model');
      result.sort(compare);
    }
    return result;
  }.property('model'),
  selectedFiles: Ember.A(),
  dirDropDownContent: function(){
    var dirPieces = _.compact(this.get('dir').split('/')),
        dirPiecesReversed = Array.prototype.slice.call(dirPieces).reverse(),
        indices = _.range(dirPieces.length).reverse();
    return _.map(indices, function(idx){ 
      return { 
        label: dirPiecesReversed.slice(idx).reverse().join('/'),
        value: idx
      }; 
    });
  }.property('dir'),
  dirDropDownSelection: function(key, value) {
    if(arguments.length > 1){
      this.set('dir', value.label);
      return value;
    }
    return _.last(this.get('dirDropDownContent'));
  }.property('dirDropDownContent'),
  levelUpDisabled: function(){
    return this.get('dirDropDownContent').length < 2 ? 'disabled': false;
  }.property('dirDropDownContent'),
  scanDetails: function(){
    return this.get('selectedFiles').length !== 1;
  }.property('selectedFiles'),
  isLoading: false,
  allSelected: false,
  layout: Ember.Handlebars.compile(
    '<div class="input-group">' +
      '{{view "select" ' +
         'content=dirDropDownContent ' +
         'optionValuePath="content.value" ' +
         'optionLabelPath="content.label" ' +
         'selection=dirDropDownSelection ' +
         'classNames="form-control"}} ' +
      '<span class="input-group-btn">' +
        '<button type="button" class="btn btn-default" {{action "levelUp"}} {{bind-attr disabled=levelUpDisabled}}>' +
          '{{icon-fontawesome icon="level-up"}}' +
        '</button>' +
        '<button type="button" class="btn btn-default" {{action "showScanDetails"}} {{bind-attr disabled=scanDetails}}>' +
          '{{icon-fontawesome icon="info"}}' +
        '</button>' +
      '</span>' +
    '</div>' +
    '{{#if isLoading}}' +
       '<div class="loading text-center">' +
         '{{icon-fontawesome icon="spinner" size="lg" spin="1"}}' +
       '</div>' +
    '{{else}}' +
      '{{data-table ' +
          'columns=_columns ' +
          'rows=_rows ' +
          'selectable="1" ' +
          'selectedRows=selectedFiles ' +
          'allSelected=allSelected ' +
          'showToggleSelectButton="1" ' + 
          'doubleClickRow="fileDoubleClick" }}' +
    '{{/if}}'
  )
});

