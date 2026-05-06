# --- bundle: base ---
FROM mcr.microsoft.com/devcontainers/base:ubuntu24.04

ARG TZ=UTC
ENV TZ="$TZ"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      bubblewrap socat \
      fd-find ripgrep tmux zsh \
      build-essential \
      jq unzip \
      dnsutils ipset iptables iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 ships nvim 0.9.x; the bind-mounted host config requires
# >= 0.10 for vim.ui.clipboard.osc52. Pin to match the Arch host (0.12.x).
ARG NVIM_VERSION=0.12.2
RUN ARCH=$(dpkg --print-architecture) && \
    case "${ARCH}" in \
      amd64) NVIM_ARCH="linux-x86_64" ;; \
      arm64) NVIM_ARCH="linux-arm64" ;; \
      *) echo "Unsupported arch: ${ARCH}" && exit 1 ;; \
    esac && \
    mkdir -p /opt/nvim && \
    curl -fsSL "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-${NVIM_ARCH}.tar.gz" \
      | tar -xz -C /opt/nvim --strip-components=1 && \
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" -o /tmp/git-delta.deb && \
    dpkg -i /tmp/git-delta.deb && rm /tmp/git-delta.deb

ARG FZF_VERSION=0.70.0
RUN ARCH=$(dpkg --print-architecture) && \
    case "${ARCH}" in \
      amd64) FZF_ARCH="linux_amd64" ;; \
      arm64) FZF_ARCH="linux_arm64" ;; \
      *) echo "Unsupported arch: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-${FZF_ARCH}.tar.gz" | tar -xz -C /usr/local/bin

ARG WORKMUX_VERSION=0.1.189
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/raine/workmux/releases/download/v${WORKMUX_VERSION}/workmux-linux-${ARCH}.tar.gz" \
      | tar -xz -C /usr/local/bin workmux && \
    chmod +x /usr/local/bin/workmux

# tree-sitter CLI: required by nvim-treesitter's new install() API
# (calls `tree-sitter build` per parser). Pin to match the Arch host.
ARG TREE_SITTER_VERSION=0.26.8
RUN ARCH=$(dpkg --print-architecture) && \
    case "${ARCH}" in \
      amd64) TS_ARCH="x64" ;; \
      arm64) TS_ARCH="arm64" ;; \
      *) echo "Unsupported arch: ${ARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-${TS_ARCH}.gz" \
      | gunzip > /usr/local/bin/tree-sitter && \
    chmod +x /usr/local/bin/tree-sitter

RUN userdel -r vscode 2>/dev/null || true && \
    useradd -m -s /bin/zsh -u 1000 rodc && \
    echo "rodc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rodc && \
    chmod 0440 /etc/sudoers.d/rodc && \
    mkdir -p /workspace /home/rodc/.local/share/nvim /home/rodc/.zshrc.d && \
    chown -R rodc:rodc /workspace /home/rodc

RUN install -d -m 700 -o rodc -g rodc /home/rodc/.ssh

ENV DEVCONTAINER=true
ENV SHELL=/bin/zsh
ENV EDITOR=nvim
ENV VISUAL=nvim

WORKDIR /workspace
USER rodc

ENV PATH="/home/rodc/.local/bin:$PATH"

ARG ZSH_IN_DOCKER_VERSION=1.2.1
RUN sh -c "$(curl -fsSL https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- -p git -x

RUN echo 'for f in ~/.zshrc.d/*.zsh(N); do source "$f"; done' >> /home/rodc/.zshrc

COPY --chown=rodc:rodc files/.zshrc.d/10-base.zsh /home/rodc/.zshrc.d/10-base.zsh
COPY --chown=rodc:rodc files/.zshrc.d/20-workmux.zsh /home/rodc/.zshrc.d/20-workmux.zsh

# --- bundle: python-uv ---
USER root
COPY --from=ghcr.io/astral-sh/uv:0.10 /uv /usr/local/bin/uv
RUN chmod +x /usr/local/bin/uv && chown root:root /usr/local/bin/uv
USER rodc
RUN uv python install 3.13 --default && \
    uv tool install ast-grep-cli

# --- bundle: node-fnm ---
ARG NODE_VERSION=22
ARG FNM_VERSION=1.38.1
ENV FNM_DIR="/home/rodc/.fnm"

USER root
RUN ARCH=$(dpkg --print-architecture) && \
    case "${ARCH}" in \
      amd64) FNM_ARCH="linux" ;; \
      arm64) FNM_ARCH="arm64" ;; \
      *) echo "Unsupported arch: ${ARCH}" && exit 1 ;; \
    esac && \
    mkdir -p "$FNM_DIR" && \
    curl -fsSL "https://github.com/Schniz/fnm/releases/download/v${FNM_VERSION}/fnm-${FNM_ARCH}.zip" -o /tmp/fnm.zip && \
    unzip /tmp/fnm.zip -d "$FNM_DIR" && \
    chmod +x "$FNM_DIR/fnm" && \
    rm /tmp/fnm.zip && \
    chown -R rodc:rodc "$FNM_DIR"
USER rodc

RUN export PATH="$FNM_DIR:$PATH" && \
    eval "$(fnm env)" && \
    fnm install ${NODE_VERSION} && \
    fnm default ${NODE_VERSION}

COPY --chown=rodc:rodc files/.zshrc.d/20-fnm.zsh /home/rodc/.zshrc.d/20-fnm.zsh

# --- bundle: zsh-history ---
USER root
RUN mkdir -p /commandhistory && \
    touch /commandhistory/.zsh_history /commandhistory/.bash_history && \
    chown -R rodc:rodc /commandhistory
USER rodc
COPY --chown=rodc:rodc files/.zshrc.d/30-history.zsh /home/rodc/.zshrc.d/30-history.zsh

# --- bundle: claude-code ---
ARG CLAUDE_VERSION=2.1.119
RUN curl -fsSL https://claude.ai/install.sh | bash -s -- "$CLAUDE_VERSION"

USER root
ARG GH_VERSION=2.92.0
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.deb" -o /tmp/gh.deb && \
    dpkg -i /tmp/gh.deb && rm /tmp/gh.deb
USER rodc

# Pre-create ~/.claude/plugins so the named volume mount inherits rodc:rodc
# ownership. Without this, Docker initialises the empty volume as root:root
# and seed-plugins fails with EACCES on the marketplace mkdir.
RUN mkdir -p /home/rodc/.claude/plugins

COPY --chown=rodc:rodc files/.zshrc.d/40-claude.zsh /home/rodc/.zshrc.d/40-claude.zsh
COPY files/seed-plugins.sh /usr/local/bin/seed-plugins

# --- dcs: staleness tracking ---
COPY .bundle-hash /usr/local/share/dcs/bundle-hash
COPY .source-hash /usr/local/share/dcs/source-hash
