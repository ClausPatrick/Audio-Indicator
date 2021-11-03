;
; Audio_indicator.asm
;
; Created: 13.05.2021 19:31:14
; Author : Boss
;

;**** Global I2C Constants ****

.equ	SCLP	= 2			; SCL Pin number (port D)
.equ	SDAP	= 0			; SDA Pin number (port D)

;.equ	SCLP	= 0			; SCL Pin number (port D)
;.equ	SDAP	= 2			; SDA Pin number (port D)


.equ	b_dir	= 0			; transfer direction bit in i2cadr

.equ	i2crd	= 1
.equ	i2cwr	= 0

;**** Global Register Variables ****

.def	led_symb	= r0
.def	test_adc	= r1
.def	adc_data	= r2
.def	zero		= r3
.def	amp_counter = r4




.def	i2cdelay	= r16			; Delay loop variable
.def	i2cdata		= r17			; I2C data transfer register
.def	i2cadr		= r18			; I2C address and direction register (PCA9685)
.def	i2cstat		= r19			; I2C bus status register
.def	temp		= r20			;
.def	adcmux_cntr	= r21
.def	grn			= r22
.def	red			= r23

;X, Y, Z pointers: r26,r27,r28,r29,r30,r31



.ORG		0x000
		rjmp		RESET
.ORG		0x00b
		rjmp		ADC_SUBROUTINE

;******************************************************************************************************************************************************

RESET:
		ldi		r16, RAMEND
		out		SP, R16
		rcall	i2c_init					; initialize I2C interface

		sbi		DDRB, 3
		sbi		DDRB, 5
		sbi		DDRB, 6
			
		cbi		PORTB, 3					; Blue LED - Right
		cbi		PORTB, 5					; Blue LED - Left
		cbi		PORTB, 6					; Red LED  - Left


		clr		temp
		ldi		adcmux_cntr, 0b00100000
		ldi		XH, high(0x06a)
		ldi		XL, low(0x06a)
		ldi		YH, high(0x060)
		ldi		YL, low(0x060)
		ldi		Zl, low(2*LED_symbols)
		ldi		Zh, high(2*LED_symbols)

		ldi		temp, 0xC0					;I2C address
		st		x+, temp
		ldi		temp, 0x12					;CMD subaddress
		st		x+, temp
		ldi		temp, 0x00					;PS0
		st		x+, temp
		ldi		temp, 0xff					;PWM0
		st		x+, temp
		ldi		temp, 0x00					;PS1
		st		x+, temp
		ldi		temp, 0xf0					;PWM1
		st		x+, temp

		;ldi		temp, 0b01010101			;L00 ~ L03
		ldi		temp, 0xff
		st		x+, temp
		;ldi		temp, 0b01010101			;L04 ~ L07
		ldi		temp, 0xff
		st		x+, temp
		;ldi		temp, 0b01010101			;L08 ~ L11
		ldi		temp, 0xff
		st		x+, temp
		;ldi		temp, 0b01010101			;L12 ~ L15
		ldi		temp, 0xff
		st		x+, temp
		rcall	write_PCA
		
		ldi		temp, 0x7f
		mov		zero, temp
		ldi		temp, 0
		mov		adc_data, temp

		ldi		temp, 0b11001000		; 0b11101000
		out		ADCSR, temp
;******************************************************************************************************************************************************
		
main:	sei
		cbi		PORTB, 3
		brtc	main							;Loop on MAIN unless T-flag is set, which happens if ADC conversion and routine are completed.
		rcall	au_value_scaling				
		rcall	LED_address_arrangement
		rcall	write_PCA
		ldi		temp, 0b11001000				;Start new ADC conversion.
		out		ADCSR, temp 
		ldi		temp, 0
		mov		amp_counter, temp
		rjmp	main

;******************************************************************************************************************************************************
; ADC conversion and interrupt are completed; ADC data is at adc_data and will be scaled to a value from 0 to 8 which is copied to amp_counter.
;******************************************************************************************************************************************************

au_value_scaling:
		
		clt
	cnt_not_null:		
		mov		temp, adc_data
		sub		temp, zero		
		breq	is_zero
		brmi	is_neg

	is_pos:		
	pos_looper:
		inc		amp_counter
		lsr		temp
		brne	pos_looper
		rjmp	end_m_loop
	is_zero:
		nop
		rjmp	end_m_loop
	is_neg: 
		neg		temp
	neg_looper:
		inc		amp_counter
		lsr		temp
		brne	neg_looper
		rjmp	end_m_loop

	end_m_loop:	
		ret

;******************************************************************************************************************************************************
; Converting data in amp_counter to LED symbols and placing them in SRAM to be written to PCA according to adcmux_cntr.
; 8 Audio Channels represented by 16 LEDs (2 for each Channel, red and green).
;******************************************************************************************************************************************************

