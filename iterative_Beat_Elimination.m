function pd_current=iterative_Beat_Elimination(data,Dc,ipd,alpha,fs,Vdither)

% 计算dither
f1=40e3;
f2=60e3;
N=length(data)/(fs/f1);

phi=0;
% 创建dither信号
VbQ_sin = Vdither*Creat_dither1(fs,f2,phi,N*(f2/f1)).';
VbI_sin = Vdither*Creat_dither1(fs,f1,phi,N).';
VbI_cos = Vdither*Creat_dither(fs,f1,phi,N).';
VbQ_cos = Vdither*Creat_dither(fs,f2,phi,N*(f2/f1)).';




% 重新计算E2和E1
Rece_remove_dc=data-Dc;

% 载波与dither 拍频
E5=real(Dc)*VbI_cos+real(Dc)*VbQ_sin;
E4=real(Dc)*VbI_cos-real(Dc)*VbQ_sin;
E1=E5+E4;


%  负频率
I_beat=real(Rece_remove_dc).*VbI_cos-imag(Rece_remove_dc).*VbI_sin;
Q_beat=real(Rece_remove_dc).*VbQ_sin+imag(Rece_remove_dc).*VbQ_cos;

E2=I_beat+Q_beat;

pd_error=alpha*(E1+E2);
% pd_error=alpha*(E2);
% 消除串扰
pd_current=ipd-pd_error;


end