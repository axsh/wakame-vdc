(function ( views ) {

  var pubishFromPicker = new app.DatetimePicker({
    input_form_id: '#publish_date_from',
    icon_id: '#icon_publish_date_from'
  });

  var pubishToPicker = new app.DatetimePicker({
    input_form_id: '#publish_date_to',
    icon_id: '#icon_publish_date_to'
  });

  $('#control_option_users').hide();
  $('#option_user_all').click(function() {
    $('#control_option_users').hide('fast');
  });

  $('#option_users').click(function() {
    $('#control_option_users').show('fast');
  });

  views.ResultView = views.ResultView.extend({
    events: {
      'click .delete': 'onDestroy'
    },

    onDestroy: function(e) {
      var self = this;

      var target = $('#destroyNotification');
      target.modal();
      target.on('hidden', function() {
        target.find('.actionDestroy').unbind('click');
      });

      target.find('.actionDestroy').bind('click', function() {

        self.model.destroy({

          success: function(model, response) {
            app.notify.success('お知らせを削除しました。');
          },

          error: function(model, response) {
            app.notify.error('お知らせの削除に失敗しました。管理者にお問い合わせください。');
          }

        });
      });

    }
  });

})( app.views );
