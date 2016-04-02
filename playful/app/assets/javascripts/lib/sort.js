(function() {

  // Establish the root object, `window` in the browser, or `global` on the server.
  var root = this;
  root.Sort = {
    strCmp: function(str1, str2){
        if (str1 < str2 ) return -1;
        if ( str1 > str2 ) return 1;
        return 0;
    },
    numCmp: function(num1, num2){
        return num1 - num2;
    }
  };
}).call(this);