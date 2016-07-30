// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class Cancel implements FREFunction  {
	private final Lookup lookup;

	public Cancel(final FREContext ctx, final Lookup lookup) {
		this.lookup = lookup;
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		try {
			FREObject input = passedArgs[0];
			String host = input.getAsString();
			lookup.cancel(host);

		} catch (final Exception ex) {
			ex.printStackTrace();
		}

		return null;
	}
}
