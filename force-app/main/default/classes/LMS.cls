public with sharing class LMS {
    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.createCourse(programmes[2]);
    */
    public static void createCourse(TL_Programme__c p) {
        TL_Programme__c programme = [
            SELECT Id,
                Name,
                Programme_Name__c,
                Cohort_Name__c,
                LMS_Course_Id__c,
                LMS_Course_Start_Job_Id__c,
                LMS_Course_End_Job_Id__c,
                LMS_Start_Date__c, 
                LMS_End_Date__c
            FROM TL_Programme__c
            WHERE Id = :p.Id
        ][0];

        if (null == programme.LMS_Start_Date__c) {
            throw new LMSException('LMS Start Date is null');
        }

        if (null == programme.LMS_End_Date__c) {
            throw new LMSException('LMS End Date is null');
        }

        DateTime startAt = DateTime.newInstance(
            programme.LMS_Start_Date__c.year(),
            programme.LMS_Start_Date__c.month(),
            programme.LMS_Start_Date__c.day()
        );

        DateTime endAt = DateTime.newInstance(
            programme.LMS_End_Date__c.year(),
            programme.LMS_End_Date__c.month(),
            programme.LMS_End_Date__c.day()
        );

        String name = programme.Programme_Name__c + ' ' + programme.Cohort_Name__c;
        Map <String, Object> apiResult = CanvasAPI.createCourse(name, programme.Name, startAt, endAt);
        String courseId = String.valueOf(apiResult.get('id'));

        ScheduledLMSUsersProvision startTask = new ScheduledLMSUsersProvision(programme, false);
        Date startDate = programme.LMS_Start_Date__c;
        String startSch = String.format('0 0 0 {0} {1} ? {2}', new Object[]{startDate.day(), startDate.month(), startDate.year()});
        String startJobId = System.Schedule('LMS Users Provision for Course Id ' + courseId, startSch, startTask);

        ScheduledLMSUsersProvision endTask = new ScheduledLMSUsersProvision(programme, true);
        Date endDate = programme.LMS_End_Date__c;
        String endSch = String.format('0 0 0 {0} {1} ? {2}', new Object[]{endDate.day(), endDate.month(), endDate.year()});
        String endJobId = System.Schedule('LMS Users Removal for Course Id ' + courseId, endSch, endTask);

        programme.LMS_Course_Id__c = Integer.valueOf(courseId);
        programme.LMS_Course_Start_Job_Id__c = startJobId;
        programme.LMS_Course_End_Job_Id__c = endJobId;

        update programme;
    }

    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.deleteCourse(programmes[2]);
    */
    public static void deleteCourse(TL_Programme__c p) {
        TL_Programme__c programme = [
            SELECT LMS_Course_Start_Job_Id__c,
                LMS_Course_End_Job_Id__c,
                LMS_Course_Id__c 
            FROM TL_Programme__c
            WHERE Id = :p.Id
        ][0];

        if (null == programme.LMS_Course_Id__c) {
            throw new LMSException('The Programme doesn\'t has a Canvas course associated');
        }

        CanvasAPI.deleteCourse(programme.LMS_Course_Id__c.format());

        if (null != programme.LMS_Course_Start_Job_Id__c) {
            System.abortJob(programme.LMS_Course_Start_Job_Id__c);
        }
        
        if (null != programme.LMS_Course_End_Job_Id__c) {
            System.abortJob(programme.LMS_Course_End_Job_Id__c);
        }

        programme.LMS_Course_Id__c = null;
        programme.LMS_Course_Start_Job_Id__c = null;
        programme.LMS_Course_End_Job_Id__c = null;

        update programme;
    }

    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.usersProvision(programmes[2]);
    */
    public static void usersProvision(TL_Programme__c p) {
        TL_Programme__c programme = [
            SELECT Id, 
                (SELECT Status__c, 
                    Participant__r.Email,
                    Participant__r.Name,
                    Participant__r.Prefered_Name__c,
                    Participant__r.Participant_UID__c
                FROM Programme_Participants__r)
            FROM TL_Programme__c
            WHERE Id = :p.Id
        ][0];

        for (Programme_Participant__c participant: programme.Programme_Participants__r) {
            if ('Active' == participant.Status__c) {
                Contact c = participant.Participant__r;
                if (null != c.Email) {
                    Map <String, Object> apiResult = CanvasAPI.createUser(
                        c.Email,
                        c.Name,
                        c.Prefered_Name__c,
                        c.Participant_UID__c
                    );
                }
            }
        }
    }

    public static void usersRemoval(TL_Programme__c programme) {
    }
}
