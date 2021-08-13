# Hooks

Hooks are specific to Dockerhub automated builds. See the following link:

https://docs.docker.com/docker-hub/builds/advanced/

The 'build' hook is used to override the docker build command that Dockerhub uses during an automated build.

In this case, the argument 'BOOTSTRAP' is passed as a build arg to the image.

The 'BOOTSTRAP' variable indicates the image onto which SSH access is to be bootstrapped.

The build arg values are specified in Dockerhub as 'environment variables' in the build settings.
