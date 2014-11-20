create or replace PACKAGE BODY XXCMM003A13C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A13C(body)
 * Description      : ���̃R���J�����g�����́A�Q�̋@�\�������Ă��܂� �B
 *                      �i�P�j�ڋq�ڍs�E���_�����ɂ�锄�㋒�_�̕ύX�\������A
 *                            �K�p�J�n���������ɔ��f����B
 *                      �i�Q�j�������ɁA�O�����㋒�_�R�[�h���X�V����B
 * MD.050           : �L�����_�f�[�^���f MD050_CMM_003_A13
 * Version          : Draft3A
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_xxcmm_cust_accounts     �ڋq�ǉ����e�[�u���\�񋒓_���X�V(A-3)
 *  prc_init                        ��������(A-1)
 *  submain                         ���C�������v���V�[�W��(A-2:�����Ώۃf�[�^���o)
 *                                    �Eprc_init
 *                                    �Eprc_upd_xxcmm_cust_accounts
 *  main                            �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5:�I������)
 *                                    �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/13    1.0   SCS Okuyama      �V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_bracket_f          CONSTANT VARCHAR2(1) := '[';
  cv_msg_bracket_t          CONSTANT VARCHAR2(1) := ']';
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
  global_process_expt        EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt            EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_check_para_expt     EXCEPTION;     -- �p�����[�^�G���[
  global_check_lock_expt     EXCEPTION;     -- ���b�N�擾�G���[

  --
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';               -- �A�h�I���F���ʁEIF�̈�
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';               -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A13C';        -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';    -- ���Ѵװ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';    -- �Ώۃf�[�^����
  cv_msg_xxcmm_00002        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00002';    -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';    -- ���b�N�G���[
  cv_msg_xxcmm_00303        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00303';    -- �f�[�^�X�V�G���[
  cv_msg_xxcmm_00333        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00333';    -- �p�����[�^�G���[
  -- ���b�Z�[�W�g�[�N��
  cv_tkn_ng_profile         CONSTANT VARCHAR2(10) := 'NG_PROFILE';          -- �v���t�@�C����
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';            -- �e�[�u����
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';             -- �ڋq�R�[�h
  cv_tkn_sale_base_code     CONSTANT VARCHAR2(12) := 'SALE_BASE_CD';        -- ���㋒�_�R�[�h
  cv_tkn_para_date          CONSTANT VARCHAR2(9)  := 'PARA_DATE';           -- �������t�i�p�����[�^�j
  cv_tkn_proc_date          CONSTANT VARCHAR2(9)  := 'PROC_DATE';           -- �Ɩ����t
  --
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '�ڋq�ǉ����';        -- XXCMM_CUST_ACCOUNTS
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- ���t�t�H�[�}�b�g
  cv_month_fmt              CONSTANT VARCHAR2(6)  := 'YYYYMM';              -- ���t�H�[�}�b�g
  cv_profile_ctrl_cal       CONSTANT VARCHAR2(26) := 'XXCMM1_003A00_SYS_CAL_CODE';  -- ���щғ�������޺��ޒ�`���̧��
  cv_term_immediate         CONSTANT VARCHAR2(8)  := '00_00_00';            -- �x���������i�����j
  cv_lang_ja                CONSTANT VARCHAR2(2)  := 'JA';                  -- ����i���{�j
  cv_rec_status_active      CONSTANT VARCHAR2(1)  := 'A';                   -- EBS�f�[�^�X�e�[�^�X�i�L���j
  cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';                   -- �t���O�iYes�j
  cv_site_use_cd_bt         CONSTANT VARCHAR2(7)  := 'BILL_TO';             -- �g�p�ړI�R�[�h�i������j
  cv_para01_name            CONSTANT VARCHAR2(6)  := '������';              -- �ݶ��ĥ���Ұ���01
  cv_sgl_space              CONSTANT VARCHAR2(1)  := CHR(32);               -- ���p�X�y�[�X����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_cal_code           VARCHAR2(10);   -- �V�X�e���ғ����J�����_�R�[�h�l
  gv_para_proc_date     VARCHAR2(10);   -- ������
  gd_para_proc_date     DATE;           -- ������
  gd_next_proc_date     DATE;           -- ���Ɩ����t
  gv_now_proc_month     VARCHAR2(6);    -- �Ɩ����t��(YYYYMM)
  gv_next_proc_month    VARCHAR2(6);    -- ���Ɩ����t��(YYYYMM)
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --
  -- A-2.�����Ώۃf�[�^���o�J�[�\��
  --
  CURSOR  xxcmm003A13c_cur
  IS
    SELECT
      xcac.customer_code                  AS  customer_code,          -- �ڋq�R�[�h
      xcac.sale_base_code                 AS  sale_base_code,         -- ���㋒�_�R�[�h
      xcac.past_sale_base_code            AS  past_sale_base_code,    -- �O�����㋒�_�R�[�h
      xcac.rsv_sale_base_code             AS  rsv_sale_base_code,     -- �\�񔄏㋒�_�R�[�h
      TRUNC(xcac.rsv_sale_base_act_date)  AS  rsv_sale_base_act_date, -- �\�񔄏㋒�_�L���J�n��
      xcac.ROWID                          AS  xcac_rowid,             -- ���R�[�hID�i�ڋq�ǉ����j
      xcac.delivery_base_code             AS  delivery_base_code,     -- �[�i���_�R�[�h
      xcac.bill_base_code                 AS  bill_base_code,         -- �������_�R�[�h
      xcac.receiv_base_code               AS  receiv_base_code,       -- �������_�R�[�h
      TRUNC(xcac.past_final_tran_date)    AS  past_final_tran_date,   -- �O���ŏI�����
      TRUNC(xcac.final_tran_date)         AS  final_tran_date,        -- �ŏI�����
      xcac.past_customer_status           AS  past_customer_status,   -- �O���ڋq�X�e�[�^�X
      hzpt.duns_number_c                  AS  customer_status,        -- �ڋq�X�e�[�^�X
      ratt.name                           AS  term_name               -- �x��������
    FROM
      xxcmm_cust_accounts       xcac,   -- �ڋq�ǉ����e�[�u��
      hz_cust_accounts          hzca,   -- �ڋq�}�X�^�e�[�u��
      hz_parties                hzpt,   -- �p�[�e�B�e�[�u��
      hz_party_sites            hzps,   -- �p�[�e�B�T�C�g�e�[�u��
      hz_cust_acct_sites_all    hzsa,   -- �ڋq���ݒn�e�[�u��
      hz_cust_site_uses_all     hzsu,   -- �ڋq�g�p�ړI�e�[�u��
      ra_terms_tl               ratt    -- �x�������e�[�u��
    WHERE
          xcac.customer_id              =   hzca.cust_account_id
      AND hzca.party_id                 =   hzpt.party_id
      AND hzpt.party_id                 =   hzps.party_id
      AND hzsa.cust_account_id          =   hzca.cust_account_id
      AND hzsa.party_site_id            =   hzps.party_site_id
      AND hzsu.cust_acct_site_id(+)     =   hzsa.cust_acct_site_id
      AND ratt.term_id(+)               =   hzsu.payment_term_id
      AND hzps.status                   =   cv_rec_status_active
      AND hzps.identifying_address_flag =   cv_flag_yes
      AND hzsu.status(+)                =   cv_rec_status_active
      AND hzsu.site_use_code(+)         =   cv_site_use_cd_bt
      AND ratt.language(+)              =   cv_lang_ja
      AND (
                (xcac.rsv_sale_base_act_date <= gd_next_proc_date)
            OR  (
                      (gv_now_proc_month <> gv_next_proc_month)
                  AND
                      (
                              ((cv_sgl_space || xcac.past_sale_base_code)   <>  (cv_sgl_space || xcac.sale_base_code))
                          OR  ((cv_sgl_space || xcac.past_final_tran_date)  <>  (cv_sgl_space || xcac.final_tran_date))
                          OR  ((cv_sgl_space || xcac.past_customer_status)  <>  (cv_sgl_space || hzpt.duns_number_c))
                      )
                )
          )
    FOR UPDATE OF xcac.customer_id NOWAIT
    ;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : �ڋq�ǉ����e�[�u���\�񋒓_���X�V(A-3)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  xxcmm003A13c_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_xxcmm_cust_accounts'; -- �v���O������
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    lv_step := 'A-3.1';
    --
    -- �ڋq�ǉ����e�[�u���\�񋒓_���X�VSQL��
    UPDATE
      -- �ڋq�ǉ����
      xxcmm_cust_accounts         xcac
    SET
      -- �O�����㋒�_�R�[�h
      xcac.past_sale_base_code    = (
                                      CASE  WHEN
                                              (
                                                    (gv_now_proc_month <> gv_next_proc_month)
                                                AND ((cv_sgl_space || iv_rec.past_sale_base_code)
                                                            <> (cv_sgl_space || iv_rec.sale_base_code))
                                              ) THEN
                                        iv_rec.sale_base_code
                                      ELSE
                                        iv_rec.past_sale_base_code
                                      END
                                    ),
      -- ���㋒�_�R�[�h
      xcac.sale_base_code         = (
                                      CASE  WHEN
                                              (
                                                iv_rec.rsv_sale_base_act_date <= gd_next_proc_date
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.sale_base_code
                                      END
                                    ),
      -- �\�񔄏㋒�_�R�[�h
      xcac.rsv_sale_base_code     = (
                                      CASE  WHEN
                                              (
                                                iv_rec.rsv_sale_base_act_date <= gd_next_proc_date
                                              ) THEN
                                        NULL
                                      ELSE
                                        iv_rec.rsv_sale_base_code
                                      END
                                    ),
      -- �\�񔄏㋒�_�L���J�n��
      xcac.rsv_sale_base_act_date = (
                                      CASE  WHEN
                                              (
                                                iv_rec.rsv_sale_base_act_date <= gd_next_proc_date
                                              ) THEN
                                        NULL
                                      ELSE
                                        iv_rec.rsv_sale_base_act_date
                                      END
                                    ),
      -- �O���ŏI�����
      xcac.past_final_tran_date   = (
                                      CASE  WHEN
                                              (
                                                    (gv_now_proc_month <> gv_next_proc_month)
                                                AND ((cv_sgl_space || iv_rec.past_final_tran_date)
                                                          <> (cv_sgl_space || iv_rec.final_tran_date))
                                              ) THEN
                                        iv_rec.final_tran_date
                                      ELSE
                                        iv_rec.past_final_tran_date
                                      END
                                    ),
      -- �O���ڋq�X�e�[�^�X
      xcac.past_customer_status   = (
                                      CASE  WHEN
                                              (
                                                    (gv_now_proc_month <> gv_next_proc_month)
                                                AND ((cv_sgl_space || iv_rec.past_customer_status)
                                                            <> (cv_sgl_space || iv_rec.customer_status))
                                              ) THEN
                                        iv_rec.customer_status
                                      ELSE
                                        iv_rec.past_customer_status
                                      END
                                    ),
      -- �[�i���_�R�[�h
      xcac.delivery_base_code     = (
                                      CASE  WHEN
                                              (
                                                    (iv_rec.rsv_sale_base_act_date <= gd_next_proc_date)
                                                AND ((cv_sgl_space || iv_rec.term_name)
                                                                          = cv_sgl_space || cv_term_immediate)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.delivery_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.bill_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.receiv_base_code)
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.delivery_base_code
                                      END
                                    ),
      -- �������_�R�[�h
      xcac.bill_base_code         = (
                                      CASE  WHEN
                                              (
                                                    (iv_rec.rsv_sale_base_act_date <= gd_next_proc_date)
                                                AND ((cv_sgl_space || iv_rec.term_name)
                                                                          = cv_sgl_space || cv_term_immediate)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.delivery_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.bill_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.receiv_base_code)
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.bill_base_code
                                      END
                                    ),
      -- �������_�R�[�h
      xcac.receiv_base_code       = (
                                      CASE  WHEN
                                              (
                                                    (iv_rec.rsv_sale_base_act_date <= gd_next_proc_date)
                                                AND ((cv_sgl_space || iv_rec.term_name)
                                                                          = cv_sgl_space || cv_term_immediate)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.delivery_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.bill_base_code)
                                                AND ((cv_sgl_space || iv_rec.sale_base_code)
                                                                          = cv_sgl_space || iv_rec.receiv_base_code)
                                              ) THEN
                                        iv_rec.rsv_sale_base_code
                                      ELSE
                                        iv_rec.receiv_base_code
                                      END
                                    ),
      -- WHO
      xcac.last_updated_by        = cn_last_updated_by,         -- �ŏI�X�V��
      xcac.last_update_date       = cd_last_update_date,        -- �ŏI�X�V��
      xcac.last_update_login      = cn_last_update_login,       -- �ŏI�X�V���O�C��
      xcac.request_id             = cn_request_id,              -- �v��ID
      xcac.program_application_id = cn_program_application_id,  -- �ݶ��ĥ��۸��ѥ���ع����ID
      xcac.program_id             = cn_program_id,              -- �ݶ��ĥ��۸���ID
      xcac.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
    WHERE
      xcac.rowid  = iv_rec.xcac_rowid                           -- ���R�[�hID�i�ڋq�ǉ��j
    ;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,            -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00303,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,            -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h2
                        iv_token_value2 =>  iv_rec.customer_code,       -- �g�[�N���l2
                        iv_token_name3  =>  cv_tkn_sale_base_code,      -- �g�[�N���R�[�h3
                        iv_token_value3 =>  iv_rec.sale_base_code       -- �g�[�N���l3
                      );
      ov_errmsg   :=  lv_errmsg;
      lv_errbuf   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                      );
      ov_errbuf   := lv_errbuf || cv_msg_bracket_f || 
                     cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || cv_msg_bracket_t;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_upd_xxcmm_cust_accounts;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE prc_init(
    iv_proc_date  IN  VARCHAR2,     --   ������
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_init'; -- �v���O������
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
    lv_step             VARCHAR2(10);   -- �X�e�b�v
    lv_now_proc_date    VARCHAR2(10);   -- �Ɩ����t�i������j
    lv_proc_date        VARCHAR2(10);   -- �p�����[�^������
    ld_now_proc_date    DATE;           -- �Ɩ����t
    ld_next_proc_date   DATE;           -- ���Ɩ����t
    lv_para_edit_buf    VARCHAR2(60);   -- �o�͗p���Ұ�������ҏW�̈�
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    lv_step := 'A-1.1';
    --
    -- �Ɩ����t�擾
    --
    ld_now_proc_date    :=  xxccp_common_pkg2.get_process_date;
    IF (iv_proc_date IS NULL) THEN
      lv_proc_date      :=  TO_CHAR(TRUNC(ld_now_proc_date), cv_date_fmt);
    ELSE
      lv_proc_date      :=  SUBSTRB(iv_proc_date, 1, 10);
    END IF;
    --
    -- �Ɩ����t��(YYYYMM)
    gv_now_proc_month   :=  TO_CHAR(ld_now_proc_date, cv_month_fmt);
    lv_step := 'A-1.2';
    --
    -- �R���J�����g�E�p�����[�^�̃��O�o��
    -- ������
    lv_para_edit_buf  :=  cv_para01_name || cv_msg_part || cv_msg_bracket_f || lv_proc_date || cv_msg_bracket_t;
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => lv_para_edit_buf
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => lv_para_edit_buf
    );
    --��s�}��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --
    -- �v���t�@�C���l�擾
    --
    lv_step := 'A-1.3';
    -- �V�X�e���ғ����J�����_�R�[�h�擾
    gv_cal_code := fnd_profile.value(cv_profile_ctrl_cal);
    IF (gv_cal_code IS NULL) THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                      iv_name           =>  cv_msg_xxcmm_00002,   -- �v���t�@�C���擾�G���[
                      iv_token_name1    =>  cv_tkn_ng_profile,    -- �g�[�N��(NG_PROFILE)
                      iv_token_value1   =>  cv_profile_ctrl_cal   -- �v���t�@�C����`��
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- �p�����[�^�`�F�b�N�i�������j
    --
    lv_step := 'A-1.4';
    lv_now_proc_date  :=  TO_CHAR(ld_now_proc_date, cv_date_fmt);
    IF (TRIM(lv_proc_date) IS NOT NULL) THEN
      IF (lv_proc_date > lv_now_proc_date) THEN
        -- �p�����[�^�́u�������v�� �Ɩ����t �ł���ꍇ�A�G���[
        -- ���b�Z�[�W�擾
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_apl_name_cmm,      -- �A�v���P�[�V�����Z�k��
                          iv_name         =>  cv_msg_xxcmm_00333,   -- ���b�Z�[�W�R�[�h
                          iv_token_name1  =>  cv_tkn_para_date,     -- �g�[�N���R�[�h1
                          iv_token_value1 =>  lv_proc_date,         -- �g�[�N���l1
                          iv_token_name2  =>  cv_tkn_proc_date,     -- �g�[�N���R�[�h2
                          iv_token_value2 =>  lv_now_proc_date      -- �g�[�N���l2
                        );
        -- �p�����[�^�G���[��O
        RAISE global_check_para_expt;
        --
      END IF;
    END IF;
    --
    -- ���������O���[�o���ϐ��Ɋi�[
    --
    gv_para_proc_date :=  lv_proc_date;
    gd_para_proc_date :=  TO_DATE(lv_proc_date, cv_date_fmt);
    --
    -- ���Ɩ����t�擾
    --
    lv_step := 'A-1.5';
    ld_next_proc_date   :=  xxccp_common_pkg2.get_working_day(
                              gd_para_proc_date,
                              1,
                              gv_cal_code
                            );
    gd_next_proc_date   :=  TRUNC(ld_next_proc_date);
    -- ���Ɩ����t��(YYYYMM)
    gv_next_proc_month  :=  TO_CHAR(gd_next_proc_date, cv_month_fmt);
    --
    --
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �p�����[�^�G���[��O�n���h�� ***
    WHEN global_check_para_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_init;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date  IN  VARCHAR2,   --   �R���J�����g�E�p�����[�^ ������
    ov_errbuf     OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
--
    -- *** ���[�J���ϐ� ***
    lb_err_flg    BOOLEAN;          -- �G���[�L��
    ln_err_cnt    NUMBER;           -- �G���[�������i�P�ڋq�P�ʁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    xxcmm003A13c_rec    xxcmm003A13c_cur%ROWTYPE;
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
   -- �G���[�L����������
   lb_err_flg := FALSE;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.����������
    -- ===============================
    lv_step := 'A-1';
    prc_init(
      iv_proc_date, -- ������
      lv_errbuf,    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    -- A-2.�����Ώۃf�[�^���o
    -- ===============================
    lv_step := 'A-2';
    OPEN  xxcmm003A13c_cur;
    --
    LOOP
      -- �����Ώۃf�[�^�E�J�[�\���t�F�b�`
      FETCH xxcmm003A13c_cur INTO xxcmm003A13c_rec;
      EXIT WHEN xxcmm003A13c_cur%NOTFOUND;
      --
      gn_target_cnt := xxcmm003A13c_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      --
      -- ===============================
      -- A-3.�ڋq�ǉ����e�[�u���L�����_���X�V
      -- ===============================
      lv_step := 'A-3';
      prc_upd_xxcmm_cust_accounts(
        xxcmm003A13c_rec,   -- �J�[�\�����R�[�h
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> cv_status_normal) THEN
        lb_err_flg  :=  TRUE;
        ln_err_cnt  :=  1;
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
        --
        lv_errmsg := NULL;
        lv_errbuf := NULL;
        --
      END IF;
      --
      -- ���������A�G���[�����̃J�E���g
      IF (ln_err_cnt = 0) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt := gn_error_cnt + ln_err_cnt;
      END IF;
      --
    END LOOP;
    --
    CLOSE xxcmm003A13c_cur;
    --
    IF (lb_err_flg = FALSE) THEN
      -- �Ώۃf�[�^�Ȃ����̃��b�Z�[�W
      IF (gn_target_cnt = 0) THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                          iv_name         =>  cv_msg_xxcmm_00001      -- ���b�Z�[�W�R�[�h
                        );
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
        );
      END IF;
    ELSE
      -- �X�V�G���[���������Ă���ׁA�G���[���Z�b�g
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    -- *** �p�����[�^�G���[��O�n���h�� ***
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF xxcmm003A13c_cur%ISOPEN THEN
        CLOSE  xxcmm003A13c_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00008,     -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,        -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac          -- �g�[�N���l1
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF xxcmm003A13c_cur%ISOPEN THEN
        CLOSE xxcmm003A13c_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF xxcmm003A13c_cur%ISOPEN THEN
        CLOSE xxcmm003A13c_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
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
    errbuf        OUT VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,     -- ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date  IN  VARCHAR2      -- �R���J�����g�E�p�����[�^�������t
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    --
    cv_log             CONSTANT VARCHAR2(100) := 'LOG';              -- ���O
    cv_output          CONSTANT VARCHAR2(100) := 'OUTPUT';           -- �A�E�g�v�b�g
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
    ----------------------------------
    -- ���O�w�b�_�o��
    ----------------------------------
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output,
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_proc_date, -- �R���J�����g�E�p�����[�^�������t
      lv_errbuf,    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (LENGTHB(TRIM(lv_errmsg)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.output,
          buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      IF (LENGTHB(TRIM(lv_errbuf)) > 0) THEN
        fnd_file.put_line(
          which  => fnd_file.log,
          buff   => LTRIM(lv_errbuf)   --�G���[���b�Z�[�W
        );
      END IF;
    END IF;
    --��s�}��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --�󔒍s�o��
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => ''
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => ''
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
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    fnd_file.put_line(
      which  => fnd_file.output,
      buff   => gv_out_msg
    );
    fnd_file.put_line(
      which  => fnd_file.log,
      buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM003A13C;
/