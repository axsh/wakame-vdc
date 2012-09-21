(function (collections) {

  collections.DetailCollection = Backbone.Collection.extend({

    initialize: function(options) {
      if(_.has(options, 'model')) {
        this.model = options.model;
      }
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

  collections.UserDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.InstanceDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.KeypairDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });
})( app.collections);
