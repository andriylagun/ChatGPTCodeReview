public with sharing class Constants {

    public static Map<String, String> getFinProcessMap() {
        Map<String, String> finProcessMap = new Map<String, String>();
        for (PicklistEntry pe : FIN_SystemDataLoadLog__c.FIN_Process__c.getDescribe().getPicklistValues()) {
            finProcessMap.put(pe.getValue(), pe.getValue() + '__c');
        }
        return finProcessMap;
    }

    public static Map<String, Integer> getOrderForSystemDataLoadLogRecords() {
        Map<String, Integer> systemDataLoadLogOrder = new Map<String, Integer>();
        for (FinanceDataRawLogsMetadata__mdt logsMetadata : FinanceDataRawLogsMetadata__mdt.getAll().values()) {
            systemDataLoadLogOrder.put(logsMetadata.Label, Math.round(logsMetadata.OrderToProcess__c));
        }
        return systemDataLoadLogOrder;
    }

    public static Set<String> idFieldsFromRuleAction = new Set<String>{'FIN_LibraryAssociation__c', 'FIN_Reviewer__c'};

    public static Map<String, String> finProcessMap = new Map<String, String>{
            'Sales' => 'Order',
            'Payment' => 'FIN_Payment__c',
            'Payment_Distribution' => 'FIN_PaymentDistribution__c',
            'Contract' => 'Contract',
            'Sales Transactions' => 'OrderItem'
    };

    public static Map<String, String> finProcessMapForSettlement = new Map<String, String>{
            'Sales' => 'Order',
            'Payment' => 'FIN_Payment__c',
            'Payment_Distribution' => 'FIN_PaymentDistribution__c',
            'Sales Transactions' => 'OrderItem'
    };

    public static String getFinObject(String finProcess) {
        String finObject = '';
        for (PicklistEntry pe : FIN_SystemDataLoadLog__c.FIN_Process__c.getDescribe().getPicklistValues()) {
            if (pe.getValue() == finProcess) {
                finObject = finProcessMap.get(finProcess);
            }
        }
        return finObject;
    }

    public static List<String> paymentDistributionsFields = new List<String>{
            'FIN_Order_ID__c', 'FIN_Payment__c'
    };

    public static Map<String, String> sObjectToFieldsMap = new Map<String, String>{
            'Order' => 'ContractId',
            'FIN_Payment__c' => 'FIN_Order__c',
            'FIN_PaymentDistribution__c' => 'FIN_Order_ID__c,FIN_Payment__c',
            'OrderItem' => 'OrderId'
    };

    public static Map<String, String> fieldsToGetMap = new Map<String, String>{
            'Order' => ', FIN_OrderContext__c, AccountId, FIN_Event__c, FIN_ZoneType__c, FIN_Venue__c, EffectiveDate, Pricebook2Id',
            'FIN_Payment__c' => ', FIN_PaymentTransactionId__c',
            'FIN_PaymentDistribution__c' => ', FIN_PaymentTransactionId__c',
            'OrderItem' => ''
    };

    public static Map<String, String> uniqueIdsMap = new Map<String, String>{
            'Sales' => 'FIN_TransactionId__c',
            'Payment' => 'FIN_Payment_Unique_ID__c',
            'Payment_Distribution' => 'FIN_Payment_Distribution_Unique_ID__c'
    };

    public static final String STANDART_SELECT_QUERY = 'SELECT :fields FROM :object WHERE :conditions';

    public static final String UNCLASSIFIED_QUEUE_US = 'FIN_US_Unclassified';

    public static final String CLASSIFIED_QUEUE_US = 'FIN_US_Classified';

    public static final String FEE_ASSOCIATION_TYPE = 'Fee';

    public static final String UNCLASSIFIED_QUERY_CONDITION = 'OwnerId = :ownerId';

    public static final String CLASSIFY_FROM_HEROKU_CONDITION = 'FIN_SystemDataLoadLog__c = :systemDataLoadLogId';

    public static final String SYSTEM_DATA_LOAD_LOG_JOB_NAME = 'Records check';

    public static final String CONTRACT_ASSOCIATION_EXCEPTION_MESSAGE = 'Contract association approval status of deactivated contract must be deactivated';

    public static final Map<String, String> contextFieldsMap = new Map<String, String>{
            Schema.Order.getSObjectType().getDescribe().getName() => Order.FIN_OrderContext__c.getDescribe().getName(),
            Schema.FIN_Payment__c.getSObjectType().getDescribe().getName() => FIN_Payment__c.FIN_Context__c.getDescribe().getName(),
            Schema.FIN_PaymentDistribution__c.getSObjectType().getDescribe().getName() => FIN_PaymentDistribution__c.FIN_ContextName__c.getDescribe().getName(),
            Schema.OrderItem.getSObjectType().getDescribe().getName() => OrderItem.FIN_ContextID__c.getDescribe().getName()
    };

    public static final Map<String, String> fieldToCheckConditions = new Map<String, String> {
            'Order' => ' AND ContractId = null AND Status != \'Approved\'',
            'FIN_Payment__c' => '',
            'FIN_PaymentDistribution__c' => ''
    };

    public static String getContextPartQueryForSObject(String sObjectName, String contextId) {
        return ' AND ' + Constants.contextFieldsMap.get(sObjectName) + '= \'' + contextId + '\'';
    }

    public static String getQueryForLibraryAssociationReclassification(String batchType) {
        switch on batchType {
            when 'OrderItem' {
                return 'SELECT Id, FIN_LibraryAssociation__c, FIN_EnrichedLibraryAssociation__c, FIN_ContextName__c, Product2.Name, FIN_Missing_Library_Association__c, FIN_FeeComponent__c, FIN_FeeComponent__r.FIN_Fee_Category__c, FIN_ContextID__c FROM OrderItem WHERE SBQQ__Contract__c = :contractId AND FIN_ContextID__c = :contextId';
            } when 'FIN_PaymentDistribution__c' {
                return 'SELECT Id, FIN_EnrichedLibraryAssociation__c, FIN_LibraryAssociation__c, FIN_ContextName__r.Name, FIN_FeeComponent__r.FIN_Fee_Category__c, FIN_FeeComponent__c, FIN_ContextID__c FROM FIN_PaymentDistribution__c WHERE Contract__c = :contractId AND FIN_ContextName__c = :contextId';
            } when 'FIN_Payment__c' {
                return 'SELECT Id, FIN_EnrichedLibraryAssociation__c, FIN_LibraryAssociation__c, FIN_ContextID__c FROM FIN_Payment__c WHERE Contract__c = :contractId AND FIN_Context__c = :contextId';
            } when else {
                throw new AuraHandledException('Wrong batch type');
            }
        }
    }

    public static String getContractFieldFromObject(String sObjectName) {
        switch on sObjectName {
            when 'Order' {
                return Order.ContractId.getDescribe().getName();
            } when 'FIN_Payment__c' {
                return FIN_Payment__c.Contract__c.getDescribe().getName();
            } when 'FIN_PaymentDistribution__c' {
                return FIN_PaymentDistribution__c.Contract__c.getDescribe().getName();
            } when 'OrderItem' {
                return OrderItem.SBQQ__Contract__c.getDescribe().getName();
            }
            when else {
                throw new AuraHandledException('Object is incorrect');
            }
        }
    }

    public static String getQueryForReclassification(String batchType, Boolean isFromContract) {
        String query = '';
        switch on batchType {
            when 'Order' {
                query = 'SELECT Id, ContractId, Pricebook2Id, EffectiveDate, FIN_TransactionId__c, FIN_ZoneType__c, FIN_OrderContext__c, FIN_Venue__c, AccountId, FIN_Reclassify__c, FIN_Event__c FROM Order WHERE Status != \'Approved\' AND ';
            } when 'FIN_PaymentDistribution__c' {
                query = 'SELECT Id, FIN_Order_ID__r.ContractId, FIN_TransactionId__c, FIN_PaymentTransactionId__c, Contract__c FROM FIN_PaymentDistribution__c WHERE ';
            } when 'FIN_Payment__c' {
                query = 'SELECT Id, FIN_Order__r.ContractId, FIN_TransactionId__c, FIN_PaymentTransactionId__c, Contract__c FROM FIN_Payment__c WHERE ';
            } when else {
                throw new AuraHandledException('Wrong batch type');
            }
        }
        if (isFromContract) {
            query += '' + getContractFieldFromObject(batchType) + ' IN :contractIds';
        }
        return query;
    }

    public static String getAssociationType(String type) {
        type = type.toLowerCase();
        switch on type {
            when 'fee' {
                return 'FEE';
            } when 'merch' {
                return 'MERCHANDISE';
            } when 'uplift' {
                return 'UPLIFT';
            } when else {
                return 'TICKET';
            }
        }
    }

    public static Decimal getTicketComponentType(String ticketComponentType) {
        if (ticketComponentType.substring(ticketComponentType.length() - 1).isNumeric()) {
            return Decimal.valueOf(ticketComponentType.substring(ticketComponentType.length() - 1));
        } else {
            return Decimal.valueOf(0);
        }
    }
}