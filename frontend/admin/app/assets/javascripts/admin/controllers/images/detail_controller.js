(function(){
   // Defer initialization until doc ready.
   $(function(){
       app.collections.detailItems = new app.collections.ImageDetailCollection({
         model: app.models.Image,
       });

       app.views.detail = new app.views.DetailView({
         collection: app.collections.detailItems,
         template: _.template($('#detailImage').html()),
       });
       app.router = new app.Router;
       Backbone.history.start();
   });
})();
