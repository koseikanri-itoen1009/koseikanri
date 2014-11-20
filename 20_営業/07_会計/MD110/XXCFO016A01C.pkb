CREATE OR REPLACE PACKAGE BODY XXCFO016A01C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO016A01C(body)
 * Description     : �W���������o�͏���
 * MD.050          : MD050_CFO_016_A01_�W���������o�͏���
 * MD.070          : MD050_CFO_016_A01_�W���������o�͏���
 * Version         : 1.4
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init            P          ���̓p�����[�^�l���O�o�͏���                 (A-1)
 *  get_profile_lookup_val P   ��������                                     (A-2)
 *  get_attache_info P         �Y�t���擾����                             (A-4)
 *  edit_attache_info P        �Y�t���ҏW����                             (A-5)
 *  get_customer_info P        �ڋq���擾����                             (A-6)
 *  get_un_info     P          �@����擾����                             (A-7)
 *  insert_rep_standard_po P   ���[�N�e�[�u���f�[�^�o�^                     (A-8)
 *  insert_po_status_mng P     �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^             (A-9)
 *  insert_csv_outs_temp P     0���o�̓��b�Z�[�W                            (A-10)
 *  out_put_file    P          ���[�N�e�[�u���f�[�^�o�^�i����0���p�j        (A-11)
 *  delete_po_status_mng P     SVF�N������                                  (A-12)
 *  delete_rep_standard_po P   ���[�N�e�[�u���f�[�^�폜                     (A-13)
 *  delete_po_status_mng P     �X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜             (A-14)
 *  submain         P          ���C�������v���V�[�W��
 *  main            P          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-20    1.0  SCS �R�� �D   ����쐬
 *  2009-02-06    1.1  SCS ���c�E�l  [��QCFO_001]���Ə��A�h�I���}�X�^�̗L�����t�`�F�b�N��ǉ�
 *  2009-02-09    1.2  SCS ���c�E�l  [��QCFO_002]�o�͌����Ή�
 *  2009-03-06    1.3  SCS ���c�E�l  SVF�N�������ύX�Ή�
 *  2009-03-16    1.4  SCS ���c�E�l  [��QT1_0050]�G���[���O�Ή�
 ************************************************************************/
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
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
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
  --===============================================================
  -- �O���[�o���萔
  --===============================================================
  gv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCFO016A01C';      -- �p�b�P�[�W��
  gv_msg_kbn_cfo           CONSTANT VARCHAR2(5)   := 'XXCFO';
  gv_flag_y                CONSTANT VARCHAR2(1)   := 'Y';                 -- �t���O�iY�j
  gv_flag_n                CONSTANT VARCHAR2(1)   := 'N';                 -- �t���O�iN�j
  gv_approved              CONSTANT VARCHAR2(10)  := 'APPROVED';          -- ���F��
  gv_standard              CONSTANT VARCHAR2(10)  := 'STANDARD';          -- �W������
  gv_reissue_flag_0        CONSTANT VARCHAR2(1)   := '0';                 -- �V�K
  gv_reissue_flag_1        CONSTANT VARCHAR2(1)   := '1';                 -- �Ĕ��s
  gv_lookup_code_100       CONSTANT VARCHAR2(3)   := '100';               -- �ݒu��_�ڋq�R�[�h=
  gv_lookup_code_110       CONSTANT VARCHAR2(3)   := '110';               -- �Љ���=
  gv_judge_code_10         CONSTANT VARCHAR2(2)   := '10';                -- ���̋@
  gv_entity_name           CONSTANT VARCHAR2(10)  := 'REQ_LINES';         -- �w���˗�����
  gv_file_type_log         CONSTANT VARCHAR2(10)  := 'LOG';               -- ���O�o��
  gv_format_date_ymd       CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- ���t�t�H�[�}�b�g�i�N�����j
  gv_format_date_ymdhms    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
                                                                          -- ���t�t�H�[�}�b�g�i�N���������b�j
  gt_lookup_code_000A00002 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00002';
                                                                                -- �u�����쐬��From�v
  gt_lookup_code_000A00003 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00003';
                                                                                -- �u�����쐬��To�v
  gt_lookup_code_000A00004 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00004';
                                                                                -- �u�������F��From�v
  gt_lookup_code_000A00005 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00005';
                                                                                -- �u�������F��To�v
  gt_lookup_code_016A01001 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO016A01001';
                                                                                -- �uSVF���[���ʊ֐�(0���o�̓��b�Z�[�W)�v
  gt_lookup_code_016A01002 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO016A01002';
                                                                                -- �u'SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)'�v
  gt_lookup_code_000A00006 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00006';
                                                                                -- �u�������v
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_cfo_00004   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; -- �x���G���[���b�Z�[�W
  gv_msg_cfo_00008   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00008'; -- ����0���p���b�Z�[�W
  gv_msg_cfo_00009   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00009'; -- ���ʊ֐��G���[���b�Z�[�W
  gv_msg_cfo_00010   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00010'; -- �Y�t���擾�G���[���b�Z�[�W
  gv_msg_cfo_00011   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00011'; -- �ڋq���擾�G���[���b�Z�[�W
  gv_msg_cfo_00012   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00012'; -- �@����擾�G���[���b�Z�[�W
  gv_msg_cfo_00013   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00013'; -- �Y�t��񕶎��񌟍��G���[���b�Z�[�W
  gv_msg_cfo_00019   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; -- �e�[�u�����b�N�G���[���b�Z�[�W
  gv_msg_cfo_00025   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; -- �f�[�^�폜�G���[���b�Z�[�W
  gv_msg_cfo_00033   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00033'; -- �R���J�����g�p�����[�^�l�召�`�F�b�N�G���[���b�Z�[�W
  gv_msg_cfo_00035   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00035'; -- �f�[�^�쐬�G���[���b�Z�[�W�G���[���b�Z�[�W
  gv_msg_cfo_00036   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00036'; -- �V�X�e���G���[���b�Z�[�W
--
  -- �g�[�N��
  gv_tkn_param_name_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- �召�`�F�b�NFrom �����p
  gv_tkn_param_name_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- �召�`�F�b�NTo �����p
  gv_tkn_param_val_from  CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- �召�`�F�b�NFrom �l�p
  gv_tkn_param_val_to    CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- �召�`�F�b�NTo �l�p
  gv_tkn_table           CONSTANT VARCHAR2(15) := 'TABLE';            -- �e�[�u����
  gv_tkn_pk1_value       CONSTANT VARCHAR2(15) := 'PK1_VALUE';        -- �w���˗�����ID
  gv_tkn_requisition_no  CONSTANT VARCHAR2(15) := 'REQUISITION_NO';   -- �w���˗��ԍ�
  gv_tkn_po_num          CONSTANT VARCHAR2(15) := 'PO_NUM';           -- �����ԍ�
  gv_tkn_search_string   CONSTANT VARCHAR2(15) := 'SEARCH_STRING';    -- �����Ώە�����
  gv_tkn_account_number  CONSTANT VARCHAR2(15) := 'ACCOUNT_NUMBER';   -- �ڋq�ԍ�
  gv_tkn_un_number_id    CONSTANT VARCHAR2(15) := 'UN_NUMBER_ID';     -- �@��ԍ�ID
  gv_tkn_errmsg          CONSTANT VARCHAR2(15) := 'ERRMSG';           -- SQLERRM�Ή�
  gv_tkn_func_name       CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- ������
--
  --�v���t�@�C��
  gv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  gv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
  gv_conc_request_id CONSTANT VARCHAR2(30) := 'CONC_REQUEST_ID';  -- �v��ID
--
  gv_lookup_type     CONSTANT VARCHAR2(100) := 'XXCFO1_SEARCH_LONG_TEXT';  -- ������������������
--
  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gn_set_of_bks_id             NUMBER;                                     -- ��v����ID
  gn_org_id                    NUMBER;                                     -- �g�DID
  gn_conc_request_id           NUMBER;                                     -- �v��ID
  gt_account_number            hz_cust_accounts.account_number%TYPE;       -- �ڋq�R�[�h
  gv_referral_comp             VARCHAR2(2000);                             -- �Љ���
  gt_long_text                 fnd_documents_long_text.long_text%TYPE;     -- ��������
  gt_party_name                hz_parties.party_name%TYPE;                 -- �ڋq��
  gt_un_number                 po_un_numbers_tl.un_number%TYPE;            -- �@��ԍ�
  gn_po_num_in_count           NUMBER;                                     -- �X�e�[�^�X�Ǘ��e�[�u���ւ̔����ԍ��o�^����
  gn_rep_standard_po_cnt       NUMBER;                                     -- �W���������쐬�p���[���[�N�e�[�u���o�^����
  gt_no_data_msg               xxcfo_rep_standard_po.data_empty_message%TYPE;
                                                                           -- 0�����b�Z�[�W

--
  --===============================================================
  -- �O���[�o���e�[�u���^�C�v
  --===============================================================
  TYPE g_po_num_ttype           IS TABLE OF xxcfo_po_status_mng.po_num%TYPE        INDEX BY PLS_INTEGER;
  TYPE g_org_id_ttype           IS TABLE OF xxcfo_po_status_mng.org_id%TYPE        INDEX BY PLS_INTEGER;
  TYPE g_search_long_text_ttype IS TABLE OF fnd_lookup_values.meaning%TYPE         INDEX BY PLS_INTEGER;
--
  --===============================================================
  -- �O���[�o���e�[�u��
  --===============================================================
  gt_po_num                 g_po_num_ttype;
  gt_org_id                 g_org_id_ttype;
  gt_search_long_text       g_search_long_text_ttype;     -- ����������������
--
  --===============================================================
  -- �O���[�o���J�[�\��
  --===============================================================
--
  CURSOR po_data_cur(
    iv_po_dept_code            IN VARCHAR2       -- �����쐬����
   ,in_po_agent_code           IN NUMBER         -- �����쐬��
   ,iv_vender_code             IN VARCHAR2       -- �d����
   ,iv_po_num                  IN VARCHAR2       -- �����ԍ�
   ,id_po_creation_date_from   IN DATE           -- �����쐬��From
   ,id_po_creation_date_to     IN DATE           -- �����쐬��To
   ,id_po_approved_date_from   IN DATE           -- �������F��From
   ,id_po_approved_date_to     IN DATE           -- �������F��To
   ,iv_reissue_flag            IN VARCHAR2       -- �Ĕ��s�t���O
  )
  IS
    SELECT pha.segment1                           po_num                     -- �����ԍ�
          ,pha.revision_num                       revision_num               -- �����ԍ�
          ,pla.vendor_product_num                 vendor_product_num         -- �d����i��
          ,pla.unit_meas_lookup_code              unit_meas_lookup_code      -- �P��
          ,pla.unit_price                         unit_price                 -- �P��
          ,pda.quantity_ordered                   quantity_ordered           -- ��������
          ,pla.unit_price * pda.quantity_ordered  amount                     -- ���z
          ,plla.promised_date                     promised_date              -- �[��
          ,mcb.attribute1                         attache_judge_code         -- �Y�t��񔻒�R�[�h
          ,d_xla.location_name                    po_location_name           -- �����S����_����������
          ,d_xla.zip                              po_zip                     -- �����S����_�X�֔ԍ�
          ,d_xla.address_line1                    po_address_line1           -- �����S����_�Z��
          ,d_xla.phone                            po_phone                   -- �����S����_�d�b�ԍ�
          ,d_xla.fax                              po_fax                     -- �����S����_FAX
          ,l_xla.location_short_name              location_short_name        -- �[���掖�Ə�
          ,l_xla.division_code                    deliver_division_code      -- �[���掖�{���R�[�h
          ,pvsa.phone                             vendor_phone               -- �d����d�b�ԍ�
          ,pvsa.fax                               vendor_fax                 -- �d����FAX�ԍ�
          ,pvsa.area_code                         area_code                  -- �d����d�b�G���A�R�[�h
          ,pvsa.fax_area_code                     fax_area_code              -- �d����FAX�G���A�R�[�h
          ,pvsa.pay_on_code                       pay_on_code                -- ���Ȑ���-�x����
          ,pvsa.attribute1                        vendor_name                -- �d���於
          ,pr.requisition_num                     requisition_num            -- �w���˗��ԍ�
          ,pr.requisition_line_id                 requisition_line_id        -- �w���˗�����ID
          ,pr.un_number_id                        un_number_id               -- �@��ID
          ,pr.location_short_name                 apply_location_short_name  -- �\�����_
          ,pr.division_code                       apply_division_code        -- �\�����_�{���R�[�h
          ,pha.org_id                             org_id                     -- �g�DID
      FROM po_headers_all          pha,                  -- �����w�b�_�e�[�u��
           po_lines_all            pla,                  -- �������׃e�[�u��
           po_line_locations_all   plla,                 -- �����[�����׃e�[�u��
           po_distributions_all    pda,                  -- �����������׃e�[�u��
           po_agents               pa,                   -- �w���S���}�X�^
           per_all_people_f        papf1,                -- �]�ƈ��}�X�^
           mtl_categories_b        mcb,                  -- �i�ڃJ�e�S���e�[�u��
           hr_locations            d_hl,                 -- ���Ə��}�X�^�i��������p�j
           xxcmn_locations_all     d_xla,                -- ���Ə��A�h�I���}�X�^�i��������p�j
           hr_locations            l_hl,                 -- ���Ə��}�X�^�i�[���掖�Ə��p�j
           xxcmn_locations_all     l_xla,                -- ���Ə��A�h�I���}�X�^�i�[���掖�Ə��p�j
           po_vendors              pv,                   -- �d����}�X�^
           po_vendor_sites_all     pvsa,                 -- �d����T�C�g�}�X�^
           (SELECT prha.segment1                requisition_num                     -- �w���˗��ԍ�
                  ,prha.org_id                  org_id                              -- �g�DID
                  ,prla.requisition_line_id     requisition_line_id                 -- �w���˗�����ID
                  ,prla.line_location_id        line_location_id                    -- �[������ID
                  ,prla.un_number_id            un_number_id                        -- �@��ID
                  ,prda.distribution_id         distribution_id                     -- �w���˗���������ID
                  ,xla.location_short_name      location_short_name                 -- �\�����_
                  ,xla.division_code            division_code                       -- �\�����_�{���R�[�h
              FROM po_requisition_headers_all   prha,          -- �w���˗��w�b�_�e�[�u��
                   po_requisition_lines_all     prla,          -- �w���˗����׃e�[�u��
                   po_req_distributions_all     prda,          -- �w���˗��������׃e�[�u��
                   per_all_people_f             papf2,         -- �]�ƈ��}�X�^
                   hr_locations                 hl,            -- ���Ə��}�X�^
                   xxcmn_locations_all          xla            -- ���Ə��A�h�I���}�X�^
             WHERE prha.org_id                  = gn_org_id
               AND prha.requisition_header_id   = prla.requisition_header_id
               AND prha.org_id                  = prla.org_id
               AND prla.requisition_line_id     = prda.requisition_line_id
               AND prla.org_id                  = prda.org_id
               AND prda.set_of_books_id         = gn_set_of_bks_id
               AND papf2.current_employee_flag  = gv_flag_y
               AND papf2.person_id              = prla.to_person_id
               AND papf2.attribute28            = hl.location_code
               AND hl.location_id               = xla.location_id
               AND TRUNC( SYSDATE ) BETWEEN TRUNC( xla.start_date_active )
                                        AND TRUNC( NVL( xla.end_date_active, SYSDATE ) )
               AND (   prla.cancel_flag = gv_flag_n
                    OR prla.cancel_flag IS NULL
                   )
           ) pr   -- �����˗��擾
     WHERE pha.org_id               = gn_org_id
       AND pha.authorization_status = gv_approved
       AND pha.type_lookup_code     = gv_standard
       AND (   pha.cancel_flag = gv_flag_n
            OR pha.cancel_flag IS NULL
           )
       AND pha.po_header_id         = pla.po_header_id
       AND pha.org_id               = pla.org_id
       AND pla.po_header_id         = plla.po_header_id
       AND pla.po_line_id           = plla.po_line_id
       AND pla.org_id               = plla.org_id
       AND (   plla.cancel_flag = gv_flag_n
            OR plla.cancel_flag IS NULL
           )
       AND plla.ship_to_location_id    =  l_hl.location_id
       AND plla.po_header_id           =  pda.po_header_id
       AND plla.po_line_id             =  pda.po_line_id
       AND plla.line_location_id       =  pda.line_location_id
       AND plla.org_id                 =  pda.org_id
       AND pda.org_id                  =  gn_org_id
       AND pda.line_location_id        =  pr.line_location_id(+)
       AND pda.req_distribution_id     =  pr.distribution_id(+)
       AND pda.org_id                  =  pr.org_id(+)
       AND l_hl.location_id            =  l_xla.location_id
       AND TRUNC( SYSDATE ) BETWEEN TRUNC( l_xla.start_date_active )
                                AND TRUNC( NVL( l_xla.end_date_active, SYSDATE ) )
       AND pha.agent_id                =  pa.agent_id
       AND pa.agent_id                 =  papf1.person_id
       AND papf1.current_employee_flag =  gv_flag_y
       AND pla.category_id             =  mcb.category_id
       AND papf1.attribute28           =  d_hl.location_code
       AND d_hl.location_id            =  d_xla.location_id
       AND TRUNC( SYSDATE ) BETWEEN TRUNC( d_xla.start_date_active )
                                AND TRUNC( NVL( d_xla.end_date_active, SYSDATE ) )
       AND pv.set_of_books_id          =  gn_set_of_bks_id
       AND pv.vendor_id                =  pvsa.vendor_id
       AND pvsa.org_id                 =  pha.org_id
       AND pvsa.vendor_site_id         =  pha.vendor_site_id
       AND pvsa.vendor_id              =  pha.vendor_id
       AND pvsa.purchasing_site_flag   =  gv_flag_y
       AND papf1.attribute28           =  iv_po_dept_code
       AND papf1.person_id             =  NVL(in_po_agent_code, papf1.person_id)
       AND pv.segment1                 =  NVL(iv_vender_code, pv.segment1)
       AND pha.segment1                =  NVL(iv_po_num, pha.segment1)
       AND pha.creation_date           >= NVL(TRUNC(id_po_creation_date_from), pha.creation_date)
       AND pha.creation_date           <  NVL(TRUNC(id_po_creation_date_to),   pha.creation_date) + 1
       AND pha.approved_date           >= NVL(TRUNC(id_po_approved_date_from), pha.approved_date)
       AND pha.approved_date           <  NVL(TRUNC(id_po_approved_date_to),   pha.approved_date) + 1
       AND (
            (    iv_reissue_flag = gv_reissue_flag_0
             AND NOT EXISTS ( SELECT 'X'
                                FROM xxcfo_po_status_mng    xpsm      -- �������o�̓X�e�[�^�X�Ǘ��e�[�u��
                               WHERE pha.segment1 = xpsm.po_num
                                 AND pha.org_id   = xpsm.org_id
                            )
            )
           OR
            (    iv_reissue_flag = gv_reissue_flag_1
             AND EXISTS ( SELECT 'X'
                            FROM xxcfo_po_status_mng xpsm
                           WHERE pha.segment1 = xpsm.po_num
                             AND pha.org_id   = xpsm.org_id
                        )
            )
           )
     ORDER BY pha.segment1 ASC
             ,pha.org_id   ASC
     FOR UPDATE OF pha.segment1
                  ,pla.line_num
                  ,plla.shipment_num
                  ,pda.quantity_ordered
                  ,pa.agent_id
                  ,papf1.full_name
                  ,mcb.attribute1
                  ,d_hl.location_id
                  ,d_xla.location_name
                  ,l_hl.location_code
                  ,l_xla.address_line1
                  ,pv.vendor_id
                  ,pvsa.phone
                  NOWAIT;
--
  --===============================================================
  -- �O���[�o�����R�[�h�^�ϐ�
  --===============================================================
  g_xxcfo_po_data_rec    po_data_cur%ROWTYPE;
--
  --===============================================================
  -- �O���[�o����O
  --===============================================================
  lock_expt             EXCEPTION;      -- ���b�N(�r�W�[)�G���[
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ���̓p�����[�^�l���O�o�͏���(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_po_dept_code            IN         VARCHAR2,     --   �����쐬����
    iv_po_agent_code           IN         VARCHAR2,     --   �����쐬��
    iv_vender_code             IN         VARCHAR2,     --   �d����
    iv_po_num                  IN         VARCHAR2,     --   �����ԍ�
    iv_po_creation_date_from   IN         VARCHAR2,     --   �����쐬��From
    iv_po_creation_date_to     IN         VARCHAR2,     --   �����쐬��To
    iv_po_approved_date_from   IN         VARCHAR2,     --   �������F��From
    iv_po_approved_date_to     IN         VARCHAR2,     --   �������F��To
    iv_reissue_flag            IN         VARCHAR2,     --   �Ĕ��s�t���O
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    xxcfr_common_pkg.put_log_param(
       iv_which        => gv_file_type_log             -- ���O�o��
      ,iv_conc_param1  => iv_po_dept_code              -- �����쐬����
      ,iv_conc_param2  => iv_po_agent_code             -- �����쐬��
      ,iv_conc_param3  => iv_vender_code               -- �d����
      ,iv_conc_param4  => iv_po_num                    -- �����ԍ�
      ,iv_conc_param5  => iv_po_creation_date_from     -- �����쐬��From
      ,iv_conc_param6  => iv_po_creation_date_to       -- �����쐬��To
      ,iv_conc_param7  => iv_po_approved_date_from     -- �������F��From
      ,iv_conc_param8  => iv_po_approved_date_to       -- �������F��To
      ,iv_conc_param9  => iv_reissue_flag              -- �Ĕ��s�t���O
      ,ov_errbuf       => lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐��G���[������ ***
    WHEN global_api_expt THEN
      ov_errbuf := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
      ov_errmsg := lv_errmsg;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_lookup_val
   * Description      : ��������(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_lookup_val(
    iv_po_creation_date_from IN         VARCHAR2,   -- �����쐬��From
    iv_po_creation_date_to   IN         VARCHAR2,   -- �����쐬��To
    iv_po_approved_date_from IN         VARCHAR2,   -- �������F��From
    iv_po_approved_date_to   IN         VARCHAR2,   -- �������F��To
    ov_errbuf                OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_lookup_val'; -- �v���O������
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
    ln_cnt  NUMBER :=0;     -- �J�[�\�������擾�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ������������������擾
    CURSOR long_text_cur IS
    SELECT flv.meaning            meaning
      FROM fnd_lookup_values      flv
     WHERE flv.lookup_type            = gv_lookup_type
       AND flv.language               = USERENV('LANG')
       AND flv.enabled_flag           = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
            OR flv.end_date_active   >= TRUNC( SYSDATE ))
       AND flv.lookup_code           IN (gv_lookup_code_100, gv_lookup_code_110)
     ORDER BY flv.lookup_code ASC;
    -- *** ���[�J���E���R�[�h ***
--
  l_xxcfo_long_text_rec    long_text_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(gv_set_of_bks_id));
--
    -- �v���t�@�C������g�DID�擾
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_org_id));
--
    -- �v���t�@�C������v��ID�擾
    gn_conc_request_id := TO_NUMBER(FND_PROFILE.VALUE(gv_conc_request_id));
--
    -- �����쐬���`�F�b�N
    IF (  iv_po_creation_date_from IS NOT NULL
      AND iv_po_creation_date_to IS NOT NULL
      AND iv_po_creation_date_from > iv_po_creation_date_to )
    THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo               -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00033             -- �召�`�F�b�N�G���[
                                                     ,gv_tkn_param_name_from       -- �g�[�N��'PARAM_NAME_FROM'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00002
                                                      )                            -- �u�����쐬��From�v
                                                     ,gv_tkn_param_name_to         -- �g�[�N��'PARAM_NAME_TO'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00003
                                                      )                            -- �u�����쐬��To�v
                                                     ,gv_tkn_param_val_from        -- �g�[�N��'PARAM_VAL_FROM'
                                                     ,iv_po_creation_date_from     -- �����쐬��From
                                                     ,gv_tkn_param_val_to          -- �g�[�N��'PARAM_VAL_TO'
                                                     ,iv_po_creation_date_to       -- �����쐬��To
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    -- �������F���`�F�b�N
    IF (  iv_po_approved_date_from IS NOT NULL
      AND iv_po_approved_date_to IS NOT NULL
      AND iv_po_approved_date_from > iv_po_approved_date_to )
    THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo               -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00033             -- �召�`�F�b�N�G���[
                                                     ,gv_tkn_param_name_from       -- �g�[�N��'PARAM_NAME_FROM'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00004
                                                      )                            -- �u�������F��From�v
                                                     ,gv_tkn_param_name_to         -- �g�[�N��'PARAM_NAME_TO'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00005
                                                      )                            -- �u�������F��To�v
                                                     ,gv_tkn_param_val_from        -- �g�[�N��'PARAM_VAL_FROM'
                                                     ,iv_po_approved_date_from     -- �������F��From
                                                     ,gv_tkn_param_val_to          -- �g�[�N��'PARAM_VAL_TO'
                                                     ,iv_po_approved_date_to       -- �������F��To
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    -- �����������������̎擾
    -- �J�[�\���I�[�v��
    OPEN long_text_cur;
    LOOP
      FETCH long_text_cur INTO l_xxcfo_long_text_rec;
      EXIT WHEN long_text_cur%NOTFOUND;
--
      ln_cnt := ln_cnt + 1;
      gt_search_long_text(ln_cnt) := l_xxcfo_long_text_rec.meaning;
--
    END LOOP;
    -- �J�[�\���N���[�Y
    IF po_data_cur%ISOPEN THEN
      CLOSE long_text_cur;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE long_text_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE long_text_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE long_text_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile_lookup_val;
--
  /**********************************************************************************
   * Procedure Name   : get_attache_info
   * Description      : �Y�t���擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_attache_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_attache_info'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT fdlt.long_text          long_text   -- ��������
      INTO gt_long_text
      FROM fnd_document_entities        fde,   -- �Y�t���̃e�[�u��
           fnd_attached_documents       fad,   -- �Y�t�����֘A�e�[�u��
           fnd_documents_tl             fdt,   -- ����ʓY�t�e�[�u��
           fnd_documents_long_text      fdlt   -- �Y�t���������e�[�u��
     WHERE fde.entity_name  = gv_entity_name
       AND fde.entity_name  = fad.entity_name
       AND fad.document_id  = fdt.document_id
       AND fdt.language     = USERENV('LANG')
       AND fdt.media_id     = fdlt.media_id
       AND fad.pk1_value    = TO_CHAR(g_xxcfo_po_data_rec.requisition_line_id);
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg  := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                          -- 'XXCFO'
                                                      ,gv_msg_cfo_00010                        -- �Y�t���擾�G���[
                                                      ,gv_tkn_pk1_value                        -- �g�[�N��'PK1_VALUE'
                                                      ,g_xxcfo_po_data_rec.requisition_line_id -- �w���˗�����ID
                                                      ,gv_tkn_requisition_no                   -- �g�[�N��'REQUISITION_NO'
                                                      ,g_xxcfo_po_data_rec.requisition_num     -- �w���˗��ԍ�
                                                      ,gv_tkn_po_num                           -- �g�[�N��'PO_NUM'
                                                      ,g_xxcfo_po_data_rec.po_num              -- �����ԍ�
                                                     )
                            ,1
                            ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_attache_info;
--
  /**********************************************************************************
   * Procedure Name   : edit_attache_info
   * Description      : �Y�t���ҏW���� (A-5)
   ***********************************************************************************/
  PROCEDURE edit_attache_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_attache_info'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Y�t��񍀖ڒl�����擾
    gt_account_number := xxcfo_common_pkg.get_special_info_item(
                                            gt_long_text                   -- ��������
                                           ,gt_search_long_text(1));       -- �����Ώە�����i�ݒu��_�ڋq�R�[�h=�j
--
    IF (gt_account_number IS NULL) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00013                    -- �Y�t��񕶎��񌟍��G���[
                                                     ,gv_tkn_search_string                -- �g�[�N��'SEARCH_STRING'
                                                     ,gt_search_long_text(1)              -- �����Ώە�����
                                                     ,gv_tkn_requisition_no               -- �g�[�N��'REQUISITION_NO'
                                                     ,g_xxcfo_po_data_rec.requisition_num -- �w���˗����הԍ�
                                                     ,gv_tkn_po_num                       -- �g�[�N��'PO_NUM'
                                                     ,g_xxcfo_po_data_rec.po_num          -- �����ԍ�
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    gv_referral_comp := xxcfo_common_pkg.get_special_info_item(
                                            gt_long_text                   -- ��������
                                           ,gt_search_long_text(2));       -- �����Ώە�����i�Љ���=�j
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_attache_info;
--
  /**********************************************************************************
   * Procedure Name   : get_customer_info
   * Description      : �ڋq���擾���� (A-6)
   ***********************************************************************************/
  PROCEDURE get_customer_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_customer_info'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT hp.party_name      party_name        -- �ڋq��
      INTO gt_party_name
      FROM hz_parties           hp,     -- �p�[�e�B�}�X�^
           hz_cust_accounts     hca     -- �ڋq�}�X�^
     WHERE hp.party_id        = hca.party_id
       AND hca.account_number = gt_account_number;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- 'XXCFO'
                                                     ,gv_msg_cfo_00011                    -- �ڋq���擾�G���[
                                                     ,gv_tkn_account_number               -- �g�[�N��'ACCOUNT_NUMBER'
                                                     ,gt_account_number                   -- �ڋq�ԍ�
                                                     ,gv_tkn_requisition_no               -- �g�[�N��'REQUISITION_NO'
                                                     ,g_xxcfo_po_data_rec.requisition_num -- �w���˗��ԍ�
                                                     ,gv_tkn_po_num                       -- �g�[�N��'PO_NUM'
                                                     ,g_xxcfo_po_data_rec.po_num          -- �����ԍ�
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_customer_info;
--
  /**********************************************************************************
   * Procedure Name   : get_un_info
   * Description      : �@����擾���� (A-7)
   ***********************************************************************************/
  PROCEDURE get_un_info(
    ov_errbuf      OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_un_info'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    SELECT punt.un_number    un_number   -- �@��ԍ�
      INTO gt_un_number
      FROM po_un_numbers_tl     punt     -- �@��}�X�^
     WHERE punt.language     = USERENV('LANG')
       AND punt.un_number_id = g_xxcfo_po_data_rec.un_number_id;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- 'XXCFO'
                                                     ,gv_msg_cfo_00012                    -- �@����擾�G���[
                                                     ,gv_tkn_un_number_id                 -- �g�[�N��'UN_NUMBER_ID'
                                                     ,g_xxcfo_po_data_rec.un_number_id    -- �@��ԍ�ID
                                                     ,gv_tkn_requisition_no               -- �g�[�N��'REQUISITION_NO'
                                                     ,g_xxcfo_po_data_rec.requisition_num -- �w���˗��ԍ�
                                                     ,gv_tkn_po_num                       -- �g�[�N��'PO_NUM'
                                                     ,g_xxcfo_po_data_rec.po_num          -- �����ԍ�
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_un_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_rep_standard_po
   * Description      : ���[�N�e�[�u���f�[�^�o�^ (A-8)
   ***********************************************************************************/
  PROCEDURE insert_rep_standard_po(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rep_standard_po'; -- �v���O������
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
    cv_table CONSTANT VARCHAR2(100) := 'XXCFO_REP_STANDARD_PO'; -- �W���������쐬�p���[���[�N�e�[�u��
--
    -- *** ���[�J���ϐ� ***
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
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�o�^ (A-8)
    -- =====================================================
    INSERT INTO xxcfo_rep_standard_po (
       vendor_name                    -- �d���於
      ,vendor_phone                   -- �d����_�d�b�ԍ�
      ,vendor_fax                     -- �d����_FAX�ԍ�
      ,area_code                      -- �d����_�d�b�G���A�R�[�h
      ,fax_area_code                  -- �d����_FAX�G���A�R�[�h
      ,po_num                         -- �����ԍ�
      ,revision_num                   -- �����ԍ�
      ,po_agent_dept_name             -- �����S����_����������
      ,address_line1                  -- �����S����_�Z��
      ,zip                            -- �����S����_�X�֔ԍ�
      ,phone                          -- �����S����_�d�b�ԍ�
      ,fax                            -- �����S����_FAX
      ,apply_location_name            -- �\�����_��
      ,deliver_location_name          -- �[�i�ꏊ��
      ,vendor_product_num             -- �������i
      ,unit_price                     -- �P��
      ,quantity                       -- ����
      ,unit_meas_lookup_code          -- �P��
      ,promised_date                  -- �[��
      ,remarks                        -- ���l
      ,requisition_num                -- �w���˗��ԍ�
      ,apply_division_code            -- �\�����_�{���R�[�h
      ,deliver_division_code          -- �[����{���R�[�h
      ,pay_on_code                    -- ���Ȑ���-�x����
      ,org_id                         -- �g�DID
      ,data_empty_message             -- 0�����b�Z�[�W
      ,created_by                     -- �쐬��
      ,created_date                   -- �쐬��
      ,last_updated_by                -- �ŏI�X�V��
      ,last_updated_date              -- �ŏI�X�V��
      ,last_update_login              -- �ŏI�X�V���O�C��
      ,request_id                     -- �v��ID
      ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                     -- �R���J�����g�E�v���O����ID
      ,program_update_date            -- �v���O�����X�V��
    )
    VALUES ( 
       g_xxcfo_po_data_rec.vendor_name
      ,g_xxcfo_po_data_rec.vendor_phone
      ,g_xxcfo_po_data_rec.vendor_fax
      ,g_xxcfo_po_data_rec.area_code
      ,g_xxcfo_po_data_rec.fax_area_code
      ,g_xxcfo_po_data_rec.po_num
      ,g_xxcfo_po_data_rec.revision_num
      ,g_xxcfo_po_data_rec.po_location_name
      ,g_xxcfo_po_data_rec.po_address_line1
      ,g_xxcfo_po_data_rec.po_zip
      ,g_xxcfo_po_data_rec.po_phone
      ,g_xxcfo_po_data_rec.po_fax
      ,g_xxcfo_po_data_rec.apply_location_short_name
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10
                                                  , SUBSTRB( gt_party_name ,1 ,240 )            -- �[�i�ꏊ��
                                                  , g_xxcfo_po_data_rec.location_short_name)
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, gt_un_number            -- �������i
                                                  , g_xxcfo_po_data_rec.vendor_product_num)
      ,g_xxcfo_po_data_rec.unit_price
      ,g_xxcfo_po_data_rec.quantity_ordered
      ,g_xxcfo_po_data_rec.unit_meas_lookup_code
      ,g_xxcfo_po_data_rec.promised_date
      ,gv_referral_comp
      ,g_xxcfo_po_data_rec.requisition_num
      ,g_xxcfo_po_data_rec.apply_division_code
      ,g_xxcfo_po_data_rec.deliver_division_code
      ,g_xxcfo_po_data_rec.pay_on_code
      ,gn_org_id
      ,NULL
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,gn_conc_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- �f�[�^�쐬�G���[
                                                     ,gv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- �W���������쐬�p���[���[�N�e�[�u��
                                                     ,gv_tkn_errmsg        -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM              -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    ELSE
      --�o�^�����擾
      gn_rep_standard_po_cnt := gn_rep_standard_po_cnt + 1;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_rep_standard_po;
--
  /**********************************************************************************
   * Procedure Name   : insert_po_status_mng
   * Description      : �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^ (A-9)
   ***********************************************************************************/
  PROCEDURE insert_po_status_mng(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_po_status_mng'; -- �v���O������
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
    cv_table CONSTANT VARCHAR2(100) := 'XXCFO_PO_STATUS_MNG'; -- �������o�̓X�e�[�^�X�Ǘ��e�[�u��
--
    -- *** ���[�J���ϐ� ***
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
    -- =====================================================
    --  �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^ (A-9)
    -- =====================================================
    INSERT INTO xxcfo_po_status_mng ( 
       po_num
      ,org_id
      ,created_by
      ,created_date
      ,last_updated_by
      ,last_updated_date
      ,last_update_login 
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )
    VALUES ( 
       g_xxcfo_po_data_rec.po_num
      ,gn_org_id
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,gn_conc_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- �f�[�^�쐬�G���[
                                                     ,gv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- �X�e�[�^�X�Ǘ��e�[�u��
                                                     ,gv_tkn_errmsg        -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM              -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_po_status_mng;
--
  /**********************************************************************************
   * Procedure Name   : no_data_msg
   * Description      : 0���o�̓��b�Z�[�W (A-10)
   ***********************************************************************************/
  PROCEDURE no_data_msg(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'no_data_msg'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_retcode := xxccp_svfcommon_pkg.no_data_msg;
--
    IF (lv_retcode <> cv_status_normal) THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo               -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00009             -- ���ʊ֐��G���[
                                                     ,gv_tkn_func_name             -- �g�[�N��'FUNC_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_016A01001
                                                      )                            -- �uSVF���[���ʊ֐�(0���o�̓��b�Z�[�W)�v
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END no_data_msg;
--
  /**********************************************************************************
   * Procedure Name   : insert_rep_standard_po_0
   * Description      : ���[�N�e�[�u���f�[�^�o�^�i����0���p�j (A-11)
   ***********************************************************************************/
  PROCEDURE insert_rep_standard_po_0(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rep_standard_po_0'; -- �v���O������
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
    cv_table       CONSTANT VARCHAR2(100) := 'XXCFO_REP_STANDARD_PO'; -- �W���������쐬�p���[���[�N�e�[�u��
--
    -- *** ���[�J���ϐ� ***
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
    -- ====================================================
    -- ���[�O�����b�Z�[�W�擾
    -- ====================================================
    gt_no_data_msg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo    -- 'XXCFO'
                                                        ,gv_msg_cfo_00008  -- ����0���p���b�Z�[�W
                                                       )
                              ,1
                              ,5000);
    -- =====================================================
    --  ���[�N�e�[�u���f�[�^�o�^�i����0���p�j (A-11)
    -- =====================================================
    INSERT INTO xxcfo_rep_standard_po (
       vendor_name                    -- �d���於
      ,vendor_phone                   -- �d����_�d�b�ԍ�
      ,vendor_fax                     -- �d����_FAX�ԍ�
      ,area_code                      -- �d����_�d�b�G���A�R�[�h
      ,fax_area_code                  -- �d����_FAX�G���A�R�[�h
      ,po_num                         -- �����ԍ�
      ,revision_num                   -- �����ԍ�
      ,po_agent_dept_name             -- �����S����_����������
      ,address_line1                  -- �����S����_�Z��
      ,zip                            -- �����S����_�X�֔ԍ�
      ,phone                          -- �����S����_�d�b�ԍ�
      ,fax                            -- �����S����_FAX
      ,apply_location_name            -- �\�����_��
      ,deliver_location_name          -- �[�i�ꏊ��
      ,vendor_product_num             -- �������i
      ,unit_price                     -- �P��
      ,quantity                       -- ����
      ,unit_meas_lookup_code          -- �P��
      ,promised_date                  -- �[��
      ,remarks                        -- ���l
      ,requisition_num                -- �w���˗��ԍ�
      ,apply_division_code            -- �\�����_�{���R�[�h
      ,deliver_division_code          -- �[����{���R�[�h
      ,pay_on_code                    -- ���Ȑ���-�x����
      ,org_id                         -- �g�DID
      ,data_empty_message             -- 0�����b�Z�[�W
      ,created_by                     -- �쐬��
      ,created_date                   -- �쐬��
      ,last_updated_by                -- �ŏI�X�V��
      ,last_updated_date              -- �ŏI�X�V��
      ,last_update_login              -- �ŏI�X�V���O�C��
      ,request_id                     -- �v��ID
      ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                     -- �R���J�����g�E�v���O����ID
      ,program_update_date            -- �v���O�����X�V��
    )
    VALUES (
       NULL                           -- �d���於
      ,NULL                           -- �d����_�d�b�ԍ�
      ,NULL                           -- �d����_FAX�ԍ�
      ,NULL                           -- �d����_�d�b�G���A�R�[�h
      ,NULL                           -- �d����_FAX�G���A�R�[�h
      ,NULL                           -- �����ԍ�
      ,NULL                           -- �����ԍ�
      ,NULL                           -- �����S����_����������
      ,NULL                           -- �����S����_�Z��
      ,NULL                           -- �����S����_�X�֔ԍ�
      ,NULL                           -- �����S����_�d�b�ԍ�
      ,NULL                           -- �����S����_FAX
      ,NULL                           -- �\�����_��
      ,NULL                           -- �[�i�ꏊ��
      ,NULL                           -- �������i
      ,NULL                           -- �P��
      ,NULL                           -- ����
      ,NULL                           -- �P��
      ,NULL                           -- �[��
      ,NULL                           -- ���l
      ,NULL                           -- �w���˗��ԍ�
      ,NULL                           -- �\�����_�{���R�[�h
      ,NULL                           -- �[����{���R�[�h
      ,NULL                           -- ���Ȑ���-�x����
      ,gn_org_id                      -- �g�DID
      ,gt_no_data_msg                 -- 0�����b�Z�[�W
      ,cn_created_by                  -- �쐬��
      ,cd_creation_date               -- �쐬��
      ,cn_last_updated_by             -- �ŏI�X�V��
      ,cd_last_update_date            -- �ŏI�X�V��
      ,cn_last_update_login           -- �ŏI�X�V���O�C��
      ,gn_conc_request_id             -- �v��ID
      ,cn_program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,cn_program_id                  -- �R���J�����g�E�v���O����ID
      ,cd_program_update_date         -- �v���O�����X�V��
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- �f�[�^�}���G���[
                                                     ,gv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- �W���������쐬�p���[���[�N�e�[�u��
                                                     ,gv_tkn_errmsg        -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM              -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    ELSE
      --�o�^�����擾
      gn_rep_standard_po_cnt := gn_rep_standard_po_cnt + 1;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_rep_standard_po_0;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N������ (A-12)
   ***********************************************************************************/
  PROCEDURE act_svf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'act_svf'; -- �v���O������
    cv_output_mode    CONSTANT VARCHAR2(1)   := '1';  -- �o�͋敪(=1�FPDF�o�́j
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFO016A01S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFO016A01S.vrq';  -- �N�G���[�l���t�@�C����
    cv_language_ja    CONSTANT  fnd_concurrent_programs_tl.language%TYPE := 'JA' ;
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';  -- �g���q�ipdf�j
--
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(30);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := gv_pkg_name
                     || TO_CHAR ( cd_creation_date, gv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- �R���J�����g���̐ݒ�
      lv_conc_name := gv_pkg_name;
--
    -- �t�@�C�����̐ݒ�
      lv_file_id := gv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
     ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg       => lv_svf_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ,iv_conc_name    => lv_conc_name         -- �R���J�����g��
    ,iv_file_name    => lv_svf_file_name     -- �o�̓t�@�C����
    ,iv_file_id      => lv_file_id           -- ���[ID
    ,iv_output_mode  => cv_output_mode       -- �o�͋敪(=1�FPDF�o�́j
    ,iv_frm_file     => cv_svf_form_name     -- �t�H�[���l���t�@�C����
    ,iv_vrq_file     => cv_svf_query_name    -- �N�G���[�l���t�@�C����
    ,iv_org_id       => gn_org_id            -- ORG_ID
    ,iv_user_name    => lv_user_name         -- ���O�C���E���[�U��
    ,iv_resp_name    => lv_resp_name         -- ���O�C���E���[�U�̐E�Ӗ�
    ,iv_doc_name     => NULL                 -- ������
    ,iv_printer_name => NULL                 -- �v�����^��
    ,iv_request_id   => cn_request_id        -- �v��ID
    ,iv_nodata_msg   => NULL                 -- �f�[�^�Ȃ����b�Z�[�W
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00009    -- ���ʊ֐��G���[���b�Z�[�W
                                                     ,gv_tkn_func_name    -- �g�[�N��'FUNC_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                      gv_msg_kbn_cfo
                                                      ,gt_lookup_code_016A01002
                                                      )                   -- �u'SVF���[���ʊ֐�(SVF�R���J�����g�̋N��)'�v
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := SUBSTRB( lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg
                           ,1
                           ,5000
                           );
      RAISE global_api_expt;
--
    ELSE
      gn_normal_cnt := gn_target_cnt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rep_standard_po
   * Description      : ���[�N�e�[�u���f�[�^�폜 (A-13)
   ***********************************************************************************/
  PROCEDURE delete_rep_standard_po(
    ov_errbuf     OUT NOCOPY VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rep_standard_po'; -- �v���O������
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
    cv_table            CONSTANT VARCHAR2(100) := 'XXCFO_REP_STANDARD_PO'; -- �W���������쐬�p���[���[�N�e�[�u��
    ln_del_count        NUMBER := 0;  -- �폜����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �e�[�u�����b�N�J�[�\��
    CURSOR del_table_d_cur
    IS
    SELECT 'X'
      FROM xxcfo_rep_standard_po    xrsp
     WHERE xrsp.request_id = gn_conc_request_id
    FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
  xxcfo_del_rec    del_table_d_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN del_table_d_cur;
--
    BEGIN
      --�Ώۃf�[�^���폜
      DELETE FROM xxcfo_rep_standard_po  xrsp
      WHERE xrsp.request_id = gn_conc_request_id;
--
      ln_del_count := SQL%ROWCOUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                       ,gv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                                       ,gv_tkn_table       -- �g�[�N��'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- �W���������쐬�p���[���[�N�e�[�u��
                                                       ,gv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                       ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_api_expt;
    END;
--
    -- �J�[�\���N���[�Y
    IF po_data_cur%ISOPEN THEN
      CLOSE del_table_d_cur;
    END IF;
--
    IF (ln_del_count = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                                     ,gv_tkn_table       -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                         -- �W���������쐬�p���[���[�N�e�[�u��
                                                     ,gv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,gv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_table          -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                    )                       -- �W���������쐬�p���[���[�N�e�[�u��
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- �J�[�\���N���[�Y
      IF po_data_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_rep_standard_po;
--
  /**********************************************************************************
   * Procedure Name   : delete_po_status_mng
   * Description      : �X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜 (A-14)
   ***********************************************************************************/
  PROCEDURE delete_po_status_mng(
    ov_errbuf       OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_po_status_mng'; -- �v���O������
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
    cv_table   CONSTANT VARCHAR2(100) := 'XXCFO_PO_STATUS_MNG'; -- �������o�̓X�e�[�^�X�Ǘ��e�[�u��
--
    -- *** ���[�J���ϐ� ***
    ln_po_num_in_count  NUMBER := 1;  -- �C���N�������g�ϐ�
    ln_del_count        NUMBER := 0;  -- �폜����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �e�[�u�����b�N�J�[�\��
    CURSOR del_table_d_cur(in_po_num_in_count IN NUMBER)
    IS
      SELECT xpsm.po_num     po_num      -- �����ԍ�
        FROM xxcfo_po_status_mng    xpsm
       WHERE xpsm.po_num = gt_po_num(in_po_num_in_count)
         AND xpsm.org_id = gt_org_id(in_po_num_in_count)
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
    l_xxcfo_del_rec    del_table_d_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    LOOP
      FOR l_xxcfo_del_rec IN del_table_d_cur(ln_po_num_in_count) LOOP
        --�Ώۃf�[�^���폜
        DELETE FROM xxcfo_po_status_mng  xpsm
        WHERE  CURRENT OF del_table_d_cur;
--
        ln_del_count := SQL%ROWCOUNT;
        -- �G���[����
        IF (ln_del_count = 0) THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                         ,gv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                                         ,gv_tkn_table       -- �g�[�N��'TABLE'
                                                         ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                             -- �������f�[�^�o�̓��[�N�e�[�u��
                                                         ,gv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                         ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
        END IF;
--
        ln_po_num_in_count := ln_po_num_in_count + 1;
      END LOOP;
--
      -- �o�^�����𒴂����ꍇ�ɏI������
      IF (ln_po_num_in_count > gn_po_num_in_count) THEN
        EXIT;
      END IF;
--
    END LOOP;
--
    -- ���[�v�Ώۃf�[�^���擾�ł��Ȃ������ꍇ�̃G���[����
    IF (ln_del_count = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00025   -- �f�[�^�폜�G���[
                                                     ,gv_tkn_table       -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                         -- �������f�[�^�o�̓��[�N�e�[�u��
                                                     ,gv_tkn_errmsg      -- �g�[�N��'ERRMSG'
                                                     ,SQLERRM            -- SQL�G���[���b�Z�[�W
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,gv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_table          -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                    )                       -- �X�e�[�^�X�Ǘ��e�[�u��
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF del_table_d_cur%ISOPEN THEN
        CLOSE del_table_d_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_po_status_mng;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_po_dept_code            IN         VARCHAR2,     --   �����쐬����
    iv_po_agent_code           IN         VARCHAR2,     --   �����쐬��
    iv_vender_code             IN         VARCHAR2,     --   �d����
    iv_po_num                  IN         VARCHAR2,     --   �����ԍ�
    iv_po_creation_date_from   IN         VARCHAR2,     --   �����쐬��From
    iv_po_creation_date_to     IN         VARCHAR2,     --   �����쐬��To
    iv_po_approved_date_from   IN         VARCHAR2,     --   �������F��From
    iv_po_approved_date_to     IN         VARCHAR2,     --   �������F��To
    iv_reissue_flag            IN         VARCHAR2,     --   �Ĕ��s�t���O
    ov_errbuf                  OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf2                VARCHAR2(5000);                   -- �G���[�E���b�Z�[�W
    lv_errmsg2                VARCHAR2(5000);                   -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_retcode2               VARCHAR2(1);                      -- ���^�[���E�R�[�h
    lt_po_num                 g_xxcfo_po_data_rec.po_num%TYPE;  -- �����ԍ��ꎞ�ۑ�
    lt_org_id                 g_xxcfo_po_data_rec.org_id%TYPE;  -- �g�DID�ꎞ�ۑ�
    ln_po_agent_code          NUMBER;                           -- �����쐬��
    ld_po_creation_date_from  DATE;                             -- �����쐬��From
    ld_po_creation_date_to    DATE;                             -- �����쐬��To
    ld_po_approved_date_from  DATE;                             -- �������F��From
    ld_po_approved_date_to    DATE;                             -- �������F��To
    ln_i                      NUMBER;                           -- �C���N�������g�ϐ�
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt          := 0;     -- �Ώی���
    gn_normal_cnt          := 0;     -- ���팏��
    gn_error_cnt           := 0;     -- �G���[����
    gn_warn_cnt            := 0;     -- �x������
    gn_po_num_in_count     := 0;     -- �X�e�[�^�X�Ǘ��e�[�u���ւ̔����ԍ��o�^����
    gn_rep_standard_po_cnt := 0;     -- �W���������쐬�p���[���[�N�e�[�u���֖��o�^
--
    -- =====================================================
    --  ���̓p�����[�^�l���O�o�͏���(A-1)
    -- =====================================================
    init(
       iv_po_dept_code                    -- �����쐬����
      ,iv_po_agent_code                   -- �����쐬��
      ,iv_vender_code                     -- �d����
      ,iv_po_num                          -- �����ԍ�
      ,iv_po_creation_date_from           -- �����쐬��From
      ,iv_po_creation_date_to             -- �����쐬��To
      ,iv_po_approved_date_from           -- �������F��From
      ,iv_po_approved_date_to             -- �������F��To
      ,iv_reissue_flag                    -- �Ĕ��s�t���O
      ,lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ��������(A-2)
    -- =====================================================
    get_profile_lookup_val(
       iv_po_creation_date_from      -- �����쐬��From
      ,iv_po_creation_date_to        -- �����쐬��To
      ,iv_po_approved_date_from      -- �������F��From
      ,iv_po_approved_date_to        -- �������F��To
      ,lv_errbuf                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �����f�[�^�擾(A-3)
    -- =====================================================
    -- ����������
    gn_target_cnt := 0;
--
    ln_po_agent_code         := TO_NUMBER(iv_po_agent_code);                      -- �����쐬��
    ld_po_creation_date_from := TO_DATE(iv_po_creation_date_from, gv_format_date_ymdhms);  -- �����쐬��From
    ld_po_creation_date_to   := TO_DATE(iv_po_creation_date_to,   gv_format_date_ymdhms);  -- �����쐬��To
    ld_po_approved_date_from := TO_DATE(iv_po_approved_date_from, gv_format_date_ymdhms);  -- �������F��From
    ld_po_approved_date_to   := TO_DATE(iv_po_approved_date_to,   gv_format_date_ymdhms);  -- �������F��To
--
    -- �J�[�\���I�[�v��
    OPEN po_data_cur(
            iv_po_dept_code                 -- �����쐬����
           ,ln_po_agent_code                -- �����쐬��
           ,iv_vender_code                  -- �d����
           ,iv_po_num                       -- �����ԍ�
           ,ld_po_creation_date_from        -- �����쐬��From
           ,ld_po_creation_date_to          -- �����쐬��To
           ,ld_po_approved_date_from        -- �������F��From
           ,ld_po_approved_date_to          -- �������F��To
           ,iv_reissue_flag);               -- �Ĕ��s�t���O
--
    LOOP
      FETCH po_data_cur INTO g_xxcfo_po_data_rec;
      EXIT WHEN po_data_cur%NOTFOUND;
--
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �Y�t��񔻒�R�[�h��10�i���̋@�̏ꍇ�j
      IF   (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10) THEN
--
        -- =====================================================
        --  �Y�t���擾����(A-4)
        -- =====================================================
        get_attache_info(
           lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
        IF (lv_retcode != cv_status_error) THEN
--
          -- =====================================================
          --  �Y�t���ҏW����(A-5)
          -- =====================================================
          edit_attache_info(
             lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
          IF (lv_retcode != cv_status_error) THEN
--
            -- =====================================================
            --  �ڋq���擾����(A-6)
            -- =====================================================
            get_customer_info(
               lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
            IF (lv_retcode != cv_status_error) THEN
--
              -- =====================================================
              --  �@����擾����(A-7)
              -- =====================================================
              get_un_info(
                 lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            END IF;
          END IF;
        END IF;
      END IF;
--
      -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
      IF (lv_retcode != cv_status_error) THEN
--
        -- =====================================================
        --  ���[�N�e�[�u���f�[�^�o�^(A-8)
        -- =====================================================
        insert_rep_standard_po(
           lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
        IF (lv_retcode != cv_status_error) THEN
--
          -- =====================================================
          --  �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^(A-9)
          -- =====================================================
          IF (iv_reissue_flag = gv_reissue_flag_0) THEN
--
            -- �����ԍ��ŃL�[�u���C�N�ɂď����J�n
            IF ( lt_po_num != g_xxcfo_po_data_rec.po_num
              OR lt_po_num IS NULL
              OR lt_org_id != g_xxcfo_po_data_rec.org_id
              OR lt_org_id IS NULL)
            THEN
              lt_po_num := g_xxcfo_po_data_rec.po_num;
              lt_org_id := g_xxcfo_po_data_rec.org_id;
--
              insert_po_status_mng(
                 lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              -- �o�^�ł����ꍇ�A�����ԍ��E�g�DID��ێ�����B
              IF (lv_retcode != cv_status_error) THEN
                gn_po_num_in_count            := gn_po_num_in_count + 1;
                gt_po_num(gn_po_num_in_count) := lt_po_num;
                gt_org_id(gn_po_num_in_count) := lt_org_id;
--
              END IF;
--
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
        EXIT;
      END IF;
--
    END LOOP;
--
    IF po_data_cur%ISOPEN THEN
      CLOSE po_data_cur;
    END IF;
--
    -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
    IF (lv_retcode != cv_status_error) THEN
--
      IF (gn_target_cnt = 0) THEN
        -- =====================================================
        --  0���o�̓��b�Z�[�W(A-10)
        -- =====================================================
        no_data_msg(
           lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
        IF (lv_retcode != cv_status_error) THEN
--
          -- =====================================================
          --  ���[�N�e�[�u���f�[�^�o�^�i����0���p�j(A-11)
          -- =====================================================
          insert_rep_standard_po_0(
             lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        END IF;
--
      END IF;
--
      -- �G���[�̏ꍇ�́u�X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜�v���珈�����J�n
      IF (lv_retcode != cv_status_error) THEN
        -- =====================================================
        --  SVF�N������(A-12)
        -- =====================================================
        act_svf(
           lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      END IF;
--
    END IF;
--
    -- �W���������쐬�p���[���[�N�e�[�u����1���ȏ�o�^����Ă����ꍇ
    IF (gn_rep_standard_po_cnt >= 1) THEN
      -- =====================================================
      --  ���[�N�e�[�u���f�[�^�폜(A-13)
      -- =====================================================
      lv_retcode2 := lv_retcode;
      lv_errmsg2  := lv_errmsg;
      lv_errbuf2  := lv_errbuf;
--
      delete_rep_standard_po(
         lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�ō폜�������s���ꍇCOMMIT���K�v�ƂȂ�
      COMMIT;
--
      -- ���b�Z�[�W��A��
      lv_errmsg := lv_errmsg2 || lv_errmsg;
      lv_errbuf := lv_errbuf2 || lv_errbuf;
      IF (lv_retcode2 = cv_status_error) THEN
        lv_retcode := cv_status_error;
      END IF;
--
    END IF;
--
    -- �x���I��
    IF (gn_target_cnt = 0 AND
        lv_retcode != cv_status_error ) THEN
      lv_retcode := cv_status_warn;
      lv_errmsg  := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                      ,gv_msg_cfo_00004   -- �Ώۃf�[�^�����G���[
                                                     )
                            ,1
                            ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    END IF;
--
    -- �V�K�E�G���[�E�X�e�[�^�X�Ǘ��e�[�u���ɓo�^�ς݂̏ꍇ�A�폜����B
    IF (  iv_reissue_flag     = gv_reissue_flag_0
      AND lv_retcode          = cv_status_error
      AND gn_po_num_in_count != 0)
    THEN
      -- =====================================================
      --  �X�e�[�^�X�Ǘ��e�[�u���f�[�^�폜(A-14)
      -- =====================================================
      lv_retcode2 := lv_retcode;
      lv_errmsg2  := lv_errmsg;
      lv_errbuf2  := lv_errbuf;
--
      delete_po_status_mng(
         lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg );                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�ō폜�������s���ꍇCOMMIT���K�v�ƂȂ�
      COMMIT;
--
      -- ���b�Z�[�W��A��
      lv_errmsg := lv_errmsg2 || lv_errmsg;
      lv_errbuf := lv_errbuf2 || lv_errbuf;
      IF (lv_retcode2 = cv_status_error) THEN
        lv_retcode := cv_status_error;
      END IF;
--
      --(�G���[����)
      RAISE global_process_expt;
--
    END IF;
--
    -- �G���[��A-14�̏����ɓ���Ȃ��ꍇ
    IF (lv_retcode = cv_status_error) THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�G���[
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,gv_msg_cfo_00019      -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_table          -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        gv_msg_kbn_cfo
                                                       ,gt_lookup_code_000A00006
                                                      )                            -- �u�������v
                                                    )                       -- �������
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF po_data_cur%ISOPEN THEN
        CLOSE po_data_cur;
      END IF;
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
    errbuf                     OUT NOCOPY VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                    OUT NOCOPY VARCHAR2,         --    �G���[�R�[�h        --# �Œ� #
    iv_po_dept_code            IN         VARCHAR2,         --    �����쐬����
    iv_po_agent_code           IN         VARCHAR2,         --    �����쐬��
    iv_vender_code             IN         VARCHAR2,         --    �d����
    iv_po_num                  IN         VARCHAR2,         --    �����ԍ�
    iv_po_creation_date_from   IN         VARCHAR2,         --    �����쐬��From
    iv_po_creation_date_to     IN         VARCHAR2,         --    �����쐬��To
    iv_po_approved_date_from   IN         VARCHAR2,         --    �������F��From
    iv_po_approved_date_to     IN         VARCHAR2,         --    �������F��To
    iv_reissue_flag            IN         VARCHAR2          --    �Ĕ��s�t���O
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    lv_errbuf2         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => gv_file_type_log
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
       iv_po_dept_code                    -- �����쐬����
      ,iv_po_agent_code                   -- �����쐬��
      ,iv_vender_code                     -- �d����
      ,iv_po_num                          -- �����ԍ�
      ,iv_po_creation_date_from           -- �����쐬��From
      ,iv_po_creation_date_to             -- �����쐬��To
      ,iv_po_approved_date_from           -- �������F��From
      ,iv_po_approved_date_to             -- �������F��To
      ,iv_reissue_flag                    -- �Ĕ��s�t���O
      ,lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- �G���[�̏ꍇ�A�G���[����������������ݒ肷��
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;          -- �Ώی���
      gn_normal_cnt := 0;          -- ��������
      gn_error_cnt  := 1;          -- �G���[����
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- =====================================================
    --  �I������(A-15)
    -- =====================================================
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �V�X�e���G���[���b�Z�[�W�o��
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => gv_msg_kbn_cfo
                      ,iv_name         => gv_msg_cfo_00036
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --�G���[���b�Z�[�W
      );
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFO016A01C;
/
