(function ( views ) {

	views.PaginatedView = Backbone.View.extend({

		events: {
			'click a.servernext': 'nextResultPage',
			'click a.serverprevious': 'previousResultPage',
			'click a.orderUpdate': 'updateSortBy',
			'click a.serverlast': 'gotoLast',
			'click a.page': 'gotoPage',
			'click a.serverfirst': 'gotoFirst',
			'click a.serverpage': 'gotoPage',
			'click .serverhowmany a': 'changeCount'
		},

		tagName: 'aside',

		template: _.template($('#tmpServerPagination').html()),

		initialize: function() {
			var self = this;
			this.collection.on('reset', this.render, this);
			this.collection.on('change', this.render, this);
			this.$el.appendTo('#pagination');

			$(window).keydown(function(e){

				switch(e.keyCode) {
					// Left Key
					case 37:
						if (self.collection.currentPage > self.collection.firstPage) { 
							self.previousResultPage(e);
						}
						break;
					// Right Key
					case 39:
						if (self.collection.currentPage < self.collection.totalPages) {
							self.nextResultPage(e);
						}
						break;
				}

			});
		},

		render: function() {
			var html = this.template(this.collection.info());
			this.$el.html(html);
		},

		updateSortBy: function(e) {
			e.preventDefault();
			var currentSort = $('#sortByField').val();
			this.collection.updateOrder(currentSort);
		},

		nextResultPage: function(e) {
			e.preventDefault();
			this.collection.requestNextPage();
			this.updateNavigate();
		},

		previousResultPage: function(e) {
			e.preventDefault();
			this.collection.requestPreviousPage();
			this.updateNavigate();
		},

		gotoFirst: function(e) {
			e.preventDefault();
			this.goTo(this.collection.information.firstPage);
		},

		gotoLast: function(e) {
			e.preventDefault();
			this.goTo(this.collection.information.lastPage);
		},

		gotoPage: function(e) {
			e.preventDefault();
			var page = $(e.target).text();
			this.goTo(page);
		},

		changeCount: function(e) {
			e.preventDefault();
			var per = $(e.target).text();
			this.collection.howManyPer(per);
		},

		goTo: function(page) {
			this.collection.goTo(page);
			this.updateNavigate();
		},

		updateNavigate: function() {
			var page = this.collection.currentPage.toString();
			Backbone.history.navigate(page);
		}

	});

})( app.views );