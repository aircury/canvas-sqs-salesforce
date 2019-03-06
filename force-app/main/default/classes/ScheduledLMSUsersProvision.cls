global class ScheduledLMSUsersProvision implements Schedulable {
    global void execute(SchedulableContext sc) {
        Date today = Date.today();
        TL_Programme__c[] programmes = [
            SELECT Id,
                LMS_Start_Date__c,
                LMS_End_Date__c
            FROM TL_Programme__c
            WHERE LMS_Access__c = true AND
                (LMS_Start_Date__c = :today OR
                LMS_End_Date__c = :today)
        ];

        for (TL_Programme__c p: programmes) {
            if (p.LMS_Start_Date__c == today) {
                LMS.usersProvision(p);
            }
            if (p.LMS_End_Date__c == today) {
                LMS.usersRemoval(p);
            }
        }
    }
}
