// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service
{
	public final class VpnCode {
		public static const SRV2CLT_OK : int = 0;
		public static const SRV2CLT_NO_SUCH_COMMAND : int = 1;
		public static const SRV2CLT_EXCEPTION : int = 2;
		public static const SRV2CLT_START_CHECKING_MAILS : int = 3;
		public static const SRV2CLT_CURRENTLY_CHECKING_MAILS : int = 4;
		public static const SRV2CLT_NEW_MAIL : int = 5;
		public static const SRV2CLT_ERROR : int = 6;
		public static const SRV2CLT_NO_UNREAD_MAIL : int = 7;
		public static const SRV2CLT_NMAILS : int = 10;
		public static const SRV2CLT_NO_ACCOUNT : int = 11;
		public static const SRV2CLT_MAIL_SAVED : int = 12;

		public static const SRV2CLT_SOCKET_ID : int = 8;
		public static const SRV2CLT_BAD_USER : int = 9;
	}
}
