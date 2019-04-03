from __future__ import print_function
from simple_salesforce import Salesforce, SalesforceLogin
from canvasapi import Canvas
from canvasapi.exceptions import Unauthorized

import os
import json


if __name__ == '__main__':
    from os.path import join, dirname
    from dotenv import load_dotenv

    load_dotenv(join(dirname(__file__), '.env'))


domain = os.environ.get('SALESFORCE_DOMAIN', 'test')

session_id, instance = SalesforceLogin(username=os.environ['SALESFORCE_USER'],
                                       password=os.environ['SALESFORCE_PASSWORD'],
                                       security_token=os.environ['SALESFORCE_SECURITY_TOKEN'],
                                       domain=domain)

sf = Salesforce(instance=instance, session_id=session_id, domain=domain)
canvas = Canvas(os.environ['CANVAS_URL'], os.environ['CANVAS_TOKEN'])


def lambda_handler(event, context):
    for record in event['Records']:
        payload = str(record["body"])
        payloads = json.loads(payload)['data']
        print(payload)
        for payload in payloads:
            try:
                login = payload['actor']['extensions']['com.instructure.canvas']
                uid = canvas.get_user(login['entity_id']).sis_user_id
                detail = 'Canvas User: ' + login['user_login']
                action = payload['action']
                date = payload['eventTime']
                time = payload['eventTime'][11:]
            except KeyError as e:
                continue
            except Unauthorized as e:
                continue
            
            participants = sf.query('''
                SELECT Id 
                FROM Programme_Participant__c
                WHERE Programme__r.LMS_Access__c = true AND
                    Programme__r.LMS_Start_Date__c <= TODAY AND
                    Programme__r.LMS_End_Date__c >= TODAY AND
                    Participant_UID__c = '%s'
            ''' % uid)

            if participants['totalSize'] <= 0:
                continue
            
            print(json.dumps(payload))
            for participant in participants['records']:
                sf.Canvas_Activitiy__c.create({
                        'Canvas_Activity__c': action,
                        'Canvas_Activity_Detail__c': detail,
                        'Date__c': date,
                        'Time__c': time,
                        'Programme_Participant__c': participant['Id']
                })


if __name__ == '__main__':
    fake_event = {'Records': [{'body': '{"data": [{"action": "Test action"}]}'}]}
    lambda_handler(fake_event, None)

