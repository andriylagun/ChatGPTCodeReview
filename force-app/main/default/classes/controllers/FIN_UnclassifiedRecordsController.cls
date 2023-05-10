public with sharing class FIN_UnclassifiedRecordsController {
    private static List<FIN_Context__c> finContexts;

    public FIN_UnclassifiedRecordsController(ApexPages.StandardSetController stdController) {
        finContexts = FIN_ContextSelector.getAllActiveContexts();
    }

    public PageReference onSalesClassify() {
        runBatchJob(Schema.Order.getSObjectType().getDescribe().getName());
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/order/home');
    }

    public PageReference onPaymentsClassify() {
        runBatchJob(Schema.FIN_Payment__c.getSObjectType().getDescribe().getName());
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/FIN_Payment__c/home');
    }

    public PageReference onPaymentsDistributionClassify() {
        runBatchJob(Schema.FIN_PaymentDistribution__c.getSObjectType().getDescribe().getName());
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/FIN_PaymentDistribution__c/home');
    }

    public static void runBatchJob(String sObjectTypeName) {
        FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
        Database.executeBatch(recordsBatch);
    }

    public static void runBatchJob(Master_Data_Load__c mdl) {
        finContexts = FIN_ContextSelector.getAllActiveContexts();
        List<Id> systemDataLoadLogIds = new List<Id>{mdl.Payment_Distribution__c, mdl.Payment__c, mdl.Sales__c};
        FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(finContexts, systemDataLoadLogIds);
        Database.executeBatch(recordsBatch);
    }
}