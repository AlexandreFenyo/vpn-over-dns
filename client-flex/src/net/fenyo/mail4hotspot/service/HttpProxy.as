// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service
{
	import flash.errors.*;
	import flash.events.*;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.system.System;
	import flash.utils.*;
	
	import mx.collections.*;
	import mx.core.FlexGlobals;
	import mx.resources.ResourceManager;
	import mx.states.InterruptionBehavior;
	
	import net.fenyo.extension.Tcp;
	import net.fenyo.mail4hotspot.dns.*;
	
	import views.BrowserView;

	// il faudrait décrire avec un automate à états :
    //
	//                  . créée
	//                   |
	//                  Cx (connexion en cours)
	//                /    \
	//        Connectée vs erreur-de-connexion -> ... supprimée
    //         /     \
// local-a-fermé vs distant-a-fermé
	//        \       /
	//        supprimée
	//
	// '=>' : appel de fonction ou invocation du serveur; 'T' : on trace
	//
	// invocations serveur :
	//   - ConnectSocket
	//   - ClosedSocket
	//   - SocketData
	//
	// artefacts ANDROID :
	//
	// 1- nvlle connexion locale
	//    static function onStatus()
	// T    création d'une instance de HttpProxy
	//      => function init()
	//      rajout à static proxies[]
	// T    => invocation serveur ConnectSocket
	//         => callback function connectSocketCB1()
	//            si id du distant fourni :
	// T            id stocké
	// T          sinon (ex: can not resolve remote host) :
	// T          => function closeSocket()
	//               closed <= true
	//               => function ane tcp.closeSocket()                         <= FERMETURE SOCKET LOCALE
	// T             => function proxies.splice()                              <= SPLICE
    //
	// 2- réception données locale et envoi au distant
	//    static function socketTimer() : boucle sur les proxies qui ont id non null
	//    => function tcp.readBytes()                                          <= DONNEES LOCALES PRESENTES
	// T     si erreur :
	// T       => function localDisconnected()                                 <= LOCAL A FERME LA SOCKET
	//            si current_dns_querier non null
	//              => function current_dns_querier.cancel()
    //            on créé un nouveau current_dns_querier pour l'invocation suivante
	//            invocation serveur ClosedSocket
	//                 => callback function voidCBFunction()
	// T       => function proxies.splice()                                    <= SPLICE
	//    => function sendBytes()
	//       si current_dns_querier null
	//         current_dns_querier créé pour invocation qui suit
	// T       => invocation serveur SocketData
	// T          => callback function socketDataCB1()
	// T            si toujours pas de données même après tous les ré-essais (i.e. pas de données pendant un certain délai) :
	// T              => function ane closeSocket()
	//                   closed <- true
	//                   => function ane tcp.closeSocket()                     <= FERMETURE SOCKET LOCALE
	// T                 => function proxies.splice()                          <= SPLICE
	//                   BUG : devrait-on prévenir le serveur ?
	//              sinon :
	//                current_dns_querier <- null
	// T              s'il y a des octets reçus :                              <= DONNEES DISTANTES PRESENTES
	//                  => function tcp.writeBytes()
	// T              si le distant a fermé la socket : (problématique en principe contournée : le distant a fermé mais on n'a peut être pas tout récupéré en local)
	// T                => function closeSocket()                              <= DISTANT A FERME LA SOCKET
	//                     closed <- true
	//                     => function ane tcp.closeSocket()                   <= FERMETURE SOCKET LOCALE
	// T                   => function proxies.splice()                        <= SPLICE

	// il faudrait faire de même pour le cas où on est sous Windows car il y a certainement des erreurs à corriger (ex: plusieurs appels à splice au lieu d'un seul)
	
	public class HttpProxy {
		// Windows
		private static var serverSockets : Array = [];

		private static var proxies : Array = [];
		private static var socket_timer : Timer = new Timer(200);

		private static var ports : ArrayCollection;

		private static var tcp : Tcp;
		
		private var socket : Socket;
		private var closed : Boolean = false;
		private var id : String = null;

		private const LOCAL_HTTP_PORT : int = 8888;
		private var local_port : int;
		private var remote_port : int;
		private var remote_host : String;
		
		private var bytes_to_proxy : ByteArray = new ByteArray();
		private var current_dns_querier : DnsQuerier = null;
		
		private var native_tcp_socket_id : int = 0;

		// to debug (release_info_debug_sockets)
		public var debug_str : String = "";
		// debug_str is added to debug_str_erased when proxies is spliced
		// then the disconnect ack is not already received => the ack is directly copied into debug_str_erased when it happens
		public static var debug_str_erased : String = "";

		public static function debugMemory() : void {
			trace("HttpProxy.debugMemory():");
			trace("serverSockets cnt: " + serverSockets.length);
			trace("proxies cnt: " + proxies.length);

			for (var i : int = 0; i < proxies.length; i++) {
				const proxy : HttpProxy = proxies[i];
				trace("");
				trace(proxy.debug_str);
			}

			trace("");
			trace("OLD debug strings:");
			trace(debug_str_erased);
		}

		// Android et Windows
		// 
		public function HttpProxy(socket : Socket, local_port : int, remote_port : int, remote_host : String, native_tcp_socket_id : int = 0) {
			this.socket = socket;
			this.native_tcp_socket_id = native_tcp_socket_id;
			this.local_port = local_port;
			this.remote_port = remote_port;
			this.remote_host = remote_host;

			if (Main.release_info_debug_sockets) {
				debug_str += new Date().toString() + " - create an instance of HttpProxy\n";
				debug_str += new Date().toString() + " - local_port = " + local_port + "\n";
				debug_str += new Date().toString() + " - remote_host = " + remote_host + "\n";
				debug_str += new Date().toString() + " - remote_port = " + remote_port + "\n";
			}
		}

		// Android et Windows
		private function getDnsQuerierType() : uint {
			if (local_port == LOCAL_HTTP_PORT) return DnsQuerierFactory.TYPE_WEB;
			else return DnsQuerierFactory.TYPE_REDIRECT;
		}

		// Android
		protected function getNativeTcpSocketId() : int {
			return native_tcp_socket_id;
		}

		// Android et Windows
		private static function socketTimer(event : TimerEvent) : void {
			try {

				for (var i : int = 0; i < proxies.length; i++) {
					// on splice proxies dans cette boucle, donc il se peut qu'on rate un proxy lors de la boucle, mais ça n'a pas d'impact
					// dans tous les cas, i n'est jamais au dessus de la valeur max car on prend proxies[i] seulement au début d'une boucle, donc on vient de vérifier que i < proxies.length

					var proxy : HttpProxy = proxies[i];

					if (proxy.id != null) {
						if (!ServerSocket.isSupported) {
							const bar : ByteArray = tcp.readBytes(proxy.getNativeTcpSocketId());
							if (bar == null) {
trace("HttpProxy.socketTimer(): tcp.readBytes() renvoie null");			
								if (Main.release_info_debug_sockets)
									proxy.debug_str += new Date().toString() + "- "+ " tcp.readBytes() returned NULL\n";
								proxy.localDisconnected();
								if (Main.release_info_debug_sockets)
									proxy.debug_str += new Date().toString() + "- "+ " splice\n";
								proxies.splice(proxies.indexOf(proxy), 1);
								if (Main.release_info_debug_sockets)
									debug_str_erased += proxy.debug_str + "\n";
							} else {
// trace("HttpProxy.socketTimer(): octets locaux lus: longueur: " + bar.length);
								proxy.addBytes(bar);
							}
						}
						
						proxy.sendBytes();
					}
				}
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.socketTimer()", e);
			}
		}

		// Android
		private function voidCBFunction(reply : String) : void {
trace("HttpProxy.voidCBFunction(): ack du serveur pour disconnect local");

			if (Main.release_info_debug_sockets)
				// ca ne sert à rien d'ajouter à debug_str car splice a déjà été appelé
				debug_str_erased += new Date().toString() + " - id " + id + " - local disconnect ack received from server - local_port = " + local_port + " - remote_host = " + remote_host + " - remote_port = " + remote_port + "\n";
		}

		// Android et Windows
		// appelé sous Android depuis socketTimer quand on recoit 0 octet de la socket
		private function localDisconnected() : void {
trace("HttpProxy.localDisonnected(): on prévient le serveur que le local s'est déconnecté");

			try {

				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + " - localDisconnected() -> invocation serveur de §ClosedSocket\n";

				// problème uniquement sous Windows : en effet, sous Android, on n'appelle pas localDisconnected si id est null
				// id == null si on a une déconnexion à signaler alors que la réponse du connect n'est pas encore revenue
				// amélioration : il faudrait donc refaire plus tard cette demande de déconnexion, car ici on ne la fera jamais
				// il y a donc toutes les chances que ça parte en timeout de l'autre côté, mais ça serait plus propre de fermer proprement
				if (id == null) return;
				
				if (current_dns_querier != null) current_dns_querier.cancel();
				current_dns_querier = DnsQuerierFactory.getDnsQuerier(getDnsQuerierType());
				current_dns_querier.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§ClosedSocket" +
					"§" + id + "§" + Main.deviceId, voidCBFunction);
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.localDisconnected()", e);
			}
		}

		// Android
		public function addBytes(bar : ByteArray) : void {
			if (Main.release_info_debug_sockets)
				debug_str += new Date().toString() + " - store " + bar.length + " bytes from local to send them later\n";

			bytes_to_proxy.writeBytes(bar);
		}

		// Android et Windows
		public function init() : void {
			try {

				if (ServerSocket.isSupported) {
					socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
					socket.addEventListener(Event.CLOSE, onClientClose);
					socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				}
				
				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + " - send §ConnectSocket: inform server about new connection\n";
				
				var dnsQuerier : DnsQuerier = DnsQuerierFactory.getDnsQuerier(getDnsQuerierType());
				dnsQuerier.sendMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§ConnectSocket" +
					"§" + remote_port + "§" + remote_host +
					"§" + Main.release_info_account_type + "§" + Main.release_info_client_version + "§" + Main.deviceId,
					connectSocketCB1);

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.init()", e);
			}
		}

		// Android et Windows
		private function connectSocketCB1(reply : String) : void {
			try {

				if (reply == null) {
					// pas de réponse même après toutes les retransmissions
					trace("pas de réponse après toutes les retransmissions");
					// il faudrait prévenir le distant
					closeSocket();
				} else {
					var fields : Array = reply.split("§");
					
					switch (new int(fields[0])) {
						case VpnCode.SRV2CLT_SOCKET_ID:
							id = fields[1];

							if (Main.release_info_debug_sockets)
								debug_str += new Date().toString() + " - id " + id + " received from server\n";
							break;
						
						default:
							// côté serveur, le remote_host est injoignable ou le remote_port n'a aucun process qui écoûte dessus
							if (Main.release_info_debug_sockets)
								debug_str += new Date().toString() + " server cannot connect\n";
							trace("connectSocketCB1(): socket error: " + reply);
							closeSocket();
							break;
					}
				}

			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.connectSocketCB1()", e);
			}
		}

		// Android et Windows
		public static function initHttpProxy(ports : ArrayCollection) : void {
			try {
				
				HttpProxy.ports = ports;
				
				// optimisation : ne le faire tourner que lorsque c'est nécessaire
				socket_timer.addEventListener(TimerEvent.TIMER, socketTimer);
				socket_timer.start();
				
				if (ServerSocket.isSupported) {
					try {
						var i : int = 0;
						for (var obj : Object in ports) {
							serverSockets[i] = new ServerSocket();
							
							serverSockets[i].addEventListener(Event.CONNECT, connectHandler);
							serverSockets[i].addEventListener(Event.CLOSE, onClose);
							
							serverSockets[i].bind(ports[obj].local_port);
							serverSockets[i].listen();
							
							i++;
						}
					} catch (ex : SecurityError) {
						trace(ex);
					}
				} else {
					tcp = new Tcp();
					tcp.addEventListener(StatusEvent.STATUS, onStatus);
					// il faudrait remonter dans un popUp les cas où on peut pas faire le bind
					for (var obj2 : Object in ports) tcp.init(ports[obj2].local_port);
				}
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.initHttpProxy()", e);
			}
		}

		// Android
		private static function onStatus(event : StatusEvent) : void {
// trace("HttpProxy.onStatus(): nouvelle connexion locale");			
			try {
				
				if (event.code == "ERROR") {
					// à localiser selon le message
					FlexGlobals.topLevelApplication.popUpError("HttpProxy.onStatus()", event.level);
					return;
				}
				
				// code: listening port
				// level: new socket id
				const local_port : int = parseInt(event.code);
				const native_tcp_socket_id : int = parseInt(event.level);
				
				var remote_port : int = -1;
				var remote_host : String = null;
				var i : int = 0;
				for (var obj : Object in ports) {
					if (local_port == ports[i].local_port) {
						remote_port = ports[i].remote_port;
						remote_host = ports[i].remote_host;
						break;
					}
					i++;
				}
				if (remote_port == -1) {
					trace("onStatus(): Error : no such socket");
					return;
				}

				var proxy : HttpProxy = new HttpProxy(null, local_port, remote_port, remote_host, native_tcp_socket_id);
				proxy.init();
				proxies.push(proxy);
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.onStatus()", e);
			}
		}

		// Windows
		public static function connectHandler(event : ServerSocketConnectEvent) : void {
			try {
				
				var server : ServerSocket = event.target as ServerSocket;
				var local_port : int = -1;
				var remote_port : int = -1;
				var remote_host : String = null;
				var i : int = 0;
				for (var obj : Object in ports) {
					if (serverSockets[i] == server) {
						local_port = ports[i].local_port;
						remote_port = ports[i].remote_port;
						remote_host = ports[i].remote_host;
						break;
					}
					i++;
				}
				if (local_port == -1) {
					trace("connectHandler(): Error : no such socket");
					return;
				}
				
				var proxy : HttpProxy = new HttpProxy(event.socket as Socket, local_port, remote_port, remote_host);
				proxy.init();
				proxies.push(proxy);
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.connectHandler()", e);
			}
		}

		// Windows
		private static function onClose(event : Event) : void {
			// quand passe-t-on ici ? A priori, quand on a appelé serverSocket.close();
			// mais on l'a jamais vu se produire même en forçant un close sur la serverSocket...
			trace("static HttpProxy.onClose()");

			var serverSocket : ServerSocket = event.target as ServerSocket;
			serverSocket.removeEventListener(Event.CONNECT, connectHandler);
			serverSocket.removeEventListener(Event.CLOSE, onClose);
		}

		// Windows
		private function socketDataHandler(event : ProgressEvent) : void {
			try {
				
				if (closed == true) {
					trace("socketDataHandler(): error: socket already closed");
					return;
				}
				
				try {
					// trace("socketDataHandler(): readBytes()");
					socket.readBytes(bytes_to_proxy, bytes_to_proxy.length);

					if (Main.release_info_debug_sockets)
						debug_str += new Date().toString() + " - store bytes from local to send them later\n";

				} catch (e: EOFError) {
					trace("socketDataHandler(): EOFError");
					// jamais appelé
				} catch (e: IOError) {
					trace("socketDataHandler(): IOError");
					// jamais appelé
				}
				
				sendBytes();
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.socketDataHandler()", e);
			}
		}
		
		// Android et Windows
		// appelé sur windows et android : retour de données depuis le serveur
		private function socketDataCB1(reply_string : String, reply_data : ByteArray) : void {
			try {

				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + " - reply from server\n";

				if (closed == true) {
					trace("socketDataCB1(): error: socket already closed");
					return;
				}

				if (reply_string == null) {
					// pas de réponse même après tous les ré-essais
// trace("HttpProxy.socketDataCB1(): pas de réponse même après tous les ré-essais");
					if (Main.release_info_debug_sockets)
						debug_str += new Date().toString() + " - no data after all tries\n";
					closeSocket();
					// il faudrait prévenir le serveur
					return;
				}
				
				current_dns_querier = null;
				
				var fields : Array = reply_string.split("§");
				
				if (reply_data.length != 0) {
					if (Main.release_info_debug_sockets)
						debug_str += new Date().toString() + " - data from server: " + reply_data.length + " bytes\n";
					if (ServerSocket.isSupported) {
						socket.writeBytes(reply_data);
						socket.flush();
					} else {
// trace("HttpProxy.socketDataCB1(): données reçues du serveur: [" + reply_data + "]");
//trace("HttpProxy.socketDataCB1(): données reçues du serveur: len=" + reply_data.length);
// heuristique à laisser ?
if (local_port == 8888) {
	if (!Main.tablet) {
		if (FlexGlobals.topLevelApplication.view_browser.activeView != null)
			FlexGlobals.topLevelApplication.view_browser.activeView.webDataReceived();
	} else {
		if (FlexGlobals.topLevelApplication.tablet_view_browser.activeView != null)
			FlexGlobals.topLevelApplication.tablet_view_browser.activeView.webDataReceived();
	}
}
						tcp.writeBytes(native_tcp_socket_id, reply_data);
					}
				}

				switch (new int(fields[0])) {
					case VpnCode.SRV2CLT_OK:
						break;
					
					default:
						// trace("HttpProxy.socketDataCB1(): le distant demande à fermer la socket");
						if (Main.release_info_debug_sockets)
							debug_str += new Date().toString() + " - server warns that remote socket closed\n";
						closeSocket();
						// il faudrait prévenir le serveur
						break;
				}
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.socketDataCB1()", e);
			}
		}
		
		// Android et Windows
		private function sendBytes() : void {
			try {
				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + " - sendBytes()\n";

				// sous Android : id ne peut pas être nul ici

				// id == null si on a des données à envoyer alors que la réponse du connect n'est pas encore revenue
				if (current_dns_querier != null || id == null) return;

// trace("HttpProxy.sendBytes(): données envoyées au serveur");

				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + " - send " + bytes_to_proxy.length + " bytes\n";

				current_dns_querier = DnsQuerierFactory.getDnsQuerier(getDnsQuerierType());
				current_dns_querier.sendBinaryMessage(FlexGlobals.topLevelApplication.persistenceManager.getProperty("uuid") + "§SocketData" +
					"§" + id, bytes_to_proxy, socketDataCB1);
				bytes_to_proxy.clear();
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.sendBytes()", e);
			}
		}
		
		// Android et Windows
		private function closeSocket() : void {
// trace("HttpProxy.closeSocket()");

			try {

				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + " - closeSocket(): closing local socket\n";

				if (ServerSocket.isSupported) {
					if (socket.connected) socket.close();
					socket.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
					socket.removeEventListener(Event.CLOSE, onClientClose);
					socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				} else tcp.closeSocket(native_tcp_socket_id);
				
				closed = true;
				if (Main.release_info_debug_sockets)
					debug_str += new Date().toString() + "- "+ " splice\n";
				proxies.splice(proxies.indexOf(this), 1);
				if (Main.release_info_debug_sockets)
					debug_str_erased += debug_str + "\n";
				
			} catch (e : Error) {
				FlexGlobals.topLevelApplication.uncaughtException("HttpProxy.closeSocket()", e);
			}
		}
		
		// Windows
		private function onClientClose(event : Event) : void {
			// cas sous Windows où la socket est fermée localement
			localDisconnected();
			closeSocket();
		}
		
		// Windows
		private function onIOError(errorEvent : IOErrorEvent) : void {
			proxies.splice(proxies.indexOf(this), 1);
			closeSocket();
		}
		
		// Windows
		private function onClose(event : Event) : void {
			// quand passe-t-on ici ? A priori, quand on a appelé socket.close(); mais visiblement ça marche pas.
			trace("HttpProxy.onClose()");
		}
		
	}
}
