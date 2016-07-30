// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.net.Inet4Address;
import net.fenyo.mail4hotspot.dns.Msg;

public interface AdvancedServices {
//	public void processMails();
//	public void processMails2();
	public void testLog();
	public void processMails(final String username);
	public void processMailsWithHeaderOnly(final String username);
	public String processQueryFromClient(String query, Inet4Address address);
	public Msg.BinaryMessageReply processBinaryQueryFromClient(String query, byte data[], Inet4Address address);
}
