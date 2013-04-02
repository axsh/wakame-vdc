(function (collections) {

  collections.TextLogCollection = Backbone.Collection.extend({

    initialize: function(options) {
      if(_.has(options, 'model')) {
        this.model = options.model;
      }
    },

    parse: function (response) {
      return response[0].results;
    }
  });


})( app.collections);
