warning off
clear, clc

%% CARICAMENTO DATI INIZIALI
%carica dataset
load('Datas_44.mat','DATA');
NF=size(DATA{3},1); %number of folds
DIV=DATA{3};%divisione fra training e test set
DIM1=DATA{4};%numero di training pattern
DIM2=DATA{5};%numero di pattern
yE=DATA{2};%label dei patterns
NX=DATA{1};%immagini

%% RETE ED OPZIONI

%carica rete pre-trained
%net = alexnet;  %load AlexNet
%siz=[227 227];
%se alexNet va male (troppo) prova (sempre che riesci con i tempi computazionali):
net = resnet50;
siz=[224 224];

%parametri rete neurale
miniBatchSize = 30;
learningRate = 1e-4;
metodoOptim='sgdm';
options = trainingOptions(metodoOptim,...
    'MiniBatchSize',miniBatchSize,...
    'MaxEpochs',30,...
    'InitialLearnRate',learningRate,...
    'Verbose',false,...
    'Plots','training-progress');

%% SCELTA PREPROCESSING
% type:
% 1 --> globalTraining
% 2 --> localTraining
% 3 --> combinedTraining
% 4 --> base filters
% 5 --> filtro bilaterale
% 6 --> filtro anisotropico
% 7 --> filtro gaussiano
% 8 --> wavelet
% 9 --> LBP
% else --> nessun preprocessing eccetto resize_image

type=5; % variabile che identifica il tipo di preprocessing


%% 2-FOLD TRAINING E TESTING

if type==9 % LBP
    NF = 1; % riduco folds a 1 per elevata complessità computazionale di LBP
end

for fold=1:NF
    close all force
    
    %% ESTRAZIONE PARAMETRI
    trainPattern=(DIV(fold,1:DIM1));
    testPattern=(DIV(fold,DIM1+1:DIM2));
    y=yE(DIV(fold,1:DIM1));%training label
    yy=yE(DIV(fold,DIM1+1:DIM2));%test label
    numClasses = max(y);%number of classes
    
    %% TRAINING SET E PREPROCESSING
    %creo il training set
    clear nome trainingImages
    for pattern=1:(DIM1)
        IM=NX{DIV(fold,pattern)};%singola data immagini
        IM=rgb2gray(IM);
           
        %inserire qui eventuale pre-processing sull'immagine IM

        % adattamento della dimensione dell'immagine mantenendo le proporzioni
        paddedImage = resize_image(IM); % aggiungo padding con bianco
           if type==1 % global features training
               IM=globalTraining(paddedImage);
           elseif type==2 % local features training
               IM=localTraining(paddedImage);
           elseif type==3 % global+local features training
               IM=combinedTraining(paddedImage);
           elseif type==4 % training base
               IM=paddedImage;
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==5 % training filtro bilaterale
               IM=paddedImage;
               IM = imbilatfilt(IM);
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==6 % training filtro anisotropico
               IM=paddedImage;
               IM = imdiffusefilt(IM);
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==7 % training filtro gaussiano
               IM=paddedImage;
               PSF = fspecial('gaussian',5,5);
               IM = deconvlucy(IM,PSF,5);
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==8
               [cA,cH,cV,cD] = dwt2(paddedImage,'sym4','mode','per');
               I1=imfuse(cA,cH,'montage');
               I2=imfuse(cV,cD,'montage');
               IM=cat(1,I1,I2);
           elseif type==9
               IM=paddedImage-128;
               IM=LocalBinaryPattern(IM);
           else % nessun preprocessing
               IM = paddedImage;
           end
           % resize per input alla rete
           IM = imresize(IM, [224, 224]);
           if size(IM,3)==1
            IM(:,:,2)=IM;
            IM(:,:,3)=IM(:,:,1);
           end
           trainingImages(:,:,:,pattern)=IM;
    end
    
    %% DATA AUGMENTATION
    %creazione pattern aggiuntivi, data augmentation
    imageAugmenter = imageDataAugmenter( ...
        'RandXReflection',true, ...
        'RandXScale',[1 2], ...
        'RandYReflection',true, ...
        'RandYScale',[1 2],...
        'RandRotation',[-10 10],...
        'RandXTranslation',[0 5],...
        'RandYTranslation', [0 5]);

    trainingImages = augmentedImageSource([224 224],trainingImages,categorical(y),'DataAugmentation',imageAugmenter);
    
    %% TRAINING
    %tuning della rete
    % The last three layers of the pretrained network net are configured for 1000 classes.
    %These three layers must be fine-tuned for the new classification problem. Extract all layers, except the last three, from the pretrained network.
    lgraph = layerGraph(net);
    lgraph = removeLayers(lgraph, {'ClassificationLayer_fc1000','fc1000_softmax','fc1000'});

    layers = [
        fullyConnectedLayer(numClasses,'WeightLearnRateFactor',20,'BiasLearnRateFactor',20)
        softmaxLayer
        classificationLayer];

    lgraph = addLayers(lgraph,layers);
    lgraph = connectLayers(lgraph,'avg_pool','fc');
    %analyzeNetwork(lgraph)

    netTransfer = trainNetwork(trainingImages,lgraph,options);

    %% TESTING
    % creo test set
    clear nome test testImages
    for pattern=ceil(DIM1)+1:ceil(DIM2)
        IM=NX{DIV(fold,pattern)};%singola data immagine
        IM=rgb2gray(IM);
        
        %inserire qui eventuale pre-processing sull'immagine IM
        paddedImage = resize_image(IM);
           if type==1 % global features training
               IM=globalTraining(paddedImage);
           elseif type==2 % local features training
               IM=localTraining(paddedImage);
           elseif type==3 % global+local features training
               IM=combinedTraining(paddedImage);
           elseif type==4 % training base
               IM=paddedImage;
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==5 % training filtro bilaterale
               IM=paddedImage;
               IM = imbilatfilt(IM);
               IM = imadjust(IM);
               IM = imsharpen(IM);           
           elseif type==6 % training filtro anisotropico
               IM=paddedImage;
               IM = imdiffusefilt(IM);
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==7 % training filtro gaussiano
               IM=paddedImage;
               PSF = fspecial('gaussian',5,5);
               IM = deconvlucy(IM,PSF,5);
               IM = imadjust(IM);
               IM = imsharpen(IM);
           elseif type==8
               [cA,cH,cV,cD] = dwt2(paddedImage,'sym4','mode','per');
               I1=imfuse(cA,cH,'montage');
               I2=imfuse(cV,cD,'montage');
               IM=cat(1,I1,I2);
           elseif type==9
               IM=paddedImage-128;
               IM=LocalBinaryPattern(IM);
           else % nessun preprocessing
               IM = paddedImage;
           end
           % resize per input alla rete
           IM = imresize(IM, [224, 224]);
           if size(IM,3)==1
            IM(:,:,2)=IM;
            IM(:,:,3)=IM(:,:,1);
           end
        testImages(:,:,:,pattern-ceil(DIM1))=uint8(IM);
    end
    
    %classifico test patterns
    [outclass, score{fold}] =  classify(netTransfer,testImages);
    
    %calcolo accuracy
    [a,b]=max(score{fold}');
    ACC(fold)=sum(b==yy)./length(yy);
    save accuracy.mat ACC
end
    