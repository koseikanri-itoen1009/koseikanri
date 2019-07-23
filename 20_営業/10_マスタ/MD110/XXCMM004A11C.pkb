CREATE OR REPLACE PACKAGE BODY      XXCMM004A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A11C(body)
 * Description      : �i�ڃ}�X�^IF�o�́i���n�j
 * MD.050           : �i�ڃ}�X�^IF�o�́i���n�j CMM_004_A11
 * Version          : Issue3.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            ��������(A-1)
 *
 *  submain              ���C�������v���V�[�W��
 *                          �Eproc_init
 *                       �i�ڏ��̎擾(A-2)
 *                       �i�ڃ}�X�^�i���n�j�o�͏���(A-3)
 *
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                          �Esubmain
 *                       �I������(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   R.Takigawa       main�V�K�쐬
 *  2009/01/27          H.Yoshikawa      �P�̃e�X�g���{�O�C��
 *  2009/01/29    1.1   H.Yoshikawa      �P�̃e�X�g�s��C��
 *                                       1.�G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
 *                                       2.���t�����̏����ݒ���@���C��(�X�e�b�vNo�D1-9)
 *                                       3.�Ώۃf�[�^�������G���[�I������悤�C��(�X�e�b�vNo�D1-10)
 *                                       4.�G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
 *                                       5.�擾����LOOKUP_TYPE�����C��
 *                                       6.�{�Џ��i�敪���擾�ł��Ȃ��ꍇ�̏����i9��ݒ�j���폜(�X�e�b�vNo�D2-3)
 *                                       7.�W�������̎擾�������C��(�X�e�b�vNo�D2-7)
 *                                       8.�c�ƌ���(�V)�Ɖc�ƌ���(��)�̏o�͗���C��(�X�e�b�vNo�D3-1)
 *  2009/01/30    1.2   H.Yoshikawa      �P�̃e�X�g�s��C��
 *                                       QA�Ή� �e�i�ڂ��ݒ肳��Ă��Ȃ��i�ڂ𒊏o�ΏۂƂ���悤�C��(�X�e�b�vNo�D3-1)
 *  2009/02/16    1.3   K.Ito            OUTBOUND�pCSV�t�@�C���쐬�ꏊ�A�t�@�C�������ʉ�
 *                                       �t�@�C�������o�͂���悤�ɏC��
 *  2009/05/12    1.4   H.Yoshikawa      ��QT1_0905,T1_0906�Ή�
 *  2009/06/15    1.5   H.Yoshikawa      ��QT1_1455�Ή�
 *  2010/02/02    1.6   Shigeto.Niki     E_�{�ғ�_01420�Ή� 
 *  2019/07/16    1.7   Kawaguchi.Takuya E_�{�ғ�_15472�Ή� 
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --WHO�J����
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- �Ώی���
  gn_normal_cnt                  NUMBER;                    -- ���팏��
  gn_error_cnt                   NUMBER;                    -- �G���[����
  gn_warn_cnt                    NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt            EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ���b�N�擾�G���[
  --
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCMM004A11C';       -- �p�b�P�[�W��
--
-- Ver1.3 Mod 20090216 START
  cv_appl_name_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- �A�v���P�[�V�����Z�k��
--  cv_app_name_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- �A�v���P�[�V�����Z�k��
-- Ver1.3 Mod 20090216 END
  -- ���b�Z�[�W
  cv_msg_xxcmm_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';   -- �Ώۃf�[�^�Ȃ�
  cv_msg_xxcmm_00002             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';   -- �v���t�@�C���擾�G���[
--
-- Ver1.3 Add 20090216
  cv_msg_xxcmm_00022             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';   -- CSV�t�@�C�����m�[�g
--
  cv_msg_xxcmm_00484             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00484';   -- CSV�t�@�C�����݃G���[
  cv_msg_xxcmm_00487             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00487';   -- �t�@�C���I�[�v���G���[
  cv_msg_xxcmm_00488             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00488';   -- �t�@�C���������݃G���[
  cv_msg_xxcmm_00489             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00489';   -- �t�@�C���N���[�Y�G���[

  -- �g�[�N��
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'NG_PROFILE';         -- �g�[�N���F�v���t�@�C����
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- �g�[�N���FSQL�G���[
-- Ver1.3 Add 20090216
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- �g�[�N���FSQL�G���[
  --
-- Ver1.1 Mod 2009/01/28 ���t�����̏����ݒ���@���C��(�X�e�b�vNo�D1-9)
--  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_ymd;
--                                                                                 -- YYYYMMDD
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
-- End
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
  --
-- Ver1.3 Mod 20090216
  cv_csv_fl_name                 CONSTANT VARCHAR2(30)  := 'XXCMM1_004A11_OUT_FILE';
--  cv_csv_fl_name                 CONSTANT VARCHAR2(30)  := 'XXCMM1_004A11_CSV_FILE_FIL';
                                                                                 -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C����
-- Ver1.3 Mod 20090216
  cv_csv_fl_dir                  CONSTANT VARCHAR2(30)  := 'XXCMM1_JYOHO_OUT_DIR';
--  cv_csv_fl_dir                  CONSTANT VARCHAR2(30)  := 'XXCMM1_004A11_CSV_FILE_DIR';
                                                                                 -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�
  cv_user_csv_fl_name            CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C����';
                                                                                 -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C����
  cv_user_csv_fl_dir             CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�';
                                                                                 -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�
  cv_dqu                         CONSTANT VARCHAR2(1)   := '"';
  cv_sep                         CONSTANT VARCHAR2(1)   := ',';
-- Ver1.1 Mod 2009/01/28 Start �擾����LOOKUP_TYPE�����C��
--  cv_lookup_cost_cmpt            CONSTANT VARCHAR2(15)  := 'XXCMM_COST_CMPT';    -- �Q�ƃ^�C�v
  cv_lookup_cost_cmpt            CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';    -- �Q�ƃ^�C�v
-- Ver1.1 Mod 2009/01/28 End
  cv_enbld_flag                  CONSTANT VARCHAR2(1)   := 'Y';                  -- �g�p�\
--
  cv_co_code                     CONSTANT VARCHAR2(4)   := 'ITOE';               -- ���
  cv_whse_code                   CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                                 -- �q��
  cv_cost_mthd_code              CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                                 -- �������@
  cv_cost_analysis_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                                 -- ���̓R�[�h
  --
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- ��ЃR�[�h
  cn_cost_level                  CONSTANT NUMBER(1)     := 0;                    -- �R�X�g���x��
  cv_categ_set_hon_prod          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;
                                                                                 -- �{�Џ��i�敪
  cv_categ_set_item_prod         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;
                                                                                 -- ���i���i�敪
  cv_csv_mode                    CONSTANT VARCHAR2(1)   := 'w';                  -- csv�t�@�C���I�[�v�����̃��[�h
-- 2010/02/02 Ver1.6 ��QE_�{�ғ�_01420 add start by Shigeto.Niki
-- �i�ڃX�e�[�^�X
  cn_itm_status_pre_reg        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;
                                                                               -- ���o�^
-- 2010/02/02 Ver1.6 ��QE_�{�ғ�_01420 add end by Shigeto.Niki
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �i�ڃ}�X�^IF�o�́i���n�j���C�A�E�g
  TYPE xxcmm004a11c_rtype IS RECORD
  (
    -- ��ЃR�[�h                        �����^(3)
     company_code               VARCHAR2(3)                                     -- VARCHAR2(3)
    -- �i�ڃR�[�h                        �����^(7)
    ,item_code                  ic_item_mst_b.item_no%TYPE                      -- VARCHAR2(32)
    -- �J�i��                            �����^(30)
    ,item_name_alt              xxcmn_item_mst_b.item_name_alt%TYPE             -- VARCHAR2(30)
    -- ������                            �����^(60)
    ,item_name                  xxcmn_item_mst_b.item_name%TYPE                 -- VARCHAR2(60)
    -- JAN�R�[�h                         �����^(13)
    ,jan_code                   VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �P�[�XJAN�R�[�h                   �����^(13)
    ,case_jan_code              xxcmm_system_items_b.case_jan_code%TYPE         -- VARCHAR2(13)
    -- ITF�R�[�h                         �����^(16)
    ,itf_code                   VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �艿�i�V�j                        ���l�^(7)
    ,price_new                  VARCHAR2(240)                                   -- VARCHAR2(240)
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    -- �艿�i���j                        ���l�^(7)
    ,price_old                  VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �艿�K�p�J�n���yYYYYMMDD�z        �����^(8)
    ,price_apply_date           VARCHAR2(240)                                   -- VARCHAR2(240)
-- End
-- Ver1.4 Mod 2009/05/12 �t�@�C�����ڒǉ��Ή�
--    -- �W������                          ���l�^(7,2)
--    ,standard_cost              cm_cmpt_dtl.cmpnt_cost%TYPE                     -- NUMBER
    -- �W�������i�V�j                      ���l�^(7,2)
    ,standard_cost              VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �W�������i���j                    ���l�^(7,2)
    ,standard_cost_old          VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �W�������K�p�J�n���yYYYYMMDD�z    �����^(8)
    ,standard_cost_apply_date   VARCHAR2(240)                                   -- VARCHAR2(240)
-- End
    -- �c�ƌ����i���j                    ���l�^(7)
    ,opt_cost_old               VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �c�ƌ����i�V�j                    ���l�^(7)
    ,opt_cost_new               VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �c�ƌ����ύX�K�p���yYYYYMMDD�z    �����^(8)
    ,opt_cost_apply_date        VARCHAR2(240)                                   -- VARCHAR2(240)
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    -- ����Ώۋ敪                      ���l�^(1)
    ,sales_div                  VARCHAR2(240)                                   -- VARCHAR2(240)
    -- ��P��                          �����^(4)
    ,item_um                    ic_item_mst_b.item_um%TYPE                      -- VARCHAR2(4)
    -- ���i���i�敪                      ���l�^(1)
    ,item_product_class         mtl_categories_b.segment1%TYPE                  -- VARCHAR2(40)
    -- ���敪                            ���l�^(1)
    ,rate_class                 xxcmn_item_mst_b.rate_class%TYPE                -- VARCHAR2(1)
    -- NET                               ���l�^(5)
    ,net                        VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �d��/�̐�                         ���l�^(7)
    ,unit                       VARCHAR2(240)                                   -- VARCHAR2(240)
    -- ���e��                            ���l�^(5.1)
    ,nets                       xxcmm_system_items_b.nets%TYPE                  -- NUMBER(5.1)
    -- ���e�ʒP��                        �����^(1)
    ,nets_uom_code              xxcmm_system_items_b.nets_uom_code%TYPE         -- VARCHAR2(1)
    -- �������                          ���l�^(5.1)
    ,inc_num                    xxcmm_system_items_b.inc_num%TYPE               -- NUMBER(5.1)
    -- �o�����敪                        ���l�^(1)
    ,baracha_div                xxcmm_system_items_b.baracha_div%TYPE           -- NUMBER(1.0)
    -- ���i����                          ���l�^(2)
    ,product_class              xxcmn_item_mst_b.product_class%TYPE             -- NUMBER(2.0)
    -- �p�~���i�������~���j              �����^(8)
    ,obsolete_date              VARCHAR2(8)                                     -- VARCHAR2(8)
    -- �p�~�敪                          ���l�^(1)
    ,obsolete_class             xxcmn_item_mst_b.obsolete_class%TYPE            -- VARCHAR2(1)
    -- �V���i�敪                        ���l�^(1)
    ,new_item_div               xxcmm_system_items_b.new_item_div%TYPE          -- VARCHAR2(1)
    -- ���X�d����R�[�h                �����^(4) �����ڒ�`�͂X��
    ,sp_supplier_code           xxcmm_system_items_b.sp_supplier_code%TYPE      -- VARCHAR2(9)
-- End
    -- �����J�n���yYYYYMMDD�z            �����^(8)
    ,sell_start_date            VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �z��                              ���l�^(2)
    ,palette_max_cs_qty         xxcmn_item_mst_b.palette_max_cs_qty%TYPE        -- NUMBER(2,0)
    -- �p���b�g����ő�i��              ���l�^(2)
    ,palette_max_step_qty       xxcmn_item_mst_b.palette_max_step_qty%TYPE      -- NUMBER(2,0)
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڍ폜�Ή�
--    -- �p���b�g�i                        ���l�^(2)
--    ,palette_step_qty           xxcmn_item_mst_b.palette_step_qty%TYPE          -- NUMBER(2,0)
-- End
    -- �P�[�X����                        ���l�^(5)
    ,num_of_cases               VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �{�[������                        ���l�^(5)
    ,bowl_inc_num               xxcmm_system_items_b.bowl_inc_num%TYPE          -- NUMBER(5,0)
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    -- �P�[�X���Z����                    ���l�^(5)
    ,case_conv_inc_num          xxcmm_system_items_b.case_conv_inc_num%TYPE     -- NUMBER(5,0)
-- End
    -- �Q�R�[�h�i�V�j                    �����^(4)
    ,crowd_code_new             VARCHAR2(240)                                   -- VARCHAR2(240)
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    -- �Q�R�[�h�i���j                    �����^(4)
    ,crowd_code_old             VARCHAR2(240)                                   -- VARCHAR2(240)
    -- �Q�R�[�h�ύX�K�p���yYYYYMMDD�z    �����^(8)
    ,crowd_code_apply_date      VARCHAR2(240)                                   -- VARCHAR2(240)
-- End
    -- �e��Q                            �����^(4)
    ,vessel_group               xxcmm_system_items_b.vessel_group%TYPE          -- VARCHAR2(4)
    -- �{�Џ��i�敪                      �����^(1)
    ,item_div                   mtl_categories.segment1%TYPE                    -- VARCHAR2(40)
    -- �o���Q                            �����^(4)
    ,acnt_group                 xxcmm_system_items_b.acnt_group%TYPE            -- VARCHAR2(4)
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    -- �o���e��Q                        �����^(4)
    ,acnt_vessel_group          xxcmm_system_items_b.acnt_vessel_group%TYPE     -- VARCHAR2(4)
    -- �u�����h�Q                        �����^(4)
    ,brand_group                xxcmm_system_items_b.brand_group%TYPE           -- VARCHAR2(4)
-- End
    -- �e���i�R�[�h                      �����^(7)
    ,parent_item_code           ic_item_mst_b.item_no%TYPE                      -- VARCHAR2(32)
    -- ���j���[�A�������i�R�[�h          �����^(7)
    ,renewal_item_code          xxcmm_system_items_b.renewal_item_code%TYPE     -- VARCHAR2(40)
    -- ����                              �����^(20)
--    ,item_short_name            xxcmm_opmmtl_items_v.item_short_name%TYPE       --
    ,item_short_name            xxcmn_item_mst_b.item_short_name%TYPE           -- VARCHAR2(20)
-- Ver1.7 Add Start 
    --�H�i�敪                           �����^(4)
    ,class_for_variable_tax     xxcmm_system_items_b.class_for_variable_tax%TYPE-- VARCHAR2(4)
-- Ver1.7 Add End
    -- �A�g�����yYYYYMMDDHH24MISS�z      �����^(14)
    ,trans_date                 VARCHAR2(14)                                    -- VARCHAR2(14)
  );
--
  -- �i�ڃ}�X�^IF�o�́i���n�j���C�A�E�g �e�[�u���^�C�v
  TYPE xxcmm004a11c_ttype IS TABLE OF xxcmm004a11c_rtype INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date                DATE;                                          -- �Ɩ����t
  gv_trans_date                  VARCHAR2(14);                                  -- �A�g���t
  gv_csv_file_dir                VARCHAR2(1000);                                -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�̎擾
  gv_file_name                   VARCHAR2(30);                                  -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C����
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : ���������v���V�[�W��(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- �v���O������
--
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(100);                                    -- �X�e�b�v
    lv_message_token          VARCHAR2(100);                                    -- �A�g���t
    lb_fexists                BOOLEAN;                                          -- �t�@�C�����ݔ��f
    ln_file_length            NUMBER;                                           -- �t�@�C���̕�����
    lbi_block_size            BINARY_INTEGER;                                   -- �u���b�N�T�C�Y
-- Ver1.3 Add 20090216
    lv_csv_file               VARCHAR2(1000);                                   -- csv�t�@�C����
    --
    -- *** ���[�U�[��`��O ***
    profile_expt              EXCEPTION;                                        -- �v���t�@�C���擾��O
    csv_file_exst_expt        EXCEPTION;                                        -- CSV�t�@�C�����݃G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�̎擾
    lv_step := 'A-1.1';
    lv_message_token := '�Ɩ����t�̎擾';
    gd_process_date  := TRUNC( xxccp_common_pkg2.get_process_date );
    --
    -- �A�g�����̎擾
    lv_step := 'A-1.1';
    lv_message_token := '�A�g�����̎擾';
    gv_trans_date    := TO_CHAR( SYSDATE, cv_date_fmt_dt_ymdhms );
    --
    -- �v���t�@�C���擾
    lv_step := 'A-1.2';
    lv_message_token := '�A�g�pCSV�t�@�C�����̎擾';
    -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C�����̎擾
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- �擾�G���[��
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_name;
      RAISE profile_expt;
    END IF;
    --
-- Ver1.3 Mod 20090216 START
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- �A�b�v���[�h���̂̏o��
                    iv_application  => cv_appl_name_xxcmm                       -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_xxcmm_00022                       -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_file_name                         -- �g�[�N���R�[�h1
                   ,iv_token_value1 => gv_file_name                             -- �g�[�N���l1
                  );
    -- �t�@�C�����o��
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
-- Ver1.3 Mod 20090216 END
    --
    lv_step := 'A-1.2';
    lv_message_token := '�A�g�pCSV�t�@�C���o�͐�̎擾';
    -- �i�ڃ}�X�^�i���n�j�A�g�pCSV�t�@�C���o�͐�̎擾
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- �擾�G���[��
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_dir;
      RAISE profile_expt;
    END IF;
    --
    lv_step := 'A-1.3';
    lv_message_token := 'CSV�t�@�C�����݃`�F�b�N';
    --
    -- CSV�t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- �t�@�C�����ݎ�
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �J�[�\���̃N���[�Y�������ɋL�q����
    --*** �v���t�@�C���擾�G���[ ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W�FAPP-XXCMM1-00002 �v���t�@�C���擾�G���[
                     ,iv_token_name1  => cv_tkn_profile                -- �g�[�N���FNG_PROFILE
                     ,iv_token_value1 => lv_message_token              -- �v���t�@�C����
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** CSV�t�@�C�����݃G���[ ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00484            -- ���b�Z�[�W�FAPP-XXCMM1-00484 CSV�t�@�C�����݃G���[
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
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
    ov_errbuf      OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(100);                                  -- �X�e�b�v
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[���[�J���ϐ�
    -- ===============================
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM�ޔ�
-- End
    lf_file_hand              UTL_FILE.FILE_TYPE;                             -- �t�@�C���E�n���h���̐錾
    lv_message_token          VARCHAR2(100);                                  -- �A�g���t
    ln_data_index             NUMBER;                                         -- �f�[�^�p����
    lv_parent_item_code       ic_item_mst_b.item_no%TYPE;                     -- �e���i�R�[�h
    lv_item_div               VARCHAR2(1);                                    -- �{�Џ��i�敪
-- Ver1.1 Mod 2009/01/28 �W�������̎擾�������C��(�X�e�b�vNo�D2-7)
--    ln_standard_cost          NUMBER(9,2);                                    -- �W������
    lv_standard_cost          VARCHAR2(20);                                   -- �W������
-- End
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    standard_cost_apply_date  DATE;                                           -- �W�������K�p�J�n��
    lv_standard_cost_old      VARCHAR2(20);                                   -- �W�������i���j
-- End
    lv_out_csv_line           VARCHAR2(1000);                                 -- �o�͍s
    --
    -- �i�ڃ}�X�^�i���n�j���J�[�\��
    --lv_step := 'A-2.1a';
    CURSOR csv_item_cur
    IS
      SELECT      xoiv.item_id                                                -- OPM�i��ID
                 ,xoiv.item_no                                                -- �i�ڃR�[�h
                 ,xoiv.jan_code                                               -- JAN�R�[�h
                 ,xoiv.itf_code                                               -- ITF�R�[�h
                 ,xoiv.num_of_cases                                           -- �P�[�X����
                 ,xoiv.bowl_inc_num                                           -- �{�[������
                 ,xoiv.price_new                                              -- �艿�i�V�j
                 ,xoiv.opt_cost_old                                           -- �c�ƌ����i���j
                 ,xoiv.opt_cost_new                                           -- �c�ƌ����i�V�j
-- Ver1.1 Mod 2009/01/28 ���t�����̏����ݒ���@���C��(�X�e�b�vNo�D1-9)
--                 ,TO_CHAR( fnd_date.canonical_to_date( xoiv.opt_cost_apply_date ), cv_date_fmt_ymd )
--                                      AS opt_cost_apply_date                  -- �c�ƌ����ύX�K�p��
                 ,TO_CHAR( xoiv.opt_cost_apply_date, cv_date_fmt_ymd )
                                      AS opt_cost_apply_date                  -- �c�ƌ����ύX�K�p��
-- End
                 ,xoiv.crowd_code_new                                         -- �Q�R�[�h�i�V�j
-- Ver1.1 Mod 2009/01/28 ���t�����̏����ݒ���@���C��(�X�e�b�vNo�D1-9)
--                 ,TO_CHAR( fnd_date.canonical_to_date( xoiv.sell_start_date ), cv_date_fmt_ymd )
--                                      AS sell_start_date                      -- �����J�n��
                 ,TO_CHAR( xoiv.sell_start_date, cv_date_fmt_ymd )
                                      AS sell_start_date                      -- �����J�n��
-- End
                 ,xoiv.item_name                                              -- ������
                 ,xoiv.item_name_alt                                          -- �J�i��
                 ,xoiv.item_short_name                                        -- ����
                 ,xoiv.parent_item_id                                         -- �e�i��ID
                 ,xoiv.palette_max_cs_qty                                     -- �z��
                 ,xoiv.palette_max_step_qty                                   -- �p���b�g����ő�i��
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڍ폜�Ή�
--                 ,xoiv.palette_step_qty                                       -- �p���b�g�i
-- End
                 ,xoiv.case_jan_code                                          -- �P�[�XJAN�R�[�h
                 ,xoiv.renewal_item_code                                      -- ���j���[�A�������i�R�[�h
                 ,xoiv.acnt_group                                             -- �o���Q
                 ,xoiv.vessel_group                                           -- �e��Q
                 ,iimb.item_no        AS parent_item_code                     -- �e���i�R�[�h
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
                 ,xoiv.price_old                                              -- �艿�i���j
                 ,TO_CHAR( xoiv.price_apply_date, cv_date_fmt_ymd )
                                      AS price_apply_date                     -- �艿�K�p�J�n��
                 ,xoiv.sales_div                                              -- ����Ώۋ敪
-- Ver1.5 Mod 2009/06/15 �����������Ή�
--                 ,TO_MULTI_BYTE( xoiv.item_um )
--                                      AS item_um                              -- ��P��
                 ,SUBSTR( TO_MULTI_BYTE( xoiv.item_um ), 1, 2 )
                                      AS item_um                              -- ��P��
-- End1.5
                 ,mcv.segment1        AS item_product_class                   -- ���i���i�敪
                 ,xoiv.rate_class                                             -- ���敪
                 ,xoiv.net                                                    -- NET
                 ,xoiv.unit                                                   -- �d��/�̐�
                 ,xoiv.nets                                                   -- ���e��
                 ,xoiv.nets_uom_code                                          -- ���e�ʒP��
                 ,xoiv.inc_num                                                -- �������
                 ,xoiv.baracha_div                                            -- �o�����敪
                 ,xoiv.product_class                                          -- ���i����
                 ,TO_CHAR( xoiv.obsolete_date, cv_date_fmt_ymd )
                                      AS obsolete_date                        -- �p�~���i�������~���j
                 ,xoiv.obsolete_class                                         -- �p�~�敪
                 ,xoiv.new_item_div                                           -- �V���i�敪
                 ,xoiv.sp_supplier_code                                       -- ���X�d����R�[�h
                 ,xoiv.case_conv_inc_num                                      -- �P�[�X���Z����
                 ,xoiv.crowd_code_old                                         -- ���Q�R�[�h
                 ,TO_CHAR( xoiv.crowd_code_apply_date, cv_date_fmt_ymd )
                                      AS crowd_code_apply_date                -- �Q�R�[�h�K�p�J�n��
                 ,xoiv.acnt_vessel_group                                      -- �o���e��Q
                 ,xoiv.brand_group                                            -- �u�����h�Q
-- Ver1.7 Add Start
                 ,xoiv.class_for_variable_tax AS class_for_variable_tax       -- �y���ŗ��p�Ŏ�ʁi�H�i�敪�j
-- Ver1.7 Add End
-- End
      FROM        xxcmm_opmmtl_items_v    xoiv                                -- �i�ڃr���[
                 ,ic_item_mst_b           iimb                                -- OPM�i�ځi�e���i�R�[�h�擾�p�j
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
                 ,gmi_item_categories     gic                                 -- �J�e�S������
                 ,mtl_categories_vl       mcv                                 -- �J�e�S��
                 ,mtl_category_sets_vl    mcsv                                -- �J�e�S���Z�b�g
-- End
-- Ver1.2 Mod 2009/01/30 �e�i�ڂ��ݒ肳��Ă��Ȃ��i�ڂ𒊏o�ΏۂƂ���悤�C��(�X�e�b�vNo�D3-1)
--      WHERE       iimb.item_id            = xoiv.parent_item_id               -- �e���i�R�[�h
      WHERE       iimb.item_id(+)         = xoiv.parent_item_id               -- �e���i�R�[�h
-- End
-- Ver1.4 Mod 2009/05/12 ���s�͖�ԃo�b�`�̍Ō� ���ꎞ�_�ŗ��c�Ɠ��̏��𑗕t����
--      AND         xoiv.start_date_active <= gd_process_date                   -- �K�p�J�n��
--      AND         xoiv.end_date_active   >= gd_process_date                   -- �K�p�I����
      AND         xoiv.start_date_active <= gd_process_date + 1               -- �K�p�J�n��
      AND         xoiv.end_date_active   >= gd_process_date + 1               -- �K�p�I����
-- End
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      AND         mcsv.category_set_name  = cv_categ_set_item_prod
      AND         gic.category_set_id     = mcsv.category_set_id
      AND         gic.item_id             = xoiv.item_id
      AND         gic.category_id         = mcv.category_id
-- End
-- 2010/02/02 Ver1.6 ��QE_�{�ғ�_01420 add start by Shigeto.Niki
      AND         xoiv.item_status       >= cn_itm_status_pre_reg
-- 2010/02/02 Ver1.6 ��QE_�{�ғ�_01420 add end by Shigeto.Niki
      ORDER BY    xoiv.item_no;
    --
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
    -- OPM�����J�����_���J�[�\��
    CURSOR opm_cost_cur(
      pn_item_id         NUMBER
     ,pd_connect_date    DATE )
    IS
      SELECT      TO_CHAR( TRUNC( SUM( NVL( ccmd.cmpnt_cost, 0 )), 2 ))  AS standard_cost  -- �W������
                 ,TO_CHAR( cclr.start_date, cv_date_fmt_ymd )            AS start_date     -- �J�n��
      FROM        cm_cmpt_dtl          ccmd           -- OPM�W������
                 ,cm_cldr_dtl          cclr           -- OPM�����J�����_
                 ,cm_cmpt_mst_vl       ccmv           -- �����R���|�[�l���g
                 ,fnd_lookup_values_vl flv            -- �Q�ƃR�[�h�l
      WHERE       ccmd.item_id             = pn_item_id                       -- �i��ID
      AND         cclr.start_date         <= pd_connect_date                  -- �J�n��
      AND         flv.lookup_type          = cv_lookup_cost_cmpt              -- �Q�ƃ^�C�v
      AND         flv.enabled_flag         = cv_enbld_flag                    -- �g�p�\
      AND         ccmv.cost_cmpntcls_code  = flv.meaning                      -- �����R���|�[�l���g�R�[�h
      AND         ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id            -- �����R���|�[�l���gID
      AND         ccmd.calendar_code       = cclr.calendar_code               -- �J�����_�R�[�h
      AND         ccmd.period_code         = cclr.period_code                 -- ���ԃR�[�h
      AND         ccmd.whse_code           = cv_whse_code                     -- �q��
      AND         ccmd.cost_mthd_code      = cv_cost_mthd_code                -- �������@
      AND         ccmd.cost_analysis_code  = cv_cost_analysis_code            -- ���̓R�[�h
      GROUP BY    cclr.start_date
      ORDER BY    cclr.start_date DESC;
    --
    l_opm_cost_now_clear                opm_cost_cur%ROWTYPE;                 -- �N���A�p
    l_opm_cost_now_rec                  opm_cost_cur%ROWTYPE;                 -- �W�������i�V�j�i�[�p
    l_opm_cost_old_rec                  opm_cost_cur%ROWTYPE;                 -- �W�������i���j�i�[�p
-- End
    lt_csv_item_tab                     xxcmm004a11c_ttype;                   -- ���iIF�o�̓f�[�^
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    chk_param_err_expt        EXCEPTION;       -- �p�����[�^�`�F�b�N�G���[
    subproc_expt              EXCEPTION;       -- �T�u�v���O�����G���[
    file_open_expt            EXCEPTION;       -- �t�@�C���I�[�v���G���[
    file_output_expt          EXCEPTION;       -- �t�@�C���������݃G���[
    file_close_expt           EXCEPTION;       -- �t�@�C���N���[�Y�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ===============================================
    -- proc_init�̌Ăяo���i����������proc_init�ōs���j
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
    --
    -----------------------------------
    -- A-2.�i�ڏ��̎擾
    -----------------------------------
    lv_step := 'A-2.1b';
    ln_data_index := 0;
    --
    <<csv_item_loop>>
    FOR l_csv_item_rec IN csv_item_cur LOOP
      --
      ln_data_index := ln_data_index + 1;
      --
      BEGIN
        lv_step := 'A-2.3';
        lv_message_token := '�{�Џ��i�敪�̎擾';
        -- �{�Џ��i�敪�̎擾
        SELECT      mc.segment1  AS item_div                           -- �{�Џ��i�敪
        INTO        lv_item_div
        FROM        gmi_item_categories     gic                        -- �J�e�S��������
                   ,mtl_categories          mc                         -- �J�e�S��
                   ,mtl_category_sets       mcs                        -- �J�e�S���Z�b�g
        WHERE       mcs.category_set_name   = cv_categ_set_hon_prod    -- '�{�Џ��i�敪'
        AND         gic.item_id             = l_csv_item_rec.item_id   -- �i��
        AND         gic.category_set_id     = mcs.category_set_id      -- �J�e�S���Z�b�gID
        AND         gic.category_id         = mc.category_id;          -- �J�e�S��ID
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.1 Mod 2009/01/28 �{�Џ��i�敪���擾�ł��Ȃ��ꍇ�̒l�ݒ���폜(�X�e�b�vNo�D2-3)
--          lv_item_div := '9';
          lv_item_div := '';
-- End
      END;
      --
      lv_step := 'A-2.4';
      lv_message_token := '�W�������̎擾';
-- Ver1.4 �W�������V���擾�ɕύX�ɂ��J�[�\����
---- Ver1.1 Mod 2009/01/28 �W�������̎擾�������C��(�X�e�b�vNo�D2-7)
----      SELECT      SUM( NVL( ccmd.cmpnt_cost, 0 ) )
----      INTO        ln_standard_cost
--      SELECT      TO_CHAR( TRUNC( SUM( NVL( ccmd.cmpnt_cost, 0 )), 2 ))
--                                                      -- �W������
--      INTO        lv_standard_cost
---- End
--      FROM        cm_cmpt_dtl          ccmd           -- OPM�W������
--                 ,cm_cldr_dtl          cclr           -- OPM�����J�����_
--                 ,cm_cmpt_mst_vl       ccmv           -- �����R���|�[�l���g
--                 ,fnd_lookup_values_vl flv            -- �Q�ƃR�[�h�l
--      WHERE       ccmd.item_id             = l_csv_item_rec.item_id           -- �i��ID
--      AND         cclr.start_date         <= gd_process_date                  -- �J�n��
--      AND         cclr.end_date           >= gd_process_date                  -- �I����
--      AND         flv.lookup_type          = cv_lookup_cost_cmpt              -- �Q�ƃ^�C�v
--      AND         flv.enabled_flag         = cv_enbld_flag                    -- �g�p�\
--      AND         ccmv.cost_cmpntcls_code  = flv.meaning                      -- �����R���|�[�l���g�R�[�h
--      AND         ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id            -- �����R���|�[�l���gID
--      AND         ccmd.calendar_code       = cclr.calendar_code               -- �J�����_�R�[�h
--      AND         ccmd.period_code         = cclr.period_code                 -- ���ԃR�[�h
--      AND         ccmd.whse_code           = cv_whse_code                     -- �q��
--      AND         ccmd.cost_mthd_code      = cv_cost_mthd_code                -- �������@
--      AND         ccmd.cost_analysis_code  = cv_cost_analysis_code;           -- ���̓R�[�h
-- End
      --
      -- �W�������̎擾
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      -- ������
      l_opm_cost_now_rec := l_opm_cost_now_clear;
      l_opm_cost_old_rec := l_opm_cost_now_clear;
      --
      -- �����J�����_���擾
      lv_step := 'A-2.4a';
      OPEN opm_cost_cur(
        l_csv_item_rec.item_id    -- OPM�i��ID
       ,gd_process_date + 1       -- �J�n���i�c�Ɠ��̗����j
      );
      -- �t�F�b�`
      -- �W�������i�V�j�E�J�n���̎擾
      lv_step := 'A-2.4b';
      FETCH opm_cost_cur INTO l_opm_cost_now_rec;
      --
      -- �W�������i���j�̎擾
      lv_step := 'A-2.4c';
      FETCH opm_cost_cur INTO l_opm_cost_old_rec;
      --
      -- �J�[�\���N���[�Y
      lv_step := 'A-2.4d';
      CLOSE opm_cost_cur;
-- End
      --
      -- �z��ɐݒ�
      lv_step := 'A-2.company_code';
      lv_message_token := '��ЃR�[�h';
      lt_csv_item_tab( ln_data_index ).company_code         := cv_company_code;
      lv_step := 'A-2.item_code';
      lv_message_token := '�i�ڃR�[�h';
      lt_csv_item_tab( ln_data_index ).item_code            := SUBSTRB( l_csv_item_rec.item_no, 1, 7 );
      lv_step := 'A-2.item_name_alt';
      lv_message_token := '�J�i��';
      lt_csv_item_tab( ln_data_index ).item_name_alt        := l_csv_item_rec.item_name_alt;
      lv_step := 'A-2.item_name';
      lv_message_token := '������';
      lt_csv_item_tab( ln_data_index ).item_name            := l_csv_item_rec.item_name;
      lv_step := 'A-2.jan_code';
      lv_message_token := 'JAN�R�[�h';
      lt_csv_item_tab( ln_data_index ).jan_code             := SUBSTRB( l_csv_item_rec.jan_code, 1, 13 );
      lv_step := 'A-2.case_jan_code';
      lv_message_token := '�P�[�XJAN�R�[�h';
      lt_csv_item_tab( ln_data_index ).case_jan_code        := l_csv_item_rec.case_jan_code;
      lv_step := 'A-2.itf_code';
      lv_message_token := 'ITF�R�[�h';
      lt_csv_item_tab( ln_data_index ).itf_code             := SUBSTRB( l_csv_item_rec.itf_code, 1, 16 );
      lv_step := 'A-2.price_new';
      lv_message_token := '�艿�i�V�j';
      lt_csv_item_tab( ln_data_index ).price_new            := TO_CHAR( l_csv_item_rec.price_new );
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      lv_step := 'A-2.price_old';
      lv_message_token := '�艿�i���j';
      lt_csv_item_tab( ln_data_index ).price_old            := TO_CHAR( l_csv_item_rec.price_old );
      lv_step := 'A-2.price_new';
      lv_message_token := '�艿�K�p�J�n��';
      lt_csv_item_tab( ln_data_index ).price_apply_date     := l_csv_item_rec.price_apply_date;
-- End
-- Ver1.4 �W�������V���擾�ɕύX�̂��ߍ폜
---- Ver1.1 Mod 2009/01/28 �W�������̎擾�������C��(�X�e�b�vNo�D2-7)
--      lv_step := 'A-2.standard_cost';
--      lv_message_token := '�W������';
----      lt_csv_item_tab( ln_data_index ).standard_cost        := ln_standard_cost;
--      lt_csv_item_tab( ln_data_index ).standard_cost        := lv_standard_cost;
---- End
-- End
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      lv_step := 'A-2.standard_cost_new';
      lv_message_token := '�W�������i�V�j';
      lt_csv_item_tab( ln_data_index ).standard_cost        := l_opm_cost_now_rec.standard_cost;
      lv_step := 'A-2.standard_cost_old';
      lv_message_token := '�W�������i���j';
      lt_csv_item_tab( ln_data_index ).standard_cost_old    := l_opm_cost_old_rec.standard_cost;
      lv_step := 'A-2.standard_cost_apply_date';
      lv_message_token := '�W�������K�p�J�n��';
      IF ( l_opm_cost_now_rec.standard_cost IS NOT NULL )
      OR ( l_opm_cost_old_rec.standard_cost IS NOT NULL ) THEN
        -- �����E�O���ǂ��炩�ɂł��W���������ݒ肳��Ă���ꍇ�ɕ\��
        lt_csv_item_tab( ln_data_index ).standard_cost_apply_date
                                                            := l_opm_cost_now_rec.start_date;
      END IF;
-- End
-- Ver1.1 Mod 2009/01/28 �c�ƌ���(�V)�Ɖc�ƌ���(��)�̏o�͗���C��(�X�e�b�vNo�D3-1)
--      lv_step := 'A-2.opt_cost_old';
--      lv_message_token := '�c�ƌ����i���j';
--      lt_csv_item_tab( ln_data_index ).opt_cost_old         := TO_CHAR( l_csv_item_rec.opt_cost_old );
--      lv_step := 'A-2.opt_cost_new';
--      lv_message_token := '�c�ƌ����i�V�j';
--      lt_csv_item_tab( ln_data_index ).opt_cost_new         := TO_CHAR( l_csv_item_rec.opt_cost_new );
--      lv_step := 'A-2.opt_cost_apply_date';
      lv_step := 'A-2.opt_cost_new';
      lv_message_token := '�c�ƌ����i�V�j';
      lt_csv_item_tab( ln_data_index ).opt_cost_new         := TO_CHAR( l_csv_item_rec.opt_cost_new );
      lv_step := 'A-2.opt_cost_old';
      lv_message_token := '�c�ƌ����i���j';
      lt_csv_item_tab( ln_data_index ).opt_cost_old         := TO_CHAR( l_csv_item_rec.opt_cost_old );
-- End
      lv_step := 'A-2.opt_cost_apply_date';
      lv_message_token := '�c�ƌ����ύX�K�p��';
      lt_csv_item_tab( ln_data_index ).opt_cost_apply_date  := l_csv_item_rec.opt_cost_apply_date;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      lv_step := 'A-2.sales_div';
      lv_message_token := '����Ώۋ敪';
      lt_csv_item_tab( ln_data_index ).sales_div            := l_csv_item_rec.sales_div;
      lv_step := 'A-2.item_um';
      lv_message_token := '��P��';
      lt_csv_item_tab( ln_data_index ).item_um              := l_csv_item_rec.item_um;
      lv_step := 'A-2.item_product_class';
      lv_message_token := '���i���i�敪';
      lt_csv_item_tab( ln_data_index ).item_product_class   := l_csv_item_rec.item_product_class;
      lv_step := 'A-2.rate_class';
      lv_message_token := '���敪';
      lt_csv_item_tab( ln_data_index ).rate_class           := l_csv_item_rec.rate_class;
      lv_step := 'A-2.net';
      lv_message_token := 'NET';
      lt_csv_item_tab( ln_data_index ).net                  := l_csv_item_rec.net;
      lv_step := 'A-2.unit';
      lv_message_token := '�d��/�̐�';
      lt_csv_item_tab( ln_data_index ).unit                 := l_csv_item_rec.unit;
      lv_step := 'A-2.nets';
      lv_message_token := '���e��';
      lt_csv_item_tab( ln_data_index ).nets                 := l_csv_item_rec.nets;
      lv_step := 'A-2.nets_uom_code';
      lv_message_token := '���e�ʒP��';
      lt_csv_item_tab( ln_data_index ).nets_uom_code        := l_csv_item_rec.nets_uom_code;
      lv_step := 'A-2.inc_num';
      lv_message_token := '�������';
      lt_csv_item_tab( ln_data_index ).inc_num              := l_csv_item_rec.inc_num;
      lv_step := 'A-2.baracha_div';
      lv_message_token := '�o�����敪';
      lt_csv_item_tab( ln_data_index ).baracha_div          := l_csv_item_rec.baracha_div;
      lv_step := 'A-2.product_class';
      lv_message_token := '���i����';
      lt_csv_item_tab( ln_data_index ).product_class        := l_csv_item_rec.product_class;
      lv_step := 'A-2.obsolete_date';
      lv_message_token := '�p�~��';
      lt_csv_item_tab( ln_data_index ).obsolete_date        := l_csv_item_rec.obsolete_date;
      lv_step := 'A-2.obsolete_class';
      lv_message_token := '�p�~�敪';
      lt_csv_item_tab( ln_data_index ).obsolete_class       := l_csv_item_rec.obsolete_class;
      lv_step := 'A-2.new_item_div';
      lv_message_token := '�V���i�敪';
      lt_csv_item_tab( ln_data_index ).new_item_div         := l_csv_item_rec.new_item_div;
      lv_step := 'A-2.sp_supplier_code';
      lv_message_token := '���X�d����R�[�h';
      lt_csv_item_tab( ln_data_index ).sp_supplier_code     := SUBSTRB( l_csv_item_rec.sp_supplier_code, 1, 4 );
-- End
      lv_step := 'A-2.sell_start_date';
      lv_message_token := '�����J�n��';
      lt_csv_item_tab( ln_data_index ).sell_start_date      := l_csv_item_rec.sell_start_date;
      lv_step := 'A-2.palette_max_cs_qty';
      lv_message_token := '�z��';
      lt_csv_item_tab( ln_data_index ).palette_max_cs_qty   := l_csv_item_rec.palette_max_cs_qty;
      lv_step := 'A-2.palette_max_step_qty';
      lv_message_token := '�p���b�g����ő�i��';
      lt_csv_item_tab( ln_data_index ).palette_max_step_qty := l_csv_item_rec.palette_max_step_qty;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڍ폜�Ή�
--      lv_step := 'A-2.palette_step_qty';
--      lv_message_token := '�p���b�g�i';
--      lt_csv_item_tab( ln_data_index ).palette_step_qty     := l_csv_item_rec.palette_step_qty;
-- End
      lv_step := 'A-2.num_of_cases';
      lv_message_token := '�P�[�X����';
      lt_csv_item_tab( ln_data_index ).num_of_cases         := TO_CHAR( l_csv_item_rec.num_of_cases );
      lv_step := 'A-2.bowl_inc_num';
      lv_message_token := '�{�[������';
      lt_csv_item_tab( ln_data_index ).bowl_inc_num         := l_csv_item_rec.bowl_inc_num;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      lv_step := 'A-2.case_conv_inc_num';
      lv_message_token := '�P�[�X���Z����';
      lt_csv_item_tab( ln_data_index ).case_conv_inc_num    := l_csv_item_rec.case_conv_inc_num;
-- End
      lv_step := 'A-2.crowd_code_new';
      lv_message_token := '�Q�R�[�h�i�V�j';
      lt_csv_item_tab( ln_data_index ).crowd_code_new       := SUBSTRB( l_csv_item_rec.crowd_code_new, 1, 4 );
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      lv_step := 'A-2.crowd_code_old';
      lv_message_token := '�Q�R�[�h�i���j';
      lt_csv_item_tab( ln_data_index ).crowd_code_old       := SUBSTRB( l_csv_item_rec.crowd_code_old, 1, 4 );
      lv_step := 'A-2.crowd_code_new';
      lv_message_token := '�Q�R�[�h�K�p�J�n��';
      lt_csv_item_tab( ln_data_index ).crowd_code_apply_date
                                                            := l_csv_item_rec.crowd_code_apply_date;
-- End
      lv_step := 'A-2.vessel_group';
      lv_message_token := '�e��Q';
      lt_csv_item_tab( ln_data_index ).vessel_group         := l_csv_item_rec.vessel_group;
      lv_step := 'A-2.item_div';
      lv_message_token := '�{�Џ��i�敪';
      lt_csv_item_tab( ln_data_index ).item_div             := lv_item_div;
      lv_step := 'A-2.acnt_group';
      lv_message_token := '�o���Q';
      lt_csv_item_tab( ln_data_index ).acnt_group           := l_csv_item_rec.acnt_group;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
      lv_step := 'A-2.acnt_vessel_group';
      lv_message_token := '�o���e��Q';
      lt_csv_item_tab( ln_data_index ).acnt_vessel_group    := l_csv_item_rec.acnt_vessel_group;
      lv_step := 'A-2.brand_group';
      lv_message_token := '�u�����h�Q';
      lt_csv_item_tab( ln_data_index ).brand_group          := l_csv_item_rec.brand_group;
-- End
      lv_step := 'A-2.parent_item_code';
      lv_message_token := '�e���i�R�[�h';
      lt_csv_item_tab( ln_data_index ).parent_item_code     := SUBSTRB( l_csv_item_rec.parent_item_code, 1, 7 );
      lv_step := 'A-2.renewal_item_code';
      lv_message_token := '���j���[�A�������i�R�[�h';
      lt_csv_item_tab( ln_data_index ).renewal_item_code    := SUBSTRB( l_csv_item_rec.renewal_item_code, 1, 7 );
      lv_step := 'A-2.item_short_name';
      lv_message_token := '����';
      lt_csv_item_tab( ln_data_index ).item_short_name      := l_csv_item_rec.item_short_name;
-- Ver1.7 Add Start 
      lv_step := 'A-2.class_for_variable_tax';
      lv_message_token := '�H�i�敪';
      lt_csv_item_tab( ln_data_index ).class_for_variable_tax
                                                            := l_csv_item_rec.class_for_variable_tax;
-- Ver1.7 Add End
      lv_step := 'A-2.trans_date';
      lv_message_token := '�A�g����';
      lt_csv_item_tab( ln_data_index ).trans_date           := gv_trans_date;
      --
    END LOOP csv_item_loop;
    --
    -----------------------------------------------
    -- A-3.�i�ڃ}�X�^�i���n�j�o�͏���
    -----------------------------------------------
    lv_step := 'A-3.1a';
    IF ( ln_data_index = 0 ) THEN
      -- �Ώۃf�[�^�Ȃ�
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm
                     ,iv_name         => cv_msg_xxcmm_00001
                     );
-- Ver1.1 Mod 2009/01/28 �Ώۃf�[�^�������G���[�I������悤�C��(�X�e�b�vNo�D1-10)
--      -- �o�͕\��
--      lv_step := 'A-3.1a';
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg
--      );
--      -- ���O�o��
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
-- End
    ELSE
      -- CSV�t�@�C���I�[�v��
      lv_step := 'A-1.5';
      BEGIN
        lf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- �o�͐�
                                        ,filename  => gv_file_name     -- CSV�t�@�C����
                                        ,open_mode => cv_csv_mode      -- ���[�h
                                       );
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
          lv_sqlerrm := SQLERRM;
-- End
          RAISE file_open_expt;
      END;
      -- �t�@�C���o��
      lv_step := 'A-3.1b';
      <<out_csv_loop>>
      FOR ln_index IN 1..lt_csv_item_tab.COUNT LOOP
        --
        lv_out_csv_line := '';
        -- ��ЃR�[�h
        lv_step := 'A-3.company_code';
        lv_out_csv_line := cv_dqu ||
                           lt_csv_item_tab( ln_index ).company_code ||
                           cv_dqu;
        -- �i�ڃR�[�h
        lv_step := 'A-3.item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_code ||
                           cv_dqu;
        -- �J�i��
        lv_step := 'A-3.item_name_alt';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_name_alt ||
                           cv_dqu;
        -- ������
        lv_step := 'A-3.item_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_name ||
                           cv_dqu;
        -- JAN�R�[�h
        lv_step := 'A-3.jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).jan_code ||
                           cv_dqu;
        -- �P�[�XJAN�R�[�h
        lv_step := 'A-3.case_jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).case_jan_code ||
                           cv_dqu;
        -- ITF�R�[�h
        lv_step := 'A-3.itf_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).itf_code ||
                           cv_dqu;
        -- �艿�i�V�j
        lv_step := 'A-3.price_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).price_new;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
        -- �艿�i���j
        lv_step := 'A-3.price_old';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).price_old;
        -- �艿�K�p�J�n���yYYYYMMDD�z
        lv_step := 'A-3.price_apply_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).price_apply_date;
-- End
-- Ver1.1 Mod 2009/01/28 �W�������̎擾�������C��(�X�e�b�vNo�D2-7)
        -- �W������
        lv_step := 'A-3.standard_cost';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           RTRIM( TO_CHAR( TRUNC( lt_csv_item_tab( ln_index ).standard_cost, 2 ), 'FM99990.99'), '.' );
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_item_tab( ln_index ).standard_cost;
-- End
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
        -- �W�������i���j
        lv_step := 'A-3.standard_cost_old';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).standard_cost_old;
        -- �W�������K�p�J�n���yYYYYMMDD�z
        lv_step := 'A-3.standard_cost_apply_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).standard_cost_apply_date;
-- End
-- Ver1.1 Mod 2009/01/28 �c�ƌ���(�V)�Ɖc�ƌ���(��)�̏o�͗���C��(�X�e�b�vNo�D3-1)
--        -- �c�ƌ����i���j
--        lv_step := 'A-3.opt_cost_old';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           lt_csv_item_tab( ln_index ).opt_cost_old;
--        -- �c�ƌ����i�V�j
--        lv_step := 'A-3.opt_cost_new';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           lt_csv_item_tab( ln_index ).opt_cost_new;
        -- �c�ƌ����i�V�j
        lv_step := 'A-3.opt_cost_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).opt_cost_new;
        -- �c�ƌ����i���j
        lv_step := 'A-3.opt_cost_old';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).opt_cost_old;
-- End
        -- �c�ƌ����ύX�K�p���yYYYYMMDD�z
        lv_step := 'A-3.opt_cost_apply_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).opt_cost_apply_date;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
        -- ����Ώۋ敪
        lv_step := 'A-3.sales_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).sales_div;
        -- ��P��
        lv_step := 'A-3.item_um';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_um ||
                           cv_dqu;
        -- ���i���i�敪
        lv_step := 'A-3.item_product_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).item_product_class;
        -- ���敪
        lv_step := 'A-3.rate_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).rate_class;
        -- NET
        lv_step := 'A-3.net';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).net;
        -- �d��/�̐�
        lv_step := 'A-3.unit';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).unit;
        -- ���e��
        lv_step := 'A-3.nets';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).nets );
        -- ���e�ʒP��
        lv_step := 'A-3.nets_uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).nets_uom_code ||
                           cv_dqu;
        -- �������
        lv_step := 'A-3.inc_num';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).inc_num );
        -- �o�����敪
        lv_step := 'A-3.baracha_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).baracha_div );
        -- ���i����
        lv_step := 'A-3.product_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).product_class );
        -- �p�~��
        lv_step := 'A-3.obsolete_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).obsolete_date;
        -- �p�~�敪
        lv_step := 'A-3.obsolete_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).obsolete_class;
        -- �V���i�敪
        lv_step := 'A-3.new_item_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).new_item_div;
        -- ���X�d����R�[�h
        lv_step := 'A-3.sp_supplier_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).sp_supplier_code ||
                           cv_dqu;
-- End
        -- �����J�n���yYYYYMMDD�z
        lv_step := 'A-3.sell_start_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).sell_start_date;
        -- �z��
        lv_step := 'A-3.palette_max_cs_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).palette_max_cs_qty );
        -- �p���b�g����ő�i��
        lv_step := 'A-3.palette_max_step_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).palette_max_step_qty );
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڍ폜�Ή�
--        -- �p���b�g�i
--        lv_step := 'A-3.palette_step_qty';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           TO_CHAR( lt_csv_item_tab( ln_index ).palette_step_qty );
-- End
        -- �P�[�X����
        lv_step := 'A-3.num_of_cases';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).num_of_cases;
        -- �{�[������
        lv_step := 'A-3.bowl_inc_num';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).bowl_inc_num );
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
        -- �P�[�X���Z����
        lv_step := 'A-3.case_conv_inc_num';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).case_conv_inc_num );
-- End
        -- �Q�R�[�h�i�V�j
        lv_step := 'A-3.crowd_code_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).crowd_code_new ||
                           cv_dqu;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
        -- �Q�R�[�h�i���j
        lv_step := 'A-3.crowd_code_old';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).crowd_code_old ||
                           cv_dqu;
        -- �Q�R�[�h�K�p�J�n���yYYYYMMDD�z
        lv_step := 'A-3.crowd_code_apply_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).crowd_code_apply_date;
-- End
        -- �e��Q
        lv_step := 'A-3.vessel_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).vessel_group ||
                           cv_dqu;
        -- �{�Џ��i�敪
        lv_step := 'A-3.item_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_div ||
                           cv_dqu;
        -- �o���Q
        lv_step := 'A-3.acnt_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).acnt_group ||
                           cv_dqu;
-- Ver1.4 Add 2009/05/12 �t�@�C�����ڒǉ��Ή�
        -- �o���e��Q
        lv_step := 'A-3.acnt_vessel_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).acnt_vessel_group ||
                           cv_dqu;
        -- �u�����h�Q
        lv_step := 'A-3.brand_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).brand_group ||
                           cv_dqu;
-- End
        -- �e���i�R�[�h
        lv_step := 'A-3.parent_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).parent_item_code ||
                           cv_dqu;
        -- ���j���[�A�������i�R�[�h
        lv_step := 'A-3.renewal_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).renewal_item_code ||
                           cv_dqu;
        -- ����
        lv_step := 'A-3.item_short_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_short_name ||
                           cv_dqu;
-- Ver1.7 Add Start 
        -- �H�i�敪
        lv_step := 'A-3.class_for_variable_tax';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).class_for_variable_tax ||
                           cv_dqu;
-- Ver1.7 Add End
        -- �A�g�����yYYYYMMDDHH24MISS�z
        lv_step := 'A-3.trans_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).trans_date;
        --
        --=================
        -- CSV�t�@�C���o��
        --=================
        lv_step := 'A-3.1c';
        BEGIN
          UTL_FILE.PUT_LINE( lf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
            lv_sqlerrm := SQLERRM;
-- End
            RAISE file_output_expt;
        END;
        --
        -- �Ώی���
        gn_target_cnt := gn_target_cnt + 1;
        -- ��������
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
      --
      -----------------------------------------------
      -- A-4.�I������
      -----------------------------------------------
      -- �t�@�C���N���[�Y
      lv_step := 'A-4.1';
      --
      --�t�@�C���N���[�Y���s
      BEGIN
        UTL_FILE.FCLOSE( lf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
          lv_sqlerrm := SQLERRM;
-- End
          RAISE file_close_expt;
      END;
      --
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- *** �T�u�v���O������O�n���h�� ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00487             -- ���b�Z�[�W�FAPP-XXCMM1-00487 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** �t�@�C���������݃G���[ ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00488             -- ���b�Z�[�W�FAPP-XXCMM1-00488 �t�@�C���I�[�v���G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** �t�@�C���N���[�Y�G���[ ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM �}�X�^
                     ,iv_name         => cv_msg_xxcmm_00489             -- ���b�Z�[�W�FAPP-XXCMM1-00489 �t�@�C���N���[�Y�G���[
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- �g�[�N���FSQLERRM
-- Ver1.1 Add 2009/01/28 �G���[���b�Z�[�W�̃g�[�N���l�w�薳�����C��(�X�e�b�vNo�D1-12)
                     ,iv_token_value1 => lv_sqlerrm                     -- �l�FSQLERRM
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����o��
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--####################################  �Œ蕔 END   ###################s#######################
--
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode        OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
  )
  IS
  --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- �v���O������
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ���O
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- �A�E�g�v�b�g
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- �A�v���P�[�V�����Z�k��
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- �x���I�����b�Z�[�W
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';   -- �x���I�����b�Z�[�W
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- ��������
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_step                   VARCHAR2(10);                                   -- �X�e�b�v
    lv_message_code           VARCHAR2(100);                                  -- ���b�Z�[�W�R�[�h
    --
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode     => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
-- Ver1.1 Del 2009/01/28 �G���[���b�Z�[�W�o�͂��C��(�X�e�b�vNo�D1-4)
--    lv_errmsg := lv_errbuf;
-- End
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�G���[���b�Z�[�W
      );
      --
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM004A11C;
/
