(function(){

  // Defer initialization until doc ready.
  $(function(){
    app.collections.paginatedItems = new app.collections.PaginatedCollection({

      model: app.models.Item.extend({
        urlRoot: app.info.resources.admin + '/api/notifications.json',
      }),

      server_api: {

        'publish_date_to': function() {
          var d = decodeURIComponent(app.utils.parsedSearch('publish_date_to')).replace('+',' ');
          if( !_.isEmpty(d) && moment(d).isValid()) {
            var publish_date_to = moment(d).format();
            return publish_date_to;
          }
        },

        'publish_date_from': function() {
          var d = decodeURIComponent(app.utils.parsedSearch('publish_date_from')).replace('+',' ');
          if( !_.isEmpty(d) && moment(d).isValid()) {
            var publish_date_from = moment(d).format();
            return publish_date_from;
          }
        }
      },

      paginator_core: {
        url: app.info.resources.admin + '/api/notifications.json'
      }

    });

    app.views.pagination = new app.views.PaginatedView({collection:app.collections.paginatedItems});
    app.views.list = new app.views.ListView({collection: app.collections.paginatedItems});
// app.views.search = new app.views.SearchView();

    app.router = new app.Router;
    Backbone.history.start();
  });

})();
