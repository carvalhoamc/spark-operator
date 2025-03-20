#
# Copyright 2018 Google LLC
#

FROM docker.io/apache/spark:3.5.3

# Switch to user root so we can add additional jars and configuration files.
USER root

# Remove JARs antigos que podem causar conflitos
RUN rm -f $SPARK_HOME/jars/guava-14.0.1.jar

# ✅ Adiciona o Iceberg para Spark 3.5 ✅
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.0/iceberg-spark-runtime-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-runtime-3.5_2.12-1.5.0.jar

# Adiciona Extensões do Iceberg (se necessário)
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-extensions-3.5_2.12/1.5.0/iceberg-spark-extensions-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-extensions-3.5_2.12-1.5.0.jar

# ✅ Configurações do Spark para usar o Iceberg ✅
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.type=hadoop" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.warehouse=s3a://iceberg-warehouse/" >> $SPARK_HOME/conf/spark-defaults.conf

# (Se estiver usando Nessie, altere 'hadoop' para 'nessie' e configure o endpoint correto)

# Setup para Prometheus JMX Exporter
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar /prometheus/
RUN chmod 644 /prometheus/jmx_prometheus_javaagent-0.11.0.jar

USER ${spark_uid}

RUN mkdir -p /etc/metrics/conf
COPY conf/metrics.properties /etc/metrics/conf
COPY conf/prometheus.yaml /etc/metrics/conf

ENTRYPOINT ["/opt/entrypoint.sh"]
