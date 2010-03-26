//
//  iWeb - HeaderControls.js
//  Copyright (c) 2007 Apple Inc. All rights reserved.
//

function HeaderControls(instanceID)
{if(instanceID!=null)
{Widget.apply(this,arguments);NotificationCenter.addObserver(this,HeaderControls.prototype.p_prevPage,"PreviousPage",this.p_mediaGridID());NotificationCenter.addObserver(this,HeaderControls.prototype.p_nextPage,"NextPage",this.p_mediaGridID());NotificationCenter.addObserver(this,HeaderControls.prototype.p_setPage,"SetPage",this.p_mediaGridID());this.mRange=new IWPageRange(0,5);this.p_updateRange();}}
HeaderControls.prototype=new Widget();HeaderControls.prototype.constructor=HeaderControls;HeaderControls.prototype.widgetIdentifier="com-apple-iweb-widget-headercontrols";HeaderControls.prototype.onload=function()
{var defaults={showBackToIndex:true,showAddPhoto:true,showSubscribe:true,showSlideshow:true,mediaIndex:false,entriesPerPage:99,entryCount:0};this.initializeDefaultPreferences(defaults);this.setPage(0);this.updateFromPreferences();if(this.preferences&&this.preferences.postNotification)
{this.preferences.postNotification("BLWidgetIsSafeToDrawNotification",1);}}
HeaderControls.prototype.onunload=function()
{}
HeaderControls.prototype.startup=function()
{this.p_updateCanvasControls();this.p_updateBackToIndex();this.p_updatePaginationControls();this.p_updateAddPhoto();this.p_updateSubscribe();this.p_updateSlideshow();if(this.p_mediaIndex())
{this.getElementById("media_index_only").show();}
else
{this.getElementById("album_only").show();}}
HeaderControls.prototype.changedPreferenceForKey=function(key)
{if(key=="entriesPerPage"||key=="entryCount"||key=="x-currentPage")
{this.p_updateRange();this.p_updatePaginationControls();}
else if(key=="showBackToIndex")
{this.p_updateBackToIndex();}
else if(key=="showAddPhoto")
{this.p_updateAddPhoto();}
else if(key=="showSubscribe")
{this.p_updateSubscribe();}
else if(key=="showSlideshow")
{this.p_updateSlideshow();}
else if(key=="canvas controls")
{this.p_updateCanvasControls();}
else if(this.runningInApp)
{if(key=="x-nextPage")
{this.nextPage();}
else if(key=="x-previousPage")
{this.prevPage();}
else if(key=="x-setPage")
{this.setPage(this.p_setPagePreference());}}}
HeaderControls.prototype.updateFromPreferences=function()
{this.startup();}
HeaderControls.prototype.prevPage=function()
{NotificationCenter.postNotification(new IWNotification("PreviousPage",this.p_mediaGridID(),null));}
HeaderControls.prototype.nextPage=function()
{NotificationCenter.postNotification(new IWNotification("NextPage",this.p_mediaGridID(),null));}
HeaderControls.prototype.setPage=function(pageIndex)
{NotificationCenter.postNotification(new IWNotification("SetPage",this.p_mediaGridID(),{pageIndex:pageIndex}));}
HeaderControls.prototype.playSlideshow=function()
{if(this.mPlaySlideshowFunction)
{this.mPlaySlideshowFunction();}}
HeaderControls.prototype.setPlaySlideshowFunction=function(playSlideshow)
{this.mPlaySlideshowFunction=playSlideshow;}
HeaderControls.prototype.p_canNavigateToPrev=function()
{return(this.p_currentPage()>0);}
HeaderControls.prototype.p_prevPage=function(notification)
{if(this.p_canNavigateToPrev())
{this.setPage(this.p_currentPage()-1);}}
HeaderControls.prototype.p_canNavigateToNext=function()
{return(this.p_currentPage()<this.p_pageCount()-1);}
HeaderControls.prototype.p_nextPage=function(notification)
{if(this.p_canNavigateToNext())
{this.setPage(this.p_currentPage()+1);}}
HeaderControls.prototype.p_setPage=function(notification)
{var pageIndex=notification.userInfo().pageIndex;this.setPreferenceForKey(pageIndex,"x-currentPage");if(!this.runningInApp)
{var entriesPerPage=this.p_entriesPerPage();var location=pageIndex*entriesPerPage;var length=Math.min(this.p_entryCount()-location,entriesPerPage);var userInfo={"range":new IWRange(location,length)};NotificationCenter.postNotification(new IWNotification("RangeChanged",this.p_mediaGridID(),userInfo));}}
HeaderControls.prototype.p_showBackToIndex=function()
{var show=this.preferenceForKey("showBackToIndex");(function(){return show!==undefined}).assert();return show;}
HeaderControls.prototype.p_showAddPhoto=function()
{var show=this.preferenceForKey("showAddPhoto");(function(){return show!==undefined}).assert();return show;}
HeaderControls.prototype.p_showSubscribe=function()
{var show=this.preferenceForKey("showSubscribe");(function(){return show!==undefined}).assert();return show;}
HeaderControls.prototype.p_showSlideshow=function()
{var show=this.preferenceForKey("showSlideshow");(function(){return show!==undefined}).assert();return show;}
HeaderControls.prototype.p_mediaGridID=function()
{var mediaGridID=null;if(this.preferences)
{mediaGridID=this.preferenceForKey("gridID");}
if(mediaGridID===undefined)
{mediaGridID=null;}
return mediaGridID;}
HeaderControls.prototype.p_setPagePreference=function()
{var setPagePreference=null;if(this.preferences)
{setPagePreference=this.preferenceForKey("x-setPage");}
if(setPagePreference===undefined)
{setPagePreference=null;}
return setPagePreference;}
HeaderControls.prototype.p_updatePaginationControls=function()
{var widgetDiv=this.div();var currentPage=this.p_currentPage();var controls="";if(this.p_isPaginated())
{var canvasControlURLs=this.preferenceForKey("canvas controls");if(this.p_canNavigateToPrev())
{var leftArrowSrc=canvasControlURLs['canvas_arrow-left'];controls+="<a href='javascript:#{WIDGET_ID}.prevPage()'>";controls+=imgMarkup(leftArrowSrc,'','','');controls+="</a> ";}
else
{var leftArrowSrc=canvasControlURLs['canvas_arrow-left-D'];controls+=imgMarkup(leftArrowSrc,'','','')+" ";}
for(var i=this.mRange.min();i<this.mRange.max();i++)
{if(i==currentPage)
{controls+="<span class='current_page'>"+(i+1)+"</span> ";}
else
{controls+="<a href='javascript:#{WIDGET_ID}.setPage("+i+")'>"+(i+1)+"</a> ";}}
if(this.p_canNavigateToNext())
{var rightArrowSrc=canvasControlURLs['canvas_arrow-right'];controls+="<a href='javascript:#{WIDGET_ID}.nextPage()'>";controls+=imgMarkup(rightArrowSrc,'','','');controls+="</a>";}
else
{var rightArrowSrc=canvasControlURLs['canvas_arrow-right-D'];controls+=imgMarkup(rightArrowSrc,'','','');}}
var template=new Template(controls);var myControls=template.evaluate({WIDGET_ID:this.instanceID});this.getElementById("pagination_controls").update(myControls);widgetDiv.select('.paginated_only').invoke(this.p_isPaginated()?'show':'hide');widgetDiv.select('.non_paginated_only').invoke(this.p_isPaginated()?'hide':'show');if(this.runningInApp)
{this.setPreferenceForKey(controls,"x-paginationSpanContents");}
else
{NotificationCenter.postNotification(new IWNotification("paginationSpanContents",this.p_mediaGridID(),{controls:controls}));}}
HeaderControls.prototype.p_setAnchorsUnderElementToHREF=function(element,href)
{var links=element.getElementsByTagName("a");for(var i=0;i<links.length;++i)
{links[i].href=href;}}
HeaderControls.prototype.p_updateCanvasControls=function()
{var canvasControlURLs=this.preferenceForKey("canvas controls");this.div().select('.canvas').each(function(img)
{var canvasControlName="canvas_"+img.classNames().toArray()[1];setImgSrc(img,canvasControlURLs[canvasControlName]);});}
HeaderControls.prototype.p_updateBackToIndex=function()
{var element=this.getElementById("back_to_index");this.p_showBackToIndex()?element.show():element.hide();if(!this.runningInApp)
{this.p_setAnchorsUnderElementToHREF(element,this.p_indexURL());}}
HeaderControls.prototype.p_updateAddPhoto=function()
{var element=this.getElementById("add_photo");this.p_showAddPhoto()?element.show():element.hide();if(!this.runningInApp)
{this.p_setAnchorsUnderElementToHREF(element,"javascript:(void)");}}
HeaderControls.prototype.p_updateSubscribe=function()
{this.div().select('.subscribe').invoke(this.p_showSubscribe()?'show':'hide');if(!this.runningInApp)
{var feedURL="javascript:"+this.instanceID+(this.p_mediaIndex()?".mediaIndexSubscribe()":".photocastSubscribe()")
var self=this;this.div().select('.subscribe').each(function(element)
{self.p_setAnchorsUnderElementToHREF(element,feedURL);});}}
HeaderControls.prototype.mediaIndexSubscribe=function()
{window.location=this.p_feedURL();}
HeaderControls.prototype.photocastSubscribe=function()
{photocastHelper(this.p_feedURL());}
HeaderControls.prototype.p_updateSlideshow=function()
{this.div().select('.play_slideshow').invoke(this.p_showSlideshow()?'show':'hide');}
HeaderControls.prototype.p_mediaIndex=function()
{var mediaIndex=null;if(this.preferences)
{mediaIndex=this.preferenceForKey("mediaIndex");}
if(mediaIndex===undefined)
{mediaIndex=false;}
return mediaIndex;}
HeaderControls.prototype.p_currentPage=function()
{var currentPage=0;if(this.preferences)
{currentPage=this.preferenceForKey("x-currentPage");}
if(!currentPage)
{currentPage=0;}
return currentPage;}
HeaderControls.prototype.p_entriesPerPage=function()
{var entriesPerPage=null;if(this.preferences)
{entriesPerPage=this.preferenceForKey("entriesPerPage");}
if(entriesPerPage==undefined)
{entriesPerPage=99;}
return entriesPerPage;}
HeaderControls.prototype.p_entryCount=function()
{var entryCount=null;if(this.preferences)
{entryCount=this.preferenceForKey("entryCount");}
if(entryCount==undefined)
{entryCount=0;}
return entryCount;}
HeaderControls.prototype.p_indexURL=function()
{return this.preferenceForKey("indexURL");}
HeaderControls.prototype.p_feedURL=function()
{return this.preferenceForKey("feedURL");}
HeaderControls.prototype.p_isPaginated=function()
{return(this.p_entryCount()>this.p_entriesPerPage());}
HeaderControls.prototype.p_pageCount=function()
{return Math.ceil(this.p_entryCount()/this.p_entriesPerPage());}
HeaderControls.prototype.p_updateRange=function()
{var pageCount=this.p_pageCount();var currentPage=this.p_currentPage();if(currentPage>=pageCount)
{currentPage=pageCount-1;this.setPreferenceForKey(currentPage,"x-currentPage");}
if(pageCount<=5||this.mRange.length()<3||this.mRange.max()>pageCount)
{this.mRange.setMax(Math.min(5,pageCount));}
if(currentPage<this.mRange.min())
{this.mRange.shift(currentPage-this.mRange.min());}
else if(currentPage>=this.mRange.max())
{this.mRange.shift(currentPage-this.mRange.max()+1);}}
