CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A23C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A23C (body)
 * Description      : �T���}�X�^�����ɁA������z�Ŕ�������T���f�[�^���쐬���̔��T�����֓o�^����
 * MD.050           : ��z�T���f�[�^�쐬 MD050_COK_024_A23
 * Version          : 1.1
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  init                   A-1.��������
 *  get_data               A-2.��z�T���������o
 *  cre_sls_dedctn         A-3.�̔��T���f�[�^�o�^
 *  submain                ���C�������v���V�[�W��
 *  main                   ��z�T���f�[�^�쐬�v���V�[�W��(A-4.�I���������܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2020/04/13    1.0   M.Sato           �V�K�쐬
 *  2021/04/06    1.1   K.Yoshikawa      ��z�T���������בΉ�
 *
 *****************************************************************************************/
--
--###########################  �Œ�O���[�o���萔�錾�� START  ###########################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--############################  �Œ�O���[�o���萔�錾�� END  ############################
--
--###########################  �Œ�O���[�o���ϐ��錾�� START  ###########################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--############################  �Œ�O���[�o���ϐ��錾�� END  ############################
--
--##############################  �Œ苤�ʗ�O�錾�� START  ##############################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
--###############################  �Œ苤�ʗ�O�錾�� END  ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK024A23C';                    -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10) := 'XXCCP';                           -- ���ʗ̈�Z�k�A�v����
  cv_xxcok_short_nm         CONSTANT VARCHAR2(10) := 'XXCOK';                           -- �ʊJ���̈�Z�k�A�v����
  -- ���b�Z�[�W����
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00001';                -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';                -- �Ɩ����t�擾�G���[
  cv_master_err_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10652';                -- �}�X�^�s���G���[���b�Z�[�W
  cv_cus_chain_corp         CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10648';                -- �ڋq�A�`�F�[���A��Ƃ̂����ꂩ1��
  cv_base_cd                CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10638';                -- ���_�R�[�h
-- 2021/04/06 Ver1.1 ADD Start
  cv_accounting_customer    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10793';                -- �v��ڋq
-- 2021/04/06 Ver1.1 ADD End
  cv_deduction_amount       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10645';                -- �T���z
  cv_tax_cd                 CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10646';                -- �ŃR�[�h
  cv_tax_credit             CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10647';                -- �T���Ŋz
  cv_target_rec_msg         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';                -- �Ώی������b�Z�[�W
  cv_success_rec_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';                -- �����������b�Z�[�W
  cv_error_rec_msg          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';                -- �G���[�������b�Z�[�W
  cv_skip_rec_msg           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90003';                -- �X�L�b�v�������b�Z�[�W
  cv_normal_msg             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';                -- ����I�����b�Z�[�W
  cv_warn_msg               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';                -- �x���I�����b�Z�[�W
  cv_error_msg              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';                -- �G���[�I���S���[���o�b�N
  -- �g�[�N��
  cv_tkn_condition_no       CONSTANT VARCHAR2(20) := 'CONDITION_NO';                    -- �T���ԍ�
  cv_tkn_column_name        CONSTANT VARCHAR2(20) := 'COLUMN_NAME';                     -- ���ږ�
  cv_cnt_token              CONSTANT VARCHAR2(20) := 'COUNT';                           -- �������b�Z�[�W�p�g�[�N����
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT  VARCHAR2(1) := 'Y';                               -- �t���O�l:Y
  -- �̔��T�����e�[�u���ɐݒ肷��Œ�l
  cv_created_sec            CONSTANT  VARCHAR2(1) := 'F';                               -- �쐬���敪
  cv_status                 CONSTANT  VARCHAR2(1) := 'N';                               -- �X�e�[�^�X
  cv_gl_rel_flag            CONSTANT  VARCHAR2(1) := 'N';                               -- GL�A�g�t���O
  cv_cancel_flag            CONSTANT  VARCHAR2(1) := 'N';                               -- ����t���O
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ��z�T���������[�N�e�[�u����`
  TYPE gr_dedctn_cond_rec IS RECORD(
       condition_id                 xxcok_condition_header.condition_id%TYPE                -- �T������ID
      ,condition_no                 xxcok_condition_header.condition_no%TYPE                -- �T���ԍ�
      ,corp_code                    xxcok_condition_header.corp_code%TYPE                   -- ��ƃR�[�h
      ,chain_code                   xxcok_condition_header.deduction_chain_code%TYPE        -- �T���p�`�F�[���R�[�h
      ,customer_code                xxcok_condition_header.customer_code%TYPE               -- �ڋq�R�[�h(����)
      ,data_type                    xxcok_condition_header.data_type%TYPE                   -- �f�[�^���
      ,tax_code                     xxcok_condition_header.tax_code%TYPE                    -- �ŃR�[�h
      ,condition_line_id            xxcok_condition_lines.condition_line_id%TYPE            -- �T���ڍ�ID
-- 2021/04/06 Ver1.1 MOD Start
--      ,accounting_base              xxcok_condition_lines.accounting_base%TYPE              -- �v�㋒�_
      ,accounting_customer_code     xxcok_condition_lines.accounting_customer_code%TYPE     -- �v��ڋq
      ,sale_base_code               xxcmm_cust_accounts.sale_base_code%TYPE                 -- ���㋒�_
-- 2021/04/06 Ver1.1 MOD End
      ,deduction_amount             xxcok_condition_lines.deduction_amount%TYPE             -- �T���z(�{��)
      ,deduction_tax                xxcok_condition_lines.deduction_tax_amount%TYPE         -- �T���Ŋz
  );
--
  -- ���[�N�e�[�u���^��`
  TYPE g_dedctn_cond_ttype    IS TABLE OF gr_dedctn_cond_rec INDEX BY BINARY_INTEGER;
  gt_dedctn_cond_tbl        g_dedctn_cond_ttype;                                   -- �̔��T���f�[�^
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�����擾
--
  gd_accounting_date                  DATE;                                         -- �T���f�[�^�v���
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : A-1.��������
   ***********************************************************************************/
  PROCEDURE init( ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
                 ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
                 ,ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                                 -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);       -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);          -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);       -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ld_process_date                   DATE;                                        -- �Ɩ����t
--
    -- *** ���[�J����O ***

    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- �ϐ��̏�����
    ld_process_date := NULL;
    --==================================
    -- �P�D�Ɩ����t�擾
    --==================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_xxcok_short_nm
                                             ,cv_process_date_msg
                                             );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    -- ����Ɏ擾�ł��Ă����ꍇ
    ELSE
      -- �T���f�[�^�̌v��������߂�
      gd_accounting_date := ADD_MONTHS ( trunc ( ld_process_date , 'month' ) , 1 );
    --
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#################################  �Œ��O������ END  #################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : A-2.��z�T���������o
   ***********************************************************************************/
  PROCEDURE get_data( ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
                     ,ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
                     ,ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_fix_dedcton_type     CONSTANT VARCHAR2(3)   := '070';      -- ��z�T���^�C�v
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� (��z�T���������o)***
    CURSOR fixed_deduction_cur
    IS
      SELECT xch.condition_id             AS condition_id       -- �T������ID
            ,xch.condition_no             AS condition_no       -- �T���ԍ�
            ,xch.corp_code                AS corp_code          -- ��ƃR�[�h
            ,xch.deduction_chain_code     AS chain_code         -- �T���p�`�F�[���R�[�h
            ,xch.customer_code            AS customer_code      -- �ڋq�R�[�h(����)
            ,xch.data_type                AS data_type          -- �f�[�^���
            ,xch.tax_code                 AS tax_code           -- �ŃR�[�h
            ,xcl.condition_line_id        AS condition_line_id  -- �T���ڍ�ID
-- 2021/04/06 Ver1.1 MOD Start
--            ,xcl.accounting_base          AS accounting_base    -- �v�㋒�_
            ,xcl.accounting_customer_code AS accounting_customer_code    -- �v��ڋq
            ,xca.sale_base_code           AS sale_base_code     -- ���㋒�_
-- 2021/04/06 Ver1.1 MOD Start
            ,xcl.deduction_amount         AS deduction_amount   -- �T���z(�{��)
            ,xcl.deduction_tax_amount     AS deduction_tax      -- �T���Ŋz
      FROM
             xxcok_condition_header       xch                   -- �T�������e�[�u��
            ,xxcok_condition_lines        xcl                   -- �T���ڍ׃e�[�u��
            ,fnd_lookup_values            flv                   -- �Q�ƕ\
-- 2021/04/06 Ver1.1 ADD Start
            ,xxcmm_cust_accounts          xca                   -- �ڋq�ǉ����
-- 2021/04/06 Ver1.1 ADD End
      WHERE 1 = 1
      AND xch.enabled_flag_h              = cv_y_flag                     -- �L���t���O
      AND gd_accounting_date              BETWEEN xch.start_date_active   -- �J�n��
                                          AND xch.end_date_active         -- �I����
      AND flv.lookup_type                 = 'XXCOK1_DEDUCTION_DATA_TYPE'  -- �T���f�[�^���
      AND flv.lookup_code                 =  xch.data_type                -- �f�[�^���
      AND flv.language                    = 'JA'                          -- ����FJA
      AND flv.enabled_flag                = cv_y_flag                     -- �Q�ƕ\:�L���t���O
      AND flv.attribute2                  = cv_fix_dedcton_type           -- �T���^�C�v
      AND xcl.condition_id                = xch.condition_id              -- �T������ID
      AND xcl.enabled_flag_l              = cv_y_flag                     -- �T���ڍ�:�L���t���O
-- 2021/04/06 Ver1.1 ADD Start
      AND xcl.accounting_customer_code    = xca.customer_code(+)          -- �T���ڍ�:�v��ڋq
-- 2021/04/06 Ver1.1 ADD End
      ;
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- �J�[�\���I�[�v��
    OPEN  fixed_deduction_cur;
    -- �f�[�^�擾
    FETCH fixed_deduction_cur BULK COLLECT INTO gt_dedctn_cond_tbl;
    -- �J�[�\���N���[�Y
    CLOSE fixed_deduction_cur;
--
    -- �擾�f�[�^���O���̏ꍇ
    IF ( gt_dedctn_cond_tbl.COUNT = 0 ) THEN
      -- �x���X�e�[�^�X�̊i�[
      ov_retcode := cv_status_warn;
      -- �ΏۂȂ����b�Z�[�W�̏o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_short_nm
                   ,iv_name         => cv_data_get_msg
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    -- �Ώی�����ݒ�
    gn_target_cnt := gt_dedctn_cond_tbl.COUNT;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( fixed_deduction_cur%ISOPEN ) THEN
        CLOSE fixed_deduction_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( fixed_deduction_cur%ISOPEN ) THEN
        CLOSE fixed_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( fixed_deduction_cur%ISOPEN ) THEN
        CLOSE fixed_deduction_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END  #####################################
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_sales_deducation
   * Description      : A-3.�̔��T���f�[�^�o�^
   ***********************************************************************************/
  PROCEDURE insert_sales_deducation( 
                      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
                     ,ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
                     ,ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sales_deducation'; -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#############################  �Œ胍�[�J���ϐ��錾�� END  #############################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
  lv_column_name                      VARCHAR2(20);                                -- �}�X�^�s���J������
    -- *** ���[�J����O ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode  := cv_status_normal;
--
    gn_normal_cnt := 0;
--
    gn_warn_cnt := 0;
--#############################  �Œ�X�e�[�^�X�������� END  #############################
--
    -- �̔��T���f�[�^�o�^���[�v
    <<insert_loop>>
    FOR ln_ins_sls_dedctn IN 1..gt_dedctn_cond_tbl.COUNT LOOP
      -- �X�e�[�^�X��������
      lv_retcode  := cv_status_normal;
      -- �擾�f�[�^�̕s��(NULL)�`�F�b�N
      IF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).customer_code IS NULL
        AND gt_dedctn_cond_tbl(ln_ins_sls_dedctn).chain_code IS NULL
        AND gt_dedctn_cond_tbl(ln_ins_sls_dedctn).corp_code IS NULL )
      -- �ڋq�A�`�F�[���A��Ƃ��ׂ�NULL�̏ꍇ
      THEN
        lv_column_name := cv_cus_chain_corp;
        lv_retcode := cv_status_warn;
-- 2021/04/06 Ver1.1 MOD Start
      ---- ���_�R�[�h��NULL�ł������ꍇ
      -- �v��ڋq�R�[�h��NULL�ł������ꍇ
--      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_base IS NULL ) THEN
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_customer_code IS NULL ) THEN
--        lv_column_name := cv_base_cd;
        lv_column_name := cv_accounting_customer;
-- 2021/04/06 Ver1.1 MOD End
        lv_retcode := cv_status_warn;
      -- �T���z��NULL�ł������ꍇ
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_amount IS NULL ) THEN
        lv_column_name := cv_deduction_amount;
        lv_retcode := cv_status_warn;
      -- �ŃR�[�h��NULL�ł������ꍇ
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).tax_code IS NULL ) THEN
        lv_column_name := cv_tax_cd;
        lv_retcode := cv_status_warn;
      -- �T���Ŋz��NULL�ł������ꍇ
      ELSIF ( gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_tax IS NULL ) THEN
        lv_column_name := cv_tax_credit;
        lv_retcode := cv_status_warn;
      END IF;
--
      -- �}�X�^�̕s���̗L���𔻒f
      IF ( lv_retcode = cv_status_warn) THEN
        -- �s��������΃}�X�^�s���G���[���b�Z�[�W�̏o��
        gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_short_nm
                     ,iv_name         => cv_master_err_msg
                     ,iv_token_name1  => cv_tkn_condition_no
                     ,iv_token_value1 => gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_no
                     ,iv_token_name2  => cv_tkn_column_name
                     ,iv_token_value2 => lv_column_name
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg                --���[�U�[�E�G���[���b�Z�[�W
        );
        -- �X�L�b�v�����̃C���N�������g
        gn_warn_cnt := gn_warn_cnt + 1;
        -- �x���X�e�[�^�X��߂�
        ov_retcode := lv_retcode;
      -- �}�X�^�ɕs�����Ȃ��ꍇ
      ELSE
        -- �̔��T���f�[�^��o�^����
        INSERT INTO xxcok_sales_deduction(
             sales_deduction_id                                       -- �̔��T��ID
            ,base_code_from                                           -- �U�֌����_
            ,base_code_to                                             -- �U�֐拒�_
            ,customer_code_from                                       -- �U�֌��ڋq�R�[�h
            ,customer_code_to                                         -- �U�֐�ڋq�R�[�h
            ,deduction_chain_code                                     -- �T���p�`�F�[���R�[�h
            ,corp_code                                                -- ��ƃR�[�h
            ,record_date                                              -- �v���
            ,source_category                                          -- �쐬���敪
            ,source_line_id                                           -- �쐬������ID
            ,condition_id                                             -- �T������ID
            ,condition_no                                             -- �T���ԍ�
            ,condition_line_id                                        -- �T���ڍ�ID
            ,data_type                                                -- �f�[�^���
            ,status                                                   -- �X�e�[�^�X
            ,item_code                                                -- �i�ڃR�[�h
            ,sales_uom_code                                           -- �̔��P��
            ,sales_unit_price                                         -- �̔��P��
            ,sales_quantity                                           -- �̔�����
            ,sale_pure_amount                                         -- ����{�̋��z
            ,sale_tax_amount                                          -- �������Ŋz
            ,deduction_uom_code                                       -- �T���P��
            ,deduction_unit_price                                     -- �T���P��
            ,deduction_quantity                                       -- �T������
            ,deduction_amount                                         -- �T���z
            ,tax_code                                                 -- �ŃR�[�h
            ,tax_rate                                                 -- �ŗ�
            ,recon_tax_code                                           -- �������ŃR�[�h
            ,recon_tax_rate                                           -- �������ŗ�
            ,deduction_tax_amount                                     -- �T���Ŋz
            ,remarks                                                  -- ���l
            ,application_no                                           -- �\����No.
            ,gl_if_flag                                               -- GL�A�g�t���O
            ,gl_base_code                                             -- GL�v�㋒�_
            ,gl_date                                                  -- GL�L����
            ,recovery_date                                            -- ���J�o���[���t
            ,cancel_flag                                              -- ����t���O
            ,cancel_gl_date                                           -- ���GL�L����
            ,cancel_user                                              -- ������{���[�U
            ,recon_base_code                                          -- �������v�㋒�_
            ,recon_slip_num                                           -- �x���`�[�ԍ�
            ,carry_payment_slip_num                                   -- �J�z���x���`�[�ԍ�
            ,report_decision_flag                                     -- ����m��t���O
            ,gl_interface_id                                          -- GL�A�gID
            ,cancel_gl_interface_id                                   -- ���GL�A�gID
            ,created_by                                               -- �쐬��
            ,creation_date                                            -- �쐬��
            ,last_updated_by                                          -- �ŏI�X�V��
            ,last_update_date                                         -- �ŏI�X�V��
            ,last_update_login                                        -- �ŏI�X�V���O�C��
            ,request_id                                               -- �v��ID
            ,program_application_id                                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                                               -- �R���J�����g�E�v���O����ID
            ,program_update_date                                      -- �v���O�����X�V��
          )VALUES(
             xxcok_sales_deduction_s01.nextval                        -- �̔��T��ID
-- 2021/04/06 Ver1.1 MOD Start
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_base    -- �U�֌����_
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).sale_base_code     -- �U�֌����_
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_base    -- �U�֐拒�_
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).sale_base_code     -- �U�֐拒�_
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).customer_code      -- �U�֌��ڋq�R�[�h
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_customer_code      -- �U�֌��ڋq�R�[�h
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).customer_code      -- �U�֐�ڋq�R�[�h
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).accounting_customer_code      -- �U�֐�ڋq�R�[�h
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).chain_code         -- �T���p�`�F�[���R�[�h
            ,NULL                                                       -- �T���p�`�F�[���R�[�h
--            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).corp_code          -- ��ƃR�[�h
            ,NULL                                                       -- ��ƃR�[�h
-- 2021/04/06 Ver1.1 MOD End
            ,gd_accounting_date                                       -- �v���
            ,cv_created_sec                                           -- �쐬���敪
            ,NULL                                                     -- �쐬������ID
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_id       -- �T������ID
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_no       -- �T���ԍ�
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).condition_line_id  -- �T���ڍ�ID
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).data_type          -- �f�[�^���
            ,cv_status                                                -- �X�e�[�^�X
            ,NULL                                                     -- �i�ڃR�[�h
            ,NULL                                                     -- �̔��P��
            ,NULL                                                     -- �̔��P��
            ,NULL                                                     -- �̔�����
            ,NULL                                                     -- ����{�̋��z
            ,NULL                                                     -- �������Ŋz
            ,NULL                                                     -- �T���P��
            ,NULL                                                     -- �T���P��
            ,NULL                                                     -- �T������
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_amount   -- �T���z
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).tax_code           -- �ŃR�[�h
            ,NULL                                                     -- �ŗ�
            ,NULL                                                     -- �������ŃR�[�h
            ,NULL                                                     -- �������ŗ�
            ,gt_dedctn_cond_tbl(ln_ins_sls_dedctn).deduction_tax      -- �T���Ŋz
            ,NULL                                                     -- ���l
            ,NULL                                                     -- �\����No.
            ,cv_gl_rel_flag                                           -- GL�A�g�t���O
            ,NULL                                                     -- GL�v�㋒�_
            ,NULL                                                     -- GL�L����
            ,NULL                                                     -- ���J�o���[���t
            ,cv_cancel_flag                                           -- ����t���O
            ,NULL                                                     -- ���GL�L����
            ,NULL                                                     -- ������{���[�U
            ,NULL                                                     -- �������v�㋒�_
            ,NULL                                                     -- �x���`�[�ԍ�
            ,NULL                                                     -- �J�z���x���`�[�ԍ�
            ,NULL                                                     -- ����m��t���O
            ,NULL                                                     -- GL�A�gID
            ,NULL                                                     -- ���GL�A�gID
            ,cn_created_by                                            -- �쐬��
            ,cd_creation_date                                         -- �쐬��
            ,cn_last_updated_by                                       -- �ŏI�X�V��
            ,cd_last_update_date                                      -- �ŏI�X�V��
            ,cn_last_update_login                                     -- �ŏI�X�V���O�C��
            ,cn_request_id                                            -- �v��ID
            ,cn_program_application_id                                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,cn_program_id                                            -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date                                   -- �v���O�����X�V��
        );
        -- ���팏�����C���N�������g
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      END IF;
    --
    END LOOP insert_loop;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#################################  �Œ��O������ END  #################################
--
  END insert_sales_deducation;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf  VARCHAR2(5000);                                        -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                                           -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--############################  �Œ�X�e�[�^�X�������� START  ############################
--
    ov_retcode := cv_status_normal;
--
--#####################################  �Œ蕔 END  #####################################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt        := 0;    -- �Ώی���
    gn_normal_cnt        := 0;    -- ���팏��
    gn_error_cnt         := 0;    -- �G���[����
    gn_warn_cnt          := 0;    -- �X�L�b�v����
    gd_accounting_date   := NULL; -- �T���f�[�^�v���
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init( ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.��z�T���������o
    -- ===============================
    get_data(
        ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
       ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
       ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �X�e�[�^�X������i�f�[�^��1���ȏ㒊�o�j�ł����A-3�����s����
    IF ( lv_retcode = cv_status_normal ) THEN
      -- ===============================
      -- A-3.�̔��T���f�[�^�o�^
      -- ===============================
      insert_sales_deducation(
          ov_errbuf  => lv_errbuf            -- �G���[�E���b�Z�[�W           -- # �Œ� #
         ,ov_retcode => lv_retcode           -- ���^�[���E�R�[�h             -- # �Œ� #
         ,ov_errmsg  => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
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
--#####################################  �Œ蕔 END  #####################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : ��z�T���f�[�^�쐬�v���V�[�W��(A-4.�I���������܂�)
   **********************************************************************************/
--
--
  PROCEDURE main( errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
                 ,retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCOK';             -- �A�h�I���F�ʊJ���̈�
--
--############################  �Œ胍�[�J���ϐ��錾�� START  ############################
--
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
--
--#####################################  �Œ蕔 END  #####################################
--
  BEGIN
--
--####################################  �Œ蕔 START  ####################################--
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
--
--#####################################  �Œ蕔 END  #####################################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain( ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
            ,ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
    -- ===============================
    -- A-4.�I������
    -- ===============================
--
    -- �G���[�������̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_warn_cnt     := 0;
      gn_error_cnt    := 1;
    END IF;
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_target_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_target_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_success_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_skip_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_warn_cnt )
                                           );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application  => cv_xxccp_appl_name
                                           ,iv_name         => cv_error_rec_msg
                                           ,iv_token_name1  => cv_cnt_token
                                           ,iv_token_value1 => TO_CHAR ( gn_error_cnt )
                                           );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg( iv_application => cv_xxccp_appl_name
                                           ,iv_name        => lv_message_code
                                           );
--
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
       ,buff  => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
--################################  �Œ��O������ START  ################################
--
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
--
--#####################################  �Œ蕔 END  #####################################
--
  END main;
--
END XXCOK024A23C;
/
