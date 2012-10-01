(function(){

  $(function(){

    app.views.create_notification = new app.views.CreateNotification({});

    app.router = new app.Router;
    Backbone.history.start();

  });

})();
