( function ( views ){

  // SearchViewをテンプレートで囲む
  views.SearchView = Backbone.View.extend({

    events: {
      'click #search': 'search',
    },

    // tagName: 'button',

    // template: '<>',

    initialize: function() {
      // var self = this;
      // this.collection.on('reset', this.render, this);
      // this.collection.on('change', this.render, this);
      // this.$el.appendTo('#pagination');
    },

    render: function() {
      // var html = this.template(this.collection.info());
      this.$el.html(html);
    },

    search: fnctioon() {
      alert('search');
    }

    $.('#search').click(function() {

    });

  });

})( app.views );