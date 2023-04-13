// export const COLUMNS_PDS_BASIC = [
//     {
//         type: 'text',
//         fieldName: 'event',
//         label: 'Event Name',
//     },
//     {
//         type: 'text',
//         fieldName: 'zone',
//         label: 'Zone',
//     },
//     {
//         type: 'text',
//         fieldName: 'salesTicketQuantity',
//         label: 'Sales Ticket Quantity',
//     },
//     {
//         type: 'currency',
//         fieldName: 'paymentDistributionsAmount',
//         label: 'Payment Distributions Net Amount',
//     },
//     {
//         type: 'text',
//         fieldName: 'pdNumber',
//         label: 'Payment Distributions Number',
//     }
// ]
//
//
// export const COLUMNS_PAYMENTS_BASIC = [
//     {
//         type: 'text',
//         fieldName: 'event',
//         label: 'Event Name',
//     },
//     {
//         type: 'text',
//         fieldName: 'zone',
//         label: 'Zone',
//     },
//     {
//         type: 'text',
//         fieldName: 'paymentType',
//         label: 'Payment Type',
//     },
//     {
//         type: 'currency',
//         fieldName: 'paymentAmount',
//         label: 'Payment Amount',
//     },
//     {
//         type: 'text',
//         fieldName: 'paymentNumber',
//         label: 'Payment Number',
//     }
// ]
//
// export const COLUMNS_SALESTR_BASIC = [
//     {
//         type: 'text',
//         fieldName: 'event',
//         label: 'Event Name',
//     },
//     {
//         type: 'text',
//         fieldName: 'zone',
//         label: 'Zone',
//     },
//     {
//         type: 'text',
//         fieldName: 'library',
//         label: 'Library Association Product',
//     },
//     {
//         type: 'text',
//         fieldName: 'qty',
//         label: 'Quantity',
//     },
//     {
//         type: 'currency',
//         fieldName: 'grossAmount',
//         label: 'Total Gross Amount',
//     },
//     {
//         type: 'text',
//         fieldName: 'saleNumber',
//         label: 'Sale Number',
//     }
//
// ]

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

export const COLUMNS_SALESTR_BASIC = [
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
    },
    {
        type: 'number',
        fieldName: 'qty',
        label: 'Total Quantity',
        cellAttributes: {
            alignment: 'left'
        },
    }
]