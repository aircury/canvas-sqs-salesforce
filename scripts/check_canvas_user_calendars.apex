List<Attendees__c> attendees = [
SELECT FLIP_Event__r.Cohort_lkp__r.Name,
    Contact__r.Email,
    Contact__r.Name,
    Contact__r.Participant_UID__c,
    FLIP_Event__r.Event_Date__c,
    FLIP_Event__r.Event_End_Date__c,
    FLIP_Event__r.Start_Time__c,
    FLIP_Event__r.End_Time__c,
    FLIP_Event__r.Event_Full_Name__c
FROM Attendees__c
WHERE 
    FLIP_Event__r.Cohort_lkp__r.LMS_Access__c = true AND
    FLIP_Event__r.Send_to_LMS__c = true AND
    FLIP_Event__r.Cohort_lkp__r.LMS_Start_Date__c <= TODAY AND
    FLIP_Event__r.Cohort_lkp__r.LMS_End_Date__c > TODAY AND
    FLIP_Event__r.Event_End_Date__c >= TODAY AND
    Contact__r.Email != null
];

List<Attendees__c> canvas_attendees = new List<Attendees__c>();
Integer i = 0, start = 99, maxIterations = 33;
List <Object> apiResultList;
Map <String, Object> apiResult;
String userId;

System.debug(LoggingLevel.INFO, 'Attendees: ' + attendees.size() + ' ' + String.valueOf(start) + '..' + String.valueOf(start+maxIterations));

for (Attendees__c attendee: attendees) {
    if (i < start) {
        i = i + 1;
        continue;
    }

    if (i >= ( start + maxIterations)) {
        break;
    }

    FLIP_Event__c event = attendee.FLIP_Event__r;
    Contact c = attendee.Contact__r;
    DateTime startAt = LMS.getEventDateTime(event.Event_Date__c, event.Start_Time__c);
    DateTime endAt = LMS.getEventDateTime(event.Event_End_Date__c, event.End_Time__c);
    
    apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);

    i = i + 1;

    if (0 == apiResultList.size()) {
        System.debug(LoggingLevel.INFO, 'Non existent user ' + start + '-' + (start+maxIterations) + ': ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Cohort_lkp__r.Name + ' ' + event.Event_Full_Name__c);
        continue;
    }

    apiResult = (Map <String, Object>) apiResultList[0];

    userId = String.valueOf(apiResult.get('id'));
    apiResultList = CanvasAPI.listUserEvents(userId, startAt, endAt);
    if (0 == apiResultList.size()) {
        System.debug(LoggingLevel.INFO, 'Non existent user calendar event ' + start + '-' + (start+maxIterations) + ': ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Cohort_lkp__r.Name + ' ' + event.Event_Full_Name__c);
    } else {
        Set<Object> eventNames = new Set<Object>();

        for (Object results: apiResultList) {
            apiResult = (Map <String, Object>) results;
            String eventId = String.valueOf(apiResult.get('id'));

            if (eventNames.contains(apiResult.get('title'))) {
                System.debug(LoggingLevel.INFO, 'User calendar event name duplicated ' + start + '-' + (start+maxIterations) + ': ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Cohort_lkp__r.Name + ' ' + event.Event_Name__c + ' ' + eventId);
                // CanvasAPI.removeUserEvent(userId, eventId);
            }

            if (apiResult.get('title') != event.Event_Name__c) {
                System.debug(LoggingLevel.INFO, 'User calendar event name (' + apiResult.get('title') + ') doesn\'t match ' + start + '-' + (start+maxIterations) + ': ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Cohort_lkp__r.Name + ' ' + event.Event_Name__c + ' ' + eventId);
            }

            eventNames.add(apiResult.get('title'));
        }
    }
}
