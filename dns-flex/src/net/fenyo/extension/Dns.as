// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension
{
	import flash.events.*;
	import flash.events.*;
	import flash.external.*;

	public class Dns extends EventDispatcher
	{
		private var extContext : ExtensionContext;

		public function Dns()
		{
	  		extContext = ExtensionContext.createExtensionContext("net.fenyo.extension.DnsExtension", null);
			if (extContext == null) trace("Dns:Dns(): extContext is null");
			else extContext.addEventListener(StatusEvent.STATUS, onStatus);
		}

		public function lookup(host : String) : void {
			if (extContext == null) trace("ane:lookup(): extContext is null");
			else extContext.call("lookup", host);
		}

		public function cancel(host : String) : void {
			if (extContext == null) trace("ane:cancel(): extContext is null");
			else extContext.call("cancel", host);
		}

		private function onStatus(event : StatusEvent) : void {
			// code: host
			// level: RRs ou error string
//			trace("event.code = " + event.code);
//			trace("event.level = " + event.level);

			dispatchEvent(event);
		}
	}
}
