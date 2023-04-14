public with sharing class FIN_SystemDataLoadLogService implements Database.AllowsCallouts {

    public static void makeCalloutToHerokuOnApprove(Map<String, String> recordIdMap) {
        makeSimpleHttpCallout(JSON.serialize(recordIdMap), 'callout:Rule_Engine_Heroku');
    }

    @Future(Callout = true)
    public static void makeSimpleHttpCallout(String body, String endpoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setBody(body);
        request.setHeader('content-type', 'application/json');
        request.setEndpoint(endpoint);
        HttpResponse response = http.send(request);
        if ((endpoint == 'callout:Records_Check_Heroku' || endpoint == 'callout:Mark_Processed_Records_Heroku') && response.getStatusCode() == 200) {
            EventBus.publish(new FIN_ResponsePublisher__e(ResponseDTO__c = response.getBody(),
                    ResponseType__c = FIN_SystemDataLoadLog__c.getSObjectType().getDescribe().getName()));
        }
    }

    public static void sendNotification(String status, String region, FIN_SystemDataLoadLog__c systemDataLoadLog) {
        String notificationTitle = '';
        String notificationBody = '';
        Set<String> profileNames = new Set<String>{'System administrator'};
        if (status == 'Success') {
            notificationTitle = 'Business rule engine successfully finished for process: ' + systemDataLoadLog.FIN_Process__c + '(Id: ' + systemDataLoadLog.Id + ')';
            notificationBody = 'You can work with your records';
        } else if (status == 'Failure') {
            notificationTitle = 'Business rule engine was failed';
            notificationBody = 'Please review rules and related records and try again';
            profileNames.add(region + ' FIN Manager');
            profileNames.add('Business admin');
        }
        List<User> users = [SELECT Id FROM User WHERE Profile.Name IN :profileNames AND IsActive = TRUE];
        Set<String> usersId = new Set<String>();
        for (User usr : users) {
            usersId.add(usr.Id);
        }
        CustomNotificationType cnt = [SELECT Id, DeveloperName  FROM CustomNotificationType WHERE DeveloperName = 'SystemDataLoadLogStatusNotification'];
        Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
        customNotification.setTitle(notificationTitle);
        customNotification.setBody(notificationBody);
        customNotification.setNotificationTypeId(cnt.Id);
        customNotification.setTargetId(systemDataLoadLog.Id);
        customNotification.send(usersId);
    }

    public static void scheduleApexJob(FIN_SystemDataLoadLog__c dataLoadLog) {
        Datetime cronDate = Datetime.now().addMinutes(3);
        String cronExpression = cronDate.format('s m H d M \'?\' yyyy');
        System.schedule(dataLoadLog.FIN_Process__c + ' ' + Constants.SYSTEM_DATA_LOAD_LOG_JOB_NAME + Integer.valueOf(Math.random() * 1000), cronExpression, new FIN_AXSRuleEngineJob(dataLoadLog));
    }

    public static void makeCalloutFromBatch(String body, String endpoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setBody(body);
        request.setHeader('content-type', 'application/json');
        request.setEndpoint(endpoint);
        http.send(request);
    }
}