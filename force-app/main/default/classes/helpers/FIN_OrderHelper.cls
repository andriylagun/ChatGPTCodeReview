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
        //Bypass this method when CPQ SBAA Approval Status changed
        if (orders[0].ApprovalStatus__c != oldMap?.get(orders[0].Id)?.ApprovalStatus__c) {
            return;
        }

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