public with sharing class FIN_JournalizingItemHelper {
    static final String PDS_CONST = 'PDs';
    static final String PAYMENTS_CONST = 'Payments';
    static final String INPROGRESS_CONST = 'InProgress';
    static final String TOBEPOSTED_CONST = 'ToBePosted';

    public static void updateStatusesAfterInsert(List<FIN_Journalizing_Item__c> items, Map<Id, FIN_Journalizing_Item__c> oldMap) {
        try {
            Map<String, Set<Id>> mapObjIds = new Map<String, Set<Id>>{
                PDS_CONST => new Set<Id>(),
                PAYMENTS_CONST => new Set<Id>()
            };

            for (FIN_Journalizing_Item__c item : [
                SELECT Id, Payment_Distribution__c, FIN_Payment__c, Payment_Distribution__r.FIN_Payment__c
                FROM FIN_Journalizing_Item__c
                WHERE Id IN :items
            ]) {
                mapObjIds.get(PDS_CONST).add(item.Payment_Distribution__c);
                mapObjIds.get(PAYMENTS_CONST).add(item.FIN_Payment__c);
                mapObjIds.get(PAYMENTS_CONST).add(item.Payment_Distribution__r.FIN_Payment__c);
            }

            List<FIN_PaymentDistribution__c> pdList = new List<FIN_PaymentDistribution__c>();

            for (FIN_PaymentDistribution__c pd : [
                SELECT Id, FIN_Journalizing_Status__c
                FROM FIN_PaymentDistribution__c
                WHERE Id IN :mapObjIds.get(PDS_CONST)
            ]) {
                pd.FIN_Journalizing_Status__c = INPROGRESS_CONST;
                pdList.add(pd);
            }

            if (!pdList.isEmpty()) {
                update pdList;
            }

            List<FIN_Payment__c> paymentsList = new List<FIN_Payment__c>();

            for (FIN_Payment__c payment : [
                SELECT Id, FIN_Journalizing_Status__c
                FROM FIN_Payment__c
                WHERE Id IN :mapObjIds.get(PAYMENTS_CONST)
            ]) {
                payment.FIN_Journalizing_Status__c = INPROGRESS_CONST;
                paymentsList.add(payment);
            }

            if (!paymentsList.isEmpty()) {
                update paymentsList;
            }
        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static void updateStatusesBeforeDelete(Map<Id, FIN_Journalizing_Item__c> itemsInv) {
        try {
            Map<String, Set<Id>> mapObjIds = new Map<String, Set<Id>>{
                PDS_CONST => new Set<Id>(),
                PAYMENTS_CONST => new Set<Id>()
            };

            for (FIN_Journalizing_Item__c item : [
                SELECT Id, Payment_Distribution__c, FIN_Payment__c, Payment_Distribution__r.FIN_Payment__c
                FROM FIN_Journalizing_Item__c
                WHERE Id IN :itemsInv.keySet()
            ]) {
                mapObjIds.get(PDS_CONST).add(item.Payment_Distribution__c);
                mapObjIds.get(PAYMENTS_CONST).add(item.FIN_Payment__c);
                mapObjIds.get(PAYMENTS_CONST).add(item.Payment_Distribution__r.FIN_Payment__c);
            }

            List<FIN_PaymentDistribution__c> pdList = new List<FIN_PaymentDistribution__c>();
            if (!mapObjIds.get(PDS_CONST).isEmpty()) {
                for (FIN_PaymentDistribution__c pd : [
                    SELECT Id, FIN_Journalizing_Status__c, FIN_Payment__r.FIN_Order__c
                    FROM FIN_PaymentDistribution__c
                    WHERE Id IN :mapObjIds.get(PDS_CONST)
                ]) {
                    pd.FIN_Journalizing_Status__c = TOBEPOSTED_CONST;
                    pdList.add(pd);
                }
            }

            if (!pdList.isEmpty()) {
                update pdList;
            }

            List<FIN_Payment__c> paymentList = new List<FIN_Payment__c>();
            if (!mapObjIds.get(PAYMENTS_CONST).isEmpty()) {
                for (FIN_Payment__c payment : [
                    SELECT Id, FIN_Journalizing_Status__c
                    FROM FIN_Payment__c
                    WHERE Id IN :mapObjIds.get(PAYMENTS_CONST)
                ]) {
                    payment.FIN_Journalizing_Status__c = TOBEPOSTED_CONST;
                    paymentList.add(payment);
                }
            }

            if (!paymentList.isEmpty()) {
                update paymentList;
            }
        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
}