LED_address_arrangement:
		ldi		Zl, low(2*LED_symbols)
		ldi		Zh, high(2*LED_symbols)
		add		r30, amp_counter
		lpm		led_symb, Z
		
		cpi		adcmux_cntr, 0x21
		breq	level_0
		cpi		adcmux_cntr, 0x22
		breq	level_1
		cpi		adcmux_cntr, 0x23
		breq	level_2
		cpi		adcmux_cntr, 0x24
		breq	level_3
		rjmp	last_4_callsplit						; Split last 4 off due to rel jump out of range
		
	level_0:
		rcall	fetch_1_4
		cbr		red, 0b00000011
		cbr		grn, 0b11000000

		sbrc	led_symb, 0
		sbr		red, 0b00000001
		sbrc	led_symb, 1
		sbr		red, 0b00000010
		sbrc	led_symb, 2
		sbr		grn, 0b01000000 
		sbrc	led_symb, 3
		sbr		grn, 0b10000000 
		rjmp	L_a_a_end_1_4

	level_1:
		rcall	fetch_1_4
		cbr		red, 0b00001100
		cbr		grn, 0b00110000

		sbrc	led_symb, 0
		sbr		red, 0b00000100
		sbrc	led_symb, 1
		sbr		red, 0b00001000
		sbrc	led_symb, 2
		sbr		grn, 0b00010000 
		sbrc	led_symb, 3
		sbr		grn, 0b00100000 
		rjmp	L_a_a_end_1_4

	level_2:
		rcall	fetch_1_4
		cbr		red, 0b00110000
		cbr		grn, 0b00001100

		sbrc	led_symb, 0
		sbr		red, 0b00010000
		sbrc	led_symb, 1
		sbr		red, 0b00100000
		sbrc	led_symb, 2
		sbr		grn, 0b00000100
		sbrc	led_symb, 3
		sbr		grn, 0b00001000
		rjmp	L_a_a_end_1_4

	level_3:
		rcall	fetch_1_4
		cbr		red, 0b11000000
		cbr		grn, 0b00000011

		sbrc	led_symb, 0
		sbr		red, 0b01000000
		sbrc	led_symb, 1
		sbr		red, 0b10000000
		sbrc	led_symb, 2
		sbr		grn, 0b00000001
		sbrc	led_symb, 3
		sbr		grn, 0b00000010
		rjmp	L_a_a_end_1_4

	last_4_callsplit:
		cpi		adcmux_cntr, 0x25
		breq	level_4
		cpi		adcmux_cntr, 0x26
		breq	level_5
		cpi		adcmux_cntr, 0x27
		breq	level_6
		cpi		adcmux_cntr, 0x20
		breq	level_7
		ret

	level_4:
		rcall	fetch_5_8
		cbr		red, 0b00000011
		cbr		grn, 0b11000000

		sbrc	led_symb, 0
		sbr		red, 0b00000001
		sbrc	led_symb, 1
		sbr		red, 0b00000010
		sbrc	led_symb, 2
		sbr		grn, 0b01000000
		sbrc	led_symb, 3
		sbr		grn, 0b10000000
		rjmp	L_a_a_end_5_8

	level_5:
		rcall	fetch_5_8
		cbr		red, 0b00001100
		cbr		grn, 0b00110000

		sbrc	led_symb, 0
		sbr		red, 0b00000100
		sbrc	led_symb, 1
		sbr		red, 0b00001000
		sbrc	led_symb, 2
		sbr		grn, 0b00010000
		sbrc	led_symb, 3
		sbr		grn, 0b00100000
		rjmp	L_a_a_end_5_8

	level_6:
		rcall	fetch_5_8
		cbr		red, 0b00110000
		cbr		grn, 0b00001100

		sbrc	led_symb, 0
		sbr		red, 0b00010000
		sbrc	led_symb, 1
		sbr		red, 0b00100000
		sbrc	led_symb, 2
		sbr		grn, 0b00000100
		sbrc	led_symb, 3
		sbr		grn, 0b00001000
		rjmp	L_a_a_end_5_8

	level_7:
		rcall	fetch_5_8
		cbr		red, 0b11000000
		cbr		grn, 0b00000011

		sbrc	led_symb, 0
		sbr		red, 0b01000000
		sbrc	led_symb, 1
		sbr		red, 0b10000000
		sbrc	led_symb, 2
		sbr		grn, 0b00000001
		sbrc	led_symb, 3
		sbr		grn, 0b00000010	
		rjmp	L_a_a_end_5_8

	L_a_a_end_1_4:
		ldi		r28, 0x70
		st		y, grn
		ldi		r28, 0x73
		st		y, red
		ret

	L_a_a_end_5_8:
		ldi		r28, 0x71
		st		y, grn
		ldi		r28, 0x72
		st		y, red
		ret

fetch_1_4:
		ldi		r28, 0x70
		ld		grn, y
		ldi		r28, 0x73
		ld		red, y
	ret

fetch_5_8:
		ldi		r28, 0x71
		ld		grn, y
		ldi		r28, 0x72
		ld		red, y
	ret

;******************************************************************************************************************************************************

