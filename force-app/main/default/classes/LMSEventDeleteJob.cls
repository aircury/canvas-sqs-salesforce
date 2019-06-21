public with sharing class LMSEventDeleteJob implements Queueable, Database.AllowsCallouts {
    static final Integer BATCH_SIZE = 25; //onEventInsert can do 4 callouts at max, so 25*4 = 100 <= 100 callout limit
    Set<Id> attendees;
    DateTime startAt, endAt;
    Queueable nextJob;

    public LMSEventDeleteJob(Set<Id> a, DateTime s, DateTime e, Queueable j) {
        attendees = a;
        startAt = s;
        endAt = e;
        nextJob = j;
    }

    public void execute(QueueableContext context) {
        if (attendees.size() <= BATCH_SIZE) {
            LMS.doEventDelete(attendees, startAt, endAt);

            if (nextJob != null) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(nextJob);
                }
            }

            return;
        }

        Set<Id> attendeesBatch = new Set<Id>();
    
        for (Id attendeeId: attendees) {
            attendeesBatch.add(attendeeId);
            if (attendeesBatch.size() == BATCH_SIZE) { 
                LMS.doEventDelete(attendeesBatch, startAt, endAt);
                break;
            }
        }

        attendees.removeAll(attendeesBatch);

        if (!Test.isRunningTest()) {
            System.enqueueJob(new LMSEventDeleteJob(attendees, startAt, endAt, nextJob));
        }
    }
}