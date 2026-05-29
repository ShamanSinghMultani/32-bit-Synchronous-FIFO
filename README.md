# 🔁 Parameterized Synchronous FIFO — Verilog

- Parameterized `DATA_WIDTH` and `FIFO_DEPTH` — no hardcoded values
- Extra-bit pointer technique for unambiguous full/empty detection
- Overflow and underflow protection
- `almost_full` and `almost_empty` flags with configurable thresholds
- `fifo_count` output for real-time occupancy tracking
- Active-low synchronous reset
- Verified with 6 directed test cases including simultaneous read/write

---

## 🗂️ File Structure

```
sync_fifo/
├── sync_fifo.v          # RTL design (DUT)
├── sync_fifo_tb.v       # Testbench
└── README.md
```

---

## ⚙️ Parameters

| Parameter             | Default | Description                        |
|-----------------------|---------|------------------------------------|
| `DATA_WIDTH`          | 32      | Width of data bus in bits          |
| `FIFO_DEPTH`          | 16      | Number of entries (must be 2^N)    |
| `ALMOST_FULL_THRESH`  | 14      | almost_full fires at this count    |
| `ALMOST_EMPTY_THRESH` | 2       | almost_empty fires at this count   |

---

## 🔌 Port Description

| Port           | Direction | Width              | Description                        |
|----------------|-----------|--------------------|------------------------------------|
| `clk`          | Input     | 1                  | Clock signal                       |
| `rst_n`        | Input     | 1                  | Active-low reset                   |
| `wr_en`        | Input     | 1                  | Write enable                       |
| `din`          | Input     | `DATA_WIDTH`       | Data input                         |
| `rd_en`        | Input     | 1                  | Read enable                        |
| `dout`         | Output    | `DATA_WIDTH`       | Data output                        |
| `full`         | Output    | 1                  | FIFO full flag                     |
| `empty`        | Output    | 1                  | FIFO empty flag                    |
| `almost_full`  | Output    | 1                  | Asserts when count ≥ threshold     |
| `almost_empty` | Output    | 1                  | Asserts when count ≤ threshold     |
| `fifo_count`   | Output    | `$clog2(DEPTH)+1`  | Current occupancy count            |

---

## 🧠 Design Notes

### Pointer Technique
Write (`wr_ptr`) and read (`rd_ptr`) pointers are one bit wider than the address bus. This extra MSB allows unambiguous full/empty detection:

```
empty → wr_ptr == rd_ptr
full  → (wr_ptr - rd_ptr) == FIFO_DEPTH
```

This avoids the classic ambiguity where both full and empty would show equal pointer values if only address bits were compared.

### Why FIFO_DEPTH must be a power of 2
`$clog2(FIFO_DEPTH)` is used to derive the address width. Pointer wraparound relies on natural binary overflow — only works cleanly when depth is a power of 2.

---

## 🧪 Testbench Coverage

| Test Case               | Description                                           |
|-------------------------|-------------------------------------------------------|
| Reset                   | Verifies clean initialization                         |
| Sequential write        | Fills FIFO to capacity, checks `full` flag            |
| Overflow attempt        | Write to full FIFO — blocked, count unchanged         |
| Sequential read         | Drains FIFO, checks `empty` flag                      |
| Underflow attempt       | Read from empty FIFO — blocked, count unchanged       |
| Simultaneous RD+WR      | Concurrent read and write in same clock cycle         |
| Almost flag assertion   | Fills/drains to verify threshold flag behaviour       |

---

## 🚀 How to Simulate (ModelSim)

```tcl
vlib work
vlog sync_fifo.v sync_fifo_tb.v
vsim work.sync_fifo_tb
add wave -recursive *
run -all
```

Waveform dump is auto-generated to `sync_fifo.vcd`.

---

## 📊 Simulation Results

All 6 test cases passed. Transcript confirmed:
- Correct sequential read/write with decrementing `fifo_count`
- Overflow and underflow blocked as expected
- `almost_empty` asserted at expected occupancy
- `$finish` at 1325 ns

> Simulated on ModelSim — Intel FPGA Starter Edition 10.5b

---

## 🔧 Tools Used

| Tool         | Version              |
|--------------|----------------------|
| ModelSim     | Intel FPGA 10.5b     |
| Quartus Prime | Lite Edition        |
| Language     | Verilog HDL (IEEE 1364-2001) |

---

## 📚 What I Learned

- Parameterized RTL design using `$clog2` for dynamic address width
- Extra-bit pointer arithmetic for full/empty flag logic
- Structured testbench design with directed corner case coverage
- Overflow/underflow protection in hardware buffers
- Synchronous reset and clock-domain aware design practices
