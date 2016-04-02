import Ember from 'ember';
import MetadataAdapter from 'playful/adapters/metadata';
//import $ from 'jquery';
import _ from 'lodash';
import TwitterTypeaheadComponent from 'playful/components/twitter-typeahead';
import humps from 'humps';

export default Ember.Component.extend({
  classNames: ['release-metadata-search'],
  artistStore: Ember.A(),
  releaseStore: Ember.A(),
  _artistContent: Ember.A(),
  _artistQuery: null,
  _artistSelected: null,
  _releaseContent: Ember.A(),
  _releaseQuery: null,
  releaseSelected: null,
  _prevArtistSearches: Ember.A(),
  _prevReleaseSearches: Ember.A(),
  isLoading: false,
  hideSpinner: function(){
    return !this.get('isLoading');
  }.property('isLoading'),
  hideArtistCheckmark: function(){
    return !this.get('_artistSelected');
  }.property('_artistSelected'),
  hideReleaseCheckmark: function(){
    return !this.get('releaseSelected'); 
  }.property('releaseSelected'),
  clear: function(){
    this.set('releaseSelected', null);
    this.set('artistSelected', null);
  },
  actions: {
    artistSearch: function(){
      this._doArtistSearch();
    },
    releaseSearch: function(){
      this._doReleaseSearch();
    }
  },
  layout: Ember.Handlebars.compile(
    '{{twitter-typeahead ' +
       'content=_artistContent ' +
       'query=_artistQuery ' +
       'selected=_artistSelected ' +
       'displayProperty="artistName" ' +
       'valueToken="artistName" ' +
       'on-select-without-match="artistSearch" ' +
       'placeholder="Search for artist" ' +
    '}}' +
    '{{icon-fontawesome icon="check" hide=hideArtistCheckmark}} ' +
    '{{icon-fontawesome icon="refresh" spin="true" hide=hideSpinner}} ' +
    '{{release-metadata-typeahead ' +
       'content=_releaseContent ' +
       'query=_releaseQuery ' +
       'selected=releaseSelected ' +
       'artistSelected=_artistSelected ' +
       'displayProperty="releaseName" ' +
       'valueToken="releaseName" ' +
       'on-select-without-match="releaseSearch" ' +
       'placeholder="Search for release" ' +
    '}}' +
    '{{icon-fontawesome icon="check" hide=hideReleaseCheckmark}} '
  ),
  _doArtistSearch: function(){
    var isLoading = this.get('isLoading');
    if(!isLoading){
      var me = this,
        adapter = MetadataAdapter.create(),
        queryText = this.get('_artistQuery').toLowerCase(),
        prevSearches = this.get('_prevArtistSearches'),
        typeaheadContent = this.get('_artistContent'),
        bestMatch;

      if(!_.contains(prevSearches, queryText) && queryText.length > 2){
        this.set('isLoading', true);
        prevSearches.push(queryText);
        var query = { text: { artist_name: queryText } };
        adapter.findArtists(query).done(function(result){
          me._addToArtistStore(result);
          bestMatch = _.find(typeaheadContent, function(artist){ 
            return artist.get('artistName').toLowerCase() === queryText.toLowerCase();
          });
        }).always(function(){
          me.set('isLoading', false);
          if(bestMatch){
            me._setSelectedArtist(bestMatch);
            me.sendAction("artistmatch", bestMatch);
          }
        });
      }
    }
  },
  _doReleaseSearch: function(){
    var isLoading = this.get('isLoading');
    if(!isLoading){
      var me = this,
        adapter = MetadataAdapter.create(),
        curArtist = this.get('_artistSelected'),
        queryText = (this.get('_releaseQuery') || '').toLowerCase(),
        prevSearches = this.get('_prevReleaseSearches'),
        query = { text: { release_name: queryText } },
        curRelease = this.get('releaseSelected');

      if(curArtist){
        _.each(_.keys(curArtist.get('identifier')), function(k){
          query[k] = humps.decamelizeKeys(curArtist.get('identifier.' + k));
        });
      }

      if(curRelease){
        _.each(_.keys(curRelease.get('identifier')), function(k){
          query[k] = query[k] || {};
          query[k].release_id = curRelease.get('identifier.' + k).releaseId;
        });
        delete query.text;
      }

      var stringifiedQuery = JSON.stringify(query),
          hasDoneTextSearch = _.contains(prevSearches, stringifiedQuery),
          noReleaseSelectedOrNoTracks = !curRelease || !curRelease.get('tracks');

      if(!hasDoneTextSearch && noReleaseSelectedOrNoTracks){
        this.set('isLoading', true);
        console.log('_doReleaseSearch', query);
        prevSearches.push(stringifiedQuery);
        adapter.findReleases(query).done(function(releases){
          me._addToReleaseStore(releases);
          var releaseTypeahead = me._releaseTypeahead();
          if(releaseTypeahead.hasFocus() && !releaseTypeahead.isOpen() && !curRelease){
            Ember.run.later(_.bind(releaseTypeahead.giveFocus, releaseTypeahead));
          }
        }).always(function(){
          me.set('isLoading', false);
        });
      }
    }
  },
  _typeaheadChildViews: function(){
    return _.filter(this.get('childViews'), function(view){
      return view instanceof TwitterTypeaheadComponent;
    });
  },
  _artistTypeahead: function(){
    return _.first(this._typeaheadChildViews());
  },
  _releaseTypeahead: function(){
    return _.last(this._typeaheadChildViews());
  },
  _addToReleaseStore: function(releases){
    var typeaheadContent = this.get('_releaseContent'),
        matchContent = _.map(typeaheadContent, function(r){ return JSON.stringify(r.identifier); });
    _.each(releases, function(release){
      var stringifiedIdentifier = JSON.stringify(release.get('identifier'));
      if(!_.contains(matchContent, stringifiedIdentifier)){
        typeaheadContent.push(release);
      }
      else {
        var idx = _.indexOf(matchContent, stringifiedIdentifier),
            releaseInStore = typeaheadContent.objectAt(idx);
        if(!releaseInStore.get('tracks') && release.get('tracks')){
          releaseInStore.updateFrom(release);
        }
      }
    });
  },
  _setSelectedArtist: function(artist){
    this.set('_artistSelected', artist);
    if(this._artistTypeahead().hasFocus()){
      this._releaseTypeahead().giveFocus();
    }
  },
  _addToArtistStore: function(artists){
    var typeaheadContent = this.get('_artistContent'),
        artistsInStore = _.invoke(typeaheadContent, 'get', 'artistName'),
        newArtists = _.filter(artists, function(artist){
          return !_.contains(artistsInStore, artist.get('artistName'));
        });
    _.each(newArtists, function(artist){ typeaheadContent.push(artist); });
  },
  _artistQueryObserver: _.debounce(function(){
    this._doArtistSearch();
  }, 3000).observes('_artistQuery'),
  _releaseQueryObserver: _.debounce(function(){
    this._doReleaseSearch();
  }, 3000).observes('_releaseQuery'),
  _artistSelectedObserver: function(){
    var selectedArtist = this.get('_artistSelected');
    if(!selectedArtist){
      this.set('releaseSelected', null);
    }
    this._doReleaseSearch();
  }.observes('_artistSelected'),
  _releaseSelectedObserver: function(){
    this._doReleaseSearch();
  }.observes('releaseSelected')
});

