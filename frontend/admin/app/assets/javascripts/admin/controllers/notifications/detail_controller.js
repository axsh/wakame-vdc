(function(){

  // Defer initialization until doc ready.
  $(function(){

    app.collections.detailItems = new app.collections.DetailCollection({
      model: app.models.Notification
    });

    app.views.detail = new app.views.DetailView({
      collection: app.collections.detailItems,
      template: _.template($('#detailNotification').html())
    });

    app.router = new app.Router;
    Backbone.history.start();

  });

})();
