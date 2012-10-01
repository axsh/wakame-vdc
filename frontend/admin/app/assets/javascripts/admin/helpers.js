(function(){

  app.helpers = {
    date: {
      parse: function(date) {
        if( !_.isEmpty(date) ) {
          var d = moment.utc(date);
          d.local();
          return d.format('YYYY/MM/DD HH:mm:ss');
        } else {
          return '';
        }
      },

      iso8601: function(date) {
        if( !_.isEmpty(date) && moment(date).isValid()) {
          return moment(date).format()
        }
      }
    },

    date_ja: {
      parse: function(date) {
        var d = moment.utc(date);
        d.local();
        return d.format('YYYY年MM月DD日 HH:mm:ss');
      }
    }
  };

})();
