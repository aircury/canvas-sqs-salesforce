global class LMSParticipantNPQStatusChangeJob extends LMSAbstractJob {
    public LMSParticipantNPQStatusChangeJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 16; //doParticipantNPQStatusChange can do 6 callouts at max, so 16*6 = 96 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Participants NPQ Status Change Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doParticipantNPQStatusChange(i);
    }
}