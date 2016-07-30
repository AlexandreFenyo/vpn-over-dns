// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

import flash.desktop.NativeApplication;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.KeyboardEvent;
import flash.net.dns.DNSResolver;

import mx.collections.ArrayCollection;
import mx.collections.ListCollectionView;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.core.BitmapAsset;
import mx.core.FlexGlobals;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.resources.ResourceManager;
import mx.utils.ColorUtil;

import spark.components.Application;
import spark.components.ViewNavigator;
import spark.components.supportClasses.ViewNavigatorApplicationBase;
import spark.events.IndexChangeEvent;
import spark.managers.PersistenceManager;
import spark.primitives.BitmapImage;

import net.fenyo.extension.Tools;
import net.fenyo.mail4hotspot.dns.DnsQuerierFactory;
import net.fenyo.mail4hotspot.gui.PopUpException;
import net.fenyo.mail4hotspot.gui.PopUpGeneric;
import net.fenyo.mail4hotspot.service.Application;
import net.fenyo.mail4hotspot.service.HttpProxy;
import net.fenyo.mail4hotspot.service.MailItem;
import net.fenyo.mail4hotspot.service.PortItem;
import net.fenyo.mail4hotspot.service.VuMeter;

import views.ConfigurationView;
import views.StatusView;

[Bindable]
public static var release_info_production_domain : Boolean = true;
[Bindable]
public static var release_info_debug_tools : Boolean = false;

public static var release_info_debug_sockets : Boolean = false;

[Bindable]
public static var new_skin : Boolean = true;

[Bindable]
public static var skin_bgcolor : uint = 0xe6e5d7;

[Bindable]
public static var release_info_client_version : String = "9";
[Bindable]
public static var release_info_protocol_version : uint = 0;
[Bindable]
// valeurs: "LOGIN_ONLY", "PAY", "LITE"
public static var release_info_account_type : String = "PAY";

// https://flex.apache.org/asdoc/mx/core/RuntimeDPIProvider.html
// 160 DPI	<140 DPI
// 160 DPI	>=140 DPI and <=200 DPI
// 240 DPI	>=200 DPI and <=280 DPI
// 320 DPI	>=280 DPI and <=400 DPI
// 480 DPI	>=400 DPI and <=560 DPI
// 640 DPI	>=640 DPI

// Galaxy Tab II 8.9 emulé : 800x1232
// mon Galaxy S2 : 480x762 @240dpi
// Galaxy S3, d'après site Samsung : 720x1280
// Galaxy Note, d'après site Samsung : 800x1280
// iPhone 4s, d'après le site d'Apple : 640x960 @326dpi
// nouvel iPad : 1536x2048
// iPad2 : 768x1024
// Galaxy S6 : 1440x2560 @577dpi
// choix du mode tablette :
//   largeur en mode tablette (horizontal) doit être supérieure au double de la la largeur nécessaire pour accueillir l'écran status
// la largeur du mode status est : FlexGlobals.topLevelApplication.applicationDPI (160, 240 ou 320) /240*400 + environ 80
//                                 @120dpi : 280px
//                                 @160dpi : 346px
//                                 @240dpi : 480px
//                                 @320dpi : 613px
//                                 @480dpi : 880px
//                                 @640dpi : 1147px
// donc avec cette règle, tablette si:
//   120dpi && height > 560
//   160dpi && height > 692
//   240dpi && height > 960
//   320dpi && height > 1226
//   480dpi && height > 1760
//   640dpi && height > 2294
// on définit donc la règle suivante :
// tablette ssi (height>{650px@160dpi,900px@240dpi,1100@320dpi} && sqrt(width^2+height^2)/dpi>=7'')
//
// mappings réels => flex définis ici http://help.adobe.com/en_US/flex/mobileapps/WS19f279b149e7481c682e5a9412cf5976c17-8000.html
// entre 200 et 280 dpi, flex dit 260 dpi
//
// valeurs dpi données par Wikipedia : http://en.wikipedia.org/wiki/List_of_displays_by_pixel_density
//
// en utilisant les dpi indiqués par DeviceCentral ou Wikipedia notamment http://en.wikipedia.org/wiki/List_of_displays_by_pixel_density :
// Galaxy Tab II 8.9 : ?
// Galaxy Tab 10.1 : 9''
// Galaxy S2 : 3,8''
// Galaxy S3 : <6.1 si 240dpi
// Galaxy Note : 6.2 si 240dpi et 4.6 si 320dpi
// iPhone 4s : 3,6''
// iPhone 4 : 4,8''
// iPad2 : 8''
// nouvel iPad : ?
// iPad AIR 2: 2048x1536@264dpi
//
// Galaxy Tab reloaded : http://www.samsung.com/global/microsite/galaxytab/7.0/index.html?type=find
// le Galaxy Tab tout court: juste au dessus de 7'' => c'est pour cela qu'on met 7'' comme limite, pour le prendre en compte

