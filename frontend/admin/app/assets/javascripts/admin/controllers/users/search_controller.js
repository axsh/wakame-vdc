(function(){

    // Defer initialization until doc ready.
    $(function(){

	    app.collections.paginatedItems = new app.collections.PaginatedCollection({

		    model: app.models.Item.extend({
			    urlRoot: app.info.api_endpoints.dcmgr_gui + '/api/users.json',
			}),

		    server_api: {
		    },

		    paginator_core: {
			url: app.info.api_endpoints.dcmgr_gui + '/api/users.json'
		    }

		});

	    app.views.pagination = new app.views.PaginatedView({collection:app.collections.paginatedItems});
	    app.views.list = new app.views.ListView({collection: app.collections.paginatedItems});

	    app.router = new app.Router;
	    Backbone.history.start();
	});

})();