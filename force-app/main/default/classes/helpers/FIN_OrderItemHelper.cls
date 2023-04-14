public with sharing class FIN_OrderItemHelper {
    public static void updateMissingLAField(List<OrderItem> orderItems) {
        for(OrderItem orderItem : orderItems) {
            orderItem.FIN_Missing_Library_Association__c = orderItem.FIN_LibraryAssociation__c != null ? false : true;
        }
    }

    public static void createRetroactiveAdjustment(List<OrderItem> orderItems, Map<Id, OrderItem> oldMap) {
        List<FIN_RetroactiveAdjustment__c> retroactiveAdjustments = new List<FIN_RetroactiveAdjustment__c>();
        Id orderItemRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Order Product').getRecordTypeId();

        Map<String, String> orderItemRAMap = new Map<String, String>{
            'FIN_Client__c' => 'FIN_Account__c',
            'FIN_Region__c' => 'FIN_Region__c', 
            'FIN_ActionDate__c' => 'FIN_ActionDate__c',
            'SBQQ__Contract__c' => 'FIN_Contract__c',
            'FIN_PaymentDistribution__c' => 'FIN_PaymentDistribution__c',
            'Quantity' => 'FIN_Quantity__c',
            'FIN_Gross_Amount__c' => 'FIN_Gross_Amount__c',
            'FIN_Amount__c' => 'FIN_Amount__c',
            'FIN_Tax_Amount__c' => 'FIN_Tax_Amount__c',
            'FIN_FeeGrossAmount__c' => 'FIN_FeeGrossAmount__c',
            'FIN_FeeNetAmount__c' => 'FIN_FeeNetAmount__c',
            'FIN_FeeTaxAmount__c' => 'FIN_FeeTaxAmount__c',
            'FIN_MerchGrossAmount__c' => 'FIN_MerchGrossAmount__c',
            'FIN_MerchNetAmount__c' => 'FIN_MerchNetAmount__c',
            'FIN_MerchTaxAmount__c' => 'FIN_MerchTaxAmount__c',
            'FIN_CurrentPaidAmount__c' => 'FIN_CurrentPaidAmount__c',
            'UnitPrice' => 'FIN_UnitPrice__c'
        };

        for(OrderItem orderItem : orderItems) {
            OrderItem oldO = oldMap.get(orderItem.Id);
            Integer i=0;

            FIN_RetroactiveAdjustment__c newRetroactiveAdjustment = new FIN_RetroactiveAdjustment__c();
            newRetroactiveAdjustment.FIN_OrderProduct__c = orderItem.Id;
            newRetroactiveAdjustment.RecordTypeId = orderItemRecordTypeId;
            newRetroactiveAdjustment.FIN_Contract__c = orderItem.SBQQ__Contract__c;
            newRetroactiveAdjustment.FIN_Account__c = orderItem.FIN_Client__c;
            newRetroactiveAdjustment.FIN_Order__c = orderItem.OrderId;
            newRetroactiveAdjustment.FIN_PaymentDistribution__c = orderItem.FIN_PaymentDistribution__c;
            
            for(String str : orderItemRAMap.keyset()) {
                if(orderItem.get(str) != oldO.get(str)) {
                    newRetroactiveAdjustment.put(orderItemRAMap.get(str), orderItem.get(str));
                    i++;
                }
            }

            if(i != 0) {
                retroactiveAdjustments.add(newRetroactiveAdjustment);
            }
        }

        insert retroactiveAdjustments;
    }

}