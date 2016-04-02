_.escapeRegExp = function(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}
_.grab = function(obj){
  var idx = 1;
  while(arguments.length > idx){
    var arg = arguments[idx++];
    if(typeof obj[arg] != undefined){
        return obj[arg]
    }
  }
}
