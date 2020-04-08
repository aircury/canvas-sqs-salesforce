public with sharing class LMSPartNPQStatusChangeQueueableJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 16; //doParticipantNPQStatusChange can do 6 callouts at max, so 16*6 = 96 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;

    public LMSPartNPQStatusChangeQueueableJob(Set<Id> p, Queueable j) {
        participants = p;
        nextJob = j;
    }

    public void execute(QueueableContext context) {
        if (participants.size() <= BATCH_SIZE) {
            LMS.doParticipantNPQStatusChange(participants);

            if (nextJob != null) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(nextJob);
                }
            }

            return;
        }

        Set<Id> participantsBatch = new Set<Id>();
    
        for (Id participantId: participants) {
            participantsBatch.add(participantId);
            if (participantsBatch.size() == BATCH_SIZE) { 
                LMS.doParticipantNPQStatusChange(participantsBatch);
                break;
            }
        }

        participants.removeAll(participantsBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSPartNPQStatusChangeQueueableJob(participants, nextJob));
        }
    }
}