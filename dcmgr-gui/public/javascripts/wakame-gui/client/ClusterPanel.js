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
  Cluster:null,
  ClusterList:null,
  ClusterCtrl:null
});

WakameGUI.Cluster = function(){
  var clistPanel = new WakameGUI.ClusterList();
  var cctrlPanel = new WakameGUI.ClusterCtrl();

  WakameGUI.Cluster.superclass.constructor.call(this, {
    title: 'Cluster',
    width: 320,
    header: false,
    border: false,
    layout: 'border',
	items: [clistPanel,cctrlPanel]
  });
}
Ext.extend(WakameGUI.Cluster, Ext.Panel);

WakameGUI.ClusterList = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'cluster-id' },
      { name: 'name' },
      { name: 'state' },
      { name: 'public-dns' }
    ],
    data:[
      [ 'AA9999995', 'Blog', 'running',  'axsh1.com/sssss/']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Cluster ID", width: 100, dataIndex: 'cluster-id' },
    { header: "Name", width: 100, dataIndex: 'name' },
    { header: "State", width: 50, dataIndex: 'state' },
    { header: "Public DNS", width: 100, dataIndex: 'public-dns' }
  ]);

  WakameGUI.ClusterList.superclass.constructor.call(this, {
    region: 'center',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    split: true,
    autoHeight: false,
    stripeRows: true,
    bbar: new Ext.PagingToolbar({
      pageSize: 1,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
    })
  });
}
Ext.extend(WakameGUI.ClusterList, Ext.grid.GridPanel);

WakameGUI.ClusterCtrl = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.SimpleStore({
    fields: [
      { name: 'app-name' },
      { name: 'state' },
      { name: 'now' },
      { name: 'future' },
      { name: 'setting' }
    ],
    data:[
      [ 'Apache', 'running', '2',  '2', ''],
      [ 'LB',     'running', '1',  '1', ''],
      [ 'MySQL',  'running', '1',  '1', '']
    ]
  });
  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Application", width: 100, dataIndex: 'app-name' },
    { header: "state", width: 100, dataIndex: 'state' },
    { header: "Now", width: 50, dataIndex: 'now' },
    { header: "Future", width: 50, dataIndex: 'future' },
    { header: "Setting", width: 50, dataIndex: 'setting' }
  ]);

  WakameGUI.ClusterCtrl.superclass.constructor.call(this, {
    region: 'east',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 380,
    split: true,
    autoHeight: true,
    stripeRows: true,
    tbar : [
      { text : 'Reboot',handler:function(){}
      },
      { text : 'Terminate',handler:function(){}
      },
      { text : 'Backup',handler:function(){}
      },
      { text : 'Restore',handler:function(){}
      }
    ]
  });
}
Ext.extend(WakameGUI.ClusterCtrl, Ext.grid.GridPanel);
