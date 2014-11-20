CREATE OR REPLACE PACKAGE BODY xxcmn810002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn810002c(body)
 * Description      : �i�ڃ}�X�^�X�V(����)
 * MD.050           : �i�ڃ}�X�^ T_MD050_BPO_810
 * MD.070           : �i�ڃ}�X�^�X�V(����)(81B) T_MD070_BPO_81B
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_mtl_categories    �i�ڃJ�e�S���o�^����  2008/09/24 Add
 *  proc_item_category     �i�ڊ����o�^����      2008/09/24 Add
 *  parameter_check        �p�����[�^���o����                        (B-1)
 *  put_item_mst           OPM�i�ڃA�h�I���}�X�^���i�[             (B-3)
 *  put_gmi_item_g         �i�ڃJ�e�S���}�X�^���i�[(�Q�R�[�h)      (B-4)
 *  put_gmi_item_k         �i�ڃJ�e�S���}�X�^���i�[(�H��Q�R�[�h)  (B-5)
 *  update_item_mst_b      OPM�i�ڃ}�X�^���f                         (B-6)
 *  update_categories      OPM�i�ڃJ�e�S���������f                   (B-7)
 *  update_xxcmn_item      OPM�i�ڃA�h�I���}�X�^���f                 (B-8)
 *  get_sysitems_b         �i�ڃ}�X�^�擾                            (B-9)
 *  update_mtl_item_f      �i�ڃ}�X�^���f(�\��\)                  (B-10)
 *  disp_report            �������ʃ��|�[�g�o��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/12    1.0   T.Iwasa          main�V�K�쐬
 *  2008/05/02    1.1   H.Marushita      �����ύX�v��No.81�Ή�
 *  2008/05/20    1.2   H.Marushita      �����ύX�v��No.105�Ή�
 *  2008/09/11    1.3   Oracle �R����_  �w�E115�Ή�
 *  2008/09/24    1.4   Oracle �R����_  T_S_421�Ή�
 *  2008/09/29    1.5   Oracle �R����_  T_S_546,T_S_547�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  parameter_expt         EXCEPTION;               -- �p�����[�^��O
  lock_expt              EXCEPTION;               -- ���b�N�擾��O
  profile_expt           EXCEPTION;               -- �v���t�@�C���擾�G���[
  no_data                EXCEPTION;               -- �O������
  PRAGMA EXCEPTION_INIT(lock_expt, -54);          -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  -- �萔
  gv_pkg_name         CONSTANT VARCHAR2(15) := 'xxcmn810002c';      -- �p�b�P�[�W��
  gv_app_name         CONSTANT VARCHAR2(5)  := 'XXCMN';             -- �A�v���P�[�V�����Z�k��
                                                                    -- �v���t�@�C���F�Q�R�[�h
  gv_tkn_name_01      CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_OTGUN';
                                                                    -- �v���t�@�C���F�H��Q�R�[�h
  gv_tkn_name_02      CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_KJGUN';
                                                                    -- �v���t�@�C���F�Q�R�[�h
  gv_tkn_name_03      CONSTANT VARCHAR2(50) := '�Q�R�[�h';
                                                                    -- �v���t�@�C���F�H��Q�R�[�h
  gv_tkn_name_04      CONSTANT VARCHAR2(50) := '�H��Q�R�[�h';
--2008/09/24 Add
  gv_tkn_name_05      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_CROWD_CODE';
  gv_tkn_name_06      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_POLICY_CODE';
  gv_tkn_name_07      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_MARKET_CODE';
  gv_tkn_name_08      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_ACNT_CROWD_CODE';
  gv_tkn_name_09      CONSTANT VARCHAR2(50) := 'XXCMN_IC_DEF_FACTORY_CODE';
  gv_tkn_name_10      CONSTANT VARCHAR2(50) := '�����l�F�Q�R�[�h';
  gv_tkn_name_11      CONSTANT VARCHAR2(50) := '�����l�F����Q�R�[�h';
  gv_tkn_name_12      CONSTANT VARCHAR2(50) := '�����l�F�}�[�P�p�Q�R�[�h';
  gv_tkn_name_13      CONSTANT VARCHAR2(50) := '�����l�F�o�����p�Q�R�[�h';
  gv_tkn_name_14      CONSTANT VARCHAR2(50) := '�����l�F�H��Q�R�[�h';
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';   -- �v���t�@�C���擾�G���[
  gv_msg_xxcmn10019   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';   -- ���b�N�擾�G���[
  gv_msg_xxcmn10083   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10083';   -- �p�����[�^���t�^�`�F�b�NNG
  gv_msg_xxcmn10084   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10084';   -- �p�����[�^NULL�`�F�b�NNG
--2008/09/24 Add
  gv_msg_xxcmn10085   CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';   --API�G���[(�R���J�����g)
--
  -- �g�[�N��
  gv_tkn_table        CONSTANT VARCHAR2(10) := 'TABLE';             -- �g�[�N���F�e�[�u����
  gv_tkn_profile      CONSTANT VARCHAR2(10) := 'NG_PROFILE';        -- �g�[�N���F�v���t�@�C����
--2008/09/24 Add
  gv_tkn_api_name     CONSTANT VARCHAR2(15) := 'API_NAME';          -- �g�[�N���FAPI��
--
  gn_data_status_nomal  CONSTANT  NUMBER := 0;                      -- ����
  gn_data_status_error  CONSTANT  NUMBER := 1;                      -- �ُ�
--2008/09/24 Add
  gn_proc_flg_01        CONSTANT  NUMBER := 1;                      -- �S�R�[�h
  gn_proc_flg_02        CONSTANT  NUMBER := 2;                      -- �H��Q�R�[�h
--
  gv_crowd_code         CONSTANT VARCHAR2(50) := '�Q�R�[�h';
  gv_policy_group_code  CONSTANT VARCHAR2(50) := '����Q�R�[�h';
  gv_marke_crowd_code   CONSTANT VARCHAR2(50) := '�}�[�P�p�Q�R�[�h';
  gv_acnt_crowd_code    CONSTANT VARCHAR2(50) := '�o�����p�Q�R�[�h';
  gv_factory_code       CONSTANT VARCHAR2(50) := '�H��Q�R�[�h';
--2008/09/24 Add
--
  -- xxcmn���ʊ֐����^�[���E�R�[�h�F1(�G���[)
  gn_rel_code         CONSTANT NUMBER       := 1;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  -- OPM�i�ڃ}�X�^�Q�擾���R�[�h
  TYPE master_item01_rec IS RECORD(
    -- OPM�i�ڃ}�X�^
    item_id             ic_item_mst_b.item_id%TYPE,                     -- �i��ID(OPM�i�ڃ}�X�^)
    item_no             ic_item_mst_b.item_no%TYPE,                     -- �i��
    attribute2          ic_item_mst_b.attribute2%TYPE,                  -- �V�E�Q�R�[�h
    -- OPM�i�ڃA�h�I���}�X�^
    start_date_active   xxcmn_item_mst_b.start_date_active%TYPE,        -- �K�p�J�n��
    item_name           xxcmn_item_mst_b.item_name%TYPE,                -- ������
    expiration_day      xxcmn_item_mst_b.expiration_day%TYPE,           -- �ܖ�����
    whse_county_code    xxcmn_item_mst_b.whse_county_code%TYPE          -- �H��Q�R�[�h
--2008/09/29 ��
    ,cs_weigth_or_capacity xxcmn_item_mst_b.cs_weigth_or_capacity%TYPE  -- �P�[�X�d�ʗe��
--2008/09/29 ��
  );
--
  -- OPM�i�ڃJ�e�S�������擾���R�[�h
  TYPE category_item02_rec IS RECORD(
    category_set_id     gmi_item_categories.category_set_id%TYPE,       -- �J�e�S���Z�b�gID
    category_id         gmi_item_categories.category_id%TYPE            -- �J�e�S��ID
  );
--
  -- �������ʏo�͗p���R�[�h
  TYPE report_item03_rec IS RECORD(
    item_no             ic_item_mst_b.item_no%TYPE,                     -- �i��
    attribute2          ic_item_mst_b.attribute2%TYPE,                  -- �V�E�Q�R�[�h
    start_date_active   xxcmn_item_mst_b.start_date_active%TYPE,        -- �K�p�J�n��
    expiration_day      xxcmn_item_mst_b.expiration_day%TYPE,           -- �ܖ�����
    whse_county_code    xxcmn_item_mst_b.whse_county_code%TYPE,         -- �H��Q�R�[�h
    item_name           xxcmn_item_mst_b.item_name%TYPE                 -- ������
  );
--
  -- ***************************************
  -- ***    �X�V���ڊi�[�e�[�u���^��`   ***
  -- ***************************************
  -- OPM�i�ڃ}�X�^���ڂ̃e�[�u���^��`
  -- �i��ID
  TYPE im_item_id           IS TABLE OF ic_item_mst_b.item_id           %TYPE INDEX BY BINARY_INTEGER;
  -- �E�v
  TYPE im_item_desc1        IS TABLE OF ic_item_mst_b.item_desc1        %TYPE INDEX BY BINARY_INTEGER;
  -- �ۑ�����
  TYPE im_shelf_life        IS TABLE OF ic_item_mst_b.shelf_life        %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE im_last_update_date  IS TABLE OF ic_item_mst_b.last_update_date  %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE im_last_updated_by   IS TABLE OF ic_item_mst_b.last_updated_by   %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE im_last_update_login IS TABLE OF ic_item_mst_b.last_update_login %TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE im_request_id        IS TABLE OF ic_item_mst_b.request_id        %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O����ID
  TYPE im_program_id        IS TABLE OF ic_item_mst_b.program_id        %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����A�v���P�[�V����ID
  TYPE im_program_application_id IS TABLE OF ic_item_mst_b.program_application_id %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE im_program_update_date    IS TABLE OF ic_item_mst_b.program_update_date    %TYPE INDEX BY BINARY_INTEGER;
--
  -- OPM�i�ڃA�h�I���}�X�^���ڂ̃e�[�u���^��`
  -- �i��ID
  TYPE xm_item_id           IS TABLE OF xxcmn_item_mst_b.item_id            %TYPE INDEX BY BINARY_INTEGER;
  -- �K�p�J�n��
  TYPE xm_start_date_active IS TABLE OF xxcmn_item_mst_b.start_date_active  %TYPE INDEX BY BINARY_INTEGER;
  -- �K�p�σt���O
  TYPE xm_active_flag       IS TABLE OF xxcmn_item_mst_b.active_flag        %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xm_last_update_date  IS TABLE OF xxcmn_item_mst_b.last_update_date   %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xm_last_updated_by   IS TABLE OF xxcmn_item_mst_b.last_updated_by    %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE xm_last_update_login IS TABLE OF xxcmn_item_mst_b.last_update_login  %TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE xm_request_id        IS TABLE OF xxcmn_item_mst_b.request_id         %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O����ID
  TYPE xm_program_id        IS TABLE OF xxcmn_item_mst_b.program_id         %TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����A�v���P�[�V����ID
  TYPE xm_program_application_id IS TABLE OF xxcmn_item_mst_b.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE xm_program_update_date    IS TABLE OF xxcmn_item_mst_b.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--2008/09/29 Add ��
  -- �P�[�X�d�ʗe��
  TYPE xm_cs_weigth_or_capacity IS TABLE OF xxcmn_item_mst_b.cs_weigth_or_capacity%TYPE INDEX BY BINARY_INTEGER;
--2008/09/29 Add ��
--
  -- OPM�i�ڃJ�e�S���������ڂ̃e�[�u���^��`
  -- �i��ID
  TYPE gm_item_id           IS TABLE OF gmi_item_categories.item_id           %TYPE INDEX BY BINARY_INTEGER;
  -- �J�e�S���Z�b�gID
  TYPE gm_category_set_id   IS TABLE OF gmi_item_categories.category_set_id   %TYPE INDEX BY BINARY_INTEGER;
  -- �J�e�S��ID
  TYPE gm_category_id       IS TABLE OF gmi_item_categories.category_id       %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE gm_last_updated_by   IS TABLE OF gmi_item_categories.last_updated_by   %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE gm_last_update_date  IS TABLE OF gmi_item_categories.last_update_date  %TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE gm_last_update_login IS TABLE OF gmi_item_categories.last_update_login %TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڃ}�X�^(�\��\�t���O)�̃e�[�u���^��`
  TYPE mt_inv_item_id       IS TABLE OF mtl_system_items_b.inventory_item_id  %TYPE INDEX BY BINARY_INTEGER;
--
  -- ***************************************
  -- ***      ���ڊi�[�e�[�u���^��`     ***
  -- ***************************************
--
  -- OPM�i�ڃ}�X�^�Q�i�[�p�e�[�u���^��`
  TYPE master_item01_tbl    IS TABLE OF master_item01_rec   INDEX BY PLS_INTEGER;
  -- OPM�i�ڃJ�e�S�������i�[�p�e�[�u���^��`
  TYPE master_item02_tbl    IS TABLE OF category_item02_rec INDEX BY PLS_INTEGER;
  -- �������ʃ��|�[�g�p�e�[�u��
  TYPE report_item03_tbl    IS TABLE OF report_item03_rec   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_max_date               DATE;                 -- MAX���t
  gv_applied_date           DATE;                 -- �K�p���t
  gv_group_code             VARCHAR2(20);         -- �v���t�@�C��(�J�e�S����)�F�Q�R�[�h
  gv_whse_county_code       VARCHAR2(20);         -- �v���t�@�C��(�J�e�S����)�F�H��Q�R�[�h
  gt_im_item_id             im_item_id;           -- OPM�i�ڃ}�X�^�F�i��ID
  gt_im_item_desc1          im_item_desc1;        -- OPM�i�ڃ}�X�^�F�E�v
  gt_im_shelf_life          im_shelf_life;        -- OPM�i�ڃ}�X�^�F�ۑ�����
  gt_xm_item_id             xm_item_id;           -- OPM�i�ڃA�h�I���}�X�^�F�i��ID
  gt_xm_start_date_active   xm_start_date_active; -- OPM�i�ڃA�h�I���}�X�^�F�K�p�J�n��
  gt_xm_active_flag         xm_active_flag;       -- OPM�i�ڃA�h�I���}�X�^�F�K�p�ς݃t���O
--2008/09/29 Add ��
  gt_xm_cs_wc               xm_cs_weigth_or_capacity; -- OPM�i�ڃA�h�I���}�X�^�F�P�[�X�d�ʗe��
--2008/09/29 Add ��
  gt_gm_item_id_g           gm_item_id;           -- OPM�i�ڃJ�e�S�������F�J�e�S��ID(�Q�R�[�h�p)
  gt_gm_category_set_id_g   gm_category_set_id;   -- OPM�i�ڃJ�e�S�������F�J�e�S���Z�b�gID
  gt_gm_category_id_g       gm_category_id;       -- OPM�i�ڃJ�e�S�������F�J�e�S��ID
  gt_gm_item_id_k           gm_item_id;           -- OPM�i�ڃJ�e�S�������F�J�e�S��ID(�H��Q�R�[�h�p)
  gt_gm_category_set_id_k   gm_category_set_id;   -- OPM�i�ڃJ�e�S�������F�J�e�S���Z�b�gID
  gt_gm_category_id_k       gm_category_id;       -- OPM�i�ڃJ�e�S�������F�J�e�S��ID
  gt_mt_invflg_item_id      mt_inv_item_id;       -- �i�ڃ}�X�^�F�i��ID(�\��\�t���O)
  gd_last_update_date       DATE;                 -- �ŏI�X�V��
  gv_last_update_by         VARCHAR2(100);        -- �ŏI�X�V��
  gv_last_update_login      VARCHAR2(100);        -- �ŏI�X�V���O�C��
  gv_request_id             VARCHAR2(100);        -- �v��ID
  gv_program_application_id VARCHAR2(100);        -- �v���O�����A�v���P�[�V����ID
  gv_program_id             VARCHAR2(100);        -- �v���O����ID
  gd_program_update_date    DATE;                 -- �v���O�����X�V��
--2008/09/11 Add
  -- �S�R�[�h�����l
  gv_def_crowd_code         VARCHAR2(20);         -- �����l�F�Q�R�[�h
  gv_def_policy_code        VARCHAR2(20);         -- �����l�F����Q�R�[�h
  gv_def_market_code        VARCHAR2(20);         -- �����l�F�}�[�P�p�Q�R�[�h
  gv_def_acnt_crowd_code    VARCHAR2(20);         -- �����l�F�o�����p�Q�R�[�h
  gv_def_factory_code       VARCHAR2(20);         -- �����l�F�H��Q�R�[�h
--
-- 2008/09/24 Add ��
  /***********************************************************************************
   * Procedure Name   : proc_mtl_categories
   * Description      : �i�ڃJ�e�S���̓o�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_mtl_categories(
    ir_item01_rec   IN     master_item01_rec,   -- OPM�i�ڃ}�X�^���R�[�h
    in_proc_flg     IN     NUMBER,              -- �����t���O
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_mtl_categories'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lang                 CONSTANT VARCHAR2(5)    := USERENV('LANG');                    -- ���{��
--
    -- *** ���[�J���ϐ� ***
    ln_category_set_id     mtl_category_sets_b.category_set_id%TYPE;
    ln_structure_id        mtl_category_sets_b.structure_id%TYPE;
    lv_category_set_name   mtl_category_sets_tl.category_set_name%TYPE;
    lr_category_rec        INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
    ln_category_id         NUMBER;
    lv_return_status       VARCHAR2(30);
    ln_errorcode           NUMBER;
    ln_msg_count           NUMBER;
    lv_msg_data            VARCHAR2(2000);
    lv_api_name            VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �S�R�[�h
    IF (in_proc_flg = gn_proc_flg_01) THEN
      lv_category_set_name := gv_group_code;
--
    -- �H��S�R�[�h
    ELSIF (in_proc_flg = gn_proc_flg_02) THEN
      lv_category_set_name := gv_whse_county_code;
    END IF;
--
    BEGIN
      SELECT mcsb.category_set_id,                  -- �J�e�S���Z�b�gID
             mcsb.structure_id                      -- �\��ID
      INTO   ln_category_set_id,
             ln_structure_id
      FROM   mtl_category_sets_b   mcsb,
             mtl_category_sets_tl  mcst
      WHERE  mcsb.category_set_id   = mcst.category_set_id
      AND    mcst.language          = cv_lang
      AND    mcst.source_lang       = cv_lang
      AND    mcst.category_set_name = lv_category_set_name;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_others_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    lr_category_rec.structure_id := ln_structure_id;
--
    -- �S�R�[�h
    IF (in_proc_flg = 1) THEN
      lr_category_rec.segment1     := ir_item01_rec.attribute2;
    -- �H��S�R�[�h
    ELSIF (in_proc_flg = 2) THEN
      lr_category_rec.segment1     := ir_item01_rec.whse_county_code;
    END IF;
--
    lr_category_rec.summary_flag := 'N';
    lr_category_rec.enabled_flag := 'Y';
--
    lr_category_rec.web_status := NULL;
    lr_category_rec.supplier_enabled_flag := NULL;
--
    -- �i�ڃJ�e�S���}�X�^�o�^
    INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY(
       P_API_VERSION      => 1.0
      ,P_INIT_MSG_LIST    => FND_API.G_FALSE
      ,P_COMMIT           => FND_API.G_FALSE
      ,X_RETURN_STATUS    => lv_return_status
      ,X_ERRORCODE        => ln_errorcode
      ,X_MSG_COUNT        => ln_msg_count
      ,X_MSG_DATA         => lv_msg_data
      ,P_CATEGORY_REC     => lr_category_rec
      ,X_CATEGORY_ID      => ln_category_id
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_msg_xxcmn10085,
                                            gv_tkn_api_name,
                                            lv_api_name);
--
      lv_msg_data := lv_errmsg;
--
      xxcmn_common_pkg.put_api_log(
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      lv_errmsg := lv_msg_data;
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    -- �S�R�[�h
    IF (in_proc_flg = gn_proc_flg_01) THEN
      gt_gm_item_id_g(gn_target_cnt)         := ir_item01_rec.item_id;
      gt_gm_category_set_id_g(gn_target_cnt) := ln_category_set_id;
      gt_gm_category_id_g(gn_target_cnt)     := ln_category_id;
--
    -- �H��S�R�[�h
    ELSIF (in_proc_flg = gn_proc_flg_02) THEN
      gt_gm_item_id_k(gn_target_cnt)         := ir_item01_rec.item_id;
      gt_gm_category_set_id_k(gn_target_cnt) := ln_category_set_id;
      gt_gm_category_id_k(gn_target_cnt)     := ln_category_id;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_mtl_categories;
--
  /***********************************************************************************
   * Procedure Name   : proc_item_category
   * Description      : �i�ڊ����̓o�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_item_category(
    ir_item01_rec   IN     master_item01_rec,   -- OPM�i�ڃ}�X�^���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_item_category'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lang                 CONSTANT VARCHAR2(5)    := USERENV('LANG');             -- ���{��
--
    -- *** ���[�J���ϐ� ***
    ln_cnt            NUMBER;
    ln_category_id    mtl_categories_b.category_id%TYPE;
    lv_segment1       mtl_categories_b.segment1%TYPE;
    lt_category_rec   INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_errorcode      NUMBER;
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_api_name       VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR category_cur
    IS
       SELECT mcsb.category_set_id,
              mcst.description,
              mcsb.structure_id
       FROM   mtl_category_sets_tl mcst,
              mtl_category_sets_b  mcsb
       WHERE  mcsb.category_set_id = mcst.category_set_id
       AND    mcst.language        = cv_lang
       AND    mcst.source_lang     = cv_lang
       AND    mcst.description IN (
                                   gv_crowd_code,              -- �Q�R�[�h
                                   gv_policy_group_code,       -- ����Q�R�[�h
                                   gv_marke_crowd_code,        -- �}�[�P�p�Q�R�[�h
                                   gv_acnt_crowd_code          -- �o�����p�Q�R�[�h
--2008/09/29 Mod ��
/*
                                   gv_acnt_crowd_code,         -- �o�����p�Q�R�[�h
                                   gv_factory_code             -- �H��Q�R�[�h
*/
--2008/09/29 Mod ��
                                  )
       ;
--
    -- *** ���[�J���E���R�[�h ***
    lr_category_rec category_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN category_cur;
--
    <<category_loop>>
    LOOP
      FETCH category_cur INTO lr_category_rec;
      EXIT WHEN category_cur%NOTFOUND;
--
      BEGIN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   gmi_item_categories  gic
        WHERE  gic.item_id         = ir_item01_rec.item_id
        AND    gic.category_set_id = lr_category_rec.category_set_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_cnt := 0;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- ���݂��Ȃ�
      IF (ln_cnt = 0) THEN
--
        lt_category_rec.structure_id := lr_category_rec.structure_id;
--
        -- �Q�R�[�h
        IF (lr_category_rec.description = gv_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_crowd_code;
--
        -- ����Q�R�[�h
        ELSIF (lr_category_rec.description = gv_policy_group_code) THEN
          lt_category_rec.segment1 := gv_def_policy_code;
--
        -- �}�[�P�p�Q�R�[�h
        ELSIF (lr_category_rec.description = gv_marke_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_market_code;
--
        -- �o�����p�Q�R�[�h
        ELSIF (lr_category_rec.description = gv_acnt_crowd_code) THEN
          lt_category_rec.segment1 := gv_def_acnt_crowd_code;
--2008/09/29 Mod ��
/*
--
        -- �H��Q�R�[�h
        ELSIF (lr_category_rec.description = gv_factory_code) THEN
          lt_category_rec.segment1 := gv_def_factory_code;
*/
--2008/09/29 Mod ��
        END IF;
--
        lt_category_rec.summary_flag := 'N';
        lt_category_rec.enabled_flag := 'Y';
--
        lt_category_rec.web_status := NULL;
        lt_category_rec.supplier_enabled_flag := NULL;
--
        BEGIN
          SELECT COUNT(1)
          INTO   ln_cnt
          FROM   mtl_categories_b mcb
          WHERE  mcb.structure_id = lt_category_rec.structure_id
          AND    mcb.segment1     = lt_category_rec.segment1
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_cnt := 0;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        -- ���݂��Ȃ�
        IF (ln_cnt = 0) THEN
--
          -- �i�ڃJ�e�S���}�X�^�o�^
          INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY(
             P_API_VERSION      => 1.0
            ,P_INIT_MSG_LIST    => FND_API.G_FALSE
            ,P_COMMIT           => FND_API.G_FALSE
            ,X_RETURN_STATUS    => lv_return_status
            ,X_ERRORCODE        => ln_errorcode
            ,X_MSG_COUNT        => ln_msg_count
            ,X_MSG_DATA         => lv_msg_data
            ,P_CATEGORY_REC     => lt_category_rec
            ,X_CATEGORY_ID      => ln_category_id
          );
--
          -- ���s
          IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            lv_api_name := 'INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY';
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                                  gv_msg_xxcmn10085,
                                                  gv_tkn_api_name,
                                                  lv_api_name);
--
            lv_msg_data := lv_errmsg;
--
            xxcmn_common_pkg.put_api_log(
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            lv_errmsg := lv_msg_data;
            lv_errbuf := lv_msg_data;
            RAISE global_api_expt;
          END IF;
--
        -- ���݂���
        ELSE
          BEGIN
            SELECT mcb.category_id
            INTO   ln_category_id
            FROM   mtl_categories_b mcb
            WHERE  mcb.structure_id = lt_category_rec.structure_id
            AND    mcb.segment1     = lt_category_rec.segment1
            ;
          EXCEPTION
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
--
        -- ���݃`�F�b�N
        BEGIN
          SELECT COUNT(1)
          INTO   ln_cnt
          FROM   gmi_item_categories
          WHERE  item_id         = ir_item01_rec.item_id
          AND    category_set_id = lr_category_rec.category_set_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_cnt := 0;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
--
        -- ���݂��Ȃ�
        IF (ln_cnt = 0) THEN
          INSERT INTO gmi_item_categories
             (item_id
             ,category_set_id
             ,category_id
             ,created_by
             ,creation_date
             ,last_updated_by
             ,last_update_date
             ,last_update_login)
          VALUES (
              ir_item01_rec.item_id
             ,lr_category_rec.category_set_id
             ,ln_category_id
             ,TO_NUMBER(gv_last_update_by)
             ,gd_last_update_date
             ,TO_NUMBER(gv_last_update_by)
             ,gd_last_update_date
             ,TO_NUMBER(gv_last_update_login)
          );
        END IF;
--
--        gt_gm_item_id_g(gn_target_cnt)         := ir_item01_rec.item_id;
--        gt_gm_category_set_id_g(gn_target_cnt) := lr_category_rec.category_set_id;
--        gt_gm_category_id_g(gn_target_cnt)     := ln_category_id;
      END IF;
--
    END LOOP category_loop;
--
    CLOSE category_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\�����J���Ă����
      IF (category_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE category_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����J���Ă����
      IF (category_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE category_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����J���Ă����
      IF (category_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE category_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_item_category;
--
-- 2008/09/24 Add ��
--
  /**********************************************************************************
   * Procedure Name   : parameter_check
   * Description      : �p�����[�^���o����(B-1)
   ***********************************************************************************/
  PROCEDURE parameter_check(
    iv_applied_date     IN     VARCHAR2,                -- �K�p���t
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_check';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_applied_date         CONSTANT VARCHAR2(20)   := '�K�p���t';              -- �p�����[�^���F�K�p���t
--
    -- *** ���[�J���ϐ� ***
    lv_applied_date         VARCHAR2(10)            := iv_applied_date;         -- �K�p���t
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***         ���tNULL�`�F�b�N        ***
    -- ***************************************
    -- �K�p���t
    IF (lv_applied_date IS NULL) THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10084   -- ���b�Z�[�W�FAPP-XXCMN-10084 �p�����[�^NULL�`�F�b�NNG
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
    END IF;
--
    -- ***************************************
    -- ***          ���t�^�`�F�b�N         ***
    -- ***************************************
    -- �K�p���t
    IF (lv_applied_date IS NOT NULL) THEN
      IF (xxcmn_common_pkg.check_param_date_yyyymmdd(lv_applied_date) = gn_rel_code) THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                              gv_app_name,      -- �A�v���P�[�V�����Z�k���FXXCMN ����
                              gv_msg_xxcmn10083 -- ���b�Z�[�W�FAPP-XXCMN-10083 �p�����[�^���t�^�`�F�b�NNG
                            ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
--
      ELSE
        gv_applied_date := FND_DATE.STRING_TO_DATE(lv_applied_date,'YYYY/MM/DD HH24:MI:SS');
      END IF;
--
    END IF;
--
    -- �v���t�@�C���F�Q�R�[�h�̎擾
    gv_group_code := FND_PROFILE.VALUE(gv_tkn_name_01);
    -- �擾�G���[��
    IF (gv_group_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_03      -- �Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- �v���t�@�C���F�H��Q�R�[�h�̎擾
    gv_whse_county_code := FND_PROFILE.VALUE(gv_tkn_name_02);
    -- �擾�G���[��
    IF (gv_whse_county_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_04      -- �H��Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
--2008/09/24 Add ��
--
    -- �v���t�@�C���F�����l�F�Q�R�[�h�̎擾
    gv_def_crowd_code := FND_PROFILE.VALUE(gv_tkn_name_05);
    -- �擾�G���[��
    IF (gv_def_crowd_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_10      -- �����l�F�Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- �v���t�@�C���F�����l�F����Q�R�[�h�̎擾
    gv_def_policy_code := FND_PROFILE.VALUE(gv_tkn_name_06);
    -- �擾�G���[��
    IF (gv_def_policy_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_11      -- �����l�F����Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- �v���t�@�C���F�����l�F�}�[�P�p�Q�R�[�h�̎擾
    gv_def_market_code := FND_PROFILE.VALUE(gv_tkn_name_07);
    -- �擾�G���[��
    IF (gv_def_market_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_12      -- �����l�F�}�[�P�p�Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- �v���t�@�C���F�����l�F�o�����p�Q�R�[�h�̎擾
    gv_def_acnt_crowd_code := FND_PROFILE.VALUE(gv_tkn_name_08);
    -- �擾�G���[��
    IF (gv_def_acnt_crowd_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_13      -- �����l�F�o�����p�Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--
    -- �v���t�@�C���F�����l�F�H��Q�R�[�h�̎擾
    gv_def_factory_code := FND_PROFILE.VALUE(gv_tkn_name_09);
    -- �擾�G���[��
    IF (gv_def_factory_code IS NULL) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10002,  -- ���b�Z�[�W�FAPP-XXCMN-10002 �v���t�@�C���擾�G���[
                            gv_tkn_profile,     -- �g�[�N���FNG_PROFILE
                            gv_tkn_name_14      -- �����l�F�H��Q�R�[�h
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE profile_expt;
    END IF;
--2008/09/24 Add ��
--
    -- WHO�J�����̎擾
    gd_last_update_date       :=  SYSDATE;
    gv_last_update_by         :=  fnd_global.user_id;
    gv_last_update_login      :=  fnd_global.login_id;
    gv_request_id             :=  fnd_global.conc_request_id;
    gv_program_application_id :=  fnd_global.prog_appl_id;
    gv_program_id             :=  fnd_global.conc_program_id;
    gd_program_update_date    :=  SYSDATE;
--
  EXCEPTION
    WHEN parameter_expt THEN                            --*** �p�����[�^��O ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN profile_expt THEN                              --*** �v���t�@�C���擾�G���[ ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END parameter_check;
--
  /**********************************************************************************
   * Procedure Name   : get_sysitems_b
   * Description      : �i�ڃ}�X�^�擾(B-9)
   ***********************************************************************************/
  PROCEDURE get_sysitems_b(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'get_sysitems_b';        -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_reservable_type_def  CONSTANT VARCHAR2(1)    := '1';                     -- �\��t���OON
    cv_tbl_name             CONSTANT VARCHAR2(50)   := '�i�ڃ}�X�^';            -- �e�[�u����
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***          �i�ڃ}�X�^�擾         ***
    -- ***************************************
    SELECT msib.inventory_item_id                 -- �i��ID
    BULK COLLECT INTO gt_mt_invflg_item_id
    FROM mtl_system_items_b msib
    WHERE msib.reservable_type = TO_NUMBER(cv_reservable_type_def)
    FOR UPDATE NOWAIT;
--
    -- �i�ڃ}�X�^�̎擾�����`�F�b�N
    IF (gt_mt_invflg_item_id.count = 0) THEN
      ov_retcode := gv_status_warn;
    END IF;

  EXCEPTION
    WHEN lock_expt THEN                                 --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10019,  -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                            gv_tkn_table,       -- �g�[�N��TABLE
                            cv_tbl_name         -- �e�[�u�����F�i�ڃ}�X�^
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sysitems_b;
--
  /**********************************************************************************
   * Procedure Name   : put_item_mst
   * Description      : OPM�i�ڃA�h�I���}�X�^���i�[(B-3)
   ***********************************************************************************/
  PROCEDURE put_item_mst(
    ir_item01_rec       IN     master_item01_rec,       -- OPM�i�ڃ}�X�^���R�[�h
    ir_report_tbl       IN OUT NOCOPY report_item03_tbl,-- OPM�i�ڃ}�X�^���|�[�g�p�e�[�u��
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_item_mst';          -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_active_flag_y        CONSTANT VARCHAR2(1)    := 'Y';                     -- �K�p�σt���O
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        OPM�i�ڃ}�X�^�i�[        ***
    -- ***************************************
    IF (ir_item01_rec.item_id IS NOT NULL) THEN
      gt_im_item_id(gn_target_cnt)    := ir_item01_rec.item_id;
      gt_im_item_desc1(gn_target_cnt) := ir_item01_rec.item_name;
      gt_im_shelf_life(gn_target_cnt) := ir_item01_rec.expiration_day;
      -- OPM�i�ڃ}�X�^���|�[�g�p�i�[
      ir_report_tbl(gn_target_cnt).item_no    := ir_item01_rec.item_no;
      ir_report_tbl(gn_target_cnt).attribute2 := ir_item01_rec.attribute2;
--
    -- ***************************************
    -- ***    OPM�i�ڃA�h�I���}�X�^�i�[    ***
    -- ***************************************
      gt_xm_item_id(gn_target_cnt)           := ir_item01_rec.item_id;
      gt_xm_start_date_active(gn_target_cnt) := ir_item01_rec.start_date_active;
      gt_xm_active_flag(gn_target_cnt)       := cv_active_flag_y;
--2008/09/29 Add ��
      gt_xm_cs_wc(gn_target_cnt)             := ir_item01_rec.cs_weigth_or_capacity;
--2008/09/29 Add ��
      -- OPM�i�ڃA�h�I���}�X�^���|�[�g�p�i�[
      ir_report_tbl(gn_target_cnt).start_date_active := ir_item01_rec.start_date_active;
      ir_report_tbl(gn_target_cnt).item_name         := ir_item01_rec.item_name;
      ir_report_tbl(gn_target_cnt).expiration_day    := ir_item01_rec.expiration_day;
      ir_report_tbl(gn_target_cnt).whse_county_code  := ir_item01_rec.whse_county_code;
    END IF;
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_item_mst;
--
  /**********************************************************************************
   * Procedure Name   : put_gmi_item_g
   * Description      : �i�ڃJ�e�S���}�X�^���i�[(�Q�R�[�h)(B-4)
   ***********************************************************************************/
  PROCEDURE put_gmi_item_g(
    ir_item01_rec       IN     master_item01_rec,       -- OPM�i�ڃ}�X�^���R�[�h
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_gmi_item_g';        -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'OPM�i�ڃJ�e�S������';   -- �e�[�u����
    cv_lang                 CONSTANT VARCHAR2(5)    := 'JA';                    -- ���{��
    cv_enabled_flag         CONSTANT VARCHAR2(5)    := 'Y';                     -- �L��
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_categ_off_rec        category_item02_rec;            -- OPM�i�ڃJ�e�S���������f�p�e�[�u��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***  OPM�i�ڃJ�e�S������(�Q�R�[�h)  ***
    -- ***************************************
    SELECT mcsb.category_set_id,                  -- �J�e�S���Z�b�gID
           mcb.category_id                        -- �J�e�S��ID
    INTO lr_categ_off_rec
    FROM mtl_category_sets_b   mcsb,
         mtl_category_sets_tl  mcst,
         mtl_categories_b      mcb,
         mtl_categories_tl     mct
    WHERE mcsb.category_set_id   = mcst.category_set_id
    AND   mcst.language          = cv_lang
    AND   mcst.source_lang       = cv_lang
    AND   mcst.category_set_name = gv_group_code
    AND   mcsb.structure_id      = mcb.structure_id
    AND   mcb.category_id        = mct.category_id
    AND   mct.language           = cv_lang
    AND   mct.source_lang        = cv_lang
    AND   mcb.segment1           = ir_item01_rec.attribute2
    AND   mcb.enabled_flag       = cv_enabled_flag
    AND   mcb.disable_date IS NULL
    FOR UPDATE NOWAIT;
--
    -- �J�e�S�����ݒ�
    gt_gm_item_id_g(gn_target_cnt)         := ir_item01_rec.item_id;
    gt_gm_category_set_id_g(gn_target_cnt) := lr_categ_off_rec.category_set_id;
    gt_gm_category_id_g(gn_target_cnt)     := lr_categ_off_rec.category_id;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10019,  -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                            gv_tkn_table,       -- �g�[�N��TABLE
                            cv_tbl_name         -- �e�[�u�����FOPM�i�ڃJ�e�S������
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_gmi_item_g;
--
  /**********************************************************************************
   * Procedure Name   : put_gmi_item_k
   * Description      : �i�ڃJ�e�S���}�X�^���i�[(�H��Q�R�[�h)(B-5)
   ***********************************************************************************/
  PROCEDURE put_gmi_item_k(
    ir_item01_rec       IN     master_item01_rec,       -- OPM�i�ڃ}�X�^���R�[�h
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'put_gmi_item_k';        -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'OPM�i�ڃJ�e�S������';   -- �e�[�u����
    cv_lang                 CONSTANT VARCHAR2(5)    := 'JA';                    -- ���{��
    cv_enabled_flag         CONSTANT VARCHAR2(5)    := 'Y';                     -- �L��
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lr_categ_off_rec        category_item02_rec;            -- OPM�i�ڃJ�e�S���������f�p�e�[�u��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***OPM�i�ڃJ�e�S������(�H��Q�R�[�h)***
    -- ***************************************
    SELECT mcsb.category_set_id,                  -- �J�e�S���Z�b�gID
           mcb.category_id                        -- �J�e�S��ID
    INTO lr_categ_off_rec
    FROM mtl_category_sets_b   mcsb,
         mtl_category_sets_tl  mcst,
         mtl_categories_b      mcb,
         mtl_categories_tl     mct
    WHERE mcsb.category_set_id   = mcst.category_set_id
    AND   mcst.language          = cv_lang
    AND   mcst.source_lang       = cv_lang
    AND   mcst.category_set_name = gv_whse_county_code
    AND   mcsb.structure_id      = mcb.structure_id
    AND   mcb.category_id        = mct.category_id
    AND   mct.language           = cv_lang
    AND   mct.source_lang        = cv_lang
    AND   mcb.segment1           = ir_item01_rec.whse_county_code
    AND   mcb.enabled_flag       = cv_enabled_flag
    AND   mcb.disable_date IS NULL
    FOR UPDATE NOWAIT;
--
    -- �J�e�S�����ݒ�
    gt_gm_item_id_k(gn_target_cnt)         := ir_item01_rec.item_id;
    gt_gm_category_set_id_k(gn_target_cnt) := lr_categ_off_rec.category_set_id;
    gt_gm_category_id_k(gn_target_cnt)     := lr_categ_off_rec.category_id;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10019,  -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                            gv_tkn_table,       -- �g�[�N��TABLE
                            cv_tbl_name         -- �e�[�u�����FOPM�i�ڃJ�e�S������
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN NO_DATA_FOUND THEN
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_gmi_item_k;
--
  /**********************************************************************************
   * Procedure Name   : update_item_mst_b
   * Description      : OPM�i�ڃ}�X�^���f(B-6)
   ***********************************************************************************/
  PROCEDURE update_item_mst_b(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_item_mst_b';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***      OPM�i�ڃ}�X�^�ꊇ�X�V      ***
    -- ***************************************
    FORALL item_cnt IN 1 .. gt_im_item_id.COUNT
      -- OPM�i�ڃ}�X�^�X�V
      UPDATE ic_item_mst_b iimb
      SET iimb.item_desc1             = gt_im_item_desc1(item_cnt),
          iimb.shelf_life             = NVL(gt_im_shelf_life(item_cnt),iimb.shelf_life),
          iimb.last_updated_by        = TO_NUMBER(gv_last_update_by),
          iimb.last_update_date       = gd_last_update_date,
          iimb.last_update_login      = TO_NUMBER(gv_last_update_login),
          iimb.request_id             = TO_NUMBER(gv_request_id),
          iimb.program_application_id = TO_NUMBER(gv_program_application_id),
          iimb.program_id             = TO_NUMBER(gv_program_id),
          iimb.program_update_date    = gd_program_update_date
      WHERE iimb.item_id = gt_im_item_id(item_cnt);
--
    -- 1.1 �����ύX�v��No.81�Ή�
    FORALL item_cnt IN 1 .. gt_im_item_id.COUNT
      -- OPM�i�ڃ}�X�^�iTL�j�X�V
      UPDATE ic_item_mst_tl iimt
      SET iimt.item_desc1             = gt_im_item_desc1(item_cnt),
          iimt.last_updated_by        = TO_NUMBER(gv_last_update_by),
          iimt.last_update_date       = gd_last_update_date,
          iimt.last_update_login      = TO_NUMBER(gv_last_update_login)
      WHERE iimt.item_id = gt_im_item_id(item_cnt)
      AND   iimt.language = USERENV('LANG');
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_item_mst_b;
--
  /**********************************************************************************
   * Procedure Name   : update_categories
   * Description      : OPM�i�ڃJ�e�S���������f(B-7)
   ***********************************************************************************/
  PROCEDURE update_categories(
    iv_ret_g            IN     VARCHAR2,
    iv_ret_k            IN     VARCHAR2,
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_categories';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***   OPM�i�ڃJ�e�S�������ꊇ�X�V   ***
    -- ***************************************
    -- �Q�R�[�h�̃J�e�S���X�V
    IF (iv_ret_g = gv_status_normal) THEN
      FORALL gun_cnt IN INDICES OF gt_gm_item_id_g
        -- �Q�R�[�h�X�V
        UPDATE gmi_item_categories gic
        SET gic.category_id       = gt_gm_category_id_g(gun_cnt),
            gic.last_updated_by   = TO_NUMBER(gv_last_update_by),
            gic.last_update_date  = gd_last_update_date,
            gic.last_update_login = TO_NUMBER(gv_last_update_login)
        WHERE gic.item_id         = gt_gm_item_id_g(gun_cnt)
        AND   gic.category_set_id = gt_gm_category_set_id_g(gun_cnt);
    END IF;
--2008/09/29 Mod ��
/*
--
    -- �H��Q�R�[�h�̃J�e�S���X�V
    IF (iv_ret_k = gv_status_normal) THEN
      FORALL kgun_cnt IN INDICES OF gt_gm_item_id_k
        -- �H��Q�R�[�h�X�V
        UPDATE gmi_item_categories gic
        SET gic.category_id       = gt_gm_category_id_k(kgun_cnt),
            gic.last_updated_by   = TO_NUMBER(gv_last_update_by),
            gic.last_update_date  = gd_last_update_date,
            gic.last_update_login = TO_NUMBER(gv_last_update_login)
        WHERE gic.item_id         = gt_gm_item_id_k(kgun_cnt)
        AND   gic.category_set_id = gt_gm_category_set_id_k(kgun_cnt);
    END IF;
*/
--2008/09/29 Mod ��
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_categories;
--
  /**********************************************************************************
   * Procedure Name   : update_xxcmn_item
   * Description      : OPM�i�ڃA�h�I���}�X�^���f(B-8)
   ***********************************************************************************/
  PROCEDURE update_xxcmn_item(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_xxcmn_item';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***  OPM�i�ڃA�h�I���}�X�^�ꊇ�X�V  ***
    -- ***************************************
    -- OPM�i�ڃA�h�I���}�X�^���`�F�b�N
    FORALL item_cnt IN 1 .. gt_xm_item_id.COUNT
      -- OPM�i�ڃA�h�I���}�X�^�X�V
      UPDATE xxcmn_item_mst_b ximb
      SET ximb.active_flag            = gt_xm_active_flag(item_cnt),
--2008/09/29 Add ��
          ximb.cs_weigth_or_capacity  = gt_xm_cs_wc(item_cnt),
--2008/09/29 Add ��
          ximb.last_updated_by        = TO_NUMBER(gv_last_update_by),
          ximb.last_update_date       = gd_last_update_date,
          ximb.last_update_login      = TO_NUMBER(gv_last_update_login),
          ximb.request_id             = TO_NUMBER(gv_request_id),
          ximb.program_application_id = TO_NUMBER(gv_program_application_id),
          ximb.program_id             = TO_NUMBER(gv_program_id),
          ximb.program_update_date    = gd_program_update_date
      WHERE ximb.item_id           = gt_xm_item_id(item_cnt)
      AND   ximb.start_date_active = gt_xm_start_date_active(item_cnt);
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_xxcmn_item;
--
  /**********************************************************************************
   * Procedure Name   : update_mtl_item_f
   * Description      : �i�ڃ}�X�^���f(�\��\)(B-10)
   ***********************************************************************************/
  PROCEDURE update_mtl_item_f(
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'update_mtl_item_f';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
-- 2008/09/11 Mod ��
/*
    cv_reservable_type_def  CONSTANT VARCHAR2(1)    := '0';                     -- �\��t���OOFF
*/
    cv_reservable_type_on   CONSTANT NUMBER    := 1;                     -- �\��t���OON
    cv_reservable_type_off  CONSTANT NUMBER    := 0;                     -- �\��t���OOFF
-- 2008/09/11 Mod ��
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �i�ڃ}�X�^�ꊇ�X�V       ***
    -- ***************************************
-- 2008/09/11 Mod ��
/*
      <<update_item_loop>>
      FORALL item_cnt IN 1 .. gt_mt_invflg_item_id.COUNT
        -- �i�ڃ}�X�^�X�V(�\��t���OOFF)
        UPDATE mtl_system_items_b msib
        SET msib.reservable_type        = cv_reservable_type_def,
            msib.last_updated_by        = TO_NUMBER(gv_last_update_by),
            msib.last_update_date       = gd_last_update_date,
            msib.last_update_login      = TO_NUMBER(gv_last_update_login),
            msib.request_id             = TO_NUMBER(gv_request_id),
            msib.program_application_id = TO_NUMBER(gv_program_application_id),
            msib.program_id             = TO_NUMBER(gv_program_id),
            msib.program_update_date    = gd_program_update_date
        WHERE msib.inventory_item_id = gt_mt_invflg_item_id(item_cnt);
*/
    -- �i�ڃ}�X�^�X�V(�\��t���OOFF)
    UPDATE mtl_system_items_b msib
    SET msib.reservable_type        = cv_reservable_type_off,
        msib.last_updated_by        = TO_NUMBER(gv_last_update_by),
        msib.last_update_date       = gd_last_update_date,
        msib.last_update_login      = TO_NUMBER(gv_last_update_login),
        msib.request_id             = TO_NUMBER(gv_request_id),
        msib.program_application_id = TO_NUMBER(gv_program_application_id),
        msib.program_id             = TO_NUMBER(gv_program_id),
        msib.program_update_date    = gd_program_update_date
    WHERE msib.reservable_type = 1;
--    WHERE msib.reservable_type = cv_reservable_type_on;   -- 2008/09/11 Del
-- 2008/09/11 Mod ��
--
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_mtl_item_f;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : �������ʃ��|�[�g�o��
   ***********************************************************************************/
  PROCEDURE disp_report(
    ir_report_tbl       IN     report_item03_tbl,       -- OPM�i�ڃ}�X�^���|�[�g�p�e�[�u��
    disp_kbn            IN     NUMBER,                  -- �敪(0:����,1:�ُ�)
    ov_errbuf           OUT    NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'disp_report';           -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_dspbuf               VARCHAR2(5000);                                     -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �������ʃ��|�[�g�̏o��
    <<disp_report_loop>>
    FOR report_cnt IN ir_report_tbl.first .. ir_report_tbl.last
    LOOP
--
      --���̓f�[�^�̍č\��
      lv_dspbuf := ir_report_tbl(report_cnt).item_no||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).attribute2||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||TO_CHAR(ir_report_tbl(report_cnt).start_date_active,'YYYY/MM/DD')||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).expiration_day||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).whse_county_code||gv_msg_pnt;
      lv_dspbuf := lv_dspbuf||ir_report_tbl(report_cnt).item_name;
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
    END LOOP disp_report_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_applied_date     IN     VARCHAR2,                -- �K�p���t
    ov_errbuf           OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'submain';               -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_ret     VARCHAR2(1);     -- �i�ڃ}�X�^�擾�̃��^�[���E�R�[�h
    lv_ret_g   VARCHAR2(1);     -- OPM�i�ڃJ�e�S������(�Q�R�[�h)�擾�̃��^�[���E�R�[�h
    lv_ret_k   VARCHAR2(1);     -- OPM�i�ڃJ�e�S������(�H��Q�R�[�h)�擾�̃��^�[���E�R�[�h
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_applied_date         CONSTANT VARCHAR2(20)   := '�K�p���t';              -- �p�����[�^���F�K�p���t
    cv_active_flag_def      CONSTANT VARCHAR2(1)    := 'N';                     -- �K�p�σt���O
    cv_inactive_ind         CONSTANT VARCHAR2(1)    := '1';                     -- �����t���O
    cv_obsolete_class       CONSTANT VARCHAR2(1)    := '1';                     -- �p�~�敪
                                                                                -- �e�[�u����
    cv_tbl_name             CONSTANT VARCHAR2(50)   := 'OPM�i��-OPM�i�ڃA�h�I���}�X�^';
--
    -- *** ���[�J���ϐ� ***
    lr_report_tbl           report_item03_tbl;                                  -- OPM�i�ڃ}�X�^���|�[�g
    lr_item01_rec           master_item01_rec;                                  -- OPM�i�ڃ}�X�^�i�[�p���R�[�h
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- OPM�i�ڃ}�X�^
    CURSOR item_mst_b_cur
    IS
    SELECT   iimb.item_id,                        -- �i��ID(OPM�i�ڃ}�X�^)
             iimb.item_no,                        -- �i��
             iimb.attribute2,                     -- �V�E�Q�R�[�h
             ximb.start_date_active,              -- �K�p�J�n��
             ximb.item_name,                      -- ������
             ximb.expiration_day,                 -- �ܖ�����
             ximb.whse_county_code                -- �H��Q�R�[�h
--2008/09/29 Add ��
             ,DECODE(iimb.attribute10,
                     NULL,0,
                     '1',TO_NUMBER(NVL(iimb.attribute11,'0')) *
                     TO_NUMBER(NVL(iimb.attribute25,'0')),  --�P�[�X����*�d��
                     '2',TO_NUMBER(NVL(iimb.attribute11,'0')) *
                     TO_NUMBER(NVL(iimb.attribute16,'0'))   --�P�[�X����*�e��
                    ) cs_weigth_or_capacity
--2008/09/29 Add ��
      FROM ic_item_mst_b iimb,
           xxcmn_item_mst_b ximb
      WHERE iimb.item_id = ximb.item_id
      AND   iimb.inactive_ind <> TO_NUMBER(cv_inactive_ind)
      AND   ximb.obsolete_class <>  cv_obsolete_class
      AND   ximb.start_date_active <= TO_DATE(iv_applied_date,'YYYY/MM/DD')
      AND   ximb.end_date_active >= TO_DATE(iv_applied_date,'YYYY/MM/DD')
      AND   ximb.active_flag = cv_active_flag_def
      ORDER BY iimb.item_no,
               ximb.start_date_active
      FOR UPDATE NOWAIT;
--
    item_mst_b_rec    item_mst_b_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
    lv_ret     := gv_status_normal;
    lv_ret_g   := gv_status_normal;
    lv_ret_k   := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;

    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- B-1.�p�����[�^���o����
    -- ===============================
    parameter_check(
      iv_applied_date,    -- �K�p���t
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-2.OPM�i�ڃA�h�I���}�X�^�擾
    -- ===============================
    <<item_mst_loop>>
    FOR lr_item01_rec IN item_mst_b_cur LOOP
--
      -- ���������̃J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- =================================
      -- B-3.OPM�i�ڃA�h�I���}�X�^���i�[
      -- =================================
      put_item_mst(
        lr_item01_rec,      -- OPM�i�ڃ}�X�^�Q�擾���R�[�h
        lr_report_tbl,      -- OPM�i�ڃ}�X�^���|�[�g�p�e�[�u��
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- B-4.�i�ڃJ�e�S���}�X�^���i�[(�Q�R�[�h)
      -- ========================================
      IF (lr_item01_rec.attribute2 IS NOT NULL) THEN
        put_gmi_item_g(
          lr_item01_rec,        -- OPM�i�ڃ}�X�^���R�[�h
          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
-- 2008/09/24 Mod ��
          -- �i�ڃJ�e�S���쐬
          proc_mtl_categories(
            lr_item01_rec,        -- OPM�i�ڃ}�X�^���R�[�h
            gn_proc_flg_01,       -- �����敪
            lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
/*
          lv_ret_g   := lv_retcode;
          lv_retcode := gv_status_normal;
*/
-- 2008/09/24 Mod ��
        END IF;
      END IF;
--2008/09/29 Mod ��
/*
--
      -- ============================================
      -- B-5.�i�ڃJ�e�S���}�X�^���i�[(�H��Q�R�[�h)
      -- ============================================
      IF (lr_item01_rec.whse_county_code IS NOT NULL) THEN
        put_gmi_item_k(
          lr_item01_rec,        -- OPM�i�ڃ}�X�^���R�[�h
          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = gv_status_warn) THEN
-- 2008/09/24 Mod ��
          -- �i�ڃJ�e�S���쐬
          proc_mtl_categories(
            lr_item01_rec,        -- OPM�i�ڃ}�X�^���R�[�h
            gn_proc_flg_02,       -- �����敪
            lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
*/
--2008/09/29 Mod ��
/*
          lv_ret_k   := lv_retcode;
          lv_retcode := gv_status_normal;
*/
-- 2008/09/24 Mod ��
--2008/09/29 Mod ��
/*
        END IF;
      END IF;
*/
--2008/09/29 Mod ��
--2008/09/24 Add ��
      -- �i�ڊ����쐬
      proc_item_category(
        lr_item01_rec,        -- OPM�i�ڃ}�X�^���R�[�h
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--2008/09/24 Add ��
--
    END LOOP item_mst_loop;
--
    -- ===============================
    -- B-6.OPM�i�ڃ}�X�^���f
    -- ===============================
    update_item_mst_b(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-7.OPM�i�ڃJ�e�S���������f
    -- ===============================
    update_categories(
      lv_ret_g,               -- �Q�R�[�h�擾��
      lv_ret_k,               -- �H��Q�R�[�h�擾��
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- B-8.OPM�i�ڃA�h�I���}�X�^���f
    -- ===============================
    update_xxcmn_item(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/09/11 Del ��
/*
    -- ===============================
    -- B-9.�i�ڃ}�X�^�擾
    -- ===============================
    get_sysitems_b(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
      lv_ret     := lv_retcode;
      lv_retcode := gv_status_normal;
    END IF;
*/
-- 2008/09/11 Del ��
--
    -- ===============================
    -- B-10.�i�ڃ}�X�^���f(�\��\)
    -- ===============================
/* 2008/09/11 Del ��
    IF (lv_ret = gv_status_normal) THEN
2008/09/11 Del �� */
    IF (lv_retcode = gv_status_normal) THEN
      update_mtl_item_f(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    -- ��������
    gn_normal_cnt := gn_target_cnt;
--
    -- ����I�������擾
    IF (gn_normal_cnt > 0) THEN
      -- ���O�o�͏���
      disp_report(lr_report_tbl, gn_data_status_nomal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN                                 --*** ���b�N�擾��O ***
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                            gv_app_name,        -- �A�v���P�[�V�����Z�k���FXXCMN ����
                            gv_msg_xxcmn10019,  -- ���b�Z�[�W�FAPP-XXCMN-10019 ���b�N�G���[
                            gv_tkn_table,       -- �g�[�N��TABLE
                            cv_tbl_name         -- �e�[�u�����FOPM�i��-OPM�i�ڃA�h�I���}�X�^
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf              OUT    VARCHAR2,                -- �G���[�E���b�Z�[�W           --# �Œ� #
    retcode             OUT    VARCHAR2,                -- ���^�[���E�R�[�h             --# �Œ� #
    iv_applied_date     IN     VARCHAR2)                -- �K�p���t
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'main';                  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_applied_date,       -- 1.�K�p���t
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn810002c;
/
