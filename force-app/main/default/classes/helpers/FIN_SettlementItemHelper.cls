public with sharing class FIN_SettlementItemHelper {

    public static void updateStatusesAfterInsert(List<FIN_SettlementItem__c> items, Map<Id, FIN_SettlementItem__c> oldMap) {
        Set<Id> pdIds = new Set<Id>();
        Set<Id> salesIds = new Set<Id>();

        if (!items.isEmpty()) {
            String statusToSet = 'ScheduledSettlement';
            SOQLQueryBuilder itemsQueryBuilder = SOQLQueryBuilder.create()
                    .selectClause()
                    .field(FIN_SettlementItem__c.Id.getDescribe().getName())
                    .field('FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c')
                    .field(FIN_SettlementItem__c.FIN_PaymentDistribution__c.getDescribe().getName())
                    .endSelectSOQL()
                    .fromClause(Schema.SObjectType.FIN_SettlementItem__c.getName())
                    .whereClause()
                    .useBindVariablesInQuery(true)
                    .condition(FIN_SettlementItem__c.Id.getDescribe().getName(), items, Constants.ConditionType.IN_CONDITION, null, null)
                    .endWhereSOQL();
            List<FIN_SettlementItem__c> settlementItems = Database.queryWithBinds(itemsQueryBuilder.build(), itemsQueryBuilder.getBindVariables(), AccessLevel.USER_MODE);
            for (FIN_SettlementItem__c settlementItem : settlementItems) {
                pdIds.add(settlementItem.FIN_PaymentDistribution__c);
                salesIds.add(settlementItem.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
            }


            SOQLQueryBuilder salesQueryBuilder = new SOQLQueryBuilder()
                    .selectClause()
                    .field(Order.Id.getDescribe().getName())
                    .field(Order.Settlement_Status__c.getDescribe().getName())
                    .endSelectSOQL()
                    .fromClause(Order.SObjectType.getDescribe().getName())
                    .whereClause()
                    .useBindVariablesInQuery(true)
                    .condition(Order.Id.getDescribe().getName(),
                            (Object) salesIds, Constants.ConditionType.IN_CONDITION, null, null)
                    .endWhereSOQL();

            SOQLQueryBuilder pdQueryBuilder = new SOQLQueryBuilder()
                    .selectClause()
                    .field(FIN_PaymentDistribution__c.Id.getDescribe().getName())
                    .field(FIN_PaymentDistribution__c.FIN_Settlement_Status__c.getDescribe().getName())
                    .endSelectSOQL()
                    .fromClause(Schema.SObjectType.FIN_PaymentDistribution__c.getName())
                    .whereClause()
                    .useBindVariablesInQuery(true)
                    .condition(FIN_PaymentDistribution__c.Id.getDescribe().getName(),
                            pdIds, Constants.ConditionType.IN_CONDITION, null, null)
                    .endWhereSOQL();

            List<FIN_PaymentDistribution__c> paymentDistributions = Database.queryWithBinds(pdQueryBuilder.build(), pdQueryBuilder.getBindVariables(), AccessLevel.USER_MODE);
            for (FIN_PaymentDistribution__c pd : paymentDistributions) {
                pd.FIN_Settlement_Status__c = statusToSet;
            }
            update paymentDistributions;
            List<Order> sales = Database.queryWithBinds(salesQueryBuilder.build(), salesQueryBuilder.getBindVariables(), AccessLevel.USER_MODE);
            for (Order ord : sales) {
                ord.Settlement_Status__c = statusToSet;
            }
            update sales;
        }
    }


    public static void updateStatusesBeforeDelete(Map<Id, FIN_SettlementItem__c> itemsSett) {
        Set<Id> pdIds = new Set<Id>();
        Set<Id> salesIds = new Set<Id>();
        Map<Id, List<Id>> salesDeletedMap = new Map<Id, List<Id>>();

        try {
            for (FIN_SettlementItem__c item : [
                    SELECT Id, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c, FIN_PaymentDistribution__c
                    FROM FIN_SettlementItem__c
                    WHERE Id IN :itemsSett.keySet()
            ]) {
                pdIds.add(item.FIN_PaymentDistribution__c);
                if (salesDeletedMap.containsKey(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c)) {
                    salesDeletedMap.get(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c).add(item.FIN_PaymentDistribution__c);
                } else {
                    salesDeletedMap.put(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c, new List<Id>{
                            item.FIN_PaymentDistribution__c
                    });
                }
            }

            List<FIN_PaymentDistribution__c> pdList = new List<FIN_PaymentDistribution__c>();

            for (FIN_PaymentDistribution__c pd : [
                    SELECT Id, FIN_Settlement_Status__c, FIN_Payment__r.FIN_Order__c
                    FROM FIN_PaymentDistribution__c
                    WHERE Id IN :pdIds
            ]) {
                pd.FIN_Settlement_Status__c = 'ToBeSettled';
                pdList.add(pd);
            }
            if (!pdList.isEmpty()) {
                update pdList;
            }

            AggregateResult[] groupedResults = [
                    SELECT FIN_Payment__r.FIN_Order__c ord, COUNT(Id) quan
                    FROM FIN_PaymentDistribution__c
                    WHERE FIN_Payment__r.FIN_Order__c IN :salesDeletedMap.keySet()
                    GROUP BY FIN_Payment__r.FIN_Order__c
            ];

            for (AggregateResult ar : groupedResults) {
                if (salesDeletedMap.get((Id) ar.get('ord')).size() == Integer.valueOf(ar.get('quan'))) {
                    salesIds.add((Id) ar.get('ord'));
                }
            }

            List<Order> salesList = new List<Order>();

            for (Order sales : [
                    SELECT Id, Settlement_Status__c
                    FROM Order
                    WHERE Id IN :salesIds
            ]) {
                sales.Settlement_Status__c = 'ToBeSettled';
                salesList.add(sales);
            }

            if (!salesList.isEmpty()) {
                update salesList;
            }
        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static void createSettlementLines(List<FIN_SettlementItem__c> items, Map<Id, FIN_SettlementItem__c> oldMap) {
        //get all related settlement items
        Set<Id> parentSettleScheduleIDs = new Set<Id>();
        if (items != null) {
            for (FIN_SettlementItem__c si : items) {
                parentSettleScheduleIDs.add(si.FIN_ParentSettlementSchedule__c);
            }
        } else {
            for (FIN_SettlementItem__c si : oldMap.values()) {
                parentSettleScheduleIDs.add(si.FIN_ParentSettlementSchedule__c);
            }
        }

        // remove existing settlement lines
        List<FIN_SettlementLine__c> settlementLinesToRemove = [
                SELECT Id, FIN_SettlementSchedule__c
                FROM FIN_SettlementLine__c
                WHERE FIN_SettlementSchedule__c IN :parentSettleScheduleIDs
        ];
        delete settlementLinesToRemove;


        Map<Id, FIN_SettlementItem__c> allSIs = new Map<Id, FIN_SettlementItem__c>([
                SELECT Id, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c,
                        FIN_PaymentDistribution__c,
                        FIN_ParentSettlementSchedule__c,
                        FIN_SubContract__r.FIN_RemittanceAccount__c,

                        FIN_EntryType__c,

                        FIN_InvoiceSchedule__c,
                        FIN_InvoiceSchedule__r.Invoice_Number__c,
                        FIN_InvoiceSchedule__r.FIN_NetDue__c,
                        FIN_RemittanceAccount__c,

                        FIN_Amount__c,
                        FIN_ManualAmount__c,
                        FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_SubledgerCodeName__c,

                        FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c
                FROM FIN_SettlementItem__c
                WHERE FIN_ParentSettlementSchedule__c IN :parentSettleScheduleIDs
        ]);

        System.debug('allSIs -----> SIZE: ' + allSIs.size());   //get all types there

        List<FIN_SettlementItem__c> standardEntrySIs = new List<FIN_SettlementItem__c>();
        List<FIN_SettlementItem__c> manualAdjSIs = new List<FIN_SettlementItem__c>();
        List<FIN_SettlementItem__c> invoiceAdjSIs = new List<FIN_SettlementItem__c>();
        //
        List<FIN_SettlementItem__c> adjustmentsSIs = new List<FIN_SettlementItem__c>();

        for (FIN_SettlementItem__c si : allSIs.values()) {
            if (si.FIN_EntryType__c == 'Standard Entry') {
                standardEntrySIs.add(si);
            } else if (si.FIN_EntryType__c == 'Manual Adjustment') {
                manualAdjSIs.add(si);
                //
                adjustmentsSIs.add(si);
            } else if (si.FIN_EntryType__c == 'Invoice Adjustment') {
                invoiceAdjSIs.add(si);
                //
                adjustmentsSIs.add(si);
            }
        }

        System.debug('--------------------------------------------');
        System.debug('standardEntrySIs -----> SIZE: ' + standardEntrySIs.size());
        System.debug('manualAdjSIs -----> SIZE: ' + manualAdjSIs.size());
        System.debug('invoiceAdjSIs -----> SIZE: ' + invoiceAdjSIs.size());
        System.debug('//: ');
        System.debug('adjustmentsSIs -----> SIZE: ' + adjustmentsSIs.size());
        System.debug('--------------------------------------------');


        // get unique events
        Set<Id> eventsIds = new Set<Id>();
        // get all PDs
        List<Id> allPdIDs = new List<Id>();
        // get unique payees
        Set<Id> payeesIds = new Set<Id>();

        for (FIN_SettlementItem__c si : allSIs.values()) {
            //if (si.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c != null) {
            eventsIds.add(si.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c);
            //}
            if (si.FIN_PaymentDistribution__c != null) {
                allPdIDs.add(si.FIN_PaymentDistribution__c);
            }
            if (si.FIN_SubContract__r.FIN_RemittanceAccount__c != null) {
                payeesIds.add(si.FIN_SubContract__r.FIN_RemittanceAccount__c);
            }
        }

        System.debug('eventsIds -----> SIZE: ' + eventsIds.size());
        System.debug('allPdIDs -----> SIZE: ' + allPdIDs.size());
        System.debug('payeesIds -----> SIZE: ' + payeesIds.size());
        System.debug('--------------------------------------------');


        List<FIN_Payee__c> uniquePayeesList = new List<FIN_Payee__c> ([
                SELECT Id, FIN_LegalName__c
                FROM FIN_Payee__c
                WHERE Id IN :payeesIds
        ]);


        //////////////////////////////

        Map<Id, Double> payeeGrossAmountMap = new Map<Id, Double>();
        for (Id p : payeesIds) {
            payeeGrossAmountMap.put(p, 0);
        }

        // REVIEW: SEEMS LIKE HERE IS REGULAR BY EVENT+PAYEE
        // create new FIN_SettlementLine__c records
        Map<String, FIN_SettlementLine__c> settlementLinesToInsert = new Map<String, FIN_SettlementLine__c>();
        Map<Id, Campaign> eventsMap = new Map<Id, Campaign>(
        [
                SELECT Id, FIN_EventID__c, FIN_LookupCode__c, StartDate, Description, Name
                FROM Campaign
                WHERE Id IN :eventsIds
        ]);
        if (!allPDIDs.isEmpty()) {
            List<Campaign> uniqueEvents = [
                    SELECT Id, FIN_EventID__c, FIN_LookupCode__c, StartDate, Description
                    FROM Campaign
            ];
            System.debug(uniqueEvents);

            List<FIN_PaymentDistribution__c> allPDs = [
                    SELECT Id, FIN_DistributionAmount__c,
                            FIN_LibraryAssociation__c,
                            FIN_LibraryAssociation__r.FIN_TicketCategories__c,
                            FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c,
                            FIN_LibraryAssociation__r.FIN_Fee_and_Component__c,
                            FIN_LibraryAssociation__r.FIN_Concept_Use__c,
                            Contract__r.FIN_RemittanceAccount__c,

                            FIN_Payment__r.FIN_Order__c,
                            //FIN_Payment__r.FIN_Order__r.FIN_ZoneType__c,
                            FIN_EventZoneType__c,
                            FIN_Payment__r.FIN_Order__r.FIN_ZoneDesc__c,
                            FIN_Payment__r.FIN_Order__r.FIN_Venue__r.Name,
                            FIN_Payment__r.FIN_Order__r.Account.Name,
                            FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c,
                            FIN_Payment__r.FIN_Order__r.FIN_Event__c,

                            Contract__c,
                            Contract__r.FIN_SettlementReportGroup__c,
                            Contract__r.FIN_SettlementReportMode__c,

                    (SELECT Id FROM Settlement_Items__r WHERE FIN_ParentSettlementSchedule__c IN :parentSettleScheduleIDs)
                    FROM FIN_PaymentDistribution__c
                    WHERE Id IN :allPdIDs
            ];

            Map<Id, FIN_Payee__c> uniquePayees = new Map<Id, FIN_Payee__c> ([
                    SELECT Id, FIN_LegalName__c
                    FROM FIN_Payee__c
                    WHERE Id IN :payeesIds
            ]);

            System.debug(uniquePayees);
            System.debug(allPDs);
            for (FIN_PaymentDistribution__c pd : allPDs) {
                FIN_Payee__c payee = uniquePayees.get(pd.Contract__r.FIN_RemittanceAccount__c);
                Campaign event = eventsMap.get(pd.FIN_Payment__r.FIN_Order__r.FIN_Event__c);
                FIN_SettlementItem__c si = allSIs.get(pd.Settlement_Items__r[0].Id);
                System.debug('pd.Settlement_Items__r - ' + pd.Settlement_Items__r);
                System.debug('si1   -   ' + si);
                FIN_SettlementLine__c newSL = new FIN_SettlementLine__c();
                String pdKey = pd.FIN_Payment__r.FIN_Order__r.FIN_Event__c + ':' + pd.Contract__r.FIN_RemittanceAccount__c;

                if (settlementLinesToInsert.containsKey(pdKey)) {
                    newSL = settlementLinesToInsert.get(pdKey);
                } else {
                    newSL.FIN_AXSFee__c = 0;
                    newSL.FIN_TotalFeeValue__c = 0;
                    newSL.FIN_AXSPaymentFeeF__c = 0;
                    newSL.FIN_VenueFacilityFee__c = 0;
                    newSL.FIN_VenueFee__c = 0;
                    newSL.FIN_VenueLift__c = 0;
                    newSL.FIN_VenueUplift__c = 0;
                    newSL.FIN_TicketsAndFees__c = 0;
                    newSL.FIN_Retain__c = 0;
                    newSL.FIN_TotalTicketValue__c = 0;
                    newSL.FIN_VenueTicketFee__c = 0;
                    newSL.FIN_VenuePremiumFee__c = 0;
                    newSL.FIN_VenueDeliveryFee__c = 0;
                    newSL.FIN_AXSTicketFee__c = 0;
                    newSL.FIN_AXSPremiumFee__c = 0;
                    newSL.FIN_AXSPaymentFee__c = 0;
                    newSL.FIN_RemitAmount__c = 0;

                    newSL.FIN_Individual__c = 0;
                    newSL.FIN_AXSPremium__c = 0;
                    newSL.FIN_VIPPackages__c = 0;
                    newSL.FIN_Merchandise__c = 0;
                    newSL.FIN_Group__c = 0;
                    newSL.FIN_Season__c = 0;
                    newSL.FIN_NonEvent__c = 0;
                    newSL.FIN_Parking__c = 0;

                    //if (si.FIN_ParentSettlementSchedule__c != null) {
                    newSL.FIN_SettlementSchedule__c = si.FIN_ParentSettlementSchedule__c;
                    //}
                    if (event != null) {
                        newSL.FIN_EventID__c = event.FIN_EventID__c;
                        newSL.FIN_EventLookupCode__c = event.FIN_LookupCode__c;
                        newSL.FIN_EventDescription__c = event.Description;
                        newSL.FIN_EventStartDate__c = event.StartDate;
                        newSL.Event__c = event.Name;
                    }
                    //newSL.FIN_ZoneType__c = pd.FIN_Payment__r.FIN_Order__r.FIN_ZoneType__c;
                    newSL.FIN_ZoneType__c = pd.FIN_EventZoneType__c;
                    newSL.FIN_ZoneDesc__c = pd.FIN_Payment__r.FIN_Order__r.FIN_ZoneDesc__c;
                    newSL.FIN_Venue__c = pd.FIN_Payment__r.FIN_Order__r.FIN_Venue__r.Name;
                    newSL.FIN_Client__c = pd.FIN_Payment__r.FIN_Order__r.Account.Name;
                }

                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'Individual') {
                    newSL.FIN_Individual__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'AXS Premium') {
                    newSL.FIN_AXSPremium__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'VIP Packages') {
                    newSL.FIN_VIPPackages__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'Merchandise') {
                    newSL.FIN_Merchandise__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'Group') {
                    newSL.FIN_Group__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'Season') {
                    newSL.FIN_Season__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'Non-Event') {
                    newSL.FIN_NonEvent__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_TicketCategories__c == 'Parking') {
                    newSL.FIN_Parking__c += pd.FIN_Payment__r.FIN_Order__r.FIN_TotalTickets__c;
                }

                //

                if (pd.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c == 'AXS Payment Fee') {
                    newSL.FIN_AXSPaymentFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalTicketValue__c += pd.FIN_DistributionAmount__c;
                    System.debug('pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c' + pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c);

                    if (pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c == 'Retained') {
                        newSL.FIN_Retain__c += pd.FIN_DistributionAmount__c;
                    }
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c == 'AXS Premium Fee') {
                    newSL.FIN_AXSPremiumFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalTicketValue__c += pd.FIN_DistributionAmount__c;
                    System.debug('pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c' + pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c);

                    if (pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c == 'Retained') {
                        newSL.FIN_Retain__c += pd.FIN_DistributionAmount__c;
                    }
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c == 'AXS Ticket Fee') {
                    newSL.FIN_AXSTicketFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalTicketValue__c += pd.FIN_DistributionAmount__c;
                    System.debug('pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c' + pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c);

                    if (pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c == 'Retained') {
                        newSL.FIN_Retain__c += pd.FIN_DistributionAmount__c;
                    }
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c == 'Venue Delivery Fee') {
                    newSL.FIN_VenueDeliveryFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalTicketValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c == 'Venue Premium Fee') {
                    newSL.FIN_VenuePremiumFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalTicketValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Ticket_price_Component__c == 'Venue Ticket Fee') {
                    newSL.FIN_VenueTicketFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalTicketValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }

                if (pd.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c == 'AXS Fee') {
                    newSL.FIN_AXSFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalFeeValue__c += pd.FIN_DistributionAmount__c;
                    System.debug('pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c' + pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c);
                    if (pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c == 'Retained') {
                        newSL.FIN_Retain__c += pd.FIN_DistributionAmount__c;
                    }
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c == 'AXS Payment Fee') {
                    newSL.FIN_AXSPaymentFeeF__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalFeeValue__c += pd.FIN_DistributionAmount__c;
                    if (pd.FIN_LibraryAssociation__r.FIN_Concept_Use__c == 'Retained') {
                        newSL.FIN_Retain__c += pd.FIN_DistributionAmount__c;
                    }
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c == 'Venue Facility Fee') {
                    newSL.FIN_VenueFacilityFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalFeeValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c == 'Venue Fee') {
                    newSL.FIN_VenueFee__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalFeeValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c == 'Venue Lift') {
                    newSL.FIN_VenueLift__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalFeeValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }
                if (pd.FIN_LibraryAssociation__r.FIN_Fee_and_Component__c == 'Venue Uplift') {
                    newSL.FIN_VenueUplift__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_TotalFeeValue__c += pd.FIN_DistributionAmount__c;
                    newSL.FIN_RemitAmount__c += pd.FIN_DistributionAmount__c;
                }
                newSL.FIN_SubContract__c = pd.Contract__c;
                newSL.FIN_SubContractRepGroup__c = pd.Contract__r.FIN_SettlementReportGroup__c;
                newSL.FIN_SubContractRepMode__c = pd.Contract__r.FIN_SettlementReportMode__c;


                newSL.FIN_TotalTickets__c = newSL.FIN_Individual__c + newSL.FIN_AXSPremium__c + newSL.FIN_VIPPackages__c + newSL.FIN_Merchandise__c
                        + newSL.FIN_Group__c + newSL.FIN_Season__c + newSL.FIN_NonEvent__c + newSL.FIN_Parking__c;
                newSL.FIN_TicketsAndFees__c = newSL.FIN_TotalTicketValue__c + newSL.FIN_TotalFeeValue__c;

                newSL.FIN_EntryType__c = 'Standard Entry';
                newSL.FIN_Mode__c = 'StandardEntryEventPayee';

                if (payee != null) {
                    newSL.FIN_RemitTo__c = payee.FIN_LegalName__c;

                    Double gross = payeeGrossAmountMap.get(payee.Id);
                    payeeGrossAmountMap.put(payee.Id, gross + newSL.FIN_RemitAmount__c);

                }
                System.debug('newSL.FIN_Retain__c' + newSL.FIN_Retain__c);
                if (!settlementLinesToInsert.containsKey(pdKey)) {
                    settlementLinesToInsert.put(pdKey, newSL);
                }
            }
        }

        System.debug('settlementLinesToInsert' + settlementLinesToInsert);
        if (!settlementLinesToInsert.isEmpty()) {
            insert settlementLinesToInsert.values();
        }

        Map<Id, FIN_Payee__c> uniquePayees = new Map<Id, FIN_Payee__c> ([
                SELECT Id, FIN_LegalName__c
                FROM FIN_Payee__c
                WHERE Id IN :payeesIds
        ]);

        // FIN_TotalRemitAmount__c for each payee for AdjustmentTotals
        Map<FIN_Payee__c, Double> payeeTotalRemitMap = new Map<FIN_Payee__c, Double>();
        for (FIN_Payee__c p : uniquePayees.values()) {
            Double totalRemitAmount = 0;
            for (FIN_SettlementLine__c sl : settlementLinesToInsert.values()) {
                if (sl.FIN_RemitTo__c == p.FIN_LegalName__c) {
                    totalRemitAmount += sl.FIN_RemitAmount__c;
                    payeeTotalRemitMap.put(p, totalRemitAmount);
                }
            }
        }

        /////////////////////////////////////////////////////

        // create FIN_SettlementLine__c AdjustmentTotals
        List<FIN_SettlementLine__c> adjustmentTotalsToInsert = new List<FIN_SettlementLine__c>();

        //if (!adjustmentsSIs.isEmpty()) {

        for (FIN_Payee__c p : uniquePayeesList) {

            FIN_SettlementLine__c newSLAdjustmentTotals = new FIN_SettlementLine__c();
            newSLAdjustmentTotals.FIN_InvoiceAdjustmentAmount__c = 0;
            newSLAdjustmentTotals.FIN_ManualAdjustmentAmount__c = 0;
            newSLAdjustmentTotals.FIN_EntryType__c = 'Adjustment';
            newSLAdjustmentTotals.FIN_Mode__c = 'AdjustmentTotals';
            newSLAdjustmentTotals.FIN_RemitAmount__c = payeeGrossAmountMap.get(p.Id);
            newSLAdjustmentTotals.FIN_TotalRemitAmount__c = payeeTotalRemitMap.get(p);

            if (!invoiceAdjSIs.isEmpty()) {
                for (FIN_SettlementItem__c si : invoiceAdjSIs) {
                    if (si.FIN_RemittanceAccount__c == p.Id) {
                        newSLAdjustmentTotals.FIN_SettlementSchedule__c = si.FIN_ParentSettlementSchedule__c;
                        newSLAdjustmentTotals.FIN_RemittanceAccount__c = si.FIN_RemittanceAccount__c;
                        newSLAdjustmentTotals.FIN_InvoiceAdjustmentAmount__c -= si.FIN_InvoiceSchedule__r.FIN_NetDue__c;
                    }
                }
            }
            if (!manualAdjSIs.isEmpty()) {
                for (FIN_SettlementItem__c si : manualAdjSIs) {
                    if (si.FIN_SubContract__r.FIN_RemittanceAccount__c == p.Id) {
                        newSLAdjustmentTotals.FIN_SettlementSchedule__c = si.FIN_ParentSettlementSchedule__c;
                        newSLAdjustmentTotals.FIN_RemittanceAccount__c = si.FIN_SubContract__r.FIN_RemittanceAccount__c;
                        newSLAdjustmentTotals.FIN_ManualAdjustmentAmount__c -= si.FIN_ManualAmount__c;
                    }
                }
            }
            for (FIN_SettlementItem__c si : standardEntrySIs) {
                newSLAdjustmentTotals.FIN_SettlementSchedule__c = si.FIN_ParentSettlementSchedule__c;
                if (si.FIN_RemittanceAccount__c != null) {
                    System.debug('here AdjustmentTotals');
                    newSLAdjustmentTotals.FIN_RemittanceAccount__c = si.FIN_RemittanceAccount__c;
                } else {
                    System.debug('else AdjustmentTotals');
                    newSLAdjustmentTotals.FIN_RemittanceAccount__c = si.FIN_SubContract__r.FIN_RemittanceAccount__c;
                }
            }

            if (newSLAdjustmentTotals.FIN_RemittanceAccount__c != null) {
                adjustmentTotalsToInsert.add(newSLAdjustmentTotals);
            }
        }
        //}

        System.debug('adjustmentTotalsToInsert: ' + adjustmentTotalsToInsert.size());
        if (!adjustmentTotalsToInsert.isEmpty()) {
            System.debug('!adjustmentTotalsToInsert.isEmpty(): ' + !adjustmentTotalsToInsert.isEmpty());
            insert adjustmentTotalsToInsert;
        }


        // Integer adjustmentDetailsSize = 0;
        // if (invoiceAdjSIs.size() > manualAdjSIs.size()) {
        //     adjustmentDetailsSize = invoiceAdjSIs.size();
        // } else if (invoiceAdjSIs.size() < manualAdjSIs.size()) {
        //     adjustmentDetailsSize = manualAdjSIs.size();
        // } else if (invoiceAdjSIs.size() == manualAdjSIs.size()){
        //     adjustmentDetailsSize = invoiceAdjSIs.size();
        // }

        // create FIN_SettlementLine__c AdjustmentDetails
        List<FIN_SettlementLine__c> adjustmentDetailsToInsert = new List<FIN_SettlementLine__c>();

        if (!adjustmentsSIs.isEmpty()) {

            for (FIN_Payee__c p : uniquePayeesList) {
                for (FIN_SettlementItem__c si : adjustmentsSIs) {

                    if (si.FIN_RemittanceAccount__c == p.Id || si.FIN_SubContract__r.FIN_RemittanceAccount__c == p.Id) {

                        FIN_SettlementLine__c newSLAdjustmentDetails = new FIN_SettlementLine__c();

                        newSLAdjustmentDetails.FIN_SettlementSchedule__c = si.FIN_ParentSettlementSchedule__c;
                        newSLAdjustmentDetails.FIN_EntryType__c = 'Adjustment';
                        newSLAdjustmentDetails.FIN_Mode__c = 'AdjustmentDetails';

                        if (si.FIN_EntryType__c == 'Invoice Adjustment') {
                            newSLAdjustmentDetails.FIN_RemittanceAccount__c = si.FIN_RemittanceAccount__c;
                            newSLAdjustmentDetails.FIN_InvoiceAdjustmentComment__c = si.FIN_InvoiceSchedule__r.Invoice_Number__c;
                            newSLAdjustmentDetails.FIN_InvoiceAdjustmentAmount__c = -1 * (si.FIN_InvoiceSchedule__r.FIN_NetDue__c);
                        }
                        if (si.FIN_EntryType__c == 'Manual Adjustment') {
                            newSLAdjustmentDetails.FIN_RemittanceAccount__c = si.FIN_SubContract__r.FIN_RemittanceAccount__c;
                            newSLAdjustmentDetails.FIN_ManualAdjustmentComment__c = si.FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_SubledgerCodeName__c;
                            newSLAdjustmentDetails.FIN_ManualAdjustmentAmount__c = -1 * si.FIN_ManualAmount__c;
                        }

                        if (newSLAdjustmentDetails.FIN_RemittanceAccount__c != null) {
                            adjustmentDetailsToInsert.add(newSLAdjustmentDetails);
                        }
                    }
                }
            }
        }

        System.debug('adjustmentDetailsToInsert.size(): ' + adjustmentDetailsToInsert.size());
        if (!adjustmentDetailsToInsert.isEmpty()) {
            insert adjustmentDetailsToInsert;
        }
    }
}