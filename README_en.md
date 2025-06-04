# Running and managing apps for Spark and PySpark in Yandex Data Processing

In a [Yandex Data Processing](https://yandex.cloud/en/docs/data-proc) cluster, you can run Spark or PySpark jobs by means of:

* [Spark Shell](https://spark.apache.org/docs/latest/quick-start) (a command shell for Scala and Python). This method runs calculations line by line rather than using a script.
* [Spark-submit](https://spark.apache.org/docs/latest/submitting-applications.html#submitting-applications). This script saves the calculation results to HDFS.
* [Yandex Cloud CLI](https://yandex.cloud/en/docs/cli/). With CLI commands, you can save calculation results not only to HDFS but also to a [Yandex Object Storage](https://yandex.cloud/en/docs/storage) bucket.

See [this tutorial](https://yandex.cloud/en/docs/data-proc/tutorials/run-spark-job) to learn to you set up the infrastructure for Yandex Data Processing through Terraform. This repository contains the configuration file you will need: [data-proc-for-spark-jobs.tf](data-proc-for-spark-jobs.tf).
