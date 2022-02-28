/* Version for Hydraulic valve */

#define	TRUE	1
#define FALSE	0
#define	_ON		1
#define _OFF	0

/* Baud Rate  -> Fosc=25Mhz,Tbit = 1+8+8+8=25tq
*
* We set PropSeg to 8, PhaseSeg1 to 8 and PhaseSeg2 to 8 which gives the bit
* time 1+8+8+8=25 tq and the sampling point (1+8+8)/(1+8+8+8) = 68%.
* With prescaler 0, we get 500 kbps.
* Also, we use SJW = 2 tq, SAM=1
*
* 500 kbps: 01 000000    1 0 111 111    0 0 000 111    40 bf 07
* 250 kbps: 01 000001    1 0 111 111    0 0 000 111    41 bf 07
* 125 kbps: 01 000011    1 0 111 111    0 0 000 111    43 bf 07
*/

/*Baud rate triplets for 25 MHz chrystal */
#define CAN_BAUD_1000K   -
#define CAN_BAUD_500K    0x40	// (0xbf, 0x07)
#define CAN_BAUD_250K    0x41	// (0xbf, 0x07)
#define CAN_BAUD_125K    0x43	// (0xbf, 0x07)
#define CAN_BAUD_100K    0x44	// (0xbf, 0x07)
#define CAN_BAUD_50K     0x49	// (0xbf, 0x07)
#define CAN_BAUD_20K     0x58	// (0xbf, 0x07)

#define INTER_SDO_TIMER	 1000	//1000 miliseconds before timeout of the next SDO

//#define MAX_CAN_OUT  4
//#define MAX_CAN_IN   4

#define	CAN_STATE_BOOTUP			0	//STATES FOR HEARTBEAT
#define	CAN_STATE_STOPPED			4
#define	CAN_STATE_OPERATIONAL		5
#define	CAN_STATE_PREOPERATIONAL	127
#define	CAN_STATE_INITIALISING		131

#define	CAN_REQUEST_START			1
#define	CAN_REQUEST_STOP			2
#define	CAN_REQUEST_ENTER_PREOP		128
#define	CAN_REQUEST_RESET			129
#define	CAN_REQUEST_RESET_COMMS		130

#define CCS_SDO_SEGMNT_DOWNLOAD		0			//client SDO messages
#define CCS_SDO_INIT_DOWNLOAD		1
#define CCS_SDO_INIT_UPLOAD_RESP	2
#define CCS_SDO_UPLOAD_SEGMNT		3
//
#define CS_SDO_ABORT				4
//
#define SCS_SDO_UPLOAD_SEG_RESP		0
#define SCS_SDO_DOWNLOAD_RESP		1			//server responses
#define SCS_SDO_INIT_UPLOAD			2
#define SCS_SDO_INIT_DOWNLOAD_RESP	3

#define BOOTUP_MSG			0x4F8
#define	BOOT_REPLY			0x3F8

typedef union abort_code
{
	struct
	{
		unsigned char b3;
		unsigned char b2;
		unsigned char b1;
		unsigned char b0;
	};
	struct
	{
		unsigned int high;		
		unsigned int low;		
	};
}M_ABORT;


typedef union TIMER_1_CONVERT
{
	unsigned int T1_int;		
	struct
	{
		unsigned char T1low_byte;
		unsigned char T1high_byte;
	};
}M_TIMER_1_CONVERT;

typedef union HEARTBEAT
{
	unsigned int count;		
	struct
	{
		unsigned char low_byte;
		unsigned char high_byte;
	};
}M_HEARTBEAT;

typedef union LONGID
{
	unsigned int Idword;
	struct
	{
		unsigned char Id_low;
		unsigned char Id_high;
	};
}M_LONGID;

typedef union long_array
{
	struct
	{
	unsigned char b0;
	unsigned char b1;
	unsigned char b2;
	unsigned char b3;
	};
//	unsigned char la[4];

	unsigned long l;
}M_LONG_TO_ARRAY;

enum CAN_PROCESS
{
	CAN_NOTHING = 0,		//no data transfer going on
	CAN_DONWLOADING,		//downloading
	CAN_UPLOADING			//uploading
};

// CAN buffers
enum CAN_OPEN_TX
{ 
  CAN_OPEN_IdTx = 0,  	// Transmit PDO
  CAN_OPEN_IdSdoTx,		// Transmit SDO
  CAN_OPEN_IdErr,		// Life guard - Heartbeat
  CAN_OPEN_IdEMCY,		// Emergency
  CAN_OPEN_TX_END,
  MAX_CAN_OUT};

enum CAN_OPEN_RX
{
  CAN_OPEN_PDO1 = 0,	// LEDs PDO
  CAN_OPEN_PDO2,		// LED blink PDO
  CAN_OPEN_IdSdoRx,		// SDO Receive
  CAN_OPEN_IdNet,		// NMT
  CAN_OPEN_IdErrIn,		// Life guard
  CAN_OPEN_RX_END,
  MAX_CAN_IN};

enum DEV_NET_TX
{ 
  DEV_NET_IdSvExp = 0,
  DEV_NET_IdSvCic,
  DEV_NET_IdSvAck,
  DEV_NET_TX_END  
};

enum DEV_NET_RX
{ 
  DEV_NET_IdSvUER = 0,
  DEV_NET_IdSvMSR,
  DEV_NET_IdMsPCC,
  DEV_NET_IdMsAck,
  DEV_NET_RX_END  
};

typedef union ERROR_REGISTER	//see table 47, page 65
{
	struct
	{
	unsigned GENERIC:1;
	unsigned CURRENT:1;
	unsigned VOLTAGE:1;
	unsigned TEMPERATURE:1;
	unsigned COMMUNICATIONS:1;
	unsigned PROFILE:1;
	unsigned RESERVED:1;
	unsigned MANUFACTURER:1;
	};
	unsigned char ebyte;
}M_ERROR_REGISTER;

