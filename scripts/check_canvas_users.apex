List<Programme_Participant__c> participants = [
SELECT Id, Participant__r.Participant_UID__c, Participant__r.Email, Programme__r.Name
FROM Programme_Participant__c
WHERE Programme__r.LMS_Access__c = true AND
Participant__r.Email != null AND
Programme__r.LMS_Start_Date__c <= TODAY AND
Programme__r.LMS_End_Date__c >= TODAY AND
(Status__c = 'Active' OR Status__c = 'Inactive')
];

List<Programme_Participant__c> canvas_users = new List<Programme_Participant__c>();
Integer i = 0, start = 1300, maxIterations = 100;

System.debug(LoggingLevel.INFO, 'Participants: ' + participants.size());

for (Programme_Participant__c participant: participants) {
    if (i < start) {
        i = i + 1;
        continue;
    }
    if (i >= (start+maxIterations)) {
        break;
    }
    Contact c = participant.Participant__r;
    List <Object> apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);
    if (0 == apiResultList.size()) {
        System.debug(LoggingLevel.INFO, 'Non existent user ' + start + '-' + (start+maxIterations) + ': ' + c.Participant_UID__c + ' ' + c.Email + ' ' + participant.Programme__r.Name);
    }
    i = i + 1;
}
