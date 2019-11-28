global class LMSParticipantNameChangeJob extends LMSAbstractJob {
    public LMSParticipantNameChangeJob(List<sObject> i, LMSAbstractJob j) {
        super(i, j);
    }

    global override Integer batchSize() {
        return 33; //onParticipantStatusChange can do 3 callouts at max, so 33*3 = 99 <= 100 callout limit
    }
    global override String emailSubject() {
        return 'Participants Name Change Job ';
    }

    global override List<String> doExecute(Set<Id> i) {
        return LMS.doParticipantNameChange(i);
    }
}