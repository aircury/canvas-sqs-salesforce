public with sharing class LMSEventInsertJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 25; //doEventInsert can do 4 callouts at max, so 25*4 = 100 <= 100 callout limit
    Set<Id> attendees;
    Queueable nextJob;

    public LMSEventInsertJob(Set<Id> a, Queueable j) {
        attendees = a;
        nextJob = j;
    }

    public void execute(QueueableContext context) {
        if (attendees.size() <= BATCH_SIZE) {
            LMS.doEventInsert(attendees);

            if (nextJob != null) {
                System.enqueueJob(nextJob);
            }

            return;
        }

        Set<Id> attendeesBatch = new Set<Id>();
    
        for (Id attendeeId: attendees) {
            attendeesBatch.add(attendeeId);
            if (attendeesBatch.size() == BATCH_SIZE) { 
                LMS.doEventInsert(attendeesBatch);
                break;
            }
        }

        attendees.removeAll(attendeesBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSEventInsertJob(attendees, nextJob));
        }
    }
}