[Bindable]
public static var tablet : Boolean = false;

[Bindable]
public static var tablet_leftwidth : uint = 0;

[Bindable]
public var persistenceManager : PersistenceManager;

[Bindable]
public var mailsDataProvider : ListCollectionView = new ListCollectionView(new ArrayCollection());

// "description", "local_port", "remote_port", "remote_host"
[Bindable]
public var portsDataProvider : ListCollectionView = new ListCollectionView(new ArrayCollection());

[Bindable]
public var normalFontSize : int = 20;
[Bindable]
public var smallLabelFontSize : int = 15;
[Bindable]
public var labelFontSize : int = 20;
[Bindable]
public var buttonFontSize : int = 25;
[Bindable]
public var headerFontSize : int = 30;

[Bindable]
public static var browserViewPaddingTop : int = 10;

[Bindable]
public static var popupTitleHeight : int = 35;

public const tools : Tools = new Tools();

public static var deviceId : String = null;

// tab bar configuration icon:
// at 160dpi: 66*160/240 = 44
// at 240dpi: 66 = 66
// at 320dpi: 66*320/240 = 88
[Embed(source='/assets/icon_configuration_new-640dpi.png')] 
public static var PictureConfig640 : Class;

// tab bar mail icon:
// at 160dpi: 66*160/240 = 44
// at 240dpi: 66 = 66
// at 320dpi: 66*320/240 = 88
[Embed(source='/assets/icon_mail_new-640dpi.png')]
public static var PictureMail640 : Class; 

// tab bar status icon:
// at 160dpi: 66*160/240 = 44
// at 240dpi: 66 = 66
// at 320dpi: 66*320/240 = 88
[Embed(source='/assets/icon_status_new-640dpi.png')]
public static var PictureStatus640 : Class;

// tab bar browser icon:
// at 160dpi: 66*160/240 = 44
// at 240dpi: 66 = 66
// at 320dpi: 66*320/240 = 88
[Embed(source='/assets/icon_browser_new-640dpi.png')]
public static var PictureBrowser640 : Class;

// tab bar screw icon:
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/icon_screw-640dpi.png')] 
public static var PictureScrewOld640 : Class; 

public static var PictureScrew640 : Class;

[Embed(source='/assets/icon_screw_new-640dpi.png')] 
public static var PictureScrewNew640 : Class; 

[Embed(source='/assets/gmail-640dpi.png')]
public static var PictureGmail640 : Class;

[Embed(source='/assets/hotmail-640dpi.png')]
public static var PictureHotmail640 : Class;

[Embed(source='/assets/operamail-640dpi.png')]
public static var PictureOperamail640 : Class;

[Embed(source='/assets/yahoomail-640dpi.png')]
public static var PictureYahoomail640 : Class;

// vu meter
// largeur originale : 620
// @160dpi : 400*160/240 = 267
// @240dpi : 400
// @320dpi : 400*320/240 = 533
[Embed(source='/assets/vumeter_bg-120dpi.png')]
public static var PictureVumeterBg120 : Class;
[Embed(source='/assets/vumeter_bgled-120dpi.png')]
public static var PictureVumeterBgled120 : Class;
[Embed(source='/assets/vumeter_mask-120dpi.png')]
public static var PictureVumeterMask120 : Class;

[Embed(source='/assets/vumeter_bg-160dpi.png')]
public static var PictureVumeterBg160 : Class;
[Embed(source='/assets/vumeter_bgled-160dpi.png')]
public static var PictureVumeterBgled160 : Class;
[Embed(source='/assets/vumeter_mask-160dpi.png')]
public static var PictureVumeterMask160 : Class;

[Embed(source='/assets/vumeter_bg-240dpi.png')]
public static var PictureVumeterBg240 : Class;
[Embed(source='/assets/vumeter_bgled-240dpi.png')]
public static var PictureVumeterBgled240 : Class;
[Embed(source='/assets/vumeter_mask-240dpi.png')]
public static var PictureVumeterMask240 : Class;

