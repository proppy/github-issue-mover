import 'dart:html';
import 'github.dart';
import 'package:cookie/cookie.dart' as cookie;
import 'package:intl/intl.dart';

User currentGithubUser;
Issue issueToMove;
Repo destinationRepo;
String accessToken;
GithubApiAccessor github;

// Displays the details of the given Issue in the "IssueOverview" div.
displayIssueDetails(Issue issue) {
  querySelector("#issueOverview #issueTitle").text = "${issue.title} #${issue.number}";
  querySelector("#issueOverview #issueTitle").href = issue.htmlUrl.fullUrl;
  querySelector("#issueOverview #issueUserName").text = issue.user.login;
  querySelector("#issueOverview #issueUserName").href = issue.user.htmlUrl;
  querySelector("#issueOverview #issueUserAvatar").src = issue.user.avatarUrl;
  querySelector("#issueOverview #issueBody").text = issue.body != "" ? issue.body :
      "No description provided.";
  querySelector("#issueOverview #issueComments").text = "${issue.comments} Comment(s)";
  querySelector("#issueError").style.display = "none";
  querySelector("#issueOverview").style.display = "block";
}

// Displays the details of the given Issue in the "IssueOverview" div.
displayRepoDetails(Repo repo) {
querySelector("#repoOverview #repoName").text = repo.fullName;
querySelector("#repoOverview #repoName").href = repo.htmlUrl.fullUrl;
querySelector("#repoOverview #repoDescription").text = repo.description != "" ? repo.description :
   "No description provided.";
querySelector("#repoError").style.display = "none";
querySelector("#repoOverview").style.display = "block";
}

displayIssueError(String errorMessage) {
  querySelector("#issueError").style.display = "block";
  querySelector("#issueError").text = errorMessage;
  querySelector("#issueOverview").style.display = "none";
}

displayRepoError(String errorMessage) {
  querySelector("#repoError").style.display = "block";
  querySelector("#repoError").text = errorMessage;
  querySelector("#repoOverview").style.display = "none";
}

// Hide the "Authorize" button block and show the move issues tooling block.
displayMoveIssueTooling() {
  querySelector("#authorize").style.display = "none";
  querySelector("#authorized").style.display = "block";
  querySelector("#issue").focus();
}

// Enables or Disables the "Move" button depending on wether or not we have an issue to move and a destination repo.
enableDisableMoveButton() {
  if (destinationRepo == null
      || issueToMove == null) {
    querySelector("#move").attributes["disabled"] = "disabled";
    if (destinationRepo != null) {
      displayRepoDetails(destinationRepo);
    }
  } else if (destinationRepo.htmlUrl.ownerName == issueToMove.htmlUrl.ownerName
      && destinationRepo.htmlUrl.repoName == issueToMove.htmlUrl.repoName) {
    displayRepoError("You can't move an issue to its current repo.");
    querySelector("#move").attributes["disabled"] = "disabled";
  } else {
    querySelector("#move").attributes.remove("disabled");
    if (destinationRepo != null) {
      displayRepoDetails(destinationRepo);
    }
  }
}

// Fetches and displays information about the currently Authorized user.
displayAuthorizedUser() {
  // Request the currently signed in Github user.
  github.getAuthorizedUser().then((User user) {
    currentGithubUser = user;
    querySelector("#login").text = user.login;
    querySelector("#login").href = user.htmlUrl;
    (querySelector("#photo") as ImageElement).src = user.avatarUrl;
    querySelector("#user").style.display = "block";
  }).catchError((error) {
    querySelector("#user").style.display = "none";
  });
}

copyIssue() {
  querySelector("#move").attributes["disabled"] = "disabled";
  querySelector("#repo").attributes["disabled"] = "disabled";
  querySelector("#issue").attributes["disabled"] = "disabled";
  querySelector("#oldIssueLink").href = issueToMove.htmlUrl.fullUrl;
  querySelector("#oldIssueLink").text = issueToMove.htmlUrl.simplifiedUrl;
  querySelector("#moveResultContainer").style.display = "block";
  Issue copy = getIssueCopy(issueToMove, destinationRepo);
  github.createIssue(copy).then((Issue issue) {
    querySelector("#copyIssueCheck").style.visibility = "visible";
    querySelector("#newIssueLink").href = issue.htmlUrl.fullUrl;
    querySelector("#newIssueLink").text = issue.htmlUrl.simplifiedUrl;
    github.getComments(issueToMove).then((List<Comment> comments) {
        querySelector("#numComments").text = "0/${comments.length}";
        comments.forEach((Comment comment) {
            if (comment.user.login != currentGithubUser.login) {
              comment.body = "_From @${comment.user.login} on ${new DateFormat('MMMM d, y H:m').format(comment.createdAt)}_\n\n${comment.body}";
            }
        });
        github.addCommentsToIssue(comments, issue, (int num, int total){querySelector("#numComments").text = "$num/$total";}).then((_) {
            querySelector("#copyCommentsCheck").style.visibility = "visible";
            List<Comment> reference = new List<Comment>();
            Comment comment = new Comment();
            comment.body = "This issue was moved to ${issue.htmlUrl.simplifiedUrl}";
            reference.add(comment);
            github.addCommentsToIssue(reference, issueToMove).then((_) {
                querySelector("#referenceCommentCheck").style.visibility = "visible";
                issueToMove.state = "closed";
                github.updateIssue(issueToMove).then((_) {
                    querySelector("#closeIssueCheck").style.visibility = "visible";
                    querySelector("#close").attributes.remove("disabled");
                    querySelector("#close").focus();
                });
            });
        });
    });
  });
}

