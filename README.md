# LUT-based Inference Pipeline (Verilog)

## 1. Project Motivation

This project was built to explore how neural network inference can be mapped onto simple digital hardware structures.

Instead of using conventional multiply-accumulate (MAC)-based implementations, this design focuses on a lookup-table (LUT) based approach, which aligns more naturally with FPGA architectures.

The goal was to understand how a small inference pipeline can be constructed using basic RTL building blocks such as combinational logic, registers, and simple control signals.

---

## 2. Why LUT-based Inference?

LUT-based inference is interesting from a hardware perspective for several reasons:

- **FPGA compatibility**: FPGAs are built around LUTs, so mapping inference directly to LUT operations avoids unnecessary arithmetic overhead
- **Low-complexity computation**: Eliminates multipliers and reduces logic depth
- **Deterministic latency**: Each lookup operation has predictable timing
- **Hardware-awareness**: Encourages thinking in terms of dataflow and bit-level representation rather than floating-point operations

This project is a simplified attempt to understand these properties at the RTL level.

---

## 3. Design Overview

The design implements a small pipelined inference module with the following stages:
Input -> Register -> LUT-based Scoring -> Register -> Decision Logic -> Output

- Inputs are captured and stabilized using registers
- Each class score is computed using LUT-based combinational logic
- Intermediate results are stored in registers to form a pipeline
- Final output is selected using simple decision logic (argmax)

The design uses valid signals to control data propagation across stages.

---

## 4. Block Diagram

+--------+    +------------------+    +------------------+    +------------------+    +------------------+    +-----------+
| n_bits | -> |  Input Register  | -> |    LUT Layer     | -> | Score Registers  | -> |  Decision Logic  | -> | class_out |
+--------+    +------------------+    | (Score Compute)  |    +------------------+    |     (Argmax)     |    +-----------+
                                      +------------------+                            +------------------+

---

## 5. Module Structure

The project is organized into a few simple modules:

- `inference_top.v`  
  Top-level module that connects all stages and manages pipeline flow

- `lut_layer.v`  
  Computes class scores based on LUT-style combinational logic

- `lut_neuron.v`  
  Basic building block representing a small LUT-based computation unit

- `decision_logic.v`  
  Selects the class with the highest score

- `inference_top_tb.v`  
  Testbench used for simulation and verification

The structure is intentionally kept simple to focus on dataflow rather than abstraction.

---

## 6. Simulation and Verification

The design was verified using:

- **Icarus Verilog (iverilog)** for compilation
- **GTKWave** for waveform inspection

### Verification approach

- Applied multiple input patterns through the testbench
- Checked reset behavior to ensure registers were properly initialized
- Observed valid signal propagation across pipeline stages
- Verified that outputs appear after expected latency
- Compared final `class_out` with intermediate class scores

### Key observation

The waveform confirms that:

- `in_valid` propagates through pipeline stages (`valid_s1`, `valid_s2`, `out_valid`)
- Data is correctly registered between stages
- The final output corresponds to the maximum class score

---

## 7. Engineering Concepts Demonstrated

This project demonstrates several core digital design concepts:

- **RTL design and modular decomposition**
- **Combinational vs sequential logic separation**
- **Pipeline design and latency control**
- **Valid signal-based dataflow control**
- **Hardware-oriented thinking for ML inference**
- **Waveform-based debugging and verification**

---

## 8. Future Extensions

There are several directions this project could be extended:

- Supporting more input bits or classes
- Increasing LUT complexity to better approximate real neural networks
- Adding parameterization (e.g., number of neurons, bit-width)
- Integrating with FPGA synthesis tools (Vivado)
- Replacing static LUT logic with trained weight mapping
- Exploring sparsity or pruning at the hardware level

---
