/* jshint node: true */

module.exports = function(environment) {
  var ENV = {
    modulePrefix: 'playful',
    environment: environment,
    baseURL: '/',
    locationType: 'auto',
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. 'with-controller': true
      }
    },
    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
      SERVER: {
        host: 'http://localhost:3000',
        apiNamespace: ''
      },
      ENDPOINTS: {
        scan: 'http://localhost:3000/files/scan',
        download: 'http://localhost:3000/files/download',
        metadata: {
          artist: 'http://localhost:3000/metadata/artist',
          release: 'http://localhost:3000/metadata/release',
          movie: 'http://localhost:3000/metadata/movie'
        }
      },
      defaultLocale: 'en'
    }
  };

  if (environment === 'development') {
    // ENV.APP.LOG_RESOLVER = true;
    // ENV.APP.LOG_ACTIVE_GENERATION = true;
    // ENV.APP.LOG_TRANSITIONS = true;
    // ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
    // ENV.APP.LOG_VIEW_LOOKUPS = true;
    ENV.contentSecurityPolicy = {
      'default-src': "'none'",
      'script-src': "'self' 'unsafe-inline' 'unsafe-eval'",
      'font-src': "'self'",
      'connect-src': "'self' localhost:3000",
      'img-src': "'self'",
      'style-src': "'self' 'unsafe-inline'",
      'frame-src': "s-static.ak.facebook.com static.ak.facebook.com www.facebook.com"
    };
  }

  if (environment === 'test') {
    // Testem prefers this...
    ENV.baseURL = '/';
    ENV.locationType = 'none';

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false;
    ENV.APP.LOG_VIEW_LOOKUPS = false;

    ENV.APP.rootElement = '#ember-testing';
  }

  if (environment === 'production') {

  }

  return ENV;
};
