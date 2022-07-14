function [LBP] = LocalBinaryPattern (gray_image)

%[LBP] = LocalBinaryPattern (gray_image)
% this function calc local binary pattern in a neighborhood
% instance by one radius and eight points
%
% example1:
%
% f = [151    79    17
%      121   101    10
%      139    88   108];
% [LBP] = LocalBinaryPattern (f);
% figure
% subplot(121),imshow(f, []), title('orginal mat')
% subplot(122),imshow(LBP, []), title('LBP mat')
%
% example2:
%
% cameraman = imread('cameraman.tif');
% [cameraman_LBP] = LocalBinaryPattern (cameraman);
% figure
% subplot(121),imshow(cameraman, []), title('cameraman')
% subplot(122),imshow(cameraman_LBP, []), title('LBP mat')
%
% ---------------------------------------------
% Author:
%    Sajjad Nasiri <s.nasiri.cs@gmail.com>
%    University of Bonab
%    Bonab
% ---------------------------------------------
% History:
%    Creation:           Date: 25/05/2019
%    Revision: 1.01.00   Date: 28/05/2019
%
% You can freely use the source files for commercial and academic research.


if size(gray_image, 3) > 1
    gray_image = rgb2gray(gray_image);
end

[m, n] = size(gray_image);

% mirror-reflecting
I = gray_image;
I = cat(1, I(1, :), I, I(end, :));
I = cat(2, I(:, 1), I, I(:, end));

LBP = zeros(m, n);

for i = 2:m+1
    for j = 2:n+1
        % local binary pattern in a neighborhood
        % instance by one radius and eight points 
        neighbor = I(i-1:i+1, j-1:j+1);
        neighbor(neighbor< neighbor(2, 2)) = 0;
        neighbor(neighbor>=neighbor(2, 2)) = 1;
        neighbor = [neighbor(1), neighbor(4), neighbor(7), neighbor(8), neighbor(9), neighbor(6), neighbor(3) ,neighbor(2)];
        % clockwise seventh rotation and selecting maximum possible amount
        n0 = bin2dec(num2str(neighbor));
        n1 = bin2dec(num2str(circshift(neighbor,-1, 2)));
        n2 = bin2dec(num2str(circshift(neighbor,-2, 2)));
        n3 = bin2dec(num2str(circshift(neighbor,-3, 2)));
        n4 = bin2dec(num2str(circshift(neighbor,-4, 2)));
        n5 = bin2dec(num2str(circshift(neighbor,-5, 2)));
        n6 = bin2dec(num2str(circshift(neighbor,-6, 2)));
        n7 = bin2dec(num2str(circshift(neighbor,-7, 2)));
        
        LBP(i-1, j-1) = max([n0 n1 n2 n3 n4 n5 n6 n7]);
    end
end

end