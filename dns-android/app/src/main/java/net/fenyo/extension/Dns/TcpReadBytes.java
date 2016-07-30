// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.nio.ByteBuffer;

import com.adobe.fre.FREByteArray;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class TcpReadBytes implements FREFunction {
	final TcpInit tcp_init;

	public TcpReadBytes(final FREContext ctx, final TcpInit tcp_init) {
		this.tcp_init = tcp_init;
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		TcpSocket tcp_socket = null;

		try {
			FREObject input = passedArgs[0];
			final int socket_id = input.getAsInt();

			tcp_socket = tcp_init.getTcpSocket(socket_id);
			if (tcp_socket == null) {
				Log.e("TcpReadBytes:call()", "tcp socket already closed");
				return null;
			}

			final byte [] data = tcp_socket.readBytes();
			FREByteArray fbe = FREByteArray.newByteArray();
			fbe.setProperty("length", FREObject.newObject(data.length));
			fbe.acquire();
			final ByteBuffer byte_buffer = fbe.getBytes();
			byte_buffer.put(data);
			fbe.release();
			return fbe;
		} catch (final Exception ex) {
			ex.printStackTrace();
		}

		return null;
	}
}
