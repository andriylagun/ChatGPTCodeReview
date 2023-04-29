public with sharing class FIN_PaymentHelper {
    public static void createRetroactiveAdjustment(List<FIN_Payment__c> payments, Map<Id, FIN_Payment__c> oldMap) {
        List<FIN_RetroactiveAdjustment__c> retroactiveAdjustments = new List<FIN_RetroactiveAdjustment__c>();
        Id paymentRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Payment').getRecordTypeId();

        Map<String, String> paymentRAMap = new Map<String, String>{
            'FIN_Order__c' => 'FIN_Order__c',
            'FIN_Region__c' => 'FIN_Region__c',
            'FIN_PaymentDate__c' => 'FIN_PaymentDate__c',
            'FIN_DepositDate__c' => 'FIN_DepositDate__c',
            'FIN_PaymentAdjustment__c' => 'FIN_PaymentAdjustment__c',
            'FIN_JournalEntryAmount__c' => 'FIN_JournalEntryAmount__c'
        };

        for (FIN_Payment__c payment : payments) {
            FIN_Payment__c oldP = oldMap.get(payment.Id);
            Integer i = 0;

            FIN_RetroactiveAdjustment__c newRetroactiveAdjustment = new FIN_RetroactiveAdjustment__c();
            newRetroactiveAdjustment.FIN_Payment__c = payment.Id;
            newRetroactiveAdjustment.FIN_Order__c = payment.FIN_Order__c;
            newRetroactiveAdjustment.RecordTypeId = paymentRecordTypeId;

            for (String str : paymentRAMap.keyset()) {
                if (payment.get(str) != oldP.get(str)) {
                    newRetroactiveAdjustment.put(paymentRAMap.get(str), payment.get(str));
                    i++;
                }
            }

            if (i != 0) {
                retroactiveAdjustments.add(newRetroactiveAdjustment);
            }
        }

        insert retroactiveAdjustments;
    }

    public static void mapPaymentToRelatedSaleContract(List<FIN_Payment__c> payments) {
        for (FIN_Payment__c payment : payments) {
            if (payment.FIN_Order__r != null) {
                payment.Contract__c = payment.FIN_Order__r.ContractId;
            }
        }
    }

    public static void updateOwnerOnClassifiedRecord(List<FIN_Payment__c> payments) {
        for (FIN_Payment__c payment : payments) {
            if (!String.isBlank(payment.Owner.Name)) {
                if (payment.Owner.Name.contains('Unclassified') && !payment.FIN_PaymentUnclassified__c) {
                    payment.OwnerId = UserInfo.getUserId();
                }
            }
        }
    }

    public static void updateJournalEntrySignAndAmount(List<FIN_Payment__c> payments, Map<Id, FIN_Payment__c> oldMap) {
        Map<Id, FIN_Payment__c> paymentsWithNewJournalEntryAmount = new Map<Id, FIN_Payment__c>();
        Id paymentRecordTypeId = Schema.SObjectType.FIN_Journalizing_Item__c.getRecordTypeInfosByName().get('II Payments Record Type').getRecordTypeId();

        for (FIN_Payment__c payment : payments) {
            if (payment.FIN_PaymentAmount__c != oldMap.get(payment.Id).FIN_PaymentAmount__c && payment.FIN_Journalizing_Status__c != 'Posted') {
                paymentsWithNewJournalEntryAmount.put(payment.Id, payment);
            }
        }

        if (paymentsWithNewJournalEntryAmount.size() > 0) {
            List<FIN_Journalizing_Item__c> journalizingItems = [
                SELECT Id, FIN_Payment__c, FIN_JournalEntryAmount__c, FIN_JournalEntrySign__c
                FROM FIN_Journalizing_Item__c
                WHERE RecordTypeId = :paymentRecordTypeId
                AND FIN_Payment__c IN :paymentsWithNewJournalEntryAmount.keySet()
            ];

            if (journalizingItems.size() > 0) {
                for (FIN_Journalizing_Item__c journalizingItem : journalizingItems) {
                    journalizingItem.FIN_JournalEntryAmount__c = paymentsWithNewJournalEntryAmount.get(journalizingItem.FIN_Payment__c).FIN_JournalEntryAmount__c;
                    journalizingItem.FIN_JournalEntrySign__c = paymentsWithNewJournalEntryAmount.get(journalizingItem.FIN_Payment__c).FIN_JournalEntrySign__c;
                }

                update journalizingItems;
            }
        }
    }

    public static void updateSettlementJournalizingStatuses(List<FIN_Payment__c> payments) {
        for (FIN_Payment__c payment : payments) {
            if (payment.FIN_FinancialResponsibilty__c == 'AXS') {
                payment.FIN_Settlement_Status__c = 'ToBeSettled';
                payment.FIN_Journalizing_Status__c = 'ToBePosted';
                payment.FIN_Invoices_Status__c = 'ToBeInvoiced';
            } else if (payment.FIN_FinancialResponsibilty__c == 'N/A') {
                payment.FIN_Settlement_Status__c = 'NotApplicable';
                payment.FIN_Journalizing_Status__c = 'NotApplicable';
                payment.FIN_Invoices_Status__c = 'NotApplicable';
            }
            if (payment.FIN_Auto_Approved__c == true) {
                payment.FIN_ApprovalStatus__c = 'Approved';
            } else {
                payment.FIN_ApprovalStatus__c = 'New';
            }
        }
    }

    public static void updateApprovalStatus(List<FIN_Payment__c> payments, Map<Id, FIN_Payment__c> oldMap) {
        for (FIN_Payment__c payment : payments) {
            if (!payment.FIN_Auto_Approved__c && payment.FIN_ApprovalStatus__c == 'Approved') {
                if (payment.FIN_ApprovalStatus__c != oldMap.get(payment.Id).FIN_ApprovalStatus__c) {
                    payment.addError('Please populate the fields required for Approval: Sale, Contract, Library Association, Payment Amount');
                } else {
                    payment.FIN_ApprovalStatus__c = 'New';
                }
            } else if (payment.FIN_Auto_Approved__c && payment.FIN_ApprovalStatus__c == oldMap.get(payment.Id).FIN_ApprovalStatus__c && payment.FIN_ApprovalStatus__c == 'New') {
                payment.FIN_ApprovalStatus__c = 'Approved';
            }
        }
    }
}