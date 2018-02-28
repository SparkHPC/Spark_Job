# SPARK

case $SPARKJOB_HOST in
theta)	export SPARK_HOME=/projects/datascience/xyjin/spark-2.2.1-bin-hadoop2.7 ;;
cooley)	export SPARK_HOME=/soft/datascience/apache_spark ;;
*) echo "Unknow host $SPARKJOB_HOST"; exit 1 ;;
esac

export SPARK_WORKER_DIR="$SPARKJOB_WORKING_DIR/workers"
export SPARK_CONF_DIR="$SPARKJOB_WORKING_DIR/conf"
export SPARK_LOG_DIR="$SPARKJOB_WORKING_DIR/logs"

# Java
case $SPARKJOB_HOST in
#theta)	export JAVA_HOME=/opt/java/jdk1.8.0_51 ;;
theta)	module load java ;;
cooley)
	export JAVA_HOME=/soft/compilers/java/jdk1.8.0_60
	export PATH="$JAVA_HOME/bin:$PATH" ;;
*) echo "Unknow host $SPARKJOB_HOST"; exit 1 ;;
esac

# Python
if ((SPARKJOB_PYVERSION==2));then
	case $SPARKJOB_HOST in
	theta)	module load intelpython27 ;;
	cooley)
		export ANACONDA=/soft/libraries/anaconda
		export PYTHONPATH="$ANACONDA/bin/python"
		;;
	*) echo "Unknow host $SPARKJOB_HOST"; exit 1 ;;
	esac
elif ((SPARKJOB_PYVERSION==3));then
	case $SPARKJOB_HOST in
	theta)	module load intelpython35 ;;
	cooley)
		export ANACONDA=/soft/interpreters/python/anaconda/anaconda3
		export PYTHONPATH="$ANACONDA/4.0.0/bin/python"
		;;
	*) echo "Unknow host $SPARKJOB_HOST"; exit 1 ;;
	esac
fi	# else you are on your own.

case $SPARKJOB_HOST in
cooley)
	export PATH="$ANACONDA/bin:$PATH"
	export PYSPARK_PYTHON=$PYTHONPATH
	;;
esac

if ((SPARKJOB_INTERACTIVE>0));then
	case $SPARKJOB_HOST in
	theta)
		echo "Interactive not implemented for theta"
		exit 1
		;;
	cooley)
		export PYSPARK_DRIVER_PYTHON=jupyter
		export PYSPARK_DRIVER_PYTHON_OPTS="notebook --no-browser --ip=$(hostname).cooley.pub.alcf.anl.gov --port=8002"
		;;
	*) echo "Unknow host $SPARKJOB_HOST"; exit 1 ;;
	esac
fi
