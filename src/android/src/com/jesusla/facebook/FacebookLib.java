package com.jesusla.facebook;

import java.net.URLEncoder;
import java.util.Date;
import java.util.UUID;

import org.json.JSONException;
import org.json.JSONObject;

import android.os.Bundle;
import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import junit.framework.Assert;

import com.facebook.*;
import com.facebook.widget.*;

import com.jesusla.ane.Context;
import com.jesusla.ane.Extension;

import com.facebook.android.R;
import java.lang.reflect.Field;

public class FacebookLib extends Context {
  static public FacebookLib staticReference;
  public String applicationId;
  public AccessToken oldAccessToken;
  public Session.StatusCallback sessionStatusCallback;
  public Activity customActivity;
  
  public FacebookLib() {
    FacebookLib.staticReference = this;
    registerFunction("applicationId", "getApplicationId");
    registerFunction("accessToken", "getAccessToken");
    registerFunction("expirationDate", "getExpirationDate");
    registerFunction("isFrictionlessRequestsEnabled");
    registerFunction("login");
    registerFunction("logout");
    registerFunction("extendAccessToken");
    registerFunction("extendAccessTokenIfNeeded");
    registerFunction("shouldExtendAccessToken");
    registerFunction("isSessionValid");
    registerFunction("enableFrictionlessRequests");
    registerFunction("reloadFrictionlessRecipientCache");
    registerFunction("isFrictionlessEnabledForRecipient");
    registerFunction("isFrictionlessEnabledForRecipients");
    registerFunction("showDialog");
    registerFunction("graph");
  }

  // reference: http://techiepulkit.blogspot.in/2013/01/air-android-native-extensions-speeding.html
  public int getResourceId(String resourceString) {
    String packageName = getActivity().getPackageName()+".R$";
	String[] arr = new String[2];
	arr = resourceString.split("\\.");
	try {
	  Class someObject = Class.forName(packageName+arr[0]);
	  Field someField = someObject.getField(arr[1]);
	  return someField.getInt(new Integer(0));
	}
	catch (Exception e) {
	  return 0;
	}
  }
  
