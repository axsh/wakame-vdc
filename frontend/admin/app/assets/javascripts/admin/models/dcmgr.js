(function ( models ) {

  models.Dcmgr = Backbone.Model.extend({
  });

  models.Instance = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });

  models.Keypair = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });
})( app.models );
