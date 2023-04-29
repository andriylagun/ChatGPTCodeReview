public class SelectQueryBuilder {
    protected List<String> fields;
    protected List<String> polymorphicBuilder;
    private SOSLQueryBuilder.SOSLReturningBuilder parentBuilder;
    private SOQLQueryBuilder parentSOQLQueryBuilder;

    public SelectQueryBuilder() {
        this.fields = new List<String>();
    }

    public SelectQueryBuilder(SOSLQueryBuilder.SOSLReturningBuilder parentReturningBuilder) {
        this();
        this.parentBuilder = parentReturningBuilder;
    }

    public SelectQueryBuilder(SOQLQueryBuilder parentSoqlQueryBuilder) {
        this();
        this.parentSOQLQueryBuilder = parentSoqlQueryBuilder;
    }

    public SOSLQueryBuilder.SOSLReturningBuilder endSelectSOSL() {
        return this.parentBuilder;
    }

    public SOQLQueryBuilder endSelectSOQL() {
        return this.parentSOQLQueryBuilder;
    }

    public SelectQueryBuilder field(String field) {
        fields.add(field);
        return this;
    }

    public static SelectQueryBuilder create() {
        return new SelectQueryBuilder();
    }

    public SelectQueryBuilder fieldList(List<String> fieldList) {
        fields.addAll(fieldList);
        return this;
    }

    public SelectQueryBuilder fieldsCommaSeparated(String commaSeparatedFields) {
        List<String> fieldList = commaSeparatedFields.split(',\\s*');
        fields.addAll(fieldList);
        return this;
    }

    public SelectQueryBuilder addPolymorphicQuery(PolymorphicBuilder builder) {
        polymorphicBuilder.add('(' + builder.build() + ')');
        return this;
    }

    public SelectQueryBuilder addSubquery(SOQLQueryBuilder soqlQueryBuilder) {
        fields.add('(' + soqlQueryBuilder.build() + ')');
        return this;
    }

    public Boolean isEmpty() {
        return fields.isEmpty();
    }

    public String build() {
        String query = 'SELECT ';
        if (polymorphicBuilder != null) {
            query += String.join(polymorphicBuilder, ', ') + ', ';
        }
        query += String.join(fields, ', ');
        return query;
    }

    public class PolymorphicBuilder {
        private final String field;
        private final List<String> whenExpressions;
        private final List<String> elseExpressions;

        public PolymorphicBuilder(String field) {
            this.field = field;
            whenExpressions = new List<String>();
            elseExpressions = new List<String>();
        }

        public PolymorphicBuilder when(String sObjectType, String field) {
            whenExpressions.add('WHEN ' + sObjectType + ' THEN ' + field);
            return this;
        }

        public PolymorphicBuilder elseField(String field) {
            elseExpressions.add('ELSE ' + field);
            return this;
        }

        public String build() {
            String query = 'TYPEOF ' + field + ' ';
            query += String.join(whenExpressions, ' ');
            if (!elseExpressions.isEmpty()) {
                query += ' ' + String.join(elseExpressions, ' ');
            }
            query += ' END';
            return query;
        }
    }
}