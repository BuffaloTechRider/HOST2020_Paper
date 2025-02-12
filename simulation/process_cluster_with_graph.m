%clc
close all
clear
MS = 80;
FSL = 15;
LW = 2;
noTrain = 90;
noTest = 70;
% Figure 1
load('ratio_m_test.mat')
load('ratio_m_train.mat')

trojanFreeData = squeeze(ratio_m_train);
trojanData = squeeze(ratio_m_test);

data4eig = [trojanFreeData(1:noTrain,:); trojanData(1:noTest,:)] ;
allData = [trojanFreeData; trojanData];

[a, b] = eig(data4eig' * data4eig);
bDiag = b(end-2:end, end-2:end);
bDiag_c = sqrt(diag(bDiag));
bDiag_inv = diag(1./bDiag_c);

c = a(:,end-2:end);
svaTrojen = allData * c;
ind0Size = size(trojanFreeData,1);

classes =[2 * ones(size(trojanFreeData,1),1); ones(size(trojanData,1),1)];

figure(1)
af = scatter3(svaTrojen(1 : ind0Size , 1), svaTrojen(1 : ind0Size , 2), svaTrojen(1 : ind0Size , 3), 'ko', 'SizeData', MS, 'Linewidth', LW);
hold on
scatter3(svaTrojen(ind0Size + 1 : end , 1), svaTrojen(ind0Size + 1 : end , 2), svaTrojen(ind0Size + 1 : end , 3), 'rx', 'SizeData', MS, 'Linewidth', LW)
view([33 65])
xlabel('x')
ylabel('y')
zlabel('z')
lg1 = legend('Train', 'Test');
set(lg1, 'Fontsize', FSL)
set(lg1, 'Position', [0.6592    0.4393    0.1982    0.1702])



% post process
figure(3)
if (0) % If notTrain = 1 and notTest = 2
    [idx, C] = kmeans(svaTrojen,2,'Start', [mean(data4eig(1:noTrain,:)); mean(data4eig(1 + noTrain:end,:))] * c);
    figure(3)
    scatter3(svaTrojen(idx==1,1), svaTrojen(idx==1,2), svaTrojen(idx==1,3), 'rx', 'SizeData', MS, 'Linewidth', LW)
    hold on
    scatter3(svaTrojen(idx==2,1), svaTrojen(idx==2,2), svaTrojen(idx==2,3), 'ko', 'SizeData', MS, 'Linewidth', LW)
    lg1 = legend('idx = 1', 'idx = 2');
else % if all data is used
    C_start = [ -0.0530   -0.0654   -0.0800
                -0.0919    0.1539   -0.0747
                 0.0225    0.1256   -0.0773
                -0.0033    0.0726   -0.0792
                 0.0910    0.0273   -0.0822];
             
    C_start = [ -4.992   10.41    -63.62
                 1.562    8.384   -65.45
                -0.507    4.682   -67.76
                -3.925   -4.457   -67.98
                 6.388    1.39    -69.58];
             
    [idx, C] = kmeans(svaTrojen,5,'Start', C_start);
    scatter3(svaTrojen(idx==1,1), svaTrojen(idx==1,2), svaTrojen(idx==1,3), 'rx', 'SizeData', MS, 'Linewidth', LW)
    hold on
    scatter3(svaTrojen(idx==2,1), svaTrojen(idx==2,2), svaTrojen(idx==2,3), 'ko', 'SizeData', MS, 'Linewidth', LW)
    scatter3(svaTrojen(idx==3,1), svaTrojen(idx==3,2), svaTrojen(idx==3,3), 'ys', 'SizeData', MS, 'Linewidth', LW)
    scatter3(svaTrojen(idx==4,1), svaTrojen(idx==4,2), svaTrojen(idx==4,3), 'bd', 'SizeData', MS, 'Linewidth', LW)
    scatter3(svaTrojen(idx==5,1), svaTrojen(idx==5,2), svaTrojen(idx==5,3), 'm*', 'SizeData', MS, 'Linewidth', LW)
    lg1 = legend('idx = 1', 'idx = 2', 'idx = 3', 'idx = 4', 'idx = 5');
end
view([33 65])
xlabel('x')
ylabel('y')
zlabel('z')

set(lg1, 'Fontsize', FSL)
set(lg1, 'Position', [0.6628    0.5393    0.1982    0.3238])


% Centroid distances
C_dist = [];
for ii = 1 : size(C, 1)
    C_dist =[C_dist; sqrt(sum((C - C(ii,:)).^2,2))'];
end
C_dist = eye(size(C_dist)) * 10 + C_dist;


% Create a graph based on the distances
thr = 7.8685 * 1.15; %Threshold value for path existance
validPaths = C_dist < thr ;
s = [];
t = [];

for ii = 1 : size(C, 1)
    pths = find(validPaths(ii,:));
    s = [s, ii * ones(1, length(pths))];
    t = [t, pths];
end
G = digraph(s,t);
figure(4)
h = plot(G,'Markersize',10);
set(gca,'xticklabel',[])
set(gca,'xtick',[])
set(gca,'yticklabel',[])
set(gca,'ytick',[])
nl = h.NodeLabel;
h.NodeLabel = '';
xd = get(h, 'XData');
yd = get(h, 'YData');
text(xd + 0.1, yd, nl, 'FontSize',20, 'FontWeight','bold', 'HorizontalAlignment','left', 'VerticalAlignment','middle')


cond = 0;
ii = 1;
considered_class = 1;
next_classes = zeros(1, size(C, 1));
next_classes(1) = 1;
while sum(next_classes == 0) ~= 0
    for kk = ii + 1 : size(C, 1)
        lst = shortestpath(G, ii, kk);
        if ~isempty(lst)
            next_classes(kk) = ii;
        end
    end
    considered_class = find(next_classes == 0, 1, 'first');
    ii = ii + 1;
    next_classes(considered_class) = ii;
end

idx_new = zeros(size(idx));

for ii = 1 : size(C, 1)
    idx_new(idx == ii) = next_classes(ii);
end


figure(5)
scatter3(svaTrojen(idx_new==1,1), svaTrojen(idx_new==1,2), svaTrojen(idx_new==1,3), 'rx', 'SizeData', MS, 'Linewidth', LW)
hold on
scatter3(svaTrojen(idx_new==2,1), svaTrojen(idx_new==2,2), svaTrojen(idx_new==2,3), 'ko', 'SizeData', MS, 'Linewidth', LW)
lg1 = legend('idx = 1', 'idx = 2');
view([33 65])
xlabel('x')
ylabel('y')
zlabel('z')

set(lg1, 'Fontsize', FSL)
set(lg1, 'Position', [0.6592    0.4393    0.1982    0.1702])
