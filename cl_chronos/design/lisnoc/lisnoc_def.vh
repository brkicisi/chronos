/* Copyright (c) 2015 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 *
 * This is the definition file. All Verilog macros are defined here.
 * Please note, that it is not intended to be used for configuration
 * (which should be done via parameters) but more for specific
 * constants, that might change over longer time periods.
 *
 * Author(s):
 *   Stefan Wallentowitz <stefan.wallentowitz@tum.de>
 *   Andreas Lankes <andreas.lankes@tum.de>
 *   Michael Tempelmeier <michael.tempelmeier@tum.de>
 */

`define FLIT_TYPE_PAYLOAD 2'b00
`define FLIT_TYPE_HEADER  2'b01
`define FLIT_TYPE_LAST    2'b10
`define FLIT_TYPE_SINGLE  2'b11

// Convenience definitions for mesh
`define SELECT_NONE  5'b00000   // NULL
`define SELECT_NORTH 5'b00001   // Input/Output Port [0], the 0-bit position is ON
`define SELECT_EAST  5'b00010   // Input/Output Port [1], the 1-bit ...
`define SELECT_SOUTH 5'b00100   // Input/Output Port [2]
`define SELECT_WEST  5'b01000   // Input/Output Port [3]
`define SELECT_LOCAL 5'b10000   // Input/Output Port [4]

`define NORTH 0
`define EAST  1
`define SOUTH 2
`define WEST  3
`define LOCAL 4

