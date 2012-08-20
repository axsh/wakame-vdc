(function() {

  this.Search = Ember.View.create({
    templateName: 'host_node_search',
  });

  this.List = Ember.View.create({
    templateName: 'host_node_list',
    contentBinding: Ember.Binding.oneWay('DcmgrAdmin.Controllers.HostNode.List.content')
  });

  this.Search.appendTo("#host_node_search");
  this.List.appendTo("#host_node_list");

}).call(DcmgrAdmin.Views.HostNode);