App.AudioFile = App.BaseFile.extend({
    artist:         DS.attr('string'),
    albumArtist:    DS.attr('string'),
    composer:       DS.attr('string'),
    album:          DS.attr('string'),
    trackTitle:     DS.attr('string'),
    trackTumber:    DS.attr('int'),
    trackTotal:     DS.attr('int'),
    discTotal:      DS.attr('int'),
    discNumber:     DS.attr('int'),
    comment:        DS.attr('string'),
    year:           DS.attr('date'),
    genre:          DS.attr('string'),
    bitRateType:    DS.attr('string'),
    bitRate:        DS.attr('int'),
    sampleRate:     DS.attr('int'),
    channelMode:    DS.attr('string'),
    duration:       DS.attr('float'),

    updateFromScan: function(scan){
        var properties = ['artist', 'albumArtist', 'composer', 'album', 'trackTitle', 
            'trackNumber', 'trackTotal','year', 'genre', 'discNumber', 
            'discTotal', 'comment', 'duration'];
        this._super(scan);
        if (scan.tag){
            _.each(properties, function(p){
                this.set(p, scan.tag[_.str.underscored(p)]);
            }, this);
        }
        if(scan.ffmpeg){
            this.set('bitRate', scan.ffmpeg.bit_rate_in_kilo_bytes_per_sec);
            if(scan.ffmpeg.audio){
                this.set('sampleRate', scan.ffmpeg.audio.sample_rate_in_hz);
                this.set('channelMode', scan.ffmpeg.audio.channels);
            }
        }
    },

    updateFromMetadata: function(mTrack){
        var props = {};
        if(!_.isEmpty(mTrack.artists)){
            props.artist = mTrack.artists[0].artist_name;
        }
        props.discNumber = mTrack.disc_number;
        props.duration = Math.round(mTrack.duration);
        props.trackTitle = mTrack.title;
        props.trackNumber = mTrack.track_number - 0;
        props.discNumber = mTrack.disc_number - 0;
        this.setProperties(props);
    },

    durationString: function(){
        return Format.secondsToMinuteString(this.get('duration'));
    }.property('duration'),

    validate: function(){
        return this._super() && Validation.Audio.validateSingle(this);
    },

    isValid: function(){
        return _.isEmpty(this.validate());
    },

    anyAudioPropertyDidChange: function(){
        this.updateObserveChangeBuffered();
    }.observes('filename', 'artist', 'albumArtist', 'composer', 'album', 
        'trackTitle', 'trackNumber', 'trackTotal', 'year', 'genre', 
        'discNumber', 'discTotal', 'comment', 'durationString'),

    getCheckPointProperties: function(){
        return this._super().concat([
            'artist', 'albumArtist', 'composer', 'album', 'trackTitle',
            'trackNumber', 'trackTotal', 'discTotal', 'discNumber',
            'comment', 'year', 'genre', 'bitRateType', 'bitRate',
            'sampleRate', 'channelMode', 'duration'])
    },

    getTagProperties: function(){
        return ['artist',  'albumArtist', 'composer', 'album', 
            'trackTitle', 'trackNumber', 'trackTotal', 'discTotal',
            'discNumber', 'comment', 'year', 'genre'];
    },

    tagDiff: function(){
        return this.diff(this.getTagProperties());
    }
});
