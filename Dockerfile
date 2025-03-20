#
# Copyright 2017 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# ✅ Build do Spark Operator
FROM golang:1.23.1 AS builder

WORKDIR /workspace

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,source=go.mod,target=go.mod \
    --mount=type=bind,source=go.sum,target=go.sum \
    go mod download

COPY . .

ENV GOCACHE=/root/.cache/go-build

ARG TARGETARCH

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=cache,target="/root/.cache/go-build" \
    CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} GO111MODULE=on make build-operator

# ✅ Build da imagem do Spark com suporte ao Iceberg
FROM docker.io/apache/spark:3.5.3

ARG SPARK_UID=185
ARG SPARK_GID=185

USER root

RUN apt-get update \
    && apt-get install -y tini \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/k8s-webhook-server/serving-certs /home/spark && \
    chmod -R g+rw /etc/k8s-webhook-server/serving-certs && \
    chown -R spark /etc/k8s-webhook-server/serving-certs /home/spark

# ✅ Adicionar dependências do Apache Iceberg
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.0/iceberg-spark-runtime-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-runtime-3.5_2.12-1.5.0.jar

ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-rest-catalog/1.5.0/iceberg-rest-catalog-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-rest-catalog-1.5.0.jar

# ✅ Configurar Iceberg no Spark
RUN echo "spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.type=rest" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.uri=http://iceberg-rest:8181" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> $SPARK_HOME/conf/spark-defaults.conf

# ✅ Copiar o Spark Operator
USER ${SPARK_UID}:${SPARK_GID}

COPY --from=builder /workspace/bin/spark-operator /usr/bin/spark-operator
COPY entrypoint.sh /usr/bin/

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
