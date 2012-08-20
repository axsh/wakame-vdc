(function() {

  this.Search = Ember.View.create({
    templateName: 'instance_search',
  });

  this.List = Ember.View.create({
    templateName: 'instance_list',
    contentBinding: Ember.Binding.oneWay('DcmgrAdmin.Controllers.Instance.List.content')
  });

  this.Search.appendTo("#instance_search");
  this.List.appendTo("#instance_list");

}).call(DcmgrAdmin.Views.Instance);