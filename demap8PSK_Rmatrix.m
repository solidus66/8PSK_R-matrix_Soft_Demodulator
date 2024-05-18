function LLRs = demap8PSK_Rmatrix(sig, sigma2)
    % Предполагается, что sig - это комплексный вектор символов

    % Инициализация массива LLR значений
    LLRs = zeros(1, length(sig)*3);

    % Проходим по каждому символу и вычисляем LLR значения
    for k=0:(length(sig) - 1)
        yI = real(sig(k+1));
        yQ = imag(sig(k+1));
        
        % Вычисляем фазовый угол принятого символа
        phaseAngle = atan2(yQ, yI);

        % Определяем область на основе фазового угла
        region = determineRegion(phaseAngle);

        % Получаем R-матрицу для определенной области
        R = getRMatrix(region);

        % Вычисляем LLR значения для текущего символа
        LLRs(3*k+1) = yI * (1/sigma2) * R(1,1) + yQ * (1/sigma2) * R(2,1);
        LLRs(3*k+2) = yI * (1/sigma2) * R(1,2) + yQ * (1/sigma2) * R(2,2);
        LLRs(3*k+3) = yI * (1/sigma2) * R(1,3) + yQ * (1/sigma2) * R(2,3);
    end

    % Преобразуем LLRs в столбец
    LLRs = reshape(LLRs, [], 1);
end