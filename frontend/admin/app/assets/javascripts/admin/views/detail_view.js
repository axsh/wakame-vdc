( function ( views ){

  views.DetailView = Backbone.View.extend({

    el : '#content',

    template: _.template($('#detailNotification').html()),

    initialize: function() {
      var tags = this.collection;
      tags.on('all', this.render, this);
      tags.get();
    },

    render: function() {
      var html = this.template(this.collection.info());
      this.$el.html(html);
    }

  });

})( app.views );
