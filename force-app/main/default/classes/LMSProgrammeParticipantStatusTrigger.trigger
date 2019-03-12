trigger LMSProgrammeParticipantStatusTrigger on Programme_Participant__c (after insert, after update) {
    if (system.isFuture()) {
        return;
    }
    
    Boolean Status_Changed = false;
    if (Trigger.isUpdate) {
        for (Id participantId : Trigger.newMap.keySet() ) {
            if (Trigger.oldMap.get( participantId ).Status__c != Trigger.newMap.get( participantId ).Status__c ) {
                Status_Changed = true;
            }
        }
    }
    
    if (Trigger.isInsert || Status_Changed) {
        LMS.onParticipantStatusChange(Trigger.newMap.keySet());
    }
}
