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
        payloads = json.loads(payload)['data']
        print(payload)
        for payload in payloads:
            try:
                login = payload['actor']['extensions']['com.instructure.canvas']
                # TODO: assert that sis_id is the parameter name sent by canvas
                uid = login['sis_id']
                # uid = '1114550'
                detail = 'Canvas User: ' + login['user_login']
                action = payload['action']
                date = payload['eventTime']
                time = payload['eventTime'][11:]
            except KeyError as e:
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

