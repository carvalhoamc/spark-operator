#
# Copyright 2018 Google LLC
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

FROM docker.io/apache/spark:3.5.3

# Switch to user root so we can add additional jars and configuration files.
USER root

# ✅ Remover dependências desnecessárias
RUN rm -f $SPARK_HOME/jars/guava-14.0.1.jar

# ✅ Adicionar dependências do Iceberg para Spark 3.5.3
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.5.0/iceberg-spark-runtime-3.5_2.12-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-spark-runtime-3.5_2.12-1.5.0.jar

# ✅ Adicionar suporte ao Iceberg REST Catalog (se necessário)
ADD https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-rest-catalog/1.5.0/iceberg-rest-catalog-1.5.0.jar $SPARK_HOME/jars/
RUN chmod 644 $SPARK_HOME/jars/iceberg-rest-catalog-1.5.0.jar

# ✅ Configurar Iceberg no Spark
RUN echo "spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.type=rest" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.catalog.iceberg.uri=http://iceberg-rest:8181" >> $SPARK_HOME/conf/spark-defaults.conf
RUN echo "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions" >> $SPARK_HOME/conf/spark-defaults.conf

# ✅ Setup para o Prometheus JMX Exporter.
ADD https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar /prometheus/
RUN chmod 644 /prometheus/jmx_prometheus_javaagent-0.11.0.jar

USER ${spark_uid}

RUN mkdir -p /etc/metrics/conf
COPY conf/metrics.properties /etc/metrics/conf
COPY conf/prometheus.yaml /etc/metrics/conf

ENTRYPOINT ["/opt/entrypoint.sh"]
