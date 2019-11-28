global class LMSEventDeleteJob extends LMSAbstractJob {
    DateTime startAt, endAt;

    public LMSEventDeleteJob(List<sObject> i, DateTime s, DateTime e, LMSAbstractJob j) {
        super(i, j);
        startAt = s;
        endAt = e;
    }

    global override Integer batchSize() {
        return 25; //doEventDelete can do 4 callouts at max, so 25*4 = 100 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Canvas Calendar Events Delete Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doEventDelete(i, startAt, endAt);
    }
}