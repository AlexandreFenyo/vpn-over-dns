// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.web;

import java.io.*;
import java.net.*;
import java.util.*;

import javax.servlet.http.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

// ex de nom de domaine accentué : céréal.eu
// http://localhost/mail4hotspot/browser/http/c%C3%A9r%C3%A9al.eu/80/partie2?tata=truc&tata=troc
// http://localhost:80/mail4hotspot/browser/http/céréaltest.eu/80/partie2?tata=truc&tata=trc

public class BrowserServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	protected final Log log = LogFactory.getLog(getClass());

	@Override
	protected void doGet(final HttpServletRequest request, final HttpServletResponse response) throws IOException {
		// debug informations
		log.debug("doGet");
		log.debug("context path: " + request.getContextPath());
		log.debug("character encoding: " + request.getCharacterEncoding());
		log.debug("content length: " + request.getContentLength());
		log.debug("content type: " + request.getContentType());
		log.debug("local addr: " + request.getLocalAddr());
		log.debug("local name: " + request.getLocalName());
		log.debug("local port: " + request.getLocalPort());
		log.debug("method: " + request.getMethod());
		log.debug("path info: " + request.getPathInfo());
		log.debug("path translated: " + request.getPathTranslated());
		log.debug("protocol: " + request.getProtocol());
		log.debug("query string: " + request.getQueryString());
		log.debug("requested session id: " + request.getRequestedSessionId());
		log.debug("Host header: " + request.getServerName());
		log.debug("servlet path: " + request.getServletPath());
		log.debug("request URI: " + request.getRequestURI());
		@SuppressWarnings("unchecked")
		final Enumeration<String> header_names = request.getHeaderNames();
		while (header_names.hasMoreElements()) {
			final String header_name = header_names.nextElement();
			log.debug("header name: " + header_name);
			@SuppressWarnings("unchecked")
			final Enumeration<String> header_values = request.getHeaders(header_name);
			while (header_values.hasMoreElements()) log.debug("  " + header_name + " => " + header_values.nextElement());
		}
		if (request.getCookies() != null) for (Cookie cookie : request.getCookies()) {
			log.debug("cookie:");
			log.debug("cookie comment: " + cookie.getComment());
			log.debug("cookie domain: " + cookie.getDomain());
			log.debug("cookie max age: " + cookie.getMaxAge());
			log.debug("cookie name: " + cookie.getName());
			log.debug("cookie path: " + cookie.getPath());
			log.debug("cookie value: " + cookie.getValue());
			log.debug("cookie version: " + cookie.getVersion());
			log.debug("cookie secure: " + cookie.getSecure());
		}
		@SuppressWarnings("unchecked")
		final Enumeration<String> parameter_names = request.getParameterNames();
		while (parameter_names.hasMoreElements()) {
			final String parameter_name = parameter_names.nextElement();
			log.debug("parameter name: " + parameter_name);
			final String [] parameter_values = request.getParameterValues(parameter_name);
			for (final String parameter_value : parameter_values) log.debug("  " + parameter_name + " => " + parameter_value);
		}

		// parse request

		String target_scheme = null;
		String target_host;
		int target_port;

		// request.getPathInfo() is url decoded
		final String [] path_info_parts = request.getPathInfo().split("/");
		if (path_info_parts.length >= 2) target_scheme = path_info_parts[1];
		if (path_info_parts.length >= 3) {
			target_host = path_info_parts[2];
			try {
				if (path_info_parts.length >= 4) target_port = new Integer(path_info_parts[3]);
				else target_port = 80;
			} catch (final NumberFormatException ex) {
				log.warn(ex);
				target_port = 80;
			}
		} else {
			target_scheme = "http";
			target_host = "www.google.com";
			target_port = 80;
		}

		log.debug("remote URL: " + target_scheme + "://" + target_host + ":" + target_port);

		// create forwarding request

		final URL target_url = new URL(target_scheme + "://" + target_host + ":" + target_port);
		final HttpURLConnection target_connection = (HttpURLConnection) target_url.openConnection();

		// be transparent for accept-language headers
		@SuppressWarnings("unchecked")
		final Enumeration<String> accepted_languages = request.getHeaders("accept-language");
		while (accepted_languages.hasMoreElements()) target_connection.setRequestProperty("Accept-Language", accepted_languages.nextElement());

		// be transparent for accepted headers
		@SuppressWarnings("unchecked")
		final Enumeration<String> accepted_content = request.getHeaders("accept");
		while (accepted_content.hasMoreElements()) target_connection.setRequestProperty("Accept", accepted_content.nextElement());

	}
}
