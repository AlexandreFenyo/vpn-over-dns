// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import org.apache.commons.lang3.ArrayUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

// StageWebView avec fichier local : http://forums.adobe.com/thread/841945

public class HttpProxy {
	protected final Log log = LogFactory.getLog(getClass());

	private SocketChannel socket_channel = null;
	private final String uuid;
	private final int remote_port;
	private int local_port = -1;
	private final String remote_host;

	private final long first_use = System.currentTimeMillis();
	private long last_use = System.currentTimeMillis();

	private boolean closed = false;

	// http://docs.oracle.com/javase/6/docs/api/java/nio/Buffer.html
	// pas thread safe => Attention !
	// A buffer's capacity is the number of elements it contains. The capacity of a buffer is never negative and never changes.
	// A buffer's limit is the index of the first element that should not be read or written. A buffer's limit is never negative and is never greater than its capacity.
	// A buffer's position is the index of the next element to be read or written. A buffer's position is never negative and is never greater than its limit.
	// A buffer's mark is the index to which its position will be reset when the reset method is invoked
	// A newly-created buffer always has a position of zero and a mark that is undefined.
	// 0 <= mark <= position <= limit <= capacity
	// read et write : incrémente la position
	// reset() resets this buffer's position to the previously-marked position
	// clear() makes a buffer ready for a new sequence of channel-read or relative put operations: It sets the limit to the capacity and the position to zero.
	// flip() makes a buffer ready for a new sequence of channel-write or relative get operations: It sets the limit to the current position and then sets the position to zero.
	// rewind() makes a buffer ready for re-reading the data that it already contains: It leaves the limit unchanged and sets the position to zero.

	// taille max d'un buffer émis vers le client lors d'une redirection de ports,
	// c'est donc environ la taille max d'un message en direction du client
	// donc plus c'est bas, plus un ssh sera réactif et plus c'est grand meilleur est le débit

	// BUG avec 64 * 1024 sur www.lemonde.fr => on met 1024 au lieu de 64k et c'est en fait bien plus réactif et ça compense le bug
	// idée du pb : peut etre que quand le distant ferme la connexion, on n'attend pas la récupération locale avant de fermer la socket locale
	// private ByteBuffer from_socket_buffer = ByteBuffer.allocate(64 * 1024);
	// private ByteBuffer from_socket_buffer = ByteBuffer.allocate(1 * 1024);
	// 12/8/2012 : on a changé MAX_REPLY_LEN de 32 à 63, pour presque doubler le débit, donc on passe de 1024 à 2048 ici pour que la durée de chargement de chaque message ne change pas,
	//             on gagne ainsi en latence car près de 2 fois moins de messages pour une même page web, par ex
	// fin août, début sept 2012 : on a mis 48 dans MAX_REPLY_LEN
	// on pourrait vouloir mettre 1 * 512 pour le premier message d'un flux HTTP puis 1 * 4096 pour la suite, afin de contourner le bug d'Android qui consiste à afficher une page blanche quand après quelques dizaines de seconde une requête HTTP n'a rien renvoyé
	private ByteBuffer from_socket_buffer = ByteBuffer.allocate(1 * 4096);

	private byte [] to_socket_array = new byte [0];

	public HttpProxy(final String uuid, final int remote_port, final String remote_host) {
		this.uuid = uuid;
		this.remote_port = remote_port;
		this.remote_host = remote_host;
	}

	public long getFirstUse() {
		return first_use;
	}

	public long getLastUse() {
		return last_use;
	}

	public int getLocalPort() {
		return local_port;
	}

	public int getRemotePort() {
		return remote_port;
	}

	public int connect() throws IOException {
		last_use = System.currentTimeMillis();

		// log.debug("connect(): new Socket()");
		// final InetAddress address = InetAddress.getByAddress("xyz", new byte [] { (byte) 192, (byte) 168, (byte) 0, (byte) 5 /* 19 */ } );
		final InetAddress address = InetAddress.getByName(remote_host);
		final SocketAddress s_address = new InetSocketAddress(address, remote_port);
		socket_channel = SocketChannel.open();
		socket_channel.configureBlocking(true);
		socket_channel.connect(s_address);
		socket_channel.configureBlocking(false);
		// log.debug("local port: " + ((InetSocketAddress) socket_channel.getLocalAddress()).getPort());

		local_port = ((InetSocketAddress) socket_channel.getLocalAddress()).getPort();
		
		return local_port;
	}

	public void sendData(final byte data[]) throws IOException {
		// log.debug("sendData on id " + local_port);

		last_use = System.currentTimeMillis();

//		log.debug("sendData(): " + data.length + " bytes");

		if (closed) return;

		try {
			final ByteBuffer bb = ByteBuffer.allocate(to_socket_array.length + data.length);
			bb.put(to_socket_array);
			bb.put(data);
			bb.flip();
			final int nbytes = socket_channel.write(bb);
			to_socket_array = ArrayUtils.subarray(bb.array(), nbytes, bb.array().length);

		} catch (final IOException ex) {
			log.warn(ex);
			ex.printStackTrace();
			
			socket_channel.close();
			closed = true;

			throw ex;
		}
	}

	public byte [] receiveData() throws IOException {
		// log.debug("receiveData on id " + local_port);

		last_use = System.currentTimeMillis();

//		log.debug("receiveData()");

		if (closed) return null;

		try {
//			log.debug("position=" + from_socket_buffer.position() + " - limit=" + from_socket_buffer.limit() + " - capacity=" + from_socket_buffer.capacity());
//			log.debug("REMAINING: " + from_socket_buffer.remaining());
			final int nbytes = socket_channel.read(from_socket_buffer);
//			log.debug("octets lus: " + nbytes);
			if (nbytes == -1) return null;

			from_socket_buffer.flip();

			final byte [] ret_array = new byte [from_socket_buffer.limit()];
			from_socket_buffer.get(ret_array);

			from_socket_buffer.clear();
//			log.debug("ret array len: " + ret_array.length);
			return ret_array;
		} catch (final IOException ex) {
			log.warn(ex);
			ex.printStackTrace();

			closed = true;
			socket_channel.close();

			throw ex;
		}

	}

	public void close() {
		last_use = System.currentTimeMillis();

		if (!closed) {
			closed = true;
			try {
				socket_channel.close();
			} catch (IOException ex) {
				log.warn(ex);
				ex.printStackTrace();
			}
		}
	}

	public String getUuid() {
		last_use = System.currentTimeMillis();

		return uuid;
	}
}
