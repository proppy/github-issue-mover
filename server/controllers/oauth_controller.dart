part of github_issue_mover;

@Controller
class OauthController {

  static const String exchangeCodePath = "/exchange_code";

  @RequestMapping(value: "/oauth_code_exchange/{authCode}")
  HttpResponse authCodeExchange(ForceRequest req, Model model, String authCode)
      {
    HttpResponse response = req.request.response;
    OauthGithubHelper.exchangeCodeForToken(authCode, getRedirectUrl(req.request.uri)).then((accessToken) {
      response.write(accessToken);
      response.close();
    }).catchError((String error) {
      response.statusCode = 400;
      response.write(error);
      response.close();
    });
    return response;
  }

  @RequestMapping(value: "/oauth_redirect")
  HttpResponse authRedirect(ForceRequest req, Model model) {
    HttpResponse response = req.request.response;
    response.redirect(OauthGithubHelper.getAuthorizationUrl(getRedirectUrl(req.request.requestedUri)));
    return response;
  }

  static String getRedirectUrl(Uri requestUri) {
    return (requestUri.scheme != null && requestUri.scheme != "" ? requestUri.scheme : "http") + "://"
        + (requestUri.host != "" ? requestUri.host : "localhost")
        + (requestUri.port != null ? ":" + requestUri.port.toString() : "")
        + exchangeCodePath;
  }

  @RequestMapping(value: "/")
  String showPage(ForceRequest req, Model model) {
    model.addAttribute("error", req.request.session["error"]);
    req.request.session["error"] = null;

    String accessToken = req.request.session["access_token"];
    Cookie accessTokenCookie = new Cookie("access_token", accessToken != null ? accessToken : "")
        ..httpOnly = false;
        //..secure = true;
    req.request.response.cookies.add(accessTokenCookie);
    return "index";
  }

  @RequestMapping(value: "/logout")
  String logout(ForceRequest req, Model model, @RequestParam() String error_message) {
    req.request.session["error"] = error_message;
    req.request.session["access_token"] = null;

    return "redirect:/";
  }


  @RequestMapping(value: exchangeCodePath)
  dynamic root(ForceRequest req, Model model, @RequestParam() String
      code, @RequestParam() String error) {
    if (error != null && error == "") {
      req.request.session["access_token"] = null;
      req.request.session["error"] = error;
      return "redirect:/";
    } else {
      OauthGithubHelper.exchangeCodeForToken(code, getRedirectUrl(req.request.requestedUri)).then((accessToken) {
        req.request.session["access_token"] = accessToken;
        req.request.session["error"] = null;
        req.async("redirect:/");
      }).catchError((String error) {
        req.request.session["access_token"] = null;
        req.request.session["error"] = error;
        req.async("redirect:/");
      });
      return req.asyncFuture;
    }
  }
}
