//
//  iWeb - DetailView.js
//  Copyright (c) 2007 Apple Inc. All rights reserved.
//

var DetailViewToggleNotification="DetailViewToggleNotification";function DetailView(instanceID)
{if(instanceID!=null)
{Widget.apply(this,arguments);this.mIsActive=false;this.mShowingThumbnails=false;this.needsHeightSet=true;this.p_setHeight();this.updateFromPreferences();if(this.runningInApp)
{this.postToggleNotification(true);}}}
DetailView.prototype=new Widget();DetailView.prototype.constructor=DetailView;DetailView.prototype.widgetIdentifier="com-apple-iweb-widget-detailview";DetailView.prototype.onload=function()
{this.p_updateSlideshow();this.p_updateDownloadVisibility();this.p_addEvent(document,'onkeydown',this.p_keyDown.bind(this),true);this.p_addEvent(document,'onkeyup',this.p_keyUp.bind(this),true);this.div().select('.noselect').each(function(element)
{if(windowsInternetExplorer)
{element.onselectstart=function(){return false;};}
else
{element.onmousedown=function(){return false;};}});}
DetailView.prototype.onunload=function()
{}
DetailView.prototype.loadFromStream=function(mediaStream)
{if(mediaStream)
{mediaStream.load(this.p_baseURL(),this.onStreamLoad.bind(this));}}
DetailView.prototype.onStreamLoad=function(imageStream)
{this.mCurrentMediaStream=imageStream;this.mThumbnailsInvalid=true;var slideshowDiv=this.getElementById("slideshow_placeholder");var slideshowAnchor=this.getElementById("slideshow_anchor");if(this.mSlideshow!=null)
{this.mSlideshow.pause();slideshowDiv.innerHTML="";}
var photos=[];for(var i=0;i<imageStream.length;++i)
{photos.push(imageStream[i].slideshowValue("image"));}
var options={backgroundColor:this.p_backgroundColor(),scaleMode:this.p_scaleMode(),advanceAnchor:slideshowAnchor};this.mSlideshow=new Slideshow(slideshowDiv,photos,this.p_onPhotoChange.bind(this),options);this.mSlideshow.setTransitionIndex(1);this.mSlideshow.pause();if(this.preferences)
{var movieOverlayURL=this.preferenceForKey("movie overlay");if(movieOverlayURL&&IWImageNamed("movie overlay")===null)
{IWRegisterNamedImage("movie overlay",movieOverlayURL);}}
if(this.runningInApp)
{this.p_updateCanvasControls();this.p_setupThumbnails();this.mSlideshow.showPhotoNumber(this.p_startIndex());var captionDiv=this.div().selectFirst('.Caption');captionDiv.innerHTML="&#160;";captionDiv.id="caption";}}
DetailView.prototype.downloadPhoto=function()
{var currentIndex=this.mSlideshow.currentPhotoNumber;var currentEntry=this.mCurrentMediaStream[currentIndex];var targetURL=currentEntry.targetURL();targetURL+=(targetURL.indexOf('?')==-1)?'?':'&';targetURL+='disposition=download';window.location.href=targetURL;}
DetailView.prototype.toggleThumbnails=function()
{var show=this.mShowingThumbnails==false;this.p_toggleThumbnails(show,true);this.setPreferenceForKey(show,"showThumbnails");}
DetailView.prototype.willShow=function(index)
{if(!this.mCanvasControlsSetUp)
{this.mCanvasControlsSetUp=true;this.p_updateCanvasControls();}
this.p_setupThumbnails();if(this.needsHeightSet)
{this.p_setHeight();}
else if(this.mSlideshow)
{this.mSlideshow.updateSize();}
this.p_updateThumbScrollers(index);}
DetailView.prototype.showPhotoNumber=function(index,callback)
{this.mIsActive=true;this.photoChangeCallback=callback;this.mSlideshow.showPhotoNumber(index);}
DetailView.prototype.height=function()
{return this.getElementById("middle").offsetHeight;}
DetailView.prototype.postToggleNotification=function(isVisible)
{this.mIsActive=isVisible;var userInfo={showDetailView:isVisible};if(this.mSlideshow)
{userInfo["index"]=this.mSlideshow.currentPhotoNumber;}
if(this.runningInApp)
{this.preferences.postCrossWidgetNotification("IWCommentTargetChanged",{});this.setPreferenceForKey(isVisible,"inDetailView");}
else
{NotificationCenter.postNotification(new IWNotification("IWCommentTargetChanged",null,{}));var gridID=this.preferenceForKey("gridID");NotificationCenter.postNotification(new IWNotification(DetailViewToggleNotification,gridID,userInfo));}}
DetailView.prototype.exitDetailView=function()
{this.mIsActive=false;if(this.mSlideshow)
{this.mSlideshow.inactivate();}
this.postToggleNotification(false);}
DetailView.prototype.playSlideshow=function()
{if(this.mPlaySlideshowFunction)
{this.mPlaySlideshowFunction();}}
DetailView.prototype.setPlaySlideshowFunction=function(playSlideshow)
{this.mPlaySlideshowFunction=playSlideshow;}
DetailView.prototype.p_setHeight=function()
{if(this.needsHeightSet)
{var slideshowDiv=this.getElementById("slideshow_placeholder");var width=slideshowDiv.offsetWidth;if(width>0)
{var height=width*3/4+"px";if(height!=parseFloat(slideshowDiv.style.height))
{slideshowDiv.parentNode.style.height=height;slideshowDiv.style.height=height;if(this.mSlideshow)
{this.mSlideshow.updateSize();}
this.needsHeightSet=false;if(this.runningInApp&&!window.onresize)
{window.onresize=function()
{this.needsHeightSet=true;this.p_setHeight();}.bind(this);}}}
this.div().style.height='';var detailFooterDiv=this.getElementById("footer_controls");var gridID=this.preferenceForKey("gridID");var divTop=Position.cumulativeOffset(detailFooterDiv)[1]+detailFooterDiv.offsetHeight;if(divTop)
{NotificationCenter.postNotificationWithInfo("DetailViewHeightNotification",gridID,{"top":divTop});}}}
DetailView.prototype.p_setupThumbnails=function()
{if(this.p_showThumbnails())
{if(!this.mShowingThumbnails)
{this.p_toggleThumbnails(true,false);}}
else
{this.p_buildThumbnailView();}}
DetailView.prototype.p_toggleThumbnails=function(show,animate)
{if(this.mShowingThumbnails!=show)
{var thumbnailView=this.getElementById("thumbnail_view");var back=this.getElementById("thumbnails_back");var forward=this.getElementById("thumbnails_forward");var viewSpan=this.getElementById("view");var thumbsOnOnly=viewSpan.select('.thumbs_on_only');var thumbsOffOnly=viewSpan.select('.thumbs_off_only');var thumbnailViewFullHeight=59;if(show)
{this.mShowingThumbnails=true;if(animate)
{var animation=new SimpleAnimation(function(){});animation.duration=300;animation.pre=function()
{back.style.opacity=forward.style.opacity=0.0;back.style.visibility=forward.style.visibility="visible";thumbnailView.show();}
animation.post=function()
{thumbnailView.style.height=px(thumbnailViewFullHeight);back.style.opacity=forward.style.opacity=1.0;}
animation.update=function(now)
{thumbnailView.style.height=px(thumbnailViewFullHeight*now);back.style.opacity=forward.style.opacity=now;}
animation.start();}
else
{back.style.visibility=forward.style.visibility="visible";back.style.opacity=forward.style.opacity=1.0;thumbnailView.style.height=px(thumbnailViewFullHeight);thumbnailView.show();}
for(var i=0;i<thumbsOnOnly.length;++i)
{thumbsOnOnly[i].style.display="inline";}
for(i=0;i<thumbsOffOnly.length;++i)
{thumbsOffOnly[i].style.display="none";}
this.p_buildThumbnailView();}
else
{this.mShowingThumbnails=false;for(var i=0;i<thumbsOnOnly.length;++i)
{thumbsOnOnly[i].style.display="none";}
for(i=0;i<thumbsOffOnly.length;++i)
{thumbsOffOnly[i].style.display="inline";}
if(animate)
{var animation=new SimpleAnimation(function(){});animation.duration=300;animation.pre=function()
{}
animation.post=function()
{thumbnailView.style.height=px(1);back.style.visibility=forward.style.visibility="hidden";thumbnailView.hide();}
animation.update=function(now)
{thumbnailView.style.height=px(Math.max(1,thumbnailViewFullHeight*(1.0-now)));back.style.opacity=forward.style.opacity=1.0-now;}
animation.start();}
else
{thumbnailView.style.height=px(1);back.style.visibility=forward.style.visibility="hidden";thumbnailView.hide();}}}}
DetailView.prototype.p_setThumbnail=function(img,thumbnail)
{var thumbnailSize=56;thumbnail.load(function(img,thumbnail)
{img.src=thumbnail.sourceURL();var size=thumbnail.naturalSize();var shorterDimension=Math.min(size.width,size.height);var scale=thumbnailSize/shorterDimension;var width=scale*size.width;var height=scale*size.height;img.style.position="absolute";img.style.left=(thumbnailSize-width)/2+"px";img.style.top=(thumbnailSize-height)/2+"px";img.style.width=width+"px";img.style.height=height+"px";thumbnail.unload();}.bind(null,img,thumbnail));}
DetailView.prototype.p_buildThumbnailView=function()
{if(this.mThumbnailsInvalid)
{var thumbnailView=this.getElementById("thumbnail_view");var back=this.getElementById("thumbnails_back");var forward=this.getElementById("thumbnails_forward");this.mThumbnailsInvalid=false;var thumbnailsDiv=this.getElementById("thumbnails");var thumbnailSize=56;var thumbnailPadding=3;var currentIndex=this.preferenceForKey("currentPhoto")||0;for(var i=0;i<this.mCurrentMediaStream.length;++i)
{var anchor=document.createElement("a");var container=document.createElement("div");container.className="thumbnail";container.style.position="absolute";container.style.top="0px";container.style.left=i*(thumbnailSize+thumbnailPadding)+"px";detectBrowser();if(windowsInternetExplorer&&(browserVersion<7))
{container.style.width=thumbnailSize+"px";container.style.height=thumbnailSize+"px";}
if(i==currentIndex)
{$(container).addClassName("selected");}
var entry=this.mCurrentMediaStream[i];var badgeMarkup=IWStreamEntryBadgeMarkup(new IWRect(0,0,thumbnailSize,thumbnailSize),entry.isMovie(),false,null);if(badgeMarkup&&badgeMarkup.length>0)
{container.innerHTML=badgeMarkup;}
var img=document.createElement("img");var thumbnail=entry.micro();this.p_setThumbnail(img,thumbnail);anchor.href="#"+i;anchor.onclick=function(i,slideshow){setTimeout(slideshow.showPhotoNumber.bind(slideshow,i,true),0);}.bind(null,i,this.mSlideshow);anchor.appendChild(img);container.insertBefore(anchor,container.firstChild);thumbnailsDiv.appendChild(container);}
this.p_updateThumbScrollers(currentIndex);back.onclick=function()
{var thumbnailsDiv=this.getElementById("thumbnails");var left=0;if(thumbnailsDiv.style.left)
{left=-parseFloat(thumbnailsDiv.style.left);}
if(left>0)
{var tileWidth=(thumbnailSize+thumbnailPadding);var nThumbs=Math.floor(thumbnailsDiv.parentNode.offsetWidth/tileWidth);this.p_setThumbnailLeft(Math.max(left-nThumbs*tileWidth,0));}}.bind(this);forward.onclick=function()
{var thumbnailsDiv=this.getElementById("thumbnails");var left=0;if(thumbnailsDiv.style.left)
{left=-parseFloat(thumbnailsDiv.style.left);}
if(this.p_enableForward(thumbnailsDiv))
{var tileWidth=thumbnailSize+thumbnailPadding;var parentWidth=thumbnailsDiv.parentNode.offsetWidth;var nThumbs=Math.floor(parentWidth/tileWidth);this.p_setThumbnailLeft(Math.min(left+nThumbs*tileWidth,this.p_lastThumnbailRight()-parentWidth));}}.bind(this);}}
DetailView.prototype.p_updateThumbScrollers=function(index)
{var thumbnailsDiv=this.getElementById("thumbnails");var back=this.getElementById("thumbnails_back");var forward=this.getElementById("thumbnails_forward");if(index!==undefined)
{var selected=thumbnailsDiv.select('.thumbnail')[index];if(selected)
{this.p_ensureThumbnailIsVisible(selected);}}
var left=parseFloat(thumbnailsDiv.style.left);var imgs=back.getElementsByTagName("img");if(left<0)
{imgs[0].style.display="none";imgs[1].style.display="inline";}
else
{imgs[0].style.display="inline";imgs[1].style.display="none";}
var imgs=forward.getElementsByTagName("img");if(this.p_enableForward(thumbnailsDiv))
{imgs[0].style.display="none";imgs[1].style.display="inline";}
else
{imgs[0].style.display="inline";imgs[1].style.display="none";}}
DetailView.prototype.p_enableForward=function(thumbnailsDiv)
{var enableForward=false;var thumbnails=thumbnailsDiv.select('.thumbnail');if(thumbnails&&thumbnails.length>0)
{var lastThumbnail=thumbnails[thumbnails.length-1];var left=0;if(thumbnailsDiv.style.left)
{left=parseFloat(thumbnailsDiv.style.left);}
var panWidth=thumbnailsDiv.parentNode.offsetWidth;var right=panWidth-left;if(lastThumbnail.offsetLeft+lastThumbnail.offsetWidth>right)
{enableForward=true;}}
return enableForward;}
DetailView.prototype.p_showSlideshow=function()
{var show=this.preferenceForKey("showSlideshow");(function(){return show!==undefined}).assert();return show;}
DetailView.prototype.p_updateSlideshow=function()
{this.div().select('.play_slideshow').invoke(this.p_showSlideshow()?'show':'hide');}
DetailView.prototype.p_showDownload=function()
{var kDoNotDownloadImageSize=4;var photoSize=this.preferenceForKey("photoSize");var show=(photoSize==null||photoSize!=kDoNotDownloadImageSize);return show;}
DetailView.prototype.p_updateDownloadVisibility=function()
{this.getElementById("download").style.visibility=(this.p_showDownload()?'visible':'hidden');}
DetailView.prototype.changedPreferenceForKey=function(key)
{if(key=="mediaStream"||key=="mediaStreamObject")
{var mediaStream=this.p_mediaStream();if(mediaStream!==null)
{this.loadFromStream(mediaStream);}}
else if(key=="captionHeight")
{var captionDiv=this.div().selectFirst('.Caption');captionDiv.style.height=this.preferenceForKey("captionHeight")+"px";}
else if(key=="movieTime")
{this.mSlideshow.setMovieTime(this.preferenceForKey(key));}
else if(key=="movieParams")
{var params=this.preferenceForKey(key);this.mCurrentMediaStream[this.mSlideshow.currentPhotoNumber].setMovieParams(params);this.mSlideshow.setMovieParams(params);}
else if(key=="canvas controls")
{this.p_updateCanvasControls();}
else if(key=="currentImageURL")
{var entry=this.mCurrentMediaStream[this.mSlideshow.currentPhotoNumber];entry.setImageURL(this.preferenceForKey(key));this.mSlideshow.setImage(entry.image());}
else if(key=="currentThumbnailURL")
{var entry=this.mCurrentMediaStream[this.mSlideshow.currentPhotoNumber];var currentThumbnailURL=this.preferenceForKey(key);entry.setThumbnailURL(currentThumbnailURL);if(this.mThumbnailsInvalid==false)
{var thumbnailsDiv=this.getElementById("thumbnails");var selectedThumbContainer=thumbnailsDiv.selectFirst('.selected');var img=selectedThumbContainer.getElementsByTagName("img")[0];this.p_setThumbnail(img,entry.thumbnail());}}
else if(key=="showSlideshow")
{this.p_updateSlideshow();}
else if(key=="photoSize")
{this.p_updateDownloadVisibility();}}
DetailView.prototype.updateFromPreferences=function()
{var mediaStream=this.p_mediaStream();this.loadFromStream(mediaStream);}
DetailView.prototype.p_updateCanvasControls=function()
{var canvasControlURLs=this.preferenceForKey("canvas controls");this.div().select('.canvas').each(function(img)
{var canvasControlName="canvas_"+img.classNames().toArray()[1];setImgSrc(img,canvasControlURLs[canvasControlName]);});}
DetailView.prototype.p_onPhotoChange=function(index)
{var currentEntry=this.mCurrentMediaStream[index];var commentURL=currentEntry.commentAssetURL();if(this.runningInApp)
{commentURL="iweb-widget:Comments/"+currentEntry.guid();this.preferences.postCrossWidgetNotification("IWCommentTargetChanged",{IWResourceURL:commentURL});}
else
{if(this.mIsActive)
{NotificationCenter.postNotification(new IWNotification("IWCommentTargetChanged",null,{IWResourceURL:commentURL}));}
var captionDiv=this.div().selectFirst('.Caption');if(captionDiv)
{captionDiv.update(currentEntry.title());}}
var thumbnailsDiv=this.getElementById("thumbnails");var oldSelected=thumbnailsDiv.selectFirst('.selected');if(oldSelected)
{oldSelected.removeClassName("selected");}
var newSelected=thumbnailsDiv.select('.thumbnail')[index];if(newSelected)
{newSelected.addClassName("selected");this.p_ensureThumbnailIsVisible(newSelected);}
this.p_updatePreviousNextControls(index);this.setPreferenceForKey(index,"currentPhoto");if(this.photoChangeCallback)
{this.photoChangeCallback();this.photoChangeCallback=null;}}
DetailView.prototype.p_lastThumnbailRight=function()
{var thumbnailsDiv=this.getElementById("thumbnails");var thumbnails=thumbnailsDiv.select('.thumbnail');var lastThumbnail=thumbnails[thumbnails.length-1];var lastThumbnailRight=lastThumbnail.offsetLeft+lastThumbnail.offsetWidth;return lastThumbnailRight;}
DetailView.prototype.p_ensureThumbnailIsVisible=function(thumbnail)
{var thumbnailsDiv=this.getElementById("thumbnails");var startLeft=0;if(thumbnailsDiv.style.left)
{startLeft=parseFloat(thumbnailsDiv.style.left);}
var visibleArea=new IWRange(-startLeft,thumbnailsDiv.parentNode.offsetWidth);var thumbnailLeft=thumbnail.offsetLeft;var thumbnailRight=thumbnailLeft+thumbnail.offsetWidth;var targetLeft=visibleArea.location();if(thumbnailRight>visibleArea.max())
{var targetLeft=thumbnailLeft;targetLeft=Math.min(targetLeft,this.p_lastThumnbailRight()-visibleArea.length());}
else if(thumbnailLeft<visibleArea.location())
{var targetLeft=thumbnailRight-visibleArea.length();targetLeft=Math.max(targetLeft,0);}
this.p_setThumbnailLeft(targetLeft);}
DetailView.prototype.p_setThumbnailLeft=function(targetLeft)
{var thumbnailsDiv=this.getElementById("thumbnails");var startLeft=0;if(thumbnailsDiv.style.left)
{startLeft=parseFloat(thumbnailsDiv.style.left);}
var deltaLeft=-startLeft-targetLeft;if(deltaLeft!=0)
{var animation=new SimpleAnimation(function(){});animation.pre=function()
{}
animation.post=function()
{thumbnailsDiv.style.left=startLeft+deltaLeft+"px";this.p_updateThumbScrollers();}.bind(this);animation.update=function(now)
{thumbnailsDiv.style.left=startLeft+deltaLeft*now+"px";}
animation.start();}}
DetailView.prototype.p_updatePreviousNextControls=function(index)
{var previousSpans=this.getElementById("previous").getElementsByTagName("span");var nextSpans=this.getElementById("next").getElementsByTagName("span");var atFirstImage=index==0;var atLastImage=index>=this.mCurrentMediaStream.length-1;var navigationClickHandler=function(i,slideshow)
{setTimeout(slideshow.showPhotoNumber.bind(slideshow,i,true),0);}
if(atFirstImage)
{$(previousSpans[0]).show();$(previousSpans[1]).hide();}
else
{var previousIndex=index-1;$(previousSpans[0]).hide();$(previousSpans[1]).show();var anchors=$(previousSpans[1]).getElementsByTagName('a');$A(anchors).each(function(anchor){anchor.href='#'+previousIndex;anchor.onclick=navigationClickHandler.bind(null,previousIndex,this.mSlideshow);}.bind(this));}
if(atLastImage)
{$(nextSpans[0]).show();$(nextSpans[1]).hide();}
else
{var nextIndex=index+1;$(nextSpans[0]).hide();$(nextSpans[1]).show();var anchors=$(nextSpans[1]).getElementsByTagName('a');$A(anchors).each(function(anchor){anchor.href='#'+nextIndex;anchor.onclick=navigationClickHandler.bind(null,nextIndex,this.mSlideshow);}.bind(this));}}
DetailView.prototype.p_mediaStream=function()
{var mediaStream=null;if(this.preferences)
{mediaStream=this.preferenceForKey("mediaStreamObject");if(mediaStream==null||mediaStream==undefined)
{var mediaStreamCode=this.preferenceForKey("mediaStream");if(mediaStreamCode!=null&&mediaStreamCode.length>0)
{mediaStream=eval(mediaStreamCode);}}}
return mediaStream;}
DetailView.prototype.p_backgroundColor=function()
{var backgroundColor=null;if(this.preferences)
{backgroundColor=this.preferenceForKey("color");}
if(backgroundColor===undefined)
{backgroundColor="transparent";}
return backgroundColor;}
DetailView.prototype.p_baseURL=function()
{return this.preferenceForKey("baseURL");}
DetailView.prototype.p_startIndex=function()
{var startIndex=null;if(this.preferences)
{startIndex=this.preferenceForKey("startIndex");}
if(startIndex===undefined)
{startIndex=0;}
return startIndex;}
DetailView.prototype.p_showThumbnails=function()
{var showThumbnails=null;if(this.preferences)
{showThumbnails=this.preferenceForKey("showThumbnails");}
if(showThumbnails===undefined)
{showThumbnails=false;}
return showThumbnails;}
DetailView.prototype.p_scaleMode=function()
{var scaleMode=null;if(this.preferences)
{scaleMode=this.preferenceForKey("scaleMode");}
if(scaleMode===undefined)
{scaleMode="fit";}
return scaleMode;}
DetailView.prototype.p_addEvent=function(object,event,functionName,capture)
{if(object.addEventListener)
{event=event.length>2?event.substring(2):event;capture=capture?capture:false;object.addEventListener(event,functionName,capture);}
else if(object.attachEvent)
{object.attachEvent(event,functionName);}
else
{try
{object.setAttribute(event,functionName);}
catch(e)
{}}}
DetailView.prototype.p_keyDown=function(event)
{}
DetailView.prototype.p_keyUp=function(event)
{event=event?event:(window.event?window.event:"");var keyCode=event.which?event.which:event.keyCode;switch(keyCode)
{case 37:event.cancelBubble=true;if(event.stopPropagation)
{event.stopPropagation();}
if(!(window.isWebKit&&window.isEarlyWebKitVersion))
{location.hash=this.mSlideshow.prevPhotoNumber();}
this.mSlideshow.goBack();break;case 39:event.cancelBubble=true;if(event.stopPropagation)
{event.stopPropagation();}
if(!(window.isWebKit&&window.isEarlyWebKitVersion))
{location.hash=this.mSlideshow.nextPhotoNumber();}
this.mSlideshow.advance();break;}}
