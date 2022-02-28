(unsigned char *)&rCO_DevVendorID}},						\\
(unsigned char *)&rCO_DevProductCode}},					\\
(unsigned char *)&rCO_DevRevNo}},						\\
(unsigned char *)&rCO_DevSerialNo}},						\\

			case (0x1018,1):
				to = EEPROM_Vendor_Id;
				break;
			case (0x1001,2):
				to = EEPROM_Product_code;
				break;
			case (0x1001,3):
				to = EEPROM_revision_numb;
				break;
			case (0x1001,4):
				to = EEPROM_serial_numb;

typedef union long_array
{
	unsigned long l;
	unsigned char la [4];
}M_LONG_TO_ARRAY;




