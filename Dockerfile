FROM python:3.13-slim as envs

# Set arguments to be used throughout the image
ARG OPERATOR_HOME="/home/op"
ARG OPERATOR_USER="op"
ARG OPERATOR_UID="50000"

# Set arguments for access s3 bucket to mount using s3fs
ARG BUCKET_NAME
ARG S3_ENDPOINT="eu-central-1"

# Add environment variables based on arguments
ENV OPERATOR_HOME ${OPERATOR_HOME}
ENV OPERATOR_USER ${OPERATOR_USER}
ENV OPERATOR_UID ${OPERATOR_UID}
ENV BUCKET_NAME ${BUCKET_NAME}
ENV S3_ENDPOINT ${S3_ENDPOINT}

# Add user for code to be run as (we don't want to be using root)
RUN useradd -ms /bin/bash -d ${OPERATOR_HOME} --uid ${OPERATOR_UID} ${OPERATOR_USER}

# Dist Image
FROM envs as dist

# install s3fs
RUN set -ex && \
    apt-get update && \
    apt-get install -y fuse3 s3fs && \ 
     rm -rf /var/lib/apt/lists/*

# setup s3fs configs
RUN echo "s3fs#${BUCKET_NAME} ${OPERATOR_HOME}/s3_bucket fuse _netdev,allow_other,nonempty,sigv4,umask=000,uid=${OPERATOR_UID},gid=${OPERATOR_UID},passwd_file=${OPERATOR_HOME}/.s3fs-creds,use_cache=/tmp,endpoint=${S3_ENDPOINT} 0 0" >> /etc/fstab
RUN sed -i '/user_allow_other/s/^#//g' /etc/fuse.conf

# Set our user to the operator user
USER ${OPERATOR_USER}
WORKDIR ${OPERATOR_HOME}

RUN printf '#!/usr/bin/env bash  \n\
echo ${ACCESS_KEY_ID}:${SECRET_ACCESS_KEY} > ${OPERATOR_HOME}/.s3fs-creds \n\
chmod 400 ${OPERATOR_HOME}/.s3fs-creds \n\
mkdir ${OPERATOR_HOME}/s3_bucket \n\
mount -a \n\
exec /bin/sh \
' >> ${OPERATOR_HOME}/entrypoint.sh

RUN chmod 700 ${OPERATOR_HOME}/entrypoint.sh
ENTRYPOINT [ "/home/op/entrypoint.sh" ]
