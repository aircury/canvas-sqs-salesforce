deploy: function.zip
	aws lambda update-function-code --function-name ProcessSQSRecord --zip-file fileb://function.zip

venv/bin/python2:
	virtualenv venv

venv/lib/python2.7/site-packages/simple_salesforce/__init__.py: venv/bin/python2 requirements.txt
	./venv/bin/pip install -r requirements.txt

function.zip: ProcessSQSRecords.py venv/lib/python2.7/site-packages/simple_salesforce/__init__.py
	cd venv/lib/python2.7/site-packages; zip -r9 ../../../../function.zip .
	zip -g function.zip ProcessSQSRecords.py

install: function.zip
	aws lambda create-function --function-name ProcessSQSRecord --zip-file fileb://function.zip --handler ProcessSQSRecords.lambda_handler --runtime python2.7 --role arn:aws:iam::621064655579:role/lambda-sqs-role

run: venv/lib/python2.7/site-packages/simple_salesforce/__init__.py
	venv/bin/python2 ProcessSQSRecords.py

apex_tests:
	sfdx force:apex:test:run -r human -c -w 6 -n LMSTest

apex_deploy:
	sfdx force:source:deploy --sourcepath force-app

