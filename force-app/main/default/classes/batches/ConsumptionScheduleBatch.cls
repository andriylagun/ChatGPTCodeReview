global class ConsumptionScheduleBatch implements Database.Batchable<sObject> {
    global Id invoiceScheduleId;
    global Id contractId;

    global ConsumptionScheduleBatch(Id invoiceScheduleId, Id contractId) {
        this.invoiceScheduleId = invoiceScheduleId;
        this.contractId = [
            SELECT FIN_ParentContract__c
            FROM Contract
            WHERE Id = :contractId
        ].FIN_ParentContract__c;
    }

    public List<sObject> start(Database.BatchableContext BC) {
        List<sObject> scope = new List<sObject>();
        scope.addAll([
            SELECT Id, Contract__c, Contract__r.FIN_Region__c, FIN_Conditional_Logic__c, FIN_Starting_Ticket_Count__c,
                    Advanced_Custom_Logic__c, FIN_Actual_Revenue__c, FIN_Starting_Revenue__c, FIN_Actual_Count__c,
                    RecordTypeId, RecordType.DeveloperName, FIN_CalculatedBalance__c, FIN_TotalRevenue__c,
                        (SELECT Id, FIN_Consumption_Schedule__c, Object__c, FIN_Object_Attribute__c, Operator__c, FIN_Value__c, FIN_Number__c
                        FROM Accumulator_Conditions__r),
                        (SELECT Id, ConsumptionScheduleId, LowerBound, UpperBound, Active__c, FIN_Unit_Price__c, FIN_Rate__c, FIN_Pricing_Method__c
                        FROM ConsumptionRates
                        WHERE Active__c = true )
            FROM ConsumptionSchedule
            WHERE Contract__c = :contractId AND IsActive = true
            AND FIN_ActiveTodayBasedonDates__c = true
        ]);
        scope.addAll([
            SELECT Id, FIN_QuantityforInvoiceQty__c,
                    FIN_TotalNetAmountforInvoice__c,
                    FIN_BaseRateUnitCost__c,

                    FIN_AppliedRateforInvoice__c,
                    FIN_AppliedUnitPriceforInvoice__c, 
                    FIN_AdjustmentforInvoice__c,
                    FIN_TotalAmountbyQty__c,
                    FIN_AmountbyQty__c,

                    FIN_EntryType__c,

                    FIN_ParentInvoiceSchedule__r.FIN_Mode__c,
                    FIN_ParentInvoiceSchedule__r.FIN_ApplyAccumulators__c,
                    FIN_ParentInvoiceSchedule__c
            FROM FIN_InvoiceItem__c
            WHERE FIN_ParentInvoiceSchedule__c = :invoiceScheduleId
            ORDER BY FIN_AppliedRateforInvoice__c
        ]);

        return scope;
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<ConsumptionSchedule> consumptionSchedule = new List<ConsumptionSchedule>();
        List<FIN_InvoiceItem__c> invoiceItems = new List<FIN_InvoiceItem__c>();
        List<FIN_InvoiceItem__c> invoiceItemsToUpdate = new List<FIN_InvoiceItem__c>();
        List<FIN_InvoiceItem__c> iiToUpdate = new List<FIN_InvoiceItem__c>();

        for (sObject obj : scope) {
            switch on obj {
                when ConsumptionSchedule cs {
                    consumptionSchedule.add(cs);
                }
                when FIN_InvoiceItem__c ii {
                    invoiceItems.add(ii);
                }
            }
        }

        /////////////////////////////// UPDATE Consumption Schedules ///////////////////////////////

        // ConsumptionSchedules by RT:
        List<ConsumptionSchedule> csRevenueAmount = new List<ConsumptionSchedule>();
        List<ConsumptionSchedule> csTicketQty = new List<ConsumptionSchedule>();
        List<ConsumptionSchedule> csAccumToTarget = new List<ConsumptionSchedule>();
        List<ConsumptionSchedule> csAdvanceRecoupment = new List<ConsumptionSchedule>();
        // ConsumptionSchedules to update
        List<ConsumptionSchedule> csToUpdate = new List<ConsumptionSchedule>();
        
        
        for (ConsumptionSchedule cs : consumptionSchedule) {
            System.debug('cs.RecordType.DeveloperName: ' + cs.RecordType.DeveloperName);
            if (cs.RecordType.DeveloperName == 'Revenue_Amount') {
                csRevenueAmount.add(cs);
            }
            if (cs.RecordType.DeveloperName == 'Ticket_Quantity') {
                csTicketQty.add(cs);
            }
            if (cs.RecordType.DeveloperName == 'Accumulation_to_Target') {
                csAccumToTarget.add(cs);
            }
            if (cs.RecordType.DeveloperName == 'Advance_Recoupment') {
                csAdvanceRecoupment.add(cs);
            }
        }
        System.debug('csRevenueAmount.size(): ' + csRevenueAmount.size());
        System.debug('csTicketQty.size(): ' + csTicketQty.size());
        System.debug('csAccumToTarget.size(): ' + csAccumToTarget.size());
        System.debug('csAdvanceRecoupment.size(): ' + csAdvanceRecoupment.size());
        
        // remove existing
        List<FIN_Applied_Accumulators__c> appliedAccumulatorsToRemove = [
            SELECT Id
            FROM FIN_Applied_Accumulators__c
            WHERE FIN_Invoice_Item__r.FIN_ParentInvoiceSchedule__c = :invoiceScheduleId
            OR FIN_Invoice_Item__c = null
        ];
        
        if (!appliedAccumulatorsToRemove.isEmpty()) {
            delete appliedAccumulatorsToRemove;
        }
        
        // update ii
        for (FIN_InvoiceItem__c ii : invoiceItems) {
            if (ii.FIN_EntryType__c == 'StandardEntry') {
                ii.FIN_AppliedRateforInvoice__c = null;
                ii.FIN_AppliedUnitPriceforInvoice__c = null;
                ii.FIN_AdjustmentforInvoice__c = null;
                ii.FIN_TotalAmountbyQty__c = null;
                ii.FIN_AmountbyQty__c = ii.FIN_QuantityforInvoiceQty__c * ii.FIN_BaseRateUnitCost__c;
                iiToUpdate.add(ii);
            }
        }
        update iiToUpdate;
        
        // add new
        List<FIN_Applied_Accumulators__c> appliedAccumulatorsToAdd = new List<FIN_Applied_Accumulators__c>();
        
        Boolean applied;

        // separate by 4 types
        if (!csRevenueAmount.isEmpty()) {
            for (ConsumptionSchedule cs : csRevenueAmount) {
                Double r = 0;
                for (FIN_InvoiceItem__c ii : invoiceItems) {
                    if (ii.FIN_EntryType__c == 'StandardEntry' && ii.FIN_ParentInvoiceSchedule__r.FIN_ApplyAccumulators__c == true && ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount') {

                        r += ii.FIN_TotalNetAmountforInvoice__c;
                        applied = checkConditions(cs, ii.Id);

                        if (applied == false) {
                            ///////////////////////////////////////// AMOUNT /////////////////////////////////////////
                            if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByAmount' && cs.FIN_Starting_Revenue__c != null && cs.FIN_Actual_Revenue__c != null) {

                                FIN_Applied_Accumulators__c appliedAccumulator = new FIN_Applied_Accumulators__c(
                                    FIN_Invoice_Schedule__c = invoiceScheduleId,
                                    FIN_Invoice_Item__c = ii.Id,
                                    FIN_Applied__c = applied,
                                    FIN_Consumption_Schedule__c = cs.Id,

                                    // value from raw data
                                    FIN_Calculated_Revenue__c = ii.FIN_TotalNetAmountforInvoice__c,
                                    // new field to calculate sum for previous_only invoice items of this invoice schedule
                                    FIN_CalculatedActualRevenue__c = r - ii.FIN_TotalNetAmountforInvoice__c,
                                    // for each = FIN_Actual_Revenue__c from CS
                                    FIN_Actual_Revenue__c = cs.FIN_Actual_Revenue__c,
                                    // starting + actual + calculated + calculatedactual from previous
                                    FIN_Total_Revenue__c = cs.FIN_Starting_Revenue__c + cs.FIN_Actual_Revenue__c + r
                                );

                                appliedAccumulator.FIN_Applied_Tier__c = setTier(cs, cs.Id, Integer.valueOf(cs.FIN_Starting_Revenue__c + cs.FIN_Actual_Revenue__c + r));

                                // here is to update csAdvanceRecoupment and csAccumToTarget lookups on applied accum
                                if (!csAdvanceRecoupment.isEmpty()) {
                                    for (ConsumptionSchedule csAR : csAdvanceRecoupment) {
                                        appliedAccumulator.FIN_AdvancedRecoupmentCS__c = csAR.Id;
                                    }
                                }
                                if (!csAccumToTarget.isEmpty()) {
                                    for (ConsumptionSchedule csAT : csAccumToTarget) {
                                        appliedAccumulator.FIN_AccumulationtoTargetCS__c = csAT.Id;
                                    }
                                }

                                if (appliedAccumulator.FIN_Applied_Tier__c != null) {
                                    appliedAccumulatorsToAdd.add(appliedAccumulator);
                                    
                                    // Consumption Rate Pricing_Method by unit price or by rate
                                    for(ConsumptionRate rate : cs.ConsumptionRates) {
                                        if(rate.ConsumptionScheduleId == cs.Id && appliedAccumulator.FIN_Applied_Tier__c == rate.Id && appliedAccumulator.FIN_Invoice_Item__c == ii.Id) {
                                            if (rate.FIN_Pricing_Method__c == 'Flat Rate (%)' && rate.FIN_Rate__c != null) {
                                                ii.FIN_AppliedRateforInvoice__c = rate.FIN_Rate__c;
                                            } else if (rate.FIN_Pricing_Method__c == 'Unit Price' && rate.FIN_Unit_Price__c != null) {
                                                ii.FIN_AppliedUnitPriceforInvoice__c = rate.FIN_Unit_Price__c;
                                            }
                                        }
                                    }

                                    // calculate adjustment for invoice
                                    if (ii.FIN_AppliedRateforInvoice__c != null) {
                                        ii.FIN_AdjustmentforInvoice__c = ii.FIN_AppliedRateforInvoice__c * ii.FIN_TotalNetAmountforInvoice__c / 100;
                                    } else if (ii.FIN_AppliedUnitPriceforInvoice__c != null) {
                                        ii.FIN_AdjustmentforInvoice__c = ii.FIN_AppliedUnitPriceforInvoice__c;
                                    }
                            
                                    invoiceItemsToUpdate.add(ii);

                                    // //update cs:
                                    // cs.FIN_TotalRevenue__c += ii.FIN_AdjustmentforInvoice__c;
                                    // csToUpdate.add(cs);
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!csTicketQty.isEmpty()) {
            //System.debug('csTicketQty IS NOT EMPTY: ' + csTicketQty);

            for (ConsumptionSchedule cs : csTicketQty) {
                Integer k = 0;
                Double r = 0;
                for (FIN_InvoiceItem__c ii : invoiceItems) {
                    if (ii.FIN_EntryType__c == 'StandardEntry' && ii.FIN_ParentInvoiceSchedule__r.FIN_ApplyAccumulators__c == true && ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity') {

                        k += Integer.valueOf(ii.FIN_QuantityforInvoiceQty__c);
                        r += ii.FIN_TotalNetAmountforInvoice__c;
                        applied = checkConditions(cs, ii.Id);

                        if (applied == false) {
                            ///////////////////////////////////////// QUANTITY /////////////////////////////////////////
                            if (ii.FIN_ParentInvoiceSchedule__r.FIN_Mode__c == 'ByTicketQuantity' && cs.FIN_Starting_Ticket_Count__c != null && cs.FIN_Actual_Count__c != null) {
                               
                                FIN_Applied_Accumulators__c appliedAccumulator = new FIN_Applied_Accumulators__c(
                                    FIN_Invoice_Schedule__c = invoiceScheduleId,
                                    FIN_Invoice_Item__c = ii.Id,
                                    FIN_Applied__c = applied,
                                    FIN_Consumption_Schedule__c = cs.Id,

                                    // value from raw data
                                    FIN_Calculated_Ticket_Count__c = ii.FIN_QuantityforInvoiceQty__c,
                                    // new field to calculate sum for previous_only invoice items of this invoice schedule
                                    FIN_CalculatedActualTicketCount__c = k - ii.FIN_QuantityforInvoiceQty__c,
                                    // for each = FIN_Actual_Count__c from CS
                                    FIN_Actual_Ticket_Count__c = cs.FIN_Actual_Count__c,
                                    // starting + actual + calculated + calculatedactual from previous
                                    FIN_Total_Ticket_Count__c = cs.FIN_Starting_Ticket_Count__c + cs.FIN_Actual_Count__c + k
                                );

                                appliedAccumulator.FIN_Applied_Tier__c = setTier(cs, cs.Id, Integer.valueOf(cs.FIN_Starting_Ticket_Count__c + cs.FIN_Actual_Count__c + k));

                                // here is to update csAdvanceRecoupment and csAccumToTarget lookups on applied accum
                                if (!csAdvanceRecoupment.isEmpty()) {
                                    for (ConsumptionSchedule csAR : csAdvanceRecoupment) {
                                        appliedAccumulator.FIN_AdvancedRecoupmentCS__c = csAR.Id;
                                    }
                                }
                                if (!csAccumToTarget.isEmpty()) {
                                    for (ConsumptionSchedule csAT : csAccumToTarget) {
                                        appliedAccumulator.FIN_AccumulationtoTargetCS__c = csAT.Id;
                                    }
                                }

                                ii.FIN_AmountbyQty__c = ii.FIN_QuantityforInvoiceQty__c * ii.FIN_BaseRateUnitCost__c;

                                if (appliedAccumulator.FIN_Applied_Tier__c != null) {
                                    appliedAccumulatorsToAdd.add(appliedAccumulator);
                                    
                                    // Consumption Rate Pricing_Method by unit price or by rate
                                    for(ConsumptionRate rate : cs.ConsumptionRates) {
                                        if(rate.ConsumptionScheduleId == cs.Id && appliedAccumulator.FIN_Applied_Tier__c == rate.Id && appliedAccumulator.FIN_Invoice_Item__c == ii.Id) {
                                            if (rate.FIN_Pricing_Method__c == 'Flat Rate (%)' && rate.FIN_Rate__c != null) {
                                                ii.FIN_AppliedRateforInvoice__c = rate.FIN_Rate__c;
                                            } else if (rate.FIN_Pricing_Method__c == 'Unit Price' && rate.FIN_Unit_Price__c != null) {
                                                ii.FIN_AppliedUnitPriceforInvoice__c = rate.FIN_Unit_Price__c;
                                            }
                                        }
                                    }

                                    // calculate adjustment for invoice
                                    if (ii.FIN_AppliedRateforInvoice__c != null) {
                                        ii.FIN_AdjustmentforInvoice__c = ii.FIN_AppliedRateforInvoice__c * ii.FIN_BaseRateUnitCost__c / 100;
                                    } else if (ii.FIN_AppliedUnitPriceforInvoice__c != null) {
                                        ii.FIN_AdjustmentforInvoice__c = ii.FIN_AppliedUnitPriceforInvoice__c;
                                    }
                                    ii.FIN_TotalAmountbyQty__c = ii.FIN_QuantityforInvoiceQty__c * ii.FIN_AdjustmentforInvoice__c; 

                                    invoiceItemsToUpdate.add(ii);
                                }   
                            }
                        }
                    }
                }
            }
        }

        System.debug('appliedAccumulatorsToAdd.size() -> ' + appliedAccumulatorsToAdd.size());
        
        
        update invoiceItemsToUpdate;
        insert appliedAccumulatorsToAdd;
    }

    private static Boolean checkConditions(ConsumptionSchedule cs, Id ii) {
        String query = 'SELECT Id, :objName FROM FIN_InvoiceItem__c WHERE :conditions AND Id =: ii';
        List<SObject> objects = new List<SObject>();
        String conditions = '';
        Map<String, List<String>> conditionsMap = new Map<String, List<String>>();
        Map<Integer, Boolean> customLogicConditionsMap = new Map<Integer, Boolean>();
        String operator = cs.FIN_Conditional_Logic__c;
        String customExpression = cs.Advanced_Custom_Logic__c;
        List<Boolean> isApplied = new List<Boolean>();
        if (operator == 'AND' || operator == 'OR') {
            conditionsMap = new Map<String, List<String>>();
            for (Accumulator_Condition__c ac : cs.Accumulator_Conditions__r) {
                //System.debug('ac'+ac);
                if (ac.FIN_Object_Attribute__c != null && ac.FIN_Value__c != null && ac.Object__c != null) {
                    String condition = prepareCondition(ac);

                    String field = ac.Object__c.replace('__c', '__r') + '.' + ac.FIN_Object_Attribute__c;

                    //System.debug('field'+field);
                    if (conditionsMap.containsKey(field)) {
                        conditionsMap.get(field).add(condition);
                    } else {
                        conditionsMap.put(field, new List<String>{
                            condition
                        });
                    }
                    //System.debug('conditionsMap'+conditionsMap);
                }
                for (String objName : conditionsMap.keySet()) {
                    conditions = String.join(conditionsMap.get(objName), ' ' + operator + ' ');
                    //System.debug('conditions'+conditions);
                    //System.debug('objName'+objName);
                    objects = Database.query(query.replace(':objName', objName).replace(':conditions', conditions));

                    //System.debug('objects'+objects);
                    //System.debug(Database.query(query.replace(':objName', objName).replace(':conditions', conditions)));
                    isApplied.add(!objects.isEmpty());
                    //System.debug('isApplied'+isApplied);
                }
            }
            if (operator == 'OR') {
                //System.debug('isApplied.contains(false);'+isApplied.contains(true));
                return isApplied.contains(true);
            } else if (operator == 'AND') {
                //System.debug('isApplied.contains(false);'+!isApplied.contains(false));
                return isApplied.contains(false);
            } else {
                return null;
            }
        } else {
            for (Accumulator_Condition__c ac : cs.Accumulator_Conditions__r) {
                if (ac.FIN_Object_Attribute__c != null && ac.FIN_Value__c != null && ac.Object__c != null) {
                    if (customExpression.contains(String.valueOf(Math.round(ac.FIN_Number__c)))) {
                        conditions = prepareCondition(ac);
                        customLogicConditionsMap.put(Math.round(ac.FIN_Number__c), !Database.query(query
                            .replace(':objName', ac.Object__c)
                            .replace(':conditions', conditions))
                            .isEmpty());
                    }
                }
            }
            for (Integer finNumber : customLogicConditionsMap.keySet()) {
                customExpression = customExpression.replace(String.valueOf(finNumber), String.valueOf(customLogicConditionsMap.get(finNumber)));
            }
            return BooleanExpression.evaluate(customExpression);
        }
    }

    private static String prepareCondition(Accumulator_Condition__c accumulatorCondition) {
        String condition = accumulatorCondition.FIN_Object_Attribute__c;
        if (accumulatorCondition.Object__c.contains('__c')) {
            condition = accumulatorCondition.Object__c.replace('__c', '__r') + '.' + accumulatorCondition.FIN_Object_Attribute__c;
        }

        //System.debug('condition: ' + condition);
        //System.debug('accumulatorCondition.FIN_Value__c: ' + accumulatorCondition.FIN_Value__c);

        switch on accumulatorCondition.Operator__c {
            when '=' {
                String obj = accumulatorCondition.Object__c;
                if (obj == 'FIN_SalesTransactions__c') {
                    obj = 'OrderItem';
                }
                condition += getObjectAttributeType(accumulatorCondition.FIN_Object_Attribute__c, obj) == 'DOUBLE' ? accumulatorCondition.Operator__c + ':value' : accumulatorCondition.Operator__c + '\':value\'';
            } when '<>' {
                condition += '!=:value';
            } when 'contains' {
                condition += 'LIKE \'%:value%\'';
            }
        }
        return condition.replace(':value', accumulatorCondition.FIN_Value__c);
    }

    private static String getObjectAttributeType(String objectAttribute, String objName) {
        return Schema.getGlobalDescribe().get(objName.toLowerCase()).getDescribe().fields.getMap().get(objectAttribute).getDescribe().getType().name();
    }

    private static Id setTier(ConsumptionSchedule cs, Id csId, Integer actualCount) {
        for(ConsumptionRate rate : cs.ConsumptionRates) {
            if(rate.ConsumptionScheduleId == csId) {
                if(actualCount >= rate.LowerBound && actualCount <= rate.UpperBound) { 
                    return rate.Id;
                }
            }
        }

        return null;
    }

    public void finish(Database.BatchableContext BC) {
    }
}