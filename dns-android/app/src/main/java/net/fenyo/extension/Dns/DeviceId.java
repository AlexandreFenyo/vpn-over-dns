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

public class DeviceId implements FREFunction {
	
	public DeviceId(final FREContext ctx) {
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
//Log.d("Alex", "DeviceId");
		try {
			return FREObject.newObject(Secure.getString(ctx.getActivity().getContentResolver(), Secure.ANDROID_ID));
		} catch (IllegalStateException e) {
			e.printStackTrace();
			return null;
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
			return null;
		}
	}
}
