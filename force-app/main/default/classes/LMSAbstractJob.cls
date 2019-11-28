global abstract class LMSAbstractJob implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    List<sObject> ids;
    LMSAbstractJob nextJob;
    private final List<String> errors;

    public LMSAbstractJob(List<sObject> i, LMSAbstractJob j) {
        ids = i;
        nextJob = j;
        errors = new List<String>();
    }

    global Iterable<SObject> start(Database.BatchableContext BC) {
        return ids;
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> i = new Set<Id>();

        for (SObject ob: scope) {
            i.add(ob.Id);
        }

        errors.addAll(doExecute(i));
    }

    global abstract List<String> doExecute(Set<Id> i);

    global abstract String emailSubject();

    global abstract Integer batchSize();

    global void finish(Database.BatchableContext BC) {
        if (errors.size() > 0) {
            AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :BC.getJobId()
            ];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            
            mail.setToAddresses(toAddresses);
            mail.setSubject(emailSubject() + a.Status + ' with errors');
            String body = 'The batch Apex job processed ' + a.TotalJobItems +
            ' batches with '+ a.NumberOfErrors + ' failures.\n\nBut the next errors were recorded:\n\n';

            for (String error: errors) {
                body = body + error + '\n';
            }

            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

        if (nextJob != null) {
            if (!Test.isRunningTest()) {
                Database.executeBatch(nextJob, nextJob.batchSize());
            }
        }
    }
}