[Embed(source='/assets/vumeter_bg-320dpi.png')]
public static var PictureVumeterBg320 : Class;
[Embed(source='/assets/vumeter_bgled-320dpi.png')]
public static var PictureVumeterBgled320 : Class;
[Embed(source='/assets/vumeter_mask-320dpi.png')]
public static var PictureVumeterMask320 : Class;

[Embed(source='/assets/vumeter_bg-480dpi.png')]
public static var PictureVumeterBg480 : Class;
[Embed(source='/assets/vumeter_bgled-480dpi.png')]
public static var PictureVumeterBgled480 : Class;
[Embed(source='/assets/vumeter_mask-480dpi.png')]
public static var PictureVumeterMask480 : Class;

[Embed(source='/assets/vumeter_bg-640dpi.png')]
public static var PictureVumeterBg640 : Class;
[Embed(source='/assets/vumeter_bgled-640dpi.png')]
public static var PictureVumeterBgled640 : Class;
[Embed(source='/assets/vumeter_mask-640dpi.png')]
public static var PictureVumeterMask640 : Class;

// header "STATUS"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_status-640dpi.png')] 
public static var TextStatusOld640 : Class;

public static var TextStatus640 : Class;

[Embed(source='/assets/text_status_new-640dpi.png')] 
public static var TextStatusNew640 : Class;

// header "STATUT"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_statut-640dpi.png')] 
public static var TextStatutOld640 : Class;

public static var TextStatut640 : Class;

[Embed(source='/assets/text_status_new-640dpi.png')] 
public static var TextStatutNew640 : Class;

// header "MAIL"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_mail-640dpi.png')] 
public static var TextMailOld640 : Class;

public static var TextMail640 : Class;

[Embed(source='/assets/text_mail_new-640dpi.png')] 
public static var TextMailNew640 : Class;

// header "BROWSER"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_browser-640dpi.png')] 
public static var TextBrowserOld640 : Class;

public static var TextBrowser640 : Class;

[Embed(source='/assets/text_browser_new-640dpi.png')] 
public static var TextBrowserNew640 : Class;

// header "CONFIG"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_config-640dpi.png')] 
public static var TextConfigOld640 : Class;

public static var TextConfig640 : Class;

[Embed(source='/assets/text_config_new-640dpi.png')] 
public static var TextConfigNew640 : Class;

// header "LANGUE"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_langue-640dpi.png')]
public static var TextLangueOld640 : Class;

public static var TextLangue640 : Class;

[Embed(source='/assets/text_langue_new-640dpi.png')]
public static var TextLangueNew640 : Class;

// header "COUNTRY"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_country-640dpi.png')]
public static var TextCountryOld640 : Class;

public static var TextCountry640 : Class;

[Embed(source='/assets/text_country_new-640dpi.png')]
public static var TextCountryNew640 : Class;

// header "PORTS"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_ports-640dpi.png')]
public static var TextPortsOld640 : Class;

public static var TextPorts640 : Class;

[Embed(source='/assets/text_ports_new-640dpi.png')]
public static var TextPortsNew640 : Class;

// header "LOGIN"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_login-640dpi.png')]
public static var TextLoginOld640 : Class;

public static var TextLogin640 : Class;

[Embed(source='/assets/text_login_new-640dpi.png')]
public static var TextLoginNew640 : Class;

// header "NEW_ACCOUNT"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_new_account-640dpi.png')]
public static var TextNewAccountOld640 : Class;

public static var TextNewAccount640 : Class;

[Embed(source='/assets/text_new_account_new-640dpi.png')]
public static var TextNewAccountNew640 : Class;

// header "IDENT"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_new_ident-640dpi.png')]
public static var TextIdentOld640 : Class;

public static var TextIdent640 : Class;

[Embed(source='/assets/text_new_ident_new-640dpi.png')]
public static var TextIdentNew640 : Class;

// header "IDENTITE"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_new_identite-640dpi.png')]
public static var TextIdentiteOld640 : Class;

public static var TextIdentite640 : Class;

[Embed(source='/assets/text_new_identite_new-640dpi.png')]
public static var TextIdentiteNew640 : Class;

// header "CREER"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_new_creer-640dpi.png')]
public static var TextCreerOld640 : Class;

public static var TextCreer640 : Class;

[Embed(source='/assets/text_new_creer_new-640dpi.png')]
public static var TextCreerNew640 : Class;

