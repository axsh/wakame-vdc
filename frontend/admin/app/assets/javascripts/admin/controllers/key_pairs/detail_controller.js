(function(){
   // Defer initialization until doc ready.
   $(function(){
       app.collections.detailItems = new app.collections.KeypairDetailCollection({
         model: app.models.Instance,
       });

       app.views.detail = new app.views.DetailView({
         collection: app.collections.detailItems,
         template: _.template($('#detailKeypair').html()),
       });
       app.router = new app.Router;
       Backbone.history.start();
   });
})();
