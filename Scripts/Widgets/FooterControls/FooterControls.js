//
//  iWeb - FooterControls.js
//  Copyright (c) 2007 Apple Inc. All rights reserved.
//

function FooterControls(instanceID)
{if(instanceID!=null)
{Widget.apply(this,arguments);NotificationCenter.addObserver(this,FooterControls.prototype.p_handlePaginationContentsNotification,"paginationSpanContents",this.p_mediaGridID());this.updateFromPreferences();}}
FooterControls.prototype=new Widget();FooterControls.prototype.constructor=FooterControls;FooterControls.prototype.widgetIdentifier="com-apple-iweb-widget-footercontrols";FooterControls.prototype.onload=function()
{if(this.preferences&&this.preferences.postNotification)
{this.preferences.postNotification("BLWidgetIsSafeToDrawNotification",1);}}
FooterControls.prototype.onunload=function()
{}
FooterControls.prototype.updateFromPreferences=function()
{this.setPage(0);}
FooterControls.prototype.changedPreferenceForKey=function(key)
{if(this.runningInApp)
{if(key=="x-paginationSpanContents")
{this.p_setPaginationControls(this.p_paginationSpanContents());}}}
FooterControls.prototype.prevPage=function()
{if(this.runningInApp)
{this.setPreferenceForKey(null,"x-previousPage");}
else
{NotificationCenter.postNotification(new IWNotification("PreviousPage",this.p_mediaGridID(),null));}}
FooterControls.prototype.nextPage=function()
{if(this.runningInApp)
{this.setPreferenceForKey(null,"x-nextPage");}
else
{NotificationCenter.postNotification(new IWNotification("NextPage",this.p_mediaGridID(),null));}}
FooterControls.prototype.setPage=function(pageIndex)
{if(this.runningInApp)
{this.setPreferenceForKey(pageIndex,"x-setPage");}
else
{NotificationCenter.postNotification(new IWNotification("SetPage",this.p_mediaGridID(),{pageIndex:pageIndex}));}}
FooterControls.prototype.p_mediaGridID=function()
{var mediaGridID=null;if(this.preferences)
{mediaGridID=this.preferenceForKey("gridID");}
if(mediaGridID===undefined)
{mediaGridID=null;}
return mediaGridID;}
FooterControls.prototype.p_paginationSpanContents=function()
{var paginationSpanContents=null;if(this.preferences)
{paginationSpanContents=this.preferenceForKey("x-paginationSpanContents");}
if(paginationSpanContents===undefined)
{paginationSpanContents=null;}
return paginationSpanContents;}
FooterControls.prototype.p_handlePaginationContentsNotification=function(notification)
{var userInfo=notification.userInfo();var controls=userInfo.controls||"";this.p_setPaginationControls(controls);}
FooterControls.prototype.p_setPaginationControls=function(controls)
{var template=new Template(controls);var myControls=template.evaluate({WIDGET_ID:this.instanceID});this.getElementById("pagination_controls").update(myControls);}
