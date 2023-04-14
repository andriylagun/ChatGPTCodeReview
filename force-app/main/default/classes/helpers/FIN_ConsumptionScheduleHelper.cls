public with sharing class FIN_ConsumptionScheduleHelper {
    public static void createConsumptionRate(List<ConsumptionSchedule> items, Map<Id, ConsumptionSchedule> oldMap) {
        List<ConsumptionRate> consRatesToAdd = new List<ConsumptionRate>();
        
        System.debug('createConsumptionRate');

        if (items != null) {
            System.debug('items != null');

            List<ConsumptionSchedule> csRT = [
                SELECT Id, Recoupment_Balance__c, Accumulation_to_Target__c, RecordType.DeveloperName
                FROM ConsumptionSchedule
                WHERE Id IN :items
            ];

            for (ConsumptionSchedule cs : csRT) {
                System.debug('csRecordType.DeveloperName ' + cs.RecordType.DeveloperName);
                if (cs.RecordType.DeveloperName == 'Accumulation_to_Target' || cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                    
                    System.debug('create cr');
                    
                    ConsumptionRate cr = new ConsumptionRate();
                    cr.ProcessingOrder = 1;
                    cr.Description = 'autocreated';
                    cr.LowerBound = 0;

                    if (cs.RecordType.DeveloperName == 'Advance_Recoupment' && cs.Recoupment_Balance__c != null) {
                        cr.UpperBound = Math.round(cs.Recoupment_Balance__c);
                    } else if (cs.RecordType.DeveloperName == 'Accumulation_to_Target' && cs.Accumulation_to_Target__c != null) {
                        cr.UpperBound = Math.round(cs.Accumulation_to_Target__c);
                    } else {
                        cr.UpperBound = 10;
                    }
                   
                    cr.Active__c = true;
                    cr.ConsumptionScheduleId = cs.Id;
                    cr.PricingMethod = 'PerUnit';
                    cr.Price = 0;
                    

                    System.debug('cr ---> ' + cr);

                    consRatesToAdd.add(cr);
                }
            }
        } else {
            // List<ConsumptionSchedule> csRT = [
            //     SELECT Id, Recoupment_Balance__c, Accumulation_to_Target__c, RecordType.DeveloperName
            //     FROM ConsumptionSchedule
            //     WHERE Id IN :oldMap.values()
            // ];
            // for (ConsumptionSchedule cs : oldMap.values()) {

            // }
        }

        System.debug('consRatesToAdd ---> ' + consRatesToAdd);

        if (!consRatesToAdd.isEmpty()){
            insert consRatesToAdd;
        }
    }




    // #2 Issue: User should not be able to Approve and Activate following accumulators for the same contract with the same effective dates
        // Ticket Quantity and Revenue Amount/ only one of these two can Approved and Activated
        // Advanced Recoupment and Accumulation To Target/ only one of these two can be Approved and Activated

    // #3: Add validation rule to check for duplicates within accumulation rules for the contract
    // WHEN:
        // User Activate or Approve the accumulation rule
        // User save changes to Active or Approved accumulation rule
    // IF satisfy the below criteria, consider as duplicates:
        // Only Accumulation rules within one contract
        // Only Active and Approved accumulation rules have to be checked
    // If the accumulation rules match by following conditions, consider them as duplicates (AND):
        // Same Accumulation rule type
        // Same Effective Dates
        // Same Conditions, where Object, Object Attribute, Operator and Value are the same -------> ?

    public static void checkForDuplicates(List<ConsumptionSchedule> items, Map<Id, ConsumptionSchedule> oldMap) {
        System.debug('checkForDuplicates');
        
        List<ConsumptionSchedule> triggeredCS = [
            SELECT Id, RecordType.DeveloperName, Contract__c, IsActive, FIN_ApprovalStatus__c, FIN_Start_Date__c, FIN_End_Date__c
                    ,(SELECT Id, FIN_Consumption_Schedule__c, Object__c, FIN_Object_Attribute__c, Operator__c, FIN_Value__c
                    FROM Accumulator_Conditions__r)
            FROM ConsumptionSchedule
            WHERE Id IN :items
        ];
        System.debug('triggeredCS.size() -> ' + triggeredCS.size());

        // if ConsumptionSchedule becomes approved we need to check it
        Map<Id, ConsumptionSchedule> csToCheckMap = new Map<Id, ConsumptionSchedule>();

        for (ConsumptionSchedule trCS : triggeredCS) {
            for (ConsumptionSchedule item : items) {
                if (oldMap?.get(item.Id)?.FIN_ApprovalStatus__c == 'Approved' && item.FIN_ApprovalStatus__c != oldMap?.get(item.Id)?.FIN_ApprovalStatus__c) {
                    item.FIN_DuplicateMessage__c = null;
                } else if (trCS.Id == item.Id && item.FIN_ApprovalStatus__c != oldMap?.get(item.Id)?.FIN_ApprovalStatus__c && item.FIN_ApprovalStatus__c == 'Approved') {
                    csToCheckMap.put(trCS.Id, trCS);
                } 
            }
        }
        System.debug('csToCheckMap.size() -> ' + csToCheckMap.size());

        // get all contract IDs
        Set<Id> contractsIds = new Set<Id>();
        for (ConsumptionSchedule cs : items) {
            contractsIds.add(cs.Contract__c);
        }
        System.debug('contractsIds.size() -> ' + contractsIds.size());

        // get all CSs that were approved & active before this one
        List<ConsumptionSchedule> allActiveCS = [
            SELECT Id, RecordType.DeveloperName, Contract__c, IsActive, FIN_ApprovalStatus__c, FIN_Start_Date__c, FIN_End_Date__c
                    ,(SELECT Id, FIN_Consumption_Schedule__c, Object__c, FIN_Object_Attribute__c, Operator__c, FIN_Value__c
                    FROM Accumulator_Conditions__r)
            FROM ConsumptionSchedule
            WHERE Contract__c IN :contractsIds
            AND IsActive = true
            AND FIN_ApprovalStatus__c = 'Approved'
        ];
        System.debug('allActiveCS.size() -> ' + allActiveCS.size());

        // get all related CS-conditions
        List<Accumulator_Condition__c> allActiveConditions = [
            SELECT Id, FIN_Consumption_Schedule__c, Object__c, FIN_Object_Attribute__c, Operator__c, FIN_Value__c
            FROM Accumulator_Condition__c
            WHERE FIN_Consumption_Schedule__c IN :allActiveCS
            //OR FIN_Consumption_Schedule__c IN :items
        ];
        System.debug('allActiveConditions.size() -> ' + allActiveConditions.size());
        
        //Map<Id, String> csIdMessageMap = new Map<Id, String>();
        Map<Accumulator_Condition__c, Id> conditionCSIdMap = new Map<Accumulator_Condition__c, Id>();
        for (Accumulator_Condition__c ac : allActiveConditions) {
            conditionCSIdMap.put(ac, ac.FIN_Consumption_Schedule__c);
        }

        for (Id cId : contractsIds) {
            
            //check
            for (ConsumptionSchedule item : items) {
                if (csToCheckMap.get(item.Id) != null) {
                    for (ConsumptionSchedule csA : allActiveCS) {
                        System.debug('csToCheckMap.get(item.Id) ' + csToCheckMap.get(item.Id));
                        System.debug('item.Contract__c ' + item.Contract__c);
                        System.debug('csA.Contract__c ' + csA.Contract__c);
                        System.debug('csToCheckMap.get(item.Id).RecordType.DeveloperName ' + csToCheckMap.get(item.Id).RecordType.DeveloperName);
                        System.debug('csA.RecordType.DeveloperName ' + csA.RecordType.DeveloperName);

                        if (csToCheckMap.get(item.Id) != null && item.Contract__c == cId && csA.Contract__c == cId && csToCheckMap.get(item.Id).RecordType.DeveloperName == csA.RecordType.DeveloperName) {
                            System.debug('checkkkkkkkkkkk');

                            if (item.FIN_End_Date__c != null && csA.FIN_End_Date__c != null) {
                                if (item.FIN_Start_Date__c >= csA.FIN_End_Date__c || item.FIN_End_Date__c <= csA.FIN_Start_Date__c) {
                                    System.debug('good dates');
                                    item.FIN_DuplicateMessage__c = null;
                                    //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                                } else if ((item.FIN_Start_Date__c <= csA.FIN_End_Date__c && item.FIN_Start_Date__c >= csA.FIN_Start_Date__c)
                                        || (item.FIN_End_Date__c <= csA.FIN_End_Date__c && item.FIN_End_Date__c >= csA.FIN_Start_Date__c)) {
                                    System.debug('bad dates');
                                    item.FIN_DuplicateMessage__c = 'BAD_DATES';
                                    //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                                }
                            } else if (item.FIN_End_Date__c != null && csA.FIN_End_Date__c == null) {
                                if (item.FIN_End_Date__c <= csA.FIN_Start_Date__c) {
                                    System.debug('good dates');
                                    item.FIN_DuplicateMessage__c = null;
                                    //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                                } else if (item.FIN_Start_Date__c >= csA.FIN_Start_Date__c || item.FIN_End_Date__c >= csA.FIN_Start_Date__c) {
                                    System.debug('bad dates');
                                    item.FIN_DuplicateMessage__c = 'BAD_DATES';
                                    //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                                }
                            } else if (item.FIN_End_Date__c == null && csA.FIN_End_Date__c != null) {
                                if (item.FIN_Start_Date__c >= csA.FIN_End_Date__c) {
                                    System.debug('good dates');
                                    item.FIN_DuplicateMessage__c = null;
                                    //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                                } else if (item.FIN_Start_Date__c <= csA.FIN_Start_Date__c || item.FIN_Start_Date__c <= csA.FIN_End_Date__c) {
                                    System.debug('bad dates');
                                    item.FIN_DuplicateMessage__c = 'BAD_DATES';
                                    //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                                }
                            } else if (item.FIN_End_Date__c == null && csA.FIN_End_Date__c == null) {
                                System.debug('bad dates');
                                item.FIN_DuplicateMessage__c = 'BAD_DATES';
                                //csIdMessageMap.put(item.Id, item.FIN_DuplicateMessage__c);
                            }
                        } else if (csToCheckMap.get(item.Id) != null && item.Contract__c == cId && csA.Contract__c == cId
                            && ((csToCheckMap.get(item.Id).RecordType.DeveloperName == 'Revenue_Amount' && csA.RecordType.DeveloperName == 'Ticket_Quantity')
                            || (csToCheckMap.get(item.Id).RecordType.DeveloperName == 'Ticket_Quantity' && csA.RecordType.DeveloperName == 'Revenue_Amount')
                            || (csToCheckMap.get(item.Id).RecordType.DeveloperName == 'Accumulation_to_Target' && csA.RecordType.DeveloperName == 'Advance_Recoupment')
                            || (csToCheckMap.get(item.Id).RecordType.DeveloperName == 'Advance_Recoupment' && csA.RecordType.DeveloperName == 'Accumulation_to_Target')
                        )) {
                            System.debug('checkkkkkkkkkkk');

                            if (item.FIN_End_Date__c != null && csA.FIN_End_Date__c != null) {
                                if (item.FIN_Start_Date__c >= csA.FIN_End_Date__c || item.FIN_End_Date__c <= csA.FIN_Start_Date__c) {
                                    System.debug('good dates');
                                    item.FIN_DuplicateMessage__c = null;
                                } else if ((item.FIN_Start_Date__c <= csA.FIN_End_Date__c && item.FIN_Start_Date__c >= csA.FIN_Start_Date__c)
                                        || (item.FIN_End_Date__c <= csA.FIN_End_Date__c && item.FIN_End_Date__c >= csA.FIN_Start_Date__c)) {
                                    System.debug('bad dates');
                                    item.FIN_DuplicateMessage__c = 'BAD_TYPE';
                                }
                            } else if (item.FIN_End_Date__c != null && csA.FIN_End_Date__c == null) {
                                if (item.FIN_End_Date__c <= csA.FIN_Start_Date__c) {
                                    System.debug('good dates');
                                    item.FIN_DuplicateMessage__c = null;
                                } else if (item.FIN_Start_Date__c >= csA.FIN_Start_Date__c || item.FIN_End_Date__c >= csA.FIN_Start_Date__c) {
                                    System.debug('bad dates');
                                    item.FIN_DuplicateMessage__c = 'BAD_TYPE';
                                }
                            } else if (item.FIN_End_Date__c == null && csA.FIN_End_Date__c != null) {
                                if (item.FIN_Start_Date__c >= csA.FIN_End_Date__c) {
                                    System.debug('good dates');
                                    item.FIN_DuplicateMessage__c = null;
                                } else if (item.FIN_Start_Date__c <= csA.FIN_Start_Date__c || item.FIN_Start_Date__c <= csA.FIN_End_Date__c) {
                                    System.debug('bad dates');
                                    item.FIN_DuplicateMessage__c = 'BAD_TYPE';
                                }
                            } else if (item.FIN_End_Date__c == null && csA.FIN_End_Date__c == null) {
                                System.debug('bad dates');
                                item.FIN_DuplicateMessage__c = 'BAD_TYPE';
                            }
                        } 
                    }

                    // add check by conditions
                    if (item.FIN_DuplicateMessage__c == 'BAD_DATES') {
                        System.debug('--------------------------> item.FIN_DuplicateMessage__c ' + item.FIN_DuplicateMessage__c);
                        for (ConsumptionSchedule thisCS : triggeredCS) {
                            for (Accumulator_Condition__c ac : allActiveConditions) {
                                for (Accumulator_Condition__c thisAC : thisCS.Accumulator_Conditions__r) {

                                    //System.debug('conditionCSIdMap.get(ac) ' + conditionCSIdMap.get(ac));
                                    System.debug('thisCS.Id ' + thisCS.Id);
                                    System.debug('item.Id ' + item.Id);
                                    System.debug('thisAC.Object__c ' + thisAC.Object__c);
                                    System.debug('ac.Object__c ' + ac.Object__c);
                                    System.debug('thisAC.FIN_Object_Attribute__c ' + thisAC.FIN_Object_Attribute__c);
                                    System.debug('ac.FIN_Object_Attribute__c ' + ac.FIN_Object_Attribute__c);
                                    System.debug('thisAC.Operator__c ' + thisAC.Operator__c);
                                    System.debug('ac.Operator__c ' + ac.Operator__c);
                                    System.debug('thisAC.FIN_Value__c ' + thisAC.FIN_Value__c);
                                    System.debug('ac.FIN_Value__c ' + ac.FIN_Value__c);

                                    if (
                                        //conditionCSIdMap.get(ac) == item.Id &&
                                         thisCS.Id == item.Id
                                        && thisAC.Object__c == ac.Object__c
                                        && thisAC.FIN_Object_Attribute__c == ac.FIN_Object_Attribute__c
                                        && thisAC.Operator__c == ac.Operator__c
                                        && thisAC.FIN_Value__c == ac.FIN_Value__c) {
                                        item.FIN_DuplicateMessage__c = 'BAD_CONDITIONS';
                                    } else {
                                        item.FIN_DuplicateMessage__c = null;
                                    }
                                }
                            }
                        }
                    }
                }

                System.debug('item.FIN_DuplicateMessage__c ' + item.FIN_DuplicateMessage__c);
            }
        }
    }
}