(function() {
  
  DcmgrAdmin = Ember.Application.create();
  DcmgrAdmin.Controllers = Ember.Namespace.create();
  DcmgrAdmin.Controllers.Notification = Ember.Namespace.create();
  DcmgrAdmin.Controllers.Instance = Ember.Namespace.create();
  DcmgrAdmin.Controllers.HostNode = Ember.Namespace.create();
  DcmgrAdmin.Controllers.KeyPair = Ember.Namespace.create();
  DcmgrAdmin.Controllers.MachinImage = Ember.Namespace.create();
  DcmgrAdmin.Controllers.User = Ember.Namespace.create();
  
  DcmgrAdmin.Views = Ember.Namespace.create();
  DcmgrAdmin.Views.Notification = Ember.Namespace.create();
  DcmgrAdmin.Views.Instance = Ember.Namespace.create();
  DcmgrAdmin.Views.HostNode = Ember.Namespace.create();
  DcmgrAdmin.Views.KeyPair = Ember.Namespace.create();
  DcmgrAdmin.Views.MachineImage = Ember.Namespace.create();
  DcmgrAdmin.Views.User = Ember.Namespace.create();

}).call(this);