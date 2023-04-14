public with sharing class  FIN_JournalizingScheduleHelper {
    static final String TOBEPOSTED_CONST = 'ToBePosted';
    static final String POSTED_CONST = 'Posted';
    static final String VOIDED_CONST = 'Voided';

    public static void updateStatusesAfterUpdate(List<Journalizing_Schedule__c> journalizings, Map<Id, Journalizing_Schedule__c> oldMap) {
        Set<Id> journalizingPostedIds = new Set<Id>();
        Set<Id> journalizingVoidIds = new Set<Id>();

        try {
            for (Journalizing_Schedule__c journalizing : journalizings) {
                if (journalizing.FIN_Status__c != oldMap?.get(journalizing.Id)?.FIN_Status__c && journalizing.FIN_Status__c == POSTED_CONST) {
                    journalizingPostedIds.add(journalizing.Id);
                } else if (journalizing.FIN_Status__c != oldMap?.get(journalizing.Id)?.FIN_Status__c && journalizing.FIN_Status__c == VOIDED_CONST) {
                    journalizingVoidIds.add(journalizing.Id);
                }
            }

            List<FIN_Journalizing_Item__c> itemsPosted = [
                SELECT Id, Payment_Distribution__c, FIN_Payment__c, Payment_Distribution__r.FIN_Payment__c
                FROM FIN_Journalizing_Item__c
                WHERE FIN_Parent_Journalizing_Schedule__c IN :journalizingPostedIds
            ];

            List<FIN_Journalizing_Item__c> itemsVoid = [
                SELECT Id, Payment_Distribution__c, FIN_Payment__c, Payment_Distribution__r.FIN_Payment__c
                FROM FIN_Journalizing_Item__c
                WHERE FIN_Parent_Journalizing_Schedule__c IN :journalizingVoidIds
            ];

            Map<String, Set<Id>> mapPDsId = new Map<String, Set<Id>>{
                POSTED_CONST => new Set<Id>(),
                VOIDED_CONST => new Set<Id>()
            };

            Map<String, Set<Id>> mapPaymentsId = new Map<String, Set<Id>>{
                POSTED_CONST => new Set<Id>(),
                VOIDED_CONST => new Set<Id>()
            };

            for (FIN_Journalizing_Item__c item : itemsPosted) {
                mapPDsId.get(POSTED_CONST).add(item.Payment_Distribution__c);
                mapPaymentsId.get(POSTED_CONST).add(item.FIN_Payment__c);
                mapPaymentsId.get(POSTED_CONST).add(item.Payment_Distribution__r.FIN_Payment__c);
            }

            for (FIN_Journalizing_Item__c item : itemsVoid) {
                mapPDsId.get(VOIDED_CONST).add(item.Payment_Distribution__c);
                mapPaymentsId.get(VOIDED_CONST).add(item.FIN_Payment__c);
                mapPaymentsId.get(VOIDED_CONST).add(item.Payment_Distribution__r.FIN_Payment__c);
            }

            System.debug('mapPDsId.values()' + mapPDsId.values());

            List<FIN_PaymentDistribution__c> pdList = [
                SELECT Id, FIN_Journalizing_Status__c
                FROM FIN_PaymentDistribution__c
                WHERE Id IN :getSet(mapPDsId)
            ];

            for (FIN_PaymentDistribution__c pd : pdList) {
                if(mapPDsId.get(POSTED_CONST).contains(pd.Id)) {
                    pd.FIN_Journalizing_Status__c = POSTED_CONST;
                } else if (mapPDsId.get(VOIDED_CONST).contains(pd.Id)) {
                    pd.FIN_Journalizing_Status__c = TOBEPOSTED_CONST;
                }
            }
            
            List<FIN_Payment__c> paymentsList = [
                SELECT Id, FIN_Journalizing_Status__c
                FROM FIN_Payment__c
                WHERE Id IN :getSet(mapPaymentsId)
            ];

            for(FIN_Payment__c payment: paymentsList) {
                if(mapPaymentsId.get(POSTED_CONST).contains(payment.Id)) {
                    payment.FIN_Journalizing_Status__c = POSTED_CONST;
                } else if (mapPaymentsId.get(VOIDED_CONST).contains(payment.Id)) {
                    payment.FIN_Journalizing_Status__c = TOBEPOSTED_CONST;
                }
            }

            update pdList;
            update paymentsList;

        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static Set<Id> getSet(Map<String,Set<Id>> mapIds) {
        Set<Id> result = new Set<Id>();
        for(Set<Id> setId : mapIds.values()){
            result.addAll(setId);
        }

        result.remove(null);
        return result;
    }
}