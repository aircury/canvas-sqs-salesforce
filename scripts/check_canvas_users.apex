List<Programme_Participant__c> participants = [
    SELECT Id,
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
Integer i = 0, start = 0, maxIterations = 100;
Map <String, Object> apiResult;
Boolean fix = True;
String userId, sectionId, sisId;

// System.debug(LoggingLevel.INFO, 'Participants: ' + participants.size());

for (Programme_Participant__c participant: participants) {
    if (i < start) {
        i = i + 1;
        continue;
    }

    if (i >= (start+maxIterations)) {
        break;
    }

    Contact c = participant.Participant__r;
    List <Object> apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);
    TL_Programme__c programme = participant.Programme__r;
    apiResult = (Map <String, Object>) apiResultList[0];
    userId = String.valueOf(apiResult.get('id'));

    i = i + 1;

    if (0 == apiResultList.size()) {
        System.debug(LoggingLevel.INFO, 'Non existent user: ' + participant.Programme__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email);

        apiResultList = CanvasAPI.findUserByUID(c.Email);

        if (0 == apiResultList.size()) {
            System.debug(LoggingLevel.INFO, 'Email not found on Canvas: ' + participant.Programme__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email);
            continue;
        }

        if (apiResultList.size() > 1) {
            System.debug(LoggingLevel.INFO, 'Repeated email on Canvas: ' + participant.Programme__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email);
            continue;
        }

        apiResult = (Map <String, Object>) apiResultList[0];

        sisId = String.valueOf(apiResult.get('sis_user_id'));

        if (c.Participant_UID__c != sisId) {
            System.debug(LoggingLevel.INFO, 'Participant UID doesnt match with Canvas SIS user id: ' + participant.Programme__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + sisId);
        }

        if (fix) {
            missingParticipants.add(participant);
        }

        continue;
    }

    for (Decimal sectionIdInt: new List<Decimal>{
        programme.LMS_Course_Section_Id__c,
        programme.LMS_Additional_Course_Section_Id_1__c,
        programme.LMS_Additional_Course_Section_Id_2__c
    }) {
        if (null == sectionIdInt ||
            (
                false == programme.LMS_Provision_Primary_Course__c &&
                sectionIdInt == programme.LMS_Course_Section_Id__c
            )
        ) {
            continue;
        }

        sectionId = String.valueOf(sectionIdInt);

        apiResultList = CanvasAPI.findEnrollmentId(userId, sectionId);

        if (0 == apiResultList.size()) {
            System.debug(LoggingLevel.INFO, 'Non existent enrollment: ' + participant.Programme__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + sectionId);

            if (fix) {
                missingParticipants.add(participant);
            }
        }
    }
}

if (missingParticipants.size() > 0) {
    LMSParticipantStatusChangeJob job = new LMSParticipantStatusChangeJob(missingParticipants, null);

    Database.executeBatch(job, job.batchSize());
}