  private void patchFacebookResourceIdsAtRuntime() {
	R.id.com_facebook_login_activity_progress_bar = getResourceId("id.com_facebook_login_activity_progress_bar"); 
    R.id.com_facebook_picker_activity_circle = getResourceId("id.com_facebook_picker_activity_circle"); 
    R.id.com_facebook_picker_checkbox = getResourceId("id.com_facebook_picker_checkbox"); 
    R.id.com_facebook_picker_checkbox_stub = getResourceId("id.com_facebook_picker_checkbox_stub"); 
    R.id.com_facebook_picker_divider = getResourceId("id.com_facebook_picker_divider"); 
    R.id.com_facebook_picker_done_button = getResourceId("id.com_facebook_picker_done_button"); 
    R.id.com_facebook_picker_image = getResourceId("id.com_facebook_picker_image"); 
    R.id.com_facebook_picker_list_section_header = getResourceId("id.com_facebook_picker_list_section_header"); 
    R.id.com_facebook_picker_list_view = getResourceId("id.com_facebook_picker_list_view"); 
    R.id.com_facebook_picker_profile_pic_stub = getResourceId("id.com_facebook_picker_profile_pic_stub"); 
    R.id.com_facebook_picker_row_activity_circle = getResourceId("id.com_facebook_picker_row_activity_circle"); 
    R.id.com_facebook_picker_title = getResourceId("id.com_facebook_picker_title"); 
    R.id.com_facebook_picker_title_bar = getResourceId("id.com_facebook_picker_title_bar"); 
    R.id.com_facebook_picker_title_bar_stub = getResourceId("id.com_facebook_picker_title_bar_stub"); 
    R.id.com_facebook_picker_top_bar = getResourceId("id.com_facebook_picker_top_bar"); 
    R.id.com_facebook_placepickerfragment_search_box_stub = getResourceId("id.com_facebook_placepickerfragment_search_box_stub"); 
    R.id.com_facebook_usersettingsfragment_login_button = getResourceId("id.com_facebook_usersettingsfragment_login_button"); 
    R.id.com_facebook_usersettingsfragment_logo_image = getResourceId("id.com_facebook_usersettingsfragment_logo_image"); 
    R.id.com_facebook_usersettingsfragment_profile_name = getResourceId("id.com_facebook_usersettingsfragment_profile_name"); 
    R.id.large = getResourceId("id.large"); 
    R.id.normal = getResourceId("id.normal"); 
    R.id.picker_subtitle = getResourceId("id.picker_subtitle"); 
    R.id.search_box = getResourceId("id.search_box"); 
    R.id.small = getResourceId("id.small"); 
	R.string.com_facebook_dialogloginactivity_ok_button = getResourceId("string.com_facebook_dialogloginactivity_ok_button");
    R.string.com_facebook_loginview_log_out_button = getResourceId("string.com_facebook_loginview_log_out_button");
    R.string.com_facebook_loginview_log_in_button = getResourceId("string.com_facebook_loginview_log_in_button");
    R.string.com_facebook_loginview_logged_in_as = getResourceId("string.com_facebook_loginview_logged_in_as");
    R.string.com_facebook_loginview_logged_in_using_facebook = getResourceId("string.com_facebook_loginview_logged_in_using_facebook");
    R.string.com_facebook_loginview_log_out_action = getResourceId("string.com_facebook_loginview_log_out_action");
    R.string.com_facebook_loginview_cancel_action = getResourceId("string.com_facebook_loginview_cancel_action");
    R.string.com_facebook_logo_content_description = getResourceId("string.com_facebook_logo_content_description");
    R.string.com_facebook_usersettingsfragment_log_in_button = getResourceId("string.com_facebook_usersettingsfragment_log_in_button");
    R.string.com_facebook_usersettingsfragment_logged_in = getResourceId("string.com_facebook_usersettingsfragment_logged_in");
    R.string.com_facebook_usersettingsfragment_not_logged_in = getResourceId("string.com_facebook_usersettingsfragment_not_logged_in");
    R.string.com_facebook_placepicker_subtitle_format = getResourceId("string.com_facebook_placepicker_subtitle_format");
    R.string.com_facebook_placepicker_subtitle_catetory_only_format = getResourceId("string.com_facebook_placepicker_subtitle_catetory_only_format");
    R.string.com_facebook_placepicker_subtitle_were_here_only_format = getResourceId("string.com_facebook_placepicker_subtitle_were_here_only_format");
    R.string.com_facebook_picker_done_button_text = getResourceId("string.com_facebook_picker_done_button_text");
    R.string.com_facebook_choose_friends = getResourceId("string.com_facebook_choose_friends");
    R.string.com_facebook_nearby = getResourceId("string.com_facebook_nearby");
    R.string.com_facebook_loading = getResourceId("string.com_facebook_loading");
    R.string.com_facebook_internet_permission_error_title = getResourceId("string.com_facebook_internet_permission_error_title");
    R.string.com_facebook_internet_permission_error_message = getResourceId("string.com_facebook_internet_permission_error_message");
    R.string.com_facebook_requesterror_web_login = getResourceId("string.com_facebook_requesterror_web_login");
    R.string.com_facebook_requesterror_relogin = getResourceId("string.com_facebook_requesterror_relogin");
    R.string.com_facebook_requesterror_password_changed = getResourceId("string.com_facebook_requesterror_password_changed");
    R.string.com_facebook_requesterror_reconnect = getResourceId("string.com_facebook_requesterror_reconnect");
    R.string.com_facebook_requesterror_permissions = getResourceId("string.com_facebook_requesterror_permissions");

  }
  
