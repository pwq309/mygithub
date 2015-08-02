//main FSM:
`define READY          3'b000
`define ARBITRATE      3'b100
`define REPLY          3'b001
`define OPENSTATE      3'b011
`define OPENKEY        3'b010
`define SECURED        3'b110
`define SECUREDKEY     3'b111
`define KILLED         3'b101

//commmand:
`define TID_WRITE              8'b1011_0000
`define TID_DONE               8'b1011_1111
`define SORT                   8'b1010_1010
`define QUERY                  8'b1010_0100
`define DIVIDE                 2'b11                 
`define QUERYREP               2'b00
`define DISPERSE               4'b1000
`define SHRINK                 8'b1001
`define ACK                    2'b01
`define NAK                    8'b1010_1111
`define ACCESS                 8'b1010_0011
`define READ                   8'b1010_0101
`define WRITE                  8'b1010_0110
`define ERASE                  8'b1010_0111
`define LOCK                   8'b1010_1000
`define KILL                   8'b1010_1001
`define GET_RN                 8'b1011_0010
`define REFRESHRN              8'b1011_0100

//special for type2
`define GET_SECPARA            8'b1010_1110
`define REQ_XAUTH              8'b1011_0000
`define RW_XAUTH               8'b1011_0001
`define REQ_SAUTH              8'b1010_0000
`define MUL_SAUTH              8'b1010_0001
`define SEC_COM                8'b1010_1101

//bsc:
`define NO_BACK              4'b0000
`define BACK_HANDLE          4'b0001
`define BACK_RN11_CRC5       4'b0010
`define BACK_UAC             4'b0011
//`define BACK_CHECK_RESULT1   4'b0110 //bsc of the first access, the value is success operation state
`define BACK_CHECK_RESULT    4'b0111 //bsc of second ACCESS, the value depend on the pwd match or not
`define BACK_READ            4'b0101
`define BACK_ACC_PWD_ERR     4'b0100
`define BACK_WRITE           4'b1000
`define NO_AUTHORITY         4'b1001
`define LOCK_EVENT           4'b1010
//`define LOCK_ERROR           4'b1011
`define BACK_ERASE           4'b1100
`define NO_AUTHORITY_P       4'b1101  //response data form is different from the state NO_AUTHORITY
`define KILL_EVENT           4'b1110
`define BACK_TID_WR          4'b0110
`define BACK_TID_DO          4'b1111
//`define KILL_ERROR           4'b1111


//parameter for interrogator non-syn!!
`define TREPLY     20000000
`define TDATA_BUF_LEN           7000
//`define FULL_FUNC            // enable it when use full function
`define DECODING_MSG           // enable it when you want to see the DECODING MSG
`define WRITE_DEC
`define SUPPRESS_SENDING_MSG   // if you do not want to sending message,enable it


//parameter for sort!!
`define MM_NN                   2'b00
`define MK_NN                   2'b01
`define MM_NK                   2'b10
`define MN_NN                   2'b11

`define Mask_Len                'd64

//parameter for query!!
`define Query_Len               'd32

`define TAG_ALL                 2'b00
`define TAG_MATCH               2'b01
`define TAG_NON_MATCH           2'b10

`define TARGET0                 1'b0
`define TARGET1                 1'b1

`define TREXT                   1'b1
`define NO_TREXT                1'b0                                
                               
`define DR_0d25                 2'b00
`define DR_0d5                  2'b01
`define DR_1                    2'b10
                               
`define M_FM0                   2'b00
`define M_MILLER2               2'b01
`define M_MILLER4               2'b10
`define M_MILLER8               2'b11

//parameter for Divide!!
`define Divide_Len               'd4

`define POSITION0                      2'b00
`define POSITION1                      2'b01

//parameter for QueryRep!!
`define QueryRep_Len             'd2

//parameter for Disperse!!
`define Disperse_Len             'd4

//parameter for Shrink!!
`define Shrink_Len               'd4


//parameter for Ack!!
`define Ack_Len                 'd18

//parameter for Nak!!
`define Nak_Len                 'd8    

//parameter Get_SecPara
`define Get_SecPara_Len         'd40

//parameter for Req_XAuth!!
`define Req_XAuth_Len           'd40

//parameter for RW_XAuth!!
`define RW_XAuth_Len            'd56

//parameter for Get_RN!!
`define Get_RN_Len              'd40

//parameter for TID_DONE
`define TID_done_Len            'd8

//parameter for TID_WRITE
`define TID_write_Len           'd58

//parameter for Sec_Com!!


//parameter for Req_SAuth!! 
`define Req_SAuth_Len           'd40

//parameter for Mul_SAuth!!
`define Mul_SAuth_Len           'd88

//parameter for RefreshRN!!
`define RefreshRN_Len           'd40

//parameter for Access!!
`define Access_Len              'd60

//parameter for 

////parameter for Req_RW!!
//`define Req_RW_Len              'd72
//
////parameter for REQ_LC!!
//`define Req_LC_Len              'd72
//
////parameter for Req_RE!!
//`define Req_RE_Len              'd40
//
////parameter for Req_KL!!
//`define Req_KL_Len              'd72

//parameter for Read!!
`define Read_Len                'd74
`define TBI                     2'b00
`define UAC                     2'b01
`define SEC                     2'b10
`define UDF                     2'b11

//parameter for Write!!
`define Write_Len               'd90

//parameter for Erase!!
`define Erase_Len               'd74

//parameter for Lock!!
`define Lock_Len                'd44
`define R_W                     2'b00
`define R_NW                    2'b01
`define NR_W                    2'b10
`define NR_NW                   2'b11                 

//parameter for Kill!!    
`define Kill_Len                'd40