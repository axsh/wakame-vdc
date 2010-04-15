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

// Global Resource
WakameGUI = {
  version : '1.0'
};

Ext.apply(WakameGUI,{
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
  },
  formsFailureBox: function(form){
     if(!form.isValid()){
      Ext.Msg.show({ 
              icon: Ext.Msg.WARNING,
              title: 'Bad Request', 
              msg: 'Please confirm the input value' 
          });
     }else{
       Ext.Msg.show({ 
               icon: Ext.Msg.ERROR,
               title: 'Bad Request', 
               msg: 'Sysytem Error' 
           });
     }
  },changePanel: function(mainPanel,changePanelName,no){
     if(WakameGUI.activePanel != no){
       WakameGUI.activePanel = no;
       mainPanel.layout.setActiveItem(WakameGUI.activePanel);
       mainPanel.refreshPanel(changePanelName);
     }
   }
});
