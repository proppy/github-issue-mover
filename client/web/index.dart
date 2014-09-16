import 'dart:html';
import 'github.dart';
import 'package:cookie/cookie.dart' as cookie;

void main() {

  final String accessToken = cookie.get('access_token') == "" ? null :
      cookie.get('access_token');

  querySelector("#auth_button").addEventListener("click", (Event) {
    window.location.href = "/oauth_redirect";
  });

  if (accessToken != null) {
    // Hide the Authorize button block and show the move issues tooling block.
    querySelector("#authorize").style.display = "none";
    querySelector("#authorized").style.display = "block";
    // Instanciate a Github API accessor.
    GithubApiAccessor github = new GithubApiAccessor(accessToken);
    github.addGlobalErrorCallback((error){
      if (error.target.status == 403) {
        window.location.href = "/logout?error_message=Error:+token+must+have+been+revoked.+Please+re-authorize";
      }});
    // Request the currently signed in Github user.
    github.getUser().then((User user) {
      querySelector("#login").text = user.login;
      (querySelector("#photo") as ImageElement).src = user.avatarUrl;
      querySelector("#user").style.display = "block";
    }).catchError((error) {
      querySelector("#user").style.display = "none";
    });



  }

}
