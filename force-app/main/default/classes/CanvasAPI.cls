/* This class needs a Custom Setting named as CanvasAPISettings with 3 fields:
    - Token: to store the an Access token created on Canvas with an admin user
    - Base_Url: the base url endpoint for the Canvas instance. For example https://ambition.instructure.com/api/v1.
        The base url also needs to be added on Remote Sites (Setup->Security Controls->Remote Site Settings)
    - Account_Id: Canvas account Id used to create courses or users on that Canvas account. For example: account id 1
        is the "Ambition School Leadership" main and only account on https://ambition.instructure.com
*/
public with sharing class CanvasAPI {
    /* Sample test code:
        CanvasAPI.createCourse('Test Course', 'Test', );
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
            '&course[course_format]=blended' +
            '&course[start_at]=' + startAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') +
            '&course[end_at]=' + endAt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        return apiCall('POST', 'accounts/:account_id/courses', body);
    }

    /* Sample test code:
        CanvasAPI.deleteCourse(programmes[2]);
    */
    public static Map <String, Object> deleteCourse(String id) {
        String body = 'event=delete';

        return apiCall('DELETE', 'courses/' + id, body);
    }

    /* Sample test code:
        CanvasAPI.createUser('test@example.org', 'Test User', 'Test Short Name', 'participant123');
    */
    public static Map <String, Object> createUser(String email, String name, String shortName, String participantUID) {
        String body = 
            'pseudonym[unique_id]=' + email + 
            '&user[name]=' + name +
            '&user[short_name]=' + shortName +
            '&user[time_zone]=Europe/London' +
            '&user[birthdate]=' +
            '&user[terms_of_use]=false' +
            '&user[skip_registration]=true' +
            '&pseudonym[send_confirmation]=false' +
            '&pseudonym[sis_user_id]=' + participantUID +
            //'&pseudonym[authentication_provider_id]=SAML' +
            '&pseudonym[force_self_registration]=false';

        return apiCall('POST', 'accounts/:account_id/users', body);
    }

    private static Map <String, Object> apiCall(String method, String endpoint, String body) {
        CanvasAPISettings__c customSettings = CanvasAPISettings__c.getOrgDefaults();
        String token = customSettings.Token__c;
        String baseUrl = customSettings.Base_Url__c;
        String accountId = customSettings.Account_Id__c.format();
        HttpRequest req = new HttpRequest();

        req.setMethod(method);
        req.setEndpoint(baseUrl + endpoint.replace(':account_id', accountId));
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(body);

        Http http = new Http();

        HTTPResponse res = http.send(req);

        String resBody = res.getBody();
        String status = res.getStatus();
        Integer statusCode = res.getStatusCode();

        System.debug('BODY: ' + resBody);
        System.debug('STATUS: ' + status);
        System.debug('STATUS_CODE: ' + statusCode);

        if ('OK' != status || 200 != statusCode) {
            throw new CanvasAPIException(statusCode.format() + ': ' + status);
        }

        return (Map <String, Object>) JSON.deserializeUntyped(resBody);
    }
}
