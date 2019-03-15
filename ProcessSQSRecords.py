from __future__ import print_function
from simple_salesforce import Salesforce, SalesforceLogin

import os
import json


domain = os.environ.get('SALESFORCE_DOMAIN', 'test')

session_id, instance = SalesforceLogin(username=os.environ['SALESFORCE_USER'],
                                       password=os.environ['SALESFORCE_PASSWORD'],
                                       security_token=os.environ['SALESFORCE_SECURITY_TOKEN'],
                                       domain=domain)

sf = Salesforce(instance=instance, session_id=session_id, domain=domain)


def lambda_handler(event, context):
    for record in event['Records']:
        payload = str(record["body"])
        payload = json.loads(payload)
        print(payload)
        sf.Canvas_Activitiy__c.create({'Canvas_Activity__c': payload['data'][0]['action']})


if __name__ == '__main__':
    fake_event = {'Records': [{'body': '{test: "Local test"}'}]}
    lambda_handler(fake_event, None)

