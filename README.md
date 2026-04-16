# LUT vs MAC Inference Pipeline (RTL + Latency Analysis)

---

## 1. Overview

This project implements and compares two hardware inference pipelines in RTL:

- LUT-based inference (lookup-table driven)
- MAC-based inference (multiply-accumulate style)

Both pipelines process the same input stream under identical control conditions, enabling direct comparison of datapath structure and latency.

The focus is not only on implementation, but on verifying timing behavior using cycle-accurate, event-based measurement.

---

## 2. Design Concept

Two pipelines operate in parallel:

Input → LUT pipeline → Output (LUT)
      → MAC pipeline → Output (MAC)

Key idea:
- Same input
- Same control
- Different datapath

→ Enables direct latency comparison

---

## 3. Pipeline Structure

Both pipelines follow:

Input → Register → Feature Extraction → Scoring → Aggregation → Decision → Output

Difference:
- MAC pipeline contains one additional register stage
- This should introduce +1 cycle latency

---

## 4. Module Structure

rtl/
- inference_top.v            (top-level, instantiates both pipelines)
- *_lut.v                   (LUT-based logic)
- *_mac.v                   (MAC-based logic with pipeline stage)
- class_aggregator.v
- decision_logic.v

tb/
- inference_top_tb.v        (testbench with latency measurement)

results/
- waveform screenshots
- comparison_results.csv

---

## 5. Event-based Latency Measurement

Latency is measured using real signal events:

Start:
- rising edge of in_valid

End:
- out_valid_lut  → LUT latency
- out_valid_mac  → MAC latency

latency = output_cycle − input_cycle

Each run is a single transaction to ensure correct pairing.

Results are logged as:

run_id, latency_lut, latency_mac

---

## 6. Results

Measured latency:

- LUT path: 4 cycles
- MAC path: 5 cycles

Key observation:
MAC latency is consistently +1 cycle.

This confirms:
- the additional pipeline register is effective
- datapath behavior matches design intent
- valid signals are correctly aligned

---

## 7. Waveform Verification

### Pipeline Execution
<img width="1069" height="317" alt="lut1" src="https://github.com/user-attachments/assets/0e24d8b8-9c6e-4b6d-80ad-35a4aa10e35d" />

This waveform shows the overall pipeline behavior. Input-valid events propagate through staged valid signals, and the MAC path produces output one cycle later than the LUT path due to the additional pipeline register.

---

### LUT Path
<img width="956" height="272" alt="lut2" src="https://github.com/user-attachments/assets/f6d2bb55-1c70-403a-8db1-dbb1d23c3e66" />

This waveform focuses on the LUT path. It shows the propagation of valid signals through the LUT-based feature extraction and scoring stages until the final LUT output becomes valid.

---

### MAC Path
<img width="869" height="302" alt="lut3" src="https://github.com/user-attachments/assets/3f53f764-37fb-4de5-8db8-df90559ca3a5" />

This waveform focuses on the MAC path. Compared to the LUT path, the MAC pipeline includes an additional registered stage, resulting in a one-cycle delay before the final output becomes valid.

---

### Latency Comparison
<img width="1069" height="407" alt="lut4" src="https://github.com/user-attachments/assets/a1323f84-9d83-4b96-8e5f-4f681a35dfed" />

This waveform verifies the event-based latency measurement. The LUT output becomes valid 4 cycles after the input-valid event, while the MAC output becomes valid 5 cycles later, confirming the deterministic +1 cycle delay introduced by the additional MAC pipeline stage.

---

## 8. Key Takeaways

- Pipeline depth directly determines latency
- Latency must be measured using real events, not assumed
- Valid signal alignment is critical in multi-stage pipelines
- Small structural changes (1 register) produce measurable timing differences

Although both designs implement similar inference functionality, the MAC-based version introduces additional latency due to sequential accumulation.

In contrast, the LUT-based design relies purely on combinational mapping, allowing faster propagation through the pipeline.

---

## 9. How to Run

Compile:
iverilog -o simv \
tb/inference_top_tb.v \
rtl/*.v

Run:
vvp simv

View waveform:
gtkwave wave.vcd
