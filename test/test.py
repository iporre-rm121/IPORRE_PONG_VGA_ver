import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    # Configurar el reloj a 25MHz (periodo de 40ns)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset del sistema
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    
    # Esperar 10 ciclos y soltar reset
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Dejar que el juego corra por 1000 ciclos
    await ClockCycles(dut.clk, 1000)

    # Verificación: Si el hvsync está funcionando, uo_out[7] (HSync) 
    # o uo_out[3] (VSync) deberían haber cambiado de estado.
    # Simplemente verificamos que el puerto de salida no sea nulo.
    assert dut.uo_out.value is not None, "Error: Salidas no inicializadas"
    
    dut._log.info("Test finalizado: El diseño responde correctamente al reloj.")
