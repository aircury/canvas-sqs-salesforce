/*
 * >>- Changelog -<<
 * Date           Developer   Comment
 * 19-06-2019     Ekta        Updated to collect participantId in a set participantIdsWithChangedNameSet
 *                            and call LMS.onParticipantNameChange(-) method
 * 	
 * 	 
*/ 
trigger LMSProgrammeParticipantStatusTrigger on Programme_Participant__c (after insert, after update) {
    if (system.isFuture()) {
        return;
    }
    Set<Id> participantIdsWithChangedNameSet =  new Set<Id>();
    Boolean Status_Changed = false;
    if (Trigger.isUpdate) {
        for (Id participantId : Trigger.newMap.keySet() ) {
            Programme_Participant__c oldP = Trigger.oldMap.get(participantId), newP =Trigger.newMap.get(participantId);
            if (oldP.Status__c != newP.Status__c ) {
                Status_Changed = true;
            }

            if (oldP.ParticipantName__c != newP.ParticipantName__c) {
                //LMS.onParticipantNameChange(participantId);
                participantIdsWithChangedNameSet.add(participantId);
            }
        }
    }
    
    if(participantIdsWithChangedNameSet.size() > 0) {
        LMS.onParticipantNameChange(participantIdsWithChangedNameSet);
    }
    
    if (Trigger.isInsert || Status_Changed) {
        System.enqueueJob(new LMSParticipantStatusChangeJob(Trigger.newMap.keySet(), null));
    }
}