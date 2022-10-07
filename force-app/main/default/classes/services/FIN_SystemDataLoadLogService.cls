public with sharing class FIN_SystemDataLoadLogService {

    @Future(Callout = true)
    public static void makeCalloutToHerokuOnApprove(Id recordId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setHeader('approved', 'true');
        request.setHeader('dataLoadLogId', recordId);
        request.setEndpoint('callout:Rule_Engine_Heroku');
        HttpResponse resp = http.send(request);
        System.debug(resp);
    }
}