deploy: function.zip
	aws lambda update-function-code --function-name ProcessSQSRecord --zip-file fileb://function.zip

function.zip: ProcessSQSRecords.py
	cd venv/lib/python2.7/site-packages; zip -r9 ../../../../function.zip .
	zip -g function.zip ProcessSQSRecords.py

install: function.zip
	aws lambda create-function --function-name ProcessSQSRecord --zip-file fileb://function.zip --handler ProcessSQSRecords.lambda_handler --runtime python2.7 --role arn:aws:iam::471287585525:role/lambda-sqs-role
