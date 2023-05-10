public with sharing class FIN_SettlementDataBatch implements Database.Batchable<SObject> {
    private final String query;
    private final String settlementSh;
    private final SObjectType batchType;
    private Map<String, Object> bindVariables = new Map<String, Object>();
    private final Map<Id, FIN_InvoiceSchedule__c> invoiceSh;
    private final Id currentInvoiceSh;
    private final String statusValue;
    public static Integer insertedRecordsCount = 0;

    public FIN_SettlementDataBatch() {
    }
    public FIN_SettlementDataBatch(String query, Map<String, Object> bindVariables, FIN_SettlementSchedule__c settlementSh) {
        this.batchType = Schema.FIN_SettlementItem__c.getSObjectType();
        this.query = query;
        this.settlementSh = settlementSh.Id;
        this.bindVariables = bindVariables;
    }

    public FIN_SettlementDataBatch(String query, Map<String, Object> bindVariables, Map<Id, FIN_InvoiceSchedule__c> invoiceSh, Id currentInvoiceSh) {
        this.batchType = Schema.FIN_InvoiceItem__c.getSObjectType();
        this.invoiceSh = invoiceSh;
        this.bindVariables = bindVariables;
        this.query = query;
        this.currentInvoiceSh = currentInvoiceSh;
    }


    public void execute(Database.BatchableContext param1, List<SObject> scope) {
        List<SObject> records = new List<SObject>();
        switch on batchType.newSObject() {
            when FIN_SettlementItem__c si {
                records.addAll(FIN_SettlementItemsService.createSettlementItems((List<FIN_PaymentDistribution__c>) scope, this.settlementSh));
            } when FIN_InvoiceItem__c ii {
                records.addAll(InvoiceDataController.createInvoiceItemsByType(scope.getSObjectType().getDescribe().getName(),
                        this.invoiceSh, this.currentInvoiceSh, scope));
            }
        }
        Database.update(scope);
        insertedRecordsCount = Database.insert(records).size();
    }

    public void finish(Database.BatchableContext param1) {
//        EventBus.publish(new FIN_ToastNotification__e(Status__c = 'Success',
//                Message__c = insertedRecordsCount + ' records was created successfully'));
    }

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocatorWithBinds(query, bindVariables, AccessLevel.USER_MODE);
    }
}