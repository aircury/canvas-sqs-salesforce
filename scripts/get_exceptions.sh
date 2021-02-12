#!/bin/bash

output_dir=output/$(date +"%Y_%m_%d")

[ -d $output_dir ] || mkdir -p $output_dir

sfdx force:apex:execute --targetusername production -f get_exceptions.apex --loglevel INFO | tee $output_dir/get_exceptions.out | grep \|INFO\| | cut -d "|" -f 5
