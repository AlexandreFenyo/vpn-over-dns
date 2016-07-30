// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.web;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.google.api.client.auth.oauth2.AuthorizationCodeFlow;
import com.google.api.client.auth.oauth2.BearerToken;
import com.google.api.client.auth.oauth2.MemoryCredentialStore;
import com.google.api.client.extensions.servlet.auth.oauth2.AbstractAuthorizationCodeServlet;
import com.google.api.client.http.BasicAuthentication;
import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.jackson.JacksonFactory;

public class OAuthServlet extends AbstractAuthorizationCodeServlet {
	private static final long serialVersionUID = 1L;
	protected final Log log = LogFactory.getLog(getClass());

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
		// do stuff
		log.debug("ICI");
	}
	
	@Override
	protected String getRedirectUri(HttpServletRequest req) throws ServletException, IOException {
		GenericUrl url = new GenericUrl(req.getRequestURL().toString());
		url.setRawPath("/mail4hotspot/oauthcb");
		return url.build();
	}

	//Client ID: 458072371664.apps.googleusercontent.com 
	//Email address: 458072371664@developer.gserviceaccount.com 
	//Client secret: mBp75wknGsGu0WMzHaHhqfXT
	// This is designed to simplify the flow in which an end-user authorizes the application to access their protected data,
	// and then the application has access to their data based on an access token and a refresh token to refresh that access
	// token when it expires. 
	// The first step is to call loadCredential(String) based on the known user ID to check if the end-user's credentials
	// are already known. If not, call newAuthorizationUrl() and direct the end-user's browser to an authorization page.
	// The web browser will then redirect to the redirect URL with a "code" query parameter which can then be used to request
	// an access token using newTokenRequest(String). Finally, use createAndStoreCredential(TokenResponse, String) to store
	// and obtain a credential for accessing protected resources. 

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
