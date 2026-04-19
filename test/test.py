# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_pong(dut):
    # Crear un reloj de 25.175 MHz (aprox 39.72ns de periodo)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset inicial
    dut._log.info("Iniciando Reset...")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut.._log.info("Reset finalizado. Verificando señales...")

    # Esperar unos ciclos para que el generador HSync arranque
    await ClockCycles(dut.clk, 100)

    # Verificar que uo_out esté haciendo algo (que no sea constante 0)
    # uo_out[7] es HSync, uo_out[3] es VSync en tu configuración
    assert dut.uo_out.value != 0, "Error: Las salidas uo_out están muertas (todo en 0)"
    
    dut._log.info("Señales de salida detectadas correctamente.")

    # Simular que el Jugador 1 presiona 'Arriba' (ui_in[0])
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 50)
    dut.ui_in.value = 0
    
    dut._log.info("Test de movimiento completado.")
    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
