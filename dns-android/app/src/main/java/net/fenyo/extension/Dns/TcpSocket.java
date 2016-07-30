// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;

import org.apache.http.util.ByteArrayBuffer;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

// gère une redirection de port en cours (un canal TCP)
public class TcpSocket implements Runnable {
	private boolean read_thread = true;
	private final int id;
	private final SocketChannel socket_channel;
	private final FREContext ctx;
	private final TcpInit tcp_init;
	private Boolean closed = false;

	// pas propre : taille dynamique à implémenter au lieu de ce max énorme
	private ByteBuffer read_buf = ByteBuffer.allocate(1024 * 1024);

	private Object write_buf_sem = new Object();
	private byte [] write_buf = new byte [] {};
	private boolean must_exit = false;
	private boolean must_exit_when_all_data_read_locally = false;

	public TcpSocket(final FREContext ctx, final int id, final SocketChannel socket_channel, final TcpInit tcp_init) {
		this.tcp_init = tcp_init;
		this.ctx = ctx;
		this.id = id;
		this.socket_channel = socket_channel;
	}

	public void writeBytes(byte [] data) {
		synchronized (write_buf_sem) {
			final byte [] new_write_buf = new byte [write_buf.length + data.length];
			for (int i = 0; i < write_buf.length; i++) new_write_buf[i] = write_buf[i];
			for (int i = 0; i < data.length; i++) new_write_buf[write_buf.length + i] = data[i];
			write_buf = new_write_buf;
			write_buf_sem.notify();
		}
	}

	public byte [] readBytes() {
		synchronized (read_buf) {
			final byte [] data = new byte [read_buf.position()];
			read_buf.rewind();
			read_buf.get(data);
			read_buf.clear();
			return data;
		}
	}

	@Override
	public void run() {
		if (read_thread) {

			read_thread = false;
			new Thread(this).start();

			try {
				// thread de lecture locale pour envoi au serveur
				while (true) {
					final ByteBuffer tmp_read_buf = ByteBuffer.allocate(1024);
					int ret = socket_channel.read(tmp_read_buf);
					if (ret >= 0) {
						tmp_read_buf.flip();
						synchronized (read_buf) {
							read_buf.put(tmp_read_buf);
						}
					} else {
						synchronized (closed) {
							if (!closed) socket_channel.close();
							closed = true;
						}
						return;
					}
				}
			} catch (IOException e) {
				Log.e("TcpSocket:run(): read(): ", "IOException");
				e.printStackTrace();
				try {
					synchronized (closed) {
						if (!closed) socket_channel.close();
						closed = true;
					}
				} catch (IOException e1) {
					Log.e("TcpSocket:run(): close(): ", "IOException");
					e1.printStackTrace();
				}
				return;
			} finally {
				tcp_init.removeSocket(id);
				terminateLocalWriteThread();
				// Log.i("Alex", "femeture thread 1 id=" + id);
			}

		} else {

			try {
				// thread de lecture distante pour écrire sur socket locale
				while (true) {
					synchronized (write_buf_sem) {
						if (must_exit == true) return;
						try {
							if (write_buf.length == 0) {
								if (must_exit_when_all_data_read_locally) {
									try {
										socket_channel.close();
									} catch (IOException e) {
										Log.e("TcpSocket:closeSocket()", "Exception");
										e.printStackTrace();
									}
									return;
								}
								write_buf_sem.wait();
							}
						} catch (InterruptedException e) {
							// e.printStackTrace();
							return;
						}
					}
					
					ByteBuffer _write_buf;
					synchronized (write_buf_sem) {
						_write_buf = ByteBuffer.allocate(write_buf.length);
						_write_buf.put(write_buf);
					}
					_write_buf.flip();
					int nbytes = socket_channel.write(_write_buf);
					synchronized (write_buf_sem) {
						final byte [] new_write_buf = new byte [write_buf.length - nbytes];
						for (int i = 0; i < write_buf.length - nbytes; i++)
							new_write_buf[i] = write_buf[i + nbytes];
						write_buf = new_write_buf;
					}					
				}
			} catch (IOException e) {
				Log.e("TcpSocket:run(): write(): ", "IOException");
				e.printStackTrace();
				try {
					synchronized (closed) {
						if (!closed) socket_channel.close();
						closed = true;
					}
				} catch (IOException e1) {
					Log.e("TcpSocket:run(): close(): ", "IOException");
					e1.printStackTrace();
				}
				return;
			} finally {
				// Log.i("Alex", "femeture thread 2 id=" + id);
			}
		}
	}

	private void terminateLocalWriteThread() {
		synchronized (write_buf_sem) {
			must_exit = true;
			write_buf_sem.notify();
		}
	}

	public void closeSocket() {
		// il ne faut pas fermer s'il y a encore des données locales non lues => on postpone le close
		synchronized (write_buf_sem) {
			if (write_buf.length > 0) {
				// Log.i("Alex", "femeture socket postponed id=" + id);

				must_exit_when_all_data_read_locally = true;
				return;
			}
		}

		try {
			socket_channel.close();
		} catch (IOException e) {
			Log.e("TcpSocket:closeSocket()", "Exception");
			e.printStackTrace();
		}
	}
}
