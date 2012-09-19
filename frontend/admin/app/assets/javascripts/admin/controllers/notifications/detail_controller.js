(function(){

  // Defer initialization until doc ready.
  $(function(){

    app.collections.detailItems = new app.collections.DetailCollection({});

    app.views.detail = new app.views.DetailView({collection:app.collections.detailItems});
    app.router = new app.Router;
    Backbone.history.start();

  });

})();
