(function() {

  this.Search = Ember.View.create({
    templateName: 'user_search',
  });

  this.List = Ember.View.create({
    templateName: 'user_list',
    contentBinding: Ember.Binding.oneWay('DcmgrAdmin.Controllers.User.List.content')
  });

  this.Search.appendTo("#user_search");
  this.List.appendTo("#user_list");

}).call(DcmgrAdmin.Views.User);