(function ( models ) {

  models.DcmgrGui = Backbone.Model.extend({
    errors: {},
    url: app.info.api_endpoints.dcmgr_gui + '/api' + location.pathname + '.json'
  });

  models.User = models.DcmgrGui.extend({
  });

  models.Notification = models.DcmgrGui.extend({
    validate: function(attrs) {
      this.errors = {};
      if(attrs.title == '') {
        this.errors['title'] = "タイトルが未入力です。";
      }

      if(attrs.distribution == 'any' && attrs.users == '') {
        this.errors['users'] = '指定ユーザーが未入力です。';
      }

      if(attrs.display_begin_at == '' || attrs.display_end_at == '') {
        this.errors['display_date'] = "掲載期間が未入力です。";
      }

      if(attrs.article == '') {
        this.errors['article'] = "記事が未入力です。";
      }

      if ( !_.isEmpty(this.errors) ) {
        return this.errors;
      }
    }
  });
})( app.models );
