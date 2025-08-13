# Product Overview

## Solid Waffle - Powens Full Stack Development Environment

This project provides a Docker-based development environment for the complete Powens stack, enabling local testing of the full application on both macOS and Linux systems using a Debian Bookworm container.

### Core Components

- **Backend**: API server (Python-based) - mounted for live development
- **Woob**: Banking connectors and modules - mounted for live development  
- **Apishell**: API utilities - mounted for live development
- **Webview**: Frontend UI - served from pre-built Docker image (no local repo needed)
- **MariaDB**: Database server
- **Gearman**: Job queue server for background tasks

### Key Features

- Multi-platform support (ARM64 Macs, Intel Macs, x86_64 Linux)
- Live code mounting for backend, woob, and apishell changes
- Production-like environment using same base images as production
- Complete development toolchain with automated setup scripts
- Environment secrets support through shell environment variables

### Development Strategy

Only backend, woob, and apishell are mounted as volumes since these are the components developers typically modify. The webview uses a pre-built Docker image from registry and connects to live backend changes.

### Architecture Considerations

- **Fast Development**: Native architecture builds (ARM64 on Apple Silicon, x86_64 on Intel/AMD)
- **Production Testing**: AMD64 with emulation when needed for exact production match
- Performance optimized for different platforms with architecture-specific builds