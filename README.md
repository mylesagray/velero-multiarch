# Velero Multiarch Image with Restic

[![GitHub repo](https://img.shields.io/badge/repo-GitHub-brightgreen)](https://github.com/mylesagray/velero-multiarch)
[![GitHub last commit](https://img.shields.io/github/last-commit/mylesagray/velero-multiarch.svg)](https://github.com/mylesagray/velero-multiarch)
[![Build Status](https://travis-ci.org/mylesagray/velero-multiarch.svg?branch=master)](https://travis-ci.org/mylesagray/velero-multiarch)
![Docker Pulls](https://img.shields.io/docker/pulls/mylesagray/velero)

Multiarch Docker image for [Velero](https://velero.io) with Restic, includes support for `amd64`, `arm32v7` and `arm64` architectures.

Available on Docker Hub at [`mylesagray/velero`](https://cloud.docker.com/repository/docker/mylesagray/velero).

## Using

If you want to use this with the [Helm chart](https://github.com/helm/charts/tree/master/stable/velero/) adjust the [values.yaml](helm/values.yaml) file to suit your environment and run:

```sh
helm install stable/velero --name velero --namespace velero -f helm/values.yaml
```

_Note: the above config uses this multiarch image, the chart's settings have snapshots disabled and has the provider set to `aws` as it's required to be populated by the chart - as-is, it is set up for on-prem deployments with Restic for PV backups._

## Building

You can build your own images using the `Makefile`:

```sh
REPO=mylesagray IMAGE=velero VELERO_VERSION=v1.0.0 make all
```