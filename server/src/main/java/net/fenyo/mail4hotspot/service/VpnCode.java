// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

public final class VpnCode {
	// error codes at Message protocol layer: see AdvancedServices.java
	public final static int SRV2CLT_OK = 0;
	public final static int SRV2CLT_NO_SUCH_COMMAND = 1;
	public final static int SRV2CLT_EXCEPTION = 2;
	public final static int SRV2CLT_START_CHECKING_MAILS = 3;
	public final static int SRV2CLT_CURRENTLY_CHECKING_MAILS = 4;
	public final static int SRV2CLT_NEW_MAIL = 5;
	public final static int SRV2CLT_ERROR = 6;
	public final static int SRV2CLT_NO_UNREAD_MAIL = 7;
	public final static int SRV2CLT_NMAILS = 10;
	public final static int SRV2CLT_NO_ACCOUNT = 11;
	public final static int SRV2CLT_MAIL_SAVED = 12;
	public final static int SRV2CLT_SOCKET_ID = 8;
	public final static int SRV2CLT_BAD_USER = 9;

	// error codes at DNS requests protocol layer: see DnsListener.java
	// E0, E1, E2, etc.
}
