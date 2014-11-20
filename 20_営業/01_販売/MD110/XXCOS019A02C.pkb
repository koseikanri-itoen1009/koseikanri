CREATE OR REPLACE PACKAGE BODY XXCOS019A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS019A02C(body)
 * Description      : �N���[�Y����Ă��Ȃ��󒍂̃N���[�Y�����쐬���܂��B
 * MD.050           : ���N���[�Y�󒍎����N���[�Y (MD050_COS_019_A02)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_data               �Ώۏ��擾(A-2)
 *  ins_order_close        �󒍃N���[�Y�Ώۏ��o�^(A-3)
 *  upd_flag               �̔����јA�g�σt���O�X�V(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/04/17    1.0   SCSK K.Nakamura  �V�K�쐬
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  global_lock_expt          EXCEPTION; -- ���b�N��O
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  warn_expt                 EXCEPTION; -- �x��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS019A02C'; -- �p�b�P�[�W��
  cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';        -- �A�v���P�[�V������
  cv_appl_short_name        CONSTANT VARCHAR2(5)   := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  -- ���b�Z�[�W
  cv_msg_no_param           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_lock_err           CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001'; -- ���b�N�G���[
  cv_msg_no_data            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^����
  cv_msg_profile_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  cv_msg_insert_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010'; -- �f�[�^�o�^�G���[
  cv_msg_update_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011'; -- �f�[�^�X�V�G���[
  cv_msg_process_date_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  cv_msg_profile_miss1_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14401'; -- �v���t�@�C���ݒ�l�s���G���[1
  cv_msg_profile_miss2_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14402'; -- �v���t�@�C���ݒ�l�s���G���[2
  cv_msg_order_source_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14403'; -- �󒍃\�[�X�擾�G���[
  -- ���b�Z�[�W������
  cv_edi_order_source       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00157'; -- XXCOS:EDI�󒍃\�[�X
  cv_org                    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047'; -- MO:�c�ƒP��
  cv_order_close_from       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14404'; -- XXCOS:��CLOSED�Ώۊ���FROM
  cv_order_close_to         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14405'; -- XXCOS:��CLOSED�Ώۊ���TO
  cv_order_lines_all        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14406'; -- �󒍖��׃e�[�u��
  cv_xxcos_order_close      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14407'; -- �󒍃N���[�Y�Ώۏ��e�[�u��
  cv_line_id                CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-14408'; -- �󒍖���ID�F
  -- �g�[�N��
  cv_tkn_profile            CONSTANT VARCHAR2(20)  := 'PROFILE';           -- �v���t�@�C����
  cv_tkn_profile1           CONSTANT VARCHAR2(20)  := 'PROFILE1';          -- �v���t�@�C����
  cv_tkn_profile2           CONSTANT VARCHAR2(20)  := 'PROFILE2';          -- �v���t�@�C����
  cv_tkn_order_source_name  CONSTANT VARCHAR2(20)  := 'ORDER_SOURCE_NAME'; -- �󒍃\�[�X��
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';             -- �e�[�u����
  cv_tkn_table_name         CONSTANT VARCHAR2(20)  := 'TABLE_NAME';        -- �e�[�u����
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';          -- �L�[����
  -- �v���t�@�C��
  cv_prf_order_close_from   CONSTANT VARCHAR2(30)  := 'XXCOS1_OM_CLOSED_FROM';   -- XXCOS:��CLOSED�Ώۊ���FROM
  cv_prf_order_close_to     CONSTANT VARCHAR2(30)  := 'XXCOS1_OM_CLOSED_TO';     -- XXCOS:��CLOSED�Ώۊ���TO
  cv_prf_edi_order_source   CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_ORDER_SOURCE'; -- XXCOS:EDI�󒍃\�[�X
  cv_prf_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                  -- MO:�c�ƒP��
  -- �N�C�b�N�R�[�h�^�C�v
  cv_lookup_hokan_type      CONSTANT VARCHAR2(30)  := 'XXCOS1_HOKAN_TYPE_MST_019_A02'; -- �ۊǏꏊ���ޓ���}�X�^_019_A02
  -- �N�C�b�N�R�[�h
  cv_lookup_hokan_code      CONSTANT VARCHAR2(30)  := 'XXCOS_019_A02%';
  -- �X�e�[�^�X
  cv_yes                    CONSTANT VARCHAR2(1)   := 'Y';      -- �t���O�FY
  cv_order_close_status     CONSTANT VARCHAR2(1)   := 'N';      -- �󒍃N���[�Y�e�[�u���X�e�[�^�X�F������
  cv_global_attribute5      CONSTANT VARCHAR2(1)   := 'Z';      -- �̔����јA�g�σt���O�F���A�g
  cv_booked                 CONSTANT VARCHAR2(10)  := 'BOOKED'; -- �󒍃X�e�[�^�X�F�L����
  --����R�[�h
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_edi_order_source_id    NUMBER         DEFAULT NULL; -- XXCOS:EDI�󒍃\�[�X
  gn_org_id                 NUMBER         DEFAULT NULL; -- �c�ƒP��
  gd_process_date           DATE           DEFAULT NULL; -- �Ɩ����t
  gd_order_close_date_max   DATE           DEFAULT NULL; -- XXCOS:��CLOSED�Ώۊ���FROM
  gd_order_close_date_min   DATE           DEFAULT NULL; -- XXCOS:��CLOSED�Ώۊ���TO
  gv_msg1                   VARCHAR2(2000) DEFAULT NULL; -- ���b�Z�[�W�p1
  gv_msg2                   VARCHAR2(2000) DEFAULT NULL; -- ���b�Z�[�W�p2
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h��`
  -- ===============================
  TYPE line_id_ttype IS TABLE OF oe_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
  gt_line_id_tab            line_id_ttype;
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
    -- *** ���[�J���ϐ� ***
    lv_edi_order_source     VARCHAR2(10) DEFAULT NULL; -- XXCOS:EDI�󒍃\�[�X
    ln_order_close_from     NUMBER       DEFAULT NULL; -- XXCOS:��CLOSED�Ώۊ���FROM
    ln_order_close_to       NUMBER       DEFAULT NULL; -- XXCOS:��CLOSED�Ώۊ���TO
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    -- =====================================================
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
    -- =====================================================
    -- �Ɩ��������t�擾
    -- =====================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application
                    ,iv_name        => cv_msg_process_date_err
                   );
      RAISE warn_expt;
      --
    END IF;
--
    -- =====================================================
    -- �v���t�@�C���̎擾(XXCOS:��CLOSED�Ώۊ���FROM)
    -- =====================================================
    BEGIN
      ln_order_close_from := TO_NUMBER( FND_PROFILE.VALUE(cv_prf_order_close_from) );
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_order_close_from
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => gv_msg1
                     );
        RAISE warn_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( ln_order_close_from IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_from
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
    -- �v���t�@�C���l���}�C�i�X�l�̏ꍇ
    IF ( ln_order_close_from < 0 ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_from
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_miss1_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- �v���t�@�C���̎擾(XXCOS:��CLOSED�Ώۊ���TO)
    -- =====================================================
    BEGIN
      ln_order_close_to := TO_NUMBER( FND_PROFILE.VALUE(cv_prf_order_close_to) );
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_order_close_to
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_profile_err
                       ,iv_token_name1  => cv_tkn_profile
                       ,iv_token_value1 => gv_msg1
                     );
        RAISE warn_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( ln_order_close_to IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_to
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
    -- �v���t�@�C���l���}�C�i�X�l�̏ꍇ
    IF ( ln_order_close_to < 0 ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_to
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_miss1_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- �v���t�@�C���l���s���̏ꍇ
    IF ( ln_order_close_from < ln_order_close_to ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_to
                   );
      gv_msg2   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_order_close_from
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_miss2_err
                     ,iv_token_name1  => cv_tkn_profile1
                     ,iv_token_value1 => gv_msg1
                     ,iv_token_name2  => cv_tkn_profile2
                     ,iv_token_value2 => gv_msg2
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- �v���t�@�C���̎擾(XXCOS:EDI�󒍃\�[�X)
    -- =====================================================
    lv_edi_order_source := FND_PROFILE.VALUE(cv_prf_edi_order_source);
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( lv_edi_order_source IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_edi_order_source
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- �v���t�@�C���̎擾(MO:�c�ƒP��)
    -- =====================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE(cv_prf_org_id) );
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_org_id IS NULL ) THEN
      gv_msg1   := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_org
                   );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => gv_msg1
                   );
      RAISE warn_expt;
    END IF;
--
    -- =====================================================
    -- �󒍃N���[�Y�Ώ۔N�����̎擾
    -- =====================================================
    gd_order_close_date_max := gd_process_date - ln_order_close_from;
    gd_order_close_date_min := gd_process_date - ln_order_close_to;
--
    -- =====================================================
    -- �󒍃\�[�XID�̎擾
    -- =====================================================
    BEGIN
      SELECT oos.order_source_id  order_source_id -- �󒍃\�[�XID
      INTO   gn_edi_order_source_id
      FROM   oe_order_sources     oos             -- �󒍃\�[�X
      WHERE  oos.name = lv_edi_order_source       -- ����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_order_source_err
                       ,iv_token_name1  => cv_tkn_order_source_name
                       ,iv_token_value1 => lv_edi_order_source
                     );
        RAISE warn_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �x����O�n���h�� ****
    WHEN warn_expt THEN
      lv_errbuf   := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
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
   * Procedure Name   : get_data
   * Description      : �Ώۏ��擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
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
    -- =====================================================
    -- �Ώێ擾
    -- =====================================================
    SELECT /*+ USE_NL(ooha oola msi)
            */
           oola.line_id               line_id  -- �󒍖���ID
    BULK COLLECT INTO gt_line_id_tab
    FROM   oe_order_headers_all       ooha     -- �󒍃w�b�_�e�[�u��
         , oe_order_lines_all         oola     -- �󒍖��׃e�[�u��
         , mtl_secondary_inventories  msi      -- �ۊǏꏊ�}�X�^
    WHERE  ooha.header_id          = oola.header_id
    AND    ooha.org_id             = oola.org_id
    AND    oola.subinventory       = msi.secondary_inventory_name
    AND    oola.ship_from_org_id   = msi.organization_id
    AND    ooha.org_id             = gn_org_id
    AND    ooha.order_source_id    = gn_edi_order_source_id
    AND    ooha.flow_status_code   = cv_booked
    AND    oola.flow_status_code   = cv_booked
    AND    oola.request_date      >= gd_order_close_date_max
    AND    oola.request_date      <= gd_order_close_date_min
    AND EXISTS (
           SELECT 1                   attribute13
           FROM   fnd_lookup_values   flv      -- �N�C�b�N�R�[�h
           WHERE  flv.lookup_type  = cv_lookup_hokan_type
           AND    flv.lookup_code  LIKE cv_lookup_hokan_code
           AND    flv.meaning      = msi.attribute13
           AND    gd_process_date >= NVL( flv.start_date_active, gd_process_date )
           AND    gd_process_date <= NVL( flv.end_date_active, gd_process_date )
           AND    flv.enabled_flag = cv_yes
           AND    flv.language     = ct_lang
               )
    FOR UPDATE OF oola.line_id NOWAIT
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** ���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application
                      ,iv_name        => cv_order_lines_all
                    );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_lock_err
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => gv_out_msg
                   );
      --
      lv_errbuf := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_order_close
   * Description      : �󒍃N���[�Y�Ώۏ��o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_order_close(
    it_line_id    IN  oe_order_lines_all.line_id%TYPE,  -- �󒍖���ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_order_close'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
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
    BEGIN
      -- =====================================================
      -- �󒍃N���[�Y�Ώۏ��o�^
      -- =====================================================
      INSERT INTO xxcos_order_close(
         order_line_id              -- �󒍖���ID
        ,process_status             -- �����X�e�[�^�X
        ,process_date               -- ������
        ,created_by                 -- �쐬��
        ,creation_date              -- �쐬��
        ,last_updated_by            -- �ŏI�X�V��
        ,last_update_date           -- �ŏI�X�V��
        ,last_update_login          -- �ŏI�X�V���O�C��
        ,request_id                 -- �v��ID
        ,program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                 -- �R���J�����g�E�v���O����ID
        ,program_update_date        -- �v���O�����X�V��
      )VALUES(
         it_line_id                 -- �󒍖���ID
        ,cv_order_close_status      -- �����X�e�[�^�X
        ,gd_process_date            -- ������
        ,cn_created_by              -- �쐬��
        ,cd_creation_date           -- �쐬��
        ,cn_last_updated_by         -- �ŏI�X�V��
        ,cd_last_update_date        -- �ŏI�X�V��
        ,cn_last_update_login       -- �ŏI�X�V���O�C��
        ,cn_request_id              -- �v��ID
        ,cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,cn_program_id              -- �R���J�����g�E�v���O����ID
        ,cd_program_update_date     -- �v���O�����X�V��
      );
    EXCEPTION
      -- *** �o�^��O�n���h�� ****
      WHEN OTHERS THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_xxcos_order_close
                     );
        gv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_line_id
                       ,iv_token_name1  => cv_tkn_key_data
                       ,iv_token_value1 => TO_CHAR( it_line_id )
                     );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_insert_err
                       ,iv_token_name1  => cv_tkn_table_name
                       ,iv_token_value1 => gv_msg1
                       ,iv_token_name2  => cv_tkn_key_data
                       ,iv_token_value2 => gv_msg2
                     );
        --
        ov_errmsg   := lv_errmsg;
        ov_errbuf   := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ov_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ov_errbuf
        );
    END;
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
  END ins_order_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_flag
   * Description      : �̔����јA�g�σt���O�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE upd_flag(
    it_line_id    IN  oe_order_lines_all.line_id%TYPE,  -- �󒍖���ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_flag'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
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
    BEGIN
      -- =====================================================
      -- �̔����јA�g�σt���O�X�V
      -- =====================================================
      UPDATE oe_order_lines_all oola
      SET    oola.global_attribute5 = cv_global_attribute5
      WHERE  oola.line_id           = it_line_id
      ;
    EXCEPTION
      -- *** �X�V��O�n���h�� ****
      WHEN OTHERS THEN
        gv_msg1   := xxccp_common_pkg.get_msg(
                        iv_application => cv_application
                       ,iv_name        => cv_order_lines_all
                     );
        gv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_line_id
                       ,iv_token_name1  => cv_tkn_key_data
                       ,iv_token_value1 => TO_CHAR( it_line_id )
                     );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_update_err
                       ,iv_token_name1  => cv_tkn_table_name
                       ,iv_token_value1 => gv_msg1
                       ,iv_token_name2  => cv_tkn_key_data
                       ,iv_token_value2 => gv_msg2
                     );
        --
        ov_errmsg   := lv_errmsg;
        ov_errbuf   := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ov_errmsg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ov_errbuf
        );
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
      ov_retcode := cv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_flag;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.�Ώۏ��擾
    -- ===============================
    get_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    <<ins_upd_loop>>
    FOR i IN 1..gt_line_id_tab.COUNT LOOP
      -- �Z�[�u�|�C���g���s
      SAVEPOINT order_close;
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
      -- ������
      lv_retcode := cv_status_normal;
      -- ===============================
      -- A-3.�󒍃N���[�Y�Ώۏ��o�^
      -- ===============================
      ins_order_close(
        gt_line_id_tab(i), -- �󒍖���ID
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================
        -- A-4.�̔����э쐬�σt���O�X�V
        -- ===============================
        upd_flag(
          gt_line_id_tab(i), -- �󒍖���ID
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        --
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- �Z�[�u�|�C���g�܂Ń��[���o�b�N
          ROLLBACK TO SAVEPOINT order_close;
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
    --
    END LOOP ins_upd_loop;
--
    -- �Ώی����Ȃ�
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_no_data
                   );
      --
      lv_errbuf := lv_errmsg;
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
    -- �x�����������݂���ꍇ�A�I���X�e�[�^�X���x����
    ELSIF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00039'; -- �x���������b�Z�[�W
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
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
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
END XXCOS019A02C;
/
