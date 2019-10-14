#!/bin/bash

sfdx force:apex:execute -f check_canvas_courses.apex --loglevel INFO | tee output/check_canvas_courses.out | grep \|INFO\|
