// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.nio.ByteBuffer;

import com.adobe.fre.FREByteArray;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class TcpCloseSocket implements FREFunction {
	final TcpInit tcp_init;

	public TcpCloseSocket(final FREContext ctx, final TcpInit tcp_init) {
		this.tcp_init = tcp_init;
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		try {
			FREObject input = passedArgs[0];
			final int socket_id = input.getAsInt();
			tcp_init.closeSocket(socket_id);
		} catch (final Exception ex) {
			ex.printStackTrace();
		}
		return null;
	}
}