  @Override
  protected void initContext() {
    Extension.debug("FacebookLib::initContext");
	
	sessionStatusCallback = new Session.StatusCallback() {
      @Override
	  public void call(Session session, SessionState state, Exception exception) {
	    // dispatch the login response for user initiated sessions but not my autosession
		if (customActivity.getIntent().getBooleanExtra("allowLoginUI", false)) {
	      if (state == SessionState.CLOSED_LOGIN_FAILED) {
	        dispatchStatusEventAsync("LOGIN_FAILED", "SESSION");
	      }
	      if ((state == SessionState.OPENED)||(state == SessionState.OPENED_TOKEN_UPDATED)) {
	        dispatchStatusEventAsync("LOGIN", "SESSION");
	      }
		}
	  }
    };

	// the sdk ids get remapped when ADT process Android ANEs
	patchFacebookResourceIdsAtRuntime();
	
    // use our fbAppID instead of com.facebook.sdk.ApplicationId
    applicationId = getProperty("FacebookAppID");
	Extension.debug("FacebookAppID = "+ applicationId);

    Settings.setShouldAutoPublishInstall(true); 
	
	// readOldAccessToken() {
    SharedPreferences preferences = getActivity().getPreferences(Activity.MODE_PRIVATE);
    String accessToken = preferences.getString("FBAccessTokenKey", null);
    long accessExpires = preferences.getLong("FBExpirationDateKey", 0);
    long lastAccessUpdate = preferences.getLong("FBLastAccessUpdate", 0);
    if (accessToken != null) {
      oldAccessToken = AccessToken.createFromExistingAccessToken(accessToken, new Date(accessExpires), new Date(lastAccessUpdate), null, null);
	  // removeOldAccessToken() {
      SharedPreferences.Editor editor = preferences.edit();
      editor.remove("FBAccessTokenKey");
      editor.remove("FBExpirationDateKey");
      editor.remove("FBLastAccessUpdate");
      editor.commit();
    }
	
	// Previously, the sessionValid flag was used and extended to say: we know we've got credentials, just reuse them
	// To emulate and improve that behavior, I attempt a silent login at launch, which takes the place of extending credentials from before
	startLoginActivity(false);
  }

  public String getApplicationId() {
    return applicationId;
  }

  public String getAccessToken() {
    if (isSessionValid()) {
	  return Session.getActiveSession().getAccessToken();
	}
    return null;
  }

  public Date getExpirationDate() {
	if (isSessionValid()) {
	  Date expires = Session.getActiveSession().getExpirationDate();
      return expires;
	}
	return null;
  }
  
  public void login(String[] permissions) {
	Extension.debug("FacebookLib::login");
	// Extension.debug("FacebookLib::isSessionValid = " + isSessionValid());
	// Extension.debug("FacebookLib::customActivity = " + customActivity);
	
	// don't bother with the login unless necessary
	if ((isSessionValid() == false) || (customActivity == null)) {
	  startLoginActivity(true);
	}
	else {
	  dispatchStatusEventAsync("LOGIN", "SESSION");
	}
  }

  private void startLoginActivity(boolean allowLoginUI) {
    // we don't want multiple login activities spinning up
	if (customActivity != null) {
	  customActivity.finish();
	  Extension.debug("FacebookLib::Sanity Check! startLoginActivity called with not-null customActivity");
	}
	Intent intent = new Intent(getActivity(), CustomActivity.class);
	intent.putExtra("allowLoginUI", allowLoginUI);
    getActivity().startActivity(intent);
  }

  public void logout() {
	if (isSessionValid()) {
	  Session.getActiveSession().closeAndClearTokenInformation();
	}
	if (customActivity != null) {
	  customActivity.finish();
	}
    dispatchStatusEventAsync("LOGOUT", "SESSION");
  }

  public boolean isFrictionlessRequestsEnabled() {
    return false;
  }

  public void extendAccessToken() {
    Extension.debug("extendAccessToken is deprecated");
  }

