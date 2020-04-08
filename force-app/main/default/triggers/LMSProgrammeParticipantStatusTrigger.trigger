trigger LMSProgrammeParticipantStatusTrigger on Programme_Participant__c (after insert, after update) {
    List<SObject> participantsWithChangedName =  new List<SObject>();
    Boolean Status_Changed = false, NPQ_Status_Changed = false;
    LMSAbstractJob job;
    Queueable queueableJob;
    Date today = Date.today();

    if (Trigger.isUpdate) {
        for (Id participantId : Trigger.newMap.keySet() ) {
            Programme_Participant__c oldP = Trigger.oldMap.get(participantId), newP = Trigger.newMap.get(participantId);
            
            if (oldP.Status__c != newP.Status__c ) {
                Status_Changed = true;
            }

            if (oldP.Qualification__c == null && newP.Qualification__c != null &&
                newP.NPQ_Status__c != null &&
                newP.NPQ_Status__c != 'Deferral' &&
                newP.NPQ_Status__c != 'Withdrawn') {
                NPQ_Status_Changed = true;
            }

            if (oldP.ParticipantName__c != newP.ParticipantName__c) {
                participantsWithChangedName.add(newP);
            }
        }

        if (!NPQ_Status_Changed) {
            if (Status_Changed && participantsWithChangedName.size() > 0) {
                job = new LMSParticipantStatusChangeJob(Trigger.new, new LMSParticipantNameChangeJob(participantsWithChangedName, null));
            } else {
                if (participantsWithChangedName.size() > 0) {
                    job = new LMSParticipantNameChangeJob(participantsWithChangedName, null);
                }

                if (Status_Changed) {
                    job = new LMSParticipantStatusChangeJob(Trigger.new, null);
                    queueableJob = new LMSParticipantStatusChangeQueueableJob(Trigger.newMap.keySet(), null);
                }
            }
        } else {
            job = new LMSParticipantNPQStatusChangeJob(Trigger.new, null);
            queueableJob = new LMSPartNPQStatusChangeQueueableJob(Trigger.newMap.keySet(), null);

            if (Status_Changed && participantsWithChangedName.size() > 0) {
                job = new LMSParticipantStatusChangeJob(Trigger.new, new LMSParticipantNPQStatusChangeJob(Trigger.new, new LMSParticipantNameChangeJob(participantsWithChangedName, null)));
            } else {
                if (participantsWithChangedName.size() > 0) {
                    job = new LMSParticipantNPQStatusChangeJob(Trigger.new, new LMSParticipantNameChangeJob(participantsWithChangedName, null));
                }

                if (Status_Changed) {
                    job = new LMSParticipantStatusChangeJob(Trigger.new, new LMSParticipantNPQStatusChangeJob(Trigger.new, null));
                    queueableJob = new LMSParticipantStatusChangeQueueableJob(Trigger.newMap.keySet(), new LMSPartNPQStatusChangeQueueableJob(Trigger.newMap.keySet(), null));
                }
            }
        }
    }

    if (Trigger.isInsert) {
        for (Id participantId : Trigger.newMap.keySet() ) {
            Programme_Participant__c p = Trigger.newMap.get(participantId);

            if (p.Programme__r.LMS_Access__c == true &&
                p.Participant__r.Email != null &&
                (
                    (p.Programme__r.LMS_Start_Date__c <= today &&
                    p.Programme__r.LMS_End_Date__c >= today)
                    ||
                    (p.Temp_LMS_Start_Date__c <= today &&
                    p.Temp_LMS_End_Date__c >= today)
                )
            ) {
                if (p.Qualification__c != null &&
                    p.NPQ_Status__c != null &&
                    p.NPQ_Status__c != 'Deferral' &&
                    p.NPQ_Status__c != 'Withdrawn')
                {
                    NPQ_Status_Changed = true;
                }

                Status_Changed = true;
            }
        }

        if (!NPQ_Status_Changed) {
            if (Status_Changed) {
                job = new LMSParticipantStatusChangeJob(Trigger.new, null);
                queueableJob = new LMSParticipantStatusChangeQueueableJob(Trigger.newMap.keySet(), null);
            }
        } else {
            job = new LMSParticipantNPQStatusChangeJob(Trigger.new, null);
            queueableJob = new LMSPartNPQStatusChangeQueueableJob(Trigger.newMap.keySet(), null);

            if (Status_Changed) {
                job = new LMSParticipantStatusChangeJob(Trigger.new, new LMSParticipantNPQStatusChangeJob(Trigger.new, null));
                queueableJob = new LMSParticipantStatusChangeQueueableJob(Trigger.newMap.keySet(), new LMSPartNPQStatusChangeQueueableJob(Trigger.newMap.keySet(), null));
            }
        }
    }

    if (system.isBatch() || system.isFuture()) {
        if (queueableJob != null) {
            System.enqueueJob(queueableJob);
        }
    } else {
        if (job != null) {
            Database.executeBatch(job, job.batchSize());
        }
    }
}