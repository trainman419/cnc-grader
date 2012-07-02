#!/usr/bin/env python

import sys

def ones(i):
   r = 0
   while i > 0:
      if i % 10 == 1:
         r += 1
      i /= 10
   return r

for line in sys.stdin:
   i = int(line)
   r = 0
   while i > 0:
      r += ones(i)
      i -= 1
   print r
