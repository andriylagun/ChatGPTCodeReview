// export const COLUMNS_PDS_BASIC = [
//     {
//         type: 'text',
//         fieldName: 'paymentNumber',
//         label: 'Payment Distributions Number',
//     },
//     {
//         type: 'text',
//         fieldName: 'context',
//         label: 'Context',
//     },
//     {
//         type: 'text',
//         fieldName: 'contract',
//         label: 'Contract',
//     },
//     {
//         type: 'text',
//         fieldName: 'paymentType',
//         label: 'Payment Type',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'text',
//         fieldName: 'libraryAssociations',
//         label: 'Library Associations'
//     },
//     {
//         type: 'text',
//         fieldName: 'finChartOfAcc',
//         label: 'Financial Chart of Account',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'currency',
//         fieldName: 'journalEntryAmount',
//         label: 'Journal Entry Amount',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'text',
//         fieldName: 'journalEntrySign',
//         label: 'Journal Entry Sign'
//     },
// ]
//
// export const COLUMNS_PAYMENTS_BASIC = [
//     {
//         type: 'text',
//         fieldName: 'paymentNumber',
//         label: 'Payment Number',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'text',
//         fieldName: 'context',
//         label: 'Context',
//     },
//     {
//         type: 'text',
//         fieldName: 'contract',
//         label: 'Contract',
//     },
//     {
//         type: 'text',
//         fieldName: 'paymentType',
//         label: 'Payment Type',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'text',
//         fieldName: 'libraryAssociations',
//         label: 'Library Associations'
//     },
//     {
//         type: 'text',
//         fieldName: 'finChartOfAcc',
//         label: 'Financial Chart of Account',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'currency',
//         fieldName: 'journalEntryAmount',
//         label: 'Journal Entry Amount',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'text',
//         fieldName: 'journalEntrySign',
//         label: 'Journal Entry Sign'
//     },
// ]
// export const COLUMNS_DEFINITION_BASIC = [
//     {
//         type: 'text',
//         fieldName: 'event',
//         label: 'Event',
//     },
//     {
//         type: 'text',
//         fieldName: 'sales',
//         label: 'Sales',
//     },
//     {
//         type: 'text',
//         fieldName: 'zone',
//         label: 'Zone',
//     },
//     {
//         type: 'currency',
//         fieldName: 'distributionsAmount',
//         label: 'Distributions Amount',
//         cellAttributes: {
//             alignment: 'left'
//         },
//     },
//     {
//         type: 'text',
//         fieldName: 'paymentNumber',
//         label: 'Payment Distributions Number',
//     },
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
        label: 'Total Journal Entry Amount',
        cellAttributes: {
            alignment: 'left'
        },
    }
]