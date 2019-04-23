#!/bin/bash

# log
log_root='./logs'
mkdir -p ${log_root}
date=`date +%Y%m%d_%H%M`
log_file=${log_root}/${date}.log


#
#SQUAD_VER=squad1
SQUAD_VER=squad2

#
BERT_BASE_DIR=./models/uncased_L-12_H-768_A-12

#
EN_TRAIN=False
#EN_TRAIN=True

#
ONLY_EVAL=False
#ONLY_EVAL=True

#
EN_EVAL=True
#EN_EVAL=False

#
if [ ${SQUAD_VER} = 'squad1' ]
then
    echo 'SQuAD1'
    SQUAD_DIR=./SQuAD1
    TRAIN_FILE=${SQUAD_DIR}/train-v1.1.json
    PREDICT_FILE=${SQUAD_DIR}/dev-v1.1.json
    VERSION_2_W_NEG=False
else
    echo 'SQuAD2'
    SQUAD_DIR=./SQuAD2
    TRAIN_FILE=${SQUAD_DIR}/train-v2.0.json
    PREDICT_FILE=${SQUAD_DIR}/dev-v2.0.json
    VERSION_2_W_NEG=True
fi

#PRE_TRAINED_DIR='./output_squad2_train_b11'
OUTPUT_DIR='./output_squad2_b11'
#OUTPUT_DIR='./output_squad2_b11_e4'

INIT_CHECKPOINT=$BERT_BASE_DIR/bert_model.ckpt
#INIT_CHECKPOINT=${PRE_TRAINED_DIR}/model.ckpt


#
OUTPUT_PREDICTION_FILE='predictions_test.json'
OUTPUT_NBEST_FILE='nbest_predictions_test.json'
OUTPUT_NULL_LOG_ODDS='null_odds_test.json'

#
MAX_NUM_APP_PARA=50
#NUM_APP_PARA=6

#
APPEND_MODE='PRE'
#APPEND_MODE='POST'

THRESH=-3.414

#
#VERBOSE=True
VERBOSE=False


#
NUM_EVAL_EXAMPLES=-1
#NUM_EVAL_EXAMPLES=10


for((i=0;i<=${MAX_NUM_APP_PARA};i++)) do
    echo 'inference'
    echo 'append paragraphs: '${i}'_'${APPEND_MODE}
    log_file=${log_root}/'append_para'
    log_file=${log_file}_${i}_${APPEND_MODE}'.log'

    OUTPUT_PREDICTION_FILE='predictions_app_para_'${i}'.json'
    OUTPUT_NBEST_FILE='nbest_predictions_app_para_'${i}'.json'
    OUTPUT_NULL_LOG_ODDS='null_odds_test_'${i}'.json'

    NUM_APP_PARA=${i}


if [ ${ONLY_EVAL} = False ]
then
    { time python -u run_squad.py \
        --vocab_file=$BERT_BASE_DIR/vocab.txt \
        --bert_config_file=$BERT_BASE_DIR/bert_config.json \
        --init_checkpoint=${INIT_CHECKPOINT} \
        --do_train=${EN_TRAIN} \
        --do_predict=True \
        --train_file=${TRAIN_FILE} \
        --predict_file=${PREDICT_FILE} \
        --output_prediction_file=${OUTPUT_PREDICTION_FILE} \
        --output_nbest_file=${OUTPUT_NBEST_FILE} \
        --output_null_log_odds=${OUTPUT_NULL_LOG_ODDS} \
        --predict_file=${PREDICT_FILE} \
        --train_batch_size=11 \
        --learning_rate=3e-5 \
        --num_train_epochs=4.0 \
        --max_seq_length=384 \
        --doc_stride=128 \
        --output_dir=${OUTPUT_DIR} \
        --version_2_with_negative=${VERSION_2_W_NEG} \
        --null_score_diff_threshold=${THRESH} \
        --use_tpu=False \
        --num_append_paragraphs=${NUM_APP_PARA}\
        --append_mode=${APPEND_MODE}\
        --verbose=${VERBOSE}\
        --num_eval_examples=${NUM_EVAL_EXAMPLES}\
        --predict_batch_size=8; } 2>&1 | tee ${log_file}

    echo 'log_file: '${log_file}
fi


if [ ${EN_EVAL} = True ]
then
    echo 'evaluation'

    if [ ${SQUAD_VER} = squad1 ]
    then
        python -u ${SQUAD_DIR}/evaluate-v1.1.py ${SQUAD_DIR}/dev-v1.1.json ${OUTPUT_DIR}/${OUTPUT_PREDICTION_FILE} | tee -a ${log_file}
    else
        python -u ${SQUAD_DIR}/evaluate-v2.0.py ${SQUAD_DIR}/dev-v2.0.json ${OUTPUT_DIR}/${OUTPUT_PREDICTION_FILE} --na-prob-file ${OUTPUT_DIR}/${OUTPUT_NULL_LOG_ODDS} --na-prob-thresh ${THRESH} | tee -a ${log_file}
    fi
fi


done
