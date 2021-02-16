List<Attendees__c> attendees = [
SELECT
    Id,
    FLIP_Event__r.Cohort_lkp__r.Name,
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
    FLIP_Event__r.Cohort_lkp__r.LMS_Provision_Primary_Course__c = true AND
    FLIP_Event__r.Send_to_LMS__c = true AND
    FLIP_Event__r.Cohort_lkp__r.LMS_Start_Date__c <= TODAY AND
    FLIP_Event__r.Cohort_lkp__r.LMS_End_Date__c > TODAY AND
    FLIP_Event__r.Event_End_Date__c >= TODAY AND
    Contact__r.Email != null
];

List<Attendees__c> attendeesWithMissingEvents = new List<Attendees__c>();
Integer i = 0, start = 0, maxIterations = 33;
List <Object> apiResultList;
Map <String, Object> apiResult;
Boolean fix = True;
String userId, sisId;

// System.debug(LoggingLevel.INFO, 'Attendees: ' + attendees.size() + ' ' + String.valueOf(start) + '..' + String.valueOf(start+maxIterations));

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
        System.debug(LoggingLevel.INFO, 'Non existent attendee: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Event_Full_Name__c);

        apiResultList = CanvasAPI.findUserByUID(c.Email);

        if (0 == apiResultList.size()) {
            System.debug(LoggingLevel.INFO, 'Email not found on Canvas: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email);
            continue;
        }

        if (apiResultList.size() > 1) {
            System.debug(LoggingLevel.INFO, 'Repeated email on Canvas: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email);
            continue;
        }

        apiResult = (Map <String, Object>) apiResultList[0];

        sisId = String.valueOf(apiResult.get('sis_user_id'));
        userId = String.valueOf(apiResult.get('id'));

        if (c.Participant_UID__c != sisId) {
            System.debug(LoggingLevel.INFO, 'Participant UID doesn\'t match with Canvas SIS user id: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + sisId);

            if (fix) {
                CanvasAPI.listUserLoginsByUserId(userId);
                apiResultList = CanvasAPI.listUserLoginsByUserId(userId);

                for (Object result: apiResultList) {
                    Map <String, Object> apiResult = (Map <String, Object>) result;
                    if (c.Email == String.valueOf(apiResult.get('unique_id'))) {
                        CanvasAPI.editUserSISId(String.valueOf(apiResult.get('id')), c.Participant_UID__c);
                    }
                }
            }
        }

        if (fix) {
            attendeesWithMissingEvents.add(attendee);
        }

        continue;
    }

    apiResult = (Map <String, Object>) apiResultList[0];

    userId = String.valueOf(apiResult.get('id'));
    apiResultList = CanvasAPI.listUserEvents(userId, startAt, endAt);
    if (0 == apiResultList.size()) {
        System.debug(LoggingLevel.INFO, 'Non existent user calendar event: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Event_Full_Name__c);

        if (fix) {
            attendeesWithMissingEvents.add(attendee);
        }
    } else {
        Set<Object> eventNames = new Set<Object>();

        for (Object results: apiResultList) {
            apiResult = (Map <String, Object>) results;
            String eventId = String.valueOf(apiResult.get('id'));

            if (eventNames.contains(apiResult.get('title'))) {
                System.debug(LoggingLevel.INFO, 'User calendar event name duplicated: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Event_Full_Name__c + ' ' + eventId);

                if (fix) {
                    CanvasAPI.removeUserEvent(userId, eventId);
                }
            }

            if (apiResult.get('title') != event.Event_Full_Name__c) {
                System.debug(LoggingLevel.INFO, 'User calendar event name (' + apiResult.get('title') + ') doesn\'t match: ' + event.Cohort_lkp__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + event.Event_Full_Name__c + ' ' + eventId);

                if (fix) {
                    CanvasAPI.removeUserEvent(userId, eventId);
                    attendeesWithMissingEvents.add(attendee);
                }
            }

            eventNames.add(apiResult.get('title'));
        }
    }
}

if (attendeesWithMissingEvents.size() > 0) {
    LMSEventInsertJob job = new LMSEventInsertJob(attendeesWithMissingEvents, null);

    Database.executeBatch(job, job.batchSize());
}
