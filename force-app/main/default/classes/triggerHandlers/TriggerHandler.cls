public virtual class TriggerHandler {

    public List<SObject> triggerNew;
    public Map<Id, SObject> triggerNewMap;
    public Map<Id, SObject> triggerOldMap;
    public System.TriggerOperation operation;

    public TriggerHandler() {}

    public virtual void init(final System.TriggerOperation operation, final List<SObject> triggerNew, final Map<Id, SObject> triggerNewMap,
            final Map<Id, SObject> triggerOldMap){

        this.triggerNew = triggerNew;
        this.triggerNewMap = triggerNewMap;
        this.triggerOldMap = triggerOldMap;
        this.operation = operation;
    }

    public virtual void execute() {

        switch on this.operation {

            when BEFORE_INSERT {
                beforeInsert();
            }

            when AFTER_INSERT {
                afterInsert();
            }

            when BEFORE_UPDATE {
                beforeUpdate();
            }

            when AFTER_UPDATE {
                afterUpdate();
            }

            when AFTER_DELETE {
                afterDelete();
            }
        }
    }

    protected virtual void beforeInsert() {}
    protected virtual void afterInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
}