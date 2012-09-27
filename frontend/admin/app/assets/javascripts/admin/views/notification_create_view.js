(function ( views ) {

    views.CreateNotification = Backbone.View.extend({
      state: 'init',
      el : '#content',
      model: app.models.Notification,
      template: _.template($('#createNotification').html()),
      events: {
        "click #confirm": 'confirm',
        "click #create": 'create',
        "click #update": 'update',
        "click #option_users": 'show_users',
        "click #option_user_all": 'hide_users'
      },

      initialize : function() {

        var notification_id = location.pathname.split('/')[2];
        this.model = new this.model({
          is_confirmed: false,
          distribution: 'all',
          title: '',
          article: '',
          publish_date_from: '',
          publish_date_to: '',
          users: ''
        });

        this.params = {
          is_new: true,
          user_all_checked: 'checked',
          user_any_checked: ''
        }

        if( _.isString(notification_id) ) {
          this.model.url = app.info.api_endpoints.dcmgr_gui + '/api/notifications/' + notification_id + '.json';
          this.model.fetch({
            async: false
          });
          this.params.is_new = false;
        }

        if( ! _.isEmpty(this.model.get('users')) ) {
          this.params.user_all_checked = '';
          this.params.user_any_checked = 'checked';
        }

        this.model.on('error', function(model, error){
        });

        this.render();

        if(! _.isEmpty(this.model.get('users'))) {
          this.show_users();
        } else {
          this.$el.find('#control_option_users').hide();
        }

        var pubishFromPicker = new app.DatetimePicker({
          input_form: this.$el.find('#publish_date_from'),
          icon: this.$el.find('#icon_publish_date_from')
        });

        var pubishToPicker = new app.DatetimePicker({
          input_form: this.$el.find('#publish_date_to'),
          icon: this.$el.find('#icon_publish_date_to')
        });

      },

      render: function() {
        var view_params = _.extend(this.model.attributes, this.params);
        this.$el.html(this.template(view_params));
        return this;
      },

      show_users: function() {
        this.$el.find('#control_option_users').show('fast');
      },

      hide_users: function() {
        this.$el.find('#control_option_users').hide('fast');
      },

      confirm: function(e) {
        var distribution = this.$el.find('[name=users]:checked').val();
        var article = this.$el.find('[name=article]').val();
        var title = this.$el.find('[name=title]').val();
        var publish_date_from = this.$el.find('[name=publish_date_from]').val();
        var publish_date_to = this.$el.find('[name=publish_date_to]').val();

        this.model.set('title', title, {silent:true});
        this.model.set('article', article, {silent:true});
        this.model.set('publish_date_from', publish_date_from, {silent:true});
        this.model.set('publish_date_to', publish_date_to, {silent:true});

        if(distribution == 'any') {
          var users = this.$el.find('[name=input_users]').val();
          this.model.set('users', users, {silent:true});
        } else {
          this.model.set('users', '', {silent:true});
        }

        this.model.set('_silent', false);

        if(this.model.isValid()){
          this.model.set('is_confirmed', true);
          this.render();
        }
        return false;
      },

      create: function(e) {
        var self = this;
        this.$el.find('#create').addClass('disabled');
        if(this.model.isValid() && this.state == 'init'){
          this.state = 'creating';

          this.model.set('publish_date_from', app.helpers.date.iso8601(this.model.get('publish_date_from')));
          this.model.set('publish_date_to', app.helpers.date.iso8601(this.model.get('publish_date_to')));
          this.model.url =  app.info.api_endpoints.dcmgr_gui + '/api/notifications';
          this.model.save(null, {
            'success': function(response, xhr) {
               this.state = 'created';
               var redirect_url = app.info.api_endpoints.admin + '/notifications';
               window.location.href = redirect_url;
               window.location.replace(redirect_url);
            },
          });
        };
        return false;
      },

      update: function(e) {
        var self = this;
        var notification_id = location.pathname.split('/')[2];
        this.$el.find('#update').addClass('disabled');
        if(this.model.isValid() && this.state == 'init'){
          this.state = 'updating';
          this.model.set('publish_date_from', app.helpers.date.iso8601(this.model.get('publish_date_from')));
          this.model.set('publish_date_to', app.helpers.date.iso8601(this.model.get('publish_date_to')));
          this.model.url = app.info.api_endpoints.dcmgr_gui + '/api/notifications/' + notification_id + '.json';
          this.model.save(null, {
            'success': function(response, xhr) {
               this.state = 'updated';
               var redirect_url = app.info.api_endpoints.admin + '/notifications';
               window.location.href = redirect_url;
               window.location.replace(redirect_url);
            },
          });
        };
        return false;
      }
    });

})( app.views );
