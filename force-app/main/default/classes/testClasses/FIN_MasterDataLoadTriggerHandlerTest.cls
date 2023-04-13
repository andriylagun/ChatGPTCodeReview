@isTest
public with sharing class FIN_MasterDataLoadTriggerHandlerTest {

@IsTest
static void sysDataLogCreationTest(){
    FIN_SystemDataLoadLog__c systemDataLoadLog = new FIN_SystemDataLoadLog__c();
    systemDataLoadLog.FIN_Process__c = 'Sales';
    systemDataLoadLog.FIN_ProcessDate__c = Datetime.now();
    systemDataLoadLog.FIN_StagingTableLoadBusinessApproved__c = true;
    systemDataLoadLog.FIN_StagingTableLoadCompleteStatus__c = 'Success';
    systemDataLoadLog.FIN_Region__c = 'US';
    systemDataLoadLog.FIN_BusinessRuleProcessCompleteStatus__c = 'In-Progress';
    insert systemDataLoadLog;

    FIN_SystemDataLoadLog__c systemDataLoadLogPayment = new FIN_SystemDataLoadLog__c();
    systemDataLoadLogPayment.FIN_Process__c = 'Payment';
    systemDataLoadLogPayment.FIN_ProcessDate__c = Datetime.now();
    systemDataLoadLogPayment.FIN_StagingTableLoadBusinessApproved__c = true;
    systemDataLoadLogPayment.FIN_StagingTableLoadCompleteStatus__c = 'Success';
    systemDataLoadLogPayment.FIN_Region__c = 'US';
    systemDataLoadLogPayment.FIN_BusinessRuleProcessCompleteStatus__c = 'In-Progress';
    insert systemDataLoadLogPayment;

    FIN_SystemDataLoadLog__c systemDataLoadLogPaymentDistr = new FIN_SystemDataLoadLog__c();
    systemDataLoadLogPaymentDistr.FIN_Process__c = 'Payment_Distribution';
    systemDataLoadLogPaymentDistr.FIN_ProcessDate__c = Datetime.now();
    systemDataLoadLogPaymentDistr.FIN_StagingTableLoadBusinessApproved__c = true;
    systemDataLoadLogPaymentDistr.FIN_StagingTableLoadCompleteStatus__c = 'Success';
    systemDataLoadLogPaymentDistr.FIN_Region__c = 'US';
    systemDataLoadLogPaymentDistr.FIN_BusinessRuleProcessCompleteStatus__c = 'In-Progress';
    insert systemDataLoadLogPaymentDistr;

    Test.setMock(HttpCalloutMock.class, new CalloutsMock());

    Test.startTest();
        Master_Data_Load__c mDL = new Master_Data_Load__c();
        mdl.ProcessDate__c = Date.today().addDays(-1);
        mdl.Sales__c = systemDataLoadLog.Id;
        mDL.Payment__c = systemDataLoadLogPayment.Id;
        mDL.Payment_Distribution__c = systemDataLoadLogPaymentDistr.Id;
        insert mDl;
    Test.stopTest();

    Assert.areEqual(1, [SELECT Id
                        FROM   Master_Data_Load__c
                        WHERE  Id = :mDL.Id].size());
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