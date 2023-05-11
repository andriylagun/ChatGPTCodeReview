global class FIN_ClassifyRecordsBatch implements Database.Batchable<SObject> {
    global String fieldToSet;
    global String fieldsToGet = 'Id, OwnerId, FIN_TransactionId__c';
    global String sObjectTypeName;
    global FIN_SystemDataLoadLog__c systemDataLoadLog;
    global FIN_Context__c context;
    global List<FIN_Context__c> contexts;
    global List<FIN_Context__c> contextsOriginal;
    global List<Id> batchJobsToExecuteInOrder;
    global List<Id> batchJobsToExecuteInOrderOriginal;

    global FIN_ClassifyRecordsBatch(String fieldToSet, String sObjectTypeName, String fieldsToGet, List<FIN_Context__c> contexts) {
        this.fieldToSet = fieldToSet;
        this.sObjectTypeName = sObjectTypeName;
        this.fieldsToGet += fieldsToGet;
        this.contexts = contexts;
        if (this.contexts != null && !this.contexts.isEmpty()) {
            this.context = contexts[0];
            this.contexts.remove(0);
        }
    }

    global FIN_ClassifyRecordsBatch(List<FIN_Context__c> contexts, List<Id> batchJobsToExecuteInOrder, List<FIN_Context__c> contextsOriginal, List<Id> batchJobsToExecuteInOrderOriginal) {
        this.contexts = contexts;
        this.contextsOriginal = contextsOriginal;
        this.batchJobsToExecuteInOrderOriginal = batchJobsToExecuteInOrderOriginal;

        if (batchJobsToExecuteInOrder.isEmpty()) {
            this.batchJobsToExecuteInOrder = this.batchJobsToExecuteInOrderOriginal.clone();
        } else {
            this.batchJobsToExecuteInOrder = batchJobsToExecuteInOrder.clone();
        }


        if (this.batchJobsToExecuteInOrder != null && !this.batchJobsToExecuteInOrder.isEmpty()) {
            this.systemDataLoadLog = FIN_SystemDataLoadLogSelector.getSystemDataLoadLogByIdIn(new List<Id>{
                    this.batchJobsToExecuteInOrder[0]
            })[0];
            this.sObjectTypeName = Constants.finProcessMap.get(this.systemDataLoadLog.FIN_Process__c);
            this.fieldToSet = Constants.sObjectToFieldsMap.get(this.sObjectTypeName);
            if (!this.fieldsToGet.containsIgnoreCase(Constants.fieldsToGetMap.get(this.sObjectTypeName))) {
                this.fieldsToGet += Constants.fieldsToGetMap.get(this.sObjectTypeName);
            }
        }
        if (this.contexts != null && !this.contexts.isEmpty()) {
            this.context = this.contexts[0];
        }


    }

    global FIN_ClassifyRecordsBatch(List<FIN_Context__c> contexts, List<Id> batchJobsToExecuteInOrder) {


        this.contextsOriginal = contexts.clone();            //set the original Context and batches once so we can loop through multiple times for ( context x  batchJobsToExecuteInOrder)
        this.batchJobsToExecuteInOrderOriginal = batchJobsToExecuteInOrder.clone();
        this.batchJobsToExecuteInOrder = batchJobsToExecuteInOrder;
        this.contexts = contexts;


        if (this.batchJobsToExecuteInOrder != null && !this.batchJobsToExecuteInOrder.isEmpty()) {
            this.systemDataLoadLog = FIN_SystemDataLoadLogSelector.getSystemDataLoadLogByIdIn(new List<Id>{
                    this.batchJobsToExecuteInOrder[0]
            })[0];
            this.sObjectTypeName = Constants.finProcessMap.get(this.systemDataLoadLog.FIN_Process__c);
            this.fieldToSet = Constants.sObjectToFieldsMap.get(this.sObjectTypeName);
            if (!this.fieldsToGet.containsIgnoreCase(Constants.fieldsToGetMap.get(this.sObjectTypeName))) {
                this.fieldsToGet += Constants.fieldsToGetMap.get(this.sObjectTypeName);
            }
        }
        if (this.contexts != null && !this.contexts.isEmpty()) {
            this.context = this.contexts[0];
            //this.contexts.remove(0);
            //this.context = this.contextsToExecute[0];
            //this.contextsToExecute.remove(0);

        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String ownerId = FIN_GroupSelector.getGroupByDeveloperName(Constants.UNCLASSIFIED_QUEUE_US).Id;
        if (this.systemDataLoadLog == null) {
            return getQueryLocator(Constants.UNCLASSIFIED_QUERY_CONDITION + Constants.fieldToCheckConditions.get(this.sObjectTypeName));
        } else {
            String systemDataLoadLogId = this.systemDataLoadLog.Id;
            return getQueryLocator(Constants.UNCLASSIFIED_QUERY_CONDITION + ' AND ' + Constants.CLASSIFY_FROM_HEROKU_CONDITION);
        }
    }

    public void execute(Database.BatchableContext context, List<SObject> records) {
        List<SObject> updatedRecordsList = new List<SObject>();
        if (!records.isEmpty()) {
            updatedRecordsList = classifyRecords(records, this.sObjectTypeName);
            Database.update(updatedRecordsList, false);
        }
    }

    public List<SObject> classifyRecords(List<SObject> records, String sObjectTypeName) {
        String ownerId = FIN_GroupSelector.getGroupByDeveloperName(Constants.CLASSIFIED_QUEUE_US).Id;
        List<SObject> updatedRecordsList = new List<SObject>();
        Map<String, Order> salesIdMap = new Map<String, Order>();
        Map<String, FIN_Payment__c> paymentIdMap = new Map<String, FIN_Payment__c>();
        List<Contract> masterContract = [SELECT Id, StartDate, EndDate, Pricebook2Id, AccountId FROM Contract WHERE FIN_ParentContract__c = NULL AND FIN_Context__c = :this.context.Id LIMIT 1];
        List<String> transactionIds = new List<String>();
        List<String> paymentTransactionIds = new List<String>();

        for (SObject record : records) {
            String transactionId = String.valueOf(record.get('FIN_TransactionId__c'));
            if (String.isNotBlank(transactionId)) {
                transactionIds.add(transactionId);
            }
            if (record.getSObjectType() == Schema.FIN_PaymentDistribution__c.getSObjectType()) {
                if (String.isNotBlank(((FIN_PaymentDistribution__c) record).FIN_PaymentTransactionId__c)) {
                    paymentTransactionIds.add(((FIN_PaymentDistribution__c) record).FIN_PaymentTransactionId__c);
                }
            }
        }
        if (sObjectTypeName == Constants.getFinObject('Sales')) {
            matchContractToSales((List<Order>) records, FIN_ContractAssociationSelector.getAllContractAssociationsByContextId(this.context.Id), ownerId, masterContract, updatedRecordsList);
        } else {
            for (Order sale : [SELECT Id, FIN_TransactionId__c, ContractId FROM Order WHERE FIN_TransactionId__c IN :transactionIds AND FIN_OrderContext__c = :this.context.Id]) {
                if (!salesIdMap.containsKey(sale.FIN_TransactionId__c)) {
                    salesIdMap.put(sale.FIN_TransactionId__c, sale);
                }
            }
        }
        if (sObjectTypeName == Constants.getFinObject('Payment_Distribution')) {
            for (FIN_Payment__c payment : [SELECT Id, FIN_PaymentTransactionId__c FROM FIN_Payment__c WHERE FIN_PaymentTransactionId__c IN :paymentTransactionIds AND FIN_Context__c = :this.context.Id]) {
                paymentIdMap.put(payment.FIN_PaymentTransactionId__c, payment);
            }
        }
        for (SObject record : records) {
            switch on record {
                when FIN_Payment__c payment {
                    Order sale = salesIdMap.get(payment.FIN_TransactionId__c);
                    if (sale != null) {
                        payment.FIN_Order__c = sale.Id;
                        payment.Contract__c = sale.ContractId;
                        payment.OwnerId = ownerId;
                    }
                    updatedRecordsList.add(payment);

                } when FIN_PaymentDistribution__c pd {
                    Order sale = salesIdMap.get(pd.FIN_TransactionId__c);
                    FIN_Payment__c pmnt = paymentIdMap.get(pd.FIN_PaymentTransactionId__c);
                    if (sale != null) {
                        pd.FIN_Order_ID__c = sale.Id;
                        pd.Contract__c = sale.ContractId;
                    }
                    if (pmnt != null) {
                        pd.FIN_Payment__c = pmnt.Id;
                    }
                    if (pd.FIN_Order_ID__c != null && pd.FIN_Payment__c != null) {
                        pd.OwnerId = ownerId;
                    }
                    updatedRecordsList.add(pd);
                }
            }
        }
        return updatedRecordsList;
    }

    public static void matchContractToSales(List<Order> records, List<ContractAssociation__c> contractAssociations, String ownerId,
            List<Contract> masterContract, List<SObject> updatedRecordsList) {
        for (ContractAssociation__c ca : contractAssociations) {
            if (!masterContract.isEmpty() && ca.Contract__c == masterContract[0].Id) {
                continue;
            }
            ContractComparingWrapper contractToCompare = new ContractComparingWrapper(ca.Context__c, ca.FIN_Venue__c, ca.Client__c, ca.FIN_AXS_Event__c, ca.FIN_Event_Zone__r.Name);
            for (Integer i = records.size() - 1; i >= 0; i--) {
                Order sale = records[i];
                ContractComparingWrapper saleToCompare = new ContractComparingWrapper(sale.FIN_OrderContext__c, sale.FIN_Venue__c, sale.AccountId, sale.FIN_Event__c, sale.FIN_ZoneType__c);
                if (String.isNotBlank(contractToCompare.contextId) && String.isNotBlank(contractToCompare.clientId)
                        && String.isNotBlank(saleToCompare.contextId) && String.isNotBlank(saleToCompare.clientId)) {
                    if (getContractMatchingLevel(contractToCompare, saleToCompare) == ca.FIN_ContractAssociationMatchingLevel__c &&
                            sale.EffectiveDate >= ca.Contract__r.StartDate && sale.EffectiveDate <= ca.Contract__r.EndDate &&
                            sale.AccountId == ca.Contract__r.AccountId && (String.isBlank(sale.Pricebook2Id) ||
                            String.isBlank(ca.Contract__r.Pricebook2Id) || (String.isNotBlank(sale.Pricebook2Id) && String.isNotBlank(ca.Contract__r.Pricebook2Id) && sale.Pricebook2Id == ca.Contract__r.Pricebook2Id))) {
                        fillSaleRecord(sale, ca, ownerId);
                        updatedRecordsList.add(sale);
                        records.remove(i);
                    }
                } else {
                    if (!masterContract.isEmpty() && sale.ContractId != masterContract[0].Id &&
                            sale.EffectiveDate >= masterContract[0].StartDate && sale.EffectiveDate <= masterContract[0].EndDate &&
                            sale.AccountId == masterContract[0].AccountId && (String.isBlank(sale.Pricebook2Id) ||
                            String.isBlank(masterContract[0].Pricebook2Id) || (String.isNotBlank(sale.Pricebook2Id) && String.isNotBlank(masterContract[0].Pricebook2Id) && sale.Pricebook2Id == masterContract[0].Pricebook2Id))) {
                        sale.ContractId = masterContract[0].Id;
                        updatedRecordsList.add(sale);
                        records.remove(i);
                    }
                }
            }
        }
    }

    public static void fillSaleRecord(Order sale, ContractAssociation__c contractAssociation, String ownerId) {
        sale.ContractId = contractAssociation.Contract__c;
        if (String.isNotBlank(ownerId)) {
            sale.OwnerId = ownerId;
        }
    }

    public void finish(Database.BatchableContext param1) {
        /* if (this.systemDataLoadLog != null && !this.batchJobsToExecuteInOrder.isEmpty()) {
             if (this.contexts.isEmpty()) {
                 Database.executeBatch(new FIN_ClassifyRecordsBatch(this.contextsToExecute, this.batchJobsToExecuteInOrder));
                 this.batchJobsToExecuteInOrder.remove(0);
             } else {
                 Database.executeBatch(new FIN_ClassifyRecordsBatch(this.contexts, this.batchJobsToExecuteInOrder));
             }
         } else if (this.systemDataLoadLog != null && this.batchJobsToExecuteInOrder.isEmpty() && this.contextsToExecute.isEmpty()) {
             FIN_AXSRuleEngineService.processSettlementRuleEngineFromSystemDataLoadLog(this.systemDataLoadLog);
         } else if (this.systemDataLoadLog == null && this.batchJobsToExecuteInOrder == null) {
             Database.executeBatch(new FIN_ClassifyRecordsBatch(this.fieldToSet, this.sObjectTypeName, this.fieldsToGet, this.contexts));
         }*/


        if (this.systemDataLoadLog != null && !this.batchJobsToExecuteInOrder.isEmpty()) {
            if (!this.batchJobsToExecuteInOrder.isEmpty()) { // this keeps looping for the same context until all batches are executed for that context.
                this.batchJobsToExecuteInOrder.remove(0);
                if (this.batchJobsToExecuteInOrder.size() > 0) {
                    system.debug('@@ checkpoint#1');
                    Database.executeBatch(new FIN_ClassifyRecordsBatch(this.contexts, this.batchJobsToExecuteInOrder, this.contextsOriginal, this.batchJobsToExecuteInOrderOriginal));
                }
            }
            System.debug('jobId: ' + param1.getJobId());
            System.debug(this.sObjectTypeName);
            system.debug('@@ checkpoint#2');
            if (!this.contexts.isEmpty() && (this.batchJobsToExecuteInOrder.isEmpty() || this.batchJobsToExecuteInOrder.size() == 0)) {
                this.contexts.remove(0); // here one one context is removed and batches repeated for all 3 processes again.
                system.debug('@@ checkpoint#3');
                if (this.contexts.size() > 0) {
                    Database.executeBatch(new FIN_ClassifyRecordsBatch(this.contexts, this.batchJobsToExecuteInOrder, this.contextsOriginal, this.batchJobsToExecuteInOrderOriginal));
                }
            }
        } else if (this.systemDataLoadLog == null && this.batchJobsToExecuteInOrder == null && !this.contexts.isEmpty()) {
            Database.executeBatch(new FIN_ClassifyRecordsBatch(this.fieldToSet, this.sObjectTypeName, this.fieldsToGet, this.contexts));
        }

        if (this.systemDataLoadLog != null && this.batchJobsToExecuteInOrder.isEmpty() && this.contexts.isEmpty()) {
            FIN_AXSRuleEngineService.processSettlementRuleEngineFromSystemDataLoadLog(this.systemDataLoadLog);
        }
    }


    public static Integer getContractMatchingLevel(ContractComparingWrapper ccw, ContractComparingWrapper sale) {
        if (String.isNotBlank(sale.venueId) && String.isNotBlank(sale.eventId) && String.isNotBlank(sale.eventZone)
                && sale.contextId == ccw.contextId && sale.venueId == ccw.venueId && sale.clientId == ccw.clientId && sale.eventId == ccw.eventId && sale.eventZone == ccw.eventZone) {
            return 8;
        }
        if (String.isNotBlank(sale.eventId) && String.isNotBlank(sale.eventZone)
                && sale.contextId == ccw.contextId && sale.clientId == ccw.clientId && sale.eventId == ccw.eventId && sale.eventZone == ccw.eventZone) {
            return 7;
        }
        if (String.isNotBlank(sale.venueId) && String.isNotBlank(sale.eventZone)
                && sale.contextId == ccw.contextId && sale.venueId == ccw.venueId && sale.clientId == ccw.clientId && sale.eventZone == ccw.eventZone) {
            return 6;
        }
        if (String.isNotBlank(sale.venueId) && String.isNotBlank(sale.eventId)
                && sale.contextId == ccw.contextId && sale.venueId == ccw.venueId && sale.clientId == ccw.clientId && sale.eventId == ccw.eventId) {
            return 5;
        }
        if (String.isNotBlank(sale.eventZone) && sale.contextId == ccw.contextId && sale.clientId == ccw.clientId && sale.eventZone == ccw.eventZone) {
            return 4;
        }
        if (String.isNotBlank(sale.eventId) && sale.contextId == ccw.contextId && sale.clientId == ccw.clientId && sale.eventId == ccw.eventId) {
            return 3;
        }
        if (String.isNotBlank(sale.venueId) && sale.contextId == ccw.contextId && sale.venueId == ccw.venueId && sale.clientId == ccw.clientId) {
            return 2;
        }
        if (ccw.contextId == sale.contextId && ccw.clientId == sale.clientId) {
            return 1;
        }
        return 0;
    }

    private Database.QueryLocator getQueryLocator(String conditions) {
        String ownerId = FIN_GroupSelector.getGroupByDeveloperName(Constants.UNCLASSIFIED_QUEUE_US).Id;
        if (this.systemDataLoadLog != null) {
            String systemDataLoadLogId = this.systemDataLoadLog.Id;
        }
        System.debug('sdloadlog: ' + this.systemDataLoadLog);
        System.debug('sobjectType: ' + this.sObjectTypeName);
        return Database.getQueryLocator(Constants.STANDART_SELECT_QUERY.replace(':fields', this.fieldsToGet + ', ' + this.fieldToSet)
                .replace(':object', this.sObjectTypeName)
                .replace(':conditions', conditions + Constants.getContextPartQueryForSObject(this.sObjectTypeName, this.context.Id)));
    }

    public class LibraryAssociationComparingWrapper {
        private String id;
        private String contextName;
        private String productName;
        private String associationType;
        private Decimal componentNumber;
        private Boolean isFeeLibraryAssociation = false;
        public LibraryAssociationComparingWrapper(String contextName, String productName, String associationType, Decimal componentNumber) {
            this.contextName = contextName;
            this.productName = productName;
            this.associationType = associationType;
            this.componentNumber = componentNumber;
            this.isFeeLibraryAssociation = associationType.toLowerCase() == Constants.FEE_ASSOCIATION_TYPE.toLowerCase();
        }

        public LibraryAssociationComparingWrapper(String contextName, String productName, String associationType) {
            this.contextName = contextName;
            this.productName = productName;
            this.associationType = associationType;
            this.isFeeLibraryAssociation = associationType.toLowerCase() == Constants.FEE_ASSOCIATION_TYPE.toLowerCase();
        }

        public LibraryAssociationComparingWrapper(String contextName, String productName, String associationType, Decimal componentNumber, String id) {
            this.contextName = contextName;
            this.productName = productName;
            this.associationType = associationType;
            this.componentNumber = componentNumber;
            this.isFeeLibraryAssociation = associationType.toLowerCase() == Constants.FEE_ASSOCIATION_TYPE.toLowerCase();
            this.id = id;
        }

        public LibraryAssociationComparingWrapper(String id) {
            this.id = id;
        }

        public Boolean equals(Object obj) {
            if (obj instanceof LibraryAssociationComparingWrapper) {
                LibraryAssociationComparingWrapper lacw = (LibraryAssociationComparingWrapper) obj;
                return (this.id != null && this.id == lacw.id) ||
                        (isFeeLibraryAssociation ? ((this.contextName != null && this.productName != null) && (this.contextName == lacw.contextName && this.productName == lacw.productName)) : ((this.contextName != null && this.productName != null && this.associationType != null && this.componentNumber != null) &&
                                (this.contextName == lacw.contextName && this.productName == lacw.productName
                                        && this.associationType == lacw.associationType && this.componentNumber == lacw.componentNumber))) ;
            }
            return false;
        }

        public override Integer hashCode() {
            return (this.contextName != null ? this.contextName.toLowerCase().hashCode() : 1) *
                    (this.productName != null ? this.productName.toLowerCase().hashCode() : 1) *
                    (this.associationType != null ? this.associationType.toLowerCase().hashCode() : 1);
        }
    }


    public class ContractComparingWrapper {
        private String contextId;
        private String venueId;
        private String clientId;
        private String eventId;
        private String eventZone;

        public ContractComparingWrapper(String contextId, String venueId, String clientId, String eventId, String eventZone) {
            this.contextId = contextId;
            this.venueId = venueId;
            this.clientId = clientId;
            this.eventId = eventId;
            this.eventZone = eventZone;
        }
    }
}