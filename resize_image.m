function [paddedImage]=resize_image(IM)   
%% questo metodo effettua un risize mantenendo le proporzioni 
% delle dell'imagine di partenza, in modo da perdere meno qualità possibile
% quando si effettua l'ingrandimento dell'immagine
            siz=size(IM);
            s1=224;
            s2=224;
            if siz(1)>siz(2)
                s2=NaN;
                s1=224;
            elseif siz(2)>siz(1)
                s1=NaN;
                s2=224;
            else
                s1=224;
                s2=224;
            end
            FM=imresize(IM,[s1 s2]); %resize mantenendo aspect ratio
            c=size(FM);
            c(1)=224-c(1);
            c(2)=224-c(2);
            c(1)=cast(c(1)/2,'uint8');
            c(2)=cast(c(2)/2,'uint8');
            paddedImage = padarray(FM,[c(1) c(2)],255); %aggiungo padding con bianco 
end