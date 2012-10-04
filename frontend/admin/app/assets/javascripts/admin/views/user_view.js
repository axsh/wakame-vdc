(function ( views ) {
   views.ResultView = views.ResultView.extend({
     events: {
       'click button.user_login': 'spoofLogin'
     },

     spoofLogin: function(e) {
       var self = this;
       var target = $('#content');

       var request = $.ajax({
	 type: "GET",
	 url: "api/generate_token",
	 data: 'id='+self.model.get('uuid'),
	 dataType: "json",
	 async: false
       });

       request.done(function(response) {
	 window.open(app.info.api_endpoints.dcmgr_gui +
		     '/session/new?token='+ encodeURIComponent(response.results.token) +
		     '&user_id='+ response.results.user_id +
		     '&timestamp='+ encodeURIComponent(response.results.timestamp));
	 });

       request.fail(function(response) {
	 app.notify.error('Tokenの取得に失敗しました。');
       });
     }
   });

})( app.views );