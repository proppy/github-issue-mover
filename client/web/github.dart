import 'dart:convert';
import 'dart:async';
import 'dart:html';


class GithubUrl {
  String ownerName;
  String repoName;
  String issueNumber;
  String simplifiedUrl;
  String fullUrl;

  // Parses a Github URL into subcomponents. Only works for repos and Issues URLs for now.
  static GithubUrl parse(String url) {
    GithubUrl githubUrl = new GithubUrl();
    githubUrl.fullUrl = url;
    githubUrl.simplifiedUrl = simplifyUrl(url);

    RegExp exp = new RegExp(r"([\w-_\.]+)\/([\w-_\.]+)(\#(\d+))?");
    Match match = exp.firstMatch(githubUrl.simplifiedUrl);
    if (match == null) {
      throw new FormatException("Wrong format of Github URL");
    }
    githubUrl.ownerName = match.group(1);
    githubUrl.repoName = match.group(2);
    githubUrl.issueNumber = match.group(4);

    return githubUrl;
  }

  // Takes a full Github URL e.g. "https://github.com/ForceUniverse/dart-forcemvc/issues/13"
  // and gives you the simplified version e.g. "ForceUniverse/dart-forcemvc#13"
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

// Interface to the Github API
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

  // Perfoms an OAuth 2 authenticated request and returns a JSON object of the response.
  Future<dynamic> authorizedRequest(String url, String method, [body]){
    Completer<dynamic> completer = new Completer<dynamic>();

    HttpRequest.request(url, method: method, responseType: "text", sendData: body, requestHeaders: {
        "authorization": "Bearer " + accessToken
    }).then((HttpRequest resp) {
        var json = JSON.decode(resp.responseText);
        completer.complete(json);
    }).catchError((error) {
        _errorCallbacks.forEach((Function f) {
            f(error);
        });
        completer.completeError(error);
    });
    return completer.future;
  }

  // Returns the currently authorized user.
  Future<User> getAuthorizedUser() {
    Completer<User> completer = new Completer<User>();

    authorizedRequest("https://api.github.com/user", "GET").then((var json) {
        completer.complete(User.fromJson(json));
    }).catchError((error) => completer.completeError(error));

    return completer.future;
  }

  // Returns the details of the given issue.
  Future<Issue> getIssue(String ownerName, String repoName, String issueNumber) {
     Completer<Issue> completer = new Completer<Issue>();

     authorizedRequest("https://api.github.com/repos/$ownerName/$repoName/issues/$issueNumber",
         "GET").then((var json) {
             completer.complete(Issue.fromJson(json));
     }).catchError((error) => completer.completeError(error));

     return completer.future;
  }

  // Updates the given issue.
  Future<Issue> updateIssue(Issue issue) {
     Completer<Issue> completer = new Completer<Issue>();

     authorizedRequest(issue.url,
         "PATCH", issue.toJson()).then((var json) {
             completer.complete(Issue.fromJson(json));
     }).catchError((error) => completer.completeError(error));

     return completer.future;
  }

  // Creates the given issue.
  Future<Issue> createIssue(Issue issue) {
     Completer<Issue> completer = new Completer<Issue>();

     authorizedRequest("https://api.github.com/repos/${issue.htmlUrl.ownerName}/${issue.htmlUrl.repoName}/issues",
         "POST", issue.toJson()).then((var json) {
             completer.complete(Issue.fromJson(json));
     }).catchError((error) => completer.completeError(error));

     return completer.future;
  }

  // Returns all comments of an issue.
  Future<List<Comment>> getComments(Issue issue) {
     Completer<List<Comment>> completer = new Completer<List<Comment>>();

     authorizedRequest(issue.commentsUrl, "GET").then((var json) {
         List commentsJson = json;
         List<Comment> comments = new List<Comment>();
         for(var commentJson in commentsJson) {
           Comment comment = Comment.fromJson(commentJson);
           comments.add(comment);
         }
         completer.complete(comments);
     }).catchError((error) => completer.completeError(error));

     return completer.future;
  }

  // Adds the list of given comments to the issue.
  Future<List<Comment>> addCommentsToIssue(List<Comment> comments, Issue issue, [Function track = null]) {
     Completer<List<Comment>> completer = new Completer<List<Comment>>();

     if (comments.length != 0) {
       _createCommentRecur(issue, comments, new List<Comment>(), completer, track);
     } else {
       completer.complete(new List<Comment>());
     }

     return completer.future;
  }

