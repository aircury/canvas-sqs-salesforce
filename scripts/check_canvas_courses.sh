#!/bin/bash -e

output_dir=output/$(date +"%Y_%m_%d")

[ -d $output_dir ] || mkdir -p $output_dir

sfdx force:apex:execute --targetusername production -f check_canvas_courses.apex --loglevel INFO | tee $output_dir/check_canvas_courses.out | grep \|INFO\| | cut -d "|" -f 5
