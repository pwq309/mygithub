//main FSM:
`define READY          4'b0000
`define ARBITRATE      4'b0001
`define REPLY          4'b0011
`define OPENSTATE      4'b0010
`define OPENKEY        4'b0110
`define SECURED        4'b0111
`define SECUREDKEY     4'b0101
`define KILLED         4'b0100
`define ACKNOWLEDGED   4'b1000

//commmand:
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

//special for type2
`define GET_SECPARA            8'b1010_1110
`define REQ_XAUTH              8'b1011_0000
`define RW_XAUTH               8'b1011_0001

`define REFRESHRN              8'b1011_0100

`define REQ_SAUTH              8'b1010_0000
`define MUL_SAUTH              8'b1010_0001

`define SEC_COM                8'b1010_1101

//bsc:
`define NO_BACK              4'b0000
`define BACK_HANDLE          4'b0001
`define BACK_RN11_CRC5       4'b0010
`define BACK_UAC             4'b0011
//`define BACK_SECPARA         5'b0_0100
//`define BACK_SNT             5'b0_0101 //bsc of REQ_XAUTH
//`define BACK_RESULT          5'b0_0110  //the result of authentic
`define BACK_CHECK_RESULT1   4'b0100 //bsc of the first access, the value is success operation state
`define BACK_CHECK_RESULT    4'b0101 //bsc of second ACCESS, the value depend on the pwd match or not
`define BACK_READ            4'b0110
`define BACK_ACC_PWD_ERR     4'b0111
//`define OPEN_READ            4'b0110
//`define SECURED_READ         4'b0111
`define BACK_WRITE           4'b1000
//`define OPEN_WRITE           4'b1000
//`define SECURED_WRITE        4'b1001
`define NO_AUTHORITY         4'b1001
`define NO_AUTHORITY_P       4'b1101
`define LOCK_EVENT           4'b1010
`define LOCK_ERROR           4'b1011
`define BACK_ERASE           4'b1100
//`define OPEN_ERASE           4'b1100
//`define SECURED_ERASE        4'b1101
`define KILL_EVENT           4'b1110
`define KILL_ERROR           4'b1111
//`define BACK_RNT             5'b1_0001
//`define BACK_RNR             5'b1_0011
//parameters for QUERY
//`define M_FM0 2'b00


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

`define Mask_Len                'd48

//parameter for query!!
`define Query_Len               'd36

`define TAG_ALL                 2'b00
`define TAG_MATCH               2'b01
`define TAG_NON_MATCH           2'b10

`define SESSION_S0              2'b00
`define SESSION_S1              2'b01
`define SESSION_S2              2'b10
`define SESSION_S3              2'b11

`define TARGET0                 1'b0
`define TARGET1                 1'b1

`define TREXT                   1'b1
`define NO_TREXT                1'b0                                
                               
`define DR_1d5                  4'b0000
`define DR_3d7                  4'b0001
`define DR_6d11                 4'b0010
`define DR_1                    4'b0011
`define DR_2d5                  4'b0100
`define DR_6d7                  4'b0101
`define DR_12d11                4'b0110
`define DR_2                    4'b0111
          
`define M_FM0                   2'b00
`define M_MILLER2               2'b01
`define M_MILLER4               2'b10
`define M_MILLER8               2'b11

//parameter for Divide!!
`define Divide_Len               'd6

`define POSITION0                      2'b00
`define POSITION1                      2'b01

//parameter for QueryRep!!
`define QueryRep_Len             'd4

//parameter for Disperse!!
`define Disperse_Len             'd6

//parameter for Shrink!!
`define Shrink_Len               'd6


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

//parameter for Sec_Com!!


//parameter for Req_SAuth!! 
`define Req_SAuth_Len           'd40

//parameter for Mul_SAuth!!
`define Mul_SAuth_Len           'd88

//parameter for RefreshRN!!
`define RefreshRN_Len           'd40

//parameter for Access!!
`define Access_Len              'd66

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
`define Read_Len                'd78
`define TBI                     6'b000000
`define UAC                     6'b010000
`define SEC                     6'b100000
`define UDF                     6'b110000

//parameter for Write!!
`define Write_Len               'd94

//parameter for Erase!!
`define Erase_Len               'd78

//parameter for Lock!!
`define Lock_Len                'd50
`define R_W                     2'b00
`define R_NW                    2'b01
`define NR_W                    2'b10
`define NR_NW                   2'b11                 

//parameter for Kill!!    
`define Kill_Len                'd40