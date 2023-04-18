@IsTest
private class FIN_RecalculateAccumulatorsTest {
    @IsTest
    static void testGetInvoiceSchedule() {
        try {
            Account acc = TestDataFactory.createAccount();

            Contract parentContract = TestDataFactory.createParentContract(acc.Id);
            Contract contract = TestDataFactory.createContract(acc.Id, parentContract.Id);

            Order ord = TestDataFactory.createTestOrderWithContract(acc.Id, contract.Id);
            FIN_Payment__c payment = TestDataFactory.createPayment(ord.Id, contract.Id);
            FIN_PaymentDistribution__c paymentdist = TestDataFactory.createPaymentDistribution(payment.Id, null,contract.Id);
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
                Contract__c = contract.Id,
                FIN_Conditional_Logic__c = 'AND',
                FIN_Actual_Count__c = 5
            );
            insert cs;

            ConsumptionRate cr = new ConsumptionRate(
                ConsumptionScheduleId = cs.Id,
                ProcessingOrder = 1,
                LowerBound = 0,
                UpperBound = 10,
                PricingMethod = 'FlatFee',
                Price =0
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

            FIN_InvoiceSchedule__c is = TestDataFactory.createInvoiceSchedule(contract.Id);
            Map<Id, List<Id>> idIdMap2 = new Map<Id, List<Id>>();
            idIdMap2.put(contract.Id, new List<Id>{payment.Id});
            String json = JSON.serialize(idIdMap2);
            Integer result2 = InvoiceDataController.createInvoiceItems(json, 'Payments', new FIN_InvoiceSchedule__c(), is.Id);

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

//            Assert.areEqual(1, aaList.size());

        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}