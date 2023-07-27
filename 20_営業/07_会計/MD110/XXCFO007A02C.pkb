CREATE OR REPLACE PACKAGE BODY APPS.XXCFO007A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO007A02C (body)
 * Description      : EBS AP�I�[�v���C���^�t�F�[�X�̓o�^���ꂽ�f�[�^�𒊏o�AERP Cloud��AP�W���e�[�u���ɓo�^����B
 * MD.050           : T_MD050_CFO_007_A02_���F�ώd���搿�������o_EBS�R���J�����g
 * Version          : 1.4
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  output_ap_data         I/F�t�@�C���o��(A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022-12-27    1.0   Yamato.Fuku      �V�K�쐬
 *  2023-01-12    1.1   Yamato.Fuku      E132�Ή��ƓE�v�̐؂�̂Ă�Ή�
 *  2023-01-16    1.2   Yamato.Fuku      E133�Ή�
 *  2023-01-16    1.3   Yamato.Fuku      E134�Ή�
 *  2023-03-13    1.4   Y.Ooyama         �V�i���I�e�X�g�s�No.0065�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_dir_get_expt       EXCEPTION;                                     -- �f�B���N�g���t���p�X�擾�G���[
  -- ���b�N�G���[��O
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCFO007A02C';      -- �p�b�P�[�W�� 
--
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff            CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo            CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi            CONSTANT VARCHAR2(5)   := 'XXCOI';
  --
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  --
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;              -- �t�@�C���T�C�Y
  cv_delim_comma            CONSTANT VARCHAR2(1)    := ',';                -- �J���}
  cv_underbar               CONSTANT VARCHAR2(1)    := '_';                -- �A���_�[�o�[
  cv_open_mode_w            CONSTANT VARCHAR2(1)    := 'w';                -- �t�@�C���I�[�v�����[�h�i�㏑���j
  cv_xx03_entry             CONSTANT VARCHAR2(15)   := 'XX03_ENTRY';       -- �������
  cv_ers                    CONSTANT VARCHAR2(15)   := 'ERS';              -- �w��
  cv_mfg_account            CONSTANT VARCHAR2(15)   := 'MFG_ACCOUNT';      -- �H���v
  cv_bm_system              CONSTANT VARCHAR2(15)   := 'BM_SYSTEM';        -- �≮�x��
  cv_sales_deduction        CONSTANT VARCHAR2(15)   := 'SALES_DEDUCTION';  -- �̔��T��
  cv_xx03_entry_short       CONSTANT VARCHAR2(7)    := 'ENTRY';            -- �������_�Z�k��
  cv_ers_short              CONSTANT VARCHAR2(7)    := 'ERS';              -- �w��_�Z�k��
  cv_mfg_account_short      CONSTANT VARCHAR2(7)    := 'MFG_ACT';          -- �H���v_�Z�k��
  cv_bm_system_short        CONSTANT VARCHAR2(7)    := 'BM_SYS';           -- �≮�x��_�Z�k��
  cv_sales_deduction_short  CONSTANT VARCHAR2(7)    := 'SL_DDC';           -- �̔��T��_�Z�k��
  cv_lf_str                 CONSTANT VARCHAR2(2)    := '\n';               -- LF�u���P��
  cv_status                 CONSTANT VARCHAR2(9)    := 'PROCESSED';        -- �X�e�[�^�XPROCESSED
  cv_lookup_code_tax        CONSTANT VARCHAR2(3)    := 'TAX';              -- lookup_code:TAX
  cv_attribute_category     CONSTANT VARCHAR2(8)    := 'SALES-BU';         -- attribute_category:SALES-BU
  cv_date_format            CONSTANT VARCHAR2(10)   := 'YYYY/MM/DD';       -- ���t�̃t�H�[�}�b�g
  cn_zero                   CONSTANT NUMBER         := 0;                  -- 0
  cn_hundred                CONSTANT NUMBER         := 100;                -- 100
  cn_utf8_size              CONSTANT NUMBER         := 240;                -- 240
  cv_flag_y                 CONSTANT VARCHAR2(1)    := 'Y';                -- ������:Y  
  cv_flag_n                 CONSTANT VARCHAR2(1)    := 'N';                -- ������:N  
  --�v���t�@�C��
  -- XXCFO:OIC�A�gAP�f�[�^�t�@�C���i�[�f�B���N�g����
  cv_oic_ap_out_file_dir    CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_AP_OUT_FILE_DIR';
  -- XXCFO:���F�ώd���搿����HEAD�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_head_filename          CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_AP_INV_H_OUT_FILE';
  -- XXCFO:���F�ώd���搿����LINE(�{��)�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_line_filename          CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_AP_INV_L_OUT_FILE';
-- Ver1.1(E132) Add Start
  -- XXCFO:AP�E�v�؂�̂ăt���O
  cv_desc_trim_flag         CONSTANT VARCHAR2(100) := 'XXCFO1_OIC_DESC_TRIM_FLAG';
-- Ver1.1(E132) End Start
  --���b�Z�[�W
  cv_msg_cfo_00001          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';   -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00019          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';   -- ���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';   -- �X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';   -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_00027          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';   -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00029          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';   -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';   -- �t�@�C�������݃G���[���b�Z�[�W
  cv_msg_coi_00029          CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';   -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_60001          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60001';   -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_cfo_60002          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60002';   -- IF�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_60004          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60004';   -- �����ΏہE�������b�Z�[�W
  cv_msg_cfo_60005          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60005';   -- �t�@�C���o�͑ΏہE�������b�Z�[�W
  cv_msg_cfo_60009          CONSTANT VARCHAR2(20) := 'APP-XXCFO1-60009';   -- �p�����[�^�K�{�G���[���b�Z�[�W
  --�g�[�N���R�[�h
  cv_tkn_param_val          CONSTANT VARCHAR2(20)  := 'PARAM_VAL';         -- �p�����[�^�l
  cv_tkn_prof_name          CONSTANT VARCHAR2(20)  := 'PROF_NAME';         -- �v���t�@�C����
  cv_tkn_dir_tok            CONSTANT VARCHAR2(20)  := 'DIR_TOK';           -- �f�B���N�g����
  cv_tkn_file_name          CONSTANT VARCHAR2(20)  := 'FILE_NAME';         -- �t�@�C����
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';             -- �e�[�u����
  cv_tkn_errmsg             CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- SQL�G���[���b�Z�[�W
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';           -- �g�[�N����(SQLERRM)
  cv_tkn_param_name         CONSTANT VARCHAR2(30)  := 'PARAM_NAME';        -- �p�����[�^��
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';            -- �^�[�Q�b�g
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';             -- �J�E���g
  --���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo_60021       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60021';  -- �\�[�X
  cv_msgtkn_cfo_60022       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60022';  -- AP������OIF
  cv_msgtkn_cfo_60023       CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-60023';  -- AP������LINE
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- XXCFO:OIC�A�gAP�f�[�^�t�@�C���i�[�f�B���N�g����
  gv_dir_name           VARCHAR2(1000);
  -- XXCFO:���F�ώd���搿����HEAD�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gv_if_file_name_head  VARCHAR2(1000);
  -- XXCFO:���F�ώd���搿����LINE(�{��)�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gv_if_file_name_line  VARCHAR2(1000);
-- Ver1.1(E132) Add Start
  -- XXCFO:AP�E�v�؂�̂ăt���O
  gv_desc_trim_flag     VARCHAR2(1000);
-- Ver1.1(E132) Add Start
  gt_directory_path all_directories.directory_path%TYPE;       -- �f�B���N�g���p�X
  gv_source_short_name  VARCHAR2(7);                           -- �Z�k��
  gn_head_cnt           NUMBER;                                -- HEAD�o�͌���
  gn_line_cnt           NUMBER;                                -- LINE�o�͌���
-- Ver1.1(E132) Add Start
--
  /**********************************************************************************
   * Procedure Name   : get_utf8_size_char
   * Description      : SJIS��UTF8�ϊ���̌������Z�o���A�w��̌����𒴉߂����ꍇ��
   *                    �w��̌����Ŋi�[�ł���l�ASJIS�e�L�X�g��؂�̂Ă����l��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION get_utf8_size_char(
    in_number_of_digits IN NUMBER   -- 1.����
   ,iv_sjis_text        IN VARCHAR2 -- 2.SJIS�e�L�X�g
  ) RETURN VARCHAR2 IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'XXCVRETS0021C.get_utf8_size_char'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    ln_digits_cnt  NUMBER;         -- ����
    lv_return_text VARCHAR2(2000); -- �߂�l���i�[
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
    -- ===============================
    -- �����l�ݒ�
    -- ===============================
    ln_digits_cnt  := in_number_of_digits; -- ����
    lv_return_text := iv_sjis_text;        -- ������
--
    -- ===============================
    -- ������؂�̂ď���
    -- ===============================
    IF lv_return_text IS NOT NULL THEN
      <<truncation_loop>>
      LOOP
        -- UTF8�ϊ���̕����񂪌����ȉ��̏ꍇ
        IF (LENGTHB(CONVERT(lv_return_text,'UTF8')) <= in_number_of_digits ) THEN
          -- �����ȉ��Ȃ̂�LOOP�𔲂���
          EXIT truncation_loop;
        ELSE
          -- �����񂩂�1�o�C�g�폜
          ln_digits_cnt  := ln_digits_cnt - 1;
          lv_return_text := SUBSTR(lv_return_text,1,ln_digits_cnt);
        END IF;
      END LOOP truncation_loop;
    END IF;
--
--
    -- �؂�̂Č�̒l��߂�
    RETURN lv_return_text;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_utf8_size_char;
--
-- Ver1.1(E132) Add End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_source     IN  VARCHAR2,     --   �\�[�X
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lv_pd_param       VARCHAR2(100)   DEFAULT NULL;                     -- ���b�Z�[�W�擾�p
    lv_msg            VARCHAR2(300)   DEFAULT NULL;                     -- ���b�Z�[�W�o�͗p
    -- �t�@�C�����݃`�F�b�N�p
    lb_exists         BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length    NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size     BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �p�����[�^�o��
    --==============================================================
    lv_pd_param := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo      -- XXCFO
                                            , cv_msgtkn_cfo_60021 -- �\�[�X
                                           );
    --
    lv_msg := xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo            -- XXCFO
                                       , cv_msg_cfo_60001          -- �p�����[�^�o�̓��b�Z�[�W
                                       , cv_tkn_param_name         -- PARAM_NAME
                                       , lv_pd_param               -- �\�[�X
                                       , cv_tkn_param_val          -- PARAM_VAL
                                       , iv_source                 -- �\�[�X
                                      );
    --���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
    );
    --���O�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => ''
    );
--
    --==============================================================
    -- 1.���̓p�����[�^�̕K�{�`�F�b�N
    --==============================================================
    IF ( iv_source IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo         -- XXCFO
                               , cv_msg_cfo_60009       -- �p�����[�^�K�{�G���[���b�Z�[�W
                               , cv_tkn_param_name      -- �g�[�N�����F�p�����[�^��
                               , lv_pd_param            -- �g�[�N���l�FXXCFO1_OIC_AP_OUT_FILE_DIR
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
    -- ==============================================================
    -- 2.�v���t�@�C���̎擾
    -- ==============================================================
    -- OIC�A�gAP�f�[�^�t�@�C���i�[�f�B���N�g����
    gv_dir_name := FND_PROFILE.VALUE( cv_oic_ap_out_file_dir );
--
    IF ( gv_dir_name IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo         -- XXCFO
                               , cv_msg_cfo_00001       -- �v���t�@�C�����擾�G���[���b�Z�[�W
                               , cv_tkn_prof_name       -- �g�[�N�����F�v���t�@�C����
                               , cv_oic_ap_out_file_dir -- �g�[�N���l�FXXCFO1_OIC_AP_OUT_FILE_DIR
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���F�ώd���搿����HEAD�A�g�f�[�^�t�@�C�����iOIC�A�g�j
    gv_if_file_name_head := FND_PROFILE.VALUE ( cv_head_filename ) ;
--
    IF ( gv_if_file_name_head IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- �v���t�@�C�����擾�G���[���b�Z�[�W
                               , cv_tkn_prof_name      -- �g�[�N�����F�v���t�@�C����
                               , cv_head_filename      -- �g�[�N���l�FXXCFO1_OIC_GL_JE_L_ERP_IN_FILE
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ���F�ώd���搿����LINE(�{��)�A�g�f�[�^�t�@�C�����iOIC�A�g�j
    gv_if_file_name_line := FND_PROFILE.VALUE ( cv_line_filename ) ;
--
    IF ( gv_if_file_name_line IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- �v���t�@�C�����擾�G���[���b�Z�[�W
                               , cv_tkn_prof_name      -- �g�[�N�����F�v���t�@�C����
                               , cv_line_filename      -- �g�[�N���l�FXXCFO1_OIC_AP_INV_L_OUT_FILE
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1(E132) Add Start
--
    -- XXCFO:AP�E�v�؂�̂ăt���O
    gv_desc_trim_flag := FND_PROFILE.VALUE ( cv_desc_trim_flag ) ;
--
    IF ( gv_desc_trim_flag IS NULL ) THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_cfo        -- XXCFO
                               , cv_msg_cfo_00001      -- �v���t�@�C�����擾�G���[���b�Z�[�W
                               , cv_tkn_prof_name      -- �g�[�N�����F�v���t�@�C����
                               , cv_desc_trim_flag     -- �g�[�N���l�FXXCFO1_OIC_DESC_TRIM_FLAG
                              )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
-- Ver1.1(E132) Add End
    -- ==============================================================
    -- 3.�v���t�@�C���l�uXXCFO:OIC�A�gAP�f�[�^�t�@�C���i�[�f�B���N�g�����v����f�B���N�g���p�X���擾����B
    -- ==============================================================
    BEGIN
      SELECT 
        RTRIM( ad.directory_path , cv_slash ) AS directory_path
      INTO 
        gt_directory_path
      FROM 
        all_directories ad
      WHERE 
        ad.directory_name = gv_dir_name;
      -- ���R�[�h�͑��݂��邪�f�B���N�g���p�X��null�̏ꍇ�A�G���[
      IF ( gt_directory_path IS NULL ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                              (
                                 cv_msg_kbn_coi          -- XXCOI
                               , cv_msg_coi_00029        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
                               , cv_tkn_dir_tok          -- �g�[�N�����F�f�B���N�g����
                               , gv_dir_name             -- �g�[�N���l�Fgv_dir_name
                              )
                             , 1
                             , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_dir_get_expt;
      END IF;
    -- ���R�[�h���擾�ł��Ȃ��ꍇ�A�G���[
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg :=  SUBSTRB ( xxccp_common_pkg.get_msg
                             (
                                cv_msg_kbn_coi          -- XXCOI
                              , cv_msg_coi_00029        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
                              , cv_tkn_dir_tok          -- �g�[�N�����F�f�B���N�g����
                              , gv_dir_name             -- �g�[�N���l�Fgv_dir_name
                             )
                            , 1
                            , 5000
                           );
      lv_errbuf :=  lv_errmsg;
      RAISE global_dir_get_expt;
    END;
--
    -- ==============================================================
    -- 4.���̓p�����[�^�u�\�[�X�v���A�t�@�C�����Ɏg�p����Z�k�������肵�܂��B
    -- ==============================================================
    CASE WHEN cv_ers             = iv_source THEN
           gv_source_short_name := cv_ers_short;
         WHEN cv_bm_system       = iv_source THEN
           gv_source_short_name := cv_bm_system_short;
         WHEN cv_mfg_account     = iv_source THEN
           gv_source_short_name := cv_mfg_account_short;
         WHEN cv_xx03_entry      = iv_source THEN
           gv_source_short_name := cv_xx03_entry_short;
         WHEN cv_sales_deduction = iv_source THEN
           gv_source_short_name := cv_sales_deduction_short;
         ELSE
           NULL;
    END CASE;
--
  EXCEPTION
    WHEN global_dir_get_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
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
   * Procedure Name   : output_ap_data
   * Description      : I/F�t�@�C���o��(A-2)
   ***********************************************************************************/
  PROCEDURE output_ap_data(
    iv_source     IN  VARCHAR2,     --   �\�[�X
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_ap_data'; -- �v���O������
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
    lf_file_handle1    UTL_FILE.FILE_TYPE;                           -- CSV�t�@�C���n���h��
    lv_data_filename1  VARCHAR2(100);                                -- HEAD�f�[�^�t�@�C����
    lf_file_handle2    UTL_FILE.FILE_TYPE;                           -- CSV�t�@�C���n���h��
    lv_data_filename2  VARCHAR2(100);                                -- LINE�f�[�^�t�@�C����
    lv_msgbuf          VARCHAR2(5000);                               -- ���[�U�[�E���b�Z�[�W
    lv_csv_text        VARCHAR2(30000)DEFAULT NULL;                  -- �o�͂P�s��������ϐ�
    lt_attribute12     ap_invoice_lines_interface.attribute12%TYPE;  -- �d�q���땔����͐�����ID/���הԍ��㏑���p�ϐ�
    -- �t�@�C���o�͊֘A
    lb_fexists          BOOLEAN;                                     -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                                      -- �t�@�C���̒���
    ln_block_size       NUMBER;                                      -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���F�ώd���搿����HEAD�J�[�\��
    CURSOR ap_head_cur
      IS
        SELECT 
            aii.invoice_id
          , cv_attribute_category as operating_unit
          , aii.source
          , aii.invoice_num
          , aii.invoice_amount
          , TO_CHAR( aii.invoice_date , cv_date_format ) as invoice_date
-- Ver1.2(E133) Mod Start
--          , avv.vendor_number as vendor_num
--          , avsv.vendor_site_code
          , CASE WHEN aii.vendor_id IS NULL 
              THEN aii.vendor_num
              ELSE avv.vendor_number
            END as vendor_num
          , CASE WHEN aii.vendor_site_id IS NULL
              THEN aii.vendor_site_code
              ELSE avsv.vendor_site_code
            END as vendor_site_code
-- Ver1.2(E133) Mod End
          , aii.invoice_currency_code
          , aii.description
          , aii.invoice_type_lookup_code
-- Ver1.2(E133) Mod Start
--          , at.name as terms_name
          , CASE WHEN aii.terms_id IS NULL
              THEN aii.terms_name
              ELSE at.name
            END as terms_name
-- Ver1.2(E133) Mod End
          , TO_CHAR( aii.terms_date , cv_date_format ) as terms_date
          , TO_CHAR( aii.gl_date , cv_date_format ) as gl_date
          , aii.pay_group_lookup_code as payment_method_code
          , aii.prepay_num
          , TO_CHAR( aii.prepay_gl_date , cv_date_format ) as prepay_gl_date
          , aii.exchange_rate_type
          , '�d����x���p�_�~�[' as pay_group
          , TO_CHAR( aii.exchange_date , cv_date_format ) as exchange_date
          , aii.exchange_rate
          , gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4 || '-' || 
              gcc.segment5 || '-' || gcc .segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 as accts_pay_code_concatenated
          , cv_attribute_category as attribute_category
          , aii.attribute1
          , aii.attribute2
          , aii.attribute3
          , aii.attribute4
          , aii.attribute5
          , aii.attribute6
          , aii.attribute7
          , aii.attribute8
          , aii.attribute9
          , aii.attribute10
          , aii.attribute11
          , aii.attribute12
          , aii.attribute13
          , aii.attribute14
          , aii.attribute15
        FROM 
            ap_invoices_interface aii
          , ap_vendors_v avv
          , ap_vendor_sites_v avsv
          , ap_terms at
          , gl_code_combinations gcc
        WHERE 
              aii.vendor_id = avv.vendor_id(+)
          AND aii.vendor_site_id = avsv.vendor_site_id(+)
          AND aii.terms_id = at.term_id(+)
          AND aii.accts_pay_code_combination_id = gcc.code_combination_id(+)
          AND (aii.status <> cv_status OR aii.status IS NULL)
          AND aii.source = iv_source
        FOR UPDATE OF aii.vendor_id NOWAIT
        ;
    ap_head_rec ap_head_cur%ROWTYPE;
--
    -- ���F�ώd���搿����LINE�J�[�\��
    CURSOR ap_line_cur
      IS
        SELECT 
            rec.invoice_id
          , rec.line_number
          , rec.line_type_lookup_code
          , rec.amount
          , rec.description
          , rec.dist_code_concatenated
          , rec.tax_code as tax_classification_code
          , CASE
              WHEN ( rec.amount <> cn_zero AND rec.tax_rate = cn_zero ) THEN cn_hundred
              ELSE NULL
            END as tax_rate
          , rec.tax_code
          , CASE 
-- Ver1.4 Mod Start
--              WHEN sum_rec.sum_amount > cn_zero THEN cv_flag_y
              WHEN sum_rec.sum_amount <> cn_zero THEN cv_flag_y
-- Ver1.4 Mod End
              ELSE cv_flag_n
            END as prorate_across_flag
          , row_num.line_group_number
          , rec.attribute_category
          , rec.attribute1
          , rec.attribute2
          , rec.attribute3
          , rec.attribute4
          , rec.attribute5
          , rec.attribute6
          , rec.attribute7
          , rec.attribute8
          , rec.attribute9
          , rec.attribute10
          , rec.attribute11
          , rec.attribute12
          , rec.attribute13
          , rec.attribute14
          , rec.attribute15
        FROM (
          SELECT
              aili.invoice_id
            , aili.line_number
            , aili.line_type_lookup_code
            , aili.amount
            , aili.description
-- Ver1.1(E132) Mod Start
--            , CASE WHEN aili.dist_code_concatenated IS NOT NULL THEN aili.dist_code_concatenated
            , CASE WHEN aili.dist_code_concatenated IS NOT NULL THEN 
                   regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 1) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 2) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3)
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 4) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 5) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 6) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 7) || '-'
                || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 8)
-- Ver1.1(E132) Add End
                ELSE gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4 
                  || '-' ||  gcc.segment5 || '-' || gcc.segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 
              END as dist_code_concatenated
            , aili.tax_code
            , NULL as tax_rate
            , cv_attribute_category as attribute_category
            , aili.attribute1
            , aili.attribute2
            , aili.attribute3
            , aili.attribute4
            , aili.attribute5
            , aili.attribute6
            , aili.attribute7
            , aili.attribute8
            , aili.attribute9
            , aili.attribute10
            , aili.tax_code as attribute11
            , aili.attribute12
            , aili.attribute13
            , aili.attribute14
            , aili.attribute15
          FROM
              ap_invoice_lines_interface aili
            , gl_code_combinations gcc
            , ap_invoices_interface aii
          WHERE
                aii.invoice_id = aili.invoice_id
            AND aili.dist_code_combination_id = gcc.code_combination_id(+)
            AND aili.line_type_lookup_code <> cv_lookup_code_tax
            AND (aii.status <> cv_status OR aii.status IS NULL)
            AND aii.source = iv_source
          UNION ALL
          SELECT
              aili.invoice_id
            , MIN(aili.line_number) as line_number
            , aili.line_type_lookup_code
            , SUM(aili.amount) as amount
            , MIN(aili.description) as description
            , CASE 
-- Ver1.1(E132) Mod Start
--                WHEN aili.dist_code_concatenated IS NOT NULL THEN aili.dist_code_concatenated
                WHEN aili.dist_code_concatenated IS NOT NULL THEN 
                     regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 1) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 2) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3)
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 4) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 5) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 6) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 7) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 8)
-- Ver1.1(E132) Mod End
                  ELSE gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4
                    || '-' || gcc.segment5 || '-' || gcc.segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 
              END as dist_code_concatenated
            , aili.tax_code
            , atca.tax_rate
            , cv_attribute_category as attribute_category
            , aili.attribute1
            , aili.attribute2
            , aili.attribute3
            , aili.attribute4
            , aili.attribute5
            , aili.attribute6
            , aili.attribute7
            , aili.attribute8
            , aili.attribute9
            , aili.attribute10
            , aili.tax_code as attribute11
            , aili.attribute12
            , aili.attribute13
            , aili.attribute14
            , aili.attribute15
          FROM
              ap_invoice_lines_interface aili
            , gl_code_combinations gcc
            , ap_invoices_interface aii
            , ap_tax_codes_all atca
            , hr_operating_units hou
          WHERE
                aii.invoice_id = aili.invoice_id
            AND aili.dist_code_combination_id = gcc.code_combination_id(+)
            AND aili.org_id = hou.organization_id
            AND hou.set_of_books_id = atca.set_of_books_id
            AND aili.tax_code = atca.name
            AND aili.line_type_lookup_code = cv_lookup_code_tax 
            AND (aii.status <> cv_status OR aii.status IS NULL)
            AND aii.source = iv_source
          GROUP BY 
              aili.invoice_id
            , aili.line_type_lookup_code
            , CASE 
-- Ver1.1(E132) Mod Start
--                WHEN aili.dist_code_concatenated IS NOT NULL THEN aili.dist_code_concatenated
                WHEN aili.dist_code_concatenated IS NOT NULL THEN 
                     regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 1) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 2) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 3)
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 4) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 5) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 6) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 7) || '-'
                  || regexp_substr( aili.dist_code_concatenated , '[^\-]+' , 1, 8)
-- Ver1.1(E132) Mod End
                  ELSE gcc.segment1 || '-' || gcc.segment2 || '-' || gcc.segment3 || '-' || gcc.segment3 || gcc.segment4 
                    || '-' || gcc.segment5 || '-' ||  gcc.segment6 || '-' || gcc.segment7 || '-' || gcc.segment8 
              END
            , aili.tax_code
            , atca.tax_rate
            , cv_attribute_category
            , aili.attribute1
            , aili.attribute2
            , aili.attribute3
            , aili.attribute4
            , aili.attribute5
            , aili.attribute6
            , aili.attribute7
            , aili.attribute8
            , aili.attribute9
            , aili.attribute10
            , aili.tax_code
            , aili.attribute12
            , aili.attribute13
            , aili.attribute14
            , aili.attribute15
          ) rec ,
          (SELECT
               lgn.invoice_id
             , lgn.tax_code
             , ROW_NUMBER()OVER(PARTITION BY lgn.invoice_id ORDER BY lgn.line_number) as line_group_number 
           FROM 
             (SELECT DISTINCT
                  aili.invoice_id
                , aili.tax_code
                , MIN(aili.line_number) line_number
              FROM 
                  ap_invoice_lines_interface aili
              GROUP BY 
                  aili.invoice_id
                , aili.tax_code
             )lgn
          ) row_num,
          (SELECT
               aili.invoice_id
             , aili.tax_code
             , SUM(aili.amount) as sum_amount
           FROM 
             ap_invoice_lines_interface aili
           WHERE 
             aili.line_type_lookup_code <> cv_lookup_code_tax
           GROUP BY 
               aili.invoice_id
             , aili.tax_code
          ) sum_rec
        WHERE 
              rec.invoice_id = row_num.invoice_id
          AND rec.tax_code = row_num.tax_code
          AND rec.invoice_id = sum_rec.invoice_id
          AND rec.tax_code = sum_rec.tax_code
        ORDER BY 
            rec.invoice_id
          , rec.line_number
      ;
    ap_line_rec ap_line_cur%ROWTYPE;
--
    -- *** ���[�J���E���R�[�h ***
--
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
    -- �ϐ��̏�����
    lv_csv_text := NULL;
    gn_head_cnt := 0;
    gn_line_cnt := 0;
--
    -- �o�̓t�@�C�������ׂăI�[�v������B
    gt_directory_path := gt_directory_path || cv_slash;
    lv_data_filename1 := xxccp_common_pkg.char_delim_partition( gv_if_file_name_head , cv_msg_cont , 1 ) || 
                           cv_underbar || gv_source_short_name || cv_msg_cont ||
                             xxccp_common_pkg.char_delim_partition( gv_if_file_name_head , cv_msg_cont , 2 );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo                          -- 'XXCFO'
                                     , cv_msg_cfo_60002                        -- IF�t�@�C�����o�̓��b�Z�[�W
                                     , cv_tkn_file_name                        -- �g�[�N��(FILE_NAME)
                                     , gt_directory_path || lv_data_filename1  -- �t�@�C���p�X/���F�ώd���搿����HEAD�A�g�f�[�^�t�@�C����
                                     );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
-- 
    -- ����t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR( gt_directory_path
                 , lv_data_filename1                                  -- HEAD�f�[�^�t�@�C����
                 , lb_fexists
                 , ln_file_size
                 , ln_block_size );
--
    -- ����t�@�C�����݃G���[���b�Z�[�W
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo    -- 'XXCFO'
                                                     , cv_msg_cfo_00027  -- ����t�@�C�����݃G���[���b�Z�[�W
                                                    )
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �t�@�C���I�[�v��
    BEGIN
      lf_file_handle1 := UTL_FILE.FOPEN( gt_directory_path , lv_data_filename1 , cv_open_mode_w , cn_max_linesize );
    EXCEPTION
      -- �t�@�C���I�[�v���G���[ 
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                         cv_msg_kbn_cfo      -- XXCFO
                                                       , cv_msg_cfo_00029    -- �t�@�C���I�[�v���G���[���b�Z�[�W
                                                      )
                              , 1
                              , 5000
                             );
        lv_errbuf := lv_errmsg;
        --��O�\���́A��ʃ��W���[���ōs���B
        RAISE global_process_expt;
    END;
--
    lv_data_filename2 := xxccp_common_pkg.char_delim_partition( gv_if_file_name_line , cv_msg_cont , 1 ) || 
                           cv_underbar || gv_source_short_name || cv_msg_cont ||
                             xxccp_common_pkg.char_delim_partition( gv_if_file_name_line , cv_msg_cont , 2 );
    lv_msgbuf := xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo                          -- 'XXCFO'
                                     , cv_msg_cfo_60002                        -- IF�t�@�C�����o�̓��b�Z�[�W
                                     , cv_tkn_file_name                        -- �g�[�N��(FILE_NAME)
                                     , gt_directory_path || lv_data_filename2  -- �t�@�C���p�X/���F�ώd���搿����LINE�A�g�f�[�^�t�@�C����
                                     );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msgbuf
    );
    --��s�}��
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
-- 
    -- ����t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR( gt_directory_path
                 , lv_data_filename2                                  -- LINE�f�[�^�t�@�C����
                 , lb_fexists
                 , ln_file_size
                 , ln_block_size );
--
    -- ����t�@�C�����݃G���[���b�Z�[�W
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(  cv_msg_kbn_cfo    -- 'XXCFO'
                                                     , cv_msg_cfo_00027  -- ����t�@�C�����݃G���[���b�Z�[�W
                                                    )
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- �t�@�C���I�[�v��
    BEGIN
      lf_file_handle2 := UTL_FILE.FOPEN( gt_directory_path , lv_data_filename2 , cv_open_mode_w , cn_max_linesize );
    EXCEPTION
      -- �t�@�C���I�[�v���G���[ 
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                                         cv_msg_kbn_cfo      -- XXCFO
                                                       , cv_msg_cfo_00029    -- �t�@�C���I�[�v���G���[���b�Z�[�W
                                                      )
                              , 1
                              , 5000
                             );
        lv_errbuf := lv_errmsg;
        --��O�\���́A��ʃ��W���[���ōs���B
        RAISE global_process_expt;
    END;
--
    -- ���F�ώd���搿����HEAD���o
    BEGIN
      <<cur_ap_head_recode_loop>> 
      FOR ap_head_rec IN ap_head_cur LOOP
        lv_csv_text := NULL;
        -- HEAD�f�[�^�s�̍쐬
        lv_csv_text :=                ap_head_rec.invoice_id                  || cv_delim_comma;  -- 1:INVOICE_ID
        lv_csv_text := lv_csv_text || ap_head_rec.operating_unit              || cv_delim_comma;  -- 2:OPERATING_UNIT
        lv_csv_text := lv_csv_text || ap_head_rec.source                      || cv_delim_comma;  -- 3:SOURCE
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_num                 || cv_delim_comma;  -- 4:INVOICE_NUM
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_amount              || cv_delim_comma;  -- 5:INVOICE_AMOUNT
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_date                || cv_delim_comma;  -- 6:INVOICE_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 7:VENDOR_NAME
        lv_csv_text := lv_csv_text || ap_head_rec.vendor_num                  || cv_delim_comma;  -- 8:VENDOR_NUM
        lv_csv_text := lv_csv_text || ap_head_rec.vendor_site_code            || cv_delim_comma;  -- 9:VENDOR_SITE_CODE
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_currency_code       || cv_delim_comma;  -- 10:INVOICE_CURRENCY_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 11:PAYMENT_CURRENCY_CODE
-- Ver1.1(E132) Mod Start
--        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.description , cv_lf_str ) 
--               || cv_delim_comma;                                                               -- 12:DESCRIPTION
        IF ( gv_desc_trim_flag = cv_flag_y ) THEN
-- Ver1.3(E134) Mod Start
--          lv_csv_text := lv_csv_text || get_utf8_size_char( cn_utf8_size , xxccp_oiccommon_pkg.to_csv_string( 
--                 ap_head_rec.description , cv_lf_str )) || cv_delim_comma;                        -- 12:DESCRIPTION
          lv_csv_text := lv_csv_text || '"' || get_utf8_size_char( cn_utf8_size , 
            REPLACE( REPLACE( REPLACE( ap_head_rec.description , '"' , '""' ), CHR(13) , NULL ) , CHR(10) , '\n' )) 
             || '"' || cv_delim_comma;                                                            -- 12:DESCRIPTION
-- Ver1.3(E134) Mod End
        ELSE
          lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.description , cv_lf_str ) 
                 || cv_delim_comma;                                                               -- 12:DESCRIPTION
        END IF;
-- Ver1.1(E132) Mod End
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 13:GROUP_ID
        lv_csv_text := lv_csv_text || ap_head_rec.invoice_type_lookup_code    || cv_delim_comma;  -- 14:INVOICE_TYPE_LOOKUP_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 15:LEGAL_ENTITY_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 16:CUST_REGISTRATION_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 17:CUST_REGISTRATION_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 18:FIRST_PARTY_REGISTRATION_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 19:THIRD_PARTY_REGISTRATION_NUM
        lv_csv_text := lv_csv_text || ap_head_rec.terms_name                  || cv_delim_comma;  -- 20:TERMS_NAME
        lv_csv_text := lv_csv_text || ap_head_rec.terms_date                  || cv_delim_comma;  -- 21:TERMS_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 22:GOODS_RECEIVED_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 23:INVOICE_RECEIVED_DATE
        lv_csv_text := lv_csv_text || ap_head_rec.gl_date                     || cv_delim_comma;  -- 24:GL_DATE
        lv_csv_text := lv_csv_text || ap_head_rec.payment_method_code         || cv_delim_comma;  -- 25:PAYMENT_METHOD_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 26:PAY_GROUP_LOOKUP_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 27:EXCLUSIVE_PAYMENT_FLAG
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 28:AMOUNT_APPLICABLE_TO_DISCOUNT
        lv_csv_text := lv_csv_text || ap_head_rec.prepay_num                  || cv_delim_comma;  -- 29:PREPAY_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 30:PREPAY_LINE_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 31:PREPAY_APPLY_AMOUNT
        lv_csv_text := lv_csv_text || ap_head_rec.prepay_gl_date              || cv_delim_comma;  -- 32:PREPAY_GL_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 33:INVOICE_INCLUDES_PREPAY_FLAG
        lv_csv_text := lv_csv_text || ap_head_rec.exchange_rate_type          || cv_delim_comma;  -- 34:EXCHANGE_RATE_TYPE
        lv_csv_text := lv_csv_text || ap_head_rec.exchange_date               || cv_delim_comma;  -- 35:EXCHANGE_DATE
        lv_csv_text := lv_csv_text || ap_head_rec.exchange_rate               || cv_delim_comma;  -- 36:EXCHANGE_RATE
        lv_csv_text := lv_csv_text || ap_head_rec.accts_pay_code_concatenated || cv_delim_comma;  -- 37:ACCTS_PAY_CODE_CONCATENATED
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 38:DOC_CATEGORY_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 39:VOUCHER_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 40:REQUESTER_FIRST_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 41:REQUESTER_LAST_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 42:REQUESTER_EMPLOYEE_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 43:DELIVERY_CHANNEL_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 44:BANK_CHARGE_BEARER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 45:REMIT_TO_SUPPLIER_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 46:REMIT_TO_SUPPLIER_NUM
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 47:REMIT_TO_ADDRESS_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 48:PAYMENT_PRIORITY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 49:SETTLEMENT_PRIORITY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 50:UNIQUE_REMITTANCE_IDENTIFIER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 51:URI_CHECK_DIGIT
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 52:PAYMENT_REASON_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 53:PAYMENT_REASON_COMMENTS
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 54:REMITTANCE_MESSAGE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 55:REMITTANCE_MESSAGE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 56:REMITTANCE_MESSAGE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 57:AWT_GROUP_NAME
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 58:SHIP_TO_LOCATION
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 59:TAXATION_COUNTRY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 60:DOCUMENT_SUB_TYPE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 61:TAX_INVOICE_INTERNAL_SEQ
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 62:SUPPLIER_TAX_INVOICE_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 63:TAX_INVOICE_RECORDING_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 64:SUPPLIER_TAX_INVOICE_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 65:SUPPLIER_TAX_EXCHANGE_RATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 66:PORT_OF_ENTRY_CODE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 67:CORRECTION_YEAR
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 68:CORRECTION_PERIOD
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 69:IMPORT_DOCUMENT_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 70:IMPORT_DOCUMENT_DATE
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 71:CONTROL_AMOUNT
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 72:CALC_TAX_DURING_IMPORT_FLAG
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 73:ADD_TAX_TO_INV_AMT_FLAG
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute_category , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 74:ATTRIBUTE_CATEGORY
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute1         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 75:ATTRIBUTE1
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute2         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 76:ATTRIBUTE2
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute3         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 77:ATTRIBUTE3
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute4         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 78:ATTRIBUTE4
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute5         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 79:ATTRIBUTE5
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute6         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 80:ATTRIBUTE6
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute7         , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 81:ATTRIBUTE7
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute8         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 82:ATTRIBUTE8
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute9         , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 83:ATTRIBUTE9
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute10        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 84:ATTRIBUTE10
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute11        , cv_lf_str )   
               || cv_delim_comma;                                                                 -- 85:ATTRIBUTE11
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute12        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 86:ATTRIBUTE12
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute13        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 87:ATTRIBUTE13
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute14        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 88:ATTRIBUTE14
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_head_rec.attribute15        , cv_lf_str )  
               || cv_delim_comma;                                                                 -- 89:ATTRIBUTE15
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 90:ATTRIBUTE_NUMBER1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 91:ATTRIBUTE_NUMBER2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 92:ATTRIBUTE_NUMBER3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 93:ATTRIBUTE_NUMBER4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 94:ATTRIBUTE_NUMBER5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 95:ATTRIBUTE_DATE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 96:ATTRIBUTE_DATE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 97:ATTRIBUTE_DATE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 98:ATTRIBUTE_DATE4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 99:ATTRIBUTE_DATE5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 100:GLOBAL_ATTRIBUTE_CATEGORY
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 101:GLOBAL_ATTRIBUTE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 102:GLOBAL_ATTRIBUTE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 103:GLOBAL_ATTRIBUTE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 104:GLOBAL_ATTRIBUTE4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 105:GLOBAL_ATTRIBUTE5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 106:GLOBAL_ATTRIBUTE6
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 107:GLOBAL_ATTRIBUTE7
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 108:GLOBAL_ATTRIBUTE8
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 109:GLOBAL_ATTRIBUTE9
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 110:GLOBAL_ATTRIBUTE10
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 111:GLOBAL_ATTRIBUTE11
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 112:GLOBAL_ATTRIBUTE12
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 113:GLOBAL_ATTRIBUTE13
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 114:GLOBAL_ATTRIBUTE14
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 115:GLOBAL_ATTRIBUTE15
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 116:GLOBAL_ATTRIBUTE16
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 117:GLOBAL_ATTRIBUTE17
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 118:GLOBAL_ATTRIBUTE18
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 119:GLOBAL_ATTRIBUTE19
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 120:GLOBAL_ATTRIBUTE20
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 121:GLOBAL_ATTRIBUTE_NUMBER1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 122:GLOBAL_ATTRIBUTE_NUMBER2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 123:GLOBAL_ATTRIBUTE_NUMBER3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 124:GLOBAL_ATTRIBUTE_NUMBER4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 125:GLOBAL_ATTRIBUTE_NUMBER5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 126:GLOBAL_ATTRIBUTE_DATE1
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 127:GLOBAL_ATTRIBUTE_DATE2
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 128:GLOBAL_ATTRIBUTE_DATE3
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 129:GLOBAL_ATTRIBUTE_DATE4
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 130:GLOBAL_ATTRIBUTE_DATE5
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 131:IMAGE_DOCUMENT_URI
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 132:EXTERNAL_BANK_ACCOUNT_NUMBER
        lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma;  -- 133:EXT_BANK_ACCOUNT_IBAN_NUMBER
        lv_csv_text := lv_csv_text || NULL;                                                       -- 134:REQUESTER_EMAIL_ADDRESS
        BEGIN
          -- �f�[�^�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( lf_file_handle1
                           , lv_csv_text
                           );
          --
          -- �o�͌����J�E���g�A�b�v
          gn_head_cnt := gn_head_cnt + 1;
        EXCEPTION
          WHEN OTHERS THEN
            gn_target_cnt := gn_target_cnt + gn_head_cnt;
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfo            -- XXCFO
                             , cv_msg_cfo_00030          -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                             , cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                             , SQLERRM                   -- �g�[�N���l1�FSQLERRM
                             )
                         , 1
                         , 5000
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP cur_ap_head_recode_loop;
    EXCEPTION
      WHEN global_lock_expt THEN
        gn_target_cnt := gn_target_cnt + gn_head_cnt;
        lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                           cv_msg_kbn_cfo            -- XXCFO
                         , cv_msg_cfo_00019          -- ���b�Z�[�W���F���b�N�G���[���b�Z�[�W
                         , cv_tkn_table              -- �g�[�N����1�FTABLE
                         , cv_msgtkn_cfo_60022       -- �g�[�N���l1�FAP������OIF
                         )
                     , 1
                     , 5000
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �t�@�C���N���[�Y
    UTL_FILE.FCLOSE( lf_file_handle1 );
    gn_target_cnt := gn_target_cnt + gn_head_cnt;
    gn_normal_cnt := gn_normal_cnt + gn_head_cnt;
    -- �o�͌������o�͂���
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60005                             -- ���b�Z�[�W���F�t�@�C���o�͑ΏہE�������b�Z�[�W
                       , cv_tkn_target                                -- �g�[�N����1�FTARGET
                       , gt_directory_path || lv_data_filename1       -- �g�[�N���l1�F�f�B���N�g���p�X�ƃt�@�C����
                       , cv_tkn_count                                 -- �g�[�N����2�FCOUNT
                       , gn_head_cnt                                  -- �g�[�N���l2�FHEAD��������
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
--
    -- HEAD�̒��o�������o�͂���
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60004                             -- ���b�Z�[�W���F�����ΏہE�������b�Z�[�W
                       , cv_tkn_target                                -- �g�[�N����1�FTARGET
                       , cv_msgtkn_cfo_60022                          -- �g�[�N���l1�FAP������OIF
                       , cv_tkn_count                                 -- �g�[�N����2�FCOUNT
                       , gn_head_cnt                                  -- �g�[�N���l2�FHEAD���o����
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- ���F�ώd���搿����LINE���o
    <<cur_ap_line_recode_loop>>
    FOR ap_line_rec IN ap_line_cur LOOP
-- Ver1.4 Add Start
      -- TAX_CODE�ł̃O���[�v����̐ō��v���z��0�~�ŁA����TAX_CODE�����{�̍��v��0�~�ɂȂ�ꍇ�A�ŋ����R�[�h�͍쐬���Ȃ��B
      IF (
           ap_line_rec.line_type_lookup_code = cv_lookup_code_tax AND
           ap_line_rec.amount = 0 AND
           ap_line_rec.prorate_across_flag = cv_flag_n
         ) THEN
        --
        CONTINUE;
      END IF;
-- Ver1.4 Add End
      --
      -- ������͂̏ꍇ�A�d�q���땔����͐�����ID/���הԍ����㏑��
      IF ( iv_source = cv_xx03_entry ) THEN
        BEGIN
          SELECT
            CASE
              WHEN ap_line_rec.line_type_lookup_code = cv_lookup_code_tax 
                THEN xps.invoice_id || '-' || (( ap_line_rec.line_number - 5 ) / 10 )
                ELSE xps.invoice_id || '-' || ( ap_line_rec.line_number / 10 )
            END as attribute12
          INTO
            lt_attribute12
          FROM
              ap_invoices_interface aii
            , xx03_payment_slips xps
          WHERE
                xps.invoice_num = aii.invoice_num
            AND aii.invoice_id = ap_line_rec.invoice_id
          ;
          ap_line_rec.attribute12 := lt_attribute12;
        END;
      END IF;
      lv_csv_text := NULL;
      -- LINE�f�[�^�s�̍쐬
      lv_csv_text :=                ap_line_rec.invoice_id                  || cv_delim_comma; -- 1:INVOICE_ID
      lv_csv_text := lv_csv_text || ap_line_rec.line_number                 || cv_delim_comma; -- 2:LINE_NUMBER
      lv_csv_text := lv_csv_text || ap_line_rec.line_type_lookup_code       || cv_delim_comma; -- 3:LINE_TYPE_LOOKUP_CODE
      lv_csv_text := lv_csv_text || ap_line_rec.amount                      || cv_delim_comma; -- 4:AMOUNT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 5:QUANTITY_INVOICED
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 6:UNIT_PRICE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 7:UNIT_OF_MEAS_LOOKUP_CODE
-- Ver1.1(E132) Mod Start
--      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.description , cv_lf_str )
--             || cv_delim_comma;                                                                -- 8:DESCRIPTION
      IF ( gv_desc_trim_flag = cv_flag_y ) THEN
-- Ver1.3(E134) Mod Start
--        lv_csv_text := lv_csv_text || get_utf8_size_char( cn_utf8_size , xxccp_oiccommon_pkg.to_csv_string( 
--             ap_line_rec.description , cv_lf_str )) || cv_delim_comma;                         -- 8:DESCRIPTION
        lv_csv_text := lv_csv_text || '"' || get_utf8_size_char( cn_utf8_size ,  
          REPLACE( REPLACE ( REPLACE ( ap_line_rec.description , '"' , '""' ) , CHR(13) , NULL ) , CHR(10) ,'\n')) 
            || '"' || cv_delim_comma;                                                          -- 8:DESCRIPTION
-- Ver1.3(E134) Mod End
      ELSE
        lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.description , cv_lf_str )
             || cv_delim_comma;                                                                -- 8:DESCRIPTION
      END IF;
-- Ver1.1(E132) Mod End
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 9:PO_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 10:PO_LINE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 11:PO_SHIPMENT_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 12:PO_DISTRIBUTION_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 13:ITEM_DESCRIPTION
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 14:RELEASE_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 15:PURCHASING_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 16:RECEIPT_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 17:RECEIPT_LINE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 18:CONSUMPTION_ADVICE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 19:CONSUMPTION_ADVICE_LINE_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 20:PACKING_SLIP
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 21:FINAL_MATCH_FLAG
      lv_csv_text := lv_csv_text || ap_line_rec.dist_code_concatenated      || cv_delim_comma; -- 22:DIST_CODE_CONCATENATED
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 23:DISTRIBUTION_SET_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 24:ACCOUNTING_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 25:ACCOUNT_SEGMENT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 26:BALANCING_SEGMENT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 27:COST_CENTER_SEGMENT
      lv_csv_text := lv_csv_text || ap_line_rec.tax_classification_code     || cv_delim_comma; -- 28:TAX_CLASSIFICATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 29:SHIP_TO_LOCATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 30:SHIP_FROM_LOCATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 31:FINAL_DISCHARGE_LOCATION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 32:TRX_BUSINESS_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 33:PRODUCT_FISC_CLASSIFICATION
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 34:PRIMARY_INTENDED_USE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 35:USER_DEFINED_FISC_CLASS
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 36:PRODUCT_TYPE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 37:ASSESSABLE_VALUE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 38:PRODUCT_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 39:CONTROL_AMOUNT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 40:TAX_REGIME_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 41:TAX
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 42:TAX_STATUS_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 43:TAX_JURISDICTION_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 44:TAX_RATE_CODE
      lv_csv_text := lv_csv_text || ap_line_rec.tax_rate                    || cv_delim_comma; -- 45:TAX_RATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 46:AWT_GROUP_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 47:TYPE_1099
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 48:INCOME_TAX_REGION
      lv_csv_text := lv_csv_text || ap_line_rec.prorate_across_flag         || cv_delim_comma; -- 49:PRORATE_ACROSS_FLAG
      lv_csv_text := lv_csv_text || ap_line_rec.line_group_number           || cv_delim_comma; -- 50:LINE_GROUP_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 51:COST_FACTOR_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 52:STAT_AMOUNT
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 53:ASSETS_TRACKING_FLAG
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 54:ASSET_BOOK_TYPE_CODE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 55:ASSET_CATEGORY_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 56:SERIAL_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 57:MANUFACTURER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 58:MODEL_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 59:WARRANTY_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 60:PRICE_CORRECTION_FLAG
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 61:PRICE_CORRECT_INV_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 62:PRICE_CORRECT_INV_LINE_NUM
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 63:REQUESTER_FIRST_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 64:REQUESTER_LAST_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 65:REQUESTER_EMPLOYEE_NUM
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute_category , cv_lf_str )  
             || cv_delim_comma;                                                                -- 66:ATTRIBUTE_CATEGORY
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute1 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 67:ATTRIBUTE1
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute2 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 68:ATTRIBUTE2
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute3 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 69:ATTRIBUTE3
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute4 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 70:ATTRIBUTE4
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute5 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 71:ATTRIBUTE5
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute6 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 72:ATTRIBUTE6
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute7 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 73:ATTRIBUTE7
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute8 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 74:ATTRIBUTE8
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute9 , cv_lf_str )  
             || cv_delim_comma;                                                                -- 75:ATTRIBUTE9
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute10 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 76:ATTRIBUTE10
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute11 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 77:ATTRIBUTE11
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute12 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 78:ATTRIBUTE12
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute13 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 79:ATTRIBUTE13
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute14 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 80:ATTRIBUTE14
      lv_csv_text := lv_csv_text || xxccp_oiccommon_pkg.to_csv_string( ap_line_rec.attribute15 , cv_lf_str ) 
             || cv_delim_comma;                                                                -- 81:ATTRIBUTE15
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 82:ATTRIBUTE_NUMBER1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 83:ATTRIBUTE_NUMBER2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 84:ATTRIBUTE_NUMBER3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 85:ATTRIBUTE_NUMBER4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 86:ATTRIBUTE_NUMBER5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 87:ATTRIBUTE_DATE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 88:ATTRIBUTE_DATE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 89:ATTRIBUTE_DATE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 90:ATTRIBUTE_DATE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 91:ATTRIBUTE_DATE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 92:GLOBAL_ATTRIBUTE_CATEGORY
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 93:GLOBAL_ATTRIBUTE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 94:GLOBAL_ATTRIBUTE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 95:GLOBAL_ATTRIBUTE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 96:GLOBAL_ATTRIBUTE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 97:GLOBAL_ATTRIBUTE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 98:GLOBAL_ATTRIBUTE6
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 99:GLOBAL_ATTRIBUTE7
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 100:GLOBAL_ATTRIBUTE8
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 101:GLOBAL_ATTRIBUTE9
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 102:GLOBAL_ATTRIBUTE10
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 103:GLOBAL_ATTRIBUTE11
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 104:GLOBAL_ATTRIBUTE12
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 105:GLOBAL_ATTRIBUTE13
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 106:GLOBAL_ATTRIBUTE14
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 107:GLOBAL_ATTRIBUTE15
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 108:GLOBAL_ATTRIBUTE16
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 109:GLOBAL_ATTRIBUTE17
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 110:GLOBAL_ATTRIBUTE18
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 111:GLOBAL_ATTRIBUTE19
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 112:GLOBAL_ATTRIBUTE20
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 113:GLOBAL_ATTRIBUTE_NUMBER1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 114:GLOBAL_ATTRIBUTE_NUMBER2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 115:GLOBAL_ATTRIBUTE_NUMBER3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 116:GLOBAL_ATTRIBUTE_NUMBER4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 117:GLOBAL_ATTRIBUTE_NUMBER5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 118:GLOBAL_ATTRIBUTE_DATE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 119:GLOBAL_ATTRIBUTE_DATE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 120:GLOBAL_ATTRIBUTE_DATE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 121:GLOBAL_ATTRIBUTE_DATE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 122:GLOBAL_ATTRIBUTE_DATE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 123:PJC_PROJECT_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 124:PJC_TASK_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 125:PJC_EXPENDITURE_TYPE_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 126:PJC_EXPENDITURE_ITEM_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 127:PJC_ORGANIZATION_ID
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 128:PJC_PROJECT_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 129:PJC_TASK_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 130:PJC_EXPENDITURE_TYPE_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 131:PJC_ORGANIZATION_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 132:PJC_RESERVED_ATTRIBUTE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 133:PJC_RESERVED_ATTRIBUTE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 134:PJC_RESERVED_ATTRIBUTE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 135:PJC_RESERVED_ATTRIBUTE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 136:PJC_RESERVED_ATTRIBUTE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 137:PJC_RESERVED_ATTRIBUTE6
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 138:PJC_RESERVED_ATTRIBUTE7
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 139:PJC_RESERVED_ATTRIBUTE8
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 140:PJC_RESERVED_ATTRIBUTE9
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 141:PJC_RESERVED_ATTRIBUTE10
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 142:PJC_USER_DEF_ATTRIBUTE1
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 143:PJC_USER_DEF_ATTRIBUTE2
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 144:PJC_USER_DEF_ATTRIBUTE3
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 145:PJC_USER_DEF_ATTRIBUTE4
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 146:PJC_USER_DEF_ATTRIBUTE5
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 147:PJC_USER_DEF_ATTRIBUTE6
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 148:PJC_USER_DEF_ATTRIBUTE7
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 149:PJC_USER_DEF_ATTRIBUTE8
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 150:PJC_USER_DEF_ATTRIBUTE9
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 151:PJC_USER_DEF_ATTRIBUTE10
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 152:FISCAL_CHARGE_TYPE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 153:DEF_ACCTG_START_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 154:DEF_ACCTG_END_DATE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 155:DEF_ACCRUAL_CODE_CONCATENATED
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 156:PJC_PROJECT_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 157:PJC_TASK_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 158:PJC_WORK_TYPE
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 159:PJC_CONTRACT_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 160:PJC_CONTRACT_NUMBER
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 161:PJC_FUNDING_SOURCE_NAME
      lv_csv_text := lv_csv_text || NULL                                    || cv_delim_comma; -- 162:PJC_FUNDING_SOURCE_NUMBER
      lv_csv_text := lv_csv_text || NULL;                                                      -- 163:REQUESTER_EMAIL_ADDRESS
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( lf_file_handle2
                         , lv_csv_text
                         );
        --
        -- �o�͌����J�E���g�A�b�v
        gn_line_cnt := gn_line_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          gn_target_cnt := gn_target_cnt + gn_line_cnt;
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                             cv_msg_kbn_cfo            -- XXCFO
                           , cv_msg_cfo_00030          -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                           , cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                           , SQLERRM                   -- �g�[�N���l1�FSQLERRM
                           )
                       , 1
                       , 5000
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP cur_ap_line_recode_loop;
    -- �t�@�C���N���[�Y
    UTL_FILE.FCLOSE( lf_file_handle2 );
    gn_target_cnt := gn_target_cnt + gn_line_cnt;
    gn_normal_cnt := gn_normal_cnt + gn_line_cnt;
    -- �o�͌������o�͂���
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60005                             -- ���b�Z�[�W���F�t�@�C���o�͑ΏہE�������b�Z�[�W
                       , cv_tkn_target                                -- �g�[�N����1�FTARGET
                       , gt_directory_path || lv_data_filename2       -- �g�[�N���l1�F�f�B���N�g���p�X�ƃt�@�C����
                       , cv_tkn_count                                 -- �g�[�N����2�FCOUNT
                       , gn_line_cnt                                  -- �g�[�N���l2�FLINE��������
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    -- LINE�̌����Ώی������o�͂���
    gv_out_msg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                         cv_msg_kbn_cfo                               -- XXCFO
                       , cv_msg_cfo_60004                             -- ���b�Z�[�W���F�����ΏہE�������b�Z�[�W
                       , cv_tkn_target                                -- �g�[�N����1�FTARGET
                       , cv_msgtkn_cfo_60023                          -- �g�[�N���l1�F�f�B���N�g���p�X�ƃt�@�C����
                       , cv_tkn_count                                 -- �g�[�N����2�FCOUNT
                       , gn_line_cnt                                  -- �g�[�N���l2�FLINE���o����
                       )
                   , 1
                   , 5000
                   );
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE (
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    -- AP������OIF�̍X�V
    <<cur_ap_head_upd_loop>> 
    FOR ap_head_rec IN ap_head_cur LOOP
      BEGIN
        UPDATE 
          ap_invoices_interface aii
        SET
            aii.status = cv_status
          , aii.last_updated_by = cn_last_updated_by
          , aii.last_update_date = cd_last_update_date
          , aii.last_update_login = cn_last_update_login
          , aii.request_id = cn_request_id
        WHERE
          aii.invoice_id = ap_head_rec.invoice_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg 
                                 (
                                    cv_msg_kbn_cfo      -- XXCFO
                                  , cv_msg_cfo_00020    -- �X�V�G���[
                                  , cv_tkn_table        -- �g�[�N����1�FTABLE
                                  , cv_msgtkn_cfo_60022 -- �g�[�N���l1�FAP������OIF
                                  , cv_tkn_errmsg       -- �g�[�N����2�FERRMSG
                                  , SQLERRM             -- �g�[�N���l2�FSQLERRM
                                 )
                                , 1
                                , 5000
                               );
          lv_errbuf := lv_errmsg;
          --��O�\���́A��ʃ��W���[���ōs���B
          RAISE global_process_expt;
      END;
    END LOOP cur_ap_head_upd_loop;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf , 1 , 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( UTL_FILE.IS_OPEN( lf_file_handle1 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle1 );
      END IF;
      IF ( UTL_FILE.IS_OPEN( lf_file_handle2 ) ) THEN
                UTL_FILE.FCLOSE( lf_file_handle2 );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_ap_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     --   �\�[�X
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- <A-1�D��������> 
    -- ===============================
    init(
      iv_source,         -- �\�[�X
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- <A-2�DI/F�t�@�C���o��> (�������ʂɂ���Č㑱�����𐧌䂷��ꍇ)
    -- ===============================
    output_ap_data(
      iv_source,         -- �\�[�X
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_source     IN  VARCHAR2       --   �\�[�X
  )
--
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
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_source   -- �\�[�X
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
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
END XXCFO007A02C;
/
