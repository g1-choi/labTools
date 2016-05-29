%% Load some file with marker data

%load()
md=expData.data{10}.markerData;
labs={'RHIP','LHIP','LANK','RANK'};
dd=md.getOrientedData(labs);
clear allX allV

%% Get some stats:
%Model 1): static (v=0 prediction)
x=dd;
s1=size(dd,2);
s2=size(dd,3);
x_1=cat(1,zeros(1,s1,s2),x(1:end-1,:,:));
x_2=cat(1,zeros(1,s1,s2),x_1(1:end-1,:,:));
x_3=cat(1,zeros(1,s1,s2),x_2(1:end-1,:,:));
v=(x_1-x_2)/md.sampPeriod;
v_1=cat(1,zeros(1,s1,s2),v(1:end-1,:,:));
v_2=cat(1,zeros(1,s1,s2),v_1(1:end-1,:,:));
a=(v-v_1)/md.sampPeriod;
a=.5*(v-v_2)/md.sampPeriod; %more robust estimator of a

N=150;
allX{1}=nan(s1*s2,N);
allV{1}=nan(s1*s2,N);
allXm{1}=nan(s1*s2,N);
allVm{1}=nan(s1*s2,N);
for n=1:N
errx=x(n:end,:,:)-x_1(1:end-n+1,:,:);
sdx=nanstd(errx(N-n+1:end,:,:));
allX{1}(:,n)=sdx(:);
allXm{1}(:,n)=nanmean(errx(:,:));
sdv=nanstd(v(N-n+1:end,:,:));
allV{1}(:,n)=0;%sdv(:);
allVm{1}(:,n)=0;
end

%% Model 2): v=cte based on previous samples, with constant sampling rate

allX{2}=nan(s1*s2,N);
allV{2}=nan(s1*s2,N);
allXm{2}=nan(s1*s2,N);
allVm{2}=nan(s1*s2,N);
for n=1:N
errx=(x(n:end,:,:)-x_1(1:end-n+1,:,:))-v(1:end-n+1,:,:)*md.sampPeriod*n ;
%hist(errx,[-10:1:10])
sdx=nanstd(errx(N-n+1:end,:,:));
allX{2}(:,n)=sdx(:);
allXm{2}(:,n)=nanmean(errx(:,:));
errv=(v(n+1:end,:,:)-v(1:end-n,:,:))*md.sampPeriod;
%figure
%hist(errv,[-10:1:10])
sdv=nanstd(errv(N-n+1:end,:,:));
allV{2}(:,n)=sdv(:);
allVm{2}(:,n)=nanmean(errv(:,:));
end

%% Model 3: same as 2, but with temporal exponential discounting of velocity

allX{3}=nan(s1*s2,N);
allV{3}=nan(s1*s2,N);
allXm{3}=nan(s1*s2,N);
allVm{3}=nan(s1*s2,N);
tau=20;
lag=1;
for n=1:N
errx=(x(n:end,:,:)-x_1(1:end-n+1,:,:))-v(1:end-n+1,:,:)*md.sampPeriod*n *exp(-(n-lag)/tau);
%hist(errx,[-10:1:10])
sdx=nanstd(errx(N-n+1:end,:,:));
allX{3}(:,n)=sdx(:);
allXm{3}(:,n)=nanmean(errx(:,:));
errv=(v(n+1:end,:,:)-v(1:end-n,:,:)*exp(-(n-lag)/tau))*md.sampPeriod;
%figure
%hist(errv,[-10:1:10])
sdv=nanstd(errv(N-n+1:end,:,:));
allV{3}(:,n)=sdv(:);
allVm{1}(:,n)=nanmean(errv(:,:));
end

%% Model 4): a=cte based on previous samples, with constant sampling rate
%is crap
allX{4}=nan(s1*s2,N);
allV{4}=nan(s1*s2,N);
allXm{4}=nan(s1*s2,N);
allVm{4}=nan(s1*s2,N);
for n=1:N
errx=(x(n:end,:,:)-x_1(1:end-n+1,:,:))-v(1:end-n+1,:,:)*md.sampPeriod*n -.5*a(1:end-n+1,:,:)*(md.sampPeriod*n)^2;
%hist(errx,[-10:1:10])
sdx=nanstd(errx(N-n+1:end,:,:));
allX{4}(:,n)=sdx(:);
allXm{4}(:,n)=nanmean(errx(:,:));
errv=(v(n+1:end,:,:)-v(1:end-n,:,:)-a(1:end-n,:,:)*(md.sampPeriod*n))*md.sampPeriod;
%figure
%hist(errv,[-10:1:10])
sdv=nanstd(errv(N-n+1:end,:,:));
allV{4}(:,n)=sdv(:);
allVm{4}(:,n)=nanmean(errv(:,:));
end

%%
close all
clear p
figure;
for j=1:3
    for k=1:3%length(allX)
        switch k
            case 1
                cc=[1 0 0];
            case 2
                cc=[0 1 0];
            case 3
                cc=[0 0 1];
            case 4
                cc=.7*ones(1,3);
        end
            
        subplot(3,2,j*2-1)
        hold on
            switch j
                case 1
                    title('X estim')
                case 2
                    title('Y estim')
                case 3
                    title('Z estim')
            end
        %set(gca,'YScale','log')
        set(gca,'XLim',[0 40])
        auxX=bsxfun(@rdivide,allX{k}(j:3:end,:).^2,1:N);
        auxV=allV{k}(j:3:end,:).^2;
        auxXm=allXm{k}(j:3:end,:);
        auxVm=allVm{k}(j:3:end,:);
        auxL=md.labels(j:3:end);
        plot(1:N,nanmean(auxX,1),'.','Color',cc)
        %plot(1:N,nanmean(abs(auxXm),1),'o','Color',cc)
        %plot(1:N,auxX,'Color',cc)
        for i=1:size(auxX,1)
            text(N,auxX(i,end),labs(i),'Color',cc)
        end
        ylabel(['\sigma ^2 /N (mm^2/sample)'])
        grid on
        subplot(3,2,j*2)
        hold on
        switch j
            case 1
                title('vX estim')
            case 2
                title('vY estim')
            case 3
                title('vZ estim')
        end
        %set(gca,'YScale','log')
        set(gca,'XLim',[0 40])
        p(k)=plot(1:N,nanmean(auxV,1),'x','Color',cc);
        %plot(1:N,nanmean(abs(auxVm),1),'*','Color',cc)
        %plot(1:N,auxV,'Color',cc)
        for i=1:size(auxX,1)
            text(N,auxV(i,end),['v' labs{i}],'Color',cc)
        end
        ylabel(['\sigma^2 (mm^2/sample)'])
        grid on
    end
end
legend(p,'Constant model (v=0)','Linear dynamics (v=cte)',['v(T) discount , \tau=' num2str(tau) ', lag=' num2str(lag)],'a=cte')