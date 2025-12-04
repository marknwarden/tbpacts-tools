# TB-PACTS Tools
Public repository of reusable code, metadata, and vignettes to help researchers work with the TB-PACTS clinical trial dataset, including utilities for deriving analysis-ready endpoints (e.g., time to culture conversion, MGIT time-to-positivity slopes) from raw SDTM-like data.

This repository provides reusable code, metadata, and example workflows to help researchers work with the **TB-PACTS** clinical trial datasets made available by the Critical Path Institute.

The TB-PACTS data are provided in a Standard Data Tabulation Model (SDTM) like format and are not directly analysis-ready. The SDTM and other standardized data formats are part of the Clinical Data Interchange Standards Consortium (CDISC). More information is available here: [https://www.cdisc.org/video/what-are-sdtm-and-sdtm-concepts](https://www.cdisc.org/video/what-are-sdtm-and-sdtm-concepts)

This repo aims to:

- List instructions for requesting access to the TB-PACTS clinical trial datasets hosted by the Critical Path Institute.
- Offer basic documentation and metadata for data available in TB-PACTS to help orient new users
  - Excel document with trial types and links to the main study result papers
  - CDISC defined variable dictionary
- Demonstrate example workflows/scripts using the SimpliciTB trial as an example (TB-1037)
- Provide functions to derive commonly used endpoints, such as:
  - Time to culture conversion (TTCC)
  - MGIT time-to-positivity (TTP) slopes
  - Prespecified analysis datasets from raw SDTM-like tables

> **Note:** This repository does **not** contain TB-PACTS data. Users are expected to obtain TB-PACTS access separately and configure local paths to their secure data storage. See instructions.

## Repo structure

- `R/` – Reusable source code (e.g. functions routinely used, TTCC, TTP slopes, dataset derivation).
- `scripts/` – Example scripts showing how to use `R/` functions in demonstration and end-to-end workflows.
- `demonstrations/` – Quarto/R Markdown documents demonstrating structured analyses the SimpliciTB trial as an example (TB-1037) **assumes data access already obtained**
  - `Adverse Events Visualization/` Example vignette of visualizing AE information across trial arms
  - `Sex Differences/` Example vignette of comparing sexes on various endpoints
- `metadata/` – Trial-level metadata (e.g., Excel catalogue of trials, links to protocols and publications).
  - `Analytic Dataset specification examples/` AD shells and data dictionaries
- `docs/` – Additional documentation on TB-PACTS structure and endpoint definitions.
- `config/` – Template configuration files (e.g., example paths) for users to adapt locally.

## Getting started

- Will be updated in time
