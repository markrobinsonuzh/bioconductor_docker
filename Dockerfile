# can be built with:
# docker build -t bioconductor_docker:4.0.0 https://github.com/markrobinsonuzh/bioconductor_docker

# The suggested name for this image is: bioconductor/bioconductor_docker:r4.0.0
FROM rockerdev/rstudio:4.0.0-ubuntu18.04

## Set Dockerfile version number
## This parameter should be incremented each time there is a change in the Dockerfile
ARG BIOCONDUCTOR_DOCKER_VERSION=3.11.10

LABEL name="bioconductor/bioconductor_docker" \
      version=$BIOCONDUCTOR_DOCKER_VERSION \
      url="https://github.com/Bioconductor/bioconductor_docker" \
      vendor="Bioconductor Project" \
      maintainer="maintainer@bioconductor.org" \
      description="Bioconductor docker image with system dependencies to install most packages." \
      license="Artistic-2.0"

RUN echo BIOCONDUCTOR_DOCKER_VERSION=$BIOCONDUCTOR_DOCKER_VERSION >> /etc/environment \
	&& echo BIOCONDUCTOR_DOCKER_VERSION=$BIOCONDUCTOR_DOCKER_VERSION >> /root/.bashrc

# nuke cache dirs before installing pkgs; tip from Dirk E fixes broken img
RUN rm -f /var/lib/dpkg/available && rm -rf  /var/cache/apt/*

# issues with '/var/lib/dpkg/available' not found
# this will recreate
RUN dpkg --clear-avail

# This is to avoid the error
# 'debconf: unable to initialize frontend: Dialog'
ENV DEBIAN_FRONTEND noninteractive

# Update apt-get
RUN apt-get update \
	&& apt-get install -y --no-install-recommends apt-utils \
	&& apt-get install -y --no-install-recommends default-libmysqlclient-dev \
	&& apt-get install -y --no-install-recommends libgdal-dev \
	## Basic deps
	&& apt-get install -y --no-install-recommends \
	gdb \
	libxml2-dev \
	python3-pip \
	zlib1g-dev \
	liblzma-dev \
	libbz2-dev \
	libpng-dev \
	#libmariadb-dev-compat \
	## sys deps from bioc_full
	pkg-config \
	fort77 \
	byacc \
	automake \
	curl \
	## This section installs libraries
	libpng-dev \
	libnetcdf-dev \
	libhdf5-dev \
	libfftw3-dev \
	libopenbabel-dev \
	libopenmpi-dev \
	libexempi-dev \
	libxt-dev \
	libgdal-dev \
	libturbojpeg0-dev \
	libcairo2-dev \
	libtiff5-dev \
	libreadline-dev \
	libgsl-dev \
	libgslcblas0 \
	libgtk2.0-dev \
	libgl1-mesa-dev \
	libglu1-mesa-dev \
	libgmp3-dev \
	libhdf5-dev \
	libncurses5-dev \
	libbz2-dev \
	libxpm-dev \
	liblapack-dev \
	libv8-dev \
	libgtkmm-2.4-dev \
	libmpfr-dev \
	libudunits2-dev \
	libmodule-build-perl \
	libapparmor-dev \
	libgeos-dev \
	libprotoc-dev \
	librdf0-dev \
	libmagick++-dev \
	libsasl2-dev \
	libpoppler-cpp-dev \
	libprotobuf-dev \
	libpq-dev \
	libperl-dev \
	## software - perl extentions and modules
	libarchive-extract-perl \
	libfile-copy-recursive-perl \
	libcgi-pm-perl \
	libdbi-perl \
	libdbd-mysql-perl \
	libxml-simple-perl \
	## Databases and other software
	sqlite \
	openmpi-bin \
	mpi-default-bin \
	openmpi-common \
	openmpi-doc \
	tcl8.6-dev \
	tk-dev \
	default-jdk \
	imagemagick \
	tabix \
	ggobi \
	graphviz \
	protobuf-compiler \
	jags \
	## Additional resources
	xfonts-100dpi \
	xfonts-75dpi \
	biber \
	software-properties-common \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
	
#RUN add-apt-repository universe \
#	&& add-apt-repository multiverse \
#	&& add-apt-repository restricted

## Python installations
RUN apt-get update \
	&& apt-get -y --no-install-recommends install python3-dev \
	&& pip3 install wheel \
	## Install sklearn and pandas on python
	&& pip3 install sklearn \
	pandas \
	pyyaml \
	cwltool \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install libsbml and xvfb
RUN cd /tmp \
	## libsbml
	&& wget https://sourceforge.net/projects/sbml/files/libsbml/5.18.0/stable/libSBML-5.18.0-core-src.tar.gz \
	&& tar zxf libSBML-5.18.0-core-src.tar.gz \
	&& cd libsbml-5.18.0 \
	&& ./configure --enable-layout \
	&& make \
	&& make install \
	## xvfb install
	#&& cd /tmp \
	#&& rm -rf /tmp/s6-overlay* \
	#&& wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-amd64.tar.gz \
	#&& tar zxf s6-overlay-amd64.tar.gz -C / \
	#&& apt-get install -y --no-install-recommends xvfb \
	#&& mkdir -p /etc/services.d/xvfb/ \
	## Clean libsbml, and tar.gz files
	&& rm -rf /tmp/libsbml-5.18.0 \
	&& rm -rf /tmp/libSBML-5.18.0-core-src.tar.gz \
	## apt-get clean and remove cache
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

#COPY ./deps/xvfb_init /etc/services.d/xvfb/run

RUN echo "R_LIBS=/usr/local/lib/R/host-site-library:\${R_LIBS}" > /usr/local/lib/R/etc/Renviron.site \
	&& echo "options(defaultPackages=c(getOption('defaultPackages'),'BiocManager'))" >> /usr/local/lib/R/etc/Rprofile.site

ADD install.R /tmp/

RUN R -f /tmp/install.R

# DEVEL: Add sys env variables to DEVEL image
RUN wget http://bioconductor.org/checkResults/devel/bioc-LATEST/Renviron.bioc \
	&& cat Renviron.bioc | grep -o '^[^#]*' | sed 's/export //g' >>/etc/environment \
	&& cat Renviron.bioc >> /usr/local/lib/R/etc/Renviron.site \
	&& rm -rf Renviron.bioc

# Init command for s6-overlay
CMD ["/init"]
