/*********************************************************************************************************
* ADOBE SYSTEMS INCORPORATED
* Copyright 2011 Adobe Systems Incorporated
* All Rights Reserved.
*
* NOTICE:  Adobe permits you to use, modify, and distribute this file in accordance with the 
* terms of the Adobe license agreement accompanying it.  If you have received this file from a 
* source other than Adobe, then your use, modification, or distribution of it requires the prior 
* written permission of Adobe.
*
*********************************************************************************************************/


package com.adobe.air.sampleextensions.android.licensing;

import com.adobe.fre.FREContext;
import com.google.android.vending.licensing.LicenseCheckerCallback;

import android.util.Log;


/* 
 * LVL after checking with the licensing server and conferring with the policy makes callbacks to communicate  
 * result with the application using callbacks i.e AndroidLicenseCheckerCallback in this case.
 * AndroidLicenseCheckerCallback then dipatches StatusEventAsync event to communicate the result obtained from LVL
 * with the ActionScript library.
 */

public class AndroidLicenseCheckerCallback implements LicenseCheckerCallback{

	private static final String EMPTY_STRING = "";
	private static final String LICENSED = "licensed"; 
	private static final String NOT_LICENSED = "notLicensed";
	private static final String ERROR_CHECK_IN_PROGRESS = "checkInProgress";
	private static final String ERROR_INVALID_PACKAGE_NAME = "invalidPackageName";
	private static final String ERROR_INVALID_PUBLIC_KEY = "invalidPublicKey";
	private static final String ERROR_MISSING_PERMISSION = "missingPermission";
	private static final String ERROR_NON_MATCHING_UID = "nonMatchingUID";
	private static final String ERROR_NOT_MARKET_MANAGED = "notMarketManaged";
	
	private FREContext mFREContext;
	

	public AndroidLicenseCheckerCallback(FREContext freContext) {
// Log.i("vpnoverdns", "AndroidLicenceCheckerCallback()");
		mFREContext = freContext;
	}


	public void allow(int reason) {
// Log.i("vpnoverdns", "allow(): " + reason);
		// mFREContext.dispatchStatusEventAsync(LICENSED, EMPTY_STRING);
		mFREContext.dispatchStatusEventAsync(LICENSED, EMPTY_STRING + reason);
	}


	public void dontAllow(int reason) {
// Log.i("vpnoverdns", "dontAllow(): " + reason);
		// mFREContext.dispatchStatusEventAsync(NOT_LICENSED, EMPTY_STRING);
		mFREContext.dispatchStatusEventAsync(NOT_LICENSED, EMPTY_STRING + reason);
	}

	/*
 	 * This function maps the ApplicationErrorCode obtained from LVL to the LicenseStatusReason of ActionScript library.
 	 */ 

//    public static final int ERROR_INVALID_PACKAGE_NAME = 1;
//    public static final int ERROR_NON_MATCHING_UID = 2;
//    public static final int ERROR_NOT_MARKET_MANAGED = 3;
//    public static final int ERROR_CHECK_IN_PROGRESS = 4;
//    public static final int ERROR_INVALID_PUBLIC_KEY = 5;
//    public static final int ERROR_MISSING_PERMISSION = 6;

	@Override
	public void applicationError(int errorCode) {
// Log.i("vpnoverdns", "applicationError(): " + errorCode);

		String errorMessage = EMPTY_STRING;

		switch(errorCode)
		{
			case LicenseCheckerCallback.ERROR_CHECK_IN_PROGRESS :
				errorMessage = ERROR_CHECK_IN_PROGRESS;
				break;
			case LicenseCheckerCallback.ERROR_INVALID_PACKAGE_NAME :	
				errorMessage = ERROR_INVALID_PACKAGE_NAME;
				break;
			case LicenseCheckerCallback.ERROR_INVALID_PUBLIC_KEY :
				errorMessage = ERROR_INVALID_PUBLIC_KEY;
				break;
			case LicenseCheckerCallback.ERROR_MISSING_PERMISSION :
				errorMessage = ERROR_MISSING_PERMISSION;
				break;
			case LicenseCheckerCallback.ERROR_NON_MATCHING_UID :
				errorMessage = ERROR_NON_MATCHING_UID;
				break;
			case LicenseCheckerCallback.ERROR_NOT_MARKET_MANAGED :
				errorMessage = ERROR_NOT_MARKET_MANAGED;
				break;
		}
		mFREContext.dispatchStatusEventAsync(NOT_LICENSED, errorMessage);
	}
}
