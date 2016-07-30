// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.service;

import java.io.BufferedInputStream;
import java.nio.*;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.*;
import java.util.regex.*;
import java.util.zip.GZIPInputStream;
import java.util.zip.Inflater;
import java.util.zip.InflaterInputStream;

import javax.servlet.http.Cookie;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class Browser {
	// protected final Log log = LogFactory.getLog(getClass());
	protected static final Log log = LogFactory.getLog(Browser.class);

	public Browser() { }

	public void setProxyHost(final String proxy_host) {
		System.setProperty("http.proxyHost", proxy_host);
	}

	public void setProxyPort(final String proxy_port) {
		System.setProperty("http.proxyPort", proxy_port);
	}

	public static String getHtml(final String target_url, final Cookie [] cookies) throws IOException {
		// log.debug("RETRIEVING_URL=" + target_url);
		final URL url = new URL(target_url);

		final HttpURLConnection conn = (HttpURLConnection) url.openConnection();
		//Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress("10.69.60.6", 3128)); 
		// final HttpURLConnection conn = (HttpURLConnection) url.openConnection(proxy);

		//		HttpURLConnection.setFollowRedirects(true);
		// conn.setRequestProperty("User-agent", "my agent name");

		conn.setRequestProperty("Accept-Language", "en-US");

//		conn.setRequestProperty(key, value);

		// allow both GZip and Deflate (ZLib) encodings
		conn.setRequestProperty("Accept-Encoding", "gzip, deflate");
		final String encoding = conn.getContentEncoding();
		InputStream is = null;
		// create the appropriate stream wrapper based on the encoding type
		if (encoding != null && encoding.equalsIgnoreCase("gzip"))
			is = new GZIPInputStream(conn.getInputStream());
		else if (encoding != null && encoding.equalsIgnoreCase("deflate"))
		     is = new InflaterInputStream(conn.getInputStream(), new Inflater(true));
		else is = conn.getInputStream();

		final InputStreamReader reader = new InputStreamReader(new BufferedInputStream(is));

		final CharBuffer cb = CharBuffer.allocate(1024 * 1024);
		int ret;
		do {
			ret = reader.read(cb);
		} while (ret > 0);
		cb.flip();
		return cb.toString();
	}

	private static String urlEncoder(final String url, final boolean url_encode) throws UnsupportedEncodingException {
		return url_encode ? URLEncoder.encode(url, "UTF-8") : url;
	}

	private static String _encode(final String source_url, /*final*/ String target_url, final String prefix, final boolean url_encode) throws UnsupportedEncodingException {
		String base = source_url;
		base = base.replaceFirst("(?is)^([^:]*://[^/]*)/.*$", "$1");

//		target_url = "toto";
//		log.debug("");
//		log.debug("ENCODE:");
//		log.debug("source=" + source_url);
//		log.debug("target=" + target_url);

		if (target_url.toLowerCase().startsWith("http:") ||
				target_url.toLowerCase().startsWith("https:") ||
				target_url.toLowerCase().startsWith("ftp:")) {
			// target_url est une URL absolue
			return prefix + urlEncoder(target_url, url_encode);
		}

		if (target_url.startsWith("/")) {
			// target_url est une URL relative au site
			return prefix + urlEncoder(base + target_url, url_encode);
		}

		// à partir d'ici, target_url est une URL relative

		if (source_url.matches("(?is)[^:]*://[^/]*$")) return prefix + urlEncoder(source_url + "/" + target_url, url_encode);

		return prefix + urlEncoder(source_url.replaceFirst("(?is)^([^:]*://[^?]*/).*$", "$1") + "/" + target_url, url_encode);
	}

	private static String encode(final String source_url, final String target_url) throws UnsupportedEncodingException {
		return _encode(source_url, target_url, "navigation?url=", true);
	}

	private static String encodeForm(final String source_url, final String target_url) throws UnsupportedEncodingException {
		return _encode(source_url, target_url, "", false);
	}
	
	// http://docs.oracle.com/javase/7/docs/api/java/util/regex/Pattern.html
    // http://docs.oracle.com/javase/tutorial/essential/regex/intro.html
	// ftp://ftp-developpez.com/cyberzoide/java/regex.pdf
	public static String getSimpleHtml(final String target_url, final Cookie [] cookies) throws IOException {
		// traiter "base url"

		String html_in = getHtml(target_url, cookies);
//		html_in = "toto <a id=\"truc\" href= \"http://www.enst.Fr\"> toto </A> gfriojzfe href=fzeoin \r\n feziojzefj <a hreF='gzn,opv,ez'> </A> < a href=toto> </A> fzeoijfe";
		String html_out = "";
		boolean matches;

		// anchors
		do {
			matches = false;
			  // with single quotes: href='xyz'
			Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*a\\s+[^>]*?\\s*href\\s*=\\s*')([^']*?)('\\s*[^>]*>.*?</\\s*a\\s*>)(.*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
				html_out += m.group(1) + m.group(2) + encode(target_url, m.group(3)) + m.group(4);
				html_in = m.group(5);
			}
		} while (matches);
		html_out += html_in;

		// anchors
		html_in = html_out;
		html_out = "";
		do {
			matches = false;
			  // with double quotes: href="xyz"
			Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*a\\s+[^>]*?\\s*href\\s*=\\s*\")([^\"]*?)(\"\\s*[^>]*>.*?</\\s*a\\s*>)(.*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
				html_out += m.group(1) + m.group(2) + encode(target_url, m.group(3)) + m.group(4);
				html_in = m.group(5);
			}
		} while (matches);
		html_out += html_in;

		// anchors
		html_in = html_out;
		html_out = "";
		do {
			matches = false;
			  // without quotes: href=xyz
			Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*a\\s+[^>]*?\\s*href\\s*=\\s*)([^'\" ]+)(\\s*[^>]*>.*?</\\s*a\\s*>)(.*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
				html_out += m.group(1) + m.group(2) + encode(target_url, m.group(3)) + m.group(4);
				html_in = m.group(5);
			}
		} while (matches);
		html_out += html_in;
		
