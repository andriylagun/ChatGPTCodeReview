public with sharing class JournalizingDataController {
    static final String PDS_CONST = 'PDs';
    static final String PAYMENTS_CONST = 'Payments';

    @AuraEnabled(cacheable=true)
    public static List<String> getRegionPickListValues() {
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = User.FIN_Current_Region__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(pickListVal.getLabel());
        }

        return pickListValuesList;
    }

    @AuraEnabled(cacheable=false)
    public static Integer createJI(List<Id> listIDs, String type, String journalizingSh) {
        List<FIN_Journalizing_Item__c> newItems = new List<FIN_Journalizing_Item__c>();

        if (type == 'PDs') {
            List<FIN_PaymentDistribution__c> listPD = new List<FIN_PaymentDistribution__c>();

            for (FIN_PaymentDistribution__c pd : [
                SELECT Id, FIN_Payment__c, FIN_LibraryAssociation__c, FIN_JournalEntryAmount__c, FIN_JournalEntrySign__c
                FROM FIN_PaymentDistribution__c
                WHERE Id IN :listIDs
            ]) {
                pd.FIN_Journalizing_Status__c = 'InProgress';
                newItems.add(new FIN_Journalizing_Item__c(
                    Payment_Distribution__c = pd.Id,
                    FIN_Payment__c = pd.FIN_Payment__c,
                    RecordTypeId = getRecordTypeIdByObjName(type),
                    FIN_Parent_Journalizing_Schedule__c = journalizingSh,
                    FIN_Library_Association__c = pd.FIN_LibraryAssociation__c,
                    FIN_Manual_Amount__c = pd.FIN_JournalEntryAmount__c,
                    FIN_JournalEntryAmount__c = pd.FIN_JournalEntryAmount__c,
                    FIN_JournalEntrySign__c = pd.FIN_JournalEntrySign__c
                ));

                listPD.add(pd);
            }

            if(!listPD.isEmpty()) {
                update listPD;
            }
        } else if (type == 'Payments') {
            List<FIN_Payment__c> listPayments = new List<FIN_Payment__c>();

            for (FIN_Payment__c payment : [
                SELECT Id, FIN_JournalEntryAmount__c, FIN_JournalEntrySign__c, FIN_LibraryAssociation__c
                FROM FIN_Payment__c
                WHERE Id IN :listIDs
            ]) {
                payment.FIN_Journalizing_Status__c = 'InProgress';
                newItems.add(new FIN_Journalizing_Item__c(
                    FIN_Payment__c = payment.Id,
                    FIN_Parent_Journalizing_Schedule__c = journalizingSh,
                    RecordTypeId = getRecordTypeIdByObjName(type),
                    FIN_JournalEntryAmount__c = payment.FIN_JournalEntryAmount__c,
                    FIN_JournalEntrySign__c = payment.FIN_JournalEntrySign__c,
                    FIN_Library_Association__c = payment.FIN_LibraryAssociation__c
                    // FIN_Manual_Amount__c = payment.FIN_JournalEntryAmount__c
                ));
                listPayments.add(payment);
            }

            if(!listPayments.isEmpty()) {
                update listPayments;
            }
        }

        insert newItems;

        return newItems.size();
    }

    @AuraEnabled(cacheable=true)
    public static List<Contract> getRelatedRecords(String journalizingSh) {
        List<FIN_Journalizing_Item__c> listII = [
            SELECT Id, Payment_Distribution__r.Contract__c, FIN_Payment__r.Contract__c, FIN_Parent_Journalizing_Schedule__r.FIN_Type__c
            FROM FIN_Journalizing_Item__c
            WHERE FIN_Parent_Journalizing_Schedule__c = :journalizingSh
        ];
        Set<String> setContractId = new Set<String>();
        Set<String> setPDsId = new Set<String>();
        Set<String> setPaymentsId = new Set<String>();

        String type;

        if (listII.size() > 0) {
            type = listII[0]?.FIN_Parent_Journalizing_Schedule__r?.FIN_Type__c;
        }

        if (type == PDS_CONST) {
            for (FIN_Journalizing_Item__c item : listII) {
                setContractId.add(item.Payment_Distribution__r.Contract__c);
                setPDsId.add(item.Payment_Distribution__c);

            }
        } else if (type == PAYMENTS_CONST) {
            for (FIN_Journalizing_Item__c item : listII) {
                setContractId.add(item.FIN_Payment__r.Contract__c);
                setPaymentsId.add(item.FIN_Payment__c);
            }
        }

        if (!setContractId.isEmpty()) {
            if (type == PDS_CONST) {
                return [
                    SELECT Id, Name, ContractNumber, (
                        SELECT Id, FIN_DistributionAmountNetofTaxAmount__c, FIN_JournalEntryAmount__c
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
            } else {
                return new List<Contract>();
            }
        } else {
            return new List<Contract>();
        }
    }

    @AuraEnabled(cacheable=false)
    public static Integer removeRelatedJIs(List<Id> listSubContracts, String journalizingSh) {
        List<FIN_Journalizing_Item__c> listII = [
            SELECT Id
            FROM FIN_Journalizing_Item__c
            WHERE (Payment_Distribution__r.Contract__c IN :listSubContracts
            OR FIN_Payment__r.Contract__c IN :listSubContracts)
            AND FIN_Parent_Journalizing_Schedule__c = :journalizingSh
        ];

        delete listII;
        return listII.size();
    }

    public static Id getRecordTypeIdByObjName(String type) {
        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.FIN_Journalizing_Item__c.getRecordTypeInfosByDeveloperName();

        for (String rt : rts.keySet()) {
            if (rt.contains(type)) {
                return rts.get(rt).RecordTypeId;
            }
        }

        return null;
    }
}