// header "CONNECTER"
// at 160dpi: 25
// at 240dpi: 37
// at 320dpi: 50
[Embed(source='/assets/text_new_connecter-640dpi.png')]
public static var TextConnecterOld640 : Class;

public static var TextConnecter640 : Class;

[Embed(source='/assets/text_new_connecter_new-640dpi.png')]
public static var TextConnecterNew640 : Class;

// [Embed(source='/assets/icon_downstream.png')] 
[Embed(source='/assets/new-down.png')] 
public static var DownStream : Class;
// [Embed(source='/assets/icon_upstream.png')]
[Embed(source='/assets/new-up.png')] 
public static var UpStream : Class;
// [Embed(source='/assets/bomb.png')]
[Embed(source='/assets/new-error.png')] 
public static var StreamError : Class;

[Embed(source='/assets/telephone-big3-640dpi.png')]
public static var Telephone640 : Class;

public var popup_intro_appeared : Boolean = false;
public var popup_ad_can_appear : Boolean = false;

// états de la vérification des mails
// 0 : inactif
//public var status_state : int = 0;

private function onTabClick(e : Event) : void {
	if (!tablet) {
		if (FlexGlobals.topLevelApplication.view_browser != null && FlexGlobals.topLevelApplication.view_browser.activeView != null)
			FlexGlobals.topLevelApplication.view_browser.activeView.tabChanged(e.currentTarget.selectedIndex);
	} else {
		if (FlexGlobals.topLevelApplication.tablet_view_browser != null && FlexGlobals.topLevelApplication.tablet_view_browser.activeView != null)
			FlexGlobals.topLevelApplication.tablet_view_browser.activeView.tabChanged(e.currentTarget.selectedIndex);
	}
}

public static function getReleaseInfos() : String {
	return "release=[" +
		release_info_account_type + ";" +
		release_info_production_domain +";" +
		release_info_debug_tools + ";" +
		release_info_client_version + ";" +
		release_info_protocol_version + ";" +
		deviceId + "]";
}

public function uncaughtErrorHandler(e : *) : void {
	trace("Main.uncaughtErrorHandler()");

	e.preventDefault(); 

	const popUp : PopUpException = new PopUpException();
	if (e.error is Error) { 
		const error : Error = e.error as Error; 
		popUp.setMessage("Uncaught Error: " + error.errorID + ", " + error.name + ", " + error.message);
	} else { 
		const errorEvent : ErrorEvent = e.error as ErrorEvent; 
		popUp.setMessage("Uncaught ErrorEvent: " + errorEvent.text);
	} 
	popUp.open(this, true);
	popUp.label.width = FlexGlobals.topLevelApplication.width * 2 / 3;
	PopUpManager.centerPopUp(popUp);
}

public function popUpGeneric(title : String, message : String, width_ratio : Number = 0.66) : void {
	const popUp : PopUpGeneric = new PopUpGeneric();
	popUp.setTitle(title);
	popUp.setMessage(message);
	popUp.open(this, true);
	popUp.label.width = FlexGlobals.topLevelApplication.width * width_ratio;
	PopUpManager.centerPopUp(popUp);
}

public function popUpError(where : String, error : String) : void {
	const popUp : PopUpException = new PopUpException();
	popUp.setMessage("Error at " + where + ": " + error);
	popUp.open(this, true);
	popUp.label.width = FlexGlobals.topLevelApplication.width * 2 / 3;
	PopUpManager.centerPopUp(popUp);
}

public function uncaughtException(where : String, error : Error) : void {
	trace("Main.uncaughtException()");

	const popUp : PopUpException = new PopUpException();
	popUp.setMessage("Uncaught Error at " + where + ": " + error.errorID + ", " + error.name + ", " + error.message);
	popUp.open(this, true);
	popUp.label.width = FlexGlobals.topLevelApplication.width * 2 / 3;
	PopUpManager.centerPopUp(popUp);
}

