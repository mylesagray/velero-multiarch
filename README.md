# Velero Multiarch Image with Restic

Multiarch Docker image for [Velero](https://velero.io).

Includes `amd64`, `arm32v7` and `arm64`.

Available on Docker Hub `mylesagray/velero`.

You can build your own images using the `Makefile`:

```sh
$ NAMESPACE=mylesagray IMAGE=velero make all
```