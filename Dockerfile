# Use the same base image as production (native platform for faster local development)
FROM public.ecr.aws/docker/library/python:3.9-slim-bookworm

# Match production user naming and structure
ENV USER=budgea_user \
    USER_UID=1100
ENV HOMEDIR=/home/${USER} \
    WORKDIR=/home/${USER}/dev
ENV PYTHON_PACKAGES_INSTALLATION_PATH=${HOMEDIR}/.local
    # UV_PYTHON_PACKAGES_INSTALLATION_PATH=${WORKDIR}/backend/.venv
ENV PYTHON_SITE_PACKAGES_INSTALLATION_PATH=${PYTHON_PACKAGES_INSTALLATION_PATH}/lib/python3.9/site-packages
    # UV_PYTHON_SITE_PACKAGES_INSTALLATION_PATH=${UV_PYTHON_PACKAGES_INSTALLATION_PATH}/lib/python3.9/site-packages
ENV PYTHON_SITE_PACKAGES_INSTALLATION_PATH_WOOB_MODULES=${PYTHON_SITE_PACKAGES_INSTALLATION_PATH}/woob_modules

# Environment variables matching production
ENV PYTHONUNBUFFERED=1 \
    TZ="Europe/Paris" \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PATH="$PATH:${PYTHON_PACKAGES_INSTALLATION_PATH}/bin:${WORKDIR}/scripts" \
    PYTHONPATH="${WORKDIR}:${WORKDIR}/budgea_user:${WORKDIR}/woob:${PYTHON_PACKAGES_INSTALLATION_PATH}/bin:${PYTHON_SITE_PACKAGES_INSTALLATION_PATH}:${PYTHON_SITE_PACKAGES_INSTALLATION_PATH_WOOB_MODULES}" \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_SYNC=1 \
    UV_SYNC_EXTRA_OPTS="--no-install-package argparse" \
    PW_CONFIG_FILES=backend.conf

# Create directories and user (matching production)
RUN mkdir -p /var/log/bi /etc/bi && \
    useradd --create-home --uid ${USER_UID} ${USER} && \
    mkdir -p ${HOMEDIR}/data ${HOMEDIR}/sessions && \
    chown -R ${USER}:${USER} ${HOMEDIR} /var/log/bi /etc/bi

# Create and set ownership of workdir
RUN mkdir -p ${WORKDIR} && chown -R ${USER}:${USER} ${WORKDIR}
WORKDIR $WORKDIR

# Install system dependencies (closer to production)
RUN apt-get update && apt-get install --no-install-recommends -y \
    # Basic tools
    sudo vim.tiny curl procps nano \
    # Build dependencies
    build-essential \
    libmariadb-dev libmariadb-dev-compat \
    libmagic-dev libpcre3 libpcre3-dev \
    poppler-utils \
    # Backend-specific
    chromium-driver \
    libglib2.0-0 \
    # Database
    default-mysql-client mariadb-server default-mysql-server \
    # Worker dependencies
    gearman-job-server \
    # Dev dependencies
    libsm6 libxext6 libxrender-dev \
    libleptonica-dev libtesseract-dev \
    iputils-ping \
    libdbus-glib-1-2 \
    # Python system packages
    # TODO: Clean a bit
    # TODO: Update these packages as Woob and Backend evolve (and drops Debian provided packages)
    python3-alembic python3-pyflakes python3-bcrypt python3-bs4 \
    python3-dateutil python3-dev python3-ecdsa python3-flask \
    python3-future python3-geopy python3-gnupg python3-html2text \
    python3-httplib2 python3-isort python3-jinja2 python3-httpsig \
    python3-jwcrypto python3-jwt python3-lxml python3-magic \
    python3-mako python3-mysqldb python3-nose python3-nss \
    python3-numpy python3-opencv python3-openssl python3-paramiko \
    python3-paste python3-pdfminer python3-pil python3-prettytable \
    python3-pycryptodome python3-reportlab python3-requests-futures \
    python3-scipy python3-selenium python3-setuptools python3-simplejson \
    python3-six python3-sklearn python3-termcolor python3-unidecode \
    python3-urllib3 python3-xlrd python3-yaml python3-webtest \
    python3-werkzeug python3-wrapt python3-requests python3-prompt-toolkit \
    python3-googleapi libgl1 \
    && apt-get clean

# Install uv
# RUN pip install "uv==0.5.1"

# Add user to sudo with no password
RUN usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to user and setup Python environment
USER ${USER}

# Create virtual environment using uv
# TODO: comment what is this
# RUN uv venv --relocatable ${UV_PYTHON_PACKAGES_INSTALLATION_PATH}

# Copy dependency installation script
COPY --chown=${USER}:${USER} install_deps.sh ${WORKDIR}/install_deps.sh
RUN chmod +x ${WORKDIR}/install_deps.sh
# TODO: need to run this script in the container right away?

# Copy and setup bashrc
COPY --chown=${USER}:${USER} additional_bashrc /tmp/additional_bashrc
RUN cat /tmp/additional_bashrc >> ${HOMEDIR}/.bashrc

# Activate virtual environment by default
# RUN echo "source ${UV_PYTHON_PACKAGES_INSTALLATION_PATH}/bin/activate" >> ${HOMEDIR}/.bashrc

WORKDIR ${HOMEDIR}

CMD ["bash"]