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
    List<SObject> participantsWithChangedName =  new List<SObject>();
    Boolean Status_Changed = false;
    if (Trigger.isUpdate) {
        for (Id participantId : Trigger.newMap.keySet() ) {
            Programme_Participant__c oldP = Trigger.oldMap.get(participantId), newP = Trigger.newMap.get(participantId);
            if (oldP.Status__c != newP.Status__c ) {
                Status_Changed = true;
            }

            if (oldP.ParticipantName__c != newP.ParticipantName__c) {
                //LMS.onParticipantNameChange(participantId);
                participantsWithChangedName.add(newP);
            }
        }
    }

    if (Status_Changed && participantsWithChangedName.size() > 0) {
        LMSParticipantStatusChangeJob job = new LMSParticipantStatusChangeJob(Trigger.new, new LMSParticipantNameChangeJob(participantsWithChangedName, null));

        Database.executeBatch(job, job.batchSize());

        return;
    }

    if(participantsWithChangedName.size() > 0) {
        LMSParticipantNameChangeJob job = new LMSParticipantNameChangeJob(participantsWithChangedName, null);

        Database.executeBatch(job, job.batchSize());
    }
    
    if (Trigger.isInsert || Status_Changed) {
        LMSParticipantStatusChangeJob job = new LMSParticipantStatusChangeJob(Trigger.new, null);

        Database.executeBatch(job, job.batchSize());
    }
}