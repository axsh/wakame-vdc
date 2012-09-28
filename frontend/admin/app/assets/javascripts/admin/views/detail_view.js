( function ( views ){

  views.DetailView = Backbone.View.extend({

    el : '#content',

    initialize: function(options) {
      if(_.has(options, 'template')) {
        this.template = options.template;
      }
      var tags = this.collection;
      tags.on('all', this.render, this);
      tags.url = tags.model.prototype.url;
      tags.fetch();
    },

    render: function() {
      if(_.has(this.collection.info(), 'id')){
        var html = this.template(this.collection.info());
        this.$el.html(html);
      }
    }

  });

})( app.views );
