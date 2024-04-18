function LLRs = demap8PSK_Rmatrix(y, sigma)
    % Преобразование входного сигнала в действительную и мнимую части
    Y_I = real(y);
    Y_Q = imag(y);

    % Инициализация массива для LLR
    LLRs = zeros(length(y), 3);  % Предполагается три бита на символ

    for i = 1:length(y)
        % Получение соответствующей R-матрицы
        R = getRMatrix(determineRegion(angle(y(i))));  

        % Умножение R-матрицы на вектор [Y_I(i); Y_Q(i)]
        LLRs(i, :) = (1/sigma^2) * R' * [Y_I(i); Y_Q(i)];  % Убедитесь, что умножение происходит в правильном порядке
    end
end
