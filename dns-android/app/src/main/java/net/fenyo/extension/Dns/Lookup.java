// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed

package net.fenyo.extension.Dns;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import android.util.Log;

public class Lookup implements FREFunction  {
	final Queries queries;
	
	public Lookup(final FREContext ctx) {
		queries = new Queries(ctx);
		queries.init();
	}

	public void cancel(final String host) {
		queries.cancel(host);
	}

	public FREObject call(FREContext ctx, FREObject passedArgs[]) {
		try {
			FREObject input = passedArgs[0];
			String host = input.getAsString();
			queries.query(host);

		} catch (final Exception ex) {
			ex.printStackTrace();
		}

		return null;
	}
}
