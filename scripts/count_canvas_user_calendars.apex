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

System.debug(LoggingLevel.INFO, 'Attendees: ' + attendees.size());
