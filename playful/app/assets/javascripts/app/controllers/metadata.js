App.MetadataController = Em.ObjectController.extend({
	// properties
  	artistSource: [],
	artistQuery: null,
  	selectedArtist: null,
    selectedArtistJq: null,
  	showArtistSuggestions: false,
  	releaseSource: [],
	releaseQuery: null,
  	selectedRelease: null,
    selectedReleaseJq: null,
  	selectableReleases: Em.A(),
  	showReleaseSuggestions: false,
  	loading: false,
  	tracks: Em.A(),
  	trackColumns: [
  		Grid.Column.create({propertyName: 'index'}),
  		Grid.Column.create({propertyName: 'title'}),
  		Grid.Column.create({propertyName: 'duration'})
  	],

  	// event handlers
  	artistQueryDidChange: function(){
  		var query = this.get('artistQuery');
  		if(query){
  			this.artistSearch();
  		}
  	}.observes('artistQuery'),

  	releaseQueryDidChange: function(){
  		var query = this.get('releaseQuery');
  		if(query){
  			this.set('selectedRelease', query);
  		}
  	}.observes('releaseQuery'),

  	selectedArtistJqDidChange: function(){
  		var selectedArtistJq = this.get('selectedArtistJq');
  		if(selectedArtistJq){
            var artistStore = this.get('artistStore');
  			this.set('selectedArtist', artistStore.getByAttr(selectedArtistJq.artistId));
            this.releaseLookupByArtist();
  		}
  		else{
  			this.set('selectedReleaseJq', null);
  		}
  	}.observes('selectedArtistJq'),

  	selectedReleaseJqDidChange: function(){
  		var selectedReleaseJq = this.get('selectedReleaseJq');
  		if(selectedReleaseJq){
            var releaseStore = this.get('releaseStore');
            this.set('selectedRelease', releaseStore.getByAttr(selectedReleaseJq.releaseId));
            this.releaseLookupByRelease();
  		}
  		else{
  			this.applyReleaseSource();
  		}
  	}.observes('selectedReleaseJq'),

    selectedReleaseDidChange: function(){
        this.updateTracks();
    }.observes('selectedRelease'),

  	// methods
  	artistToWidgetInput: function(artist){
		return {
  			label: artist.artist_name,
      		value: artist.artist_name,
      		artistId: artist.id
    	};
    },

  	applyArtistSource: function(){
		var artistStore = this.get('artistStore'),
    		query = this.get('artistQuery');
  		this.set('artistSource', _.map(artistStore.query(query), this.artistToWidgetInput));
    },

    releaseToWidgetInput: function(release){
		var tracks = "";
		if(release.tracks){
			tracks = " (" + release.tracks.length + ")"
		}
		var name = release.release_name + tracks; 
		return {
			label: name,
			value: name,
			releaseId: release.id
		}
    },

    applyReleaseSource: function(){
		var releaseStore = this.get('releaseStore'),
			selectedArtist = this.get('selectedArtist'),
			widgetSource = [];

		if(selectedArtist){
			var releases = releaseStore.findByArtistIdentifier(selectedArtist.identifier);
			this.set('selectableReleases', Em.A(releases));
			widgetSource = _.map(releases, this.releaseToWidgetInput);
		}

		this.set('releaseSource', widgetSource);
    },

  	artistSearch: function(){
    	var me = this,
    		artistStore = this.get('artistStore'),
    		query = this.get('artistQuery'),
        	performSearch = function(){
          		var match = artistStore.match(query);
          		if (match) me.set('selectedArtistJq', me.artistToWidgetInput(match));
          		me.set('showArtistSuggestions', !match);
          		me.applyArtistSource();
        	};
  		performSearch = _.wrap(performSearch, function(func){
    		me.set('loading', true);
    		artistStore.fetchByArtistName(query, function(){
				func();
        		me.set('loading', false);
			});
		})
		performSearch();
	},

	releaseLookupByArtist: function(){
		var me = this,
			releaseStore = this.get('releaseStore'),
			selectedArtist = this.get('selectedArtist'),
			performSearch = _.bind(this.applyReleaseSource, this);

		if(selectedArtist){
			performSearch = _.wrap(performSearch, function(func){
        		me.set('loading', true);
        		releaseStore.fetchByArtistIdentifier(selectedArtist.identifier, function(){
					func();
	        		me.set('loading', false);
				});
			});
		}
		performSearch();
	},

	releaseLookupByRelease: function(){
		var me = this,
			releaseStore = this.get('releaseStore'),
			selectedRelease = this.get('selectedRelease');

		if(selectedRelease && !selectedRelease.tracks){
			var filteredIdentifier = _.clone(selectedRelease.identifier);
			_.each(filteredIdentifier, function(value, key, o){
				o[key] = _.pick(value, 'release_id')
			});
        	me.set('loading', true);
			releaseStore.fetchByReleaseIdentifier(filteredIdentifier, function(){
				me.set('selectedRelease', releaseStore.getByAttr(selectedRelease.id));
				me.set('loading', false);
			})
		}
	},

	updateTracks: function(){
		var selectedRelease = this.get('selectedRelease'),
			idx = 1,
			tracks = [];
		if(selectedRelease && selectedRelease.tracks){
			tracks = _.map(selectedRelease.tracks, function(t){
				var time = Math.floor(t.duration / 60) + ':' + Math.round(t.duration % 60);
				return Ember.Object.create({
					title: t.title,
					duration: Format.secondsToMinuteString(t.duration),
					index: idx++
				});
			});
		}
		this.set('tracks', tracks);
	},

	// stores
	artistStore: App.dataAccess.db.MetadataStore.create({
		fetchByArtistName: function(artistName, callback){
			var me = this,
				descriptor = { text: { artist_name: artistName } };
			App.dataAccess.metadata.artist(descriptor, 
				_.bind(function(data){
					this.add(data);
					callback();
				}, this),
				function(xhr, errorMessage, thrownError) {
					App.log.error("artist fetch failed " + xhr.statusText);
					callback();
			  	}
			);
		},
		getSearchString: function(record){
			return record.artist_name || '';
		}
	}),
	releaseStore: App.dataAccess.db.MetadataStore.create({
		fetch: function(descriptor, callback, onDataRetrieval){
			var me = this;
			if(!_.isFunction(onDataRetrieval)){
				onDataRetrieval = _.bind(function(data){
					this.add(data);
					callback();
				}, this)
			}
			App.dataAccess.metadata.release(descriptor, 
				onDataRetrieval,
				function(xhr, errorMessage, thrownError) {
					App.log.error("release fetch failed " + xhr.statusText);
					callback();
			  	}
			);

		},
		fetchByReleaseName: function(artistName, callback){
			var descriptor = { text: { release_name: artistName } };
			this.fetch(descriptor, callback);
		},
		fetchByArtistIdentifier: function(identifier, callback){
			this.fetch(identifier, callback);
		},
		fetchByReleaseIdentifier: function(identifier, callback){
			this.fetch(identifier, callback, _.bind(function(data){
				this.update(data);
				callback();
			}, this));
		},
		getSearchString: function(record){
			return record.release_name || '';
		},
		findByArtistIdentifier: function(artistIdentifier){
			return this.findAll(function(r){
                var filteredIdentifier = _.clone(r.identifier);
                _.each(filteredIdentifier, function(value, key, o){
                    o[key] = _.pick(value, 'artist_id')
                });
                return _.isEqual(filteredIdentifier, artistIdentifier)
            });
		}
	})
});
