library github_issue_mover;

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:forcemvc/force_mvc.dart';
import 'package:github_oauth/githuboauth.dart';

part '../controllers/oauth_controller.dart';

void main() {
  // Setup what port to listen to
  var portEnv = Platform.environment['PORT'];
  var port = portEnv == null ? 8080 : int.parse(portEnv);
  var serveClient = portEnv == null ? true : false;

  // Create a force server
  WebServer server = new WebServer(host: "0.0.0.0",
                                   port: port,
                                   staticFiles: '../../client/static/',
                                   clientFiles: '../../client/build/web/', // use this on prod
                                   //clientFiles: '../client/web/', // use this for dev
                                   clientServe: serveClient,
                                   views: "../views/");
  // register yaml files
  server.loadValues("../app.yaml");

  // Set up logger.
  server.setupConsoleLog(Level.FINEST);

  // Start serving force
  server.start();
}

