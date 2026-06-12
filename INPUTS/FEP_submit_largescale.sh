#!/bin/bash -l
#
#SBATCH --nodes=NODES
#SBATCH --ntasks-per-node=NTASKS
#SBATCH --mem MEMORY
#SBATCH -p PARTITION
#              d-hh:mm:ss
#SBATCH --time=TIME

## Instead of submitting 1 job per replica, this script submits all replicas as a single long job.
## Since LIE is very fast, this version avoids having to manage many short jobs,
## useful for HPC systems with a maximum number of jobs in queue per user
## Only needs changing the RUNFILE to a standard script instead of a SLURM submission script

temperatures=(TEMP_VAR)
runs=RUN_VAR
restartfile=md_0000_1000.re
workdir="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
inputfiles=$workdir/inputfiles
submitfile=$inputfiles/RUNFILE

sed -i s/finalMDrestart=.*/finalMDrestart="$restartfile"/g $submitfile
sed -i s#workdir=.*#workdir="$workdir"#g $submitfile
sed -i s#inputfiles=.*#inputfiles="$inputfiles"#g $submitfile
for temp in ${temperatures[*]};do
sed -i s/temperature=.*/temperature="$temp"/g $submitfile
for i in $(seq 1 $runs);do
sed -i s/run=.*/run="$i"/g $submitfile
sh $submitfile
done
done

###### Clean dcd files
for i in $(seq 1 $runs);do
rm $workdir/FEP*/$temp/$i/*.dcd
done

###### analyze results
conda activate qligfep
export QLIGFEP="/home2/odiaz/software/QLIE/qligfep_LIE/"
export PATH=${QLIGFEP}:${PATH}
export PYTHONPATH=${QLIGFEP}:${PYTHONPATH}

cd $workdir/..
analyze_LIE.py -L $workdir -C DRAGO > $workdir/dG_LIE.log

###### compress outputs
cd $workdir
tar -czvf LIE_results.tar.gz FEP*
rm -rf FEP*
