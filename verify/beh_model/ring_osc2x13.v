// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
// Tunable ring oscillator---behavioral model

// Ring oscillator with 13 stages, each with two trim bits delay
// (see above).  Trim is not binary:  For trim[1:0], lower bit
// trim[0] is primary trim and must be applied first;  upper
// bit trim[1] is secondary trim and should only be applied
// after the primary trim is applied, or it has no effect.
//
// Total effective number of inverter stages in this oscillator
// ranges from 13 at trim 0 to 65 at trim 24.  The intention is
// to cover a range greater than 2x so that the midrange can be
// reached over all PVT conditions.
//
// Frequency of this ring oscillator under SPICE simulations at
// nominal PVT is maximum 214 MHz (trim 0), minimum 90 MHz (trim 24).

// Frequency of this ring oscillator measured on silicon is 
// maximum 113.35 MHz (8.8ns) and minimum 50.25 MHz (19.9ns).
// the maximum and minimum rate equations are:
// max rate = 1/(4 * delay0)
// min rate = 1/(4 * (delay0 + delay1 * 26))

module ring_osc2x13 #(parameter delay0=2.206, delay1=0.107) (
    input   wire        reset,
    input   wire [25:0] trim,
    output  reg  [1:0]  clockp
);    
    
    reg hiclock;
    integer i;
    real delay;
    wire [5:0] bcount;

    assign bcount = trim[0] + trim[1] + trim[2]
		+ trim[3] + trim[4] + trim[5] + trim[6] + trim[7]
		+ trim[8] + trim[9] + trim[10] + trim[11] + trim[12]
		+ trim[13] + trim[14] + trim[15] + trim[16] + trim[17]
		+ trim[18] + trim[19] + trim[20] + trim[21] + trim[22]
		+ trim[23] + trim[24] + trim[25];

    initial begin
	hiclock <= 1'b0;
	delay = 3.0;
    end

    // Run "hiclock" at 2x this rate, then use positive and negative
    // edges to derive the 0 and 90 degree phase clocks.

    always #delay begin
	hiclock <= (hiclock === 1'b0);
    end

    always @(trim) begin
    // Implement trim as a variable delay, one delay per trim bit
	delay = delay0 + delay1 * $itor(bcount);
    end

    always @(posedge hiclock or posedge reset) begin
	if (reset == 1'b1) begin
	    clockp[0] <= 1'b0;
	end else begin
	    clockp[0] <= (clockp[0] === 1'b0);
	end
    end

    always @(negedge hiclock or posedge reset) begin
	if (reset == 1'b1) begin
	    clockp[1] <= 1'b0;
	end else begin
	    clockp[1] <= (clockp[1] === 1'b0);
	end
    end

endmodule