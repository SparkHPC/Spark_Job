export ANACONDA=/soft/interpreters/python/anaconda/anaconda3/
export PYSPARK_DRIVER_PYTHON=jupyter
export PYTHONPATH=$ANACONDA/4.0.0/bin/python
export PYSPARK_PYTHON=$ANACONDA/4.0.0/bin/python
export PYSPARK_DRIVER_PYTHON_OPTS="notebook --no-browser --ip=$(hostname).cooley.pub.alcf.anl.gov --port=8002" pyspark
export PYSPARK_MASTER_URI=spark://$(hostname):7077
#export PATH=path_to_add:$PATH
