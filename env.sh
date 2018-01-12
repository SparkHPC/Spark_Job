export SPARK_HOME=/projects/datascience/apache_spark
export SPARK_WORKER_DIR="$WORKING_DIR/workers"
export SPARK_CONF_DIR="$WORKING_DIR/conf"
export SPARK_LOG_DIR="$WORKING_DIR/logs"

# python 2 non inter
export ANACONDA=/soft/libraries/anaconda
export PYTHONPATH=$ANACONDA/bin/python
export PYSPARK_PYTHON=$PYTHONPATH
export PYSPARK_DRIVER_PYTHON=python
export PYSPARK_DRIVER_PYTHON_OPTS=""

# python 3
#export ANACONDA=/soft/interpreters/python/anaconda/anaconda3
#export PYTHONPATH=$ANACONDA/4.0.0/bin/python
#export PYSPARK_PYTHON=$PYTHONPATH
#export PYSPARK_DRIVER_PYTHON=jupyter
#export PYSPARK_DRIVER_PYTHON_OPTS="notebook --no-browser --ip=$(hostname).cooley.pub.alcf.anl.gov --port=8002"
