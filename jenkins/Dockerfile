# Jenkins LTS + the tools the pipeline needs: docker CLI, aws CLI v2, kubectl.
# The Docker daemon is shared from the host via the mounted socket (see docker-compose.yml).
FROM jenkins/jenkins:lts-jdk17

USER root

# docker CLI client (docker-cli has the `docker` binary; docker.io alone ships only the daemon
# on Debian trixie) + helpers
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release unzip docker-cli \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && rm -rf /tmp/aws /tmp/awscliv2.zip

# kubectl
RUN curl -fsSL -o /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# Let the 'jenkins' user talk to the mounted docker socket. 999 is a common host docker GID;
# override with --build-arg DOCKER_GID=<gid> if your host differs (see docker-compose.yml).
ARG DOCKER_GID=999
RUN groupadd -g ${DOCKER_GID} docker_host 2>/dev/null || true \
    && usermod -aG ${DOCKER_GID} jenkins || usermod -aG docker jenkins || true

USER jenkins
