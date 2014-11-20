CREATE OR REPLACE PACKAGE BODY XXCFF015A34C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF015A34C(body)
 * Description      : ���̋@���[�X���\�Z�쐬
 * MD.050           : ���̋@���[�X���\�Z�쐬 MD050_CFF_015_A34
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������                       (A-1)
 *  get_if_data            �t�@�C���A�b�v���[�hI/F�擾    (A-2)
 *  divide_delimiter       �f���~�^�������ڕ���           (A-3)
 *  chk_data               �f�[�^�Ó����`�F�b�N           (A-4)
 *  ins_lease_budget_wk    ���[�X���\�Z���[�N�쐬         (A-6)
 *  del_object_code_data   �o�͑ΏۊO�����R�[�h�f�[�^�폜 (A-7)
 *  upd_scrap_data         �p�����f�[�^�X�V               (A-8)
 *  create_output_file     �o�̓t�@�C���쐬               (A-9)
 *  del_if_data            �t�@�C���A�b�v���[�hI/F�폜    (A-10)
 *  del_lease_budget_wk    ���[�X���\�Z���[�N�폜         (A-11)
 *  set_g_lease_budget_tab ���[�X���\�Z�p���i�[�z��ݒ�p�v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *                         ���[�X���\�Z���o               (A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������                       (A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/11/25    1.0   SCSK ��������    �V�K�쐬
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
  lock_expt                 EXCEPTION; -- ���b�N�擾��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCFF015A34C';     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cff    CONSTANT VARCHAR2(5)   := 'XXCFF';            --�A�h�I���F��v�E���[�X�EFA�̈�
  -- ���b�Z�[�W��(�{��)
  cv_msg_xxcff_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  cv_msg_xxcff_00020        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_xxcff_00094        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094'; -- ���ʊ֐��G���[
  cv_msg_xxcff_00110        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00110'; -- �f�[�^�ϊ��G���[
  cv_msg_xxcff_00165        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^����
  cv_msg_xxcff_00167        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167'; -- �A�b�v���[�h�t�@�C�����
  cv_msg_xxcff_00189        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189'; -- �Q�ƃ^�C�v�擾�G���[
  cv_msg_xxcff_00190        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00190'; -- ���݃`�F�b�N�G���[
  -- ���b�Z�[�W��(�g�[�N��)
  cv_msg_xxcff_50130        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130'; -- ��������
  cv_msg_xxcff_50131        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131'; -- BLOB�f�[�^�ϊ��p�֐�
  cv_msg_xxcff_50175        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175'; -- �t�@�C���A�b�v���[�hI/F�e�[�u��
  cv_msg_xxcff_50189        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50189'; -- ���[�X���\�ZCSV�f�[�^���o
  cv_msg_xxcff_50190        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50190'; -- ���[�X���\�Z
  cv_msg_xxcff_50191        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50191'; -- ���̋@���[�X���\�Z�쐬_�w�b�_
  cv_msg_xxcff_50192        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50192'; -- ���̋@���[�X���\�Z�쐬_���ׁi�V�K�䐔�j
  cv_msg_xxcff_50193        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50193'; -- ���̋@���[�X���\�Z�쐬�o�͍���
  cv_msg_xxcff_50194        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50194'; -- ���Y��v�N�x
  cv_msg_xxcff_50195        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50195'; -- �n��R�[�h
  cv_msg_xxcff_50196        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50196'; -- ���_�R�[�h
  cv_msg_xxcff_50197        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50197'; -- ���[�X���\�Z���[�N
  cv_msg_xxcff_50198        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50198'; -- XXCFF:���̋@���[�X���\�Z�쐬�o���N����
  -- �g�[�N��
  cv_tkn_prof               CONSTANT VARCHAR2(10)  := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_table_name         CONSTANT VARCHAR2(10)  := 'TABLE_NAME';       -- �e�[�u����
  cv_tkn_func_name          CONSTANT VARCHAR2(10)  := 'FUNC_NAME';        -- �@�\��
  cv_tkn_info               CONSTANT VARCHAR2(10)  := 'INFO';             -- �G���[���b�Z�[�W
  cv_tkn_appl_name          CONSTANT VARCHAR2(10)  := 'APPL_NAME';        -- �A�v���P�[�V������
  cv_tkn_get_data           CONSTANT VARCHAR2(10)  := 'GET_DATA';         -- �e�[�u����
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_csv_name           CONSTANT VARCHAR2(10)  := 'CSV_NAME';         -- CSV�t�@�C����
  cv_tkn_lookup_type        CONSTANT VARCHAR2(11)  := 'LOOKUP_TYPE';      -- �Q�ƃ^�C�v��
  cv_tkn_input              CONSTANT VARCHAR2(10)  := 'INPUT';            -- �R�[�h��
  cv_tkn_column_data        CONSTANT VARCHAR2(11)  := 'COLUMN_DATA';      -- �R�[�h�l
  -- �Q�ƃ^�C�v
  cv_lookup_budget_head     CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_HEAD';        -- ���̋@���[�X���\�Z�쐬�w�b�_
  cv_lookup_budget_line     CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_LINE';        -- ���̋@���[�X���\�Z�쐬���ׁi�V�K�䐔�j
  cv_lookup_budget_itemname CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_ITEMNAME';    -- ���̋@���[�X���\�Z�쐬�Œ�l
  cv_lookup_budget_no_code  CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_NO_OBJCODE';  -- ���̋@���[�X���\�Z�쐬�o�͑ΏۊO�����R�[�h
  cv_lookup_chiku_code      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_CHIKU_CODE';           -- �n��R�[�h
  -- �v���t�@�C��
  cv_bulk_collect_cnt       CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_BULK_COUNT';  -- XXCFF:���̋@���[�X���\�Z�쐬�o���N����
  cv_aff_cust_code          CONSTANT VARCHAR2(30)  := 'XXCSO1_AFF_CUST_CODE';            -- XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j
  cv_msg_aff_cust_code      CONSTANT VARCHAR2(40)  := 'XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j'; -- ���b�Z�[�W�o��
  -- �l�Z�b�g
  cv_department             CONSTANT VARCHAR2(40)  := 'XX03_DEPARTMENT';   -- ����
  -- ���Y��v�N�x��
  cv_fiscal_year_name       CONSTANT VARCHAR2(30)  := 'XXCFF_FISCAL_YEAR'; -- ���Y��v�N�x��
  -- �o�͋敪
  cv_file_type_log          CONSTANT VARCHAR2(3)   := 'LOG';     -- ���O
  -- ��؂蕶��
  cv_kanma                  CONSTANT VARCHAR2(1)   := ',';       -- �J���}
  cv_wqt                    CONSTANT VARCHAR2(1)   := '"';       -- �_�u���N�H�[�e�[�V����
  cv_persent                CONSTANT VARCHAR2(1)   := '%';       -- �p�[�Z���g
  -- �t���O
  cv_flag_on                CONSTANT VARCHAR2(1)   := 'Y';       -- 'Y'
  -- ���t�t�H�[�}�b�g
  cv_format_yyyymm          CONSTANT VARCHAR2(7)   := 'YYYY-MM'; -- �N��
  -- �ڋq�X�e�[�^�X
  cv_cust_status_a          CONSTANT VARCHAR2(1)   := 'A';       -- �ڋq(�L��)
  -- �ڋq�ڍs���X�e�[�^�X
  cv_cust_shift_status_a    CONSTANT VARCHAR2(1)   := 'A';       -- �ڋq�ڍs���(�m��)
  -- �����X�e�[�^�X
  cv_object_status_101      CONSTANT VARCHAR2(3)   := '101';     -- ���_��
  cv_object_status_104      CONSTANT VARCHAR2(3)   := '104';     -- �ă��[�X�_���
  cv_object_status_110      CONSTANT VARCHAR2(3)   := '110';     -- ���r���(���ȓs��)
  -- �x���ƍ��t���O
  cv_payment_match_flag_1   CONSTANT VARCHAR2(1)   := '1';       -- �x���ƍ��t���O
  -- ���[�X���
  cv_lease_class_11         CONSTANT VARCHAR2(2)   := '11';      -- ���̋@
  cv_lease_class_12         CONSTANT VARCHAR2(2)   := '12';      -- �V���[�P�[�X
  -- ���[�X�敪
  cv_lease_type_1           CONSTANT VARCHAR2(1)   := '1';       -- ���_��
  cv_lease_type_2           CONSTANT VARCHAR2(1)   := '2';       -- �ă��[�X
  -- �ă��[�X�v�t���O
  cv_re_lease_flag_0        CONSTANT VARCHAR2(1)   := '0';       -- �ă��[�X����
  cv_re_lease_flag_1        CONSTANT VARCHAR2(1)   := '1';       -- �ă��[�X���Ȃ�
  -- �W�v�P��
  cv_group_unit_1           CONSTANT VARCHAR2(1)   := '1';       -- ������
  cv_group_unit_2           CONSTANT VARCHAR2(1)   := '2';       -- ���_��
  -- ���R�[�h�敪
  cv_record_type_1          CONSTANT VARCHAR2(1)   := '1';       -- �擾
  cv_record_type_2          CONSTANT VARCHAR2(1)   := '2';       -- �V�~�����[�V����
  cv_record_type_3          CONSTANT VARCHAR2(1)   := '3';       -- �V�K
  cv_record_type_4          CONSTANT VARCHAR2(1)   := '4';       -- ���_�v(�䐔)
  cv_record_type_5          CONSTANT VARCHAR2(1)   := '5';       -- ���_�v(���[�X��)
  -- �p�����X�V�敪
  cv_update_type_1          CONSTANT VARCHAR2(1)   := '1';       -- ��v�N�x�X�V
  cv_update_type_2          CONSTANT VARCHAR2(1)   := '2';       -- �ȑO�N�x�X�V
  -- ���_�����
  cn_lease_type_1_year      CONSTANT NUMBER        := 5;         -- ���_�����
  -- ����
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ��������ї��N�x����`
  TYPE g_next_year_rtype IS RECORD(
     year                            NUMBER(4)
    ,this_may                        VARCHAR2(7)
    ,this_june                       VARCHAR2(7)
    ,this_july                       VARCHAR2(7)
    ,this_august                     VARCHAR2(7)
    ,this_september                  VARCHAR2(7)
    ,this_october                    VARCHAR2(7)
    ,this_november                   VARCHAR2(7)
    ,this_december                   VARCHAR2(7)
    ,this_january                    VARCHAR2(7)
    ,this_february                   VARCHAR2(7)
    ,this_march                      VARCHAR2(7)
    ,this_april                      VARCHAR2(7)
    ,may                             VARCHAR2(7)
    ,june                            VARCHAR2(7)
    ,july                            VARCHAR2(7)
    ,august                          VARCHAR2(7)
    ,september                       VARCHAR2(7)
    ,october                         VARCHAR2(7)
    ,november                        VARCHAR2(7)
    ,december                        VARCHAR2(7)
    ,january                         VARCHAR2(7)
    ,february                        VARCHAR2(7)
    ,march                           VARCHAR2(7)
    ,april                           VARCHAR2(7)
  );
  -- ���̋@���[�X���\�Z�쐬�w�b�_��`
  TYPE g_lookup_budget_head_ttype    IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  -- ���̋@���[�X���\�Z�쐬���ׁi�V�K�䐔�j��`
  TYPE g_lookup_budget_line_ttype    IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  -- ���̋@���[�X���\�Z�쐬�Œ�l��`
  TYPE g_lookup_budget_itemnm_ttype  IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY PLS_INTEGER;
  -- ���̋@���[�X���\�Z�쐬�o�͑ΏۊO�����R�[�h��`
  TYPE g_lookup_budget_objcode_ttype IS TABLE OF fnd_lookup_values.meaning%TYPE INDEX BY PLS_INTEGER;
  -- �������ڕ�����w�b�_�f�[�^��`
  TYPE g_load_head_data_rtype IS RECORD(
     lease_class                     xxcff_lease_budget_work.lease_class%TYPE
    ,lease_type                      xxcff_object_headers.lease_type%TYPE
    ,chiku_code                      hz_locations.address3%TYPE
    ,department_code                 xxcff_lease_budget_work.department_code%TYPE
    ,group_unit                      VARCHAR2(1)
  );
  -- �p�����X�V�p��`
  TYPE g_update_scrap_rtype IS RECORD(
     update_type                     VARCHAR2(1)
    ,lease_class                     xxcff_lease_budget_work.lease_class%TYPE
    ,year                            NUMBER(4)
    ,persent                         NUMBER
  );
  TYPE g_update_scrap_ttype                   IS TABLE OF g_update_scrap_rtype INDEX BY PLS_INTEGER;
  -- ���[�X���\�Z�p��`
  TYPE g_lease_budget_rtype IS RECORD(
     record_type                     xxcff_lease_budget_work.record_type%TYPE
    ,lease_class                     xxcff_lease_budget_work.lease_class%TYPE
    ,lease_class_name                xxcff_lease_budget_work.lease_class_name%TYPE
    ,lease_type                      xxcff_lease_budget_work.lease_type%TYPE
    ,lease_type_name                 xxcff_lease_budget_work.lease_type_name%TYPE
    ,chiku_code                      xxcff_lease_budget_work.chiku_code%TYPE
    ,department_code                 xxcff_lease_budget_work.department_code%TYPE
    ,department_name                 xxcff_lease_budget_work.department_name%TYPE
    ,object_name                     xxcff_lease_budget_work.object_name%TYPE
    ,lease_start_year                xxcff_lease_budget_work.lease_start_year%TYPE
    ,lease_end_months                VARCHAR2(7)
    ,re_lease_times                  xxcff_object_headers.re_lease_times%TYPE
    ,re_lease_flag                   xxcff_object_headers.re_lease_flag%TYPE
    ,lease_type_1_charge             NUMBER
    ,may_charge                      xxcff_lease_budget_work.may_charge%TYPE       DEFAULT 0
    ,may_number                      xxcff_lease_budget_work.may_number%TYPE       DEFAULT 0
    ,june_charge                     xxcff_lease_budget_work.june_charge%TYPE      DEFAULT 0
    ,june_number                     xxcff_lease_budget_work.june_number%TYPE      DEFAULT 0
    ,july_charge                     xxcff_lease_budget_work.july_charge%TYPE      DEFAULT 0
    ,july_number                     xxcff_lease_budget_work.july_number%TYPE      DEFAULT 0
    ,august_charge                   xxcff_lease_budget_work.august_charge%TYPE    DEFAULT 0
    ,august_number                   xxcff_lease_budget_work.august_number%TYPE    DEFAULT 0
    ,september_charge                xxcff_lease_budget_work.september_charge%TYPE DEFAULT 0
    ,september_number                xxcff_lease_budget_work.september_number%TYPE DEFAULT 0
    ,october_charge                  xxcff_lease_budget_work.october_charge%TYPE   DEFAULT 0
    ,october_number                  xxcff_lease_budget_work.october_number%TYPE   DEFAULT 0
    ,november_charge                 xxcff_lease_budget_work.november_charge%TYPE  DEFAULT 0
    ,november_number                 xxcff_lease_budget_work.november_number%TYPE  DEFAULT 0
    ,december_charge                 xxcff_lease_budget_work.december_charge%TYPE  DEFAULT 0
    ,december_number                 xxcff_lease_budget_work.december_number%TYPE  DEFAULT 0
    ,january_charge                  xxcff_lease_budget_work.january_charge%TYPE   DEFAULT 0
    ,january_number                  xxcff_lease_budget_work.january_number%TYPE   DEFAULT 0
    ,february_charge                 xxcff_lease_budget_work.february_charge%TYPE  DEFAULT 0
    ,february_number                 xxcff_lease_budget_work.february_number%TYPE  DEFAULT 0
    ,march_charge                    xxcff_lease_budget_work.march_charge%TYPE     DEFAULT 0
    ,march_number                    xxcff_lease_budget_work.march_number%TYPE     DEFAULT 0
    ,april_charge                    xxcff_lease_budget_work.april_charge%TYPE     DEFAULT 0
    ,april_number                    xxcff_lease_budget_work.april_number%TYPE     DEFAULT 0
    ,cust_shift_date                 VARCHAR2(7)
    ,new_base_code                   xxcff_lease_budget_work.department_code%TYPE
    ,new_department_name             xxcff_lease_budget_work.department_name%TYPE
  );
  TYPE g_lease_budget_ttype          IS TABLE OF g_lease_budget_rtype INDEX BY PLS_INTEGER;
  -- �o�̓t�@�C���p��`
  TYPE g_out_rtype IS RECORD(
     lease_class_name                xxcff_lease_budget_work.lease_class_name%TYPE
    ,lease_type_name                 xxcff_lease_budget_work.lease_type_name%TYPE
    ,department_code                 xxcff_lease_budget_work.department_code%TYPE
    ,department_name                 xxcff_lease_budget_work.department_name%TYPE
    ,object_name                     xxcff_lease_budget_work.object_name%TYPE
    ,may                             NUMBER
    ,june                            NUMBER
    ,july                            NUMBER
    ,august                          NUMBER
    ,september                       NUMBER
    ,october                         NUMBER
    ,november                        NUMBER
    ,december                        NUMBER
    ,january                         NUMBER
    ,february                        NUMBER
    ,march                           NUMBER
    ,april                           NUMBER
  );
  TYPE g_out_ttype                   IS TABLE OF g_out_rtype INDEX BY PLS_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_aff_cust_code                   VARCHAR2(9) DEFAULT NULL; -- AFF�ڋq�R�[�h�i��`�Ȃ��j
  gn_bulk_collect_cnt                NUMBER      DEFAULT 0;    -- ���̋@���[�X���\�Z�쐬�o���N����
  gn_line_cnt                        NUMBER      DEFAULT 0;    -- ���[�X���\�Z�p���J�E���^�[
  -- �����������i�[�z��
  g_init_rec                         xxcff_common1_pkg.init_rtype;
  -- ��������ї��N�x���i�[�z��
  g_next_year_rec                    g_next_year_rtype;
  -- ���̋@���[�X���\�Z�쐬�w�b�_�i�[�z��
  g_lookup_budget_head_tab           g_lookup_budget_head_ttype;
  -- ���̋@���[�X���\�Z�쐬���ׁi�V�K�䐔�j�i�[�z��
  g_lookup_budget_line_tab           g_lookup_budget_line_ttype;
  -- ���̋@���[�X���\�Z�쐬�Œ�l�i�[�z��
  g_lookup_budget_itemnm_tab         g_lookup_budget_itemnm_ttype;
  -- ���̋@���[�X���\�Z�쐬�o�͑ΏۊO�����R�[�h�i�[�z��
  g_lookup_budget_objcode_tab        g_lookup_budget_objcode_ttype;
  -- �t�@�C���A�b�v���[�h�f�[�^�i�[�z��
  g_file_data_tab                    xxccp_common_pkg2.g_file_data_tbl;
  -- �������ڕ�����w�b�_�f�[�^�i�[�z��
  g_lord_head_data_rec               g_load_head_data_rtype;
  -- �p�����X�V�p���i�[�z��
  g_update_scrap_tab                 g_update_scrap_ttype;
  -- ���[�X���\�Z�p���i�[�z��(�o���N�p)
  g_lease_budget_bulk_tab            g_lease_budget_ttype;
  -- ���[�X���\�Z�p���i�[�z��
  g_lease_budget_tab                 g_lease_budget_ttype;
  -- �o�͏��i�[�z��
  g_out_tab                          g_out_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    iv_file_format IN  VARCHAR2,     -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_file_name                     xxccp_mrp_file_ul_interface.file_name%TYPE; -- �A�b�v���[�hCSV�t�@�C����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬�w�b�_)�擾�J�[�\��
    CURSOR lookup_budget_head_cur
    IS
      SELECT TO_NUMBER(flv.meaning) AS index_num
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_head
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
      ORDER BY flv.lookup_code
    ;
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬���ׁi�V�K�䐔�j)�擾�J�[�\��
    CURSOR lookup_budget_line_cur
    IS
      SELECT TO_NUMBER(flv.meaning) AS index_num
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_line
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
      ORDER BY flv.lookup_code
    ;
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬�Œ�l)�擾�J�[�\��
    CURSOR lookup_budget_itemname_cur
    IS
      SELECT flv.description        AS item_name
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_itemname
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
      ORDER BY flv.lookup_code
    ;
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬�o�͑ΏۊO�����R�[�h)�擾�J�[�\��
    CURSOR lookup_budget_objcode_cur
    IS
      SELECT flv.meaning            AS object_code
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_no_code
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
    ;
    -- ��������ї��N�x���擾�J�[�\��
    CURSOR next_year_cur
    IS
      SELECT ffy.fiscal_year                                            AS year           -- ��v�N�x
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -12), cv_format_yyyymm) AS this_may       -- ���N�x5��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -11), cv_format_yyyymm) AS this_june      -- ���N�x6��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -10), cv_format_yyyymm) AS this_july      -- ���N�x7��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -9),  cv_format_yyyymm) AS this_august    -- ���N�x8��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -8),  cv_format_yyyymm) AS this_september -- ���N�x9��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -7),  cv_format_yyyymm) AS this_october   -- ���N�x10��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -6),  cv_format_yyyymm) AS this_november  -- ���N�x11��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -5),  cv_format_yyyymm) AS this_december  -- ���N�x12��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -4),  cv_format_yyyymm) AS this_january   -- ���N�x1��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -3),  cv_format_yyyymm) AS this_february  -- ���N�x2��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -2),  cv_format_yyyymm) AS this_march     -- ���N�x3��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -1),  cv_format_yyyymm) AS this_april     -- ���N�x4��
           , TO_CHAR(ffy.start_date,                  cv_format_yyyymm) AS may            -- 5��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 1),   cv_format_yyyymm) AS june           -- 6��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 2),   cv_format_yyyymm) AS july           -- 7��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 3),   cv_format_yyyymm) AS august         -- 8��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 4),   cv_format_yyyymm) AS september      -- 9��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 5),   cv_format_yyyymm) AS october        -- 10��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 6),   cv_format_yyyymm) AS november       -- 11��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 7),   cv_format_yyyymm) AS december       -- 12��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 8),   cv_format_yyyymm) AS january        -- 1��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 9),   cv_format_yyyymm) AS february       -- 2��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 10),  cv_format_yyyymm) AS march          -- 3��
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 11),  cv_format_yyyymm) AS april          -- 4��
      FROM  fa_fiscal_year ffy                                                            -- ���Y��v�N�x
      WHERE ffy.fiscal_year_name = cv_fiscal_year_name                                    -- ��v�N�x
      AND   ADD_MONTHS(g_init_rec.process_date, 12) BETWEEN ffy.start_date                -- �J�n��
                                                        AND ffy.end_date                  -- �I����
    ;
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
    --======================================================
    -- �A�b�v���[�hCSV�t�@�C�����擾
    --======================================================
    BEGIN
      SELECT xfui.file_name                   -- �A�b�v���[�hCSV�t�@�C����
      INTO   lv_file_name
      FROM   xxccp_mrp_file_ul_interface xfui -- �t�@�C���A�b�v���[�hI/F
      WHERE  xfui.file_id = in_file_id        -- �t�@�C��ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_short_name_cff
                               ,iv_name         => cv_msg_xxcff_00165
                               ,iv_token_name1  => cv_tkn_get_data
                               ,iv_token_value1 => cv_msg_xxcff_50175)
                                                     , 1
                                                     , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_short_name_cff
                               ,iv_name         => cv_msg_xxcff_00007
                               ,iv_token_name1  => cv_tkn_table_name
                               ,iv_token_value1 => cv_msg_xxcff_50175)
                                                     , 1
                                                     , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --======================================================
    -- ���O�o�̓��b�Z�[�W�擾
    --======================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_cff
                           ,iv_name         => cv_msg_xxcff_00167
                           ,iv_token_name1  => cv_tkn_file_name
                           ,iv_token_value1 => cv_msg_xxcff_50189
                           ,iv_token_name2  => cv_tkn_csv_name
                           ,iv_token_value2 => lv_file_name)
                                                 ,1
                                                 ,5000);
    -- ���O�o��
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
--
    --======================================================
    -- �R���J�����g�p�����[�^�l�o��(���O)
    --======================================================
    xxcff_common1_pkg.put_log_param(
       iv_which   => cv_file_type_log -- �o�͋敪
      ,ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- ���ʊ֐�[��������]�̌Ăяo��
    --======================================================
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec
      ,ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00094
                             ,iv_token_name1  => cv_tkn_func_name
                             ,iv_token_value1 => cv_msg_xxcff_50130)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬�w�b�_)�擾
    --======================================================
    OPEN lookup_budget_head_cur;
    FETCH lookup_budget_head_cur BULK COLLECT INTO g_lookup_budget_head_tab;
    CLOSE lookup_budget_head_cur;
    --
    IF ( g_lookup_budget_head_tab.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00189
                             ,iv_token_name1  => cv_tkn_lookup_type
                             ,iv_token_value1 => cv_lookup_budget_head)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬���ׁi�V�K�䐔�j)�擾
    --======================================================
    OPEN lookup_budget_line_cur;
    FETCH lookup_budget_line_cur BULK COLLECT INTO g_lookup_budget_line_tab;
    CLOSE lookup_budget_line_cur;
    --
    IF ( g_lookup_budget_line_tab.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00189
                             ,iv_token_name1  => cv_tkn_lookup_type
                             ,iv_token_value1 => cv_lookup_budget_line)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬�Œ�l)�擾
    --======================================================
    OPEN lookup_budget_itemname_cur;
    FETCH lookup_budget_itemname_cur BULK COLLECT INTO g_lookup_budget_itemnm_tab;
    CLOSE lookup_budget_itemname_cur;
    --
    IF ( g_lookup_budget_itemnm_tab.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00189
                             ,iv_token_name1  => cv_tkn_lookup_type
                             ,iv_token_value1 => cv_lookup_budget_itemname)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- �Q�ƃ^�C�v(���̋@���[�X���\�Z�쐬�o�͑ΏۊO�����R�[�h)�擾
    --======================================================
    OPEN lookup_budget_objcode_cur;
    FETCH lookup_budget_objcode_cur BULK COLLECT INTO g_lookup_budget_objcode_tab;
    CLOSE lookup_budget_objcode_cur;
--
    --======================================================
    -- ��������ї��N�x�擾
    --======================================================
    OPEN next_year_cur;
    FETCH next_year_cur INTO g_next_year_rec;
    CLOSE next_year_cur;
    --
    IF ( g_next_year_rec.year IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00165
                             ,iv_token_name1  => cv_tkn_get_data
                             ,iv_token_value1 => cv_msg_xxcff_50194)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- XXCFF:���̋@���[�X���\�Z�쐬�o���N����
    --======================================================
    gn_bulk_collect_cnt := TO_NUMBER(FND_PROFILE.VALUE(cv_bulk_collect_cnt));
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gn_bulk_collect_cnt IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00020
                             ,iv_token_name1  => cv_tkn_prof
                             ,iv_token_value1 => cv_msg_xxcff_50198)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- XXCSO:AFF�ڋq�R�[�h�i��`�Ȃ��j
    --======================================================
    gv_aff_cust_code := FND_PROFILE.VALUE(cv_aff_cust_code);
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_aff_cust_code IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00020
                             ,iv_token_name1  => cv_tkn_prof
                             ,iv_token_value1 => cv_msg_aff_cust_code)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ****
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lookup_budget_head_cur%ISOPEN ) THEN
        CLOSE lookup_budget_head_cur;
      END IF;
      IF ( lookup_budget_line_cur%ISOPEN ) THEN
        CLOSE lookup_budget_line_cur;
      END IF;
      IF ( lookup_budget_itemname_cur%ISOPEN ) THEN
        CLOSE lookup_budget_itemname_cur;
      END IF;
      IF ( lookup_budget_objcode_cur%ISOPEN ) THEN
        CLOSE lookup_budget_objcode_cur;
      END IF;
      IF ( next_year_cur%ISOPEN ) THEN
        CLOSE next_year_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hI/F�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --======================================================
    -- BLOB�f�[�^�ϊ�
    --======================================================
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id      -- �t�@�C���h�c
      ,ov_file_data => g_file_data_tab -- �ϊ���VARCHAR2�f�[�^
      ,ov_retcode   => lv_retcode
      ,ov_errbuf    => lv_errbuf
      ,ov_errmsg    => lv_errmsg
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00110
                             ,iv_token_name1  => cv_tkn_appl_name
                             ,iv_token_value1 => cv_msg_xxcff_50131
                             ,iv_token_name2  => cv_tkn_info
                             ,iv_token_value2 => lv_errmsg)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_delimiter
   * Description      : �f���~�^�������ڕ��� (A-3)
   ***********************************************************************************/
  PROCEDURE divide_delimiter(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_delimiter'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lv_head_data                     VARCHAR2(100) DEFAULT NULL; -- �w�b�_�f�[�^
    lv_line_data                     VARCHAR2(100) DEFAULT NULL; -- ���׃f�[�^
    ln_vd_year_1                     NUMBER        DEFAULT 0;    -- ���̋@_�N1
    ln_vd_year_2                     NUMBER        DEFAULT 0;    -- ���̋@_�N2
    ln_vd_year_3                     NUMBER        DEFAULT 0;    -- ���̋@_�N3
    ln_sh_year_1                     NUMBER        DEFAULT 0;    -- �V���[�P�[�X_�N1
    ln_sh_year_2                     NUMBER        DEFAULT 0;    -- �V���[�P�[�X_�N2
    ln_sh_year_3                     NUMBER        DEFAULT 0;    -- �V���[�P�[�X_�N3
    ln_vd_lease_charge               NUMBER        DEFAULT 0;    -- �V�䃊�[�X��_���̋@
    ln_sh_lease_charge               NUMBER        DEFAULT 0;    -- �V�䃊�[�X��_�V���[�P�[�X
    ln_scrap_cnt                     NUMBER        DEFAULT 0;    -- �p�����X�V�J�E���^�[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --======================================================
    -- �f���~�^�������ڕ���
    --======================================================
    <<g_file_data_tab_loop>>
    FOR i IN g_file_data_tab.FIRST .. g_file_data_tab.LAST LOOP
      -- �w�b�_�s�i�P�s�̂݁j
      IF ( i = 1 ) THEN
        -- �Ώی����J�E���g�A�b�v
        gn_target_cnt := 1;
        --
        <<char_delim_head_loop>>
        FOR j IN g_lookup_budget_head_tab.FIRST .. g_lookup_budget_head_tab.LAST LOOP
          -- ������
          lv_head_data := NULL;
          --
          lv_head_data := xxccp_common_pkg.char_delim_partition(
                             iv_char     => g_file_data_tab(i)
                            ,iv_delim    => cv_kanma
                            ,in_part_num => g_lookup_budget_head_tab(j)
                          );
          --
          IF    ( j = 1 ) THEN
            g_lord_head_data_rec.lease_class     := lv_head_data; -- ���[�X���
          ELSIF ( j = 2 ) THEN
            g_lord_head_data_rec.lease_type      := lv_head_data; -- ���[�X�敪
          ELSIF ( j = 3 ) THEN
            g_lord_head_data_rec.chiku_code      := lv_head_data; -- �n��R�[�h
          ELSIF ( j = 4 ) THEN
            g_lord_head_data_rec.department_code := lv_head_data; -- ���_�R�[�h
          ELSIF ( j = 5 ) THEN
            g_lord_head_data_rec.group_unit      := lv_head_data; -- �W�v�P��
          ELSIF ( j = 6 ) THEN
            ln_vd_year_1                                   := TO_NUMBER(lv_head_data);                 -- ���̋@_�N1
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_11;                       -- �p�������_���[�X���
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_vd_year_1 
                                                                + 1 );                                 -- �p�������_�N
          ELSIF ( j = 7 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- �p�������_%
          ELSIF ( j = 8 ) THEN
            ln_vd_year_2                                   := TO_NUMBER(lv_head_data);                 -- ���̋@_�N2
            IF    ( ( ln_vd_year_1 IS NOT NULL )
              AND   ( ln_vd_year_2 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- �p�������_�X�V�敪
            ELSIF ( ( ln_vd_year_1 IS NOT NULL )
              AND   ( ln_vd_year_2 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- �p�������_�X�V�敪
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_11;                       -- �p�������_���[�X���
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_vd_year_2 
                                                                + 1 );                                 -- �p�������_�N
          ELSIF ( j = 9 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- �p�������_%
          ELSIF ( j = 10 ) THEN
            ln_vd_year_3                                   := TO_NUMBER(lv_head_data);                 -- ���̋@_�N3
            IF    ( ( ln_vd_year_2 IS NOT NULL )
              AND   ( ln_vd_year_3 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- �p�������_�X�V�敪
            ELSIF ( ( ln_vd_year_2 IS NOT NULL )
              AND   ( ln_vd_year_3 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- �p�������_�X�V�敪
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- �p�������_�X�V�敪
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_11;                       -- �p�������_���[�X���
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_vd_year_3 
                                                                + 1 );                                 -- �p�������_�N
            IF ( ln_vd_year_3 IS NOT NULL ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- �p�������_�X�V�敪
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- �p�������_�X�V�敪
            END IF;
          ELSIF ( j = 11 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- �p�������_%
          ELSIF ( j = 12 ) THEN
            ln_sh_year_1                                   := TO_NUMBER(lv_head_data);                 -- �V���[�P�[�X_�N1
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_12;                       -- �p�������_���[�X���
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_sh_year_1 
                                                                + 1 );                                 -- �p�������_�N
          ELSIF ( j = 13 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- �p�������_%
          ELSIF ( j = 14 ) THEN
            ln_sh_year_2                                   := TO_NUMBER(lv_head_data);                 -- �V���[�P�[�X_�N2
            IF    ( ( ln_sh_year_1 IS NOT NULL )
              AND   ( ln_sh_year_2 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- �p�������_�X�V�敪
            ELSIF ( ( ln_sh_year_1 IS NOT NULL )
              AND   ( ln_sh_year_2 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- �p�������_�X�V�敪
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_12;                       -- �p�������_���[�X���
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year 
                                                                - ln_sh_year_2 
                                                                + 1 );                                 -- �p�������_�N
          ELSIF ( j = 15 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- �p�������_%
          ELSIF ( j = 16 ) THEN
            ln_sh_year_3                                   := TO_NUMBER(lv_head_data);                 -- �V���[�P�[�X_�N3
            IF    ( ( ln_sh_year_2 IS NOT NULL )
              AND   ( ln_sh_year_3 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- �p�������_�X�V�敪
            ELSIF ( ( ln_sh_year_2 IS NOT NULL )
              AND   ( ln_sh_year_3 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- �p�������_�X�V�敪
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- �p�������_�X�V�敪
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_12;                       -- �p�������_���[�X���
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year 
                                                                - ln_sh_year_3 
                                                                + 1 );                                 -- �p�������_�N
            IF ( ln_sh_year_3 IS NOT NULL ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- �p�������_�X�V�敪
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- �p�������_�X�V�敪
            END IF;
          ELSIF ( j = 17 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- �p�������_%
          ELSIF ( j = 18 ) THEN
            ln_vd_lease_charge                             := TO_NUMBER(lv_head_data);                 -- �V�䃊�[�X��_���̋@
          ELSIF ( j = 19 ) THEN
            ln_sh_lease_charge                             := TO_NUMBER(lv_head_data);                 -- �V�䃊�[�X��_�V���[�P�[�X
          END IF;
        END LOOP char_delim_head_loop;
      -- ���ׁi�V�K�䐔�j�s
      ELSE
        -- �Ώی����J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
        --
        <<char_delim_line_loop>>
        FOR k IN g_lookup_budget_line_tab.FIRST .. g_lookup_budget_line_tab.LAST LOOP
          lv_line_data := xxccp_common_pkg.char_delim_partition(
                             iv_char     => g_file_data_tab(i)
                            ,iv_delim    => cv_kanma
                            ,in_part_num => g_lookup_budget_line_tab(k)
                          );
          -- �`�F�b�N�Ώۂ̏ꍇ�̂�
          IF ( k = 1 ) THEN
            -- �z��J�E���g�A�b�v
            gn_line_cnt := gn_line_cnt + 1;
            g_lease_budget_tab(gn_line_cnt).record_type        := cv_record_type_3;                -- ���R�[�h�敪
            g_lease_budget_tab(gn_line_cnt).lease_class        := lv_line_data;                    -- ���[�X���
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).lease_class_name := g_lookup_budget_itemnm_tab(19);  -- ���[�X��ʖ�
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).lease_class_name := g_lookup_budget_itemnm_tab(20);  -- ���[�X��ʖ�
            END IF;
            -- �W�v�P�ʂ����_�̏ꍇ
            IF ( g_lord_head_data_rec.group_unit = cv_group_unit_2 ) THEN
              g_lease_budget_tab(gn_line_cnt).lease_type       := cv_lease_type_1;                 -- ���[�X�敪
              g_lease_budget_tab(gn_line_cnt).lease_type_name  := g_lookup_budget_itemnm_tab(21);  -- ���[�X�敪��
            ELSE
              g_lease_budget_tab(gn_line_cnt).lease_type       := NULL;                            -- ���[�X�敪
              g_lease_budget_tab(gn_line_cnt).lease_type_name  := NULL;                            -- ���[�X�敪��
            END IF;
          ELSIF ( k = 2 ) THEN
            g_lease_budget_tab(gn_line_cnt).chiku_code         := NULL;                            -- �n��R�[�h
            g_lease_budget_tab(gn_line_cnt).department_code    := lv_line_data;                    -- ���_�R�[�h
            g_lease_budget_tab(gn_line_cnt).department_name    := NULL;                            -- ���_��
            g_lease_budget_tab(gn_line_cnt).object_name        := g_lookup_budget_itemnm_tab(23);  -- �����R�[�h
            g_lease_budget_tab(gn_line_cnt).lease_start_year   := NULL;                            -- ���[�X�J�n�N�x
          ELSIF ( ( k >= 3 ) AND ( k <= 15 ) ) THEN
            g_lease_budget_tab(gn_line_cnt).may_number         := NVL(g_lease_budget_tab(gn_line_cnt).may_number, 0) +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 5��_�䐔(���N�x5���`���N�x5���̌v)
            IF  ( k = 15 ) THEN
              IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
                g_lease_budget_tab(gn_line_cnt).may_charge
                  := ( g_lease_budget_tab(gn_line_cnt).may_number * ln_vd_lease_charge );          -- 5��_���[�X��
              ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
                g_lease_budget_tab(gn_line_cnt).may_charge
                  := ( g_lease_budget_tab(gn_line_cnt).may_number * ln_sh_lease_charge );          -- 5��_���[�X��
              END IF;
            END IF;
          ELSIF ( k = 16 ) THEN
            g_lease_budget_tab(gn_line_cnt).june_number        := g_lease_budget_tab(gn_line_cnt).may_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 6��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).june_charge
                := ( g_lease_budget_tab(gn_line_cnt).june_number * ln_vd_lease_charge );           -- 6��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).june_charge
                := ( g_lease_budget_tab(gn_line_cnt).june_number * ln_sh_lease_charge );           -- 6��_���[�X��
            END IF;
          ELSIF ( k = 17 ) THEN
            g_lease_budget_tab(gn_line_cnt).july_number        := g_lease_budget_tab(gn_line_cnt).june_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 7��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).july_charge
                := ( g_lease_budget_tab(gn_line_cnt).july_number * ln_vd_lease_charge );           -- 7��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).july_charge
                := ( g_lease_budget_tab(gn_line_cnt).july_number * ln_sh_lease_charge );           -- 7��_���[�X��
            END IF;
          ELSIF ( k = 18 ) THEN
            g_lease_budget_tab(gn_line_cnt).august_number      := g_lease_budget_tab(gn_line_cnt).july_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 8��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).august_charge
                := ( g_lease_budget_tab(gn_line_cnt).august_number * ln_vd_lease_charge );         -- 8��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).august_charge
                := ( g_lease_budget_tab(gn_line_cnt).august_number * ln_sh_lease_charge );         -- 8��_���[�X��
            END IF;
          ELSIF ( k = 19 ) THEN
            g_lease_budget_tab(gn_line_cnt).september_number   := g_lease_budget_tab(gn_line_cnt).august_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 9��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).september_charge
                := ( g_lease_budget_tab(gn_line_cnt).september_number * ln_vd_lease_charge );      -- 9��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).september_charge
                := ( g_lease_budget_tab(gn_line_cnt).september_number * ln_sh_lease_charge );      -- 9��_���[�X��
            END IF;
          ELSIF ( k = 20 ) THEN
            g_lease_budget_tab(gn_line_cnt).october_number     := g_lease_budget_tab(gn_line_cnt).september_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 10��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).october_charge
                := ( g_lease_budget_tab(gn_line_cnt).october_number * ln_vd_lease_charge );        -- 10��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).october_charge
                := ( g_lease_budget_tab(gn_line_cnt).october_number * ln_sh_lease_charge );        -- 10��_���[�X��
            END IF;
          ELSIF ( k = 21 ) THEN
            g_lease_budget_tab(gn_line_cnt).november_number    := g_lease_budget_tab(gn_line_cnt).october_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 11��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).november_charge
                := ( g_lease_budget_tab(gn_line_cnt).november_number * ln_vd_lease_charge );       -- 11��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).november_charge
                := ( g_lease_budget_tab(gn_line_cnt).november_number * ln_sh_lease_charge );       -- 11��_���[�X��
            END IF;
          ELSIF ( k = 22 ) THEN
            g_lease_budget_tab(gn_line_cnt).december_number    := g_lease_budget_tab(gn_line_cnt).november_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 12��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).december_charge
                := ( g_lease_budget_tab(gn_line_cnt).december_number * ln_vd_lease_charge );       -- 12��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).december_charge
                := ( g_lease_budget_tab(gn_line_cnt).december_number * ln_sh_lease_charge );       -- 12��_���[�X��
            END IF;
          ELSIF ( k = 23 ) THEN
            g_lease_budget_tab(gn_line_cnt).january_number     := g_lease_budget_tab(gn_line_cnt).december_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 1��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).january_charge
               := ( g_lease_budget_tab(gn_line_cnt).january_number * ln_vd_lease_charge );         -- 1��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).january_charge
               := ( g_lease_budget_tab(gn_line_cnt).january_number * ln_sh_lease_charge );         -- 1��_���[�X��
            END IF;
          ELSIF ( k = 24 ) THEN
            g_lease_budget_tab(gn_line_cnt).february_number    := g_lease_budget_tab(gn_line_cnt).january_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 2��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).february_charge
               := ( g_lease_budget_tab(gn_line_cnt).february_number * ln_vd_lease_charge );        -- 2��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).february_charge
               := ( g_lease_budget_tab(gn_line_cnt).february_number * ln_sh_lease_charge );        -- 2��_���[�X��
            END IF;
          ELSIF ( k = 25 ) THEN
            g_lease_budget_tab(gn_line_cnt).march_number       := g_lease_budget_tab(gn_line_cnt).february_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 3��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).march_charge
               := ( g_lease_budget_tab(gn_line_cnt).march_number * ln_vd_lease_charge );           -- 3��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).march_charge
               := ( g_lease_budget_tab(gn_line_cnt).march_number * ln_sh_lease_charge );           -- 3��_���[�X��
            END IF;
          ELSIF ( k = 26 ) THEN
            g_lease_budget_tab(gn_line_cnt).april_number       := g_lease_budget_tab(gn_line_cnt).march_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 4��_�䐔
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).april_charge
               := ( g_lease_budget_tab(gn_line_cnt).april_number * ln_vd_lease_charge );           -- 4��_���[�X��
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).april_charge
               := ( g_lease_budget_tab(gn_line_cnt).april_number * ln_sh_lease_charge );           -- 4��_���[�X��
            END IF;
          END IF;
        END LOOP char_delim_line_loop;
      END IF;
    END LOOP g_file_data_tab_loop;
    -- �z��f�[�^�폜
    g_lookup_budget_head_tab.DELETE;
    g_lookup_budget_line_tab.DELETE;
    g_file_data_tab.DELETE;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END divide_delimiter;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : �f�[�^�Ó����`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lv_chk                           VARCHAR2(240) DEFAULT NULL; -- �`�F�b�N�p�ϐ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --======================================================
    -- �Ó����`�F�b�N
    --======================================================
    -- �n��R�[�h���ݒ肳��Ă���ꍇ
    IF ( g_lord_head_data_rec.chiku_code IS NOT NULL ) THEN
      BEGIN
        SELECT flv.description   AS item_name
        INTO   lv_chk
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type  = cv_lookup_chiku_code
        AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                       AND NVL(flv.end_date_active, g_init_rec.process_date)
        AND    flv.enabled_flag = cv_flag_on
        AND    flv.language     = ct_language
        AND    flv.lookup_code  = g_lord_head_data_rec.chiku_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_short_name_cff
                                 ,iv_name         => cv_msg_xxcff_00190
                                 ,iv_token_name1  => cv_tkn_input
                                 ,iv_token_value1 => cv_msg_xxcff_50195
                                 ,iv_token_name2  => cv_tkn_column_data
                                 ,iv_token_value2 => g_lord_head_data_rec.chiku_code)
                                                       , 1
                                                       , 5000);
          FND_FILE.PUT_LINE(
            which => FND_FILE.LOG
           ,buff  => lv_errmsg
          );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END IF;
    -- ���_�R�[�h���ݒ肳��Ă���ꍇ
    IF ( g_lord_head_data_rec.department_code IS NOT NULL ) THEN
      BEGIN
        SELECT xdv.department_name AS department_name
        INTO   lv_chk
        FROM   xxcff_department_v  xdv
        WHERE  xdv.department_code = g_lord_head_data_rec.department_code
        AND    xdv.enabled_flag    = cv_flag_on
        AND    g_init_rec.process_date BETWEEN NVL(xdv.start_date_active, g_init_rec.process_date)
                                       AND NVL(xdv.end_date_active, g_init_rec.process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_short_name_cff
                                 ,iv_name         => cv_msg_xxcff_00190
                                 ,iv_token_name1  => cv_tkn_input
                                 ,iv_token_value1 => cv_msg_xxcff_50196
                                 ,iv_token_name2  => cv_tkn_column_data
                                 ,iv_token_value2 => g_lord_head_data_rec.department_code)
                                                       , 1
                                                       , 5000);
          FND_FILE.PUT_LINE(
            which => FND_FILE.LOG
           ,buff  => lv_errmsg
          );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END IF;
    -- �V�K�䐔(���_�R�[�h)�����݂���ꍇ
    IF ( g_lease_budget_tab.COUNT > 0 ) THEN
      <<chk_line_data_loop>>
      FOR j IN g_lease_budget_tab.FIRST .. g_lease_budget_tab.LAST LOOP
        IF ( g_lease_budget_tab(j).department_code IS NOT NULL ) THEN
          BEGIN
            SELECT xdv.department_name AS department_name
            INTO   g_lease_budget_tab(j).department_name
            FROM   xxcff_department_v  xdv
            WHERE  xdv.department_code = g_lease_budget_tab(j).department_code
            AND    xdv.enabled_flag    = cv_flag_on
            AND    g_init_rec.process_date BETWEEN NVL(xdv.start_date_active, g_init_rec.process_date)
                                           AND NVL(xdv.end_date_active, g_init_rec.process_date)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_appl_short_name_cff
                                     ,iv_name         => cv_msg_xxcff_00190
                                     ,iv_token_name1  => cv_tkn_input
                                     ,iv_token_value1 => cv_msg_xxcff_50196
                                     ,iv_token_name2  => cv_tkn_column_data
                                     ,iv_token_value2 => g_lease_budget_tab(j).department_code)
                                                           , 1
                                                           , 5000);
              FND_FILE.PUT_LINE(
                which => FND_FILE.LOG
               ,buff  => lv_errmsg
              );
              ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_error;
          END;
        END IF;
      END LOOP chk_line_data_loop;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_lease_budget_wk
   * Description      : ���[�X���\�Z���[�N�쐬 (A-6)
   ***********************************************************************************/
  PROCEDURE ins_lease_budget_wk(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lease_budget_wk'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    ln_seqno                         NUMBER DEFAULT 0; -- �ʔ�
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�X���\�Z���[�N�ő�ʔԎ擾
    SELECT NVL(MAX(xlbw.seqno), 0)
    INTO   ln_seqno
    FROM   xxcff_lease_budget_work xlbw
    ;
    --
    --======================================================
    -- ���[�X���\�Z���[�N�f�[�^�}������
    --======================================================
    IF ( g_lease_budget_tab.COUNT > 0 ) THEN
      <<insert_lease_wk_loop>>
      FOR i IN g_lease_budget_tab.FIRST .. g_lease_budget_tab.LAST LOOP
        ln_seqno := ln_seqno + 1;
        --
        INSERT INTO xxcff_lease_budget_work(
           seqno
          ,record_type
          ,lease_class
          ,lease_class_name
          ,lease_type
          ,lease_type_name
          ,chiku_code
          ,department_code
          ,department_name
          ,object_name
          ,lease_start_year
          ,may_charge
          ,may_number
          ,june_charge
          ,june_number
          ,july_charge
          ,july_number
          ,august_charge
          ,august_number
          ,september_charge
          ,september_number
          ,october_charge
          ,october_number
          ,november_charge
          ,november_number
          ,december_charge
          ,december_number
          ,january_charge
          ,january_number
          ,february_charge
          ,february_number
          ,march_charge
          ,march_number
          ,april_charge
          ,april_number
          ,file_id
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date
        )VALUES(
           ln_seqno
          ,g_lease_budget_tab(i).record_type
          ,g_lease_budget_tab(i).lease_class
          ,g_lease_budget_tab(i).lease_class_name
          ,g_lease_budget_tab(i).lease_type
          ,g_lease_budget_tab(i).lease_type_name
          ,g_lease_budget_tab(i).chiku_code
          ,g_lease_budget_tab(i).department_code
          ,g_lease_budget_tab(i).department_name
          ,g_lease_budget_tab(i).object_name
          ,g_lease_budget_tab(i).lease_start_year
          ,g_lease_budget_tab(i).may_charge
          ,g_lease_budget_tab(i).may_number
          ,g_lease_budget_tab(i).june_charge
          ,g_lease_budget_tab(i).june_number
          ,g_lease_budget_tab(i).july_charge
          ,g_lease_budget_tab(i).july_number
          ,g_lease_budget_tab(i).august_charge
          ,g_lease_budget_tab(i).august_number
          ,g_lease_budget_tab(i).september_charge
          ,g_lease_budget_tab(i).september_number
          ,g_lease_budget_tab(i).october_charge
          ,g_lease_budget_tab(i).october_number
          ,g_lease_budget_tab(i).november_charge
          ,g_lease_budget_tab(i).november_number
          ,g_lease_budget_tab(i).december_charge
          ,g_lease_budget_tab(i).december_number
          ,g_lease_budget_tab(i).january_charge
          ,g_lease_budget_tab(i).january_number
          ,g_lease_budget_tab(i).february_charge
          ,g_lease_budget_tab(i).february_number
          ,g_lease_budget_tab(i).march_charge
          ,g_lease_budget_tab(i).march_number
          ,g_lease_budget_tab(i).april_charge
          ,g_lease_budget_tab(i).april_number
          ,in_file_id
          ,cn_created_by
          ,cd_creation_date
          ,cn_last_updated_by
          ,cd_last_update_date
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
         );
      END LOOP insert_lease_wk_loop;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_lease_budget_wk;
--
  /**********************************************************************************
   * Procedure Name   : del_object_code_data
   * Description      : �o�͑ΏۊO�����R�[�h�f�[�^�폜 (A-7)
   ***********************************************************************************/
  PROCEDURE del_object_code_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_object_code_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    --======================================================
    -- �o�͑ΏۊO�����R�[�h�f�[�^�폜����
    --======================================================
    <<delete_object_code_loop>>
    FOR i IN 1 .. g_lookup_budget_objcode_tab.COUNT LOOP
      DELETE FROM xxcff_lease_budget_work xlbw -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id     =    in_file_id  -- �t�@�C��ID
      AND    xlbw.object_name LIKE g_lookup_budget_objcode_tab(i) || cv_persent
      ;
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_object_code_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_scrap_data
   * Description      : �p�����f�[�^�X�V (A-8)
   ***********************************************************************************/
  PROCEDURE upd_scrap_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_scrap_data'; -- �v���O������
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
    --======================================================
    -- �p�����f�[�^�X�V����
    --======================================================
    <<update_scrap_loop>>
    FOR i IN 1 .. g_update_scrap_tab.COUNT LOOP
      -- ���[�X�J�n�N�x�ƈ�v�N�x�X�V
      IF ( g_update_scrap_tab(i).update_type = cv_update_type_1 ) THEN
        UPDATE xxcff_lease_budget_work xlbw
        SET    xlbw.may_charge             = ROUND(xlbw.may_charge       - ( xlbw.may_charge       * g_update_scrap_tab(i).persent ))
             , xlbw.june_charge            = ROUND(xlbw.june_charge      - ( xlbw.june_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.july_charge            = ROUND(xlbw.july_charge      - ( xlbw.july_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.august_charge          = ROUND(xlbw.august_charge    - ( xlbw.august_charge    * g_update_scrap_tab(i).persent ))
             , xlbw.september_charge       = ROUND(xlbw.september_charge - ( xlbw.september_charge * g_update_scrap_tab(i).persent ))
             , xlbw.october_charge         = ROUND(xlbw.october_charge   - ( xlbw.october_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.november_charge        = ROUND(xlbw.november_charge  - ( xlbw.november_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.december_charge        = ROUND(xlbw.december_charge  - ( xlbw.december_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.january_charge         = ROUND(xlbw.january_charge   - ( xlbw.january_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.february_charge        = ROUND(xlbw.february_charge  - ( xlbw.february_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.march_charge           = ROUND(xlbw.march_charge     - ( xlbw.march_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.april_charge           = ROUND(xlbw.april_charge     - ( xlbw.april_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.last_updated_by        = cn_last_updated_by
             , xlbw.last_update_date       = cd_last_update_date
             , xlbw.last_update_login      = cn_last_update_login
             , xlbw.request_id             = cn_request_id
             , xlbw.program_application_id = cn_program_application_id
             , xlbw.program_id             = cn_program_id
             , xlbw.program_update_date    = cd_program_update_date
        WHERE  xlbw.file_id                = in_file_id
        AND    xlbw.record_type            = cv_record_type_2
        AND    xlbw.lease_class            = g_update_scrap_tab(i).lease_class
        AND    xlbw.lease_start_year       = g_update_scrap_tab(i).year
        ;
      ELSIF ( g_update_scrap_tab(i).update_type = cv_update_type_2 ) THEN
        -- ���[�X�J�n�N�x�ȑO�̔N�x
        UPDATE xxcff_lease_budget_work xlbw
        SET    xlbw.may_charge             = ROUND(xlbw.may_charge       - ( xlbw.may_charge       * g_update_scrap_tab(i).persent ))
             , xlbw.june_charge            = ROUND(xlbw.june_charge      - ( xlbw.june_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.july_charge            = ROUND(xlbw.july_charge      - ( xlbw.july_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.august_charge          = ROUND(xlbw.august_charge    - ( xlbw.august_charge    * g_update_scrap_tab(i).persent ))
             , xlbw.september_charge       = ROUND(xlbw.september_charge - ( xlbw.september_charge * g_update_scrap_tab(i).persent ))
             , xlbw.october_charge         = ROUND(xlbw.october_charge   - ( xlbw.october_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.november_charge        = ROUND(xlbw.november_charge  - ( xlbw.november_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.december_charge        = ROUND(xlbw.december_charge  - ( xlbw.december_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.january_charge         = ROUND(xlbw.january_charge   - ( xlbw.january_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.february_charge        = ROUND(xlbw.february_charge  - ( xlbw.february_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.march_charge           = ROUND(xlbw.march_charge     - ( xlbw.march_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.april_charge           = ROUND(xlbw.april_charge     - ( xlbw.april_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.last_updated_by        = cn_last_updated_by
             , xlbw.last_update_date       = cd_last_update_date
             , xlbw.last_update_login      = cn_last_update_login
             , xlbw.request_id             = cn_request_id
             , xlbw.program_application_id = cn_program_application_id
             , xlbw.program_id             = cn_program_id
             , xlbw.program_update_date    = cd_program_update_date
        WHERE  xlbw.file_id                = in_file_id
        AND    xlbw.record_type            = cv_record_type_2
        AND    xlbw.lease_class            = g_update_scrap_tab(i).lease_class
        AND    xlbw.lease_start_year      <= g_update_scrap_tab(i).year
        ;
      END IF;
    END LOOP update_scrap_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_scrap_data;
--
  /**********************************************************************************
   * Procedure Name   : create_output_file
   * Description      : �o�̓t�@�C���쐬 (A-9)
   ***********************************************************************************/
  PROCEDURE create_output_file(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_output_file'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- *** ���[�J���ϐ� ***
    lv_lease_type                    VARCHAR2(5)    DEFAULT NULL; -- �⏕�Ȗ�
    lv_chiku_code                    VARCHAR2(5)    DEFAULT NULL; -- �n��R�[�h
    lv_department_code               VARCHAR2(4)    DEFAULT NULL; -- ���_�R�[�h
    lv_csvbuff                       VARCHAR2(5000) DEFAULT NULL; -- �o��
    lv_chk_department_code           VARCHAR2(4)    DEFAULT NULL; -- ���_����
    ln_data_cnt                      NUMBER         DEFAULT 0;    -- �o�̓f�[�^
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���\�Z���[�N(����)�擾�J�[�\��
    CURSOR get_wk_object_cur
    IS
      SELECT xlbw.record_type               AS record_type      -- ���R�[�h�敪
           , xlbw.lease_class               AS lease_class      -- ���[�X���
           , xlbw.lease_class_name          AS lease_class_name -- ���[�X��ʖ�
           , xlbw.lease_type                AS lease_type       -- ���[�X�敪
           , xlbw.lease_type_name           AS lease_type_name  -- ���[�X�敪��
           , xlbw.department_code           AS department_code  -- ���_
           , xlbw.department_name           AS department_name  -- ���_��
           , xlbw.object_name               AS object_name      -- ����
           , xlbw.may_charge                AS may              -- 5��
           , xlbw.june_charge               AS june             -- 6��
           , xlbw.july_charge               AS july             -- 7��
           , xlbw.august_charge             AS august           -- 8��
           , xlbw.september_charge          AS september        -- 9��
           , xlbw.october_charge            AS october          -- 10��
           , xlbw.november_charge           AS november         -- 11��
           , xlbw.december_charge           AS december         -- 12��
           , xlbw.january_charge            AS january          -- 1��
           , xlbw.february_charge           AS february         -- 2��
           , xlbw.march_charge              AS march            -- 3��
           , xlbw.april_charge              AS april            -- 4��
      FROM   xxcff_lease_budget_work xlbw                       -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id            = in_file_id               -- �t�@�C��ID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- ���R�[�h�敪�F�V�K
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- ���R�[�h�敪
                                        , cv_record_type_2 )    --   �擾�܂��̓V�~�����[�V����
      AND     xlbw.lease_type        IN ( cv_lease_type_1       -- ���[�X�敪
                                        , cv_lease_type_2 )     --   ���_��܂��͍ă��[�X
      AND ( ( lv_lease_type          IS NULL )                  -- �p�����[�^<�⏕�Ȗ�>��NULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   �܂��̓p�����[�^<�⏕�Ȗ�>�ƈ�v
      AND ( ( lv_chiku_code          IS NULL )                  -- �p�����[�^<�n��>��NULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   �܂��̓p�����[�^<�n��>�ƈ�v
      AND ( ( lv_department_code     IS NULL )                  -- �p�����[�^<���_>��NULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   �܂��̓p�����[�^<���_>�ƈ�v
          )
      ORDER BY lease_class                                      -- ���[�X���
             , department_code                                  -- ���_
             , lease_type                                       -- ���[�X�敪
             , object_name                                      -- ����
    ;
    -- ���[�X���\�Z���[�N(���_)�擾�J�[�\��
    CURSOR get_wk_department_cur
    IS
      SELECT cv_record_type_4               AS record_type      -- ���R�[�h�敪
           , xlbw.lease_class               AS lease_class      -- ���[�X���
           , xlbw.lease_class_name          AS lease_class_name -- ���[�X��ʖ�
           , xlbw.lease_type                AS lease_type       -- ���[�X�敪
           , xlbw.lease_type_name           AS lease_type_name  -- ���[�X�敪��
           , xlbw.department_code           AS department_code  -- ���_
           , xlbw.department_name           AS department_name  -- ���_��
           , g_lookup_budget_itemnm_tab(24) AS object_name      -- ����
           , SUM(xlbw.may_number)           AS may              -- 5��
           , SUM(xlbw.june_number)          AS june             -- 6��
           , SUM(xlbw.july_number)          AS july             -- 7��
           , SUM(xlbw.august_number)        AS august           -- 8��
           , SUM(xlbw.september_number)     AS september        -- 9��
           , SUM(xlbw.october_number)       AS october          -- 10��
           , SUM(xlbw.november_number)      AS november         -- 11��
           , SUM(xlbw.december_number)      AS december         -- 12��
           , SUM(xlbw.january_number)       AS january          -- 1��
           , SUM(xlbw.february_number)      AS february         -- 2��
           , SUM(xlbw.march_number)         AS march            -- 3��
           , SUM(xlbw.april_number)         AS april            -- 4��
      FROM   xxcff_lease_budget_work xlbw                       -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id            = in_file_id               -- �t�@�C��ID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- ���R�[�h�敪�F�V�K
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- ���R�[�h�敪
                                        , cv_record_type_2 )    --   �擾�܂��̓V�~�����[�V����
      AND     xlbw.lease_type        IN ( cv_lease_type_1       -- ���[�X�敪
                                        , cv_lease_type_2 )     --   ���_��܂��͍ă��[�X
      AND ( ( lv_lease_type          IS NULL )                  -- �p�����[�^<�⏕�Ȗ�>��NULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   �܂��̓p�����[�^<�⏕�Ȗ�>�ƈ�v
      AND ( ( lv_chiku_code          IS NULL )                  -- �p�����[�^<�n��>��NULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   �܂��̓p�����[�^<�n��>�ƈ�v
      AND ( ( lv_department_code     IS NULL )                  -- �p�����[�^<���_>��NULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   �܂��̓p�����[�^<���_>�ƈ�v
          )
      GROUP BY xlbw.lease_class                                 -- ���[�X���
             , xlbw.lease_class_name                            -- ���[�X��ʖ�
             , xlbw.lease_type                                  -- ���[�X�敪
             , xlbw.lease_type_name                             -- ���[�X�敪��
             , xlbw.department_code                             -- ���_
             , xlbw.department_name                             -- ���_��
      UNION ALL
      SELECT cv_record_type_5               AS record_type      -- ���R�[�h�敪
           , xlbw.lease_class               AS lease_class      -- ���[�X���
           , xlbw.lease_class_name          AS lease_class_name -- ���[�X��ʖ�
           , xlbw.lease_type                AS lease_type       -- ���[�X�敪
           , xlbw.lease_type_name           AS lease_type_name  -- ���[�X�敪��
           , xlbw.department_code           AS department_code  -- ���_
           , xlbw.department_name           AS department_name  -- ���_��
           , g_lookup_budget_itemnm_tab(25) AS object_name      -- ����
           , SUM(xlbw.may_charge)           AS may              -- 5��
           , SUM(xlbw.june_charge)          AS june             -- 6��
           , SUM(xlbw.july_charge)          AS july             -- 7��
           , SUM(xlbw.august_charge)        AS august           -- 8��
           , SUM(xlbw.september_charge)     AS september        -- 9��
           , SUM(xlbw.october_charge)       AS october          -- 10��
           , SUM(xlbw.november_charge)      AS november         -- 11��
           , SUM(xlbw.december_charge)      AS december         -- 12��
           , SUM(xlbw.january_charge)       AS january          -- 1��
           , SUM(xlbw.february_charge)      AS february         -- 2��
           , SUM(xlbw.march_charge)         AS march            -- 3��
           , SUM(xlbw.april_charge)         AS april            -- 4��
      FROM   xxcff_lease_budget_work xlbw                       -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id            = in_file_id               -- �t�@�C��ID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- ���R�[�h�敪�F�V�K
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- ���R�[�h�敪
                                        , cv_record_type_2 )    --   �擾�܂��̓V�~�����[�V����
      AND     xlbw.lease_type        IN ( cv_lease_type_1       -- ���[�X�敪
                                        , cv_lease_type_2 )     --   ���_��܂��͍ă��[�X
      AND ( ( lv_lease_type          IS NULL )                  -- �p�����[�^<�⏕�Ȗ�>��NULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   �܂��̓p�����[�^<�⏕�Ȗ�>�ƈ�v
      AND ( ( lv_chiku_code          IS NULL )                  -- �p�����[�^<�n��>��NULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   �܂��̓p�����[�^<�n��>�ƈ�v
      AND ( ( lv_department_code     IS NULL )                  -- �p�����[�^<���_>��NULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   �܂��̓p�����[�^<���_>�ƈ�v
          )
      GROUP BY xlbw.lease_class                                 -- ���[�X���
             , xlbw.lease_class_name                            -- ���[�X��ʖ�
             , xlbw.lease_type                                  -- ���[�X�敪
             , xlbw.lease_type_name                             -- ���[�X�敪��
             , xlbw.department_code                             -- ���_
             , xlbw.department_name                             -- ���_��
      ORDER BY lease_class                                      -- ���[�X���
             , department_code                                  -- ���_
             , lease_type                                       -- ���[�X�敪
             , record_type                                      -- ���R�[�h�敪
    ;
    -- ���[�X���\�Z���[�N(���������_)�擾�J�[�\��
    CURSOR get_wk_object_department_cur
    IS
      SELECT DECODE(xlbw.record_type, cv_record_type_2, cv_record_type_1
                                    , xlbw.record_type)
                                            AS record_type      -- ���R�[�h�敪(�\�[�g�̂��߂�DECODE���s��)
           , xlbw.lease_class               AS lease_class      -- ���[�X���
           , xlbw.lease_class_name          AS lease_class_name -- ���[�X��ʖ�
           , xlbw.lease_type                AS lease_type       -- ���[�X�敪
           , xlbw.lease_type_name           AS lease_type_name  -- ���[�X�敪��
           , xlbw.department_code           AS department_code  -- ���_
           , xlbw.department_name           AS department_name  -- ���_��
           , xlbw.object_name               AS object_name      -- ����
           , xlbw.may_charge                AS may              -- 5��
           , xlbw.june_charge               AS june             -- 6��
           , xlbw.july_charge               AS july             -- 7��
           , xlbw.august_charge             AS august           -- 8��
           , xlbw.september_charge          AS september        -- 9��
           , xlbw.october_charge            AS october          -- 10��
           , xlbw.november_charge           AS november         -- 11��
           , xlbw.december_charge           AS december         -- 12��
           , xlbw.january_charge            AS january          -- 1��
           , xlbw.february_charge           AS february         -- 2��
           , xlbw.march_charge              AS march            -- 3��
           , xlbw.april_charge              AS april            -- 4��
      FROM   xxcff_lease_budget_work xlbw                       -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id            = in_file_id               -- �t�@�C��ID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- ���R�[�h�敪�F�V�K
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- ���R�[�h�敪
                                        , cv_record_type_2 )    --   �擾�܂��̓V�~�����[�V����
      AND    xlbw.lease_type         IN ( cv_lease_type_1       -- ���[�X�敪
                                        , cv_lease_type_2 )     --   ���_��܂��͍ă��[�X
      AND ( ( lv_lease_type          IS NULL )                  -- �p�����[�^<�⏕�Ȗ�>��NULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   �܂��̓p�����[�^<�⏕�Ȗ�>�ƈ�v
      AND ( ( lv_chiku_code          IS NULL )                  -- �p�����[�^<�n��>��NULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   �܂��̓p�����[�^<�n��>�ƈ�v
      AND ( ( lv_department_code     IS NULL )                  -- �p�����[�^<���_>��NULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   �܂��̓p�����[�^<���_>�ƈ�v
          )
      UNION ALL
      SELECT cv_record_type_4               AS record_type      -- ���R�[�h�敪
           , xlbw.lease_class               AS lease_class      -- ���[�X���
           , xlbw.lease_class_name          AS lease_class_name -- ���[�X��ʖ�
           , NULL                           AS lease_type       -- ���[�X�敪
           , NULL                           AS lease_type_name  -- ���[�X�敪
           , xlbw.department_code           AS department_code  -- ���_
           , xlbw.department_name           AS department_name  -- ���_��
           , g_lookup_budget_itemnm_tab(24) AS object_name      -- ����
           , SUM(xlbw.may_number)           AS may              -- 5��
           , SUM(xlbw.june_number)          AS june             -- 6��
           , SUM(xlbw.july_number)          AS july             -- 7��
           , SUM(xlbw.august_number)        AS august           -- 8��
           , SUM(xlbw.september_number)     AS september        -- 9��
           , SUM(xlbw.october_number)       AS october          -- 10��
           , SUM(xlbw.november_number)      AS november         -- 11��
           , SUM(xlbw.december_number)      AS december         -- 12��
           , SUM(xlbw.january_number)       AS january          -- 1��
           , SUM(xlbw.february_number)      AS february         -- 2��
           , SUM(xlbw.march_number)         AS march            -- 3��
           , SUM(xlbw.april_number)         AS april            -- 4��
      FROM   xxcff_lease_budget_work xlbw                       -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id            = in_file_id               -- �t�@�C��ID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- ���R�[�h�敪�F�V�K
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- ���R�[�h�敪
                                        , cv_record_type_2 )    --   �擾�܂��̓V�~�����[�V����
      AND    xlbw.lease_type         IN ( cv_lease_type_1       -- ���[�X�敪
                                        , cv_lease_type_2 )     --   ���_��܂��͍ă��[�X
      AND ( ( lv_lease_type          IS NULL )                  -- �p�����[�^<�⏕�Ȗ�>��NULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   �܂��̓p�����[�^<�⏕�Ȗ�>�ƈ�v
      AND ( ( lv_chiku_code          IS NULL )                  -- �p�����[�^<�n��>��NULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   �܂��̓p�����[�^<�n��>�ƈ�v
      AND ( ( lv_department_code     IS NULL )                  -- �p�����[�^<���_>��NULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   �܂��̓p�����[�^<���_>�ƈ�v
          )
      GROUP BY xlbw.lease_class                                 -- ���[�X���
             , xlbw.lease_class_name                            -- ���[�X��ʖ�
             , xlbw.department_code                             -- ���_
             , xlbw.department_name                             -- ���_��
      UNION ALL
      SELECT cv_record_type_5               AS record_type      -- ���R�[�h�敪
           , xlbw.lease_class               AS lease_class      -- ���[�X���
           , xlbw.lease_class_name          AS lease_class_name -- ���[�X��ʖ�
           , NULL                           AS lease_type       -- ���[�X�敪
           , NULL                           AS lease_type_name  -- ���[�X�敪
           , xlbw.department_code           AS department_code  -- ���_
           , xlbw.department_name           AS department_name  -- ���_��
           , g_lookup_budget_itemnm_tab(25) AS object_name      -- ����
           , SUM(xlbw.may_charge)           AS may              -- 5��
           , SUM(xlbw.june_charge)          AS june             -- 6��
           , SUM(xlbw.july_charge)          AS july             -- 7��
           , SUM(xlbw.august_charge)        AS august           -- 8��
           , SUM(xlbw.september_charge)     AS september        -- 9��
           , SUM(xlbw.october_charge)       AS october          -- 10��
           , SUM(xlbw.november_charge)      AS november         -- 11��
           , SUM(xlbw.december_charge)      AS december         -- 12��
           , SUM(xlbw.january_charge)       AS january          -- 1��
           , SUM(xlbw.february_charge)      AS february         -- 2��
           , SUM(xlbw.march_charge)         AS march            -- 3��
           , SUM(xlbw.april_charge)         AS april            -- 4��
      FROM   xxcff_lease_budget_work xlbw                       -- ���[�X���\�Z���[�N
      WHERE  xlbw.file_id            = in_file_id               -- �t�@�C��ID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- ���R�[�h�敪�F�V�K
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- ���R�[�h�敪
                                        , cv_record_type_2 )    --   �擾�܂��̓V�~�����[�V����
      AND    xlbw.lease_type         IN ( cv_lease_type_1       -- ���[�X�敪
                                        , cv_lease_type_2 )     --   ���_��܂��͍ă��[�X
      AND ( ( lv_lease_type          IS NULL )                  -- �p�����[�^<�⏕�Ȗ�>��NULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   �܂��̓p�����[�^<�⏕�Ȗ�>�ƈ�v
      AND ( ( lv_chiku_code          IS NULL )                  -- �p�����[�^<�n��>��NULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   �܂��̓p�����[�^<�n��>�ƈ�v
      AND ( ( lv_department_code     IS NULL )                  -- �p�����[�^<���_>��NULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   �܂��̓p�����[�^<���_>�ƈ�v
          )
      GROUP BY xlbw.lease_class                                 -- ���[�X���
             , xlbw.lease_class_name                            -- ���[�X��ʖ�
             , xlbw.department_code                             -- ���_
             , xlbw.department_name                             -- ���_��
      ORDER BY lease_class                                      -- ���[�X���
             , department_code                                  -- ���_
             , lease_type                                       -- ���[�X�敪
             , record_type                                      -- ���R�[�h�敪
             , object_name                                      -- ����
    ;
    -- ���[�X���\�Z���[�N(����)�擾�J�[�\�����R�[�h�^
    get_wk_object_rec                get_wk_object_cur%ROWTYPE;
    -- ���[�X���\�Z���[�N(���_)�擾�J�[�\�����R�[�h�^
    get_wk_department_rec            get_wk_department_cur%ROWTYPE;
    -- ���[�X���\�Z���[�N(���������_)�擾�J�[�\�����R�[�h�^
    get_wk_object_department_rec     get_wk_object_department_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ��i�[
    lv_lease_type      := g_lord_head_data_rec.lease_type;      -- ���[�X�敪
    lv_chiku_code      := g_lord_head_data_rec.chiku_code;      -- �n��
    lv_department_code := g_lord_head_data_rec.department_code; -- ���_
    -- �W�v�P�ʂ����������_�̏ꍇ
    IF ( g_lord_head_data_rec.group_unit IS NULL ) THEN
      --
      OPEN get_wk_object_department_cur;
      --
      <<get_wk_object_departmen_loop>>
      LOOP
        FETCH get_wk_object_department_cur INTO get_wk_object_department_rec;
        EXIT WHEN get_wk_object_department_cur%NOTFOUND;
          ln_data_cnt := ln_data_cnt + 1;
          g_out_tab(ln_data_cnt).lease_class_name := get_wk_object_department_rec.lease_class_name;
          g_out_tab(ln_data_cnt).lease_type_name  := get_wk_object_department_rec.lease_type_name;
          g_out_tab(ln_data_cnt).department_code  := get_wk_object_department_rec.department_code;
          g_out_tab(ln_data_cnt).department_name  := get_wk_object_department_rec.department_name;
          g_out_tab(ln_data_cnt).object_name      := get_wk_object_department_rec.object_name;
          g_out_tab(ln_data_cnt).may              := get_wk_object_department_rec.may;
          g_out_tab(ln_data_cnt).june             := get_wk_object_department_rec.june;
          g_out_tab(ln_data_cnt).july             := get_wk_object_department_rec.july;
          g_out_tab(ln_data_cnt).august           := get_wk_object_department_rec.august;
          g_out_tab(ln_data_cnt).september        := get_wk_object_department_rec.september;
          g_out_tab(ln_data_cnt).october          := get_wk_object_department_rec.october;
          g_out_tab(ln_data_cnt).november         := get_wk_object_department_rec.november;
          g_out_tab(ln_data_cnt).december         := get_wk_object_department_rec.december;
          g_out_tab(ln_data_cnt).january          := get_wk_object_department_rec.january;
          g_out_tab(ln_data_cnt).february         := get_wk_object_department_rec.february;
          g_out_tab(ln_data_cnt).march            := get_wk_object_department_rec.march;
          g_out_tab(ln_data_cnt).april            := get_wk_object_department_rec.april;
      END LOOP get_wk_object_departmen_loop;
      --
      CLOSE get_wk_object_department_cur;
      --
    -- �W�v�P�ʂ������̏ꍇ
    ELSIF ( g_lord_head_data_rec.group_unit = cv_group_unit_1 ) THEN
      --
      OPEN get_wk_object_cur;
      --
      <<get_wk_object_loop>>
      LOOP
        FETCH get_wk_object_cur INTO get_wk_object_rec;
        EXIT WHEN get_wk_object_cur%NOTFOUND;
          ln_data_cnt := ln_data_cnt + 1;
          g_out_tab(ln_data_cnt).lease_class_name := get_wk_object_rec.lease_class_name;
          g_out_tab(ln_data_cnt).lease_type_name  := get_wk_object_rec.lease_type_name;
          g_out_tab(ln_data_cnt).department_code  := get_wk_object_rec.department_code;
          g_out_tab(ln_data_cnt).department_name  := get_wk_object_rec.department_name;
          g_out_tab(ln_data_cnt).object_name      := get_wk_object_rec.object_name;
          g_out_tab(ln_data_cnt).may              := get_wk_object_rec.may;
          g_out_tab(ln_data_cnt).june             := get_wk_object_rec.june;
          g_out_tab(ln_data_cnt).july             := get_wk_object_rec.july;
          g_out_tab(ln_data_cnt).august           := get_wk_object_rec.august;
          g_out_tab(ln_data_cnt).september        := get_wk_object_rec.september;
          g_out_tab(ln_data_cnt).october          := get_wk_object_rec.october;
          g_out_tab(ln_data_cnt).november         := get_wk_object_rec.november;
          g_out_tab(ln_data_cnt).december         := get_wk_object_rec.december;
          g_out_tab(ln_data_cnt).january          := get_wk_object_rec.january;
          g_out_tab(ln_data_cnt).february         := get_wk_object_rec.february;
          g_out_tab(ln_data_cnt).march            := get_wk_object_rec.march;
          g_out_tab(ln_data_cnt).april            := get_wk_object_rec.april;
      END LOOP get_wk_object_loop;
      --
      CLOSE get_wk_object_cur;
      --
    -- �W�v�P�ʂ����_�̏ꍇ
    ELSIF ( g_lord_head_data_rec.group_unit = cv_group_unit_2 ) THEN
      --
      OPEN get_wk_department_cur;
      --
      <<get_wk_department_loop>>
      LOOP
        FETCH get_wk_department_cur INTO get_wk_department_rec;
        EXIT WHEN get_wk_department_cur%NOTFOUND;
          ln_data_cnt := ln_data_cnt + 1;
          g_out_tab(ln_data_cnt).lease_class_name := get_wk_department_rec.lease_class_name;
          g_out_tab(ln_data_cnt).lease_type_name  := get_wk_department_rec.lease_type_name;
          g_out_tab(ln_data_cnt).department_code  := get_wk_department_rec.department_code;
          g_out_tab(ln_data_cnt).department_name  := get_wk_department_rec.department_name;
          g_out_tab(ln_data_cnt).object_name      := get_wk_department_rec.object_name;
          g_out_tab(ln_data_cnt).may              := get_wk_department_rec.may;
          g_out_tab(ln_data_cnt).june             := get_wk_department_rec.june;
          g_out_tab(ln_data_cnt).july             := get_wk_department_rec.july;
          g_out_tab(ln_data_cnt).august           := get_wk_department_rec.august;
          g_out_tab(ln_data_cnt).september        := get_wk_department_rec.september;
          g_out_tab(ln_data_cnt).october          := get_wk_department_rec.october;
          g_out_tab(ln_data_cnt).november         := get_wk_department_rec.november;
          g_out_tab(ln_data_cnt).december         := get_wk_department_rec.december;
          g_out_tab(ln_data_cnt).january          := get_wk_department_rec.january;
          g_out_tab(ln_data_cnt).february         := get_wk_department_rec.february;
          g_out_tab(ln_data_cnt).march            := get_wk_department_rec.march;
          g_out_tab(ln_data_cnt).april            := get_wk_department_rec.april;
      END LOOP get_wk_department_loop;
      --
      CLOSE get_wk_department_cur;
      --
    END IF;
    --
    -- �擾����0���̏ꍇ
    IF ( ln_data_cnt = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00165
                             ,iv_token_name1  => cv_tkn_get_data
                             ,iv_token_value1 => cv_msg_xxcff_50197)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --======================================================
    -- �o�̓t�@�C���쐬
    --======================================================
    -- �N�x�s
    lv_csvbuff :=               cv_wqt || g_lookup_budget_itemnm_tab(1) || cv_wqt || cv_kanma;   -- �N�x
    lv_csvbuff := lv_csvbuff || cv_wqt || g_next_year_rec.year          || cv_wqt;               -- ���s�N�x
    -- �W���o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_csvbuff
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
    -- �w�b�_�s
    lv_csvbuff :=               cv_wqt || g_lookup_budget_itemnm_tab(2)  || cv_wqt || cv_kanma;  -- ���[�X���
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(3)  || cv_wqt || cv_kanma;  -- ���[�X�敪
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(4)  || cv_wqt || cv_kanma;  -- ���_
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(5)  || cv_wqt || cv_kanma;  -- ���_��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(6)  || cv_wqt || cv_kanma;  -- ����
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(7)  || cv_wqt || cv_kanma;  -- 5��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(8)  || cv_wqt || cv_kanma;  -- 6��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(9)  || cv_wqt || cv_kanma;  -- 7��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(10) || cv_wqt || cv_kanma;  -- 8��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(11) || cv_wqt || cv_kanma;  -- 9��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(12) || cv_wqt || cv_kanma;  -- 10��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(13) || cv_wqt || cv_kanma;  -- 11��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(14) || cv_wqt || cv_kanma;  -- 12��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(15) || cv_wqt || cv_kanma;  -- 1��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(16) || cv_wqt || cv_kanma;  -- 2��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(17) || cv_wqt || cv_kanma;  -- 3��
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(18) || cv_wqt;              -- 4��
    -- �W���o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_csvbuff
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
    <<out_loop>>
    FOR i IN g_out_tab.FIRST .. g_out_tab.LAST LOOP
      -- �O���R�[�h�Ƌ��_���ύX���ꂽ�ꍇ
      IF ( NVL(lv_chk_department_code, g_out_tab(i).department_code) <> g_out_tab(i).department_code ) THEN
        -- ��s�}��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => ''
        );
      END IF;
      -- ���_���ʗp
      lv_chk_department_code := g_out_tab(i).department_code;
      -- �f�[�^�s
      lv_csvbuff :=               cv_wqt || g_out_tab(i).lease_class_name || cv_wqt || cv_kanma; -- ���[�X���
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).lease_type_name  || cv_wqt || cv_kanma; -- ���[�X�敪
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).department_code  || cv_wqt || cv_kanma; -- ���_
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).department_name  || cv_wqt || cv_kanma; -- ���_��
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).object_name      || cv_wqt || cv_kanma; -- ����
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).may                        || cv_kanma; -- 5��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).june                       || cv_kanma; -- 6��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).july                       || cv_kanma; -- 7��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).august                     || cv_kanma; -- 8��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).september                  || cv_kanma; -- 9��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).october                    || cv_kanma; -- 10��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).november                   || cv_kanma; -- 11��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).december                   || cv_kanma; -- 12��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).january                    || cv_kanma; -- 1��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).february                   || cv_kanma; -- 2��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).march                      || cv_kanma; -- 3��
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).april;                                  -- 4��
      -- �W���o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_csvbuff
      );
      -- ���������J�E���g�A�b�v
      gn_normal_cnt := gn_normal_cnt + 1;
      --
    END LOOP out_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF ( get_wk_object_cur%ISOPEN ) THEN
        CLOSE get_wk_object_cur;
      END IF;
      IF ( get_wk_department_cur%ISOPEN ) THEN
        CLOSE get_wk_department_cur;
      END IF;
      IF ( get_wk_object_department_cur%ISOPEN ) THEN
        CLOSE get_wk_object_department_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_output_file;
--
  /**********************************************************************************
   * Procedure Name   : del_if_data
   * Description      : �t�@�C���A�b�v���[�hI/F�폜 (A-10)
   ***********************************************************************************/
  PROCEDURE del_if_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_if_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    DELETE FROM xxccp_mrp_file_ul_interface xfui -- �t�@�C���A�b�v���[�hI/F
    WHERE       xfui.file_id = in_file_id        -- �t�@�C��ID
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_if_data;
--
  /**********************************************************************************
   * Procedure Name   : del_lease_budget_wk
   * Description      : ���[�X���\�Z���[�N�폜 (A-11)
   ***********************************************************************************/
  PROCEDURE del_lease_budget_wk(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lease_budget_wk'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ���[�X���\�Z���[�N�폜
    DELETE FROM xxcff_lease_budget_work xlbw -- ���[�X���\�Z���[�N
    WHERE  xlbw.file_id = in_file_id         -- �t�@�C��ID
    ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_lease_budget_wk;
--
  /**********************************************************************************
   * Procedure Name   : set_g_lease_budget_tab
   * Description      : ���[�X���\�Z�p���i�[�z��ݒ�p�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE set_g_lease_budget_tab(
    iv_record_type          IN  VARCHAR2, -- ���R�[�h�敪
    iv_lease_class          IN  VARCHAR2, -- ���[�X���
    iv_lease_class_name     IN  VARCHAR2, -- ���[�X��ʖ�
    iv_lease_type           IN  VARCHAR2, -- ���[�X�敪
    iv_lease_type_name      IN  VARCHAR2, -- ���[�X�敪��
    iv_chiku_code           IN  VARCHAR2, -- �n��R�[�h
    iv_department_code      IN  VARCHAR2, -- ���_�R�[�h
    iv_department_name      IN  VARCHAR2, -- ���_��
    iv_cust_shift_date      IN  VARCHAR2, -- �ڋq�ڍs��
    iv_new_department_code  IN  VARCHAR2, -- �V���_�R�[�h
    iv_new_department_name  IN  VARCHAR2, -- �V���_��
    iv_object_name          IN  VARCHAR2, -- �����R�[�h
    iv_lease_start_year     IN  VARCHAR2, -- ���[�X�J�n�N�x
    iv_lease_end_months     IN  VARCHAR2, -- ���[�X�x���ŏI��
    in_may_charge           IN  NUMBER,   -- 5��_���[�X��
    in_june_charge          IN  NUMBER,   -- 6��_���[�X��
    in_july_charge          IN  NUMBER,   -- 7��_���[�X��
    in_august_charge        IN  NUMBER,   -- 8��_���[�X��
    in_september_charge     IN  NUMBER,   -- 9��_���[�X��
    in_october_charge       IN  NUMBER,   -- 10��_���[�X��
    in_november_charge      IN  NUMBER,   -- 11��_���[�X��
    in_december_charge      IN  NUMBER,   -- 12��_���[�X��
    in_january_charge       IN  NUMBER,   -- 1��_���[�X��
    in_february_charge      IN  NUMBER,   -- 2��_���[�X��
    in_march_charge         IN  NUMBER,   -- 3��_���[�X��
    in_april_charge         IN  NUMBER,   -- 4��_���[�X��
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_g_lease_budget_tab'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_may_charge                    NUMBER DEFAULT 0; -- 5��_���[�X��
    ln_june_charge                   NUMBER DEFAULT 0; -- 6��_���[�X��
    ln_july_charge                   NUMBER DEFAULT 0; -- 7��_���[�X��
    ln_august_charge                 NUMBER DEFAULT 0; -- 8��_���[�X��
    ln_september_charge              NUMBER DEFAULT 0; -- 9��_���[�X��
    ln_october_charge                NUMBER DEFAULT 0; -- 10��_���[�X��
    ln_november_charge               NUMBER DEFAULT 0; -- 11��_���[�X��
    ln_december_charge               NUMBER DEFAULT 0; -- 12��_���[�X��
    ln_january_charge                NUMBER DEFAULT 0; -- 1��_���[�X��
    ln_february_charge               NUMBER DEFAULT 0; -- 2��_���[�X��
    ln_march_charge                  NUMBER DEFAULT 0; -- 3��_���[�X��
    ln_april_charge                  NUMBER DEFAULT 0; -- 4��_���[�X��
    ln_may_number                    NUMBER DEFAULT 0; -- 5��_�䐔
    ln_june_number                   NUMBER DEFAULT 0; -- 6��_�䐔
    ln_july_number                   NUMBER DEFAULT 0; -- 7��_�䐔
    ln_august_number                 NUMBER DEFAULT 0; -- 8��_�䐔
    ln_september_number              NUMBER DEFAULT 0; -- 9��_�䐔
    ln_october_number                NUMBER DEFAULT 0; -- 10��_�䐔
    ln_november_number               NUMBER DEFAULT 0; -- 11��_�䐔
    ln_december_number               NUMBER DEFAULT 0; -- 12��_�䐔
    ln_january_number                NUMBER DEFAULT 0; -- 1��_�䐔
    ln_february_number               NUMBER DEFAULT 0; -- 2��_�䐔
    ln_march_number                  NUMBER DEFAULT 0; -- 3��_�䐔
    ln_april_number                  NUMBER DEFAULT 0; -- 4��_�䐔
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�X���ݒ�
    ln_may_charge       := in_may_charge;       -- 5��_���[�X��
    ln_june_charge      := in_june_charge;      -- 6��_���[�X��
    ln_july_charge      := in_july_charge;      -- 7��_���[�X��
    ln_august_charge    := in_august_charge;    -- 8��_���[�X��
    ln_september_charge := in_september_charge; -- 9��_���[�X��
    ln_october_charge   := in_october_charge;   -- 10��_���[�X��
    ln_november_charge  := in_november_charge;  -- 11��_���[�X��
    ln_december_charge  := in_december_charge;  -- 12��_���[�X��
    ln_january_charge   := in_january_charge;   -- 1��_���[�X��
    ln_february_charge  := in_february_charge;  -- 2��_���[�X��
    ln_march_charge     := in_march_charge;     -- 3��_���[�X��
    ln_april_charge     := in_april_charge;     -- 4��_���[�X��
    -- �䐔�ݒ�
    IF ( ln_may_charge <> 0 ) THEN
      ln_may_number       := 1; -- 5��_�䐔
    END IF;
    IF ( ln_june_charge <> 0 ) THEN
      ln_june_number      := 1; -- 6��_�䐔
    END IF;
    IF ( ln_july_charge <> 0 ) THEN
      ln_july_number      := 1; -- 7��_�䐔
    END IF;
    IF ( ln_august_charge <> 0 ) THEN
      ln_august_number    := 1; -- 8��_�䐔
    END IF;
    IF ( ln_september_charge <> 0 ) THEN
      ln_september_number := 1; -- 9��_�䐔
    END IF;
    IF ( ln_october_charge <> 0 ) THEN
      ln_october_number   := 1; -- 10��_�䐔
    END IF;
    IF ( ln_november_charge <> 0 ) THEN
      ln_november_number  := 1; -- 11��_�䐔
    END IF;
    IF ( ln_december_charge <> 0 ) THEN
      ln_december_number  := 1; -- 12��_�䐔
    END IF;
    IF ( ln_january_charge <> 0 ) THEN
      ln_january_number   := 1; -- 1��_�䐔
    END IF;
    IF ( ln_february_charge <> 0 ) THEN
      ln_february_number  := 1; -- 2��_�䐔
    END IF;
    IF ( ln_march_charge <> 0 ) THEN
      ln_march_number     := 1; -- 3��_�䐔
    END IF;
    IF ( ln_april_charge <> 0 ) THEN
      ln_april_number     := 1; -- 4��_�䐔
    END IF;
    -- �J�E���g�A�b�v
    gn_line_cnt := gn_line_cnt + 1;
    -- �ȉ��̏ꍇ�A�����_�܂��͐V���_�ł�1���R�[�h
    --   �ă��[�X�̏ꍇ
    --   �܂��͌��_�񂩂ڋq�ڍs����NULL
    --                   �܂��͌ڋq�ڍs�������N�x5���ȑO�̏ꍇ
    --                   �܂��͌ڋq�ڍs����胊�[�X�x���ŏI�����O�̏ꍇ
    IF ( ( iv_lease_type = cv_lease_type_2 )
      OR ( ( iv_lease_type = cv_lease_type_1 )
      AND  ( ( iv_cust_shift_date IS NULL )
      OR     ( iv_cust_shift_date <= g_next_year_rec.may )
      OR     ( iv_lease_end_months < iv_cust_shift_date  ) ) ) ) THEN
      g_lease_budget_tab(gn_line_cnt).record_type      := iv_record_type;      -- ���R�[�h�敪
      g_lease_budget_tab(gn_line_cnt).lease_class      := iv_lease_class;      -- ���[�X���
      g_lease_budget_tab(gn_line_cnt).lease_class_name := iv_lease_class_name; -- ���[�X��ʖ�
      g_lease_budget_tab(gn_line_cnt).lease_type       := iv_lease_type;       -- ���[�X�敪
      g_lease_budget_tab(gn_line_cnt).lease_type_name  := iv_lease_type_name;  -- ���[�X�敪��
      g_lease_budget_tab(gn_line_cnt).chiku_code       := iv_chiku_code;       -- �n��R�[�h
      -- �ڋq�ڍs����NULL�̏ꍇ
      -- �܂��̓��[�X�x���ŏI�����ڋq�ڍs�����O�̏ꍇ
      IF ( ( iv_cust_shift_date IS NULL )
        OR ( iv_lease_end_months < iv_cust_shift_date ) ) THEN
        g_lease_budget_tab(gn_line_cnt).department_code := iv_department_code;     -- ���_�R�[�h
        g_lease_budget_tab(gn_line_cnt).department_name := iv_department_name;     -- ���_��
      -- ���[�X�x���ŏI�����ڋq�ڍs���ȍ~�̏ꍇ
      ELSIF ( iv_lease_end_months >= iv_cust_shift_date ) THEN
        g_lease_budget_tab(gn_line_cnt).department_code := iv_new_department_code; -- �V���_�R�[�h
        g_lease_budget_tab(gn_line_cnt).department_name := iv_new_department_name; -- �V���_��
      END IF;
      g_lease_budget_tab(gn_line_cnt).object_name      := iv_object_name;      -- �����R�[�h
      g_lease_budget_tab(gn_line_cnt).lease_start_year := iv_lease_start_year; -- ���[�X�J�n�N�x
      g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
      g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
      g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
      g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
      g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
      g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
      g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
      g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
      g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
      g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
      g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
      g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
      g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
      g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
      g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
      g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
      g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
      g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
      g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
      g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
      g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
      g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
      g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
      g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
    -- �ȉ��̏ꍇ�A�ڋq�ڍs�O���2���R�[�h
    --   ���_�񂩂��[�X�x���ŏI�����ڋq�ڍs���ȍ~�̏ꍇ
    ELSIF ( ( iv_lease_type = cv_lease_type_1 )
      AND   ( iv_lease_end_months >= iv_cust_shift_date ) ) THEN
      <<create_record_loop>>
      FOR i IN 1 .. 2 LOOP
        g_lease_budget_tab(gn_line_cnt).record_type      := iv_record_type;      -- ���R�[�h�敪
        g_lease_budget_tab(gn_line_cnt).lease_class      := iv_lease_class;      -- ���[�X���
        g_lease_budget_tab(gn_line_cnt).lease_class_name := iv_lease_class_name; -- ���[�X��ʖ�
        g_lease_budget_tab(gn_line_cnt).lease_type       := iv_lease_type;       -- ���[�X�敪
        g_lease_budget_tab(gn_line_cnt).lease_type_name  := iv_lease_type_name;  -- ���[�X�敪��
        g_lease_budget_tab(gn_line_cnt).object_name      := iv_object_name;      -- �����R�[�h
        g_lease_budget_tab(gn_line_cnt).lease_start_year := iv_lease_start_year; -- ���[�X�J�n�N�x
        g_lease_budget_tab(gn_line_cnt).chiku_code       := iv_chiku_code;       -- �n��R�[�h
        -- �ڋq�ڍs�O���R�[�h
        IF ( i = 1 ) THEN
          g_lease_budget_tab(gn_line_cnt).department_code    := iv_department_code;  -- ���_�R�[�h
          g_lease_budget_tab(gn_line_cnt).department_name    := iv_department_name;  -- ���_��
          IF ( iv_cust_shift_date = g_next_year_rec.june ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.july ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.august ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.september ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.october ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.november ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.december ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.january ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.february ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.march ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.april ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5��_���[�X��
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5��_�䐔
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
          END IF;
          --
          gn_line_cnt := gn_line_cnt + 1;
        -- �ڋq�ڍs�ヌ�R�[�h
        ELSE
          g_lease_budget_tab(gn_line_cnt).department_code    := iv_new_department_code; -- �V���_�R�[�h
          g_lease_budget_tab(gn_line_cnt).department_name    := iv_new_department_name; -- �V���_��
          IF ( iv_cust_shift_date = g_next_year_rec.june ) THEN
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6��_���[�X��
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6��_�䐔
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.july ) THEN
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7��_���[�X��
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7��_�䐔
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.august ) THEN
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8��_���[�X��
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8��_�䐔
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.september ) THEN
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9��_���[�X��
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9��_�䐔
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.october ) THEN
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10��_���[�X��
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10��_�䐔
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.november ) THEN
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11��_���[�X��
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11��_�䐔
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.december ) THEN
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12��_���[�X��
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12��_�䐔
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.january ) THEN
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1��_���[�X��
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1��_�䐔
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.february ) THEN
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2��_���[�X��
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2��_�䐔
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.march ) THEN
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3��_���[�X��
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3��_�䐔
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          ELSIF ( iv_cust_shift_date = g_next_year_rec.april ) THEN
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4��_���[�X��
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4��_�䐔
          END IF;
        END IF;
      END LOOP create_record_loop;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_g_lease_budget_tab;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       -- 1.�t�@�C��ID(�K�{)
    iv_file_format IN  VARCHAR2,     -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_cust_shift_date               VARCHAR2(7) DEFAULT NULL;  -- �ڋq�ڍs��
    lv_re_lease_months               VARCHAR2(7) DEFAULT NULL;  -- ���[�X�x���ŏI��
    ln_cnt                           NUMBER      DEFAULT 0;     -- ����
    lt_chk_object_code               xxcff_object_headers.object_code%TYPE DEFAULT 'DUMMY'; -- �����R�[�h
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���\�Z���o�J�[�\��
    CURSOR get_lease_budget_cur
    IS
      SELECT /*+ LEADING( FFVS FFV FFVT )
                 INDEX( XOH  XXCFF_OBJECT_HEADERS_N03 )
                 INDEX( XCH  XXCFF_CONTRACT_HEADERS_PK )
                 INDEX( FFVT FND_FLEX_VALUES_TL_U1 )    */
             cv_record_type_1                                                             AS record_type         -- ���R�[�h�敪
           , xoh.lease_class                                                              AS lease_class         -- ���[�X���
           , DECODE(xoh.lease_class, cv_lease_class_11, g_lookup_budget_itemnm_tab(19)
                                   , cv_lease_class_12, g_lookup_budget_itemnm_tab(20))   AS lease_class_name    -- ���[�X��ʖ�
           , xch.lease_type                                                               AS lease_type          -- ���[�X�敪
           , DECODE(xch.lease_type, cv_lease_type_1, g_lookup_budget_itemnm_tab(21)
                                  , cv_lease_type_2, g_lookup_budget_itemnm_tab(22))      AS lease_type_name     -- ���[�X�敪��
           , hl.address3                                                                  AS chiku_code          -- �n��R�[�h
           , xoh.department_code                                                          AS department_code     -- ���_�R�[�h
           , ffvt.description                                                             AS department_name     -- ���_��
           , xoh.object_code                                                              AS object_name         -- �����R�[�h
           , ( SELECT ffy.fiscal_year
               FROM   fa_fiscal_year ffy
               WHERE  ffy.fiscal_year_name = cv_fiscal_year_name
               AND    xch.lease_start_date BETWEEN ffy.start_date
                                           AND ffy.end_date )                             AS lease_start_year    -- ���[�X�J�n�N�x
           , MAX(xpp.period_name)                                                         AS lease_end_months    -- ���[�X�x���ŏI��
           , xch.re_lease_times                                                           AS re_lease_times      -- �ă��[�X��
           , xoh.re_lease_flag                                                            AS re_lease_flag       -- �ă��[�X�v�t���O
           , ( SELECT xcl2.second_charge
               FROM   xxcff_contract_headers xch2
                    , xxcff_contract_lines   xcl2
               WHERE  xch2.contract_header_id = xcl2.contract_header_id
               AND    xcl2.object_header_id   = xoh.object_header_id
               AND    xch2.lease_type         = cv_lease_type_1
              )                                                                           AS lease_type_1_charge -- ���_����z
           , SUM(DECODE(xpp.period_name, g_next_year_rec.may,       xpp.lease_charge, 0)) AS may_charge          -- 5��_���[�X��
           , 0                                                                            AS may_number          -- 5��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.june,      xpp.lease_charge, 0)) AS june_charge         -- 6��_���[�X��
           , 0                                                                            AS june_number         -- 6��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.july,      xpp.lease_charge, 0)) AS july_charge         -- 7��_���[�X��
           , 0                                                                            AS july_number         -- 7��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.august,    xpp.lease_charge, 0)) AS august_charge       -- 8��_���[�X��
           , 0                                                                            AS august_number       -- 8��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.september, xpp.lease_charge, 0)) AS september_charge    -- 9��_���[�X��
           , 0                                                                            AS september_number    -- 9��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.october,   xpp.lease_charge, 0)) AS october_charge      -- 10��_���[�X��
           , 0                                                                            AS october_number      -- 10��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.november,  xpp.lease_charge, 0)) AS november_charge     -- 11��_���[�X��
           , 0                                                                            AS november_number     -- 11��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.december,  xpp.lease_charge, 0)) AS december_charge     -- 12��_���[�X��
           , 0                                                                            AS december_number     -- 12��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.january,   xpp.lease_charge, 0)) AS january_charge      -- 1��_���[�X��
           , 0                                                                            AS january_number      -- 1��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.february,  xpp.lease_charge, 0)) AS february_charge     -- 2��_���[�X��
           , 0                                                                            AS february_number     -- 2��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.march,     xpp.lease_charge, 0)) AS march_charge        -- 3��_���[�X��
           , 0                                                                            AS march_number        -- 3��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.april,     xpp.lease_charge, 0)) AS april_charge        -- 4��_���[�X��
           , 0                                                                            AS april_number        -- 4��_�䐔
           , TO_CHAR(xcsi1.cust_shift_date, cv_format_yyyymm)                             AS cust_shift_date     -- �ڋq�ڍs��
           , xcsi1.new_base_code                                                          AS new_base_code       -- �V���_�R�[�h
           , xcsi1.department_name                                                        AS new_department_name -- �V���_��
      FROM   xxcff_contract_headers xch                              -- ���[�X�_��w�b�_
           , xxcff_contract_lines   xcl                              -- ���[�X�_�񖾍�
           , xxcff_object_headers   xoh                              -- ���[�X����
           , xxcff_pay_planning     xpp                              -- ���[�X�x���v��
           , fnd_flex_value_sets    ffvs                             -- �l�Z�b�g�l
           , fnd_flex_values        ffv                              -- �l�Z�b�g
           , fnd_flex_values_tl     ffvt                             -- �l��`
           , hz_cust_accounts       hca                              -- �ڋq�A�J�E���g
           , hz_parties             hp                               -- �p�[�e�B
           , hz_party_sites         hps                              -- �p�[�e�B�T�C�g
           , hz_cust_acct_sites     hcas                             -- �ڋq���ݒn
           , hz_locations           hl                               -- ���P�[�V����
           , ( SELECT /*+ INDEX( FFVT FND_FLEX_VALUES_TL_U1 ) */
                      xcsi.cust_code        AS cust_code             -- �ڋq�R�[�h
                    , xcsi.cust_shift_date  AS cust_shift_date       -- �ڋq�ڍs��
                    , xcsi.prev_base_code   AS prev_base_code        -- �����_�R�[�h
                    , xcsi.new_base_code    AS new_base_code         -- �V���_�R�[�h
                    , ffvt.description      AS department_name       -- �V���_��
               FROM   xxcok_cust_shift_info xcsi                     -- �ڋq�ڍs���
                    , fnd_flex_value_sets   ffvs                     -- �l�Z�b�g�l
                    , fnd_flex_values       ffv                      -- �l�Z�b�g
                    , fnd_flex_values_tl    ffvt                     -- �l��`
               WHERE  xcsi.new_base_code       = ffv.flex_value(+)      -- �V���_�R�[�h
               AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id  -- �l�Z�b�gID
               AND    ffvs.flex_value_set_name = cv_department          -- �l�Z�b�g��
               AND    ffv.flex_value_id        = ffvt.flex_value_id     -- �lID
               AND    ffvt.language            = ct_language            -- ����
               AND    xcsi.status              = cv_cust_shift_status_a -- �X�e�[�^�X:�m��
               AND    xcsi.cust_shift_date BETWEEN g_init_rec.process_date
                                           AND     LAST_DAY(TRUNC(TO_DATE(g_next_year_rec.april, cv_format_yyyymm)))
             ) xcsi1
      WHERE  xch.contract_header_id   = xcl.contract_header_id  -- �_�����ID
      AND    xcl.contract_line_id     = xpp.contract_line_id    -- �_�񖾍ד���ID
      AND    xcl.object_header_id     = xoh.object_header_id    -- ��������ID
      AND    xoh.department_code      = ffv.flex_value(+)       -- �Ǘ�����R�[�h
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id   -- �l�Z�b�gID
      AND    ffvs.flex_value_set_name = cv_department           -- �l�Z�b�g��
      AND    ffv.flex_value_id        = ffvt.flex_value_id      -- �lID
      AND    ffvt.language            = ct_language             -- ����
      AND    xoh.customer_code        = xcsi1.cust_code(+)      -- �ڋq�R�[�h
      AND    xoh.department_code      = xcsi1.prev_base_code(+) -- �����_�R�[�h
      AND    xoh.customer_code        = hca.account_number      -- �ڋq�R�[�h
      AND    hca.party_id             = hp.party_id             -- �p�[�e�BID
      AND    hp.party_id              = hps.party_id            -- �p�[�e�BID
      AND    hca.cust_account_id      = hcas.cust_account_id    -- �ڋqID
      AND    hps.party_site_id        = hcas.party_site_id      -- �p�[�e�B�T�C�gID
      AND    hcas.org_id              = g_init_rec.org_id       -- �c�ƒP��
      AND    hl.location_id           = hps.location_id         -- ���P�[�V����ID
      AND    hca.status               = cv_cust_status_a        -- �ڋq�X�e�[�^�X���L��
      AND    xoh.lease_class          IN ( cv_lease_class_11    -- ���[�X���
                                         , cv_lease_class_12 )  --   ���̋@�܂��̓V���[�P�[�X
      AND    xoh.object_status        > cv_object_status_101    -- �����X�e�[�^�X�����_�������
      AND    xoh.object_status        < cv_object_status_110    -- �����X�e�[�^�X����������
      AND  ( ( g_lord_head_data_rec.lease_class  IS NULL )                   -- �p�����[�^<���>��NULL
        OR   ( xoh.lease_class        = g_lord_head_data_rec.lease_class ) ) -- �܂��̓p�����[�^<���>�ƈ�v
      AND  ( ( g_lord_head_data_rec.chiku_code   IS NULL )                   -- �p�����[�^<�n��>��NULL
        OR   ( ( g_lord_head_data_rec.chiku_code IS NOT NULL )               -- �܂��̓p�����[�^<�n��>��NOT NULL
        AND    ( hl.address3          = g_lord_head_data_rec.chiku_code ) )  --   �p�����[�^<�n��>�ƒn�悪��v
           )
      AND  ( ( g_lord_head_data_rec.department_code IS NULL )                     -- �p�����[�^<���_>��NULL
        OR   ( ( g_lord_head_data_rec.department_code IS NOT NULL )               -- �܂��̓p�����[�^<���_>��NOT NULL
        AND    ( ( xoh.department_code = g_lord_head_data_rec.department_code )   --   �p�����[�^<���_>�Ƌ����_����v
        OR       ( xcsi1.new_base_code = g_lord_head_data_rec.department_code ) ) --   �܂��̓p�����[�^<���_>�ƐV���_����v
             )
           )
      AND (
           ( ( xoh.lease_type         = cv_lease_type_1 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -1), cv_format_yyyymm) ) )
        OR ( ( xoh.lease_type         = cv_lease_type_2 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -12), cv_format_yyyymm) ) )
          )                                                     -- ��v����
      GROUP BY
             xoh.lease_class
           , xch.lease_type
           , hl.address3
           , xoh.department_code
           , ffvt.description
           , xoh.object_code
           , xch.lease_start_date
           , xch.re_lease_times
           , xoh.re_lease_flag
           , xoh.object_header_id
           , xcsi1.cust_shift_date
           , xcsi1.new_base_code
           , xcsi1.department_name
      UNION ALL
      SELECT /*+ LEADING( FFVS FFV FFVT )
                 INDEX( XOH  XXCFF_OBJECT_HEADERS_N03 )
                 INDEX( XCH  XXCFF_CONTRACT_HEADERS_PK )
                 INDEX( FFVT FFVT FND_FLEX_VALUES_TL_U1 ) */
             cv_record_type_1                                                             AS record_type         -- ���R�[�h�敪
           , xoh.lease_class                                                              AS lease_class         -- ���[�X���
           , DECODE(xoh.lease_class, cv_lease_class_11, g_lookup_budget_itemnm_tab(19)
                                   , cv_lease_class_12, g_lookup_budget_itemnm_tab(20))   AS lease_class_name    -- ���[�X��ʖ�
           , xch.lease_type                                                               AS lease_type          -- ���[�X�敪
           , DECODE(xch.lease_type, cv_lease_type_1, g_lookup_budget_itemnm_tab(21)
                                  , cv_lease_type_2, g_lookup_budget_itemnm_tab(22))      AS lease_type_name     -- ���[�X�敪��
           , NULL                                                                         AS chiku_code          -- �n��R�[�h
           , xoh.department_code                                                          AS department_code     -- ���_�R�[�h
           , ffvt.description                                                             AS department_name     -- ���_��
           , xoh.object_code                                                              AS object_name         -- �����R�[�h
           , ( SELECT ffy.fiscal_year
               FROM   fa_fiscal_year ffy
               WHERE  ffy.fiscal_year_name = cv_fiscal_year_name
               AND    xch.lease_start_date BETWEEN ffy.start_date
                                           AND ffy.end_date )                             AS lease_start_year    -- ���[�X�J�n�N�x
           , MAX(xpp.period_name)                                                         AS lease_end_months    -- ���[�X�x���ŏI��
           , xch.re_lease_times                                                           AS re_lease_times      -- �ă��[�X��
           , xoh.re_lease_flag                                                            AS re_lease_flag       -- �ă��[�X�v�t���O
           , ( SELECT xcl2.second_charge
               FROM   xxcff_contract_headers xch2
                    , xxcff_contract_lines   xcl2
               WHERE  xch2.contract_header_id = xcl2.contract_header_id
               AND    xcl2.object_header_id   = xoh.object_header_id
               AND    xch2.lease_type         = cv_lease_type_1
              )                                                                           AS lease_type_1_charge -- ���_����z
           , SUM(DECODE(xpp.period_name, g_next_year_rec.may,       xpp.lease_charge, 0)) AS may_charge          -- 5��_���[�X��
           , 0                                                                            AS may_number          -- 5��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.june,      xpp.lease_charge, 0)) AS june_charge         -- 6��_���[�X��
           , 0                                                                            AS june_number         -- 6��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.july,      xpp.lease_charge, 0)) AS july_charge         -- 7��_���[�X��
           , 0                                                                            AS july_number         -- 7��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.august,    xpp.lease_charge, 0)) AS august_charge       -- 8��_���[�X��
           , 0                                                                            AS august_number       -- 8��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.september, xpp.lease_charge, 0)) AS september_charge    -- 9��_���[�X��
           , 0                                                                            AS september_number    -- 9��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.october,   xpp.lease_charge, 0)) AS october_charge      -- 10��_���[�X��
           , 0                                                                            AS october_number      -- 10��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.november,  xpp.lease_charge, 0)) AS november_charge     -- 11��_���[�X��
           , 0                                                                            AS november_number     -- 11��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.december,  xpp.lease_charge, 0)) AS december_charge     -- 12��_���[�X��
           , 0                                                                            AS december_number     -- 12��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.january,   xpp.lease_charge, 0)) AS january_charge      -- 1��_���[�X��
           , 0                                                                            AS january_number      -- 1��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.february,  xpp.lease_charge, 0)) AS february_charge     -- 2��_���[�X��
           , 0                                                                            AS february_number     -- 2��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.march,     xpp.lease_charge, 0)) AS march_charge        -- 3��_���[�X��
           , 0                                                                            AS march_number        -- 3��_�䐔
           , SUM(DECODE(xpp.period_name, g_next_year_rec.april,     xpp.lease_charge, 0)) AS april_charge        -- 4��_���[�X��
           , 0                                                                            AS april_number        -- 4��_�䐔
           , NULL                                                                         AS cust_shift_date     -- �ڋq�ڍs��
           , NULL                                                                         AS new_base_code       -- �V���_�R�[�h
           , NULL                                                                         AS new_department_name -- �V���_��
      FROM   xxcff_contract_headers xch                        -- ���[�X�_��w�b�_
           , xxcff_contract_lines   xcl                        -- ���[�X�_�񖾍�
           , xxcff_object_headers   xoh                        -- ���[�X����
           , xxcff_pay_planning     xpp                        -- ���[�X�x���v��
           , fnd_flex_value_sets    ffvs                       -- �l�Z�b�g�l
           , fnd_flex_values        ffv                        -- �l�Z�b�g
           , fnd_flex_values_tl     ffvt                       -- �l��`
      WHERE  xch.contract_header_id   = xcl.contract_header_id -- �_�����ID
      AND    xcl.contract_line_id     = xpp.contract_line_id   -- �_�񖾍ד���ID
      AND    xcl.object_header_id     = xoh.object_header_id   -- ��������ID
      AND    xoh.department_code      = ffv.flex_value(+)      -- �Ǘ�����R�[�h
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id  -- �l�Z�b�gID
      AND    ffvs.flex_value_set_name = cv_department          -- �l�Z�b�g��
      AND    ffv.flex_value_id        = ffvt.flex_value_id     -- �lID
      AND    ffvt.language            = ct_language            -- ����
      AND (  ( xoh.customer_code      IS NULL )                -- �ڋq�R�[�h��NULL
        OR   ( xoh.customer_code      = gv_aff_cust_code ) )   -- �ڋq�R�[�h���v���t�@�C���ƈ�v
      AND    xoh.lease_class          IN ( cv_lease_class_11   -- ���[�X���
                                         , cv_lease_class_12 ) --   ���̋@�܂��̓V���[�P�[�X
      AND    xoh.object_status        > cv_object_status_101   -- �����X�e�[�^�X�����_�������
      AND    xoh.object_status        < cv_object_status_110   -- �����X�e�[�^�X����������
      AND  ( ( g_lord_head_data_rec.lease_class IS NULL )      -- �p�����[�^<���>��NULL
        OR   ( xoh.lease_class        = g_lord_head_data_rec.lease_class ) )      -- �܂��̓p�����[�^<���>�ƈ�v
      AND  ( ( g_lord_head_data_rec.department_code   IS NULL )                   -- �p�����[�^<���_>��NULL
        OR   ( ( g_lord_head_data_rec.department_code IS NOT NULL )               -- �܂��̓p�����[�^<���_>��NOT NULL
        AND    ( xoh.department_code   = g_lord_head_data_rec.department_code ) ) --   �p�����[�^<���_>�Ƌ����_����v
           )
      AND (
           ( ( xoh.lease_type         = cv_lease_type_1 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -1), cv_format_yyyymm) ) )
        OR ( ( xoh.lease_type         = cv_lease_type_2 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -12), cv_format_yyyymm) ) )
          )                                                    -- ��v����
      GROUP BY
             xoh.lease_class
           , xch.lease_type
           , xoh.department_code
           , ffvt.description
           , xoh.object_code
           , xch.lease_start_date
           , xch.re_lease_times
           , xoh.re_lease_flag
           , xoh.object_header_id
      ORDER BY
             object_name
           , lease_end_months DESC
    ;
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
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
      in_file_id,        -- 1.�t�@�C��ID(�K�{)
      iv_file_format,    -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hI/F�擾 (A-2)
    -- ===============================
    get_if_data(
      in_file_id,        -- 1.�t�@�C��ID(�K�{)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �f���~�^�������ڕ��� (A-3)
    -- ===============================
    divide_delimiter(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �f�[�^�Ó����`�F�b�N (A-4)
    -- ===============================
    chk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�X���\�Z���o (A-5)
    -- ===============================
    OPEN get_lease_budget_cur;
    --
    <<lease_budget_loop>>
    LOOP
      -- ������
      g_lease_budget_bulk_tab.DELETE;
      -- ����̂ݐV���񂪊i�[����Ă��邽�ߏ��������Ȃ�
      IF ( ln_cnt > 0 ) THEN
        g_lease_budget_tab.DELETE;
      END IF;
      --
      FETCH get_lease_budget_cur BULK COLLECT INTO g_lease_budget_bulk_tab LIMIT gn_bulk_collect_cnt;
      -- �V���񂨂�ю擾�f�[�^�����݂��Ȃ��ꍇ�A���[�v�𔲂���
      IF ( ( g_lease_budget_tab.COUNT = 0 ) AND ( g_lease_budget_bulk_tab.COUNT = 0 ) ) THEN
        EXIT lease_budget_loop;
      END IF;
      -- �f�[�^���݃`�F�b�N�p
      ln_cnt := ln_cnt + 1;
      -- �擾�f�[�^�����݂���ꍇ
      IF ( g_lease_budget_bulk_tab.COUNT > 0 ) THEN
        <<set_g_lease_budget_tab_loop>>
        FOR i IN g_lease_budget_bulk_tab.FIRST .. g_lease_budget_bulk_tab.LAST LOOP
          -- ���[�X�敪���ă��[�X�A���A
          -- �ă��[�X�v�t���O��1(�ă��[�X���Ȃ�)�̏ꍇ
          IF (  ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_2 )
            AND ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_1 ) ) THEN
            -- ���[�X�I���������N�x5���`���N�x4���̏ꍇ�A�ă��[�X���R�[�h�̂ݏo��
            -- ���[�X�I��������L�ȊO�̏ꍇ�A�o�͂��Ȃ�
            IF (  ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may )
              AND ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.april ) ) THEN
              -- �擾�����ă��[�X���R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- ���[�X�J�n�N�x
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          -- �O�񏈗����R�[�h�ƕ����R�[�h�����Ⴗ��A���A
          -- ���[�X�敪���ă��[�X�A���A
          -- �ă��[�X�v�t���O��0(�ă��[�X����)�̏ꍇ
          ELSIF ( ( g_lease_budget_bulk_tab(i).object_name <> lt_chk_object_code )
            AND   ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_2 )
            AND   ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_0 ) ) THEN
            -- ���[�X�I���������N�x5���`���N�x4���̏ꍇ�A�擾�����ă��[�X���R�[�h�̂ݏo��
            IF ( ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may )
              AND   ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.april ) ) THEN
              -- �擾�����ă��[�X���R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- ���[�X�J�n�N�x
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- ���[�X�I���������N�x5���`���N�x4���̏ꍇ�A�V�~�����[�V�����ă��[�X���R�[�h�̍쐬
            ELSIF (  ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.this_may )
              AND ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.this_april ) ) THEN
              -- �ă��[�X�x�����̎擾
              lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 12), cv_format_yyyymm);
              -- �ă��[�X���̎擾
              IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              END IF;
              -- �V�~�����[�V�����ă��[�X���R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => cv_record_type_2,                               -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- ���[�X�J�n�N�x
                iv_lease_end_months    => lv_re_lease_months,                             -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- ���[�X�I���������N�x5�����O�̏ꍇ�A�V�~�����[�V�����ă��[�X���R�[�h�̍쐬
            ELSIF ( g_lease_budget_bulk_tab(i).lease_end_months < g_next_year_rec.this_may ) THEN
              -- �ă��[�X�x�����̎擾
              lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 24), cv_format_yyyymm);
              -- �ă��[�X���̎擾
              IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              END IF;
              -- �V�~�����[�V�����ă��[�X���R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => cv_record_type_2,                               -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- ���[�X�J�n�N�x
                iv_lease_end_months    => lv_re_lease_months,                             -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          -- ���[�X�敪�����_��A���A�ă��[�X�v�t���O��1(�ă��[�X���Ȃ�)�̏ꍇ
          ELSIF (  ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_1 )
            AND ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_1 ) ) THEN
            -- ���[�X�I���������N�x5�����O�̏ꍇ�A�o�͑ΏۊO�̂��ߏ������Ȃ�
            -- ���[�X�I���������N�x5���ȍ~�̏ꍇ�A�擾�������_�񃌃R�[�h�̂ݏo��
            IF ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may ) THEN
              -- ���_�񃌃R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- ���[�X�J�n�N�x
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          -- ���[�X�敪�����_��A���A�ă��[�X�v�t���O��0(�ă��[�X����)�̏ꍇ
          ELSIF ( ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_1 )
            AND   ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_0 ) ) THEN
            -- ���[�X�I���������N�x3���ȍ~�̏ꍇ�A���_�񃌃R�[�h�̂ݏo��
            IF ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.march ) THEN
              -- ���_�񃌃R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- ���[�X�J�n�N�x
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- �O�񏈗����R�[�h�ƕ����R�[�h�����Ⴗ��A���A
            -- ���[�X�I���������N�x5�����O�̏ꍇ
            ELSIF ( ( g_lease_budget_bulk_tab(i).object_name <> lt_chk_object_code )
              AND   ( g_lease_budget_bulk_tab(i).lease_end_months < g_next_year_rec.may ) ) THEN
              -- ���[�X�I���������N�x3��or���N�x4���̏ꍇ
              IF ( ( g_lease_budget_bulk_tab(i).lease_end_months = g_next_year_rec.this_march )
                OR ( g_lease_budget_bulk_tab(i).lease_end_months = g_next_year_rec.this_april ) )THEN
                -- ����ă��[�X�x�����̎擾
                lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 2), cv_format_yyyymm);
              -- ��L�ȊO�̏ꍇ
              ELSE
                -- 2��ڍă��[�X�x�����̎擾
                lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 14), cv_format_yyyymm);
              END IF;
              -- �ă��[�X���̎擾
              IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              END IF;
              -- �V�~�����[�V�����ă��[�X���R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => cv_record_type_2,                                 -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,           -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,      -- ���[�X��ʖ�
                iv_lease_type          => cv_lease_type_2,                                  -- ���[�X�敪
                iv_lease_type_name     => g_lookup_budget_itemnm_tab(22),                   -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,            -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,       -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,       -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,       -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,         -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name,   -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,           -- �����R�[�h
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,      -- ���[�X�J�n�N�x
                iv_lease_end_months    => lv_re_lease_months,                               -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- ���[�X�I���������N�x5���`���N�x2���̏ꍇ�A���_��ƍă��[�X���R�[�h�̏o��
            ELSIF ( ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may ) 
              AND   ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.february ) ) THEN
              -- ���_�񃌃R�[�h
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- ���R�[�h�敪
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- ���[�X�敪
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- ���[�X�敪��
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- ���[�X�J�n�N�x
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- ���[�X�x���ŏI��
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              -- �ă��[�X���R�[�h�쐬�O�̏ꍇ�A�V�~�����[�V�����ă��[�X���R�[�h�쐬
              -- �ă��[�X���R�[�h�쐬�ς̏ꍇ�A�������Ȃ�
              IF ( g_lease_budget_bulk_tab(i).object_name <> lt_chk_object_code ) THEN
                -- �ă��[�X�x�����̎擾
                lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 2), cv_format_yyyymm);
                -- �ă��[�X���̎擾
                -- ���_��̋��z�����݂��邽��0�ɂ���
                g_lease_budget_bulk_tab(i).may_charge       := 0;
                g_lease_budget_bulk_tab(i).june_charge      := 0;
                g_lease_budget_bulk_tab(i).july_charge      := 0;
                g_lease_budget_bulk_tab(i).august_charge    := 0;
                g_lease_budget_bulk_tab(i).september_charge := 0;
                g_lease_budget_bulk_tab(i).october_charge   := 0;
                g_lease_budget_bulk_tab(i).november_charge  := 0;
                g_lease_budget_bulk_tab(i).december_charge  := 0;
                g_lease_budget_bulk_tab(i).january_charge   := 0;
                g_lease_budget_bulk_tab(i).february_charge  := 0;
                g_lease_budget_bulk_tab(i).march_charge     := 0;
                g_lease_budget_bulk_tab(i).april_charge     := 0;
                -- �x�����̍ă��[�X���̂ݐݒ�
                IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                  g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                  g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                  g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                  g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                  g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                  g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                  g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                  g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                  g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                  g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                  g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                  g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                END IF;
                -- �V�~�����[�V�����ă��[�X���R�[�h
                set_g_lease_budget_tab(
                  iv_record_type         => cv_record_type_2,                               -- ���R�[�h�敪
                  iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- ���[�X���
                  iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- ���[�X��ʖ�
                  iv_lease_type          => cv_lease_type_2,                                -- ���[�X�敪
                  iv_lease_type_name     => g_lookup_budget_itemnm_tab(22),                 -- ���[�X�敪��
                  iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- �n��R�[�h
                  iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- ���_�R�[�h
                  iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- ���_��
                  iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- �ڋq�ڍs��
                  iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- �V���_�R�[�h
                  iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- �V���_��
                  iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- �����R�[�h
                  iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- ���[�X�J�n�N�x
                  iv_lease_end_months    => lv_re_lease_months,                             -- ���[�X�x���ŏI��
                  in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5��_���[�X��
                  in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6��_���[�X��
                  in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7��_���[�X��
                  in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8��_���[�X��
                  in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9��_���[�X��
                  in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10��_���[�X��
                  in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11��_���[�X��
                  in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12��_���[�X��
                  in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1��_���[�X��
                  in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2��_���[�X��
                  in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3��_���[�X��
                  in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4��_���[�X��
                  ov_errbuf              => lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                  ov_retcode             => lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                  ov_errmsg              => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END IF;
          END IF;
          -- �����R�[�h�ύX
          lt_chk_object_code := g_lease_budget_bulk_tab(i).object_name;
          --
        END LOOP set_g_lease_budget_tab_loop;
      END IF;
--
      -- ===============================
      -- ���[�X���\�Z���[�N�쐬 (A-6)
      -- ===============================
      ins_lease_budget_wk(
        in_file_id,        -- 1.�t�@�C��ID(�K�{)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP lease_budget_loop;
    --
    CLOSE get_lease_budget_cur;
--
    -- �擾����0���̏ꍇ
    IF ( ln_cnt = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00165
                             ,iv_token_name1  => cv_tkn_get_data
                             ,iv_token_value1 => cv_msg_xxcff_50190)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�͑ΏۊO�����R�[�h�f�[�^�폜 (A-7)
    -- ===============================
    IF ( g_lookup_budget_objcode_tab.COUNT <> 0 ) THEN
      del_object_code_data(
        in_file_id,        -- 1.�t�@�C��ID(�K�{)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- �p�����f�[�^�X�V (A-8)
    -- ===============================
    upd_scrap_data(
      in_file_id,        -- 1.�t�@�C��ID(�K�{)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�̓t�@�C���쐬 (A-9)
    -- ===============================
    create_output_file(
      in_file_id,        -- 1.�t�@�C��ID(�K�{)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�hI/F�폜 (A-10)
    -- ===============================
    del_if_data(
      in_file_id,        -- 1.�t�@�C��ID(�K�{)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���[�X���\�Z���[�N�폜 (A-11)
    -- ===============================
    del_lease_budget_wk(
      in_file_id,        -- 1.�t�@�C��ID(�K�{)
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
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
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_lease_budget_cur%ISOPEN ) THEN
        CLOSE get_lease_budget_cur;
      END IF;
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    in_file_id     IN  NUMBER,        -- 1.�t�@�C��ID(�K�{)
    iv_file_format IN  VARCHAR2       -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
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
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_file_type_log
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
       in_file_id     -- 1.�t�@�C��ID(�K�{)
      ,iv_file_format -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which => FND_FILE.LOG
        ,buff  => lv_errbuf
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
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
END XXCFF015A34C;
/
