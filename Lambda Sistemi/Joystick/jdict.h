/*****************************************************************************
 *
 * This software was derived from Microchip CANopen Stack (Dictionary Services)
 *
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Gino Isla			30/10/06	First version
 * 
 *****************************************************************************/

// This is the scalar equivelant of a portion of the DICT_OBJ
typedef struct _DICTIONARY_OBJECT_TEMPLATE
{
	unsigned int index;
	unsigned char subindex;
	unsigned char ctl;
	unsigned int len;
	rom unsigned char * pROM;
}DICT_OBJECT_TEMPLATE;


typedef struct _DICTIONARY_EXTENDED_OBJECT
{
	//enum _DICT_OBJECT_REQUEST		/* Command required for function */
	//{
	//	DICT_OBJ_INFO = 0,
	//	DICT_OBJ_READ,
	//	DICT_OBJ_WRITE
	//}cmd;

//	unsigned char * pReqBuf;		/* Pointer to the requestors buffer */

	unsigned int reqLen;			/* Number of bytes requested */
	unsigned int reqOffst;			/* Starting point for the request */

	unsigned int index;				/* CANOpen Index */
	unsigned char subindex;			/* CANOpen Sub-index */

	enum DICT_CTL					/* Memory access type */
	{
		ACCESS_BITS	= 0b00000111,
				
		NA			= 0b00000000,	/* Default, non-existant */
		CONST		= 0b00000101,	/* Default, read only from ROM */
		RW			= 0b00000011,	/* Default, read/write from RAM */
		RO			= 0b00000001,	/* Default, read only from RAM */
		WO			= 0b00000010,	/* Default, write only to RAM */
		RW_EE		= 0b00001011,	/* Default, read/write from EEDATA */
		RO_EE		= 0b00001001,	/* Default, read only from EEDATA */
		WO_EE		= 0b00001010,	/* Default, write only to EEDATA */
		FUNC		= 0b00010000,	/* Default, function specific */
		
		RD_BIT		= 0b00000001,	/* Read Access */
		RD			= 0b01111111,	
		N_RD		= 0b01111110,	
		
		WR_BIT		= 0b00000010,	/* Write Access */
		WR			= 0b01111111,	
		N_WR		= 0b01111101,
		
		ROM_BIT		= 0b00000100,	/* ROM based object */
		ROM			= 0b01111111,	
		N_ROM		= 0b01111011,
		
		EE_BIT		= 0b00001000,	/* EEDATA based object */
		EE			= 0b01111111,
		N_EE		= 0b01110111,
		
		FDEF_BIT	= 0b00010000,	/* Functionally defined access */
		FDEF		= 0b01111111,	
		N_FDEF		= 0b01101111,
		
		MAP_BIT		= 0b00100000,	/* PDO Mappability*/
		MAP			= 0b01111111,
		N_MAP		= 0b01011111,	
		
		FSUB_BIT	= 0b01000000,	/* Functionally defined sub-index */
		FSUB		= 0b01111111,
		N_FSUB		= 0b00111111	
	}ctl;
	
	unsigned int len;				/* Size of the object in bytes */
	
	union DICT_PTRS					/* Pointers to objects */
	{
		void (* pFunc)(void);
		unsigned char * pRAM;
		rom unsigned char * pROM;
		unsigned int pEEDATA;
	}p;
	
}DICT_OBJ;

enum _SDO_REQ_TYPE		/* gi: type of sdo access*/
{
	DICT_READ = 0,
	DICT_WRITE,
	DICT_INFO
};

typedef union UNSIGNED16_MUX
{
	struct
	{
		unsigned char b0;
		unsigned char b1;
	};
	unsigned int w;
};

typedef struct _MULTIPLEXOR
{
	unsigned int index;
	unsigned char sindex;
	unsigned length;
}M_MULTIPLEXOR;


typedef struct _DICTIONARY_DATA
{
	DICT_OBJ * obj;					/* Pointer to the local object */
	enum _DICT_OBJECT_REQUEST		/* Command required for function */
	{
		DICT_OBJ_INFO = 0,
		DICT_OBJ_READ,
		DICT_OBJ_WRITE
	}cmd;
	unsigned char ret;				/* Return status */
}DICT_PARAM;


extern DICT_PARAM uDict;


