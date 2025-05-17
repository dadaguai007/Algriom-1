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
PRE='DSB_Dither_Itera_Amp_';
Button_save= 'off';

Amp_NUM=300;

% 装载数据保存模块
ds=DataSaver([], [],[]);
% 装载GUI界面
% WB = OCG_WaitBar(length(Amp_NUM));

for i=length(Amp_NUM)
    % 生成数据存储位置
    Title=strcat(PRE,num2str(Amp_NUM(i)));
    ds.filePath = strcat('Output\',Title);
    ds.createFolder();
    Filename=strcat('D:\PhD\Project\单边带光发射机自适应偏压控制\Exp\ofdm_dd_ber_64G_18GBaud_20GBaud\Data\20240522_ofdm_64G_20G_SSB_BTB_dsb_',num2str(Amp_NUM(i)),'mv_8M\');
    addpath(Filename)
    load('pd_inpower.mat')
    pre='ROP-';
    % 装载GUI界面
    WB = OCG_WaitBar(length(pd_inpower));
    %for j=7:length(pd_inpower)
    for j=9
        % 对输入光功率近似，取整数值
        power = sprintf('%.1f.mat', pd_inpower(j));
        % 读取输入数据
        title=strcat(pre,power);
        load(title)
        % 数据输入
        signal_orgin = data(:,1);    % 第10个，选择3组数据

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
            50,...                   % 训练序列长度
            ofdmPHY.nModCarriers,...             % 相噪估计——导频位置
            ofdmPHY.nModCarriers,...             % 频偏估计——导频数量，一般对全体载波进行估计
            qam_signal,...            % 调制信号参考矩阵
            label,...                % 同步参考信号
            'off',...                % 默认 关闭 CPE
            'on',...                 % 频偏补偿 默认 打开
            'on',...                % 是否选取全部信号 或者 分段选取
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
        [DataGroup,Index_P,selectedPortionTotal]=Receive.Synchronization(Rxsig);
        % 训练序列
        Receive.Nr.nTrainSym =  1000;
        % 均衡解码
        [~,~,~,data_ofdm_Total] = Receive.OFDM_ExecuteDecoding(selectedPortionTotal);
        % 比特判决
        [ber,num,L]=Receive.Direcct_Cal_BER(data_ofdm_Total);

        berTotal(j)=ber;




        % 分组 处理
        % 创建变量
        Total1=0;
        Num1=0;
        Receive.Button.Display='off';
        for Idx=1:length(Index_P)
            % 序列号
            Receive.Nr.squ_num=Idx;
            % 每次都是选取一段进行处理
            Receive.Nr.k=1;
            % 训练序列进行纠正
            Receive.Nr.nTrainSym =  100;
            % 重新生成 DSP 所需的 训练矩阵
            Receive.createReferenceSignal_matrix();

            selectedPortion=Receive.selectSignal(Index_P,DataGroup);
            % 均衡解码
            [signal_ofdm_martix,data_ofdm_martix,Hf,data_ofdm] = Receive.OFDM_ExecuteDecoding(selectedPortion);
            % 比特判决
            [ber,num,L]=Receive.Direcct_Cal_BER(data_ofdm);
            Num1=Num1+num;
            Total1=Total1+L;

            Receive.Button.Remod='on';
            [~,~,~,data_ofdm1] = Receive.OFDM_ExecuteDecoding(selectedPortion);
            %             % 硬判决 为 最近的星座点
            data_qam=hard_decision_qam(nn.M,data_ofdm1);
            % 转换为矩阵形式
            data_mat=reshape(data_qam,nn.nModCarriers,[]);
    
            mat_signal{Idx}=data_mat;
            Receive.Button.Remod='off';
        end
        BER1=Num1/Total1;
        fprintf('Total Num of Errors = %d, BER = %1.7f\n',Num1,BER1);


        re_mod_signal=[];
        % 重新进行信号调制
        for ii=1:length(Index_P)
            martix=mat_signal{ii};
            % 重新调制为ofdm
            ofdm_signal= nn.ofdm(martix);
            re_mod_signal=[re_mod_signal,ofdm_signal.'];
        end



        Receive.Button.Display='on';
        % 提取光电流 ,分组KK
        Receive.Button.select_photocurrentSignal = 'on';
        % 同步
        [DataGroupPhotoCurrentSignal,Index_P_PhotoCurrentSignal,selectedPhotoCurrentSignal]=Receive.Synchronization(Rxsig);




        % 分组 处理
        % 创建变量
        resSignal=[];
        Receive.Button.Display='on';
        disp('分组KK')
        for Idx=1:length(Index_P_PhotoCurrentSignal)

            % 序列号
            Receive.Nr.squ_num=Idx;
            % 每次都是选取一段进行处理
            %             Receive.Nr.k=1;
            % 训练序列进行纠正
            %             Receive.Nr.nTrainSym =  20;
            %             % 重新生成 DSP 所需的 训练矩阵
            %             Receive.createReferenceSignal_matrix();
            % 选取电流信号
            selectedPhotoCurrentSignal_group=Receive.selectSignal(Index_P,DataGroupPhotoCurrentSignal);

            % KK算法
            [Rxsig_PhotoCurrentSignal,Dc]=Receive.Preprocessed_signal(selectedPhotoCurrentSignal_group);
            resSignal=[resSignal;Rxsig_PhotoCurrentSignal];
        end
        % 训练序列
        Receive.Nr.nTrainSym = 1000;
        % 均衡解码
        [~,~,~,data_ofdm_Total_PhotoCurrentSignal] = Receive.OFDM_ExecuteDecoding(resSignal);
        % 比特判决
        [ber1,num1,L1]=Receive.Direcct_Cal_BER(data_ofdm_Total_PhotoCurrentSignal);
        BER_ALL(j)=ber1;


        resSignal=resSignal.'-mean(resSignal);

%         selectedPortionTotal=selectedPortionTotal.'-mean(selectedPortionTotal);
        % 消除算法
        fs=64e9;
        Vdither=0.1;
        Dc1=sqrt(Dc)-0.02;
        alpha=0.18;
        pd=real(selectedPhotoCurrentSignal).';
        [recoverI,ipd_error]=iteraElimate(resSignal+Dc1,pd,fs,alpha,Dc1,Vdither);

%         fs=64e9;   % 重新调制的存在问题
%         Vdither=0.02;
%         Dc1=sqrt(Dc)-0.02;
% 
%         alpha=0.1;
%         pd=real(selectedPhotoCurrentSignal).';
%         [recoverI,ipd_error]=iteraElimate(re_mod_signal+Dc1,pd,fs,alpha,Dc1,Vdither);

        % KK算法
        [RR,~]=Receive.Preprocessed_signal(recoverI.');

        % 训练序列
        Receive.Nr.nTrainSym = 1000;
        % 均衡解码
        [~,~,~,data_ofdm_Total_PhotoCurrentSignal1] = Receive.OFDM_ExecuteDecoding(RR);
        % 比特判决
        [ber1,num1,L1]=Receive.Direcct_Cal_BER(data_ofdm_Total_PhotoCurrentSignal1);

        % 分组解码
        recoverIGroup=reshape(RR,Receive.TxPHY.len,[]);
        % 分组 处理
        % 创建变量
        Total=0;
        Num=0;
        Receive.Button.Display='off';
        for Idx=1:length(Index_P)
            % 序列号
            Receive.Nr.squ_num=Idx;
            % 每次都是选取一段进行处理
            Receive.Nr.k=1;
            % 训练序列进行纠正
            Receive.Nr.nTrainSym =  100;
            % 重新生成 DSP 所需的 训练矩阵
            Receive.createReferenceSignal_matrix();
            selectedPortion=recoverIGroup(:,Idx);
            % selectedPortion=Receive.selectSignal(Index_P,DataGroup);
            % 均衡解码
            [signal_ofdm_martix,data_ofdm_martix,Hf,data_ofdm] = Receive.OFDM_ExecuteDecoding(selectedPortion);
            % 比特判决
            [ber,num,L]=Receive.Direcct_Cal_BER(data_ofdm);
            Num=Num+num;
            Total=Total+L;
        end
        BER=Num/Total;
        fprintf('Total Num of Errors = %d, BER = %1.7f\n',Num,BER);


% 再次尝试分组KK，结果不理想
%         recoverI_group=reshape(recoverI,Receive.TxPHY.len,[]);
%         resSignal1=[];
%         disp('分组KK')
%         for Idx1=1:length(Index_P_PhotoCurrentSignal)
% 
%             % 序列号
%             Receive.Nr.squ_num=Idx1;
%             % 每次都是选取一段进行处理
%             %             Receive.Nr.k=1;
%             % 训练序列进行纠正
%             %             Receive.Nr.nTrainSym =  20;
%             %             % 重新生成 DSP 所需的 训练矩阵
%             %             Receive.createReferenceSignal_matrix();
%             % 选取电流信号
%             selectedPortion=recoverI_group(:,Receive.Nr.squ_num);
%             % KK算法
%             [Rxsig_PhotoCurrentSignal,Dc]=Receive.Preprocessed_signal(selectedPortion);
%             resSignal1=[resSignal1;Rxsig_PhotoCurrentSignal];
%         end
% 
%         % KK算法
%         %[RR,~]=Receive.Preprocessed_signal(recoverI.');
% 
%         % 训练序列
%         Receive.Nr.nTrainSym = 1000;
%         % 均衡解码
%         [~,~,~,data_ofdm_Total_PhotoCurrentSignal2] = Receive.OFDM_ExecuteDecoding(resSignal1);
%         % 比特判决
%         [ber1,num1,L1]=Receive.Direcct_Cal_BER(data_ofdm_Total_PhotoCurrentSignal2);

        WB.updata(i);


    end

    % 输入光功率
    pd_inpower=round(pd_inpower);

    % 是否进行存储
    if strcmp(Button_save,'on')
        ds.name='BER';
        ds.data=Itera_BER;
        ds.saveToMat();


        ds.name='pd_inpower';
        ds.data=pd_inpower;
        ds.saveToMat();
    end



end
WB.closeWaitBar();

% BER 绘图
berplot = BERPlot_David();
berplot.interval=2;
berplot.flagThreshold=1;
berplot.flagRedraw=1;
berplot.flagAddLegend=1;
Mat=[berTotal;BER_ALL];
% LengendArrary=["100mv",...
%     "200mv","300mv",...
%     "400mv","500mv"];
LengendArrary=["Total","w/o Algritom"];
berplot.multiplot(pd_inpower,Mat,LengendArrary);