(function(){
   // Defer initialization until doc ready.
   $(function(){
       app.collections.detailItems = new app.collections.SshKeyPairDetailCollection({
         model: app.models.SshKeyPair,
       });

       app.views.detail = new app.views.DetailView({
         collection: app.collections.detailItems,
         template: _.template($('#detailSshKeyPair').html()),
       });
       app.router = new app.Router;
       Backbone.history.start();
   });
})();
