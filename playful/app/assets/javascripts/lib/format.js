(function() {

  // Establish the root object, `window` in the browser, or `global` on the server.
  var root = this;
  root.Format = {
    secondsToMinuteString: function(seconds){
      if(_.isNumber(seconds)){
        return Math.floor(seconds / 60) + ":" + _.str.sprintf("%02d", Math.round(seconds % 60))
      }
    },
    bytesToHuman: function(bytes){
        var amount = bytes,
            units = ['B', 'kB', 'MB', 'GB'],
            unitIdx = 0;
        while(amount > 1024 && unitIdx + 1 < units.length){
            amount /= 1024;
            unitIdx++;
        }

        return _.str.sprintf(amount % 1 > 0 ? "%.2f" : "%d", amount) + " " + units[unitIdx];
    },
    modifyKeysRecursively: function(obj, strFunc){
      if(_.isObject(obj)){
        _.each(obj, function(val, key, obj){
          var newKey = key;
          if(_.isString(key) && strFunc(key) != key){
            newKey = strFunc(key);
          }
          delete obj[key]; 
          obj[newKey] = root.Format.modifyKeysRecursively(val, strFunc);
        })
      }
      return obj;
    }
  };
  root.Format.underscoreKeysRecursively = function(obj){
    return root.Format.modifyKeysRecursively(obj, _.str.underscored);
  };
}).call(this);