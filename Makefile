deploy: function.zip
	aws lambda update-function-code --function-name ProcessSQSRecord --zip-file fileb://function.zip

function.zip: ProcessSQSRecords.py
	cd venv/lib/python2.7/site-packages; zip -r9 ../../../../function.zip .
	zip -g function.zip ProcessSQSRecords.py
