`timescale 1ns / 1ps
/***********************************************************************************************************************
*                                                                                                                      *
* ANTIKERNEL v0.1                                                                                                      *
*                                                                                                                      *
* Copyright (c) 2012-2018 Andrew D. Zonenberg                                                                          *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

/**
	@file
	@author Andrew D. Zonenberg
	@brief Implements the Internet checksum.

	Input is fed to the checksum 16 bits at a time.
 */
module InternetChecksum(
	input wire			clk,
	input wire			load,
	input wire			process,
	input wire[15:0]	din,
	output reg[15:0]	sumout	= 0,
	output reg[15:0]	csumout	= 0
);

	////////////////////////////////////////////////////////////////////////////////////////////////
	// Checksum computation

	assign csumout = ~sumout;

	wire[15:0] sumout_next;
	InternetChecksumCombinatorial ccalc(
		.din(din),
		.cursum(load ? 16'h0 : sumout),
		.sumout(sumout_next));

	always @(posedge clk) begin
		if(load || process) begin
			sumout 	<= sumout_next;
			csumout	<= ~sumout_next;
		end
	end

endmodule

//Combinatorial internet checksum
module InternetChecksumCombinatorial(
	input wire[15:0]	din,
	input wire[15:0]	cursum,
	output reg[15:0]	sumout
);

	reg[16:0]			rawsum;

	always @(*) begin

		//Compute the raw checksum including overflow
		rawsum <= {1'b0, cursum} + {1'b0, din};

		//Add in overflow if necessary
		if(rawsum[16])
			sumout <= rawsum[15:0] + 16'd1;
		else
			sumout <= rawsum[15:0];

	end

endmodule

module InternetChecksum32bit(
	input wire			clk,
	input wire			load,
	input wire			reset,
	input wire			process,
	input wire[31:0]	din,
	output reg[15:0]	sumout	= 0,
	output reg[15:0]	csumout	= 0
	);

	////////////////////////////////////////////////////////////////////////////////////////////////
	// Checksum computation

	wire[15:0] sumout_stage1;
	wire[15:0] sumout_stage2;
	InternetChecksumCombinatorial ccalc_stage1(
		.din(din[15:0]),
		.cursum(load ? 16'h0 : sumout),
		.sumout(sumout_stage1));
	InternetChecksumCombinatorial ccalc_stage2(
		.din(din[31:16]),
		.cursum(sumout_stage1),
		.sumout(sumout_stage2));

	always @(posedge clk) begin
		if(load || process) begin
			sumout	<= sumout_stage2;
			csumout	<= ~sumout_stage2;
		end
		if(reset) begin
			sumout	<= 16'h0;
			csumout	<= 16'hffff;
		end
	end

endmodule