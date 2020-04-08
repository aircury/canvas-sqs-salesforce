global class LMSRemoveUsersJob extends LMSAbstractJob {
    public LMSRemoveUsersJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 7; //doRemoveUsers can do 13 callouts at max, so 7*13 = 91 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Remove Canvas Users Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doRemoveUsers(i);
    }
}