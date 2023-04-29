public class SOQLQueryBuilder {
    protected List<String> groupByFields;
    protected List<String> conditions;
    protected List<String> havingConditions;
    protected String sObjectType;
    protected List<String> orderBy;
    protected Integer limitForQuery;
    protected Integer offset;
    protected SelectQueryBuilder selectBuilder = null;
    private  WhereClauseBuilder whereBuilder;

    public SOQLQueryBuilder() {
        groupByFields = new List<String>();
        conditions = new List<String>();
        orderBy = new List<String>();
        havingConditions = new List<String>();
    }

    public static SOQLQueryBuilder create() {
        return new SOQLQueryBuilder();
    }

    public SelectQueryBuilder selectClause() {
        if (this.selectBuilder == null) {
            this.selectBuilder = new SelectQueryBuilder(this);
        }
        return this.selectBuilder;
    }

    public SelectQueryBuilder selectClauseByBuilder(SelectQueryBuilder queryBuilder) {
        this.selectBuilder = queryBuilder;
        return this.selectBuilder;
    }
    public SOQLQueryBuilder fromClause(String sObjectType) {
        this.sObjectType = sObjectType;
        return this;
    }

    public WhereClauseBuilder whereClause() {
        if (whereBuilder == null) {
            this.whereBuilder = WhereClauseBuilder.create(this);
        }
        return whereBuilder;
    }

    public Map<String, Object> getBindVariables() {
        if (whereBuilder.isEmpty()) {
            return new Map<String, Object>();
        }
        return whereBuilder.getBindVariables();
    }

    public WhereClauseBuilder whereConditionsByBuilder(WhereClauseBuilder queryBuilder) {
        this.whereBuilder = queryBuilder;
        return this.whereBuilder;
    }

    public SOQLQueryBuilder groupBy(List<String> fields) {
        groupByFields.addAll(fields);
        return this;
    }

    public SOQLQueryBuilder groupBy(String field) {
        groupByFields.add(field);
        return this;
    }

    //ToDO finish implementation
    public SOQLQueryBuilder havingCondition(String condition) {
        havingConditions.add(condition);
        return this;
    }

    public SOQLQueryBuilder orderBy(String field) {
        return orderBy(field, Constants.Direction.ASC_DIRECTION);
    }


    public SOQLQueryBuilder orderBy(String field, Constants.Direction direction) {
        orderBy.add(field + ' ' + direction.name().substringBefore('_'));
        return this;
    }

    public SOQLQueryBuilder limitForQuery(Integer limitForQuery) {
        this.limitForQuery = limitForQuery;
        return this;
    }

    public SOQLQueryBuilder offset(Integer offset) {
        this.offset = offset;
        return this;
    }

    public String build() {
        String query = getSelectClause() + ' ' + getFromClause() + ' ' + getWhereClause() + ' ' + getGroupByClause() + ' ' + getHavingClause() + ' ' + getOrderByClause() + ' ' + getLimitClause() + ' ' + getOffsetClause();
        return query.trim().replaceAll(' +', ' ');
    }

    public String buildForSosl() {
        String query = getSelectClause() + ' ' + getWhereClause();
        return query.trim().replaceAll(' +', ' ');
    }


    private String getSelectClause() {
        if (selectBuilder == null || selectBuilder.isEmpty()) {
            return 'SELECT Id';
        }
        return selectBuilder.build();
    }

    private String getFromClause() {
        if (String.isBlank(sObjectType)) {
            throw new QueryBuilderException('No object type specified');
        }
        return 'FROM ' + sObjectType;
    }

    private String getWhereClause() {
        if (whereBuilder == null || (whereBuilder != null && whereBuilder.isEmpty())) {
            return '';
        }
        return whereBuilder.build();
    }

    private String getGroupByClause() {
        if (groupByFields.isEmpty()) {
            return '';
        }
        return 'GROUP BY ' + String.join(groupByFields, ', ');
    }

    private String getHavingClause() {
        if (havingConditions.isEmpty()) {
            return '';
        }
        return 'HAVING ' + String.join(havingConditions, ', ');
    }

    private String getOrderByClause() {
        if (orderBy.isEmpty()) {
            return '';
        }
        return 'ORDER BY ' + String.join(orderBy, ', ');
    }

    private String getLimitClause() {
        if (limitForQuery == null) {
            return '';
        }
        return 'LIMIT ' + limitForQuery;
    }

    private String getOffsetClause() {
        if (offset == null) {
            return '';
        }
        return 'OFFSET ' + offset;
    }

    public class QueryBuilderException extends Exception {
    }
}