//		// form
//		do {
//			matches = false;
//			  // with single quotes: action='xyz'
//			Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*form\\s+[^>]*?\\s*action\\s*=\\s*')([^']*?)('\\s*[^>]*>.*?</\\s*form\\s*>)(.*)$");
//			Matcher m = p.matcher(html_in);
//			if (m.find()) {
//				matches = true;
//				html_out += m.group(1) + m.group(2) + encode(target_url, m.group(3)) + m.group(4);
//				html_in = m.group(5);
//			}
//		} while (matches);
//		html_out += html_in;

		// form
		html_in = html_out;
		html_out = "";
		do {
			matches = false;
		  // with double quotes: action="xyz"
			Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*form\\s+[^>]*?\\s*action\\s*=\\s*\")([^\"]*?)(\"\\s*[^>]*>)(.*?</\\s*form\\s*>)(.*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
//				log.debug("group2: " + m.group(2));
//				log.debug("group3: " + m.group(3));
//				log.debug("group4: " + m.group(4));
//				log.debug("target_url=" + target_url);
				html_out += m.group(1) + m.group(2) + encode(target_url, m.group(3)) + m.group(4) + "<input type=\"hidden\" name=\"url\" value=\"" +
				encodeForm(target_url, m.group(3))
				+ "\" />" + m.group(5);
//				log.debug("encoded=" + encodeForm(target_url, m.group(3)));
				html_in = m.group(6);
			}
		} while (matches);
		html_out += html_in;

//		// form
//		html_in = html_out;
//		html_out = "";
//		do {
//			matches = false;
//			  // without quotes: action=xyz
//			Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*form\\s+[^>]*?\\s*action\\s*=\\s*)([^'\" ]+)(\\s*[^>]*>.*?</\\s*form\\s*>)(.*)$");
//			Matcher m = p.matcher(html_in);
//			if (m.find()) {
//				matches = true;
//				html_out += m.group(1) + m.group(2) + encode(target_url, m.group(3)) + m.group(4);
//				html_in = m.group(5);
//			}
//		} while (matches);
//		html_out += html_in;

		// .js
		html_in = html_out;
		html_out = "";
		do {
			matches = false;
			Pattern p = Pattern.compile("(?is)^(.*?)(https?://\\S*\\.js)([^a-zA-Z].*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
				html_out += m.group(1);
				html_in = m.group(3);
			}
		} while (matches);
		html_out += html_in;

		// link
		html_in = html_out;
		html_out = "";
		do {
			matches = false;
			Pattern p = Pattern.compile("(?is)^(.*?)(<link\\s[^>]*>)(.*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
				html_out += m.group(1);
				html_in = m.group(3);
			}
		} while (matches);
		html_out += html_in;

		// img
		// optimisation : traiter les attributs alt
		html_in = html_out;
		html_out = "";
		do {
			matches = false;
			Pattern p = Pattern.compile("(?is)^(.*?)(<img\\s[^>]*>)(.*)$");
			Matcher m = p.matcher(html_in);
			if (m.find()) {
				matches = true;
				html_out += m.group(1);
				html_in = m.group(3);
			}
		} while (matches);
		html_out += html_in;

		if (true) {
			// script
			html_in = html_out;
			html_out = "";
			do {
				matches = false;
				Pattern p = Pattern.compile("(?is)^(.*?)(<\\s*script\\s.*?</\\s*script\\s*>)(.*)$");
				Matcher m = p.matcher(html_in);
				if (m.find()) {
//					log.debug("group1: " + m.group(1));
//					log.debug("group2: " + m.group(2));
//					log.debug("group3: " + m.group(3));
					matches = true;
					html_out += m.group(1);
					html_in = m.group(3);
				}
			} while (matches);
			html_out += html_in;
		}

		//		log.debug("html=" + html_out);

		return html_out;
	}
}
