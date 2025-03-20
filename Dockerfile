#
# Copyright 2017 Google LLC
#

ARG SPARK_IMAGE=docker.io/apache/spark:3.5.3  # Certifique-se de que este Spark tem suporte ao Iceberg

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

FROM ${SPARK_IMAGE}  # 🔥 Agora usa a imagem corrigida do Spark com Iceberg 🔥

ARG SPARK_UID=185
ARG SPARK_GID=185

USER root

# Instala pacotes necessários
RUN apt-get update \
    && apt-get install -y tini \
    && rm -rf /var/lib/apt/lists/*

# Configura permissões no OpenShift
RUN mkdir -p /etc/k8s-webhook-server/serving-certs /home/spark && \
    chmod -R g+rw /etc/k8s-webhook-server/serving-certs && \
    chown -R spark /etc/k8s-webhook-server/serving-certs /home/spark

# ✅ Garante que o diretório de configuração do Spark exista ✅
RUN mkdir -p $SPARK_HOME/conf/

# ✅ Adiciona suporte ao Iceberg para os pods do Spark ✅
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.0/iceberg-spark-runtime-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-runtime-3.5_2.12-1.5.0.jar

ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-extensions-3.5_2.12/1.5.0/iceberg-spark-extensions-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-extensions-3.5_2.12-1.5.0.jar

# ✅ Configuração do Spark para Iceberg ✅
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.type=hadoop" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.warehouse=s3a://iceberg-warehouse/" >> $SPARK_HOME/conf/spark-defaults.conf

USER ${SPARK_UID}:${SPARK_GID}

COPY --from=builder /workspace/bin/spark-operator /usr/bin/spark-operator
COPY entrypoint.sh /usr/bin/

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
