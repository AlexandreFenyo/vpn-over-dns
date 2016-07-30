// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.client;

//import org.apache.log4j.xml.DOMConfigurator;

public class CommandLine {
	protected static final org.apache.commons.logging.Log log = org.apache.commons.logging.LogFactory.getLog(CommandLine.class);

	public static void main(final String [] args) {
//		DOMConfigurator.configure("src/main/webapp/WEB-INF/log4j.xml");
		log.debug("MAIL4HOTSPOT Java Client starting");

		log.debug("MAIL4HOTSPOT Java Client ending");
	}
}
