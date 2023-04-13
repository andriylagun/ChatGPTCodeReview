export const COLUMNS_DEFINITION_BASIC = [
    {
        type: 'text',
        fieldName: 'remPayoutNumber',
        label: 'Remittance Payout Number',
    },
    {
        type: 'text',
        fieldName: 'payeeLegalName',
        label: 'Payee Legal Name',
    },
    {
        type: 'text',
        fieldName: 'remittanceAccount',
        label: 'Remittance Account',
    },

    {
        type: 'currency',
        fieldName: 'remittanceAmount',
        label: 'Remittance Amount',  
        cellAttributes: {
            alignment: 'left'
        },  
    },
    {
        type: 'Date',
        fieldName: 'dueDate',
        label: 'Due Date',
    },
    {
        type: 'text',
        fieldName: 'status',
        label: 'Status',
    },
    {
        type: 'text',
        fieldName: 'contractNumber',
        label: 'Contract',
    },
    {
        type: 'Date',
        fieldName: 'remittanceDate',
        label: 'Remittance Date',
    },
    {
        type: 'text',
        fieldName: 'settlementStatus',
        label: 'Settlement Status',
    },
    {
        type: 'text',
        fieldName: 'settlementProcess',
        label: 'Settlement Process',
    },
    
]