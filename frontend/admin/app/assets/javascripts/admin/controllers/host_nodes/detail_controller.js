(function(){
   // Defer initialization until doc ready.
   $(function(){
       app.collections.detailItems = new app.collections.HostNodeDetailCollection({
         model: app.models.HostNode,
       });

       app.collections.statisticsItems = new app.collections.StatisticsCollection({
	 model: app.models.Statistics,
       });

       app.views.detail = new app.views.DetailView({
         collection: app.collections.detailItems,
         template: _.template($('#detailHostNode').html()),
       });

       app.views.statistics = new app.views.DetailView({
	 el: '#statistics',
	 collection: app.collections.statisticsItems,
	 template: _.template($('#detailStatistics').html()),
       });

       app.router = new app.Router;
       Backbone.history.start();
   });
})();
