# LUT-based Inference Pipeline (Verilog)

---

## 1. Project Motivation

This project explores how simple inference-like behavior can be implemented using basic digital hardware structures.

Instead of relying on conventional multiply-accumulate (MAC) operations, the design uses lookup-table (LUT) based logic to map inputs directly to outputs. This approach aligns naturally with FPGA architectures and helps focus on bit-level dataflow rather than numerical computation.

The goal was to build a small, fully synchronous pipeline using fundamental RTL components such as combinational logic, registers, and control signals.

---

## 2. Why LUT-based Inference?

From a hardware perspective, LUT-based computation has several advantages:

- **FPGA-native structure**  
  FPGAs are composed of LUTs, so mapping logic directly to LUT-style computation avoids unnecessary abstraction

- **Low complexity**  
  Eliminates multipliers and reduces arithmetic depth

- **Deterministic timing**  
  Each stage has fixed latency, making timing predictable

- **Bit-level control**  
  Encourages reasoning in terms of bit masking and combinational mapping

This project demonstrates these properties using a simplified RTL implementation.

---

## 3. Design Overview

The design implements a multi-stage pipelined inference structure:
Input -> Register -> LUT-based Scoring -> Register -> Decision Logic -> Output

- Inputs are first registered to stabilize data
- A LUT-based feature layer generates intermediate feature vectors using masked inputs
- Feature values are mapped to per-class scores using combinational logic
- Class scores are accumulated for each class
- Final output is selected using simple comparison logic (argmax)
- Valid signals control data movement across pipeline stages

---

## 4. Block Diagram



---

---

## 5. Module Structure

The design is divided into small, focused RTL modules:

- `inference_top.v`  
  Top-level module that connects all pipeline stages and manages valid signals

- `lut_feature_layer.v`  
  Generates feature vectors using masked LUT-based neurons

- `lut_feature_neuron.v`  
  Basic LUT unit that maps input bits to small output values

- `class_scoring_layer.v`  
  Converts feature vectors into per-class partial scores

- `class_scoring_neuron.v`  
  Small combinational blocks used to compute class scores

- `class_aggregator.v`  
  Accumulates partial scores into final class-wise sums

- `decision_logic.v`  
  Selects the final class output based on maximum score

- `inference_top_tb.v`  
  Testbench for simulation

---

## 6. Simulation and Verification

Simulation was performed using:

- **Icarus Verilog (iverilog)** for compilation
- **GTKWave** for waveform inspection

### Verification Approach

- Applied multiple input patterns through the testbench
- Observed behavior under different mask configurations
- Checked valid signal propagation across pipeline stages
- Verified correct accumulation of class scores
- Confirmed that output corresponds to the maximum class score

---

## 7. Waveform Results

### 1. Pipeline Overview

<img width="1188" height="419" alt="lut1" src="https://github.com/user-attachments/assets/08e580ab-79bb-4ae9-9bb4-38c313962217" />

This waveform shows how input data propagates through the pipeline.  
Each stage is separated by registers, forming a multi-cycle processing flow.

---

### 2. Feature Extraction (LUT Layer)

<img width="1170" height="292" alt="lut2" src="https://github.com/user-attachments/assets/fee985fe-926b-4160-a340-08493c75b60b" />

Masked input bits are processed through LUT-based neurons to generate feature vectors.

---

### 3. Class Scoring

<img width="1170" height="152" alt="lut3" src="https://github.com/user-attachments/assets/461ff872-ef66-4b0e-835a-debf4ee8094a" />

Feature vectors are mapped to per-class partial scores using combinational logic.

---

### 4. Aggregation and Decision

<img width="1171" height="149" alt="lut4" src="https://github.com/user-attachments/assets/394bed10-78f0-4172-b221-9ae4e5a1b8bc" />

Partial scores are accumulated, and the final class is selected using simple comparison logic.

---

### 5. Mask Effect

<img width="1074" height="473" alt="lut5" src="https://github.com/user-attachments/assets/f81014be-17e7-40e3-a931-34e5b0c4837a" />

For the same input value, changing the mask alters the generated feature vectors and class scores.

This shows that masking directly influences the dataflow and final output.

---

## 8. Engineering Concepts Demonstrated

This project demonstrates several core digital design principles:

- RTL-based modular design
- Separation of combinational and sequential logic
- Pipeline structure and stage isolation
- Valid signal-based dataflow control
- Bit-level manipulation using masking
- Waveform-based debugging and verification

---

## 9. How to Run

### Compile

```bash
iverilog -o simv \
inference_top_tb.v \
inference_top.v \
decision_logic.v \
class_aggregator.v \
class_scoring_layer.v \
class_scoring_neuron.v \
lut_feature_layer.v \
lut_feature_neuron.v
```

### Run Simulation
```bash
vvp simv
```

### View Waveform
```bash
gtkwave wave.vcd
```

