(function (collections) {

  collections.DetailCollection = Backbone.Collection.extend({

    initialize: function(options) {
      if(_.has(options, 'model')) {
        this.model = options.model;
      }
    },

    info: function() {
      if( _.isArray(this.models) && _.has(this.models, 0) ) {
        return this.models[0].attributes;
      } else {
        return {};
      }
    },

    parse: function (response) {
       return response.result;
    }
  });

  collections.UserDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.InstanceDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.SshKeyPairDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.ImageDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.HostNodeDetailCollection = collections.DetailCollection.extend({
    parse: function (response) {
      return response;
    }
  });

  collections.StatisticsCollection = collections.DetailCollection.extend({
    parse: function (response) {
      var res = _.groupBy(response[0].results, function(account){
	return account.account_id;
      });

      var data = [];
      data[0] = {'accounts':res}
      return data;
    },

    accountTotal: function(accounts){
      var account_ids = _.keys(accounts);
      return account_ids.length;
    },

    instanceTotal: function(accounts){
      var instances = _.map(accounts, function(account){
        return account.length;
      });

      var total = _.reduce(instances, function(sum, num){
	return sum + num;
      },0);
      return total;
    },
  });
})( app.collections);
