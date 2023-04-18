global class ReclassifyUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Id contractId;
    global String batchType;
    global String contextId;
    global List<String> contractIds;

    global ReclassifyUpdateBatch(String batchType, String contextId, List<String> contractIds) {
        this.batchType = batchType;
        this.contextId = contextId;
        this.contractIds = contractIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> contractIds = this.contractIds;
        return Database.getQueryLocator(Constants.getQueryForReclassification(this.batchType, true));
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<String> contractIds = this.contractIds;
        List<SObject> updatedRecordsList = new List<SObject>();
        Map<String, Order> salesIdMap = new Map<String, Order>();
        List<Contract> masterContract = [SELECT Id, StartDate, EndDate, AccountId FROM Contract WHERE FIN_ParentContract__c = NULL AND Id IN :contractIds LIMIT 1];
        Map<String, FIN_Payment__c> paymentIdMap = new Map<String, FIN_Payment__c>();
        List<String> transactionIds = new List<String>();
        List<String> paymentTransactionIds = new List<String>();

        if (batchType == Schema.Order.getSObjectType().getDescribe().getName()) {
            FIN_ClassifyRecordsBatch.matchContractToSales((List<Order>) scope, FIN_ContractAssociationSelector.getAllContractAssociationsByContractIdInAndContextId(this.contextId, this.contractIds),
                    classifiedGroupId, masterContract, updatedRecordsList);
        }

        for (SObject record : scope) {
            switch on record {
                when FIN_Payment__c payment {
                    if (payment.FIN_Order__r.ContractId != payment.Contract__c) {
                        payment.Contract__c = payment.FIN_Order__r.ContractId;
                        updatedRecordsList.add(payment);
                    }
                } when FIN_PaymentDistribution__c pd {
                    if (pd.FIN_Order_ID__r.ContractId != pd.Contract__c) {
                        pd.Contract__c = pd.FIN_Order_ID__r.ContractId;
                        updatedRecordsList.add(pd);
                    }
                } when Order sale {
                    if (!masterContract.isEmpty() && sale.ContractId != masterContract[0].Id &&
                        sale.EffectiveDate >= masterContract[0].StartDate && sale.EffectiveDate <= masterContract[0].EndDate &&
                        sale.AccountId == masterContract[0].AccountId) {
                        sale.ContractId = masterContract[0].Id;
                        updatedRecordsList.add(sale);
                    }
                }
            }
        }

        if (!updatedRecordsList.isEmpty()) {
            Database.update(updatedRecordsList);
        }
    }

    public void finish(Database.BatchableContext BC) {
        if(batchType == Schema.Order.getSObjectType().getDescribe().getName()){
            Database.executeBatch(new ReclassifyUpdateBatch('FIN_Payment__c', contextId, contractIds), 500);
            Database.executeBatch(new ReclassifyUpdateBatch('FIN_PaymentDistribution__c', contextId, contractIds), 500);
        }
    }
}