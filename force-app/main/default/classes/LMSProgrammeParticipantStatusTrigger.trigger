trigger LMSProgrammeParticipantStatusTrigger on Programme_Participant__c (after insert, after update) {
    if (system.isFuture()) {
        return;
    }
    
    Boolean Status_Changed = false;
    if (Trigger.isUpdate) {
        for (Id participantId : Trigger.newMap.keySet() ) {
            Programme_Participant__c oldP = Trigger.oldMap.get(participantId), newP =Trigger.newMap.get(participantId);
            if (oldP.Status__c != newP.Status__c ) {
                Status_Changed = true;
            }

            if (oldP.ParticipantName__c != newP.ParticipantName__c) {
                LMS.onParticipantNameChange(participantId);
            }
        }
    }
    
    if (Trigger.isInsert || Status_Changed) {
        LMS.onParticipantStatusChange(Trigger.newMap.keySet());
    }
}
