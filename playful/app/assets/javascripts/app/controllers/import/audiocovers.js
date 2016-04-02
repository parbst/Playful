App.AudioCoversController = Em.ObjectController.extend(App.OrderLineControllerMixin, {
    imageSearchResults: Em.A(),
    selectedAlbumImage: null,
    formImageUrl: null,
    actions: {
        stepCompleted: function(){
            var me = this,
                urlAlbums = _.filter(this.get('albumImages'), function(a){ return !!a.get('src') }),
                coverArt = _.map(urlAlbums, function(album){
                    var o = Em.Object.create({
                        albumName: album.get('caption'),
                        artistName: me.getArtistForAlbum(album),
                        type: 'front'
                    });

                    if(!_.isEmpty(album.get('path'))){
                        o.set('path', album.get('path'));
                    }
                    else{
                        o.set('url', album.get('src'));
                    }

                    return o;
                });
            this.get('orderLine').set('coverArt', coverArt);
            this.send('nextStep')
        },
        selectThumbnail: function(thumbnailData){
            var isImageFile = thumbnailData instanceof App.ImageFile,
                selectedAlbumImage = this.get('selectedAlbumImage');
            if(isImageFile){
                if(selectedAlbumImage){
                    selectedAlbumImage.setProperties({
                        src: thumbnailData.get('downloadEndpoint'),
                        path: thumbnailData.get('path')
                    });
                }
            }
            else{
                this.set('selectedAlbumImage', thumbnailData);
            }
        },
        formImageUrlSubmit: function(){
            var formImageUrl = this.get('formImageUrl'),
                selectedAlbumImage = this.get('selectedAlbumImage');
            if(URI.parse(formImageUrl).hostname && selectedAlbumImage){
                selectedAlbumImage.setProperties({
                    src: formImageUrl,
                    path: null
                });
            }
        }
    },
    albumImages: function(){
        var res = Em.A(), ol = this.get('orderLine');
        if(ol){
            res = Em.A(_.map(ol.get('audioFiles').uniqValues('album'), function(albumTitle){
                return Em.Object.create({ caption: albumTitle, src: null }) })
            );
        }
        return res;
    }.property('orderLine', 'orderLine.audioFiles.@each.observeChange'),
    imageQuery: function(){
        var query = this.get('selectedAlbumImage.title'),
            artist = this.getArtistForAlbum(query);
        if(artist){
            query += " " + artist
        }
        return query;
    }.property('selectedAlbumImage'),
    getArtistForAlbum: function(albumTitle){
        var songsOnAlbum = _.filter(this.get('orderLine.audioFiles'), function(af){ return af.get('album') == albumTitle }),
            artists = _.uniq(_.map(songsOnAlbum, function(af){ return af.get('artist') })),
            albumArtists = _.uniq(_.map(songsOnAlbum, function(af){ return af.get('albumArtist') }));
        if(artists.length == 1){
            return artists[0]
        }
        else if (albumArtists.length == 1){
            return albumArtists[0]
        }
    },
    importedImageFiles: function(){
        var fc = this.get('orderLine.fileCollection');
        if(fc){
            return fc.get('imageFiles');
        }
    }.property('orderLine.fileCollection'),
    googleSearchUrl: function(){
        var query = this.get('imageQuery');
        if(query){
            return "https://www.google.dk/search?q=" + encodeURIComponent(query) + "&site=imghp&source=lnms&tbm=isch"
        }
    }.property('imageQuery')
});
