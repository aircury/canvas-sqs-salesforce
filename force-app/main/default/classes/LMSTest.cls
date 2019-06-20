@isTest
private class LMSTest {
    static Programme_Definition__c prDef;
    static Opportunity o;
    static Contact c1, c2;
    static CanvasAPIMock apiMock;
    static {
        apiMock = new CanvasAPIMock();
        Test.setMock(HttpCalloutMock.class, apiMock);

        prDef = new Programme_Definition__c(Programme__c='Test', Status__c='Active');
        insert prDef;
        
        Account a = new Account(Name='TestAccount');
        insert a;
        
        c1 = new Contact(FirstName = 'Test', LastName= 'Test', AccountId = a.Id, Email='test1@example.org');
        insert c1;

        c2 = new Contact(FirstName = 'Test', LastName= 'Test', AccountId = a.Id, Email='test2@example.org');
        insert c2;

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

    @isTest private static void TestLMSCourseProvisionUpdateTrigger() {
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

        cohort.LMS_Access__c = false;

        update cohort;

        cohort.LMS_Access__c = true;
        cohort.LMS_End_Date__c = cohort.LMS_End_Date__c + 1;

        update cohort;

        Test.stopTest();
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
            Participant__c=c1.Id,
            Status__c='Active'
        );
        insert participant;
        
        Test.stopTest();
    }
    
    @isTest private static void TestLMSProgrammeParticipantStatusTriggerName() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c1.Id,
            Status__c='Active'
        );
        insert participant;
        
        Test.startTest();

        participant.ParticipantName__c = 'New Name';

        update participant;

        Test.stopTest();
    }

    @isTest private static void TestLMSProgrammeParticipantStatusTriggerInactive() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c2.Id,
            Status__c='Active'
        );
        apiMock.setEmptySearch(true);
        insert participant;
       
        Test.startTest();
        
        participant.Status__c='Inactive';
        update participant;

        Test.stopTest();
        apiMock.setEmptySearch(false);
    }

    @isTest private static void TestLMSContactTrigger() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c1.Id,
            Status__c='Active'
        );
        insert participant;
       
        Test.startTest();
        
        c1.Email = 'test11@example.org';
        update c1;

        Test.stopTest();
    }

    @isTest private static void TestLMSProgrammeParticipantStatusTriggerComplete() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c1.Id,
            Status__c='Active'
        );
        insert participant;
       
        Test.startTest();
        
        participant.Status__c='Complete';
        update participant;

        Test.stopTest();
    }

    @isTest private static void TestLMSEventAttendeesProvisionTrigger() {
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
        FLIP_Event__c event = new FLIP_Event__c(
            Event_Date__c=Date.today(),
            Event_End_Date__c=Date.today(),
            Start_Time__c='10:00',
            End_Time__c='11:00',
            Event_Name__c='Test Event',
            Event_Description__c='Test Description',
            Address_Line_1__c='Test Address Line 1',
            Address_Line_2__c='Test Address Line 2',
            Postal_Code__c='SE1 8JX',
            Send_to_LMS__c=true,
            Cohort_lkp__c=cohort.Id
        );

        insert event;

        Attendees__c attendee = new Attendees__c(
            FLIP_Event__c=event.Id,
            Contact__c=c1.Id
        );

        insert attendee;

        event.End_Time__c = '12:00';

        update event;

        Test.stopTest();
    }

    @isTest private static void TestLMSEventAttendeesProvisionTriggerDelete() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        FLIP_Event__c event = new FLIP_Event__c(
            Event_Date__c=Date.today(),
            Event_End_Date__c=Date.today(),
            Start_Time__c='10:00',
            End_Time__c='11:00',
            Event_Name__c='Test Event',
            Event_Description__c='Test Description',
            Address_Line_1__c='Test Address Line 1',
            Address_Line_2__c='Test Address Line 2',
            Postal_Code__c='SE1 8JX',
            Send_to_LMS__c=true,
            Cohort_lkp__c=cohort.Id
        );

        insert event;

        Attendees__c attendee = new Attendees__c(
            FLIP_Event__c=event.Id,
            Contact__c=c1.Id
        );

        insert attendee;

        Test.startTest();

        delete attendee;

        Test.stopTest();
    }

    @isTest private static void TestScheduledLMSUsersProvision() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today(),
            LMS_End_Date__c=Date.today() + 1
        );

        insert cohort;

        FLIP_Event__c event = new FLIP_Event__c(
            Event_Date__c=Date.today(),
            Event_End_Date__c=Date.today(),
            Start_Time__c='10:00',
            End_Time__c='11:00',
            Event_Name__c='Test Event',
            Event_Description__c='Test Description',
            Address_Line_1__c='Test Address Line 1',
            Address_Line_2__c='Test Address Line 2',
            Postal_Code__c='SE1 8JX',
            Send_to_LMS__c=true,
            Cohort_lkp__c=cohort.Id
        );

        insert event;

        Attendees__c attendee = new Attendees__c(
            FLIP_Event__c=event.Id,
            Contact__c=c1.Id
        );

        insert attendee;

        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c1.Id,
            Status__c='Active'
        );
        
        insert participant;

        Test.startTest();

        System.schedule('ScheduleApexTest', '0 0 0 1 1 ?', new ScheduledLMSUsersProvision());

        Test.stopTest();
    }

    @isTest private static void TestScheduledLMSUsersProvisionComplete() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true,
            LMS_Start_Date__c=Date.today() - 1,
            LMS_End_Date__c=Date.today()
        );

        insert cohort;

        FLIP_Event__c event = new FLIP_Event__c(
            Event_Date__c=Date.today(),
            Event_End_Date__c=Date.today(),
            Start_Time__c='10:00',
            End_Time__c='11:00',
            Event_Name__c='Test Event',
            Event_Description__c='Test Description',
            Address_Line_1__c='Test Address Line 1',
            Address_Line_2__c='Test Address Line 2',
            Postal_Code__c='SE1 8JX',
            Send_to_LMS__c=true,
            Cohort_lkp__c=cohort.Id
        );

        insert event;

        Attendees__c attendee = new Attendees__c(
            FLIP_Event__c=event.Id,
            Contact__c=c1.Id
        );

        insert attendee;

        Programme_Participant__c participant = new Programme_Participant__c(
            Cohort__c=cohort.Id,
            Participant__c=c1.Id,
            Status__c='Active'
        );
        
        insert participant;

        Test.startTest();

        System.schedule('ScheduleApexTest', '0 0 0 1 1 ?', new ScheduledLMSUsersProvision());

        Test.stopTest();
    }

    @isTest private static void TestLMSException() {
        TL_Programme__c cohort = new TL_Programme__c(
            Programme_Definition__c=prDef.Id,
            Opportunity__c=o.Id,
            Cohort_Name__c='Test 1',
            LMS_Access__c=true
        );

        try {
            Test.startTest();
            insert cohort;
            Test.stopTest();
        } catch (Exception caught) {
            System.assert(caught.getTypeName() == 'LMSException');
        }
    }

    @isTest private static void TestCanvasAPIException() {
        try {
            Test.startTest();
            CanvasAPI.updateEnrollment('19', '60', 'deactivate');
            Test.stopTest();
        } catch (Exception caught) {
            System.assert(caught.getTypeName() == 'CanvasAPIException', 'Got ' + caught.getTypeName() + ' instead');
        }
    }
}