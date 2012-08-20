(function() {

this.search = Ember.View.create({
  templateName: 'notification_search',
  submit: function(e) {
    console.log(e);    
    var t = e.target;
    console.log(t);
  }
});

this.list = Ember.View.create({
  templateName: 'notification_list',
  contentBinding: Ember.Binding.oneWay('DcmgrAdmin.Controllers.Notification.List.content'),
  destroy: function(e) {
    console.log(e.target.id);
    var id = e.target.id;
    // console.log(e.target.className);
    // console.log(e.target.attributes);
    // console.log(e.target.name);
  }
});

this.search.appendTo("#notification_search");
this.list.appendTo("#notification_list");

}).call(DcmgrAdmin.Views.Notification);