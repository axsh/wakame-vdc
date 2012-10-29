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
      addErrorClass: function(el, name) {
        if( _.has(this.model.errors, name)) {
          el.addClass('error');
        }
      },
      initialize : function() {
        var self = this;
        var notification_id = location.pathname.split('/')[2];
        this.model = new this.model({
          is_confirmed: false,
          is_new: true,
          distribution: 'all',
          title: '',
          article: '',
          display_begin_at: '',
          display_end_at: '',
          users: ''
        });

        this.params = {
          is_new: true,
          user_all_checked: 'checked',
          user_any_checked: '',
          distribution: 'all'
        }

        if( notification_id != 'new' ) {
          this.model.url = app.info.api_endpoints.dcmgr_gui + '/api/notifications/' + notification_id + '.json';
          this.model.fetch({
            async: false
          });
          this.params.is_new = false;
        }

        this.model.on('error', function(model, error){
          self.render();
          self.addErrorClass(self.$el.find('#control_title'), 'title');
          self.addErrorClass(self.$el.find('#control_article'), 'article');
          self.addErrorClass(self.$el.find('#control_display_date'), 'display_date');
          self.addErrorClass(self.$el.find('#control_option_users'), 'users');
        });

        this.render();

      },

      render: function() {

        var distribution = this.$el.find('[name=users]:checked').val();

        if( _.contains([distribution, this.model.get('distribution')], 'any')) {
          this.params.user_all_checked = '';
          this.params.user_any_checked = 'checked';
        } else {
          this.params.user_all_checked = 'checked';
          this.params.user_any_checked = '';
        }

        var view_params = {}
        _.extend(view_params, this.model.attributes,
                              this.params,
                              {'errors': this.model.errors});

        this.$el.html(this.template(view_params));

        if( this.params.user_any_checked == 'checked') {
          this.show_users();
        } else {
          this.$el.find('#control_option_users').hide();
        }

        var pubishFromPicker = new app.DatetimePicker({
          input_form: this.$el.find('#display_begin_at'),
          icon: this.$el.find('#icon_display_begin_at')
        });

        var pubishToPicker = new app.DatetimePicker({
          input_form: this.$el.find('#display_end_at'),
          icon: this.$el.find('#icon_display_end_at')
        });


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
        var display_begin_at = this.$el.find('[name=display_begin_at]').val();
        var display_end_at = this.$el.find('[name=display_end_at]').val();

        this.model.set('title', title, {silent:true});
        this.model.set('article', article, {silent:true});
        this.model.set('display_begin_at', display_begin_at, {silent:true});
        this.model.set('display_end_at', display_end_at, {silent:true});
        this.model.set('distribution', distribution, {silent:true});

        if(distribution == 'any') {
          var users = this.$el.find('[name=input_users]').val();
          this.model.set('users', users, {silent:true});
          this.params.distribution = 'any';
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

          this.model.set('display_begin_at', app.helpers.date.iso8601(this.model.get('display_begin_at')));
          this.model.set('display_end_at', app.helpers.date.iso8601(this.model.get('display_end_at')));
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
          this.model.set('display_begin_at', app.helpers.date.iso8601(this.model.get('display_begin_at')));
          this.model.set('display_end_at', app.helpers.date.iso8601(this.model.get('display_end_at')));
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
