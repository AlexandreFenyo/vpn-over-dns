// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dns
{
	public class DnsQuerierFactory
	{
		import flash.events.*;
		import flash.net.ServerSocket;
		import flash.net.dns.*;
		
		import mx.core.*;
		import mx.resources.ResourceManager;

		private static var dnsQueriesForMail : Array = new Array();
		private static var dnsQueriesForWeb : Array = new Array();
		private static var dnsQueriesForRedirect : Array = new Array();

		public static const TYPE_MAIL : uint = 0;
		public static const TYPE_WEB : uint = 1;
		public static const TYPE_REDIRECT : uint = 2;

		private static var DnsQuerierFactory_simult : String;
		private static var DnsQuerierFactory_STATE_JUST_CREATED : String;
		private static var DnsQuerierFactory_STATE_GET_TICKET : String;
		private static var DnsQuerierFactory_STATE_SEND_MESSAGE : String;
		private static var DnsQuerierFactory_STATE_CHECK_MESSAGE : String;
		private static var DnsQuerierFactory_STATE_RECEIVE_MESSAGE : String;
		private static var DnsQuerierFactory_of : String;
		private static var DnsQuerierFactory_bytes : String;
		private static var DnsQuerierFactory_STATE_CLOSE_TICKET : String;
		private static var DnsQuerierFactory_STATE_TERMINATE : String;
		private static var DnsQuerierFactory_STATE_CANCELLED : String;
		private static var DnsQuerierFactory_no_message : String;

		public function DnsQuerierFactory() { }

		public static function initLocale() : void {
			DnsQuerierFactory_simult = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_simult');
			DnsQuerierFactory_STATE_JUST_CREATED = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_JUST_CREATED');
			DnsQuerierFactory_STATE_GET_TICKET = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_GET_TICKET');
			DnsQuerierFactory_STATE_SEND_MESSAGE = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_SEND_MESSAGE');
			DnsQuerierFactory_STATE_CHECK_MESSAGE = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_CHECK_MESSAGE');
			DnsQuerierFactory_STATE_RECEIVE_MESSAGE = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_RECEIVE_MESSAGE');
			DnsQuerierFactory_of = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_of');
			DnsQuerierFactory_bytes = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_bytes');
			DnsQuerierFactory_STATE_CLOSE_TICKET = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_CLOSE_TICKET');
			DnsQuerierFactory_STATE_TERMINATE = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_TERMINATE');
			DnsQuerierFactory_STATE_CANCELLED = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_STATE_CANCELLED');
			DnsQuerierFactory_no_message = ResourceManager.getInstance().getString('localizedContent', 'DnsQuerierFactory_no_message');
		}

		public static function debugMemory() : void {
			trace("DnsQuerierFactory.debugMemory():");
			trace("dnsQueriesForMail cnt: " + dnsQueriesForMail.length);
			trace("dnsQueriesForWeb cnt: " + dnsQueriesForWeb.length);
			trace("dnsQueriesForRedirect cnt: " + dnsQueriesForRedirect.length);
		}

		private static function flushMailQueries() : void {
			var _dnsQueriesForMail : Array = new Array();

			for (var i : uint = 0; i < dnsQueriesForMail.length; i++) {
				const dnsQuerier : DnsQuerier = dnsQueriesForMail[i];
				if (!dnsQuerier.isTerminated()) _dnsQueriesForMail.push(dnsQuerier);
			}

			dnsQueriesForMail = _dnsQueriesForMail;
		}

		private static function flushWebQueries() : void {
			var _dnsQueriesForWeb : Array = new Array();

			for (var i : uint = 0; i < dnsQueriesForWeb.length; i++) {
				const dnsQuerier : DnsQuerier = dnsQueriesForWeb[i];
				if (!dnsQuerier.isTerminated()) _dnsQueriesForWeb.push(dnsQuerier);
			}

			dnsQueriesForWeb = _dnsQueriesForWeb;
		}

		private static function flushRedirectQueries() : void {
			var _dnsQueriesForRedirect : Array = new Array();
			
			for (var i : uint = 0; i < dnsQueriesForRedirect.length; i++) {
				const dnsQuerier : DnsQuerier = dnsQueriesForRedirect[i];
				if (!dnsQuerier.isTerminated()) _dnsQueriesForRedirect.push(dnsQuerier);
			}
			
			dnsQueriesForRedirect = _dnsQueriesForRedirect;
		}

		public static function getNQueries() : int {
			return getMailCount() + getWebCount() + getRedirectCount();
		}

		public static function getRatio() : RatioInfo {
			try {

			const ratioInfo : RatioInfo = new RatioInfo();
			var messageTypes : String = "";

			flushMailQueries();
			flushWebQueries();
			flushRedirectQueries();

			var dnsQueries : Array = null;
			if (dnsQueriesForMail.length != 0) {
				messageTypes = "mail";
				dnsQueries = dnsQueriesForMail;
			}

			if (dnsQueriesForWeb.length != 0) {
				if (dnsQueries != null) {
					ratioInfo.ratio = -1;
					if (dnsQueriesForRedirect.length != 0) ratioInfo.message =
						(dnsQueriesForRedirect.length + dnsQueriesForMail.length + dnsQueriesForWeb.length) + " " +
					DnsQuerierFactory_simult + " (mail+web+redirect)";
					else ratioInfo.message =
						(dnsQueriesForRedirect.length + dnsQueriesForMail.length + dnsQueriesForWeb.length) + " " +
						DnsQuerierFactory_simult + " (mail+web)";
// il faudrait ne pas se baser sur DNSResolver.isSupported pour savoir si on est sur un mobile
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					return ratioInfo;
				} else messageTypes = "web";
				dnsQueries = dnsQueriesForWeb;
			}

			if (dnsQueriesForRedirect.length != 0) {
				if (dnsQueries != null) {
					ratioInfo.ratio = -1;
					ratioInfo.message =
						(dnsQueriesForRedirect.length + dnsQueriesForMail.length + dnsQueriesForWeb.length) + " " +
						DnsQuerierFactory_simult +
						" (" + messageTypes + "+redirect)";
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					return ratioInfo;
				} else messageTypes = "redirect";
				dnsQueries = dnsQueriesForRedirect;
			}

			// à partir d'ici, pas d'échanges simultanés de types différents (mail / web / redirect)
			if (dnsQueries == null || dnsQueries.length > 1) {
				ratioInfo.ratio = -1;
				if (dnsQueries == null) {
					ratioInfo.message = DnsQuerierFactory_no_message;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStop(ratioInfo.message);
				}		
				else {
					ratioInfo.message =
						(dnsQueriesForRedirect.length + dnsQueriesForMail.length + dnsQueriesForWeb.length) + " " +
						DnsQuerierFactory_simult +
						" (" + messageTypes +")";
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
				}
				return ratioInfo;
			}

			// à partir d'ici, un seul échange en cours
			const dnsQuerier : DnsQuerier = dnsQueries[0];
			ratioInfo.ratio = dnsQuerier.getRatio();
			const state : String = dnsQuerier.getState();
			switch (state) {
				case DnsQuerier.STATE_JUST_CREATED:
					ratioInfo.message = DnsQuerierFactory_STATE_JUST_CREATED;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					break;

				case DnsQuerier.STATE_GET_TICKET:
					ratioInfo.message = DnsQuerierFactory_STATE_GET_TICKET;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					break;

				case DnsQuerier.STATE_SEND_MESSAGE:
					ratioInfo.message = DnsQuerierFactory_STATE_SEND_MESSAGE;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					break;

				case DnsQuerier.STATE_CHECK_MESSAGE:
					DnsQuerierFactory_STATE_CHECK_MESSAGE;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					break;
					
				case DnsQuerier.STATE_RECEIVE_MESSAGE:
					const percent : int = ratioInfo.ratio / 10;
					ratioInfo.message = DnsQuerierFactory_STATE_RECEIVE_MESSAGE + ": " +
						percent + "% " + DnsQuerierFactory_of + " " + dnsQuerier.getReplyLength() + " " +
						DnsQuerierFactory_bytes;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					break;

				case DnsQuerier.STATE_CLOSE_TICKET:
					ratioInfo.message = DnsQuerierFactory_STATE_CLOSE_TICKET;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStart(ratioInfo.message);
					break;
				
				case DnsQuerier.STATE_TERMINATE:
					ratioInfo.message = DnsQuerierFactory_STATE_TERMINATE;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStop(ratioInfo.message);
					break;

				case DnsQuerier.STATE_CANCELLED:
					ratioInfo.message = DnsQuerierFactory_STATE_CANCELLED;
					if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStop(ratioInfo.message);
					break;
					
				default:
					trace("DnsQuerierFactory.cancel(): invalid state");
					ratioInfo.message = "";
					if (!ServerSocket.isSupported) FlexGlobals.topLevelApplication.tools.notificationStop(ratioInfo.message);
					break;
			}

			return ratioInfo;

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsQuerierFactory.errorHandler()", e);
			}
			if (!DNSResolver.isSupported) FlexGlobals.topLevelApplication.tools.notificationStop(ratioInfo.message);
			return ratioInfo;
		}

		public static function getMailCount() : uint {
			flushMailQueries();
			return dnsQueriesForMail.length;
		}

		public static function getWebCount() : uint {
			flushWebQueries();
			return dnsQueriesForWeb.length;
		}

		public static function getRedirectCount() : uint {
			flushRedirectQueries();
			return dnsQueriesForRedirect.length;
		}

		public static function cancelMailQueries() : void {
			for (var i : uint = 0; i < dnsQueriesForMail.length; i++) {
				const dnsQuerier : DnsQuerier = dnsQueriesForMail[i];
				dnsQuerier.cancel();
			}
			dnsQueriesForMail = new Array();
		}

		public static function cancelWebQueries() : void {
			for (var i : uint = 0; i < dnsQueriesForWeb.length; i++) {
				const dnsQuerier : DnsQuerier = dnsQueriesForWeb[i];
				dnsQuerier.cancel();
			}
			dnsQueriesForWeb = new Array();
		}

		public static function cancelRedirectQueries() : void {
			for (var i : uint = 0; i < dnsQueriesForRedirect.length; i++) {
				const dnsQuerier : DnsQuerier = dnsQueriesForRedirect[i];
				dnsQuerier.cancel();
			}
			dnsQueriesForRedirect = new Array();
		}

		public static function getDnsQuerier(type : uint) : DnsQuerier {
			var dnsQuerier : DnsQuerier = new DnsQuerier();
			if (type == TYPE_MAIL) dnsQueriesForMail.push(dnsQuerier);
			else if (type == TYPE_WEB) dnsQueriesForWeb.push(dnsQuerier);
			else if (type == TYPE_REDIRECT) dnsQueriesForRedirect.push(dnsQuerier);
			else trace("getDnsQuerier(): error: bad type");
			return dnsQuerier;
		}
	}
}
