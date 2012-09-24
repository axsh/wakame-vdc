(function ( models ) {

  models.DcmgrGui = Backbone.Model.extend({
  });

  models.User = models.DcmgrGui.extend({
    url: app.info.api_endpoints.dcmgr_gui + '/api' + location.pathname + '.json'
  });
})( app.models );
