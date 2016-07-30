// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.ane
{
	import flash.events.*;
	import flash.external.*;
	import flash.net.dns.*;
	import flash.utils.*;
	
	import mx.core.*;
	
	import net.fenyo.extension.Dns;
	import net.fenyo.mail4hotspot.service.*;

	// PEUT ETRE des pbs de mémoire à cause du tableau resolvers

	public class DnsRelay {
		private var dns : Dns;
		private var resolvers : Array;

		public function cancel(resolver : XDNSResolver) : void {
			for (var host : String in resolvers)
				if (resolvers[host] == resolver) dns.cancel(host);
		}

		public function lookup(host : String, resolver : XDNSResolver) : void {
//{
//var _cnt : int = 0;
//for (var _host : String in resolvers) _cnt++;
//trace("DnsRelay.lookup(): cnt=" + _cnt);
//}

			try {
				if (resolvers[host] != undefined) trace("DnsRelay:lookup(): resolution already made: " + host);
				else {
					resolvers[host] = resolver;
					dns.lookup(host);
				}
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsRelay.lookup()", e);
			}
		}

		private function onStatus(event : StatusEvent) : void {
			try {
				
				var host : String = event.code;
				var info : String = event.level;
				
				if (resolvers[host] == null)
					trace("DnsRelay:onStatus(): no resolver waiting for this host");
				else {
					var resolver : XDNSResolver = (XDNSResolver) (resolvers[host]);
					delete resolvers[host];
					if (info.charAt(0) == ':') {
						var errorEvent : ErrorEvent = new ErrorEvent(ErrorEvent.ERROR, false, false, info, 0);
						resolver.errorHandler(errorEvent);
					} else {
						var rrs : Array = new Array();
						// trace("INFO=={" + info + "}");
						
						var ips : Array = info.split(";");
						for (var ipidx : Object in ips) {
							var record : ARecord = new ARecord();
							record.name = host;
							record.address = ips[ipidx];
							// trace("RR: name=" + record.name + " - address=" + ips[ipidx]);
							rrs.push(record);
						}
						var dnsResolverEvent : DNSResolverEvent = new DNSResolverEvent(DNSResolverEvent.LOOKUP, false, false, host, rrs);
						resolver.lookupHandler(dnsResolverEvent);
					}
				}

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsRelay.onStatus()", e);
			}
		}

		public function DnsRelay() {
			dns = new Dns();
			resolvers = new Array();
			dns.addEventListener(StatusEvent.STATUS, onStatus);
		}
	}
}
