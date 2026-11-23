/*
 * Copyright (c) 2026 Fatima Hernandez
 * SPDX-License-Identifier: Apache-2.0
 *
 * Emulador de planta de primer orden ("RC en silicio").
 *   y[n+1] = y[n] + (x[n] - y[n]) / 2^k      k = 1..8
 * Equivale a H(z) = a / (z - (1 - a)),  a = 2^-k
 */
`default_nettype none

module tt_um_plant_emulator (
    input  wire [7:0] ui_in,    // configuracion
    output wire [7:0] uo_out,   // y[n]: respuesta de la planta (8 bits)
    input  wire [7:0] uio_in,   // uio_in[1:0] amplitud, uio_in[2] escalon manual
    output wire [7:0] uio_out,  // uio_out[7] = x (escalon), uio_out[6] = tick de muestreo
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ---- Configuracion ----
    wire [2:0] k_sel  = ui_in[2:0];            // k = k_sel + 1  (tau ~ 2^k muestras)
    wire       manual = ui_in[3];              // 0 = escalon automatico, 1 = manual
    wire [3:0] p_sel  = ui_in[7:4];            // muestra cada 2^p_sel ciclos de clk
    wire [7:0] amp    = {uio_in[1:0], 6'b111111}; // 63, 127, 191 o 255

    // ---- Tick de muestreo ----
    reg  [15:0] pre;
    wire [15:0] mask = (16'd1 << p_sel) - 16'd1;
    wire        tick = ((pre & mask) == mask);

    always @(posedge clk) begin
        if (!rst_n) pre <= 16'd0;
        else        pre <= pre + 16'd1;
    end

    // ---- Escalon automatico: cambia cada 4096 muestras ----
    reg [11:0] hp;
    reg        auto_hi;

    always @(posedge clk) begin
        if (!rst_n) begin
            hp      <= 12'd0;
            auto_hi <= 1'b0;
        end else if (tick) begin
            hp <= hp + 12'd1;
            if (hp == 12'hFFF) auto_hi <= ~auto_hi;
        end
    end

    wire       step_hi = manual ? uio_in[2] : auto_hi;
    wire [7:0] x       = step_hi ? amp : 8'd0;

    // ---- Planta de primer orden (punto fijo, 8 bits fraccionarios) ----
    wire [3:0] k = {1'b0, k_sel} + 4'd1;       // 1..8
    reg  [15:0] acc;

    wire signed [17:0] xin   = {2'b00, x, 8'b0};
    wire signed [17:0] accs  = {2'b00, acc};
    wire signed [17:0] diff  = xin - accs;
    wire signed [17:0] rnd   = (18'sd1 <<< k) - 18'sd1;   // redondeo hacia arriba
    wire signed [17:0] delta = (diff + rnd) >>> k;

    always @(posedge clk) begin
        if (!rst_n)    acc <= 16'd0;
        else if (tick) acc <= acc + delta[15:0];
    end

    // ---- Salidas ----
    assign uo_out  = acc[15:8];
    assign uio_out = {step_hi, tick, 6'b000000};
    assign uio_oe  = 8'b1100_0000;

    wire _unused = &{ena, uio_in[7:3], 1'b0};

endmodule
