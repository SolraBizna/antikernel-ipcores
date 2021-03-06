`timescale 1ns / 1ps
/***********************************************************************************************************************
*                                                                                                                      *
* ANTIKERNEL v0.1                                                                                                      *
*                                                                                                                      *
* Copyright (c) 2012-2017 Andrew D. Zonenberg                                                                          *
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
	@brief Ethernet CRC-32 (derived from easics.com generator)

	Original license:

	Copyright (C) 1999-2008 Easics NV.
	 This source file may be used and distributed without restriction
	 provided that this copyright statement is not removed from the file
	 and that any derivative work contains the original copyright notice
	 and the associated disclaimer.

	 THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
	 OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
	 WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

	 Purpose : synthesizable CRC function
	   * polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
	   * data width: 8

	 Info : tools@easics.be
	        http://www.easics.com
 */
module CRC32_Ethernet_x32(
	input wire clk,
	input wire reset,
	input wire update,
	input wire[31:0] din,
	output wire[31:0] crc_flipped);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// I/O shuffling

	reg[31:0] crc = 0;

	wire[31:0] crc_not = ~crc;
	assign crc_flipped =
	{
		crc_not[24], crc_not[25], crc_not[26], crc_not[27],
		crc_not[28], crc_not[29], crc_not[30], crc_not[31],

		crc_not[16], crc_not[17], crc_not[18], crc_not[19],
		crc_not[20], crc_not[21], crc_not[22], crc_not[23],

		crc_not[8], crc_not[9], crc_not[10], crc_not[11],
		crc_not[12], crc_not[13], crc_not[14], crc_not[15],

		crc_not[0], crc_not[1], crc_not[2], crc_not[3],
		crc_not[4], crc_not[5], crc_not[6], crc_not[7]
	};

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// The actual CRC function

	wire[31:0] din_flipped =
	{
		din[0], din[1], din[2], din[3],
		din[4], din[5], din[6], din[7],

		din[8], din[9], din[10], din[11],
		din[12], din[13], din[14], din[15],

		din[16], din[17], din[18], din[19],
		din[20], din[21], din[22], din[23],

		din[24], din[25], din[26], din[27],
		din[28], din[29], din[30], din[31]
	};

	always @(posedge clk) begin
		if(reset)
			crc <= 'hffffffff;
		if(update) begin
			crc[0] <= din_flipped[31] ^ din_flipped[30] ^ din_flipped[29] ^ din_flipped[28] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[16] ^ din_flipped[12] ^ din_flipped[10] ^ din_flipped[9] ^ din_flipped[6] ^ din_flipped[0] ^ crc[0] ^ crc[6] ^ crc[9] ^ crc[10] ^ crc[12] ^ crc[16] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31];
			crc[1] <= din_flipped[28] ^ din_flipped[27] ^ din_flipped[24] ^ din_flipped[17] ^ din_flipped[16] ^ din_flipped[13] ^ din_flipped[12] ^ din_flipped[11] ^ din_flipped[9] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[6] ^ crc[7] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[13] ^ crc[16] ^ crc[17] ^ crc[24] ^ crc[27] ^ crc[28];
			crc[2] <= din_flipped[31] ^ din_flipped[30] ^ din_flipped[26] ^ din_flipped[24] ^ din_flipped[18] ^ din_flipped[17] ^ din_flipped[16] ^ din_flipped[14] ^ din_flipped[13] ^ din_flipped[9] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[2] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[2] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[16] ^ crc[17] ^ crc[18] ^ crc[24] ^ crc[26] ^ crc[30] ^ crc[31];
			crc[3] <= din_flipped[31] ^ din_flipped[27] ^ din_flipped[25] ^ din_flipped[19] ^ din_flipped[18] ^ din_flipped[17] ^ din_flipped[15] ^ din_flipped[14] ^ din_flipped[10] ^ din_flipped[9] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[3] ^ din_flipped[2] ^ din_flipped[1] ^ crc[1] ^ crc[2] ^ crc[3] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[10] ^ crc[14] ^ crc[15] ^ crc[17] ^ crc[18] ^ crc[19] ^ crc[25] ^ crc[27] ^ crc[31];
			crc[4] <= din_flipped[31] ^ din_flipped[30] ^ din_flipped[29] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[20] ^ din_flipped[19] ^ din_flipped[18] ^ din_flipped[15] ^ din_flipped[12] ^ din_flipped[11] ^ din_flipped[8] ^ din_flipped[6] ^ din_flipped[4] ^ din_flipped[3] ^ din_flipped[2] ^ din_flipped[0] ^ crc[0] ^ crc[2] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[8] ^ crc[11] ^ crc[12] ^ crc[15] ^ crc[18] ^ crc[19] ^ crc[20] ^ crc[24] ^ crc[25] ^ crc[29] ^ crc[30] ^ crc[31];
			crc[5] <= din_flipped[29] ^ din_flipped[28] ^ din_flipped[24] ^ din_flipped[21] ^ din_flipped[20] ^ din_flipped[19] ^ din_flipped[13] ^ din_flipped[10] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[3] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[10] ^ crc[13] ^ crc[19] ^ crc[20] ^ crc[21] ^ crc[24] ^ crc[28] ^ crc[29];
			crc[6] <= din_flipped[30] ^ din_flipped[29] ^ din_flipped[25] ^ din_flipped[22] ^ din_flipped[21] ^ din_flipped[20] ^ din_flipped[14] ^ din_flipped[11] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[2] ^ din_flipped[1] ^ crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[11] ^ crc[14] ^ crc[20] ^ crc[21] ^ crc[22] ^ crc[25] ^ crc[29] ^ crc[30];
			crc[7] <= din_flipped[29] ^ din_flipped[28] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[22] ^ din_flipped[21] ^ din_flipped[16] ^ din_flipped[15] ^ din_flipped[10] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[5] ^ din_flipped[3] ^ din_flipped[2] ^ din_flipped[0] ^ crc[0] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[15] ^ crc[16] ^ crc[21] ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[28] ^ crc[29];
			crc[8] <= din_flipped[31] ^ din_flipped[28] ^ din_flipped[23] ^ din_flipped[22] ^ din_flipped[17] ^ din_flipped[12] ^ din_flipped[11] ^ din_flipped[10] ^ din_flipped[8] ^ din_flipped[4] ^ din_flipped[3] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[8] ^ crc[10] ^ crc[11] ^ crc[12] ^ crc[17] ^ crc[22] ^ crc[23] ^ crc[28] ^ crc[31];
			crc[9] <= din_flipped[29] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[18] ^ din_flipped[13] ^ din_flipped[12] ^ din_flipped[11] ^ din_flipped[9] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[2] ^ din_flipped[1] ^ crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[13] ^ crc[18] ^ crc[23] ^ crc[24] ^ crc[29];
			crc[10] <= din_flipped[31] ^ din_flipped[29] ^ din_flipped[28] ^ din_flipped[26] ^ din_flipped[19] ^ din_flipped[16] ^ din_flipped[14] ^ din_flipped[13] ^ din_flipped[9] ^ din_flipped[5] ^ din_flipped[3] ^ din_flipped[2] ^ din_flipped[0] ^ crc[0] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[16] ^ crc[19] ^ crc[26] ^ crc[28] ^ crc[29] ^ crc[31];
			crc[11] <= din_flipped[31] ^ din_flipped[28] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[20] ^ din_flipped[17] ^ din_flipped[16] ^ din_flipped[15] ^ din_flipped[14] ^ din_flipped[12] ^ din_flipped[9] ^ din_flipped[4] ^ din_flipped[3] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[3] ^ crc[4] ^ crc[9] ^ crc[12] ^ crc[14] ^ crc[15] ^ crc[16] ^ crc[17] ^ crc[20] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[31];
			crc[12] <= din_flipped[31] ^ din_flipped[30] ^ din_flipped[27] ^ din_flipped[24] ^ din_flipped[21] ^ din_flipped[18] ^ din_flipped[17] ^ din_flipped[15] ^ din_flipped[13] ^ din_flipped[12] ^ din_flipped[9] ^ din_flipped[6] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[2] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[2] ^ crc[4] ^ crc[5] ^ crc[6] ^ crc[9] ^ crc[12] ^ crc[13] ^ crc[15] ^ crc[17] ^ crc[18] ^ crc[21] ^ crc[24] ^ crc[27] ^ crc[30] ^ crc[31];
			crc[13] <= din_flipped[31] ^ din_flipped[28] ^ din_flipped[25] ^ din_flipped[22] ^ din_flipped[19] ^ din_flipped[18] ^ din_flipped[16] ^ din_flipped[14] ^ din_flipped[13] ^ din_flipped[10] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[5] ^ din_flipped[3] ^ din_flipped[2] ^ din_flipped[1] ^ crc[1] ^ crc[2] ^ crc[3] ^ crc[5] ^ crc[6] ^ crc[7] ^ crc[10] ^ crc[13] ^ crc[14] ^ crc[16] ^ crc[18] ^ crc[19] ^ crc[22] ^ crc[25] ^ crc[28] ^ crc[31];
			crc[14] <= din_flipped[29] ^ din_flipped[26] ^ din_flipped[23] ^ din_flipped[20] ^ din_flipped[19] ^ din_flipped[17] ^ din_flipped[15] ^ din_flipped[14] ^ din_flipped[11] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[4] ^ din_flipped[3] ^ din_flipped[2] ^ crc[2] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[7] ^ crc[8] ^ crc[11] ^ crc[14] ^ crc[15] ^ crc[17] ^ crc[19] ^ crc[20] ^ crc[23] ^ crc[26] ^ crc[29];
			crc[15] <= din_flipped[30] ^ din_flipped[27] ^ din_flipped[24] ^ din_flipped[21] ^ din_flipped[20] ^ din_flipped[18] ^ din_flipped[16] ^ din_flipped[15] ^ din_flipped[12] ^ din_flipped[9] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[3] ^ crc[3] ^ crc[4] ^ crc[5] ^ crc[7] ^ crc[8] ^ crc[9] ^ crc[12] ^ crc[15] ^ crc[16] ^ crc[18] ^ crc[20] ^ crc[21] ^ crc[24] ^ crc[27] ^ crc[30];
			crc[16] <= din_flipped[30] ^ din_flipped[29] ^ din_flipped[26] ^ din_flipped[24] ^ din_flipped[22] ^ din_flipped[21] ^ din_flipped[19] ^ din_flipped[17] ^ din_flipped[13] ^ din_flipped[12] ^ din_flipped[8] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[0] ^ crc[0] ^ crc[4] ^ crc[5] ^ crc[8] ^ crc[12] ^ crc[13] ^ crc[17] ^ crc[19] ^ crc[21] ^ crc[22] ^ crc[24] ^ crc[26] ^ crc[29] ^ crc[30];
			crc[17] <= din_flipped[31] ^ din_flipped[30] ^ din_flipped[27] ^ din_flipped[25] ^ din_flipped[23] ^ din_flipped[22] ^ din_flipped[20] ^ din_flipped[18] ^ din_flipped[14] ^ din_flipped[13] ^ din_flipped[9] ^ din_flipped[6] ^ din_flipped[5] ^ din_flipped[1] ^ crc[1] ^ crc[5] ^ crc[6] ^ crc[9] ^ crc[13] ^ crc[14] ^ crc[18] ^ crc[20] ^ crc[22] ^ crc[23] ^ crc[25] ^ crc[27] ^ crc[30] ^ crc[31];
			crc[18] <= din_flipped[31] ^ din_flipped[28] ^ din_flipped[26] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[21] ^ din_flipped[19] ^ din_flipped[15] ^ din_flipped[14] ^ din_flipped[10] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[2] ^ crc[2] ^ crc[6] ^ crc[7] ^ crc[10] ^ crc[14] ^ crc[15] ^ crc[19] ^ crc[21] ^ crc[23] ^ crc[24] ^ crc[26] ^ crc[28] ^ crc[31];
			crc[19] <= din_flipped[29] ^ din_flipped[27] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[22] ^ din_flipped[20] ^ din_flipped[16] ^ din_flipped[15] ^ din_flipped[11] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[3] ^ crc[3] ^ crc[7] ^ crc[8] ^ crc[11] ^ crc[15] ^ crc[16] ^ crc[20] ^ crc[22] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[29];
			crc[20] <= din_flipped[30] ^ din_flipped[28] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[23] ^ din_flipped[21] ^ din_flipped[17] ^ din_flipped[16] ^ din_flipped[12] ^ din_flipped[9] ^ din_flipped[8] ^ din_flipped[4] ^ crc[4] ^ crc[8] ^ crc[9] ^ crc[12] ^ crc[16] ^ crc[17] ^ crc[21] ^ crc[23] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[30];
			crc[21] <= din_flipped[31] ^ din_flipped[29] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[24] ^ din_flipped[22] ^ din_flipped[18] ^ din_flipped[17] ^ din_flipped[13] ^ din_flipped[10] ^ din_flipped[9] ^ din_flipped[5] ^ crc[5] ^ crc[9] ^ crc[10] ^ crc[13] ^ crc[17] ^ crc[18] ^ crc[22] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31];
			crc[22] <= din_flipped[31] ^ din_flipped[29] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[19] ^ din_flipped[18] ^ din_flipped[16] ^ din_flipped[14] ^ din_flipped[12] ^ din_flipped[11] ^ din_flipped[9] ^ din_flipped[0] ^ crc[0] ^ crc[9] ^ crc[11] ^ crc[12] ^ crc[14] ^ crc[16] ^ crc[18] ^ crc[19] ^ crc[23] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31];
			crc[23] <= din_flipped[31] ^ din_flipped[29] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[20] ^ din_flipped[19] ^ din_flipped[17] ^ din_flipped[16] ^ din_flipped[15] ^ din_flipped[13] ^ din_flipped[9] ^ din_flipped[6] ^ din_flipped[1] ^ din_flipped[0] ^ crc[0] ^ crc[1] ^ crc[6] ^ crc[9] ^ crc[13] ^ crc[15] ^ crc[16] ^ crc[17] ^ crc[19] ^ crc[20] ^ crc[26] ^ crc[27] ^ crc[29] ^ crc[31];
			crc[24] <= din_flipped[30] ^ din_flipped[28] ^ din_flipped[27] ^ din_flipped[21] ^ din_flipped[20] ^ din_flipped[18] ^ din_flipped[17] ^ din_flipped[16] ^ din_flipped[14] ^ din_flipped[10] ^ din_flipped[7] ^ din_flipped[2] ^ din_flipped[1] ^ crc[1] ^ crc[2] ^ crc[7] ^ crc[10] ^ crc[14] ^ crc[16] ^ crc[17] ^ crc[18] ^ crc[20] ^ crc[21] ^ crc[27] ^ crc[28] ^ crc[30];
			crc[25] <= din_flipped[31] ^ din_flipped[29] ^ din_flipped[28] ^ din_flipped[22] ^ din_flipped[21] ^ din_flipped[19] ^ din_flipped[18] ^ din_flipped[17] ^ din_flipped[15] ^ din_flipped[11] ^ din_flipped[8] ^ din_flipped[3] ^ din_flipped[2] ^ crc[2] ^ crc[3] ^ crc[8] ^ crc[11] ^ crc[15] ^ crc[17] ^ crc[18] ^ crc[19] ^ crc[21] ^ crc[22] ^ crc[28] ^ crc[29] ^ crc[31];
			crc[26] <= din_flipped[31] ^ din_flipped[28] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[22] ^ din_flipped[20] ^ din_flipped[19] ^ din_flipped[18] ^ din_flipped[10] ^ din_flipped[6] ^ din_flipped[4] ^ din_flipped[3] ^ din_flipped[0] ^ crc[0] ^ crc[3] ^ crc[4] ^ crc[6] ^ crc[10] ^ crc[18] ^ crc[19] ^ crc[20] ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[28] ^ crc[31];
			crc[27] <= din_flipped[29] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[21] ^ din_flipped[20] ^ din_flipped[19] ^ din_flipped[11] ^ din_flipped[7] ^ din_flipped[5] ^ din_flipped[4] ^ din_flipped[1] ^ crc[1] ^ crc[4] ^ crc[5] ^ crc[7] ^ crc[11] ^ crc[19] ^ crc[20] ^ crc[21] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[29];
			crc[28] <= din_flipped[30] ^ din_flipped[28] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[22] ^ din_flipped[21] ^ din_flipped[20] ^ din_flipped[12] ^ din_flipped[8] ^ din_flipped[6] ^ din_flipped[5] ^ din_flipped[2] ^ crc[2] ^ crc[5] ^ crc[6] ^ crc[8] ^ crc[12] ^ crc[20] ^ crc[21] ^ crc[22] ^ crc[24] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[30];
			crc[29] <= din_flipped[31] ^ din_flipped[29] ^ din_flipped[28] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[25] ^ din_flipped[23] ^ din_flipped[22] ^ din_flipped[21] ^ din_flipped[13] ^ din_flipped[9] ^ din_flipped[7] ^ din_flipped[6] ^ din_flipped[3] ^ crc[3] ^ crc[6] ^ crc[7] ^ crc[9] ^ crc[13] ^ crc[21] ^ crc[22] ^ crc[23] ^ crc[25] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[31];
			crc[30] <= din_flipped[30] ^ din_flipped[29] ^ din_flipped[28] ^ din_flipped[27] ^ din_flipped[26] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[22] ^ din_flipped[14] ^ din_flipped[10] ^ din_flipped[8] ^ din_flipped[7] ^ din_flipped[4] ^ crc[4] ^ crc[7] ^ crc[8] ^ crc[10] ^ crc[14] ^ crc[22] ^ crc[23] ^ crc[24] ^ crc[26] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30];
			crc[31] <= din_flipped[31] ^ din_flipped[30] ^ din_flipped[29] ^ din_flipped[28] ^ din_flipped[27] ^ din_flipped[25] ^ din_flipped[24] ^ din_flipped[23] ^ din_flipped[15] ^ din_flipped[11] ^ din_flipped[9] ^ din_flipped[8] ^ din_flipped[5] ^ crc[5] ^ crc[8] ^ crc[9] ^ crc[11] ^ crc[15] ^ crc[23] ^ crc[24] ^ crc[25] ^ crc[27] ^ crc[28] ^ crc[29] ^ crc[30] ^ crc[31];
		end
	end

endmodule
