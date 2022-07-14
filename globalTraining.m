function [I]=globalTraining(img)
    J = imbilatfilt(img);
    J=imadjust(J);
    M=edge(J,'sobel');
    I = M;
end