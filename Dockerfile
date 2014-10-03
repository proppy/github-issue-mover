# Install a dart container for the Github Issue Mover project.
# Your dart server app will be accessible via HTTP on container port 8080. The port can be changed.
# You should adapt this Dockerfile to your needs.
# If you are new to Dockerfiles please read 
# http://docs.docker.io/en/latest/reference/builder/
# to learn more about Dockerfiles.
#
# This file is hosted on github. Therefore you can start it in docker like this:
# > docker build -t githubissuemover github.com/nicolasgarnier/github-issue-mover
# > docker run -p 80:8080 -d githubissuemover

FROM google/dart
MAINTAINER Nicolas Garnier <nivco@google.com>

ADD /github_oauth /app/github_oauth

ADD server/pubspec.yaml /app/server/pubspec.yaml
RUN cd /app/server && pub get

ADD client/pubspec.yaml /app/client/pubspec.yaml
RUN cd /app/client && pub get

ADD client          /app/client
RUN cd /app/client && pub get # fix host symlinks if any
RUN cd /app/client && pub build
ADD server          /app/server
RUN cd /app/server && pub get # fix host symlinks if any
ADD dart_app.yaml       /app/dart_app.yaml

EXPOSE 8080

CMD []
ENTRYPOINT ["/usr/bin/dart", "/app/server/server.dart"]
