import 'dart:convert';
import 'dart:async';
import 'dart:html';


class GithubUrl {
  String fullName;
  String name;
  String issueNmber;
  String url;

  static GithubUrl parse(String url) {
    GithubUrl githubUrl = new GithubUrl();
    githubUrl.url = simplifyUrl(url);

    RegExp exp = new RegExp(r"^(\w+)\/(\w+)((#\d+)?)$");
    Match match = exp.firstMatch(githubUrl.url);
    if (match == null) {
      throw new FormatException("Wrong format of Github URL");
    }
    githubUrl.fullName = match.group(1) + "/" + match.group(2);
    githubUrl.name = match.group(2);
    githubUrl.issueNmber = match.group(3);

    return githubUrl;
  }

  // Takes a full Github URL e.g. "https://github.com/ForceUniverse/dart-forcemvc/issues/13"
  // and gives you the simplyfied version e.g. "ForceUniverse/dart-forcemvc#13"
  static String simplifyUrl(String url) {
    String simplifiedfUrl = url;
    if (simplifiedfUrl.startsWith("https://github.com/")) {
      simplifiedfUrl = simplifiedfUrl.substring("https://github.com/".length);
    }
    simplifiedfUrl = simplifiedfUrl.replaceFirst("/issues/", "#");
    simplifiedfUrl = simplifiedfUrl.replaceFirst("/issues", "");
    return simplifiedfUrl;
  }
}

class GithubApiAccessor {

  String accessToken;
  List<Function> _errorCallbacks = new List<Function>();

  GithubApiAccessor(String accessToken) {
    this.accessToken = accessToken;
  }

  void addGlobalErrorCallback(Function onError) {
    _errorCallbacks.add(onError);
  }

  void removeGlobalErrorCallback(Function onError) {
    _errorCallbacks.remove(onError);
  }

  Future<User> getUser() {
    Completer<User> completer = new Completer<User>();

    HttpRequest.request("https://api.github.com/user", method: "GET",
        responseType: "text", requestHeaders: {
      "authorization": "Bearer " + accessToken
    }).then((HttpRequest resp) {
      var json = JSON.decode(resp.responseText);
      User user = new User();
      user.fromJson(json);
      completer.complete(user);
    }).catchError((error) {
      _errorCallbacks.forEach((Function f) {
        f(error);
      });
      completer.completeError(error);
    });

    return completer.future;
  }

}

class User {
  String login;
  String avatarUrl;

  fromJson(json) {
    login = json["login"];
    avatarUrl = json["avatar_url"];
  }
}
