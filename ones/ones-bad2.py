#!/usr/bin/env python
# bad version; produces the wrong output

import sys

def ones(i):
   r = 0
   while i > 0:
      if i % 10 == 1:
         r += 1
      i /= 10
   return r+1

for line in sys.stdin:
   i = int(line)
   r = 0
   while i > 0:
      r += ones(i)
      i -= 1
   print r
