import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer

@cocotb.test()
async def test_project(dut):
    # Configurar Reloj (Corregido 'units' a 'unit')
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())
    # Reset del Sistema
    dut._log.info("Iniciando Reset...")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1 
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Reset liberado.")
    # PRUEBA REAL: Verificar Sincronismo Horizontal (HSync)
    dut._log.info("Esperando pulso en HSync...")
    # esperamos a que el valor total del bus cambie y verificamos el bit.
    hsync_detected = False
    for _ in range(2000): # Esperamos hasta 2000 ciclos (más de una línea VGA)
        await ClockCycles(dut.clk, 1)
        # Verificamos si el bit 7 (HSync) es 0 (activo bajo)
        if int(dut.uo_out.value) & 0x80 == 0:
            hsync_detected = True
            break      
    if hsync_detected:
        dut._log.info("¡Pulso HSync detectado! La lógica VGA funciona.")
    else:
        assert False, "Error: No se detectó pulso de HSync tras 2000 ciclos."
    # PRUEBA DE ENTRADAS
    dut.ui_in.value = 0x01 
    await ClockCycles(dut.clk, 100)
    # Verificación Final
    assert dut.uo_out.value.is_resolvable, "Error: Salidas en estado inválido (X o Z)"
    dut._log.info("Test finalizado con éxito.")
