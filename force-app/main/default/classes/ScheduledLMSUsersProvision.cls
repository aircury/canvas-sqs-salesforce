global class ScheduledLMSUsersProvision implements Schedulable{
    TL_Programme__c programme;
    Boolean endTask;

    public ScheduledLMSUsersProvision(TL_Programme__c p, Boolean endTask) {
        programme = p;
        endTask = endTask;
    }

    global void execute(SchedulableContext sc) {
        if (endTask) {
            LMS.usersRemoval(programme);
        } else {
            LMS.usersProvision(programme);
        }
    }
}
