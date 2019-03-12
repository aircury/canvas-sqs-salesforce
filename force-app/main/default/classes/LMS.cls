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
        Boolean providerFound = false;
        List <Object> apiResultList = CanvasAPI.listUserLogins(userId);
        List <String[]> loginsToRemove = new List <String[]>();
        
        for (Object result: apiResultList) {
            Map <String, Object> login = (Map <String, Object>) result;
            String providerType = String.valueOf(login.get('authentication_provider_type'));
            String loginId = String.valueOf(login.get('id'));
            if (provider != providerType) {
                loginsToRemove.add(new String[]{userId, loginId});
            } else {
                providerFound = true;
            }
        }

        if (!providerFound) {
            CanvasAPI.createUserLogin(userId, email, provider);
        }

        for (String[] loginToRemove: loginsToRemove) {
            CanvasAPI.removeUserLogin(loginToRemove[0], loginToRemove[1]);
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

    public static void userEventsProvision(TL_Programme__c p) {
        Map<Id, Attendees__c> attendees = new Map<Id, Attendees__c>([
            SELECT Id,
                FLIP_Event__r.Cohort_lkp__r.Id
            FROM Attendees__c
            WHERE FLIP_Event__r.Cohort_lkp__r.Id = :p.Id
        ]);

        onEventInsert(attendees.keySet());
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

    public static void enrollUser(String userId, String courseSectionId, Boolean deactivate, String task) {
        List <Object> apiResultList = CanvasAPI.findEnrollmentId(userId, courseSectionId);
        Map <String, Object> apiResult;
        String desiredState = deactivate ? 'active' : 'inactive';
        String enrollmentId;

        if (0 == apiResultList.size()) {
            apiResultList.add(CanvasAPI.enrollUser(userId, courseSectionId, desiredState));
        }

        apiResult = (Map <String, Object>) apiResultList[0];
        
        if (desiredState != String.valueOf(apiResult.get('enrollment_state'))) {
            return;
        }

        enrollmentId = String.valueOf(apiResult.get('id'));

        if (deactivate) {
            CanvasAPI.updateEnrollment(enrollmentId, String.valueOf(apiResult.get('course_id')), task);
        } else {
            CanvasAPI.reactivateEnrollment(enrollmentId, String.valueOf(apiResult.get('course_id')));
        }
    }

    @future(callout=true)
    public static void onParticipantStatusChange(Set<ID> participantIds) {
        List<Programme_Participant__c> participants = [
            SELECT Id,
                Status__c,
                Programme__r.LMS_Course_Section_Id__c,
                Participant__r.Email,
                Participant__r.Name,
                Participant__r.Prefered_Name__c,
                Participant__r.Participant_UID__c
            FROM Programme_Participant__c
            WHERE Id IN :participantIds AND
                Programme__r.LMS_Access__c = true AND
                Participant__r.Email != null AND
                Programme__r.LMS_Start_Date__c <= TODAY AND
                Programme__r.LMS_End_Date__c >= TODAY
        ], test = [
            SELECT Id,
                Status__c,
                Programme__r.LMS_Access__c,
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

        System.debug('participants: ' + test);
        for (Programme_Participant__c participant: participants) {
            TL_Programme__c programme = participant.Programme__r;
            Contact c = participant.Participant__r;
            List <Object> apiResultList = CanvasAPI.findUserByEmail(c.Email);
            Map <String, Object> apiResult;
            String userId, sectionId = String.valueOf(programme.LMS_Course_Section_Id__c);

            if (0 == apiResultList.size()) {
                if (participant.Status__c == 'Complete' ||
                    participant.Status__c == 'Deferred' ||
                    participant.Status__c == 'Withdrawn') {
                        return;
                }

                apiResultList.add(CanvasAPI.createUser(
                    c.Email,
                    c.Name,
                    c.Prefered_Name__c,
                    c.Participant_UID__c
                ));
            }

            apiResult = (Map <String, Object>) apiResultList[0];

            userId = String.valueOf(apiResult.get('id'));

            switch on participant.Status__c {
               when 'Active' {
                    enrollUser(userId, sectionId, false, null);
               }
               when 'Inactive' {
                    enrollUser(userId, sectionId, true, 'deactivate');
               }
               when 'Complete', 'Deferred', 'Withdrawn' {
                    Integer otherUserCourses = [SELECT COUNT()
                        FROM Programme_Participant__c
                        WHERE Participant__r.Email = :c.Email AND
                            Programme__r.Id != :programme.Id AND
                            Programme__r.LMS_Access__c = true AND
                            Programme__r.LMS_Start_Date__c <= TODAY AND
                            Programme__r.LMS_End_Date__c > TODAY
                    ];

                    if (0 < otherUserCourses) {
                        enrollUser(userId, sectionId, true, 'conclude');
                    } else {
                        CanvasAPI.removeUser(userId);
                    }
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

    public static DateTime getEventDateTime(Date eventDate, String eventTime) {
        Integer hour = Integer.valueOf(eventTime.split(':')[0]),
                minute = Integer.valueOf(eventTime.split(':')[1]);

        return DateTime.newInstance(
            eventDate.year(),
            eventDate.month(),
            eventDate.day(),
            hour,
            minute,
            0
        );
    }

    @future(callout=true)
    public static void onEventInsert(Set<ID> attendeeIds) {
        doEventInsert(attendeeIds);
    }

    private static void doEventInsert(Set<ID> attendeeIds) {
        List<Attendees__c> attendees = [
            SELECT Id,
                Contact__r.Email,
                Contact__r.Name,
                Contact__r.Prefered_Name__c,
                Contact__r.Participant_UID__c,
                FLIP_Event__r.Event_Date__c,
                FLIP_Event__r.Event_End_Date__c,
                FLIP_Event__r.Start_Time__c,
                FLIP_Event__r.End_Time__c,
                FLIP_Event__r.Event_Name__c,
                FLIP_Event__r.Event_Description__c,
                FLIP_Event__r.Address_Line_1__c,
                FLIP_Event__r.Address_Line_2__c,
                FLIP_Event__r.Postal_Code__c
            FROM Attendees__c
            WHERE Id IN :attendeeIds AND
                FLIP_Event__r.Cohort_lkp__r.LMS_Access__c = true AND
                FLIP_Event__r.Send_to_LMS__c = true AND
                FLIP_Event__r.Cohort_lkp__r.LMS_Start_Date__c <= TODAY AND
                FLIP_Event__r.Cohort_lkp__r.LMS_End_Date__c > TODAY AND
                Contact__r.Email != null
        ];
        String code, title, description, address;
        List <Object> apiResultList;
        Map <String, Object> apiResult;
        String userId;

        for (Attendees__c attendee: attendees) {
            FLIP_Event__c event = attendee.FLIP_Event__r;
            Contact c = attendee.Contact__r;
            DateTime startAt = getEventDateTime(event.Event_Date__c, event.Start_Time__c);
            DateTime endAt = getEventDateTime(event.Event_End_Date__c, event.End_Time__c);
            
            apiResultList = CanvasAPI.findUserByEmail(c.Email);

            if (0 == apiResultList.size()) {
                apiResultList.add(CanvasAPI.createUser(
                    c.Email,
                    c.Name,
                    c.Prefered_Name__c,
                    c.Participant_UID__c
                ));
            }

            apiResult = (Map <String, Object>) apiResultList[0];

            userId = String.valueOf(apiResult.get('id'));
            title = event.Event_Name__c;
            description = event.Event_Description__c;
            address = event.Address_Line_1__c + '\n' + event.Address_Line_2__c + '\n' + event.Postal_Code__c;
            CanvasAPI.createEvent('user', userId, userId, title, description, startAt, endAt, address);
        }
    }

    @future(callout=true)
    public static void onEventDelete(Set<ID> attendeeIds, DateTime startAt, DateTime endAt) {
        doEventDelete(attendeeIds, null, null);
    }

    private static void doEventDelete(Set<ID> attendeeIds, DateTime startAt, DateTime endAt) {
        List<Attendees__c> attendees = [
            SELECT Id,
                Contact__r.Email,
                FLIP_Event__r.Event_Date__c,
                FLIP_Event__r.Event_End_Date__c,
                FLIP_Event__r.Start_Time__c,
                FLIP_Event__r.End_Time__c
            FROM Attendees__c
            WHERE Id IN :attendeeIds  AND
                FLIP_Event__r.Cohort_lkp__r.LMS_Access__c = true AND
                FLIP_Event__r.Cohort_lkp__r.LMS_Start_Date__c <= TODAY AND
                FLIP_Event__r.Cohort_lkp__r.LMS_End_Date__c > TODAY AND
                Contact__r.Email != null
            ALL ROWS
        ];
        String code, title, description, address;
        List <Object> apiResultList;
        Map <String, Object> apiResult;
        String userId;

        for (Attendees__c attendee: attendees) {
            FLIP_Event__c event = attendee.FLIP_Event__r;
            Contact c = attendee.Contact__r;
            startAt = null == startAt ? getEventDateTime(event.Event_Date__c, event.Start_Time__c) : startAt;
            endAt = null == endAt ? getEventDateTime(event.Event_End_Date__c, event.End_Time__c) : endAt;
            
            apiResultList = CanvasAPI.findUserByEmail(c.Email);

            if (0 == apiResultList.size()) {
                continue;
            }

            apiResult = (Map <String, Object>) apiResultList[0];

            userId = String.valueOf(apiResult.get('id'));
            
            apiResultList = CanvasAPI.listUserEvents(userId, startAt, endAt);

            for (Object result: apiResultList) {
                Map <String, Object> apiEvent = (Map <String, Object>) result;
                String eventId = String.valueOf(apiEvent.get('id'));
                CanvasAPI.removeUserEvent(userId, eventId);
            }
        }
    }

    @future(callout=true)
    public static void onEventUpdate(Set<ID> attendeeIds, DateTime startAt, DateTime endAt) {
        doEventDelete(attendeeIds, startAt, endAt);
        doEventInsert(attendeeIds);
    }
}
