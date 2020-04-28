trigger LMSAssessmentSubmissionTrigger on Assessment_Submission__c (after insert, after update) {
    Map<Id, String> participantIds = new Map<Id, String>();
    List<Programme_Participant__c> participants;
    
    if (Trigger.isInsert) {
        for (Assessment_Submission__c a: Trigger.new) {
            if (null != a.Submission_Date__c && a.Participant_NPQ_Assessment_Submissions__c >= (a.Cohort_NPQ_Tasks__c - 1)) {
                participantIds.put(a.Participant__c, 'Submitted- pending allocation');
            }

            if (null != a.Marker__c && a.Participant_NPQ_Assess_Sub_Marked__c >= (a.Cohort_NPQ_Tasks__c - 1)) {
                participantIds.put(a.Participant__c, 'Submitted (pending outcome)');
            }
        }
    }

    if (Trigger.isUpdate) {
        for (Id submissionId : Trigger.newMap.keySet() ) {
            Assessment_Submission__c oldS = Trigger.oldMap.get(submissionId), newS = Trigger.newMap.get(submissionId);

            if (oldS.Submission_Date__c == null && newS.Submission_Date__c != null && newS.Participant_NPQ_Assessment_Submissions__c >= (newS.Cohort_NPQ_Tasks__c - 1)) {
                participantIds.put(newS.Participant__c, 'Submitted- pending allocation');
            }

            if (null != newS.Marker__c && oldS.Marker__c != newS.Marker__c && newS.Participant_NPQ_Assess_Sub_Marked__c >= (newS.Cohort_NPQ_Tasks__c - 1)) {
                participantIds.put(newS.Participant__c, 'Submitted (pending outcome)');
            }
        }
    }

    participants = [
        SELECT Id, NPQ_Status__c
        FROM Programme_Participant__c
        WHERE Id IN :participantIds.keySet()
    ];
    
    for (Programme_Participant__c p: participants) {
        if (p.NPQ_Status__c == 'Submitted (pending outcome)' && participantIds.get(p.Id) == 'Submitted- pending allocation') {
            continue;
        }
        
        p.NPQ_Status__c = participantIds.get(p.Id);
    }

    update participants;
}