#!/bin/bash

for i in $(seq 0 33 1400); do
    sed -i s/start\ =.*,/start\ =\ $i,/ check_canvas_user_calendars.apex
    sfdx force:apex:execute -f check_canvas_user_calendars.apex --loglevel INFO | tee output/check_canvas_user_calendars.out.$i | grep \|INFO\|
done
