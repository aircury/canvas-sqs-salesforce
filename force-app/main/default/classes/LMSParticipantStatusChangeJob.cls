global class LMSParticipantStatusChangeJob extends LMSAbstractJob {
    public LMSParticipantStatusChangeJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 16; //doParticipantStatusChange can do 6 callouts at max, so 16*6 = 96 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Participants Status Change Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doParticipantStatusChange(i);
    }
}