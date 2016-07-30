// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREWrongThreadException;

import android.provider.Settings.Secure;
import android.util.Log;

import android.app.*;
import android.os.*;
import android.content.*;

public class NotificationInit implements FREFunction {
    private Notification.Builder builder = null;
    private NotificationManager manager = null;

    public Notification.Builder getBuilder() {
	return builder;
    }

    public NotificationManager getManager() {
	return manager;
    }

	public NotificationInit(final FREContext ctx) {
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
// Log.d("Alex", "NotificationInit");
		try {
			Intent intent = new Intent(ctx.getActivity(), NotificationActivity.class);
			PendingIntent pendingIntent = PendingIntent.getActivity(ctx.getActivity(),
				1, intent, PendingIntent.FLAG_UPDATE_CURRENT);

			builder = new Notification.Builder(ctx.getActivity())
			.setSmallIcon(android.R.drawable.stat_sys_download_done)
			.setContentTitle("VPN-over-DNS")
			.setContentIntent(pendingIntent)
			.setContentText("Running");

			Notification n;
			if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.JELLY_BEAN) {
				n = builder.build();
			} else {
				n = builder.getNotification();
			}
			/* http://www.laurivan.com/android-make-your-notification-sticky/ */
			n.flags |= Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT;

			manager = 
				(NotificationManager) ctx.getActivity().getSystemService(Context.NOTIFICATION_SERVICE);
			manager.notify(1, n);

			
		} catch (IllegalStateException e) {
			e.printStackTrace();
		}

		return null;
	}
}
