#!/bin/bash  

trap 'kill $!; exit' INT #terminate script running when press CTRL+C 

#set the number of arguments
ARG_NUM=1

#check arguments
if [ $# -ne $ARG_NUM ]; then
  echo -e "\nargument number error: $#"
  echo "the number of arguments should be :$ARG_NUM"
  echo "usage: ./runcase.sh tc_name"
  echo -e "for example: ./runcase.sh tc_rapid_ptp_test\n"
  exit 1
fi

#define variables
#note: remove space around '='
elfFile=xge-ptpv2 
waveFile=xge-ptpv2

#compile and run
iverilog -o ${elfFile}.out -s $1 -f comp.f 
vvp -n ${elfFile}.out -fst
#gtkwave ${waveFile}.fst
