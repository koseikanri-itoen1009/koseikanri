CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS003A06C (body)
 * Description      : �̔��\�����X�V
 * MD.050           : �̔��\�����X�V MD050_COS_003_A06
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_xxcos_vd_deliv     �x���_�[�i���уf�[�^���o(A-2)
 *  update_mst_vd_column   VD�R�����}�X�^�X�V(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/09/26    1.0   K.Nakamura       �V�K�쐬
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
  gn_normal_cnt    NUMBER;                    -- �X�V����
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
  -- ���b�N��O
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  -- �x������O
  warn_expt                 EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS003A06C';    -- �p�b�P�[�W��
  cv_application            CONSTANT VARCHAR2(10)  := 'XXCOS';           -- �A�v���P�[�V������(�̔�)
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';           -- �A�h�I���F���ʁEIF�̈�
  -- ���b�Z�[�W
  cv_msg_no_data_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�����G���[
  cv_msg_profile_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G��
  cv_msg_org_id_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00091'; -- �݌ɑg�DID�擾�G���[
  cv_msg_update_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_process_date_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- �Ɩ��������擾�G���[
  cv_msg_lookup_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14255'; -- �̔��\���Ώیڋq�X�e�[�^�X�擾�G���[���b�Z�[�W
  cv_msg_lock_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14256'; -- VD�R�����}�X�^���b�N�擾�G���[���b�Z�[�W
  cv_msg_no_param           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ�
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE';          -- �v���t�@�C����
  cv_tkn_org_code_tok       CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';     -- �݌ɑg�D�R�[�h
  cv_tkn_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';      -- �^�C�v��
  cv_tkn_table_name         CONSTANT VARCHAR2(20) := 'TABLE_NAME';       -- �e�[�u����
  cv_tkn_key_data           CONSTANT VARCHAR2(20) := 'KEY_DATA';         -- �L�[����
  -- �v���t�@�C��
  cv_organization_code      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- �݌ɑg�D�R�[�h
  -- �Q�ƃR�[�h
  cv_lookup_cust_status     CONSTANT VARCHAR2(30) := 'XXCOS1_FORECAST_CUST_STATUS';   -- �̔��\���Ώیڋq�X�e�[�^�X
  cv_lookup_type_gyotai     CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03'; -- �Ƒԁi�����ށj
  -- ���b�Z�[�W�o�͕���
  cv_profile_org_code       CONSTANT VARCHAR2(30) := 'XXCOI:�݌ɑg�D�R�[�h'; -- �v���t�@�C����
  cv_xxcoi_mst_cd_column    CONSTANT VARCHAR2(20) := 'VD�R�����}�X�^';       -- �e�[�u����
  cv_customer_code          CONSTANT VARCHAR2(20) := '�ڋq�R�[�h';           -- ���ږ�
  cv_column_no              CONSTANT VARCHAR2(20) := '�R����No';             -- ���ږ�
  -- �t���O
  cv_flag_on                CONSTANT VARCHAR2(1)  := 'Y'; -- �L���t���O
  cv_forecast_use_flag      CONSTANT VARCHAR2(1)  := 'Y'; -- �̔��\�����p�t���O
  -- ����
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- VD�R�����}�X�^�X�V���i�[�p
  TYPE g_update_rtype IS RECORD
    (
       rownumber            NUMBER,                                      -- ����
       customer_number      xxcos_vd_deliv_headers.customer_number%TYPE, -- �ڋq�R�[�h
       customer_id          xxcoi_mst_vd_column.customer_id%TYPE,        -- �ڋqID
       column_no            xxcoi_mst_vd_column.column_no%TYPE,          -- �R����No
       dlv_date_1           xxcoi_mst_vd_column.dlv_date_1%TYPE,         -- �[�i��1
       quantity_1           xxcoi_mst_vd_column.quantity_1%TYPE,         -- �{��1
       dlv_date_2           xxcoi_mst_vd_column.dlv_date_2%TYPE,         -- �[�i��2
       quantity_2           xxcoi_mst_vd_column.quantity_2%TYPE,         -- �{��2
       dlv_date_3           xxcoi_mst_vd_column.dlv_date_3%TYPE,         -- �[�i��3
       quantity_3           xxcoi_mst_vd_column.quantity_3%TYPE,         -- �{��3
       dlv_date_4           xxcoi_mst_vd_column.dlv_date_4%TYPE,         -- �[�i��4
       quantity_4           xxcoi_mst_vd_column.quantity_4%TYPE,         -- �{��4
       dlv_date_5           xxcoi_mst_vd_column.dlv_date_5%TYPE,         -- �[�i��5
       quantity_5           xxcoi_mst_vd_column.quantity_5%TYPE          -- �{��5
    );
  TYPE g_update_ttype IS TABLE OF g_update_rtype INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_organization_code      mtl_parameters.organization_code%TYPE; -- �݌ɑg�D�R�[�h
  gv_organization_id        mtl_parameters.organization_id%TYPE;   -- �݌ɑg�DID
  gv_key_info               fnd_new_messages.message_text%TYPE;    -- ���b�Z�[�W�o�͗p�L�[���
  gd_process_date           DATE         DEFAULT NULL;             -- �Ɩ����t
  gn_init_warn_cnt          NUMBER;                                -- �x������
  g_update_tab              g_update_ttype;                        -- VD�R�����}�X�^�X�V���
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
    -- *** ���[�J���ϐ� ***
    ln_lookup_code_cnt               NUMBER DEFAULT 0; -- �̔��\���Ώیڋq�X�e�[�^�X�擾
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
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_msg_no_param
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- �Ɩ����������擾
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( gd_process_date IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_msg_process_date_err
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �v���t�@�C���̎擾(�݌ɑg�D�R�[�h)
    --==============================================================
    gv_organization_code := FND_PROFILE.VALUE(cv_organization_code);
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( gv_organization_code IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_org_code
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �݌ɑg�D�R�[�h���݌ɑg�DID�𓱏o
    --==============================================================
    gv_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
    -- �݌ɑg�DID�擾�G���[�̏ꍇ
    IF ( gv_organization_id IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_org_id_err
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => gv_organization_code
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- �̔��\���Ώیڋq�X�e�[�^�X�擾
    --==============================================================
    SELECT COUNT(flv.lookup_code) lookup_code -- ����
    INTO   ln_lookup_code_cnt
    FROM   fnd_lookup_values      flv
    WHERE  flv.lookup_type  = cv_lookup_cust_status
    AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                               AND NVL(flv.end_date_active, gd_process_date)
    AND    flv.enabled_flag = cv_flag_on
    AND    flv.language     = ct_language
    ;
    -- �̔��\���Ώیڋq�X�e�[�^�X�����݂��Ȃ��ꍇ
    IF ( ln_lookup_code_cnt = 0 ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_lookup_err
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_lookup_cust_status
                   );
      RAISE warn_expt;
    END IF;
--
  EXCEPTION
    -- *** ���������x������O�n���h�� ***
    WHEN warn_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      -- �x�������J�E���g�A�b�v
      gn_init_warn_cnt := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
   * Procedure Name   : get_xxcos_vd_deliv
   * Description      : �x���_�[�i���уf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_xxcos_vd_deliv(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcos_vd_deliv'; -- �v���O������
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
    cv_blank_column_code    CONSTANT VARCHAR2(7) := 'BLANK_C'; -- �u�����N�R�����p�_�~�[�i�ځi�x���_�[�i���т݂̂Ŏg�p�����j
    cv_dummy_char           CONSTANT VARCHAR2(1) := 'X';       -- �_�~�[����
    cv_rownumber_min        CONSTANT NUMBER      := 1;         -- �擾���R�[�h�ŏ��l
    cv_rownumber_max        CONSTANT NUMBER      := 5;         -- �擾���R�[�h�ő�l
    cv_record_1             CONSTANT NUMBER      := 1;         -- ���R�[�h1����
    cv_record_2             CONSTANT NUMBER      := 2;         -- ���R�[�h2����
    cv_record_3             CONSTANT NUMBER      := 3;         -- ���R�[�h3����
    cv_record_4             CONSTANT NUMBER      := 4;         -- ���R�[�h4����
    cv_record_5             CONSTANT NUMBER      := 5;         -- ���R�[�h5����
--
    -- *** ���[�J���ϐ� ***
    lv_segment1                      VARCHAR2(7) DEFAULT NULL;  -- �}�X�^�i�ڃR�[�h�p�ϐ�
    lv_hot_cold                      VARCHAR2(1) DEFAULT NULL;  -- �}�X�^H/C�p�ϐ�
    ln_recode_cnt                    NUMBER      DEFAULT 1;     -- �i�[�i�[�i��1�`5�A�{��1�`5�j����p�ϐ�
    ln_vd_column_cnt                 NUMBER      DEFAULT 1;     -- PL/SQL�\�̃��R�[�h�p�ϐ�
    lb_same_record_flag              BOOLEAN     DEFAULT FALSE; -- ��v���R�[�h����t���O
    lb_column_change_flag            BOOLEAN     DEFAULT FALSE; -- �R�����ύX����t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �x���_�[�i���уJ�[�\��
    CURSOR xxcos_vd_deliv_cur
    IS
      SELECT xvdhv.customer_number   customer_number    -- �ڋq�R�[�h
           , xvdhv.customer_id       customer_id        -- �ڋqID
           , xvdhv.dlv_date          dlv_date           -- �[�i��
           , xvdl.column_num         column_num         -- �R����No
           , xvdl.sales_qty          sales_qty          -- ���㐔
           , xvdl.item_code          item_code          -- �i�ڃR�[�h(�[�i����)
           , xvdl.hot_cold_type      hot_cold_type      -- H/C(�[�i����)
           , msib.segment1           segment1           -- �i�ڃR�[�h(�}�X�^)
           , xmvc.hot_cold           hot_cold           -- H/C(�}�X�^)
           , xmvc.column_change_date column_change_date -- �R�����ύX��
           , xvdhv.rownumber         rownumber          -- ����
      FROM 
             (
               SELECT /*+ LEADING(flv xca xvdh) USE_NL(flv xca xvdh) */
                      xca.customer_id        customer_id                     -- �ڋqID
                    , xvdh.customer_number   customer_number                 -- �ڋq�R�[�h
                    , xvdh.dlv_date          dlv_date                        -- �[�i��
                    , ROW_NUMBER() OVER (PARTITION BY xvdh.customer_number ORDER BY xvdh.dlv_date DESC)
                                             rownumber                       -- �ڋq���Ƃɔ[�i���Ń\�[�g���ď��ԕt��
               FROM   xxcos_vd_deliv_headers xvdh                            -- �x���_�[�i���уw�b�_
                    , hz_parties             hp                              -- �p�[�e�B�}�X�^
                    , hz_cust_accounts       hca                             -- �ڋq�}�X�^
                    , xxcmm_cust_accounts    xca                             -- �ڋq�ǉ����
                    , fnd_lookup_values      flv                             -- �N�C�b�N�R�[�h
                    , fnd_lookup_values      flv2                            -- �N�C�b�N�R�[�h
               WHERE  xvdh.customer_number   = xca.customer_code             -- �ڋq�R�[�h
               AND    xca.customer_id        = hca.cust_account_id           -- �ڋqID
               AND    hca.party_id           = hp.party_id                   -- �p�[�e�BID
               AND    xca.business_low_type  = flv.meaning                   -- �Ƒԁi�����ށj
               AND    flv.lookup_type        = cv_lookup_type_gyotai         -- �^�C�v
               AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                          AND NVL(flv.end_date_active, gd_process_date)
                                                                             -- �L����
               AND    flv.enabled_flag       = cv_flag_on                    -- �L���t���O
               AND    flv.language           = ct_language                   -- ����
               AND    flv2.lookup_code       = hp.duns_number_c              -- �ڋq�X�e�[�^�X
               AND    flv2.lookup_type       = cv_lookup_cust_status         -- �^�C�v
               AND    gd_process_date BETWEEN NVL(flv2.start_date_active, gd_process_date)
                                          AND NVL(flv2.end_date_active, gd_process_date)
                                                                             -- �L����
               AND    flv2.enabled_flag      = cv_flag_on                    -- �L���t���O
               AND    flv2.language          = ct_language                   -- ����
               AND EXISTS (
                            SELECT /*+ USE_NL(xvdhv) */
                                   cv_dummy_char           dummy_char
                            FROM   xxcos_vd_deliv_headers  xvdhv                  -- �x���_�[�i���уw�b�_
                            WHERE  xvdhv.customer_number   = xvdh.customer_number -- �ڋq�R�[�h
                            AND    xvdhv.last_update_date >= gd_process_date      -- �ŏI�X�V��
                          )
               AND EXISTS (
                            SELECT cv_dummy_char      dummy_char
                            FROM   bom_calendars      bc                     -- �ғ����J�����_
                                 , bom_calendar_dates bcd                    -- �ғ����J�����_���t
                            WHERE  bc.calendar_code   = bcd.calendar_code    -- �J�����_�R�[�h
                            AND    bc.calendar_code   = xca.calendar_code    -- �ғ����J�����_�R�[�h
                            AND    bcd.calendar_date  = xvdh.dlv_date        -- �J�����_���t
                            AND    bc.attribute1      = cv_forecast_use_flag -- �̔��\�����p�t���O�i�̔��\���J�����_�j
                            AND    bcd.seq_num   IS NOT NULL                 -- ���ԁi��ғ��������O�j
                          )
             )                         xvdhv                                 -- �x���_�[�i���уw�b�_�̑Ώۍi���݃T�u�N�G���[
           , xxcos_vd_deliv_lines      xvdl                                  -- �x���_�[�i���і���
           , xxcoi_mst_vd_column       xmvc                                  -- VD�R�����}�X�^
           , mtl_system_items_b        msib                                  -- �i�ڃ}�X�^
      WHERE  xvdhv.customer_number     = xvdl.customer_number                -- �ڋq�R�[�h
      AND    xvdhv.dlv_date            = xvdl.dlv_date                       -- �[�i��
      AND    xvdhv.rownumber BETWEEN cv_rownumber_min
                                 AND cv_rownumber_max                        -- �x���_�[�i���т̌ڋq���Ƃɒ���5���擾
      AND    xvdhv.customer_id         = xmvc.customer_id                    -- �ڋqID
      AND    xvdl.column_num           = xmvc.column_no                      -- �R����No
      AND    msib.inventory_item_id(+) = xmvc.item_id                        -- �i��ID
      AND    msib.organization_id(+)   = gv_organization_id                  -- �݌ɑg�DID
      ORDER BY xvdhv.customer_number                                         -- �ڋq�R�[�h
             , xvdl.column_num                                               -- �R����No
             , xvdhv.rownumber                                               -- ����
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
    -- �X�V���i�[���[�v
    <<xxcos_vd_deliv_loop>>
    FOR l_xxcos_vd_deliv_rec IN xxcos_vd_deliv_cur LOOP
      -- �Ώی����J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
      -- ����̏ꍇ
      IF ( gn_target_cnt = cv_record_1 ) THEN
        -- �}�X�^�̕i�ڃR�[�h��H/C��ϐ��i�[
        lv_segment1 := NVL(l_xxcos_vd_deliv_rec.segment1, cv_blank_column_code);
        lv_hot_cold := NVL(l_xxcos_vd_deliv_rec.hot_cold, cv_dummy_char);
        --
        g_update_tab(ln_vd_column_cnt).rownumber       := l_xxcos_vd_deliv_rec.rownumber;
        g_update_tab(ln_vd_column_cnt).customer_number := l_xxcos_vd_deliv_rec.customer_number;
        g_update_tab(ln_vd_column_cnt).customer_id     := l_xxcos_vd_deliv_rec.customer_id;
        g_update_tab(ln_vd_column_cnt).column_no       := l_xxcos_vd_deliv_rec.column_num;
        -- �ȉ��̏ꍇ�́A�[�i���Ɩ{����NULL�Ŋi�[
        --   VD�R�����}�X�^�̕i�ڂ�NULL�i��R�����j�̏ꍇ
        --   �[�i�����R�����ύX�������O�̏ꍇ
        --   �i�ڂ��[�i���т�VD�R�����}�X�^�ő��Ⴗ��ꍇ
        --   H/C���[�i���т�VD�R�����}�X�^�ő��Ⴗ��ꍇ
        IF ( ( lv_segment1 = cv_blank_column_code )
          OR ( l_xxcos_vd_deliv_rec.dlv_date < NVL(l_xxcos_vd_deliv_rec.column_change_date, l_xxcos_vd_deliv_rec.dlv_date ) )
          OR ( l_xxcos_vd_deliv_rec.item_code <> lv_segment1 )
          OR ( NVL(l_xxcos_vd_deliv_rec.hot_cold_type, cv_dummy_char) <> lv_hot_cold ) ) THEN
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := NULL;
          g_update_tab(ln_vd_column_cnt).quantity_1 := NULL;
          lb_column_change_flag := TRUE;
        ELSE
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := l_xxcos_vd_deliv_rec.dlv_date;
          g_update_tab(ln_vd_column_cnt).quantity_1 := l_xxcos_vd_deliv_rec.sales_qty;
        END IF;
      -- �O��i�[���R�[�h�ƌڋq�܂��̓R�������قȂ�ꍇ
      ELSIF ( ( g_update_tab(ln_vd_column_cnt).customer_id <> l_xxcos_vd_deliv_rec.customer_id )
        OR ( g_update_tab(ln_vd_column_cnt).column_no <> l_xxcos_vd_deliv_rec.column_num ) ) THEN
        -- �R�����ύX����t���O������
        lb_column_change_flag := FALSE;
        -- �}�X�^�̕i�ڃR�[�h��H/C��ϐ��i�[
        lv_segment1 := NVL(l_xxcos_vd_deliv_rec.segment1, cv_blank_column_code);
        lv_hot_cold := NVL(l_xxcos_vd_deliv_rec.hot_cold, cv_dummy_char);
        -- �����R�[�h�֊i�[
        ln_vd_column_cnt := ln_vd_column_cnt + 1;
        ln_recode_cnt    := 1;
        --
        g_update_tab(ln_vd_column_cnt).rownumber       := l_xxcos_vd_deliv_rec.rownumber;
        g_update_tab(ln_vd_column_cnt).customer_number := l_xxcos_vd_deliv_rec.customer_number;
        g_update_tab(ln_vd_column_cnt).customer_id     := l_xxcos_vd_deliv_rec.customer_id;
        g_update_tab(ln_vd_column_cnt).column_no       := l_xxcos_vd_deliv_rec.column_num;
        --
        -- �ȉ��̏ꍇ�́A�[�i���Ɩ{����NULL�Ŋi�[
        --   VD�R�����}�X�^�̕i�ڂ�NULL�i��R�����j�̏ꍇ
        --   �[�i�����R�����ύX�������O�̏ꍇ
        --   �i�ڂ��[�i���т�VD�R�����}�X�^�ő��Ⴗ��ꍇ
        --   H/C���[�i���т�VD�R�����}�X�^�ő��Ⴗ��ꍇ
        IF ( ( lv_segment1 = cv_blank_column_code )
          OR ( l_xxcos_vd_deliv_rec.dlv_date < NVL(l_xxcos_vd_deliv_rec.column_change_date, l_xxcos_vd_deliv_rec.dlv_date ) )
          OR ( l_xxcos_vd_deliv_rec.item_code <> lv_segment1 )
          OR ( NVL(l_xxcos_vd_deliv_rec.hot_cold_type, cv_dummy_char) <> lv_hot_cold ) ) THEN
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := NULL;
          g_update_tab(ln_vd_column_cnt).quantity_1 := NULL;
          -- �R�����ύX����t���O
          lb_column_change_flag := TRUE;
        ELSE
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := l_xxcos_vd_deliv_rec.dlv_date;
          g_update_tab(ln_vd_column_cnt).quantity_1 := l_xxcos_vd_deliv_rec.sales_qty;
        END IF;
      -- �O��i�[���R�[�h�ƌڋq�ƃR�����������ꍇ�A���ꃌ�R�[�h�֊i�[�i�[�i��1�`5�A�{��1�`5�̂����ꂩ�֊i�[����j
      ELSE
        -- �ȉ��̏����Ŕ���
        --   ROWNUMBER����v����ꍇ�i�ڋq�A�R�����A�[�i������v���郌�R�[�h�j
        --   ROWNUMBER���s��v�̏ꍇ�A���̔[�i������і{���֊i�[����
        IF ( g_update_tab(ln_vd_column_cnt).rownumber = l_xxcos_vd_deliv_rec.rownumber ) THEN
          -- ��v���R�[�h����p�t���O
          lb_same_record_flag := TRUE;
        ELSE
          -- ��v���R�[�h����t���O�̏�����
          lb_same_record_flag := FALSE;
          --
          ln_recode_cnt := ln_recode_cnt + 1;
          g_update_tab(ln_vd_column_cnt).rownumber := l_xxcos_vd_deliv_rec.rownumber;
        END IF;
        -- �ȉ��̏ꍇ�́A�[�i���Ɩ{����NULL�Ŋi�[
        --   �V�������̗����Ŋ��ɃR�����ύX���s���Ă���Ɣ��肵���ꍇ
        --   VD�R�����}�X�^�̕i�ڂ�NULL�i��R�����j�̏ꍇ
        --   �[�i�����R�����ύX�������O�̏ꍇ
        --   �i�ڂ��[�i���т�VD�R�����}�X�^�ő��Ⴗ��ꍇ
        --   H/C���[�i���т�VD�R�����}�X�^�ő��Ⴗ��ꍇ
        IF ( ( lb_column_change_flag = TRUE )
          OR ( lv_segment1 = cv_blank_column_code )
          OR ( l_xxcos_vd_deliv_rec.dlv_date < NVL(l_xxcos_vd_deliv_rec.column_change_date, l_xxcos_vd_deliv_rec.dlv_date ) )
          OR ( l_xxcos_vd_deliv_rec.item_code <> lv_segment1 )
          OR ( NVL(l_xxcos_vd_deliv_rec.hot_cold_type, cv_dummy_char) <> lv_hot_cold ) ) THEN
          -- �ȉ��̏����Ŋi�[
          --   ROWNUMBER����v���郌�R�[�h�̏ꍇ�A�����R�[�h�փX�L�b�v
          --     �i���ɐ������l���i�[����Ă���A�܂��͌㑱���R�[�h���������l�̂��߁j
          --   ROWNUMBER����v���Ȃ����R�[�h�̏ꍇ�ANULL�Ŋi�[
          IF ( lb_same_record_flag = FALSE ) THEN
            -- �R�����ύX����t���O
            lb_column_change_flag := TRUE;
            --
            IF ( ln_recode_cnt = cv_record_1 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_1 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_1 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_2 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_2 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_2 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_3 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_3 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_3 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_4 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_4 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_4 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_5 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_5 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_5 := NULL;
            END IF;
          END IF;
          --
        ELSE
          IF ( ln_recode_cnt = cv_record_1 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_1 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_1 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_2 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_2 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_2 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_3 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_3 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_3 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_4 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_4 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_4 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_5 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_5 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_5 := l_xxcos_vd_deliv_rec.sales_qty;
          END IF;
        END IF;
      END IF;
    END LOOP xxcos_vd_deliv_loop;
    --
    -- �Ώی���0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_no_data_err
                   );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
  END get_xxcos_vd_deliv;
--
  /**********************************************************************************
   * Procedure Name   : update_mst_vd_column
   * Description      : VD�R�����}�X�^�X�V(A-3)
   ***********************************************************************************/
  PROCEDURE update_mst_vd_column(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mst_vd_column'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_rowid                         ROWID;
    lb_warn_flag                     BOOLEAN DEFAULT FALSE; -- �x���t���O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- VD�R�����}�X�^�X�V���[�v
    <<update_mst_vd_column_loop>>
    FOR i IN 1..g_update_tab.COUNT LOOP
      -- ������
      lv_errmsg    := NULL;
      lv_errbuf    := NULL;
      lb_warn_flag := FALSE;
      gv_key_info  := NULL;
      -- VD�R�����}�X�^���R�[�h���b�N
      BEGIN
        SELECT xmvc.ROWID
        INTO   lv_rowid
        FROM   xxcoi_mst_vd_column xmvc                       -- VD�R�����}�X�^
        WHERE  xmvc.customer_id = g_update_tab(i).customer_id -- �ڋqID
        AND    xmvc.column_no   = g_update_tab(i).column_no   -- �R����No
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN lock_expt THEN
          lb_warn_flag := TRUE;
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                          ,ov_retcode     => lv_retcode
                                          ,ov_errmsg      => lv_errmsg
                                          ,ov_key_info    => gv_key_info
                                          ,iv_item_name1  => cv_customer_code
                                          ,iv_data_value1 => g_update_tab(i).customer_number
                                          ,iv_item_name2  => cv_column_no
                                          ,iv_data_value2 => TO_CHAR(g_update_tab(i).column_no));
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_lock_err
                         ,iv_token_name1  => cv_tkn_table_name
                         ,iv_token_value1 => cv_xxcoi_mst_cd_column
                         ,iv_token_name2  => cv_tkn_key_data
                         ,iv_token_value2 => gv_key_info
                       );
          lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_warn;
          -- �X�L�b�v�����J�E���g�A�b�v
          gn_warn_cnt := gn_warn_cnt + 1;
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        WHEN OTHERS THEN
          RAISE;
      END;
      --
--
      -- ���b�N�擾���ł����ꍇ
      IF ( lb_warn_flag = FALSE ) THEN
        BEGIN
          -- VD�R�����}�X�^�X�V
          UPDATE xxcoi_mst_vd_column xmvc
          SET    xmvc.dlv_date_1             = g_update_tab(i).dlv_date_1  -- �[�i��1
               , xmvc.quantity_1             = g_update_tab(i).quantity_1  -- �{��1
               , xmvc.dlv_date_2             = g_update_tab(i).dlv_date_2  -- �[�i��2
               , xmvc.quantity_2             = g_update_tab(i).quantity_2  -- �{��2
               , xmvc.dlv_date_3             = g_update_tab(i).dlv_date_3  -- �[�i��3
               , xmvc.quantity_3             = g_update_tab(i).quantity_3  -- �{��3
               , xmvc.dlv_date_4             = g_update_tab(i).dlv_date_4  -- �[�i��4
               , xmvc.quantity_4             = g_update_tab(i).quantity_4  -- �{��4
               , xmvc.dlv_date_5             = g_update_tab(i).dlv_date_5  -- �[�i��5
               , xmvc.quantity_5             = g_update_tab(i).quantity_5  -- �{��5
               , xmvc.last_updated_by        = cn_last_updated_by          -- �ŏI�X�V��
               , xmvc.last_update_date       = cd_last_update_date         -- �ŏI�X�V��
               , xmvc.last_update_login      = cn_last_update_login        -- �ŏI�X�V۸޲�
               , xmvc.request_id             = cn_request_id               -- �v��ID
               , xmvc.program_application_id = cn_program_application_id   -- �ݶ��ĥ��۸��ѥ���ع����ID
               , xmvc.program_id             = cn_program_id               -- �ݶ��ĥ��۸���ID
               , xmvc.program_update_date    = cd_program_update_date      -- ��۸��эX�V��
          WHERE  xmvc.customer_id            = g_update_tab(i).customer_id -- �ڋqID
          AND    xmvc.column_no              = g_update_tab(i).column_no   -- �R����No
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lb_warn_flag := TRUE;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                            ,ov_retcode     => lv_retcode
                                            ,ov_errmsg      => lv_errmsg
                                            ,ov_key_info    => gv_key_info
                                            ,iv_item_name1  => cv_customer_code
                                            ,iv_data_value1 => g_update_tab(i).customer_number
                                            ,iv_item_name2  => cv_column_no
                                            ,iv_data_value2 => TO_CHAR(g_update_tab(i).column_no));
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_update_err
                           ,iv_token_name1  => cv_tkn_table_name
                           ,iv_token_value1 => cv_xxcoi_mst_cd_column
                           ,iv_token_name2  => cv_tkn_key_data
                           ,iv_token_value2 => gv_key_info
                         );
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
            ov_retcode := cv_status_warn;
            -- �X�L�b�v�����J�E���g�A�b�v
            gn_warn_cnt := gn_warn_cnt + 1;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
        END;
      END IF;
--
      -- �X�V�ł����ꍇ
      IF ( lb_warn_flag = FALSE ) THEN
        -- �X�V�����J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    --
    END LOOP update_mst_vd_column_loop;
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
  END update_mst_vd_column;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
    gn_init_warn_cnt := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �x���_�[�i���уf�[�^���o(A-2)
    -- ===============================
    get_xxcos_vd_deliv(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- VD�R�����}�X�^�X�V(A-3)
    -- ===============================
    update_mst_vd_column(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �x����O�n���h�� ***
    WHEN warn_expt THEN
      ov_retcode := cv_status_warn;
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
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14251'; -- �Ώی������b�Z�[�W
    cv_update_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14252'; -- �X�V�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14253'; -- �X�L�b�v�������b�Z�[�W
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14254'; -- �x���������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    --
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt    := 0;
      gn_normal_cnt    := 0;
      gn_warn_cnt      := 0;
      gn_init_warn_cnt := 0;
      gn_error_cnt     := 1;
      --
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
    -- ===============================
    -- �I������(A-4)
    -- ===============================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�V�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_update_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�x�������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_init_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCOS003A06C;
/
