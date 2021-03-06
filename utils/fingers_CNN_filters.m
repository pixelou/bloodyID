colormap gray; 
for i=1:net.nets{1}.net.nets{1}.nFilters
    subplot(2, 1, 1)
    imagesc(net.nets{1}.net.nets{1}.filters(:,:, i));
    axis image
    colorbar;
    subplot(2, 1, 2)
    imagesc(filters(:,:, i));
    axis image
    colorbar;
    pause;
end

y = wholeNet.nets{1}.compute(allX);

for i = 1:150
    hist([y{1}(i,:) y{2}(i,:)], 30);
    pause;
end

colormap gray;
o = net.compute(allX);
eer = fminsearch(@(t) abs(mean(o(allY == 0) < t) ...
    - mean(o(allY > 0) >= t)), double(mean(o)));
m = (o > eer) ~= (allY > 0);

for posErr = find(m & (allY > 0))
   subplot(2, 2, 1);
   imagesc(allX{1}(:,:,posErr));
   axis image;
   subplot(2, 2, 2);
   bar(net.nets{1}.net.compute(allX{1}(:,:,posErr)));
   subplot(2, 2, 3);
   imagesc(allX{2}(:,:,posErr));
   axis image;
   subplot(2, 2, 4);
   bar(net.nets{1}.net.compute(allX{2}(:,:,posErr)));
   fprintf('%e < %e\n', o(posErr), eer);
   pause
end

for negErr = find(m & (allY == 0))
   subplot(2, 2, 1);
   imagesc(allX{1}(:,:,negErr));
   axis image;
   subplot(2, 2, 2);
   bar(net.nets{1}.net.compute(allX{1}(:,:,negErr)));
   subplot(2, 2, 3);
   imagesc(allX{2}(:,:,negErr));
   axis image;
   subplot(2, 2, 4);
   bar(net.nets{1}.net.compute(allX{2}(:,:,negErr)));
   fprintf('%e > %e\n', o(negErr), eer);
   pause
end

[allX, allY] = trainOpts.batchFn(X, Y, inf, []);
o = wholeNet.compute(allX);
eer = fminsearch(@(t) abs(mean(o(allY == 0)<t) - mean(o(allY > 0)>=t)), double(mean(o)));
subplot(1,2,1)
hold off
histogram(o(allY > 0), 'binWidth', 0.005);
hold on
histogram(o(allY == 0), 'binWidth', 0.005);
plot(eer, 0, 'r*')
hold off

[allX, allY] = trainOpts.batchFn(Xv, Yv, inf, []);
o = wholeNet.compute(allX);
subplot(1,2,2)
hold off
histogram(o(allY > 0), 'binWidth', 0.005);
hold on
histogram(o(allY == 0), 'binWidth', 0.005);
plot(eer, 0, 'r*')
hold off