/*
 * Wakame GUI JS
 */
Ext.onReady(function(){
  Ext.QuickTips.init();
  var formButtons = [ 
    { text: "Login", handler: submit, disabled:false }
  ];
  var formPanel = new Ext.FormPanel({
    standardSubmit: true,
    labelWidth: 75,
    frame:true,
    title: 'Wakame-login',
    style:'align:center',
    bodyStyle:'padding:5px 5px 0',
    renderTo: Ext.getDom('FormPanel'),
    width : 400,
    height: 150,
    defaults: {width: 230},
    defaultType: 'textfield',
    items: [{
        fieldLabel: 'User-Name',
        name: 'id',
        allowBlank:false
      },{
        fieldLabel: 'Password',
        name: 'pw',
        allowBlank:false,
        inputType: 'password'
      }
    ],
    buttons: formButtons
  });
  function submit() { 
	formPanel.getForm().getEl().dom.action = "/center/login"; 
	formPanel.getForm().getEl().dom.method = "POST";
	formPanel.getForm().submit(); 
  }
});
