// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension
{
	import flash.events.*;
	import flash.events.*;
	import flash.external.*;
	
	public class Tools extends EventDispatcher
	{
		private var extContext : ExtensionContext;
		private var notifState : Boolean = false;
		private var lastNotificationString : String = "";
		
		public function Tools()
		{
			extContext = ExtensionContext.createExtensionContext("net.fenyo.extension.DnsExtension", null);
			if (extContext == null) trace("Tools:Tools(): extContext is null");
			else extContext.addEventListener(StatusEvent.STATUS, onStatus);
		}
		
		public function deviceId() : String {
			if (extContext == null) {
				trace("Tools.deviceId(): extContext is null");
				return null;
			}
			else return extContext.call("deviceid") as String;
		}

		public function extTrace(msg : String) : String {
			if (extContext == null) {
				trace("Tools.trace(): extContext is null");
				return null;
			}
			else return extContext.call("trace", msg) as String;
		}

		public function notificationInit() : void {
//extTrace("Alex NotificationInit");
			// if (extContext != null) extContext.call("trace", "notificationInit");
			if (extContext == null)
				trace("Tools.notificationInit(): extContext is null");
			else extContext.call("notificationinit");
		}

		public function notificationStart(msg : String) : void {
//extTrace("Alex NotificationStart");
			// if (extContext != null) extContext.call("trace", "notificationStart");
			if (notifState == true && lastNotificationString == msg) return;
			lastNotificationString = msg;
			notifState = true;
			if (extContext == null)
				trace("Tools.notificationStart(): extContext is null");
			else extContext.call("notificationstart", msg);
		}

		public function notificationStop(msg : String) : void {
//extTrace("Alex NotificationStop");
			// if (extContext != null) extContext.call("trace", "notificationStop");
			if (notifState == false  && lastNotificationString == msg) return;
			lastNotificationString = msg;
			notifState = false;
			if (extContext == null)
				trace("Tools.notificationStop(): extContext is null");
			else extContext.call("notificationstop", msg);
		}
		
		private function onStatus(event : StatusEvent) : void {
//extTrace("Alex NotificationOnStatus");
			// code: host
			// level: RRs ou error string
			//			trace("event.code = " + event.code);
			//			trace("event.level = " + event.level);
			
			dispatchEvent(event);
		}
	}
}
