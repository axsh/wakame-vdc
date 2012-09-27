(function(){

  // Defer initialization until doc ready.
  $(function(){
    if (!_.isEmpty($('#system_message').html())){
      app.notify.success($('#system_message').html());
    }

    app.collections.paginatedItems = new app.collections.PaginatedCollection({

      model: app.models.Item.extend({
        urlRoot: app.info.api_endpoints.dcmgr_gui + '/api/notifications'
      }),

      server_api: {

        'publish_date_to': function() {
          var d = decodeURIComponent(app.utils.parsedSearch('publish_date_to')).replace('+',' ');
          return app.helpers.date.iso8601(d);
        },

        'publish_date_from': function() {
          var d = decodeURIComponent(app.utils.parsedSearch('publish_date_from')).replace('+',' ');
          return app.helpers.date.iso8601(d);
        }
      },

      paginator_core: {
        url: app.info.api_endpoints.dcmgr_gui + '/api/notifications.json'
      }

    });

    app.views.pagination = new app.views.PaginatedView({collection:app.collections.paginatedItems});
    app.views.list = new app.views.ListView({collection: app.collections.paginatedItems});

    app.router = new app.Router;
    Backbone.history.start();
  });

})();