write_PCA:
		;ret		;test %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ldi		r26, 0x6a					;I2C data @$6a thru $74, including Address, SubCmd, PS and PWM settings and LED values.
		ld		i2cadr, X+
		;mov		i2cadr, temp
		;ldi		i2cadr, $C0				; Set device address and write
		rcall	i2c_start					; Send start condition and address

	i2c_loop:
		;ldi		i2cdata, $12			; Write word address
		ld		i2cdata, X+
		rcall	i2c_do_transfer				; Execute transfer
		cpi		r26, 0x74
		brne	i2c_loop
		rcall	i2c_stop					; Send stop condition
		ret
		
;********
i2c_hp_delay:
		ldi		i2cdelay, 0xf0
i2c_hp_delay_loop:
		dec		i2cdelay
		brne	i2c_hp_delay_loop
		ret

i2c_qp_delay:
		ldi		i2cdelay, 0x78	
i2c_qp_delay_loop:
		dec		i2cdelay
		brne	i2c_qp_delay_loop
		ret

;*****

i2c_start:				
		mov		i2cdata, i2cadr		; copy address to transmitt register
		sbi		DDRB, SDAP			; force SDA low
		rcall	i2c_qp_delay		; quarter period delay

;*****

i2c_write:
		sec							; set carry flag
		rol		i2cdata				; shift in carry and out bit one
		rjmp	i2c_write_first
i2c_write_bit:
		lsl		i2cdata				; if transmit register empty
i2c_write_first:
		breq	i2c_get_ack			;	goto get acknowledge
		sbi		DDRB, SCLP			; force SCL low

		brcc	i2c_write_low		; if bit high
		nop							;	(equalize number of cycles)
		cbi		DDRB, SDAP			;	release SDA
		rjmp	i2c_write_high
i2c_write_low:						; else
		sbi		DDRB, SDAP			;	force SDA low
		rjmp	i2c_write_high		;	(equalize number of cycles)
i2c_write_high:
		rcall	i2c_hp_delay		; half period delay
		cbi		DDRB, SCLP			; release SCL
		rcall	i2c_hp_delay		; half period delay
		rjmp	i2c_write_bit

;*****

i2c_get_ack:
		sbi		DDRB,SCLP			; force SCL low
		cbi		DDRB,SDAP			; release SDA
		rcall	i2c_hp_delay		; half period delay
		cbi		DDRB,SCLP			; release SCL

i2c_get_ack_wait: 
		sbis	PINB, SCLP			; wait SCL high 
									;(In case wait states are inserted)
		rjmp	i2c_get_ack_wait
		clc							; clear carry flag
									; Carry flag - Cleared if a slave responds to a request.
		cbi		PORTB, 6
		cbi		PORTB, 5
		sbic	PINB, SDAP			; if SDA is high
		;sec							;	set carry flag - Skipped if ACK is received.
		sbi		PORTB, 6
		sbis	PINB, SDAP
		sbi		PORTB, 5

		rcall	i2c_hp_delay		; half period delay
		ret
;*****

i2c_do_transfer:
		sbrs	i2cadr, b_dir		; if dir = write
		rjmp	i2c_write			;	goto write data
;*****

i2c_stop:
		sbi		DDRB,SCLP			; force SCL low
		sbi		DDRB,SDAP			; force SDA low
		rcall	i2c_hp_delay		; half period delay
		cbi		DDRB,SCLP			; release SCL
		rcall	i2c_qp_delay		; quarter period delay
		cbi		DDRB,SDAP			; release SDA
		rcall	i2c_hp_delay		; half period delay
		cbi		PORTB, 5
		ret

;*****

i2c_init:
		clr		i2cstat				; clear I2C status register (used
									; as a temporary register)
		out		PORTB, i2cstat		; set I2C pins to open collector
		out		DDRB, i2cstat
		ret



;******************************************************************************************************************************************************
; ADC interrupt. Reading in Value from Current ADC CHANNEL to reg adc_data and changing the ADC CHANNEL in ADMUX by incrementing admux_cntr.
; When ADC is called upon, T-Flag is SET, and MAIN routine will process ADC data and proceed with the rest of program.
;******************************************************************************************************************************************************

ADC_SUBROUTINE:		
		sbi		PORTB, 3
		push	temp
		in      temp, SREG
		push	temp
		in		temp, ADCH
		;ldi		temp, 0x7f	;TEST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		mov		adc_data, temp
		inc		adcmux_cntr				; Initialised at 0b00100000. Last 3 bits are incremented to loop thru all ADC channels.
		cpi		adcmux_cntr, 0b00101000			
		brne	skip_count_reset
		ldi		adcmux_cntr, 0b00100000
	skip_count_reset:		
		out		ADMUX, adcmux_cntr
		pop		temp
		out		SREG, temp
		pop		temp
		set								;T flag indicating ADC value change.
		cbi		PORTB, 3
		reti

;******************************************************************************************************************************************************

.org    0x180 

LED_symbols:  

.db		0b00000101, 0b00000110
.db		0b00000110, 0b00000111
.db		0b00001000, 0b00001100
.db		0b00001100, 0b00000001


/*

.db		0b00000101, 0b00001001
.db		0b00001001, 0b00001101
.db		0b00000010, 0b00000011
.db		0b00000011, 0b00000100

*/

