CREATE OR REPLACE PACKAGE BODY APPS.XXCOK024A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A41C (body)
 * Description      : �x�����A�g�T���f�[�^�o��
 * MD.050           : �x�����A�g�T���f�[�^�o�� MD050_COK_024_A41
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_order_list_cond    �x�����A�g�T���f�[�^���o(A-2)
 *  output_data            �f�[�^�o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/09/07    1.0   M.Akachi         �V�K�쐬
 *  2024/08/23    1.1   SCSK Y.Koh       E_�{�ғ�_20159�y���v�F���z�x�����A�g�T���o�͋@�\�̃p�t�H�[�}���X����
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000)  DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)   DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)    DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)    DEFAULT NULL;
  gn_target_cnt             NUMBER          DEFAULT NULL;    -- �Ώی���
  gn_normal_cnt             NUMBER          DEFAULT NULL;    -- ���팏��
  gn_error_cnt              NUMBER          DEFAULT NULL;    -- �G���[����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐��x����O ***
  global_api_warn_expt      EXCEPTION;
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
  --*** �o�͓� ���t�t�]�`�F�b�N��O ***
  global_date_rever_old_chk_expt    EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_delimit                  CONSTANT  VARCHAR2(4)   := ',';                    -- ��؂蕶��
  cv_null                     CONSTANT  VARCHAR2(4)   := '';                     -- �󕶎�
  cv_half_space               CONSTANT  VARCHAR2(4)   := ' ';                    -- �X�y�[�X
  cv_full_space               CONSTANT  VARCHAR2(4)   := '�@';                   -- �S�p�X�y�[�X
  cv_const_y                  CONSTANT  VARCHAR2(1)   := 'Y';                    -- 'Y'
  cv_const_n                  CONSTANT  VARCHAR2(1)   := 'N';                    -- 'N'
  cv_perc                     CONSTANT  VARCHAR2(1)   := '%';                    -- '%'
  cv_lang                     CONSTANT  VARCHAR2(100) := USERENV( 'LANG' );      -- ����
  -- ���l
  cn_zero                     CONSTANT  NUMBER        := 0;                      -- 0
  cn_one                      CONSTANT  NUMBER        := 1;                      -- 1
  --
  cv_pkg_name                 CONSTANT  VARCHAR2(100) := 'XXCOK024A41C';         -- �p�b�P�[�W��
  cv_xxcok_short_name         CONSTANT  VARCHAR2(100) := 'XXCOK';                -- �̕��̈�Z�k�A�v����
  -- �����}�X�N
  cv_date_format              CONSTANT  VARCHAR2(10)  := 'YYYY/MM/DD';              -- ���t����
  cv_date_format_time         CONSTANT  VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';   -- ���t����(����)
  -- �Q�ƃ^�C�v
  cv_type_department          CONSTANT  VARCHAR2(30)  := 'XX03_DEPARTMENT';               -- ���_�R�[�h
  cv_type_business_type       CONSTANT  VARCHAR2(30)  := 'XX03_BUSINESS_TYPE';            -- ��ƃR�[�h
  cv_type_chain_code          CONSTANT  VARCHAR2(30)  := 'XXCMM_CHAIN_CODE';              -- �T���p�`�F�[���R�[�h
  cv_type_header              CONSTANT  VARCHAR2(30)  := 'XXCOK1_NOTLINK_DEDUCTION_HEAD'; -- �x�����A�g�T���f�[�^�o�͗p���o��
  cv_type_dec_pri_base        CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEC_PRIVILEGE_BASE';     -- �T���}�X�^�������_
  cv_type_deduction_data      CONSTANT  VARCHAR2(30)  := 'XXCOK1_DEDUCTION_DATA_TYPE';    -- �T���f�[�^���
  --���b�Z�[�W
  cv_msg_date_rever_err       CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10651';     -- ���t�t�]�G���[
  cv_msg_parameter            CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10848';     -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_base_params_err      CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10849';     -- �p�����[�^�����ݒ�G���[�i�{���S�����_�A���㋒�_�j
  cv_msg_proc_date_err        CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00028';     -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_user_id_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-10594';     -- ���[�U�[ID�擾�G���[���b�Z�[�W
  cv_msg_user_base_code_err   CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00012';     -- �������_�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_no_data_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00001';     -- �Ώۃf�[�^�Ȃ��G���[���b�Z�[�W
  cv_msg_profile_err          CONSTANT  VARCHAR2(100) := 'APP-XXCOK1-00003';     -- �v���t�@�C���擾�G���[���b�Z�[�W
  --�g�[�N����
  cv_tkn_nm_date_type         CONSTANT  VARCHAR2(100) := 'DATE_TYPE';            -- �f�[�^���
  cv_tkn_nm_rec_date_from     CONSTANT  VARCHAR2(100) := 'RECORD_DATE_FROM';     -- �v����iFROM�j
  cv_tkn_nm_rec_date_to       CONSTANT  VARCHAR2(100) := 'RECORD_DATE_TO';       -- �v����iTO�j
  cv_tkn_nm_base_code         CONSTANT  VARCHAR2(100) := 'BASE_CODE';            -- �{���S�����_
  cv_tkn_nm_sale_base_code    CONSTANT  VARCHAR2(100) := 'SALE_BASE_CODE';       -- ���㋒�_
  cv_tkn_nm_user_id           CONSTANT  VARCHAR2(100) := 'USER_ID';              -- ���[�U�[ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date              DATE           DEFAULT NULL;                     -- �Ɩ����t
  gn_user_id                NUMBER         DEFAULT NULL;                     -- ���[�U�[ID
  gv_user_base_code         VARCHAR2(150)  DEFAULT NULL;                     -- �������_�R�[�h
  gn_privilege_base         NUMBER         DEFAULT NULL;                     -- �o�^�E�X�V�����i0�F�����Ȃ��A1�F��������j
  gv_privilege_flag         VARCHAR2(1)    DEFAULT NULL;                     -- �������[�U�[���f�t���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  CURSOR get_deduction_list_data_cur (
           iv_data_type                  VARCHAR2              -- �f�[�^���
          ,iv_record_date_from           VARCHAR2              -- �v���(FROM)
          ,iv_record_date_to             VARCHAR2              -- �v���(TO)
          ,iv_base_code                  VARCHAR2              -- �{���S�����_
          ,iv_sale_base_code             VARCHAR2              -- ���㋒�_
          )
  IS
-- 2024/08/23 Ver1.1 MOD Start
    SELECT  /*+ LEADING ( xch xsd ) */
            xsd.base_code_to          AS  base_code_to        , -- ���_�R�[�h
--    SELECT  xsd.base_code_to          AS  base_code_to        , -- ���_�R�[�h
-- 2024/08/23 Ver1.1 MOD End
            ffvt.description          AS  base_code_name      , -- ���_��
            papf.employee_number      AS  employee_number     , -- �w�b�_�ŏI�X�V�ҏ]�ƈ��ԍ�
            papf.per_information18    AS  employee_first_name , -- �w�b�_�ŏI�X�V�Ґ�
            papf.per_information19    AS  employee_last_name  , -- �w�b�_�ŏI�X�V�Җ�
            xch.corp_code             AS  corp_code           , -- ��ƃR�[�h
            ffvv.attribute2           AS  base_code_corp      , -- �{���S�����_�i��Ɓj
            xch.deduction_chain_code  AS  deduction_chain_code, -- �T���p�`�F�[���R�[�h
            flv.attribute3            AS  base_code_chain     , -- �{���S�����_�i�`�F�[���j
            xch.customer_code         AS  customer_code       , -- �ڋq�R�[�h
            xca.sale_base_code        AS  sale_base_code      , -- ���㋒�_
            xch.data_type             AS  data_type           , -- �f�[�^���
            xch.condition_no          AS  condition_no        , -- �T���ԍ�
            xch.content               AS  content             , -- ���e
            xch.decision_no           AS  decision_no         , -- ����No.
            xch.start_date_active     AS  start_date_active   , -- �J�n��
            xch.end_date_active       AS  end_date_active     , -- �I����
            xch.last_update_date      AS  last_update_date    , -- �ŏI�X�V��
            sum(xsd.sale_pure_amount) AS  sale_pure_amount    , -- ����{�̋��z
            sum(xsd.deduction_amount) AS  deduction_amount      -- �T���z
    FROM    xxcok_condition_header    xch,                      -- �T������
            xxcok_sales_deduction     xsd ,                     -- �̔��T�����
            fnd_flex_values_tl        ffvt,                     -- �l���{��(���_)
            fnd_flex_values           ffv ,                     -- �l(���_)
            fnd_flex_value_sets       ffvs,                     -- �l�Z�b�g(���_)
            per_all_people_f          papf,                     -- �]�ƈ��}�X�^
            fnd_user                  fu  ,                     -- ���[�U�[�}�X�^
            fnd_flex_values_vl        ffvv,                     -- ���
            fnd_lookup_values         flv,                      -- �`�F�[���R�[�h
            xxcmm_cust_accounts       xca,                      -- �ڋq
            xxcmm_cust_accounts       xca2                      -- �ڋq
    WHERE   xsd.recon_slip_num          IS      NULL
    AND     xsd.data_type               IN      ( SELECT REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) FROM DUAL
                                                  CONNECT BY REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) IS NOT NULL )    -- �f�[�^���
    AND     xsd.record_date             BETWEEN to_date(iv_record_date_from,cv_date_format)
                                        AND     to_date(iv_record_date_to,cv_date_format)
    AND     xsd.status                  =       cv_const_n
    AND     xch.condition_no            =       xsd.condition_no
    AND     ffvs.flex_value_set_name    =       cv_type_department
    AND     ffv.flex_value_set_id       =       ffvs.flex_value_set_id
    AND     ffv.flex_value              =       xsd.base_code_to
    AND     ffvt.flex_value_id          =       ffv.flex_value_id
    AND     ffvt.language               =       cv_lang
    -- ���
    AND     ffvv.value_category(+)      =       cv_type_business_type
    AND     ffvv.flex_value(+)          =       xch.corp_code
    -- �`�F�[��
    AND     flv.lookup_type(+)          =       cv_type_chain_code
    AND     flv.lookup_code(+)          =       xch.deduction_chain_code
    AND     flv.language(+)             =       cv_lang
    -- �ڋq
    AND     xca.customer_code(+)        =       xch.customer_code
    -- �U�֐�ڋq
    AND     xsd.customer_code_to        =       xca2.customer_code           -- �̔��T�����.�U�֐�ڋq�R�[�h = �ڋq�}�X�^.�ڋq�R�[�h
    -- ���[�U
    AND     fu.user_id                  =       xch.created_by
    AND     papf.person_id              =       fu.employee_id
    AND     papf.current_employee_flag  =       cv_const_y
    AND     papf.effective_start_date   =       ( SELECT MAX(papf2.effective_start_date) effective_start_date
                                                  FROM   per_all_people_f papf2
                                                  WHERE  papf2.current_employee_flag  = cv_const_y
                                                  AND    papf2.person_id              = papf.person_id )
    AND (
         -- <�{���S�����_�̒��o����>
         (( ffvv.attribute2 = iv_base_code OR flv.attribute3 = iv_base_code OR xca.sale_base_code = iv_base_code OR iv_base_code IS NULL )
          AND  ( gv_privilege_flag = cv_const_y OR ffvv.attribute2 = gv_user_base_code OR flv.attribute3 = gv_user_base_code OR xca.sale_base_code = gv_user_base_code )
          AND  ( iv_sale_base_code IS NULL )
         )
         OR 
         -- <���㋒�_�̒��o����>  
         (( xca2.sale_base_code = iv_sale_base_code OR iv_sale_base_code IS NULL )
          AND  ( gv_privilege_flag =  cv_const_y OR xca2.sale_base_code = gv_user_base_code )
          AND  ( iv_base_code IS NULL )
         )
        )
-- 2024/08/23 Ver1.1 ADD Start
    AND     xch.data_type               IN      ( SELECT REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) FROM DUAL
                                                  CONNECT BY REGEXP_SUBSTR(iv_data_type, '[^,]+', 1, LEVEL) IS NOT NULL )    -- �f�[�^���
    AND     xch.START_DATE_ACTIVE       <=      to_date(iv_record_date_to,cv_date_format)
    AND     xch.END_DATE_ACTIVE         >=      to_date(iv_record_date_from,cv_date_format)
-- 2024/08/23 Ver1.1 ADD End
    GROUP BY
            ffv.attribute9            , -- ���_�{���R�[�h
            xsd.base_code_to          , -- ���_�R�[�h
            ffvt.description          , -- ���_��
            papf.employee_number      , -- �w�b�_�ŏI�X�V�ҏ]�ƈ��ԍ�
            papf.per_information18    , -- �w�b�_�ŏI�X�V�Ґ�
            papf.per_information19    , -- �w�b�_�ŏI�X�V�Җ�
            xch.corp_code             , -- ��ƃR�[�h
            ffvv.attribute2           , -- �{���S�����_�i��Ɓj
            xch.deduction_chain_code  , -- �T���p�`�F�[���R�[�h
            flv.attribute3            , -- �{���S�����_�i�`�F�[���j
            xch.customer_code         , -- �ڋq�R�[�h
            xca.sale_base_code        , -- ���㋒�_
            xch.data_type             , -- �f�[�^���
            xch.condition_no          , -- �T���ԍ�
            xch.content               , -- ���e
            xch.decision_no           , -- ����No.
            xch.start_date_active     , -- �J�n��
            xch.end_date_active       , -- �I����
            xch.last_update_date        -- �ŏI�X�V��
    ORDER BY
            ffv.attribute9            , -- ���_�R�[�h
            xch.corp_code             , -- ��ƃR�[�h
            xch.deduction_chain_code  , -- �T���p�`�F�[���R�[�h
            xch.customer_code         , -- �ڋq�R�[�h
            xch.condition_no            -- �T���ԍ�
    ;
--
  -- �擾�f�[�^�i�[�ϐ���` (�S�o��)
  TYPE g_out_file_ttype IS TABLE OF get_deduction_list_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_data_type                    IN     VARCHAR2     -- �f�[�^���
   ,iv_record_date_from             IN     VARCHAR2     -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2     -- �v���(TO)
   ,iv_base_code                    IN     VARCHAR2     -- �{���S�����_
   ,iv_sale_base_code               IN     VARCHAR2     -- ���㋒�_
   ,ov_errbuf                       OUT    VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_para_msg                     VARCHAR2(5000)  DEFAULT NULL;     -- �p�����[�^�o�̓��b�Z�[�W
    lv_para_msg2                    VARCHAR2(5000)  DEFAULT NULL;     -- �p�����[�^�o�̓��b�Z�[�W
    ln_option_param_count           NUMBER := cn_zero;        -- �C�Ӄp�����[�^�ݒ萔
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode        := cv_status_normal;
    gv_privilege_flag := NULL;
    gn_privilege_base := cn_zero;
--
--###########################  �Œ蕔 END   ############################
--
    --========================================
    -- 1.�p�����[�^�o�͏���
    --========================================
    lv_para_msg   :=  xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name           -- �A�v���Z�k��
                                               ,iv_name               =>  cv_msg_parameter              -- �p�����[�^�o�̓��b�Z�[�W
                                               ,iv_token_name1        =>  cv_tkn_nm_date_type           -- �g�[�N���F�f�[�^���
                                               ,iv_token_value1       =>  iv_data_type                  -- �f�[�^���
                                               ,iv_token_name2        =>  cv_tkn_nm_rec_date_from       -- �g�[�N���F�v����iFROM�j
                                               ,iv_token_value2       =>  iv_record_date_from           -- �v����iFROM�j
                                               ,iv_token_name3        =>  cv_tkn_nm_rec_date_to         -- �g�[�N���F�v����iTO�j
                                               ,iv_token_value3       =>  iv_record_date_to             -- �v����iTO�j
                                               ,iv_token_name4        =>  cv_tkn_nm_base_code           -- �g�[�N���F�{���S�����_
                                               ,iv_token_value4       =>  iv_base_code                  -- �{���S�����_
                                               ,iv_token_name5        =>  cv_tkn_nm_sale_base_code      -- �g�[�N���F���㋒�_
                                               ,iv_token_value5       =>  iv_sale_base_code             -- ���㋒�_
                                               );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.���̓p�����[�^�`�F�b�N
    --========================================
    -- �v���(FROM)���v���(TO)��薢�����̏ꍇ�G���[
    IF ( iv_record_date_from > iv_record_date_to ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_date_rever_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �{���S�����_�A���㋒�_�̗��������͂���Ă���ꍇ�G���[
    IF ( iv_base_code IS NOT NULL AND iv_sale_base_code IS NOT NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_base_params_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.�Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.���[�U�[ID�擾����
    --========================================
    gn_user_id := fnd_global.user_id;
    IF ( gn_user_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_id_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 5.�������_�R�[�h�擾����
    --========================================
    gv_user_base_code := xxcok_common_pkg.get_base_code_f(
      id_proc_date            =>  gd_proc_date,
      in_user_id              =>  gn_user_id
      );
    IF ( gv_user_base_code IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcok_short_name,
        iv_name               =>  cv_msg_user_base_code_err,
        iv_token_name1        =>  cv_tkn_nm_user_id,
        iv_token_value1       =>  gn_user_id
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 6.�������[�U�[�m�F����
    --========================================
    -- 6-1 �������_�̏������[�U�[���m�F
    BEGIN
      SELECT  COUNT(1)            AS privilege_base_cnt
      INTO    gn_privilege_base
      FROM    fnd_lookup_values flv
      WHERE   flv.lookup_type      = cv_type_dec_pri_base
      AND     flv.lookup_code      = gv_user_base_code
      AND     flv.enabled_flag     = cv_const_y
      AND     flv.language         = cv_lang
      AND     gd_proc_date BETWEEN flv.start_date_active 
                               AND NVL(flv.end_date_active,gd_proc_date)
      ;
    END;
--
    -- 6-1 �������_���[�U�[�̔���
    IF (gn_privilege_base >= cn_one) THEN
      gv_privilege_flag  := cv_const_y;
    END IF;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_order_list_cond
   * Description      : �x�����A�g�T���f�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE get_order_list_cond(
    iv_data_type                    IN     VARCHAR2     -- �f�[�^���
   ,iv_record_date_from             IN     VARCHAR2     -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2     -- �v���(TO)
   ,iv_base_code                    IN     VARCHAR2     -- �{���S�����_
   ,iv_sale_base_code               IN     VARCHAR2     -- ���㋒�_
   ,ov_errbuf                       OUT    VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                      OUT    VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                       OUT    VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_list_cond'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
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
    ov_retcode    := cv_status_normal;
    gn_target_cnt := cn_zero;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ώۃf�[�^�擾
    OPEN get_deduction_list_data_cur (
           iv_data_type                  -- �f�[�^���
          ,iv_record_date_from           -- �v���(FROM)
          ,iv_record_date_to             -- �v���(TO)
          ,iv_base_code                  -- �{���S�����_
          ,iv_sale_base_code             -- ���㋒�_
          );
    FETCH get_deduction_list_data_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE get_deduction_list_data_cur;
    -- ���������J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
    -- ���o�f�[�^��0���������ꍇ�x��
    IF  gn_target_cnt = cn_zero THEN
      RAISE global_api_warn_expt;
    END IF;
--
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF get_deduction_list_data_cur%ISOPEN THEN
        CLOSE get_deduction_list_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_list_cond;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf     VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg     VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_code_eoh_024a41    CONSTANT  VARCHAR2(100) := '024A41%';                 -- �N�C�b�N�R�[�h�i�T���}�X�^�o�͗p���o���j
--
    -- *** ���[�J���ϐ� ***
    lv_line_data              VARCHAR2(5000)  DEFAULT NULL;                     -- OUTPUT�f�[�^�ҏW�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR header_cur
    IS
      SELECT  flv.description  head                                             -- �E�v�F�o�͗p���o��
      FROM    fnd_lookup_values flv
      WHERE   flv.language        = cv_lang                                     -- ����
      AND     flv.lookup_type     = cv_type_header                              -- �x�����A�g�T���f�[�^�o�͗p���o��
      AND     flv.lookup_code  LIKE cv_code_eoh_024a41                          -- �N�C�b�N�R�[�h�i�x�����A�g�T���f�[�^�o�͗p���o���j
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_proc_date )  -- �L���J�n��
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_proc_date )  -- �L���I����
      AND     flv.enabled_flag    = cv_const_y                                  -- �g�p�\
      ORDER BY
              TO_NUMBER(flv.attribute1)
      ;
    --���o��
    TYPE l_header_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_header_tab l_header_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------------------
    -- ���o���̏o��
    ------------------------------------------
    -- �f�[�^�̌��o�����擾
    OPEN  header_cur;
    FETCH header_cur BULK COLLECT INTO lt_header_tab;
    CLOSE header_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_header_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_header_tab(i);
      ELSE
        lv_line_data := lv_line_data || cv_delimit || lt_header_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
    ------------------------------------------
    -- �f�[�^�o��
    ------------------------------------------
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
--
      --�f�[�^��ҏW
      lv_line_data :=     gt_out_file_tab(i).base_code_to          -- ���_�R�[�h
         || cv_delimit || gt_out_file_tab(i).base_code_name        -- ���_��
         || cv_delimit || gt_out_file_tab(i).employee_number       -- �Ј��R�[�h
         || cv_delimit || gt_out_file_tab(i).employee_first_name || cv_half_space || gt_out_file_tab(i).employee_last_name  -- �쐬�Җ�
         || cv_delimit || gt_out_file_tab(i).corp_code             -- ��ƃR�[�h 
         || cv_delimit || gt_out_file_tab(i).base_code_corp        -- �{���S�����_�i��Ɓj
         || cv_delimit || gt_out_file_tab(i).deduction_chain_code  -- �T���p�`�F�[���R�[�h
         || cv_delimit || gt_out_file_tab(i).base_code_chain       -- �{���S�����_�i�`�F�[���j
         || cv_delimit || gt_out_file_tab(i).customer_code         -- �ڋq�R�[�h
         || cv_delimit || gt_out_file_tab(i).sale_base_code        -- ���㋒�_
         || cv_delimit || gt_out_file_tab(i).data_type             -- �f�[�^���
         || cv_delimit || gt_out_file_tab(i).condition_no          -- �T���ԍ�
         || cv_delimit || gt_out_file_tab(i).content               -- ���e
         || cv_delimit || gt_out_file_tab(i).decision_no           -- ����No.
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).start_date_active,cv_date_format)  -- �J�n��(YYYY/MM/DD)
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).end_date_active,cv_date_format)    -- �I����(YYYY/MM/DD)
         || cv_delimit || TO_CHAR(gt_out_file_tab(i).last_update_date,cv_date_format_time)   -- �ŏI�X�V��(YYYY/MM/DD HH24:MI:SS)
         || cv_delimit || gt_out_file_tab(i).sale_pure_amount      -- ����{�̋��z
         || cv_delimit || gt_out_file_tab(i).deduction_amount      -- �T���z
      ;
      -- �f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
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
      IF header_cur%ISOPEN THEN
        CLOSE header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain( iv_data_type                    IN     VARCHAR2  -- �f�[�^���
                    ,iv_record_date_from             IN     VARCHAR2  -- �v���(FROM)
                    ,iv_record_date_to               IN     VARCHAR2  -- �v���(TO)
                    ,iv_base_code                    IN     VARCHAR2  -- �{���S�����_
                    ,iv_sale_base_code               IN     VARCHAR2  -- ���㋒�_
                    ,ov_errbuf                       OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
                    ,ov_retcode                      OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
                    ,ov_errmsg                       OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf  VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init( iv_data_type                   -- �f�[�^���
         ,iv_record_date_from            -- �v���(FROM)
         ,iv_record_date_to              -- �v���(TO)
         ,iv_base_code                   -- �{���S�����_
         ,iv_sale_base_code              -- ���㋒�_
         ,lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
         );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �x�����A�g�T���f�[�^���o
    -- ===============================
    get_order_list_cond( iv_data_type                 -- �f�[�^���
                        ,iv_record_date_from          -- �v���(FROM)
                        ,iv_record_date_to            -- �v���(TO)
                        ,iv_base_code                 -- �{���S�����_
                        ,iv_sale_base_code            -- ���㋒�_
                        ,lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
                        ,lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
                        ,lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        );
--
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( iv_application        =>  cv_xxcok_short_name,
                                             iv_name               =>  cv_msg_no_data_err
                                            );
      RAISE global_api_warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSE
      NULL;
    END IF;
--
    -- ===============================
    -- A-3  �f�[�^�o��
    -- ===============================
    output_data(
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �x���n���h�� ***
    WHEN global_api_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_data_type                    IN     VARCHAR2          -- �f�[�^���
   ,iv_record_date_from             IN     VARCHAR2          -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- �v���(TO)
   ,iv_base_code                    IN     VARCHAR2          -- �{���S�����_
   ,iv_sale_base_code               IN     VARCHAR2          -- ���㋒�_
  )
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000)  DEFAULT NULL;  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1)     DEFAULT NULL;  -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000)  DEFAULT NULL;  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100)   DEFAULT NULL;  -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_data_type                    -- �f�[�^���
      ,iv_record_date_from             -- �v���(FROM)
      ,iv_record_date_to               -- �v���(TO)
      ,iv_base_code                    -- �{���S�����_
      ,iv_sale_base_code               -- ���㋒�_
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- A-4.�I������
    -- ===============================
--
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�G���[�̏ꍇ���������N���A�A�G���[�����Œ�
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_zero;
      gn_error_cnt  := cn_one;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
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
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOK024A41C;
/
