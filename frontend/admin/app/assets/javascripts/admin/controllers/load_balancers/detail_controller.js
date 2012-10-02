(function(){
   // Defer initialization until doc ready.
   $(function(){
	 app.collections.detailItems = new app.collections.LoadBalancerDetailCollection({
         model: app.models.LoadBalancer,
       });

       app.views.detail = new app.views.DetailView({
         collection: app.collections.detailItems,
         template: _.template($('#detailLoadBalancer').html()),
       });
       app.router = new app.Router;
       Backbone.history.start();
   });
})();
