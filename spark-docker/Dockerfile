#
# Copyright 2018 Google LLC
#

FROM docker.io/apache/spark:3.5.3

# Switch to user root so we can add additional jars and configuration files.
USER root

# Remover dependências desnecessárias
RUN rm -f $SPARK_HOME/jars/guava-14.0.1.jar

# ✅ Criar diretório de configuração caso não exista ✅
RUN mkdir -p $SPARK_HOME/conf && chmod -R 777 $SPARK_HOME/conf

# ✅ Adicionar JARs do Iceberg ✅
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.0/iceberg-spark-runtime-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-runtime-3.5_2.12-1.5.0.jar

ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-extensions-3.5_2.12/1.5.0/iceberg-spark-extensions-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-extensions-3.5_2.12-1.5.0.jar

# ✅ Adicionar configurações do Iceberg ✅
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.type=hadoop" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.warehouse=s3a://iceberg-warehouse/" >> $SPARK_HOME/conf/spark-defaults.conf

# Setup for the Prometheus JMX exporter.
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar /prometheus/
RUN chmod 644 /prometheus/jmx_prometheus_javaagent-0.11.0.jar

USER ${spark_uid}

RUN mkdir -p /etc/metrics/conf
COPY conf/metrics.properties /etc/metrics/conf
COPY conf/prometheus.yaml /etc/metrics/conf

ENTRYPOINT ["/opt/entrypoint.sh"]
