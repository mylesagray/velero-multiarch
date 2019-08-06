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

# VERSION 1.0.0
# AUTHOR:         Myles Gray <mg@mylesgray.com>
# DESCRIPTION:    mylesagray/velero

ARG BASE
FROM ${BASE}

LABEL summary="Heptio Velero for ARM" \
    description="Heptio Velero for ARM devices" \
    name="mylesagray/velero" \
    url="https://github.com/mylesagray/arm-velero" \
    maintainer="Myles Gray <mg@mylesgray.com>"

ARG BIN_ARCH
ARG VELERO_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget bzip2 && \
    wget --quiet https://github.com/heptio/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-${BIN_ARCH}.tar.gz && \
    tar -zxvf velero-${VELERO_VERSION}-linux-${BIN_ARCH}.tar.gz && \
    rm velero-${VELERO_VERSION}-linux-${BIN_ARCH}.tar.gz && \
    mv velero-${VELERO_VERSION}-linux-${BIN_ARCH}/velero /velero && \
    chmod +x /velero && \
    wget --quiet https://github.com/restic/restic/releases/download/v0.9.4/restic_0.9.4_linux_${BIN_ARCH}.bz2 && \
    bunzip2 restic_0.9.4_linux_${BIN_ARCH}.bz2 && \
    mv restic_0.9.4_linux_${BIN_ARCH} /usr/bin/restic && \
    chmod +x /usr/bin/restic && \
    apt-get remove -y wget bzip2 && \
    rm -rf /var/lib/apt/lists/*

USER nobody:nobody

ENTRYPOINT ["/velero"]