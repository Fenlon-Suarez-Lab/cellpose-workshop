#!/bin/bash --login

# Slurm directives for resource allocation
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --job-name=cellpose_counts
#SBATCH --time=01:00:00
#SBATCH --partition=gpu_cuda
#SBATCH --qos=gpu
#SBATCH --gres=gpu:l40:1
#SBATCH --account=a_suarez
#SBATCH -o /home/%u/Logs/output-%j.log
#SBATCH -e /home/%u/Logs/error-%j.log

# Other gres options include:
# a100 10GB slice - gpu:nvidia_a100_80gb_pcie_1g.10gb:1
# a100 20GB slice - gpu:nvidia_a100_80gb_pcie_2g.20gb:1

# Load modules
module load cuda/12.2.0
module load cudnn/8.9.2.26-cuda-12.2.0
module load miniconda3/4.12.0

# Parse options
while getopts "d:m::" opt; do
    case $opt in
        d) DIAMETER=$OPTARG ;;
        m) MODEL=$OPTARG ;;
        \?) echo "invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Prep conda
. /sw/auto/rocky8c/epyc3_l40/software/Miniconda3/4.12.0/etc/profile.d/conda.sh
conda activate
conda activate /sw/local/rocky8/noarch/rcc/software/cellpose/3

# Set scripts and directories
PY_SCRIPT="$HOME/Software/cellpose-workshop/cellpose_counter.py"
INPUT_DIR="/QRISdata/Q7021/Cellpose/test_in"
OUTPUT_DIR="/QRISdata/Q7021/Cellpose/test_out"
MODEL_DIR="/QRISdata/Q7021/Cellpose/Cellpose3/models"

if [[ -z $MODEL ]]; then
    MODEL="cyto3"
else
    MODEL="${MODEL_DIR}/${MODEL}"
fi

# Build file list from input directory
declare -a file_list
for file in $INPUT_DIR/*.tif; do 
	file_list+=("$file")
done

# python $PY_SCRIPT ${file_list[@]} # DEPRECATED
python3 -c 'import sys,' \
           'sys.path.append("'(dirname $PY_SCRIPT)'"),' \
           'import cellpose_counter,' \
           'file_string = "'${file_list[@]}'",' \
           'file_list = file_string.split(),' \
           'cellpose_counter.cellpose3_count(file_list, diameter='$DIAMETER', model='$MODEL', outpath='$OUTPUT_DIR')'