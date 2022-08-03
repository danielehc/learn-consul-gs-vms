# Base Image for labs in Docker/Instruqt

## Image content

* Based on Debian
* Uses `tini` as init process     
* Uses dropbear as SSH server
* HashiCorp repository already configured


### SSH keys

The image has an SSH cert-key pair that enables password-less ssh connections
across all containers based on the same image. 

When building the images for your own lab create your own SSH keys with:

```shell
cd ./ssh
```

```shell
ssh-keygen -t rsa -b 4096
```

## Build

The folder contains a `Makefile` to simplify build. Allowed commands are:

* `make build` - Builds the image and tags it with current date (`YYYY-MM-DD` format).
* `make build_and_push` - Builds the image and tags it with current date (`YYYY-MM-DD` format), after that it pushes it to the Docker registry.
* `make latest` - Builds the image and tags it with `latest` tag, after that it pushes it to the Docker registry.

### Define image name

The `Makefile` uses a variable to define the Docker image name, `DOCKER_REPOSITORY`.
By setting this variable you can define the image name for your build.


Example:

```
DOCKER_REPOSITORY=test/image make build
```

## Use

```
docker run --name instruqt-base -d danielehc/instruqt-base:latest
```




