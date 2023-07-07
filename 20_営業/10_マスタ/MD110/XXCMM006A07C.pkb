CREATE OR REPLACE PACKAGE BODY APPS.XXCMM006A07C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCMM006A07C
 * Description     : �l���X�g�̒lIF���o
 * MD.050          : T_MD050_CMM_006_A07_�l���X�g�̒lIF���o_EBS�R���J�����g
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  init                ���������i�p�����[�^�`�F�b�N�E�v���t�@�C���擾�j(A-1)
 *  data_outbound_proc1 AFF�l�̒��o�E�t�@�C���o�͏���                   (A-2)
 *  data_outbound_proc2 AFF�K�w�̒��o�E�t�@�C���o�͏���                 (A-3)
 *  data_outbound_proc3 AFF�֘A�l�̒��o�E�t�@�C���o�͏���               (A-4)
 *  upd_oic_ctrl_tbl    �Ǘ��e�[�u���o�^�E�X�V����                      (A-5)
 *  submain             ���C�������v���V�[�W��
 *  main                �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2022-12-07    1.0   T.Okuyama     ����쐬
 ************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_slash     CONSTANT VARCHAR2(3) := '/';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی����i�����j
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --*** ���b�N(�r�W�[)�G���[��O ***
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt,         -54);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCMM006A07C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmm     CONSTANT VARCHAR2(5)   := 'XXCMM';        -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_cfo     CONSTANT VARCHAR2(5)   := 'XXCFO';        -- �A�h�I���F��v�E�A�h�I���̈�̃A�v���P�[�V�����Z�k��
  cv_msg_kbn_coi     CONSTANT VARCHAR2(5)   := 'XXCOI';        -- �A�h�I���F�̕��E�݌ɗ̈�̃A�v���P�[�V�����Z�k��
--
  -- ��v�t���b�N�X�E�Z�O�����g
  cv_aff_cmp         CONSTANT VARCHAR2(20) := 'XX03_COMPANY';        -- ���
  cv_aff_dpt         CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT';     -- ����
  cv_aff_acc         CONSTANT VARCHAR2(20) := 'XX03_ACCOUNT';        -- ����Ȗ�
  cv_aff_sub         CONSTANT VARCHAR2(20) := 'XX03_SUB_ACCOUNT';    -- �⏕�Ȗ�
  cv_aff_btp         CONSTANT VARCHAR2(20) := 'XX03_BUSINESS_TYPE';  -- ��ƃR�[�h
  cv_aff_pat         CONSTANT VARCHAR2(20) := 'XX03_PARTNER';        -- �ڋq�R�[�h
  cv_aff_dpt_t       CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT_T';   -- ����T
--
  -- �t�@�C�����ʔԍ�
  cv_fno_cmp         CONSTANT VARCHAR2(3) := '_01';                  -- ���
  cv_fno_dpt         CONSTANT VARCHAR2(3) := '_02';                  -- ����
  cv_fno_acc         CONSTANT VARCHAR2(3) := '_03';                  -- ����Ȗ�
  cv_fno_sub         CONSTANT VARCHAR2(3) := '_04';                  -- �⏕�Ȗ�
  cv_fno_btp         CONSTANT VARCHAR2(3) := '_05';                  -- ��ƃR�[�h
  cv_fno_pat         CONSTANT VARCHAR2(3) := '_06';                  -- �ڋq�R�[�h
  cv_2nd_nm          CONSTANT VARCHAR2(4) :=  '.csv';                -- �t�@�C���g���q
--
  -- ���b�Z�[�W�ԍ�
  cv_msg_coi1_00029  CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';    -- �f�B���N�g���p�X�擾�G���[
--
  cv_msg_cmm1_00002  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cmm1_00008  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00008';    -- ���b�N�G���[���b�Z�[�W
  cv_msg_cmm1_00054  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00054';    -- �}���G���[���b�Z�[�W
  cv_msg_cmm1_00055  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00055';    -- �X�V�G���[���b�Z�[�W
  cv_msg_cmm1_00487  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00487';    -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cmm1_00488  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00488';    -- �t�@�C���������݃G���[���b�Z�[�W
--
  cv_msg_cmm1_60001  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60001';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_cmm1_60002  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60002';    -- �l�Z�b�g���Y���Ȃ��G���[���b�Z�[�W
  cv_msg_cmm1_60003  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60003';    -- IF�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cmm1_60004  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60004';    -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cmm1_60005  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60005';    -- ���������o�̓��b�Z�[�W
  cv_msg_cmm1_60006  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60006';    -- �����ΏہE�������b�Z�[�W
  cv_msg_cmm1_60007  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60007';    -- �t�@�C���o�͑ΏہE�������b�Z�[�W
  cv_msg_cmm1_60008  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60008';    -- OIC�A�g�����Ǘ��e�[�u��
  cv_msg_cmm1_60009  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60009';    -- �l�Z�b�g�̒l
  cv_msg_cmm1_60010  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60010';    -- AFF�K�w�i����j
  cv_msg_cmm1_60011  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60011';    -- AFF�K�w�i����Ȗځj
  cv_msg_cmm1_60012  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60012';    -- AFF�֘A�l
  cv_msg_cmm1_60043  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60043';    -- �p�����[�^���i�l�Z�b�g���j
  cv_msg_cmm1_60048  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-60048';    -- �p�����[�^�K�{�G���[���b�Z�[�W
--
  cv_msg1            CONSTANT VARCHAR2(2)  := '1.';                  -- ���b�Z�[�WNo.
  cv_msg2            CONSTANT VARCHAR2(2)  := '2.';                  -- ���b�Z�[�WNo.
  cv_msg3            CONSTANT VARCHAR2(2)  := '3.';                  -- ���b�Z�[�WNo.
  cv_msg4            CONSTANT VARCHAR2(2)  := '4.';                  -- ���b�Z�[�WNo.
  cv_msg5            CONSTANT VARCHAR2(2)  := '5.';                  -- ���b�Z�[�WNo.
--
  -- �g�[�N��
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';          -- �p�����[�^��
  cv_tkn_param_val   CONSTANT VARCHAR2(20) := 'PARAM_VAL';           -- �p�����[�^�l
  cv_tkn_ng_profile  CONSTANT VARCHAR2(20) := 'NG_PROFILE';          -- �v���t�@�C����
  cv_tkn_dir_tok     CONSTANT VARCHAR2(20) := 'DIR_TOK';             -- �f�B���N�g����
  cv_tkn_file_name   CONSTANT VARCHAR2(20) := 'FILE_NAME';           -- �t�@�C����
  cv_tkn_ng_table    CONSTANT VARCHAR2(20) := 'NG_TABLE';            -- �e�[�u����
  cv_tkn_date1       CONSTANT VARCHAR2(20) := 'DATE1';               -- �O�񏈗������iYYYY/MM/DD HH24:MI:SS�j
  cv_tkn_date2       CONSTANT VARCHAR2(20) := 'DATE2';               -- ���񏈗������iYYYY/MM/DD HH24:MI:SS�j
  cv_tkn_target      CONSTANT VARCHAR2(20) := 'TARGET';              -- �����ΏہA�܂��̓t�@�C���o�͑Ώ�
  cv_tkn_count       CONSTANT VARCHAR2(20) := 'COUNT';               -- ����
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE';               -- �e�[�u����
  cv_tkn_err_msg     CONSTANT VARCHAR2(20) := 'ERR_MSG';             -- SQLERRM
  cv_tkn_sqlerrm     CONSTANT VARCHAR2(20) := 'SQLERRM';             -- SQLERRM
--
  -- �v���t�@�C��
  cv_data_filedir    CONSTANT VARCHAR2(60) := 'XXCMM1_OIC_OUT_FILE_DIR';        -- XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  cv_data_filename1  CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_AFF_OUT_FILE_FIL'; -- XXCMM:AFF�l�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_data_filename2  CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_HIE_OUT_FILE_FIL'; -- XXCMM:AFF�K�w�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_data_filename3  CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_REL_OUT_FILE_FIL'; -- XXCMM:AFF�֘A�l�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_tv_start_date   CONSTANT VARCHAR2(60) := 'XXCMM1_006A07_TV_START_DATE';    -- XXCMM:�c���[�o�[�W�����J�n���iOIC�A�g�j
--
  -- ����������
  cv_proc_date_fm    CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_ymd        CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';
  cv_comma_edit      CONSTANT VARCHAR2(30) := 'FM999,999,999';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_target1_cnt          NUMBER := 0;                                          -- AFF�l�A�g�Ώی���
  gn_target2_dpt_cnt      NUMBER := 0;                                          -- AFF�K�w�i����j�A�g�Ώی���
  gn_target2_acc_cnt      NUMBER := 0;                                          -- AFF�K�w�i����Ȗځj�A�g�Ώی���
  gn_target3_cnt          NUMBER := 0;                                          -- AFF�֘A�l�A�g�Ώی���
  gv_data_filedir         VARCHAR2(100);                                        -- XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  gv_data_filename1       VARCHAR2(100);                                        -- XXCMM:AFF�l�A�g�f�[�^�t�@�C����
  gv_data_filename2       VARCHAR2(100);                                        -- XXCMM:AFF�K�w�A�g�f�[�^�t�@�C����
  gv_data_filename3       VARCHAR2(100);                                        -- XXCMM:AFF�֘A�l�A�g�f�[�^�t�@�C����
  gv_file_path            ALL_DIRECTORIES.DIRECTORY_PATH%TYPE;                  -- �t�@�C���p�X
  gd_tv_start_date        DATE;                                                 -- XXCMM:�c���[�o�[�W�����J�n���iOIC�A�g�j
  gd_process_date         DATE;                                                 -- ���񏈗�����
  gd_pre_process_date     DATE;                                                 -- �O�񏈗�����
  gv_f_value_set_name     FND_FLEX_VALUE_SETS.FLEX_VALUE_SET_NAME%TYPE;         -- �l�Z�b�g��
--
  -- �t�@�C���o�͊֘A
  gf_file_hand1           UTL_FILE.FILE_TYPE;                                   -- AFF�l�A�g�t�@�C���E�n���h��
  gf_file_hand2           UTL_FILE.FILE_TYPE;                                   -- AFF�K�w(����/����Ȗ�)�A�g�t�@�C���E�n���h��
  gf_file_hand3           UTL_FILE.FILE_TYPE;                                   -- AFF�֘A�l�A�g�t�@�C���E�n���h��
--
  cv_open_mode_w          CONSTANT VARCHAR2(1)  := 'w';                         -- �t�@�C���I�[�v�����[�h�i�㏑���j
  cn_max_linesize         CONSTANT BINARY_INTEGER := 32767;                     -- �t�@�C���s�T�C�Y
--
  -- ==============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ==============================
--
  -- (1) AFF�i��ЁA����A����ȖځA�⏕�ȖځA��ƁA�ڋq�j�̒l�𒊏o����B
  -- =============================================================================================================
  CURSOR c_outbound_data1_cur(p_flex_value_set_name IN VARCHAR2)
  IS
    SELECT /*+ LEADING(ffvs) USE_CONCAT USE_NL(ffvv.t ffvv.v) */
        ffvs.flex_value_set_name                       AS flex_value_set_name                                         -- �l�Z�b�g��
      , DECODE(ffvs.flex_value_set_name, cv_aff_sub, ffvv.parent_flex_value_low || ffvv.flex_value, ffvv.flex_value) AS flex_value -- �l
      , TO_CHAR(ffvv.start_date_active, cv_date_ymd)   AS start_date_active                                           -- �J�n��
      , TO_CHAR(ffvv.end_date_active,   cv_date_ymd)   AS end_date_active                                             -- �I����
      , ffvv.summary_flag                              AS summary_flag                                                -- �v��t���O
      , ffvv.enabled_flag                              AS enabled_flag                                                -- �L���t���O
      , DECODE(ffvs.flex_value_set_name, cv_aff_acc, SUBSTR(ffvv.compiled_value_attributes, 5, 1), null)  AS acc_type -- ����Ȗڃ^�C�v
      , SUBSTR(ffvv.compiled_value_attributes, 3, 1)   AS posting                                                     -- �]�L�̋���
      , SUBSTR(ffvv.compiled_value_attributes, 1, 1)   AS regist                                                      -- �\�Z�o�^�̋���
      , ffvv.description                               AS description                                                 -- �E�v
      , ffvv.attribute1                                AS attribute1                                                  -- �Sattribute(1�`50)
      , ffvv.attribute2                                AS attribute2
      , ffvv.attribute3                                AS attribute3
      , ffvv.attribute4                                AS attribute4
      , ffvv.attribute5                                AS attribute5
      , ffvv.attribute6                                AS attribute6
      , ffvv.attribute7                                AS attribute7
      , ffvv.attribute8                                AS attribute8
      , ffvv.attribute9                                AS attribute9
      , ffvv.attribute10                               AS attribute10
      , ffvv.attribute11                               AS attribute11
      , ffvv.attribute12                               AS attribute12
      , ffvv.attribute13                               AS attribute13
      , ffvv.attribute14                               AS attribute14
      , ffvv.attribute15                               AS attribute15
      , ffvv.attribute16                               AS attribute16
      , ffvv.attribute17                               AS attribute17
      , ffvv.attribute18                               AS attribute18
      , ffvv.attribute19                               AS attribute19
      , ffvv.attribute20                               AS attribute20
      , ffvv.attribute21                               AS attribute21
      , ffvv.attribute22                               AS attribute22
      , ffvv.attribute23                               AS attribute23
      , ffvv.attribute24                               AS attribute24
      , ffvv.attribute25                               AS attribute25
      , ffvv.attribute26                               AS attribute26
      , ffvv.attribute27                               AS attribute27
      , ffvv.attribute28                               AS attribute28
      , ffvv.attribute29                               AS attribute29
      , ffvv.attribute30                               AS attribute30
      , ffvv.attribute31                               AS attribute31
      , ffvv.attribute32                               AS attribute32
      , ffvv.attribute33                               AS attribute33
      , ffvv.attribute34                               AS attribute34
      , ffvv.attribute35                               AS attribute35
      , ffvv.attribute36                               AS attribute36
      , ffvv.attribute37                               AS attribute37
      , ffvv.attribute38                               AS attribute38
      , ffvv.attribute39                               AS attribute39
      , ffvv.attribute40                               AS attribute40
      , ffvv.attribute41                               AS attribute41
      , ffvv.attribute42                               AS attribute42
      , ffvv.attribute43                               AS attribute43
      , ffvv.attribute44                               AS attribute44
      , ffvv.attribute45                               AS attribute45
      , ffvv.attribute46                               AS attribute46
      , ffvv.attribute47                               AS attribute47
      , ffvv.attribute48                               AS attribute48
      , ffvv.attribute49                               AS attribute49
      , ffvv.attribute50                               AS attribute50
    FROM
        fnd_flex_value_sets ffvs
      , fnd_flex_values_vl  ffvv
    WHERE
        ffvs.flex_value_set_name = p_flex_value_set_name
    AND ffvs.flex_value_set_id   = ffvv.flex_value_set_id
    AND ( gd_pre_process_date is null or ffvv.last_update_date > gd_pre_process_date )
    AND SUBSTR(ffvv.flex_value, -1) != CHR(9)
    ORDER BY
      ffvv.flex_value;           -- �l
