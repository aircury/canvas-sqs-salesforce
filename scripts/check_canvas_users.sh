#!/bin/bash

for i in $(seq 0 100 1300); do
    sed -i s/start\ =.*,/start\ =\ $i,/ check_canvas_users.apex
    sfdx force:apex:execute -f check_canvas_users.apex --loglevel WARN | tee output/check_canvas_users.out.$i | grep WARN\|
done
