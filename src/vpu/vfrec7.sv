///////////////////////////////////////////
// vfrec7.sv
//
// Written: nfotneos@g.hmc.edu 2026-09-07
//
// Purpose: Compute floating point Reciprocal with 7 bit precision.
//
//
// Copyright (C) 2021-26 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module vfrec7 (
  input  logic [63:0] vs2,
  input  logic [2:0]  vsew,
  input  logic [2:0]  rm,

  output logic [63:0] vd,
  output logic [4:0]  fflags
);

  // --------------------------------------------------------------------------
  // VSEW encodings
  // --------------------------------------------------------------------------
  localparam logic [2:0] VSEW_16 = 3'b001;
  localparam logic [2:0] VSEW_32 = 3'b010;
  localparam logic [2:0] VSEW_64 = 3'b011;

  // --------------------------------------------------------------------------
  // RISC-V rounding modes
  // --------------------------------------------------------------------------
  localparam logic [2:0] RNE = 3'b000;
  localparam logic [2:0] RTZ = 3'b001;
  localparam logic [2:0] RDN = 3'b010;
  localparam logic [2:0] RUP = 3'b011;
  localparam logic [2:0] RMM = 3'b100;

  // fflags = {NV, DZ, OF, UF, NX}
  localparam integer NV = 4;
  localparam integer DZ = 3;
  localparam integer OF = 2;
  localparam integer UF = 1;
  localparam integer NX = 0;


  // --------------------------------------------------------------------------
  // Leading-zero counters
  //
  // These operate at the native fraction width. Their outputs are only used
  // when the selected input is subnormal.
  // --------------------------------------------------------------------------

  logic [3:0] lzc16_count;
  logic [4:0] lzc32_count;
  logic [5:0] lzc64_count;

  lzc #(.WIDTH(10)) lzc16 (
    .num     (vs2[9:0]),
    .ZeroCnt (lzc16_count)
  );

  lzc #(.WIDTH(23)) lzc32 (
    .num     (vs2[22:0]),
    .ZeroCnt (lzc32_count)
  );

  lzc #(.WIDTH(52)) lzc64 (
    .num     (vs2[51:0]),
    .ZeroCnt (lzc64_count)
  );


  // --------------------------------------------------------------------------
  // Decoded input information
  // --------------------------------------------------------------------------

  logic        valid_sew;
  logic        sign;
  logic        exp_zero;
  logic        exp_ones;
  logic        frac_zero;
  logic        snan;

  logic [10:0] exp_field;
  logic [5:0]  zero_count;

  // 2*B - 1
  logic signed [12:0] recip_exp_constant;

  // Constants for the selected FP format
  logic [63:0] sign_mask;
  logic [63:0] pos_inf;
  logic [63:0] max_finite;
  logic [63:0] canonical_nan;


  // --------------------------------------------------------------------------
  // Normalized finite-number datapath
  // --------------------------------------------------------------------------

  logic signed [12:0] norm_in_exp;
  logic signed [12:0] norm_out_exp;

  logic [9:0]  norm_frac16;
  logic [22:0] norm_frac32;
  logic [51:0] norm_frac64;

  logic [6:0] lut_idx;
  logic [6:0] lut_out;

  logic [10:0] sub_sig16;
  logic [23:0] sub_sig32;
  logic [52:0] sub_sig64;

  logic overflow_to_inf;


  // ==========================================================================
  // Main combinational datapath
  // ==========================================================================

  always_comb begin

    // ------------------------------------------------------------------------
    // Defaults
    // ------------------------------------------------------------------------

    vd                  = 64'b0;
    fflags              = 5'b0;

    valid_sew           = 1'b0;
    sign                = 1'b0;
    exp_zero            = 1'b0;
    exp_ones            = 1'b0;
    frac_zero           = 1'b0;
    snan                = 1'b0;

    exp_field           = 11'b0;
    zero_count          = 6'b0;

    recip_exp_constant  = 13'sd0;

    sign_mask           = 64'b0;
    pos_inf             = 64'b0;
    max_finite          = 64'b0;
    canonical_nan       = 64'b0;

    norm_in_exp         = 13'sd0;
    norm_out_exp        = 13'sd0;

    norm_frac16         = 10'b0;
    norm_frac32         = 23'b0;
    norm_frac64         = 52'b0;

    lut_idx             = 7'b0;

    sub_sig16           = 11'b0;
    sub_sig32           = 24'b0;
    sub_sig64           = 53'b0;

    overflow_to_inf     = 1'b0;


    // ========================================================================
    // 1. Decode input according to SEW
    // ========================================================================

    case (vsew)

      // ----------------------------------------------------------------------
      // FP16
      // ----------------------------------------------------------------------
      VSEW_16: begin
        valid_sew          = 1'b1;

        sign               = vs2[15];
        exp_field          = {6'b0, vs2[14:10]};

        exp_zero           = ~|vs2[14:10];
        exp_ones           =  &vs2[14:10];
        frac_zero          = ~|vs2[9:0];

        // Quiet/signaling bit is the MSB of the fraction.
        snan               = (!vs2[9]) && (!frac_zero);

        zero_count         = {2'b0, lzc16_count};

        // B = 15
        // 2*B - 1 = 29
        recip_exp_constant = 13'sd29;

        sign_mask          = 64'h0000_0000_0000_8000;
        pos_inf            = 64'h0000_0000_0000_7C00;
        max_finite         = 64'h0000_0000_0000_7BFF;
        canonical_nan      = 64'h0000_0000_0000_7E00;
      end


      // ----------------------------------------------------------------------
      // FP32
      // ----------------------------------------------------------------------
      VSEW_32: begin
        valid_sew          = 1'b1;

        sign               = vs2[31];
        exp_field          = {3'b0, vs2[30:23]};

        exp_zero           = ~|vs2[30:23];
        exp_ones           =  &vs2[30:23];
        frac_zero          = ~|vs2[22:0];

        snan               = (!vs2[22]) && (!frac_zero);

        zero_count         = {1'b0, lzc32_count};

        // B = 127
        // 2*B - 1 = 253
        recip_exp_constant = 13'sd253;

        sign_mask          = 64'h0000_0000_8000_0000;
        pos_inf            = 64'h0000_0000_7F80_0000;
        max_finite         = 64'h0000_0000_7F7F_FFFF;
        canonical_nan      = 64'h0000_0000_7FC0_0000;
      end


      // ----------------------------------------------------------------------
      // FP64
      // ----------------------------------------------------------------------
      VSEW_64: begin
        valid_sew          = 1'b1;

        sign               = vs2[63];
        exp_field          = vs2[62:52];

        exp_zero           = ~|vs2[62:52];
        exp_ones           =  &vs2[62:52];
        frac_zero          = ~|vs2[51:0];

        snan               = (!vs2[51]) && (!frac_zero);

        zero_count         = lzc64_count;

        // B = 1023
        // 2*B - 1 = 2045
        recip_exp_constant = 13'sd2045;

        sign_mask          = 64'h8000_0000_0000_0000;
        pos_inf            = 64'h7FF0_0000_0000_0000;
        max_finite         = 64'h7FEF_FFFF_FFFF_FFFF;
        canonical_nan      = 64'h7FF8_0000_0000_0000;
      end


      // ----------------------------------------------------------------------
      // SEW=8 and reserved encodings are unsupported by this module
      // ----------------------------------------------------------------------
      default: begin
        valid_sew = 1'b0;
      end

    endcase


    // ========================================================================
    // 2. Classify input / handle special cases
    // ========================================================================

    if (valid_sew) begin

      // ----------------------------------------------------------------------
      // Infinity or NaN
      // ----------------------------------------------------------------------
      if (exp_ones) begin

        // +/- infinity -> +/- zero
        if (frac_zero) begin
          if (sign)
            vd = sign_mask;
          else
            vd = 64'b0;
        end

        // NaN -> canonical NaN
        else begin
          vd = canonical_nan;

          if (snan)
            fflags[NV] = 1'b1;
        end
      end


      // ----------------------------------------------------------------------
      // +/- zero -> +/- infinity, divide-by-zero exception
      // ----------------------------------------------------------------------
      else if (exp_zero && frac_zero) begin

        vd = pos_inf | (sign ? sign_mask : 64'b0);

        fflags[DZ] = 1'b1;
      end


      // ----------------------------------------------------------------------
      // Very small subnormal
      //
      // If there are two or more leading zeros in the fraction, the
      // normalized output exponent exceeds 2*B and reciprocal overflow occurs.
      // ----------------------------------------------------------------------
      else if (exp_zero && (zero_count >= 6'd2)) begin

        fflags[OF] = 1'b1;
        fflags[NX] = 1'b1;


        // Positive overflow
        if (!sign) begin
          case (rm)

            // +maximum finite
            RTZ: overflow_to_inf = 1'b0;
            RDN: overflow_to_inf = 1'b0;

            // +infinity
            RNE: overflow_to_inf = 1'b1;
            RUP: overflow_to_inf = 1'b1;
            RMM: overflow_to_inf = 1'b1;

            // Illegal rm is assumed to be rejected upstream.
            default: overflow_to_inf = 1'b1;

          endcase
        end


        // Negative overflow
        else begin
          case (rm)

            // -maximum finite
            RTZ: overflow_to_inf = 1'b0;
            RUP: overflow_to_inf = 1'b0;

            // -infinity
            RNE: overflow_to_inf = 1'b1;
            RDN: overflow_to_inf = 1'b1;
            RMM: overflow_to_inf = 1'b1;

            // Illegal rm is assumed to be rejected upstream.
            default: overflow_to_inf = 1'b1;

          endcase
        end


        if (overflow_to_inf)
          vd = pos_inf | (sign ? sign_mask : 64'b0);
        else
          vd = max_finite | (sign ? sign_mask : 64'b0);
      end


      // ======================================================================
      // 3. Finite, nonzero, non-overflow input
      //
      // Normalize if subnormal, then generate the seven-bit LUT index.
      // ======================================================================
      else begin

        // --------------------------------------------------------------------
        // Subnormal input
        //
        // normalized input exponent = -leading_zero_count
        //
        // normalized fraction =
        //      fraction << (leading_zero_count + 1)
        //
        // The shift removes the newly-created leading 1.
        // --------------------------------------------------------------------
        if (exp_zero) begin

          norm_in_exp = -$signed({7'b0, zero_count});

          case (vsew)

            VSEW_16: begin
              norm_frac16 = vs2[9:0] << (zero_count + 6'd1);
              lut_idx     = norm_frac16[9:3];
            end

            VSEW_32: begin
              norm_frac32 = vs2[22:0] << (zero_count + 6'd1);
              lut_idx     = norm_frac32[22:16];
            end

            VSEW_64: begin
              norm_frac64 = vs2[51:0] << (zero_count + 6'd1);
              lut_idx     = norm_frac64[51:45];
            end

            default: begin
              lut_idx = 7'b0;
            end

          endcase
        end


        // --------------------------------------------------------------------
        // Normal input
        //
        // No normalization is necessary.
        // --------------------------------------------------------------------
        else begin

          norm_in_exp = {2'b00, exp_field};

          case (vsew)

            VSEW_16: begin
              norm_frac16 = vs2[9:0];
              lut_idx     = norm_frac16[9:3];
            end

            VSEW_32: begin
              norm_frac32 = vs2[22:0];
              lut_idx     = norm_frac32[22:16];
            end

            VSEW_64: begin
              norm_frac64 = vs2[51:0];
              lut_idx     = norm_frac64[51:45];
            end

            default: begin
              lut_idx = 7'b0;
            end

          endcase
        end


        // ====================================================================
        // 4. Reciprocal exponent
        //
        // normalized output exponent =
        //      2*B - 1 - normalized input exponent
        //
        // lut_idx -> LUT -> lut_out occurs combinationally below.
        // ====================================================================

        norm_out_exp = recip_exp_constant - norm_in_exp;

        // ==========================================================================
        // vfrec7 lookup table
        //
        // Input  = seven MSBs of normalized input fraction
        // Output = seven MSBs of normalized reciprocal fraction
        // ==========================================================================

        begin

          lut_out = 7'd0;

          case (lut_idx)

            7'd0:   lut_out = 7'd127;
            7'd1:   lut_out = 7'd125;
            7'd2:   lut_out = 7'd123;
            7'd3:   lut_out = 7'd121;
            7'd4:   lut_out = 7'd119;
            7'd5:   lut_out = 7'd117;
            7'd6:   lut_out = 7'd116;
            7'd7:   lut_out = 7'd114;
            7'd8:   lut_out = 7'd112;
            7'd9:   lut_out = 7'd110;
            7'd10:  lut_out = 7'd109;
            7'd11:  lut_out = 7'd107;
            7'd12:  lut_out = 7'd105;
            7'd13:  lut_out = 7'd104;
            7'd14:  lut_out = 7'd102;
            7'd15:  lut_out = 7'd100;
            7'd16:  lut_out = 7'd99;
            7'd17:  lut_out = 7'd97;
            7'd18:  lut_out = 7'd96;
            7'd19:  lut_out = 7'd94;
            7'd20:  lut_out = 7'd93;
            7'd21:  lut_out = 7'd91;
            7'd22:  lut_out = 7'd90;
            7'd23:  lut_out = 7'd88;
            7'd24:  lut_out = 7'd87;
            7'd25:  lut_out = 7'd85;
            7'd26:  lut_out = 7'd84;
            7'd27:  lut_out = 7'd83;
            7'd28:  lut_out = 7'd81;
            7'd29:  lut_out = 7'd80;
            7'd30:  lut_out = 7'd79;
            7'd31:  lut_out = 7'd77;
            7'd32:  lut_out = 7'd76;
            7'd33:  lut_out = 7'd75;
            7'd34:  lut_out = 7'd74;
            7'd35:  lut_out = 7'd72;
            7'd36:  lut_out = 7'd71;
            7'd37:  lut_out = 7'd70;
            7'd38:  lut_out = 7'd69;
            7'd39:  lut_out = 7'd68;
            7'd40:  lut_out = 7'd66;
            7'd41:  lut_out = 7'd65;
            7'd42:  lut_out = 7'd64;
            7'd43:  lut_out = 7'd63;
            7'd44:  lut_out = 7'd62;
            7'd45:  lut_out = 7'd61;
            7'd46:  lut_out = 7'd60;
            7'd47:  lut_out = 7'd59;
            7'd48:  lut_out = 7'd58;
            7'd49:  lut_out = 7'd57;
            7'd50:  lut_out = 7'd56;
            7'd51:  lut_out = 7'd55;
            7'd52:  lut_out = 7'd54;
            7'd53:  lut_out = 7'd53;
            7'd54:  lut_out = 7'd52;
            7'd55:  lut_out = 7'd51;
            7'd56:  lut_out = 7'd50;
            7'd57:  lut_out = 7'd49;
            7'd58:  lut_out = 7'd48;
            7'd59:  lut_out = 7'd47;
            7'd60:  lut_out = 7'd46;
            7'd61:  lut_out = 7'd45;
            7'd62:  lut_out = 7'd44;
            7'd63:  lut_out = 7'd43;
            7'd64:  lut_out = 7'd42;
            7'd65:  lut_out = 7'd41;
            7'd66:  lut_out = 7'd40;
            7'd67:  lut_out = 7'd40;
            7'd68:  lut_out = 7'd39;
            7'd69:  lut_out = 7'd38;
            7'd70:  lut_out = 7'd37;
            7'd71:  lut_out = 7'd36;
            7'd72:  lut_out = 7'd35;
            7'd73:  lut_out = 7'd35;
            7'd74:  lut_out = 7'd34;
            7'd75:  lut_out = 7'd33;
            7'd76:  lut_out = 7'd32;
            7'd77:  lut_out = 7'd31;
            7'd78:  lut_out = 7'd31;
            7'd79:  lut_out = 7'd30;
            7'd80:  lut_out = 7'd29;
            7'd81:  lut_out = 7'd28;
            7'd82:  lut_out = 7'd28;
            7'd83:  lut_out = 7'd27;
            7'd84:  lut_out = 7'd26;
            7'd85:  lut_out = 7'd25;
            7'd86:  lut_out = 7'd25;
            7'd87:  lut_out = 7'd24;
            7'd88:  lut_out = 7'd23;
            7'd89:  lut_out = 7'd23;
            7'd90:  lut_out = 7'd22;
            7'd91:  lut_out = 7'd21;
            7'd92:  lut_out = 7'd21;
            7'd93:  lut_out = 7'd20;
            7'd94:  lut_out = 7'd19;
            7'd95:  lut_out = 7'd19;
            7'd96:  lut_out = 7'd18;
            7'd97:  lut_out = 7'd17;
            7'd98:  lut_out = 7'd17;
            7'd99:  lut_out = 7'd16;
            7'd100: lut_out = 7'd15;
            7'd101: lut_out = 7'd15;
            7'd102: lut_out = 7'd14;
            7'd103: lut_out = 7'd14;
            7'd104: lut_out = 7'd13;
            7'd105: lut_out = 7'd12;
            7'd106: lut_out = 7'd12;
            7'd107: lut_out = 7'd11;
            7'd108: lut_out = 7'd11;
            7'd109: lut_out = 7'd10;
            7'd110: lut_out = 7'd9;
            7'd111: lut_out = 7'd9;
            7'd112: lut_out = 7'd8;
            7'd113: lut_out = 7'd8;
            7'd114: lut_out = 7'd7;
            7'd115: lut_out = 7'd7;
            7'd116: lut_out = 7'd6;
            7'd117: lut_out = 7'd5;
            7'd118: lut_out = 7'd5;
            7'd119: lut_out = 7'd4;
            7'd120: lut_out = 7'd4;
            7'd121: lut_out = 7'd3;
            7'd122: lut_out = 7'd3;
            7'd123: lut_out = 7'd2;
            7'd124: lut_out = 7'd2;
            7'd125: lut_out = 7'd1;
            7'd126: lut_out = 7'd1;
            7'd127: lut_out = 7'd0;

            default: lut_out = 7'd0;

          endcase
        end

        // ====================================================================
        // 5. Assemble result
        // ====================================================================

        case (vsew)

          // ------------------------------------------------------------------
          // FP16 result
          // ------------------------------------------------------------------
          VSEW_16: begin

            // normalized output exponent = 0
            if (norm_out_exp == 13'sd0) begin

              sub_sig16 = {1'b1, lut_out, 3'b0} >> 1;

              vd = {
                48'b0,
                sign,
                5'b0,
                sub_sig16[9:0]
              };
            end


            // normalized output exponent = -1
            else if (norm_out_exp == -13'sd1) begin

              sub_sig16 = {1'b1, lut_out, 3'b0} >> 2;

              vd = {
                48'b0,
                sign,
                5'b0,
                sub_sig16[9:0]
              };
            end


            // Normal result
            else begin

              vd = {
                48'b0,
                sign,
                norm_out_exp[4:0],
                lut_out,
                3'b0
              };
            end

          end


          // ------------------------------------------------------------------
          // FP32 result
          // ------------------------------------------------------------------
          VSEW_32: begin

            if (norm_out_exp == 13'sd0) begin

              sub_sig32 = {1'b1, lut_out, 16'b0} >> 1;

              vd = {
                32'b0,
                sign,
                8'b0,
                sub_sig32[22:0]
              };
            end


            else if (norm_out_exp == -13'sd1) begin

              sub_sig32 = {1'b1, lut_out, 16'b0} >> 2;

              vd = {
                32'b0,
                sign,
                8'b0,
                sub_sig32[22:0]
              };
            end


            else begin

              vd = {
                32'b0,
                sign,
                norm_out_exp[7:0],
                lut_out,
                16'b0
              };
            end

          end


          // ------------------------------------------------------------------
          // FP64 result
          // ------------------------------------------------------------------
          VSEW_64: begin

            if (norm_out_exp == 13'sd0) begin

              sub_sig64 = {1'b1, lut_out, 45'b0} >> 1;

              vd = {
                sign,
                11'b0,
                sub_sig64[51:0]
              };
            end


            else if (norm_out_exp == -13'sd1) begin

              sub_sig64 = {1'b1, lut_out, 45'b0} >> 2;

              vd = {
                sign,
                11'b0,
                sub_sig64[51:0]
              };
            end


            else begin

              vd = {
                sign,
                norm_out_exp[10:0],
                lut_out,
                45'b0
              };
            end

          end


          default: begin
            vd = 64'b0;
          end

        endcase

      end

    end

  end




endmodule
