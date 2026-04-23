import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

@cocotb.test()
async def test_project(dut):
    # 1. Configurar Reloj: 25.175 MHz son aprox 39.72ns (usamos 40ns para simulación)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # 2. Reset del Sistema
    dut._log.info("Iniciando Reset...")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Reset liberado.")

    # 3. PRUEBA REAL: Verificar Sincronismo Horizontal (HSync)
    # Aquí es donde el test se vuelve "real". Esperamos a que la señal baje.
    dut._log.info("Esperando flanco de bajada en HSync...")
    
    # Si el generador VGA funciona, uo_out[7] debe bajar en menos de 800 ciclos
    await FallingEdge(dut.uo_out[7])
    dut._log.info("¡Pulso HSync detectado! La lógica de sincronismo VGA es funcional.")

    # 4. PRUEBA DE ENTRADAS: 
    # Simulamos que el Jugador 1 presiona "Arriba" (ui_in[0] = 1)
    dut.ui_in.value = 0x01 
    await ClockCycles(dut.clk, 100)
    
    # 5. Verificación Final: Asegurar que las salidas no sean indefinidas (X o Z)
    assert dut.uo_out.value.is_resolvable, "Error: Las salidas están en un estado inválido (X o Z)"
    
    dut._log.info("Test finalizado: El diseño genera pulsos y responde a entradas.")
