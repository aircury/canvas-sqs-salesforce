public with sharing class LMSPartNPQStatusChangeQueueableJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 16; //doParticipantNPQStatusChange can do 6 callouts at max, so 16*6 = 96 <= 100 callout limit
    Set<Id> participants;
    Queueable nextJob;
    private final List<String> errors;
    private final Integer totalParticipants;

    public LMSPartNPQStatusChangeQueueableJob(Set<Id> p, Queueable j, List<String> e, Integer t) {
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
            errors.addAll(LMS.doParticipantNPQStatusChange(participants));

            if (nextJob != null) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(nextJob);
                }
            }
            
            if (errors.size() > 0 || Test.isRunningTest()) {
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

            if (!Test.isRunningTest()) {
                return;
            }
        }
        
        Set<Id> participantsBatch = new Set<Id>();
    
        for (Id participantId: participants) {
            participantsBatch.add(participantId);
            if (participantsBatch.size() == BATCH_SIZE) { 
                errors.addAll(LMS.doParticipantNPQStatusChange(participantsBatch));
                break;
            }
        }

        participants.removeAll(participantsBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSPartNPQStatusChangeQueueableJob(participants, nextJob, errors, totalParticipants));
        }
    }
}