// Because the applicationComplete event occurs when the application layout is added to the displaylist, so until then stage is not available.
// pour catcher ce type d'exception :
// // cet import pour réferencer FlexGlobals
// import mx.core.*;
// try {
// ...
// } catch (e : Error) {
// FlexGlobals.topLevelApplication.uncaughtException("Main.applicationComplete()", e);
//   ou
// parentApplication.uncaughtException("Main.applicationComplete()", e);
// }
// retourner éventuellement une valeur logique dans le contexte
// return 0;
private function applicationComplete(event : FlexEvent) : void {
	if (FlexGlobals.topLevelApplication.systemManager.stage.loaderInfo.hasOwnProperty("uncaughtErrorEvents"))
		IEventDispatcher(FlexGlobals.topLevelApplication.systemManager.stage.loaderInfo["uncaughtErrorEvents"]).addEventListener("uncaughtError", uncaughtErrorHandler);

	// pour simuler la génération d'une erreur et tester la prise en compte de telles erreurs via un message dans un popup
	//	try {
	//		var x : FlexEvent = null;
	// erreur 1 : x est null et on référence une de ses propriétés
	//		trace(x.bubbles);
	// erreur 2 : doNotExist n'est pas une méthode de topLevelApplication
	//		FlexGlobals.topLevelApplication.doNotExist.centerPopUp();
	//	} catch (e : Error) {
	//		uncaughtException("Main.applicationComplete()", e);
	//	}
}

private function creationCompleteHandler(event : FlexEvent) : void { }

//public function checkLicense() : void {
//	// trace("Main.checkLicense()");
//	var lc : LicenseChecker = new LicenseChecker();
//	lc.addEventListener(ErrorEvent.ERROR, licenseErrorHandler);
//	lc.addEventListener(LicenseStatusEvent.STATUS, licenseResultHandler);
//	lc.checkLicense();
//}
//
//private function licenseErrorHandler(event : ErrorEvent) : void {
//	// trace("Main.licenseErrorHandler(): " + event.toString());
//}
//
//private function licenseResultHandler(event : LicenseStatusEvent) : void {
//	// trace("Main.licenseResultHandler(): status: " + event.status + " statusReason: " + event.statusReason);
//	
//	if (event.status == LicenseStatus.LICENSED) {
//		
//		//Application is licensed, allow the user to proceed.
//	} else if (event.status == LicenseStatus.NOT_LICENSED) {
//		
//		//Application is not licensed, don't allow to user to proceed.
//		switch (event.statusReason) { 
//			case LicenseStatusReason.CHECK_IN_PROGRESS:   
//				// There is already a license check in progress. 
//				break ; 
//			case LicenseStatusReason.INVALID_PACKAGE_NAME:
//				// Package Name of the application is not valid. 
//				break ; 
//			case LicenseStatusReason.INVALID_PUBLIC_KEY:   
//				// Public key specified is incorrect. 
//				break ; 
//			case LicenseStatusReason.MISSING_PERMISSION:   
//				// License Check permission in App descriptor is missing.
//				break ; 
//			case LicenseStatusReason.NON_MATCHING_UID:   
//				// UID of the application is not matching.
//				break ; 
//			case LicenseStatusReason.NOT_MARKET_MANAGED:   
//				// The application is not market managed.
//				break ; 
//			default: 
//				// Application is not licensed. 
//		} 
//	}
//}

// soft keyboards in mobiles applications: http://help.adobe.com/en_US/flex/mobileapps/WS82181550ec4a666a39bafe0312d9a274c00-8000.html
// Event handler to handle hardware keyboard keys.
protected function handleButtons(event:KeyboardEvent) : void {
	// trace("Main.handleButtons(): event.keyCode = " + event.keyCode);

	// Menu button
	if (event.keyCode == 16777234) {
		if (!tablet) viewnavigator_main.selectedIndex = 3;
		else tablet_viewnavigator_main.selectedIndex = 3;
		if (!tablet) view_config.popToFirstView();
		else tablet_view_config.popToFirstView();
	}
}

//private function scale(src : Class) : void {
////	var x : BitmapImage = BitmapImage;
//// 	x.scaleX = x.scaleY = x.scaleZ = FlexGlobals.topLevelApplication.applicationDPI / 640;
//var x : BitmapImage = src.
//}
	
