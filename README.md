# Запуск и управление приложениями для Spark и PySpark в сервисе Yandex Data Processing

В кластере [Yandex Data Processing](https://yandex.cloud/ru/docs/data-proc) вы можете запустить Spark- и PySpark-задания с помощью инструментов:

* [Spark Shell](https://spark.apache.org/docs/latest/quick-start) (командная оболочка для языков программирования Scala и Python). Расчеты запускаются не с помощью скрипта, а построчно.
* [Spark-submit](https://spark.apache.org/docs/latest/submitting-applications.html#submitting-applications). Скрипт сохраняет результаты расчета в HDFS.
* [CLI Yandex Cloud](https://yandex.cloud/ru/docs/cli/). Команды CLI позволяют сохранить результаты расчета не только в HDFS, но и в бакете [Yandex Object Storage](https://yandex.cloud/ru/docs/storage).

Подготовка инфраструктуры для Yandex Data Processing через Terraform описана в [практическом руководстве](https://yandex.cloud/ru/docs/data-proc/tutorials/run-spark-job), необходимый для настройки конфигурационный файл [data-proc-for-spark-jobs.tf](data-proc-for-spark-jobs.tf) расположен в этом репозитории.
