CREATE OR REPLACE PACKAGE BODY XXCMM005A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A03C(body)
 * Description      : ���_�}�X�^IF�o�́iHHT�j
 * MD.050           : ���_�}�X�^IF�o�́iHHT�j MD050_CMM_005_A03
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_base_mst_if_data   �����Ώۃf�[�^���o(A-3)
 *  output_csv_data        ���o���o��(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/03    1.0   Masayuki.Sano    �V�K�쐬
 *  2009/02/26    1.1   Masayuki.Sano    �����e�X�g����s���Ή�
 *  2009/03/09    1.2   Yutaka.Kuboshima �t�@�C���o�͐�̃v���t�@�C���̕ύX
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM005A03C';                  -- �p�b�P�[�W��
  -- �� �A�v���P�[�V�����Z�k��
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30)  := 'XXCMM';                      -- �}�X�^
  cv_app_name_xxccp   CONSTANT VARCHAR2(30)  := 'XXCCP';                      -- ���ʁEIF
  -- �� �J�X�^���E�v���t�@�C���E�I�v�V����(XXCMM:���_�}�X�^�iHHT�j)
-- 2009/03/09 modify start by Yutaka.Kuboshima
--  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_005A03_OUT_FILE_DIR';  -- �A�g�pCSV�t�@�C���o�͐�
  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_HHT_OUT_DIR';          -- HHT(OUTBOUND)�A�g�pCSV�t�@�C���o�͐�
