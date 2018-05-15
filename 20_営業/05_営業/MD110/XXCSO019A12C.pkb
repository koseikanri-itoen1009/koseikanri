CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A12C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO005A02C(body)
 * Description      : ���[�gNo�^�c�ƈ�CSV�o��
 * MD.050           : ���[�gNo�^�c�ƈ�CSV�o�� (MD050_CSO_019A12)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_route_emp_data     ���[�gNo�^�c�ƈ����擾(A-2)
 *  output_data            CSV�t�@�C���o��(A-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/03/08    1.0   K.Kiriu          �V�K�쐬(E_�{�ғ�_14722)
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
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
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
  init_err_expt                 EXCEPTION;      -- ����������O
  global_warn_expt              EXCEPTION;      -- �f�[�^�Ȃ���O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCSO019A12C';                 -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxcso       CONSTANT VARCHAR2(10)  := 'XXCSO';                        -- XXCSO
  -- ���t����
  cv_fmt_yyyymmdd          CONSTANT VARCHAR2(50)  := 'YYYY/MM/DD';
  -- ������؂�
  cv_comma                 CONSTANT VARCHAR2(1)   := ',';                            -- �J���}
  -- ���b�Z�[�W�R�[�h
  cv_msg_cso_00130         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00130';             -- ���_�R�[�h
  cv_msg_cso_00842         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00842';             -- �c�ƈ�
  cv_msg_cso_00843         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00843';             -- ���[�gNo
  cv_msg_cso_00011         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00011';             -- �Ɩ����t�擾�G���[
  cv_msg_cso_00649         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00649';             -- �f�[�^�ǉ��G���[
  cv_msg_cso_00224         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00224';             -- CSV�t�@�C���o��0���G���[
  cv_msg_cso_00844         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00844';             -- ���[�gNo�^�c�ƈ�CSV�w�b�_
  cv_msg_cso_00845         CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00845';             -- ���[�gNo�^�c�ƈ�CSV�o�͈ꎞ�\
  -- �g�[�N��
  cv_tkn_err_message       CONSTANT VARCHAR2(11)  := 'ERR_MESSAGE';                  -- SQL�G���[���b�Z�[�W
  cv_tkn_entry             CONSTANT VARCHAR2(5)   := 'ENTRY';                        -- ���͒l
  cv_tkn_count             CONSTANT VARCHAR2(5)   := 'COUNT';                        -- ����
  cv_tkn_table             CONSTANT VARCHAR2(5)   := 'TABLE';                        -- �e�[�u��
  -- �Q�ƃ^�C�v
  cv_route_mgr_cust_class  CONSTANT VARCHAR2(27)  := 'XXCSO1_ROUTE_MGR_CUST_CLASS';  -- ���[�gNo�Ǘ��Ώیڋq
  cv_customer_class        CONSTANT VARCHAR2(14)  := 'CUSTOMER CLASS';               -- �ڋq�敪
  -- �ڋq�敪�_�~�[
  cv_00                    CONSTANT VARCHAR2(2)   := '00';                           -- �ڋq�敪NULL�̏ꍇ�̃_�~�[
  -- yes no
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                            -- YES
  cv_no                    CONSTANT VARCHAR2(1)   := 'N';                            -- NO
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �p�����[�^�i�[�p
  gt_base_code            jtf_rs_groups_vl.attribute1%TYPE;       -- �p�����[�^�F���_�R�[�h
  gt_employee_number      per_people_f.employee_number%TYPE;      -- �p�����[�^�F�c�ƈ��R�[�h
  gt_route_no             hz_org_profiles_ext_b.c_ext_attr2%TYPE; -- �p�����[�^�F���[�gNo
  -- �������t�p
  gd_process_date         DATE;                                   -- �Ɩ����t
  gd_next_date            DATE;                                   -- �Ɩ����t����
  gd_next_month_last_date DATE;                                   -- �Ɩ����t�̗�������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  CURSOR route_emp_cur
  IS
    SELECT  sub.customer_class_name  customer_class_name  -- �ڋq�敪��
           ,sub.account_number       account_number       -- �ڋq�R�[�h
           ,sub.party_name           party_name           -- �ڋq��
           ,sub.trgt_resource        trgt_resource        -- ���S��
           ,sub.trgt_route_no        trgt_route_no        -- �����[�gNo
           ,sub.next_resource        next_resource        -- �V�S��
           ,sub.next_route_no        next_route_no        -- �V���[�gNo
    FROM    (
              -- ���S�� �����|���Ǘ���ڋq�ȊO
              SELECT  /*+
                        LEADING(xrcv1.fa xrcv1.efdfc xrrv1.rtn_ctx xrrv1.rsrc_ctx xtrr1)
                        INDEX(xrcv1.fa fnd_application_u3)
                        USE_NL(xrcv1.fa xrcv1.efdfce xrrv1.rtn_ctx xrrv1.rsrc_ctx xtrr1)
                      */
                      '1'                                sort_code
                     ,xcav1.customer_class_name          customer_class_name
                     ,xrrv1.account_number               account_number
                     ,xcav1.party_name                   party_name
                     ,xrrv1.trgt_resource                trgt_resource
                     ,xrrv1.trgt_route_no                trgt_route_no
                     ,xrrv1.next_resource                next_resource
                     ,xrrv1.next_route_no                next_route_no
              FROM    xxcso_tmp_rtn_rsrc      xtrr1  -- ���[�gNo�^�c�ƈ�CSV�o�͈ꎞ�\
                     ,xxcso_resource_custs_v2 xrcv1  -- �ڋq�S���c�ƈ��i�ŐV�j�r���[
                     ,xxcso_rtn_rsrc_v        xrrv1  -- �K��E����v��^���[�gNo�S���c�ƈ��ꊇ�X�V��ʗp�r���[
                     ,xxcso_cust_accounts_v   xcav1  -- �ڋq�}�X�^�r���[
                     ,fnd_lookup_values_vl    flvv1  -- �Q�ƃ^�C�v�u���[�gNo�Ǘ��Ώیڋq�v
              WHERE   xtrr1.employee_number  = xrcv1.employee_number
              AND     xrcv1.account_number   = xrrv1.account_number
              AND     xrrv1.account_number   = xcav1.account_number
              AND     (
                        xcav1.sale_base_code = xtrr1.base_code
                        OR
                        xcav1.sale_base_code IS NULL  -- ��ʂ��쐬����MC���EMC�̏ꍇ�̏���
                      )
              AND     flvv1.lookup_type      = cv_route_mgr_cust_class
              AND     gd_process_date        BETWEEN flvv1.start_date_active
                                             AND     NVL( flvv1.end_date_active, gd_process_date )
              AND     flvv1.attribute1       = cv_no  -- ���|���Ǘ���ȊO
              AND     NVL( xcav1.customer_class_code, cv_00 ) || '-' || xcav1.customer_status = flvv1.lookup_code
              AND     (
                        (
                          ( gt_route_no IS NOT NULL )
                          AND
                          ( EXISTS(
                              SELECT  /*+
                                        LEADING(xcrv1.hca)
                                        USE_NL(xcrv1.hca xcrv1.fa xcrv1.hp xcrv1.hop xcrv1.efdfce xcrv1.hopeb)
                                      */
                                      1
                               FROM   xxcso_cust_routes_v2  xcrv1
                               WHERE  xcrv1.route_number    = gt_route_no
                               AND    xcrv1.account_number  = xcav1.account_number
                            )
                          )
                        )
                        OR
                        ( gt_route_no IS NULL )
                      )
              UNION ALL
              -- �\��(�V�S��) �����|���Ǘ���ڋq�ȊO
              SELECT  /*+
                        LEADING(xrcv2.fa xrcv2.efdfc xrrv2.rtn_ctx xrrv2.rsrc_ctx xtrr2 )
                        INDEX(xrcv2.fa fnd_application_u3)
                        USE_NL(xrcv2.fa xrcv2.efdfce xrrv2.rtn_ctx xrrv2.rsrc_ctx xtrr2)
                      */
                      '1'                                sort_code
                     ,xcav2.customer_class_name          customer_class_name
                     ,xrrv2.account_number               account_number
                     ,xcav2.party_name                   party_name
                     ,xrrv2.trgt_resource                trgt_resource
                     ,xrrv2.trgt_route_no                trgt_route_no
                     ,xrrv2.next_resource                next_resource
                     ,xrrv2.next_route_no                next_route_no
              FROM    xxcso_tmp_rtn_rsrc      xtrr2  -- ���[�gNo�^�c�ƈ�CSV�o�͈ꎞ�\
                     ,xxcso_resource_custs_v  xrcv2  -- �ڋq�S���c�ƈ��r���[
                     ,xxcso_rtn_rsrc_v        xrrv2  -- �K��E����v��^���[�gNo�S���c�ƈ��ꊇ�X�V��ʗp�r���[
                     ,xxcso_cust_accounts_v   xcav2  -- �ڋq�}�X�^�r���[
                     ,fnd_lookup_values_vl    flvv2  -- �Q�ƃ^�C�v�u���[�gNo�Ǘ��Ώیڋq�v
              WHERE   xtrr2.employee_number         = xrcv2.employee_number
              AND     xrcv2.start_date_active       > gd_process_date         -- �����ȍ~
              AND     xrcv2.end_date_active         IS NULL
              AND     xrcv2.account_number          = xrrv2.account_number
              AND     xrrv2.account_number          = xcav2.account_number
              AND     flvv2.lookup_type             = cv_route_mgr_cust_class
              AND     gd_process_date               BETWEEN flvv2.start_date_active
                                                    AND     NVL( flvv2.end_date_active, gd_process_date )
              AND     flvv2.attribute1              = cv_no                   -- ���|���Ǘ���ȊO
              AND     NVL( xcav2.customer_class_code, cv_00 ) || '-' || xcav2.customer_status = flvv2.lookup_code
              AND     xcav2.rsv_sale_base_code      = xtrr2.base_code
              AND     xcav2.rsv_sale_base_act_date >= gd_next_date            -- �Ɩ����t�̗����ȍ~
              AND     xcav2.rsv_sale_base_act_date <= gd_next_month_last_date -- �Ɩ����t�̗�������
              AND     (
                        (
                          ( gt_route_no IS NOT NULL )
                          AND
                          ( EXISTS(
                              SELECT  /*+ 
                                        LEADING(xcrv2.hca)
                                        USE_NL(xcrv2.hca xcrv2.fa xcrv2.hp xcrv2.hop xcrv2.efdfce xcrv2.hopeb)
                                      */
                                      1
                              FROM    xxcso_cust_routes_v  xcrv2
                              WHERE   xcrv2.route_number       = gt_route_no
                              AND     xcrv2.start_date_active  > gd_process_date --�����ȍ~
                              AND     xcrv2.end_date_active    IS NULL
                              AND     xcrv2.account_number     = xcav2.account_number
                            )
                          )
                        )
                        OR
                        ( gt_route_no IS NULL )
                      )
              UNION ALL
              -- ������Ǘ���ڋq
              SELECT  /*+
                        LEADING(xrcv3.fa xrcv3.efdfc xrrv3.rtn_ctx xrrv3.rsrc_ctx xtrr3)
                        INDEX(xrcv3.fa fnd_application_u3)
                        USE_NL(xrcv3.fa xrcv3.efdfce xrrv3.rtn_ctx xrrv3.rsrc_ctx xtrr3)
                      */
                      '3'                                sort_code
                     ,xxcso_util_common_pkg.get_lookup_meaning(
                        cv_customer_class
                       ,hca3.customer_class_code
                       ,gd_process_date
                      )                                  customer_class_name
                     ,xrrv3.account_number               account_number
                     ,hp3.party_name                     party_name
                     ,xrrv3.trgt_resource                trgt_resource
                     ,xrrv3.trgt_route_no                trgt_route_no
                     ,xrrv3.next_resource                next_resource
                     ,xrrv3.next_route_no                next_route_no
              FROM    xxcso_tmp_rtn_rsrc       xtrr3  -- ���[�gNo�^�c�ƈ�CSV�o�͈ꎞ�\
                     ,xxcso_resource_custs_v2  xrcv3  -- �ڋq�S���c�ƈ��r���[
                     ,xxcso_rtn_rsrc_v         xrrv3  -- �K��E����v��^���[�gNo�S���c�ƈ��ꊇ�X�V��ʗp�r���[
                     ,hz_cust_accounts         hca3   -- �ڋq�}�X�^
                     ,hz_parties               hp3    -- �p�[�e�B�}�X�^
                     ,xxcmm_cust_accounts      xca3   -- �ڋq�ǉ����
                     ,fnd_lookup_values_vl     flvv3  -- �Q�ƃ^�C�v�u���[�gNo�Ǘ��Ώیڋq�v
              WHERE   xtrr3.employee_number     = xrcv3.employee_number
              AND     xrcv3.account_number      = xrrv3.account_number
              AND     xrrv3.account_number      = hca3.account_number
              AND     hca3.party_id             = hp3.party_id
              AND     hca3.cust_account_id      = xca3.customer_id
              AND     flvv3.lookup_type         = cv_route_mgr_cust_class
              AND     gd_process_date           BETWEEN flvv3.start_date_active
                                                AND     NVL( flvv3.end_date_active, gd_process_date )
              AND     flvv3.attribute1          = cv_yes  -- ���|���Ǘ���
              AND     hca3.customer_class_code || '-' || hp3.duns_number_c = flvv3.lookup_code
              AND     xca3.receiv_base_code     = xtrr3.base_code
              AND     gt_route_no IS NULL                 -- ���|���Ǘ���ڋq�Ƀ��[�gNo�͂Ȃ�
            ) sub
    ORDER BY
      sub.trgt_resource   -- ���S��
     ,sub.sort_code       -- �\�[�g�R�[�h(���|���Ǘ���ڋq�ȊO���D��j
     ,sub.account_number  -- �ڋq�R�[�h
    ;
--
  --�擾�f�[�^�i�[�ϐ���`
  TYPE g_out_file_ttype IS TABLE OF route_emp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code       IN  VARCHAR2  -- 1.���_�R�[�h
   ,iv_employee_number IN  VARCHAR2  -- 2.�c�ƈ�
   ,iv_route_no        IN  VARCHAR2  -- 3.���[�gNo
   ,ov_errbuf          OUT VARCHAR2  --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode         OUT VARCHAR2  --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg          OUT VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lv_msg_base_code   VARCHAR2(100);  -- ���_�R�[�h�o�͗p
    lv_msg_emp_number  VARCHAR2(100);  -- �c�ƈ��o�͗p
    lv_msg_route_no    VARCHAR2(100);  -- ���[�gNo�o�͗p
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
--
    --==================================================
    -- ���̓p�����[�^�i�[
    --==================================================
--
    gt_base_code       := iv_base_code;
    gt_employee_number := iv_employee_number;
    gt_route_no        := iv_route_no;
--
    --==================================================
    -- ���O�o��
    --==================================================
--
    -- ���_�R�[�h
    lv_msg_base_code   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_cso_00130    -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_entry        -- �g�[�N���R�[�h1
                          , iv_token_value1 => gt_base_code        -- �g�[�N���l1
                          );
    -- �c�ƈ�
    lv_msg_emp_number  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_cso_00842    -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_entry        -- �g�[�N���R�[�h1
                          , iv_token_value1 => gt_employee_number  -- �g�[�N���l1
                          );
    -- ���[�gNo
    lv_msg_route_no    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcso  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_cso_00843    -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_entry        -- �g�[�N���R�[�h1
                          , iv_token_value1 => gt_route_no         -- �g�[�N���l1
                          );
--
    -- ���O�ɏo��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''                || CHR(10) ||
                 lv_msg_base_code  || CHR(10) ||  -- ���_�R�[�h
                 lv_msg_emp_number || CHR(10) ||  -- �c�ƈ�
                 lv_msg_route_no   || CHR(10)     -- ���[�gNo
    );
--
    --==================================================
    -- �����p�̓��t�̎擾
    --==================================================
    -- �Ɩ����t
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    -- �Ɩ����t�̎擾�Ɏ��s�����ꍇ�̓G���[
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_appl_name_xxcso
         ,iv_name         => cv_msg_cso_00011
      );
      lv_errbuf  := lv_errmsg;
      RAISE init_err_expt;
    END IF;
--
    -- �Ɩ����t�̗���
    gd_next_date := TRUNC( gd_process_date + 1 );
--
   -- �Ɩ����t�̗�������
   gd_next_month_last_date := TRUNC( LAST_DAY( ADD_MONTHS( gd_process_date, 1 ) ) );
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN init_err_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
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
   * Procedure Name   : get_route_emp_data
   * Description      : ���[�gNo�^�c�ƈ����擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_route_emp_data(
    ov_errbuf                       OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_route_emp_data'; -- �v���O������
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
    ln_emp_cnt  NUMBER;  -- ���_�c�ƈ��̌���
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
    --==================================================
    -- �Ώۉc�ƈ����f�[�^�擾
    --==================================================
    BEGIN
--
      -- ���_�̂ݎw��(�c�ƈ��̎w��Ȃ�)
      IF ( gt_employee_number IS NULL ) THEN
--
        -- �ꎟ�\�ɑΏۂ̋��_�̉c�ƈ���}��
        INSERT INTO xxcso_tmp_rtn_rsrc (
           base_code           -- �������_
          ,employee_number     -- �c�ƈ�
        )
        SELECT  /*+
                  LEADING( xrmev.jrgb )
                  INDEX( xrmev.jrgb xxcso_jtf_rs_groups_n01 )
                  USE_NL( xrmev.jrgb xrmev.jrgm xrmev.xrv2 )
                */
                gt_base_code           base_code
               ,xrmev.employee_number  employee_number
        FROM    xxcso_route_management_emp_v xrmev
        WHERE   xrmev.employee_base_code = gt_base_code
        ;
--
        -- ���_�c�ƈ��̌���
        ln_emp_cnt := SQL%ROWCOUNT;
--
      -- �c�ƈ��̎w�肠��
      ELSE
--
        -- �ꎟ�\�ɑΏۂ̋��_�̉c�ƈ���}��
        INSERT INTO xxcso_tmp_rtn_rsrc (
           base_code           -- �������_
          ,employee_number     -- �c�ƈ�
        )
        SELECT  /*+
                  LEADING( xrmev.xrv2.ppf )
                  INDEX( xrmev.xrv2.ppf per_people_f_n51 )
                  USE_NL( xrmev.xrv2 xrmev.jrgm xrmev.jrgb  )
                */
                gt_base_code           base_code
               ,xrmev.employee_number  employee_number
        FROM    xxcso_route_management_emp_v xrmev
        WHERE   xrmev.employee_base_code = gt_base_code
        AND     xrmev.employee_number    = gt_employee_number
        ;
--
        -- ���_�c�ƈ��̌���
        ln_emp_cnt := SQL%ROWCOUNT;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00649
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => cv_msg_cso_00845
                      ,iv_token_name2  => cv_tkn_err_message
                      ,iv_token_value2 => SQLERRM
                     );
        RAISE global_api_expt; 
    END;
--
    -- �c�ƈ����擾�ł����ꍇ
    IF ( ln_emp_cnt > 0 ) THEN
--
      OPEN  route_emp_cur;
      FETCH route_emp_cur BULK COLLECT INTO gt_out_file_tab;
      CLOSE route_emp_cur;
--
      --���������J�E���g
      gn_target_cnt := gt_out_file_tab.COUNT;
--
    ELSE
--
      -- ���������J�E���g
      gn_target_cnt := 0;
--
    END IF;
--
    -- �o�͑Ώۂ����݂��Ȃ��ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
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
  END get_route_emp_data;
--
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : CSV�t�@�C���o��(A-3)
   ***********************************************************************************/
  PROCEDURE output_data(
    ov_errbuf                       OUT    VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    lv_line_data            VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
    lv_out_process_time     VARCHAR2(10);           -- �ҏW��̏�������
    lv_csv_header           VARCHAR2(5000);         -- CSV�w�b�_�o�͗p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
    -- *** ���[�J���E�e�[�u�� ***
    lt_head_tab g_head_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================================
    -- CSV�w�b�_�o��
    --==================================================
    -- ���b�Z�[�W�擾
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcso
                    ,iv_name         => cv_msg_cso_00844
                   );
--
    -- �w�b�_�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
--
    --==================================================
    -- �f�[�^�o��
    --==================================================
    --�f�[�^���擾
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --������
      lv_line_data := NULL;
      --�f�[�^��ҏW
      lv_line_data :=                gt_out_file_tab(i).customer_class_name  -- �ڋq�敪��
                      || cv_comma || gt_out_file_tab(i).account_number       -- �ڋq�R�[�h
                      || cv_comma || gt_out_file_tab(i).party_name           -- �ڋq��
                      || cv_comma || gt_out_file_tab(i).trgt_resource        -- ���S��
                      || cv_comma || gt_out_file_tab(i).trgt_route_no        -- �����[�gNo
                      || cv_comma || gt_out_file_tab(i).next_resource        -- �V�S��
                      || cv_comma || gt_out_file_tab(i).next_route_no        -- �V���[�gNo
                      ;
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
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
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code        IN  VARCHAR2,     -- 1.���_�R�[�h
    iv_employee_number  IN  VARCHAR2,     -- 2.�c�ƈ�
    iv_route_no         IN  VARCHAR2,     -- 3.���[�gNo
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_base_code       => iv_base_code        -- 1.���_�R�[�h
      ,iv_employee_number => iv_employee_number  -- 2.�c�ƈ�
      ,iv_route_no        => iv_route_no         -- 3.���[�gNo
      ,ov_errbuf          => lv_errbuf           --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode          --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );           
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�gNo�^�c�ƈ����擾(A-2)
    -- ===============================
    get_route_emp_data(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      RAISE global_warn_expt;
    END IF;
--
    -- ===============================
    -- CSV�t�@�C���o��(A-3)
    -- ===============================
    output_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    --�f�[�^�Ȃ��x��
    WHEN global_warn_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := ov_errmsg;
      ov_retcode := lv_retcode;
--
--#################################  �Œ��O������ START   ###################################
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
    errbuf             OUT VARCHAR2,   --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode            OUT VARCHAR2,   --   ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code       IN  VARCHAR2,   -- 1.���_�R�[�h
    iv_employee_number IN  VARCHAR2,   -- 2.�c�ƈ�
    iv_route_no        IN  VARCHAR2    -- 3.���[�gNo
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
    cv_appl_name_xxccp CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
--
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
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_base_code       => iv_base_code        -- 1.���_�R�[�h
      ,iv_employee_number => iv_employee_number  -- 2.�c�ƈ�
      ,iv_route_no        => iv_route_no         -- 3.���[�gNo
      ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �I������(A-6)
    -- ===============================
    --�X�e�[�^�X����
    IF (lv_retcode = cv_status_warn) THEN
      --CSV�t�@�C���o��0���G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcso
                      ,iv_name         => cv_msg_cso_00224
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    ELSIF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;  --�Ώی���
      gn_normal_cnt := 0;  --��������
      gn_error_cnt  := 1;  --�G���[����
      --
      --�G���[�o��
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
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
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
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
END XXCSO019A12C;
/