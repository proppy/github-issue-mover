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

FROM google/appengine-dart
MAINTAINER Nicolas Garnier <nivco@google.com>

ADD app.yaml       /container/app.yaml
ADD server          /container/server
ADD github_oauth          /container/github_oauth
ADD client          /container/client

# Build the app.
WORKDIR /container/client
RUN pub build
WORKDIR /container/server
RUN pub get

# Expose port 8080. You should change it to the port(s) your app is serving on.
EXPOSE 8080

# Entrypoint. Whenever the container is started the following command is executed in your container.
# In most cases it simply starts your app.
WORKDIR /container/server
ENTRYPOINT ["dart"]

# Change this to your starting dart.
CMD ["/container/server/server.dart"]