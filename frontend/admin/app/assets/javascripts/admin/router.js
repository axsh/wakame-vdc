(function( app ){

  app.Router = Backbone.Router.extend({
      routes: {
          "*actions": "list"
      },
      list: function( page ) {
        if(_.has(app.views, 'pagination')) {
          if(_.isEmpty(page)) {
            var page = 1;
          }

          app.views.pagination.collection.goTo(page);
        }
      }
  });

})( app );