include .env
export

PYTHON_VERSION=3.7

deploy: function.zip
	aws lambda update-function-code --function-name $$LAMBDA_NAME --zip-file fileb://function.zip

venv/bin/python$(PYTHON_VERSION):
	virtualenv -p python$(PYTHON_VERSION) venv

venv/lib/python$(PYTHON_VERSION)/site-packages/simple_salesforce/__init__.py: venv/bin/python$(PYTHON_VERSION) requirements.txt
	./venv/bin/pip$(PYTHON_VERSION) install -r requirements.txt

function.zip: process_sqs_records.py canvas_live_events.py venv/lib/python$(PYTHON_VERSION)/site-packages/simple_salesforce/__init__.py
	cd venv/lib/python$(PYTHON_VERSION)/site-packages; zip -r9 ../../../../function.zip .
	zip -g function.zip process_sqs_records.py canvas_live_events.py

install: function.zip
	aws lambda create-function --function-name $$LAMBDA_NAME --zip-file \
	fileb://function.zip --handler process_sqs_records.lambda_handler --runtime python$(PYTHON_VERSION) \
	--role $$LAMBDA_ROLE --environment Variables={SALESFORCE_USER=$$SALESFORCE_USER,\
	SALESFORCE_PASSWORD=$$SALESFORCE_PASSWORD,SALESFORCE_SECURITY_TOKEN=$$SALESFORCE_SECURITY_TOKEN,\
	CANVAS_URL=$$CANVAS_URL,CANVAS_ACCOUNT=$$CANVAS_ACCOUNT,CANVAS_TOKEN=$$CANVAS_TOKEN}

uninstall:
	aws lambda delete-function --function-name $$LAMBDA_NAME

run: venv/lib/python$(PYTHON_VERSION)/site-packages/simple_salesforce/__init__.py
	venv/bin/python$(PYTHON_VERSION) process_sqs_records.py
