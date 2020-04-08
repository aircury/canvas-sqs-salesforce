global class LMSParticipantStatusChangeJob extends LMSAbstractJob {
    public LMSParticipantStatusChangeJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 8; //doParticipantStatusChange can do 12 callouts at max, so 12*8 = 96 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Participants Status Change Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doParticipantStatusChange(i);
    }
}