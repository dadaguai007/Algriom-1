function pd_current=iterative_Beat_Elimination(data,Dc,ipd,alpha,fs)

% 计算dither
fI=40e3;
fQ=60e3;

N=length(data);
VbI = Creat_dither(fs,fI,N);
VbQ = Creat_dither(fs,fQ,N*(fQ/fI));



dd=real(Dc);
% 重新计算E2和E1
Rece_remove_dc=data-dd;

% 载波与dither 拍频
E5=real(dd)*VbI+real(dd)*VbQ_sin;
E4=real(dd)*VbI-real(dd)*VbQ_sin;
E1=E5+E4;


%  负频率
I_beat=real(Rece_remove_dc).*VbI-imag(Rece_remove_dc).*VbI_sin;
Q_beat=real(Rece_remove_dc).*VbQ_sin+imag(Rece_remove_dc).*VbQ;

E2=I_beat+Q_beat;

pd_error=alpha*(E1+E2);

% 消除串扰
pd_current=ipd-pd_error;


end