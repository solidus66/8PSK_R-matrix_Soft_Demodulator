clear;
% Parameters
%noiseVar = 2e-1;
noiseVar = (0.025:0.025:0.5);
frameLength = 300;

% Create objects
convEncoder = comm.ConvolutionalEncoder('TrellisStructure',poly2trellis(7,[171 133]),'TerminationMethod','Truncated');
pskMod = comm.PSKModulator('BitInput',true,'PhaseOffset',0);
appDecoder1 = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false);
appDecoder2 = comm.APPDecoder('TrellisStructure',poly2trellis(7,[171 133]), 'Algorithm','True APP','CodedBitLLROutputPort',false);

% Initialize error rate objects
errRate = comm.ErrorRate;
errRateSimp = comm.ErrorRate;

% Number of iterations
%numIterations = 1000;

ber1 = zeros(1,length(noiseVar));
ber2 = zeros(1,length(noiseVar));

for k = 1:length(noiseVar)
    % numFrames = 100;
    errorStats = zeros(1,3);
    errorStatsSimp = zeros(1,3);
    
    while errorStats(2) < 1000 && errorStats(3) < 1e7 
        % Generate data
        data = randi([0 1], frameLength, 1);
        encodedData = convEncoder(data);
        modSignal = pskMod(encodedData);
        awgnChan = comm.AWGNChannel('NoiseMethod','Variance', 'Variance',noiseVar(k));
        receivedSignal = awgnChan(modSignal);
        % Demodulation using the existing demodulator
        pskDemod = comm.PSKDemodulator('BitOutput',true,'PhaseOffset',pi/8, 'DecisionMethod','Approximate log-likelihood ratio', 'Variance',noiseVar(k));
        demodSignal = pskDemod(receivedSignal);
        receivedSoftBits = appDecoder1(zeros(frameLength, 1), -demodSignal);
        receivedBits = double(receivedSoftBits > 0);
        errorStats = errRate(data, receivedBits);
        % Demodulation using the new 8PSK demodulator
        demodSignal8PSK = demap8PSK_Rmatrix(receivedSignal, noiseVar(k));
        receivedSoftBits8PSK = appDecoder2(zeros(frameLength, 1), demodSignal8PSK);
        receivedBits8PSK = double(receivedSoftBits8PSK > 0);
        errorStatsSimp = errRateSimp(data, receivedBits8PSK);
    end
    % Save the BER data and reset the bit error rate object
    ber1(k) = errorStats(1);
    ber2(k) = errorStatsSimp(1);
    reset(errRate);
    reset(errRateSimp);
end

figure
semilogy(noiseVar,ber1,'-o',noiseVar,ber2,"-diamond")
grid
xlabel('noiseVar')
ylabel('Bit Error Rate')
legend('8PSK','Simp8PSK')