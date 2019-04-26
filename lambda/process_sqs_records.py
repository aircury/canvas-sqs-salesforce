from __future__ import print_function
from simple_salesforce import Salesforce, SalesforceLogin

import os
import json
import logging
import canvas_live_events

if __name__ == '__main__':
    from os.path import join, dirname
    from dotenv import load_dotenv

    load_dotenv(join(dirname(__file__), '.env'))


logging.getLogger().setLevel(os.environ.get('LOG_LEVEL', 'DEBUG'))
domain = os.environ.get('SALESFORCE_DOMAIN', 'test')

session_id, instance = SalesforceLogin(username=os.environ['SALESFORCE_USER'],
                                       password=os.environ['SALESFORCE_PASSWORD'],
                                       security_token=os.environ['SALESFORCE_SECURITY_TOKEN'],
                                       domain=domain)

sf = Salesforce(instance=instance, session_id=session_id, domain=domain)


def complete_details(detail, participant, date):
    return detail.replace('<participant>', participant).replace('<date>', date[:10])

def lambda_handler(event, context):
    for record in event['Records']:
        payload = str(record["body"])
        payloads = json.loads(payload)['data']
        logging.debug(payload)
        for payload in payloads:
            try:
                actor = payload['actor']
                typev = payload['type']
                action = payload['action']
                objectv = payload['object']
                object_type = objectv['type']
                group = payload.get('group', {})
                date = payload['eventTime']
                time = payload['eventTime'][11:]
                liveEvent = canvas_live_events.EVENT_MAP[typev][action][object_type]
            except Exception as e:
                logging.error('Error mapping live event:\n%s' % str(e))
                logging.error(payload)
                continue
            
            try:
                uid, course_id, detail, activity, event_name = getattr(canvas_live_events, 'process_' + liveEvent)(actor, objectv, group)
                logging.debug(detail)
            except AttributeError as e:
                logging.warning('process_%s not implemented yet' % liveEvent)
                logging.warning(payload)
                continue
            except Exception as e:
                logging.error('Error processing %s:\n%s' % (liveEvent, str(e)))
                logging.error(payload)
                continue

            query = '''
                SELECT Id,
                    ParticipantName__c
                FROM Programme_Participant__c
                WHERE Programme__r.LMS_Access__c = true AND
                    Programme__r.LMS_Start_Date__c <= TODAY AND
                    Programme__r.LMS_End_Date__c > TODAY AND
                    Participant_UID__c = '%s'
            '''

            if course_id:
                query += "AND Programme__r.LMS_Course_Id__c = %s" % course_id
            
            participants = sf.query(query % uid)

            if participants['totalSize'] <= 0:
                continue
            
            for participant in participants['records']:
                detail = complete_details(detail, participant['ParticipantName__c'], date)
                sf.Canvas_Activitiy__c.create({
                        'Canvas_Activity__c': activity,
                        'Canvas_Activity_Detail__c': detail,
                        'Date__c': date,
                        'Time__c': time,
                        'Programme_Participant__c': participant['Id']
                })

            if not event_name:
                continue
            
            query = '''
                SELECT Id
                FROM Attendees__c
                WHERE Contact__r.Participant_UID__c = '%s' AND
                    FLIP_Event__r.Cohort_lkp__r.LMS_Access__c = true AND
                    FLIP_Event__r.Send_to_LMS__c = true AND
                    FLIP_Event__r.Cohort_lkp__r.LMS_Start_Date__c <= TODAY AND
                    FLIP_Event__r.Cohort_lkp__r.LMS_End_Date__c > TODAY AND
                    Contact__r.Email != null AND
                    FLIP_Event__r.Event_Name__c = '%s'
            '''

            attendees = sf.query(query % (uid, event_name))

            if attendees['totalSize'] <= 0:
                continue
            
            for attendee in attendees['records']:
                sf.Attendees__c.update(attendee['Id'], {'Event_Attended__c': True})

if __name__ == '__main__':
    with open('event_samples/quiz_submitted.json') as f:
        fake_event = {'Records': [{'body': '{"data": %s}' % f.read()}]}
        lambda_handler(fake_event, None)

