import Ember from "ember";

export default Ember.TextField.extend({
  intitializeTypeahead: Ember.observer(function(){
    Ember.run.scheduleOnce('afterRender', this, '_initializeTypeahead');
  }).on('didInsertElement'),

  classNames: ['form-control', 'twitter-typeahead'],
  _selected: null,
  _ttSourceCallback: null,
  _placeholder: null,

  suggestions: Ember.A(),

  keyUp: function(event){
    if (event.which === 13){
      var $dropdownMenu = this.$().siblings('.tt-dropdown-menu');
      var $suggestions = $dropdownMenu.find('.tt-suggestion:not(.enter-suggest)');
      if ($suggestions.length) {
        $suggestions.first().click();
      } else {
        this.sendAction('on-select-without-match', this, this.$().val());
      }
    }
  },

  _initializeTypeahead: function(){
    this.$().typeahead({
    }, {
      minLength: 0,
      displayKey: function(object){
        return Ember.get(object, this.get('displayProperty'));
      }.bind(this),
      source: function(query, cb){
        this.set('query', query);
        this.set('_ttSourceCallback', cb);
      }.bind(this),
      templates: {
/*
        footer: function(object){
          if (object.isEmpty) {
            return '';
          } else {
            return '<span class="tt-suggestion enter-suggest">Footer</span>';
          }
        }.bind(this),
        empty: function() {
          return "<span class='tt-suggestion enter-suggest'>Empty</span>";
        }.bind(this)
*/
      }
      /* jshint unused:false */
    }).on('typeahead:selected typeahead:autocompleted', Ember.run.bind(this, function(e, obj, dataSet){
      this.set('selected', obj);
    }));
    if(this.get('_selected')){
      this.$().typeahead('val', this.get('_selected').get(this.get('displayProperty')));
    }
  },

  hasFocus: function(){
    return this.element === document.activeElement;
  },

  selected: function(key, value){
    if (arguments.length > 1) {
//      if(value){
        var newDispVal = Ember.typeOf(value) === 'instance' ? value.get(this.get('displayProperty')) : '';
        var resetByUserEdit = !value && this.hasFocus();
        if(!this.element){
          this.one('didInsertElement', this, function(){ 
            Ember.run.scheduleOnce('afterRender', this, function(){
              this.set('selected', value); 
            });
          });
        }
        else if(this.$().typeahead('val') !== newDispVal && !resetByUserEdit){
          // update not received from twitter typeahead event. update the jQuery component
          this.$().typeahead('val', newDispVal);
        }
//      }
      this.set('_selected', value);
    }
    return this.get('_selected');
  }.property(),

  close: function(){
    this.$().typeahead('close');
  },

  open: function(){
    this.$().typeahead('open');
  },

  isOpen: function(){
    return this.$().parent().find('tt-dropdown-menu').is(':visible');
  },

  giveFocus: function(){
    this.$().blur();
    this.$().focus();
  },

  _filterContent: function(query) {
    var regex = new RegExp(query || '', 'i');
    var valueKey = this.get('valueToken');
    return this.get('content').sortBy(this.get('displayProperty')).filter(function(thing){
      return regex.test(Ember.get(thing, valueKey));
    });
  },

  _valueObserver: function(){
    if(!this.get('value')){
      this.set('query', null);
    }
  }.observes('value'),

  _queryObserver: function(){
    var curSelected = this.get('selected');
    if(curSelected && this.get('query') !== curSelected.get(this.get('displayProperty'))){
      this.set('selected', null);
    }
  }.observes('query'),

  updateSuggestionsObserver: function(){
    var cb = this.get('_ttSourceCallback'),
        suggestions = this.get('suggestions');
    if(cb){
      var cbSuggestions = !Ember.isEmpty(suggestions) ? suggestions : this._filterContent(this.get('query'));
      cb(cbSuggestions);
      if(!Ember.isEmpty(cbSuggestions) && this.hasFocus() && !this.isOpen()){
        this.open();
      }
    }
  }.observes('_ttSourceCallback', 'suggestions', 'content', 'content.length'),

  focusIn: function(){
    var typeahead = this.$().data('ttTypeahead');
    typeahead.dropdown.update(this.$().val());
    if(!this.get('selected')){
      this.$().typeahead('open');
    }
    this.set('_placeholder', this.get('placeholder'));
    this.set('placeholder', null);
  },

  focusOut: function(){
    var query = this.$().typeahead('val');
    var results = this._filterContent(query);
    if (Ember.$.trim(query).length) {
      if (!results.length) {
        this.sendAction('on-select-without-match', this, query);
      }
    }
    this.$().typeahead('close');
    this.set('placeholder', this.get('_placeholder'));
  },

  destroyTypeahead: Ember.observer(function(){
    this.$().typeahead('destroy');
  }).on('willDestroyElement')
});