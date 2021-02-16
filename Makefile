apex_tests:
	sfdx force:apex:test:run -r human -c -w 6 -n LMSTest

apex_deploy:
	sfdx force:source:deploy --sourcepath force-app

production_deploy:
	sfdx force:source:deploy --targetusername production --checkonly -m ApexClass:LMS,ApexClass:LMSTest,ApexClass:CanvasAPI --testlevel RunSpecifiedTests -r LMSTest
