// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dns
{
	import flash.events.*;
	import flash.net.dns.*;
	import flash.utils.*;

	import mx.core.*;

	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.CharacterUtil;
	
	import net.fenyo.mail4hotspot.ane.XDNSResolver;
	import net.fenyo.mail4hotspot.ane.XEvent;
	import net.fenyo.mail4hotspot.service.*;
	import net.fenyo.mail4hotspot.tools.*;

// flash.utils.Timer : pour réduire artificiellement le timeout des requêtes DNS

public class DnsQuerier {
		private static var PROTOCOL_VERSION : uint;
		private static var TLD : String;

		private static const MAX_RETRIES : uint = 20 /* 500 */;

		public static const STATE_JUST_CREATED : String = "STATE_JUST_CREATED";
		public static const STATE_GET_TICKET : String = "STATE_GET_TICKET";
		public static const STATE_SEND_MESSAGE : String = "STATE_SEND_MESSAGE";
		public static const STATE_CHECK_MESSAGE : String = "STATE_CHECK_MESSAGE";
		public static const STATE_RECEIVE_MESSAGE : String = "STATE_RECEIVE_MESSAGE";
		public static const STATE_CLOSE_TICKET : String = "STATE_CLOSE_TICKET";
		public static const STATE_TERMINATE : String = "STATE_TERMINATE";
		public static const STATE_CANCELLED : String = "STATE_CANCELLED";
		private var state : String = STATE_JUST_CREATED;

		private var binary_message : Boolean = false;

		private var message_string : String;
		private var message_bytes : ByteArray;
		private var callback_called : Boolean = false;
		private var callback : Function;

		// getting ticket
		private var dns_resolver : XDNSResolver;
		private var current_rr : String;
		private var ticket : String;
		private var retry : uint;

		// sending request
		// 63 caractères dans un label d'un nom DNS, et 2 caractères par octet (codage hexadécimal), et 3 caractères réservés pour "bf-"
		private static const MAX_REQUEST_LEN : uint = (63 - 3) / 2;
		private var nrequests : uint;
		private var request_dns_resolvers : Array = [];
		private var request_current_rrs : Array = [];
		private var request_retries : Array = [];
		private var request_acks : Array = [];

		// checking reply
		private var check_dns_resolver : XDNSResolver;
		private var check_current_rr : String;
		private var check_retry : uint;
		private var reply_length : uint;

		// receiving reply
		// marche pas avec 192, ni 128, on met 64 et ça marche => c'est dû à la taille du paquet de réponse : cf analyse dans DnsListener.java (côté serveur JEE)
		// avec 64 ça laisse peu de marge (notamment si on rajoute des NS secondaires à mail4hotspot.fenyo.net, cf l'analyse)
		// donc on prend 32
		// finalement, on prend peu de marge pour avoir un bon débit (12/8/2012)
		// les captures wireshark sont dans mail4hotspot - general\captures\MAX_REPLY_LEN_{32,64}.cap
		// suite a pb a l'hotel et a la vauzelle, on passer a 48
		// private static const MAX_REPLY_LEN : uint = 63;
		private static const MAX_REPLY_LEN : uint = 48;
// pour marcher avec SFR en cas de limite de crédit:
//		private static const MAX_REPLY_LEN : uint = 36;

		private var nreplies : uint;
		private var reply_dns_resolvers : Array = [];
		private var reply_current_rrs : Array = [];
		private var reply_current_rrs_map : Array = [];
		private var reply_retries : Array = [];
		private var reply_bytes : Array = [];
		private var reply_acks : Array = [];
		private var reply_pos : Array = [];
		private var reply_len : Array = [];

		// closing message
		private var close_dns_resolver : XDNSResolver;
		private var close_current_rr : String;
		private var close_retry : uint;

		public function DnsQuerier() {
			PROTOCOL_VERSION = Main.release_info_protocol_version;
			if (Main.release_info_production_domain == true) TLD = "tun.vpnoverdns.com";
			else TLD = "mail4hotspot.fenyo.net";
		}

		public function getState() : String {
			return state;
		}

		public function getReplyLength() : uint {
			return reply_length;
		}

		public function getRatio() : int {
			try {

			switch (state) {
				case STATE_JUST_CREATED:
				case STATE_GET_TICKET:
				case STATE_SEND_MESSAGE:
				case STATE_CHECK_MESSAGE:
					return 0;
				
				case STATE_RECEIVE_MESSAGE:
					var cnt : int = 0;
					for (var i : int = 0; i < nreplies; i++)
						if (reply_acks[i] == true) cnt++;
					return (1000 * cnt) / nreplies;
				
				case STATE_CLOSE_TICKET:
				case STATE_TERMINATE:
				case STATE_CANCELLED:
					return 1000;
				
				default:
					trace("DnsQuerierFactory.cancel(): invalid state");
					return 0;
			}

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsQuerier.getRatio()", e);
			}
			return 0;
		}

		public function cancel() : void {
			var i : int;

			switch (state) {
				case STATE_JUST_CREATED:
					break;
				
				case STATE_GET_TICKET:
					dns_resolver.cancel();
					break;
				
				case STATE_SEND_MESSAGE:
					for (i = 0; i < request_dns_resolvers.length; i++) request_dns_resolvers[i].cancel();
					break;
				
				case STATE_CHECK_MESSAGE:
					check_dns_resolver.cancel();
					break;
				
				case STATE_RECEIVE_MESSAGE:
					for (i = 0; i < reply_dns_resolvers.length; i++) reply_dns_resolvers[i].cancel();
					break;
				
				case STATE_CLOSE_TICKET:
					close_dns_resolver.cancel();
					break;
				
				case STATE_TERMINATE:
					break;
				
				case STATE_CANCELLED:
					break;

				default:
					trace("DnsQuerierFactory.cancel(): invalid state");
					break;
			}

			state = STATE_CANCELLED;
		}

		public function isTerminated() : Boolean {
			return ((state == STATE_CANCELLED) || (state == STATE_TERMINATE));
		}

//		private function errorHandler(errorEvent : ErrorEvent) : void {
		private function errorHandler(errorEvent : XEvent) : void {
			try {
			trace("DnsQuerierFactory.errorHandler(): "+ errorEvent.text);

			switch (state) {
			case STATE_CANCELLED:
				return;

			case STATE_GET_TICKET:
				if (errorEvent.target == dns_resolver) {
					if (retry > 0) retry--;
					if (retry > 0) {
						trace("DnsQuerierFactory.errorHandler(): STATE_GET_TICKET retrying (" + retry + ") -> " + current_rr);
						dns_resolver.lookup(GenericTools.simulateIPLoss(current_rr), ARecord, retry);
					}
					else {
						trace("DnsQuerierFactory.errorHandler(): STATE_GET_TICKET retry is null");
						if (callback_called == false) {
							state = STATE_TERMINATE;
							callback_called = true;
							if (binary_message == false) callback(null);
							else callback(null, null);
						}
					}
				} else {
					trace("DnsQuerierFactory.errorHandler(): STATE_GET_TICKET invalid dns resolver");
					// on n'appelle pas callback(null) car il se peut que cette erreur ne nous concerne pas
				}
				break;

			case STATE_SEND_MESSAGE:
				const request_resolver_idx : uint = request_dns_resolvers.indexOf(errorEvent.target);
				if (request_resolver_idx != -1) {
					if (request_retries[request_resolver_idx] > 0) request_retries[request_resolver_idx]--;
					if (request_acks[request_resolver_idx] == false) {
						if (request_retries[request_resolver_idx] > 0) {
							trace("DnsQuerierFactory.errorHandler(): STATE_SEND_MESSAGE retrying (" + request_retries[request_resolver_idx] + ") -> " + request_current_rrs[request_resolver_idx]);
							request_dns_resolvers[request_resolver_idx].lookup(GenericTools.simulateIPLoss(request_current_rrs[request_resolver_idx]), ARecord, request_retries[request_resolver_idx]);
						} else {
							trace("DnsQuerierFactory.errorHandler(): STATE_SEND_MESSAGE retries is null");
							for (var i : uint = 0; i < request_dns_resolvers.length; i++) {
								((XDNSResolver) (request_dns_resolvers[i])).removeEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
								// NE PAS supprimer l'event listener pour les erreurs, car des erreurs peuvent intervenir par la suite : on ne peut pas faire de cancel sur le DNSResolver
								// donc NE PAS écrire : ((XDNSResolver) (request_dns_resolvers[i])).removeEventListener(ErrorEvent.ERROR, errorHandler);
							}
							if (callback_called == false) {
								state = STATE_TERMINATE;
								if (binary_message == false) callback(null);
								else callback(null, null);
								callback_called = true;
							}
						}
					} else {
						trace("DnsQuerierFactory.errorHandler(): STATE_SEND_MESSAGE dns resolver already acknowledged");
						// on n'appelle pas callback(null) car cette résolution n'est plus utile, on laisse le process de résolution complet continuer
					}
				} else {
					trace("DnsQuerierFactory.errorHandler(): STATE_SEND_MESSAGE invalid dns resolver");
					// on n'appelle pas callback(null) car il se peut que cette erreur ne nous concerne pas
				}
				break;

			case STATE_CHECK_MESSAGE:
				if (errorEvent.target == check_dns_resolver) {
					if (check_retry > 0) check_retry--;
					if (check_retry > 0) {
						check_current_rr = qualify("ck-" + GenericTools.padNumber(check_retry) + "." + ticket);
						trace("DnsQuerierFactory.errorHandler(): STATE_CHECK_MESSAGE retrying (" + check_retry + ") -> " + check_current_rr);
						check_dns_resolver.lookup(GenericTools.simulateIPLoss(check_current_rr), ARecord, check_retry);
					} else {
						trace("DnsQuerierFactory.errorHandler(): STATE_CHECK_MESSAGE retry is null");
						((XDNSResolver) (check_dns_resolver)).removeEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
						if (callback_called == false) {
							state = STATE_TERMINATE;
							callback_called = true;
							if (binary_message == false) callback(null);
							else callback(null, null);
						}
					}
				} else {
					trace("DnsQuerierFactory.errorHandler(): STATE_CHECK_MESSAGE invalid dns resolver");
					// on n'appelle pas callback(null) car il se peut que cette erreur ne nous concerne pas
				}
				break;

			case STATE_RECEIVE_MESSAGE:
				const reply_resolver_idx : uint = reply_dns_resolvers.indexOf(errorEvent.target);
				if (reply_resolver_idx != -1) {
					if (reply_retries[reply_resolver_idx] > 0) reply_retries[reply_resolver_idx]--;
					if (reply_acks[reply_resolver_idx] == false) {
						if (reply_retries[reply_resolver_idx] > 0) {
							trace("DnsQuerierFactory.errorHandler(): STATE_RECEIVE_MESSAGE retrying (" + reply_retries[reply_resolver_idx] + ") -> " + reply_current_rrs[reply_resolver_idx]);
							reply_dns_resolvers[reply_resolver_idx].lookup(GenericTools.simulateIPLoss(reply_current_rrs[reply_resolver_idx]), ARecord, reply_retries[reply_resolver_idx]);
						} else {
							trace("DnsQuerierFactory.errorHandler(): STATE_RECEIVE_MESSAGE retries is null");
							for (i = 0; i < reply_dns_resolvers.length; i++) {
								((XDNSResolver) (reply_dns_resolvers[i])).removeEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
								// NE PAS supprimer l'event listener pour les erreurs, car des erreurs peuvent intervenir par la suite : on ne peut pas faire de cancel sur le DNSResolver
								// donc NE PAS écrire : ((XDNSResolver) (reply_dns_resolvers[i])).removeEventListener(ErrorEvent.ERROR, errorHandler);
							}
							if (callback_called == false) {
								state = STATE_TERMINATE;
								if (binary_message == false) callback(null);
								else callback(null, null);
								callback_called = true;
							}
						}
					} else {
						trace("DnsQuerierFactory.errorHandler(): STATE_RECEIVE_MESSAGE dns resolver already acknowledged");
						// on n'appelle pas callback(null) car cette résolution n'est plus utile, on laisse le process de résolution complet continuer
					}
				} else {
					trace("DnsQuerierFactory.errorHandler(): STATE_RECEIVE_MESSAGE invalid dns resolver");
					// on n'appelle pas callback(null) car il se peut que cette erreur ne nous concerne pas
				}
				break;

			case STATE_CLOSE_TICKET:
				if (errorEvent.target == close_dns_resolver) {
					if (close_retry > 0) close_retry--;
					if (close_retry > 0) {
						trace("DnsQuerierFactory.errorHandler(): STATE_CLOSE_MESSAGE retrying (" + close_retry + ") -> " + close_current_rr);
						check_dns_resolver.lookup(GenericTools.simulateIPLoss(close_current_rr), ARecord, close_retry);
					} else {
						((XDNSResolver) (close_dns_resolver)).removeEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
						trace("DnsQuerierFactory.errorHandler(): STATE_CLOSE_MESSAGE retry is null");
						if (callback_called == false) {
							state = STATE_TERMINATE;
							callback_called = true;
							if (binary_message == false) callback(null);
							else callback(null, null);
						}
					}
				} else {
					trace("DnsQuerierFactory.errorHandler(): STATE_CLOSE_TICKET invalid dns resolver");
					// on n'appelle pas callback(null) car il se peut que cette erreur ne nous concerne pas
				}
				break;

			default:
				trace("DnsQuerierFactory.errorHandler(): invalid state");
				// on n'appelle pas callback(null) car il se peut que cette erreur ne nous concerne pas
				break;
			}
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsQuerier.errorHandler()", e);
			}
		}

//		private function lookupHandler(event : DNSResolverEvent) : void {
		private function lookupHandler(event : XEvent) : void {
			try {
			// GenericTools.profiler("lookupHandler() ENTER", false);

			if (state == STATE_CANCELLED) return;
			
			var answer : Array = [];
			var current_request_or_reply_rr : String;

			// on parcourt tous les RR de la réponse pour déterminer le tableau d'octets renvoyé
			for (var i : uint = 0; i < event.resourceRecords.length; i++) {
				if (event.resourceRecords[i] is ARecord) {
					const rr_a : ARecord = event.resourceRecords[i];
					var bad_fqdn : Boolean = true;
					switch (state) {
						case STATE_GET_TICKET:
							if (rr_a.name.toLowerCase() == current_rr.toLowerCase()) bad_fqdn = false;
							break;

						case STATE_SEND_MESSAGE:
							for each (var rr : String in request_current_rrs)
								if (rr_a.name.toLowerCase() == rr.toLowerCase()) {
									current_request_or_reply_rr = rr;
									bad_fqdn = false;
								}
							break;

						case STATE_CHECK_MESSAGE:
							if (rr_a.name.toLowerCase() == check_current_rr.toLowerCase()) bad_fqdn = false;
							break;

						case STATE_RECEIVE_MESSAGE:
							if (reply_current_rrs_map[rr_a.name.toLowerCase()] != null) {
								bad_fqdn = false;
								current_request_or_reply_rr = reply_current_rrs[reply_current_rrs_map[rr_a.name.toLowerCase()]];
							}

							break;

						case STATE_CLOSE_TICKET:
							if (rr_a.name.toLowerCase() == close_current_rr.toLowerCase()) bad_fqdn = false;
							break;
					}

					if (bad_fqdn) trace("DnsQuerier.lookupHandler(): bad FQDN");
					else {
						const X : uint = rr_a.address.split('.')[0];
						const Y : uint = rr_a.address.split('.')[1];
						const Z : uint = rr_a.address.split('.')[2];
						const T : uint = rr_a.address.split('.')[3];
						const NBYTES : uint = X >> 6;
						const OFFSET : uint = 3 * (X & ((1 << 6) - 1));
						// trace(X + "-" + Y + "-" + Z +"-" + T); 

						switch (NBYTES) {
							case 0:
								trace("DnsQuerier.lookupHandler(): 0 bytes valid");
								break;

							case 3:
								answer[OFFSET + 2] = T;

							case 2:
								answer[OFFSET + 1] = Z;

							case 1:
								answer[OFFSET] = Y;
						}
					}
				} else {
					trace("DnsQuerier.lookupHandler(): not an A RR");
				}
			}

			// for (i = 0; i < answer.length; i++) trace("ARRAY[" + i + "]= " + answer[i]);

			if (answer.length == 0) {
				trace("DnsQuerier.lookupHandler(): answer is empty");
				return;
			}

			VuMeter.statsReceiveEncapsulatedBytes(answer.length);

			switch (state) {
				case STATE_GET_TICKET:
					if (answer.length == 2 && answer[0] == "E".charCodeAt(0)) {
						trace("DnsQuerier.lookupHandler(): STATE_GET_TICKET answered with error number " + answer[1]);
					} else {
						ticket = "id-" + GenericTools.padNumber((answer[0] << 16) + (answer[1] << 8) + answer[2]);
						// trace("DnsQuerier.lookupHandler(): received ticket " + ticket);
						state = STATE_SEND_MESSAGE;

						const message_ba : ByteArray = new ByteArray();
						// on pourrait optimiser sachant qu'on a déjà fait cette opération pour déterminer la taille du message à envoyer

						if (binary_message == false) message_ba.writeByte(0);
						else {
							const tmpbar : ByteArray = new ByteArray();
							tmpbar.writeUTFBytes(message_string);
							if (tmpbar.length > 255) trace("lookupHandler error: UTF-8 part too long");
							message_ba.writeByte(tmpbar.length);
						}

						message_ba.writeUTFBytes(message_string);
						if (binary_message == true) message_ba.writeBytes(message_bytes);

//if (binary_message == true) {
//	trace("binary message: message_bytes length = " + message_bytes.length);
//}

						message_ba.position = 0;
						var message_hexa : String = "";
						while (message_ba.bytesAvailable) {
							var code : int = message_ba.readByte();
							message_hexa += GenericTools.d2h((code < 0) ? (code + 256) : code);
						}

						nrequests = (message_hexa.length / 2 - 1) / MAX_REQUEST_LEN + 1;
						for (i = 0; i < nrequests; i++) {
							request_current_rrs[i] = qualify("bf-" + message_hexa.substr(2 * i * MAX_REQUEST_LEN,
								(i < nrequests - 1) ? (2 * MAX_REQUEST_LEN) : (message_hexa.length - 2 * i * MAX_REQUEST_LEN)) +
								".wr-" + GenericTools.padNumber(i * MAX_REQUEST_LEN) + "." + ticket);
							request_retries[i] = MAX_RETRIES;
							request_dns_resolvers[i] = new XDNSResolver();
							request_dns_resolvers[i].addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
							request_dns_resolvers[i].addEventListener(ErrorEvent.ERROR, errorHandler);
							request_dns_resolvers[i].lookup(GenericTools.simulateIPLoss(request_current_rrs[i]), ARecord);
							request_acks[i] = false;

//							trace("request[" + i + "] = " + request_current_rrs[i]);
						}
					}
					break;

				case STATE_SEND_MESSAGE:
					if (answer.length == 2 && answer[0] == "E".charCodeAt(0) && answer[1] != 0) {
						trace("DnsQuerier.lookupHandler(): STATE_SEND_MESSAGE answered with error number " + answer[1]);
					} else if (answer.length != 2 || answer[0] != "E".charCodeAt(0)) {
						trace("DnsQuerier.lookupHandler(): STATE_SEND_MESSAGE bad answer");
					} else {
//						trace("DnsQuerier.lookupHandler(): ack of sent message:" + current_request_or_reply_rr);
						request_acks[request_current_rrs.indexOf(current_request_or_reply_rr)] = true;
						if (request_acks.indexOf(false) == -1) {
//							trace("DnsQuerier.lookupHandler(): REQUEST ACK COMPLETED");
							state = STATE_CHECK_MESSAGE;
							check_retry = MAX_RETRIES;
							check_current_rr = qualify("ck-" + GenericTools.padNumber(check_retry) + "." + ticket);
							check_dns_resolver = new XDNSResolver();
							check_dns_resolver.addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
							check_dns_resolver.addEventListener(ErrorEvent.ERROR, errorHandler);
							check_dns_resolver.lookup(GenericTools.simulateIPLoss(check_current_rr), ARecord);
//							trace("check request = " + check_current_rr);
						}
					}
					break;

				case STATE_CHECK_MESSAGE:
					switch (answer.length) {
						case 2:
							if (answer[0] == "E".charCodeAt(0)) {
								if (answer[1] == 10) {
									// trace("DnsQuerier.lookupHandler(): STATE_CHECK_MESSAGE reply not ready (check_retry=" + check_retry + ")");
									// pour faire apparaître : chrome sur un gros site comme www.enst.fr ou www.lefigaro.com par ex
									// c'est quand le site distant ne renvoie rien, donc on boucle assez rapidement pour réessayer et si on atteint check_retry essais, on arrête
									// => optimisation : ne pas boucler immédiatement mais lancer un timer pour ensuite boucler, après environ 200 ms ou 500 ms
									// autre pb potentiel à régler : on décrémente check_retry, donc il faut qu'il soit grand au départ, sinon on ne bouclerait pas longtemps
									// ca pose aussi le pb d'un service TCP dans lequel il est normal qu'on n'ai pas de réponse pendant un moment, genre telnet au lieu de ssh
									
									if (check_retry > 0) check_retry--;
									if (check_retry > 0) {
										check_current_rr = qualify("ck-" + GenericTools.padNumber(check_retry) + "." + ticket);
										// trace("DnsQuerierFactory.errorHandler(): STATE_CHECK_MESSAGE retrying (" + check_retry + ") -> " + check_current_rr);
										check_dns_resolver.lookup(GenericTools.simulateIPLoss(check_current_rr), ARecord, check_retry);
									} else {
										// trace("DnsQuerierFactory.errorHandler(): STATE_CHECK_MESSAGE retry is null");
										((XDNSResolver) (check_dns_resolver)).removeEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
										if (callback_called == false) {
											state = STATE_TERMINATE;
											callback_called = true;
											// pb : le null n'est pas pris en compte, ca plante en exception
											if (binary_message == false) callback(null);
											else callback(null, null);
										}
									}
									
									
									
								}
								else trace("DnsQuerier.lookupHandler(): STATE_CHECK_MESSAGE error " + answer[1]);
							} else trace("DnsQuerier.lookupHandler(): STATE_CHECK_MESSAGE bad answer");
							break;

						case 4:
							if (answer[0] == "L".charCodeAt(0)) {
								reply_length = (answer[1] << 16) + (answer[2] << 8) + answer[3];
//								trace("DnsQuerier.lookupHandler(): STATE_CHECK_MESSAGE reply length is " + reply_length);
								state = STATE_RECEIVE_MESSAGE;

								nreplies = (reply_length - 1) / MAX_REPLY_LEN + 1;
								for (i = 0; i < nreplies; i++) {
									reply_pos[i] = i * MAX_REPLY_LEN;
									reply_len[i] = (i < nreplies - 1) ? MAX_REPLY_LEN : (reply_length - i * MAX_REPLY_LEN);
									reply_current_rrs[i] = qualify("ln-" + GenericTools.padNumber(reply_len[i], 3) +
										".rd-" + GenericTools.padNumber(reply_pos[i]) + "." + ticket);
									reply_current_rrs_map[(reply_current_rrs[i] as String).toLowerCase()] = i;
									reply_retries[i] = MAX_RETRIES;
									reply_dns_resolvers[i] = new XDNSResolver();
									reply_dns_resolvers[i].addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
									reply_dns_resolvers[i].addEventListener(ErrorEvent.ERROR, errorHandler);
									reply_acks[i] = false;
									reply_dns_resolvers[i].lookup(GenericTools.simulateIPLoss(reply_current_rrs[i]), ARecord);
									
//									trace("reply[" + i + "] = " + reply_current_rrs[i]);
								}

							} else trace("DnsQuerier.lookupHandler(): STATE_CHECK_MESSAGE bad answer");
							break;

						default:
							trace("DnsQuerier.lookupHandler(): STATE_CHECK_MESSAGE bad answer");
							break;
					}
					break;

				case STATE_RECEIVE_MESSAGE:
//					trace("DnsQuerier.lookupHandler(): reply message:" + current_request_or_reply_rr);
					var reply_idx : uint = reply_current_rrs.indexOf(current_request_or_reply_rr);
					if (reply_idx != -1 || answer.length != reply_len[reply_idx]) {
						if (reply_acks[reply_idx] == false) {
							for (i = 0; i < reply_len[reply_idx]; i++) reply_bytes[reply_pos[reply_idx] + i] = answer[i];
							reply_acks[reply_idx] = true;
							if (reply_acks.indexOf(false) == -1) {
//								trace("DnsQuerier.lookupHandler(): REPLY ACK COMPLETED");
								state = STATE_CLOSE_TICKET;
								close_retry = MAX_RETRIES;
								close_current_rr = qualify("ac." + ticket);
								close_dns_resolver = new XDNSResolver();
								close_dns_resolver.addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
								close_dns_resolver.addEventListener(ErrorEvent.ERROR, errorHandler);
								close_dns_resolver.lookup(GenericTools.simulateIPLoss(close_current_rr), ARecord);

								const _reply_bytes : ByteArray = new ByteArray();
								for (i = 0; i < reply_bytes.length; i++) _reply_bytes[i] = reply_bytes[i];
								
								// pour tester la généation d'un IOError : ca arrive si on redémarre l'appli sous tomcat au milieu d'un chargement
								// _reply_bytes[5] = 12;
								_reply_bytes.uncompress();

								if (binary_message == false) {
									const reply_ba : ByteArray = new ByteArray();
									for (i = 0; i < _reply_bytes.length; i++) reply_ba[i] = _reply_bytes[i];
									const reply_string : String = reply_ba.readMultiByte(reply_ba.bytesAvailable, "UTF-8");

									callback(reply_string);
								} else {
//trace("REPLY BYTES len: " + reply_bytes.length);
//trace("1er octet: " + reply_bytes[0]);
									const reply_ba_string_part : ByteArray = new ByteArray();
									const string_part_len : int = _reply_bytes[0];
									for (i = 0; i < string_part_len; i++) reply_ba_string_part[i] = _reply_bytes[i + 1];
									const reply_string_part : String = reply_ba_string_part.readMultiByte(reply_ba_string_part.bytesAvailable, "UTF-8");

									const reply_data_part : ByteArray = new ByteArray();
									for (i = 0; i < _reply_bytes.length - string_part_len - 1; i++) reply_data_part[i] = _reply_bytes[i + string_part_len + 1];
//trace("reply_bytes.length - string_part_len - 1 = " + (reply_bytes.length - string_part_len - 1));
									callback(reply_string_part, reply_data_part);
								}

//								trace("close request = " + close_current_rr);
							}
						}
					} else {
						if (answer.length != reply_len[reply_idx]) trace("DnsQuerierFactory.lookupHandler(): STATE_RECEIVE_MESSAGE invalid length");
						else trace("DnsQuerierFactory.lookupHandler(): STATE_RECEIVE_MESSAGE invalid dns resolver");
					}
					break;

				case STATE_CLOSE_TICKET:
					if (answer.length == 2 && answer[0] == "E".charCodeAt(0) && (answer[1] == 0 || answer[1] == 14)) {
						state = STATE_TERMINATE;
//						trace("DnsQuerierFactory.lookupHandler(): STATE_CLOSE_TICKET terminated");
					} else trace("DnsQuerierFactory.lookupHandler(): STATE_CLOSE_MESSAGE bad answer");
					break;

				default:
					trace("DnsQuerier.lookupHandler(): bad state");
					break;
			}

			// GenericTools.profiler("lookupHandler() RETURN");
		} catch (e : Error) {
			FlexGlobals.topLevelApplication.uncaughtException("DnsQuerier.lookupHandler()", e);
		}
		}

		private function qualify(domain : String) : String {
			return domain + ".v" + new String(PROTOCOL_VERSION) + "." + TLD;
		}

		public function sendMessage(message_string : String, callback : Function) : void {
			try {

			if (state == STATE_CANCELLED) return;

			if (state != STATE_JUST_CREATED) {
				trace("DnsQuerier.sendMessage(): error: bad state");
				return;
			}

			// ERREUR à corriger : on compte en char (UTF8) mais pas en bytes ! Ca fausse les débits affichés.
			VuMeter.statsSendEncapsulatedBytes(message_string.length);

//			trace("DnsQuerier.sendMessage(\"" + message_string + "\")");
			this.message_string = message_string;
			this.callback = callback;
	
			const bar : ByteArray = new ByteArray();

			// string message type
			bar.writeByte(0);

			bar.writeUTFBytes(message_string);

			state = STATE_GET_TICKET;
			current_rr = qualify("sz-" + GenericTools.padNumber(bar.length) +
				".rn-" + GenericTools.padNumber(Math.random() * 100000000) + ".id-00000001");
			retry = MAX_RETRIES;
			dns_resolver = new XDNSResolver();
			dns_resolver.addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
			dns_resolver.addEventListener(ErrorEvent.ERROR, errorHandler);

//			trace("DnsQuerier.sendDnsQuery() - " + current_rr);
			dns_resolver.lookup(GenericTools.simulateIPLoss(current_rr), ARecord);

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsQuerier.sendMessage()", e);
			}
		}

		public function sendBinaryMessage(message_string : String, message_bytes : ByteArray, callback : Function) : void {
			try {

			if (state == STATE_CANCELLED) return;

//			trace("DnsQuerier.sendBinaryMessage(): message_bytes len: " + message_bytes.length);
			if (state != STATE_JUST_CREATED) {
				trace("DnsQuerier.sendBinaryMessage(): error: bad state");
				return;
			}

			binary_message = true;

			// ERREUR à corriger : on compte en char (UTF8) mais pas en bytes ! Ca fausse les débits affichés.
			VuMeter.statsSendEncapsulatedBytes(message_string.length + message_bytes.length);

			this.message_string = message_string;
			this.message_bytes = new ByteArray();
			this.message_bytes.writeBytes(message_bytes);
			this.callback = callback;

			const bar : ByteArray = new ByteArray();

			// binary message type
			const tmpbar : ByteArray = new ByteArray();
			tmpbar.writeUTFBytes(message_string);
			if (tmpbar.length > 255) trace("sendBinaryMessage error: UTF-8 part too long");
			bar.writeByte(tmpbar.length);

			bar.writeUTFBytes(message_string);
			bar.writeBytes(message_bytes);

			state = STATE_GET_TICKET;
			current_rr = qualify("sz-" + GenericTools.padNumber(bar.length) +
				".rn-" + GenericTools.padNumber(Math.random() * 100000000) + ".id-00000001");
			retry = MAX_RETRIES;
			dns_resolver = new XDNSResolver();
			dns_resolver.addEventListener(DNSResolverEvent.LOOKUP, lookupHandler);
			dns_resolver.addEventListener(ErrorEvent.ERROR, errorHandler);
			
			dns_resolver.lookup(GenericTools.simulateIPLoss(current_rr), ARecord);
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("DnsQuerier.sendBinaryMessage()", e);
			}
		}
	}
}
