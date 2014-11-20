CREATE OR REPLACE PACKAGE BODY XXCOK014A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A06R(body)
 * Description      : �����ʔ̎�̋��v�Z�������s���ɔ̎�����}�X�^���o�^�̔̔����т��G���[���X�g�ɏo��
 * MD.050           : ���̋@�̎�����G���[���X�g MD050_COK_014_A06
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  delete_err_data        ���[�N�e�[�u���f�[�^�폜(A-6)
 *  start_svf              SVF�N������(A-5)
 *  insert_err_data        ���[�N�e�[�u���o�^����(A-4)
 *  get_mst_info           ���㋒�_�E�ڋq��񒊏o����(A-3)
 *  get_err_data           �̎�����G���[��񒊏o����(A-2)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   S.Tozawa         �V�K�쐬
 *  2009/03/02    1.1   M.Hiruta         [��QCOK_066] �e��敪�擾���@�ύX
 *  2009/03/25    1.2   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/03/02    1.3   K.Yamaguchi      [��QT1_0510] ���㋒�_���擾SQL���̕s���Ή�
 *  2009/09/01    1.4   S.Moriyama       [��Q0001230] OPM�i�ڃ}�X�^�擾�����ǉ�
 *  2011/02/02    1.5   S.Ochiai         [��QE_�{�ғ�_05408] �N���֑ؑΉ�
 *
 *****************************************************************************************/
  -- ===============================================
  -- �O���[�o���萔
  -- ===============================================
  -- �p�b�P�[�W��
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOK014A06R';
  -- �A�v���P�[�V�����Z�k��
  cv_xxcok_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCCP';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ���b�Z�[�W�R�[�h
  cv_msg_code_00001          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00001';          -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_code_00074          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00074';          -- �p�����[�^���O�o�͗p���b�Z�[�W
  cv_msg_code_00003          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00003';          -- �v���t�@�C���擾�G���[
  cv_msg_code_00013          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00013';          -- �݌ɑg�DID�擾�G���[
  cv_msg_code_00048          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00048';          -- ����v�㋒�_���0���G���[
  cv_msg_code_00047          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00047';          -- ����v�㋒�_��񕡐����G���[
  cv_msg_code_00035          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00035';          -- �ڋq���0���G���[
  cv_msg_code_00046          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00046';          -- �ڋq��񕡐����擾�G���[
  cv_msg_code_00056          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00056';          -- �i�ڏ��擾�G���[
  cv_msg_code_00015          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00015';          -- �e����擾�G���[
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD START
  cv_msg_code_00028          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00028';          -- �Ɩ��������t�擾�G���[
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD END
  cv_msg_code_00040          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-00040';          -- SVF�N��API�G���[
  cv_msg_code_10321          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10321';          -- ���b�N�擾�G���[
  cv_msg_code_10397          CONSTANT VARCHAR2(50)  := 'APP-XXCOK1-10397';          -- �f�[�^�폜�G���[
  cv_msg_code_90000          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';          -- �Ώی���
  cv_msg_code_90001          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';          -- ��������
  cv_msg_code_90002          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';          -- �G���[����
  cv_msg_code_90004          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';          -- ����I��
  cv_msg_code_90005          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';          -- �x���I��
  cv_msg_code_90006          CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';          -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_token_base_code         CONSTANT VARCHAR2(20)  := 'SELLING_BASE_CODE';
  cv_token_profile           CONSTANT VARCHAR2(20)  := 'PROFILE';
  cv_token_sales_log         CONSTANT VARCHAR2(20)  := 'SALES_LOC';
  cv_token_org_code          CONSTANT VARCHAR2(20)  := 'ORG_CODE';
  cv_token_cust_code         CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_token_item_code         CONSTANT VARCHAR2(20)  := 'ITEM_CODE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(20)  := 'LOOKUP_VALUE_SET';
  cv_token_count             CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_token_request_id        CONSTANT VARCHAR2(20)  := 'REQUEST_ID';
  -- �Q�ƃ^�C�v
-- Start 2009/03/03 M.Hiruta
--  cv_token_yoki_kubun        CONSTANT VARCHAR2(20)  := 'XXCMM_YOKI_KUBUN';          -- �e��敪
  cv_token_yoki_kubun        CONSTANT VARCHAR2(25)  := 'XXCSO1_SP_RULE_BOTTLE';     -- �e��敪
-- End   2009/03/03 M.Hiruta
  -- �v���t�@�C��
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD START
  cv_prof_org_id             CONSTANT VARCHAR2(25)  := 'ORG_ID';    -- MO�F�c�ƒP��ID
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD END
  cv_prof_org_code_sales     CONSTANT VARCHAR2(25)  := 'XXCOK1_ORG_CODE_SALES';     -- �݌ɑg�D�R�[�h_�c�Ƒg�D
  -- �ڋq�^�C�v
  cv_cust_base_type          CONSTANT VARCHAR2(30)  := '1';                  -- �ڋq�敪�u���_�v�F'1'
  cv_cust_customer_type      CONSTANT VARCHAR2(30)  := '10';                 -- �ڋq�敪�u�ڋq�v�F'10'
  -- �Z�p���[�^
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
  -- �o�͋敪
  cv_which                   CONSTANT VARCHAR2(3)   := 'LOG';                -- �o�͋敪�F'LOG'
  -- ���l(���s�̎w��A�����`�F�b�N���Ɏg�p)
  cn_number_0                CONSTANT NUMBER        := 0;
  cn_number_1                CONSTANT NUMBER        := 1;
  -- SVF�N���p�����[�^
  cv_file_id                 CONSTANT VARCHAR2(20)  := 'XXCOK014A06R';       -- ���[ID
  cv_output_mode             CONSTANT VARCHAR2(1)   := '1';                  -- �o�͋敪(PDF�o��)
  cv_frm_file                CONSTANT VARCHAR2(20)  := 'XXCOK014A06S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                CONSTANT VARCHAR2(20)  := 'XXCOK014A06S.vrq';   -- �N�G���[�l���t�@�C����
  -- SVF�o�̓t�@�C�����쐬�p
  cv_format_yyyymmdd         CONSTANT VARCHAR2(20)  := 'YYYYMMDD';           -- ������ϊ��p���t�����t�H�[�}�b�g
  cv_extension               CONSTANT VARCHAR2(5)   := '.pdf';               -- �o�̓t�@�C���p�g���q(PDF�`��)
  -- ===============================================
  -- �O���[�o���ϐ�
  -- ===============================================
  -- �J�E���^
  gn_target_cnt             NUMBER         DEFAULT 0;     -- �Ώی���
  gn_normal_cnt             NUMBER         DEFAULT 0;     -- ���팏��
  gn_error_cnt              NUMBER         DEFAULT 0;     -- �G���[����
  -- ���b�Z�[�W
  gv_no_data_msg_table      VARCHAR2(30)                         DEFAULT NULL;  -- 0�����b�Z�[�W(�e�[�u���i�[�p)
  gv_no_data_msg_output     VARCHAR2(5000)                       DEFAULT NULL;  -- 0�����b�Z�[�W(SVF�o�͗p)
  -- �擾�f�[�^�i�[
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD START
  gn_operating_unit         NUMBER                               DEFAULT NULL;  -- �v���t�@�C��(MO�F�c�ƒP��ID)
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD END
  gv_org_code               VARCHAR2(50)                         DEFAULT NULL;  -- �v���t�@�C���l(�݌ɑg�D�R�[�h)
  gn_org_id                 NUMBER                               DEFAULT NULL;  -- �݌ɑg�DID
  gt_selling_base_code      hz_cust_accounts.account_number%TYPE DEFAULT NULL;  -- ����v�㋒�_�R�[�h(���̓p�����[�^)
  gt_selling_base_name      hz_cust_accounts.account_name%TYPE   DEFAULT NULL;  -- ����v�㋒�_��
  gt_section_code           hz_locations.address3%TYPE           DEFAULT NULL;  -- �n��R�[�h�i����v�㋒�_�j
  gt_customer_code          hz_cust_accounts.account_number%TYPE DEFAULT NULL;  -- �ڋq�R�[�h
  gt_customer_name          hz_cust_accounts.account_name%TYPE   DEFAULT NULL;  -- �ڋq��
  -- �ޔ��f�[�^�i�[
  gt_base_code              xxcok_bm_contract_err.base_code%TYPE DEFAULT NULL;  -- ���_�R�[�h(���̓p�����[�^)
  gt_selling_base_code_bkup hz_cust_accounts.account_number%TYPE DEFAULT NULL;  -- ����v�㋒�_�R�[�h
  gt_cust_code_bkup         hz_locations.address3%TYPE           DEFAULT NULL;  -- �n��R�[�h
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD START
  gd_process_date           DATE                                 DEFAULT NULL;  -- �Ɩ��������t
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD END
  -- �t�@�C������
  gv_file_name              VARCHAR2(100)                        DEFAULT NULL;  -- SVF�o�̓t�@�C����
  -- ===============================================
  -- �O���[�o���J�[�\��
  -- ===============================================
  -- �G���[�f�[�^�擾�J�[�\��
  CURSOR g_get_err_cur(
    iv_bace_code IN  VARCHAR2 DEFAULT NULL                        -- ���_�R�[�h(���̓p�����[�^)
  )
  IS
-- 2011/02/02 Ver.1.5 [��QE_�{�ғ�_05408] SCS S.Ochiai UPD START
--    SELECT xbce.base_code            AS base_code                 -- ���_�R�[�h
    SELECT /*+
               PUSH_PRED(ITEM)
               LEADING  (XBCE XCA)
               USE_NL   (XBCE XCA)
               INDEX    (XBCE XXCOK_BM_CONTRACT_ERR_N02)
               INDEX    (XCA  XXCMM_CUST_ACCOUNTS_N06)
           */
           xbce.base_code            AS base_code                 -- ���_�R�[�h
-- 2011/02/02 Ver.1.5 [��QE_�{�ғ�_05408] SCS S.Ochiai UPD END
         , xbce.cust_code            AS cust_code                 -- �ڋq�R�[�h
         , xbce.item_code            AS item_code                 -- �i�ڃR�[�h
         , xbce.container_type_code  AS container_type_code       -- �e��R�[�h
         , xbce.selling_price        AS selling_price             -- ����
         , xbce.selling_amt_tax      AS selling_amt_tax           -- ������z(�ō�)
         , xbce.closing_date         AS closing_date              -- ���ߓ�
         , item.item_short_name      AS item_short_name           -- �i�ځE����
         , cont.container_name       AS container_name            -- �e�햼
    FROM   xxcok_bm_contract_err     xbce                         -- �̎�����G���[�e�[�u��
-- 2011/02/02 Ver.1.5 [��QE_�{�ғ�_05408] SCS S.Ochiai ADD START
         , xxcmm_cust_accounts       xca                          -- �ڋq�ǉ����
-- 2011/02/02 Ver.1.5 [��QE_�{�ғ�_05408] SCS S.Ochiai ADD END
         , ( SELECT msib.segment1         AS item_code            -- �i�ڃR�[�h
                  , ximb.item_short_name  AS item_short_name      -- �i�ځE����
             FROM   mtl_system_items_b    msib                    -- �i�ڃ}�X�^
                  , ic_item_mst_b         iimb                    -- OPM�i�ڃ}�X�^
                  , xxcmn_item_mst_b      ximb                    -- OPM�i�ڃA�h�I���}�X�^
             WHERE  msib.organization_id  = gn_org_id
             AND    msib.segment1         = iimb.item_no
             AND    iimb.item_id          = ximb.item_id
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD START
             AND    gd_process_date BETWEEN ximb.start_date_active
                                    AND NVL ( ximb.end_date_active , gd_process_date )
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD END
           ) item
-- Start 2009/03/03 M.Hiruta
--         , ( SELECT xlvv.lookup_code      AS container_type_code  -- �e��R�[�h
         , ( SELECT xlvv.attribute1       AS container_type_code  -- �e��R�[�h
-- End   2009/03/03 M.Hiruta
                  , xlvv.meaning          AS container_name       -- �e�햼
             FROM   xxcmn_lookup_values_v xlvv                    -- �N�C�b�N�R�[�h
             WHERE  xlvv.lookup_type      = cv_token_yoki_kubun
           ) cont
-- 2011/02/02 Ver.1.5 [��QE_�{�ғ�_05408] SCS S.Ochiai UPD START
--    WHERE  xbce.base_code            = NVL( iv_bace_code , xbce.base_code )
    WHERE  xbce.cust_code            = xca.customer_code
    AND    xca.past_sale_base_code   = NVL( iv_bace_code ,xca.past_sale_base_code)
-- 2011/02/02 Ver.1.5 [��QE_�{�ғ�_05408] SCS S.Ochiai UPD END
    AND    xbce.item_code            = item.item_code(+)
    AND    xbce.container_type_code  = cont.container_type_code(+)
    ORDER BY
      xbce.base_code
    , xbce.cust_code
    , xbce.item_code
    , xbce.container_type_code;
  -- ===============================================
  -- �O���[�o���e�[�u���^�C�v
  -- ===============================================
  TYPE g_err_ttype IS TABLE OF g_get_err_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  -- ===============================================
  -- �O���[�o���e�[�u���^�ϐ�
  -- ===============================================
  g_err_tab                 g_err_ttype;
  -- ===============================================
  -- �O���[�o����O
  -- ===============================================
  global_api_expt           EXCEPTION;  -- ���ʊ֐���O
  global_api_others_expt    EXCEPTION;  -- ���ʊ֐�OTHERS��O
  global_lock_fail_expt     EXCEPTION;  -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT( global_api_others_expt , -20000 );
  PRAGMA EXCEPTION_INIT(global_lock_fail_expt, -54);
--
  /************************************************************************
   * Procedure Name  : delete_err_data
   * Description     : ���[�N�e�[�u���f�[�^�폜(A-6)
   ************************************************************************/
  PROCEDURE delete_err_data(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'delete_err_data';       -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- �쐬���b�Z�[�W�i�[
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    -- ===============================================
    -- ���[�J���J�[�\��
    -- ===============================================
    CURSOR lock_chk_cur
    IS
      SELECT 'X'
      FROM   xxcok_rep_bm_contract_err  xrbce       -- �̎�����G���[���X�g���[���[�N�e�[�u��
      WHERE  xrbce.request_id = cn_request_id
      FOR UPDATE OF xrbce.request_id NOWAIT;
--
  BEGIN
    lv_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�����G���[���X�g���[���[�N�e�[�u�����b�N�擾
    -- ===============================================
    OPEN  lock_chk_cur;
    CLOSE lock_chk_cur;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�폜
    -- ===============================================
    BEGIN
      DELETE FROM xxcok_rep_bm_contract_err         -- �̎�����G���[���X�g���[���[�N�e�[�u��
      WHERE       request_id = cn_request_id;
    EXCEPTION
      WHEN OTHERS THEN
      lv_message  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcok_appl_short_name
                     , iv_name         => cv_msg_code_10397
                     , iv_token_name1  => cv_token_request_id
                     , iv_token_value1 => cn_request_id
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                    , iv_message  => lv_errmsg         -- ���b�Z�[�W
                    , in_new_line => cn_number_0       -- ���s
                    );
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
    END;
    -- ===============================================
    -- ���������擾
    -- ===============================================
    gn_normal_cnt := SQL%ROWCOUNT;
    -- �G���[���X�g�e�[�u���̎擾�f�[�^��0���̏ꍇ�́A���������ɂ�0�����B
    IF ( gn_target_cnt = cn_number_0 ) THEN
      gn_normal_cnt := cn_number_0;
    END IF;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN global_lock_fail_expt THEN
      lv_message  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcok_appl_short_name
                     , iv_name         => cv_msg_code_10321
                     , iv_token_name1  => cv_token_request_id
                     , iv_token_value1 => cn_request_id
                     );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      -- �o�͋敪
                    , iv_message  => lv_errmsg         -- ���b�Z�[�W
                    , in_new_line => cn_number_0       -- ���s
                    );
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
      ov_errmsg  := NULL;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END delete_err_data;
--
  /************************************************************************
   * Procedure Name  : start_svf
   * Description     : SVF�N������(A-5)
   ************************************************************************/
  PROCEDURE start_svf(
    ov_errbuf        OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , ov_retcode       OUT VARCHAR2  -- ���^�[���E�R�[�h
  , ov_errmsg        OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'start_svf';            -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- �쐬���b�Z�[�W�i�[
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    lv_sysdate             VARCHAR2(10)   DEFAULT NULL;             -- �V�X�e�����t�̕����^�i�[
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    call_svf_err_expt      EXCEPTION;                  -- SVF���s�G���[
-- 
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �o�̓t�@�C�����Ɏg�p������t�𕶎���ɕϊ�
    -- ===============================================
    lv_sysdate := TO_CHAR( SYSDATE, cv_format_yyyymmdd );
    -- ===============================================
    -- �o�̓t�@�C����(���[ID + YYYYMMDD + �v��ID)
    -- ===============================================
    gv_file_name := cv_file_id || lv_sysdate || TO_CHAR( cn_request_id ) || cv_extension;
    -- ===============================================
    -- SVF�R���J�����g�N��
    -- ===============================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_errbuf        => lv_errbuf                 -- �G���[�o�b�t�@
      , ov_retcode       => lv_retcode                -- ���^�[���R�[�h
      , ov_errmsg        => lv_errmsg                 -- �G���[���b�Z�[�W
      , iv_conc_name     => cv_pkg_name               -- �R���J�����g��
      , iv_file_name     => gv_file_name              -- �o�̓t�@�C����
      , iv_file_id       => cv_file_id                -- ���[ID
      , iv_output_mode   => cv_output_mode            -- �o�͋敪
      , iv_frm_file      => cv_frm_file               -- �t�H�[���l���t�@�C����
      , iv_vrq_file      => cv_vrq_file               -- �N�G���[�l���t�@�C����
      , iv_org_id        => TO_CHAR( gn_org_id )      -- ORG_ID
      , iv_user_name     => fnd_global.user_name      -- ���O�C���E���[�U��
      , iv_resp_name     => fnd_global.resp_name      -- ���O�C���E���[�U�E�Ӗ�
      , iv_doc_name      => NULL                      -- ������
      , iv_printer_name  => NULL                      -- �v�����^��
      , iv_request_id    => TO_CHAR( cn_request_id )  -- �v��ID
      , iv_nodata_msg    => gv_no_data_msg_output     -- �f�[�^�Ȃ����b�Z�[�W
    );
    IF( lv_retcode <> cv_status_normal ) THEN
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00040
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --�o�͋敪
                    , iv_message  => lv_message       --���b�Z�[�W
                    , in_new_line => cn_number_0      --���s
              );
      RAISE call_svf_err_expt;
    END IF;
--
  EXCEPTION
    -- *** SVF���s�G���[ ***
    WHEN call_svf_err_expt THEN
      ov_retcode := lv_retcode;
      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END start_svf;
--
  /************************************************************************
   * Procedure Name  : insert_err_data
   * Description     : ���[�N�e�[�u���o�^����(A-4)
   ************************************************************************/
  PROCEDURE insert_err_data(
    ov_errbuf    OUT VARCHAR2               -- �G���[�E���b�Z�[�W
  , ov_retcode   OUT VARCHAR2               -- ���^�[���E�R�[�h
  , ov_errmsg    OUT VARCHAR2               -- ���[�U�E�G���[�E���b�Z�[�W
  , in_cnt       IN  NUMBER                 -- LOOP�J�E���^
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)   := 'insert_err_data';     -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �G���[�f�[�^�̑}��
    -- ===============================================
    -- 0���ȊO�̏ꍇ
    IF ( gn_target_cnt != cn_number_0 ) THEN
      INSERT INTO xxcok_rep_bm_contract_err(   -- �̎�����G���[���X�g���[���[�N�e�[�u��
        p_selling_base_code                    -- ����v�㋒�_�R�[�h(���̓p�����[�^)
      , selling_base_code                      -- ����v�㋒�_�R�[�h
      , selling_base_name                      -- ����v�㋒�_��
      , cost_code                              -- �ڋq�R�[�h
      , cost_name                              -- �ڋq��
      , item_code                              -- �i�ڃR�[�h
      , item_name                              -- �i�ږ�
      , container_type                         -- �e��敪
      , selling_price                          -- ����
      , selling_amt_tax                        -- ������z(�ō�)
      , closing_date                           -- ���ߓ�
      , selling_base_section_code              -- �n��R�[�h�i����v�㋒�_�j
      , no_data_message                        -- 0�����b�Z�[�W
      , created_by                             -- �쐬��
      , creation_date                          -- �쐬��
      , last_updated_by                        -- �ŏI�X�V��
      , last_update_date                       -- �ŏI�X�V��
      , last_update_login                      -- �ŏI�X�V���O�C��
      , request_id                             -- �v��ID
      , program_application_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                             -- �R���J�����g�E�v���O����ID
      , program_update_date                    -- �v���O�����X�V��
      )
      VALUES(
        gt_base_code                           -- ����v�㋒�_�R�[�h(���̓p�����[�^)
      , gt_selling_base_code                   -- ����v�㋒�_�R�[�h
      , gt_selling_base_name                   -- ����v�㋒�_��
      , gt_customer_code                       -- �ڋq�R�[�h
      , gt_customer_name                       -- �ڋq��
      , g_err_tab( in_cnt ).item_code          -- �i�ڃR�[�h
      , g_err_tab( in_cnt ).item_short_name    -- �i�ږ�
      , g_err_tab( in_cnt ).container_name     -- �e��敪
      , g_err_tab( in_cnt ).selling_price      -- ����
      , g_err_tab( in_cnt ).selling_amt_tax    -- ������z(�ō�)
      , g_err_tab( in_cnt ).closing_date       -- ���ߓ�
      , gt_section_code                        -- �n��R�[�h�i����v�㋒�_�j
      , gv_no_data_msg_table                   -- 0�����b�Z�[�W
      , cn_created_by                          -- �쐬��
      , SYSDATE                                -- �쐬��
      , cn_last_updated_by                     -- �ŏI�X�V��
      , SYSDATE                                -- �ŏI�X�V��
      , cn_last_update_login                   -- �ŏI���O�C��
      , cn_request_id                          -- �v��ID
      , cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                          -- �R���J�����g�E�v���O����ID
      , SYSDATE                                -- �v���O�����X�V��
      );
      -- ===============================================
      -- �擾�f�[�^�̑ޔ�
      -- ===============================================
      gt_selling_base_code_bkup := gt_selling_base_code;  -- ����v�㋒�_���
      gt_cust_code_bkup         := gt_customer_code;      -- �ڋq���
    -- 0���̏ꍇ
    ELSE
      INSERT INTO xxcok_rep_bm_contract_err(   -- �̎�����G���[���X�g���[���[�N�e�[�u��
        p_selling_base_code                    -- ����v�㋒�_�R�[�h(���̓p�����[�^)
      , selling_base_code                      -- ����v�㋒�_�R�[�h
      , selling_base_name                      -- ����v�㋒�_��
      , cost_code                              -- �ڋq�R�[�h
      , cost_name                              -- �ڋq��
      , item_code                              -- �i�ڃR�[�h
      , item_name                              -- �i�ږ�
      , container_type                         -- �e��敪
      , selling_price                          -- ����
      , selling_amt_tax                        -- ������z(�ō�)
      , closing_date                           -- ���ߓ�
      , selling_base_section_code              -- �n��R�[�h�i����v�㋒�_�j
      , no_data_message                        -- 0�����b�Z�[�W
      , created_by                             -- �쐬��
      , creation_date                          -- �쐬��
      , last_updated_by                        -- �ŏI�X�V��
      , last_update_date                       -- �ŏI�X�V��
      , last_update_login                      -- �ŏI�X�V���O�C��
      , request_id                             -- �v��ID
      , program_application_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id                             -- �R���J�����g�E�v���O����ID
      , program_update_date                    -- �v���O�����X�V��
      )
      VALUES(
        gt_base_code                           -- ����v�㋒�_�R�[�h(���̓p�����[�^)
      , NULL                                   -- ����v�㋒�_�R�[�h
      , NULL                                   -- ����v�㋒�_��
      , NULL                                   -- �ڋq�R�[�h
      , NULL                                   -- �ڋq��
      , NULL                                   -- �i�ڃR�[�h
      , NULL                                   -- �i�ږ�
      , NULL                                   -- �e��敪
      , NULL                                   -- ����
      , NULL                                   -- ������z(�ō�)
      , NULL                                   -- ���ߓ�
      , NULL                                   -- �n��R�[�h�i����v�㋒�_�j
      , gv_no_data_msg_table                   -- 0�����b�Z�[�W
      , cn_created_by                          -- �쐬��
      , SYSDATE                                -- �쐬��
      , cn_last_updated_by                     -- �ŏI�X�V��
      , SYSDATE                                -- �ŏI�X�V��
      , cn_last_update_login                   -- �ŏI���O�C��
      , cn_request_id                          -- �v��ID
      , cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                          -- �R���J�����g�E�v���O����ID
      , SYSDATE                                -- �v���O�����X�V��
      );
    END IF;
  EXCEPTION
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END insert_err_data;
--
  /************************************************************************
   * Procedure Name  : get_mst_info
   * Description     : ���㋒�_�E�ڋq��񒊏o����(A-3)
   ************************************************************************/
  PROCEDURE get_mst_info(
    ov_errbuf     OUT VARCHAR2               -- �G���[�E���b�Z�[�W
  , ov_retcode    OUT VARCHAR2               -- ���^�[���E�R�[�h
  , ov_errmsg     OUT VARCHAR2               -- ���[�U�E�G���[�E���b�Z�[�W
  , iv_base_code  IN  VARCHAR2               -- ���_�R�[�h(SQL����)
  , iv_cust_code  IN  VARCHAR2               -- �ڋq�R�[�h(SQL����)
  , in_cnt        IN  NUMBER                 -- LOOP�J�E���^
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'get_mst_info';         -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- �쐬���b�Z�[�W�i�[
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    get_data_err_expt      EXCEPTION;         -- �f�[�^�擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ���㋒�_���擾
    -- ===============================================
    -- ����A�������͒��O�̋��_�R�[�h�ƒl���قȂ�ꍇ�Ɏ擾����B
--    IF ( in_cnt = cn_number_0 )
    IF ( in_cnt = cn_number_1 )
      OR ( gt_selling_base_code_bkup != iv_base_code )
    THEN
--
      BEGIN
        SELECT hca.account_number   AS selling_base_code  -- ����v�㋒�_�R�[�h(�ڋq�R�[�h)
             , hca.account_name     AS selling_base_name  -- ���㋒�_��(�A�J�E���g��)
             , hl.address3          AS section_code       -- �n��R�[�h(�Z��3)
        INTO   gt_selling_base_code
             , gt_selling_base_name
             , gt_section_code
        FROM   hz_cust_accounts        hca                -- �ڋq�}�X�^
             , hz_locations            hl                 -- �ڋq���Ə��}�X�^
             , hz_parties              hp                 -- �p�[�e�B�}�X�^
             , hz_party_sites          hps                -- �p�[�e�B�T�C�g�}�X�^
             , hz_cust_acct_sites_all  hcasa              -- �ڋq���ݒn�}�X�^
        WHERE  hca.party_id            = hp.party_id
        AND    hca.cust_account_id     = hcasa.cust_account_id
        AND    hp.party_id             = hps.party_id
        AND    hps.location_id         = hl.location_id
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD START
        AND    hcasa.party_site_id     = hps.party_site_id
        AND    hcasa.org_id            = gn_operating_unit
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD END
        AND    hca.account_number      = iv_base_code
        AND    hca.customer_class_code = cv_cust_base_type;
--
      EXCEPTION
        -- *** �Ώۃf�[�^0���̏ꍇ ***
        WHEN NO_DATA_FOUND THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00048
                        , iv_token_name1  => cv_token_sales_log
                        , iv_token_value1 => iv_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --�o�͋敪
                        , iv_message  => lv_message       --���b�Z�[�W
                        , in_new_line => cn_number_0      --���s
                        );
          RAISE get_data_err_expt;
        -- *** �����s�̃f�[�^���Ԃ��ꂽ�ꍇ ***
        WHEN TOO_MANY_ROWS THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00047
                        , iv_token_name1  => cv_token_sales_log
                        , iv_token_value1 => iv_base_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --�o�͋敪
                        , iv_message  => lv_message       --���b�Z�[�W
                        , in_new_line => cn_number_0      --���s
                        );
          RAISE get_data_err_expt;
      END;
    END IF;
    -- ===============================================
    -- �ڋq���̎擾
    -- ===============================================
    -- ����A�������͒��O�̌ڋq�R�[�h�ƒl���قȂ�ꍇ�Ɏ擾����B
--    IF ( in_cnt = cn_number_0 )
    IF ( in_cnt = cn_number_1 )
      OR ( gt_cust_code_bkup != iv_cust_code )
    THEN
--
      BEGIN
        SELECT hca.account_number      AS customer_code  -- �ڋq�R�[�h
             , hp.party_name           AS customer_name  -- �ڋq��
        INTO   gt_customer_code
             , gt_customer_name
        FROM   hz_cust_accounts        hca               -- �ڋq�}�X�^
             , hz_parties              hp                -- �p�[�e�B�}�X�^
        WHERE  hca.party_id            = hp.party_id
        AND    hca.account_number      = iv_cust_code
        AND    hca.customer_class_code = cv_cust_customer_type;
--
      EXCEPTION
        -- *** �Ώۃf�[�^0���̏ꍇ ***
        WHEN NO_DATA_FOUND THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00035
                        , iv_token_name1  => cv_token_cust_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --�o�͋敪
                        , iv_message  => lv_message       --���b�Z�[�W
                        , in_new_line => cn_number_0      --���s
                        );
          RAISE get_data_err_expt;
        -- *** �����s�̃f�[�^���Ԃ��ꂽ�ꍇ ***
        WHEN TOO_MANY_ROWS THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00046
                        , iv_token_name1  => cv_token_cust_code
                        , iv_token_value1 => iv_cust_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --�o�͋敪
                        , iv_message  => lv_message       --���b�Z�[�W
                        , in_new_line => cn_number_0      --���s
                        );
          RAISE get_data_err_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** �f�[�^�擾�G���[ ***
    WHEN get_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
      ov_errmsg  := NULL;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      ov_errmsg  := NULL;
  END get_mst_info;
--
  /************************************************************************
   * Procedure Name  : get_err_data
   * Description     : �̎�����G���[��񒊏o����(A-2)
   ************************************************************************/
  PROCEDURE get_err_data(
    ov_errbuf     OUT VARCHAR2       -- �G���[�E���b�Z�[�W
  , ov_retcode    OUT VARCHAR2       -- ���^�[���E�R�[�h
  , ov_errmsg     OUT VARCHAR2       -- ���[�U�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'get_err_date';                    -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;                        -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal;            -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;                        -- ���[�U�E�G���[����b�Z�[�W
    lv_message             VARCHAR2(5000) DEFAULT NULL;                        -- �쐬���b�Z�[�W�i�[
    lb_retcode             BOOLEAN        DEFAULT NULL;                        -- ���b�Z�[�W�o�͎����^�[���R�[�h
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    get_data_null_expt     EXCEPTION;                                          -- �i�ځE�����A�e�햼�擾�G���[
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- �̎�����G���[���̎擾
    -- ===============================================
    -- �J�[�\���I�[�v��
    OPEN g_get_err_cur(
           iv_bace_code => gt_base_code
         );
    FETCH g_get_err_cur BULK COLLECT INTO g_err_tab;
    -- �J�[�\���N���[�Y
    CLOSE g_get_err_cur;
    -- �擾������ޔ�
    gn_target_cnt := g_err_tab.COUNT;
    -- ===============================================
    -- �f�[�^���擾���ꂽ�ꍇ
    -- ===============================================
    IF ( gn_target_cnt != 0 ) THEN
      -- ���[�v�J�n
      <<main_loop>>
      FOR i IN g_err_tab.FIRST .. g_err_tab.LAST LOOP
        -- ===============================================
        -- �i�ځE�������擾�ł��Ȃ������ꍇ
        -- ===============================================
        IF ( g_err_tab( i ).item_short_name IS NULL ) THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00056
--                        , iv_token_name1  => cv_token_profile
--                        , iv_token_value1 => cv_prof_org_code_sales
                        , iv_token_name1  => cv_token_item_code
                        , iv_token_value1 => g_err_tab( i ).item_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --�o�͋敪
                        , iv_message  => lv_message       --���b�Z�[�W
                        , in_new_line => cn_number_0      --���s
                        );
          RAISE get_data_null_expt;
        END IF;
        -- ===============================================
        -- �e�킪�擾�ł��Ȃ������ꍇ
        -- ===============================================
        IF ( g_err_tab( i ).container_name IS NULL ) THEN
          lv_message := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcok_appl_short_name
                        , iv_name         => cv_msg_code_00015
--                        , iv_token_name1  => cv_token_profile
--                        , iv_token_value1 => cv_prof_org_code_sales
                        , iv_token_name1  => cv_token_lookup_value_set
                        , iv_token_value1 => g_err_tab( i ).container_type_code
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.LOG     --�o�͋敪
                        , iv_message  => lv_message       --���b�Z�[�W
                        , in_new_line => cn_number_0      --���s
                        );
          RAISE get_data_null_expt;
        END IF;
        -- ===============================================
        -- ���㋒�_�E�ڋq���擾(A-3)
        -- ===============================================
        get_mst_info(
          ov_errbuf             => lv_errbuf                 -- �G���[�E���b�Z�[�W
        , ov_retcode            => lv_retcode                -- ���^�[���E�R�[�h
        , ov_errmsg             => lv_errmsg                 -- ���[�U�E�G���[�E���b�Z�[�W
        , iv_base_code          => g_err_tab( i ).base_code  -- ���_�R�[�h(SQL����)
        , iv_cust_code          => g_err_tab( i ).cust_code  -- �ڋq�R�[�h(SQL����)
        , in_cnt                => i                         -- LOOP�J�E���^
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        -- ===============================================
        -- ���[�N�e�[�u���ւ̓o�^����(A-4)
        -- ===============================================
        insert_err_data(
            ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W
          , ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h
          , ov_errmsg             => lv_errmsg              -- ���[�U�E�G���[�E���b�Z�[�W
          , in_cnt                => i                      -- LOOP�J�E���^
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP main_loop;
    -- ===============================================
    -- �f�[�^��0���̏ꍇ
    -- ===============================================
    ELSE
      -- ===============================================
      -- �Ώۃf�[�^�Ȃ����b�Z�[�W�擾
      -- ===============================================
      gv_no_data_msg_table := xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcok_appl_short_name
                              , iv_name         => cv_msg_code_00001
                        );
      -- ===============================================
      -- ���[�N�e�[�u���ւ̓o�^����(A-4)
      -- ===============================================
      insert_err_data(
        ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W
      , ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h
      , ov_errmsg             => lv_errmsg              -- ���[�U�E�G���[�E���b�Z�[�W
      , in_cnt                => cn_number_0            -- LOOP�J�E���^(0�Œ�)
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** �i�ځE�����A�e�햼�擾�G���[ ***
    WHEN get_data_null_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    WHEN global_api_others_expt THEN
    -- *** ���ʊ֐�OTHERS��O ***
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
--
  END get_err_data;
--
  /************************************************************************
   * Procedure Name  : init
   * Description     : ��������(A-1)
   ************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg     OUT VARCHAR2     -- ���[�U�E�G���[�E���b�Z�[�W
  , iv_base_code  IN  VARCHAR2     -- ���_�R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'init';  -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- �쐬���b�Z�[�W�i�[
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    -- ===============================================
    -- ���[�J����O
    -- ===============================================
    get_data_err_expt      EXCEPTION;                -- �f�[�^�擾�G���[����O
--
  BEGIN
    ov_retcode := cv_status_normal;
    --================================================
    -- ���̓p�����[�^�̑ޔ�
    --================================================
    gt_base_code := iv_base_code;
    --================================================
    -- ���̓p�����[�^�̃��O�o��
    --================================================
      lv_message  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00074
                    , iv_token_name1  => cv_token_base_code
                    , iv_token_value1 => gt_base_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --�o�͋敪
                    , iv_message  => lv_message       --���b�Z�[�W
                    , in_new_line => cn_number_1      --���s
                    );
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD START
    --================================================
    -- �v���t�@�C��(�c�ƒP��ID)�̎擾
    --================================================
    gn_operating_unit := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_operating_unit IS NULL ) THEN
      lv_message  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --�o�͋敪
                    , iv_message  => lv_message       --���b�Z�[�W
                    , in_new_line => cn_number_0      --���s
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/04/14 Ver.1.3 [��QT1_0510] SCS K.Yamaguchi ADD END
    --================================================
    -- �J�X�^���E�v���t�@�C��(�݌ɑg�D�R�[�h)�̎擾
    --================================================
    gv_org_code := FND_PROFILE.VALUE(
                     cv_prof_org_code_sales
                   );
    IF ( gv_org_code IS NULL ) THEN
      lv_message  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --�o�͋敪
                    , iv_message  => lv_message       --���b�Z�[�W
                    , in_new_line => cn_number_0      --���s
                    );
      RAISE get_data_err_expt;
    END IF;
    --================================================
    -- �݌ɑg�DID�̎擾
    --================================================
    gn_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gv_org_code
                 );
    -- �݌ɑg�DID�̎擾�Ɏ��s�����ꍇ
    IF ( gn_org_id IS NULL ) THEN
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00013
                    , iv_token_name1  => cv_token_org_code
                    , iv_token_value1 => gv_org_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG     --�o�͋敪
                    , iv_message  => lv_message       --���b�Z�[�W
                    , in_new_line => cn_number_0      --���s
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD START
    -- ===============================================
    -- �Ɩ��������t�擾
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_short_name
                    , iv_name         => cv_msg_code_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE get_data_err_expt;
    END IF;
-- 2009/09/01 Ver.1.4 [��Q0001230] SCS S.Moriyama ADD END
--
  EXCEPTION
    -- *** �f�[�^�擾�G���[ ***
    WHEN get_data_err_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_message , 1 , 5000 );
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
  END init;
--
  /************************************************************************
   * Procedure Name  : submain
   * Description     : ���C�������v���V�[�W��
   ************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h
  , ov_errmsg     OUT VARCHAR2     -- ���[�U�E�G���[�E���b�Z�[�W
  , iv_base_code  IN  VARCHAR2     -- ���_�R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'submain';  -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
      ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg     -- ���[�U�E�G���[�E���b�Z�[�W
    , iv_base_code  => iv_base_code  -- ���_�R�[�h
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- �̎�����G���[��񒊏o����(A-2)�E���㋒�_�E�ڋq��񒊏o����(A-3)�E���[�N�e�[�u���o�^����(A-4)
    -- ===============================================
    get_err_data(
      ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg     -- ���[�U�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�m��
    -- ===============================================
    COMMIT;
    -- ===============================================
    -- SVF�N������(A-5)
    -- ===============================================
    start_svf(
      ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg     -- ���[�U�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- ���[�N�e�[�u���f�[�^�폜(A-6)
    -- ===============================================
    delete_err_data(
      ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg     -- ���[�U�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      ov_retcode := lv_retcode;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf , 1 , 5000 );
      ov_errmsg  := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_retcode := cv_status_error;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
--
  END submain;
--
  /************************************************************************
   * Procedure Name  : main
   * Description     : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   ************************************************************************/
  PROCEDURE main(
    errbuf        OUT VARCHAR2     -- �G���[�E���b�Z�[�W
  , retcode       OUT VARCHAR2     -- ���^�[���E�R�[�h
  , iv_base_code  IN  VARCHAR2     -- ���_�R�[�h
  )
  IS
    -- ===============================================
    -- ���[�J���萔
    -- ===============================================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'main';  -- �v���V�[�W����
    -- ===============================================
    -- ���[�J���ϐ�
    -- ===============================================
    lv_errbuf              VARCHAR2(5000) DEFAULT NULL;             -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1)    DEFAULT cv_status_normal; -- ���^�[���E�R�[�h
    lv_errmsg              VARCHAR2(5000) DEFAULT NULL;             -- ���[�U�E�G���[����b�Z�[�W
    lv_message             VARCHAR2(5000) DEFAULT NULL;             -- �쐬���b�Z�[�W�i�[
    lb_retcode             BOOLEAN        DEFAULT NULL;             -- ���b�Z�[�W�o�͎����^�[���R�[�h
    lv_message_code        VARCHAR2(50)   DEFAULT NULL;             -- �I�����b�Z�[�W�R�[�h�i�[
--
  BEGIN
    -- ===============================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg     -- ���[�U�E�G���[�E���b�Z�[�W
    , iv_which      => cv_which      -- �o�͋敪
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submain(������)�Ăяo��
    -- ===============================================
    submain(
      ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
    , ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
    , ov_errmsg     => lv_errmsg     -- ���[�U�E�G���[�E���b�Z�[�W
    , iv_base_code  => iv_base_code  -- ���_�R�[�h
    );
    -- ===============================================
    -- �G���[�I�����Alv_errmsg��lv_errbuf�����O�ɏo�͂���
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errmsg      -- ���b�Z�[�W
                    , in_new_line => cn_number_0    -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG   -- �o�͋敪
                    , iv_message  => lv_errbuf      -- ���b�Z�[�W
                    , in_new_line => cn_number_1    -- ���s
                    );
    END IF;
    -- ===============================================
    -- �Ώی����o��
    -- ===============================================
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90000         -- �Ώی����o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��1('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )  -- �Ώۑ�����
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --�o�͋敪
                  , iv_message  => lv_message                    --���b�Z�[�W
                  , in_new_line => cn_number_0                   --���s
                  );
    -- ===============================================
    -- ���������o��(�G���[�������A��������:0�� �G���[����:1��)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
      gn_error_cnt  := cn_number_1;
--    ELSE
--      gn_normal_cnt := gn_target_cnt;
    END IF;
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90001         -- ���������o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��1('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )  -- �Ώۑ�����
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --�o�͋敪
                  , iv_message  => lv_message                    --���b�Z�[�W
                  , in_new_line => cn_number_0                   --���s
                  );
    -- ===============================================
    -- �G���[�����o��
    -- ===============================================
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- 'XXCCP'
                  , iv_name         => cv_msg_code_90002         -- �G���[�����o�̓��b�Z�[�W
                  , iv_token_name1  => cv_token_count            -- �g�[�N��1('COUNT')
                  , iv_token_value1 => TO_CHAR( gn_error_cnt )   -- �Ώۑ�����
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG                  --�o�͋敪
                  , iv_message  => lv_message                    --���b�Z�[�W
                  , in_new_line => cn_number_1                   --���s
                  );
    -- ===============================================
    -- �����I�����b�Z�[�W�o��
    -- ===============================================
    -- ����I��
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_code_90004;
    -- �x���I��
    ELSIF ( lv_retcode = cv_status_warn )   THEN
      lv_message_code := cv_msg_code_90005;
    -- �G���[�I��
    ELSIF ( lv_retcode = cv_status_error )  THEN
      lv_message_code := cv_msg_code_90006;
    END IF;
    lv_message := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxccp_appl_short_name  -- XXCCP'
                  , iv_name         => lv_message_code           -- �I�����b�Z�[�W
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG     --�o�͋敪
                  , iv_message  => lv_message       --���b�Z�[�W
                  , in_new_line => cn_number_0      --���s
                  );
    -- ===============================================
    -- �X�e�[�^�X�Z�b�g
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM , 1 , 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK014A06R;
/
