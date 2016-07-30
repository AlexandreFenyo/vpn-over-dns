// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import java.io.*;
import java.net.*;
import java.nio.charset.Charset;

import javax.net.ssl.HttpsURLConnection;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

public class NotificationActivity extends Activity {
	public NotificationActivity() {
		Log.i("NotificationActivity", "constructeur()");
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		Log.i("NotificationActivity", "onCreate()");
		super.onCreate(savedInstanceState);
		finish();
	}
}
