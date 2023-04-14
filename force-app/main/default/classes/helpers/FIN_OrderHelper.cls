public class FIN_OrderHelper {
    public static void orderSharing(List<Order> orders, Map<Id, Order> oldMap) {
        List<OrderShare> listShareRecords = new List<OrderShare>();
        //        System.debug(orders);
        //        System.debug(oldMap);


        //Bypass this method when CPQ SBAA Approval Status changed
        if (orders[0].ApprovalStatus__c != oldMap?.get(orders[0].Id)?.ApprovalStatus__c) {
            return;
        }

        Group groupUS = [
            SELECT Id
            FROM Group
            WHERE Name = :'US Region'
            LIMIT 1
        ];
        Group groupUK = [
            SELECT Id
            FROM Group
            WHERE Name = :'UK Region'
            LIMIT 1
        ];
        Group groupSWE = [
            SELECT Id
            FROM Group
            WHERE Name = :'SWE Region'
            LIMIT 1
        ];

        for (Order order : orders) {
            if (order.FIN_Region__c != oldMap?.get(order.Id)?.FIN_Region__c) {
                OrderShare newShareRecord = new OrderShare();
                newShareRecord.put('OrderAccessLevel', 'Read');
                newShareRecord.put('OrderId', order.Id);
                newShareRecord.put('RowCause', 'Manual');

                if (order.FIN_Region__c == 'US') {
                    newShareRecord.put('UserOrGroupId', groupUS.Id);
                } else if (order.FIN_Region__c == 'UK') {
                    newShareRecord.put('UserOrGroupId', groupUK.Id);
                } else if (order.FIN_Region__c == 'SWE') {
                    newShareRecord.put('UserOrGroupId', groupSWE.Id);
                }

                if (newShareRecord.UserOrGroupId != null) {
                    listShareRecords.add(newShareRecord);
                }
            }
        }
        if (Trigger.isUpdate && Trigger.isAfter) {
            //            System.debug('ords: ' + orders);
        }
        insert listShareRecords;
    }

    public static void createRetroactiveAdjustment(List<Order> orders, Map<Id, Order> oldMap) {
        List<FIN_RetroactiveAdjustment__c> retroactiveAdjustments = new List<FIN_RetroactiveAdjustment__c>();
        Id orderRecordTypeId = Schema.SObjectType.FIN_RetroactiveAdjustment__c.getRecordTypeInfosByName().get('Order').getRecordTypeId();
        Map<String, String> orderRAMap = new Map<String, String>{
            'AccountId' => 'FIN_Account__c',
            'FIN_Region__c' => 'FIN_Region__c',
            'TotalAmount' => 'FIN_AdjustmentAmount__c',
            'EffectiveDate' => 'FIN_OrderStartDate__c',
            'ContractId' => 'FIN_Contract__c',
            'FIN_Payment__c' => 'FIN_Payment__c',
            'FIN_total_sales_amount__c' => 'FIN_Total_Sales_Amount__c',
            'FIN_Total_Sales_Gross_Amoun__c' => 'FIN_Total_Sales_Gross_Amount__c',
            'Adjustment_Amount__c' => 'FIN_AdjustmentAmount__c',
            'FIN_ReferencePrice__c' => 'FIN_ReferencePrice__c'
        };

        //Bypass this method when CPQ SBAA Approval Status changed
        if (orders[0].ApprovalStatus__c != oldMap?.get(orders[0].Id)?.ApprovalStatus__c) {
            return;
        }

        for (Order order : orders) {
            Order oldO = oldMap.get(order.Id);
            Integer i = 0;

            FIN_RetroactiveAdjustment__c newRetroactiveAdjustment = new FIN_RetroactiveAdjustment__c();
            newRetroactiveAdjustment.FIN_Order__c = order.Id;
            newRetroactiveAdjustment.FIN_Account__c = order.AccountId;
            newRetroactiveAdjustment.FIN_Contract__c = order.ContractId;
            newRetroactiveAdjustment.FIN_Payment__c = order.FIN_Payment__c;
            newRetroactiveAdjustment.RecordTypeId = orderRecordTypeId;

            for (String str : orderRAMap.keyset()) {
                if (order.get(str) != oldO.get(str)) {
                    newRetroactiveAdjustment.put(orderRAMap.get(str), order.get(str));
                    i++;
                }
            }

            if (i != 0) {
                retroactiveAdjustments.add(newRetroactiveAdjustment);
            }
        }
        System.debug('orders in trigger: ' + orders.size());
        insert retroactiveAdjustments;
    }

//    public static void updateOwnerOnClassifiedRecord(List<Order> sales) {
//        for (Order sale : sales) {
//            if (!String.isBlank(sale.Owner.Name)) {
//                if (sale.Owner.Name.contains('Unclassified') && !sale.FIN_Unclassified_US__c) {
//                    sale.OwnerId = UserInfo.getUserId();
//                }
//            }
//        }
//    }

    public static void updateApprovalStatus(List<Order> sales, Map<Id, Order> oldMap) {
        for (Order order : sales) {
            System.debug('order.FIN_Auto_Approved__c'+order.FIN_Auto_Approved__c);
            System.debug('order.ApprovalStatus__c'+order.ApprovalStatus__c);
            if (!order.FIN_Auto_Approved__c && order.ApprovalStatus__c == 'Approved' && order.FIN_Total_Sales_Qty__c > 0) {
                if (order.ApprovalStatus__c != oldMap.get(order.Id).ApprovalStatus__c) {
                    order.addError('Please populate the fields required for Approval: Contract, Context, and add Sales Transactions');
                } else {
                    order.ApprovalStatus__c = 'New';
                    order.Status = 'New';
                }
            } else if (order.FIN_Auto_Approved__c && order.ApprovalStatus__c == oldMap.get(order.Id).ApprovalStatus__c && order.ApprovalStatus__c == 'New' && order.FIN_Total_Sales_Qty__c > 0) {
                order.Status = 'Approved';
                order.ApprovalStatus__c = 'Approved';
            }
        }
    }
}