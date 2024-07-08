#!/bin/bash

listTestcase=(testcase testcase_baud_change testcase_break_condition testcase_msb_first \
	testcase_multiple_access testcase_parity_msb testcase_parity);

echo "********************************************";
echo "*********Regress test begin!****************";
echo "********************************************";

trap 'kill $!; exit' INT #terminate script running when press CTRL+C 
for tsc in ${listTestcase[@]}
do
	echo;
	echo;
	echo "     Run test " ${tsc}  "..."
	echo;

	make ${tsc};
    ./uart.out;
	make clean;

	echo;
	echo;
done

echo "********************************************";
echo "*********Regress test end!******************";
echo "********************************************";
