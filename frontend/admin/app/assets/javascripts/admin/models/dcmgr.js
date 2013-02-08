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

  models.LoadBalancer = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03' + location.pathname + '.json'
  });

  models.Statistics = models.Dcmgr.extend({
    url: app.info.api_endpoints.dcmgr + '/api/12.03/instances.json?host_node_id=' + location.pathname.split('/')[2] + '&state=without_terminated'
  });

  models.TextLog = models.Dcmgr.extend({
    url: (function(id){
      console.log()
      var params = {
        'account_id': 'a-00000000',
        'instance_id': 'none',
        'application_id': app.utils.parsedSearch('application_id'),
        'start': 1,
        'limit': 10,
        'start_time': app.helpers.date.iso8601(moment('2013-01-28T19:06:38'))
      };

      return app.info.api_endpoints.dcmgr + '/api/12.03/text_logs.json?' + $.param(params);
    })(),
  });

})( app.models );
