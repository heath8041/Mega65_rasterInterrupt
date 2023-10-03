.cpu _45gs02

#import "../Mega65_System/System_Macros.s"
// Segment definitions
.file [name="%o.prg", segments="BasicUpstart,Code"]
.segmentdef BasicUpstart [start=$2001]
.segmentdef Code         [start=$2016]

.segment BasicUpstart
    .byte $09,$20 // End position
    .byte $72,$04 // Line number
    .byte $fe,$02,$30,$00 // BANK 0 command
    .byte <end, >end  // End of command marker (first byte after the 00 terminator)
    .byte $e2,$16 // Line number
    .byte $9e // SYS command
    .text toIntString(Entry)
    .byte $00
end:
    .byte $00,$00 //End of basic terminators


.segment Code
Entry: {


        jsr cls    //clear the screen

        lda #$01
        sta VIC.COLOR_RAM  //set some color ram

        sei       //enabled interrupts

        // Enable mega65 I/O personality (eg. for VIC IV registers)
        lda #$47
        sta $d02f
        lda #$53
        sta $d02f 

        // Reset MAP Banking
        lda #$00
        tax
        tay
        taz
        map
        eom

        // All RAM + I/O
        lda #$35
        sta $01

        // IRQ vector
        lda #<irq_handler
        sta $fffe
        lda #>irq_handler
        sta $ffff

        lda #$01
        sta $d01a      //vic ii raster IRQ location
        
        lda #$7f
        sta $dc0d       //disable cia timer iterrupt
        sta $dd0d       

        lda #$80        //not sure what this does?
        trb $d011

        lda #$7F        //store the value for the raster line interrupt
        sta $d012      

        cli             //clear interrupts

        jmp *

    irq_handler:

        //save cpu registers to stack
        pha
        txa 
        pha
        tya
        pha
        tza
        pha


        inc $d019       //inc the IRQ handler

        inx
        inx
        inx 
        inx 
        bne !+
        inc VIC.SCREEN  //make a char increment in corner

      !:
        lda $d012        //store the value of the current raster line
        cmp $d012        //compare  it to the new current value 
        beq *-3          //branch if equal to zero go back 3 bytes 
                          // keep looping

        lda #$05         //here we've moved on to next raster line
                          // use green color to paint a single line 
        sta $d020         //border and screen green.
        sta $d021

        lda $d012         //save the value of the current raster 
        cmp $d012         // compare it to the new current value
        beq *-3           // keep looping until it's changed

        lda #$00          //here we've moved on to the next raster line
        sta $d020         //go back to black border and background
        sta $d021
  


        //restor cpu registers from stack
        pla
        tza 
        pla
        tya
        pla
        txa
        pla

        rti   //return from the interrupt

      cls:
          lda #32   //load A with whatever want to fill the screen with 
                    // for clearing the screen you should use #32 which is "space"
          ldx #0    //load index register with immediate 0

      cls_loop:
                      //screen size is 40x25 or 1000 chars
          sta VIC.SCREEN, X  //store whatever is in acc to screen location plus index offset    
          sta VIC.SCREEN + $0100, X //cover the next quarter
          sta VIC.SCREEN + $0200, X // cover the 3rd quarter
          //sta SCREEN + $0300, X // this would actually go past the screen by 24 bytes
          sta VIC.SCREEN + $02E8, X // this starts at $0300 - 24 bytes 
          dex             //decrement our x counter *more efficient than adding and cmp
          bne cls_loop    // branch  if x is not zero (falls through after 255 cycles)
          rts             //return to the calling routine

}


