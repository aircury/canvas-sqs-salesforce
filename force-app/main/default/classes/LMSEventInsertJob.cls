global class LMSEventInsertJob extends LMSAbstractJob {
    public LMSEventInsertJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 20; //doEventInsert can do 5 callouts at max, so 20*5 = 100 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Canvas Calendar Events Insert Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doEventInsert(i);
    }
}