  public void extendAccessTokenIfNeeded() {
    Extension.debug("extendAccessTokenIfNeeded is deprecated");
  }

  public boolean shouldExtendAccessToken() {
    Extension.debug("shouldExtendAccessToken is deprecated");
    return false;
  }

  static public boolean isSessionValid() {
    Session session = Session.getActiveSession();
    if (session != null) {
      return session.isOpened();
    }
    return false;
  }

  public void enableFrictionlessRequests() {
  }

  public void reloadFrictionlessRecipientCache() {
  }

  public boolean isFrictionlessEnabledForRecipient(String fbid) {
    return false;
  }

  public boolean isFrictionlessEnabledForRecipients(String[] fbids) {
    return false;
  }

  public void showDialog(String action, Bundle params) {
      Session session = Session.getActiveSession();
	  Assert.assertEquals(session.isOpened(), true);
      WebDialog.OnCompleteListener onComplete = new WebDialog.OnCompleteListener() {
      @Override
      public void onComplete(Bundle values, FacebookException error) {
        if (error == null) {
          String url = encodeBundle(values);
          asyncFlashCall(null, null, "dialogDidComplete", url);
        } else if (error instanceof FacebookOperationCanceledException) {
          // User clicked the "x" button
          String url = encodeBundle(values);
          asyncFlashCall(null, null, "dialogDidNotComplete", url);
        } else {
          // Generic, ex: network error
          String url = encodeBundle(values);
          asyncFlashCall(null, null, "dialogDidFailWithError", url);
        }
      }
    };

    String method = params.getString("method");
    if (method.equalsIgnoreCase("feed")) {
      WebDialog feedDialog =
        new WebDialog.FeedDialogBuilder(customActivity, Session.getActiveSession(), params)
      .setOnCompleteListener(onComplete)
      .build();
      feedDialog.show();
    }
    else if (method.equalsIgnoreCase("apprequests")) {
      WebDialog requestDialog =
        new WebDialog.RequestsDialogBuilder(customActivity,Session.getActiveSession(), params)
      .setOnCompleteListener(onComplete)
      .build();
      requestDialog.show();
    }
  }

  public String graph(String graphPath, Bundle params, String httpMethodString) {
    final String uuid = UUID.randomUUID().toString();
    Session session = Session.getActiveSession();
	Assert.assertEquals(session.isOpened(), true);

    Request.Callback callback = new Request.Callback() {
      @Override
      public void onCompleted(Response response) {
		if (response.getGraphObject() != null) {
		  try {
            JSONObject data = new JSONObject(response.getGraphObject().asMap());
            asyncFlashCall(null, null, "requestDidLoad", uuid, data);
          } 
		  catch (NullPointerException e) {
            Extension.debug("Extension.fail Parsing '%s'", response.getGraphObject().asMap());
		    asyncFlashCall(null, null, "requestDidFailWithError", uuid, e);
          }
		}
		else {
		  asyncFlashCall(null, null, "requestDidFailWithError", uuid, response.getError());
		}
      }
    };
    HttpMethod httpMethod = HttpMethod.GET;
    if (httpMethodString.equalsIgnoreCase("delete")) {
      httpMethod = HttpMethod.DELETE;
    }
    if (httpMethodString.equalsIgnoreCase("post")) {
      httpMethod = HttpMethod.POST;
    }
    Request request = new Request(session, graphPath, params, httpMethod, callback);
    request.executeAsync();
    return uuid;
  }

  private String encodeBundle(Bundle bundle) {
    String url = "fbconnect://success";
	if (bundle != null ) {
	  url += "?";
	  for (String key : bundle.keySet()) {
	    String val = bundle.getString(key);
	    key = URLEncoder.encode(key);
	    val = URLEncoder.encode(val);
	    if (!url.endsWith("?"))
  		  url += '&';
	    url = url + key + '=' + val;
	  }
	}
    return url;
  }
}
