---
title: Shareable Reproducible HPC Containers
author: Ben Evans
date: October 22, 2019
---

# Outline for Today

- Containers Background
- Docker & Singularity
- Running Singularity
- Development Workflow
  - Using Docker to build

#
## Conventions

``` bash
echo "this is one line of code split \
      for your viewing pleasure"
```

[This is a link](https://www.youtube.com/watch?v=dQw4w9WgXcQ)

#
## Containers

<section>

#
### Terms

- _**Container Image**_: A self-contained, read-only file(s) used to run application(s)

- _**Container**_: A running instance of an image

#
### Three methods of control

- Process isolation
- Resource limits
- Security

#
### Isolation

Linux [Namespaces](https://en.wikipedia.org/wiki/Linux_namespaces) for hiding various aspects of host system from container.

- Can't see other processes
- Can be used to modify networking
- Chrome uses Namespaces for [sandboxes](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux_sandboxing.md)

#
### Resource Limits

Linux [cgroups](https://en.wikipedia.org/wiki/Cgroups) to limit RAM, CPU cores, etc.

#
### Security

When user is trusted: [SELinx](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), [AppArmor](https://en.wikipedia.org/wiki/AppArmor)

When user is untrusted: run container as user

</section>

#
## Should I Use Containers?

| Pro                | Con                               |
|--------------------|-----------------------------------|
| Light-weight       | Linux-only\*                      |
| Fast Startup       | Another layer of abstraction      |
| Shareable          | Additional development complexity |
| Reproducible       | Licensed software can be tricky   |

#
## Motivating Example

GPU-enabled IPython [w/TensorFlow](https://www.tensorflow.org/install/docker) on a GPU node:

``` bash
srun --pty -p gpu_devel -c 2 --gres gpu:1 --mem 16G \
  singularity exec --nv \
  docker://tensorflow/tensorflow:latest-gpu-jupyter \
  ipython
```

#
## Better Example

Saved container for [`viral-ngs`](https://viral-ngs.readthedocs.io/en/latest/) pipeline:

``` bash
# once
singularity build viral-ngs-1.25.0.sif \
  docker://broadinstitute/viral-ngs:1.25.0
```

``` bash
# subsequently
singularity exec viral-ngs-1.25.0.sif metagenomics.py -h
```

#
## Docker

<section>

![](img/docker_logo.svg)

#

- Most popular container application
- Publicly [announced](https://www.youtube.com/watch?v=wW9CAH9nSLs) in 2013
- Designed to run services
  - Often used for web apps
- Registries:
  - [Docker Hub](https://hub.docker.com/)
  - [Red Hat Quay.io](https://quay.io/)
  - [Nvidia](https://www.nvidia.com/en-us/gpu-cloud/containers/)
  - [Google](https://cloud.google.com/container-registry/)
  - [Amazon](https://aws.amazon.com/ecr/)

#
### Design

- Service runs to orchestrate
- Images are composed of separate files: layers
- Designed to be run with elevated privileges

#

![](img/docker_layout.png)

</section>

#
## Singularity

<section>

![](img/singularity_logo.png)

#

- Released in 2016, [paper in 2017](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0177459)
- Designed to run compute jobs
- Sylabs re-write, OSS/support model
  - v2 and v3 different, not backwards-compatible
- Registries:
  - [Singularity Hub](https://singularity-hub.org/)
  - [Singularity Library](https://cloud.sylabs.io/library)

#
### Design

- No services needed to run
- Images are single files
- Designed to be run as unprivileged user

#
### Advantages

- Admins are happy
- Existing scripts, paths can work
- Data are where you left them

</section>

#
## How To Singularity

<section>

#
### [`build`](https://sylabs.io/guides/3.4/user-guide/cli/singularity_build.html) a container image

``` bash
singularity build my_container.sif \
   docker://brevans/my_container:latest
```

- Can only build from registries on cluster
- Can also copy an image file from elsewhere

#
### Run the Container

``` bash
singularity run image.sif

singularity exec docker://org/image Rscript analyze.R

singularity shell -s /bin/bash shub://user/image
```

#
### [`run`](https://sylabs.io/guides/3.4/user-guide/cli/singularity_run.html) (default behavior)

``` bash
singularity run image.sif --arg=42
```

- Default action specified by `CMD` or `%runscript`
- Additional arguments are passed to default action
- If image is +x and on path, can just be executed

#
### [`exec`](https://sylabs.io/guides/3.4/user-guide/cli/singularity_exec.html) a command

``` bash
singularity exec docker://tensorflow/tensorflow:latest-gpu \
    python /home/ben/my_script.py
```

- Run first argument after container
- Must exist/be on the `PATH` inside container

#
### [`shell`](https://sylabs.io/guides/3.4/user-guide/cli/singularity_shell.html) session

``` bash
singularity shell -s /bin/bash sl-linux.sif
```

- Use a different shell sh with `-s/--shell`

#
### [`inspect`](https://sylabs.io/guides/3.4/user-guide/cli/singularity_inspect.html) an image

``` bash
singularity inspect my_pipes.sif
singularity inspect -r my_pipes.sif
```

- Use `-r` to show runscript

</section>

#
## Singularity Runtime Config

<section>

#
### Container Links

``` text
type://[registry]/[namespace]/<repo_name>:[repo_tag]
```

- **Type**: docker, shub or library
- **Registry**: default index.docker.io
- **Namespace**: username, org, etc
- **Repo**: image name
- **Tag**: name (latest) or hash (@sha256:1a6hz...)

#
### Environment Variables

Set before running to add to container:

``` bash
# prefixing new variables with with SINGULARITYENV_
export SINGULARITYENV_BLASTDB=/data/db/blast
```

``` bash
# PATH
export SINGULARITYENV_PREPEND_PATH=/opt/important/bin
export SINGULARITYENV_APPEND_PATH=/opt/fallback/bin
export SINGULARITYENV_PATH=/only/path
```

#
### Cache Location

To change where image files are cached:

``` bash
# default is ~/.singularity
export SINGULARITY_CACHEDIR=~/scratch60/.singularity
# or
export SINGULARITY_CACHEDIR=/tmp/${USER}/.singularity
```

- Can get big fast

#
### Change Container Filesystem View

Add host directory to the container with `-B/--bind`:

``` bash
singularity run --bind /path/outside:/path/inside \
   my_container.sif
```

- container may expect files somewhere, e.g. `/data`

#
### Private DockerHub Repos

To specify DockerHub credentials:

``` bash
singularity build --docker-login pytorch-19.09.sif \
  docker://nvcr.io/nvidia/pytorch:19.09-py3
```

#
### Where did this come from?

Quick way to determine which files are from image:

``` bash
singularity run/exec/shell --containall ...
```

- Only container image files are available

#
### GPUs

Bind GPU drivers properly when CUDA installed inside container:

``` bash
singularity run/exec/shell --nv ...
```

#
### MPI

- Have recent and same version in container & host
- `mpirun` inside container needs more setup

</section>

#
## RStudio Example

<section>

I want to run RStudio and Tidyverse.

see: [rocker-project.org](https://www.rocker-project.org/)

#

Job file

``` bash
#!/bin/bash
#SBATCH -c 4 -t 2-00:00:00
mkdir -p /tmp/${USER}
export SINGULARITYENV_DISABLE_AUTH=true
singularity run -B /tmp/${USER}:/tmp \
   docker://rocker/geospatial:3.5.1
```

#

Reverse `ssh` tunnel:

``` bash
ssh -NL 8787:cxxnxx:8787 netid@grace.hpc.yale.edu
```

Then connect to http://localhost:8787

#

Not ideal...

- [According to docs](https://support.rstudio.com/hc/en-us/articles/200552316-Configuring-the-Server), we have to rebuild the container
- Change `/etc/rstudio/rserver.conf`

</section>

#
## Dev Workflow

<section>

When you have to configure your own

#
![](img/workflow_diagram.svg)

#
### *id est*

- Use docker to build everything
- Use singularity to when you can't use docker

#
### Reasoning

- Docker/Docker Hub ecosystem large, stable
- Docker re-builds can be faster
- Can auto-build git repos to docker\*
- More easily use docker on most platforms

#
### Best Practices

- Don’t install anything to root’s home, `/root`
- Don’t put container valuables in `$TMP` or `$HOME`
- Use `CMD` for default runtime behavior
- Maybe call `ldconfig` at the end of your `Dockerfile`

</section>

#
### [Dockerfiles](https://docs.docker.com/engine/reference/builder)

<section>

#
### Container recipes

- File always named `Dockerfile`
- Text file with setup scripts
- Split up into *instructions*
- Each instruction is a layer

#

A half-fix for my RStudio issue

```dockerfile
FROM rocker/geospatial:3.5.1
LABEL maintainer="b.evans@yale.edu" version=0.01

ENV RSTUDIO_PORT=30301
RUN echo "www-port=${RSTUDIO_PORT}" >> /etc/rstudio/rserver.conf
```

#
### [FROM](https://docs.docker.com/engine/reference/builder/#from) a base image

```dockerfile
FROM ubuntu:bionic
FROM ubuntu@sha256:6d0e0c26489e33f5a6f0020edface2727db9489744ecc9b4f50c7fa671f23c49
```

- Required, usually first
- Hashes are more reproducible

#
### [LABEL](https://docs.docker.com/engine/reference/builder/#label) your image

```dockerfile
LABEL maintainer="Ben Evans <b.evans@yale.edu>"
LABEL help="help message"
```

- Good to at least specify a maintainer email

#
### [ENV](https://docs.docker.com/engine/reference/builder/#env) variables

```dockerfile
ENV PATH=/opt/my_app/bin:$PATH MY_DB=/opt/my_app/db ...
```

- Available for subsequent layers, and at runtime

#
### [RUN](https://docs.docker.com/engine/reference/builder/#run) commands

```dockerfile
RUN apt-get update && \
    apt-get install openmpi-bin \
                    openmpi-common \
                    wget \
                    vim
```

- Always chain update and install together
- One package per line, alphabetical

#
### [COPY](https://docs.docker.com/engine/reference/builder/#copy) files

```dockerfile
COPY <host_src>... <container_dest>
```

- Try to download them instead

#
### [CMD](https://docs.docker.com/engine/reference/builder/#cmd)

Specify a default action.

```dockerfile
CMD ["/opt/conda/bin/ipython", "notebook"]
```

- Used for docker run and singularity run
- Also ENTRYPOINT, [they interact](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact)
</section>

#
## Docker Image Development

<section>

#
### Tips

- Put most troublesome/changing parts at the end
- Use git to version your Dockerfile
- Keep build directory clean
- Look into [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)

#
### [inspect](https://docs.docker.com/engine/reference/commandline/inspect/) an image

``` bash
docker inspect ubuntu:bionic
docker inspect --format='{{index .RepoDigests 0}}' \
  ubuntu:bionic

docker inspect -f '{{.Config.Entrypoint}} {{.Config.Cmd}}' \
  nvcr.io/nvidia/pytorch:19.09-py3
```

#
### [`build`](https://docs.docker.com/engine/reference/commandline/build/) locally

``` bash
cd /path/to/Dockerfile_dir/
docker build -t custom_ubuntu:testing .
```

- Notice the period at the end for current directory
- Use -t to tag your builds

#
### [`image ls`](https://docs.docker.com/engine/reference/commandline/image_ls/)

``` bash
docker image ls
```

``` text
REPOSITORY      TAG     IMAGE ID      CREATED       SIZE
rocker/rstudio  latest  879f3fd2bee9  39 hours ago  1.12GB
ubuntu          bionic  93fd78260bd1  13 days ago   86.2MB
```

- Delete images with `image rm`(https://docs.docker.com/engine/reference/commandline/image_rm/)

#
### [`run`](https://docs.docker.com/engine/reference/run/) locally

``` bash
docker run --rm custom_ubuntu:dev
docker run --rm -ti custom_ubuntu:testing /bin/bash
```

- Use `--rm` to clean up container after it exits
- Use `--volume` to bind directories to container
- Use `-e` to set environment variables
  - `-e USERID=$UID` can avoid permission woes

#
### [`push`](https://docs.docker.com/docker-cloud/builds/push-images/) to cloud

``` bash
export DOCKER_USERNAME="username"
docker login
docker tag custom_ubuntu:testing ${DOCKER_USERNAME}/my_image:v0.1
docker push ${DOCKER_USERNAME}/my_image
```

#
### [`prune`](https://docs.docker.com/engine/reference/commandline/system_prune/) uneeded things

Clean up every now and again.

``` bash
docker system prune
```

``` text
WARNING! This will remove:
        - all stopped containers
        - all networks not used by at least one container
        - all dangling images
        - all dangling build cache
Are you sure you want to continue? [y/N]
```

</section>

#
## Links

<section>

[Docker Documentation](https://docs.docker.com/)

Install Docker on [MacOS](https://docs.docker.com/docker-for-mac/), [Windows](https://docs.docker.com/docker-for-windows/), and [Linux](https://docs.docker.com/install/linux/ubuntu/)

[Ubuntu](https://hub.docker.com/_/ubuntu/) and [CentOS](https://hub.docker.com/_/centos/) [Docker Hub](https://hub.docker.com/) pages

[`Dockerfile` reference](https://docs.docker.com/engine/reference/builder) & [best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices)

[`docker` CLI reference](https://docs.docker.com/engine/reference/commandline/docker/)

#

[Singularity docs](https://www.sylabs.io/docs/)

[Install Singularity](https://sylabs.io/guides/3.4/user-guide/installation.html)

[Container definition reference](https://sylabs.io/guides/3.4/user-guide/definition_files.html)

[YCRC abridged Singularity docs](https://research.computing.yale.edu/support/hpc/user-guide/singularity-yale)

</section>