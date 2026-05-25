### 👋👋👋 This is Design Logic with HDL Assignment of group 1, L01

# 🛠️ Hướng Dẫn Demo RISC CPU trên FPGA Arty Z7-20

> Hướng dẫn này mô tả từng bước để tổng hợp, implement và chạy thử dự án **RISC CPU 32-bit** trên board **Digilent Arty Z7-20** sử dụng Vivado.

---

## 📋 Mục Lục

1. [Yêu Cầu Hệ Thống](#1-yêu-cầu-hệ-thống)
2. [Tổng Quan Kiến Trúc](#2-tổng-quan-kiến-trúc)
3. [Tập Lệnh (Instruction Set)](#3-tập-lệnh-instruction-set)
4. [Chuẩn Bị Project trong Vivado](#4-chuẩn-bị-project-trong-vivado)
5. [Tạo File Chương Trình (program.hex)](#5-tạo-file-chương-trình-programhex)
6. [Thêm Constraints (XDC)](#6-thêm-constraints-xdc)
7. [Synthesis & Implementation](#7-synthesis--implementation)
8. [Nạp Bitstream lên Board](#8-nạp-bitstream-lên-board)
9. [Quan Sát Kết Quả trên Board](#9-quan-sát-kết-quả-trên-board)
10. [Chạy Simulation Trước Khi Demo](#10-chạy-simulation-trước-khi-demo)
11. [Lưu Ý & Troubleshooting](#11-lưu-ý--troubleshooting)

---

## 1. Yêu Cầu Hệ Thống

| Thành phần | Yêu cầu |
|---|---|
| **FPGA Board** | Digilent Arty Z7-20 (Zynq-7000, xc7z020clg400-1) |
| **EDA Tool** | Xilinx Vivado 2020.1 trở lên (khuyến nghị 2022.2+) |
| **Hệ điều hành** | Windows 10/11 hoặc Ubuntu 20.04+ |
| **Cáp kết nối** | Micro-USB (đi kèm board) |
| **Driver** | Digilent USB-JTAG (cài qua Vivado hoặc Adept) |

---

## 2. Tổng Quan Kiến Trúc

RISC CPU này là kiến trúc **accumulator-based**, 32-bit, với FSM controller 8 trạng thái. Mỗi lệnh được thực thi trong **8 chu kỳ clock**.

```
                    ┌─────────────┐
         ┌──────────│  Controller │──────────┐
         │          │  (FSM 8st)  │          │
         │          └─────────────┘          │
         │ Control signals                   │ opcode, is_zero
         ▼                                   │
  ┌─────────────┐    addr    ┌────────────┐  │
  │  Program    │───────────►│  Address   │  │
  │  Counter    │            │    MUX     │  │
  └─────────────┘            └─────┬──────┘  │
                                   │ addr    │
                             ┌─────▼──────┐  │
                             │   Memory   │  │
                             │  (32x32b)  │  │
                             └─────┬──────┘  │
                                   │ data    │
  ┌─────────────┐            ┌─────▼──────┐  │
  │ Accumulator │◄───────────│    ALU     │◄─┘
  │  Register   │            │            │
  └─────────────┘            └────────────┘
         │ acc_out                ▲
         └────────────────────────┘ inA
```

**Các module RTL:**

| File | Module | Mô tả |
|---|---|---|
| `risc_cpu_top.v` | `risc_cpu_top` | Top-level, kết nối toàn bộ |
| `controller.v` | `controller` | FSM điều khiển 8 trạng thái |
| `alu.v` | `alu` | Đơn vị tính toán số học/logic |
| `memory.v` | `memory` | RAM 32 từ × 32-bit |
| `program_counter.v` | `program_counter` | Bộ đếm chương trình |
| `register.v` | `register` | Instruction Register & Accumulator |
| `address_mux.v` | `address_mux` | MUX chọn địa chỉ PC / IR |

---

## 3. Tập Lệnh (Instruction Set)

Mỗi lệnh dài **8-bit** (trong word 32-bit): `[7:5]` = opcode, `[4:0]` = địa chỉ.

| Opcode (3-bit) | Ký hiệu | Thao tác | Mô tả |
|---|---|---|---|
| `000` | `HLT` | Dừng | Dừng CPU |
| `001` | `SKZ` | if ACC==0: PC++ | Bỏ qua lệnh tiếp nếu ACC = 0 |
| `010` | `ADD` | ACC ← ACC + mem[addr] | Cộng với bộ nhớ |
| `011` | `AND` | ACC ← ACC & mem[addr] | AND với bộ nhớ |
| `100` | `XOR` | ACC ← ACC ^ mem[addr] | XOR với bộ nhớ |
| `101` | `LDA` | ACC ← mem[addr] | Nạp từ bộ nhớ |
| `110` | `STO` | mem[addr] ← ACC | Lưu vào bộ nhớ |
| `111` | `JMP` | PC ← addr | Nhảy tới địa chỉ |

> **Chương trình mẫu (test program) trong testbench:**
> ```
> [0] LDA 16   → ACC = mem[16] = 5
> [1] ADD 17   → ACC = 5 + 3 = 8
> [2] AND 18   → ACC = 8 & 0xFF = 8
> [3] XOR 19   → ACC = 8 ^ 0 = 8
> [4] STO 20   → mem[20] = 8
> [5] LDA 20   → ACC = mem[20] = 8
> [6] JMP 7    → Nhảy đến địa chỉ 7
> [7] HLT      → Dừng
> ```

---

## 4. Chuẩn Bị Project trong Vivado

### Bước 4.1 – Tạo Project mới

1. Mở **Vivado**, chọn **Create Project**.
2. Đặt tên project (ví dụ: `risc_cpu_arty_z7`) và chọn thư mục lưu.
3. Chọn **RTL Project** → tick **"Do not specify sources at this time"** → Next.
4. Ở phần **Default Part**, tìm và chọn:
   - **Board**: Arty Z7-20
   - Hoặc **Part**: `xc7z020clg400-1`
5. Nhấn **Finish**.

### Bước 4.2 – Thêm Source Files

1. Trong **Sources** panel, click **"+" → Add Sources → Add or create design sources**.
2. Thêm tất cả file RTL từ thư mục `risc_cpu/RTL/`:
   - `address_mux.v`
   - `alu.v`
   - `controller.v`
   - `memory.v`
   - `program_counter.v`
   - `register.v`
   - `risc_cpu_top.v` ← **Top Module**
3. Nhấn **Finish**.
4. Chuột phải vào `risc_cpu_top` → **Set as Top**.

---

## 5. Tạo File Chương Trình (program.hex)

Module `memory.v` nạp chương trình từ file `program.hex` thông qua lệnh `$readmemh`. File này cần được đặt trong **thư mục project của Vivado** (cùng cấp với `*.xpr`).

### Nội dung `program.hex` (chương trình mẫu)

```hex
000000B0
00000051
00000072
00000093
000000D4
000000B4
000000F7
00000000
00000000
00000000
00000000
00000000
00000000
00000000
00000000
00000000
00000005
00000003
000000FF
00000000
00000000
```

> **Giải thích cách mã hóa lệnh:**
> - Dòng 0 (`000000B0`): opcode `LDA` = `101`, addr = `10000` (16) → byte = `1011 0000` = `0xB0`
> - Dòng 1 (`00000051`): opcode `ADD` = `010`, addr = `10001` (17) → byte = `0101 0001` = `0x51`
> - Dòng 7 (`00000000`): opcode `HLT` = `000`

> ⚠️ **Lưu ý:** Vivado sử dụng `$readmemh` tại thời điểm **simulation**. Để dùng trên FPGA thực, cần khởi tạo memory bằng **Block Memory Generator IP** hoặc dùng `initial` với giá trị cố định (xem mục Lưu Ý).

---

## 6. Thêm Constraints (XDC)

Tạo file `arty_z7_20.xdc` trong Vivado (**Add Sources → Add or create constraints**) với nội dung sau. File này ánh xạ `clk` và `rst` của CPU vào tín hiệu vật lý trên board, và xuất tín hiệu `halt` ra LED.

```tcl
## Clock: 125 MHz system clock (Zynq PS, hoặc dùng oscillator ngoài)
## Arty Z7-20 có oscillator 125 MHz tại chân E3
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 8.000 -waveform {0 4} [get_ports { clk }]

## Reset: Button BTN0 (active HIGH)
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { rst }]

## HALT output → LED LD0 (màu xanh lá)
## Cần thêm port halt ra top-level (xem hướng dẫn sửa top module bên dưới)
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { halt_led }]

## (Tùy chọn) LED LD1: báo CPU đang chạy
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { running_led }]
```

### Sửa Top Module để Xuất Tín Hiệu Ra LED

Vì `risc_cpu_top` hiện tại chỉ có `clk` và `rst`, cần thêm output để quan sát trên board. Tạo wrapper module `risc_cpu_fpga_top.v`:

```verilog
module risc_cpu_fpga_top (
    input  clk,
    input  rst,
    output halt_led,      // LED sáng khi CPU halt
    output running_led    // LED nháy theo clock khi chạy
);
    // Chia tần: 125 MHz → ~1 Hz để LED nháy thấy được
    reg [26:0] clk_div = 0;
    reg slow_clk = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
        if (clk_div == 27'd62_500_000) begin
            clk_div  <= 0;
            slow_clk <= ~slow_clk;
        end
    end

    // Instantiate CPU với slow clock
    wire halt_internal;
    risc_cpu_top cpu_inst (
        .clk (slow_clk),
        .rst (rst)
    );

    // Kéo halt signal ra (cần hierarchical ref hoặc sửa port)
    // Giải pháp đơn giản: dùng slow_clk làm running_led
    assign halt_led    = 1'b0; // Nối vào dut.halt nếu expose port
    assign running_led = slow_clk;
endmodule
```

> 💡 **Gợi ý tốt hơn:** Thêm `output halt` vào port list của `risc_cpu_top.v` và kết nối với tín hiệu `halt` bên trong controller để quan sát trực tiếp.

---

## 7. Synthesis & Implementation

### Bước 7.1 – Chạy Synthesis

1. Trong **Flow Navigator** bên trái, click **Run Synthesis**.
2. Chọn số lượng job phù hợp → **OK**.
3. Chờ đến khi xuất hiện thông báo **"Synthesis Complete"**.
4. Kiểm tra **Synthesis Report**:
   - Không có lỗi **Error**.
   - Warning về `$readmemh` là bình thường trong synthesis.

### Bước 7.2 – Chạy Implementation

1. Click **Run Implementation** → **OK**.
2. Sau khi hoàn thành, kiểm tra **Timing Summary**:
   - **WNS (Worst Negative Slack) ≥ 0**: Timing đạt yêu cầu ✅
   - Nếu WNS < 0: Cần giảm tần số clock hoặc tối ưu RTL.

### Bước 7.3 – Generate Bitstream

1. Click **Generate Bitstream** → **OK**.
2. Chờ đến khi hoàn thành (thường 2–5 phút).

---

## 8. Nạp Bitstream lên Board

### Bước 8.1 – Kết Nối Board

1. Kết nối Arty Z7-20 với máy tính qua **cổng Micro-USB** (PROG/UART).
2. Bật nguồn board (Power switch sang ON).
3. Kiểm tra **Device Manager** (Windows) hoặc `lsusb` (Linux) thấy thiết bị Digilent.

### Bước 8.2 – Mở Hardware Manager

1. Trong Vivado, chọn **Open Hardware Manager** → **Open Target → Auto Connect**.
2. Board sẽ xuất hiện trong danh sách với tên `xc7z020_1`.

### Bước 8.3 – Program Device

1. Chuột phải vào `xc7z020_1` → **Program Device**.
2. Vivado sẽ tự điền đường dẫn bitstream (`.bit`). Xác nhận và nhấn **Program**.
3. Đèn **DONE** trên board sẽ sáng → nạp thành công.

---

## 9. Quan Sát Kết Quả trên Board

Sau khi nạp bitstream:

| Tín hiệu | Vị trí trên board | Ý nghĩa |
|---|---|---|
| **BTN0** (D19) | Nút nhấn | `rst = 1`: Reset CPU, giữ để dừng |
| **LD0** | LED xanh lá | Bật khi CPU nhận lệnh `HLT` |
| **LD1** | LED xanh dương | Nháy theo `slow_clk` → CPU đang chạy |

### Quy Trình Demo

```
1. Nhấn và giữ BTN0  →  CPU ở trạng thái RESET (tất cả về 0)
2. Thả BTN0          →  CPU bắt đầu fetch & execute lệnh
3. Quan sát LD1 nháy →  CPU đang chạy qua các lệnh LDA, ADD, AND, XOR, STO, JMP
4. Sau ~8 lệnh × 8 chu kỳ = 64 slow_clk cycles:
   LD0 sáng           →  CPU gặp lệnh HLT và dừng lại
5. Nhấn BTN0 lại     →  Reset và lặp lại chu trình
```

> ⏱️ Với `slow_clk` ≈ 1 Hz, toàn bộ chương trình mẫu hoàn thành trong **~64 giây**. Tăng tần số chia clock để demo nhanh hơn nếu cần.

---

## 10. Chạy Simulation Trước Khi Demo

Khuyến nghị chạy simulation để xác nhận logic trước khi nạp lên board.

### Thêm Testbench vào Vivado

1. **Add Sources → Add or create simulation sources**.
2. Thêm file `risc_cpu/testbench/risc_cpu_top_tb.v`.
3. Đặt `tb_risc_cpu_top` là **top simulation module**.

### Chạy Behavioral Simulation

1. Click **Run Simulation → Run Behavioral Simulation**.
2. Trong cửa sổ Tcl Console, quan sát output:

```
========== STARTING RISC CPU TOP-LEVEL TEST ==========
  Program loaded into memory.
--- De-asserting Reset ---
--- After LDA 16 (Inst 1) ---
  [PASS] ACC = mem[16]   | expected=5 (0x5), got=5 (0x5)
  [PASS] PC Incremented  | expected=1 (0x1), got=1 (0x1)
--- After ADD 17 (Inst 2) ---
  [PASS] ACC = 5 + 3     | expected=8 (0x8), got=8 (0x8)
...
FINAL RESULT: 8 PASS, 0 FAIL
>>> ALL TESTS PASSED SUCCESSFULLY!
```

3. Quan sát waveform: thêm signals `clk`, `rst`, `dut.ctrl.state`, `dut.acc.data_out`, `dut.pc.pc_out` vào **Wave** window.

---

## 11. Lưu Ý & Troubleshooting

### ⚠️ Vấn đề `$readmemh` trên FPGA thực

`$readmemh("program.hex", mem)` chỉ hoạt động trong **simulation**. Khi synthesis lên FPGA, Vivado sẽ:
- Cố gắng suy ra giá trị khởi tạo từ `initial` block → không đảm bảo trên tất cả tool version.

**Giải pháp khuyến nghị:** Thay `$readmemh` bằng khởi tạo tường minh:

```verilog
initial begin
    mem[0]  = 32'h000000B0; // LDA 16
    mem[1]  = 32'h00000051; // ADD 17
    mem[2]  = 32'h00000072; // AND 18
    mem[3]  = 32'h00000093; // XOR 19
    mem[4]  = 32'h000000D4; // STO 20
    mem[5]  = 32'h000000B4; // LDA 20
    mem[6]  = 32'h000000F7; // JMP 7
    mem[7]  = 32'h00000000; // HLT
    // Data
    mem[16] = 32'd5;
    mem[17] = 32'd3;
    mem[18] = 32'h000000FF;
    mem[19] = 32'd0;
    mem[20] = 32'd0;
end
```

### ❓ LED không phản ứng sau khi nạp

- Kiểm tra lại file XDC: pin assignment có đúng với **Arty Z7-20** không (không nhầm với Arty A7).
- Đảm bảo `halt_led` và `running_led` được khai báo đúng trong top module wrapper.

### ❓ Timing violation (WNS < 0)

- Giảm tần số clock trong XDC: thay đổi `-period` từ `8.000` lên `20.000` (50 MHz).
- Hoặc dùng `slow_clk` từ bộ chia tần như đã hướng dẫn.

### ❓ Synthesis warning về inferred latch

- Đảm bảo mọi `always @(*)` đều có `default` hoặc gán đầy đủ các output trong mọi nhánh `case`. Controller hiện tại đã xử lý đúng với dòng `{sel,...} = 9'b0` ở đầu.

---

## 📁 Cấu Trúc Thư Mục

```
Project/
├── risc_cpu/
│   ├── RTL/
│   │   ├── risc_cpu_top.v       ← Top module
│   │   ├── controller.v         ← FSM Controller
│   │   ├── alu.v                ← ALU
│   │   ├── memory.v             ← RAM 32x32
│   │   ├── program_counter.v    ← PC
│   │   ├── register.v           ← IR & Accumulator
│   │   └── address_mux.v        ← Addr MUX
│   └── testbench/
│       ├── risc_cpu_top_tb.v    ← Top-level testbench
│       └── ...                  ← Module-level testbenches
└── sim/                         ← Ảnh kết quả simulation
    ├── ALU/
    ├── Controller/
    ├── Memory/
    └── ...
```

---

*Hướng dẫn được soạn cho HCMUT – Digital Design Project | RISC CPU 32-bit on Arty Z7-20*


### Demo ✨✨✨
Watch the FPGA demo here:

UI/UX:
[![FPGA Demo](https://img.youtube.com/vi/-PD0mppv8So/1.jpg)](https://youtube.com/shorts/-PD0mppv8So)

Pipeline 2 stage:
[![FPGA Demo](https://img.youtube.com/vi/-D_QTIO0Ers/1.jpg)](https://youtube.com/shorts/-D_QTIO0Ers)
