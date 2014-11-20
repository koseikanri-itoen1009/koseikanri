CREATE OR REPLACE PACKAGE BODY XXCOK021A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A01C(body)
 * Description      : �≮�̔�����������Excel�A�b�v���[�h
 * MD.050           : �≮�̔�����������Excel�A�b�v���[�h MD050_COK_021_A01
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  init                         ��������(A-1)
 *  get_file_data                �t�@�C���f�[�^�擾(A-2)
 *  get_tmp_wholesale_bill       �ꎞ�\�f�[�^�擾(A-3)
 *  chk_data                     �Ó����`�F�b�N(A-4)
 *  chk_wholesale_bill_data      �≮�������e�[�u���f�[�^�`�F�b�N(A-5)
 *  del_wholesale_bill_details   ���׃f�[�^�폜(A-6)
 *  ins_wholesale_bill_tbl       �≮�������e�[�u���f�[�^�o�^(A-7)
 *  del_mrp_file_ul_interface    �����f�[�^�폜(A-8)
 *  del_interface_at_error       �G���[��IF�f�[�^�폜(A-10)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/11    1.0   S.Sasaki         �V�K�쐬
 *  2009/02/02    1.1   S.Sasaki         [��QCOK_005]�擾�����ǉ��A�G���[��IF�f�[�^�폜�����ǉ�
 *  2009/03/10    1.2   K.Yamaguchi      [��QT1_0009]�≮���������׃e�[�u���폜�����ύX
 *  2009/04/10    1.3   M.Hiruta         [��QT1_0400]���l�`�F�b�N�Ń}�C�i�X�l���`�F�b�N�ł���悤�ύX
 *                                       [��QT1_0493]�Ó����`�F�b�N��NULL�`�F�b�N���ɐ��m�ȍ��ڂ��Q�Ƃ���悤�C��
 *  2009/08/27    1.4   T.Taniguchi      [��Q0001176]�≮���������׃e�[�u���폜�����ǉ�
 *  2009/09/30    1.5   S.Moriyama       [��Q0001392]E_T3_00592�Ή��F�������ʁA�����P����0�ȊO���ݒ肳��Ă���ꍇ��
 *                                                                    �������z�̕K�{�`�F�b�N���s���悤�C��
 *                                                                    ����Ȗڎx�����Ɏx�����ʂ�1�ȊO�̏ꍇ�G���[�Ƃ���
 *  2009/12/18    1.6   K.Yamaguchi      [E_�{�ғ�_00539] �Ó����`�F�b�N�ǉ�
 *  2009/12/24    1.7   K.Nakamura       [E_�{�ғ�_00554] �≮�������e�[�u���f�[�^�`�F�b�N�����A���׃f�[�^�폜�����ɏ����ǉ�
 *  2009/12/25    1.8   K.Nakamura       [E_�{�ғ�_00608] �����P���A�x���P���`�F�b�N�C��
 *
 *****************************************************************************************/
--
  -- =============================================================================
  -- �O���[�o���萔
  -- =============================================================================
  --�p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20) := 'XXCOK021A01C';
  --�A�v���P�[�V�����Z�k��
  cv_xxcok_appl_name         CONSTANT VARCHAR2(10) := 'XXCOK';
  cv_xxccp_appl_name         CONSTANT VARCHAR2(10) := 'XXCCP';
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn             CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  cv_status_continue         CONSTANT VARCHAR2(1)  := '9';                                --�p���G���[
  --���b�Z�[�W����
  cv_err_msg_00062           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00062';   --IF�\�폜�G���[
  cv_err_msg_10093           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10093';   --���׃e�[�u�����b�N�擾�G���[
  cv_err_msg_10094           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10094';   --���׃e�[�u���f�[�^�폜�G���[
  cv_err_msg_10092           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10092';   --�����f�[�^�X�e�[�^�X�G���[
  cv_err_msg_10161           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10161';   --�K�{�`�F�b�N�G���[
  cv_err_msg_10140           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10140';   --�������ʔ��p�����`�F�b�N�G���[
  cv_err_msg_10141           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10141';   --�����P�����p�����`�F�b�N�G���[
  cv_err_msg_10142           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10142';   --�������z���p�����`�F�b�N�G���[
  cv_err_msg_10143           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10143';   --�x�����ʔ��p�����`�F�b�N�G���[
  cv_err_msg_10144           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10144';   --�x���P�����p�����`�F�b�N�G���[
  cv_err_msg_10145           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10145';   --�x�����z���p�����`�F�b�N�G���[
  cv_err_msg_10153           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10153';   --�x���\������t�`�F�b�N�G���[
  cv_err_msg_10152           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10152';   --����Ώ۔N�����t�`�F�b�N�G���[
  cv_err_msg_10147           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10147';   --������No�����`�F�b�N�G���[
  cv_err_msg_10148           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10148';   --�������ʌ����`�F�b�N�G���[
  cv_err_msg_10149           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10149';   --�����P�������`�F�b�N�G���[
  cv_err_msg_10150           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10150';   --�������z�����`�F�b�N�G���[
  cv_err_msg_10151           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10151';   --�����P�ʌ����`�F�b�N�G���[
  cv_err_msg_10154           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10154';   --�x�����ʌ����`�F�b�N�G���[
  cv_err_msg_10155           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10155';   --�x���P�������`�F�b�N�G���[
  cv_err_msg_10156           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10156';   --�x�����z�����`�F�b�N�G���[
  cv_err_msg_10162           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10162';   --�d����R�[�h�`�F�b�N�G���[
  cv_err_msg_10163           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10163';   --���_�R�[�h�`�F�b�N�G���[
  cv_err_msg_10382           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10382';   --���_�R�[�h�`�F�b�N�G���[(���_������)
  cv_err_msg_10164           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10164';   --�ڋq�R�[�h�`�F�b�N�G���[
  cv_err_msg_10165           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10165';   --�≮������R�[�h�`�F�b�N�G���[
  cv_err_msg_10166           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10166';   --�i�ڃR�[�h�`�F�b�N�G���[
  cv_err_msg_10167           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10167';   --����ȖڃR�[�h�`�F�b�N�G���[
  cv_err_msg_10168           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10168';   --�⏕�ȖڃR�[�h�`�F�b�N�G���[
  cv_err_msg_10169           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10169';   --�x���\����`�F�b�N�G���[
-- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama ADD START
  cv_err_msg_10464           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10464';   --�������z�����K�{���b�Z�[�W�[
  cv_err_msg_10465           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10465';   --�����A�x�����ʃ`�F�b�N�G���[
-- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama ADD END
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
  cv_err_msg_10466           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10466';   --�i�ڂ܂��͊���ȖڕK�{
  cv_err_msg_10467           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10467';   --����Ȗڎx�����A����ȖځE�⏕�ȖڕK�{
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD START
  cv_err_msg_10470           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10470';   --����Ȗڎx�����A�����P���`�F�b�N�G���[
  cv_err_msg_10471           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10471';   --����Ȗڎx�����A�����P���`�F�b�N�G���[
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD END
  cv_err_msg_00061           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00061';   --IF�\���b�N�擾�G���[
  cv_err_msg_00041           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00041';   --BLOB�f�[�^�ϊ��G���[
  cv_err_msg_00039           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00039';   --��t�@�C���G���[
  cv_err_msg_00003           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00003';   --�v���t�@�C���擾�G���[
  cv_err_msg_00030           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00030';   --��������擾�G���[
  cv_err_msg_00028           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00028';   --�Ɩ����t�擾�G���[���b�Z�[�W
  cv_message_00016           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00016';   --���̓p�����[�^(�t�@�C��ID)
  cv_message_00017           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00017';   --���̓p�����[�^(�t�H�[�}�b�g�p�^�[��)
  cv_message_00006           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00006';   --�t�@�C�������b�Z�[�W�o��
  cv_message_10385           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10385';   --�x�����ʁE�x���P���E�x�����z�`�F�b�N
  cv_message_10388           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10388';   --���_�R�[�h�X�e�[�^�X�G���[
  cv_message_10389           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10389';   --�ڋq�R�[�h�X�e�[�^�X�G���[
  cv_message_90000           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90000';   --�Ώی������b�Z�[�W
  cv_message_90001           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90001';   --�����������b�Z�[�W
  cv_message_90002           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90002';   --�G���[�������b�Z�[�W
  cv_message_90004           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90004';   --����I�����b�Z�[�W
  cv_message_90006           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90006';   --�G���[�I���S���[���o�b�N���b�Z�[�W
  --�v���t�@�C��
  cv_dept_code_p             CONSTANT VARCHAR2(100) := 'XXCOK1_AFF2_DEPT_ACT';   --�Ɩ��Ǘ����̕���R�[�h
  cv_org_id_p                CONSTANT VARCHAR2(100) := 'ORG_ID';                 --�c�ƒP��ID
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
  cv_organization_code       CONSTANT VARCHAR2(100) := 'XXCOK1_ORG_CODE_SALES';  --�݌ɑg�D
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
  --�g�[�N��
  cv_token_file_id           CONSTANT VARCHAR2(10)  := 'FILE_ID';         --�g�[�N����(FILE_ID)
  cv_token_format            CONSTANT VARCHAR2(10)  := 'FORMAT';          --�g�[�N����(FORMAT)
  cv_token_user_id           CONSTANT VARCHAR2(10)  := 'USER_ID';         --�g�[�N����(USER_ID)
  cv_token_file_name         CONSTANT VARCHAR2(10)  := 'FILE_NAME';       --�g�[�N����(FILE_NAME)
  cv_token_customer_code     CONSTANT VARCHAR2(15)  := 'CUSTOMER_CODE';   --�g�[�N����(CUSTOMER_CODE)
  cv_token_invoice_no        CONSTANT VARCHAR2(10)  := 'INVOICE_NO';      --�g�[�N����(INVOICE_NO)
  cv_token_row_num           CONSTANT VARCHAR2(10)  := 'ROW_NUM';         --�g�[�N����(ROW_NUM)
  cv_token_vendor_code       CONSTANT VARCHAR2(15)  := 'VENDOR_CODE';     --�g�[�N����(VENDOR_CODE)
  cv_token_kyoten_code       CONSTANT VARCHAR2(15)  := 'KYOTEN_CODE';     --�g�[�N����(KYOTEN_CODE)
  cv_token_tonya_code        CONSTANT VARCHAR2(10)  := 'TONYA_CODE';      --�g�[�N����(TONYA_CODE)
  cv_token_item_code         CONSTANT VARCHAR2(10)  := 'ITEM_CODE';       --�g�[�N����(ITEM_CODE)
  cv_token_account_code      CONSTANT VARCHAR2(15)  := 'ACCOUNT_CODE';    --�g�[�N����(ACCOUNT_CODE)
  cv_token_sub_code          CONSTANT VARCHAR2(10)  := 'SUB_CODE';        --�g�[�N����(SUB_CODE)
  cv_token_payment_date      CONSTANT VARCHAR2(15)  := 'PAYMENT_DATE';    --�g�[�N����(PAYMENT_DATE)
  cv_token_profile           CONSTANT VARCHAR2(10)  := 'PROFILE';         --�g�[�N����(PROFILE)
  cv_token_emp               CONSTANT VARCHAR2(10)  := 'EMP_CODE';        --�g�[�N����(EMP_CODE)
  cv_token_count             CONSTANT VARCHAR2(5)   := 'COUNT';           --�g�[�N����(COUNT)
  --�t�H�[�}�b�g
  cv_date_format1            CONSTANT VARCHAR2(10)  := 'FXYYYYMMDD';   --�x���\����̃t�H�[�}�b�g
  cv_date_format2            CONSTANT VARCHAR2(8)   := 'FXYYYYMM';     --����Ώ۔N���̃t�H�[�}�b�g
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD START
  cv_number_format1          CONSTANT VARCHAR2(7)   := '9999999';      --����Ȗڎx�����̒P���t�H�[�}�b�g
  cv_number_format2          CONSTANT VARCHAR2(10)  := '9999999.99';   --����Ȗڎx�����ȊO�̒P���t�H�[�}�b�g
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD END
  --�L��
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';   --�R����
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';     --�s���I�h
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';     --�J���}
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
  cv_minus                   CONSTANT VARCHAR2(1)   := '-';     --�}�C�i�X
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
  --������
  cv_revise_flag             CONSTANT VARCHAR2(1)   := '0';    --�Ɗǒ����t���O(0:������)
  cv_base_code               CONSTANT VARCHAR2(1)   := '1';    --�ڋq�敪(���_�R�[�h)
  cv_sales_wholesale         CONSTANT VARCHAR2(2)   := '12';   --�����≮
  cv_sales_outlets           CONSTANT VARCHAR2(2)   := '16';   --�≮������
  cv_status_a                CONSTANT VARCHAR2(1)   := 'A';    --A:�m���
  cv_status_i                CONSTANT VARCHAR2(1)   := 'I';    --I:�Ɗǒ���
  cv_status_p                CONSTANT VARCHAR2(1)   := 'P';    --P:�x����
  cv_cust_status_80          CONSTANT VARCHAR2(2)   := '80';   --80:�X����
  cv_cust_status_90          CONSTANT VARCHAR2(2)   := '90';   --90:���~���ٍ�
  --���l
  cn_0                       CONSTANT NUMBER        := 0;      --���l:0
  cn_1                       CONSTANT NUMBER        := 1;      --���l:1
  cn_2                       CONSTANT NUMBER        := 2;      --���l:2
  cn_9                       CONSTANT NUMBER        := 9;      --���l:9
  cn_10                      CONSTANT NUMBER        := 10;     --���l:10
  --WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;           --CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;           --LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;   --PROGRAM_ID
  -- =============================================================================
  -- �O���[�o���ϐ�
  -- =============================================================================
  gn_target_cnt     NUMBER        DEFAULT 0;                  --�Ώی���
  gn_normal_cnt     NUMBER        DEFAULT 0;                  --��������
  gn_error_cnt      NUMBER        DEFAULT 0;                  --�G���[����
  gv_user_dept_code VARCHAR2(100) DEFAULT NULL;               --���[�U�S�����_(A-1,A-4)
  gv_dept_code      VARCHAR2(100) DEFAULT NULL;               --�J�X�^����v���t�@�C���擾�ϐ�
  gn_org_id         NUMBER;                                   --�v���t�@�C��(�c�ƒP��)
  gd_prdate         DATE;                                     --�Ɩ����t
  gv_chk_code       VARCHAR2(1)   DEFAULT cv_status_normal;   --�Ó����`�F�b�N�̏������ʃX�e�[�^�X
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
  gv_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  --�݌ɑg�D
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
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
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  /**********************************************************************************
   * Procedure Name   : del_interface_at_error
   * Description      : �G���[��IF�f�[�^�폜(A-10)
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
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
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
                  , iv_name         => cv_err_msg_00062
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => TO_CHAR( in_file_id )
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
    -- *** ���b�N���s ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_interface_at_error;
--
  /**********************************************************************************
   * Procedure Name   : del_mrp_file_ul_interface
   * Description      : �����f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE del_mrp_file_ul_interface(
    ov_errbuf   OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)     --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'del_mrp_file_ul_interface';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg     VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lb_retcode BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- �t�@�C���A�b�v���[�hIF�\�̍폜����
    -- =============================================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id;
      COMMIT;
    EXCEPTION
      -- *** �폜�����Ɏ��s ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_00062
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => TO_CHAR( in_file_id )
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_mrp_file_ul_interface;
--
  /**********************************************************************************
   * Procedure Name   : ins_wholesale_bill_tbl
   * Description      : �≮�������e�[�u���f�[�^�o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_wholesale_bill_tbl(
    ov_errbuf               OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode              OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg               OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , iv_supplier_code        IN  VARCHAR2    --�d����R�[�h
  , iv_expect_payment_date  IN  VARCHAR2    --�x���\���
  , iv_selling_month        IN  VARCHAR2    --����Ώ۔N��
  , iv_base_code            IN  VARCHAR2    --���_�R�[�h
  , iv_bill_no              IN  VARCHAR2    --������No.
  , iv_cust_code            IN  VARCHAR2    --�ڋq�R�[�h
  , iv_sales_outlets_code   IN  VARCHAR2    --�≮������R�[�h
  , iv_item_code            IN  VARCHAR2    --�i�ڃR�[�h
  , iv_acct_code            IN  VARCHAR2    --����ȖڃR�[�h
  , iv_sub_acct_code        IN  VARCHAR2    --�⏕�ȖڃR�[�h
  , iv_demand_unit_type     IN  VARCHAR2    --�����P��
  , iv_demand_qty           IN  VARCHAR2    --��������
  , iv_demand_unit_price    IN  VARCHAR2    --�����P��(�Ŕ�)
  , iv_demand_amt           IN  VARCHAR2    --�������z(�Ŕ�)
  , iv_payment_qty          IN  VARCHAR2    --�x������
  , iv_payment_unit_price   IN  VARCHAR2    --�x���P��(�Ŕ�)
  , iv_payment_amt          IN  VARCHAR2)   --�x�����z(�Ŕ�)
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'ins_wholesale_bill_tbl';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                       VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lb_retcode                   BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
    ln_wholesale_bill_header_id  NUMBER;                                    --�≮�������w�b�_�[ID
    ln_wholesale_bill_detail_id  NUMBER;                                    --�≮����������ID
    ln_payment_qty               NUMBER;                                    --�x������
    ln_payment_unit_price        NUMBER;                                    --�x���P��
    ln_payment_amt               NUMBER;                                    --�x�����z
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.�≮�������w�b�_�[�e�[�u���ɁA���ɑΏۂƂȂ�w�b�_�[�����݂��邩�`�F�b�N
    -- =============================================================================
    BEGIN
      SELECT xwbh.wholesale_bill_header_id AS wholesale_bill_header_id
      INTO   ln_wholesale_bill_header_id
      FROM   xxcok_wholesale_bill_head xwbh
      WHERE  xwbh.base_code           = iv_base_code
      AND    xwbh.cust_code           = iv_cust_code
      AND    xwbh.supplier_code       = iv_supplier_code
      AND    xwbh.expect_payment_date = TO_DATE( iv_expect_payment_date, cv_date_format1 );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- =============================================================================
      -- �≮�������w�b�_�[ID���V�[�P���X���擾
      -- =============================================================================
      SELECT xxcok_wholesale_bill_head_s01.NEXTVAL AS xxcok_wholesale_bill_head_s01
      INTO   ln_wholesale_bill_header_id
      FROM   DUAL;
      -- =============================================================================
      -- 2.�≮�������w�b�_�[�e�[�u���փ��R�[�h�̒ǉ�
      -- =============================================================================
      INSERT INTO xxcok_wholesale_bill_head(
        wholesale_bill_header_id                             --�≮�������w�b�_�[ID
      , base_code                                            --���_�R�[�h
      , cust_code                                            --�ڋq�R�[�h
      , supplier_code                                        --�d����R�[�h
      , expect_payment_date                                  --�x���\���
      , created_by                                           --�쐬��
      , creation_date                                        --�쐬��
      , last_updated_by                                      --�ŏI�X�V��
      , last_update_date                                     --�ŏI�X�V��
      , last_update_login                                    --�ŏI�X�V���O�C��
      , request_id                                           --�v��ID
      , program_application_id                               --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                                           --�R���J�����g�E�v���O����ID
      , program_update_date                                  --�v���O�����X�V��
      ) VALUES (
        ln_wholesale_bill_header_id                          --wholesale_bill_header_id
      , iv_base_code                                         --base_code
      , iv_cust_code                                         --cust_code
      , iv_supplier_code                                     --supplier_code
      , TO_DATE( iv_expect_payment_date, cv_date_format1 )   --expect_payment_date
      , cn_created_by                                        --created_by
      , SYSDATE                                              --creation_date
      , cn_last_updated_by                                   --last_updated_by
      , SYSDATE                                              --last_update_date
      , cn_last_update_login                                 --last_update_login
      , cn_request_id                                        --request_id
      , cn_program_application_id                            --program_application_id
      , cn_program_id                                        --program_id
      , SYSDATE                                              --program_update_date
      );
    END;
    -- =============================================================================
    -- �x�����ʁA�x���P���A�x�����z�����ׂ�'NULL'�̏ꍇ�AA-3�Ŏ擾����
    -- �������ʁA�����P��(�Ŕ�)�A�������z(�Ŕ�)��ݒ�
    -- =============================================================================
    IF (    ( iv_payment_qty        IS NULL )
        AND ( iv_payment_unit_price IS NULL )
        AND ( iv_payment_amt        IS NULL )
       ) THEN
      ln_payment_qty        := TO_NUMBER( iv_demand_qty );
      ln_payment_unit_price := TO_NUMBER( iv_demand_unit_price );
      ln_payment_amt        := TO_NUMBER( iv_demand_amt );
    ELSE
      ln_payment_qty        := TO_NUMBER( iv_payment_qty );
      ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price );
      ln_payment_amt        := TO_NUMBER( iv_payment_amt );
    END IF;
    -- =============================================================================
    -- �≮����������ID���V�[�P���X���擾
    -- =============================================================================
    SELECT xxcok_wholesale_bill_line_s01.NEXTVAL AS xxcok_wholesale_bill_line_s01
    INTO   ln_wholesale_bill_detail_id
    FROM   DUAL;
    -- =============================================================================
    -- 3.�≮���������׃e�[�u���փ��R�[�h�̒ǉ�
    -- =============================================================================
    INSERT INTO xxcok_wholesale_bill_line(
      wholesale_bill_detail_id            --�≮����������ID
    , wholesale_bill_header_id            --�≮�������w�b�_�[ID
    , bill_no                             --������No
    , sales_outlets_code                  --�≮������R�[�h
    , item_code                           --�i�ڃR�[�h
    , demand_qty                          --��������
    , demand_unit_price                   --�����P��
    , demand_amt                          --�������z
    , selling_month                       --����Ώ۔N��
    , demand_unit_type                    --�����P��
    , acct_code                           --����ȖڃR�[�h
    , sub_acct_code                       --�⏕�ȖڃR�[�h
    , payment_qty                         --�x������
    , payment_unit_type                   --�x���P��
    , payment_unit_price                  --�x���P��
    , payment_amt                         --�x�����z
    , status                              --�X�e�[�^�X
    , revise_flag                         --�Ɗǒ����t���O
    , payment_creation_date               --�x���f�[�^�쐬�N����
    , created_by                          --�쐬��
    , creation_date                       --�쐬��
    , last_updated_by                     --�ŏI�X�V��
    , last_update_date                    --�ŏI�X�V��
    , last_update_login                   --�ŏI�X�V���O�C��
    , request_id                          --�v��ID
    , program_application_id              --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                          --�R���J�����g�E�v���O����ID
    , program_update_date                 --�v���O�����X�V��
    ) VALUES (
      ln_wholesale_bill_detail_id         --wholesale_bill_detail_id
    , ln_wholesale_bill_header_id         --wholesale_bill_header_id
    , iv_bill_no                          --bill_no
    , iv_sales_outlets_code               --sales_outlets_code
    , iv_item_code                        --item_code
    , TO_NUMBER( iv_demand_qty )          --demand_qty
    , TO_NUMBER( iv_demand_unit_price )   --demand_unit_price
    , TO_NUMBER( iv_demand_amt )          --demand_amt
    , iv_selling_month                    --selling_month
    , iv_demand_unit_type                 --demand_unit_type
    , iv_acct_code                        --acct_code
    , iv_sub_acct_code                    --sub_acct_code
    , ln_payment_qty                      --payment_qty
    , iv_demand_unit_type                 --payment_unit_type
    , ln_payment_unit_price               --payment_unit_price
    , ln_payment_amt                      --payment_amt
    , NULL                                --status
    , cv_revise_flag                      --revise_flag
    , NULL                                --payment_creation_date
    , cn_created_by                       --created_by
    , SYSDATE                             --creation_date
    , cn_last_updated_by                  --last_updated_by
    , SYSDATE                             --last_update_date
    , cn_last_update_login                --last_update_login
    , cn_request_id                       --request_id
    , cn_program_application_id           --program_application_id
    , cn_program_id                       --program_id
    , SYSDATE                             --program_update_date
    );
    -- *** ���������J�E���g ***
    gn_normal_cnt := gn_normal_cnt + 1;
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_wholesale_bill_tbl;
--
  /**********************************************************************************
   * Procedure Name   : del_wholesale_bill_details
   * Description      : ���׃f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_wholesale_bill_details(
    ov_errbuf               OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode              OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg               OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'del_wholesale_bill_details';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg      VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lb_retcode  BOOLEAN        DEFAULT NULL;               --���b�Z�[�W�o�̖͂߂�l
    lr_rowid    ROWID;                                     --ROWID
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
-- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama UPD START
--    CURSOR get_xwbl_lock_cur
--    IS
--      SELECT 'X'
--      FROM xxcok_wholesale_bill_line     xwbl
--      WHERE EXISTS ( SELECT 'X'
--                     FROM xxcok_wholesale_bill_head     xwbh
--                        , xxcok_tmp_wholesale_bill      xtwb
--                     WHERE xwbl.wholesale_bill_header_id = xwbh.wholesale_bill_header_id
--                       AND xtwb.cust_code                = xwbh.cust_code
--                       AND xtwb.expect_payment_date      = TO_CHAR( xwbh.expect_payment_date, cv_date_format1 )
--                       AND xtwb.bill_no                  = xwbl.bill_no
---- 2009/08/26 Ver.1.4 [��Q0001176] SCS T.Taniguchi START
--                       AND xwbl.status IS NULL
---- 2009/08/26 Ver.1.4 [��Q0001176] SCS T.Taniguchi END
--                   )
--      FOR UPDATE OF xwbl.wholesale_bill_detail_id NOWAIT
--    ;
    CURSOR get_xwbl_lock_cur
    IS
      SELECT 'X'
        FROM xxcok_wholesale_bill_line     xwbl
       WHERE xwbl.status IS NULL
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura MOD START
--         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n01) */
         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n02) */
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura MOD END
                             'X'
                        FROM xxcok_wholesale_bill_head     xwbh
                           , xxcok_tmp_wholesale_bill      xtwb
                       WHERE xwbh.cust_code                = xtwb.cust_code
                         AND xwbh.expect_payment_date      = TO_DATE( xtwb.expect_payment_date, cv_date_format1 )
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD START
                         AND xwbh.supplier_code            = xtwb.supplier_code
                         AND xwbh.base_code                = xtwb.base_code
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD END
                         AND xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id
                         AND xtwb.bill_no                  = xwbl.bill_no
                         AND ROWNUM = 1
                    )
      FOR UPDATE OF xwbl.wholesale_bill_detail_id NOWAIT
    ;
-- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama UPD END
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.�≮���������׃e�[�u���̃��b�N���擾
    -- =============================================================================
    OPEN  get_xwbl_lock_cur;
    CLOSE get_xwbl_lock_cur;
    -- =============================================================================
    -- 2.�≮���������׃e�[�u���̍폜����
    -- =============================================================================
    BEGIN
-- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama UPD START
--      DELETE
--      FROM xxcok_wholesale_bill_line     xwbl
--      WHERE EXISTS ( SELECT 'X'
--                     FROM xxcok_wholesale_bill_head     xwbh
--                        , xxcok_tmp_wholesale_bill      xtwb
--                     WHERE xwbl.wholesale_bill_header_id = xwbh.wholesale_bill_header_id
--                       AND xtwb.cust_code                = xwbh.cust_code
--                       AND xtwb.expect_payment_date      = TO_CHAR( xwbh.expect_payment_date, cv_date_format1 )
--                       AND xtwb.bill_no                  = xwbl.bill_no
---- 2009/08/26 Ver.1.4 [��Q0001176] SCS T.Taniguchi START
--                       AND xwbl.status IS NULL
---- 2009/08/26 Ver.1.4 [��Q0001176] SCS T.Taniguchi END
--                   )
--      ;
      DELETE FROM xxcok_wholesale_bill_line     xwbl
       WHERE xwbl.status IS NULL
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD START
--         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n01) */
         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n02) */
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD END
                             'X'
                        FROM xxcok_wholesale_bill_head     xwbh
                           , xxcok_tmp_wholesale_bill      xtwb
                       WHERE xwbh.cust_code                = xtwb.cust_code
                         AND xwbh.expect_payment_date      = TO_DATE( xtwb.expect_payment_date, cv_date_format1 )
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD START
                         AND xwbh.supplier_code            = xtwb.supplier_code
                         AND xwbh.base_code                = xtwb.base_code
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD END
                         AND xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id
                         AND xtwb.bill_no                  = xwbl.bill_no
                         AND ROWNUM = 1
                    )
      ;
-- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama UPD END
    EXCEPTION
      -- *** �폜�����Ɏ��s ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10094
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ���b�N���s ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10093
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
  END del_wholesale_bill_details;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �Ó����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf              OUT VARCHAR2    --�G���[�E���b�Z�[�W
  , ov_retcode             OUT VARCHAR2    --���^�[���E�R�[�h
  , ov_errmsg              OUT VARCHAR2    --���[�U�[�E�G���[�E���b�Z�[�W
  , in_loop_cnt            IN  NUMBER      --LOOP�J�E���^
  , iv_supplier_code       IN  VARCHAR2    --�d����R�[�h
  , iv_expect_payment_date IN  VARCHAR2    --�x���\���
  , iv_selling_month       IN  VARCHAR2    --����Ώ۔N��
  , iv_base_code           IN  VARCHAR2    --���_�R�[�h
  , iv_bill_no             IN  VARCHAR2    --������No.
  , iv_cust_code           IN  VARCHAR2    --�ڋq�R�[�h
  , iv_sales_outlets_code  IN  VARCHAR2    --�≮������R�[�h
  , iv_item_code           IN  VARCHAR2    --�i�ڃR�[�h
  , iv_acct_code           IN  VARCHAR2    --����ȖڃR�[�h
  , iv_sub_acct_code       IN  VARCHAR2    --�⏕�ȖڃR�[�h
  , iv_demand_unit_type    IN  VARCHAR2    --�����P��
  , iv_demand_qty          IN  VARCHAR2    --��������
  , iv_demand_unit_price   IN  VARCHAR2    --�����P��(�Ŕ�)
  , iv_demand_amt          IN  VARCHAR2    --�������z(�Ŕ�)
  , iv_payment_qty         IN  VARCHAR2    --�x������
  , iv_payment_unit_price  IN  VARCHAR2    --�x���P��(�Ŕ�)
  , iv_payment_amt         IN  VARCHAR2)   --�x�����z(�Ŕ�)
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_data';     --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                  VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lv_cust_status          VARCHAR2(2)    DEFAULT NULL;               --�ڋq�X�e�[�^�X
    lb_retcode              BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    lb_chk_number           BOOLEAN        DEFAULT TRUE;               --���p�����`�F�b�N�̌���
    ln_chk_number           NUMBER         DEFAULT NULL;               --���p�����`�F�b�N�p
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
    ld_expect_payment_date  DATE;                                      --�x���\���(���t�^�ϊ���)
    ld_selling_month        DATE;                                      --����Ώ۔N��(���t�^�ϊ���)
    ln_chr_length           NUMBER         DEFAULT 0;                  --�����`�F�b�N
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura MOD START
--    ln_demand_unit_price    NUMBER(8,2);                               --�����P��(�Ŕ�)
--    ln_payment_unit_price   NUMBER(8,2);                               --�x���P��(�Ŕ�)
    ln_demand_unit_price    xxcok_wholesale_bill_line.demand_unit_price%TYPE;                       --�����P��(�Ŕ�)
    ln_payment_unit_price   xxcok_wholesale_bill_line.payment_unit_price%TYPE;                      --�x���P��(�Ŕ�)
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura MOD END
    ln_count                NUMBER;                                    --COUNT
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
    ln_demand_qty           NUMBER;
    ln_demand_amt           NUMBER;
    ln_payment_qty          NUMBER;
    ln_payment_amt          NUMBER;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.�K�{���ڃ`�F�b�N
    -- =============================================================================
        
    IF (    ( iv_base_code          IS NULL )
         OR ( iv_cust_code          IS NULL )
         OR ( iv_supplier_code      IS NULL )
         OR ( iv_bill_no            IS NULL )
         OR ( iv_sales_outlets_code IS NULL )
         OR ( iv_demand_qty         IS NULL )
         OR ( iv_demand_unit_type   IS NULL )
         OR ( iv_demand_unit_price  IS NULL )
         OR ( iv_selling_month      IS NULL )
         OR ( iv_expect_payment_date IS NULL )
       ) THEN
      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10161
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi DELETE START
---- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama ADD START
--    ELSIF ( ( iv_demand_qty <> 0
--              OR iv_demand_unit_price <> 0
--            )
--           AND iv_demand_amt IS NULL
--          ) THEN
--      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10464
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    ELSIF ( iv_acct_code IS NOT NULL
--           AND ( ( iv_payment_qty != 1 AND iv_payment_qty IS NOT NULL )
--              OR iv_demand_qty != 1
--               )
--          ) THEN
--      -- *** ����Ȗڎx�����ɐ������ʂ������͎x�����ʂ�1�ȊO�̏ꍇ�A��O���� ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10465
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
---- 2009/09/30 Ver.1.5 [��QE_T3_00592] SCS S.Moriyama ADD END
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi DELETE END
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
    --==================================================
    -- �����K�{
    --==================================================
    -- �i�ڃR�[�h�܂��͊���Ȗڂǂ��炩�K�{
    IF(    (     ( iv_item_code     IS     NULL )
             AND ( iv_acct_code     IS     NULL )
             AND ( iv_sub_acct_code IS     NULL )
           )
        OR (     ( iv_item_code     IS NOT NULL )
             AND ( iv_acct_code     IS NOT NULL OR iv_sub_acct_code IS NOT NULL )
           )
    ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10466
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    ELSIF(     ( iv_item_code IS NULL )
           AND ( iv_acct_code IS NULL OR iv_sub_acct_code IS NULL )
    ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10467
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
    -- =============================================================================
    -- 2.�@�������ʂ̃f�[�^�^�`�F�b�N(���p�����`�F�b�N)
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
    lb_chk_number := xxccp_common_pkg.chk_number(
                       iv_check_char => iv_demand_qty
                     );

    IF ( lb_chk_number = FALSE ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10140
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
*/
    BEGIN
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR START
--      ln_chk_number := TO_NUMBER( iv_demand_qty );
      ln_demand_qty := TO_NUMBER( iv_demand_qty );
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR END
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10140
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
    END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    -- =============================================================================
    -- 2.�A�������z(�Ŕ�)�̃f�[�^�^�`�F�b�N(���p�����`�F�b�N)
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
    lb_chk_number := xxccp_common_pkg.chk_number(
                       iv_check_char => iv_demand_amt
                     );
--
    IF ( lb_chk_number = FALSE ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10142
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
*/
    BEGIN
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR START
--      ln_chk_number := TO_NUMBER( iv_demand_amt );
      ln_demand_amt := TO_NUMBER( iv_demand_amt );
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR END
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10142
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
    END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    -- =============================================================================
    -- 2.�B�x�����ʂ̃f�[�^�^�`�F�b�N(���p�����`�F�b�N)(�l��NULL�̏ꍇ�`�F�b�N�ΏۊO)
    -- =============================================================================
    IF ( iv_payment_qty IS NOT NULL ) THEN
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
      lb_chk_number := xxccp_common_pkg.chk_number(
                         iv_check_char => iv_payment_qty
                       );
--
      IF ( lb_chk_number = FALSE ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10143
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
*/
      BEGIN
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR START
--        ln_chk_number := TO_NUMBER( iv_payment_qty );
        ln_payment_qty := TO_NUMBER( iv_payment_qty );
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR END
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10143
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          ov_retcode := cv_status_continue;
      END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
    END IF;
--
    -- ====================================================================================
    -- 2.�C�x�����z(�Ŕ�)�̃f�[�^�^�`�F�b�N(���p�����`�F�b�N)(�l��NULL�̏ꍇ�`�F�b�N�ΏۊO)
    -- ====================================================================================
-- Start 2009/04/10 Ver_1.3 T1_0493 M.Hiruta
--    IF ( iv_payment_qty IS NOT NULL ) THEN
    IF ( iv_payment_amt IS NOT NULL ) THEN
-- End   2009/04/10 Ver_1.3 T1_0493 M.Hiruta
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
      lb_chk_number := xxccp_common_pkg.chk_number(
                         iv_check_char => iv_payment_amt
                       );
--
      IF ( lb_chk_number = FALSE ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10145
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
*/
      BEGIN
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR START
--        ln_chk_number := TO_NUMBER( iv_payment_amt );
        ln_payment_amt := TO_NUMBER( iv_payment_amt );
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR END
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10145
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          ov_retcode := cv_status_continue;
      END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
    END IF;
--
    -- =============================================================================
    -- �x���\����̓��t�^�ϊ��`�F�b�N
    -- =============================================================================
    BEGIN
      ld_expect_payment_date := TO_DATE( iv_expect_payment_date, cv_date_format1 );
    EXCEPTION
      -- *** �ϊ��ł��Ȃ������ꍇ�A��O���� ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10153
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
    END;
    -- =============================================================================
    -- ����Ώ۔N���̓��t�^�ϊ��`�F�b�N
    -- =============================================================================
    BEGIN
      ld_selling_month := TO_DATE( iv_selling_month, cv_date_format2 );
    EXCEPTION
      -- *** �ϊ��ł��Ȃ������ꍇ�A��O���� ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10152
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
    END;
    -- =============================================================================
    -- 3.�@������No�̌����`�F�b�N
    -- =============================================================================
    ln_chr_length := LENGTHB( iv_bill_no );
--
    IF ( ln_chr_length > cn_10 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10147
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.�A�������ʂ̌����`�F�b�N
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_demand_qty );
    ln_chr_length := LENGTHB( REPLACE( iv_demand_qty , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_9 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10148
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.�B�����P��(�Ŕ�)�̌����`�F�b�N
    -- =============================================================================
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD START
    IF ( iv_acct_code IS NOT NULL ) AND ( iv_sub_acct_code IS NOT NULL ) THEN
      BEGIN
        ln_demand_unit_price := TO_NUMBER( iv_demand_unit_price , cv_number_format1 );
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10470
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          ov_retcode := cv_status_continue;
      END;
    ELSE
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD END
      BEGIN
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Yamaguchi REPAIR START
--        ln_demand_unit_price := TO_NUMBER( iv_demand_unit_price );
        ln_demand_unit_price := TO_NUMBER( iv_demand_unit_price, cv_number_format2 );
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Yamaguchi REPAIR END
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10149
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          ov_retcode := cv_status_continue;
      END;
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD START
    END IF;
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD END
    -- =============================================================================
    -- 3.�C�������z(�Ŕ�)�̌����`�F�b�N
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_demand_amt );
    ln_chr_length := LENGTHB( REPLACE( iv_demand_amt , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_10 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10150
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.�D�����P�ʂ̌����`�F�b�N
    -- =============================================================================
    ln_chr_length := LENGTHB( iv_demand_unit_type );
--
    IF NOT ( ln_chr_length = cn_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10151
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.�E�x�����ʂ̌����`�F�b�N
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_payment_qty );
    ln_chr_length := LENGTHB( REPLACE( iv_payment_qty , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_9 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10154
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.�F�x���P��(�Ŕ�)�̌����`�F�b�N
    -- =============================================================================
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD START
    IF ( iv_acct_code IS NOT NULL ) AND ( iv_sub_acct_code IS NOT NULL ) THEN
      BEGIN
        ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price , cv_number_format1 );
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10471
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          ov_retcode := cv_status_continue;
      END;
    ELSE
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD END
      BEGIN
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Yamaguchi REPAIR START
--        ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price );
        ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price, cv_number_format2 );
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Yamaguchi REPAIR END
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10155
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --�o�͋敪
                        , iv_message  => lv_msg            --���b�Z�[�W
                        , in_new_line => 0                 --���s
                        );
          ov_retcode := cv_status_continue;
      END;
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD START
    END IF;
-- 2009/12/25 Ver.1.8 [E_�{�ғ�_00608] SCS K.Nakamura ADD END
    -- =============================================================================
    -- 3.�G�x�����z(�Ŕ�)�̌����`�F�b�N
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_payment_amt );
    ln_chr_length := LENGTHB( REPLACE( iv_payment_amt , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_10 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10156
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 4.�d����R�[�h���d����}�X�^�ɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    SELECT  COUNT('X') AS cnt
    INTO    ln_count
    FROM    po_vendors          pv     --�d����}�X�^
          , po_vendor_sites_all pvsa   --�d����T�C�g�}�X�^
    WHERE   pv.segment1  = iv_supplier_code
    AND     pv.vendor_id = pvsa.vendor_id
    AND     (   ( pv.end_date_active > gd_prdate )
             OR ( pv.end_date_active IS NULL     )
            )
    AND     (   ( pvsa.inactive_date > gd_prdate )
             OR ( pvsa.inactive_date IS NULL     )
            )
    AND     pvsa.org_id  = gn_org_id
    AND     ROWNUM       = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10162
                , iv_token_name1  => cv_token_vendor_code
                , iv_token_value1 => iv_supplier_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 5.���_�R�[�h���ڋq�}�X�^�ɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    SELECT  COUNT('X') AS cnt
    INTO    ln_count
    FROM    hz_cust_accounts hca
    WHERE   hca.account_number      = iv_base_code
    AND     hca.customer_class_code = cv_base_code
    AND     ROWNUM                  = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10163
                , iv_token_name1  => cv_token_kyoten_code
                , iv_token_value1 => iv_base_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    ELSE
      IF (    ( gv_dept_code      <> gv_user_dept_code )
          AND ( gv_user_dept_code <> iv_base_code )
         ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10382
                  , iv_token_name1  => cv_token_kyoten_code
                  , iv_token_value1 => iv_base_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
      -- =============================================================================
      -- �ڋq�X�e�[�^�X���擾���A�u90(���~���ٍ�)�v�̏ꍇ�G���[
      -- =============================================================================
      SELECT hp.duns_number_c
      INTO   lv_cust_status
      FROM   hz_cust_accounts hca
           , hz_parties hp
      WHERE  hca.party_id            = hp.party_id
      AND    hca.account_number      = iv_base_code
      AND    hca.customer_class_code = cv_base_code
      AND    ROWNUM                  = cn_1;
      IF ( lv_cust_status = cv_cust_status_90 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10388
                  , iv_token_name1  => cv_token_kyoten_code
                  , iv_token_value1 => iv_base_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi DELETE START
--    -- =============================================================================
--    -- �ڋq�X�e�[�^�X���擾���A�u90(���~���ٍ�)�v�̏ꍇ�G���[
--    -- =============================================================================
--    SELECT hp.duns_number_c
--    INTO   lv_cust_status
--    FROM   hz_cust_accounts hca
--         , hz_parties hp
--    WHERE  hca.party_id            = hp.party_id
--    AND    hca.account_number      = iv_base_code
--    AND    hca.customer_class_code = cv_base_code
--    AND    ROWNUM                  = cn_1;
----
--    IF ( lv_cust_status = cv_cust_status_90 ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_message_10388
--                , iv_token_name1  => cv_token_kyoten_code
--                , iv_token_value1 => iv_base_code
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi DELETE END
    -- =============================================================================
    -- 6.�ڋq�R�[�h���ڋq�}�X�^�ɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   hz_cust_accounts hca
         , xxcmm_cust_accounts xca
    WHERE  hca.cust_account_id   = xca.customer_id
    AND    hca.account_number    = iv_cust_code
    AND    xca.business_low_type = cv_sales_wholesale
    AND    ROWNUM                = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10164
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => iv_cust_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
    ELSE
      -- =============================================================================
      -- �ڋq�X�e�[�^�X���擾���A�u80(�X����)�v�܂��́u90(���~���ٍ�)�v�̏ꍇ�G���[
      -- =============================================================================
      SELECT hp.duns_number_c
      INTO   lv_cust_status
      FROM   hz_cust_accounts hca
           , hz_parties hp
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id   = xca.customer_id
      AND    hca.party_id          = hp.party_id
      AND    hca.account_number    = iv_cust_code
      AND    xca.business_low_type = cv_sales_wholesale
      AND    ROWNUM                = cn_1;
      IF (   ( lv_cust_status = cv_cust_status_80 )
          OR ( lv_cust_status = cv_cust_status_90 )
          ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10389
                  , iv_token_name1  => cv_token_customer_code
                  , iv_token_value1 => iv_cust_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi DELETE START
--    -- =============================================================================
--    -- �ڋq�X�e�[�^�X���擾���A�u80(�X����)�v�܂��́u90(���~���ٍ�)�v�̏ꍇ�G���[
--    -- =============================================================================
--    SELECT hp.duns_number_c
--    INTO   lv_cust_status
--    FROM   hz_cust_accounts hca
--         , hz_parties hp
--         , xxcmm_cust_accounts xca
--    WHERE  hca.cust_account_id   = xca.customer_id
--    AND    hca.party_id          = hp.party_id
--    AND    hca.account_number    = iv_cust_code
--    AND    xca.business_low_type = cv_sales_wholesale
--    AND    ROWNUM                = cn_1;
----
--    IF (   ( lv_cust_status = cv_cust_status_80 )
--        OR ( lv_cust_status = cv_cust_status_90 )
--        ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_message_10389
--                , iv_token_name1  => cv_token_customer_code
--                , iv_token_value1 => iv_cust_code
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
--                    , iv_message  => lv_msg            --���b�Z�[�W
--                    , in_new_line => 0                 --���s
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi DELETE END
    -- =============================================================================
    -- 7.�≮������R�[�h���ڋq�}�X�^�ɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   hz_cust_accounts hca
    WHERE  hca.account_number      = iv_sales_outlets_code
    AND    hca.customer_class_code = cv_sales_outlets
    AND    ROWNUM                  = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10165
                , iv_token_name1  => cv_token_tonya_code
                , iv_token_value1 => iv_sales_outlets_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 8.�i�ڃR�[�h��NULL�ȊO�̏ꍇ�A�i�ڃ}�X�^�ɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    IF ( iv_item_code IS NOT NULL ) THEN
      SELECT COUNT('X') AS cnt
      INTO   ln_count
      FROM   mtl_system_items_b mti
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
           , mtl_parameters     mp
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
      WHERE  mti.segment1 = iv_item_code
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
      AND    mti.organization_id  = mp.organization_id
      AND    mp.organization_code = gv_organization_code
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
      AND    ROWNUM       = cn_1;
--
      IF ( ln_count = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10166
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => iv_item_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
    END IF;
    -- =============================================================================
    -- 9.����ȖڃR�[�h��NULL�ȊO�̏ꍇ�AAFF����Ȗڂɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    IF ( iv_acct_code IS NOT NULL ) THEN
      SELECT COUNT('X') AS cnt
      INTO   ln_count
      FROM   xx03_accounts_v xav
      WHERE  xav.flex_value = iv_acct_code
      AND    ROWNUM         = cn_1;
--
      IF ( ln_count = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10167
                  , iv_token_name1  => cv_token_account_code
                  , iv_token_value1 => iv_acct_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
    END IF;
    -- =============================================================================
    -- 10.�⏕�ȖڃR�[�h��NULL�ȊO�̏ꍇ�AAFF�⏕�Ȗڂɑ��݂��邱�Ƃ��`�F�b�N
    -- =============================================================================
    IF ( iv_sub_acct_code IS NOT NULL ) THEN
      SELECT COUNT('X') AS cnt
      INTO   ln_count
      FROM   xx03_sub_accounts_v xsav
      WHERE  xsav.flex_value             = iv_sub_acct_code
      AND    xsav.parent_flex_value_low  = iv_acct_code
      AND    ROWNUM = cn_1;
--
      IF ( ln_count = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10168
                  , iv_token_name1  => cv_token_sub_code
                  , iv_token_value1 => iv_sub_acct_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --�o�͋敪
                      , iv_message  => lv_msg            --���b�Z�[�W
                      , in_new_line => 0                 --���s
                      );
        ov_retcode := cv_status_continue;
      END IF;
    END IF;
    -- =============================================================================
    -- 11.�x���\���������ڋq�A���ꐿ����No.���œ������t�ł��邱�Ƃ��`�F�b�N
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   xxcok_tmp_wholesale_bill xtwb
    WHERE  xtwb.cust_code           =  iv_cust_code
    AND    xtwb.bill_no             =  iv_bill_no
    AND    xtwb.expect_payment_date <> iv_expect_payment_date
    AND    ROWNUM                   =  cn_1;
--
    IF ( ln_count = cn_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10169
                , iv_token_name1  => cv_token_payment_date
                , iv_token_value1 => iv_expect_payment_date
                , iv_token_name2  => cv_token_customer_code
                , iv_token_value2 => iv_cust_code
                , iv_token_name3  => cv_token_invoice_no
                , iv_token_value3 => iv_bill_no
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 12.�x�����ʁE�x���P���E�x�����z�̃`�F�b�N
    -- =============================================================================
    IF NOT ( (    ( iv_payment_qty        IS NOT NULL )
              AND ( iv_payment_unit_price IS NOT NULL )
              AND ( iv_payment_amt        IS NOT NULL )
             )
           OR 
             (    ( iv_payment_qty        IS NULL )
              AND ( iv_payment_unit_price IS NULL )
              AND ( iv_payment_amt        IS NULL )
             )
           ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10385
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
    IF (     ( ln_demand_qty <> 0 OR ln_demand_unit_price <> 0 )
         AND ( ln_demand_amt IS NULL )
    ) THEN
      -- *** ���ڂ�NULL�̏ꍇ�A��O���� ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10464
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    ELSIF ( iv_acct_code IS NOT NULL
           AND ( ( ln_payment_qty != 1 AND ln_payment_qty IS NOT NULL )
              OR ln_demand_qty != 1
               )
    ) THEN
      -- *** ����Ȗڎx�����ɐ������ʂ������͎x�����ʂ�1�ȊO�̏ꍇ�A��O���� ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10465
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
    -- =============================================================================
    -- �≮�������e�[�u���f�[�^�`�F�b�N(A-5)
    -- �≮�������w�b�_�[�e�[�u���A�≮���������׃e�[�u���̊����f�[�^�`�F�b�N���s��
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   xxcok_wholesale_bill_head xwbh
         , xxcok_wholesale_bill_line xwbl
    WHERE  xwbh.cust_code                = iv_cust_code
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR START
--    AND    xwbh.expect_payment_date      = TO_DATE( iv_expect_payment_date, cv_date_format1 )
    AND    xwbh.expect_payment_date      = ld_expect_payment_date
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi REPAIR END
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD START
    AND    xwbh.supplier_code            = iv_supplier_code
    AND    xwbh.base_code                = iv_base_code
-- 2009/12/24 Ver.1.7 [E_�{�ғ�_00554] SCS K.Nakamura ADD END
    AND    xwbl.bill_no                  = iv_bill_no
    AND    xwbl.status IN( cv_status_a,  cv_status_i,  cv_status_p )
    AND    xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id
    AND    ROWNUM                        = cn_1 ;
    -- *** �Y���f�[�^�����݂���ꍇ�A��O���� ***
    IF ( ln_count = cn_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10092
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => iv_cust_code
                , iv_token_name2  => cv_token_invoice_no
                , iv_token_value2 => iv_bill_no
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    --�o�͋敪
                    , iv_message  => lv_msg             --���b�Z�[�W
                    , in_new_line => 0                  --���s
                    );
      ov_retcode := cv_status_continue;
    END IF;
  EXCEPTION
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
   * Procedure Name   : get_tmp_wholesale_bill
   * Description      : �≮������Excel�A�b�v���[�h���[�N�e�[�u���f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_tmp_wholesale_bill(
    ov_errbuf   OUT VARCHAR2     --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2     --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)      --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'get_tmp_wholesale_bill';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode   BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����J�[�\��
    -- =======================
    CURSOR get_wk_tab_cur
    IS
      SELECT   xtwb.supplier_code       AS supplier_code
             , xtwb.expect_payment_date AS expect_payment_date
             , xtwb.selling_month       AS selling_month
             , xtwb.base_code           AS base_code
             , xtwb.bill_no             AS bill_no
             , xtwb.cust_code           AS cust_code
             , xtwb.sales_outlets_code  AS sales_outlets_code
             , xtwb.item_code           AS item_code
             , xtwb.acct_code           AS acct_code
             , xtwb.sub_acct_code       AS sub_acct_code
             , xtwb.demand_unit_type    AS demand_unit_type
             , xtwb.demand_qty          AS demand_qty
             , xtwb.demand_unit_price   AS demand_unit_price
             , xtwb.demand_amt          AS demand_amt
             , xtwb.payment_qty         AS payment_qty
             , xtwb.payment_unit_price  AS payment_unit_price
             , xtwb.payment_amt         AS payment_amt
      FROM     xxcok_tmp_wholesale_bill xtwb
      WHERE    xtwb.file_id = in_file_id
      ORDER BY xtwb.sort_no;
    -- =======================
    -- ���[�J��TABLE�^�ϐ�
    -- =======================
    TYPE l_tab_ttype IS TABLE OF get_wk_tab_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_get_tmp_cur_tab  l_tab_ttype;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ���׃f�[�^�폜(A-6)�ďo��
    -- =============================================================================
    del_wholesale_bill_details(
      ov_errbuf              => lv_errbuf                                         --�G���[�E���b�Z�[�W
    , ov_retcode             => lv_retcode                                        --���^�[���E�R�[�h
    , ov_errmsg              => lv_errmsg                                         --���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- *** �J�[�\���I�[�v�� ***
    OPEN  get_wk_tab_cur;
    FETCH get_wk_tab_cur BULK COLLECT INTO l_get_tmp_cur_tab;
    CLOSE get_wk_tab_cur;
    -- �Ώی������i�[
    gn_target_cnt := l_get_tmp_cur_tab.COUNT;
--
    <<loop_1>>
    FOR ln_idx IN 1 .. l_get_tmp_cur_tab.COUNT LOOP
      -- =============================================================================
      -- �Ó����`�F�b�N(A-4)�ďo��
      -- =============================================================================
      chk_data(
        ov_errbuf              => lv_errbuf                                         --�G���[�E���b�Z�[�W
      , ov_retcode             => lv_retcode                                        --���^�[���E�R�[�h
      , ov_errmsg              => lv_errmsg                                         --���[�U�[�E�G���[�E���b�Z�[�W
      , in_loop_cnt            => ln_idx                                            --LOOP�J�E���^
      , iv_supplier_code       => l_get_tmp_cur_tab( ln_idx ).supplier_code         --�d����R�[�h
      , iv_expect_payment_date => l_get_tmp_cur_tab( ln_idx ).expect_payment_date   --�x���\���
      , iv_selling_month       => l_get_tmp_cur_tab( ln_idx ).selling_month         --����Ώ۔N��
      , iv_base_code           => l_get_tmp_cur_tab( ln_idx ).base_code             --���_�R�[�h
      , iv_bill_no             => l_get_tmp_cur_tab( ln_idx ).bill_no               --������No.
      , iv_cust_code           => l_get_tmp_cur_tab( ln_idx ).cust_code             --�ڋq�R�[�h
      , iv_sales_outlets_code  => l_get_tmp_cur_tab( ln_idx ).sales_outlets_code    --�≮������R�[�h
      , iv_item_code           => l_get_tmp_cur_tab( ln_idx ).item_code             --�i�ڃR�[�h
      , iv_acct_code           => l_get_tmp_cur_tab( ln_idx ).acct_code             --����ȖڃR�[�h
      , iv_sub_acct_code       => l_get_tmp_cur_tab( ln_idx ).sub_acct_code         --�⏕�ȖڃR�[�h
      , iv_demand_unit_type    => l_get_tmp_cur_tab( ln_idx ).demand_unit_type      --�����P��
      , iv_demand_qty          => l_get_tmp_cur_tab( ln_idx ).demand_qty            --��������
      , iv_demand_unit_price   => l_get_tmp_cur_tab( ln_idx ).demand_unit_price     --�����P��(�Ŕ�)
      , iv_demand_amt          => l_get_tmp_cur_tab( ln_idx ).demand_amt            --�������z(�Ŕ�)
      , iv_payment_qty         => l_get_tmp_cur_tab( ln_idx ).payment_qty           --�x������
      , iv_payment_unit_price  => l_get_tmp_cur_tab( ln_idx ).payment_unit_price    --�x���P��(�Ŕ�)
      , iv_payment_amt         => l_get_tmp_cur_tab( ln_idx ).payment_amt           --�x�����z(�Ŕ�)
      );
--
      IF ( lv_retcode = cv_status_continue ) THEN
        gv_chk_code  := lv_retcode;
        ov_retcode   := lv_retcode;
        gn_error_cnt := gn_error_cnt + 1;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- =============================================================================
      -- �Ó����`�F�b�N�ŃG���[���������Ă��Ȃ����A-6�AA-7�����s
      -- =============================================================================
      IF NOT ( gv_chk_code = cv_status_continue ) THEN
        -- =============================================================================
        -- �≮�������e�[�u���f�[�^�o�^(A-7)�ďo��
        -- =============================================================================
        ins_wholesale_bill_tbl(
          ov_errbuf              => lv_errbuf                                         --�G���[�E���b�Z�[�W
        , ov_retcode             => lv_retcode                                        --���^�[���E�R�[�h
        , ov_errmsg              => lv_errmsg                                         --���[�U�[�E�G���[�E���b�Z�[�W
        , iv_supplier_code       => l_get_tmp_cur_tab( ln_idx ).supplier_code         --�d����R�[�h
        , iv_expect_payment_date => l_get_tmp_cur_tab( ln_idx ).expect_payment_date   --�x���\���
        , iv_selling_month       => l_get_tmp_cur_tab( ln_idx ).selling_month         --����Ώ۔N��
        , iv_base_code           => l_get_tmp_cur_tab( ln_idx ).base_code             --���_�R�[�h
        , iv_bill_no             => l_get_tmp_cur_tab( ln_idx ).bill_no               --������No.
        , iv_cust_code           => l_get_tmp_cur_tab( ln_idx ).cust_code             --�ڋq�R�[�h
        , iv_sales_outlets_code  => l_get_tmp_cur_tab( ln_idx ).sales_outlets_code    --�≮������R�[�h
        , iv_item_code           => l_get_tmp_cur_tab( ln_idx ).item_code             --�i�ڃR�[�h
        , iv_acct_code           => l_get_tmp_cur_tab( ln_idx ).acct_code             --����ȖڃR�[�h
        , iv_sub_acct_code       => l_get_tmp_cur_tab( ln_idx ).sub_acct_code         --�⏕�ȖڃR�[�h
        , iv_demand_unit_type    => l_get_tmp_cur_tab( ln_idx ).demand_unit_type      --�����P��
        , iv_demand_qty          => l_get_tmp_cur_tab( ln_idx ).demand_qty            --��������
        , iv_demand_unit_price   => l_get_tmp_cur_tab( ln_idx ).demand_unit_price     --�����P��(�Ŕ�)
        , iv_demand_amt          => l_get_tmp_cur_tab( ln_idx ).demand_amt            --�������z(�Ŕ�)
        , iv_payment_qty         => l_get_tmp_cur_tab( ln_idx ).payment_qty           --�x������
        , iv_payment_unit_price  => l_get_tmp_cur_tab( ln_idx ).payment_unit_price    --�x���P��(�Ŕ�)
        , iv_payment_amt         => l_get_tmp_cur_tab( ln_idx ).payment_amt           --�x�����z(�Ŕ�)
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_wholesale_bill;
--
  /**********************************************************************************
   * Procedure Name   : get_file_data
   * Description      : �t�@�C���f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_data(
    ov_errbuf   OUT VARCHAR2     --�G���[�E���b�Z�[�W
  , ov_retcode  OUT VARCHAR2     --���^�[���E�R�[�h
  , ov_errmsg   OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
  , in_file_id  IN  NUMBER)      --�t�@�C��ID
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(15) := 'get_file_data';   --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf               VARCHAR2(5000)  DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1)     DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000)  DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg                  VARCHAR2(5000)  DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lv_file_name            VARCHAR2(256)   DEFAULT NULL;               --�t�@�C����
    lv_supplier_code        VARCHAR2(100)   DEFAULT NULL;               --�d����R�[�h
    lv_expect_payment_date  VARCHAR2(100)   DEFAULT NULL;               --�x���\���
    lv_selling_month        VARCHAR2(100)   DEFAULT NULL;               --����Ώ۔N��
    lv_base_code            VARCHAR2(100)   DEFAULT NULL;               --���_�R�[�h
    lv_bill_no              VARCHAR2(100)   DEFAULT NULL;               --������No.
    lv_cust_code            VARCHAR2(100)   DEFAULT NULL;               --�ڋq�R�[�h
    lv_sales_outlets_code   VARCHAR2(100)   DEFAULT NULL;               --�≮������R�[�h
    lv_item_code            VARCHAR2(100)   DEFAULT NULL;               --�i�ڃR�[�h
    lv_acct_code            VARCHAR2(100)   DEFAULT NULL;               --����ȖڃR�[�h
    lv_sub_acct_code        VARCHAR2(100)   DEFAULT NULL;               --�⏕�ȖڃR�[�h
    lv_demand_unit_type     VARCHAR2(100)   DEFAULT NULL;               --�����P��
    lv_demand_qty           VARCHAR2(100)   DEFAULT NULL;               --��������
    lv_demand_unit_price    VARCHAR2(100)   DEFAULT NULL;               --�����P��(�Ŕ�)
    lv_demand_amt           VARCHAR2(100)   DEFAULT NULL;               --�������z(�Ŕ�)
    lv_payment_qty          VARCHAR2(100)   DEFAULT NULL;               --�x������
    lv_payment_unit_price   VARCHAR2(100)   DEFAULT NULL;               --�x���P��(�Ŕ�)
    lv_payment_amt          VARCHAR2(100)   DEFAULT NULL;               --�x�����z(�Ŕ�)
    lv_line                 VARCHAR2(32767) DEFAULT NULL;               --1�s�̃f�[�^
    lb_retcode              BOOLEAN         DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
    ln_col                  NUMBER          DEFAULT 0;                  --�J����
    ln_loop_cnt             NUMBER          DEFAULT 0;                  --LOOP�J�E���^
    ln_csv_col_cnt          NUMBER;                                     --CSV���ڐ�
    -- =======================
    -- ���[�J��TABLE�^�ϐ�
    -- =======================
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;   --�s�e�[�u���i�[�̈�
    l_split_csv_tab   xxcok_common_pkg.g_split_csv_tbl;    --CSV�����f�[�^�i�[�̈�
    -- =======================
    -- ���[�J���J�[�\��
    -- =======================
    -- =============================================================================
    -- 1.�t�@�C���A�b�v���[�hIF�\�̃f�[�^�E���b�N���擾
    -- =============================================================================
    CURSOR xmfui_cur
    IS
      SELECT xmfui.file_name AS file_name
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
    -- =======================
    -- ���[�J�����R�[�h
    -- =======================
    xmfui_rec  xmfui_cur%ROWTYPE;
    -- =======================
    -- ���[�J����O
    -- =======================
    blob_expt  EXCEPTION;   --BLOB�f�[�^�ϊ��G���[
    file_expt  EXCEPTION;   --��t�@�C���G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  xmfui_cur;
      FETCH xmfui_cur INTO xmfui_rec;
      lv_file_name := xmfui_rec.file_name;
    CLOSE xmfui_cur;
    -- =============================================================================
    -- 2.�t�@�C�������b�Z�[�W�o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00006
              , iv_token_name1  => cv_token_file_name
              , iv_token_value1 => lv_file_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 1                 --���s
                  );
    -- =============================================================================
    -- 4.BLOB�f�[�^�ϊ�
    -- =============================================================================
    xxccp_common_pkg2.blob_to_varchar2(
      ov_errbuf    => lv_errbuf
    , ov_retcode   => lv_retcode
    , ov_errmsg    => lv_errmsg
    , in_file_id   => in_file_id
    , ov_file_data => l_file_data_tab
    );
    -- *** ���^�[���R�[�h��0(����)�ȊO�̏ꍇ�A��O���� ***
    IF NOT ( lv_retcode = cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
    -- =============================================================================
    -- 5.�擾�����f�[�^�������`�F�b�N(������1���ȉ��̏ꍇ�A��O����)
    -- =============================================================================
    IF ( l_file_data_tab.COUNT <= cn_1 ) THEN
      RAISE file_expt;
    END IF;
    -- =============================================================================
    -- 6.������𕪊�
    -- =============================================================================
    <<main_loop>>
    FOR ln_index IN 2 .. l_file_data_tab.COUNT LOOP
      --LOOP�J�E���^
      ln_loop_cnt := ln_loop_cnt + 1;
      --1�s���̃f�[�^���i�[
      lv_line := l_file_data_tab( ln_index );
      -- =============================================================================
      -- �ϐ��̏�����
      -- =============================================================================
      l_split_csv_tab.delete;
--
      lv_supplier_code       := NULL;
      lv_expect_payment_date := NULL;
      lv_selling_month       := NULL;
      lv_base_code           := NULL;
      lv_bill_no             := NULL;
      lv_cust_code           := NULL;
      lv_sales_outlets_code  := NULL;
      lv_item_code           := NULL;
      lv_acct_code           := NULL;
      lv_sub_acct_code       := NULL;
      lv_demand_unit_type    := NULL;
      lv_demand_qty          := NULL;
      lv_demand_unit_price   := NULL;
      lv_demand_amt          := NULL;
      lv_payment_qty         := NULL;
      lv_payment_unit_price  := NULL;
      lv_payment_amt         := NULL;
      -- =============================================================================
      -- CSV�����񕪊�
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
        --����1(�d����R�[�h)
        IF ( ln_cnt = 1 ) THEN
           lv_supplier_code := l_split_csv_tab( ln_cnt );
        --����2(�x���\���)
        ELSIF ( ln_cnt = 2 ) THEN
          lv_expect_payment_date := l_split_csv_tab( ln_cnt );
        --����3(����Ώ۔N��)
        ELSIF ( ln_cnt = 3 ) THEN
          lv_selling_month := l_split_csv_tab( ln_cnt );
        --����4(���_�R�[�h)
        ELSIF ( ln_cnt = 4 ) THEN
          lv_base_code := l_split_csv_tab( ln_cnt );
        --����5(������No.)
        ELSIF ( ln_cnt = 5 ) THEN
          lv_bill_no := l_split_csv_tab( ln_cnt );
        --����6(�ڋq�R�[�h)
        ELSIF ( ln_cnt = 6 ) THEN
          lv_cust_code := l_split_csv_tab( ln_cnt );
        --����7(�≮������R�[�h)
        ELSIF ( ln_cnt = 7 ) THEN
          lv_sales_outlets_code := l_split_csv_tab( ln_cnt );
        --����8(�i�ڃR�[�h)
        ELSIF ( ln_cnt = 8 ) THEN
          lv_item_code := l_split_csv_tab( ln_cnt );
        --����9(����ȖڃR�[�h)
        ELSIF ( ln_cnt = 9 ) THEN
          lv_acct_code := l_split_csv_tab( ln_cnt );
        --����10(�⏕�ȖڃR�[�h)
        ELSIF ( ln_cnt = 10 ) THEN
          lv_sub_acct_code := l_split_csv_tab( ln_cnt );
        --����11(�����P��)
        ELSIF ( ln_cnt = 11 ) THEN
          lv_demand_unit_type := l_split_csv_tab( ln_cnt );
        --����12(��������)
        ELSIF ( ln_cnt = 12 ) THEN
          lv_demand_qty := l_split_csv_tab( ln_cnt );
        --����13(�����P��(�Ŕ�))
        ELSIF ( ln_cnt = 13 ) THEN
          lv_demand_unit_price := l_split_csv_tab( ln_cnt );
        --����14(�������z(�Ŕ�))
        ELSIF ( ln_cnt = 14 ) THEN
          lv_demand_amt := l_split_csv_tab( ln_cnt );
        --����15(�x������)
        ELSIF ( ln_cnt = 15 ) THEN
          lv_payment_qty := l_split_csv_tab( ln_cnt );
        --����16(�x���P��(�Ŕ�))
        ELSIF ( ln_cnt = 16 ) THEN
          lv_payment_unit_price := l_split_csv_tab( ln_cnt );
        --����17(�x�����z(�Ŕ�))
        ELSIF ( ln_cnt = 17 ) THEN
          lv_payment_amt := l_split_csv_tab( ln_cnt );
        END IF;
      END LOOP comma_loop;
      -- =============================================================================
      -- 7.�≮������Excel�A�b�v���[�h���[�N�e�[�u���֎�荞��
      -- =============================================================================
      INSERT INTO xxcok_tmp_wholesale_bill(
        sort_no                   --�\�[�gNo(LOOP�J�E���^)
      , file_id                   --�t�@�C��ID
      , supplier_code             --�d����R�[�h
      , expect_payment_date       --�x���\���
      , selling_month             --����Ώ۔N��
      , base_code                 --���_�R�[�h
      , bill_no                   --������No.
      , cust_code                 --�ڋq�R�[�h
      , sales_outlets_code        --�≮������R�[�h
      , item_code                 --�i�ڃR�[�h
      , acct_code                 --����ȖڃR�[�h
      , sub_acct_code             --�⏕�ȖڃR�[�h
      , demand_unit_type          --�����P��
      , demand_qty                --��������
      , demand_unit_price         --�����P��(�Ŕ�)
      , demand_amt                --�������z(�Ŕ�)
      , payment_qty               --�x������
      , payment_unit_price        --�x���P��(�Ŕ�)
      , payment_amt               --�x�����z(�Ŕ�)
      ) VALUES (
        ln_loop_cnt               --sort_no
      , in_file_id                --file_id
      , lv_supplier_code          --supplier_code
      , lv_expect_payment_date    --expect_payment_date
      , lv_selling_month          --selling_month
      , lv_base_code              --base_code
      , lv_bill_no                --bill_no
      , lv_cust_code              --cust_code
      , lv_sales_outlets_code     --sales_outlets_code
      , lv_item_code              --item_code
      , lv_acct_code              --acct_code
      , lv_sub_acct_code          --sub_acct_code
      , lv_demand_unit_type       --demand_unit_type
      , lv_demand_qty             --demand_qty
      , lv_demand_unit_price      --demand_unit_price
      , lv_demand_amt             --demand_amt
      , lv_payment_qty            --payment_qty
      , lv_payment_unit_price     --payment_unit_price
      , lv_payment_amt            --payment_amt
      );
    END LOOP main_loop;
  EXCEPTION
    -- *** ���b�N���s ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** BLOB�f�[�^�ϊ��G���[ ***
    WHEN blob_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00041
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ��t�@�C���G���[ ***
    WHEN file_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00039
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
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
  END get_file_data;
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
    cv_prg_name   CONSTANT VARCHAR2(5) := 'init';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg          VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lv_emp_code     VARCHAR2(5)    DEFAULT NULL;               --�]�ƈ��R�[�h�擾�ϐ�
    lv_profile_code VARCHAR2(100)  DEFAULT NULL;               --�v���t�@�C���l
    lb_retcode      BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
    -- =======================
    -- ���[�J����O
    -- =======================
    get_profile_expt EXCEPTION;   --�J�X�^����v���t�@�C���擾�G���[
    get_process_expt EXCEPTION;   --�Ɩ��������t�擾�G���[
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
              , iv_token_value1 => TO_CHAR( in_file_id )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 0                 --���s
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
              , iv_token_value1 => TO_CHAR( iv_format_pattern )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 1                 --���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --�o�͋敪
                  , iv_message  => lv_msg            --���b�Z�[�W
                  , in_new_line => 2                 --���s
                  );
    -- =============================================================================
    -- 2.(1)�v���t�@�C�����擾(�Ɩ��Ǘ����̕���R�[�h)
    -- =============================================================================
    gv_dept_code := FND_PROFILE.VALUE( cv_dept_code_p );
--
    IF ( gv_dept_code IS NULL ) THEN
      lv_profile_code := cv_dept_code_p;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 2.(2)�v���t�@�C�����擾(�c�ƒP��ID)
    -- =============================================================================
    gn_org_id := TO_NUMBER ( FND_PROFILE.VALUE( cv_org_id_p ) );
--
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_code := cv_org_id_p;
      RAISE get_profile_expt;
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD START
    --==================================================
    -- �݌ɑg�D
    --==================================================
    gv_organization_code  := FND_PROFILE.VALUE( cv_organization_code );
    IF ( gv_organization_code IS NULL ) THEN
      lv_profile_code := cv_organization_code;
      RAISE get_profile_expt;
    END IF;
-- 2009/12/18 Ver.1.6 [E_�{�ғ�_00539] SCS K.Yamaguchi ADD END
    -- =============================================================================
    -- 3.���[�U�̏���������擾
    -- =============================================================================
    gv_user_dept_code := xxcok_common_pkg.get_department_code_f(
                           in_user_id => cn_created_by
                         );
--
    IF ( gv_user_dept_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00030
                , iv_token_name1  => cv_token_user_id
                , iv_token_value1 => cn_created_by
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END IF;
    -- =============================================================================
    -- 4.�Ɩ��������t�擾
    -- =============================================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_prdate IS NULL ) THEN
      RAISE get_process_expt;
    END IF;
  EXCEPTION
    -- *** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00003
                , iv_token_name1  => cv_token_profile
                , iv_token_value1 => lv_profile_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --�o�͋敪
                    , iv_message  => lv_msg            --���b�Z�[�W
                    , in_new_line => 0                 --���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �Ɩ����t�擾�G���[ ***
    WHEN get_process_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00028
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
    ov_errbuf         OUT VARCHAR2     --�G���[�E���b�Z�[�W
  , ov_retcode        OUT VARCHAR2     --���^�[���E�R�[�h
  , ov_errmsg         OUT VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W
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
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode   BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ��������(A-1)�̌ďo��
    -- =============================================================================
    init(
      ov_errbuf         => lv_errbuf
    , ov_retcode        => lv_retcode
    , ov_errmsg         => lv_errmsg
    , in_file_id        => in_file_id
    , iv_format_pattern => iv_format_pattern
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- �t�@�C���f�[�^�擾(A-2)�̌ďo��
    -- =============================================================================
    get_file_data(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    , in_file_id => in_file_id
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- �ꎞ�\�f�[�^�擾(A-3)�̌ďo��
    -- =============================================================================
    get_tmp_wholesale_bill(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    , in_file_id => in_file_id
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_continue ) THEN
      ROLLBACK;
    END IF;
    -- =============================================================================
    -- �����f�[�^�폜(A-8)�̌ďo��
    -- =============================================================================
    del_mrp_file_ul_interface(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    , in_file_id => in_file_id
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- �Ó����`�F�b�N�ŃG���[�����������ꍇ�A�X�e�[�^�X���G���[�ɐݒ�
    -- =============================================================================
    IF ( gv_chk_code = cv_status_continue ) THEN
      ov_retcode := cv_status_error;
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
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf            OUT  VARCHAR2    --�G���[���b�Z�[�W
  , retcode           OUT  VARCHAR2    --�G���[�R�[�h
  , iv_file_id        IN   VARCHAR2    --�t�@�C��ID
  , iv_format_pattern IN   VARCHAR2    --�t�H�[�}�b�g�p�^�[��
  )
  IS
    -- =======================
    -- ���[�J���萔
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(5) := 'main';    --�v���O������
    -- =======================
    -- ���[�J���ϐ�
    -- =======================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;               --�G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;   --���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;               --���[�U�[�E�G���[�E���b�Z�[�W
    lv_msg           VARCHAR2(5000) DEFAULT NULL;               --���b�Z�[�W�擾�ϐ�
    lv_message_code  VARCHAR2(500)  DEFAULT NULL;               --���b�Z�[�W�R�[�h
    lb_retcode       BOOLEAN        DEFAULT TRUE;               --���b�Z�[�W�o�̖͂߂�l
    ln_file_id       NUMBER;                                    --�t�@�C��ID
--
  BEGIN
    ln_file_id := TO_NUMBER( iv_file_id );
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
      ov_errbuf         => lv_errbuf
    , ov_retcode        => lv_retcode
    , ov_errmsg         => lv_errmsg
    , in_file_id        => ln_file_id
    , iv_format_pattern => iv_format_pattern
    );
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
    -- �Ώی����o��
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90000
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => gn_target_cnt
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    -- =============================================================================
    -- ���������o��
    -- =============================================================================
    -- *** ���^�[���R�[�h���G���[�̏ꍇ�A����������'0'���ɂ��� ***
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
    END IF;
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90001
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => gn_normal_cnt
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
              , iv_token_value1 => gn_error_cnt
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
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_message_90006;
    END IF;
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application => cv_xxccp_appl_name
              , iv_name        => lv_message_code
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --�o�͋敪
                  , iv_message  => lv_msg              --���b�Z�[�W
                  , in_new_line => 0                   --���s
                  );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
      --IF�e�[�u���Ƀf�[�^������ꍇ�͍폜
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --�G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode     --���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg      --���[�U�[�E�G���[�E���b�Z�[�W
      , in_file_id => ln_file_id     --�t�@�C��ID
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
      , in_file_id => ln_file_id     --�t�@�C��ID
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
      , in_file_id => ln_file_id     --�t�@�C��ID
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
      , in_file_id => ln_file_id     --�t�@�C��ID
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
END XXCOK021A01C;
/
