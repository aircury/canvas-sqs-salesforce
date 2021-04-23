#!/bin/bash -e

output_dir=output/$(date +"%Y_%m_%d")

[ -d $output_dir ] || mkdir -p $output_dir

participants=$(sfdx force:apex:execute --targetusername production -f count_canvas_users.apex --loglevel INFO | grep \|INFO\| | cut -d ":" -f 4)

for i in $(seq 0 33 $participants); do
    echo "Batch $i"
    sed -i s/start\ =.*,/start\ =\ $i,/ check_canvas_users.apex
    sfdx force:apex:execute --targetusername production -f check_canvas_users.apex --loglevel INFO | tee $output_dir/check_canvas_users.out.$i | grep \|INFO\| | cut -d "|" -f 5
    grep -q Error: $output_dir/check_canvas_users.out.$i && echo "Error in batch $i"
done

sed -i s/start\ =.*,/start\ =\ 0,/ check_canvas_users.apex
