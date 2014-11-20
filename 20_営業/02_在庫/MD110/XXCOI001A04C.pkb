CREATE OR REPLACE PACKAGE BODY XXCOI001A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A04C(body)
 * Description      : �������Ɋm�F
 * MD.050           : �������Ɋm�F MD050_COI_001_A04
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_slip_num           �Ώۓ`�[No�擾���� (A-2)
 *  get_storage_info       ���ɏ��擾���� (A-4)
 *  chk_org_acct_period    ��v���ԃ`�F�b�N���� (A-5)
 *  get_lock               ���b�N�擾���� (A-6)
 *  upd_storage_info_tab   �������Ɋm�F���� (A-7)
 *  submain                ���C�������v���V�[�W��
 *                         �Z�[�u�|�C���g�ݒ� (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   K.Nakamura       �V�K�쐬
 *  2009/02/12    1.1   S.Moriyama       �����e�X�g��QNo002�Ή�
 *  2009/02/24    1.2   K.Nakamura       �����e�X�g��QNo026�Ή�
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
  no_data_expt                   EXCEPTION; -- �擾����0����O
  lock_expt                      EXCEPTION; -- ���b�N�擾��O
  acct_period_close_expt         EXCEPTION; -- �݌ɉ�v���ԃN���[�Y
--
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  -- ���b�N�擾��O
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100) := 'XXCOI001A04C'; -- �p�b�P�[�W
  cv_appl_short_name             CONSTANT VARCHAR2(10)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_application_short_name      CONSTANT VARCHAR2(10)  := 'XXCOI';        -- �A�v���P�[�V�����Z�k��
  cv_flag_on                     CONSTANT VARCHAR2(1)   := 'Y';            -- �t���OON
  cv_flag_off                    CONSTANT VARCHAR2(1)   := 'N';            -- �t���OOFF
  -- ���b�Z�[�W
  cv_no_para_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_org_code_get_err_msg        CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00005'; -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_org_id_get_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00006'; -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_no_data_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00008'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_process_date_get_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOI1-00011'; -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_acct_period_close_err_msg   CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10018'; -- �݌ɉ�v���ԃN���[�Y���b�Z�[�W
  cv_table_lock_err_msg          CONSTANT VARCHAR2(100) := 'APP-XXCOI1-10029'; -- ���b�N�G���[���b�Z�[�W�i���ɏ��ꎞ�\�j
  -- �g�[�N��
  cv_tkn_pro                     CONSTANT VARCHAR2(20)  := 'PRO_TOK';          -- �v���t�@�C����
  cv_tkn_org_code                CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';     -- �݌ɑg�D�R�[�h
  cv_tkn_den_no                  CONSTANT VARCHAR2(20)  := 'DEN_NO';           -- �`�[No
  cv_tkn_entry_date              CONSTANT VARCHAR2(20)  := 'ENTRY_DATE';       -- �`�[���t
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �`�[No���R�[�h�i�[�p
  TYPE gt_slip_num_ttype IS TABLE OF xxcoi_storage_information.slip_num%TYPE INDEX BY BINARY_INTEGER;
--
  -- ���ɏ�񃌃R�[�h�i�[�p
  TYPE gr_storage_info_rec IS RECORD(
      transaction_id                 xxcoi_storage_information.transaction_id%TYPE                 -- ���ID
    , slip_num                       xxcoi_storage_information.slip_num%TYPE                       -- �`�[�ԍ�
    , slip_date                      xxcoi_storage_information.slip_date%TYPE                      -- �`�[���t
    , ship_case_qty                  xxcoi_storage_information.ship_case_qty%TYPE                  -- �o�ɐ��ʃP�[�X��
    , ship_singly_qty                xxcoi_storage_information.ship_singly_qty%TYPE                -- �o�ɐ��ʃo����
    , ship_summary_qty               xxcoi_storage_information.ship_summary_qty%TYPE               -- �o�ɐ��ʑ��o����
    , check_summary_qty              xxcoi_storage_information.check_summary_qty%TYPE              -- �m�F���ʑ��o����
    , material_transaction_unset_qty xxcoi_storage_information.material_transaction_unset_qty%TYPE -- ���ގ�����A�g����
  );
--
  TYPE gt_storage_info_ttype IS TABLE OF gr_storage_info_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_id                      mtl_parameters.organization_id%TYPE; -- �݌ɑg�DID
  gd_date                        DATE;                                -- �Ɩ����t
  -- �J�E���^
  gn_slip_loop_cnt               NUMBER; -- �`�[�P�ʃ��[�v�J�E���^
  gn_storage_info_loop_cnt       NUMBER; -- ���ɏ��P�ʃ��[�v�J�E���^
  gn_storage_info_cnt            NUMBER; -- ���ɏ��P�ʃJ�E���^
  -- PL/SQL�\
  gt_slip_num_tab                gt_slip_num_ttype;
  gt_storage_info_tab            gt_storage_info_ttype;
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
    -- �v���t�@�C��
    cv_prf_org_code                CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE'; -- �݌ɑg�D�R�[�h
--
    -- *** ���[�J���ϐ� ***
    lt_org_code                    mtl_parameters.organization_code%TYPE; -- �݌ɑg�D�R�[�h
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
    --==============================================================
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���O�o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => cv_no_para_msg
                  );
    -- ���b�Z�[�W�o��
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
    -- ===============================
    -- �v���t�@�C���擾�F�݌ɑg�D�R�[�h
    -- ===============================
    lt_org_code := fnd_profile.value( cv_prf_org_code );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( lt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_code_get_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_code );
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_org_id_get_err_msg
                     , iv_token_name1  => cv_tkn_org_code
                     , iv_token_value1 => lt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_date := xxccp_common_pkg2.get_process_date;
    -- ���ʊ֐��̖߂�l��NULL�̏ꍇ
    IF ( gd_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_process_date_get_err_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN
    -- *** ���ʊ֐���O�n���h�� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : get_slip_num
   * Description      : �Ώۓ`�[No�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_slip_num(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_slip_num'; -- �v���O������
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
    -- �`�[�P�ʎ擾
    CURSOR slip_num_cur
    IS
      SELECT  DISTINCT xsi.slip_num     AS slip_num              -- �`�[No
      FROM    xxcoi_storage_information xsi                      -- ���ɏ��ꎞ�\
      WHERE   xsi.auto_store_check_flag = cv_flag_on             -- �������Ɋm�F�t���O
      AND     xsi.summary_data_flag     = cv_flag_on             -- �T�}���[�f�[�^�t���O
      AND     xsi.ship_summary_qty      <> xsi.check_summary_qty -- �o�ɐ��ʑ��o���� <> �m�F���ʑ��o����
      AND     TRUNC( xsi.slip_date )    <= gd_date               -- �`�[���t
      ORDER BY xsi.slip_num
    ;
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
    -- �J�[�\���I�[�v��
    OPEN slip_num_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH slip_num_cur BULK COLLECT INTO gt_slip_num_tab;
--
    -- �Ώی����Z�b�g
    gn_target_cnt := gt_slip_num_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE slip_num_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( slip_num_cur%ISOPEN ) THEN
        CLOSE slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_slip_num;
--
  /**********************************************************************************
   * Procedure Name   : get_storage_info
   * Description      : ���ɏ��擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_storage_info(
    gn_slip_loop_cnt IN  NUMBER,       --   �`�[�P�ʃ��[�v�J�E���^
    ov_errbuf        OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode       OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_storage_info'; -- �v���O������
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
    -- ���ɏ��P�ʎ擾
    CURSOR storage_info_cur
    IS
      SELECT
             xsi.transaction_id                 AS transaction_id                     -- ���ID
           , xsi.slip_num                       AS slip_num                           -- �`�[No
           , xsi.slip_date                      AS slip_date                          -- �`�[���t
           , xsi.ship_case_qty                  AS ship_case_qty                      -- �o�ɐ��ʃP�[�X��
           , xsi.ship_singly_qty                AS ship_singly_qty                    -- �o�ɐ��ʃo����
           , xsi.ship_summary_qty               AS ship_summary_qty                   -- �o�ɐ��ʑ��o����
           , xsi.check_summary_qty              AS check_summary_qty                  -- �m�F���ʑ��o����
           , xsi.material_transaction_unset_qty AS material_transaction_unset_qty     -- ���ގ�����A�g����
      FROM 
             xxcoi_storage_information          xsi                                   -- ���ɏ��ꎞ�\
      WHERE 
             xsi.slip_num                       = gt_slip_num_tab( gn_slip_loop_cnt ) -- �`�[No
      AND    xsi.summary_data_flag              = cv_flag_on                          -- �T�}���[�f�[�^�t���O
      AND    xsi.ship_summary_qty               <> xsi.check_summary_qty              -- �o�ɐ��ʑ��o���� <> �m�F���ʑ��o����
      AND    TRUNC( xsi.slip_date )             <= gd_date                            -- �`�[���t
    ;
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
    -- �J�[�\���I�[�v��
    OPEN storage_info_cur;
--
    -- ���R�[�h�ǂݍ���
    FETCH storage_info_cur BULK COLLECT INTO gt_storage_info_tab;
--
    -- �Ώی����Z�b�g
    gn_storage_info_cnt := gt_storage_info_tab.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE storage_info_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( storage_info_cur%ISOPEN ) THEN
        CLOSE storage_info_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_storage_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_org_acct_period
   * Description      : ��v���ԃ`�F�b�N���� (A-5)
   ***********************************************************************************/
  PROCEDURE chk_org_acct_period(
    gn_slip_loop_cnt         IN   NUMBER,    -- �`�[�P�ʃ��[�v�J�E���^
    gn_storage_info_loop_cnt IN   NUMBER,    -- ���ɏ��P�ʃ��[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_org_acct_period'; -- �v���O������
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
    -- �݌ɉ�v���ԃ`�F�b�N
    lb_chk_result                BOOLEAN; -- �X�e�[�^�X
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
    -- �ϐ�������
    lb_chk_result := TRUE;
--
    -- ===============================
    -- �݌ɉ�v���ԃ`�F�b�N
    -- ===============================
    xxcoi_common_pkg.org_acct_period_chk(
        in_organization_id => gt_org_id                                                 -- �݌ɑg�DID
      , id_target_date     => gt_storage_info_tab( gn_storage_info_loop_cnt ).slip_date -- �Ώۓ�
      , ob_chk_result      => lb_chk_result                                             -- �`�F�b�N����
      , ov_errbuf          => lv_errbuf                                                 -- �G���[���b�Z�[�W
      , ov_retcode         => lv_retcode                                                -- ���^�[���E�R�[�h
      , ov_errmsg          => lv_errmsg                                                 -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- �߂�l�̃X�e�[�^�X��FALSE�̏ꍇ
    IF ( lb_chk_result = FALSE ) THEN
      RAISE acct_period_close_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- �݌ɉ�v���ԃN���[�Y�G���[
    WHEN acct_period_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application_short_name
                     , iv_name         => cv_acct_period_close_err_msg
                     , iv_token_name1  => cv_tkn_den_no
                     , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                     , iv_token_name2  => cv_tkn_entry_date
                     , iv_token_value2 => TO_CHAR( gt_storage_info_tab( gn_storage_info_loop_cnt ).slip_date, 'YYYY/MM/DD' )
                   );
      lv_errbuf  := lv_errmsg;
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END chk_org_acct_period;
--
  /**********************************************************************************
   * Procedure Name   : get_lock
   * Description      : ���b�N�擾���� (A-6)
   ***********************************************************************************/
  PROCEDURE get_lock(
    gn_slip_loop_cnt         IN   NUMBER,    -- �`�[�P�ʃ��[�v�J�E���^
    gn_storage_info_loop_cnt IN   NUMBER,    -- ���ɏ��P�ʃ��[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lock'; -- �v���O������
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
    -- ���ɏ��ꎞ�\���b�N�擾
    CURSOR xsi_slip_num_cur
    IS
      SELECT  xsi.slip_num              AS slip_num                                                      -- �`�[No
      FROM    xxcoi_storage_information xsi                                                              -- ���ɏ��ꎞ�\
      WHERE   xsi.transaction_id        = gt_storage_info_tab( gn_storage_info_loop_cnt ).transaction_id -- ���ID
      FOR UPDATE OF xsi.slip_num NOWAIT
    ;
--
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
    -- �J�[�\���I�[�v��
    OPEN xsi_slip_num_cur;
--
    -- �J�[�\���N���[�Y
    CLOSE xsi_slip_num_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_table_lock_err_msg
                      , iv_token_name1  => cv_tkn_den_no
                      , iv_token_value1 => gt_slip_num_tab( gn_slip_loop_cnt )
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\����OPEN���Ă���ꍇ
      IF ( xsi_slip_num_cur%ISOPEN ) THEN
        CLOSE xsi_slip_num_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lock;
--
  /**********************************************************************************
   * Procedure Name   : upd_storage_info_tab
   * Description      : �������Ɋm�F���� (A-7)
   ***********************************************************************************/
  PROCEDURE upd_storage_info_tab(
    gn_storage_info_loop_cnt IN   NUMBER,    -- �q�փf�[�^���[�v�J�E���^
    ov_errbuf                OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT  VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_storage_info_tab'; -- �v���O������
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
    -- ���o�Ɉꎞ�\�X�V
    UPDATE xxcoi_storage_information xsi                                                                                -- ���ɏ��ꎞ�\
    SET    xsi.check_case_qty                 = gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_case_qty           -- �m�F���ʃP�[�X��
         , xsi.check_singly_qty               = gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_singly_qty         -- �m�F���ʃo����
         , xsi.check_summary_qty              = gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_summary_qty        -- �m�F���ʑ��o����
         , xsi.material_transaction_unset_qty = ( ( gt_storage_info_tab( gn_storage_info_loop_cnt ).material_transaction_unset_qty -- ���ގ�����A�g����
                                                  + gt_storage_info_tab( gn_storage_info_loop_cnt ).ship_summary_qty )  -- �o�ɐ��ʑ��o����
                                                  - gt_storage_info_tab( gn_storage_info_loop_cnt ).check_summary_qty ) -- �m�F���ʑ��o����
         , xsi.store_check_flag               = cv_flag_on                                                              -- ���Ɋm�F�t���O
         , xsi.material_transaction_set_flag  = cv_flag_off                                                             -- ���ގ���A�g�σt���O
         , xsi.last_updated_by                = cn_last_updated_by                                                      -- �ŏI�X�V��
         , xsi.last_update_date               = cd_last_update_date                                                     -- �ŏI�X�V��
         , xsi.last_update_login              = cn_last_update_login                                                    -- �ŏI�X�V���O�C��
         , xsi.request_id                     = cn_request_id                                                           -- �v��ID
         , xsi.program_application_id         = cn_program_application_id                                               -- �v���O�����A�v���P�[�V����ID
         , xsi.program_id                     = cn_program_id                                                           -- �v���O����ID
         , xsi.program_update_date            = cd_program_update_date                                                  -- �v���O�����X�V��
    WHERE  xsi.transaction_id                 = gt_storage_info_tab( gn_storage_info_loop_cnt ).transaction_id          -- ���ID
    ;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END upd_storage_info_tab;
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
--
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
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۓ`�[No�擾���� (A-2)
    -- ===============================
    get_slip_num(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �`�[No�擾������0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
--
    -- �`�[�P�ʃ��[�v�J�n
    <<gt_slip_num_tab_loop>>
    FOR gn_slip_loop_cnt IN 1 .. gn_target_cnt LOOP
--
      -- ===============================
      -- �Z�[�u�|�C���g�ݒ� (A-3)
      -- ===============================
      SAVEPOINT slip_num_point;
--
      -- ===============================
      -- ���ɏ��擾���� (A-4)
      -- ===============================
      get_storage_info(
          gn_slip_loop_cnt => gn_slip_loop_cnt -- �`�[�P�ʃ��[�v�J�E���^
        , ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���ɏ��P�ʃ��[�v�J�n
      <<gt_storage_info_tab_loop>>
      FOR gn_storage_info_loop_cnt IN 1 .. gn_storage_info_cnt LOOP
--
        -- ===============================
        -- ��v���ԃ`�F�b�N���� (A-5)
        -- ===============================
        chk_org_acct_period(
            gn_slip_loop_cnt         => gn_slip_loop_cnt         -- �`�[�P�ʃ��[�v�J�E���^
          , gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- ���ɏ��P�ʃ��[�v�J�E���^
          , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
          ROLLBACK TO SAVEPOINT slip_num_point;
          -- ���ɏ��P�ʃ��[�v�𔲂���
          EXIT gt_storage_info_tab_loop;
        END IF;
--
        -- ===============================
        -- ���b�N�擾���� (A-6)
        -- ===============================
        get_lock(
            gn_slip_loop_cnt         => gn_slip_loop_cnt         -- �`�[�P�ʃ��[�v�J�E���^
          , gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- ���ɏ��P�ʃ��[�v�J�E���^
          , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
          ROLLBACK TO SAVEPOINT slip_num_point;
          -- ���ɏ��P�ʃ��[�v�𔲂���
          EXIT gt_storage_info_tab_loop;
        END IF;
--
        -- ===============================
        -- �������Ɋm�F���� (A-7)
        -- ===============================
        upd_storage_info_tab(
            gn_storage_info_loop_cnt => gn_storage_info_loop_cnt -- ���ɏ��P�ʃ��[�v�J�E���^
          , ov_errbuf                => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
          , ov_retcode               => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
          , ov_errmsg                => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP gt_storage_info_tab_loop;
--
      -- �X�e�[�^�X������̏ꍇ
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ��������
        gn_normal_cnt := gn_normal_cnt + 1;
      -- �X�e�[�^�X���x���̏ꍇ
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- �G���[����
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
--
    END LOOP gt_slip_num_tab_loop;
--
  EXCEPTION
    -- �擾����0��
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application_short_name
                      , iv_name         => cv_no_data_msg
                    );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_normal;
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => ov_errmsg --�G���[���b�Z�[�W
      );
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
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
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
        lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
        , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    -- �I���X�e�[�^�X�u�G���[�v�̏ꍇ�A�Ώی����E���팏���̏������ƃG���[�����̃Z�b�g
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_appl_short_name
--                    , iv_name         => cv_skip_rec_msg
--                    , iv_token_name1  => cv_cnt_token
--                    , iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- �I���X�e�[�^�X���u�G���[�v�ȊO���A�G���[������1���ȏ゠��ꍇ�A�I���X�e�[�^�X�u�x���v�ɂ���
    IF ( ( lv_retcode <> cv_status_error ) AND ( gn_error_cnt > 0 ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    --�I�����b�Z�[�W
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOI001A04C;
/
