// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.io.IOException;
import java.net.BindException;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class TcpInit implements FREFunction, Runnable {
	private FREContext ctx = null;

	private Integer socket_cnt = 0;
	// gestion des instances de TcpSocket : chaque instance est une redirection en cours (un canal TCP)
	private final Map<Integer, TcpSocket> tcp_socket_map = new HashMap<Integer, TcpSocket>();

	private final List<Integer> listening_ports = new ArrayList<Integer>();

	public TcpInit(final FREContext ctx) {
		this.ctx = ctx;
	}

	public TcpSocket getTcpSocket(final int id) {
		synchronized (tcp_socket_map) {
			return tcp_socket_map.get(id);
		}
	}

	public void closeSocket(final int id) {
		synchronized (tcp_socket_map) {
			final TcpSocket tcp_socket = tcp_socket_map.get(id);
			if (tcp_socket != null) tcp_socket.closeSocket();
			tcp_socket_map.remove(id);
		}
	}

	public void removeSocket(final int id) {
		synchronized (tcp_socket_map) {
			tcp_socket_map.remove(id);
		}
	}

	@Override
	public void run() {
		int listening_port;

		synchronized (listening_ports) {
			listening_port = listening_ports.get(0);
			listening_ports.remove(0);
		}

		try {
			final ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
			serverSocketChannel.socket().bind(new InetSocketAddress(listening_port));

			while (true) {
				// bug ? : ce while (true) qui bouclerait expliquerait des comportements de CPU intensif en cas de changement de couverture réseau
				// LAISSER CE LOG car si un tel comportement est à nouveau rencontré, il suffira pour le confirmer de regarder dans les logs Android s'il se produit en boucle
				Log.i("TcpInit:run()", "loop");

				synchronized (socket_cnt) {
					socket_cnt++;
				}
				final SocketChannel socket = serverSocketChannel.accept();
				final TcpSocket tcp_socket = new TcpSocket(ctx, socket_cnt, socket, this);
				synchronized (tcp_socket_map) {
					tcp_socket_map.put(socket_cnt, tcp_socket);
				}
				new Thread(tcp_socket).start();

				// code: "connectHandler"
				// level: new socket id
				ctx.dispatchStatusEventAsync("" + listening_port, "" + socket_cnt);
			}
		} catch (BindException ex) {
			ctx.dispatchStatusEventAsync("ERROR", "cannot redirect port " + listening_port + " - " + ex.toString());
		} catch (IOException ex) {
			Log.i("TcpInit:run() exception", ex.toString());
			ctx.dispatchStatusEventAsync("ERROR", ex.toString());
		}
	}

	// lancer 1 thread par port local sur lequel on doit écouter (call est donc appelé 1 seule fois)
	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		this.ctx = ctx;

		try {
			FREObject port1_obj = passedArgs[0];
			int port1 = port1_obj.getAsInt();

			synchronized (listening_ports) {
				listening_ports.add(port1);
			}
			
			new Thread(this).start();

		} catch (final Exception ex) {
			System.err.println(ex);
			ex.printStackTrace();
		}

		return null;
	}
}
