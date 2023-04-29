public with sharing class FIN_InvoiceScheduleHelper {
    static final String COMPLETED_CONST = 'Completed';
    static final String VOIDED_CONST = 'ToBeInvoiced';

    public static void updateStatusesAfterUpdate(List<FIN_InvoiceSchedule__c> invoices, Map<Id, FIN_InvoiceSchedule__c> oldMap) {
        Set<Id> invoiceCompleteIds = new Set<Id>();
        Set<Id> invoiceVoidIds = new Set<Id>();

        try {
            for (FIN_InvoiceSchedule__c invoice : invoices) {
                if (invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'Complete') {
                    invoiceCompleteIds.add(invoice.Id);
                } else if (invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'Void') {
                    invoiceVoidIds.add(invoice.Id);
                }
            }

            List<FIN_InvoiceItem__c> itemsComplete = [
                SELECT Id, FIN_PaymentDistribution__c, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c,
                    FIN_PaymentDistribution__r.FIN_Payment__c, FIN_Payment__c, FIN_Payment__r.FIN_Order__c, FIN_Sales__c,
                    FIN_SalesTransactions__c, FIN_SalesTransactions__r.OrderId
                FROM FIN_InvoiceItem__c
                WHERE FIN_ParentInvoiceSchedule__c IN :invoiceCompleteIds
            ];

            List<FIN_InvoiceItem__c> itemsVoid = [
                SELECT Id, FIN_PaymentDistribution__c, FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c, FIN_Sales__c,
                    FIN_Payment__c, FIN_Payment__r.FIN_Order__c, FIN_SalesTransactions__c, FIN_SalesTransactions__r.OrderId
                FROM FIN_InvoiceItem__c
                WHERE FIN_ParentInvoiceSchedule__c IN :invoiceVoidIds
            ];

            Map<String, Set<Id>> mapPDsId = new Map<String, Set<Id>>{
                COMPLETED_CONST => new Set<Id>(),
                VOIDED_CONST => new Set<Id>()
            };

            Map<String, Set<Id>> mapPaymentsId = new Map<String, Set<Id>>{
                COMPLETED_CONST => new Set<Id>(),
                VOIDED_CONST => new Set<Id>()
            };

            Map<String, Set<Id>> mapSalesId = new Map<String, Set<Id>>{
                COMPLETED_CONST => new Set<Id>(),
                VOIDED_CONST => new Set<Id>()
            };

            Map<String, Set<Id>> mapSalesTrId = new Map<String, Set<Id>>{
                COMPLETED_CONST => new Set<Id>(),
                VOIDED_CONST => new Set<Id>()
            };


            for (FIN_InvoiceItem__c item : itemsComplete) {
                mapPDsId.get(COMPLETED_CONST).add(item.FIN_PaymentDistribution__c);
                mapPaymentsId.get(COMPLETED_CONST).add(item.FIN_Payment__c);
                mapPaymentsId.get(COMPLETED_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__c);
                mapSalesId.get(COMPLETED_CONST).add(item.FIN_Sales__c);
                mapSalesId.get(COMPLETED_CONST).add(item.FIN_Payment__r.FIN_Order__c);
                mapSalesId.get(COMPLETED_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
                mapSalesId.get(COMPLETED_CONST).add(item.FIN_SalesTransactions__r.OrderId);
                mapSalesTrId.get(COMPLETED_CONST).add(item.FIN_SalesTransactions__c);
            }

            for (FIN_InvoiceItem__c item : itemsVoid) {
                mapPDsId.get(VOIDED_CONST).add(item.FIN_PaymentDistribution__c);
                mapPaymentsId.get(VOIDED_CONST).add(item.FIN_Payment__c);
                mapPaymentsId.get(VOIDED_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__c);
                mapSalesId.get(VOIDED_CONST).add(item.FIN_Sales__c);
                mapSalesId.get(VOIDED_CONST).add(item.FIN_Payment__r.FIN_Order__c);
                mapSalesId.get(VOIDED_CONST).add(item.FIN_PaymentDistribution__r.FIN_Payment__r.FIN_Order__c);
                mapSalesId.get(VOIDED_CONST).add(item.FIN_SalesTransactions__r.OrderId);
                mapSalesTrId.get(VOIDED_CONST).add(item.FIN_SalesTransactions__c);
            }

            System.debug('mapPDsId.values()' + mapPDsId.values());

        List<FIN_PaymentDistribution__c> pdList = [
            SELECT Id, Invoices_Status__c
            FROM FIN_PaymentDistribution__c
            WHERE Id IN :getSet(mapPDsId)
        ];

        for (FIN_PaymentDistribution__c pd : pdList) {
            if(mapPDsId.get(COMPLETED_CONST).contains(pd.Id)) {
                pd.Invoices_Status__c = 'Invoiced';
            } else if (mapPDsId.get(VOIDED_CONST).contains(pd.Id)) {
                pd.Invoices_Status__c = VOIDED_CONST;
            }
        }

        List<Order> salesList = [
            SELECT Id, Invoices_Status__c
            FROM Order
            WHERE Id IN :getSet(mapSalesId)
        ];

        for(Order sales: salesList) {
            if(mapSalesId.get(COMPLETED_CONST).contains(sales.Id)) {
                sales.Invoices_Status__c = 'Invoiced';
            } else if (mapSalesId.get(VOIDED_CONST).contains(sales.Id)) {
                sales.Invoices_Status__c = VOIDED_CONST;
            }
        }

        List<OrderItem> salesTrList = [
            SELECT Id, FIN_Invoices_Status__c
            FROM OrderItem
            WHERE Id IN :getSet(mapSalesTrId)
        ];

        for(OrderItem salesTr: salesTrList) {
            if(mapSalesTrId.get(COMPLETED_CONST).contains(salesTr.Id)) {
                salesTr.FIN_Invoices_Status__c = 'Invoiced';
            } else if (mapSalesTrId.get(VOIDED_CONST).contains(salesTr.Id)) {
                salesTr.FIN_Invoices_Status__c = VOIDED_CONST;
            }
        }

        List<FIN_Payment__c> paymentsList = [
            SELECT Id, FIN_Invoices_Status__c
            FROM FIN_Payment__c
            WHERE Id IN :getSet(mapPaymentsId)
        ];

        for(FIN_Payment__c payment: paymentsList) {
            if(mapPaymentsId.get(COMPLETED_CONST).contains(payment.Id)) {
                payment.FIN_Invoices_Status__c = 'Invoiced';
            } else if (mapPaymentsId.get(VOIDED_CONST).contains(payment.Id)) {
                payment.FIN_Invoices_Status__c = VOIDED_CONST;
            }
        }

        update salesList;
        update salesTrList;
        update pdList;
        update paymentsList;

        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static void createSettlementItemInvoiceAdj(List<FIN_InvoiceSchedule__c> invoices, Map<Id, FIN_InvoiceSchedule__c> oldMap) {
        List<FIN_InvoiceSchedule__c> invoiceSchedules = new List<FIN_InvoiceSchedule__c>();
        List<FIN_SettlementItem__c> settlementItems = new List<FIN_SettlementItem__c>();
        Set<Id> contractIds = new Set<Id>();

        try {
            for (FIN_InvoiceSchedule__c invoice : invoices) {
                if (invoice.FIN_SettlementSchedule__c != oldMap?.get(invoice.Id)?.FIN_SettlementSchedule__c && invoice.FIN_SettlementSchedule__c != null) {
                    invoiceSchedules.add(invoice);
                    contractIds.add(invoice.FIN_Contract__c);
                }
            }

            Map<Id, Contract> contracts = new Map<Id, Contract>([
                SELECT Id, FIN_RemittanceAccount__c
                FROM Contract
                WHERE Id IN : contractIds
            ]);

            for(FIN_InvoiceSchedule__c invoiceSchedule : invoiceSchedules) {
                System.debug('invoiceSchedule.FIN_Contract__r.FIN_ParentContract__r.FIN_RemittanceAccount__c'+invoiceSchedule.FIN_Contract__r.FIN_ParentContract__r.FIN_RemittanceAccount__c);
                System.debug('invoiceSchedule.FIN_Contract__r.FIN_ParentContract__r.'+invoiceSchedule.FIN_Contract__r.FIN_ParentContract__c);
                System.debug('invoiceSchedule.FIN_Contract__r..'+invoiceSchedule.FIN_Contract__c);
                settlementItems.add(
                    new FIN_SettlementItem__c(
                        FIN_ParentSettlementSchedule__c = invoiceSchedule.FIN_SettlementSchedule__c,
                        FIN_SubContract__c = invoiceSchedule.FIN_Contract__c,
                        FIN_InvoiceSchedule__c = invoiceSchedule.Id,
                        FIN_RemittanceAccount__c = contracts.get(invoiceSchedule.FIN_Contract__c).FIN_RemittanceAccount__c,
                        FIN_Amount__c = invoiceSchedule.FIN_NetDue__c,
                        FIN_EntryType__c = 'Invoice Adjustment'
                    )
                );
            }

            insert settlementItems;
        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static Set<Id> getSet(Map<String,Set<Id>> mapIds) {
        Set<Id> result = new Set<Id>();
        for(Set<Id> setId : mapIds.values()){
            result.addAll(setId);
        }

        result.remove(null);
        return result;
    }

    public static void updateConsumptionScheduleAmounts(List<FIN_InvoiceSchedule__c> invoices, Map<Id, FIN_InvoiceSchedule__c> oldMap) {
        Set<FIN_InvoiceSchedule__c> invoiceCompletedFromProgress = new Set<FIN_InvoiceSchedule__c>();
        Set<FIN_InvoiceSchedule__c> invoiceCompletedFromVoid = new Set<FIN_InvoiceSchedule__c>();
        Set<FIN_InvoiceSchedule__c> invoiceVoidedFromComplete = new Set<FIN_InvoiceSchedule__c>();
        Set<FIN_InvoiceSchedule__c> invoiceVoidedFromProgress = new Set<FIN_InvoiceSchedule__c>();
        Set<FIN_InvoiceSchedule__c> invoiceProgressFromVoid = new Set<FIN_InvoiceSchedule__c>();
        Set<FIN_InvoiceSchedule__c> invoiceProgressFromComplete = new Set<FIN_InvoiceSchedule__c>();
        Set<Id> subContractIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();

        try {
            for (FIN_InvoiceSchedule__c invoice : invoices) {
                if (oldMap?.get(invoice.Id)?.FIN_Status__c == 'InvoiceInProgress' && invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'Complete') {
                    invoiceCompletedFromProgress.add(invoice);
                } 
                if (oldMap?.get(invoice.Id)?.FIN_Status__c == 'InvoiceInProgress' && invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'Void') {
                    invoiceVoidedFromProgress.add(invoice);
                }
                if (oldMap?.get(invoice.Id)?.FIN_Status__c == 'Complete' && invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'Void') {
                    invoiceVoidedFromComplete.add(invoice);
                } 
                if (oldMap?.get(invoice.Id)?.FIN_Status__c == 'Complete' && invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'InvoiceInProgress') {
                    invoiceProgressFromComplete.add(invoice);
                }
                if (oldMap?.get(invoice.Id)?.FIN_Status__c == 'Void' && invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'InvoiceInProgress') {
                    invoiceProgressFromVoid.add(invoice);
                }
                if (oldMap?.get(invoice.Id)?.FIN_Status__c == 'Void' && invoice.FIN_Status__c != oldMap?.get(invoice.Id)?.FIN_Status__c && invoice.FIN_Status__c == 'Complete') {
                    invoiceCompletedFromVoid.add(invoice);
                }
                
                subContractIds.add(invoice.FIN_Contract__c);
            }
            System.debug('invoiceCompletedFromProgress.size() ' + invoiceCompletedFromProgress.size());
            System.debug('invoiceCompletedFromVoid.size() ' + invoiceCompletedFromVoid.size());
            System.debug('invoiceVoidedFromComplete.size() ' + invoiceVoidedFromComplete.size());
            System.debug('invoiceVoidedFromProgress.size() ' + invoiceVoidedFromProgress.size());
            System.debug('invoiceProgressFromVoid.size() ' + invoiceProgressFromVoid.size());
            System.debug('invoiceProgressFromComplete.size() ' + invoiceProgressFromComplete.size());
            
            for (Contract c : [
                SELECT FIN_ParentContract__c
                FROM Contract
                WHERE Id IN :subContractIds]) {
                    contractIds.add(c.FIN_ParentContract__c);
            }

            List<ConsumptionSchedule> csToUpdate = new List<ConsumptionSchedule>();

            List<ConsumptionSchedule> allCS = [
                SELECT Id, Contract__c, Contract__r.FIN_Region__c, FIN_Conditional_Logic__c, FIN_Starting_Ticket_Count__c,
                    Advanced_Custom_Logic__c, FIN_Actual_Revenue__c, FIN_Starting_Revenue__c, FIN_Actual_Count__c,

                    Starting_Balance__c, Accumulation_to_Target__c, Recoupment_Balance__c,

                    RecordType.DeveloperName,
                    FIN_CalculatedBalance__c,

                    FIN_TotalRevenue__c,
                    FIN_TotalTicketCount__c
                FROM ConsumptionSchedule
                WHERE Contract__c = :contractIds
                AND IsActive = true
                AND FIN_ActiveTodayBasedonDates__c = true
            ];

            // InvoiceInProgress -> Complete
            for (FIN_InvoiceSchedule__c invoice : invoiceCompletedFromProgress) {
                if (invoice.FIN_Mode__c == 'ByAmount') {
                    for (ConsumptionSchedule cs : allCS) {                  
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        }
                    }

                } else if (invoice.FIN_Mode__c == 'ByTicketQuantity') {
                    for (ConsumptionSchedule cs : allCS) {
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        }
                    }                           
                }
            }

            // InvoiceInProgress -> Void
            for (FIN_InvoiceSchedule__c invoice : invoiceVoidedFromProgress) {
                if (invoice.FIN_Mode__c == 'ByAmount') {
                    for (ConsumptionSchedule cs : allCS) {                  
                        if (cs.RecordType.DeveloperName == 'Revenue_Amount') {
                            cs.FIN_Actual_Revenue__c -= invoice.FIN_TotalInvoiceRegularAmountRevenue_App__c;
                            csToUpdate.add(cs);
                        } 
                    }

                } else if (invoice.FIN_Mode__c == 'ByTicketQuantity') {
                    for (ConsumptionSchedule cs : allCS) {
                        if (cs.RecordType.DeveloperName == 'Ticket_Quantity') {
                            cs.FIN_Actual_Count__c -= invoice.FIN_TotalQuantityApplicable__c;
                            csToUpdate.add(cs);
                        }
                    }                           
                }
            }

            // Complete -> Void
            for (FIN_InvoiceSchedule__c invoice : invoiceVoidedFromComplete) {
                if (invoice.FIN_Mode__c == 'ByAmount') {
                    for (ConsumptionSchedule cs : allCS) {                  
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Revenue_Amount') {
                            cs.FIN_Actual_Revenue__c -= invoice.FIN_TotalInvoiceRegularAmountRevenue_App__c;
                            csToUpdate.add(cs);
                        } 
                    }

                } else if (invoice.FIN_Mode__c == 'ByTicketQuantity') {
                    for (ConsumptionSchedule cs : allCS) {
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Ticket_Quantity') {
                            cs.FIN_Actual_Count__c -= invoice.FIN_TotalQuantityApplicable__c;
                            csToUpdate.add(cs);
                        }
                    }                           
                }
            }

            // Complete -> InvoiceInProgress
            for (FIN_InvoiceSchedule__c invoice : invoiceProgressFromComplete) {
                if (invoice.FIN_Mode__c == 'ByAmount') {
                    for (ConsumptionSchedule cs : allCS) {                  
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        }
                    }

                } else if (invoice.FIN_Mode__c == 'ByTicketQuantity') {
                    for (ConsumptionSchedule cs : allCS) {
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c -= invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        }
                    }                           
                }
            }

            // Void -> InvoiceInProgress
            for (FIN_InvoiceSchedule__c invoice : invoiceProgressFromVoid) {
                if (invoice.FIN_Mode__c == 'ByAmount') {
                    for (ConsumptionSchedule cs : allCS) {                  
                        if (cs.RecordType.DeveloperName == 'Revenue_Amount') {
                            cs.FIN_Actual_Revenue__c += invoice.FIN_TotalInvoiceRegularAmountRevenue_App__c;
                            csToUpdate.add(cs);
                        } 
                    }

                } else if (invoice.FIN_Mode__c == 'ByTicketQuantity') {
                    for (ConsumptionSchedule cs : allCS) {
                        if (cs.RecordType.DeveloperName == 'Ticket_Quantity') {
                            cs.FIN_Actual_Count__c += invoice.FIN_TotalQuantityApplicable__c;
                            csToUpdate.add(cs);
                        }
                    }                           
                }
            }

            // Void -> Complete
            for (FIN_InvoiceSchedule__c invoice : invoiceCompletedFromVoid) {
                if (invoice.FIN_Mode__c == 'ByAmount') {
                    for (ConsumptionSchedule cs : allCS) {                  
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Revenue_Amount') {
                            cs.FIN_Actual_Revenue__c += invoice.FIN_TotalInvoiceRegularAmountRevenue_App__c;
                            csToUpdate.add(cs);
                        } 
                    }

                } else if (invoice.FIN_Mode__c == 'ByTicketQuantity') {
                    for (ConsumptionSchedule cs : allCS) {
                        if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                            cs.FIN_CalculatedBalance__c += invoice.FIN_NetDue__c;
                            csToUpdate.add(cs);
                        } else if (cs.RecordType.DeveloperName == 'Ticket_Quantity') {
                            cs.FIN_Actual_Count__c += invoice.FIN_TotalQuantityApplicable__c;
                            csToUpdate.add(cs);
                        }
                    }                           
                }
            }

            // check for zero amounts
            for (ConsumptionSchedule item : csToUpdate) {
                System.debug('item.FIN_CalculatedBalance__c ' + item.FIN_CalculatedBalance__c);
                System.debug('item.Accumulation_to_Target__c ' + item.Accumulation_to_Target__c);
                System.debug('item.Starting_Balance__c ' + item.Starting_Balance__c);
                System.debug('item.Recoupment_Balance__c ' + item.Recoupment_Balance__c);
                if (item.FIN_CalculatedBalance__c < 0) {
                    item.FIN_CalculatedBalance__c = 0;
                } else if (item.Accumulation_to_Target__c != null && item.Starting_Balance__c != null && item.FIN_CalculatedBalance__c > item.Accumulation_to_Target__c - item.Starting_Balance__c) {
                    item.FIN_CalculatedBalance__c = item.Accumulation_to_Target__c - item.Starting_Balance__c;
                } else if (item.Recoupment_Balance__c != null && item.Starting_Balance__c != null && item.FIN_CalculatedBalance__c > item.Recoupment_Balance__c - item.Starting_Balance__c) {
                    item.FIN_CalculatedBalance__c = item.Recoupment_Balance__c - item.Starting_Balance__c;
                }
            }
            
            
            update csToUpdate;

        } catch (DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }

    public static void runAccumulationRulesOnInsert(List<FIN_InvoiceSchedule__c> invoices, Map<Id, FIN_InvoiceSchedule__c> oldMap) {
        for (FIN_InvoiceSchedule__c is : invoices) {
            if (is.FIN_ApplyAccumulators__c == true) {
                ConsumptionScheduleBatch objbatch = new ConsumptionScheduleBatch(is.Id, is.FIN_Contract__c);
                Database.executeBatch(objbatch);
            } 
        }
    }

    public static void runAccumulationRules(List<FIN_InvoiceSchedule__c> invoices, Map<Id, FIN_InvoiceSchedule__c> oldMap) {
        for (FIN_InvoiceSchedule__c is : invoices) {
            if (is.FIN_ApplyAccumulators__c != oldMap?.get(is.Id)?.FIN_ApplyAccumulators__c) {
                ConsumptionScheduleBatch objbatch = new ConsumptionScheduleBatch(is.Id, is.FIN_Contract__c);
                Database.executeBatch(objbatch);
            }
        }
    }
}