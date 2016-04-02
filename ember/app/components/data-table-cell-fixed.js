import Ember from 'ember';
import DataTableCellComponent from 'playful/components/data-table-cell';

export default DataTableCellComponent.extend({
    layout: Ember.Handlebars.compile('&nbsp;'),
});
