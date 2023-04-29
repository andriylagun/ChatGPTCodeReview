public class GeneralBatchUpdater implements Database.Batchable<SObject>, Database.Stateful {
    private final String query;
    private final Map<String, Object> fieldMapping;
    private final Map<String, Object> bindedVariables;

    public GeneralBatchUpdater(String query , Map<String, Object> fieldMapping) {
        this.query = query;
        this.fieldMapping = fieldMapping;
    }

    public GeneralBatchUpdater(String query, Map<String, Object> fieldMapping, Map<String, Object> bindedVariables) {
        this.query = query;
        this.fieldMapping = fieldMapping;
        this.bindedVariables = bindedVariables;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return this.bindedVariables.isEmpty() ? Database.getQueryLocator(query) :
                Database.getQueryLocatorWithBinds(query, bindedVariables, AccessLevel.USER_MODE);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        for (SObject record : scope) {
            for (String targetField : fieldMapping.keySet()) {
                Object sourceValue = fieldMapping.get(targetField);
                record.put(targetField, sourceValue);
            }
        }
        update scope;
    }

    public void finish(Database.BatchableContext BC) {
    }
}