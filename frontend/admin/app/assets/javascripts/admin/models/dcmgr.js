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
      var start_time = app.utils.parsedSearch('start_time');

      if( !_.isEmpty(start_time) ) {
        var d = app.utils.decodeSearhTime(app.utils.parsedSearch('start_time'));
        start_time = app.helpers.date.iso8601(d)
      } else {
        start_time = '';
      }

      var params = {
        'account_id': 'a-00000000',
        'instance_id': 'none',
        'application_id': app.utils.parsedSearch('application_id'),
        'start': 1,
        'limit': 100,
        'start_time': start_time
      };

      return app.info.api_endpoints.dcmgr + '/api/12.03/text_logs.json?' + $.param(params);
    })(),
  });

})( app.models );
