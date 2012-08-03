#!/bin/bash
#
# Generate problem directory from problem descriptions

i=0
#0 => rare_order
#1 => gears
#2 => jolly_jumpers
out="/opt/crashandcompile/problems"

rm -rf $out
mkdir -p $out

for d in $@
do
	mkdir -p "$out/$i"
	markdown $d/*.md > "$out/$i/problem.html"
	if [ -d $d/inputs ]
	then
		cp $d/inputs/* "$out/$i"
	else
		echo "No inputs for $d"
	fi
	if [ -d $d/outputs ]
	then
		cp $d/outputs/* "$out/$i"
	else
		echo "No outputs for $d"
	fi
	echo $d $i
	i=$(($i + 1))
done
