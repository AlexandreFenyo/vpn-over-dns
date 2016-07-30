// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;
import com.google.api.client.auth.oauth2.AuthorizationCodeResponseUrl;
import com.google.api.client.auth.oauth2.BearerToken;
import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.auth.oauth2.MemoryCredentialStore;
import com.google.api.client.extensions.servlet.auth.oauth2.AbstractAuthorizationCodeCallbackServlet;
import com.google.api.client.http.BasicAuthentication;
import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.jackson.JacksonFactory;

public class OAuthServletCallback extends AbstractAuthorizationCodeCallbackServlet {
	private static final long serialVersionUID = 1L;
	protected final Log log = LogFactory.getLog(getClass());

	@Override
	protected void onSuccess(HttpServletRequest req, HttpServletResponse resp, Credential credential) throws ServletException, IOException {
		log.debug("ok");
		resp.sendRedirect("/");
	}

	@Override
	protected void onError(HttpServletRequest req, HttpServletResponse resp, AuthorizationCodeResponseUrl errorResponse) throws ServletException, IOException {
		// handle error
		log.debug("erreur");
	}
	
	@Override
	protected String getRedirectUri(HttpServletRequest req) throws ServletException, IOException {
		GenericUrl url = new GenericUrl(req.getRequestURL().toString());
		url.setRawPath("/mail4hotspot/oauthcb");
		return url.build();
	}
	
	@Override
	protected AuthorizationCodeFlow initializeFlow() throws IOException {
		return new AuthorizationCodeFlow.Builder(BearerToken.authorizationHeaderAccessMethod(),
				new NetHttpTransport(),
				new JacksonFactory(),
				// token server URL:
				// new GenericUrl("https://server.example.com/token"),
				new GenericUrl("https://accounts.google.com/o/oauth2/auth"),
				new BasicAuthentication("458072371664.apps.googleusercontent.com",
						"mBp75wknGsGu0WMzHaHhqfXT"),
				"458072371664.apps.googleusercontent.com",
				// authorization server URL:
				"https://accounts.google.com/o/oauth2/auth").
				// setCredentialStore(new JdoCredentialStore(JDOHelper.getPersistenceManagerFactory("transactions-optional")))
				setCredentialStore(new MemoryCredentialStore()).setScopes("https://mail.google.com/")
				// setCredentialStore(new MyCredentialStore())
				.build();
	}
	
	@Override
	protected String getUserId(HttpServletRequest req) throws ServletException, IOException {
		// return user ID
		return "alexandre.fenyo2@gmail.com";
	}
}
