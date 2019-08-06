# Copyright 2019 Myles Gray <mg@mylesgray.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# AUTHOR:         Myles Gray <mg@mylesgray.com>
# DESCRIPTION:    mylesagray/velero

ARG BASE
FROM ${BASE}

LABEL summary="Multiarch Heptio Velero" \
    description="Multiarch images for Heptio Velero and Restic" \
    name="mylesagray/velero" \
    url="https://github.com/mylesagray/velero-multiarch" \
    maintainer="Myles Gray <mg@mylesgray.com>"

ARG BIN_ARCH
ARG VELERO_VERSION
ARG RESTIC_VERSION

RUN apk update && \
    apk upgrade && \
    apk add ca-certificates && \
    rm -rf /var/cache/apk/* && \
    update-ca-certificates 2>/dev/null || true

RUN apk add --no-cache --virtual .build-deps tar wget bzip2 && \
    wget --quiet https://github.com/heptio/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-${BIN_ARCH}.tar.gz && \
    tar -zxvf velero-${VELERO_VERSION}-linux-${BIN_ARCH}.tar.gz && \
    rm velero-${VELERO_VERSION}-linux-${BIN_ARCH}.tar.gz && \
    mv velero-${VELERO_VERSION}-linux-${BIN_ARCH}/velero /velero && \
    chmod +x /velero && \
    wget --quiet https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${BIN_ARCH}.bz2 && \
    bunzip2 restic_${RESTIC_VERSION}_linux_${BIN_ARCH}.bz2 && \
    mv restic_${RESTIC_VERSION}_linux_${BIN_ARCH} /usr/bin/restic && \
    chmod +x /usr/bin/restic && \
    apk del .build-deps

USER nobody:nobody

ENTRYPOINT ["/velero"]