--
  -- (2)-1. AFF�i����A�܂��͊���Ȗځj�̒l�Z�b�gID�𒊏o����B
  -- =============================================================================================================
  CURSOR c_outbound_data2_id_cur(p_flex_value_set_name IN VARCHAR2)
  IS
    SELECT
      ffvs.flex_value_set_id  AS flex_value_set_id
    FROM
      fnd_flex_value_sets  ffvs
    WHERE
      ffvs.flex_value_set_name = p_flex_value_set_name
    AND EXISTS (
          SELECT
              1
          FROM
              fnd_flex_value_hierarchies  ffvh
          WHERE
              ffvs.flex_value_set_id = ffvh.flex_value_set_id
          AND ( gd_pre_process_date is null or ffvh.last_update_date > gd_pre_process_date )
        );
--
  --(2)-2. AFF�i����A����Ȗځj�K�w�̒l�Z�b�gID���A�g�f�[�^�𒊏o����B
  -- =============================================================================================================
  CURSOR c_outbound_data2_cur( p_value_set_id IN NUMBER )
  IS
    WITH hierarchy_list AS (
       -- �K�w�����擾
       SELECT
            ffvnh.parent_flex_value  AS parent_flex_value
          , ffvv.flex_value          AS flex_value
          , ffvv.summary_flag        AS summary_flag
       FROM
            fnd_flex_value_norm_hierarchy  ffvnh
          , fnd_flex_values_vl             ffvv
       WHERE
           ffvv.flex_value_set_id = p_value_set_id
       AND ffvv.flex_value_set_id = ffvnh.flex_value_set_id
       AND (( ffvv.summary_flag = 'Y' AND ffvnh.range_attribute = 'P' ) OR
            ( ffvv.summary_flag = 'N' AND ffvnh.range_attribute = 'C' ))
       AND ffvv.flex_value BETWEEN ffvnh.child_flex_value_low and ffvnh.child_flex_value_high
     ) ,base_list AS (
     -- �ŏ�ʂ��擾
     SELECT
          DISTINCT
          NULL                   AS parent_flex_value
        , hl1.parent_flex_value  AS flex_value
        , 'Y'                    AS summary_flag
     FROM
         hierarchy_list  hl1
     WHERE
         NOT EXISTS (
               SELECT 1
               FROM   hierarchy_list  hl2
               WHERE  hl2.flex_value = hl1.parent_flex_value
         )
     --
     UNION ALL
     -- �ŏ�ʂ��z�����擾
     SELECT
          hl3.parent_flex_value  AS parent_flex_value
        , hl3.flex_value         AS flex_value
        , hl3.summary_flag       AS summary_flag
     FROM
         hierarchy_list  hl3
     )
     --
     SELECT
         NVL( bl1.parent_flex_value, 'None' )   AS parent_flex_value  -- �e�l
       , bl1.flex_value                         AS flex_value         -- �l
       , DECODE( bl1.summary_flag
                   , 'Y'
                   , TO_CHAR(level)
                   , '31'
         )                                      AS depth              -- depth
     FROM
       base_list  bl1
     START WITH
       bl1.parent_flex_value is null
     CONNECT BY
       PRIOR bl1.flex_value = bl1.parent_flex_value
     ORDER BY
         level
       , bl1.parent_flex_value
       , bl1.flex_value;
--
  -- (3) AFF�i����ȖځA�⏕�Ȗځj�̊֘A�l���A�g�f�[�^�𒊏o����B
  -- =============================================================================================================
  CURSOR c_outbound_data3_cur(p_flex_value_set_name IN VARCHAR2)
  IS
    SELECT
        cv_aff_acc                                     AS cv_aff_acc               -- �Œ�l�F�i����Ȗځj
      , ffvs.flex_value_set_name                       AS flex_value_set_name      -- �l�Z�b�g��
      , ffvv.parent_flex_value_low                     AS parent_flex_value_low    -- �e�l
      , ffvv.parent_flex_value_low || ffvv.flex_value  AS flex_value               -- �e�l+�l
      , ffvv.enabled_flag                                                          -- �L���t���O
    FROM
        fnd_flex_value_sets ffvs
      , fnd_flex_values_vl  ffvv
    WHERE
      ffvs.flex_value_set_name = p_flex_value_set_name
    AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
    AND ( gd_pre_process_date IS NULL OR ffvv.last_update_date > gd_pre_process_date )
    ORDER BY
      ffvv.flex_value;
--
  -- AFF�f�[�^���i�[����e�[�u���^�̒�`
  gt_aff_data1_tbl_rec      c_outbound_data1_cur%ROWTYPE;           -- AFF�l�擾
  gt_aff_data2_tbl_rec      c_outbound_data2_cur%ROWTYPE;           -- AFF�K�w�擾
  gt_aff_data3_tbl_rec      c_outbound_data3_cur%ROWTYPE;           -- AFF�֘A�l�擾
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���������i�p�����[�^�`�F�b�N�E�v���t�@�C���擾�j(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_flex_value_set_name  IN  VARCHAR2     -- �l�Z�b�g��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt       NUMBER;                                             -- ����
    lv_msg       VARCHAR(2);                                         -- MSG No.
    lv_msgbuf    VARCHAR2(5000);                                     -- ���[�U�[�E���b�Z�[�W
--
    -- �t�@�C���o�͊֘A
    lb_fexists          BOOLEAN;                                     -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                                      -- �t�@�C���̒���
    ln_block_size       NUMBER;                                      -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
    -- OIC�A�g�����Ǘ��e�[�u���i�r���j
    CURSOR c_prog_name_cur IS
      SELECT xoipm.pre_process_date          AS pre_process_date     -- �O�񏈗�����
      FROM   xxccp_oic_if_process_mng xoipm                          -- OIC�A�g�����Ǘ��e�[�u��
      WHERE  xoipm.program_name = iv_flex_value_set_name             -- �l�Z�b�g��
      FOR UPDATE NOWAIT;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===================================
    -- A-1-1�D���̓p�����[�^���`�F�b�N����
    -- ===================================
--
    -- (1) ���̓p�����[�^�o��
    -- ===================================================================
    gv_f_value_set_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                         , iv_name         => cv_msg_cmm1_60043  -- �p�����[�^���i�l�Z�b�g���j
                         );
--
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm           -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60001        -- �p�����[�^�o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_param_name        -- �g�[�N��(PARAM_NAME)
                    , iv_token_value1 => gv_f_value_set_name      -- �l�Z�b�g��
                    , iv_token_name2  => cv_tkn_param_val         -- �g�[�N��(PARAM_VAL)
                    , iv_token_value2 => iv_flex_value_set_name   -- �p�����[�^�i�l�Z�b�g���j
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msgbuf
    );
--
    -- (2) ���̓p�����[�^�K�{�`�F�b�N
    -- ===================================================================
    IF ( iv_flex_value_set_name IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                    , cv_msg_cmm1_60048  -- �p�����[�^�K�{�G���[
                                                    , cv_tkn_param_name  -- �g�[�N��'PARAM_NAME'
                                                    , cv_msg_cmm1_60043  -- �p�����[�^���i�l�Z�b�g���j
                                                   )
                                                  , 1
                                                  , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- (3) �l�Z�b�g���݃`�F�b�N
    -- ===================================================================
    -- ���̓p�����[�^�u�l�Z�b�g���v���l�Z�b�g�e�[�u���ɑ��݂��邩�`�F�b�N����B
    SELECT COUNT(1) AS count
    INTO   ln_cnt
    FROM   fnd_flex_value_sets ffvs
    WHERE  ffvs.flex_value_set_name = iv_flex_value_set_name        -- �p�����[�^���i�l�Z�b�g���j
    AND    ffvs.flex_value_set_name in ( cv_aff_cmp, cv_aff_dpt, cv_aff_acc, cv_aff_sub, cv_aff_btp, cv_aff_pat );  -- �Ώ�AFF
--
    IF ( ln_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cmm     -- �A�h�I���F�}�X�^�E�o���E���ʂ̃A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_cmm1_60002  -- �l�Z�b�g���Y���Ȃ��G���[���b�Z�[�W
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1-2�D�v���t�@�C���l���擾����
    -- ===============================
--
    -- 1.�v���t�@�C������XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����擾
    -- ===================================================================
    gv_data_filedir := FND_PROFILE.VALUE( cv_data_filedir );
    -- �v���t�@�C���擾�G���[��
    IF ( gv_data_filedir IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_00002  -- �v���t�@�C���擾�G���[
                                                               , cv_tkn_ng_profile  -- �g�[�N��'NG_PROFILE'
                                                               , cv_data_filedir
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2.�v���t�@�C������XXCMM:AFF�l�A�g�f�[�^�t�@�C�����iOIC�A�g�j�擾
    -- ===================================================================
    gv_data_filename1 := FND_PROFILE.VALUE( cv_data_filename1 );
    -- �v���t�@�C���擾�G���[��
    IF ( gv_data_filename1 IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_00002  -- �v���t�@�C���擾�G���[
                                                               , cv_tkn_ng_profile  -- �g�[�N��'NG_PROFILE'
                                                               , cv_data_filename1
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3.�v���t�@�C������XXCMM:AFF�K�w�A�g�f�[�^�t�@�C�����iOIC�A�g�j�擾
    -- ===================================================================
    gv_data_filename2 := FND_PROFILE.VALUE( cv_data_filename2 );
    -- �v���t�@�C���擾�G���[��
    IF ( gv_data_filename2 IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg3 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00002   -- �v���t�@�C���擾�G���[
                                                               , cv_tkn_ng_profile   -- �g�[�N��'NG_PROFILE'
                                                               , cv_data_filename2
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 4.�v���t�@�C������XXCMM:AFF�֘A�l�A�g�f�[�^�t�@�C�����iOIC�A�g�j�擾
    -- ===================================================================
    gv_data_filename3 := FND_PROFILE.VALUE( cv_data_filename3 );
    -- �v���t�@�C���擾�G���[��
    IF ( gv_data_filename3 IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg4 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00002   -- �v���t�@�C���擾�G���[
                                                               , cv_tkn_ng_profile   -- �g�[�N��'NG_PROFILE'
                                                               , cv_data_filename3
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 5.�v���t�@�C������XXCMM:�c���[�o�[�W�����J�n���擾
    -- ===============================================================
    gd_tv_start_date := TO_DATE(FND_PROFILE.VALUE( cv_tv_start_date ), cv_date_ymd);
    -- �v���t�@�C���擾�G���[��
    IF ( gd_tv_start_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg5 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00002   -- �v���t�@�C���擾�G���[
                                                               , cv_tkn_ng_profile   -- �g�[�N��'NG_PROFILE'
                                                               , cv_tv_start_date
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================================================================
    -- A-1-3�D�v���t�@�C���l�uXXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����v����f�B���N�g���p�X���擾����
    -- ====================================================================================================
    BEGIN
      SELECT RTRIM( ad.directory_path , cv_msg_slash )   AS  directory_path  -- �f�B���N�g���p�X
      INTO   gv_file_path
      FROM   all_directories  ad
      WHERE  ad.directory_name = gv_data_filedir;                         -- �v���t�@�C���l�uXXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g�����v
    EXCEPTION
      WHEN OTHERS THEN
        -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
        lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                                 , cv_msg_coi1_00029      -- �f�B���N�g���p�X�擾�G���[
                                                                 , cv_tkn_dir_tok         -- �g�[�N��'DIR_TOK'
                                                                 , gv_data_filedir        -- XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                                                                )
                                                               , 1
                                                               , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �f�B���N�g���p�X�擾�G���[���b�Z�[�W
    -- directory_name�͓o�^����Ă��邪�Adirectory_path���󔒂̎�
    IF ( gv_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_coi         -- 'XXCOI'
                                                               , cv_msg_coi1_00029      -- �f�B���N�g���p�X�擾�G���[
                                                               , cv_tkn_dir_tok         -- �g�[�N��'DIR_TOK'
                                                               , gv_data_filedir        -- XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================================================================
    -- A-1-4�D�t�@�C�����Ɏ��ʔԍ���t�^���A�t�@�C���p�X/�t�@�C�����ŏo�͂���
    -- ====================================================================================================
    gv_file_path := gv_file_path || cv_msg_slash;                   -- �t�@�C���p�X/
    CASE WHEN iv_flex_value_set_name = cv_aff_cmp THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_cmp || cv_2nd_nm;    -- ���
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_cmp || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_cmp || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_dpt THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_dpt || cv_2nd_nm;    -- ����
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_dpt || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_dpt || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_acc THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_acc || cv_2nd_nm;    -- ����Ȗ�
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_acc || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_acc || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_sub THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_sub || cv_2nd_nm;    -- �⏕�Ȗ�
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_sub || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_sub || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_btp THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_btp || cv_2nd_nm;    -- ��ƃR�[�h
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_btp || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_btp || cv_2nd_nm;
         WHEN iv_flex_value_set_name = cv_aff_pat THEN
           gv_data_filename1 := REPLACE( gv_data_filename1, cv_2nd_nm) || cv_fno_pat || cv_2nd_nm;    -- �ڋq�R�[�h
           gv_data_filename2 := REPLACE( gv_data_filename2, cv_2nd_nm) || cv_fno_pat || cv_2nd_nm;
           gv_data_filename3 := REPLACE( gv_data_filename3, cv_2nd_nm) || cv_fno_pat || cv_2nd_nm;
         ELSE
           NULL;
    END CASE;
--
    -- 1) XXCMM:AFF�l�A�g�f�[�^�t�@�C��
    -- =================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cmm                     -- 'XXCMM'
                                         , iv_name         => cv_msg_cmm1_60003                  -- IF�t�@�C�����o�̓��b�Z�[�W
                                         , iv_token_name1  => cv_tkn_file_name                   -- �g�[�N��(FILE_NAME)
                                         , iv_token_value1 => gv_file_path || gv_data_filename1  -- �t�@�C���p�X/AFF�l�A�g�f�[�^�t�@�C����
                                         );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 2) XXCMM:AFF�K�w�A�g�f�[�^�t�@�C��
    -- =================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cmm                     -- 'XXCMM'
                                         , iv_name         => cv_msg_cmm1_60003                  -- IF�t�@�C�����o�̓��b�Z�[�W
                                         , iv_token_name1  => cv_tkn_file_name                   -- �g�[�N��(FILE_NAME)
                                         , iv_token_value1 => gv_file_path || gv_data_filename2  -- �t�@�C���p�X/XCMM:AFF�K�w�A�g�f�[�^�t�@�C����
                                         );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 3) XXCMM:AFF�֘A�l�A�g�f�[�^�t�@�C��
    -- =================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                           iv_application  => cv_msg_kbn_cmm                     -- 'XXCMM'
                                         , iv_name         => cv_msg_cmm1_60003                  -- IF�t�@�C�����o�̓��b�Z�[�W
                                         , iv_token_name1  => cv_tkn_file_name                   -- �g�[�N��(FILE_NAME)
                                         , iv_token_value1 => gv_file_path || gv_data_filename3  -- �t�@�C���p�X/XXCMM:AFF�֘A�l�A�g�f�[�^�t�@�C����
                                         );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ====================================================================
    -- A-1-5�D ���ɓ���t�@�C�������݂��Ă��Ȃ����t�@�C�������`�F�b�N���s��
    -- ====================================================================
--
    -- 1) XXCMM:AFF�l�A�g�f�[�^�t�@�C��
    -- =================================
    UTL_FILE.FGETATTR( gv_data_filedir
                     , gv_data_filename1                                  -- AFF�l�A�g�f�[�^�t�@�C����
                     , lb_fexists
                     , ln_file_size
                     , ln_block_size );
--
    -- ����t�@�C�����݃G���[���b�Z�[�W
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_60004  -- ����t�@�C�����݃G���[���b�Z�[�W
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 2) XCMM:AFF�K�w�A�g�f�[�^�t�@�C��
    -- =================================
    UTL_FILE.FGETATTR( gv_data_filedir
                     , gv_data_filename2                                  -- AFF�K�w�A�g�f�[�^�t�@�C����
                     , lb_fexists
                     , ln_file_size
                     , ln_block_size );
--
    -- ����t�@�C�����݃G���[���b�Z�[�W
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_60004  -- ����t�@�C�����݃G���[���b�Z�[�W
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 3) XXCMM:AFF�֘A�l�A�g�f�[�^�t�@�C��
    -- =================================
    UTL_FILE.FGETATTR( gv_data_filedir
                     , gv_data_filename3                                  -- AFF�֘A�l�A�g�f�[�^�t�@�C����
                     , lb_fexists
                     , ln_file_size
                     , ln_block_size );
--
    -- ����t�@�C�����݃G���[���b�Z�[�W
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(cv_msg3 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm     -- 'XXCMM'
                                                               , cv_msg_cmm1_60004  -- ����t�@�C�����݃G���[���b�Z�[�W
                                                              )
                                                             , 1
                                                             , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================================================================================
    -- A-1-6�D���@�\�́u�R���J�����g�v���O�������v�A����сu�O�񏈗������v���擾����B�i�r�������j
    -- ===========================================================================================
    BEGIN
      OPEN  c_prog_name_cur;
      FETCH c_prog_name_cur INTO gd_pre_process_date;               -- �O�񏈗�����
      CLOSE c_prog_name_cur;
--
    EXCEPTION
      WHEN global_lock_expt THEN  -- �e�[�u�����b�N�G���[
        IF ( c_prog_name_cur%ISOPEN ) THEN
          -- �J�[�\���̃N���[�Y
          CLOSE c_prog_name_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cmm         -- 'XXCMM'
                        , iv_name         => cv_msg_cmm1_00008      -- ���b�N�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_ng_table        -- �g�[�N��(NG_TABLE)
                        , iv_token_value1 => cv_msg_cmm1_60008      -- OIC�A�g�����Ǘ��e�[�u��
                       );
--
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        IF ( c_prog_name_cur%ISOPEN ) THEN
          -- �J�[�\���̃N���[�Y
          CLOSE c_prog_name_cur;
        END IF;
        RAISE global_api_others_expt;
    END;
--
    -- ========================================
    -- A-1-7�D���񏈗������iSYSDATE�j���擾����
    -- ========================================
    gd_process_date := cd_creation_date;                                    -- ���񏈗�����
--
    -- ===========================================
    -- A-1-8�D�O��A����э���̏����������o�͂���
    -- ===========================================
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                                -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60005                             -- ���������o�̓��b�Z�[�W
                    , iv_token_name1  => cv_tkn_date1                                  -- �g�[�N��(DATE1)
                    , iv_token_value1 => TO_CHAR(gd_pre_process_date, cv_proc_date_fm) -- �O�񏈗�����
                    , iv_token_name2  => cv_tkn_date2                                  -- �g�[�N��(DATE2)
                    , iv_token_value2 => TO_CHAR(gd_process_date, cv_proc_date_fm)     -- ���񏈗�����
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- ==========================================
    -- A-1-9�D���ׂĂ�OIC�A�g�t�@�C���I�[�v������
    -- ==========================================
    BEGIN
        -- 1.�t�@�C���I�[�v���iAFF�l�A�g�f�[�^�t�@�C���j
        lv_msg := cv_msg1;
        gf_file_hand1 := UTL_FILE.FOPEN(
                                         gv_data_filedir            -- �f�B���N�g���p�X
                                       , gv_data_filename1          -- �t�@�C����
                                       , cv_open_mode_w             -- �I�[�v�����[�h
                                       , cn_max_linesize            -- �t�@�C���s�T�C�Y
                                       );
--
        -- 2.�t�@�C���I�[�v���iAFF�K�w�A�g�f�[�^�t�@�C���j
        lv_msg := cv_msg2;
        gf_file_hand2 := UTL_FILE.FOPEN(
                                         gv_data_filedir            -- �f�B���N�g���p�X
                                       , gv_data_filename2          -- �t�@�C����
                                       , cv_open_mode_w             -- �I�[�v�����[�h
                                       , cn_max_linesize            -- �t�@�C���s�T�C�Y
                                       );
--
        -- 3.�t�@�C���I�[�v���iAFF�֘A�l�A�g�f�[�^�t�@�C���j
        lv_msg := cv_msg3;
        gf_file_hand3 := UTL_FILE.FOPEN(
                                         gv_data_filedir            -- �f�B���N�g���p�X
                                       , gv_data_filename3          -- �t�@�C����
                                       , cv_open_mode_w             -- �I�[�v�����[�h
                                       , cn_max_linesize            -- �t�@�C���s�T�C�Y
                                       );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILENAME THEN
        lv_errmsg := SUBSTRB(lv_msg || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                                , cv_msg_cmm1_00487   -- �t�@�C���I�[�v���G���[
                                                                , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                                , SQLERRM             -- SQLERRM�i�t�@�C�����������j
                                                               )
                                                              , 1
                                                              , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_OPERATION THEN
        lv_errmsg := SUBSTRB(lv_msg || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                                , cv_msg_cmm1_00487   -- �t�@�C���I�[�v���G���[
                                                                , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                                , SQLERRM             -- SQLERRM�i�t�@�C�����I�[�v���ł��Ȃ��j
                                                               )
                                                              , 1
                                                              , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(lv_msg || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                                , cv_msg_cmm1_00487   -- �t�@�C���I�[�v���G���[
                                                                , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                                , SQLERRM             -- SQLERRM�i���̑��j
                                                               )
                                                              , 1
                                                              , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc1
   * Description      : AFF�l�̒��o�E�t�@�C���o�͏��� (A-2)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc1(
      iv_flex_value_set_name  IN  VARCHAR2     -- �l�Z�b�g��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc1'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                         -- LF�u���P��iFBDI�t�@�C���p������u���j
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';                         -- CSV��؂蕶��
    cv_fixed_n        CONSTANT VARCHAR2(1)  := 'N';                         -- �Œ�o�͕���
--
    -- *** ���[�J���ϐ� ***
    ln_cnt            NUMBER := 0;                                          -- �eAFF�擾�̌���
    lv_csv_text       VARCHAR2(30000)           DEFAULT NULL;               -- �o�͂P�s��������ϐ�
    lv_posting        VARCHAR2(1);                                          -- �]�L�̋���
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================================
    -- A-2-1.AFF�l�A�g�f�[�^�̒��o
    -- =======================================
    <<data_loop>>
    FOR gt_aff_data1_tbl_rec IN c_outbound_data1_cur( iv_flex_value_set_name ) LOOP
      -- �t�@�C���o�͍s��ҏW
      -- �]�L�̋���'Y'�A���ASUMMARY_FLAG�i�v��t���O�j��'Y'�̏ꍇ�A'N'�֕ϊ�����B
      IF ( gt_aff_data1_tbl_rec.posting = 'Y' AND gt_aff_data1_tbl_rec.summary_flag = 'Y' ) THEN
        lv_posting := cv_fixed_n;
      ELSE
        lv_posting := gt_aff_data1_tbl_rec.posting;
      END IF;
      lv_csv_text := 
           xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.flex_value_set_name, cv_space ) || cv_delimiter  --  1.�l�Z�b�g��
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.flex_value, cv_space )   || cv_delimiter         --  2.�l
        || gt_aff_data1_tbl_rec.start_date_active || cv_delimiter                                                   --  3.�J�n��
        || gt_aff_data1_tbl_rec.end_date_active || cv_delimiter                                                     --  4.�I����
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.summary_flag, cv_space ) || cv_delimiter         --  5.�v��
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.enabled_flag, cv_space ) || cv_delimiter         --  6.�L��
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.acc_type, cv_space )     || cv_delimiter         --  7.����Ȗڃ^�C�v
        || xxccp_oiccommon_pkg.to_csv_string( lv_posting, cv_space )                        || cv_delimiter         --  8.�]�L�̋���
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.regist, cv_space )       || cv_delimiter         --  9.�\�Z�o�^�̋���
        || cv_fixed_n || cv_delimiter                                                                               -- 10.�Œ�l�FN
        || cv_fixed_n || cv_delimiter                                                                               -- 11.�Œ�l�FN
        || NULL || cv_delimiter                                                                                     -- 12.Financial Category
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.description, cv_space ) || cv_delimiter          -- 13.Description US
        || NULL || cv_delimiter                                                                                     -- 14.Description AR
        || NULL || cv_delimiter                                                                                     -- 15.Description CS
        || NULL || cv_delimiter                                                                                     -- 16.Description D
        || NULL || cv_delimiter                                                                                     -- 17.Description DK
        || NULL || cv_delimiter                                                                                     -- 18.Description E
        || NULL || cv_delimiter                                                                                     -- 19.Description EL
        || NULL || cv_delimiter                                                                                     -- 20.Description ES
        || NULL || cv_delimiter                                                                                     -- 21.Description F
        || NULL || cv_delimiter                                                                                     -- 22.Description FR
        || NULL || cv_delimiter                                                                                     -- 23.Description HR
        || NULL || cv_delimiter                                                                                     -- 24.Description HU
        || NULL || cv_delimiter                                                                                     -- 25.Description I
        || NULL || cv_delimiter                                                                                     -- 26.Description IS
        || NULL || cv_delimiter                                                                                     -- 27.Description IW
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.description, cv_space ) || cv_delimiter          -- 28.�E�v
        || NULL || cv_delimiter                                                                                     -- 29.Description KO
        || NULL || cv_delimiter                                                                                     -- 30.Description NL
        || NULL || cv_delimiter                                                                                     -- 31.Description LT
        || NULL || cv_delimiter                                                                                     -- 32.Description PL
        || NULL || cv_delimiter                                                                                     -- 33.Description PT
        || NULL || cv_delimiter                                                                                     -- 34.Description PTB
        || NULL || cv_delimiter                                                                                     -- 35.Description N
        || NULL || cv_delimiter                                                                                     -- 36.Description RO
        || NULL || cv_delimiter                                                                                     -- 37.Description RU
        || NULL || cv_delimiter                                                                                     -- 38.Description S
        || NULL || cv_delimiter                                                                                     -- 39.Description SF
        || NULL || cv_delimiter                                                                                     -- 40.Description SK
        || NULL || cv_delimiter                                                                                     -- 41.Description SL
        || NULL || cv_delimiter                                                                                     -- 42.Description TH
        || NULL || cv_delimiter                                                                                     -- 43.Description TR
        || NULL || cv_delimiter                                                                                     -- 44.Description ZHS
        || NULL || cv_delimiter                                                                                     -- 45.Description ZHT
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute1 , cv_space ) || cv_delimiter          -- 46.Attribute1
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute2 , cv_space ) || cv_delimiter          -- 47.Attribute2
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute3 , cv_space ) || cv_delimiter          -- 48.Attribute3
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute4 , cv_space ) || cv_delimiter          -- 49.Attribute4
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute5 , cv_space ) || cv_delimiter          -- 50.Attribute5
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute6 , cv_space ) || cv_delimiter          -- 51.Attribute6
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute7 , cv_space ) || cv_delimiter          -- 52.Attribute7
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute8 , cv_space ) || cv_delimiter          -- 53.Attribute8
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute9 , cv_space ) || cv_delimiter          -- 54.Attribute9
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute10, cv_space ) || cv_delimiter          -- 55.Attribute10
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute11, cv_space ) || cv_delimiter          -- 56.attribute11
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute12, cv_space ) || cv_delimiter          -- 57.attribute12
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute13, cv_space ) || cv_delimiter          -- 58.attribute13
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute14, cv_space ) || cv_delimiter          -- 59.attribute14
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute15, cv_space ) || cv_delimiter          -- 60.attribute15
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute16, cv_space ) || cv_delimiter          -- 61.attribute16
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute17, cv_space ) || cv_delimiter          -- 62.attribute17
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute18, cv_space ) || cv_delimiter          -- 63.attribute18
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute19, cv_space ) || cv_delimiter          -- 64.attribute19
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute20, cv_space ) || cv_delimiter          -- 65.attribute20
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute21, cv_space ) || cv_delimiter          -- 66.Attribute21
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute22, cv_space ) || cv_delimiter          -- 67.Attribute22
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute23, cv_space ) || cv_delimiter          -- 68.Attribute23
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute24, cv_space ) || cv_delimiter          -- 69.Attribute24
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute25, cv_space ) || cv_delimiter          -- 70.Attribute25
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute26, cv_space ) || cv_delimiter          -- 71.Attribute26
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute27, cv_space ) || cv_delimiter          -- 72.Attribute27
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute28, cv_space ) || cv_delimiter          -- 73.Attribute28
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute29, cv_space ) || cv_delimiter          -- 74.Attribute29
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute30, cv_space ) || cv_delimiter          -- 75.Attribute30
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute31, cv_space ) || cv_delimiter          -- 76.Attribute31
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute32, cv_space ) || cv_delimiter          -- 77.Attribute32
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute33, cv_space ) || cv_delimiter          -- 78.Attribute33
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute34, cv_space ) || cv_delimiter          -- 79.Attribute34
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute35, cv_space ) || cv_delimiter          -- 80.Attribute35
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute36, cv_space ) || cv_delimiter          -- 81.Attribute36
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute37, cv_space ) || cv_delimiter          -- 82.Attribute37
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute38, cv_space ) || cv_delimiter          -- 83.Attribute38
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute39, cv_space ) || cv_delimiter          -- 84.Attribute39
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute40, cv_space ) || cv_delimiter          -- 85.Attribute40
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute41, cv_space ) || cv_delimiter          -- 86.Attribute41
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute42, cv_space ) || cv_delimiter          -- 87.Attribute42
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute43, cv_space ) || cv_delimiter          -- 88.Attribute43
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute44, cv_space ) || cv_delimiter          -- 89.Attribute44
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute45, cv_space ) || cv_delimiter          -- 90.Attribute45
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute46, cv_space ) || cv_delimiter          -- 91.Attribute46
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute47, cv_space ) || cv_delimiter          -- 92.Attribute47
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute48, cv_space ) || cv_delimiter          -- 93.Attribute48
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute49, cv_space ) || cv_delimiter          -- 94.Attribute49
        || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data1_tbl_rec.attribute50, cv_space ) || cv_delimiter          -- 95.Attribute50
        || NULL                                                                                                     -- 96.Data Source
      ;
--
      -- =======================================
      -- A-2-2.AFF�l�A�g�f�[�^�̃t�@�C���o��
      -- =======================================
      -- �t�@�C����������
      UTL_FILE.PUT_LINE( gf_file_hand1, lv_csv_text ) ;
      ln_cnt := ln_cnt + 1 ;
    END LOOP data_loop;
--
    -- AFF�l�A�g�̑Ώی������Z�b�g
    gn_target1_cnt := ln_cnt;                    -- AFF�l�A�g�̌���
    gn_target_cnt  := ln_cnt;                    -- �A�g�f�[�^�̗݌v
    -- ���팏�� = �Ώی����i�����j
    gn_normal_cnt  := gn_target_cnt;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand1 );
      END IF;
      lv_errmsg := SUBSTRB(cv_msg1 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00488   -- �t�@�C���������݃G���[
                                                               , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                               , SQLERRM             -- SQLERRM
                                                              )
                                                             , 1
                                                             , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand1 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand1 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_outbound_proc1;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc2
   * Description      : AFF�K�w�̒��o�E�t�@�C���o�͏��� (A-3)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc2(
      iv_flex_value_set_name  IN  VARCHAR2     -- �l�Z�b�g��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc2'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                            -- LF�u���P��iFBDI�t�@�C���p������u���j
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';                            -- CSV��؂蕶��
    cv_fixed_dpth     CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT_HIERARCHY';    -- �Œ�o�͕���
    cv_fixed_dptv     CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT';              -- �Œ�o�͕���
    cv_fixed_acch     CONSTANT VARCHAR2(30) := 'XX03_ACCOUNT_HIERARCHY';       -- �Œ�o�͕���
    cv_fixed_accv     CONSTANT VARCHAR2(30) := 'XX03_ACCOUNT';                 -- �Œ�o�͕���
    cv_fixed_dpth_t   CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT_HIERARCHY_T';  -- �Œ�o�͕���(����T)
--
--
    -- *** ���[�J���ϐ� ***
    ln_loop_cnt             NUMBER := 0;                                       -- ���[�v�J�E���^
    ln_cnt                  NUMBER := 0;                                       -- �eAFF�擾�̌���
    lv_csv_text             VARCHAR2(30000)           DEFAULT NULL;            -- �o�͂P�s��������ϐ�
    l_tree_code             VARCHAR2(30);                                      -- 2.Tree Code
    l_version_name          VARCHAR2(30);                                      -- 3.Tree Version Name
    ln_flex_value_set_id    fnd_flex_value_sets.flex_value_set_id%TYPE;        -- �l�Z�b�gID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================================
    -- A-3-1.AFF�K�w�A�g�f�[�^�̒��o
    -- =======================================
    -- ���̓p�����[�^�u�l�Z�b�g���v������iXX03_DEPARTMENT�j�A�܂��͊���ȖځiXX03_ACCOUNT�j�̏ꍇ�A���o�������s���B
--
    IF ( iv_flex_value_set_name = cv_aff_dpt OR iv_flex_value_set_name = cv_aff_acc ) THEN
      --(2)-1. �A�g�ΏۂƂȂ�K�w�i�l�Z�b�gID�j���擾����B
      OPEN  c_outbound_data2_id_cur( iv_flex_value_set_name );
      FETCH c_outbound_data2_id_cur INTO ln_flex_value_set_id;
      CLOSE c_outbound_data2_id_cur;
--
      --(2)-2. ����̎��A����K�w�̒l�Z�b�gID���ɘA�g�f�[�^�𒊏o����B
      IF ( iv_flex_value_set_name = cv_aff_dpt ) THEN
        ln_cnt := 0;
        <<data_loop>>
        FOR gt_aff_data2_tbl_rec IN c_outbound_data2_cur( ln_flex_value_set_id ) LOOP
          CASE WHEN gt_aff_data2_tbl_rec.flex_value        = 'T' THEN
                 l_tree_code    := cv_fixed_dpth_t;
                 l_version_name := cv_aff_dpt_t;
               WHEN gt_aff_data2_tbl_rec.parent_flex_value = 'T' THEN
                 l_tree_code    := cv_fixed_dpth_t;
                 l_version_name := cv_aff_dpt_t;
               ELSE
                 l_tree_code    := cv_fixed_dpth;
                 l_version_name := cv_aff_dpt;
          END CASE;
          -- �t�@�C���o�͍s�ҏW�i����j
          lv_csv_text :=
               cv_aff_dpt                                                                            || cv_delimiter  --  1.�Œ�l
            || l_tree_code                                                                           || cv_delimiter  --  2.�Œ�l
            || l_version_name                                                                        || cv_delimiter  --  3.�Œ�l
            || TO_CHAR(gd_tv_start_date, cv_date_ymd)                                                || cv_delimiter  --  4.�c���[�o�[�W�����J�n��
            || NULL                                                                                  || cv_delimiter  --  5.Tree Version End Date
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.flex_value, cv_space )        || cv_delimiter  --  6.�l
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.parent_flex_value, cv_space ) || cv_delimiter  --  7.�e�l
            || gt_aff_data2_tbl_rec.depth                                                            || cv_delimiter  --  8.DEPTH
            || NULL                                                                                                   --  9.Label Short Name
          ;
          -- =================================
          -- AFF�K�w�i����j�̃t�@�C���o��
          -- =================================
          -- �t�@�C����������
          UTL_FILE.PUT_LINE( gf_file_hand2, lv_csv_text ) ;
          ln_cnt := ln_cnt + 1 ;
        END LOOP data_loop;
--
        -- AFF�K�w�i����j�A�g�̑Ώی������Z�b�g
        gn_target2_dpt_cnt := ln_cnt;                       -- AFF�K�w�i����j�A�g�̌���
        gn_target_cnt      := gn_target_cnt + ln_cnt;       -- �A�g�f�[�^�̗݌v
        -- ���팏�� = �Ώی����i�����j
        gn_normal_cnt      := gn_target_cnt;
--
      --(2)-3. ����Ȗڂ̎��A����ȖڊK�w�̒l�Z�b�gID���ɘA�g�f�[�^�𒊏o����B
      ELSE
        ln_cnt := 0;
        <<data_loop>>
        FOR gt_aff_data2_tbl_rec IN c_outbound_data2_cur( ln_flex_value_set_id ) LOOP
          -- �t�@�C���o�͍s�ҏW�i����Ȗځj
          lv_csv_text :=
               cv_aff_acc                                                                            || cv_delimiter  --  1.�Œ�l
            || cv_fixed_acch                                                                         || cv_delimiter  --  2.�Œ�l
            || cv_aff_acc                                                                            || cv_delimiter  --  3.�Œ�l
            || TO_CHAR(gd_tv_start_date, cv_date_ymd)                                                || cv_delimiter  --  4.�c���[�o�[�W�����J�n��
            || NULL                                                                                  || cv_delimiter  --  5.Tree Version End Date
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.flex_value, cv_space )        || cv_delimiter  --  6.�l
            || xxccp_oiccommon_pkg.to_csv_string( gt_aff_data2_tbl_rec.parent_flex_value, cv_space ) || cv_delimiter  --  7.�e�l
            || gt_aff_data2_tbl_rec.depth                                                            || cv_delimiter  --  8.DEPTH
            || NULL                                                                                                   --  9.Label Short Name
          ;
--
          -- =================================
          -- AFF�K�w�i����Ȗځj�̃t�@�C���o��
          -- =================================
          -- �t�@�C����������
          UTL_FILE.PUT_LINE( gf_file_hand2, lv_csv_text ) ;
          ln_cnt := ln_cnt + 1 ;
        END LOOP data_loop;
--
        -- AFF�K�w�i����Ȗځj�A�g�̑Ώی������Z�b�g
        gn_target2_acc_cnt := ln_cnt;                        -- AFF�K�w�i����Ȗځj�A�g�̌���
        gn_target_cnt      := gn_target_cnt + ln_cnt;        -- �A�g�f�[�^�̗݌v
        -- ���팏�� = �Ώی����i�����j
        gn_normal_cnt      := gn_target_cnt;
      END IF;
--
    END IF;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand2 );
      END IF;
      lv_errmsg := SUBSTRB(cv_msg2 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00488   -- �t�@�C���������݃G���[
                                                               , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                               , SQLERRM             -- SQLERRM
                                                              )
                                                             , 1
                                                             , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_outbound_proc2;
--
  /**********************************************************************************
   * Procedure Name   : data_outbound_proc3
   * Description      : AFF�֘A�l�̒��o�E�t�@�C���o�͏��� (A-4)
   ***********************************************************************************/
  PROCEDURE data_outbound_proc3(
      iv_flex_value_set_name  IN  VARCHAR2     -- �l�Z�b�g��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_outbound_proc3'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    cv_space          CONSTANT VARCHAR2(1)  := ' ';                         -- LF�u���P��iFBDI�t�@�C���p������u���j
    cv_delimiter      CONSTANT VARCHAR2(1)  := '|';                         -- CSV��؂蕶��
    cv_fixed_hd1      CONSTANT VARCHAR2(30) := 'VALUE_SET_CODE1';           -- �Œ�o�͕����iA3�w�b�_�[�j
    cv_fixed_hd2      CONSTANT VARCHAR2(30) := 'VALUE_SET_CODE2';           -- �Œ�o�͕����iA3�w�b�_�[�j
    cv_fixed_hd3      CONSTANT VARCHAR2(30) := 'VALUE1';                    -- �Œ�o�͕����iA3�w�b�_�[�j
    cv_fixed_hd4      CONSTANT VARCHAR2(30) := 'VALUE2';                    -- �Œ�o�͕����iA3�w�b�_�[�j
    cv_fixed_hd5      CONSTANT VARCHAR2(30) := 'ENABLED_FLAG';              -- �Œ�o�͕����iA3�w�b�_�[�j
--
    -- *** ���[�J���ϐ� ***
    ln_cnt            NUMBER := 0;                                          -- �eAFF�擾�̌���
    lv_csv_text       VARCHAR2(30000)           DEFAULT NULL;               -- �o�͂P�s��������ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================================
    -- A-4-1.AFF�֘A�l�A�g�f�[�^�̒��o
    -- =======================================
    -- ���̓p�����[�^�u�l�Z�b�g���v���⏕�ȖځiXX03_SUB_ACCOUNT�j�̏ꍇ�A���o�������s���B
--
    IF ( iv_flex_value_set_name = cv_aff_sub ) THEN
      ln_cnt := 0;
      <<data_loop>>
      FOR gt_aff_data3_tbl_rec IN c_outbound_data3_cur( iv_flex_value_set_name ) LOOP
        IF ( ln_cnt = 0 ) THEN
          -- �t�@�C���o�͍s��ҏW�i�w�b�_�[�j
          lv_csv_text := cv_fixed_hd1 || cv_delimiter   --  1.�Œ�l
            || cv_fixed_hd2 || cv_delimiter             --  2.�Œ�l
            || cv_fixed_hd3 || cv_delimiter             --  3.�Œ�l
            || cv_fixed_hd4 || cv_delimiter             --  4.�Œ�l
            || cv_fixed_hd5                             --  5.�Œ�l
          ;
          -- �t�@�C����������
          UTL_FILE.PUT_LINE( gf_file_hand3, lv_csv_text ) ;
        END IF;
--
        -- �t�@�C���o�͍s��ҏW�i�f�[�^�s�j
        lv_csv_text := gt_aff_data3_tbl_rec.cv_aff_acc  || cv_delimiter    --  1.�Œ�l�i����Ȗځj
          || gt_aff_data3_tbl_rec.flex_value_set_name   || cv_delimiter    --  2.�Œ�l�i�l�Z�b�g���j
          || gt_aff_data3_tbl_rec.parent_flex_value_low || cv_delimiter    --  3.�e�l
          || gt_aff_data3_tbl_rec.flex_value            || cv_delimiter    --  4.�l
          || gt_aff_data3_tbl_rec.enabled_flag                             --  5.�L��
        ;
--
        -- =======================================
        -- A-4-2.AFF�֘A�l�A�g�f�[�^�̃t�@�C���o��
        -- =======================================
        -- �t�@�C����������
        UTL_FILE.PUT_LINE( gf_file_hand3, lv_csv_text ) ;
        ln_cnt := ln_cnt + 1 ;
      END LOOP data_loop;
--
      -- AFF�֘A�l�A�g�̑Ώی������Z�b�g
      gn_target3_cnt := ln_cnt;                                    -- AFF�֘A�l�A�g�̌���
      gn_target_cnt  := gn_target_cnt + ln_cnt;                    -- �A�g�f�[�^�̗݌v
      -- ���팏�� = �Ώی����i�����j
      gn_normal_cnt  := gn_target_cnt;
--
    END IF;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand3 );
      END IF;
      lv_errmsg := SUBSTRB(cv_msg3 || xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm      -- 'XXCMM'
                                                               , cv_msg_cmm1_00488   -- �t�@�C���������݃G���[
                                                               , cv_tkn_sqlerrm      -- �g�[�N��'SQLERRM'
                                                               , SQLERRM             -- SQLERRM
                                                              )
                                                             , 1
                                                             , 5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand3 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �t�@�C���N���[�Y
      IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN
        UTL_FILE.FCLOSE( gf_file_hand3 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END data_outbound_proc3;
--
  /**********************************************************************************
   * Procedure Name   : upd_oic_ctrl_tbl
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����          (A-5)
   ***********************************************************************************/
  PROCEDURE upd_oic_ctrl_tbl(
      iv_flex_value_set_name  IN  VARCHAR2     -- �l�Z�b�g��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_oic_ctrl_tbl'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- OIC�A�g�����Ǘ��e�[�u���o�^
    -- ===============================
    -- �O�񏈗�������NULL�i�ڍs�̎��j�͐V�K�o�^
    IF ( gd_pre_process_date IS NULL ) THEN
      BEGIN
        INSERT INTO xxccp_oic_if_process_mng(
           program_name
         , pre_process_date
         , created_by
         , creation_date
         , last_updated_by
         , last_update_date
         , last_update_login
         , request_id
         , program_application_id
         , program_id
         , program_update_date
        ) VALUES (
           iv_flex_value_set_name                 -- �l�Z�b�g��
         , gd_process_date                        -- ���񏈗�����
         , cn_created_by                          -- �쐬��
         , cd_creation_date                       -- �쐬��
         , cn_last_updated_by                     -- �ŏI�X�V��
         , cd_last_update_date                    -- �ŏI�X�V��
         , cn_last_update_login                   -- �ŏI�X�V���O�C��
         , cn_request_id                          -- �v��ID
         , cn_program_application_id              -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         , cn_program_id                          -- �R���J�����g�E�v���O����ID
         , cd_program_update_date                 -- �v���O�����ɂ��X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �V�K�o�^���̃G���[
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm        -- 'XXCMM'
                                                        , cv_msg_cmm1_00054     -- �}���G���[
                                                        , cv_tkn_table          -- �g�[�N��'TABLE'
                                                        , cv_msg_cmm1_60008     -- OIC�A�g�����Ǘ��e�[�u��
                                                        , cv_tkn_err_msg        -- �g�[�N��'ERR_MSG'
                                                        , SQLERRM               -- SQLERRM
                                                       )
                                                      , 1
                                                      , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- ==================================
    -- �O�񏈗��������擾�������͍X�V����
    -- ==================================
    ELSE
      BEGIN
        UPDATE xxccp_oic_if_process_mng
        SET    pre_process_date        = gd_process_date,             -- ���񏈗�����
               last_updated_by         = cn_last_updated_by,          -- �ŏI�X�V��
               last_update_date        = cd_last_update_date,         -- �ŏI�X�V��
               last_update_login       = cn_last_update_login,        -- �ŏI�X�V���O�C��
               request_id              = cn_request_id,               -- �v��ID
               program_application_id  = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               program_id              = cn_program_id,               -- �R���J�����g�E�v���O����ID
               program_update_date     = cd_program_update_date       -- �v���O�����X�V��
        WHERE  program_name = iv_flex_value_set_name;                 -- �l�Z�b�g��
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�X�V���̃G���[
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cmm        -- 'XXCMM'
                                                        , cv_msg_cmm1_00055     -- �X�V�G���[
                                                        , cv_tkn_table          -- �g�[�N��'TABLE'
                                                        , cv_msg_cmm1_60008     -- OIC�A�g�����Ǘ��e�[�u��
                                                        , cv_tkn_err_msg        -- �g�[�N��'ERR_MSG'
                                                        , SQLERRM               -- SQLERRM
                                                       )
                                                      , 1
                                                      , 5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_oic_ctrl_tbl;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_flex_value_set_name  IN  VARCHAR2     -- �l�Z�b�g��
    , ov_errbuf               OUT VARCHAR2     -- �G���[�E���b�Z�[�W            # �Œ� #
    , ov_retcode              OUT VARCHAR2     -- ���^�[���E�R�[�h              # �Œ� #
    , ov_errmsg               OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ======================================================
    --  ���������i�p�����[�^�`�F�b�N�E�v���t�@�C���擾�j(A-1)
    -- ======================================================
    init(
        iv_flex_value_set_name  -- �l�Z�b�g��
      , lv_errbuf               -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  AFF�l�̒��o�E�t�@�C���o�͏��� (A-2)
    -- =====================================================
    data_outbound_proc1(
        iv_flex_value_set_name  -- �l�Z�b�g��
      , lv_errbuf               -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  AFF�K�w�̒��o�E�t�@�C���o�͏��� (A-3)
    -- =====================================================
    data_outbound_proc2(
        iv_flex_value_set_name  -- �l�Z�b�g��
      , lv_errbuf               -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  AFF�֘A�l�̒��o�E�t�@�C���o�͏��� (A-4)
    -- =====================================================
    data_outbound_proc3(
        iv_flex_value_set_name  -- �l�Z�b�g��
      , lv_errbuf               -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode              -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �Ǘ��e�[�u���o�^�E�X�V���� (A-5)
    -- =====================================================
    -- �Ǘ��e�[�u���o�^�E�X�V�������s���B
    upd_oic_ctrl_tbl(
        iv_flex_value_set_name  -- �l�Z�b�g��
      , lv_errbuf             -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode            -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    IF ( lv_retcode = cv_status_error ) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
      errbuf                  OUT VARCHAR2      -- �G���[�E���b�Z�[�W   # �Œ� #
    , retcode                 OUT VARCHAR2      -- ���^�[���E�R�[�h     # �Œ� #
    , iv_flex_value_set_name  IN  VARCHAR2      -- �l�Z�b�g��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_msgbuf          VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    ln_cnt             NUMBER := 0;     -- ����
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        iv_flex_value_set_name   -- �l�Z�b�g��
      , lv_errbuf                -- �G���[�E���b�Z�[�W            # �Œ� #
      , lv_retcode               -- ���^�[���E�R�[�h              # �Œ� #
      , lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  # �Œ� #
    );
--
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�}��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ''
      );
    END IF;
--
    -- =============
    -- A-6�D�I������
    -- =============
    -- A-6-1�D���ׂẴt�@�C�����N���[�Y����
    -- =====================================
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand1 )) THEN      -- AFF�l�A�g�f�[�^�t�@�C��
      UTL_FILE.FCLOSE( gf_file_hand1 );
    END IF;
    --
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand2 )) THEN      -- AFF�K�w�A�g�f�[�^�t�@�C��
      UTL_FILE.FCLOSE( gf_file_hand2 );
    END IF;
    --
    IF ( UTL_FILE.IS_OPEN ( gf_file_hand3 )) THEN      -- AFF�֘A�l�A�g�f�[�^�t�@�C��
      UTL_FILE.FCLOSE( gf_file_hand3 );
    END IF;
--
    -- A-6-2�D���o�������o�͂���
    -- =========================
    -- 1.AFF�̒��o�������o�͂���B
    ln_cnt := gn_target1_cnt;                                             -- AFF�l�A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- �����ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60009                 -- �l�Z�b�g�̒l
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- ���o����
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 2.AFF�K�w�i����j�̒��o�������o�͂���B
    ln_cnt := gn_target2_dpt_cnt;                                         -- AFF�K�w�i����j�A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- �����ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60010                 -- AFF�K�w�i����j
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- ���o����
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 3.AFF�K�w�i����Ȗځj�̒��o�������o�͂���B
    ln_cnt := gn_target2_acc_cnt;                                         -- AFF�K�w�i����Ȗځj�A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- �����ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60011                 -- AFF�K�w�i����Ȗځj
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- ���o����
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 4.AFF�֘A�l�A�g�̒��o�������o�͂���B
    ln_cnt := gn_target3_cnt;                                             -- AFF�֘A�l�A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60006                 -- �����ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => cv_msg_cmm1_60012                 -- (AFF�֘A�l)
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- ���o����
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- A-6-3�D�o�͌������o�͂���
    -- =========================
    -- �G���[���̌����\��
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target1_cnt     := 0;                    -- AFF�l�A�g�t�@�C���̏o�͌���
      gn_target2_dpt_cnt := 0;                    -- AFF�K�w�i����j�A�g�t�@�C���̏o�͌���
      gn_target2_acc_cnt := 0;                    -- AFF�K�w�i����Ȗځj�A�g�t�@�C���̏o�͌���
      gn_target3_cnt     := 0;                    -- AFF�֘A�l�A�g�t�@�C���̏o�͌���
      gn_normal_cnt      := 0;                    -- ��������
      gn_error_cnt       := 1;                    -- �G���[����
    END IF;
--
    -- 1.AFF�l�A�g�t�@�C���o�͌����o��
    ln_cnt := gn_target1_cnt;                                             -- AFF�l�A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60007                 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => gv_data_filename1                 -- AFF�l�A�g�f�[�^�t�@�C��
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- �o�͌���
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 2.AFF�K�w�A�g�t�@�C���o�͌����o��
    ln_cnt := gn_target2_dpt_cnt + gn_target2_acc_cnt;                    -- AFF�K�w�A�g�̌����i���� + ����Ȗځj
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60007                 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => gv_data_filename2                 -- FF�K�w�A�g�f�[�^�t�@�C��
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- �o�͌���
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
--
    -- 3.FF�֘A�l�A�g�t�@�C���o�͌����o��
    ln_cnt := gn_target3_cnt;                                             -- AFF�֘A�l�A�g�̌���
    lv_msgbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cmm                    -- 'XXCMM'
                    , iv_name         => cv_msg_cmm1_60007                 -- �t�@�C���o�͑ΏہE�������b�Z�[�W
                    , iv_token_name1  => cv_tkn_target                     -- �g�[�N��(TARGET)
                    , iv_token_value1 => gv_data_filename3                 -- AFF�֘A�l�A�g�f�[�^�t�@�C��
                    , iv_token_name2  => cv_tkn_count                      -- �g�[�N��(COUNT)
                    , iv_token_value2 => TO_CHAR(ln_cnt, cv_comma_edit)    -- �o�͌���
                   );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --
    -- A-6-4�D�Ώی����A�����I/F�t�@�C���ւ̏o�͌����i���������^�G���[�����j���o�͂���
    -- ================================================================================
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt, cv_comma_edit)    -- �Ώی���
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt, cv_comma_edit)    -- ��������
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt, cv_comma_edit)    -- �G���[����
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --
    -- A-6-5�D�I���X�e�[�^�X�ɂ��A�Y�����鏈���I�����b�Z�[�W���o�͂���
    -- =================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --�X �e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM006A07C;
/
