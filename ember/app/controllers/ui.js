import Ember from 'ember';
import { DataTableColumn, DataTableColumnIconDefinition } from 'playful/components/data-table';

export default Ember.Controller.extend({
  actions: {
    hello: function(){
      window.alert('hello from controller!');
    }
  },
  columnsTest: Ember.A([
    DataTableColumn.create({ property: 'name', cellType: 'data-table-cell-icon', 
                             iconDefinition: DataTableColumnIconDefinition.create({ bootstrapIcon: 'stats' }) }),
    DataTableColumn.create({ property: 'value', cellType: 'data-table-cell-icon', 
                             iconDefinition: DataTableColumnIconDefinition.create({ fontAwesomeIcon: 'refresh', fontAwesomeIconSize: 'lg', fontAwesomeSpin: true }) }),
    DataTableColumn.create({ property: 'name', header: 'Object name' }),
    DataTableColumn.create({ property: 'value', header: 'Object value' }),
    DataTableColumn.create({ property: 'edit', cellType: 'data-table-cell-edit' }),
    DataTableColumn.create({ cellType: 'data-table-cell-popover-icon', 
                             iconDefinition: DataTableColumnIconDefinition.create({ bootstrapIcon: 'edit' }),
                             popoverComponent: 'audio-tags-edit' })
//                             popoverComponent: 'edit-audio-data-table' })
  ]),
  rowsTest: Ember.A([
    Ember.Object.create({ name: 'object 1', value: 'value 1', edit: 'edit in place' }),
    Ember.Object.create({ name: 'object 2', value: 'value 1', edit: 'edit in place' }),
    Ember.Object.create({ name: 'object 3', value: 'value 2', edit: 'edit in place' }),
    Ember.Object.create({ name: 'object 4', value: 'value 1', edit: 'edit in place' }),
    Ember.Object.create({ name: 'object 5', value: 'value 1', edit: 'edit in place' }),
    Ember.Object.create({ name: 'object 6', value: 'value 1', edit: 'edit in place' }),
    Ember.Object.create({ name: 'object 7', value: 'value 1', edit: 'edit in place' })
  ]),
  selectedRowsTest: Ember.A(),
  selectableDataTable: true,
  sortableDataTable: true,
  twoColumnDataProperty: Ember.A([
    'A', 'B', 'C'
  ]),
  twoColumnDataPropertyReadonly: Ember.A([
    'A'
  ]),
  twoColumnDataModel: Ember.Object.create({
    A: 'The A value',
    B: 'The B value',
    C: 'The C value'
  }),
  twoColumnDataModelCObserver: function(){
    console.log('C value changed!');
  }.observes('twoColumnDataModel.C'),
  typeaheadContent: Ember.A([
    Ember.Object.create({ name: 'Glenn Quagmire', value: 'a'}),
    Ember.Object.create({ name: 'Joe Swanson', value: 'a'}),
    Ember.Object.create({ name: 'Bonnie Swanson', value: 'a'}),
    Ember.Object.create({ name: 'Cleveland Brown', value: 'a'}),
    Ember.Object.create({ name: 'Loretta Brown', value: 'a'}),
    Ember.Object.create({ name: 'Peter Griffin', value: 'a'}),
    Ember.Object.create({ name: 'Lois Griffin', value: 'a'}),
    Ember.Object.create({ name: 'Meg Griffin', value: 'a'}),
    Ember.Object.create({ name: 'Chris Griffin', value: 'a'}),
    Ember.Object.create({ name: 'Stewie Griffin', value: 'a'}),
    Ember.Object.create({ name: 'Brian Griffin', value: 'a'}),
    Ember.Object.create({ name: 'John Herbert', value: 'a'}),
    Ember.Object.create({ name: 'Mort Goldman', value: 'a'}),
    Ember.Object.create({ name: 'Muriel Goldman', value: 'a'}),
    Ember.Object.create({ name: 'Neil Goldman', value: 'a'}),
    Ember.Object.create({ name: 'Kevin Swanson', value: 'a'}),
    Ember.Object.create({ name: 'Susie Swanson', value: 'a'}),
    Ember.Object.create({ name: 'Tom Tucker', value: 'a'}),
    Ember.Object.create({ name: 'Diane Simmons', value: 'a'}),
    Ember.Object.create({ name: 'Tricia Takanawa', value: 'a'}),
    Ember.Object.create({ name: 'Ollie Williams', value: 'a'}),
    Ember.Object.create({ name: 'Borgmester Adam West', value: 'a'}),
    Ember.Object.create({ name: 'Bruce', value: 'a'}),
    Ember.Object.create({ name: 'Consuela', value: 'a'}),
    Ember.Object.create({ name: 'Døden', value: 'a'}),
    Ember.Object.create({ name: 'Doktor Elmer Hartman', value: 'a'}),
    Ember.Object.create({ name: 'James Woods', value: 'a'}),
    Ember.Object.create({ name: 'Jasper', value: 'a'}),
    Ember.Object.create({ name: 'Rupert', value: 'a'})
  ]),
  typeaheadSelected: null,
  typeaheadQuery: null,
  thumbnailGridImages: Ember.A([
    Ember.Object.create({ image: 'images/test1.jpg', description: 'Monkey with a gun' }),
    Ember.Object.create({ image: 'images/test2.jpg', description: 'Lady monkey with a gun' }),
    Ember.Object.create({ image: 'images/test3.jpg', description: 'Sniper monkey' }),
    Ember.Object.create({ image: 'images/test4.jpg', description: 'Shotgun monkey' }),
    Ember.Object.create({ image: 'images/test1.jpg', description: 'Monkey with a gun' }),
    Ember.Object.create({ image: 'images/test2.jpg', description: 'Lady monkey with a gun' }),
    Ember.Object.create({ image: 'images/test3.jpg', description: 'Sniper monkey' }),
    Ember.Object.create({ image: 'images/test4.jpg', description: 'Shotgun monkey' }),
    Ember.Object.create({ image: 'images/test1.jpg', description: 'Monkey with a gun' }),
    Ember.Object.create({ image: 'images/test2.jpg', description: 'Lady monkey with a gun' }),
    Ember.Object.create({ image: 'images/test3.jpg', description: 'Sniper monkey' }),
    Ember.Object.create({ image: 'images/test1.jpg', description: 'Monkey with a gun' }),
    Ember.Object.create({ image: 'images/test2.jpg', description: 'Lady monkey with a gun' }),
    Ember.Object.create({ image: 'images/test3.jpg', description: 'Sniper monkey' }),
    Ember.Object.create({ image: 'images/test4.jpg', description: 'Shotgun monkey' }),
    Ember.Object.create({ image: 'images/test1.jpg', description: 'Monkey with a gun' }),
    Ember.Object.create({ image: 'images/test2.jpg', description: 'Lady monkey with a gun' }),
    Ember.Object.create({ image: 'images/test3.jpg', description: 'Sniper monkey' }),
    Ember.Object.create({ image: 'images/test4.jpg', description: 'Shotgun monkey' })
  ]),
  thumbnailGridSelected: Ember.A(),
  selectableThumbnailGrid: true,
  selectMultipleThumbnailGrid: true,
  treeData: {
    label: 'root',
    children: [
      {
        label: 'child 1'
      },
      {
        label: 'child 2',
        children: [
          {
            label: 'child 2.1'
          },
          {
            label: 'child 2.2',
            children: [
              {
                label: 'child 2.2.1'
              }
            ]
          }
        ]
      },
      {
        label: 'child 3'
      }
    ],
  },
  treeData2: {
    ordinary: 'value',
    aNumber: 2,
    hereIsADate: new Date(),
    doNotForgetTheChildren: {
      aChildObject: 'with a value',
      aChildList: [ 1, 2, 3 ]
    }
  },
  init: function(){
    this._super();
    window.uiController = this;
  }
});
