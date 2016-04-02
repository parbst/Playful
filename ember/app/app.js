import Ember from 'ember';
import Resolver from 'ember/resolver';
import loadInitializers from 'ember/load-initializers';
import config from './config/environment';

// disabled because of this fix not really doing what it's supposed to: https://github.com/emberjs/data/pull/2586/files
//Ember.MODEL_FACTORY_INJECTIONS = true;
Ember.MODEL_FACTORY_INJECTIONS = false;

var App = Ember.Application.extend({
  modulePrefix: config.modulePrefix,
  podModulePrefix: config.podModulePrefix,
  Resolver: Resolver
});

loadInitializers(App, config.modulePrefix);

export default App;
