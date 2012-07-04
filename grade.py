#!/usr/bin/env python
# vim: tabstop=4 shiftwidth=4 softtabstop=4

import sys
import os
import subprocess


def try_compile(source):
    """ Accepts source file name, tries to figure out what it is and compile
    it. Returns the executable command for running the compiled (or not
    compiled) program and potentially a filename to cleanup
    """
    sourcepath = source.split('/')
    (basename, extension) = sourcepath[-1].rpartition(".")[::2]

    comp = None
    output = None
    executable = source

    if extension == "cpp":
        comp = "g++ -o %s %s" % (basename, source)
        executable = "./%s" % basename
        output = basename

    elif extension == "c":
        comp = "gcc -o %s %s" % (basename, source)
        executable = "./%s" % basename
        output = basename

    elif extension == "java":
        comp = "cp %s . ; javac %s.java" % (source, basename)
        executable = "java %s" % basename
        output = "%s.class" % basename

    elif extension == "frink":
        executable = "/home/hendrix/bin/frink %s" % source

    else:
        # assume interpreted
        comp = "chmod u+x %s" % source
        if len(sourcepath) < 2:
            executable = "./%s" % source

    # if we have a compile command, run it
    if comp:
        comp_cmd = subprocess.Popen(comp, shell=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE)
        # TODO: timeout rather than wait forever
        if comp_cmd.wait():
            print "Compilation failed"
            (out, err) = comp_cmd.communicate()
            print out
            print err
            sys.exit(1)

    return executable, output


def main(source, input_file, output_file=None):
    # TODO: take submissions with a makefile
    # TODO: take submissions as a tarball
    # TODO: run tests in a chroot

    executable, output = try_compile(source)

    executable = "%s < %s" % (executable, input_file)

    if output_file:
        executable = "%s | diff -B - %s" % (executable, output_file)

    # Run the test program
    exec_cmd = subprocess.Popen(executable, shell=True, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)

    # TODO: timeout rather than wait forever
    if exec_cmd.wait():
        print "Execution failed"
        (out, err) = exec_cmd.communicate()
        #print out
        #print err
        if output:
            os.remove(output)
        sys.exit(2)

    print "%s passed" % source
    if output:
        os.remove(output)

if __name__ == '__main__':
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print "Usage: grade.py <source> <input> [output]"

    main(*sys.argv[1:])
