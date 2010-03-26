////////////////////////////////////////////////////////////////////////////////
//
//  iWeb - iWPopUpSlideshow.js
//  Copyright (c) 2007 Apple Inc. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

var slideWidth;var slideHeight;var frameHeight;var frameWidth;var scroller;var slideshow;var thumbnails;var hud;var thumbMatte=89;var pickerHeight=100;var browser;var baseURL="http://www.me.com/1/slideshow/";var windowWidth=800;var windowHeight=800;function initSlideshow(imageStream,index,parameters){browser=new BrowserDetectLite();if(checkBrowser())
{alphaRules();if(document.documentElement&&document.documentElement.clientWidth&&document.documentElement.clientHeight)
{windowWidth=document.documentElement.clientWidth;windowHeight=document.documentElement.clientHeight;}
else if(self.innerWidth&&self.innerHeight)
{windowWidth=self.innerWidth;windowHeight=self.innerHeight;}
else if(document.body&&document.body.clientWidth&&document.body.clientHeight)
{windowWidth=document.body.clientWidth;windowHeight=document.body.clientHeight;}
slideWidth=windowWidth-200;slideHeight=windowHeight-290;frameHeight=slideHeight+50;frameWidth=slideWidth-20;var frame=appendDiv(document.body,'frame',frameWidth,frameHeight);var frameTop=Math.max(Math.round((windowHeight-frameHeight)/2),0);frame.style.marginTop=frameTop+'px';var slideMatte=appendDiv(frame,'matte',slideWidth,frameHeight);slideMatte.style.marginLeft=Math.round((frameWidth-slideWidth)/2)+"px";slideMatte.style.marginRight=Math.round((frameWidth-slideWidth)/2)+"px";var photos=[];for(var i=0;i<imageStream.length;++i)
{photos.push(imageStream[i].slideshowValue("image"));}
function onchange(index)
{selectThumb(index);}
parameters.movieMode=kAutoplayMovie;slideshow=new Slideshow(slideMatte,photos,onchange,parameters);if(parameters.hasOwnProperty("transitionIndex"))
{slideshow.setTransitionIndex(parameters.transitionIndex,0);}
initControls();var initThumbFade=function(){thumbnails.fadeHandler=null;thumbnails.fade(0.80,0,4000);};var initControlFade=function(){hud.fadeHandler=null;hud.fade(0.80,0,4000);};initThumbnailPicker(index!=null?index:0,imageStream);thumbnails.fadeHandler=setTimeout(initThumbFade,1000);hud.fadeHandler=setTimeout(initControlFade,1000);slideshow.playHandler=setTimeout(beginPlay.bind(null,index),0);addEvent(document,'onkeydown',arrowKeyDown,true);addEvent(document,'onkeyup',arrowKeyUp,true);}}
function beginPlay(index)
{clearInterval(slideshow.playHandler);slideshow.playHandler=null;if(index!=null&&index>0)
{slideshow.paused=false;slideshow.showPhotoNumber(index,true);}
else
{slideshow.start();}}
function initThumbnailPicker(startPoint,imageStream)
{var thumbnailZone=appendDiv(document.body,'thumbnailZone');var thumbnailPicker=appendDiv(thumbnailZone,'thumbnailPicker');var thumbStrip=appendDiv(thumbnailPicker,'thumbStrip');var pickerWidth=Math.min((imageStream.length*89)+2,frameWidth);thumbnailZone.style.width=windowWidth+"px";thumbnailZone.style.height=pickerHeight+25+"px";thumbnailZone.style.top="10px";thumbnailPicker.style.width=pickerWidth+"px";thumbnailPicker.style.height=pickerHeight+"px";thumbnailPicker.style.left=Math.round((windowWidth-pickerWidth)/2)+"px";thumbStrip.style.left='0px';setOpacity(thumbnailPicker,0.8);addEvent(thumbnailZone,'onmouseover',thumbnailFadeIn,false);addEvent(thumbnailZone,'onmouseout',thumbnailFadeOut,false);var results=generateThumbs(imageStream);selectThumb(startPoint);initScroller(startPoint);thumbnails=new hoverControls('thumbnailPicker');}
function initControls(){var controlZone=appendDiv(document.body,'controlZone');var controls=appendDiv(controlZone,'controls');var backButton;var forwardButton;var playButton;var pauseButton;var frameTop=Math.max(Math.round((windowHeight-frameHeight)/2),0);controlZone.style.top=frameTop+frameHeight+"px";if($('matte').style.marginLeft){controls.style.left=Math.round((windowWidth-177)/2)+parseInt($('matte').style.marginLeft,10)+"px";}else{controls.style.left=Math.round((windowWidth-177)/2)+parseInt($('matte').offsetLeft,10)+"px";}
if(browser.isIE===false){backButton=appendImage(controls,baseURL+'images/arrow_left.png','backbutton');playButton=appendImage(controls,baseURL+'images/play.png','playbutton',null,null,true);pauseButton=appendImage(controls,baseURL+'images/pause.png','pausebutton');forwardButton=appendImage(controls,baseURL+'images/arrow_right.png','forwardbutton');}else{controls.style.background='url('+baseURL+'images/controls.gif) center center no-repeat';backButton=appendImage(controls,baseURL+'images/arrow_left.gif','backbutton');playButton=appendImage(controls,baseURL+'images/play.gif','playbutton',null,null,true);pauseButton=appendImage(controls,baseURL+'images/pause.gif','pausebutton');forwardButton=appendImage(controls,baseURL+'images/arrow_right.gif','forwardbutton');}
setOpacity(controls,0.8);addEvent(backButton,'onmousedown',backClick,false);addEvent(backButton,'onmouseup',previous,false);addEvent(playButton,'onmousedown',playClick,false);addEvent(playButton,'onmouseup',restart,false);addEvent(pauseButton,'onmousedown',pauseClick,false);addEvent(pauseButton,'onmouseup',stop,false);addEvent(forwardButton,'onmousedown',forwardClick,false);addEvent(forwardButton,'onmouseup',next,false);addEvent(controlZone,'onmouseover',hudFadeIn);addEvent(controlZone,'onmouseout',hudFadeOut);hud=new hoverControls('controls');}
function selectThumb(index)
{var thumbPicker=$('thumbStrip');var thumbs=thumbPicker.getElementsByTagName('img');for(var i=0;i<thumbs.length;++i)
{var className='thumb';if(i==index)
{className='selectedthumb';}
var thumb=thumbs[i];if(thumb.className!=className)
{thumb.className=className;}}}
var thumbWidth=69;var thumbHeight=69;function thumbnailLoaded(thumbnail,index)
{var thumbPicker=$('thumbStrip');var thumbPickerPlaceholder=thumbPicker.getElementsByTagName('img')[index];var naturalSize=thumbnail.naturalSize();var imageScale=thumbWidth/naturalSize.width<thumbHeight/naturalSize.height?thumbWidth/naturalSize.width:thumbHeight/naturalSize.height;var scaledWidth=naturalSize.width*imageScale;var scaledHeight=naturalSize.height*imageScale;var hspace=Math.round((thumbWidth-scaledWidth)/2)+7;var vspace=Math.round((thumbHeight-scaledHeight)/2);thumbPickerPlaceholder.width=scaledWidth;thumbPickerPlaceholder.height=scaledHeight;thumbPickerPlaceholder.hspace=hspace;thumbPickerPlaceholder.vspace=vspace;thumbPickerPlaceholder.src=thumbnail.sourceURL();}
function generateThumbs(imageStream)
{var thumbPicker=$('thumbStrip');thumbPicker.style.width=(imageStream.length*89)+"px";var markup="";for(var i=0,len=imageStream.length;i<len;++i)
{markup+='<img width="'+thumbWidth+'" height="'+thumbHeight+'" id="thumb'+i+'" hspace="'+7+'" vspace="'+0+'" onclick="selectThumb('+i+'); slideshow.showPhotoNumber('+i+', true);" onfocus="blur()">';}
thumbPicker.innerHTML=markup;var index=0;$A(imageStream).invoke('micro').each(function(thumbnail){thumbnail.load(thumbnailLoaded.bind(null,thumbnail,index),index>=10);index++;});return true;}
function initScroller(startPoint){var thumbZone=$('thumbnailPicker');var scrollbar=appendDiv(thumbZone,"scrollbar");scrollbar.style.top="84px";scrollbar.style.left="0px";scrollbar.style.width=thumbZone.getWidth()-2+"px";scrollbar.style.height="15px";var bar=appendDiv(scrollbar,"bar");bar.style.top="0px";bar.style.left="0px";bar.style.width="100%";bar.style.height="13px";var dragTool=appendDiv(scrollbar,"dragtool");dragTool.style.top="1px";dragTool.style.left="0px";dragTool.style.width="26px";dragTool.style.height="13px";dragTool=appendImage(dragTool,'http://www.me.com/1/slideshow/images/dragger.gif',null,24,13);dragTool.setAttribute('hspace','1');var ruler=appendDiv(scrollbar,"ruler");ruler.style.top="0px";ruler.style.left="0px";scroller=new Scroller();if(startPoint!=null){scroller.jumpTo(startPoint);}
if(browser.isIE6x&&browser.isWin){scrollbar.style.top=parseInt(scrollbar.style.top,10)-2+'px';bar.style.height=parseInt(bar.style.height,10)+2+'px';scrollbar.style.width=parseInt(scrollbar.style.width,10)+2+'px';}else if(browser.isSafariJaguar){bar.style.width=$('thumbnailPicker').getWidth()-3+'px';}}
function checkBrowser(){var languageinfo=getLanguage();if(browser.isSafari||browser.isFirefox1up||browser.isNS7up||browser.isIE55up||browser.isCamino){return true;}else if(getCookie('browsewarning')=='true'){return true;}else{setCookie('browsewarning','true');setCookie('continue',window.location.href);switch(languageinfo){case'de':window.location=baseURL+'messaging/4/browser_req.html';break;case'fr':window.location=baseURL+'messaging/3/browser_req.html';break;case'ja':window.location=baseURL+'messaging/2/browser_req.html';break;default:window.location=baseURL+'messaging/1/browser_req.html';}
return false;}}
function thumbnailFadeIn(evt){try{evt=(evt)?evt:((window.event)?window.event:"");if(checkMouseEnter($('thumbnailZone'),evt)){if(!thumbnails.holdFade){scroller.jumpTo(slideshow.currentPhotoNumber);slideshow.pause();thumbnails.fade(0.90,0.90,0);}}}catch(e){}}
function thumbnailFadeOut(evt){try{evt=(evt)?evt:((window.event)?window.event:"");if(checkMouseLeave($('thumbnailZone'),evt)){if(!thumbnails.holdFade){thumbnails.fade(0.30,0,2000);if(slideshow.playHandler===null){slideshow.resume();}}}}catch(e){}}
function hudFadeIn(evt){try{evt=(evt)?evt:((window.event)?window.event:"");if(checkMouseEnter($('controlZone'),evt)){hud.fade(0.80,0.80,0);}}catch(e){}}
function hudFadeOut(evt){try{evt=(evt)?evt:((window.event)?window.event:"");if(checkMouseLeave($('controlZone'),evt)&&getOpacity($('controls'))>0.05){hud.fade(0.40,0,2000);if(slideshow.playHandler===null){slideshow.resume();}}}catch(e){}}
function stop(){slideshow.pause();slideshow.playHandler=-1;$('playbutton').style.display='';$('pausebutton').src=browser.isIE?baseURL+'images/pause.gif':baseURL+'images/pause.png';$('pausebutton').style.display='none';return false;}
function pauseClick(){$('pausebutton').src=browser.isIE?baseURL+'images/pause_on.gif':baseURL+'images/pause_on.png';return false;}
function restart(){slideshow.playHandler=null;$('pausebutton').style.display='';$('playbutton').src=browser.isIE?baseURL+'images/play.gif':baseURL+'images/play.png';$('playbutton').style.display='none';if(getOpacity($('controls'))>0.05)
{hud.fade(0.90,0,5000);}
slideshow.playHandler=setTimeout(function(){slideshow.resume();},1500);}
function playClick(){$('playbutton').src=browser.isIE?baseURL+'images/play_on.gif':baseURL+'images/play_on.png';return false;}
function forwardClick(){$('forwardbutton').src=browser.isIE?baseURL+'images/arrow_right_on.gif':baseURL+'images/arrow_right_on.png';return false;}
function next(){$('forwardbutton').src=browser.isIE?baseURL+'images/arrow_right.gif':baseURL+'images/arrow_right.png';slideshow.advance();return false;}
function backClick(){$('backbutton').src=browser.isIE?baseURL+'images/arrow_left_on.gif':baseURL+'images/arrow_left_on.png';return false;}
function previous(){$('backbutton').src=browser.isIE?baseURL+'images/arrow_left.gif':baseURL+'images/arrow_left.png';slideshow.goBack();return false;}
function arrowKeyDown(evt){evt=(evt)?evt:((window.event)?window.event:"");var keyCode=evt.which?evt.which:evt.keyCode;switch(keyCode){case 39:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
forwardClick();break;case 34:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
forwardClick();break;case 37:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
backClick();break;case 33:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
backClick();break;case 32:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
if(slideshow.playHandler==-1){playClick();}else{pauseClick();}
break;}
if((slideshow.photos.length*thumbMatte)>(scroller.getContentClipW()-scroller.getContentL())){scroller.jumpTo(slideshow.currentPhotoNumber,'left');}else if((slideshow.photos.length*thumbMatte)<-scroller.getContentL()){scroller.jumpTo(slideshow.currentPhotoNumber,'right');}}
function arrowKeyUp(evt){evt=(evt)?evt:((window.event)?window.event:"");var keyCode=evt.which?evt.which:evt.keyCode;switch(keyCode){case 39:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
next();break;case 34:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
next();break;case 37:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
previous();break;case 33:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
previous();break;case 32:evt.cancelBubble=true;if(evt.stopPropagation){evt.stopPropagation();}
if(slideshow.playHandler==-1){restart();}else{stop();}
break;case 36:slideshow.pause();slideshow.resetSlideshow(0);if(slideshow.playHandler!=-1){slideshow.play();}
break;case 35:slideshow.pause();slideshow.resetSlideshow(slideshow.photos.length-1);if(slideshow.playHandler!=-1){slideshow.play();}
break;}
if((slideshow.currentPhotoNumber*thumbMatte)>(scroller.getContentClipW()-scroller.getContentL())){scroller.jumpTo(slideshow.currentPhotoNumber,'left');}else if((slideshow.currentPhotoNumber*thumbMatte)<-scroller.getContentL()){scroller.jumpTo(slideshow.currentPhotoNumber,'right');}}
function heightOffset(browser){if(browser.isIE5xMac){return 15;}else if(browser.isSafari){return 23;}else if(browser.isFirefox&&browser.isWin){return 25;}else if(browser.isNS6up&&browser.isWin){return 30;}else if(browser.isCamino){return 40;}else if(browser.isMozilla){return 42;}else if(browser.isIEWin){return 49;}else{return 0;}}
function widthOffset(browser){if(browser.isIE5xMac){return 5;}else{return 0;}}
function BrowserDetectLite(){var ua=navigator.userAgent.toLowerCase();this.ua=ua;this.isGecko=(ua.indexOf('gecko')!=-1);this.isMozilla=(this.isGecko&&ua.indexOf("gecko/")+14==ua.length);this.isFirefox=(this.isGecko&&ua.indexOf("firefox")!=-1);this.isCamino=(this.isGecko&&ua.indexOf("camino")!=-1);this.isSafari=(this.isGecko&&ua.indexOf("safari")!=-1);this.isNS=((this.isGecko)?(ua.indexOf('netscape')!=-1):((ua.indexOf('mozilla')!=-1)&&(ua.indexOf('spoofer')==-1)&&(ua.indexOf('compatible')==-1)&&(ua.indexOf('opera')==-1)&&(ua.indexOf('webtv')==-1)&&(ua.indexOf('hotjava')==-1)));this.isIE=((ua.indexOf("msie")!=-1)&&(ua.indexOf("opera")==-1)&&(ua.indexOf("webtv")==-1));this.isOpera=(ua.indexOf("opera")!=-1);this.isKonqueror=(ua.indexOf("konqueror")!=-1);this.isIcab=(ua.indexOf("icab")!=-1);this.isAol=(ua.indexOf("aol")!=-1);this.isWebtv=(ua.indexOf("webtv")!=-1);this.isOmniweb=(ua.indexOf("omniweb")!=-1);this.isDreamcast=(ua.indexOf("dreamcast")!=-1);this.isIECompatible=((ua.indexOf("msie")!=-1)&&!this.isIE);this.isNSCompatible=((ua.indexOf("mozilla")!=-1)&&!this.isNS&&!this.isMozilla);this.versionMinor=parseFloat(navigator.appVersion);if(this.isNS&&this.isGecko){this.versionMinor=parseFloat(ua.substring(ua.lastIndexOf('/')+1));}
else if(this.isFirefox){this.versionMinor=parseFloat(ua.substring(ua.lastIndexOf('/')+1));}
else if(this.isSafari){this.versionMinor=parseFloat(ua.substring(ua.lastIndexOf('/')+1));}
else if(this.isIE&&this.versionMinor>=4){this.versionMinor=parseFloat(ua.substring(ua.indexOf('msie ')+5));}
else if(this.isOpera){if(ua.indexOf('opera/')!=-1){this.versionMinor=parseFloat(ua.substring(ua.indexOf('opera/')+6));}
else{this.versionMinor=parseFloat(ua.substring(ua.indexOf('opera ')+6));}}
else if(this.isKonqueror){this.versionMinor=parseFloat(ua.substring(ua.indexOf('konqueror/')+10));}
else if(this.isIcab){if(ua.indexOf('icab/')!=-1){this.versionMinor=parseFloat(ua.substring(ua.indexOf('icab/')+6));}
else{this.versionMinor=parseFloat(ua.substring(ua.indexOf('icab ')+6));}}
else if(this.isWebtv){this.versionMinor=parseFloat(ua.substring(ua.indexOf('webtv/')+6));}
this.versionMajor=parseInt(this.versionMinor,10);this.geckoVersion=((this.isGecko)?ua.substring((ua.lastIndexOf('gecko/')+6),(ua.lastIndexOf('gecko/')+14)):-1);this.isWin=(ua.indexOf('win')!=-1);this.isWin32=(this.isWin&&(ua.indexOf('95')!=-1||ua.indexOf('98')!=-1||ua.indexOf('nt')!=-1||ua.indexOf('win32')!=-1||ua.indexOf('32bit')!=-1));this.isMac=(ua.indexOf('mac')!=-1);this.isUnix=(ua.indexOf('unix')!=-1||ua.indexOf('linux')!=-1||ua.indexOf('sunos')!=-1||ua.indexOf('bsd')!=-1||ua.indexOf('x11')!=-1);this.isNS4below=(this.isNS&&this.versionMajor<=4);this.isNS4x=(this.isNS&&this.versionMajor==4);this.isNS40x=(this.isNS4x&&this.versionMinor<4.5);this.isNS47x=(this.isNS4x&&this.versionMinor>=4.7);this.isNS4up=(this.isNS&&this.versionMinor>=4);this.isNS6x=(this.isNS&&this.versionMajor==6);this.isNS6up=(this.isNS&&this.versionMajor>=6);this.isNS7up=(this.isNS&&this.versionMajor>=7);this.isIEWin=(this.isIE&this.isWin);this.isIE4below=(this.isIE&&this.versionMajor<=4);this.isIE4x=(this.isIE&&this.versionMajor==4);this.isIE4up=(this.isIE&&this.versionMajor>=4);this.isIE5x=(this.isIE&&this.versionMajor==5);this.isIE55=(this.isIE&&this.versionMinor==5.5);this.isIE5up=(this.isIE&&this.versionMajor>=5);this.isIE55up=(this.isIE&&this.versionMinor>=5.5);this.isIE6x=(this.isIE&&this.versionMajor==6);this.isIE6up=(this.isIE&&this.versionMajor>=6);this.isSafariJaguar=(this.isSafari&&this.versionMajor<100);this.isFirefox1up=(this.isFirefox&&this.versionMinor>=1);this.isIE4xMac=(this.isIE4x&&this.isMac);this.isIE5xMac=(this.isIE5up&&this.isMac);this.supportsOnload=(!this.isOpera&&!this.isIcab&&!this.isIE4below&&!this.isNS4below);}
function getLanguage(){var languageInfo;languageInfo=navigator.language?navigator.language:(navigator.userLanguage?navigator.userLanguage:"");if(languageInfo.indexOf('-')>-1){languageInfo=languageInfo.substr(0,2);}
return languageInfo;}
function alphaRules(){if(browser===null){browser=new BrowserDetectLite();}
if(browser.isWin&&browser.isIE){document.styleSheets[0].addRule("img","filter: alpha(opacity=100)",0);}}
function getType(obj){var type;if(typeof obj.style.opacity!='undefined'){type='w3c';}else if(typeof obj.style.MozOpacity!='undefined'){type='moz';}else if(typeof obj.style.KhtmlOpacity!='undefined'){type='khtml';}else if(typeof obj.filters=='object'){type='ie';}else{type='none';}
return type;}
function appendDiv(parentObj,divId,width,height,makeInvisible){var divObj=document.createElement('div');if(width!=null){divObj.style.width=width+'px';}
if(height!=null){divObj.style.height=height+'px';}
if(makeInvisible){divObj.style.display='none';}
divObj=parentObj.appendChild(divObj);if(divId!=null){divObj.setAttribute('id',divId);}
return divObj;}
function appendImage(parentObj,src,imgId,width,height,makeInvisible){var imgObj=document.createElement('img');imgObj.src=src;if(width!=null){imgObj.style.width=width+'px';}
if(height!=null){imgObj.style.height=height+'px';}
if(makeInvisible){imgObj.style.display='none';}
imgObj=parentObj.appendChild(imgObj);if(imgId!=null){imgObj.setAttribute('id',imgId);}
return imgObj;}
function addEvent(object,event,functionName,capture)
{if(object.addEventListener)
{event=event.length>2?event.substring(2):event;capture=capture?capture:false;object.addEventListener(event,functionName,capture);}
else if(object.attachEvent)
{object.attachEvent(event,functionName);}
else
{try
{object.setAttribute(event,functionName);}
catch(e)
{}}}
function setOpacity(obj,value){if(value>0){var type=getType(obj);switch(type){case'ie':value=value>=0.99?100:Math.round(value*100);if(typeof obj.filters=='object'&&obj.filters.alpha){obj.filters.alpha.opacity=value;}
else{obj.style.filter='alpha('+value+')';}
break;case'khtml':obj.style.KhtmlOpacity=value;break;case'moz':obj.style.MozOpacity=(value>=0.99?0.99:value);break;case'none':break;default:obj.style.opacity=(value>=0.99?0.99:value);}
obj.style.display='';}else{obj.style.display='none';}}
function getOpacity(obj){var type=getType(obj);var opac;switch(type){case'ie':if(typeof obj.filters=='object'&&obj.filters.alpha){opac=obj.filters.alpha.opacity;}
opac=(opac===null||typeof opac=='undefined')?1.0:opac/100.0;break;case'khtml':opac=obj.style.KhtmlOpacity;opac=opac===null||typeof opac=='undefined'||opac===''?1.0:opac;break;case'moz':opac=obj.style.MozOpacity;opac=opac===null||typeof opac=='undefined'||opac===''?1.0:opac;break;case'none':opac=1.0;break;default:opac=obj.style.opacity;opac=opac===null||typeof opac=='undefined'||opac===''?1.0:opac;}
return Number(opac);}
function hoverControls(divId){this.timer=1;this.fadeHandler=null;this.divId=divId;this.start=null;this.end=null;this.holdFade=false;this.restartFade=false;var me=this;this.fade=function(start,end,ms)
{start=getOpacity($(this.divId));if(this.animation)
{this.animation.stop();}
if(this.fadeHandler)
{clearInterval(this.fadeHandler);}
this.animation=new SimpleAnimation(function(){});this.animation.startOpacity=start;this.animation.endOpacity=end;this.animation.duration=ms;this.animation.pre=function()
{setOpacity($(me.divId),this.startOpacity);}
this.animation.post=function()
{setOpacity($(me.divId),this.endOpacity);}
this.animation.update=function(now)
{setOpacity($(me.divId),this.startOpacity+now*(this.endOpacity-this.startOpacity));}
this.animation.start();}}
function Scroller(){var scrollW=$('thumbnailPicker').getWidth();var speed=4;var mouseY;var mouseX;var clickLeft=false;var clickRight=false;var clickDrag=false;var timer=setTimeout(function(){},500);var leftL;var leftT;var rightL;var rightT;var dragL;var dragT;var rulerL;var rulerT;var contentL;var contentW;var contentClipW;var scrollLength;var startX;var scrollbarOffset;var leftH;var leftW;var rightH;var rightW;var dragH;var dragW;var me=this;var eventLoader=function eventLoader(){scrollbarOffset=IWChildOffset($('scrollbar'),document.body);dragL=parseInt($('dragtool').style.left,10);dragT=parseInt($('dragtool').style.top,10);rulerT=parseInt($('ruler').style.top,10);rulerL=parseInt($('ruler').style.left,10);contentW=$('thumbStrip').getWidth();contentClipW=$('thumbnailPicker').getWidth();dragH=$('dragtool').getHeight();dragW=$('dragtool').getWidth();scrollLength=((scrollW-dragW)/(contentW-contentClipW));window.onresize=me.resetPosition;if(contentW<contentClipW){$('scrollbar').style.display='none';}
document.onmousedown=down;document.onmousemove=move;document.onmouseup=up;};this.resetPosition=function resetPosition(){scrollbarOffset=IWChildOffset($('scrollbar'),document.body);};var down=function down(e){getMouse(e);startX=(mouseX-dragL);if(mouseX>=leftL&&(mouseX<=(leftL+leftW))&&mouseY>=leftT&&(mouseY<=(leftT+leftH))){clickLeft=true;return me.scrollLeft();}
else if(mouseX>=rightL&&(mouseX<=(rightL+rightW))&&mouseY>=rightT&&(mouseY<=(rightT+rightH))){clickRight=true;return me.scrollRight();}
else if(mouseY>=dragT&&(mouseY<=(dragT+dragH+4))&&mouseX>=rulerL&&(mouseX<=(rulerL+scrollW))){clickDrag=true;if(thumbnails){thumbnails.holdFade=true;}
return move(e);}
else{return true;}};var move=function move(e){if(clickDrag&&contentW>contentClipW){getMouse(e);dragL=mouseX-(dragW/2);if(dragL<(rulerL)){dragL=rulerL;}
if(dragL>(rulerL+scrollW-dragW)){dragL=(rulerL+scrollW-dragW);}
contentL=-((dragL-rulerL)*(1/scrollLength));moveTo();return false;}};var up=function(e){clearTimeout(timer);clickLeft=false;clickRight=false;clickDrag=false;if(thumbnails&&thumbnails.holdFade){thumbnails.holdFade=false;getMouse(e);var thumbZone=$('thumbnailZone');var zoneOffset=IWChildOffset(thumbZone,document.body);var zoneR=zoneOffset.x+thumbZone.getWidth();var zoneB=zoneOffset.y+thumbZone.getHeight();if((mouseX+scrollbarOffset.x)>zoneOffset.x&&(mouseX+scrollbarOffset.x)<zoneR&&(mouseY+scrollbarOffset.y)>zoneOffset.y&&(mouseY+scrollbarOffset.y)<zoneB){}else{thumbnails.fade(0.30,0,2000);slideshow.resume();}}
return true;};var getL=function getL(){contentL=parseInt($('thumbStrip').style.left,10);};var getMouse=function getMouse(e){if(typeof scrollbarOffset=='undefined'||typeof rightOffset=='undefined'){me.resetPosition();}
if(typeof event!='undefined'){mouseY=event.clientY+document.body.scrollTop-scrollbarOffset.y;mouseX=event.clientX+document.body.scrollLeft-scrollbarOffset.x;}else{mouseY=e.pageY-scrollbarOffset.y;mouseX=e.pageX-scrollbarOffset.x;}};this.jumpTo=function jumpTo(slideCount,slidePosition){if(contentW>contentClipW){getL();if(slidePosition=='left'){contentL=(-slideCount*thumbMatte);}else if(slidePosition=='right'){contentL=(-slideCount*thumbMatte)+contentClipW;}else{contentL=Math.round((contentClipW/2)-(slideCount*thumbMatte)-(thumbMatte/2));}
if(contentL<scrollW-contentW){contentL=scrollW-contentW;}else if(contentL>0){contentL=0;}
dragL=contentL*(scrollW-dragW)/(scrollW-contentW);if(dragL<0){dragL=0;}
return moveTo();}else{return false;}};var moveTo=function moveTo(){$('thumbStrip').style.left=contentL+"px";$('dragtool').style.left=dragL+"px";$('ruler').style.left=dragL+"px";return true;};this.scrollLeft=function scrollLeft(){getL();if(clickLeft&&contentW>contentClipW){if(contentL<0){dragL=dragL-(speed*scrollLength);if(dragL<(rulerL))
{dragL=rulerL;}
contentL=contentL+speed;if(contentL>0)
{contentL=0;}
moveTo();timer=setTimeout(me.scrollLeft,25);}}
return false;};this.scrollRight=function scrollRight(){getL();if(clickRight&&contentW>contentClipW){if(contentL>-(contentW-contentClipW)){dragL=dragL+(speed*scrollLength);if(dragL>(rulerL+scrollW-dragH))
{dragL=(rulerL+scrollW-dragH);}
contentL=contentL-speed;if(contentL<-(contentW-contentClipW))
{contentL=-(contentW-contentClipW);}
moveTo();timer=setTimeout(me.scrollRight,25);}}
return false;};this.getContentL=function getContentL(){return contentL;};this.getContentW=function getContentW(){return contentW;};this.getContentClipL=function getContentClipL(){return contentClipL;};this.getContentClipW=function getContentClipW(){return contentClipW;};eventLoader();}
function isParent(container,containee){var isParentBool=false;while(!isParentBool&&containee){isParentBool=container==containee;containee=containee.parentNode;}
return isParentBool;}
function checkMouseEnter(element,evt){if(evt.fromElement){return!isParent(element,evt.fromElement);}
else if(evt.relatedTarget){return!isParent(element,evt.relatedTarget);}
else{return true;}}
function checkMouseLeave(element,evt){if(evt.toElement){return!isParent(element,evt.toElement);}
else if(evt.relatedTarget){return!isParent(element,evt.relatedTarget);}
else{return true;}}
function setCookie(c_name,value)
{document.cookie=c_name+"="+escape(value);}
function getCookie(c_name)
{if(document.cookie.length>0)
{c_start=document.cookie.indexOf(c_name+"=")
if(c_start!=-1)
{c_start=c_start+c_name.length+1
c_end=document.cookie.indexOf(";",c_start)
if(c_end==-1)c_end=document.cookie.length
return unescape(document.cookie.substring(c_start,c_end))}}
return""}
