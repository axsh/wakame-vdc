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

      if(attrs.distribution == 'any' && !attrs.users == '') {
        if(!_.isObject(attrs.users)) {
          var arr = _.map(attrs.users.split(','), function(user){
            return _.isNull(user.match(/^u-[a-z0-9]*$/));
          });
          if(_.any(arr)) {
            this.errors['users'] = '指定ユーザーの書式が違います。';
          }
        }
      }

      if(attrs.display_begin_at == '' || attrs.display_end_at == '') {
        this.errors['display_date'] = "掲載期間が未入力です。";
      }

      if(!attrs.display_begin_at == '') {
        if(_.isNull(attrs.display_begin_at.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/))){
          if(_.isNull(attrs.display_begin_at.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}$/))){
            if(_.isNull(attrs.display_begin_at.match(/^\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2}$/))) {
              this.errors['display_date'] = "掲載期間の書式が違います。";
            }
          }
        }
      }

      if(!attrs.display_end_at == '') {
        if(_.isNull(attrs.display_end_at.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/))){
          if(_.isNull(attrs.display_end_at.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}$/))){
            if(_.isNull(attrs.display_end_at.match(/^\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2}$/))) {
              this.errors['display_date'] = "掲載期間の書式が違います。";
	    }
          }
        }
      }

      if(Date.parse(attrs.display_begin_at) > Date.parse(attrs.display_end_at)) {
        this.errors['display_date'] = "無効な掲載期間です。";
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
