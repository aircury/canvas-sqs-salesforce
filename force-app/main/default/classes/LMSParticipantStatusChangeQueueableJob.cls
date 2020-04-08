public with sharing class LMSParticipantStatusChangeQueueableJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 8; //doParticipantStatusChange can do 12 callouts at max, so 12*8 = 96 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;

    public LMSParticipantStatusChangeQueueableJob(Set<Id> p, Queueable j) {
        participants = p;
        nextJob = j;
    }

    public void execute(QueueableContext context) {
        if (participants.size() <= BATCH_SIZE) {
            LMS.doParticipantStatusChange(participants);

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
                LMS.doParticipantStatusChange(participantsBatch);
                break;
            }
        }

        participants.removeAll(participantsBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSParticipantStatusChangeQueueableJob(participants, nextJob));
        }
    }
}