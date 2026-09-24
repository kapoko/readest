# Readest

This module runs a self-hosted Readest backend for shared reader settings and books; its persistent PostgreSQL and MinIO data is kept in `data/`. The upstream Readest source is pinned as the `readest` submodule; its [Docker Compose configuration at the latest stable release (v0.12.10)](https://github.com/readest/readest/blob/v0.12.10/docker/compose.yaml) is the compatibility reference for the backend image versions here. Generate production configuration with `READEST_PUBLIC_URL=https://<reader-host> READEST_S3_PUBLIC_URL=https://<storage-host> ./init.sh`.
