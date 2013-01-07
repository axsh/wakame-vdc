( function ( views ){

  views.TextLogView = Backbone.View.extend({
    events: {
    },
    addErrorClass: function(el, name) {
      if( _.has(this.model.errors, name)) {
        el.addClass('error');
      }
    },

    initialize : function() {
      var c = this.collection;
      c.on('all', this.addAll, this);
      c.url = c.model.prototype.url;
      c.fetch();
    },

    addAll : function () {
      console.log($('#resultItemTemplate').html())
      this.$el.empty();
      this.collection.each (this.addOne);
    },

    addOne : function ( item ) {
      $('#content').append(_.template($('#resultItemTemplate').html(), item.attributes));
    }
  });

})( app.views );