typedef struct Error_Code
{
	unsigned char err_high;
	unsigned char err_low;
}M_ERROR_CODE;


typedef union  STAT_TX_B 
{
  struct
    {
     unsigned :5;
     unsigned R_R:1;  // Ricevuta una richiesta da remoto
     unsigned IN:1;   // Ricevuto nuovo messaggio
     unsigned OUT:1;  // In trasmissione
    };
    
  struct
    {
     char STATO_TX_B;  
    };
}M_STAT_TX_B;

typedef union SDO_Command	//headers of received SDO messages
{
	struct
	{						//INITIATE DOWNLOAD
		unsigned s:1;		//data set size
		unsigned e:1;		//transfer type (0=normal, 1=expedite)
		unsigned n:2;		//number of bytes of unused data
		unsigned x:1;		//unused
		unsigned ccs:3;		//client command specifier
	}INIT_DOWNLOAD;

	struct
	{						//INITIATE DOWNLOAD RESPONSE
		unsigned x:5;		//data set size
		unsigned scs:3;		//client command specifier
	}INIT_DOWNLOAD_RESPONSE;

	struct
	{						//DOWNLOAD SDO SEGMENT	
		unsigned c:1;		//more segments to download? 0:more, 1:no more
		unsigned n:3;		//number of bytes of unused data
		unsigned t:1;		//toggle bit
		unsigned ccs:3;		//client command specifier		
	}DOWNLOAD_SEGMT;

	struct
	{						//INITIATE DOWNLOAD RESPONSE
		unsigned x:4;		//data set size
		unsigned t:1;
		unsigned scs:3;		//client command specifier
	}DOWNLOAD_RESPONSE;

	struct
	{						//INITIATE UPLOAD
		unsigned x:5;		//unused
		unsigned scs:3;		//client command specifier
	}INIT_UPLOAD;

	struct
	{						//INITIATE UPLOAD RESPONSE
		unsigned s:1;		//size indicator
		unsigned e:1;		//transfer type
		unsigned n:2;		//number of bytes of unused data
		unsigned x:1;		//unused
		unsigned ccs:3;		//client command specifier
	}INIT_UPLOAD_RESPONSE;

	struct
	{						//UPLOAD SEGMENT
		unsigned x:4;		//unused
		unsigned t:1;		//toggle bit
		unsigned ccs:3;		//client command specifier		
	}UPLOAD_SEGMT;

	struct
	{						//UPLOAD SEGMENT RESPONSE
		unsigned c:1;		//last upload reponse message
		unsigned n:3;		//number of bytes of unused data
		unsigned t:1;		//toggle bit
		unsigned scs:3;		//client command specifier		
	}UPLOAD_SEGMT_RESP;

	struct
	{						//ABORT SDO TRANSFER
		unsigned x:5;		//unused
		unsigned cs:3;		//command specifier
	}ABORT_SDO;

	struct
	{						//ANONYMOUS SDO, just for analysis
		unsigned x:5;		//unused
		unsigned cs:3;		//command specifier
	}ANONYMOUS;

	unsigned char b;

}M_SDO_Command_header;
    
typedef union TXB_BUFF 
{
  struct // Receive PDO
    {
     unsigned char TXBD7;
     unsigned char TXBD6;
     unsigned char TXBD5;
     unsigned char TXBD4;
     unsigned char TXBD3;
     unsigned char TXBD2;
     unsigned char TXBD1;
     unsigned char TXBD0;
     unsigned char TXBDLC;
     unsigned char TXBSIDL;
     unsigned char TXBSIDH;
	 M_STAT_TX_B ST_B;
    };

  struct  // Sdo initiate download, upload
    {
     unsigned char B3;
     unsigned char B2;
     unsigned char B1;
     unsigned char B0;
     unsigned char SUB_INDEX;
     unsigned int  INDEX;
 	 M_SDO_Command_header COMMAND;
     unsigned char TXBDLC;
     unsigned char TXBSIDL;
     unsigned char TXBSIDH;
	 M_STAT_TX_B ST_B;
    };

  struct  // Sdo segment download
    {
     unsigned char D6;
     unsigned char D5;
     unsigned char D4;
     unsigned char D3;
     unsigned char D2;
     unsigned char D1;
     unsigned char D0;
 	 M_SDO_Command_header COMMAND;
     unsigned char TXBDLC;
     unsigned char TXBSIDL;
     unsigned char TXBSIDH;
	 M_STAT_TX_B ST_B;

    };
}M_TXB_BUFF;

typedef enum M_SDO_REQ_STATUS		//gi
{
	E_SUCCESS = 0,
	E_TOGGLE,
	E_SDO_TIME,
	E_CS_CMD,
	E_MEMORY_OUT,
	E_UNSUPP_ACCESS,
	E_CANNOT_READ,
	E_CANNOT_WRITE,
	E_OBJ_NOT_FOUND,
	E_OBJ_CANNOT_MAP,
	E_OBJ_MAP_LEN,
	E_GEN_PARAM_COMP,
	E_GEN_INTERNAL_COMP,
	E_HARDWARE,
	E_LEN_SERVICE,
	E_LEN_SERVICE_HIGH,
	E_LEN_SERVICE_LOW,
	E_SUBINDEX_NOT_FOUND,
	E_PARAM_RANGE,
	E_PARAM_HIGH,
	E_PARAM_LOW,
	E_MAX_LT_MIN,
	E_GENERAL,
	E_TRANSFER,
	E_LOCAL_CONTROL,
	E_DEV_STATE,
	E_NO_DICTIONARY
}REQ_STAT;


