#!/bin/bash

prefix=/opt/crashandcompile
user=www-data

mkdir -p $prefix/archive
mkdir -p $prefix/tmp
mkdir -p $prefix/problems
mkdir -p $prefix/grader

local=`dirname $0`
echo $local

if [ -d $local/.git ] 
then
   echo "Copy files to grader"
   cp -r $local $prefix/grader/
else
   pushd $prefix/grader
   git clone https://github.com/trainman419/cnc-grader.git
fi

chown -R $user $prefix
