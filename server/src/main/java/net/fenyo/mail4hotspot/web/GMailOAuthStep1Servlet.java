// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.web;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import javax.crypto.*;
import javax.crypto.spec.SecretKeySpec;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.fenyo.mail4hotspot.service.Browser;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class GMailOAuthStep1Servlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	protected final Log log = LogFactory.getLog(getClass());

	// 	private static final String base = "https://www.vpnoverdns.com/mail4hotspot/";
	private static final String base = "http://localhost/mail4hotspot/";
	private static final String consumer_secret = "eFqVBKU0Fe204Pkw78XBzlIW";

	// bug : fuite de mémoire, on ne vide pas les vieilles entrées
	private Map<String, String> map_request_token = new HashMap<String, String>();

	private String nonce() {
		return new Integer(new Double(Math.random() * 100000000).intValue()).toString();
	}

	private String now() {
		return new Long(new java.util.Date().getTime() / 1000).toString();
	}

	private String urlEncode(final String url) throws UnsupportedEncodingException {
		return URLEncoder.encode(url, "UTF-8");
	}

	private String urlDecode(final String url) throws UnsupportedEncodingException {
		return URLDecoder.decode(url, "UTF-8");
	}

	private String hmac(final String key, final String message) throws InvalidKeyException, NoSuchAlgorithmException, UnsupportedEncodingException {
		final Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(new SecretKeySpec(key.getBytes("UTF-8"), "HmacSHA1"));
        return org.apache.commons.codec.binary.Base64.encodeBase64String(mac.doFinal(message.getBytes("UTF-8")));
	}

	private String parseReply(final String key, final String message) {
		for (final String part : message.split("&"))
			if (part.startsWith(key + "=")) return part.substring(key.length() + 1);
		return null;
	}

	// http://localhost/mail4hotspot/oauth/step1?uuid=12938123
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
		try {
			if (request.getPathInfo().equals("/step1")) {
//				final String uuid = request.getParameter("uuid");
				final String nonce = nonce();
				final String now = now();
				log.debug("nonce=" + nonce);
				log.debug("now=" + now);
				final String base_string = "GET&" +
						urlEncode("https://www.google.com/accounts/OAuthGetRequestToken") +
						"&" +
						urlEncode("oauth_callback=" +
								  urlEncode(base + "oauth/step2") +
								  "&oauth_consumer_key=www.vpnoverdns.com&oauth_nonce=" +
								  nonce +
								  "&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
								  now +
								  "&oauth_version=1.0&scope=" +
								  urlEncode("https://mail.google.com/"));
				log.debug("digestencoded=" + urlEncode(hmac(consumer_secret + "&", base_string)));
					final String url =
							"https://www.google.com/accounts/OAuthGetRequestToken?oauth_consumer_key=www.vpnoverdns.com&oauth_nonce=" +
							nonce +
							"&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
							now +
							"&oauth_version=1.0&oauth_callback=" +
							urlEncode(base + "oauth/step2") +
							"&scope=" +
							urlEncode("https://mail.google.com/") +
							"&oauth_signature=" +
							urlEncode(hmac(consumer_secret + "&", base_string));
					final String reply = Browser.getHtml(url, null);
					// request_token est URL encoded
					final String request_token = parseReply("oauth_token", reply);
					// request_token_secret est URL encoded
					final String request_token_secret = parseReply("oauth_token_secret", reply);
					log.debug("oauthtoken=" + request_token);
					log.debug("oauthtokensecret=" + request_token_secret);
					if (request_token == null || request_token_secret == null) {
						log.error("token error: token=" + request_token + " - token_secret=" + request_token_secret);
						return;
					}
					map_request_token.put(urlDecode(request_token), urlDecode(request_token_secret));
					
					response.setContentType("text/html");
			        response.setStatus(HttpServletResponse.SC_MOVED_TEMPORARILY);
			        response.setHeader("Location", "https://www.google.com/accounts/OAuthAuthorizeToken?oauth_token=" + request_token);
					final PrintWriter out = response.getWriter();
					out.println("<html><body>click <a href='https://www.google.com/accounts/OAuthAuthorizeToken?oauth_token=" + request_token + "'>here</a></body></html>");
			}
			
			if (request.getPathInfo().equals("/step2")) {
				final String verifier = request.getParameter("oauth_verifier");
				// request_token n'est pas URL encoded
				final String request_token = request.getParameter("oauth_token");
				// request_token_secret n'est pas URL encoded
				final String request_token_secret = map_request_token.get(request_token);

				log.debug("oauthtoken=" + request_token);
				log.debug("oauthtokensecret=" + request_token_secret);
				log.debug("verifier=" + verifier);

				String nonce = nonce();
				String now = now();
				log.debug("nonce=" + nonce);
				log.debug("now=" + now);

				String base_string = "GET&" +
						urlEncode("https://www.google.com/accounts/OAuthGetAccessToken") +
						"&" +
						urlEncode("oauth_consumer_key=www.vpnoverdns.com&oauth_nonce=" +
								  nonce +
								  "&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
								  now +
								  "&oauth_token=" +
								  urlEncode(request_token) +
								  "&oauth_verifier=" +
								  urlEncode(verifier) +
								  "&oauth_version=1.0");

				log.debug("digestencoded=" + urlEncode(hmac(consumer_secret + "&" + request_token_secret, base_string)));

					String url =
							"https://www.google.com/accounts/OAuthGetAccessToken?oauth_consumer_key=www.vpnoverdns.com&oauth_nonce=" +
							nonce +
							"&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
							now +
							"&oauth_token=" +
							urlEncode(request_token) +
							"&oauth_verifier=" +
							urlEncode(verifier) +
							"&oauth_version=1.0&oauth_signature=" +
							urlEncode(hmac(consumer_secret + "&" + request_token_secret, base_string));
					
					final String reply = Browser.getHtml(url, null);
					// access token est URL encoded
					final String access_token = parseReply("oauth_token", reply);
					// access_token_secret est URL encoded
					final String access_token_secret = parseReply("oauth_token_secret", reply);
					log.debug("oauthaccesstoken=" + access_token);
					log.debug("oauthaccesstokensecret=" + access_token_secret);

					nonce = nonce();
					now = now();
					log.debug("nonce=" + nonce);
					log.debug("now=" + now);

					base_string = "GET&" +
							urlEncode("https://mail.google.com/mail/b/alexandre.fenyo2@gmail.com/imap/") +
							"&" +
							urlEncode("oauth_consumer_key=www.vpnoverdns.com&oauth_nonce=" +
									  nonce +
									  "&oauth_signature_method=HMAC-SHA1&oauth_timestamp=" +
									  now +
									  "&oauth_token=" +
									  access_token +
									  "&oauth_version=1.0");

					// oauth_token=\"$oauthaccesstoken\",oauth_version=\"1.0\",oauth_signature=\"$digestencoded\"" | read URL

					log.debug("digestencoded=" + urlEncode(hmac(consumer_secret + "&" + urlDecode(access_token_secret), base_string)));

					url =
							"GET https://mail.google.com/mail/b/alexandre.fenyo2@gmail.com/imap/ oauth_consumer_key=\"www.vpnoverdns.com\",oauth_nonce=\"" +
							nonce +
							"\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"" +
							now +
							"\",oauth_token=\"" +
							access_token +
							"\",oauth_version=\"1.0\",oauth_signature=\"" +
							urlEncode(hmac(consumer_secret + "&" + urlDecode(access_token_secret), base_string)) +"\"";
					log.debug(org.apache.commons.codec.binary.Base64.encodeBase64String(url.getBytes("UTF-8")));
					
			}

		} catch (InvalidKeyException ex) {
			log.error(ex.toString());
		} catch (NoSuchAlgorithmException ex) {
			log.error(ex.toString());
		}
	}
}
