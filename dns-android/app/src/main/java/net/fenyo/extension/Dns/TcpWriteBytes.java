// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.nio.ByteBuffer;

import com.adobe.fre.FREByteArray;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class TcpWriteBytes implements FREFunction {
	final TcpInit tcp_init;

	public TcpWriteBytes(final FREContext ctx, final TcpInit tcp_init) {
		this.tcp_init = tcp_init;
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		try {
			FREObject input = passedArgs[0];
			final int socket_id = input.getAsInt();

			final TcpSocket tcp_socket = tcp_init.getTcpSocket(socket_id);
			if (tcp_socket == null) {
				Log.e("TcpWriteBytes:call()", "tcp socket already closed");
				return null;
			}

			final FREByteArray fre_data = (FREByteArray) passedArgs[1];
			fre_data.acquire();
			final int data_length = (int) fre_data.getLength();
			final ByteBuffer data = fre_data.getBytes();
			final byte [] copy = new byte [data_length];
			data.get(copy);
			fre_data.release();

			tcp_socket.writeBytes(copy);
		} catch (final Exception ex) {
			System.err.println(ex);
			ex.printStackTrace();
		}

		return null;
	}
}
