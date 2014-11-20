CREATE OR REPLACE PACKAGE BODY XXCOK008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A04C(body)
 * Description      : ����U�֊����̓o�^
 * MD.050           : ����U�֊����̓o�^ MD050_COK_008_A04
 * Version          : 1.3
 *
 * Program List
 * -------------------------------- ---------------------------------------------------------
 *  Name                            Description
 * -------------------------------- ---------------------------------------------------------
 *  del_interface_at_error          �G���[��IF�f�[�^�폜�����ǉ�
 *  del_file_upload_interface_tbl   �t�@�C���A�b�v���[�hI/F�e�[�u�����R�[�h�폜(A-13)
 *  upd_selling_trns_rate_info      ����U�֊������e�[�u���X�V(�u�����t���O�v�u����U�֊����v�X�V)(A-12)
 *  ins_selling_trns_rate_info      ����U�֊������e�[�u���}��(A-11)
 *  upd_invalid_flag                ����U�֊������e�[�u���X�V(�u�����t���O�v��'����'��)(A-10)
 *  get_selling_trns_rate_info_a9   ����U�֊������e�[�u�����o(�u�o�^�E�����敪�v='1'(����))(A-9)
 *  get_selling_trns_rate_info_a8   ����U�֊������e�[�u�����o(�u�o�^�E�����敪�v='0'(�o�^))(A-8)
 *  get_tmp_tbl                     ����U�֊����o�^�ꎞ�\�ʃf�[�^���o(A-7)
 *  get_tmp_tbl_union_data          ����U�֊����o�^�ꎞ�\�W�v�f�[�^���o(A-6)
 *  upd_tmp_tbl_error_flag          ����U�֊����o�^�ꎞ�\�L���t���O�X�V(A-5)
 *  chk_data                        �f�[�^�Ó����`�F�b�N(A-4)
 *  get_tmp_selling_trns_rate       ����U�֊����o�^�ꎞ�\�f�[�^���o(A-3)
 *  get_file_upload_interface_date  �t�@�C���̃A�b�v���[�hI/F�f�[�^�擾(A-2)
 *  init                            ��������(A-1)
 *  submain                         ���C�������v���V�[�W��
 *  main                            �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2008/10/28     1.0   S.Sasaki         �V�K�쐬
 * 2009/02/06     1.1   S.Sasaki         [��QCOK_019]�G���[��IF�f�[�^�폜�����ǉ�
 * 2009/02/09     1.2   S.Sasaki         [��QCOK_021]����U�֊��̒l���u0�v�̏ꍇ�̑Ή�(�u�o�^�v�̏ꍇ)
 * 2009/02/10     1.3   S.Sasaki         [��QCOK_026]�K�{�`�F�b�N�����ǉ�
 *
 *****************************************************************************************/
  -- =========================
  -- �O���[�o���萔
  -- =========================
  --�p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(30)  := 'XXCOK008A04C';
  --�A�v���P�[�V�����Z�k��
  cv_xxcok_appl_name        CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;   --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;     --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;    --�ُ�:2
  --���b�Z�[�W����
  cv_message_00060          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00060'; --�f�[�^�폜�G���[���b�Z�[�W
  cv_message_10022          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10022'; --���b�N�G���[(����U�֊������e�[�u��)
  cv_message_10029          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10029'; --�f�[�^�X�V�G���[(����U�֊������e�[�u��)
  cv_message_10028          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10028'; --�f�[�^�ǉ��G���[���b�Z�[�W
  cv_message_10024          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10024'; --�X�e�[�^�X����x�����b�Z�[�W
  cv_message_10025          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10025'; --�������Ώۃ��R�[�h���݂Ȃ��x�����b�Z�[�W
  cv_message_10026          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10026'; --����U�֊���100���ȊO�x�����b�Z�[�W
  cv_message_10027          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10027'; --�f�[�^�X�V�G���[(����U�֊����o�^�ꎞ�\)
  cv_message_10352          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10352'; --���b�N�G���[(����U�֊����o�^�ꎞ�\)
  cv_message_10014          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10014'; --�o�^�E�����敪�Ó���NG�x�����b�Z�[�W
  cv_message_10015          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10015'; --����U�֌����_�R�[�h�Ȃ��x�����b�Z�[�W
  cv_message_10016          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10016'; --����U�֌��ڋq�R�[�h�Ȃ��x�����b�Z�[�W
  cv_message_10017          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10017'; --����U�֐�ڋq�R�[�h�Ȃ��x�����b�Z�[�W
  cv_message_10018          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10018'; --�����_�R�[�h�A���ڋq�R�[�h�R�t���m�f
  cv_message_10019          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10019'; --����U�֊��������m�f�x�����b�Z�[�W
  cv_message_10020          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10020'; --����U�֊������l�m�f�x�����b�Z�[�W
  cv_message_10021          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10021'; --����U�֌ڋq���Ȃ��x�����b�Z�[�W
  cv_message_00006          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00006'; --�t�@�C�������b�Z�[�W�o��
  cv_message_00061          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00061'; --���b�N�G���[:�t�@�C���A�b�v���[�hIF�e�[�u��
  cv_message_00039          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00039'; --��t�@�C���G���[���b�Z�[�W
  cv_message_00041          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00041'; --BLOB�f�[�^�ϊ��G���[���b�Z�[�W
  cv_message_00016          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00016'; --�t�@�C��ID���b�Z�[�W
  cv_message_00017          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00017'; --�t�H�[�}�b�g�p�^�[�����b�Z�[�W
  cv_message_00046          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00046'; --�ڋq��񕡐��擾�G���[
  cv_message_00047          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00047'; --���㋒�_��񕡐��擾�G���[
  cv_message_00028          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00028'; --�Ɩ����t�擾�G���[
  cv_message_10450          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10450'; --����U�֊������l�m�f�x��(�o�^)���b�Z�[�W
  cv_message_10451          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10451'; --�K�{���ږ��ݒ�G���[���b�Z�[�W
  cv_message_90000          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W
  cv_message_90001          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90001'; --�����������b�Z�[�W
  cv_message_90002          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W
  cv_message_90004          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90004'; --����I�����b�Z�[�W
  cv_message_90005          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90005'; --�x���I�����b�Z�[�W
  cv_message_90006          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90006'; --�G���[�I���S���[���o�b�N���b�Z�[�W
  --�g�[�N��
  cv_token_file_id          CONSTANT VARCHAR2(10)  := 'FILE_ID';           --�g�[�N����(FILE_ID)
  cv_token_file_name        CONSTANT VARCHAR2(10)  := 'FILE_NAME';         --�g�[�N����(FILE_NAME)
  cv_token_from_base        CONSTANT VARCHAR2(15)  := 'FROM_LOCATION';     --�g�[�N����(FROM_LOCATION)
  cv_token_from_cust        CONSTANT VARCHAR2(15)  := 'FROM_CUSTOMER';     --�g�[�N����(FROM_CUSTOMER)
  cv_token_to_cust          CONSTANT VARCHAR2(15)  := 'TO_CUSTOMER';       --�g�[�N����(TO_CUSTOMER)
  cv_token_rate             CONSTANT VARCHAR2(5)   := 'RATE';              --�g�[�N����(RATE)
  cv_token_kubun            CONSTANT VARCHAR2(15)  := 'KUBUN_VALUE';       --�g�[�N����(KUBUN_VALUE)
  cv_token_format           CONSTANT VARCHAR2(10)  := 'FORMAT';            --�g�[�N����(FORMAT)
  cv_token_count            CONSTANT VARCHAR2(5)   := 'COUNT';             --�g�[�N����(COUNT)
  cv_token_cust_code        CONSTANT VARCHAR2(10)  := 'COST_CODE';         --�g�[�N����(CUST_CODE)
  cv_token_sales_loc        CONSTANT VARCHAR2(10)  := 'SALES_LOC';         --�g�[�N����(SALES_LOC)
  --������
  cv_0                      CONSTANT VARCHAR2(1)   := '0';       --������:0
  cv_1                      CONSTANT VARCHAR2(1)   := '1';       --������:1
  cv_12                     CONSTANT VARCHAR2(2)   := '12';      --�ڋq�敪(��l�ڋq�ȊO)
  cv_40                     CONSTANT VARCHAR2(2)   := '40';      --'�ڋq'(���~�ڋq�łȂ�)
  --���l
  cn_0                      CONSTANT NUMBER        := 0;         --���l�F0
  cn_1                      CONSTANT NUMBER        := 1;         --���l�F1
  cn_100                    CONSTANT NUMBER        := 100;       --���l�F100
  --�t�H�[�}�b�g
  cv_number_format          CONSTANT VARCHAR2(5)   := '999.9';   --����U�֊����t�H�[�}�b�g
  cv_date_format            CONSTANT VARCHAR2(2)   := 'MM';      --�V�X�e�����t�t�H�[�}�b�g
  --WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;           --CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;           --LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;   --PROGRAM_ID
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';                        --�R����
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';                          --�s���I�h
  -- =============================================================================
  -- �O���[�o���ϐ�
  -- =============================================================================
  gn_target_cnt   NUMBER        DEFAULT 0;      --�Ώی���
  gn_normal_cnt   NUMBER        DEFAULT 0;      --��������
  gn_error_cnt    NUMBER        DEFAULT 0;      --�G���[����
  gn_file_id      NUMBER        DEFAULT NULL;   --�t�@�C��ID(���l�^)
  gv_file_id      VARCHAR2(100) DEFAULT NULL;   --�t�@�C��ID(�����^)
  gd_process_date DATE;                         --�Ɩ��������t
  -- =============================================================================
  -- �O���[�o����O
  -- =============================================================================
  -- *** ���b�N�G���[�n���h�� ***
  global_lock_fail          EXCEPTION;
  -- *** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  -- *** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  -- *** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);            --���b�N�G���[
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);   --���ʊ֐�OTHERS�G���[
--
  /**********************************************************************************
   * Procedure Name   : del_interface_at_error
   * Description      : �G���[��IF�f�[�^�폜(A-14)
   ***********************************************************************************/
  PROCEDURE del_interface_at_error(
    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)     --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(50) := 'del_interface_at_error';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --�G���[���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�G���[���b�Z�[�W
    lv_msg     VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lb_retcode BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hIF�e�[�u���̃��b�N�擾
    -- =============================================================================
    CURSOR xmfui_cur
    IS
      SELECT 'X'
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  xmfui_cur;
    CLOSE xmfui_cur;
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hIF�\�̍폜����
    -- =============================================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id;
    EXCEPTION
      -- *** �폜�����Ɏ��s ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_00060
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => gv_file_id
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_interface_at_error;
--
  /***************************************************************************
   * Procedure Name   : del_file_upload_interface_tbl
   * Description      : �t�@�C���A�b�v���[�hI/F�e�[�u�����R�[�h�폜(A-13)
   ***************************************************************************/
  PROCEDURE del_file_upload_interface_tbl(
    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)     --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'del_file_upload_interface_tbl';  --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hI/F�e�[�u���̑Ώۃ��R�[�h���폜
    -- =============================================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE  xmf.file_id = in_file_id;
    EXCEPTION
      -- *** �폜�Ɏ��s ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_00060
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => gv_file_id
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_file_upload_interface_tbl;
--
  /***********************************************************************************************
   * Procedure Name   : upd_selling_trns_rate_info
   * Description      : ����U�֊������e�[�u���X�V(�u�����t���O�v�u����U�֊����v�X�V)(A-12)
   ***********************************************************************************************/
  PROCEDURE upd_selling_trns_rate_info(
    ov_errbuf                     OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                    OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                     OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_selling_from_base_code     IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code     IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_selling_to_cust_code       IN  VARCHAR2    --����U�֐�ڋq�R�[�h
  , in_selling_trns_rate          IN  NUMBER      --����U�֊���
  , iv_invalid_flag               IN  VARCHAR2    --�����t���O
  , in_selling_trns_rate_info_id  IN  NUMBER)     --����U�֊������ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'upd_selling_trns_rate_info';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- ����U�֊������e�[�u���̃��b�N�擾
    -- =============================================================================
    CURSOR selling_rate_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxcok_selling_rate_info xstri
      WHERE  xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id
      FOR UPDATE OF xstri.selling_trns_rate_info_id NOWAIT;
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  selling_rate_cur;
    CLOSE selling_rate_cur;
    -- =============================================================================
    -- 1.A-8�Œ��o�������R�[�h�́u�����t���O�v��'0'(�L��)�̏ꍇ
    -- =============================================================================
    BEGIN
      IF ( iv_invalid_flag = cv_0 ) THEN
        UPDATE  xxcok_selling_rate_info xstri
        SET     xstri.selling_trns_rate      = in_selling_trns_rate
              , xstri.last_updated_by        = cn_last_updated_by
              , xstri.last_update_date       = SYSDATE
              , xstri.last_update_login      = cn_last_update_login
              , xstri.request_id             = cn_request_id
              , xstri.program_application_id = cn_program_application_id
              , xstri.program_id             = cn_program_id
              , xstri.program_update_date    = SYSDATE
        WHERE   xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id;
      -- =============================================================================
      -- 2.A-8�Œ��o�������R�[�h�́u�����t���O�v��'1'(����)�̏ꍇ
      -- =============================================================================
      ELSIF ( iv_invalid_flag = cv_1 ) THEN
        UPDATE  xxcok_selling_rate_info xstri
        SET     xstri.selling_trns_rate      = in_selling_trns_rate
              , xstri.invalid_flag           = cv_0
              , xstri.last_updated_by        = cn_last_updated_by
              , xstri.last_update_date       = SYSDATE
              , xstri.last_update_login      = cn_last_update_login
              , xstri.request_id             = cn_request_id
              , xstri.program_application_id = cn_program_application_id
              , xstri.program_id             = cn_program_id
              , xstri.program_update_date    = SYSDATE
        WHERE   xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id;
      END IF;
      -- *** ���������J�E���g ***
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** �X�V�����Ɏ��s�����ꍇ ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10029
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10022
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_retcode := cv_status_warn;
      -- *** �G���[�����J�E���g ***
      gn_error_cnt := gn_error_cnt + 1;
      -- *** A-6�Őݒ肵���Z�[�u�|�C���g�֑J�� ***
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_selling_trns_rate_info;
--
  /******************************************************************************************
   * Procedure Name   : ins_selling_trns_rate_info
   * Description      : ����U�֊������e�[�u���}��(A-11)
   ****************************************************************************************/
  PROCEDURE ins_selling_trns_rate_info(
    ov_errbuf                 OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                 OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_selling_from_base_code IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_selling_to_cust_code   IN  VARCHAR2    --����U�֐�ڋq�R�[�h
  , in_selling_trns_rate      IN  NUMBER)     --����U�֊���
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'ins_selling_trns_rate_info';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                     VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_registed_by             VARCHAR2(5)    DEFAULT NULL;   --�o�^�S����
    ln_selling_trns_rate_info  NUMBER         DEFAULT 0;      --����U�֊������ID
    lb_retcode                 BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ����U�֊������ID�̎擾
    -- =============================================================================
    SELECT xxcok_selling_rate_info_s01.NEXTVAL AS xxcok_selling_rate_info_s01
    INTO   ln_selling_trns_rate_info
    FROM   DUAL;
    -- =============================================================================
    -- �o�^�S���҂̎擾(�]�ƈ��R�[�h)
    -- =============================================================================
    lv_registed_by := xxcok_common_pkg.get_emp_code_f(
                        in_user_id => cn_created_by
                      );
    -- =============================================================================
    -- A-7�Œ��o�����f�[�^�𔄏�U�֊������e�[�u���֑}��
    -- =============================================================================
    BEGIN
      INSERT INTO xxcok_selling_rate_info(
        selling_trns_rate_info_id   --����U�֊������ID
      , selling_from_base_code      --����U�֌����_�R�[�h
      , selling_from_cust_code      --����U�֌��ڋq�R�[�h
      , selling_to_cust_code        --����U�֐�ڋq�R�[�h
      , selling_trns_rate           --����U�֊���
      , invalid_flag                --�����t���O
      , registed_by                 --�o�^�S����
      , created_by                  --�쐬��
      , creation_date               --�쐬��
      , last_updated_by             --�ŏI�X�V��
      , last_update_date            --�ŏI�X�V��
      , last_update_login           --�ŏI�X�V���O�C��
      , request_id                  --�v��ID
      , program_application_id      --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                  --�R���J�����g�E�v���O����ID
      , program_update_date         --�v���O�����X�V��
      ) VALUES (
        ln_selling_trns_rate_info   --selling_trns_rate_info_id
      , iv_selling_from_base_code   --selling_from_base_code
      , iv_selling_from_cust_code   --selling_from_cust_code
      , iv_selling_to_cust_code     --selling_to_cust_code
      , in_selling_trns_rate        --selling_trns_rate
      , cv_0                        --invalid_flag
      , lv_registed_by              --registed_by
      , cn_created_by               --created_by
      , SYSDATE                     --creation_date
      , cn_last_updated_by          --last_updated_by
      , SYSDATE                     --last_update_date
      , cn_last_update_login        --last_update_login
      , cn_request_id               --request_id
      , cn_program_application_id   --program_application_id
      , cn_program_id               --program_id
      , SYSDATE                     --program_update_date
      );
      -- *** ���������J�E���g ***
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** �ǉ��Ɏ��s ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10028
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_selling_trns_rate_info;
--
  /******************************************************************************************
   * Procedure Name   : upd_invalid_flag
   * Description      : ����U�֊������e�[�u���X�V(�u�����t���O�v��'����'��)(A-10)
   ****************************************************************************************/
  PROCEDURE upd_invalid_flag(
    ov_errbuf                    OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                   OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                    OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_selling_from_base_code    IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code    IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_selling_to_cust_code      IN  VARCHAR2    --����U�֐�ڋq�R�[�h
  , in_selling_trns_rate         IN  NUMBER      --����U�֊���
  , in_selling_trns_rate_info_id IN  NUMBER)     --����U�֊������ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(20)  := 'upd_invalid_flag';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- ����U�֊������e�[�u���̃��b�N�擾
    -- =============================================================================
    CURSOR selling_rate_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxcok_selling_rate_info xstri
      WHERE  xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id
      FOR UPDATE OF xstri.selling_trns_rate_info_id NOWAIT;
--
  BEGIN
    OPEN  selling_rate_cur;
    CLOSE selling_rate_cur;
    -- =============================================================================
    -- �u�����t���O�v��'1'(����)�ɍX�V
    -- =============================================================================
    BEGIN
      UPDATE  xxcok_selling_rate_info
      SET     invalid_flag              = cv_1
            , last_updated_by           = cn_last_updated_by
            , last_update_date          = SYSDATE
            , last_update_login         = cn_last_update_login
            , request_id                = cn_request_id
            , program_application_id    = cn_program_application_id
            , program_id                = cn_program_id
            , program_update_date       = SYSDATE
      WHERE   selling_trns_rate_info_id = in_selling_trns_rate_info_id;
      -- *** ���������J�E���g ***
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** �X�V�����Ɏ��s�����ꍇ ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10029
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10022
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_retcode := cv_status_warn;
      -- *** �G���[�����J�E���g ***
      gn_error_cnt := gn_error_cnt + 1;
      -- *** A-6�Őݒ肵���Z�[�u�|�C���g�֑J�� ***
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_invalid_flag;
--
  /******************************************************************************************
   * Procedure Name   : get_selling_trns_rate_info_a9
   * Description      : ����U�֊������e�[�u�����o(�u�o�^�E�����敪�v'1'(����))(A-9)
   ****************************************************************************************/
  PROCEDURE get_selling_trns_rate_info_a9(
    ov_errbuf                 OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                 OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_valid_invalid_type     IN  VARCHAR2    --�o�^������敪
  , iv_selling_from_base_code IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_selling_to_cust_code   IN  VARCHAR2    --����U�֐�ڋq�R�[�h
  , in_selling_trns_rate      IN  NUMBER)     --����U�֊���
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'get_selling_trns_rate_info_a9';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                     VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode                    VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                     VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                        VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_selling_from_base_code     VARCHAR2(4)    DEFAULT NULL;   --����U�֌����_�R�[�h
    lv_selling_from_cust_code     VARCHAR2(9)    DEFAULT NULL;   --����U�֌��ڋq�R�[�h
    lv_selling_to_cust_code       VARCHAR2(9)    DEFAULT NULL;   --����U�֐�ڋq�R�[�h
    lv_invalid_flag               VARCHAR2(1)    DEFAULT NULL;   --�����t���O
    ln_selling_trns_rate_info_id  NUMBER         DEFAULT NULL;   --����U�֊������ID
    lb_retcode                    BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ����U�֊������e�[�u�����o
    -- =============================================================================
    BEGIN
      SELECT  xsri.selling_from_base_code    AS selling_from_base_code
            , xsri.selling_from_cust_code    AS selling_from_cust_code
            , xsri.selling_to_cust_code      AS selling_to_cust_code
            , xsri.invalid_flag              AS invalid_flag
            , xsri.selling_trns_rate_info_id AS selling_trns_rate_info_id
      INTO    lv_selling_from_base_code
            , lv_selling_from_cust_code
            , lv_selling_to_cust_code
            , lv_invalid_flag
            , ln_selling_trns_rate_info_id
      FROM    xxcok_selling_rate_info xsri
      WHERE   xsri.selling_from_base_code = iv_selling_from_base_code
      AND     xsri.selling_from_cust_code = iv_selling_from_cust_code
      AND     xsri.selling_to_cust_code   = iv_selling_to_cust_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- =============================================================================
    -- 1.�f�[�^�����o�ł��A���u�����t���O�v��'0'�i�L���j�̏ꍇ�AA-10�֑J��
    -- =============================================================================
    IF (    ( ln_selling_trns_rate_info_id IS NOT NULL )
        AND ( lv_invalid_flag = cv_0 )
        ) THEN
      upd_invalid_flag(
        ov_errbuf                    => lv_errbuf
      , ov_retcode                   => lv_retcode
      , ov_errmsg                    => lv_errmsg
      , iv_selling_from_base_code    => iv_selling_from_base_code
      , iv_selling_from_cust_code    => iv_selling_from_cust_code
      , iv_selling_to_cust_code      => iv_selling_to_cust_code
      , in_selling_trns_rate         => in_selling_trns_rate
      , in_selling_trns_rate_info_id => ln_selling_trns_rate_info_id
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    -- ===================================================================================
    -- 2.�f�[�^�����o�ł��A���u�����t���O�v��'1'�i�����j�̏ꍇ�A�x�����b�Z�[�W���o��
    -- ===================================================================================
    ELSIF (    ( ln_selling_trns_rate_info_id IS NOT NULL )
           AND ( lv_invalid_flag = cv_1 )
          ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10024
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                   in_which    => FND_FILE.OUTPUT     --�o�͋敪
                 , iv_message  => lv_msg              --���b�Z�[�W
                 , in_new_line => 0                   --���s
                 );
      ov_retcode := cv_status_warn;
--
      gn_error_cnt := gn_error_cnt + 1;
      -- ===================================================================================
      -- A-6�Őݒ肵���Z�[�u�|�C���g�֑J��
      -- ===================================================================================
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    -- ======================================================
    -- 3.�f�[�^�𒊏o�ł��Ȃ������ꍇ�A�x�����b�Z�[�W�o��
    -- ======================================================
    ELSIF ( ln_selling_trns_rate_info_id IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10025
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_retcode := cv_status_warn;
--
      gn_error_cnt := gn_error_cnt + 1;
      -- ===================================================================================
      -- A-6�Őݒ肵���Z�[�u�|�C���g�֑J��
      -- ===================================================================================
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_selling_trns_rate_info_a9;
--
  /*****************************************************************************************
   * Procedure Name   : get_selling_trns_rate_info_a8
   * Description      : ����U�֊������e�[�u�����o(�u�o�^�E�����敪�v'0'(�o�^))(A-8)
   ****************************************************************************************/
  PROCEDURE get_selling_trns_rate_info_a8(
    ov_errbuf                 OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                 OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_selling_from_base_code IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_selling_to_cust_code   IN  VARCHAR2    --����U�֐�ڋq�R�[�h
  , in_selling_trns_rate      IN  NUMBER)     --����U�֊���
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name     CONSTANT VARCHAR2(30) := 'get_selling_trns_rate_info_a8';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_selling_from_base_code    VARCHAR2(4)    DEFAULT NULL;   --����U�֌����_�R�[�h
    lv_selling_from_cust_code    VARCHAR2(9)    DEFAULT NULL;   --����U�֌��ڋq�R�[�h
    lv_selling_to_cust_code      VARCHAR2(9)    DEFAULT NULL;   --����U�֐�ڋq�R�[�h
    lv_invalid_flag              VARCHAR2(1)    DEFAULT NULL;   --�����t���O
    ln_selling_trns_rate_info_id NUMBER         DEFAULT NULL;   --����U�֊������ID
    lb_retcode                   BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ����U�֊������e�[�u�����o
    -- =============================================================================
    BEGIN
      SELECT  xsri.selling_from_base_code    AS selling_from_base_code
            , xsri.selling_from_cust_code    AS selling_from_cust_code
            , xsri.selling_to_cust_code      AS selling_to_cust_code
            , xsri.invalid_flag              AS invalid_flag
            , xsri.selling_trns_rate_info_id AS selling_trns_rate_info_id
      INTO    lv_selling_from_base_code
            , lv_selling_from_cust_code
            , lv_selling_to_cust_code
            , lv_invalid_flag
            , ln_selling_trns_rate_info_id
      FROM    xxcok_selling_rate_info xsri
      WHERE   xsri.selling_from_base_code = iv_selling_from_base_code
      AND     xsri.selling_from_cust_code = iv_selling_from_cust_code
      AND     xsri.selling_to_cust_code   = iv_selling_to_cust_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- =============================================================================
    -- 1.�f�[�^�𒊏o�ł��Ȃ������ꍇ�AA-11�֑J��
    -- =============================================================================
    IF ( ln_selling_trns_rate_info_id IS NULL ) THEN
      ins_selling_trns_rate_info(
        ov_errbuf                 => lv_errbuf                   --�G���[�E���b�Z�[�W
      , ov_retcode                => lv_retcode                  --���^�[���E�R�[�h
      , ov_errmsg                 => lv_errmsg                   --���[�U�[�E�G���[�E���b�Z�[�W
      , iv_selling_from_base_code => iv_selling_from_base_code   --����U�֌����_�R�[�h
      , iv_selling_from_cust_code => iv_selling_from_cust_code   --����U�֌��ڋq�R�[�h
      , iv_selling_to_cust_code   => iv_selling_to_cust_code     --����U�֐�ڋq�R�[�h
      , in_selling_trns_rate      => in_selling_trns_rate        --����U�֊���
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    -- =============================================================================
    -- 2.�f�[�^�𒊏o�ł����ꍇ�AA-12�֑J��
    -- =============================================================================
    ELSIF ( ln_selling_trns_rate_info_id IS NOT NULL ) THEN
      upd_selling_trns_rate_info(
        ov_errbuf                    => lv_errbuf                      --�G���[�E���b�Z�[�W
      , ov_retcode                   => lv_retcode                     --���^�[���E�R�[�h
      , ov_errmsg                    => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
      , iv_selling_from_base_code    => iv_selling_from_base_code      --����U�֌����_�R�[�h
      , iv_selling_from_cust_code    => iv_selling_from_cust_code      --����U�֌��ڋq�R�[�h
      , iv_selling_to_cust_code      => iv_selling_to_cust_code        --����U�֐�ڋq�R�[�h
      , in_selling_trns_rate         => in_selling_trns_rate           --����U�֊���
      , iv_invalid_flag              => lv_invalid_flag                --�����t���O
      , in_selling_trns_rate_info_id => ln_selling_trns_rate_info_id   --����U�֊������ID
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_selling_trns_rate_info_a8;
--
  /**********************************************************************************
   * Procedure Name   : get_tmp_tbl
   * Description      : ����U�֊����o�^�ꎞ�\�ʃf�[�^���o(A-7)
   ***********************************************************************************/
  PROCEDURE get_tmp_tbl(
    ov_errbuf                 OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                 OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id                IN  NUMBER      --�t�@�C��ID
  , iv_selling_from_base_code IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code IN  VARCHAR2)   --����U�֐�ڋq�R�[�h
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(15) := 'get_tmp_tbl';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode    BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- ======================
    -- ���[�J���E�J�[�\��
    -- ======================
    -- =============================================================================
    -- ����U�֊����o�^�ꎞ�\�f�[�^���o
    -- =============================================================================
    CURSOR get_tmp_cur
    IS
      SELECT  xtsr.valid_invalid_type     AS  valid_invalid_type       --�o�^�E�����敪
            , xtsr.selling_from_base_code AS  selling_from_base_code   --����U�֌����_�R�[�h
            , xtsr.selling_from_cust_code AS  selling_from_cust_code   --����U�֌��ڋq�R�[�h
            , xtsr.selling_to_cust_code   AS  selling_to_cust_code     --����U�֐�ڋq�R�[�h
            , xtsr.selling_trns_rate      AS  selling_trns_rate        --����U�֊���
      FROM    xxcok_tmp_selling_rate xtsr
      WHERE   xtsr.file_id                = in_file_id
      AND     xtsr.selling_from_base_code = iv_selling_from_base_code
      AND     xtsr.selling_from_cust_code = iv_selling_from_cust_code;
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    TYPE tab_type IS TABLE OF get_tmp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_get_tmp_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  get_tmp_cur;
    FETCH get_tmp_cur BULK COLLECT INTO l_get_tmp_tab;
    CLOSE get_tmp_cur;
--
    <<loop_3>>
    FOR ln_idx IN 1 .. l_get_tmp_tab.COUNT LOOP
      -- =============================================================================
      -- �o�^������敪���o�^(0)�̏ꍇ�AA-8�֑J��
      -- =============================================================================
      IF ( l_get_tmp_tab( ln_idx ).valid_invalid_type = cv_0 ) THEN
        get_selling_trns_rate_info_a8(
          ov_errbuf                 => lv_errbuf                                        --�G���[���b�Z�[�W
        , ov_retcode                => lv_retcode                                       --���^�[���R�[�h
        , ov_errmsg                 => lv_errmsg                                        --���[�U�[�G���[���b�Z�[�W
        , iv_selling_from_base_code => l_get_tmp_tab( ln_idx ).selling_from_base_code   --����U�֌����_�R�[�h
        , iv_selling_from_cust_code => l_get_tmp_tab( ln_idx ).selling_from_cust_code   --����U�֌��ڋq�R�[�h
        , iv_selling_to_cust_code   => l_get_tmp_tab( ln_idx ).selling_to_cust_code     --����U�֐�ڋq�R�[�h
        , in_selling_trns_rate      => l_get_tmp_tab( ln_idx ).selling_trns_rate        --����U�֊���
        );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
          EXIT loop_3;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      -- =============================================================================
      -- �o�^������敪������(1)�̏ꍇ�AA-9�֑J��
      -- =============================================================================
      ELSIF ( l_get_tmp_tab( ln_idx ).valid_invalid_type = cv_1 ) THEN
        get_selling_trns_rate_info_a9(
          ov_errbuf                 => lv_errbuf                                        --�G���[���b�Z�[�W
        , ov_retcode                => lv_retcode                                       --���^�[���R�[�h
        , ov_errmsg                 => lv_errmsg                                        --���[�U�[�G���[���b�Z�[�W
        , iv_valid_invalid_type     => l_get_tmp_tab( ln_idx ).valid_invalid_type       --�o�^������敪
        , iv_selling_from_base_code => l_get_tmp_tab( ln_idx ).selling_from_base_code   --����U�֌����_�R�[�h
        , iv_selling_from_cust_code => l_get_tmp_tab( ln_idx ).selling_from_cust_code   --����U�֌��ڋq�R�[�h
        , iv_selling_to_cust_code   => l_get_tmp_tab( ln_idx ).selling_to_cust_code     --����U�֐�ڋq�R�[�h
        , in_selling_trns_rate      => l_get_tmp_tab( ln_idx ).selling_trns_rate        --����U�֊���
        );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
          EXIT loop_3;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_3;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1 ,5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_tmp_tbl_union_data
   * Description      : ����U�֊����o�^�ꎞ�\�W�v�f�[�^���o(A-6)
   ***********************************************************************************/
  PROCEDURE get_tmp_tbl_union_data(
    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)     --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name        CONSTANT VARCHAR2(30)  := 'get_tmp_tbl_union_data';  --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                     VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode                 BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���E�J�[�\��
    -- =======================
    -- =============================================================================
    -- ����U�֌��f�[�^�W�v
    -- =============================================================================
    CURSOR data_union_cur
    IS
      SELECT    inline_view_a.selling_from_base_code AS selling_from_base_code
              , inline_view_a.selling_from_cust_code AS selling_from_cust_code
              , SUM(inline_view_a.selling_trns_rate) AS sum_selling_trns_rate
      FROM     (
                SELECT  xtsr.selling_from_base_code            AS selling_from_base_code
                      , xtsr.selling_from_cust_code            AS selling_from_cust_code
                      , xtsr.selling_to_cust_code              AS selling_to_cust_code
                      , DECODE( xtsr.valid_invalid_type,
                                cv_1, cn_0,
                                cv_0, xtsr.selling_trns_rate ) AS selling_trns_rate
                FROM   xxcok_tmp_selling_rate xtsr
                WHERE  xtsr.file_id    = in_file_id
                AND    xtsr.error_flag = cv_0
                UNION ALL
                SELECT  xsri.selling_from_base_code AS selling_from_base_code
                      , xsri.selling_from_cust_code AS selling_from_cust_code
                      , xsri.selling_to_cust_code   AS selling_to_cust_code
                      , xsri.selling_trns_rate      AS selling_trns_rate
                FROM    xxcok_selling_rate_info xsri
                WHERE   xsri.invalid_flag = cv_0
                AND     NOT EXISTS (
                                    SELECT 'X'
                                    FROM   xxcok_tmp_selling_rate xtsr
                                    WHERE  xtsr.file_id    = in_file_id
                                    AND    xtsr.error_flag = cv_0
                                    AND    xtsr.selling_from_base_code = xsri.selling_from_base_code
                                    AND    xtsr.selling_from_cust_code = xsri.selling_from_cust_code
                                    AND    xtsr.selling_to_cust_code   = xsri.selling_to_cust_code
                                   )
               ) inline_view_a
      GROUP BY  selling_from_base_code
              , selling_from_cust_code;
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    TYPE tab_type IS TABLE OF data_union_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_data_union_cur_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  data_union_cur;
    FETCH data_union_cur BULK COLLECT INTO l_data_union_cur_tab;
    CLOSE data_union_cur;
--
    <<loop_2>>
    FOR ln_idx IN 1 .. l_data_union_cur_tab.COUNT LOOP
      -- =============================================================================
      --  ���[���o�b�N�p�ɃZ�[�u�|�C���g�ݒ�
      -- =============================================================================
      SAVEPOINT get_union_data_seve;
      -- =============================================================================
      -- �u����U�֊����v�̏W�v�l��'100'��������'0'�łȂ��ꍇ
      -- ��O�������s���A���̃��R�[�h�֏�����J��
      -- =============================================================================
      IF NOT (   ( l_data_union_cur_tab( ln_idx ).sum_selling_trns_rate = cn_100 )
              OR ( l_data_union_cur_tab( ln_idx ).sum_selling_trns_rate = cn_0   )
             ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10026
                  , iv_token_name1  => cv_token_from_base
                  , iv_token_value1 => l_data_union_cur_tab( ln_idx ).selling_from_base_code
                  , iv_token_name2  => cv_token_from_cust
                  , iv_token_value2 => l_data_union_cur_tab( ln_idx ).selling_from_cust_code
                  , iv_token_name3  => cv_token_rate
                  , iv_token_value3 => TO_CHAR( l_data_union_cur_tab( ln_idx ).sum_selling_trns_rate )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        ov_retcode := cv_status_warn;
        -- *** �G���[�����J�E���g ***
        gn_error_cnt := gn_error_cnt + 1;
      -- =============================================================================
      -- �u����U�֊����v�̏W�v�l��'100'��������'0'�̏ꍇ�AA-7�֑J��
      -- =============================================================================
      ELSE
        get_tmp_tbl(
          ov_errbuf                 => lv_errbuf                                             --�G���[���b�Z�[�W
        , ov_retcode                => lv_retcode                                            --���^�[���R�[�h
        , ov_errmsg                 => lv_errmsg                                             --���[�U�[�G���[���b�Z�[�W
        , in_file_id                => in_file_id                                            --�t�@�C��ID
        , iv_selling_from_base_code => l_data_union_cur_tab( ln_idx ).selling_from_base_code --����U�֌����_�R�[�h
        , iv_selling_from_cust_code => l_data_union_cur_tab( ln_idx ).selling_from_cust_code --����U�֐�ڋq�R�[�h
        );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_2;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_tbl_union_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_tmp_tbl_error_flag
   * Description      : ����U�֊����o�^�ꎞ�\�L���t���O�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_tmp_tbl_error_flag(
    ov_errbuf                 OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                 OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id                IN  NUMBER      --�t�@�C��ID
  , iv_selling_from_base_code IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code IN  VARCHAR2)   --����U�֌��ڋq�R�[�h
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'upd_tmp_tbl_error_flag';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg       VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode   BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- 1.����U�֊����o�^�ꎞ�\�̃��b�N�擾
    -- =============================================================================
    CURSOR tmp_selling_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxcok_tmp_selling_rate xtsr
      WHERE  xtsr.file_id = in_file_id
      AND    (   ( xtsr.selling_from_base_code = iv_selling_from_base_code )
              OR ( xtsr.selling_from_base_code IS NULL )
             )
      AND    (   ( xtsr.selling_from_cust_code = iv_selling_from_cust_code )
              OR ( xtsr.selling_from_cust_code IS NULL )
             )
      FOR UPDATE OF xtsr.file_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  tmp_selling_cur;
    CLOSE tmp_selling_cur;
    -- =============================================================================
    -- 2.����U�֊����ꎞ�\�̍X�V����
    -- =============================================================================
    BEGIN
      UPDATE xxcok_tmp_selling_rate xtsr
      SET    error_flag = cv_1
      WHERE  xtsr.file_id = in_file_id
      AND    (   ( xtsr.selling_from_base_code = iv_selling_from_base_code )
              OR ( xtsr.selling_from_base_code IS NULL )
             )
      AND    (   ( xtsr.selling_from_cust_code = iv_selling_from_cust_code )
              OR ( xtsr.selling_from_cust_code IS NULL )
             )
      AND    xtsr.error_flag <> cv_1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** �X�V�����Ɏ��s�����ꍇ ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10027
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10352
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_tmp_tbl_error_flag;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �f�[�^�Ó����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf                  OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode                 OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg                  OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_valid_invalid_type      IN  VARCHAR2    --�o�^������敪
  , iv_selling_from_base_code  IN  VARCHAR2    --����U�֌����_�R�[�h
  , iv_selling_from_cust_code  IN  VARCHAR2    --����U�֌��ڋq�R�[�h
  , iv_selling_to_cust_code    IN  VARCHAR2    --����U�֐�ڋq�R�[�h
  , in_selling_trns_rate       IN  NUMBER)     --�U�֊���
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10)  := 'chk_data';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --�G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --���^�[���R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�G���[���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    ln_selling  NUMBER         DEFAULT 0;      --����U�֊��������`�F�b�N�ϐ�
    ln_rownum   NUMBER         DEFAULT 0;      --ROWNUM
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����O
    -- =======================
    data_warn_expt  EXCEPTION;   --�f�[�^�x��
    data_many_expt  EXCEPTION;   --�f�[�^�����擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.�K�{�`�F�b�N
    -- =============================================================================
    IF (   ( iv_valid_invalid_type     IS NULL )
        OR ( iv_selling_from_base_code IS NULL )
        OR ( iv_selling_from_cust_code IS NULL )
        OR ( iv_selling_to_cust_code   IS NULL )
        OR ( in_selling_trns_rate      IS NULL )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10451
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE data_warn_expt;
    END IF;
    -- =============================================================================
    -- 2.�u�o�^�E�����敪�v�����Ғl�i�[����1�j�łȂ��ꍇ�A�x�����b�Z�[�W�o��
    -- =============================================================================
    IF NOT (   ( iv_valid_invalid_type = cv_0 )
            OR ( iv_valid_invalid_type = cv_1 )
           ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10014
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      RAISE data_warn_expt;
    END IF;
    -- =============================================================================
    -- �u�o�^�E�����敪�v���u�o�^(�[��)�v�̏ꍇ
    -- =============================================================================
    IF ( iv_valid_invalid_type = cv_0 ) THEN 
      -- =============================================================================
      -- 3.�u����U�֌����_�R�[�h�v���ڋq�}�X�^�ɑ��݂��邩�m�F
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    hz_cust_accounts hca
        WHERE   hca.account_number      = iv_selling_from_base_code
        AND     hca.customer_class_code = cv_1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10015
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00047
                    , iv_token_name1  => cv_token_sales_loc
                    , iv_token_value1 => iv_selling_from_base_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 4.�u����U�֌��ڋq�R�[�h�v���}�X�^�ɑ��݂��邩�m�F
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    hz_cust_accounts hca
              , hz_parties hp
              , xxcmm_cust_accounts xca
        WHERE   hca.party_id             = hp.party_id
        AND     hca.cust_account_id      = xca.customer_id
        AND     hca.account_number       = iv_selling_from_cust_code
        AND     hp.duns_number_c         = cv_40
        AND     xca.selling_transfer_div = cv_1
        AND     xca.chain_store_code IS NULL
        AND     hca.customer_class_code <> cv_12;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10016
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00046
                    , iv_token_name1  => cv_token_cust_code
                    , iv_token_value1 => iv_selling_from_cust_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 5.����U�֌����_�R�[�h�Ɣ���U�֌��ڋq�R�[�h���������R�t���Ă��邱�Ɗm�F
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    hz_cust_accounts hca
              , xxcmm_cust_accounts xca
        WHERE   hca.cust_account_id = xca.customer_id
        AND     xca.sale_base_code  = iv_selling_from_base_code
        AND     hca.account_number  = iv_selling_from_cust_code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10018
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00046
                    , iv_token_name1  => cv_token_cust_code
                    , iv_token_value1 => iv_selling_from_cust_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
        RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 6.�u����U�֐�ڋq�R�[�h�v���}�X�^�ɑ��݂��邩���m�F
      -- =============================================================================
      BEGIN
        SELECT ROWNUM
        INTO   ln_rownum
        FROM   hz_parties hp
             , hz_cust_accounts hca
             , xxcmm_cust_accounts xca
        WHERE  hca.party_id             = hp.party_id
        AND    hca.cust_account_id      = xca.customer_id
        AND    hca.account_number       = iv_selling_to_cust_code
        AND    hp.duns_number_c         = cv_40
        AND    xca.selling_transfer_div = cv_1
        AND    xca.chain_store_code IS NULL
        AND    hca.customer_class_code <> cv_12;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10017
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00046
                    , iv_token_name1  => cv_token_cust_code
                    , iv_token_value1 => iv_selling_to_cust_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
        RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 9.����U�֌����e�[�u���A����U�֐���e�[�u���ɁA�f�[�^�����݂��邩�m�F
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    xxcok_selling_from_info xsfi
              , xxcok_selling_to_info xsti
        WHERE   xsfi.selling_from_info_id   = xsti.selling_from_info_id
        AND     xsfi.selling_from_base_code = iv_selling_from_base_code
        AND     xsfi.selling_from_cust_code = iv_selling_from_cust_code
        AND     xsti.selling_to_cust_code   = iv_selling_to_cust_code
        AND     xsti.start_month           <= TO_CHAR( TRUNC( gd_process_date, cv_date_format ), 'YYYYMM' )
        AND     xsti.invalid_flag           = cv_0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10021
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --�o�͋敪
                        , iv_message  => lv_msg              --���b�Z�[�W
                        , in_new_line => 0                   --���s
                        );
          RAISE data_warn_expt;
      END;
      -- =============================================================================
      -- 10.����U�֊����̒l�̃`�F�b�N
      -- =============================================================================
      IF ( in_selling_trns_rate = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10450
                  , iv_token_name1  => cv_token_kubun
                  , iv_token_value1 => iv_valid_invalid_type
                  , iv_token_name2  => cv_token_from_base
                  , iv_token_value2 => iv_selling_from_base_code
                  , iv_token_name3  => cv_token_from_cust
                  , iv_token_value3 => iv_selling_from_cust_code
                  , iv_token_name4  => cv_token_to_cust
                  , iv_token_value4 => iv_selling_to_cust_code
                  , iv_token_name5  => cv_token_rate
                  , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        RAISE data_warn_expt;
      END IF;
    END IF;
    -- =============================================================================
    -- 7.�u����U�֊����v�̏������h999.9�h�̏����ł��邩���m�F
    -- =============================================================================
    BEGIN
      ln_selling := TO_NUMBER( in_selling_trns_rate, cv_number_format );
    EXCEPTION
      WHEN VALUE_ERROR THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10019
                  , iv_token_name1  => cv_token_kubun
                  , iv_token_value1 => iv_valid_invalid_type
                  , iv_token_name2  => cv_token_from_base
                  , iv_token_value2 => iv_selling_from_base_code
                  , iv_token_name3  => cv_token_from_cust
                  , iv_token_value3 => iv_selling_from_cust_code
                  , iv_token_name4  => cv_token_to_cust
                  , iv_token_value4 => iv_selling_to_cust_code
                  , iv_token_name5  => cv_token_rate
                  , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --�o�͋敪
                      , iv_message  => lv_msg              --���b�Z�[�W
                      , in_new_line => 0                   --���s
                      );
        RAISE data_warn_expt;
    END;
    -- =============================================================================
    -- 8.����U�֊����̒l���}�C�i�X�̏ꍇ�A�x�����b�Z�[�W
    -- =============================================================================
    IF ( in_selling_trns_rate < cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10020
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      RAISE data_warn_expt;
    END IF;
  EXCEPTION
    -- *** �f�[�^�`�F�b�N�Ōx���̏ꍇ ***
    WHEN data_warn_expt THEN
      ov_retcode := cv_status_warn;
    -- *** ���݃`�F�b�N�ŕ����擾���ꂽ�ꍇ
    WHEN data_many_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : get_tmp_selling_trns_rate
   * Description      : ����U�֊����o�^�ꎞ�\�f�[�^���o(A-3)
   ***********************************************************************************/
  PROCEDURE get_tmp_selling_trns_rate(
    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)     --�t�@�C��ID
  IS
    -- ======================
    -- ���[�J���萔
    -- ======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'get_tmp_selling_trns_rate';  --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)    DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg               VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode           BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    ln_selling_trns_rate NUMBER;                        --����U�֊���(�ꎞ�\�W�v�l)
    -- =====================
    -- ���[�J���E�J�[�\��
    -- =====================
    CURSOR temporary_cur
    IS
      -- =============================================================================
      -- A-2�Ŏ擾���ꂽ�ꎞ�\�̃��R�[�h�𒊏o
      -- =============================================================================
      SELECT  xtsr.valid_invalid_type     AS valid_invalid_type       --�o�^�E�����敪
            , xtsr.selling_from_base_code AS selling_from_base_code   --����U�֌����_�R�[�h
            , xtsr.selling_from_cust_code AS selling_from_cust_code   --����U�֌��ڋq�R�[�h
            , xtsr.selling_to_cust_code   AS selling_to_cust_code     --����U�֐�ڋq�R�[�h
            , xtsr.selling_trns_rate      AS selling_trns_rate        --����U�֊���
      FROM    xxcok_tmp_selling_rate xtsr
      WHERE   xtsr.file_id = in_file_id;
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    TYPE tab_type IS TABLE OF temporary_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_temporary_cur_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  temporary_cur;
    FETCH temporary_cur BULK COLLECT INTO l_temporary_cur_tab;
    CLOSE temporary_cur;
    -- *** �Ώۏ��������J�E���g ***
    gn_target_cnt := l_temporary_cur_tab.COUNT;
--
    <<loop_1>>
    FOR ln_idx IN 1 .. l_temporary_cur_tab.COUNT LOOP
      -- =============================================================================
      -- �f�[�^�Ó����`�F�b�N(A-4)�Ăяo��
      -- =============================================================================
      chk_data(
        ov_errbuf                 => lv_errbuf                                             --�G���[���b�Z�[�W
      , ov_retcode                => lv_retcode                                            --���^�[���R�[�h
      , ov_errmsg                 => lv_errmsg                                             --���[�U�[�G���[���b�Z�[�W
      , iv_valid_invalid_type     => l_temporary_cur_tab( ln_idx ).valid_invalid_type      --�o�^�E�����敪
      , iv_selling_from_base_code => l_temporary_cur_tab( ln_idx ).selling_from_base_code  --����U�֌����_�R�[�h
      , iv_selling_from_cust_code => l_temporary_cur_tab( ln_idx ).selling_from_cust_code  --����U�֌��ڋq�R�[�h
      , iv_selling_to_cust_code   => l_temporary_cur_tab( ln_idx ).selling_to_cust_code    --����U�֐�ڋq�R�[�h
      , in_selling_trns_rate      => l_temporary_cur_tab( ln_idx ).selling_trns_rate       --����U�֊���
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- =============================================================================
      -- �ꎞ�\�f�[�^�L���t���O�X�V(A-5)�Ăяo��
      -- =============================================================================
      IF ( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt := gn_error_cnt + 1;
--
        upd_tmp_tbl_error_flag(
          ov_errbuf                 => lv_errbuf                                             --�G���[���b�Z�[�W
        , ov_retcode                => lv_retcode                                            --���^�[���R�[�h
        , ov_errmsg                 => lv_errmsg                                             --���[�U�[�G���[���b�Z�[�W
        , in_file_id                => in_file_id                                            --�t�@�C��ID
        , iv_selling_from_base_code => l_temporary_cur_tab( ln_idx ).selling_from_base_code  --����U�֌����_�R�[�h
        , iv_selling_from_cust_code => l_temporary_cur_tab( ln_idx ).selling_from_cust_code  --����U�֌��ڋq�R�[�h
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_1;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_selling_trns_rate;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_interface_date
   * Description      : �t�@�C���A�b�v���[�hI/F�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_upload_interface_date(
    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)     --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'get_file_upload_interface_date';  --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                  VARCHAR2(5000)  DEFAULT NULL;   --�G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1)     DEFAULT NULL;   --���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000)  DEFAULT NULL;   --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                     VARCHAR2(5000)  DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_file_name               VARCHAR2(256)   DEFAULT NULL;   --�t�@�C����
    lv_valid_invalid_type      VARCHAR2(1)     DEFAULT NULL;   --�o�^�E�����敪
    lv_selling_from_base_code  VARCHAR2(4)     DEFAULT NULL;   --����U�֌����_�R�[�h
    lv_selling_from_cust_code  VARCHAR2(9)     DEFAULT NULL;   --����U�֌��ڋq�R�[�h
    lv_selling_to_cust_code    VARCHAR2(9)     DEFAULT NULL;   --����U�֐�ڋq�R�[�h
    lv_line                    VARCHAR2(32767) DEFAULT NULL;   --1�s�̃f�[�^
    ln_selling_trns_rate       NUMBER          DEFAULT NULL;   --����U�֊���
    ln_csv_col_cnt             NUMBER          DEFAULT 0;      --CSV���ڐ�
    lb_retcode                 BOOLEAN         DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;   --�s�e�[�u���i�[�̈�
    l_split_csv_tab   xxcok_common_pkg.g_split_csv_tbl;    --CSV�����f�[�^�i�[�̈�
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hI/F�e�[�u���̃��b�N�擾
    -- =============================================================================
    CURSOR xmf_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxccp_mrp_file_ul_interface xmf
      WHERE  xmf.file_id = in_file_id
      FOR UPDATE OF xmf.file_id NOWAIT;
    -- =======================
    -- ���[�J����O
    -- =======================
    blob_expt  EXCEPTION;   --BLOB�f�[�^�ϊ��G���[
    file_expt  EXCEPTION;   --��t�@�C���G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  xmf_cur;
    CLOSE xmf_cur;
    -- =============================================================================
    -- �A�b�v���[�h�t�@�C���̃t�@�C�����擾
    -- =============================================================================
    SELECT xmf.file_name AS file_name
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id;
    -- =========================================
    -- 1.�A�b�v���[�h�t�@�C���̃t�@�C�����o��
    -- =========================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00006
              , iv_token_name1  => cv_token_file_name
              , iv_token_value1 => lv_file_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 1                   --���s
                  );
    -- =============================================================================
    -- 3.�t�@�C���A�b�v���[�hI/F�e�[�u����FILE_DATA�擾
    -- =============================================================================
    xxccp_common_pkg2.blob_to_varchar2(
      ov_errbuf    => lv_errbuf
    , ov_retcode   => lv_retcode
    , ov_errmsg    => lv_errmsg
    , in_file_id   => in_file_id
    , ov_file_data => l_file_data_tab
    );
    IF NOT ( lv_retcode = cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
    -- =============================================================================
    -- 4.�f�[�^������1���ȉ��̏ꍇ�A��O����
    -- =============================================================================
    IF ( l_file_data_tab.COUNT <= cn_1 ) THEN
      RAISE file_expt;
    END IF;
    -- =============================================
    -- �擾���������A�s���Ƃɏ���(2�s�ڈȍ~)
    -- =============================================
    <<main_loop>>
    FOR ln_index IN 2 .. l_file_data_tab.COUNT LOOP
      --1�s���̃f�[�^���i�[
      lv_line := l_file_data_tab( ln_index );
      -- =============================================================================
      -- 5.CSV�����񕔕���
      -- =============================================================================
      xxcok_common_pkg.split_csv_data_p(
        ov_errbuf        => lv_errbuf         --�G���[�o�b�t�@
      , ov_retcode       => lv_retcode        --���^�[���R�[�h
      , ov_errmsg        => lv_errmsg         --�G���[���b�Z�[�W
      , iv_csv_data      => lv_line           --CSV������
      , on_csv_col_cnt   => ln_csv_col_cnt    --CSV���ڐ�
      , ov_split_csv_tab => l_split_csv_tab   --CSV�����f�[�^
      );
      <<comma_loop>>
      FOR ln_cnt IN 1 .. ln_csv_col_cnt LOOP
        --���ڇ@(�o�^������敪)
        IF ( ln_cnt = 1 ) THEN
          lv_valid_invalid_type := l_split_csv_tab( ln_cnt );
        --���ڇA(����U�֌����_�R�[�h)
        ELSIF ( ln_cnt = 2 ) THEN
          lv_selling_from_base_code := l_split_csv_tab( ln_cnt );
        --���ڇB(����U�֌��ڋq�R�[�h)
        ELSIF ( ln_cnt = 3 ) THEN
          lv_selling_from_cust_code := l_split_csv_tab( ln_cnt );
        --���ڇC(����U�֐�ڋq�R�[�h)
        ELSIF ( ln_cnt = 4 ) THEN
          lv_selling_to_cust_code := l_split_csv_tab( ln_cnt );
        --���ڇD(����U�֊���)
        ELSIF ( ln_cnt = 5 ) THEN
          ln_selling_trns_rate := TO_NUMBER( l_split_csv_tab( ln_cnt ) );
        END IF;
      END LOOP comma_loop;
      -- =============================================================================
      -- 6.����U�֊����o�^�ꎞ�\�֓Ǎ���
      -- =============================================================================
      INSERT INTO xxcok_tmp_selling_rate(
        valid_invalid_type           --�o�^�E�����敪
      , selling_from_base_code       --����U�֌����_�R�[�h
      , selling_from_cust_code       --����U�֌��ڋq�R�[�h
      , selling_to_cust_code         --����U�֐�ڋq�R�[�h
      , selling_trns_rate            --�U�֊���
      , file_id                      --�t�@�C��ID
      , error_flag                   --�G���[�t���O
      ) VALUES (
        lv_valid_invalid_type        --valid_invalid_type
      , lv_selling_from_base_code    --selling_from_base_code
      , lv_selling_from_cust_code    --selling_from_cust_code
      , lv_selling_to_cust_code      --selling_to_cust_code
      , ln_selling_trns_rate         --selling_trns_rate
      , in_file_id                   --file_id
      , cv_0                         --error_flag
      );
    END LOOP main_loop;
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** BLOB�f�[�^�ϊ��G���[ ***
    WHEN blob_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00041
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
              );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ��t�@�C���G���[ ***
    WHEN file_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00039
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
              );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --�o�͋敪
                    , iv_message  => lv_msg              --���b�Z�[�W
                    , in_new_line => 0                   --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_file_upload_interface_date;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf          OUT VARCHAR2     --�G���[�E���b�Z�[�W
  , ov_retcode         OUT VARCHAR2     --���^�[���E�R�[�h
  , ov_errmsg          OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id         IN  NUMBER       --�t�@�C��ID
  , iv_format_pattern  IN  VARCHAR2)    --�t�H�[�}�b�g�p�^�[��
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name      CONSTANT VARCHAR2(50) := 'init';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --�G���[���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --���^�[���R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�G���[���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����O
    -- =======================
    get_process_expt  EXCEPTION;   --�Ɩ����t�擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.�R���J�����g�v���O�������͍��ڂ����b�Z�[�W�o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00016
              , iv_token_name1  => cv_token_file_id
              , iv_token_value1 => gv_file_id
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT  --�o�͋敪
                   , iv_message  => lv_msg           --���b�Z�[�W
                   , in_new_line => 0                --���s
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 0                 --���s
                  );
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00017
              , iv_token_name1  => cv_token_format
              , iv_token_value1 => iv_format_pattern
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT  --�o�͋敪
                  , iv_message  => lv_msg           --���b�Z�[�W
                  , in_new_line => 1                --���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 2                 --���s
                  );
    -- =============================================================================
    -- 2.�Ɩ��������t�̎擾
    -- =============================================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_process_expt;
    END IF;
  EXCEPTION
    -- *** �Ɩ����t�擾�G���[ ***
    WHEN get_process_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_00028
                  );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf         OUT VARCHAR2     --�G���[���b�Z�[�W
  , ov_retcode        OUT VARCHAR2     --���^�[���R�[�h
  , ov_errmsg         OUT VARCHAR2     --���[�U�[�G���[���b�Z�[�W
  , in_file_id        IN  NUMBER       --�t�@�C��ID
  , iv_format_pattern IN  VARCHAR2)    --�t�H�[�}�b�g�p�^�[��
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10) := 'submain';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;   --�G���[���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;   --���^�[���R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�G���[���b�Z�[�W
    lb_retcode   BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
    ln_counter   NUMBER         DEFAULT 0;      --�ꎞ�\�̗L���f�[�^�J�E���g
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ��������(A-1)�̌ďo��
    -- =============================================================================
    init(
      ov_errbuf         => lv_errbuf           --�G���[���b�Z�[�W
    , ov_retcode        => lv_retcode          --���^�[���R�[�h
    , ov_errmsg         => lv_errmsg           --���[�U�[�G���[���b�Z�[�W
    , in_file_id        => in_file_id          --�t�@�C��ID
    , iv_format_pattern => iv_format_pattern   --�t�H�[�}�b�g�p�^�[��
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hI/F�f�[�^�擾(A-2)�̌ďo��
    -- =============================================================================
    get_file_upload_interface_date(
      ov_errbuf  => lv_errbuf    --�G���[���b�Z�[�W
    , ov_retcode => lv_retcode   --���^�[���R�[�h
    , ov_errmsg  => lv_errmsg    --���[�U�[�G���[���b�Z�[�W
    , in_file_id => in_file_id   --�t�@�C��ID
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- �ꎞ�\�f�[�^���o(A-3)�̌ďo��
    -- =============================================================================
    get_tmp_selling_trns_rate(
      ov_errbuf  => lv_errbuf    --�G���[���b�Z�[�W
    , ov_retcode => lv_retcode   --���^�[���R�[�h
    , ov_errmsg  => lv_errmsg    --���[�U�[�G���[���b�Z�[�W
    , in_file_id => in_file_id   --�t�@�C��ID
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- �ꎞ�\�ɗL���f�[�^�����݂��邩�`�F�b�N
    -- =============================================================================
    SELECT COUNT(xtsr.file_id)
    INTO   ln_counter
    FROM   xxcok_tmp_selling_rate xtsr
    WHERE  xtsr.file_id    = in_file_id
    AND    xtsr.error_flag = cv_0
    AND    ROWNUM = 1;
    -- =============================================================================
    -- �L���f�[�^�����݂����ꍇ�A�ꎞ�\�W�v�f�[�^���o(A-6)�̌ďo��
    -- =============================================================================
    IF( ln_counter <> 0 ) THEN
      get_tmp_tbl_union_data(
        ov_errbuf  => lv_errbuf    --�G���[���b�Z�[�W
      , ov_retcode => lv_retcode   --���^�[���R�[�h
      , ov_errmsg  => lv_errmsg    --���[�U�[�G���[���b�Z�[�W
      , in_file_id => in_file_id   --�t�@�C��ID
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hI/F�e�[�u�����R�[�h�폜(A-13)
    -- =============================================================================
    IF (   ( lv_retcode = cv_status_normal )
        OR ( lv_retcode = cv_status_warn )
        ) THEN
      del_file_upload_interface_tbl(
        ov_errbuf  => lv_errbuf    --�G���[���b�Z�[�W
      , ov_retcode => lv_retcode   --���^�[���R�[�h
      , ov_errmsg  => lv_errmsg    --���[�U�[�G���[���b�Z�[�W
      , in_file_id => in_file_id   --�t�@�C��ID
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ����U�֊����̓o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf            OUT  VARCHAR2     --�G���[���b�Z�[�W
  , retcode           OUT  VARCHAR2     --�G���[�R�[�h
  , iv_file_id        IN   VARCHAR2     --�t�@�C��ID
  , iv_format_pattern IN   VARCHAR2)    --�t�H�[�}�b�g�p�^�[��
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name      CONSTANT VARCHAR2(5) := 'main';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;   --�G���[���b�Z�[�W
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;   --���^�[���R�[�h
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;   --���[�U�[�G���[���b�Z�[�W
    lv_msg            VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�擾�ϐ�
    lv_message_code   VARCHAR2(5000) DEFAULT NULL;   --���b�Z�[�W�R�[�h
    lb_retcode        BOOLEAN        DEFAULT TRUE;   --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    gn_file_id := TO_NUMBER( iv_file_id );
    gv_file_id := iv_file_id;
    -- =============================================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- =============================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- =============================================================================
    -- submain�̌ďo��
    -- =============================================================================
    submain(
      ov_errbuf         => lv_errbuf           --�G���[���b�Z�[�W
    , ov_retcode        => lv_retcode          --���^�[���R�[�h
    , ov_errmsg         => lv_errmsg           --���[�U�[�G���[���b�Z�[�W
    , in_file_id        => gn_file_id          --�t�@�C��ID
    , iv_format_pattern => iv_format_pattern   --�t�H�[�}�b�g�p�^�[��
    );
    -- =============================================================================
    -- �G���[�I���̏ꍇ�A�Ώی����E����������0���ɂ��A�G���[������1���ɂ���B
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := cn_0;
      gn_normal_cnt := cn_0;
      gn_error_cnt  := cn_1;
    END IF;
    -- =============================================================================
    -- �G���[�o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_errmsg         --���b�Z�[�W
                    , in_new_line => 1                 --���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      --�o�͋敪
                    , iv_message  => lv_errbuf         --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
    END IF;
    -- =============================================================================
    -- �x���I���̏ꍇ�A��s���o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => NULL              --���b�Z�[�W
                    , in_new_line => 1                 --���s
                    );
    END IF;
    -- =============================================================================
    -- �Ώی����o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90000
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_target_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- =============================================================================
    -- ���������o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90001
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_normal_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- =============================================================================
    -- �G���[�����o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90002
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_error_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 1                   --���s
                  );
    -- =============================================================================
    -- �����I�����b�Z�[�W���o��
    -- =============================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_message_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_message_90005;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_message_90006;
    END IF;
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => lv_message_code
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- *** �X�e�[�^�X�Z�b�g ***
    retcode := lv_retcode;
    -- *** �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK ***
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --�G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode     --���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg      --���[�U�[�E�G���[�E���b�Z�[�W
      , in_file_id => gn_file_id     --�t�@�C��ID
      );
    END IF;
    --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_errmsg         --���b�Z�[�W
                    , in_new_line => 1                 --���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      --�o�͋敪
                    , iv_message  => lv_errbuf         --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ROLLBACK;
    END IF;
    --�����̊m��
    COMMIT;
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --�G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode     --���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg      --���[�U�[�E�G���[�E���b�Z�[�W
      , in_file_id => gn_file_id     --�t�@�C��ID
      );
      --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK
      IF ( lv_retcode = cv_status_error ) THEN
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_errmsg         --���b�Z�[�W
                      , in_new_line => 1                 --���s
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      --�o�͋敪
                      , iv_message  => lv_errbuf         --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ROLLBACK;
      END IF;
    --�����̊m��
    COMMIT;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --�G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode     --���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg      --���[�U�[�E�G���[�E���b�Z�[�W
      , in_file_id => gn_file_id     --�t�@�C��ID
      );
      --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK
      IF ( lv_retcode = cv_status_error ) THEN
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_errmsg         --���b�Z�[�W
                      , in_new_line => 1                 --���s
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      --�o�͋敪
                      , iv_message  => lv_errbuf         --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ROLLBACK;
      END IF;
    --�����̊m��
    COMMIT;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --�G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode     --���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg      --���[�U�[�E�G���[�E���b�Z�[�W
      , in_file_id => gn_file_id     --�t�@�C��ID
      );
      --�G���[��IF�f�[�^�폜�����p�G���[�o�͂�ROLLBACK
      IF ( lv_retcode = cv_status_error ) THEN
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_errmsg         --���b�Z�[�W
                      , in_new_line => 1                 --���s
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      --�o�͋敪
                      , iv_message  => lv_errbuf         --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ROLLBACK;
      END IF;
    --�����̊m��
    COMMIT;
  END main;
END XXCOK008A04C;
/