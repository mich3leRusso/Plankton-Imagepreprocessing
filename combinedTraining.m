function [I]=combinedTraining(img)
    B = imbilatfilt(img);
    B=imadjust(B);
    J = imsharpen(B);
    S=edge(J,'sobel');
    C = edge(J,'canny');
    I = imoverlay(J, S | C, 'black');
end