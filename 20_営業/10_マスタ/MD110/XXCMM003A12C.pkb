create or replace PACKAGE BODY XXCMM003A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A12C(body)
 * Description      : ���@�\�́A���_�����ɂ��ڋq�ڍs���ɓ��͂��ꂽ�ڋq�ɕR�t��
 *                    ���_�ύX���𒊏o���A�Ή�����ڋq�ǉ����̗\�񋒓_��񍀖ڂ�
 *                    �A�g����@�\�ł��B
 * MD.050           : ���_�X�V�f�[�^�A�g MD050_CMM_003_A12
 * Version          : 1.1
 *
 * Program List
 * -------------------- -----------------------------------------------------------------
 *  Name                 Description
 * -------------------- -----------------------------------------------------------------
 *  prc_upd_xxcok_cust_shift_info   �ڋq�ڍs���e�[�u�����_�������A�g�t���O�X�V(A-4)
 *  prc_upd_xxcmm_cust_accounts     �ڋq�ǉ����e�[�u���\�񋒓_���X�V(A-3)
 *  upd_for_cust_shift_cancel       �ڋq�ڍs �ύX�E���������(A-6)
 *  prc_init                        ��������(A-1)
 *  submain                         ���C�������v���V�[�W��(A-2:�����Ώۃf�[�^���o)
 *                                    �Eprc_init
 *                                    �Eupd_for_cust_shift_cancel
 *                                    �Eprc_upd_xxcmm_cust_accounts
 *                                    �Eprc_upd_xxcok_cust_shift_info
 *  main                            �R���J�����g���s�t�@�C���o�^�v���V�[�W��(A-5:�I������)
 *                                    �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   SCS Okuyama      �V�K�쐬
 *  2020/12/22    1.1   SCSK Yoshino     E_�{�ғ�_16384 �m�������Ή�
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
  cv_cust_shift_status_act  CONSTANT VARCHAR2(1) := 'A';  -- �ڋq�ڍs���X�e�[�^�X�i�m��ρj
  cv_base_split_flag_on     CONSTANT VARCHAR2(1) := '1';  -- ���_�����A�g�t���O�i�A�g�ρj
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
  cv_resv_selling_clr_flag  CONSTANT VARCHAR2(1) := '1';  -- �\�񔄏�����t���O�i�\������Ώہj
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_bullet             CONSTANT VARCHAR2(2) := '�E';
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
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
  gn_cust_shift_cnt NUMBER ;                  -- �ڋq�ڍs �ύX�E������Ώی���
  gd_process_date  DATE ;                     -- �Ɩ��������t
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt     EXCEPTION;
  global_check_lock_expt     EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_apl_name_ccp           CONSTANT VARCHAR2(5)  := 'XXCCP';               -- �A�h�I���F���ʁEIF�̈�
  cv_apl_name_cmm           CONSTANT VARCHAR2(5)  := 'XXCMM';               -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_pkg_name               CONSTANT VARCHAR2(12) := 'XXCMM003A12C';        -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_msg_xxccp_90008        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90008';    -- �ݶ������Ұ�����
  cv_msg_xxccp_91003        CONSTANT VARCHAR2(16) := 'APP-XXCCP1-91003';    -- ���Ѵװ
  cv_msg_xxcmm_00001        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00001';    -- �Ώۃf�[�^����
  cv_msg_xxcmm_00008        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00008';    -- ���b�N�G���[
  cv_msg_xxcmm_00300        CONSTANT VARCHAR2(16) := 'APP-XXCMM1-00300';    -- �f�[�^�X�V�G���[

  -- ���b�Z�[�W�g�[�N��
  cv_tkn_ng_table           CONSTANT VARCHAR2(8)  := 'NG_TABLE';            -- �e�[�u����
  cv_tkn_cust_code          CONSTANT VARCHAR2(7)  := 'CUST_CD';             -- �ڋq�R�[�h
  cv_tkn_rsv_base_act_date  CONSTANT VARCHAR2(13) := 'BASE_ACT_DATE';       -- �ڋq�ڍs��
  cv_tkn_rsv_base_cd        CONSTANT VARCHAR2(7)  := 'BASE_CD';             -- �V�S�����_�R�[�h
  --
  cv_tbl_nm_xcsi            CONSTANT VARCHAR2(12) := '�ڋq�ڍs���';        -- XXCOK_CUST_SHIFT_INFO
  cv_tbl_nm_xcac            CONSTANT VARCHAR2(12) := '�ڋq�ǉ����';        -- XXCMM_CUST_ACCOUNTS
  cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- ���t�t�H�[�}�b�g
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  --
  -- ���_�X�V�f�[�^�A�g�Ώێ擾�J�[�\��
  --
  CURSOR xxcmm003A12c_cur
  IS
    SELECT
      xcsi.cust_code,             -- �ڋq�R�[�h
      xcsi.cust_shift_date,       -- �ڋq�ڍs��
      xcsi.new_base_code,         -- �V�S�����_�R�[�h
      xcac.ROWID  AS  xcac_rowid, -- ���R�[�hID�i�ڋq�ǉ��j
      xcsi.ROWID  AS  xcsi_rowid  -- ���R�[�hID�i�ڋq�ڍs�j
    FROM
      xxcok_cust_shift_info       xcsi,   -- �ڋq�ڍs���e�[�u��
      hz_cust_accounts            hcac,   -- �ڋq�}�X�^�e�[�u��
      xxcmm_cust_accounts         xcac    -- �ڋq�ǉ����e�[�u��
    WHERE
          hcac.cust_account_id    = xcac.customer_id
      AND xcsi.cust_code          = hcac.account_number
      AND xcsi.status             = cv_cust_shift_status_act
      AND xcsi.base_split_flag    IS NULL
    FOR UPDATE OF xcsi.cust_code, xcac.customer_id NOWAIT
    ;
--
--
--
--
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
  /**********************************************************************************
   * Procedure Name   : upd_for_cust_shift_cancel
   * Description      : �ڋq�ڍs �ύX�E���������(A-6)
   ***********************************************************************************/
  PROCEDURE upd_for_cust_shift_cancel(
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_for_cust_shift_cancel'; -- �v���O������
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
--    lv_step       VARCHAR2(10);     -- �X�e�b�v
--
    -- ***  �ڋq�ڍs���J�[�\�� ***
--
  CURSOR l_cust_shift_cur
  IS
    SELECT xcsi.cust_code     AS cust_code     -- �ڋq�R�[�h
          ,xcsi.ROWID         AS xcsi_rowid    -- ���R�[�hID�i�ڋq�ڍs�j
          ,xcac.ROWID         AS xcac_rowid    -- ���R�[�hID�i�ڋq�ǉ��j
    FROM   xxcok_cust_shift_info       xcsi    -- �ڋq�ڍs���e�[�u��
          ,xxcmm_cust_accounts         xcac    -- �ڋq�ǉ����e�[�u��
    WHERE  xcsi.resv_selling_clr_flag = cv_resv_selling_clr_flag
    AND    xcsi.cust_shift_date       > gd_process_date
    AND    xcsi.cust_code             = xcac.customer_code
    FOR UPDATE OF xcsi.cust_code , xcac.customer_code NOWAIT
    ;
--
  l_cust_shift_rec    l_cust_shift_cur%ROWTYPE;
--
  BEGIN
--    lv_step := 'A-6-1';
    gn_cust_shift_cnt := 0 ;              -- �ڋq�ڍs �ύX�E���������
    OPEN l_cust_shift_cur ;
    --
    LOOP
      -- �����Ώۃf�[�^�E�J�[�\���t�F�b�`
      FETCH l_cust_shift_cur INTO l_cust_shift_rec ;
      EXIT WHEN l_cust_shift_cur%NOTFOUND;
--
--      lv_step := 'A-6-3';
      -- �ڋq�ǉ����X�V
      UPDATE xxcmm_cust_accounts xcac                                 -- �ڋq�ǉ����e�[�u��
      SET    xcac.rsv_sale_base_code     = NULL                       -- �\�񔄏㋒�_�R�[�h
            ,xcac.rsv_sale_base_act_date = NULL                       -- �\�񔄏㋒�_�L���J�n��
            ,xcac.last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
            ,xcac.last_update_date       = cd_last_update_date        -- �ŏI�X�V��
            ,xcac.last_update_login      = cn_last_update_login       -- �ŏI�X�V���O�C��
            ,xcac.request_id             = cn_request_id              -- �v��ID
            ,xcac.program_application_id = cn_program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
            ,xcac.program_id             = cn_program_id              -- �ݶ��ĥ��۸���ID
            ,xcac.program_update_date    = cd_program_update_date     -- �v���O�����X�V��
      WHERE xcac.ROWID                   = l_cust_shift_rec.xcac_rowid ;
--
--      lv_step := 'A-6-5';
--      -- �ڋq�ڍs���e�[�u��
      UPDATE xxcok_cust_shift_info       xcsi                         -- �ڋq�ڍs���e�[�u��
      SET    xcsi.resv_selling_clr_flag  = NULL                       -- �\�񔄏�����t���O
            ,xcsi.base_split_flag        = NULL                       -- ���_�������A�g�t���O
            ,xcsi.last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
            ,xcsi.last_update_date       = cd_last_update_date        -- �ŏI�X�V��
            ,xcsi.last_update_login      = cn_last_update_login       -- �ŏI�X�V���O�C��
            ,xcsi.request_id             = cn_request_id              -- �v��ID
            ,xcsi.program_application_id = cn_program_application_id  -- �ݶ��ĥ��۸��ѥ���ع����ID
            ,xcsi.program_id             = cn_program_id              -- �ݶ��ĥ��۸���ID
            ,xcsi.program_update_date    = cd_program_update_date     -- �v���O�����X�V��
      WHERE  xcsi.ROWID                  = l_cust_shift_rec.xcsi_rowid ;
--
      gn_cust_shift_cnt := gn_cust_shift_cnt + 1 ;                    -- �ڋq�ڍs �ύX�E����������J�E���g�A�b�v
    END LOOP ;
--
    CLOSE l_cust_shift_cur;
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ***  ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      IF l_cust_shift_cur%ISOPEN THEN
        CLOSE  l_cust_shift_cur;
      END IF;
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00008,     -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,        -- �g�[�N���R�[�h1
                        iv_token_value1 =>  (cv_tbl_nm_xcsi)        -- �g�[�N���l1
                      );
      lv_errbuf   :=  lv_errmsg;
      ov_errmsg   :=  lv_errmsg;
      ov_errbuf   :=  cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode  :=  cv_status_error;
      -- �G���[�����ݒ�
      gn_error_cnt := 1 ;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      RAISE global_process_expt;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_for_cust_shift_cancel;
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcok_cust_shift_info
   * Description      : �ڋq�ڍs���e�[�u�����_�������A�g�t���O�X�V(A-4)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcok_cust_shift_info(
    iv_rec        IN  xxcmm003A12c_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
    ov_errbuf     OUT VARCHAR2,                   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,                   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_upd_xxcok_cust_shift_info'; -- �v���O������
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
    lv_step := 'A-4.1';
    --
    -- �ڋq�ڍs���e�[�u�����_�������A�g�t���O�X�VSQL��
    UPDATE
      xxcok_cust_shift_info         xcsi                        -- �ڋq�ڍs���
    SET
      xcsi.base_split_flag        = cv_base_split_flag_on,      -- ���_�������A�g�t���O
      xcsi.last_updated_by        = cn_last_updated_by,         -- �ŏI�X�V��
      xcsi.last_update_date       = cd_last_update_date,        -- �ŏI�X�V��
      xcsi.last_update_login      = cn_last_update_login,       -- �ŏI�X�V���O�C��
      xcsi.request_id             = cn_request_id,              -- �v��ID
      xcsi.program_application_id = cn_program_application_id,  -- �ݶ��ĥ��۸��ѥ���ع����ID
      xcsi.program_id             = cn_program_id,              -- �ݶ��ĥ��۸���ID
      xcsi.program_update_date    = cd_program_update_date      -- �v���O�����X�V��
    WHERE
      xcsi.rowid  = iv_rec.xcsi_rowid                           -- ���R�[�hID�i�ڋq�ڍs�j
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
                        iv_name         =>  cv_msg_xxcmm_00300,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,            -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcsi,             -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h2
                        iv_token_value2 =>  iv_rec.cust_code,           -- �g�[�N���l2
                        iv_token_name3  =>  cv_tkn_rsv_base_act_date,   -- �g�[�N���R�[�h3
                        iv_token_value3 =>  TO_CHAR(iv_rec.cust_shift_date, cv_date_fmt), -- �g�[�N���l3
                        iv_token_name4  =>  cv_tkn_rsv_base_cd,         -- �g�[�N���R�[�h4
                       iv_token_value4  =>  iv_rec.new_base_code        -- �g�[�N���l4
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
  END prc_upd_xxcok_cust_shift_info;
--
--
--
--
  /**********************************************************************************
   * Procedure Name   : prc_upd_xxcmm_cust_accounts
   * Description      : �ڋq�ǉ����e�[�u���\�񋒓_���X�V(A-3)
   ***********************************************************************************/
  PROCEDURE prc_upd_xxcmm_cust_accounts(
    iv_rec        IN  xxcmm003A12c_cur%ROWTYPE,   -- �����Ώۃf�[�^���R�[�h
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
      xxcmm_cust_accounts         xcac                          -- �ڋq�ǉ����
    SET
      xcac.rsv_sale_base_act_date = iv_rec.cust_shift_date,     -- �\�񔄏㋒�_�L���J�n��
      xcac.rsv_sale_base_code     = iv_rec.new_base_code,       -- �\�񔄏㋒�_�R�[�h
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
                        iv_name         =>  cv_msg_xxcmm_00300,         -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,            -- �g�[�N���R�[�h1
                        iv_token_value1 =>  cv_tbl_nm_xcac,             -- �g�[�N���l1
                        iv_token_name2  =>  cv_tkn_cust_code,           -- �g�[�N���R�[�h2
                        iv_token_value2 =>  iv_rec.cust_code,           -- �g�[�N���l2
                        iv_token_name3  =>  cv_tkn_rsv_base_act_date,   -- �g�[�N���R�[�h3
                        iv_token_value3 =>  TO_CHAR(iv_rec.cust_shift_date, cv_date_fmt), -- �g�[�N���l3
                        iv_token_name4  =>  cv_tkn_rsv_base_cd,         -- �g�[�N���R�[�h4
                        iv_token_value4 =>  iv_rec.new_base_code        -- �g�[�N���l4
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
    lv_step       VARCHAR2(10);     -- �X�e�b�v
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
    -- �R���J�����g�E�p�����[�^�̃��O�o��
    -- ���b�Z�[�W�Z�b�g
    lv_errmsg   :=  xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,    -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_90008  -- ���b�Z�[�W�R�[�h
                    );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => lv_errmsg --�p�����[�^�Ȃ����b�Z�[�W
    );
    --��s�}��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
    );

-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
    -- �Ɩ����t�̎擾
    gd_process_date := xxccp_common_pkg2.get_process_date ;
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END

--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_apl_name_ccp,          -- �A�v���P�[�V�����Z�k��
                      iv_name         =>  cv_msg_xxccp_91003        -- ���b�Z�[�W�R�[�h
                    );
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      RAISE global_process_expt;
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
    xxcmm003A12c_rec    xxcmm003A12c_cur%ROWTYPE;

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
      lv_errbuf,    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
    -- ===============================
    -- A-6.�ڋq�ڍs �ύX�E���������
    -- ===============================
    lv_step := 'A-6';

      upd_for_cust_shift_cancel(
        lv_errbuf,    -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,   -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END
    -- ===============================
    -- A-2.�����Ώۃf�[�^���o
    -- ===============================
    lv_step := 'A-2';
    OPEN xxcmm003A12c_cur;
    --
    LOOP
      -- �����Ώۃf�[�^�E�J�[�\���t�F�b�`
      FETCH xxcmm003A12c_cur INTO xxcmm003A12c_rec;
      EXIT WHEN xxcmm003A12c_cur%NOTFOUND;
      --
      gn_target_cnt := xxcmm003A12c_cur%ROWCOUNT;
      ln_err_cnt    := 0;
      --
      -- ===============================
      -- A-3.�ڋq�ǉ����e�[�u���\�񋒓_���X�V
      -- ===============================
      lv_step := 'A-3';
      prc_upd_xxcmm_cust_accounts(
        xxcmm003A12c_rec,   -- �J�[�\�����R�[�h
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
      -- ===============================
      -- A-4.�ڋq�ڍs���e�[�u�����_�������A�g�t���O�X�V
      -- ===============================
      lv_step := 'A-4';
      prc_upd_xxcok_cust_shift_info(
        xxcmm003A12c_rec,   -- �J�[�\�����R�[�h
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
    CLOSE xxcmm003A12c_cur;
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
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF xxcmm003A12c_cur%ISOPEN THEN
        CLOSE  xxcmm003A12c_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg   :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_apl_name_cmm,        -- �A�v���P�[�V�����Z�k��
                        iv_name         =>  cv_msg_xxcmm_00008,     -- ���b�Z�[�W�R�[�h
                        iv_token_name1  =>  cv_tkn_ng_table,        -- �g�[�N���R�[�h1
                        iv_token_value1 =>  (cv_tbl_nm_xcac || cv_msg_bullet || cv_tbl_nm_xcsi) -- �g�[�N���l1
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
      IF xxcmm003A12c_cur%ISOPEN THEN
        CLOSE xxcmm003A12c_cur;
      END IF;
      -- ���b�Z�[�W�Z�b�g
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                      cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf,
                      1,
                      5000
                    );
      -- �����X�e�[�^�X�Z�b�g
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF xxcmm003A12c_cur%ISOPEN THEN
        CLOSE xxcmm003A12c_cur;
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
    retcode       OUT VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
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
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
    cv_cust_shift_msg  CONSTANT VARCHAR2(100) := 'APP-XXCMM1-10501'; -- �ڋq�ڍs �ύX�E����������b�Z�[�W
    cv_app_sht_nam_xxcmm CONSTANT VARCHAR2(10)  := 'XXCMM';            -- �A�h�I���F���ʁEIF�̈�
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END
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
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      IF (LENGTHB(TRIM(lv_errmsg)) > 0) THEN
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => LTRIM(lv_errmsg)   --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
      IF (LENGTHB(TRIM(lv_errbuf)) > 0) THEN
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => LTRIM(lv_errbuf)   --�G���[���b�Z�[�W
        );
      END IF;
    END IF;
    --��s�}��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt + gn_cust_shift_cnt )
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
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
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
--
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD START
--
    --����������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_sht_nam_xxcmm
                    ,iv_name         => cv_cust_shift_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_cust_shift_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
--
-- 2020/12/22 Ver.1.1 [E_�{�ғ�_16834] SCSK K.Yoshino ADD END
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
    );
    --�󔒍s�o��
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => ''
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => fnd_file.log
      ,buff   => gv_out_msg
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
END XXCMM003A12C;
/
