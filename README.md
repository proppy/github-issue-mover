#Github Issue Mover

You know what's hard? Moving issues between repos in Github. 
Well, in fact, it's impossible so this tool will help you:
 - Create a copy of the issue in the destination repo
 - Close the original issue
 - Add references between the issues

##Usage

The tool is hosted online at http://www.githubissuemover.com

It looks like this:

<img width="600px" src="https://raw.githubusercontent.com/nicolasgarnier/github-issue-mover/master/README_assets/app.png">


##How to use

You can copy paste full Github URLs. For instance you can copy paste

`https://github.com/nicolasgarnier/github-issue-mover/issues/4`

into the "Issue to Move" text field. It will get automatically transformed to the _short_ Github URL:

`nicolasgarnier/github-issue-mover#4`

The tool will extract some information about the issue if it's accessible to your user:

<img width="300px" src="https://raw.githubusercontent.com/nicolasgarnier/github-issue-mover/master/README_assets/issue.png">

You can do the same for the "Destination Repo" text field and copy paste:

`https://github.com/nicolasgarnier/drive-music-player`

It will get automatically transformed to the _short_ Github URL for repos:

`nicolasgarnier/drive-music-player`

and some information will get extracted as well:

<img width="300px" src="https://raw.githubusercontent.com/nicolasgarnier/github-issue-mover/master/README_assets/repo.png">

Once existing issue and repo have been set you can start the move process:

<img width="300px" src="https://raw.githubusercontent.com/nicolasgarnier/github-issue-mover/master/README_assets/move.png">

This will create a new issue which is a copy of the original one, with mentions of every users who commented on the bug. The two issues will also references themselves:

<img width="600px" src="https://raw.githubusercontent.com/nicolasgarnier/github-issue-mover/master/README_assets/result.png">

##Installing your own instance

This app runs in a Docker container and has an [automated Build repo](https://registry.hub.docker.com/u/nicolasgarnier/github-issue-mover) on Docker hub. It can easilly be deployed Google Compute Engine with this command:

`gcloud compute instances create docker-1 --image container-vm-v20140929 --metadata-from-file google-container-manifest=<path to>/containers.yaml --image-project google-containers --zone us-central1-a --tags http-server --machine-type n1-standard-4`

The command above will create a new [Google Compute Engine](https://cloud.google.com/compute/) Instance with Dart and the Github Issue Mover app deployed and running.

### App Engine

It can also be deployed on [App Engine Managed VM](https://cloud.google.com/appengine/docs/managed-vms/)

`gcloud preview app deploy <path to>/app.yaml --server=preview.appengine.google.com`
