@isTest
private class LMSTest {
    static Programme_Definition__c prDef;
    static Opportunity o;
    static Contact c;
    static {
        Test.setMock(HttpCalloutMock.class, new CanvasAPIMock());

        prDef = new Programme_Definition__c(Programme__c='Test', Status__c='Active');
        insert prDef;
        
        Account a = new Account(Name='TestAccount');
        insert a;
        
        c = new Contact(FirstName = 'Test', LastName= 'Test', AccountId = a.Id, Email='test@example.org');
        insert c;
        
        o = new Opportunity(Name='Test', AccountId=a.Id, Package_del__c='Independant cycle',
            StageName='Completed', Type='Small group', CloseDate=Date.today());
        insert o;
    }

    @isTest private static void TestLMSCourseProvisionTrigger() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;
    }

    @isTest private static void TestLMSProgrammeParticipantStatusTrigger() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        Test.startTest();
        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c.Id,
            Status__c='Active'
        );
        insert participant;

        participant.Status__c = 'Inactive';

        update participant;

        Test.stopTest();
    }
}
