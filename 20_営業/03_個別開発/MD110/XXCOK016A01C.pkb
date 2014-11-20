CREATE OR REPLACE PACKAGE BODY XXCOK016A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK016A01C(spec)
 * Description      : �g�ݖ߂��E�c������E�ۗ����(CSV�t�@�C��)�̎捞����
 * MD.050           : �c���X�VExcel�A�b�v���[�h MD050_COK_016_A01
 * Version          : 1.3
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �g�ݖ߂��E�c������E�ۗ����(CSV�t�@�C��)�̎捞����
 *  submain              ���C�������v���V�[�W��
 *  init_proc            ��������(A-1)
 *  chk_validate_item    �Ó����`�F�b�N����(A-4)
 *  upd_bm_balance_data  �c���̍X�V(A-6)
 *  del_file_upload_data �t�@�C���A�b�v���[�h�f�[�^�̍폜(A-7)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   K.Ezaki          �V�K�쐬
 *  2009/02/19    1.1   A.Yano           [��QCOK_047] �c��������̍X�V�s��Ή�
 *  2009/05/29    1.2   M.Hiruta         [��QT1_1139] ���t������ύX���A�ߋ����̃f�[�^�������ł���悤�ύX
 *  2010/01/20    1.3   K.Kiriu          [E_�{�ғ�_01115]�c���X�V�����_�ŏ����A�P�d����̕����������\�Ƃł���悤�ύX
 *
 *****************************************************************************************/
--
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���萔
  ------------------------------------------------------------
  -- �p�b�P�[�W��`
  cv_pkg_name       CONSTANT VARCHAR2(12) := 'XXCOK016A01C';                     -- �p�b�P�[�W��
  -- �����l
  cv_msg_part       CONSTANT VARCHAR2(3)  := ' : ';                              -- ���b�Z�[�W�f���~�^
  cv_msg_cont       CONSTANT VARCHAR2(1)  := '.';                                -- �J���}
  cn_zero           CONSTANT NUMBER       := 0;                                  -- ���l:0
  cn_one            CONSTANT NUMBER       := 1;                                  -- ���l:1
  cv_zero           CONSTANT VARCHAR2(1)  := '0';                                -- ����:0
  cv_one            CONSTANT VARCHAR2(1)  := '1';                                -- ����:1
  cv_msg_wq         CONSTANT VARCHAR2(1)  := '"';                                -- �_�u���N�H�[�e�C�V����
  cv_msg_c          CONSTANT VARCHAR2(1)  := ',';                                -- �R���}
  cv_csv_sep        CONSTANT VARCHAR2(1)  := ',';                                -- CSV�Z�p���[�^
  cv_yes            CONSTANT VARCHAR2(1)  := 'Y';                                -- ����:Y
  cv_no             CONSTANT VARCHAR2(1)  := 'N';                                -- ����:N
  cv_act_dept       CONSTANT VARCHAR2(1)  := '1';                                -- �Ɩ��Ǘ���
  cv_bel_dept       CONSTANT VARCHAR2(1)  := '2';                                -- �e���_����
  cn_vend_len       CONSTANT NUMBER       := 9;                                  -- �d����R�[�h����
  cn_cust_len       CONSTANT NUMBER       := 9;                                  -- �ڋq�R�[�h����
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--  cn_pay_amt_len    CONSTANT NUMBER       := 7;                                  -- �x�����z����
  cn_pay_amt_len    CONSTANT NUMBER       := 10;                                 -- �x�����z����(FB�f�[�^�t�@�C���̌����ɍ��킷)
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
  cv_proc_type1     CONSTANT VARCHAR2(1)  := '1';                                -- �����敪�F�g�ݖ߂�
  cv_proc_type2     CONSTANT VARCHAR2(1)  := '2';                                -- �����敪�F�c�����
  cv_proc_type3     CONSTANT VARCHAR2(1)  := '3';                                -- �����敪�F�ۗ�
  cv_proc_type4     CONSTANT VARCHAR2(1)  := '4';                                -- �����敪�F�ۗ�����
  cv_pay_type1      CONSTANT VARCHAR2(1)  := '1';                                -- �x���敪�F�{�U�i�ē�������j
  cv_pay_type2      CONSTANT VARCHAR2(1)  := '2';                                -- �x���敪�F�{�U�i�ē����Ȃ��j
  cv_pay_type3      CONSTANT VARCHAR2(1)  := '3';                                -- �x���敪�F�o��x���a�l
  cv_pay_type4      CONSTANT VARCHAR2(1)  := '4';                                -- �x���敪�F�����x��
  cv_pay_type5      CONSTANT VARCHAR2(1)  := '5';                                -- �x���敪�F�Ȃ�
  cv_fb_if_type0    CONSTANT VARCHAR2(1)  := '0';                                -- �A�g�敪�F������
  cv_fb_if_type1    CONSTANT VARCHAR2(1)  := '1';                                -- �A�g�敪�F������
  cv_output         CONSTANT VARCHAR2(6)  := 'OUTPUT';                           -- �w�b�_���O�o��
  --WHO�J����
  cn_created_by     CONSTANT NUMBER       := fnd_global.user_id;                 -- �쐬�҂̃��[�U�[ID
  cn_last_upd_by    CONSTANT NUMBER       := fnd_global.user_id;                 -- �ŏI�X�V�҂̃��[�U�[ID
  cn_last_upd_login CONSTANT NUMBER       := fnd_global.login_id;                -- �ŏI�X�V�҂̃��O�C��ID
  cn_request_id     CONSTANT NUMBER       := fnd_global.conc_request_id;         -- �v��ID
  cn_prg_appl_id    CONSTANT NUMBER       := fnd_global.prog_appl_id;            -- �R���J�����g�A�v���P�[�V����ID
  cn_program_id     CONSTANT NUMBER       := fnd_global.conc_program_id;         -- �R���J�����g�v���O����ID
  -- �A�v���P�[�V�����Z�k��
  cv_ap_type_xxccp  CONSTANT VARCHAR2(5)  := 'XXCCP';                            -- ����
  cv_ap_type_xxcok  CONSTANT VARCHAR2(5)  := 'XXCOK';                            -- �ʊJ��
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal  CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn    CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error   CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  cv_status_check   CONSTANT VARCHAR2(1)  := 9;                                  -- �`�F�b�N�G���[:9
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
  cv_status_lock    CONSTANT VARCHAR2(1)  := '7';                                -- ���b�N�G���[:7
  cv_status_update  CONSTANT VARCHAR2(1)  := '8';                                -- �X�V�G���[:8
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
  -- ���ʃ��b�Z�[�W��`
  cv_normal_msg     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';                 -- ����I�����b�Z�[�W
  cv_warn_msg       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';                 -- �x���I�����b�Z�[�W
  cv_error_msg      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';                 -- �G���[�I�����b�Z�[�W
  cv_mainmsg_90000  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';                 -- �Ώی����o��
  cv_mainmsg_90001  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';                 -- ���������o��
  cv_mainmsg_90002  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';                 -- �G���[�����o��
  cv_mainmsg_90003  CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';                 -- �X�L�b�v�����o��
  -- �ʃ��b�Z�[�W��`
  cv_prmmsg_00016   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00016';                 -- �t�@�C��ID�p�����[�^
  cv_prmmsg_00017   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00017';                 -- �t�@�C���p�^�[���p�����[�^
  cv_errmsg_00028   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';                 -- �Ɩ��������t�擾�G���[
  cv_errmsg_00003   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';                 -- �v���t�@�C���擾�G���[
  cv_errmsg_00030   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00030';                 -- ��������擾�G���[
  cv_errmsg_00061   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00061';                 -- �t�@�C���A�b�v���[�h���b�N�G���[
  cv_errmsg_00041   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';                 -- BLOB�f�[�^�ϊ��G���[
  cv_errmsg_00039   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00039';                 -- �t�@�C���擾�G���[
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--  cv_errmsg_00053   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00053';                 -- �c���X�V���b�N�G���[
--  cv_errmsg_00054   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00054';                 -- �c���X�V�G���[
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
  cv_errmsg_00062   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00062';                 -- �t�@�C���A�b�v���[�hIF�폜�G���[
  cv_errmsg_10217   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10217';                 -- �c���X�V�A�b�v���[�h���擾�G���[
  cv_errmsg_10218   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10218';                 -- �Ɩ��Ǘ��������敪�`�F�b�N�G���[
  cv_errmsg_10219   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10219';                 -- ���_�����敪�`�F�b�N�G���[
  cv_errmsg_10220   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10220';                 -- �g�ݖ߂��K�{�`�F�b�N�G���[
  cv_errmsg_10221   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10221';                 -- �c������K�{�`�F�b�N�G���[
  cv_errmsg_10222   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10222';                 -- �Ɩ��Ǘ����ۗ��K�{�`�F�b�N�G���[
  cv_errmsg_10223   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10223';                 -- ���_�ۗ��K�{�`�F�b�N�G���[
  cv_errmsg_10224   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10224';                 -- �d����R�[�h���p�p�����`�F�b�N�G���[
  cv_errmsg_10225   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10225';                 -- �ڋq�R�[�h���p�p�����`�F�b�N�G���[
  cv_errmsg_10226   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10226';                 -- �d����R�[�h�����`�F�b�N�G���[
  cv_errmsg_10227   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10227';                 -- �ڋq�R�[�h�����`�F�b�N�G���[
  cv_errmsg_10228   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10228';                 -- �x�������t�`�F�b�N�G���[
  cv_errmsg_10229   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10229';                 -- �x�����z���l�`�F�b�N�G���[
  cv_errmsg_10230   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10230';                 -- �x�����z�����`�F�b�N�G���[
  cv_errmsg_10231   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10231';                 -- �x�����z�l�`�F�b�N�G���[
  cv_errmsg_10232   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10232';                 -- �d���摶�݃`�F�b�N�G���[
  cv_errmsg_10233   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10233';                 -- �ڋq���݃`�F�b�N�G���[
  cv_errmsg_10234   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10234';                 -- �g�ݖ߂��d����BM�x���敪�`�F�b�N�G���[
  cv_errmsg_10235   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10235';                 -- �c������d����BM�x���敪�`�F�b�N�G���[
  cv_errmsg_10236   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10236';                 -- �ۗ��d����BM�x���敪�`�F�b�N�G���[
  cv_errmsg_10237   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10237';                 -- �ۗ��ڋqBM�x���敪�`�F�b�N�G���[
  cv_errmsg_10238   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10238';                 -- �d����ۗ��`�F�b�N�G���[
  cv_errmsg_10239   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10239';                 -- �g�ݖ߂��g�ݍ��킹�`�F�b�N�G���[
  cv_errmsg_10240   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10240';                 -- �c������g�ݍ��킹�`�F�b�N�G���[
  cv_errmsg_10241   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10241';                 -- �ۗ��d����g�ݍ��킹�`�F�b�N�G���[
  cv_errmsg_10242   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10242';                 -- �ۗ��ڋq�g�ݍ��킹�`�F�b�N�G���[
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
  cv_errmsg_10474   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10474';                 -- �c���X�V���b�N�G���[
  cv_errmsg_10475   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10475';                 -- �c���X�V�G���[
  cv_errmsg_10456   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10476';                 -- �c������K�{�`�F�b�N�G���[(���_)
  cv_errmsg_10457   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10477';                 -- �c������g�ݍ��킹�`�F�b�N�G���[�i���_�j
  cv_errmsg_10458   CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10478';                 -- ���z���m��`�F�b�N�G���[�i���_�j
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
  -- ���b�Z�[�W�g�[�N����`
  cv_tkn_file_id    CONSTANT VARCHAR2(7)  := 'FILE_ID';                          -- �t�@�C��ID�g�[�N��
  cv_tkn_format     CONSTANT VARCHAR2(6)  := 'FORMAT';                           -- �t�@�C���p�^�[���g�[�N��
  cv_tkn_profile    CONSTANT VARCHAR2(7)  := 'PROFILE';                          -- �v���t�@�C���g�[�N��
  cv_tkn_user_id    CONSTANT VARCHAR2(7)  := 'USER_ID';                          -- ���[�UID�g�[�N��
  cv_tkn_row_num    CONSTANT VARCHAR2(7)  := 'ROW_NUM';                          -- �G���[�s�g�[�N��
  cv_tkn_vend_code  CONSTANT VARCHAR2(11) := 'VENDOR_CODE';                      -- �d����R�[�h�g�[�N��
  cv_tkn_cust_code  CONSTANT VARCHAR2(13) := 'CUSTOMER_CODE';                    -- �ڋq�R�[�h�g�[�N��
  cv_tkn_pay_date   CONSTANT VARCHAR2(8)  := 'PAY_DATE';                         -- �x�����g�[�N��
  cv_tkn_pay_amt    CONSTANT VARCHAR2(10) := 'PAY_AMOUNT';                       -- �x�����z�g�[�N��
  cv_tkn_count      CONSTANT VARCHAR2(5)  := 'COUNT';                            -- �����o�̓g�[�N��
  -- �v���t�@�C����`
  cv_dept_act_code  CONSTANT VARCHAR2(20) := 'XXCOK1_AFF2_DEPT_ACT';             -- �Ɩ��Ǘ�������R�[�h
  cv_prof_org_id    CONSTANT VARCHAR2(30) := 'ORG_ID';                           -- �g�DID
  -- �Q�ƕ\��`
  cv_lk_proc_type   CONSTANT VARCHAR2(27) := 'XXCOK1_BM_BALANCE_PROC_TYPE';      -- �c���A�b�v���[�h�����敪
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���ϐ�
  ------------------------------------------------------------
  gd_proc_date      DATE           := NULL;                                      -- �Ɩ��������t
  gn_target_cnt     NUMBER         := 0;                                         -- �Ώی���
  gn_normal_cnt     NUMBER         := 0;                                         -- ���팏��
  gn_error_cnt      NUMBER         := 0;                                         -- �G���[����
  gn_warn_cnt       NUMBER         := 0;                                         -- �X�L�b�v����
  gn_org_id         NUMBER         := NULL;                                      -- �݌ɑg�DID
  gv_dept_flg       VARCHAR2(1)    := NULL;                                      -- ����t���O
  gv_dept_act_code  fnd_profile_option_values.profile_option_value%TYPE := NULL; -- �Ɩ��Ǘ�������R�[�h
  gv_org_code_sales fnd_profile_option_values.profile_option_value%TYPE := NULL; -- �݌ɑg�D�R�[�h
  gv_dept_bel_code  per_all_people_f.attribute1%TYPE                    := NULL; -- ��������R�[�h
  -- �`�F�b�N��f�[�^�ޔ����R�[�h�^
  TYPE g_check_data_rtype IS RECORD (
     vendor_code   po_vendors.segment1%TYPE                                      -- �d����R�[�h
    ,customer_code hz_cust_accounts.account_number%TYPE                          -- �ڋq�R�[�h
    ,pay_date      xxcok_backmargin_balance.expect_payment_date%TYPE             -- �x����
    ,pay_amount    xxcok_backmargin_balance.backmargin%TYPE                      -- �x�����z
    ,proc_type     xxcok_backmargin_balance.resv_flag%TYPE                       -- �����^�C�v
  );
  -- �`�F�b�N��f�[�^�ޔ��e�[�u���^
  TYPE g_check_data_ttype IS TABLE OF g_check_data_rtype INDEX BY BINARY_INTEGER;
  ------------------------------------------------------------
  -- ���[�U�[��`��O
  ------------------------------------------------------------
  -- ��O
  global_api_expt        EXCEPTION; -- ���ʊ֐���O
  global_api_others_expt EXCEPTION; -- ���ʊ֐�OTHERS��O
  global_lock_expt       EXCEPTION; -- �O���[�o����O
  -- �v���O�}
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�̍폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_file_id IN NUMBER    -- �t�@�C��ID
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(2000);  -- ���b�Z�[�W
    lb_retcode BOOLEAN;         -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �t�@�C���A�b�v���[�h�폜���b�N�J�[�\����`
    CURSOR file_delete_cur(
       in_file_id IN NUMBER -- �t�@�C��ID
    )
    IS
      SELECT xmf.file_id AS file_id -- �t�@�C��ID
      FROM   xxccp_mrp_file_ul_interface xmf -- �t�@�C���A�b�v���[�h�e�[�u��
      WHERE  xmf.file_id = in_file_id
      FOR UPDATE NOWAIT;
    --===============================
    -- ���[�J����O
    --===============================
    delete_err_expt EXCEPTION; -- �폜�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�t�@�C���A�b�v���[�h�폜���b�N����
    -------------------------------------------------
    -- ���b�N����
    OPEN file_delete_cur(
       in_file_id -- �t�@�C��ID
    );
    CLOSE file_delete_cur;
    -------------------------------------------------
    -- 2.�t�@�C���A�b�v���[�h�폜����
    -------------------------------------------------
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE xmf.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE delete_err_expt;
    END;
  --
  EXCEPTION
    -- *** ���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00061
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �폜��O�n���h�� ***
    WHEN delete_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00062
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- ���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
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
  END del_file_upload_data;
  --
  /**********************************************************************************
   * Procedure Name   : upd_bm_balance_data
   * Description      : �c���̍X�V(A-5)
   ***********************************************************************************/
  PROCEDURE upd_bm_balance_data(
     ov_errbuf     OUT VARCHAR2           -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2           -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_index      IN  NUMBER             -- �s�ԍ�
    ,it_check_data IN  g_check_data_ttype -- �`�F�b�N��f�[�^
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'upd_bm_balance_data'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(2000);  -- ���b�Z�[�W
    lb_retcode BOOLEAN;         -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �g�ݖ߂����b�N�J�[�\����`
    CURSOR bm_rollback_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- �d����R�[�h
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
      ,id_pay_date    IN xxcok_backmargin_balance.publication_date%TYPE    -- �x����
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- �̎�c��ID
      FROM   xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
      WHERE  xbb.supplier_code       = iv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date = id_pay_date
      AND    xbb.publication_date = id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status = cv_fb_if_type1
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
    -- �Ɩ��Ǘ����c��������b�N�J�[�\����`
    CURSOR bm_cancel_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- �d����R�[�h
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- �̎�c��ID
      FROM   xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
      WHERE  xbb.supplier_code       = iv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
    -- �Ɩ��Ǘ����d����ۗ����b�N�J�[�\����`
    CURSOR bm_act_vend_pending_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- �d����R�[�h
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
      ,iv_recv_type   IN VARCHAR2                                          -- �ۗ��E�ۗ�����
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- �̎�c��ID
      FROM   xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
      WHERE  xbb.supplier_code        = iv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date  = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' ) = iv_recv_type
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
    -- �Ɩ��Ǘ����ڋq�ۗ����b�N�J�[�\����`
    CURSOR bm_act_cust_pending_cur(
       iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- �ڋq�R�[�h
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
      ,iv_recv_type     IN VARCHAR2                                          -- �ۗ��E�ۗ�����
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- �̎�c��ID
      FROM   xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
      WHERE  xbb.cust_code            = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date  = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' ) = iv_recv_type
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- ���_�c��������b�N�A�X�V�J�[�\����`
    CURSOR bm_bel_cancel_cur(
       iv_vendor_code IN po_vendors.segment1%TYPE                          -- �d����R�[�h
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE            -- �ڋq�R�[�h
      ,id_pay_date    IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
    )
    IS
      SELECT xbb.rowid AS row_id -- �̎�c��ROWID
      FROM   xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
      WHERE  xbb.supplier_code       = iv_vendor_code
      AND    xbb.expect_payment_date <= id_pay_date
      AND    xbb.resv_flag           IS NULL
      AND    xbb.fb_interface_status = cv_fb_if_type0
      AND    xbb.base_code           = gv_dept_bel_code
      AND    xbb.cust_code           = iv_customer_code
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- ���_�ڋq�ۗ����b�N�J�[�\����`
    CURSOR bm_bel_cust_pending_cur(
       iv_base_code     IN xxcok_backmargin_balance.base_code%TYPE           -- ���_�R�[�h
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- �ڋq�R�[�h
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
      ,iv_recv_type     IN VARCHAR2                                          -- �ۗ��E�ۗ�����
    )
    IS
      SELECT xbb.bm_balance_id AS bm_balance_id -- �̎�c��ID
      FROM   xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
      WHERE  xbb.base_code            = iv_base_code
      AND    xbb.cust_code            = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date  = id_pay_date
      AND    xbb.expect_payment_date <= id_pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' ) = iv_recv_type
      AND    xbb.fb_interface_status  = cv_fb_if_type0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- =======================
    -- ���[�J��TABLE�^
    -- =======================
    TYPE bm_bel_cancel_tab_type IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    l_bm_bel_cancel_tab  bm_bel_cancel_tab_type;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    --===============================
    -- ���[�J����O
    --===============================
    update_err_expt EXCEPTION; -- �X�V�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.�g�ݖ߂����b�N����
    -------------------------------------------------
    IF ( it_check_data(in_index).proc_type = cv_proc_type1 ) THEN
      -- ���b�N����
      OPEN bm_rollback_cur(
         it_check_data(in_index).vendor_code -- �d����R�[�h
        ,it_check_data(in_index).pay_date    -- �x����
      );
      CLOSE bm_rollback_cur;
    -------------------------------------------------
    -- 2.�Ɩ��Ǘ����c��������b�N����
    -------------------------------------------------
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--    ELSIF ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      -- ���b�N����
      OPEN bm_cancel_cur(
         it_check_data(in_index).vendor_code -- �d����R�[�h
        ,it_check_data(in_index).pay_date    -- �x����
      );
      CLOSE bm_cancel_cur;
    -------------------------------------------------
    -- 3.�Ɩ��Ǘ����d����ۗ����b�N����
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ���b�N����
      OPEN bm_act_vend_pending_cur(
         it_check_data(in_index).vendor_code -- �d����R�[�h
        ,it_check_data(in_index).pay_date    -- �x����
        ,cv_no                               -- �ۗ��E�ۗ�����
      );
      CLOSE bm_act_vend_pending_cur;
    -------------------------------------------------
    -- 3.�Ɩ��Ǘ����d����ۗ��������b�N����
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ���b�N����
      OPEN bm_act_vend_pending_cur(
         it_check_data(in_index).vendor_code -- �d����R�[�h
        ,it_check_data(in_index).pay_date    -- �x����
        ,cv_yes                              -- �ۗ��E�ۗ�����
      );
      CLOSE bm_act_vend_pending_cur;
    -------------------------------------------------
    -- 4.�Ɩ��Ǘ����ڋq�ۗ����b�N����
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ���b�N����
      OPEN bm_act_cust_pending_cur(
         it_check_data(in_index).customer_code -- �ڋq�R�[�h
        ,it_check_data(in_index).pay_date      -- �x����
        ,cv_no                                 -- �ۗ��E�ۗ�����
      );
      CLOSE bm_act_cust_pending_cur;
    -------------------------------------------------
    -- 4.�Ɩ��Ǘ����ڋq�ۗ��������b�N����
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ���b�N����
      OPEN bm_act_cust_pending_cur(
         it_check_data(in_index).customer_code -- �ڋq�R�[�h
        ,it_check_data(in_index).pay_date      -- �x����
        ,cv_yes                                -- �ۗ��E�ۗ�����
      );
      CLOSE bm_act_cust_pending_cur;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -------------------------------------------------
    -- 5.���_�c��������b�N����
    -------------------------------------------------      
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
      OPEN bm_bel_cancel_cur(
         it_check_data(in_index).vendor_code   -- �d����R�[�h
        ,it_check_data(in_index).customer_code -- �ڋq�R�[�h
        ,it_check_data(in_index).pay_date      -- �x����
      );
      FETCH bm_bel_cancel_cur BULK COLLECT INTO l_bm_bel_cancel_tab;
      CLOSE bm_bel_cancel_cur;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -------------------------------------------------
    -- 6.���_�ڋq�ۗ����b�N����
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
      -- ���b�N����
      OPEN bm_bel_cust_pending_cur(
         gv_dept_bel_code                      -- ��������R�[�h
        ,it_check_data(in_index).customer_code -- �ڋq�R�[�h
        ,it_check_data(in_index).pay_date      -- �x����
        ,cv_no                                 -- �ۗ��E�ۗ�����
      );
      CLOSE bm_bel_cust_pending_cur;
    -------------------------------------------------
    -- 7.���_�ڋq�ۗ��������b�N����
    -------------------------------------------------
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( it_check_data(in_index).customer_code IS NOT NULL ) AND
          ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
      -- ���b�N����
      OPEN bm_bel_cust_pending_cur(
         gv_dept_bel_code                      -- ��������R�[�h
        ,it_check_data(in_index).customer_code -- �ڋq�R�[�h
        ,it_check_data(in_index).pay_date      -- �x����
        ,cv_yes                                -- �ۗ��E�ۗ�����
      );
      CLOSE bm_bel_cust_pending_cur;
    END IF;
    -------------------------------------------------
    -- 8.�g�ݖ߂��X�V����
    -------------------------------------------------
    BEGIN
      IF ( it_check_data(in_index).proc_type = cv_proc_type1 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.expect_payment_amt_tax = xbb.payment_amt_tax       -- �x���\��z
              ,xbb.payment_amt_tax        = cn_zero                   -- �x���z
              ,xbb.publication_date       = NULL                      -- �ē���������
              ,xbb.fb_interface_status    = cv_fb_if_type0            -- �A�g�X�e�[�^�X�i�{�U�pFB�j
              ,xbb.edi_interface_status   = cv_fb_if_type0            -- �A�g�X�e�[�^�X�iEDI�x���ē����j
              ,xbb.gl_interface_status    = cv_fb_if_type0            -- �A�g�X�e�[�^�X�iGL�j
              ,xbb.return_flag            = cv_yes                    -- �g�ݖ߂��t���O
              ,xbb.balance_cancel_date    = NULL                      -- �c�������
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                   -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.supplier_code       = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = it_check_data(in_index).pay_date
        AND    xbb.publication_date    = it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NULL
        AND    xbb.fb_interface_status = cv_fb_if_type1;
      -------------------------------------------------
      -- 9.�Ɩ��Ǘ����c������X�V����
      -------------------------------------------------
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--      ELSIF ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.expect_payment_amt_tax = cn_zero                    -- �x���\��z
              ,xbb.payment_amt_tax        = xbb.expect_payment_amt_tax -- �x���z
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--              ,xbb.publication_date       = gd_proc_date               -- �ē���������
              ,xbb.publication_date       = it_check_data(in_index).pay_date -- �ē���������
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
              ,xbb.fb_interface_status    = cv_fb_if_type1             -- �A�g�X�e�[�^�X�i�{�U�pFB�j
              ,xbb.fb_interface_date      = gd_proc_date               -- �A�g���i�{�U�pFB�j
              ,xbb.edi_interface_status   = cv_fb_if_type1             -- �A�g�X�e�[�^�X�iEDI�x���ē����j
              ,xbb.edi_interface_date     = gd_proc_date               -- �A�g���iEDI�x���ē����j
              ,xbb.gl_interface_status    = cv_fb_if_type1             -- �A�g�X�e�[�^�X�iGL�j
              ,xbb.gl_interface_date      = gd_proc_date               -- �A�g���iGL�j
              ,xbb.return_flag            = NULL                       -- �g�ݖ߂��t���O
              ,xbb.balance_cancel_date    = gd_proc_date               -- �c�������
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID    -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                    -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID   -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id              -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id             -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id              -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                    -- �v���O�����X�V��
        WHERE  xbb.supplier_code       = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NULL
        AND    xbb.fb_interface_status = cv_fb_if_type0;
      -------------------------------------------------
      -- 10.�Ɩ��Ǘ����d����ۗ��X�V����
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.resv_flag              = cv_yes                    -- �ۗ��t���O
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                   -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.supplier_code        = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_no
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).vendor_code IS NOT NULL ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.resv_flag         = NULL                           -- �ۗ��t���O
              ,xbb.last_updated_by   = APPS.FND_GLOBAL.USER_ID        -- �ŏI�X�V��
              ,xbb.last_update_date  = SYSDATE                        -- �ŏI�X�V��
              ,xbb.last_update_login = APPS.FND_GLOBAL.LOGIN_ID       -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.supplier_code        = it_check_data(in_index).vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_yes
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      -------------------------------------------------
      -- 11.�Ɩ��Ǘ����ڋq�ۗ��X�V����
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.resv_flag              = cv_yes                    -- �ۗ��t���O
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                   -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_no
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      ELSIF ( gv_dept_flg =  cv_act_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.resv_flag              = NULL                      -- �ۗ��t���O
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                   -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_yes
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      -------------------------------------------------
      -- 12.���_�ڋq�c������X�V����
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type2 ) THEN
        -- �X�V����
        FORALL i IN 1 .. l_bm_bel_cancel_tab.COUNT
          UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
          SET    xbb.expect_payment_amt_tax = cn_zero                    -- �x���\��z
                ,xbb.payment_amt_tax        = xbb.expect_payment_amt_tax -- �x���z
                ,xbb.publication_date       = it_check_data(in_index).pay_date -- �ē���������
                ,xbb.fb_interface_status    = cv_fb_if_type1             -- �A�g�X�e�[�^�X�i�{�U�pFB�j
                ,xbb.fb_interface_date      = gd_proc_date               -- �A�g���i�{�U�pFB�j
                ,xbb.edi_interface_status   = cv_fb_if_type1             -- �A�g�X�e�[�^�X�iEDI�x���ē����j
                ,xbb.edi_interface_date     = gd_proc_date               -- �A�g���iEDI�x���ē����j
                ,xbb.gl_interface_status    = cv_fb_if_type1             -- �A�g�X�e�[�^�X�iGL�j
                ,xbb.gl_interface_date      = gd_proc_date               -- �A�g���iGL�j
                ,xbb.return_flag            = NULL                       -- �g�ݖ߂��t���O
                ,xbb.balance_cancel_date    = gd_proc_date               -- �c�������
                ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID    -- �ŏI�X�V��
                ,xbb.last_update_date       = SYSDATE                    -- �ŏI�X�V��
                ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID   -- �ŏI�X�V���O�C��ID
                ,xbb.request_id             = cn_request_id              -- ���N�G�X�gID
                ,xbb.program_application_id = cn_prg_appl_id             -- �v���O�����A�v��ID
                ,xbb.program_id             = cn_program_id              -- �v���O����ID
                ,xbb.program_update_date    = SYSDATE                    -- �v���O�����X�V��
          WHERE  xbb.rowid       = l_bm_bel_cancel_tab(i);
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      -------------------------------------------------
      -- 13.���_�ڋq�ۗ��X�V����
      -------------------------------------------------
      ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type3 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.resv_flag              = cv_yes                    -- �ۗ��t���O
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                   -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.base_code            = gv_dept_bel_code
        AND    xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_no
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
            ( it_check_data(in_index).customer_code IS NOT NULL ) AND
            ( it_check_data(in_index).proc_type = cv_proc_type4 ) THEN
        -- �X�V����
        UPDATE xxcok_backmargin_balance xbb -- �̎�c���e�[�u��
        SET    xbb.resv_flag              = NULL                      -- �ۗ��t���O
              ,xbb.last_updated_by        = APPS.FND_GLOBAL.USER_ID   -- �ŏI�X�V��
              ,xbb.last_update_date       = SYSDATE                   -- �ŏI�X�V��
              ,xbb.last_update_login      = APPS.FND_GLOBAL.LOGIN_ID  -- �ŏI�X�V���O�C��ID
              ,xbb.request_id             = cn_request_id             -- ���N�G�X�gID
              ,xbb.program_application_id = cn_prg_appl_id            -- �v���O�����A�v��ID
              ,xbb.program_id             = cn_program_id             -- �v���O����ID
              ,xbb.program_update_date    = SYSDATE                   -- �v���O�����X�V��
        WHERE  xbb.base_code            = gv_dept_bel_code
        AND    xbb.cust_code            = it_check_data(in_index).customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date  = it_check_data(in_index).pay_date
        AND    xbb.expect_payment_date <= it_check_data(in_index).pay_date
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    NVL( xbb.resv_flag,'N' ) = cv_yes
        AND    xbb.fb_interface_status  = cv_fb_if_type0;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
        --�G���[���e�ݒ�
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
        RAISE update_err_expt;
    END;
  --
  EXCEPTION
    -- *** ���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--      -- ���b�Z�[�W�擾
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_ap_type_xxcok
--                      ,iv_name         => cv_errmsg_00053
--                    );    
--      -- ���b�Z�[�W�o��
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
--                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
--                      ,in_new_line   => cn_one          -- ���s
--                    );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_lock;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- *** �X�V��O�n���h�� ***
    WHEN update_err_expt THEN
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--      -- ���b�Z�[�W�擾
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_ap_type_xxcok
--                      ,iv_name         => cv_errmsg_00054
--                    );
--      -- ���b�Z�[�W�o��
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
--                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
--                      ,in_new_line   => cn_one          -- ���s
--                    );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_update;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
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
  END upd_bm_balance_data;
  --
  /**********************************************************************************
   * Procedure Name   : chk_validate_item�i���[�v���j
   * Description      : �Ó����`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
     ov_errbuf   OUT VARCHAR2                                          -- �G���[�E���b�Z�[�W
    ,ov_retcode  OUT VARCHAR2                                          -- ���^�[���E�R�[�h
    ,ov_errmsg   OUT VARCHAR2                                          -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_index    IN  PLS_INTEGER                                       -- �s�ԍ�
    ,iv_segment1 IN  VARCHAR2                                          -- �`�F�b�N�O����1�F�d����R�[�h
    ,iv_segment2 IN  VARCHAR2                                          -- �`�F�b�N�O����2�F�ڋq�R�[�h
    ,iv_segment3 IN  VARCHAR2                                          -- �`�F�b�N�O����3�F�x����
    ,iv_segment4 IN  VARCHAR2                                          -- �`�F�b�N�O����4�F�x�����z
    ,iv_segment5 IN  VARCHAR2                                          -- �`�F�b�N�O����5�F�����^�C�v
    ,ov_segment1 OUT po_vendors.segment1%TYPE                          -- �`�F�b�N�㍀��1�F�d����R�[�h
    ,ov_segment2 OUT hz_cust_accounts.account_number%TYPE              -- �`�F�b�N�㍀��2�F�ڋq�R�[�h
    ,ov_segment3 OUT xxcok_backmargin_balance.expect_payment_date%TYPE -- �`�F�b�N�㍀��3�F�x����
    ,ov_segment4 OUT xxcok_backmargin_balance.backmargin%TYPE          -- �`�F�b�N�㍀��4�F�x�����z
    ,ov_segment5 OUT xxcok_backmargin_balance.resv_flag%TYPE           -- �`�F�b�N�㍀��5�F�����^�C�v
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);                                    -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);                                       -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_cnt           NUMBER;                                            -- �J�E���^
    lb_retcode       BOOLEAN;                                           -- API���^�[���E���b�Z�[�W�p
    lb_retbool       BOOLEAN;                                           -- API���^�[���E�`�F�b�N�p
    lv_out_msg       VARCHAR2(2000);                                    -- ���b�Z�[�W
    ln_pay_chk_flg   VARCHAR2(1) := '0';                                -- �x�����z�`�F�b�N�p(0:�G���[,1:����)
    lv_recv_type     VARCHAR2(1) := NULL;                               -- �ۗ��E�ۗ��������f�p
    -- �`�F�b�N����
    lv_vendor_code   po_vendors.segment1%TYPE;                          -- �d����R�[�h
    lv_customer_code hz_cust_accounts.account_number%TYPE;              -- �ڋq�R�[�h
    ld_pay_date      xxcok_backmargin_balance.expect_payment_date%TYPE; -- �x����
    ln_pay_amount    xxcok_backmargin_balance.backmargin%TYPE;          -- �x�����z
    lv_proc_type     xxcok_backmargin_balance.resv_flag%TYPE;           -- �����敪
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    ln_amt_nofix_cnt NUMBER;                                            -- ���z�m��
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- ���o����
    lv_hold_pay_flg  po_vendor_sites_all.hold_all_payments_flag%TYPE;   -- �S�x���ۗ��t���O
    lv_pay_type      po_vendor_sites_all.attribute4%TYPE;               -- BM�x���敪
    ln_pay_sum_amt   xxcok_backmargin_balance.backmargin%TYPE;          -- �̎�c���x�����z
    --===============================
    -- ���[�J���J�[�\��
    --===============================
    -- �Ɩ��Ǘ����`�F�b�N�p�J�[�\����`
    CURSOR customer_bm_chk_cur1 (
       iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- �ڋq�R�[�h
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
      ,id_proc_date     IN DATE                                              -- �Ɩ��������t
      ,iv_recv_type     IN VARCHAR2 -- �ۗ��E�ۗ�����
    ) IS
      SELECT xbb.cust_code              AS customer_code -- �ڋq�R�[�h
            ,xbb.supplier_code          AS vendor_code   -- �d����R�[�h
            ,pva.hold_all_payments_flag AS hold_pay_flg  -- �S�x���ۗ�
            ,NVL( pva.attribute4,'X' )  AS pay_type      -- BM�x���敪
      FROM   xxcok_backmargin_balance xbb
            ,po_vendors               pvs
            ,po_vendor_sites_all      pva
      WHERE  xbb.cust_code                                        = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date                              = TRUNC( id_pay_date )
      AND    xbb.expect_payment_date                             <= TRUNC( id_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' )                             = iv_recv_type
      AND    xbb.fb_interface_status                              = cv_zero
      AND    pvs.segment1                                         = xbb.supplier_code
      AND    pvs.enabled_flag                                     = cv_yes
      AND    pvs.vendor_id                                        = pva.vendor_id
      AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > id_proc_date
      AND    pva.org_id                                           = gn_org_id
      GROUP BY xbb.cust_code
              ,xbb.supplier_code
              ,pva.hold_all_payments_flag
              ,pva.attribute4;
    -- �Ɩ��Ǘ����`�F�b�N�p���R�[�h��`
    customer_bm_chk_rec1 customer_bm_chk_cur1%ROWTYPE;
    -- ���_�`�F�b�N�p�J�[�\����`
    CURSOR customer_bm_chk_cur2 (
       iv_base_code     IN xxcok_backmargin_balance.base_code%TYPE           -- ��������R�[�h
      ,iv_customer_code IN hz_cust_accounts.account_number%TYPE              -- �ڋq�R�[�h
      ,id_pay_date      IN xxcok_backmargin_balance.expect_payment_date%TYPE -- �x����
      ,id_proc_date     DATE                                                 -- �Ɩ��������t
      ,iv_recv_type     VARCHAR2                                             -- �ۗ��E�ۗ�����
    ) IS
      SELECT xbb.cust_code              AS customer_code -- �ڋq�R�[�h
            ,xbb.supplier_code          AS vendor_code   -- �d����R�[�h
            ,pva.hold_all_payments_flag AS hold_pay_flg  -- �S�x���ۗ�
            ,NVL( pva.attribute4,'X' )  AS pay_type      -- BM�x���敪
      FROM   xxcok_backmargin_balance xbb
            ,po_vendors               pvs
            ,po_vendor_sites_all      pva
      WHERE  xbb.base_code                                        = iv_base_code
      AND    xbb.cust_code                                        = iv_customer_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--      AND    xbb.expect_payment_date                              = TRUNC( id_pay_date )
      AND    xbb.expect_payment_date                             <= TRUNC( id_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
      AND    NVL( xbb.resv_flag,'N' )                             = iv_recv_type
      AND    xbb.fb_interface_status                              = cv_zero
      AND    pvs.segment1                                         = xbb.supplier_code
      AND    pvs.enabled_flag                                     = cv_yes
      AND    pvs.vendor_id                                        = pva.vendor_id
      AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > id_proc_date
      AND    pva.org_id                                           = gn_org_id
      GROUP BY xbb.cust_code
              ,xbb.supplier_code
              ,pva.hold_all_payments_flag
              ,pva.attribute4;
    -- ���_�`�F�b�N�p���R�[�h��`
    customer_bm_chk_rec2 customer_bm_chk_cur2%ROWTYPE;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.�Ɩ��Ǘ��������敪�`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( gv_dept_flg =  cv_act_dept ) THEN
      -- �Ɩ��Ǘ��������敪�`�F�b�N
      IF ( iv_segment5 = cv_proc_type1 ) OR
         ( iv_segment5 = cv_proc_type2 ) OR
         ( iv_segment5 = cv_proc_type3 ) OR
         ( iv_segment5 = cv_proc_type4 ) THEN
        -- �����敪��ޔ�
        lv_proc_type := iv_segment5;
      ELSE
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10218
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 2.���_�����敪�`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( gv_dept_flg =  cv_bel_dept ) THEN
      -- ���_�����敪�`�F�b�N
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--      IF ( iv_segment5 = cv_proc_type3 ) OR
      IF ( iv_segment5 = cv_proc_type2 ) OR
         ( iv_segment5 = cv_proc_type3 ) OR
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
         ( iv_segment5 = cv_proc_type4 ) THEN
        -- �����敪��ޔ�
        lv_proc_type := iv_segment5;
      ELSE
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10219
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 3.�d����R�[�h���p�p�����`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment1 IS NOT NULL ) THEN
      -- ���p�p�����`�F�b�N
      lb_retbool := xxccp_common_pkg.chk_alphabet_number_only( iv_segment1 );
      -- �d����R�[�h���p�p�����`�F�b�N
      IF ( lb_retbool = FALSE ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10224
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 4.�d����R�[�h�����`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment1 IS NOT NULL ) AND
       ( lb_retbool = TRUE ) THEN
      -- �����J�E���g
      ln_cnt := LENGTHB( iv_segment1 );
      -- �d����R�[�h�����`�F�b�N
      IF ( ln_cnt <> cn_vend_len ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10226
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 5.�ڋq�R�[�h���p�p�����`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment2 IS NOT NULL ) THEN
      -- ���p�p�����`�F�b�N
      lb_retbool := xxccp_common_pkg.chk_alphabet_number_only( iv_segment2 );
      -- �ڋq�R�[�h���p�p�����`�F�b�N
      IF ( lb_retbool = FALSE ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10225
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 6.�ڋq�R�[�h�����`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment2 IS NOT NULL ) AND
       ( lb_retbool = TRUE ) THEN
      -- �����J�E���g
      ln_cnt := LENGTHB( iv_segment2 );
      -- �ڋq�R�[�h�����`�F�b�N
      IF ( ln_cnt <> cn_cust_len ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10227
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 7.�x���������`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment3 IS NOT NULL ) THEN
      -- ���t�ϊ�
      BEGIN
        ld_pay_date := fnd_date.canonical_to_date( iv_segment3 );
      EXCEPTION
        WHEN OTHERS THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10228
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
      END;
    END IF;
    -------------------------------------------------
    -- 8.�x�����z���p�����`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment4 IS NOT NULL ) THEN
      -- ���p�����`�F�b�N
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--      lb_retbool := xxccp_common_pkg.chk_number( iv_segment4 );
      BEGIN
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        lb_retbool    := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          lb_retbool := FALSE;
      END;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      -- �x�����z���p�����`�F�b�N
      IF ( lb_retbool = TRUE ) THEN
        -- �x�����z�`�F�b�N����
        ln_pay_chk_flg := cv_one;
      ELSE
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10229
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
    END IF;
    -------------------------------------------------
    -- 9.�x�����z�����`�F�b�N�i���ʁj
    -------------------------------------------------
    IF ( iv_segment4 IS NOT NULL ) AND
       ( ln_pay_chk_flg = cv_one ) THEN
      -- �����J�E���g
      ln_cnt := LENGTHB( TO_NUMBER( iv_segment4 ) );
      -- �x�����z�����`�F�b�N
      IF ( ln_cnt > cn_pay_amt_len ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10230
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
        -- �x�����z�`�F�b�N�G���[
        ln_pay_chk_flg := cv_zero;
      END IF;
    END IF;
    -------------------------------------------------
    -- 10.����t���O�E�����敪����
    -------------------------------------------------
    -- �Ɩ��Ǘ������g�ݖ߂��̏ꍇ
    IF ( gv_dept_flg = cv_act_dept ) AND
       ( lv_proc_type = cv_proc_type1 ) THEN
      -------------------------------------------------
      -- 1.�K�{�`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( iv_segment1 IS NULL ) OR
         ( iv_segment3 IS NULL ) OR
         ( iv_segment4 IS NULL ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10220
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.�x�����z�l�`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( iv_segment4 IS NOT NULL ) AND
         ( ln_pay_chk_flg = cv_one ) THEN
        -- ���l�ϊ�
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        -- �x�����z�l�`�F�b�N
        IF ( ln_pay_amount = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10231
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
          -- �x�����z�`�F�b�N�G���[
          ln_pay_chk_flg := cv_zero;
        END IF;
      END IF;
      -------------------------------------------------
      -- 3.�d���摶�݃`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- �d����m�F
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- �d����R�[�h
                ,pva.hold_all_payments_flag AS hold_pay_flg -- �S�x���ۗ��t���O
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM�x���敪
          INTO   lv_vendor_code  -- �d����R�[�h
                ,lv_hold_pay_flg -- �S�x���ۗ��t���O
                ,lv_pay_type     -- BM�x���敪
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- �d���摶�݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 4.BM�x���敪�L���`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM�x���敪�L���`�F�b�N
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10234
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 5.�x���ۗ��L���`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- �x���ۗ��L���`�F�b�N
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.�̎�c�����݃`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- �̎�c���m�F
        BEGIN
          SELECT xbb.supplier_code          AS supplier_code -- �d����R�[�h
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--                ,xbb.expect_payment_date    AS payment_date  -- �x���\���
                ,xbb.publication_date       AS publication_date  -- �ē���������
                ,SUM( xbb.payment_amt_tax ) AS payment_amt   -- �x���z
          INTO   lv_vendor_code -- �d����R�[�h
--                ,ld_pay_date    -- �x���\���
                ,ld_pay_date    -- �ē���������
                ,ln_pay_sum_amt -- �x���\��z
          FROM   xxcok_backmargin_balance xbb
          WHERE  xbb.supplier_code       = lv_vendor_code
--          AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
          AND    xbb.publication_date    = TRUNC( ld_pay_date )
          AND    xbb.resv_flag           IS NULL
          AND    xbb.fb_interface_status = cv_one
          GROUP BY xbb.supplier_code
--                  ,xbb.expect_payment_date;
                  ,xbb.publication_date;
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        EXCEPTION
          -- �̎�c�����݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10239
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => lv_vendor_code
                            ,iv_token_name2  => cv_tkn_pay_date
                            ,iv_token_value2 => ld_pay_date
                            ,iv_token_name3  => cv_tkn_pay_amt
                            ,iv_token_value3 => ln_pay_amount
                            ,iv_token_name4  => cv_tkn_row_num
                            ,iv_token_value4 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 7.�̎�c���g�ݍ��킹�`�F�b�N�i�g�ݖ߂��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- �̎�c���g�ݍ��킹�`�F�b�N
        IF ( ln_pay_amount <> ln_pay_sum_amt ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10239
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_pay_amt
                          ,iv_token_value3 => ln_pay_amount
                          ,iv_token_name4  => cv_tkn_row_num
                          ,iv_token_value4 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
    -- �Ɩ��Ǘ������c������̏ꍇ
    ELSIF ( gv_dept_flg = cv_act_dept ) AND
          ( lv_proc_type = cv_proc_type2 ) THEN
      -------------------------------------------------
      -- 1.�K�{�`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( iv_segment1 IS NULL ) OR
         ( iv_segment3 IS NULL ) OR
         ( iv_segment4 IS NULL ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10221
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.�x�����z�l�`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( iv_segment4 IS NOT NULL ) AND
         ( ln_pay_chk_flg = cv_one ) THEN
        -- ���l�ϊ�
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        -- �x�����z�l�`�F�b�N
        IF ( ln_pay_amount = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10231
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
          -- �x�����z�`�F�b�N�G���[
          ln_pay_chk_flg := cv_zero;
        END IF;
      END IF;
      -------------------------------------------------
      -- 3.�d���摶�݃`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- �d����m�F
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- �d����R�[�h
                ,pva.hold_all_payments_flag AS hold_pay_flg -- �S�x���ۗ��t���O
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM�x���敪
          INTO   lv_vendor_code  -- �d����R�[�h
                ,lv_hold_pay_flg -- �S�x���ۗ��t���O
                ,lv_pay_type     -- BM�x���敪
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- �d���摶�݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 4.BM�x���敪�L���`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM�x���敪�L���`�F�b�N
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) AND
           ( lv_pay_type <> cv_pay_type3 ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10235
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 5.�x���ۗ��L���`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- �x���ۗ��L���`�F�b�N
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.�̎�c�����݃`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- �̎�c���m�F
        BEGIN
          SELECT xbb.supplier_code                 AS supplier_code -- �d����R�[�h
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--                ,xbb.expect_payment_date           AS payment_date  -- �x���\���
                ,SUM( xbb.expect_payment_amt_tax ) AS payment_amt   -- �x���\��z
          INTO   lv_vendor_code -- �d����R�[�h
--                ,ld_pay_date    -- �x���\���
                ,ln_pay_sum_amt -- �x���\��z
          FROM   xxcok_backmargin_balance xbb
          WHERE  xbb.supplier_code       = lv_vendor_code
--          AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
          AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
          AND    xbb.resv_flag           IS NULL
          AND    xbb.fb_interface_status = cv_zero
--          GROUP BY xbb.supplier_code
--                  ,xbb.expect_payment_date;
          GROUP BY xbb.supplier_code;
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        EXCEPTION
          -- �̎�c�����݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10240
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => lv_vendor_code
                            ,iv_token_name2  => cv_tkn_pay_date
                            ,iv_token_value2 => ld_pay_date
                            ,iv_token_name3  => cv_tkn_pay_amt
                            ,iv_token_value3 => ln_pay_amount
                            ,iv_token_name4  => cv_tkn_row_num
                            ,iv_token_value4 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 7.�̎�c���g�ݍ��킹�`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- �̎�c���g�ݍ��킹�`�F�b�N
        IF ( ln_pay_amount <> ln_pay_sum_amt ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10240
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_pay_amt
                          ,iv_token_value3 => ln_pay_amount
                          ,iv_token_name4  => cv_tkn_row_num
                          ,iv_token_value4 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
    -- �Ɩ��Ǘ������ۗ��E�ۗ������̏ꍇ
    ELSIF ( gv_dept_flg =  cv_act_dept ) AND
          (( lv_proc_type = cv_proc_type3 ) OR ( lv_proc_type = cv_proc_type4 )) THEN
      -------------------------------------------------
      -- 1.�K�{�`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF (( iv_segment1 IS NULL ) AND ( iv_segment2 IS NULL )) OR
         (( iv_segment1 IS NOT NULL ) AND ( iv_segment2 IS NOT NULL )) OR
         ( iv_segment3 IS NULL ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10222
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.�d���摶�݃`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- �d����m�F
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- �d����R�[�h
                ,pva.hold_all_payments_flag AS hold_pay_flg -- �S�x���ۗ��t���O
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM�x���敪
          INTO   lv_vendor_code     -- �d����R�[�h
                ,lv_hold_pay_flg -- �S�x���ۗ��t���O
                ,lv_pay_type     -- BM�x���敪
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- �d���摶�݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 3.BM�x���敪�L���`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- BM�x���敪�L���`�F�b�N
        IF ( lv_pay_type <> cv_pay_type1 ) AND
           ( lv_pay_type <> cv_pay_type2 ) AND
           ( lv_pay_type <> cv_pay_type3 ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10236
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 4.�x���ۗ��L���`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- �x���ۗ��L���`�F�b�N
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 5.�̎�c�����݃`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( lv_proc_type   =  cv_pay_type3 ) THEN
        -- �̎�c���m�F
        SELECT COUNT('X')
        INTO   ln_cnt
        FROM   xxcok_backmargin_balance xbb
        WHERE  xbb.supplier_code       = lv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
        AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NULL
        AND    xbb.fb_interface_status = cv_zero;
        -- �̎�c�����݃`�F�b�N
        IF ( ln_cnt = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10241
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.�̎�c�����݃`�F�b�N�i�Ɩ��Ǘ����ۗ������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( lv_proc_type   =  cv_pay_type4 ) THEN
        -- �̎�c���m�F
        SELECT COUNT('X')
        INTO   ln_cnt
        FROM   xxcok_backmargin_balance xbb
        WHERE  xbb.supplier_code       = lv_vendor_code
-- Start 2009/05/29 Ver_1.2 T1_1139 M.Hiruta
--        AND    xbb.expect_payment_date = TRUNC( ld_pay_date )
        AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
-- End   2009/05/29 Ver_1.2 T1_1139 M.Hiruta
        AND    xbb.resv_flag           IS NOT NULL
        AND    xbb.fb_interface_status = cv_zero;
        -- �̎�c�����݃`�F�b�N
        IF ( ln_cnt = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10241
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 7.�ڋq���݃`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( iv_segment2 IS NOT NULL ) THEN
        -- �ڋq�m�F
        BEGIN
          SELECT hza.account_number
          INTO   lv_customer_code
          FROM   hz_cust_accounts hza
          WHERE  hza.account_number = iv_segment2;
        EXCEPTION
          -- �ڋq���݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10233
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 8.�̎�c�����݃`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( lv_customer_code IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
         ( lv_proc_type     IS NOT NULL ) THEN
        -- �ۗ��E�ۗ���������
        IF ( lv_proc_type   =  cv_pay_type3 ) THEN
          -- �ۗ�
          lv_recv_type := cv_no;
        ELSE
          -- �ۗ�����
          lv_recv_type := cv_yes;
        END IF;
        -- �̎�c���`�F�b�N�J�[�\��
        OPEN customer_bm_chk_cur1 (
           lv_customer_code -- �ڋq�R�[�h
          ,ld_pay_date      -- �x����
          ,gd_proc_date     -- �Ɩ��������t
          ,lv_recv_type     -- �ۗ��E�ۗ�����
        );
        LOOP
          FETCH customer_bm_chk_cur1 INTO customer_bm_chk_rec1;
          EXIT WHEN customer_bm_chk_cur1%NOTFOUND;
          -------------------------------------------------
          -- 9.BM�x���敪�L���`�F�b�N�i�Ɩ��Ǘ����ۗ��j
          -------------------------------------------------
          -- BM�x���敪�L���`�F�b�N
          IF ( customer_bm_chk_rec1.pay_type <> cv_pay_type1 ) AND
             ( customer_bm_chk_rec1.pay_type <> cv_pay_type2 ) AND
             ( customer_bm_chk_rec1.pay_type <> cv_pay_type3 ) THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10237
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec1.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
          END IF;
          -------------------------------------------------
          -- 10.�x���ۗ��L���`�F�b�N�i�Ɩ��Ǘ����ۗ��j
          -------------------------------------------------
          -- �x���ۗ��L���`�F�b�N
          IF ( customer_bm_chk_rec1.hold_pay_flg = cv_yes ) THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10238
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec1.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
          END IF;
        END LOOP;
        -- �̎�c���`�F�b�N
        IF ( customer_bm_chk_cur1%ROWCOUNT = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10242
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
        -- �J�[�\���N���[�Y
        CLOSE customer_bm_chk_cur1;
      END IF;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- ���_���c������̏ꍇ
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          ( lv_proc_type = cv_proc_type2 ) THEN
      -------------------------------------------------
      -- 1.�K�{�`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( iv_segment1 IS NULL ) OR
         ( iv_segment2 IS NULL ) OR
         ( iv_segment3 IS NULL ) OR
         ( iv_segment4 IS NULL ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10456
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.�x�����z�l�`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( iv_segment4 IS NOT NULL ) AND
         ( ln_pay_chk_flg = cv_one ) THEN
        -- ���l�ϊ�
        ln_pay_amount := TO_NUMBER( iv_segment4 );
        -- �x�����z�l�`�F�b�N
        IF ( ln_pay_amount = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10231
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
          -- �x�����z�`�F�b�N�G���[
          ln_pay_chk_flg := cv_zero;
        END IF;
      END IF;
      -------------------------------------------------
      -- 3.�d���摶�݃`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( iv_segment1 IS NOT NULL ) THEN
        -- �d����m�F
        BEGIN
          SELECT pvs.segment1               AS vendor_code  -- �d����R�[�h
                ,pva.hold_all_payments_flag AS hold_pay_flg -- �S�x���ۗ��t���O
                ,NVL( pva.attribute4,'X' )  AS pay_type     -- BM�x���敪
          INTO   lv_vendor_code  -- �d����R�[�h
                ,lv_hold_pay_flg -- �S�x���ۗ��t���O
                ,lv_pay_type     -- BM�x���敪
          FROM   po_vendors          pvs
                ,po_vendor_sites_all pva
          WHERE  pvs.segment1                                         = iv_segment1
          AND    pvs.enabled_flag                                     = cv_yes
          AND    pvs.vendor_id                                        = pva.vendor_id
          AND    TRUNC( NVL( pva.inactive_date, gd_proc_date + 1 ) )  > gd_proc_date
          AND    pva.org_id                                           = gn_org_id;
        EXCEPTION
          -- �d���摶�݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10232
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 4.�ڋq���݃`�F�b�N�i�Ɩ��Ǘ����ۗ��j
      -------------------------------------------------
      IF ( iv_segment2 IS NOT NULL ) THEN
        -- �ڋq�m�F
        BEGIN
          SELECT hza.account_number
          INTO   lv_customer_code
          FROM   hz_cust_accounts hza
          WHERE  hza.account_number = iv_segment2;
        EXCEPTION
          -- �ڋq���݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10233
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 5.�x���ۗ��L���`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) THEN
        -- �x���ۗ��L���`�F�b�N
        IF ( lv_hold_pay_flg = cv_yes ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10238
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_row_num
                          ,iv_token_value2 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 6.�̎�c�����݃`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code   IS NOT NULL ) AND
         ( lv_customer_code IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
         ( lv_proc_type     IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- �̎�c���m�F
        BEGIN
          SELECT xbb.supplier_code                 AS supplier_code -- �d����R�[�h
                ,SUM( xbb.expect_payment_amt_tax ) AS payment_amt   -- �x���\��z
                ,SUM( DECODE(  xbb.amt_fix_status
                              ,cv_zero, cn_one
                              ,cn_zero
                      )
                 )                                 AS amt_nofix_cnt -- ���z���m�茏��
          INTO   lv_vendor_code   -- �d����R�[�h
                ,ln_pay_sum_amt   -- �x���\��z
                ,ln_amt_nofix_cnt -- ���z���m�茏��
          FROM   xxcok_backmargin_balance xbb  -- �̎�c��
          WHERE  xbb.supplier_code       = lv_vendor_code
          AND    xbb.expect_payment_date <= TRUNC( ld_pay_date )
          AND    xbb.resv_flag           IS NULL
          AND    xbb.fb_interface_status = cv_zero
          AND    xbb.base_code           = gv_dept_bel_code
          AND    xbb.cust_code           = lv_customer_code
          GROUP BY xbb.supplier_code
                  ,xbb.cust_code;
        EXCEPTION
          -- �̎�c�����݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10457
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => lv_vendor_code
                            ,iv_token_name2  => cv_tkn_cust_code
                            ,iv_token_value2 => lv_customer_code
                            ,iv_token_name3  => cv_tkn_pay_date
                            ,iv_token_value3 => ld_pay_date
                            ,iv_token_name4  => cv_tkn_pay_amt
                            ,iv_token_value4 => ln_pay_amount
                            ,iv_token_name5  => cv_tkn_row_num
                            ,iv_token_value5 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 7.���z���m��`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        --���z���m��`�F�b�N
        IF ( ln_amt_nofix_cnt <> cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10458
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_cust_code
                          ,iv_token_value2 => lv_customer_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => ld_pay_date
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
      -------------------------------------------------
      -- 8.�̎�c���g�ݍ��킹�`�F�b�N�i�c������j
      -------------------------------------------------
      IF ( lv_vendor_code IS NOT NULL ) AND
         ( ld_pay_date    IS NOT NULL ) AND
         ( ln_pay_sum_amt IS NOT NULL ) AND
         ( lv_proc_type   IS NOT NULL ) AND
         ( ln_pay_chk_flg =  cv_one ) THEN
        -- �̎�c���g�ݍ��킹�`�F�b�N
        IF ( ln_pay_amount <> ln_pay_sum_amt ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10457
                          ,iv_token_name1  => cv_tkn_vend_code
                          ,iv_token_value1 => lv_vendor_code
                          ,iv_token_name2  => cv_tkn_cust_code
                          ,iv_token_value2 => lv_customer_code
                          ,iv_token_name3  => cv_tkn_pay_date
                          ,iv_token_value3 => ld_pay_date
                          ,iv_token_name4  => cv_tkn_pay_amt
                          ,iv_token_value4 => ln_pay_amount
                          ,iv_token_name5  => cv_tkn_row_num
                          ,iv_token_value5 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
      END IF;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- ���_���ۗ��E�ۗ������̏ꍇ
    ELSIF ( gv_dept_flg =  cv_bel_dept ) AND
          (( lv_proc_type = cv_proc_type3 ) OR ( lv_proc_type = cv_proc_type4 )) THEN
      -------------------------------------------------
      -- 1.�K�{�`�F�b�N�i���_�ۗ��j
      -------------------------------------------------
      IF ( iv_segment2 IS NULL ) OR
         ( iv_segment3 IS NULL ) THEN
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok
                        ,iv_name         => cv_errmsg_10223
                        ,iv_token_name1  => cv_tkn_row_num
                        ,iv_token_value1 => in_index
                      );
        -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                        ,in_new_line   => cn_zero         -- ���s
                      );
        -- �Ó����`�F�b�N�G���[
        ov_retcode := cv_status_check;
      END IF;
      -------------------------------------------------
      -- 2.�ڋq���݃`�F�b�N�i���_�ۗ��j
      -------------------------------------------------
      IF ( iv_segment2 IS NOT NULL ) THEN
        -- �ڋq�m�F
        BEGIN
          SELECT hza.account_number
          INTO   lv_customer_code
          FROM   hz_cust_accounts hza
          WHERE  hza.account_number = iv_segment2;
        EXCEPTION
          -- �ڋq���݃`�F�b�N
          WHEN NO_DATA_FOUND THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10233
                            ,iv_token_name1  => cv_tkn_row_num
                            ,iv_token_value1 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
        END;
      END IF;
      -------------------------------------------------
      -- 3.�̎�c�����݃`�F�b�N�i���_�ۗ��j
      -------------------------------------------------
      IF ( lv_customer_code IS NOT NULL ) AND
         ( ld_pay_date      IS NOT NULL ) AND
         ( lv_proc_type     IS NOT NULL ) THEN
        -- �ۗ��E�ۗ���������
        IF ( lv_proc_type   =  cv_pay_type3 ) THEN
          -- �ۗ�
          lv_recv_type := cv_no;
        ELSE
          -- �ۗ�����
          lv_recv_type := cv_yes;
        END IF;
        -- �̎�c���`�F�b�N�J�[�\��
        OPEN customer_bm_chk_cur2 (
           gv_dept_bel_code -- ��������R�[�h
          ,lv_customer_code -- �ڋq�R�[�h
          ,ld_pay_date      -- �x����
          ,gd_proc_date     -- �Ɩ��������t
          ,lv_recv_type     -- �ۗ��E�ۗ�����
        );
        LOOP
          FETCH customer_bm_chk_cur2 INTO customer_bm_chk_rec2;
          EXIT WHEN customer_bm_chk_cur2%NOTFOUND;
          
          -------------------------------------------------
          -- 8.BM�x���敪�L���`�F�b�N�i�Ɩ��Ǘ����ۗ��j
          -------------------------------------------------
          -- BM�x���敪�L���`�F�b�N
          IF ( customer_bm_chk_rec2.pay_type <> cv_pay_type1 ) AND
             ( customer_bm_chk_rec2.pay_type <> cv_pay_type2 ) AND
             ( customer_bm_chk_rec2.pay_type <> cv_pay_type3 ) THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10237
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec2.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
          END IF;
          -------------------------------------------------
          -- 9.�x���ۗ��L���`�F�b�N�i�Ɩ��Ǘ����ۗ��j
          -------------------------------------------------
          -- �x���ۗ��L���`�F�b�N
          IF ( customer_bm_chk_rec2.hold_pay_flg = cv_yes ) THEN
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
            lv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_ap_type_xxcok
                            ,iv_name         => cv_errmsg_10238
                            ,iv_token_name1  => cv_tkn_vend_code
                            ,iv_token_value1 => customer_bm_chk_rec2.vendor_code
                            ,iv_token_name2  => cv_tkn_row_num
                            ,iv_token_value2 => in_index
                          );
            -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
            lb_retcode := xxcok_common_pkg.put_message_f(
                             in_which      => FND_FILE.OUTPUT -- �o�͋敪
                            ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                            ,in_new_line   => cn_zero         -- ���s
                          );
            -- �Ó����`�F�b�N�G���[
            ov_retcode := cv_status_check;
          END IF;
        END LOOP;
        -- �̎�c���`�F�b�N
        IF ( customer_bm_chk_cur2%ROWCOUNT = cn_zero ) THEN
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10242
                          ,iv_token_name1  => cv_tkn_cust_code
                          ,iv_token_value1 => lv_customer_code
                          ,iv_token_name2  => cv_tkn_pay_date
                          ,iv_token_value2 => ld_pay_date
                          ,iv_token_name3  => cv_tkn_row_num
                          ,iv_token_value3 => in_index
                        );
          -- �Ó����`�F�b�N�G���[���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero         -- ���s
                        );
          -- �Ó����`�F�b�N�G���[
          ov_retcode := cv_status_check;
        END IF;
        -- �J�[�\���N���[�Y
        CLOSE customer_bm_chk_cur2;
      END IF;
    END IF;
    -- �������ʑޔ�
    ov_segment1 := lv_vendor_code;   -- �`�F�b�N�㍀��1�F�d����R�[�h
    ov_segment2 := lv_customer_code; -- �`�F�b�N�㍀��2�F�ڋq�R�[�h
    ov_segment3 := ld_pay_date;      -- �`�F�b�N�㍀��3�F�x����
    ov_segment4 := ln_pay_amount;    -- �`�F�b�N�㍀��4�F�x�����z
    ov_segment5 := lv_proc_type;     -- �`�F�b�N�㍀��5�F�����^�C�v
  --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_validate_item;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,in_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    -- �G���[���b�Z�[�W�p
    lv_prof_err    fnd_profile_options.profile_option_name%TYPE := NULL; -- �v���t�@�C���ޔ�
    ln_user_err    fnd_user.user_id%TYPE                        := NULL; -- ���[�UID�ޔ�
    --===============================
    -- ���[�J����O
    --===============================
    get_date_err_expt   EXCEPTION; -- �Ɩ��������t�擾�G���[
    get_prof_err_expt   EXCEPTION; -- �v���t�@�C���擾�G���[
    get_dept_err_expt   EXCEPTION; -- ��������擾�G���[
    get_org_id_err_expt EXCEPTION; -- ��������擾�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    -------------------------------------------------
    -- �R���J�����g�p�����[�^.�t�@�C��ID���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00016
                    ,iv_token_name1  => cv_tkn_file_id
                    ,iv_token_value1 => TO_CHAR(in_file_id)
                  );
    -- �R���J�����g�p�����[�^.�t�@�C��ID���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -- �R���J�����g�p�����[�^.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00017
                    ,iv_token_name1  => cv_tkn_format
                    ,iv_token_value1 => iv_format
                  );
    -- �R���J�����g�p�����[�^.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_one          -- ���s
                  );
    -------------------------------------------------
    -- 2.�Ɩ��������t�擾
    -------------------------------------------------
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    -- NULL�̏ꍇ�̓G���[
    IF ( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    -------------------------------------------------
    -- 3.�Ɩ��Ǘ�������R�[�h�v���t�@�C���擾
    -------------------------------------------------
    gv_dept_act_code := FND_PROFILE.VALUE(cv_dept_act_code);
    -- NULL�̏ꍇ�̓G���[
    IF ( gv_dept_act_code IS NULL ) THEN
      lv_prof_err := cv_dept_act_code;
      RAISE get_prof_err_expt;
    END IF;
    -------------------------------------------------
    -- 4.��������R�[�h�擾
    -------------------------------------------------
    gv_dept_bel_code := xxcok_common_pkg.get_department_code_f(cn_created_by);
    -- NULL�̏ꍇ�̓G���[
    IF ( gv_dept_bel_code IS NULL ) THEN
      ln_user_err := cn_created_by;
      RAISE get_dept_err_expt;
    END IF;
    -------------------------------------------------
    -- 5.���唻��
    -------------------------------------------------
    IF ( gv_dept_act_code = gv_dept_bel_code ) THEN
      gv_dept_flg := cv_act_dept; -- �Ɩ��Ǘ�����ݒ�
    ELSE
      gv_dept_flg := cv_bel_dept; -- �e���_�����ݒ�
    END IF;
    -------------------------------------------------
    -- 6.�c�ƒP��ID�v���t�@�C���擾
    -------------------------------------------------
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_prof_err := cv_prof_org_id;
      RAISE get_prof_err_expt;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �Ɩ��������t�擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00028
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �v���t�@�C���擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_prof_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00003
                      ,iv_token_name1  => cv_tkn_profile
                      ,iv_token_value1 => lv_prof_err
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ��������擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_dept_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00030
                      ,iv_token_name1  => cv_tkn_user_id
                      ,iv_token_value1 => ln_user_err
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);                                    -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);                                       -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);                                    -- ���b�Z�[�W
    lb_retcode       BOOLEAN;                                           -- ���b�Z�[�W�߂�l
    ln_file_id       xxccp_mrp_file_ul_interface.file_id%TYPE;          -- �t�@�C��ID
    lv_format        xxccp_mrp_file_ul_interface.file_format%TYPE;      -- �t�H�[�}�b�g
    -- BLOB�ϊ���f�[�^������ޔ�p
    ln_col_cnt       PLS_INTEGER := 0;                                  -- CSV���ڐ�
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--    ln_row_cnt       PLS_INTEGER := 0;                                  -- CSV�s��
    ln_row_cnt       PLS_INTEGER := 1;                                  -- CSV�s��
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    ln_line_cnt      PLS_INTEGER := 0;                                  -- CSV�����s�J�E���^
    lt_csv_data      xxcok_common_pkg.g_split_csv_tbl;                  -- CSV�����f�[�^
    lt_file_data     xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB�ϊ���f�[�^�ޔ�(�󔒍s�r����)
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    lt_file_data_all xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB�ϊ���f�[�^�ޔ�(�S�f�[�^)
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    lt_check_data    g_check_data_ttype;                                -- �`�F�b�N��f�[�^�ޔ�
    lv_vendor_code   po_vendors.segment1%TYPE;                          -- �d����R�[�h
    lv_customer_code hz_cust_accounts.account_number%TYPE;              -- �ڋq�R�[�h
    ld_pay_date      xxcok_backmargin_balance.expect_payment_date%TYPE; -- �x����
    ln_pay_amount    xxcok_backmargin_balance.backmargin%TYPE;          -- �x�����z
    lv_proc_type     xxcok_backmargin_balance.resv_flag%TYPE;           -- �����^�C�v
    --===============================
    -- ���[�J����O
    --===============================
    blob_err_expt    EXCEPTION; -- BLOB�ϊ��G���[
    no_data_err_expt EXCEPTION; -- �̎�c�����擾�G���[
    proc_err_expt    EXCEPTION; -- �ďo���v���O�����̃G���[
  --
  BEGIN
  --
    --===============================================
    -- A-0.������
    --===============================================
    lv_retcode := cv_status_normal;
    ln_file_id := TO_NUMBER(TRUNC(iv_file_id));
    lv_format  := iv_format;
    lt_file_data.delete;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    lt_file_data_all.delete;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    --===============================================
    -- A-1.��������
    --===============================================
    --
    init_proc(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,in_file_id => ln_file_id -- �t�@�C��ID
      ,iv_format  => lv_format  -- �t�H�[�}�b�g
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-2.�t�@�C���A�b�v���[�h�f�[�^�擾
    --===============================================
    --
    -- 1.BLOB�f�[�^�ϊ�
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => ln_file_id   -- �t�@�C��ID
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--      ,ov_file_data => lt_file_data -- BLOB�ϊ���f�[�^�ޔ�
      ,ov_file_data => lt_file_data_all -- BLOB�ϊ���f�[�^�ޔ�
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      ,ov_errbuf    => lv_errbuf    -- �G���[�E���b�Z�[�W
      ,ov_retcode   => lv_retcode   -- ���^�[���E�R�[�h
      ,ov_errmsg    => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE blob_err_expt;
    END IF;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- �擾�����f�[�^����A�󔒍s(�J���}�݂̂̍s)��r������
    << blob_data_loop >>
    FOR i IN 1..lt_file_data_all.COUNT LOOP
      IF ( LENGTHB( REPLACE( lt_file_data_all(i), ',', '') ) <> cn_zero ) THEN
        ln_line_cnt := ln_line_cnt + cn_one;
        lt_file_data(ln_line_cnt) := lt_file_data_all(i);
      END IF;
    END LOOP blob_data_loop;
    -- �ҏW�p�̃e�[�u���폜
    lt_file_data_all.delete;
    -- CSV�����s�J�E���^������
    ln_line_cnt := cn_zero;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    -- �����Ώی�����ޔ�
    gn_target_cnt := lt_file_data.COUNT - cn_one; -- �w�b�_�[�͏���
    -- �����Ώۑ��݃`�F�b�N
    IF ( gn_target_cnt <= cn_zero ) THEN
      RAISE no_data_err_expt;
    END IF;
    -- 2.BLOB�ϊ���f�[�^�`�F�b�N���[�v
    << blob_data_check_loop >>
    FOR ln_line_cnt IN 2..lt_file_data.COUNT LOOP
      --===============================================
      -- A-3.�t�@�C���A�b�v���[�h�f�[�^�ϊ�
      --===============================================
      --
      -- 1.CSV�����񕪊�
       xxcok_common_pkg.split_csv_data_p(
         ov_errbuf        => lv_errbuf                 -- �G���[�E���b�Z�[�W
        ,ov_retcode       => lv_retcode                -- ���^�[���E�R�[�h
        ,ov_errmsg        => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,iv_csv_data      => lt_file_data(ln_line_cnt) -- CSV������
        ,on_csv_col_cnt   => ln_col_cnt                -- CSV���ڐ�
        ,ov_split_csv_tab => lt_csv_data               -- CSV�����f�[�^
      );
      -- �X�e�[�^�X�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      END IF;
      --
      --===============================================
      -- A-4.�Ó����`�F�b�N����
      --===============================================
      --
      chk_validate_item(
           ov_errbuf   => lv_errbuf             -- �G���[�E���b�Z�[�W
          ,ov_retcode  => lv_retcode            -- ���^�[���E�R�[�h
          ,ov_errmsg   => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,in_index    => ln_line_cnt           -- �s�ԍ�
          ,iv_segment1 => TRIM(lt_csv_data(1))  -- �`�F�b�N�O����1�F�d����R�[�h
          ,iv_segment2 => TRIM(lt_csv_data(2))  -- �`�F�b�N�O����2�F�ڋq�R�[�h
          ,iv_segment3 => TRIM(lt_csv_data(3))  -- �`�F�b�N�O����3�F�x����
          ,iv_segment4 => TRIM(lt_csv_data(4))  -- �`�F�b�N�O����4�F�x�����z
          ,iv_segment5 => TRIM(lt_csv_data(5))  -- �`�F�b�N�O����5�F�����^�C�v
          ,ov_segment1 => lv_vendor_code        -- �`�F�b�N�㍀��1�F�d����R�[�h
          ,ov_segment2 => lv_customer_code      -- �`�F�b�N�㍀��2�F�ڋq�R�[�h
          ,ov_segment3 => ld_pay_date           -- �`�F�b�N�㍀��3�F�x����
          ,ov_segment4 => ln_pay_amount         -- �`�F�b�N�㍀��4�F�x�����z
          ,ov_segment5 => lv_proc_type          -- �`�F�b�N�㍀��5�F�����^�C�v
        );
      --
      --===============================================
      -- A-5.�c���X�V�A�b�v���[�h�f�[�^�̊i�[
      --===============================================
      --
      -- �X�e�[�^�X�G���[����F���펞
      IF ( lv_retcode = cv_status_normal ) THEN
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--        -- ����f�[�^�̍s�����C���N�������g
--        ln_row_cnt := ln_row_cnt + 1;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
        -- ����f�[�^�ޔ�
        lt_check_data(ln_row_cnt).vendor_code   := lv_vendor_code;   -- �d����R�[�h
        lt_check_data(ln_row_cnt).customer_code := lv_customer_code; -- �ڋq�R�[�h
        lt_check_data(ln_row_cnt).pay_date      := ld_pay_date;      -- �x����
        lt_check_data(ln_row_cnt).pay_amount    := ln_pay_amount;    -- �x�����z
        lt_check_data(ln_row_cnt).proc_type     := lv_proc_type;     -- �����^�C�v
      -- �X�e�[�^�X�G���[����F�`�F�b�N�G���[��
      ELSIF ( lv_retcode = cv_status_check ) THEN
        -- ���b�Z�[�W�o��
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- �o�͋敪
                        ,iv_message    => NULL            -- ���b�Z�[�W
                        ,in_new_line   => cn_one          -- ���s
                      );
        -- �G���[�������C���N�������g
        gn_error_cnt := gn_error_cnt + 1;
      -- �X�e�[�^�X�G���[����F�G���[��
      ELSE
        -- �G���[�I��
        RAISE proc_err_expt;
      END IF;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      --===============================================
      -- A-6.�c���̍X�V
      --===============================================
      -- �X�e�[�^�X�G���[����F���펞
      IF ( lv_retcode = cv_status_normal ) THEN
        -- �c���X�V����
        upd_bm_balance_data(
             ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
            ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
            ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--            ,in_index      => ln_line_cnt   -- �s�ԍ�
            ,in_index      => ln_row_cnt    -- �s�ԍ�
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
            ,it_check_data => lt_check_data -- �`�F�b�N��f�[�^
          );
        -- �X�e�[�^�X�G���[����(���b�N�G���[)
        IF ( lv_retcode = cv_status_lock ) THEN
          -- ���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10474
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => ln_line_cnt
                        );
          -- ���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_one          -- ���s
                        );
          -- �G���[�������C���N�������g
          gn_error_cnt := gn_error_cnt + 1;
        -- �X�e�[�^�X�G���[����(�X�V�G���[)
        ELSIF ( lv_retcode = cv_status_update ) THEN
          -- ���b�Z�[�W�擾
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok
                          ,iv_name         => cv_errmsg_10475
                          ,iv_token_name1  => cv_tkn_row_num
                          ,iv_token_value1 => ln_line_cnt
                        );
          -- ���b�Z�[�W�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                          ,in_new_line   => cn_zero          -- ���s
                        );
          -- �G���[���e�o��
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT -- �o�͋敪
                          ,iv_message    => lv_errbuf       -- ���b�Z�[�W
                          ,in_new_line   => cn_one          -- ���s
                        );
          -- �G���[�������C���N�������g
          gn_error_cnt := gn_error_cnt + 1;
        -- �X�e�[�^�X�G���[����(���̑���O)
        ELSIF ( lv_retcode = cv_status_error ) THEN
          -- �G���[�I��
          RAISE proc_err_expt;
        -- �X�e�[�^�X�G���[����(����)
        ELSE
          -- ����I���������C���N�������g
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
      END IF;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
      --
    END LOOP;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
--    --===============================================
--    -- A-6.�c���̍X�V
--    --===============================================
--    --
--    IF ( gn_error_cnt = cn_zero ) THEN
--      << upd_bm_balance_loop >>
--      FOR ln_line_cnt IN 1..lt_check_data.COUNT LOOP
--        -- �c���X�V����
--        upd_bm_balance_data(
--             ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
--            ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
--            ,ov_errmsg     => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
--            ,in_index      => ln_line_cnt   -- �s�ԍ�
--            ,it_check_data => lt_check_data -- �`�F�b�N��f�[�^
--          );
--        -- �X�e�[�^�X�G���[����
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE proc_err_expt;
--        END IF;
--        -- ����I���������C���N�������g
--        gn_normal_cnt := gn_normal_cnt + 1;
--      END LOOP;
--    END IF;
    -- �`�F�b�N�E�X�V�ŃG���[�̏ꍇ�A�X�V�����f�[�^��ROLLBACK(�폜�����������)
    IF ( gn_error_cnt <> cn_zero ) THEN
      ROLLBACK;
    END IF;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    --
    --===============================================
    -- A-7.�t�@�C���A�b�v���[�h�f�[�^�̍폜
    --===============================================
    --
    del_file_upload_data(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      ,in_file_id => ln_file_id -- �t�@�C��ID
    );
    -- �X�e�[�^�X�G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
-- Start 2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    ELSE
      -- �`�F�b�N�E�X�V�G���[�̏ꍇ�A�ُ�I��������̂ł�����COMMIT
      COMMIT;
-- End   2010/01/20 Ver_1.3 E_�{�ғ�_01115 K.Kiriu
    END IF;
    -- �Ó����`�F�b�N�G���[����
    IF ( gn_error_cnt <> cn_zero ) THEN
      RAISE proc_err_expt;
    END IF;
    -- ����I��
    ov_retcode := lv_retcode;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- BLOB�ϊ���O�n���h��
    ----------------------------------------------------------
    WHEN blob_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00041
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(ln_file_id)
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �c���X�V���擾��O�n���h��
    ----------------------------------------------------------
    WHEN no_data_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10217
                    );
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �T�u�v���O������O�n���h��
    ----------------------------------------------------------
    WHEN proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,retcode    OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000);  -- ���b�Z�[�W
    lv_message_code VARCHAR2(5000);  -- �����I�����b�Z�[�W
    lb_retcode      BOOLEAN;         -- ���b�Z�[�W�߂�l
  --
  BEGIN
  --
    --===============================================
    -- ������
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- �R���J�����g�w�b�_�o��
    --===============================================
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => NULL            -- ���b�Z�[�W
                    ,in_new_line   => cn_one          -- ���s
                  );
    --
    --===============================================
    -- �T�u���C������
    --===============================================
    --
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_file_id => iv_file_id -- �t�@�C��ID
      ,iv_format  => iv_format  -- �t�H�[�}�b�g
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[���b�Z�[�W�o��
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- �o�͋敪
                      ,iv_message    => lv_errbuf       -- ���b�Z�[�W
                      ,in_new_line   => cn_one          -- ���s
                    );
      -- �G���[�����������ݒ�
      gn_normal_cnt := cn_zero; -- ���팏��
      gn_error_cnt  := cn_one;  -- �G���[����
    END IF;
    --
    --===============================================
    -- A-8.�I������
    --===============================================
    -------------------------------------------------
    -- 1.�Ώی������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 2.�����������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -------------------------------------------------
    -- 3.�����������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_one          -- ���s
                  );
    -------------------------------------------------
    -- 4.�I�����b�Z�[�W�o��
    -------------------------------------------------
    -- �I�����b�Z�[�W���f
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- ���b�Z�[�W�o��
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- �o�͋敪
                    ,iv_message    => lv_out_msg      -- ���b�Z�[�W
                    ,in_new_line   => cn_zero         -- ���s
                  );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCOK016A01C;
/
