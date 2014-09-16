library github_oauth;

import 'dart:async';
import 'package:http/http.dart';

// Incomplete Helper for OAuth 2.0 operations with the Github API.

class OauthGithubHelper {
  static final String authEndpoint = "https://github.com/login/oauth/authorize";
  static final Uri tokenEndpoint = Uri.parse("https://github.com/login/oauth/access_token");
  static final String identifier = "ac87a22403717c430941";
  static final String secret = "d027b0fb4b84e85eb799b8cb773fdb594cf3238e";
  static final String scopes = "repo";

  _OauthGithubHelper() {}

  static Uri getAuthorizationUrl(String redirectUri){
    return Uri.parse(authEndpoint + "?client_id=" + identifier + "&redirect_uri=" + redirectUri + "&scopes=" + scopes);
  }

  static Future<String> exchangeCodeForToken(String authCode, String redirectUri) {
    Completer<String> completer = new Completer<String>();
    Client cl = new Client();
    cl.post(tokenEndpoint, body: {
      "grant_type": "authorization_code",
      "code": authCode,
      "redirect_uri": redirectUri,
      "client_id": identifier,
      "client_secret": secret
    }).then((Response response) {
      if (response.statusCode != 200) {
        completer.completeError(response.body);
      } else {
        Map<String, String> data = parseFormUrlEncoded(response.body);
        if (data["access_token"] != null) {
          completer.complete(data["access_token"]);
        } else if (data["error"] != null) {
          completer.completeError(data["error"]);
        } else {
          completer.completeError(response.body);
        }
      }
    });
    return completer.future;
  }

  static Map<String, String> parseFormUrlEncoded(String formData) {
    Map<String, String> data = new Map<String, String>();
    Iterator<String> params = formData.split("&").iterator;
    while (params.moveNext()) {
      var paramAndValue = params.current.split("=");
      if (paramAndValue.length != 2) {
        continue;
      }
      data[paramAndValue.first] = paramAndValue.last;
    }
    return data;
  }
}
