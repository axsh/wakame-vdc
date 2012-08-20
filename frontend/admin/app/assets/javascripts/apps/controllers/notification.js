(function() {

  this.Search = Ember.ArrayController.create({

  });

  this.List = Ember.ArrayController.create({
    content: [],
    show: function() {
      var d = [];
      for(var i=0; i<20; i++) {
        d.push({id: "user_" + i, user_id: i});
      }
      this.set('content', d);
    }
  })

  this.List.show();

 }).call(DcmgrAdmin.Controllers.Notification);