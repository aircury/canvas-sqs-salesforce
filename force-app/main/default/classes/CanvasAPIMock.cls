@isTest
global class CanvasAPIMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatus('OK');
        res.setStatusCode(200);
        
        String endpoint = req.getEndpoint();
        
        res.setBody('{"id":"1"}');

        if (endpoint.contains('accounts/1/users?search_term=test2')) {
            res.setBody('[]');
        } 
        
        if (endpoint.contains('accounts/1/users?search_term=test1') ||
            endpoint.contains('sections/1/enrollments') ||
            endpoint.contains('calendar_events?start_date')
        ) {
            res.setBody('[{"id":"1", "enrollment_state": "deactivate"}]');
        }

        if (endpoint.contains('courses/60/enrollments/19')) {
            res.setStatusCode(503);
            res.setStatus('KO');
        }
        
        return res;
    }
}
