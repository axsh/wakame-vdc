(function ( models ) {

  models.Admin = Backbone.Model.extend({
  });

  models.Notification = models.Admin.extend({
    url: app.info.api_endpoints.admin + '/api' + location.pathname + '.json'
  });

})( app.models );
