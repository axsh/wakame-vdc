(function ( models ) {

  models.DcmgrGui = Backbone.Model.extend({
    url: app.info.api_endpoints.dcmgr_gui + '/api' + location.pathname + '.json'
  });

  models.User = models.DcmgrGui.extend({
  });

  models.Notification = models.DcmgrGui.extend({
    validate: function(attrs) {
      var errors = [];
      if(attrs.title == '') {
        errors.push("タイトルが未入力です。");
      }

      if(attrs.display_begin_at == '' || attrs.display_end_at == '') {
        errors.push("掲載期間が未入力です。");
      }

      if(attrs.article == '') {
        errors.push("記事が未入力です。");
      }

      if (errors.length > 0) {
        return errors;
      }
    }
  });
})( app.models );
