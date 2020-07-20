/* This class needs a Custom Setting named as CanvasAPISettings with 4 fields:
    - Token: to store the an Access token created on Canvas with an admin user
    - Base_Url: the base url endpoint for the Canvas instance. For example https://ambition.instructure.com/api/v1.
        The base url also needs to be added on Remote Sites (Setup->Security Controls->Remote Site Settings)
    - Account_Id: Canvas account Id used to create courses or users on that Canvas account. For example: account id 1
        is the "Ambition School Leadership" main and only account on https://ambition.instructure.com
    - Participant_Role_Id__c: Role id of the Participant role in Canvas. For example 13 (the default if not filled) is
        the "Participant" role id on the Canvas instance <https://ambition.instructure.com>.
*/
public with sharing class CanvasAPI {
    /* Sample test code:
        CanvasAPI.createCourse('Test Course', 'Test',
            DateTime.newInstance(2019, 3, 30), DateTime.newInstance(2019, 4, 30));
    */
    public static Map <String, Object> createCourse(String name, String code, DateTime startAt, DateTime endAt) {
        String body =
            'course[name]=' + name +
            '&course[course_code]=' + code +
            '&course[license]=private' +
            '&course[is_public]=false' +
            '&course[allow_wiki_comments]=false' +
            '&course[open_enrollment]=false' +
            '&course[self_enrollment]=false' +
            '&course[term_id]=' + //empty to set "Default term"
            '&course[time_zone]=Europe/London' +
            '&course[course_format]=blended';

        if (null != startAt) {
            body += '&course[start_at]=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        if (null != endAt) {
            body += '&course[end_at]=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        return (Map <String, Object>) apiCall('POST', 'accounts/:account_id/courses', body);
    }

    /* Sample test code:
        CanvasAPI.updateCourse('37', 'Test Course', 'Test',
            DateTime.newInstance(2019, 3, 30), DateTime.newInstance(2019, 4, 30));
    */
    public static Map <String, Object> updateCourse(String courseId, String name, String code, DateTime startAt, DateTime endAt) {
        String body =
            'course[name]=' + name +
            '&course[course_code]=' + code;

        if (null != startAt) {
            body += '&course[start_at]=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        if (null != endAt) {
            body += '&course[end_at]=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        return (Map <String, Object>) apiCall('PUT', 'courses/' + courseId, body);
    }

    /* Sample test code:
        CanvasAPI.createSection('Test Course', '91',
            DateTime.newInstance(2019, 3, 30), DateTime.newInstance(2019, 4, 30));
    */
    public static Map <String, Object> createSection(String name, String courseId, DateTime startAt, DateTime endAt) {
        String body =
            'course_section[name]=' + name;

        if (null != startAt) {
            body += '&course_section[start_at]=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        if (null != endAt) {
            body += '&course_section[end_at]=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        return (Map <String, Object>) apiCall('POST', 'courses/' + courseId + '/sections', body);
    }

    /* Sample test code:
        CanvasAPI.updateSection('13', 'Test Course', '91',
            DateTime.newInstance(2019, 3, 30), DateTime.newInstance(2019, 4, 30));
    */
    public static Map <String, Object> updateSection(String sectionId, String name, DateTime startAt, DateTime endAt) {
        String body =
            'course_section[name]=' + name;

        if (null != startAt) {
            body += '&course_section[start_at]=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        if (null != endAt) {
            body += '&course_section[end_at]=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        }

        return (Map <String, Object>) apiCall('PUT', 'sections/' + sectionId, body);
    }

    /* Sample test code:
        CanvasAPI.enrollUser('26', '49', 'active');
    */
    public static Map <String, Object> enrollUser(String userId, String courseSectionId, String state) {
        String body =
            'enrollment[user_id]=' + userId +
            '&enrollment[role_id]=:participant_role_id' +
            '&enrollment[enrollment_state]=' + state;

        return (Map <String, Object>) apiCall('POST', 'sections/' + courseSectionId + '/enrollments', body);
    }

    /* Sample test code:
        CanvasAPI.deleteCourse(programmes[2]);
    */
    // public static Map <String, Object> deleteCourse(String id) {
    //     String body = 'event=delete';

    //     return (Map <String, Object>) apiCall('DELETE', 'courses/' + id, body);
    // }

    /* Sample test code:
        CanvasAPI.createUser('test@example.org', 'Test User', 'Test Short Name', 'participant123');
    */
    public static Map <String, Object> createUser(String email, String name, String shortName, String participantUID) {
        String body =
            'pseudonym[unique_id]=' + email +
            '&user[name]=' + name +
            '&user[short_name]=' + (null != shortName ? shortName : name) +
            '&user[time_zone]=Europe/London' +
            '&user[birthdate]=' +
            '&user[terms_of_use]=false' +
            '&user[skip_registration]=true' +
            '&communication_channel[skip_confirmation]=true' +
            '&pseudonym[send_confirmation]=false' +
            '&pseudonym[sis_user_id]=' + participantUID +
            '&enable_sis_reactivation=true' +
            '&pseudonym[authentication_provider_id]=saml' +
            '&pseudonym[force_self_registration]=false';

        Map <String, Object> result = null;

        try {
            result = (Map <String, Object>) apiCall('POST', 'accounts/:account_id/users', body);
        } catch (CanvasAPIException caught) {
            if (!caught.getMessage().contains('ID already in use for this account')) {
                throw caught;
            }
        }

        return result;
    }

    public static Map <String, Object> createCommunicationChannel(String participantUID, String email) {
        String body =
            'communication_channel[address]=' + email +
            '&communication_channel[type]=email' +
            '&skip_confirmation=true';

        Map <String, Object> result = null;

        try {
            result = (Map <String, Object>) apiCall('POST', 'users/sis_user_id:' + participantUID + '/communication_channels', body);
        } catch (CanvasAPIException caught) {
            if (!caught.getMessage().contains('unique!')) {
                throw caught;
            }
        }

        return result;
    }

    public static Map <String, Object> deleteCommunicationChannel(String participantUID, String email) {
        return (Map <String, Object>) apiCall('DELETE', 'users/sis_user_id:' + participantUID + '/communication_channels/email/' + email, '');
    }

    public static Map <String, Object> updateUser(String participantUID, String name, String shortName) {
        String body =
            'user[name]=' + name +
            '&user[short_name]=' + (null != shortName ? shortName : name);

        return (Map <String, Object>) apiCall('PUT', 'users/sis_user_id:' + participantUID, body);
    }

    public static Map <String, Object> updateUserEmail(String participantUID, String email) {
        String body = 'user[email]=' + email;

        return (Map <String, Object>) apiCall('PUT', 'users/sis_user_id:' + participantUID, body);
    }

    /* Sample test code:
        CanvasAPI.findUserByUID('123456');
    */
    public static List <Object> findUserByUID(String participantUID) {
        String query =
            '?search_term=' + participantUID +
            '&sort=sis_id';

        return (List <Object>) apiCall('GET', 'accounts/:account_id/users' + query, '');
    }

    /* Sample test code:
        CanvasAPI.findCourseById('19');
    */
    public static Map <String, Object> findCourseById(String id) {
        return (Map <String, Object>) apiCall('GET', 'courses/' + id, '');
    }

    /* Sample test code:
        CanvasAPI.findEnrollmentId('19', '60');
    */
    public static List <Object> findEnrollmentId(String userId, String courseSectionId) {
        String query =
            '?user_id=' + userId +
            '&state[]=active' +
            '&state[]=inactive';

        return (List <Object>) apiCall('GET', 'sections/' + courseSectionId + '/enrollments' + query, '');
    }

    /* Sample test code:
        CanvasAPI.reactivateEnrollment('19', '60');
    */
    public static Map <String, Object> reactivateEnrollment(String id, String courseId) {
        return (Map <String, Object>) apiCall('PUT', 'courses/' + courseId + '/enrollments/' + id + '/reactivate', '');
    }

    /* Sample test code:
        CanvasAPI.updateEnrollment('19', '60', 'deactivate');
    */
    public static Map <String, Object> updateEnrollment(String id, String courseId, String task) {
         String body = 'task=' + task;

        return (Map <String, Object>) apiCall('DELETE', 'courses/' + courseId + '/enrollments/' + id, body);
    }

    /* Sample test code:
        CanvasAPI.listUserLogins('123456');
    */
    public static List <Object> listUserLogins(String participantUID) {
        return (List <Object>) apiCall('GET', 'users/sis_user_id:' + participantUID + '/logins', '');
    }

    /* Sample test code:
        CanvasAPI.editUserLogin('123', 'test@example.org');
    */
    public static Map <String, Object> editUserLogin(String loginId, String email) {
        String body = 'login[unique_id]=' + email;

        return (Map <String, Object>) apiCall('PUT', 'accounts/:account_id/logins/' + loginId, body);
    }

    /* Sample test code:
        CanvasAPI.createEvent('user', '115', '115', 'Test Event', 'Test Description',
            DateTime.newInstance(2019, 3, 30, 10, 0, 0), DateTime.newInstance(2019, 3, 30, 12, 0 ,0),
            'Test Address');
    */
    public static Map <String, Object> createEvent(
        String context,
        String id,
        String userId,
        String title,
        String description,
        DateTime startAt,
        DateTime endAt,
        String address
    ) {
        String body =
            'calendar_event[context_code]=' + context + '_' + id +
            '&calendar_event[title]=' + title +
            '&calendar_event[description]=' + description +
            '&calendar_event[start_at]=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            '&calendar_event[end_at]=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            '&calendar_event[location_address]=' + address;

        String endpoint = 'calendar_events';

        if (null != userId) {
            endpoint = endpoint + '?as_user_id=' + userId;
        }
        return (Map <String, Object>) apiCall('POST', endpoint, body);
    }

    /* Sample test code:
        CanvasAPI.listEvents('115', DateTime.newInstance(2019, 3, 30, 10, 0, 0),
            DateTime.newInstance(2019, 3, 30, 12, 0, 0));
    */
    public static List <Object> listUserEvents(String userId, DateTime startAt, DateTime endAt) {
        String query =
            '?start_date=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            '&end_date=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            '&as_user_id=' + userId;

        return (List <Object>) apiCall('GET', 'calendar_events' + query, '');
    }

    /* Sample test code:
        CanvasAPI.removeUserEvent('115', '84');
    */
    public static Map <String, Object> removeUserEvent(String userId, String eventId) {
        return (Map <String, Object>) apiCall('DELETE', 'calendar_events/' + eventId + '?as_user_id=' + userId, '');
    }

    /* Sample test code:
        CanvasAPI.removeUserLogin('115', '84');
    */
    // public static Map <String, Object> removeUserLogin(String userId, String loginId) {
    //     return (Map <String, Object>) apiCall('DELETE', 'users/' + userId + '/logins/' + loginId, '');
    // }

    /* Sample test code:
        CanvasAPI.removeUser('115');
    */
    public static Map <String, Object> removeUser(String userId) {
        return (Map <String, Object>) apiCall('DELETE', 'accounts/:account_id/users/' + userId, '');
    }

    public static Boolean runningInASandbox() {
        return System.URL.getSalesforceBaseUrl().getHost() != 'ambitionorg.my.salesforce.com';
    }

    private static Object apiCall(String method, String endpoint, String body) {
        CanvasAPISettings__c customSettings = CanvasAPISettings__c.getOrgDefaults();
        String token = runningInASandbox() ? customSettings.Test_Token__c : customSettings.Token__c;
        String baseUrl = runningInASandbox() ? customSettings.Test_Base_Url__c : customSettings.Base_Url__c;
        String accountId = null == customSettings.Account_Id__c ? '1' : customSettings.Account_Id__c.format();
        String roleId = null == customSettings.Participant_Role_Id__c ? '13' : customSettings.Participant_Role_Id__c.format();
        HttpRequest req = new HttpRequest();

        endpoint = endpoint.replace(':account_id', accountId);
        body = body.replace(':participant_role_id', roleId);
        req.setMethod(method);
        req.setEndpoint(baseUrl + endpoint);
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(60000);

        if ('' != body) {
            req.setBody(body);
        }

        Http http = new Http();
        HTTPResponse res;

        if (Test.isRunningTest()) {
            res = LMSTest.apiMock.respond(req);
        } else {
            res = http.send(req);
        }

        String resBody = res.getBody();
        String status = res.getStatus();
        Integer statusCode = res.getStatusCode();

        System.debug('BODY: ' + resBody);
        System.debug('STATUS: ' + status);
        System.debug('STATUS_CODE: ' + statusCode);

        if (('OK' != status && 'Created' != status) || (200 > statusCode && 300 <= statusCode)) {
            throw new CanvasAPIException(String.format('{0} {1} {2}: {3}\n{4}',
                new Object[] {method, endpoint, statusCode.format(), status, resBody}));
        }

        return JSON.deserializeUntyped(resBody);
    }
}