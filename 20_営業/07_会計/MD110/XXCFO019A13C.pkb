CREATE OR REPLACE PACKAGE BODY XXCFO019A13C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCFO019A13C(body)
 * Description      : �d�q���됿���̏��n�V�X�e���A�g
 * MD.050           : MD050_CFO_019_A13_�d�q���됿���̏��n�V�X�e���A�g
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    ��������(A-1)
 *  get_invoice             �Ώۃf�[�^�擾(A-2)
 *  chk_item                ���ڃ`�F�b�N����(A-3)
 *  out_csv                 �b�r�u�o�͏���(A-4)
 *  submain                 ���C�������v���V�[�W��
 *  main                    �R���J�����g���s�t�@�C���o�^�v���V�[�W���E�I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021-12-23    1.0   K.Tomie         �V�K�쐬 (E_�{�ғ�_17770�Ή�)
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
  gv_out_msg         VARCHAR2(2000);
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
  gn_target_cnt      NUMBER;                    -- �Ώی���
  gn_normal_cnt      NUMBER;                    -- ���팏��
  gn_error_cnt       NUMBER;                    -- �G���[����
  gn_warn_cnt        NUMBER;                    -- �X�L�b�v����
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A13C'; -- �p�b�P�[�W��
  --�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp              CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --�v���t�@�C��
  cv_data_filepath            CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';     -- �d�q����f�[�^�t�@�C���i�[�p�X
  cv_filename                 CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_INV_DATA_FILENAME'; -- �d�q���됿���f�[�^�t�@�C����
  cv_prf_org_id               CONSTANT VARCHAR2(50)  := 'ORG_ID';                                 -- MO:�c�ƒP��
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                       -- GL��v����ID
  --���b�Z�[�W
  cv_msg_ccp_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-00001';   --�x���������b�Z�[�W
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --�Q�ƃ^�C�v�擾�G���[
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --�擾�Ώۃf�[�^�����G���[���b�Z�[�W
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --�t�@�C�����݃G���[
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --�t�@�C���������݃G���[
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  --�g�[�N���R�[�h
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ���b�N�A�b�v�^�C�v��
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- �v���t�@�C����
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- �f�B���N�g����
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- �t�@�C����
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- �e�[�u����
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- �G���[���
  --���b�Z�[�W�o�͗p������(�g�[�N��)
  cv_msgtkn_cfo_11178         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11178'; -- �������
  cv_msgtkn_cfo_11179         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11179'; -- �ꊇ������ID
  cv_msgtkn_cfo_11180         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11180'; -- �ꊇ����������No
  --�Q�ƃ^�C�v
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --�d�q���돈�����s��
  cv_lookup_item_chk_invoice  CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_ITEM_CHK_ARINV'; --�d�q���덀�ڃ`�F�b�N�i�����j
  cv_lookup_syohizei_kbn      CONSTANT VARCHAR2(30)  := 'XXCMM_CSUT_SYOHIZEI_KBN';        --����ŋ敪
  cv_lookup_vd_customer_kbn   CONSTANT VARCHAR2(30)  := 'XXCFO1_VD_CUSTOMER_KBN';         --VD�ڋq�敪
  cv_lookup_invoice_kbn       CONSTANT VARCHAR2(30)  := 'XXCFO1_INVOICE_KBN';             --�����敪
  cv_lookup_delivery_slip     CONSTANT VARCHAR2(30)  := 'XXCOS1_DELIVERY_SLIP_CLASS';     --����ԕi�敪
  cv_lookup_chain_code        CONSTANT VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';               --�[�i��`�F�[���R�[�h
  --�l�Z�b�g
  cv_flex_value_department    CONSTANT VARCHAR2(30)  := 'XX03_DEPARTMENT';                  --�������_�R�[�h
  --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format_ymdshms      CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';     --�b�r�u�o�̓t�H�[�}�b�g
  --�b�r�u
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- �J���}
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- ��������
  --��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --����
  cv_1                        CONSTANT VARCHAR2(1)   := '1';   --'1'
  cv_2                        CONSTANT VARCHAR2(1)   := '2';   --'2'
  cv_18                       CONSTANT VARCHAR2(2)   := '18';  --'18'
  --�Œ�l
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- �X���b�V��
  --�t�@�C���o��
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
  cn_max_linesize             CONSTANT BINARY_INTEGER := 32767;               -- �t�@�C���T�C�Y
  --���ڑ���
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   �i�`�F�b�N�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)   INDEX BY PLS_INTEGER;
  gt_data_tab                  g_layout_ttype;              --�o�̓f�[�^���
  --���ڃ`�F�b�N
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.attribute1%type  
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute2%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute3%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute4%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype      IS TABLE OF fnd_lookup_values.attribute6%type
                                            INDEX BY PLS_INTEGER;
  --
  gt_item_name                  g_item_name_ttype;          -- ���ږ���
  gt_item_len                   g_item_len_ttype;           -- ���ڂ̒���
  gt_item_decimal               g_item_decimal_ttype;       -- ���ځi�����_�ȉ��̒����j
  gt_item_nullflg               g_item_nullflg_ttype;       -- �K�{���ڃt���O
  gt_item_attr                  g_item_attr_ttype;          -- ���ڑ���
  gt_item_cutflg                g_item_cutflg_ttype;        -- �؎̂ăt���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date             DATE;                                -- �Ɩ����t
  gv_coop_date                VARCHAR2(14);                        -- �A�g����
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;   -- �d�q���돈�����s����
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;   -- �����Ώێ���
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --�t�@�C���p�X
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --�d�q�������f�[�^�ǉ��t�@�C��
  gn_org_id                   NUMBER;                       --�g�DID(�c�ƒP��)
  gn_set_of_bks_id            NUMBER;                       --GL��v����ID
  gn_item_cnt                 NUMBER;             --�`�F�b�N���ڌ���
  gv_0file_flg                VARCHAR2(1) DEFAULT cv_flag_n; --0Byte�t�@�C���㏑���t���O
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  global_lock_expt  EXCEPTION; -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_cutoff_date IN  VARCHAR2, -- 1.����
    iv_file_name   IN  VARCHAR2, -- 2.�t�@�C����
    ov_errbuf      OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_profile_name           fnd_profile_options.profile_option_name%TYPE;
    lv_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_msg          VARCHAR2(3000);
    lv_full_name    VARCHAR2(200) DEFAULT NULL;    --�f�B���N�g�����{�t�@�C�����A���l
    lt_dir_path     all_directories.directory_path%TYPE DEFAULT NULL; --�f�B���N�g���p�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             meaning    --���ږ���
              , flv.attribute1          attribute1 --���ڂ̒���
              , flv.attribute2          attribute2 --���ڂ̒����i�����_�ȉ��j
              , flv.attribute3          attribute3 --�K�{�t���O
              , flv.attribute4          attribute4 --����
              , flv.attribute5          attribute5 --�؎̂ăt���O
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_invoice --�d�q���덀�ڃ`�F�b�N�i�����j
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        = cv_flag_y
      AND       flv.language            = cv_lang
      ORDER BY  flv.lookup_code
      ;
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
    -- �p�����[�^�o��
    --==============================================================
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out                                 -- ���b�Z�[�W�o��
      ,iv_conc_param1  => iv_cutoff_date                                   -- ����
      ,iv_conc_param2  => iv_file_name                                     -- �t�@�C����      
      ,ov_errbuf       => lv_errbuf                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                                       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);                                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log                                -- ���O�o��
      ,iv_conc_param1  => iv_cutoff_date                                  -- ����
      ,iv_conc_param2  => iv_file_name                                    -- �t�@�C����
      ,ov_errbuf       => lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);                                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00015 -- �Ɩ����t�擾�G���[
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �A�g�����p���t�擾
    --==============================================================
    gv_coop_date := TO_CHAR(SYSDATE, cv_date_format_ymdhms);
--
    --==================================
    -- �N�C�b�N�R�[�h(���ڃ`�F�b�N�����p)���̎擾
    --==================================
    OPEN get_chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- �Ώی����̃Z�b�g
    gn_item_cnt := gt_item_name.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
    --
    IF ( gn_item_cnt = 0 ) THEN
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_item_chk_invoice -- 'XXCFO1_ELECTRIC_ITEM_CHK_INVOICE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- �N�C�b�N�R�[�h
    --==================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    flv.attribute1 attribute1-- �d�q���돈�����s����
      INTO      gt_electric_exec_days
      FROM      fnd_lookup_values  flv
      WHERE     flv.lookup_type    = cv_lookup_book_date
      AND       flv.lookup_code    = cv_pkg_name
      AND       gd_process_date    BETWEEN NVL(flv.start_date_active, gd_process_date)
                                   AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag   = cv_flag_y
      AND       flv.language       = cv_lang
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- �Q�ƃ^�C�v�擾�G���[
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_book_date     -- 'XXCFO1_ELECTRIC_BOOK_DATE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    --�t�@�C���i�[�p�X
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_data_filepath -- 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --�t�@�C����
    IF ( iv_file_name IS NOT NULL ) THEN
      --�p�����[�^�u�t�@�C�����v�����͍ς̏ꍇ�́A���͒l���t�@�C�����Ƃ��Ďg�p
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL ) THEN
      --�p�����[�^�u�t�@�C�����v�������͂̏ꍇ�́A�v���t�@�C������t�@�C�������擾
      gv_file_name  := FND_PROFILE.VALUE( cv_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- �v���t�@�C�����擾�G���[
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_filename  -- 'XXCFO1_ELECTRIC_BOOK_INV_DATA_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
    
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    gn_org_id := apps.FND_PROFILE.VALUE( cv_prf_org_id );
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001
                                                    ,cv_tkn_prof_name
                                                    ,cv_prf_org_id
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;

    -- �v���t�@�C���̎擾(GL��v����ID)
    gn_set_of_bks_id := TO_NUMBER(apps.FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00001  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof_name       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id )  -- GL��v����ID
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �f�B���N�g���p�X�擾
    --==================================
    BEGIN
      SELECT    ad.directory_path directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- �f�B���N�g���p�X�擾�G���[
                                                    ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                    ,gt_file_path     -- �t�@�C���i�[�p�X
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    --==================================
    -- IF�t�@�C�����o��
    --==================================
    --�擾�����f�B���N�g���p�X�̖�����'/'(�X���b�V��)�����݂���ꍇ�A
    --�f�B���N�g���ƃt�@�C�����̊Ԃ�'/'�A���͍s�킸�Ƀt�@�C�������o�͂���
    IF  SUBSTRB(lt_dir_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  lt_dir_path || gv_file_name;
    ELSE
      lv_full_name :=  lt_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                               ,cv_msg_cfo_00002 -- �t�@�C�����o�̓��b�Z�[�W
                                               ,cv_tkn_file_name -- 'FILE_NAME'
                                               ,lv_full_name     -- �i�[�p�X�ƃt�@�C�����̘A������
                                              )
                      ,1
                      ,5000);
    -- �t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- ����t�@�C�����݃`�F�b�N
    --==================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- ����t�@�C������
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gt_file_path
                       ,filename     => gv_file_name
                       ,open_mode    => cv_open_mode_w
                       ,max_linesize => cn_max_linesize
                                   );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_msgcode            OUT VARCHAR2,   --   ���b�Z�[�W�R�[�h
    ov_errbuf             OUT VARCHAR2,   --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode            OUT VARCHAR2,   --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg             OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_item'; -- �v���O������
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
    lv_invoice_id_name         VARCHAR2(12);                    --�ꊇ������ID���b�Z�[�W�o�͗p
    lv_invoice_detail_num_name VARCHAR2(16);                    --�ꊇ����������No���b�Z�[�W�o�͗p
    lv_invoice_id              VARCHAR2(500);                    --�ꊇ������ID�̒l���b�Z�[�W�o�͗p(������)
    lv_invoice_detail_num      VARCHAR2(500);                    --�ꊇ����������No�̒l���b�Z�[�W�o�͗p(������)
    lv_data_mess               VARCHAR2(500);                   --���ڂ̒l���b�Z�[�W�o�͗p(������)
    -- ===============================
    -- ���[�J����`��O
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    ov_msgcode := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- ���ڌ��`�F�b�N
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      --�ύX�O�̒l���i�[
      lv_invoice_id := gt_data_tab(1);
      lv_invoice_detail_num := gt_data_tab(42);
      lv_data_mess := gt_data_tab(ln_cnt);
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --���ږ���
        , iv_item_value                 =>        gt_data_tab(ln_cnt)               --�ύX�O�̒l
        , in_item_len                   =>        gt_item_len(ln_cnt)               --���ڂ̒���
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --�K�{�t���O
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --���ڑ���
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --�؎̂ăt���O
        , ov_item_value                 =>        gt_data_tab(ln_cnt)               --���ڂ̒l
        , ov_errbuf                     =>        lv_errbuf                         --�G���[���b�Z�[�W
        , ov_retcode                    =>        lv_retcode                        --���^�[���R�[�h
        , ov_errmsg                     =>        lv_errmsg                         --���[�U�[�E�G���[���b�Z�[�W
        );
      IF ( lv_retcode = cv_status_warn ) THEN
        -- ���b�Z�[�W�g�[�N���擾
        lv_invoice_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                        ,cv_msgtkn_cfo_11179);         -- �ꊇ������ID
        --
        lv_invoice_detail_num_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                          ,cv_msgtkn_cfo_11180); -- �ꊇ����������No
        IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
          --�������߃G���[�̏ꍇ�A���b�Z�[�W���o��
          lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo     -- 'XXCFO'
                                      ,cv_msg_cfo_10011   -- �������߃X�L�b�v���b�Z�[�W
                                      ,cv_tkn_key_data    -- �g�[�N��'KEY_DATA'
                                      ,lv_invoice_id_name || cv_msg_part || lv_invoice_id  || ' ' || lv_invoice_detail_num_name || cv_msg_part || lv_invoice_detail_num
                                         || ' ' || gt_item_name(ln_cnt) || cv_msg_part || lv_data_mess--�ꊇ������ID,�ꊇ����������No,�Ώۍ���
                                      )
                                     ,1
                                     ,5000);
        ELSE
          --�^���`�F�b�N�ɂāA�x�����e���������߈ȊO�̏ꍇ�A�߂胁�b�Z�[�W�Ɉꊇ������ID,�ꊇ����������No,,�Ώۍ��ڂ�ǉ��o��
          lv_errmsg := lv_errmsg || ' ' || lv_invoice_id_name || cv_msg_part || lv_invoice_id  || ' ' || lv_invoice_detail_num_name || cv_msg_part || lv_invoice_detail_num
                         || ' ' || gt_item_name(ln_cnt) || cv_msg_part || lv_data_mess;--�ꊇ������ID,�ꊇ����������No,�Ώۍ���
        END IF;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        --
        ov_retcode          := lv_retcode;
        ov_msgcode          := lv_errbuf;        --�߂胁�b�Z�[�W�R�[�h
        ov_errmsg           := lv_errmsg;        --�߂胁�b�Z�[�W
      ELSIF ( lv_retcode = cv_status_error ) THEN
        ov_errmsg   := lv_errmsg;
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP;
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : �b�r�u�o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- �v���O������
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
    lv_delimit                VARCHAR2(1);
    lv_file_data              VARCHAR2(30000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
--
    --�f�[�^�ҏW
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), cv_quot, ' '), cv_delimit, ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --�A�g����
    lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(90);
    --
    -- ====================================================
    -- �t�@�C����������
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,lv_file_data
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfo
                                ,cv_msg_cfo_00030)
                              ,1
                              ,5000
                              );
        --
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END;
    --���������J�E���g
    gn_normal_cnt := gn_normal_cnt + 1;
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
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : get_invoice
   * Description      : �Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_invoice(
    iv_cutoff_date IN  VARCHAR2, --   ����
    ov_errbuf      OUT VARCHAR2, --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode     OUT VARCHAR2, --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg      OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_invoice'; -- �v���O������
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
    lv_msgcode                 VARCHAR2(5000);                  -- A-4�̖߂胁�b�Z�[�W�R�[�h(�^���`�F�b�N)
    ld_cutoff_date             DATE;                            --�����Ώے���
    lv_invoice_info_name       VARCHAR2(12);                    --������񃁃b�Z�[�W�o�͗p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    CURSOR get_invoice_fixed_cur
    IS
    SELECT /*+ LEADING(xih) */
           xih.invoice_id                      AS  invoice_id                           --�ꊇ������ID
          ,xih.set_of_books_id                 AS  set_of_books_id                      --��v����ID
          ,xih.cutoff_date                     AS  cutoff_date                          --����
          ,xih.term_name                       AS  term_name                            --�x������
          ,xih.term_id                         AS  term_id                              --�x������ID
          ,xih.due_months_forword              AS  due_months_forword                   --�T�C�g����
          ,xih.month_remit                     AS  month_remit                          --����
          ,xih.payment_date                    AS  payment_date                         --�x����
          ,xih.tax_type                        AS  tax_type                             --����ŋ敪
          ,flv1.meaning                        AS  tax_div_name                         --����ŋ敪��
          ,xih.tax_gap_trx_id                  AS  tax_gap_trx_id                       --�ō��z���ID
          ,xih.tax_gap_amount                  AS  tax_gap_amount                       --�ō��z
          ,xih.inv_amount_no_tax               AS  inv_amount_no_tax                    --�Ŕ��������z���v
          ,xih.tax_amount_sum                  AS  tax_amount_sum                       --�Ŋz���v
          ,xih.inv_amount_includ_tax           AS  inv_amount_includ_tax                --�ō��������z���v
          ,xih.itoen_name                      AS  itoen_name                           --����於
          ,xih.postal_code                     AS  postal_code                          --���t��X�֔ԍ�
          ,xih.send_address1                   AS  send_address1                        --���t��Z��1
          ,xih.send_address2                   AS  send_address2                        --���t��Z��2
          ,xih.send_address3                   AS  send_address3                        --���t��Z��3
          ,xih.send_to_name                    AS  send_to_name                         --���t�於
          ,xih.inv_creation_date               AS  inv_creation_date                    --�쐬��
          ,xih.object_month                    AS  object_month                         --�Ώ۔N��
          ,xih.object_date_from                AS  object_date_from                     --�Ώۊ��ԁi���j
          ,xih.object_date_to                  AS  object_date_to                       --�Ώۊ��ԁi���j
          ,xih.vender_code                     AS  vender_code                          --�d����R�[�h
          ,xih.receipt_location_code           AS  receipt_location_code                --�������_�R�[�h
          ,ffv1.base_name                      AS  base_name                            --�������_��
          ,xih.bill_location_code              AS  bill_location_code                   --�������_�R�[�h
          ,xih.bill_location_name              AS  bill_location_name                   --�������_��
          ,xih.bill_cust_code                  AS  bill_cust_code                       --������ڋq�R�[�h
          ,xih.bill_cust_name                  AS  bill_cust_name                       --������ڋq��
          ,xih.bill_cust_kana_name             AS  bill_cust_kana_name                  --������ڋq�J�i��
          ,xih.bill_cust_account_id            AS  bill_cust_account_id                 --������ڋqID
          ,xih.bill_cust_acct_site_id          AS  bill_cust_acct_site_id               --������ڋq���ݒnID
          ,xih.bill_shop_code                  AS  bill_shop_code                       --������X�܃R�[�h
          ,xih.bill_shop_name                  AS  bill_shop_name                       --������X��
          ,xih.credit_receiv_code2             AS  credit_receiv_code2                  --���|�R�[�h2�i���Ə��j
          ,xih.credit_receiv_name2             AS  credit_receiv_name2                  --���|�R�[�h2�i���Ə��j����
          ,xih.credit_receiv_code3             AS  credit_receiv_code3                  --���|�R�[�h3�i���̑��j
          ,xih.credit_receiv_name3             AS  credit_receiv_name3                  --���|�R�[�h3�i���̑��j����
          ,xil.invoice_detail_num              AS  invoice_detail_num                   --�ꊇ����������No
          ,xil.note_line_id                    AS  note_line_id                         --�`�[����No
          ,xil.ship_cust_code                  AS  ship_cust_code                       --�[�i��ڋq�R�[�h
          ,xil.ship_cust_name                  AS  ship_cust_name                       --�[�i��ڋq��
          ,xil.ship_cust_kana_name             AS  ship_cust_kana_name                  --�[�i��ڋq�J�i��
          ,xil.sold_location_code              AS  sold_location_code                   --���㋒�_�R�[�h
          ,xil.sold_location_name              AS  sold_location_name                   --���㋒�_��
          ,xil.ship_shop_code                  AS  ship_shop_code                       --�[�i��X�܃R�[�h
          ,xil.ship_shop_name                  AS  ship_shop_name                       --�[�i��X��
          ,xil.inv_type                        AS  inv_type                             --�����敪
          ,flv2.meaning                        AS  inv_name                             --�����敪��
          ,xil.vd_cust_type                    AS  vd_cust_type                         --VD�ڋq�敪
          ,flv3.meaning                        AS  vd_cust_name                         --VD�ڋq�敪��
          ,xil.chain_shop_code                 AS  chain_shop_code                      --�`�F�[���X�R�[�h
          ,hp.party_name                       AS  edi_chain_code_name                  --�`�F�[���X��
          ,xil.delivery_date                   AS  delivery_date                        --�[�i��
          ,xil.slip_num                        AS  slip_num                             --�`�[�ԍ�
          ,xil.order_num                       AS  order_num                            --�I�[�_�[NO
          ,xil.slip_type                       AS  slip_type                            --�`�[�敪
          ,xil.classify_type                   AS  classify_type                        --���ދ敪
          ,xil.customer_dept_code              AS  customer_dept_code                   --���q�l����R�[�h
          ,xil.customer_division_code          AS  customer_division_code               --���q�l�ۃR�[�h
          ,xil.sold_return_type                AS  sold_return_type                     --����ԕi�敪
          ,flv4.meaning                        AS  sold_return_name                     --����ԕi�敪��
          ,xil.nichiriu_by_way_type            AS  nichiriu_by_way_type                 --�j�`���E�o�R�敪
          ,xil.sale_type                       AS  sale_type                            --�����敪
          ,xil.direct_num                      AS  direct_num                           --��No
          ,xil.po_date                         AS  po_date                              --������
          ,xil.acceptance_date                 AS  acceptance_date                      --������
          ,xil.item_code                       AS  item_code                            --���iCD
          ,xil.item_name                       AS  item_name                            --���i��
          ,xil.item_kana_name                  AS  item_kana_name                       --���i�J�i��
          ,xil.policy_group                    AS  policy_group                         --����Q�R�[�h
          ,mc.policy_group_name                AS  policy_group_name                    --����Q�R�[�h��
          ,xil.jan_code                        AS  jan_code                             --JAN�R�[�h
          ,xil.quantity                        AS  quantity                             --����
          ,xil.unit_price                      AS  unit_price                           --�P��
          ,xil.dlv_qty                         AS  dlv_qty                              --�[�i����
          ,xil.dlv_unit_price                  AS  dlv_unit_price                       --�[�i�P��
          ,xil.tax_amount                      AS  tax_amount                           --����ŋ��z
          ,xil.tax_rate                        AS  tax_rate                             --����ŗ�
          ,xil.ship_amount                     AS  ship_amount                          --�[�i���z
          ,xil.sold_amount                     AS  sold_amount                          --������z
          ,xil.red_black_slip_type             AS  red_black_slip_type                  --�ԓ`���`�敪
          ,xil.delivery_chain_code             AS  delivery_chain_code                  --�[�i��`�F�[���R�[�h
          ,flv5.description                    AS  delivery_chain_name                  --�[�i��`�F�[����
          ,xil.tax_code                        AS  tax_code                             --�ŋ��R�[�h
          ,avtab.description                   AS  description                          --�ŋ���
          ,gv_coop_date                        AS  cool_date                            --�A�g����
    FROM   apps.xxcfr_invoice_headers      xih    --�����w�b�_���e�[�u��
          ,apps.xxcfr_invoice_lines        xil    --�������׏��e�[�u��
          ,apps.fnd_lookup_values          flv1   --����ŋ敪���擾�p
          ,(
             SELECT ffvl.flex_value  base_code    --�������_�R�[�h
                   ,ffvl.attribute4  base_name    --�������_��
             FROM   apps.fnd_flex_value_sets           ffvs
                   ,apps.fnd_flex_values               ffvl
                   ,apps.fnd_flex_values_tl            ffvt
             WHERE  ffvl.flex_value_set_id    =  ffvs.flex_value_set_id
               AND  ffvt.flex_value_id        =  ffvl.flex_value_id
               AND  ffvt.language             =  cv_lang
               AND  ffvl.summary_flag         =  cv_flag_n
               AND  ffvs.flex_value_set_name  =  cv_flex_value_department
           ) ffv1                                 --�������_���擾�p
          ,apps.fnd_lookup_values          flv2   --�����敪���擾�p
          ,apps.fnd_lookup_values          flv3   --VD�ڋq�敪���擾�p
          ,apps.xxcmm_cust_accounts        xca    --�ڋq�ǉ����(�`�F�[���X���擾�p)
          ,apps.hz_cust_accounts           hca    --�ڋq�}�X�^(�`�F�[���X���擾�p)
          ,apps.hz_parties                 hp     --�p�[�e�B�}�X�^(�`�F�[���X���擾�p)
          ,apps.fnd_lookup_values          flv4   --����ԕi�敪���擾�p
          ,(
             SELECT mcb.segment1     policy_group
                   ,mct.description  policy_group_name
             FROM   apps.mtl_categories_b           mcb    --�J�e�S���}�X�^(����Q�R�[�h���擾�p)
                   ,apps.mtl_category_sets_b        mcsb   --�J�e�S���Z�b�g�}�X�^(����Q�R�[�h���擾�p)
                   ,apps.mtl_categories_tl          mct    --�J�e�S�����{��}�X�^(����Q�R�[�h���擾�p)
             WHERE  mcb.structure_id            = mcsb.structure_id
             AND    mcsb.category_set_id        = 1100000022
             AND    mcb.category_id             = mct.category_id
             AND    mct.language                = cv_lang
             AND    mct.source_lang             = cv_lang
           ) mc                                   --����Q�R�[�h���擾�p
          ,apps.fnd_lookup_values          flv5   --�[�i��`�F�[�����擾�p
          ,apps.ar_vat_tax_all_b           avtab  --�ŃR�[�h���擾�p
    WHERE  xih.invoice_id             = xil.invoice_id
      AND  xih.cutoff_date            = ld_cutoff_date               --�����Ώۓ��t
      AND  xih.tax_type               = flv1.lookup_code(+)          --����ŋ敪���擾
      AND  flv1.language(+)           = cv_lang                      --����ŋ敪���擾
      AND  flv1.lookup_type(+)        = cv_lookup_syohizei_kbn       --����ŋ敪���擾
      AND  flv1.enabled_flag(+)       = cv_flag_y                    --����ŋ敪���擾
      AND  xih.receipt_location_code  = ffv1.base_code (+)           --�������_���擾
      AND  xil.inv_type               = flv2.lookup_code(+)          --�����敪���擾
      AND  flv2.language(+)           = cv_lang                      --�����敪���擾
      AND  flv2.lookup_type(+)        = cv_lookup_invoice_kbn        --�����敪���擾
      AND  flv2.enabled_flag(+)       = cv_flag_y                    --�����敪���擾
      AND  xil.vd_cust_type           = flv3.lookup_code(+)          --VD�ڋq�敪���擾
      AND  flv3.language(+)           = cv_lang                      --VD�ڋq�敪���擾
      AND  flv3.lookup_type(+)        = cv_lookup_vd_customer_kbn    --VD�ڋq�敪���擾
      AND  flv3.enabled_flag(+)       = cv_flag_y                    --VD�ڋq�敪���擾
      AND  xil.chain_shop_code        = xca.edi_chain_code(+)        --�`�F�[���X���擾
      AND  xca.customer_id            = hca.cust_account_id(+)       --�`�F�[���X���擾
      AND  hca.party_id               = hp.party_id(+)               --�`�F�[���X���擾
      AND  hca.customer_class_code(+) = cv_18                        --�`�F�[���X���擾
      AND  xil.sold_return_type       = flv4.attribute1(+)           --����ԕi�敪���擾
      AND  flv4.lookup_type(+)        = cv_lookup_delivery_slip      --����ԕi�敪���擾
      AND  flv4.language(+)           = cv_lang                      --����ԕi�敪���擾
      AND  flv4.lookup_code(+)        IN (cv_1,cv_2)                 --����ԕi�敪���擾
      AND  xil.policy_group           = mc.policy_group(+)           --����Q�R�[�h���擾
      AND  xil.delivery_chain_code    = flv5.lookup_code(+)          --�[�i��`�F�[�����擾�p
      AND  flv5.language(+)           = cv_lang                      --�[�i��`�F�[�����擾�p
      AND  flv5.lookup_type(+)        = cv_lookup_chain_code         --�[�i��`�F�[�����擾�p
      AND  flv5.enabled_flag(+)       = cv_flag_y                    --�[�i��`�F�[�����擾�p
      AND  xil.tax_code               = avtab.tax_code(+)            --�ŃR�[�h���擾�p
      AND  avtab.set_of_books_id(+)   = gn_set_of_bks_id             --�ŃR�[�h���擾�p
      AND  avtab.org_id(+)            = gn_org_id                    --�ŃR�[�h���擾�p
      AND  avtab.enabled_flag(+)      = cv_flag_y                    --�ŃR�[�h���擾�p
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
    --���b�Z�[�W�g�[�N���擾
    --==============================================================
--
    lv_invoice_info_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                      ,cv_msgtkn_cfo_11178);         -- �ꊇ���
--
    --==============================================================
    --�Ώۃf�[�^�擾
    --==============================================================
      --�����Ώے����v�Z
      IF (iv_cutoff_date IS NULL) THEN
        --�Ɩ����t - �d�q���돈�����s����
        ld_cutoff_date := gd_process_date - TO_NUMBER(gt_electric_exec_days);
      ELSE
        --����(�C���p�����[�^)
        ld_cutoff_date := TO_DATE( iv_cutoff_date , cv_date_format_ymdshms );
      END IF;
      --�J�[�\���I�[�v��
      OPEN get_invoice_fixed_cur;
      <<main_loop>>
      LOOP
      FETCH get_invoice_fixed_cur INTO
            gt_data_tab(1)  --�ꊇ������ID
          , gt_data_tab(2)  --��v����ID
          , gt_data_tab(3)  --����
          , gt_data_tab(4)  --�x������
          , gt_data_tab(5)  --�x������ID
          , gt_data_tab(6)  --�T�C�g����
          , gt_data_tab(7)  --����
          , gt_data_tab(8)  --�x����
          , gt_data_tab(9)  --����ŋ敪
          , gt_data_tab(10) --����ŋ敪��
          , gt_data_tab(11) --�ō��z���ID
          , gt_data_tab(12) --�ō��z
          , gt_data_tab(13) --�Ŕ��������z���v
          , gt_data_tab(14) --�Ŋz���v
          , gt_data_tab(15) --�ō��������z���v
          , gt_data_tab(16) --����於
          , gt_data_tab(17) --���t��X�֔ԍ�
          , gt_data_tab(18) --���t��Z��1
          , gt_data_tab(19) --���t��Z��2
          , gt_data_tab(20) --���t��Z��3
          , gt_data_tab(21) --���t�於
          , gt_data_tab(22) --�쐬��
          , gt_data_tab(23) --�Ώ۔N��
          , gt_data_tab(24) --�Ώۊ��ԁi���j
          , gt_data_tab(25) --�Ώۊ��ԁi���j
          , gt_data_tab(26) --�d����R�[�h
          , gt_data_tab(27) --�������_�R�[�h
          , gt_data_tab(28) --���_��
          , gt_data_tab(29) --�������_�R�[�h
          , gt_data_tab(30) --�������_��
          , gt_data_tab(31) --������ڋq�R�[�h
          , gt_data_tab(32) --������ڋq��
          , gt_data_tab(33) --������ڋq�J�i��
          , gt_data_tab(34) --������ڋqID
          , gt_data_tab(35) --������ڋq���ݒnID
          , gt_data_tab(36) --������X�܃R�[�h
          , gt_data_tab(37) --������X��
          , gt_data_tab(38) --���|�R�[�h2�i���Ə��j
          , gt_data_tab(39) --���|�R�[�h2�i���Ə��j����
          , gt_data_tab(40) --���|�R�[�h3�i���̑��j
          , gt_data_tab(41) --���|�R�[�h3�i���̑��j����
          , gt_data_tab(42) --�ꊇ����������No
          , gt_data_tab(43) --�`�[����No
          , gt_data_tab(44) --�[�i��ڋq�R�[�h
          , gt_data_tab(45) --�[�i��ڋq��
          , gt_data_tab(46) --�[�i��ڋq�J�i��
          , gt_data_tab(47) --���㋒�_�R�[�h
          , gt_data_tab(48) --���㋒�_��
          , gt_data_tab(49) --�[�i��X�܃R�[�h
          , gt_data_tab(50) --�[�i��X��
          , gt_data_tab(51) --�����敪
          , gt_data_tab(52) --�����敪��
          , gt_data_tab(53) --VD�ڋq�敪
          , gt_data_tab(54) --VD�ڋq�敪��
          , gt_data_tab(55) --�`�F�[���X�R�[�h
          , gt_data_tab(56) --�`�F�[���X��
          , gt_data_tab(57) --�[�i��
          , gt_data_tab(58) --�`�[�ԍ�
          , gt_data_tab(59) --�I�[�_�[NO
          , gt_data_tab(60) --�`�[�敪
          , gt_data_tab(61) --���ދ敪
          , gt_data_tab(62) --���q�l����R�[�h
          , gt_data_tab(63) --���q�l�ۃR�[�h
          , gt_data_tab(64) --����ԕi�敪
          , gt_data_tab(65) --����ԕi�敪��
          , gt_data_tab(66) --�j�`���E�o�R�敪
          , gt_data_tab(67) --�����敪
          , gt_data_tab(68) --��No
          , gt_data_tab(69) --������
          , gt_data_tab(70) --������
          , gt_data_tab(71) --���iCD
          , gt_data_tab(72) --���i��
          , gt_data_tab(73) --���i�J�i��
          , gt_data_tab(74) --����Q�R�[�h
          , gt_data_tab(75) --����Q�R�[�h��
          , gt_data_tab(76) --JAN�R�[�h
          , gt_data_tab(77) --����
          , gt_data_tab(78) --�P��
          , gt_data_tab(79) --�[�i����
          , gt_data_tab(80) --�[�i�P��
          , gt_data_tab(81) --����ŋ��z
          , gt_data_tab(82) --����ŗ�
          , gt_data_tab(83) --�[�i���z
          , gt_data_tab(84) --������z
          , gt_data_tab(85) --�ԓ`���`�敪
          , gt_data_tab(86) --�[�i��`�F�[���R�[�h
          , gt_data_tab(87) --�[�i��`�F�[����
          , gt_data_tab(88) --�ŋ��R�[�h
          , gt_data_tab(89) --�ŋ���
          , gt_data_tab(90) --�A�g����
          ;
        EXIT WHEN get_invoice_fixed_cur%NOTFOUND;
--
        --
        --==============================================================
        --���ڃ`�F�b�N����(A-3)
        --==============================================================
        chk_item(
          ov_msgcode                    =>        lv_msgcode     -- ���b�Z�[�W�R�[�h
         ,ov_errbuf                     =>        lv_errbuf      -- �G���[�E���b�Z�[�W
         ,ov_retcode                    =>        lv_retcode     -- ���^�[���E�R�[�h
         ,ov_errmsg                     =>        lv_errmsg);    -- ���[�U�[�E�G���[�E���b�Z�[�W
        IF ( ( lv_retcode = cv_status_normal ) AND ( gn_warn_cnt = 0 ) ) THEN
          -- ���ڃ`�F�b�N�̖߂肪���킩��0Byte�t�@�C���㏑���t���O��'N'�̏ꍇ�ACSV�o�͂��s��
          --==============================================================
          -- CSV�o�͏���(A-4)
          --==============================================================
          out_csv (
            ov_errbuf                   =>        lv_errbuf
           ,ov_retcode                  =>        lv_retcode
           ,ov_errmsg                   =>        lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --�����𒆒f
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        --�Ώی�����1�J�E���g
        gn_target_cnt      := gn_target_cnt + 1;
--
      END LOOP main_loop;
      CLOSE get_invoice_fixed_cur;
--
    --==================================================================
    -- 0���̏ꍇ�̓��b�Z�[�W�o��
    --==================================================================
    IF gn_target_cnt = 0 THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,cv_msg_cfo_10025      -- �擾�Ώۃf�[�^�������b�Z�[�W
                                                     ,cv_tkn_get_data       -- �g�[�N��'GET_DATA' 
                                                     ,lv_invoice_info_name  -- �������
                                                    )
                            ,1
                            ,5000
                          );
      --���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF get_invoice_fixed_cur%ISOPEN THEN
        CLOSE get_invoice_fixed_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_invoice;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_cutoff_date        IN  VARCHAR2, --   1.����
    iv_file_name          IN  VARCHAR2, --   2.�t�@�C����
    ov_errbuf             OUT VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2) --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_cutoff_date      -- 1.����
      ,iv_file_name        -- 2.�t�@�C����
      ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۃf�[�^�擾(A-2)
    -- ===============================
    get_invoice(
      iv_cutoff_date      -- ����
     ,lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      gv_0file_flg := cv_flag_y;
      RAISE global_process_expt;
    ELSIF ( gn_warn_cnt <> 0 ) THEN
      gv_0file_flg := cv_flag_y;
      ov_retcode := cv_status_warn;
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
    errbuf                OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode               OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_cutoff_date        IN  VARCHAR2,      -- 1.����
    iv_file_name          IN  VARCHAR2       -- 2.�t�@�C����
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
       iv_cutoff_date                              -- 1.����
      ,iv_file_name                                -- 2.�t�@�C����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    IF ( lv_retcode = cv_status_warn ) THEN
      -- ��v�`�[���W���F�x���I�����̌����ݒ�
      gn_normal_cnt := 0;
    END IF;
--
    -- ====================================================
    -- �t�@�C���N���[�Y
    -- ====================================================
    -- �t�@�C�����I�[�v������Ă���ꍇ�̓N���[�Y����
    IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    -- ====================================================
    -- �t�@�C��0Byte�X�V
    -- ====================================================
    -- A-2�ȍ~�̏����ŃG���[���������Ă����ꍇ�A
    -- �t�@�C�����ēx�I�[�v�����N���[�Y���A0Byte�ɍX�V����
    IF ( ( ( lv_retcode = cv_status_error ) OR ( lv_retcode = cv_status_warn ) ) 
         AND ( gv_0file_flg = cv_flag_y ) ) THEN
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                       ,cn_max_linesize
                                      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- �t�@�C���I�[�v���G���[
                                                       )
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
      END;
      --�t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
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
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_msg_ccp_00001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    --
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
END XXCFO019A13C;
/
