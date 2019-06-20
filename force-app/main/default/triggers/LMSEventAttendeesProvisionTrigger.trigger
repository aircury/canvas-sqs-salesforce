trigger LMSEventAttendeesProvisionTrigger on Attendees__c (after insert, before delete) {
    if (system.isFuture()) {
        return;
    }
    
    if (Trigger.isInsert) {
        LMS.onEventInsert(Trigger.newMap.keySet());
    }

    if (Trigger.isDelete) {
        LMS.onEventDelete(Trigger.oldMap.keySet(), null, null);
    }
}