public function setSkin() : void {
	if (new_skin) {
		skin_bgcolor = 0xe6e5d7;

		// modifier l'image : http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf60546-7ff2.html

		PictureScrew640 = PictureScrewNew640;
		TextStatus640 = TextStatusNew640;
		TextStatut640 = TextStatutNew640;
		TextMail640 = TextMailNew640;
		TextBrowser640 = TextBrowserNew640;
		TextConfig640 = TextConfigNew640;
		TextLangue640 = TextLangueNew640;
		TextCountry640 = TextCountryNew640;
		TextPorts640 = TextPortsNew640;
		TextLogin640 = TextLoginNew640;
		TextNewAccount640 = TextNewAccountNew640;
		TextIdent640 = TextIdentNew640;
		TextIdentite640 = TextIdentiteNew640;
		TextCreer640 = TextCreerNew640;
		TextConnecter640 = TextConnecterNew640;
	} else {
		skin_bgcolor = 0xd0d0d0;
		PictureScrew640 = PictureScrewOld640;
		TextStatus640 = TextStatusOld640;
		TextStatut640 = TextStatutOld640;
		TextMail640 = TextMailOld640;
		TextBrowser640 = TextBrowserOld640;
		TextConfig640 = TextConfigOld640;
		TextLangue640 = TextLangueOld640;
		TextCountry640 = TextCountryOld640;
		TextPorts640 = TextPortsOld640;
		TextLogin640 = TextLoginOld640;
		TextNewAccount640 = TextNewAccountOld640;
		TextIdent640 = TextIdentOld640;
		TextIdentite640 = TextIdentiteOld640;
		TextCreer640 = TextCreerOld640;
		TextConnecter640 = TextConnecterOld640;
	}
}

