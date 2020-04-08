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
                LMS.removeUsers(p);
            }
        }

        List<Programme_Participant__c> participants = [
            SELECT Id
            FROM Programme_Participant__c
            WHERE Programme__r.LMS_Access__c = true AND
                Participant__r.Email != null AND
                Temp_LMS_Start_Date__c = :today
        ];

        if (0 != participants.size()) {
            LMSParticipantStatusChangeJob job = new LMSParticipantStatusChangeJob(participants, null);
            
            Database.executeBatch(job, job.batchSize());
        }

        participants = [
            SELECT Id
            FROM Programme_Participant__c
            WHERE Programme__r.LMS_Access__c = true AND
                Participant__r.Email != null AND
                Temp_LMS_End_Date__c = :today
        ];

        if (0 != participants.size()) {
            LMSRemoveUsersJob job = new LMSRemoveUsersJob(participants, null);
            
            Database.executeBatch(job, job.batchSize());
        }
    }
}