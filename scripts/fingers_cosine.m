h = 40;
w = 100;
nMatching     = 3; % number of matching pairs for each image
nNonMatching  = 3; % number of non matching pairs for each image
patchSz       = [20 25];
overlap       = [10 12];

%% load initial data

% fill a dataset object with fields 
% train_x : training samples pairs, nbsamples x (2*h*w) matrix
% train_y : associated label
% test_x  : same as train_x for testing
% test_y  : same as train_y for testing
% h       : height of the images
% w       : width of the images

load('data/hk_Qin_preprocessing/dataset.mat');

%% Extraction layers

RBMtrainOpts = struct('lRate', 100, ...
                      'decayNorm', 2, ...
                      'decayRate', 1e-10);

extractionNet = MultiLayerNet(struct('skipBelow', 1));

patchMaker = PatchNet([h, w], patchSz, overlap);
extractionNet.add(patchMaker);

patchRedux = MultiLayerNet(struct());

RBMpretrainingOpts = struct( ...
    'lRate', 0.05, ...
    'momentum', 0.9, ...
    'nEpochs', 150, ...
    'batchSz', 300, ...
    'dropoutVis', 0.4, ...
    'wPenalty', 0.005, ...
    'wDecayDelay', 0, ...
    'selectivity', 0.1, ...
    'selectivityGain', 0.5, ...
    'sparsity', 0.05, ...
    'sparseGain', 0.1, ...
    'displayEvery', 5);
rbm = RBM(prod(patchSz), 200, RBMpretrainingOpts, RBMtrainOpts);
patchRedux.add(rbm);
RBMpretrainingOpts = struct( ...
    'lRate', 0.05, ...
    'momentum', 0.9, ...
    'nEpochs', 180, ...
    'batchSz', 300, ...
    'dropoutVis', 0.2, ...
    'wPenalty', 0.01, ...
    'wDecayDelay', 10, ...
    'sparsity', 0.05, ...
    'sparseGain', 0.1, ...
    'displayEvery', 5);
rbm = RBM(200, 100, RBMpretrainingOpts, RBMtrainOpts);
patchRedux.add(rbm);
rbm = RBM(100, 50, RBMpretrainingOpts, RBMtrainOpts);
patchRedux.add(rbm);

imRedux = SiameseNet(patchRedux, numel(patchMaker.outsize()));
extractionNet.add(imRedux);

patchMerge = ReshapeNet(imRedux, sum(cellfun(@prod, imRedux.outsize())));
extractionNet.add(patchMerge);

extractionNet.pretrain(dataset.pretrain_x);

save('data/workspaces/pretrained.mat', 'extractionNet');

%% Comparison layers

trainOpts = struct('nIter', 150, ...
                   'batchSz', 300, ...
                   'displayEvery', 5);

wholeNet   = MultiLayerNet(trainOpts);

% Duplicate extraction network
compareNet = SiameseNet(extractionNet, 2, 'skipPretrain');
wholeNet.add(compareNet);

cosine = CosineCompare(50);
wholeNet.add(cosine);

%% Training
% wholeNet.pretrain(dataset.train_x);
wholeNet.train(dataset.train_x, dataset.train_y');

o = wholeNet.compute(dataset.test_x);
m = o > 0.42 ~= dataset.test_y';
mean(m(dataset.test_y))
mean(m(~dataset.test_y))
o = wholeNet.compute(dataset.train_x);
m = o > .42 ~= dataset.train_y';
mean(m(dataset.train_y))
mean(m(~dataset.train_y))

%% Testing

% Xa = wholeNet.compute(dataset.train_x);
% Xt = wholeNet.compute(dataset.test_x);
% 
% SVMModel = fitcsvm(Xa',dataset.train_y,'KernelFunction','rbf', 'OutlierFraction',0.05);
% y = predict(SVMModel,Xa');
% m = y ~= dataset.train_y;
% fprintf(1, 'Training fpr : %f\n', mean(m(~dataset.train_y)));
% fprintf(1, '         frr : %f\n', mean(m(dataset.train_y)));
% y = predict(SVMModel,Xt');
% m = y ~= dataset.test_y;
% fprintf(1, 'Testing  fpr : %f\n', mean(m(~dataset.test_y)));
% fprintf(1, '         frr : %f\n', mean(m(dataset.test_y)));