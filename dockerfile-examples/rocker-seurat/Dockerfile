# I want to containerize Seurat
# https://satijalab.org/seurat/

# start from a specific set of layers; they will never change unless deleted
FROM rocker/geospatial@sha256:ea4456bf8f8b051dc8e2c6a178158d0c16fb57e96f685d38aa9bb9fc0c8f5c1d
# R v3.6.1

# tell everyone who I am
LABEL maintainer="Ben Evans <b.evans@yale.edu>"

# install python
RUN apt-get update && \
    apt-get -y install python-pip \
                       python-virtualenv && \
    rm -rf /var/lib/apt/lists/*

# install some R libraries
RUN R -e 'install.packages(c("WGCNA", "igraph", "reticulate"))' && \
    R -e "library('reticulate'); reticulate::py_install(packages = 'umap-learn')"

# compile and install a Seurat dependency
RUN cd /tmp && \
    wget --quiet https://github.com/KlugerLab/FIt-SNE/archive/v1.1.0.tar.gz -O FIt-SNE.tar.gz && \
    tar xf FIt-SNE.tar.gz && \
    cd FIt-SNE-1.1.0 && \
    g++ -std=c++11 -O3  src/sptree.cpp src/tsne.cpp src/nbodyfft.cpp  -o bin/fast_tsne -pthread -lfftw3 -lm && \
    cp bin/fast_tsne /usr/local/bin/

# install Seurat
RUN R -e 'install.packages("Seurat")'

CMD ["/usr/local/bin/R"]