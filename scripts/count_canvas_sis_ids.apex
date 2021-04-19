List<Programme_Participant__c> participants = [
    SELECT Id,
        Participant__r.Participant_UID__c,
        Participant__r.Email,
        Programme__r.Name,
        Programme__r.LMS_Course_Section_Id__c,
        Programme__r.LMS_Additional_Course_Section_Id_1__c,
        Programme__r.LMS_Additional_Course_Section_Id_2__c
    FROM Programme_Participant__c
];

System.debug(LoggingLevel.INFO, 'Participants: ' + participants.size());
