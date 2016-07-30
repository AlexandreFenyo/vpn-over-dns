// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.dao;

import net.fenyo.mail4hotspot.domain.Ip;
import java.net.*;

public interface IpDAO {
	public void persist(final Ip transientIp);
	public void remove(final Ip ip);
	public Ip getIp(final String ipString);
	public Ip getIp(final Inet4Address inet4Address);
}
