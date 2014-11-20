CREATE OR REPLACE PACKAGE BODY APPS.xxcso_route_common_pkg  
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_ROUTE_COMMON_PKG(body)
 * Description      : ROUTE�֘A���ʊ֐�
 * MD.050           : XXCSO_View�E���ʊ֐��ꗗ
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  validate_route_no      F     B     ���[�g�m���Ó����`�F�b�N
 *  distribute_sales_plan  P     -     ����v����ʔz������
 *  calc_visit_times       P     -     ���[�g�m���K��񐔎Z�o����
 *  validate_route_no_p    P     -     ���[�g�m���Ó����`�F�b�N(�v���V�[�W��)
 *  isCustomerVendor       F     B     �u�c�ƑԔ���֐�
 *  calc_visit_times_f     F     N     ���[�g�m���K��񐔎Z�o����(�t�@���N�V����)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/16    1.0   Kenji.Sai       �V�K�쐬
 *  2008/11/18    1.0   Kenji.Sai       ����v����ʔz�������쐬
 *  2008/12/12    1.0   Kazuo.Satomura  ���[�g�m���K��񐔎Z�o�����쐬
 *  2008/12/16    1.0   Kenji.Sai       ����v����ʔz�������Ƀp�����[�^�`�F�b�N�����ǉ�
 *  2008/12/17    1.0   Noriyuki.Yabuki ���[�g�m���Ó����`�F�b�N�쐬
 *  2009/01/09    1.0   Kazumoto.Tomio  ���[�g�m���Ó����`�F�b�N(�v���V�[�W��)�쐬
 *  2009/01/20    1.0   T.Maruyama      �u�c�ƑԔ���֐��ǉ�
 *  2009/02/19    1.0   Mio.Maruyama    ���[�g�m���K��񐔎Z�o����(�t�@���N�V����)�ǉ�
 *  2009/02/27    1.0   Kazuo.Satomura  ����v����ʔz�����������Ή�
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'xxcso_route_common_pkg'; -- �p�b�P�[�W��
  cb_true          CONSTANT BOOLEAN := TRUE;
  cb_false         CONSTANT BOOLEAN := FALSE;  
  cv_week_1        CONSTANT VARCHAR2(100) := '���j��';
  cv_week_2        CONSTANT VARCHAR2(100) := '�Ηj��';
  cv_week_3        CONSTANT VARCHAR2(100) := '���j��';
  cv_week_4        CONSTANT VARCHAR2(100) := '�ؗj��';
  cv_week_5        CONSTANT VARCHAR2(100) := '���j��';
  cv_week_6        CONSTANT VARCHAR2(100) := '�y�j��';
  cv_week_7        CONSTANT VARCHAR2(100) := '���j��';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
-- 
  /**********************************************************************************
   * Function Name    : validate_route_no                                                       
   * Description      : ���[�g�m���Ó����`�F�b�N
   ***********************************************************************************/
  FUNCTION validate_route_no(
    iv_route_number  IN  VARCHAR2,    -- ���[�g�m��
    ov_error_reason  OUT VARCHAR2     -- �G���[���R
  ) RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_route_no';  -- �v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sales_appl_short_name  CONSTANT VARCHAR2(5)  := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
    cv_msg_number_01          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00432';  -- ���p�����`�F�b�N�G���[
    cv_msg_number_02          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00433';  -- �����`�F�b�N�G���[
    cv_msg_number_03          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00434';  -- �R���ڃ`�F�b�N�G���[
    cv_msg_number_04          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00435';  -- �R,�S���ڐ������`�F�b�N�G���[
    cv_msg_number_05          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00436';  -- �T���ڃ`�F�b�N�G���[
    cv_msg_number_06          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00437';  -- �U���ڃ`�F�b�N�G���[
    cv_msg_number_07          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00438';  -- �U,�V���ڐ������`�F�b�N�G���[
    cv_msg_number_08          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00439';  -- �R,�S���ڃ`�F�b�N�G���[
    cv_msg_number_09          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00440';  -- �U,�V���ڃ`�F�b�N�G���[
    cv_msg_number_10          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00441';  -- �R,�S���ځA�U,�V���ڃ`�F�b�N�G���[
    cv_msg_number_11          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00442';  -- ���̑��ڋq�`�F�b�N�G���[
    cv_msg_number_12          CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00443';  -- �T�P��ȏ�ڋq�`�F�b�N�G���[
    cv_visit_type_month       CONSTANT VARCHAR2(2)  := '5-';       -- �K��^�C�v�����P��
    cv_visit_type_season      CONSTANT VARCHAR2(2)  := '6-';       -- �K��^�C�v���G�ߒP��
    cv_visit_type_other       CONSTANT VARCHAR2(2)  := '9-';       -- �K��^�C�v�����̑�
    cv_zero                   CONSTANT VARCHAR2(1)  := '0';        -- �Œ�l'0'
    cv_third_min              CONSTANT VARCHAR2(1)  := '1';        -- �R���ڂ�MIN�l�i�T�P��ȉ��ڋq�j
    cv_third_forth_max        CONSTANT VARCHAR2(1)  := '5';        -- �R,�S���ڂ�MAX�l�i�T�P��ȉ��ڋq�j
    cv_sixth_min              CONSTANT VARCHAR2(1)  := '1';        -- �U���ڂ�MIN�l�i�T�P��ȉ��ڋq�j
    cv_sixth_seventh_max      CONSTANT VARCHAR2(1)  := '7';        -- �U,�V���ڂ�MAX�l�i�T�P��ȉ��ڋq�j
    cv_season_min             CONSTANT VARCHAR2(2)  := '01';       -- �R,�S���ڂ�MIN�l�i�G�ߎ���ڋq�j
    cv_season_max             CONSTANT VARCHAR2(2)  := '12';       -- �R,�S���ڂ�MAX�l�i�G�ߎ���ڋq�j
    cv_search_val             CONSTANT VARCHAR2(3)  := '123';      -- �����Ώە����i�T�P��ȏ�i�j���P�ʁj�ڋqcheck�p�j
    cv_trans_val              CONSTANT VARCHAR2(3)  := '000';      -- �u���Ώە����i�T�P��ȏ�i�j���P�ʁj�ڋqcheck�p�j
    cv_route_number_other     CONSTANT VARCHAR2(7)  := '9-00-00';  -- ���̑��ڋq�̏ꍇ�̃��[�g�m��
    cv_route_number_day_chk   CONSTANT VARCHAR2(7)  := '0000000';  -- �T�P��ȏ�i�j���P�ʁj�ڋqcheck�p
--
    -- *** ���[�J���ϐ� ***
    lv_route_number           VARCHAR2(7);    -- ���[�g�m���ޔ�p
    ln_route_number_length    NUMBER;         -- ���[�g�m���̍��ڒ�
    lv_route_number_third     VARCHAR2(1);    -- ���[�g�m���R���ڊi�[�p
    lv_route_number_fourth    VARCHAR2(1);    -- ���[�g�m���S���ڊi�[�p
    lv_route_number_sixth     VARCHAR2(1);    -- ���[�g�m���U���ڊi�[�p
    lv_route_number_seventh   VARCHAR2(1);    -- ���[�g�m���V���ڊi�[�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
    -- �o�͍��ڂ̏�����
    ov_error_reason := NULL;
--
    -- ���̓p�����[�^�������͂̏ꍇ
    IF ( TRIM( iv_route_number ) IS NULL ) THEN
      RETURN cb_true;
      --
    END IF;
--
    -- ���[�g�m���̍��ڒ����擾
    ln_route_number_length := LENGTHB( iv_route_number );
    --
--
    -- ���[�g�m���i�n�C�t���͏����j�̔��p�����`�F�b�N�ŃG���[�̏ꍇ
    IF xxccp_common_pkg.chk_number( REPLACE( iv_route_number, '-' ) ) = cb_false THEN
      ov_error_reason := xxccp_common_pkg.get_msg(
                             iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_number_01          -- ���b�Z�[�W�R�[�h
                         );
      --
      RETURN cb_false;
    END IF;
    --
    -- ���[�g�m�����V���łȂ��ꍇ
    IF ln_route_number_length > 7
      OR ln_route_number_length < 7
    THEN
      ov_error_reason := xxccp_common_pkg.get_msg(
                             iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_number_02          -- ���b�Z�[�W�R�[�h
                         );
      --
      RETURN cb_false;
      --
    ELSE
      -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
      lv_route_number := iv_route_number;
      --
    END IF;
    --
--
    -- ���[�g�m���̐擪�Q����'5-'�̏ꍇ�i�T�P��ȉ��K��̏ꍇ�j
    IF ( SUBSTRB( lv_route_number, 1, 2 ) = cv_visit_type_month ) THEN
      -- ���[�g�m���̂R,�S,�U,�V���ڂ��擾
      lv_route_number_third   := SUBSTRB( lv_route_number, 3, 1 );
      lv_route_number_fourth  := SUBSTRB( lv_route_number, 4, 1 );
      lv_route_number_sixth   := SUBSTRB( lv_route_number, 6, 1 );
      lv_route_number_seventh := SUBSTRB( lv_route_number, 7, 1 );
      --
      -- ���[�g�m���̂R���ڂ�1�`5�܂ł̐����̏ꍇ
      IF lv_route_number_third >= cv_third_min
        AND lv_route_number_third <= cv_third_forth_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_03          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂R�E�S���ڐ������`�F�b�N
      -- �i���[�g�m���̂S���ڂ��R���ڂ��傫��5�ȉ��̐��� �܂��� 0�ł���ꍇ�j
      IF lv_route_number_fourth > lv_route_number_third
        AND lv_route_number_fourth <= cv_third_forth_max
          OR lv_route_number_fourth = cv_zero
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_04          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂T���ڂ�'-'�̏ꍇ
      IF SUBSTRB( lv_route_number, 5, 1 ) = '-' THEN
        NULL;
        --
      -- ���[�g�m���̂T���ڂ�'-'�łȂ��ꍇ
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_05          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂U���ڂ�1�`7�܂ł̐����̏ꍇ
      IF lv_route_number_sixth >= cv_sixth_min
        AND lv_route_number_sixth <= cv_sixth_seventh_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_06          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      --
      -- ���[�g�m���̂U�E�V���ڐ������`�F�b�N
      -- �i���[�g�m���̂V���ڂ��U���ڂ��傫��7�ȉ��̐��� �܂��� 0�ł���ꍇ�j
      IF lv_route_number_seventh > lv_route_number_sixth
        AND lv_route_number_seventh <= cv_sixth_seventh_max
          OR lv_route_number_seventh = cv_zero
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_07          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
--
    -- ���[�g�m���̐擪�Q����'6-'�̏ꍇ�i�G�ߎ���ڋq�̏ꍇ�j
    ELSIF ( SUBSTRB( lv_route_number, 1, 2 ) = cv_visit_type_season ) THEN
      -- ���[�g�m���̂R,�S���ڂ�'-'���܂܂�Ă��Ȃ�����
      IF SUBSTRB( lv_route_number, 3, 1 ) = '-'
        OR SUBSTRB( lv_route_number, 4, 1) = '-'
      THEN
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_08          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂R,�S���ڂ�01�`12�ł��邱��
      IF SUBSTRB( lv_route_number, 3, 2 ) >= cv_season_min
        AND SUBSTRB( lv_route_number, 3, 2 ) <= cv_season_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_08          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂T���ڂ�'-'�̏ꍇ
      IF SUBSTRB( lv_route_number, 5, 1 ) = '-' THEN
        NULL;
        --
      -- ���[�g�m���̂T���ڂ�'-'�łȂ��ꍇ
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_05          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂U,�V���ڂ�'-'���܂܂�Ă��Ȃ�����
      IF SUBSTRB( lv_route_number, 6, 1 ) = '-'
        OR SUBSTRB( lv_route_number, 7, 1) = '-'
      THEN
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_09          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂U,�V���ڂ�01�`12�ł��邱��
      IF SUBSTRB( lv_route_number, 6, 2 ) >= cv_season_min
        AND SUBSTRB( lv_route_number, 6, 2 ) <= cv_season_max
      THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_09          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
      -- ���[�g�m���̂R,�S���ڂƂU,�V���ڂ��قȂ邱�Ɓi�����ꍇ�̓G���[�j
      IF SUBSTRB( lv_route_number, 3, 2 ) = SUBSTRB( lv_route_number, 6, 2 ) THEN
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_10          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
--
    -- ���[�g�m���̐擪�Q����'9-'�̏ꍇ�i���̑��ڋq�̏ꍇ�j
    ELSIF ( SUBSTRB( lv_route_number, 1, 2 ) = cv_visit_type_other ) THEN
      -- '9-00-00'�ł��邱��
      IF lv_route_number = cv_route_number_other THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_11          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
--
    -- ���[�g�m���̐擪�Q����'5-','6-','9-'�ȊO�̏ꍇ
    ELSE
      -- �S�Ă̌���0�`3�̐����ł��邱��
      IF TRANSLATE( lv_route_number, cv_search_val, cv_trans_val ) = cv_route_number_day_chk THEN
        NULL;
        --
      ELSE
        ov_error_reason := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_number_12          -- ���b�Z�[�W�R�[�h
                           );
        --
        RETURN cb_false;
        --
      END IF;
      --
    END IF;
--
   -- �߂�l
    RETURN cb_true;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_error_reason := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      RETURN cb_false;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_route_no;
--
--
  /**********************************************************************************
   * Procedure Name   : distribute_sales_plan                                                       
   * Description      : ����v����ʔz������
   ***********************************************************************************/
  PROCEDURE distribute_sales_plan(
    iv_year_month                  IN VARCHAR2,                                            -- �N���i�����FYYYYMM�j
    it_sales_plan_amt              IN xxcso_in_sales_plan_month.sales_plan_amt%TYPE,       -- ���Ԕ���v����z
    it_route_number                IN xxcso_in_route_no.route_no%TYPE,                     -- ���[�g�m�� 
    on_day_on_month                OUT NUMBER,                                             -- ���Y���̓���
    on_visit_daytimes              OUT NUMBER,                                             -- ���Y���̖K�����
    ot_sales_plan_day_amt_1        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 1���ړ��ʔ���v����z
    ot_sales_plan_day_amt_2        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 2���ړ��ʔ���v����z
    ot_sales_plan_day_amt_3        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 3���ړ��ʔ���v����z
    ot_sales_plan_day_amt_4        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 4���ړ��ʔ���v����z
    ot_sales_plan_day_amt_5        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 5���ړ��ʔ���v����z
    ot_sales_plan_day_amt_6        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 6���ړ��ʔ���v����z
    ot_sales_plan_day_amt_7        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 7���ړ��ʔ���v����z
    ot_sales_plan_day_amt_8        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 8���ړ��ʔ���v����z
    ot_sales_plan_day_amt_9        OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 9���ړ��ʔ���v����z
    ot_sales_plan_day_amt_10       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 10���ړ��ʔ���v����z
    ot_sales_plan_day_amt_11       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 11���ړ��ʔ���v����z
    ot_sales_plan_day_amt_12       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 12���ړ��ʔ���v����z
    ot_sales_plan_day_amt_13       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 13���ړ��ʔ���v����z
    ot_sales_plan_day_amt_14       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 14���ړ��ʔ���v����z
    ot_sales_plan_day_amt_15       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 15���ړ��ʔ���v����z
    ot_sales_plan_day_amt_16       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 16���ړ��ʔ���v����z
    ot_sales_plan_day_amt_17       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 17���ړ��ʔ���v����z
    ot_sales_plan_day_amt_18       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 18���ړ��ʔ���v����z
    ot_sales_plan_day_amt_19       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 19���ړ��ʔ���v����z
    ot_sales_plan_day_amt_20       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 20���ړ��ʔ���v����z
    ot_sales_plan_day_amt_21       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 21���ړ��ʔ���v����z
    ot_sales_plan_day_amt_22       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 22���ړ��ʔ���v����z
    ot_sales_plan_day_amt_23       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 23���ړ��ʔ���v����z
    ot_sales_plan_day_amt_24       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 24���ړ��ʔ���v����z
    ot_sales_plan_day_amt_25       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 25���ړ��ʔ���v����z
    ot_sales_plan_day_amt_26       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 26���ړ��ʔ���v����z
    ot_sales_plan_day_amt_27       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 27���ړ��ʔ���v����z
    ot_sales_plan_day_amt_28       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 28���ړ��ʔ���v����z
    ot_sales_plan_day_amt_29       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 29���ړ��ʔ���v����z
    ot_sales_plan_day_amt_30       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 30���ړ��ʔ���v����z
    ot_sales_plan_day_amt_31       OUT xxcso_account_sales_plans.sales_plan_day_amt%TYPE,  -- 31���ړ��ʔ���v����z
    ov_errbuf                      OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode                     OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg                      OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'distribute_sales_plan'; -- �v���O������
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
    cv_sales_appl_short_name   CONSTANT VARCHAR2(5)  := 'XXCSO';            -- �A�v���P�[�V�����Z�k��
    cv_tkn_number_01           CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00325'; -- �p�����[�^�K�{�G���[
    cv_tkn_number_02           CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00252'; -- �p�����[�^�Ó����`�F�b�N�G���[���b�Z�[�W
    cv_tkn_number_03           CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00547'; -- �����������I�[�o
    cv_tkn_parm_name           CONSTANT VARCHAR2(20) := 'PARAM_NAME';       -- �p�����[�^
    cv_tkn_item                CONSTANT VARCHAR2(20) := 'ITEM';             -- �A�C�e��
    cv_tkn_val_ym_name         CONSTANT VARCHAR2(20) := '�N��';             -- �p�����[�^��:�N��
    cv_tkn_val_amt_name        CONSTANT VARCHAR2(20) := '���Ԕ���v����z'; -- �p�����[�^��:���ʔ���v����z
    cv_tkn_val_route_name      CONSTANT VARCHAR2(20) := '���[�g�m��';       -- �p�����[�^��:���[�gNo
    cv_visit_type_0            CONSTANT VARCHAR2(1)  := '0';                -- �K��^�C�v���T1��ȏ�(0)
    cv_visit_type_1            CONSTANT VARCHAR2(1)  := '1';                -- �K��^�C�v���T1��ȏ�(1)
    cv_visit_type_2            CONSTANT VARCHAR2(1)  := '2';                -- �K��^�C�v���T1��ȏ�(2)
    cv_visit_type_3            CONSTANT VARCHAR2(1)  := '3';                -- �K��^�C�v���T1��ȏ�(3)
    cv_visit_type_5            CONSTANT VARCHAR2(1)  := '5';                -- �K��^�C�v���T2��ȉ�(5)
    cv_visit_type_6            CONSTANT VARCHAR2(1)  := '6';                -- �K��^�C�v���G�ߒP��(6)
    cv_visit_type_9            CONSTANT VARCHAR2(1)  := '9';                -- �K��^�C�v�����̑�(9)    
--
    -- *** �e�[�u���^��` ***
    -- ���ʔ���v�惏�[�N�e�[�u�����֘A��񒊏o�f�[�^
    TYPE l_sales_plan_day_rtype IS RECORD(
      sales_plan_day_amt      xxcso_in_sales_plan_month.sales_plan_amt%TYPE,     -- ����v����z
      houmon_flg              number                                             -- �K��t���O
    );    
    TYPE l_sales_plan_day_ttype IS TABLE OF l_sales_plan_day_rtype INDEX BY PLS_INTEGER;
-- �P�����ȓ��Ŏw��K��j���ɊY��������ɂ����i�[����f�[�^
    TYPE l_day_one_week_ttype IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;               -- �P�T�Ԉȓ��̓��ɂ�
    TYPE l_all_day_week_ttype IS TABLE OF l_day_one_week_ttype INDEX BY BINARY_INTEGER; -- �e�T���Ƃɓ��ɂ����i�[
--
    -- *** ���[�J���ϐ� ***
--
    lv_year_month                  VARCHAR2(6);                                   -- �N���i�����FYYYYMM�j
    lt_sales_plan_amt              xxcso_in_sales_plan_month.sales_plan_amt%TYPE; -- ���z������z
    lt_route_number                xxcso_in_route_no.route_no%TYPE; -- ���[�g�m�� 
    l_sales_plan_day_on_month_tbl  l_sales_plan_day_ttype;          -- ���ۂ̌��̓��ɂ����̓��ʔ���v��f�[�^
    ln_day_on_month                NUMBER;                          -- �Y�����̓���
    ln_cnt_houmon_day              NUMBER;                          -- �Y�����̖K�����
    ln_sales_plan_day              NUMBER;                          -- �K�����
    ln_loop_cnt                    NUMBER;                          -- ���[�v�p�ϐ�
    ln_cnt_first_houmon            NUMBER;                          -- �ŏ��K����𔻒f����K����J�E���g�ϐ�
    lt_sales_plan_day_amt          xxcso_account_sales_plans.sales_plan_day_amt%TYPE;
-- ���[�gNo�ɔz�����ꂽ�K����̓��ʔ���v����z
    lv_day_for_houmon              VARCHAR2(100);                   -- �K����ɊY������j�����X�g
    l_week_day_tab                 g_day_of_week_ttype;             -- ���j��0���j�����i�[����e�[�u���^�ϐ�
    lv_day_on_week                 VARCHAR2(20);                    -- �Y�����ɂ��̗j�� 
    ln_houmon_week1                NUMBER;                          -- �T�P��ȉ��K�⎞�́A�P��ڂ̏T
    ln_houmon_week2                NUMBER;                          -- �T�P��ȉ��K�⎞�́A�Q��ڂ̏T
    ln_week_cnt                    NUMBER;                          -- �T�J�E���g�p
    lv_day_for_yymm01              VARCHAR2(20);                    -- �����߂̗j��  
    l_all_day_week_tab             l_all_day_week_ttype;            -- �e�T���Ƃɓ��ɂ���2�����Ŋi�[����ϐ�
    ln_day_week2                   NUMBER;                          -- 2�T�ڂ̌��j���ɊY��������ɂ�
    ln_day_houmon_number1          NUMBER;                          -- �T2��ȉ��K�⎞�A���[��No6�Ԗڐ���
    ln_day_houmon_number2          NUMBER;                          -- �T2��ȉ��K�⎞�A���[��No7�Ԗڐ���  
    ln_i                           NUMBER;                          -- ���[�v�p
    ln_j                           NUMBER;                          -- ���[�v�p
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
    -- �p�����[�^�`�F�b�N 
    -- ���̓p�����[�^:�N���������͂̏ꍇ
    IF iv_year_month IS NULL THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_parm_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_ym_name       -- �g�[�N���l1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    -- ���̓p�����[�^:���ʔ���v����z�������͂̏ꍇ
    ELSIF it_sales_plan_amt IS NULL THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_parm_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_amt_name      -- �g�[�N���l1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    -- ���̓p�����[�^:���[�gNo�������͂̏ꍇ
    ELSIF it_route_number IS NULL THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_parm_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_route_name    -- �g�[�N���l1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    END IF; 
--
    -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
    lv_year_month         := iv_year_month;              -- �N���i�����FYYYYMM�j
    lt_sales_plan_amt     := it_sales_plan_amt;          -- ���Ԕ���v����z
    lt_route_number       := it_route_number;            -- ���[�g�m�� 
--
    -- **DEBUG**
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�N��:'             || lv_year_month              || CHR(10) ||
                 '���ʔ���v����z:' || TO_CHAR(lt_sales_plan_amt) || CHR(10) ||
                 '���[�gNo:'         || TO_CHAR(lt_route_number)   || CHR(10)
    );
    -- **DEBUG**
    -- ���[�gNo�Ó����`�F�b�N
    IF SUBSTR(it_route_number,1,1) NOT IN (cv_visit_type_0,
                                           cv_visit_type_1,
                                           cv_visit_type_2,
                                           cv_visit_type_3,
                                           cv_visit_type_5,
                                           cv_visit_type_6,
                                           cv_visit_type_9) 
         OR LENGTHB(it_route_number) <> 7 THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_val_route_name    -- �g�[�N���l1
                  );
      lv_retcode := cv_status_error;
      RAISE global_api_others_expt;
    END IF; 
--  
    -- �j����ϐ��ɃZ�b�g
    l_week_day_tab(1)     := cv_week_1;                  -- '���j��'
    l_week_day_tab(2)     := cv_week_2;                  -- '�Ηj��'
    l_week_day_tab(3)     := cv_week_3;                  -- '���j��'
    l_week_day_tab(4)     := cv_week_4;                  -- '�ؗj��'
    l_week_day_tab(5)     := cv_week_5;                  -- '���j��'
    l_week_day_tab(6)     := cv_week_6;                  -- '�y�j��'
    l_week_day_tab(7)     := cv_week_7;                  -- '���j��'
    -- �K������̏�����
    ln_cnt_houmon_day     := 0;
    -- �ŏ��K����𔻒f����ϐ��̏�����
    ln_cnt_first_houmon   := 0;
--
    -- �Y�����̓������擾
    ln_day_on_month := TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE(lv_year_month||'01', 'YYYYMMDD')),'DD')); 
--
    -- �K��j�����X�g������
    lv_day_for_houmon := '';
--  
    -- ===============================================
    -- 1.�T�P��ȏ�K��̏ꍇ
    -- ===============================================
    IF SUBSTR(lt_route_number,1,1)   = cv_visit_type_0
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_1
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_2
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_3 THEN
--
      -- ���[�gNO�ɂ��A�K��j�����X�g���쐬
      <<create_houmon_day_week>>
      FOR ln_loop_cnt IN 1..7 LOOP
        IF (SUBSTR(lt_route_number,ln_loop_cnt,1)  = cv_visit_type_1
          OR SUBSTR(lt_route_number,ln_loop_cnt,1) = cv_visit_type_2
          OR SUBSTR(lt_route_number,ln_loop_cnt,1) = cv_visit_type_3) THEN
          lv_day_for_houmon := lv_day_for_houmon||l_week_day_tab(ln_loop_cnt);
        END IF;
      END LOOP create_houmon_day_week;
--
      -- �K������̌v�Z
      <<get_sales_day_loop>>
      FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
        -- �Y�����ɂ��̗j���擾
        lv_day_on_week := TO_CHAR(TO_DATE(lv_year_month||LPAD(TO_CHAR(ln_loop_cnt), 2, '0'), 'YYYYMMDD'), 'Day');
        -- �K����ɊY��������ʔ���v��f�[�^�̖K��t���O�̏������i0���Z�b�g)
        l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 0; 
        -- �K����ɊY������������v�Z
        IF (INSTR(lv_day_for_houmon, lv_day_on_week) >= 1) THEN
          ln_cnt_houmon_day := ln_cnt_houmon_day + 1;
          -- �K����ɊY��������ʔ���v��f�[�^�̖K��t���O��'1'���Z�b�g
          l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 1; 
        END IF;
      END LOOP get_sales_day_loop;
    END IF;
--    
    -- ===============================================
    -- 2.�T2��ȉ��K��̏ꍇ
    -- ===============================================
    -- �擪�����̃`�F�b�N
    IF SUBSTR(lt_route_number,1,1)   = cv_visit_type_5 THEN
      -- �T���j���̂Q�����z��̓��ɂ�������
      FOR ln_i in 1..6 LOOP        -- �T
        FOR ln_j in 1..7 LOOP      -- �j��
          l_all_day_week_tab(ln_i)(ln_j) := 0;
        END LOOP;
      END LOOP;    
      -- �Y���N���̂P���ڂ̗j�����擾
      lv_day_for_yymm01 := TO_CHAR(TO_DATE(lv_year_month||'01', 'YYYYMMDD'), 'Day');
      -- �P���ڂ̗j���ɂ��A�z��ɂP�T�ڂ̓��ɂ����Z�b�g
      ln_week_cnt := 1;
      <<get_day_week1>>
      FOR ln_i in 1..7 LOOP  
        -- �P���ڂ̗̂j���`�F�b�N    
        IF lv_day_for_yymm01 = l_week_day_tab(ln_i) THEN
          -- 1�T�ڂ̓��ɂ����Z�b�g
          <<set_day_fir_week>>
          FOR ln_j in ln_i..7 LOOP
            l_sales_plan_day_on_month_tbl(ln_j-ln_i+1).houmon_flg := 0;
            l_all_day_week_tab(1)(ln_j)                           := ln_j - ln_i + 1;
          END LOOP set_day_fir_week;
          -- 2�T�ڌ��j���ɊY��������ɂ��Z�b�g�ニ�[�v�𔲂���
          ln_day_week2 := l_all_day_week_tab(1)(7) + 1;
          EXIT;
        END IF;
      END LOOP get_day_week1;
      -- 2�T�ڈȍ~�̓��ɂ��Z�b�g
      ln_loop_cnt := ln_day_week2;
      <<get_day_week2>>
      LOOP
        ln_week_cnt := ln_week_cnt + 1;    -- �T�J�E���g
        -- 2�T�ڈȍ~�̓��ɂ����Z�b�g
        <<set_day_after_week>>
        FOR ln_j in 1..7 LOOP
            l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 0;
            IF ln_loop_cnt <= ln_day_on_month THEN
               l_all_day_week_tab(ln_week_cnt)(ln_j)   := ln_loop_cnt;
               ln_loop_cnt                             := ln_loop_cnt + 1; 
            END IF;                                       
        END LOOP set_day_after_week;
        IF ln_loop_cnt > ln_day_on_month THEN 
          EXIT;
        END IF;
      END LOOP get_day_week2;
--
      -- ���[�gNO�ɂ��A�K��j�����X�g���쐬
      -- ���[�gNo�̂R�Ԗڐ����ɂ��K��T���擾
      ln_houmon_week1 := TO_NUMBER(SUBSTR(lt_route_number,3,1));
      -- ���[�gNo�̂S�Ԗڐ����ɂ��K��T���擾
      ln_houmon_week2 := TO_NUMBER(SUBSTR(lt_route_number,4,1));
      -- ���[�gNo�̂U�Ԗڐ����ɂ��A�K��j�����擾
      ln_day_houmon_number1 := TO_NUMBER(SUBSTR(lt_route_number,6,1));
      -- ���[�gNo�̂V�Ԗڐ����ɂ��A�K��j�����擾
      ln_day_houmon_number2 := TO_NUMBER(SUBSTR(lt_route_number,7,1));
--
      -- �K�����������
      ln_cnt_houmon_day := 0;
      -- �T���ƂɃZ�b�g�������ɂ��f�[�^���L���f�[�^�ł���ꍇ
      -- 1�T�ږK�₪���݂���ꍇ�̖̂K����Z�b�g
      IF ln_houmon_week1 > 0 THEN
        -- ���[�gNo�̂U�ԖڂɂO���傫���������Z�b�g����Ă���ꍇ
        IF ln_day_houmon_number1 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number1) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- �K������J�E���g
            -- �Y��������ɂ��ɖK��t���O���Z�b�g
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number1)).houmon_flg := 1; 
          END IF;
        END IF;
        -- ���[�gNo�̂V�ԖڂɂO���傫���������Z�b�g����Ă���ꍇ
        IF ln_day_houmon_number2 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number2) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- �K������J�E���g
            -- �Y��������ɂ��ɖK��t���O���Z�b�g
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week1)(ln_day_houmon_number2)).houmon_flg := 1; 
          END IF;
        END IF;
      END IF;
      -- 2�T�ږK�₪���݂���ꍇ�̖K����Z�b�g
      IF ln_houmon_week2 > 0 THEN
        -- ���[�gNo�̂U�ԖڂɂO���傫���������Z�b�g����Ă���ꍇ
        IF ln_day_houmon_number1 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number1) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- �K������J�E���g
            -- �Y��������ɂ��ɖK��t���O���Z�b�g
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number1)).houmon_flg := 1; 
          END IF;
        END IF;
        -- ���[�gNo�̂V�ԖڂɂO���傫���������Z�b�g����Ă���ꍇ
        IF ln_day_houmon_number2 > 0 THEN
          IF l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number2) >= 1 THEN
            ln_cnt_houmon_day := ln_cnt_houmon_day + 1;  -- �K������J�E���g
            -- �Y��������ɂ��ɖK��t���O���Z�b�g
            l_sales_plan_day_on_month_tbl(l_all_day_week_tab(ln_houmon_week2)(ln_day_houmon_number2)).houmon_flg := 1; 
          END IF;
        END IF;
      END IF;
    END IF; 
--
    -- �T�P��ȏ�A�P��ȉ��K��̏ꍇ�̂݁i�敪��0,1,2,3,5�j�A���������s��
    IF SUBSTR(lt_route_number,1,1)   = cv_visit_type_0
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_1
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_2
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_3 
      OR SUBSTR(lt_route_number,1,1) = cv_visit_type_5 THEN
--
      -- �K��������O�̏ꍇ�A�G���[ 
      IF ln_cnt_houmon_day = 0 THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_val_route_name    -- �g�[�N���l1
                    );
        lv_retcode := cv_status_error;
        RAISE global_api_others_expt;
      END IF;
--
      -- ���[�gNo�ɂ��z�����ꂽ�K����̓��ʔ���v����z�̌v�Z
      BEGIN
        lt_sales_plan_day_amt := TRUNC(lt_sales_plan_amt/ln_cnt_houmon_day);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          -- ����ꂪ���������ꍇ
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_03         -- ���b�Z�[�W�R�[�h
                      );
          ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || lv_errbuf;
          ov_retcode := cv_status_error;
          ov_errmsg  := lv_errbuf;
          RETURN;
      END;
--
      -- �K��t���O���Z�b�g����Ă���K����ɂ��Ĕ���v����z���Z�b�g
      <<distribute_sales_loop>>
      FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
        -- �Y�������K����̏ꍇ�A���ʔ���v����z���Z�b�g
        IF (l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg = 1) THEN
          -- �K������̃J�E���g
          ln_cnt_first_houmon := ln_cnt_first_houmon + 1;
          -- ���ʔ�����z�̃Z�b�g
          l_sales_plan_day_on_month_tbl(ln_loop_cnt).sales_plan_day_amt := lt_sales_plan_day_amt;
          -- �ŏ��K����̓��ʔ�����z�̒���
          IF ln_cnt_first_houmon = '1' THEN
             l_sales_plan_day_on_month_tbl(ln_loop_cnt).sales_plan_day_amt := 
               lt_sales_plan_amt - lt_sales_plan_day_amt*(ln_cnt_houmon_day-1);
          END IF;
        END IF;
      END LOOP distribute_sales_loop;
    END IF;
--
    -- ===============================================
    -- 3.�G�ߎ���ڋq�̏ꍇ�A�܂��͂��̑�
    -- ===============================================
    IF (SUBSTR(lt_route_number,1,1)       = cv_visit_type_6
         OR SUBSTR(lt_route_number,1,1)   = cv_visit_type_9) THEN
      -- �K��t���O�̏�����
      <<distribute_sales_loop>>
      FOR ln_loop_cnt IN 1..ln_day_on_month LOOP
        l_sales_plan_day_on_month_tbl(ln_loop_cnt).houmon_flg := 0;
      END LOOP distribute_sales_loop;
      -- �K������ɂP���Z�b�g
      ln_cnt_houmon_day := 1;
      -- �ŏI���ɖK��t���O�Z�b�g�A���ʔ���v��f�[�^���Z�b�g
      l_sales_plan_day_on_month_tbl(ln_day_on_month).houmon_flg         := 1;
     l_sales_plan_day_on_month_tbl(ln_day_on_month).sales_plan_day_amt := lt_sales_plan_amt;
    END IF;
--   
    -- ���Y���̓�����OUT�p�����[�^�ɃZ�b�g
    on_day_on_month          := ln_day_on_month;    
    on_visit_daytimes        := ln_cnt_houmon_day;
--
    -- ���ʔ���v����z��OUT�p�����[�^�ɃZ�b�g
    ot_sales_plan_day_amt_1  := l_sales_plan_day_on_month_tbl(1).sales_plan_day_amt;
    ot_sales_plan_day_amt_2  := l_sales_plan_day_on_month_tbl(2).sales_plan_day_amt;
    ot_sales_plan_day_amt_3  := l_sales_plan_day_on_month_tbl(3).sales_plan_day_amt;
    ot_sales_plan_day_amt_4  := l_sales_plan_day_on_month_tbl(4).sales_plan_day_amt;
    ot_sales_plan_day_amt_5  := l_sales_plan_day_on_month_tbl(5).sales_plan_day_amt;
    ot_sales_plan_day_amt_6  := l_sales_plan_day_on_month_tbl(6).sales_plan_day_amt;
    ot_sales_plan_day_amt_7  := l_sales_plan_day_on_month_tbl(7).sales_plan_day_amt;
    ot_sales_plan_day_amt_8  := l_sales_plan_day_on_month_tbl(8).sales_plan_day_amt;
    ot_sales_plan_day_amt_9  := l_sales_plan_day_on_month_tbl(9).sales_plan_day_amt;
    ot_sales_plan_day_amt_10 := l_sales_plan_day_on_month_tbl(10).sales_plan_day_amt;
    ot_sales_plan_day_amt_11 := l_sales_plan_day_on_month_tbl(11).sales_plan_day_amt;
    ot_sales_plan_day_amt_12 := l_sales_plan_day_on_month_tbl(12).sales_plan_day_amt;
    ot_sales_plan_day_amt_13 := l_sales_plan_day_on_month_tbl(13).sales_plan_day_amt;
    ot_sales_plan_day_amt_14 := l_sales_plan_day_on_month_tbl(14).sales_plan_day_amt;
    ot_sales_plan_day_amt_15 := l_sales_plan_day_on_month_tbl(15).sales_plan_day_amt;
    ot_sales_plan_day_amt_16 := l_sales_plan_day_on_month_tbl(16).sales_plan_day_amt;
    ot_sales_plan_day_amt_17 := l_sales_plan_day_on_month_tbl(17).sales_plan_day_amt;
    ot_sales_plan_day_amt_18 := l_sales_plan_day_on_month_tbl(18).sales_plan_day_amt;
    ot_sales_plan_day_amt_19 := l_sales_plan_day_on_month_tbl(19).sales_plan_day_amt;
    ot_sales_plan_day_amt_20 := l_sales_plan_day_on_month_tbl(20).sales_plan_day_amt;
    ot_sales_plan_day_amt_21 := l_sales_plan_day_on_month_tbl(21).sales_plan_day_amt;
    ot_sales_plan_day_amt_22 := l_sales_plan_day_on_month_tbl(22).sales_plan_day_amt;
    ot_sales_plan_day_amt_23 := l_sales_plan_day_on_month_tbl(23).sales_plan_day_amt;
    ot_sales_plan_day_amt_24 := l_sales_plan_day_on_month_tbl(24).sales_plan_day_amt;
    ot_sales_plan_day_amt_25 := l_sales_plan_day_on_month_tbl(25).sales_plan_day_amt;
    ot_sales_plan_day_amt_26 := l_sales_plan_day_on_month_tbl(26).sales_plan_day_amt;
    ot_sales_plan_day_amt_27 := l_sales_plan_day_on_month_tbl(27).sales_plan_day_amt;
    ot_sales_plan_day_amt_28 := l_sales_plan_day_on_month_tbl(28).sales_plan_day_amt;
    -- ���Y���̓����ɂ��A�Q�X���`�R�P���܂ł̃f�[�^�Z�b�g�������s��
    IF ln_day_on_month > 28 THEN
      ot_sales_plan_day_amt_29 := l_sales_plan_day_on_month_tbl(29).sales_plan_day_amt;
    END IF;
    IF ln_day_on_month > 29 THEN
      ot_sales_plan_day_amt_30 := l_sales_plan_day_on_month_tbl(30).sales_plan_day_amt;
    END IF;
    IF ln_day_on_month > 30 THEN
      ot_sales_plan_day_amt_31 := l_sales_plan_day_on_month_tbl(31).sales_plan_day_amt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errbuf;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END distribute_sales_plan;
--
  /**********************************************************************************
   * Procedure Name   : calc_visit_times
   * Description      : ���[�g�m���K��񐔎Z�o����
   ***********************************************************************************/
  PROCEDURE calc_visit_times(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ���[�g�m��
    ,on_times        OUT NOCOPY NUMBER                          -- �K���
    ,ov_errbuf       OUT NOCOPY VARCHAR2                        -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode      OUT NOCOPY VARCHAR2                        -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg       OUT NOCOPY VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'calc_visit_times'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_sales_appl_short_name CONSTANT VARCHAR2(5)  := 'XXCSO';            -- �A�v���P�[�V�����Z�k��
    cv_tkn_number_01         CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00325'; -- �p�����[�^�K�{�G���[
    cv_tkn_number_02         CONSTANT VARCHAR2(20) := 'APP-XXCSO1-00252'; -- �p�����[�^�Ó����`�F�b�N�G���[���b�Z�[�W
    cv_tkn_parm_name         CONSTANT VARCHAR2(20) := 'PARAM_NAME';       -- �p�����[�^
    cv_tkn_item              CONSTANT VARCHAR2(20) := 'ITEM';             -- �A�C�e��
    cv_tkn_value_parm_name   CONSTANT VARCHAR2(20) := '���[�g�m��';       -- �p�����[�^��
    cv_tkn_value_item        CONSTANT VARCHAR2(20) := '���[�g�m��';       -- �A�C�e����
    cv_visit_type_week1      CONSTANT VARCHAR2(1)  := '0';                -- �K��^�C�v���T�P��
    cv_visit_type_week2      CONSTANT VARCHAR2(1)  := '3';                -- �K��^�C�v���T�P��
    cv_visit_type_month      CONSTANT VARCHAR2(2)  := '5-';               -- �K��^�C�v�����P��
    cv_visit_type_season     CONSTANT VARCHAR2(2)  := '6-';               -- �K��^�C�v���G�ߒP��
    cv_visit_type_other      CONSTANT VARCHAR2(2)  := '9-';               -- �K��^�C�v�����̑�
    cn_multiplication_no     CONSTANT NUMBER       := 4;                  -- �T�P�ʂ̏ꍇ�̏�Z�l
    cn_visit_day_unit_from   CONSTANT NUMBER       := 6;                  -- ���P�ʂ̏ꍇ�̗j���J�n����
    cn_visit_day_unit_to     CONSTANT NUMBER       := 7;                  -- ���P�ʂ̏ꍇ�̗j���I������
    cn_visit_week_unit_from  CONSTANT NUMBER       := 3;                  -- ���P�ʂ̏ꍇ�̏T�J�n����
    cn_visit_week_unit_to    CONSTANT NUMBER       := 4;                  -- ���P�ʂ̏ꍇ�̏T�I������
    cn_visit_count_other     CONSTANT NUMBER       := 1;                  -- ���̑��̏ꍇ�̌Œ�K���
    --
    cv_zero CONSTANT VARCHAR2(1) := '0';
    cn_one  CONSTANT NUMBER      := 1;
    --
    -- *** ���[�J���ϐ� ***
    lt_route_number        xxcso_in_route_no.route_no%TYPE; -- ���[�g�m���ޔ�p
    ln_route_number_length NUMBER;                          -- ���[�g�m���̍��ڒ�
    ln_route_number_work   NUMBER;                          -- ���[�g�񐔉��Z�̃��[�N�̈�
    ln_route_number_week   NUMBER;                          -- ���P�ʂ̏ꍇ�̏T�K��񐔃��[�N�̈�
    ln_route_number_month  NUMBER;                          -- ���P�ʂ̏ꍇ�̌��K��񐔃��[�N�̈�
    ln_loop_count          NUMBER;                          -- ���[�v�p�ϐ�
    ln_visit_count         NUMBER;                          -- �K���
    --
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
    --
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    lv_errbuf  := NULL;
    lv_retcode := cv_status_normal;
    lv_errmsg  := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- �e�ϐ��̏�����
    ln_route_number_length := 0; -- ���[�g�m���̍��ڒ�
    ln_route_number_work   := 0; -- ���[�g�񐔉��Z�̃��[�N�̈�
    ln_route_number_week   := 0; -- ���P�ʂ̏ꍇ�̏T�K��񐔃��[�N�̈�
    ln_route_number_month  := 0; -- ���P�ʂ̏ꍇ�̌��K��񐔃��[�N�̈�
    ln_visit_count         := 0; -- �K���
    --
    IF (TRIM(it_route_number) IS NULL) THEN
      -- ���̓p�����[�^�������͂̏ꍇ
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_parm_name         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_tkn_value_parm_name   -- �g�[�N���l1
                  );
      --
      lv_retcode := cv_status_error;
      --
    ELSE
      -- IN�p�����[�^�����R�[�h�ϐ��ɑ��
      lt_route_number := it_route_number;
      --
      -- ���[�g�m���̍��ڒ����擾
      ln_route_number_length := LENGTHB(lt_route_number);
      --
      IF (SUBSTRB(lt_route_number, 1, 1) BETWEEN cv_visit_type_week1
        AND cv_visit_type_week2)
      THEN
        -- ���[�gNO�̐擪1����'0'�`'3'�̏ꍇ
        ln_loop_count := 1;
        --
        <<route_number_loop1>>
        LOOP
          IF (ln_loop_count > ln_route_number_length) THEN
            -- ���[�v�񐔂����[�g�m���̍��ڒ��𒴂����烋�[�v�𔲂���
            EXIT;
            --
          END IF;
          --
          -- �e���̖K��񐔂����Z
          ln_route_number_work := ln_route_number_work + TO_NUMBER(SUBSTRB(lt_route_number, ln_loop_count, 1));
          --
          -- ���[�v�J�E���^���J�E���g�A�b�v
          ln_loop_count := ln_loop_count + 1;
          --
        END LOOP route_number_loop1;
        --
        -- ���Z�����K��񐔂���Z
        ln_visit_count := ln_route_number_work * cn_multiplication_no;
        --
      ELSIF (SUBSTRB(lt_route_number, 1, 2) = cv_visit_type_month) THEN
        -- ���[�gNO�̐擪2����'5-'�̏ꍇ
        ln_loop_count := 1;
        --
        <<route_number_loop2>>
        LOOP
          IF (ln_loop_count > ln_route_number_length) THEN
            -- ���[�v�񐔂����[�g�m���̍��ڒ��𒴂����烋�[�v�𔲂���
            EXIT;
            --
          END IF;
          --
          -- ��T�Ԃ̖K��������Z�o
          IF (ln_loop_count BETWEEN cn_visit_day_unit_from
            AND cn_visit_day_unit_to)
          THEN
            -- ���[�g�m���̌������j���P�ʂ̖K���\�������̏ꍇ
            IF (SUBSTRB(lt_route_number, ln_loop_count, 1) <> cv_zero) THEN
              -- ���[�g�m����0�ȊO�̏ꍇ(1:���j�A2:�Ηj�A3:���j�A4:�ؗj�A5:���j�A6:�y�j�A7:���j)
              ln_route_number_week := ln_route_number_week + cn_one;
              --
            END IF;
            --
          END IF;
          --
          -- �ꃖ���̖K��������Z�o
          IF (ln_loop_count BETWEEN cn_visit_week_unit_from
            AND cn_visit_week_unit_to)
          THEN
            -- ���[�g�m���̌�������T�ԒP�ʂ̖K���\�������̏ꍇ
            IF (SUBSTRB(lt_route_number, ln_loop_count, 1) <> cv_zero) THEN
              -- ���[�g�m����0�ȊO�̏ꍇ(1:���T�A2:���T�A3:��O�T�A4:��l�T�A5:��܏T)
              ln_route_number_month := ln_route_number_month + cn_one;
              --
            END IF;
            --
          END IF;
          --
          -- ���[�v�J�E���^���J�E���g�A�b�v
          ln_loop_count := ln_loop_count + 1;
          --
        END LOOP route_number_loop2;
        --
        -- �K��񐔈�T�Ԃ̖K�����*�ꃖ���̖K��T�����Z�o
        ln_visit_count := ln_route_number_week * ln_route_number_month;
        --
      ELSIF (SUBSTRB(lt_route_number, 1, 2) IN (cv_visit_type_season, cv_visit_type_other)) THEN
        -- ���[�gNO�̐擪1����'6-'����'9-'�̏ꍇ
        ln_visit_count := cn_visit_count_other;
        --
      ELSE
        -- ��L�ȊO�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_02         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_tkn_value_item        -- �g�[�N���l1
                    );
        --
        lv_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    --
    on_times   := ln_visit_count;
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errbuf;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      on_times   := ln_visit_count;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errbuf;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END calc_visit_times;
--
--
   /**********************************************************************************
   * Function Name    : validate_route_no_p
   * Description      : ���[�g�m���Ó����`�F�b�N(�v���V�[�W��)�쐬
   ***********************************************************************************/
  PROCEDURE validate_route_no_p(
     iv_route_number  IN  VARCHAR2            -- ���[�g�m��
    ,ov_retcode       OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h  --# �Œ� #
    ,ov_error_reason  OUT VARCHAR2            -- �G���[���R
  ) IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'validate_route_no_p';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lb_return_value              BOOLEAN;    --���[�g�m���Ó����`�F�b�NRETURN�l�i�[
--
  BEGIN
--
    lb_return_value := xxcso_route_common_pkg.validate_route_no(iv_route_number, ov_error_reason);
--
    IF ( lb_return_value ) THEN
--
      ov_retcode := '0';
--
    ELSE
--
      ov_retcode := '2';
--
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt('xxcso_route_common_pkg', cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END validate_route_no_p;
--
  /**********************************************************************************
   * Function Name    : isCustomerVendor
   * Description      : �u�c�ƑԔ���֐�
   ***********************************************************************************/
  FUNCTION isCustomerVendor(
     iv_cust_gyoutai  IN  VARCHAR2            -- �Ƒԁi�����ށj
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'isCustomerVendor';
    cv_lookup_type_dai           CONSTANT VARCHAR2(100)   := 'XXCMM_CUST_GYOTAI_DAI';
    cv_lookup_type_chu           CONSTANT VARCHAR2(100)   := 'XXCMM_CUST_GYOTAI_CHU';
    cv_lookup_type_syo           CONSTANT VARCHAR2(100)   := 'XXCMM_CUST_GYOTAI_SHO';
    cv_profile_option            CONSTANT VARCHAR2(100)   := 'XXCSO1_VD_GYOUTAI_CD_DAI';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lt_gyoutai_cd_dai            fnd_lookup_values_vl.lookup_code%type;
    lb_return_value              VARCHAR2(10);
    lv_process_date              DATE := xxccp_common_pkg2.get_process_date;
--
  BEGIN
--
    BEGIN
      --�Ƒԁi�����ށj����Ƒԁi�啪�ށj���擾
      SELECT dai.lookup_code gyoutai_dai_cd
      INTO   lt_gyoutai_cd_dai
      FROM   fnd_lookup_values_vl dai
      ,      fnd_lookup_values_vl chu
      ,      fnd_lookup_values_vl syo
      WHERE  syo.lookup_type = cv_lookup_type_syo
      AND    chu.lookup_type = cv_lookup_type_chu
      AND    dai.lookup_type = cv_lookup_type_dai
      AND    syo.lookup_code = iv_cust_gyoutai    --�p�����[�^.�Ƒԁi�����ށj
      AND    chu.lookup_code = syo.attribute1
      AND    dai.lookup_code = chu.attribute1
      AND    syo.enabled_flag   = 'Y'
      AND    chu.enabled_flag   = 'Y'
      AND    dai.enabled_flag   = 'Y'
      AND    NVL(dai.start_date_active, TRUNC(lv_process_date)) <= TRUNC(lv_process_date)
      AND    NVL(dai.end_date_active,   TRUNC(lv_process_date)) >= TRUNC(lv_process_date)
      AND    NVL(chu.start_date_active, TRUNC(lv_process_date)) <= TRUNC(lv_process_date)
      AND    NVL(chu.end_date_active,   TRUNC(lv_process_date)) >= TRUNC(lv_process_date)
      AND    NVL(syo.start_date_active, TRUNC(lv_process_date)) <= TRUNC(lv_process_date)
      AND    NVL(syo.end_date_active,   TRUNC(lv_process_date)) >= TRUNC(lv_process_date)
      ;
--
      IF ( lt_gyoutai_cd_dai = FND_PROFILE.VALUE(cv_profile_option) ) THEN
        --�Ƒԁi�啪�ށj���u�c�̏ꍇ
        lb_return_value := 'TRUE';
      ELSE
        --�Ƒԁi�啪�ށj���u�c�ȊO�̏ꍇ
        lb_return_value := 'FALSE';
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        --�啪�ނ��擾�ł��Ȃ��ꍇ�i�l�b�ڋq�̏ꍇ�Ȃǁj
        lb_return_value := 'FALSE';
    END;
--
    RETURN lb_return_value;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt('xxcso_route_common_pkg', cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END isCustomerVendor;
--
  /**********************************************************************************
   * Function Name    : calc_visit_times_f
   * Description      : �K��񐔎Z�o����(�t�@���N�V����)
   ***********************************************************************************/
  FUNCTION calc_visit_times_f(
     it_route_number IN         xxcso_in_route_no.route_no%TYPE -- ���[�g�m��
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'calc_visit_times_f';
    cn_err_vit_times CONSTANT NUMBER        := -1;
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_times     NUMBER;          -- �߂�l�F�K��񐔊i�[
    lv_errbuf    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    -- �K��񐔎Z�o
    xxcso_route_common_pkg.calc_visit_times(
      it_route_number => it_route_number
     ,on_times        => ln_times
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
      );
--
    IF (lv_retcode <> cv_status_normal) THEN
      ln_times := cn_err_vit_times;
    END IF;
    
    RETURN ln_times;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt('xxcso_route_common_pkg', cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END calc_visit_times_f;
--
END xxcso_route_common_pkg;
/
