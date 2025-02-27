# hadolint ignore=DL3007
FROM myoung34/github-runner-base:ubuntu-focal
LABEL maintainer="walker@lithic.com"

ENV DEBIAN_FRONTEND=noninteractive

# Install Docker
RUN apt-get update && apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unzip
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor > /etc/apt/keyrings/docker.gpg
#TODO: verify default umask is set correctly
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN mkdir -p /opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.299.1"
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Used to pass in secrets via Buildx
# Pass a GitHub PAT in as an environment variable so the container can call out to git properly
RUN --mount=type=secret,id=REPO_ACCESS_GITHUB_PAT \
  git config --global url.https://foo:$(cat /run/secrets/REPO_ACCESS_GITHUB_PAT)@github.com/privacy-com.insteadOf https://github.com/privacy-com

# Enable ephemeral runner
ENV EPHEMERAL=1

WORKDIR /actions-runner
COPY install_actions.sh /actions-runner

# TODO: remove this terrible sed once
#  https://github.com/actions/runner/pull/1585 is merged or similar
RUN chmod +x /actions-runner/install_actions.sh \
  && sed -i.bak 's/.\/bin\/installdependencies.sh/wget https:\/\/raw.githubusercontent.com\/myoung34\/runner\/main\/src\/Misc\/layoutbin\/installdependencies.sh -O .\/bin\/installdependencies.sh; bash .\/bin\/installdependencies.sh/g' /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh

COPY token.sh entrypoint.sh /
RUN chmod +x /token.sh /entrypoint.sh

## Custom tweaks to fix build breaks - most are specific to the server repo
# add github.com host keys
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# install missing package dependencies (mostly server/core requirements)
RUN apt-get update && apt-get install -y \
  ccache \
  gawk \
  libbackward-cpp-dev \ 
  libidn2-dev \
  libmysqlclient21 \
  libnghttp2-dev \
  ninja-build \
  nodejs \
  npm \
  python3-venv \
  python3.8 \
  python3.8-venv \
  uuid-runtime

EXPOSE 8000

# TODO: remove this hack and install python more canonically, ideally
RUN ln -s /usr/bin/python3 /usr/bin/python

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
