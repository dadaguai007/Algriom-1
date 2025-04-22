clear;clc;close all;

current_date = date;
disp(current_date);

% 加入文件路径
addpath('D:\PhD\Project\Base_Code\Base\')
% addpath('D:\BIT_PhD\Base_Code\Codebase_using\')
addpath('DSP\')
addpath('Fncs\')
addpath("Plot\")
addpath("GUI\")


% 信号生成
OFDM_generation;

% 存储数据的位置信息
PRE='SSFM_CSPR_';

CSPR_NUM=10;
% 装载数据保存模块
ds=DataSaver([], [],[]);
% 装载GUI界面
WB = OCG_WaitBar(length(CSPR_NUM));


for i=length(CSPR_NUM)
    % 生成数据存储位置
    Title=strcat(PRE,num2str(CSPR_NUM(i)));
    ds.filePath = strcat('Output\',Title);
    ds.createFolder();
    % 加入数据文件位置
    Filename=strcat('D:\PhD\Project\单边带光发射机自适应偏压控制\Exp\ofdm_dd_ber_64G_18GBaud_20GBaud\Data\20240522_ofdm_64G_20G_SSB_BTB_ssfm_',num2str(CSPR_NUM(i)),'dBm\');
    addpath(Filename)
    load('pd_inpower.mat')
    pre='ROP-';
    for j=1:length(pd_inpower)
        % 对输入光功率近似，取整数值
        power = sprintf('%.1f.mat', pd_inpower(j));
        % 读取输入数据
        title=strcat(pre,power);
        load(title)
        % 数据输入
        signal_orgin = data(:,2);

        % 发射机参数
        ofdmPHY=nn;

        % 接收机参数
        Receive=DataProcessor( ...
            ofdmPHY,...              % 发射机参数
            80e9,...                 % 接收信号的采样率
            64e9,...                 % 接收信号的波特率
            2*80e9,...               % KK恢复算法的采样率
            [],...                   % 接收的光电流信号
            1,...                    % 选取第 x 段信号
            50,...                   %  训练序列长度
            ofdmPHY.nModCarriers,...             % 相噪估计——导频位置
            ofdmPHY.nModCarriers,...             % 频偏估计——导频数量，一般对全体载波进行估计
            qam_signal,...            % 调制信号参考矩阵
            label,...                % 同步参考信号
            'off',...                % 默认 关闭 CPE
            'on',...                 % 频偏补偿 默认 打开
            'off',...                % 是否选取全部信号 或者 分段选取
            'off');                  % 是否选择光电流信号进行处理


        % 创建参考解码序列
        Receive.createReferenceSignal();
        % 预先均衡
        filteredData = Receive.preFilter(signal_orgin, 22e9);
        % 装载光电流信号
        Receive.signalPHY.photocurrentSignal =filteredData;
        % KK算法
        [Rxsig,Dc]=Receive.Preprocessed_signal(filteredData);
        % 同步
        [DataGroup,Index_P,selectedPortion]=Receive.Synchronization(Rxsig);

        % 创建变量
        Total=0;
        Num=0;
        for Idx=1:length(Index_P)
            % 序列号
            Receive.Nr.squ_num=Idx;
            selectedPortion=Receive.selectSignal(Index_P,DataGroup);
            % 均衡解码
            [signal_ofdm_martix,data_ofdm_martix,Hf,data_ofdm] = Receive.OFDM_ExecuteDecoding(selectedPortion);
            % 比特判决
            [ber,num,L]=Receive.Direcct_Cal_BER(data_ofdm);
            Num=Num+num;
            Total=Total+L;
        end
        BER=Num/Total;
        fprintf('Total Num of Errors = %d, BER = %1.7f\n',Num,BER);
        BER_ALL(j)=BER;

    end


    ds.name='BER';
    ds.data=BER_ALL;
    ds.saveToMat();

    % 输入光功率
    pd_inpower=round(pd_inpower);
    ds.name='pd_inpower';
    ds.data=pd_inpower;
    ds.saveToMat();

    BER_mat(i,:)=BER_ALL;

    WB.updata(i);
end
WB.closeWaitBar();

% BER 绘图
berplot = BERPlot_David();
berplot.interval=2;
berplot.flagThreshold=1;
berplot.flagRedraw=1;
berplot.flagAddLegend=1;
berplot.orderInterpolation=2;
% LengendArrary=["100mv",...
%     "200mv","300mv",...
%     "400mv","500mv"];
berplot.plot(pd_inpower,BER_mat);