# TriALU-with-Soft-Core-CPU-FPGA-Implementation
High-performance Triple Arithmetic Logic Unit (Tri-ALU) designed with execution modes and multi-operand operation for efficient FPGA-based CPU architectures.

# Tri-ALU: High-Performance Arithmetic Logic Unit with Execution Modes and Multi-Operand Operation

This project presents the  Tri-ALU (Triple Arithmetic Logic Unit)  — a high-speed hybrid ALU architecture that integrates multiple ALU types (stack, accumulator, register, and vector).  
The Tri-ALU performs  multiple arithmetic and logic operations simultaneously using execution modes  and  multi-operand processing, reducing memory access and improving throughput in FPGA-based CPU systems.

---

   Features
-  Triple operand architecture (A, B, Feedback) 
-  Operator and routing fusion  for reduced instruction count  
-  Execution modes  (Normal, Switcher, Continuous, Switcher-Continuous)  
-  Hybrid ALU structure  (stack, accumulator, register, vector)  
-  Supports MIMD and SIMD operations 
-  FPGA implementation using VHDL 

---

  Applications
- Neural network acceleration  
- Mathematical sequences and series  
- Digital filters (MAC operations)  
- PID controllers and signal processing  
- Embedded and IoT CPUs  

---

   Technical Details
-  Language:  VHDL  
-  Platform:  Intel/Altera FPGA (Quartus Prime)  
-  Design Level:  Register-Transfer Level (RTL)  
-  Verification:  ModelSim simulation  
-  Benchmarked against:  Conventional ALU, x86, and RISC-V  

---

Results
The Tri-ALU achieved:
-  Reduced CPU operation time  
-  Lower power consumption  
-  Smaller software size  

---

Author
Abdullah Saad Albishri   
Master’s Thesis — Fahd Bin Sultan University  
Supervisor: Dr. Nazar El Fadel

> Albishri, A. S. (2023). *Design and Development of a High-Performance ALU Using Execution Modes and Multi-Operand Operation.* Master’s Thesis, Fahd Bin Sultan University.



