include .env
export

deploy: function.zip
	aws lambda update-function-code --function-name $$LAMBDA_NAME --zip-file fileb://function.zip

venv/bin/python2:
	virtualenv venv

venv/lib/python2.7/site-packages/simple_salesforce/__init__.py: venv/bin/python2 requirements.txt
	./venv/bin/pip install -r requirements.txt

function.zip: ProcessSQSRecords.py venv/lib/python2.7/site-packages/simple_salesforce/__init__.py
	cd venv/lib/python2.7/site-packages; zip -r9 ../../../../function.zip .
	zip -g function.zip ProcessSQSRecords.py

install: function.zip
	aws lambda create-function --function-name $$LAMBDA_NAME --zip-file \
	fileb://function.zip --handler ProcessSQSRecords.lambda_handler --runtime python2.7 \
	--role $$LAMBDA_ROLE --environment Variables={SALESFORCE_USER=$$SALESFORCE_USER,\
	SALESFORCE_PASSWORD=$$SALESFORCE_PASSWORD,SALESFORCE_SECURITY_TOKEN=$$SALESFORCE_SECURITY_TOKEN,\
	CANVAS_URL=$$CANVAS_URL,CANVAS_ACCOUNT=$$CANVAS_ACCOUNT,CANVAS_TOKEN=$$CANVAS_TOKEN}

uninstall:
	aws lambda delete-function --function-name ProcessSQSRecord

run: venv/lib/python2.7/site-packages/simple_salesforce/__init__.py
	venv/bin/python2 ProcessSQSRecords.py
