// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.mail4hotspot.web;

import java.io.IOException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.auth.oauth2.CredentialStore;

public class MyCredentialStore implements CredentialStore {
	protected final Log log = LogFactory.getLog(getClass());

	public boolean load(String userId, Credential credential)
			throws IOException {
		// TODO Auto-generated method stub
		log.debug("load(" + userId + ", " + credential.toString() + ")");
		return true;
	}

	public void store(String userId, Credential credential) throws IOException {
		// TODO Auto-generated method stub
		log.debug("store(" + userId + ", " + credential.toString() + ")");
	}

	public void delete(String userId, Credential credential) throws IOException {
		// TODO Auto-generated method stub
		log.debug("delete(" + userId + ", " + credential.toString() + ")");
	}

}
