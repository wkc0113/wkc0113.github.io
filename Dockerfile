FROM ubuntu:22.04 as base
LABEL maintainer="wkc19870113@hotmail.com"

RUN apt-get update && \
    apt-get install -y sudo git aptly

WORKDIR /source

# Default command
CMD ["bash"]