Issue getIssueCopy(Issue issue, Repo repo) {
  Issue copiedIssue = new Issue();
  copiedIssue.title = issueToMove.title;
  copiedIssue.body = "_From @${issue.user.login} on ${new DateFormat('MMMM d, y H:m').format(issue.createdAt)}_\n\n${issue.body}\n\n_Copied from original issue: ${issue.htmlUrl.simplifiedUrl}_";
  copiedIssue.labels = issue.labels;
  copiedIssue.assignee = issue.assignee;
  copiedIssue.state = issue.state;
  copiedIssue.htmlUrl = repo.htmlUrl;
  return copiedIssue;
}

closeMoveResultContainer() {
  querySelector("#moveResultContainer").style.display = "none";
  querySelectorAll("#moveResultContainer #content .check").forEach(
      (element) => element.style.visibility = "hidden");
  querySelectorAll("#moveResultContainer #content .loading").forEach(
      (element) => element.style.visibility = "hidden");
  querySelector("#moveResultContainer #content #newIssueLink").href = "";
  querySelector("#moveResultContainer #content #oldIssueLink").href = "";
  querySelector("#moveResultContainer #content #newIssueLink").text = "";
  querySelector("#moveResultContainer #content #oldIssueLink").text = "";
  querySelector("#numComments").text = "";
  querySelector("#close").attributes["disabled"] = "disabled";
  querySelector("#move").attributes.remove("disabled");
  querySelector("#repo").attributes.remove("disabled");
  querySelector("#issue").attributes.remove("disabled");
}

void main() {
  // Reading the OAuth 2.0 accessToken from the Cookies
  accessToken = cookie.get('access_token') == "" ? null : cookie.get('access_token');
  // Instanciate the Github Accessor if we have an AccessToken
  github = accessToken == null ? null : new GithubApiAccessor(accessToken);

  if (github != null) { // If the user authorized already.
    // If token expired or revoked we automatically logout.
    github.addGlobalErrorCallback((error) {
      if (error.target.status == 403) {
        window.location.href =
            "/logout?error_message=Error:+token+must+have+been+revoked.+Please+re-authorize";
      }
    });
    displayAuthorizedUser();
    displayMoveIssueTooling();
  }


  // Event bindings

  // Authorize Github button redirects to the Auth URL.
  querySelector("#auth_button").onClick.listen((Event) => window.location.href = "/oauth_redirect");

  // The Issue input automatically simplifies the URL and loads the issue's details if possible.
  querySelector("#issue").onChange.listen((Event e) {
    issueToMove = null;
    enableDisableMoveButton();
    GithubUrl issueUrl;
    try {
      issueUrl = GithubUrl.parse(e.target.value);
    } catch (exception) {
      if (e.target.value.isEmpty) {
        displayIssueError("");
      } else {
        displayIssueError("Not a valid Github URL");
      }
      return;
    }
    e.target.value = issueUrl.simplifiedUrl;
    if (issueUrl.ownerName != null && issueUrl.repoName != null && issueUrl.issueNumber != null) {
      querySelector("#issue").attributes["disabled"] = "disabled";
      github.getIssue(issueUrl.ownerName, issueUrl.repoName, issueUrl.issueNumber).then((Issue issue) {
        issueToMove = issue;
        enableDisableMoveButton();
        displayIssueDetails(issue);
        querySelector("#issue").attributes.remove("disabled");
      }).catchError((error) {
        displayIssueError("The issue or repo does not exist.");
        querySelector("#issue").attributes.remove("disabled");
      });
      if (querySelector("#repo").value.isEmpty) {
        querySelector("#repo").value = "${issueUrl.ownerName}/";
      }
      querySelector("#repo").focus();
    } else {
      displayIssueError("Not a valid Github Issue URL");
    }
  });

  // The Repo input automatically simplifies the URL if possible and loads the Repo's details.
  querySelector("#repo").onChange.listen((Event e) {
    destinationRepo = null;
    enableDisableMoveButton();
    GithubUrl repoUrl;
    try {
      repoUrl = GithubUrl.parse(e.target.value);
    } catch (exception) {
      if (e.target.value.isEmpty) {
        displayRepoError("");
      } else {
        displayRepoError("Not a valid Github URL");
      }
      return;
    }
    e.target.value = "${repoUrl.ownerName}/${repoUrl.repoName}";

    if (repoUrl.ownerName != null && repoUrl.repoName != null) {
      querySelector("#repo").attributes["disabled"] = "disabled";
      github.getRepo(repoUrl.ownerName, repoUrl.repoName).then((Repo repo) {
        destinationRepo = repo;
        querySelector("#repo").attributes.remove("disabled");
        displayRepoDetails(repo);
        enableDisableMoveButton();
        querySelector("#move").focus();
      }).catchError((error) {
        displayRepoError("The repo does not exist.");
        querySelector("#repo").attributes.remove("disabled");
      });
      querySelector("#repo").focus();
    } else {
      displayRepoError("Not a valid Github Repo URL");
    }
  });

  querySelector("#move").onClick.listen((Event e) => copyIssue());

  querySelector("#close").onClick.listen((Event e) => closeMoveResultContainer());
}
