clear;
% Параметры
bps = 3;  % Количество бит на символ для 8PSK
EbN0_dB = (0:0.5:10);  % Значения Eb/N0 в дБ
frameLength = 300;  % Длина кадра

% Создание объектов
convEncoder = comm.ConvolutionalEncoder('TrellisStructure', poly2trellis(7, [171 133]), 'TerminationMethod', 'Truncated');  % Создание свёрточного кодера
pskMod = comm.PSKModulator('BitInput', true, 'PhaseOffset', 0, 'ModulationOrder', 8);  % Создание PSK модулятора
appDecoderLLR = comm.APPDecoder('TrellisStructure', poly2trellis(7, [171 133]), 'Algorithm', 'True APP', 'CodedBitLLROutputPort', false);  % Создание декодера APP для Log-likelihood ratio
appDecoderApproxLLR = comm.APPDecoder('TrellisStructure', poly2trellis(7, [171 133]), 'Algorithm', 'True APP', 'CodedBitLLROutputPort', false);  % Создание декодера APP для Approximate log-likelihood ratio
appDecoder8PSK = comm.APPDecoder('TrellisStructure', poly2trellis(7, [171 133]), 'Algorithm', 'True APP', 'CodedBitLLROutputPort', false);  % Создание декодера APP декодера для demap8PSK_Rmatrix

% Инициализация объектов для подсчета ошибок
errorRateLLR = comm.ErrorRate;  % Объект для подсчета ошибок (Log-likelihood ratio)
errorRateApproxLLR = comm.ErrorRate;  % Объект для подсчета ошибок (Approximate log-likelihood ratio)
errorRate8PSK = comm.ErrorRate;  % Объект для подсчета ошибок (demap8PSK_Rmatrix)

% Предварительное выделение массивов BER
berLLR = zeros(1, length(EbN0_dB));  % Вектор для хранения BER (Log-likelihood ratio)
berApproxLLR = zeros(1, length(EbN0_dB));  % Вектор для хранения BER (Approximate log-likelihood ratio)
ber8PSK = zeros(1, length(EbN0_dB));  % Вектор для хранения BER (demap8PSK_Rmatrix)

tic;

for k_idx = 1:length(EbN0_dB)
    rate = 1/2;
    EsNo = EbN0_dB(k_idx) + 10*log10(bps);  % Преобразование Eb/N0 в Es/N0
    snr_dB = EsNo + 10*log10(rate);  % Отношение сигнал/шум в дБ
    noiseVar = 1./(10.^(snr_dB/10));  % Дисперсия шума

    % Инициализация статистики ошибок
    errorStatsLLR = zeros(1, 3);  % Статистика ошибок для Log-likelihood ratio
    errorStatsApproxLLR = zeros(1, 3);  % Статистика ошибок для Approximate log-likelihood ratio
    errorStats8PSK = zeros(1, 3);  % Статистика ошибок для demap8PSK_Rmatrix

    % Цикл для подсчета ошибок
    while errorStatsLLR(2) < 1e5 && errorStatsLLR(3) < 1e8
        % Генерация данных
        data = randi([0 1], frameLength, 1);
        encodedData = convEncoder(data);
        modSignal = pskMod(encodedData);
        awgnChan = comm.AWGNChannel('NoiseMethod', 'Variance', 'Variance', noiseVar);
        receivedSignal = awgnChan(modSignal);

        % Демодуляция с использованием PSKDemodulator Log-likelihood ratio
        pskDemodLLR = comm.PSKDemodulator('BitOutput', true, 'PhaseOffset', pi/8, 'DecisionMethod', 'Log-likelihood ratio', 'Variance', noiseVar);
        demodSignalLLR = pskDemodLLR(receivedSignal);
        receivedSoftBitsLLR = appDecoderLLR(zeros(frameLength, 1), -demodSignalLLR);
        receivedBitsLLR = double(receivedSoftBitsLLR > 0);
        errorStatsLLR = errorRateLLR(data, receivedBitsLLR);

        % Демодуляция с использованием PSKDemodulator Approximate log-likelihood ratio
        pskDemodApproxLLR = comm.PSKDemodulator('BitOutput', true, 'PhaseOffset', pi/8, 'DecisionMethod', 'Approximate log-likelihood ratio', 'Variance', noiseVar);
        demodSignalApproxLLR = pskDemodApproxLLR(receivedSignal);
        receivedSoftBitsApproxLLR = appDecoderApproxLLR(zeros(frameLength, 1), -demodSignalApproxLLR);
        receivedBitsApproxLLR = double(receivedSoftBitsApproxLLR > 0);
        errorStatsApproxLLR = errorRateApproxLLR(data, receivedBitsApproxLLR);

        % Демодуляция с использованием demap8PSK_Rmatrix
        demodSignal8PSK = demap8PSK_Rmatrix(receivedSignal, noiseVar);
        receivedSoftBits8PSK = appDecoder8PSK(zeros(frameLength, 1), demodSignal8PSK);
        receivedBits8PSK = double(receivedSoftBits8PSK > 0);
        errorStats8PSK = errorRate8PSK(data, receivedBits8PSK);
    end

    % Сохранение данных BER и сброс объектов подсчета ошибок
    berLLR(k_idx) = errorStatsLLR(1);  % Сохранение BER для Log-likelihood ratio
    berApproxLLR(k_idx) = errorStatsApproxLLR(1);  % Сохранение BER для Approximate log-likelihood ratio
    ber8PSK(k_idx) = errorStats8PSK(1);  % Сохранение BER для demap8PSK_Rmatrix

    reset(errorRateLLR);  % Сброс объекта подсчета ошибок
    reset(errorRateApproxLLR);  % Сброс объекта подсчета ошибок
    reset(errorRate8PSK);  % Сброс объекта подсчета ошибок

    fprintf('Выполнение: %.2f%%\n', (k_idx / length(EbN0_dB)) * 100);
end

elapsedTime = toc;
fprintf('Время выполнения программы в секундах: %.2f \n', elapsedTime);
fprintf('Время выполнения программы в минутах: %.2f \n', elapsedTime / 60);

% Построение графика BER
figure;
semilogy(EbN0_dB, berLLR, '-o', EbN0_dB, berApproxLLR, '-square', EbN0_dB, ber8PSK, '-diamond');
grid;
xlabel('E_b/N_0 (dB)');  % Подпись оси X
ylabel('Bit Error Rate');  % Подпись оси Y
legend('Log-MAP (LLR)', 'MAX-Log-MAP (Approximate LLR)', 'demap8PSK_Rmatrix');