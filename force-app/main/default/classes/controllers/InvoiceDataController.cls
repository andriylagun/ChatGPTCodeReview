public with sharing class InvoiceDataController {

    @AuraEnabled(cacheable=true)
    public static List<Contract> getFilteredSubContractsWithPayments(String objectName, String contractId, String sale, String event, String zone, String context, String region) {
        String query = 'SELECT Id, Name, ContractNumber, (SELECT Id, FIN_PaymentAmount__c, FIN_JournalEntryAmount__c ' +
                'FROM Payments__r ';

        if (objectName == 'invoice') {
            query += ' WHERE ((FIN_Invoices_Status__c = \'ToBeInvoiced\' OR FIN_Invoices_Status__c = \'Voided\') AND FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
        } else if (objectName == 'journalizing') {
            query += ' WHERE FIN_Journalizing_Status__c = \'ToBePosted\' AND FIN_Order__r.ApprovalStatus__c = \'Approved\' ';

            if (contractId != null && contractId != '') {
                query += ' AND Contract__c = :contractId ';
            }
        }

        if (sale != '') {
            query += ' AND FIN_Order__c = :sale';
        }
        if (event != '') {
            query += ' AND FIN_Order__r.FIN_Event__c = :event';
        }
        if (zone != '') {
            query += ' AND FIN_Order__r.FIN_ZoneDesc__c = :zone';
        }
        if (context != '') {
            query += ' AND FIN_Order__r.FIN_OrderContext__c = :context';
        }
        if (region != '') {
            query += ' AND FIN_Region__c = :region';
        }

        if (objectName == 'journalizing') {
            query += ') FROM Contract WHERE FIN_ParentContract__c != NULL';
        } else {
            query += ') FROM Contract WHERE FIN_ParentContract__c = :contractId OR (FIN_ParentContract__c != NULL AND Id = :contractId)';
        }

        List<Contract> filteredSubContracts = new List<Contract>();
        filteredSubContracts = Database.query(query);

        List<Contract> processedSubContracts = new List<Contract>();

        for (Contract contract : filteredSubContracts) {
            if (contract.Payments__r.size() > 0) {
                processedSubContracts.add(contract);
            }
        }
        System.debug('processedSubContracts' + processedSubContracts);

        return processedSubContracts;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<OrderItem>> getFilteredSubContractsWithSalesTransactions(String contractId, String sale, String event, String zone) {
        // String query = 'SELECT Id, Name, ContractNumber, (SELECT Id, FIN_TotalNetAmount__c, Quantity ' +
        //     'FROM SBQQ__OrderProducts__r ' +
        //     'WHERE FIN_Invoices_Status__c = \'ToBeInvoiced\' ' +
        //     'AND Order.ApprovalStatus__c = \'Approved\' ';

        // if (sale != '') {
        //     query += ' AND OrderId = :sale';
        // }
        // if (event != '') {
        //     query += ' AND Order.FIN_Event__c = :event';
        // }
        // if (zone != '') {
        //     query += ' AND Order.FIN_ZoneDesc__c = :zone';
        // }
        // query += ') FROM Contract WHERE FIN_ParentContract__c = :contractId OR (FIN_ParentContract__c != NULL AND Id = :contractId)';
        //


        // List<Contract> filteredSubContracts = new List<Contract>();
        // filteredSubContracts = Database.query(query);

        // List<Contract> processedSubContracts = new List<Contract>();

        // for (Contract contract : filteredSubContracts) {
        //     if (contract.SBQQ__OrderProducts__r.size() > 0) {
        //         processedSubContracts.add(contract);
        //     }
        // }

        // return processedSubContracts;
        //
        Map<Id, Contract> contractsMap = new Map<Id, Contract> ([
                SELECT Id
                        , Name
                        , ContractNumber
                FROM Contract
                WHERE FIN_ParentContract__c = :contractId
                OR (FIN_ParentContract__c != NULL AND Id = :contractId)
        ]);

        Set<Id> contactIds = contractsMap.keySet();

        String queryST = 'SELECT Id, Order.Contract.Id, FIN_TotalNetAmount__c, Quantity ' +
                'FROM OrderItem ' +
                'WHERE FIN_Invoices_Status__c = \'ToBeInvoiced\' ' +
                'AND Order.ApprovalStatus__c = \'Approved\' ';

        if (sale != '') {
            queryST += ' AND OrderId = :sale';
        }
        if (event != '') {
            queryST += ' AND Order.FIN_Event__c = :event';
        }
        if (zone != '') {
            queryST += ' AND Order.FIN_ZoneDesc__c = :zone';
        }

        queryST += ' AND Order.Contract.Id =: contactIds';


        List<OrderItem> filteredSTs = new List<OrderItem>();
        filteredSTs = Database.query(queryST);

        Map<String, List<OrderItem>> contractsToRelatedST = new Map<String, List<OrderItem>>();
        for (OrderItem oi : filteredSTs) {
            if (contractsToRelatedST.keySet().contains(JSON.serialize(contractsMap.get(oi.Order.Contract.Id)))) {
                contractsToRelatedST.get(JSON.serialize(contractsMap.get(oi.Order.Contract.Id))).add(oi);
            } else {
                contractsToRelatedST.put(JSON.serialize(contractsMap.get(oi.Order.Contract.Id)), new List<OrderItem>{
                        oi
                });
            }
        }

        return contractsToRelatedST;

    }

    @AuraEnabled(Cacheable = false)
    public static Integer createInvoiceItems(String jsonString, String type, FIN_InvoiceSchedule__c invoiceSh, Id currentInvoiceSh) {
        try {
            Map<Id, List<Id>> selectedRecords = (Map<Id, List<Id>>) JSON.deserialize(jsonString, Map<Id, List<Id>>.class);
            Map<Id, FIN_InvoiceSchedule__c> invoiceSchedules = createInvoiceSchedules(selectedRecords, invoiceSh, currentInvoiceSh, type);
            List<Id> selectedChild = getSelectedChildIds(selectedRecords);

            SOQLQueryBuilder queryBuilder = SOQLQueryBuilder.create()
                    .selectClause()
                    .field('Id')
                    .field(Constants.getLookupFieldByRelatedObjectName(type, Schema.SBQQ__ContractedPrice__c.getSObjectType().getDescribe().getName()))
                    .field(Constants.getContractFieldByType(Schema.getGlobalDescribe().get(type)))
                    .field(Constants.amountFields.get(type))
                    .endSelectSOQL()
                    .fromClause(Schema.getGlobalDescribe().get(type).getDescribe().getName())
                    .whereClause()
                    .useBindVariablesInQuery(true)
                    .condition('Id', selectedChild, Constants.ConditionType.IN_CONDITION, null, null)
                    .endWhereSOQL();
            switch on Schema.getGlobalDescribe().get(type).newSObject() {
                when FIN_Payment__c payment {
                    queryBuilder.selectClause()
                            .field(FIN_Payment__c.FIN_Invoices_Status__c.getDescribe().getName())
                            .endSelectSOQL();
                } when FIN_PaymentDistribution__c pd {
                    queryBuilder.selectClause()
                            .field(FIN_PaymentDistribution__c.Invoices_Status__c.getDescribe().getName())
                            .endSelectSOQL();
                } when OrderItem oi {
                    queryBuilder.selectClause()
                            .field(OrderItem.Quantity.getDescribe().getName())
                            .field(OrderItem.FIN_BaseRateUnitCost__c.getDescribe().getName())
                            .field(OrderItem.FIN_Invoices_Status__c.getDescribe().getName())
                            .endSelectSOQL();
                } when else {
                    throw new AuraHandledException('Type is wrong');
                }
            }
            Database.executeBatch(new FIN_SettlementDataBatch(queryBuilder.build(), queryBuilder.getBindVariables(), invoiceSchedules, currentInvoiceSh), 100);
            return selectedChild.size();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Map<Id, FIN_InvoiceSchedule__c> createInvoiceSchedules(Map<Id, List<Id>> selectedRecords, FIN_InvoiceSchedule__c invoiceSh, Id currentInvoiceSh, String type) {
        Map<Id, FIN_InvoiceSchedule__c> invoiceSchedules = new Map<Id, FIN_InvoiceSchedule__c>();
        if (currentInvoiceSh == null) {
            for (Id selectedRecord : selectedRecords.keySet()) {
                FIN_InvoiceSchedule__c invoiceSchedule = invoiceSh.clone(false);
                invoiceSchedule.FIN_Contract__c = selectedRecord;
                invoiceSchedule.FIN_Type__c = type;
                if (invoiceSh.FIN_Mode__c != null) {
                    invoiceSchedule.FIN_Mode__c = invoiceSh.FIN_Mode__c;
                } else {
                    invoiceSchedule.FIN_Mode__c = 'ByAmount';
                }
                invoiceSchedules.put(selectedRecord, invoiceSchedule);
            }
            insert invoiceSchedules.values();
        }

        return invoiceSchedules;
    }

    private static List<Id> getSelectedChildIds(Map<Id, List<Id>> selectedRecords) {
        List<Id> selectedChild = new List<Id>();

        for (Id selectedRecord : selectedRecords.keySet()) {
            selectedChild.addAll(selectedRecords.get(selectedRecord));
        }

        return selectedChild;
    }

    public static List<FIN_InvoiceItem__c> createInvoiceItemsByType(String type, Map<Id, FIN_InvoiceSchedule__c> invoiceSchedules, Id currentInvoiceSh, List<SObject> relatedRecords) {
        List<FIN_InvoiceItem__c> invoiceItems = new List<FIN_InvoiceItem__c>();
        String invoiceShId = '';
        String contractField = Constants.getContractFieldByType(relatedRecords.getSObjectType());
        String recordObjectType = relatedRecords.getSObjectType().getDescribe().getName();
        for (SObject record : relatedRecords) {
            String relatedFieldName = Constants.getLookupFieldByRelatedObjectName(Schema.FIN_InvoiceItem__c.getSObjectType().getDescribe().getName(), recordObjectType);
            String libraryAssociationLookupName = Constants.getLookupFieldByRelatedObjectName(recordObjectType,
                    Schema.SBQQ__ContractedPrice__c.getSObjectType().getDescribe().getName());
            if (currentInvoiceSh != null) {
                invoiceShId = currentInvoiceSh;
            } else {
                invoiceShId = invoiceSchedules.get(String.valueOf(record.get(contractField))).Id;
            }
            FIN_InvoiceItem__c invoiceItem = new FIN_InvoiceItem__c();
            invoiceItem.FIN_SubContract__c = String.valueOf(record.get(contractField));
            invoiceItem.put(relatedFieldName, record.get('Id'));
            invoiceItem.FIN_ParentInvoiceSchedule__c = invoiceShId;
            invoiceItem.FIN_LibraryAssociation__c = String.valueOf(record.get(libraryAssociationLookupName));
            invoiceItem.RecordTypeId = getRecordTypeIdByObjName(Constants.getPicklistEntriesByValueMapFromPicklist(FIN_InvoiceSchedule__c.FIN_Type__c.getDescribe().getPicklistValues()).get(type));
            invoiceItem.FIN_EntryType__c = 'StandardEntry';
            invoiceItem.FIN_TotalNetAmountforInvoice__c = Decimal.valueOf(Double.valueOf(record.get(Constants.amountFields.get(recordObjectType))));
            if (recordObjectType == Schema.OrderItem.getSObjectType().getDescribe().getName()) {
                Double quantity = Double.valueOf(record.get(OrderItem.Quantity.getDescribe().getName()));
                Double netAmount = Double.valueOf(record.get(OrderItem.FIN_BaseRateUnitCost__c.getDescribe().getName()));
                invoiceItem.FIN_QuantityforInvoiceQty__c = quantity;
                invoiceItem.FIN_TotalNetAmountforInvoice__c = quantity;
                invoiceItem.FIN_AmountbyQty__c = quantity * netAmount;
            }
            invoiceItems.add(invoiceItem);
            record.put(Constants.statusFields.get(FIN_InvoiceItem__c.SObjectType.getDescribe().getName()).get(record.getSObjectType().getDescribe().getName()),
                    'InvoiceScheduled');
        }
        update relatedRecords;
        return invoiceItems;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getRelatedRecords(String invoiceSh) {
        List<FIN_InvoiceItem__c> listII = [
                SELECT Id, FIN_PaymentDistribution__r.Contract__c, FIN_Payment__r.Contract__c, FIN_SalesTransactions__r.Order.Contract.Id, FIN_ParentInvoiceSchedule__r.FIN_Type__c
                FROM FIN_InvoiceItem__c
                WHERE FIN_ParentInvoiceSchedule__c = :invoiceSh
        ];
        Set<String> setContractId = new Set<String>();
        Set<String> setPDsId = new Set<String>();
        Set<String> setPaymentsId = new Set<String>();
        Set<String> setSTsId = new Set<String>();

        String type;

        if (listII.size() > 0) {
            type = listII[0]?.FIN_ParentInvoiceSchedule__r?.FIN_Type__c;
        }
        if (type == FIN_PaymentDistribution__c.SObjectType.getDescribe().getName()) {
            for (FIN_InvoiceItem__c item : listII) {
                setContractId.add(item.FIN_PaymentDistribution__r.Contract__c);
                setPDsId.add(item.FIN_PaymentDistribution__c);
            }
            return [
                    SELECT Id, Name, ContractNumber, (
                            SELECT Id, FIN_DistributionAmount__c, FIN_JournalEntryAmount__c
                            FROM Payment_Distributions__r
                            WHERE Id IN :setPDsId
                    )
                    FROM Contract
                    WHERE Id IN :setContractId
            ];
        } else if (type == FIN_Payment__c.SObjectType.getDescribe().getName()) {
            for (FIN_InvoiceItem__c item : listII) {
                setContractId.add(item.FIN_Payment__r.Contract__c);
                setPaymentsId.add(item.FIN_Payment__c);
            }
            return [
                    SELECT Id, Name, ContractNumber, (
                            SELECT Id, FIN_PaymentAmount__c, FIN_JournalEntryAmount__c
                            FROM Payments__r
                            WHERE Id IN :setPaymentsId
                    )
                    FROM Contract
                    WHERE Id IN :setContractId
            ];
        } else if (type == OrderItem.SObjectType.getDescribe().getName()) {
            for (FIN_InvoiceItem__c item : listII) {
                setContractId.add(item.FIN_SalesTransactions__r.Order.Contract.Id);
                setSTsId.add(item.FIN_SalesTransactions__c);
            }
            return [
                    SELECT Id, Name, ContractNumber, (
                            SELECT Id, FIN_TotalNetAmount__c, Quantity
                            FROM SBQQ__OrderProducts__r
                            WHERE Id IN :setSTsId
                    )
                    FROM Contract
                    WHERE Id IN :setContractId
            ];
        } else {
            return new List<Contract>();
        }
    }

    @AuraEnabled(cacheable=false)
    public static Integer removeRelatedIIs(List<Id> listSubContracts, String invoiceSh) {
        List<FIN_InvoiceItem__c> listII = [
                SELECT Id
                FROM FIN_InvoiceItem__c
                WHERE (FIN_PaymentDistribution__r.Contract__c IN :listSubContracts
                OR FIN_Payment__r.Contract__c IN :listSubContracts
                OR FIN_SalesTransactions__r.Order.Contract.Id IN :listSubContracts)
                AND FIN_ParentInvoiceSchedule__c = :invoiceSh
        ];

        delete listII;
        return listII.size();
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<OrderItem>> getRelatedSalesTransaction(String invoiceSh) {
        List<FIN_InvoiceItem__c> listII = [
                SELECT Id, FIN_SalesTransactions__r.Order.Contract.Id
                FROM FIN_InvoiceItem__c
                WHERE FIN_ParentInvoiceSchedule__c = :invoiceSh
                AND FIN_SalesTransactions__r.Order.Contract.Id != NULL
        ];
        Set<String> setContractId = new Set<String>();
        Set<String> setSTsId = new Set<String>();

        for (FIN_InvoiceItem__c item : listII) {
            setContractId.add(item.FIN_SalesTransactions__r.Order.Contract.Id);
            setSTsId.add(item.FIN_SalesTransactions__c);
        }
        Map<String, List<OrderItem>> contractsToRelatedST = new Map<String, List<OrderItem>>();

        if (!setContractId.isEmpty()) {
            Map<Id, Contract> contractsMap = new Map<Id, Contract> ([
                    SELECT Id
                            , Name
                            , ContractNumber
                    FROM Contract
                    WHERE Id IN :setContractId
            ]);

            Set<Id> contactIds = contractsMap.keySet();

            List<OrderItem> filteredSTs = [
                    SELECT Id
                            , Order.Contract.Id
                            , FIN_TotalNetAmount__c
                            , Quantity
                    FROM OrderItem
                    WHERE Id IN :setSTsId
                    AND Order.Contract.Id IN :contactIds
            ];

            for (OrderItem oi : filteredSTs) {
                if (contractsToRelatedST.keySet().contains(JSON.serialize(contractsMap.get(oi.Order.Contract.Id)))) {
                    contractsToRelatedST.get(JSON.serialize(contractsMap.get(oi.Order.Contract.Id))).add(oi);
                } else {
                    contractsToRelatedST.put(JSON.serialize(contractsMap.get(oi.Order.Contract.Id)), new List<OrderItem>{
                            oi
                    });
                }
            }

        }
        return contractsToRelatedST;
    }

    public static Id getRecordTypeIdByObjName(String type) {
        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.FIN_InvoiceItem__c.getRecordTypeInfosByDeveloperName();
        for (String rt : rts.keySet()) {
            if (rt.contains(type)) {
                return rts.get(rt).RecordTypeId;
            }
        }

        return null;
    }
}