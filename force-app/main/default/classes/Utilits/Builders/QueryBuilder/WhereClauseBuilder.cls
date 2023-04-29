public class WhereClauseBuilder {
    private static List<String> conditions;
    private final Map<String, Object> bindVariables;
    private Boolean negative;
    private final SOSLQueryBuilder.SOSLReturningBuilder parentReturningBuilder;
    private final SOQLQueryBuilder parentSOQLQueryBuilder;


    private final static String EQUALS_OPERATOR = '=';
    private final static String GREATER_THEN = '>=';
    private final static String LIKE_OPERATOR = 'LIKE';
    private final static String IN_OPERATOR = 'IN';
    private final static String NEGATIVE_OPERATOR = 'NOT ';
    private final Map<String, String> NEGATIVE_OPERATORS = new Map<String, String>{
            EQUALS_OPERATOR => '!=',
            LIKE_OPERATOR => NEGATIVE_OPERATOR + LIKE_OPERATOR,
            LIKE_OPERATOR => NEGATIVE_OPERATOR + IN_OPERATOR,
            GREATER_THEN => '<='
    };
    private Boolean useBindVariables;

    public WhereClauseBuilder() {
        useBindVariables = false;
        conditions = new List<String>();
        bindVariables = new Map<String, Object>();
        negative = false;
    }

    public WhereClauseBuilder(SOSLQueryBuilder.SOSLReturningBuilder parentReturningBuilder) {
        this();
        this.parentReturningBuilder = parentReturningBuilder;
    }

    public WhereClauseBuilder(SOQLQueryBuilder parentSoqlQueryBuilder) {
        this();
        this.parentSOQLQueryBuilder = parentSoqlQueryBuilder;
    }
    public SOSLQueryBuilder.SOSLReturningBuilder endWhere() {
        return this.parentReturningBuilder;
    }

    public SOQLQueryBuilder endWhereSOQL() {
        return this.parentSOQLQueryBuilder;
    }

    public static WhereClauseBuilder create(SOQLQueryBuilder parentBuilder) {
        return new WhereClauseBuilder(parentBuilder);
    }

    public static WhereClauseBuilder create(SOSLQueryBuilder.SOSLReturningBuilder parentReturningBuilder) {
        return new WhereClauseBuilder(parentReturningBuilder);
    }

    public WhereClauseBuilder negative(String field, Object paramValue, Constants.ConditionType conditionType,
            Constants.LikeConditionType likeConditionType, Constants.ConditionOperatorType conditionOperatorType) {
        negative = true;
        condition(field, paramValue, conditionType, likeConditionType, conditionOperatorType);
        negative = false;
        return this;
    }

    public WhereClauseBuilder beginGroup(Constants.ConditionOperatorType operatorType) {
        if (!conditions.isEmpty()) {
            conditions.add(operatorType.name().substringBefore('_'));
        }
        conditions.add('(');
        return this;
    }

    public WhereClauseBuilder endGroup() {
        conditions.add(')');
        return this;
    }


    public WhereClauseBuilder conditionFromString(String condition) {
        conditions.add(condition);
        return this;
    }


    public WhereClauseBuilder removeCondition(String condition) {
        conditions.remove(conditions.indexOf(condition));
        return this;
    }


    public WhereClauseBuilder condition(String field, Object paramValue, Constants.ConditionType conditionType,
            Constants.LikeConditionType likeConditionType, Constants.ConditionOperatorType conditionOperatorType) {
        if (paramValue != null && String.isNotBlank(String.valueOf(paramValue)) && field != null && conditionType != null) {
            String paramName = field + '_param';
            switch on conditionType {
                when EQUALS_CONDITION {
                    addCondition(field, EQUALS_OPERATOR, paramName, paramValue, conditionOperatorType);
                }
                when LIKE_CONDITION {
                    if (paramValue instanceof String) {
                        addLikeCondition(field, paramName, String.valueOf(paramValue), likeConditionType, conditionOperatorType);
                    } else {
                        throw new SOQLQueryBuilder.QueryBuilderException('Use string value for like condition');
                    }
                }
                when IN_CONDITION {
                    addCondition(field, IN_OPERATOR, paramName, paramValue, conditionOperatorType);
                }
                when else {
                    throw new SOQLQueryBuilder.QueryBuilderException('Invalid condition type specified');
                }
            }
            bindVariables.put(paramName, paramValue);
        }
        return this;
    }

    public WhereClauseBuilder andCondition(WhereClauseBuilder whereClauseBuilder) {
        conditions.add('AND (' + whereClauseBuilder.build().remove(' WHERE ') + ')');
        bindVariables.putAll(this.getBindVariables());
        return this;
    }

    public WhereClauseBuilder orCondition(WhereClauseBuilder whereClauseBuilder) {
        conditions.add('OR (' + whereClauseBuilder.build() + ')');
        bindVariables.putAll(whereClauseBuilder.getBindVariables());
        return this;
    }

    private void addLikeCondition(String field, String paramName, String paramValue, Constants.LikeConditionType likeConditionType, Constants.ConditionOperatorType conditionOperatorType) {
        buildCondition(field, paramName, prepareLikeCondition(paramValue, likeConditionType), LIKE_OPERATOR, conditionOperatorType);
    }


    private void buildCondition(String field, String paramName, Object paramValue, String operator, Constants.ConditionOperatorType conditionOperator) {
        if (useBindVariables) {
            conditions.add((conditionOperator != null ? ' ' + conditionOperator.name().substringBefore('_') + ' ' : '') + field
                    + ' ' + (negative ? NEGATIVE_OPERATORS.get(operator) : operator)
                    + ' :' + paramName);
        } else {
            String formattedValue = formatValue(paramValue);
            if (String.isNotBlank(formattedValue)) {
                conditions.add((conditionOperator != null ? ' ' + conditionOperator.name().substringBefore('_') + ' ' : '') + field
                        + ' ' + (negative ? NEGATIVE_OPERATORS.get(operator) : operator)
                        + formattedValue);
            }
        }
    }

    private String formatValue(Object paramValue) {
        if (paramValue instanceof String) {
            return '\'' + String.escapeSingleQuotes((String) paramValue) + '\'';
        } else {
            try {
                List<String> objectList = new List<String>();
                objectList = (List<String>) JSON.deserializeStrict(JSON.serialize((Iterable<String>) paramValue), List<String>.class);
                List<String> formattedValues = new List<String>();
                for (Object value : objectList) {
                    formattedValues.add(formatValue(value));
                }

                if (formattedValues.isEmpty()) {
                    return '';
                } else {
                    return '(' + String.join(formattedValues, ', ') + ')';
                }
            } catch (Exception e) {
                return String.valueOf(paramValue);
            }
        }
    }


    private String prepareLikeCondition(String paramValue, Constants.LikeConditionType likeConditionType) {
        String operator = null;
        switch on likeConditionType {
            when STARTS_WITH {
                operator = String.escapeSingleQuotes(paramValue.trim()) + '%';
            }
            when ENDS_WITH {
                operator = '%' + String.escapeSingleQuotes(paramValue.trim());
            }
            when CONTAINS {
                operator = '%' + String.escapeSingleQuotes(paramValue.trim()) + '%';
            }
            when else {
                throw new SOQLQueryBuilder.QueryBuilderException('Invalid LikeConditionType');
            }
        }
        return operator;
    }

    private void addCondition(String field, String operator, String paramName, Object paramValue, Constants.ConditionOperatorType conditionOperatorType) {
        buildCondition(field, paramName, paramValue, operator, conditionOperatorType);
    }

    public WhereClauseBuilder useBindVariablesInQuery(Boolean use) {
        useBindVariables = use;
        return this;
    }

    public Map<String, Object> getBindVariables() {
        return bindVariables;
    }


    public String build() {
        String whereClause = 'WHERE ';
        for (String condition : conditions) {
            whereClause += condition + ' ';
        }
        return whereClause.trim();
    }

    public Boolean isEmpty() {
        return conditions != null && conditions.isEmpty();
    }

    //ToDo to implement later
//    private class ConditionBuilder {
//        private String field;
//        private String operator;
//        private Object value;
//        private String paramName;
//        private Boolean negative;
//        private Map<String, String> NEGATIVE_OPERATORS = new Map<String, String>{
//                '=' => '!=',
//                'LIKE' => 'NOT LIKE',
//                'IN' => 'NOT IN'
//        };
//
//        public ConditionBuilder(String field) {
//            this.field = field;
//            this.negative = false;
//        }
//
//        public ConditionBuilder operator(String operator) {
//            this.operator = operator;
//            return this;
//        }
//
//        public ConditionBuilder value(Object value) {
//            this.value = value;
//            return this;
//        }
//
//        public ConditionBuilder paramName(String paramName) {
//            this.paramName = paramName;
//            return this;
//        }
//
//        public ConditionBuilder negative(Boolean negative) {
//            this.negative = negative;
//            return this;
//        }
//
//        public String build(Boolean useBindVariables) {
//            String conditionOperator = negative ? NEGATIVE_OPERATORS.get(operator) : operator;
//            String conditionValue = useBindVariables ? ':' + paramName : String.valueOf(value);
//            return field + ' ' + conditionOperator + ' ' + conditionValue;
//        }
//    }


}