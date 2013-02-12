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

      var Picker = new app.DatetimePicker({
        input_form: $('#display_begin_at'),
        icon: $('#icon_display_begin_at')
      });

      var c = this.collection;
      c.on('all', this.addAll, this);
      c.url = c.model.prototype.url;
      c.fetch();
    },

    addAll : function() {
      this.$el.empty();
      var self = this;
      var last_id = this.collection.models.length -1;
      if (last_id != -1) {
        var last_item_id = this.collection.models[last_id].id
        var tail = '<div id="textline" style="text-align:center"><br /><a id="tail" href="#' +last_item_id+ '">取得</a></div>';
      }
      var application_id = app.utils.parsedSearch('application_id');

      this.collection.each(this.addOne);
      $('#content').append(tail);

      // Tail logging
      $('#content').find('#tail').click(function(){
        $('#content').find('#textline').remove();
        var c = self.collection;
        c.url = c.model.prototype.url + '&id=' + last_item_id ;
        c.fetch();
      });

      // Application Keys
      $.get(app.info.api_endpoints.dcmgr + '/api/12.03/text_logs/keys.json', function(items){
        var keys = items[0].results;
        var key_collection = [];
        $.each(keys, function(key, value){
          key_collection.push(value.split(':')[2]);
        });
        key_collection = _.uniq(key_collection);
        key_collection = _.without(key_collection, 'invalid')

        // TODO: templating
        var start_time = app.utils.decodeSearhTime(app.utils.parsedSearch('start_time'));
        $('#display_begin_at').attr('value', start_time);

        $('#select_keys').empty();
        $.each(key_collection, function(key, value){

          if(value == application_id) {
            var option_el = "<option value='"+value+"'selected>"+ value +"</options>"
          } else {
            var option_el = "<option value='"+value+"'>"+ value +"</options>"
          }

          $('#select_keys').append(option_el);
        });

      });
    },

    addOne : function( item ) {
      $('#content').append(_.template($('#resultItemTemplate').html(), item.attributes));
    },
  });

})( app.views );
