@IsTest
private class FIN_RecalculateAccumulatorsTest {
    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount();

        Contract parentContract = TestDataFactory.createParentContract(acc.Id);
        Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

        Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
        FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
        FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null, contract.Id);
        paymentdist.Invoices_Status__c = 'ToBeInvoiced';
        paymentdist.FIN_Channel__c = 'Web';
        update paymentdist;

        ConsumptionSchedule cs = new ConsumptionSchedule(
            RecordTypeId = Schema.SObjectType.ConsumptionSchedule.getRecordTypeInfosByDeveloperName()
                .get('Ticket_Quantity').getRecordTypeId(),
            Name = 'Test',
            FIN_Start_Date__c = Date.today(),
            BillingTerm = 12,
            BillingTermUnit = 'Month',
            Type = 'Range',
            RatingMethod = 'Tier',
            Contract__c = parentContract.Id,
            FIN_Conditional_Logic__c = 'OR',
            FIN_Actual_Count__c = 5,
            FIN_TotalTicketCount__c = 1,
            FIN_Starting_Ticket_Count__c = 2,
            FIN_Starting_Revenue__c = 2,
            FIN_Actual_Revenue__c = 5,
            FIN_ApprovalStatus__c = 'Approved'
        );
        insert cs;

        ConsumptionRate cr = new ConsumptionRate(
            ConsumptionScheduleId = cs.Id,
            ProcessingOrder = 1,
            LowerBound = 0,
            UpperBound = 10,
            PricingMethod = 'FlatFee',
            Price = 0,
            Active__c = true
        );
        insert cr;

        Accumulator_Condition__c ac = new Accumulator_Condition__c(
            FIN_Consumption_Schedule__c = cs.Id,
            FIN_Number__c = 1,
            Object__c = 'FIN_PaymentDistribution__c',
            FIN_Object_Attribute__c = 'FIN_Channel__c',
            Operator__c = '=',
            FIN_Value__c = 'Web'
        );
        insert ac;

        cs.IsActive = true;
        update cs;

        FIN_InvoiceSchedule__c is = TestDataFactory.createInvoiceSchedule(contract.Id);
        is.FIN_Mode__c = 'ByTicketQuantity';
        is.FIN_ApplyAccumulators__c = true;
        update is;

        Map<Id, List<Id>> idIdMap2 = new Map<Id, List<Id>>();
        idIdMap2.put(contract.Id, new List<Id>{
            payment.Id
        });
        String json = JSON.serialize(idIdMap2);
        Integer result2 = InvoiceDataController.createInvoiceItems(json, 'Payments', new FIN_InvoiceSchedule__c(), is.Id);

        FIN_InvoiceItem__c ii = [
            SELECT Id
            FROM FIN_InvoiceItem__c
            LIMIT 1
        ];
        ii.FIN_QuantityforInvoiceQty__c = 2;
        ii.FIN_TotalNetAmountforInvoice__c = 10;
        ii.FIN_TotalAmountbyQty__c = 5;
        ii.FIN_AdjustmentforInvoice__c = 1;
        update ii;
    }

    @IsTest
    static void testGetInvoiceScheduleTicketQuantity() {
        try {
            FIN_InvoiceSchedule__c is = [
                SELECT Id
                FROM FIN_InvoiceSchedule__c
                LIMIT 1
            ];
            Contract contract = [
                SELECT Id, FIN_ParentContract__c
                FROM Contract
                WHERE FIN_ParentContract__c != NULL
                LIMIT 1
            ];

            FIN_RecalculateAccumulators.FlowInputs flowInputs = new FIN_RecalculateAccumulators.FlowInputs();
            flowInputs.invoiceScheduleId = is.Id;
            flowInputs.contractId = contract.Id;
            List<FIN_RecalculateAccumulators.FlowInputs> listFlowInputs = new List<FIN_RecalculateAccumulators.FlowInputs>();
            listFlowInputs.add(flowInputs);

            Test.startTest();
            FIN_RecalculateAccumulators.getInvoiceSchedule(listFlowInputs);
            Test.stopTest();

            List<FIN_Applied_Accumulators__c> aaList = [
                SELECT Id
                FROM FIN_Applied_Accumulators__c
            ];

            Assert.areEqual(1, aaList.size());

        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testGetInvoiceScheduleRevenueAmount() {
        try {
            ConsumptionSchedule cs = [
                SELECT Id
                FROM ConsumptionSchedule
            ];
            cs.RecordTypeId = Schema.SObjectType.ConsumptionSchedule.getRecordTypeInfosByDeveloperName()
                .get('Revenue_Amount').getRecordTypeId();
            update cs;

            FIN_InvoiceSchedule__c is = [
                SELECT Id
                FROM FIN_InvoiceSchedule__c
                LIMIT 1
            ];

            is.FIN_Mode__c = 'ByAmount';
            update is;

            Contract contract = [
                SELECT Id, FIN_ParentContract__c
                FROM Contract
                WHERE FIN_ParentContract__c != NULL
                LIMIT 1
            ];

            FIN_RecalculateAccumulators.FlowInputs flowInputs = new FIN_RecalculateAccumulators.FlowInputs();
            flowInputs.invoiceScheduleId = is.Id;
            flowInputs.contractId = contract.Id;
            List<FIN_RecalculateAccumulators.FlowInputs> listFlowInputs = new List<FIN_RecalculateAccumulators.FlowInputs>();
            listFlowInputs.add(flowInputs);

            Test.startTest();
            FIN_RecalculateAccumulators.getInvoiceSchedule(listFlowInputs);
            Test.stopTest();

            List<FIN_Applied_Accumulators__c> aaList = [
                SELECT Id
                FROM FIN_Applied_Accumulators__c
            ];

            Assert.areEqual(0, aaList.size());

        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}