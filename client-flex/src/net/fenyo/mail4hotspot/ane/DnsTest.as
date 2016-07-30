// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.ane
{
	import flash.events.EventDispatcher;
	import flash.external.*;
	import flash.events.*;

	public class DnsTest // extends EventDispatcher
	{
		private var extContext : ExtensionContext;
		private var values : Vector.<int>;

		public function DnsTest() {
			extContext = ExtensionContext.createExtensionContext(
				"net.fenyo.mail4hotspot.ane.Dns", null);
			extContext.addEventListener(StatusEvent.STATUS, onStatus);
		}

		public function lookup(host : String) : void {
			extContext.call("lookup", host);
		}

		public function dispose() : void {
			extContext.dispose();
			// Clean up other resources that the Dns instance uses.
		}

		private function onStatus(event : StatusEvent) : void {
			if ((event.level == "status") && (event.code == "lookupCompleted")) {
				values = (Vector.<int>) (extContext.call("getValues"));
	//				dispatchEvent (new Event ("lookupCompleted") );
			}
		}
	}
}
