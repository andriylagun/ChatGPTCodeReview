public with sharing class SettleDataController {
    static final String PDS_CONST = 'PDs';
    static final String PAYMENTS_CONST = 'Payments';

    @AuraEnabled(cacheable=true)
    public static List<Contract> getFilteredSubContractsWithPDs(String objectName, String contractId,
        Date eventDateFrom, Date eventDateTo, String sale, String event,
        Date transactionDateFrom, Date transactionDateTo, String zone, String context, String region) {

        String query = 'SELECT Id, Name, ContractNumber, (SELECT Id, FIN_DistributionAmount__c, FIN_JournalEntryAmount__c ' +
            'FROM Payment_Distributions__r ';

        if (objectName == 'settlement') {
            query += ' WHERE ((FIN_Settlement_Status__c = \'ToBeSettled\' OR FIN_Settlement_Status__c = \'Voided\') AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
        } else if (objectName == 'invoice') {
            query += ' WHERE ((Invoices_Status__c = \'ToBeInvoiced\' OR Invoices_Status__c = \'Voided\') AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
        } else if (objectName == 'journalizing') {
            query += ' WHERE FIN_Journalizing_Status__c = \'ToBePosted\' AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\' ';

            if (contractId != null && contractId != '') {
                query += ' AND Contract__c = :contractId';
            }
        }

        if (context != '') {
            query += ' AND FIN_ContextID__c = :context';
        }
        if (region != '') {
            query += ' AND FIN_Region__c = :region';
        }

        if (eventDateFrom != null) {
            query += ' AND FIN_Event__r.StartDate >= :eventDateFrom';
        }
        if (eventDateTo != null) {
            query += ' AND FIN_Event__r.EndDate <= :eventDateTo';
        }
        if (transactionDateFrom != null) {
            query += ' AND FIN_DistributionDate__c >= :transactionDateFrom';
        }
        if (transactionDateTo != null) {
            query += ' AND FIN_DistributionDate__c <= :transactionDateTo';
        }
        if (sale != '') {
            query += ' AND FIN_Payment__r.FIN_Order__c = :sale';
        }
        if (event != '') {
            query += ' AND FIN_Event__c = :event';
        }
        if (zone != '') {
            query += ' AND FIN_Payment__r.FIN_Order__r.FIN_ZoneDesc__c = :zone';
        }

        if (objectName == 'journalizing') {
            query += ') FROM Contract WHERE FIN_ParentContract__c != NULL';
        } else {
            query += ') FROM Contract WHERE FIN_ParentContract__c = :contractId';
        }

        List<Contract> filteredSubContracts = new List<Contract>();
        filteredSubContracts = Database.query(query);

        List<Contract> processedSubContracts = new List<Contract>();

        for (Contract contract : filteredSubContracts) {
            if (contract.Payment_Distributions__r.size() > 0) {
                processedSubContracts.add(contract);
            }
        }
        System.debug('processedSubContracts'+processedSubContracts);

        return processedSubContracts;
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getSales(String contractId) {
        if(contractId != null) {
            return [
                SELECT Id, OrderNumber, Status
                FROM Order
                WHERE (Contract.FIN_ParentContract__c = :contractId
                OR ContractId = :contractId)
                AND ApprovalStatus__c = :'Approved'
                ORDER BY OrderNumber
                //WITH SECURITY_ENFORCED
            ];
        } else {
            return [
                SELECT Id, OrderNumber, Status
                FROM Order
                WHERE ApprovalStatus__c = :'Approved'
                ORDER BY OrderNumber
                //WITH SECURITY_ENFORCED
            ];
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getZones(String contractId) {
        if(contractId != null) {
            return [
                SELECT Id, FIN_ZoneDesc__c, Status
                FROM Order
                WHERE (Contract.FIN_ParentContract__c = :contractId
                OR ContractId = :contractId)
                AND ApprovalStatus__c = :'Approved'
                ORDER BY FIN_ZoneDesc__c
                //WITH SECURITY_ENFORCED
            ];
        } else {
            return [
                SELECT Id, FIN_ZoneDesc__c, Status
                FROM Order
                WHERE ApprovalStatus__c = :'Approved'
                ORDER BY FIN_ZoneDesc__c
                //WITH SECURITY_ENFORCED
            ];
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Campaign> getEvents(String objectName, String contractId) {
        String query = 'SELECT FIN_Event__c ' +
            'FROM FIN_PaymentDistribution__c ';

        if(contractId != null && contractId != '') {
            query += ' WHERE Contract__c = :contractId';
        }

        if (objectName == 'settlement') {
            query += ' AND ((FIN_Settlement_Status__c = \'ToBeSettled\' OR FIN_Settlement_Status__c = \'Voided\') AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
        } else if (objectName == 'invoice') {
            query += ' AND ((Invoices_Status__c = \'ToBeInvoiced\' OR Invoices_Status__c = \'Voided\') AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\') ';
        } else if (objectName == 'journalizing') {
            query += ' WHERE FIN_Journalizing_Status__c = \'ToBePosted\' AND FIN_Payment__r.FIN_Order__r.ApprovalStatus__c = \'Approved\' ';
        }

        List<FIN_PaymentDistribution__c> eventsFromPdList = new List<FIN_PaymentDistribution__c>();
        eventsFromPdList = Database.query(query);

        List<Campaign> allCampaigns = [
            SELECT Id, Name
            FROM Campaign
            ORDER BY Name
        ];

        List<Campaign> relatedEvents = new List<Campaign>();

        for (Campaign event : allCampaigns) {
            for (FIN_PaymentDistribution__c eventPD : eventsFromPdList) {
                if (event.Id == eventPD.FIN_Event__c && !relatedEvents.contains(event)) {
                    relatedEvents.add(event);
                }
            }
        }

        return relatedEvents;
    }

    @AuraEnabled(cacheable=true)
    public static List<FIN_Context__c> getContexts(String type, String region) {
        Set<Id> contextIds = new Set<Id>();

        if (type == PDS_CONST) {
            List<FIN_PaymentDistribution__c> listPDs = [
                SELECT Id, FIN_ContextName__c, FIN_ContextName__r.FIN_Active__c
                FROM FIN_PaymentDistribution__c
                WHERE FIN_ContextName__r.FIN_Active__c = TRUE
                AND FIN_Region__c =: region
            ];

            for(FIN_PaymentDistribution__c pd : listPDs) {
                if(!contextIds.contains(pd.FIN_ContextName__c)) {
                    contextIds.add(pd.FIN_ContextName__c);
                }
            }

        } else if (type == PAYMENTS_CONST) {
            List<FIN_Payment__c> listPayments = [
                SELECT Id, FIN_Order__r.FIN_OrderContext__c, FIN_Order__r.FIN_OrderContext__r.FIN_Active__c
                FROM FIN_Payment__c
                WHERE FIN_Order__r.FIN_OrderContext__r.FIN_Active__c = TRUE
                AND FIN_Region__c =: region
            ];

            for(FIN_Payment__c payment : listPayments) {
                if(!contextIds.contains(payment.FIN_Order__r.FIN_OrderContext__c)) {
                    contextIds.add(payment.FIN_Order__r.FIN_OrderContext__c);
                }
            }
        }

        List<FIN_Context__c> listContexts = [
            SELECT Id, Name
            FROM FIN_Context__c
            WHERE Id IN : contextIds
        ];

        return listContexts;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getContracts(String region) {
        return [
            SELECT Id, Name, ContractNumber
            FROM Contract
            WHERE FIN_Region__c =: region
            AND FIN_ActiveStatus__c = TRUE
            AND ActivatedDate <= TODAY
        ];
    }

    @AuraEnabled(cacheable=false)
    public static Integer createSI(List<Id> paymentDis, String settlementSh) {
        List<FIN_SettlementItem__c> newItems = new List<FIN_SettlementItem__c>();

        List<FIN_PaymentDistribution__c> listPD = [
            SELECT Id, Contract__c, FIN_LibraryAssociation__c, FIN_DistributionAmount__c
            FROM FIN_PaymentDistribution__c
            WHERE Id IN :paymentDis
        ];

        for (FIN_PaymentDistribution__c payment : listPD) {
            payment.FIN_Settlement_Status__c = 'ScheduledSettlement';
            newItems.add(new FIN_SettlementItem__c(
                FIN_PaymentDistribution__c = payment.Id,
                FIN_ParentSettlementSchedule__c = settlementSh,
                FIN_SubContract__c = payment.Contract__c,
                FIN_Amount__c = payment.FIN_DistributionAmount__c,
                FIN_LibraryAssociation__c = payment.FIN_LibraryAssociation__c
            ));
        }

        insert newItems;
        update listPD;

        return newItems.size();
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getRelatedSubContractsWithPDs(String settlementSh) {
        List<FIN_SettlementItem__c> listSI = [
            SELECT Id, FIN_PaymentDistribution__r.Contract__c
            FROM FIN_SettlementItem__c
            WHERE FIN_ParentSettlementSchedule__c = :settlementSh
        ];
        Set<String> setContractId = new Set<String>();
        Set<String> setPDIds = new Set<String>();

        for (FIN_SettlementItem__c item : listSI) {
            setContractId.add(item.FIN_PaymentDistribution__r.Contract__c);
            setPDIds.add(item.FIN_PaymentDistribution__c);
        }

        List<Contract> contractList = [
            SELECT Id, Name, ContractNumber, (
                SELECT Id, FIN_DistributionAmount__c, FIN_JournalEntryAmount__c
                FROM Payment_Distributions__r
                WHERE Id IN :setPDIds
            )
            FROM Contract
            WHERE Id IN :setContractId
        ];

        return contractList;
    }

    @AuraEnabled(cacheable=false)
    public static Integer removeRelatedSIs(List<Id> listSubContracts, String settlementSh) {
        List<FIN_SettlementItem__c> listSI = [
            SELECT Id, FIN_PaymentDistribution__r.FIN_Settlement_Status__c
            FROM FIN_SettlementItem__c
            WHERE FIN_PaymentDistribution__r.Contract__c IN :listSubContracts
            AND FIN_ParentSettlementSchedule__c = :settlementSh
        ];

        delete listSI;
        return listSI.size();
    }
}