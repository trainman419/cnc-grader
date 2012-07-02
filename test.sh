#!/bin/bash

cd ones

for f in Ones.java ones.cpp ones.pl ones.py ones.frink
do
   ../grade.py $f in1.txt out1.txt
done
