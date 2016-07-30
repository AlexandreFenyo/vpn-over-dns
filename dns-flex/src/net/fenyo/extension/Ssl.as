// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension
{
	import flash.events.*;
	import flash.external.*;
	import flash.utils.*;
	
	public class Ssl extends EventDispatcher
	{
		private var extContext : ExtensionContext;
		
		public function Ssl() {
			extContext = ExtensionContext.createExtensionContext("net.fenyo.extension.DnsExtension", null);
			if (extContext == null) trace("Ssl:Ssl(): extContext is null");
			else extContext.addEventListener(StatusEvent.STATUS, onStatus);
		}
		
		public function get(url : String, query : String, timeout : int) : void {
			if (extContext == null) trace("Ssl:init(): extContext is null");
			else extContext.call("sslget", url, query, timeout);
		}
		
		private function onStatus(event : StatusEvent) : void {
			dispatchEvent(event);
		}
	}
}
