CREATE OR REPLACE PACKAGE BODY XXCOS009A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A06R (body)
 * Description      : EDI�[�i�\�薢�[���X�g
 * MD.050           : EDI�[�i�\�薢�[���X�g MD050_COS_009_A06
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_data               �Ώۃf�[�^�擾(A-2)
 *  insert_rpt_wrk_data    ���[���[�N�e�[�u���o�^(A-3)
 *  execute_svf            SVF�N��(A-4)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���폜(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/07    1.0   H.Ri             �V�K�쐬
 *  2009/02/17    1.1   H.Ri             get_msg�̃p�b�P�[�W���C��
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
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id; --PER_BUSINESS_GROUP_ID
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �����Ώۃf�[�^�o�^��O ***
  global_data_insert_expt           EXCEPTION;
  --*** SVF�N����O ***
  global_svf_excute_expt            EXCEPTION;
  --*** �Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  --*** �Ώۃf�[�^�폜��O ***
  global_data_delete_expt           EXCEPTION;
  
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS009A06R';         -- �p�b�P�[�W��
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS009A06R';         -- �R���J�����g��
  --���[�o�͊֘A
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS009A06R';         -- ���[�h�c
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A06S.xml';     -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A06S.vrq';     -- �N�G���[�l���t�@�C����
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                    -- �o�͋敪(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                 -- �g���q(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                -- ���ʗ̈�Z�k�A�v����
  cv_half_space             CONSTANT  VARCHAR2(100) := ' ';                    -- ���p�X�y�[�X
  --���b�Z�[�W
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00010';    -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00018';    -- ����0���G���[���b�Z�[�W
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_api_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00017';    -- API�G���[���b�Z�[�W
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  --�g�[�N����
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          --�e�[�u������
  cv_tkn_nm_table_lock      CONSTANT  VARCHAR2(100) :=  'TABLE';               --�e�[�u������(���b�N�G���[���p)
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            --�L�[�f�[�^
  cv_tkn_nm_api_name        CONSTANT  VARCHAR2(100) :=  'API_NAME';            --API����
  cv_tkn_nm_profile         CONSTANT  VARCHAR2(100) :=  'PROFILE';             --�v���t�@�C����(�̔��̈�)
  --�g�[�N���l
  cv_msg_vl_table_name      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11901';    --���[���[�N�e�[�u����
  cv_msg_vl_api_name        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00041';    --API����
  cv_msg_vl_key_request_id  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00088';    --�v��ID
  cv_msg_vl_min_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN���t
  cv_msg_vl_max_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX���t
  --���t�t�H�[�}�b�g
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) :=  'YYYYMMDD';            --YYYYMMDD�^
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';          --YYYY/MM/DD�^
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) :=  'YYYY/MM';             --YYYY/MM�^
  --�N�C�b�N�R�[�h�Q�Ɨp
  --�g�p�\�t���O�萔
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE :=  'Y';    --�g�p�\
  cv_lang                   CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );            --����
  cv_ord_src_type           CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_MST_009_A06'; --�󒍃\�[�X�̃N�C�b�N�^�C�v
  cv_ord_src_code           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A06_01';           --�󒍃\�[�X�̃N�C�b�N�R�[�h
  cv_hokan_type             CONSTANT  VARCHAR2(100) :=  'XXCOS1_HOKAN_TYPE_MST_009_A06'; --�ۊǏꏊ�̃N�C�b�N�^�C�v
  cv_hokan_code             CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A06_01';           --�ۊǏꏊ�̃N�C�b�N�R�[�h
  --�v���t�@�C���֘A
  cv_prof_min_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';     -- �v���t�@�C����(MIN���t)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';     -- �v���t�@�C����(MAX���t)
  --�J�e�S���^�X�e�[�^�X
  cv_emp                    CONSTANT  VARCHAR2(100) := 'EMP';                  -- �]�ƈ�
  cv_oh_status_booked       CONSTANT  VARCHAR2(100) := 'BOOKED';               -- �󒍃w�b�_�X�e�[�^�X(�L����)
  cv_ol_status_closed       CONSTANT  VARCHAR2(100) := 'CLOSED';               -- �󒍖��׃X�e�[�^�X(�N���[�Y)
  cv_ol_status_cancelled    CONSTANT  VARCHAR2(100) := 'CANCELLED';            -- �󒍖��׃X�e�[�^�X(���)
  cv_order_return           CONSTANT  VARCHAR2(100) := 'RETURN';               -- �}�C�i�X�󒍃^�C�v
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --EDI�[�i�\�薢�[���X�g���[���[�N�e�[�u���^
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_sch_dlv_list%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_report_data_tab         g_rpt_data_ttype;                                   --���[�f�[�^�R���N�V����
  gd_proc_date              DATE;                                               --�Ɩ����t
  gd_min_date               DATE;                                               --MIN���t
  gd_max_date               DATE;                                               --MAX���t
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- �v���O������
    cv_msg_no_para  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- �p�����[�^�������b�Z�[�W��
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
    lv_no_para_msg  VARCHAR2(5000);  -- �p�����[�^�������b�Z�[�W
    lv_date_item    VARCHAR2(100);   -- MIN���t/MAX���t
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
    --========================================
    -- 1.�p�����[�^�������b�Z�[�W�o�͏���
    --========================================
    lv_no_para_msg            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxccp_short_name,
        iv_name               =>  cv_msg_no_para
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_no_para_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --========================================
    -- 2.�Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.MIN���t�擾����
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_min_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.MAX���t�擾����
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_max_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
   * Procedure Name   : get_data
   * Description      : �����Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);
    ln_idx                    NUMBER;                                 --���C�����[�v�J�E���g
    lt_record_id              xxcos_rep_sch_dlv_list.record_id%TYPE;  --���R�[�hID
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR data_cur
    IS
      SELECT  
        lbiv.base_code                    base_code,        --�[�i���_�R�[�h
        MAX( lbiv.base_name )             base_name,        --�[�i���_��
        ooha.request_date                 req_date,         --�v����
        jrre.source_number                emp_code,         --�]�ƈ��ԍ�
        MAX( papf.per_information18 || 
        cv_half_space               || 
        papf.per_information19 )          emp_name,         --������ + ������
        hca.account_number                cust_code,        --�ڋq�R�[�h
        MAX( hp.party_name )              cust_name,        --�ڋq����
        ooha.order_number                 order_no,         --�󒍔ԍ�
        ooha.cust_po_number               entry_no,         --�ڋq����
        ooha.ordered_date                 ord_date,         --�󒍓�
        --���z���v
        SUM( 
          oola.ordered_quantity * DECODE( otta.order_category_code, cv_order_return, -1, 1 ) * oola.unit_selling_price
        )                                 amount            --���z
      FROM  
        oe_order_headers_all      ooha,                     --�󒍃w�b�_�e�[�u��
        oe_order_lines_all        oola,                     --�󒍖��׃e�[�u��
        mtl_secondary_inventories msi,                      --�ۊǏꏊ�}�X�^
        oe_order_sources          oos,                      --�󒍃\�[�X�}�X�^
        xxcos_login_base_info_v   lbiv,                     --���O�C�����[�U���_�r���[
        hz_cust_accounts          hca,                      --�ڋq�}�X�^
        xxcmm_cust_accounts       xca,                      --�ڋq�A�h�I��
        hz_parties                hp,                       --�p�[�e�B
        jtf_rs_resource_extns     jrre,                     --���\�[�X�}�X�^
        jtf_rs_salesreps          jrs,                      --jtf_rs_salesreps
        per_all_people_f          papf,                     --�]�ƈ��}�X�^
        per_person_types          ppt,                      --�]�ƈ��^�C�v�}�X�^
        oe_transaction_types_tl   ottt,                     --�󒍖��דE�v�p����^�C�v
        oe_transaction_types_all  otta                      --�󒍖��חp����^�C�v
      WHERE ooha.header_id       = oola.header_id           --�󒍃w�b�_.�w�b�_ID = �󒍖���.�w�b�_ID
      AND   ooha.order_source_id = oos.order_source_id      --�󒍃w�b�_.�󒍃\�[�XID = �󒍃\�[�X.�󒍃\�[�XID
      --�󒍃\�[�X�̃N�C�b�N�Q��(EDI��)
      AND   EXISTS(
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val,
                      fnd_lookup_types_tl         types_tl,
                      fnd_lookup_types            types,
                      fnd_application_tl          appl,
                      fnd_application             app
              WHERE   appl.application_id         = types.application_id
              AND     app.application_id          = appl.application_id
              AND     types_tl.lookup_type        = look_val.lookup_type
              AND     types.lookup_type           = types_tl.lookup_type
              AND     types.security_group_id     = types_tl.security_group_id
              AND     types.view_application_id   = types_tl.view_application_id
              AND     types_tl.language           = cv_lang
              AND     look_val.language           = cv_lang
              AND     appl.language               = cv_lang
              AND     app.application_short_name  = cv_xxcos_short_name
              AND     look_val.lookup_type        = cv_ord_src_type
              AND     look_val.lookup_code        = cv_ord_src_code
              AND     look_val.meaning            = oos.name
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
                  )
      AND   ooha.flow_status_code   = cv_oh_status_booked   --�󒍃w�b�_.�X�e�[�^�X = �L����
                                                            --�󒍖���.�X�e�[�^�X <> �N���[�Y�A���
      AND   oola.flow_status_code   NOT IN ( cv_ol_status_closed, cv_ol_status_cancelled )
      AND   oola.request_date       < gd_proc_date          --�󒍖���.�v���� < �Ɩ����t
      AND   oola.subinventory       = msi.secondary_inventory_name  --�󒍖���.�ۊǏꏊ = �ۊǏꏊ�}�X�^.����
      AND   oola.ship_from_org_id   = msi.organization_id   --�󒍖���.�o�׌��g�DID = �ۊǏꏊ�}�X�^.�݌ɑg�DID
      --�ۊǏꏊ�̃N�C�b�N�Q��(�c�Ǝ�)
      AND   EXISTS(
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val,
                      fnd_lookup_types_tl         types_tl,
                      fnd_lookup_types            types,
                      fnd_application_tl          appl,
                      fnd_application             app
              WHERE   appl.application_id         = types.application_id
              AND     app.application_id          = appl.application_id
              AND     types_tl.lookup_type        = look_val.lookup_type
              AND     types.lookup_type           = types_tl.lookup_type
              AND     types.security_group_id     = types_tl.security_group_id
              AND     types.view_application_id   = types_tl.view_application_id
              AND     types_tl.language           = cv_lang
              AND     look_val.language           = cv_lang
              AND     appl.language               = cv_lang
              AND     app.application_short_name  = cv_xxcos_short_name
              AND     look_val.lookup_type        = cv_hokan_type
              AND     look_val.lookup_code        = cv_hokan_code
              AND     look_val.meaning            = msi.attribute13
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
                    )
      AND   ooha.sold_to_org_id     = hca.cust_account_id   --�󒍃w�b�_.�ڋqID = �ڋq�}�X�^.�ڋqID
      AND   hca.party_id            = hp.party_id           --�ڋq�}�X�^.�p�[�e�B�[ID = �p�[�e�B.�p�[�e�B�[ID
      AND   hca.cust_account_id     = xca.customer_id       --�ڋq�}�X�^.�ڋqID = �ڋq�A�h�I��.�ڋqID
      AND   xca.delivery_base_code  = lbiv.base_code        --�ڋq�A�h�I��.�[�i���_�R�[�h = ���_�r���[.���_�R�[�h
      --�c�ƒS���҂̎擾�p
      AND   ooha.salesrep_id        = jrs.salesrep_id       --�󒍃w�b�_.�c�ƒS��ID = jtf_rs_salesreps.�c�ƒS��ID
      AND   jrs.resource_id         = jrre.resource_id
      AND   jrre.source_id          = papf.person_id
      AND   gd_proc_date            >= NVL( papf.effective_start_date, gd_min_date )
      AND   gd_proc_date            <= NVL( papf.effective_end_date, gd_max_date )
      AND   ppt.business_group_id   = cn_per_business_group_id
      AND   ppt.system_person_type  = cv_emp
      AND   ppt.active_flag         = ct_enabled_flg_y
      AND   papf.person_type_id     = ppt.person_type_id
      --�v���X�^�}�C�i�X�󒍃^�C�v����p
      AND   oola.line_type_id         = ottt.transaction_type_id
      AND   ottt.transaction_type_id  = otta.transaction_type_id
      AND   ottt.language             = cv_lang
      GROUP BY  lbiv.base_code,                                       --�[�i���_�R�[�h
                ooha.request_date,                                    --�v����
                jrre.source_number,                                   --�]�ƈ��ԍ�
                hca.account_number,                                   --�ڋq�R�[�h
                ooha.order_number,                                    --�󒍔ԍ�
                ooha.cust_po_number,                                  --�ڋq����
                ooha.ordered_date                                     --�󒍓�
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec                data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���[�v�J�E���g������
    ln_idx          := 0;
    --�Ώۃf�[�^�擾
    <<loop_get_data>>
    FOR l_data_rec IN data_cur LOOP
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT
          xxcos_rep_sch_dlv_list_s01.NEXTVAL     redord_id
        INTO
          lt_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx := ln_idx + 1;
      g_report_data_tab(ln_idx).record_id              := lt_record_id;                --���R�[�hID
      g_report_data_tab(ln_idx).base_code              := l_data_rec.base_code;        --���_�R�[�h
      g_report_data_tab(ln_idx).base_name              := l_data_rec.base_name;        --���_����
      g_report_data_tab(ln_idx).schedule_dlv_date      := l_data_rec.req_date;         --�[�i�\���
      g_report_data_tab(ln_idx).employee_base_code     := l_data_rec.emp_code;         --�c�ƒS���҃R�[�h
      g_report_data_tab(ln_idx).employee_base_name     := SUBSTRB( l_data_rec.emp_name, 1, 12 );  --�c�ƒS���Җ�
      g_report_data_tab(ln_idx).customer_number        := l_data_rec.cust_code;                   --�ڋq�ԍ�
      g_report_data_tab(ln_idx).customer_name          := SUBSTRB( l_data_rec.cust_name, 1, 20 ); --�ڋq��
      g_report_data_tab(ln_idx).order_number           := l_data_rec.order_no;         --�󒍔ԍ�
      g_report_data_tab(ln_idx).entry_number           := l_data_rec.entry_no;         --�`�[�ԍ�
      g_report_data_tab(ln_idx).amount                 := l_data_rec.amount;           --���z
      g_report_data_tab(ln_idx).ordered_date           := l_data_rec.ord_date;         --�󒍓�                        
      g_report_data_tab(ln_idx).created_by             := cn_created_by;               --�쐬��
      g_report_data_tab(ln_idx).creation_date          := cd_creation_date;            --�쐬��
      g_report_data_tab(ln_idx).last_updated_by        := cn_last_updated_by;          --�ŏI�X�V��
      g_report_data_tab(ln_idx).last_update_date       := cd_last_update_date;         --�ŏI�X�V��
      g_report_data_tab(ln_idx).last_update_login      := cn_last_update_login;        --�ŏI�X�V۸޲�
      g_report_data_tab(ln_idx).request_id             := cn_request_id;               --�v��ID
      g_report_data_tab(ln_idx).program_application_id := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
      g_report_data_tab(ln_idx).program_id             := cn_program_id;               --�ݶ��ĥ��۸���ID
      g_report_data_tab(ln_idx).program_update_date    := cd_program_update_date;      --��۸��эX�V��
    END LOOP loop_get_data;
--
    --���������J�E���g
    gn_target_cnt := g_report_data_tab.COUNT;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���o�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --���[���[�N�e�[�u�����{�ꖼ
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
    --���[���[�N�e�[�u���o�^����
    BEGIN
      FORALL ln_cnt IN g_report_data_tab.FIRST .. g_report_data_tab.LAST
        INSERT INTO 
          xxcos_rep_sch_dlv_list
        VALUES
          g_report_data_tab(ln_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
    --���팏���擾
    gn_normal_cnt := g_report_data_tab.COUNT;
--
  EXCEPTION
    --*** �����Ώۃf�[�^�o�^��O ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_insert_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-4)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lv_nodata_msg       VARCHAR2(5000);   --����0���p���b�Z�[�W
    lv_file_name        VARCHAR2(100);    --�o�̓t�@�C����
    lv_tkn_vl_api_name  VARCHAR2(100);    --API��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --����0���p���b�Z�[�W�擾
    lv_nodata_msg           :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_no_data_err
    );
--
    --�o�̓t�@�C�����ҏW
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF�N��
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              =>  lv_retcode,
      ov_errbuf               =>  lv_errbuf,
      ov_errmsg               =>  lv_errmsg,
      iv_conc_name            =>  cv_conc_name,
      iv_file_name            =>  lv_file_name,
      iv_file_id              =>  cv_report_id,
      iv_output_mode          =>  cv_output_mode,
      iv_frm_file             =>  cv_frm_file,
      iv_vrq_file             =>  cv_vrq_file,
      iv_org_id               =>  NULL,
      iv_user_name            =>  NULL,
      iv_resp_name            =>  NULL,
      iv_doc_name             =>  NULL,
      iv_printer_name         =>  NULL,
      iv_request_id           =>  TO_CHAR( cn_request_id ),
      iv_nodata_msg           =>  lv_nodata_msg,
      iv_svf_param1           =>  NULL,
      iv_svf_param2           =>  NULL,
      iv_svf_param3           =>  NULL,
      iv_svf_param4           =>  NULL,
      iv_svf_param5           =>  NULL,
      iv_svf_param6           =>  NULL,
      iv_svf_param7           =>  NULL,
      iv_svf_param8           =>  NULL,
      iv_svf_param9           =>  NULL,
      iv_svf_param10          =>  NULL,
      iv_svf_param11          =>  NULL,
      iv_svf_param12          =>  NULL,
      iv_svf_param13          =>  NULL,
      iv_svf_param14          =>  NULL,
      iv_svf_param15          =>  NULL
    );
    --SVF�N�����s
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF�N����O ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name      :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_api_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_api_err,
        iv_token_name1        =>  cv_tkn_nm_api_name,
        iv_token_value1       =>  lv_tkn_vl_api_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-5)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
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
    lv_key_info               VARCHAR2(5000);     --�L�[���
    lv_tkn_vl_key_request_id  VARCHAR2(100);      --�v��ID�̕���
    lv_tkn_vl_table_name      VARCHAR2(100);      --���[���[�N�e�[�u�����{�ꖼ
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT sdl.record_id rec_id
      FROM   xxcos_rep_sch_dlv_list sdl         --EDI�[�i�\�薢�[���X�g���[���[�N�e�[�u��
      WHERE sdl.request_id = cn_request_id      --�v��ID
      FOR UPDATE NOWAIT
      ;
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
    --�Ώۃf�[�^���b�N
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN lock_cur;
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
    EXCEPTION
      --�Ώۃf�[�^���b�N��O
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --�Ώۃf�[�^�폜
    BEGIN
      DELETE FROM 
        xxcos_rep_sch_dlv_list sdl              --EDI�[�i�\�薢�[���X�g���[���[�N�e�[�u��
      WHERE sdl.request_id = cn_request_id      --�v��ID
      ;
    EXCEPTION
      --�Ώۃf�[�^�폜���s
      WHEN OTHERS THEN
        lv_tkn_vl_key_request_id  :=  xxccp_common_pkg.get_msg(
          iv_application          =>  cv_xxcos_short_name,
          iv_name                 =>  cv_msg_vl_key_request_id
        );
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1         =>  lv_tkn_vl_key_request_id,   --�v��ID�̕���
          iv_data_value1        =>  TO_CHAR( cn_request_id ),   --�v��ID
          ov_key_info           =>  lv_key_info,                --�ҏW���ꂽ�L�[���
          ov_errbuf             =>  lv_errbuf,                  --�G���[���b�Z�[�W
          ov_retcode            =>  lv_retcode,                 --���^�[���R�[�h
          ov_errmsg             =>  lv_errmsg                   --���[�U�E�G���[�E���b�Z�[�W
        );
        IF ( lv_retcode = cv_status_normal ) THEN
          RAISE global_data_delete_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �����Ώۃf�[�^�폜��O�n���h�� ***
    WHEN global_data_delete_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_delete_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  lv_key_info
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    ld_dlv_date_from    DATE;         --   �[�i��(FROM)
    ld_dlv_date_to      DATE;         --   �[�i��(TO)
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
    init(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �Ώۃf�[�^�擾
    -- ===============================
    get_data(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ���[���[�N�e�[�u���o�^
    -- ===============================
    insert_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  SVF�N��
    -- ===============================
    execute_svf(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5  ���[���[�N�e�[�u���폜
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    --����0�����X�e�[�^�X���䏈��
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
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
    IF ( lv_retcode = cv_status_error ) THEN
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
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
                     iv_application  => cv_xxccp_short_name
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
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
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
                     iv_application  => cv_xxccp_short_name
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
END XXCOS009A06R;
/
