#!/bin/bash

#
source ./venv/bin/activate

# log
log_root='./logs'
mkdir -p ${log_root}
date=`date +%Y%m%d_%H%M`
log_file=${log_root}/${date}.log

#
SQUAD_VER=squad1
#SQUAD_VER=squad2

#
BERT_BASE_ROOT=../08_BERT_MODELS
BERT_BASE_DIR=${BERT_BASE_ROOT}/uncased_L-12_H-768_A-12


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
#OUTPUT_DIR='./output_squad2_b11'
#OUTPUT_DIR='./output_squad2_b11_e4'
#OUTPUT_DIR='./output_squad1_b11'
OUTPUT_DIR='./output_squad1_b-11_l-384_s-128'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-64'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-4'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-1'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-1'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-3'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-5'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-5-re'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-7'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-7-re'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-7-re-re'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-post-9'

#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-all-re'
#OUTPUT_DIR='./output_squad1_b-11_l-384_s-128_a-pre-1'

INIT_CHECKPOINT=$BERT_BASE_DIR/bert_model.ckpt
#INIT_CHECKPOINT=${PRE_TRAINED_DIR}/model.ckpt


#
OUTPUT_PREDICTION_FILE='predictions_test.json'
OUTPUT_NBEST_FILE='nbest_predictions_test.json'
OUTPUT_NULL_LOG_ODDS='null_odds_test.json'

#
THRESH=-3.414

#
APPEND_MODE='None'
#APPEND_MODE='PRE'
#APPEND_MODE='POST'
#APPEND_MODE='ALL'

#
NUM_APP_PARA=9
#NUM_APP_PARA=7

#
VERBOSE=True
#VERBOSE=False

#
#NUM_EVAL_EXAMPLES=-1
NUM_EVAL_EXAMPLES=100

#
MAX_SEQ_LEN=384
STRIDE=128

#
if ! [ ${APPEND_MODE} = 'None' ]
then
    log_file=${log_root}/${date}_a-${APPEND_MODE}-${NUM_APP_PARA}_l-${MAX_SEQ_LEN}_s-${STRIDE}.log
fi


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
        --num_train_epochs=2.0 \
        --max_seq_length=${MAX_SEQ_LEN} \
        --doc_stride=${STRIDE} \
        --output_dir=${OUTPUT_DIR} \
        --version_2_with_negative=${VERSION_2_W_NEG} \
        --null_score_diff_threshold=${THRESH} \
        --use_tpu=False \
        --num_append_paragraphs=${NUM_APP_PARA}\
        --append_mode=${APPEND_MODE}\
        --verbose=${VERBOSE}\
        --num_eval_examples=${NUM_EVAL_EXAMPLES}\
        --predict_batch_size=1; } 2>&1 | tee ${log_file}

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


