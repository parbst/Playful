/* global require, module */

var EmberApp = require('ember-cli/lib/broccoli/ember-app');

var app = new EmberApp();

app.import('bower_components/ember/ember-template-compiler.js');

// Bootstrap sass
app.import('bower_components/bootstrap-sass-official/assets/javascripts/bootstrap.js');

// bootstrap icons
var pickFiles = require('broccoli-static-compiler');
app.import('bower_components/bootstrap-sass-official/assets/fonts/bootstrap/glyphicons-halflings-regular.woff', {
  destDir: 'fonts/bootstrap'
});
app.import('bower_components/bootstrap-sass-official/assets/fonts/bootstrap/glyphicons-halflings-regular.woff2', {
  destDir: 'fonts/bootstrap'
});

// font awesome
app.import('bower_components/fontawesome/fonts/fontawesome-webfont.woff', {
  destDir: 'fonts'
});
app.import('bower_components/fontawesome/fonts/fontawesome-webfont.woff2', {
  destDir: 'fonts'
});

// lodash
app.import('bower_components/lodash/lodash.js');
app.import('vendor/lodash/shim.js');

// string.js
app.import('bower_components/string/lib/string.js');
app.import('vendor/stringjs/shim.js');

// humps
app.import('vendor/humps/humps.js');

// twitter typeahead.js
app.import('bower_components/typeahead.js/dist/typeahead.bundle.min.js');

// Use `app.import` to add additional libraries to the generated
// output files.
//
// If you need to use different assets in different
// environments, specify an object as the first parameter. That
// object's keys should be the environment name and the values
// should be the asset to use in that environment.
//
// If the library that you are including contains AMD or ES6
// modules that you would like to import into your application
// please specify an object with the list of modules as keys
// along with the exports of each module as its value.

module.exports = app.toTree();