protected function initMail4HotSpot() : void {
	// tablette ssi (height>{650px@160dpi,900px@240dpi,1100@320dpi} && sqrt(width^2+height^2)/dpi>=8'')
	// trace(FlexGlobals.topLevelApplication.systemManager.screen.width);
	// trace(FlexGlobals.topLevelApplication.systemManager.screen.height);
//	trace(Math.sqrt(FlexGlobals.topLevelApplication.systemManager.screen.width * FlexGlobals.topLevelApplication.systemManager.screen.width +
//		FlexGlobals.topLevelApplication.systemManager.screen.height * FlexGlobals.topLevelApplication.systemManager.screen.height) /
//		FlexGlobals.topLevelApplication.applicationDPI);

//trace(FlexGlobals.topLevelApplication.applicationDPI);
	
	if ((Math.sqrt(FlexGlobals.topLevelApplication.systemManager.screen.width * FlexGlobals.topLevelApplication.systemManager.screen.width +
		FlexGlobals.topLevelApplication.systemManager.screen.height * FlexGlobals.topLevelApplication.systemManager.screen.height) /
		FlexGlobals.topLevelApplication.applicationDPI >= 7) &&
		((FlexGlobals.topLevelApplication.applicationDPI == 160 && FlexGlobals.topLevelApplication.systemManager.screen.height > 650) ||
		 (FlexGlobals.topLevelApplication.applicationDPI == 240 && FlexGlobals.topLevelApplication.systemManager.screen.height > 900) ||
		 (FlexGlobals.topLevelApplication.applicationDPI == 120 && FlexGlobals.topLevelApplication.systemManager.screen.height > 650) ||
		 (FlexGlobals.topLevelApplication.applicationDPI == 480 && FlexGlobals.topLevelApplication.systemManager.screen.height > 1300) ||
		 (FlexGlobals.topLevelApplication.applicationDPI == 640 && FlexGlobals.topLevelApplication.systemManager.screen.height > 1500) ||
		 (FlexGlobals.topLevelApplication.applicationDPI == 320 && FlexGlobals.topLevelApplication.systemManager.screen.height > 1100))) {
			tablet = true;
			switch (FlexGlobals.topLevelApplication.applicationDPI) {
				default:
				case 160:
					tablet_leftwidth = 346;
					break;

				case 120:
					tablet_leftwidth = 280;
					break;

				case 240:
					tablet_leftwidth = 480;
					break;
				
				case 320:
					tablet_leftwidth = 613;
					break;

				case 480:
					tablet_leftwidth = 880;
					break;

				case 640:
					tablet_leftwidth = 1147;
					break;
			}
			tablet_view_status.firstView = views.StatusView;
			tablet_view_mails.firstView = views.MailView;
			tablet_view_browser.firstView = views.BrowserView;
			tablet_view_config.firstView = views.ConfigurationView;
	} else {
		view_status.firstView = views.StatusView;
		view_mails.firstView = views.MailView;
		view_browser.firstView = views.BrowserView;
		view_config.firstView = views.ConfigurationView;
	}
	// trace("tablet: " + tablet);

	// tant qu'on n'aura pas débuggé le bug du browser qui ne supporte pas qu'on tourne l'écran
	// autre solution : dans Main-app.xml : positionner autoOrients
	// la solution est d'appeler BrowserView.resize() quand l'écran tourne
	FlexGlobals.topLevelApplication.systemManager.stage.setAspectRatio(tablet ? flash.display.StageAspectRatio.LANDSCAPE : flash.display.StageAspectRatio.PORTRAIT);
	FlexGlobals.topLevelApplication.systemManager.stage.autoOrients = false;

	// FlexGlobals.topLevelApplication.systemManager.stage.addEventListener("keyDown", handleButtons, false,1);
	FlexGlobals.topLevelApplication.systemManager.stage.addEventListener("keyUp", handleButtons, false, 1);

	net.fenyo.mail4hotspot.service.Application.initMail4HotSpot();
	VuMeter.init();

	browserViewPaddingTop = FlexGlobals.topLevelApplication.applicationDPI < 480 ? 10 : 14;
	switch (FlexGlobals.topLevelApplication.applicationDPI) {
		case 120:
			popupTitleHeight = 20;
			break;
		
		case 160:
			popupTitleHeight = 25;
			break;
		
		case 240:
			popupTitleHeight = 30;
			break;
		
		default:
		case 320:
			popupTitleHeight = 35;
			break;
		
		case 480:
			popupTitleHeight = 45;
			break;
		
		case 640:
			popupTitleHeight = 60;
			break;
	}
    /* apparemment, sur un véritable téléphone, la valeur qui fonctionne sous Windows doit être augmentée légèrement */
	popupTitleHeight += 8;

	// que se passe-t-il si le champ sent_date est mal ou non rempli ?
	var sort : Sort = new Sort();
	sort.fields = [ new SortField("sent_date", true, true), new SortField("received_date", true, true) ];
	mailsDataProvider.sort = sort;
	mailsDataProvider.refresh();

	var sort2 : Sort = new Sort();
	sort2.fields = [ new SortField("description", true, false), new SortField("local_port", true, false), new SortField("remote_host", true, false), new SortField("remote_port", true, false) ];
	portsDataProvider.sort = sort2;
	portsDataProvider.refresh();

	persistenceManager = new PersistenceManager();
	persistenceManager.load();

	switch (persistenceManager.getProperty("skinSelectedByUser")) {
		case 'grey':
			new_skin = false;
			break;
		case 'blue':
			new_skin = true;
			break;
		case null:
			// first start or when user has never selected a locale
			// the value set on new_skin at the beginning of this file applies
			break;
		default:
			trace("should not be there");
			break;
	}
	setSkin();

// tools.extTrace("Alex dns: " + DNSResolver.isSupported);
// tools.extTrace("Alex srv: " + ServerSocket.isSupported);

	if (!DNSResolver.isSupported) {
		// Android
		deviceId = tools.deviceId();
		tools.notificationInit();
// Alex
// tools.extTrace("Alex ceci est un test");
	} else {
		// PC
		if (persistenceManager.getProperty("deviceId") == null) {
			// first start
			deviceId = "PC-" + String(int(Math.random() * 100000000));
			persistenceManager.setProperty("deviceId", deviceId);
			persistenceManager.save();
		} else {
			deviceId = persistenceManager.getProperty("deviceId") as String;
		}
	}
	
	// for testing
	//	trace("dpi: " + FlexGlobals.topLevelApplication.applicationDPI);
	//	trace("uuid: " + persistenceManager.getProperty("uuid"));

	var factor : Number = FlexGlobals.topLevelApplication.applicationDPI / 640;
	var matrix : Matrix = new Matrix();
	matrix.scale(factor, factor);

	var pic : BitmapAsset;
	var newpic : BitmapData;
	
	if (!tablet) {
		pic = new PictureConfig640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		view_config.icon = newpic;			

		pic = new PictureMail640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		view_mails.icon = newpic;			

		pic = new PictureStatus640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		view_status.icon = newpic;			

		pic = new PictureBrowser640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		view_browser.icon = newpic;			
	} else {
		pic = new PictureConfig640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		tablet_view_config.icon = newpic;			
		
		pic = new PictureMail640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		tablet_view_mails.icon = newpic;			
		
		pic = new PictureStatus640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		tablet_view_status.icon = newpic;			
		
		pic = new PictureBrowser640() as BitmapAsset;
		newpic = new BitmapData(pic.width * factor, pic.height * factor, true, 0);
		newpic.draw(pic, matrix, null, null, null, true);
		tablet_view_browser.icon = newpic;			
	}
	normalFontSize = normalFontSize * FlexGlobals.topLevelApplication.applicationDPI / 240;
	labelFontSize = labelFontSize * FlexGlobals.topLevelApplication.applicationDPI / 240;
	smallLabelFontSize = smallLabelFontSize * FlexGlobals.topLevelApplication.applicationDPI / 240;
	buttonFontSize = buttonFontSize * FlexGlobals.topLevelApplication.applicationDPI / 240;
	headerFontSize = headerFontSize * FlexGlobals.topLevelApplication.applicationDPI / 240;

	const saved_mails : ArrayCollection = persistenceManager.getProperty("mailsDataProvider") as ArrayCollection;
	if (saved_mails != null) {
		for (var obj : Object in saved_mails) {
			var mail : MailItem = new MailItem(
				saved_mails[obj].from,
				saved_mails[obj].to,
				saved_mails[obj].cc,
				saved_mails[obj].message_id,
				saved_mails[obj].subject,
				saved_mails[obj].sent_date,
				saved_mails[obj].received_date,
				saved_mails[obj].content,
				saved_mails[obj].unread);
			mailsDataProvider.addItem(mail);
		}
	}

	var saved_ports : ArrayCollection = persistenceManager.getProperty("portsDataProvider") as ArrayCollection;
	if (saved_ports == null) {
		var _portsDataProvider : ListCollectionView = new ListCollectionView(new ArrayCollection());

		_portsDataProvider.addItem(new PortItem(8888, 80, "127.0.0.1", "Web Browser", true));
		_portsDataProvider.addItem(new PortItem(8080, 3128, "127.0.0.1", "Web Proxy (fast)", true));
		_portsDataProvider.addItem(new PortItem(8081, 3129, "127.0.0.1", "Web Proxy (full)", true));

		_portsDataProvider.addItem(new PortItem(8993, 993, "imap.gmail.com", "GMail: IMAP SSL", true));
		_portsDataProvider.addItem(new PortItem(8465, 465, "smtp.gmail.com", "GMail: SMTP SSL", true));

		_portsDataProvider.addItem(new PortItem(7993, 993, "imap-mail.outlook.com", "HotMail/Outlook.com: IMAP SSL", true));
		_portsDataProvider.addItem(new PortItem(7025, 25, "smtp.mail-outlook.com", "HotMail/Outlook.com: SMTP", true));

		_portsDataProvider.addItem(new PortItem(6993, 993, "imap.mail.yahoo.com", "YahooMail: IMAP SSL", true));
		_portsDataProvider.addItem(new PortItem(6465, 465, "smtp.mail.yahoo.com", "YahooMail: SMTP SSL", true));

		_portsDataProvider.addItem(new PortItem(5993, 993, "mail.messagingengine.com", "OperaMail/FastMail: IMAP SSL", true));
		_portsDataProvider.addItem(new PortItem(5995, 995, "mail.messagingengine.com", "OperaMail/FastMail: SMTP SSL", true));

		persistenceManager.setProperty("portsDataProvider", _portsDataProvider.list);
		persistenceManager.save();
	}
	
	saved_ports = persistenceManager.getProperty("portsDataProvider") as ArrayCollection;
	for (var obj2 : Object in saved_ports) {
		var port : PortItem = new PortItem(
			saved_ports[obj2].local_port,
			saved_ports[obj2].remote_port,
			saved_ports[obj2].remote_host,
			saved_ports[obj2].description,
			saved_ports[obj2].internal_use);
		portsDataProvider.addItem(port);
	}

	net.fenyo.mail4hotspot.service.HttpProxy.initHttpProxy(saved_ports);
	
	if (persistenceManager.getProperty("loggedIn") != null && persistenceManager.getProperty("loggedIn") != "") {
		popup_intro_appeared = true;
		popup_ad_can_appear = true;
		if (!tablet) {
			viewnavigator_login.visible = false;
			viewnavigator_main.visible = true;
		} else {
			viewnavigator_login.visible = false;
			tablet_splitviewnavigator.visible = true;
		}
	}
	
	// trace(flash.system.Capabilities.language); // returns "fr"
	// trace(ResourceManager.getInstance().localeChain[0]); // returns "fr_FR"
	switch (persistenceManager.getProperty("localeSelectedByUser")) {
		case 'en_US':
			ResourceManager.getInstance().localeChain = [ 'en_US', 'fr_FR' ];
			break;
		case 'fr_FR':
			ResourceManager.getInstance().localeChain = [ 'fr_FR', 'en_US' ];
			break;
		case null:
			// first start or when user has never selected a locale 
			break;
		default:
			trace("should not be there");
			break;
	}
	DnsQuerierFactory.initLocale();
}
