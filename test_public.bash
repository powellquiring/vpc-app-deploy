#!/bin/bash

bootstrapfile=noindex/css/bootstrap.min.css
public_ip=$(terraform output ip)
expecting=INTERNET
elapsed=0
total=600
while (( 600 > $elapsed)); do
    contents=$(curl -s $public_ip)
    if [ "x$contents" = x$expecting ]; then
      echo success: httpd default correctly replaced, the computer has access to the internet
      hi=$(curl -s $public_ip/$bootstrapfile)
      if [ "x$hi" = xhi ]; then
        echo success: terraform provision works
        exit 0
      else
        echo $hi
        echo "fail: terraform provision does not work, expecting 'hi' but got the stuff above intead"
        exit 2
      fi
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
