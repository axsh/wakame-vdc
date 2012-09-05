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
      return this.fetch( options );
    }

  });

})( app.collections);