public with sharing class FIN_InvoiceItemHelper {
    static final String PDS_CONST = FIN_PaymentDistribution__c.SObjectType.getDescribe().getName();
    static final String PAYMENTS_CONST = FIN_Payment__c.SObjectType.getDescribe().getName();
    static final String SALES_CONST = Order.SObjectType.getDescribe().getName();
    static final String SALESTR_CONST = OrderItem.SObjectType.getDescribe().getName();
    static final String INVOICE_SCHEDULED_CONST = 'InvoiceScheduled';

    public static void updateStatuses(List<FIN_InvoiceItem__c> items, Map<Id, FIN_InvoiceItem__c> oldMap, String statusValue) {
        Map<String, Set<Id>> mapObjIds = new Map<String, Set<Id>>{
                PDS_CONST => new Set<Id>(),
                PAYMENTS_CONST => new Set<Id>(),
                SALES_CONST => new Set<Id>(),
                SALESTR_CONST => new Set<Id>()
        };
        SOQLQueryBuilder itemsQueryBuilder = SOQLQueryBuilder.create()
                .selectClause()
                .field(FIN_InvoiceItem__c.Id.getDescribe().getName())
                .field(FIN_InvoiceItem__c.FIN_PaymentDistribution__c.getDescribe().getName())
                .field(FIN_InvoiceItem__c.FIN_Sales__c.getDescribe().getName())
                .field(FIN_InvoiceItem__c.FIN_Payment__c.getDescribe().getName())
                .field(FIN_InvoiceItem__c.FIN_SalesTransactions__c.getDescribe().getName())
                .field('FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c')
                .field('FIN_PaymentDistribution__r.FIN_Payment__c')
                .field('FIN_Payment__r.FIN_Order__c')
                .field('FIN_SalesTransactions__r.OrderId')
                .endSelectSOQL()
                .fromClause(Schema.SObjectType.FIN_InvoiceItem__c.getName())
                .whereClause()
                .useBindVariablesInQuery(true)
                .condition(FIN_InvoiceItem__c.Id.getDescribe().getName(), items,
                        Constants.ConditionType.IN_CONDITION, null, null)
                .endWhereSOQL();
        Map<String, Object> bindVariables = itemsQueryBuilder.getBindVariables();
        for (FIN_InvoiceItem__c item : (List<FIN_InvoiceItem__c>) Database.queryWithBinds(itemsQueryBuilder.build(), bindVariables,
                AccessLevel.USER_MODE)) {
            mapObjIds.get(PDS_CONST).add(item.FIN_PaymentDistribution__c);
            mapObjIds.get(PAYMENTS_CONST).add(item.FIN_Payment__c);
            mapObjIds.get(PAYMENTS_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_Sales__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_Payment__r.FIN_Order__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_SalesTransactions__r.OrderId);
            mapObjIds.get(SALESTR_CONST).add(item.FIN_SalesTransactions__c);
        }

        for (String obj : mapObjIds.keySet()) {
            updateRelatedRecordsStatuses(Constants.statusFields.get(FIN_InvoiceItem__c.SObjectType.getDescribe().getName()).get(obj), obj, mapObjIds.get(obj), statusValue);
        }
    }

    public static void createInvoiceLines(List<FIN_InvoiceItem__c> items, Map<Id, FIN_InvoiceItem__c> oldMap) {

        Set<Id> parentInvoiceScheduleIDs = new Set<Id>();

        if (items != null) {
            for (FIN_InvoiceItem__c ii : items) {
                parentInvoiceScheduleIDs.add(ii.FIN_ParentInvoiceSchedule__c);
            }
        } else {
            for (FIN_InvoiceItem__c ii : oldMap.values()) {
                parentInvoiceScheduleIDs.add(ii.FIN_ParentInvoiceSchedule__c);
            }
        }

        List<FIN_InvoiceLine__c> invoiceLinesToRemove = [
                SELECT Id
                FROM FIN_InvoiceLine__c
                WHERE FIN_ParentInvoiceSchedule__c IN :parentInvoiceScheduleIDs
        ];
        EventBus.publish(new FIN_RecordsForwarder__e(RecordsToProcessNew__c = JSON.serialize(invoiceLinesToRemove), OperationName__c = 'deleteRecords', ObjectType__c = FIN_InvoiceLine__c.SObjectType.getDescribe().getName()));


        // // update rates
        // List<FIN_InvoiceItem__c> updateIIs = [
        //     SELECT Id, FIN_AdjustmentforInvoice__c, FIN_TotalAmountbyQty__c, FIN_QuantityforInvoiceQty__c, FIN_BaseRateUnitCost__c
        //     FROM FIN_InvoiceItem__c
        //     WHERE FIN_ParentInvoiceSchedule__c IN :parentInvoiceScheduleIDs
        //     AND FIN_EntryType__c = 'StandardEntry'
        // ];

        // for (FIN_InvoiceItem__c ii : updateIIs) {
        //     if (ii.FIN_AdjustmentforInvoice__c != null) {
        //         ii.FIN_TotalAmountbyQty__c = ii.FIN_QuantityforInvoiceQty__c * ii.FIN_AdjustmentforInvoice__c;
        //     } else {
        //         ii.FIN_AmountbyQty__c = ii.FIN_QuantityforInvoiceQty__c * ii.FIN_BaseRateUnitCost__c;
        //     }
        // }
        // update updateIIs;
        String invoiceItemLAReference = FIN_InvoiceItem__c.FIN_LibraryAssociation__r.getDescribe().getName() + '.' + SBQQ__ContractedPrice__c.FIN_Financial_Code__r.getDescribe().getName() + '.';
        String invoiceItemPDPaymentReference = FIN_InvoiceItem__c.FIN_PaymentDistribution__r.getDescribe().getReferenceTargetField()  + '.' +
                + FIN_PaymentDistribution__c.FIN_Payment__r.getDescribe().getName() + '.';
        String invoiceItemPDReference = FIN_InvoiceItem__c.FIN_PaymentDistribution__r.getDescribe().getName() + '.';
        String invoiceItemPaymentReference = FIN_InvoiceItem__c.FIN_Payment__r.getDescribe().getName() + '.';
        List<String> fields = new List<String> {
                FIN_InvoiceItem__c.Id.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_TotalGrossAmountforInvoice__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_BaseRateUnitCost__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_ManualAmount__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_EntryType__c.getDescribe().getName(),

                invoiceItemLAReference + FIN_Financial_Code__c.FIN_Chart_of_Accounts_Description__c.getDescribe().getName(),
                invoiceItemLAReference + FIN_Financial_Code__c.FIN_Subledger_Code__c.getDescribe().getName(),
                invoiceItemLAReference + FIN_Financial_Code__c.FIN_Business_Unit__c.getDescribe().getName(),
                invoiceItemLAReference.replace(SBQQ__ContractedPrice__c.FIN_Financial_Code__r.getDescribe().getName() + '.', '') + SBQQ__ContractedPrice__c.FIN_Financial_Code__c.getDescribe().getName(),

                FIN_InvoiceItem__c.FIN_PaymentDistribution__c.getDescribe().getName(),
                invoiceItemPDPaymentReference + FIN_Payment__c.FIN_Order__r.getDescribe().getName() + '.' + Order.FIN_Event__c.getDescribe().getName(),
                invoiceItemPDPaymentReference + FIN_Payment__c.FIN_Order__c.getDescribe().getName(),
                invoiceItemPDReference + FIN_PaymentDistribution__c.FIN_Channel__c.getDescribe().getName(),

                FIN_InvoiceItem__c.FIN_Payment__c.getDescribe().getName(),
                invoiceItemPaymentReference + '.' + FIN_Payment__c.FIN_Order__r.getDescribe().getReferenceTargetField().FIN_Event__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_Payment__r.FIN_Order__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_Payment__r.FIN_Channel__c.getDescribe().getName(),

                FIN_InvoiceItem__c.FIN_SalesTransactions__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_SalesTransactions__r.Order.FIN_Event__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_SalesTransactions__r.OrderId,
                FIN_InvoiceItem__c.FIN_SalesTransactions__r.FIN_Channel__c.getDescribe().getName(),

                FIN_InvoiceItem__c.FIN_ParentInvoiceSchedule__r.FIN_Mode__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_TotalAmountbyQty__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_AmountbyQty__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_AdjustmentforInvoice__c.getDescribe().getName(),

                FIN_InvoiceItem__c.FIN_QuantityforInvoiceQty__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_AppliedRateforInvoice__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_AppliedUnitPriceforInvoice__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_BaseRate_UnitCost__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_ParentContract__r.FIN_BaseRate_UnitCost__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_InvoiceRate_del__c.getDescribe().getName(),
                FIN_InvoiceItem__c.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_ParentContract__r.FIN_InvoiceRate_del__c
        };

        List<FIN_InvoiceItem__c> allIIs = [
                SELECT Id, FIN_TotalGrossAmountforInvoice__c,
                        FIN_BaseRateUnitCost__c,
                        FIN_ManualAmount__c,
                        FIN_EntryType__c,

                        FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Chart_of_Accounts_Description__c,
                        FIN_LibraryAssociation__r.FIN_Financial_Code__c,
                        FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Subledger_Code__c,
                        FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Business_Unit__c,

                        FIN_PaymentDistribution__c,
                        FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c,
                        FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c,
                        FIN_PaymentDistribution__r.FIN_Channel__c,

                        FIN_Payment__c,
                        FIN_Payment__r.FIN_Order__r.FIN_Event__c,
                        FIN_Payment__r.FIN_Order__c,
                        FIN_Payment__r.FIN_Channel__c,

                        FIN_SalesTransactions__c,
                        FIN_SalesTransactions__r.Order.FIN_Event__c,
                        FIN_SalesTransactions__r.OrderId,
                        FIN_SalesTransactions__r.FIN_Channel__c,

                        FIN_ParentInvoiceSchedule__r.FIN_Mode__c,
                        FIN_TotalAmountbyQty__c,
                        FIN_AmountbyQty__c,
                        FIN_AdjustmentforInvoice__c,

                        FIN_QuantityforInvoiceQty__c,
                        FIN_AppliedRateforInvoice__c,
                        FIN_AppliedUnitPriceforInvoice__c,
                        FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_BaseRate_UnitCost__c,
                        FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_ParentContract__r.FIN_BaseRate_UnitCost__c,
                        FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_InvoiceRate_del__c,
                        FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_ParentContract__r.FIN_InvoiceRate_del__c

                FROM FIN_InvoiceItem__c
                WHERE FIN_ParentInvoiceSchedule__c IN :parentInvoiceScheduleIDs
                ORDER BY FIN_AppliedRateforInvoice__c
        ];


        // get unique events
        Set<Id> eventsIdsSet = new Set<Id>();
        // get unique sales
        Set<Id> salesIdsSet = new Set<Id>();
        // get unique subledger codes
        Set<Id> subledgerIdsSet = new Set<Id>();
        // get unique business units
        Set<Id> bUnitIdsSet = new Set<Id>();

        // get unique financialCodes
        Set<Id> finCodeIdsSet = new Set<Id>();
        // get unique fin cOFa description
        Set<String> cOfaDescSet = new Set<String>();
        // get unique channels
        Set<String> channelsSet = new Set<String>();

        // get all PDs
        List<Id> allPdIDs = new List<Id>();
        // get all Payments
        List<Id> allPaymentIDs = new List<Id>();
        // get all STs
        List<Id> allStIDs = new List<Id>();

        for (FIN_InvoiceItem__c ii : allIIs) {
            if (ii.FIN_PaymentDistribution__c != null) {
                allPdIDs.add(ii.FIN_PaymentDistribution__c);
                eventsIdsSet.add(ii.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c);
                salesIdsSet.add(ii.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
                channelsSet.add(ii.FIN_PaymentDistribution__r.FIN_Channel__c);
            }
            if (ii.FIN_Payment__c != null) {
                allPaymentIDs.add(ii.FIN_Payment__c);
                eventsIdsSet.add(ii.FIN_Payment__r.FIN_Order__r.FIN_Event__c);
                salesIdsSet.add(ii.FIN_Payment__r.FIN_Order__c);
                channelsSet.add(ii.FIN_Payment__r.FIN_Channel__c);
            }
            if (ii.FIN_SalesTransactions__c != null) {
                allStIDs.add(ii.FIN_SalesTransactions__c);
                eventsIdsSet.add(ii.FIN_SalesTransactions__r.Order.FIN_Event__c);
                salesIdsSet.add(ii.FIN_SalesTransactions__r.OrderId);
                channelsSet.add(ii.FIN_SalesTransactions__r.FIN_Channel__c);
            }
            finCodeIdsSet.add(ii.FIN_LibraryAssociation__r.FIN_Financial_Code__c);
            subledgerIdsSet.add(ii.FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Subledger_Code__c);
            bUnitIdsSet.add(ii.FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Business_Unit__c);
            cOfaDescSet.add(ii.FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Chart_of_Accounts_Description__c);
        }
        System.debug('channelsSet: ' + channelsSet);

        // get actual business units
        List<FIN_BusinessUnit__c> bUnitList = [
                SELECT Id, Name, FIN_Description__c
                FROM FIN_BusinessUnit__c
                WHERE Id IN :bUnitIdsSet
        ];
        //FIN_Remark__c

        // get actual subledgers
        List<FIN_SubledgerCode__c> subCodeList = [
                SELECT Id, Name
                FROM FIN_SubledgerCode__c
                WHERE Id IN :subledgerIdsSet
        ];

        // get actual sales
        List<Order> salesList = [
                SELECT Id, FIN_EventLookupCode__c, FIN_PriceCodeType__c
                FROM Order
                WHERE Id IN :salesIdsSet
        ];

        // get actual events
        List<Campaign> eventsList = [
                SELECT Id, Description, FIN_LookupCode__c
                FROM Campaign
                WHERE Id IN :eventsIdsSet
        ];

        // get unique values of the field ii.FIN_AppliedRateforInvoice__c
        Set<Double> uniqueAppliedRateforInvoiceSet = new Set<Double>();

                for (FIN_InvoiceItem__c ii : allIIs) {
                    uniqueAppliedRateforInvoiceSet.add(ii.FIN_AppliedRateforInvoice__c);
                }

                List<FIN_InvoiceLine__c> invoiceLinesToInsert = new List<FIN_InvoiceLine__c>();

                for (ID isId : parentInvoiceScheduleIDs) {
                    ////////////////////////////////// BusinessUnit //////////////////////////////////
                    for (FIN_BusinessUnit__c bu : bUnitList) {
                        // list of invoice items related to this bUnit
                        List<FIN_InvoiceItem__c> iiRelatedToThisBU = [
                                SELECT Id, FIN_TotalGrossAmountforInvoice__c,
                                        FIN_ParentInvoiceSchedule__r.FIN_Mode__c,
                                        FIN_BaseRateUnitCost__c,
                                        FIN_TotalAmountbyQty__c,
                                        FIN_AmountbyQty__c,
                                        FIN_AdjustmentforInvoice__c,
                                        FIN_EntryType__c,
                                        FIN_ManualAmount__c
                                FROM FIN_InvoiceItem__c
                                WHERE FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Business_Unit__c = :bu.Id
                                AND FIN_ParentInvoiceSchedule__c = :isId
                        ];

                        if (!iiRelatedToThisBU.isEmpty()) {
                            System.debug('____________________BusinessUnit____________________');
                            FIN_InvoiceLine__c invLine = new FIN_InvoiceLine__c();
                            invLine.FIN_ParentInvoiceSchedule__c = isId;
                            invLine.FIN_Unique__c = 'BusinessUnit';
                            invLine.FIN_BusinessUnit__c = bu.Name;
                            invLine.FIN_GrossAmt__c = 0;
                            invLine.FIN_Remark__c = bu.FIN_Description__c;

                            for (FIN_InvoiceItem__c ii : iiRelatedToThisBU) {
                                if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && ii.FIN_EntryType__c == 'StandardEntry') {
                                    invLine.FIN_AccumulatorType__c = 'ByAmount';
                                    if (ii.FIN_AdjustmentforInvoice__c != null) {
                                        invLine.FIN_GrossAmt__c += ii.FIN_AdjustmentforInvoice__c;
                                    } else {
                                        invLine.FIN_GrossAmt__c += ii.FIN_TotalGrossAmountforInvoice__c;
                                    }
                                } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && ii.FIN_EntryType__c == 'ManualAdjustment') {
                                    invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                    invLine.FIN_GrossAmt__c += ii.FIN_ManualAmount__c;
                                } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && ii.FIN_EntryType__c == 'StandardEntry') {
                                    invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                    if (ii.FIN_TotalAmountbyQty__c != null) {
                                        invLine.FIN_GrossAmt__c += ii.FIN_TotalAmountbyQty__c;
                                    } else {
                                        invLine.FIN_GrossAmt__c += ii.FIN_AmountbyQty__c;
                                    }
                                } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && ii.FIN_EntryType__c == 'ManualAdjustment') {
                                    invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                    invLine.FIN_GrossAmt__c += ii.FIN_ManualAmount__c;
                                }
                            }

                            invoiceLinesToInsert.add(invLine);
                        }
                    }

                    ////////////////////////////////// CofASubledger //////////////////////////////////
                    for (FIN_SubledgerCode__c subCode : subCodeList) {
                        for (String cOfaDesc : cOfaDescSet) {

                            // list of related invoice items
                            List<FIN_InvoiceItem__c> iiRelatedToThisSubCodeAndCofA = [
                                    SELECT Id, FIN_LibraryAssociation__r.FIN_SubledgerType__c, FIN_AdjustmentforInvoice__c,
                                            FIN_LibraryAssociation__r.FIN_Subledger__c, FIN_TotalGrossAmountforInvoice__c,
                                            FIN_ParentInvoiceSchedule__r.FIN_Mode__c, FIN_TotalAmountbyQty__c, FIN_AmountbyQty__c,
                                            FIN_EntryType__c, FIN_ManualAmount__c
                                    FROM FIN_InvoiceItem__c
                                    WHERE FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Subledger_Code__c = :subCode.Id
                                    AND FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Chart_of_Accounts_Description__c = :cOfaDesc
                                    AND FIN_ParentInvoiceSchedule__c = :isId
                            ];

                            if (!iiRelatedToThisSubCodeAndCofA.isEmpty()) {
                                System.debug('____________________CofASubledger____________________');
                                FIN_InvoiceLine__c invLine = new FIN_InvoiceLine__c();
                                invLine.FIN_ParentInvoiceSchedule__c = isId;
                                invLine.FIN_Unique__c = 'CofASubledger';
                                invLine.FIN_AmountIC__c = 0;
                                invLine.FIN_CofADesc__c = cOfaDesc;

                                for (FIN_InvoiceItem__c ii : iiRelatedToThisSubCodeAndCofA) {
                                    if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && ii.FIN_EntryType__c == 'StandardEntry') {
                                        invLine.FIN_AccumulatorType__c = 'ByAmount';
                                        if (ii.FIN_AdjustmentforInvoice__c != null) {
                                            invLine.FIN_AmountIC__c += ii.FIN_AdjustmentforInvoice__c;
                                        } else {
                                            invLine.FIN_AmountIC__c += ii.FIN_TotalGrossAmountforInvoice__c;
                                        }
                                    } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && ii.FIN_EntryType__c == 'ManualAdjustment') {
                                        invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                        invLine.FIN_AmountIC__c += ii.FIN_ManualAmount__c;
                                    } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && ii.FIN_EntryType__c == 'StandardEntry') {
                                        invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                        if (ii.FIN_TotalAmountbyQty__c != null) {
                                            invLine.FIN_AmountIC__c += ii.FIN_TotalAmountbyQty__c;
                                        } else {
                                            invLine.FIN_AmountIC__c += ii.FIN_AmountbyQty__c;
                                        }
                                    } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && ii.FIN_EntryType__c == 'ManualAdjustment') {
                                        invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                        invLine.FIN_AmountIC__c += ii.FIN_ManualAmount__c;
                                    }
                                    invLine.FIN_SubTypeIC__c = ii.FIN_LibraryAssociation__r.FIN_SubledgerType__c;
                                    invLine.FIN_SubledgerIC__c = ii.FIN_LibraryAssociation__r.FIN_Subledger__c;
                                }

                                invoiceLinesToInsert.add(invLine);
                            }
                        }

                ////////////////////////////////// AccountSubledger //////////////////////////////////
                List<FIN_InvoiceItem__c> iiRelatedToThisSubCodeOnly = [
                        SELECT Id, FIN_LibraryAssociation__r.FIN_SubledgerType__c, FIN_AccountforInvoice__c,
                                FIN_LibraryAssociation__r.FIN_Subledger__c, FIN_TotalGrossAmountforInvoice__c,
                                FIN_ParentInvoiceSchedule__r.FIN_Mode__c, FIN_TotalAmountbyQty__c, FIN_AmountbyQty__c,
                                FIN_AdjustmentforInvoice__c, FIN_EntryType__c, FIN_ManualAmount__c
                        FROM FIN_InvoiceItem__c
                        WHERE FIN_LibraryAssociation__r.FIN_Financial_Code__r.FIN_Subledger_Code__c = :subCode.Id
                        AND FIN_ParentInvoiceSchedule__c = :isId
                ];

                Set<String> accNumList = new Set<String>();

                for (FIN_InvoiceItem__c ii : iiRelatedToThisSubCodeOnly) {
                    accNumList.add(ii.FIN_AccountforInvoice__c);
                }

                if (!accNumList.isEmpty()) {
                    System.debug('____________________AccountSubledger____________________');
                    for (String s : accNumList) {
                        List<FIN_InvoiceItem__c> iiRelatedToThisSubCodeAndAccNum = new List<FIN_InvoiceItem__c>();
                        for (FIN_InvoiceItem__c ii : iiRelatedToThisSubCodeOnly) {
                            if (ii.FIN_AccountforInvoice__c == s) {
                                iiRelatedToThisSubCodeAndAccNum.add(ii);
                            }
                        }

                        if (!iiRelatedToThisSubCodeAndAccNum.isEmpty()) {
                            FIN_InvoiceLine__c invLine = new FIN_InvoiceLine__c();
                            invLine.FIN_ParentInvoiceSchedule__c = isId;
                            invLine.FIN_Unique__c = 'AccountSubledger';
                            invLine.FIN_Amount__c = 0;
                            invLine.FIN_AccountNum__c = s;

                            for (FIN_InvoiceItem__c ii : iiRelatedToThisSubCodeAndAccNum) {
                                if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && ii.FIN_EntryType__c == 'StandardEntry') {
                                    invLine.FIN_AccumulatorType__c = 'ByAmount';
                                    if (ii.FIN_AdjustmentforInvoice__c != null) {
                                        invLine.FIN_Amount__c += ii.FIN_AdjustmentforInvoice__c;
                                    } else {
                                        invLine.FIN_Amount__c += ii.FIN_TotalGrossAmountforInvoice__c;
                                    }
                                } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && ii.FIN_EntryType__c == 'ManualAdjustment') {
                                    invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                    invLine.FIN_Amount__c += ii.FIN_ManualAmount__c;
                                } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && ii.FIN_EntryType__c == 'StandardEntry') {
                                    invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                    if (ii.FIN_TotalAmountbyQty__c != null) {
                                        invLine.FIN_Amount__c += ii.FIN_TotalAmountbyQty__c;
                                    } else {
                                        invLine.FIN_Amount__c += ii.FIN_AmountbyQty__c;
                                    }
                                } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && ii.FIN_EntryType__c == 'ManualAdjustment') {
                                    invLine.FIN_AccumulatorType__c = 'ByQuantity';
                                    invLine.FIN_Amount__c += ii.FIN_ManualAmount__c;
                                }
                                invLine.FIN_SubType__c = ii.FIN_LibraryAssociation__r.FIN_SubledgerType__c;
                                invLine.FIN_Subledger__c = ii.FIN_LibraryAssociation__r.FIN_Subledger__c;
                            }

                            invoiceLinesToInsert.add(invLine);
                        }
                    }
                }
            }

            ////////////////////////////////// Addendum //////////////////////////////////
            // for each unique order, CHANNEL, event and uar
            for (Order sale : salesList) {
                //System.debug('sale : ' + sale);

                for (String channel : channelsSet) {
                    //System.debug('channel : ' + channel);

                    for (Campaign event : eventsList) {
                        //System.debug('event : ' + event);
                        for (Double uar : uniqueAppliedRateforInvoiceSet) {
                            //System.debug('uar : ' + uar);
                            if (event.FIN_LookupCode__c == sale.FIN_EventLookupCode__c) {

                                Boolean notFilled = true;

                                FIN_InvoiceLine__c invLineWithoutAccums = new FIN_InvoiceLine__c();
                                invLineWithoutAccums.FIN_ParentInvoiceSchedule__c = isId;

                                invLineWithoutAccums.FIN_Unique__c = 'Addendum';

                                invLineWithoutAccums.FIN_PriceCodeType__c = sale.FIN_PriceCodeType__c;
                                invLineWithoutAccums.FIN_EventLookup__c = sale.FIN_EventLookupCode__c;
                                invLineWithoutAccums.FIN_EventDesc__c = event.Description;

                                invLineWithoutAccums.FIN_AmountAddendum__c = 0;
                                invLineWithoutAccums.FIN_Quantity__c = 0;

                                invLineWithoutAccums.FIN_UnitCost__c = 0;

                                // list of invoice items related to this sale and event
                                for (FIN_InvoiceItem__c ii : allIIs) {

                                    if (
                                            (ii.FIN_ParentInvoiceSchedule__c == isId && ii.FIN_AppliedRateforInvoice__c == uar) &&

                                                    ii.FIN_EntryType__c == 'StandardEntry' &&

                                                    ((ii.FIN_SalesTransactions__r.OrderId == sale.Id && ii.FIN_SalesTransactions__r.Order.FIN_Event__c == event.Id && ii.FIN_SalesTransactions__r.FIN_Channel__c == channel)
                                                            || (ii.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c == sale.Id && ii.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c == event.Id && ii.FIN_PaymentDistribution__r.FIN_Channel__c == channel)
                                                            || (ii.FIN_Payment__r.FIN_Order__c == sale.Id && ii.FIN_Payment__r.FIN_Order__r.FIN_Event__c == event.Id && ii.FIN_Payment__r.FIN_Channel__c == channel))
                                    ) {

                                        System.debug('____________________Addendum____________________');
                                        notFilled = false;

                                        invLineWithoutAccums.FIN_Channel__c = channel;
                                        if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount') {
                                            invLineWithoutAccums.FIN_AccumulatorType__c = 'ByAmount';
                                            if (ii.FIN_AdjustmentforInvoice__c != null) {
                                                invLineWithoutAccums.FIN_AmountAddendum__c += ii.FIN_AdjustmentforInvoice__c;
                                            } else {
                                                invLineWithoutAccums.FIN_AmountAddendum__c += ii.FIN_TotalGrossAmountforInvoice__c;
                                            }

                                            if (ii.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_InvoiceRate_del__c != null) {
                                                invLineWithoutAccums.FIN_InvoiceRate__c = ii.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_InvoiceRate_del__c;
                                            } else if (ii.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_ParentContract__r.FIN_InvoiceRate_del__c != null) {
                                                invLineWithoutAccums.FIN_InvoiceRate__c = ii.FIN_ParentInvoiceSchedule__r.FIN_Contract__r.FIN_ParentContract__r.FIN_InvoiceRate_del__c;
                                            } else {
                                                invLineWithoutAccums.FIN_InvoiceRate__c = 100;
                                            }
                                        }

                                        if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity') {
                                            invLineWithoutAccums.FIN_AccumulatorType__c = 'ByQuantity';
                                            invLineWithoutAccums.FIN_Quantity__c += ii.FIN_QuantityforInvoiceQty__c;
                                            if (ii.FIN_AppliedRateforInvoice__c != null) {
                                                invLineWithoutAccums.FIN_AccumulationRate__c = ii.FIN_AppliedRateforInvoice__c;
                                            } else if (ii.FIN_AppliedUnitPriceforInvoice__c != null) {
                                                invLineWithoutAccums.FIN_AccumulationRate__c = ii.FIN_AppliedUnitPriceforInvoice__c;
                                            }

                                            //invLineWithoutAccums.FIN_UnitCost__c += ii.FIN_TotalGrossAmountforInvoice__c;
                                            invLineWithoutAccums.FIN_UnitCost__c = ii.FIN_BaseRateUnitCost__c;
                                        }
                                    }
                                }

                                if (!notFilled) {
                                    invoiceLinesToInsert.add(invLineWithoutAccums);
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!invoiceLinesToInsert.isEmpty()) {
            insert invoiceLinesToInsert;
        }
    }

    public static void updateConsumptionScheduleAmounts(List<FIN_InvoiceItem__c> items, Map<Id, FIN_InvoiceItem__c> oldMap) {
        Set<Id> subContractIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> isIdsSet = new Set<Id>();

        Map<Id, FIN_InvoiceItem__c> addedIIs = new Map<Id, FIN_InvoiceItem__c>();
        Map<Id, FIN_InvoiceItem__c> removedIIs = new Map<Id, FIN_InvoiceItem__c>();
        Map<Id, FIN_InvoiceItem__c> allIIs = new Map<Id, FIN_InvoiceItem__c>();

        List<FIN_InvoiceItem__c> invoiceItemsChangedApplicable = new List<FIN_InvoiceItem__c>();

        try {
            for (FIN_InvoiceItem__c item : items) {
                if (item.FIN_Applicable__c != oldMap?.get(item.Id)?.FIN_Applicable__c && item.FIN_Applicable__c == true) {
                    invoiceItemsChangedApplicable.add(item);
                }
            }

            System.debug('items.size(): ' + items.size());

            if (items != null && invoiceItemsChangedApplicable != null) {
                for (FIN_InvoiceItem__c ii : invoiceItemsChangedApplicable) {
                    if (ii.FIN_EntryType__c == 'StandardEntry') {
                        addedIIs.put(ii.id, ii);
                        allIIs.put(ii.id, ii);
                        isIdsSet.add(ii.FIN_ParentInvoiceSchedule__c);
                    }
                }
            } else {
                for (FIN_InvoiceItem__c ii : oldMap.values()) {
                    if (ii.FIN_EntryType__c == 'StandardEntry') {
                        removedIIs.put(ii.id, ii);
                        allIIs.put(ii.id, ii);
                        isIdsSet.add(ii.FIN_ParentInvoiceSchedule__c);
                    }
                }
            }

            List<FIN_InvoiceSchedule__c> isList = [
                    SELECT Id, FIN_Contract__c, FIN_Mode__c
                    FROM FIN_InvoiceSchedule__c
                    WHERE Id IN :isIdsSet
            ];

            for (FIN_InvoiceSchedule__c is : isList) {
                subContractIds.add(is.FIN_Contract__c);
            }

            for (Contract c : [
                    SELECT FIN_ParentContract__c
                    FROM Contract
                    WHERE Id IN :subContractIds
            ]) {
                contractIds.add(c.FIN_ParentContract__c);
            }

            Map<Id, ConsumptionSchedule> csToUpdate = new Map< Id, ConsumptionSchedule>();

            List<ConsumptionSchedule> allCS = [
                    SELECT Id, Contract__c, Contract__r.FIN_Region__c, FIN_Conditional_Logic__c, FIN_Starting_Ticket_Count__c,
                            Advanced_Custom_Logic__c, FIN_Starting_Revenue__c,

                            RecordType.DeveloperName,
                            FIN_CalculatedBalance__c,

                            FIN_TotalRevenue__c,
                            FIN_TotalTicketCount__c,

                            FIN_Actual_Revenue__c,
                            FIN_Actual_Count__c
                    FROM ConsumptionSchedule
                    WHERE Contract__c = :contractIds
                    AND IsActive = true
                    AND FIN_ActiveTodayBasedonDates__c = true
                    AND (RecordType.DeveloperName = 'Revenue_Amount' OR RecordType.DeveloperName = 'Ticket_Quantity')
            ];

            for (FIN_InvoiceSchedule__c is : isList) {
                for (ConsumptionSchedule cs : allCS) {
                    for (FIN_InvoiceItem__c ii : allIIs.values()) {

                        if (cs.RecordType.DeveloperName == 'Revenue_Amount'
                                && is.FIN_Mode__c == 'ByAmount'
                                && ii.FIN_ParentInvoiceSchedule__c == is.Id
                                && ii.FIN_Applicable__c == true
                        ) {

                            if (addedIIs.get(ii.id) != null) {
                                cs.FIN_Actual_Revenue__c += ii.FIN_TotalGrossAmountforInvoice__c;
                                csToUpdate.put(cs.Id, cs);
                            } else if (removedIIs.get(ii.id) != null) {
                                cs.FIN_Actual_Revenue__c -= ii.FIN_TotalGrossAmountforInvoice__c;
                                csToUpdate.put(cs.Id, cs);
                            }

                        } else if (cs.RecordType.DeveloperName == 'Ticket_Quantity'
                                && is.FIN_Mode__c == 'ByTicketQuantity'
                                && ii.FIN_ParentInvoiceSchedule__c == is.Id
                                && ii.FIN_Applicable__c == true
                        ) {

                            if (addedIIs.get(ii.id) != null) {
                                cs.FIN_Actual_Count__c += ii.FIN_QuantityforInvoiceQty__c;
                                csToUpdate.put(cs.Id, cs);
                            } else if (removedIIs.get(ii.id) != null) {
                                cs.FIN_Actual_Count__c -= ii.FIN_QuantityforInvoiceQty__c;
                                csToUpdate.put(cs.Id, cs);
                            }
                        }
                    }
                }
            }

            System.debug('csToUpdate.values().size(): ' + csToUpdate.values().size());

            update csToUpdate.values();


        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static void checkIfApplicableForConsumption(List<FIN_InvoiceItem__c> items) {
        //FIN_Applicable__c
        System.debug('checkIfApplicableForConsumption ');

        Set<Id> iiIdsSet = new Set<Id>();
        for (FIN_InvoiceItem__c ii : items) {
            iiIdsSet.add(ii.Id);
        }

        List<FIN_InvoiceItem__c> currentInvoiceItems = [
                SELECT Id, FIN_EntryType__c, FIN_TotalNetAmountforInvoice__c, FIN_QuantityforInvoiceQty__c, FIN_ParentInvoiceSchedule__c
                FROM FIN_InvoiceItem__c
                WHERE Id IN :iiIdsSet
        ];
        List<FIN_InvoiceItem__c> invoiceItemsToUpdate = new List<FIN_InvoiceItem__c>();

        Set<Id> isIdsSet = new Set<Id>();
        Set<Id> subContractIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();

        for (FIN_InvoiceItem__c ii : items) {
            if (ii.FIN_EntryType__c == 'StandardEntry') {
                isIdsSet.add(ii.FIN_ParentInvoiceSchedule__c);
            }
        }

        List<FIN_InvoiceSchedule__c> isList = [
                SELECT Id, FIN_Contract__c, FIN_Mode__c
                FROM FIN_InvoiceSchedule__c
                WHERE Id IN :isIdsSet
        ];
        List<Id> isRevenueList = new List<Id>();
        List<Id> isQtyList = new List<Id>();
        for (FIN_InvoiceSchedule__c is : isList) {
            if (is.FIN_Mode__c == 'ByAmount') {
                isRevenueList.add(is.Id);
            } else if (is.FIN_Mode__c == 'ByTicketQuantity') {
                isQtyList.add(is.Id);
            }
        }


        for (FIN_InvoiceSchedule__c is : isList) {
            subContractIds.add(is.FIN_Contract__c);
        }

        for (Contract c : [
                SELECT FIN_ParentContract__c
                FROM Contract
                WHERE Id IN :subContractIds
        ]) {
            contractIds.add(c.FIN_ParentContract__c);
        }

        List<ConsumptionSchedule> consumptionSchedule = [
                SELECT Id, Contract__c, Contract__r.FIN_Region__c, FIN_Conditional_Logic__c, FIN_Starting_Ticket_Count__c,
                        Advanced_Custom_Logic__c, FIN_Actual_Revenue__c, FIN_Starting_Revenue__c, FIN_Actual_Count__c,
                        RecordTypeId, RecordType.DeveloperName, FIN_CalculatedBalance__c, FIN_TotalRevenue__c, (
                        SELECT Id, FIN_Consumption_Schedule__c, Object__c, FIN_Object_Attribute__c, Operator__c, FIN_Value__c, FIN_Number__c
                        FROM Accumulator_Conditions__r
                ), (
                        SELECT Id, ConsumptionScheduleId, LowerBound, UpperBound, Active__c, FIN_Unit_Price__c, FIN_Rate__c, FIN_Pricing_Method__c
                        FROM ConsumptionRates
                        WHERE Active__c = true
                )
                FROM ConsumptionSchedule
                WHERE Contract__c IN :contractIds
                AND IsActive = true
                AND FIN_ActiveTodayBasedonDates__c = true
        ];

        // ConsumptionSchedules by RT:
        List<ConsumptionSchedule> csRevenueAmount = new List<ConsumptionSchedule>();
        List<ConsumptionSchedule> csTicketQty = new List<ConsumptionSchedule>();

        for (ConsumptionSchedule cs : consumptionSchedule) {
            if (cs.RecordType.DeveloperName == 'Revenue_Amount') {
                csRevenueAmount.add(cs);
            }
            if (cs.RecordType.DeveloperName == 'Ticket_Quantity') {
                csTicketQty.add(cs);
            }
        }
        System.debug('csRevenueAmount.size(): ' + csRevenueAmount.size());
        System.debug('csTicketQty.size(): ' + csTicketQty.size());

        Boolean applied;

        if (!csRevenueAmount.isEmpty()) {
            for (ConsumptionSchedule cs : csRevenueAmount) {
                Double r = 0;
                for (FIN_InvoiceItem__c ii : currentInvoiceItems) {
                    if (ii.FIN_EntryType__c == 'StandardEntry' && isRevenueList.contains(ii.FIN_ParentInvoiceSchedule__c)) {
                        r += ii.FIN_TotalNetAmountforInvoice__c;
                        applied = checkConditions(cs, ii.Id);

                        System.debug('applied ' + applied);
                        if (applied == true) {
                            if (cs.FIN_Starting_Revenue__c != null && cs.FIN_Actual_Revenue__c != null) {

                                FIN_Applied_Accumulators__c appliedAccumulator = new FIN_Applied_Accumulators__c();
                                appliedAccumulator.FIN_Applied_Tier__c = setTier(cs, cs.Id, Integer.valueOf(cs.FIN_Starting_Revenue__c + cs.FIN_Actual_Revenue__c + r));

                                System.debug('appliedAccumulator.FIN_Applied_Tier__c: ' + appliedAccumulator.FIN_Applied_Tier__c);

                                if (appliedAccumulator.FIN_Applied_Tier__c != null) {
                                    ii.FIN_Applicable__c = true;
                                    invoiceItemsToUpdate.add(ii);
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!csTicketQty.isEmpty()) {
            for (ConsumptionSchedule cs : csTicketQty) {
                Integer k = 0;
                Double r = 0;
                for (FIN_InvoiceItem__c ii : currentInvoiceItems) {
                    if (ii.FIN_EntryType__c == 'StandardEntry' && isQtyList.contains(ii.FIN_ParentInvoiceSchedule__c)) {

                        k += Integer.valueOf(ii.FIN_QuantityforInvoiceQty__c);
                        r += ii.FIN_TotalNetAmountforInvoice__c;
                        applied = checkConditions(cs, ii.Id);

                        System.debug('applied ' + applied);
                        if (applied == true) {

                            if (cs.FIN_Starting_Ticket_Count__c != null && cs.FIN_Actual_Count__c != null) {

                                FIN_Applied_Accumulators__c appliedAccumulator = new FIN_Applied_Accumulators__c();
                                appliedAccumulator.FIN_Applied_Tier__c = setTier(cs, cs.Id, Integer.valueOf(cs.FIN_Starting_Ticket_Count__c + cs.FIN_Actual_Count__c + k));

                                if (appliedAccumulator.FIN_Applied_Tier__c != null) {
                                    ii.FIN_Applicable__c = true;
                                    invoiceItemsToUpdate.add(ii);
                                }
                            }
                        }
                    }
                }
            }
        }
        System.debug('invoiceItemsToUpdate.size(): ' + invoiceItemsToUpdate.size());
        if (!invoiceItemsToUpdate.isEmpty()) {
            update invoiceItemsToUpdate;
        }
    }

    public static Boolean checkConditions(ConsumptionSchedule cs, Id ii) {
        String query = 'SELECT Id, :objName FROM FIN_InvoiceItem__c WHERE :conditions AND Id =: ii';
        List<SObject> objects = new List<SObject>();
        String conditions = '';
        Map<String, List<String>> conditionsMap = new Map<String, List<String>>();
        Map<Integer, Boolean> customLogicConditionsMap = new Map<Integer, Boolean>();
        String operator = cs.FIN_Conditional_Logic__c;
        String customExpression = cs.Advanced_Custom_Logic__c;
        List<Boolean> isApplied = new List<Boolean>();
        if (operator == 'AND' || operator == 'OR') {
            conditionsMap = new Map<String, List<String>>();
            for (Accumulator_Condition__c ac : cs.Accumulator_Conditions__r) {
                //System.debug('ac : ' + ac);
                if (ac.FIN_Object_Attribute__c != null && ac.FIN_Value__c != null && ac.Object__c != null) {
                    String condition = prepareCondition(ac);

                    String field = ac.Object__c.replace('__c', '__r') + '.' + ac.FIN_Object_Attribute__c;

                    // System.debug('field : ' + field);
                    if (conditionsMap.containsKey(field)) {
                        conditionsMap.get(field).add(condition);
                    } else {
                        conditionsMap.put(field, new List<String>{
                                condition
                        });
                    }
                    //System.debug('conditionsMap'+conditionsMap);
                }
                for (String objName : conditionsMap.keySet()) {
                    conditions = String.join(conditionsMap.get(objName), ' ' + operator + ' ');
                    System.debug('conditions ' + conditions);
                    //System.debug('objName'+objName);
                    objects = Database.query(query.replace(':objName', objName).replace(':conditions', conditions));

                    System.debug('objects' + objects);

                    System.debug(query.replace(':objName', objName).replace(':conditions', conditions));
                    isApplied.add(!objects.isEmpty());
                    System.debug('isApplied' + isApplied);
                }
            }
            System.debug('isApplied: ' + isApplied);
            if (operator == 'OR') {
                //System.debug('isApplied.contains(false);'+isApplied.contains(true));
                return isApplied.contains(true);
            } else if (operator == 'AND') {
                //System.debug('isApplied.contains(false);'+!isApplied.contains(false));
                return !isApplied.contains(false);
            } else {
                return null;
            }
        } else {
            for (Accumulator_Condition__c ac : cs.Accumulator_Conditions__r) {
                if (ac.FIN_Object_Attribute__c != null && ac.FIN_Value__c != null && ac.Object__c != null) {
                    if (customExpression.contains(String.valueOf(Math.round(ac.FIN_Number__c)))) {
                        conditions = prepareCondition(ac);
                        customLogicConditionsMap.put(Math.round(ac.FIN_Number__c), !Database.query(query
                                .replace(':objName', ac.Object__c)
                                .replace(':conditions', conditions))
                                .isEmpty());
                    }
                }
            }
            for (Integer finNumber : customLogicConditionsMap.keySet()) {
                customExpression = customExpression.replace(String.valueOf(finNumber), String.valueOf(customLogicConditionsMap.get(finNumber)));
            }
            return BooleanExpression.evaluate(customExpression);
        }
    }

    private static String prepareCondition(Accumulator_Condition__c accumulatorCondition) {
        String condition = accumulatorCondition.FIN_Object_Attribute__c;
        if (accumulatorCondition.Object__c.contains('__c')) {
            condition = accumulatorCondition.Object__c.replace('__c', '__r') + '.' + accumulatorCondition.FIN_Object_Attribute__c;
        }

        System.debug('condition: ' + condition);
        System.debug('accumulatorCondition.FIN_Value__c: ' + accumulatorCondition.FIN_Value__c);

        switch on accumulatorCondition.Operator__c {
            when '=' {
                String obj = accumulatorCondition.Object__c;
                if (obj == 'FIN_SalesTransactions__c') {
                    obj = 'OrderItem';
                }
                condition += getObjectAttributeType(accumulatorCondition.FIN_Object_Attribute__c, obj) == 'DOUBLE' ? accumulatorCondition.Operator__c + ':value' : accumulatorCondition.Operator__c + '\':value\'';
            } when '<>' {
                condition += '!=:value';
            } when 'contains' {
                condition += 'LIKE \'%:value%\'';
            }
        }
        return condition.replace(':value', accumulatorCondition.FIN_Value__c);
    }

    private static String getObjectAttributeType(String objectAttribute, String objName) {
        return Schema.getGlobalDescribe().get(objName.toLowerCase()).getDescribe().fields.getMap().get(objectAttribute).getDescribe().getType().name();
    }

    private static Id setTier(ConsumptionSchedule cs, Id csId, Integer actualCount) {
        for (ConsumptionRate rate : cs.ConsumptionRates) {
            if (rate.ConsumptionScheduleId == csId) {
                System.debug('actualCount: ' + actualCount);
                if (actualCount >= rate.LowerBound && actualCount <= rate.UpperBound) {
                    return rate.Id;
                }
            }
        }

        return null;
    }

    private static void updateRelatedRecordsStatuses(String statusField, String objectToUpdate, Set<Id> relatedRecordsIds, String statusValue) {
        List<SObject> records = new List<SObject>();
        SOQLQueryBuilder queryBuilder = new SOQLQueryBuilder()
                .selectClause()
                .field('Id')
                .field(statusField)
                .endSelectSOQL()
                .fromClause(objectToUpdate)
                .whereClause()
                .useBindVariablesInQuery(true)
                .condition('Id', relatedRecordsIds,
                        Constants.ConditionType.IN_CONDITION, null, null)
                .endWhereSOQL();
        for (SObject record : Database.queryWithBinds(queryBuilder.build(),
                queryBuilder.getBindVariables(), AccessLevel.USER_MODE)) {
            record.put(statusField, statusValue);
            records.add(record);
        }
        Database.update(records);
    }
}
