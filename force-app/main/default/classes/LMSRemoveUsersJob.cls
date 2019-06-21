public with sharing class LMSRemoveUsersJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 25; //onRemoveUsers can do 4 callouts at max, so 25*4 = 100 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;

    public LMSRemoveUsersJob(Set<Id> p, Queueable j) {
        participants = p;
        nextJob = j;
    }

    public void execute(QueueableContext context) {
        if (participants.size() <= BATCH_SIZE) {
            LMS.doRemoveUsers(participants);

            if (nextJob != null) {
                System.enqueueJob(nextJob);
            }

            return;
        }

        Set<Id> participantsBatch = new Set<Id>();
    
        for (Id participantId: participants) {
            participantsBatch.add(participantId);
            if (participantsBatch.size() == BATCH_SIZE) { 
                LMS.doRemoveUsers(participantsBatch);
                break;
            }
        }

        participants.removeAll(participantsBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSRemoveUsersJob(participants, nextJob));
        }
    }
}