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

public class Trace implements FREFunction {
	
	public Trace(final FREContext ctx) {
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
	    final String retval = "no value";

	    try {
		FREObject input1 = passedArgs[0];
		Log.i("vpnoverdns", input1.getAsString());
	    } catch (final Exception ex) {
		ex.printStackTrace();
	    }
	    
	    try {
		return FREObject.newObject(retval);
	    } catch (IllegalStateException e) {
		e.printStackTrace();
		return null;
	    } catch (FREWrongThreadException e) {
		e.printStackTrace();
		return null;
	    }
	}
}
