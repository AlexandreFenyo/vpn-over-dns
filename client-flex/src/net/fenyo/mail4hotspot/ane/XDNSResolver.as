// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.ane
{
	import flash.events.*;
	import flash.external.*;
	import flash.net.dns.*;
	import flash.utils.*;
	import mx.core.*;
	import net.fenyo.mail4hotspot.service.*;
	
	public class XDNSResolver
	{
		private var cbErrorHandler : Function;
		private var cbLookupHandler : Function;

		private var dnsResolver : DNSResolver;

		private static var dnsRelay : DnsRelay;

		private function addRetriesIntoHost(host : String, nretry : int) : String {
			if (nretry == -1) return host;
			else return "retry-" + nretry + "." + host;
		}

		private function dropRetriesFromHost(host : String) : String {
			if (host.substr(0, 6) != "retry-") return host;
			else return host.substr(host.indexOf(".") + 1);
		}

		public function cancel() : void {
			if (DNSResolver.isSupported == true) {
				// nothing can be done to cancel a DNSResolver
			} else {
				dnsRelay.cancel(this);
			}
		}

		public function addEventListener(type:String, listener:Function) : void {
			if (type == DNSResolverEvent.LOOKUP) cbLookupHandler = listener;
			else if (type == ErrorEvent.ERROR) cbErrorHandler = listener;
			else trace("XDNSResolver:addEventListener should not be there");
		}

		public function removeEventListener(type:String, listener:Function) : void {
			if (type == DNSResolverEvent.LOOKUP) cbLookupHandler = null;
			else if (type == ErrorEvent.ERROR) cbErrorHandler = null;
			else trace("XDNSResolver:removeEventListener should not be there");
		}

		public function errorHandler(event : ErrorEvent) : void {
			if (cbErrorHandler != null) {
				VuMeter.statsLossDnsPacket();

				var xev : XEvent = new XEvent();
				xev.target = this;
				xev.text = "XDNSResolver error: " + event.text;
				cbErrorHandler(xev);
			} else trace("XDNSResolver:privateErrorHandler(): errorHandler is null");
		}

		public function lookupHandler(event : DNSResolverEvent) : void {
			try {

			if (cbLookupHandler != null) {
				VuMeter.statsReceiveDnsPacket();


				var xev : XEvent = new XEvent();
				xev.target = this;
				xev.resourceRecords = event.resourceRecords;
				for (var i : int = 0; i < xev.resourceRecords.length; i++)
					if (xev.resourceRecords[i] is ARecord) {
						var record : ARecord = (ARecord) (xev.resourceRecords[i]);
						record.name = dropRetriesFromHost(record.name);
					}
				cbLookupHandler(xev);
			} else trace("XDNSResolver:privateLookupHandler(): lookupHandler is null");

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("XDNSResolver.lookupHandler()", e);
			}
		}

		public function lookup(host : String, recordType : Class, nretry : int = -1) : void {
			try {

			if (recordType != ARecord) {
				trace("XDNSResolver:lookup(): should not be here");
				return;
			}

			VuMeter.statsSendDnsPacket();

			if (DNSResolver.isSupported == true) {
				dnsResolver.addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
				dnsResolver.addEventListener(ErrorEvent.ERROR, errorHandler);
				dnsResolver.lookup(addRetriesIntoHost(host, nretry), ARecord);
			} else {
				dnsRelay.lookup(addRetriesIntoHost(host, nretry), this);
			}

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("XDNSResolver.lookup()", e);
			}
		}

		public function XDNSResolver() {
			if (DNSResolver.isSupported == true) dnsResolver = new DNSResolver();
			else if (dnsRelay == null) dnsRelay = new DnsRelay();
		}
	}
}
