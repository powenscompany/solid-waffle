# Lean Dockerfile following container best practices
# Only system dependencies and basic setup - Python deps handled at runtime

FROM public.ecr.aws/docker/library/python:3.9-slim-bookworm

# Build arguments
ARG USER=budgea_user
ARG USER_UID=1100

# Environment variables for production compatibility
ENV PYTHONUNBUFFERED=1 \
    TZ="Europe/Paris" \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PW_CONFIG_FILES=backend.conf

# Create user and basic directory structure
RUN useradd --create-home --uid ${USER_UID} ${USER} && \
    mkdir -p /var/log/bi /etc/bi /home/${USER}/dev && \
    chown -R ${USER}:${USER} /home/${USER} /var/log/bi /etc/bi

# Install ONLY system dependencies (no Python packages)
RUN apt-get update && apt-get install --no-install-recommends -y \
    # Essential tools
    sudo curl git tmux vim-tiny nano procps \
    # Build dependencies for Python packages
    build-essential \
    # Database client libraries
    default-mysql-client \
    libmariadb-dev libmariadb-dev-compat \
    # System libraries needed by Python packages
    libmagic-dev libpcre3-dev \
    libglib2.0-0 libgl1 \
    libsm6 libxext6 libxrender-dev \
    libleptonica-dev libtesseract-dev \
    libdbus-glib-1-2 \
    # Runtime dependencies
    poppler-utils \
    chromium-driver \
    gearman-job-server \
    iputils-ping \
    # Python development headers (needed for some packages)
    python3-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add user to sudo with no password (development only)
RUN usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Task (go-task) as system binary
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Switch to user
USER ${USER}
WORKDIR /home/${USER}

# Set basic PATH (runtime scripts will extend this)
ENV PATH="/home/${USER}/.local/bin:${PATH}"

# Default command
CMD ["bash"]