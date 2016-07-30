// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension
{
	import flash.events.*;
	import flash.external.*;
	import flash.utils.*;
	
	public class Tcp extends EventDispatcher
	{
		private var extContext : ExtensionContext;

		public function Tcp() {
			extContext = ExtensionContext.createExtensionContext("net.fenyo.extension.DnsExtension", null);
			if (extContext == null) trace("Tcp:Tcp(): extContext is null");
			else extContext.addEventListener(StatusEvent.STATUS, onStatus);
		}

		public function init(port1 : int) : void {
			if (extContext == null) trace("Tcp:init(): extContext is null");
			else extContext.call("tcpinit", port1);
		}

		public function readBytes(socket_id : int) : ByteArray {
			if (extContext == null) {
				trace("Tcp:readBytes(): extContext is null");
				return null;
			}

			const bar : ByteArray = (extContext.call("tcpreadbytes", socket_id) as ByteArray);
			return bar;
		}

		public function writeBytes(socket_id : int, data : ByteArray) : void {
			if (extContext == null) {
				trace("Tcp:writeBytes(): extContext is null");
				return;
			}
			
			extContext.call("tcpwritebytes", socket_id, data);
		}

		public function closeSocket(socket_id : int) : void {
			// trace("Tcp:closeSocket()");
			
			if (extContext == null) {
				trace("Tcp:closeSocket(): extContext is null");
				return;
			}
			
			extContext.call("tcpclosesocket", socket_id);
		}

		private function onStatus(event : StatusEvent) : void {
			dispatchEvent(event);
		}
	}
}
