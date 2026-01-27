# Zynq SoC Smart Security Camera — RTL Sharpening Kernel (Resume Project)

This repository corresponds to the resume project titled:

> **Zynq SoC Smart Security Camera (RTL + AXI Video Pipeline)**

It contains my **SystemVerilog RTL implementation** of an **AXI4-Stream image sharpening kernel** and the integration artifacts used to plug the kernel into an existing Zynq video pipeline.

---

## My Contribution (What I Actually Did)

- Designed and implemented the **RTL sharpening kernel** (SystemVerilog)
- Ensured **AXI4-Stream handshake correctness** (ready/valid backpressure) and **sideband alignment** (`tuser` / `tlast`)
- Integrated the kernel into an **existing Vivado block diagram**
  (the base block diagram was reused from a prior project)

> Note: The overall platform infrastructure and block diagram baseline were reused;
> my work focuses on the **custom RTL kernel design and its integration point**.

---

## Repository Contents

- `sharpening_detect_hw.sv`  
  Top-level module that wires the sharpening datapath and maintains AXI4-Stream behavior.

- `intensity_kernel.sv`  
  Fixed-point RGB → luma/intensity conversion pipeline.

- `stencil_buf.sv`  
  Line-buffered stencil generator producing neighborhood pixels for spatial filtering.

- `sharpening_kernel.sv`  
  Pipelined Laplacian sharpening core with saturation and runtime bypass support.

- `block_diagram.pdf`  
  Vivado IP Integrator block diagram snapshot for reference and interview discussion.

(If filenames differ in your final repo, update this list to match.)

---

## Overview

The sharpening block is a fully streaming RTL module that:

- Accepts RGB pixel data via **AXI4-Stream**
- Generates neighborhood stencils for spatial filtering
- Computes a Laplacian-style detail term and adds it back to RGB
- Preserves video synchronization by forwarding **`tuser` (frame start)** and
  **`tlast` (end of line)**
- Supports **ready/valid backpressure** for safe pipeline integration

---

## Architecture

### 1) Intensity Conversion Pipeline (`intensity_kernel`)

- Converts incoming RGB pixels to a grayscale intensity value using fixed-point weights:

  **Y = 77·R + 151·G + 28·B**

- Implemented as a multi-stage pipelined datapath
- Forwards both:
  - the intensity stream (for filtering)
  - the original RGB pixels (for reconstruction)
- Propagates `tvalid`, `tuser`, and `tlast` through the pipeline

---

### 2) Stencil Generator (`stencil_buf`)

- Produces a **3×3 stencil** from a streaming intensity input using line-buffer storage
- Includes an FSM-controlled fill/active mode to manage buffer bring-up
- Forwards `tvalid`, `tuser`, and `tlast` aligned with stencil outputs
- Preserves original RGB pixels for downstream processing

---

### 3) Sharpening Core (`sharpening_kernel`)

Implements a 2-stage pipelined cross-pattern Laplacian computation:

**detail = 4·center − (up + down + left + right)**

Then:
- Adds the detail term to the original RGB channels using signed arithmetic
- Clamps each color channel to the **[0, 255]** range
- Supports a runtime **bypass/select control (`hwsw_sel`)** to output either
  original or sharpened pixels

---

### 4) Top-Level Wrapper (`sharpening_detect_hw`)

- Connects the intensity pipeline, stencil generator, and sharpening core
- Maintains AXI4-Stream semantics end-to-end, including:
  - `tready` backpressure support
  - consistent alignment of `tuser` and `tlast` with pixel data

---

## AXI4-Stream Interface Notes

- Input: `s_axis_*` (RGB pixels + sideband signals)
- Output: `m_axis_*` (sharpened RGB pixels + aligned sideband signals)
- Handshake:
  - `tvalid / tready` for backpressure
  - `tuser` forwarded through all pipeline stages
  - `tlast` forwarded through all pipeline stages

---

## Vivado Block Diagram (PDF)

A snapshot of the Vivado IP Integrator block diagram is provided as:

- `block_diagram.pdf`

This diagram illustrates how the custom sharpening IP is inserted into
a Zynq video pipeline. The base block diagram was reused from a prior project;
this repository focuses on the **custom RTL kernel and its integration**.

---

## Build / Simulation

This repository is intended primarily for RTL review and interview discussion.

Simulation instructions are intentionally minimal; the design can be exercised
using a simple AXI4-Stream testbench with any standard simulator
(e.g., XSIM, Verilator, VCS).

---

## Resume Cross-Reference

If you arrived here from my resume, this repository corresponds to:

> **Zynq SoC Smart Security Camera (RTL + AXI Video Pipeline)**  
> Custom SystemVerilog AXI4-Stream sharpening kernel

---

## License

Academic / demonstration use.
