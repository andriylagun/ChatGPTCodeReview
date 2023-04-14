export const COLUMNS_DEFINITION_BASIC = [
    {
        type: 'text',
        fieldName: 'scNumber',
        label: 'Sub-Contract Number ',
    },
    {
        type: 'text',
        fieldName: 'scName',
        label: 'Sub-Contract Name',
    },
    {
        type: 'currency',
        fieldName: 'total',
        label: 'Total Net Amount',
        cellAttributes: {
            alignment: 'left'
        },
    }
]