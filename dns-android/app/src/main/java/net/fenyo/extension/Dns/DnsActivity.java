// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.io.*;
import java.net.*;
import java.nio.charset.Charset;

import javax.net.ssl.HttpsURLConnection;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

public class DnsActivity extends Activity {

	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
		Log.i("DnsActivity", "onCreate()");

		super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        final String query = "username=fenyog&password=xxxxxx&info=toto";

        // pour utiliser le proxy du système : http://developer.android.com/reference/java/net/ProxySelector.html
        // ProxySelector.setDefault / ProxySelector.getDefault()

        // cf HttpsURLConnection
		HttpsURLConnection urlConnection = null;
		try {
			urlConnection = (HttpsURLConnection) new URL("https://www.fenyo.fr/mail4hotspot/app/mobile-get-user").openConnection();

			//urlConnection = (HttpURLConnection) new URL("http://10.69.126.84/mail4hotspot/app/mobile-get-user").openConnection();
//			urlConnection = (HttpURLConnection) new URL("http://www.fenyo.fr/mail4hotspot/app/mobile-get-user").
//					openConnection(
//							new Proxy(Proxy.Type.HTTP, new InetSocketAddress(Inet4Address.getByName("172.35.255.13"), 80)
//							));
			Log.i("DnsActivity", "après openConnection()");

			// bug android avec l'utilisation d'un proxy (par ex positionné par le système) : il met l'IP ou le nom du proxy dans l'indicateur SNI donc ca perturbe apache qui refuse la connexion : "[Mon Jul 16 14:45:19 2012] [error] Hostname 10.69.126.84 provided via SNI and hostname www.fenyo.fr provided via HTTP are different"
			// rq : ce bug n'apparaît pas via le navigateur

			// si on connait la taille
			urlConnection.setRequestProperty("Content-Length", "" + Integer.toString(query.getBytes().length));
			// si on ne connait pas la taille (mais pour un post ca passe pas le squid)
			// urlConnection.setChunkedStreamingMode(0);

			urlConnection.setRequestMethod("POST");
			urlConnection.setRequestProperty("Host", "10.69.126.84");
			urlConnection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
			urlConnection.setUseCaches(false);
			urlConnection.setDoInput(true);
			urlConnection.setDoOutput(true);

			DataOutputStream wr = new DataOutputStream(urlConnection.getOutputStream());
			wr.writeBytes(query);
			wr.flush();
			wr.close();

			InputStream is = urlConnection.getInputStream();
			BufferedReader rd = new BufferedReader(new InputStreamReader(is));
			String line;
			StringBuffer response = new StringBuffer();
			while((line = rd.readLine()) != null) {
				response.append(line);
				response.append('\r');
			}
			rd.close();

			Log.i("DnsActivity", "result: " + response.toString());

		} catch (final IOException ex) {
			Log.i("DnsActivity", "exception IOException " + ex.toString());
			
		} finally {
			Log.i("DnsActivity", "dans finally");
			if (urlConnection != null) urlConnection.disconnect();
		}

		System.exit(0);
    }
}
