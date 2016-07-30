// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.io.IOException;
import java.util.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class HttpProxyFactory {
	protected static final Log log = LogFactory.getLog(HttpProxyFactory.class);

	private static Map<Integer, HttpProxy> port2proxy = new HashMap<Integer, HttpProxy>();

	public static void sweep() {
		synchronized (port2proxy) {
			// ne pas effacer un élément d'une map quand on itère dessus (cf doc de keySet)
			final List<Integer> to_delete = new ArrayList<Integer>();
			for (int local_port : port2proxy.keySet())
				// délai max : 5 min + délai entre les tests (rechercher @Scheduled dans AdvancedServicesImpl)
				if (System.currentTimeMillis() - port2proxy.get(local_port).getLastUse() > 5 * 60 * 1000)
					to_delete.add(local_port);
			for (int local_port : to_delete) {
				final HttpProxy proxy = port2proxy.get(local_port);
				log.info("sweeping one old proxy: " + local_port + " - " + proxy.getUuid());
				proxy.close();
				// log.warn("" + port2proxy.size() + " proxie(s)");
				port2proxy.remove(local_port);
				// log.warn("sweeping one proxy => " + port2proxy.size() + " proxie(s) now");
			}
		}
	}

	public static HttpProxy getHttpProxy(final int local_port) {
		synchronized (port2proxy) {
			return port2proxy.get(local_port);
		}
	}

	public static boolean removeHttpProxy(final int local_port) {
    	synchronized (port2proxy) {
    		final HttpProxy proxy = port2proxy.get(local_port);
    		if (proxy == null) {
    			log.warn("no such id");
        		log.debug("HttpProxyFactory.removeHttpProxy(): proxies.size = " + port2proxy.size());
    			return false;
    		} else {
    			proxy.close();
    			port2proxy.remove(local_port);
        		// log.debug("HttpProxyFactory.removeHttpProxy(): proxies.size = " + port2proxy.size());
    			return true;
    		}
    	}
	}

	public static HttpProxy createHttpProxy(final String uuid, final int remote_port, final String remote_host) throws IOException {
		final HttpProxy proxy = new HttpProxy(uuid, remote_port, remote_host);

		// si une exception IOException est levée, on ne rajoutera donc pas ce proxy à la liste des proxies
		final int port = proxy.connect();

		synchronized (port2proxy) {
    		final HttpProxy old_proxy = port2proxy.get(port);
    		if (old_proxy != null) {
    			log.error("an old proxy has the same new local port");
    			old_proxy.close();
    			port2proxy.remove(port);
    		}
    		port2proxy.put(port, proxy);
    		// log.debug("HttpProxyFactory.createHttpProxy(): proxies.size = " + port2proxy.size());
		}

		return proxy;
	}
}
