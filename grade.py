#!/usr/bin/env python

import sys
import os
import subprocess

if len(sys.argv) < 3 or len(sys.argv) > 4:
   print "Usage: grade.py <source> <input> [output]"

source = sys.argv[1]
input_file = sys.argv[2]

sourcepath = source.split('/')
(basename,a,extension) = sourcepath[-1].rpartition(".")

# TODO: take submissions with a makefile
# TODO: take submissions as a tarball
# TODO: run tests in a chroot

comp = None
executable = source

if extension == "cpp":
   comp = "gcc -o %s %s"%(basename, source)
   executable = "./%s"%basename
elif extension == "c":
   comp = "gcc -o %s %s"%(basename, source)
   executable = "./%s"%basename
elif extension == "java":
   comp = "cp %s . ; javac %s.java"%(source, basename)
   executable = "java %s"%basename
elif extension == "frink":
   executable = "frink %s"%source
else:
   # assume interpreted
   comp = "chmod u+x %s"%source
   if not source.startswith('/'):
      executable = "./%s"%source

executable = "%s < %s"%(executable, input_file)

if len(sys.argv) == 4:
   executable = "%s | diff -B - %s"%(executable, sys.argv[3])

# if we have a compile command, run it
if comp:
   comp_cmd = subprocess.Popen(comp, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
   # TODO: timeout rather than wait forever
   if comp_cmd.wait():
      print "Compilation failed"
      (out,err) = comp_cmd.communicate()
      print out
      print err
      sys.exit(1)

# Run the test program
exec_cmd = subprocess.Popen(executable, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
# TODO: timeout rather than wait forever
if exec_cmd.wait():
   print "Execution failed"
   sys.exit(2)

print "%s passed"%source
