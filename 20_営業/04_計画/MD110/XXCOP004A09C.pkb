CREATE OR REPLACE PACKAGE BODY APPS.XXCOP004A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A09C(body)
 * Description      : �A�b�v���[�h�t�@�C������̓o�^�i����v��j
 * MD.050           : MD050_COP_004_A09_�A�b�v���[�h�t�@�C������̓o�^�i����v��j
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_file_upload_data   �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
 *  chk_validate_item      �Ó����`�F�b�N����(A-3)
 *  exec_api_forecast_if   ���v�\��API���s(A-5)
 *  del_file_upload_data   �t�@�C���A�b�v���[�h�f�[�^�폜����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/10/30    1.0   S.Niki           �V�K�쐬
 *  2014/04/03    1.1   N.Nakamura       E_�{�ғ�_11687�Ή�
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
  global_lock_expt          EXCEPTION;  -- ���b�N��O
  global_chk_item_expt      EXCEPTION;  -- �Ó����`�F�b�N��O
-- ********** Ver.1.1 K.Nakamura ADD Start ************ --
  global_no_insert_expt     EXCEPTION;  -- �o�^�ΏۊO��O
-- ********** Ver.1.1 K.Nakamura ADD End ************ --
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOP004A09C';     -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOP';            -- �A�v���P�[�V����:XXCOP
  cv_appl_xxcok               CONSTANT VARCHAR2(5)  := 'XXCOK';            -- �A�v���P�[�V����:XXCOK
  -- �v���t�@�C��
  cv_master_org_id            CONSTANT VARCHAR2(30) := 'XXCMN_MASTER_ORG_ID';          -- �}�X�^�g�DID
  cv_sales_org_code           CONSTANT VARCHAR2(30) := 'XXCOP1_SALES_ORG_CODE';        -- �c�Ƒg�D�R�[�h
  cv_whse_code_leaf           CONSTANT VARCHAR2(30) := 'XXCOP1_WHSE_CODE_LEAF';        -- �o�׌��q��_���[�t
  cv_whse_code_drink          CONSTANT VARCHAR2(30) := 'XXCOP1_WHSE_CODE_DRINK';       -- �o�׌��q��_�h�����N
  cv_arti_div_code            CONSTANT VARCHAR2(30) := 'XXCMN_ARTI_DIV_CODE';          -- �J�e�S���Z�b�g��(�{�Џ��i�敪)
  cv_product_div_code         CONSTANT VARCHAR2(30) := 'XXCMN_PRODUCT_DIV_CODE';       -- �J�e�S���Z�b�g��(���i���i�敪)
  cv_item_class               CONSTANT VARCHAR2(30) := 'XXCMN_ITEM_CLASS';             -- �J�e�S���Z�b�g��(�i�ڋ敪)
  cv_limit_forecast           CONSTANT VARCHAR2(30) := 'XXCOP1_LIMIT_FORECAST';        -- ����v����͐�������
  -- �N�C�b�N�R�[�h
  cv_file_upload_obj          CONSTANT VARCHAR2(30) := 'XXCCP1_FILE_UPLOAD_OBJ';       -- �t�@�C���A�b�v���[�h���
  cv_forecast_item            CONSTANT VARCHAR2(30) := 'XXCOP1_FORECAST_ITEM';         -- ����v��A�b�v���[�h���ڃ`�F�b�N
  cv_forecast_date            CONSTANT VARCHAR2(30) := 'XXCOP1_FORECAST_DATE';         -- �h�����N�֓��t
  -- ���b�Z�[�W
  cv_msg_xxcop_00032          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00032';   -- �A�b�v���[�hIF���擾�G���[���b�Z�[�W
  cv_msg_xxcop_00036          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00036';   -- �A�b�v���[�h�t�@�C���o�̓��b�Z�[�W
  cv_msg_xxcop_00065          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00065';   -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcop_00002          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00002';   -- �v���t�@�C���l�擾���s�G���[
  cv_msg_xxcop_00013          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00013';   -- �}�X�^�`�F�b�N�G���[
  cv_msg_xxcop_00006          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00006';   -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_xxcop_00007          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00007';   -- �e�[�u�����b�N�G���[���b�Z�[�W
  cv_msg_xxcop_00042          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00042';   -- �폜�����G���[���b�Z�[�W
  cv_msg_xxcok_00041          CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';   -- BLOB�f�[�^�ϊ��G���[���b�Z�[�W
  cv_msg_xxcop_00069          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00069';   -- �t�H�[�}�b�g�`�F�b�N�G���[
  cv_msg_xxcop_00070          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00070';   -- �s���`�F�b�N�G���[
  cv_msg_xxcop_00071          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00071';   -- DATE�^�`�F�b�N�G���[
  cv_msg_xxcop_00072          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00072';   -- �S�����_�`�F�b�N�G���[
  cv_msg_xxcop_00073          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00073';   -- �}�X�^���o�^�G���[
  cv_msg_xxcop_00074          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00074';   -- �s�����G���[
  cv_msg_xxcop_00076          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00076';   -- API�N���G���[
  cv_msg_xxcop_00077          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00077';   -- �͈͊O�G���[
  cv_msg_xxcop_00079          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00079';   -- �t�@�C���A�b�v���[�hIF�\�m�[�g
  cv_msg_xxcop_00080          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00080';   -- �g�D�R�[�h�m�[�g
  cv_msg_xxcop_00081          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00081';   -- �g�D�p�����[�^�m�[�g
  cv_msg_xxcop_00082          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00082';   -- �t�H�[�L���X�g�m�[�g
  cv_msg_xxcop_00084          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00084';   -- ���[�t�֕\�m�[�g
  cv_msg_xxcop_00085          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00085';   -- �N�C�b�N�R�[�h�m�[�g
  cv_msg_xxcop_00086          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00086';   -- OPM�ۊǏꏊ�}�X�^�m�[�g
  cv_msg_xxcop_00087          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00087';   -- �i�ڃ}�X�^�m�[�g
  cv_msg_xxcop_00088          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00088';   -- �o�׊Ǘ��敪�m�[�g
  cv_msg_xxcop_00089          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00089';   -- ���i�敪�m�[�g
  cv_msg_xxcop_00092          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00092';   -- �N���m�[�g
  cv_msg_xxcop_10058          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10058';   -- ����v��IF�\�m�[�g
  cv_msg_xxcop_10064          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10064';   -- ����v��f�[�^�͈͊O�G���[
  cv_msg_xxcop_10065          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10065';   -- �o�׌��q�Ɏ擾�G���[
  cv_msg_xxcop_10066          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10066';   -- �t�H�[�L���X�g���݃`�F�b�N�G���[
  cv_msg_xxcop_10068          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10068';   -- �։ғ����`�F�b�N�G���[
  cv_msg_xxcop_10069          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-10069';   -- �֏d���`�F�b�N�G���[
  cv_msg_xxcop_00027          CONSTANT VARCHAR2(16) := 'APP-XXCOP1-00027';   -- �o�^�����G���[���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_fileid               CONSTANT VARCHAR2(20) := 'FILEID';             -- �t�@�C��ID
  cv_tkn_file_id              CONSTANT VARCHAR2(20) := 'FILE_ID';            -- �t�@�C��ID�l
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';          -- �t�@�C����
  cv_tkn_format               CONSTANT VARCHAR2(20) := 'FORMAT';             -- �t�H�[�}�b�g�p�^�[��
  cv_tkn_format_ptn           CONSTANT VARCHAR2(20) := 'FORMAT_PTN';         -- �t�H�[�}�b�g�p�^�[���l
  cv_tkn_upload_object        CONSTANT VARCHAR2(20) := 'UPLOAD_OBJECT';      -- �t�@�C���A�b�v���[�h����
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROF_NAME';          -- �v���t�@�C��
  cv_tkn_row                  CONSTANT VARCHAR2(20) := 'ROW';                -- �s
  cv_tkn_file                 CONSTANT VARCHAR2(20) := 'FILE';               -- ����
  cv_tkn_item                 CONSTANT VARCHAR2(20) := 'ITEM';               -- ����
  cv_tkn_item1                CONSTANT VARCHAR2(20) := 'ITEM1';              -- ����1
  cv_tkn_item2                CONSTANT VARCHAR2(20) := 'ITEM2';              -- ����2
  cv_tkn_item3                CONSTANT VARCHAR2(20) := 'ITEM3';              -- ����3
  cv_tkn_value                CONSTANT VARCHAR2(20) := 'VALUE';              -- ���ڒl
  cv_tkn_value1               CONSTANT VARCHAR2(20) := 'VALUE1';             -- ���ڒl1
  cv_tkn_value2               CONSTANT VARCHAR2(20) := 'VALUE2';             -- ���ڒl2
  cv_tkn_value3               CONSTANT VARCHAR2(20) := 'VALUE3';             -- ���ڒl3
  cv_tkn_value4               CONSTANT VARCHAR2(20) := 'VALUE4';             -- ���ڒl4
  cv_tkn_value5               CONSTANT VARCHAR2(20) := 'VALUE5';             -- ���ڒl5
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';              -- �e�[�u����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';             -- �G���[���e�ڍ�
  cv_tkn_prg_name             CONSTANT VARCHAR2(20) := 'PRG_NAME';           -- �v���O������
  --
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                  -- �L��
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');
  -- ������
  cv_comma                    CONSTANT VARCHAR2(1)  := ',';                  -- ������؂�
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                  -- ��������
  -- ���t����
  cv_format_yyyymm            CONSTANT VARCHAR2(6)  := 'YYYYMM';             -- YYYYMM
  cv_format_yyyymmdd          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';           -- YYYYMMDD
  cv_format_std_yyyymmdd      CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';         -- YYYY/MM/DD
  --
  cv_forecast_type_01         CONSTANT VARCHAR2(2)  := '01';                 -- '01'�F����v��
  cv_prod_class_leaf          CONSTANT VARCHAR2(1)  := '1';                  -- '1'�F���[�t
  cv_prod_class_drink         CONSTANT VARCHAR2(1)  := '2';                  -- '2'�F�h�����N
  cv_prod_class_both          CONSTANT VARCHAR2(1)  := '3';                  -- '3'�F����
  cv_ins_0                    CONSTANT VARCHAR2(1)  := '0';
  cn_pad_2                    CONSTANT NUMBER       := 2;
  cn_case_count_min           CONSTANT NUMBER       := 0;                    -- �v�搔��(min)
  cn_case_count_max           CONSTANT NUMBER       := 999999;               -- �v�搔��(max)
  cn_num_of_case_1            CONSTANT NUMBER       := 1;                    -- �P�[�X����
  cn_api_ret_normal           CONSTANT NUMBER       := 5;                    -- 5�F����
  cn_process_status           CONSTANT NUMBER       := 2;                    -- process_status
  cn_confidence_percentage    CONSTANT NUMBER       := 100;                  -- confidence_percentage
  cn_bucket_type              CONSTANT NUMBER       := 1;                    -- �o�P�b�g�^�C�v
  cv_api_name                 CONSTANT VARCHAR2(50) := 'mrp_forecast_interface_pk.mrp_forecast_interface';
                                                                             -- ���vAPI��
  cv_item_status_20           CONSTANT VARCHAR2(2)  := '20';                 -- '20'�F���o�^
  cv_item_status_30           CONSTANT VARCHAR2(2)  := '30';                 -- '30'�F�{�o�^
  cv_item_status_40           CONSTANT VARCHAR2(2)  := '40';                 -- '40'�F�p
  cv_item_prod_class_prod     CONSTANT VARCHAR2(1)  := '2';                  -- '2'�F���i
  cv_item_class_prod          CONSTANT VARCHAR2(1)  := '5';                  -- '5'�F���i
  cv_shipment_on              CONSTANT VARCHAR2(1)  := '1';                  -- '1'�F�o�׉�
  cv_obsolete_class_off       CONSTANT VARCHAR2(1)  := '0';                  -- '0'�F�ΏۊO
  cv_sales_target_on          CONSTANT VARCHAR2(1)  := '1';                  -- '1'�F����Ώ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���ڃ`�F�b�N�i�[���R�[�h
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE     -- ���ږ���
    , attribute1              fnd_lookup_values.attribute1%TYPE  -- ���ڂ̒���
    , attribute2              fnd_lookup_values.attribute2%TYPE  -- ���ڂ̒����i�����_�ȉ��j
    , attribute3              fnd_lookup_values.attribute3%TYPE  -- �K�{�t���O
    , attribute4              fnd_lookup_values.attribute4%TYPE  -- ����
  );
  -- �e�[�u���^�C�v
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  -- �e�[�u���^
  gt_file_data                xxccp_common_pkg2.g_file_data_tbl; -- �ϊ���VARCHAR2�f�[�^
  gt_csv_tab                  xxcop_common_pkg.g_char_ttype;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_item_cnt                 NUMBER       DEFAULT 0;                        -- CSV���ڐ�
  gn_line_cnt                 NUMBER       DEFAULT 0;                        -- CSV�����s�J�E���^
  gn_record_no                NUMBER       DEFAULT 0;                        -- ���R�[�hNo
  gd_process_date             DATE         DEFAULT NULL;                     -- �Ɩ����t
  gt_master_org_id            mtl_parameters.organization_id%TYPE;           -- �}�X�^�g�DID
  gt_sales_org_code           mtl_parameters.organization_code%TYPE;         -- �c�Ƒg�D�R�[�h
  gt_sales_org_id             mtl_parameters.organization_id%TYPE;           -- �c�Ƒg�DID
  gt_whse_code_leaf           mtl_item_locations.segment1%TYPE;              -- �o�׌��q��_���[�t
  gt_whse_code_drink          mtl_item_locations.segment1%TYPE;              -- �o�׌��q��_�h�����N
  gt_arti_div_code            mtl_category_sets_vl.category_set_name%TYPE;   -- �J�e�S���Z�b�g��(�{�Џ��i�敪)
  gt_product_div_code         mtl_category_sets_vl.category_set_name%TYPE;   -- �J�e�S���Z�b�g��(���i���i�敪)
  gt_item_class               mtl_category_sets_vl.category_set_name%TYPE;   -- �J�e�S���Z�b�g��(�i�ڋ敪)
  gn_limit_forecast           NUMBER;                                        -- ����v����͐�������
  gt_upload_name              fnd_lookup_values.meaning%TYPE;                -- �t�@�C���A�b�v���[�h����
  --
  gv_tkn_1                    VARCHAR2(5000);        -- �G���[���b�Z�[�W�p�g�[�N��1
  gv_tkn_2                    VARCHAR2(5000);        -- �G���[���b�Z�[�W�p�g�[�N��2
  gv_tkn_3                    VARCHAR2(5000);        -- �G���[���b�Z�[�W�p�g�[�N��3
  gv_tkn_4                    VARCHAR2(5000);        -- �G���[���b�Z�[�W�p�g�[�N��4
  -- �e�[�u���ϐ�
  g_chk_item_tab              g_chk_item_ttype;      -- ���ڃ`�F�b�N
--
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  -- ����v��IF�\�J�[�\��
  CURSOR forecast_if_cur(
    iv_file_id  IN VARCHAR2)
  IS
    SELECT xmfi.file_id               AS file_id               -- �t�@�C��ID
         , xmfi.record_no             AS record_no             -- ���R�[�hNo
         , xmfi.target_month          AS target_month          -- �N��
         , xmfi.base_code             AS base_code             -- ���_�R�[�h
         , xmfi.whse_code             AS whse_code             -- �o�׌��q��
         , xmfi.item_code             AS item_code             -- ���i�R�[�h
         , xmfi.service_no            AS service_no            -- �֐�
         , xmfi.case_count            AS case_count            -- �v�搔��
         , xmfi.inventory_item_id     AS inventory_item_id     -- �i��ID
         , xmfi.num_of_case           AS num_of_case           -- �P�[�X����
         , xmfi.forecast_date         AS forecast_date         -- ���t
         , xmfi.forecast_designator   AS forecast_designator   -- �t�H�[�L���X�g��
    FROM   xxcop_mrp_forecast_interface  xmfi  -- ����v��IF�\
    WHERE  xmfi.file_id               = TO_NUMBER(iv_file_id)
    ORDER BY xmfi.record_no  -- ���R�[�hNo
    ;
  -- ���R�[�h��`
  forecast_if_rec             forecast_if_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lt_file_name              xxccp_mrp_file_ul_interface.file_name%TYPE;     -- �t�@�C����
    lt_upload_date            xxccp_mrp_file_ul_interface.creation_date%TYPE; -- �A�b�v���[�h����
--
    -- *** ���[�J���J�[�\�� ***
    -- ���ڃ`�F�b�N�J�[�\��
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning              AS meaning     -- ���ږ���
           , flv.attribute1           AS attribute1  -- ���ڂ̒���
           , flv.attribute2           AS attribute2  -- ���ڂ̒����i�����_�ȉ��j
           , flv.attribute3           AS attribute3  -- �K�{�t���O
           , flv.attribute4           AS attribute4  -- ����
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_forecast_item
      AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                             AND     NVL( flv.end_date_active  , gd_process_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    --
    --==============================================================
    -- 1�D�t�@�C���A�b�v���[�h�e�[�u�����擾
    --==============================================================
    xxcop_common_pkg.get_upload_table_info(
        in_file_id     => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      , iv_format      => iv_format             -- �t�H�[�}�b�g�p�^�[��
      , ov_upload_name => gt_upload_name        -- �t�@�C���A�b�v���[�h����
      , ov_file_name   => lt_file_name          -- �t�@�C����
      , od_upload_date => lt_upload_date        -- �A�b�v���[�h����
      , ov_retcode     => lv_retcode            -- ���^�[���R�[�h
      , ov_errbuf      => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_errmsg      => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �A�b�v���[�hIF���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00032 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_fileid      -- �g�[�N���R�[�h1
                     , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_format      -- �g�[�N���R�[�h2
                     , iv_token_value2 => iv_format          -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2�D�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    --==============================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_msg_xxcop_00036   -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_file_id       -- �g�[�N���R�[�h1
                   , iv_token_value1 => iv_file_id           -- �g�[�N���l1
                   , iv_token_name2  => cv_tkn_format_ptn    -- �g�[�N���R�[�h2
                   , iv_token_value2 => iv_format            -- �g�[�N���l2
                   , iv_token_name3  => cv_tkn_upload_object -- �g�[�N���R�[�h3
                   , iv_token_value3 => gt_upload_name       -- �g�[�N���l3
                   , iv_token_name4  => cv_tkn_file_name     -- �g�[�N���R�[�h4
                   , iv_token_value4 => lt_file_name         -- �g�[�N���l4
                 );
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => lv_errmsg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 3�D�Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application         -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_msg_xxcop_00065     -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 4�D�v���t�@�C���F�}�X�^�g�DID�擾
    --==============================================================
      BEGIN
        gt_master_org_id := fnd_profile.value(cv_master_org_id);
      EXCEPTION
        WHEN OTHERS THEN
          gt_master_org_id := NULL;
      END;
      -- �v���t�@�C���F�}�X�^�g�DID���擾�o���Ȃ��ꍇ
      IF ( gt_master_org_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_master_org_id     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 5�D�v���t�@�C���F�c�Ƒg�D�R�[�h�擾
    --==============================================================
      BEGIN
        gt_sales_org_code := fnd_profile.value(cv_sales_org_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_sales_org_code := NULL;
      END;
      -- �v���t�@�C���F�c�Ƒg�D�R�[�h���擾�o���Ȃ��ꍇ
      IF ( gt_sales_org_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_sales_org_code    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 6�D�c�Ƒg�DID�擾
    --==============================================================
      BEGIN
        SELECT mp.organization_id  AS organization_id
        INTO   gt_sales_org_id
        FROM   mtl_parameters mp
        WHERE  mp.organization_code = gt_sales_org_code  -- 5.�c�Ƒg�D�R�[�h
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gt_sales_org_id := NULL;
      END;
      -- �c�Ƒg�DID���擾�o���Ȃ��ꍇ
      IF ( gt_sales_org_id IS NULL ) THEN
        -- �g�[�N���l��ݒ�
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00080 );
        gv_tkn_3  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00081 );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcop_00013    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_item           -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_tkn_1              -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => gt_sales_org_code     -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_table          -- �g�[�N���R�[�h3
                      ,iv_token_value3 => gv_tkn_3              -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 7�D�v���t�@�C���F�o�׌��q��_���[�t�擾
    --==============================================================
      BEGIN
        gt_whse_code_leaf := fnd_profile.value(cv_whse_code_leaf);
      EXCEPTION
        WHEN OTHERS THEN
          gt_whse_code_leaf := NULL;
      END;
      -- �v���t�@�C���F�o�׌��q��_���[�t���擾�o���Ȃ��ꍇ
      IF ( gt_whse_code_leaf IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_whse_code_leaf    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 8�D�v���t�@�C���F�o�׌��q��_�h�����N�擾
    --==============================================================
      BEGIN
        gt_whse_code_drink := fnd_profile.value(cv_whse_code_drink);
      EXCEPTION
        WHEN OTHERS THEN
          gt_whse_code_leaf := NULL;
      END;
      -- �v���t�@�C���F�o�׌��q��_�h�����N���擾�o���Ȃ��ꍇ
      IF ( gt_whse_code_drink IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_whse_code_drink   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 9�D�v���t�@�C���F�J�e�S���Z�b�g��(�{�Џ��i�敪)�擾
    --==============================================================
      BEGIN
        gt_arti_div_code := fnd_profile.value(cv_arti_div_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_arti_div_code := NULL;
      END;
      -- �v���t�@�C���F�J�e�S���Z�b�g��(�{�Џ��i�敪)���擾�o���Ȃ��ꍇ
      IF ( gt_arti_div_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_arti_div_code     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 10�D�v���t�@�C���F�J�e�S���Z�b�g��(���i���i�敪)�擾
    --==============================================================
      BEGIN
        gt_product_div_code := fnd_profile.value(cv_product_div_code);
      EXCEPTION
        WHEN OTHERS THEN
          gt_product_div_code := NULL;
      END;
      -- �v���t�@�C���F�J�e�S���Z�b�g��(���i���i�敪)���擾�o���Ȃ��ꍇ
      IF ( gt_product_div_code IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_product_div_code  -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 11�D�v���t�@�C���F�J�e�S���Z�b�g��(�i�ڋ敪)�擾
    --==============================================================
      BEGIN
        gt_item_class := fnd_profile.value(cv_item_class);
      EXCEPTION
        WHEN OTHERS THEN
          gt_item_class := NULL;
      END;
      -- �v���t�@�C���F�J�e�S���Z�b�g��(�i�ڋ敪)���擾�o���Ȃ��ꍇ
      IF ( gt_item_class IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_item_class        -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 12�D�v���t�@�C���F����v����͐��������擾
    --==============================================================
      BEGIN
        gn_limit_forecast := TO_NUMBER(fnd_profile.value(cv_limit_forecast));
      EXCEPTION
        WHEN OTHERS THEN
          gn_limit_forecast := NULL;
      END;
      -- �v���t�@�C���F����v����͐����������擾�o���Ȃ��ꍇ
      IF ( gn_limit_forecast IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application          -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00002      -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile          -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_limit_forecast       -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    --==============================================================
    -- 13�D�N�C�b�N�R�[�h(���ڃ`�F�b�N���)�擾
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN chk_item_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- �J�[�\���N���[�Y
    CLOSE chk_item_cur;
    -- �N�C�b�N�R�[�h���擾�ł��Ȃ��ꍇ
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00006    -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_value          -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_forecast_item      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 14�D�N�C�b�N�R�[�h(���ڃ`�F�b�N���)���R�[�h�����擾
    --==============================================================
    gn_item_cnt := g_chk_item_tab.COUNT;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_file_upload_data'; -- �v���O������
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
--
    -- *** ���[�J���J�[�\�� ***
    -- �A�b�v���[�h�t�@�C���f�[�^�J�[�\��
    CURSOR xmfui_cur( in_file_id NUMBER )
    IS
      SELECT xmfui.file_name     AS file_name        -- �t�@�C����
            ,flv.meaning         AS upload_object    -- �t�@�C���A�b�v���[�h����
      FROM   xxccp_mrp_file_ul_interface xmfui       -- �t�@�C���A�b�v���[�hIF�e�[�u��
            ,fnd_lookup_values           flv         -- �N�C�b�N�R�[�h
      WHERE  xmfui.file_id       = in_file_id
      AND    flv.lookup_type     = cv_file_upload_obj
      AND    flv.lookup_code     = xmfui.file_content_type
      AND    gd_process_date     BETWEEN NVL( flv.start_date_active, gd_process_date )
                                 AND     NVL( flv.end_date_active  , gd_process_date )
      AND    flv.enabled_flag    = cv_flag_y
      AND    flv.language        = ct_lang
      FOR UPDATE OF xmfui.file_id NOWAIT
    ;
    -- ���R�[�h��`
    xmfui_rec                 xmfui_cur%ROWTYPE;
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
    -- 1�D�t�@�C���A�b�v���[�hIF�e�[�u�����b�N�擾
    --==============================================================
    BEGIN
      -- �I�[�v��
      OPEN xmfui_cur( TO_NUMBER(iv_file_id) );
      -- �t�F�b�`
      FETCH xmfui_cur INTO xmfui_rec;
      -- �N���[�Y
      CLOSE xmfui_cur;
      --
    EXCEPTION
      -- ���b�N�擾��O�n���h��
      WHEN global_lock_expt THEN
        -- �g�[�N���l��ݒ�
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00079 );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00007 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 2�DBLOB�f�[�^�ϊ�����
    --==============================================================
    xxccp_common_pkg2.blob_to_varchar2(
        in_file_id   => TO_NUMBER(iv_file_id) -- �t�@�C��ID
      , ov_file_data => gt_file_data          -- �ϊ���VARCHAR2�f�[�^
      , ov_errbuf    => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode   => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg    => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- ���^�[���R�[�h���G���[�̏ꍇ
    IF ( lv_retcode = cv_status_error ) THEN
      -- BLOB�f�[�^�ϊ��G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcok      -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcok_00041 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_file_id     -- �g�[�N���R�[�h1
                     , iv_token_value1 => iv_file_id         -- �g�[�N���l1
                   );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( xmfui_cur%ISOPEN ) THEN
        CLOSE xmfui_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_validate_item
   * Description      : �Ó����`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- �v���O������
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
    ln_chk_cnt                NUMBER       DEFAULT 0;                                 -- �`�F�b�N�p����
    lt_inventory_item_id      xxcop_mrp_forecast_interface.inventory_item_id%TYPE;    -- �i��ID
    lt_prod_class             mtl_categories_vl.segment1%TYPE;                        -- ���i�敪
    lt_num_of_case            xxcop_mrp_forecast_interface.num_of_case%TYPE;          -- �P�[�X����
    lt_whse_code              xxcop_mrp_forecast_interface.whse_code%TYPE;            -- �o�׌��q��
    lt_whse_type              hr_locations_all.attribute1%TYPE;                       -- �o�׊Ǘ����敪
    lt_target_month           xxcop_mrp_forecast_interface.target_month%TYPE;         -- �N��
    lt_forecast_date          xxcop_mrp_forecast_interface.forecast_date%TYPE;        -- �t�H�[�L���X�g���t
    lt_chk_forecast_date      xxcop_mrp_forecast_interface.forecast_date%TYPE;        -- �ғ����`�F�b�N�p���t
    lv_forecast_month         VARCHAR(6);                                             -- �t�H�[�L���X�g�N��
    lt_forecast_designator    xxcop_mrp_forecast_interface.forecast_designator%TYPE;  -- �t�H�[�L���X�g��
    lt_csv_tab                xxcop_common_pkg.g_char_ttype;                          -- ��������
    lb_item_check_flag        BOOLEAN      DEFAULT FALSE;                             -- ���ڃ`�F�b�N�t���O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    ln_chk_cnt              := 0;      -- �`�F�b�N�p����
    lt_inventory_item_id    := NULL;   -- �i��ID
    lt_prod_class           := NULL;   -- ���i�敪
    lt_num_of_case          := NULL;   -- �P�[�X����
    lt_whse_code            := NULL;   -- �o�׌��q��
    lt_whse_type            := NULL;   -- �o�׊Ǘ����敪
    lt_target_month         := NULL;   -- �N��
    lt_forecast_date        := NULL;   -- �t�H�[�L���X�g���t
    lt_chk_forecast_date    := NULL;   -- �ғ����`�F�b�N�p���t
    lv_forecast_month       := NULL;   -- �t�H�[�L���X�g�N��
    lt_forecast_designator  := NULL;   -- �t�H�[�L���X�g��
    lb_item_check_flag      := FALSE;  -- ���ڃ`�F�b�N�t���O
    lt_csv_tab.DELETE;            -- ��������
    gt_csv_tab.DELETE;            -- �������ʁi�������菜����j
--
    --==============================================================
    -- 1�DCSV�����񕪊�
    --==============================================================
    --CSV��������
    xxcop_common_pkg.char_delim_partition(
        ov_retcode => lv_retcode                    -- ���^�[���R�[�h
      , ov_errbuf  => lv_errbuf                     -- �G���[�E���b�Z�[�W
      , ov_errmsg  => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W
      , iv_char    => gt_file_data(gn_line_cnt)     -- �Ώە�����
      , iv_delim   => cv_comma                      -- �f���~�^
      , o_char_tab => lt_csv_tab                    -- ��������
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- ���R�[�hNo
    gn_record_no  := gn_record_no  + 1;
    -- �Ώی����iCSV�̍s���j�ێ�
    gn_target_cnt := gn_target_cnt + 1;
    --
    -- ���ڐ����قȂ�ꍇ
    IF ( gn_item_cnt <> lt_csv_tab.COUNT ) THEN
      -- �t�H�[�}�b�g�`�F�b�N�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00069 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row         -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_record_no       -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_file        -- �g�[�N���R�[�h2
                     , iv_token_value2 => gt_upload_name     -- �g�[�N���l2
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- �Ó����`�F�b�N�G���[��O
      RAISE global_chk_item_expt;
    END IF;
    --
    --==============================================================
    -- 2�D�K�{�^�^�^�����`�F�b�N
    --==============================================================
    -- ���ڃ`�F�b�N���[�v
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      -- �������肪���݂���ꍇ�͍폜
      gt_csv_tab(i) := TRIM( REPLACE( lt_csv_tab(i), cv_dobule_quote, NULL ) );
      --
      -- ���ڃ`�F�b�N���ʊ֐�
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning     -- ���ږ���
        , iv_item_value   => gt_csv_tab(i)                 -- ���ڂ̒l
        , in_item_len     => g_chk_item_tab(i).attribute1  -- ���ڂ̒���
        , in_item_decimal => g_chk_item_tab(i).attribute2  -- ���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3  -- �K�{�t���O
        , iv_item_attr    => g_chk_item_tab(i).attribute4  -- ���ڑ���
        , ov_errbuf       => lv_errbuf                     -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      => lv_retcode                    -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       => lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- ���^�[���R�[�h������ȊO�̏ꍇ
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- ���ڕs���G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00070        -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                       , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                       , iv_token_value2 => g_chk_item_tab(i).meaning -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                       , iv_token_value3 => gt_csv_tab(i)             -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_errmsg             -- �g�[�N���R�[�h4
                       , iv_token_value4 => lv_errmsg                 -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- �Ó����`�F�b�N�G���[�ݒ�
        lb_item_check_flag := TRUE;
      END IF;
      --
    END LOOP item_check_loop;
    --
    -- �Ó����`�F�b�N�G���[�̏ꍇ
    IF ( lb_item_check_flag = TRUE ) THEN
      -- �Ó����`�F�b�N�G���[��O
      RAISE global_chk_item_expt;
    END IF;
    --
    --==============================================================
    -- 3�D�N���`�F�b�N
    --==============================================================
    IF xxcop_common_pkg.chk_date_format( gt_csv_tab(1), cv_format_yyyymm ) = FALSE THEN
      -- DATE�^�`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00071        -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                     , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                     , iv_token_value2 => g_chk_item_tab(1).meaning -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                     , iv_token_value3 => gt_csv_tab(1)             -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- �Ó����`�F�b�N�G���[�ݒ�
      lb_item_check_flag := TRUE;
    ELSE
      -- �`�F�b�NOK�̏ꍇ�A���[�J���ϐ��ɐݒ�
      lt_target_month := gt_csv_tab(1);
    END IF;
    --
    --==============================================================
    -- 4�D�S�����_�R�[�h�`�F�b�N
    --==============================================================
    SELECT COUNT(1)  AS cnt
    INTO   ln_chk_cnt
    FROM   xxcop_base_code_v xbcv         -- �v��_�S�����_�r���[
    WHERE  xbcv.base_code = gt_csv_tab(2) -- ���_�R�[�h
    ;
    --
    -- ������0���̏ꍇ
    IF ( ln_chk_cnt = 0 ) THEN
      -- �S�����_�`�F�b�N�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00072        -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                      , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                      , iv_token_value2 => g_chk_item_tab(2).meaning -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                      , iv_token_value3 => gt_csv_tab(2)             -- �g�[�N���l3
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- �Ó����`�F�b�N�G���[�ݒ�
      lb_item_check_flag := TRUE;
    END IF;
    --
    --==============================================================
    -- 5�D���i�R�[�h�`�F�b�N
    --==============================================================
    BEGIN
      SELECT msib.inventory_item_id               AS inventory_item_id  -- �i��ID
            ,pc.prod_class                        AS prod_class         -- ���i�敪
            ,TO_NUMBER( NVL( iimb.attribute11, cn_num_of_case_1 ) )
                                                  AS num_of_case        -- �P�[�X����
      INTO   lt_inventory_item_id
            ,lt_prod_class
            ,lt_num_of_case
      FROM   ic_item_mst_b          iimb     -- OPM�i��
            ,xxcmn_item_mst_b       ximb     -- OPM�i�ڃA�h�I��
            ,xxcmm_system_items_b   xsib     -- Disc�i�ڃA�h�I��
            ,mtl_system_items_b     msib     -- Disc�i��
            ,(SELECT gic_pc.item_id          AS item_id
                    ,mcv_pc.segment1         AS prod_class
              FROM   gmi_item_categories     gic_pc
                    ,mtl_category_sets_vl    mcsv_pc
                    ,mtl_categories_vl       mcv_pc
              WHERE  gic_pc.category_set_id    = mcsv_pc.category_set_id
              AND    mcsv_pc.category_set_name = gt_arti_div_code      -- �J�e�S���Z�b�g��(�{�Џ��i�敪)
              AND    gic_pc.category_id        = mcv_pc.category_id
            ) pc  -- �C�����C���r���[_�{�Џ��i�敪
            ,(SELECT gic_ip.item_id          AS item_id
                    ,mcv_ip.segment1         AS item_prod_class
              FROM   gmi_item_categories     gic_ip
                    ,mtl_category_sets_vl    mcsv_ip
                    ,mtl_categories_vl       mcv_ip
              WHERE  gic_ip.category_set_id    = mcsv_ip.category_set_id
              AND    mcsv_ip.category_set_name = gt_product_div_code   -- �J�e�S���Z�b�g��(���i���i�敪)
              AND    gic_ip.category_id        = mcv_ip.category_id
            ) ip  -- �C�����C���r���[_���i���i�敪
            ,(SELECT gic_ic.item_id          AS item_id
                    ,mcv_ic.segment1         AS item_class
              FROM   gmi_item_categories     gic_ic
                    ,mtl_category_sets_vl    mcsv_ic
                    ,mtl_categories_vl       mcv_ic
              WHERE  gic_ic.category_set_id    = mcsv_ic.category_set_id
              AND    mcsv_ic.category_set_name = gt_item_class         -- �J�e�S���Z�b�g��(�i�ڋ敪)
              AND    gic_ic.category_id        = mcv_ic.category_id
            ) ic  -- �C�����C���r���[_�i�ڋ敪
      WHERE  iimb.item_id            = ximb.item_id
      AND    iimb.item_id            = pc.item_id
-- ********** Ver.1.1 K.Nakamura MOD Start ************ --
--      AND    iimb.item_id            = ic.item_id
      AND    iimb.item_id            = ic.item_id(+)
-- ********** Ver.1.1 K.Nakamura MOD End ************ --
      AND    iimb.item_id            = ip.item_id
      AND    iimb.item_no            = xsib.item_code
      AND    iimb.item_no            = msib.segment1
      AND    iimb.item_no            = gt_csv_tab(4)                              -- ���i�R�[�h
      AND    msib.organization_id    = gt_master_org_id                           -- �}�X�^�g�DID
      AND    gd_process_date         BETWEEN ximb.start_date_active
                                     AND     ximb.end_date_active
      AND    ip.item_prod_class      = cv_item_prod_class_prod                    -- ���i
-- ********** Ver.1.1 K.Nakamura MOD Start ************ --
--      AND    ic.item_class           = cv_item_class_prod                         -- ���i
      AND    (  ( ic.item_class      = cv_item_class_prod )                       -- ���i
             OR ( ic.item_class      IS NULL ) )
-- ********** Ver.1.1 K.Nakamura MOD End ************ --
      AND    iimb.attribute18        = cv_shipment_on                             -- �o�׉�
      AND    ximb.obsolete_class     = cv_obsolete_class_off                      -- �ΏۊO
             -- �e�i�ڂ��A�i�ڃX�e�[�^�X�u30�F�{�o�^�v�u40�F�p�v���A����Ώ�
      AND    (  (   iimb.item_id     = ximb.parent_item_id
                AND xsib.item_status IN ( cv_item_status_30 ,cv_item_status_40 )  -- �i�ڃX�e�[�^�X
                AND iimb.attribute26 = cv_sales_target_on )                       -- ����Ώ�
             -- �e�i�ڂ��A�i�ڃX�e�[�^�X�u20�F���o�^�v
             OR (   iimb.item_id     = ximb.parent_item_id
                AND xsib.item_status = cv_item_status_20                          -- �i�ڃX�e�[�^�X
                )
             -- �q�i�ڂ��A�i�ڃX�e�[�^�X�u20�F���o�^�v�u30�F�{�o�^�v�u40�F�p�v
             OR (iimb.item_id        <> ximb.parent_item_id
                AND xsib.item_status IN ( cv_item_status_20 ,cv_item_status_30 ,cv_item_status_40 )
                )
             )
      AND    xsib.item_status_apply_date <= gd_process_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �g�[�N���l��ݒ�
        gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00087 );
        -- �}�X�^���o�^�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_msg_xxcop_00073        -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                        , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                        , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                        , iv_token_value2 => g_chk_item_tab(4).meaning -- �g�[�N���l2
                        , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                        , iv_token_value3 => gt_csv_tab(4)             -- �g�[�N���l3
                        , iv_token_name4  => cv_tkn_table              -- �g�[�N���R�[�h4
                        , iv_token_value4 => gv_tkn_4                  -- �g�[�N���l4
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- �Ó����`�F�b�N�G���[�ݒ�
        lb_item_check_flag := TRUE;
    END;
    --
    --==============================================================
    -- 6�D�o�׌��q�ɐݒ�
    --==============================================================
    -- �o�׌��q�ɂ����ݒ肩�A���[�J���ϐ�_���i�敪���擾�ł����ꍇ
    IF ( gt_csv_tab(3) IS NULL ) AND ( lt_prod_class IS NOT NULL ) THEN
      -- ���[�t�̏ꍇ
      IF ( lt_prod_class = cv_prod_class_leaf ) THEN
        lt_whse_code  := gt_whse_code_leaf;   -- �v���t�@�C���F�o�׌��q��_���[�t
      -- �h�����N�̏ꍇ
      ELSE
        lt_whse_code  := gt_whse_code_drink;  -- �v���t�@�C���F�o�׌��q��_�h�����N
      END IF;
    -- �o�׌��q�ɂɒl���ݒ肳��Ă���ꍇ
    ELSIF ( gt_csv_tab(3) IS NOT NULL ) THEN
      lt_whse_code    := gt_csv_tab(3);
    -- ��L�ȊO�̏ꍇ
    ELSE
      lt_whse_code    := NULL;
      --
      -- �o�׌��q�ɐݒ�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_10065  -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_row          -- �g�[�N���R�[�h1
                      , iv_token_value1 => gn_record_no        -- �g�[�N���l1
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- �Ó����`�F�b�N�G���[�ݒ�
      lb_item_check_flag := TRUE;
    END IF;
    --
    --==============================================================
    -- 7�D�o�׌��q�Ƀ`�F�b�N
    --==============================================================
    -- ���[�J���ϐ�_�o�׌��q�ɂ��ݒ肳��Ă���ꍇ
    IF ( lt_whse_code IS NOT NULL ) THEN
      BEGIN
        SELECT hla.attribute1  AS whse_type     -- DFF1(�o�׊Ǘ����敪)
        INTO   lt_whse_type
        FROM   ic_whse_mst                iwm   -- OPM�q�Ƀ}�X�^
              ,mtl_item_locations         mil   -- OPM�ۊǏꏊ�}�X�^
              ,hr_all_organization_units  haou  -- �݌ɑg�D�}�X�^
              ,hr_locations_all           hla   -- ���Ə��}�X�^
        WHERE  iwm.mtl_organization_id = haou.organization_id
        AND    haou.organization_id    = mil.organization_id
        AND    mil.segment1            = lt_whse_code  -- ���[�J���ϐ�_�o�׌��q��
        AND    iwm.whse_code           = hla.location_code
        AND    gd_process_date         BETWEEN haou.date_from
                                       AND     NVL( haou.date_to, gd_process_date )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00086 );
          -- �}�X�^���o�^�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_xxcop_00073        -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                          , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                          , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                          , iv_token_value2 => g_chk_item_tab(3).meaning -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                          , iv_token_value3 => lt_whse_code              -- �g�[�N���l3
                          , iv_token_name4  => cv_tkn_table              -- �g�[�N���R�[�h4
                          , iv_token_value4 => gv_tkn_4                  -- �g�[�N���l4
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg);
          -- �Ó����`�F�b�N�G���[�ݒ�
          lb_item_check_flag := TRUE;
      END;
    END IF;
    --
    --==============================================================
    -- 8�D�o�׌��q�ɂƏ��i�R�[�h�̐������`�F�b�N
    --==============================================================
    -- �o�׊Ǘ��敪�Ə��i�敪���s��v�̏ꍇ�̓G���[
    IF ( lt_whse_type IS NOT NULL ) AND ( lt_prod_class IS NOT NULL ) THEN
      IF ( lt_whse_type <> cv_prod_class_both ) AND ( lt_whse_type <> lt_prod_class ) THEN
        -- �g�[�N���l��ݒ�
        gv_tkn_2  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00088 );
        gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00089 );
        -- �s�����G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_msg_xxcop_00074        -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                        , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                        , iv_token_name2  => cv_tkn_item1              -- �g�[�N���R�[�h2
                        , iv_token_value2 => gv_tkn_2                  -- �g�[�N���l2
                        , iv_token_name3  => cv_tkn_value1             -- �g�[�N���R�[�h3
                        , iv_token_value3 => lt_whse_type              -- �g�[�N���l3
                        , iv_token_name4  => cv_tkn_item2              -- �g�[�N���R�[�h4
                        , iv_token_value4 => gv_tkn_4                  -- �g�[�N���l4
                        , iv_token_name5  => cv_tkn_value2             -- �g�[�N���R�[�h5
                        , iv_token_value5 => lt_prod_class             -- �g�[�N���l5
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- �Ó����`�F�b�N�G���[�ݒ�
        lb_item_check_flag := TRUE;
      END IF;
    END IF;
    --
    -- �ȉ�9�A10�̃`�F�b�N�͏�L3���G���[�ł͂Ȃ��ꍇ�Ɏ��s
    IF ( lt_target_month IS NOT NULL ) THEN
      --==============================================================
      -- 9�D�֐����݃`�F�b�N
      --==============================================================
      -- ���[�t���A���[�J���ϐ�_�o�׊Ǘ����敪���ݒ肳��Ă���ꍇ
      IF ( lt_prod_class = cv_prod_class_leaf ) AND ( lt_whse_type IS NOT NULL ) THEN
        BEGIN
          SELECT wl.forecast_date AS forecast_date  -- �t�H�[�L���X�g���t
          INTO   lt_forecast_date
          FROM   (SELECT ROW_NUMBER() OVER ( ORDER BY xldos.target_month, xldos.day_of_service )    AS service_no
                        ,TO_DATE( xldos.target_month || LPAD( xldos.day_of_service, cn_pad_2, cv_ins_0 ), cv_format_yyyymmdd )
                                                                                                    AS forecast_date
                  FROM   xxcop_leaf_day_of_service xldos      -- ���[�t�֕\
                  WHERE  xldos.whse_code    = lt_whse_code    -- �o�׌��q��
                  AND    xldos.base_code    = gt_csv_tab(2)   -- ���_�R�[�h
                  AND    xldos.target_month = lt_target_month -- �N��
                 ) wl
          WHERE wl.service_no               = gt_csv_tab(5)   -- �֐�
          ;
          --
          -- �ғ����`�F�b�N�p���t��ݒ�
          lt_chk_forecast_date := mrp_calendar.next_work_day(
                                  gt_sales_org_id          -- �c�Ƒg�DID
                                 ,cn_bucket_type           -- �o�P�b�g�^�C�v
                                 ,lt_forecast_date         -- ���[�J���ϐ�_���t
                                  );
          --
          -- ���[�J���ϐ�_���t�Ɖғ����`�F�b�N�p���t����v���Ȃ��ꍇ�̓G���[
          IF ( lt_forecast_date <> lt_chk_forecast_date ) THEN
            -- �g�[�N���l��ݒ�
            gv_tkn_3  := TO_CHAR( lt_forecast_date ,cv_format_std_yyyymmdd );
            -- �։ғ����`�F�b�N�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcop_10068        -- ���b�Z�[�W�R�[�h
                            , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                            , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                            , iv_token_name2  => cv_tkn_value1             -- �g�[�N���R�[�h2
                            , iv_token_value2 => gt_csv_tab(5)             -- �g�[�N���l2
                            , iv_token_name3  => cv_tkn_value2             -- �g�[�N���R�[�h3
                            , iv_token_value3 => gv_tkn_3                  -- �g�[�N���l3
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- �Ó����`�F�b�N�G���[�ݒ�
            lb_item_check_flag := TRUE;
          END IF;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �g�[�N���l��ݒ�
            gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00084 );
            -- �}�X�^���o�^�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcop_00073        -- ���b�Z�[�W�R�[�h
                            , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                            , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                            , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                            , iv_token_value2 => g_chk_item_tab(5).meaning -- �g�[�N���l2
                            , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                            , iv_token_value3 => gt_csv_tab(5)             -- �g�[�N���l3
                            , iv_token_name4  => cv_tkn_table              -- �g�[�N���R�[�h4
                            , iv_token_value4 => gv_tkn_4                  -- �g�[�N���l4
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- �Ó����`�F�b�N�G���[�ݒ�
            lb_item_check_flag := TRUE;
        END;
      --
      -- �h�����N�̏ꍇ
      ELSIF ( lt_prod_class = cv_prod_class_drink ) THEN
        BEGIN
          SELECT wd.forecast_date AS forecast_date  -- �t�H�[�L���X�g���t
          INTO   lt_forecast_date
          FROM (SELECT ROW_NUMBER() OVER ( ORDER BY tmp.forecast_date )  AS service_no
                      ,tmp.forecast_date                                 AS forecast_date
                FROM (SELECT mrp_calendar.next_work_day(
                             gt_sales_org_id          -- �c�Ƒg�DID
                            ,cn_bucket_type           -- �o�P�b�g�^�C�v
                            ,TRUNC( ADD_MONTHS( TO_DATE( lt_target_month    -- �N��
                               || LPAD( TO_NUMBER( flv.description ), cn_pad_2, cv_ins_0 ), cv_format_yyyymmdd )
                              ,TO_NUMBER( flv.attribute1 ) ) )
                             )  AS forecast_date
                      FROM   fnd_lookup_values flv
                      WHERE  flv.lookup_type                                = cv_forecast_date
                      AND    flv.language                                   = ct_lang
                      AND    flv.enabled_flag                               = cv_flag_y
                      AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date
                      AND    NVL( flv.end_date_active  , gd_process_date ) >= gd_process_date
                      ) tmp
               ) wd
          WHERE wd.service_no                                               = gt_csv_tab(5) -- �֐�
          ;
          --
          -- �Ώۊ��ԓ��`�F�b�N
          IF ( lt_forecast_date < gd_process_date - gn_limit_forecast ) THEN
            -- �g�[�N���l��ݒ�
            gv_tkn_4  := TO_CHAR( lt_forecast_date ,cv_format_std_yyyymmdd );
            -- ����v��Ώۊ��ԊO�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcop_10064        -- ���b�Z�[�W�R�[�h
                            , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                            , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                            , iv_token_name2  => cv_tkn_value1             -- �g�[�N���R�[�h2
                            , iv_token_value2 => gn_limit_forecast         -- �g�[�N���l2
                            , iv_token_name3  => cv_tkn_value2             -- �g�[�N���R�[�h3
                            , iv_token_value3 => gt_csv_tab(5)             -- �g�[�N���l3
                            , iv_token_name4  => cv_tkn_value3             -- �g�[�N���R�[�h4
                            , iv_token_value4 => gv_tkn_4                  -- �g�[�N���l4
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- �Ó����`�F�b�N�G���[�ݒ�
            lb_item_check_flag := TRUE;
          END IF;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �g�[�N���l��ݒ�
            gv_tkn_4  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00085 )
                         ||'( '|| cv_forecast_date ||' )';
            -- �}�X�^���o�^�G���[���b�Z�[�W
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                            , iv_name         => cv_msg_xxcop_00073        -- ���b�Z�[�W�R�[�h
                            , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                            , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                            , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                            , iv_token_value2 => g_chk_item_tab(5).meaning -- �g�[�N���l2
                            , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                            , iv_token_value3 => gt_csv_tab(5)             -- �g�[�N���l3
                            , iv_token_name4  => cv_tkn_table              -- �g�[�N���R�[�h4
                            , iv_token_value4 => gv_tkn_4                  -- �g�[�N���l4
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg);
            -- �Ó����`�F�b�N�G���[�ݒ�
            lb_item_check_flag := TRUE;
        END;
      END IF;
      --
      --==============================================================
      -- 10�D�N���Ɠ��t�̐������`�F�b�N
      --==============================================================
      IF ( lt_forecast_date IS NOT NULL ) THEN
        -- ���t�̔N�����擾
        lv_forecast_month := TO_CHAR( lt_forecast_date ,cv_format_yyyymm );
        -- �t�H�[�L���X�g���t�̔N����CSV�t�@�C���̔N�����s��v�̏ꍇ�̓G���[
        IF ( lv_forecast_month <> lt_target_month ) THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_2  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00082 ) ||
                       xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00092 );
          -- �s�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application             -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_xxcop_00074         -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_row                 -- �g�[�N���R�[�h1
                          , iv_token_value1 => gn_record_no               -- �g�[�N���l1
                          , iv_token_name2  => cv_tkn_item1               -- �g�[�N���R�[�h2
                          , iv_token_value2 => gv_tkn_2                   -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_value1              -- �g�[�N���R�[�h3
                          , iv_token_value3 => lv_forecast_month          -- �g�[�N���l3
                          , iv_token_name4  => cv_tkn_item2               -- �g�[�N���R�[�h4
                          , iv_token_value4 => g_chk_item_tab(1).meaning  -- �g�[�N���l4
                          , iv_token_name5  => cv_tkn_value2              -- �g�[�N���R�[�h5
                          , iv_token_value5 => lt_target_month            -- �g�[�N���l5
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg);
          -- �Ó����`�F�b�N�G���[�ݒ�
          lb_item_check_flag := TRUE;
        END IF;
      END IF;
    END IF;
    --
    --==============================================================
    -- 11�D�v�搔�ʃ`�F�b�N
    --==============================================================
    -- �v�搔�ʂ��͈͓��ł��邩�`�F�b�N
    IF ( gt_csv_tab(6) < cn_case_count_min ) OR ( gt_csv_tab(6) > cn_case_count_max ) THEN
      -- �͈͊O�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_00077        -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                      , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                      , iv_token_value2 => g_chk_item_tab(6).meaning -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_value1             -- �g�[�N���R�[�h3
                      , iv_token_value3 => gt_csv_tab(6)             -- �g�[�N���l3
                      , iv_token_name4  => cv_tkn_value2             -- �g�[�N���R�[�h4
                      , iv_token_value4 => cn_case_count_min         -- �g�[�N���l4
                      , iv_token_name5  => cv_tkn_value3             -- �g�[�N���R�[�h5
                      , iv_token_value5 => cn_case_count_max         -- �g�[�N���l5
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- �Ó����`�F�b�N�G���[�ݒ�
      lb_item_check_flag := TRUE;
    END IF;
    --
    --==============================================================
    -- 12�D�t�H�[�L���X�g�����݃`�F�b�N
    --==============================================================
    -- ���[�J���ϐ�_�o�׊Ǘ����敪���ݒ肳��Ă���ꍇ
    IF ( lt_whse_type IS NOT NULL ) THEN
      --
      BEGIN
        SELECT mfds.forecast_designator  AS forecast_designator  -- �t�H�[�L���X�g��
        INTO   lt_forecast_designator
        FROM   mrp_forecast_designators mfds                   -- �t�H�[�L���X�g��
        WHERE  mfds.organization_id     = gt_master_org_id     -- �}�X�^�g�DID
        AND    mfds.attribute1          = cv_forecast_type_01  -- FORECAST����
        AND    mfds.attribute2          = lt_whse_code         -- �o�׌��q��
        AND    mfds.attribute3          = gt_csv_tab(2)        -- ���_�R�[�h
        AND  ( mfds.disable_date        IS NULL
          OR   mfds.disable_date        > gd_process_date )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �}�X�^���o�^�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_msg_xxcop_10066        -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                          , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                          , iv_token_name2  => cv_tkn_value1             -- �g�[�N���R�[�h2
                          , iv_token_value2 => cv_forecast_type_01       -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_value2             -- �g�[�N���R�[�h3
                          , iv_token_value3 => lt_whse_code              -- �g�[�N���l3
                          , iv_token_name4  => cv_tkn_value3             -- �g�[�N���R�[�h4
                          , iv_token_value4 => gt_csv_tab(2)             -- �g�[�N���l4
                       );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg);
        -- �Ó����`�F�b�N�G���[�ݒ�
        lb_item_check_flag := TRUE;
      END;
    END IF;
    --
    --==============================================================
    -- 13�D����v��IF�\�o�^
    --==============================================================
    -- �Ó����`�F�b�N�ŃG���[���Ȃ��ꍇ�͈���v��IF�\�ɓo�^
    IF ( lb_item_check_flag = FALSE ) THEN
      BEGIN
        INSERT INTO xxcop_mrp_forecast_interface(
            file_id                   -- �t�@�C��ID
          , record_no                 -- ���R�[�hNo
          , target_month              -- �N��
          , base_code                 -- ���_�R�[�h
          , whse_code                 -- �o�׌��q��
          , item_code                 -- ���i�R�[�h
          , service_no                -- �֐�
          , case_count                -- �v�搔��
          , inventory_item_id         -- �i��ID
          , num_of_case               -- �P�[�X����
          , forecast_date             -- ���t
          , forecast_designator       -- �t�H�[�L���X�g��
        ) VALUES (
            TO_NUMBER(iv_file_id)     -- �t�@�C��ID
          , gn_record_no              -- ���R�[�hNo
          , lt_target_month           -- �N��
          , gt_csv_tab(2)             -- ���_�R�[�h
          , lt_whse_code              -- �o�׌��q��
          , gt_csv_tab(4)             -- ���i�R�[�h
          , gt_csv_tab(5)             -- �֐�
          , gt_csv_tab(6)             -- �v�搔��
          , lt_inventory_item_id      -- �i��ID
          , lt_num_of_case            -- �P�[�X����
          , lt_forecast_date          -- ���t
          , lt_forecast_designator    -- �t�H�[�L���X�g��
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10058 );
          -- �o�^�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_1              -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    -- 14�D�֏d���`�F�b�N
    --==============================================================
    SELECT COUNT(1)  AS cnt      -- �`�F�b�N�p����
    INTO   ln_chk_cnt
    FROM   xxcop_mrp_forecast_interface xmfi
    WHERE  xmfi.target_month  = lt_target_month  -- �N��
    AND    xmfi.base_code     = gt_csv_tab(2)    -- ���_�R�[�h
    AND    xmfi.whse_code     = lt_whse_code     -- �o�׌��q��
    AND    xmfi.item_code     = gt_csv_tab(4)    -- ���i�R�[�h
    AND    xmfi.service_no    = gt_csv_tab(5)    -- ��
    AND    xmfi.record_no    <> gn_record_no
    ;
    -- ������1���ȏ�̏ꍇ
    IF ( ln_chk_cnt > 0 ) THEN
      -- �d���G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application            -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcop_10069        -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_row                -- �g�[�N���R�[�h1
                      , iv_token_value1 => gn_record_no              -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_value1             -- �g�[�N���R�[�h2
                      , iv_token_value2 => lt_target_month           -- �g�[�N���l2
                      , iv_token_name3  => cv_tkn_value2             -- �g�[�N���R�[�h3
                      , iv_token_value3 => gt_csv_tab(2)             -- �g�[�N���l3
                      , iv_token_name4  => cv_tkn_value3             -- �g�[�N���R�[�h4
                      , iv_token_value4 => lt_whse_code              -- �g�[�N���l4
                      , iv_token_name5  => cv_tkn_value4             -- �g�[�N���R�[�h5
                      , iv_token_value5 => gt_csv_tab(4)             -- �g�[�N���l5
                      , iv_token_name6  => cv_tkn_value5             -- �g�[�N���R�[�h6
                      , iv_token_value6 => gt_csv_tab(5)             -- �g�[�N���l6
                   );
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg);
      -- �Ó����`�F�b�N�G���[�ݒ�
      lb_item_check_flag := TRUE;
    END IF;
--
  -- �Ó����`�F�b�N�G���[�̏ꍇ
  IF ( lb_item_check_flag = TRUE ) THEN
    -- �Ó����`�F�b�N��O
    RAISE global_chk_item_expt;
  END IF;
--
  EXCEPTION
--
    -- �Ó����`�F�b�N��O�n���h��
    WHEN global_chk_item_expt THEN
      ov_retcode := cv_status_error;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : exec_api_forecast_if
   * Description      : ���vAPI���s(A-5)
   ***********************************************************************************/
  PROCEDURE exec_api_forecast_if(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_api_forecast_if'; -- �v���O������
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
    lt_transaction_id     mrp_forecast_dates.transaction_id%TYPE;  -- �g�����U�N�V����ID
    lt_attribute5         mrp_forecast_dates.attribute5%TYPE;      -- DFF5(���_)
    lt_attribute6         mrp_forecast_dates.attribute6%TYPE;      -- DFF6(�v�搔��)
    lt_creation_date      mrp_forecast_dates.creation_date%TYPE;   -- �쐬��
    lt_created_by         mrp_forecast_dates.created_by%TYPE;      -- �쐬��
    ln_forecast_quantity  NUMBER;                                  -- �t�H�[�L���X�g����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    t_forecast_interface_tab    mrp_forecast_interface_pk.t_forecast_interface;  -- ���vAPI�F�t�H�[�L���X�g���t
    lb_api                      BOOLEAN;                                         -- ���vAPI�F�ԋp�l
--
    -- *** ���[�J�����[�U�[��`��O ***
    exec_api_forecast_expt    EXCEPTION;  -- ���vAPI���s��O
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
    -- 1�D�t�H�[�L���X�g���t���擾
    --==============================================================
    BEGIN
      SELECT mfdt.transaction_id  AS transaction_id  -- �g�����U�N�V����ID
            ,mfdt.creation_date   AS creation_date   -- �쐬��
            ,mfdt.created_by      AS created_by      -- �쐬��
      INTO   lt_transaction_id
            ,lt_creation_date
            ,lt_created_by
      FROM   mrp_forecast_dates mfdt  -- �t�H�[�L���X�g���t
      WHERE  mfdt.organization_id     = gt_master_org_id                     -- �}�X�^�g�DID
      AND    mfdt.forecast_designator = forecast_if_rec.forecast_designator  -- �t�H�[�L���X�g��
      AND    mfdt.inventory_item_id   = forecast_if_rec.inventory_item_id    -- �i��ID
      AND    mfdt.forecast_date       = forecast_if_rec.forecast_date        -- �t�H�[�L���X�g���t
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      --
      WHEN NO_DATA_FOUND THEN
        -- �擾�ł��Ȃ��ꍇ�́A�V�K���R�[�h�Ƃ��ĕϐ���NULL��ݒ�
        lt_transaction_id := NULL;
-- ********** Ver.1.1 K.Nakamura ADD Start ************ --
        -- �V�K���R�[�h���v�搔�ʂ�0�̏ꍇ�A�o�^���Ȃ�
        IF ( forecast_if_rec.case_count = 0 ) THEN
          RAISE global_no_insert_expt;
        END IF;
-- ********** Ver.1.1 K.Nakamura ADD End ************ --
      -- ���b�N�擾��O�n���h��
      WHEN global_lock_expt THEN
        -- �g�[�N���l��ݒ�
        gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00082 );
        --
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcop_00007 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- 2�D���vAPI���s
    --==============================================================
    -- �t�H�[�L���X�g���ʂ̎Z�o�i�v�搔�� * �P�[�X�����j
    ln_forecast_quantity := forecast_if_rec.case_count * forecast_if_rec.num_of_case;
--
    -- �o�^�̏ꍇ
    IF ( lt_transaction_id IS NULL ) THEN
      lt_attribute5       := forecast_if_rec.base_code;   -- DFF5(���_�R�[�h)
      lt_attribute6       := forecast_if_rec.case_count;  -- DFF6(�v�搔��)
      lt_creation_date    := cd_creation_date;            -- �쐬��
      lt_created_by       := cn_created_by;               -- �쐬��
    ELSE
      -- �X�V�̏ꍇ
      IF ( ln_forecast_quantity <> 0 ) THEN
        lt_attribute5     := forecast_if_rec.base_code;   -- DFF5(���_�R�[�h)
        lt_attribute6     := forecast_if_rec.case_count;  -- DFF6(�v�搔��)
      ELSE
        -- �폜�̏ꍇ
        lt_attribute5     := NULL;                        -- DFF5(���_�R�[�h)
        lt_attribute6     := NULL;                        -- DFF6(�v�搔��)
      END IF;
    END IF;
    --
    -- ���vAPI�p�����[�^�̏�����
    t_forecast_interface_tab.DELETE;
    --
    -- �p�����[�^�Z�b�g�i�t�H�[�L���X�g���t�j
    t_forecast_interface_tab(1).inventory_item_id       := forecast_if_rec.inventory_item_id;     -- �i��ID
    t_forecast_interface_tab(1).forecast_designator     := forecast_if_rec.forecast_designator;   -- �t�H�[�L���X�g��
    t_forecast_interface_tab(1).organization_id         := gt_master_org_id;                      -- �}�X�^�g�DID
    t_forecast_interface_tab(1).forecast_date           := forecast_if_rec.forecast_date;         -- �t�H�[�L���X�g���t
    t_forecast_interface_tab(1).last_update_date        := cd_last_update_date;                   -- �ŏI�X�V��
    t_forecast_interface_tab(1).last_updated_by         := cn_last_updated_by;                    -- �ŏI�X�V��
    t_forecast_interface_tab(1).creation_date           := lt_creation_date;                      -- �쐬��
    t_forecast_interface_tab(1).created_by              := lt_created_by;                         -- �쐬��
    t_forecast_interface_tab(1).last_update_login       := cn_last_update_login;                  -- �ŏI�X�V���O�C��
    t_forecast_interface_tab(1).quantity                := ln_forecast_quantity;                  -- �t�H�[�L���X�g����
    t_forecast_interface_tab(1).process_status          := cn_process_status;                     -- process_status
    t_forecast_interface_tab(1).confidence_percentage   := cn_confidence_percentage;              -- confidence_percentage
    t_forecast_interface_tab(1).bucket_type             := cn_bucket_type;                        -- �o�P�b�g�E�^�C�v
    t_forecast_interface_tab(1).transaction_id          := lt_transaction_id;                     -- �g�����U�N�V����ID
    t_forecast_interface_tab(1).attribute5              := lt_attribute5;                         -- DFF5(���_)
    t_forecast_interface_tab(1).attribute6              := lt_attribute6;                         -- DFF6(�v�搔��)
--
    -- ���vAPI�̎��s
    lb_api := mrp_forecast_interface_pk.mrp_forecast_interface(
                t_forecast_interface_tab
              );
    -- �߂�l������ȊO
    IF ( t_forecast_interface_tab(1).process_status <> cn_api_ret_normal ) THEN
      -- API�N���G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application             -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00076         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_row                 -- �g�[�N���R�[�h1
                     ,iv_token_value1 => forecast_if_rec.record_no  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_prg_name            -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_api_name                -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_errmsg              -- �g�[�N���R�[�h3
                     ,iv_token_value3 => SQLERRM                    -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ��������
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
-- ********** Ver.1.1 K.Nakamura ADD Start ************ --
    -- *** �o�^�ΏۊO��O�n���h�� ***
    WHEN global_no_insert_expt THEN
      -- ���������ւ̏o�͂⃁�b�Z�[�W�o�͂��s�Ȃ�Ȃ�
      ov_retcode := cv_status_normal;
-- ********** Ver.1.1 K.Nakamura ADD End ************ --
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
  END exec_api_forecast_if;
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : �t�@�C���A�b�v���[�h�f�[�^�폜����(A-6)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
      iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- �v���O������
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
    --==============================================================
    -- �t�@�C���A�b�v���[�h�폜
    --==============================================================
    --�t�@�C���A�b�v���[�h�e�[�u���f�[�^�폜����
    xxcop_common_pkg.delete_upload_table(
        ov_retcode => lv_retcode                -- ���^�[���E�R�[�h
      , ov_errbuf  => lv_errbuf                 -- �G���[�E���b�Z�[�W
      , ov_errmsg  => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
      , in_file_id => TO_NUMBER(iv_file_id)     -- �t�@�C��ID
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- �g�[�N���l��ݒ�
      gv_tkn_1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_00079 );
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcop_00042 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                     , iv_token_value1 => gv_tkn_1           -- �g�[�N���l1
                   );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_file_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf  OUT VARCHAR2 -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode OUT VARCHAR2 -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg  OUT VARCHAR2 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
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
    lv_errbuf            VARCHAR2(5000)   DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)      DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000)   DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_validate_retcode  VARCHAR2(1)      DEFAULT cv_status_normal;  -- �Ó����`�F�b�N���^�[���E�R�[�h
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
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , iv_format  => iv_format  -- �t�H�[�}�b�g
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�擾����(A-2)
    -- ===============================================
    get_file_upload_data(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ����v��IF�\�o�^���[�v
    << ins_if_loop >>
    FOR i IN gt_file_data.FIRST .. gt_file_data.COUNT LOOP
      -- �J�E���g�A�b�v
      gn_line_cnt := gn_line_cnt + 1;
      -- ===============================================
      -- �Ó����`�F�b�N����(A-3)
      -- ===============================================
      chk_validate_item(
          iv_file_id => iv_file_id -- �t�@�C��ID
        , iv_format  => iv_format  -- �t�H�[�}�b�g
        , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      -- �Ó����`�F�b�N�G���[
      IF ( lv_retcode = cv_status_error ) THEN
        lv_validate_retcode := cv_status_error;
      END IF;
      --
    END LOOP ins_if_loop;
--
    -- �S���R�[�h�Ó����`�F�b�N��ɃG���[����
    IF ( lv_validate_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ����v��IF�\�f�[�^�擾����(A-4)
    -- ===============================================
    -- �J�[�\���I�[�v��
    OPEN forecast_if_cur( iv_file_id );
    -- �t�H�[�L���X�g���t�o�^���[�v
    << ins_forecast_loop >>
    LOOP
      -- �t�F�b�`
      FETCH forecast_if_cur INTO forecast_if_rec;
      EXIT WHEN forecast_if_cur%NOTFOUND;
      --
      -- ===============================================
      -- ���vAPI���s(A-5)
      -- ===============================================
      exec_api_forecast_if(
          ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END LOOP ins_forecast_loop;
    -- �J�[�\���N���[�Y
    CLOSE forecast_if_cur;
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
      IF ( forecast_if_cur%ISOPEN ) THEN
        CLOSE forecast_if_cur;
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
      errbuf     OUT VARCHAR2 -- �G���[�E���b�Z�[�W #�Œ�#
    , retcode    OUT VARCHAR2 -- ���^�[���E�R�[�h   #�Œ�#
    , iv_file_id IN  VARCHAR2 -- �t�@�C��ID
    , iv_format  IN  VARCHAR2 -- �t�H�[�}�b�g
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    -- ���b�Z�[�W
    cv_target_rec_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- �g�[�N��
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      , iv_file_id => iv_file_id -- �t�@�C��ID
      , iv_format  => iv_format  -- �t�H�[�}�b�g
    );
--
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
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- �t�@�C���A�b�v���[�h�f�[�^�폜����(A-6)
    -- ===============================================
    del_file_upload_data(
        iv_file_id => iv_file_id -- �t�@�C��ID
      , ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
    -- �t�@�C���A�b�v���[�h�f�[�^�폜���COMMIT
    COMMIT;
--
    -- �G���[���������݂���ꍇ
    IF ( gn_error_cnt > 0 ) THEN
      -- �G���[���̌����ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      -- �I���X�e�[�^�X���G���[�ɂ���
      lv_retcode := cv_status_error;
    ELSE
      -- �I���X�e�[�^�X�𐳏�ɂ���
      lv_retcode := cv_status_normal;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- �Ώی����o��
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
    -- ���������o��
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
    -- �G���[�����o��
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
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOP004A09C;
/