-- 2009/03/09 modify end by Yutaka.Kuboshima
  cv_pro_out_file_fil CONSTANT VARCHAR2(50) := 'XXCMM1_005A03_OUT_FILE_FIL';  -- �A�g�pCSV�t�@�C����
  -- �� ���b�Z�[�W�E�R�[�h
  cv_msg_00038        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00038';            -- ���̓p�����[�^���b�Z�[�W
  cv_msg_05132        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';            -- �t�@�C�����o�̓��b�Z�[�W
  cv_msg_00031        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00031';            -- ���Ԏw��G���[
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';            -- �v���t�@�C���擾�G���[
  cv_msg_00010        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';            -- CSV�t�@�C�����݃`�F�b�N
  cv_msg_00003        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';            -- �t�@�C���p�X�s���G���[
  cv_msg_00009        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';            -- CSV�f�[�^�o�̓G���[
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';            -- �Ώی������b�Z�[�W
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';            -- �����������b�Z�[�W
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';            -- �G���[�������b�Z�[�W
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';            -- ����I�����b�Z�[�W
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';            -- �G���[�I���S���[���o�b�N
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';            -- �Ώۃf�[�^����
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';            -- �V�X�e���G���[
-- 2009/02/26 ADD by M.Sano End
  -- �� �g�[�N��
  cv_tok_param        CONSTANT VARCHAR2(5)  := 'PARAM';
  cv_tok_value        CONSTANT VARCHAR2(5)  := 'VALUE';
  cv_tok_filename     CONSTANT VARCHAR2(10) := 'FILE_NAME';                   -- �t�@�C����
  cv_tok_ng_profile   CONSTANT VARCHAR2(10) := 'NG_PROFILE';
  cv_tok_ng_word      CONSTANT VARCHAR2(10) := 'NG_WORD';
  cv_tok_ng_data      CONSTANT VARCHAR2(10) := 'NG_DATA';
  cv_tok_count        CONSTANT VARCHAR2(10) := 'COUNT';
  -- �� �g�[�N���l
  cv_tval_out_file_dir CONSTANT VARCHAR2(50)  := '���_�}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�';
  cv_tval_out_file_fil CONSTANT VARCHAR2(50)  := '���_�}�X�^�iHHT�j�A�g�pCSV�t�@�C����';
  cv_tval_base_code    CONSTANT VARCHAR2(20)  := '���_�R�[�h'; 
  cv_tval_update_from  CONSTANT VARCHAR2(20)  := '�ŏI�X�V��(from)';
  cv_tval_update_to    CONSTANT VARCHAR2(20)  := '�ŏI�X�V��(to)  ';
  cv_tval_para_auto    CONSTANT VARCHAR2(10)  := '�����擾�l';          -- �ݶ��ĥ���Ұ���_����
  cv_tval_part         CONSTANT VARCHAR2(3)   := ' : ';
  cv_tval_backnet_st   CONSTANT VARCHAR2(1)   := '[';
  cv_tval_backnet_en   CONSTANT VARCHAR2(1)   := ']';
  -- �� ���̑�
  cv_date_format       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_datetime_format   CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
-- 
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���_�}�X�^IF�o�́iHHT�j���C�A�E�g
  TYPE output_data_rtype IS RECORD
  (
     account_number           hz_cust_accounts.account_number%TYPE        -- ���_�R�[�h
    ,account_name             hz_cust_accounts.account_name%TYPE          -- ����
    ,address                  VARCHAR2(60)                               -- �Z��
    ,address_lines_phonetic   hz_locations.address_lines_phonetic%TYPE    -- �d�b�ԍ�
    ,attribute6               hz_cust_accounts.attribute6%TYPE            -- ���_�ԑq�֋敪
    ,attribute5               hz_cust_accounts.attribute5%TYPE            -- �o�׌��Ǘ��敪
    ,stop_approval_date       xxcmm_cust_accounts.stop_approval_date%TYPE -- ������
    ,hza_last_update_date     hz_cust_accounts.last_update_date%TYPE      -- �ŏI�X�V��
    ,xca_last_update_date     hz_cust_accounts.last_update_date%TYPE      -- �ŏI�X�V��
    ,hlo_last_update_date     hz_locations.last_update_date%TYPE          -- �ŏI�X�V��
  );
--
  -- ���_�}�X�^IF�o�́iHHT�j���C�A�E�g �e�[�u���^�C�v
  TYPE xxcmm005a03c_ttype IS TABLE OF output_data_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date       DATE;             -- �Ɩ����t
  -- ���̓p�����[�^
  gv_update_from        VARCHAR2(50);     -- �ŏI�X�V��(FROM)
  gv_update_to          VARCHAR2(50);     -- �ŏI�X�V��(TO)
  -- �����p
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;  -- ���_�}�X�^(HHT)�A�g�pCSV�t�@�C���o�͐�
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;  -- ���_�}�X�^(HHT)�A�g�pCSV�t�@�C����
  gf_file_handler       UTL_FILE.FILE_TYPE;                                   -- CSV�t�@�C���o�͗p�n���h��
  gt_csv_output_tab     xxcmm005a03c_ttype;                                   -- ���_�}�X�^IF�o�̓f�[�^
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lb_file_exists   BOOLEAN;        -- �t�@�C�����ݔ��f
    ln_file_length   NUMBER(30);     -- �t�@�C���̕�����
    lbi_block_size   BINARY_INTEGER; -- �u���b�N�T�C�Y
    lv_update_from   VARCHAR2(10);   -- �`�F�b�N�p�ŏI�X�V��(From)
    lv_update_to     VARCHAR2(10);   -- �`�F�b�N�p�ŏI�X�V��(To)
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
    --�P�D�v���t�@�C���̎擾���s���܂��B
    --==============================================================
    -- XXCMM: ���_�}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐���擾
    gv_csv_file_dir    := FND_PROFILE.VALUE(cv_pro_out_file_dir);
    -- XXCMM: ���_�}�X�^�iHHT�j�A�g�pCSV�t�@�C���o�͐�̎擾���e�`�F�b�N
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tval_out_file_dir -- �l      :CSV�t�@�C���o�͐�
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCMM: ���_�}�X�^�iHHT�j�A�g�pCSV�t�@�C�������擾
    gv_csv_file_name    := FND_PROFILE.VALUE(cv_pro_out_file_fil);
    -- XXCMM: ���_�}�X�^�iHHT�j�A�g�pCSV�t�@�C�����̎擾���e�`�F�b�N
    IF ( gv_csv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00002         -- �G���[  :�v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tok_ng_profile    -- �g�[�N��:NG_PROFILE
                     ,iv_token_value1 => cv_tval_out_file_fil -- �l      :CSV�t�@�C����
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�Q�DCSV�t�@�C�����݃`�F�b�N���s���܂��B
    --==============================================================
    -- �t�@�C�������擾
    UTL_FILE.FGETATTR(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- �t�@�C���d���`�F�b�N(�t�@�C�����݂̗L��)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00010         -- �G���[:CSV�t�@�C�����݃`�F�b�N
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�R�D�Ɩ����t���擾���܂��B
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    --==============================================================
    --�S�D�p�����[�^�`�F�b�N���s���܂��B
    --==============================================================
    -- "�ŏI�X�V��(From) > �ŏI�X�V��(To)"�̏ꍇ�A�p�����[�^�G���[
    lv_update_from := NVL(gv_update_from, TO_CHAR(gd_process_date, cv_date_format));
    lv_update_to   := NVL(gv_update_to,   TO_CHAR(gd_process_date, cv_date_format));
    IF ( lv_update_from > lv_update_to ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- �}�X�^
                     ,iv_name         => cv_msg_00031         -- �G���[:���Ԏw��G���[
                   );
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_base_master_if_data
   * Description      : �����Ώۃf�[�^���o(A-3)
   ***********************************************************************************/
  PROCEDURE get_base_mst_if_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_mst_if_data'; -- �v���O������
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
    cv_time_min    VARCHAR2(10) := ' 00:00:00';
    cv_time_max    VARCHAR2(10) := ' 23:59:59';
    
    -- *** ���[�J���ϐ� ***
    ld_update_from DATE;
    ld_update_to   DATE;
--
    -- *** ���[�J���J�[�\��***
    CURSOR base_mst_if_cur(
       id_last_update_date_from DATE
      ,id_last_update_date_to   DATE)
    IS
      SELECT hza.account_number           account_number          -- �ڋq�R�[�h
            ,hza.account_name             account_name            -- ����(�A�J�E���g��)
-- 2009/02/26 UPD by M.Sano Start
--            ,hlo.state || hlo.city || 
--             hlo.address1 || hlo.address2 address                 -- �Z��
            ,SUBSTRB(hlo.state || hlo.city || hlo.address1 || hlo.address2, 1, 60)
                                          address                 -- �Z��
-- 2009/02/26 UPD by M.Sano End
            ,hlo.address_lines_phonetic   address_lines_phonetic  -- �d�b�ԍ�
            ,hza.attribute6               attribute6              -- �q�֑Ώۉۃt���O
            ,hza.attribute5               attribute5              -- �o�׌��Ǘ��敪
            ,xca.stop_approval_date       stop_approval_date      -- ���~���ϓ�
            ,hza.last_update_date         hza_last_update_date    -- �ŏI�X�V��
            ,xca.last_update_date         xca_last_update_date    -- �ŏI�X�V��
            ,hlo.last_update_date         hlo_last_update_date    -- �ŏI�X�V��
      FROM   hz_cust_accounts     hza
            ,xxcmm_cust_accounts  xca
            ,hz_party_sites       hps
            ,hz_locations         hlo
      WHERE  xca.customer_id = hza.cust_account_id
      AND    hza.party_id    = hps.party_id
      AND    hlo.location_id = hps.location_id
      AND    hza.customer_class_code  = '1'
      AND    hps.status      = 'A'
      AND    (  ( hza.last_update_date BETWEEN id_last_update_date_from AND id_last_update_date_to )
             OR ( xca.last_update_date BETWEEN id_last_update_date_from AND id_last_update_date_to )
             OR ( hlo.last_update_date BETWEEN id_last_update_date_from AND id_last_update_date_to ) )

      ORDER BY
             hza.account_number ASC
      ;
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
    -- ���������ɑ}������������쐬����B
    --==============================================================
    -- �ŏI�X�V��(From)���쐬(YYYY/MM/DD 00:00:00)
    IF ( gv_update_from IS NULL ) THEN
      ld_update_from := TO_DATE(TO_CHAR(gd_process_date, cv_date_format) || cv_time_min, cv_datetime_format);
    ELSE
      ld_update_from := TO_DATE(gv_update_from || cv_time_min, cv_datetime_format);
    END IF;
    -- �ŏI�X�V��(To)���쐬(YYYY/MM/DD 23:59:59)
    IF ( gv_update_to IS NULL ) THEN
      ld_update_to := TO_DATE(TO_CHAR(gd_process_date, cv_date_format) || cv_time_max, cv_datetime_format);
    ELSE
      ld_update_to := TO_DATE(gv_update_to || cv_time_max, cv_datetime_format);
    END IF;
--
    --==============================================================
    -- ���_�}�X�^IF�����擾���A���ʂ�z��Ɋi�[���܂��B
    --==============================================================
    -- CSV�o�̓f�[�^�擾�J�[�\���̃I�[�v��
    OPEN base_mst_if_cur(ld_update_from, ld_update_to);
    -- CSV�o�̓f�[�^�擾�̎擾
    <<base_mat_if_loop>>
    LOOP
      FETCH base_mst_if_cur BULK COLLECT INTO gt_csv_output_tab;
      EXIT WHEN base_mst_if_cur%NOTFOUND;
    END LOOP base_mat_if_loop;
    -- CSV�o�̓f�[�^�擾�J�[�\���̃N���[�Y
    CLOSE base_mst_if_cur;
    -- �������擾
    gn_target_cnt := gt_csv_output_tab.COUNT;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_base_mst_if_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : ���o���o��(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_data'; -- �v���O������
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
    cv_sep          CONSTANT VARCHAR2(1)   := ',';  -- ��؂蕶��
    cv_dqu          CONSTANT VARCHAR2(1)   := '"';  -- �_�u���N�H�[�e�[�V����
    -- *** ���[�J���ϐ� ***
    ln_idx          NUMBER;         -- Loop���̃J�E���g�ϐ�
    lv_output_val   VARCHAR2(100);  -- �o�͓��e(����)
    lv_output_line  VARCHAR2(240);  -- �o�͓��e(�s)
    ld_max_date     DATE;           -- �擾�����ŏI�X�V���̍ő�l
    lv_base_code    hz_cust_accounts.account_number%TYPE;
                                    -- ���_�R�[�h
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
    -- �擾�������_�}�X�^IF�̏����ACSV�t�@�C���֏o��
    --==============================================================
    <<output_csv_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      BEGIN
        -- �� �����ݒ�
        lv_output_line := '';
        lv_base_code   := SUBSTRB(gt_csv_output_tab(ln_idx).account_number,1,4);
--
        -- �� �o�̓f�[�^�쐬
        -- ���_�R�[�h
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).account_number,1,4);
        lv_output_line := cv_dqu || lv_output_val || cv_dqu;
        -- ����
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).account_name,1,8);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- �Z��
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).address,1,60);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- �d�b�ԍ�
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).address_lines_phonetic,1,15);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- ���_�ԑq�֋敪
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).attribute6,1,1);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- �o�׌��Ǘ��敪
        lv_output_val  := SUBSTRB(gt_csv_output_tab(ln_idx).attribute5,1,1);
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- ������
        lv_output_val  := TO_CHAR(gt_csv_output_tab(ln_idx).stop_approval_date, 'YYYYMMDD');
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
        -- �擾�����ŏI�X�V������ő�̂��̂��Z�o
        ld_max_date := gt_csv_output_tab(ln_idx).hza_last_update_date;
        IF ( ld_max_date < gt_csv_output_tab(ln_idx).xca_last_update_date ) THEN
          ld_max_date := gt_csv_output_tab(ln_idx).xca_last_update_date;
        END IF;
        IF ( ld_max_date < gt_csv_output_tab(ln_idx).hlo_last_update_date ) THEN
          ld_max_date := gt_csv_output_tab(ln_idx).hlo_last_update_date;
        END IF;
        -- �Z�o�����ŏI�X�V��
        lv_output_val  := TO_CHAR(ld_max_date, 'YYYY/MM/DD HH:MI:SS');
        lv_output_line := lv_output_line || cv_sep || cv_dqu || lv_output_val || cv_dqu;
--
      -- �� �o�̓f�[�^��csv�t�@�C���ɏo�͂���B
        UTL_FILE.PUT_LINE(gf_file_handler, lv_output_line);
--
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm    -- �}�X�^
                         ,iv_name         => cv_msg_00009         -- �G���[  :CSV�f�[�^�o�̓G���[
                         ,iv_token_name1  => cv_tok_ng_word       -- �g�[�N��:NG_WORD
                         ,iv_token_value1 => cv_tval_base_code    -- �l      :���_�R�[�h
                         ,iv_token_name2  => cv_tok_ng_data       -- �g�[�N��:NG_DATA
                         ,iv_token_value2 => lv_base_code         -- �l      :���_�R�[�h(�f�[�^)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      --�����������X�V����B
      gn_normal_cnt := gn_normal_cnt + 1;
   END LOOP output_csv_loop;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- �t�@�C���I�[�v�����[�h(�������݃��[�h)
--
    -- *** ���[�J���ϐ� ***
    lv_tok_value        VARCHAR2(100);  -- �g�[�N���Ɋi�[����l
    lv_out_msg          VARCHAR2(5000); -- �o�͗p
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
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- A-1.��������
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- [���̓p�����[�^���o��(�ŏI�X�V��(From))]
    -- �E�ŏI�X�V��(From)��NULL�ȊO �� �ŏI�X�V���iFrom�j �F [YYYY/MM/DD]
    -- �E�ŏI�X�V��(From)��NULL     �� �ŏI�X�V���iFrom�j �F [] : �����擾[YYYY/MM/DD]
    lv_tok_value := cv_tval_backnet_st || gv_update_from || cv_tval_backnet_en;
    IF ( gv_update_from IS NULL AND gd_process_date IS NOT NULL ) THEN
      lv_tok_value := lv_tok_value || cv_tval_part || cv_tval_para_auto ||
                       cv_tval_backnet_st || TO_CHAR(gd_process_date, cv_date_format) || cv_tval_backnet_en;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm
                    ,iv_name         => cv_msg_00038
                    ,iv_token_name1  => cv_tok_param
                    ,iv_token_value1 => cv_tval_update_from
                    ,iv_token_name2  => cv_tok_value
                    ,iv_token_value2 => lv_tok_value
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- [���̓p�����[�^���o��(�ŏI�X�V��(To))]
    -- �E�ŏI�X�V��(To)��NULL�ȊO �� �ŏI�X�V���iTo�j �F [YYYY/MM/DD]
    -- �E�ŏI�X�V��(To)��NULL     �� �ŏI�X�V���iTo�j �F [] : �����擾[YYYY/MM/DD]
    lv_tok_value := cv_tval_backnet_st || gv_update_to || cv_tval_backnet_en;
    IF ( gv_update_to IS NULL AND gd_process_date IS NOT NULL ) THEN
      lv_tok_value := lv_tok_value || cv_tval_part || cv_tval_para_auto ||
                       cv_tval_backnet_st || TO_CHAR(gd_process_date, cv_date_format) || cv_tval_backnet_en;
    END IF;
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxcmm
                    ,iv_name         => cv_msg_00038
                    ,iv_token_name1  => cv_tok_param
                    ,iv_token_value1 => cv_tval_update_to
                    ,iv_token_name2  => cv_tok_value
                    ,iv_token_value2 => lv_tok_value
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- [�t�@�C�����̏o��]
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_05132
                    ,iv_token_name1  => cv_tok_filename
                    ,iv_token_value1 => gv_csv_file_name
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- [���������̎��s���ʃ`�F�b�N]
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2�D�t�@�C���I�[�v������(�������[�h)
    -- ===============================================
    BEGIN
      -- �t�@�C�����J��
      gf_file_handler := UTL_FILE.FOPEN(
                            location   => gv_csv_file_dir     -- �o�͐�
                           ,filename   => gv_csv_file_name    -- �t�@�C����
                           ,open_mode  => cv_csv_mode_w       -- �t�@�C���I�[�v�����[�h
                        );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        -- ���b�Z�[�W���擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm  -- �}�X�^
                       ,iv_name         => cv_msg_00003       -- �G���[:�t�@�C���p�X�s���G���[
                     );
        lv_errbuf := lv_errmsg;
        -- ��O���X���[
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================================
    -- A-3�D�����Ώۃf�[�^���o
    -- ===============================================
    get_base_mst_if_data(
       ov_errbuf           => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-4�D���o���o��
    -- ===============================================
    output_csv_data(
       ov_errbuf           => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- [�������ʃ`�F�b�N]
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    -- [����������0���̏ꍇ�A�Ώۃf�[�^�������b�Z�[�W�o��]
    IF ( gn_target_cnt = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm    -- �}�X�^
                       ,iv_name         => cv_msg_00001         -- �G���[  :CSV�f�[�^�o�̓G���[
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
    END IF;
--
    -- ===============================================
    -- A-5�D�I������
    -- ===============================================
    UTL_FILE.FCLOSE(gf_file_handler);
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- �}�X�^
                     ,iv_name         => cv_msg_91003         -- �G���[:�V�X�e���G���[
                   );
-- 2009/02/26 ADD by M.Sano End
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
    errbuf                OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_update_from        IN     VARCHAR2,        --   1.�ŏI�X�V��(FROM)
    iv_update_to          IN     VARCHAR2)        --   2.�ŏI�X�V��(TO)
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg           VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code     VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
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
    -- ���̓p�����[�^�̎擾
    -- ===============================================
    gv_update_from := iv_update_from;
    gv_update_to   := iv_update_to;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf           => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode          => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg           => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �t�@�C���������Ă��Ȃ��ꍇ�A�t�@�C�������B
    IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
      UTL_FILE.FCLOSE(gf_file_handler);
    END IF;
--
    -- ===============================================
    -- �G���[���b�Z�[�W�̏o��
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- �����̏o��
    -- ===============================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================================
    --�I�����b�Z�[�W
    -- ===============================================
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
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
END XXCMM005A03C;
/
