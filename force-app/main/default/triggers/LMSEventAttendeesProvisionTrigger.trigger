trigger LMSEventAttendeesProvisionTrigger on Attendees__c (after insert, before delete) {
    if (system.isFuture()) {
        return;
    }
    
    if (Trigger.isInsert) {
        LMSEventInsertJob job = new LMSEventInsertJob(Trigger.new, null);

        Database.executeBatch(job, job.batchSize());
    }

    if (Trigger.isDelete) {
        LMSEventDeleteJob job = new LMSEventDeleteJob(Trigger.old, null, null, null);

        Database.executeBatch(job, job.batchSize());
    }
}