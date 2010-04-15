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
  Service:null
});

WakameGUI.Service = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'wmi-id' },
      { name: 'name' },
      { name: 'owner-id' },
      { name: 'visibility' },
      { name: 'architecture' }
    ],
    data:[
      [ 'WK-2009', 'Blog', 'O10001', 'public', 'i386'],
      [ 'WK-2011', 'SNS', 'O10001', 'public', 'i386']
    ]
  });

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "WMI-ID", width: 100, dataIndex: 'wmi-id' },
    { header: "Name", width: 100, dataIndex: 'name' },
    { header: "Owner", width: 100, dataIndex: 'owner-id' },
    { header: "Visibility", width: 100, dataIndex: 'visibility' },
    { header: "Architecture", width: 100, dataIndex: 'architecture'  }
  ]);
  
  this.refresh = function(){
    store.reload();
  }

  WakameGUI.Service.superclass.constructor.call(this, {
    title: 'Service',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    }),
    tbar : [
      { text : 'Launch',handler:function(){}
      },
      { text : 'Delete',handler:function(){}
      }
    ]
  });
}
Ext.extend(WakameGUI.Service, Ext.grid.GridPanel);
