// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//<![CDATA[
jQuery(function($){

  //global
  window.dcmgrGUI = new DcmgrGUI();
  window.dcmgrGUI.initialize();
  window.dcmgrGUI.notification = new DcmgrGUI.Notification;

	//Toggle side menus.
	var regionpos = 0;
	$('#regionselect').click(function () {
		if(regionpos==0){regionpos+=33;}else{regionpos=0;}
		$('#regionselect').css("background-position","0px -"+regionpos+"px");
		$('#regionmenu').toggle();
	});
	
	$('#regionmenu li a').click(function () {
		if(regionpos==0){regionpos+=33;}else{regionpos=0;}
		$('#regionselect').css("background-position","0px -"+regionpos+"px");
		$('#regionselect').html($(this).html());
		$('#regionmenu').toggle();
	});
	
	//Toggle maincontent
  $('.showhide').click(function(){
   $(this).parent().next().toggle();
   //Swap background image.
   var imgurl = $(this).css("background-image");
   var img = imgurl.match(/.+\/images\/(btn_[a-z]+\.gif)/);
   if(img[1] == "btn_hide.gif"){
     $(this).css("background-image","url(images/btn_show.gif)");
     $(this).css("background-repeat","no-repeat");
   }else{
     $(this).css("background-image","url(images/btn_hide.gif)");
     $(this).css("background-repeat","no-repeat");
   }
  });
  
	//Toggle InstanceActions menu.
	var instancepos = 0;
	$('#instanceaction').click(function () {
		if(instancepos==0){instancepos+=26;}else{instancepos=0;}
		$('#instanceaction').css("background-position","0px -"+instancepos+"px");
		$('#actionlist').toggle();
	});
	
	$('#actionlist li a').click(function () {
		if(instancepos==0){instancepos+=26;}else{instancepos=0;}
		$('#instanceaction').css("background-position","0px -"+instancepos+"px");
		$('#instanceaction').html($(this).html());
		$('#actionlist').toggle();
	});
	
	//Toggle VolumeActions menu.
	var volumepos = 0;
	$('#volumeaction').click(function () {
		if(volumepos==0){volumepos+=26;}else{volumepos=0;}
		$('#volumeaction').css("background-position","0px -"+volumepos+"px");
		$('#volumelist').toggle();
	});
	
	$('#volumelist li a').click(function () {
		if(volumepos==0){volumepos+=26;}else{volumepos=0;}
		$('#volumeaction').css("background-position","0px -"+volumepos+"px");
		$('#volumeaction').html($(this).html());
		$('#volumelist').toggle();
	});
	
	//Toggle ReservedInstances menu.
	var rsvinstancepos = 0;
	$('#reservedinstance').click(function () {
		if(rsvinstancepos==0){rsvinstancepos+=26;}else{rsvinstancepos=0;}
		$('#reservedinstance').css("background-position","0px -"+rsvinstancepos+"px");
		$('#rsvinstancelist').toggle();
	});
	
	$('#rsvinstancelist li a').click(function () {
		if(rsvinstancepos==0){rsvinstancepos+=26;}else{rsvinstancepos=0;}
		$('#reservedinstance').css("background-position","0px -"+rsvinstancepos+"px");
		$('#reservedinstance').html($(this).html());
		$('#rsvinstancelist').toggle();
	});
	
  $('#accounts_account_uuid').live('change',function() {
    $(this).parent('form').submit();
    return false;
  });

  $('#select_language_locale').bind('change', function(){
    $('#select_language')[0].submit();
  });
  
  $(document).ajaxError(function(e, xhr, settings, exception) {
    var message = '';
    if(xhr.status == 0){
      message = 'Please Check Your Network.';
    }else if(e == 'parsererror'){
      message = 'Parsing JSON Request failed.';
    }else if(e == 'timeout'){
      message = 'Request Time out.';
    }else {
      var is_dcmgr = function() {
        if(xhr.getResponseHeader("X-Vdc-Request-Id")) {
            return true;
        } else {
            return false;
        }
      }
      
      if(is_dcmgr()) {
        try {
          var r = $.parseJSON(xhr.responseText);
          var code = xhr.status;
	  var body = sprintf(r.message, r.message_params);
        } catch(e) {
          var code = xhr.status;
          var body = 'Request faild.'
          dcmgrGUI.logger.push(e.type, xhr);
        }  
      } else{
        var code = xhr.status;
        var body = xhr.statusText;
      }
      
      message = "<div id='error_box'>"
              + "<div class='error_code'>" + $.i18n.prop('code_error_box') + ': ' + code + '</div>'
              + "<div class='error_body'>" + body + '</div>'
              + '</div>';
    }

    dcmgrGUI.logger.push(e.type, xhr);

    if(dcmgrGUI.getConfig('error_popup')) {
      Sexy.error(message);
      if(dcmgrGUI.getConfig('error_popup_once')) {
        dcmgrGUI.setConfig('error_popup', false);
      }
    }
  });

  //Region selectmenu
  $('#regionmenu').selectmenu({
    width: 208,
    menuWidth: 208,
    style:'dropdown',
    icons: [
      {find: '.script', icon: 'ui-icon-script'},
      {find: '.image', icon: 'ui-icon-image'}
    ],
    select: function(event){
    }
  });

  $('#regionmenu-button').css('font-size', '13px')
                         .css('height', '25px');

  $('a[id^="ui-selectmenu-item"]').css('font-size', '13px')
    .css('height', '17px');

});
//]]>
