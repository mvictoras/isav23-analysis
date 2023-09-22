# Scaling Computational Fluid Dynamics: In Situ Visualization of NekRS using SENSEI

This repository contains the analysis and related materials for the paper titled **"Scaling Computational Fluid Dynamics: In Situ Visualization of NekRS using SENSEI"** which was accepted at the **ISAV 2023: In Situ Infrastructures for Enabling Extreme-scale Analysis and Visualization** workshop. The workshop was held in conjunction with SC23, The International Conference for High Performance Computing, Networking, Storage, and Analysis.

## Abstract
In the realm of Computational Fluid Dynamics (CFD), the demand for memory and computation resources is extreme, necessitating the use of leadership-scale computing platforms for practical domain sizes. This intensive requirement renders traditional checkpointing methods ineffective due to the significant slowdown in simulations while saving state data to disk. As we progress towards exascale and GPU-driven High-Performance Computing (HPC) and confront larger problem sizes, the choice becomes increasingly stark: to compromise data fidelity or to reduce resolution. To navigate this challenge, this study advocates for the use of *in situ* analysis and visualization techniques. These allow more frequent data "snapshots" to be taken directly from memory, thus avoiding the need for disruptive checkpointing. We detail our approach of instrumenting NekRS, a GPU-focused thermal-fluid simulation code employing the spectral element method (SEM), and describe varied *in situ* and in transit strategies for data rendering. Additionally, we provide concrete scientific use-cases and report on runs performed on Polaris, Argonne Leadership Computing Facility's (ALCF) 44 Petaflop supercomputer and Jülich Wizard for European Leadership Science (JUWELS) Booster, Jülich Supercomputing Centre's (JSC) 71 Petaflop High Performance Computing (HPC) system, offering practical insight into the implications of our methodology.

## Prerequisites
- jupyter notebook

## Publication
The full paper can be found here.

## Citation
If you use the materials or findings from this research, please cite our work as:
TBD

## Acknowledgements
This work was supported by and used resources of the Argonne Leadership Computing Facility, which is a U.S. Department of Energy Office of Science User Facility supported under Contract DE-AC02- 06CH11357. This work was supported by Northern Illinois University. This work was supported in part by the Director, Office of Science, Office of Advanced Scientific Computing Research, of the U.S. Department of Energy under Contract DE-AC02-06CH11357, through the grant “Scalable Analysis Methods and In Situ Infrastructure for Extreme Scale Knowledge Discovery”, program manager Dr. Margaret Lenz. The authors from JSC acknowledge computing time grants for the project TurbulenceSL by the JARA-HPC Vergabegremium provided on the JARA-HPC Partition part of the supercomputer JURECA at Jülich Supercomputing Centre, Forschungszentrum Jülich, the Gauss Centre for Supercomputing e.V. (www.gauss-centre.eu) for funding this project by providing computing time on the GCS Supercomputer JUWELS at Jülich Supercomputing Centre (JSC), and funding from the European Union’s Horizon 2020 research and innovation program under the Center of Excellence in Combustion (CoEC) project, grant agreement no. 952181. Support by the Joint Laboratory for Extreme Scale Computing (JLESC, https://jlesc.github.io/) for traveling is acknowledged.


