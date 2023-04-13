public with sharing class FIN_InvoiceItemHelper {
    static final String PDS_CONST = 'PDs';
    static final String PAYMENTS_CONST = 'Payments';
    static final String SALES_CONST = 'Sales';
    static final String SALESTR_CONST = 'SalesTransactions';
    static final String INVOICE_SCHEDULED_CONST = 'InvoiceScheduled';

    public static void updateStatusesAfterInsert(List<FIN_InvoiceItem__c> items, Map<Id, FIN_InvoiceItem__c> oldMap) {
        try {
            Map<String, Set<Id>> mapObjIds = new Map<String, Set<Id>>{
            PDS_CONST => new Set<Id>(),
            PAYMENTS_CONST => new Set<Id>(),
            SALES_CONST => new Set<Id>(),
            SALESTR_CONST => new Set<Id>()
        };
        
        for (FIN_InvoiceItem__c item : [
            SELECT Id, FIN_PaymentDistribution__c, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c,
            FIN_Payment__c, FIN_Payment__r.FIN_Order__c, FIN_Sales__c, FIN_SalesTransactions__c, FIN_SalesTransactions__r.OrderId
            FROM FIN_InvoiceItem__c
            WHERE Id IN :items
            ]) {
            mapObjIds.get(PDS_CONST).add(item.FIN_PaymentDistribution__c);
            mapObjIds.get(PAYMENTS_CONST).add(item.FIN_Payment__c);
            mapObjIds.get(PAYMENTS_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_Sales__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_Payment__r.FIN_Order__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
            mapObjIds.get(SALES_CONST).add(item.FIN_SalesTransactions__r.OrderId);
            mapObjIds.get(SALESTR_CONST).add(item.FIN_SalesTransactions__c);
        }
        
        List<FIN_PaymentDistribution__c> pdList = new List<FIN_PaymentDistribution__c>();
        
        for (FIN_PaymentDistribution__c pd : [
            SELECT Id, Invoices_Status__c
            FROM FIN_PaymentDistribution__c
            WHERE Id IN :mapObjIds.get(PDS_CONST)
        ]) {
            pd.Invoices_Status__c = INVOICE_SCHEDULED_CONST;
            pdList.add(pd);
        }
        if (!pdList.isEmpty()) {
            update pdList;
        }
        
        List<Order> salesList = new List<Order>();
        
        for (Order sales : [
            SELECT Id, Invoices_Status__c
            FROM Order
            WHERE Id IN :mapObjIds.get(SALES_CONST)
        ]) {
            sales.Invoices_Status__c = INVOICE_SCHEDULED_CONST;
            salesList.add(sales);
        }
        if (!salesList.isEmpty()) {
        update salesList;
        }
        
        List<OrderItem> salesTrList = new List<OrderItem>();
        
        for (OrderItem salesTr : [
        SELECT Id, FIN_Invoices_Status__c
        FROM OrderItem
        WHERE Id IN :mapObjIds.get(SALESTR_CONST)
        ]) {
        salesTr.FIN_Invoices_Status__c = INVOICE_SCHEDULED_CONST;
        salesTrList.add(salesTr);
        }
        
        if (!salesTrList.isEmpty()) {
        update salesTrList;
        }
        
        List<FIN_Payment__c> paymentsList = new List<FIN_Payment__c>();
        
        for (FIN_Payment__c payment : [
        SELECT Id, FIN_Invoices_Status__c
        FROM FIN_Payment__c
        WHERE Id IN :mapObjIds.get(PAYMENTS_CONST)
        ]) {
        payment.FIN_Invoices_Status__c = INVOICE_SCHEDULED_CONST;
        paymentsList.add(payment);
        }
        
        if (!paymentsList.isEmpty()) {
        update paymentsList;
        }
        } catch (DmlException e) {
        System.debug('The following exception has occurred: ' + e.getMessage());
        }
        }
        
        public static void updateStatusesBeforeDelete(Map<Id, FIN_InvoiceItem__c> itemsInv) {
        try {
        Map<String, Set<Id>> mapObjIds = new Map<String, Set<Id>>{
        PDS_CONST => new Set<Id>(),
        PAYMENTS_CONST => new Set<Id>(),
        SALES_CONST => new Set<Id>(),
        SALESTR_CONST => new Set<Id>()
        };
        
        for (FIN_InvoiceItem__c item : [
        SELECT Id, FIN_PaymentDistribution__c, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c,
        FIN_Payment__c, FIN_Payment__r.FIN_Order__c, FIN_Sales__c, FIN_SalesTransactions__c, FIN_SalesTransactions__r.OrderId
        FROM FIN_InvoiceItem__c
        WHERE Id IN :itemsInv.keySet()
        ]) {
        mapObjIds.get(PDS_CONST).add(item.FIN_PaymentDistribution__c);
        mapObjIds.get(PAYMENTS_CONST).add(item.FIN_Payment__c);
        mapObjIds.get(PAYMENTS_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__c);
        mapObjIds.get(SALES_CONST).add(item.FIN_Sales__c);
        mapObjIds.get(SALES_CONST).add(item.FIN_Payment__r.FIN_Order__c);
        mapObjIds.get(SALES_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
        mapObjIds.get(SALES_CONST).add(item.FIN_SalesTransactions__r.OrderId);
        mapObjIds.get(SALESTR_CONST).add(item.FIN_SalesTransactions__c);
        }
        
        //ToDo add functionality if all PDs from Sales is ToBeInvoiced -> Sales become ToBeInvoiced
        List<FIN_PaymentDistribution__c> pdList = new List<FIN_PaymentDistribution__c>();
        if (!mapObjIds.get(PDS_CONST).isEmpty()) {
        for (FIN_PaymentDistribution__c pd : [
        SELECT Id, Invoices_Status__c, FIN_Payment__r.FIN_Order__c
        FROM FIN_PaymentDistribution__c
        WHERE Id IN :mapObjIds.get(PDS_CONST)
        ]) {
        pd.Invoices_Status__c = 'ToBeInvoiced';
        pdList.add(pd);
        }
        }
        
        if (!pdList.isEmpty()) {
        update pdList;
        }
        
        List<Order> salesList = new List<Order>();
        if (!mapObjIds.get(SALES_CONST).isEmpty()) {
        for (Order sales : [
        SELECT Id, Invoices_Status__c
        FROM Order
        WHERE Id IN :mapObjIds.get(SALES_CONST)
        ]) {
        sales.Invoices_Status__c = 'ToBeInvoiced';
        salesList.add(sales);
        }
        }
        if (!salesList.isEmpty()) {
        update salesList;
        }
        
        List<OrderItem> salesTrList = new List<OrderItem> ();
        if (!mapObjIds.get(SALESTR_CONST).isEmpty()) {
        for (OrderItem salesTr : [
        SELECT Id, FIN_Invoices_Status__c
        FROM OrderItem
        WHERE Id IN :mapObjIds.get(SALESTR_CONST)
        ]) {
        salesTr.FIN_Invoices_Status__c = 'ToBeInvoiced';
        salesTrList.add(salesTr);
        }
        }
        
        if (!salesTrList.isEmpty()) {
        update salesTrList;
        }
        
        List<FIN_Payment__c> paymentList = new List<FIN_Payment__c>();
        if (!mapObjIds.get(PAYMENTS_CONST).isEmpty()) {
        for (FIN_Payment__c payment : [
        SELECT Id, FIN_Invoices_Status__c
        FROM FIN_Payment__c
        WHERE Id IN :mapObjIds.get(PAYMENTS_CONST)
        ]) {
        payment.FIN_Invoices_Status__c = 'ToBeInvoiced';
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

    public static void createInvoiceLines(List<FIN_InvoiceItem__c> items, Map<Id, FIN_InvoiceItem__c> oldMap) {
        
        //get all related invoice items
        Set<Id> parentInvoiceScheduleIDs = new Set<Id>();
        
        if (items != null) {
            for(FIN_InvoiceItem__c ii : items) {
                parentInvoiceScheduleIDs.add(ii.FIN_ParentInvoiceSchedule__c);
            }
        } else {
            for(FIN_InvoiceItem__c ii : oldMap.values()) {
                parentInvoiceScheduleIDs.add(ii.FIN_ParentInvoiceSchedule__c);
            }
        }
        

        // remove existing settlement lines
        List<FIN_InvoiceLine__c> invoiceLinesToRemove = [
            SELECT Id
            FROM FIN_InvoiceLine__c
            WHERE FIN_ParentInvoiceSchedule__c IN :parentInvoiceScheduleIDs
        ];

        delete invoiceLinesToRemove; 


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

                                    (   (ii.FIN_SalesTransactions__r.OrderId == sale.Id                       && ii.FIN_SalesTransactions__r.Order.FIN_Event__c == event.Id                         && ii.FIN_SalesTransactions__r.FIN_Channel__c == channel) 
                                    ||  (ii.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c == sale.Id && ii.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__r.FIN_Event__c == event.Id && ii.FIN_PaymentDistribution__r.FIN_Channel__c == channel)
                                    ||  (ii.FIN_Payment__r.FIN_Order__c == sale.Id                            && ii.FIN_Payment__r.FIN_Order__r.FIN_Event__c == event.Id                            && ii.FIN_Payment__r.FIN_Channel__c == channel)    )
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

        try {

            if (items != null) {
                for (FIN_InvoiceItem__c ii : items) {
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
                WHERE Id IN :subContractIds]) {
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
                AND (RecordType.DeveloperName = 'Revenue_Amount' OR RecordType.DeveloperName = 'Ticket_Quantity')
            ];

            for (FIN_InvoiceSchedule__c is : isList) {
                for (ConsumptionSchedule cs : allCS) {
                    for (FIN_InvoiceItem__c ii : allIIs.values()) {
                    
                        if (cs.RecordType.DeveloperName == 'Revenue_Amount'
                            && is.FIN_Mode__c == 'ByAmount'
                            && ii.FIN_ParentInvoiceSchedule__c == is.Id 
                            //&& ii.FIN_Applied__c == true
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
                                //&& ii.FIN_Applied__c == true 
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

            update csToUpdate.values();

        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
}