;General maro definitions

M_CMP_JE	macro	value1,value2,jumpto	;value1 = value2?
		movf	value1,w
		xorwf	value2,w
		btfsc	STATUS,Z
		goto	jumpto
		endm
M_CMPL_JE	macro	value1,literal,jumpto	;value1 = k?
		movf	value1,w
		xorlw	literal
		btfsc	STATUS,Z
		goto	jumpto
		endm
M_CMPL_JNE	macro	value1,literal,jumpto	;value1 <> k?
		movf	value1,w
		xorlw	literal
		btfss	STATUS,Z
		goto	jumpto
		endm
M_CMP_JG	macro	value1,value2,jumpto	;value1 > value2?
		movf	value2,w
		subwf	value1,w	;v1-v2 > 0
		btfss	STATUS,C
		goto	$+4
		btfsc	STATUS,Z
		goto	$+2
		goto	jumpto
		endm

M_CMP_JGE	macro	value1,value2,jumpto	;value1 >= value2?
		movf	value2,w
		subwf	value1,w	;v1-v2 >= 0
		btfsc	STATUS,C
		goto	jumpto
		endm


M_CMP_JL	macro	value1,value2,jumpto	;value1 < value2?
		movf	value2,w
		subwf	value1,w	;v1-v2 < 0
		btfss	STATUS,C
		goto	jumpto
		endm

M_CMP_JLE	macro	value1,value2,jumpto	;value1 <= value2?
		movf	value1,w
		subwf	value2,w	;v2-v1 > 0
		btfsc	STATUS,C
		goto	$+2
		btfsc	STATUS,Z
		goto	jumpto
		endm


M_CMPL_JL	macro	value1,literal,jumpto	;value1 < literal?
		movf	value1,w
		sublw	literal ;k-v1 < 0
		btfss	STATUS,C
		goto	$+4
		btfsc	STATUS,Z
		goto	$+2
		goto	jumpto
		endm

M_CMPL_JG	macro	value1,literal,jumpto	;k-val1 < 0
		movf	value1,w
		sublw	literal	
		btfss	STATUS,C
		goto	jumpto	
		endm
		