  _createCommentRecur(Issue issue, List<Comment> remainingCommentsToAdd,
                      List<Comment> commentsAdded, Completer<List<Comment>> completer,
                      [Function track]) {
    Comment nextCommentToAdd = remainingCommentsToAdd.removeAt(0);

    authorizedRequest(issue.commentsUrl, "POST", nextCommentToAdd.toJson()).then((var json) {
      commentsAdded.add(Comment.fromJson(json));
      if (track != null) {
        track(commentsAdded.length, remainingCommentsToAdd.length + commentsAdded.length); // call the tracker if it exists. We pass the number of issues already crated over the total.
      }
      if(remainingCommentsToAdd.isEmpty) {
        completer.complete(commentsAdded);
      } else {
        // 1 sec between issue creation to avoid issues being created in the wrong order becasue of a bug in the Github API.
        var timer = new Timer(new Duration(milliseconds: 1000), (){
          _createCommentRecur(issue, remainingCommentsToAdd, commentsAdded, completer, track);
        });
      }
    }).catchError((error) => completer.completeError(error));
  }

  // Fetches all repos belonging to the given owner
  Future<List<Repo>> getRepos(String owner, [int page = 1, List<Repo> repos, Completer<List<Repo>> completer]) {
    if (completer == null) completer = new Completer<List<Repo>>();
    if (repos == null) repos = new List<Repo>();

    authorizedRequest("https://api.github.com/users/$owner/repos?sort=full_name&page=$page", "GET").then((var json) {
        List reposJson = json;
        if (reposJson.length == 0) {
          completer.complete(repos);
        } else {
          for(var repoJson in reposJson) {
            Repo repo = Repo.fromJson(reposJson);
            repos.add(repo);
            getRepos(owner, page + 1, repos, completer);
          }
        }
    }).catchError((error) => completer.completeError(error));

    return completer.future;
  }

  // Fetches details for 1 repo
  Future<Repo> getRepo(String ownerName, String repoName) {
    Completer<Repo> completer = new Completer<Repo>();

    authorizedRequest("https://api.github.com/repos/$ownerName/$repoName", "GET").then((var json) {
      Repo repo = Repo.fromJson(json);
      completer.complete(repo);
    }).catchError((error) => completer.completeError(error));

    return completer.future;
  }

}

// Represents a Repo
class Repo {
  String fullName;
  String name;
  GithubUrl htmlUrl;
  String description;
  User owner;

  static Repo fromJson(json) {
    Repo repo = new Repo();
    repo.fullName = json["full_name"];
    repo.name = json["name"];
    repo.htmlUrl = GithubUrl.parse(json["html_url"]);
    repo.description = json["description"];
    repo.owner = User.fromJson(json["owner"]);
    return repo;
  }
}


// Represents a Github User.
class User {
  String login;
  String avatarUrl;
  String htmlUrl;

  static User fromJson(json) {
    if(json == null) return null;
    User user = new User();
    user.login = json["login"];
    user.avatarUrl = json["avatar_url"];
    user.htmlUrl = json["html_url"];
    return user;
  }
}

// Represents a Github Issue
class Issue {
  String title;
  String body;
  User assignee;
  int milestone;
  String state;
  List<String> labels;
  // Read Only attributes
  User user;
  int number;
  int comments;
  Repo repository;
  GithubUrl htmlUrl;
  String commentsUrl;
  String url;
  DateTime createdAt;
  DateTime updatedAt;

  static Issue fromJson(json) {
    Issue issue = new Issue();
    issue.title = json["title"];
    issue.body = json["body"];
    issue.assignee = User.fromJson(json["assignee"]);
    issue.state = json["state"];
    List labelsJson = json["labels"];
    issue.labels = new List<String>();
    for(var labelsJson in labelsJson) {
      issue.labels.add(labelsJson["name"]);
    }
    issue.url = json["url"];
    issue.user = User.fromJson(json["user"]);
    issue.number = json["number"];
    issue.comments = json["comments"];
    issue.htmlUrl = GithubUrl.parse(json["html_url"]);
    issue.commentsUrl = json["comments_url"];
    issue.createdAt = DateTime.parse(json["created_at"]);
    issue.updatedAt = DateTime.parse(json["updated_at"]);
    return issue;
  }

  String toJson() {
    return """
      {
        "title": "$title",
        "body": "${body.replaceAll("\n", "\\n").replaceAll("\r", "\\r")}",
        "assignee": ${assignee == null ? null : "\"" + assignee.login + "\""},
        "state": "$state",
        "labels": ${JSON.encode(labels)}
      }
""";
  }
}

// Represents a Gothib Comment of an Issue.
class Comment {
  String body;
  // Read Only attributes
  User user;
  DateTime createdAt;
  DateTime updatedAt;
  int id;

  static Comment fromJson(json) {
    Comment comment = new Comment();
    comment.user = User.fromJson(json["user"]);
    comment.createdAt = DateTime.parse(json["created_at"]);
    comment.updatedAt = DateTime.parse(json["updated_at"]);
    comment.id = json["id"];
    comment.body = json["body"];
    return comment;
  }

  String toJson() {
    return """
      {
        "body": "${body.replaceAll("\n", "\\n").replaceAll("\r", "\\r")}"
      }
""";
  }
}
