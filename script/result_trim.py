import pandas as pd
import os
import sys

log_root='../logs'
output_root='../output_squad2_b11'

num_append=[]

best_exact=[]
best_f1=[]
HasAns_exact=[]
HasAns_f1=[]
NoAns_exact=[]
NoAns_f1=[]
HasAns_total=[]
NoAns_total=[]
num_examples=[]
num_features=[]

exe_time=[]


append_mode='PRE'
#append_mode='POST'

if len(sys.argv)==2:
    max_append=int(sys.argv[1])
else:
    max_append=51

for i_append in range(max_append):

    log_name='append_para_'+str(i_append)+'_'+append_mode+'.log'
    log_file=os.path.join(log_root,log_name)
    f=open(log_file)
    lines=f.readlines()
    f.close()

    num_append.append(int(i_append))

    for line in lines:
        if 'best_exact' in line and not 'best_exact_thresh' in line:
            best_exact.append(float(line[:-2].split(':')[1]))

        if 'best_f1' in line and not 'best_f1_thresh' in line:
            best_f1.append(float(line[:-2].split(':')[1]))

        if 'HasAns_exact' in line:
            HasAns_exact.append(float(line[:-2].split(':')[1]))

        if 'HasAns_f1' in line:
            HasAns_f1.append(float(line[:-2].split(':')[1]))

        if 'NoAns_exact' in line:
            NoAns_exact.append(float(line[:-2].split(':')[1]))

        if 'NoAns_f1' in line:
            NoAns_f1.append(float(line[:-2].split(':')[1]))

        if 'HasAns_total' in line:
            HasAns_total.append(float(line[:-2].split(':')[1]))

        if 'NoAns_total' in line:
            NoAns_total.append(float(line[:-2].split(':')[1]))

        if 'num_examples' in line:
            num_examples.append(int(line[:-1].split(':')[1]))

        if 'num_features' in line:
            num_features.append(int(line[:-1].split(':')[1]))

        if 'real' in line:
            m=int(line[:-1].split('\t')[1].split('m')[0])
            s=float(line[:-1].split('\t')[1].split('m')[1].split('s')[0])

            exe_time.append(60.0*m+s)


col_title=['num_append','exact','f1','HasAns_exact','HasAns_f1','NoAns_exact','NoAns_f1','HasAns_total','NoAns_total','num_examples','num_features','exe_time']

df=pd.DataFrame({\
        'num_append': num_append,\
        'exact': best_exact,\
        'f1': best_f1,\
        'HasAns_exact': HasAns_exact,\
        'HasAns_f1': HasAns_f1,\
        'NoAns_exact': NoAns_exact,\
        'NoAns_f1': NoAns_f1,\
        'HasAns_total': HasAns_total,\
        'NoAns_total': NoAns_total,\
        'num_examples': num_examples,\
        'num_features': num_features,\
        'exe_time': exe_time})

df=df.reindex(columns=col_title)

#df.set_index('num_append', inplace=True)

print(df)

f_name_excel=os.path.join(output_root,'result_app_para_'+append_mode+'.xlsx')
df.to_excel(f_name_excel)

print('result excel file: %s'%(f_name_excel))
