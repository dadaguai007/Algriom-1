clear;clc;
OFDM_generation;
PRE='SSFM_SSB_10dBm_Dither_Amp_';
Amp_NUM=[100,200,300,400,500];
for I=1:length(Amp_NUM)

    Title=strcat(PRE,num2str(Amp_NUM(I)));

    datapath = strcat('Ber\',Title);
    if ~exist(datapath,'dir')
        mkdir(datapath);
    end
    Filename=strcat('D:\PhD\Project\单边带光发射机自适应偏压控制\Exp\ofdm_dd_ber_64G_18GBaud_20GBaud\Data\20240523_ofdm_64G_20G_SSB_BTB_ssb_ssfm_ssb_',num2str(Amp_NUM(I)),'mv_10dBm\');
    addpath(Filename)
    load('pd_inpower.mat')
    pre='ROP-';
    for WW=1:length(pd_inpower)
        power = sprintf('%.1f.mat', pd_inpower(WW));
        title=strcat(pre,power);
        load(title)
        fs = 80e9; % sampling rate
        fb = 64e9;

        signal_dsb = data(:,1);
        c_vec=0;

        signal_orgin=signal_dsb;
        signal_orgin = LPF(signal_orgin,fs,22e9);
        rxsig = real(signal_orgin(1:2*floor(length(signal_orgin)/2)));

        % 误码率计算参数
        Total=0;
        Num=0;
        for i=1:length(c_vec)
            c=c_vec(i);

            fs_up=fs*2;
            Rxsig = KK_New(rxsig+c,fs,fs_up);

            [DeWaveform,P,OptSampPhase,MaxCorrIndex] = Quick_Syn_Vec(Rxsig,label,1/fs_up,1/fb);
            x=1;
            x1=floor(P(1)/(nn.nPkts*1056));
            x2=floor((length(DeWaveform)-P(1))/(nn.nPkts*1056));
            Index_P=Cal_Index_sym_P(x1,x2,nn.nPkts*1056,P);

            for Idx=1:length(Index_P)
                if Index_P(Idx)+nn.nPkts*1056*x-1>length(DeWaveform)
                    break;

                else
                    Data = DeWaveform(Index_P(Idx):Index_P(Idx)+nn.nPkts*1056-1);
                end

                P_EST='none';
                pow='none';
                Sym_EST='symbol_est';
                f_EST='fre_est';
                nTrainSym =50;
                W=nn.nModCarriers;
                nTrainCarrier=nn.nModCarriers;
                Decode;
                EVM_Mea;
                Num=Num+num;
                Total=Total+a;
            end
            BER=Num/Total;
            fprintf('Total Num of Errors = %d, BER = %1.7f\n',Num,BER);
        end
        BER_ALL(WW)=BER;
    end

    semilogy(pd_inpower,BER_ALL,'LineWidth',2)
    hold on;
    save(sprintf('%s\\BER.mat',datapath),'BER_ALL');
    pd_inpower=floor(pd_inpower);
    save(sprintf('%s\\power.mat',datapath),'pd_inpower');
end