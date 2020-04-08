global class LMSBatchTest implements Database.Batchable<sObject> {
    global final String Query;
    global final String Entity;
    global final String Field;
    global final String Value;
 
    global LMSBatchTest(String q, String e, String f, String v) {
        Query=q; Entity=e; Field=f;Value=v;
    }
 
    global Database.QueryLocator start(Database.BatchableContext BC) {
       return Database.getQueryLocator(Query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
       for(Sobject s : scope) {
           s.put(Field,Value); 
       }
       
       update scope;
    }
 
    global void finish(Database.BatchableContext BC) {
    }
}
