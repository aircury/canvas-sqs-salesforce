List<Programme_Participant__c> participants = [
    SELECT Id,
        Participant__c,
        Participant__r.Participant_UID__c,
        Participant__r.Email,
        Programme__r.Name,
        Programme__r.LMS_Course_Section_Id__c,
        Programme__r.LMS_Additional_Course_Section_Id_1__c,
        Programme__r.LMS_Additional_Course_Section_Id_2__c,
        Programme__r.LMS_Provision_Primary_Course__c
    FROM Programme_Participant__c
    WHERE Programme__r.LMS_Access__c = true AND
        Participant__r.Email != null AND
        (
            (Programme__r.LMS_Start_Date__c <= TODAY AND
            Programme__r.LMS_End_Date__c >= TODAY)
            OR
            (Temp_LMS_Start_Date__c <= TODAY AND
            Temp_LMS_End_Date__c >= TODAY)
        ) AND
        (Status__c = 'Active' OR Status__c = 'Inactive')
];

List<Programme_Participant__c> missingParticipants = new List<Programme_Participant__c>();
Integer i = 0, start = 0, maxIterations = 50;
Map <String, Object> apiResult;
Boolean fix = False;
String userId, sectionId, sisId, fS = ';';

// System.debug(LoggingLevel.INFO, 'Participants: ' + participants.size());

for (Programme_Participant__c participant: participants) {
    if (i < start) {
        i = i + 1;
        continue;
    }

    if (i >= (start+maxIterations)) {
        break;
    }

    if (Null == participant.Participant__c) {
        System.debug(LoggingLevel.INFO, 'Null Contact' + fS + participant.Programme__r.Name + fS + participant.Id);
        continue;
    }

    Contact c = participant.Participant__r;
    List <Object> apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);
    TL_Programme__c programme = participant.Programme__r;

    i = i + 1;

    if (apiResultList.size() > 0) {
        continue;
    }

    apiResultList = CanvasAPI.findUserByUID(c.Email);

    if (0 == apiResultList.size()) {
        continue;
    }

    if (apiResultList.size() > 1) {
        System.debug(LoggingLevel.INFO, 'Repeated email on Canvas' + fS + participant.Programme__r.Name + fS + c.Participant_UID__c + fS + c.Email);
        continue;
    }

    apiResult = (Map <String, Object>) apiResultList[0];

    sisId = String.valueOf(apiResult.get('sis_user_id'));

    if (c.Participant_UID__c != sisId) {
        System.debug(LoggingLevel.INFO, 'Participant UID doesnt match with Canvas SIS user id' + fS + participant.Programme__r.Name + fS + c.Participant_UID__c + fS + c.Email + fS + sisId);
    }

    if (fix) {
        missingParticipants.add(participant);
    }
}

if (missingParticipants.size() > 0) {
    LMSParticipantStatusChangeJob job = new LMSParticipantStatusChangeJob(missingParticipants, null);

    Database.executeBatch(job, job.batchSize());
}
