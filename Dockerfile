FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_LISTCHANGES_FRONTEND=none

# Configure apt for non-interactive use
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90noninteractive && \
  echo 'DPkg::Pre-Install-Pkgs {"/bin/true"};' >> /etc/apt/apt.conf.d/90noninteractive && \
  echo 'DPkg::Post-Install-Pkgs {"/bin/true"};' >> /etc/apt/apt.conf.d/90noninteractive && \
  echo 'Dpkg::Progress-Fancy "0";' >> /etc/apt/apt.conf.d/90noninteractive && \
  echo 'Dpkg::Use-Pty "0";' >> /etc/apt/apt.conf.d/90noninteractive

# Configure default test user
ARG USERNAME="mfaine"
ENV USERNAME="$USERNAME"
ARG UID=1000
ARG GID=1000
ENV UID="${UID}"
ENV GID="${GID}"


RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  curl \
  gzip \
  tar \
  zsh \
  sudo \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add to sudo group with NOPASSWD
# First, handle any existing user/group conflicts by moving them to high IDs
RUN set -e; \
  # Check if a user with target UID exists and change it
  EXISTING_USER=$(getent passwd "${UID}" | cut -d: -f1 || true); \
  if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$USERNAME" ]; then \
  echo "Moving existing user $EXISTING_USER from UID ${UID} to 9999"; \
  usermod -u 9999 "$EXISTING_USER" 2>/dev/null || true; \
  fi; \
  # Check if a group with target GID exists and change it
  EXISTING_GROUP=$(getent group "${GID}" | cut -d: -f1 || true); \
  if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$USERNAME" ]; then \
  echo "Moving existing group $EXISTING_GROUP from GID ${GID} to 9999"; \
  groupmod -g 9999 "$EXISTING_GROUP" 2>/dev/null || true; \
  fi; \
  # Now create our user and group with the desired IDs
  groupadd -g "${GID}" "${USERNAME}" && \
  useradd -m -s /bin/zsh -u "${UID}" -g "${USERNAME}" "${USERNAME}" && \
  usermod -aG sudo "${USERNAME}"

# Allow sudo without password for this user
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
  chmod 0440 /etc/sudoers.d/${USERNAME}

# Switch to the mfaine
USER "${USERNAME}"
WORKDIR "/home/${USERNAME}"

CMD ["tail", "-f", "/dev/null"]
