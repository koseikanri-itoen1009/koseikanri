CREATE OR REPLACE PACKAGE BODY XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(body)
 * Description      : �C�Z�g�[�������f�[�^�쐬
 * MD.050           : MD050_CFR_003_A17_�C�Z�g�[�������f�[�^�쐬
 * MD.070           : MD050_CFR_003_A17_�C�Z�g�[�������f�[�^�쐬
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  insert_work_table      p ���[�N�e�[�u���f�[�^�o�^                (A-3)
 *  chk_account_data       p �������擾�`�F�b�N                    (A-4)
 *  chk_line_cnt_limit     p ���������׌����`�F�b�N                  (A-5)
 *  csv_file_output        p �t�@�C���o�͏���                        (A-6)
 *  put_account_warning    p �ڋq�R�t���x���o��                      (A-7)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-23    1.00 SCS ���� �K��     �V�K�쐬
 *  2009-09-29    1.10 SCS ���� �q��     ���ʉۑ�uIE535�v�Ή�
 *
 *****************************************************************************************/
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFR003A17C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn      CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr      CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- ���b�Z�[�W�ԍ�
--
  cv_msg_xxcfr_00010  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00010';            -- ���ʊ֐��G���[���b�Z�[�W
  cv_msg_xxcfr_00004  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00004';            -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_xxcfr_00024  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00024';            -- �擾�f�[�^�Ȃ����b�Z�[�W
  cv_msg_xxcfr_00016  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00016';            -- �e�[�u���}���G���[
  cv_msg_xxcfr_00038  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00038';            -- �U���������o�^���b�Z�[�W
  cv_msg_xxcfr_00051  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00051';            -- �U���������o�^���
  cv_msg_xxcfr_00052  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00052';            -- �U���������o�^�������b�Z�[�W
  cv_msg_xxcfr_00071  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00071';            -- ���������׌����������b�Z�[�W
  cv_msg_xxcfr_00072  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00072';            -- ���������׌����������
  cv_msg_xxcfr_00056  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00056';            -- �V�X�e���G���[���b�Z�[�W
-- Modify 2009-09-29 Ver1.10 Start  
  cv_msg_xxcfr_00079  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00079';            -- �������p�ڋq���݂Ȃ����b�Z�[�W
  cv_msg_xxcfr_00080  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00080';            -- ���|�Ǘ���ڋq���݂Ȃ����b�Z�[�W
  cv_msg_xxcfr_00081  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00081';            -- �ڋq�R�[�h�����w�胁�b�Z�[�W
  cv_msg_xxcfr_00082  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00082';            -- �����������p�ڋq���݂Ȃ����b�Z�[�W
-- Modify 2009-09-29 Ver1.10 End
--
-- �g�[�N��
  cv_tkn_func         CONSTANT VARCHAR2(15)  := 'FUNC_NAME';                   -- ���ʊ֐���
  cv_tkn_prof         CONSTANT VARCHAR2(15)  := 'PROF_NAME';                   -- �v���t�@�C����
  cv_tkn_table        CONSTANT VARCHAR2(15)  := 'TABLE';                       -- �e�[�u����
  cv_tkn_ac_code      CONSTANT VARCHAR2(30)  := 'ACCOUNT_CODE';                -- �ڋq�R�[�h
  cv_tkn_ac_name      CONSTANT VARCHAR2(30)  := 'ACCOUNT_NAME';                -- �ڋq��
  cv_tkn_lc_name      CONSTANT VARCHAR2(30)  := 'KYOTEN_NAME';                 -- ���_��
  cv_tkn_rec_limit    CONSTANT VARCHAR2(30)  := 'LINE_LIMIT';                  -- �������R�[�h��
  cv_tkn_count        CONSTANT VARCHAR2(30)  := 'COUNT';                       -- �J�E���g��
--
  -- ���{�ꎫ��
  cv_dict_date_func   CONSTANT VARCHAR2(100) := 'CFR000A00003';                -- ���t�p�����[�^�ϊ��֐�
  cv_dict_ymd4        CONSTANT VARCHAR2(100) := 'CFR000A00007';                -- YYYY"�N"MM"��"DD"��"
  cv_dict_ymd2        CONSTANT VARCHAR2(100) := 'CFR000A00008';                -- YY"�N"MM"��"DD"��"
  cv_dict_year        CONSTANT VARCHAR2(100) := 'CFR000A00009';                -- �N
  cv_dict_month       CONSTANT VARCHAR2(100) := 'CFR000A00010';                -- ��
  cv_dict_bank        CONSTANT VARCHAR2(100) := 'CFR000A00011';                -- ��s
  cv_dict_central     CONSTANT VARCHAR2(100) := 'CFR000A00015';                -- �{�X
  cv_dict_branch      CONSTANT VARCHAR2(100) := 'CFR000A00012';                -- �x�X
  cv_dict_account     CONSTANT VARCHAR2(100) := 'CFR000A00013';                -- ����
  cv_dict_current     CONSTANT VARCHAR2(100) := 'CFR000A00014';                -- ����
  cv_dict_zip_mark    CONSTANT VARCHAR2(100) := 'CFR000A00016';                -- ��
  cv_dict_bank_damy   CONSTANT VARCHAR2(100) := 'CFR000A00017';                -- ��s�_�~�[�R�[�h
  cv_dict_csv_out     CONSTANT VARCHAR2(100) := 'CFR000A00018';                -- OUT�t�@�C���o�͏���
--
  --�v���t�@�C��
  cv_line_cnt_limit   CONSTANT VARCHAR2(30)  := 'XXCFR1_LINE_CNT_LIMIT';       -- �������א�
-- Modify 2009-09-29 Ver1.10 Start
  cv_line_cnt_limit2  CONSTANT VARCHAR2(30)  := 'XXCFR1_LINE_CNT_LIMIT2';      -- �������א�
-- Modify 2009-09-29 Ver1.10 End
  cv_set_of_bks_id    CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';            -- ��v����ID
  cv_org_id           CONSTANT VARCHAR2(30)  := 'ORG_ID';                      -- �g�DID
--
  cv_tax_div_excluded CONSTANT VARCHAR2(1)   := '1';                           -- ����ŋ敪�F�O��
  cv_tax_div_nontax   CONSTANT VARCHAR2(1)   := '4';                           -- ����ŋ敪�F��ې�
  cv_out_div_included CONSTANT VARCHAR2(1)   := '1';                           -- �������o�͋敪�F�ō�
  cv_out_div_excluded CONSTANT VARCHAR2(1)   := '2';                           -- �������o�͋敪�F�Ŕ�
  cv_inv_prt_type     CONSTANT VARCHAR2(1)   := '4';                           -- �������o�͌`���F�Ǝ҈ϑ�
--
  cv_table            CONSTANT VARCHAR2(100) := 'XXCFR_CSV_OUTS_TEMP';         -- ���[�N�e�[�u����
  cv_lookup_type_out  CONSTANT VARCHAR2(100) := 'XXCFR1_003A17_BILL_DATA_SET'; -- �C�Z�g�[�������f�[�^�쐬�p�Q�ƃ^�C�v��
--
  cv_file_type_log    CONSTANT VARCHAR2(10)  := 'LOG';                         -- ���O�o��
--
  cv_flag_yes         CONSTANT VARCHAR2(1)   := 'Y';                           -- �L���t���O�i�x�j
--
  cv_status_yes       CONSTANT VARCHAR2(1)   := '1';                           -- �L���X�e�[�^�X�i1�F�L���j
  cv_status_no        CONSTANT VARCHAR2(1)   := '0';                           -- �L���X�e�[�^�X�i0�F�����j
--
  cv_format_date_ymd      CONSTANT VARCHAR2(8)   := 'YY/MM/DD';                    -- ���t�t�H�[�}�b�g�i2���N�����X���b�V���t�j
  cv_format_date_yyyymmdd CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                    -- ���t�t�H�[�}�b�g�iYYYYMMDD�j
--
  cv_max_date_value   CONSTANT VARCHAR2(10)  := '9999/12/31';                  -- �ő���t�l
--
-- Modify 2009-09-29 Ver1.10 Start
  -- �ڋq�敪
  cv_customer_class_code14 CONSTANT VARCHAR2(2) := '14';      -- �ڋq�敪14(���|�Ǘ���)
  cv_customer_class_code21 CONSTANT VARCHAR2(2) := '21';      -- �ڋq�敪21(�����������p)
  cv_customer_class_code20 CONSTANT VARCHAR2(2) := '20';      -- �ڋq�敪20(�������p)
  cv_customer_class_code10 CONSTANT VARCHAR2(2) := '10';      -- �ڋq�敪10(�ڋq)
--
  -- ����������P��
  cv_invoice_printing_unit_a1 CONSTANT VARCHAR2(2) := '9';    -- ����������P��:'A1'
  cv_invoice_printing_unit_a2 CONSTANT VARCHAR2(2) := '8';    -- ����������P��:'A2'
  cv_invoice_printing_unit_a3 CONSTANT VARCHAR2(2) := '6';    -- ����������P��:'A3'
  cv_invoice_printing_unit_a4 CONSTANT VARCHAR2(2) := '7';    -- ����������P��:'A4'
  cv_invoice_printing_unit_a5 CONSTANT VARCHAR2(2) := '5';    -- ����������P��:'A5'
  cv_invoice_printing_unit_a6 CONSTANT VARCHAR2(2) := '4';    -- ����������P��:'A6'
  cv_invoice_printing_unit_n1 CONSTANT VARCHAR2(2) := '2';    -- ����������P��:'N1'
  cv_invoice_printing_unit_n2 CONSTANT VARCHAR2(2) := '3';    -- ����������P��:'N2'
  cv_invoice_printing_unit_n3 CONSTANT VARCHAR2(2) := '1';    -- ����������P��:'N3'
  cv_invoice_printing_unit_n4 CONSTANT VARCHAR2(2) := '0';    -- ����������P��:'N4'
--
  -- �g�p�ړI
  cv_site_use_code_bill_to CONSTANT VARCHAR(10) := 'BILL_TO';  -- �g�p�ړI�F�u������v
--
  -- �ڋq�֘A�����ΏۃX�e�[�^�X
  cv_acct_relate_status    CONSTANT VARCHAR2(1) := 'A';
--
  -- �ڋq�֘A
  cv_acct_relate_type_bill CONSTANT VARCHAR2(1) := '1';     -- �����֘A
--
  -- AFF����l�Z�b�g��
  cv_ffv_set_name_dept CONSTANT VARCHAR2(100) := 'XX03_DEPARTMENT';
--
  -- �w�b�_/���׋敪
  cv_header_kbn   VARCHAR2(1) := '1'; -- �w�b�_
  cv_line_kbn     VARCHAR2(1) := '2'; -- ����
--
  -- ���R�[�h�敪
  cv_record_kbn0  VARCHAR2(1) := '0'; -- �w�b�_���R�[�h
  cv_record_kbn1  VARCHAR2(1) := '1'; -- ���׃��R�[�h
  cv_record_kbn2  VARCHAR2(1) := '2'; -- �X�܌v���R�[�h
--
  -- ���C�A�E�g�敪
  cv_layout_kbn1  VARCHAR2(1) := '1'; -- �X�ܕʓ���Ȃ�
  cv_layout_kbn2  VARCHAR2(1) := '2'; -- �X�ܕʓ��󂠂�
-- Modify 2009-09-29 Ver1.10 End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gd_target_date        DATE;                                      -- �p�����[�^�D�����i�f�[�^�^�ϊ��p�j
  gn_line_cnt_limit     NUMBER;                                    -- ���������׌�������(�X�ܕʓ���Ȃ�)
-- Modify 2009-09-29 Ver1.10 Start
  gn_line_cnt_limit2    NUMBER;                                    -- ���������׌�������(�X�ܕʓ��󂠂�)
-- Modify 2009-09-29 Ver1.10 End
  gn_org_id             NUMBER;                                    -- �g�DID
  gn_set_of_bks_id      NUMBER;                                    -- ��v����ID
--
  -- �ő���t
  gd_max_date           DATE DEFAULT TO_DATE(cv_max_date_value, cv_format_date_ymd);
--
-- Modify 2009-09-29 Ver1.10 Start
  -- �ڋq�R�t���x�����݃t���O
  gv_warning_flag       VARCHAR2(1) := cv_status_no;
-- Modify 2009-09-29 Ver1.10 End
--
  -- ���{�ꎫ���p�ϐ�
  gv_format_date_jpymd4  VARCHAR2(25); -- �������`�p�FYYYY"�N"MM"��"DD"��"
  gv_format_date_jpymd2  VARCHAR2(25); -- �������`�p�FYY"�N"MM"��"DD"��"
  gv_format_zip_mark     VARCHAR2(10); -- ��
  gv_format_date_year    VARCHAR2(10); -- �N
  gv_format_date_month   VARCHAR2(10); -- ��
  gv_format_bank         VARCHAR2(10); -- ��s
  gv_format_central      VARCHAR2(10); -- �{�X
  gv_format_branch       VARCHAR2(10); -- �x�X
  gv_format_account      VARCHAR2(10); -- ����
  gv_format_current      VARCHAR2(10); -- ����
  gv_format_bank_dummy   VARCHAR2(10); -- D%
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code14     IN      VARCHAR2,         -- ���|�Ǘ���ڋq
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    param_expt EXCEPTION;  -- �ڋq�R�[�h�����w���O
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
    --�R���J�����g�p�����[�^�o��
    --==============================================================
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log   -- ���O�o��
                                   ,iv_conc_param1  => iv_target_date     -- �R���J�����g�p�����[�^�P
                                   ,iv_conc_param2  => iv_customer_code10 -- �R���J�����g�p�����[�^�Q
                                   ,iv_conc_param3  => iv_customer_code20 -- �R���J�����g�p�����[�^�R
                                   ,iv_conc_param4  => iv_customer_code21 -- �R���J�����g�p�����[�^�S
                                   ,iv_conc_param5  => iv_customer_code14 -- �R���J�����g�p�����[�^�T
                                   ,ov_errbuf       => ov_errbuf          -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode         -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W 
--
    -- �p�����[�^�D������DATE�^�ɕϊ�����
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfr 
                                                   ,cv_msg_xxcfr_00010 -- ���ʊ֐��G���[
                                                   ,cv_tkn_func        -- �g�[�N��'�@�\��'
                                                   ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                      ,cv_dict_date_func))
                                                   -- ���t�ϊ����ʊ֐��G���[
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009-09-29 Ver1.10 Start
    -- �p�����[�^�ڋq�R�[�h�̎w�萔�`�F�b�N �ڋq�R�[�h�͂P�̂ݎw�肵�Ă��邱�Ƃ��`�F�b�N
    IF (iv_customer_code14 IS NOT NULL) THEN
      IF (iv_customer_code21 IS NOT NULL)
      OR (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code21 IS NOT NULL) THEN
      IF (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code20 IS NOT NULL)
    AND   (iv_customer_code10 IS NOT NULL)
    THEN
      RAISE param_expt;
    END IF;
-- Modify 2009-09-29 Ver1.10 End
--
  EXCEPTION
    WHEN param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr
                                            ,iv_name         => cv_msg_xxcfr_00081);
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
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C�����琧�����א����擾
    gn_line_cnt_limit := TO_NUMBER(FND_PROFILE.VALUE(cv_line_cnt_limit));
--
    IF (gn_line_cnt_limit IS NULL) THEN
      -- �擾�G���[��
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��:�v���t�@�C����
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_line_cnt_limit))
                                                     -- �������א�
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009-09-29 Ver1.10 Start
    -- �v���t�@�C�����琧�����א����擾
    gn_line_cnt_limit2 := TO_NUMBER(FND_PROFILE.VALUE(cv_line_cnt_limit2));
--
    IF (gn_line_cnt_limit2 IS NULL) THEN
      -- �擾�G���[��
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��:�v���t�@�C����
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_line_cnt_limit2))
                                                     -- �������א�
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Modify 2009-09-29 Ver1.10 End
--
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
--
    IF (gn_set_of_bks_id IS NULL) THEN
      -- �擾�G���[��
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��:�v���t�@�C����
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- ��v����ID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
--
    IF (gn_org_id IS NULL) THEN
      -- �擾�G���[��
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof        -- �g�[�N��:�v���t�@�C����
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- �g�DID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END get_profile_value;
--
-- Modify 2009-09-29 Ver1.10 Start
  /**********************************************************************************
   * Procedure Name   : put_account_warning(A-7)
   * Description      : �ڋq�R�t���x���o�� (A-7)
   ***********************************************************************************/
  PROCEDURE put_account_warning(
    iv_customer_class_code  IN   VARCHAR2,            -- �ڋq�敪
    iv_customer_code        IN   VARCHAR2,            -- �ڋq�R�[�h
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_account_warning'; -- �v���O������
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
    lv_data_msg  VARCHAR2(5000);        -- ���O�o�̓��b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
    -- ���|�Ǘ���ڋq���݂Ȃ����b�Z�[�W�o��
    IF (iv_customer_class_code = cv_customer_class_code14) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_xxcfr_00080
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- �����������p�ڋq���݂Ȃ����b�Z�[�W�o��
    ELSIF (iv_customer_class_code = cv_customer_class_code21) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_xxcfr_00082
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- �������p�ڋq���݂Ȃ����b�Z�[�W�o��
    ELSIF (iv_customer_class_code = cv_customer_class_code20) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_xxcfr_00079
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    END IF;
--
    -- �ڋq�R�t���x�����݃t���O�𑶍݂���ɕύX����
    gv_warning_flag := cv_status_yes;
--
--###########################  �Œ蕔 END   ############################
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
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
  END put_account_warning;
-- Modify 2009-09-29 Ver1.10 End
--
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-3)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- ����
    iv_customer_code10      IN   VARCHAR2,            -- �ڋq
    iv_customer_code20      IN   VARCHAR2,            -- �������p�ڋq
    iv_customer_code21      IN   VARCHAR2,            -- �����������p�ڋq
    iv_customer_code14      IN   VARCHAR2,            -- ���|�Ǘ���ڋq
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- �v���O������
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
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
--
    lv_no_data_msg  VARCHAR2(5000); -- ���[�O�����b�Z�[�W
    lv_func_status  VARCHAR2(1);    -- SVF���[���ʊ֐�(0���o�̓��b�Z�[�W)�I���X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
-- Modify 2009-09-29 Ver1.10 Start
    -- �ڋq�擾�J�[�\���^�C�v
    TYPE cursor_rec_type IS RECORD(customer_id           xxcmm_cust_accounts.customer_id%TYPE,           -- �ڋq�敪10�ڋqID
                                   customer_code         xxcmm_cust_accounts.customer_code%TYPE,         -- �ڋq�敪10�ڋq�R�[�h
                                   invoice_printing_unit xxcmm_cust_accounts.invoice_printing_unit%TYPE, -- �ڋq�敪10����������P��
                                   bill_base_code        xxcmm_cust_accounts.bill_base_code%TYPE);       -- �ڋq�敪10�������_�R�[�h
    TYPE cursor_ref_type IS REF CURSOR;
    get_all_account_cur cursor_ref_type;
    all_account_rec cursor_rec_type;
--
    -- �ڋq10�擾�J�[�\��������
    cv_get_all_account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||            -- �ڋqID
    '       xxca.customer_code         AS customer_code, '||          -- �ڋq�R�[�h
    '        xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
    '        xxca.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    ' FROM xxcmm_cust_accounts xxca, '||                                     -- �ڋq�ǉ����
    '      hz_cust_accounts    hzca '||                                      -- �ڋq�}�X�^
    ' WHERE hzca.customer_class_code = '''||cv_customer_class_code10||''' '||         -- �ڋq�敪:10
    ' AND   xxca.customer_id = hzca.cust_account_id ';
--
    -- �ڋq10�擾�J�[�\��������(���|�Ǘ���ڋq�w�莞)
    cv_get_14account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     hz_cust_accounts    hzca10, '||                                     -- �ڋq10�ڋq�}�X�^
    '     hz_cust_acct_sites  hasa10, '||                                     -- �ڋq10�ڋq���ݒn
    '     hz_cust_site_uses   hsua10, '||                                     -- �ڋq10�ڋq�g�p�ړI
    '     hz_cust_accounts    hzca14, '||                                     -- �ڋq14�ڋq�}�X�^
    '     hz_cust_acct_relate hcar14, '||                                     -- �ڋq�֘A�}�X�^
    '     hz_cust_acct_sites  hasa14, '||                                     -- �ڋq14�ڋq���ݒn
    '     hz_cust_site_uses   hsua14 '||                                      -- �ڋq14�ڋq�g�p�ړI
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a1||''','||
                                           ''''||cv_invoice_printing_unit_a2||''','||
                                           ''''||cv_invoice_printing_unit_a3||''','||
                                           ''''||cv_invoice_printing_unit_a4||''','||
                                           ''''||cv_invoice_printing_unit_a5||''','||
                                           ''''||cv_invoice_printing_unit_a6||''','||
                                           ''''||cv_invoice_printing_unit_n1||''','||
                                           ''''||cv_invoice_printing_unit_n2||''','||
                                           ''''||cv_invoice_printing_unit_n3||''') '|| -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.account_number = :iv_customer_code14 '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id ';
--
    -- �ڋq10�擾�J�[�\��������(�����������p�ڋq�w�莞)
    cv_get_21account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca20, '||                                     -- �ڋq20�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca21, '||                                     -- �ڋq21�ڋq�ǉ����
    '     hz_cust_accounts    hzca10 '||                                      -- �ڋq10�ڋq�}�X�^
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a2||''','||
                                           ''''||cv_invoice_printing_unit_a4||''') '|| -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||          -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.enclose_invoice_code = xxca21.customer_code '||
    'AND   xxca21.customer_code = :iv_customer_code21 ';
--
    -- �ڋq10�擾�J�[�\��������(�������p�ڋq�w�莞)
    cv_get_20account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca10.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
    '       xxca10.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- �ڋq10�ڋq�ǉ����
    '     xxcmm_cust_accounts xxca20, '||                                     -- �ڋq20�ڋq�ǉ����
    '     hz_cust_accounts    hzca10 '||                                      -- �ڋq10�ڋq�}�X�^
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a3||''','||
                                           ''''||cv_invoice_printing_unit_a6||''','||
                                           ''''||cv_invoice_printing_unit_n3||''') '||   -- ����������P��
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- �ڋq�敪:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.customer_code = :iv_customer_code20 ';
--
    -- �ڋq10�擾�J�[�\��������(�ڋq�w�莞)
    cv_get_10account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||           -- �ڋqID
    '       xxca.customer_code         AS customer_code, '||         -- �ڋq�R�[�h
    '       xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- ����������P��
    '       xxca.bill_base_code        AS bill_base_code '||         -- �������_�R�[�h
    'FROM xxcmm_cust_accounts xxca, '||                                     -- �ڋq�ǉ����
    '     hz_cust_accounts    hzca '||                                      -- �ڋq�}�X�^
    'WHERE xxca.invoice_printing_unit = '''||cv_invoice_printing_unit_n4||''' '||       -- ����������P��
    'AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||            -- �ڋq�敪:10
    'AND   xxca.customer_id = hzca.cust_account_id '||
    'AND   xxca.customer_code = :iv_customer_code10 ';
--
    -- �ڋq14�擾�J�[�\��
    CURSOR get_14account_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT bill_hzca_1.cust_account_id         AS cash_account_id,         --�ڋq14ID
            bill_hzca_1.account_number          AS cash_account_number,     --�ڋq14�R�[�h
            bill_hzpa_1.party_name              AS cash_account_name,       --�ڋq14�ڋq��
            ship_hzca_1.cust_account_id         AS ship_account_id,         --�ڋq10�ڋqID        
            ship_hzca_1.account_number          AS ship_account_number,     --�ڋq10�ڋq�R�[�h 
            bill_hzad_1.bill_base_code          AS bill_base_code,          --�ڋq14�������_�R�[�h
            bill_hzlo_1.postal_code             AS bill_postal_code,        --�ڋq14�X�֔ԍ�            
            bill_hzlo_1.state                   AS bill_state,              --�ڋq14�s���{��            
            bill_hzlo_1.city                    AS bill_city,               --�ڋq14�s�E��              
            bill_hzlo_1.address1                AS bill_address1,           --�ڋq14�Z��1               
            bill_hzlo_1.address2                AS bill_address2,           --�ڋq14�Z��2
            bill_hzlo_1.address_lines_phonetic  AS phone_num,               --�ڋq14�d�b�ԍ�
            bill_hzad_1.tax_div                 AS bill_tax_div,            --�ڋq14����ŋ敪
            bill_hsua_1.attribute7              AS bill_invoice_type,       --�ڋq14�������o�͌`��      
            bill_hsua_1.payment_term_id         AS bill_payment_term_id,    --�ڋq14�x������
            bill_hzcp_1.cons_inv_flag           AS cons_inv_flag            --�ڋq14�ꊇ���������s�t���O
     FROM hz_cust_accounts          bill_hzca_1,              --�ڋq14�ڋq�}�X�^
          hz_cust_accounts          ship_hzca_1,              --�ڋq10�ڋq�}�X�^
          xxcmm_cust_accounts       bill_hzad_1,              --�ڋq14�ڋq�ǉ����
          hz_cust_acct_sites        bill_hasa_1,              --�ڋq14�ڋq���ݒn
          hz_locations              bill_hzlo_1,              --�ڋq14�ڋq���Ə�
          hz_cust_site_uses         bill_hsua_1,              --�ڋq14�ڋq�g�p�ړI
          hz_customer_profiles      bill_hzcp_1,              --�ڋq14�v���t�@�C��
          hz_cust_acct_relate       bill_hcar_1,              --�ڋq�֘A�}�X�^(�����֘A)
          hz_cust_acct_sites        ship_hasa_1,              --�ڋq10�ڋq���ݒn
          hz_cust_site_uses         ship_hsua_1,              --�ڋq10�ڋq�g�p�ړI
          hz_party_sites            bill_hzps_1,              --�ڋq14�p�[�e�B�T�C�g
          hz_parties                bill_hzpa_1               --�ڋq14�p�[�e�B
     WHERE ship_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
     AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --�ڋq�֘A�}�X�^.�֘A��ڋqID = �ڋq10�ڋq�}�X�^.�ڋqID
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code14        --�ڋq14�ڋq�}�X�^.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
     AND   bill_hcar_1.status = cv_acct_relate_status                        --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
     AND   bill_hcar_1.attribute1 = cv_acct_relate_type_bill                 --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq14�ڋq�ǉ����.�ڋqID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --�ڋq14�ڋq�}�X�^.�ڋqID = �ڋq14�ڋq���ݒn.�ڋqID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --�ڋq14�ڋq���ݒn.�ڋq���ݒnID = �ڋq14�ڋq�g�p�ړI.�ڋq���ݒnID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --�ڋq14�ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
     AND   bill_hzcp_1.cust_account_id = bill_hzca_1.cust_account_id         --�ڋq14�v���t�@�C��.�ڋqID = �ڋq14�ڋq�}�X�^.�ڋqID
     AND   bill_hzcp_1.site_use_id = bill_hsua_1.site_use_id                 --�ڋq14�v���t�@�C��.�g�p�ړIID = �ڋq14�ڋq�g�p�ړI.�g�p�ړIID
     AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --�ڋq10�ڋq�}�X�^.�ڋqID = �ڋq10�ڋq���ݒn.�ڋqID
     AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --�ڋq10�ڋq���ݒn.�ڋq���ݒnID = �ڋq10�ڋq�g�p�ړI.�ڋq���ݒnID
     AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --�ڋq10�ڋq�g�p�ړI.�����掖�Ə�ID = �ڋq14�ڋq�g�p�ړI.�g�p�ړIID
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --�ڋq14�ڋq���ݒn.�p�[�e�B�T�C�gID = �ڋq14�p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --�ڋq14�p�[�e�B�T�C�g.���Ə�ID = �ڋq14�ڋq���Ə�.���Ə�ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id;                      --�ڋq14�ڋq�}�X�^.�p�[�e�BID = �ڋq14.�p�[�e�BID
--
    get_14account_rec get_14account_cur%ROWTYPE;
--
    -- �ڋq21�擾�J�[�\��
    CURSOR get_21account_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT xxca21.customer_id                  AS bill_account_id,         --�ڋq21ID
            xxca21.customer_code                AS bill_account_number,     --�ڋq21�R�[�h
            hzpa21.party_name                   AS bill_account_name,       --�ڋq21�ڋq��
            xxca21.bill_base_code               AS bill_base_code21,        --�ڋq21�������_�R�[�h
            hzlo21.postal_code                  AS bill_postal_code,        --�ڋq21�X�֔ԍ�
            hzlo21.state                        AS bill_state,              --�ڋq21�s���{��
            hzlo21.city                         AS bill_city,               --�ڋq21�s�E��
            hzlo21.address1                     AS bill_address1,           --�ڋq21�Z��1
            hzlo21.address2                     AS bill_address2,           --�ڋq21�Z��2
            hzlo21.address_lines_phonetic       AS phone_num,               --�ڋq21�d�b�ԍ�
            xxca20.bill_base_code               AS bill_base_code20         --�ڋq20�������_�R�[�h
     FROM xxcmm_cust_accounts       xxca21,                   --�ڋq21�ڋq�ǉ����
          xxcmm_cust_accounts       xxca20,                   --�ڋq20�ڋq�ǉ����
          xxcmm_cust_accounts       xxca10,                   --�ڋq10�ڋq�ǉ����
          hz_cust_accounts          hzca20,                   --�ڋq20�ڋq�}�X�^
          hz_cust_accounts          hzca21,                   --�ڋq21�ڋq�}�X�^
          hz_parties                hzpa21,                   --�ڋq21�p�[�e�B
          hz_cust_acct_sites        hcas21,                   --�ڋq21�ڋq���ݒn
          hz_party_sites            hzps21,                   --�ڋq21�p�[�e�B�T�C�g
          hz_locations              hzlo21                    --�ڋq21�ڋq���Ə�
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --�ڋq10�ڋq�ǉ����.�������p�R�[�h = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   xxca20.enclose_invoice_code = xxca21.customer_code                --�ڋq20�ڋq�ǉ����.�����������p�R�[�h = �ڋq21�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca20.customer_class_code = cv_customer_class_code20             --�ڋq20�ڋq�}�X�^.�ڋq�敪 = '20'(�������p)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --�ڋq20�ڋq�}�X�^.�ڋqID = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca21.customer_class_code = cv_customer_class_code21             --�ڋq21�ڋq�}�X�^.�ڋq�敪 = '21'(�����������p)
     AND   hzca21.cust_account_id = xxca21.customer_id                       --�ڋq21�ڋq�}�X�^.�ڋqID = �ڋq21�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca21.party_id = hzpa21.party_id                                 --�ڋq21�ڋq�}�X�^.�p�[�e�BID = �ڋq21�p�[�e�B.�p�[�e�BID
     AND   hzca21.cust_account_id = hcas21.cust_account_id                   --�ڋq21�ڋq�}�X�^.�ڋqID = �ڋq21���ݒn.�ڋqID
     AND   hcas21.party_site_id = hzps21.party_site_id                       --�ڋq���ݒn21.�p�[�e�B�T�C�g = �ڋq21�p�[�e�B�T�C�g.�ڋq21�p�[�e�B�T�C�gID
     AND   hzps21.location_id = hzlo21.location_id;                          --�ڋq21�p�[�e�B�T�C�g.���Ə�ID = �ڋq21�ڋq���Ə�.���Ə�ID
--
    get_21account_rec get_21account_cur%ROWTYPE;
--
    -- �ڋq20�擾�J�[�\��
    CURSOR get_20account_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT xxca20.customer_id                  AS bill_account_id,         --�ڋq20ID
            xxca20.customer_code                AS bill_account_number,     --�ڋq20�R�[�h
            hzpa20.party_name                   AS bill_account_name,       --�ڋq20�ڋq��
            xxca20.bill_base_code               AS bill_base_code,          --�ڋq20�������_�R�[�h
            hzlo20.postal_code                  AS bill_postal_code,        --�ڋq20�X�֔ԍ�
            hzlo20.state                        AS bill_state,              --�ڋq20�s���{��
            hzlo20.city                         AS bill_city,               --�ڋq20�s�E��
            hzlo20.address1                     AS bill_address1,           --�ڋq20�Z��1
            hzlo20.address2                     AS bill_address2,           --�ڋq20�Z��2
            hzlo20.address_lines_phonetic       AS phone_num                --�ڋq20�d�b�ԍ�
     FROM xxcmm_cust_accounts       xxca20,                   --�ڋq20�ڋq�ǉ����
          xxcmm_cust_accounts       xxca10,                   --�ڋq10�ڋq�ǉ����
          hz_cust_accounts          hzca20,                   --�ڋq20�ڋq�}�X�^
          hz_parties                hzpa20,                   --�ڋq20�p�[�e�B
          hz_cust_acct_sites        hcas20,                   --�ڋq20�ڋq���ݒn
          hz_party_sites            hzps20,                   --�ڋq20�p�[�e�B�T�C�g
          hz_locations              hzlo20                    --�ڋq20�ڋq���Ə�
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --�ڋq10�ڋq�ǉ����.�������p�R�[�h = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca20.customer_class_code = cv_customer_class_code20             --�ڋq20�ڋq�}�X�^.�ڋq�敪 = '20'(�������p)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --�ڋq20�ڋq�}�X�^.�ڋqID = �ڋq20�ڋq�ǉ����.�ڋq�R�[�h
     AND   hzca20.party_id = hzpa20.party_id                                 --�ڋq20�ڋq�}�X�^.�p�[�e�BID = �ڋq20�p�[�e�B.�p�[�e�BID
     AND   hzca20.cust_account_id = hcas20.cust_account_id                   --�ڋq20�ڋq�}�X�^.�ڋqID = �ڋq20���ݒn.�ڋqID
     AND   hcas20.party_site_id = hzps20.party_site_id                       --�ڋq���ݒn20.�p�[�e�B�T�C�g = �ڋq20�p�[�e�B�T�C�g.�ڋq20�p�[�e�B�T�C�gID
     AND   hzps20.location_id = hzlo20.location_id;                          --�ڋq20�p�[�e�B�T�C�g.���Ə�ID = �ڋq20�ڋq���Ə�.���Ə�ID
--
    get_20account_rec get_20account_cur%ROWTYPE;
--
    -- �P�ƓX�������o�͌`���擾�J�[�\��
    CURSOR get_10inv_type_cur(
      iv_customer_id IN NUMBER) -- �ڋq�敪10�̌ڋqID
    IS
     SELECT hsua.attribute7    AS invoice_type, -- �������o�͌`��
            hcpa.cons_inv_flag AS cons_inv_flag -- �ꊇ���������s�t���O
     FROM hz_cust_acct_sites      hasa,      -- �ڋq10�ڋq���ݒn
          hz_cust_site_uses       hsua,      -- �ڋq10�g�p�ړI
          hz_customer_profiles    hcpa       -- �ڋq10�v���t�@�C��
     WHERE hasa.cust_account_id = iv_customer_id
       AND hsua.cust_acct_site_id = hasa.cust_acct_site_id  -- �ڋq10�g�p�ړI.�ڋq���ݒnID = �ڋq10�ڋq���ݒn.�ڋq���ݒnID
       AND hsua.site_use_code = cv_site_use_code_bill_to    -- �ڋq10�ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
       AND hsua.attribute7 = cv_inv_prt_type                -- �ڋq10�ڋq�g�p�ړI.�������o�͌`�� = '4'(�Ǝ҈ϑ�)
       AND hcpa.cons_inv_flag = cv_flag_yes                 -- �ڋq10�ꊇ���������s�t���O = 'Y'
       AND hcpa.cust_account_id = iv_customer_id
       AND hcpa.site_use_id = hsua.site_use_id;             -- �ڋq10�v���t�@�C��.�g�p�ړIID = �ڋq10�g�p�ړI.�g�p�ړIID
--
    get_10inv_type_rec get_10inv_type_cur%ROWTYPE;
--
-- Modify 2009-09-29 Ver1.10 End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- ���{�ꕶ����擾
    -- ====================================================
    gv_format_date_jpymd4  := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_ymd4)      -- YYYY"�N"MM"��"DD"��"
                                     ,1
                                     ,5000);
    --
    gv_format_date_jpymd2  := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_ymd2)      -- YY"�N"MM"��"DD"��"
                                     ,1
                                     ,5000);
    --
    gv_format_zip_mark     := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_zip_mark)  -- ��
                                     ,1
                                     ,5000);
    --
    gv_format_date_year    := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_year)      -- �N
                                     ,1
                                     ,5000);
    --
    gv_format_date_month   := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_month)     -- ��
                                     ,1
                                     ,5000);
    --
    gv_format_bank         := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_bank)      -- ��s
                                     ,1
                                     ,5000);
    --
    gv_format_central      := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_central)   -- �{�X
                                     ,1
                                     ,5000);
    --
    gv_format_branch       := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_branch)    -- �x�X
                                     ,1
                                     ,5000);
    --
    gv_format_account      := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_account)   -- ����
                                     ,1
                                     ,5000);
    --
    gv_format_current      := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_current)   -- ����
                                     ,1
                                     ,5000);
    --
    gv_format_bank_dummy   := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_bank_damy) -- D
                                     ,1
                                     ,5000);
--
    -- ====================================================
    -- ���[�N�e�[�u���ւ̓o�^
    -- ====================================================
    BEGIN
--
-- Modify 2009-09-29 Ver1.10 Start
      -- ���|�Ǘ���ڋq�w�莞
      IF (iv_customer_code14 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_14account_cur USING iv_customer_code14;
      -- �����������p�ڋq�w�莞
      ELSIF (iv_customer_code21 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_21account_cur USING iv_customer_code21;
      -- �������p�ڋq�w�莞
      ELSIF (iv_customer_code20 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_customer_code20;
      -- �ڋq�w�莞
      ELSIF (iv_customer_code10 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_customer_code10;
      -- �p�����[�^�w��Ȃ���
      ELSE
        OPEN get_all_account_cur FOR cv_get_all_account_cur;
      END IF;
--
      <<get_account10_loop>>
      LOOP
        FETCH get_all_account_cur INTO all_account_rec;
        EXIT WHEN get_all_account_cur%NOTFOUND;
--
        -- ����������P�ʂ�'N4'(�P�ƓX)�ȊO�̏ꍇ�A
        -- �ڋq�敪10�̌ڋq�ɕR�Â��A�ڋq�敪14�̌ڋq���擾
        IF (all_account_rec.invoice_printing_unit <> cv_invoice_printing_unit_n4) THEN
          OPEN get_14account_cur(all_account_rec.customer_id);
          FETCH get_14account_cur INTO get_14account_rec;
--
          -- �R�Â��ڋq�敪14�̌ڋq�����݂��Ȃ��ꍇ
          IF (get_14account_cur%NOTFOUND) THEN
            -- �ڋq�敪14���݂Ȃ����b�Z�[�W�o��
            put_account_warning(iv_customer_class_code => cv_customer_class_code14
                               ,iv_customer_code       => all_account_rec.customer_code
                               ,ov_errbuf              => lv_errbuf
                               ,ov_retcode             => lv_retcode
                               ,ov_errmsg              => lv_errmsg);
            IF (lv_retcode = cv_status_error) THEN
              --(�G���[����)
              RAISE global_process_expt;
            END IF;
          -- ����������P�� IN ('A1','A5') ���|�Ǘ���ڋq�ł܂Ƃ߂�
          ELSIF (all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a1,cv_invoice_printing_unit_a5))
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 4.�Ǝ҈ϑ�
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- �ꊇ���������s�t���O = 'Y'
          THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- �v��ID
             ,seq              -- �o�͏�
             ,col1             -- �w�b�_/���׋敪
             ,col2             -- ���R�[�h�敪
             ,col3             -- ���s���t
             ,col4             -- �X�֔ԍ�
             ,col5             -- �Z���P
             ,col6             -- �Z���Q
             ,col7             -- �Z���R
             ,col8             -- �ڋq�R�[�h
             ,col9             -- �ڋq��
             ,col10            -- �S�����_��
             ,col11            -- �d�b�ԍ�
             ,col12            -- �Ώ۔N��
             ,col13            -- ���|�Ǘ��R�[�h�A��������
             ,col14            -- �������o�͋敪
             ,col15            -- �����������グ�z
             ,col16            -- ����œ�
             ,col17            -- ���������z
             ,col18            -- �����\���
             ,col19            -- �U�����s��
             ,col20            -- �U�����s�x�X��
             ,col21            -- �U����������
             ,col22            -- �U��������ԍ�
             ,col23            -- �U����������`�l�J�i��
             ,col24            -- �X�܃R�[�h
             ,col25            -- �X�ܖ�
             ,col26            -- �`�[���t
             ,col27            -- �`�[No
             ,col28            -- �`�[���z
             ,col29            -- ���C�A�E�g�敪
             ,col101           -- �`�[�Ŕ��z(��o�͍���)
             ,col102           -- �`�[�Ŋz(��o�͍���)
             ,col103           -- ������ڋq�R�[�h(��o�͍���)
             ,col104)          -- ������ڋq��(��o�͍���)
            SELECT cn_request_id                                              request_id         -- �v��ID
                  ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                  ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                  ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                  ,NULL                                                       zip_code           -- �X�֔ԍ�
                  ,NULL                                                       send_address1      -- �Z���P
                  ,NULL                                                       send_address2      -- �Z���Q
                  ,NULL                                                       send_address3      -- �Z���R
                  ,get_14account_rec.cash_account_number                      bill_cust_code     -- �ڋq�R�[�h
                  ,NULL                                                       bill_cust_name     -- �ڋq��
                  ,NULL                                                       location_name      -- ���_��
                  ,NULL                                                       phone_num          -- �d�b�ԍ�
                  ,xih.object_month                                           object_month       -- �Ώ۔N��
                  ,get_14account_rec.cash_account_number||' '||xih.term_name  ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                  ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                        ,cv_tax_div_nontax,cv_out_div_excluded
                                                                          ,cv_out_div_included)
                                                                              out_put_div        -- �������o�͋敪
                  ,NULL                                                       inv_amount         -- �����������グ�z
                  ,NULL                                                       tax_amount         -- ����œ�
                  ,NULL                                                       total_amount       -- ���������z
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                             ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                   END                                                        banc_number        -- ��s��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,CASE WHEN INSTR(bank.bank_branch_name
                                           ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                   END                                                        bank_branch_number -- �x�X��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                   END                                                        bank_account_type  -- �������
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,bank.bank_account_num)
                   END                                                        bank_account_num   -- �����ԍ�
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,bank.account_holder_name_alt)
                   END                                                        bank_account_name  -- �������`�l�J�i��
                  ,xil.ship_cust_code                                         ship_cust_code     -- �X�܃R�[�h
                  ,hzp.party_name                                             ship_cust_name     -- �X�ܖ�
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                 ,xil.delivery_date
                                 ,xil.acceptance_date)
                                 ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                  ,xil.slip_num                                                     slip_num     -- �`�[�ԍ�
                  ,SUM(CASE
                       WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                              ,cv_tax_div_excluded)
                       THEN
                            xil.ship_amount
                       ELSE
                            xil.tax_amount + xil.ship_amount
                       END)                                                         slip_sum          -- �`�[���z
                  ,cv_layout_kbn2                                                   layout_kbn        -- ���C�A�E�g�敪
                  ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- �`�[�Ŕ��z
                  ,SUM(xil.tax_amount)                                              slip_tax          -- �`�[�Ŋz
                  ,get_14account_rec.cash_account_number                            payment_cust_code -- ������ڋq�R�[�h
                  ,get_14account_rec.cash_account_name                              payment_cust_name -- ������ڋq��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                 hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                 (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                        ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                        ,ap_bank_accounts_all           abaa                 --��s����
                        ,ap_bank_branches               abb                  --��s�x�X
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  get_14account_rec.cash_account_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
            GROUP BY xih.inv_creation_date,                                               -- ���s���t
                     xih.object_month,                                                    -- �Ώ۔N��
                     xih.term_name,                                                       -- �x������
                     xih.payment_date,                                                    -- �����\���
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END,                                                                 -- ��s��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END,                                                                 -- �x�X��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END,                                                                 -- �������
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END,                                                                 -- �����ԍ�
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- �������`�l�J�i��
                     xil.ship_cust_code,                                                  -- �X�܃R�[�h
                     hzp.party_name,                                                      -- �X�ܖ�
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- �`�[���t
                     xil.slip_num;                                                        -- �`�[�ԍ�
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          -- ����������P�� IN ('A2','A4') �����������p�ڋq�ł܂Ƃ߂�
          ELSIF (all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a2,cv_invoice_printing_unit_a4))
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 4.�Ǝ҈ϑ�
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- �ꊇ���������s�t���O = 'Y'
          THEN
            OPEN get_21account_cur(all_account_rec.customer_id);
            FETCH get_21account_cur INTO get_21account_rec;
--
            --�ڋq�敪21�̌ڋq�����݂��Ȃ��ꍇ
            IF get_21account_cur%NOTFOUND THEN
              -- �ڋq�敪21���݂Ȃ����b�Z�[�W�o��
              put_account_warning(iv_customer_class_code => cv_customer_class_code21
                                 ,iv_customer_code       => all_account_rec.customer_code
                                 ,ov_errbuf              => lv_errbuf
                                 ,ov_retcode             => lv_retcode
                                 ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                RAISE global_process_expt;
              END IF;
            ELSE
              INSERT INTO xxcfr_csv_outs_temp(
                request_id       -- �v��ID
               ,seq              -- �o�͏�
               ,col1             -- �w�b�_/���׋敪
               ,col2             -- ���R�[�h�敪
               ,col3             -- ���s���t
               ,col4             -- �X�֔ԍ�
               ,col5             -- �Z���P
               ,col6             -- �Z���Q
               ,col7             -- �Z���R
               ,col8             -- �ڋq�R�[�h
               ,col9             -- �ڋq��
               ,col10            -- �S�����_��
               ,col11            -- �d�b�ԍ�
               ,col12            -- �Ώ۔N��
               ,col13            -- ���|�Ǘ��R�[�h�A��������
               ,col14            -- �������o�͋敪
               ,col15            -- �����������グ�z
               ,col16            -- ����œ�
               ,col17            -- ���������z
               ,col18            -- �����\���
               ,col19            -- �U�����s��
               ,col20            -- �U�����s�x�X��
               ,col21            -- �U����������
               ,col22            -- �U��������ԍ�
               ,col23            -- �U����������`�l�J�i��
               ,col24            -- �X�܃R�[�h
               ,col25            -- �X�ܖ�
               ,col26            -- �`�[���t
               ,col27            -- �`�[No
               ,col28            -- �`�[���z
               ,col29            -- ���C�A�E�g�敪
               ,col101           -- �`�[�Ŕ��z(��o�͍���)
               ,col102           -- �`�[�Ŋz(��o�͍���)
               ,col103           -- ������ڋq�R�[�h(��o�͍���)
               ,col104)          -- ������ڋq��(��o�͍���)
              SELECT cn_request_id                                              request_id         -- �v��ID
                    ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                    ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                    ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                    ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                    ,NULL                                                       zip_code           -- �X�֔ԍ�
                    ,NULL                                                       send_address1      -- �Z���P
                    ,NULL                                                       send_address2      -- �Z���Q
                    ,NULL                                                       send_address3      -- �Z���R
                    ,get_21account_rec.bill_account_number                      bill_cust_code     -- �ڋq�R�[�h
                    ,NULL                                                       bill_cust_name     -- �ڋq��
                    ,NULL                                                       location_name      -- ���_��
                    ,NULL                                                       phone_num          -- �d�b�ԍ�
                    ,xih.object_month                                           object_month       -- �Ώ۔N��
                    ,get_21account_rec.bill_account_number||' '||xih.term_name  ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                    ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                          ,cv_tax_div_nontax,cv_out_div_excluded
                                                                            ,cv_out_div_included)
                                                                                out_put_div        -- �������o�͋敪
                    ,NULL                                                       inv_amount         -- �����������グ�z
                    ,NULL                                                       tax_amount         -- ����œ�
                    ,NULL                                                       total_amount       -- ���������z
                    ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END                                                        banc_number        -- ��s��
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END                                                        bank_branch_number -- �x�X��
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END                                                        bank_account_type  -- �������
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END                                                        bank_account_num   -- �����ԍ�
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END                                                        bank_account_name  -- �������`�l�J�i��
                    ,xxca.invoice_code                                          ship_cust_code     -- �X�܃R�[�h
                    ,hzp.party_name                                             ship_cust_name     -- �X�ܖ�
                    ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                    ,xil.slip_num                                                     slip_num     -- �`�[�ԍ�
                    ,SUM(CASE
                         WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                                ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                                         slip_sum          -- �`�[���z
                    ,cv_layout_kbn2                                                   layout_kbn        -- ���C�A�E�g�敪
                    ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- �`�[�Ŕ��z
                    ,SUM(xil.tax_amount)                                              slip_tax          -- �`�[�Ŋz
                    ,get_14account_rec.cash_account_number                            payment_cust_code -- ������ڋq�R�[�h
                    ,get_14account_rec.cash_account_name                              payment_cust_name -- ������ڋq��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   hz_cust_accounts               hzca , -- �ڋq20�ڋq�}�X�^
                   hz_parties                     hzp  , -- �ڋq20�p�[�e�B�}�X�^
                   xxcmm_cust_accounts            xxca , -- �ڋq10�ǉ����
                   (SELECT all_account_rec.customer_code ship_cust_code
                          ,rcrm.customer_id             customer_id
                          ,abb.bank_number              bank_number
                          ,abb.bank_name                bank_name
                          ,abb.bank_branch_name         bank_branch_name
                          ,abaa.bank_account_type       bank_account_type
                          ,abaa.bank_account_num        bank_account_num
                          ,abaa.account_holder_name     account_holder_name
                          ,abaa.account_holder_name_alt account_holder_name_alt
                    FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                          ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                          ,ap_bank_accounts_all           abaa                 --��s����
                          ,ap_bank_branches               abb                  --��s�x�X
                    WHERE  rcrm.primary_flag      = cv_flag_yes
                      AND  get_14account_rec.cash_account_id = rcrm.customer_id
                      AND  gd_target_date   BETWEEN rcrm.start_date
                                                AND NVL(rcrm.end_date, gd_max_date)
                      AND  rcrm.site_use_id      IS NOT NULL
                      AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND  arma.bank_account_id   = abaa.bank_account_id(+)
                      AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                      AND  arma.org_id            = gn_org_id
                      AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
              WHERE xih.invoice_id = xil.invoice_id
                AND xil.cutoff_date = gd_target_date
                AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND xxca.customer_id = all_account_rec.customer_id
                AND hzca.account_number = xxca.invoice_code
                AND hzp.party_id = hzca.party_id
              GROUP BY xih.inv_creation_date,                                               -- ���s���t
                       xih.object_month,                                                    -- �Ώ۔N��
                       xih.term_name,                                                       -- �x������
                       xih.payment_date,                                                    -- �����\���
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name 
                                END)
                       END,                                                                 -- ��s��
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END)
                       END,                                                                 -- �x�X��
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type))
                       END,                                                                 -- �������
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,bank.bank_account_num)
                       END,                                                                 -- �����ԍ�
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,bank.account_holder_name_alt)
                       END,                                                                 -- �������`�l�J�i��
                       xxca.invoice_code,                                                   -- �X�܃R�[�h
                       hzp.party_name,                                                      -- �X�ܖ�
                       TO_CHAR(DECODE(xil.acceptance_date,NULL
                                     ,xil.delivery_date
                                     ,xil.acceptance_date)
                                     ,cv_format_date_yyyymmdd),                             -- �`�[���t
                       xil.slip_num;                                                        -- �`�[�ԍ�
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            END IF;
--
            CLOSE get_21account_cur;
--
          -- ����������P�� IN ('A3','A6') �������p�ڋq�ł܂Ƃ߂�
          ELSIF (all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a3,cv_invoice_printing_unit_a6))
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 4.�Ǝ҈ϑ�
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- �ꊇ���������s�t���O
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --�ڋq�敪20�̌ڋq�����݂��Ȃ��ꍇ
            IF get_20account_cur%NOTFOUND THEN
              -- �ڋq�敪20���݂Ȃ����b�Z�[�W�o��
              put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                  ,iv_customer_code       => all_account_rec.customer_code
                                  ,ov_errbuf              => lv_errbuf
                                  ,ov_retcode             => lv_retcode
                                  ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                RAISE global_process_expt;
              END IF;
            ELSE
              INSERT INTO xxcfr_csv_outs_temp(
                request_id       -- �v��ID
               ,seq              -- �o�͏�
               ,col1             -- �w�b�_/���׋敪
               ,col2             -- ���R�[�h�敪
               ,col3             -- ���s���t
               ,col4             -- �X�֔ԍ�
               ,col5             -- �Z���P
               ,col6             -- �Z���Q
               ,col7             -- �Z���R
               ,col8             -- �ڋq�R�[�h
               ,col9             -- �ڋq��
               ,col10            -- �S�����_��
               ,col11            -- �d�b�ԍ�
               ,col12            -- �Ώ۔N��
               ,col13            -- ���|�Ǘ��R�[�h�A��������
               ,col14            -- �������o�͋敪
               ,col15            -- �����������グ�z
               ,col16            -- ����œ�
               ,col17            -- ���������z
               ,col18            -- �����\���
               ,col19            -- �U�����s��
               ,col20            -- �U�����s�x�X��
               ,col21            -- �U����������
               ,col22            -- �U��������ԍ�
               ,col23            -- �U����������`�l�J�i��
               ,col24            -- �X�܃R�[�h
               ,col25            -- �X�ܖ�
               ,col26            -- �`�[���t
               ,col27            -- �`�[No
               ,col28            -- �`�[���z
               ,col29            -- ���C�A�E�g�敪
               ,col101           -- �`�[�Ŕ��z(��o�͍���)
               ,col102           -- �`�[�Ŋz(��o�͍���)
               ,col103           -- ������ڋq�R�[�h(��o�͍���)
               ,col104)          -- ������ڋq��(��o�͍���)
              SELECT cn_request_id                                              request_id         -- �v��ID
                    ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                    ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                    ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                    ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                    ,NULL                                                       zip_code           -- �X�֔ԍ�
                    ,NULL                                                       send_address1      -- �Z���P
                    ,NULL                                                       send_address2      -- �Z���Q
                    ,NULL                                                       send_address3      -- �Z���R
                    ,get_20account_rec.bill_account_number                      bill_cust_code     -- �ڋq�R�[�h
                    ,NULL                                                       bill_cust_name     -- �ڋq��
                    ,NULL                                                       location_name      -- ���_��
                    ,NULL                                                       phone_num          -- �d�b�ԍ�
                    ,xih.object_month                                           object_month       -- �Ώ۔N��
                    ,get_20account_rec.bill_account_number||' '||xih.term_name  ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                    ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                          ,cv_tax_div_nontax,cv_out_div_excluded
                                                                            ,cv_out_div_included)
                                                                                out_put_div        -- �������o�͋敪
                    ,NULL                                                       inv_amount         -- �����������グ�z
                    ,NULL                                                       tax_amount         -- ����œ�
                    ,NULL                                                       total_amount       -- ���������z
                    ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END                                                        banc_number        -- ��s��
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END                                                        bank_branch_number -- �x�X��
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END                                                        bank_account_type  -- �������
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END                                                        bank_account_num   -- �����ԍ�
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END                                                        bank_account_name  -- �������`�l�J�i��
                    ,xil.ship_cust_code                                         ship_cust_code     -- �X�܃R�[�h
                    ,hzp.party_name                                             ship_cust_name     -- �X�ܖ�
                    ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                    ,xil.slip_num                                                     slip_num     -- �`�[�ԍ�
                    ,SUM(CASE
                         WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                                ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                                         slip_sum          -- �`�[���z
                    ,cv_layout_kbn2                                                   layout_kbn        -- ���C�A�E�g�敪
                    ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- �`�[�Ŕ��z
                    ,SUM(xil.tax_amount)                                              slip_tax          -- �`�[�Ŋz
                    ,get_14account_rec.cash_account_number                            payment_cust_code -- ������ڋq�R�[�h
                    ,get_14account_rec.cash_account_name                              payment_cust_name -- ������ڋq��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   hz_cust_accounts               hzca , -- �ڋq10�ڋq�}�X�^
                   hz_parties                     hzp  , -- �ڋq10�p�[�e�B�}�X�^
                   (SELECT all_account_rec.customer_code ship_cust_code
                          ,rcrm.customer_id             customer_id
                          ,abb.bank_number              bank_number
                          ,abb.bank_name                bank_name
                          ,abb.bank_branch_name         bank_branch_name
                          ,abaa.bank_account_type       bank_account_type
                          ,abaa.bank_account_num        bank_account_num
                          ,abaa.account_holder_name     account_holder_name
                          ,abaa.account_holder_name_alt account_holder_name_alt
                    FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                          ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                          ,ap_bank_accounts_all           abaa                 --��s����
                          ,ap_bank_branches               abb                  --��s�x�X
                    WHERE  rcrm.primary_flag      = cv_flag_yes
                      AND  get_14account_rec.cash_account_id = rcrm.customer_id
                      AND  gd_target_date   BETWEEN rcrm.start_date
                                                AND NVL(rcrm.end_date, gd_max_date)
                      AND  rcrm.site_use_id      IS NOT NULL
                      AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND  arma.bank_account_id   = abaa.bank_account_id(+)
                      AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                      AND  arma.org_id            = gn_org_id
                      AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
              WHERE xih.invoice_id = xil.invoice_id
                AND xil.cutoff_date = gd_target_date
                AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND hzca.cust_account_id = all_account_rec.customer_id
                AND hzp.party_id = hzca.party_id
              GROUP BY xih.inv_creation_date,                                               -- ���s���t
                       xih.object_month,                                                    -- �Ώ۔N��
                       xih.term_name,                                                       -- �x������
                       xih.payment_date,                                                    -- �����\���
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name 
                                END)
                       END,                                                                 -- ��s��
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END)
                       END,                                                                 -- �x�X��
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type))
                       END,                                                                 -- �������
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,bank.bank_account_num)
                       END,                                                                 -- �����ԍ�
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,bank.account_holder_name_alt)
                       END,                                                                 -- �������`�l�J�i��
                       xil.ship_cust_code,                                                  -- �X�܃R�[�h
                       hzp.party_name,                                                      -- �X�ܖ�
                       TO_CHAR(DECODE(xil.acceptance_date,NULL
                                     ,xil.delivery_date
                                     ,xil.acceptance_date)
                                     ,cv_format_date_yyyymmdd),                             -- �`�[���t
                       xil.slip_num;                                                        -- �`�[�ԍ�
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            END IF;
--
            CLOSE get_20account_cur;
--
          -- ����������P�� = 'N1' �ڋq�敪10�P�ʂő��t
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n1)
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 4.�Ǝ҈ϑ�
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- �ꊇ���������s�t���O = 'Y'
          THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- �v��ID
             ,seq              -- �o�͏�
             ,col1             -- �w�b�_/���׋敪
             ,col2             -- ���R�[�h�敪
             ,col3             -- ���s���t
             ,col4             -- �X�֔ԍ�
             ,col5             -- �Z���P
             ,col6             -- �Z���Q
             ,col7             -- �Z���R
             ,col8             -- �ڋq�R�[�h
             ,col9             -- �ڋq��
             ,col10            -- �S�����_��
             ,col11            -- �d�b�ԍ�
             ,col12            -- �Ώ۔N��
             ,col13            -- ���|�Ǘ��R�[�h�A��������
             ,col14            -- �������o�͋敪
             ,col15            -- �����������グ�z
             ,col16            -- ����œ�
             ,col17            -- ���������z
             ,col18            -- �����\���
             ,col19            -- �U�����s��
             ,col20            -- �U�����s�x�X��
             ,col21            -- �U����������
             ,col22            -- �U��������ԍ�
             ,col23            -- �U����������`�l�J�i��
             ,col24            -- �X�܃R�[�h
             ,col25            -- �X�ܖ�
             ,col26            -- �`�[���t
             ,col27            -- �`�[No
             ,col28            -- �`�[���z
             ,col29            -- ���C�A�E�g�敪
             ,col101           -- �`�[�Ŕ��z(��o�͍���)
             ,col102           -- �`�[�Ŋz(��o�͍���)
             ,col103           -- ������ڋq�R�[�h(��o�͍���)
             ,col104)          -- ������ڋq��(��o�͍���)
            SELECT cn_request_id                                              request_id         -- �v��ID
                  ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                  ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                  ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                  ,NULL                                                       zip_code           -- �X�֔ԍ�
                  ,NULL                                                       send_address1      -- �Z���P
                  ,NULL                                                       send_address2      -- �Z���Q
                  ,NULL                                                       send_address3      -- �Z���R
                  ,xil.ship_cust_code                                         bill_cust_code     -- �ڋq�R�[�h
                  ,NULL                                                       bill_cust_name     -- �ڋq��
                  ,NULL                                                       location_name      -- ���_��
                  ,NULL                                                       phone_num          -- �d�b�ԍ�
                  ,xih.object_month                                           object_month       -- �Ώ۔N��
                  ,xil.ship_cust_code||' '||xih.term_name                     ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                  ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                        ,cv_tax_div_nontax,cv_out_div_excluded
                                                                          ,cv_out_div_included)
                                                                              out_put_div        -- �������o�͋敪
                  ,NULL                                                       inv_amount         -- �����������グ�z
                  ,NULL                                                       tax_amount         -- ����œ�
                  ,NULL                                                       total_amount       -- ���������z
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                             ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                   END                                                        banc_number        -- ��s��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,CASE WHEN INSTR(bank.bank_branch_name
                                           ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                   END                                                        bank_branch_number -- �x�X��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                   END                                                        bank_account_type  -- �������
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,bank.bank_account_num)
                   END                                                        bank_account_num   -- �����ԍ�
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,bank.account_holder_name_alt)
                   END                                                        bank_account_name  -- �������`�l�J�i��
                  ,NULL                                                       ship_cust_code     -- �X�܃R�[�h
                  ,NULL                                                       ship_cust_name     -- �X�ܖ�
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                 ,xil.delivery_date
                                 ,xil.acceptance_date)
                                 ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                  ,xil.slip_num                                                     slip_num     -- �`�[�ԍ�
                  ,SUM(CASE
                       WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                              ,cv_tax_div_excluded)
                       THEN
                            xil.ship_amount
                       ELSE
                            xil.tax_amount + xil.ship_amount
                       END)                                                         slip_sum     -- �`�[���z
                  ,cv_layout_kbn1                                                   layout_kbn   -- ���C�A�E�g�敪
                  ,SUM(xil.ship_amount)                                             slip_sum_ex_tax  -- �`�[�Ŕ��z
                  ,SUM(xil.tax_amount)                                              slip_tax         -- �`�[�Ŋz
                  ,get_14account_rec.cash_account_number                            payment_cust_code -- ������ڋq�R�[�h
                  ,get_14account_rec.cash_account_name                              payment_cust_name -- ������ڋq��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                        ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                        ,ap_bank_accounts_all           abaa                 --��s����
                        ,ap_bank_branches               abb                  --��s�x�X
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  get_14account_rec.cash_account_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
            GROUP BY xih.inv_creation_date,                                               -- ���s���t
                     xil.ship_cust_code,                                                  -- �ڋq�R�[�h
                     xih.object_month,                                                    -- �Ώ۔N��
                     xih.term_name,                                                       -- �x������
                     xih.payment_date,                                                    -- �����\���
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END,                                                                 -- ��s��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END,                                                                 -- �x�X��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END,                                                                 -- �������
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END,                                                                 -- �����ԍ�
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- �������`�l�J�i��
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- �`�[���t
                     xil.slip_num;                                                        -- �`�[�ԍ�
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          -- ����������P�� = 'N2' ���|�Ǘ���ڋq�ɑ��t
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n2)
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 4.�Ǝ҈ϑ�
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- �ꊇ���������s�t���O = 'Y'
          THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- �v��ID
             ,seq              -- �o�͏�
             ,col1             -- �w�b�_/���׋敪
             ,col2             -- ���R�[�h�敪
             ,col3             -- ���s���t
             ,col4             -- �X�֔ԍ�
             ,col5             -- �Z���P
             ,col6             -- �Z���Q
             ,col7             -- �Z���R
             ,col8             -- �ڋq�R�[�h
             ,col9             -- �ڋq��
             ,col10            -- �S�����_��
             ,col11            -- �d�b�ԍ�
             ,col12            -- �Ώ۔N��
             ,col13            -- ���|�Ǘ��R�[�h�A��������
             ,col14            -- �������o�͋敪
             ,col15            -- �����������グ�z
             ,col16            -- ����œ�
             ,col17            -- ���������z
             ,col18            -- �����\���
             ,col19            -- �U�����s��
             ,col20            -- �U�����s�x�X��
             ,col21            -- �U����������
             ,col22            -- �U��������ԍ�
             ,col23            -- �U����������`�l�J�i��
             ,col24            -- �X�܃R�[�h
             ,col25            -- �X�ܖ�
             ,col26            -- �`�[���t
             ,col27            -- �`�[No
             ,col28            -- �`�[���z
             ,col29            -- ���C�A�E�g�敪
             ,col101           -- �`�[�Ŕ��z(��o�͍���)
             ,col102           -- �`�[�Ŋz(��o�͍���)
             ,col103           -- ������ڋq�R�[�h(��o�͍���)
             ,col104)          -- ������ڋq��(��o�͍���)
            SELECT cn_request_id                                              request_id         -- �v��ID
                  ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                  ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                  ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                  ,NULL                                                       zip_code           -- �X�֔ԍ�
                  ,NULL                                                       send_address1      -- �Z���P
                  ,NULL                                                       send_address2      -- �Z���Q
                  ,NULL                                                       send_address3      -- �Z���R
                  ,get_14account_rec.cash_account_number                      bill_cust_code     -- �ڋq�R�[�h
                  ,NULL                                                       bill_cust_name     -- �ڋq��
                  ,NULL                                                       location_name      -- ���_��
                  ,NULL                                                       phone_num          -- �d�b�ԍ�
                  ,xih.object_month                                           object_month       -- �Ώ۔N��
                  ,get_14account_rec.cash_account_number||' '||xih.term_name  ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                  ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                        ,cv_tax_div_nontax,cv_out_div_excluded
                                                                          ,cv_out_div_included)
                                                                              out_put_div        -- �������o�͋敪
                  ,NULL                                                       inv_amount         -- �����������グ�z
                  ,NULL                                                       tax_amount         -- ����œ�
                  ,NULL                                                       total_amount       -- ���������z
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                             ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                   END                                                        banc_number        -- ��s��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,CASE WHEN INSTR(bank.bank_branch_name
                                           ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                   END                                                        bank_branch_number -- �x�X��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                   END                                                        bank_account_type  -- �������
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,bank.bank_account_num)
                   END                                                        bank_account_num   -- �����ԍ�
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                           ,bank.account_holder_name_alt)
                   END                                                        bank_account_name  -- �������`�l�J�i��
                  ,NULL                                                       ship_cust_code     -- �X�܃R�[�h
                  ,NULL                                                       ship_cust_name     -- �X�ܖ�
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                 ,xil.delivery_date
                                 ,xil.acceptance_date)
                                 ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                  ,xil.slip_num                                                     slip_num     -- �`�[�ԍ�
                  ,SUM(CASE
                       WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                              ,cv_tax_div_excluded)
                       THEN
                            xil.ship_amount
                       ELSE
                            xil.tax_amount + xil.ship_amount
                       END)                                                         slip_sum          -- �`�[���z
                  ,cv_layout_kbn1                                                   layout_kbn        -- ���C�A�E�g�敪
                  ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- �`�[�Ŕ��z
                  ,SUM(xil.tax_amount)                                              slip_tax          -- �`�[�Ŋz
                  ,get_14account_rec.cash_account_number                            payment_cust_code -- ������ڋq�R�[�h
                  ,get_14account_rec.cash_account_name                              payment_cust_name -- ������ڋq��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                 xxcfr_invoice_lines            xil  , -- ��������
                 (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                        ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                        ,ap_bank_accounts_all           abaa                 --��s����
                        ,ap_bank_branches               abb                  --��s�x�X
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  get_14account_rec.cash_account_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
            GROUP BY xih.inv_creation_date,                                               -- ���s���t
                     xih.object_month,                                                    -- �Ώ۔N��
                     xih.term_name,                                                       -- �x������
                     xih.payment_date,                                                    -- �����\���
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END,                                                                 -- ��s��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END,                                                                 -- �x�X��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END,                                                                 -- �������
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END,                                                                 -- �����ԍ�
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- �������`�l�J�i��
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- �`�[���t
                     xil.slip_num;                                                        -- �`�[�ԍ�
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          -- ����������P�� = 'N3' �������p�ڋq�ɑ��t
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n3)
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- �������o�͌`�� = 4.�Ǝ҈ϑ�
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- �ꊇ���������s�t���O
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --�ڋq�敪20�̌ڋq�����݂��Ȃ��ꍇ
            IF get_20account_cur%NOTFOUND THEN
              -- �ڋq�敪20���݂Ȃ����b�Z�[�W�o��
              put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                  ,iv_customer_code       => all_account_rec.customer_code
                                  ,ov_errbuf              => lv_errbuf
                                  ,ov_retcode             => lv_retcode
                                  ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(�G���[����)
                RAISE global_process_expt;
              END IF;
            ELSE
              INSERT INTO xxcfr_csv_outs_temp(
                request_id       -- �v��ID
               ,seq              -- �o�͏�
               ,col1             -- �w�b�_/���׋敪
               ,col2             -- ���R�[�h�敪
               ,col3             -- ���s���t
               ,col4             -- �X�֔ԍ�
               ,col5             -- �Z���P
               ,col6             -- �Z���Q
               ,col7             -- �Z���R
               ,col8             -- �ڋq�R�[�h
               ,col9             -- �ڋq��
               ,col10            -- �S�����_��
               ,col11            -- �d�b�ԍ�
               ,col12            -- �Ώ۔N��
               ,col13            -- ���|�Ǘ��R�[�h�A��������
               ,col14            -- �������o�͋敪
               ,col15            -- �����������グ�z
               ,col16            -- ����œ�
               ,col17            -- ���������z
               ,col18            -- �����\���
               ,col19            -- �U�����s��
               ,col20            -- �U�����s�x�X��
               ,col21            -- �U����������
               ,col22            -- �U��������ԍ�
               ,col23            -- �U����������`�l�J�i��
               ,col24            -- �X�܃R�[�h
               ,col25            -- �X�ܖ�
               ,col26            -- �`�[���t
               ,col27            -- �`�[No
               ,col28            -- �`�[���z
               ,col29            -- ���C�A�E�g�敪
               ,col101           -- �`�[�Ŕ��z(��o�͍���)
               ,col102           -- �`�[�Ŋz(��o�͍���)
               ,col103           -- ������ڋq�R�[�h(��o�͍���)
               ,col104)          -- ������ڋq��(��o�͍���)
              SELECT cn_request_id                                              request_id         -- �v��ID
                    ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                    ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                    ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                    ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                    ,NULL                                                       zip_code           -- �X�֔ԍ�
                    ,NULL                                                       send_address1      -- �Z���P
                    ,NULL                                                       send_address2      -- �Z���Q
                    ,NULL                                                       send_address3      -- �Z���R
                    ,get_20account_rec.bill_account_number                      bill_cust_code     -- �ڋq�R�[�h
                    ,NULL                                                       bill_cust_name     -- �ڋq��
                    ,NULL                                                       location_name      -- ���_��
                    ,NULL                                                       phone_num          -- �d�b�ԍ�
                    ,xih.object_month                                           object_month       -- �Ώ۔N��
                    ,get_20account_rec.bill_account_number||' '||xih.term_name  ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                    ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                          ,cv_tax_div_nontax,cv_out_div_excluded
                                                                            ,cv_out_div_included)
                                                                                out_put_div        -- �������o�͋敪
                    ,NULL                                                       inv_amount         -- �����������グ�z
                    ,NULL                                                       tax_amount         -- ����œ�
                    ,NULL                                                       total_amount       -- ���������z
                    ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END                                                        banc_number        -- ��s��
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END                                                        bank_branch_number -- �x�X��
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END                                                        bank_account_type  -- �������
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END                                                        bank_account_num   -- �����ԍ�
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END                                                        bank_account_name  -- �������`�l�J�i��
                    ,NULL                                                       ship_cust_code     -- �X�܃R�[�h
                    ,NULL                                                       ship_cust_name     -- �X�ܖ�
                    ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                    ,xil.slip_num                                                     slip_num     -- �`�[�ԍ�
                    ,SUM(CASE
                         WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                                ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                                         slip_sum          -- �`�[���z
                    ,cv_layout_kbn1                                                   layout_kbn        -- ���C�A�E�g�敪
                    ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- �`�[�Ŕ��z
                    ,SUM(xil.tax_amount)                                              slip_tax          -- �`�[�Ŋz
                    ,get_14account_rec.cash_account_number                            payment_cust_code -- ������ڋq�R�[�h
                    ,get_14account_rec.cash_account_name                              payment_cust_name -- ������ڋq��
              FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                   xxcfr_invoice_lines            xil  , -- ��������
                   (SELECT all_account_rec.customer_code ship_cust_code
                          ,rcrm.customer_id             customer_id
                          ,abb.bank_number              bank_number
                          ,abb.bank_name                bank_name
                          ,abb.bank_branch_name         bank_branch_name
                          ,abaa.bank_account_type       bank_account_type
                          ,abaa.bank_account_num        bank_account_num
                          ,abaa.account_holder_name     account_holder_name
                          ,abaa.account_holder_name_alt account_holder_name_alt
                    FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                          ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                          ,ap_bank_accounts_all           abaa                 --��s����
                          ,ap_bank_branches               abb                  --��s�x�X
                    WHERE  rcrm.primary_flag      = cv_flag_yes
                      AND  get_14account_rec.cash_account_id = rcrm.customer_id
                      AND  gd_target_date   BETWEEN rcrm.start_date
                                                AND NVL(rcrm.end_date, gd_max_date)
                      AND  rcrm.site_use_id      IS NOT NULL
                      AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND  arma.bank_account_id   = abaa.bank_account_id(+)
                      AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                      AND  arma.org_id            = gn_org_id
                      AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
              WHERE xih.invoice_id = xil.invoice_id
                AND xil.cutoff_date = gd_target_date
                AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND xil.ship_cust_code = all_account_rec.customer_code
              GROUP BY xih.inv_creation_date,                                               -- ���s���t
                       xih.object_month,                                                    -- �Ώ۔N��
                       xih.term_name,                                                       -- �x������
                       xih.payment_date,                                                    -- �����\���
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name 
                                END)
                       END,                                                                 -- ��s��
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END)
                       END,                                                                 -- �x�X��
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type))
                       END,                                                                 -- �������
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,bank.bank_account_num)
                       END,                                                                 -- �����ԍ�
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                               ,bank.account_holder_name_alt)
                       END,                                                                 -- �������`�l�J�i��
                       TO_CHAR(DECODE(xil.acceptance_date,NULL
                                     ,xil.delivery_date
                                     ,xil.acceptance_date)
                                     ,cv_format_date_yyyymmdd),                             -- �`�[���t
                       xil.slip_num;                                                        -- �`�[�ԍ�
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            END IF;
--
            CLOSE get_20account_cur;
--
          END IF;
--
          CLOSE get_14account_cur;
--
        -- ����������P�ʂ�'N4'(�P�ƓX)�̏ꍇ�A
        ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n4) THEN
          -- �������o�͌`���擾
          OPEN get_10inv_type_cur(all_account_rec.customer_id);
          FETCH get_10inv_type_cur INTO get_10inv_type_rec;
          -- �������o�͌`����'4'���A�ꊇ���������s�t���O = 'Y'�̏ꍇ
          IF  (get_10inv_type_cur%FOUND) THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- �v��ID
             ,seq              -- �o�͏�
             ,col1             -- �w�b�_/���׋敪
             ,col2             -- ���R�[�h�敪
             ,col3             -- ���s���t
             ,col4             -- �X�֔ԍ�
             ,col5             -- �Z���P
             ,col6             -- �Z���Q
             ,col7             -- �Z���R
             ,col8             -- �ڋq�R�[�h
             ,col9             -- �ڋq��
             ,col10            -- �S�����_��
             ,col11            -- �d�b�ԍ�
             ,col12            -- �Ώ۔N��
             ,col13            -- ���|�Ǘ��R�[�h�A��������
             ,col14            -- �������o�͋敪
             ,col15            -- �����������グ�z
             ,col16            -- ����œ�
             ,col17            -- ���������z
             ,col18            -- �����\���
             ,col19            -- �U�����s��
             ,col20            -- �U�����s�x�X��
             ,col21            -- �U����������
             ,col22            -- �U��������ԍ�
             ,col23            -- �U����������`�l�J�i��
             ,col24            -- �X�܃R�[�h
             ,col25            -- �X�ܖ�
             ,col26            -- �`�[���t
             ,col27            -- �`�[No
             ,col28            -- �`�[���z
             ,col29            -- ���C�A�E�g�敪
             ,col101           -- �`�[�Ŕ��z(��o�͍���)
             ,col102           -- �`�[�Ŋz(��o�͍���)
             ,col103           -- ������ڋq�R�[�h(��o�͍���)
             ,col104)          -- ������ڋq��(��o�͍���)
            SELECT cn_request_id                                              request_id         -- �v��ID
                  ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
                  ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
                  ,cv_record_kbn1                                             record_kbn         -- ���R�[�h�敪
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- ���s���t
                  ,NULL                                                       zip_code           -- �X�֔ԍ�
                  ,NULL                                                       send_address1      -- �Z���P
                  ,NULL                                                       send_address2      -- �Z���Q
                  ,NULL                                                       send_address3      -- �Z���R
                  ,xil.ship_cust_code                                         bill_cust_code     -- �ڋq�R�[�h
                  ,NULL                                                       bill_cust_name     -- �ڋq��
                  ,NULL                                                       location_name      -- ���_��
                  ,NULL                                                       phone_num          -- �d�b�ԍ�
                  ,xih.object_month                                           object_month       -- �Ώ۔N��
                  ,xil.ship_cust_code||' '||xih.term_name                     ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
                  ,DECODE(xxca.tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                      ,cv_tax_div_nontax,cv_out_div_excluded
                                      ,cv_out_div_included)
                                                                              out_put_div        -- �������o�͋敪
                  ,NULL                                                       inv_amount         -- �����������グ�z
                  ,NULL                                                       tax_amount         -- ����œ�
                  ,NULL                                                       total_amount       -- ���������z
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- �����\���
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                            ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                              ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                    END                                                        banc_number        -- ��s��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                            ,CASE WHEN INSTR(bank.bank_branch_name
                                            ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                    END                                                        bank_branch_number -- �x�X��
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                            ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                    END                                                        bank_account_type  -- �������
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                            ,bank.bank_account_num)
                    END                                                        bank_account_num   -- �����ԍ�
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                            ,bank.account_holder_name_alt)
                    END                                                        bank_account_name  -- �������`�l�J�i��
                  ,NULL                                                        ship_cust_code     -- �X�܃R�[�h
                  ,NULL                                                        ship_cust_name     -- �X�ܖ�
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                  ,xil.delivery_date
                                  ,xil.acceptance_date)
                                  ,cv_format_date_yyyymmdd)                          slip_date    -- �`�[���t
                  ,xil.slip_num                                                      slip_num     -- �`�[�ԍ�
                  ,SUM(CASE
                        WHEN xxca.tax_div IN (cv_tax_div_nontax
                                             ,cv_tax_div_excluded)
                        THEN
                            xil.ship_amount
                        ELSE
                            xil.tax_amount + xil.ship_amount
                        END)                                                         slip_sum          -- �`�[���z
                  ,cv_layout_kbn1                                                    layout_kbn        -- ���C�A�E�g�敪
                  ,SUM(xil.ship_amount)                                              slip_sum_ex_tax   -- �`�[�Ŕ��z
                  ,SUM(xil.tax_amount)                                               slip_tax          -- �`�[�Ŋz
                  ,NULL                                                              payment_cust_code -- ������ڋq�R�[�h
                  ,NULL                                                              payment_cust_name -- ������ڋq��
            FROM xxcfr_invoice_headers          xih  , -- �����w�b�_
                  xxcfr_invoice_lines            xil  , -- ��������
                  xxcmm_cust_accounts            xxca , -- �ڋq10�ǉ����
                  (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --�x�����@���
                        ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                        ,ap_bank_accounts_all           abaa                 --��s����
                        ,ap_bank_branches               abb                  --��s�x�X
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  all_account_rec.customer_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- �O�������̂��߂̃_�~�[����
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND xxca.customer_code = all_account_rec.customer_code
            GROUP BY xih.inv_creation_date,                                               -- ���s���t
                     xil.ship_cust_code,                                                  -- �ڋq�R�[�h
                     xih.object_month,                                                    -- �Ώ۔N��
                     xih.term_name,                                                       -- �x������
                     xxca.tax_div,                                                        -- ����ŋ敪
                     xih.payment_date,                                                    -- �����\���
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                               CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                               THEN
                                 bank.bank_name
                               ELSE
                                 bank.bank_name || gv_format_bank
                               END
                             ELSE
                               bank.bank_name 
                             END)
                     END,                                                                 -- ��s��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                             THEN
                               bank.bank_branch_name
                             ELSE
                               bank.bank_branch_name || gv_format_branch
                             END)
                     END,                                                                 -- �x�X��
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,DECODE(bank.bank_account_type
                                   ,1, gv_format_account
                                   ,2, gv_format_current
                                   ,bank.bank_account_type))
                     END,                                                                 -- �������
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.bank_account_num)
                     END,                                                                 -- �����ԍ�
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- �������`�l�J�i��
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- �`�[���t
                     xil.slip_num;                                                        -- �`�[�ԍ�
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          END IF;
--
          CLOSE get_10inv_type_cur;
--
        END IF;
      END LOOP get_account10_loop;
--
      -- �X�ܕʏ��v���R�[�h�쐬
      INSERT INTO xxcfr_csv_outs_temp(
        request_id       -- �v��ID
        ,seq              -- �o�͏�
        ,col1             -- �w�b�_/���׋敪
        ,col2             -- ���R�[�h�敪
        ,col3             -- ���s���t
        ,col4             -- �X�֔ԍ�
        ,col5             -- �Z���P
        ,col6             -- �Z���Q
        ,col7             -- �Z���R
        ,col8             -- �ڋq�R�[�h
        ,col9             -- �ڋq��
        ,col10            -- �S�����_��
        ,col11            -- �d�b�ԍ�
        ,col12            -- �Ώ۔N��
        ,col13            -- ���|�Ǘ��R�[�h�A��������
        ,col14            -- �������o�͋敪
        ,col15            -- �����������グ�z
        ,col16            -- ����œ�
        ,col17            -- ���������z
        ,col18            -- �����\���
        ,col19            -- �U�����s��
        ,col20            -- �U�����s�x�X��
        ,col21            -- �U����������
        ,col22            -- �U��������ԍ�
        ,col23            -- �U����������`�l�J�i��
        ,col24            -- �X�܃R�[�h
        ,col25            -- �X�ܖ�
        ,col26            -- �`�[���t
        ,col27            -- �`�[No
        ,col28            -- �`�[���z
        ,col29)           -- ���C�A�E�g�敪
      SELECT cn_request_id                                              request_id         -- �v��ID
            ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
            ,cv_line_kbn                                                header_line_kbn    -- �w�b�_/���׋敪
            ,cv_record_kbn2                                             record_kbn         -- ���R�[�h�敪
            ,xxcot.col3                                                 issue_date         -- ���s���t
            ,NULL                                                       zip_code           -- �X�֔ԍ�
            ,NULL                                                       send_address1      -- �Z���P
            ,NULL                                                       send_address2      -- �Z���Q
            ,NULL                                                       send_address3      -- �Z���R
            ,xxcot.col8                                                 bill_cust_code     -- �ڋq�R�[�h
            ,NULL                                                       bill_cust_name     -- �ڋq��
            ,NULL                                                       location_name      -- ���_��
            ,NULL                                                       phone_num          -- �d�b�ԍ�
            ,NULL                                                       object_month       -- �Ώ۔N��
            ,NULL                                                       ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
            ,NULL                                                       out_put_div        -- �������o�͋敪
            ,NULL                                                       inv_amount         -- �����������グ�z
            ,NULL                                                       tax_amount         -- ����œ�
            ,NULL                                                       total_amount       -- ���������z
            ,NULL                                                       payment_date       -- �����\���
            ,NULL                                                       banc_number        -- ��s��
            ,NULL                                                       bank_branch_number -- �x�X��
            ,NULL                                                       bank_account_type  -- �������
            ,NULL                                                       bank_account_num   -- �����ԍ�
            ,NULL                                                       bank_account_name  -- �������`�l�J�i��
            ,xxcot.col24                                                ship_cust_code     -- �X�܃R�[�h
            ,xxcot.col25                                                ship_cust_name     -- �X�ܖ�
            ,NULL                                                       slip_date          -- �`�[���t
            ,NULL                                                       slip_num           -- �`�[�ԍ�
            ,SUM(TO_NUMBER(xxcot.col28))                                slip_sum           -- �`�[���z
            ,cv_layout_kbn2                                             layout_kbn         -- ���C�A�E�g�敪
      FROM xxcfr_csv_outs_temp          xxcot  -- CSV�o�̓��[�N�e�[�u��
      WHERE xxcot.request_id = cn_request_id
        AND xxcot.col29 = cv_layout_kbn2       -- ���C�A�E�g�敪 = '2'(�X�ܕʓ��󃌃C�A�E�g)
        AND xxcot.col2 = cv_record_kbn1        -- ���R�[�h�敪 = '1'(�X�ܕʖ��׃��R�[�h)
      GROUP BY xxcot.col3,                                                                 -- ���s���t
               xxcot.col8,                                                                 -- �ڋq�R�[�h
               xxcot.col24,                                                                -- �X�܃R�[�h
               xxcot.col25;                                                                -- �X�ܖ�
--
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
      -- �w�b�_���R�[�h�쐬
      INSERT INTO xxcfr_csv_outs_temp(
        request_id       -- �v��ID
        ,seq              -- �o�͏�
        ,col1             -- �w�b�_/���׋敪
        ,col2             -- ���R�[�h�敪
        ,col3             -- ���s���t
        ,col4             -- �X�֔ԍ�
        ,col5             -- �Z���P
        ,col6             -- �Z���Q
        ,col7             -- �Z���R
        ,col8             -- �ڋq�R�[�h
        ,col9             -- �ڋq��
        ,col10            -- �S�����_��
        ,col11            -- �d�b�ԍ�
        ,col12            -- �Ώ۔N��
        ,col13            -- ���|�Ǘ��R�[�h�A��������
        ,col14            -- �������o�͋敪
        ,col15            -- �����������グ�z
        ,col16            -- ����œ�
        ,col17            -- ���������z
        ,col18            -- �����\���
        ,col19            -- �U�����s��
        ,col20            -- �U�����s�x�X��
        ,col21            -- �U����������
        ,col22            -- �U��������ԍ�
        ,col23            -- �U����������`�l�J�i��
        ,col24            -- �X�܃R�[�h
        ,col25            -- �X�ܖ�
        ,col26            -- �`�[���t
        ,col27            -- �`�[No
        ,col28            -- �`�[���z
        ,col29            -- ���C�A�E�g�敪
        ,col103           -- ������ڋq�R�[�h(��o�͍���)
        ,col104)          -- ������ڋq��(��o�͍���)
      SELECT cn_request_id                                              request_id         -- �v��ID
            ,TO_NUMBER(NULL)                                            seq                -- �o�͏�
            ,cv_header_kbn                                              header_line_kbn    -- �w�b�_/���׋敪
            ,cv_record_kbn0                                             record_kbn         -- ���R�[�h�敪
            ,xxcot.col3                                                 issue_date         -- ���s���t
            ,hzlo.postal_code                                           zip_code           -- �X�֔ԍ�
            ,hzlo.state||hzlo.city                                      send_address1      -- �Z���P
            ,hzlo.address1                                              send_address2      -- �Z���Q
            ,hzlo.address2                                              send_address3      -- �Z���R
            ,xxcot.col8                                                 bill_cust_code     -- �ڋq�R�[�h
            ,hzpa.party_name                                            bill_cust_name     -- �ڋq��
            ,xffvv.description                                          location_name      -- ���_��
            ,xxcfr_common_pkg.get_base_target_tel_num(xxcot.col8)       phone_num          -- �d�b�ԍ�
            ,xxcot.col12                                                object_month       -- �Ώ۔N��
            ,xxcot.col13                                                ar_concat_text     -- ���|�Ǘ��R�[�h�A��������
            ,xxcot.col14                                                out_put_div        -- �������o�͋敪
            ,SUM(TO_NUMBER(xxcot.col101))                               inv_amount         -- �����������グ�z
            ,SUM(TO_NUMBER(xxcot.col102))                               tax_amount         -- ����œ�
            ,SUM(TO_NUMBER(xxcot.col101) + TO_NUMBER(xxcot.col102))     total_amount       -- ���������z
            ,xxcot.col18                                                payment_date       -- �����\���
            ,xxcot.col19                                                banc_number        -- ��s��
            ,xxcot.col20                                                bank_branch_number -- �x�X��
            ,xxcot.col21                                                bank_account_type  -- �������
            ,xxcot.col22                                                bank_account_num   -- �����ԍ�
            ,xxcot.col23                                                bank_account_name  -- �������`�l�J�i��
            ,NULL                                                       ship_cust_code     -- �X�܃R�[�h
            ,NULL                                                       ship_cust_name     -- �X�ܖ�
            ,NULL                                                       slip_date          -- �`�[���t
            ,NULL                                                       slip_num           -- �`�[�ԍ�
            ,NULL                                                       slip_sum           -- �`�[���z
            ,xxcot.col29                                                layout_kbn         -- ���C�A�E�g�敪
            ,NVL(xxcot.col103,xxcot.col8)                               payment_cust_code  -- ������ڋq�r���[(�P�ƓX�̏ꍇ�ڋq�R�[�h���Z�b�g)
            ,NVL(xxcot.col104,hzpa.party_name)                          payment_cust_name  -- ������ڋq��(�P�ƓX�̏ꍇ�ڋq�����Z�b�g)
      FROM xxcfr_csv_outs_temp          xxcot,  -- CSV�o�̓��[�N�e�[�u��
           xxcmm_cust_accounts          xxca,   -- �ڋq�ǉ����
           hz_cust_accounts             hzca,   -- �ڋq�}�X�^
           hz_parties                   hzpa,   -- �p�[�e�B
           hz_cust_acct_sites           hcas,   -- �ڋq���ݒn
           hz_party_sites               hzps,   -- �p�[�e�B�T�C�g
           hz_locations                 hzlo,   -- �ڋq���Ə�
           (SELECT flex_value,
                   description
            FROM   fnd_flex_values_vl ffv
            WHERE  EXISTS
                   (SELECT  'X'
                    FROM    fnd_flex_value_sets
                    WHERE   flex_value_set_name = cv_ffv_set_name_dept
                    AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  -- ����l�Z�b�g
      WHERE xxcot.request_id = cn_request_id
        AND xxcot.col2 = cv_record_kbn1                             -- ���R�[�h�敪 = '1'(���׃��R�[�h)
        AND xxca.customer_code = xxcot.col8                         -- �ڋq�ǉ����.�ڋq�R�[�h = CSV���[�N.�ڋq�R�[�h
        AND hzca.cust_account_id = xxca.customer_id                 -- �ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
        AND hzpa.party_id = hzca.party_id                           -- �p�[�e�B.�p�[�e�BID = �ڋq�}�X�^.�p�[�e�BID
        AND hcas.cust_account_id = hzca.cust_account_id             -- �ڋq���ݒn.�ڋqID = �ڋq�}�X�^.�ڋqID
        AND hzps.party_site_id = hcas.party_site_id                 -- �p�[�e�B�T�C�g.�p�[�e�B�T�C�gID = �ڋq���ݒn.�p�[�e�B�T�C�gID
        AND hzlo.location_id = hzps.location_id                     -- �ڋq���Ə�.���Ə�ID = �p�[�e�B�T�C�g.���Ə�ID
        AND xffvv.flex_value = xxca.bill_base_code                  -- ����l�Z�b�g.�R�[�h = �ڋq�ǉ����.�������_�R�[�h
      GROUP BY xxcot.col3,                                                                 -- ���s���t
               hzlo.postal_code,                                                           -- �X�֔ԍ�
               hzlo.state||hzlo.city,                                                      -- �Z���P
               hzlo.address1,                                                              -- �Z���Q
               hzlo.address2,                                                              -- �Z���R
               xxcot.col8,                                                                 -- �ڋq�R�[�h
               hzpa.party_name,                                                            -- �ڋq��
               xffvv.description,                                                          -- ���_��
               xxcot.col12,                                                                -- �Ώ۔N��
               xxcot.col13,                                                                -- ���|�Ǘ��R�[�h�A��������
               xxcot.col14,                                                                -- �������o�͋敪
               xxcot.col18,                                                                -- �����\���
               xxcot.col19,                                                                -- ��s��
               xxcot.col20,                                                                -- �x�X��
               xxcot.col21,                                                                -- �������
               xxcot.col22,                                                                -- �����ԍ�
               xxcot.col23,                                                                -- �������`�l�J�i��
               xxcot.col29,                                                                -- ���C�A�E�g�敪
               xxcot.col103,                                                               -- ������ڋq�R�[�h
               xxcot.col104;                                                               -- ������ڋq��
--
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
      -- ���׃��R�[�h�X�V(�s�v�ȍ��ڒl���N���A����)
      UPDATE xxcfr_csv_outs_temp xxcot
      SET col12 = NULL,                          -- �Ώ۔N��
          col13 = NULL,                          -- ���|�Ǘ��R�[�h�A��������
          col14 = NULL,                          -- �������o�͋敪
          col18 = NULL,                          -- �����\���
          col19 = NULL,                          -- �U�����s��
          col20 = NULL,                          -- �U�����s�x�X��
          col21 = NULL,                          -- �U����������
          col22 = NULL,                          -- �U��������ԍ�
          col23 = NULL                           -- �U����������`�l�J�i��
      WHERE xxcot.request_id = cn_request_id
        AND xxcot.col2 = cv_record_kbn1;         -- ���R�[�h�敪 = '1'(���׃��R�[�h)
--
/*
      INSERT INTO xxcfr_csv_outs_temp(
        request_id       -- �v��ID
       ,seq              -- �o�͏�
       ,col1             -- ���s���t
       ,col2             -- �X�֔ԍ�
       ,col3             -- �Z��1
       ,col4             -- �Z��2
       ,col5             -- �Z��3
       ,col6             -- �ڋq�R�[�h
       ,col7             -- �ڋq��
       ,col8             -- �S�����_��
       ,col9             -- �d�b�ԍ�
       ,col10            -- �Ώ۔N��
       ,col11            -- ���|�Ǘ��R�[�h�A��������
       ,col12            -- �������o�͋敪
       ,col13            -- ���������グ�z
       ,col14            -- ����œ�
       ,col15            -- ���������z
       ,col16            -- �����\���
       ,col17            -- �U������
       ,col18            -- �`�[���t
       ,col19            -- �`�[No
       ,col20)           -- �`�[���z
      SELECT
             bill.request_id       -- �v��ID
            ,ROWNUM                -- �\����
            ,bill.issue_date       -- ���s���t
            ,bill.zip_code         -- �X�֔ԍ�
            ,bill.send_address1    -- �Z���P
            ,bill.send_address2    -- �Z���Q
            ,bill.send_address3    -- �Z���R
            ,bill.bill_cust_code   -- �ڋq�R�[�h
            ,bill.bill_cust_name   -- �ڋq��
            ,bill.location_name    -- �S�����_��
            ,bill.phone_num        -- �d�b�ԍ�
            ,bill.target_date      -- �Ώ۔N��
            ,bill.ar_concat_text   -- ���|�Ǘ��R�[�h�A��������
            ,bill.out_put_div      -- �������o�͋敪
            ,bill.inv_amount       -- ���������グ�z
            ,bill.tax_amount       -- ����œ�
            ,bill.total_amount     -- ���������z
            ,bill.payment_due_date -- �����\���
            ,bill.account_data     -- �U���������
            ,bill.line_date        -- �`�[���t
            ,bill.line_number      -- �`�[No
            ,bill.line_amount      -- �`�[���z
      FROM
             (SELECT
                     cn_request_id                                        request_id       -- �v��ID
                    ,TO_CHAR(xih.inv_creation_date,gv_format_date_jpymd4) issue_date       -- ���s���t
                    ,DECODE(xih.postal_code,
                            NULL,NULL,
                            gv_format_zip_mark ||
                              SUBSTR(xih.postal_code,1,3) || '-' || 
                              SUBSTR(xih.postal_code,4,4))                zip_code         -- �X�֔ԍ�
                    ,xih.send_address1                                    send_address1    -- �Z���P
                    ,xih.send_address2                                    send_address2    -- �Z���Q
                    ,xih.send_address3                                    send_address3    -- �Z���R
                    ,xih.bill_cust_code                                   bill_cust_code   -- �ڋq�R�[�h
                    ,xih.send_to_name                                     bill_cust_name   -- �ڋq��
                    ,xih.bill_location_name                               location_name    -- �S�����_��
                    ,xih.agent_tel_num                                    phone_num        -- �d�b�ԍ�
                    ,SUBSTR(xih.object_month,1,4)||gv_format_date_year||
                       SUBSTR(xih.object_month,5,2)||gv_format_date_month target_date      -- �Ώ۔N��
                    ,xih.payment_cust_code || ' ' ||
                       xih.bill_cust_code  || ' ' ||
                       xih.term_name                                      ar_concat_text   -- ���|�Ǘ��R�[�h�A��������
                    ,CASE
                     WHEN xbcv.tax_div IN (cv_tax_div_nontax
                                          ,cv_tax_div_excluded)
                     THEN
                          cv_out_div_excluded
                     ELSE
                          cv_out_div_included
                     END                                                  out_put_div      -- �������o�͋敪
                    ,xih.inv_amount_no_tax                                inv_amount       -- ���������グ�z
                    ,xih.tax_amount_sum                                   tax_amount       -- ����œ�
                    ,xih.inv_amount_includ_tax                            total_amount     -- ���������z
                    ,TO_CHAR(xih.payment_date, gv_format_date_jpymd2)     payment_due_date -- �����\���
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- �_�~�[��s�̏ꍇ��NULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END || ' ' ||                                    -- ��s��
                              CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END || ' ' ||                                    -- �x�X��
                              DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type) || ' ' ||         -- �������
                              bank.bank_account_num || ' ' ||                  -- �����ԍ�
                              bank.account_holder_name || ' ' ||               -- �������`�l
                              bank.account_holder_name_alt)                    -- �������`�l�J�i��
                     END                                                  account_data     -- �U���������
                    ,TO_CHAR(DECODE(xil.acceptance_date
                                   ,NULL, xil.delivery_date
                                   ,xil.acceptance_date)
                            ,cv_format_date_ymd)                          line_date        -- �`�[���t
                    ,xil.slip_num                                         line_number      -- �`�[No
                    ,SUM(CASE
                         WHEN xbcv.tax_div IN (cv_tax_div_nontax
                                              ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                             line_amount      -- �`�[���z
              FROM
                     xxcfr_invoice_headers          xih                     -- �����w�b�_
                    ,xxcfr_invoice_lines            xil                     -- ��������
                    ,xxcfr_bill_customers_v         xbcv                    -- ������ڋq�r���[
                    ,(SELECT
                             rcrm.customer_id             customer_id
                            ,abb.bank_number              bank_number
                            ,abb.bank_name                bank_name
                            ,abb.bank_branch_name         bank_branch_name
                            ,abaa.bank_account_type       bank_account_type
                            ,abaa.bank_account_num        bank_account_num
                            ,abaa.account_holder_name     account_holder_name
                            ,abaa.account_holder_name_alt account_holder_name_alt
                      FROM
                             ra_cust_receipt_methods        rcrm                 --�x�����@���
                            ,ar_receipt_method_accounts_all arma                 --AR�x�����@����
                            ,ap_bank_accounts_all           abaa                 --��s����
                            ,ap_bank_branches               abb                  --��s�x�X
                      WHERE
                             rcrm.primary_flag      = cv_flag_yes
                        AND  gd_target_date   BETWEEN rcrm.start_date
                                                  AND NVL(rcrm.end_date, gd_max_date)
                        AND  rcrm.site_use_id      IS NOT NULL
                        AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                        AND  arma.bank_account_id   = abaa.bank_account_id(+)
                        AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                        AND  arma.org_id            = gn_org_id
                        AND  abaa.org_id            = gn_org_id) bank            -- ��s�����r���[
              WHERE
                    xih.invoice_id      = xil.invoice_id                         -- �ꊇ������ID
                AND xih.cutoff_date     = gd_target_date                         -- �p�����[�^�D����
                AND xih.set_of_books_id = gn_set_of_bks_id                       -- ��v����ID
                AND xih.org_id          = gn_org_id                              -- �g�DID
                AND EXISTS (SELECT
                                   1
                            FROM
                                   xxcfr_bill_customers_v xb                     -- ������ڋq�r���[
                            WHERE
                                   xih.bill_cust_code    = xb.bill_customer_code
                              AND  xb.inv_prt_type       = cv_inv_prt_type       -- �������o�͌`��
                              AND  xb.cons_inv_flag      = cv_flag_yes           -- �ꊇ�����t���O
                              AND  xb.bill_customer_code = NVL(iv_bill_cust_code, xb.bill_customer_code))
                AND xih.bill_cust_code   = xbcv.bill_customer_code
                AND xbcv.pay_customer_id = bank.customer_id(+)
              GROUP BY cn_request_id
                      ,TO_CHAR(xih.inv_creation_date,gv_format_date_jpymd4)
                      ,DECODE(xih.postal_code,
                              NULL,NULL,
                              gv_format_zip_mark ||
                                SUBSTR(xih.postal_code,1,3) || '-' ||
                                SUBSTR(xih.postal_code,4,4))
                      ,xih.send_address1
                      ,xih.send_address2
                      ,xih.send_address3
                      ,xih.bill_cust_code
                      ,xih.send_to_name
                      ,xih.bill_location_name
                      ,xih.agent_tel_num
                      ,SUBSTR(xih.object_month,1,4)||gv_format_date_year||
                         SUBSTR(xih.object_month,5,2)||gv_format_date_month
                      ,xih.payment_cust_code || ' ' ||
                         xih.bill_cust_code  || ' ' ||
                         xih.term_name
                      ,CASE
                       WHEN xbcv.tax_div IN (cv_tax_div_nontax
                                            ,cv_tax_div_excluded)
                       THEN
                            cv_out_div_excluded
                       ELSE
                            cv_out_div_included
                       END
                      ,xih.inv_amount_no_tax
                      ,xih.tax_amount_sum
                      ,xih.inv_amount_includ_tax
                      ,TO_CHAR(xih.payment_date, gv_format_date_jpymd2)
                      ,CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name
                                END || ' ' ||
                                CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END || ' ' ||
                                DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type) || ' ' ||
                                bank.bank_account_num || ' ' ||
                                bank.account_holder_name || ' ' ||
                                bank.account_holder_name_alt)
                       END
                      ,TO_CHAR(DECODE(xil.acceptance_date
                                     ,NULL, xil.delivery_date
                                     ,xil.acceptance_date)
                              ,cv_format_date_ymd)
                      ,xil.slip_num
              ORDER BY
                       bill_cust_code
                      ,line_date
                      ,line_number) bill;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
*/
-- Modify 2009-09-29 Ver1.10 End
      -- �o�^�f�[�^���P�������݂��Ȃ��ꍇ�A�O�����b�Z�[�W���O�o��
      IF (gn_target_cnt = 0) THEN
--
        -- �x���I��
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr
                              ,iv_name         => cv_msg_xxcfr_00024)  -- �Ώۃf�[�^0���x��
                            ,1
                            ,5000);
--
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
--
        ov_retcode := cv_status_warn;
--
      END IF;
--
    EXCEPTION
      -- �o�^���G���[
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr
                              ,iv_name         => cv_msg_xxcfr_00016                            -- �e�[�u���}���G���[
                              ,iv_token_name1  => cv_tkn_table                                  -- �g�[�N���F�e�[�u����
                              ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table)) -- ���[�N�e�[�u��
                            ,1
                            ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- ���������̐ݒ�
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : chk_account_data
   * Description      : �������擾�`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE chk_account_data(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_account_data'; -- �v���O������
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
    ln_target_cnt    NUMBER DEFAULT 0; -- �Ώی���
    lv_warn_msg      VARCHAR2(5000);
    lv_cust_data_msg VARCHAR2(5000);
    lv_warn_bill_num VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �������Ȃ����ג��o
-- Modify 2009-09-29 Ver1.10 Start
    CURSOR sel_no_account_data_cur
    IS
      SELECT
            -- xcot.col6 bill_cust_code
             xcot.col103 payment_cust_code   -- ������ڋq�R�[�h
            --,xcot.col7 bill_cust_name
            ,xcot.col104 payment_cust_name   -- ������ڋq��
            --,xcot.col8 bill_location_name
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- �v��ID
        AND  xcot.col1 = cv_header_kbn         -- �w�b�_/���׋敪 = '1'(�w�b�_�[)
        --AND  xcot.col17      IS NULL
        AND  xcot.col19 IS NULL                -- �U�����s�� IS NULL
      GROUP BY --xcot.col6,
               xcot.col103,
               --xcot.col7,
               xcot.col104
               --xcot.col8
      ORDER BY --xcot.col6;
               xcot.col103;
-- Modify 2009-09-29 Ver1.10 End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���������s�Ώۃf�[�^�����݂���ꍇ�ȉ��̏��������s
    IF (gn_target_cnt > 0) THEN
--      END IF;
      -- �������Ȃ����ג��o
      <<sel_no_account_loop>>
      FOR l_sel_no_account_data_rec IN sel_no_account_data_cur LOOP
--
        -- �͂��߂ɐU���������o�^���b�Z�[�W���o��
        IF (sel_no_account_data_cur%ROWCOUNT = 1) THEN
        --�P�s���s
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''
        );
--
        -- �U���������o�^���b�Z�[�W�o��
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_xxcfr_00038)
                              ,1
                              ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        END IF;
--
        -- �ڋq�R�[�h�E�ڋq�����b�Z�[�W�o��
        lv_cust_data_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00051
                                     ,iv_token_name1  => cv_tkn_ac_code
-- Modify 2009-09-29 Ver1.10 Start
                                     --,iv_token_value1 => l_sel_no_account_data_rec.bill_cust_code
                                     ,iv_token_value1 => l_sel_no_account_data_rec.payment_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     --,iv_token_value2 => l_sel_no_account_data_rec.bill_cust_name
-- Modify 2009-09-29 Ver1.10 End
                                     ,iv_token_value2 => l_sel_no_account_data_rec.payment_cust_name)
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_cust_data_msg
        );
--
        ln_target_cnt := sel_no_account_data_cur%ROWCOUNT;
--
      END LOOP sel_no_account_loop;
--
      -- ����������1���ȏ㍇�����ꍇ
      IF (ln_target_cnt > 0) THEN
        -- �ڋq�R�[�h�̌��������b�Z�[�W�o��
        lv_warn_bill_num := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00052
                                     ,iv_token_name1  => cv_tkn_count
                                     ,iv_token_value1 => TO_CHAR(ln_target_cnt))
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_bill_num
        );
--
        --�P�s���s
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
--
        -- �x���I��
        ov_retcode := cv_status_warn;
--
      END IF;
--
    END IF;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END chk_account_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_line_cnt_limit
   * Description      : ���������׌����`�F�b�N (A-5)
   ***********************************************************************************/
  PROCEDURE chk_line_cnt_limit(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_line_cnt_limit'; -- �v���O������
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
    ln_target_cnt    NUMBER DEFAULT 0; -- �Ώی���
    lv_warn_msg      VARCHAR2(5000);
    lv_cust_data_msg VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���׌��������ڋq��񒊏o(�X�ܕʓ���Ȃ�)
-- Modify 2009-09-29 Ver1.10 Start
    CURSOR line_cnt_limit_cur
    IS
      SELECT
            -- xcot.col6        bill_cust_code     -- ������ڋq�R�[�h
             xcot.col8        bill_cust_code     -- ������ڋq�R�[�h
            --,xcot.col7        bill_cust_name     -- ������ڋq��
            ,xcot.col9        bill_cust_name     -- ������ڋq��
            --,xcot.col8        bill_location_name -- �S�����_��
            ,xcot.col10       bill_location_name -- �S�����_��
            ,COUNT(xcot.col8) line_count         -- ���׌���
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- �v��ID
        AND  xcot.col29 = cv_layout_kbn1       -- ���C�A�E�g�敪 = '1'(�X�ܕʓ���Ȃ�)
      HAVING count(xcot.col8) > gn_line_cnt_limit
      GROUP BY --xcot.col6,
               xcot.col8,
               --xcot.col7,
               xcot.col9,
               --xcot.col8
               xcot.col10
      ORDER BY --xcot.col6;
               xcot.col8;
--
    CURSOR line_cnt_limit2_cur
    IS
      SELECT
             xcot.col8        bill_cust_code     -- ������ڋq�R�[�h
            ,xcot.col9        bill_cust_name     -- ������ڋq��
            ,xcot.col10       bill_location_name -- �S�����_��
            ,COUNT(xcot.col8) line_count         -- ���׌���
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- �v��ID
        AND  xcot.col29 = cv_layout_kbn2       -- ���C�A�E�g�敪 = '2'(�X�ܕʓ��󂠂�)
      HAVING count(xcot.col8) > gn_line_cnt_limit2
      GROUP BY xcot.col8,
               xcot.col9,
               xcot.col10
      ORDER BY xcot.col8;
-- Modify 2009-09-29 Ver1.10 End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���������s�Ώۃf�[�^�����݂���ꍇ�ȉ��̏��������s
    IF (gn_target_cnt > 0) THEN
      -- ���׌��������ڋq��񒊏o(�X�ܕʓ���Ȃ�)
      <<sel_no_account_loop>>
      FOR l_line_cnt_limit_rec IN line_cnt_limit_cur LOOP
--
        -- �͂��߂ɐ��������׌����������b�Z�[�W���o��
        IF (line_cnt_limit_cur%ROWCOUNT = 1) THEN
        --�P�s���s
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''
        );
--
        -- ���������׌����������b�Z�[�W�o��
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_xxcfr_00071
                                ,iv_token_name1  => cv_tkn_rec_limit
                                ,iv_token_value1 => TO_CHAR(gn_line_cnt_limit))
                              ,1
                              ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        END IF;
--
        -- �ڋq�R�[�h�E�ڋq�����b�Z�[�W�o��
        lv_cust_data_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00072
                                     ,iv_token_name1  => cv_tkn_ac_code
                                     ,iv_token_value1 => l_line_cnt_limit_rec.bill_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     ,iv_token_value2 => l_line_cnt_limit_rec.bill_cust_name
                                     ,iv_token_name3  => cv_tkn_lc_name
                                     ,iv_token_value3 => l_line_cnt_limit_rec.bill_location_name
                                     ,iv_token_name4  => cv_tkn_count
                                     ,iv_token_value4 => l_line_cnt_limit_rec.line_count)
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_cust_data_msg
        );
--
        ln_target_cnt := line_cnt_limit_cur%ROWCOUNT;
--
      END LOOP sel_no_account_loop;
--
-- Modify 2009-09-29 Ver1.10 Start
      -- ���׌��������ڋq��񒊏o(�X�ܕʓ��󂠂�)
      <<sel_no_account_loop2>>
      FOR l_line_cnt_limit2_rec IN line_cnt_limit2_cur LOOP
--
        -- �͂��߂ɐ��������׌����������b�Z�[�W���o��
        IF (line_cnt_limit2_cur%ROWCOUNT = 1) THEN
        --�P�s���s
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''
        );
--
        -- ���������׌����������b�Z�[�W�o��
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_xxcfr_00071
                                ,iv_token_name1  => cv_tkn_rec_limit
                                ,iv_token_value1 => TO_CHAR(gn_line_cnt_limit2))
                              ,1
                              ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        END IF;
--
        -- �ڋq�R�[�h�E�ڋq�����b�Z�[�W�o��
        lv_cust_data_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00072
                                     ,iv_token_name1  => cv_tkn_ac_code
                                     ,iv_token_value1 => l_line_cnt_limit2_rec.bill_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     ,iv_token_value2 => l_line_cnt_limit2_rec.bill_cust_name
                                     ,iv_token_name3  => cv_tkn_lc_name
                                     ,iv_token_value3 => l_line_cnt_limit2_rec.bill_location_name
                                     ,iv_token_name4  => cv_tkn_count
                                     ,iv_token_value4 => l_line_cnt_limit2_rec.line_count)
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_cust_data_msg
        );
--
        ln_target_cnt := ln_target_cnt + line_cnt_limit2_cur%ROWCOUNT;
--
      END LOOP sel_no_account_loop2;
-- Modify 2009-09-29 Ver1.10 End
--
      -- ����������1���ȏ㍇�����ꍇ
      IF (ln_target_cnt > 0) THEN
        -- �x���I��
        ov_retcode := cv_status_warn;
--
      END IF;
--
    END IF;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
  END chk_line_cnt_limit;
--
  /**********************************************************************************
   * Procedure Name   : csv_file_output
   * Description      : �t�@�C���o�͏���(A-6)
   ***********************************************************************************/
  PROCEDURE csv_file_output(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  �Œ胍�[�J���萔�錾�� START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_file_output';  -- �v���O������
--
--##############################  �Œ蕔 END   ##################################
    --===============================================================
    -- ���[�J���萔
    --===============================================================
    --===============================================================
    -- ���[�J���ϐ�
    --===============================================================
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   #######################
--
    lv_retcode VARCHAR2(1);    -- ���ʊ֐����^�[���R�[�h
    lv_errbuf  VARCHAR2(5000); -- ���ʊ֐��G���[�o�b�t�@
    lv_errmsg  VARCHAR2(5000); -- ���ʊ֐��G���[���b�Z�[�W
--
--##############################  �Œ蕔 END   ##################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- OUT�t�@�C���o�͏������s
    xxcfr_common_pkg.csv_out(in_request_id  => cn_request_id,      -- �v��ID
                             iv_lookup_type => cv_lookup_type_out, -- ���ږ��p�Q�ƃ^�C�v
                             in_rec_cnt     => gn_target_cnt,      -- ��������
                             ov_retcode     => lv_retcode,
                             ov_errbuf      => lv_errbuf,
                             ov_errmsg      => lv_errmsg
                            );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfr 
                                                   ,cv_msg_xxcfr_00010 -- ���ʊ֐��G���[
                                                   ,cv_tkn_func        -- �g�[�N��'�@�\��'
                                                   ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                      ,cv_dict_csv_out))
                                                   -- OUT�t�@�C���o�͋��ʊ֐��G���[
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END csv_file_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code14     IN      VARCHAR2,         -- ���|�Ǘ���ڋq
    ov_errbuf              OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT     VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT     VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
--
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       iv_target_date         -- ����
      ,iv_customer_code10     -- �ڋq
      ,iv_customer_code20     -- �������p�ڋq
      ,iv_customer_code21     -- �����������p�ڋq
      ,iv_customer_code14     -- ���|�Ǘ���ڋq
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�o�^ (A-3)
    -- =====================================================
    insert_work_table(
       iv_target_date         -- ����
      ,iv_customer_code10     -- �ڋq
      ,iv_customer_code20     -- �������p�ڋq
      ,iv_customer_code21     -- �����������p�ڋq
      ,iv_customer_code14     -- ���|�Ǘ���ڋq
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
-- Modify 2009-09-29 Ver1.10 Start
    ELSIF (gv_warning_flag = cv_status_yes) THEN  -- �ڋq�R�t���x�����ݎ�
      ov_retcode := cv_status_warn;
-- Modify 2009-09-29 Ver1.10 End
    END IF;
--
    -- =====================================================
    --  �������擾�`�F�b�N (A-4)
    -- =====================================================
    chk_account_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  ���������׌����`�F�b�N (A-5)
    -- =====================================================
    chk_line_cnt_limit(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  �t�@�C���o�͏��� (A-6)
    -- =====================================================
    csv_file_output(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
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
    errbuf                 OUT     VARCHAR2,         -- �G���[�E���b�Z�[�W  #�Œ�#
    retcode                OUT     VARCHAR2,         -- �G���[�R�[�h        #�Œ�#
    iv_target_date         IN      VARCHAR2,         -- ����
    iv_customer_code10     IN      VARCHAR2,         -- �ڋq
    iv_customer_code20     IN      VARCHAR2,         -- �������p�ڋq
    iv_customer_code21     IN      VARCHAR2,         -- �����������p�ڋq
    iv_customer_code14     IN      VARCHAR2          -- ���|�Ǘ���ڋq
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
    lv_errbuf2      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   #############################
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
      ,ov_retcode => lv_retcode
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
       iv_target_date     -- ����
      ,iv_customer_code10 -- �ڋq
      ,iv_customer_code20 -- �������p�ڋq
      ,iv_customer_code21 -- �����������p�ڋq
      ,iv_customer_code14 -- ���|�Ǘ���ڋq
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- =====================================================
    --  �I������ (A-7)
    -- =====================================================
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
      -- ���[�U�[�G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
--
     --�P�s���s
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
      -- �V�X�e���G���[���b�Z�[�W�o��
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfr
                     ,iv_name         => cv_msg_xxcfr_00056
                    );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --�G���[���b�Z�[�W
      );
--
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --�G���[���b�Z�[�W
      );
    END IF;
--
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' -- �G���[���b�Z�[�W
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
--###########################  �Œ蕔 START   #####################################################
--
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
END XXCFR003A17C;
/
