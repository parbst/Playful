(function() {

  // Establish the root object, `window` in the browser, or `global` on the server.
  var root = this;
  root.Validation = {
    merge: function(valObjList){
      if(arguments.length > 1){
        valObjList = _.flatten(arguments);
      }

      var res = {};
      _.each(valObjList, function(valObj){
        _.each(valObj, function(messages, field){
          if(!res[field]){
            res[field] = [];
          }
          res[field] = res[field].concat(messages);
        });
      });
      return res;
    },
    intersection: function(validations){
      var result = {},
          commonKeys = _.intersection(_.flatten(_.map(validations, _.keys)));
      _.each(commonKeys, function(key){
        var commonErrors = _.intersection(_.flatten(_.pluck(validations, key)));
        if(!_.isEmpty(commonErrors)){
          result[key] = commonErrors
        }
      });
      return result;
    },
    subtract: function(valA, valB){
      // find valA - valB
      var clone = JSON.parse(JSON.stringify(valA));
      _.each(_.keys(valB), function(key){
        if(!_.isEmpty(clone[key])){
          clone[key] = _.difference(clone[key], valB[key]);
          if(_.isEmpty(clone[key])){
            delete clone[key];
          }
        }
      });
      return clone;
    },
    getResultForAudioFile: function(resultSet, audioFile){
      return resultSet[audioFile.get('path')];
    },
    isOk: function(validations){
        return _.isEmpty(validations);
    }
  };
  root.Validation.Basic = {
      integer: function(value){
          var result = {};
          if(!_.isNumber(value) || parseInt(value) !== value){
              result.value = ['Must be an integer']
          }
          return result;
      },
      nonEmptyString: function(value){
          var result = {}
          if(!_.isString(value) || value == ""){
              result.value = ['Cannot be empty']
          }
          return result;
      }
  };
  root.Validation.BaseFile = {
      zeroSize: function(baseFile){
        var result = {},
            byteSize = baseFile.get('byteSize');
        if(_.isNumber(byteSize) && byteSize == 0){
          result.byteSize = ['File is empty (size zero)'];
        }
        return result;
      }
  };
  root.Validation.Audio = {
    // TODO:
    // has track but no album
    // selected files has multiple albums, multiple years
    artist: function(audioFile){
      var result = {};
      if(_.str.isBlank(audioFile.get('artist'))){
        result.artist = ['No artist specified'];
      }
      return result;
    },
    albumArtist: function(audioFile){
      var result = {};
      if(_.str.isBlank(audioFile.get('albumArtist')) && _.str.isBlank(audioFile.get('artist'))){
        result.albumArtist = ['No album artist specified'];
      }
      return result;
    },
    hasAlbum: function(audioFile){
      var res = {};
      if(!_.str.isBlank(audioFile.get('album'))){
        if(_.str.isBlank(audioFile.get('year'))){
          res.year = ['Album year not specified']
        }
        if(!_.isFinite(audioFile.get('trackNumber'))){
          res.trackNumber = ['No track number specified']
        }
        if(!_.isFinite(audioFile.get('trackTotal'))){
          res.trackTotal = ['No total track amount specified']
        }
        if(!_.isFinite(audioFile.get('discNumber'))){
          res.discNumber = ['No disc number specified']
        }
        if(!_.isFinite(audioFile.get('discTotal'))){
          res.discTotal = ['No total disc amount specified']
        }
      }
      return res;
    },

    albumRequired: function(audioFiles){
      var result = {};
      if(_.some(_.invoke(audioFiles, 'get', 'album'), _.isEmpty)){
        result.album = ['album not present on all tracks'];
      }
      return result;
    },

    sameGenreOnAlbum: function(audioFiles){
      var result = {},
          d = _.invoke(audioFiles, 'getProperties', 'genre', 'album'),
          uniqGenres = _.map(_.values(_.groupBy(d, 'album')), function(albumGroup){ 
            return _.uniq(_.pluck(albumGroup, 'genre')).length == 1;
          });
      if(!_.every(uniqGenres, _.identity)){
        result.genre = ['Genres not unique within album'];
      }
      return result;
    },

    sameArtistOrAlbumArtistOnAlbum: function(audioFiles){
      var result = {},
          d = _.invoke(audioFiles, 'getProperties', 'artist', 'album', 'albumArtist'),
          uniqArtistsOnAlbum = _.map(_.values(_.groupBy(d, 'album')), function(albumGroup){
            return _.uniq(_.map(albumGroup, function(grp){
                return _.grab(grp, 'albumArtist', 'artist');
            }))
          });
      if(!_.every(uniqArtistsOnAlbum, function(ua){ return ua.length == 1})){
        result.artist = ['artist not the same for every track on album'];
      }
      return result;
    },

    hasComment: function(audioFile){
        var result = {};
        if(!_.isEmpty(audioFile.get('comment'))){
            result.comment = ['has a comment...'];
        }
        return result;
    }
  };

  root.Validation.Audio.sameAlbumRequired = function(audioFiles){
    var allHasAlbum = _.isEmpty(root.Validation.Audio.albumRequired(audioFiles));
    return allHasAlbum && _.uniq(_.invoke(audioFiles, 'get', 'album')).length == 1;
  };

  root.Validation.Audio.validateSingle = function(audioFile){
    return root.Validation.merge([
      root.Validation.Audio.artist(audioFile),
      root.Validation.Audio.albumArtist(audioFile),
      root.Validation.Audio.hasAlbum(audioFile),
      root.Validation.Audio.hasComment(audioFile),
      root.Validation.BaseFile.zeroSize(audioFile)
    ]);
  };
}).call(this);