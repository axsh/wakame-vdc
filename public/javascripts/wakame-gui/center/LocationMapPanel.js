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
  LocationMap:null,
  MAPProperty:null,
  MAPView:null
});

WakameGUI.LocationMap = function(){
  var mPropertyPanel = new WakameGUI.MAPProperty();
  var mtabPanel      = new WakameGUI.MAPTab('center',600);
  mtabPanel.add(new WakameGUI.MAPView('1F-100',"/images/map/1F-10.jpeg"));
  mtabPanel.add(new WakameGUI.MAPView('1F-101',"/images/map/1F-10.jpeg"));
  mtabPanel.add(new WakameGUI.MAPView('2F-101',"/images/map/1F-10.jpeg"));
  mtabPanel.add(new WakameGUI.MAPView('2F-200',"/images/map/1F-10.jpeg"));
  mtabPanel.add(new WakameGUI.MAPView('3F-105',"/images/map/1F-10.jpeg"));
  mtabPanel.add(new WakameGUI.MAPView('3F-200',"/images/map/1F-10.jpeg"));
  WakameGUI.LocationMap.superclass.constructor.call(this, {
    split: true,
    header: false,
    border: false,
    layout: 'border',
	items: [mtabPanel,mPropertyPanel],
    tbar : [
      { text : 'Add Map',
        handler:function(){
          var addmap = new AddMapWindow();
		  addmap.show();
        }
      },
      { text : 'Remove',handler:function(){
          alert('Remove');
         }
      },
      { text : 'Edit',handler:function(){
          alert('Edit');
        }
      }
    ]
  });

  AddMapWindow = function(){
    var form = new Ext.form.FormPanel({
//    fileUpload: true,
      width: 400,
      baseCls: 'x-plain',
      items: [{
      fieldLabel: 'Map-Name',
      xtype: 'textfield',
      id: 'nm',
      anchor: '100%'
      },
      {
      fieldLabel: 'Map-File',
      xtype: 'textfield',
      inputType: 'file',
      width: 200,
      id: 'file',
      anchor: '100%'
      },
      {
      fieldLabel: 'Memo',
      xtype: 'textarea',
      id: 'mm',
      anchor: '100%'
      }]
    });

    AddMapWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      height: 220,
      width: 400,
	  layout:'fit',
      title: 'Add Map',
      collapsible:true,
      titleCollapse:true,
	  modal: true,
	  plain: true,
	  closeAction:'hide',
      defaults:{bodyStyle:'padding:15px'},
	  items: [form],
	  buttons: [{
        text:'Save',
        handler: function(){
          form.getForm().submit({
            url: '/map_upload',
            waitMsg: 'Uploading...',
            method: 'POST',
            scope: this,
            success: function(form, action) {
              alert('Success !');
	          this.close();
            },
            failure: function(form, action) {
              alert('Upload file failure.');
	          this.close();
            }
          });
        },
        scope:this
      },{
	    text: 'Close',
	    handler: function(){
          this.close();
        },
        scope:this
      }]
    });
  }
  Ext.extend(AddMapWindow, Ext.Window);
}
Ext.extend(WakameGUI.LocationMap, Ext.Panel);

WakameGUI.MAPProperty = function(){
  WakameGUI.MAPProperty.superclass.constructor.call(this, {
    region: 'east',
    title: "Property",
    split: true,
    width: 150,
    collapsed:false,
    collapsible:true,
    titleCollapse:true,
    animCollapse:true,
    bodyStyle:'padding:15px',
    html: 'Memo:xxxx'
  });
}
Ext.extend(WakameGUI.MAPProperty, Ext.Panel);

WakameGUI.MAPView = function(name,url){
  WakameGUI.MAPView.superclass.constructor.call(this, {
    region: 'center',
    title: name,
    autoScroll: true,
    split: true,
    layout: 'fit',
    html: '<img src='+url+'>'
//  html: '<img src='1F-10.jpeg">'
//  bodyStyle: "background-image:url(1F-10.jpeg); background-repeat: no-repeat; background-attachment: fixed;"
  });
}
Ext.extend(WakameGUI.MAPView, Ext.Panel);

