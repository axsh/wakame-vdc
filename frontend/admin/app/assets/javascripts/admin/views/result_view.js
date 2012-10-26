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
			if(attr.display_begin_at && attr.display_end_at) {
				var display_begin_at = app.helpers.date.parse(attr.display_begin_at)
				var display_end_at = app.helpers.date.parse(attr.display_end_at)
				return display_begin_at + ' ~ ' + display_end_at
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
		}

	});

})( app.views );
