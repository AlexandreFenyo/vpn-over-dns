// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.io.*;
import java.net.*;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;

import javax.net.ssl.HttpsURLConnection;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class SslGet implements FREFunction, Runnable {
	private FREContext ctx = null;

	private String url = null;
	private String query = null;
	private int timeout = 0;

	public SslGet(final FREContext ctx) {
		this.ctx = ctx;
	}

	@Override
	public void run() {
		StringBuffer response = new StringBuffer();
		HttpURLConnection urlConnection = null;

		try {
			urlConnection = (HttpsURLConnection) new URL(url).openConnection();

			urlConnection.setConnectTimeout(timeout);
			urlConnection.setReadTimeout(timeout);

			// si on connait la taille, on l'indique
			urlConnection.setRequestProperty("Content-Length", "" + Integer.toString(query.getBytes().length));
			// si on ne connait pas la taille (mais pour un post ca passe pas le squid)
			// urlConnection.setChunkedStreamingMode(0);

			urlConnection.setRequestMethod("POST");
			urlConnection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
			urlConnection.setUseCaches(false);
			urlConnection.setDoInput(true);
			urlConnection.setDoOutput(true);

			final DataOutputStream wr = new DataOutputStream(urlConnection.getOutputStream());
			wr.writeBytes(query);
			wr.flush();
			wr.close();

			final InputStream is = urlConnection.getInputStream();
			final BufferedReader rd = new BufferedReader(new InputStreamReader(is));
			String line;
			while((line = rd.readLine()) != null) response.append(line + "\n");
			rd.close();

		} catch (final IOException ex) {
			ctx.dispatchStatusEventAsync("ERROR", ex.toString());
			return;
		} finally {
		     if (urlConnection != null) urlConnection.disconnect();
		}
		ctx.dispatchStatusEventAsync("OK", response.toString());
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		try {
			FREObject input1 = passedArgs[0];
			url = input1.getAsString();

			FREObject input2 = passedArgs[1];
			query = input2.getAsString();

			FREObject input3 = passedArgs[2];
			timeout = input3.getAsInt();

			new Thread(this).start();

		} catch (final Exception ex) {
			ex.printStackTrace();
		}

		return null;
	}
}
