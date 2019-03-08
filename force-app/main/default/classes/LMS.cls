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
                LMS_Course_Section_Id__c,
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
        
        if (null != programme.LMS_Course_Id__c) {
            try {
                CanvasAPI.findCourseById(String.valueOf(programme.LMS_Course_Id__c));
                return;
            } catch (CanvasAPIException caught) {
                if (!caught.getMessage().contains('The specified resource does not exist')) {
                    throw caught;
                }
            }
        }

        String name = programme.Programme_Name__c + ' ' + programme.Cohort_Name__c;
        Map <String, Object> apiResult = CanvasAPI.createCourse(name, programme.Name, startAt, endAt);
        String courseId = String.valueOf(apiResult.get('id'));
        apiResult = CanvasAPI.createSection(name, courseId, startAt, endAt);
        Integer courseSectionId = Integer.valueOf(apiResult.get('id'));

        programme.LMS_Course_Id__c = Integer.valueOf(courseId);
        programme.LMS_Course_Section_Id__c = courseSectionId;

        update programme;
    }

    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.deleteCourse(programmes[2]);
    */
    public static void deleteCourse(TL_Programme__c p) {
        TL_Programme__c programme = [
            SELECT LMS_Course_Id__c 
            FROM TL_Programme__c
            WHERE Id = :p.Id
        ][0];

        if (null == programme.LMS_Course_Id__c) {
            throw new LMSException('The Programme doesn\'t has a Canvas course associated');
        }

        CanvasAPI.deleteCourse(programme.LMS_Course_Id__c.format());

        programme.LMS_Course_Id__c = null;

        update programme;
    }

    private static void cleanOtherUserLogins(String userId, String email, String provider) {
        try {
            CanvasAPI.createUserLogin(userId, email, provider);
        } catch (CanvasAPIException caught) {
            if (!caught.getMessage().contains('ID already in use for this account and authentication provider')) {
                throw caught;
            }
        }
        
        List <Object> apiResultList = CanvasAPI.listUserLogins(userId);
        
        for (Object result: apiResultList) {
            Map <String, Object> login = (Map <String, Object>) result;
            String providerType = String.valueOf(login.get('authentication_provider_type'));
            String loginId = String.valueOf(login.get('id'));
            if (provider != providerType) {
                CanvasAPI.removeUserLogin(userId, loginId);
            }
        }
    }

    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.usersProvision(programmes[2]);

        The participant should have a valid email
    */
    public static void usersProvision(TL_Programme__c p) {
        Map<Id, Programme_Participant__c> participants = new Map<Id, Programme_Participant__c>([
            SELECT Id,
                Programme__r.Id
            FROM Programme_Participant__c
            WHERE Programme__r.Id = :p.Id
        ]);

        onParticipantStatusChange(participants.keySet());
    }

    public static void usersComplete(TL_Programme__c p) {
        TL_Programme__c programme = [
            SELECT Id,
                (SELECT Status__c, 
                    Participant__r.Email
                FROM Programme_Participants__r)
            FROM TL_Programme__c
            WHERE Id = :p.Id
        ][0];

        for (Programme_Participant__c participant: programme.Programme_Participants__r) {
            participant.Status__c = 'Complete';

            update participant;
        }
    }

    public static void enrollUser(String userId, String courseSectionId, Boolean deactivate) {
        List <Object> apiResultList = CanvasAPI.findEnrollmentId(userId, courseSectionId);
        Map <String, Object> apiResult;
        String desiredState = deactivate ? 'active' : 'inactive';
        String enrollmentId;

        if (0 == apiResultList.size()) {
            apiResultList[0] = CanvasAPI.enrollUser(userId, courseSectionId, 'active');
        }

        apiResult = (Map <String, Object>) apiResultList[0];
        
        if (desiredState != String.valueOf(apiResult.get('enrollment_state'))) {
            return;
        }

        enrollmentId = String.valueOf(apiResult.get('id'));

        if (deactivate) {
            CanvasAPI.updateEnrollment(enrollmentId, String.valueOf(apiResult.get('course_id')), 'deactivate');
        } else {
            CanvasAPI.reactivateEnrollment(enrollmentId, String.valueOf(apiResult.get('course_id')));
        }
    }

    @future(callout=true)
    public static void onParticipantStatusChange(Set<ID> participantIds) {
        List<Programme_Participant__c> participants = [
            SELECT Id,
                Status__c,
                Programme__r.LMS_Start_Date__c,
                Programme__r.LMS_End_Date__c,
                Programme__r.LMS_Course_Section_Id__c,
                Participant__r.Email,
                Participant__r.Name,
                Participant__r.Prefered_Name__c,
                Participant__r.Participant_UID__c
            FROM Programme_Participant__c
            WHERE Id IN :participantIds
        ];
        Date today = Date.today();

        for (Programme_Participant__c participant: participants) {
            TL_Programme__c programme = participant.Programme__r;
            
            if (programme.LMS_Start_Date__c > today || programme.LMS_End_Date__c <= today) {
                continue;
            }

            Contact c = participant.Participant__r;
            if (null == c.Email) {
                continue;
            }

            List <Object> apiResultList = CanvasAPI.findUserByEmail(c.Email);
            Map <String, Object> apiResult;
            String userId;

            if (0 == apiResultList.size()) {
                apiResultList[0] = CanvasAPI.createUser(
                    c.Email,
                    c.Name,
                    c.Prefered_Name__c,
                    c.Participant_UID__c
                );
            }

            apiResult = (Map <String, Object>) apiResultList[0];

            userId = String.valueOf(apiResult.get('id'));

            switch on participant.Status__c {
               when 'Active' {
                    cleanOtherUserLogins(userId, c.Email, 'saml');
                    enrollUser(userId, String.valueOf(programme.LMS_Course_Section_Id__c), false);
               }
               when 'Inactive' {
                    enrollUser(userId, String.valueOf(programme.LMS_Course_Section_Id__c), true);
               }
               when 'Complete', 'Deferred', 'Withdrawn' {
                    cleanOtherUserLogins(userId, c.Email, 'canvas');
               }
            }
        }
    }

    @future(callout=true)
    public static void onCourseInsertOrUpdate(Set<ID> programmeIds) {
        for (TL_Programme__c programme: [SELECT Id, LMS_Access__c FROM TL_Programme__c WHERE Id IN :programmeIds]) {
            if (true == programme.LMS_Access__c) {
                createCourse(programme);
            }
        }
    }
}
