#!/bin/bash

output_dir=output/$(date +"%Y_%m_%d")

[ -d $output_dir ] || mkdir -p $output_dir

./check_canvas_courses.sh | tee $output_dir/checks.log
./check_canvas_users.sh | tee -a $output_dir/checks.log
./check_canvas_user_calendars.sh | tee -a $output_dir/checks.log
./get_exceptions.sh | tee $output_dir/exceptions.log
