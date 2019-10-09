#!/bin/bash

for i in $(seq 0 50 1800); do
    sed -i s/start\ =.*,/start\ =\ $i,/ check_canvas_user_calendars.apex
    sfdx force:apex:execute -f check_canvas_user_calendars.apex --loglevel WARN | tee output/check_canvas_user_calendars.out.$i | grep WARN\|
done
