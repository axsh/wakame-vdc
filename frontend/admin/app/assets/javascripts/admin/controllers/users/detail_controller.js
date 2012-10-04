(function(){
   // Defer initialization until doc ready.
   $(function(){
       app.collections.detailItems = new app.collections.UserDetailCollection({
         model: app.models.User,
       });

       app.views.detail = new app.views.DetailView({
         collection: app.collections.detailItems,
         template: _.template($('#detailUser').html()),
       });
       app.router = new app.Router;
       Backbone.history.start();
   });
})();
