CREATE OR REPLACE PACKAGE BODY XXCOI009A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI009A05R(body)
 * Description      : �����u�c���i�ʃ`�F�b�N���X�g
 * MD.050           : �����u�c���i�ʃ`�F�b�N���X�g <MD050_XXCOI_009_A05>
 * Version          : V1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_svf_data            ���[�N�e�[�u���f�[�^�폜    (A-7)
 *  call_output_svf         SVF�N��                     (A-6)
 *  ins_svf_data            ���o�ɏ��擾              (A-3)
 *                          �����v�Z���擾            (A-4)
 *                          ���[�N�e�[�u���f�[�^�o�^    (A-5)
 *  get_base_info           ���_���擾                (A-2)
 *  init                    ��������                    (A-1)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/02    1.0   H.Sasaki         ���ō쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100)  :=  'XXCOI009A05R';           --  �p�b�P�[�W��
  -- SVF�N���֐��p�����[�^�p
  cv_conc_name              CONSTANT VARCHAR2(30)   :=  'XXCOI009A05R';           --  �R���J�����g��
  cv_file_id                CONSTANT VARCHAR2(30)   :=  'XXCOI009A05R';           --  ���[ID
  cv_type_pdf               CONSTANT VARCHAR2(4)    :=  '.pdf';                   --  �g���q�iPDF�j
  cv_output_mode            CONSTANT VARCHAR2(30)   :=  '1';                      --  �o�͋敪
  cv_frm_file               CONSTANT VARCHAR2(30)   :=  'XXCOI009A05S.xml';       --  �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(30)   :=  'XXCOI009A05S.vrq';       --  �N�G���[�l���t�@�C����
  -- ���b�Z�[�W
  cv_short_name_xxcoi       CONSTANT VARCHAR2(5)    :=  'XXCOI';                  --  �A�v���P�[�V�����Z�k��
  cv_msg_xxcoi1_00005       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00005';       --  �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00006       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00006';       --  �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00008       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00008';       --  �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_00009       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00009';       --  ���_���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00011       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00011';       --  �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_00019       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-00019';       --  �ڋq���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10119       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10119';       --  SVF�N��API�G���[���b�Z�[�W
  cv_msg_xxcoi1_10337       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10337';       --  ���t�p�����[�^�������G���[���b�Z�[�W
  cv_msg_xxcoi1_10414       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10414';       --  ���_���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10415       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10415';       --  ����VD���i�ʃ`�F�b�N���X�g�p�����[�^�l���b�Z�[�W
  cv_msg_xxcoi1_10416       CONSTANT VARCHAR2(30)   :=  'APP-XXCOI1-10416';       --  ���t�p�����[�^�w��͈̓G���[���b�Z�[�W
  -- ���b�Z�[�W�i�g�[�N���j
  cv_token_00005            CONSTANT VARCHAR2(30)   :=  'PRO_TOK';
  cv_token_00006            CONSTANT VARCHAR2(30)   :=  'ORG_CODE_TOK ';
  cv_token_00009            CONSTANT VARCHAR2(30)   :=  'DEPT_CODE_TOK';
  cv_token_00019            CONSTANT VARCHAR2(30)   :=  'CUSTOMER_CODE';
  cv_token_10414            CONSTANT VARCHAR2(30)   :=  'BASE_CODE';
  cv_token_10415_1          CONSTANT VARCHAR2(30)   :=  'BASE_CODE';
  cv_token_10415_2          CONSTANT VARCHAR2(30)   :=  'BASE_NAME';
  cv_token_10415_3          CONSTANT VARCHAR2(30)   :=  'DATE_FROM';
  cv_token_10415_4          CONSTANT VARCHAR2(30)   :=  'DATE_TO';
  cv_token_10415_5          CONSTANT VARCHAR2(30)   :=  'CONCLUSION_DAY';
  cv_token_10415_6          CONSTANT VARCHAR2(30)   :=  'CUST_CODE';
  cv_token_10415_7          CONSTANT VARCHAR2(30)   :=  'CUST_NAME';
  --
  cv_log                    CONSTANT VARCHAR2(3)    :=  'LOG';                -- �R���J�����g�w�b�_�o�͐�
  --
  -- �v���t�@�C��
  cv_prf_name_orgcd         CONSTANT VARCHAR2(30)   :=  'XXCOI1_ORGANIZATION_CODE';   -- �v���t�@�C�����i�݌ɑg�D�R�[�h�j
  -- �R�[�h�l
  cv_invoice_type_4         CONSTANT VARCHAR2(1)    :=  '4';                      --  �`�[�敪 4
  cv_invoice_type_5         CONSTANT VARCHAR2(1)    :=  '5';                      --  �`�[�敪 5
  cv_invoice_type_6         CONSTANT VARCHAR2(1)    :=  '6';                      --  �`�[�敪 6
  cv_invoice_type_7         CONSTANT VARCHAR2(1)    :=  '7';                      --  �`�[�敪 7
  cv_record_type_30         CONSTANT VARCHAR2(2)    :=  '30';                     --  ���R�[�h�^�C�v  30 ���o��
  cv_cust_class_1           CONSTANT VARCHAR2(1)    :=  '1';                      --  �ڋq�敪 1  ���_
  cv_cust_class_10          CONSTANT VARCHAR2(2)    :=  '10';                     --  �ڋq�敪 10 �ڋq
  -- ���̑�
  cv_yes                    CONSTANT VARCHAR2(1)    :=  'Y';
  cv_no                     CONSTANT VARCHAR2(1)    :=  'N';
  cv_d                      CONSTANT VARCHAR2(1)    :=  'D';
  cv_space                  CONSTANT VARCHAR2(1)    :=  ' ';
  cv_comma                  CONSTANT VARCHAR2(1)    :=  ',';
  cv_slash                  CONSTANT VARCHAR2(1)    :=  '/';
  cv_date_type              CONSTANT VARCHAR2(8)    :=  'YYYYMMDD';
  cv_date_type_2            CONSTANT VARCHAR2(10)   :=  'YYYY/MM/DD';
  cv_date_type_3            CONSTANT VARCHAR2(21)   :=  'YYYY/MM/DD HH24:MI:SS';
  cv_date_type_4            CONSTANT VARCHAR2(7)    :=  'YYYY/MM';
  cv_default_time           CONSTANT VARCHAR2(8)    :=  '00:00:00';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���_���
  TYPE  g_base_info_rtype   IS  RECORD(
      base_code     xxcoi_rep_vd_item_chklist.base_code%TYPE          --  ���_�R�[�h
    , base_name     xxcoi_rep_vd_item_chklist.base_name%TYPE          --  ���_����
  );
  TYPE  g_base_info_ttype   IS  TABLE OF g_base_info_rtype INDEX BY BINARY_INTEGER;
  tab_base_info     g_base_info_ttype;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gt_base_code              xxcoi_rep_vd_item_chklist.base_code%TYPE;             --  ���_�R�[�h
  gd_date_from              DATE;                                                 --  �o�͊���(FROM)
  gd_date_to                DATE;                                                 --  �o�͊���(TO)
  gt_conclusion_day         xxcoi_rep_vd_item_chklist.conclusion_day_param%TYPE;  --  ���ߓ�
  gt_customer_code          xxcoi_rep_vd_item_chklist.customer_code%TYPE;         --  �ڋq�R�[�h
  --
  -- ���ʃf�[�^
  gv_f_organization_code    VARCHAR2(30);                                     --  �݌ɑg�D�R�[�h
  gn_f_organization_id      NUMBER;                                           --  �݌ɑg�DID
  gd_f_process_date         DATE;                                             --  �Ɩ��������t
  gv_nodata_msg             VARCHAR2(5000);                                   --  �Ώۃf�[�^�Ȃ����b�Z�[�W
  --
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE del_svf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_svf_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ���[���[�N�e�[�u���̍폜�i����Ώۃf�[�^�̂݁j
    DELETE  xxcoi_rep_vd_item_chklist
    WHERE   request_id    =   cn_request_id;
    --
  EXCEPTION
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
  END del_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : call_output_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE call_output_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_output_svf'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    -- ===============================
    --  1.SVF�N��
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name         =>    cv_conc_name                        -- �R���J�����g��
      ,iv_file_name         =>    cv_file_id 
                              ||  TO_CHAR(SYSDATE, cv_date_type)
                              ||  TO_CHAR(cn_request_id)
                              ||  cv_type_pdf                         -- �o�̓t�@�C����
      ,iv_file_id           =>    cv_file_id                          -- ���[ID
      ,iv_output_mode       =>    cv_output_mode                      -- �o�͋敪
      ,iv_frm_file          =>    cv_frm_file                         -- �t�H�[���l���t�@�C����
      ,iv_vrq_file          =>    cv_vrq_file                         -- �N�G���[�l���t�@�C����
      ,iv_org_id            =>    fnd_global.org_id                   -- ORG_ID
      ,iv_user_name         =>    fnd_global.user_name                -- ���O�C���E���[�U��
      ,iv_resp_name         =>    fnd_global.resp_name                -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name          =>    NULL                                -- ������
      ,iv_printer_name      =>    NULL                                -- �v�����^��
      ,iv_request_id        =>    cn_request_id                       -- �v��ID
      ,iv_nodata_msg        =>    NULL                                -- �f�[�^�Ȃ����b�Z�[�W
      ,ov_retcode           =>    lv_retcode                          -- ���^�[���R�[�h
      ,ov_errbuf            =>    lv_errbuf                           -- �G���[���b�Z�[�W
      ,ov_errmsg            =>    lv_errmsg                           -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �I���p�����[�^����
    IF (lv_retcode  <>  cv_status_normal) THEN
      -- SVF�N��API�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10119
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF; 
   --
  EXCEPTION
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : edit_conclusion_day
   * Description      : ���ߓ��ҏW����
   ***********************************************************************************/
  PROCEDURE edit_conclusion_day(
    iv_material1  IN  VARCHAR2,     --  ���ߓ��P
    iv_material2  IN  VARCHAR2,     --  ���ߓ��Q
    iv_material3  IN  VARCHAR2,     --  ���ߓ��R
    ov_conc_day   OUT VARCHAR2,     --  ���ߓ�
    ov_errbuf     OUT VARCHAR2,     --  �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --  ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_conclusion_day'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �ݒ肳��Ă�����ߓ����A���t���ɃJ���}��؂�łP�f�[�^�ɕҏW
    IF (iv_material1 IS NOT NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NOT NULL) THEN
      IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material2)) THEN
        IF (TO_NUMBER(iv_material2) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material1 || cv_comma || iv_material2 || cv_comma || iv_material3;
        ELSIF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material1 || cv_comma || iv_material3 || cv_comma || iv_material2;
        ELSE
          ov_conc_day :=  iv_material3 || cv_comma || iv_material1 || cv_comma || iv_material2;
        END IF;
      ELSE
        IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material2 || cv_comma || iv_material1 || cv_comma || iv_material3;
        ELSIF (TO_NUMBER(iv_material2) <= TO_NUMBER(iv_material3)) THEN
          ov_conc_day :=  iv_material2 || cv_comma || iv_material3 || cv_comma || iv_material1;
        ELSE
          ov_conc_day :=  iv_material3 || cv_comma || iv_material2 || cv_comma || iv_material1;
        END IF;
      END IF;
    ELSIF (iv_material1 IS NOT NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NULL) THEN
      IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material2)) THEN
        ov_conc_day :=  iv_material1 || cv_comma || iv_material2;
      ELSE
        ov_conc_day :=  iv_material2 || cv_comma || iv_material1;
      END IF;
    ELSIF (iv_material1 IS NOT NULL AND iv_material2 IS NULL AND iv_material3 IS NOT NULL) THEN
      IF (TO_NUMBER(iv_material1) <= TO_NUMBER(iv_material3)) THEN
        ov_conc_day :=  iv_material1 || cv_comma || iv_material3;
      ELSE
        ov_conc_day :=  iv_material3 || cv_comma || iv_material1;
      END IF;
    ELSIF (iv_material1 IS NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NOT NULL) THEN
      IF (TO_NUMBER(iv_material2) <= TO_NUMBER(iv_material3)) THEN
        ov_conc_day :=  iv_material2 || cv_comma || iv_material3;
      ELSE
        ov_conc_day :=  iv_material3 || cv_comma || iv_material2;
      END IF;
    ELSIF (iv_material1 IS NOT NULL AND iv_material2 IS NULL AND iv_material3 IS NULL) THEN
      ov_conc_day :=  iv_material1;
    ELSIF (iv_material1 IS NULL AND iv_material2 IS NOT NULL AND iv_material3 IS NULL) THEN
      ov_conc_day :=  iv_material2;
    ELSIF (iv_material1 IS NULL AND iv_material2 IS NULL AND iv_material3 IS NOT NULL) THEN
      ov_conc_day :=  iv_material3;
    ELSE
      ov_conc_day :=  NULL;
    END IF;
    --
  EXCEPTION
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
  END edit_conclusion_day;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : ���o�ɏ��擾            (A-3)
   *                  : �����v�Z���擾          (A-4)
   *                  : ���[�N�e�[�u���f�[�^�o�^  (A-5)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    iv_base_code  IN  VARCHAR2,     --  ���_
    iv_base_name  IN  VARCHAR2,     --  ���_����
    ov_errbuf     OUT VARCHAR2,     --  �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --  ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_svf_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_conc_day                 VARCHAR2(8);                  --  �ҏW���ߓ�
    ln_target_cnt               NUMBER  :=  0;                --  ���_�ʑΏی���
    ln_dummy                    NUMBER;                       --  �_�~�[
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR  cur_tran_data
    IS
      SELECT  sub.base_code                   base_code         --  ���_
            , hca2.account_name               base_name         --  ���_����
            , sub.account_number              customer_code     --  �ڋq
            , hp.party_name                   customer_name     --  �ڋq����
            , sub.item_code                   item_code         --  �i�ڃR�[�h
            , ximb.item_short_name            item_name         --  �i�ږ���
            , xca.conclusion_day1             conclusion_day1   --  �����v�Z���ߓ��P
            , xca.conclusion_day2             conclusion_day2   --  �����v�Z���ߓ��Q
            , xca.conclusion_day3             conclusion_day3   --  �����v�Z���ߓ��R
            , SUM(
                    CASE  WHEN  sub.data_type = 1 THEN  sub.quantity
                          ELSE  0
                    END
              )     stock_quantity            --  ���ɐ���
            , SUM(
                    CASE  WHEN  sub.data_type = 2 THEN  sub.quantity
                          ELSE  0
                    END
              )     ship_quantity             --  �o�ɐ���
      FROM    hz_cust_accounts                    hca1                          --  �ڋq�}�X�^�i�ڋq�j
            , hz_cust_accounts                    hca2                          --  �ڋq�}�X�^�i���_�j
            , xxcmm_cust_accounts                 xca                           --  �ڋq�A�h�I��
            , hz_parties                          hp                            --  �p�[�e�B�[
            , mtl_system_items_b                  msib                          --  �i�ڃ}�X�^
            , ic_item_mst_b                       iimb                          --  OPM�i��
            , xxcmn_item_mst_b                    ximb                          --  OPM�i�ڃA�h�I��
            , ( SELECT
                        xhit.base_code                base_code                 --  ���_
                      , xhit.inside_code              account_number            --  �ڋq�i���ɑ��j
                      , xhit.item_code                item_code                 --  �i��
                      , NVL(xhit.total_quantity, 0)   quantity                  --  ����
                      , 1                             data_type                 --  �f�[�^�^�C�v�i1:���ɑ��j
                FROM    xxcoi_hht_inv_transactions    xhit                      --  HHT���o�Ɉꎞ�\
                      , hz_cust_accounts              hca                       --  �ڋq�}�X�^
                WHERE   xhit.invoice_date             >=  gd_date_from
                AND     xhit.invoice_date             <   gd_date_to + 1
                AND     xhit.invoice_type             IN(cv_invoice_type_4, cv_invoice_type_5, cv_invoice_type_6, cv_invoice_type_7)
                AND     xhit.record_type              =   cv_record_type_30
                AND     xhit.consume_vd_flag          =   cv_yes
                AND     xhit.inside_code              =   hca.account_number
                AND     xhit.base_code                =   iv_base_code
                AND     xhit.inside_code              =   NVL(gt_customer_code, xhit.inside_code)
                AND     hca.customer_class_code       =   cv_cust_class_10
                UNION ALL
                SELECT
                        xhit.base_code                base_code                 --  ���_
                      , xhit.outside_code             account_number            --  �ڋq�i�o�ɑ��j
                      , xhit.item_code                item_code                 --  �i��
                      , NVL(xhit.total_quantity, 0)   quantity                  --  ����
                      , 2                             data_type                 --  �f�[�^�^�C�v�i2:�o�ɑ��j
                FROM    xxcoi_hht_inv_transactions    xhit                      --  HHT���o�Ɉꎞ�\
                      , hz_cust_accounts              hca                       --  �ڋq�}�X�^
                WHERE   xhit.invoice_date             >=  gd_date_from
                AND     xhit.invoice_date             <   gd_date_to + 1
                AND     xhit.invoice_type             IN(cv_invoice_type_4, cv_invoice_type_5, cv_invoice_type_6, cv_invoice_type_7)
                AND     xhit.record_type              =   cv_record_type_30
                AND     xhit.consume_vd_flag          =   cv_yes
                AND     xhit.outside_code             =   hca.account_number
                AND     xhit.base_code                =   iv_base_code
                AND     xhit.outside_code             =   NVL(gt_customer_code, xhit.outside_code)
                AND     hca.customer_class_code       =   cv_cust_class_10
              )     sub
      WHERE   sub.account_number        =   hca1.account_number
      AND     sub.item_code             =   msib.segment1
      AND     sub.base_code             =   hca2.account_number
      AND     hca1.cust_account_id      =   xca.customer_id
      AND     hca1.party_id             =   hp.party_id
      AND     msib.segment1             =   iimb.item_no
      AND     iimb.item_id              =   ximb.item_id
      AND     hca1.customer_class_code  =   cv_cust_class_10
      AND     hca2.customer_class_code  =   cv_cust_class_1
      AND     msib.organization_id      =   gn_f_organization_id
      AND     (   xca.conclusion_day1   =   gt_conclusion_day
               OR xca.conclusion_day2   =   gt_conclusion_day
               OR xca.conclusion_day3   =   gt_conclusion_day
              )
      AND     gd_f_process_date   BETWEEN   ximb.start_date_active
                                  AND       NVL(ximb.end_date_active, gd_f_process_date)
      GROUP BY
              sub.base_code
            , hca2.account_name
            , sub.account_number
            , hp.party_name
            , sub.item_code
            , ximb.item_short_name
            , xca.conclusion_day1
            , xca.conclusion_day2
            , xca.conclusion_day3;
    --
    CURSOR  cur_digestion_due
    IS
      SELECT  xvdh.sales_base_code        base_code         --  ���_
            , hca2.account_name           base_name         --  ���_����
            , xvdh.customer_number        customer_code     --  �ڋq
            , hp.party_name               customer_name     --  �ڋq����
            , xvdl.item_code              item_code         --  �i�ڃR�[�h
            , ximb.item_short_name        item_name         --  �i�ږ���
            , xca.conclusion_day1         conclusion_day1   --  �����v�Z���ߓ��P
            , xca.conclusion_day2         conclusion_day2   --  �����v�Z���ߓ��Q
            , xca.conclusion_day3         conclusion_day3   --  �����v�Z���ߓ��R
            , SUM(CASE  WHEN  xvdh.sales_result_creation_flag IN(cv_yes, cv_d) THEN xvdl.sales_quantity
                        ELSE 0
                  END
              )                           sales_quantity    --  ����v���
            , SUM(CASE  WHEN  (xvdh.sales_result_creation_flag = cv_no OR xvdh.sales_result_creation_flag IS NULL) THEN xvdl.sales_quantity
                        ELSE 0
                  END
              )                           digestion_due_qty --  ��������v�Z�Ώ�
      FROM    xxcos_vd_digestion_lns      xvdl              --  ����VD�p�����v�Z���׃e�[�u��
            , xxcos_vd_digestion_hdrs     xvdh              --  ����VD�p�����v�Z�w�b�_�e�[�u��
            , hz_cust_accounts            hca1              --  �ڋq�}�X�^�i�ڋq�j
            , hz_cust_accounts            hca2              --  �ڋq�}�X�^�i���_�j
            , xxcmm_cust_accounts         xca               --  �ڋq�A�h�I��
            , hz_parties                  hp                --  �p�[�e�B�[
            , mtl_system_items_b          msib              --  �i�ڃ}�X�^
            , ic_item_mst_b               iimb              --  OPM�i�ڃ}�X�^
            , xxcmn_item_mst_b            ximb              --  OPM�i�ڃA�h�I��
      WHERE   xvdh.vd_digestion_hdr_id  =   xvdl.vd_digestion_hdr_id
      AND     xvdh.sales_base_code      =   hca2.account_number
      AND     xvdh.customer_number      =   hca1.account_number
      AND     hca1.cust_account_id      =   xca.customer_id
      AND     hca1.party_id             =   hp.party_id
      AND     xvdl.item_code            =   msib.segment1
      AND     msib.segment1             =   iimb.item_no
      AND     iimb.item_id              =   ximb.item_id
      AND     xvdh.sales_base_code      =   iv_base_code
      AND     xvdh.customer_number      =   NVL(gt_customer_code, xvdh.customer_number)
      AND     xvdh.digestion_due_date   >=  gd_date_from
      AND     xvdh.digestion_due_date   <   gd_date_to + 1
      AND     xvdh.uncalculate_class    IN('0', '2', '4')
      AND     hca1.customer_class_code  =   cv_cust_class_10
      AND     hca2.customer_class_code  =   cv_cust_class_1
      AND     msib.organization_id      =   gn_f_organization_id
      AND     (   xca.conclusion_day1   =   gt_conclusion_day
               OR xca.conclusion_day2   =   gt_conclusion_day
               OR xca.conclusion_day3   =   gt_conclusion_day
              )
      AND     gd_f_process_date   BETWEEN   ximb.start_date_active
                                  AND       NVL(ximb.end_date_active, gd_f_process_date)
      GROUP BY
              xvdh.sales_base_code
            , hca2.account_name
            , xvdh.customer_number
            , hp.party_name
            , xvdl.item_code
            , ximb.item_short_name
            , xca.conclusion_day1
            , xca.conclusion_day2
            , xca.conclusion_day3;
    --
    -- <�J�[�\����>���R�[�h�^
    rec_tran_data       cur_tran_data%ROWTYPE;
    rec_digestion_due   cur_digestion_due%ROWTYPE;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    -- ===========================================
    --  ���o�ɏ��ݒ�
    -- ===========================================
    OPEN  cur_tran_data;
    --
    LOOP
      FETCH cur_tran_data INTO  rec_tran_data;
      EXIT WHEN cur_tran_data%NOTFOUND;
      ln_target_cnt :=  ln_target_cnt + 1;
      --
      -- ------------------------
      --  ���ߓ��ҏW
      -- ------------------------
      edit_conclusion_day(
          iv_material1  =>  rec_tran_data.conclusion_day1
        , iv_material2  =>  rec_tran_data.conclusion_day2
        , iv_material3  =>  rec_tran_data.conclusion_day3
        , ov_conc_day   =>  lv_conc_day
        , ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      INSERT INTO xxcoi_rep_vd_item_chklist(
          base_code                             --  01.���_�R�[�h
        , base_name                             --  02.���_��
        , customer_code                         --  03.�ڋq�R�[�h
        , customer_name                         --  04.�ڋq����
        , item_code                             --  05.�i�ڃR�[�h
        , item_name                             --  06.�i�ږ���
        , date_from                             --  07.�o�͊��ԁiFrom)
        , date_to                               --  08.�o�͊��ԁiTo)
        , conclusion_day_param                  --  09.���ߓ��i�w��j
        , conclusion_day                        --  10.���ߓ�
        , stock_qty                             --  11.���ɐ���
        , ship_qty                              --  12.�o�ɐ���
        , sales_qty                             --  13.����v��ϐ���
        , digestion_due_qty                     --  14.��������v�Z�Ώې���
        , customer_specify_flag                 --  15.�ڋq�w��
        , message                               --  16.���b�Z�[�W
        , created_by                            --  17.�쐬��
        , creation_date                         --  18.�쐬��
        , last_updated_by                       --  19.�ŏI�X�V��
        , last_update_date                      --  20.�ŏI�X�V��
        , last_update_login                     --  21.�ŏI�X�V���O�C��
        , request_id                            --  22.�v��ID
        , program_application_id                --  23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                            --  24.�R���J�����g�E�v���O����ID
        , program_update_date                   --  25.�v���O�����X�V��
      )VALUES(
          rec_tran_data.base_code                       --  01
        , SUBSTRB(rec_tran_data.base_name, 1, 20)       --  02
        , rec_tran_data.customer_code                   --  03
        , SUBSTRB(rec_tran_data.customer_name, 1, 80)   --  04
        , rec_tran_data.item_code                       --  05
        , SUBSTRB(rec_tran_data.item_name, 1, 20)       --  06
        , TO_CHAR(gd_date_from, cv_date_type_2)         --  07
        , TO_CHAR(gd_date_to, cv_date_type_2)           --  08
        , gt_conclusion_day                             --  09
        , lv_conc_day                                   --  10
        , rec_tran_data.stock_quantity                  --  11
        , rec_tran_data.ship_quantity                   --  12
        , 0                                             --  13
        , 0                                             --  14
        , CASE  WHEN  gt_customer_code IS NULL THEN  '0'
                ELSE  '1'
          END                                           --  15
        , NULL                                          --  16
        , cn_created_by                                 --  17
        , SYSDATE                                       --  18
        , cn_last_updated_by                            --  19
        , SYSDATE                                       --  20
        , cn_last_update_login                          --  21
        , cn_request_id                                 --  22
        , cn_program_application_id                     --  23
        , cn_program_id                                 --  24
        , SYSDATE                                       --  25
      );
    END LOOP;
    --
    CLOSE cur_tran_data;
    --
    -- ===========================================
    --  �����v�Z���ݒ�
    -- ===========================================
    OPEN cur_digestion_due;
    --
    <<digestion_due_loop>>
    LOOP
      FETCH cur_digestion_due INTO  rec_digestion_due;
      EXIT WHEN cur_digestion_due%NOTFOUND;
      --
      BEGIN
        SELECT  1
        INTO    ln_dummy
        FROM    xxcoi_rep_vd_item_chklist   xrvic
        WHERE   xrvic.base_code       =   rec_digestion_due.base_code
        AND     xrvic.customer_code   =   rec_digestion_due.customer_code
        AND     xrvic.item_code       =   rec_digestion_due.item_code
        AND     xrvic.request_id      =   cn_request_id;
        --
        UPDATE  xxcoi_rep_vd_item_chklist
        SET     sales_qty             =   rec_digestion_due.sales_quantity      --  14.����v��ϐ���
              , digestion_due_qty     =   rec_digestion_due.digestion_due_qty   --  15.��������v�Z�Ώې���
        WHERE   base_code             =   rec_digestion_due.base_code
        AND     customer_code         =   rec_digestion_due.customer_code
        AND     item_code             =   rec_digestion_due.item_code
        AND     request_id            =   cn_request_id;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_target_cnt :=  ln_target_cnt + 1;
          --
          -- ------------------------
          --  ���ߓ��ҏW
          -- ------------------------
          edit_conclusion_day(
              iv_material1  =>  rec_digestion_due.conclusion_day1
            , iv_material2  =>  rec_digestion_due.conclusion_day2
            , iv_material3  =>  rec_digestion_due.conclusion_day3
            , ov_conc_day   =>  lv_conc_day
            , ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
            , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
            , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          INSERT INTO xxcoi_rep_vd_item_chklist(
              base_code                             --  01.���_�R�[�h
            , base_name                             --  02.���_��
            , customer_code                         --  03.�ڋq�R�[�h
            , customer_name                         --  04.�ڋq����
            , item_code                             --  05.�i�ڃR�[�h
            , item_name                             --  06.�i�ږ���
            , date_from                             --  07.�o�͊��ԁiFrom)
            , date_to                               --  08.�o�͊��ԁiTo)
            , conclusion_day_param                  --  09.���ߓ��i�w��j
            , conclusion_day                        --  10.���ߓ�
            , stock_qty                             --  11.���ɐ���
            , ship_qty                              --  12.�o�ɐ���
            , sales_qty                             --  13.����v��ϐ���
            , digestion_due_qty                     --  14.��������v�Z�Ώې���
            , customer_specify_flag                 --  15.�ڋq�w��
            , message                               --  16.���b�Z�[�W
            , created_by                            --  17.�쐬��
            , creation_date                         --  18.�쐬��
            , last_updated_by                       --  19.�ŏI�X�V��
            , last_update_date                      --  20.�ŏI�X�V��
            , last_update_login                     --  21.�ŏI�X�V���O�C��
            , request_id                            --  22.�v��ID
            , program_application_id                --  23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                            --  24.�R���J�����g�E�v���O����ID
            , program_update_date                   --  25.�v���O�����X�V��
          )VALUES(
              rec_digestion_due.base_code                       --  01
            , SUBSTRB(rec_digestion_due.base_name, 1, 20)       --  02
            , rec_digestion_due.customer_code                   --  03
            , SUBSTRB(rec_digestion_due.customer_name, 1, 80)   --  04
            , rec_digestion_due.item_code                       --  05
            , SUBSTRB(rec_digestion_due.item_name, 1, 20)       --  06
            , TO_CHAR(gd_date_from, cv_date_type_2)             --  07
            , TO_CHAR(gd_date_to, cv_date_type_2)               --  08
            , gt_conclusion_day                                 --  09
            , lv_conc_day                                       --  10
            , 0                                                 --  11
            , 0                                                 --  12
            , rec_digestion_due.sales_quantity                  --  13
            , rec_digestion_due.digestion_due_qty               --  14
            , CASE  WHEN  gt_customer_code IS NULL THEN  '0'
                    ELSE  '1'
              END                                               --  15
            , NULL                                              --  16
            , cn_created_by                                     --  17
            , SYSDATE                                           --  18
            , cn_last_updated_by                                --  19
            , SYSDATE                                           --  20
            , cn_last_update_login                              --  21
            , cn_request_id                                     --  22
            , cn_program_application_id                         --  23
            , cn_program_id                                     --  24
            , SYSDATE                                           --  25
          );
      END;
      --
    END LOOP;
    --
    CLOSE cur_digestion_due;
    --
    --
    -- ===========================================
    --  �Ώی����O�����ݒ�
    -- ===========================================
    IF (ln_target_cnt = 0) THEN
      --
      INSERT INTO xxcoi_rep_vd_item_chklist(
          base_code                             --  01.���_�R�[�h
        , base_name                             --  02.���_��
        , customer_code                         --  03.�ڋq�R�[�h
        , customer_name                         --  04.�ڋq����
        , item_code                             --  05.�i�ڃR�[�h
        , item_name                             --  06.�i�ږ���
        , date_from                             --  07.�o�͊��ԁiFrom)
        , date_to                               --  08.�o�͊��ԁiTo)
        , conclusion_day_param                  --  09.���ߓ��i�w��j
        , conclusion_day                        --  10.���ߓ�
        , stock_qty                             --  11.���ɐ���
        , ship_qty                              --  12.�o�ɐ���
        , sales_qty                             --  13.����v��ϐ���
        , digestion_due_qty                     --  14.��������v�Z�Ώې���
        , customer_specify_flag                 --  15.�ڋq�w��
        , message                               --  16.���b�Z�[�W
        , created_by                            --  17.�쐬��
        , creation_date                         --  18.�쐬��
        , last_updated_by                       --  19.�ŏI�X�V��
        , last_update_date                      --  20.�ŏI�X�V��
        , last_update_login                     --  21.�ŏI�X�V���O�C��
        , request_id                            --  22.�v��ID
        , program_application_id                --  23.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                            --  24.�R���J�����g�E�v���O����ID
        , program_update_date                   --  25.�v���O�����X�V��
      )VALUES(
          iv_base_code                          --  01
        , SUBSTRB(iv_base_name, 1, 20)          --  02
        , NULL                                  --  03
        , NULL                                  --  04
        , NULL                                  --  05
        , NULL                                  --  06
        , TO_CHAR(gd_date_from, cv_date_type_2) --  07
        , TO_CHAR(gd_date_to, cv_date_type_2)   --  08
        , gt_conclusion_day                     --  09
        , NULL                                  --  10
        , NULL                                  --  11
        , NULL                                  --  12
        , NULL                                  --  13
        , NULL                                  --  14
        , '0'                                   --  15
        , gv_nodata_msg                         --  16
        , cn_created_by                         --  17
        , SYSDATE                               --  18
        , cn_last_updated_by                    --  19
        , SYSDATE                               --  20
        , cn_last_update_login                  --  21
        , cn_request_id                         --  22
        , cn_program_application_id             --  23
        , cn_program_id                         --  24
        , SYSDATE                               --  25
      );
    END IF;
    --
    gn_target_cnt :=  gn_target_cnt + ln_target_cnt;
    gn_normal_cnt :=  gn_normal_cnt + ln_target_cnt;
    --
  EXCEPTION
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
  END ins_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_info
   * Description      : ���_���擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_info(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_info'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    CURSOR  cur_base_info
    IS
      SELECT  hca.account_number                          --  ���_�R�[�h
            , SUBSTRB(hca.account_name, 1, 20)            --  ���_����
      FROM    hz_cust_accounts          hca
            , xxcmm_cust_accounts       xca
      WHERE   hca.cust_account_id       =   xca.customer_id
      AND     xca.management_base_code  =   gt_base_code
      AND     hca.customer_class_code   =   cv_cust_class_1
      UNION
      SELECT  hca.account_number                          --  ���_�R�[�h
            , SUBSTRB(hca.account_name, 1, 20)            --  ���_����
      FROM    hz_cust_accounts          hca
      WHERE   hca.account_number        =   gt_base_code
      AND     hca.customer_class_code   =   cv_cust_class_1;
    --
    -- <�J�[�\����>���R�[�h�^
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �J�[�\���I�[�v��
    OPEN  cur_base_info;
    FETCH cur_base_info BULK COLLECT INTO tab_base_info;
    --
    IF (tab_base_info.COUNT = 0) THEN
      -- ���o�f�[�^��0���̏ꍇ
      -- ���_���擾�G���[���b�Z�[�W
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application      =>  cv_short_name_xxcoi
                        , iv_name             =>  cv_msg_xxcoi1_10414
                          , iv_token_name1    =>  cv_token_10414
                          , iv_token_value1   =>  gt_base_code
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    CLOSE cur_base_info;
   --
  EXCEPTION
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
  END get_base_info;
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
    lv_output_msg         VARCHAR2(5000);                               --  ���b�Z�[�W�ݒ�
    lt_base_name          hz_cust_accounts.account_name%TYPE;           --  ���_����
    lt_customer_name      hz_parties.party_name%TYPE;                   --  �ڋq����
    ld_date_to            DATE;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ==================================
    --  1.�o�͊��ԕҏW
    -- ==================================
    IF (gt_conclusion_day = '30') THEN
      -- �������ߓ����w�肳��Ă���ꍇ�A�o�͊���(TO)�̌�������ݒ�
      gd_date_to  :=  LAST_DAY(gd_date_to);
    ELSE
      -- 
      BEGIN
        -- ��L�ȊO�̏ꍇ�A�o�͊���(TO)�̓��t���������ߓ��ɒu����
        ld_date_to  :=  TO_DATE( TO_CHAR(gd_date_to, cv_date_type_4) || cv_slash || gt_conclusion_day || cv_default_time, cv_date_type_3);
        gd_date_to  :=  ld_date_to;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
    --
    -- ==================================
    --  2.�N���p�����[�^���O�o��
    -- ==================================
    --  ���_���̎擾
    BEGIN
      SELECT  hca.account_name
      INTO    lt_base_name
      FROM    hz_cust_accounts      hca
      WHERE   hca.account_number        =   gt_base_code
      AND     hca.customer_class_code   =   cv_cust_class_1;
      --
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        -- ���_���擾�G���[���b�Z�[�W
        lv_errbuf   :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_00009
                          , iv_token_name1    =>  cv_token_00009
                          , iv_token_value1   =>  gt_base_code
                        );
        lv_errmsg   :=  lv_errbuf;
        RAISE global_process_expt;
    END;
    --
    -- �ڋq���̎擾
    IF (gt_customer_code IS NOT NULL) THEN
      BEGIN
        SELECT  hp.party_name
        INTO    lt_customer_name
        FROM    hz_cust_accounts      hca
              , hz_parties            hp
        WHERE   hca.account_number        =   gt_customer_code
        AND     hca.party_id              =   hp.party_id
        AND     hca.customer_class_code   =   cv_cust_class_10;
        --
      EXCEPTION
        WHEN  NO_DATA_FOUND THEN
          -- ���_���擾�G���[���b�Z�[�W
          lv_errbuf   :=  xxccp_common_pkg.get_msg(
                              iv_application    =>  cv_short_name_xxcoi
                            , iv_name           =>  cv_msg_xxcoi1_00019
                            , iv_token_name1    =>  cv_token_00019
                            , iv_token_value1   =>  gt_base_code
                          );
          lv_errmsg   :=  lv_errbuf;
          RAISE global_process_expt;
      END;
    END IF;
    --
    -- ���b�Z�[�W�ݒ�
    lv_output_msg   :=  xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_short_name_xxcoi
                          , iv_name           =>  cv_msg_xxcoi1_10415
                          , iv_token_name1    =>  cv_token_10415_1
                          , iv_token_value1   =>  gt_base_code
                          , iv_token_name2    =>  cv_token_10415_2
                          , iv_token_value2   =>  lt_base_name
                          , iv_token_name3    =>  cv_token_10415_3
                          , iv_token_value3   =>  TO_CHAR(gd_date_from, cv_date_type_2)
                          , iv_token_name4    =>  cv_token_10415_4
                          , iv_token_value4   =>  TO_CHAR(gd_date_to, cv_date_type_2)
                          , iv_token_name5    =>  cv_token_10415_5
                          , iv_token_value5   =>  gt_conclusion_day
                          , iv_token_name6    =>  cv_token_10415_6
                          , iv_token_value6   =>  gt_customer_code
                          , iv_token_name7    =>  cv_token_10415_7
                          , iv_token_value7   =>  lt_customer_name
                        );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_output_msg
    );
    -- ��s���o��
    fnd_file.put_line(
        which   =>  FND_FILE.LOG
      , buff    =>  cv_space
    );
    --
    -- ==================================
    --  3.�p�����[�^�Ó����`�F�b�N
    -- ==================================
    IF  (gd_date_from > gd_date_to) THEN
      -- �o�͊��� FROM ���� TO ���ߋ����t�̏ꍇ
      -- ���t�p�����[�^�������G���[���b�Z�[�W
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_10337
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
      --
    ELSIF (ADD_MONTHS(gd_date_from, 1) <= gd_date_to)  THEN
      -- �o�͊��� FROM ���� TO ���P�����ȏ�̏ꍇ
      -- ���t�p�����[�^�w��͈̓G���[���b�Z�[�W
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_10416
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ==================================
    --  4.�����l�ݒ�
    -- ==================================
    -- �݌ɑg�D�R�[�h�擾
    gv_f_organization_code  :=  fnd_profile.value(cv_prf_name_orgcd);
    --
    IF (gv_f_organization_code IS NULL) THEN
      -- �݌ɑg�D�R�[�h���擾����Ȃ������ꍇ
      -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00005
                        , iv_token_name1    =>  cv_token_00005
                        , iv_token_value1   =>  cv_prf_name_orgcd
                     );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- �݌ɑg�DID�擾
    gn_f_organization_id  :=  xxcoi_common_pkg.get_organization_id(gv_f_organization_code);
    --
    IF (gn_f_organization_id IS NULL) THEN
      -- �݌ɑg�DID���擾����Ȃ������ꍇ
      -- �݌ɑg�DID�擾�G���[���b�Z�[�W
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_short_name_xxcoi
                        , iv_name           =>  cv_msg_xxcoi1_00006
                        , iv_token_name1    =>  cv_token_00006
                        , iv_token_value1   =>  gv_f_organization_code
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- �Ɩ��������t�擾
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF (gd_f_process_date IS NULL) THEN
      -- �Ɩ��������t���擾�ł��Ȃ������ꍇ
      -- �Ɩ����t�̎擾�Ɏ��s���܂����B
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_short_name_xxcoi
                       ,iv_name         => cv_msg_xxcoi1_00011
                      );
      lv_errmsg   :=  lv_errbuf;
      RAISE global_process_expt;
    END IF;
    --
    -- �Ώۃf�[�^�Ȃ����b�Z�[�W
    gv_nodata_msg :=  xxccp_common_pkg.get_msg(
                          iv_application      =>  cv_short_name_xxcoi
                        , iv_name             =>  cv_msg_xxcoi1_00008
                      );
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
    iv_base_code      IN  VARCHAR2,     --  ���_�R�[�h
    iv_date_from      IN  VARCHAR2,     --  �o�͊���(FROM)
    iv_date_to        IN  VARCHAR2,     --  �o�͊���(TO)
    iv_conclusion_day IN  VARCHAR2,     --  ���ߓ�
    iv_customer_code  IN  VARCHAR2,     --  �ڋq�R�[�h
    ov_errbuf         OUT VARCHAR2,     --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    --  �O���[�o���l�ݒ�
    -- ===============================================
    gn_target_cnt       :=  0;                                        --  �Ώی���
    gn_normal_cnt       :=  0;                                        --  ���팏��
    gn_warn_cnt         :=  0;                                        --  �x������
    gn_error_cnt        :=  0;                                        --  �G���[����
    --
    gt_base_code        :=  iv_base_code;                             --  ���_�R�[�h
    gd_date_from        :=  TO_DATE(iv_date_from, cv_date_type_3);    --  �o�͊���(FROM)
    gd_date_to          :=  TO_DATE(iv_date_to, cv_date_type_3);      --  �o�͊���(TO)
    gt_conclusion_day   :=  iv_conclusion_day;                        --  ���ߓ�
    gt_customer_code    :=  iv_customer_code;                         --  �ڋq�R�[�h
    --
    -- ===============================
    --  A-1.��������
    -- ===============================
    init(
        ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --  �I������
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-2.���_���擾
    -- ===============================
    get_base_info(
        ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --  �I������
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    --
    <<base_info_loop>>
    FOR  ln_cnt  IN  1 .. tab_base_info.COUNT  LOOP
      --
      -- ===============================
      --  A-3.���o�ɏ��擾
      --  A-4.�����v�Z���擾
      --  A-5.���[�N�e�[�u���f�[�^�o�^
      -- ===============================
      ins_svf_data(
          iv_base_code  =>  tab_base_info(ln_cnt).base_code       --  ���_�R�[�h
        , iv_base_name  =>  tab_base_info(ln_cnt).base_name       --  ���_����
        , ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --  �I������
      IF  (lv_retcode <>  cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
    END LOOP base_info_loop;
    --
    -- SVF�p���[�N�e�[�u���̊m��
    COMMIT;
    --
    -- ===============================
    --  A-6.SVF�N��
    -- ===============================
    call_output_svf(
        ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --  �I������
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-7.���[�N�e�[�u���f�[�^�폜
    -- ===============================
    del_svf_data(
        ov_errbuf     =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode    =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg     =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --  �I������
    IF  (lv_retcode <>  cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
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
    errbuf            OUT VARCHAR2,       --  �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2,       --  ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code      IN  VARCHAR2,       --  ���_�R�[�h
    iv_date_from      IN  VARCHAR2,       --  �o�͊���(FROM)
    iv_date_to        IN  VARCHAR2,       --  �o�͊���(TO)
    iv_conclusion_day IN  VARCHAR2,       --  ���ߓ�
    iv_customer_code  IN  VARCHAR2        --  �ڋq�R�[�h
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
        iv_base_code        =>  iv_base_code        --  ���_�R�[�h
      , iv_date_from        =>  iv_date_from        --  �o�͊���(FROM)
      , iv_date_to          =>  iv_date_to          --  �o�͊���(TO)
      , iv_conclusion_day   =>  iv_conclusion_day   --  ���ߓ�
      , iv_customer_code    =>  iv_customer_code    --  �ڋq�R�[�h
      , ov_errbuf           =>  lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode          =>  lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg           =>  lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      gn_error_cnt  :=  1;
      gn_normal_cnt :=  0;
      --
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
END XXCOI009A05R;
/
