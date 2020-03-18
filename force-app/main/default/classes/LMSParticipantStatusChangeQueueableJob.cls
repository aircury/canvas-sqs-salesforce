public with sharing class LMSParticipantStatusChangeQueueableJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 8; //doParticipantStatusChange can do 12 callouts at max, so 12*8 = 96 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;
    private final List<String> errors;
    private final Integer totalParticipants;

    public LMSParticipantStatusChangeQueueableJob(Set<Id> p, Queueable j, List<String> e, Integer t) {
        participants = p;
        nextJob = j;
        errors = e;
        if (null == errors) {
            errors = new List<String>();
        }
        totalParticipants = t;
    }

    public void execute(QueueableContext context) {
        if (participants.size() <= BATCH_SIZE) {
            errors.addAll(LMS.doParticipantStatusChange(participants));

            if (nextJob != null) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(nextJob);
                }
            }

            if (errors.size() > 0) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {UserInfo.getUserEmail()};
                
                mail.setToAddresses(toAddresses);
                mail.setSubject('Queueable Participant Status Change job finished with errors');
                String body = 'The queable Apex job processed ' + totalParticipants.format() +
                ' participants with ' + errors.size().format() + ' failures.\n\nThe next errors were recorded:\n\n';
    
                for (String error: errors) {
                    body = body + error + '\n';
                }
    
                mail.setPlainTextBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }

            return;
        }

        Set<Id> participantsBatch = new Set<Id>();
    
        for (Id participantId: participants) {
            participantsBatch.add(participantId);
            if (participantsBatch.size() == BATCH_SIZE) { 
                errors.addAll(LMS.doParticipantStatusChange(participantsBatch));
                break;
            }
        }

        participants.removeAll(participantsBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSParticipantStatusChangeQueueableJob(participants, nextJob, errors, totalParticipants));
        }
    }
}