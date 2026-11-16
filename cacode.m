function c = cacode(prn)
% inputs a PRN number. returns a 1x1023 vector of +1/-1 chips.
% XORing G1 with a PRN-specific delayed copy of G2 gives a Gold code.
% the Gold code is formatted in a way for minimal overlap w/ other codes.
% example : c = cacode(1);

% ! ! PRN TABLE (IS-GPS-200) ! !
     % the IS-GPS-200 table, a 32x2 table that each PRN (1-32) reads.
  g2_taps = [ 2 6;  3 7;  4 8;  5 9;  1 9;  2 10; 1 8;  2 9; ...
      3 10; 2 3;  3 4;  5 6;  6 7;  7 8;  8 9;  9 10; ...
      1 4;  2 5;  3 6;  4 7;  5 8;  6 9;  1 3;  4 6; ...
      5 7;  6 8;  7 9;  8 10; 1 6;  2 7;  3 8;  4 9 ];

  % ! ! PRN VALIDATION ! !
  % MATLABs suggested debugging-related code. unnecessary, works fine.
    if ~isscalar(prn) || prn < 1 || prn > size(g2_taps, 1) || prn ~= fix(prn)
        error('PRN must be an integer from 1 to %d.', size(g2_taps, 1));
    end

  % ! ! REGISTER SETUP ! !
    g1 = ones(1, 10); % creates two fresh xor-ready slates of 10 1's
    g2 = ones(1, 10);
    a = g2_taps(prn, 1); % a looks up a prn-decided-number first  G2 box
    b = g2_taps(prn, 2); % b looks up a prn-decided-number second G2 box
    c = zeros(1, 1023); % blank slate for saving the created chip!

  % ! ! CHIP GENERATION LOOP BEGINNING ! !
    for k = 1:1023 % 1023 chip loop to create the key of the satellites public id. (2^10 - 1 = 1023)
        % the gold code is described here in a conveyor/worker allegory
          % the goal is to produce a chip, or a complex key of sorts. it does
          % this by having produced 2 digits from simple/complex comparing.
          % this chip is calculated by cycling a 10 bit conveyor that is
          % 
          % take note that there this really just generates a single consistent 1x1023 bit template.
          % g1out is also a consistent result, never impacted by g2_out or the PRN.
          % the magic is in g2out, the second digit. g2 is read in a PRN specific method.
          % the template (g1out) is read against a modified / complex yet exclusive stream (g2out).
        
        g1out = g1(end);            % takes a "screenshot" of the final g1 bit (worker logs box 10 value) = g1out
        g2out = xor(g2(a), g2(b));  % creates a g2_tap impacted DELAYED g2 bit (worker does some unique math) = g2out
        c(k) = xor(g1out, g2out);   % the chip (worker compares both g1out and g2out, writing down their differences)

        % feedback and shift step for g1
        fb1 = xor(g1(3), g1(10)); % calculates the new bit and saves to fb1 (worker solves for bit 1)
        g1 = [fb1, g1(1:9)]; % does the actual pushing out to g1 (10 bit conveyor. bit 1 is added to the loop, only g(1:9) is kept)

        % feedback and shift step for g2
        fb2 = xor(xor(xor(xor(xor(g2(2), g2(3)), g2(6)), g2(8)), g2(9)), g2(10)); % calculates new bit and saves to fb2.
        g2 = [fb2, g2(1:9)]; % works as the same conveyor belt as g1, just only using a more complicated IS-GPS-200 XOR pattern
    end

c = 1 - 2*c; % converts 1 into -1 & 0 into 1
end