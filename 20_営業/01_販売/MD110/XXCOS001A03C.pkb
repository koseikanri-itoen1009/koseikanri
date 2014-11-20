CREATE OR REPLACE PACKAGE BODY XXCOS001A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A03C (body)
 * Description      : VD�[�i�f�[�^�쐬
 * MD.050           : VD�[�i�f�[�^�쐬(MD050_COS_001_A03)
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_data_update       �擾���e�[�u���t���O�X�V(A-5)
 *  proc_data_insert_line  �̔����уf�[�^�o�^����(����)(A-4-2)
 *  proc_data_insert_head  �̔����уf�[�^�o�^����(�w�b�_)(A-4-1)
 *  proc_molded            VD�[�i�f�[�^�쐬���^����(A-3)
 *  proc_extract           �Ώۃf�[�^���o(A-2)
 *  proc_init              ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0     N.Maeda          �V�K�쐬
 *  2009/02/02    1.1     N.Maeda          �[�i�`�[���͉�ʓ��̓f�[�^�Ή�(��ېŎ��̏���Ŋz��NVL�֐��ɂ�锻��ǉ�)
 *  2009/02/03    1.2     N.Maeda          HHT�S�ݓX���͋敪�̔�������ύX
 *                                         �]�ƈ��r���[��苒�_�R�[�h�擾���s���ۂ̏�����ǉ�
 *  2009/02/17    1.3     N.Maeda          ����ŗ��擾�����ɗL���t���O��ǉ�
 *  2009/02/18    1.4     N.Maeda          �ڋq���擾���̏����ύX(�duns_number��ˢduns_number_c�)
 *  2009/02/20    1.5     N.Maeda          �p�����[�^�̃��O�t�@�C���o�͑Ή�
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
  -- ���b�N�G���[
  lock_err_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_err_expt, -54 );
  -- �[�i�`�ԋ敪�G���[
  delivered_from_err_expt  EXCEPTION;
  -- ���o�ΏۂȂ��G���[
  no_data_extract          EXCEPTION;
  -- ���o�G���[
  extract_err_expt         EXCEPTION;
  -- �o�^�G���[
  insert_err_expt          EXCEPTION;
  -- �X�V�G���[
  updata_err_expt          EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(100):= 'XXCOS001A03C';             -- �p�b�P�[�W��
  cv_application                 CONSTANT VARCHAR2(5)  := 'XXCOS';                    -- �A�v���P�[�V������
  cv_prf_orga_code               CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE'; -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_max_date                CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';          -- XXCOS:MAX���t
  cv_prf_bks_id                  CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';         -- GL��v����ID
  cv_lookup_type                 CONSTANT VARCHAR2(100) := 'XXCOS1_CONSUMPTION_TAX_CLASS'; -- ����ŋ敪
  cv_cust_s                      CONSTANT VARCHAR2(2)  := '30';                       -- �ڋq
  cv_cust_v                      CONSTANT VARCHAR2(2)  := '40';                       -- ��l
  cv_cost_p                      CONSTANT VARCHAR2(2)  := '50';                       -- �x�~
--  cv_consum_code_out_tax         CONSTANT NUMBER  := 1;                          -- �ŃR�[�h(�O��)
--  cv_consum_code_no_tax          CONSTANT NUMBER  := 4;                          -- �ŃR�[�h(��ې�)
  cv_correct_class               CONSTANT NUMBER  := 1;                          -- ����E�����敪(����)
  cv_cancel_class                CONSTANT NUMBER  := 2;                          -- ����E�����敪(���)
  cv_black_flag                  CONSTANT NUMBER  := 1;                          -- �ԁE���t���O(��) 
  cv_red_flag                    CONSTANT NUMBER  := 0;                          -- �ԁE���t���O(��)
  cv_system_class_fs_vd          CONSTANT VARCHAR2(5)  := '24';                  -- �t���T�[�r�XVD
  cv_system_class_fs_vd_s        CONSTANT VARCHAR2(5)  := '25';                  -- �t���T�[�r�X�i�����jVD
  cv_customer_type_c             CONSTANT VARCHAR2(5)  := '10';                  -- �ڋq�敪(�ڋq)
  cv_customer_type_u             CONSTANT VARCHAR2(5)  := '12';                  -- �ڋq�敪(��l)
  cv_bace_branch                 CONSTANT VARCHAR2(5)  := '1';
  cv_input_class_fs_vd_at        CONSTANT VARCHAR2(5)  := '5';                   -- �t��VD(�����z��)
  cv_head_create_class_vd_d_c    CONSTANT NUMBER  := 3;
--  cv_tax_not_odd                 CONSTANT NUMBER  := 0;                          -- �[���̔�������p
  cv_forward_flag_no             CONSTANT VARCHAR2(1)  := 'N';                   -- �����σt���O(������)
  cv_xxcos1_input_class          CONSTANT VARCHAR2(50) := 'XXCOS1_INPUT_CLASS';
  cv_xxcos1_hokan_mst_001_a05    CONSTANT VARCHAR2(50) := 'XXCOS1_HOKAN_TYPE_MST_001_A05';
  cv_xxcos_001_a05_05            CONSTANT VARCHAR2(50) := 'XXCOS_001_A05_05';
  cv_xxcos_001_a05_09            CONSTANT VARCHAR2(50) := 'XXCOS_001_A05_09';
  cv_stand_date                  CONSTANT VARCHAR(25)  := 'YYYY/MM/DD HH24:MI';
  cv_short_day                   CONSTANT VARCHAR(25)  := 'YYYY/MM/DD';
--  cv_short_time                  CONSTANT VARCHAR(25)  := 'HH24:MI:SS';
  cv_amount_up                   CONSTANT VARCHAR(5)   := 'UP';
  cv_amount_down                 CONSTANT VARCHAR(5)   := 'DOWN';
  cv_amount_nearest              CONSTANT VARCHAR(10)  := 'NEAREST';
  cv_tkn_ti                      CONSTANT VARCHAR(10)  := ':';
  cv_con_char                    CONSTANT VARCHAR(25)  := ',';
  cv_space_char                  CONSTANT VARCHAR(25)  := ' ';
  cv_line_to_calculate_fees_f_n  CONSTANT VARCHAR(25)  := 'N';
  cv_line_unit_price_mst_flag_n  CONSTANT VARCHAR(25)  := 'N';
  cv_line_inv_interface_flag_n   CONSTANT VARCHAR(25)  := 'N';
  cv_head_ar_interface_flag_n    CONSTANT VARCHAR(25)  := 'N';
  cv_head_gl_interface_flag_n    CONSTANT VARCHAR(25)  := 'N';
  cv_head_dwh_interface_flag_n   CONSTANT VARCHAR(25)  := 'N';
  cv_head_edi_interface_flag_n   CONSTANT VARCHAR(25)  := 'N';
  cv_tkn_yes                     CONSTANT VARCHAR(10)  := 'Y';
--  cv_tkn_ja                      CONSTANT VARCHAR(10)  := 'JA';
--  cv_depart_type                 CONSTANT VARCHAR(10)  := '1';
--  cv_depart_car                  CONSTANT VARCHAR(10)  := '2';
  cv_line_order_invoice_l_num    CONSTANT VARCHAR(10)  := NULL;
  cv_head_order_source_id        CONSTANT VARCHAR(10)  := NULL;
  cv_head_order_invoice_number   CONSTANT VARCHAR(10)  := NULL;
  cv_head_order_connection_num   CONSTANT VARCHAR(10)  := NULL;
  cv_head_edi_send_date          CONSTANT VARCHAR(10)  := NULL;
  cv_tkn_null                    CONSTANT VARCHAR(10)  := NULL;
  cv_key_name_null               CONSTANT VARCHAR(10)  := NULL;
  -- ���f�[�^����ŋ敪
  cv_non_tax                     CONSTANT VARCHAR(10)  := '0';                -- ��ې�
  cv_out_tax                     CONSTANT VARCHAR(10)  := '1';                -- �O��
  cv_ins_slip_tax                CONSTANT VARCHAR(10)  := '2';                -- ���Łi�`�[�ېŁj
  cv_ins_bid_tax                 CONSTANT VARCHAR(10)  := '3';                -- ���Łi�P�����݁j
  cn_cons_tkn_zero               CONSTANT NUMBER  := 0;                       -- '0'
  --�G���[�R�[�h
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';         -- �v���t�@�C���擾�G���[
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';         -- XXCOS:MAX���t
  cv_loc_err         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';         -- ���b�N�G���[
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';         -- �Ɩ��������擾�G���[
  cv_msg_orga        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';         -- �݌ɑg�DID�擾�G���[
  cv_msg_orga_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';         -- �݌ɑg�D�R�[�h
  cv_msg_gl_books    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';         -- GL��v����
  cv_msg_lock_work   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10037';         -- �w�b�_���[�N�e�[�u���y�і��׃��[�N�e�[�u��
  cv_msg_cus_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';         -- �ڋq�}�X�^
  cv_inv_item_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';         -- �i�ڃ}�X�^
  cv_location_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00052';         -- �ۊǏꏊ�}�X�^
  cv_msg_lookup_mst  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';         -- �Q�ƃR�[�h�}�X�^
  cv_ar_tax_mst      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00067';         -- AR����Ń}�X�^
  cv_emp_data_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00068';         -- �]�ƈ����VIEW
  cv_msg_cus_type    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00074';         -- �ڋq�敪
  cv_msg_cus_code    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00053';         -- �ڋq�R�[�h
  cv_msg_lookup_code CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00082';         -- �Q�ƃR�[�h
  cv_msg_lookup_type CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00075';         -- �Q�ƃ^�C�v
  cv_msg_lookup_tax  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00076';         -- ����ŃR�[�h�i�Q�ƃR�[�h�}�X�^DFF2)
  cv_msg_item_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';         -- �i�ڃR�[�h
  cv_msg_org_id      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00063';         -- �݌ɑg�DID
  cv_msg_bace_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00055';         -- ���_�R�[�h
  cv_msg_type        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00077';         -- �^�C�v
  cv_msg_code        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00078';         -- �R�[�h
  cv_msg_location_type  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00079';      -- �ۊǏꏊ�敪
  cv_msg_dlv         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';         -- �[�i�҃R�[�h
  cv_msg_lookup_inp  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00081';         -- �Q�ƃR�[�h�i���͋敪�j
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';         -- �}�X�^�`�F�b�N�G���[
  cv_msg_no_data     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';         -- �ڋq�t�уf�[�^�擾�G���[
  cv_msg_data_count  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10101';         -- �Ώی������b�Z�[�W
  cv_msg_ins_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10102';         -- �o�^�������b�Z�[�W
  cv_msg_err_count   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10103';         -- �o�^�������b�Z�[�W
  cv_msg_update_err             CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12303'; -- �X�V�G���[
  cv_msg_delivered_from_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10104'; -- �[�i�`�ԋ敪�G���[
  cv_msg_extract_err            CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001'; -- ���o�G���[
  cv_msg_target_no_data         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00083'; -- ���͑Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_tab_name_colum_line    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00084'; -- VD�R�����ʎ����񖾍�
  cv_msg_tab_name_colum_head    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00085'; -- VD�R�����ʎ�����w�b�_
  cv_msg_tab_xxcos_sal_exp_head CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00086';  -- �̔����уw�b�_
  cv_msg_tab_xxcos_sal_exp_line CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00087';  -- �̔����і���
  cv_msg_tab_ins_err            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10351';  -- �o�^�G���[
  -- ���b�Z�[�W�o��
  cv_msg_count_he_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00141';   -- �w�b�_�Ώی���
  cv_msg_count_li_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00142';   -- ���בΏی���
  cv_msg_count_he_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00143';   -- �w�b�_�o�^��������
  cv_msg_count_li_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00144';   -- ���דo�^��������
  -- �g�[�N��
  cv_tkn_tab       CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_table     CONSTANT VARCHAR2(20)  := 'TABLE_NAME';           -- �e�[�u����
  cv_tkn_table_na  CONSTANT VARCHAR2(20)  := 'TABLE _NAME';
  cv_tkn_profile   CONSTANT VARCHAR2(20)  := 'PROFILE';              -- �v���t�@�C����
  cv_tkn_colmun    CONSTANT VARCHAR2(20)  := 'COLMUN';               -- �e�[�u����
  cv_key_data      CONSTANT VARCHAR2(20)  := 'KEY_DATA';             -- �ҏW���ꂽ�L�[���
  cv_target_cnt    CONSTANT VARCHAR2(20)  := 'COUNT';                -- �Ώی���
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- VD�R�����ʎ�����w�b�_�f�[�^�i�[�p�ϐ�
  TYPE g_rec_vd_c_head_data IS RECORD
    (
      row_id                       ROWID,                    -- �sID
      order_no_hht                 xxcos_vd_column_headers.order_no_hht%TYPE,             -- ��No.�iHHT)
      digestion_ln_number          xxcos_vd_column_headers.digestion_ln_number%TYPE,      -- �}��
      order_no_ebs                 xxcos_vd_column_headers.order_no_ebs%TYPE,             -- ��No.(EBS)
      base_code                    xxcos_vd_column_headers.base_code%TYPE,                -- ���_�R�[�h
      performance_by_code          xxcos_vd_column_headers.performance_by_code%TYPE,      -- ���ю҃R�[�h
      dlv_by_code                  xxcos_vd_column_headers.dlv_by_code%TYPE,              -- �[�i�҃R�[�h
      hht_invoice_no               xxcos_vd_column_headers.hht_invoice_no%TYPE,           -- HHT�`�[No.
      dlv_date                     xxcos_vd_column_headers.dlv_date%TYPE,                 -- �[�i��
      inspect_date                 xxcos_vd_column_headers.inspect_date%TYPE,             -- ������
      sales_classification         xxcos_vd_column_headers.sales_classification%TYPE,     -- ���㕪�ދ敪
      sales_invoice                xxcos_vd_column_headers.sales_invoice%TYPE,            -- ����`�[�敪
      card_sale_class              xxcos_vd_column_headers.card_sale_class%TYPE,          -- �J�[�h���敪
      dlv_time                     xxcos_vd_column_headers.dlv_time%TYPE,                 -- ����
      change_out_time_100          xxcos_vd_column_headers.change_out_time_100%TYPE,      -- ��K�؂ꎞ��100�~
      change_out_time_10           xxcos_vd_column_headers.change_out_time_10%TYPE,       -- ��K�؂ꎞ��10�~
      customer_number              xxcos_vd_column_headers.customer_number%TYPE,          -- �ڋq�R�[�h
      dlv_form                     xxcos_vd_column_headers.dlv_form%TYPE,                 -- �[�i�`��
      system_class                 xxcos_vd_column_headers.system_class%TYPE,             -- �Ƒԋ敪
      invoice_type                 xxcos_vd_column_headers.invoice_type%TYPE,             -- �`�[�敪
      input_class                  xxcos_vd_column_headers.input_class%TYPE,              -- ���͋敪
      consumption_tax_class        xxcos_vd_column_headers.consumption_tax_class%TYPE,    -- ����ŋ敪
      total_amount                 xxcos_vd_column_headers.total_amount%TYPE,             -- ���v���z
      sale_discount_amount         xxcos_vd_column_headers.sale_discount_amount%TYPE,     -- ����l���z
      sales_consumption_tax        xxcos_vd_column_headers.sales_consumption_tax%TYPE,    -- �������Ŋz
      tax_include                  xxcos_vd_column_headers.tax_include%TYPE,              -- �ō����z
      keep_in_code                 xxcos_vd_column_headers.keep_in_code%TYPE,             -- �a����R�[�h
      department_screen_class      xxcos_vd_column_headers.department_screen_class%TYPE,  -- �S�ݓX��ʎ��
      digestion_vd_rate_maked_date xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE, -- ����VD�|���쐬�ϔN����
      red_black_flag               xxcos_vd_column_headers.red_black_flag%TYPE,            -- �ԍ��t���O
      cancel_correct_class         xxcos_vd_column_headers.cancel_correct_class%TYPE      --����E�����敪
    );
  TYPE g_tab_vd_c_head_data IS TABLE OF g_rec_vd_c_head_data INDEX BY PLS_INTEGER;
--
  -- VD�R�����ʎ�����׏��
  TYPE g_rec_vd_c_lines_data IS RECORD
    (
      order_no_hht                xxcos_vd_column_lines.order_no_hht%TYPE,          --��No.(HHT)
      line_no_hht                 xxcos_vd_column_lines.line_no_hht%TYPE,           --�sNo.(HHT)
      digestion_ln_number         xxcos_vd_column_lines.digestion_ln_number%TYPE,   --�}��
      order_no_ebs                xxcos_vd_column_lines.order_no_ebs%TYPE,          --��No.(EBS)
      line_number_ebs             xxcos_vd_column_lines.line_number_ebs%TYPE,       --���הԍ�(EBS)
      item_code_self              xxcos_vd_column_lines.item_code_self%TYPE,        --�i���R�[�h(����)
      content                     xxcos_vd_column_lines.content%TYPE,               --����
      inventory_item_id           xxcos_vd_column_lines.inventory_item_id%TYPE,     --�i��ID
      standard_unit               xxcos_vd_column_lines.standard_unit%TYPE,         --��P��
      case_number                 xxcos_vd_column_lines.case_number%TYPE,           --�P�[�X��
      quantity                    xxcos_vd_column_lines.quantity%TYPE,              --����
      sale_class                  xxcos_vd_column_lines.sale_class%TYPE,            --����敪
      wholesale_unit_ploce        xxcos_vd_column_lines.wholesale_unit_ploce%TYPE,  --���P��
      selling_price               xxcos_vd_column_lines.selling_price%TYPE,         --���P��
      column_no                   xxcos_vd_column_lines.column_no%TYPE,             --�R����No
      h_and_c                     xxcos_vd_column_lines.h_and_c%TYPE,               --H/C
      sold_out_class              xxcos_vd_column_lines.sold_out_class%TYPE,        --���؋敪
      sold_out_time               xxcos_vd_column_lines.sold_out_time%TYPE,         --���؎���
      replenish_number            xxcos_vd_column_lines.replenish_number%TYPE,      --��[��
      cash_and_card               xxcos_vd_column_lines.cash_and_card%TYPE          --�����E�J�[�h���p�z
    );
  TYPE g_tab_vd_c_lines_data IS TABLE OF g_rec_vd_c_lines_data INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �w�b�_�f�[�^�o�^�p�ϐ�
  TYPE g_tab_head_row_id            IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;   -- �̔����уw�b�_ID
  TYPE g_tab_head_id                IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   -- �̔����уw�b�_ID
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_sales_exp_headers.order_number%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.(EBS)(�󒍔ԍ�)
  TYPE g_tab_head_digestion_ln_number IS TABLE OF xxcos_sales_exp_headers.digestion_ln_number%TYPE
    INDEX BY PLS_INTEGER;   -- �}��(��No(HHT)�}��)
  TYPE g_tab_head_dlv_invoice_class IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_class%TYPE
    INDEX BY PLS_INTEGER;   --�[�i�`�[�敪(���o)
  TYPE g_tab_head_cancel_cor_cls    IS TABLE OF xxcos_sales_exp_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;   --����E�����敪(���o)
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_sales_exp_headers.cust_gyotai_sho%TYPE
    INDEX BY PLS_INTEGER;   --�Ƒԋ敪(�Ƒԏ�����)
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_sales_exp_headers.delivery_date%TYPE
    INDEX BY PLS_INTEGER;   --�[�i��
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_sales_exp_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   --������
  TYPE g_tab_head_customer_number   IS TABLE OF xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    INDEX BY PLS_INTEGER;   --�ڋq�y�[�i��z
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_sales_exp_headers.sale_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   --������z���v
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_sales_exp_headers.pure_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   --���v���z(�{�̋��z���v)
  TYPE g_tab_head_sales_consump_tax IS TABLE OF xxcos_sales_exp_headers.tax_amount_sum%TYPE
    INDEX BY PLS_INTEGER;   --����ŋ��z���v
  TYPE g_tab_head_consump_tax_class IS TABLE OF xxcos_sales_exp_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   --����ŋ敪(���o)
  TYPE g_tab_head_tax_code          IS TABLE OF xxcos_sales_exp_headers.tax_code%TYPE
    INDEX BY PLS_INTEGER;   --�ŋ��R�[�h(���o)
  TYPE g_tab_head_tax_rate          IS TABLE OF xxcos_sales_exp_headers.tax_rate%TYPE
    INDEX BY PLS_INTEGER;   --����ŗ�(���o)
  TYPE g_tab_head_performance_by_code     IS TABLE OF xxcos_sales_exp_headers.results_employee_code%TYPE
    INDEX BY PLS_INTEGER;   --���ьv��҃R�[�h
  TYPE g_tab_head_sales_base_code   IS TABLE OF xxcos_sales_exp_headers.sales_base_code%TYPE
    INDEX BY PLS_INTEGER;   --���㋒�_�R�[�h(���o)
  TYPE g_tab_head_card_sale_class   IS TABLE OF xxcos_sales_exp_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   --�J�[�h����敪
  TYPE g_tab_head_sales_classificat    IS TABLE OF xxcos_sales_exp_headers.invoice_class%TYPE
    INDEX BY PLS_INTEGER;   --�`�[�敪
  TYPE g_tab_head_invoice_class     IS TABLE OF xxcos_sales_exp_headers.invoice_classification_code%TYPE
    INDEX BY PLS_INTEGER;   --�`�[���ރR�[�h
  TYPE g_tab_head_receiv_base_code  IS TABLE OF xxcos_sales_exp_headers.receiv_base_code%TYPE
    INDEX BY PLS_INTEGER;   --�������_�R�[�h(���o)
  TYPE g_tab_head_change_out_time_100     IS TABLE OF xxcos_sales_exp_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   --��K�؂ꎞ��100�~
  TYPE g_tab_head_change_out_time_10      IS TABLE OF xxcos_sales_exp_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   --��K�؂ꎞ��10�~
  TYPE g_tab_head_hht_dlv_input_date      IS TABLE OF xxcos_sales_exp_headers.hht_dlv_input_date%TYPE
    INDEX BY PLS_INTEGER;   --HHT�[�i���͓���(���^����)
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_sales_exp_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   --�[�i�҃R�[�h
  TYPE g_tab_head_business_date     IS TABLE OF xxcos_sales_exp_headers.business_date%TYPE
    INDEX BY PLS_INTEGER;   --�o�^�Ɩ����t(���������擾)
  TYPE g_tab_head_order_source_id   IS TABLE OF xxcos_sales_exp_headers.order_source_id%TYPE
    INDEX BY PLS_INTEGER;   --�󒍃\�[�XID(NULL�ݒ�)
  TYPE g_tab_head_order_invoice_num IS TABLE OF xxcos_sales_exp_headers.order_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   --�����`�[�ԍ�(NULL�ݒ�)
  TYPE g_tab_head_order_connect_num IS TABLE OF xxcos_sales_exp_headers.order_connection_number%TYPE
    INDEX BY PLS_INTEGER;   --�󒍊֘A�ԍ�(NULL�ݒ�)
  TYPE g_tab_head_ar_interface_flag IS TABLE OF xxcos_sales_exp_headers.ar_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --AR�C���^�t�F�[�X�σt���O('N'�ݒ�)
  TYPE g_tab_head_gl_interface_flag IS TABLE OF xxcos_sales_exp_headers.gl_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --GL�C���^�t�F�[�X�σt���O('N'�ݒ�)
  TYPE g_tab_head_dwh_interface_flag IS TABLE OF xxcos_sales_exp_headers.dwh_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --���V�X�e���C���^�t�F�[�X�σt���O('N'�ݒ�)
  TYPE g_tab_head_edi_interface_flag IS TABLE OF xxcos_sales_exp_headers.edi_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --EDI���M�ς݃t���O('N'�ݒ�)
  TYPE g_tab_head_edi_send_date      IS TABLE OF xxcos_sales_exp_headers.edi_send_date%TYPE
    INDEX BY PLS_INTEGER;   --EDI���M����(NULL�ݒ�)
  TYPE g_tab_head_create_class       IS TABLE OF xxcos_sales_exp_headers.create_class%TYPE
    INDEX BY PLS_INTEGER;   --�쐬���敪(�3��ݒ�)
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_sales_exp_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.(HHT)(��No(HHT))  
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_sales_exp_headers.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   --HHT�`�[No.(HHT�`�[No?�A�[�i�`�[No?)
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_sales_exp_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   --���͋敪
  --���׃f�[�^�o�^�p�ϐ�
  TYPE g_tab_line_sales_exp_line_id      IS TABLE OF xxcos_sales_exp_lines.sales_exp_line_id%TYPE
    INDEX BY PLS_INTEGER;   --�̔����і���ID
  TYPE g_tab_line_sal_exp_header_id    IS TABLE OF xxcos_sales_exp_lines.sales_exp_header_id%TYPE
    INDEX BY PLS_INTEGER;   --�̔����уw�b�_ID
  TYPE g_tab_line_dlv_invoice_number     IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_number%TYPE
    INDEX BY PLS_INTEGER;   --�[�i�`�[�ԍ�
  TYPE g_tab_line_dlv_invoice_l_num  IS TABLE OF xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   --�[�i���הԍ�
  TYPE g_tab_line_sales_class            IS TABLE OF xxcos_sales_exp_lines.sales_class%TYPE
    INDEX BY PLS_INTEGER;   --����敪
  TYPE g_tab_line_red_black_flag         IS TABLE OF xxcos_sales_exp_lines.red_black_flag%TYPE
    INDEX BY PLS_INTEGER;   --�ԍ��t���O
  TYPE g_tab_line_item_code              IS TABLE OF xxcos_sales_exp_lines.item_code%TYPE
    INDEX BY PLS_INTEGER;   --�i�ڃR�[�h
  TYPE g_tab_line_dlv_qty                IS TABLE OF xxcos_sales_exp_lines.dlv_qty%TYPE
    INDEX BY PLS_INTEGER;   --�[�i����
  TYPE g_tab_line_standard_qty           IS TABLE OF xxcos_sales_exp_lines.standard_qty%TYPE
    INDEX BY PLS_INTEGER;   --�����(�[�i����)
  TYPE g_tab_line_dlv_uom_code           IS TABLE OF xxcos_sales_exp_lines.dlv_uom_code%TYPE
    INDEX BY PLS_INTEGER;   --�[�i�P��
  TYPE g_tab_line_standard_uom_code      IS TABLE OF xxcos_sales_exp_lines.standard_uom_code%TYPE
    INDEX BY PLS_INTEGER;   --��P��(�[�i�P��)
  TYPE g_tab_line_dlv_unit_price         IS TABLE OF xxcos_sales_exp_lines.dlv_unit_price%TYPE
    INDEX BY PLS_INTEGER;   --�[�i�P��(�[�i�P��)
  TYPE g_tab_line_standard_unit_price    IS TABLE OF xxcos_sales_exp_lines.standard_unit_price%TYPE
    INDEX BY PLS_INTEGER;   --��P��
  TYPE g_tab_line_business_cost          IS TABLE OF xxcos_sales_exp_lines.business_cost%TYPE
    INDEX BY PLS_INTEGER;   --�c�ƌ���
  TYPE g_tab_line_sale_amount            IS TABLE OF xxcos_sales_exp_lines.sale_amount%TYPE
    INDEX BY PLS_INTEGER;   --������z
  TYPE g_tab_line_pure_amount            IS TABLE OF xxcos_sales_exp_lines.pure_amount%TYPE
    INDEX BY PLS_INTEGER;   --�{�̋��z
  TYPE g_tab_line_tax_amount             IS TABLE OF xxcos_sales_exp_lines.tax_amount%TYPE
    INDEX BY PLS_INTEGER;   --����ŋ��z
  TYPE g_tab_line_cash_and_card          IS TABLE OF xxcos_sales_exp_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   --�����E�J�[�h���p�z
  TYPE g_tab_line_ship_from_subinv_co    IS TABLE OF xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE
    INDEX BY PLS_INTEGER;   --�o�׌��ۊǏꏊ
  TYPE g_tab_line_delivery_base_code     IS TABLE OF xxcos_sales_exp_lines.delivery_base_code%TYPE
    INDEX BY PLS_INTEGER;   --�[�i���_�R�[�h
  TYPE g_tab_line_hot_cold_class         IS TABLE OF xxcos_sales_exp_lines.hot_cold_class%TYPE
    INDEX BY PLS_INTEGER;   --�g���b
  TYPE g_tab_line_column_no              IS TABLE OF xxcos_sales_exp_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   --�R����No
  TYPE g_tab_line_sold_out_class         IS TABLE OF xxcos_sales_exp_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   --���؋敪
  TYPE g_tab_line_sold_out_time          IS TABLE OF xxcos_sales_exp_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   --���؎���
  TYPE g_tab_line_to_cal_fees_flag IS TABLE OF xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE
    INDEX BY PLS_INTEGER;   --�萔���v�Z�C���^�t�F�[�X�σt���O
  TYPE g_tab_line_unit_price_mst_flag    IS TABLE OF xxcos_sales_exp_lines.unit_price_mst_flag%TYPE
    INDEX BY PLS_INTEGER;   --�P���}�X�^�쐬�σt���O
  TYPE g_tab_line_inv_interface_flag     IS TABLE OF xxcos_sales_exp_lines.inv_interface_flag%TYPE
    INDEX BY PLS_INTEGER;   --INV�C���^�t�F�[�X�σt���O
  TYPE g_tab_line_order_invoice_l_num IS TABLE OF xxcos_sales_exp_lines.order_invoice_line_number%TYPE
    INDEX BY PLS_INTEGER;   --�������הԍ�(NULL�ݒ�)
  TYPE g_tab_line_not_tax_amount      IS TABLE OF xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE
    INDEX BY PLS_INTEGER;   --�Ŕ���P��
  TYPE g_tab_line_delivery_pat_class      IS TABLE OF xxcos_sales_exp_lines.delivery_pattern_class%TYPE
    INDEX BY PLS_INTEGER;   --�[�i�`�ԋ敪(���o)
--
  --�w�b�_�f�[�^�i�[�ϐ�
  gt_head_row_id                  g_tab_head_row_id;              -- �w�b�_�sID
  gt_head_id                      g_tab_head_id;                  -- �̔����уw�b�_ID
  gt_head_order_no_ebs            g_tab_head_order_no_ebs;        -- �󒍔ԍ�
  gt_head_digestion_ln_number     g_tab_head_digestion_ln_number; -- �}��(��No(HHT)�}��)
  gt_head_dlv_invoice_class       g_tab_head_dlv_invoice_class;   -- �[�i�`�[�敪(���o)
  gt_head_cancel_cor_cls          g_tab_head_cancel_cor_cls;      -- ����E�����敪(���o)
  gt_head_system_class            g_tab_head_system_class;        -- �Ƒԋ敪(�Ƒԏ�����)
  gt_head_dlv_date                g_tab_head_dlv_date;            -- �[�i��
  gt_head_inspect_date            g_tab_head_inspect_date;        -- ������(����v���)
  gt_head_customer_number         g_tab_head_customer_number;     -- �ڋq�R�[�h(�ڋq�y�[�i��z)
  gt_head_tax_include             g_tab_head_tax_include;         -- �ō����z(������z���v)
  gt_head_total_amount            g_tab_head_total_amount;        -- ���v���z(�{�̋��z���v)
  gt_head_sales_consump_tax       g_tab_head_sales_consump_tax;   -- �������Ŋz(����ŋ��z���v)
  gt_head_consump_tax_class       g_tab_head_consump_tax_class;   -- ����ŋ敪(���o)
  gt_head_tax_code                g_tab_head_tax_code;            -- �ŋ��R�[�h(���o)
  gt_head_tax_rate                g_tab_head_tax_rate;            -- ����ŗ�(���o)
  gt_head_performance_by_code     g_tab_head_performance_by_code; -- ���ю҃R�[�h(���ьv��҃R�[�h)
  gt_head_sales_base_code         g_tab_head_sales_base_code;     -- ���㋒�_�R�[�h(���o)
  gt_head_card_sale_class         g_tab_head_card_sale_class;     -- �J�[�h����敪
  gt_head_sales_classification    g_tab_head_sales_classificat;   -- ���㕪�ދ敪(�`�[�敪)
  gt_head_invoice_class           g_tab_head_invoice_class;       -- ����`�[�敪(�`�[���ރR�[�h)
  gt_head_receiv_base_code        g_tab_head_receiv_base_code;    -- �������_�R�[�h(���o)
  gt_head_change_out_time_100     g_tab_head_change_out_time_100; -- ��K�؂ꎞ��100�~
  gt_head_change_out_time_10      g_tab_head_change_out_time_10;  -- ��K�؂ꎞ��10�~
  gt_head_hht_dlv_input_date      g_tab_head_hht_dlv_input_date;  -- HHT�[�i���͓���(���^����)
  gt_head_dlv_by_code             g_tab_head_dlv_by_code;         -- �[�i�҃R�[�h
  gt_head_business_date           g_tab_head_business_date;       -- �o�^�Ɩ����t(���������擾)
  gt_head_order_source_id         g_tab_head_order_source_id;      -- �󒍃\�[�XID(NULL�ݒ�)order_source_id
  gt_head_order_invoice_number    g_tab_head_order_invoice_num; -- �����`�[�ԍ�(NULL�ݒ�)
  gt_head_order_connection_num    g_tab_head_order_connect_num; -- �󒍊֘A�ԍ�(NULL�ݒ�)
  gt_head_ar_interface_flag       g_tab_head_ar_interface_flag;    -- AR�C���^�t�F�[�X�σt���O('N'�ݒ�)ar_interface_flag
  gt_head_gl_interface_flag       g_tab_head_gl_interface_flag;    -- GL�C���^�t�F�[�X�σt���O('N'�ݒ�)
  gt_head_dwh_interface_flag      g_tab_head_dwh_interface_flag;   -- ���V�X�e���C���^�t�F�[�X�σt���O('N'�ݒ�)
  gt_head_edi_interface_flag      g_tab_head_edi_interface_flag;   -- EDI���M�ς݃t���O('N'�ݒ�)
  gt_head_edi_send_date           g_tab_head_edi_send_date;        -- EDI���M����(NULL�ݒ�)
  gt_head_create_class            g_tab_head_create_class;         -- �쐬���敪(�3��ݒ�)
  gt_head_order_no_hht            g_tab_head_order_no_hht;      -- ��No.(HHT)(��No(HHT))  
  gt_head_hht_invoice_no          g_tab_head_hht_invoice_no;    -- HHT�`�[No.(HHT�`�[No?�A�[�i�`�[No?)
  gt_head_input_class             g_tab_head_input_class;       -- ���͋敪
--
  --���׃f�[�^�i�[�ϐ�
  gt_line_sales_exp_line_id       g_tab_line_sales_exp_line_id;      -- �̔����і���ID
  gt_line_sales_exp_header_id     g_tab_line_sal_exp_header_id;      -- �̔����уw�b�_ID  
  gt_line_dlv_invoice_number      g_tab_line_dlv_invoice_number;     -- �[�i�`�[�ԍ�
  gt_line_dlv_invoice_l_num       g_tab_line_dlv_invoice_l_num;      -- �[�i���הԍ�
  gt_line_sales_class             g_tab_line_sales_class;            -- ����敪
  gt_line_red_black_flag          g_tab_line_red_black_flag;         -- �ԍ��t���O
  gt_line_item_code               g_tab_line_item_code;              -- �i�ڃR�[�h
  gt_line_dlv_qty                 g_tab_line_dlv_qty;                -- �[�i����
  gt_line_standard_qty            g_tab_line_standard_qty;           -- �����
  gt_line_dlv_uom_code            g_tab_line_dlv_uom_code;           -- �[�i�P��
  gt_line_standard_uom_code       g_tab_line_standard_uom_code;      -- ��P��
  gt_dlv_unit_price               g_tab_line_dlv_unit_price;         -- �[�i�P��
  gt_line_standard_unit_price     g_tab_line_standard_unit_price;    -- ��P��
  gt_line_business_cost           g_tab_line_business_cost;          -- �c�ƌ���
  gt_line_sale_amount             g_tab_line_sale_amount;            -- ������z
  gt_line_pure_amount             g_tab_line_pure_amount;            -- �{�̋��z
  gt_line_tax_amount              g_tab_line_tax_amount;             -- ����ŋ��z
  gt_line_cash_and_card           g_tab_line_cash_and_card;          -- �����E�J�[�h���p�z
  gt_line_ship_from_subinv_co     g_tab_line_ship_from_subinv_co;    -- �o�׌��ۊǏꏊ
  gt_line_delivery_base_code      g_tab_line_delivery_base_code;     -- �[�i���_�R�[�h
  gt_line_hot_cold_class          g_tab_line_hot_cold_class;         -- �g���b
  gt_line_column_no               g_tab_line_column_no;              -- �R����No
  gt_line_sold_out_class          g_tab_line_sold_out_class;         -- ���؋敪
  gt_line_sold_out_time           g_tab_line_sold_out_time;          -- ���؎���
  gt_line_to_calculate_fees_flag  g_tab_line_to_cal_fees_flag;       -- �萔���v�Z�C���^�t�F�[�X�σt���O
  gt_line_unit_price_mst_flag     g_tab_line_unit_price_mst_flag;    -- �P���}�X�^�쐬�σt���O
  gt_line_inv_interface_flag      g_tab_line_inv_interface_flag;     -- INV�C���^�t�F�[�X�σt���O
  gt_line_order_invoice_l_num     g_tab_line_order_invoice_l_num;    -- �������הԍ�(NULL�ݒ�)
  gt_line_not_tax_amount          g_tab_line_not_tax_amount;         -- �Ŕ���P��
  gt_line_delivery_pat_class      g_tab_line_delivery_pat_class;         -- �[�i�`�ԋ敪(���o)
--
  gt_vd_c_headers_data            g_tab_vd_c_head_data;  -- VD�R�����ʎ�����w�b�_�e�[�u�����o�f�[�^
  gt_vd_c_lines_data              g_tab_vd_c_lines_data; -- VD�R�����ʎ�����׏��e�[�u�����o�f�[�^
  gt_inp_vd_c_headers_data        g_tab_vd_c_head_data;  -- ���͉�ʃf�[�^VD�R�����ʎ�����w�b�_�e�[�u�����o�f�[�^
  gt_inp_vd_c_lines_data          g_tab_vd_c_lines_data; -- ���͉�ʃf�[�^VD�R�����ʎ�����׏��e�[�u�����o�f�[�^
--
--  gn_consum_amount    NUMBER;
--  gn_head_cnt         NUMBER;                         -- �w�b�_�o�^����
  gn_line_cnt         NUMBER;                         -- ���דo�^����
  gn_update_count     NUMBER;                         -- �X�V����
--  gn_amount_data      NUMBER;                         -- �{�̋��z
--  gn_sales_amount     NUMBER;                         -- ������z
--  gt_consum_amount    NUMBER;                         -- ����Ŋz
--  gn_inp_target_cnt   NUMBER;                         -- ���͉�ʓo�^�f�[�^�擾����(�w�b�_)
  gn_target_lines_cnt NUMBER;                         -- ���׌����J�E���g�p
--  gn_target_lines_inp_cnt NUMBER;                     -- ���͉�ʓo�^�f�[�^�擾����(����)
  gn_orga_id          NUMBER;                         -- �݌ɑg�DID
  gn_header_ck_no     NUMBER := 1;                    -- �w�b�_�o�^�p�ϐ��Y����
  gn_line_ck_no       NUMBER := 1;                    -- ���דo�^�p�ϐ��Y����
  gd_process_date     DATE;                           -- �Ɩ�������
  gd_input_date       DATE;                           -- HHT�[�i���͓���
  gd_max_date         DATE;                           -- MAX���t
  gv_orga_code        VARCHAR2(50);                   -- �݌ɑg�D�R�[�h
  gv_bks_id           VARCHAR2(50);                   -- ��v����ID
  gv_tkn1             VARCHAR2(5000);                   -- �G���[���b�Z�[�W�p�g�[�N���P
  gv_tkn2             VARCHAR2(5000);                   -- �G���[���b�Z�[�W�p�g�[�N���Q
  gv_tkn3             VARCHAR2(5000);                   -- �G���[���b�Z�[�W�p�g�[�N���R
--
  /**********************************************************************************
   * Procedure Name   : proc_data_update
   * Description      : �擾���e�[�u���t���O�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE proc_data_update(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_update'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  --==================
  -- ���[�U�[��`�ϐ�
  --==================
--  lt_update_rowid     ROWID;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --== �f�[�^�o�^ ==--
    -- ���׃f�[�^�쐬�����Z�b�g
    gn_update_count := gt_vd_c_headers_data.COUNT;
--
    <<id_loop>>
    FOR row_count IN 1..gn_update_count LOOP
      gt_head_row_id( row_count ) := gt_vd_c_headers_data( row_count ).row_id;
    END LOOP id_loop;
--
    BEGIN
--
      FORALL i IN 1..gn_update_count
--
       UPDATE xxcos_vd_column_headers
       SET    forward_flag = cv_tkn_yes,                           --�A�g�ς݃t���O
              forward_date = gd_process_date,                      --�A�g��
              last_updated_by = cn_last_updated_by,                --�ŏI�X�V��
              last_update_date = cd_last_update_date,              --�ŏI�X�V��
              last_update_login = cn_last_update_login,            --�ŏI�X�V۸޲�
              request_id = cn_request_id,                          --�v��ID
              program_application_id = cn_program_application_id,  --�ݶ��ĥ��۸��ѥ���ع����ID
              program_id = cn_program_id,                          --�ݶ��ĥ��۸���ID
              program_update_date = cd_program_update_date         --��۸��эX�V��                        
       WHERE  ROWID  =  gt_head_row_id( i );
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_head );
        gv_tkn2    := xxccp_common_pkg.get_msg( cv_application, cv_msg_update_err,
                                                cv_tkn_table,gv_tkn1);
        RAISE updata_err_expt;
    END;
--
  EXCEPTION
    WHEN updata_err_expt THEN
      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--####################################  �Œ蕔 START ###########################################
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
  END proc_data_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_data_insert_line
   * Description      : �̔����уf�[�^�o�^����(����)(A-4-2)
   ***********************************************************************************/
  PROCEDURE proc_data_insert_line(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2 )     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_insert_line'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --== �f�[�^�o�^ ==--
    -- ���׃f�[�^�쐬�����Z�b�g
    gn_line_cnt := gt_line_sales_exp_line_id.COUNT;
--
    BEGIN
      FORALL i IN 1..gn_line_cnt
        INSERT INTO xxcos_sales_exp_lines            --�̔����і��׃e�[�u��
                      (
                        sales_exp_line_id,             --1.�̔����і���ID
                        sales_exp_header_id,           --2.�̔����уw�b�_ID
                        dlv_invoice_number,            --3.�[�i�`�[�ԍ�
                        dlv_invoice_line_number,       --4.�[�i���הԍ�
                        order_invoice_line_number,     --5.�������הԍ�
                        sales_class,                   --6.����敪
                        red_black_flag,                --7.�ԍ��t���O
                        item_code,                     --8.�i�ڃR�[�h
                        dlv_qty,                       --9.�[�i����
                        standard_qty,                  --10.�����
                        dlv_uom_code,                  --11.�[�i�P��
                        standard_uom_code,             --12.��P��
                        dlv_unit_price,                --13.�[�i�P��
                        standard_unit_price_excluded,  --14.�Ŕ���P��
                        standard_unit_price,           --15.��P��
                        business_cost,                 --16.�c�ƌ���
                        sale_amount,                   --17.������z
                        pure_amount,                   --18.�{�̋��z
                        tax_amount,                    --19.����ŋ��z
                        cash_and_card,                 --20.�����E�J�[�h���p�z
                        ship_from_subinventory_code,   --21.�o�׌��ۊǏꏊ
                        delivery_base_code,            --22.�[�i���_�R�[�h
                        hot_cold_class,                --23.�g���b
                        column_no,                     --24.�R����No
                        sold_out_class,                --25.���؋敪
                        sold_out_time,                 --26.���؎���
                        delivery_pattern_class,        --27.�[�i�`�ԋ敪
                        to_calculate_fees_flag,        --28.�萔���v�Z�C���^�t�F�[�X�σt���O
                        unit_price_mst_flag,           --29.�P���}�X�^�쐬�σt���O
                        inv_interface_flag,            --30.INV�C���^�t�F�[�X�σt���O
                        created_by,                    --31.�쐬��
                        creation_date,                 --32.�쐬��
                        last_updated_by,               --33.�ŏI�X�V��
                        last_update_date,              --34.�ŏI�X�V��
                        last_update_login,             --35.�ŏI�X�V۸޲�
                        request_id,                    --36.�v��ID
                        program_application_id,        --37.�ݶ��ĥ��۸��ѥ���ع����ID
                        program_id,                    --38.�ݶ��ĥ��۸���ID
                        program_update_date )          --39.��۸��эX�V��
                      VALUES(
                        gt_line_sales_exp_line_id( i ),     --1.�̔����і���ID
                        gt_line_sales_exp_header_id( i ),   --2.�̔����уw�b�_ID
                        gt_line_dlv_invoice_number( i ),    --3.�[�i�`�[�ԍ�
                        gt_line_dlv_invoice_l_num( i ),     --4.�[�i���הԍ�
                        gt_line_order_invoice_l_num( i ),   --5.�������הԍ�
                        gt_line_sales_class( i ),           --6.����敪
                        gt_line_red_black_flag( i ),        --7.�ԍ��t���O
                        gt_line_item_code( i ),             --8.�i�ڃR�[�h
                        gt_line_dlv_qty( i ),               --9.�[�i����
                        gt_line_standard_qty( i ),          --10.�����
                        gt_line_dlv_uom_code( i ),          --11.�[�i�P��
                        gt_line_standard_uom_code( i ),     --12.��P��
                        gt_dlv_unit_price( i ),             --13.�[�i�P��
                        gt_line_not_tax_amount( i ),        --14.�Ŕ���P��
                        gt_line_standard_unit_price( i ),   --15.��P��
                        gt_line_business_cost( i ),         --16.�c�ƌ���
                        gt_line_sale_amount( i ),           --17.������z
                        gt_line_pure_amount( i ),           --18.�{�̋��z
                        gt_line_tax_amount( i ),            --19.����ŋ��z
                        gt_line_cash_and_card( i ),         --20.�����E�J�[�h���p�z
                        gt_line_ship_from_subinv_co( i ),   --21.�o�׌��ۊǏꏊ
                        gt_line_delivery_base_code( i ),    --22.�[�i���_�R�[�h
                        gt_line_hot_cold_class( i ),        --23.�g���b
                        gt_line_column_no( i ),             --24.�R����No
                        gt_line_sold_out_class( i ),        --25.���؋敪
                        gt_line_sold_out_time( i ),         --26.���؎���
                        gt_line_delivery_pat_class( i ),    --27.�[�i�`�ԋ敪
                        gt_line_to_calculate_fees_flag( i ), --28.�萔���v�Z�C���^�t�F�[�X�σt���O
                        gt_line_unit_price_mst_flag( i ),   --29.�P���}�X�^�쐬�σt���O
                        gt_line_inv_interface_flag( i ),    --30.INV�C���^�t�F�[�X�σt���O
                        cn_created_by,                      --31.�쐬��
                        cd_creation_date,                   --32.�쐬��
                        cn_last_updated_by,                 --33.�ŏI�X�V��
                        cd_last_update_date,                --34.�ŏI�X�V��
                        cn_last_update_login,               --35.�ŏI�X�V۸޲�
                        cn_request_id,                      --36.�v��ID
                        cn_program_application_id,          --37.�ݶ��ĥ��۸��ѥ���ع����ID
                        cn_program_id,                      --38.�ݶ��ĥ��۸���ID
                        cd_program_update_date );           --39.��۸��эX�V��
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_line );
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na, gv_tkn1 );
        RAISE insert_err_expt;
    END;
                              
--
  EXCEPTION
    WHEN insert_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_data_insert_line;
--
  /**********************************************************************************
   * Procedure Name   : proc_data_insert_head
   * Description      : �̔����уf�[�^�o�^����(�w�b�_)(A-4-1)
   ***********************************************************************************/
  PROCEDURE proc_data_insert_head(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2 )     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_data_insert_head'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --== �f�[�^�o�^ ==--
    -- �w�b�_�f�[�^�쐬�����Z�b�g
    gn_normal_cnt := gt_head_id.COUNT;
--
    BEGIN
      FORALL i IN 1..gn_normal_cnt
        INSERT INTO xxcos_sales_exp_headers          --�̔����уw�b�_�e�[�u��
                      (
                        sales_exp_header_id,           --1.�̔����уw�b�_ID
                        dlv_invoice_number,            --2.�[�i�`�[�ԍ�
                        order_invoice_number,          --3.�����`�[�ԍ�
                        order_number,                  --4.�󒍔ԍ�
                        order_no_hht,                  --5.��No(HHT)
                        digestion_ln_number,           --6.��No(HHT)�}��
                        order_connection_number,       --7.�󒍊֘A�ԍ�
                        dlv_invoice_class,             --8.�[�i�`�[�敪
                        cancel_correct_class,          --9.����E�����敪
                        input_class,                   --10.���͋敪
                        cust_gyotai_sho,               --11.�Ƒԏ�����
                        delivery_date,                 --12.�[�i��
                        orig_delivery_date,            --13.�I���W�i���[�i��
                        inspect_date,                  --14.������
                        orig_inspect_date,             --15.�I���W�i��������
                        ship_to_customer_code,         --16.�ڋq�y�[�i��z
                        sale_amount_sum,               --17.������z���v
                        pure_amount_sum,               --18.�{�̋��z���v
                        tax_amount_sum,                --19.����ŋ��z���v
                        consumption_tax_class,         --20.����ŋ敪
                        tax_code,                      --21.�ŋ��R�[�h
                        tax_rate,                      --22.����ŗ�
                        results_employee_code,         --23.���ьv��҃R�[�h
                        sales_base_code,               --24.���㋒�_�R�[�h
                        receiv_base_code,              --25.�������_�R�[�h
                        order_source_id,               --26.�󒍃\�[�XID
                        card_sale_class,               --27.�J�[�h����敪
                        invoice_class,                 --28.�`�[�敪
                        invoice_classification_code,   --29.�`�[���ރR�[�h
                        change_out_time_100,           --30.��K�؂ꎞ��100�~
                        change_out_time_10,            --31.��K�؂ꎞ��10�~
                        ar_interface_flag,             --32.AR�C���^�t�F�[�X�σt���O
                        gl_interface_flag,             --33.G�C���^�t�F�[�X�σt���O
                        dwh_interface_flag,            --34.���V�X�e���C���^�t�F�[�X�σt���O
                        edi_interface_flag,            --35.EDI���M�ς݃t���O
                        edi_send_date,                 --36.EDI���M����
                        hht_dlv_input_date,            --37.HHT�[�i���͓���
                        dlv_by_code,                   --38.�[�i�҃R�[�h
                        create_class,                  --39.�쐬���敪
                        business_date,                 --40.�o�^�Ɩ����t
                        created_by,                    --41.�쐬��
                        creation_date,                 --42.�쐬��
                        last_updated_by,               --43.�ŏI�X�V��
                        last_update_date,              --44.�ŏI�X�V��
                        last_update_login,             --45.�ŏI�X�V۸޲�
                        request_id,                    --46.�v��ID
                        program_application_id,        --47.�ݶ��ĥ��۸��ѥ���ع����ID
                        program_id,                    --48.�ݶ��ĥ��۸���ID
                        program_update_date )          --49.��۸��эX�V��
                      VALUES(
                        gt_head_id( i ),                    --1.�̔����уw�b�_ID
                        gt_head_hht_invoice_no( i ),        --2.HHT�`�[�ԍ�
                        gt_head_order_invoice_number( i ),  --3.�����`�[�ԍ�
                        gt_head_order_no_ebs( i ),          --4.�󒍔ԍ�
                        gt_head_order_no_hht( i ),          --5.��No(HHT)
                        gt_head_digestion_ln_number( i ),   --6.��No(HHT)�}��
                        gt_head_order_connection_num( i ),  --7.�󒍊֘A�ԍ�
                        gt_head_dlv_invoice_class( i ),     --8.�[�i�`�[�敪
                        gt_head_cancel_cor_cls( i ),        --9.����E�����敪
                        gt_head_input_class( i ),           --10.���͋敪
                        gt_head_system_class( i ),          --11.�Ƒԏ�����
                        gt_head_dlv_date( i ),              --12.�[�i��
                        gt_head_dlv_date( i ),              --13.�I���W�i���[�i��
                        gt_head_inspect_date( i ),          --14.������(����v���?)
                        gt_head_inspect_date( i ),          --15.�I���W�i��������
                        gt_head_customer_number( i ),       --16.�ڋq�y�[�i��z
                        gt_head_tax_include( i ),           --17.������z���v
                        gt_head_total_amount( i ),          --18.�{�̋��z���v
                        gt_head_sales_consump_tax( i ),     --19.����ŋ��z���v
                        gt_head_consump_tax_class( i ),     --20.����ŋ敪
                        gt_head_tax_code( i ),              --21.�ŋ��R�[�h
                        gt_head_tax_rate( i ),              --22.����ŗ�
                        gt_head_performance_by_code( i ),   --23.���ьv��҃R�[�h
                        gt_head_sales_base_code( i ),       --24.���㋒�_�R�[�h
                        gt_head_receiv_base_code( i ),      --25.�������_�R�[�h
                        gt_head_order_source_id( i ),       --26.�󒍃\�[�XID
                        gt_head_card_sale_class( i ),       --27.�J�[�h����敪
                        gt_head_sales_classification( i ),  --28.�`�[�敪
                        gt_head_invoice_class( i ),         --29.�`�[���ރR�[�h
                        gt_head_change_out_time_100( i ),   --30.��K�؂ꎞ��100�~
                        gt_head_change_out_time_10( i ),    --31.��K�؂ꎞ��10�~
                        gt_head_ar_interface_flag( i ),     --32.AR�C���^�t�F�[�X�σt���O
                        gt_head_gl_interface_flag( i ),     --33.GL�C���^�t�F�[�X�σt���O
                        gt_head_dwh_interface_flag( i ),    --34.���V�X�e���C���^�t�F�[�X�σt���O
                        gt_head_edi_interface_flag( i ),    --35.EDI���M�ς݃t���O
                        gt_head_edi_send_date( i ),         --36.EDI���M����
                        gt_head_hht_dlv_input_date( i ),    --37.HHT�[�i���͓���
                        gt_head_dlv_by_code( i ),           --38.�[�i�҃R�[�h
                        gt_head_create_class( i ),          --39.�쐬���敪
                        gt_head_business_date( i ),         --40.�o�^�Ɩ����t
                        cn_created_by,                 --41.�쐬��
                        cd_creation_date,              --42.�쐬��
                        cn_last_updated_by,            --43.�ŏI�X�V��
                        cd_last_update_date,           --44.�ŏI�X�V��
                        cn_last_update_login,          --45.�ŏI�X�V۸޲�
                        cn_request_id,                 --46.�v��ID
                        cn_program_application_id,     --47.�ݶ��ĥ��۸��ѥ���ع����ID
                        cn_program_id,                 --48.�ݶ��ĥ��۸���ID
                        cd_program_update_date );      --49.��۸��эX�V��
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_xxcos_sal_exp_head);
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_ins_err,
                                             cv_tkn_table_na,gv_tkn1 );
        RAISE insert_err_expt;
    END;
--
  EXCEPTION
    WHEN insert_err_expt THEN
--      lv_errbuf  := gv_tkn2;
      ov_errmsg  := gv_tkn2;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_data_insert_head;
--
  /**********************************************************************************
   * Procedure Name   : proc_molded
   * Description      : VD�[�i�f�[�^�쐬���^����(A-3)
   ***********************************************************************************/
  PROCEDURE proc_molded(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_molded'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  --==================
  -- ���[�U�[��`�ϐ�
  --==================
--
  --�w�b�_���i�[�ϐ�
  lt_order_no_hht                 xxcos_vd_column_headers.order_no_hht%TYPE;           --��No.(HHT)
  lt_digestion_ln_number          xxcos_vd_column_headers.digestion_ln_number%TYPE;    --�}��
  lt_order_no_ebs                 xxcos_vd_column_headers.order_no_ebs%TYPE;           --��No.(EBS)
  lt_base_code                    xxcos_vd_column_headers.base_code%TYPE;              --���_�R�[�h
  lt_performance_by_code          xxcos_vd_column_headers.performance_by_code%TYPE;    --���ю҃R�[�h
  lt_dlv_by_code                  xxcos_vd_column_headers.dlv_by_code%TYPE;            --�[�i�҃R�[�h
  lt_hht_invoice_no               xxcos_vd_column_headers.hht_invoice_no%TYPE;         --HHT�`�[No.
  lt_dlv_date                     xxcos_vd_column_headers.dlv_date%TYPE;               --�[�i��
  lt_inspect_date                 xxcos_vd_column_headers.inspect_date%TYPE;           --������
  lt_sales_classification         xxcos_vd_column_headers.sales_classification%TYPE;   --���㕪�ދ敪
  lt_sales_invoice                xxcos_vd_column_headers.sales_invoice%TYPE;          --����`�[�敪
  lt_card_sale_class              xxcos_vd_column_headers.card_sale_class%TYPE;        --�J�[�h���敪
  lt_dlv_time                     xxcos_vd_column_headers.dlv_time%TYPE;               --����
  lt_change_out_time_100          xxcos_vd_column_headers.change_out_time_100%TYPE;    --��K�؂ꎞ��100�~
  lt_change_out_time_10           xxcos_vd_column_headers.change_out_time_10%TYPE;     --��K�؂ꎞ��10�~
  lt_customer_number              xxcos_vd_column_headers.customer_number%TYPE;        --�ڋq�R�[�h
  lt_dlv_form                     xxcos_vd_column_headers.dlv_form%TYPE;               --�[�i�`��
  lt_system_class                 xxcos_vd_column_headers.system_class%TYPE;           --�Ƒԋ敪
  lt_invoice_type                 xxcos_vd_column_headers.invoice_type%TYPE;           --�`�[�敪
  lt_input_class                  xxcos_vd_column_headers.input_class%TYPE;            --���͋敪
  lt_consumption_tax_class        xxcos_vd_column_headers.consumption_tax_class%TYPE;  --����ŋ敪
  lt_total_amount                 xxcos_vd_column_headers.total_amount%TYPE;           --���v���z
  lt_sale_discount_amount         xxcos_vd_column_headers.sale_discount_amount%TYPE;   --����l���z
  lt_sales_consumption_tax        xxcos_vd_column_headers.sales_consumption_tax%TYPE;  --�������Ŋz
  lt_tax_include                  xxcos_vd_column_headers.tax_include%TYPE;            --�ō����z
  lt_keep_in_code                 xxcos_vd_column_headers.keep_in_code%TYPE;           --�a����R�[�h
  lt_department_screen_class      xxcos_vd_column_headers.department_screen_class%TYPE; --�S�ݓX��ʎ��
  lt_digestion_rate_maked_date xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE; --����VD�|���쐬�ϔN����
  lt_red_black_flag               xxcos_vd_column_headers.red_black_flag%TYPE;         --�ԍ��t���O
  lt_cancel_correct_class         xxcos_vd_column_headers.cancel_correct_class%TYPE;    --����E�����敪
  lt_sale_amount_sum              xxcos_sales_exp_headers.sale_amount_sum%TYPE;        -- ������z���v
  lt_pure_amount_sum              xxcos_sales_exp_headers.pure_amount_sum%TYPE;        -- �{�̋��z���v
  lt_tax_amount_sum               xxcos_sales_exp_headers.tax_amount_sum%TYPE;         -- ����ŋ��z���v
--
  --���׏��i�[�ϐ�
  lt_lin_order_no_hht             xxcos_vd_column_lines.order_no_hht%TYPE;             --��No.(HHT)
  lt_lin_line_no_hht              xxcos_vd_column_lines.line_no_hht%TYPE;              --�sNo.(HHT)
  lt_lin_digestion_ln_number      xxcos_vd_column_lines.digestion_ln_number%TYPE;      --�}��
  lt_lin_order_no_ebs             xxcos_vd_column_lines.order_no_ebs%TYPE;             --��No.(EBS)
  lt_lin_line_number_ebs          xxcos_vd_column_lines.line_number_ebs%TYPE;          --���הԍ�(EBS)
  lt_lin_item_code_self           xxcos_vd_column_lines.item_code_self%TYPE;           --�i���R�[�h(����)
  lt_lin_content                  xxcos_vd_column_lines.content%TYPE;                  --����
  lt_lin_inventory_item_id        xxcos_vd_column_lines.inventory_item_id%TYPE;        --�i��ID
  lt_lin_standard_unit            xxcos_vd_column_lines.standard_unit%TYPE;            --��P��
  lt_lin_case_number              xxcos_vd_column_lines.case_number%TYPE;              --�P�[�X��
  lt_lin_quantity                 xxcos_vd_column_lines.quantity%TYPE;                 --����
  lt_lin_sale_class               xxcos_vd_column_lines.sale_class%TYPE;               --����敪
  lt_lin_wholesale_unit_ploce     xxcos_vd_column_lines.wholesale_unit_ploce%TYPE;     --���P��
  lt_lin_selling_price            xxcos_vd_column_lines.selling_price%TYPE;            --���P��
  lt_lin_column_no                xxcos_vd_column_lines.column_no%TYPE;                --�R����No
  lt_lin_h_and_c                  xxcos_vd_column_lines.h_and_c%TYPE;                  --H/C
  lt_lin_sold_out_class           xxcos_vd_column_lines.sold_out_class%TYPE;           --���؋敪
  lt_lin_sold_out_time            xxcos_vd_column_lines.sold_out_time%TYPE;            --���؎���
  lt_lin_replenish_number         xxcos_vd_column_lines.replenish_number%TYPE;         --��[��
  lt_lin_cash_and_card            xxcos_vd_column_lines.cash_and_card%TYPE;            --�����E�J�[�h���p�z
  --
  lt_sale_base_code               xxcmm_cust_accounts.sale_base_code%TYPE;
  lt_tax_odd                      xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE;
  lt_secondary_inventory_name     mtl_secondary_inventories.secondary_inventory_name%TYPE;
  lt_stand_unit                   mtl_system_items_b.primary_unit_of_measure%TYPE;
  lt_consum_code                  fnd_lookup_values.attribute2%TYPE;
  lt_consum_type                  fnd_lookup_values.attribute3%TYPE;
  lt_ins_invoice_type             fnd_lookup_values.attribute4%TYPE;
  lt_location_type_code           fnd_lookup_values.meaning%TYPE;
  lt_depart_location_type_code    fnd_lookup_values.meaning%TYPE;
  lt_ins_line_invoice_type        fnd_lookup_values.attribute4%TYPE;
--  lt_lin_standard_amount          xxcos_vd_column_lines.standard_unit%TYPE;            --��P���ϐ��i�[�p
--  lt_lin_not_tax_amount           xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE; --�Ŕ���P��
--  ln_tax_amount                   xxcos_sales_exp_lines.tax_amount%TYPE;
  lt_tax_consum                   ar_vat_tax_all_b.tax_rate%TYPE;
  lt_dlv_base_code                xxcos_rs_info_v.base_code%TYPE;
  lt_sales_cost                   ic_item_mst_b.attribute7%TYPE;
  lv_depart_code                  xxcmm_cust_accounts.dept_hht_div%TYPE;
  lt_old_sales_cost               ic_item_mst_b.attribute7%TYPE;
  lt_new_sales_cost               ic_item_mst_b.attribute8%TYPE;
  lt_st_sales_cost                ic_item_mst_b.attribute9%TYPE;
  lt_stand_unit_price_excl        xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE;--�Ŕ���P��
  lt_standard_unit_price          xxcos_sales_exp_lines.standard_unit_price%TYPE;    -- ��P��
  lt_sale_amount                  xxcos_sales_exp_lines.sale_amount%TYPE;            -- ������z
  lt_pure_amount                  xxcos_sales_exp_lines.pure_amount%TYPE;            -- �{�̋��z
  lt_tax_amount                   xxcos_sales_exp_lines.tax_amount%TYPE;             -- ����ŋ��z
  --
  lt_set_replenish_number         xxcos_sales_exp_lines.standard_qty%TYPE;           -- �o�^�p�����(�[�i����)
  lt_set_sale_amount              xxcos_sales_exp_lines.sale_amount%TYPE;            -- �o�^�p������z
  lt_set_pure_amount              xxcos_sales_exp_lines.pure_amount%TYPE;            -- �o�^�p�{�̋��z
  lt_set_tax_amount               xxcos_sales_exp_lines.tax_amount%TYPE;             -- �o�^�p����ŋ��z
  lt_set_sale_amount_sum          xxcos_sales_exp_headers.sale_amount_sum%TYPE;      -- �o�^�p������z���v
  lt_set_pure_amount_sum          xxcos_sales_exp_headers.pure_amount_sum%TYPE;      -- �o�^�p�{�̋��z���v
  lt_set_tax_amount_sum           xxcos_sales_exp_headers.tax_amount_sum%TYPE;       -- �o�^�p����ŋ��z���v
--  lt_lin_sale_amount              NUMBER;                                            -- ������z
  ln_actual_id                    NUMBER;                                            -- �̔����уw�b�_ID
  ln_sales_exp_line_id            NUMBER;                                            -- ����ID
--  ln_tax_Odd                      NUMBER;
--  ln_up_odd                       NUMBER;
  ln_header_ck_no                 NUMBER  :=  1;                                     -- �w�b�_�`�F�b�N�ϔԍ�
  ln_line_cnt                     NUMBER  :=  1;                                     -- ���׃`�F�b�N�ϔԍ�
  ln_all_tax_amount               NUMBER  :=  0;                                     -- ����ŋ��z���v�l
  ln_max_tax_data                 NUMBER  :=  0;                                     -- ���׍ő����Ŋz
  ln_max_no_data                  NUMBER;                                            -- �w�b�_�ő����Ŗ��׍s�ԍ�
  ln_tax_data                     NUMBER;
  lv_delivery_type                VARCHAR2(500);                                     -- �[�i�`�ԋ敪
  lv_key_name1                    VARCHAR2(500);
  lv_key_name2                    VARCHAR2(500);
  lv_key_data1                    VARCHAR2(500);
  lv_key_data2                    VARCHAR2(500);
--
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- ���[�v�J�n�F�w�b�_��
    <<header_loop>>
    FOR ck_no IN 1..gn_target_cnt LOOP
--
      --�Ϗ����ł̏�����
      ln_all_tax_amount               := 0;
      --�ő����Ŋz�̏�����
      ln_max_tax_data                 := 0;
      -- �ő喾�הԍ�
      ln_max_no_data                  := 0;
      --�w�b�_���ڂ̑��
      lt_order_no_hht                 := gt_vd_c_headers_data(ck_no).order_no_hht;           --��No.(HHT)
      lt_digestion_ln_number          := gt_vd_c_headers_data(ck_no).digestion_ln_number;    --�}��
      lt_order_no_ebs                 := gt_vd_c_headers_data(ck_no).order_no_ebs;           --��No.(EBS)
      lt_base_code                    := gt_vd_c_headers_data(ck_no).base_code;              --���_�R�[�h
      lt_performance_by_code          := gt_vd_c_headers_data(ck_no).performance_by_code;    --���ю҃R�[�h
      lt_dlv_by_code                  := gt_vd_c_headers_data(ck_no).dlv_by_code;            --�[�i�҃R�[�h
      lt_hht_invoice_no               := gt_vd_c_headers_data(ck_no).hht_invoice_no;         --HHT�`�[No.
      lt_dlv_date                     := gt_vd_c_headers_data(ck_no).dlv_date;               --�[�i��
      lt_inspect_date                 := gt_vd_c_headers_data(ck_no).inspect_date;           --������
      lt_sales_classification         := gt_vd_c_headers_data(ck_no).sales_classification;   --���㕪�ދ敪
      lt_sales_invoice                := gt_vd_c_headers_data(ck_no).sales_invoice;          --����`�[�敪
      lt_card_sale_class              := gt_vd_c_headers_data(ck_no).card_sale_class;        --�J�[�h���敪
      lt_dlv_time                     := gt_vd_c_headers_data(ck_no).dlv_time;               --����
      lt_change_out_time_100          := gt_vd_c_headers_data(ck_no).change_out_time_100;    --��K�؂ꎞ��100�~
      lt_change_out_time_10           := gt_vd_c_headers_data(ck_no).change_out_time_10;     --��K�؂ꎞ��10�~
      lt_customer_number              := gt_vd_c_headers_data(ck_no).customer_number;        --�ڋq�R�[�h
      lt_dlv_form                     := gt_vd_c_headers_data(ck_no).dlv_form;               --�[�i�`��
      lt_system_class                 := gt_vd_c_headers_data(ck_no).system_class;           --�Ƒԋ敪
      lt_invoice_type                 := gt_vd_c_headers_data(ck_no).invoice_type;           --�`�[�敪
      lt_input_class                  := gt_vd_c_headers_data(ck_no).input_class;            --���͋敪
      lt_consumption_tax_class        := gt_vd_c_headers_data(ck_no).consumption_tax_class;  --����ŋ敪
      lt_total_amount                 := gt_vd_c_headers_data(ck_no).total_amount;           --���v���z
      lt_sale_discount_amount         := gt_vd_c_headers_data(ck_no).sale_discount_amount;   --����l���z
      lt_sales_consumption_tax        := gt_vd_c_headers_data(ck_no).sales_consumption_tax;  --�������Ŋz
      lt_tax_include                  := gt_vd_c_headers_data(ck_no).tax_include;            --�ō����z
      lt_keep_in_code                 := gt_vd_c_headers_data(ck_no).keep_in_code;           --�a����R�[�h
      lt_department_screen_class      := gt_vd_c_headers_data(ck_no).department_screen_class; --�S�ݓX��ʎ��
      lt_digestion_rate_maked_date    := gt_vd_c_headers_data(ck_no).digestion_vd_rate_maked_date; --����VD�|���쐬�ϔN����
      lt_red_black_flag               := gt_vd_c_headers_data(ck_no).red_black_flag;         --�ԍ��t���O
      lt_cancel_correct_class         := gt_vd_c_headers_data(ck_no).cancel_correct_class;   --����E�����敪
--
      --================================
      --�̔����уw�b�_ID(�V�[�P���X�擾)
      --================================
      SELECT xxcos_sales_exp_headers_s01.NEXTVAL AS NEXTVAL 
      INTO ln_actual_id
      FROM DUAL;
      --=========================
      --�ڋq�}�X�^�t�я��̓��o
      --=========================
      BEGIN
        SELECT  xca.sale_base_code, --���㋒�_�R�[�h
                xch.bill_tax_round_rule -- �ŋ�-�[������(�T�C�g)
        INTO    lt_sale_base_code,
                lt_tax_odd
        FROM    hz_cust_accounts hca,  --�ڋq�}�X�^
                xxcmm_cust_accounts xca, --�ڋq�ǉ����
                xxcos_cust_hierarchy_v xch -- �ڋq�K�w�r���[
        WHERE   hca.cust_account_id = xca.customer_id
        AND     xch.ship_account_id = hca.cust_account_id
        AND     xch.ship_account_id = xca.customer_id
        AND     hca.account_number = TO_CHAR( lt_customer_number )
        AND     hca.customer_class_code IN ( cv_customer_type_c, cv_customer_type_u )
        AND     hca.party_id IN ( SELECT  hpt.party_id
                                  FROM    hz_parties hpt
                                  WHERE   hpt.duns_number_c   IN ( cv_cust_s , cv_cust_v , cv_cost_p ) );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --�L�[�ҏW����
          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
          lv_key_data1 := cv_customer_type_c||cv_con_char||cv_customer_type_u;
          lv_key_data2 := lt_customer_number;
          RAISE no_data_extract;
      END;
--
      --========================
      --����ŃR�[�h�̓��o
      --========================
      BEGIN
        SELECT  look_val.attribute2,  --����ŃR�[�h
                look_val.attribute3   --�̔����јA�g���̏���ŋ敪
        INTO    lt_consum_code,
                lt_consum_type
        FROM    fnd_lookup_values     look_val,  --�N�C�b�N�R�[�h
                fnd_lookup_types_tl   types_tl,  --
                fnd_lookup_types      types,     --
                fnd_application_tl    appl,      --
                fnd_application       app        --
        WHERE   appl.application_id   = types.application_id
        AND     app.application_id    = appl.application_id
        AND     types_tl.lookup_type  = look_val.lookup_type
        AND     types.lookup_type     = types_tl.lookup_type
        AND     types.security_group_id   = types_tl.security_group_id
        AND     types.view_application_id = types_tl.view_application_id
        AND     types_tl.language = USERENV( 'LANG' )
        AND     look_val.language = USERENV( 'LANG' )
        AND     appl.language     = USERENV( 'LANG' )
        AND     app.application_short_name = cv_application
        AND     gd_process_date      >= look_val.start_date_active
        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
        AND     look_val.enabled_flag = cv_tkn_yes
        AND     look_val.lookup_type = cv_lookup_type
        AND     look_val.lookup_code = lt_consumption_tax_class;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg(cv_application, cv_msg_lookup_mst );
          --�L�[�ҏW����
          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_code );
          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_type );
          lv_key_data1 := lt_consumption_tax_class;
          lv_key_data2 := cv_lookup_type;
          RAISE no_data_extract;
      END;
--
      --====================
      --����Ń}�X�^���擾
      --====================
      BEGIN
        SELECT avtab.tax_rate           -- ����ŗ�
        INTO   lt_tax_consum 
        FROM   ar_vat_tax_all_b avtab   -- AR����Ń}�X�^
        WHERE  avtab.tax_code = lt_consum_code
        AND    avtab.set_of_books_id = TO_NUMBER(gv_bks_id)
/*--==============2009/2/4-START=========================--*/
        AND    NVL( avtab.start_date, gd_process_date )  <= gd_process_date
        AND    NVL( avtab.end_date, gd_max_date ) >= gd_process_date
/*--==============2009/2/4--END==========================--*/
/*--==============2009/2/17-START=========================--*/
        AND    avtab.enabled_flag = cv_tkn_yes;
/*--==============2009/2/17--END==========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ���O�o��          
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_ar_tax_mst );
          --�L�[�ҏW����
          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_tax );
          lv_key_name2 := NULL;
          lv_key_data1 := lt_consum_code;
          lv_key_data2 := NULL;
          RAISE no_data_extract;
      END;
      --HHT�[�i���͓����`��
      gd_input_date :=TO_DATE(TO_CHAR( lt_dlv_date, cv_short_day )||cv_space_char||
                              SUBSTR(lt_dlv_time,1,2)||cv_tkn_ti||SUBSTR(lt_dlv_time,3,2), cv_stand_date );
      -- ����ŗ��Z�o
      ln_tax_data := ( (100 + lt_tax_consum) / 100 );
--
      --==========================
      --�o�׌��ۊǏꏊ�̓��o
      --==========================
      BEGIN
        SELECT xca.dept_hht_div   -- HHT�S�ݓX���͋敪
        INTO   lv_depart_code
        FROM   hz_cust_accounts hca,  -- �ڋq�}�X�^
               xxcmm_cust_accounts xca  -- �ڋq�ǉ����
        WHERE  hca.cust_account_id = xca.customer_id
        AND    hca.account_number = lt_base_code
        AND    hca.customer_class_code = cv_bace_branch;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN    
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
          --�L�[�ҏW����
          lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code );
          lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_type );
          lv_key_data1 := lt_base_code;
          lv_key_data2 := cv_bace_branch;
        RAISE no_data_extract;
      END;
--
/*--==============2009/2/3-START=========================--*/
--      IF ( lv_depart_code = cv_depart_car ) THEN
      IF ( lv_depart_code IS NULL ) THEN
/*--==============2009/2/3-END=========================--*/
        --�Q�ƃR�[�h�}�X�^�F�c�ƎԂ̕ۊǏꏊ���ރR�[�h�擾
        BEGIN
          SELECT  look_val.meaning      --�ۊǏꏊ���ރR�[�h
          INTO    lt_location_type_code
          FROM    fnd_lookup_values     look_val,
                  fnd_lookup_types_tl   types_tl,
                  fnd_lookup_types      types,
                  fnd_application_tl    appl,
                  fnd_application       app
          WHERE   appl.application_id   = types.application_id
          AND     app.application_id    = appl.application_id
          AND     types_tl.lookup_type  = look_val.lookup_type
          AND     types.lookup_type     = types_tl.lookup_type
          AND     types.security_group_id   = types_tl.security_group_id
          AND     types.view_application_id = types_tl.view_application_id
          AND     types_tl.language = USERENV( 'LANG' )
          AND     look_val.language = USERENV( 'LANG' )
          AND     appl.language     = USERENV( 'LANG' )
          AND     gd_process_date      >= look_val.start_date_active
          AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
          AND     app.application_short_name = cv_application
          AND     look_val.enabled_flag = cv_tkn_yes
          AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
          AND     look_val.lookup_code = cv_xxcos_001_a05_05;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
            --�L�[�ҏW�����p�ϐ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
            lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
            lv_key_data2 := cv_xxcos_001_a05_05;
          RAISE no_data_extract;
        END;
--
        --�ۊǏꏊ�}�X�^�f�[�^�擾
        BEGIN
          SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
          INTO   lt_secondary_inventory_name
          FROM   mtl_secondary_inventories msi    --�ۊǏꏊ�}�X�^
          WHERE  msi.attribute7 = lt_base_code
          AND    msi.attribute13 = lt_location_type_code
          AND    msi.attribute3 = lt_dlv_by_code;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
            --�L�[�ҏW�����p�ϐ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
            lv_key_data1 := lt_base_code;
            lv_key_data2 := cv_xxcos_001_a05_05;
          RAISE no_data_extract;
        END;
--
/*--==============2009/2/3-START=========================--*/
--      ELSIF ( lv_depart_code = cv_depart_type ) THEN
      ELSIF ( lv_depart_code IS NOT NULL ) THEN
/*--==============2009/2/3-END=========================--*/
        --�Q�ƃR�[�h�}�X�^�F�S�ݓX�̕ۊǏꏊ���ރR�[�h�擾
        BEGIN
          SELECT  look_val.meaning    --�ۊǏꏊ���ރR�[�h
          INTO    lt_depart_location_type_code
          FROM    fnd_lookup_values     look_val,
                  fnd_lookup_types_tl   types_tl,
                  fnd_lookup_types      types,
                  fnd_application_tl    appl,
                  fnd_application       app
          WHERE   appl.application_id   = types.application_id
          AND     app.application_id    = appl.application_id
          AND     types_tl.lookup_type  = look_val.lookup_type
          AND     types.lookup_type     = types_tl.lookup_type
          AND     types.security_group_id   = types_tl.security_group_id
          AND     types.view_application_id = types_tl.view_application_id
          AND     types_tl.language = USERENV( 'LANG' )
          AND     look_val.language = USERENV( 'LANG' )
          AND     appl.language     = USERENV( 'LANG' )
          AND     gd_process_date   >= look_val.start_date_active
          AND     gd_process_date   <= NVL(look_val.end_date_active, gd_max_date)
          AND     app.application_short_name = cv_application
          AND     look_val.enabled_flag = cv_tkn_yes
          AND     look_val.lookup_type = cv_xxcos1_hokan_mst_001_a05
          AND     look_val.lookup_code = cv_xxcos_001_a05_09;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
            --�L�[�ҏW�����p�ϐ��ݒ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_type );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_code );
            lv_key_data1 := cv_xxcos1_hokan_mst_001_a05;
            lv_key_data2 := cv_xxcos_001_a05_09;
          RAISE no_data_extract;
        END;
--
        --�ۊǏꏊ�}�X�^�f�[�^�擾
        BEGIN
          SELECT msi.secondary_inventory_name     -- �ۊǏꏊ�R�[�h
          INTO   lt_secondary_inventory_name
          FROM   mtl_secondary_inventories msi    -- �ۊǏꏊ�}�X�^
          WHERE  msi.attribute7 = lt_base_code
          AND    msi.attribute13 = lt_depart_location_type_code
          AND    msi.attribute4 = lt_customer_number;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_location_mst );
            --�L�[�ҏW�����p�ϐ��ݒ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_bace_code );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_location_type );
            lv_key_data1 := lt_base_code;
            lv_key_data2 := cv_xxcos_001_a05_09;
          RAISE no_data_extract;
        END;
      END IF;
--
      --=============
      -- �[�i�`�ԋ敪�擾
      --=============
      xxcos_common_pkg.get_delivered_from( lt_secondary_inventory_name,
                                           lt_base_code, 
                                           lt_base_code, 
                                           gv_orga_code,
                                           gn_orga_id, 
                                           lv_delivery_type,
                                           lv_errbuf, 
                                           lv_retcode, 
                                           lv_errmsg );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE delivered_from_err_expt;
      END IF;
      --====================
      --�[�i���_�̓��o(����)
      --====================
      BEGIN
        SELECT rin_v.base_code  --���_�R�[�h
        INTO lt_dlv_base_code
        FROM xxcos_rs_info_v rin_v   --�]�ƈ����view
        WHERE rin_v.employee_number = lt_dlv_by_code
/*--==============2009/2/3-START=========================--*/
        AND   NVL( rin_v.effective_start_date, lt_dlv_date ) <= lt_dlv_date
        AND   NVL( rin_v.effective_end_date, lt_dlv_date ) >= lt_dlv_date;
/*--==============2009/2/3-END=========================--*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_emp_data_mst );
            --�L�[�ҏW�p�ϐ��ݒ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv );
            lv_key_name2 := NULL;
            lv_key_data1 := lt_dlv_by_code;
            lv_key_data2 := NULL;
      RAISE no_data_extract;
      END;
--
      --=========================
      --�[�i�`�[���͋敪�̓��o(����)
      --=========================
      BEGIN
        SELECT  look_val.attribute4     -- �[�i�`�[�敪(�̔����ѓ��͋敪)
        INTO    lt_ins_line_invoice_type
        FROM    fnd_lookup_values     look_val,
                fnd_lookup_types_tl   types_tl,
                fnd_lookup_types      types,
                fnd_application_tl    appl,
                fnd_application       app
        WHERE   appl.application_id   = types.application_id
        AND     app.application_id    = appl.application_id
        AND     types_tl.lookup_type  = look_val.lookup_type
        AND     types.lookup_type     = types_tl.lookup_type
        AND     types.security_group_id   = types_tl.security_group_id
        AND     types.view_application_id = types_tl.view_application_id
        AND     types_tl.language = USERENV( 'LANG' )
        AND     look_val.language = USERENV( 'LANG' )
        AND     appl.language     = USERENV( 'LANG' )
        AND     gd_process_date      >= look_val.start_date_active
        AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
        AND     app.application_short_name = cv_application
        AND     look_val.enabled_flag = cv_tkn_yes
        AND     look_val.lookup_type = cv_xxcos1_input_class
        AND     look_val.lookup_code = lt_input_class;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
            --�L�[�ҏW�\�ϐ��ݒ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
            lv_key_name2 := NULL;
            lv_key_data1 := lt_input_class;
            lv_key_data2 := NULL;
          RAISE no_data_extract;
      END;
--
        --==========================
        --�[�i���׋敪�̓��o(�w�b�_)
        --==========================
      BEGIN
          SELECT  DECODE(lt_cancel_correct_class, 
                         cv_tkn_null, look_val.attribute4,        -- �ʏ펞(�[�i�`�[�敪(�̔����ѓ��͋敪))
                         cv_correct_class, look_val.attribute5,   -- �����(�[�i�`�[�敪(�̔����ѓ��͋敪))
                         cv_cancel_class, look_val.attribute5)    -- ����(�[�i�`�[�敪(�̔����ѓ��͋敪))
          INTO    lt_ins_invoice_type
          FROM    fnd_lookup_values     look_val,
                  fnd_lookup_types_tl   types_tl,
                  fnd_lookup_types      types,
                  fnd_application_tl    appl,
                  fnd_application       app
          WHERE   appl.application_id   = types.application_id
          AND     app.application_id    = appl.application_id
          AND     types_tl.lookup_type  = look_val.lookup_type
          AND     types.lookup_type     = types_tl.lookup_type
          AND     types.security_group_id   = types_tl.security_group_id
          AND     types.view_application_id = types_tl.view_application_id
          AND     types_tl.language = USERENV( 'LANG' )
          AND     look_val.language = USERENV( 'LANG' )
          AND     appl.language     = USERENV( 'LANG' )
          AND     gd_process_date      >= look_val.start_date_active
          AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
          AND     app.application_short_name = cv_application
          AND     look_val.enabled_flag = cv_tkn_yes
          AND     look_val.lookup_type = cv_xxcos1_input_class
          AND     look_val.lookup_code = lt_input_class;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_mst );
            --�L�[�ҏW�\�ϐ��ݒ�
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup_inp );
            lv_key_name2 := NULL;
            lv_key_data1 := lt_input_class;
            lv_key_data2 := NULL;
          RAISE no_data_extract;
        END;
--
      <<line_loop>>
      FOR ln_line_no IN ln_line_cnt..gn_target_lines_cnt LOOP                                   --���הԍ�
        lt_lin_order_no_hht     :=  gt_vd_c_lines_data( ln_line_no ).order_no_hht;              --��No.(HHT)
        lt_lin_line_no_hht      :=  gt_vd_c_lines_data( ln_line_no ).line_no_hht;               --�sNo.(HHT)
        lt_lin_digestion_ln_number :=  gt_vd_c_lines_data( ln_line_no ).digestion_ln_number;    --�}��
        lt_lin_order_no_ebs     :=  gt_vd_c_lines_data( ln_line_no ).order_no_ebs;              --��No.(EBS)
        lt_lin_line_number_ebs  :=  gt_vd_c_lines_data( ln_line_no ).line_number_ebs;           --���הԍ�(EBS)
        lt_lin_item_code_self   :=  gt_vd_c_lines_data( ln_line_no ).item_code_self;            --�i���R�[�h(����)
        lt_lin_content          :=  gt_vd_c_lines_data( ln_line_no ).content;                   --����
        lt_lin_inventory_item_id :=  gt_vd_c_lines_data( ln_line_no ).inventory_item_id;        --�i��ID
        lt_lin_standard_unit    :=  gt_vd_c_lines_data( ln_line_no ).standard_unit;             --��P��
        lt_lin_case_number      :=  gt_vd_c_lines_data( ln_line_no ).case_number;               --�P�[�X��
        lt_lin_quantity         :=  gt_vd_c_lines_data( ln_line_no ).quantity;                  --����
        lt_lin_sale_class       :=  gt_vd_c_lines_data( ln_line_no ).sale_class;                --����敪
        lt_lin_wholesale_unit_ploce :=  gt_vd_c_lines_data( ln_line_no ).wholesale_unit_ploce;  --���P��
        lt_lin_selling_price    :=  gt_vd_c_lines_data( ln_line_no ).selling_price;             --���P��
        lt_lin_column_no        :=  gt_vd_c_lines_data( ln_line_no ).column_no;                 --�R����No
        lt_lin_h_and_c          :=  gt_vd_c_lines_data( ln_line_no ).h_and_c;                   --H/C
        lt_lin_sold_out_class   :=  gt_vd_c_lines_data( ln_line_no ).sold_out_class;            --���؋敪
        lt_lin_sold_out_time    :=  gt_vd_c_lines_data( ln_line_no ).sold_out_time;             --���؎���
        lt_lin_replenish_number :=  gt_vd_c_lines_data( ln_line_no ).replenish_number;          --��[��
        lt_lin_cash_and_card    :=  gt_vd_c_lines_data( ln_line_no ).cash_and_card;             --�����E�J�[�h���p�z
--
        EXIT WHEN ( ( lt_order_no_hht || lt_digestion_ln_number ) <> ( lt_lin_order_no_hht || lt_lin_digestion_ln_number ) );
--
        IF ( lt_lin_case_number IS NULL ) THEN
          lt_lin_case_number := 0;
        END IF;
--
        --====================================
        --�c�ƌ����̓��o(�̔����і���(�R����))
        --====================================
        BEGIN
          SELECT ic_item.attribute7,              -- ���c�ƌ���
                 ic_item.attribute8,              -- �V�c�ƌ���
                 ic_item.attribute9,              -- �c�ƌ����K�p�J�n��
                 mtl_item.primary_unit_of_measure     -- ��P��
          INTO   lt_old_sales_cost,
                 lt_new_sales_cost,
                 lt_st_sales_cost,
                 lt_stand_unit
          FROM   mtl_system_items_b    mtl_item,    -- �i��
                 ic_item_mst_b         ic_item,     -- OPM�i��
                 xxcmm_system_items_b  cmm_item     -- Disc�i�ڃA�h�I��
          WHERE  mtl_item.organization_id   = gn_orga_id
          AND  mtl_item.segment1          = lt_lin_item_code_self
          AND  mtl_item.segment1 = ic_item.item_no
          AND  mtl_item.segment1 = cmm_item.item_code
          AND  cmm_item.item_id  = ic_item.item_id
/*--==============2009/2/4-START=========================--*/
          AND    NVL( mtl_item.start_date_active, gd_process_date) <= gd_process_date
          AND    NVL( mtl_item.end_date_active, gd_max_date ) >= gd_process_date;
/*--==============2009/2/4-END==========================--*/
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          --�L�[�ҏW����
            -- ���O�o��          
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_inv_item_mst );
            lv_key_name1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_key_name2 := xxccp_common_pkg.get_msg( cv_application, cv_msg_org_id );
            lv_key_data1 := lt_lin_item_code_self;
            lv_key_data2 := gn_orga_id;
            RAISE no_data_extract;
        END;
--
        -- �c�ƌ������f
        IF ( TO_DATE(lt_st_sales_cost,cv_short_day) > gd_process_date ) THEN
          lt_sales_cost := lt_old_sales_cost;
        ELSE
          lt_sales_cost := lt_new_sales_cost;
        END IF;
--
        -- ===================
        -- �o�^�p����ID�擾
        -- ===================
        SELECT xxcos_sales_exp_lines_s01.NEXTVAL AS NEXTVAL
        INTO   ln_sales_exp_line_id
        FROM   DUAL;
--
        -- ��P��
        lt_standard_unit_price   := lt_lin_wholesale_unit_ploce;
        -- ������z
        lt_sale_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
--
        IF ( lt_consumption_tax_class = cv_non_tax ) THEN         -- ��ې�
--
          -- �Ŕ���P��
          lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
          -- �{�̋��z
          lt_pure_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
          -- ����ŋ��z
          lt_tax_amount            := cn_cons_tkn_zero;
--
        ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
          -- �Ŕ���P��
          lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
          -- �{�̋��z
          lt_pure_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
          -- ����ŋ��z
          lt_tax_amount            := (  ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
            IF ( lt_tax_odd = cv_amount_up ) THEN
              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
            -- �؎̂�
            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount );
            -- �l�̌ܓ�
            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
              lt_tax_amount := ROUND( lt_tax_amount );
            END IF;
          END IF;
--
        ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
          -- �Ŕ���P��
          lt_stand_unit_price_excl := lt_lin_wholesale_unit_ploce;
          -- �{�̋��z
          lt_pure_amount           := ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number );
          -- ����ŋ��z
          lt_tax_amount            := ( ( lt_pure_amount * ln_tax_data ) - lt_pure_amount );
          IF ( lt_tax_amount <> TRUNC( lt_tax_amount ) ) THEN
            IF ( lt_tax_odd = cv_amount_up ) THEN
              lt_tax_amount := ( TRUNC( lt_tax_amount ) + 1 );
            -- �؎̂�
            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
              lt_tax_amount := TRUNC( lt_tax_amount );
            -- �l�̌ܓ�
            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
              lt_tax_amount := ROUND( lt_tax_amount );
            END IF;
          END IF;
--
        ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--
          -- �Ŕ���P��
          lt_stand_unit_price_excl := ( lt_lin_wholesale_unit_ploce / ln_tax_data );
          IF ( lt_stand_unit_price_excl <> TRUNC( lt_stand_unit_price_excl ) ) THEN
            IF ( lt_tax_odd = cv_amount_up ) THEN
              lt_stand_unit_price_excl := ( TRUNC( lt_stand_unit_price_excl ) + 1 );
            -- �؎̂�
            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
              lt_stand_unit_price_excl := TRUNC( lt_stand_unit_price_excl );
            -- �l�̌ܓ�
            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
              lt_stand_unit_price_excl := ROUND( lt_stand_unit_price_excl );
            END IF;
          END IF;
          -- �{�̋��z
          lt_pure_amount           := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number ) / ln_tax_data);
          IF ( lt_pure_amount <> TRUNC( lt_pure_amount ) ) THEN
            IF ( lt_tax_odd = cv_amount_up ) THEN
              lt_pure_amount := ( TRUNC( lt_pure_amount ) + 1 );
            -- �؎̂�
            ELSIF ( lt_tax_odd = cv_amount_down ) THEN
              lt_pure_amount := TRUNC( lt_pure_amount );
            -- �l�̌ܓ�
            ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
              lt_pure_amount := ROUND( lt_pure_amount );
            END IF;
          END IF;
          -- ����ŋ��z
          lt_tax_amount            := ( ( lt_lin_wholesale_unit_ploce * lt_lin_replenish_number )
                                         - lt_pure_amount );
--
        END IF;
--
        --�Ώƃf�[�^����ېłłȂ��Ƃ��̂Ƃ�
        IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
          --����ō��v�Ϗグ
            ln_all_tax_amount := ( ln_all_tax_amount + lt_tax_amount );
          --���וʍő����ŎZ�o
          IF ( ln_max_tax_data < lt_tax_amount ) THEN
            ln_max_tax_data := lt_tax_amount;
            ln_max_no_data  := gn_line_ck_no;
          END IF;
        END IF;
--
        -- �ԁE���̋��z���Z
        --���̎�
        IF ( lt_red_black_flag = cv_black_flag) THEN
          -- �����(�[�i����)
          lt_set_replenish_number := lt_lin_replenish_number;
          -- ������z
          lt_set_sale_amount := lt_sale_amount;
          -- �{�̋��z
          lt_set_pure_amount := lt_pure_amount;
          -- ����ŋ��z
          lt_set_tax_amount := lt_tax_amount;
        -- �Ԃ̎�
        ELSIF ( lt_red_black_flag = cv_red_flag) THEN
          -- �����(�[�i����)
          lt_set_replenish_number := ( lt_lin_replenish_number * ( -1 ) );
          -- ������z
          lt_set_sale_amount := ( lt_sale_amount * ( -1 ) );
          -- �{�̋��z
          lt_set_pure_amount := ( lt_pure_amount * ( -1 ) );
          -- ����ŋ��z
          lt_set_tax_amount := ( lt_tax_amount * ( -1 ) );
        END IF;
        --====================
        --���׃f�[�^�̕ϐ��}��
        --====================
        gt_line_sales_exp_line_id( gn_line_ck_no )       := ln_sales_exp_line_id;         -- �̔����і���ID
        gt_line_sales_exp_header_id( gn_line_ck_no )     := ln_actual_id;                 -- �̔����уw�b�_ID
        gt_line_dlv_invoice_number( gn_line_ck_no )      := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
        gt_line_dlv_invoice_l_num( gn_line_ck_no )       := lt_lin_line_no_hht;           -- �[�i���הԍ�
        gt_line_sales_class( gn_line_ck_no )             := lt_lin_sale_class;            -- ����敪
        gt_line_red_black_flag( gn_line_ck_no )          := lt_red_black_flag;            -- �ԍ��t���O
        gt_line_item_code( gn_line_ck_no )               := lt_lin_item_code_self;        -- �i�ڃR�[�h
        gt_line_standard_qty( gn_line_ck_no )            := lt_set_replenish_number;      -- �����--
        gt_line_standard_uom_code( gn_line_ck_no )       := lt_stand_unit;                -- ��P��
        gt_line_standard_unit_price( gn_line_ck_no )     := lt_standard_unit_price;       -- ��P��
        gt_line_business_cost( gn_line_ck_no )           := lt_sales_cost;                -- �c�ƌ���
        gt_line_sale_amount( gn_line_ck_no )             := lt_set_sale_amount;           -- ������z--
        gt_line_pure_amount( gn_line_ck_no )             := lt_set_pure_amount;           -- �{�̋��z--
        gt_line_tax_amount( gn_line_ck_no )              := lt_set_tax_amount;            -- ����ŋ��z--
        gt_line_cash_and_card( gn_line_ck_no )           := lt_lin_cash_and_card;         -- �����E�J�[�h���p�z
        gt_line_ship_from_subinv_co( gn_line_ck_no )     := lt_secondary_inventory_name;  -- �o�׌��ۊǏꏊ
        gt_line_delivery_base_code( gn_line_ck_no )      := lt_dlv_base_code;             -- �[�i���_�R�[�h
        gt_line_hot_cold_class( gn_line_ck_no )          := lt_lin_h_and_c;               -- �g���b
        gt_line_column_no( gn_line_ck_no )               := lt_lin_column_no;             -- �R����No
        gt_line_sold_out_class( gn_line_ck_no )          := lt_lin_sold_out_class;        -- ���؋敪
        gt_line_sold_out_time( gn_line_ck_no )           := lt_lin_sold_out_time;         -- ���؎���
        gt_line_to_calculate_fees_flag( gn_line_ck_no )  := cv_line_to_calculate_fees_f_n;-- �萔���v�Z�C���^�t�F�[�X�σt���O
        gt_line_unit_price_mst_flag( gn_line_ck_no )     := cv_line_unit_price_mst_flag_n;-- �P���}�X�^�쐬�σt���O
        gt_line_inv_interface_flag( gn_line_ck_no )      := cv_line_inv_interface_flag_n; -- INV�C���^�t�F�[�X�σt���O
        gt_line_order_invoice_l_num( gn_line_ck_no )     := cv_line_order_invoice_l_num;  -- �������הԍ�(NULL�ݒ�)
        gt_line_not_tax_amount( gn_line_ck_no )          := lt_stand_unit_price_excl;     -- �Ŕ���P��
        gt_line_delivery_pat_class( gn_line_ck_no )      := lv_delivery_type;             -- �[�i�`�ԋ敪
        gt_line_dlv_qty( gn_line_ck_no )                 := lt_set_replenish_number;      -- �[�i����--
        gt_line_dlv_uom_code( gn_line_ck_no )            := lt_stand_unit;                -- �[�i�P��
        gt_dlv_unit_price( gn_line_ck_no )               := lt_standard_unit_price;       -- �[�i�P��
        ln_line_cnt := ln_line_cnt + 1;
        gn_line_ck_no := gn_line_ck_no + 1; 
--
      END LOOP line_loop;
--
      -- ==================
      -- �w�b�_�o�^�p���z�Z�o
      -- ==================
      IF ( lt_consumption_tax_class = cv_non_tax ) THEN           -- ��ې�
--
        -- ������z���v
        lt_sale_amount_sum := lt_total_amount;
        -- �{�̋��z���v
        lt_pure_amount_sum := lt_total_amount;
        -- ����ŋ��z���v
        lt_tax_amount_sum  := NVL( lt_sales_consumption_tax, cn_cons_tkn_zero );
--
      ELSIF ( lt_consumption_tax_class = cv_out_tax ) THEN      -- �O��
--
            -- ������z���v
        lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
        IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
          IF ( lt_tax_odd = cv_amount_up ) THEN
          lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
          -- �؎̂�
          ELSIF ( lt_tax_odd = cv_amount_down ) THEN
            lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
          -- �l�̌ܓ�
          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
            lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
          END IF;
        END IF;
        -- �{�̋��z���v
        lt_pure_amount_sum := lt_total_amount;
        -- ����ŋ��z���v
        lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
--
      ELSIF ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN -- ���Łi�`�[�ېŁj
--
        -- ������z���v
        lt_sale_amount_sum := ( lt_total_amount * ln_tax_data );
        IF ( lt_sale_amount_sum <> TRUNC( lt_sale_amount_sum ) ) THEN
          IF ( lt_tax_odd = cv_amount_up ) THEN
          lt_sale_amount_sum := ( TRUNC( lt_sale_amount_sum ) + 1 );
          -- �؎̂�
          ELSIF ( lt_tax_odd = cv_amount_down ) THEN
            lt_sale_amount_sum := TRUNC( lt_sale_amount_sum );
          -- �l�̌ܓ�
          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
            lt_sale_amount_sum := ROUND( lt_sale_amount_sum );
          END IF;
        END IF;
        -- �{�̋��z���v
        lt_pure_amount_sum := lt_total_amount;
        -- ����ŋ��z���v
        lt_tax_amount_sum  := ( lt_sale_amount_sum - lt_pure_amount_sum );
--
      ELSIF ( lt_consumption_tax_class = cv_ins_bid_tax ) THEN  -- ���Łi�P�����݁j
--  
        -- ������z���v
        lt_sale_amount_sum := lt_total_amount;
        -- �{�̋��z���v
        lt_pure_amount_sum := ( lt_total_amount / ln_tax_data );
        IF ( lt_pure_amount_sum <> TRUNC( lt_pure_amount_sum ) ) THEN
          IF ( lt_tax_odd = cv_amount_up ) THEN
            lt_pure_amount_sum := ( TRUNC( lt_pure_amount_sum ) + 1 );
          -- �؎̂�
          ELSIF ( lt_tax_odd = cv_amount_down ) THEN
            lt_pure_amount_sum := TRUNC( lt_pure_amount_sum );
          -- �l�̌ܓ�
          ELSIF ( lt_tax_odd = cv_amount_nearest ) THEN
            lt_pure_amount_sum:= ROUND( lt_pure_amount_sum );
          END IF;
        END IF;
      -- ����ŋ��z���v
      lt_tax_amount_sum  := ln_all_tax_amount;
--
      END IF;
--
      --��ېňȊO�̂Ƃ�
      IF ( lt_consumption_tax_class <> cv_non_tax ) THEN
        --================================================
        --�w�b�_�������Ŋz�Ɩ��ה������Ŋz��r���f����
        --================================================
        IF ( lt_tax_amount_sum <> ln_all_tax_amount ) THEN
          -- �O�� OR ����(�`�[�ې�)�̎�
          IF ( lt_consumption_tax_class = cv_out_tax ) OR ( lt_consumption_tax_class = cv_ins_slip_tax ) THEN
            gt_line_tax_amount( ln_max_no_data ) := ( ln_max_tax_data + ( lt_tax_amount_sum - ln_all_tax_amount ) );
          END IF;
        END IF;
      END IF;
      -- �ԁE���̋��z���Z
      --���̎�
      IF ( lt_red_black_flag = cv_black_flag) THEN
        -- ������z���v
        lt_set_sale_amount_sum := lt_sale_amount_sum;
        -- �{�̋��z���v
        lt_set_pure_amount_sum := lt_pure_amount_sum;
        -- ����ŋ��z���v
        lt_set_tax_amount_sum := lt_tax_amount_sum;
      -- �Ԃ̎�
      ELSIF ( lt_red_black_flag = cv_red_flag) THEN
        -- ������z���v
        lt_set_sale_amount_sum := ( lt_sale_amount_sum * ( -1 ) );
        -- �{�̋��z���v
        lt_set_pure_amount_sum := ( lt_pure_amount_sum * ( -1 ) );
        -- ����ŋ��z���v
        lt_set_tax_amount_sum := ( lt_tax_amount_sum * ( -1 ) );
      END IF;
--
      --==========================
      -- �w�b�_�f�[�^�̕ϐ��}��
      --==========================
      gt_head_id( gn_header_ck_no )                      := ln_actual_id;                 -- �̔����уw�b�_ID
      gt_head_order_no_ebs( gn_header_ck_no )            := lt_order_no_ebs;              -- ��No.(EBS)(�󒍔ԍ�)
      gt_head_hht_invoice_no( gn_header_ck_no )          := lt_hht_invoice_no;            -- �[�i�`�[�ԍ�
      gt_head_order_no_hht( gn_header_ck_no )            := lt_order_no_hht;              -- ��No(HHT)
      gt_head_digestion_ln_number( gn_header_ck_no )     := lt_digestion_ln_number;       -- �}��(��No(HHT)�}��)
      gt_head_dlv_invoice_class( gn_header_ck_no )       := lt_ins_invoice_type;          -- �[�i�`�[�敪(���o)
      gt_head_cancel_cor_cls( gn_header_ck_no )          := lt_ins_invoice_type;          -- ����E�����敪(���o)
      gt_head_system_class( gn_header_ck_no )            := lt_system_class;              -- �Ƒԋ敪(�Ƒԏ�����)
      gt_head_dlv_date( gn_header_ck_no )                := lt_dlv_date;                  -- �[�i��
      gt_head_inspect_date( gn_header_ck_no )            := lt_inspect_date;              -- ������(����v���)
      gt_head_customer_number( gn_header_ck_no )         := lt_customer_number;           -- �ڋq�R�[�h(�ڋq�y�[�i��z)
      gt_head_tax_include( gn_header_ck_no )             := lt_set_sale_amount_sum;           -- ������z���v--
      gt_head_total_amount( gn_header_ck_no )            := lt_set_pure_amount_sum;           -- �{�̋��z���v--
      gt_head_sales_consump_tax( gn_header_ck_no )       := lt_set_tax_amount_sum;            -- ����ŋ��z���v--
      gt_head_consump_tax_class( gn_header_ck_no )       := lt_consum_type;               -- ����ŋ敪(���o)
      gt_head_tax_code( gn_header_ck_no )                := lt_consum_code;               -- �ŋ��R�[�h(���o)
      gt_head_tax_rate( gn_header_ck_no )                := lt_tax_consum;                -- ����ŗ�(���o)
      gt_head_performance_by_code( gn_header_ck_no )     := lt_performance_by_code;       -- ���ю҃R�[�h(���ьv��҃R�[�h)
      gt_head_sales_base_code( gn_header_ck_no )         := lt_sale_base_code;            -- ���㋒�_�R�[�h(���o)
      gt_head_card_sale_class( gn_header_ck_no )         := lt_card_sale_class;           -- �J�[�h����敪
      gt_head_sales_classification( gn_header_ck_no )    := lt_sales_classification;      -- ���㕪�ދ敪(�`�[�敪)
      gt_head_invoice_class( gn_header_ck_no )           := lt_sales_invoice;             -- ����`�[�敪(�`�[���ރR�[�h)
      gt_head_receiv_base_code( gn_header_ck_no )        := lt_sale_base_code;            -- �������_�R�[�h(���o)
      gt_head_change_out_time_100( gn_header_ck_no )     := lt_change_out_time_100;       -- ��K�؂ꎞ��100�~
      gt_head_change_out_time_10( gn_header_ck_no )      := lt_change_out_time_10;        -- ��K�؂ꎞ��10�~
      gt_head_hht_dlv_input_date( gn_header_ck_no )      := gd_input_date;                -- HHT�[�i���͓���(���^����)
      gt_head_dlv_by_code( gn_header_ck_no )             := lt_dlv_by_code;               -- �[�i�҃R�[�h
      gt_head_business_date( gn_header_ck_no )           := gd_process_date;              -- �o�^�Ɩ����t(���������擾)
      gt_head_order_source_id( gn_header_ck_no )         := cv_head_order_source_id;      -- �󒍃\�[�XID(NULL�ݒ�)
      gt_head_order_invoice_number( gn_header_ck_no )    := cv_head_order_invoice_number; -- �����`�[�ԍ�(NULL�ݒ�)
      gt_head_order_connection_num( gn_header_ck_no )    := cv_head_order_connection_num; -- �󒍊֘A�ԍ�(NULL�ݒ�)
      gt_head_ar_interface_flag( gn_header_ck_no )       := cv_head_ar_interface_flag_n;  -- AR�C���^�t�F�[�X�σt���O('N'�ݒ�)
      gt_head_gl_interface_flag( gn_header_ck_no )       := cv_head_gl_interface_flag_n;  -- GL�C���^�t�F�[�X�σt���O('N'�ݒ�)
      gt_head_dwh_interface_flag( gn_header_ck_no )      := cv_head_dwh_interface_flag_n; -- ���V�X�e���C���^�t�F�[�X�σt���O('N'�ݒ�)
      gt_head_edi_interface_flag( gn_header_ck_no )      := cv_head_edi_interface_flag_n; -- EDI���M�ς݃t���O('N'�ݒ�)
      gt_head_edi_send_date( gn_header_ck_no )           := cv_head_edi_send_date;        -- EDI���M����(NULL�ݒ�)
      gt_head_create_class( gn_header_ck_no )            := cv_head_create_class_vd_d_c;  -- �쐬���敪(�3��ݒ�)
      gt_head_input_class( gn_header_ck_no )             := lt_input_class;               -- ���͋敪
      ln_header_ck_no := ln_header_ck_no + 1;
      gn_header_ck_no := gn_header_ck_no + 1;
--
    END LOOP header_loop;
--
  EXCEPTION
    WHEN no_data_extract THEN
      --�L�[�ҏW�֐�
      xxcos_common_pkg.makeup_key_info(
                                         lv_key_name1, 
                                         lv_key_data1,
                                         lv_key_name2,
                                         lv_key_data2,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         cv_key_name_null,
                                         cv_tkn_null,
                                         gv_tkn2,
                                         lv_errbuf,
                                         lv_retcode,
                                         lv_errmsg);
      --���b�Z�[�W����
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_no_data,
                                             cv_tkn_table, gv_tkn1,
                                             cv_key_data, gv_tkn2 );
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    WHEN delivered_from_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application,cv_msg_delivered_from_err );
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB ( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
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
  END proc_molded;
--
  /**********************************************************************************
   * Procedure Name   : proc_extract
   * Description      : �Ώۃf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE proc_extract(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_extract'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    --===============================
    -- ���[�U��`���[�J���ϐ�
    --===============================
    lv_no_data_msg   VARCHAR2(500);
    lv_err_tab_name  VARCHAR2(500);
--
    -- *** ���[�J���E�J�[�\�� ***
--
  -- VD�R�����ʎ�����w�b�_���
  CURSOR get_header_data_cur
  IS
    SELECT vch.ROWID,                         -- �sID
           vch.order_no_hht,                  -- ��No.(HHT)
           vch.digestion_ln_number,           -- �}��
           vch.order_no_ebs,                  -- ��No.(EBS)
           vch.base_code,                     -- ���_�R�[�h
           vch.performance_by_code,           -- ���ю҃R�[�h
           vch.dlv_by_code,                   -- �[�i�҃R�[�h
           vch.hht_invoice_no,                -- HHT�`�[No. 
           vch.dlv_date,                      -- �[�i��
           vch.inspect_date,                  -- ������
           vch.sales_classification,          -- ���㕪�ދ敪
           vch.sales_invoice,                 -- ����`�[�敪
           vch.card_sale_class,               -- �J�[�h���敪
           vch.dlv_time,                      -- ����
           vch.change_out_time_100,           -- ��K�؂ꎞ��100�~
           vch.change_out_time_10,            -- ��K�؂ꎞ��10�~
           vch.customer_number,               -- �ڋq�R�[�h
           vch.dlv_form,                      -- �[�i�`��
           vch.system_class,                  -- �Ƒԋ敪
           vch.invoice_type,                  -- �`�[�敪
           vch.input_class,                   -- ���͋敪
           vch.consumption_tax_class,         -- ����ŋ敪
           ABS ( vch.total_amount ),          -- ���v���z
           ABS ( vch.sale_discount_amount ),  -- ����l���z
           ABS ( vch.sales_consumption_tax ), -- �������Ŋz
           ABS ( vch.tax_include ),           -- �ō����z
           vch.keep_in_code,                  -- �a����R�[�h
           vch.department_screen_class,       -- �S�ݓX��ʎ��
           vch.digestion_vd_rate_maked_date,  -- ����VD�|���쐬�ϔN����
           vch.red_black_flag,                -- �ԍ��t���O
           vch.cancel_correct_class           -- ����E�����敪
    FROM   xxcos_vd_column_headers vch        -- VD�R�����ʎ�����w�b�_���
    WHERE  vch.order_no_hht IN ( SELECT vcl.order_no_hht
                                 FROM   xxcos_vd_column_lines vcl )
    AND    vch.digestion_ln_number IN ( SELECT vcl.digestion_ln_number
                                        FROM   xxcos_vd_column_lines vcl)
    AND    vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
    AND    vch.input_class   =  cv_input_class_fs_vd_at
    AND    vch.forward_flag  =  cv_forward_flag_no
    ORDER BY vch.order_no_hht,vch.digestion_ln_number
  FOR UPDATE NOWAIT;
--
  -- VD�R�����ʎ�����׏��
  CURSOR get_lines_data_cur
  IS
    SELECT vcl.order_no_hht,                  -- ��No.(HHT)
           vcl.line_no_hht,                   -- �sNo.(HHT)
           vcl.digestion_ln_number,           -- �}��
           vcl.order_no_ebs,                  -- ��No.(EBS)
           vcl.line_number_ebs,               -- ���הԍ�(EBS)
           vcl.item_code_self,                -- �i���R�[�h(����)
           vcl.content,                       -- ����
           vcl.inventory_item_id,             -- �i��ID
           vcl.standard_unit,                 -- ��P��
           vcl.case_number,                   -- �P�[�X��
           vcl.quantity,                      -- ����
           vcl.sale_class,                    -- ����敪
           vcl.wholesale_unit_ploce,          -- ���P��
            vcl.selling_price,                -- ���P��
           vcl.column_no,                     -- �R����No
           vcl.h_and_c,                       -- H/C
           vcl.sold_out_class,                -- ���؋敪
           vcl.sold_out_time,                 -- ���؎���
           ABS ( vcl.replenish_number ),      -- ��[��
           vcl.cash_and_card                  -- �����E�J�[�h���p�z
    FROM   xxcos_vd_column_lines vcl          -- VD�R�����ʎ�����׏��
    WHERE  vcl.order_no_hht IN ( SELECT vch.order_no_hht
                                FROM   xxcos_vd_column_headers vch
                                WHERE  vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
                                AND    vch.input_class   =  cv_input_class_fs_vd_at
                                AND    vch.forward_flag  =  cv_forward_flag_no )
    AND    vcl.digestion_ln_number IN ( SELECT vch.digestion_ln_number
                                       FROM   xxcos_vd_column_headers vch
                                       WHERE  vch.system_class  IN ( cv_system_class_fs_vd, cv_system_class_fs_vd_s )
                                       AND    vch.input_class   =  cv_input_class_fs_vd_at
                                       AND    vch.forward_flag  =  cv_forward_flag_no )
    ORDER BY vcL.order_no_hht,vcL.digestion_ln_number,vcl.line_no_hht
  FOR UPDATE NOWAIT;
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
    --==============================================================
    -- VD�R�����ʎ�����w�b�_���擾
    --==============================================================
    BEGIN
      -- ����͉�ʓo�^�f�[�^�擾
      -- �J�[�\��OPEN
      OPEN  get_header_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_header_data_cur BULK COLLECT INTO gt_vd_c_headers_data;
      -- ���o�����Z�b�g
      gn_target_cnt := get_header_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_header_data_cur;
--
--
    EXCEPTION
      WHEN lock_err_expt THEN
        IF( get_header_data_cur%ISOPEN ) THEN
          CLOSE get_header_data_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_head );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_tab, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF( get_header_data_cur%ISOPEN ) THEN
          CLOSE get_header_data_cur;
        END IF;
        lv_err_tab_name := xxccp_common_pkg.get_msg ( cv_application, cv_msg_tab_name_colum_head );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err,
                                             cv_tkn_tab, lv_err_tab_name );
        RAISE extract_err_expt;
    END;
    
--
    --==============================================================
    -- VD�R�����ʎ�����׏��擾
    --==============================================================
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_lines_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_lines_data_cur BULK COLLECT INTO gt_vd_c_lines_data;
      -- ���o�����Z�b�g
      gn_target_lines_cnt := get_lines_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_lines_data_cur;
--
    EXCEPTION
      WHEN lock_err_expt THEN

        IF( get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_line );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_loc_err, cv_tkn_tab, gv_tkn1 );
        RAISE;
      WHEN OTHERS THEN
        IF(get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
        lv_err_tab_name := xxccp_common_pkg.get_msg( cv_application, cv_msg_tab_name_colum_line );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_extract_err,
                                             cv_tkn_tab, lv_err_tab_name);
        RAISE extract_err_expt;
    END;
--
    -- �Ώƃf�[�^�����݂��Ȃ��ꍇ
    IF ( ov_retcode <> cv_status_error ) AND ( gn_target_cnt = 0 ) OR ( gn_target_lines_cnt = 0 )THEN
      lv_no_data_msg := xxccp_common_pkg.get_msg ( cv_application, cv_msg_target_no_data );
      ov_errmsg := lv_no_data_msg;
      ov_errbuf := lv_no_data_msg;
--      lv_errbuf := lv_no_data_msg;
    END IF;
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN lock_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- ���o�G���[
    WHEN extract_err_expt THEN
--      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--##############################################################################################
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( get_header_data_cur %ISOPEN ) THEN
          CLOSE get_header_data_cur;
      END IF;
      IF ( get_lines_data_cur%ISOPEN ) THEN
        CLOSE get_lines_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_header_data_cur %ISOPEN ) THEN
          CLOSE get_header_data_cur;
      END IF;
      IF ( get_lines_data_cur%ISOPEN ) THEN
        CLOSE get_lines_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_extract;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    lv_max_date      VARCHAR2(50);      -- MAX���t
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOI:�݌ɑg�D�R�[�h)
    --==============================================================
    gv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
    --�v���t�@�C���G���[
    IF (gv_orga_code IS NULL) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ���ʊ֐����݌ɑg�DID�擾���̌Ăяo��
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( gv_orga_code );
--
    -- �݌ɑg�DID�擾�G���[�̏ꍇ
    IF ( gn_orga_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �Ɩ��������擾
    --==============================================================
     gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_process_date := TRUNC( gd_process_date );
--
    --==================================
    -- �v���t�@�C���̎擾(XXCOS:MAX���t)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_short_day );
    END IF;
--
    --====================================
    -- �v���t�@�C���̎擾(��v����ID)
    --====================================
    gv_bks_id := FND_PROFILE.VALUE( cv_prf_bks_id ); 
--
    IF ( gv_bks_id IS NULL) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_gl_books);
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
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
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_lines_cnt := 0;
    gn_line_cnt   := 0;
--
    -- ===============================
    -- proc_init(��������)
    -- ===============================
    proc_init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    -- ================================
    -- proc_extract(�Ώۃf�[�^���o)
    -- ================================
    proc_extract(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    -- �Ώƃf�[�^�����݂���ꍇ
    IF (gn_target_cnt <> 0) AND (gn_target_lines_cnt <> 0) THEN
        -- ================================
        -- proc_molded(VD�[�i�f�[�^�쐬���^����)
        -- ================================
        proc_molded(
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--      END IF;
--
      -- ================================
      -- proc_data_insert_head(�̔����уf�[�^�o�^����(�w�b�_))
      -- ================================
      proc_data_insert_head(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ================================
      -- proc_data_insert_line(�̔����уf�[�^�o�^����(����))
      -- ================================
      proc_data_insert_line(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
      -- ================================
      -- proc_data_update(�擾���e�[�u���t���O�X�V)
      -- ================================
      proc_data_update(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSIF ( lv_errbuf <> cv_status_error) 
      AND ( gn_target_cnt = 0 ) 
      AND ( gn_target_lines_cnt = 0 )THEN
      ov_retcode := cv_status_warn;
--      ov_errbuf  := lv_errbuf;
      ov_errmsg  := lv_errbuf;
    END IF;
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o�́F�u�x���v���umain�Ń��b�Z�[�W���o�́v����v���̂���ꍇ
    IF (lv_retcode <> cv_status_normal) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => ''
        );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
        ,buff   => ''
        );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      IF ( lv_retcode <> cv_status_warn ) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
          ,buff   => ''
          );
      END IF;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;

    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�w�b�_�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_he_target
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���בΏی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_li_target
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_lines_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�w�b�_���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_he_update
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���א��������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_count_li_update
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
       which  => FND_FILE.OUTPUT
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
END XXCOS001A03C;
/