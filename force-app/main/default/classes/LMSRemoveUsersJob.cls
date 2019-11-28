global class LMSRemoveUsersJob extends LMSAbstractJob {
    public LMSRemoveUsersJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 25; //doRemoveUsers can do 4 callouts at max, so 25*4 = 100 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Remove Canvas Users Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doRemoveUsers(i);
    }
}