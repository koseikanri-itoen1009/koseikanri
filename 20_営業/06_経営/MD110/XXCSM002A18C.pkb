CREATE OR REPLACE PACKAGE BODY XXCSM002A18C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 *
 * Package Name     : XXCSM002A18C(body)
 * Description      : �A�b�v���[�h�t�@�C������P�i�ʂ̔N�ԏ��i�v��f�[�^�̐􂢑ւ�
 * MD.050           : �N�ԏ��i�v��P�i�ʃA�b�v���[�h MD050_CSM_002_A18
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 ���C�������v���V�[�W��
 *  submain              �T�u���C�������v���V�[�W��
 *  init_proc            ��������(A-1)
 *  get_upload_line      �A�b�v���[�h�f�[�^�擾(A-2)
 *  chk_upload_item      �A�b�v���[�h���ڃ`�F�b�N(A-3)
 *  chk_validate_item    �Ó����`�F�b�N����(A-4)
 *  chk_budget_item      �A�b�v���[�h�\�Z�l�`�F�b�N
 *  set_item_bgt         �P�i�\�Z�ݒ�(A-5)
 *  calc_budget_item     �\�Z�l�Z�o
 *  exchange_item_bgt    �P�i�\�Z�􂢑ւ�(A-6)
 *  del_upload_data      �A�b�v���[�h�f�[�^�폜(A-8)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2019/01/30    1.0   K.Nara           �V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���萔
  ------------------------------------------------------------
  -- �p�b�P�[�W��`
  cv_pkg_name                      CONSTANT VARCHAR2(12) := 'XXCSM002A18C';      -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_csm           CONSTANT VARCHAR2(10) := 'XXCSM';
  -- ���ʃ��b�Z�[�W��`
  cv_nrmal_msg                     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
  cv_warn_msg                      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
  cv_error_msg                     CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';  -- �G���[�I�����b�Z�[�W
  cv_mainmsg_90000                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';  -- �Ώی����o��
  cv_mainmsg_90001                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';  -- ���������o��
  cv_mainmsg_90002                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';  -- �G���[�����o��
  cv_mainmsg_90003                 CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';  -- �X�L�b�v�����o��
  -- �ʃ��b�Z�[�W��`
  cv_msg_xxcsm00004                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00004';  -- �\�Z�N�x�`�F�b�N�G���[
  cv_msg_xxcsm00005                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00005';  -- �v���t�@�C���擾�G���[
  cv_msg_xxcsm00006                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00006';  -- �N�Ԕ̔��v��J�����_�[�����݃G���[
  cv_msg_xxcsm00037                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00037';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcsm00050                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00050';  -- ���ʔ���̍����`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcsm00051                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00051';  -- ����Q�\�Z�����G���[���b�Z�[�W
  cv_msg_xxcsm00059                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00059';  -- ���O�C�����[�U�[�ݐЋ��_�擾�G���[
  cv_msg_xxcsm00101                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00101';  -- �t�@�C��ID�p�����[�^
  cv_msg_xxcsm00102                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-00102';  -- �t�@�C���p�^�[���p�����[�^
  cv_msg_xxcsm10138                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10138';  -- �V���i�R�[�h�擾�G���[���b�Z�[�W
  --
  cv_msg_xxcsm10234                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10234';  -- ���b�N�G���[���b�Z�[�W
  cv_msg_xxcsm10238                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10238';  -- ���i�v�斾�׃e�[�u����
  cv_msg_xxcsm10301                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10301';  -- ���ڐ�����G���[���b�Z�[�W
  cv_msg_xxcsm10302                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10302';  -- ���ڕs���G���[���b�Z�[�W
  cv_msg_xxcsm10303                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10303';  -- �Ɩ��������t�擾�G���[
  cv_msg_xxcsm10304                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10304';  -- BLOB�f�[�^�ϊ��G���[
  cv_msg_xxcsm10305                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10305';  -- �A�b�v���[�h�����ΏۂȂ��G���[
  cv_msg_xxcsm10306                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10306';  -- �w�苒�_�G���[
  cv_msg_xxcsm10307                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10307';  -- �������_�G���[
  cv_msg_xxcsm10308                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10308';  -- �w��\�Z�N�x�G���[
  cv_msg_xxcsm10309                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10309';  -- �����\�Z�N�x�G���[
  cv_msg_xxcsm10310                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10310';  -- ���R�[�h�敪�����G���[
  cv_msg_xxcsm10311                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10311';  -- ���R�[�h�敪�����G���[
  cv_msg_xxcsm10312                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10312';  -- ���R�[�h�敪���
  cv_msg_xxcsm10313                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10313';  -- ���i�Q�A���i�R�[�h�g�����G���[
  cv_msg_xxcsm10314                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10314';  -- ���i�Q�\�Z���o�^�G���[
  cv_msg_xxcsm10315                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10315';  -- �c�ƌ����擾�G���[
  cv_msg_xxcsm10316                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10316';  -- �艿�擾�G���[
  cv_msg_xxcsm10317                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10317';  -- ����w��G���[
  cv_msg_xxcsm10318                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10318';  -- �e���z�A�e�����A�|�������w��G���[
  cv_msg_xxcsm10319                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10319';  -- ���e�͈̓G���[
  cv_msg_xxcsm10320                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10320';  -- �N�C�b�N�R�[�h�擾�G���[
  cv_msg_xxcsm10321                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10321';  -- �t�@�C���A�b�v���[�h���b�N�G���[
  cv_msg_xxcsm10322                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10322';  -- �t�@�C���A�b�v���[�hIF�폜�G���[
  cv_msg_xxcsm10323                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10323';  -- �V���i����A�e���v�z�}�C�i�X�x�����b�Z�[�W
  cv_msg_xxcsm10324                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10324';  -- �����_�ȉ��w��G���[
  cv_msg_xxcsm10325                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10325';  -- �N�Ԍv�斢�o�^�G���[
  cv_msg_xxcsm10326                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10326';  -- �\�Z�l�Z�o�G���[
  cv_msg_xxcsm10327                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10327';  -- �o�^�O���i�w��G���[
  cv_msg_xxcsm10328                CONSTANT VARCHAR2(16) := 'APP-XXCSM1-10328';  -- ����NULL�G���[
  --
  -- ���b�Z�[�W�g�[�N����`
  cv_tkn_file_id                   CONSTANT VARCHAR2(20) := 'FILE_ID';           -- �t�@�C��ID�g�[�N��
  cv_tkn_format                    CONSTANT VARCHAR2(20) := 'FORMAT';            -- �t�@�C���p�^�[��
  cv_tkn_prof_name                 CONSTANT VARCHAR2(20) := 'PROF_NAME';         -- �v���t�@�C����
  cv_tkn_item                      CONSTANT VARCHAR2(20) := 'ITEM';              -- ����
  cv_tkn_user_id                   CONSTANT VARCHAR2(20) := 'USER_ID';           -- ���[�UID
  cv_tkn_errmsg                    CONSTANT VARCHAR2(20) := 'ERRMSG';            -- �G���[���e�ڍ�
  cv_tkn_row_num                   CONSTANT VARCHAR2(20) := 'ROW_NUM';           -- �G���[�s
  cv_tkn_kyoten_cd                 CONSTANT VARCHAR2(20) := 'KYOTEN_CD';         -- ���_�R�[�h
  cv_tkn_yosan_nendo               CONSTANT VARCHAR2(20) := 'YOSAN_NENDO';       -- �\�Z�N�x
  cv_tkn_yyyy                      CONSTANT VARCHAR2(100):= 'YYYY';              -- YYYY
  cv_tkn_month                     CONSTANT VARCHAR2(20) := 'MONTH';             -- ��
  cv_tkn_deal_cd                   CONSTANT VARCHAR2(20) := 'DEAL_CD';           -- ���i�Q
  cv_tkn_item_cd                   CONSTANT VARCHAR2(20) := 'ITEM_CD';           -- ���i�R�[�h
  cv_tkn_rec_type                  CONSTANT VARCHAR2(20) := 'REC_TYPE';          -- ���R�[�h�^�C�v
  cv_tkn_column                    CONSTANT VARCHAR2(20) := 'COLUMN';            -- ���ږ�
  cv_tkn_min                       CONSTANT VARCHAR2(20) := 'MIN';               -- �ŏ��l
  cv_tkn_max                       CONSTANT VARCHAR2(20) := 'MAX';               -- �ŏ��l
  cv_tkn_lookup_value_set          CONSTANT VARCHAR2(20) := 'LOOKUP_VALUE_SET';  -- �^�C�v
  cv_tkn_count                     CONSTANT VARCHAR2(20) := 'COUNT';             -- ����
  cv_tkn_value                     CONSTANT VARCHAR2(20) := 'VALUE';             -- �l
  cv_tkn_org_code                  CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';      -- �݌ɑg�D�R�[�h
  cv_tkn_table                     CONSTANT VARCHAR2(20) := 'TABLE';             --�e�[�u����
  cv_output                        CONSTANT VARCHAR2(6)  := 'OUTPUT';            -- �w�b�_���O�o��
  -- �����l
  cv_y                             CONSTANT VARCHAR2(1)  := 'Y';                 -- 'Y'
  cv_n                             CONSTANT VARCHAR2(1)  := 'N';                 -- 'N'
  cn_0                             CONSTANT NUMBER       := 0;                   -- ���l:0
  cn_1                             CONSTANT NUMBER       := 1;                   -- ���l:1
  cv_a                             CONSTANT VARCHAR2(1)  := 'A';                 -- 'A'
  cv_b                             CONSTANT VARCHAR2(1)  := 'B';                 -- 'B'
  cv_c                             CONSTANT VARCHAR2(1)  := 'C';                 -- 'C'
  cv_d                             CONSTANT VARCHAR2(1)  := 'D';                 -- 'D'
  cv_z                             CONSTANT VARCHAR2(1)  := 'Z';                 -- 'Z'
  cv_blank                         CONSTANT VARCHAR2(1)  := ' ';                 --���p�X�y�[�X
  ct_lang                          CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
  cv_rec_type_a_name               CONSTANT VARCHAR2(10) := '����';              -- ���R�[�h�敪��
  cv_rec_type_b_name               CONSTANT VARCHAR2(10) := '�e���z';            -- ���R�[�h�敪��
  cv_rec_type_c_name               CONSTANT VARCHAR2(10) := '�e����';            -- ���R�[�h�敪��
  cv_rec_type_d_name               CONSTANT VARCHAR2(10) := '�|��';              -- ���R�[�h�敪��
  cv_amount                        CONSTANT VARCHAR2(10) := '����';
  --�͈̓`�F�b�N�p
  cn_min_gross                     CONSTANT NUMBER       := -999999999999;       -- ���z�ŏ��l
  cn_max_gross                     CONSTANT NUMBER       :=  999999999999;       -- ���z�ő�l
  cn_min_rate                      CONSTANT NUMBER       := -999.99;             -- �ŏ���
  cn_max_rate                      CONSTANT NUMBER       :=  999.99;             -- �ő嗦
  cn_min_crerate                   CONSTANT NUMBER       :=  1;                  -- �ŏ���
  cn_max_crerate                   CONSTANT NUMBER       :=  999.99;             -- �ő嗦
  cn_min_amount                    CONSTANT NUMBER       :=  0;                  -- �ŏ�����
  cn_max_amount                    CONSTANT NUMBER       :=  9999999999999.9;    -- �ő吔��
  --�Q�ƃ^�C�v
  cv_upload_item_chk_name          CONSTANT VARCHAR2(30) := 'XXCSM1_ITEM_BGT_UPLOAD_ITEM'; -- �N�ԏ��i�v��P�i�ʃA�b�v���[�h���ڃ`�F�b�N
  cv_lookup_type_bara              CONSTANT VARCHAR2(30) := 'XXCSM1_UNIT_KG_G';            -- �o�����ʒP��
  cv_lookup_type_dmy_dept          CONSTANT VARCHAR2(30) := 'XXCSM1_DUMMY_DEPT';           -- �_�~�[�K�w
  cv_out_regist_item               CONSTANT VARCHAR2(30) := 'XXCSM1_OUT_REGIST_ITEM';      -- �o�^�O���i
  --�v���t�@�C���I�v�V������
  cv_prof_yearplan_calender        CONSTANT VARCHAR2(30) := 'XXCSM1_YEARPLAN_CALENDER';  -- XXCSM:�N�Ԕ̔��v��J�����_�[��
  cv_prof_deal_category            CONSTANT VARCHAR2(30) := 'XXCSM1_DEAL_CATEGORY';      -- XXCSM:����Q�i�ڃJ�e�S�����薼
  cv_prof_organization_code        CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';  -- XXCOI:�݌ɑg�D�R�[�h
  cv_xxcsm1_dummy_dept_ref         CONSTANT VARCHAR2(30) := 'XXCSM1_DUMMY_DEPT_REF';     -- XXCSM:�_�~�[����K�w�Q��
  cv_gl_set_of_bks_id_nm           CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';          -- GL��v����ID
  -- ���i�̔��v�揤�i�敪
  cv_item_kbn_group                CONSTANT VARCHAR2(1)  := '0';                  -- 0:���i�Q
  cv_item_kbn_tanpin               CONSTANT VARCHAR2(1)  := '1';                  -- 1:�P�i
  cv_item_kbn_new                  CONSTANT VARCHAR2(1)  := '2';                  -- 2:�V���i
  -- �N�ԌQ�\�Z�敪
  cv_budget_kbn_month              CONSTANT VARCHAR2(1)  := '0';                  -- 0:�e���P�ʗ\�Z
  cv_budget_kbn_year               CONSTANT VARCHAR2(1)  := '1';                  -- 1:�N�ԌQ�\�Z
  -- �X�e�[�^�X�E�R�[�h
  cv_status_check                  CONSTANT VARCHAR2(1)  := '9';                  -- �`�F�b�N�G���[:9
  cv_ap_type_xxccp                 CONSTANT VARCHAR2(5)  := 'XXCCP';              -- ����
  ------------------------------------------------------------
  -- ���[�U�[��`�O���[�o���ϐ�
  ------------------------------------------------------------
  gn_user_id                                NUMBER;                   -- ���[�U�[ID
  gd_proc_date                              DATE         := NULL;     -- �Ɩ��������t
  gd_start_date                             DATE;
  gv_group_status                           VARCHAR2(1);
  -- �`�F�b�N���ڊi�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning           fnd_lookup_values.meaning%TYPE    -- ���ږ���
    , attribute1        fnd_lookup_values.attribute1%TYPE -- ���ڂ̒���
    , attribute2        fnd_lookup_values.attribute2%TYPE -- ���ڂ̒����i�����_�ȉ��j
    , attribute3        fnd_lookup_values.attribute3%TYPE -- �K�{�t���O
    , attribute4        fnd_lookup_values.attribute4%TYPE -- ����
  );
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  g_chk_item_tab              g_chk_item_ttype;             -- ���ڃ`�F�b�N
  --
  gn_item_cnt                               NUMBER := 0;    -- CSV�K�荀�ڐ�
  --�v���t�@�C���l
  gv_prof_yearplan_calender                 VARCHAR2(100);  --XXCSM:�N�Ԕ̔��v��J�����_�[��
  gv_prof_deal_category                     VARCHAR2(100);  --XXCSM:����Q�i�ڃJ�e�S�����薼
  gv_prof_organization_code                 VARCHAR2(100);  --XXCOI:�݌ɑg�D�R�[�h
  gv_dummy_dept_ref                         VARCHAR2(1);    --XXCSM:�_�~�[����K�w�Q��
  gn_gl_set_of_bks_id                       NUMBER;         --��v����ID
  --
  gn_organization_id                        NUMBER;         --�݌ɑg�DID
  gv_user_foothold                          VARCHAR2(4);    --���[�U�[�ݐЋ��_�R�[�h(p_user_foothold)
  gt_plan_year                              xxcsm_item_plan_headers.plan_year%TYPE;    -- �\�Z�N�x
  gt_item_plan_header_id                    xxcsm_item_plan_headers.item_plan_header_id%TYPE;
  --
  -- �A�b�v���[�h���R�[�h�^�C�v
  TYPE g_upload_data_rtype IS RECORD (
    location_cd     xxcsm_item_plan_headers.location_cd%TYPE
   ,plan_year       xxcsm_item_plan_headers.plan_year%TYPE
   ,item_group_no   xxcsm_item_plan_lines.item_group_no%TYPE
   ,item_no         xxcsm_item_plan_lines.item_no%TYPE
   ,item_name       xxcsm_commodity_group3_v.item_nm%TYPE
   ,rec_type        VARCHAR2(1)
   ,month_05        NUMBER(14,2)  --������z�A�e���v�A�e���v���A�|���̍ő吸�x
   ,month_06        NUMBER(14,2)
   ,month_07        NUMBER(14,2)
   ,month_08        NUMBER(14,2)
   ,month_09        NUMBER(14,2)
   ,month_10        NUMBER(14,2)
   ,month_11        NUMBER(14,2)
   ,month_12        NUMBER(14,2)
   ,month_01        NUMBER(14,2)
   ,month_02        NUMBER(14,2)
   ,month_03        NUMBER(14,2)
   ,month_04        NUMBER(14,2)
   --�ȉ��������t�����
   ,bara_kbn        VARCHAR2(1)  --�o���敪(Y:�o���P�ʁAN:�o���P�ʂłȂ�)
   ,discrete_cost   xxcmm_system_items_b_hst.discrete_cost%TYPE  --�c�ƌ���
   ,fixed_price     xxcmm_system_items_b_hst.fixed_price%TYPE    --�艿
  );
  -- �A�b�v���[�h�e�[�u���i���i�Q�A���i�R�[�h�A���R�[�h�敪���j�iINDEX = BINARY_INTEGER�j
  TYPE g_upload_data_ttype_i IS TABLE OF g_upload_data_rtype INDEX BY BINARY_INTEGER;
  g_upload_data_tab     g_upload_data_ttype_i;
  -- ���i���Ƃ̃��R�[�h�敪�������i�[���郌�R�[�h
  TYPE g_upload_item_rtype IS RECORD (
    location_cd     xxcsm_item_plan_headers.location_cd%TYPE
   ,plan_year       xxcsm_item_plan_headers.plan_year%TYPE
   ,item_group_no   xxcsm_item_plan_lines.item_group_no%TYPE
   ,item_no         xxcsm_item_plan_lines.item_no%TYPE
   ,rec_type_a      NUMBER
   ,rec_type_b      NUMBER
   ,rec_type_c      NUMBER
   ,rec_type_d      NUMBER
   ,else_type       NUMBER
  );
  -- ���_�A�N�x�A���i���Ƃ̃��R�[�h�敪�������i�[���郌�R�[�h
  TYPE g_upload_item_ttype IS TABLE OF g_upload_item_rtype INDEX BY BINARY_INTEGER;
  g_upload_item_tab   g_upload_item_ttype;
  --�P�i�\�Z�o�^��
  TYPE t_item_plan_lines_ttype IS TABLE OF xxcsm_item_plan_lines%ROWTYPE INDEX BY BINARY_INTEGER;
  g_item_line_tab            t_item_plan_lines_ttype;
  --�P�i�\�Z���v
  TYPE g_item_bgt_sum_rtype IS RECORD(
    sales_budget           NUMBER
   ,amount_gross_margin    NUMBER
  );
  TYPE g_item_bgt_sum_ttype       IS TABLE OF g_item_bgt_sum_rtype INDEX BY BINARY_INTEGER;
  g_item_bgt_sum_tab              g_item_bgt_sum_ttype;    -- �P�i�\�Z���v
  --�o���P��
  TYPE g_bara_unit_ttype IS TABLE OF VARCHAR2(80) INDEX BY BINARY_INTEGER;
  g_bara_unit_tab                 g_bara_unit_ttype;
  --�o�^�O���i
  TYPE g_out_regist_item_ttype IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
  g_out_regist_item_tab           g_out_regist_item_ttype;

  --
  ------------------------------------------------------------
  -- ���[�U�[��`��O
  ------------------------------------------------------------
  -- ��O
  global_lock_expt       EXCEPTION; -- �O���[�o����O
  -- �v���O�}
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : del_upload_data
   * Description      : �A�b�v���[�h�f�[�^�폜(A-8)
   ***********************************************************************************/
  PROCEDURE del_upload_data(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_file_id IN VARCHAR2  -- �t�@�C��ID
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_upload_data'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg VARCHAR2(2000);  -- ���b�Z�[�W
    lb_retcode BOOLEAN;         -- API���^�[���E���b�Z�[�W�p
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �t�@�C���A�b�v���[�h�폜���b�N�J�[�\����`
    CURSOR file_delete_cur
    IS
      SELECT xmf.file_id AS file_id          -- �t�@�C��ID
      FROM   xxccp_mrp_file_ul_interface xmf -- �t�@�C���A�b�v���[�h�e�[�u��
      WHERE  xmf.file_id = TO_NUMBER(iv_file_id)
      FOR UPDATE NOWAIT;
    --===============================
    -- ���[�J����O
    --===============================
    delete_err_expt EXCEPTION; -- �폜�G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1,�A�b�v���[�h�f�[�^���b�N
    -------------------------------------------------
    -- ���b�N����
    OPEN file_delete_cur;
    CLOSE file_delete_cur;
    -------------------------------------------------
    -- 2,�A�b�v���[�h�f�[�^�폜
    -------------------------------------------------
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE xmf.file_id = TO_NUMBER(iv_file_id);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE delete_err_expt;
    END;
  --
  EXCEPTION
    -- *** ���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10321
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => iv_file_id
                    );    
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �폜��O�n���h�� ***
    WHEN delete_err_expt THEN
      -- ���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10322
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => iv_file_id
                    );    
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
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
  END del_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : exchange_item_bgt
   * Description      : �P�i�\�Z�􂢑ւ�(A-6)
   ***********************************************************************************/
  PROCEDURE exchange_item_bgt(
     ov_errbuf        OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'exchange_item_bgt'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    -- �P�i�폜���b�N�J�[�\��
    CURSOR item_line_lock_cur
    IS
      SELECT  item_plan_header_id
      FROM    xxcsm_item_plan_lines xipl
      WHERE  item_plan_header_id = gt_item_plan_header_id
      AND    item_group_no = g_item_line_tab(1).item_group_no
      AND    item_kbn = cv_item_kbn_tanpin      --1:�P�i
      FOR UPDATE NOWAIT
      ;
    -- ���i�Q�ʃf�[�^�擾
    CURSOR item_group_cur
    IS
      SELECT  xipl.sales_budget           AS sales_budget                    --�u������z�v
             ,xipl.amount_gross_margin    AS amount_gross_margin             --�u�e���v(�V)�v
             ,xipl.month_no               AS month_no                        --�u���v
             ,xipl.year_month             AS year_month                      --�u�N���v
             ,xipl.item_group_no          AS item_group_no                   --�u���i�Q�R�[�h�v
      FROM    xxcsm_item_plan_lines    xipl                                  --�w���i�v�斾�׃e�[�u���x
      WHERE   xipl.item_plan_header_id = gt_item_plan_header_id              -- ���i�v��w�b�_ID
      AND     xipl.item_kbn            = cv_item_kbn_group                   -- ���i�敪(���i�Q)
      AND     xipl.item_group_no       = g_item_line_tab(1).item_group_no    -- ���i�Q�R�[�h
      AND     xipl.year_bdgt_kbn       = cv_budget_kbn_month                 -- �N�ԌQ�\�Z�敪(0:�e���P�ʗ\�Z)
      ORDER BY xipl.year_month
    ;
    --
    lv_dummy               VARCHAR2(1);
    lt_new_item_no         mtl_categories_b.attribute3%TYPE;
    lv_tab_name            VARCHAR2(500);   --�e�[�u����
    ln_cnt                 NUMBER;
    l_rowid                UROWID;
    lv_step                VARCHAR2(200);
    --�V���i
    lt_new_item_sales_budget        xxcsm_item_plan_lines.sales_budget%TYPE;         --����
    lt_new_item_amount_gross_mgn    xxcsm_item_plan_lines.amount_gross_margin%TYPE;  --�e���z
    lt_new_item_credit_rate         xxcsm_item_plan_lines.credit_rate%TYPE;          --�|��
    lt_new_item_amount              xxcsm_item_plan_lines.amount%TYPE;               --����
    lt_new_item_discrete_cost       xxcmm_system_items_b_hst.discrete_cost%TYPE;     --�c�ƌ���
    lt_new_item_fixed_price         xxcmm_system_items_b_hst.fixed_price%TYPE;       --�艿
    --
  BEGIN
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    --
    IF gv_group_status = cv_status_normal THEN
      -------------------------------------------------
      -- 1.���i�v�斾�׃e�[�u���s���b�N�i�P�i�\�Z�j
      -------------------------------------------------
      lv_step := '�P�i�\�Z�폜 '||g_item_line_tab(1).item_group_no;
      OPEN item_line_lock_cur;
      CLOSE item_line_lock_cur;
      -------------------------------------------------
      -- 2.�P�i�\�Z�폜
      -------------------------------------------------
      DELETE xxcsm_item_plan_lines
      WHERE  item_plan_header_id = gt_item_plan_header_id
      AND    item_group_no = g_item_line_tab(1).item_group_no
      AND    item_kbn = '1'      --1:���i�P�i
      ;
      -------------------------------------------------
      -- 3.�P�i�\�Z�o�^
      -------------------------------------------------
      lv_step := '�P�i�\�Z�o�^ '||g_item_line_tab(1).item_group_no;
      FORALL i in 1..g_item_line_tab.COUNT
        INSERT INTO xxcsm_item_plan_lines VALUES g_item_line_tab(i);
    END IF;
    -------------------------------------------------
    -- 4.�V���i�\�Z�X�V
    -------------------------------------------------
    -------------------------------------------------
    -- 4-1.�V���i�R�[�h�擾
    -------------------------------------------------
    lv_step := '�V���i�R�[�h�擾 '||g_item_line_tab(1).item_group_no;
    BEGIN
      SELECT  DISTINCT mcb.attribute3     AS new_item_no
      INTO    lt_new_item_no
      FROM    mtl_categories_b       mcb              --�w�J�e�S���x
             ,mtl_category_sets_b    mcsb             --�w�J�e�S���Z�b�g�x 
             ,mtl_category_sets_tl   mcst             --�w�J�e�S���Z�b�g���{��x
      WHERE  mcst.category_set_name  = gv_prof_deal_category
      AND    mcst.language           = ct_lang
      AND    mcst.category_set_id    = mcsb.category_set_id
      AND    mcsb.structure_id       = mcb.structure_id
      AND    mcb.segment1            LIKE SUBSTR(g_item_line_tab(1).item_group_no, 1, 3) || '_'
      AND    mcb.attribute3          IS NOT NULL
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10138
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => g_item_line_tab(1).item_group_no
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
    END;
    -------------------------------------------------
    -- 4-2.�V���i�c�ƌ����擾
    -------------------------------------------------
    lv_step := '�V���i�c�ƌ����擾 '||g_item_line_tab(1).item_group_no;
    BEGIN
      -- �O�N�x�̉c�ƌ�����i�ڕύX��������擾
      SELECT xsibh.discrete_cost                           -- �c�ƌ���
      INTO   lt_new_item_discrete_cost
      FROM   xxcmm_system_items_b_hst   xsibh              -- �i�ڕύX�����e�[�u��
            ,(SELECT MAX(item_hst_id)   item_hst_id        -- �i�ڕύX����ID
              FROM   xxcmm_system_items_b_hst              -- �i�ڕύX����
              WHERE  item_code  = lt_new_item_no           -- �i�ڃR�[�h
              AND    apply_date < gd_start_date            -- �N�x�J�n���O
              AND    apply_flag = cv_y                     -- �K�p�ς�
              AND    discrete_cost IS NOT NULL             -- �c�ƌ��� IS NOT NULL
             ) xsibh_view
      WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- �i�ڕύX����ID
      AND    xsibh.item_code   = lt_new_item_no            -- �V���i�R�[�h
      AND    xsibh.apply_flag  = cv_y                      -- �K�p�ς�
      AND    xsibh.discrete_cost IS NOT NULL
      ;
        --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --�c�ƌ����擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10315                 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_item_line_tab(1).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                    -- �g�[�N���R�[�h2
                       , iv_token_value2 => lt_new_item_no                    -- �g�[�N���l2�i���i�R�[�h�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
    END;
    --
    -------------------------------------------------
    -- 4-3.�V���i�艿�擾
    -------------------------------------------------
    lv_step := '�V���i�艿�擾 '||g_item_line_tab(1).item_group_no;
    BEGIN
      -- �O�N�x�̒艿��i�ڕύX��������擾
      SELECT xsibh.fixed_price                             -- �艿
      INTO   lt_new_item_fixed_price
      FROM   xxcmm_system_items_b_hst   xsibh              -- �i�ڕύX�����e�[�u��
            ,(SELECT MAX(item_hst_id)   item_hst_id        -- �i�ڕύX����ID
              FROM   xxcmm_system_items_b_hst              -- �i�ڕύX����
              WHERE  item_code  = lt_new_item_no           -- �i�ڃR�[�h
              AND    apply_date < gd_start_date            -- �N�x�J�n���O
              AND    apply_flag = cv_y                     -- �K�p�ς�
              AND    fixed_price IS NOT NULL               -- �艿 IS NOT NULL
                ) xsibh_view
      WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id    -- �i�ڕύX����ID
      AND    xsibh.item_code   = lt_new_item_no            -- �V���i�R�[�h
      AND    xsibh.apply_flag  = cv_y                      -- �K�p�ς�
      AND    xsibh.fixed_price IS NOT NULL
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --�艿�擾�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10316                 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                    -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_item_line_tab(1).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                    -- �g�[�N���R�[�h2
                       , iv_token_value2 => lt_new_item_no                    -- �g�[�N���l2�i���i�R�[�h�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
    END;
    --
    IF ov_retcode = cv_status_check THEN
      RETURN;
    END IF;
    -------------------------------------------------
    -- 4-4.�V���i�̔���A�e���z�A�|���A���ʎZ�o
    -------------------------------------------------
    --���i�Q�\�Z���ʃ��[�v
    ln_cnt := 1;
    FOR item_group_rec IN item_group_cur LOOP
      -------------------------------------------------
      -- �V���i�o�^�l�Z�o�i����A�e���z�A�|���A���ʁj
      -------------------------------------------------
      --�V���i����
      lv_step := '�V���i�̔���Z�o['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      BEGIN
        lt_new_item_sales_budget     := item_group_rec.sales_budget - g_item_bgt_sum_tab(ln_cnt).sales_budget;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => item_group_rec.item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => lt_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�V���i�̔���Z�o > ���i�Q����(��~)='||TO_CHAR(item_group_rec.sales_budget / 1000)||' �P�i���㍇�v(��~)='||TO_CHAR(g_item_bgt_sum_tab(ln_cnt).sales_budget / 1000)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --�V���i�e���z
      lv_step := '�V���i�̑e���z�Z�o['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      BEGIN
        lt_new_item_amount_gross_mgn := item_group_rec.amount_gross_margin - g_item_bgt_sum_tab(ln_cnt).amount_gross_margin;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => item_group_rec.item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => lt_new_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�V���i�̑e���z�Z�o > ���i�Q�e���z(��~)='||TO_CHAR(item_group_rec.amount_gross_margin / 1000)||' �P�i�e���z���v(��~)='||TO_CHAR(g_item_bgt_sum_tab(ln_cnt).amount_gross_margin / 1000)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      --�V���i����
      lv_step := '�V���i�̐��ʎZ�o['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      IF lt_new_item_discrete_cost = 0 THEN
        lt_new_item_amount := 0;
      ELSE
        BEGIN
          --���� = (���� - �e���v�z) / �c�ƌ����̏����_��1�ʂ��l�̌ܓ�
          lt_new_item_amount := ROUND( ( lt_new_item_sales_budget - lt_new_item_amount_gross_mgn ) / lt_new_item_discrete_cost, 0);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => item_group_rec.item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => lt_new_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�V���i�̐��ʎZ�o > �V���i����(��~)='||TO_CHAR(lt_new_item_sales_budget / 1000)||' �V���i�e���z(��~)='||TO_CHAR(lt_new_item_amount_gross_mgn / 1000)||' �V���i�c�ƌ���='||TO_CHAR(lt_new_item_discrete_cost)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
        --
      END IF;
      --
      --�V���i�|��
      lv_step := '�V���i�̊|���Z�o['||item_group_rec.item_group_no||' / '||TO_CHAR(item_group_rec.year_month)||']';
      IF lt_new_item_amount * lt_new_item_fixed_price = 0 THEN
        lt_new_item_credit_rate := 0;
      ELSE
        --�|�� = ( ���� / (�艿 * ����) * 100 )�̏����_��3�ʂ��l�̌ܓ�
        BEGIN
          lt_new_item_credit_rate := ROUND( ( lt_new_item_sales_budget / ( lt_new_item_fixed_price * lt_new_item_amount ) * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => item_group_rec.item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => lt_new_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(item_group_rec.year_month)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�V���i�̊|���Z�o > �V���i����(��~)='||TO_CHAR(lt_new_item_sales_budget / 1000)||' �V���i�艿='||TO_CHAR(lt_new_item_fixed_price)||' �V���i����='||TO_CHAR(lt_new_item_amount)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
        --
      END IF;
      --
      IF ov_retcode = cv_status_normal THEN
        -------------------------------------------------
        -- �V���i�\�Z���R�[�h���b�N�i�V���i�A�Y�����j
        -------------------------------------------------
        SELECT rowid
        INTO   l_rowid
        FROM   xxcsm_item_plan_lines    xipl                               --�w���i�v�斾�׃e�[�u���x
        WHERE   xipl.item_plan_header_id = gt_item_plan_header_id          -- ���i�v��w�b�_ID
        AND     year_month               = item_group_rec.year_month
        AND     xipl.year_bdgt_kbn       = cv_budget_kbn_month             -- �N�ԌQ�\�Z�敪(0:�e���P�ʗ\�Z)
        AND     xipl.item_kbn            = cv_item_kbn_new                 -- ���i�敪(�V���i)
        AND     xipl.item_no             = lt_new_item_no
        AND     xipl.item_group_no       = g_item_line_tab(1).item_group_no
        FOR UPDATE NOWAIT
        ;
        --
        -------------------------------------------------
        -- �V���i�\�Z�X�V
        -------------------------------------------------
        UPDATE xxcsm_item_plan_lines
        SET sales_budget           = lt_new_item_sales_budget
           ,amount_gross_margin    = lt_new_item_amount_gross_mgn
           ,credit_rate            = lt_new_item_credit_rate
           ,amount                 = lt_new_item_amount
           ,last_updated_by        = cn_last_updated_by
           ,last_update_date       = cd_last_update_date
           ,last_update_login      = cn_last_update_login
           ,request_id             = cn_request_id
           ,program_application_id = cn_program_application_id
           ,program_id             = cn_program_id
           ,program_update_date    = cd_program_update_date
        WHERE rowid = l_rowid
        ;
      END IF;
      --
      ln_cnt := ln_cnt + 1;
      --
    END LOOP;
    --
  EXCEPTION
    -- *** ���b�N��O�n���h�� ****
    WHEN global_lock_expt THEN
      lv_tab_name := xxccp_common_pkg.get_msg(
                               iv_application => cv_appl_short_name_csm
                              ,iv_name        => cv_msg_xxcsm10238
                             );
      -- ���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10234
                      ,iv_token_name1  => cv_tkn_table
                      ,iv_token_value1 => lv_tab_name
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      --
  END exchange_item_bgt;
--
  /**********************************************************************************
   * Procedure Name   : calc_budget_item
   * Description      : �\�Z�l�Z�o
   ***********************************************************************************/
  PROCEDURE calc_budget_item(
     ov_errbuf               OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_item_group_no        IN  VARCHAR2
    ,iv_item_no              IN  VARCHAR2
    ,in_month_no             IN  NUMBER
    ,in_sales_budget         IN  NUMBER      -- ����_����(�P�ʁF��~)�i�K�{�j
    ,in_amount_gross_margin  IN  NUMBER      -- ����_�e���z(�P�ʁF��~)
    ,in_margin_rate          IN  NUMBER      -- ����_�e����
    ,in_credit_rate          IN  NUMBER      -- ����_�|��
    ,iv_bara_kbn             IN  VARCHAR2    -- ����_�o���敪
    ,in_discrete_cost        IN  XXCMM_SYSTEM_ITEMS_B_HST.DISCRETE_COST%TYPE      -- �c�ƌ���
    ,in_fixed_price          IN  XXCMM_SYSTEM_ITEMS_B_HST.FIXED_PRICE%TYPE        -- �艿
    ,on_amount_gross_margin  OUT xxcsm_item_plan_lines.amount_gross_margin%TYPE   -- �Z�o����_�e���z(�P�ʁF�~)
    ,on_margin_rate          OUT xxcsm_item_plan_lines.margin_rate%TYPE           -- �Z�o����_�e����
    ,on_credit_rate          OUT xxcsm_item_plan_lines.credit_rate%TYPE           -- �Z�o����_�|��
    ,on_amount               OUT xxcsm_item_plan_lines.amount%TYPE                -- �Z�o����_����
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'calc_budget_item'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    lv_step        VARCHAR2(200);
    --
    ln_sales_budget             NUMBER;  -- ����(�P�ʁF�~)
    ln_sales_bdgt_per1          NUMBER;  -- 1�{������̔��l
    ln_gross_amount_per1        NUMBER;  -- 1�{������̗��v
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    lv_step := '������';
    --����(�~) = ����(��~) * 1000
    ln_sales_budget := in_sales_budget * 1000;
    ln_sales_bdgt_per1   := 0;
    ln_gross_amount_per1 := 0;
    -------------------------------------------------
    -- 1.�e���z�A�e�����A�|���A���ʂ̎Z�o
    -------------------------------------------------
    IF in_amount_gross_margin IS NOT NULL THEN
      -------------------------------------------------
      -- �e���z���w�肳��Ă���ꍇ
      -------------------------------------------------
      lv_step := '�e���z�w�� �e���z';
      --�e���z = �A�b�v���[�h�l * 1000
      on_amount_gross_margin := in_amount_gross_margin * 1000;
      --�e���� = ( �e���v�z / ���� * 100 ) �̏����_��3�ʂ��l�̌ܓ�
      lv_step := '�e���z�w�� �e����';
      IF ln_sales_budget = 0 THEN
        on_margin_rate := 0;
      ELSE
        BEGIN
          on_margin_rate := ROUND( ( on_amount_gross_margin / ln_sales_budget * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e���z�w�� �e�����Z�o > �e���z(��~)='||TO_CHAR(on_amount_gross_margin / 1000)||' ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --1�{������̔��l
      lv_step := '�e���z�w�� 1�{������̔��l';
      IF (ln_sales_budget - on_amount_gross_margin) = 0 THEN
        ln_sales_bdgt_per1 := 0;
      ELSE
        --1�{������̔��l = ( ���� / (���� - �e���v�z) * �c�ƌ��� )�̏����_��11�ʂ��l�̌ܓ�
        BEGIN
          ln_sales_bdgt_per1 := ROUND( ( ln_sales_budget / (ln_sales_budget - on_amount_gross_margin) * in_discrete_cost ), 10);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e���z�w�� 1�{������̔��l�Z�o > ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' �e���z(��~)='||TO_CHAR(on_amount_gross_margin / 1000)||' �c�ƌ���='||TO_CHAR(in_discrete_cost)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --�|��
      lv_step := '�e���z�w�� �|��';
      IF in_fixed_price = 0 THEN
        on_credit_rate := 0;
      ELSE
        --�|�� = (1�{������̔��l / �艿 * 100)�̏����_��3�ʂ��l�̌ܓ�
        BEGIN
          on_credit_rate := ROUND( (ln_sales_bdgt_per1 / in_fixed_price * 100), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e���z�w�� �|���Z�o > 1�{������̔��l='||TO_CHAR(ln_sales_bdgt_per1)||' �艿='||TO_CHAR(in_fixed_price)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --����
      lv_step := '�e���z�w�� ����';
      IF ln_sales_bdgt_per1 = 0 THEN
        on_amount := 0;
      ELSE
        BEGIN
          IF (iv_bara_kbn = cv_y) THEN
            --���� = ( ���� / ���l )�̏����_��2�ʂ��l�̌ܓ�
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 1);
          ELSE
            --���� = ( ���� / ���l )�̏����_��1�ʂ��l�̌ܓ�
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 0);
          END IF;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e���z�w�� ���ʎZ�o > ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' 1�{������̔��l='||TO_CHAR(ln_sales_bdgt_per1)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
    ELSIF in_margin_rate IS NOT NULL THEN
      -------------------------------------------------
      -- �e�������w�肳��Ă���ꍇ
      -------------------------------------------------
      lv_step := '�e�����w�� �e���z';
      --�e���z = ( ���� * �e���v�� / 100 / 1000 ) �̏����_��1�ʂ��l�̌ܓ����āA�P�ʂ��~�ɕύX(�~1000����)
      BEGIN
        on_amount_gross_margin := ROUND( ( ln_sales_budget * in_margin_rate / 100 / 1000), 0) * 1000;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(in_month_no)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�e�����w�� �e���z�Z�o > ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' �e����='||TO_CHAR(in_margin_rate)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      lv_step := '�e�����w�� �e����';
      --�e���� = �A�b�v���[�h�l
      on_margin_rate := in_margin_rate;
      lv_step := '�e�����w�� 1�{������̔��l';
      --1�{������̔��l
      IF (ln_sales_budget - on_amount_gross_margin) = 0 THEN
        ln_sales_bdgt_per1 := 0;
      ELSE
        --1�{������̔��l = ( ���� / (���� - �e���v�z) * �c�ƌ��� )�̏����_��11�ʂ��l�̌ܓ�
        BEGIN
          ln_sales_bdgt_per1 := ROUND( ( ln_sales_budget / (ln_sales_budget - on_amount_gross_margin) * in_discrete_cost ), 10);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e�����w�� 1�{������̔��l�Z�o > ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' �e���z(��~)='||TO_CHAR(on_amount_gross_margin / 1000)||' �c�ƌ���='||TO_CHAR(in_discrete_cost)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      lv_step := '�e�����w�� �|��';
      --�|��
      IF in_fixed_price = 0 THEN
        on_credit_rate := 0;
      ELSE
        --�|�� = (1�{������̔��l / �艿 * 100)�̏����_��3�ʂ��l�̌ܓ�
        BEGIN
          on_credit_rate := ROUND( (ln_sales_bdgt_per1 / in_fixed_price * 100), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e�����w�� �|���Z�o > 1�{������̔��l='||TO_CHAR(ln_sales_bdgt_per1)||' �艿='||TO_CHAR(in_fixed_price)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      lv_step := '�e�����w�� ����';
      --����
      IF ln_sales_bdgt_per1 = 0 THEN
        on_amount := 0;
      ELSE
        BEGIN
          IF (iv_bara_kbn = cv_y) THEN
            --���� = ( ���� / ���l )�̏����_��2�ʂ��l�̌ܓ�
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 1);
          ELSE
            --���� = ( ���� / ���l )�̏����_��1�ʂ��l�̌ܓ�
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 0);
          END IF;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�e�����w�� ���ʎZ�o > ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' 1�{������̔��l='||TO_CHAR(ln_sales_bdgt_per1)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
    ELSIF in_credit_rate IS NOT NULL THEN
      -------------------------------------------------
      -- �|�����w�肳��Ă���ꍇ
      -------------------------------------------------
      --�e���z
      lv_step := '�|���w�� 1�{������̔��l';
      --1�{������̔��l = �艿 * �|�� / 100
      BEGIN
        ln_sales_bdgt_per1 := in_fixed_price * in_credit_rate / 100;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(in_month_no)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�|���w�� 1�{������̔��l�Z�o > �艿='||TO_CHAR(in_fixed_price)||' �|��='||TO_CHAR(in_credit_rate)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      lv_step := '�|���w�� ����';
      --����
      IF ln_sales_bdgt_per1 = 0 THEN
        on_amount := 0;
      ELSE
        --����
        BEGIN
          IF (iv_bara_kbn = cv_y) THEN
            --���� = ( ���� / ���l )�̏����_��2�ʂ��l�̌ܓ�
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 1);
          ELSE
            --���� = ( ���� / ���l )�̏����_��1�ʂ��l�̌ܓ�
            on_amount := ROUND( ( ln_sales_budget / ln_sales_bdgt_per1), 0);
          END IF;
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�|���w�� ���ʎZ�o > ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' 1�{������̔��l='||TO_CHAR(ln_sales_bdgt_per1)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --
      lv_step := '�|���w�� 1�{������̗��v';
      --1�{������̗��v = 1�{������̔��l - �c�ƌ���
      ln_gross_amount_per1 := NVL(ln_sales_bdgt_per1 - in_discrete_cost, 0);
      --
      lv_step := '�|���w�� �e���z';
      --�e���z = (1�{������̗��v * ����) / 1000�̏����_��1�ʂ��l�̌ܓ����āA�P�ʂ��~�ɕύX(�~1000����)
      BEGIN
        on_amount_gross_margin := ROUND( ( ln_gross_amount_per1 * on_amount / 1000 ), 0) * 1000;
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => TO_CHAR(in_month_no)
                         , iv_token_name4  => cv_tkn_errmsg
                         , iv_token_value4 => '�|���w�� �e���z�Z�o > 1�{������̗��v='||TO_CHAR(ln_gross_amount_per1)||' ����='||TO_CHAR(on_amount)||' �G���[���e='||SQLERRM
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          ov_retcode := cv_status_check;
      END;
      --
      lv_step := '�|���w�� �e����';
      --�e���� = (�e���v�z / ���� * 100)�̏����_��3�ʂ��l�̌ܓ�
      IF ln_sales_budget = 0 THEN
        on_margin_rate := 0;
      ELSE
        BEGIN
          on_margin_rate := ROUND( (on_amount_gross_margin / ln_sales_budget * 100 ), 2);
        EXCEPTION
          WHEN VALUE_ERROR THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10326          -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd
                           , iv_token_value1 => iv_item_group_no
                           , iv_token_name2  => cv_tkn_item_cd
                           , iv_token_value2 => iv_item_no
                           , iv_token_name3  => cv_tkn_month
                           , iv_token_value3 => TO_CHAR(in_month_no)
                           , iv_token_name4  => cv_tkn_errmsg
                           , iv_token_value4 => '�|���w�� �e�����Z�o > �e���z(��~)='||TO_CHAR(on_amount_gross_margin / 1000)||' ����(��~)='||TO_CHAR(ln_sales_budget / 1000)||' �G���[���e='||SQLERRM
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errbuf
            );
            ov_retcode := cv_status_check;
        END;
      END IF;
      --
      lv_step := '�|���w�� �|��';
      --�|�� = �A�b�v���[�h�l
      on_credit_rate := in_credit_rate;
      --
    END IF;
    --
    -------------------------------------------------
    -- 2.���e�͈̓`�F�b�N
    -------------------------------------------------
    lv_step := '���e�͈̓`�F�b�N';
    --0
    IF ln_sales_budget = 0 AND on_amount_gross_margin = 0 AND on_margin_rate = 0
      AND on_credit_rate = 0 AND on_amount = 0
    THEN 
      --�S����0��ok�Ƃ���
      NULL;
    ELSE
      --�e���z
      IF ( ( on_amount_gross_margin / 1000 ) < cn_min_gross ) OR ( cn_max_gross < ( on_amount_gross_margin / 1000 ) ) THEN
        --�e���z�͋��e�͈͂𒴂��Ă��܂��܂��B
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_rec_type_b_name
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_gross)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_gross)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_amount_gross_margin / 1000)
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --�e����
      IF ( on_margin_rate < cn_min_rate ) OR ( cn_max_rate < on_margin_rate ) THEN
        --�e�����͋��e�͈͂𒴂��Ă��܂��܂��B
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_rec_type_c_name
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_rate)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_rate)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_margin_rate,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --�|��
      IF ( on_credit_rate < cn_min_crerate ) OR ( cn_max_crerate < on_credit_rate ) THEN
        --�|���͋��e�͈͂𒴂��Ă��܂��܂��B
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_rec_type_d_name
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_crerate)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_crerate)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_credit_rate,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      --����
      IF ( on_amount < cn_min_amount ) OR ( cn_max_amount < on_amount ) THEN
        --���ʂ͋��e�͈͂𒴂��Ă��܂��܂��B
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10319
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => TO_CHAR(in_month_no)
                       ,iv_token_name4          => cv_tkn_column
                       ,iv_token_value4         => cv_amount
                       ,iv_token_name5          => cv_tkn_min
                       ,iv_token_value5         => TO_CHAR(cn_min_amount)
                       ,iv_token_name6          => cv_tkn_max
                       ,iv_token_value6         => TO_CHAR(cn_max_amount)
                       ,iv_token_name7          => cv_tkn_value
                       ,iv_token_value7         => TO_CHAR(on_amount,'FM999999999990.09')
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END calc_budget_item;
  --
  /**********************************************************************************
   * Procedure Name   : set_item_bgt
   * Description      : �P�i�\�Z�ݒ�(A-5)
   ***********************************************************************************/
  PROCEDURE set_item_bgt(
     ov_errbuf        OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode       OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg        OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'set_item_bgt'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    --
    ln_line_no                      NUMBER;   --�s�J�E���^
    ln_item_line_cnt                NUMBER;   --�P�i�\�Z���׃J�E���^
    lv_pre_item_group_no            xxcsm_item_plan_lines.item_group_no%TYPE;
    lv_step                         VARCHAR2(200);
    --
    ln_sales_budget                 NUMBER(14,2);
    ln_amount_gross_margin          NUMBER(14,2);
    ln_margin_rate                  NUMBER(14,2);
    ln_credit_rate                  NUMBER(14,2);
    lv_out_regist_item              VARCHAR2(1);      -- �o�^�O���i����
    --===============================
    -- ���[�J����O
    --===============================
    sub_proc_err_expt    EXCEPTION; -- �ďo���v���O�����̃G���[
  --
  BEGIN
    --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    lv_step     := NULL;
    --
    ln_line_no := 1;
    g_item_line_tab.DELETE;
    ln_item_line_cnt := 1;
    FOR i IN 1..12 LOOP
      g_item_bgt_sum_tab(i).sales_budget := 0;
      g_item_bgt_sum_tab(i).amount_gross_margin := 0;
    END LOOP;
    gv_group_status := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.�P�i�\�Z�ݒ�
    -------------------------------------------------
    lv_pre_item_group_no := NULL;
    --
    -- ���i�Q�A���i�R�[�h�A���R�[�h�敪���ɏ��������{
    << upload_data_tab_loop >>
    LOOP
      EXIT WHEN ln_line_no > g_upload_data_tab.COUNT;
      -------------------------------------------------
      -- 1-1.�J�����g���i�Q����
      -------------------------------------------------
      IF lv_pre_item_group_no <> g_upload_data_tab(ln_line_no).item_group_no THEN
        --�O�񏈗����i�Q�ƍ��񏈗����i�Q���قȂ�ꍇ�A
        -------------------------------------------------
        -- �P�i�\�Z�􂢑ւ�
        -------------------------------------------------
        exchange_item_bgt(
          ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
        --
        IF ( lv_retcode = cv_status_check ) THEN
          gv_group_status := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE sub_proc_err_expt;
        END IF;
        --
        IF ( gv_group_status = cv_status_check ) THEN
          ov_retcode := cv_status_error;
        END IF;
        -------------------------------------------------
        -- �i�[�揉�����i���i�v�斾�׃e�[�u���o�^�l�A���v���z�A�����j
        -------------------------------------------------
        g_item_line_tab.DELETE;
        FOR i IN 1..12 LOOP
          g_item_bgt_sum_tab(i).sales_budget := 0;
          g_item_bgt_sum_tab(i).amount_gross_margin := 0;
        END LOOP;
        ln_item_line_cnt := 1;
        --
        gv_group_status := cv_status_normal;
        --
      END IF;
      --
      -------------------------------------------------
      -- �o�^�O���i����
      -------------------------------------------------
      lv_out_regist_item := cv_n;
      --
      FOR i IN 1..g_out_regist_item_tab.COUNT LOOP
        IF g_upload_data_tab(ln_line_no).item_no = g_out_regist_item_tab(i) THEN
           lv_out_regist_item := cv_y;
        END IF;
      END LOOP;
      --
      -------------------------------------------------
      -- 1-2.���i�v�斾�׃e�[�u�����ڐݒ�
      -------------------------------------------------
      FOR i IN 1..12 LOOP
        g_item_line_tab(ln_item_line_cnt).item_plan_header_id := gt_item_plan_header_id;
        g_item_line_tab(ln_item_line_cnt).item_plan_lines_id  := xxcsm_item_plan_lines_s01.NEXTVAL;
        g_item_line_tab(ln_item_line_cnt).year_month          := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'YYYYMM'));
        g_item_line_tab(ln_item_line_cnt).month_no            := TO_NUMBER(TO_CHAR(ADD_MONTHS(gd_start_date, i - 1),'MM'));
        g_item_line_tab(ln_item_line_cnt).year_bdgt_kbn       := cv_budget_kbn_month;
        g_item_line_tab(ln_item_line_cnt).item_kbn            := cv_item_kbn_tanpin;
        g_item_line_tab(ln_item_line_cnt).item_no             := g_upload_data_tab(ln_line_no).item_no;
        g_item_line_tab(ln_item_line_cnt).item_group_no       := g_upload_data_tab(ln_line_no).item_group_no;
        --
        g_item_line_tab(ln_item_line_cnt).created_by              := cn_created_by;
        g_item_line_tab(ln_item_line_cnt).creation_date           := cd_creation_date;
        g_item_line_tab(ln_item_line_cnt).last_updated_by         := cn_last_updated_by;
        g_item_line_tab(ln_item_line_cnt).last_update_date        := cd_last_update_date;
        g_item_line_tab(ln_item_line_cnt).last_update_login       := cn_last_update_login;
        g_item_line_tab(ln_item_line_cnt).request_id              := cn_request_id;
        g_item_line_tab(ln_item_line_cnt).program_application_id  := cn_program_application_id;
        g_item_line_tab(ln_item_line_cnt).program_id              := cn_program_id;
        g_item_line_tab(ln_item_line_cnt).program_update_date     := cd_program_update_date;
        --
        lv_step := g_item_line_tab(ln_item_line_cnt).item_group_no || ' / ' || g_item_line_tab(ln_item_line_cnt).item_no  || ' / ' || TO_CHAR(g_item_line_tab(ln_item_line_cnt).year_month);
        --
        IF i = 1 THEN --5����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_05 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_05;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_05;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_05;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_05;            -- ����_�|��
        ELSIF i = 2 THEN --6����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_06 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_06;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_06;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_06;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_06;            -- ����_�|��
        ELSIF i = 3 THEN --7����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_07 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_07;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_07;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_07;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_07;            -- ����_�|��
        ELSIF i = 4 THEN --8����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_08 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_08;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_08;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_08;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_08;            -- ����_�|��
        ELSIF i = 5 THEN --9����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_09 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_09;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_09;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_09;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_09;            -- ����_�|��
        ELSIF i = 6 THEN --10����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_10 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_10;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_10;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_10;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_10;            -- ����_�|��
        ELSIF i = 7 THEN --11����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_11 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_11;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_11;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_11;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_11;            -- ����_�|��
        ELSIF i = 8 THEN --12����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_12 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_12;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_12;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_12;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_12;            -- ����_�|��
        ELSIF i = 9 THEN --1����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_01 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_01;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_01;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_01;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_01;            -- ����_�|��
        ELSIF i = 10 THEN --2����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_02 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_02;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_02;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_02;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_02;            -- ����_�|��
        ELSIF i = 11 THEN --3����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_03 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_03;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_03;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_03;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_03;            -- ����_�|��
        ELSIF i = 12 THEN --4����
          g_item_line_tab(ln_item_line_cnt).sales_budget := g_upload_data_tab(ln_line_no).month_04 * 1000;  --����
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_04;                -- ����_����(�P�ʁF��~)�i�K�{�j
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_04;            -- ����_�e���z(�P�ʁF��~)
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_04;            -- ����_�e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_04;            -- ����_�|��
        END IF;
        --
        IF lv_out_regist_item = cv_n THEN
          --�ʏ폤�i�̏ꍇ
          -------------------------------------------------
          -- �\�Z���ڐݒ�
          -------------------------------------------------
          calc_budget_item(
            ov_errbuf              => lv_errbuf                                             -- �G���[�E���b�Z�[�W
           ,ov_retcode             => lv_retcode                                            -- ���^�[���E�R�[�h
           ,ov_errmsg              => lv_errmsg                                             -- ���[�U�[�E�G���[�E���b�Z�[�W
           ,iv_item_group_no       => g_item_line_tab(ln_item_line_cnt).item_group_no
           ,iv_item_no             => g_item_line_tab(ln_item_line_cnt).item_no
           ,in_month_no            => g_item_line_tab(ln_item_line_cnt).month_no
           ,in_sales_budget        => ln_sales_budget                                       -- ����_����(�P�ʁF��~)�i�K�{�j
           ,in_amount_gross_margin => ln_amount_gross_margin                                -- ����_�e���z(�P�ʁF��~)
           ,in_margin_rate         => ln_margin_rate                                        -- ����_�e����
           ,in_credit_rate         => ln_credit_rate                                        -- ����_�|��
           ,iv_bara_kbn            => g_upload_data_tab(ln_line_no).bara_kbn                -- ����_�o���敪
           ,in_discrete_cost       => g_upload_data_tab(ln_line_no).discrete_cost           -- ����_�c�ƌ���
           ,in_fixed_price         => g_upload_data_tab(ln_line_no).fixed_price             -- ����_�艿
           ,on_amount_gross_margin => g_item_line_tab(ln_item_line_cnt).amount_gross_margin -- �Z�o����_�e���z(�P�ʁF�~)
           ,on_margin_rate         => g_item_line_tab(ln_item_line_cnt).margin_rate         -- �Z�o����_�e����
           ,on_credit_rate         => g_item_line_tab(ln_item_line_cnt).credit_rate         -- �Z�o����_�|��
           ,on_amount              => g_item_line_tab(ln_item_line_cnt).amount              -- �Z�o����_����
          );
          --
          IF ( lv_retcode = cv_status_check ) THEN
            gv_group_status := cv_status_check;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE sub_proc_err_expt;
          END IF;
          --
        ELSE
          --�o�^�O���i�̏ꍇ
          g_item_line_tab(ln_item_line_cnt).amount_gross_margin := ln_amount_gross_margin * 1000;  -- �e���z(�P�ʁF�~)
          g_item_line_tab(ln_item_line_cnt).margin_rate         := 0;  -- �e����
          g_item_line_tab(ln_item_line_cnt).credit_rate         := 0;  -- �|��
          g_item_line_tab(ln_item_line_cnt).amount              := 0;  -- ����
        END IF;
        -------------------------------------------------
        -- �P�i�\�Z���v�X�V(�Ώۏ��i�Q��)
        -------------------------------------------------
        --����
        g_item_bgt_sum_tab(i).sales_budget        := g_item_bgt_sum_tab(i).sales_budget + ln_sales_budget * 1000;
        --�e���z
        g_item_bgt_sum_tab(i).amount_gross_margin := g_item_bgt_sum_tab(i).amount_gross_margin + g_item_line_tab(ln_item_line_cnt).amount_gross_margin;
        --
        ln_item_line_cnt := ln_item_line_cnt + 1;
        --
      END LOOP ;  --�P�i�\�Z���R�[�h�ݒ胋�[�v
      --
      lv_pre_item_group_no := g_upload_data_tab(ln_line_no).item_group_no;
      ln_line_no := ln_line_no + 4;
      --
    END LOOP  upload_data_tab_loop;
    --
    -------------------------------------------------
    -- 2.�P�i�\�Z�􂢑ւ��i�Ō�̏��i�Q���j
    -------------------------------------------------
    exchange_item_bgt(
      ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W
     ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h
     ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_check ) THEN
      gv_group_status := cv_status_check;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    IF gv_group_status = cv_status_check THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- �T�u�v���O������O�n���h��
    ----------------------------------------------------------
    WHEN sub_proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
  END set_item_bgt;
  --
  /**********************************************************************************
   * Procedure Name   : chk_budget_item
   * Description      : �A�b�v���[�h�\�Z�l�`�F�b�N
   ***********************************************************************************/
  PROCEDURE chk_budget_item(
     ov_errbuf               OUT VARCHAR2    -- �G���[�E���b�Z�[�W
    ,ov_retcode              OUT VARCHAR2    -- ���^�[���E�R�[�h
    ,ov_errmsg               OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_item_group_no        IN  VARCHAR2    -- ���i�Q
    ,iv_item_no              IN  VARCHAR2    -- ���i�R�[�h
    ,iv_month                IN  VARCHAR2    -- ��
    ,in_sales_budget         IN  NUMBER      -- ����
    ,in_amount_gross_margin  IN  NUMBER      -- �e���z
    ,in_margin_rate          IN  NUMBER      -- �e����
    ,in_credit_rate          IN  NUMBER      -- �|��
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_budget_item'; -- �v���O������
    --
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);      -- ���b�Z�[�W
    lb_retcode       BOOLEAN;             -- API���^�[���E���b�Z�[�W�p
    --
    ln_cnt              NUMBER;           -- �J�E���^
    lv_out_regist_item  VARCHAR2(1);      -- �o�^�O���i����
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    -------------------------------------------------
    -- 1.����`�F�b�N
    -------------------------------------------------
    -------------------------------------------------
    -- NULL�s�`�F�b�N
    -------------------------------------------------
    IF in_sales_budget IS NULL THEN
      --������z���w�肵�Ă�������
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcsm10328          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_deal_cd
                     , iv_token_value1 => iv_item_group_no
                     , iv_token_name2  => cv_tkn_item_cd
                     , iv_token_value2 => iv_item_no
                     , iv_token_name3  => cv_tkn_month
                     , iv_token_value3 => iv_month
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
      --
    ELSE
      -------------------------------------------------
      -- �}�C�i�X�s�`�F�b�N
      -------------------------------------------------
      IF in_sales_budget < 0 THEN  --���̒i�K��NULL�͖���
        --�����0�ȏ��ݒ肵�Ă�������
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10317          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd
                       , iv_token_value1 => iv_item_group_no
                       , iv_token_name2  => cv_tkn_item_cd
                       , iv_token_value2 => iv_item_no
                       , iv_token_name3  => cv_tkn_month
                       , iv_token_value3 => iv_month
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
      -------------------------------------------------
      -- ���㏬���_�ȉ��`�F�b�N
      -------------------------------------------------
      IF MOD(in_sales_budget, 1) > 0 THEN
        --����A�e���z�͏����_�ȉ����w��ł��܂���
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm   -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcsm10324        -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_deal_cd
                     , iv_token_value1 => iv_item_group_no
                     , iv_token_name2  => cv_tkn_item_cd
                     , iv_token_value2 => iv_item_no
                     , iv_token_name3  => cv_tkn_month
                     , iv_token_value3 => iv_month
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    -------------------------------------------------
    -- �o�^�O���i����
    -------------------------------------------------
    lv_out_regist_item := cv_n;
    --
    FOR i IN 1..g_out_regist_item_tab.COUNT LOOP
      IF iv_item_no = g_out_regist_item_tab(i) THEN
         lv_out_regist_item := cv_y;
      END IF;
    END LOOP;
    --
    -------------------------------------------------
    -- 2.�e���z�A�e�����A�|���`�F�b�N
    -------------------------------------------------
    IF lv_out_regist_item = cv_n THEN
      --�ʏ폤�i�̏ꍇ
      --�e���z�A�e�����A�|��
      SELECT NVL2(in_amount_gross_margin, 1, 0) + NVL2(in_margin_rate, 1, 0) + NVL2(in_credit_rate, 1, 0)
      INTO  ln_cnt
      FROM  dual
      ;
      IF ln_cnt = 1 THEN
        IF in_amount_gross_margin IS NOT NULL THEN
          --
          -------------------------------------------------
          -- �e���z�����_�ȉ��`�F�b�N
          -------------------------------------------------
          IF MOD(in_amount_gross_margin, 1) > 0 THEN
            --�e���z�͏����_�ȉ����w��ł��܂���
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm  -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10324       -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd
                         , iv_token_value1 => iv_item_group_no
                         , iv_token_name2  => cv_tkn_item_cd
                         , iv_token_value2 => iv_item_no
                         , iv_token_name3  => cv_tkn_month
                         , iv_token_value3 => iv_month
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
          END IF;
          --
        END IF;
        --
      ELSE
        -------------------------------------------------
        -- 1���ڎw��`�F�b�N
        -------------------------------------------------
        --�e���z�A�e�����A�|���͂����ꂩ1���ڂ�ݒ肵�Ă�������
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10318
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => iv_month
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
      END IF;
    ELSE
      --�o�^�O���i�̏ꍇ
      IF in_amount_gross_margin IS NOT NULL
        AND in_margin_rate IS NULL
        AND in_credit_rate IS NULL
      THEN
        -------------------------------------------------
        -- �e���z�����_�ȉ��`�F�b�N
        -------------------------------------------------
        IF MOD(in_amount_gross_margin, 1) > 0 THEN
          --�e���z�͏����_�ȉ����w��ł��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10324       -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd
                       , iv_token_value1 => iv_item_group_no
                       , iv_token_name2  => cv_tkn_item_cd
                       , iv_token_value2 => iv_item_no
                       , iv_token_name3  => cv_tkn_month
                       , iv_token_value3 => iv_month
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
      ELSE
        --�o�^�O���i�͑e���z�݂̂�ݒ肵�Ă�������
        lv_out_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_csm
                       ,iv_name                 => cv_msg_xxcsm10327
                       ,iv_token_name1          => cv_tkn_deal_cd
                       ,iv_token_value1         => iv_item_group_no
                       ,iv_token_name2          => cv_tkn_item_cd
                       ,iv_token_value2         => iv_item_no
                       ,iv_token_name3          => cv_tkn_month
                       ,iv_token_value3         => iv_month
                      );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_out_msg
        );
        ov_retcode := cv_status_check;
        --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_budget_item;
  --
  /***********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : �Ó����`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
    ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
   ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
   ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- �v���O������
    --
    cv_security_mgr           CONSTANT VARCHAR2(1)  := '2';    -- 2:�c�ƊǗ������
    cv_security_etc           CONSTANT VARCHAR2(1)  := '3';    -- 3:�u�c�Ɗ��v�u�c�ƊǗ��v�ȊO
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);    -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000); -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000); -- ���b�Z�[�W
    lb_retcode     BOOLEAN;        -- ���b�Z�[�W�߂�l
    lv_chk_status  VARCHAR2(1);
    --
    lv_no_flv_tag               VARCHAR2(100);      -- �Z�L�����e�B����ߒl
    ln_cnt                      NUMBER;
    --
    lt_checked_location_cd      xxcsm_item_plan_headers.location_cd%TYPE;
    lt_checked_plan_year        xxcsm_item_plan_headers.plan_year%TYPE;
    lt_checked_item_group_no    xxcsm_item_plan_lines.item_group_no%TYPE;
    lt_checked_item_no          xxcsm_item_plan_lines.item_no%TYPE;
    lv_step                     VARCHAR2(200);
    --
    ln_month_count              NUMBER;           -- ������
    lv_month                    VARCHAR(100);     -- �������݌���
    lv_item_group_no            VARCHAR2(1000);   -- ���i�Q
    ln_item_cnt                 NUMBER;
    ln_line_no                  NUMBER;
    lt_group3_cd                xxcsm_commodity_group3_v.group3_cd%TYPE;
    lv_dmy                      VARCHAR(10);
    lt_unit_of_issue            xxcsm_commodity_group3_v.unit_of_issue%TYPE;
    --
    ln_sales_budget             NUMBER(14,2);
    ln_amount_gross_margin      NUMBER(14,2);
    ln_margin_rate              NUMBER(14,2);
    ln_credit_rate              NUMBER(14,2);
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    --���ʔ���̍����`�F�b�N
    CURSOR kyoten_check_cur
    IS
      SELECT  xiplb.month_no              month_no                             --��
      FROM    xxcsm_item_plan_loc_bdgt xiplb                                   --���i�v�拒�_�ʗ\�Z�e�[�u��
              ,(SELECT xipl.item_plan_header_id item_plan_header_id            --���i�v��w�b�_ID
                      ,xipl.month_no month_no                                  --��
                      ,SUM(xipl.sales_budget) sales_budget                     --������z
                FROM   xxcsm_item_plan_lines xipl                              --���i�v�斾�׃e�[�u��
                WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
                AND    xipl.year_bdgt_kbn = cv_budget_kbn_month                --�N�ԌQ�\�Z�敪(0�F�e��)
                AND    xipl.item_kbn = cv_item_kbn_group                       --���i�敪
                GROUP BY xipl.item_plan_header_id
                        ,xipl.month_no
               ) xipl_view                                                     --���i�v�斾�׌��ʗ\�Z�C�����C���r���[
      WHERE   xipl_view.item_plan_header_id = xiplb.item_plan_header_id
      AND     xipl_view.month_no = xiplb.month_no
      AND     (xiplb.sales_budget + (xiplb.receipt_discount * -1) 
                 + (xiplb.sales_discount * -1)) <> xipl_view.sales_budget
      ORDER BY xiplb.month_no
      ;
    --�Q�ʔ���̍����`�F�b�N
    CURSOR deal_check_cur
    IS
      SELECT xipl.item_group_no        item_group_no,     --���i�Q�R�[�h
             SUM(DECODE(xipl.year_bdgt_kbn, cv_budget_kbn_year, xipl.sales_budget, 0)) 
             - SUM(DECODE(xipl.year_bdgt_kbn, cv_budget_kbn_month, xipl.sales_budget, 0)) 
             sales_budget   -- SUM(�N�ԌQ�\�Z�敪'1'�̏ꍇ�̔�����z) - SUM(�N�ԌQ�\�Z�敪'0'�̏ꍇ�̔�����z)
      FROM   xxcsm_item_plan_lines   xipl                 --���i�v�斾�׃e�[�u��
      WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
      AND    xipl.item_kbn = cv_item_kbn_group            --���i�敪(0�F���i�Q)
      GROUP BY xipl.item_group_no
      ORDER BY xipl.item_group_no
      ;
    --
    --===============================
    -- ���[�J����O
    --===============================
    --
  BEGIN
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.���_�R�[�h�A�N�x�`�F�b�N
    -------------------------------------------------
    lv_step := '���_�A�N�x�`�F�b�N';
    lt_checked_location_cd := NULL;
    lt_checked_plan_year   := NULL;
    lv_chk_status := cv_status_normal;
    << chk_upload_data_tab_loop >>
    FOR ln_line_no IN 1..g_upload_data_tab.COUNT LOOP
      IF ln_line_no = 1 THEN
        -------------------------------------------------
        -- 1-1. 1�s�ڂ̋��_�R�[�h�`�F�b�N
        -------------------------------------------------
        -------------------------------------------------
        -- �c�ƊǗ����E�c�ƊǗ��ہE�c�Ɗ�敔����
        -------------------------------------------------
        xxcsm_common_pkg.year_item_plan_security(
           in_user_id          => gn_user_id                    --���[�UID
          ,ov_lv6_kyoten_list  => lv_no_flv_tag                 --�Z�L�����e�B�߂�l
          ,ov_retcode          => lv_retcode                    --���^�[���R�[�h
          ,ov_errbuf           => lv_errbuf                     --�G���[���b�Z�[�W
          ,ov_errmsg           => lv_errmsg                     --���[�U�[�E�G���[���b�Z�[�W
        );
        -------------------------------------------------
        -- ���i�v��Ώۋ��_���݃`�F�b�N
        -------------------------------------------------
        IF ( lv_no_flv_tag = cv_security_mgr   -- 2�F�c�ƊǗ������
          OR lv_no_flv_tag = cv_security_etc   -- 3�F���̑�
          OR lv_retcode = cv_status_warn )
        THEN
          IF ( gv_dummy_dept_ref = cv_y ) THEN
            -- ���[�U�[���u�c�Ɗ�敔�v�u���Ǘ����v�ɏ������Ă��Ȃ��Ɣ��肵���ꍇ
            -- �܂��́A���^�[���R�[�h���x���i�����_���o�^�j�̏ꍇ
            -- �p�����[�^.�_�~�[����K�w�Q�Ƃ�'Y'�̏ꍇ
            SELECT SUM(cnt)
            INTO   ln_cnt
            FROM (SELECT COUNT(*) AS cnt
                  FROM   fnd_lookup_values   flv
                  WHERE  flv.language        = ct_lang
                  AND    flv.lookup_type     = cv_lookup_type_dmy_dept
                  AND    flv.enabled_flag    = cv_y
                  AND    flv.attribute2      = gv_user_foothold  --���O�C�����[�U�ݐȋ��_
                  AND    flv.description     = g_upload_data_tab(ln_line_no).location_cd
                  UNION ALL
                  SELECT COUNT(*) AS cnt
                  FROM   apps.hz_cust_accounts    hca
                        ,apps.hz_parties          hps
                        ,apps.xxcmm_cust_accounts xca
                  WHERE  hca.party_id              = hps.party_id
                  AND    hca.cust_account_id       = xca.customer_id
                  AND   (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
                  AND   (xca.management_base_code  = gv_user_foothold
                  OR     hca.account_number        = gv_user_foothold)
                  AND    hca.account_number  = g_upload_data_tab(ln_line_no).location_cd
                 )
            ;
            --
          ELSE
            -- �p�����[�^.�_�~�[����K�w�Q�Ƃ�'Y'�ȊO�̏ꍇ
            SELECT SUM(cnt)
            INTO   ln_cnt
            FROM (SELECT COUNT(*) AS cnt
                  FROM   hz_cust_accounts   hca
                        ,hz_parties         hps
                  WHERE  hca.party_id       = hps.party_id
                  AND    hca.customer_class_code = '1'
                  AND   (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
                  AND    hca.account_number = gv_user_foothold
                  AND    hca.account_number = g_upload_data_tab(ln_line_no).location_cd
                  UNION ALL
                  SELECT COUNT(*) AS cnt
                  FROM   hz_cust_accounts    hca
                        ,hz_parties          hps
                        ,xxcmm_cust_accounts xca
                  WHERE hca.party_id              = hps.party_id
                  AND    hca.cust_account_id      = xca.customer_id
                  AND   (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
                  AND    xca.management_base_code = gv_user_foothold
                  AND    hca.account_number = g_upload_data_tab(ln_line_no).location_cd
                 )
            ;
            --
          END IF;
          --
        ELSE
          -- �c�Ɗ�敔�̏ꍇ
          SELECT COUNT(*)
          INTO   ln_cnt
          FROM   hz_cust_accounts    hca
                ,hz_parties          hps
          WHERE hca.party_id            = hps.party_id
          AND   hca.customer_class_code = '1'
          AND  (hps.duns_number_c <> '90' OR hps.duns_number_c IS NULL)
          AND   hca.account_number = g_upload_data_tab(ln_line_no).location_cd
          ;
        END IF;
        --
        IF ln_cnt = 0 THEN
          -- �w�苒�_�G���[���b�Z�[�W�o�͂��A�ُ�I��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm                      -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10306                           -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_kyoten_cd                            -- �g�[�N���R�[�h1
                         , iv_token_value1 => g_upload_data_tab(ln_line_no).location_cd   -- �g�[�N���l1�i���_�R�[�h�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        lt_checked_location_cd := g_upload_data_tab(ln_line_no).location_cd;
        --
        -------------------------------------------------
        -- 1-2. 1�s�ڂ̗\�Z�N�x�`�F�b�N
        -------------------------------------------------
        IF g_upload_data_tab(ln_line_no).plan_year <> gt_plan_year THEN
          -- �N�x�G���[���b�Z�[�W�o�͂��A�ُ�I��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10308      -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_yosan_nendo     -- �g�[�N���R�[�h1
                         , iv_token_value1 => TO_CHAR(gt_plan_year)  -- �g�[�N���l1�i�\�Z�N�x�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_check;
        END IF;
        --
        lt_checked_plan_year := g_upload_data_tab(ln_line_no).plan_year;
        --
      ELSE
        IF lv_chk_status = cv_status_normal THEN
          --����̏ꍇ�̂݃`�F�b�N�𑱂���i��ʃ��b�Z�[�W�o�͗}�~�j
          -------------------------------------------------
          -- 1-3. 2�s�ڈȍ~�̋��_�R�[�h�`�F�b�N
          -------------------------------------------------
          IF g_upload_data_tab(ln_line_no).location_cd <> lt_checked_location_cd THEN
            --�������_�w��s�G���[���b�Z�[�W���o�͂��������~
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10307      -- ���b�Z�[�W�R�[�h
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --
          -------------------------------------------------
          -- 1-4. 2�s�ڈȍ~�̗\�Z�N�x�`�F�b�N
          -------------------------------------------------
          IF g_upload_data_tab(ln_line_no).plan_year <> lt_checked_plan_year THEN
            --�����\�Z�N�x�w��s�G���[���b�Z�[�W���o�͂��������~
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10309      -- ���b�Z�[�W�R�[�h
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
            lv_chk_status := cv_status_check;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    END LOOP  chk_upload_data_tab_loop;
    --2�s�ڈȍ~�ْl�w��̏ꍇ
    IF lv_chk_status = cv_status_check THEN
      ov_retcode := cv_status_check;
    END IF;
    --�`�F�b�N�G���[�L��̏ꍇ
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --���_�ƔN�x���m��
    -------------------------------------------------
    -- 2.���_�\�Z�A���i�Q�\�Z�o�^�`�F�b�N
    -------------------------------------------------
    lv_step := '���_�\�Z�A���i�Q�\�Z�o�^�`�F�b�N';
    BEGIN
      SELECT xiph.item_plan_header_id
      INTO   gt_item_plan_header_id
      FROM   xxcsm_item_plan_headers xiph
      WHERE  xiph.plan_year = g_upload_data_tab(1).plan_year
      AND    xiph.location_cd = g_upload_data_tab(1).location_cd
      AND    EXISTS (SELECT 'x'
                     FROM xxcsm_item_plan_lines xipl
                     WHERE xiph.item_plan_header_id = xipl.item_plan_header_id
                    )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --�N�Ԍv�斢�o�^�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10325                 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_kyoten_cd                  -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_data_tab(1).location_cd  -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_yosan_nendo                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_data_tab(1).plan_year    -- �g�[�N���l2
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_error;
        RETURN;
    END;
    -------------------------------------------------
    -- 3.���i�v�攄��`�F�b�N
    -------------------------------------------------
    -------------------------------------------------
    -- 3-1.���ʔ���̍����`�F�b�N
    -------------------------------------------------
    lv_step := '�����`�F�b�N';
    ln_month_count := 0;
    -- ���ʔ���̍���������f�[�^�̌����擾
    FOR kyoten_check_rec IN kyoten_check_cur LOOP
      -- ����
      ln_month_count := ln_month_count + 1;
      -- ���������錎�g�[�N���쐬/�ǋL 
      IF lv_month IS NOT NULL THEN
        lv_month := lv_month || ',' || kyoten_check_rec.month_no;
      ELSE
        lv_month := kyoten_check_rec.month_no;
      END IF;
    END LOOP;
    --
    -- �������݂���ꍇ�A�G���[�Ƃ���
    IF ln_month_count <> 0 THEN
      -- ���ʔ���̍����`�F�b�N�G���[���b�Z�[�W�o�͂��A�ُ�I��
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcsm00050      -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_yyyy            -- �g�[�N���R�[�h1
                     , iv_token_value1 => TO_CHAR(gt_plan_year)  -- �g�[�N���l1�i�N�j
                     , iv_token_name2  => cv_tkn_month           -- �g�[�N���R�[�h1
                     , iv_token_value2 => lv_month               -- �g�[�N���l1�i���j
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
    -------------------------------------------------
    -- 3-2.�Q�ʔ���̍����`�F�b�N
    -------------------------------------------------
    --�Q�ʔ���̍����`�F�b�N
    FOR deal_check_rec IN deal_check_cur LOOP
      -- �N�ԌQ�v�ƔN�ԌQ�\�Z�ɍ���������ꍇ
      IF deal_check_rec.sales_budget <> 0 THEN
        -- ���������鏤�i�Q�R�[�h�g�[�N���쐬/�ǋL 
        IF lv_item_group_no IS NOT NULL THEN
          lv_item_group_no := lv_item_group_no || ',' || deal_check_rec.item_group_no;
        ELSE
          lv_item_group_no := deal_check_rec.item_group_no;
        END IF;
      END IF;
    END LOOP;
    -- �N�ԌQ�v�ƔN�ԌQ�\�Z�ɍ���������ꍇ�A�G���[�Ƃ���
    IF lv_item_group_no IS NOT NULL THEN
      -- ����Q�\�Z�����G���[���b�Z�[�W�o�͂��A�ُ�I��
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcsm00051       -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_deal_cd          -- �g�[�N���R�[�h1
                     , iv_token_value1 => lv_item_group_no        -- �g�[�N���l1�i���i�Q�j
                   );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_check;
    END IF;
    --
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    -------------------------------------------------
    -- 4.���R�[�h�敪�`�F�b�N
    -------------------------------------------------
    lv_step := '���R�[�h�敪�`�F�b�N';
    --������
    lt_checked_item_group_no := cv_blank;
    lt_checked_item_no := cv_blank;
    --
    ln_item_cnt := 0;
    -- ���i�Q�A���i�R�[�h�A���R�[�h�敪���ɏ��������{
    << chk_rec_type_loop >>
    -- ���i���Ƃ̃��R�[�h�敪�������J�E���g
    FOR ln_line_no IN 1..g_upload_data_tab.COUNT LOOP
      -- �`�F�b�N�Ϗ��i�ƈقȂ�΁A���i�ʃ��R�[�h�敪�������[�N������
      IF lt_checked_item_group_no <> g_upload_data_tab(ln_line_no).item_group_no
        OR lt_checked_item_no <> g_upload_data_tab(ln_line_no).item_no
      THEN
        ln_item_cnt := ln_item_cnt + 1;
        g_upload_item_tab(ln_item_cnt).item_group_no := g_upload_data_tab(ln_line_no).item_group_no;
        g_upload_item_tab(ln_item_cnt).item_no       := g_upload_data_tab(ln_line_no).item_no;
        g_upload_item_tab(ln_item_cnt).rec_type_a    := 0;
        g_upload_item_tab(ln_item_cnt).rec_type_b    := 0;
        g_upload_item_tab(ln_item_cnt).rec_type_c    := 0;
        g_upload_item_tab(ln_item_cnt).rec_type_d    := 0;
        g_upload_item_tab(ln_item_cnt).else_type     := 0;
      END IF;
      --
      --�A�b�v���[�h�s���R�[�h�敪���肨��у��R�[�h�敪���C���N�������g
      IF g_upload_data_tab(ln_line_no).rec_type = cv_a THEN
        g_upload_item_tab(ln_item_cnt).rec_type_a := g_upload_item_tab(ln_item_cnt).rec_type_a + 1;
      ELSIF g_upload_data_tab(ln_line_no).rec_type = cv_b THEN
        g_upload_item_tab(ln_item_cnt).rec_type_b := g_upload_item_tab(ln_item_cnt).rec_type_b + 1;
      ELSIF g_upload_data_tab(ln_line_no).rec_type = cv_c THEN
        g_upload_item_tab(ln_item_cnt).rec_type_c := g_upload_item_tab(ln_item_cnt).rec_type_c + 1;
      ELSIF g_upload_data_tab(ln_line_no).rec_type = cv_d THEN
        g_upload_item_tab(ln_item_cnt).rec_type_d := g_upload_item_tab(ln_item_cnt).rec_type_d + 1;
      ELSE
        g_upload_item_tab(ln_item_cnt).else_type := g_upload_item_tab(ln_item_cnt).else_type + 1;
      END IF;
      --
      lt_checked_item_group_no := g_upload_data_tab(ln_line_no).item_group_no;
      lt_checked_item_no       := g_upload_data_tab(ln_line_no).item_no;
      --
    END LOOP  chk_rec_type_loop;
    --
    --�Ώۃ��R�[�h�敪�̌����G���[�����O�o��
    << chk_rec_type_outlog_loop >>
    FOR ln_item_cnt IN 1..g_upload_item_tab.COUNT LOOP
      -- ���ヌ�R�[�h
      IF g_upload_item_tab(ln_item_cnt).rec_type_a = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10310                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_a_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_a > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10311                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_a_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- �e���z���R�[�h
      IF g_upload_item_tab(ln_item_cnt).rec_type_b = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10310                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_b_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_b > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10311                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_b_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- �e�������R�[�h
      IF g_upload_item_tab(ln_item_cnt).rec_type_c = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10310                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_c_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_c > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10311                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_c_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- �|�����R�[�h
      IF g_upload_item_tab(ln_item_cnt).rec_type_d = 0 THEN
        --�����݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10310                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_d_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      IF g_upload_item_tab(ln_item_cnt).rec_type_d > 1 THEN
        --�������݃G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10311                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       , iv_token_name3  => cv_tkn_rec_type                               -- �g�[�N���R�[�h3
                       , iv_token_value3 => cv_rec_type_d_name                            -- �g�[�N���l3�i���R�[�h�敪�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      -- ����A�e���z�A�e�����A�|���ȊO�̃��R�[�h���݃G���[
      IF g_upload_item_tab(ln_item_cnt).else_type > 0 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm                        -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10312                             -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_deal_cd                                -- �g�[�N���R�[�h1
                       , iv_token_value1 => g_upload_item_tab(ln_item_cnt).item_group_no  -- �g�[�N���l1�i���i�Q�j
                       , iv_token_name2  => cv_tkn_item_cd                                -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_upload_item_tab(ln_item_cnt).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode := cv_status_check;
      END IF;
      --
    END LOOP  chk_rec_type_outlog_loop;
    --
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --���R�[�h�敪4�s���m��
    -------------------------------------------------
    -- 5.�A�b�v���[�h���i�`�F�b�N
    -------------------------------------------------
    -- ���i�Q�A���i�R�[�h�A���R�[�h�敪���ɏ���
    ln_line_no := 1;
    << chk_item_loop >>
    LOOP
      EXIT WHEN ln_line_no > g_upload_data_tab.COUNT;
      lv_step := '���i�`�F�b�N:'||g_upload_data_tab(ln_line_no).item_no;
      --
      lv_chk_status := cv_status_normal;  --�g�����Ȃ����̈ȍ~�̃`�F�b�N�X�L�b�v�p
      -------------------------------------------------
      -- 1.�g�������݃`�F�b�N
      -------------------------------------------------
      BEGIN
        SELECT xcg3v.unit_of_issue
        INTO   lt_unit_of_issue
        FROM   xxcsm_commodity_group3_v  xcg3v
        WHERE  xcg3v.group3_cd = g_upload_data_tab(ln_line_no).item_group_no
        AND    xcg3v.item_cd = g_upload_data_tab(ln_line_no).item_no
        AND    NOT EXISTS(SELECT 'X'
                          FROM   xxcsm_item_category_v xicv
                          WHERE  xicv.attribute3 = xcg3v.item_cd
                         )
       ;
       --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --���i�Q�Ə��i�R�[�h�̑g���������݂��܂���
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm                       -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10313                            -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_deal_cd                               -- �g�[�N���R�[�h1
                         , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no  -- �g�[�N���l1�i���i�Q�j
                         , iv_token_name2  => cv_tkn_item_cd                               -- �g�[�N���R�[�h2
                         , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          lv_chk_status := cv_status_check;
          ov_retcode := cv_status_check;
      END;
      --
      IF lv_chk_status = cv_status_normal THEN
        --�}�X�^�`�F�b�Nok�̏ꍇ�̂݁A�ȍ~�̏������p��
        -------------------------------------------------
        -- 2.�o���敪�擾
        -------------------------------------------------
        g_upload_data_tab(ln_line_no).bara_kbn := cv_n;
        --
        FOR i IN 1..g_bara_unit_tab.COUNT LOOP
          IF lt_unit_of_issue = g_bara_unit_tab(i) THEN
            g_upload_data_tab(ln_line_no).bara_kbn := cv_y;
          END IF;
        END LOOP;
        --
        -------------------------------------------------
        -- 3.���i�Q�\�Z���݃`�F�b�N
        -------------------------------------------------
        BEGIN
          SELECT 'x'
          INTO   lv_dmy
          FROM   xxcsm_item_plan_lines    xipl
          WHERE  xipl.item_plan_header_id = gt_item_plan_header_id
          AND    xipl.item_group_no       =  g_upload_data_tab(ln_line_no).item_group_no
          AND    xipl.item_kbn            = cv_item_kbn_group
          AND    ROWNUM                   = 1
          ;
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --���i�Q�\�Z�����݂��܂���
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm                         -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10314                              -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd                                 -- �g�[�N���R�[�h1
                           , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no    -- �g�[�N���l1�i���i�Q�j
                           , iv_token_name2  => cv_tkn_item_cd                                 -- �g�[�N���R�[�h2
                           , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no          -- �g�[�N���l2�i���i�R�[�h�j
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
        END;
        --
        -------------------------------------------------
        -- 4.�c�ƌ����擾
        -------------------------------------------------
        BEGIN
          -- �֑ؑO�N�x�̉c�ƌ�����i�ڕύX��������擾
          SELECT xsibh.discrete_cost                                           -- �c�ƌ���
          INTO   g_upload_data_tab(ln_line_no).discrete_cost
          FROM   xxcmm_system_items_b_hst   xsibh                              -- �i�ڕύX�����e�[�u��
                ,(SELECT MAX(item_hst_id)   item_hst_id                        -- �i�ڕύX����ID
                  FROM   xxcmm_system_items_b_hst                              -- �i�ڕύX����
                  WHERE  item_code  = g_upload_data_tab(ln_line_no).item_no    -- �i�ڃR�[�h
                  AND    apply_date < gd_start_date                            -- �N�x�J�n���O
                  AND    apply_flag = cv_y                                     -- �K�p�ς�
                  AND    discrete_cost IS NOT NULL                             -- �c�ƌ��� IS NOT NULL
                 ) xsibh_view
          WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id                    -- �i�ڕύX����ID
          AND    xsibh.item_code   = g_upload_data_tab(ln_line_no).item_no     -- ���i�R�[�h
          AND    xsibh.apply_flag  = cv_y                                      -- �K�p�ς�
          AND    xsibh.discrete_cost IS NOT NULL
          ;
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�c�ƌ����擾�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm                       -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10315                            -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd                               -- �g�[�N���R�[�h1
                           , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no  -- �g�[�N���l1�i���i�Q�j
                           , iv_token_name2  => cv_tkn_item_cd                               -- �g�[�N���R�[�h2
                           , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
        END;
        -------------------------------------------------
        -- 5.�艿�擾
        -------------------------------------------------
        BEGIN
          -- �֑ؑO�N�x�̒艿��i�ڕύX��������擾
          SELECT xsibh.fixed_price                                             -- �艿
          INTO   g_upload_data_tab(ln_line_no).fixed_price
          FROM   xxcmm_system_items_b_hst   xsibh                              -- �i�ڕύX�����e�[�u��
                ,(SELECT MAX(item_hst_id)   item_hst_id                        -- �i�ڕύX����ID
                  FROM   xxcmm_system_items_b_hst                              -- �i�ڕύX����
                  WHERE  item_code  = g_upload_data_tab(ln_line_no).item_no    -- �i�ڃR�[�h
                  AND    apply_date < gd_start_date                            -- �N�x�J�n���O
                  AND    apply_flag = cv_y                                     -- �K�p�ς�
                  AND    fixed_price IS NOT NULL                               -- �艿 IS NOT NULL
                    ) xsibh_view
          WHERE  xsibh.item_hst_id = xsibh_view.item_hst_id                    -- �i�ڕύX����ID
          AND    xsibh.item_code   = g_upload_data_tab(ln_line_no).item_no     -- ���i�R�[�h
          AND    xsibh.apply_flag  = cv_y                                      -- �K�p�ς�
          AND    xsibh.fixed_price IS NOT NULL
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�艿�擾�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name_csm                       -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_msg_xxcsm10316                            -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_deal_cd                               -- �g�[�N���R�[�h1
                           , iv_token_value1 => g_upload_data_tab(ln_line_no).item_group_no  -- �g�[�N���l1�i���i�Q�j
                           , iv_token_name2  => cv_tkn_item_cd                               -- �g�[�N���R�[�h2
                           , iv_token_value2 => g_upload_data_tab(ln_line_no).item_no        -- �g�[�N���l2�i���i�R�[�h�j
                         );
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_retcode := cv_status_check;
        END;
        --
      END IF;
      --
      ln_line_no := ln_line_no + 4;
      --
    END LOOP  chk_item_loop;
    --
    --���i�Q�A���i�̑Ó����`�F�b�N�I��
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 6.����A�e���z�A�e�����A�|���`�F�b�N
    -------------------------------------------------
    ln_line_no := 1;
    << chk_value_loop >>
    LOOP
      EXIT WHEN ln_line_no > g_upload_data_tab.COUNT;
      --
      --12���������[�v
      <<LOOP1>>
      FOR i IN 1..12 LOOP
        lv_step := '�\�Z�l�`�F�b�N ���i:'||g_upload_data_tab(ln_line_no).item_no||' i='||TO_CHAR(i);
        IF i = 1 THEN
          lv_month               := '5';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_05;      -- ����
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_05;  -- �e���z
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_05;  -- �e����
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_05;  -- �|��
        ELSIF i = 2 THEN
          lv_month               := '6';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_06;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_06;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_06;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_06;
        ELSIF i = 3 THEN
          lv_month               := '7';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_07;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_07;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_07;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_07;
        ELSIF i = 4 THEN
          lv_month               := '8';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_08;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_08;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_08;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_08;
        ELSIF i = 5 THEN
          lv_month               := '9';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_09;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_09;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_09;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_09;
        ELSIF i = 6 THEN
          lv_month               := '10';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_10;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_10;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_10;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_10;
        ELSIF i = 7 THEN
          lv_month               := '11';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_11;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_11;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_11;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_11;
        ELSIF i = 8 THEN
          lv_month               := '12';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_12;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_12;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_12;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_12;
        ELSIF i = 9 THEN
          lv_month               := '1';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_01;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_01;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_01;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_01;
        ELSIF i = 10 THEN
          lv_month               := '2';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_02;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_02;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_02;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_02;
        ELSIF i = 11 THEN
          lv_month               := '3';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_03;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_03;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_03;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_03;
        ELSE
          lv_month               := '4';
          ln_sales_budget        := g_upload_data_tab(ln_line_no).month_04;
          ln_amount_gross_margin := g_upload_data_tab(ln_line_no + 1).month_04;
          ln_margin_rate         := g_upload_data_tab(ln_line_no + 2).month_04;
          ln_credit_rate         := g_upload_data_tab(ln_line_no + 3).month_04;
        END IF;
        --
        -------------------------------------------------
        -- 6-1.�A�b�v���[�h�\�Z�l�`�F�b�N
        -------------------------------------------------
        chk_budget_item(
          ov_errbuf               => lv_errbuf          -- �G���[�E���b�Z�[�W
         ,ov_retcode              => lv_retcode         -- ���^�[���E�R�[�h
         ,ov_errmsg               => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
         ,iv_item_group_no        => g_upload_data_tab(ln_line_no).item_group_no
         ,iv_item_no              => g_upload_data_tab(ln_line_no).item_no
         ,iv_month                => lv_month
         ,in_sales_budget         => ln_sales_budget         -- ����
         ,in_amount_gross_margin  => ln_amount_gross_margin  -- �e���z
         ,in_margin_rate          => ln_margin_rate          -- �e����
         ,in_credit_rate          => ln_credit_rate          -- �|��
        );
        -- �X�e�[�^�X�G���[����
        IF ( lv_retcode = cv_status_check ) THEN
          ov_retcode := cv_status_check;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END LOOP  LOOP1;
      --
      ln_line_no := ln_line_no + 4;
      --
    END LOOP  chk_value_loop;
    --
    -- �X�e�[�^�X�G���[����
    IF ov_retcode = cv_status_check THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- �\�Z�l�`�F�b�N��O�n���h��
    ----------------------------------------------------------
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_validate_item;
  --
  --
  /**********************************************************************************
   * Procedure Name   : chk_upload_item
   * Description      : �A�b�v���[�h���ڃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_upload_item(
     ov_errbuf     OUT VARCHAR2                           -- �G���[�E���b�Z�[�W
    ,ov_retcode    OUT VARCHAR2                           -- ���^�[���E�R�[�h
    ,ov_errmsg     OUT VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,it_file_data  IN  xxccp_common_pkg2.g_file_data_tbl  -- BLOB�ϊ���
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_upload_item'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);       -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);    -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg       VARCHAR2(2000);    -- ���b�Z�[�W
    lb_retcode       BOOLEAN;           -- API���^�[���E���b�Z�[�W�p
    --�A�b�v���[�h���ڃ`�F�b�N
    ln_col_cnt                  PLS_INTEGER := 0;                  -- �A�b�v���[�h���ڐ�
    lt_csv_data_all             xxcok_common_pkg.g_split_csv_tbl;  -- CSV�����f�[�^�iTRIM�O�j
    lt_csv_data                 xxcok_common_pkg.g_split_csv_tbl;  -- CSV�����f�[�^�iTRIM��j
    --����f�[�^�i�[�p  INDEX = ���i�Q(4) || ���i�R�[�h(7) || ���R�[�h�敪(1) || �J�E���^(5)
    TYPE l_upload_data_ttype_v IS TABLE OF g_upload_data_rtype INDEX BY VARCHAR2(17);
    lt_upload_data_tab_v        l_upload_data_ttype_v;
    lv_step                     VARCHAR2(200);
    --
    lv_index                    VARCHAR2(17);  --���i�Q(4) || ���i�R�[�h(7) || ���R�[�h�敪(1) || �J�E���^(5)
    --
    ln_line_cnt                 NUMBER;        --�A�b�v���[�h���R�[�h�J�E���^
    lv_item_err                 VARCHAR2(1);   --���^�[���E�R�[�h
    lv_chk_status               VARCHAR2(1);
    --===============================
    -- ���[�J����O
    --===============================
    --
  BEGIN
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    -------------------------------------------------
    -- 1.�A�b�v���[�h�f�[�^���ڃ`�F�b�N
    -------------------------------------------------
    << split_item_loop >>
    FOR ln_line_no IN 1..it_file_data.COUNT LOOP
      -------------------------------------------------
      -- 1-1.�A�b�v���[�h�f�[�^���ڕ���
      -------------------------------------------------
      xxcok_common_pkg.split_csv_data_p(
        ov_errbuf        => lv_errbuf                 -- �G���[�E���b�Z�[�W
       ,ov_retcode       => lv_retcode                -- ���^�[���E�R�[�h
       ,ov_errmsg        => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
       ,iv_csv_data      => it_file_data(ln_line_no)  -- CSV������i�A�b�v���[�h1�s�j
       ,on_csv_col_cnt   => ln_col_cnt                -- CSV���ڐ�
       ,ov_split_csv_tab => lt_csv_data_all           -- CSV�����f�[�^�i�z��ŕԂ��jTRIM�O�z��
      );
      --
      -------------------------------------------------
      -- 1-2.���ڐ��`�F�b�N
      -------------------------------------------------
      IF ( gn_item_cnt <> ln_col_cnt ) THEN
        -- ���ڐ�����G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name_csm  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcsm10301       -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_row_num          -- �g�[�N���R�[�h1
                       , iv_token_value1 => ln_line_no + 1          -- �g�[�N���l1�i���o�����݂̍s���j
                     );
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        ov_retcode  := cv_status_check;
        CONTINUE;
      END IF;
      --
      -------------------------------------------------
      -- 1-3.�A�b�v���[�h�l���ڃ`�F�b�N
      -------------------------------------------------
      lv_chk_status := cv_status_normal;
      << item_check_loop >>
      FOR ln_item_no IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
        --
        lt_csv_data(ln_item_no) := TRIM( lt_csv_data_all(ln_item_no) );  --TRIM��z���
        --
        lv_step := '�A�b�v���[�h�l���ڃ`�F�b�N �s�ԍ�='||TO_CHAR(ln_line_no+1)||' ���ڔԍ�='||TO_CHAR(ln_item_no)||' �l=['||lt_csv_data(ln_item_no)||']';
        -- ���ڃ`�F�b�N���ʊ֐�
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(ln_item_no).meaning     -- ���ږ���
         ,iv_item_value   => lt_csv_data(ln_item_no)                -- ���ڂ̒l
         ,in_item_len     => g_chk_item_tab(ln_item_no).attribute1  -- ���ڂ̒���
         ,in_item_decimal => g_chk_item_tab(ln_item_no).attribute2  -- ���ڂ̒���(�����_�ȉ�)
         ,iv_item_nullflg => g_chk_item_tab(ln_item_no).attribute3  -- �K�{�t���O
         ,iv_item_attr    => g_chk_item_tab(ln_item_no).attribute4  -- ���ڑ���
         ,ov_errbuf       => lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode      => lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg       => lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- ���^�[���R�[�h������ȊO�̏ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- ���ڕs���G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_short_name_csm               -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcsm10302                    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_item                          -- �g�[�N���R�[�h1
                         , iv_token_value1 => g_chk_item_tab(ln_item_no).meaning   -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_errmsg                        -- �g�[�N���R�[�h2
                         , iv_token_value2 => lv_errmsg                            -- �g�[�N���l2
                         , iv_token_name3  => cv_tkn_row_num                       -- �g�[�N���R�[�h3
                         , iv_token_value3 => ln_line_no + 1                       -- �g�[�N���l3�i���o�����݂̍s���j
                       );
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          --
          lv_chk_status := cv_status_error;
          --
        END IF;
        --
      END LOOP item_check_loop;
      --
      -------------------------------------------------
      -- 1-4.����f�[�^�ޔ�
      -------------------------------------------------
      lv_step := '����f�[�^�ޔ� �s�ԍ�='||TO_CHAR(ln_line_no+1);
      IF ( lv_chk_status = cv_status_normal ) THEN
        -- ����f�[�^�ޔ�
        -- index = ���i�Q + ���i�R�[�h + ���R�[�h�敪 + �V�[�P���X
        lv_index := lt_csv_data(3) || lt_csv_data(4) || CASE lt_csv_data(6) 
                                                        WHEN cv_rec_type_a_name THEN cv_a
                                                        WHEN cv_rec_type_b_name THEN cv_b
                                                        WHEN cv_rec_type_c_name THEN cv_c
                                                        WHEN cv_rec_type_d_name THEN cv_d
                                                        ELSE cv_z
                                                        END
                                                     || TO_CHAR(ln_line_no, 'FM00000')
                                                        ;
        --
        lt_upload_data_tab_v(lv_index).location_cd   := lt_csv_data(1) ;   -- ���_�R�[�h
        lt_upload_data_tab_v(lv_index).plan_year     := lt_csv_data(2) ;   -- �N�x
        lt_upload_data_tab_v(lv_index).item_group_no := lt_csv_data(3) ;   -- ���i�Q
        lt_upload_data_tab_v(lv_index).item_no       := lt_csv_data(4) ;   -- ���i�R�[�h
        lt_upload_data_tab_v(lv_index).item_name     := lt_csv_data(5) ;   -- ���i��
        lt_upload_data_tab_v(lv_index).rec_type      := CASE lt_csv_data(6)
                                                        WHEN cv_rec_type_a_name THEN cv_a
                                                        WHEN cv_rec_type_b_name THEN cv_b
                                                        WHEN cv_rec_type_c_name THEN cv_c
                                                        WHEN cv_rec_type_d_name THEN cv_d
                                                        ELSE cv_z
                                                        END;           --���R�[�h�敪 
        lt_upload_data_tab_v(lv_index).month_05      := lt_csv_data(7) ;   --  5�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_06      := lt_csv_data(8) ;   --  6�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_07      := lt_csv_data(9) ;   --  7�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_08      := lt_csv_data(10);   --  8�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_09      := lt_csv_data(11);   --  9�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_10      := lt_csv_data(12);   -- 10�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_11      := lt_csv_data(13);   -- 11�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_12      := lt_csv_data(14);   -- 12�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_01      := lt_csv_data(15);   --  1�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_02      := lt_csv_data(16);   --  2�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_03      := lt_csv_data(17);   --  3�����i���z�A���j
        lt_upload_data_tab_v(lv_index).month_04      := lt_csv_data(18);   --  4�����i���z�A���j
        --
      ELSE
        ov_retcode := cv_status_check;
      END IF;
      --
    END LOOP  split_item_loop;
    --
    IF ( ov_retcode = cv_status_check ) THEN
      ov_retcode := cv_status_error;
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 2.����f�[�^���ёւ��i���i�Q�A���i�A���R�[�h�敪���j
    -------------------------------------------------
    lv_index    := lt_upload_data_tab_v.FIRST;
    ln_line_cnt := 1;
    LOOP
      g_upload_data_tab(ln_line_cnt) := lt_upload_data_tab_v(lv_index);
      --
      EXIT WHEN lv_index = lt_upload_data_tab_v.LAST;
      lv_index := lt_upload_data_tab_v.NEXT(lv_index);
      ln_line_cnt := ln_line_cnt + 1;
      --
    END LOOP;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_upload_item;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_upload_line
   * Description      : �A�b�v���[�h�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_line(
    ov_errbuf       OUT VARCHAR2    -- �G���[�E���b�Z�[�W
   ,ov_retcode      OUT VARCHAR2    -- ���^�[���E�R�[�h
   ,ov_errmsg       OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W
   ,iv_file_id      IN  VARCHAR2    -- �t�@�C��ID
   ,ot_file_data    OUT xxccp_common_pkg2.g_file_data_tbl  -- BLOB�ϊ���(���o���A��s����)
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_upload_line'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf        VARCHAR2(5000);                                -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);                                   -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);                                -- ���[�U�[�E�G���[�E���b�Z�[�W
    lb_retcode       BOOLEAN;                                       -- API���^�[���E���b�Z�[�W�p
    lv_out_msg       VARCHAR2(2000);                                -- ���b�Z�[�W
    -- BLOB
    lt_file_data_all          xxccp_common_pkg2.g_file_data_tbl;    -- BLOB�ϊ���f�[�^�ޔ�(�S�f�[�^)
    ln_line_cnt               NUMBER;                               -- CSV�����s�J�E���^
    --===============================
    -- ���[�J����O
    --===============================
    blob_err_expt    EXCEPTION; -- BLOB�ϊ��G���[
    no_data_err_expt EXCEPTION; -- �A�b�v���[�h�����ΏۂȂ��G���[
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    ln_line_cnt := 0;
    --
    -------------------------------------------------
    -- 1.BLOB�f�[�^�ϊ�
    -------------------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => TO_NUMBER(iv_file_id)  -- �t�@�C��ID
     ,ov_file_data => lt_file_data_all       -- BLOB�ϊ���f�[�^�ޔ�(��s�A���o���܂�)
     ,ov_errbuf    => lv_errbuf              -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode             -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE blob_err_expt;
    END IF;
    -------------------------------------------------
    -- 2.2.���o���A�����s���O
    -------------------------------------------------
    << blob_data_loop >>
    FOR i IN 2..lt_file_data_all.COUNT LOOP
      IF ( LENGTHB( REPLACE( lt_file_data_all(i), ',', '') ) <> 0 ) THEN
        ln_line_cnt := ln_line_cnt + 1;
        ot_file_data(ln_line_cnt) := lt_file_data_all(i);
      END IF;
    END LOOP blob_data_loop;
    -- �����Ώی�����ޔ�
    gn_target_cnt := ln_line_cnt;  --���o���A��s������������
    -- �ҏW�p�̃e�[�u���폜
    lt_file_data_all.DELETE;
    -- �����Ώۑ��݃`�F�b�N
    IF ( gn_target_cnt <= cn_0 ) THEN
      RAISE no_data_err_expt;
    END IF;
    --
  EXCEPTION
    ----------------------------------------------------------
    -- BLOB�ϊ���O�n���h��
    ----------------------------------------------------------
    WHEN blob_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10304
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => iv_file_id
                    );
      -- �G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- �A�b�v���[�h�����ΏۂȂ���O�n���h��
    ----------------------------------------------------------
    WHEN no_data_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm
                      ,iv_name         => cv_msg_xxcsm10305
                    );
      -- �G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END get_upload_line;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg     VARCHAR2(2000);  -- ���b�Z�[�W
    lb_retcode     BOOLEAN;         -- ���b�Z�[�W�߂�l
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �A�b�v���[�h���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- ���ږ���
           , flv.attribute1    AS attribute1  -- ���ڂ̒���
           , flv.attribute2    AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3    AS attribute3  -- �K�{�t���O
           , flv.attribute4    AS attribute4  -- ����
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_upload_item_chk_name
      AND    gd_proc_date BETWEEN NVL( flv.start_date_active, gd_proc_date )
                              AND NVL( flv.end_date_active, gd_proc_date )
      AND    flv.enabled_flag = cv_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
    ;
    --
    -- ��v�J�����_���瓖�N�x�J�n�����擾�J�[�\��
    CURSOR cur_get_month_this_year
    IS 
      SELECT   glpds.start_date            AS start_date             -- �N�x�J�n��
      FROM     gl_periods        glpds,                              -- ��v�J�����_�e�[�u��
               gl_sets_of_books  glsob                               -- ��v����}�X�^
      WHERE    glsob.set_of_books_id        = gn_gl_set_of_bks_id    -- ��v����ID
      AND      glpds.period_set_name        = glsob.period_set_name  -- �J�����_��
      AND      glpds.period_year            = gt_plan_year           -- �\�Z�N�x
      AND      glpds.adjustment_period_flag = cv_n                   -- ������v���ԊO
      AND      glpds.period_num             = 1                      -- �N�x�J�n��
    ;
    rec_get_month_this_year cur_get_month_this_year%ROWTYPE;
--
    -- ��v�J�����_�����N�x�J�n�����擾
    CURSOR cur_get_month_last_year
    IS
    SELECT   glpds.start_date              AS start_date             -- �N�x�J�n��
    FROM     gl_periods        glpds,                                -- ��v�J�����_�e�[�u��
             gl_sets_of_books  glsob                                 -- ��v����}�X�^
    WHERE    glsob.set_of_books_id        = gn_gl_set_of_bks_id      -- ��v����ID
    AND      glpds.period_set_name        = glsob.period_set_name    -- �J�����_��
    AND      glpds.period_year            = gt_plan_year - 1         -- �\�Z�N�x
    AND      glpds.adjustment_period_flag = cv_n                     -- ������v���ԊO
    AND      glpds.period_num             = 1;                       -- �N�x�J�n��
    rec_get_month_last_year cur_get_month_last_year%ROWTYPE;
--
    -- �o���P�ʎ擾�J�[�\��
    CURSOR bara_unit_cur
    IS
      SELECT  flv.meaning                  AS meaning
      FROM    fnd_lookup_values   flv                   --�u�N�C�b�N�R�[�h�l�v
      WHERE   flv.lookup_type     = cv_lookup_type_bara
      AND     flv.language        = ct_lang
      AND     flv.enabled_flag    = cv_y
      AND     gd_proc_date  BETWEEN  NVL(flv.start_date_active ,gd_proc_date)
                                AND  NVL(flv.end_date_active, gd_proc_date)
    ;
    --
    -- �o�^�O���i�擾�J�[�\��
    CURSOR out_regist_item_cur
    IS
      SELECT flv.lookup_code               AS lookup_code
      FROM   fnd_lookup_values  flv                    -- �N�C�b�N�R�[�h�l
      WHERE  flv.lookup_type     = cv_out_regist_item  -- �Q�ƃ^�C�v�F�o�^�O���i�R�[�h
      AND    flv.language        = ct_lang             -- ����
      AND    flv.enabled_flag    = cv_y                -- �L���t���O
      AND    TRUNC(gd_proc_date)  BETWEEN  TRUNC(NVL(flv.start_date_active, gd_proc_date)) 
                                      AND  TRUNC(NVL(flv.end_date_active,   gd_proc_date))
    ;
    --
    -- �ϐ�
    ln_count                   NUMBER;
    lv_status                  VARCHAR2(1);                          -- ���ʊ֐��X�e�[�^�X
    lv_employee_code           per_people_f.employee_number%TYPE;    -- �]�ƈ��R�[�h
    --===============================
    -- ���[�J����O
    --===============================
    get_date_err_expt           EXCEPTION; -- �Ɩ��������t�擾�G���[
    get_item_chk_lookup_expt    EXCEPTION; -- ���ڃ`�F�b�N�p�N�C�b�N�R�[�h�擾�G���[
    get_profile_expt            EXCEPTION; -- �v���t�@�C���擾�G���[
    --
  BEGIN
  --
    -------------------------------------------------
    -- 0.������
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -------------------------------------------------
    -- 1.�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    -------------------------------------------------
    -- �R���J�����g�p�����[�^.�t�@�C��ID���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_csm
                   ,iv_name         => cv_msg_xxcsm00101
                   ,iv_token_name1  => cv_tkn_file_id
                   ,iv_token_value1 => iv_file_id
                  );
    -- �R���J�����g�p�����[�^.�t�@�C��ID���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- �R���J�����g�p�����[�^.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_csm
                   ,iv_name         => cv_msg_xxcsm00102
                   ,iv_token_name1  => cv_tkn_format
                   ,iv_token_value1 => iv_format
                  );
    -- �R���J�����g�p�����[�^.�t�H�[�}�b�g�p�^�[�����b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    -- ���[�U�[ID�̎擾
    gn_user_id   := FND_GLOBAL.USER_ID;
    -------------------------------------------------
    -- 2.�Ɩ��������t�擾
    -------------------------------------------------
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    -------------------------------------------------
    -- 3.���ڃ`�F�b�N�p��`�擾
    -------------------------------------------------
    OPEN  chk_item_cur;
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    CLOSE chk_item_cur;
    --
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      RAISE get_item_chk_lookup_expt;
    END IF;
    --
    gn_item_cnt := g_chk_item_tab.COUNT;  --���ڐ��擾
    --
    -------------------------------------------------
    -- 4.�v���t�@�C���擾
    -------------------------------------------------
    -- XXCSM:�N�Ԕ̔��v��J�����_�[��
    gv_prof_yearplan_calender := FND_PROFILE.VALUE(cv_prof_yearplan_calender);
    IF( gv_prof_yearplan_calender IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- XXCSM:����Q�i�ڃJ�e�S�����薼
    gv_prof_deal_category := FND_PROFILE.VALUE(cv_prof_deal_category);
    IF( gv_prof_deal_category IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_deal_category
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- XXCOI:�݌ɑg�D�R�[�h
    gv_prof_organization_code  := FND_PROFILE.VALUE(cv_prof_organization_code);
    IF( gv_prof_organization_code IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_prof_organization_code
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- XXCSM:�_�~�[����K�w�Q��
    gv_dummy_dept_ref := FND_PROFILE.VALUE( cv_xxcsm1_dummy_dept_ref );
    IF( gv_dummy_dept_ref IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_xxcsm1_dummy_dept_ref
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- GL��v����ID
    gn_gl_set_of_bks_id         := FND_PROFILE.VALUE( cv_gl_set_of_bks_id_nm );
    IF( gn_gl_set_of_bks_id IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00005
                     ,iv_token_name1          => cv_tkn_prof_name
                     ,iv_token_value1         => cv_gl_set_of_bks_id_nm
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -- �݌ɑg�DID�擾����
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_prof_organization_code);
    IF( gn_organization_id IS NULL ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00037
                     ,iv_token_name1          => cv_tkn_org_code
                     ,iv_token_value1         => gv_prof_organization_code
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    IF ov_retcode = cv_status_error THEN
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 5.�N�Ԕ̔��v��J�����_���݃`�F�b�N
    -------------------------------------------------
    SELECT COUNT(*)
    INTO   ln_count
    FROM   fnd_flex_value_sets ffvs
    WHERE  flex_value_set_name = gv_prof_yearplan_calender
    ;
    -- �J�����_��`�����݂��Ȃ��ꍇ
    IF (ln_count = 0) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00006
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -------------------------------------------------
    -- 6.�\�Z�N�x�擾
    -------------------------------------------------
    xxcsm_common_pkg.get_yearplan_calender(
      id_comparison_date => gd_proc_date           -- �^�p��
     ,ov_status          => lv_status              -- ��������(0�F����A1�F�ُ�)
     ,on_active_year     => gt_plan_year           -- �擾�����\�Z�N�x
     ,ov_retcode         => lv_retcode             -- ���^�[���R�[�h
     ,ov_errbuf          => lv_errbuf              -- �G���[���b�Z�[�W
     ,ov_errmsg          => lv_errmsg              -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �\�Z�N�x�����݂��Ȃ��ꍇ
    IF ( lv_status <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00004
                     ,iv_token_name1          => cv_tkn_item
                     ,iv_token_value1         => gv_prof_yearplan_calender
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    -------------------------------------------------
    -- 7.���O�C�����[�U�[�ݐЋ��_�擾
    -------------------------------------------------
    xxcsm_common_pkg.get_login_user_foothold(
      in_user_id       => gn_user_id               --���[�UID
     ,ov_foothold_code => gv_user_foothold         --���_�R�[�h
     ,ov_employee_code => lv_employee_code         --�]�ƈ��R�[�h
     ,ov_retcode       => lv_retcode               --���^�[���R�[�h
     ,ov_errbuf        => lv_errbuf                --�G���[���b�Z�[�W
     ,ov_errmsg        => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
    );
    -- ���O�C�����[�U�[�ݐЋ��_�����݂��Ȃ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm00059
                     ,iv_token_name1          => cv_tkn_user_id
                     ,iv_token_value1         => gn_user_id
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000)
      );
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
    END IF;
    --
    IF ov_retcode = cv_status_error THEN
      RETURN;
    END IF;
    --
    -------------------------------------------------
    -- 8.�N�x�J�n���擾
    -------------------------------------------------
    -- �p�����[�^�̏�����
    gd_start_date := NULL;
    -- �N�x�J�n�����擾
    OPEN cur_get_month_this_year;
    FETCH cur_get_month_this_year INTO rec_get_month_this_year;
    CLOSE cur_get_month_this_year;
    -- �p�����[�^.�N�x�J�n�����Z�b�g
    gd_start_date := rec_get_month_this_year.start_date;
    --
    -- ��v�J�����_�ɗ��N�x�̉�v���Ԃ���`����Ă��Ȃ������ꍇ
    IF (gd_start_date IS NULL) THEN
      -- �N�x�J�n�����擾
      OPEN cur_get_month_last_year;
      FETCH cur_get_month_last_year INTO rec_get_month_last_year;
      CLOSE cur_get_month_last_year;
      -- �p�����[�^.�N�x�J�n�����Z�b�g
      gd_start_date := rec_get_month_last_year.start_date;
    END IF;
    --
    -------------------------------------------------
    -- 9.�o���P�ʎ擾
    -------------------------------------------------
    OPEN  bara_unit_cur;
    FETCH bara_unit_cur BULK COLLECT INTO g_bara_unit_tab;
    CLOSE bara_unit_cur;
    --
    -------------------------------------------------
    -- 10.�o�^�O���i�擾
    -------------------------------------------------
    OPEN  out_regist_item_cur;
    FETCH out_regist_item_cur BULK COLLECT INTO g_out_regist_item_tab;
    CLOSE out_regist_item_cur;
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �Ɩ��������t�擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_csm
                     ,iv_name         => cv_msg_xxcsm10303
                    );
      -- �G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ڃ`�F�b�N�p�N�C�b�N�R�[�h�擾��O�n���h��
    ----------------------------------------------------------
    WHEN get_item_chk_lookup_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name_csm    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcsm10320         -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_lookup_value_set   -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_upload_item_chk_name   -- �g�[�N���l1
                    );
      -- �G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => cv_blank
      );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      IF ( cur_get_month_this_year%ISOPEN ) THEN
        CLOSE cur_get_month_this_year;
      END IF;
      IF ( cur_get_month_last_year%ISOPEN ) THEN
        CLOSE cur_get_month_last_year;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    --===============================
    -- ���[�J���J�[�\����`
    --===============================
    -- �V���i���z�}�C�i�X�f�[�^�擾
    CURSOR new_item_minus_cur
    IS
      SELECT  xipl.item_group_no
      FROM    xxcsm_item_plan_lines    xipl                      --�w���i�v�斾�׃e�[�u���x
      WHERE   xipl.item_plan_header_id = gt_item_plan_header_id  -- ���i�v��w�b�_ID
      AND     xipl.item_kbn            = cv_item_kbn_new         -- ���i�敪(2:�V���i)
      AND    (xipl.sales_budget        < 0                       -- ����܂��͑e���v���}�C�i�X
              OR xipl.amount_gross_margin < 0 )
      GROUP BY xipl.item_group_no
      ORDER BY xipl.item_group_no
    ;
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf                 VARCHAR2(5000);             -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);             -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg                VARCHAR2(2000);             -- ���b�Z�[�W
    lb_retcode                BOOLEAN;                    -- ���b�Z�[�W�߂�l
    --BLOB�ϊ���f�[�^�ޔ�(���o���A�󔒍s�r����)
    lt_file_data              xxccp_common_pkg2.g_file_data_tbl;
    --===============================
    -- ���[�J����O
    --===============================
    sub_proc_err_expt    EXCEPTION; -- �ďo���v���O�����̃G���[
  --
  BEGIN
  --
    --===============================================
    -- A-0.������
    --===============================================
    ov_retcode := cv_status_normal;
    --===============================================
    -- A-1.��������
    --===============================================
    init_proc(
      ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
     ,iv_file_id => iv_file_id -- �t�@�C��ID
     ,iv_format  => iv_format  -- �t�H�[�}�b�g
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-2.�A�b�v���[�h�f�[�^�擾
    --===============================================
    get_upload_line(
      ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
     ,iv_file_id   => iv_file_id    -- �t�@�C��ID
     ,ot_file_data => lt_file_data  -- BLOB�ϊ���(���o���A��s����)
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-3.�A�b�v���[�h���ڃ`�F�b�N
    --===============================================
    chk_upload_item(
      ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
     ,it_file_data => lt_file_data  -- BLOB�ϊ���
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    lt_file_data.DELETE;
    --
    --===============================================
    -- A-4.�Ó����`�F�b�N����
    --===============================================
    chk_validate_item(
      ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-5.�P�i�\�Z�ݒ�
    --===============================================
    set_item_bgt(
      ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-7.�V���i���z�`�F�b�N(�o�^��`�F�b�N)
    --===============================================
    FOR new_item_minus_rec IN new_item_minus_cur LOOP
      lv_out_msg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_csm
                     ,iv_name                 => cv_msg_xxcsm10323
                     ,iv_token_name1          => cv_tkn_deal_cd
                     ,iv_token_value1         => new_item_minus_rec.item_group_no
                    );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_out_msg
      );
      ov_retcode := cv_status_warn;
    END LOOP;
    --===============================================
    -- A-8.�A�b�v���[�h�f�[�^�폜
    --===============================================
    del_upload_data(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
      ,iv_file_id => iv_file_id -- �t�@�C��ID
    );
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- �T�u�v���O������O�n���h��
    ----------------------------------------------------------
    WHEN sub_proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      ROLLBACK;
      --
      del_upload_data(
         ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
        ,iv_file_id => iv_file_id -- �t�@�C��ID
      );
      COMMIT;
      --
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- �G���[�E���b�Z�[�W
    ,retcode    OUT VARCHAR2 -- ���^�[���E�R�[�h
    ,iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    ,iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
  )
  IS
    --===============================
    -- ���[�J���萔
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    --===============================
    -- ���[�J���ϐ�
    --===============================
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_out_msg      VARCHAR2(2000);  -- ���b�Z�[�W
    lv_message_code VARCHAR2(5000);  -- �����I�����b�Z�[�W
    lb_retcode      BOOLEAN;         -- ���b�Z�[�W�߂�l
  --
  BEGIN
  --
    --===============================================
    -- ������
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- �R���J�����g�w�b�_�o��
    --===============================================
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --
    --===============================================
    -- �T�u���C������
    --===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      ,ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      ,ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      ,iv_file_id => iv_file_id -- �t�@�C��ID
      ,iv_format  => iv_format  -- �t�H�[�}�b�g
    );
    --
    IF ( lv_retcode <> cv_status_error ) THEN
      gn_normal_cnt := gn_target_cnt;
    ELSE
      -- �G���[���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_blank
      );
      -- �G���[�����������ݒ�
      gn_normal_cnt := cn_0;  -- ���팏��
      gn_error_cnt  := cn_1;  -- �G���[����
    END IF;
    --
    --===============================================
    -- �I������
    --===============================================
    -------------------------------------------------
    -- 1.�Ώی������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -------------------------------------------------
    -- 2.�����������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -------------------------------------------------
    -- 3.�G���[�������b�Z�[�W�o��
    -------------------------------------------------
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    -------------------------------------------------
    -- 4.�I�����b�Z�[�W�o��
    -------------------------------------------------
    -- �I�����b�Z�[�W���f
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_nrmal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSE
      lv_message_code := cv_error_msg;
    END IF;
    -- ���b�Z�[�W�擾
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- ���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- ���ʊ֐�OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS��O�n���h��
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCSM002A18C;
/
