
Ext.apply(Ext,{
  maxZindex : function() {
    var ret = 0;
    var els = Ext.select('*');
    els.each(function(el){
    var zIndex = el.getStyle('z-index');
    if(Ext.isNumber(parseInt(zIndex)) && ret < zIndex) {
      ret = zIndex;
    }
  }, this);
    return ret;
},
  getScrollPos: function() {
    var y = (document.documentElement.scrollTop > 0)
       ? document.documentElement.scrollTop
       : document.body.scrollTop;
    var x = (document.documentElement.scrollLeft > 0)
       ? document.documentElement.scrollLeft
        : document.body.scrollLeft;
    return {
      x: x,
      y: y
    };
  }
});
