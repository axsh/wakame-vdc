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
        'distribution' : app.utils.parsedSearch('distribution'),
        'users' : app.utils.parsedSearch('user_id'),
        'display_end_at': function() {
          var display_end_at = app.utils.parsedSearch('display_end_at');
          if( !_.isEmpty(display_end_at)) {
            var d = decodeURIComponent(display_end_at).replace('+',' ');
            return encodeURIComponent(app.helpers.date.iso8601(d));
          } else {
            return '';
          }
        }(),

        'display_begin_at': function() {
          var display_begin_at = app.utils.parsedSearch('display_begin_at');
          if( !_.isEmpty(display_begin_at) ) {
            var d = decodeURIComponent(app.utils.parsedSearch('display_begin_at')).replace('+',' ');
            return encodeURIComponent(app.helpers.date.iso8601(d));
          } else {
            return '';
          }
        }()
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
