public with sharing class FIN_SettlementScheduleHelper {
    public static void updateStatusesAfterUpdate(List<FIN_SettlementSchedule__c> schedules, Map<Id, FIN_SettlementSchedule__c> oldMap) {
        Set<Id> scheduleCompleteIds = new Set<Id>();
        Set<Id> scheduleVoidIds = new Set<Id>();

        for (FIN_SettlementSchedule__c schedule : schedules) {
            if (schedule.FIN_Status__c != oldMap?.get(schedule.Id)?.FIN_Status__c && schedule.FIN_Status__c == 'Complete') {
                scheduleCompleteIds.add(schedule.Id);
            } else if (schedule.FIN_Status__c != oldMap?.get(schedule.Id)?.FIN_Status__c && schedule.FIN_Status__c == 'Void') {
                scheduleVoidIds.add(schedule.Id);
            }
        }

        List<FIN_SettlementItem__c> itemsComplete = [
            SELECT Id, FIN_PaymentDistribution__c, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c
            FROM FIN_SettlementItem__c
            WHERE FIN_ParentSettlementSchedule__c IN :scheduleCompleteIds
        ];

        List<FIN_SettlementItem__c> itemsVoid = [
            SELECT Id, FIN_PaymentDistribution__c,FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c
            FROM FIN_SettlementItem__c
            WHERE FIN_ParentSettlementSchedule__c IN :scheduleVoidIds
        ];

        Set<Id> pdCompleteIds = new Set<Id>();
        Set<Id> pdVoidIds = new Set<Id>();
        Set<Id> salesCompleteIds = new Set<Id>();
        Set<Id> salesVoidIds = new Set<Id>();

        for (FIN_SettlementItem__c item : itemsComplete) {
            pdCompleteIds.add(item.FIN_PaymentDistribution__c);
            salesCompleteIds.add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
        }

        for (FIN_SettlementItem__c item : itemsVoid) {
            pdVoidIds.add(item.FIN_PaymentDistribution__c);
            salesVoidIds.add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
        }

        List<FIN_PaymentDistribution__c> pdCompeteList = [
            SELECT Id, FIN_Settlement_Status__c
            FROM FIN_PaymentDistribution__c
            WHERE Id IN :pdCompleteIds
        ];

        List<FIN_PaymentDistribution__c> pdVoidList = [
            SELECT Id, FIN_Settlement_Status__c
            FROM FIN_PaymentDistribution__c
            WHERE Id IN :pdVoidIds
        ];

        for (FIN_PaymentDistribution__c pd : pdCompeteList) {
            pd.FIN_Settlement_Status__c = 'Settled';
        }

        for (FIN_PaymentDistribution__c pd : pdVoidList) {
            pd.FIN_Settlement_Status__c = 'Voided';
        }

        List<Order> salesCompleteList = [
            SELECT Id, Settlement_Status__c
            FROM Order
            WHERE Id IN :salesCompleteIds
        ];

        List<Order> salesVoidList = [
            SELECT Id, Settlement_Status__c
            FROM Order
            WHERE Id IN :salesVoidIds
        ];

        for (Order sales : salesCompleteList) {
            sales.Settlement_Status__c = 'Settled';
        }

        for (Order sales : salesVoidList) {
            sales.Settlement_Status__c = 'Voided';
        }

        update pdCompeteList;
        update pdVoidList;
        update salesCompleteList;
        update salesVoidList;
    }

    public static void createRemittancePayoutsAfterUpdate(List<FIN_SettlementSchedule__c> schedules, Map<Id, FIN_SettlementSchedule__c> oldMap) {
        
        Set<Id> schedulesIDs = new Set<Id>();

        for (FIN_SettlementSchedule__c schedule : schedules) {
            if (schedule.FIN_Status__c != oldMap?.get(schedule.Id)?.FIN_Status__c && schedule.FIN_Status__c == 'Remittance') {
                schedulesIDs.add(schedule.Id);
            }
        }

        List<FIN_SettlementItem__c> settlementItemsList = [
            SELECT Id, FIN_PaymentDistribution__c, FIN_Payout__c, FIN_EntryType__c, FIN_ManualAmount__c,
                    FIN_SubContract__r.FIN_RemittanceAccount__c,
                    FIN_ParentSettlementSchedule__c,
                    FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c,
                    FIN_LibraryAssociation__r.FIN_Fee_and_Component__c,
                    FIN_ParentSettlementSchedule__r.FIN_RemittanceDate__c,
                    FIN_ParentSettlementSchedule__r.FIN_PublishingDate__c,
                    FIN_ParentSettlementSchedule__r.FIN_Contract__c,
                    FIN_PaymentDistribution__r.FIN_DistributionAmount__c
            FROM FIN_SettlementItem__c
            WHERE FIN_ParentSettlementSchedule__c IN :schedulesIDs
            AND FIN_PaymentDistribution__c != null      // do we need to take only SIs of regular entry?
        ];

        Map<Id, FIN_SettlementItem__c> payeesSettlementItemMap = new Map<Id, FIN_SettlementItem__c>();
        Map<Id, List<FIN_SettlementItem__c>> payeesAllSettlementItemsMap = new Map<Id, List<FIN_SettlementItem__c>>();

        for (FIN_SettlementItem__c si : settlementItemsList) {
            payeesSettlementItemMap.put(si.FIN_SubContract__r.FIN_RemittanceAccount__c, si);
        }

        for (ID payeeID : payeesSettlementItemMap.keySet()) {
            List<FIN_SettlementItem__c> settleItemsOfThisPayee = new List<FIN_SettlementItem__c>();

            for (FIN_SettlementItem__c siCurrent : settlementItemsList) {
                if (siCurrent.FIN_SubContract__r.FIN_RemittanceAccount__c == payeeID) {
                    settleItemsOfThisPayee.add(siCurrent);    
                }
            }
            payeesAllSettlementItemsMap.put(payeeID, settleItemsOfThisPayee);
        }

        Map<Id, Double> payeeTotalAmount = new Map<Id, Double>();
        Map<Id, Double> payeeDistributionAmount = new Map<Id, Double>();
        
        if (payeesAllSettlementItemsMap.values() != null) {
            
            for (ID payeeID : payeesAllSettlementItemsMap.keySet()) {
                Double totalAmount = 0;
                Double distributionAmount = 0;
    
                for (FIN_SettlementItem__c siForCalculation : payeesAllSettlementItemsMap.get(payeeID)) {
                   
                    String ticketPriceAndComponent = siForCalculation.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c;
                    String feeAndComponent = siForCalculation.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c;
                    String criteriaString = 'Venue';

                    if (ticketPriceAndComponent != null) {
                        if (ticketPriceAndComponent.contains(criteriaString)) {
                            totalAmount += siForCalculation.FIN_PaymentDistribution__r.FIN_DistributionAmount__c;
                            System.Debug('totalAmount = ' + totalAmount);
                        } else {
                            distributionAmount += siForCalculation.FIN_PaymentDistribution__r.FIN_DistributionAmount__c;
                            System.Debug('distributionAmount = ' + distributionAmount);
                        }
                    } 
                    
                    if (feeAndComponent != null) {
                        if (feeAndComponent.contains(criteriaString)) {
                            totalAmount += siForCalculation.FIN_PaymentDistribution__r.FIN_DistributionAmount__c;
                        } else {
                            distributionAmount += siForCalculation.FIN_PaymentDistribution__r.FIN_DistributionAmount__c;
                        }
                    } 
                }
                payeeTotalAmount.put(payeeID, totalAmount);
                payeeDistributionAmount.put(payeeID, distributionAmount);
            }
        }

        List<Remittance_Payout__c> remittancePayoutsList = new List<Remittance_Payout__c>();

        for (Id payeeId : payeesSettlementItemMap.keySet()) {
            Remittance_Payout__c rp = new Remittance_Payout__c();
            rp.Payee__c = payeeId;
            rp.Due_Date__c = payeesSettlementItemMap.get(payeeId).FIN_ParentSettlementSchedule__r.FIN_RemittanceDate__c;
            rp.FIN_PublishDate__c = payeesSettlementItemMap.get(payeeId).FIN_ParentSettlementSchedule__r.FIN_PublishingDate__c;
            rp.FIN_SettlementSchedule__c = payeesSettlementItemMap.get(payeeId).FIN_ParentSettlementSchedule__c;
            rp.Contract__c = payeesSettlementItemMap.get(payeeId).FIN_ParentSettlementSchedule__r.FIN_Contract__c;
            rp.FIN_RemittancePayoutAmount__c = payeeTotalAmount.get(payeeId);
            rp.Distribution_Amount__c = payeeDistributionAmount.get(payeeId);

            remittancePayoutsList.add(rp);
        }

        insert remittancePayoutsList;
    }
}