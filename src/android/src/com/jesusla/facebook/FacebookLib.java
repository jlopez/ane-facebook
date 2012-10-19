package com.jesusla.facebook;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URLEncoder;
import java.util.Date;
import java.util.UUID;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;

import com.facebook.android.AsyncFacebookRunner;
import com.facebook.android.AsyncFacebookRunner.RequestListener;
import com.facebook.android.DialogError;
import com.facebook.android.Facebook;
import com.facebook.android.Facebook.DialogListener;
import com.facebook.android.Facebook.ServiceListener;
import com.facebook.android.FacebookError;
import com.jesusla.ane.Context;
import com.jesusla.ane.CustomActivityListener;
import com.jesusla.ane.Extension;

public class FacebookLib extends Context {
  private Facebook facebook;
  private AsyncFacebookRunner asyncRunner;
  private String applicationId;

  public FacebookLib() {
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

  @Override
  protected void initContext() {
    applicationId = getProperty("FacebookAppID");
    facebook = new Facebook(applicationId);
    asyncRunner = new AsyncFacebookRunner(facebook);
    readToken();
    facebook.publishInstall(getActivity());
  }

  public String getApplicationId() {
    return applicationId;
  }

  public String getAccessToken() {
    return facebook.getAccessToken();
  }

  public Date getExpirationDate() {
    long expires = facebook.getAccessExpires();
    if (expires == 0)
      return null;
    return new Date(expires);
  }

  public void login(String[] permissions) {
    startActivity(new CustomActivityListener() {
      @Override public void onCreate(Activity activity, Bundle savedInstanceState) {
        facebook.authorize(activity, loginListener);
      }

      @Override
      public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        facebook.authorizeCallback(requestCode, resultCode, data);
      }
    });
  }

  public void logout() {
    asyncRunner.logout(getActivity(), logoutListener);
  }

  public boolean isFrictionlessRequestsEnabled() {
    return false;
  }

  public void extendAccessToken() {
    facebook.extendAccessToken(getActivity(), tokenListener);
  }

  public void extendAccessTokenIfNeeded() {
    facebook.extendAccessTokenIfNeeded(getActivity(), tokenListener);
  }

  public boolean shouldExtendAccessToken() {
    return facebook.shouldExtendAccessToken();
  }

  public boolean isSessionValid() {
    return facebook.isSessionValid();
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
    facebook.dialog(getActivity(), action, params, dialogListener);
  }

  public String graph(String graphPath, Bundle params, String httpMethod) {
    String uuid = UUID.randomUUID().toString();
    asyncRunner.request(graphPath, params, httpMethod, requestListener, uuid);
    return uuid;
  }

  private final DialogListener loginListener = new DialogListener() {
    @Override public void onFacebookError(FacebookError e) { dispatchStatusEventAsync("LOGIN_FAILED", "SESSION"); }
    @Override public void onError(DialogError e) { dispatchStatusEventAsync("LOGIN_FAILED", "SESSION"); }
    @Override public void onCancel() { dispatchStatusEventAsync("LOGIN_CANCELED", "SESSION"); }
    @Override public void onComplete(Bundle values) {
      updateToken();
      dispatchStatusEventAsync("LOGIN", "SESSION");
    }
  };

  private final RequestListener logoutListener = new RequestListener() {
    @Override public void onMalformedURLException(MalformedURLException e, Object state) { Extension.warn(e, "Facebook.logout()"); }
    @Override public void onIOException(IOException e, Object state) { Extension.warn(e, "Facebook.logout()"); }
    @Override public void onFileNotFoundException(FileNotFoundException e, Object state) { Extension.warn(e, "Facebook.logout()"); }
    @Override public void onFacebookError(FacebookError e, Object state) { Extension.warn(e, "Facebook.logout()"); }
    @Override public void onComplete(String response, Object state) {
      removeToken();
      dispatchStatusEventAsync("LOGOUT", "SESSION");
    }
  };

  private final ServiceListener tokenListener = new ServiceListener() {
    @Override public void onFacebookError(FacebookError e) { Extension.fail(e, "Facebook.extendAccessToken()"); }
    @Override public void onError(Error e) { Extension.fail(e, "Facebook.extendAccessToken()"); }
    @Override public void onComplete(Bundle values) {
      updateToken();
      dispatchStatusEventAsync("ACCESS_TOKEN_EXTENDED", "SESSION");
    }
  };

  private final DialogListener dialogListener = new DialogListener() {
    @Override public void onFacebookError(FacebookError e) { asyncFlashCall(null, null, "dialogDidFailWithError", ""); }
    @Override public void onError(DialogError e) { asyncFlashCall(null, null, "dialogDidFailWithError", ""); }
    @Override public void onCancel() { asyncFlashCall(null, null, "dialogDidNotComplete", ""); }
    @Override public void onComplete(Bundle values) {
      String url = encodeBundle(values);
      asyncFlashCall(null, null, "dialogDidComplete", url);
    }
  };

  private final RequestListener requestListener = new RequestListener() {
    @Override public void onMalformedURLException(MalformedURLException e, Object state) { fail(e, state); }
    @Override public void onIOException(IOException e, Object state) { fail(e, state); }
    @Override public void onFileNotFoundException(FileNotFoundException e, Object state) { fail(e, state); }
    @Override public void onFacebookError(FacebookError e, Object state) { fail(e, state); }
    @Override public void onComplete(String response, Object state) {
      try {
        JSONObject data = new JSONObject(response);
        asyncFlashCall(null, null, "requestDidLoad", state, data);
      } catch (JSONException e) {
        Extension.fail(e, "Parsing '%s'", response);
      }
    }

    private void fail(Throwable t, Object uuid) {
      asyncFlashCall(null, null, "requestDidFailWithError", uuid, "error");
    }
  };

  private void readToken() {
    SharedPreferences preferences = getActivity().getPreferences(Activity.MODE_PRIVATE);
    String accessToken = preferences.getString("FBAccessTokenKey", null);
    long accessExpires = preferences.getLong("FBExpirationDateKey", 0);
    long lastAccessUpdate = preferences.getLong("FBLastAccessUpdate", 0);
    if (accessToken != null)
      facebook.setTokenFromCache(accessToken, accessExpires, lastAccessUpdate);
  }

  private void updateToken() {
    SharedPreferences.Editor editor = getActivity().getPreferences(Activity.MODE_PRIVATE).edit();
    editor.putString("FBAccessTokenKey", facebook.getAccessToken());
    editor.putLong("FBExpirationDateKey", facebook.getAccessExpires());
    editor.putLong("FBLastAccessUpdate", facebook.getLastAccessUpdate());
    editor.commit();
  }

  private void removeToken() {
    SharedPreferences.Editor editor = getActivity().getPreferences(Activity.MODE_PRIVATE).edit();
    editor.remove("FBAccessTokenKey");
    editor.remove("FBExpirationDateKey");
    editor.remove("FBLastAccessUpdate");
    editor.commit();
  }

  private String encodeBundle(Bundle bundle) {
    String url = "fbconnect://success?";
    for (String key : bundle.keySet()) {
      String val = bundle.getString(key);
      key = URLEncoder.encode(key);
      val = URLEncoder.encode(val);
      if (!url.endsWith("?"))
        url += '&';
      url = url + key + '=' + val;
    }
    return url;
  }
}
