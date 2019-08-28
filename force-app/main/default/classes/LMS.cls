/*
 * >>- Changelog -<<
 * Date           Developer   Comment
 * 19-06-2019     Ekta        Updated onParticipantNameChange method parameter from ID to Set<ID>
 * 							  to avoid Too many future calls: 51 and solve the Dataloader Error Case.
 * 	
 * 	 
*/ 

public with sharing class LMS {
    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.createCourse(programmes[2]);
    */
    public static void createCourse(TL_Programme__c p) {
        TL_Programme__c programme = [
            SELECT Id,
                Programme_Name__c,
                Cohort_Name__c,
                LMS_Course_Id__c,
                LMS_Course_Section_Id__c,
                LMS_Start_Date__c,
                LMS_End_Date__c
            FROM TL_Programme__c
            WHERE Id = :p.Id
        ][0];

        DateTime startAt = null, endAt = null;

        if (null != programme.LMS_Start_Date__c) {
            startAt = DateTime.newInstance(
                programme.LMS_Start_Date__c.year(),
                programme.LMS_Start_Date__c.month(),
                programme.LMS_Start_Date__c.day()
            );
        }

        if (null != programme.LMS_End_Date__c) {
            endAt = DateTime.newInstance(
                programme.LMS_End_Date__c.year(),
                programme.LMS_End_Date__c.month(),
                programme.LMS_End_Date__c.day()
            );
        }

        
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
        Map <String, Object> apiResult = CanvasAPI.createCourse(name, name, startAt, endAt);
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
    // public static void deleteCourse(TL_Programme__c p) {
    //     TL_Programme__c programme = [
    //         SELECT LMS_Course_Id__c 
    //         FROM TL_Programme__c
    //         WHERE Id = :p.Id
    //     ][0];

    //     if (null == programme.LMS_Course_Id__c) {
    //         throw new LMSException('The Programme doesn\'t has a Canvas course associated');
    //     }

    //     CanvasAPI.deleteCourse(programme.LMS_Course_Id__c.format());

    //     programme.LMS_Course_Id__c = null;

    //     update programme;
    // }

    // private static void cleanOtherUserLogins(String userId, String email, String provider) {
    //     Boolean providerFound = false;
    //     List <Object> apiResultList = CanvasAPI.listUserLogins(userId);
    //     List <String[]> loginsToRemove = new List <String[]>();
        
    //     for (Object result: apiResultList) {
    //         Map <String, Object> login = (Map <String, Object>) result;
    //         String providerType = String.valueOf(login.get('authentication_provider_type'));
    //         String loginId = String.valueOf(login.get('id'));
    //         if (provider != providerType) {
    //             loginsToRemove.add(new String[]{userId, loginId});
    //         } else {
    //             providerFound = true;
    //         }
    //     }

    //     if (!providerFound) {
    //         CanvasAPI.createUserLogin(userId, email, provider);
    //     }

    //     for (String[] loginToRemove: loginsToRemove) {
    //         CanvasAPI.removeUserLogin(loginToRemove[0], loginToRemove[1]);
    //     }
    // }

    /* Sample test code:
        TL_Programme__c[] programmes = [SELECT Id FROM TL_Programme__c];
        LMS.usersProvision(programmes[2]);

        The participant should have a valid email
    */
    public static void usersProvision(TL_Programme__c p) {
        Map<Id, Programme_Participant__c> participants = new Map<Id, Programme_Participant__c>([
            SELECT Id
            FROM Programme_Participant__c
            WHERE Programme__r.Id = :p.Id
        ]);

        Map<Id, Attendees__c> attendees = new Map<Id, Attendees__c>([
            SELECT Id
            FROM Attendees__c
            WHERE FLIP_Event__r.Cohort_lkp__r.Id = :p.Id
        ]);

        System.enqueueJob(new LMSParticipantStatusChangeJob(participants.keySet(), new LMSEventInsertJob(attendees.keySet(), null)));
    }

    public static void removeUsers(TL_Programme__c p) {
         Map<Id, Programme_Participant__c> participants = new Map<Id, Programme_Participant__c>([
            SELECT Id
            FROM Programme_Participant__c
            WHERE Programme__r.Id = :p.Id
        ]);

        System.enqueueJob(new LMSRemoveUsersJob(participants.keySet(), null));
    }

    public static void doRemoveUsers(Set<ID> participantIds) {
        List<Programme_Participant__c> participants = [
            SELECT Id,
                Programme__r.LMS_Course_Section_Id__c,
                Programme__r.Id,
                Participant__r.Email,
                Participant__r.Participant_UID__c
            FROM Programme_Participant__c
            WHERE Id IN :participantIds AND
                Programme__r.LMS_Access__c = true AND
                Participant__r.Email != null
        ];
        
        for (Programme_Participant__c participant: participants) {
            Contact c = participant.Participant__r;
            List <Object> apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);
            Map <String, Object> apiResult;
            String userId, sectionId = String.valueOf(participant.Programme__r.LMS_Course_Section_Id__c);

            if (0 == apiResultList.size()) {
                continue;
            }

            apiResult = (Map <String, Object>) apiResultList[0];

            userId = String.valueOf(apiResult.get('id'));

            removeUser(userId, sectionId, participant.Programme__r.Id, c.Email);
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

    public static void removeUser(String userId, String sectionId, Id programmeId, String email) {
        Integer otherUserCourses = [SELECT COUNT()
            FROM Programme_Participant__c
            WHERE Participant__r.Email = :email AND
                Programme__r.Id != :programmeId AND
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

    public static void doParticipantStatusChange(Set<ID> participantIds) {
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
        ];
        
        for (Programme_Participant__c participant: participants) {
            TL_Programme__c programme = participant.Programme__r;
            Contact c = participant.Participant__r;
            List <Object> apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);
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

                try {
                    CanvasAPI.createCommunicationChannel(c.Participant_UID__c, c.Email);
                } catch (CanvasAPIException caught) {
                    if (!caught.getMessage().contains('unique!')) {
                        throw caught;
                    }
                }
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
                    removeUser(userId, sectionId, programme.Id, c.Email);
               }
            }
        }
    }

    @future(callout=true)
    public static void onContactUpdate(ID contactId, String oldEmail, String newEmail) {
        doContactUpdate(contactId, oldEmail, newEmail);
    }

    public static void doContactUpdate(ID contactId, String oldEmail, String newEmail) {
        List<Programme_Participant__c> participants = [
            SELECT Participant__r.Name,
                Participant__r.Email,
                Participant__r.Prefered_Name__c,
                Participant__r.Participant_UID__c
            FROM Programme_Participant__c
            WHERE Participant__r.Id = :contactId AND
                Programme__r.LMS_Access__c = true AND
                Participant__r.Email != null AND
                Programme__r.LMS_Start_Date__c <= TODAY AND
                Programme__r.LMS_End_Date__c >= TODAY
        ];
        
        for (Programme_Participant__c participant: participants) {
            Contact c = participant.Participant__r;

            CanvasAPI.updateUser(c.Participant_UID__c, c.Name, c.Prefered_Name__c);

            if (oldEmail == newEmail) {
                break;
            }

            try {
                CanvasAPI.deleteCommunicationChannel(c.Participant_UID__c, oldEmail);
            } catch (CanvasAPIException caught) {
                if (!caught.getMessage().contains('The specified resource does not exist')) {
                    throw caught;
                }
            }

            try {
                CanvasAPI.createCommunicationChannel(c.Participant_UID__c, newEmail);
            } catch (CanvasAPIException caught) {
                if (!caught.getMessage().contains('unique!')) {
                    throw caught;
                }
            }

            CanvasAPI.updateUserEmail(c.Participant_UID__c, newEmail);
            
            //Update user login
            List<Object> apiResultList = CanvasAPI.listUserLogins(c.Participant_UID__c);

            for (Object result: apiResultList) {
                Map <String, Object> apiResult = (Map <String, Object>) result;
                if (oldEmail == String.valueOf(apiResult.get('unique_id'))) {
                    CanvasAPI.editUserLogin(String.valueOf(apiResult.get('id')), newEmail);
                }
            }

            break;
        }
    }
    
    
	//Updated method parameter from ID to Set<ID> to avoid Too many future calls: 51 and solve the Dataloader Error Case.
    public static void doParticipantNameChange(Set<ID> participantId) {
        List<Programme_Participant__c> participants = [
            SELECT ParticipantName__c,
                Participant__r.Email,
                Participant__r.Name,
                Participant__r.Prefered_Name__c,
                Participant__r.Participant_UID__c
            FROM Programme_Participant__c
            WHERE Id = :participantId AND
                Programme__r.LMS_Access__c = true AND
                Participant__r.Email != null AND
                Programme__r.LMS_Start_Date__c <= TODAY AND
                Programme__r.LMS_End_Date__c >= TODAY
        ];
        List <Object> apiResultList;

        for (Programme_Participant__c participant: participants) {
            Contact c = participant.Participant__r;

            apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);

            if (0 == apiResultList.size()) {
                apiResultList.add(CanvasAPI.createUser(
                    c.Email,
                    c.Name,
                    c.Prefered_Name__c,
                    c.Participant_UID__c
                ));

                try {
                    CanvasAPI.createCommunicationChannel(c.Participant_UID__c, c.Email);
                } catch (CanvasAPIException caught) {
                    if (!caught.getMessage().contains('unique!')) {
                        throw caught;
                    }
                }
            } else {
                CanvasAPI.updateUser(c.Participant_UID__c, participant.ParticipantName__c, c.Prefered_Name__c);
            }
        }
    }

    @future(callout=true)
    public static void onCourseInsert(ID programmeId) {
        List<TL_Programme__c> programmes = [
            SELECT Id,
                LMS_Access__c
            FROM TL_Programme__c
            WHERE Id = :programmeId
        ];

        for (TL_Programme__c programme: programmes) {
            if (true == programme.LMS_Access__c) {
                createCourse(programme);
            }
        }
    }

    @future(callout=true)
    public static void onCourseUpdate(ID programmeId) {
        List<TL_Programme__c> programmes = [
            SELECT LMS_Access__c,
                Programme_Name__c,
                Cohort_Name__c,
                LMS_Course_Id__c,
                LMS_Course_Section_Id__c,
                LMS_Start_Date__c,
                LMS_End_Date__c
            FROM TL_Programme__c
            WHERE Id = :programmeId
        ];
        DateTime startAt = null, endAt = null;
        String name;

        for (TL_Programme__c programme: programmes) {
            if (true == programme.LMS_Access__c) {
                if (null != programme.LMS_Start_Date__c) {
                    startAt = DateTime.newInstance(
                        programme.LMS_Start_Date__c.year(),
                        programme.LMS_Start_Date__c.month(),
                        programme.LMS_Start_Date__c.day()
                    );
                }

                if (null != programme.LMS_End_Date__c) {
                    endAt = DateTime.newInstance(
                        programme.LMS_End_Date__c.year(),
                        programme.LMS_End_Date__c.month(),
                        programme.LMS_End_Date__c.day()
                    );
                }

                name = programme.Programme_Name__c + ' ' + programme.Cohort_Name__c;
                CanvasAPI.updateCourse(String.valueOf(programme.LMS_Course_Id__c), name, name, startAt, endAt);
                CanvasAPI.updateSection(String.valueOf(programme.LMS_Course_Section_Id__c), name, startAt, endAt);
            }
        }
    }

    public static DateTime getEventDateTime(Date eventDate, String eventTime) {
        if (null == eventTime) {
            eventTime = '12:00';
        }

        if (null == eventDate) {
            return Datetime.now();
        }

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

    public static void doEventInsert(Set<ID> attendeeIds) {
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
                FLIP_Event__r.Event_Description_Rich__c,
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
        String code, title, description, address, line1, line2, postalCode;
        List <Object> apiResultList;
        Map <String, Object> apiResult;
        String userId;

        for (Attendees__c attendee: attendees) {
            FLIP_Event__c event = attendee.FLIP_Event__r;
            Contact c = attendee.Contact__r;
            DateTime startAt = getEventDateTime(event.Event_Date__c, event.Start_Time__c);
            DateTime endAt = getEventDateTime(event.Event_End_Date__c, event.End_Time__c);
            
            apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);

            if (0 == apiResultList.size()) {
                apiResultList.add(CanvasAPI.createUser(
                    c.Email,
                    c.Name,
                    c.Prefered_Name__c,
                    c.Participant_UID__c
                ));

                try {
                    CanvasAPI.createCommunicationChannel(c.Participant_UID__c, c.Email);
                } catch (CanvasAPIException caught) {
                    if (!caught.getMessage().contains('unique!')) {
                        throw caught;
                    }
                }
            }

            apiResult = (Map <String, Object>) apiResultList[0];

            userId = String.valueOf(apiResult.get('id'));
            title = event.Event_Name__c;
            description = null == event.Event_Description_Rich__c ? '' : event.Event_Description_Rich__c;
            line1 = null == event.Address_Line_1__c ? '' : event.Address_Line_1__c;
            line2 = null == event.Address_Line_2__c ? '' : event.Address_Line_2__c;
            postalCode = null == event.Postal_Code__c ? '' : event.Postal_Code__c;
            address = line1 + ' ' + line2 + ' ' + postalCode;
            CanvasAPI.createEvent('user', userId, userId, title, description, startAt, endAt, address);
        }
    }

    public static void doEventDelete(Set<ID> attendeeIds, DateTime startAt, DateTime endAt) {
        List<Attendees__c> attendees = [
            SELECT Id,
                Contact__r.Participant_UID__c,
                FLIP_Event__r.Event_Date__c,
                FLIP_Event__r.Event_End_Date__c,
                FLIP_Event__r.Start_Time__c,
                FLIP_Event__r.End_Time__c
            FROM Attendees__c
            WHERE Id IN :attendeeIds  AND
                FLIP_Event__r.Cohort_lkp__r.LMS_Access__c = true AND
                FLIP_Event__r.Cohort_lkp__r.LMS_Start_Date__c <= TODAY AND
                FLIP_Event__r.Cohort_lkp__r.LMS_End_Date__c > TODAY AND
                Contact__r.Participant_UID__c != null
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
            
            apiResultList = CanvasAPI.findUserByUID(c.Participant_UID__c);

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

    public static void onEventUpdate(Set<ID> attendeeIds, DateTime startAt, DateTime endAt) {
        System.enqueueJob(new LMSEventDeleteJob(attendeeIds, startAt, endAt, new LMSEventInsertJob(attendeeIds, null)));
    }
}