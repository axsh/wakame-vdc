(function (collections) {

  collections.DetailCollection = Backbone.Collection.extend({

    initialize: function(options) {
      if(_.has(options, 'url')) {
        this.url = options.url;
      }
    },

    get: function ( options ) {
      if ( !_.isObject(options) ) {
        options = {};
      }
      this.url = '/api' + location.pathname + '.json';
      return this.fetch( options );
    },

    info: function() {
      if( _.isArray(this.models) && _.has(this.models, 0) ) {
        return this.models[0].attributes;
      } else {
        return {};
      }
    },

    parse: function (response) {
       return response.result;
    }
  });

})( app.collections);
