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

// Global Resources
Ext.apply(WakameGUI, {
  Header:null,
  Footer:null
});

WakameGUI.Header = function(headerTitle){

  function reqeustSuccess(response)
  {
    if (response.responseText !== undefined) { 
      Ext.get("WELCOME_MESSAGE").update('Welcome , ' + response.responseText);
    }
  }

  WakameGUI.Header.superclass.constructor.call(this,{
    region: "north", 
    height: 0,
    border: false,
    listeners: {
      'render': function(node){
        Ext.Ajax.request({
	      url: '/user-name',
	      method: "GET",
          success: reqeustSuccess
	    });
      }
    },
    tbar : [
      { xtype: 'tbtext',
        style: 'color:#0000ff; font-size:14px;',
        text : headerTitle
      },'->','-',
      { xtype: 'tbtext',
        id: 'WELCOME_MESSAGE',
        text : ''
      },'-',
      { text : 'Help',handler:function(){ alert('Help'); }
      },'-',
      { text: 'Logout',
        handler:function(){ location.href = "/logout" }
      },'-'
    ]
  });
}
Ext.extend(WakameGUI.Header, Ext.Panel);

WakameGUI.Footer = function(){
  WakameGUI.Footer.superclass.constructor.call(this,{
    region: "south", 
    height: 0,
    border: false,
    tbar : [
      { xtype: 'tbtext',
        text : '2009-2010,axsh Co., Ltd. All right reserved.'
      }
    ]
  });
}
Ext.extend(WakameGUI.Footer, Ext.Panel);
