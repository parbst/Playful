App.AudioTagsController = Em.ObjectController.extend(Ember.Evented, App.OrderLineControllerMixin, {
    needs: ['metadata'],
    audioFiles: Em.A(),
    albumTitles: function(){
        return _.uniq(_.invoke(this.get('audioFiles'), 'get', 'album'));
    }.property('audioFiles.@each.album'),
    panoramaPosition: null,
    selectedImportTypeElement: null,
    importTrackColumns: function(){
        var result = [
            Grid.Column.create({propertyName: 'trackNumber'}),
            Grid.Column.create({propertyName: 'trackTitle'}),
            Grid.Column.create({propertyName: 'durationString'})
        ];
        if(this.get('albumTitles').length > 1){
            result.push(Grid.RowTypeColumn.create({propertyName: 'album'}))
        }
        return result;
    }.property('albumTitles'),
//    importTrackRows: Em.A(),
    selectedRows: Em.A(),
    commonValidationErrors: Em.A(),
    selectedFilesValidationErrors: Em.A(),
    showValidations: function(){
        return !_.isEmpty(this.get('commonValidationErrors')) || !_.isEmpty(this.get('selectedFilesValidationErrors'))
    }.property('commonValidationErrors', 'commonValidationErrors.length',
               'selectedFilesValidationErrors', 'selectedFilesValidationErrors.length'),
    actions: {
        togglePanorama: function(){
            this.trigger('togglePanorama')
        },
        tagTrackNumbers: function(){
            var selectedRows = this.get('selectedRows'),
                listName = selectedRows.length > 0 ? 'selectedRows' : 'audioFiles',
                list = this.get(listName),
                total = list.length; 
            _.each(list, function(af, idx){
                af.set('trackNumber', idx + 1);
                af.set('trackTotal', total);
            });
        },
        tagOneDiscAlbum: function(){
            _.each(this.get('audioFiles'), function(af){
                af.set('discNumber', 1);
                af.set('discTotal', 1);
            });
        },
        cleanTracks: function(){
            _.each(this.get('audioFiles'), function(af){
                var artist = af.get('artist');
                if(!_.str.isBlank(artist) && artist == af.get('albumArtist')){
                    af.set('albumArtist', null);
                }
                af.set('comment', '');
            });
        },
        transferMetadata: function(){
            var mTracks = this.get('controllers.metadata.selectedRelease.tracks'),
                selectedTracks = this.get('selectedRows'),
                useTracks = selectedTracks.length > 0 ? selectedTracks : this.get('audioFiles');

            _.each(useTracks, function(af,idx){ af.updateFromMetadata(mTracks.get(idx)); });
        }
    },
    validateAudioFiles: function(filesProperty, validationResultProperty){
        var audioFiles = this.get(filesProperty),
            validations = _.invoke(audioFiles, 'validate'),
            commonErrors = Validation.intersection(validations);

        // individual validations
        _.each(audioFiles, function(af, idx){
            var rowClass = null, 
                rowTooltip = null;
            var uniqValidation = Validation.subtract(validations[idx], commonErrors);
            if(!_.isEmpty(uniqValidation)) {
                rowClass = 'row-failed-validation';
                rowTooltip = {
                    html: true,
                    title: 'Validation failed:<br/>' + _.flatten(_.values(af.validate())).join('<br/>')
                };
            }

            af.set('rowClass', rowClass);
            af.set('rowTooltip', rowTooltip);
        });

        // group validation
        var importType = this.get('importType');
        if(importType == 'onedisc' || importType == 'multi'){
            var grpValidations = [Validation.Audio.albumRequired, Validation.Audio.sameGenreOnAlbum,
                Validation.Audio.sameArtistOrAlbumArtistOnAlbum];
            commonErrors = Validation.merge(commonErrors,
                _.map(grpValidations, function(val){ return val(audioFiles) }));
        }

        this.set(validationResultProperty, commonErrors);
//        this.set('importTrackRows', this.get('audioFiles'));
    },
    guessMetadataArtist: function(){
        var metadataController = this.get('controllers.metadata'),
            audioFiles = this.get('audioFiles'),
            artists = _.map(audioFiles, function(af){ return af.get('artist') }),
            albumArtists = _.map(audioFiles, function(af){ return af.get('albumArtist') }),
            uniqueArtists = _.uniq(artists),
            uniqueAlbumArtists = _.uniq(albumArtists);
        
        var query;
        if(uniqueArtists.length == 1){
            query = uniqueArtists[0];
        }
        else if (uniqueAlbumArtists.length == 1){
            query = uniqueAlbumArtists[0];
        }
        if(query){
            metadataController.set('artistQuery', query)
        }
    },
    guessMetadataRelease: function(){
        var metadataController = this.get('controllers.metadata'),
            audioFiles = this.get('audioFiles'),
            albums = _.map(audioFiles, function(af){ return af.get('album') }),
            uniqueAlbums = _.uniq(albums),
            selectableReleases = metadataController.get('selectableReleases'),
            titles = _.map(selectableReleases, function(r){ return r.release_name });
        if(uniqueAlbums.length == 1){
            var match = _.find(titles, function(title){
                return new RegExp(title, 'i').test(uniqueAlbums[0])
            });
            
            if(match){
                var release = selectableReleases[titles.indexOf(match)];
                metadataController.set('releaseQuery', release.release_name);
            }
        }
    },
    sortAudioFiles: function(sortFunc){
        this.get('audioFiles').sort(sortFunc);
        this.set('audioFiles', Em.copy(this.get('audioFiles')));
    },
    sortByAlbum: function(){
        this.sortAudioFiles(function(a, b){
            var albumA = a.get('album') || '',
                albumB = b.get('album') || '',
                trackNumberA = a.get('trackNumber') || 0,
                trackNumberB = b.get('trackNumber') || 0,
                result = Sort.strCmp(albumA, albumB);

            if(result == 0){
                result = Sort.numCmp(trackNumberA, trackNumberB);
            }
            return result;
        });
    },
    sortByTrack: function(){
        this.sortAudioFiles(function(a, b){
            var trackNumberA = a.get('trackNumber') || 0,
                trackNumberB = b.get('trackNumber') || 0,
                trackTitleA = a.get('trackTitle') || '',
                trackTitleB = b.get('trackTitle') || '',
                filenameA = a.get('filename') || '',
                filenameB = b.get('filename') || '',
                result = Sort.numCmp(trackNumberA, trackNumberB);

            if(result == 0){
                result = Sort.strCmp(trackTitleA, trackTitleB);
            }
            if(result == 0){
                result = result = Sort.strCmp(filenameA, filenameB);
            }
            return result;
        });
    },
    audioFilesDidChange: function(){
        this.validateAudioFiles('audioFiles', 'commonValidationErrors');
    }.observes('audioFiles', 'audioFiles.@each.observeChange'),
    selectedRowsDidChange: function(){
        this.validateAudioFiles('selectedRows', 'selectedFilesValidationErrors');
    }.observes('selectedRows', 'selectedRows.@each.observeChange'),
    orderLineDidChange: function(){
        var ol = this.get('orderLine');
        if(ol){
            this.set('audioFiles', ol.get('audioFiles'));
            this.sortByAlbum();
            this.guessMetadataArtist();
        }
    }.observes('orderLine'),
    importTypeDidChange: function(){
        this.validateAudioFiles('audioFiles', 'commonValidationErrors');
    }.observes('importType'),
    selectableReleasesDidChange: function(){
        this.guessMetadataRelease();
    }.observes('controllers.metadata.selectableReleases'),
    maskHidden: function(){
        return !!this.get('selectedImportTypeElement');
    }.property('selectedImportTypeElement'),
    importType: function(){
        var map = {
                op_onediscalbum: 'onedisc',
                op_multidiscalbum: 'multi',
                op_mixedtracks: 'mixed'
            },
            elem = this.get('selectedImportTypeElement'),
            idx = elem && elem.id;
        return map[idx];
    }.property('selectedImportTypeElement'),
    transferMetadataDisabled: function(){
        return !(this.get('metadataTransferable') && this.get('panoramaPosition') == 'right');
    }.property('panoramaPosition', 'metadataTransferable'),
    metadataTransferable: function(){
        var metadataController = this.get('controllers.metadata'),
            selectedRelease = metadataController.get('selectedRelease'),
            selectedTracks = this.get('selectedRows'),
            audioFiles = this.get('audioFiles') || Em.A(),
            numTracks = selectedTracks.length > 0 ? selectedTracks.length : audioFiles.length;

        return !_.isEmpty(selectedRelease) && selectedRelease.tracks && selectedRelease.tracks.length == numTracks;
    }.property('controllers.metadata.selectedRelease.tracks', 'selectedRows'),
    displayCommonValidationErrors: function(){
        return  _.map(this.get('commonValidationErrors'), function(errors, headline){
            return _.map(errors, function(e){ return _.str.humanize(headline) + ': ' + e})
        })
    }.property('commonValidationErrors'),
    displaySelectedFilesValidationErrors: function(){
        return  _.map(this.get('selectedFilesValidationErrors'), function(errors, headline){
            return _.map(errors, function(e){ return _.str.humanize(headline) + ': ' + e})
        })
    }.property('selectedFilesValidationErrors')

});
