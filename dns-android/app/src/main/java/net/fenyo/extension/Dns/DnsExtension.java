// (c) Alexandre Fenyo 2012, 2013, 2014, 2015, 2016 - alex@fenyo.net - http://fenyo.net - GPLv3 licensed


package net.fenyo.extension.Dns;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;
import android.util.Log;

/*
 * Initialization and finalization class of native extension.
 */

public class DnsExtension implements FREExtension
{
	/*
 	 * Extension initialization.
 	 */  
	public void initialize() {
        }

	public void finalize() { }

	public FREContext createContext(String extId) {
		return new DnsExtensionContext();
	}

	@Override
	public void dispose() {
	/*
	* Called if the extension is unloaded from the process. Extensions
	* are not guaranteed to be unloaded; the runtime process may exit without
	* doing so.
	*/
	}
}
