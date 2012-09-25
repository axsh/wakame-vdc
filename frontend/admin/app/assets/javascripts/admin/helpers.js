(function(){

  app.helpers = {
    date: {
      parse: function(date) {
        var d = moment.utc(date);
        d.local();
        return d.format('YYYY/MM/DD HH:mm:ss');
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
