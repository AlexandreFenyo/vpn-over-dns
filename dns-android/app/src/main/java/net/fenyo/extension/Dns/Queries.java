// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed


package net.fenyo.extension.Dns;

import java.net.*;
import java.util.*;

import com.adobe.fre.FREContext;

import android.util.Log;

public class Queries implements Runnable {
	private static final int NTHREADS = 10;
//	// max throughput: NTHREADS dns requests per DELAY milliseconds
//	private static /* final */ long DELAY = 0;

	private final FREContext ctx;

	private final List<String> hosts = new ArrayList<String>();

	public Queries() {
		ctx = null;
	}

	public Queries(final FREContext ctx) {
		this.ctx = ctx;
	}

	public void init() {
		for (int i = 0; i < NTHREADS; i++) {
			new Thread(this).start();
		}
	}

	public void query(final String host) {
		synchronized (hosts) {
			hosts.add(host);
			// Log.d("Queries", "file d'attente +1: " + hosts.size());
			hosts.notify();
		}
	}

	public void cancel(final String host) {
		synchronized (hosts) {
			hosts.remove(host);
		}
	}

	@Override
	public void run() {
		while (true) {
			String host = null;

			synchronized (hosts) {
				if (hosts.size() != 0) {
//					if (hosts.size() > 50) DELAY = 1000;
//					else DELAY = 0;

					host = hosts.get(0);
					hosts.remove(0);
					// Log.d("Queries", "file d'attente -1: " + hosts.size());
				} else {
					// Log.i("Queries", "run(): sleeping");

					try {
						hosts.wait();
					} catch (final InterruptedException e) {
						e.printStackTrace();
						Log.e("Queries", "run(): InterruptedException => thread exiting");
					}
				}
			}

			if (host != null) {
				// Log.i("Queries", "run(): resolving " + host);
				try {
//					final long start_date = System.currentTimeMillis();
					// Log.i("Queries", "avant getAllByName");
					final InetAddress [] ips = InetAddress.getAllByName(host);
					// Log.i("Queries", "après getAllByName");
//					final long duration = System.currentTimeMillis() - start_date;
//					try {
//						if (duration < DELAY) Thread.sleep(DELAY - duration);
//					} catch (InterruptedException ex) {
//						ex.printStackTrace();
//					}

					String result_string = "";
					for (InetAddress ip : ips) {
						if (Inet4Address.class.isInstance(ip)) {
							// Log.i("Queries", "run(): IPv4 address for " + host + ": " + ip.toString());
							final String [] ip_parts = ip.toString().split("/");
							if (ip_parts == null || ip_parts.length != 2) {
								Log.e("Queries", "run(): bad answer for " + host + ": " + ip);
							} else {
								if (result_string.isEmpty()) result_string += ip_parts[1];
								else result_string += ";" + ip_parts[1];
							}
						} else Log.e("Queries", "run(): non IPv4 answer for " + host + ": " + ip.toString());
					}
//					Log.d("Queries", result_string);

					// code: host
					// level: RRs ou error string
					if (ctx != null) {
						if (result_string.isEmpty()) ctx.dispatchStatusEventAsync(host, ":answer empty");
						else ctx.dispatchStatusEventAsync(host, result_string);
					}

				} catch (final UnknownHostException e) {
					e.printStackTrace();
					Log.e("Queries", "run(): UnknownHostException for " + host + " - " + e.toString());
					if (ctx != null) ctx.dispatchStatusEventAsync(host, ":UnknownHostException");
				}
			}
		}
	}
}
