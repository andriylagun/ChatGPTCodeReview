public class SOSLQueryBuilder {
    public enum SearchField {
        ALL_FIELDS, NAME_FIELDS, EMAIL_FIELDS
    }

    private String searchString;
    private Integer queryLimit;
    private SearchField searchField;
    private final List<String> orderBy;
    private Map<String, SOSLReturningBuilder> returningBuilders;

    public static SOSLQueryBuilder create() {
        return new SOSLQueryBuilder();
    }

    public SOSLQueryBuilder() {
        this.queryLimit = 0;
        orderBy = new List<String>();
        returningBuilders = new Map<String, SOSLReturningBuilder>();
    }

    public SOSLReturningBuilder returningBuilder(String sObjectType) {
        if (!returningBuilders.containsKey(sObjectType)) {
            returningBuilders.put(sObjectType, new SOSLReturningBuilder(sObjectType, this));
        }
        return returningBuilders.get(sObjectType);
    }

    public SOSLQueryBuilder inFields(SearchField searchField) {
        this.searchField = searchField;
        return this;
    }

    public SOSLQueryBuilder find(String searchString) {
        this.searchString = searchString;
        return this;
    }

    public SOSLQueryBuilder queryLimit(Integer queryLimit) {
        this.queryLimit = queryLimit;
        return this;
    }

    public SOSLQueryBuilder orderBy(String field) {
        return orderBy(field, Constants.Direction.ASC_DIRECTION);
    }


    public SOSLQueryBuilder orderBy(String field, Constants.Direction direction) {
        orderBy.add(field + ' ' + direction.name().substringBefore('_'));
        return this;
    }
    public String build() {
        String query = 'FIND {' + searchString + '} IN ' + searchFieldsToString(searchField) + ' RETURNING ';
        List<String> returningQueries = new List<String>();
        for (SOSLReturningBuilder builder : returningBuilders.values()) {
            returningQueries.add(builder.build());
        }
        query += String.join(returningQueries, ', ');
        query += this.queryLimit != 0 ? ' LIMIT ' + this.queryLimit : '';

        if (!orderBy.isEmpty()) {
            query += ' ORDER BY ' + String.join(orderBy, ', ');
        }
        return query;
    }

    private static String searchFieldsToString(SearchField searchFields) {
        switch on searchFields {
            when ALL_FIELDS {
                return 'ALL FIELDS';
            }
            when NAME_FIELDS {
                return 'NAME FIELDS';
            }
            when EMAIL_FIELDS {
                return 'EMAIL FIELDS';
            }
            when else {
                return 'ALL FIELDS';
            }
        }


    }
    public class SOSLReturningBuilder {
        private String sObjectType;
        private SOQLQueryBuilder soqlBuilder;
        private SOSLQueryBuilder soslBuilder;
        private WhereClauseBuilder whereBuilder;
        private SelectQueryBuilder selectBuilder;


        public SOSLReturningBuilder(String sObjectType) {
            this.sObjectType = sObjectType;
            soqlBuilder = new SOQLQueryBuilder();
        }

        public SOSLReturningBuilder(String sObjectType, SOSLQueryBuilder parentSOSLBuilder) {
            this(sObjectType);
            this.soslBuilder = parentSOSLBuilder;
        }

        public SelectQueryBuilder selectClause() {
            if (this.selectBuilder == null) {
                this.selectBuilder = new SelectQueryBuilder(this);
            }
            return this.selectBuilder;
        }


        public SOSLQueryBuilder endReturning() {
            return soslBuilder;
        }

        public SOSLReturningBuilder field(String field) {
            this.selectBuilder.field(field);
            return this;
        }

        public WhereClauseBuilder whereClause() {
            if (whereBuilder == null) {
                whereBuilder = WhereClauseBuilder.create(this);
                soqlBuilder.whereConditionsByBuilder(whereBuilder);
            }
            return whereBuilder;
        }

        public String build() {
            String query = this.sObjectType + '(' + this.selectBuilder.build().substringAfter('SELECT ') + ')';
            return query;
        }
    }
}