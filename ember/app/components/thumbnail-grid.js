import Ember from 'ember';
import _ from 'lodash';

export default Ember.Component.extend({
  classNames: 'thumbnail-grid',
  images: Ember.A(),
  imageSrcProperty: 'image',
  imageDescriptionProperty: 'description',
  selected: Ember.A(),
  selectable: false,
  selectMultiple: false,
  isSelectable: function(){
    return !!this.get('selectable');
  }.property('selectable'),
  isSelectMultiple: function(){
    return this.get('isSelectable') && !!this.get('selectMultiple');
  }.property('selectMultiple', 'isSelectable'),
  actions: {
    toggleSelected: function(itemView, model){
      if(this.get('isSelectable')){
        var newState = !itemView.get('selected'),
            selected = this.get('selected');
        if(newState && (!selected || selected.length === 0 || this.get('isSelectMultiple'))){
          this.get('selected').pushObject(model);
        }
        else if (!newState) {
          this.get('selected').removeObject(model);
        }
        else {
          return;
        }
        itemView.set('selected', newState);
      }
    }
  },
  _selectObserver: function(){
    var selected = this.get('selected');
    if(this.get('isSelectable')){
      if(!this.isSelectMultiple){
        while(selected.length > 1){
          selected.removeAt(1);
        }
      }
    }
    else {
      selected.clear();
    }
    _.each(this.get('childViews'), function(cv){
      cv.set('selected', _.contains(selected, cv.get('model')));
    });
  }.observes('isSelectable', 'isSelectMultiple'),
  layout: Ember.Handlebars.compile(
    '{{#each model in images}}' +
      '{{thumbnail-grid-item model=model action="toggleSelected"}}' +
    '{{/each}}' +
    '<div class="clearfix"></div>'
  )
});