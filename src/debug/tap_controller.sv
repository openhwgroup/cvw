module tap_controller(
    input  logic tck, trst, tms, tdi,
    output logic tdo,
    output logic reset, enable, select,
    output logic ShiftIR, ClockIR, UpdateIR,
    output logic ShiftDR, ClockDR, UpdateDR
);
    // IEEE 1149.1-2001 Table 6-3
    enum logic [3:0] {
        EXIT2_DR         = 4'h0,
		EXIT1_DR         = 4'h1,
		SHIFT_DR         = 4'h2,
		PAUSE_DR         = 4'h3,
		SELECT_IR        = 4'h4,
		UPDATE_DR        = 4'h5,
		CAPTURE_DR       = 4'h6,
		SELECT_DR        = 4'h7,
		EXIT2_IR         = 4'h8,
		EXIT1_IR         = 4'h9,
		SHIFT_IR         = 4'hA,
		PAUSE_IR         = 4'hB,
		RUN_TEST_IDLE    = 4'hC,
		UPDATE_IR        = 4'hD,
		CAPTURE_IR       = 4'hE,
		TEST_LOGIC_RESET = 4'hF
	} State;

    always @(posedge tck) begin
        if (~trst) State <= TEST_LOGIC_RESET; 
        else case (State)
	        TEST_LOGIC_RESET : State <= tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
	        RUN_TEST_IDLE    : State <= tms ? SELECT_DR : RUN_TEST_IDLE;
	        SELECT_DR        : State <= tms ? SELECT_IR : CAPTURE_DR;
	        CAPTURE_DR       : State <= tms ? EXIT1_DR : SHIFT_DR;
	        SHIFT_DR         : State <= tms ? EXIT1_DR : SHIFT_DR;
	        EXIT1_DR          : State <= tms ? UPDATE_DR : PAUSE_DR;
	        PAUSE_DR          : State <= tms ? EXIT2_DR : PAUSE_DR;
	        EXIT2_DR          : State <= tms ? UPDATE_DR : SHIFT_DR;
	        UPDATE_DR         : State <= tms ? SELECT_DR : RUN_TEST_IDLE;
	        SELECT_IR        : State <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
	        CAPTURE_IR        : State <= tms ? EXIT1_IR : SHIFT_IR;
	        SHIFT_IR         : State <= tms ? EXIT1_IR : SHIFT_IR;
	        EXIT1_IR          : State <= tms ? UPDATE_IR : PAUSE_IR;
	        PAUSE_IR          : State <= tms ? EXIT2_IR : PAUSE_IR;
	        EXIT2_IR          : State <= tms ? UPDATE_IR : SHIFT_IR;
	        UPDATE_IR         : State <= tms ? SELECT_DR : RUN_TEST_IDLE;
	    endcase // case (State)
    end // always @ (posedge tck)

    // The following assignments and flops are based completely on the
    // IEEE 1149.1-2001 spec.
    
    // Instruction Register and Test Data Register should be clocked
    // on their respective CAPTURE and SHIFT states
    assign ClockIR = tck | ~(State == CAPTURE_IR) | ~(State == SHIFT_IR);
    assign ClockDR = tck | ~(State == CAPTURE_DR) | ~(State == SHIFT_DR);

    assign UpdateIR = tck & (State == UPDATE_IR);
    assign UpdateDR = tck & (State == UPDATE_DR);

    // This signal is present in the IEEE 1149.1-2001 spec, but is not
    // present in Dr. Harris' implementation
    assign select = State[3];

    always @(negedge tck, negedge trst)
      if (~trst) begin
          ShiftIR <= 0;
          ShiftDR <= 0;
          reset <= 0;
          enable <= 0;
      end else begin
          ShiftIR <= (State == SHIFT_IR);
          ShiftDR <= (State == SHIFT_DR);
          reset <= ~(State == TEST_LOGIC_RESET);
          enable <= (State == SHIFT_IR) | (State == SHIFT_DR);
      end // else: !if(~trst)
endmodule
