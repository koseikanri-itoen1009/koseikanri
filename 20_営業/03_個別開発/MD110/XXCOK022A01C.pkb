CREATE OR REPLACE PACKAGE BODY XXCOK022A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK022A01C(body)
 * Description      : �̎�̋��\�ZExcel�A�b�v���[�h
 * MD.050           : �̎�̋��\�ZExcel�A�b�v���[�h MD050_COK_022_A01
 * Version          : 2.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  del_mrp_file_ul_interface    �t�@�C���A�b�v���[�hIF�̍폜     (A-9)
 *  purge_bm_support_budget      �p�[�W����                       (A-8)
 *  ins_bm_support_budget        �̎�̋��\�Z���̓o�^           (A-7)
 *  del_duplicate_budget_year    �d���\�Z�N�x�f�[�^�̍폜         (A-6)
 *  ins_xxcok_tmp_022a01c        �A�b�v���[�h���ꎞ�\�̓o�^     (A-5)
 *  chk_data_amount              �Ó����`�F�b�N�F�\�Z���z         (A-4-8)
 *  chk_data_month               �Ó����`�F�b�N�F�Ώ۔N��         (A-4-7)
 *  chk_data_sub_acct_code       �Ó����`�F�b�N�F�⏕�ȖڃR�[�h   (A-4-6)
 *  chk_data_acct_code           �Ó����`�F�b�N�F����ȖڃR�[�h   (A-4-5)
 *  chk_data_corp_code           �Ó����`�F�b�N�F��ƃR�[�h       (A-4-3)
 *  chk_data_base_code           �Ó����`�F�b�N�F���_�R�[�h       (A-4-2)
 *  chk_data_budget_year         �Ó����`�F�b�N�F�\�Z�N�x         (A-4-1)
 *  chk_data                     �Ó����`�F�b�N                   (A-4)
 *  import_upload_file_data      �A�b�v���[�h�t�@�C���f�[�^�̎捞 (A-3)
 *  get_upload_file_data         �A�b�v���[�h�t�@�C���f�[�^�̎擾 (A-2)
 *  init                         ��������                         (A-1)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   T.Osada          �V�K�쐬
 *  2009/06/12    1.1   K.Yamaguchi      [��QT1_1433]�N���ݒ�s���Ή�
 *  2010/08/02    2.0   S.Arizumi        [E_�{�ғ�_03332]�d�l�ύX�i�@�\�̌������j
 *  2010/08/24    2.0   S.Arizumi        [E_�{�ғ�_03332]�d�l�ύX�i�}�C�i�X���z�Ή��j
 *
 *****************************************************************************************/
-- 2010/08/02 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR START
--  -- =============================================================================
--  -- �O���[�o���萔
--  -- =============================================================================
--  --�p�b�P�[�W��
--  cv_pkg_name                CONSTANT VARCHAR2(20) := 'XXCOK022A01C';
--  --�A�v���P�[�V�����Z�k��
--  cv_xxcok_appl_name         CONSTANT VARCHAR2(10) := 'XXCOK';
--  cv_xxccp_appl_name         CONSTANT VARCHAR2(10) := 'XXCCP';
--  cv_sqlgl_appl_name         CONSTANT VARCHAR2(10) := 'SQLGL';
--  --�X�e�[�^�X�E�R�[�h
--  cv_status_normal           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
--  cv_status_warn             CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
--  cv_status_error            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
--  cv_status_continue         CONSTANT VARCHAR2(1)  := '9';                                --�p���G���[
--  cv_status_open             CONSTANT VARCHAR2(1)  := 'O';                                --��v���ԃI�[�v��
--  --���b�Z�[�W����
--  cv_err_msg_00003           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00003';   --�v���t�@�C���擾�G���[
--  cv_err_msg_00039           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00039';   --��t�@�C���G���[
--  cv_err_msg_00041           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00041';   --BLOB�f�[�^�ϊ��G���[
--  cv_err_msg_00057           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00057';   --�I�[�v����v���Ԏ擾�G���[
--  cv_err_msg_00059           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00059';   --�L����v���Ԏ擾�G���[
--  cv_err_msg_00061           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00061';   --IF�\���b�N�擾�G���[
--  cv_err_msg_00062           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00062';   --�t�@�C���A�b�v���[�hIF�e�[�u���폜�G���[
--  cv_err_msg_10107           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10107';   --�̎�̋��\�Z�e�[�u���f�[�^���b�N�G���[
--  cv_err_msg_10108           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10108';   --�\�Z�N�x�d���f�[�^�폜�G���[
--  cv_err_msg_10109           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10109';   --�\�Z�N�x����G���[
--  cv_err_msg_10111           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10111';   --�O�X�\�Z�N�x�f�[�^�폜�G���[
--  cv_err_msg_10123           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10123';   --�\�Z���z���p�p�����G���[
--  cv_err_msg_10125           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10125';   --�≮������R�[�h�����`�F�b�N�G���[
--  cv_err_msg_10126           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10126';   --���_�R�[�h�����`�F�b�N�G���[
--  cv_err_msg_10127           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10127';   --��ƃR�[�h�����`�F�b�N�G���[
--  cv_err_msg_10128           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10128';   --����ȖڃR�[�h�����`�F�b�N�G���[
--  cv_err_msg_10129           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10129';   --�⏕�ȖڃR�[�h�����`�F�b�N�G���[
--  cv_err_msg_10130           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10130';   --�\�Z���z�����`�F�b�N�G���[
--  cv_err_msg_10135           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10135';   --���_�R�[�h���p�p�����`�F�b�N�G���[
--  cv_err_msg_10136           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10136';   --��ƃR�[�h���p�p�����`�F�b�N�G���[
--  cv_err_msg_10137           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10137';   --�≮������R�[�h���p�p�����`�F�b�N�G���[
--  cv_err_msg_10138           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10138';   --����ȖڃR�[�h���p�p�����`�F�b�N�G���[
--  cv_err_msg_10139           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10139';   --�⏕�ȖڃR�[�h���p�p�����`�F�b�N�G���[
--  cv_err_msg_10417           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10417';   --�\�Z�N�x����NULL�G���[
--  cv_err_msg_10418           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10418';   --���_�R�[�h����NULL�G���[
--  cv_err_msg_10419           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10419';   --��ƃR�[�h����NULL�G���[
--  cv_err_msg_10420           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10420';   --�≮������R�[�h����NULL�G���[
--  cv_err_msg_10421           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10421';   --����ȖڃR�[�h����NULL�G���[
--  cv_err_msg_10422           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10422';   --�⏕�ȖڃR�[�h����NULL�G���[
--  cv_err_msg_10423           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10423';   --���x����NULL�`�F�b�N�G���[
--  cv_err_msg_10424           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10424';   --�\�Z���z����NULL�`�F�b�N�G���[
--  cv_err_msg_10425           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10425';   --���t�^�ϊ��`�F�b�N�G���[
--  cv_err_msg_10449           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-10449';   --�̎�̋��\�Z�e�[�u���ǉ��G���[
--  cv_message_00006           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00006';   --�t�@�C�������b�Z�[�W�o��
--  cv_message_00016           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00016';   --���̓p�����[�^(�t�@�C��ID)
--  cv_message_00017           CONSTANT VARCHAR2(50) := 'APP-XXCOK1-00017';   --���̓p�����[�^(�t�H�[�}�b�g�p�^�[��)
--  cv_message_90000           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90000';   --�Ώی������b�Z�[�W
--  cv_message_90001           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90001';   --�����������b�Z�[�W
--  cv_message_90002           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90002';   --�G���[�������b�Z�[�W
--  cv_message_90004           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90004';   --����I�����b�Z�[�W
--  cv_message_90006           CONSTANT VARCHAR2(50) := 'APP-XXCCP1-90006';   --�G���[�I���S���[���o�b�N���b�Z�[�W
--  --�v���t�@�C��
--  cv_set_of_bks_id           CONSTANT VARCHAR2(50) := 'GL_SET_OF_BKS_ID';         --��v����ID
--  cv_company_code            CONSTANT VARCHAR2(50) := 'XXCOK1_AFF1_COMPANY_CODE'; --��ЃR�[�h
--  --�g�[�N��
--  cv_token_file_id           CONSTANT VARCHAR2(10) := 'FILE_ID';         --�g�[�N����(FILE_ID)
--  cv_token_format            CONSTANT VARCHAR2(10) := 'FORMAT';          --�g�[�N����(FORMAT)
--  cv_token_file_name         CONSTANT VARCHAR2(10) := 'FILE_NAME';       --�g�[�N����(FILE_NAME)
--  cv_token_row_num           CONSTANT VARCHAR2(20) := 'ROW_NUM';         --�g�[�N����(ROW_NUM)
--  cv_token_occurs            CONSTANT VARCHAR2(20) := 'OCCURS';          --�g�[�N����(OCCURS)
--  cv_token_budget_year       CONSTANT VARCHAR2(20) := 'BUDGET_YEAR';     --�g�[�N����(BUDGET_YEAR)
--  cv_token_object_year       CONSTANT VARCHAR2(50) := 'OBJECT_YEAR';     --�g�[�N����(OBJECT_YEAR)
--  cv_token_profile           CONSTANT VARCHAR2(10) := 'PROFILE';         --�g�[�N����(PROFILE)
--  cv_token_count             CONSTANT VARCHAR2(5)  := 'COUNT';           --�g�[�N����(COUNT)
--  --�t�H�[�}�b�g
--  cv_date_format_yyyymm      CONSTANT VARCHAR2(8)  := 'FXYYYYMM';        --���t�^�ϊ��`�F�b�N�p�t�H�[�}�b�g
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD START
--  cv_date_format_mm          CONSTANT VARCHAR2(2)  := 'MM';              --���̂ݎ擾
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD END
--  --�L��
--  cv_msg_part                CONSTANT VARCHAR2(3)  := ' : ';   --�R����
--  cv_msg_cont                CONSTANT VARCHAR2(3)  := '.';     --�s���I�h
--  cv_comma                   CONSTANT VARCHAR2(1)  := ',';     --�J���}
--  --������
--  cv_info_interface_status   CONSTANT VARCHAR2(1)  := '0';    --���n�A�g�X�e�[�^�X(0:���A�g)
--  --�l
--  cv_0                       CONSTANT VARCHAR2(1)  := '0';    --���x���t�^�ϊ��`�F�b�N�p
--  --���l
--  cn_0                       CONSTANT NUMBER       :=  0;     --���l:0
--  cn_1                       CONSTANT NUMBER       :=  1;     --���l:1
--  cn_2                       CONSTANT NUMBER       :=  2;     --���l:2
--  cn_3                       CONSTANT NUMBER       :=  3;     --���l:3
--  cn_4                       CONSTANT NUMBER       :=  4;     --���l:4
--  cn_5                       CONSTANT NUMBER       :=  5;     --���l:4
--  cn_6                       CONSTANT NUMBER       :=  6;     --���l:6
--  cn_9                       CONSTANT NUMBER       :=  9;     --���l:9
--  cn_12                      CONSTANT NUMBER       := 12;     --���l:12
--  --�t���O
--  cv_adjustment_flag         CONSTANT VARCHAR2(1)  := 'N';                          -- �����t���O
--  --WHO�J����
--  cn_created_by              CONSTANT NUMBER       := fnd_global.user_id;           --CREATED_BY
--  cn_last_updated_by         CONSTANT NUMBER       := fnd_global.user_id;           --LAST_UPDATED_BY
--  cn_last_update_login       CONSTANT NUMBER       := fnd_global.login_id;          --LAST_UPDATE_LOGIN
--  cn_request_id              CONSTANT NUMBER       := fnd_global.conc_request_id;   --REQUEST_ID
--  cn_program_application_id  CONSTANT NUMBER       := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
--  cn_program_id              CONSTANT NUMBER       := fnd_global.conc_program_id;   --PROGRAM_ID
--  -- =============================================================================
--  -- �O���[�o���ϐ�
--  -- =============================================================================
--  gn_target_cnt           NUMBER        DEFAULT 0;      --�Ώی���
--  gn_normal_cnt           NUMBER        DEFAULT 0;      --��������
--  gn_error_cnt            NUMBER        DEFAULT 0;      --�G���[����
--  gn_line_no              NUMBER        DEFAULT 0;      --�s���J�E���^
--  gv_set_of_books_id      VARCHAR2(100) DEFAULT NULL;   --��v����ID
--  gv_company_code         VARCHAR2(100) DEFAULT NULL;   --��ЃR�[�h
--  gn_account_year         NUMBER        DEFAULT NULL;   --�I�[�v����v�N���ϐ�
--  gn_target_account_year  NUMBER        DEFAULT NULL;   --�����Ώۉ�v�N�x�ϐ�
--  gv_chk_code             VARCHAR2(1)   DEFAULT cv_status_normal;   --�Ó����`�F�b�N�̏������ʃX�e�[�^�X
--  -- =============================================================================
--  -- �O���[�o�����R�[�h�^
--  -- =============================================================================
--  TYPE gr_csv_bm_support_budget_tab IS RECORD(
--    budget_year          VARCHAR2(100)   DEFAULT NULL
--   ,base_code            VARCHAR2(100)   DEFAULT NULL
--   ,corp_code            VARCHAR2(100)   DEFAULT NULL
--   ,sales_outlets_code   VARCHAR2(100)   DEFAULT NULL
--   ,acct_code            VARCHAR2(100)   DEFAULT NULL
--   ,sub_acct_code        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_01      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_01        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_02      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_02        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_03      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_03        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_04      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_04        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_05      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_05        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_06      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_06        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_07      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_07        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_08      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_08        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_09      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_09        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_10      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_10        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_11      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_11        VARCHAR2(100)   DEFAULT NULL
--   ,target_month_12      VARCHAR2(100)   DEFAULT NULL
--   ,budget_amt_12        VARCHAR2(100)   DEFAULT NULL);
--   -- �ϐ��̐錾
--   gr_csv_bm_support_budget_rec gr_csv_bm_support_budget_tab;
--  -- =============================================================================
--  -- �O���[�o����O
--  -- =============================================================================
--  -- *** ���b�N�G���[�n���h�� ***
--  global_lock_fail          EXCEPTION;
--  -- *** ���������ʗ�O ***
--  global_process_expt       EXCEPTION;
--  -- *** ���ʊ֐���O ***
--  global_api_expt           EXCEPTION;
--  -- *** ���ʊ֐�OTHERS��O ***
--  global_api_others_expt    EXCEPTION;
----
--  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
--  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
----
--  /**********************************************************************************
--   * Procedure Name   : del_interface_at_error
--   * Description      : �G���[��IF�f�[�^�폜(A-10)
--   ***********************************************************************************/
--  PROCEDURE del_interface_at_error(
--    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
--  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
--  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
--  , in_file_id  IN  NUMBER      --�t�@�C��ID
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'del_interface_at_error';   --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_msg     VARCHAR2(5000) DEFAULT NULL;  --���b�Z�[�W�擾�ϐ�
--    lb_retcode BOOLEAN        DEFAULT TRUE;  --���b�Z�[�W�o�̖͂߂�l
--    lv_target  VARCHAR2(1)    DEFAULT NULL;  --IF�e�[�u���폜�Ώۃ��R�[�h�L��
--    -- =======================
--    -- ���[�J���J�[�\��
--    -- =======================
--    CURSOR xmfui_cur
--    IS
--      SELECT 'X'
--      FROM   xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id
--      FOR UPDATE OF xmfui.file_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- �t�@�C���A�b�v���[�hIF�e�[�u���̃��b�N�擾
--    -- =============================================================================
--    BEGIN
--      SELECT 'X'
--      INTO   lv_target
--      FROM   xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id;
----
--      OPEN  xmfui_cur;
--      CLOSE xmfui_cur;
--      -- =============================================================================
--      -- �t�@�C���A�b�v���[�hIF�e�[�u���̍폜����
--      -- =============================================================================
--      BEGIN
--        DELETE FROM xxccp_mrp_file_ul_interface xmfui
--        WHERE  xmfui.file_id = in_file_id;
--      EXCEPTION
--        -- *** �폜�����Ɏ��s ***
--        WHEN OTHERS THEN
--          lv_msg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_name
--                    , iv_name         => cv_err_msg_00062
--                    , iv_token_name1  => cv_token_file_id
--                    , iv_token_value1 => TO_CHAR( in_file_id )
--                    );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                        , iv_message  => lv_msg              --���b�Z�[�W
--                        , in_new_line => 0                   --���s
--                        );
--          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--          ov_retcode := cv_status_error;
--      END;
--    EXCEPTION
--      -- *** ���b�N���s ***
--      WHEN global_lock_fail THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_00061
--                  , iv_token_name1  => cv_token_file_id
--                  , iv_token_value1 => TO_CHAR( in_file_id )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                      , iv_message  => lv_msg            --���b�Z�[�W
--                      , in_new_line => 0                 --���s
--                      );
--        ov_errmsg  := NULL;
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--      -- *** �Ώۖ��� ***
--      WHEN OTHERS THEN
--        NULL;
--    END;
--  EXCEPTION
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_interface_at_error;
----
--  /**********************************************************************************
--   * Procedure Name   : del_mrp_file_ul_interface
--   * Description      : �����f�[�^�폜(A-8)
--   ***********************************************************************************/
--  PROCEDURE del_mrp_file_ul_interface(
--    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
--  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
--  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
--  , in_file_id  IN  NUMBER      --�t�@�C��ID
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'del_mrp_file_ul_interface';   --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg     VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lb_retcode BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- �t�@�C���A�b�v���[�hIF�e�[�u���̍폜����
--    -- =============================================================================
--    BEGIN
--      DELETE FROM xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id;
--    EXCEPTION
--      -- *** �폜�����Ɏ��s ***
--      WHEN OTHERS THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_00062
--                  , iv_token_name1  => cv_token_file_id
--                  , iv_token_value1 => TO_CHAR( in_file_id )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                      , iv_message  => lv_msg              --���b�Z�[�W
--                      , in_new_line => 0                   --���s
--                      );
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
--  EXCEPTION
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_mrp_file_ul_interface;
----
--  /**********************************************************************************
--   * Procedure Name   : del_past_acct_year_data
--   * Description      : �O�X�\�Z�N�x�f�[�^�폜(A-7)
--   ***********************************************************************************/
--  PROCEDURE del_past_acct_year_data(
--    ov_errbuf  OUT VARCHAR2    --�G���[�E���b�Z�[�W
--  , ov_retcode OUT VARCHAR2    --���^�[���E�R�[�h
--  , ov_errmsg  OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name  CONSTANT VARCHAR2(50) := 'del_past_acct_year_data';   --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
--    lv_retcode              VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
--    ln_two_years_past_year  NUMBER         DEFAULT 0;      --�����Ώۗ\�Z�N�x�̑O�X�\�Z�N�x
--    lb_retcode              BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
--    -- =============================================================================
--    -- 1.�̎�̋��\�Z�e�[�u���̃��b�N���擾
--    -- =============================================================================
--    CURSOR lock_acct_cur(
--             in_two_years_past_year IN NUMBER
--           )
--    IS
--      SELECT 'X'
--      FROM   xxcok_bm_support_budget xbsb
--      WHERE  TO_NUMBER( xbsb.budget_year ) <= in_two_years_past_year
--      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- �����Ώۗ\�Z�N�x�̑O�X�\�Z�N�x�����߂�
--    -- =============================================================================
--    ln_two_years_past_year := gn_target_account_year - cn_2;
--    -- =============================================================================
--    -- �̎�̋��\�Z�e�[�u���̃��b�N���擾
--    -- =============================================================================
--    OPEN  lock_acct_cur(
--            ln_two_years_past_year
--          );
--    CLOSE lock_acct_cur;
--    -- =============================================================================
--    -- �̎�̋��\�Z�e�[�u����背�R�[�h���폜
--    -- =============================================================================
--    BEGIN
--      DELETE FROM xxcok_bm_support_budget xbsb
--      WHERE  TO_NUMBER( xbsb.budget_year ) <= ln_two_years_past_year;
--    EXCEPTION
--      -- *** �폜�Ɏ��s�����ꍇ ***
--      WHEN OTHERS THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10111
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( ln_two_years_past_year )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                    , iv_message  => lv_msg              --���b�Z�[�W
--                    , in_new_line => 0                   --���s
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    END;
--  EXCEPTION
--    -- ***���b�N�Ɏ��s�����ꍇ ***
--    WHEN global_lock_fail THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10107
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( ln_two_years_past_year )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                    , iv_message  => lv_msg              --���b�Z�[�W
--                    , in_new_line => 0                   --���s
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_past_acct_year_data;
----
--  /**********************************************************************************
--   * Procedure Name   : ins_bm_support_budget
--   * Description      : �̎�̋��\�Z�e�[�u���f�[�^�o�^(A-6)
--   ***********************************************************************************/
--  PROCEDURE ins_bm_support_budget(
--    ov_errbuf               OUT VARCHAR2    --�G���[�E���b�Z�[�W
--  , ov_retcode              OUT VARCHAR2    --���^�[���E�R�[�h
--  , ov_errmsg               OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
--  , iv_budget_year          IN  VARCHAR2    --�\�Z�N�x
--  , iv_base_code            IN  VARCHAR2    --���_�R�[�h
--  , iv_corp_code            IN  VARCHAR2    --��ƃR�[�h
--  , iv_sales_outlets_code   IN  VARCHAR2    --�≮������R�[�h
--  , iv_acct_code            IN  VARCHAR2    --����ȖڃR�[�h
--  , iv_sub_acct_code        IN  VARCHAR2    --�⏕�ȖڃR�[�h
--  , iv_target_month         IN  VARCHAR2    --���x
--  , iv_budget_amt           IN  VARCHAR2    --�\�Z���z
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'ins_bm_support_budget';   --�v���O������
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD START
--    cv_no_adj_flag               gl_periods.adjustment_period_flag%TYPE := 'N';
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD END
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode                   VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg                       VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lb_retcode                   BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--    ln_bm_support_budget_id      NUMBER         DEFAULT 0;                  --�̎�̋��\�ZID
--    lv_target_month              VARCHAR2(2)    DEFAULT NULL;               --���x
--    ln_chr_length                NUMBER         DEFAULT 0;                  --���x������
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD START
--    lt_target_ym                 xxcok_bm_support_budget.target_month%TYPE DEFAULT NULL; -- �N��
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD END
----
--  BEGIN
--    ov_retcode := cv_status_normal;
----
--    -- =============================================================================
--    -- �̎�̋��\�ZID���V�[�P���X���擾
--    -- =============================================================================
--    SELECT xxcok_bm_support_budget_s01.NEXTVAL AS xxcok_bm_support_budget_s01
--    INTO   ln_bm_support_budget_id
--    FROM   DUAL;
--    -- =============================================================================
--    -- ���x��������
--    -- =============================================================================
--    ln_chr_length := LENGTHB( iv_target_month );
--    --�P���œ��͂���Ă���ꍇ�A��'�O'��t�^���Q���ɂ���
--    IF ( ln_chr_length = cn_1 ) THEN
--      lv_target_month := ( cv_0 || iv_target_month );
--    ELSE
--      lv_target_month := iv_target_month;
--    END IF;
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD START
--    -- =============================================================================
--    -- �N������
--    -- =============================================================================
--    SELECT TO_CHAR( gp.start_date, 'RRRRMM' )
--    INTO lt_target_ym
--    FROM gl_periods                gp                          -- ��v�J�����_�e�[�u��
--       , gl_sets_of_books          gsob                        -- ��v����}�X�^
--    WHERE gp.period_set_name             = gsob.period_set_name
--      AND gsob.set_of_books_id           = TO_NUMBER( gv_set_of_books_id )
--      AND gp.period_year                 = TO_NUMBER( iv_budget_year )
--      AND gp.adjustment_period_flag      = cv_no_adj_flag
--      AND TO_CHAR( gp.start_date, 'MM' ) = lv_target_month
--    ;
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi ADD END
--    -- =============================================================================
--    -- �̎�̋��\�Z�e�[�u���փ��R�[�h�̒ǉ�
--    -- =============================================================================
--    INSERT INTO xxcok_bm_support_budget(
--      bm_support_budget_id                                 --�̎�̋��\�ZID
--    , company_code                                         --��ЃR�[�h
--    , budget_year                                          --�\�Z�N�x
--    , base_code                                            --���_�R�[�h
--    , corp_code                                            --��ƃR�[�h
--    , sales_outlets_code                                   --�≮������R�[�h
--    , acct_code                                            --����ȖڃR�[�h
--    , sub_acct_code                                        --�⏕�ȖڃR�[�h
--    , target_month                                         --���x
--    , budget_amt                                           --�\�Z���z
--    , info_interface_status                                --���n�A�g�X�e�[�^�X
--    , created_by                                           --�쐬��
--    , creation_date                                        --�쐬��
--    , last_updated_by                                      --�ŏI�X�V��
--    , last_update_date                                     --�ŏI�X�V��
--    , last_update_login                                    --�ŏI�X�V���O�C��
--    , request_id                                           --�v��ID
--    , program_application_id                               --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--    , program_id                                           --�R���J�����g�E�v���O����ID
--    , program_update_date                                  --�v���O�����X�V��
--    ) VALUES (
--      ln_bm_support_budget_id                              --bm_support_budget_id
--    , gv_company_code                                      --company_code
--    , iv_budget_year                                       --budget_year
--    , iv_base_code                                         --base_code
--    , iv_corp_code                                         --corp_code
--    , iv_sales_outlets_code                                --sales_outlets_code
--    , iv_acct_code                                         --acct_code
--    , iv_sub_acct_code                                     --sub_acct_code
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi REPAIR START
----    , iv_budget_year || lv_target_month                    --target_month
--    , lt_target_ym                                         --target_month
---- 2009/06/12 Ver.1.1 [��QT1_1433] SCS K.Yamaguchi REPAIR END
--    , TO_NUMBER( iv_budget_amt )                           --budget_amt
--    , cv_info_interface_status                             --info_interface_status
--    , cn_created_by                                        --created_by
--    , SYSDATE                                              --creation_date
--    , cn_last_updated_by                                   --last_updated_by
--    , SYSDATE                                              --last_update_date
--    , cn_last_update_login                                 --last_update_login
--    , cn_request_id                                        --request_id
--    , cn_program_application_id                            --program_application_id
--    , cn_program_id                                        --program_id
--    , SYSDATE                                              --program_update_date
--    );
--    -- *** ���������J�E���g ***
--    gn_normal_cnt := gn_normal_cnt + 1;
--  EXCEPTION
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� (�ǉ������G���[) ***
--    WHEN OTHERS THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10449
--                , iv_token_name1  => cv_token_budget_year
--                , iv_token_value1 => iv_budget_year
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END ins_bm_support_budget;
----
--  /**********************************************************************************
--   * Procedure Name   : chk_data_month_amt
--   * Description      : �Ó����`�F�b�N(���x�A�\�Z���z)(A-5-1)
--   ***********************************************************************************/
--  PROCEDURE chk_data_month_amt(
--    ov_errbuf                    OUT VARCHAR2                     --�G���[�E���b�Z�[�W
--  , ov_retcode                   OUT VARCHAR2                     --���^�[���E�R�[�h
--  , ov_errmsg                    OUT VARCHAR2                     --���[�U�[�E�G���[�E���b�Z�[�W
--  , iv_target_month              IN  VARCHAR2                     --���x
--  , iv_budget_amt                IN  VARCHAR2                     --�\�Z���z
--  , in_occurs                    IN  NUMBER                       --���x�A�\�Z���z�̏���
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'chk_data_month_amt';     --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode              VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lv_target_month         VARCHAR2(2)    DEFAULT NULL;               --���x�ޔ�p
--    lv_occurs               VARCHAR2(2)    DEFAULT NULL;               --���x�A�\�Z���z�̏���(�\���p)
--    lb_retcode              BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--    lb_chk_number           BOOLEAN        DEFAULT TRUE;               --���p�����`�F�b�N�̌���
--    ln_chr_length           NUMBER         DEFAULT 0;                  --�����`�F�b�N
--    ld_chk_month            DATE           DEFAULT NULL;               --���t�^�ϊ��`�F�b�N�p
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- ���x�A�\�Z���z�̏���(�\���p)��ݒ�
--    -- =============================================================================
--    ln_chr_length := LENGTHB( in_occurs );
--    IF ( ln_chr_length = cn_1 ) THEN
--      lv_occurs   := ( cv_0 || TO_CHAR( in_occurs ) );
--    ELSE
--      lv_occurs   := TO_CHAR( in_occurs );
--    END IF;
--    -- =============================================================================
--    -- �K�{���ڃ`�F�b�N
--    -- =============================================================================
--    --���x
--    IF ( iv_target_month IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10423
--                , iv_token_name1  => cv_token_occurs
--                , iv_token_value1 => lv_occurs
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --�\�Z���z
--    IF ( iv_budget_amt IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10424
--                , iv_token_name1  => cv_token_occurs
--                , iv_token_value1 => lv_occurs
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    -- =============================================================================
--    -- �f�[�^�^�`�F�b�N(���p�����`�F�b�N)
--    -- =============================================================================
--    --�\�Z���z
--    lb_chk_number := xxccp_common_pkg.chk_number(
--                       iv_check_char => iv_budget_amt
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10123
--                , iv_token_name1  => cv_token_occurs
--                , iv_token_value1 => lv_occurs
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
--    -- =============================================================================
--    -- ���t�^�ϊ��`�F�b�N(�l��NULL�̏ꍇ�`�F�b�N�ΏۊO)
--    -- =============================================================================
--    --���x
--    BEGIN
--      IF ( iv_target_month IS NOT NULL ) THEN
--        ln_chr_length := LENGTHB( iv_target_month );
--        --�P���œ��͂���Ă���ꍇ�A��'�O'��t�^���Q���ɂ��ă`�F�b�N����
--        IF ( ln_chr_length = cn_1 ) THEN
--          lv_target_month := ( cv_0 || iv_target_month );
--        ELSE
--          lv_target_month := iv_target_month;
--        END IF;
--        ld_chk_month  := TO_DATE( TO_CHAR( gn_target_account_year ) || lv_target_month, cv_date_format_yyyymm );
--      END IF;
--    EXCEPTION
--      -- *** �ϊ��ł��Ȃ������ꍇ�A��O���� ***
--      WHEN OTHERS THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_10425
--                  , iv_token_name1  => cv_token_occurs
--                  , iv_token_value1 => lv_occurs
--                  , iv_token_name2  => cv_token_row_num
--                  , iv_token_value2 => TO_CHAR( gn_line_no )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                      , iv_message  => lv_msg            --���b�Z�[�W
--                      , in_new_line => 0                 --���s
--                      );
--        ov_retcode := cv_status_continue;
--    END;
--    -- =============================================================================
--    -- �����`�F�b�N(�l��NULL�̏ꍇ�`�F�b�N�ΏۊO)
--    -- =============================================================================
--    --�\�Z���z
--    IF ( iv_budget_amt IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( iv_budget_amt );
----
--       IF ( ln_chr_length > cn_12 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10130
--                   , iv_token_name1  => cv_token_occurs
--                   , iv_token_value1 => lv_occurs
--                   , iv_token_name2  => cv_token_row_num
--                   , iv_token_value2 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                       , iv_message  => lv_msg            --���b�Z�[�W
--                       , in_new_line => 0                 --���s
--                       );
--         ov_retcode := cv_status_continue;
--      END IF;
----
--    END IF;
----
--  EXCEPTION
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END chk_data_month_amt;
----
--  /**********************************************************************************
--   * Procedure Name   : chk_data
--   * Description      : �Ó����`�F�b�N(A-5)
--   ***********************************************************************************/
--  PROCEDURE chk_data(
--    ov_errbuf                    OUT VARCHAR2                      --�G���[�E���b�Z�[�W
--  , ov_retcode                   OUT VARCHAR2                      --���^�[���E�R�[�h
--  , ov_errmsg                    OUT VARCHAR2                      --���[�U�[�E�G���[�E���b�Z�[�W
--  , it_csv_bm_support_budget_rec IN  gr_csv_bm_support_budget_tab  --CSV�̎�̋��\�Z�f�[�^�E���R�[�h�^
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'chk_data';     --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode              VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lv_target_month         VARCHAR2(100)  DEFAULT NULL;               --���x
--    lv_budget_amt           VARCHAR2(100)  DEFAULT NULL;               --�\�Z���z
--    lb_retcode              BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--    lb_chk_number           BOOLEAN        DEFAULT TRUE;               --���p�����`�F�b�N�̌���
--    ln_chr_length           NUMBER         DEFAULT 0;                  --�����`�F�b�N
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- �K�{���ڃ`�F�b�N
--    -- =============================================================================
--    --�\�Z�N�x
--    IF ( it_csv_bm_support_budget_rec.budget_year IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10417
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --���_�R�[�h
--    IF ( it_csv_bm_support_budget_rec.base_code IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10418
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --��ƃR�[�h
--    IF ( it_csv_bm_support_budget_rec.corp_code IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10419
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --�≮������R�[�h
--    IF ( it_csv_bm_support_budget_rec.sales_outlets_code IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10420
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --����ȖڃR�[�h
--    IF ( it_csv_bm_support_budget_rec.acct_code IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10421
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --�⏕�ȖڃR�[�h
--    IF ( it_csv_bm_support_budget_rec.sub_acct_code IS NULL ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10422
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    -- =============================================================================
--    -- CSV�t�@�C���̗\�Z�N�x�Ə����Ώۉ�v�N�x�̔�r
--    -- =============================================================================
--    IF ( it_csv_bm_support_budget_rec.budget_year IS NOT NULL ) THEN
--      IF ( it_csv_bm_support_budget_rec.budget_year <> TO_CHAR( gn_target_account_year ) ) THEN
--        -- *** �\�Z�N�x�Ə����Ώۉ�v�N�x�����Ⴗ��ꍇ�A��O���� ***
--        lv_msg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcok_appl_name
--                  , iv_name         => cv_err_msg_10109
--                  , iv_token_name1  => cv_token_budget_year
--                  , iv_token_value1 => it_csv_bm_support_budget_rec.budget_year
--                  , iv_token_name2  => cv_token_object_year
--                  , iv_token_value2 => TO_CHAR( gn_target_account_year )
--                  , iv_token_name3  => cv_token_row_num
--                  , iv_token_value3 => TO_CHAR( gn_line_no )
--                  );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                      , iv_message  => lv_msg            --���b�Z�[�W
--                      , in_new_line => 0                 --���s
--                      );
--        ov_retcode := cv_status_continue;
--      END IF;
--    END IF;
----
--    -- =============================================================================
--    -- �f�[�^�^�`�F�b�N(���p�p�����`�F�b�N)
--    -- =============================================================================
--    --���_�R�[�h
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.base_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10135
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --��ƃR�[�h
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.corp_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10136
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --�≮������R�[�h
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.sales_outlets_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10137
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --����ȖڃR�[�h
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.acct_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10138
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    --�⏕�ȖڃR�[�h
--    lb_chk_number := xxccp_common_pkg.chk_alphabet_number_only(
--                       iv_check_char => it_csv_bm_support_budget_rec.sub_acct_code
--                     );
----
--    IF ( lb_chk_number = FALSE ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10139
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( gn_line_no )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
----
--    -- =============================================================================
--    -- �����`�F�b�N(�l��NULL�̏ꍇ�`�F�b�N�ΏۊO)
--    -- =============================================================================
--    --���_�R�[�h
--    IF ( it_csv_bm_support_budget_rec.base_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.base_code );
----
--       IF ( ln_chr_length <> cn_4 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10126
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                       , iv_message  => lv_msg            --���b�Z�[�W
--                       , in_new_line => 0                 --���s
--                       );
--         ov_retcode := cv_status_continue;
--      END IF;
----
--    END IF;
----
--    --��ƃR�[�h
--    IF ( it_csv_bm_support_budget_rec.corp_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.corp_code );
----
--       IF ( ln_chr_length <> cn_6 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10127
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                       , iv_message  => lv_msg            --���b�Z�[�W
--                       , in_new_line => 0                 --���s
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    --�≮������R�[�h
--    IF ( it_csv_bm_support_budget_rec.sales_outlets_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.sales_outlets_code );
----
--       IF ( ln_chr_length <> cn_9 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10125
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                       , iv_message  => lv_msg            --���b�Z�[�W
--                       , in_new_line => 0                 --���s
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    --����ȖڃR�[�h
--    IF ( it_csv_bm_support_budget_rec.acct_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.acct_code );
----
--       IF ( ln_chr_length <> cn_5 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10128
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                       , iv_message  => lv_msg            --���b�Z�[�W
--                       , in_new_line => 0                 --���s
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    --�⏕�ȖڃR�[�h
--    IF ( it_csv_bm_support_budget_rec.sub_acct_code IS NOT NULL ) THEN
--       ln_chr_length := LENGTHB( it_csv_bm_support_budget_rec.sub_acct_code );
----
--       IF ( ln_chr_length <> cn_5 ) THEN
--         lv_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_xxcok_appl_name
--                   , iv_name         => cv_err_msg_10129
--                   , iv_token_name1  => cv_token_row_num
--                   , iv_token_value1 => TO_CHAR( gn_line_no )
--                   );
--         lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                       , iv_message  => lv_msg            --���b�Z�[�W
--                       , in_new_line => 0                 --���s
--                       );
--         ov_retcode := cv_status_continue;
--       END IF;
----
--    END IF;
----
--    -- =============================================================================
--    -- ���x�A�\�Z���z�`�F�b�N
--    -- =============================================================================
--    <<chk_loop>>
--    FOR ln_idx IN 1 .. 12 LOOP
--      IF ln_idx = 1 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_01;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_01;
--      ELSIF ln_idx = 2 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_02;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_02;
--      ELSIF ln_idx = 3 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_03;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_03;
--      ELSIF ln_idx = 4 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_04;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_04;
--      ELSIF ln_idx = 5 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_05;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_05;
--      ELSIF ln_idx = 6 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_06;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_06;
--      ELSIF ln_idx = 7 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_07;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_07;
--      ELSIF ln_idx = 8 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_08;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_08;
--      ELSIF ln_idx = 9 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_09;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_09;
--      ELSIF ln_idx = 10 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_10;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_10;
--      ELSIF ln_idx = 11 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_11;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_11;
--      ELSIF ln_idx = 12 THEN
--         lv_target_month := it_csv_bm_support_budget_rec.target_month_12;
--         lv_budget_amt   := it_csv_bm_support_budget_rec.budget_amt_12;
--      END IF;
----
--      -- =============================================================================
--      -- �Ó����`�F�b�N(���x�A�\�Z���z)(A-5-1)�ďo��
--      -- =============================================================================
--      chk_data_month_amt(
--        ov_errbuf                    => lv_errbuf                          --�G���[�E���b�Z�[�W
--      , ov_retcode                   => lv_retcode                         --���^�[���E�R�[�h
--      , ov_errmsg                    => lv_errmsg                          --���[�U�[�E�G���[�E���b�Z�[�W
--      , iv_target_month              => lv_target_month                    --���x
--      , iv_budget_amt                => lv_budget_amt                      --�\�Z���z
--      , in_occurs                    => ln_idx                             --���x�A�\�Z���z�̏���
--      );
--      IF ( lv_retcode = cv_status_continue ) THEN
--        ov_retcode := cv_status_continue;
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--    END LOOP chk_loop;
----
--  EXCEPTION
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END chk_data;
----
--  /**********************************************************************************
--   * Procedure Name   : get_file_data
--   * Description      : �t�@�C���f�[�^�擾(A-4)
--   ***********************************************************************************/
--  PROCEDURE get_file_data(
--    ov_errbuf   OUT VARCHAR2     --�G���[�E���b�Z�[�W
--  , ov_retcode  OUT VARCHAR2     --���^�[���E�R�[�h
--  , ov_errmsg   OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
--  , in_file_id  IN  NUMBER       --�t�@�C��ID
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'get_file_data';   --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf               VARCHAR2(5000)  DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode              VARCHAR2(1)     DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg               VARCHAR2(5000)  DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg                  VARCHAR2(5000)  DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lv_file_name            VARCHAR2(256)   DEFAULT NULL;               --�t�@�C����
--    lv_line                 VARCHAR2(32767) DEFAULT NULL;               --1�s�̃f�[�^
--    lb_retcode              BOOLEAN         DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--    ln_col                  NUMBER          DEFAULT 0;                  --�J����
--    ln_loop_cnt             NUMBER          DEFAULT 0;                  --LOOP�J�E���^
--    ln_csv_col_cnt          NUMBER          DEFAULT 0;                  --CSV���ڐ�
--    lv_target_month         VARCHAR2(100)   DEFAULT NULL;               --���x(�ޔ�p)
--    lv_budget_amt           VARCHAR2(100)   DEFAULT NULL;               --�\�Z���z(�ޔ�p)
--    -- =======================
--    -- ���[�J��TABLE�^�ϐ�
--    -- =======================
--    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;   --�s�e�[�u���i�[�̈�
--    l_split_csv_tab   xxcok_common_pkg.g_split_csv_tbl;    --CSV�����f�[�^�i�[�̈�
--    -- =======================
--    -- ���[�J���J�[�\��
--    -- =======================
--    -- =============================================================================
--    -- �t�@�C���A�b�v���[�hIF�\�̃f�[�^�E���b�N���擾
--    -- =============================================================================
--    CURSOR xmfui_cur
--    IS
--      SELECT xmfui.file_name AS file_name
--      FROM   xxccp_mrp_file_ul_interface xmfui
--      WHERE  xmfui.file_id = in_file_id
--      FOR UPDATE OF xmfui.file_id NOWAIT;
--    -- =======================
--    -- ���[�J�����R�[�h
--    -- =======================
--    xmfui_rec  xmfui_cur%ROWTYPE;
--    -- =======================
--    -- ���[�J����O
--    -- =======================
--    blob_expt  EXCEPTION;   --BLOB�f�[�^�ϊ��G���[
--    file_expt  EXCEPTION;   --��t�@�C���G���[
----
--  BEGIN
--    ov_retcode := cv_status_normal;
----
--    OPEN  xmfui_cur;
--      FETCH xmfui_cur INTO xmfui_rec;
--      lv_file_name := xmfui_rec.file_name;
--    CLOSE xmfui_cur;
--    -- =============================================================================
--    -- �t�@�C�������b�Z�[�W�o��
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxcok_appl_name
--              , iv_name         => cv_message_00006
--              , iv_token_name1  => cv_token_file_name
--              , iv_token_value1 => lv_file_name
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                  , iv_message  => lv_msg            --���b�Z�[�W
--                  , in_new_line => 1                 --���s
--                  );
--    -- =============================================================================
--    -- BLOB�f�[�^�ϊ�
--    -- =============================================================================
--    xxccp_common_pkg2.blob_to_varchar2(
--      ov_errbuf    => lv_errbuf
--    , ov_retcode   => lv_retcode
--    , ov_errmsg    => lv_errmsg
--    , in_file_id   => in_file_id
--    , ov_file_data => l_file_data_tab
--    );
--    -- *** ���^�[���R�[�h��0(����)�ȊO�̏ꍇ�A��O���� ***
--    IF NOT ( lv_retcode = cv_status_normal ) THEN
--      RAISE blob_expt;
--    END IF;
--    -- =============================================================================
--    -- �擾�����f�[�^�������`�F�b�N(������1���ȉ��̏ꍇ�A��O����)
--    -- =============================================================================
--    IF ( l_file_data_tab.COUNT <= cn_1 ) THEN
--      RAISE file_expt;
--    END IF;
--    -- =============================================================================
--    -- �Ώی�����ݒ�
--    -- =============================================================================
--    gn_target_cnt := l_file_data_tab.COUNT - cn_1;
--    -- =============================================================================
--    -- ������𕪊�
--    -- =============================================================================
--    <<main_loop>>
--    FOR ln_index IN 2 .. l_file_data_tab.COUNT LOOP
--      --LOOP�J�E���^
--      ln_loop_cnt := ln_loop_cnt + 1;
--      --1�s���̃f�[�^���i�[
--      lv_line := l_file_data_tab( ln_index );
--      -- =============================================================================
--      -- �ϐ��̏�����
--      -- =============================================================================
--      l_split_csv_tab.delete;
----
--      gr_csv_bm_support_budget_rec := NULL;
--      -- =============================================================================
--      -- CSV�����񕪊�
--      -- =============================================================================
--      xxcok_common_pkg.split_csv_data_p(
--        ov_errbuf        => lv_errbuf         --�G���[�o�b�t�@
--      , ov_retcode       => lv_retcode        --���^�[���R�[�h
--      , ov_errmsg        => lv_errmsg         --�G���[���b�Z�[�W
--      , iv_csv_data      => lv_line           --CSV������
--      , on_csv_col_cnt   => ln_csv_col_cnt    --CSV���ڐ�
--      , ov_split_csv_tab => l_split_csv_tab   --CSV�����f�[�^
--      );
--      <<comma_loop>>
--      FOR ln_cnt IN 1 .. ln_csv_col_cnt LOOP
--        --����1(�\�Z�N�x)
--        IF    ( ln_cnt = 1 ) THEN
--          gr_csv_bm_support_budget_rec.budget_year         := l_split_csv_tab( ln_cnt );
--        --����2(���_�R�[�h)
--        ELSIF ( ln_cnt = 2 ) THEN
--          gr_csv_bm_support_budget_rec.base_code           := l_split_csv_tab( ln_cnt );
--        --����3(��ƃR�[�h)
--        ELSIF ( ln_cnt = 3 ) THEN
--          gr_csv_bm_support_budget_rec.corp_code           := l_split_csv_tab( ln_cnt );
--        --����4(�≮������R�[�h)
--        ELSIF ( ln_cnt = 4 ) THEN
--          gr_csv_bm_support_budget_rec.sales_outlets_code  := l_split_csv_tab( ln_cnt );
--        --����5(����ȖڃR�[�h)
--        ELSIF ( ln_cnt = 5 ) THEN
--          gr_csv_bm_support_budget_rec.acct_code           := l_split_csv_tab( ln_cnt );
--        --����6(�⏕�ȖڃR�[�h)
--        ELSIF ( ln_cnt = 6 ) THEN
--          gr_csv_bm_support_budget_rec.sub_acct_code       := l_split_csv_tab( ln_cnt );
--        --����7(���x_01)
--        ELSIF ( ln_cnt = 7 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_01     := l_split_csv_tab( ln_cnt );
--        --����8(�\�Z���z_01)
--        ELSIF ( ln_cnt = 8 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_01       := l_split_csv_tab( ln_cnt );
--        --����9(���x_02)
--        ELSIF ( ln_cnt = 9 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_02     := l_split_csv_tab( ln_cnt );
--        --����10(�\�Z���z_02)
--        ELSIF ( ln_cnt = 10 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_02       := l_split_csv_tab( ln_cnt );
--        --����11(���x_03)
--        ELSIF ( ln_cnt = 11 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_03     := l_split_csv_tab( ln_cnt );
--        --����12(�\�Z���z_03)
--        ELSIF ( ln_cnt = 12 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_03       := l_split_csv_tab( ln_cnt );
--        --����13(���x_04)
--        ELSIF ( ln_cnt = 13 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_04     := l_split_csv_tab( ln_cnt );
--        --����14(�\�Z���z_04)
--        ELSIF ( ln_cnt = 14 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_04       := l_split_csv_tab( ln_cnt );
--        --����15(���x_05)
--        ELSIF ( ln_cnt = 15 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_05     := l_split_csv_tab( ln_cnt );
--        --����16(�\�Z���z_05)
--        ELSIF ( ln_cnt = 16 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_05       := l_split_csv_tab( ln_cnt );
--        --����17(���x_06)
--        ELSIF ( ln_cnt = 17 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_06     := l_split_csv_tab( ln_cnt );
--        --����18(�\�Z���z_06)
--        ELSIF ( ln_cnt = 18 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_06       := l_split_csv_tab( ln_cnt );
--        --����19(���x_07)
--        ELSIF ( ln_cnt = 19 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_07     := l_split_csv_tab( ln_cnt );
--        --����20(�\�Z���z_07)
--        ELSIF ( ln_cnt = 20 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_07       := l_split_csv_tab( ln_cnt );
--        --����21(���x_08)
--        ELSIF ( ln_cnt = 21 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_08     := l_split_csv_tab( ln_cnt );
--        --����22(�\�Z���z_08)
--        ELSIF ( ln_cnt = 22 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_08       := l_split_csv_tab( ln_cnt );
--        --����23(���x_09)
--        ELSIF ( ln_cnt = 23 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_09     := l_split_csv_tab( ln_cnt );
--        --����24(�\�Z���z_09)
--        ELSIF ( ln_cnt = 24 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_09       := l_split_csv_tab( ln_cnt );
--        --����25(���x_10)
--        ELSIF ( ln_cnt = 25 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_10     := l_split_csv_tab( ln_cnt );
--        --����26(�\�Z���z_10)
--        ELSIF ( ln_cnt = 26 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_10       := l_split_csv_tab( ln_cnt );
--        --����27(���x_11)
--        ELSIF ( ln_cnt = 27 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_11     := l_split_csv_tab( ln_cnt );
--        --����28(�\�Z���z_11)
--        ELSIF ( ln_cnt = 28 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_11       := l_split_csv_tab( ln_cnt );
--        --����29(���x_12)
--        ELSIF ( ln_cnt = 29 ) THEN
--          gr_csv_bm_support_budget_rec.target_month_12     := l_split_csv_tab( ln_cnt );
--        --����30(�\�Z���z_12)
--        ELSIF ( ln_cnt = 30 ) THEN
--          gr_csv_bm_support_budget_rec.budget_amt_12       := l_split_csv_tab( ln_cnt );
--        END IF;
--      END LOOP comma_loop;
----
--      --�s���J�E���^���O���[�o���ϐ��փZ�b�g
--      gn_line_no := ln_index;
--      -- =============================================================================
--      -- �Ó����`�F�b�N(A-5)�ďo��
--      -- =============================================================================
--      chk_data(
--        ov_errbuf                    => lv_errbuf                          --�G���[�E���b�Z�[�W
--      , ov_retcode                   => lv_retcode                         --���^�[���E�R�[�h
--      , ov_errmsg                    => lv_errmsg                          --���[�U�[�E�G���[�E���b�Z�[�W
--      , it_csv_bm_support_budget_rec => gr_csv_bm_support_budget_rec       --CSV�̎�̋��\�Z�f�[�^�E���R�[�h�^
--      );
----
--      IF ( lv_retcode = cv_status_continue ) THEN
--        gv_chk_code  := lv_retcode;
--        ov_retcode   := lv_retcode;
--        gn_error_cnt := gn_error_cnt + 1;
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--      -- =============================================================================
--      -- �Ó����`�F�b�N�ŃG���[���������Ă��Ȃ����A-6�����s
--      -- =============================================================================
--      IF NOT ( gv_chk_code = cv_status_continue ) THEN
--         <<ins_loop>>
--         FOR ln_idx2 IN 1 .. 12 LOOP
--           IF ln_idx2 = 1 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_01;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_01;
--           ELSIF ln_idx2 = 2 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_02;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_02;
--           ELSIF ln_idx2 = 3 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_03;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_03;
--           ELSIF ln_idx2 = 4 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_04;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_04;
--           ELSIF ln_idx2 = 5 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_05;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_05;
--           ELSIF ln_idx2 = 6 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_06;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_06;
--           ELSIF ln_idx2 = 7 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_07;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_07;
--           ELSIF ln_idx2 = 8 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_08;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_08;
--           ELSIF ln_idx2 = 9 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_09;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_09;
--           ELSIF ln_idx2 = 10 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_10;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_10;
--           ELSIF ln_idx2 = 11 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_11;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_11;
--           ELSIF ln_idx2 = 12 THEN
--             lv_target_month := gr_csv_bm_support_budget_rec.target_month_12;
--             lv_budget_amt   := gr_csv_bm_support_budget_rec.budget_amt_12;
--           END IF;
--           -- =============================================================================
--           -- �̎�̋��\�Z���o�^(A-6)�ďo��
--           -- =============================================================================
--           ins_bm_support_budget(
--             ov_errbuf              => lv_errbuf                          --�G���[�E���b�Z�[�W
--           , ov_retcode             => lv_retcode                         --���^�[���E�R�[�h
--           , ov_errmsg              => lv_errmsg                          --���[�U�[�E�G���[�E���b�Z�[�W
--           , iv_budget_year         => gr_csv_bm_support_budget_rec.budget_year         --�\�Z�N�x
--           , iv_base_code           => gr_csv_bm_support_budget_rec.base_code           --���_�R�[�h
--           , iv_corp_code           => gr_csv_bm_support_budget_rec.corp_code           --��ƃR�[�h
--           , iv_sales_outlets_code  => gr_csv_bm_support_budget_rec.sales_outlets_code  --�≮������R�[�h
--           , iv_acct_code           => gr_csv_bm_support_budget_rec.acct_code           --����ȖڃR�[�h
--           , iv_sub_acct_code       => gr_csv_bm_support_budget_rec.sub_acct_code       --�⏕�ȖڃR�[�h
--           , iv_target_month        => lv_target_month                                  --���x
--           , iv_budget_amt          => lv_budget_amt                                    --�\�Z���z
--           );
--           IF ( lv_retcode = cv_status_error ) THEN
--             RAISE global_process_expt;
--           END IF;
--         END LOOP ins_loop;
--      END IF;
----
--    END LOOP main_loop;
----
--      -- =============================================================================
--      -- �Ó����`�F�b�N�ŃG���[���������Ă��Ȃ����A-7�����s
--      -- =============================================================================
--      IF NOT ( gv_chk_code = cv_status_continue ) THEN
--        -- =============================================================================
--        -- �O�X�N�x�\�Z�f�[�^�폜(A-7)�ďo��
--        -- =============================================================================
--        del_past_acct_year_data(
--          ov_errbuf              => lv_errbuf                                         --�G���[�E���b�Z�[�W
--        , ov_retcode             => lv_retcode                                        --���^�[���E�R�[�h
--        , ov_errmsg              => lv_errmsg                                         --���[�U�[�E�G���[�E���b�Z�[�W
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      ELSE
--        -- =============================================================================
--        -- �Ó����`�F�b�N�ŃG���[���������Ă����ꍇ�͗\�Z�N�x�d���f�[�^���폜���Ȃ�
--        -- =============================================================================
--        ROLLBACK TO del_acct_year_dupl_save;
--      END IF;
----
--  EXCEPTION
--    -- *** ���b�N���s ***
--    WHEN global_lock_fail THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00061
--                , iv_token_name1  => cv_token_file_id
--                , iv_token_value1 => TO_CHAR( in_file_id )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** BLOB�f�[�^�ϊ��G���[ ***
--    WHEN blob_expt THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00041
--                , iv_token_name1  => cv_token_file_id
--                , iv_token_value1 => TO_CHAR( in_file_id )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ��t�@�C���G���[ ***
--    WHEN file_expt THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00039
--                , iv_token_name1  => cv_token_file_id
--                , iv_token_value1 => TO_CHAR( in_file_id )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END get_file_data;
----
--  /**********************************************************************************
--   * Procedure Name   : del_acct_year_dupl_data
--   * Description      : �\�Z�N�x�d���f�[�^�폜(A-3)
--   ***********************************************************************************/
--  PROCEDURE del_acct_year_dupl_data(
--    ov_errbuf  OUT VARCHAR2    --�G���[�E���b�Z�[�W
--  , ov_retcode OUT VARCHAR2    --���^�[���E�R�[�h
--  , ov_errmsg  OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name  CONSTANT VARCHAR2(50) := 'del_acct_year_dupl_data';   --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
--    lv_retcode              VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
--    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg                  VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
--    ln_two_years_past_year  NUMBER         DEFAULT 0;      --�����Ώۗ\�Z�N�x�̑O�X�\�Z�N�x
--    lb_retcode              BOOLEAN        DEFAULT NULL;   --���b�Z�[�W�o�̖͂߂�l
--    -- =============================================================================
--    -- 1.�̎�̋��\�Z�e�[�u���̃��b�N���擾
--    -- =============================================================================
--    CURSOR lock_dupl_cur
--    IS
--      SELECT 'X'
--      FROM   xxcok_bm_support_budget xbsb
--      WHERE  xbsb.budget_year  = TO_CHAR( gn_target_account_year )
--      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT;
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- �Z�[�u�|�C���g�̐ݒ�
--    -- =============================================================================
--    SAVEPOINT del_acct_year_dupl_save;
--    -- =============================================================================
--    -- �̎�̋��\�Z�e�[�u���̃��b�N���擾
--    -- =============================================================================
--    OPEN  lock_dupl_cur;
--    CLOSE lock_dupl_cur;
--    -- =============================================================================
--    -- �̎�̋��\�Z�e�[�u����背�R�[�h���폜
--    -- =============================================================================
--    BEGIN
--      DELETE FROM xxcok_bm_support_budget xbsb
--      WHERE  xbsb.budget_year = TO_CHAR( gn_target_account_year );
--    EXCEPTION
--      -- *** �폜�Ɏ��s�����ꍇ ***
--      WHEN OTHERS THEN
--        lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10108
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( gn_target_account_year )
--                );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                    , iv_message  => lv_msg              --���b�Z�[�W
--                    , in_new_line => 0                   --���s
--                    );
--        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--        ov_retcode := cv_status_error;
--    END;
--  EXCEPTION
--    -- ***���b�N�Ɏ��s�����ꍇ ***
--    WHEN global_lock_fail THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10107
--                , iv_token_name1  => cv_token_object_year
--                , iv_token_value1 => TO_CHAR( gn_target_account_year )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                    , iv_message  => lv_msg              --���b�Z�[�W
--                    , in_new_line => 0                   --���s
--                    );
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END del_acct_year_dupl_data;
----
--  /**********************************************************************************
--   * Procedure Name   : get_target_acct_year
--   * Description      : �����Ώۉ�v�N�x�擾(A-2)
--   ***********************************************************************************/
--  PROCEDURE get_target_acct_year(
--    ov_errbuf  OUT VARCHAR2                                            -- �G���[�E���b�Z�[�W
--  , ov_retcode OUT VARCHAR2                                            -- ���^�[���E�R�[�h
--  , ov_errmsg  OUT VARCHAR2                                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--  )
--  IS
--    -- ===============================
--    -- ���[�J���萔
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'get_target_acct_year'; -- �v���O������
--    -- ===============================
--    -- ���[�J���ϐ�
--    -- ===============================
--    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;                            -- �G���[�E���b�Z�[�W
--    lv_retcode VARCHAR2(1)    DEFAULT NULL;                            -- ���^�[���E�R�[�h
--    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;                            -- ���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg     VARCHAR2(100)  DEFAULT NULL;                            -- ���b�Z�[�W�o�͕ϐ�
--    lb_retcode BOOLEAN        DEFAULT NULL;                            -- ���b�Z�[�W�o�͊֐��̖߂�l
--    -- ===============================
--    -- ���[�J����O
--    -- ===============================
--    close_status_expt EXCEPTION;                                       -- �I�[�v����v�N�x�擾�G���[
--    effective_expt    EXCEPTION;                                       -- �L����v���Ԏ擾�G���[
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    --==============================================================
--    --��v�N�����擾
--    --==============================================================
--    SELECT COUNT(*)
--    INTO   gn_account_year
--    FROM(
--      SELECT   gps.period_year                                   -- �I�[�v����v�N��
--      FROM     gl_period_statuses           gps
--             , fnd_application              fa
--      WHERE    gps.application_id         = fa.application_id
--      AND      gps.set_of_books_id        = gv_set_of_books_id
--      AND      fa.application_short_name  = cv_sqlgl_appl_name
--      AND      gps.adjustment_period_flag = cv_adjustment_flag
--      AND      gps.closing_status         = cv_status_open
--      GROUP BY gps.period_year
--    );
--    --==============================================================
--    --��v�N����1�̏ꍇ�A�I�[�v�����Ă����v�N�x�̗��N�������ΏۂƂ���
--    --==============================================================
--    IF( gn_account_year = cn_1 ) THEN
--      SELECT   gps.period_year + 1                               -- �����Ώۉ�v�N�x
--      INTO     gn_target_account_year
--      FROM     gl_period_statuses           gps
--             , fnd_application              fa
--      WHERE    gps.application_id         = fa.application_id
--      AND      gps.set_of_books_id        = gv_set_of_books_id
--      AND      fa.application_short_name  = cv_sqlgl_appl_name
--      AND      gps.adjustment_period_flag = cv_adjustment_flag
--      AND      gps.closing_status         = cv_status_open
--      GROUP BY gps.period_year;
--    --==============================================================
--    --��v�N����2�̏ꍇ�A�傫�����̔N�x�������ΏۂƂ���
--    --==============================================================
--    ELSIF( gn_account_year = cn_2 ) THEN
--      SELECT MAX( period_year )
--      INTO   gn_target_account_year
--      FROM( 
--        SELECT   gps.period_year                                 -- �����Ώۉ�v�N�x
--        FROM     gl_period_statuses           gps
--               , fnd_application              fa
--        WHERE    gps.application_id         = fa.application_id
--        AND      gps.set_of_books_id        = gv_set_of_books_id
--        AND      fa.application_short_name  = cv_sqlgl_appl_name
--        AND      gps.adjustment_period_flag = cv_adjustment_flag
--        AND      gps.closing_status         = cv_status_open
--        GROUP BY gps.period_year
--      );
--    --==============================================================
--    --��v���Ԃ̃X�e�[�^�X���I�[�v�����Ă��Ȃ����A�G���[�Ƃ��ď���
--    --==============================================================
--    ELSIF( gn_account_year = 0 ) THEN
--      RAISE close_status_expt;
--    --==============================================================
--    --��v�N������L�ȊO�̏ꍇ�A�G���[�Ƃ��ď���
--    --==============================================================
--    ELSE
--      RAISE effective_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** �I�[�v����v���Ԏ擾�G���[ ***
--    WHEN close_status_expt THEN
--      lv_msg     := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_name
--                    , iv_name         => cv_err_msg_00057
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      in_which        => FND_FILE.OUTPUT    -- �o�͋敪
--                    , iv_message      => lv_msg             -- ���b�Z�[�W
--                    , in_new_line     => 0                  -- ���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** �L����v���Ԏ擾�G���[ ***
--    WHEN effective_expt THEN
--      lv_msg     := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl_name
--                    , iv_name         => cv_err_msg_00059
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f( 
--                      in_which        => FND_FILE.OUTPUT    -- �o�͋敪
--                    , iv_message      => lv_msg             -- ���b�Z�[�W
--                    , in_new_line     => 0                  -- ���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000);
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END get_target_acct_year;
----
--  /**********************************************************************************
--   * Procedure Name   : init
--   * Description      : ��������(A-1)
--   ***********************************************************************************/
--  PROCEDURE init(
--    ov_errbuf          OUT VARCHAR2     --�G���[�E���b�Z�[�W
--  , ov_retcode         OUT VARCHAR2     --���^�[���E�R�[�h
--  , ov_errmsg          OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
--  , in_file_id         IN  NUMBER       --�t�@�C��ID
--  , iv_format_pattern  IN  VARCHAR2     --�t�H�[�}�b�g�p�^�[��
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'init';    --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg           VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lv_profile_name  VARCHAR2(50)   DEFAULT NULL;               --�v���t�@�C�����̕ϐ�
--    lb_retcode       BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--    -- =======================
--    -- ���[�J����O
--    -- =======================
--    get_profile_expt EXCEPTION;   --�J�X�^����v���t�@�C���擾�̗�O����
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- �R���J�����g�v���O�������͍��ڂ����b�Z�[�W�o��
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxcok_appl_name
--              , iv_name         => cv_message_00016
--              , iv_token_name1  => cv_token_file_id
--              , iv_token_value1 => TO_CHAR( in_file_id )
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                  , iv_message  => lv_msg            --���b�Z�[�W
--                  , in_new_line => 0                 --���s
--                  );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.LOG      --�o�͋敪
--                  , iv_message  => lv_msg            --���b�Z�[�W
--                  , in_new_line => 0                 --���s
--                  );
----
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxcok_appl_name
--              , iv_name         => cv_message_00017
--              , iv_token_name1  => cv_token_format
--              , iv_token_value1 => iv_format_pattern
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                  , iv_message  => lv_msg            --���b�Z�[�W
--                  , in_new_line => 1                 --���s
--                  );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.LOG      --�o�͋敪
--                  , iv_message  => lv_msg            --���b�Z�[�W
--                  , in_new_line => 2                 --���s
--                  );
--    -- =============================================================================
--    -- �v���t�@�C�����擾(��v����ID)
--    -- =============================================================================
--    gv_set_of_books_id := FND_PROFILE.VALUE( cv_set_of_bks_id );
----
--    IF ( gv_set_of_books_id IS NULL ) THEN
--      lv_profile_name := cv_set_of_bks_id;
--      RAISE get_profile_expt;
--    END IF;
--    -- =============================================================================
--    -- �v���t�@�C�����擾(��ЃR�[�h)
--    -- =============================================================================
--    gv_company_code := FND_PROFILE.VALUE( cv_company_code );
----
--    IF ( gv_company_code IS NULL ) THEN
--      lv_profile_name := cv_company_code;
--      RAISE get_profile_expt;
--    END IF;
----
--  EXCEPTION
--    -- *** �v���t�@�C���擾�G���[ ***
--    WHEN get_profile_expt THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_00003
--                , iv_token_name1  => cv_token_profile
--                , iv_token_value1 => lv_profile_name
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END init;
----
--  /**********************************************************************************
--   * Procedure Name   : submain
--   * Description      : ���C�������v���V�[�W��
--   **********************************************************************************/
--  PROCEDURE submain(
--    ov_errbuf         OUT VARCHAR2     --�G���[�E���b�Z�[�W
--  , ov_retcode        OUT VARCHAR2     --���^�[���E�R�[�h
--  , ov_errmsg         OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
--  , in_file_id        IN  NUMBER       --�t�@�C��ID
--  , iv_format_pattern IN  VARCHAR2     --�t�H�[�}�b�g�p�^�[��
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name  CONSTANT VARCHAR2(50) := 'submain';   --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lb_retcode   BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
----
--  BEGIN
--    ov_retcode := cv_status_normal;
--    -- =============================================================================
--    -- ��������(A-1)�̌ďo��
--    -- =============================================================================
--    init(
--      ov_errbuf         => lv_errbuf
--    , ov_retcode        => lv_retcode
--    , ov_errmsg         => lv_errmsg
--    , in_file_id        => in_file_id
--    , iv_format_pattern => iv_format_pattern
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- �����Ώۉ�v�N�x�擾(A-2)�̌ďo��
--    -- =============================================================================
--    get_target_acct_year(
--      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
--    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
--    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- �\�Z�N�x�d���f�[�^�폜(A-3)�̌ďo��
--    -- =============================================================================
--    del_acct_year_dupl_data(
--      ov_errbuf  => lv_errbuf                          -- �G���[�E���b�Z�[�W
--    , ov_retcode => lv_retcode                         -- ���^�[���E�R�[�h
--    , ov_errmsg  => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
--    );
--    IF( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- �t�@�C���f�[�^�擾(A-4)�̌ďo��
--    -- =============================================================================
--    get_file_data(
--      ov_errbuf  => lv_errbuf
--    , ov_retcode => lv_retcode
--    , ov_errmsg  => lv_errmsg
--    , in_file_id => in_file_id
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- �����f�[�^�폜(A-8)�̌ďo��
--    -- =============================================================================
--    del_mrp_file_ul_interface(
--      ov_errbuf  => lv_errbuf
--    , ov_retcode => lv_retcode
--    , ov_errmsg  => lv_errmsg
--    , in_file_id => in_file_id
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_process_expt;
--    END IF;
--    -- =============================================================================
--    -- �Ó����`�F�b�N�ŃG���[�����������ꍇ�A�X�e�[�^�X���G���[�ɐݒ�
--    -- =============================================================================
--    IF ( gv_chk_code = cv_status_continue ) THEN
--      ov_retcode := cv_status_error;
--    END IF;
--  EXCEPTION
--    -- *** ���������ʗ�O�n���h�� ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      ov_retcode := cv_status_error;
--  END submain;
----
--  /**********************************************************************************
--   * Procedure Name   : main
--   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
--   **********************************************************************************/
--  PROCEDURE main(
--    errbuf            OUT  VARCHAR2    --�G���[���b�Z�[�W
--  , retcode           OUT  VARCHAR2    --�G���[�R�[�h
--  , iv_file_id        IN   VARCHAR2    --�t�@�C��ID
--  , iv_format_pattern IN   VARCHAR2    --�t�H�[�}�b�g�p�^�[��
--  )
--  IS
--    -- =======================
--    -- ���[�J���萔
--    -- =======================
--    cv_prg_name   CONSTANT VARCHAR2(50) := 'main';    --�v���O������
--    -- =======================
--    -- ���[�J���ϐ�
--    -- =======================
--    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
--    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
--    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
--    lv_msg           VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
--    lv_message_code  VARCHAR2(500)  DEFAULT NULL;               --���b�Z�[�W�R�[�h
--    lb_retcode       BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--    ln_file_id       NUMBER         DEFAULT 0;                  --�t�@�C��ID
----
--  BEGIN
--    ln_file_id := TO_NUMBER( iv_file_id );
--    -- =============================================================================
--    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
--    -- =============================================================================
--    xxccp_common_pkg.put_log_header(
--      ov_retcode => lv_retcode
--    , ov_errbuf  => lv_errbuf
--    , ov_errmsg  => lv_errmsg
--    );
--    IF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    END IF;
--    -- =============================================================================
--    -- submain�̌ďo��
--    -- =============================================================================
--    submain(
--      ov_errbuf         => lv_errbuf
--    , ov_retcode        => lv_retcode
--    , ov_errmsg         => lv_errmsg
--    , in_file_id        => ln_file_id
--    , iv_format_pattern => iv_format_pattern
--    );
--    -- =============================================================================
--    -- �G���[�o��
--    -- =============================================================================
--    IF ( lv_retcode = cv_status_error ) THEN
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_errmsg         --���b�Z�[�W
--                    , in_new_line => 1                 --���s
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG      --�o�͋敪
--                    , iv_message  => lv_errbuf         --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--    END IF;
--    -- =============================================================================
--    -- �Ώی����o��
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxccp_appl_name
--              , iv_name         => cv_message_90000
--              , iv_token_name1  => cv_token_count
--              , iv_token_value1 => gn_target_cnt
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                  , iv_message  => lv_msg              --���b�Z�[�W
--                  , in_new_line => 0                   --���s
--                  );
--    -- =============================================================================
--    -- ���������o��
--    -- =============================================================================
--    -- *** ���^�[���R�[�h���G���[�̏ꍇ�A����������'0'���ɂ��� ***
--    IF ( lv_retcode = cv_status_error ) THEN
--      gn_normal_cnt := cn_0;
--    END IF;
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxccp_appl_name
--              , iv_name         => cv_message_90001
--              , iv_token_name1  => cv_token_count
--              , iv_token_value1 => gn_normal_cnt
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                  , iv_message  => lv_msg              --���b�Z�[�W
--                  , in_new_line => 0                   --���s
--                  );
--    -- =============================================================================
--    -- �G���[�����o��
--    -- =============================================================================
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application  => cv_xxccp_appl_name
--              , iv_name         => cv_message_90002
--              , iv_token_name1  => cv_token_count
--              , iv_token_value1 => gn_error_cnt
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                  , iv_message  => lv_msg              --���b�Z�[�W
--                  , in_new_line => 0                   --���s
--                  );
--    -- =============================================================================
--    -- �����I�����b�Z�[�W���o��
--    -- =============================================================================
--    IF ( lv_retcode = cv_status_normal ) THEN
--      lv_message_code := cv_message_90004;
--    ELSIF ( lv_retcode = cv_status_error ) THEN
--      lv_message_code := cv_message_90006;
--    END IF;
----
--    lv_msg := xxccp_common_pkg.get_msg(
--                iv_application => cv_xxccp_appl_name
--              , iv_name        => lv_message_code
--              );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
--                  , iv_message  => lv_msg              --���b�Z�[�W
--                  , in_new_line => 0                   --���s
--                  );
--    --�X�e�[�^�X�Z�b�g
--    retcode := lv_retcode;
--    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK
--    IF ( retcode = cv_status_error ) THEN
--      ROLLBACK;
--      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--    END IF;
--    --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK���s��
--    IF ( lv_retcode = cv_status_error ) THEN
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_errmsg         --���b�Z�[�W
--                    , in_new_line => 1                 --���s
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG      --�o�͋敪
--                    , iv_message  => lv_errbuf         --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ROLLBACK;
--    END IF;
--    --�G���[�����ł������̊m�������B
--    COMMIT;
--  EXCEPTION
--    -- *** ���ʊ֐���O�n���h�� ***
--    WHEN global_api_expt THEN
--      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--      --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK���s��
--      IF ( lv_retcode = cv_status_error ) THEN
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                      , iv_message  => lv_errmsg         --���b�Z�[�W
--                      , in_new_line => 1                 --���s
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      --�o�͋敪
--                      , iv_message  => lv_errbuf         --���b�Z�[�W
--                      , in_new_line => 0                 --���s
--                      );
--        ROLLBACK;
--      END IF;
--      --�G���[�����ł������̊m�������B
--      COMMIT;
--    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
--    WHEN global_api_others_expt THEN
--      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--      --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK���s��
--      IF ( lv_retcode = cv_status_error ) THEN
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                      , iv_message  => lv_errmsg         --���b�Z�[�W
--                      , in_new_line => 1                 --���s
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      --�o�͋敪
--                      , iv_message  => lv_errbuf         --���b�Z�[�W
--                      , in_new_line => 0                 --���s
--                      );
--        ROLLBACK;
--      END IF;
--      --�G���[�����ł������̊m�������B
--      COMMIT;
--    -- *** OTHERS��O�n���h�� ***
--    WHEN OTHERS THEN
--      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
--      retcode := cv_status_error;
--      ROLLBACK;
--      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
--      del_interface_at_error(
--        ov_errbuf   => lv_errbuf
--      , ov_retcode  => lv_retcode
--      , ov_errmsg   => lv_errmsg
--      , in_file_id  => ln_file_id
--      );
--      --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK���s��
--      IF ( lv_retcode = cv_status_error ) THEN
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                      , iv_message  => lv_errmsg         --���b�Z�[�W
--                      , in_new_line => 1                 --���s
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which    => FND_FILE.LOG      --�o�͋敪
--                      , iv_message  => lv_errbuf         --���b�Z�[�W
--                      , in_new_line => 0                 --���s
--                      );
--        ROLLBACK;
--      END IF;
--      --�G���[�����ł������̊m�������B
--      COMMIT;
--  END main;
--
  -- ===============================
  -- �O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(100)  := 'XXCOK022A01C';  -- �p�b�P�[�W��
--
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;   -- �ُ�:2
--
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER         := FND_GLOBAL.USER_ID;          -- CREATED_BY
--  cd_creation_date          CONSTANT DATE           := SYSDATE;                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER         := FND_GLOBAL.USER_ID;          -- LAST_UPDATED_BY
--  cd_last_update_date       CONSTANT DATE           := SYSDATE;                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER         := FND_GLOBAL.LOGIN_ID;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER         := FND_GLOBAL.CONC_REQUEST_ID;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER         := FND_GLOBAL.PROG_APPL_ID;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER         := FND_GLOBAL.CONC_PROGRAM_ID;  -- PROGRAM_ID
--  cd_program_update_date    CONSTANT DATE           := SYSDATE;                     -- PROGRAM_UPDATE_DATE  
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_sqlgl        CONSTANT VARCHAR2(10)   := 'SQLGL';
  cv_appl_name_xxccp        CONSTANT VARCHAR2(10)   := 'XXCCP';
  cv_appl_name_xxcok        CONSTANT VARCHAR2(10)   := 'XXCOK';
--
  --�v���t�@�C��
  cv_set_of_bks_id           CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';          -- ��v����ID
  cv_company_code            CONSTANT VARCHAR2(50)  := 'XXCOK1_AFF1_COMPANY_CODE';  -- ��ЃR�[�h
  cv_keep_period             CONSTANT VARCHAR2(50)  := 'XXCOK1_BUDGET_KEEP_PERIOD'; -- �̎�̋��\�Z�ێ�����
--
  -- �N�C�b�N�R�[�h
  cv_lookup_type_upload_file CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';    -- �t�@�C���A�b�v���[�h���
  cv_enabled_flag_y          CONSTANT VARCHAR2(50)  := 'Y';                         -- �L���t���O�F�L��
--
  -- ��v�J�����_�[�^��v���ԃX�e�[�^�X
  cv_adj_flag_no            CONSTANT gl_period_statuses.adjustment_period_flag%TYPE := 'N'; -- �������ԃt���O�F�������ԈȊO
  cv_period_status_open     CONSTANT gl_period_statuses.closing_status%TYPE         := 'O'; -- �X�e�[�^�X    �F�I�[�v��
--
  -- �A�b�v���[�h�t�@�C���F���ڃC���f�b�N�X
  cn_idx_budget_year        CONSTANT PLS_INTEGER    :=  1;  -- �\�Z�N�x
  cn_idx_base_code          CONSTANT PLS_INTEGER    :=  2;  -- ���_�R�[�h
  cn_idx_corp_code          CONSTANT PLS_INTEGER    :=  3;  -- ��ƃR�[�h
  cn_idx_sales_outlets_code CONSTANT PLS_INTEGER    :=  4;  -- �≮������R�[�h
  cn_idx_acct_code          CONSTANT PLS_INTEGER    :=  5;  -- ����ȖڃR�[�h
  cn_idx_sub_acct_code      CONSTANT PLS_INTEGER    :=  6;  -- �⏕�ȖڃR�[�h
  cn_idx_month_01           CONSTANT PLS_INTEGER    :=  7;  -- ���x_01
  cn_idx_amount_01          CONSTANT PLS_INTEGER    :=  8;  -- ���z_01
  cn_idx_month_02           CONSTANT PLS_INTEGER    :=  9;  -- ���x_02
  cn_idx_amount_02          CONSTANT PLS_INTEGER    := 10;  -- ���z_02
  cn_idx_month_03           CONSTANT PLS_INTEGER    := 11;  -- ���x_03
  cn_idx_amount_03          CONSTANT PLS_INTEGER    := 12;  -- ���z_03
  cn_idx_month_04           CONSTANT PLS_INTEGER    := 13;  -- ���x_04
  cn_idx_amount_04          CONSTANT PLS_INTEGER    := 14;  -- ���z_04
  cn_idx_month_05           CONSTANT PLS_INTEGER    := 15;  -- ���x_05
  cn_idx_amount_05          CONSTANT PLS_INTEGER    := 16;  -- ���z_05
  cn_idx_month_06           CONSTANT PLS_INTEGER    := 17;  -- ���x_06
  cn_idx_amount_06          CONSTANT PLS_INTEGER    := 18;  -- ���z_06
  cn_idx_month_07           CONSTANT PLS_INTEGER    := 19;  -- ���x_07
  cn_idx_amount_07          CONSTANT PLS_INTEGER    := 20;  -- ���z_07
  cn_idx_month_08           CONSTANT PLS_INTEGER    := 21;  -- ���x_08
  cn_idx_amount_08          CONSTANT PLS_INTEGER    := 22;  -- ���z_08
  cn_idx_month_09           CONSTANT PLS_INTEGER    := 23;  -- ���x_09
  cn_idx_amount_09          CONSTANT PLS_INTEGER    := 24;  -- ���z_09
  cn_idx_month_10           CONSTANT PLS_INTEGER    := 25;  -- ���x_10
  cn_idx_amount_10          CONSTANT PLS_INTEGER    := 26;  -- ���z_10
  cn_idx_month_11           CONSTANT PLS_INTEGER    := 27;  -- ���x_11
  cn_idx_amount_11          CONSTANT PLS_INTEGER    := 28;  -- ���z_11
  cn_idx_month_12           CONSTANT PLS_INTEGER    := 29;  -- ���x_12
  cn_idx_amount_12          CONSTANT PLS_INTEGER    := 30;  -- ���z_12
--
  -- �Ó����`�F�b�N�F�����i�o�C�g���j
  cn_len_budget_year        CONSTANT NUMBER         :=  4;  -- �\�Z�N�x
  cn_len_base_code          CONSTANT NUMBER         :=  4;  -- ���_�R�[�h
  cn_len_corp_code          CONSTANT NUMBER         :=  6;  -- ��ƃR�[�h
  cn_len_sales_outlets_code CONSTANT NUMBER         :=  9;  -- �≮������R�[�h
  cn_len_acct_code          CONSTANT NUMBER         :=  5;  -- ����ȖڃR�[�h
  cn_len_sub_acct_code      CONSTANT NUMBER         :=  5;  -- �⏕�ȖڃR�[�h
  cn_len_month              CONSTANT NUMBER         :=  2;  -- ���x
  cn_len_amount             CONSTANT NUMBER         := 12;  -- ���z
--
  -- ����
  cv_format_yyyymmdd        CONSTANT VARCHAR2(50)   := 'FXRRRR/MM/DD';
  cv_format_yyyymm          CONSTANT VARCHAR2(50)   := 'RRRRMM';
  cv_format_mm              CONSTANT VARCHAR2(50)   := 'MM';
--
  -- ���b�Z�[�W��`
  cv_output                 CONSTANT VARCHAR2(6)    := 'OUTPUT';            -- �w�b�_���O�o��
  cv_msg_part               CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)    := '.';
--
  cv_message_90000          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
  cv_message_90001          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
  cv_message_90003          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90003';  -- �X�L�b�v�����o��
  cv_message_90002          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
  cv_message_90004          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
  cv_message_90005          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
  cv_message_90006          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N���b�Z�[�W
--
  cv_message_00016          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00016';  -- �t�@�C��ID�o�͗p���b�Z�[�W
  cv_message_00017          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00017';  -- �t�H�[�}�b�g�p�^�[���o�͗p���b�Z�[�W
  cv_message_00022          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00022';  -- �Ɩ����t���b�Z�[�W
  cv_message_00106          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00106';  -- �t�@�C���A�b�v���[�h���̏o�͗p���b�Z�[�W
  cv_message_00006          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00006';  -- �t�@�C�����o�͗p���b�Z�[�W
--
  cv_err_msg_00028          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00028';  -- �Ɩ��������t�擾�G���[
  cv_err_msg_00003          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00003';  -- �v���t�@�C���擾�G���[
  cv_err_msg_00061          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00061';  -- IF�e�[�u�����b�N�擾�G���[
  cv_err_msg_00041          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00041';  -- BLOB�f�[�^�ϊ��G���[
  cv_err_msg_00039          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00039';  -- ��t�@�C���G���[���b�Z�[�W
  cv_err_msg_10417          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10417';  -- �\�Z�N�x����NULL�G���[
  cv_err_msg_10479          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10479';  -- �\�Z�N�x���p�����`�F�b�N�G���[
  cv_err_msg_10480          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10480';  -- �\�Z�N�x�����`�F�b�N�G���[
  cv_err_msg_10481          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10481';  -- ��v���ԃI�[�v���`�F�b�N�G���[
  cv_err_msg_10418          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10418';  -- ���_�R�[�h����NULL�G���[
  cv_err_msg_10135          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10135';  -- ���_�R�[�h���p�p�����`�F�b�N�G���[
  cv_err_msg_10126          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10126';  -- ���_�R�[�h�����`�F�b�N�G���[
  cv_err_msg_10419          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10419';  -- ��ƃR�[�h����NULL�G���[
  cv_err_msg_10136          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10136';  -- ��ƃR�[�h���p�p�����`�F�b�N�G���[
  cv_err_msg_10127          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10127';  -- ��ƃR�[�h�����`�F�b�N�G���[
  cv_err_msg_10420          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10420';  -- �≮������R�[�h����NULL�G���[
  cv_err_msg_10137          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10137';  -- �≮������R�[�h���p�p�����`�F�b�N�G���[
  cv_err_msg_10125          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10125';  -- �≮������R�[�h�����`�F�b�N�G���[
  cv_err_msg_10421          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10421';  -- ����ȖڃR�[�h����NULL�G���[
  cv_err_msg_10138          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10138';  -- ����ȖڃR�[�h���p�p�����`�F�b�N�G���[
  cv_err_msg_10128          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10128';  -- ����ȖڃR�[�h�����`�F�b�N�G���[
  cv_err_msg_10422          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10422';  -- �⏕�ȖڃR�[�h����NULL�G���[
  cv_err_msg_10139          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10139';  -- �⏕�ȖڃR�[�h���p�p�����`�F�b�N�G���[
  cv_err_msg_10129          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10129';  -- �⏕�ȖڃR�[�h�����`�F�b�N�G���[
  cv_err_msg_10423          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10423';  -- ���x(n�Ԗ�)�K�{�`�F�b�N�G���[
  cv_err_msg_10482          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10482';  -- ���x(n�Ԗ�)���p�����`�F�b�N�G���[
  cv_err_msg_10483          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10483';  -- ���x(n�Ԗ�)�����`�F�b�N�G���[
  cv_err_msg_10425          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10425';  -- ���x(n�Ԗ�)���t�`�F�b�N�G���[
  cv_err_msg_10424          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10424';  -- �\�Z���z(n�Ԗ�)�K�{�`�F�b�N�G���[
  cv_err_msg_10123          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10123';  -- �\�Z���z(n�Ԗ�)���p�����`�F�b�N�G���[
  cv_err_msg_10130          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10130';  -- �\�Z���z(n�Ԗ�)�����`�F�b�N�G���[
  cv_err_msg_10484          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10484';  -- �A�b�v���[�h���o�^�G���[
  cv_err_msg_10107          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10107';  -- �f�[�^���b�N�G���[(�̎�̋��\�Z�e�[�u��)
  cv_err_msg_10108          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10108';  -- �\�Z�N�x�d���f�[�^�폜�G���[
  cv_err_msg_10449          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10449';  -- �̎�̋��\�Z�o�^�G���[
  cv_err_msg_10111          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10111';  -- �ێ����ԊO�\�Z�폜�G���[
  cv_err_msg_00062          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00062';  -- �t�@�C���A�b�v���[�hIF�e�[�u���폜�G���[
--
  -- ���b�Z�[�W�g�[�N����`
  cv_token_file_id          CONSTANT VARCHAR2(50)   := 'FILE_ID';           -- �t�@�C��ID
  cv_token_format           CONSTANT VARCHAR2(50)   := 'FORMAT';            -- �t�H�[�}�b�g�p�^�[��
  cv_token_business_date    CONSTANT VARCHAR2(50)   := 'BUSINESS_DATE';     -- �Ɩ����t
  cv_token_profile          CONSTANT VARCHAR2(50)   := 'PROFILE';           -- �v���t�@�C����
  cv_token_upload_object    CONSTANT VARCHAR2(50)   := 'UPLOAD_OBJECT';     -- �t�@�C���A�b�v���[�h����
  cv_token_file_name        CONSTANT VARCHAR2(50)   := 'FILE_NAME';         -- �t�@�C������
  cv_token_row_num          CONSTANT VARCHAR2(50)   := 'ROW_NUM';           -- �s�ԍ�
  cv_token_budget_year      CONSTANT VARCHAR2(50)   := 'BUDGET_YEAR';       -- �\�Z�N�x
  cv_token_occurs           CONSTANT VARCHAR2(50)   := 'OCCURS';            -- �J��Ԃ����ڂ̃C���f�b�N�X
  cv_token_month            CONSTANT VARCHAR2(50)   := 'MONTH';             -- ���x
  cv_token_count            CONSTANT VARCHAR2(50)   := 'COUNT';             -- ��������
--
  -- ���n�A�g�X�e�[�^�X
  cv_dwh_if_status_yet      CONSTANT VARCHAR2(1)    := '0';                 -- 0:���A�g
--
  -- ���̑�
  cn_0                      CONSTANT NUMBER         := 0;
  cn_1                      CONSTANT NUMBER         := 1;
  cn_2                      CONSTANT NUMBER         := 2;
  cv_comma                  CONSTANT VARCHAR2(1)    := ',';
  cv_0                      CONSTANT VARCHAR2(1)    := '0';
-- 2010/08/24 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi ADD START
  cv_hyphen                 CONSTANT VARCHAR2(1)    := '-';
-- 2010/08/24 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi ADD END
--
  -- =============================================================================
  -- �O���[�o�����R�[�h�^
  -- =============================================================================
--
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  gn_target_cnt             PLS_INTEGER DEFAULT 0;  -- �Ώی���
  gn_normal_cnt             PLS_INTEGER DEFAULT 0;  -- ���팏��
  gn_warn_cnt               PLS_INTEGER DEFAULT 0;  -- �X�L�b�v����
  gn_error_cnt              PLS_INTEGER DEFAULT 0;  -- �G���[����
--
  gd_operation_date         DATE                                        DEFAULT NULL; -- �Ɩ��������t
  gn_set_of_books_id        NUMBER                                      DEFAULT NULL; -- ��v����ID
  gt_company_code           xxcok_tmp_022a01c_upload.company_code%TYPE  DEFAULT NULL; -- ��ЃR�[�h
  gn_keep_period            NUMBER                                      DEFAULT NULL; -- �̎�̋��\�Z�ێ�����
  gt_next_period_year       xxcok_bm_support_budget.budget_year%TYPE    DEFAULT NULL; -- ����v�N�x
  gn_keep_period_year       NUMBER                                      DEFAULT NULL; -- �̋��\�Z�ێ����ԁi�N�x�j
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
  global_process_expt       EXCEPTION;  -- ���������ʗ�O
  global_api_expt           EXCEPTION;  -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION;  -- ���ʊ֐�OTHERS��O
  global_lock_expt          EXCEPTION;  -- ���b�N��O
--
  -- �v���O�}
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : del_mrp_file_ul_interface
   * Description      : �t�@�C���A�b�v���[�hIF�̍폜(A-9)
   ***********************************************************************************/
  PROCEDURE del_mrp_file_ul_interface(
      ov_errbuf   OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode  OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg   OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_id  IN  VARCHAR2                          -- �t�@�C��ID
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'del_mrp_file_ul_interface';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    --===============================
    -- ���b�N�擾�p�J�[�\��
    --===============================
    CURSOR lock_xmfui_cur
    IS
      SELECT  xmfui.file_id AS file_id  -- �t�@�C��ID
      FROM    xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF�e�[�u��
      WHERE   xmfui.file_id =  TO_NUMBER( iv_file_id )
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- �t�@�C���A�b�v���[�hIF�̍폜
    --===============================================
    <<delete_loop>>
    FOR lock_xmfui_rec IN lock_xmfui_cur LOOP
      BEGIN
        DELETE
        FROM    xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF�e�[�u��
        WHERE   xmfui.file_id =  lock_xmfui_rec.file_id
        ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- OTHERS��O�n���h��
        ----------------------------------------------------------
        WHEN OTHERS THEN
            lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
            lb_retcode := xxcok_common_pkg.put_message_f(
                              in_which        => FND_FILE.LOG     -- �o�͋敪
                            , iv_message      => lv_out_msg       -- ���b�Z�[�W
                            , in_new_line     => cn_0             -- ���s
                          );
--
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_00062
                          , iv_token_name1  => cv_token_file_id
                          , iv_token_value1 => TO_CHAR( lock_xmfui_rec.file_id )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          RAISE global_process_expt;
      END;
    END LOOP delete_loop;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���b�N�擾��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00061
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END del_mrp_file_ul_interface;
--
  /**********************************************************************************
   * Procedure Name   : purge_bm_support_budget
   * Description      : �p�[�W����(A-8)
   ***********************************************************************************/
  PROCEDURE purge_bm_support_budget(
      ov_errbuf   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
    , ov_retcode  OUT VARCHAR2  -- ���^�[���E�R�[�h
    , ov_errmsg   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'purge_bm_support_budget';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    --===============================
    -- ���b�N�擾�p�J�[�\��
    --===============================
    CURSOR lock_xbsb_cur
    IS
      SELECT  xbsb.bm_support_budget_id AS bm_support_budget_id -- �̎�̋��\�ZID
      FROM    xxcok_bm_support_budget xbsb  -- �̎�̋��\�Z
      WHERE   TO_NUMBER( xbsb.budget_year ) <= gn_keep_period_year
      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT
    ;
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- �p�[�W����
    --===============================================
    <<purge_loop>>
    FOR lock_xbsb_rec IN lock_xbsb_cur LOOP
      BEGIN
        DELETE
        FROM    xxcok_bm_support_budget xbsb  -- �̎�̋��\�Z
        WHERE   xbsb.bm_support_budget_id =  lock_xbsb_rec.bm_support_budget_id
        ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- OTHERS��O�n���h��
        ----------------------------------------------------------
        WHEN OTHERS THEN
            lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
            lb_retcode := xxcok_common_pkg.put_message_f(
                              in_which        => FND_FILE.LOG     -- �o�͋敪
                            , iv_message      => lv_out_msg       -- ���b�Z�[�W
                            , in_new_line     => cn_0             -- ���s
                          );
--
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10111
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          RAISE global_process_expt;
      END;
    END LOOP purge_loop;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���b�N�擾��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10107
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END purge_bm_support_budget;
--
  /**********************************************************************************
   * Procedure Name   : ins_bm_support_budget
   * Description      : �̎�̋��\�Z���̓o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_bm_support_budget(
      ov_errbuf   OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode  OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg   OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_bm_support_budget';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    --===============================
    -- �̎�̋��\�Z�p�J�[�\��
    --===============================
    CURSOR  xt022a01c_cur
    IS
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_01    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_01      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_02    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_02      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_03    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_03      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_04    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_04      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_05    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_05      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_06    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_06      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_07    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_07      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_08    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_08      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_09    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_09      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_10    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_10      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_11    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_11      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
      UNION ALL
      SELECT    xt022a01c.row_num            AS row_num             -- �s�ԍ�
              , xt022a01c.company_code       AS company_code        -- ��ЃR�[�h
              , xt022a01c.budget_year        AS budget_year         -- �\�Z�N�x
              , xt022a01c.base_code          AS base_code           -- ���_�R�[�h
              , xt022a01c.corp_code          AS corp_code           -- ��ƃR�[�h
              , xt022a01c.sales_outlets_code AS sales_outlets_code  -- �≮������R�[�h
              , xt022a01c.acct_code          AS acct_code           -- ����ȖڃR�[�h
              , xt022a01c.sub_acct_code      AS sub_acct_code       -- �⏕�ȖڃR�[�h
              , xt022a01c.target_month_12    AS target_month        -- �Ώ۔N��
              , xt022a01c.budget_amt_12      AS budget_amt          -- �\�Z���z
      FROM      xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
    ;
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- �̎�̋��\�Z�̓o�^
    --===============================================
    <<insert_loop>>
    FOR xt022a01c_rec IN xt022a01c_cur LOOP
      BEGIN
        INSERT INTO xxcok_bm_support_budget(
            bm_support_budget_id    -- �̎�̋��\�ZID
          , company_code            -- ��ЃR�[�h
          , budget_year             -- �\�Z�N�x
          , base_code               -- ���_�R�[�h
          , corp_code               -- ��ƃR�[�h
          , sales_outlets_code      -- �≮������R�[�h
          , acct_code               -- ����ȖڃR�[�h
          , sub_acct_code           -- �⏕�ȖڃR�[�h
          , target_month            -- ���x(�Ώ۔N��)
          , budget_amt              -- �\�Z���z
          , info_interface_status   -- ���n�A�g�X�e�[�^�X
          , created_by              -- �쐬��
          , creation_date           -- �쐬��
          , last_updated_by         -- �ŏI�X�V��
          , last_update_date        -- �ŏI�X�V��
          , last_update_login       -- �ŏI�X�V���O�C��
          , request_id              -- �v��ID
          , program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , program_id              -- �v���O����ID
          , program_update_date     -- �v���O�����X�V��
        ) VALUES (
            xxcok_bm_support_budget_s01.NEXTVAL -- bm_support_budget_id
          , xt022a01c_rec.company_code          -- company_code
          , xt022a01c_rec.budget_year           -- budget_year
          , xt022a01c_rec.base_code             -- base_code
          , xt022a01c_rec.corp_code             -- corp_code
          , xt022a01c_rec.sales_outlets_code    -- sales_outlets_code
          , xt022a01c_rec.acct_code             -- acct_code
          , xt022a01c_rec.sub_acct_code         -- sub_acct_code
          , xt022a01c_rec.target_month          -- target_month
          , xt022a01c_rec.budget_amt            -- budget_amt
          , cv_dwh_if_status_yet                -- info_interface_status
          , cn_created_by                       -- created_by
          , SYSDATE                             -- creation_date
          , cn_last_updated_by                  -- last_updated_by
          , SYSDATE                             -- last_update_date
          , cn_last_update_login                -- last_update_login
          , cn_request_id                       -- request_id
          , cn_program_application_id           -- program_application_id
          , cn_program_id                       -- program_id
          , SYSDATE                             -- program_update_date
        );
--
      EXCEPTION
        ----------------------------------------------------------
        -- OTHERS��O�n���h��
        ----------------------------------------------------------
        WHEN OTHERS THEN
          lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
--
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10449
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          RAISE global_process_expt;
      END;
    END LOOP insert_loop;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END ins_bm_support_budget;
--
  /**********************************************************************************
   * Procedure Name   : del_duplicate_budget_year
   * Description      : �d���\�Z�N�x�f�[�^�̍폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_duplicate_budget_year(
      ov_errbuf   OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode  OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg   OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'del_duplicate_budget_year';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    --===============================
    -- ���b�N�擾�p�J�[�\��
    --===============================
    CURSOR  lock_duplicate_budget_year_cur
    IS
      SELECT  xbsb.bm_support_budget_id -- �̎�̋��\�ZID
      FROM    xxcok_bm_support_budget xbsb  -- �̎�̋��\�Z
      WHERE   EXISTS( SELECT  'X'
                      FROM    xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
                      WHERE   xt022a01c.budget_year   =  xbsb.budget_year
                        AND   ROWNUM = 1
              )
      FOR UPDATE OF xbsb.bm_support_budget_id NOWAIT
    ;
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- �d���\�Z�N�x�̃��b�N�擾
    --===============================================
    OPEN  lock_duplicate_budget_year_cur;
    CLOSE lock_duplicate_budget_year_cur;
--
    --===============================================
    -- �d���\�Z�N�x�̍폜
    --===============================================
    BEGIN
      DELETE
      FROM    xxcok_bm_support_budget xbsb  -- �̎�̋��\�Z
      WHERE   EXISTS( SELECT  'X'
                      FROM    xxcok_tmp_022a01c_upload  xt022a01c -- �̎�̋��\�Z�A�b�v���[�h���ꎞ�\
                      WHERE   xt022a01c.budget_year   =  xbsb.budget_year
                        AND   ROWNUM = 1
              )
      ;
--
    EXCEPTION
      ----------------------------------------------------------
      -- OTHERS��O�n���h��
      ----------------------------------------------------------
      WHEN OTHERS THEN
          lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.LOG     -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
--
        lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcok
                        , iv_name         => cv_err_msg_10108
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- �o�͋敪
                        , iv_message      => lv_out_msg       -- ���b�Z�[�W
                        , in_new_line     => cn_0             -- ���s
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                        , iv_message      => lv_out_msg       -- ���b�Z�[�W
                        , in_new_line     => cn_0             -- ���s
                      );
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���b�N�擾��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10107
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END del_duplicate_budget_year;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxcok_tmp_022a01c
   * Description      : �A�b�v���[�h���ꎞ�\�̓o�^(A-5)
   ***********************************************************************************/
  PROCEDURE ins_xxcok_tmp_022a01c(
      ov_errbuf         OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num        IN  PLS_INTEGER                       -- �s�ԍ�
    , it_xt022a01c_rec  IN  xxcok_tmp_022a01c_upload%ROWTYPE  -- �̎�̋��\�Z���
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'ins_xxcok_tmp_022a01c';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    INSERT INTO xxcok_tmp_022a01c_upload(
        row_num                 -- �s�ԍ�
      , company_code            -- ��ЃR�[�h
      , budget_year             -- �\�Z�N�x
      , base_code               -- ���_�R�[�h
      , corp_code               -- ��ƃR�[�h
      , sales_outlets_code      -- �≮������R�[�h
      , acct_code               -- ����ȖڃR�[�h
      , sub_acct_code           -- �⏕�ȖڃR�[�h
      , target_month_01         -- �Ώ۔N��_01
      , budget_amt_01           -- �\�Z���z_01
      , target_month_02         -- �Ώ۔N��_02
      , budget_amt_02           -- �\�Z���z_02
      , target_month_03         -- �Ώ۔N��_03
      , budget_amt_03           -- �\�Z���z_03
      , target_month_04         -- �Ώ۔N��_04
      , budget_amt_04           -- �\�Z���z_04
      , target_month_05         -- �Ώ۔N��_05
      , budget_amt_05           -- �\�Z���z_05
      , target_month_06         -- �Ώ۔N��_06
      , budget_amt_06           -- �\�Z���z_06
      , target_month_07         -- �Ώ۔N��_07
      , budget_amt_07           -- �\�Z���z_07
      , target_month_08         -- �Ώ۔N��_08
      , budget_amt_08           -- �\�Z���z_08
      , target_month_09         -- �Ώ۔N��_09
      , budget_amt_09           -- �\�Z���z_09
      , target_month_10         -- �Ώ۔N��_10
      , budget_amt_10           -- �\�Z���z_10
      , target_month_11         -- �Ώ۔N��_11
      , budget_amt_11           -- �\�Z���z_11
      , target_month_12         -- �Ώ۔N��_12
      , budget_amt_12           -- �\�Z���z_12
    ) VALUES (
        in_row_num                          -- row_num
      , gt_company_code                     -- company_code
      , it_xt022a01c_rec.budget_year        -- budget_year
      , it_xt022a01c_rec.base_code          -- base_code
      , it_xt022a01c_rec.corp_code          -- corp_code
      , it_xt022a01c_rec.sales_outlets_code -- sales_outlets_code
      , it_xt022a01c_rec.acct_code          -- acct_code
      , it_xt022a01c_rec.sub_acct_code      -- sub_acct_code
      , it_xt022a01c_rec.target_month_01    -- target_month_01
      , it_xt022a01c_rec.budget_amt_01      -- budget_amt_01
      , it_xt022a01c_rec.target_month_02    -- target_month_02
      , it_xt022a01c_rec.budget_amt_02      -- budget_amt_02
      , it_xt022a01c_rec.target_month_03    -- target_month_03
      , it_xt022a01c_rec.budget_amt_03      -- budget_amt_03
      , it_xt022a01c_rec.target_month_04    -- target_month_04
      , it_xt022a01c_rec.budget_amt_04      -- budget_amt_04
      , it_xt022a01c_rec.target_month_05    -- target_month_05
      , it_xt022a01c_rec.budget_amt_05      -- budget_amt_05
      , it_xt022a01c_rec.target_month_06    -- target_month_06
      , it_xt022a01c_rec.budget_amt_06      -- budget_amt_06
      , it_xt022a01c_rec.target_month_07    -- target_month_07
      , it_xt022a01c_rec.budget_amt_07      -- budget_amt_07
      , it_xt022a01c_rec.target_month_08    -- target_month_08
      , it_xt022a01c_rec.budget_amt_08      -- budget_amt_08
      , it_xt022a01c_rec.target_month_09    -- target_month_09
      , it_xt022a01c_rec.budget_amt_09      -- budget_amt_09
      , it_xt022a01c_rec.target_month_10    -- target_month_10
      , it_xt022a01c_rec.budget_amt_10      -- budget_amt_10
      , it_xt022a01c_rec.target_month_11    -- target_month_11
      , it_xt022a01c_rec.budget_amt_11      -- budget_amt_11
      , it_xt022a01c_rec.target_month_12    -- target_month_12
      , it_xt022a01c_rec.budget_amt_12      -- budget_amt_12
    )
    ;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
      ov_errbuf  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10484
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                      , iv_token_name2  => cv_token_budget_year
                      , iv_token_value2 => it_xt022a01c_rec.budget_year
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => ov_errbuf       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END ins_xxcok_tmp_022a01c;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_amount
   * Description      : �Ó����`�F�b�N�F�\�Z���z(A-4-8)
   ***********************************************************************************/
  PROCEDURE chk_data_amount(
      ov_errbuf   OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
    , ov_retcode  OUT VARCHAR2                                -- ���^�[���E�R�[�h
    , ov_errmsg   OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num  IN  PLS_INTEGER                             -- �s�ԍ�
    , in_occurs   IN  PLS_INTEGER                             -- �J��Ԃ����ڂ̃C���f�b�N�X
    , iv_amount   IN  VARCHAR2                                -- �\�Z���z
    , ot_amount   OUT xxcok_bm_support_budget.budget_amt%TYPE -- �\�Z���z
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_amount'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
    ot_amount   := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_amount IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10424
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2010/08/24 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR START
--    --===============================================
--    -- ���p�����`�F�b�N
--    --===============================================
--    lb_chk_number := xxccp_common_pkg.chk_number(
--                        iv_check_char => iv_amount
--                     );
    --===============================================
    -- �\�Z���z ���l�`�F�b�N�i�}�C�i�X���z�j
    --===============================================
    BEGIN
      --===============================================
      -- ���p���� �n�C�t���`�F�b�N
      --===============================================
      lb_chk_number := xxccp_common_pkg.chk_number(
                          iv_check_char => REPLACE( iv_amount, cv_hyphen, NULL )
                       );
      lb_chk_number := NVL( lb_chk_number, FALSE ); -- ������NULL�̏ꍇ�A�߂�l��NULL�̂���
      IF( lb_chk_number ) THEN
        --===============================================
        -- ���l�ϊ��`�F�b�N
        --===============================================
          ot_amount  := TO_NUMBER( iv_amount );
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- �o�͋敪
                        , iv_message      => lv_out_msg       -- ���b�Z�[�W
                        , in_new_line     => cn_0             -- ���s
                      );
--
        lb_chk_number := FALSE;
    END;
    ot_amount  := NULL;
-- 2010/08/24 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR END
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10123
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_amount ) > cn_len_amount ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10130
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_amount  := TO_NUMBER( iv_amount );
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_amount;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_month
   * Description      : �Ó����`�F�b�N�F�Ώ۔N��(A-4-7)
   ***********************************************************************************/
  PROCEDURE chk_data_month(
      ov_errbuf         OUT VARCHAR2                                  -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2                                  -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num        IN  PLS_INTEGER                               -- �s�ԍ�
    , in_occurs         IN  PLS_INTEGER                               -- �J��Ԃ����ڂ̃C���f�b�N�X
    , it_budget_year    IN  xxcok_bm_support_budget.budget_year%TYPE  -- �\�Z�N�x
    , iv_month          IN  VARCHAR2                                  -- ���x
    , ot_target_month   OUT xxcok_bm_support_budget.target_month%TYPE -- �Ώ۔N��
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_month'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf         := NULL;
    ov_retcode        := cv_status_normal;
    ov_errmsg         := NULL;
    ot_target_month   := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_month IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10423
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ���p�����`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_number(
                        iv_check_char => iv_month
                     );
--
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10482
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_month ) > cn_len_month ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10483
                      , iv_token_name1  => cv_token_occurs
                      , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                      , iv_token_name2  => cv_token_row_num
                      , iv_token_value2 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ��v�J�����_�[�`�F�b�N
    --===============================================
    IF( it_budget_year IS NULL ) THEN
      -- �\�Z�N�x��NULL�̏ꍇ�ɂ͌㑱�̃`�F�b�N�����Ȃ�
      RAISE global_process_expt;
    END IF;
--
    BEGIN
      SELECT  TO_CHAR( gp.start_date, cv_format_yyyymm )  AS target_month -- ��v���ԊJ�n���̔N��
      INTO  ot_target_month -- �Ώ۔N��
      FROM    gl_sets_of_books  gsob  -- ��v����}�X�^
            , gl_periods        gp    -- ��v�J�����_�[
      WHERE   gsob.set_of_books_id                    =  gn_set_of_books_id
        AND   gp.period_set_name                      =  gsob.period_set_name
        AND   gp.period_year                          =  TO_NUMBER( it_budget_year )
        AND   TO_CHAR( gp.start_date, cv_format_mm )  =  LPAD( iv_month, cn_len_month, cv_0 )
        AND   gp.adjustment_period_flag               =  cv_adj_flag_no
        AND   ROWNUM = 1
      ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- ��v�J�����_�[���o�^
        ----------------------------------------------------------
        WHEN NO_DATA_FOUND THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10425
                          , iv_token_name1  => cv_token_occurs
                          , iv_token_value1 => LPAD( TO_CHAR( in_occurs ), cn_2, cv_0 )
                          , iv_token_name2  => cv_token_row_num
                          , iv_token_value2 => TO_CHAR( in_row_num )
                          , iv_token_name3  => cv_token_budget_year
                          , iv_token_value3 => TO_CHAR( it_budget_year )
                          , iv_token_name4  => cv_token_month
                          , iv_token_value4 => LPAD( iv_month, cn_len_month, cv_0 )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          RAISE global_process_expt;
    END;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_month;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_sub_acct_code
   * Description      : �Ó����`�F�b�N�F�⏕�ȖڃR�[�h(A-4-6)
   ***********************************************************************************/
  PROCEDURE chk_data_sub_acct_code(
      ov_errbuf         OUT VARCHAR2                                    -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2                                    -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num        IN  PLS_INTEGER                                 -- �s�ԍ�
    , it_acct_code      IN  xxcok_bm_support_budget.acct_code%TYPE      -- ����ȖڃR�[�h
    , iv_sub_acct_code  IN  VARCHAR2                                    -- �⏕�ȖڃR�[�h
    , ot_sub_acct_code  OUT xxcok_bm_support_budget.sub_acct_code%TYPE  -- �⏕�ȖڃR�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_sub_acct_code'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf         := NULL;
    ov_retcode        := cv_status_normal;
    ov_errmsg         := NULL;
    ot_sub_acct_code  := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_sub_acct_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10422
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_sub_acct_code ) <> cn_len_sub_acct_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10129
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;

    --===============================================
    -- ���p�p�����i�L���j�`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_sub_acct_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10139
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_sub_acct_code  := iv_sub_acct_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_sub_acct_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_acct_code
   * Description      : �Ó����`�F�b�N�F����ȖڃR�[�h(A-4-5)
   ***********************************************************************************/
  PROCEDURE chk_data_acct_code(
      ov_errbuf     OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
    , ov_retcode    OUT VARCHAR2                                -- ���^�[���E�R�[�h
    , ov_errmsg     OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num    IN  PLS_INTEGER                             -- �s�ԍ�
    , iv_acct_code  IN  VARCHAR2                                -- ����ȖڃR�[�h
    , ot_acct_code  OUT xxcok_bm_support_budget.acct_code%TYPE  -- ����ȖڃR�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_acct_code'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf     := NULL;
    ov_retcode    := cv_status_normal;
    ov_errmsg     := NULL;
    ot_acct_code  := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_acct_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10421
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ���p�p�����i�L���j�`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_acct_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10138
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_acct_code ) <> cn_len_acct_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10128
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_acct_code  := iv_acct_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_acct_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_sales_outlets_code
   * Description      : �Ó����`�F�b�N�F�≮������R�[�h(A-4-4)
   ***********************************************************************************/
  PROCEDURE chk_data_sales_outlets_code(
      ov_errbuf             OUT VARCHAR2                                        -- �G���[�E���b�Z�[�W
    , ov_retcode            OUT VARCHAR2                                        -- ���^�[���E�R�[�h
    , ov_errmsg             OUT VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num            IN  PLS_INTEGER                                     -- �s�ԍ�
    , iv_sales_outlets_code IN  VARCHAR2                                        -- �≮������R�[�h
    , ot_sales_outlets_code OUT xxcok_bm_support_budget.sales_outlets_code%TYPE -- �≮������R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_sales_outlets_code';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf             := NULL;
    ov_retcode            := cv_status_normal;
    ov_errmsg             := NULL;
    ot_sales_outlets_code := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_sales_outlets_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10420
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ���p�p�����i�L���j�`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_sales_outlets_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10137
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_sales_outlets_code ) <> cn_len_sales_outlets_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10125
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_sales_outlets_code := iv_sales_outlets_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_sales_outlets_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_corp_code
   * Description      : �Ó����`�F�b�N�F��ƃR�[�h(A-4-3)
   ***********************************************************************************/
  PROCEDURE chk_data_corp_code(
      ov_errbuf     OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
    , ov_retcode    OUT VARCHAR2                                -- ���^�[���E�R�[�h
    , ov_errmsg     OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num    IN  PLS_INTEGER                             -- �s�ԍ�
    , iv_corp_code  IN  VARCHAR2                                -- ��ƃR�[�h
    , ot_corp_code  OUT xxcok_bm_support_budget.corp_code%TYPE  -- ��ƃR�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_corp_code'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf     := NULL;
    ov_retcode    := cv_status_normal;
    ov_errmsg     := NULL;
    ot_corp_code  := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_corp_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10419
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ���p�p�����i�L���j�`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_corp_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10136
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_corp_code ) <> cn_len_corp_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10127
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_corp_code  := iv_corp_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_corp_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_base_code
   * Description      : �Ó����`�F�b�N�F���_�R�[�h(A-4-2)
   ***********************************************************************************/
  PROCEDURE chk_data_base_code(
      ov_errbuf     OUT VARCHAR2                                -- �G���[�E���b�Z�[�W
    , ov_retcode    OUT VARCHAR2                                -- ���^�[���E�R�[�h
    , ov_errmsg     OUT VARCHAR2                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num    IN  PLS_INTEGER                             -- �s�ԍ�
    , iv_base_code  IN  VARCHAR2                                -- ���_�R�[�h
    , ot_base_code  OUT xxcok_bm_support_budget.base_code%TYPE  -- ���_�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_base_code'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf     := NULL;
    ov_retcode    := cv_status_normal;
    ov_errmsg     := NULL;
    ot_base_code  := NULL;
--
    --===============================================
    -- �K�{���̓`�F�b�N
    --===============================================
    IF( iv_base_code IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10418
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ���p�p�����i�L���j�`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_alphabet_number(
                        iv_check_char => iv_base_code
                     );
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10135
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_base_code ) <> cn_len_base_code ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10126
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ot_base_code  := iv_base_code;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_base_code;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_budget_year
   * Description      : �Ó����`�F�b�N�F�\�Z�N�x(A-4-1)
   ***********************************************************************************/
  PROCEDURE chk_data_budget_year(
      ov_errbuf       OUT VARCHAR2                                  -- �G���[�E���b�Z�[�W
    , ov_retcode      OUT VARCHAR2                                  -- ���^�[���E�R�[�h
    , ov_errmsg       OUT VARCHAR2                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num      IN  PLS_INTEGER                               -- �s�ԍ�
    , iv_budget_year  IN  VARCHAR2                                  -- �\�Z�N�x
    , ot_budget_year  OUT xxcok_bm_support_budget.budget_year%TYPE  -- �\�Z�N�x
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_budget_year'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lb_chk_number   BOOLEAN;                                  -- ���ʊ֐��߂�l
    lv_period_year  VARCHAR2(4)     DEFAULT NULL;             -- ��v�N�x
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf       := NULL;
    ov_retcode      := cv_status_normal;
    ov_errmsg       := NULL;
    ot_budget_year  := NULL;
--
    --===============================================
    -- �Ó����`�F�b�N
    --===============================================
    IF( iv_budget_year IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10417
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ���p�����`�F�b�N
    --===============================================
    lb_chk_number := xxccp_common_pkg.chk_number(
                        iv_check_char => iv_budget_year
                     );
--
    IF( lb_chk_number = FALSE ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10479
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    --===============================================
    -- �����`�F�b�N
    --===============================================
    IF( LENGTHB( iv_budget_year ) > cn_len_budget_year ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_10480
                      , iv_token_name1  => cv_token_row_num
                      , iv_token_value1 => TO_CHAR( in_row_num )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_retcode := cv_status_error;
    END IF;
--
    IF( ov_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- ��v���ԃX�e�[�^�X�`�F�b�N
    --===============================================
    IF( iv_budget_year = gt_next_period_year ) THEN
      -- �Ɩ����t�̗��N�x�̏ꍇ�ɂ̓G���[�Ƃ��Ȃ�
      ot_budget_year := iv_budget_year;
--
    ELSE
      BEGIN
        SELECT  TO_CHAR( gps.period_year )  AS period_year  -- ��v�N�x
        INTO  ot_budget_year  -- ��v�N�x
        FROM    fnd_application     fa  -- ���ʃA�v���P�[�V����
              , gl_period_statuses  gps -- ��v���ԃX�e�[�^�X
        WHERE   fa.application_short_name   =  cv_appl_name_sqlgl
          AND   gps.application_id          =  fa.application_id
          AND   gps.set_of_books_id         =  gn_set_of_books_id
          AND   gps.adjustment_period_flag  =  cv_adj_flag_no
          AND   gps.closing_status          =  cv_period_status_open
          AND   gps.period_year             =  TO_NUMBER( iv_budget_year )
          AND   ROWNUM = 1
        ;
--
      EXCEPTION
        ----------------------------------------------------------
        -- ��v���Ԗ��I�[�v��
        ----------------------------------------------------------
        WHEN NO_DATA_FOUND THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcok
                          , iv_name         => cv_err_msg_10481
                          , iv_token_name1  => cv_token_budget_year
                          , iv_token_value1 => iv_budget_year
                          , iv_token_name2  => cv_token_row_num
                          , iv_token_value2 => TO_CHAR( in_row_num )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
                          , in_new_line     => cn_0             -- ���s
                        );
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data_budget_year;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �Ó����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
      ov_errbuf     OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode    OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg     OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    , in_row_num    IN  PLS_INTEGER                       -- �s�ԍ�
    , it_csv_data   IN  xxcok_common_pkg.g_split_csv_tbl  -- CSV�����f�[�^
    , ot_budget_rec OUT xxcok_tmp_022a01c_upload%ROWTYPE  -- �̎�̋��\�Z�f�[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    ln_occurs       PLS_INTEGER;                              -- �J��Ԃ����ڂ̃C���f�b�N�X
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    ln_occurs   := 0;
--
    --===============================================
    -- �Ó����`�F�b�N�F�\�Z�N�x
    --===============================================
    chk_data_budget_year(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , iv_budget_year        => CASE WHEN it_csv_data.COUNT >= cn_idx_budget_year
                                   THEN TRIM( it_csv_data( cn_idx_budget_year ) )
                                   ELSE NULL
                                 END                                              -- �\�Z�N�x
      , ot_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���_�R�[�h
    --===============================================
    chk_data_base_code(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , iv_base_code          => CASE WHEN it_csv_data.COUNT >= cn_idx_base_code
                                   THEN TRIM( it_csv_data( cn_idx_base_code ) )
                                   ELSE NULL
                                 END                                              -- ���_�R�[�h
      , ot_base_code          => ot_budget_rec.base_code                          -- ���_�R�[�h
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F��ƃR�[�h
    --===============================================
    chk_data_corp_code(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , iv_corp_code          => CASE WHEN it_csv_data.COUNT >= cn_idx_corp_code
                                   THEN TRIM( it_csv_data( cn_idx_corp_code ) )
                                   ELSE NULL
                                 END                                              -- ��ƃR�[�h
      , ot_corp_code          => ot_budget_rec.corp_code                          -- ��ƃR�[�h
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F�≮������R�[�h
    --===============================================
    chk_data_sales_outlets_code(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , iv_sales_outlets_code => CASE WHEN it_csv_data.COUNT >= cn_idx_sales_outlets_code
                                   THEN TRIM( it_csv_data( cn_idx_sales_outlets_code ) )
                                   ELSE NULL
                                 END                                              -- �≮������R�[�h
      , ot_sales_outlets_code => ot_budget_rec.sales_outlets_code                 -- �≮������R�[�h
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F����ȖڃR�[�h
    --===============================================
    chk_data_acct_code(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , iv_acct_code          => CASE WHEN it_csv_data.COUNT >= cn_idx_acct_code
                                   THEN TRIM( it_csv_data( cn_idx_acct_code ) )
                                   ELSE NULL
                                 END                                              -- ����ȖڃR�[�h
      , ot_acct_code          => ot_budget_rec.acct_code                          -- ����ȖڃR�[�h
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F�⏕�ȖڃR�[�h
    --===============================================
    chk_data_sub_acct_code(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , it_acct_code          => ot_budget_rec.acct_code                          -- ����ȖڃR�[�h
      , iv_sub_acct_code      => CASE WHEN it_csv_data.COUNT >= cn_idx_sub_acct_code
                                   THEN TRIM( it_csv_data( cn_idx_sub_acct_code ) )
                                   ELSE NULL
                                 END                                              -- �⏕�ȖڃR�[�h
      , ot_sub_acct_code      => ot_budget_rec.sub_acct_code                      -- �⏕�ȖڃR�[�h
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_01�A���z_01
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_01
                                   THEN TRIM( it_csv_data( cn_idx_month_01 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_01                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_01
                                   THEN TRIM( it_csv_data( cn_idx_amount_01 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_01                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_02�A���z_02
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_02
                                   THEN TRIM( it_csv_data( cn_idx_month_02 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_02                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_02
                                   THEN TRIM( it_csv_data( cn_idx_amount_02 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_02                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_03�A���z_03
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_03
                                   THEN TRIM( it_csv_data( cn_idx_month_03 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_03                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_03
                                   THEN TRIM( it_csv_data( cn_idx_amount_03 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_03                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_04�A���z_04
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_04
                                   THEN TRIM( it_csv_data( cn_idx_month_04 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_04                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_04
                                   THEN TRIM( it_csv_data( cn_idx_amount_04 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_04                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_05�A���z_05
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_05
                                   THEN TRIM( it_csv_data( cn_idx_month_05 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_05                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_05
                                   THEN TRIM( it_csv_data( cn_idx_amount_05 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_05                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_06�A���z_06
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_06
                                   THEN TRIM( it_csv_data( cn_idx_month_06 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_06                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_06
                                   THEN TRIM( it_csv_data( cn_idx_amount_06 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_06                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_07�A���z_07
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_07
                                   THEN TRIM( it_csv_data( cn_idx_month_07 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_07                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_07
                                   THEN TRIM( it_csv_data( cn_idx_amount_07 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_07                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_08�A���z_08
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_08
                                   THEN TRIM( it_csv_data( cn_idx_month_08 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_08                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_08
                                   THEN TRIM( it_csv_data( cn_idx_amount_08 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_08                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_09�A���z_09
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_09
                                   THEN TRIM( it_csv_data( cn_idx_month_09 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_09                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_09
                                   THEN TRIM( it_csv_data( cn_idx_amount_09 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_09                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_10�A���z_10
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_10
                                   THEN TRIM( it_csv_data( cn_idx_month_10 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_10                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_10
                                   THEN TRIM( it_csv_data( cn_idx_amount_10 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_10                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_11�A���z_11
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_11
                                   THEN TRIM( it_csv_data( cn_idx_month_11 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_11                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_11
                                   THEN TRIM( it_csv_data( cn_idx_amount_11 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_11                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    --===============================================
    -- �Ó����`�F�b�N�F���x_12�A���z_12
    --===============================================
    ln_occurs := ln_occurs + 1;
    chk_data_month(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , it_budget_year        => ot_budget_rec.budget_year                        -- �\�Z�N�x
      , iv_month              => CASE WHEN it_csv_data.COUNT >= cn_idx_month_12
                                   THEN TRIM( it_csv_data( cn_idx_month_12 ) )
                                   ELSE NULL
                                 END                                              -- ���x
      , ot_target_month       => ot_budget_rec.target_month_12                    -- �Ώ۔N��
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
    chk_data_amount(
        ov_errbuf             => lv_errbuf                                        -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode                                       -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_row_num            => in_row_num                                       -- �s�ԍ�
      , in_occurs             => ln_occurs                                        -- �J��Ԃ����ڂ̃C���f�b�N�X
      , iv_amount             => CASE WHEN it_csv_data.COUNT >= cn_idx_amount_12
                                   THEN TRIM( it_csv_data( cn_idx_amount_12 ) )
                                   ELSE NULL
                                 END                                              -- �\�Z���z
      , ot_amount             => ot_budget_rec.budget_amt_12                      -- �\�Z���z
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      ov_retcode  := lv_retcode;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : import_upload_file_data
   * Description      : �A�b�v���[�h�t�@�C���f�[�^�̎捞(A-3)
   ***********************************************************************************/
  PROCEDURE import_upload_file_data(
      ov_errbuf         OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_id        IN  VARCHAR2                          -- �t�@�C��ID
    , i_file_data_tab   IN  xxccp_common_pkg2.g_file_data_tbl -- �t�@�C���f�[�^�i�[�̈�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'import_upload_file_data';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lt_csv_data     xxcok_common_pkg.g_split_csv_tbl;         -- CSV�����f�[�^
    ln_csv_col_cnt  PLS_INTEGER;                              -- CSV���ڐ�
    lt_budget_rec   xxcok_tmp_022a01c_upload%ROWTYPE;         -- �̎�̋��\�Z�f�[�^
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--    lv_out_msg := '    �G���[�s   �G���[�f�[�^(�擪����1,000�o�C�g�܂�)';
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- �o�͋敪
--                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                    , in_new_line     => cn_0             -- ���s
--                  );
--    lv_out_msg := '============= ===============================================================';
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- �o�͋敪
--                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                    , in_new_line     => cn_0             -- ���s
--                  );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
--
    -- �A�b�v���[�h�t�@�C���f�[�^�̎捞
    <<import_loop>>
    FOR ln_row_num IN 2 .. i_file_data_tab.COUNT LOOP
      gn_target_cnt   := gn_target_cnt + 1; -- �Ώی������C���N�������g
--
      lt_csv_data.delete;
      ln_csv_col_cnt  := 0;
      lt_budget_rec   := NULL;
--
      -- CSV�f�[�^�̕���
      xxcok_common_pkg.split_csv_data_p(
          ov_errbuf         => lv_errbuf                      -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode                     -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
        , iv_csv_data       => i_file_data_tab( ln_row_num )  -- CSV������
        , on_csv_col_cnt    => ln_csv_col_cnt                 -- CSV���ڐ�
        , ov_split_csv_tab  => lt_csv_data                    -- CSV�����f�[�^
      );
      IF( lv_retcode <> cv_status_normal ) THEN
        lv_out_msg := TO_CHAR( ln_row_num, '99,990' ) || ' �s��   ' || lv_errmsg;
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- �o�͋敪
                        , iv_message      => lv_out_msg       -- ���b�Z�[�W
                        , in_new_line     => cn_0             -- ���s
                      );
      END IF;
--
      IF( REPLACE( i_file_data_tab( ln_row_num ), cv_comma, NULL ) IS NULL ) THEN
        -- ��s�i�J���}�̂݁j�̏ꍇ�ɂ͖���
        gn_warn_cnt := gn_warn_cnt + 1; -- �X�L�b�v�������C���N�������g
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--        lv_out_msg := TO_CHAR( ln_row_num, '99,990' ) || ' �s��   ' || SUBSTR( i_file_data_tab( ln_row_num ), 1, 1000 );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                          in_which        => FND_FILE.LOG     -- �o�͋敪
--                        , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                        , in_new_line     => cn_0             -- ���s
--                      );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
--
      ELSE
        --===============================================
        -- A-4�D�Ó����`�F�b�N
        --===============================================
        chk_data(
            ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W
          , ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h
          , ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
          , in_row_num    => ln_row_num     -- �s�ԍ�
          , it_csv_data   => lt_csv_data    -- CSV�����f�[�^
          , ot_budget_rec => lt_budget_rec  -- �̎�̋��\�Z�f�[�^
        );
        IF( lv_retcode <> cv_status_normal ) THEN
          gn_error_cnt  := gn_error_cnt + 1; -- �G���[�������C���N�������g
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--          lv_out_msg := TO_CHAR( ln_row_num, '99,990' ) || ' �s��   ' || SUBSTR( i_file_data_tab( ln_row_num ), 1, 1000 );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                            in_which        => FND_FILE.LOG     -- �o�͋敪
--                          , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                          , in_new_line     => cn_0             -- ���s
--                        );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
        END IF;
--
        --===============================================
        -- A-5�D�̎�̋��\�Z�A�b�v���[�h���ꎞ�\�ւ̓o�^
        --===============================================
        IF( gn_error_cnt = 0 ) THEN
          ins_xxcok_tmp_022a01c(
              ov_errbuf         => lv_errbuf      -- �G���[�E���b�Z�[�W
            , ov_retcode        => lv_retcode     -- ���^�[���E�R�[�h
            , ov_errmsg         => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
            , in_row_num        => ln_row_num     -- �s�ԍ�
            , it_xt022a01c_rec  => lt_budget_rec  -- �̎�̋��\�Z�f�[�^
          );
          IF( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          gn_normal_cnt := gn_normal_cnt + 1; -- ���팏�����C���N�������g
        END IF;
      END IF;
    END LOOP import_loop;
--
    IF( gn_target_cnt = gn_warn_cnt ) THEN
      -- �S���X�L�b�v�̏ꍇ�ɂ͋�t�@�C���G���[�̃��b�Z�[�W���o��
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00039
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
      RAISE global_process_expt;
--
    ELSIF( gn_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
--
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi REPAIR START
--    ELSIF( gn_error_cnt = 0 ) THEN
--      lv_out_msg := '               �G���[�͂���܂���B';
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- �o�͋敪
--                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                      , in_new_line     => cn_0             -- ���s
--                    );
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- �o�͋敪
--                    , iv_message      => NULL             -- ���b�Z�[�W
--                    , in_new_line     => cn_1             -- ���s
--                  );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi REPAIR END
    END IF;
--
    --===============================================
    -- A-6�D�d���\�Z�N�x�̍폜
    --===============================================
    del_duplicate_budget_year(
        ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W
      , ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h
      , ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-7�D�̎�̋��\�Z�̓o�^
    --===============================================
    ins_bm_support_budget(
        ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W
      , ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h
      , ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-8�D�p�[�W����
    --===============================================
    purge_bm_support_budget(
        ov_errbuf     => lv_errbuf      -- �G���[�E���b�Z�[�W
      , ov_retcode    => lv_retcode     -- ���^�[���E�R�[�h
      , ov_errmsg     => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END import_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_file_data
   * Description      : �A�b�v���[�h�t�@�C���f�[�^�̎擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_file_data(
      ov_errbuf         OUT VARCHAR2                          -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2                          -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_id        IN  VARCHAR2                          -- �t�@�C��ID
    , iv_format_pattern IN  VARCHAR2                          -- �t�H�[�}�b�g�p�^�[��
    , o_file_data_tab   OUT xxccp_common_pkg2.g_file_data_tbl -- �t�@�C���f�[�^�i�[�̈�
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'get_upload_file_data'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lt_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE  DEFAULT NULL; --�t�@�C����
--
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- �A�b�v���[�h�t�@�C���f�[�^
    CURSOR xmfui_cur
    IS
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR START
--      SELECT  xmfui.file_name   AS file_name      -- �t�@�C����
--      FROM    xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF�e�[�u��
--      WHERE   xmfui.file_id     =  TO_NUMBER( iv_file_id )
--      FOR UPDATE OF xmfui.file_id NOWAIT
--    ;
      SELECT  xmfui.file_name   AS file_name      -- �t�@�C����
            , flvv.meaning      AS upload_object  -- �t�@�C���A�b�v���[�h����
      FROM    xxccp_mrp_file_ul_interface xmfui -- �t�@�C���A�b�v���[�hIF�e�[�u��
            , fnd_lookup_values_vl        flvv  -- �N�C�b�N�R�[�h
      WHERE   xmfui.file_id     =  TO_NUMBER( iv_file_id )
        AND   flvv.lookup_type  =  cv_lookup_type_upload_file
        AND   flvv.lookup_code  =  xmfui.file_content_type
        AND   flvv.enabled_flag =  cv_enabled_flag_y
        AND   gd_operation_date BETWEEN TRUNC( NVL( start_date_active, gd_operation_date ) )
                                    AND TRUNC( NVL( end_date_active  , gd_operation_date ) )
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR END
    xmfui_rec xmfui_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    blob_expt EXCEPTION;  --BLOB�f�[�^�ϊ��G���[��O
    file_expt EXCEPTION;  --��t�@�C���G���[��O
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- �t�@�C���A�b�v���[�h���̎擾
    --===============================================
    OPEN  xmfui_cur;
    FETCH xmfui_cur INTO xmfui_rec;
    CLOSE xmfui_cur;
--
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi ADD START
    --===============================================
    -- �t�@�C���A�b�v���[�h���̂̃��b�Z�[�W�o��
    --===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00106 
                    , iv_token_name1  => cv_token_upload_object
                    , iv_token_value1 => xmfui_rec.upload_object
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_0             -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_0             -- ���s
                  );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi ADD END
--
    --===============================================
    -- �A�b�v���[�h�t�@�C�����̃��b�Z�[�W�o��
    --===============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00006
                    , iv_token_name1  => cv_token_file_name
                    , iv_token_value1 => xmfui_rec.file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_1             -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_1             -- ���s
                  );
--
    --===============================================
    -- BLOB�f�[�^�ϊ�
    --===============================================
    xxccp_common_pkg2.blob_to_varchar2(
        ov_errbuf     => lv_errbuf
      , ov_retcode    => lv_retcode
      , ov_errmsg     => lv_errmsg
      , in_file_id    => TO_NUMBER( iv_file_id )
      , ov_file_data  => o_file_data_tab
    );
    -- ���^�[���R�[�h��0(����)�ȊO�̏ꍇ
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
    -- ������1���ȉ��̏ꍇ
    IF( o_file_data_tab.COUNT <= cn_1 ) THEN
      RAISE file_expt;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���b�N��O�n���h��
    ----------------------------------------------------------
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00061
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- BLOB�f�[�^�ϊ��G���[��O�n���h��
    ----------------------------------------------------------
    WHEN blob_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => lv_errmsg        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00041
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- ��t�@�C���G���[��O�n���h��
    ----------------------------------------------------------
    WHEN file_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00039
                      , iv_token_name1  => cv_token_file_id
                      , iv_token_value1 => iv_file_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
      IF( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
  END get_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf         OUT VARCHAR2  -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2  -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_id        IN  VARCHAR2  -- �t�@�C��ID
    , iv_format_pattern IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    lv_profile_name fnd_profile_options.profile_option_name%TYPE  DEFAULT NULL; -- �v���t�@�C���ޔ�
--
    -- ===============================
    -- ���[�J����O
    -- ===============================
    operation_date_expt EXCEPTION;  -- �Ɩ��������t�擾�G���[��O
    get_profile_expt    EXCEPTION;  -- �v���t�@�C���擾�G���[��O
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- �R���J�����g�v���O�������͍��ڂ̃��b�Z�[�W�o��
    --===============================================
    -- ���͍���.�t�@�C��ID
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00016
                    , iv_token_name1  => cv_token_file_id
                    , iv_token_value1 => iv_file_id
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_0             -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_0             -- ���s
                  );
--
    -- ���͍���.�t�H�[�}�b�g�p�^�[��
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00017
                    , iv_token_name1  => cv_token_format
                    , iv_token_value1 => iv_format_pattern
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_1             -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT  -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_1             -- ���s
                  );
--
    --==============================================================
    --�Ɩ��������t���擾
    --==============================================================
    gd_operation_date := xxccp_common_pkg2.get_process_date;
--
    IF( gd_operation_date IS NULL ) THEN
      RAISE operation_date_expt;
    END IF;
--
    -- �Ɩ����t
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_message_00022
                    , iv_token_name1  => cv_token_business_date
                    , iv_token_value1 => TO_CHAR( gd_operation_date, cv_format_yyyymmdd )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.LOG     -- �o�͋敪
                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
                    , in_new_line     => cn_0             -- ���s
                  );
--
    --===============================================
    -- �v���t�@�C���̎擾
    --===============================================
    BEGIN
      -- ��v����ID
      lv_profile_name    := cv_set_of_bks_id;
      gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_bks_id ) );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--      lv_out_msg := '�v���t�@�C����  �F  '           || cv_set_of_bks_id              || ' �A'
--                 || '�v���t�@�C���I�v�V�����l  �F  ' || TO_CHAR( gn_set_of_books_id );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- �o�͋敪
--                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                      , in_new_line     => cn_0             -- ���s
--                    );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
      IF( gn_set_of_books_id IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
--
      -- ��ЃR�[�h
      lv_profile_name := cv_company_code;
      gt_company_code := FND_PROFILE.VALUE( cv_company_code );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--      lv_out_msg := '�v���t�@�C����  �F  '           || cv_company_code || ' �A'
--                 || '�v���t�@�C���I�v�V�����l  �F  ' || gt_company_code;
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- �o�͋敪
--                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                      , in_new_line     => cn_0             -- ���s
--                    );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
      IF( gt_company_code IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
--
      -- �̎�̋��\�Z�ێ�����
      lv_profile_name := cv_keep_period;
      gn_keep_period  := TO_NUMBER( FND_PROFILE.VALUE( cv_keep_period ) );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--      lv_out_msg := '�v���t�@�C����  �F  '           || cv_keep_period            || ' �A'
--                 || '�v���t�@�C���I�v�V�����l  �F  ' || TO_CHAR( gn_keep_period );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                        in_which        => FND_FILE.LOG     -- �o�͋敪
--                      , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                      , in_new_line     => cn_0             -- ���s
--                    );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
      IF( gn_keep_period IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
--
    EXCEPTION
      ----------------------------------------------------------
      -- OTHERS��O�n���h��
      -- (get_profile_expt�Ƃ��Ă̓n���h�����O���Ȃ�)
      ----------------------------------------------------------
      WHEN OTHERS THEN
        lv_out_msg := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.LOG     -- �o�͋敪
                        , iv_message      => ov_errbuf        -- ���b�Z�[�W
                        , in_new_line     => cn_0             -- ���s
                      );
--
        lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcok
                        , iv_name         => cv_err_msg_00003
                        , iv_token_name1  => cv_token_profile
                        , iv_token_value1 => lv_profile_name
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which        => FND_FILE.OUTPUT -- �o�͋敪
                        , iv_message      => lv_out_msg      -- ���b�Z�[�W
                        , in_new_line     => cn_0            -- ���s
                      );
--
      RAISE global_process_expt;
    END;
--
    --===============================================
    -- ���\�Z�N�x�̎擾
    --===============================================
    SELECT  TO_CHAR( gp.period_year + cn_1 )  AS next_period_year -- ���\�Z�N�x
          , gp.period_year - gn_keep_period   AS keep_period_year -- �̋��\�Z�ێ����ԁi�N�x�j
    INTO  gt_next_period_year -- ���\�Z�N�x
        , gn_keep_period_year -- �̋��\�Z�ێ����ԁi�N�x�j
    FROM    gl_sets_of_books  gsob  -- ��v����}�X�^
          , gl_periods        gp    -- ��v�J�����_
    WHERE   gsob.set_of_books_id      =  gn_set_of_books_id
      AND   gp.period_set_name        =  gsob.period_set_name
      AND   gp.adjustment_period_flag =  cv_adj_flag_no
      AND   gd_operation_date         BETWEEN gp.start_date
                                          AND gp.end_date
      AND   ROWNUM = 1
    ;
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD START
--    lv_out_msg := '���\�Z�N�x  �F  ' || gt_next_period_year;
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- �o�͋敪
--                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                    , in_new_line     => cn_0             -- ���s
--                  );
--    lv_out_msg := '�̎�̋��\�Z�p�[�W�Ώ�  �F  ' || TO_CHAR( gn_keep_period_year ) || ' �N�x�ȑO';
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which        => FND_FILE.LOG     -- �o�͋敪
--                    , iv_message      => lv_out_msg       -- ���b�Z�[�W
--                    , in_new_line     => cn_1             -- ���s
--                  );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332][DEBUG] SCS S.Arizumi ADD END
--
  EXCEPTION
    ----------------------------------------------------------
    -- �Ɩ��������t�擾�G���[��O�n���h��
    ----------------------------------------------------------
    WHEN operation_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcok
                      , iv_name         => cv_err_msg_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.OUTPUT -- �o�͋敪
                      , iv_message      => lv_out_msg      -- ���b�Z�[�W
                      , in_new_line     => cn_0            -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf         OUT VARCHAR2  -- �G���[�E���b�Z�[�W
    , ov_retcode        OUT VARCHAR2  -- ���^�[���E�R�[�h
    , ov_errmsg         OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_file_id        IN  VARCHAR2  -- �t�@�C��ID
    , iv_format_pattern IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
    l_file_data_tab xxccp_common_pkg2.g_file_data_tbl;        -- �t�@�C���f�[�^
  BEGIN
    --===============================================
    -- ������
    --===============================================
    ov_errbuf   := NULL;
    ov_retcode  := cv_status_normal;
    ov_errmsg   := NULL;
--
    --===============================================
    -- A-1�D��������
    --===============================================
    init(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
      , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_file_id        => iv_file_id         -- �t�@�C��ID
      , iv_format_pattern => iv_format_pattern  -- �t�H�[�}�b�g�p�^�[��
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-2�D�A�b�v���[�h�t�@�C���f�[�^�̎擾
    --===============================================
    get_upload_file_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
      , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_file_id        => iv_file_id         -- �t�@�C��ID
      , iv_format_pattern => iv_format_pattern  -- �t�H�[�}�b�g�p�^�[��
      , o_file_data_tab   => l_file_data_tab    -- �t�@�C���f�[�^�i�[�̈�
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- A-3�D�̎�̋��\�Z�̎捞
    --===============================================
    import_upload_file_data(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
      , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_file_id        => iv_file_id         -- �t�@�C��ID
      , i_file_data_tab   => l_file_data_tab    -- �t�@�C���f�[�^�i�[�̈�
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  --
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => ov_errbuf        -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
      errbuf            OUT VARCHAR2  -- �G���[�E���b�Z�[�W
    , retcode           OUT VARCHAR2  -- ���^�[���E�R�[�h
    , iv_file_id        IN  VARCHAR2  -- �t�@�C��ID
    , iv_format_pattern IN  VARCHAR2  -- �t�H�[�}�b�g�p�^�[��
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
--
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)     DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;             -- ���b�Z�[�W
    lb_retcode      BOOLEAN         DEFAULT TRUE;             -- ���b�Z�[�W�߂�l
--
  BEGIN
    --===============================================
    -- ������
    --===============================================
    errbuf  := NULL;              -- �G���[�E���b�Z�[�W
    retcode := cv_status_normal;  -- ���^�[���E�R�[�h
--
    --===============================================
    -- �R���J�����g�w�b�_�o��
    --===============================================
    xxccp_common_pkg.put_log_header(
        iv_which    => cv_output
      , ov_retcode  => lv_retcode
      , ov_errbuf   => lv_errbuf
      , ov_errmsg   => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi DELETE START
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which      => FND_FILE.OUTPUT -- �o�͋敪
--                    , iv_message    => NULL            -- ���b�Z�[�W
--                    , in_new_line   => cn_1            -- ���s
--                  );
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi DELETE END
--
    --===============================================
    -- �T�u���C������
    --===============================================
    submain(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
      , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_file_id        => iv_file_id         -- �t�@�C��ID
      , iv_format_pattern => iv_format_pattern  -- �t�H�[�}�b�g
    );
    -- �X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF( lv_retcode = cv_status_error ) THEN
      -- �X�e�[�^�X�Z�b�g
      retcode := cv_status_error;
      ROLLBACK;
    END IF;
--
    --===============================================
    -- A-9�D�t�@�C���A�b�v���[�hIF�̍폜
    --===============================================
    del_mrp_file_ul_interface(
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
      , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_file_id        => iv_file_id         -- �t�@�C��ID
    );
    IF( lv_retcode = cv_status_error ) THEN
      -- �X�e�[�^�X�Z�b�g
      retcode := cv_status_error;
    END IF;
--
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR START
--    IF( retcode = cv_status_error ) THEN
--      -- �G���[�����������ݒ�
--      gn_normal_cnt := cn_0;  -- ���팏��
----
--      -- �X�e�[�^�X�Z�b�g
--      retcode := cv_status_error;
--    END IF;
----
--    lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which      => FND_FILE.OUTPUT -- �o�͋敪
--                    , iv_message    => NULL            -- ���b�Z�[�W
--                    , in_new_line   => cn_1            -- ���s
--                  );
    IF( retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      , iv_message    => NULL            -- ���b�Z�[�W
                      , in_new_line   => cn_1            -- ���s
                    );
--
      -- �G���[�����������ݒ�
      gn_normal_cnt := cn_0;  -- ���팏��
      IF( gn_error_cnt = cn_0 ) THEN
        gn_error_cnt := cn_1; -- �G���[����
      END IF;
--
      -- �X�e�[�^�X�Z�b�g
      retcode := cv_status_error;
    END IF;
-- 2010/08/04 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR END
--
    --===============================================
    -- A-10.�I������
    --===============================================
    -- �Ώی������b�Z�[�W�o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90000
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_0            -- ���s
                  );
--
    -- �����������b�Z�[�W�o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90001
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_0            -- ���s
                  );
--
    -- �G���[�������b�Z�[�W�o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90002
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_0            -- ���s
                  );
--
    -- �X�L�b�v�������b�Z�[�W�o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => cv_message_90003
                    , iv_token_name1  => cv_token_count
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_0            -- ���s
                  );
--
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message    => NULL            -- ���b�Z�[�W
                    , in_new_line   => cn_1            -- ���s
                  );
--
    -- �I�����b�Z�[�W�o��
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxccp
                    , iv_name         => CASE retcode
                                           WHEN cv_status_normal THEN cv_message_90004
                                           WHEN cv_status_warn   THEN cv_message_90005
                                           ELSE                       cv_message_90006
                                         END
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which        => FND_FILE.OUTPUT -- �o�͋敪
                    , iv_message      => lv_out_msg      -- ���b�Z�[�W
                    , in_new_line     => cn_0            -- ���s
                  );
--
    -- �K���t�@�C���A�b�v���[�hIF���폜���邽�߁A�����I�ɃR�~�b�g
    COMMIT;
--
  EXCEPTION
    ----------------------------------------------------------
    -- ���������ʗ�O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
      --===============================================
      -- A-9�D�t�@�C���A�b�v���[�hIF�̍폜
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        , iv_file_id        => iv_file_id         -- �t�@�C��ID
      );
      COMMIT;
--
    ----------------------------------------------------------
    -- ���ʊ֐���O�n���h��
    ----------------------------------------------------------
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
      --===============================================
      -- A-9�D�t�@�C���A�b�v���[�hIF�̍폜
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        , iv_file_id        => iv_file_id         -- �t�@�C��ID
      );
      COMMIT;
--
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => errbuf           -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ROLLBACK;
--
      --===============================================
      -- A-9�D�t�@�C���A�b�v���[�hIF�̍폜
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        , iv_file_id        => iv_file_id         -- �t�@�C��ID
      );
      COMMIT;
--
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
--
      lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which        => FND_FILE.LOG     -- �o�͋敪
                      , iv_message      => errbuf           -- ���b�Z�[�W
                      , in_new_line     => cn_0             -- ���s
                    );
      ROLLBACK;
--
      --===============================================
      -- A-9�D�t�@�C���A�b�v���[�hIF�̍폜
      --===============================================
      del_mrp_file_ul_interface(
          ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W
        , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h
        , ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        , iv_file_id        => iv_file_id         -- �t�@�C��ID
      );
      COMMIT;
  END  main;
-- 2010/08/02 Ver.2.0 [E_�{�ғ�_03332] SCS S.Arizumi REPAIR END
END XXCOK022A01C;
/
