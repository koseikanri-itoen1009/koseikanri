CREATE OR REPLACE PACKAGE BODY XXCOK008A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A05R(body)
 * Description      : �v���̔��s��ʂ���A����U�֊����`�F�b�N���X�g�𒠕[�ɏo�͂��܂��B
 * MD.050           : ����U�֊����`�F�b�N���X�g MD050_COK_008_A05
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ------------------------------------------------------------
 *  Name                         Description
 * --------------------------- ------------------------------------------------------------
 *  init                         ��������(A-1)
 *  get_target_data              �f�[�^�擾(A-2)
 *  ins_rep_selling_trns_chk     ���[�N�e�[�u���f�[�^�o�^(A-3)
 *  start_svf                    SVF�N��(A-4)
 *  del_rep_selling_trns_chk     ���[�N�e�[�u���f�[�^�폜(A-5)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/10/23    1.0   T.Abe            �V�K�쐬
 *  2009/02/02    1.1   T.Abe            [��QCOK_003] �擾�����ɉc�ƒP��ID��ǉ�
 *  2009/03/25    1.2   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/08/26    1.3   M.Hiruta         [��Q0001154] �]�ƈ��}�X�^�̗L�������f�[�^���o�����ɒǉ�
 *
 *****************************************************************************************/
--
  --==========================
  -- �O���[�o���萔
  --==========================
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;         -- PROGRAM_ID
  -- �Z�p���[�^
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOK008A05R';
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_appl             CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl             CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- �v���t�@�C��
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  cv_prof_org_code_sales    CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';    -- �݌ɑg�D�R�[�h_�c�Ƒg�D
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  cv_prof_org_id            CONSTANT VARCHAR2(25)  := 'ORG_ID';                   -- �c�ƒP��ID
  -- ���b�Z�[�W
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  cv_msg_xxcok_00013        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';         -- �݌ɑg�DID�擾�G���[
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  cv_msg_xxcok_00028        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';         -- �Ɩ��������t�擾�G���[
  cv_msg_xxcok_00001        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';         -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_xxcok_00040        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';         -- SVF�N��API�G���['
  cv_msg_xxcok_00003        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';         -- �v���t�@�C���擾�G���[
  cv_msg_xxcok_10412        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10412';         -- ���b�N�擾�G���[
  cv_msg_xxcok_10413        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10413';         -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_xxcok_00082        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00082';         -- ����U�֌����_�R�[�h
  cv_msg_xxcok_00083        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00083';         -- ����U�֌��ڋq�R�[�h
  cv_msg_xxcok_00084        CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00084';         -- ����U�֐拒�_�R�[�h
  cv_msg_xxccp_90000        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';         -- �Ώی���
  cv_msg_xxccp_90001        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';         -- ��������
  cv_msg_xxccp_90002        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';         -- �G���[����
  cv_msg_xxccp_90004        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';         -- ����I��
  cv_msg_xxccp_90006        CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';         -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_token_request_id       CONSTANT VARCHAR2(50)  := 'REQUEST_ID';               -- �v��ID
  cv_token_profile          CONSTANT VARCHAR2(50)  := 'PROFILE';                  -- �v���t�@�C��
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  cv_token_org_code         CONSTANT VARCHAR2(50)  := 'ORG_CODE';                 -- ORG_CODE
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  cv_token_count            CONSTANT VARCHAR2(50)  := 'COUNT';                    -- ����
  cv_token_from_location    CONSTANT VARCHAR2(50)  := 'FROM_LOCATION';            -- ����U�֌����_�R�[�h
  cv_token_from_customer    CONSTANT VARCHAR2(50)  := 'FROM_CUSTOMER';            -- ����U�֌��ڋq�R�[�h
  cv_token_to_location      CONSTANT VARCHAR2(50)  := 'TO_LOCATION';              -- ����U�֐拒�_�R�[�h
  -- �X�y�[�X
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';                        -- �X�y�[�X
  -- �o�͋敪
  cv_which                  CONSTANT VARCHAR2(3)   := 'LOG';                      -- ���O
  -- SVF�N���p�����[�^
  cv_file_id                CONSTANT VARCHAR2(20)  := 'XXCOK008A05R';             -- ���[ID
  cv_output_mode            CONSTANT VARCHAR2(1)   := '1';                        -- �o�͋敪(PDF�o��)
  cv_extension              CONSTANT VARCHAR2(10)  := '.pdf';                     -- �o�̓t�@�C�����g���q(PDF�o��)
  cv_frm_file               CONSTANT VARCHAR2(20)  := 'XXCOK008A05S.xml';         -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(20)  := 'XXCOK008A05S.vrq';         -- �N�G���[�l���t�@�C����
  -- ���l
  cn_0                      CONSTANT NUMBER        := 0;                          -- ���l�F0
  cn_1                      CONSTANT NUMBER        := 1;                          -- ���l�F1
  -- ����
  cv_0                      CONSTANT VARCHAR2(1)   := '0';                        -- �����F'0'
  --==========================
  -- �O���[�o���ϐ�
  --==========================
  -- �����J�E���^
  gn_target_cnt             NUMBER        DEFAULT 0;            -- �Ώی���
  gn_normal_cnt             NUMBER        DEFAULT 0;            -- ���팏��
  gn_error_cnt              NUMBER        DEFAULT 0;            -- �G���[����
  gn_warn_cnt               NUMBER        DEFAULT 0;            -- �X�L�b�v����
  -- �ϐ�
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--  gv_org_code               VARCHAR2(50)  DEFAULT NULL;         -- �v���t�@�C���l(�݌ɑg�D�R�[�h_�c�Ƒg�D)
--  gn_org_id                 NUMBER        DEFAULT NULL;         -- �݌ɑg�DID
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
  gn_org_id_sales           NUMBER        DEFAULT NULL;         -- �c�ƒP��ID
  gd_process_date           DATE          DEFAULT NULL;         -- �Ɩ��������t
  gv_no_data_msg            VARCHAR2(30)  DEFAULT NULL;         -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  --===============================
  -- �O���[�o���J�[�\��
  --===============================
  CURSOR g_target_cur(
    iv_selling_from_base_code IN VARCHAR2    -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN VARCHAR2    -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN VARCHAR2    -- ����U�֐拒�_�R�[�h
  )
  IS
    SELECT  xsri.selling_from_base_code                                    AS selling_from_base_code  -- ����U�֌����_�R�[�h
           ,mkhp.party_name                                                AS selling_from_base_name  -- ����U�֌����_��
           ,xsri.selling_from_cust_code                                    AS selling_from_cust_code  -- ����U�֌��ڋq�R�[�h
           ,mhp.party_name                                                 AS selling_from_cust_name  -- ����U�֌��ڋq��
           ,mjrre.source_number                                            AS selling_from_emp_code   -- ����U�֌��S���c�ƃR�[�h
           ,mpapf.per_information18 || cv_space || mpapf.per_information19 AS selling_from_emp_name   -- ����U�֌��S���c�Ɩ�(�� ��)
           ,xsri.selling_to_cust_code                                      AS selling_to_cust_code    -- ����U�֐�ڋq�R�[�h
           ,shp.party_name                                                 AS selling_to_cust_name    -- ����U�֐�ڋq��
           ,xca.sale_base_code                                             AS selling_to_base_code    -- ����U�֐拒�_�R�[�h
           ,skhp.party_name                                                AS selling_to_base_name    -- ����U�֐拒�_��
           ,sjrre.source_number                                            AS selling_to_emp_code     -- ����U�֐�S���c�ƃR�[�h
           ,spapf.per_information18 || cv_space || spapf.per_information19 AS selling_to_emp_name     -- ����U�֐�S���c�Ɩ�(�� ��)
           ,xsri.selling_trns_rate                                         AS selling_trns_rate       -- ����U�֊���
           ,hl.address3                                                    AS section_code            -- �n��R�[�h
    FROM    xxcok_selling_rate_info    xsri     -- ����U�֊������e�[�u��
           ,hz_cust_accounts           mhca     -- �ڋq�}�X�^(�U�֌�)
           ,hz_cust_accounts           shca     -- �ڋq�}�X�^(�U�֐�)
           ,hz_cust_accounts           mkhca    -- �ڋq�}�X�^(�U�֌����_)
           ,hz_cust_accounts           skhca    -- �ڋq�}�X�^(�U�֐拒�_)
           ,hz_parties                 mkhp     -- �p�[�e�B�}�X�^(�U�֌����_)
           ,hz_parties                 skhp     -- �p�[�e�B�}�X�^(�U�֐拒�_)
           ,hz_parties                 mhp      -- �p�[�e�B�}�X�^(�U�֌��ڋq)
           ,hz_parties                 shp      -- �p�[�e�B�}�X�^(�U�֐�ڋq)
           ,hz_cust_acct_sites_all     hcas     -- �ڋq���ݒn�}�X�^
           ,hz_party_sites             hps      -- �p�[�e�B�T�C�g�}�X�^
           ,hz_locations               hl       -- �ڋq���Ə�
           ,hz_organization_profiles   mhop     -- �g�D�v���t�@�C��(�U�֌�)
           ,hz_organization_profiles   shop     -- �g�D�v���t�@�C��(�U�֐�)
           ,ego_resource_agv           mera     -- �g�D�v���t�@�C���g��View(�U�֌�)
           ,ego_resource_agv           sera     -- �g�D�v���t�@�C���g��View(�U�֐�)
           ,jtf_rs_resource_extns      mjrre    -- ���\�[�X(�U�֌�)
           ,jtf_rs_resource_extns      sjrre    -- ���\�[�X(�U�֐�)
           ,xxcmm_cust_accounts        xca      -- �ڋq�ǉ����
           ,per_all_people_f           mpapf    -- �]�ƈ��}�X�^(�U�֌�)
           ,per_all_people_f           spapf    -- �]�ƈ��}�X�^(�U�֐�)
    WHERE xsri.selling_from_base_code                = NVL( iv_selling_from_base_code, xsri.selling_from_base_code )
    AND   xsri.selling_from_cust_code                = NVL( iv_selling_from_cust_code, xsri.selling_from_cust_code )
    AND   xsri.selling_from_cust_code                               = mhca.account_number
    AND   mhca.party_id                                             = mhp.party_id
    AND   mhca.party_id                                             = mhop.party_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( mhop.effective_start_date )                       <= gd_process_date
    AND   TRUNC( NVL( mhop.effective_start_date, SYSDATE ) )       <= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   mhop.organization_profile_id                              = mera.organization_profile_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( NVL( mhop.effective_end_date, gd_process_date ) ) >= gd_process_date
    AND   TRUNC( NVL( mhop.effective_end_date, SYSDATE ) )         >= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   TRUNC( NVL( mera.resource_s_date, gd_process_date ) )    <= gd_process_date
    AND   TRUNC( NVL( mera.resource_e_date, gd_process_date ) )    >= gd_process_date
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   TRUNC( NVL( mpapf.effective_start_date, gd_process_date ) ) <= gd_process_date
    AND   TRUNC( NVL( mpapf.effective_end_date,   gd_process_date ) ) >= gd_process_date
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   mjrre.source_number                                       = mera.resource_no
    AND   mhca.cust_account_id                                      = hcas.cust_account_id
    AND   hcas.party_site_id                                        = hps.party_site_id
    AND   hcas.org_id                                               = gn_org_id_sales
    AND   hps.location_id                                           = hl.location_id
    AND   xsri.selling_to_cust_code                                 = shca.account_number
    AND   shca.party_id                                             = shp.party_id
    AND   shca.party_id                                             = shop.party_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( shop.effective_start_date )                       <= gd_process_date
    AND   TRUNC( shop.effective_start_date )                       <= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   shop.organization_profile_id                              = sera.organization_profile_id
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--    AND   TRUNC( NVL( shop.effective_end_date, gd_process_date ) ) >= gd_process_date
    AND   TRUNC( NVL( shop.effective_end_date, SYSDATE ) )         >= TRUNC( SYSDATE )
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
    AND   TRUNC( NVL( sera.resource_s_date, gd_process_date ) )    <= gd_process_date
    AND   TRUNC( NVL( sera.resource_e_date, gd_process_date ) )    >= gd_process_date
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   TRUNC( NVL( spapf.effective_start_date, gd_process_date ) ) <= gd_process_date
    AND   TRUNC( NVL( spapf.effective_end_date,   gd_process_date ) ) >= gd_process_date
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta ADD
    AND   sjrre.source_number                                       = sera.resource_no
    AND   xsri.selling_from_base_code                               = mkhca.account_number
    AND   mkhca.party_id                                            = mkhp.party_id
    AND   xsri.invalid_flag                                         = cv_0
    AND   shca.cust_account_id                                      = xca.customer_id
    AND   xca.sale_base_code                                        = NVL( iv_selling_to_base_code, xca.sale_base_code )
    AND   xca.sale_base_code                                        = skhca.account_number
    AND   skhca.party_id                                            = skhp.party_id
    AND   mpapf.employee_number                                     = mjrre.source_number
    AND   spapf.employee_number                                     = sjrre.source_number;
  TYPE g_target_ttype IS TABLE OF g_target_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_target_tab g_target_ttype;
  --=================================
  -- ���ʗ�O
  --=================================
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --*** ���b�N�擾�G���[ ***
  global_lock_err_expt      EXCEPTION;
  --=================================
  -- �v���O�}
  --=================================
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_err_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : del_rep_selling_trns_chk
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-5)
   ***********************************************************************************/
  PROCEDURE del_rep_selling_trns_chk(
    ov_errbuf   OUT VARCHAR2      -- �G���[�E���b�Z�[�W
   ,ov_retcode  OUT VARCHAR2      -- ���^�[���E�R�[�h
   ,ov_errmsg   OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_selling_trns_chk'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode    BOOLEAN        DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��߂�l
    --===============================
    -- ���[�J���J�[�\��
    --===============================
    CURSOR rep_selling_trns_chk_cur
    IS
    SELECT 'X'
    FROM   xxcok_rep_selling_trns_chk  xrstc
    WHERE  xrstc.request_id = cn_request_id
    FOR UPDATE OF xrstc.request_id NOWAIT;
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --===========================================================
    -- ����U�֊����`�F�b�N���X�g���[���[�N�e�[�u�����b�N�擾����
    --===========================================================
    OPEN rep_selling_trns_chk_cur;
    CLOSE rep_selling_trns_chk_cur;
    --===========================================================
    -- ����U�֊����`�F�b�N���X�g���[���[�N�e�[�u���f�[�^�폜����
    --===========================================================
    BEGIN
      DELETE FROM xxcok_rep_selling_trns_chk  xrstc
      WHERE xrstc.request_id = cn_request_id;
      -- ===============================================
      -- ���������擾
      -- ===============================================
      gn_normal_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcok_appl
                       ,iv_name         => cv_msg_xxcok_10413
                       ,iv_token_name1  => cv_token_request_id
                       ,iv_token_value1 => cn_request_id
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG   -- �o�͋敪
                       ,iv_message  => lv_errmsg      -- ���b�Z�[�W
                       ,in_new_line => cn_0           -- ���s
                      );
    END;
  EXCEPTION
    -- *** ���b�N�擾��O�n���h�� ***
    WHEN global_lock_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_10412
                     ,iv_token_name1  => cv_token_request_id
                     ,iv_token_value1 => cn_request_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                     ,iv_message  => lv_errmsg      -- ���b�Z�[�W
                     ,in_new_line => cn_0           -- ���s
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_rep_selling_trns_chk;
--
  /**********************************************************************************
   * Procedure Name   : start_svf
   * Description      : SVF�N��(A-4)
   ***********************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf  OUT VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode OUT VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg  OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf';    -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode    BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_outmsg     VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_date       VARCHAR2(8)    DEFAULT NULL;                 -- �o�̓t�@�C�����p���t
    lv_file_name  VARCHAR2(100)  DEFAULT NULL;                 -- �o�̓t�@�C����
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --====================
    -- �V�X�e�����t�^�ϊ�
    --====================
    lv_date := TO_CHAR( SYSDATE, 'YYYYMMDD' );
    --============================================
    -- �o�̓t�@�C����(���[ID + YYYYMMDD + �v��ID)
    --============================================
    lv_file_name := cv_file_id || lv_date || TO_CHAR( cn_request_id ) || cv_extension;
    --==============================
    -- SVF�N������
    --==============================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                 -- �G���[�o�b�t�@
      , ov_retcode       => lv_retcode                -- ���^�[���R�[�h
      , ov_errmsg        => lv_errmsg                 -- �G���[���b�Z�[�W
      , iv_conc_name     => cv_pkg_name               -- �R���J�����g��
      , iv_file_name     => lv_file_name              -- �o�̓t�@�C����
      , iv_file_id       => cv_file_id                -- ���[ID
      , iv_output_mode   => cv_output_mode            -- �o�͋敪
      , iv_frm_file      => cv_frm_file               -- �t�H�[���l���t�@�C����
      , iv_vrq_file      => cv_vrq_file               -- �N�G���[�l���t�@�C����
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
--      , iv_org_id        => TO_CHAR( gn_org_id )      -- ORG_ID
      , iv_org_id        => NULL                      -- ORG_ID
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta REPAIR
      , iv_user_name     => fnd_global.user_name      -- ���O�C���E���[�U��
      , iv_resp_name     => fnd_global.resp_name      -- ���O�C���E���[�U�E�Ӗ�
      , iv_doc_name      => NULL                      -- ������
      , iv_printer_name  => NULL                      -- �v�����^��
      , iv_request_id    => TO_CHAR( cn_request_id )  -- �v��ID
      , iv_nodata_msg    => NULL                      -- �f�[�^�Ȃ����b�Z�[�W
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                     ,iv_message  => lv_outmsg      -- ���b�Z�[�W
                     ,in_new_line => cn_0           -- ���s
                    );
      RAISE global_api_expt;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END start_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_selling_trns_chk
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE ins_rep_selling_trns_chk(
    ov_errbuf                 OUT VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode                OUT VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg                 OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_selling_from_base_code IN  VARCHAR2     -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN  VARCHAR2     -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN  VARCHAR2     -- ����U�֐拒�_�R�[�h
   ,in_i                      IN  NUMBER       -- �C���f�b�N�X
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'ins_rep_selling_trns_chk'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --==============================
    -- ���[�N�e�[�u���f�[�^�o�^
    --==============================
    IF ( gn_target_cnt <> 0 ) THEN
      INSERT INTO xxcok_rep_selling_trns_chk(
         selling_from_base_code_in          -- ����U�֌����_
        ,selling_from_cust_code_in          -- ����U�֌��ڋq
        ,selling_to_base_code_in            -- ����U�֐拒�_
        ,selling_from_base_code             -- ����U�֌����_�R�[�h
        ,selling_from_base_name             -- ����U�֌����_��
        ,selling_from_cust_code             -- ����U�֌��ڋq�R�[�h
        ,selling_from_cust_name             -- ����U�֌��ڋq��
        ,selling_from_emp_code              -- ����U�֌��S���c�ƃR�[�h
        ,selling_from_emp_name              -- ����U�֌��S���c�Ɩ�
        ,selling_to_cust_code               -- ����U�֐�ڋq�R�[�h
        ,selling_to_cust_name               -- ����U�֐�ڋq��
        ,selling_to_base_code               -- ����U�֐拒�_�R�[�h
        ,selling_to_base_name               -- ����U�֐拒�_��
        ,selling_to_emp_code                -- ����U�֐�S���c�ƃR�[�h
        ,selling_to_emp_name                -- ����U�֐�S���c�Ɩ�
        ,selling_trns_rate                  -- ����U�֊���
        ,section_code                       -- �n��R�[�h
        ,no_data_message                    -- 0�����b�Z�[�W
        ,created_by                         -- �쐬��
        ,creation_date                      -- �쐬��
        ,last_updated_by                    -- �ŏI�X�V��
        ,last_update_date                   -- �ŏI�X�V��
        ,last_update_login                  -- �ŏI�X�V���O�C��
        ,request_id                         -- �v��ID
        ,program_application_id             -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                         -- �R���J�����g�E�v���O����ID
        ,program_update_date                -- �v���O�����X�V��
      )
      VALUES(
         iv_selling_from_base_code                       -- selling_from_base_code_in
        ,iv_selling_from_cust_code                       -- selling_from_cust_code_in
        ,iv_selling_to_base_code                         -- selling_to_base_code_in
        ,g_target_tab( in_i ).selling_from_base_code     -- selling_from_base_code
        ,g_target_tab( in_i ).selling_from_base_name     -- selling_from_base_name
        ,g_target_tab( in_i ).selling_from_cust_code     -- selling_from_cust_code
        ,g_target_tab( in_i ).selling_from_cust_name     -- selling_from_cust_name
        ,g_target_tab( in_i ).selling_from_emp_code      -- selling_from_emp_code
        ,g_target_tab( in_i ).selling_from_emp_name      -- selling_from_emp_name
        ,g_target_tab( in_i ).selling_to_cust_code       -- selling_to_cust_code
        ,g_target_tab( in_i ).selling_to_cust_name       -- selling_to_cust_name
        ,g_target_tab( in_i ).selling_to_base_code       -- selling_to_base_code
        ,g_target_tab( in_i ).selling_to_base_name       -- selling_to_base_name
        ,g_target_tab( in_i ).selling_to_emp_code        -- selling_to_emp_code
        ,g_target_tab( in_i ).selling_to_emp_name        -- selling_to_emp_name
        ,g_target_tab( in_i ).selling_trns_rate          -- selling_trns_rate
        ,g_target_tab( in_i ).section_code               -- section_code
        ,NULL                                            -- no_data_message
        ,cn_created_by                                   -- created_by
        ,SYSDATE                                         -- creation_date
        ,cn_last_updated_by                              -- last_updated_by
        ,SYSDATE                                         -- last_update_date
        ,cn_last_update_login                            -- last_update_login
        ,cn_request_id                                   -- request_id
        ,cn_program_application_id                       -- program_application_id
        ,cn_program_id                                   -- program_id
        ,SYSDATE                                         -- program_update_date
      );
    ELSE
      -- ===============================================
      -- �Ώی���0�������[�N�e�[�u���f�[�^�o�^
      -- ===============================================
      INSERT INTO xxcok_rep_selling_trns_chk(
        selling_from_base_code_in           -- ����U�֌����_
       ,selling_from_cust_code_in           -- ����U�֌��ڋq
       ,selling_to_base_code_in             -- ����U�֐拒�_
       ,no_data_message                     -- 0�����b�Z�[�W
       ,created_by                          -- �쐬��
       ,creation_date                       -- �쐬��
       ,last_updated_by                     -- �ŏI�X�V��
       ,last_update_date                    -- �ŏI�X�V��
       ,last_update_login                   -- �ŏI�X�V���O�C��
       ,request_id                          -- �v��ID
       ,program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                          -- �R���J�����g�E�v���O����ID
       ,program_update_date                 -- �v���O�����X�V��
      )
      VALUES(
        iv_selling_from_base_code           -- selling_from_base_code_in
       ,iv_selling_from_cust_code           -- selling_from_cust_code_in
       ,iv_selling_to_base_code             -- selling_to_base_code_in
       ,gv_no_data_msg                      -- no_data_message
       ,cn_created_by                       -- created_by
       ,SYSDATE                             -- creation_date
       ,cn_last_updated_by                  -- last_updated_by
       ,SYSDATE                             -- last_update_date
       ,cn_last_update_login                -- last_update_login
       ,cn_request_id                       -- request_id
       ,cn_program_application_id           -- program_application_id
       ,cn_program_id                       -- program_id
       ,SYSDATE                             -- program_update_date
      );
    END IF;
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_rep_selling_trns_chk;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf                 OUT VARCHAR2         -- �G���[�E���b�Z�[�W
   ,ov_retcode                OUT VARCHAR2         -- ���^�[���E�R�[�h
   ,ov_errmsg                 OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_selling_from_base_code IN  VARCHAR2         -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN  VARCHAR2         -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN  VARCHAR2         -- ����U�֐拒�_�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_target_data'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --===============================
    -- �f�[�^�擾
    --===============================
    OPEN g_target_cur(
      iv_selling_from_base_code => iv_selling_from_base_code
     ,iv_selling_from_cust_code => iv_selling_from_cust_code
     ,iv_selling_to_base_code   => iv_selling_to_base_code
    );
    FETCH g_target_cur BULK COLLECT INTO g_target_tab;
    CLOSE g_target_cur;
    --=======================================
    -- �Ώی����擾
    --=======================================
    gn_target_cnt := g_target_tab.COUNT;
    IF ( gn_target_cnt = 0 ) THEN
      --=====================================
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      --=====================================
      gv_no_data_msg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl
                         ,iv_name         => cv_msg_xxcok_00001
                        );
      --===============================================
      -- �Ώی���0�������[�N�e�[�u���f�[�^�o�^
      --===============================================
      ins_rep_selling_trns_chk(
         ov_errbuf                 => lv_errbuf                    -- �G���[�E���b�Z�[�W
        ,ov_retcode                => lv_retcode                   -- ���^�[���E�R�[�h
        ,ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
        ,iv_selling_from_base_code => iv_selling_from_base_code    -- ����U�֌����_�R�[�h
        ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- ����U�֌��ڋq�R�[�h
        ,iv_selling_to_base_code   => iv_selling_to_base_code      -- ����U�֐拒�_�R�[�h
        ,in_i                      => cn_0                         -- �C���f�b�N�X
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    ELSE
      <<get_data_loop>>
      FOR i IN 1 .. g_target_tab.COUNT LOOP
        --==============================
        -- ���[�N�e�[�u���f�[�^�o�^
        --==============================
        ins_rep_selling_trns_chk(
           ov_errbuf                 => lv_errbuf                  -- �G���[�E���b�Z�[�W
          ,ov_retcode                => lv_retcode                 -- ���^�[���E�R�[�h
          ,ov_errmsg                 => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          ,iv_selling_from_base_code => iv_selling_from_base_code  -- ����U�֌����_�R�[�h
          ,iv_selling_from_cust_code => iv_selling_from_cust_code  -- ����U�֌��ڋq�R�[�h
          ,iv_selling_to_base_code   => iv_selling_to_base_code    -- ����U�֐拒�_�R�[�h
          ,in_i                      => i                          -- �C���f�b�N�X
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END LOOP get_data_loop;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                 OUT VARCHAR2     -- �G���[�E���b�Z�[�W
   ,ov_retcode                OUT VARCHAR2     -- ���^�[���E�R�[�h
   ,ov_errmsg                 OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_selling_from_base_code IN  VARCHAR2     -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN  VARCHAR2     -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN  VARCHAR2     -- ����U�֐拒�_�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)     DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg     VARCHAR2(5000)  DEFAULT NULL;                -- �o�͗p���b�Z�[�W
    lb_retcode    BOOLEAN         DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��߂�l
    --===============================
    -- ���[�J����O
    --===============================
    --*** ���������G���[ ***
    init_fail_expt EXCEPTION;
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    --==============================
    -- �v���O�������͍��ڂ��o��
    --==============================
    -- ����U�֌����_�R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl
                   ,iv_name         => cv_msg_xxcok_00082
                   ,iv_token_name1  => cv_token_from_location
                   ,iv_token_value1 => iv_selling_from_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                   ,iv_message  => lv_outmsg
                   ,in_new_line => cn_0
                  );
    -- ����U�֌��ڋq�R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl
                   ,iv_name         => cv_msg_xxcok_00083
                   ,iv_token_name1  => cv_token_from_customer
                   ,iv_token_value1 => iv_selling_from_cust_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                   ,iv_message  => lv_outmsg
                   ,in_new_line => cn_0
                  );
    -- ����U�֐拒�_�R�[�h
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl
                   ,iv_name         => cv_msg_xxcok_00084
                   ,iv_token_name1  => cv_token_to_location
                   ,iv_token_value1 => iv_selling_to_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG
                   ,iv_message  => lv_outmsg
                   ,in_new_line => cn_1
                  );
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--    --==============================
--    -- �v���t�@�C��(�݌ɑg�D�R�[�h_�c�Ƒg�D)���擾����
--    --==============================
--    gv_org_code := FND_PROFILE.VALUE( cv_prof_org_code_sales );
--    IF( gv_org_code IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl
--                     ,iv_name         => cv_msg_xxcok_00003
--                     ,iv_token_name1  => cv_token_profile
--                     ,iv_token_value1 => cv_prof_org_code_sales
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG   -- �o�͋敪
--                     ,iv_message  => lv_errmsg      -- ���b�Z�[�W
--                     ,in_new_line => cn_0           -- ���s
--                    );
--      RAISE init_fail_expt;
--    END IF;
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
    --==============================
    -- �v���t�@�C��(�c�ƒP��ID)���擾����
    --==============================
    gn_org_id_sales := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_00003
                     ,iv_token_name1  => cv_token_profile
                     ,iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                     ,iv_message  => lv_errmsg      -- ���b�Z�[�W
                     ,in_new_line => cn_0           -- ���s
                    );
      RAISE init_fail_expt;
    END IF;
-- Start 2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
--    --===============================================
--    -- �݌ɑg�DID���擾����
--    --===============================================
--    gn_org_id := xxcoi_common_pkg.get_organization_id( gv_org_code );
--    IF ( gn_org_id IS NULL ) THEN
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_xxcok_appl
--                    , iv_name         => cv_msg_xxcok_00013
--                    , iv_token_name1  => cv_token_org_code
--                    , iv_token_value1 => gv_org_code
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.LOG   -- �o�͋敪
--                    , iv_message  => lv_errmsg      -- ���b�Z�[�W
--                    , in_new_line => cn_0           -- ���s
--                    );
--      RAISE init_fail_expt;
--    END IF;
-- End   2009/08/26 Ver.1.3 0001154 M.Hiruta DELETE
    --==============================
    -- �Ɩ��������t���擾����
    --==============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �擾�G���[
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl
                     ,iv_name         => cv_msg_xxcok_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                     ,iv_message  => lv_errmsg      -- ���b�Z�[�W
                     ,in_new_line => cn_0           -- ���s
                    );
      RAISE init_fail_expt;
    END IF;
  EXCEPTION
    -- *** ���������G���[ ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
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
    ov_errbuf                 OUT VARCHAR2         -- �G���[�E���b�Z�[�W
   ,ov_retcode                OUT VARCHAR2         -- ���^�[���E�R�[�h
   ,ov_errmsg                 OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_selling_from_base_code IN  VARCHAR2         -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN  VARCHAR2         -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN  VARCHAR2         -- ����U�֐拒�_�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
  BEGIN
    -- �X�e�[�^�X������
    ov_retcode := cv_status_normal;
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --===============================
    -- A-1.��������
    --===============================
    init(
      ov_errbuf                 => lv_errbuf                    -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                   -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
     ,iv_selling_from_base_code => iv_selling_from_base_code    -- ����U�֌����_�R�[�h
     ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- ����U�֌��ڋq�R�[�h
     ,iv_selling_to_base_code   => iv_selling_to_base_code      -- ����U�֐拒�_�R�[�h
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================
    -- A-2.�f�[�^�擾, A-3.���[�N�e�[�u���f�[�^�o�^
    --==============================================
    get_target_data(
      ov_errbuf                 => lv_errbuf                    -- �G���[�E���b�Z�[�W
     ,ov_retcode                => lv_retcode                   -- ���^�[���E�R�[�h
     ,ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
     ,iv_selling_from_base_code => iv_selling_from_base_code    -- ����U�֌����_�R�[�h
     ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- ����U�֌��ڋq�R�[�h
     ,iv_selling_to_base_code   => iv_selling_to_base_code      -- ����U�֐拒�_�R�[�h
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===========================
    -- ���[�N�e�[�u���f�[�^�m��
    --===========================
    COMMIT;
    --==========================
    -- A-4.SVF�N��
    --==========================
    start_svf(
      ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W
     ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h
     ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --===============================
    -- A-5.���[�N�e�[�u���f�[�^�폜
    --===============================
    del_rep_selling_trns_chk(
      ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode            -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
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
--
  PROCEDURE main(
    errbuf                    OUT VARCHAR2         -- �G���[�E���b�Z�[�W
   ,retcode                   OUT VARCHAR2         -- ���^�[���E�R�[�h
   ,iv_selling_from_base_code IN  VARCHAR2         -- ����U�֌����_�R�[�h
   ,iv_selling_from_cust_code IN  VARCHAR2         -- ����U�֌��ڋq�R�[�h
   ,iv_selling_to_base_code   IN  VARCHAR2         -- ����U�֐拒�_�R�[�h
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';   -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;    -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode      BOOLEAN        DEFAULT TRUE;                -- ���b�Z�[�W�o�͊֐��߂�l
    lv_message_code VARCHAR2(100)  DEFAULT NULL;                -- �I�����b�Z�[�W�R�[�h
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                -- �o�͗p���b�Z�[�W
  BEGIN
    --===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
     ,iv_which   => cv_which
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --===============================================
    submain(
       ov_errbuf                 => lv_errbuf                    -- �G���[�E���b�Z�[�W
      ,ov_retcode                => lv_retcode                   -- ���^�[���E�R�[�h
      ,ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_selling_from_base_code => iv_selling_from_base_code    -- ����U�֌����_�R�[�h
      ,iv_selling_from_cust_code => iv_selling_from_cust_code    -- ����U�֌��ڋq�R�[�h
      ,iv_selling_to_base_code   => iv_selling_to_base_code      -- ����U�֐拒�_�R�[�h
    );
    --===============================================
    -- �G���[�o��
    --===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                     ,iv_message  => lv_errmsg      -- ���b�Z�[�W
                     ,in_new_line => cn_0           -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                     ,iv_message  => lv_errbuf      -- ���b�Z�[�W
                     ,in_new_line => cn_1           -- ���s
                    );
    END IF;
    --===============================================
    -- �Ώی����o��
    --===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => cv_msg_xxccp_90000
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- �o�͋敪
                   ,iv_message  => lv_outmsg      -- ���b�Z�[�W
                   ,in_new_line => cn_0           -- ���s
                  );
    --===============================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
      gn_error_cnt  := cn_1;
    ELSE
      IF ( gn_target_cnt = cn_0 ) THEN
        gn_normal_cnt := cn_0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => cv_msg_xxccp_90001
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- �o�͋敪
                   ,iv_message  => lv_outmsg      -- ���b�Z�[�W
                   ,in_new_line => cn_0           -- ���s
                  );
    --===============================================
    -- �G���[�����o��
    --===============================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => cv_msg_xxccp_90002
                   ,iv_token_name1  => cv_token_count
                   ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- �o�͋敪
                   ,iv_message  => lv_outmsg      -- ���b�Z�[�W
                   ,in_new_line => cn_1           -- ���s
                  );
    --===============================================
    -- �����I�����b�Z�[�W�o��
    --===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp_90004;
    ELSE
      lv_message_code := cv_msg_xxccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl
                   ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG   -- �o�͋敪
                   ,iv_message  => lv_outmsg      -- ���b�Z�[�W
                   ,in_new_line => cn_0           -- ���s
                  );
    --===============================================
    -- �X�e�[�^�X�Z�b�g
    --===============================================
    retcode := lv_retcode;
    --===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK008A05R;
/
