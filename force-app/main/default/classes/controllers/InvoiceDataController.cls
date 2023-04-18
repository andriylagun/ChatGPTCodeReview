public with sharing class InvoiceDataController {
    static final String PDS_CONST = 'PDs';
    static final String PAYMENTS_CONST = 'Payments';

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
    public static List<Contract> getFilteredSubContractsWithSalesTransactions(String contractId, String sale, String event, String zone) {
        String query = 'SELECT Id, Name, ContractNumber, (SELECT Id, FIN_TotalNetAmount__c, Quantity ' +
            'FROM SBQQ__OrderProducts__r ' +
            'WHERE FIN_Invoices_Status__c = \'ToBeInvoiced\' ' +
            'AND Order.ApprovalStatus__c = \'Approved\' ';

        if (sale != '') {
            query += ' AND OrderId = :sale';
        }
        if (event != '') {
            query += ' AND Order.FIN_Event__c = :event';
        }
        if (zone != '') {
            query += ' AND Order.FIN_ZoneDesc__c = :zone';
        }
        query += ') FROM Contract WHERE FIN_ParentContract__c = :contractId OR (FIN_ParentContract__c != NULL AND Id = :contractId)';

        List<Contract> filteredSubContracts = new List<Contract>();
        filteredSubContracts = Database.query(query);

        List<Contract> processedSubContracts = new List<Contract>();

        for (Contract contract : filteredSubContracts) {
            if (contract.SBQQ__OrderProducts__r.size() > 0) {
                processedSubContracts.add(contract);
            }
        }

        return processedSubContracts;
    }

    @AuraEnabled(cacheable=false)
    public static Integer createInvoiceItems(String jsonString, String type, FIN_InvoiceSchedule__c invoiceSh, Id currentInvoiceSh) {
        try {
            Map<Id, List<Id>> selectedRecords = (Map<Id, List<Id>>) JSON.deserialize(jsonString, Map<Id, List<Id>>.class);
            Map<Id, FIN_InvoiceSchedule__c> invoiceSchedules = new Map<Id, FIN_InvoiceSchedule__c>();
            List<FIN_InvoiceItem__c> invoiceItems = new List<FIN_InvoiceItem__c>();

            List<Id> selectedChild = new List<Id>();

            if (currentInvoiceSh == null) {
                for (Id selectedRecord : selectedRecords.keySet()) {
                    FIN_InvoiceSchedule__c invoiceSchedule = invoiceSh.clone(false);
                    invoiceSchedule.FIN_Contract__c = selectedRecord;
                    invoiceSchedule.FIN_Type__c = type;
                    invoiceSchedule.FIN_Mode__c = 'ByAmount';

                    invoiceSchedules.put(selectedRecord, invoiceSchedule);
                    selectedChild.addAll(selectedRecords.get(selectedRecord));
                }

                insert invoiceSchedules.values();
            } else {
                for (Id selectedRecord : selectedRecords.keySet()) {
                    selectedChild.addAll(selectedRecords.get(selectedRecord));
                }
            }

            Id invoiceId = null;
            if (type == PDS_CONST) {
                List<FIN_PaymentDistribution__c> listPD = [
                    SELECT Id, Contract__c, FIN_LibraryAssociation__c, Invoices_Status__c, FIN_DistributionAmount__c
                    FROM FIN_PaymentDistribution__c
                    WHERE Id IN :selectedChild
                ];

                for (FIN_PaymentDistribution__c pd : listPD) {
                    if (currentInvoiceSh != null) {
                        invoiceId = currentInvoiceSh;
                    } else {
                        invoiceId = invoiceSchedules.get(pd.Contract__c).Id;
                    }

                    invoiceItems.add(new FIN_InvoiceItem__c(
                        FIN_SubContract__c = pd.Contract__c,
                        FIN_PaymentDistribution__c = pd.Id,
                        FIN_ParentInvoiceSchedule__c = invoiceId,
                        FIN_LibraryAssociation__c = pd.FIN_LibraryAssociation__c,
                        RecordTypeId = getRecordTypeIdByObjName(type),
                        FIN_EntryType__c = 'StandardEntry',
                        FIN_TotalNetAmountforInvoice__c = pd.FIN_DistributionAmount__c
                    ));
                }
            } else if (type == PAYMENTS_CONST) {
                List<FIN_Payment__c> listPayments = [
                    SELECT Id, Contract__c, FIN_Invoices_Status__c, FIN_PaymentAmount__c, FIN_LibraryAssociation__c
                    FROM FIN_Payment__c
                    WHERE Id IN :selectedChild
                ];

                for (FIN_Payment__c payment : listPayments) {
                    if (currentInvoiceSh != null) {
                        invoiceId = currentInvoiceSh;
                    } else {
                        invoiceId = invoiceSchedules.get(payment.Contract__c).Id;
                    }

                    invoiceItems.add(new FIN_InvoiceItem__c(
                        FIN_SubContract__c = payment.Contract__c,
                        FIN_Payment__c = payment.Id,
                        FIN_ParentInvoiceSchedule__c = invoiceId,
                        RecordTypeId = getRecordTypeIdByObjName(type),
                        FIN_LibraryAssociation__c = payment.FIN_LibraryAssociation__c,
                        FIN_EntryType__c = 'StandardEntry',
                        FIN_TotalNetAmountforInvoice__c = payment.FIN_PaymentAmount__c
                    ));
                }
            } else if (type == 'SalesTransactions') {
                List<OrderItem> listSalesTr = [
                    SELECT Id, SBQQ__Contract__c, FIN_LibraryAssociation__c, FIN_TotalNetAmount__c, Quantity
                    FROM OrderItem
                    WHERE Id IN :selectedChild
                ];

                for (OrderItem salesTr : listSalesTr) {
                    if (currentInvoiceSh != null) {
                        invoiceId = currentInvoiceSh;
                    } else {
                        invoiceId = invoiceSchedules.get(salesTr.SBQQ__Contract__c).Id;
                    }

                    invoiceItems.add(new FIN_InvoiceItem__c(
                        FIN_SubContract__c = salesTr.SBQQ__Contract__c,
                        FIN_SalesTransactions__c = salesTr.Id,
                        FIN_ParentInvoiceSchedule__c = invoiceId,
                        RecordTypeId = getRecordTypeIdByObjName(type),
                        FIN_LibraryAssociation__c = salesTr.FIN_LibraryAssociation__c,
                        FIN_EntryType__c = 'StandardEntry',
                        FIN_QuantityforInvoiceQty__c = salesTr.Quantity,
                        FIN_TotalNetAmountforInvoice__c = salesTr.FIN_TotalNetAmount__c
                    ));
                }
            }
            System.debug('invoiceItems'+invoiceItems);

            insert invoiceItems;
            return invoiceItems.size();
        } catch (Exception e) {
            return 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getRelatedRecords(String invoiceSh) {
        List<FIN_InvoiceItem__c> listII = [
            SELECT Id, FIN_PaymentDistribution__r.Contract__c, FIN_Payment__r.Contract__c, FIN_SalesTransactions__r.SBQQ__Contract__c, FIN_ParentInvoiceSchedule__r.FIN_Type__c
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

        if (type == PDS_CONST) {
            for (FIN_InvoiceItem__c item : listII) {
                setContractId.add(item.FIN_PaymentDistribution__r.Contract__c);
                setPDsId.add(item.FIN_PaymentDistribution__c);
            }
        } else if (type == PAYMENTS_CONST) {
            for (FIN_InvoiceItem__c item : listII) {
                setContractId.add(item.FIN_Payment__r.Contract__c);
                setPaymentsId.add(item.FIN_Payment__c);
            }
        } else if (type == 'SalesTransactions') {
            for (FIN_InvoiceItem__c item : listII) {
                setContractId.add(item.FIN_SalesTransactions__r.SBQQ__Contract__c);
                setSTsId.add(item.FIN_SalesTransactions__c);
            }
        }

        if (!setContractId.isEmpty()) {
            if (type == PDS_CONST) {
                return [
                    SELECT Id, Name, ContractNumber, (
                        SELECT Id, FIN_DistributionAmount__c, FIN_JournalEntryAmount__c
                        FROM Payment_Distributions__r
                        WHERE Id IN:setPDsId
                    )
                    FROM Contract
                    WHERE Id IN :setContractId
                ];
            } else if (type == PAYMENTS_CONST) {
                return [
                    SELECT Id, Name, ContractNumber, (
                        SELECT Id, FIN_PaymentAmount__c, FIN_JournalEntryAmount__c
                        FROM Payments__r
                        WHERE Id IN:setPaymentsId
                    )
                    FROM Contract
                    WHERE Id IN :setContractId
                ];
            } else if (type == 'SalesTransactions') {
                return [
                    SELECT Id, Name, ContractNumber, (
                        SELECT Id, FIN_TotalNetAmount__c, Quantity
                        FROM SBQQ__OrderProducts__r
                        WHERE Id IN:setSTsId
                    )
                    FROM Contract
                    WHERE Id IN :setContractId
                ];
            } else {
                return new List<Contract>();
            }
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
            OR FIN_SalesTransactions__r.SBQQ__Contract__c IN :listSubContracts)
            AND FIN_ParentInvoiceSchedule__c = :invoiceSh
        ];

        delete listII;
        return listII.size();
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