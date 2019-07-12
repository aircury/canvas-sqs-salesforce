public with sharing class LMSParticipantStatusChangeJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 16; //doParticipantStatusChange can do 6 callouts at max, so 16*6 = 96 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;

    public LMSParticipantStatusChangeJob(Set<Id> p, Queueable j) {
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
            System.enqueueJob(new LMSParticipantStatusChangeJob(participants, nextJob));
        }
    }
}