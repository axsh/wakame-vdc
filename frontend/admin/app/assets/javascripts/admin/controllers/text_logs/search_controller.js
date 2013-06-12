(function(){
  // Defer initialization until doc ready.
  $(function(){
    app.collections.textLogItems = new app.collections.TextLogCollection({
      model: app.models.TextLog,
    });
    app.views.list = new app.views.TextLogView({collection: app.collections.textLogItems});
    app.router = new app.Router;
    Backbone.history.start();
  });
})();