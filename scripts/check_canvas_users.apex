List<Programme_Participant__c> participants = [
    SELECT Id, Participant__r.Participant_UID__c, Participant__r.Email, Programme__r.Name
    FROM Programme_Participant__c
    WHERE Programme__r.LMS_Access__c = true AND
        Participant__r.Email != null AND
        (
            (Programme__r.LMS_Start_Date__c <= TODAY AND
            Programme__r.LMS_End_Date__c >= TODAY)
            OR
            (Temp_LMS_Start_Date__c <= TODAY AND
            Temp_LMS_End_Date__c >= TODAY)
        )
        (Status__c = 'Active' OR Status__c = 'Inactive')
];

List<Programme_Participant__c> missingParticipants = new List<Programme_Participant__c>();
Integer i = 0, start = 2000, maxIterations = 100;
Map <String, Object> apiResult;
String userId, sectionId;

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
        missingParticipants.add(participant);
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

        List <Object> apiResultList = CanvasAPI.findEnrollmentId(userId, courseSectionId);

        if (0 == apiResultList.size()) {
            System.debug(LoggingLevel.INFO, 'Non existent enrollment: ' + participant.Programme__r.Name + ' ' + c.Participant_UID__c + ' ' + c.Email + ' ' + sectionId);
        }
    }
}

if (missingParticipants.size() > 0) {
    LMSParticipantStatusChangeJob job = new LMSParticipantStatusChangeJob(missingParticipants, null);

    Database.executeBatch(job, job.batchSize());
}
