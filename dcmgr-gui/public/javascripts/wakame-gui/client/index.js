/*-
 * Copyright (c) 2010 axsh co., LTD.
 * All rights reserved.
 *
 * Author: Takahisa Kamiya
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
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
	formPanel.getForm().getEl().dom.action = "/client/login"; 
	formPanel.getForm().getEl().dom.method = "POST";
	formPanel.getForm().submit(); 
  }
});
