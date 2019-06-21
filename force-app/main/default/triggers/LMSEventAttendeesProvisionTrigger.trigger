trigger LMSEventAttendeesProvisionTrigger on Attendees__c (after insert, before delete) {
    if (system.isFuture()) {
        return;
    }
    
    if (Trigger.isInsert) {
         System.enqueueJob(new LMSEventInsertJob(Trigger.newMap.keySet(), null));
    }

    if (Trigger.isDelete) {
        System.enqueueJob(new LMSEventDeleteJob(Trigger.oldMap.keySet(), null, null, null));
    }
}