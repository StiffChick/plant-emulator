# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def reset(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_primer_orden(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await reset(dut)

    # Modo manual, muestreo en cada ciclo (p=0), amplitud maxima (x=255), k=1
    dut.ui_in.value = (0 << 4) | (1 << 3) | 0
    dut.uio_in.value = 0b111
    await ClockCycles(dut.clk, 40)
    assert int(dut.uo_out.value) == 255, f"k=1 debe llegar a 255, dio {int(dut.uo_out.value)}"

    # Bajar el escalon: debe regresar a 0
    dut.uio_in.value = 0b011
    await ClockCycles(dut.clk, 40)
    assert int(dut.uo_out.value) == 0, f"debe regresar a 0, dio {int(dut.uo_out.value)}"


@cocotb.test()
async def test_tau_mayor_es_mas_lento(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await reset(dut)

    # k_sel=7 -> k=8: tras 20 muestras debe ir muy abajo de 255
    dut.ui_in.value = (0 << 4) | (1 << 3) | 7
    dut.uio_in.value = 0b111
    await ClockCycles(dut.clk, 20)
    lento = int(dut.uo_out.value)
    assert 0 < lento < 60, f"con k=8 se esperaba un valor bajo, dio {lento}"

    anterior = lento
    for _ in range(5):
        await ClockCycles(dut.clk, 50)
        actual = int(dut.uo_out.value)
        assert actual >= anterior
        anterior = actual
