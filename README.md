# gps-l1-receiver
A GPS L1 C/A software receiver, written from scratch in MATLAB. Generates satellite C/A codes and acquires satellites from raw I/Q samples.

The program converts the interleaved I/Q samples to complex samples, taking 1 ms and testing each of the 32 PRNs against it.

## Data
Currently reads 2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat.  
   
Reading the data off of a file is just for current development. Implementation will later receive a data stream from the SDR into the code. Will require an active GPS antenna.

## How it works
### 1. C/A code generation (cacode.m)
Contains the IS-GPS-200 PRN table for prn_taps.

- Runs through two 10-bit shift registers (G1, G2), XORing them, giving each PRN its own unique 1023-chip code. Also known as the Gold code.
- PRNs are validated and 0/1's are converted into 1/-1 for radar.m's function calls of cacode(prn).

### 2. Acquisition (radar.m)
- In 1 ms, 4000 complex samples (4 MS/s) are read. Each PRN's 1023 chips are up-sampled to 4000, as well.
- A Doppler shift guesser tests -5 to +15 kHz in 500 Hz steps, deciding the best match. 
- In the Doppler shift guessing loop, Euler's formula is utilized on our incoming complex sample to leave 4000 samples with no spin.
- FFT circular correlation, as implemented, saves processing power by testing all 4000 code shifts at once.
- The PRN results are stored, and a graph is displayed showing the peak ratios under each PRN, with anything above our set threshold of 2.5 being a detected satellite. 
- The best Doppler guess, code phase, and ratio are saved. While the graph only displays the ratios; the Doppler, code phase, and ratios are individually printed in a table.

Each step is explained in simplified detail in the comment blocks inside the heavily commented cacode.m and radar.m.

## Results
<img width="892" height="604" alt="image" src="https://github.com/user-attachments/assets/a17cdbc2-86d3-4577-9b9c-b248fc1b0e17" />

<img width="347" height="124" alt="image" src="https://github.com/user-attachments/assets/d2b9551d-3b75-4477-b450-91bc1f91e8d8" />

## How to run
When running through MATLAB, run radar.m with cacode.m in the workspace.

In this current version (while the program depends on file-reading), set the filename in the fopen call under LOAD RECORDING.

Download and extract the .dat into the same folder, with no toolboxes needed.

By default, 2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat is the test file, and can be found in References.

## What's next
Tracking (PRN 1 first), with navigation data and a position fix.

## References
- The recording was acquired from GNSS-SDR's SourceForge page, at https://sourceforge.net/projects/gnss-sdr/files/data/.
- There is a single in-code labeled input-validation check in cacode.m, suggested by MATLAB’s AI assistant, kept as good practice of healthy code. The receiver works the exact same without it.
- IS-GPS-200, from https://navcen.uscg.gov.
