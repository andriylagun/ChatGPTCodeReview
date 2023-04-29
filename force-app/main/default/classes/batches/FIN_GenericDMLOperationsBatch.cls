public with sharing class FIN_GenericDMLOperationsBatch implements Database.Batchable<SObject>, Database.Stateful {
    private final Constants.DmlOperation operation;
    private final List<SObject> records;
    private final Database.Batchable<SObject> batchForFinish;
    private List<SObject> scopeToExecute;
    private Integer chunkSize = 200;
    public FIN_GenericDMLOperationsBatch(Constants.DmlOperation operation, List<SObject> records) {
        this.operation = operation;
        this.records = records;
        this.scopeToExecute = new List<SObject>();
        this.batchForFinish = null;
    }

    public FIN_GenericDMLOperationsBatch(Constants.DmlOperation operation, List<SObject> records, Database.Batchable<SObject> batchForFinish) {
        this.operation = operation;
        this.records = records;
        this.batchForFinish = batchForFinish;
        this.scopeToExecute = new List<SObject>();
    }

    public FIN_GenericDMLOperationsBatch(Constants.DmlOperation operation, List<SObject> records, Integer chunkSize) {
        this.operation = operation;
        this.records = records;
        this.chunkSize = chunkSize;
        this.scopeToExecute = new List<SObject>();
        this.batchForFinish = null;
    }

    public FIN_GenericDMLOperationsBatch(Constants.DmlOperation operation, List<SObject> records,
            Database.Batchable<SObject> batchForFinish, Integer chunkSize) {
        this.operation = operation;
        this.records = records;
        this.scopeToExecute = new List<SObject>();
        this.batchForFinish = batchForFinish;
        this.chunkSize = chunkSize;
    }

    public Iterable<SObject> start(Database.BatchableContext context) {
        System.debug('records.size()'+records.size());
        if (records.isEmpty()) {
            for (Integer i = Math.min(records.size() -1, chunkSize); i >= 0 ; i--) {
                this.scopeToExecute.add(records[i]);
                this.records.remove(i);
            }
        }
        System.debug('operation'+operation);
        System.debug('scopeToExecute'+scopeToExecute);
        return scopeToExecute;
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        System.debug('scope'+scope);
        System.debug('operation'+operation);
        switch on operation {
            when INSERT_OP {
                Database.insert(scope, false);
            }
            when UPDATE_OP {
                Database.update(scope, false);
            }
            when DELETE_OP {
                Database.delete(scope, false);
            }
            when UPSERT_OP {
                Database.upsert(scope, false);
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('finish records.size() : '+records.size());
        System.debug('batchForFinish : '+batchForFinish);
        if (batchForFinish != null && records.size() == 0) {
            Database.executeBatch(batchForFinish);
        } else {
            Database.executeBatch(new FIN_GenericDMLOperationsBatch(operation, records, batchForFinish));
        }
    }
}