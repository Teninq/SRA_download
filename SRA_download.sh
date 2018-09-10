#!/bin/bash
########################################
##! @Author: Chenkai Lv
##! @Todo: SRA Data Download
##! @Updated: 2018.09.04
##! @Dep: Shell, ascp
##! @ChangeLog:
##!   argument collection.
##!   ascp supported.
########################################

########################################
# functions

WORK_PATH=$PWD

function version {
  echo -e "\nauthor: Chenkai Lv
updated date: 2018.09.04\n"
  exit 1
}

function usage {
  echo -e "\n$(basename $0) is used to download sra file for sequence(NGS) analysis.\n
Usage:	sh $0 [options]
Options:
	-h --help    display the usage and exit.
	-a --access  necessary file containing SRR number. [e.g. accession.txt]
	-v --version display version information and exit.\n"
	exit 1
}

function exist_fastq {
  if [[ -e ${1} ]]; then
    return 1
  else
    return 2
  fi
}


########################################
# get options

TEMP=$(getopt -a -o ha:t:v -l help,access:,thread:,version -n "$0" -- "$@")

if [ $# = 0 ]; then
  usage
  exit 1
fi

if [ $? != 0 ]; then
  echo -e "ERROR: Terminating..." >&2
  exit 1
fi

# set argv to ($1,$2,...)
eval set -- "$TEMP"

while [ -n "$1" ]
do
  case $1 in
    -h|--help)
      usage;;
    -v|--version)
      version;;
    -a|--access)
      if [[ -f $2 ]]; then
        ACCESS=$2
      else
        echo -e "\e[31mWARNING: The file containing SRR number has not been provied, default setting will be used! \e[0m\n" >&2
      fi
      shift 2;;
    --)
      shift
      break;;
    *)
      echo "Internal error!" >&2
      exit 1;;
  esac
done

########################################
# download sra file

mkdir -p $WORK_PATH/srafile

for i in $(cat ${ACCESS} | grep "^SRR"); do
    echo $(date)
    echo "=====start downloading sra for $i!====="
    x=$(echo $i | cut -b1-6)
    y=$(echo $i | cut -b1-3)
    exist_fastq $WORK_PATH/srafile/${i}.sra
    value=$?
    if [[ ${value} -eq 2 ]]; then
      ascp -T -i /home/usertest/.aspera/connect/etc/asperaweb_id_dsa.openssh -k 1 -l 200m \
         anonftp@ftp-private.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/${y}/${x}/${i}/${i}.sra $WORK_PATH/srafile \
         2> $WORK_PATH/srafile/${i}_download.log
      echo $(date)
      echo "=====${i}.sra has been downloaded!=====" 
    elif [[ ${value} -eq 1 ]]; then
      echo -e "${i} sra has been existed, continue... \e[0m"
    fi
done

########################################

########################################
# transform from SRA to fastq
mkdir -p $WORK_PATH/fastq-dump

for i in $(cat ${ACCESS} | grep "^SRR"); do
    echo $(date)
    echo -e "=====start transforming SRA to fastq for ${i}!====="
    exist_fastq $WORK_PATH/fastq-dump/${i}*.fastq.gz
    value=$?
    if [[ ${value} -eq 2 ]]; then
      fastq-dump --split-3 $WORK_PATH/srafile/${i}.sra --gzip -O $WORK_PATH/fastq-dump \
               2> $WORK_PATH/fastq-dump/${i}.fastq-dump.log
      echo -e "=====finish transforming SRA to fastq for ${i}!=====\n"
    elif [[ ${value} -eq 1 ]]; then
      echo -e "${i} fq has been existed\e[0m"
    fi
done



