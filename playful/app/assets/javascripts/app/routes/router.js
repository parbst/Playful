App.Router.map(function() {
  this.resource("home", function() {
    this.route("index", { path: '/' });
  });
  this.resource("import", function() {
    this.route("index", { path: '/' });
    this.route("selectShare");
    this.resource("audio", function() {
      this.route("tags");
      this.route("covers");
      this.route("confirm");
    });
  this.resource('order', function(){
      this.route("index", { path: '/' });
  });
//    this.route("audio");
  });
});
