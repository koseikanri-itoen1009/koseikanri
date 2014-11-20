CREATE OR REPLACE PACKAGE BODY XXCFO016A02C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFO016A02C(body)
 * Description     : �������f�[�^�o�͏���
 * MD.050          : MD050_CFO_016_A02_�������f�[�^�o�͏���
 * MD.070          : MD050_CFO_016_A02_�������f�[�^�o�͏���
 * Version         : 1.7
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
 *  insert_po_status_mng P     �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^             (A-8)
 *  insert_tmp_standard_data_po P �������f�[�^�o�̓��[�N�e�[�u���f�[�^�o�^  (A-9)
 *  insert_csv_outs_temp P     CSV���[�N�e�[�u���f�[�^�o�^                  (A-10)
 *  out_put_file    P          OUT�t�@�C���o�͏���                          (A-11)
 *  submain         P          ���C�������v���V�[�W��
 *  main            P          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-11-12    1.0  SCS �R�� �D   ����쐬
 *  2009-02-06    1.1  SCS ���c�E�l  [��QCFO_001]���Ə��A�h�I���}�X�^�̗L�����t�`�F�b�N��ǉ�
 *  2009-02-09    1.2  SCS ���c�E�l  [��QCFO_002]�o�͌����Ή�
 *  2009-03-16    1.3  SCS ���c�E�l  [��QT1_0050]�G���[���O�Ή�
 *  2009-03-17    1.4  SCS ���c�E�l  [��QT1_0051]���ʊ֐��G���[���Ή�
 *  2009-03-23    1.5  SCS �J�����  [��QT1_0059]�@��R�[�h�̕ύX�Ή�
 *  2009-11-25    1.6  SCS �����^�I  [��QE_�{�ғ�_00063]�ڋq���擾�G���[�Ή�
 *  2009-12-24    1.7  SCS �����^�I  [��QE_�{�ғ�_00592]�[�i�ꏊ�ύX�Ή�
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
  gv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCFO016A02C';   -- �p�b�P�[�W��
  gv_msg_kbn_cfo           CONSTANT VARCHAR2(5)   := 'XXCFO';
  gv_flag_y                CONSTANT VARCHAR2(1)   := 'Y';              -- �t���O�iY�j
  gv_flag_n                CONSTANT VARCHAR2(1)   := 'N';              -- �t���O�iN�j
  gv_approved              CONSTANT VARCHAR2(10)  := 'APPROVED';       -- ���F��
  gv_standard              CONSTANT VARCHAR2(10)  := 'STANDARD';       -- �W������
  gv_reissue_flag_0        CONSTANT VARCHAR2(1)   := '0';              -- �V�K
  gv_reissue_flag_1        CONSTANT VARCHAR2(1)   := '1';              -- �Ĕ��s�F�Ĕ��s
  gv_reissue_flag_2        CONSTANT VARCHAR2(1)   := '2';              -- �Ĕ��s�F�Ɖ�
  gv_lookup_code_100       CONSTANT VARCHAR2(3)   := '100';            -- �ݒu��_�ڋq�R�[�h=
  gn_view_appli_id_201     CONSTANT NUMBER        := 201;              -- �r���[�A�v���P�[�V����ID
  gv_judge_code_10         CONSTANT VARCHAR2(2)   := '10';             -- ���̋@
  gv_judge_code_20         CONSTANT VARCHAR2(2)   := '20';             -- �Œ莑�Y
  gv_judge_code_30         CONSTANT VARCHAR2(2)   := '30';             -- ���h
  gv_entity_name           CONSTANT VARCHAR2(10)  := 'REQ_LINES';      -- �w���˗�����
  gv_equal                 CONSTANT VARCHAR2(1)   := '=';              -- �C�R�[��
  gv_file_type_log         CONSTANT VARCHAR2(10)  := 'LOG';            -- ���O�o��
  gv_format_date_ymdhms    CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
                                                                       -- ���t�t�H�[�}�b�g�i�N���������b�j
                                                                                -- �G���[���b�Z�[�W�o�͗p�Q�ƃ^�C�v�R�[�h
  gt_lookup_code_000A00002 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00002';
                                                                                -- �u�����쐬��From�v
  gt_lookup_code_000A00003 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00003';
                                                                                -- �u�����쐬��To�v
  gt_lookup_code_000A00004 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00004';
                                                                                -- �u�������F��From�v
  gt_lookup_code_000A00005 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00005';
                                                                                -- �u�������F��To�v
  gt_lookup_code_016A02001 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO016A02001';
                                                                                -- �uOUT�t�@�C���o�͏����v
  gt_lookup_code_000A00006 CONSTANT fnd_lookup_values.lookup_code%TYPE := 'CFO000A00006';
                                                                                -- �u�������v
--
  -- ���b�Z�[�W�ԍ�
  gv_msg_cfo_00001   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_msg_cfo_00004   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004'; -- �x���G���[���b�Z�[�W
  gv_msg_cfo_00009   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00009'; -- ���ʊ֐��G���[���b�Z�[�W
  gv_msg_cfo_00010   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00010'; -- �Y�t���擾�G���[���b�Z�[�W
  gv_msg_cfo_00011   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00011'; -- �ڋq���擾�G���[���b�Z�[�W
  gv_msg_cfo_00012   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00012'; -- �@����擾�G���[���b�Z�[�W
  gv_msg_cfo_00013   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00013'; -- �Y�t��񕶎��񌟍��G���[���b�Z�[�W
  gv_msg_cfo_00014   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00014'; -- �Y�t��񕶎���擾���E�G���[���b�Z�[�W
  gv_msg_cfo_00019   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; -- �e�[�u�����b�N�G���[���b�Z�[�W
  gv_msg_cfo_00025   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; -- �f�[�^�폜�G���[���b�Z�[�W
  gv_msg_cfo_00033   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00033'; -- �R���J�����g�p�����[�^�l�召�`�F�b�N�G���[���b�Z�[�W
  gv_msg_cfo_00035   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00035'; -- �f�[�^�쐬�G���[���b�Z�[�W�G���[���b�Z�[�W
  gv_msg_cfo_00036   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00036'; -- �V�X�e���G���[���b�Z�[�W
--
  -- �g�[�N��
  gv_tkn_prof            CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  gv_tkn_param_name_from CONSTANT VARCHAR2(15) := 'PARAM_NAME_FROM';  -- �召�`�F�b�NFrom �����p
  gv_tkn_param_name_to   CONSTANT VARCHAR2(15) := 'PARAM_NAME_TO';    -- �召�`�F�b�NTo �����p
  gv_tkn_param_val_from  CONSTANT VARCHAR2(15) := 'PARAM_VAL_FROM';   -- �召�`�F�b�NFrom �l�p
  gv_tkn_param_val_to    CONSTANT VARCHAR2(15) := 'PARAM_VAL_TO';     -- �召�`�F�b�NTo �l�p
  gv_tkn_lookup_type     CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';      -- ���b�N�A�b�v�^�C�v
  gv_tkn_lookup_code     CONSTANT VARCHAR2(15) := 'LOOKUP_CODE';      -- ���b�N�A�b�v�R�[�h
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
  gv_user_id         CONSTANT VARCHAR2(30) := 'USER_ID';          -- ���[�U�[ID
  gv_conc_request_id CONSTANT VARCHAR2(30) := 'CONC_REQUEST_ID';  -- �v��ID
--
  gv_lookup_type1    CONSTANT VARCHAR2(100) := 'XXCFO1_PO_REPORT_OUT_FLAG';          -- �W���������o�͍σt���O
  gv_lookup_type2    CONSTANT VARCHAR2(100) := 'AUTHORIZATION STATUS';               -- ���F�X�e�[�^�X
  gv_lookup_type3    CONSTANT VARCHAR2(100) := 'XXCFO1_SEARCH_LONG_TEXT';            -- ������������������
  gv_lookup_type4    CONSTANT VARCHAR2(100) := 'XXCFO1_PO_DATA_OUT_HEAD_ITEM';       -- �������f�[�^�o�̓w�b�_����
--
  --===============================================================
  -- �O���[�o���ϐ�
  --===============================================================
  gn_set_of_bks_id             NUMBER;                                     -- ��v����ID
  gn_org_id                    NUMBER;                                     -- �g�DID
  gn_conc_request_id           NUMBER;                                     -- �v��ID
  gt_search_long_text          fnd_lookup_values.meaning%TYPE;             -- ����������������
  gt_account_number            hz_cust_accounts.account_number%TYPE;       -- �ڋq�R�[�h
  gt_standard_po_output        fnd_lookup_values.description%TYPE;         -- �W���������o�͍σt���O��
  gt_long_text                 fnd_documents_long_text.long_text%TYPE;     -- ��������
  gt_authorization_status_name fnd_lookup_values.meaning%TYPE;             -- ���F�X�e�[�^�X�̎擾
  gt_party_name                hz_parties.party_name%TYPE;                 -- �ڋq��
  gt_state                     hz_locations.state%TYPE;                    -- �s���{��
  gt_city                      hz_locations.city%TYPE;                     -- �s�撬��
  gt_address1                  hz_locations.address1%TYPE;                 -- �Z���P
  gt_address2                  hz_locations.address2%TYPE;                 -- �Z���Q
  gt_un_number                 po_un_numbers_tl.un_number%TYPE;            -- �@��ԍ�
  gn_po_num_in_count           NUMBER;                                     -- �X�e�[�^�X�Ǘ��e�[�u���ւ̔����ԍ��o�^����
  gn_special_info_cnt          NUMBER;                                     -- ���ʏ�񍀖ڐ�
--
  --===============================================================
  -- �O���[�o���e�[�u���^�C�v
  --===============================================================
  TYPE g_special_info_ttype     IS TABLE OF fnd_documents_long_text.long_text%TYPE INDEX BY PLS_INTEGER;
  TYPE g_po_num_ttype           IS TABLE OF xxcfo_po_status_mng.po_num%TYPE        INDEX BY PLS_INTEGER;
  TYPE g_org_id_ttype           IS TABLE OF xxcfo_po_status_mng.org_id%TYPE        INDEX BY PLS_INTEGER;
--
  --===============================================================
  -- �O���[�o���e�[�u��
  --===============================================================
  gt_special_info_item      g_special_info_ttype;
  gt_po_num                 g_po_num_ttype;
  gt_org_id                 g_org_id_ttype;
--
  --===============================================================
  -- �O���[�o���e�[�u��
  --===============================================================
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
--MOD_Ver.1.7_2009/12/24_START----------------------------------------------------------------------------
--          ,l_xla.location_short_name              location_short_name        -- �[���掖�Ə�
          ,l_xla.location_name                    location_name              -- �[���掖�Ə�
--MOD_Ver.1.7_2009/12/24_END------------------------------------------------------------------------------
          ,l_hl.location_code                     location_code              -- �[���掖�Ə��R�[�h
          ,pvsa.phone                             vendor_phone               -- �d����d�b�ԍ�
          ,pvsa.fax                               vendor_fax                 -- �d����FAX�ԍ�
          ,pvsa.pay_on_code                       pay_on_code                -- ���Ȑ���-�x����
          ,pvsa.attribute1                        vendor_name                -- �d���於
          ,pr.requisition_num                     requisition_num            -- �w���˗��ԍ�
          ,pr.requisition_line_id                 requisition_line_id        -- �w���˗�����ID
--MOD_Ver.1.5_2009/03/23_START------------------------------------------------------------------------------
--          ,pr.un_number_id                        un_number_id               -- �@��ID
          ,pla.un_number_id                       un_number_id               -- �@��ID
--MOD_Ver.1.5_2009/03/23_END--------------------------------------------------------------------------------
          ,pr.location_short_name                 apply_location_short_name  -- �\�����_
          ,pr.location_code                       apply_location_code        -- �\�����_�R�[�h
          ,pha.revision_num                       revision_num               -- �����ԍ�
          ,pla.line_num                           line_num                   -- �������הԍ�
          ,plla.need_by_date                      need_by_date               -- ��]�����
          ,pvsa.vendor_site_code                  vendor_site_code           -- �d����T�C�g�R�[�h
          ,pha.currency_code                      currency_code              -- �ʉ݃R�[�h
          ,papf1.full_name                        full_name                  -- �w���S����
          ,mcb.segment1                           category_name              -- �J�e�S����
          ,pla.item_description                   item_description           -- �E�v
          ,plla.shipment_num                      shipment_num               -- �[�����הԍ�
          ,pla.quantity                           quantity                   -- ��������
          ,l_xla.address_line1                    address_line1              -- �[�i�ꏊ�Z��
          ,pha.org_id                             org_id                     -- �g�DID
          ,pha.creation_date                      creation_date              -- �����쐬��
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
--DEL_Ver.1.5_2009/03/23_START------------------------------------------------------------------------------
--                  ,prla.un_number_id            un_number_id                        -- �@��ID
--DEL_Ver.1.5_2009/03/23_END--------------------------------------------------------------------------------
                  ,prda.distribution_id         distribution_id                     -- �w���˗���������ID
                  ,xla.location_short_name      location_short_name                 -- �\�����_
                  ,hl.location_code             location_code                       -- �\�����_�R�[�h
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
            (    iv_reissue_flag IN (gv_reissue_flag_1, gv_reissue_flag_2)
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
    iv_reissue_flag          IN         VARCHAR2,   -- �Ĕ��s�t���O
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
    -- �W���������o�͍σt���O���̎擾
    SELECT flv.description            description
      INTO gt_standard_po_output
      FROM fnd_lookup_values      flv
     WHERE flv.lookup_type            = gv_lookup_type1
       AND flv.language               = USERENV('LANG')
       AND flv.enabled_flag           = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
            OR flv.end_date_active   >= TRUNC( SYSDATE ))
       AND flv.lookup_code            = iv_reissue_flag;
--
    -- ���F�X�e�[�^�X�̎擾
    SELECT flv.meaning            meaning
      INTO gt_authorization_status_name
      FROM fnd_lookup_values      flv
     WHERE flv.view_application_id   = gn_view_appli_id_201
       AND flv.lookup_type           = gv_lookup_type2
       AND flv.language              = USERENV('LANG')
       AND flv.enabled_flag          = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
            OR flv.end_date_active   >= TRUNC( SYSDATE ))
       AND flv.lookup_code           = gv_approved;
--
    -- �����������������̎擾
    SELECT flv.meaning            meaning
      INTO gt_search_long_text
      FROM fnd_lookup_values      flv
     WHERE flv.lookup_type            = gv_lookup_type3
       AND flv.language               = USERENV('LANG')
       AND flv.enabled_flag           = gv_flag_y
       AND (   flv.start_date_active IS NULL
            OR flv.start_date_active <= TRUNC( SYSDATE ))
       AND (   flv.end_date_active   IS NULL
           OR flv.end_date_active    >= TRUNC( SYSDATE ))
       AND flv.lookup_code            = gv_lookup_code_100;
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
    lv_long_text       fnd_documents_long_text.long_text%TYPE;   -- ���������̈ꎞ�ϐ�
    ln_cnt             NUMBER;
    ln_len             NUMBER;
    ln_chr10           NUMBER;
    lv_char            fnd_documents_long_text.long_text%TYPE;
    ln_char_len        NUMBER;
    ln_compartmental   NUMBER;
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
    -- ���̋@�̏ꍇ
    IF (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10) THEN
      gt_account_number := xxcfo_common_pkg.get_special_info_item(
                                              gt_long_text                   -- ��������
                                             ,gt_search_long_text);          -- �����Ώە�����i�ݒu��_�ڋq�R�[�h=�j
--
      IF (gt_account_number IS NULL) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo                      -- �A�v���P�[�V�����Z�k���FXXCFO
                                                       ,gv_msg_cfo_00013                    -- �Y�t��񕶎��񌟍��G���[
                                                       ,gv_tkn_search_string                -- �g�[�N��'SEARCH_STRING'
                                                       ,gt_search_long_text                 -- �����Ώە�����
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
    END IF;
--
    -- ���ʏ�񍀖ڎ擾����
    lv_long_text := gt_long_text;
    FOR ln_cnt IN 1..100 LOOP
      -- ���������̒���
      ln_len   := LENGTHB(lv_long_text);
      -- ���������̉��s�R�[�h�ʒu
      ln_chr10 := INSTRB(lv_long_text,CHR(10));
--
      IF (ln_chr10 != 0) THEN
        -- ������
        lv_char := SUBSTRB(lv_long_text, 1, ln_chr10 - 1);
--
      ELSE
        -- ������
        lv_char := lv_long_text;
--
      END IF;
--
      -- ������̒���
      ln_char_len := LENGTHB(lv_char);
      -- ��؂�ʒu
      ln_compartmental := INSTRB(lv_char, gv_equal);
      -- ���ʏ�񍀖ڎ擾
      gt_special_info_item(ln_cnt) := SUBSTRB(lv_char, ln_compartmental + 1, ln_char_len - ln_compartmental);
--
      -- ���ʏ�񍀖ڐ�
      gn_special_info_cnt := gn_special_info_cnt + 1;
--
      -- �c������
      lv_long_text := SUBSTRB(lv_long_text, ln_chr10 + 1, ln_len - ln_chr10);
--
      IF (ln_chr10 = 0) THEN
        EXIT;
      END IF;
--
    END LOOP;
--
    -- ���ʏ�񍀖ڂ�100���ȏ�擾�ł���ꍇ = ���s�R�[�h�����������Ɏc���Ă���
    IF ( ln_chr10 != 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00014   -- �Y�t��񕶎���擾���E�G���[
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
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
          ,hl.state           state             -- �s���{��
          ,hl.city            city              -- �s�撬��
          ,hl.address1        address1          -- �Z���P
          ,hl.address2        address2          -- �Z���Q
      INTO gt_party_name
          ,gt_state
          ,gt_city
          ,gt_address1
          ,gt_address2
      FROM hz_parties           hp,     -- �p�[�e�B�}�X�^
           hz_party_sites       hps,    -- �p�[�e�B�T�C�g�}�X�^
           hz_cust_accounts     hca,    -- �ڋq�}�X�^
           hz_locations         hl      -- �ڋq���Ə��}�X�^
---- == 2009/11/25 V1.6 Added START =================================
          ,hz_cust_acct_sites_all hcasa -- �ڋq�T�C�g�}�X�^
---- == 2009/11/25 V1.6 Added END ===================================
     WHERE hp.party_id        = hca.party_id
       AND hca.account_number = gt_account_number
       AND hp.party_id        = hps.party_id
---- == 2009/11/25 V1.6 Added START =================================
       AND hca.cust_account_id  = hcasa.cust_account_id
       AND hcasa.org_id       = gn_org_id
       AND hps.party_site_id  = hcasa.party_site_id
---- == 2009/11/25 V1.6 Added END ===================================
       AND hl.location_id     = hps.location_id;
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
   * Procedure Name   : insert_po_status_mng
   * Description      : �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^ (A-8)
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
--
    cv_table CONSTANT VARCHAR2(100) := 'XXCFO_PO_STATUS_MNG'; -- �X�e�[�^�X�Ǘ��e�[�u��
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
    --  �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^ (A-8)
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
   * Procedure Name   : insert_tmp_standard_data_po
   * Description      : �������f�[�^�o�̓��[�N�e�[�u���f�[�^�o�^ (A-9)
   ***********************************************************************************/
  PROCEDURE insert_tmp_standard_data_po(
    ov_errbuf     OUT NOCOPY VARCHAR2,        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,        --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_tmp_standard_data_po'; -- �v���O������
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
    cv_table   CONSTANT VARCHAR2(100) := 'XXCFO_TMP_STANDARD_DATA_PO'; -- �������f�[�^�o�̓��[�N�e�[�u��
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
    --  �������f�[�^�o�̓��[�N�e�[�u���f�[�^�o�^ (A-9)
    -- =====================================================
    INSERT INTO xxcfo_tmp_standard_data_po ( 
       po_num                               -- �����ԍ�
      ,revision_num                         -- �����ԍ�
      ,authorization_status_name            -- ���F�X�e�[�^�X
      ,po_creation_date                     -- �����쐬����
      ,vendor_name                          -- �d����
      ,vendor_site_code                     -- �d����T�C�g�R�[�h
      ,currency_code                        -- �ʉ݃R�[�h
      ,full_name                            -- �w���S��
      ,line_num                             -- �������הԍ�
      ,item_category_name                   -- �i�ڃJ�e�S��
      ,item_description                     -- �E�v
      ,quantity_ordered                     -- ��������
      ,unit_meas_lookup_code                -- �P��
      ,unit_price                           -- ���i
      ,amount                               -- ���z
      ,vendor_product_num                   -- �d����i��
      ,requisition_num                      -- �w���˗��ԍ�
      ,apply_location_code                  -- �\�����_�R�[�h
      ,apply_location_name                  -- �\�����_��
      ,shipment_num                         -- �[�����הԍ�
      ,deliver_location_code                -- �[�i�ꏊ�R�[�h
      ,deliver_location_name                -- �[�i�ꏊ��
      ,promised_date                        -- �[��
      ,need_by_date                         -- ��]�����
      ,deliver_address                      -- �[�i�ꏊ�Z��
      ,standard_po_output                   -- �W�������o�͍�
      ,special_info_item1
      ,special_info_item2
      ,special_info_item3
      ,special_info_item4
      ,special_info_item5
      ,special_info_item6
      ,special_info_item7
      ,special_info_item8
      ,special_info_item9
      ,special_info_item10
      ,special_info_item11
      ,special_info_item12
      ,special_info_item13
      ,special_info_item14
      ,special_info_item15
      ,special_info_item16
      ,special_info_item17
      ,special_info_item18
      ,special_info_item19
      ,special_info_item20
      ,special_info_item21
      ,special_info_item22
      ,special_info_item23
      ,special_info_item24
      ,special_info_item25
      ,special_info_item26
      ,special_info_item27
      ,special_info_item28
      ,special_info_item29
      ,special_info_item30
      ,special_info_item31
      ,special_info_item32
      ,special_info_item33
      ,special_info_item34
      ,special_info_item35
      ,special_info_item36
      ,special_info_item37
      ,special_info_item38
      ,special_info_item39
      ,special_info_item40
      ,special_info_item41
      ,special_info_item42
      ,special_info_item43
      ,special_info_item44
      ,special_info_item45
      ,special_info_item46
      ,special_info_item47
      ,special_info_item48
      ,special_info_item49
      ,special_info_item50
      ,special_info_item51
      ,special_info_item52
      ,special_info_item53
      ,special_info_item54
      ,special_info_item55
      ,special_info_item56
      ,special_info_item57
      ,special_info_item58
      ,special_info_item59
      ,special_info_item60
      ,special_info_item61
      ,special_info_item62
      ,special_info_item63
      ,special_info_item64
      ,special_info_item65
      ,special_info_item66
      ,special_info_item67
      ,special_info_item68
      ,special_info_item69
      ,special_info_item70
      ,special_info_item71
      ,special_info_item72
      ,special_info_item73
      ,special_info_item74
      ,special_info_item75
      ,special_info_item76
      ,special_info_item77
      ,special_info_item78
      ,special_info_item79
      ,special_info_item80
      ,special_info_item81
      ,special_info_item82
      ,special_info_item83
      ,special_info_item84
      ,special_info_item85
      ,special_info_item86
      ,special_info_item87
      ,special_info_item88
      ,special_info_item89
      ,special_info_item90
      ,special_info_item91
      ,special_info_item92
      ,special_info_item93
      ,special_info_item94
      ,special_info_item95
      ,special_info_item96
      ,special_info_item97
      ,special_info_item98
      ,special_info_item99
      ,special_info_item100
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
       g_xxcfo_po_data_rec.po_num                                                  -- �����ԍ�
      ,g_xxcfo_po_data_rec.revision_num                                            -- �����ԍ�
      ,gt_authorization_status_name                                                -- ���F�X�e�[�^�X
      ,g_xxcfo_po_data_rec.creation_date                                           -- �����쐬����
      ,g_xxcfo_po_data_rec.vendor_name                                             -- �d����
      ,g_xxcfo_po_data_rec.vendor_site_code                                        -- �d����T�C�g�R�[�h
      ,g_xxcfo_po_data_rec.currency_code                                           -- �ʉ݃R�[�h
      ,g_xxcfo_po_data_rec.full_name                                               -- �w���S��
      ,g_xxcfo_po_data_rec.line_num                                                -- �������הԍ�
      ,SUBSTRB( g_xxcfo_po_data_rec.category_name ,1 ,240 )                        -- �i�ڃJ�e�S��
      ,g_xxcfo_po_data_rec.item_description                                        -- �E�v
      ,g_xxcfo_po_data_rec.quantity_ordered                                        -- ��������
      ,g_xxcfo_po_data_rec.unit_meas_lookup_code                                   -- �P��
      ,g_xxcfo_po_data_rec.unit_price                                              -- ���i
      ,g_xxcfo_po_data_rec.amount                                                  -- ���z
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, gt_un_number
                                                  , g_xxcfo_po_data_rec.vendor_product_num)    -- �d����i��
      ,g_xxcfo_po_data_rec.requisition_num                                         -- �w���˗��ԍ�
      ,g_xxcfo_po_data_rec.apply_location_code                                     -- �\�����_�R�[�h
      ,g_xxcfo_po_data_rec.apply_location_short_name                               -- �\�����_��
      ,g_xxcfo_po_data_rec.shipment_num                                            -- �[�����הԍ�
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, gt_account_number      -- �[�i�ꏊ�R�[�h
                                                  , g_xxcfo_po_data_rec.location_code)
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10
                                                  , SUBSTRB( gt_party_name ,1 , 240 )          -- �[�i�ꏊ��
--MOD_Ver.1.7_2009/12/24_START----------------------------------------------------------------------------
--                                                  , g_xxcfo_po_data_rec.location_short_name)
                                                  , g_xxcfo_po_data_rec.location_name)
--MOD_Ver.1.7_2009/12/24_END------------------------------------------------------------------------------
      ,g_xxcfo_po_data_rec.promised_date                                           -- �[��
      ,g_xxcfo_po_data_rec.need_by_date                                            -- ��]�����
      ,DECODE(g_xxcfo_po_data_rec.attache_judge_code, gv_judge_code_10, 
                                                SUBSTRB(  gt_state                 -- �[�i�ꏊ�Z��
                                                       || gt_city
                                                       || gt_address1
                                                       || gt_address2
                                                        ,1
                                                        ,240
                                                       )
                                                        , g_xxcfo_po_data_rec.address_line1)
      ,gt_standard_po_output                                               -- �W�������o�͍�
      ,CASE WHEN 1   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(1) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 2   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(2) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 3   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(3) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 4   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(4) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 5   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(5) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 6   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(6) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 7   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(7) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 8   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(8) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 9   <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(9) ,1 ,240 )   ELSE NULL END
      ,CASE WHEN 10  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(10) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 11  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(11) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 12  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(12) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 13  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(13) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 14  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(14) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 15  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(15) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 16  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(16) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 17  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(17) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 18  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(18) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 19  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(19) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 20  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(20) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 21  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(21) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 22  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(22) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 23  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(23) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 24  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(24) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 25  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(25) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 26  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(26) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 27  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(27) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 28  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(28) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 29  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(29) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 30  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(30) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 31  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(31) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 32  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(32) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 33  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(33) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 34  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(34) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 35  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(35) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 36  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(36) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 37  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(37) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 38  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(38) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 39  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(39) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 40  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(40) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 41  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(41) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 42  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(42) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 43  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(43) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 44  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(44) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 45  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(45) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 46  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(46) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 47  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(47) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 48  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(48) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 49  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(49) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 50  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(50) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 51  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(51) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 52  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(52) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 53  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(53) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 54  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(54) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 55  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(55) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 56  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(56) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 57  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(57) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 58  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(58) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 59  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(59) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 60  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(60) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 61  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(61) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 62  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(62) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 63  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(63) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 64  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(64) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 65  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(65) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 66  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(66) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 67  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(67) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 68  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(68) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 69  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(69) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 70  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(70) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 71  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(71) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 72  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(72) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 73  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(73) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 74  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(74) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 75  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(75) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 76  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(76) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 77  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(77) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 78  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(78) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 79  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(79) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 80  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(80) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 81  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(81) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 82  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(82) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 83  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(83) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 84  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(84) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 85  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(85) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 86  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(86) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 87  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(87) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 88  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(88) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 89  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(89) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 90  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(90) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 91  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(91) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 92  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(92) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 93  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(93) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 94  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(94) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 95  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(95) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 96  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(96) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 97  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(97) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 98  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(98) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 99  <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(99) ,1 ,240 )  ELSE NULL END
      ,CASE WHEN 100 <= gn_special_info_cnt THEN SUBSTRB( gt_special_info_item(100) ,1 ,240 ) ELSE NULL END
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
                                                     ,gv_msg_cfo_00035     -- �f�[�^�}���G���[
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
  END insert_tmp_standard_data_po;
--
  /**********************************************************************************
   * Procedure Name   : insert_csv_outs_temp
   * Description      : CSV���[�N�e�[�u���f�[�^�o�^ (A-10)
   ***********************************************************************************/
  PROCEDURE insert_csv_outs_temp(
    ov_errbuf     OUT NOCOPY VARCHAR2,        --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,        --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_csv_outs_temp'; -- �v���O������
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
    cv_table   CONSTANT VARCHAR2(100) := 'XXCFR_CSV_OUTS_TEMP'; -- CSV�o�̓��[�N�e�[�u��
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
    --  CSV���[�N�e�[�u���f�[�^�o�^ (A-10)
    -- =====================================================
--
    INSERT INTO xxcfr_csv_outs_temp ( 
       REQUEST_ID
      ,SEQ
      ,COL1                     -- �����ԍ�
      ,COL2                     -- �����ԍ�
      ,COL3                     -- ���F�X�e�[�^�X
      ,COL4                     -- �����쐬����
      ,COL5                     -- �d����
      ,COL6                     -- �d����T�C�g�R�[�h
      ,COL7                     -- �ʉ݃R�[�h
      ,COL8                     -- ���v���z
      ,COL9                     -- �w���S��
      ,COL10                    -- �������הԍ�
      ,COL11                    -- �i�ڃJ�e�S��
      ,COL12                    -- �E�v
      ,COL13                    -- ��������
      ,COL14                    -- �P��
      ,COL15                    -- ���i
      ,COL16                    -- ���z
      ,COL17                    -- �d����i��
      ,COL18                    -- �w���˗��ԍ�
      ,COL19                    -- �\�����_�R�[�h
      ,COL20                    -- �\�����_��
      ,COL21                    -- �[�����הԍ�
      ,COL22                    -- �[�i�ꏊ�R�[�h
      ,COL23                    -- �[�i�ꏊ��
      ,COL24                    -- �[��
      ,COL25                    -- ��]�����
      ,COL26                    -- �[�i�ꏊ�Z��
      ,COL27                    -- �W�������o�͍�
      ,COL28                    -- ���ʏ�񍀖�1
      ,COL29                    -- ���ʏ�񍀖�2
      ,COL30                    -- ���ʏ�񍀖�3
      ,COL31                    -- ���ʏ�񍀖�4
      ,COL32                    -- ���ʏ�񍀖�5
      ,COL33                    -- ���ʏ�񍀖�6
      ,COL34                    -- ���ʏ�񍀖�7
      ,COL35                    -- ���ʏ�񍀖�8
      ,COL36                    -- ���ʏ�񍀖�9
      ,COL37                    -- ���ʏ�񍀖�10
      ,COL38                    -- ���ʏ�񍀖�11
      ,COL39                    -- ���ʏ�񍀖�12
      ,COL40                    -- ���ʏ�񍀖�13
      ,COL41                    -- ���ʏ�񍀖�14
      ,COL42                    -- ���ʏ�񍀖�15
      ,COL43                    -- ���ʏ�񍀖�16
      ,COL44                    -- ���ʏ�񍀖�17
      ,COL45                    -- ���ʏ�񍀖�18
      ,COL46                    -- ���ʏ�񍀖�19
      ,COL47                    -- ���ʏ�񍀖�20
      ,COL48                    -- ���ʏ�񍀖�21
      ,COL49                    -- ���ʏ�񍀖�22
      ,COL50                    -- ���ʏ�񍀖�23
      ,COL51                    -- ���ʏ�񍀖�24
      ,COL52                    -- ���ʏ�񍀖�25
      ,COL53                    -- ���ʏ�񍀖�26
      ,COL54                    -- ���ʏ�񍀖�27
      ,COL55                    -- ���ʏ�񍀖�28
      ,COL56                    -- ���ʏ�񍀖�29
      ,COL57                    -- ���ʏ�񍀖�30
      ,COL58                    -- ���ʏ�񍀖�31
      ,COL59                    -- ���ʏ�񍀖�32
      ,COL60                    -- ���ʏ�񍀖�33
      ,COL61                    -- ���ʏ�񍀖�34
      ,COL62                    -- ���ʏ�񍀖�35
      ,COL63                    -- ���ʏ�񍀖�36
      ,COL64                    -- ���ʏ�񍀖�37
      ,COL65                    -- ���ʏ�񍀖�38
      ,COL66                    -- ���ʏ�񍀖�39
      ,COL67                    -- ���ʏ�񍀖�40
      ,COL68                    -- ���ʏ�񍀖�41
      ,COL69                    -- ���ʏ�񍀖�42
      ,COL70                    -- ���ʏ�񍀖�43
      ,COL71                    -- ���ʏ�񍀖�44
      ,COL72                    -- ���ʏ�񍀖�45
      ,COL73                    -- ���ʏ�񍀖�46
      ,COL74                    -- ���ʏ�񍀖�47
      ,COL75                    -- ���ʏ�񍀖�48
      ,COL76                    -- ���ʏ�񍀖�49
      ,COL77                    -- ���ʏ�񍀖�50
      ,COL78                    -- ���ʏ�񍀖�51
      ,COL79                    -- ���ʏ�񍀖�52
      ,COL80                    -- ���ʏ�񍀖�53
      ,COL81                    -- ���ʏ�񍀖�54
      ,COL82                    -- ���ʏ�񍀖�55
      ,COL83                    -- ���ʏ�񍀖�56
      ,COL84                    -- ���ʏ�񍀖�57
      ,COL85                    -- ���ʏ�񍀖�58
      ,COL86                    -- ���ʏ�񍀖�59
      ,COL87                    -- ���ʏ�񍀖�60
      ,COL88                    -- ���ʏ�񍀖�61
      ,COL89                    -- ���ʏ�񍀖�62
      ,COL90                    -- ���ʏ�񍀖�63
      ,COL91                    -- ���ʏ�񍀖�64
      ,COL92                    -- ���ʏ�񍀖�65
      ,COL93                    -- ���ʏ�񍀖�66
      ,COL94                    -- ���ʏ�񍀖�67
      ,COL95                    -- ���ʏ�񍀖�68
      ,COL96                    -- ���ʏ�񍀖�69
      ,COL97                    -- ���ʏ�񍀖�70
      ,COL98                    -- ���ʏ�񍀖�71
      ,COL99                    -- ���ʏ�񍀖�72
      ,COL100                   -- ���ʏ�񍀖�73
      ,COL101                   -- ���ʏ�񍀖�74
      ,COL102                   -- ���ʏ�񍀖�75
      ,COL103                   -- ���ʏ�񍀖�76
      ,COL104                   -- ���ʏ�񍀖�77
      ,COL105                   -- ���ʏ�񍀖�78
      ,COL106                   -- ���ʏ�񍀖�79
      ,COL107                   -- ���ʏ�񍀖�80
      ,COL108                   -- ���ʏ�񍀖�81
      ,COL109                   -- ���ʏ�񍀖�82
      ,COL110                   -- ���ʏ�񍀖�83
      ,COL111                   -- ���ʏ�񍀖�84
      ,COL112                   -- ���ʏ�񍀖�85
      ,COL113                   -- ���ʏ�񍀖�86
      ,COL114                   -- ���ʏ�񍀖�87
      ,COL115                   -- ���ʏ�񍀖�88
      ,COL116                   -- ���ʏ�񍀖�89
      ,COL117                   -- ���ʏ�񍀖�90
      ,COL118                   -- ���ʏ�񍀖�91
      ,COL119                   -- ���ʏ�񍀖�92
      ,COL120                   -- ���ʏ�񍀖�93
      ,COL121                   -- ���ʏ�񍀖�94
      ,COL122                   -- ���ʏ�񍀖�95
      ,COL123                   -- ���ʏ�񍀖�96
      ,COL124                   -- ���ʏ�񍀖�97
      ,COL125                   -- ���ʏ�񍀖�98
      ,COL126                   -- ���ʏ�񍀖�99
      ,COL127                   -- ���ʏ�񍀖�100
      ,COL128
      ,COL129
      ,COL130
      ,COL131
      ,COL132
      ,COL133
      ,COL134
      ,COL135
      ,COL136
      ,COL137
      ,COL138
      ,COL139
      ,COL140
      ,COL141
      ,COL142
      ,COL143
      ,COL144
      ,COL145
      ,COL146
      ,COL147
      ,COL148
      ,COL149
      ,COL150
    )
    (SELECT gn_conc_request_id                                 -- �v��ID
           ,ROWNUM                                             -- �o�͏�
           ,TO_CHAR(po_num)                                    -- �����ԍ�
           ,TO_CHAR(revision_num)                              -- �����ԍ�
           ,authorization_status_name                          -- ���F�X�e�[�^�X
           ,TO_CHAR(po_creation_date, gv_format_date_ymdhms)   -- �����쐬����
           ,vendor_name                                        -- �d����
           ,vendor_site_code                                   -- �d����T�C�g�R�[�h
           ,currency_code                                      -- �ʉ݃R�[�h
           ,TO_CHAR(sum_amount)                                -- ���v���z
           ,full_name                                          -- �w���S��
           ,TO_CHAR(line_num)                                  -- �������הԍ�
           ,item_category_name                                 -- �i�ڃJ�e�S��
           ,item_description                                   -- �E�v
           ,TO_CHAR(quantity_ordered)                          -- ��������
           ,unit_meas_lookup_code                              -- �P��
           ,TO_CHAR(unit_price)                                -- ���i
           ,TO_CHAR(amount)                                    -- ���z
           ,vendor_product_num                                 -- �d����i��
           ,TO_CHAR(requisition_num)                           -- �w���˗��ԍ�
           ,apply_location_code                                -- �\�����_�R�[�h
           ,apply_location_name                                -- �\�����_��
           ,shipment_num                                       -- �[�����הԍ�
           ,deliver_location_code                              -- �[�i�ꏊ�R�[�h
           ,deliver_location_name                              -- �[�i�ꏊ��
           ,TO_CHAR(promised_date, gv_format_date_ymdhms)      -- �[��
           ,TO_CHAR(need_by_date, gv_format_date_ymdhms)       -- ��]�����
           ,deliver_address                                    -- �[�i�ꏊ�Z��
           ,standard_po_output                                 -- �W�������o�͍�
           ,special_info_item1                                 -- ���ʏ�񍀖�1
           ,special_info_item2                                 -- ���ʏ�񍀖�2
           ,special_info_item3                                 -- ���ʏ�񍀖�3
           ,special_info_item4                                 -- ���ʏ�񍀖�4
           ,special_info_item5                                 -- ���ʏ�񍀖�5
           ,special_info_item6                                 -- ���ʏ�񍀖�6
           ,special_info_item7                                 -- ���ʏ�񍀖�7
           ,special_info_item8                                 -- ���ʏ�񍀖�8
           ,special_info_item9                                 -- ���ʏ�񍀖�9
           ,special_info_item10                                -- ���ʏ�񍀖�10
           ,special_info_item11                                -- ���ʏ�񍀖�11
           ,special_info_item12                                -- ���ʏ�񍀖�12
           ,special_info_item13                                -- ���ʏ�񍀖�13
           ,special_info_item14                                -- ���ʏ�񍀖�14
           ,special_info_item15                                -- ���ʏ�񍀖�15
           ,special_info_item16                                -- ���ʏ�񍀖�16
           ,special_info_item17                                -- ���ʏ�񍀖�17
           ,special_info_item18                                -- ���ʏ�񍀖�18
           ,special_info_item19                                -- ���ʏ�񍀖�19
           ,special_info_item20                                -- ���ʏ�񍀖�20
           ,special_info_item21                                -- ���ʏ�񍀖�21
           ,special_info_item22                                -- ���ʏ�񍀖�22
           ,special_info_item23                                -- ���ʏ�񍀖�23
           ,special_info_item24                                -- ���ʏ�񍀖�24
           ,special_info_item25                                -- ���ʏ�񍀖�25
           ,special_info_item26                                -- ���ʏ�񍀖�26
           ,special_info_item27                                -- ���ʏ�񍀖�27
           ,special_info_item28                                -- ���ʏ�񍀖�28
           ,special_info_item29                                -- ���ʏ�񍀖�29
           ,special_info_item30                                -- ���ʏ�񍀖�30
           ,special_info_item31                                -- ���ʏ�񍀖�31
           ,special_info_item32                                -- ���ʏ�񍀖�32
           ,special_info_item33                                -- ���ʏ�񍀖�33
           ,special_info_item34                                -- ���ʏ�񍀖�34
           ,special_info_item35                                -- ���ʏ�񍀖�35
           ,special_info_item36                                -- ���ʏ�񍀖�36
           ,special_info_item37                                -- ���ʏ�񍀖�37
           ,special_info_item38                                -- ���ʏ�񍀖�38
           ,special_info_item39                                -- ���ʏ�񍀖�39
           ,special_info_item40                                -- ���ʏ�񍀖�40
           ,special_info_item41                                -- ���ʏ�񍀖�41
           ,special_info_item42                                -- ���ʏ�񍀖�42
           ,special_info_item43                                -- ���ʏ�񍀖�43
           ,special_info_item44                                -- ���ʏ�񍀖�44
           ,special_info_item45                                -- ���ʏ�񍀖�45
           ,special_info_item46                                -- ���ʏ�񍀖�46
           ,special_info_item47                                -- ���ʏ�񍀖�47
           ,special_info_item48                                -- ���ʏ�񍀖�48
           ,special_info_item49                                -- ���ʏ�񍀖�49
           ,special_info_item50                                -- ���ʏ�񍀖�50
           ,special_info_item51                                -- ���ʏ�񍀖�51
           ,special_info_item52                                -- ���ʏ�񍀖�52
           ,special_info_item53                                -- ���ʏ�񍀖�53
           ,special_info_item54                                -- ���ʏ�񍀖�54
           ,special_info_item55                                -- ���ʏ�񍀖�55
           ,special_info_item56                                -- ���ʏ�񍀖�56
           ,special_info_item57                                -- ���ʏ�񍀖�57
           ,special_info_item58                                -- ���ʏ�񍀖�58
           ,special_info_item59                                -- ���ʏ�񍀖�59
           ,special_info_item60                                -- ���ʏ�񍀖�60
           ,special_info_item61                                -- ���ʏ�񍀖�61
           ,special_info_item62                                -- ���ʏ�񍀖�62
           ,special_info_item63                                -- ���ʏ�񍀖�63
           ,special_info_item64                                -- ���ʏ�񍀖�64
           ,special_info_item65                                -- ���ʏ�񍀖�65
           ,special_info_item66                                -- ���ʏ�񍀖�66
           ,special_info_item67                                -- ���ʏ�񍀖�67
           ,special_info_item68                                -- ���ʏ�񍀖�68
           ,special_info_item69                                -- ���ʏ�񍀖�69
           ,special_info_item70                                -- ���ʏ�񍀖�70
           ,special_info_item71                                -- ���ʏ�񍀖�71
           ,special_info_item72                                -- ���ʏ�񍀖�72
           ,special_info_item73                                -- ���ʏ�񍀖�73
           ,special_info_item74                                -- ���ʏ�񍀖�74
           ,special_info_item75                                -- ���ʏ�񍀖�75
           ,special_info_item76                                -- ���ʏ�񍀖�76
           ,special_info_item77                                -- ���ʏ�񍀖�77
           ,special_info_item78                                -- ���ʏ�񍀖�78
           ,special_info_item79                                -- ���ʏ�񍀖�79
           ,special_info_item80                                -- ���ʏ�񍀖�80
           ,special_info_item81                                -- ���ʏ�񍀖�81
           ,special_info_item82                                -- ���ʏ�񍀖�82
           ,special_info_item83                                -- ���ʏ�񍀖�83
           ,special_info_item84                                -- ���ʏ�񍀖�84
           ,special_info_item85                                -- ���ʏ�񍀖�85
           ,special_info_item86                                -- ���ʏ�񍀖�86
           ,special_info_item87                                -- ���ʏ�񍀖�87
           ,special_info_item88                                -- ���ʏ�񍀖�88
           ,special_info_item89                                -- ���ʏ�񍀖�89
           ,special_info_item90                                -- ���ʏ�񍀖�90
           ,special_info_item91                                -- ���ʏ�񍀖�91
           ,special_info_item92                                -- ���ʏ�񍀖�92
           ,special_info_item93                                -- ���ʏ�񍀖�93
           ,special_info_item94                                -- ���ʏ�񍀖�94
           ,special_info_item95                                -- ���ʏ�񍀖�95
           ,special_info_item96                                -- ���ʏ�񍀖�96
           ,special_info_item97                                -- ���ʏ�񍀖�97
           ,special_info_item98                                -- ���ʏ�񍀖�98
           ,special_info_item99                                -- ���ʏ�񍀖�99
           ,special_info_item100                               -- ���ʏ�񍀖�100
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
           ,NULL
       FROM (SELECT gn_conc_request_id                     gn_conc_request_id              -- �v��ID
                   ,''                                     sort_num                        -- �o�͏�
                   ,xtsdp1.po_num                          po_num                          -- �����ԍ�
                   ,xtsdp1.revision_num                    revision_num                    -- �����ԍ�
                   ,xtsdp1.authorization_status_name       authorization_status_name       -- ���F�X�e�[�^�X
                   ,xtsdp1.po_creation_date                po_creation_date                -- �����쐬����
                   ,xtsdp1.vendor_name                     vendor_name                     -- �d����
                   ,xtsdp1.vendor_site_code                vendor_site_code                -- �d����T�C�g�R�[�h
                   ,xtsdp1.currency_code                   currency_code                   -- �ʉ݃R�[�h
                   ,sum_xtsdp2.sum_amount                  sum_amount                      -- ���v���z
                   ,xtsdp1.full_name                       full_name                       -- �w���S��
                   ,xtsdp1.line_num                        line_num                        -- �������הԍ�
                   ,xtsdp1.item_category_name              item_category_name              -- �i�ڃJ�e�S��
                   ,xtsdp1.item_description                item_description                -- �E�v
                   ,SUM(xtsdp1.quantity_ordered)           quantity_ordered                -- ��������
                   ,xtsdp1.unit_meas_lookup_code           unit_meas_lookup_code           -- �P��
                   ,xtsdp1.unit_price                      unit_price                      -- ���i
                   ,SUM(xtsdp1.amount)                     amount                          -- ���z
                   ,xtsdp1.vendor_product_num              vendor_product_num              -- �d����i��
                   ,xtsdp1.requisition_num                 requisition_num                 -- �w���˗��ԍ�
                   ,xtsdp1.apply_location_code             apply_location_code             -- �\�����_�R�[�h
                   ,xtsdp1.apply_location_name             apply_location_name             -- �\�����_��
                   ,xtsdp1.shipment_num                    shipment_num                    -- �[�����הԍ�
                   ,xtsdp1.deliver_location_code           deliver_location_code           -- �[�i�ꏊ�R�[�h
                   ,xtsdp1.deliver_location_name           deliver_location_name           -- �[�i�ꏊ��
                   ,xtsdp1.promised_date                   promised_date                   -- �[��
                   ,xtsdp1.need_by_date                    need_by_date                    -- ��]�����
                   ,xtsdp1.deliver_address                 deliver_address                 -- �[�i�ꏊ�Z��
                   ,xtsdp1.standard_po_output              standard_po_output              -- �W�������o�͍�
                   ,xtsdp1.special_info_item1              special_info_item1              -- ���ʏ�񍀖�1
                   ,xtsdp1.special_info_item2              special_info_item2              -- ���ʏ�񍀖�2
                   ,xtsdp1.special_info_item3              special_info_item3              -- ���ʏ�񍀖�3
                   ,xtsdp1.special_info_item4              special_info_item4              -- ���ʏ�񍀖�4
                   ,xtsdp1.special_info_item5              special_info_item5              -- ���ʏ�񍀖�5
                   ,xtsdp1.special_info_item6              special_info_item6              -- ���ʏ�񍀖�6
                   ,xtsdp1.special_info_item7              special_info_item7              -- ���ʏ�񍀖�7
                   ,xtsdp1.special_info_item8              special_info_item8              -- ���ʏ�񍀖�8
                   ,xtsdp1.special_info_item9              special_info_item9              -- ���ʏ�񍀖�9
                   ,xtsdp1.special_info_item10             special_info_item10             -- ���ʏ�񍀖�10
                   ,xtsdp1.special_info_item11             special_info_item11             -- ���ʏ�񍀖�11
                   ,xtsdp1.special_info_item12             special_info_item12             -- ���ʏ�񍀖�12
                   ,xtsdp1.special_info_item13             special_info_item13             -- ���ʏ�񍀖�13
                   ,xtsdp1.special_info_item14             special_info_item14             -- ���ʏ�񍀖�14
                   ,xtsdp1.special_info_item15             special_info_item15             -- ���ʏ�񍀖�15
                   ,xtsdp1.special_info_item16             special_info_item16             -- ���ʏ�񍀖�16
                   ,xtsdp1.special_info_item17             special_info_item17             -- ���ʏ�񍀖�17
                   ,xtsdp1.special_info_item18             special_info_item18             -- ���ʏ�񍀖�18
                   ,xtsdp1.special_info_item19             special_info_item19             -- ���ʏ�񍀖�19
                   ,xtsdp1.special_info_item20             special_info_item20             -- ���ʏ�񍀖�20
                   ,xtsdp1.special_info_item21             special_info_item21             -- ���ʏ�񍀖�21
                   ,xtsdp1.special_info_item22             special_info_item22             -- ���ʏ�񍀖�22
                   ,xtsdp1.special_info_item23             special_info_item23             -- ���ʏ�񍀖�23
                   ,xtsdp1.special_info_item24             special_info_item24             -- ���ʏ�񍀖�24
                   ,xtsdp1.special_info_item25             special_info_item25             -- ���ʏ�񍀖�25
                   ,xtsdp1.special_info_item26             special_info_item26             -- ���ʏ�񍀖�26
                   ,xtsdp1.special_info_item27             special_info_item27             -- ���ʏ�񍀖�27
                   ,xtsdp1.special_info_item28             special_info_item28             -- ���ʏ�񍀖�28
                   ,xtsdp1.special_info_item29             special_info_item29             -- ���ʏ�񍀖�29
                   ,xtsdp1.special_info_item30             special_info_item30             -- ���ʏ�񍀖�30
                   ,xtsdp1.special_info_item31             special_info_item31             -- ���ʏ�񍀖�31
                   ,xtsdp1.special_info_item32             special_info_item32             -- ���ʏ�񍀖�32
                   ,xtsdp1.special_info_item33             special_info_item33             -- ���ʏ�񍀖�33
                   ,xtsdp1.special_info_item34             special_info_item34             -- ���ʏ�񍀖�34
                   ,xtsdp1.special_info_item35             special_info_item35             -- ���ʏ�񍀖�35
                   ,xtsdp1.special_info_item36             special_info_item36             -- ���ʏ�񍀖�36
                   ,xtsdp1.special_info_item37             special_info_item37             -- ���ʏ�񍀖�37
                   ,xtsdp1.special_info_item38             special_info_item38             -- ���ʏ�񍀖�38
                   ,xtsdp1.special_info_item39             special_info_item39             -- ���ʏ�񍀖�39
                   ,xtsdp1.special_info_item40             special_info_item40             -- ���ʏ�񍀖�40
                   ,xtsdp1.special_info_item41             special_info_item41             -- ���ʏ�񍀖�41
                   ,xtsdp1.special_info_item42             special_info_item42             -- ���ʏ�񍀖�42
                   ,xtsdp1.special_info_item43             special_info_item43             -- ���ʏ�񍀖�43
                   ,xtsdp1.special_info_item44             special_info_item44             -- ���ʏ�񍀖�44
                   ,xtsdp1.special_info_item45             special_info_item45             -- ���ʏ�񍀖�45
                   ,xtsdp1.special_info_item46             special_info_item46             -- ���ʏ�񍀖�46
                   ,xtsdp1.special_info_item47             special_info_item47             -- ���ʏ�񍀖�47
                   ,xtsdp1.special_info_item48             special_info_item48             -- ���ʏ�񍀖�48
                   ,xtsdp1.special_info_item49             special_info_item49             -- ���ʏ�񍀖�49
                   ,xtsdp1.special_info_item50             special_info_item50             -- ���ʏ�񍀖�50
                   ,xtsdp1.special_info_item51             special_info_item51             -- ���ʏ�񍀖�51
                   ,xtsdp1.special_info_item52             special_info_item52             -- ���ʏ�񍀖�52
                   ,xtsdp1.special_info_item53             special_info_item53             -- ���ʏ�񍀖�53
                   ,xtsdp1.special_info_item54             special_info_item54             -- ���ʏ�񍀖�54
                   ,xtsdp1.special_info_item55             special_info_item55             -- ���ʏ�񍀖�55
                   ,xtsdp1.special_info_item56             special_info_item56             -- ���ʏ�񍀖�56
                   ,xtsdp1.special_info_item57             special_info_item57             -- ���ʏ�񍀖�57
                   ,xtsdp1.special_info_item58             special_info_item58             -- ���ʏ�񍀖�58
                   ,xtsdp1.special_info_item59             special_info_item59             -- ���ʏ�񍀖�59
                   ,xtsdp1.special_info_item60             special_info_item60             -- ���ʏ�񍀖�60
                   ,xtsdp1.special_info_item61             special_info_item61             -- ���ʏ�񍀖�61
                   ,xtsdp1.special_info_item62             special_info_item62             -- ���ʏ�񍀖�62
                   ,xtsdp1.special_info_item63             special_info_item63             -- ���ʏ�񍀖�63
                   ,xtsdp1.special_info_item64             special_info_item64             -- ���ʏ�񍀖�64
                   ,xtsdp1.special_info_item65             special_info_item65             -- ���ʏ�񍀖�65
                   ,xtsdp1.special_info_item66             special_info_item66             -- ���ʏ�񍀖�66
                   ,xtsdp1.special_info_item67             special_info_item67             -- ���ʏ�񍀖�67
                   ,xtsdp1.special_info_item68             special_info_item68             -- ���ʏ�񍀖�68
                   ,xtsdp1.special_info_item69             special_info_item69             -- ���ʏ�񍀖�69
                   ,xtsdp1.special_info_item70             special_info_item70             -- ���ʏ�񍀖�70
                   ,xtsdp1.special_info_item71             special_info_item71             -- ���ʏ�񍀖�71
                   ,xtsdp1.special_info_item72             special_info_item72             -- ���ʏ�񍀖�72
                   ,xtsdp1.special_info_item73             special_info_item73             -- ���ʏ�񍀖�73
                   ,xtsdp1.special_info_item74             special_info_item74             -- ���ʏ�񍀖�74
                   ,xtsdp1.special_info_item75             special_info_item75             -- ���ʏ�񍀖�75
                   ,xtsdp1.special_info_item76             special_info_item76             -- ���ʏ�񍀖�76
                   ,xtsdp1.special_info_item77             special_info_item77             -- ���ʏ�񍀖�77
                   ,xtsdp1.special_info_item78             special_info_item78             -- ���ʏ�񍀖�78
                   ,xtsdp1.special_info_item79             special_info_item79             -- ���ʏ�񍀖�79
                   ,xtsdp1.special_info_item80             special_info_item80             -- ���ʏ�񍀖�80
                   ,xtsdp1.special_info_item81             special_info_item81             -- ���ʏ�񍀖�81
                   ,xtsdp1.special_info_item82             special_info_item82             -- ���ʏ�񍀖�82
                   ,xtsdp1.special_info_item83             special_info_item83             -- ���ʏ�񍀖�83
                   ,xtsdp1.special_info_item84             special_info_item84             -- ���ʏ�񍀖�84
                   ,xtsdp1.special_info_item85             special_info_item85             -- ���ʏ�񍀖�85
                   ,xtsdp1.special_info_item86             special_info_item86             -- ���ʏ�񍀖�86
                   ,xtsdp1.special_info_item87             special_info_item87             -- ���ʏ�񍀖�87
                   ,xtsdp1.special_info_item88             special_info_item88             -- ���ʏ�񍀖�88
                   ,xtsdp1.special_info_item89             special_info_item89             -- ���ʏ�񍀖�89
                   ,xtsdp1.special_info_item90             special_info_item90             -- ���ʏ�񍀖�90
                   ,xtsdp1.special_info_item91             special_info_item91             -- ���ʏ�񍀖�91
                   ,xtsdp1.special_info_item92             special_info_item92             -- ���ʏ�񍀖�92
                   ,xtsdp1.special_info_item93             special_info_item93             -- ���ʏ�񍀖�93
                   ,xtsdp1.special_info_item94             special_info_item94             -- ���ʏ�񍀖�94
                   ,xtsdp1.special_info_item95             special_info_item95             -- ���ʏ�񍀖�95
                   ,xtsdp1.special_info_item96             special_info_item96             -- ���ʏ�񍀖�96
                   ,xtsdp1.special_info_item97             special_info_item97             -- ���ʏ�񍀖�97
                   ,xtsdp1.special_info_item98             special_info_item98             -- ���ʏ�񍀖�98
                   ,xtsdp1.special_info_item99             special_info_item99             -- ���ʏ�񍀖�99
                   ,xtsdp1.special_info_item100            special_info_item100            -- ���ʏ�񍀖�100
               FROM xxcfo_tmp_standard_data_po        xtsdp1        -- �������f�[�^�o�̓��[�N�e�[�u��
                   ,(SELECT xtsdp2.po_num                    po_num
                           ,xtsdp2.org_id                    org_id
                           ,SUM(xtsdp2.amount)               sum_amount
                       FROM xxcfo_tmp_standard_data_po    xtsdp2    -- �������f�[�^�o�̓��[�N�e�[�u��
                      GROUP BY xtsdp2.po_num
                              ,xtsdp2.org_id
                    ) sum_xtsdp2
              WHERE xtsdp1.po_num = sum_xtsdp2.po_num
                AND xtsdp1.org_id = sum_xtsdp2.org_id
              GROUP BY xtsdp1.po_num
                      ,xtsdp1.revision_num
                      ,xtsdp1.authorization_status_name
                      ,xtsdp1.po_creation_date
                      ,xtsdp1.vendor_name
                      ,xtsdp1.vendor_site_code
                      ,xtsdp1.currency_code
                      ,sum_xtsdp2.sum_amount
                      ,xtsdp1.full_name
                      ,xtsdp1.line_num
                      ,xtsdp1.item_category_name
                      ,xtsdp1.item_description
                      ,xtsdp1.unit_meas_lookup_code
                      ,xtsdp1.unit_price
                      ,xtsdp1.vendor_product_num
                      ,xtsdp1.requisition_num
                      ,xtsdp1.apply_location_code
                      ,xtsdp1.apply_location_name
                      ,xtsdp1.shipment_num
                      ,xtsdp1.deliver_location_code
                      ,xtsdp1.deliver_location_name
                      ,xtsdp1.promised_date
                      ,xtsdp1.need_by_date
                      ,xtsdp1.deliver_address
                      ,xtsdp1.standard_po_output
                      ,xtsdp1.special_info_item1
                      ,xtsdp1.special_info_item2
                      ,xtsdp1.special_info_item3
                      ,xtsdp1.special_info_item4
                      ,xtsdp1.special_info_item5
                      ,xtsdp1.special_info_item6
                      ,xtsdp1.special_info_item7
                      ,xtsdp1.special_info_item8
                      ,xtsdp1.special_info_item9
                      ,xtsdp1.special_info_item10
                      ,xtsdp1.special_info_item11
                      ,xtsdp1.special_info_item12
                      ,xtsdp1.special_info_item13
                      ,xtsdp1.special_info_item14
                      ,xtsdp1.special_info_item15
                      ,xtsdp1.special_info_item16
                      ,xtsdp1.special_info_item17
                      ,xtsdp1.special_info_item18
                      ,xtsdp1.special_info_item19
                      ,xtsdp1.special_info_item20
                      ,xtsdp1.special_info_item21
                      ,xtsdp1.special_info_item22
                      ,xtsdp1.special_info_item23
                      ,xtsdp1.special_info_item24
                      ,xtsdp1.special_info_item25
                      ,xtsdp1.special_info_item26
                      ,xtsdp1.special_info_item27
                      ,xtsdp1.special_info_item28
                      ,xtsdp1.special_info_item29
                      ,xtsdp1.special_info_item30
                      ,xtsdp1.special_info_item31
                      ,xtsdp1.special_info_item32
                      ,xtsdp1.special_info_item33
                      ,xtsdp1.special_info_item34
                      ,xtsdp1.special_info_item35
                      ,xtsdp1.special_info_item36
                      ,xtsdp1.special_info_item37
                      ,xtsdp1.special_info_item38
                      ,xtsdp1.special_info_item39
                      ,xtsdp1.special_info_item40
                      ,xtsdp1.special_info_item41
                      ,xtsdp1.special_info_item42
                      ,xtsdp1.special_info_item43
                      ,xtsdp1.special_info_item44
                      ,xtsdp1.special_info_item45
                      ,xtsdp1.special_info_item46
                      ,xtsdp1.special_info_item47
                      ,xtsdp1.special_info_item48
                      ,xtsdp1.special_info_item49
                      ,xtsdp1.special_info_item50
                      ,xtsdp1.special_info_item51
                      ,xtsdp1.special_info_item52
                      ,xtsdp1.special_info_item53
                      ,xtsdp1.special_info_item54
                      ,xtsdp1.special_info_item55
                      ,xtsdp1.special_info_item56
                      ,xtsdp1.special_info_item57
                      ,xtsdp1.special_info_item58
                      ,xtsdp1.special_info_item59
                      ,xtsdp1.special_info_item60
                      ,xtsdp1.special_info_item61
                      ,xtsdp1.special_info_item62
                      ,xtsdp1.special_info_item63
                      ,xtsdp1.special_info_item64
                      ,xtsdp1.special_info_item65
                      ,xtsdp1.special_info_item66
                      ,xtsdp1.special_info_item67
                      ,xtsdp1.special_info_item68
                      ,xtsdp1.special_info_item69
                      ,xtsdp1.special_info_item70
                      ,xtsdp1.special_info_item71
                      ,xtsdp1.special_info_item72
                      ,xtsdp1.special_info_item73
                      ,xtsdp1.special_info_item74
                      ,xtsdp1.special_info_item75
                      ,xtsdp1.special_info_item76
                      ,xtsdp1.special_info_item77
                      ,xtsdp1.special_info_item78
                      ,xtsdp1.special_info_item79
                      ,xtsdp1.special_info_item80
                      ,xtsdp1.special_info_item81
                      ,xtsdp1.special_info_item82
                      ,xtsdp1.special_info_item83
                      ,xtsdp1.special_info_item84
                      ,xtsdp1.special_info_item85
                      ,xtsdp1.special_info_item86
                      ,xtsdp1.special_info_item87
                      ,xtsdp1.special_info_item88
                      ,xtsdp1.special_info_item89
                      ,xtsdp1.special_info_item90
                      ,xtsdp1.special_info_item91
                      ,xtsdp1.special_info_item92
                      ,xtsdp1.special_info_item93
                      ,xtsdp1.special_info_item94
                      ,xtsdp1.special_info_item95
                      ,xtsdp1.special_info_item96
                      ,xtsdp1.special_info_item97
                      ,xtsdp1.special_info_item98
                      ,xtsdp1.special_info_item99
                      ,xtsdp1.special_info_item100
            )
    );
--
    IF (SQL%ROWCOUNT = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo       -- 'XXCFO'
                                                     ,gv_msg_cfo_00035     -- �f�[�^�}���G���[
                                                     ,gv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table)
                                                                           -- �������f�[�^�o�̓��[�N�e�[�u��
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
  END insert_csv_outs_temp;
--
  /**********************************************************************************
   * Procedure Name   : out_put_file
   * Description      : OUT�t�@�C���o�͏��� (A-11)
   ***********************************************************************************/
  PROCEDURE out_put_file(
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_put_file'; -- �v���O������
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
    xxcfr_common_pkg.csv_out( gn_conc_request_id     -- �v��ID
                             ,gv_lookup_type4        -- �Q�ƃ^�C�v
                             ,gn_target_cnt          -- ��������
                             ,lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
                             ,lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
                             ,lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = cv_status_normal) THEN
--
      gn_normal_cnt := gn_target_cnt;
--
    ELSE
      RAISE global_api_expt;
--
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
  END out_put_file;
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
       iv_po_creation_date_from           -- �����쐬��From
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
    --  �����f�[�^�擾(A-3)
    -- =====================================================
    -- ����������
    gn_target_cnt := 0;
--
    ln_po_agent_code         := TO_NUMBER(iv_po_agent_code);                               -- �����쐬��
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
      -- ����������
      -- �z���NULL��INSERT���悤�Ƃ���ƃG���[�ŗ�����ׁA�����������Ƃ��Ēl��������B
      -- ���AINSERT����CASE��p����NULL��INSERT�o����悤�ɃR�[�f�B���O����B
      FOR ln_i IN 1..100 LOOP
        gt_special_info_item(ln_i) := ' ';
      END LOOP;
      gn_special_info_cnt := 0;
--
      IF   (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10    -- ���̋@
        OR  g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_20    -- �Œ莑�Y
        OR  g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_30)   -- ���h
      THEN
--
        -- =====================================================
        --  �Y�t���擾����(A-4)
        -- =====================================================
        get_attache_info(
           lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        -- =====================================================
        --  �Y�t���ҏW����(A-5)
        -- =====================================================
        edit_attache_info(
           lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = cv_status_error) THEN
          --(�G���[����)
          RAISE global_process_expt;
        END IF;
--
        -- ���̋@�̏ꍇ
        IF (g_xxcfo_po_data_rec.attache_judge_code = gv_judge_code_10) THEN
          -- =====================================================
          --  �ڋq���擾����(A-6)
          -- =====================================================
          get_customer_info(
             lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
          -- =====================================================
          --  �@����擾����(A-7)
          -- =====================================================
          get_un_info(
             lv_errbuf                             -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode                            -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg);                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
          END IF;
--
        END IF;
      END IF;
--
      -- =====================================================
      --  �X�e�[�^�X�Ǘ��e�[�u���f�[�^�o�^(A-8)
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
          IF (lv_retcode = cv_status_error) THEN
            --(�G���[����)
            RAISE global_process_expt;
--
          ELSE
            -- �o�^�ł����ꍇ�A�����ԍ��E�g�DID��ێ�����B
            gn_po_num_in_count            := gn_po_num_in_count + 1;
            gt_po_num(gn_po_num_in_count) := lt_po_num;
            gt_org_id(gn_po_num_in_count) := lt_org_id;
--
          END IF;
--
        END IF;
      END IF;
--
      -- =====================================================
      --  �������f�[�^�o�̓��[�N�e�[�u���f�[�^�o�^(A-9)
      -- =====================================================
      insert_tmp_standard_data_po(
         lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
    IF po_data_cur%ISOPEN THEN
      CLOSE po_data_cur;
    END IF;
--
    -- �x���I��
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( gv_msg_kbn_cfo     -- �A�v���P�[�V�����Z�k���FXXCFO
                                                     ,gv_msg_cfo_00004   -- �Ώۃf�[�^�����G���[
                                                    )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    ELSE
      -- =====================================================
      --  CSV���[�N�e�[�u���f�[�^�o�^(A-10)
      -- =====================================================
      insert_csv_outs_temp(
         lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
--
      -- =====================================================
      --  OUT�t�@�C���o�͏���(A-11)
      -- =====================================================
      out_put_file(
         lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg);                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = cv_status_error) THEN
        --(�G���[����)
        RAISE global_process_expt;
      END IF;
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
    --  �I������(A-13)
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
END XXCFO016A02C;
/
