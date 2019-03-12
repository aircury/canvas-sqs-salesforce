@isTest
global class CanvasAPIMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatus('OK');
        res.setStatusCode(200);
        
        String endpoint = req.getEndpoint();
        
        if (endpoint.contains('accounts/1/users') || endpoint.contains('sections/1/enrollments')) {
            res.setBody('[{"id":"1"}]');
        } else {
            res.setBody('{"id":"1"}');
        }

        return res;
    }
}
