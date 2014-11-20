CREATE OR REPLACE PACKAGE BODY XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(body)
 * Description      : �C�Z�g�[�������f�[�^�쐬
 * MD.050           : MD050_CFR_003_A17_�C�Z�g�[�������f�[�^�쐬
 * MD.070           : MD050_CFR_003_A17_�C�Z�g�[�������f�[�^�쐬
 * Version          : 1.00
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
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-23    1.00 SCS ���� �K��     �V�K�쐬
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
  cv_format_date_ymd  CONSTANT VARCHAR2(8)   := 'YY/MM/DD';                    -- ���t�t�H�[�}�b�g�i2���N�����X���b�V���t�j
--
  cv_max_date_value   CONSTANT VARCHAR2(10)  := '9999/12/31';                  -- �ő���t�l
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
  gn_line_cnt_limit     NUMBER;                                    -- ���������׌�������
  gn_org_id             NUMBER;                                    -- �g�DID
  gn_set_of_bks_id      NUMBER;                                    -- ��v����ID
--
  -- �ő���t
  gd_max_date           DATE DEFAULT TO_DATE(cv_max_date_value, cv_format_date_ymd);
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
    iv_bill_cust_code      IN      VARCHAR2,         -- ������ڋq�R�[�h
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
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log  -- ���O�o��
                                   ,iv_conc_param1  => iv_target_date    -- �R���J�����g�p�����[�^�P
                                   ,iv_conc_param2  => iv_bill_cust_code -- �R���J�����g�p�����[�^�Q
                                   ,ov_errbuf       => ov_errbuf         -- �G���[�E���b�Z�[�W
                                   ,ov_retcode      => ov_retcode        -- ���^�[���E�R�[�h
                                   ,ov_errmsg       => ov_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W 
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
  EXCEPTION
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
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-3)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- ����
    iv_bill_cust_code       IN   VARCHAR2,            -- ������ڋq�R�[�h
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
    CURSOR sel_no_account_data_cur
    IS
      SELECT
             xcot.col6 bill_cust_code
            ,xcot.col7 bill_cust_name
            ,xcot.col8 bill_location_name
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- �v��ID
        AND  xcot.col17      IS NULL
      GROUP BY xcot.col6,
               xcot.col7,
               xcot.col8
      ORDER BY xcot.col6;
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
                                     ,iv_token_value1 => l_sel_no_account_data_rec.bill_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     ,iv_token_value2 => l_sel_no_account_data_rec.bill_cust_name
                                     ,iv_token_name3  => cv_tkn_lc_name
                                     ,iv_token_value3 => l_sel_no_account_data_rec.bill_location_name)
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
    -- ���׌��������ڋq��񒊏o
    CURSOR line_cnt_limit_cur
    IS
      SELECT
             xcot.col6        bill_cust_code     -- ������ڋq�R�[�h
            ,xcot.col7        bill_cust_name     -- ������ڋq��
            ,xcot.col8        bill_location_name -- �S�����_��
            ,COUNT(xcot.col6) line_count         -- ���׌���
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- �v��ID
      HAVING count(xcot.col6) > gn_line_cnt_limit
      GROUP BY xcot.col6,
               xcot.col7,
               xcot.col8
      ORDER BY xcot.col6;
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
      -- ���׌��������ڋq��񒊏o
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
    iv_bill_cust_code      IN      VARCHAR2,         -- ������ڋq�R�[�h
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
      ,iv_bill_cust_code      -- ������ڋq�R�[�h
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
      ,iv_bill_cust_code      -- ������ڋq�R�[�h
      ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
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
    iv_bill_cust_code      IN      VARCHAR2          -- ������ڋq
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
       iv_target_date    -- ����
      ,iv_bill_cust_code -- ������ڋq�R�[�h
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
