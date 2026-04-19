/*
 * Copyright (c) 2026 RODRIGO IPORRE
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_iporre_rm121 (
    input  wire [7:0] ui_in,    // J1: ui_in[0,1] | J2: ui_in[2,3]
    output wire [7:0] uo_out,   // Salidas PMOD TinyVGA
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    // SEÑALES E INSTANCIAS
    wire hsync, vsync, video_active;
    wire [9:0] pix_x, pix_y;
    reg [1:0] R, G, B;

    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    assign uio_out = 0;
    assign uio_oe  = 0;
    wire _unused_ok = &{ena, ui_in[7:4], uio_in};

    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // LÓGICA DE JUEGO (MOVIMIENTO Y COLISIÓN)
    reg [9:0] ball_x, ball_y;
    reg x_dir, y_dir;
    reg [9:0] paddle1_y, paddle2_y;
    reg [3:0] score_l, score_r;

    always @(posedge vsync or negedge rst_n) begin
        if (~rst_n) begin
            ball_x <= 320; ball_y <= 240;
            x_dir <= 1;    y_dir <= 1;
            paddle1_y <= 210; paddle2_y <= 210;
            score_l <= 0;  score_r <= 0;
        end else begin
            // Control Jugador 1 (Pines 0 y 1)
            if (ui_in[0] && paddle1_y > 10) paddle1_y <= paddle1_y - 4;
            if (ui_in[1] && paddle1_y < 410) paddle1_y <= paddle1_y + 4;

            // Control Jugador 2 (Pines 2 y 3)
            if (ui_in[2] && paddle2_y > 10) paddle2_y <= paddle2_y - 4;
            if (ui_in[3] && paddle2_y < 410) paddle2_y <= paddle2_y + 4;

            // Lógica de anotación
            if (ball_x >= 630) begin
                score_l <= score_l + 1;
                ball_x <= 320; ball_y <= 240; x_dir <= 0;
            end else if (ball_x <= 5) begin
                score_r <= score_r + 1;
                ball_x <= 320; ball_y <= 240; x_dir <= 1;
            end else begin
                // Rebote vertical
                if (ball_y >= 470) y_dir <= 0; else if (ball_y <= 5) y_dir <= 1;
                
                // Rebote Paleta 1 (Izquierda)
                if (x_dir == 0 && ball_x <= 25 && ball_y + 10 >= paddle1_y && ball_y <= paddle1_y + 60)
                    x_dir <= 1;
                
                // Rebote Paleta 2 (Derecha)
                if (x_dir == 1 && ball_x >= 605 && ball_y + 10 >= paddle2_y && ball_y <= paddle2_y + 60)
                    x_dir <= 0;

                ball_x <= x_dir ? ball_x + 4 : ball_x - 4;
                ball_y <= y_dir ? ball_y + 4 : ball_y - 4;
            end
        end
    end

    // CAPAS DE DIBUJO
    wire center_line = (pix_x >= 319 && pix_x <= 321) && pix_y[4];
    wire ball_on = (pix_x >= ball_x && pix_x < ball_x + 10) && (pix_y >= ball_y && pix_y < ball_y + 10);
    wire p1_on   = (pix_x >= 15 && pix_x < 25) && (pix_y >= paddle1_y && pix_y < paddle1_y + 60);
    wire p2_on   = (pix_x >= 615 && pix_x < 625) && (pix_y >= paddle2_y && pix_y < paddle2_y + 60);
    //(J1)
    wire [4:0] tx = (pix_x - 110); // Coordenadas locales
    wire [4:0] ty = (pix_y - 20);
    wire triforce_on = (pix_x >= 110 && pix_x < 126 && pix_y >= 20 && pix_y < 40) && (
        (ty < 10 && tx >= (8 - ty/2) && tx <= (8 + ty/2)) ||
        (ty >= 10 && ((tx >= (4 - (ty-10)/2) && tx <= (4 + (ty-10)/2)) || 
                     (tx >= (12 - (ty-10)/2) && tx <= (12 + (ty-10)/2))))
    );

    //(J2)
    wire mushroom_cap_on, mushroom_spots_on, mushroom_stem_on;
    wire [4:0] mx = (pix_x - 450); // Coordenadas locales
    wire [4:0] my = (pix_y - 20);
    // Rojo 
    assign mushroom_cap_on = (pix_x >= 450 && pix_x < 466 && pix_y >= 20 && pix_y < 36) && (
        (my < 12 && mx >= (8 - my/2) && mx <= (8 + my/2)) 
    );
    // Puntos blancos
    assign mushroom_spots_on = mushroom_cap_on && (
        (mx >= 6 && mx < 10 && my >= 4 && my < 8)  || // Central
        (mx >= 1 && mx < 4  && my >= 9 && my < 12) || // Izquierdo
        (mx >= 12 && mx < 15 && my >= 9 && my < 12)   // Derecho
    );
    // Tallo blanco
    assign mushroom_stem_on = (pix_x >= 454 && pix_x < 462 && pix_y >= 32 && pix_y < 40);

    // LÓGICA DE NÚMEROS (puntuacion)
    reg score_pix;
    reg [14:0] d_bits_l, d_bits_r;

    function [14:0] get_digit(input [3:0] d);
        case(d)
            0: get_digit = 15'b111_101_101_101_111; 1: get_digit = 15'b010_010_010_010_010;
            2: get_digit = 15'b111_001_111_100_111; 3: get_digit = 15'b111_001_111_001_111;
            4: get_digit = 15'b101_101_111_001_001; 5: get_digit = 15'b111_100_111_001_111;
            6: get_digit = 15'b111_100_111_101_111; 7: get_digit = 15'b111_001_001_001_001;
            8: get_digit = 15'b111_101_111_101_111; 9: get_digit = 15'b111_101_111_001_111;
            default: get_digit = 15'b0;
        endcase
    endfunction

    always @(*) begin
        score_pix = 0;
        d_bits_l = get_digit(score_l);
        d_bits_r = get_digit(score_r);
        
        if (pix_x >= 140 && pix_x < 152 && pix_y >= 20 && pix_y < 40)
            score_pix = d_bits_l[14 - (((pix_x-140)/4) + ((pix_y-20)/4)*3)];
        
        if (pix_x >= 480 && pix_x < 492 && pix_y >= 20 && pix_y < 40)
            score_pix = d_bits_r[14 - (((pix_x-480)/4) + ((pix_y-20)/4)*3)];
    end

    // SALIDA DE COLOR
    always @(*) begin
        if (!video_active) begin
            {R, G, B} = 6'b00_00_00;
        end else if (ball_on || triforce_on) begin
            {R, G, B} = 6'b11_11_00; // Amarillo
        end else if (p1_on) begin
            {R, G, B} = 6'b00_11_00; // Verde (Link)
        end else if (p2_on) begin
            {R, G, B} = 6'b11_00_00; // Rojo (Ganon)
        end else if (mushroom_cap_on && !mushroom_spots_on) {R, G, B} = 6'b11_00_00;else if (center_line || score_pix || mushroom_spots_on || mushroom_stem_on) begin
            {R, G, B} = 6'b11_11_11; // Blanco
        end else begin
            {R, G, B} = 6'b00_00_00; // Fondo Azul
        end
    end
endmodule
