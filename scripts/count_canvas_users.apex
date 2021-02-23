List<Programme_Participant__c> participants = [
    SELECT Id,
        Participant__r.Participant_UID__c,
        Participant__r.Email,
        Programme__r.Name,
        Programme__r.LMS_Course_Section_Id__c,
        Programme__r.LMS_Additional_Course_Section_Id_1__c,
        Programme__r.LMS_Additional_Course_Section_Id_2__c
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
        (Status__c = 'Active' OR Status__c = 'Inactive') AND
        Programme__r.LMS_Provision_Primary_Course__c = true
];

System.debug(LoggingLevel.INFO, 'Participants: ' + participants.size());
