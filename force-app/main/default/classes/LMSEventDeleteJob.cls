global class LMSEventDeleteJob extends LMSAbstractJob {
    DateTime startAt, endAt;
    String eventName;

    public LMSEventDeleteJob(List<sObject> i, DateTime s, DateTime e, String n, LMSAbstractJob j) {
        super(i, j);
        startAt = s;
        endAt = e;
        eventName = n;
    }

    global override Integer batchSize() {
        return 25; //doEventDelete can do 4 callouts at max, so 25*4 = 100 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Canvas Calendar Events Delete Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doEventDelete(i, startAt, endAt, eventName);
    }
}