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
#mysql -u crashncompile -p$PASS crashncompile -e 'select email from submissions join users on userid = users.id where problem = 1 group by email;'
mysql -u crashncompile -p$PASS crashncompile -e 'select email, start from users where start is not null order by email;' | perl -p -e 's/(\d{10})/localtime($1)/ge'
date

echo
echo "Passed qualification problem"
mysql -u crashncompile -p$PASS crashncompile -e 'select email, submissions.time - users.start from submissions join users on userid = users.id where problem = 1 and result = 1 group by email;'
