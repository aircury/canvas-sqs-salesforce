#!/bin/bash

sfdx force:apex:execute --targetusername production -f check_canvas_courses.apex --loglevel INFO | tee output/check_canvas_courses.out | grep \|INFO\|
