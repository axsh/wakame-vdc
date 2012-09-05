(function(){

  app.helpers = {
    date: {
      parse: function(date) {
        var d = moment.utc(date);
        d.local();
        return d.format('YYYY/MM/DD HH:mm:ss');
      }
    }
  };

})();
