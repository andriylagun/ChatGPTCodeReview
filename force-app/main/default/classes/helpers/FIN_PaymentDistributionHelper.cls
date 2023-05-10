public with sharing class FIN_PaymentDistributionHelper {
    public static void updateJournalEntrySignAndAmount(List<FIN_PaymentDistribution__c> pds, Map<Id, FIN_PaymentDistribution__c> oldMap) {
        Map<Id, FIN_PaymentDistribution__c> pdsWithNewJournalEntryAmount = new Map<Id, FIN_PaymentDistribution__c>();
        Id pdRecordTypeId = Schema.SObjectType.FIN_Journalizing_Item__c.getRecordTypeInfosByName().get('II PDs Record Type').getRecordTypeId();

        for (FIN_PaymentDistribution__c pd : pds) {
            if (pd.FIN_DistributionAmount__c != oldMap.get(pd.Id).FIN_DistributionAmount__c && pd.FIN_Journalizing_Status__c != 'Posted') {
                pdsWithNewJournalEntryAmount.put(pd.Id, pd);
            }
        }

        if (pdsWithNewJournalEntryAmount.size() > 0) {
            List<FIN_Journalizing_Item__c> journalizingItems = [
                SELECT Id, Payment_Distribution__c, FIN_JournalEntryAmount__c, FIN_JournalEntrySign__c
                FROM FIN_Journalizing_Item__c
                WHERE RecordTypeId = :pdRecordTypeId
                AND Payment_Distribution__c IN :pdsWithNewJournalEntryAmount.keySet()
            ];

            if (journalizingItems.size() > 0) {
                for (FIN_Journalizing_Item__c journalizingItem : journalizingItems) {
                    journalizingItem.FIN_JournalEntryAmount__c = pdsWithNewJournalEntryAmount.get(journalizingItem.Payment_Distribution__c).FIN_JournalEntryAmount__c;
                    journalizingItem.FIN_JournalEntrySign__c = pdsWithNewJournalEntryAmount.get(journalizingItem.Payment_Distribution__c).FIN_JournalEntrySign__c;
                }

                update journalizingItems;
            }
        }
    }

    public static void createRetroactiveAdjustment(List<FIN_PaymentDistribution__c> pdDistributions, Map<Id, FIN_PaymentDistribution__c> oldMap) {
        List<FIN_RetroactiveAdjustment__c> retroactiveAdjustments = new List<FIN_RetroactiveAdjustment__c>();
        Id pdDistributionRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Payment Distribution').getRecordTypeId();

        Map<String, String> pdDistributionRAMap = new Map<String, String>{
            'FIN_Region__c' => 'FIN_Region__c',
            'FIN_OrderProduct__c' => 'FIN_OrderProduct__c',
            'FIN_DistributionDate__c' => 'FIN_DistributionDate__c',
            'FIN_DistributionAmount__c' => 'FIN_DistributionAmount__c',
            'FIN_DistributionAmountTaxIncluded__c' => 'FIN_DistributionAmountTaxIncluded__c',
            'FIN_DistributionAmountTaxAmount__c' => 'FIN_DistributionAmountTaxAmount__c',
            'FIN_DistributionAmountNetofTaxAmount__c' => 'FIN_DistributionAmountNetofTaxAmount__c',
            'FIN_AdjustmentAmount__c' => 'FIN_AdjustmentAmount__c'
        };

        for (FIN_PaymentDistribution__c pdDistribution : pdDistributions) {
            if (pdDistribution.FIN_AdjustmentAmount__c != oldMap.get(pdDistribution.Id).FIN_AdjustmentAmount__c) {
                FIN_PaymentDistribution__c oldPD = oldMap.get(pdDistribution.Id);

                FIN_RetroactiveAdjustment__c newRetroactiveAdjustment = new FIN_RetroactiveAdjustment__c();
                newRetroactiveAdjustment.FIN_PaymentDistribution__c = pdDistribution.Id;
                newRetroactiveAdjustment.FIN_OrderProduct__c = pdDistribution.FIN_OrderProduct__c;
                newRetroactiveAdjustment.RecordTypeId = pdDistributionRecordTypeId;

                for (String str : pdDistributionRAMap.keyset()) {
                    if (pdDistribution.get(str) != oldPD.get(str)) {
                        newRetroactiveAdjustment.put(pdDistributionRAMap.get(str), pdDistribution.get(str));
                    }
                }

                retroactiveAdjustments.add(newRetroactiveAdjustment);
            }
        }
        if (!retroactiveAdjustments.isEmpty()) {
                insert retroactiveAdjustments;
        }
    }

    public static void updateOwnerOnClassifiedRecord(List<FIN_PaymentDistribution__c> paymentDistributions) {
        for (FIN_PaymentDistribution__c pd : paymentDistributions) {
            if (!String.isBlank(pd.Owner.Name)) {
                System.debug('pd.Owner' + pd.Owner.Name.contains('Unclassified'));
                if (pd.Owner.Name.contains('Unclassified') && !pd.FIN_PDUnclassified__c) {
                    pd.OwnerId = UserInfo.getUserId();
                }
            }
        }
    }

    public static void updateSettlementJournalizingStatuses(List<FIN_PaymentDistribution__c> paymentDistributions) {
        for (FIN_PaymentDistribution__c pd : paymentDistributions) {
            if (pd.FIN_FinancialResponsibilty__c == 'AXS') {
                pd.FIN_Settlement_Status__c = 'ToBeSettled';
                pd.FIN_Journalizing_Status__c = 'ToBePosted';
                pd.Invoices_Status__c = 'ToBeInvoiced';
            } else if (pd.FIN_FinancialResponsibilty__c == 'N/A') {
                pd.FIN_Settlement_Status__c = 'NotApplicable';
                pd.FIN_Journalizing_Status__c = 'NotApplicable';
                pd.Invoices_Status__c = 'NotApplicable';
            }
            if (pd.FIN_Auto_Approved__c == true) {
                pd.FIN_ApprovalStatus__c = 'Approved';
            } else {
                pd.FIN_ApprovalStatus__c = 'New';
            }
        }
    }

    public static void updateApprovalStatus(List<FIN_PaymentDistribution__c> paymentDistributions, Map<Id, FIN_PaymentDistribution__c> oldMap) {
        for (FIN_PaymentDistribution__c pd : paymentDistributions) {
            if (!pd.FIN_Auto_Approved__c && pd.FIN_ApprovalStatus__c == 'Approved') {
                if (pd.FIN_ApprovalStatus__c != oldMap.get(pd.Id).FIN_ApprovalStatus__c) {
                    pd.addError('Please populate the fields required for Approval: Contract, Payment, Library Association, Distribution Amount');
                } else {
                    pd.FIN_ApprovalStatus__c = 'New';
                }
            } else if (pd.FIN_Auto_Approved__c && pd.FIN_ApprovalStatus__c == oldMap.get(pd.Id).FIN_ApprovalStatus__c && pd.FIN_ApprovalStatus__c == 'New') {
                pd.FIN_ApprovalStatus__c = 'Approved';
            }
        }
    }
}