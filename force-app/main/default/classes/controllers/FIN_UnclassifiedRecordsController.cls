public with sharing class FIN_UnclassifiedRecordsController {
    private static String fieldsToGet = 'Id, OwnerId, FIN_TransactionId__c';
    private static List<FIN_Context__c> finContexts;

    public FIN_UnclassifiedRecordsController(ApexPages.StandardSetController stdController) {
        finContexts = FIN_ContextSelector.getAllActiveContexts();
    }

    public PageReference onSalesClassify() {
       runBatchJob(Schema.Order.getSObjectType().getDescribe().getName());
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/o/order/home');
    }

    public PageReference onPaymentsClassify() {
        runBatchJob(Schema.FIN_Payment__c.getSObjectType().getDescribe().getName());
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/o/FIN_Payment__c/home');
    }

    public PageReference onPaymentsDistributionClassify() {
        runBatchJob(Schema.FIN_PaymentDistribution__c.getSObjectType().getDescribe().getName());
        return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/o/FIN_PaymentDistribution__c/home');
    }

    public static void runBatchJob(String sObjectTypeName) {
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), finContexts);
            Database.executeBatch(recordsBatch);
    }

    public static void runBatchJob(String sObjectTypeName, FIN_SystemDataLoadLog__c systemDataLoadLog) {
            finContexts = FIN_ContextSelector.getAllActiveContexts();
            FIN_ClassifyRecordsBatch recordsBatch = new FIN_ClassifyRecordsBatch(Constants.sObjectToFieldsMap.get(sObjectTypeName), sObjectTypeName, fieldsToGet + Constants.fieldsToGetMap.get(sObjectTypeName), systemDataLoadLog, finContexts);
            Database.executeBatch(recordsBatch);
    }
}