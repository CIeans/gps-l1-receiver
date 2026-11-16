% GPS acquisition. Finds if/which satellites are in the recording.

% ! ! BASE SETTINGS / PARAMETERS ! !
threshold = 2.5; % later ratio's threshold. separated for easy editing.
fs = 4e6; % sample rate: 4,000,000. later makes freq range -fs/2 to +fs/2
N = 4000; % number of samples for the FFT. later used for fs/N and 1:N.
% fs/N = spacing between frequency bins.

% ! ! LOAD RECORDING ! ! LATER SWITCH FOR ANTENNA ! ! ! ! ! ! ! ! ! ! ! ! !
fileId = fopen('2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat', 'r'); % this makes a pointer to the file and opens it!
fileData = fread(fileId, 800000, 'int16'); %fread fileId, 800000 int16 numbers, or 400,000 complex samples. this makes 100 ms.
fclose(fileId); % releases the file.

% ! ! I/Q TO COMPLEX SAMPLES ! !
I = fileData(1:2:end); % odd elements (each is a 16 bit number)
Q = fileData(2:2:end); % even elements
X = (I+1j*Q); % formula to combine I and Q into a single complex sample. abs(X) gives magnitude.

% y = abs(fftshift(fft(X(1:N)))); edited because no plot. this is frequency plotting. keeping if needed 
% takes 1:4000, transforms it into frequency bins, gets frequency bins out, shifts, then abs() = magnitude (for y)

% ! ! ACQUISITION RELATED PRE-SET VARIABLES ! !
t = (0:N-1).' / fs; % each sample has a time. this checks 0:3999 over the sample rate (thus getting time)
ratios = zeros(1,32); % initializing storage arrays
dopplers = NaN(1,32);
positions = NaN(1,32);

for prn = 1:32 % ! ! ALL IN PRN CHECKING LOOP ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
    code = cacode(prn);  % the call for the 1023 chips
    codeUp = zeros(1,N); % blank 4000 zeros vector. will later be the template.

    % ! ! UPSAMPLE CODE TO 4000 SAMPLES ! ! 
    for j = 1:N
        chipIdx = floor(((j-1) * 1023/N) + 1); % +1 because we start at 1 in MATLAB
        codeUp(j) = code(chipIdx); % each sample takes the chip it falls into (~4)
    end

    highest = 0; % reset the best peak for this prn
    codeCol = codeUp.'; % turns the modified codeUp into a column with .'
    codeTemplate = conj(fft(codeCol));
    % codeCol is just a template.
    %   by running both of them through fft, we turn them both into frequency
    %   arrows, being able to multiply bin by bin due to compatibility. conj flips the
    %   template's angles, allowing our templates angles to cancel. this leaves
    %   one obvious spike when we use ifft, giving us 4000 scores (with each one
    %   being per templates offset)

    % ! ! DOPPLER SHIFT FINDING LOOP ! !
    for fd = -5000:500:15000 % try 41 Doppler guesses, keep one w/ tallest spike
        sig = X(1:N) .* exp(-1j*2*pi*fd*t); % multiplying a complex exponential slides a signal down in frequency.
        % exp(-1j * 2pi * fd * t) is an applied Euler's formula to remove the spin from X(1:N).
        % X(1:N) refers to our incoming complex sample.
        % exp(1j*2) is the Euler's formula, finding the spin of the signal.
        % By making it negative and applying it to our samples (fd) over
        % time, we basically get the spin-flipped inversion of X(1:N). By
        % multiplying them together, signal gets X(1:N) with no spin.
        
        corr = ifft(fft(sig) .* codeTemplate); % multiplying the template along the signal.
        power = abs(corr).^2; % turns corr into the power of the signal. ^2 for boosting.
        [maxPower, maxPosition] = max(power); % separates maxPower and maxPosition (per loop)
        
        % ! ! HIGHEST SIGNAL READING RESULTS (DATA SAVING) ! !
        if maxPower > highest % fairly self-evident loop. logs current highest power, saving its data into best.
            highest = maxPower; 
            bestFd = fd;
            bestPosition = maxPosition;
            bestPower = power;
        end
    end

    % ! ! DETECTION TEST (PEAK RATIO) ! !
    p2 = bestPower; % copy of power
    w = 4; % the 1023 chips were spread into samples. its about 4 samples per.
    idx = (bestPosition - w) : (bestPosition + w); % 1 chip lower and higher.
    idx = mod(idx - 1, N) + 1; % this is a safety net. it allows slopes to wrap if a signal is at the edge.
    p2(idx) = 0; % erases the first max signal in p2, the entire triangle. makes p2 the 2nd highest signal.
    ratio = max(bestPower) / max(p2); % divides max(1st choice) / max(2nd choice)
    % strong difference means its most likely a signal.
    %   weak signal can also happen, usually can be better caught by
    %   adding up 10 ms instead of 1. ! ! WILL BE ADDED LATER ! !

    % ! ! SAVE 1 PRN RESULT TO PERMANENT STORAGE ARRAYS ! !
    ratios(prn) = ratio; % ratio is important for making sure that a signal is truly different from regular noise.
    dopplers(prn) = bestFd;
    positions(prn) = bestPosition;
end % ! ! END OF PRN CHECKING LOOPING ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !

% ! ! PLOT / RESULTS ! !
% the plot just graphs the signal strengths in any of the 32 PRNs. 
% uses ratio to confirm significant signal strength.
detectedPrns = find(ratios > threshold); % filter system.
fprintf('Detected PRNs: %s\n', mat2str(detectedPrns));
figure;
bar(1:32, ratios); 
yline(threshold, '--');               % the detection threshold
xlabel('PRN'); ylabel('Peak ratio');
title('Acquisition: which satellites are visible');

% ! ! TABLE OF DOPPLERS + POSITIONS OF PRNS ! !
% MATLABs suggested debugging-related code. unnecessary due to graph.
fprintf('PRN   Doppler (Hz)   Code position   Ratios\n');
fprintf('%3d   %12.0f   %13d   %3.2f\n', [detectedPrns; dopplers(detectedPrns); positions(detectedPrns); ratios(detectedPrns)]);