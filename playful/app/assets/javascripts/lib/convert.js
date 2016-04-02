(function() {

  // Establish the root object, `window` in the browser, or `global` on the server.
  var root = this;
  root.Convert = {
    // converts true, 'true', 1 and "1" to true, all other is false
    toBool: function(value){
        if(_.isString(value) && !_.contains(['1', '2'], value.trim())){
            return value.toLowerCase() == 'true'
        }
        else{
            return Boolean(value - 0);
        }
    },
    // makes sure the returned value is an array.
    toArray: function(value){
        var result = [];
        if(arguments.length == 1){
            if(_.isArray(value)){
                result = value;
            }
            else{
                result.push(value);
            }
        }
        else {
            result = _.toArray(arguments);
        }
        return result;
    }
  };
}).call(this);