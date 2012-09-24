(function ( models ) {

  models.Dcmgr = Backbone.Model.extend({
  });

  models.Instance = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });

  models.SshKeyPair = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });

  models.Image = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });

  models.HostNode = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });

  models.Statistics = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03/instances.json?host_node_id=' + location.pathname.split('/')[2]
  });
})( app.models );
