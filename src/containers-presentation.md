---
title: HPC Containers with Singularity
author: Ben Evans
date: December 4, 2018
---

# Outline for Today
- Containers Background
- Docker & Singularity
- Running Singularity
- Development Workflow
    - Using Docker to build

# Conventions
```bash
echo "this is one line of code split for \
your viewing pleasure"
```
[This is a link](https://www.youtube.com/watch?v=dQw4w9WgXcQ)

# Containers

<section>
# 
### Definitions

- _**Container Image**_: A self-contained, read-only file(s) used to run application(s)

- _**Container**_: A running instance of an image

# 
### Three methods of control

- Process isolation 
- Resource Limits
- Security

#
### Isolation

Linux [Namespaces](https://en.wikipedia.org/wiki/Linux_namespaces) for hiding various aspects of host system from container.

- Can't see other processes
- Can be used to modify networking
- Chrome uses Namespaces for [sandboxes](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux_sandboxing.md)

#
### Resource Limits

Linux [cgroups](https://en.wikipedia.org/wiki/Cgroups) to limit RAM, CPU cores, etc etc.

#
### Security

When user is trusted: [SELinx](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), [AppArmor](https://en.wikipedia.org/wiki/AppArmor)

When user is untrusted: run container as user
</section>

# Should I Use Containers?
| Pro                | Con                               |
|--------------------|-----------------------------------|
| Light-weight       | Often Linux-only                  |
| Fast Startup       | Another layer of abstraction      |
| Shareable          | Additional development complexity |
| Reproducible       | Licensed software can be tricky   |

# Example

GPU-enabled IPython w/TensorFlow on a GPU node:

```bash
srun --pty -p gpu -c 2 --gres gpu:1 --mem 24G \
  singularity exec --nv \
    docker://tensorflow/tensorflow:latest-gpu ipython
```

# Docker
<section>
![](img/docker_logo.svg)

# 
- Most popular container application
- Publicly [announced](https://www.youtube.com/watch?v=wW9CAH9nSLs) in 2013
- Designed to run services
    - Often used for web apps
- Primary registry hub.docker.com

# 
### Design
- Service runs to orchestrate
- Images are composed of separate files: layers
- Designed to be run with elevated privileges

#  
![](img/docker_layout.png)
</section>

# Singularity

<section>
![](img/singularity_logo.png)

# 
- Released in 2016, [paper in 2017](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0177459)
- Designed to run compute jobs
- Sylabs re-written, OSS/support model
    - v2.6 and v3 different, not backwards-compatible
- Registries: 
    - singularity-hub.org
    - cloud.sylabs.io/library

# 
### Design
- No services needed to run
- Images are single files
- Designed to be run as unprivileged user

#
### Advantages
- Admins are happy
- Existing scripts, paths should work
- No shuffling data around

</section>

# How To Singularity
<section>
#
### [`build`](https://www.sylabs.io/guides/2.6/user-guide/appendix.html#build-command)
Build a singularity image (on the clusters)
```bash
singularity build my_container.simg \
   docker://brevans/my_container:latest
```
- Can only build from docker/shub on cluster
- Can also copy an image file from elsewhere

# 
### Run the Container
```bash
singularity run image.simg

singularity exec docker://org/image Rscript analyze.R

singularity shell -s /bin/bash shub://user/image
```
# 
### [`run`](https://www.sylabs.io/guides/2.6/user-guide/quick_start.html#running-a-container)
Execute the default behavior
```bash
singularity run image.simg --arg=42
```
- Default action specified by ENTRYPOINT
- Additional arguments are passed to default action
- If image is +x and on path, can just be executed

# 
### [`exec`](https://www.sylabs.io/guides/2.6/user-guide/appendix.html#exec-command)
Run a command inside the container
```bash
singularity exec docker://tensorflow/tensorflow:latest-gpu \
    python /home/be59/my_script.py
```
- Run first argument after container
- Must exist/be on the `PATH` inside container

# 
### [`shell`](https://www.sylabs.io/guides/2.6/user-guide/quick_start.html#shell)
Run an interactive shell inside the container
```
singularity shell -s /bin/bash sl-linux.simg
```
- Use a different shell sh with `-s/--shell`
</section>

# Runtime Config
<section>

# 
### Docker Links

```
docker://[registry]/[namespace]/<repo_name>:[repo_tag]
```
- Registry: default [index.docker.io]
- Namespace: username, org, or the default [library]
- Repo: image name
- Tag: name (e.g. latest) or hash (e.g. @sha256:1234...)

# 
### Environment Variables
Set environment variables before running singularity:
```bash
# prefixing new variables with with SINGULARITYENV_
export SINGULARITYENV_BLASTDB=/data/db/blast
```
To modify `PATH`:
```bash
export SINGULARITYENV_PREPEND_PATH=/opt/important/bin
export SINGULARITYENV_APPEND_PATH=/opt/fallback/bin
export SINGULARITYENV_PATH=/only/path
```

# 
### Cache Location
To change where image files are cached:
```bash
# default is ~/.singularity
export SINGULARITY_CACHEDIR=~/scratch60/.singularity
# or
export SINGULARITY_CACHEDIR=/tmp/${USER}/.singularity
```
( .singularity can get big fast )

# 
### Move Directories Around
Add host directory to the container with `-B/--bind`:
```bash
singularity run --bind /path/outside:/path/inside \
   my_container.simg
```
A Container may expect files somewhere, e.g. `/data`

# 
### Private DockerHub Repos
To specify Docker Hub credentials:
```bash
set +o history
export SINGULARITY_DOCKER_USERNAME=brevans
export SINGULARITY_DOCKER_PASSWORD=password123
set -o history
```
!! Be wary of storing credentials in your shell history !!

# 
### Where did this come from?
Quick way to determine which files are from image:
```
singularity run/exec/shell --containall ...
```
Only container image files are available.

# 
### GPUs
Bind GPU drivers properly when CUDA installed inside container:
```
singularity run/exec/shell --nv ...
```

#
### MPI

Having recent and same version in container and on host is usually sufficient

Please reach out if you are trying something interesting!
</section>

# RStudio Example
<section>
I want to run the newest RStudio and tidyverse.

see: [rocker-project.org](https://www.rocker-project.org/)

# 
job file:
```bash
#!/bin/bash
#SBATCH -c 4 -t 2-00:00:00
mkdir -p /tmp/${USER}
export SINGULARITYENV_DISABLE_AUTH=true
singularity run -B /tmp/${USER}:/tmp \
   docker://rocker/geospatial:3.5.1
```

# 
Reverse `ssh` tunnel:
```bash
ssh -NL 8787:cxxnxx:8787 grace.hpc.yale.edu
```
Then connect to http://localhost:8787

# 
Not ideal...

- [According to docs](https://support.rstudio.com/hc/en-us/articles/200552316-Configuring-the-Server), we have to rebuild the container
- Change `/etc/rstudio/rserver.conf`
</section>

# Dev Workflow
<section>
When you have to configure your own

# 
![](img/workflow_diagram.svg)

# 
### Reasoning

- Docker/Docker Hub ecosystem large, stable
- Docker re-builds can be faster
- Docker Hub can auto-build github repos
- More easily use docker on other platforms

# 
### Best Practices

- Don’t install anything to root’s home, `/root`
- Don’t put container valuables in `$TMP` or `$HOME`
- Use `ENTRYPOINT` to for default runtime behavior
- Update shared library cache by calling `ldconfig` at the end of your `Dockerfile`
</section>

# [Dockerfiles](https://docs.docker.com/engine/reference/builder)
<section>
A half-fix for my RStudio issue

```dockerfile
FROM rocker/geospatial:3.5.1
LABEL maintainer="b.evans@yale.edu" version=0.01

ENV RSTUDIO_PORT=30301
RUN echo "www-port=${RSTUDIO_PORT}" >> /etc/rstudio/rserver.conf
```
# 
- Recipes for container images
- File always named `Dockerfile`

# 
## [FROM](https://docs.docker.com/engine/reference/builder/#from)
Sets base image

```dockerfile
FROM ubuntu:bionic
FROM ubuntu@sha256:6d0e0c26489e33f5a6f0020edface2727db9489744ecc9b4f50c7fa671f23c49
```
- Required, usually first
- Hashes are more reproducible.

# 
## [LABEL](https://docs.docker.com/engine/reference/builder/#label)
Annotate your container image with metadata.
```dockerfile
LABEL maintainer="ben evans <b.evans@yale.edu>"
LABEL help="help message"
```
- Good to at least specify a maintainer email.

# 
## [ENV](https://docs.docker.com/engine/reference/builder/#env)
Set environment variables. 
```dockerfile
ENV PATH=/opt/my_app/bin:$PATH MY_DB=/opt/my_app/db ...
```

- Available for subsequent layers, and at runtime.

# 
## [RUN](https://docs.docker.com/engine/reference/builder/#run)
Run commands to build your image.
```dockerfile
RUN apt-get update && \
    apt-get install openmpi-bin \
                    openmpi-common \
                    wget \
                    vim 
```

- Each `RUN` instruction is a separate layer.
- Suggested style: one package per line, alphabetical

# 
## [COPY](https://docs.docker.com/engine/reference/builder/#copy)
Copy files from your computer to the image.
```dockerfile
COPY <host_src>... <container_dest>
```

- I usually try to download them instead

# 
## [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#entrypoint)
Specify a default action.
```dockerfile
ENTRYPOINT ["/opt/conda/bin/ipython", "notebook"]
```

- Used for docker run and singularity run.
</section>

# Docker Dev
<section>
# 
### Tips
- Put most troublesome RUNs at the end
- Use git to version your Dockerfile
- **Only** use ENTRYPOINT (not CMD) if you plan to use Singularity
- Use [docker inspect](https://docs.docker.com/engine/reference/commandline/inspect/) to get container image info
```
docker inspect ubuntu:bionic
docker inspect --format='{{index .RepoDigests 0}}' ubuntu:bionic
```

# 
### [`build`](https://docs.docker.com/engine/reference/commandline/build/)
Build locally
```bash
cd /path/to/Dockerfile_dir/
docker build -t custom_ubuntu:testing .
```
- use -t to tag your builds

#
### [Image List](https://docs.docker.com/engine/reference/commandline/image_ls/)
List container images on your computer
```bash
docker image ls
REPOSITORY      TAG     IMAGE ID      CREATED       SIZE
rocker/rstudio  latest  879f3fd2bee9  39 hours ago  1.12GB
ubuntu          bionic  93fd78260bd1  13 days ago   86.2MB
```

# 
### [`run`](https://docs.docker.com/engine/reference/run/)
Run Docker locally
```bash
docker run --rm /bin/bash custom_ubuntu:testing
docker run --rm -ti --entrypoint /bin/bash custom_ubuntu:testing 
```
- Use `--rm` to clean up container after it exits
- Docker containers run like `--containall` by default
    - Use `--volume` to bind directories to container

# 
### [`push`](https://docs.docker.com/docker-cloud/builds/push-images/)
Send your container to Docker Hub for use elsewhere
```bash
export DOCKER_USERNAME="username"
docker login
docker tag custom_ubuntu:testing ${DOCKER_USERNAME}/my_image:v0.1
docker push ${DOCKER_USERNAME}/my_image
```

# 
### [`prune`](https://docs.docker.com/engine/reference/commandline/system_prune/)
Clean up every now and again.
```bash
docker system prune
WARNING! This will remove:
        - all stopped containers
        - all networks not used by at least one container
        - all dangling images
        - all dangling build cache
Are you sure you want to continue? [y/N]
```
</section>

# Links
<section>
[Docker Documentation](https://docs.docker.com/)

Install Docker on [MacOS](https://docs.docker.com/docker-for-mac/), [Windows](https://docs.docker.com/docker-for-windows/), and [Linux](https://docs.docker.com/install/linux/ubuntu/)

[Ubuntu](https://hub.docker.com/_/ubuntu/) and [CentOS](https://hub.docker.com/_/centos/) [Docker Hub](https://hub.docker.com/) pages

[`Dockerfile` reference](https://docs.docker.com/engine/reference/builder)

[`docker` CLI reference](https://docs.docker.com/engine/reference/commandline/docker/)

# 
[Singularity Documentation](https://www.sylabs.io/docs/)

Install Singularity [v3](https://www.sylabs.io/guides/3.0/user-guide/quick_start.html#quick-installation-steps) and [v2](https://www.sylabs.io/guides/2.6/user-guide/installation.html)

Container [recipe reference](https://www.sylabs.io/guides/2.6/user-guide/container_recipes.html#container-recipes)

YCRC [abridged Singularity docs](https://research.computing.yale.edu/support/hpc/user-guide/singularity-yale)
</section>