CREATE OR REPLACE PACKAGE BODY APPS.XXCMM004A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM004A13C(body)
 * Description      : �ύX�\����ꊇ�o�^
 * MD.050           : �ύX�\����ꊇ�o�^ MD050_CMM_004_A13
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  validate_data          �Ó����`�F�b�N����(A-4)
 *  ins_item_chg_data      �ύX�\����o�^����(A-5)
 *  del_item_chg_data      �ύX�\����폜����(A-6)
 *  loop_main              �ꎞ�\�擾����(A-3)�A�Ó����`�F�b�N����(A-4)
 *  get_if_data            �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
 *  del_if_data            �t�@�C���A�b�v���[�h�f�[�^�폜����(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/07/19    1.0   S.Niki           E_�{�ғ�_14300�Ή� �V�K�쐬
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
  --*** ���b�N�G���[��O ***
  global_check_lock_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_appl_name_xxcmm       CONSTANT VARCHAR2(5)   := 'XXCMM';               -- �A�v���P�[�V�����Z�k��
  cv_pkg_name              CONSTANT VARCHAR2(100) := 'XXCMM004A13C';        -- �p�b�P�[�W��
  cv_msg_comma             CONSTANT VARCHAR2(1)   := ',';                   -- �J���}
  cv_file_format           CONSTANT VARCHAR2(3)   := '540';                 -- �ύX�\����ꊇ�o�^
--
  -- �f�[�^���ڒ�`�p
  cv_varchar               CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_varchar;        -- ������
  cv_number                CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_number;         -- ���l
  cv_date                  CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date;           -- ���t
  cv_varchar_cd            CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_varchar_cd;     -- �����񍀖�
  cv_number_cd             CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_number_cd;      -- ���l����
  cv_date_cd               CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_date_cd;        -- ���t����
  cv_not_null              CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_not_null;       -- �K�{
  cv_null_ok               CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ok;        -- �C�Ӎ���
  cv_null_ng               CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ng;        -- �K�{����
--
  -- �v���t�@�C����
  cv_prf_item_num          CONSTANT VARCHAR2(60)  := 'XXCMM1_004A13_ITEM_NUM';         -- XXCMM:�ύX�\����ꊇ�o�^�f�[�^���ڐ�
  cv_prf_org_code          CONSTANT VARCHAR2(60)  := 'XXCOI1_ORGANIZATION_CODE';       -- XXCOI:�݌ɑg�D�R�[�h
--
  -- LOOKUP�\
  cv_lookup_file_up_obj    CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';         -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_lookup_item_def       CONSTANT VARCHAR2(30)  := 'XXCMM1_004A13_ITEM_DEF';         -- �ύX�\����ꊇ�o�^�f�[�^���ڒ�`
  cv_lookup_item_status    CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_STATUS';               -- �i�ڃX�e�[�^�X
--
  -- ���b�Z�[�W
  cv_msg_xxcmm_00018       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';      -- �Ɩ����t�擾�G���[
  cv_msg_xxcmm_00002       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';      -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_10429       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10429';      -- �擾���s�G���[
  cv_msg_xxcmm_00402       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00402';      -- IF���b�N�擾�G���[
  cv_msg_xxcmm_00021       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00021';      -- �g�DID�擾�G���[���b�Z�[�W
  cv_msg_xxcmm_00015       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00015';      -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmm_00022       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00022';      -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_00023       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00023';      -- FILE_ID�m�[�g
  cv_msg_xxcmm_00024       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00024';      -- �t�H�[�}�b�g�m�[�g
  cv_msg_xxcmm_00028       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00028';      -- �f�[�^���ڐ��G���[
  cv_msg_xxcmm_00403       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00403';      -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmm_10328       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10328';      -- �l�`�F�b�N�G���[
  cv_msg_xxcmm_10330       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10330';      -- �Q�ƃR�[�h���݃`�F�b�N�G���[
  cv_msg_xxcmm_10481       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10481';      -- IF�f�[�^�폜�G���[
  cv_msg_xxcmm_10461       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10461';      -- ���ږ����̓G���[
  cv_msg_xxcmm_10462       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10462';      -- �e�i�ڌp�����ړ��̓G���[
  cv_msg_xxcmm_10463       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10463';      -- �K�p���ߋ����G���[
  cv_msg_xxcmm_10464       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10464';      -- �i�ڏd���G���[
  cv_msg_xxcmm_10465       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10465';      -- �Ώۃ��R�[�h���݃`�F�b�N�G���[
  cv_msg_xxcmm_10466       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10466';      -- �Ώۃ��R�[�h�񑶍݃`�F�b�N�G���[
  cv_msg_xxcmm_10467       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10467';      -- �i�ڃX�e�[�^�X�p�~�G���[
  cv_msg_xxcmm_10468       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10468';      -- �i�ڃX�e�[�^�X�q�i�ڃG���[
  cv_msg_xxcmm_10469       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10469';      -- �i�ڃX�e�[�^�X�t���[�G���[
  cv_msg_xxcmm_10470       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10470';      -- �i�ڃX�e�[�^�X�K�p���G���[
  cv_msg_xxcmm_10471       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10471';      -- �i�ڃX�e�[�^�X����쐬�σG���[
  cv_msg_xxcmm_10472       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10472';      -- �i�ڃX�e�[�^�X���_�݌ɑ��݃G���[
  cv_msg_xxcmm_10473       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10473';      -- �i�ڃX�e�[�^�X�߂��G���[
  cv_msg_xxcmm_10474       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10474';      -- �p�~�i�ړ��̓G���[
  cv_msg_xxcmm_10475       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10475';      -- �i�ڃX�e�[�^�X���̔ԓo�^�G���[
  cv_msg_xxcmm_10476       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10476';      -- �W���������o�^�G���[
  cv_msg_xxcmm_10477       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10477';      -- �K�p�ς݃��R�[�h�폜�G���[
  cv_msg_xxcmm_10478       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10478';      -- ����ύX�\�񃌃R�[�h�폜�G���[
  cv_msg_xxcmm_00407       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00407';      -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_00008       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';      -- ���b�N�擾�G���[
  cv_msg_xxcmm_10479       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10479';      -- �f�[�^�폜�G���[
  cv_msg_xxcmm_10480       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10480';      -- �ύX�\���񏈗�����
--
  -- �g�[�N���l
  cv_msg_xxcmm_10452       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10452';      -- ���ڃ`�F�b�N�p��`���
  cv_msg_xxcmm_10453       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10453';      -- �t�@�C���A�b�v���[�h����
  cv_msg_xxcmm_10454       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10454';      -- �݌ɉ�v����
  cv_msg_xxcmm_10455       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10455';      -- �ύX�\����ꊇ�o�^
  cv_msg_xxcmm_10456       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10456';      -- �i���R�[�h
  cv_msg_xxcmm_10457       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10457';      -- �i�ڃX�e�[�^�X
  cv_msg_xxcmm_10458       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10458';      -- �o�^�X�e�[�^�X
  cv_msg_xxcmm_10459       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10459';      -- �ύX�\����ꎞ�\
  cv_msg_xxcmm_10460       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-10460';      -- Disc�i�ڕύX�����A�h�I��
--
  -- �g�[�N����
  cv_tkn_ng_profile        CONSTANT VARCHAR2(20)  := 'NG_PROFILE';            -- �v���t�@�C����
  cv_tkn_value             CONSTANT VARCHAR2(20)  := 'VALUE';                 -- �l
  cv_tkn_ng_ou_name        CONSTANT VARCHAR2(20)  := 'NG_OU_NAME';            -- �g�D��
  cv_tkn_up_name           CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';           -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_name         CONSTANT VARCHAR2(20)  := 'FILE_NAME';             -- CSV�t�@�C����
  cv_tkn_file_id           CONSTANT VARCHAR2(20)  := 'FILE_ID';               -- FILE_ID
  cv_tkn_file_format       CONSTANT VARCHAR2(20)  := 'FORMAT';                -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_table             CONSTANT VARCHAR2(20)  := 'TABLE';                 -- �e�[�u����
  cv_tkn_ng_table          CONSTANT VARCHAR2(20)  := 'NG_TABLE';              -- NG�e�[�u����
  cv_tkn_input_line_no     CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';         -- �s�ԍ�
  cv_tkn_err_msg           CONSTANT VARCHAR2(20)  := 'ERR_MSG';               -- �G���[���b�Z�[�W
  cv_tkn_count             CONSTANT VARCHAR2(20)  := 'COUNT';                 -- ����
  cv_tkn_input             CONSTANT VARCHAR2(20)  := 'INPUT';                 -- ���ږ�
  cv_tkn_item_code         CONSTANT VARCHAR2(20)  := 'ITEM_CODE';             -- �i���R�[�h
  cv_tkn_input_item_code   CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';       -- �i���R�[�h
  cv_tkn_apply_date        CONSTANT VARCHAR2(20)  := 'APPLY_DATE';            -- �K�p��
  cv_tkn_ins_count         CONSTANT VARCHAR2(20)  := 'INS_COUNT';             -- �o�^����
  cv_tkn_del_count         CONSTANT VARCHAR2(20)  := 'DEL_COUNT';             -- �폜����
--
  -- �i�ڃX�e�[�^�X
  cn_itm_sts_num_tmp       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;       -- ���̔�
  cn_itm_sts_pre_reg       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;       -- ���o�^
  cn_itm_sts_regist        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;        -- �{�o�^
  cn_itm_sts_no_sch        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;        -- �p
  cn_itm_sts_trn_only      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;      -- �c�f
  cn_itm_sts_no_use        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;        -- �c
--
  -- �i�ڃJ�e�S��
  cv_ctg_set_seisakugun    CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;     -- ����Q�R�[�h
--
  cv_yes                   CONSTANT VARCHAR2(1)   := 'Y';                     -- �t���O�F�L��
  cv_no                    CONSTANT VARCHAR2(1)   := 'N';                     -- �t���O�F����
  cv_ins                   CONSTANT VARCHAR2(1)   := 'I';                     -- �o�^�X�e�[�^�X�F�o�^
  cv_del                   CONSTANT VARCHAR2(1)   := 'D';                     -- �o�^�X�e�[�^�X�F�폜
  cv_open                  CONSTANT VARCHAR2(1)   := 'Y';                     -- ���ԃI�[�v���t���O�F�I�[�v��
  cv_flag_yes              CONSTANT VARCHAR2(1)   := 'Y';                     -- �K�p�t���O�F�K�p����
  cv_flag_no               CONSTANT VARCHAR2(1)   := 'N';                     -- �K�p�t���O�F���K�p
  cv_wildcard              CONSTANT VARCHAR2(3)   := '%*%';                   -- ���C���h�J�[�h
--
  -- ���t����
  cv_date_fmt_std          CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';            -- ���t�����FYYYY/MM/DD
--
  cn_0                     CONSTANT NUMBER        := 0;                       -- �����F0
  cn_1                     CONSTANT NUMBER        := 1;                       -- �����F1
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڃ`�F�b�N�p��`���
  TYPE g_rec_item_def_data IS RECORD(
       item_name            VARCHAR2(100)                                     -- ���ږ�
     , item_attribute       VARCHAR2(100)                                     -- ���ڑ���
     , item_essential       VARCHAR2(100)                                     -- �K�{�t���O
     , int_length           NUMBER                                            -- ���ڂ̒���(��������)
     , dec_length           NUMBER                                            -- ���ڂ̒���(�����_�ȉ�)
  );
  TYPE g_tab_item_def_data IS TABLE OF g_rec_item_def_data  INDEX BY PLS_INTEGER;
--
  -- �o�^���R�[�h�i�[�ϐ�
  TYPE g_rec_ins_data IS RECORD(
       item_id              xxcmm_system_items_b_hst.item_id%TYPE             -- �i��ID
     , item_code            xxcmm_system_items_b_hst.item_code%TYPE           -- �i�ڃR�[�h
     , apply_date           xxcmm_system_items_b_hst.apply_date%TYPE          -- �K�p��
     , item_status          xxcmm_system_items_b_hst.item_status%TYPE         -- �i�ڃX�e�[�^�X
     , policy_group         xxcmm_system_items_b_hst.policy_group%TYPE        -- ����Q
     , discrete_cost        xxcmm_system_items_b_hst.discrete_cost%TYPE       -- �c�ƌ���
     , line_no              NUMBER                                            -- �s�ԍ�
  );
  TYPE g_tab_ins_data  IS TABLE OF g_rec_ins_data  INDEX BY PLS_INTEGER;
--
  -- �폜���R�[�h�i�[�ϐ�
  TYPE g_rec_del_data IS RECORD(
       item_hst_id          xxcmm_system_items_b_hst.item_hst_id%TYPE         -- �i�ڕύX����ID
     , item_code            xxcmm_system_items_b_hst.item_code%TYPE           -- �i�ڃR�[�h
     , apply_date           xxcmm_system_items_b_hst.apply_date%TYPE          -- �K�p��
     , line_no              NUMBER                                            -- �s�ԍ�
  );
  TYPE g_tab_del_data  IS TABLE OF g_rec_del_data  INDEX BY PLS_INTEGER;
--
  -- �e�[�u���^
  gt_item_def_data          g_tab_item_def_data;    -- ���ڃ`�F�b�N�p��`���
  gt_ins_data               g_tab_ins_data;         -- �o�^���R�[�h�i�[�ϐ�
  gt_del_data               g_tab_del_data;         -- �폜���R�[�h�i�[�ϐ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_id                NUMBER;                 -- FILE_ID
  gv_format                 VARCHAR2(100);          -- �t�H�[�}�b�g�p�^�[��
  gd_process_date           DATE;                   -- �Ɩ����t
  gn_item_num               NUMBER;                 -- �ύX�\����ꊇ�o�^�f�[�^���ڐ�
  gn_org_id                 NUMBER;                 -- �݌ɑg�DID
  gd_period_s_date          DATE;                   -- �݌ɉ�v���ԊJ�n��
--
  -- �J�E���^����p
  gn_ins_cnt                NUMBER;                 -- �o�^�p�J�E���^
  gn_del_cnt                NUMBER;                 -- �폜�p�J�E���^
--
  -- �G���[����p
  gv_a2_check_sts           VARCHAR2(1);            -- A-2�G���[�`�F�b�N�p
  gv_a4_check_sts           VARCHAR2(1);            -- A-4�G���[�`�F�b�N�p
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �ύX�\����ꎞ�\�擾
  CURSOR get_tmp_data_cur
  IS
    SELECT xticp.file_id                  AS file_id                -- �t�@�C��ID
          ,xticp.line_no                  AS line_no                -- �s�ԍ�
          ,xticp.item_code                AS item_code              -- �i�ڃR�[�h
          ,xticp.apply_date               AS apply_date             -- �K�p��
          ,xticp.old_item_status          AS old_item_status        -- ���i�ڃX�e�[�^�X
          ,xticp.new_item_status          AS new_item_status        -- �V�i�ڃX�e�[�^�X
          ,xticp.discrete_cost            AS discrete_cost          -- �c�ƌ���
          ,xticp.policy_group             AS policy_group           -- ����Q
          ,xticp.status                   AS status                 -- �o�^�X�e�[�^�X
          ,xticp.item_id                  AS item_id                -- �i��ID
          ,xticp.parent_item_id           AS parent_item_id         -- �e�i��ID
          ,xticp.inventory_item_id        AS inventory_item_id      -- Disc�i��ID
          ,xticp.parent_item_flag         AS parent_item_flag       -- �e�i�ڃt���O
    FROM   xxcmm_tmp_item_chg_upload   xticp     -- �ύX�\����ꎞ�\
    WHERE  xticp.file_id   =  gn_file_id
    ORDER BY
           xticp.line_no
    ;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id            IN  VARCHAR2          -- �t�@�C��ID
   ,iv_format_pattern     IN  VARCHAR2          -- �t�H�[�}�b�g�p�^�[��
   ,ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn_value              VARCHAR2(100);                                    -- �g�[�N���l
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM
    ln_cnt                    NUMBER;                                           -- �J�E���^
    lv_upload_obj             VARCHAR2(100);                                    -- �t�@�C���A�b�v���[�h����
    -- �t�@�C���A�b�v���[�hIF�e�[�u������
    lt_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- �t�@�C�����i�[�p
    -- IN�p�����[�^�o�͗p
    lv_up_name                VARCHAR2(1000);                                   -- �A�b�v���[�h����
    lv_file_name              VARCHAR2(1000);                                   -- �t�@�C����
    lv_file_id                VARCHAR2(1000);                                   -- �t�@�C��ID
    lv_file_format            VARCHAR2(1000);                                   -- �t�H�[�}�b�g
    --
    lv_org_code               VARCHAR2(100);                                    -- �݌ɑg�D�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���ڃ`�F�b�N�p��`���擾�J�[�\��
    CURSOR get_item_def_cur
    IS
      SELECT flv.meaning                         AS item_name                 -- ���ږ�
            ,DECODE(flv.attribute1
                  , cv_varchar ,cv_varchar_cd
                  , cv_number  ,cv_number_cd
                  , cv_date_cd
             )                                   AS item_attribute            -- ���ڑ���
            ,DECODE(flv.attribute2
                  , cv_not_null, cv_null_ng
                  , cv_null_ok
             )                                   AS item_essential            -- �K�{�t���O
            ,TO_NUMBER(flv.attribute3)           AS int_length                -- ���ڂ̒���(��������)
            ,TO_NUMBER(flv.attribute4)           AS dec_length                -- ���ڂ̒���(�����_�ȉ�)
      FROM   fnd_lookup_values_vl  flv
      WHERE  flv.lookup_type  = cv_lookup_item_def
      AND    flv.enabled_flag = cv_yes
      AND    gd_process_date
               BETWEEN NVL(flv.start_date_active ,gd_process_date)
                   AND NVL(flv.end_date_active   ,gd_process_date)
      ORDER BY
             flv.lookup_code
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �p�����[�^���O���[�o���ϐ��Ɋi�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format_pattern;
--
    -- ===============================
    -- �Ɩ����t�擾
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00018            -- ���b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    -- �ύX�\����ꊇ�o�^�f�[�^���ڐ�
    gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num));
    -- �擾�l��NULL�̏ꍇ
    IF ( gn_item_num IS NULL ) THEN
      -- �v���t�@�C���擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prf_item_num               -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �݌ɑg�D�R�[�h
    lv_org_code := FND_PROFILE.VALUE(cv_prf_org_code);
    -- �擾�l��NULL�̏ꍇ
    IF ( lv_org_code IS NULL ) THEN
      -- �v���t�@�C���擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prf_org_code               -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- ���ڃ`�F�b�N�p��`���擾
    -- ===============================
    -- �J�E���^�[������
    ln_cnt := 0;
    -- ���ڃ`�F�b�N�p��`���擾LOOP
    <<item_def_loop>>
    FOR get_item_def_rec IN get_item_def_cur LOOP
      ln_cnt := ln_cnt + 1;
      gt_item_def_data(ln_cnt).item_name      := get_item_def_rec.item_name;       -- ���ږ�
      gt_item_def_data(ln_cnt).item_attribute := get_item_def_rec.item_attribute;  -- ���ڑ���
      gt_item_def_data(ln_cnt).item_essential := get_item_def_rec.item_essential;  -- �K�{�t���O
      gt_item_def_data(ln_cnt).int_length     := get_item_def_rec.int_length;      -- ���ڂ̒���(��������)
      gt_item_def_data(ln_cnt).dec_length     := get_item_def_rec.dec_length;      -- ���ڂ̒���(�����_�ȉ�)
    END LOOP item_def_loop
    ;
    -- ������0���̏ꍇ
    IF ( ln_cnt = 0 ) THEN
      -- �擾���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10429            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_msg_xxcmm_10452            -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���A�b�v���[�h���̎擾
    -- ===============================
    BEGIN
      SELECT flv.meaning      AS upload_obj
      INTO   lv_upload_obj
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type  = cv_lookup_file_up_obj
      AND    flv.lookup_code  = gv_format
      AND    flv.enabled_flag = cv_yes
      AND    gd_process_date
               BETWEEN NVL(flv.start_date_active ,gd_process_date)
                   AND NVL(flv.end_date_active   ,gd_process_date)
      ;
    EXCEPTION
      -- �擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �擾���s�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10429            -- ���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_msg_xxcmm_10453            -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END;
--
    -- ===============================
    -- CSV�t�@�C�����擾
    -- ===============================
    SELECT fui.file_name      AS csv_file_name
    INTO   lt_csv_file_name
    FROM   xxccp_mrp_file_ul_interface  fui      -- �t�@�C���A�b�v���[�hI/F�\
    WHERE  fui.file_id           = gn_file_id    -- �t�@�C��ID
    AND    fui.file_content_type = gv_format     -- �t�@�C���t�H�[�}�b�g
    FOR UPDATE NOWAIT
    ;
--
    -- ===============================
    -- �݌ɑg�DID�擾
    -- ===============================
    BEGIN
      SELECT mp.organization_id   AS org_id
      INTO   gn_org_id
      FROM   mtl_parameters       mp
      WHERE  mp.organization_code = lv_org_code  -- �݌ɑg�D�R�[�h
      ;
    EXCEPTION
      -- �擾�ł��Ȃ��ꍇ
      WHEN NO_DATA_FOUND THEN
        -- �g�DID�擾�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00015            -- ���b�Z�[�W
                      ,iv_token_name1  => cv_tkn_ng_ou_name             -- �g�[�N���R�[�h1
                      ,iv_token_value1 => lv_org_code                   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �݌ɉ�v���ԊJ�n���擾
    -- ===============================
    SELECT MIN( oap.period_start_date )   AS period_s_date
    INTO   gd_period_s_date
    FROM   org_acct_periods   oap
    WHERE  oap.organization_id = gn_org_id  -- �݌ɑg�DID
    AND    oap.open_flag       = cv_open    -- �I�[�v��
    ;
    -- �擾�ł��Ȃ��ꍇ
    IF ( gd_period_s_date IS NULL ) THEN
      -- �擾���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10429            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_msg_xxcmm_10454            -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �p�����[�^�o��
    -- ===============================
    -- �t�@�C���A�b�v���[�h����
    lv_up_name     := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00021            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_up_name                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_upload_obj                 -- �g�[�N���l1
                      );
    -- CSV�t�@�C����
    lv_file_name   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00022            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_name              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lt_csv_file_name              -- �g�[�N���l1
                      );
    -- �t�@�C��ID
    lv_file_id     := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00023            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)           -- �g�[�N���l1
                      );
    -- �t�H�[�}�b�g�p�^�[��
    lv_file_format := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00024             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_format             -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format                      -- �g�[�N���l1
                      );
    -- �o�͂ɕ\��
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
    );
    -- ���O�ɕ\��
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
    );
--
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- IF���b�N�擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00402            -- ���b�Z�[�W
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : validate_data
   * Description      : �Ó����`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE validate_data(
    i_tmp_date_rec     IN  get_tmp_data_cur%ROWTYPE       -- �ύX�\����ꎞ�\���
   ,ov_errbuf          OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  -- # �Œ� #
   ,ov_retcode         OUT VARCHAR2     --   ���^�[���E�R�[�h                    -- # �Œ� #
   ,ov_errmsg          OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_data'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_check_status           VARCHAR2(1);            -- �X�e�[�^�X
    --
    lt_item_hst_id            xxcmm_system_items_b_hst.item_hst_id%TYPE;        -- �i�ڕύX����ID
    lt_apply_flag             xxcmm_system_items_b_hst.apply_flag%TYPE;         -- �K�p�L��
    lt_first_apply_flag       xxcmm_system_items_b_hst.first_apply_flag%TYPE;   -- ����K�p�t���O
    ln_standard_cost          NUMBER;                                           -- �W������
    ln_chk_cnt                NUMBER;                                           -- �`�F�b�N�p����
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
    -- ���[�J���ϐ��̏�����
    lv_check_status := cv_status_normal;
--
    -- ===============================
    -- �K�{���ڃ`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�K�{���ڂ̂����ꂩ�ݒ肳��Ă��邩�`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status IS NULL )
      AND ( i_tmp_date_rec.discrete_cost IS NULL )
      AND ( i_tmp_date_rec.policy_group IS NULL ) THEN
      -- ���ږ����̓G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10461                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- �e�i�ڌp�����ړ��̓`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�u�q�i�ځv�̏ꍇ�A
    -- �e�i�ڌp�����ڂ����͂���Ă��Ȃ����`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.parent_item_flag = cv_no )
      AND ( ( i_tmp_date_rec.discrete_cost IS NOT NULL )
         OR ( i_tmp_date_rec.policy_group IS NOT NULL ) ) THEN
      -- �e�i�ڌp�����ړ��̓G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10462                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- �p�~�i�ڃ`�F�b�N
    -- ===============================
    -- �u�o�^�v���A���i�ڃX�e�[�^�X���u�c�v�A�V�i�ڃX�e�[�^�X�����ݒ�
    -- �܂��͐V�i�ڃX�e�[�^�X���u�c�v�̏ꍇ�A�c�ƌ��������͂���Ă��Ȃ����`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( ( ( i_tmp_date_rec.old_item_status = cn_itm_sts_no_use )  --�u�c�v
          AND ( i_tmp_date_rec.new_item_status IS NULL ) )
       OR   ( i_tmp_date_rec.new_item_status = cn_itm_sts_no_use ) )  --�u�c�v
      AND ( i_tmp_date_rec.discrete_cost IS NOT NULL ) THEN
      -- �p�~�i�ړ��̓G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10474                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- �ߋ����`�F�b�N
    -- ===============================
    -- �u�o�^�v�̏ꍇ�A�K�p�����Ɩ����t�łȂ����`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.apply_date < gd_process_date ) THEN
      -- �K�p���ߋ����G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10463                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- �d�����R�[�h�`�F�b�N(�ꎞ�\)
    -- ===============================
    -- �ꎞ�\���ɓ���i�ځA�K�p���Ń��R�[�h���d�����Ă��Ȃ����`�F�b�N
    SELECT COUNT(0)      AS chk_cnt
    INTO   ln_chk_cnt
    FROM   xxcmm_tmp_item_chg_upload  xticu
    WHERE  xticu.item_code   = i_tmp_date_rec.item_code
    AND    xticu.apply_date  = i_tmp_date_rec.apply_date
    AND    xticu.line_no    != i_tmp_date_rec.line_no
    AND    ROWNUM            = cn_1
    ;
    -- ������1���ȏ�̏ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- �i�ڏd���G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10464                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================================
    -- �Ώۃ��R�[�h�L���`�F�b�N
    -- ===============================================
    -- �u�o�^�v�̏ꍇ�A�������R�[�h�����݂��Ȃ����Ƃ��`�F�b�N
    -- �u�폜�v�̏ꍇ�A�������R�[�h�����݂��邱�Ƃ��`�F�b�N
    BEGIN
      SELECT xsibhv.item_hst_id         AS item_hst_id         -- �i�ڕύX����ID
            ,xsibhv.apply_flag          AS apply_flag          -- �K�p�L��
            ,xsibhv.first_apply_flag    AS first_apply_flag    -- ����K�p�t���O
      INTO   lt_item_hst_id
            ,lt_apply_flag
            ,lt_first_apply_flag
      FROM  (SELECT xsibh.item_hst_id         AS item_hst_id
                   ,xsibh.apply_flag          AS apply_flag
                   ,xsibh.first_apply_flag    AS first_apply_flag
                   ,ROW_NUMBER() OVER ( ORDER BY xsibh.item_hst_id DESC )
                                              AS num
             FROM   xxcmm_system_items_b_hst xsibh
             WHERE  xsibh.item_code   = i_tmp_date_rec.item_code
             AND    xsibh.apply_date  = i_tmp_date_rec.apply_date
            ) xsibhv
      WHERE  xsibhv.num               = cn_1
      ;
      -- ���R�[�h���擾�ł��āu�o�^�v�̏ꍇ�G���[
      IF ( i_tmp_date_rec.status = cv_ins ) THEN
        -- �Ώۃ��R�[�h���݃`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10465                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                    ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                    ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���R�[�h���擾�ł����u�폜�v�̏ꍇ�G���[
        IF ( i_tmp_date_rec.status = cv_del ) THEN
          -- �Ώۃ��R�[�h�񑶍݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_10466                                     -- ���b�Z�[�W
                      ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                      ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                      ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                      ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                      ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                      ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- �G���[�Z�b�g
          gv_a4_check_sts := cv_status_error;
          lv_check_status := cv_status_error;
        END IF;
    END;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X�p�~�`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�u�e�i�ځv���A�V�i�ڃX�e�[�^�X���u�c�v�̏ꍇ�A
    -- �R�t���q�i�ڂ̕i�ڃX�e�[�^�X���S�āu�c�v�ł��邩�`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.parent_item_flag = cv_yes )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_no_use ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_opmmtl_items_v  xoiv
      WHERE  xoiv.parent_item_id      = i_tmp_date_rec.parent_item_id
      AND    xoiv.item_id            != i_tmp_date_rec.parent_item_id
      AND    xoiv.item_status        != cn_itm_sts_no_use   -- �i�ڃX�e�[�^�X�u�c�v
      AND    xoiv.start_date_active  <= gd_process_date
      AND    xoiv.end_date_active    >= gd_process_date
      AND    ROWNUM                   = cn_1
      ;
      -- ������1���ȏ�̏ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- �i�ڃX�e�[�^�X�p�~�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10467                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X�q�i�ڃ`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�u�q�i�ځv���A���i�ڃX�e�[�^�X���u�c�v���A
    -- �V�i�ڃX�e�[�^�X���u�{�o�^�v�u�p�v�u�c�f�v�̏ꍇ�A
    -- �e�i�ڂ̕i�ڃX�e�[�^�X���u�c�v�łȂ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.parent_item_flag = cv_no )
      AND ( i_tmp_date_rec.old_item_status = cn_itm_sts_no_use )       -- �u�c�v
      AND ( i_tmp_date_rec.new_item_status IN ( cn_itm_sts_regist      -- �u�{�o�^�v
                                              , cn_itm_sts_no_sch      -- �u�p�v
                                              , cn_itm_sts_trn_only    -- �u�c�f�v
                                              ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_opmmtl_items_v  xoiv
      WHERE  xoiv.parent_item_id      = i_tmp_date_rec.parent_item_id
      AND    xoiv.item_id             = xoiv.parent_item_id
      AND    xoiv.item_status         = cn_itm_sts_no_use   -- �u�c�v
      AND    xoiv.start_date_active  <= gd_process_date
      AND    xoiv.end_date_active    >= gd_process_date
      AND    ROWNUM                   = cn_1
      ;
      -- ������1���ȏ�̏ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- �i�ڃX�e�[�^�X�q�i�ڃG���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10468                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X�t���[�`�F�b�N�P
    -- ===============================
    -- �u�o�^�v���A�V�i�ڃX�e�[�^�X���u�{�o�^�v�u�p�v�u�c�f�v�u�c�v�̏ꍇ�A
    -- �������Ɂu���̔ԁv�u���o�^�v�̃��R�[�h���Ȃ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status IN ( cn_itm_sts_regist      -- �u�{�o�^�v
                                              , cn_itm_sts_no_sch      -- �u�p�v
                                              , cn_itm_sts_trn_only    -- �u�c�f�v
                                              , cn_itm_sts_no_use      -- �u�c�v
                                              ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_item_chg_info_v  xiciv
      WHERE  xiciv.item_code     = i_tmp_date_rec.item_code
      AND    xiciv.apply_date    > i_tmp_date_rec.apply_date
      AND    xiciv.item_status   IN ( cn_itm_sts_pre_reg         -- �u���̔ԁv
                                    , cn_itm_sts_num_tmp         -- �u���o�^�v
                                    )
      AND    ROWNUM              = cn_1
      ;
      -- ������1���ȏ�̏ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- �i�ڃX�e�[�^�X�t���[�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10469                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X�t���[�`�F�b�N�Q
    -- ===============================
    -- �u�o�^�v���A�V�i�ڃX�e�[�^�X���u���o�^�v�̏ꍇ�A
    -- �ߋ����Ɂu�{�o�^�v�u�p�v�u�c�f�v�u�c�v�̃��R�[�h���Ȃ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_pre_reg )    -- �u���o�^�v
    THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   xxcmm_item_chg_info_v  xiciv
      WHERE  xiciv.item_code     = i_tmp_date_rec.item_code
      AND    xiciv.apply_date    < i_tmp_date_rec.apply_date
      AND    xiciv.item_status   IN ( cn_itm_sts_regist      -- �u�{�o�^�v
                                    , cn_itm_sts_no_sch      -- �u�p�v
                                    , cn_itm_sts_trn_only    -- �u�c�f�v
                                    , cn_itm_sts_no_use      -- �u�c�v
                                    )
      AND    ROWNUM              = cn_1
      ;
      -- ������1���ȏ�̏ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- �i�ڃX�e�[�^�X�t���[�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10469                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X�K�p���`�F�b�N
    -- ===============================
    -- �u�o�^�v���A���i�ڃX�e�[�^�X���u�c�v�ȊO���A�V�i�ڃX�e�[�^�X���u�c�f�v�A
    -- �܂��́A�V�i�ڃX�e�[�^�X���u�c�f�v�̏ꍇ�A
    -- �K�p�����Ɩ����t�łȂ����Ƃ��`�F�b�N
    IF ( ( ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.old_item_status != cn_itm_sts_no_use )
      AND ( i_tmp_date_rec.new_item_status  = cn_itm_sts_trn_only ) )
      OR  ( i_tmp_date_rec.new_item_status  = cn_itm_sts_no_use ) ) THEN
      -- �K�p�����Ɩ����t�̏ꍇ
      IF  ( i_tmp_date_rec.apply_date = gd_process_date ) THEN
        -- �i�ڃX�e�[�^�X�K�p���G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10470                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- ������݃`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�V�i�ڃX�e�[�^�X���u�c�v�̏ꍇ�A
    -- OPEN�݌ɉ�v���ԓ��Ɏ�����쐬����Ă��Ȃ����Ƃ��`�F�b�N
    IF  ( ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status  = cn_itm_sts_no_use ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   mtl_material_transactions mmt  -- ���ގ��
      WHERE  mmt.inventory_item_id  = i_tmp_date_rec.inventory_item_id
      AND    mmt.organization_id    = gn_org_id
      AND    mmt.transaction_date  >= gd_period_s_date
      AND    mmt.transaction_date  <  i_tmp_date_rec.apply_date + 1
      AND    ROWNUM                 = cn_1
      ;
      -- ������1���ȏ�̏ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- �i�ڃX�e�[�^�X����쐬�σG���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10471                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- ���_�݌ɑ��݃`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�V�i�ڃX�e�[�^�X���u�c�v�̏ꍇ�A
    -- ���_�ɍ݌ɂ����݂��Ȃ����Ƃ��`�F�b�N
    IF  ( ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status  = cn_itm_sts_no_use ) ) THEN
      --
      SELECT COUNT(0)      AS chk_cnt
      INTO   ln_chk_cnt
      FROM   mtl_onhand_quantities moq  -- �莝�݌�
      WHERE  moq.inventory_item_id     = i_tmp_date_rec.inventory_item_id
      AND    moq.organization_id       = gn_org_id
      AND    moq.transaction_quantity != cn_0
      AND    ROWNUM                    = cn_1
      ;
      -- ������1���ȏ�̏ꍇ
      IF ( ln_chk_cnt > 0 ) THEN
        -- �i�ڃX�e�[�^�X���_�݌ɑ��݃G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          =>  cv_msg_xxcmm_10472                                     -- ���b�Z�[�W
                    ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                    ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                    ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                    ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        -- �G���[�Z�b�g
        gv_a4_check_sts := cv_status_error;
        lv_check_status := cv_status_error;
      END IF;
    END IF;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X�߂��`�F�b�N
    -- ===============================
    -- �u�o�^�v���A���i�ڃX�e�[�^�X���u�{�o�^�v�u�p�v�u�c�f�v�u�c�v�̏ꍇ�A
    -- �V�i�ڃX�e�[�^�X���u���o�^�v�łȂ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.old_item_status IN ( cn_itm_sts_regist      -- �u�{�o�^�v
                                              , cn_itm_sts_no_sch      -- �u�p�v
                                              , cn_itm_sts_trn_only    -- �u�c�f�v
                                              , cn_itm_sts_no_use      -- �u�c�v
                                              ) )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_pre_reg )      -- �u���o�^�v
    THEN
      -- �i�ڃX�e�[�^�X�߂��G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10473                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- �i�ڃX�e�[�^�X���̔ԓo�^�`�F�b�N
    -- ===============================
    -- �u�o�^�v�̏ꍇ�A�V�i�ڃX�e�[�^�X���u���̔ԁv�łȂ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.new_item_status = cn_itm_sts_num_tmp )    -- �u���̔ԁv
    THEN
      -- �i�ڃX�e�[�^�X���̔ԓo�^�G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10475                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- �W�������`�F�b�N
    -- ===============================
    -- �u�o�^�v���A�c�ƌ������ݒ肳��Ă���ꍇ�A
    -- �K�p�����_�̕W���������o�^����Ă��邱�Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_ins )
      AND ( i_tmp_date_rec.discrete_cost IS NOT NULL ) THEN
      BEGIN
        SELECT SUM(ccd.cmpnt_cost)  AS standard_cost
        INTO   ln_standard_cost
        FROM   cm_cmpt_dtl  ccd    -- OPM����
              ,cm_cldr_dtl  ccc    -- OPM�����J�����_
        WHERE  ccd.calendar_code  = ccc.calendar_code
        AND    ccd.period_code    = ccc.period_code
        AND    ccc.start_date    <= i_tmp_date_rec.apply_date
        AND    ccc.end_date      >= i_tmp_date_rec.apply_date
        AND    ccd.item_id        = i_tmp_date_rec.item_id
        GROUP BY
               ccd.item_id
              ,ccd.calendar_code
              ,ccd.period_code
        ;
      EXCEPTION
        -- �擾�ł��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          -- �W���������o�^�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_10476                                     -- ���b�Z�[�W
                      ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                      ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                      ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                      ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                      ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                      ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- �G���[�Z�b�g
          gv_a4_check_sts := cv_status_error;
          lv_check_status := cv_status_error;
      END;
    END IF;
--
    -- ===============================
    -- �K�p�ς݃��R�[�h�폜�`�F�b�N
    -- ===============================
    -- �u�폜�v�̏ꍇ�A�K�p�L�����u�K�p�ς݁v�łȂ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_del )
      AND ( lt_apply_flag = cv_flag_yes )    -- �u�K�p�ς݁v
    THEN
      -- �K�p�ς݃��R�[�h�폜�G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10477                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- ����ύX�\�񃌃R�[�h�폜�`�F�b�N
    -- ===============================
    -- �u�폜�v�̏ꍇ�A����K�p�t���O���u����K�p�v�łȂ����Ƃ��`�F�b�N
    IF ( i_tmp_date_rec.status = cv_del )
      AND ( lt_first_apply_flag = cv_flag_yes )    -- �u����K�p�v
    THEN
      -- ����ύX�\�񃌃R�[�h�폜�G���[
      gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   =>  cv_appl_name_xxcmm                                     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          =>  cv_msg_xxcmm_10478                                     -- ���b�Z�[�W
                  ,iv_token_name1   =>  cv_tkn_item_code                                       -- �g�[�N���R�[�h1
                  ,iv_token_value1  =>  i_tmp_date_rec.item_code                               -- �g�[�N���l1
                  ,iv_token_name2   =>  cv_tkn_apply_date                                      -- �g�[�N���R�[�h2
                  ,iv_token_value2  =>  TO_CHAR( i_tmp_date_rec.apply_date ,cv_date_fmt_std )  -- �g�[�N���l2
                  ,iv_token_name3   =>  cv_tkn_input_line_no                                   -- �g�[�N���R�[�h3
                  ,iv_token_value3  =>  TO_CHAR( i_tmp_date_rec.line_no )                      -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �G���[�Z�b�g
      gv_a4_check_sts := cv_status_error;
      lv_check_status := cv_status_error;
    END IF;
--
    -- ===============================
    -- ���R�[�h�i�[
    -- ===============================
    -- �Ó����`�F�b�NOK�̏ꍇ
    IF ( lv_check_status = cv_status_normal ) THEN
      -- �u�o�^�v�̏ꍇ
      IF ( i_tmp_date_rec.status = cv_ins ) THEN
        gn_ins_cnt                             := gn_ins_cnt + 1;
        gt_ins_data(gn_ins_cnt).item_id        := i_tmp_date_rec.item_id;            -- �i��ID
        gt_ins_data(gn_ins_cnt).item_code      := i_tmp_date_rec.item_code;          -- �i�ڃR�[�h
        gt_ins_data(gn_ins_cnt).apply_date     := i_tmp_date_rec.apply_date;         -- �K�p��
        gt_ins_data(gn_ins_cnt).item_status    := i_tmp_date_rec.new_item_status;    -- �i�ڃX�e�[�^�X
        gt_ins_data(gn_ins_cnt).policy_group   := i_tmp_date_rec.policy_group;       -- ����Q
        gt_ins_data(gn_ins_cnt).discrete_cost  := i_tmp_date_rec.discrete_cost;      -- �c�ƌ���
        gt_ins_data(gn_ins_cnt).line_no        := i_tmp_date_rec.line_no;            -- �s�ԍ�
--
      -- �u�폜�v�̏ꍇ
      ELSE
        gn_del_cnt                             := gn_del_cnt + 1;
        gt_del_data(gn_del_cnt).item_hst_id    := lt_item_hst_id;                    -- �i�ڕύX����ID
        gt_del_data(gn_del_cnt).item_code      := i_tmp_date_rec.item_code;          -- �i�ڃR�[�h
        gt_del_data(gn_del_cnt).apply_date     := i_tmp_date_rec.apply_date;         -- �K�p��
        gt_del_data(gn_del_cnt).line_no        := i_tmp_date_rec.line_no;            -- �s�ԍ�
      END IF;
    END IF;
--
    -- �Ó����`�F�b�N���ʂ��Z�b�g
    ov_retcode := lv_check_status;
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
  END validate_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_item_chg_data
   * Description      : �ύX�\����o�^����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_item_chg_data(
    ov_errbuf          OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  -- # �Œ� #
   ,ov_retcode         OUT VARCHAR2     --   ���^�[���E�R�[�h                    -- # �Œ� #
   ,ov_errmsg          OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_item_chg_data'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_check_status           VARCHAR2(1);            -- �X�e�[�^�X
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
    -- ���[�J���ϐ��̏�����
    lv_check_status := cv_status_normal;
--
    <<ins_data_loop>>
    FOR ln_cnt IN 1..gt_ins_data.COUNT LOOP
      BEGIN
        -- ===============================
        -- �ύX�\����o�^
        -- ===============================
        INSERT INTO xxcmm_system_items_b_hst(
          item_hst_id
         ,item_id
         ,item_code
         ,apply_date
         ,apply_flag
         ,item_status
         ,policy_group
         ,fixed_price
         ,discrete_cost
         ,first_apply_flag
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
        ) VALUES (
          xxcmm_system_items_b_hst_s.NEXTVAL     -- �i�ڕύX����ID
         ,gt_ins_data(ln_cnt).item_id            -- �i��ID
         ,gt_ins_data(ln_cnt).item_code          -- �i�ڃR�[�h
         ,gt_ins_data(ln_cnt).apply_date         -- �K�p��(�K�p�J�n��)
         ,cv_flag_no                             -- �K�p�L��
         ,gt_ins_data(ln_cnt).item_status        -- �i�ڃX�e�[�^�X
         ,gt_ins_data(ln_cnt).policy_group       -- �Q�R�[�h(����Q�R�[�h)
         ,NULL                                   -- �艿
         ,gt_ins_data(ln_cnt).discrete_cost      -- �c�ƌ���
         ,cv_flag_no                             -- ����K�p�t���O
         ,cn_created_by                          -- �쐬��
         ,cd_creation_date                       -- �쐬��
         ,cn_last_updated_by                     -- �ŏI�X�V��
         ,cd_last_update_date                    -- �ŏI�X�V��
         ,cn_last_update_login                   -- �ŏI�X�V���O�C��
         ,cn_request_id                          -- �v��ID
         ,cn_program_application_id              -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
         ,cn_program_id                          -- �R���J�����g�E�v���O����ID
         ,cd_program_update_date                 -- �v���O�����ɂ��X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�o�^�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxcmm_00407                        -- ���b�Z�[�W
                       ,iv_token_name1   =>  cv_tkn_table                              -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxcmm_10460                        -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no                      -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  TO_CHAR( ln_cnt )                         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_input_item_code                    -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_ins_data(ln_cnt).item_code             -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_err_msg                            -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  SQLERRM                                   -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END LOOP ins_data_loop;
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
  END ins_item_chg_data;
--
  /**********************************************************************************
   * Procedure Name   : del_item_chg_data
   * Description      : �ύX�\����폜����(A-6)
   ***********************************************************************************/
  PROCEDURE del_item_chg_data(
    ov_errbuf          OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  -- # �Œ� #
   ,ov_retcode         OUT VARCHAR2     --   ���^�[���E�R�[�h                    -- # �Œ� #
   ,ov_errmsg          OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_item_chg_data'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_check_status           VARCHAR2(1);                                    -- �X�e�[�^�X
    lt_item_hst_id            xxcmm_system_items_b_hst.item_hst_id%TYPE;      -- �i�ڕύX����ID
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
    -- ���[�J���ϐ��̏�����
    lv_check_status := cv_status_normal;
--
    <<del_data_loop>>
    FOR ln_cnt IN 1..gt_del_data.COUNT LOOP
      -- ===============================
      -- �Ώۃ��R�[�h���b�N
      -- ===============================
      SELECT xsibh.item_hst_id      AS item_hst_id
      INTO   lt_item_hst_id
      FROM   xxcmm_system_items_b_hst  xsibh
      WHERE  xsibh.item_hst_id = gt_del_data(ln_cnt).item_hst_id   -- �i�ڕύX����ID
      FOR UPDATE NOWAIT
      ;
--
      -- ===============================
      -- �ύX�\����폜
      -- ===============================
      BEGIN
        DELETE FROM  xxcmm_system_items_b_hst  xsibh
        WHERE  xsibh.item_hst_id = lt_item_hst_id   -- �i�ڕύX����ID
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �f�[�^�폜�G���[
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                       ,iv_name          =>  cv_msg_xxcmm_10479                        -- ���b�Z�[�W
                       ,iv_token_name1   =>  cv_tkn_table                              -- �g�[�N���R�[�h1
                       ,iv_token_value1  =>  cv_msg_xxcmm_10460                        -- �g�[�N���l1
                       ,iv_token_name2   =>  cv_tkn_input_line_no                      -- �g�[�N���R�[�h2
                       ,iv_token_value2  =>  TO_CHAR( ln_cnt )                         -- �g�[�N���l2
                       ,iv_token_name3   =>  cv_tkn_input_item_code                    -- �g�[�N���R�[�h3
                       ,iv_token_value3  =>  gt_del_data(ln_cnt).item_code             -- �g�[�N���l3
                       ,iv_token_name4   =>  cv_tkn_err_msg                            -- �g�[�N���R�[�h4
                       ,iv_token_value4  =>  SQLERRM                                   -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
    END LOOP del_data_loop;
--
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                        -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00008                        -- ���b�Z�[�W
                   ,iv_token_name1   =>  cv_tkn_ng_table                           -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_msg_xxcmm_10460                        -- �g�[�N���l1
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END del_item_chg_data;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �ꎞ�\�擾����(A-3)�A�Ó����`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_check_status           VARCHAR2(1);                          -- �X�e�[�^�X
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lv_check_status := cv_status_normal;
--
    <<main_loop>>
    FOR get_tmp_data_rec IN get_tmp_data_cur LOOP
      -- ===============================
      -- �Ó����`�F�b�N����(A-4)
      -- ===============================
      validate_data(
        i_tmp_date_rec     => get_tmp_data_rec         -- �ύX�\����ꎞ�\���
       ,ov_errbuf          => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode         => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg          => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ���팏�����Z
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        -- �f�[�^�Ó����`�F�b�N�G���[�̏ꍇ�A�G���[�X�e�[�^�X�ޔ�
        lv_check_status := cv_status_error;
        -- �G���[�������Z
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
      --
    END LOOP main_loop;
--
    -- �Ó����`�F�b�N���ʂ��Z�b�g
    ov_retcode := gv_a4_check_sts;
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
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J�� ���[�U�[��`�^ ***
    TYPE l_check_data_ttype  IS TABLE OF VARCHAR2(4000)  INDEX BY BINARY_INTEGER;
--
    -- *** ���[�J���ϐ� ***
    lv_check_status           VARCHAR2(1);            -- �X�e�[�^�X
    ln_line_cnt               NUMBER;                 -- �s�J�E���^
    ln_column_cnt             NUMBER;                 -- ���ڐ��J�E���^
    ln_ins_cnt                NUMBER;                 -- �o�^�����J�E���^
    ln_item_num               NUMBER;                 -- ���ڐ�
    lv_tkn_value              VARCHAR2(100);          -- �g�[�N���l
    lv_tkn_err_msg            VARCHAR2(100);          -- �g�[�N���l
    --
    lt_item_status            xxcmm_opmmtl_items_v.item_status%TYPE;         -- �i�ڃX�e�[�^�X
    lt_item_id                xxcmm_opmmtl_items_v.item_id%TYPE;             -- �i��ID
    lt_parent_item_id         xxcmm_opmmtl_items_v.parent_item_id%TYPE;      -- �e�i��ID
    lt_inventory_item_id      xxcmm_opmmtl_items_v.inventory_item_id%TYPE;   -- Disc�i��ID
    lv_parent_item_flag       VARCHAR2(1);                                   -- �e�i�ڃt���O
    ln_chk_cnt                NUMBER;                                        -- �`�F�b�N�p����
    --
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      -- IF�e�[�u���擾�p
    l_wk_item_tab             l_check_data_ttype;                     -- �e�[�u���^�ϐ���錾(���ڕ���)
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --������
    ln_ins_cnt := 0;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�hI/F�\�f�[�^�擾
    -- ===============================================
    xxccp_common_pkg2.blob_to_varchar2(          -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id                 -- �t�@�C��ID
     ,ov_file_data => l_if_data_tab              -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================================
    -- LOOP START
    -- ��1�s�ڂ̓w�b�_���̂��߁A2�s�ڈȍ~���擾
    -- ===============================================
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 2..l_if_data_tab.COUNT LOOP
--
      -- �s�J�E���^
      ln_ins_cnt := ln_ins_cnt + 1;
--
      -- ���[�J���ϐ��̏�����
      lt_item_status        := NULL;   -- �i�ڃX�e�[�^�X
      lt_item_id            := NULL;   -- �i��ID
      lt_parent_item_id     := NULL;   -- �e�i��ID
      lt_inventory_item_id  := NULL;   -- Disc�i��ID
      lv_parent_item_flag   := NULL;   -- �e�i�ڃt���O
      --
      lv_check_status       := cv_status_normal;
--
      -- ===============================================
      -- ���ڐ��`�F�b�N
      -- ===============================================
      -- �f�[�^���ڐ����i�[
      ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt) )
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '') ) )
                   + 1 );
      -- ���ڐ�����v���Ȃ��ꍇ
      IF ( gn_item_num <> ln_item_num ) THEN
        -- �f�[�^���ڐ��G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00028            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_msg_xxcmm_10455            -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_count                  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => TO_CHAR(ln_item_num)          -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- CSV�����񕪊�
      -- ===============================================
--
      <<get_column_loop>>
      FOR ln_column_cnt IN 1..gn_item_num LOOP
--
        -- �ϐ��ɍ��ڂ̒l���i�[
        l_wk_item_tab(ln_column_cnt) := xxccp_common_pkg.char_delim_partition(        -- �f���~�^�����ϊ����ʊ֐�
                                          iv_char     => l_if_data_tab(ln_line_cnt)   -- ������������
                                         ,iv_delim    => cv_msg_comma                 -- �f���~�^
                                         ,in_part_num => ln_column_cnt                -- �擾�Ώۂ̍���Index
                                        );
--
        -- ===============================================
        -- ���ڃ`�F�b�N
        -- ===============================================
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gt_item_def_data(ln_column_cnt).item_name         -- ���ږ���
         ,iv_item_value   => l_wk_item_tab(ln_column_cnt)                      -- ���ڂ̒l
         ,in_item_len     => gt_item_def_data(ln_column_cnt).int_length        -- ���ڂ̒���(��������)
         ,in_item_decimal => gt_item_def_data(ln_column_cnt).dec_length        -- ���ڂ̒���(�����_�ȉ�)
         ,iv_item_nullflg => gt_item_def_data(ln_column_cnt).item_essential    -- �K�{�t���O
         ,iv_item_attr    => gt_item_def_data(ln_column_cnt).item_attribute    -- ���ڂ̑���
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
--
        -- ���ڃ`�F�b�N���ʂ�����ȊO�̏ꍇ
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- �t�@�C�����ڃ`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name          =>  cv_msg_xxcmm_00403          -- ���b�Z�[�W
                      ,iv_token_name1   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h1
                      ,iv_token_value1  =>  TO_CHAR( ln_ins_cnt )       -- �g�[�N���l1
                      ,iv_token_name2   =>  cv_tkn_err_msg              -- �g�[�N���R�[�h2
                      ,iv_token_value2  =>  LTRIM(lv_errmsg)            -- �g�[�N���l2
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- �G���[�Z�b�g
          gv_a2_check_sts := cv_status_error;
          lv_check_status := cv_status_error;
--
        ELSE
--
          -- ===============================================
          -- �i���R�[�h
          -- ===============================================
          IF ( ln_column_cnt = 1 ) THEN
            BEGIN
              SELECT xoiv.item_status          AS item_status          -- �i�ڃX�e�[�^�X
                    ,xoiv.item_id              AS item_id              -- �i��ID
                    ,xoiv.parent_item_id       AS parent_item_id       -- �e�i��ID
                    ,xoiv.inventory_item_id    AS inventory_item_id    -- Disc�i��ID
                    ,CASE WHEN xoiv.item_id = xoiv.parent_item_id THEN
                       cv_yes
                     ELSE
                       cv_no
                     END                       AS parent_item_flag     -- �e�i�ڃt���O
              INTO   lt_item_status
                    ,lt_item_id
                    ,lt_parent_item_id
                    ,lt_inventory_item_id
                    ,lv_parent_item_flag
              FROM   xxcmm_opmmtl_items_v xoiv
              WHERE  xoiv.start_date_active <= gd_process_date
              AND    xoiv.end_date_active   >= gd_process_date
              AND    xoiv.item_no            = l_wk_item_tab(1)  -- �i���R�[�h
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �l�`�F�b�N�G���[
                gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                            ,iv_name          =>  cv_msg_xxcmm_10328          -- ���b�Z�[�W
                            ,iv_token_name1   =>  cv_tkn_input                -- �g�[�N���R�[�h1
                            ,iv_token_value1  =>  cv_msg_xxcmm_10456          -- �g�[�N���l1
                            ,iv_token_name2   =>  cv_tkn_value                -- �g�[�N���R�[�h2
                            ,iv_token_value2  =>  l_wk_item_tab(1)            -- �g�[�N���l2
                            ,iv_token_name3   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                            ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- �g�[�N���l3
                             );
                -- ���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => gv_out_msg
                );
                -- �G���[�Z�b�g
                gv_a2_check_sts := cv_status_error;
                lv_check_status := cv_status_error;
            END;
          END IF;
--
          -- ===============================================
          -- �i�ڃX�e�[�^�X
          -- ===============================================
          IF ( ln_column_cnt = 3 )
            AND ( l_wk_item_tab(3) IS NOT NULL ) THEN
            SELECT COUNT(0)   AS chk_cnt
            INTO   ln_chk_cnt
            FROM   fnd_lookup_values_vl flvv
            WHERE  flvv.lookup_type  = cv_lookup_item_status
            AND    flvv.lookup_code  = l_wk_item_tab(3)        -- �i�ڃX�e�[�^�X
            ;
            IF ( ln_chk_cnt = 0 ) THEN
              -- �Q�ƃR�[�h���݃`�F�b�N�G���[
              gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_10330          -- ���b�Z�[�W
                          ,iv_token_name1   =>  cv_tkn_input                -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  cv_msg_xxcmm_10457          -- �g�[�N���l1
                          ,iv_token_name2   =>  cv_tkn_value                -- �g�[�N���R�[�h2
                          ,iv_token_value2  =>  l_wk_item_tab(3)            -- �g�[�N���l2
                          ,iv_token_name3   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                          ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- �g�[�N���l3
                           );
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => gv_out_msg
              );
              -- �G���[�Z�b�g
              gv_a2_check_sts := cv_status_error;
              lv_check_status := cv_status_error;
            END IF;
          END IF;
--
          -- ===============================================
          -- ����Q
          -- ===============================================
          IF ( ln_column_cnt = 5 )
            AND ( l_wk_item_tab(5) IS NOT NULL ) THEN
            SELECT COUNT(0)   AS chk_cnt
            INTO   ln_chk_cnt
            FROM   mtl_categories_vl      mcv
                  ,mtl_category_sets_vl   mcsv
            WHERE  mcv.structure_id        = mcsv.structure_id
            AND    mcsv.category_set_name  = cv_ctg_set_seisakugun  -- �J�e�S���Z�b�g���i����Q�R�[�h�j
            AND    mcv.enabled_flag        = cv_yes
            AND    mcv.segment1            NOT LIKE cv_wildcard
            AND    mcv.segment1            = l_wk_item_tab(5)   -- ����Q
            ;
            IF ( ln_chk_cnt = 0 ) THEN
              -- �l�`�F�b�N�G���[
              gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                          ,iv_name          =>  cv_msg_xxcmm_10328          -- ���b�Z�[�W
                          ,iv_token_name1   =>  cv_tkn_input                -- �g�[�N���R�[�h1
                          ,iv_token_value1  =>  cv_ctg_set_seisakugun       -- �g�[�N���l1
                          ,iv_token_name2   =>  cv_tkn_value                -- �g�[�N���R�[�h2
                          ,iv_token_value2  =>  l_wk_item_tab(5)            -- �g�[�N���l2
                          ,iv_token_name3   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                          ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- �g�[�N���l3
                           );
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => gv_out_msg
              );
              -- �G���[�Z�b�g
              gv_a2_check_sts := cv_status_error;
              lv_check_status := cv_status_error;
            END IF;
          END IF;
--
          -- ===============================================
          -- �o�^�X�e�[�^�X
          -- ===============================================
          IF ( ln_column_cnt = 6 )
            AND ( l_wk_item_tab(6) NOT IN ( cv_ins , cv_del ) ) THEN
            -- �l�`�F�b�N�G���[
            gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_10328          -- ���b�Z�[�W
                        ,iv_token_name1   =>  cv_tkn_input                -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  cv_msg_xxcmm_10458          -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_value                -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  l_wk_item_tab(6)            -- �g�[�N���l2
                        ,iv_token_name3   =>  cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                        ,iv_token_value3  =>  TO_CHAR( ln_ins_cnt )       -- �g�[�N���l3
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg
            );
            -- �G���[�Z�b�g
            gv_a2_check_sts := cv_status_error;
            lv_check_status := cv_status_error;
          END IF;
        END IF;
      END LOOP get_column_loop;
--
      -- ===============================================
      -- �ύX�\����ꎞ�\�o�^
      -- ===============================================
      IF ( lv_check_status = cv_status_normal ) THEN
        BEGIN
          INSERT INTO xxcmm_tmp_item_chg_upload(
             file_id                   -- �t�@�C��ID
            ,line_no                   -- �s�ԍ�
            ,item_code                 -- �i�ڃR�[�h
            ,apply_date                -- �K�p��
            ,old_item_status           -- ���i�ڃX�e�[�^�X
            ,new_item_status           -- �V�i�ڃX�e�[�^�X
            ,discrete_cost             -- �c�ƌ���
            ,policy_group              -- ����Q
            ,status                    -- �o�^�X�e�[�^�X
            ,item_id                   -- �i��ID
            ,parent_item_id            -- �e�i��ID
            ,inventory_item_id         -- Disc�i��ID
            ,parent_item_flag          -- �e�i�ڃt���O
          ) VALUES (
             gn_file_id                                    -- �t�@�C��ID
            ,ln_ins_cnt                                    -- �t�@�C��SEQ
            ,l_wk_item_tab(1)                              -- �i�ڃR�[�h
            ,TO_DATE(l_wk_item_tab(2) ,cv_date_fmt_std)    -- �K�p��
            ,lt_item_status                                -- ���i�ڃX�e�[�^�X
            ,l_wk_item_tab(3)                              -- �V�i�ڃX�e�[�^�X
            ,l_wk_item_tab(4)                              -- �c�ƌ���
            ,l_wk_item_tab(5)                              -- ����Q
            ,l_wk_item_tab(6)                              -- �o�^�X�e�[�^�X
            ,lt_item_id                                    -- �i��ID
            ,lt_parent_item_id                             -- �e�i��ID
            ,lt_inventory_item_id                          -- Disc�i��ID
            ,lv_parent_item_flag                           -- �e�i�ڃt���O
          );
        EXCEPTION
          -- *** �f�[�^�o�^��O�n���h�� ***
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                 -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_00407                 -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table                       -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_msg_xxcmm_10459                 -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_line_no               -- �g�[�N���R�[�h2
                          ,iv_token_value2 => TO_CHAR( ln_ins_cnt )              -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_input_item_code             -- �g�[�N���R�[�h3
                          ,iv_token_value3 => l_wk_item_tab(1)                   -- �g�[�N���l3
                          ,iv_token_name4  => cv_tkn_err_msg                     -- �g�[�N���R�[�h4
                          ,iv_token_value4 => SQLERRM                            -- �g�[�N���l4
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP ins_wk_loop;
--
    -- ===============================================
    -- LOOP END
    -- ===============================================
--
    -- �����Ώی������i�[(�w�b�_����������)
    gn_target_cnt := l_if_data_tab.COUNT - 1 ;
--
    -- �߂�l�X�V
    ov_retcode := gv_a2_check_sts;
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
   * Procedure Name   : del_if_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�폜����(A-7)
   ***********************************************************************************/
  PROCEDURE del_if_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�hI/F�\�f�[�^�폜
    -- ===============================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfi
      WHERE  xmfi.file_id = gn_file_id
      ;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        -- IF�f�[�^�폜�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm      -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10481      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_err_msg          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => SQLERRM                 -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END del_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id            IN  VARCHAR2      -- 1.�t�@�C��ID
   ,iv_format_pattern     IN  VARCHAR2      -- 2.�t�H�[�}�b�g�p�^�[��
   ,ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J�����[�U�[��`��O ***
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
    gn_ins_cnt    := 0;  -- �o�^�p�J�E���^
    gn_del_cnt    := 0;  -- �폜�p�J�E���^
--
    gv_a2_check_sts  := cv_status_normal;  -- A-2�G���[�`�F�b�N�p
    gv_a4_check_sts  := cv_status_normal;  -- A-4�G���[�`�F�b�N�p
--
    --===============================================
    -- ��������(A-1)
    --===============================================
    init(
      iv_file_id         => iv_file_id          -- �t�@�C��ID
     ,iv_format_pattern  => iv_format_pattern   -- �t�H�[�}�b�g�p�^�[��
     ,ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �����J�E���g
      gn_target_cnt := 0;  -- �Ώی���
      gn_error_cnt  := 1;  -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
    --===============================================
    get_if_data(                        -- get_if_data���R�[��
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �����J�E���g
      gn_target_cnt := 0;  -- �Ώی���
      gn_error_cnt  := 1;  -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- �ꎞ�\�擾����(A-3)�A�Ó����`�F�b�N����(A-4)
    --===============================================
    loop_main(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- �ύX�\����o�^����(A-5)
    --===============================================
    ins_item_chg_data(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �����J�E���g
      gn_target_cnt := 0;  -- �Ώی���
      gn_error_cnt  := 1;  -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- �ύX�\����폜����(A-6)
    --===============================================
    del_item_chg_data(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �����J�E���g
      gn_target_cnt := 0;  -- �Ώی���
      gn_error_cnt  := 1;  -- �G���[����
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
    errbuf                  OUT VARCHAR2      --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                 OUT VARCHAR2      --   ���^�[���E�R�[�h    --# �Œ� #
   ,iv_file_id              IN  VARCHAR2      --   �t�@�C��ID
   ,iv_format_pattern       IN  VARCHAR2      --   �t�H�[�}�b�g�p�^�[��
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
      iv_file_id            => iv_file_id               -- �t�@�C��ID
     ,iv_format_pattern     => iv_format_pattern        -- �t�H�[�}�b�g�p�^�[��
     ,ov_errbuf             => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --===============================================
    -- �I������(A-8)
    --===============================================
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
    END IF;
--
    --===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�폜����(A-7)
    --===============================================
    del_if_data(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      -- �����J�E���g
      gn_target_cnt := 0;  -- �Ώی���
      gn_normal_cnt := 0;  -- ��������
      gn_error_cnt  := 1;  -- �G���[����
      -- �G���[����ROLLBACK
      ROLLBACK;
    END IF;
--
    -- �t�@�C���A�b�v���[�h�f�[�^�폜���COMMIT
    COMMIT;
--
    -- �G���[�������0���ŕԂ��܂�
    IF ( gn_error_cnt > 0 ) THEN
--
      IF ( gv_a4_check_sts <> cv_status_error ) THEN
        -- �����J�E���g
        gn_target_cnt := 0;  -- �Ώی���
        gn_normal_cnt := 0;  -- ��������
        gn_error_cnt  := 1;  -- �G���[����
      END IF;
--
      gn_ins_cnt    := 0;  -- �ύX�\����o�^����
      gn_del_cnt    := 0;  -- �ύX�\����폜����
      --�X�e�[�^�X�Z�b�g
      lv_retcode := cv_status_error;
    END IF;
--
    -- ===============================
    -- �ύX�\���񏈗������o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm
                    ,iv_name         => cv_msg_xxcmm_10480
                    ,iv_token_name1  => cv_tkn_ins_count
                    ,iv_token_value1 => TO_CHAR(gn_ins_cnt)
                    ,iv_token_name2  => cv_tkn_del_count
                    ,iv_token_value2 => TO_CHAR(gn_del_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X������ȊO�̏ꍇ��ROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
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
END XXCMM004A13C;
/
