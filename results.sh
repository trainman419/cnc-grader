#!/bin/bash

#stty -echo
#echo -n "Password: "
#read PASS
#stty echo
#echo
PASS=crashncompile

echo "Completed sample problem:"
mysql -u crashncompile -p$PASS crashncompile -e 'select email from submissions join users on userid = users.id where problem = 0 and result = 1 group by email;'

echo 
echo "Attempted qualification problem"
mysql -u crashncompile -p$PASS crashncompile -e 'select email from submissions join users on userid = users.id where problem = 1 group by email;'

echo
echo "Passed qualification problem"
mysql -u crashncompile -p$PASS crashncompile -e 'select email from submissions join users on userid = users.id where problem = 1 and result = 1 group by email;'
