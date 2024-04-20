function LLRs = demap8PSK_Rmatrix(yI, yQ, sigma2)
    % вычисляем фазовый угол принятого символа
    phaseAngle = atan2(yQ, yI);  

    % определяем область на основе фазового угла
    region = determineRegion(phaseAngle);  

    % получаем R-матрицу для определенной области
    R = getRMatrix(region);  

    % вычисляем LLR для каждого бита
    LLRs = [yI, yQ] * (1/sigma2) * R;
end