List<Programme_Participant__c> participants = [
    SELECT Id
    FROM Programme_Participant__c
    WHERE Programme__r.LMS_Access__c = true AND
    Participant__r.Email != null AND
    Programme__r.LMS_Start_Date__c <= TODAY AND
    Programme__r.LMS_End_Date__c >= TODAY AND
    (Status__c = 'Active' OR Status__c = 'Inactive')
];

System.debug(LoggingLevel.INFO, 'Participants: ' + participants.size());
