# SSH

This readme is for the encircle ssh-\* images.

The image essentially takes a build argument of $BOOTSTRAP, which is used as the base image.

SSH configuration is then layered over the base image, so any image can be bootstrapped with SSH access.

This is handy for images like Drupal 9, where you want an SSH container with all the same tooling and packages as the Drupal container that hosts the code.

## Hooks

The hooks folder is for dockerhub, it allows us to use build arguments from Dockerhub environment variables.

In this case, we are using the hooks to pass the $BOOTSTRAP variable to the image.

## Environment Variables

There are no environment variables that can be passed at runtime.
