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
  Account:null,
  AccountList:null
});

WakameGUI.Account = function(){
  var alistPanel = new WakameGUI.AccountList();
  WakameGUI.Account.superclass.constructor.call(this, {
      split: true,
      header: false,
      border: false,
      layout: 'border',
  	  items: [alistPanel]
  });
  
  this.refresh = function(){
    alistPanel.refresh();
  }
}
Ext.extend(WakameGUI.Account, Ext.Panel);
  
WakameGUI.AccountList = function(){
    
    var sm = new Ext.grid.RowSelectionModel({singleSelect:true});
    var store = new Ext.data.Store({
        proxy: new Ext.data.HttpProxy({
          url: '/account-list',
          method:'GET'
        }),
        reader: new Ext.data.JsonReader({
          totalProperty: "totalCount",
          root:'rows',
          fields:[
            { name:'id' ,type:'string'},
            { name:'nm' ,type:'string'},
            { name:'en' ,type:'string'},
            { name:'rg' ,type:'string'},
            { name:'cn' ,type:'string'},
            { name:'mm' ,type:'string'}
          ]
        })
      });

    this.refresh = function(){
      store.reload();
    };

    var searchView = function(data){
      store.loadData(data);
    };
      
    var schWin = null;    
    var clmnModel = new Ext.grid.ColumnModel([
        new Ext.grid.RowNumberer(),
        { header: "Account-ID"    , width: 120, dataIndex: 'id' , hideable:false, menuDisabled:true },
        { header: "Account-Name"  , width: 120, dataIndex: 'nm' , sortable: true },
        { header: "Useful"        , width: 60,  dataIndex: 'en' },
        { header: "Registered"    , width: 80,  dataIndex: 'rg' , sortable: true},
        { header: "Contract-Date" , width: 80,  dataIndex: 'cn' , sortable: true },
        { header: "Memo"          , width: 300, dataIndex: 'mm' }
      ]);
      
    WakameGUI.AccountList.superclass.constructor.call(this, {
      region: "center",
      store:store,
      cm:clmnModel,
      sm:sm,
      title: "Account Management",
      width: 320,
      autoHeight: false,
      stripeRows: true,
      loadMask: {msg: 'Loading...'},
      bbar: new Ext.PagingToolbar({
        pageSize: 50,
        store: store,
        displayInfo: true,
        displayMsg: 'Displaying data {0} - {1} of {2}',
        emptyMsg: "No data to display"
      }),
      tbar : [
        { iconCls: 'addUser',
          text : 'Add',handler:function(){
            var addWin = new AddAccountWindow();
    		  addWin.show();
          }
        },'-',
        { iconCls: 'removeUser',
          text : 'Remove', handler:function(){
    		  if(sm.getCount() <= 0)
              return;
            Ext.Ajax.request({
    	        url: '/account-remove',
    	        method: "POST", 
              params : 'id=' + sm.getSelected().id,
              success: function(form, action) {
                store.reload();
              }
    	      });
          }
        },'-',
        { iconCls: 'editUser',
          text : 'Edit',handler:function(){
    		  var temp = sm.getCount();
    		  if(temp > 0){
              var data = sm.getSelected();
    			var editWin = new EditAccountWindow(data);
    			editWin.show();
            }
          }
        },'-',
        { iconCls: 'findUser',
          text : 'Search',handler:function(){
            if(schWin == null){
              schWin = new SearchAccountWindow();
            }
    		  schWin.show();
          }
        }
      ]
    });  
  store.load({params: {start: 0, limit: 50}});       // limit = page size
  AddAccountWindow = function(){
    var form = new Ext.form.FormPanel({
      labelWidth: 120, 
      width: 400, 
      baseCls: 'x-plain',
      items: [
      {
      fieldLabel: 'Account-Name',
      xtype: 'textfield',
      id: 'nm',
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Useful',
      xtype: 'radiogroup',
      defaultType: "radio", 
      anchor: '100%',
	  items: [{
        name: "en", 
	    inputValue: "true", 
	      boxLabel: "enable", 
	      checked: true 
	    },
	    {
	      name: "en", 
	      inputValue: "false", 
	      boxLabel: "disable" 
	    }]
      }
      ,{
      fieldLabel: 'Contract-Date',
      xtype: 'datefield',
      format: 'Y/m/d',
      id: 'cn',
      anchor: '100%'
      }
      ,{
      fieldLabel: 'Memo',
      xtype: 'textarea',
      id: 'mm',
      anchor: '100%'
      }]
    });
    AddAccountWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      collapsible:true,
      titleCollapse:true,
      width: 500,
      height: 250,
	  layout:'fit',
	  closeAction:'hide',
      title: 'Add Account',
	  modal: true,
	  plain: true,
      defaults:{bodyStyle:'padding:15px'},
	  items: [form],
	  buttons: [{
	  text:'Create',
      handler: function(){
        form.getForm().submit({
          url: '/account-create',
          waitMsg: 'Adding...',
          method: 'POST',
          scope: this,
          success: function(form, action) {
            refresh();
	        this.close();
          },
          failure: function(form, action) {
            alert('Add account failure.');
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
  Ext.extend(AddAccountWindow, Ext.Window);

  EditAccountWindow = function(accountData){
    var form = new Ext.form.FormPanel({
      labelWidth: 120,
      width: 400,
      baseCls: 'x-plain',
      items: [
        {
        fieldLabel: 'Account-ID',
        xtype: 'displayfield',
        value: accountData.get('id'),
        anchor: '100%'
        }
        ,{
        xtype: 'hidden',
        id: 'id',
        value: accountData.get('id'),
        }
        ,{
        fieldLabel: 'Account-Name',
        xtype: 'textfield',
        name: 'nm',
        value: accountData.get('nm'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Useful',
        xtype: 'radiogroup',
        defaultType: "radio", 
        anchor: '100%',
	      items: [{
            name: "en", 
	        inputValue: "true", 
	        boxLabel: "enable",
            checked: accountData.get('en') == "true"
	      },
	      {
	        name: "en", 
	        inputValue: "false", 
	        boxLabel: "disable",
            checked: accountData.get('en') == "false"
	      }]
        }
        ,{
        fieldLabel: 'Contract-Date',
        xtype: 'textfield',
        name: "cn",
        value: accountData.get('cn'),
        anchor: '100%'
        }
        ,{
        fieldLabel: 'Memo',
        xtype: 'textarea',
        name: "mm",
        value: accountData.get('mm'),
        anchor: '100%'
        }
      ]
    });
    EditAccountWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      collapsible:true,
      titleCollapse:true,
      width: 500,
      height: 250,
      layout:'fit',
      title: 'Edit Account',
      modal: true,
      plain: true,
      defaults:{bodyStyle:'padding:15px'},
      items: [form],
      buttons: [{
        text:'Save',
        handler: function(){
          form.getForm().submit({
            url: '/account-save',
            waitMsg: 'Saveing...',
            method: 'POST',
            scope: this,
            success: function(form, action) {
              refresh();
	          this.close();
            },
            failure: function(form, action) {
              alert('Add account failure.');
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
  Ext.extend(EditAccountWindow, Ext.Window);

  SearchAccountWindow = function(){
    var form = new Ext.form.FormPanel({
      frame:true,
      bodyStyle:'padding:5px 5px 0',
      items:[{
        layout: 'form',
        items: [{
          fieldLabel: '<span ext:qtitle="Account-ID" ext:qwidth=200 ext:qtip="Input Account ID. (exact)">Account-ID</span>',
          xtype: 'textfield',
          id: 'id',
          anchor: '100%'
        },{
          fieldLabel: '<span ext:qtitle="Account-Name" ext:qwidth=200 ext:qtip="Input Account Name. (include)">Account-Name</span>',
          xtype: 'textfield',
          id: 'nm',
          anchor: '100%'
        },{
          fieldLabel: 'Useful',
          xtype: 'radiogroup',
          defaultType: "radio", 
          anchor: '100%',
	      items: [{
            name: "en", 
	        inputValue: 0, 
	        boxLabel: "non",
            checked: true
	      },
	      {
	        name: "en",
	        inputValue: 1,
	        boxLabel: "enable"
	      },
	      {
	        name: "en",
	        inputValue: 2, 
	        boxLabel: "disable"
	      }]
        },{
          fieldLabel: 'Contract-Date',
          xtype: 'datefield',
          id: 'cn',
          anchor: '100%',
          format: 'Y/m/d'
        }]
      }]
    });
    SearchAccountWindow.superclass.constructor.call(this, {
      iconCls: 'icon-panel',
      height: 200,
      width: 350,
      layout:'fit',
      title: 'Search Account',
      items: [form],
      buttons: [{
        text:'Reset',
        handler: function(){
          form.getForm().reset();
	    },
		scope:this
      },{
        text:'OK',
        handler: function(){
          form.getForm().submit({
            url: '/account-search',
            waitMsg: 'Searching...',
            method: 'POST',
            scope: this,
            success: function(form, action) {
              jsonRes = Ext.util.JSON.decode(action.response.responseText);
              searchView(jsonRes);
			  this.hide();
            },
            failure: function(form, action) {
              alert('Add account failure.');
			  this.hide();
            }
          });
	    },
        scope:this
      },{
        text: 'Cancel',
		handler: function(){
		  this.hide();
		},
		scope:this
      }]
    });
  }
  Ext.extend(SearchAccountWindow, Ext.Window);
}
Ext.extend(WakameGUI.AccountList, Ext.grid.GridPanel);
