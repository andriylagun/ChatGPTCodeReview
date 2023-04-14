public class FIN_RecalculateAccumulators {
    @InvocableMethod(label='Recalculate Accumulators - Apex Action')
    public static void getInvoiceSchedule(List<FlowInputs> request) {
        Id invoiceScheduleId = request[0].invoiceScheduleId;
        Id contractId = request[0].contractId;

        ConsumptionScheduleBatch objbatch = new ConsumptionScheduleBatch(invoiceScheduleId, contractId);
        Database.executeBatch(objbatch);
    }

    public class FlowInputs {
        @InvocableVariable
        public Id invoiceScheduleId;

        @InvocableVariable
        public Id contractId;
    }
}