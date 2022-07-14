function [I]=localTraining(img)
    M = edge(img,'canny');
    I = M;
end