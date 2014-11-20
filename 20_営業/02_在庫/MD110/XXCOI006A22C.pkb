CREATE OR REPLACE PACKAGE BODY XXCOI006A22C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A22C(body)
 * Description      : ���ގ�������ɁAVD�󕥏����쐬���܂��B
 * MD.050           : VD�󕥃f�[�^�쐬<MD050_COI_006_A22>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  finalize               �I������                   (A-7)
 *  set_cooperation_data   �����ώ��ID�X�V           (A-6)
 *  set_last_month_data    �O��VD�󕥃f�[�^����       (A-4, A-5)
 *  set_vd_reception_info  �����f�[�^VD�󕥏��o��   (A-2, A-3)
 *  init                   ��������                   (A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/06    1.0   H.Sasaki         ���ō쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  zero_data_expt            EXCEPTION;
  lock_error_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI006A22C'; -- �p�b�P�[�W��
  -- ���b�Z�[�W�֘A
  cv_short_name         CONSTANT VARCHAR2(30) :=  'XXCOI';
  cv_msg_xxcoi1_00005   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00005';         -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00006   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00006';         -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00011   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-00011';         -- �Ɩ��������t�擾�G���[
  cv_msg_xxcoi1_10127   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10127';         -- �ő���ID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10285   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10285';         -- �W�������擾���s�G���[���b�Z�[�W
  cv_msg_xxcoi1_10293   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10293';         -- �c�ƌ����擾���s�G���[���b�Z�[�W
  cv_msg_xxcoi1_10365   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10365';         -- �R���J�����g���̓p�����[�^
  cv_msg_xxcoi1_10366   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10366';         -- VD�󕥏�񃍃b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10367   CONSTANT VARCHAR2(30) :=  'APP-XXCOI1-10367';         -- �N���t���O���擾�G���[���b�Z�[�W
  cv_token_00005_1      CONSTANT VARCHAR2(30) :=  'PRO_TOK';
  cv_token_00006_1      CONSTANT VARCHAR2(30) :=  'ORG_CODE_TOK';
  cv_token_10365_1      CONSTANT VARCHAR2(30) :=  'EXEC_FLAG';
  cv_token_10367_1      CONSTANT VARCHAR2(30) :=  'LOOKUP_TYPE';
  cv_token_10367_2      CONSTANT VARCHAR2(30) :=  'LOOKUP_CODE';
  -- �󕥏W�v�L�[�i����^�C�v�j
  cv_trans_type_160     CONSTANT VARCHAR2(3)  :=  '160';                      -- ��݌ɕύX
  cv_trans_type_300     CONSTANT VARCHAR2(3)  :=  '300';                      -- ���_����VD�݌ɐU��
  -- �ۊǏꏊ����
  cv_subinv_class_6     CONSTANT VARCHAR2(1)  :=  '6';                        -- ���̋@�i�t���j
  cv_subinv_class_7     CONSTANT VARCHAR2(1)  :=  '7';                        -- ���̋@�i�����j
  -- �Ƒԁi�����ށj
  cv_low_type_24        CONSTANT VARCHAR2(2)  :=  '24';                       -- �t���i�����jVD
  cv_low_type_25        CONSTANT VARCHAR2(2)  :=  '25';                       -- �t��VD
  cv_low_type_27        CONSTANT VARCHAR2(2)  :=  '27';                       -- ����VD
  -- �Q�ƕ\�^�C�v
  cv_lookup_type        CONSTANT VARCHAR2(30) :=  'XXCOI1_EXEC_FLAG_NAME';    -- �N���t���O����
  -- �v���t�@�C��
  cv_prf_name_orgcd     CONSTANT VARCHAR2(30) :=  'XXCOI1_ORGANIZATION_CODE'; -- �v���t�@�C�����i�݌ɑg�D�R�[�h�j
  -- ���̑�
  cn_control_id         CONSTANT NUMBER       :=  60;
  cv_month              CONSTANT VARCHAR2(6)  :=  'YYYYMM';
  cv_yes                CONSTANT VARCHAR2(1)  :=  'Y';
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';
  cv_pgsname_a22c       CONSTANT VARCHAR2(30) :=  'XXCOI006A22C';
  cv_exec_flag_2        CONSTANT VARCHAR2(1)  :=  '2';                        -- �N���t���O�Q�i�����N���j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE quantity_type IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  gt_quantity           quantity_type;      -- ����^�C�v�ʐ���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_param_exec_flag          VARCHAR2(1);        -- �N���t���O
  -- ���������ݒ�l
  gd_f_process_date           DATE;               -- �Ɩ��������t
  gv_f_last_month             VARCHAR2(6);        -- �Ɩ��������t�i�O���j
  gv_f_organization_code      VARCHAR2(10);       -- �݌ɑg�D�R�[�h
  gn_f_organization_id        NUMBER;             -- �݌ɑg�DID
  gv_f_inv_acct_period        VARCHAR2(6);        -- �݌ɉ�v���ԁi�N�� YYYYMM�j
  gn_f_last_transaction_id    NUMBER;             -- �����ώ��ID
  gd_f_last_cooperation_date  DATE;               -- ������
  gn_f_max_transaction_id     NUMBER;             -- �ő���ID
--
--
  /**********************************************************************************
   * Procedure Name   : finalize
   * Description      : �I������(A-7)
   ***********************************************************************************/
  PROCEDURE finalize(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'finalize'; -- �v���O������
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.���������ݒ�
    -- ===================================
    -- �Ώی����ݒ�
    SELECT  COUNT(1)
    INTO    gn_target_cnt
    FROM    xxcoi_vd_reception_info
    WHERE   request_id  = cn_request_id;
    --
    -- ���������ݒ�
    gn_normal_cnt := gn_target_cnt;
    --
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END finalize;
--
  /**********************************************************************************
   * Procedure Name   : set_cooperation_data
   * Description      : �����ώ��ID�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE set_cooperation_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_cooperation_data'; -- �v���O������
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�f�[�^�A�g������쐬
    -- ===================================
    IF (gn_f_last_transaction_id = 0) THEN
      -- �f�[�^�A�g�����񂪑��݂��Ȃ��ꍇ
      INSERT INTO xxcoi_cooperation_control(
        control_id                      -- 01.����ID
       ,last_cooperation_date           -- 02.�ŏI�A�g����
       ,transaction_id                  -- 03.���ID
       ,program_short_name              -- 04.�v���O��������
       ,last_update_date                -- 05.�ŏI�X�V��
       ,last_updated_by                 -- 06.�ŏI�X�V��
       ,creation_date                   -- 07.�쐬��
       ,created_by                      -- 08.�쐬��
       ,last_update_login               -- 09.�ŏI�X�V���[�U
       ,request_id                      -- 10.�v��ID
       ,program_application_id          -- 11.�v���O�����A�v���P�[�V����ID
       ,program_id                      -- 12.�v���O����ID
       ,program_update_date             -- 13.�v���O�����X�V��
      )VALUES(
        cn_control_id                   -- 01
       ,gd_f_process_date               -- 02
       ,gn_f_max_transaction_id         -- 03
       ,cv_pgsname_a22c                 -- 04
       ,SYSDATE                         -- 05
       ,cn_last_updated_by              -- 06
       ,SYSDATE                         -- 07
       ,cn_created_by                   -- 08
       ,cn_last_update_login            -- 09
       ,cn_request_id                   -- 10
       ,cn_program_application_id       -- 11
       ,cn_program_id                   -- 12
       ,SYSDATE                         -- 13
      );
      --
    ELSE
      -- �f�[�^�A�g�����񂪑��݂���ꍇ
      UPDATE  xxcoi_cooperation_control
      SET     last_cooperation_date   = gd_f_process_date           -- 02.�ŏI�A�g����
             ,transaction_id          = gn_f_max_transaction_id     -- 03.���ID
             ,last_update_date        = SYSDATE                     -- 05.�ŏI�X�V��
             ,last_updated_by         = cn_last_updated_by          -- 06.�ŏI�X�V��
             ,last_update_login       = cn_last_update_login        -- 09.�ŏI�X�V���[�U
             ,request_id              = cn_request_id               -- 10.�v��ID
             ,program_application_id  = cn_program_application_id   -- 11.�v���O�����A�v���P�[�V����ID
             ,program_id              = cn_program_id               -- 12.�v���O����ID
             ,program_update_date     = SYSDATE                     -- 13.�v���O�����X�V��
      WHERE   control_id    =   cn_control_id;
      --
    END IF;
    --
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END set_cooperation_data;
--
  /**********************************************************************************
   * Procedure Name   : set_last_month_data
   * Description      : �O��VD�󕥃f�[�^����(A-4, A-5)
   ***********************************************************************************/
  PROCEDURE set_last_month_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_last_month_data'; -- �v���O������
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
    lt_standard_cost        xxcoi_vd_reception_info.standard_cost%TYPE;       -- �W������
    lt_operation_cost       xxcoi_vd_reception_info.operation_cost%TYPE;      -- �c�ƌ���
    ln_dummy                NUMBER;                                           -- �_�~�[�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  vd_column_cur
    IS
      SELECT  xvri_lm.base_code                     base_code                       -- ���_�R�[�h�i�O���j
             ,xvri_lm.practice_date                 practice_date                   -- �N��
             ,xvri_lm.inventory_item_id             inventory_item_id               -- �i��ID
             ,xvri_lm.month_begin_quantity          month_begin_quantity            -- ����݌�
             ,  xvri_lm.vd_stock
              + xvri_lm.vd_move_stock
              - xvri_lm.vd_ship
              - xvri_lm.vd_move_ship                vd_total_quantity               -- VD���o�ɍ��v
             ,xvri_tm.base_code                     this_month_base_code            -- ���_�R�[�h�i�����j
             ,vcm.last_month_inventory_quantity     last_month_inventory_quantity   -- �O������݌ɐ�
      FROM    xxcoi_vd_reception_info   xvri_lm                                     -- VD�󕥏��i�O���j
             ,xxcoi_vd_reception_info   xvri_tm                                     -- VD�󕥏��i�����j
             ,(SELECT   xca.past_sale_base_code                   base_code                         -- �O�����㋒�_�R�[�h
                       ,xmvc.last_month_item_id                   inventory_item_id                 -- �O�����i��ID
                       ,SUM(xmvc.last_month_inventory_quantity)   last_month_inventory_quantity     -- �O������݌ɐ�
               FROM     xxcoi_mst_vd_column     xmvc                                                -- VD�R�����}�X�^
                       ,xxcmm_cust_accounts     xca                                                 -- �ڋq�ǉ����
               WHERE    xmvc.customer_id      =   xca.customer_id
               AND      xca.business_low_type IN(cv_low_type_24, cv_low_type_25, cv_low_type_27)
               GROUP BY xca.past_sale_base_code
                       ,xmvc.last_month_item_id
              )                         vcm                                         -- �R�����}�X�^���
      WHERE   xvri_lm.base_code           =   xvri_tm.base_code(+)
      AND     xvri_lm.inventory_item_id   =   xvri_tm.inventory_item_id(+)
      AND     xvri_lm.practice_date       =   gv_f_last_month
      AND     xvri_tm.practice_date(+)    =   TO_CHAR(gd_f_process_date, cv_month)
      AND     xvri_lm.base_code           =   vcm.base_code
      AND     xvri_lm.inventory_item_id   =   vcm.inventory_item_id;
--
    -- *** ���[�J���E���R�[�h ***
    vd_column_rec   vd_column_cur%ROWTYPE;
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�O��VD�󕥃f�[�^�ǉ��i�����j
    -- ===================================
    --
    <<set_vd_column_loop>>
    FOR vd_column_rec IN vd_column_cur LOOP
      IF (vd_column_rec.last_month_inventory_quantity = 0) THEN
        -- �O������݌ɐ����O�̏ꍇ�A�o�^���s��Ȃ�
        NULL;
        --
      ELSIF (vd_column_rec.this_month_base_code IS NULL) THEN
        -- ��������VD�󕥏�񂪑��݂��Ȃ��ꍇ
        
        -- ===================================
        --  �W�������擾
        -- ===================================
        xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id      =>  vd_column_rec.inventory_item_id                 -- �i��ID
         ,in_org_id       =>  gn_f_organization_id                            -- �g�DID
         ,id_period_date  =>  gd_f_process_date                               -- �Ώۓ�
         ,ov_cmpnt_cost   =>  lt_standard_cost                                -- �W������
         ,ov_errbuf       =>  lv_errbuf                                       -- �G���[���b�Z�[�W
         ,ov_retcode      =>  lv_retcode                                      -- ���^�[���E�R�[�h
         ,ov_errmsg       =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lt_standard_cost IS NULL) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10285
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
        END IF;
        --
        -- ===================================
        --  �c�ƌ����擾
        -- ===================================
        xxcoi_common_pkg.get_discrete_cost(
          in_item_id        =>  vd_column_rec.inventory_item_id                 -- �i��ID
         ,in_org_id         =>  gn_f_organization_id                            -- �g�DID
         ,id_target_date    =>  gd_f_process_date                               -- �Ώۓ�
         ,ov_discrete_cost  =>  lt_operation_cost                               -- �c�ƌ���
         ,ov_errbuf         =>  lv_errbuf                                       -- �G���[���b�Z�[�W
         ,ov_retcode        =>  lv_retcode                                      -- ���^�[���E�R�[�h
         ,ov_errmsg         =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
        );
        -- �I���p�����[�^����
        IF (lt_operation_cost IS NULL) THEN
          lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name
                          ,iv_name         => cv_msg_xxcoi1_10293
                         );
          lv_errbuf   := lv_errmsg;
          RAISE global_process_expt;
        END IF;
        --
        INSERT INTO xxcoi_vd_reception_info(
          base_code                                     -- 01.���_�R�[�h
         ,organization_id                               -- 02.�g�DID
         ,practice_date                                 -- 03.�N��
         ,inventory_item_id                             -- 04.�i��ID
         ,operation_cost                                -- 05.�c�ƌ���
         ,standard_cost                                 -- 06.�W������
         ,month_begin_quantity                          -- 07.����݌�
         ,vd_stock                                      -- 08.�x���_����
         ,vd_move_stock                                 -- 09.�x���_-�ړ�����
         ,vd_ship                                       -- 10.�x���_�o��
         ,vd_move_ship                                  -- 11.�x���_-�ړ��o��
         ,month_end_book_remain_qty                     -- 12.��������c
         ,month_end_quantity                            -- 13.�����݌�
         ,inv_wear_account                              -- 14.�I�����Ք�
         ,created_by                                    -- 15.�쐬��
         ,creation_date                                 -- 16.�쐬��
         ,last_updated_by                               -- 17.�ŏI�X�V��
         ,last_update_date                              -- 18.�ŏI�X�V��
         ,last_update_login                             -- 19.�ŏI�X�V���O�C��
         ,request_id                                    -- 20.�v��ID
         ,program_application_id                        -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                                    -- 22.�R���J�����g�E�v���O����ID
         ,program_update_date                           -- 23.�v���O�����X�V��
        )VALUES(
          vd_column_rec.base_code                       -- 01
         ,gn_f_organization_id                          -- 02
         ,TO_CHAR(gd_f_process_date, cv_month)          -- 03
         ,vd_column_rec.inventory_item_id               -- 04
         ,lt_operation_cost                             -- 05
         ,lt_standard_cost                              -- 06
         ,vd_column_rec.last_month_inventory_quantity   -- 07
         ,0                                             -- 08
         ,0                                             -- 09
         ,0                                             -- 10
         ,0                                             -- 11
         ,0                                             -- 12
         ,0                                             -- 13
         ,0                                             -- 14
         ,cn_created_by                                 -- 15
         ,SYSDATE                                       -- 16
         ,cn_last_updated_by                            -- 17
         ,SYSDATE                                       -- 18
         ,cn_last_update_login                          -- 19
         ,cn_request_id                                 -- 20
         ,cn_program_application_id                     -- 21
         ,cn_program_id                                 -- 22
         ,SYSDATE                                       -- 23
        );
        --
      ELSE
        -- ��������VD�󕥏�񂪑��݂���ꍇ
        BEGIN
          -- ���b�N�擾
          SELECT  1
          INTO    ln_dummy
          FROM    xxcoi_vd_reception_info
          WHERE   base_code           = vd_column_rec.base_code
          AND     practice_date       = TO_CHAR(gd_f_process_date, cv_month)
          AND     inventory_item_id   = vd_column_rec.inventory_item_id
          FOR UPDATE NOWAIT;
          --
        EXCEPTION
          WHEN  lock_error_expt THEN
            -- VD�󕥏�񃍃b�N�G���[���b�Z�[�W
            lv_errmsg   :=  xxccp_common_pkg.get_msg(
                              iv_application  => cv_short_name
                             ,iv_name         => cv_msg_xxcoi1_10366
                            );
            lv_errbuf   :=  lv_errmsg;
            RAISE global_process_expt;
            --
        END;
        --
        UPDATE  xxcoi_vd_reception_info
        SET     month_begin_quantity    = month_begin_quantity  +  vd_column_rec.last_month_inventory_quantity
                                                                              -- 07.����݌�
               ,last_updated_by         = cn_last_updated_by                  -- 17.�ŏI�X�V��
               ,last_update_date        = SYSDATE                             -- 18.�ŏI�X�V��
               ,last_update_login       = cn_last_update_login                -- 19.�ŏI�X�V���O�C��
               ,request_id              = cn_request_id                       -- 20.�v��ID
               ,program_application_id  = cn_program_application_id           -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,program_id              = cn_program_id                       -- 22.�R���J�����g�E�v���O����ID
               ,program_update_date     = SYSDATE                             -- 23.�v���O�����X�V��
        WHERE   base_code               = vd_column_rec.base_code
        AND     practice_date           = TO_CHAR(gd_f_process_date, cv_month)
        AND     inventory_item_id       = vd_column_rec.inventory_item_id;
        --
      END IF;
      --
      -- ===================================
      --  2.�O��VD�󕥃f�[�^�m��
      -- ===================================
      BEGIN
        -- ���b�N�擾
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_vd_reception_info
        WHERE   base_code           = vd_column_rec.base_code
        AND     practice_date       = gv_f_last_month
        AND     inventory_item_id   = vd_column_rec.inventory_item_id
        FOR UPDATE NOWAIT;
        --
      EXCEPTION
        WHEN  lock_error_expt THEN
          -- VD�󕥏�񃍃b�N�G���[���b�Z�[�W
          lv_errmsg   :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_short_name
                           ,iv_name         => cv_msg_xxcoi1_10366
                          );
          lv_errbuf   :=  lv_errmsg;
          RAISE global_process_expt;
          --
      END;
      --
      UPDATE  xxcoi_vd_reception_info
      SET     month_end_book_remain_qty =  month_end_book_remain_qty
                                         + vd_column_rec.month_begin_quantity
                                         + vd_column_rec.vd_total_quantity                  -- 12.��������c
             ,month_end_quantity        =  vd_column_rec.last_month_inventory_quantity      -- 13.�����݌�
             ,inv_wear_account          =  vd_column_rec.month_begin_quantity
                                         + vd_column_rec.vd_total_quantity
                                         - vd_column_rec.last_month_inventory_quantity      -- 14.�I�����Ք�
             ,last_updated_by           =  cn_last_updated_by                               -- 17.�ŏI�X�V��
             ,last_update_date          =  SYSDATE                                          -- 18.�ŏI�X�V��
             ,last_update_login         =  cn_last_update_login                             -- 19.�ŏI�X�V���O�C��
             ,request_id                =  cn_request_id                                    -- 20.�v��ID
             ,program_application_id    =  cn_program_application_id                        -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                =  cn_program_id                                    -- 22.�R���J�����g�E�v���O����ID
             ,program_update_date       =  SYSDATE                                          -- 23.�v���O�����X�V��
      WHERE   base_code           = vd_column_rec.base_code
      AND     practice_date       = gv_f_last_month
      AND     inventory_item_id   = vd_column_rec.inventory_item_id;
      --
    END LOOP set_vd_column_loop;
    --
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (vd_column_cur%ISOPEN) THEN
        CLOSE vd_column_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_last_month_data;
--
  /**********************************************************************************
   * Procedure Name   : set_vd_reception_info
   * Description      : �����f�[�^VD�󕥏��o��(A-2, A-3)
   ***********************************************************************************/
  PROCEDURE set_vd_reception_info(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_vd_reception_info'; -- �v���O������
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
    lt_base_code            xxcoi_vd_reception_info.base_code%TYPE;           -- ���_�R�[�h
    lt_inventory_item_id    xxcoi_vd_reception_info.inventory_item_id%TYPE;   -- �i��ID
    lt_transaction_date     xxcoi_vd_reception_info.practice_date%TYPE;       -- �N��
    lt_xvri_base_code       xxcoi_vd_reception_info.base_code%TYPE;           -- VD���_�R�[�h
    lt_vd_stock             xxcoi_vd_reception_info.vd_stock%TYPE;            -- �x���_����
    lt_vd_move_stock        xxcoi_vd_reception_info.vd_move_stock%TYPE;       -- �x���_-�ړ�����
    lt_vd_ship              xxcoi_vd_reception_info.vd_ship%TYPE;             -- �x���_�o��
    lt_vd_move_ship         xxcoi_vd_reception_info.vd_move_ship%TYPE;        -- �x���_-�ړ��o��
    lt_standard_cost        xxcoi_vd_reception_info.standard_cost%TYPE;       -- �W������
    lt_operation_cost       xxcoi_vd_reception_info.operation_cost%TYPE;      -- �c�ƌ���
    ld_object_date          DATE;                                             -- �����擾�p�Ώۓ�
    ln_dummy                NUMBER;                                           -- �_�~�[�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR  vd_rep_cur
    IS
      SELECT  mmt.base_code                 base_code               -- ���_�R�[�h
             ,mmt.subinventory_class        subinventory_class      -- �ۊǏꏊ����
             ,mmt.inventory_item_id         inventory_item_id       -- �i��ID
             ,TO_CHAR(mmt.transaction_date, cv_month)
                                            transaction_date        -- ����N��
             ,mmt.transaction_quantity      transaction_quantity    -- �������
             ,mtt.attribute3                transaction_type        -- �󕥏W�v�L�[
             ,xvri.base_code                xvri_base_code          -- VD���_�R�[�h
      FROM    mtl_transaction_types         mtt                     -- ����^�C�v�}�X�^
             ,xxcoi_vd_reception_info       xvri                    -- VD�󕥏��e�[�u��
             ,(SELECT   smsi.attribute7               base_code
                       ,smsi.attribute13              subinventory_class
                       ,smmt.inventory_item_id        inventory_item_id
                       ,smmt.transaction_date         transaction_date
                       ,smmt.transaction_quantity     transaction_quantity
                       ,smmt.transaction_type_id      transaction_type_id
               FROM     mtl_material_transactions     smmt
                       ,mtl_secondary_inventories     smsi
               WHERE    smmt.organization_id      =   gn_f_organization_id
               AND      smmt.transaction_id       >   gn_f_last_transaction_id
               AND      smmt.transaction_id      <=   gn_f_max_transaction_id
               AND      smmt.subinventory_code    =   smsi.secondary_inventory_name
               AND      smmt.organization_id      =   smsi.organization_id
               AND      smsi.attribute13         IN(cv_subinv_class_6, cv_subinv_class_7)
              )                             mmt                     -- ���ގ���A�ۊǏꏊ���
      WHERE   mmt.transaction_type_id   =   mtt.transaction_type_id
      AND     mtt.attribute3           IN(cv_trans_type_160, cv_trans_type_300)
      AND     mmt.base_code             =   xvri.base_code(+)
      AND     mmt.inventory_item_id     =   xvri.inventory_item_id(+)
      AND     TO_CHAR(mmt.transaction_date, cv_month)
                                        =   xvri.practice_date(+)
      ORDER BY  mmt.base_code
               ,mmt.inventory_item_id
               ,mmt.transaction_date;
--
    -- *** ���[�J���E���R�[�h ***
    vd_rep_rec    vd_rep_cur%ROWTYPE;
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
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �W�v�L�[�ʎ�����ʗ݌v��������
    FOR i IN  1 .. 4 LOOP
      gt_quantity(i)  :=  0;
    END LOOP;
    --
    OPEN  vd_rep_cur;
    FETCH vd_rep_cur  INTO  vd_rep_rec;
    --
    IF (vd_rep_cur%NOTFOUND) THEN
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�{�v���V�[�W�����I��
      CLOSE vd_rep_cur;
      RAISE zero_data_expt;
    END IF;
    --
    <<set_vd_info_loop>>
    LOOP
    --
      IF (   (vd_rep_rec.base_code            <>  lt_base_code)
          OR (vd_rep_rec.inventory_item_id    <>  lt_inventory_item_id)
          OR (vd_rep_rec.transaction_date     <>  lt_transaction_date)
          OR (vd_rep_cur%NOTFOUND)
         )
      THEN
        -- ==========================
        --  �X�V�p�f�[�^�ݒ�
        -- ==========================
        lt_vd_stock       :=  gt_quantity(1);             -- �x���_����
        lt_vd_move_stock  :=  gt_quantity(3);             -- �x���_-�ړ�����
        lt_vd_ship        :=  gt_quantity(2)  * -1;       -- �x���_�o��
        lt_vd_move_ship   :=  gt_quantity(4)  * -1;       -- �x���_-�ړ��o��
        --
        -- �W�v�L�[�ʎ�����ʗ݌v��������
        FOR i IN  1 .. 4 LOOP
          gt_quantity(i)  :=  0;
        END LOOP;
        --
        IF (    (lt_transaction_date   = gv_f_last_month)
            AND (gv_f_inv_acct_period <> gv_f_last_month)
           )
        THEN
          -- ����N�����O���ŁA�O���̍݌ɉ�v���Ԃ�CLOSE���Ă���ꍇ�A�o�^���s��Ȃ�
          NULL;
        ELSE
          -- ===================================
          --  VD�󕥏��o��
          -- ===================================
          IF (lt_xvri_base_code IS NULL) THEN
            -- VD�󕥏��Ƀf�[�^�����݂��Ȃ��ꍇ
            --
            -- ===================================
            -- �����擾
            -- ===================================
            -- �Ώۓ��ݒ�
            IF (lt_transaction_date = TO_CHAR(gd_f_process_date, cv_month)) THEN
              -- �󕥓��������̏ꍇ
              ld_object_date  :=  gd_f_process_date;
            ELSE
              -- �󕥓����O���̏ꍇ
              ld_object_date  :=  LAST_DAY(ADD_MONTHS(gd_f_process_date, -1));
            END IF;
            --
            -- �W�������擾
            xxcoi_common_pkg.get_cmpnt_cost(
              in_item_id      =>  lt_inventory_item_id                            -- �i��ID
             ,in_org_id       =>  gn_f_organization_id                            -- �g�DID
             ,id_period_date  =>  ld_object_date                                  -- �Ώۓ�
             ,ov_cmpnt_cost   =>  lt_standard_cost                                -- �W������
             ,ov_errbuf       =>  lv_errbuf                                       -- �G���[���b�Z�[�W
             ,ov_retcode      =>  lv_retcode                                      -- ���^�[���E�R�[�h
             ,ov_errmsg       =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
            );
            -- �I���p�����[�^����
            IF (lt_standard_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10285
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            -- �c�ƌ����擾
            xxcoi_common_pkg.get_discrete_cost(
              in_item_id        =>  lt_inventory_item_id                            -- �i��ID
             ,in_org_id         =>  gn_f_organization_id                            -- �g�DID
             ,id_target_date    =>  ld_object_date                                  -- �Ώۓ�
             ,ov_discrete_cost  =>  lt_operation_cost                               -- �c�ƌ���
             ,ov_errbuf         =>  lv_errbuf                                       -- �G���[���b�Z�[�W
             ,ov_retcode        =>  lv_retcode                                      -- ���^�[���E�R�[�h
             ,ov_errmsg         =>  lv_errmsg                                       -- ���[�U�[�E�G���[���b�Z�[�W
            );
            -- �I���p�����[�^����
            IF (lt_operation_cost IS NULL) THEN
              lv_errmsg   := xxccp_common_pkg.get_msg(
                               iv_application  => cv_short_name
                              ,iv_name         => cv_msg_xxcoi1_10293
                             );
              lv_errbuf   := lv_errmsg;
              RAISE global_process_expt;
            END IF;
            --
            --
            INSERT INTO xxcoi_vd_reception_info(
              base_code                       -- 01.���_�R�[�h
             ,organization_id                 -- 02.�g�DID
             ,practice_date                   -- 03.�N��
             ,inventory_item_id               -- 04.�i��ID
             ,operation_cost                  -- 05.�c�ƌ���
             ,standard_cost                   -- 06.�W������
             ,month_begin_quantity            -- 07.����݌�
             ,vd_stock                        -- 08.�x���_����
             ,vd_move_stock                   -- 09.�x���_-�ړ�����
             ,vd_ship                         -- 10.�x���_�o��
             ,vd_move_ship                    -- 11.�x���_-�ړ��o��
             ,month_end_book_remain_qty       -- 12.��������c
             ,month_end_quantity              -- 13.�����݌�
             ,inv_wear_account                -- 14.�I�����Ք�
             ,created_by                      -- 15.�쐬��
             ,creation_date                   -- 16.�쐬��
             ,last_updated_by                 -- 17.�ŏI�X�V��
             ,last_update_date                -- 18.�ŏI�X�V��
             ,last_update_login               -- 19.�ŏI�X�V���O�C��
             ,request_id                      -- 20.�v��ID
             ,program_application_id          -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id                      -- 22.�R���J�����g�E�v���O����ID
             ,program_update_date             -- 23.�v���O�����X�V��
            )VALUES(
              lt_base_code                    -- 01
             ,gn_f_organization_id            -- 02
             ,lt_transaction_date             -- 03
             ,lt_inventory_item_id            -- 04
             ,lt_operation_cost               -- 05
             ,lt_standard_cost                -- 06
             ,0                               -- 07
             ,lt_vd_stock                     -- 08
             ,lt_vd_move_stock                -- 09
             ,lt_vd_ship                      -- 10
             ,lt_vd_move_ship                 -- 11
             ,0                               -- 12
             ,0                               -- 13
             ,0                               -- 14
             ,cn_created_by                   -- 15
             ,SYSDATE                         -- 16
             ,cn_last_updated_by              -- 17
             ,SYSDATE                         -- 18
             ,cn_last_update_login            -- 19
             ,cn_request_id                   -- 20
             ,cn_program_application_id       -- 21
             ,cn_program_id                   -- 22
             ,SYSDATE                         -- 23
            );
            --
          ELSE
            -- VD�󕥏��Ƀf�[�^�����݂���ꍇ
            BEGIN
              -- ���b�N�擾
              SELECT  1
              INTO    ln_dummy
              FROM    xxcoi_vd_reception_info
              WHERE   base_code               = lt_base_code
              AND     practice_date           = lt_transaction_date
              AND     inventory_item_id       = lt_inventory_item_id
              FOR UPDATE NOWAIT;
              --
            EXCEPTION
              WHEN  lock_error_expt THEN
                -- VD�󕥏�񃍃b�N�G���[���b�Z�[�W
                lv_errmsg   :=  xxccp_common_pkg.get_msg(
                                  iv_application  => cv_short_name
                                 ,iv_name         => cv_msg_xxcoi1_10366
                                );
                lv_errbuf   :=  lv_errmsg;
                RAISE global_process_expt;
                --
            END;
            --
            UPDATE  xxcoi_vd_reception_info
            SET     vd_stock                = vd_stock      + lt_vd_stock         -- 08.�x���_����
                   ,vd_move_stock           = vd_move_stock + lt_vd_move_stock    -- 09.�x���_-�ړ�����
                   ,vd_ship                 = vd_ship       + lt_vd_ship          -- 10.�x���_�o��
                   ,vd_move_ship            = vd_move_ship  + lt_vd_move_ship     -- 11.�x���_-�ړ��o��
                   ,last_updated_by         = cn_last_updated_by                  -- 17.�ŏI�X�V��
                   ,last_update_date        = SYSDATE                             -- 18.�ŏI�X�V��
                   ,last_update_login       = cn_last_update_login                -- 19.�ŏI�X�V���O�C��
                   ,request_id              = cn_request_id                       -- 20.�v��ID
                   ,program_application_id  = cn_program_application_id           -- 21.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                   ,program_id              = cn_program_id                       -- 22.�R���J�����g�E�v���O����ID
                   ,program_update_date     = SYSDATE                             -- 23.�v���O�����X�V��
            WHERE   base_code               = lt_base_code
            AND     practice_date           = lt_transaction_date
            AND     inventory_item_id       = lt_inventory_item_id;
            --
          END IF;
        END IF;
      END IF;
      --
      -- �Ώۃf�[�^�����̏ꍇ�ALOOP�����I��
      EXIT set_vd_info_loop WHEN vd_rep_cur%NOTFOUND;
      --
      --
      -- ===================================
      --  �󕥏W�v�L�[�ʎ�����ʏW�v
      -- ===================================
      CASE vd_rep_rec.transaction_type
        WHEN  cv_trans_type_160 THEN        -- ��݌ɕύX
          IF (vd_rep_rec.transaction_quantity >= 0) THEN
            -- ������ʂ��v���X�̏ꍇ�A�x���_����
            gt_quantity(1)  :=  gt_quantity(1) + vd_rep_rec.transaction_quantity;
            --
          ELSE
            -- ������ʂ��}�C�i�X�̏ꍇ�A�x���_�o��
            gt_quantity(2)  :=  gt_quantity(2) + vd_rep_rec.transaction_quantity;
          END IF;
          --
        WHEN  cv_trans_type_300 THEN        -- ���_����VD�݌ɐU��
          IF (vd_rep_rec.transaction_quantity >= 0) THEN
            -- ������ʂ��v���X�̏ꍇ�A�x���_�ړ�����
            gt_quantity(3)  :=  gt_quantity(3) + vd_rep_rec.transaction_quantity;
            --
          ELSE
            -- ������ʂ��}�C�i�X�̏ꍇ�A�x���_�ړ��o��
            gt_quantity(4)  :=  gt_quantity(4) + vd_rep_rec.transaction_quantity;
          END IF;
          --
        ELSE  NULL;
      END CASE;
      --
      --
      -- �Ώۃf�[�^�ێ�
      lt_base_code          :=  vd_rep_rec.base_code;
      lt_inventory_item_id  :=  vd_rep_rec.inventory_item_id;
      lt_transaction_date   :=  vd_rep_rec.transaction_date;
      lt_xvri_base_code     :=  vd_rep_rec.xvri_base_code;
      --
      -- �Ώۃf�[�^�擾
      FETCH vd_rep_cur  INTO  vd_rep_rec;
      --
    END LOOP set_vd_info_loop;
    --
    CLOSE vd_rep_cur;
    --
  EXCEPTION
    -- *** �����ΏۂȂ� ***
    WHEN zero_data_expt THEN
      NULL;
      --
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (vd_rep_cur%ISOPEN) THEN
        CLOSE vd_rep_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (vd_rep_cur%ISOPEN) THEN
        CLOSE vd_rep_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (vd_rep_cur%ISOPEN) THEN
        CLOSE vd_rep_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_vd_reception_info;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_param_name   fnd_lookup_values.meaning%TYPE;       -- ���̓p�����[�^����
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===================================
    --  1.�N���p�����[�^���O�o��
    -- ===================================
    -- �N���p�����[�^���̎擾
    lt_param_name :=  xxcoi_common_pkg.get_meaning(
                        iv_lookup_type      =>    cv_lookup_type
                       ,iv_lookup_code      =>    gv_param_exec_flag
                      );
    --
    IF (lt_param_name IS NULL) THEN
      --  �N���t���O���擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_10367
                       ,iv_token_name1  => cv_token_10367_1
                       ,iv_token_value1 => cv_lookup_type
                       ,iv_token_name2  => cv_token_10367_2
                       ,iv_token_value2 => gv_param_exec_flag
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �R���J�����g���̓p�����[�^
    gv_out_msg  :=  xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_short_name
                     ,iv_name         =>  cv_msg_xxcoi1_10365
                     ,iv_token_name1  =>  cv_token_10365_1
                     ,iv_token_value1 =>  lt_param_name
                    );
    --
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  gv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(which       =>  FND_FILE.OUTPUT
                     ,buff        =>  cv_space
    );
    --
    -- ===================================
    --  2.�Ɩ��������t�擾
    -- ===================================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    gv_f_last_month     :=  TO_CHAR(ADD_MONTHS(gd_f_process_date, -1), cv_month);
    --
    IF (gd_f_process_date IS NULL) THEN
      -- �Ɩ��������t�擾�G���[���b�Z�[�W
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errbuf   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  3.�݌ɑg�D�R�[�h�擾
    -- ===================================
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00005
                      ,iv_token_name1  => cv_token_00005_1
                      ,iv_token_value1 => cv_prf_name_orgcd
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  4.�݌ɑg�DID�擾
    -- ===================================
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name
                      ,iv_name         => cv_msg_xxcoi1_00006
                      ,iv_token_name1  => cv_token_00006_1
                      ,iv_token_value1 => gv_f_organization_code
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===================================
    --  5.WHO�J�����擾
    -- ===================================
    -- �O���[�o���Œ�l�̐ݒ蕔�Ŏ擾���Ă��܂��B
    --
    -- ===================================
    --  6.�I�[�v���݌ɉ�v���ԏ��擾
    -- ===================================
    SELECT  MIN(TO_CHAR(oap.period_start_date, cv_month)) -- �ł��Â���v�N��
    INTO    gv_f_inv_acct_period
    FROM    org_acct_periods      oap                     -- �݌ɉ�v���ԃe�[�u��
    WHERE   oap.organization_id   =   gn_f_organization_id
    AND     oap.open_flag         =   cv_yes;
    --
    -- ===================================
    --  7.�O��A�g�� ���ID�擾
    -- ===================================
    BEGIN
      SELECT  xcc.transaction_id                              -- �����ώ��ID
      INTO    gn_f_last_transaction_id
      FROM    xxcoi_cooperation_control   xcc         -- �f�[�^�A�g����e�[�u��
      WHERE   control_id    =   cn_control_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gn_f_last_transaction_id  :=  0;
    END;
    --
    -- ===================================
    --  8.�ő����h�c�擾�i���ގ���j
    -- ===================================
    BEGIN
      SELECT  MAX(mmt.transaction_id)
      INTO    gn_f_max_transaction_id
      FROM    mtl_material_transactions   mmt
      WHERE   mmt.organization_id   =   gn_f_organization_id
      AND     mmt.transaction_id   >=   gn_f_last_transaction_id;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �ő���ID�擾�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name
                        ,iv_name         => cv_msg_xxcoi1_10127
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_exec_flag      IN  VARCHAR2,     -- 1.�N���t���O
    ov_errbuf         OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
    -- ���̓p�����[�^�ێ�
    gv_param_exec_flag  :=  iv_exec_flag;
    --
    -- =====================================
    --  1.��������(A-1)
    -- =====================================
    init(
      ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^�`�F�b�N
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
        -- =====================================
    --  2.�����f�[�^VD�󕥏��o��(A-2, A-3)
    -- =====================================
    set_vd_reception_info(
      ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^�`�F�b�N
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    --  3.�O��VD�󕥃f�[�^����(A-4, A-5)
    -- =====================================
    IF (gv_param_exec_flag = cv_exec_flag_2) THEN
      -- �����N���̏ꍇ�̂ݎ��s
      set_last_month_data(
        ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^�`�F�b�N
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
    -- =====================================
    --  4.�����ώ��ID�X�V(A-6)
    -- =====================================
    set_cooperation_data(
      ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^�`�F�b�N
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================
    --  5.�I������(A-7)
    -- =====================================
    finalize(
      ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^�`�F�b�N
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
  EXCEPTION
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
    errbuf              OUT VARCHAR2,       -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,       -- ���^�[���E�R�[�h    --# �Œ� #
    iv_exec_flag        IN  VARCHAR2        -- 1.�N���t���O
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
        iv_exec_flag        =>  iv_exec_flag        -- 1.�N���t���O
       ,ov_errbuf           =>  lv_errbuf           -- �G���[�E���b�Z�[�W             --# �Œ� #
       ,ov_retcode          =>  lv_retcode          -- ���^�[���E�R�[�h               --# �Œ� #
       ,ov_errmsg           =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      -- ���������ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
      --
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s���o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_space
      );
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s���o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_space
    );
    --
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
    fnd_file.put_line(
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
END XXCOI006A22C;
/
