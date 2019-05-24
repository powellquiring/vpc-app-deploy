#!/bin/bash
bootstrapfile=noindex/css/bootstrap.min.css
public_ip=$(terraform output ip)
private_ip=$(terraform output private_ip)
expecting=ISOLATED
elapsed=0
total=600
while (( 600 > $elapsed)); do
		contents=$(ssh root@$public_ip curl -s $private_ip)
    if [ "x$contents" = x$expecting ]; then
      echo success: httpd default correctly replaced, the computer does not have access to the internet only the software from ibm mirrors has been installed
      exit 0
    else
      echo $contents
      echo 
      echo Fail, expected $expecting, but got the stuff shown above instead, will try again
      sleep 1
    fi

    # while loop end:
    sleep 10
    let "elapsed = $(date +%s) - $end"
    echo $elapsed of $total have elapsed, try again...
done
exit 1
