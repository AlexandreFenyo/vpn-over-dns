// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.util.HashMap;
import java.util.Map;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.air.sampleextensions.android.licensing.*;

/*
 * This class specifies the mapping between the actionscript functions and the native classes.
 */

public class DnsExtensionContext extends FREContext {
	public DnsExtensionContext() { }

	@Override
	public void dispose() {	}

	@Override
	public Map<String, FREFunction> getFunctions() {

		Map<String, FREFunction> functionMap = new HashMap<String, FREFunction>();

		final AndroidLicensing checkLicenseNative = new AndroidLicensing();
		functionMap.put("checkLicenseNative", checkLicenseNative);

		final Trace trace = new Trace(this);
		functionMap.put("trace", trace);

		final DeviceId deviceid = new DeviceId(this);
		functionMap.put("deviceid", deviceid);

		final NotificationInit notificationinit = new NotificationInit(this);
		functionMap.put("notificationinit", notificationinit);

		final NotificationStart notificationstart = new NotificationStart(this, notificationinit);
		functionMap.put("notificationstart", notificationstart);

		final NotificationStop notificationstop = new NotificationStop(this, notificationinit);
		functionMap.put("notificationstop", notificationstop);

		final SslGet sslget = new SslGet(this);
		functionMap.put("sslget", sslget);

		final Lookup lookup = new Lookup(this);
		functionMap.put("lookup", lookup);

		final Cancel cancel = new Cancel(this, lookup);
		functionMap.put("cancel", cancel);

		final TcpInit tcp_init = new TcpInit(this);
		functionMap.put("tcpinit", tcp_init);

		final TcpReadBytes tcp_read_bytes = new TcpReadBytes(this, tcp_init);
		functionMap.put("tcpreadbytes", tcp_read_bytes);

		final TcpWriteBytes tcp_write_bytes = new TcpWriteBytes(this, tcp_init);
		functionMap.put("tcpwritebytes", tcp_write_bytes);

		final TcpCloseSocket tcp_close_socket = new TcpCloseSocket(this, tcp_init);
		functionMap.put("tcpclosesocket", tcp_close_socket);

		return functionMap;
	}
}
