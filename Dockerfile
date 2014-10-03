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

ADD app.yaml       /app/app.yaml
ADD server          /app/server
ADD github_oauth          /app/github_oauth
ADD client          /app/client

# Build the app.
WORKDIR /app/client
RUN pub build
WORKDIR /app/server
RUN pub get

# Expose port 8080. You should change it to the port(s) your app is serving on.
EXPOSE 8080

# Entrypoint. Whenever the container is started the following command is executed in your container.
# In most cases it simply starts your app.
WORKDIR /app/server

CMD []
ENTRYPOINT ["/usr/bin/dart", "/app/server/server.dart"]