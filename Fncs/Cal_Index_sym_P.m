function Index_sym_P=Cal_Index_sym_P(x1,x2,T,P)
X=x1+x2;
Index_sym_P=zeros(X+1,1);
Index_P=zeros(x1,1);
for idx=1:x1
Index_P(idx)=P(1)-T*idx;
end
Index_P=flip(Index_P);

Index_sym_P(1:x1)=Index_P;
Index_sym_P(x1+1)=P(1);
for idx=1:x2
Index_sym_P(idx+x1+1)=P(1)+T*idx;
end


end