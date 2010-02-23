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
  Instance:null
});

WakameGUI.Instance = function(){
  var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
  var store = new Ext.data.Store({
    proxy: new Ext.data.HttpProxy({
      url: '/instance-list',
      method:'GET'
    }),
    reader: new Ext.data.JsonReader({
      totalProperty: "totalCount",
      root:'rows',
      fields:[
        { name:'id' ,type:'string'},
        { name:'od' ,type:'string'},
        { name:'wd' ,type:'string'},
        { name:'st' ,type:'string'},
//      { name:'pub-dns' ,type:'string'},
//      { name:'pri-dns' ,type:'string'},
        { name:'ip' ,type:'string'},
        { name:'tp' ,type:'string'}
//      { name:'sv' ,type:'string'}
      ]
    })
  });

  function statusChange(val){
    if(val == "pending"){
      return '<span style="color:#FF9000;">' + val + '</span>';
    } else if(val == "running"){
      return '<span style="color:#4FFF00;">' + val + '</span>';
    } else {
      return '<span style="color:gray;">' + val + '</span>';
    }
    return val;
  }

  var clmnModel = new Ext.grid.ColumnModel([
    new Ext.grid.RowNumberer(),
    { header: "Instance ID" ,width: 100, dataIndex: 'id'},
    { header: "Owner"       ,width: 100, dataIndex: 'od'},
    { header: "WMI ID"      ,width: 100, dataIndex: 'wd'},
    { header: "State"       ,width: 80,  dataIndex: 'st' , renderer: statusChange},
//  { header: "Public DNS"  ,width: 100, dataIndex: 'pub-dns'},
//  { header: "Private DNS" ,width: 100, dataIndex: 'pri-dns'},
    { header: "Private IP"  ,width: 100, dataIndex: 'ip'},
    { header: "type"        ,width: 50,  dataIndex: 'tp'}
//  { header: "Service"     ,width: 100, dataIndex: 'sv'}
  ]);

  this.refresh = function(){
    store.reload();
  }

  function reqeustSuccess()
  {
    store.reload();
  }

  function  reqeustfailure()
  {
    alert('Request failure.');
  }

  var toolbar= new Ext.PagingToolbar({
      pageSize: 50,
      store: store,
      displayInfo: true,
      displayMsg: 'Displaying data {0} - {1} of {2}',
      emptyMsg: "No data to display"
  });

  WakameGUI.Instance.superclass.constructor.call(this, {
    title: 'Instance',
    store: store,
    cm:clmnModel,
    sm:sm,
    width: 320,
    autoHeight: false,
    stripeRows: true,
    bbar: toolbar,
    tbar : [
      { text : 'Reboot',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-reboot',
	        method: "POST", 
            params : 'id=' + sm.getSelected().data['id'],
            success: reqeustSuccess,
            failure: reqeustfailure
	      }); 
        }
      },
      { text : 'Terminate',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          if(sm.getSelected().data['st'] != "running")
            return;
          Ext.Msg.confirm("Terminate:","Are you share?", function(btn){
            if(btn == 'yes'){
              Ext.Ajax.request({
	            url: '/instance-terminate',
	            method: "POST",
                params : 'id=' + sm.getSelected().data['id'],
                success: reqeustSuccess,
                failure: reqeustfailure
	          });
            }
          });
        }
      },
      { text : 'Save',handler:function(){
		  if(sm.getCount() <= 0)
            return;
          Ext.Ajax.request({
	        url: '/instance-save',
	        method: "POST", 
            params : 'id=' + sm.getSelected().data['id'],
            success: reqeustSuccess,
            failure: reqeustfailure
	      }); 
        }
      }
    ]
  });
  Ext.TaskMgr.start({
    run: function(){
      if(WakameGUI.activePanel == 0){
        store.reload();
      }
    },
    interval: 60000
  });
}
Ext.extend(WakameGUI.Instance, Ext.grid.GridPanel);
