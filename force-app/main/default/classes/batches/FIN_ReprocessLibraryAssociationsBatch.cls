public with sharing class FIN_ReprocessLibraryAssociationsBatch implements Database.Batchable<SObject> {

    private String contractId;
    private List<Contract> contracts;
    private String batchType;
    private String contextId;

    public FIN_ReprocessLibraryAssociationsBatch(List<Contract> contracts, String contextId, String batchType) {
        this.batchType = batchType;
        this.contextId = contextId;
        this.contracts = contracts;
        if (!this.contracts.isEmpty()) {
            this.contractId = contracts[0].Id;
            this.contracts.remove(0);
        }
    }
    public FIN_ReprocessLibraryAssociationsBatch() {
    }

    public void execute(Database.BatchableContext param1, List<SObject> param2) {
        List<SObject> updatedRecordsList = new List<SObject>();
        Map<FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper, SBQQ__ContractedPrice__c> libraryAssociationsMap = new Map<FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper, SBQQ__ContractedPrice__c>();
        for (SBQQ__ContractedPrice__c la : FIN_LibraryAssociationSelector.getLibraryAssociationsForReclassificationByContextId(this.contextId)) {
            libraryAssociationsMap.put(new FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper(la.FIN_ContextName__c, la.FIN_Fee_Category__c != null ? String.valueOf(la.FIN_Fee_Category__c) : la.FIN_ProductName__c, la.Association_Type__c, la.FIN_Component_Number__c != null ? la.FIN_Component_Number__c : null, la.Id), la);
        }
        for (SObject record : param2) {
            if (String.isBlank((String) record.get('FIN_LibraryAssociation__c'))) {
                FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper lacw;
                if (record.getSObjectType().getDescribe().getName() == Schema.OrderItem.getSObjectType().getDescribe().getName()) {
                    OrderItem oi = (OrderItem) record;
                    if (oi.FIN_FeeComponent__c == null) {
                        lacw = new FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper(oi.FIN_ContextName__c.toLowerCase(), oi.Product2.Name.toLowerCase(), Constants.getAssociationType(oi.Product2.Name).toLowerCase(), Constants.getTicketComponentType(oi.Product2.Name), oi.FIN_EnrichedLibraryAssociation__c);
                    } else {
                        lacw = new FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper(oi.FIN_ContextName__c.toLowerCase(), oi.FIN_FeeComponent__r.FIN_Fee_Category__c, Constants.getAssociationType('fee').toLowerCase());
                    }
                }
                if (record.getSObjectType().getDescribe().getName() == Schema.FIN_PaymentDistribution__c.getSObjectType().getDescribe().getName()) {
                    FIN_PaymentDistribution__c paymentDistribution = (FIN_PaymentDistribution__c) record;
                    if (paymentDistribution.FIN_FeeComponent__c != null) {
                        lacw = new FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper(paymentDistribution.FIN_ContextName__r.Name.toLowerCase(), paymentDistribution.FIN_FeeComponent__r.FIN_Fee_Category__c, Constants.getAssociationType('fee').toLowerCase());
                    }
                }
                String enrichedLibAssoc = (String) record.get('FIN_EnrichedLibraryAssociation__c');
                if (String.isNotBlank(enrichedLibAssoc) && lacw == null) {
                    lacw = new FIN_ClassifyRecordsBatch.LibraryAssociationComparingWrapper(enrichedLibAssoc);
                }
                if (libraryAssociationsMap.containsKey(lacw)) {
                    SBQQ__ContractedPrice__c libraryAssociation = libraryAssociationsMap.get(lacw);
                    if (libraryAssociation.FIN_Context__c == record.get(Constants.contextFieldsMap.get(record.getSObjectType().getDescribe().getName()))) {
                        record.put('FIN_LibraryAssociation__c', libraryAssociationsMap.get(lacw).Id);
                    }
                    if (this.batchType == OrderItem.getSObjectType().getDescribe().getName() && (((Boolean) record.get('FIN_Missing_Library_Association__c')) == true)) {
                        record.put('FIN_Missing_Library_Association__c', false);
                    }
                    updatedRecordsList.add(record);
                }
            }
        }
        update updatedRecordsList;
    }

    public void finish(Database.BatchableContext param1) {
        if (!this.contracts.isEmpty()) {
            Database.executeBatch(new FIN_ReprocessLibraryAssociationsBatch(this.contracts, this.contextId, this.batchType));
        }
    }

    public Database.QueryLocator start(Database.BatchableContext param1) {
        return Database.getQueryLocator(Constants.getQueryForLibraryAssociationReclassification(this.batchType));
    }
}