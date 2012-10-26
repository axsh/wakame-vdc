(function(){

  // Defer initialization until doc ready.
  $(function(){
    app.collections.paginatedItems = new app.collections.PaginatedCollection({

      model: app.models.Item.extend({
        urlRoot: app.info.api_endpoints.dcmgr + '/api/12.03/instances.json'
      }),

      server_api: {
        id: app.utils.parsedSearch('q'),
        state: app.utils.parsedSearch('state'),
        host_node_id: app.utils.parsedSearch('host_node_id'),
        account_id: app.utils.parsedSearch('account_id')
      },

      paginator_core: {
        url: app.info.api_endpoints.dcmgr + '/api/12.03/instances.json'
      }

    });

    app.views.pagination = new app.views.PaginatedView({collection:app.collections.paginatedItems});
    app.views.list = new app.views.ListView({collection: app.collections.paginatedItems});

    app.router = new app.Router;
    Backbone.history.start();
  });

})();
