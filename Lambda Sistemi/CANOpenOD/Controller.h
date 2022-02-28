// Comments ..........


//Sebastiano, meti qui tutte le tue variabile anche quelle che devi usare nel 
//assembler fai atenzione solo alla "lunghezza" di queste (8 bit, 16, bit etc.). Non ti 
//preocupare del bank a utilizzare, senza un'istruzione di #pragma, il compilatore li mete 
//nel primo banco donde c'e' molto spazio. 
//Per essempio:
unsigned char variabile_8_bit_nonsegnata;  //valori: 0 - 255
char variabile_8_segnata;					//valori: -127 a 127
unsigned int variabile_16_bit_ns;
int	variabile_16_bit_segnata;
long variabile_32_bit; 
//ecc.

//Start declarations:
unsigned char T0_1ms;
