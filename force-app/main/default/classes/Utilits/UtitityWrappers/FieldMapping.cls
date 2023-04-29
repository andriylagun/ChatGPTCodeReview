public class FieldMapping {
    public String sourceField {get; set;}
    public String destinationField {get; set;}
    public Boolean isMandatory {get; set;}

    public FieldMapping(String sourceField, String destinationField, Boolean isMandatory) {
        this.sourceField = sourceField;
        this.destinationField = destinationField;
        this.isMandatory = isMandatory;
    }

    public static Map<String, List<FieldMapping>> objectFieldMappings = new Map<String, List<FieldMapping>>{
            'FIN_OrderProduct__c' => new List<FieldMapping>{
                    new FieldMapping('FIN_Client__c', 'FIN_Account__c', true),
                    new FieldMapping('OrderId', 'FIN_Order__c', true),
                    new FieldMapping('FIN_PaymentDistribution__c', 'FIN_PaymentDistribution__c', true),
                    new FieldMapping('SBQQ__Contract__c', 'FIN_Contract__c', true),
                    new FieldMapping('FIN_Region__c', 'FIN_Region__c', false),
                    new FieldMapping('FIN_ActionDate__c', 'FIN_ActionDate__c', false),
                    new FieldMapping('Quantity', 'FIN_Quantity__c', false),
                    new FieldMapping('FIN_Gross_Amount__c', 'FIN_Gross_Amount__c', false),
                    new FieldMapping('FIN_Amount__c', 'FIN_Amount__c', false),
                    new FieldMapping('FIN_Tax_Amount__c', 'FIN_Tax_Amount__c', false),
                    new FieldMapping('FIN_FeeGrossAmount__c', 'FIN_FeeGrossAmount__c', false),
                    new FieldMapping('FIN_FeeNetAmount__c', 'FIN_FeeNetAmount__c', false),
                    new FieldMapping('FIN_FeeTaxAmount__c', 'FIN_FeeTaxAmount__c', false),
                    new FieldMapping('FIN_MerchGrossAmount__c', 'FIN_MerchGrossAmount__c', false),
                    new FieldMapping('FIN_MerchNetAmount__c', 'FIN_MerchNetAmount__c', false),
                    new FieldMapping('FIN_MerchTaxAmount__c', 'FIN_MerchTaxAmount__c', false),
                    new FieldMapping('FIN_CurrentPaidAmount__c', 'FIN_CurrentPaidAmount__c', false),
                    new FieldMapping('UnitPrice', 'FIN_UnitPrice__c', false)
            },
            'FIN_Payment__c' => new List<FieldMapping>{
                    new FieldMapping('FIN_Order__c', 'FIN_Order__c', true),
                    new FieldMapping('FIN_Region__c', 'FIN_Region__c', false),
                    new FieldMapping('FIN_PaymentDate__c', 'FIN_PaymentDate__c', false),
                    new FieldMapping('FIN_DepositDate__c', 'FIN_DepositDate__c', false),
                    new FieldMapping('FIN_PaymentAdjustment__c', 'FIN_PaymentAdjustment__c', false),
                    new FieldMapping('FIN_JournalEntryAmount__c', 'FIN_JournalEntryAmount__c', false)
            },
            'FIN_Order__c' => new List<FieldMapping>{
                    new FieldMapping('AccountId', 'FIN_Account__c', true),
                    new FieldMapping('FIN_Region__c', 'FIN_Region__c', false),
                    new FieldMapping('TotalAmount', 'FIN_AdjustmentAmount__c', false),
                    new FieldMapping('EffectiveDate', 'FIN_OrderStartDate__c', false),
                    new FieldMapping('ContractId', 'FIN_Contract__c', true),
                    new FieldMapping('FIN_Payment__c', 'FIN_Payment__c', true),
                    new FieldMapping('FIN_total_sales_amount__c', 'FIN_Total_Sales_Amount__c', false),
                    new FieldMapping('FIN_Total_Sales_Gross_Amoun__c', 'FIN_Total_Sales_Gross_Amount__c', false),
                    new FieldMapping('Adjustment_Amount__c', 'FIN_AdjustmentAmount__c', false),
                    new FieldMapping('FIN_ReferencePrice__c', 'FIN_ReferencePrice__c', false)
            }
    };
}