(function ( models ) {

  models.Item = Backbone.Model.extend({
    url: function() {
      // return _.string.sprintf('%s/%s.json', this.urlRoot, this.id)
      return _.string.sprintf('%s?id=%s', this.urlRoot, this.id)
    }
  });

})( app.models );