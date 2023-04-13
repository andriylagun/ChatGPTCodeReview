@IsTest
private class FIN_ConsumptionScheduleHelperTest {
    @IsTest
    static void testCreateConsumptionRates() {
        try {
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
                    .get('Accumulation_to_Target').getRecordTypeId(),
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
                FIN_ApprovalStatus__c = 'Approved',
                Recoupment_Balance__c = 10
            );
            insert cs;

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

            List<ConsumptionRate> crList = [
                SELECT Id
                FROM ConsumptionRate
            ];

            System.assertEquals(1, crList.size());

        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @IsTest
    static void testCheckForDuplicates() {
        try {
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
                    .get('Accumulation_to_Target').getRecordTypeId(),
                Name = 'Test',
                FIN_Start_Date__c = Date.today(),
                FIN_End_Date__c = Date.today() + 2,
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
                FIN_ApprovalStatus__c = 'Approved',
                Recoupment_Balance__c = 10,
                Accumulation_to_Target__c = 2
            );
            insert cs;

            ConsumptionRate cr = new ConsumptionRate(
                ConsumptionScheduleId = cs.Id,
                ProcessingOrder = 3,
                LowerBound = 2,
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

            ConsumptionSchedule cs2 = new ConsumptionSchedule(
                RecordTypeId = Schema.SObjectType.ConsumptionSchedule.getRecordTypeInfosByDeveloperName()
                    .get('Accumulation_to_Target').getRecordTypeId(),
                Name = 'Test',
                FIN_Start_Date__c = Date.today()-1,
                FIN_End_Date__c = Date.today() + 2,
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
                FIN_ApprovalStatus__c = 'Approved',
                Recoupment_Balance__c = 10,
                Accumulation_to_Target__c = 2
            );
            insert cs2;

            ConsumptionRate cr2 = new ConsumptionRate(
                ConsumptionScheduleId = cs2.Id,
                ProcessingOrder = 2,
                LowerBound = 3,
                UpperBound = 10,
                PricingMethod = 'FlatFee',
                Price = 0,
                Active__c = true
            );
            insert cr2;

            Accumulator_Condition__c ac2 = new Accumulator_Condition__c(
                FIN_Consumption_Schedule__c = cs2.Id,
                FIN_Number__c = 1,
                Object__c = 'FIN_PaymentDistribution__c',
                FIN_Object_Attribute__c = 'FIN_Channel__c',
                Operator__c = '=',
                FIN_Value__c = 'Web'
            );
            insert ac2;

            cs2.IsActive = true;
            update cs2;

        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}