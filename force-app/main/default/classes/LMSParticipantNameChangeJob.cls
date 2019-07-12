public with sharing class LMSParticipantNameChangeJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 33; //onParticipantStatusChange can do 3 callouts at max, so 33*3 = 99 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;

    public LMSParticipantNameChangeJob(Set<Id> p, Queueable j) {
        participants = p;
        nextJob = j;
    }

    public void execute(QueueableContext context) {
        if (participants.size() <= BATCH_SIZE) {
            LMS.doParticipantNameChange(participants);

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
                LMS.doParticipantNameChange(participantsBatch);
                break;
            }
        }

        participants.removeAll(participantsBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSParticipantNameChangeJob(participants, nextJob));
        }
    }
}