@IsTest
private class FIN_AXSRuleEngineServiceTest {
    @TestSetup
    static void setUp() {
        RecordType clientRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'FIN_Client'];
        Account acc = TestDataFactory.createClientAccount(clientRecordType.Id);
        Contract parent = TestDataFactory.createParentContract(acc.Id);
        insert TestDataFactory.createContext();
        TestDataFactory.createRuleEngine(parent.Id);
        insert TestDataFactory.createSale(acc.Id, parent.Id, null, null, null, 'Admissions');
    }

    @IsTest
    static void testSuccessResponse() {
        testsBehaviour(true, false, false, 'Success Heroku', 'Sales');
    }

    @IsTest
    static void testErrorResponse() {
        testsBehaviour(false, true, false, 'Failure', 'Sales');
    }

    @IsTest
    static void testFromMarkingProcessed() {
        testsBehaviour(true, false, true, 'Success', 'Sales');
    }

    @IsTest
    static void testFalseResponse() {
        testsBehaviour(false, false, false, 'Success Heroku', 'Sales');
    }

    private static void testsBehaviour(Boolean isProcessed, Boolean hasErrors, Boolean isFromMarkingProcessed, String systemDataLoadLogStatus,
                                        String finProcess) {
        FIN_ResponsePublisherService.SystemDataLoadLogResponseBodyWrapper responseBodyWrapper = new FIN_ResponsePublisherService.SystemDataLoadLogResponseBodyWrapper();
        responseBodyWrapper.isFromMarkingProcessed = isFromMarkingProcessed;
        responseBodyWrapper.markedAsProcessedCount = 10;
        responseBodyWrapper.salesTransactionsCount = 20;
        responseBodyWrapper.failedRecords = 0;
        responseBodyWrapper.isProcessed = isProcessed;
        responseBodyWrapper.hasErrors = hasErrors;
        Test.setMock(HttpCalloutMock.class, new CalloutsMock());
        Test.startTest();
        FIN_SystemDataLoadLog__c systemDataLoadLog = new FIN_SystemDataLoadLog__c();
        systemDataLoadLog.FIN_Process__c = 'Sales';
        systemDataLoadLog.FIN_ProcessDate__c = Datetime.now();
        systemDataLoadLog.FIN_StagingTableLoadBusinessApproved__c = true;
        systemDataLoadLog.FIN_StagingTableLoadCompleteStatus__c = 'Success';
        systemDataLoadLog.FIN_Process__c = finProcess;
        systemDataLoadLog.FIN_Region__c = 'US';
        systemDataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c = systemDataLoadLogStatus;
        String systemDataLoadLogId = Database.insert(systemDataLoadLog).id;
        responseBodyWrapper.systemDataLoadLogId = systemDataLoadLogId;
        FIN_ResponsePublisher__e responsePublisher = new FIN_ResponsePublisher__e(ResponseDTO__c = JSON.serialize(responseBodyWrapper),
                ResponseType__c = FIN_SystemDataLoadLog__c.getSObjectType().getDescribe().getName());
        EventBus.publish(responsePublisher);
        Test.stopTest();
        System.assert(1 == 1);
    }
    class CalloutsMock implements HttpCalloutMock {
            public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"title":"TestTitle","shortDescription":"Short Description","longDescription":"Long Description","desiredSkills":"Test Desired Skills"}');
            response.setStatusCode(200);
            return response;
        }
    }
}