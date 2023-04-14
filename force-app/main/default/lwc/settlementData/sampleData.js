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
        label: 'Total Net Amount',
        cellAttributes: {
            alignment: 'left'
        },
    }
]