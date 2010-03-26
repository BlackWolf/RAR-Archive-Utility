// Created by iWeb 2.0.4 local-build-20100326

function createMediaStream_id3()
{return IWCreatePhotocast("file://localhost/Users/BlackWolf/Sites/RAU/RAR-Archive_Utility/Screenshots_files/rss.xml",false,true);}
function initializeMediaStream_id3()
{createMediaStream_id3().load('file://localhost/Users/BlackWolf/Sites/RAU/RAR-Archive_Utility',function(imageStream)
{var entryCount=imageStream.length;var headerView=widgets['widget1'];headerView.setPreferenceForKey(imageStream.length,'entryCount');NotificationCenter.postNotification(new IWNotification('SetPage','id3',{pageIndex:0}));});}
function layoutMediaGrid_id3(range)
{createMediaStream_id3().load('file://localhost/Users/BlackWolf/Sites/RAU/RAR-Archive_Utility',function(imageStream)
{if(range==null)
{range=new IWRange(0,imageStream.length);}
IWLayoutPhotoGrid('id3',new IWPhotoGridLayout(3,new IWSize(158,158),new IWSize(158,35),new IWSize(196,208),27,27,0,new IWSize(2,2)),new IWEmptyStroke(),imageStream,range,null,null,1.000000,null,'Media/slideshow.html','widget1','widget2','widget3')});}
function relayoutMediaGrid_id3(notification)
{var userInfo=notification.userInfo();var range=userInfo['range'];layoutMediaGrid_id3(range);}
function onStubPage()
{var args=getArgs();parent.IWMediaStreamPhotoPageSetMediaStream(createMediaStream_id3(),args.id);}
if(window.stubPage)
{onStubPage();}
setTransparentGifURL('Media/transparent.gif');function hostedOnDM()
{return false;}
function onPageLoad()
{IWRegisterNamedImage('comment overlay','Media/Photo-Overlay-Comment.png')
IWRegisterNamedImage('movie overlay','Media/Photo-Overlay-Movie.png')
IWRegisterNamedImage('contribution overlay','Media/Photo-Overlay-Contribution.png')
loadMozillaCSS('Screenshots_files/ScreenshotsMoz.css')
adjustLineHeightIfTooBig('id1');adjustFontSizeIfTooBig('id1');adjustLineHeightIfTooBig('id2');adjustFontSizeIfTooBig('id2');NotificationCenter.addObserver(null,relayoutMediaGrid_id3,'RangeChanged','id3')
Widget.onload();fixupAllIEPNGBGs();fixAllIEPNGs('Media/transparent.gif');initializeMediaStream_id3()
performPostEffectsFixups()}
function onPageUnload()
{Widget.onunload();}
