import Ember from 'ember';
import DataTableRow from 'playful/components/data-table-row';

export default DataTableRow.extend({
  actions: {
    doSort: function(column){
      this.sendAction('sortByColumn', column);
    }
  },
  layout:  Ember.Handlebars.compile(
    '{{#each column in columns}}' +
      '{{data-table-header-cell action="doSort" column=column}}' +
    '{{/each}}'
  ),
  draggable: 'false'
});
