( function ( views ){

	views.ResultView = Backbone.View.extend({

		tagName : 'tr',

		template: _.template($('#resultItemTemplate').html()),

		initialize: function() {
			this.model.bind('change', this.render, this);
			this.model.bind('destroy', this.remove, this);
		},

		publish_date : function() {
			var attr = this.model.attributes;
			if(attr.publish_date_from && attr.publish_date_to) {
				var publish_date_from = app.helpers.date.parse(attr.publish_date_from)
				var publish_date_to = app.helpers.date.parse(attr.publish_date_to)
				return publish_date_from + ' ~ ' + publish_date_to
			} else {
				return '';
			}
		},

		render : function() {
			if(_.isNull(this.model.attributes.id)) {
				this.$el.addClass('empty_row');
			}
			this.$el.html(this.template(this.model.toJSON()));
			return this;
		},

	});

})( app.views );
