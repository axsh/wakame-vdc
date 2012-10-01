(function (collections, paginator) {

 collections.PaginatedCollection = paginator.requestPager.extend({
  initialize: function(options) {

   if(_.has(options, 'server_api')) {
     var server_api = _.clone(options.server_api);
     _.each(_.keys(server_api), function(key){
       if(_.isEmpty(server_api[key])){
	   delete server_api[key];
       }
     });
    this.server_api = _.extend(server_api, this.server_api);
   }

   if(_.has(options, 'paginator_core')) {
    this.paginator_core = _.defaults(options.paginator_core, this.paginator_core);
   }

   if(_.has(options, 'model')) {
    this.model = options.model;
   }
  },

  // model: model,
  paginator_core: {
   type: 'GET',
   dataType: 'json',
  },

  paginator_ui: {
   firstPage: 1,
   currentPage: 1,
   perPage: 10,
   // totalPages: 30
  },

  // addSearchQuery: {
   // app.helpers.util.getQueryVars()
  // },

  server_api: {
   // 'filter': function() {
   //  console.log(this)
   //  return '&hoge'
   // },
   'limit': function() { return this.perPage },

   'start': function() { return (this.currentPage * this.perPage) - this.perPage },

   // field to sort by
   // 'orderby': function() {
   //  if(this.sortField === undefined)
   //   return 'ReleaseYear';
   //  return this.sortField;
   // },


   // what format would you like to request results in?
   // 'format': 'json',

   // custom parameters
   // '$inlinecount': 'allpages',
   // '$callback': 'callback'
  },

  parse: function (response) {
    if( _.isEmpty(response[0]) ) {
      var tags = _.clone(response.results);
    } else {
      // for Dcmgr
      var _response = _.clone(response[0]);
      var tags = _response.results;
      response.count = _response.total;
    }

   //fill with empty data.
   if(tags.length < this.perPage && !_.isEmpty(tags)) {
     var empty_data = {};
     _.each(_.keys(_.clone(tags[0])), function(k) {
       empty_data[k] = '';
     });

     var loop = this.perPage - tags.length;
     for(var i=0; i < loop; i++) {
      empty_data.id = null;
      tags.push(_.clone(empty_data));
     }
   }

   this.totalPages = Math.ceil(response.count / this.perPage);
   this.totalRecords = parseInt(response.count);

   return tags;
  }

 });

})( app.collections, Backbone.Paginator);
