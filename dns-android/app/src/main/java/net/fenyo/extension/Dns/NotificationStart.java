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

public class NotificationStart implements FREFunction {
    private final NotificationInit notificationinit;

    public NotificationStart(final FREContext ctx, NotificationInit notificationinit) {
	this.notificationinit = notificationinit;
    }

    public FREObject call(FREContext ctx, FREObject passedArgs[]) {
// Log.d("Alex", "NotificationStart");

	if (notificationinit.getBuilder() != null && notificationinit.getManager() != null) {
	    String msg = "";

	    try {
		FREObject input = passedArgs[0];
		msg = input.getAsString();
	    } catch (final Exception ex) {
		ex.printStackTrace();
	    }

	    notificationinit.getBuilder().setSmallIcon(android.R.drawable.stat_sys_download).setContentText(msg);
	    Notification n;
	    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.JELLY_BEAN) {
		n = notificationinit.getBuilder().build();
	    } else {
		n = notificationinit.getBuilder().getNotification();
	    }
	    /* http://www.laurivan.com/android-make-your-notification-sticky/ */
	    n.flags |= Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT;
	    notificationinit.getManager().notify(1, n);
	}
	// Log.i("notification", "start");
	return null;
    }
}
