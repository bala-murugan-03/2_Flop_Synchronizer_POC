# ⚡ 2-Stage Flip-Flop Synchronizer: Hardware CDC Proof-of-Concept

[![Vivado](https://img.shields.io/badge/Vivado-2020.2+-orange.svg)](#)
[![Target-FPGA](https://img.shields.io/badge/Target-PYNQ--Z2%20(Zynq--7020)-blue.svg)](#)
[![Simulation](https://img.shields.io/badge/Simulation-Post--Implementation%20Timing-brightgreen.svg)](#)
[![Domain Crossing](https://img.shields.io/badge/CDC-Clock%20Domain%20Crossing-red.svg)](#)

A hardware-level Proof of Concept (PoC) demonstrating **Clock Domain Crossing (CDC) setup/hold aperture violations** and experimentally validating how a **2-Stage Flip-Flop (2-FF) Synchronizer** mitigates metastability and exponentially improves **Mean Time Between Failures (MTBF)**.

---

## 🎯 Executive Summary

In pure behavioral RTL simulation, digital flip-flops operate as mathematical abstractions with zero setup/hold apertures, deterministically resolving races to binary states (`0` or `1`). As a result, **metastability and CDC collisions remain invisible in standard RTL simulation**.

By running **Post-Implementation Timing Simulation** with physical Standard Delay Format (SDF) back-annotation on a Xilinx Zynq-7020 architecture, this project captures:
* **294 Timing Aperture Violations (`$setuphold`)** on an unsynchronized 1-FF receiver.
* **0 Violations** on the second stage of the 2-FF synchronizer.

---

## 📊 Experimental Results

Simulated over a **$50\,\mu\text{s}$** window across **7,351 Clock B cycles**:

| Metric | 1-FF Unsynchronized Path | 2-Stage Synchronizer Path | Verdict |
| :--- | :---: | :---: | :--- |
| **Evaluated Clock B Cycles** | 7,351 | 7,351 | Equal sample baseline |
| **UNISIM `$setuphold` Violations** | **294** | **0** | 1-FF repeatedly violates timing |
| **Metastability Risk Window** | Critical ($T_{\text{resolve}} \approx 0$) | Shielded ($T_{\text{resolve}} \approx T_{\text{clk\_b}}$) | **$100\%$ Isolation on Stage 2** |

### Waveform Analysis
![CDC Simulation Waveform](cdc_result.png)
* `single_ff_violations` steps upward to 294 at every physical aperture collision[cite: 1].
* `sync_2ff_violations` stays flat at 0 across the entire duration[cite: 1].

---

## 🧠 Architectural Overview

Data originating in **Domain A** ($100\,\text{MHz}$) is sampled asynchronously by **Domain B** ($147.058\,\text{MHz}$) via two parallel topologies:
