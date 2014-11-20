CREATE OR REPLACE PACKAGE BODY XXCMM004A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A04C(spec)
 * Description      : Disc�i�ڕύX�����A�h�I���}�X�^�ɂĕύX�\��Ǘ�����Ă��鍀�ڂ�
 *                  : �K�p�������������^�C�~���O�Ŋe�i�ڏ��ɔ��f���܂��B
 * MD.050           : �ύX�\��K�p    MD050_CMM_004_A04
 * Version          : Issue3.9
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  proc_init                 �������� (A-1)
 *  loop_main                 �ύX�K�p�i�ڏ��̎擾 (A-2)
 *                               �Eproc_apply_update
 *  proc_apply_update         �i�ڕύX�K�p����
 *                               �Eproc_first_update
 *                               �Eproc_status_update
 *                               �Eproc_parent_item_update
 *                               �Eproc_comp_apply_update
 *  proc_first_update         ����o�^�f�[�^���� (A-3)
 *  proc_status_update        �i�ڃX�e�[�^�X�ύX
 *                               �Eproc_item_status_update
 *                               �Eproc_inherit_parent
 *  proc_item_status_update   �i�ڃX�e�[�^�X���f���� (A-5)
 *                               �Evalidate_item
 *  validate_item             �f�[�^�Ó����`�F�b�N (A-4)
 *  proc_inherit_parent       �e�i�ڏ��̌p�� (A-6)
 *  proc_parent_item_update   �e�i�ڕύX���̌p�� (A-7)
 *  proc_comp_apply_update    �i�ڕύX�K�p�ςݏ��̍X�V (A-8,A-9)
 *  submain                   ���C�������v���V�[�W��
 *                               �Eproc_init
 *                               �Eloop_main
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                               �Esubmain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/06    1.0   H.Yoshikawa      main�V�K�쐬
 *  2009/01/20    1.1   H.Yoshikawa      �P�̃e�X�g�s��ɂ��C��
 *  2009/01/27    1.2   H.Yoshikawa      �W�������o�^�܂��̏C��
 *                                      �i���������ׂēo�^����悤�C���j
 *  2009/01/29    1.3   H.Yoshikawa      �e�i�ڂ̉��o�^�ύX���Ɂu���敪�v��K�{���ڂɒǉ�
 *  2009/01/30    1.4   H.Yoshikawa      �����g�D�ύX�ɂ��C��
 *  2009/02/19    1.5   H.Yoshikawa      �i�ڃX�e�[�^�X�`�F�b�N��ǉ�
 *  2009/02/20                           �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
 *  2009/03/23    1.6   H.Yoshikawa      ��QNoT1_0037�Ή�      �d��/�e�ρE�d�ʗe�ϋ敪�̐ݒ��ǉ�
 *                                       ��QNoT1_0039�Ή�      �}�X�^��M����(OPM�i��.ATTRIBUTE30)�̐ݒ��ǉ�
 *  2009/04/03    1.7   K.Ito            ��Q�Ή�(T1_0295)      �i��OIF�쐬���Ƀ��b�g�Ǘ�(LOT_CONTROL_CODE)�Ɂu1�v(�Ǘ��Ȃ�)��ǉ�
 *  2009/05/27    1.7   H.Yoshikawa      ��Q�Ή�(T1_0906)      �e�i�ڌp�����ڂ̒ǉ��ycase_conv_inc_num(�P�[�X���Z����)�z
 *  2009/06/11    1.8   H.Yoshikawa      ��Q�Ή�(T1_1366)      ����Q�ύX���A�Q�R�[�h���ύX����悤�C��
 *  2009/07/07    1.9   H.Yoshikawa      ��Q�Ή�(0000364)      �W������_�R���|�[�l���g�敪�s���Ή�
 *                                       ��Q�Ή�(0000365)      �V�K�K�p���̋��l(�艿�E�c�ƌ����E����Q)�ݒ�Ή�
 *  2009/07/15    1.10  H.Yoshikawa      ��Q�Ή�(0000463)      �ۊǒI�Ǘ��̐ݒ�l�Ɂw�Ǘ��Ȃ��x��ݒ�
 *  2009/08/10    1.11  Y.Kuboshima      ��Q�Ή�(0000862)      �W�������`�F�b�N������ǉ�
 *                                       ��Q�Ή�(0000894)      ���t���ڂ̏C��(SYSDATE -> �Ɩ����t)
 *  2009/09/11    1.12  Y.Kuboshima      ��Q�Ή�(0000948)      �P�ʊ��Z���쐬����^�C�~���O��ύX
 *                                                              (��P�ʂ��{�ŃP�[�X�������ݒ肳��Ă���ꍇ -> �{�o�^��)
 *                                       ��Q�Ή�(0001130)      �݌ɑg�D�̏C��(S01 -> Z99)
 *                                       ��Q�Ή�(0001258)      �i�ڃJ�e�S������(Disc)�̑ΏۃJ�e�S����ǉ�
 *                                                              (�i�ڋ敪,���O�敪,���i�敪,�i���敪,�H��Q�R�[�h,�o�����p�Q�R�[�h)
 *  2009/10/16    1.13  Y.Kuboshima      ��Q�Ή�(0001423)      �q�i�ڂ�{�o�^�ɂ��鎞�A�e�i�ڂ��{�o�^�ȊO�̏ꍇ�̓G���[�Ƃ���悤�C��
 *                                                              �W�������p��������ύX
 *  2009/12/24    1.14  Shigeto.Niki     ��Q�Ή�(�{�ғ�_00577) �V�K�i�ړo�^���́A�ۊǒI�Ǘ��Ɂw1:�Ǘ��Ȃ��x��ݒ�
 *                                                              �����i�ڍX�V���́A�ۊǒI�Ǘ��Ɂw�g�D���x���l�x��ݒ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  --����:0
  cv_status_warn               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    --�x��:1
  cv_status_error              CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   --�ُ�:2
  --WHO�J����
  cn_created_by                CONSTANT NUMBER      := fnd_global.user_id;            --CREATED_BY
  cd_creation_date             CONSTANT DATE        := SYSDATE;                       --CREATION_DATE
  cn_last_updated_by           CONSTANT NUMBER      := fnd_global.user_id;            --LAST_UPDATED_BY
  cd_last_update_date          CONSTANT DATE        := SYSDATE;                       --LAST_UPDATE_DATE
  cn_last_update_login         CONSTANT NUMBER      := fnd_global.login_id;           --LAST_UPDATE_LOGIN
  cn_request_id                CONSTANT NUMBER      := fnd_global.conc_request_id;    --REQUEST_ID
  cn_program_application_id    CONSTANT NUMBER      := fnd_global.prog_appl_id;       --PROGRAM_APPLICATION_ID
  cn_program_id                CONSTANT NUMBER      := fnd_global.conc_program_id;    --PROGRAM_ID
  cd_program_update_date       CONSTANT DATE        := SYSDATE;                       --PROGRAM_UPDATE_DATE
  cv_msg_part                  CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                  CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                   VARCHAR2(2000);
  gv_sep_msg                   VARCHAR2(2000);
  gv_exec_user                 VARCHAR2(100);
  gv_conc_name                 VARCHAR2(30);
  gv_conc_status               VARCHAR2(30);
  gn_target_cnt                NUMBER;                    -- �Ώی���
  gn_normal_cnt                NUMBER;                    -- ���팏��
  gn_error_cnt                 NUMBER;                    -- �G���[����
  gn_warn_cnt                  NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt          EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt              EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt       EXCEPTION;
  global_check_lock_expt       EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
--################################  �Œ蕔 END   ##################################
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCMM004A04C';       -- �p�b�P�[�W��
  cv_appl_name_xxcmm           CONSTANT VARCHAR2(10)  := 'XXCMM';              -- �A�h�I���F���ʁE�}�X�^
  --
  cv_date_fmt_std              CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                               -- ���t�����FYYYY/MM/DD
  --
  cv_msg_space                 CONSTANT VARCHAR2(1)   := ' ';
  cv_boot_flag_online          CONSTANT VARCHAR2(1)   := '1';
  cv_boot_flag_batch           CONSTANT VARCHAR2(1)   := '2';
  cv_yes                       CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                        CONSTANT VARCHAR2(1)   := 'N';
  cv_inherit_kbn_hst           CONSTANT VARCHAR2(1)   := '0';                  -- �e�l�p�����敪�y'0'�F�������ɂ��X�V�z
  cv_inherit_kbn_inh           CONSTANT VARCHAR2(1)   := '1';                  -- �e�l�p�����敪�y'1'�F�e�i�ڕύX�ɂ��X�V�z
-- Ver1.6  2009/04/03 Add Start Disc�i��.���b�g�Ǘ�(LOT_CONTROL_CODE)
  cn_lot_control_code_no       CONSTANT NUMBER        := 1;                    -- �u1�v(�Ǘ��Ȃ�)
-- Ver1.6  2009/04/03 Add End
-- Ver1.10 2009/07/15 Add  �ۊǒI�Ǘ�(LOCATION_CONTROL_CODE)�ǉ�
  cn_location_control_code_no  CONSTANT NUMBER        := 1;                    -- �u1�v(�Ǘ��Ȃ�)
-- End1.10
  --
  -- �i�ڃX�e�[�^�X
  cn_itm_status_num_tmp        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;
                                                                               -- ���̔�
  cn_itm_status_pre_reg        CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;
                                                                               -- ���o�^
  cn_itm_status_regist         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;
                                                                               -- �{�o�^
  cn_itm_status_no_sch         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;
                                                                               -- �p
  cn_itm_status_trn_only       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;
                                                                               -- �c�f
  cn_itm_status_no_use         CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                               -- �c
  --
  -- �W������
  cv_whse_code                 CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                               -- �q��
  cv_cost_mthd_code            CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                               -- �������@
  cv_cost_analysis_code        CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                               -- ���̓R�[�h
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
  cv_pro_org_code              CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';   -- �݌ɑg�D�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
  --
  -- ���b�Z�[�W�֘A
  -- ���b�Z�[�W
-- Ver1.7 2009/05/27 Add  ���݃X�e�[�^�X���u�c�v�̏ꍇ�A�i�ڃX�e�[�^�X�ȊO�̕ύX�͕s��
  cv_msg_xxcmm_00430           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00430';   -- �i�ڃX�e�[�^�X�`�F�b�N�G���[
-- End
-- Ver1.5 �`�F�b�N�����ǉ�
  cv_msg_xxcmm_00436           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00436';   -- �q�i�ڃX�e�[�^�X�`�F�b�N�G���[
  cv_msg_xxcmm_00437           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00437';   -- �e�i�ڃX�e�[�^�X�`�F�b�N�G���[
-- End
  cv_msg_xxcmm_00440           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00440';   -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00441           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00441';   -- �f�[�^�擾�G���[(�f�[�^����g�[�N���Ȃ�)
  cv_msg_xxcmm_00442           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00442';   -- �f�[�^�擾�G���[(�ύX�\����)
  cv_msg_xxcmm_00443           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00443';   -- ���b�N�擾�G���[(�ύX�\����)
  cv_msg_xxcmm_00444           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00444';   -- �f�[�^�o�^�G���[(�ύX�\����)
  cv_msg_xxcmm_00445           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00445';   -- �f�[�^�X�V�G���[(�ύX�\����)
  cv_msg_xxcmm_00446           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00446';   -- �f�[�^�擾�G���[(�e�i�ڕύX�ɂ��p����)
  cv_msg_xxcmm_00447           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00447';   -- ���b�N�擾�G���[(�e�i�ڕύX�ɂ��p����)
  cv_msg_xxcmm_00448           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00448';   -- �f�[�^�o�^�G���[(�e�i�ڕύX�ɂ��p����)
  cv_msg_xxcmm_00449           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00449';   -- �f�[�^�X�V�G���[(�e�i�ڕύX�ɂ��p����)
  cv_msg_xxcmm_00450           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00450';   -- �f�[�^�Ó����G���[
  cv_msg_xxcmm_00451           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00451';   -- �����������O
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
  cv_msg_xxcmm_00432           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00432';   -- �W������0�~�G���[
  cv_msg_xxcmm_00433           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00433';   -- �c�ƌ����G���[
-- End1.9
-- 2009/08/10 Ver1.11 ��Q0000862 add start by Y.Kuboshima
  cv_msg_xxcmm_00491           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00491';   -- �W�����������G���[
-- 2009/08/10 Ver1.11 ��Q0000862 add end by Y.Kuboshima
--
-- 2009/10/16 Ver1.13 ��Q0001423 add start by Y.Kuboshima
  cv_msg_xxcmm_00492           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00492';   -- �e�i�ږ{�o�^�X�e�[�^�X�`�F�b�N�G���[
-- 2009/10/16 Ver1.13 ��Q0001423 add start by Y.Kuboshima
--
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
  cv_msg_xxcmm_00002           CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';   -- �v���t�@�C���擾�G���[
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
  --
  -- �g�[�N��
  cv_tkn_param_name            CONSTANT VARCHAR2(100) := 'PARAM_NAME';
  cv_tkn_data_info             CONSTANT VARCHAR2(100) := 'DATA_INFO';
  cv_tkn_table                 CONSTANT VARCHAR2(20)  := 'TABLE';              -- �e�[�u����
  cv_tkn_item_code             CONSTANT VARCHAR2(20)  := 'ITEM_CODE';          -- �i�ڃR�[�h
  cv_tkn_item_status           CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';        -- �i�ڃX�e�[�^�X
  cv_tkn_parent_item           CONSTANT VARCHAR2(20)  := 'PARENT_ITEM';        -- �e�i�ڃR�[�h
  cv_tkn_err_msg               CONSTANT VARCHAR2(20)  := 'ERR_MSG';            -- �G���[���b�Z�[�W
  cv_tkn_data_name             CONSTANT VARCHAR2(20)  := 'DATA_NAME';          -- ������
  cv_tkn_data_cnt              CONSTANT VARCHAR2(20)  := 'DATA_CNT';           -- �f�[�^����
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
  cv_tkn_disc_cost             CONSTANT VARCHAR2(20)  := 'DISC_COST';          -- �c�ƌ���
  cv_tkn_opm_cost              CONSTANT VARCHAR2(20)  := 'OPM_COST';           -- �W������
-- End1.9
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
  cv_tkn_ng_profile            CONSTANT VARCHAR2(20)  := 'NG_PROFILE';         -- �v���t�@�C����
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
  --
  cv_tkn_val_categ_policy_cd   CONSTANT VARCHAR2(30)  := '����Q�J�e�S�����';
-- Ver1.8  2009/06/11  Add  ����Q�R�[�h���ύX���ꂽ�ꍇ�A�Q�R�[�h�ɂ����f
  cv_tkn_val_categ_gun_cd      CONSTANT VARCHAR2(30)  := '�Q�R�[�h�J�e�S�����';
-- End1.8
  cv_tkn_val_categ_prd_class   CONSTANT VARCHAR2(30)  := '�{�Џ��i�敪�J�e�S�����';
  cv_tkn_val_item_status       CONSTANT VARCHAR2(30)  := '�i�ڃX�e�[�^�X���';
  cv_tkn_val_item              CONSTANT VARCHAR2(30)  := '�i��';
  cv_tkn_val_uon_conv          CONSTANT VARCHAR2(30)  := '�敪�Ԋ��Z';
  cv_tkn_val_target_cnt        CONSTANT VARCHAR2(30)  := '��������  �F ';
  cv_tkn_val_item_status_cnt   CONSTANT VARCHAR2(30)  := '�i�ڃX�e�[�^�X�ύX����  �F ';
  cv_tkn_val_policy_group_cnt  CONSTANT VARCHAR2(30)  := '����Q�ύX����  �F ';
  cv_tkn_val_fixed_price_cnt   CONSTANT VARCHAR2(30)  := '�艿�ύX����  �F ';
  cv_tkn_val_disc_cost_cnt     CONSTANT VARCHAR2(30)  := '�c�ƌ����ύX����  �F ';
  cv_tkn_val_error_cnt         CONSTANT VARCHAR2(30)  := '�G���[����  �F ';
  --
  cv_tkn_val_xxcmm_discitem    CONSTANT VARCHAR2(30)  := '�c�������i�ڃA�h�I��';
  cv_tkn_val_xxcmm_itemhst     CONSTANT VARCHAR2(30)  := '�c�������i�ڕύX����';
  cv_tkn_val_discitem_if       CONSTANT VARCHAR2(30)  := '�c�������i�ڃC���^�t�F�[�X';
  cv_tkn_val_disccost_if       CONSTANT VARCHAR2(30)  := '�c�����������C���^�t�F�[�X';
  cv_tkn_val_mtl_item_categ    CONSTANT VARCHAR2(30)  := '�c�������i�ڃJ�e�S������';
  cv_tkn_val_xxcmn_opmitem     CONSTANT VARCHAR2(30)  := '�n�o�l�i�ڃA�h�I��';
  cv_tkn_val_opmitem           CONSTANT VARCHAR2(30)  := '�n�o�l�i��';
  cv_tkn_val_opmcost           CONSTANT VARCHAR2(30)  := '�n�o�l�W������';
  cv_tkn_val_opm_item_categ    CONSTANT VARCHAR2(30)  := '�n�o�l�i�ڃJ�e�S������';
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
  cv_tkn_val_org_code          CONSTANT VARCHAR2(20)  := '�݌ɑg�D�R�[�h';     -- �݌ɑg�D�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
  --
  -- �i�ڃJ�e�S���Z�b�g��
  cv_categ_set_seisakugun      CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_seisakugun;
                                                                               -- ����Q�R�[�h
  cv_categ_set_hon_prod        CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;
                                                                               -- �{�Џ��i�敪
  cv_categ_set_item_prod       CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_prod;
                                                                               -- ���i���i�敪
-- Ver1.8  2009/06/11  Add  ����Q�R�[�h���ύX���ꂽ�ꍇ�A�Q�R�[�h�ɂ����f
  cv_categ_set_baracha_div     CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_baracha_div;
                                                                               -- �o�����敪
  cv_categ_set_mark_pg         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_mark_pg;
                                                                               -- �}�[�P�p�Q�R�[�h
  cv_categ_set_gun_code        CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_gun_code;
                                                                               -- �Q�R�[�h
-- End1.8
-- 2009/09/11 Ver1.12 ��Q0001258 add start by Y.Kuboshima
  cv_categ_set_item_div        CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_item_div;
                                                                               -- �i�ڋ敪
  cv_categ_set_inout_div       CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_inout_div;
                                                                               -- ���O�敪
  cv_categ_set_product_div     CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_product_div;
                                                                               -- ���i�敪
  cv_categ_set_quality_div     CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_quality_div;
                                                                               -- �i���敪
  cv_categ_set_fact_pg         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_fact_pg;
                                                                               -- �H��Q�R�[�h
  cv_categ_set_acnt_pg         CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_acnt_pg;
                                                                               -- �o�����p�Q�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001258 add end by Y.Kuboshima
  --
  -- ���b�N�A�b�v
  cv_lookup_item_status        CONSTANT VARCHAR2(20)  := 'XXCMM_ITM_STATUS';   -- �i�ڃX�e�[�^�X
  cv_lookup_cost_cmpt          CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';   -- �W�������R���|�[�l���g
-- 2009/09/11 Ver1.12 ��Q0000948 add start by Y.Kuboshima
  cv_lookup_item_um            CONSTANT VARCHAR2(30)  := 'XXCMM_UNITS_OF_MEASURE';   -- ��P��
-- 2009/09/11 Ver1.12 ��Q0000948 add end by Y.Kuboshima
  --
-- 2009/08/10 Ver1.11 ��Q0000862 add start by Y.Kuboshima
  -- ���ޕi��
  cv_leaf_material             CONSTANT VARCHAR2(1)   := '5';                  -- ���ޕi��(���[�t)
  cv_drink_material            CONSTANT VARCHAR2(1)   := '6';                  -- ���ޕi��(�h�����N)
-- 2009/08/10 Ver1.11 ��Q0000862 add end by Y.Kuboshima
-- 2009/08/10 Ver1.11 ��Q0000894 move start by Y.Kuboshima
-- ���̈ʒu�ł�gd_process_date�͂܂���`����Ă��Ȃ����߁A�J�[�\�������ֈړ����܂��B
--
--  -- �ύX�K�p�i�ڒ��o�J�[�\��
--  CURSOR update_item_cur(
--    pd_apply_date        DATE )
--  IS
--    SELECT      xsibh.item_hst_id                                       -- �i�ڕύX����ID
--               ,1                     AS  item_div                      -- �e�q�敪�i1:�e�i�ځj
--               ,xoiv.inventory_item_id                                  -- Disc�i��ID
--               ,xoiv.item_id                                            -- OPM�i��ID
--               ,xoiv.parent_item_id                                     -- �e���iID
--               ,xoiv.item_no                                            -- �i�ڃR�[�h
--               ,xoiv.item_status      AS  b_item_status                 -- �ύX�O�i�ڃX�e�[�^�X
--               ,xoiv.item_um                                            -- ��P��        �iOPM�i�ځj
--               ,xoiv.num_of_cases                                       -- �P�[�X����      �iOPM�i�ځj
--               ,xoiv.sales_div                                          -- ����Ώۋ敪    �iOPM�i�ځj
--               ,xoiv.net                                                -- NET             �iOPM�i�ځj
--               ,xoiv.unit                                               -- �d��            �iOPM�i�ځj
--               ,xoiv.crowd_code_new                                     -- �V�E����Q�R�[�h�iOPM�i�ځj
--               ,xoiv.price_new                                          -- �V�E�艿        �iOPM�i�ځj
--               ,xoiv.opt_cost_new                                       -- �V�E�c�ƌ���    �iOPM�i�ځj
--               ,xoiv.item_name_alt                                      -- �J�i��          �iOPM�i�ڃA�h�I���j
--               ,xoiv.rate_class                                         -- ���敪          �iOPM�i�ڃA�h�I���j
--               ,xoiv.palette_max_cs_qty                                 -- �z��            �iOPM�i�ڃA�h�I���j
--               ,xoiv.palette_max_step_qty                               -- �i��            �iOPM�i�ڃA�h�I���j
--               ,xoiv.nets                                               -- ���e��          �iDisc�i�ڃA�h�I���j
--               ,xoiv.nets_uom_code                                      -- ���e�ʒP��      �iDisc�i�ڃA�h�I���j
--               ,xoiv.inc_num                                            -- �������        �iDisc�i�ڃA�h�I���j
--               ,xoiv.baracha_div                                        -- �o�����敪      �iDisc�i�ڃA�h�I���j
--               ,xoiv.sp_supplier_code                                   -- ���X�d����    �iDisc�i�ڃA�h�I���j
--               ,xsibh.apply_date                                        -- �K�p���i�K�p�J�n���j
--               ,xsibh.apply_flag                                        -- �K�p�L��
--               ,xsibh.item_status                                       -- �i�ڃX�e�[�^�X
--               ,xsibh.policy_group                                      -- �Q�R�[�h�i����Q�R�[�h�j
--               ,xsibh.fixed_price                                       -- �艿
--               ,xsibh.discrete_cost                                     -- �c�ƌ���
--               ,xsibh.first_apply_flag                                  -- ����K�p�t���O
--               ,xoiv.purchasing_item_flag                               -- �w���i��
--               ,xoiv.shippable_item_flag                                -- �o�׉\
--               ,xoiv.customer_order_flag                                -- �ڋq��
--               ,xoiv.purchasing_enabled_flag                            -- �w���\
--               ,xoiv.internal_order_enabled_flag                        -- �Г�����
--               ,xoiv.so_transactions_flag                               -- OE ����\
--               ,xoiv.reservable_type                                    -- �\��\
--    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc�i�ڕύX�����A�h�I��
--               ,xxcmm_opmmtl_items_v      xoiv                          -- �i�ڃr���[
--    WHERE       xsibh.apply_date       <= pd_apply_date                 -- �K�p��(�N�����t�őΏۂƂȂ�Ȃ��������邩��)
--    AND         xsibh.apply_flag        = cv_no                         -- ���K�p
--    AND         xoiv.item_no            = xsibh.item_code               -- �i�ڃR�[�h
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- �K�p�J�n��
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- �K�p�I����
--    AND         xoiv.start_date_active <= gd_process_date               -- �K�p�J�n��
--    AND         xoiv.end_date_active   >= gd_process_date               -- �K�p�I����
--    AND         xoiv.item_id            = xoiv.parent_item_id           -- �e�i��
--    --
--    UNION ALL
--    --
--    SELECT      xsibh.item_hst_id                                       -- �i�ڕύX����ID
--               ,2                     AS  item_div                      -- �e�q�敪�i2:�q�i�ځj
--               ,xoiv.inventory_item_id                                  -- Disc�i��ID
--               ,xoiv.item_id                                            -- OPM�i��ID
--               ,xoiv.parent_item_id                                     -- �e���iID
--               ,xoiv.item_no                                            -- �i�ڃR�[�h
--               ,xoiv.item_status      AS  b_item_status                 -- �ύX�O�i�ڃX�e�[�^�X
--               ,xoiv.item_um                                            -- ��P��        �iOPM�i�ځj
--               ,xoiv.num_of_cases                                       -- �P�[�X����      �iOPM�i�ځj
--               ,xoiv.sales_div                                          -- ����Ώۋ敪    �iOPM�i�ځj
--               ,xoiv.net                                                -- NET             �iOPM�i�ځj
--               ,xoiv.unit                                               -- �d��            �iOPM�i�ځj
--               ,xoiv.crowd_code_new                                     -- �V�E����Q�R�[�h�iOPM�i�ځj
--               ,xoiv.price_new                                          -- �V�E�艿        �iOPM�i�ځj
--               ,xoiv.opt_cost_new                                       -- �V�E�c�ƌ���    �iOPM�i�ځj
--               ,xoiv.item_name_alt                                      -- �J�i��          �iOPM�i�ڃA�h�I���j
--               ,xoiv.rate_class                                         -- ���敪          �iOPM�i�ڃA�h�I���j
--               ,xoiv.palette_max_cs_qty                                 -- �z��            �iOPM�i�ڃA�h�I���j
--               ,xoiv.palette_max_step_qty                               -- �i��            �iOPM�i�ڃA�h�I���j
--               ,xoiv.nets                                               -- ���e��          �iDisc�i�ڃA�h�I���j
--               ,xoiv.nets_uom_code                                      -- ���e�ʒP��      �iDisc�i�ڃA�h�I���j
--               ,xoiv.inc_num                                            -- �������        �iDisc�i�ڃA�h�I���j
--               ,xoiv.baracha_div                                        -- �o�����敪      �iDisc�i�ڃA�h�I���j
--               ,xoiv.sp_supplier_code                                   -- ���X�d����    �iDisc�i�ڃA�h�I���j
--               ,xsibh.apply_date                                        -- �K�p���i�K�p�J�n���j
--               ,xsibh.apply_flag                                        -- �K�p�L��
--               ,xsibh.item_status                                       -- �i�ڃX�e�[�^�X
--               ,xsibh.policy_group                                      -- �Q�R�[�h�i����Q�R�[�h�j
--               ,xsibh.fixed_price                                       -- �艿
--               ,xsibh.discrete_cost                                     -- �c�ƌ���
--               ,xsibh.first_apply_flag                                  -- ����K�p�t���O
--               ,xoiv.purchasing_item_flag                               -- �w���i��
--               ,xoiv.shippable_item_flag                                -- �o�׉\
--               ,xoiv.customer_order_flag                                -- �ڋq��
--               ,xoiv.purchasing_enabled_flag                            -- �w���\
--               ,xoiv.internal_order_enabled_flag                        -- �Г�����
--               ,xoiv.so_transactions_flag                               -- OE ����\
--               ,xoiv.reservable_type                                    -- �\��\
--    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc�i�ڕύX�����A�h�I��
--               ,xxcmm_opmmtl_items_v      xoiv                          -- �i�ڃr���[
--    WHERE       xsibh.apply_date       <= pd_apply_date                 -- �K�p��(�N�����t�őΏۂƂȂ�Ȃ��������邩��)
--    AND         xsibh.apply_flag        = cv_no                         -- ���K�p
--    AND         xoiv.item_no            = xsibh.item_code               -- �i�ڃR�[�h
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- �K�p�J�n��
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- �K�p�I����
---- Ver1.1 2009/01/14 MOD �e�X�g�V�i���I 4-3
----    AND         xoiv.item_id           != xoiv.parent_item_id           -- �e�i��
--    AND      (  xoiv.item_id           != xoiv.parent_item_id           -- �e�i�ڂłȂ�
--             OR xoiv.parent_item_id    IS NULL )                        -- �e�i�ڂ����ݒ�
---- Ver1.1 MOD END
--    ORDER BY    item_div
--               ,apply_date
--               ,first_apply_flag
--               ,item_no;
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_boot_flag                 VARCHAR2(1);                                    -- �N�����
  gn_bus_org_id                mtl_parameters.organization_id%TYPE;            -- �c�Ƒg�DID[Z99]
  gn_cost_org_id               mtl_parameters.cost_organization_id%TYPE;       -- �����g�DID[ZZZ]
  gn_master_org_id             mtl_parameters.master_organization_id%TYPE;     -- �}�X�^�[�݌ɑg�DID[ZZZ]
  --
-- Ver1.5 2009/02/20 Add �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
  gd_process_date              DATE;                                           -- �Ɩ����t
--
  gd_apply_date                DATE;                                           -- �K�p��
  gv_inherit_kbn               VARCHAR2(1);                                    -- �e�l�p�����敪�y'0'�F�������ɂ��X�V�A'1'�F�e�i�ڕύX�ɂ��X�V�z
  --
  gn_item_status_cnt           NUMBER;                                         -- �X�e�[�^�X�X�V����
  gn_policy_group_cnt          NUMBER;                                         -- ����Q�X�V����  �i�ύX�����x�[�X�j
  gn_fixed_price_cnt           NUMBER;                                         -- �艿�X�V����    �i�ύX�����x�[�X�j
  gn_discrete_cost_cnt         NUMBER;                                         -- �c�ƌ����X�V�����i�ύX�����x�[�X�j
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
  gv_bus_org_code              VARCHAR2(3);                                    -- �݌ɑg�D�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  -- �i�ڃX�e�[�^�X���f
  TYPE item_status_rtype IS RECORD
  (
    item_id                        ic_item_mst_b.item_id%TYPE                             -- �i��ID
   ,apply_date                     xxcmm_system_items_b_hst.apply_date%TYPE               -- �K�p��
   ,item_status                    xxcmm_system_items_b_hst.item_status%TYPE              -- �i�ڃX�e�[�^�X
   ,inventory_item_id              mtl_system_items_b.inventory_item_id%TYPE              -- Disc�i��ID
   ,organization_id                mtl_system_items_b.organization_id%TYPE                -- �g�DID
   ,purchasing_item_flag           mtl_system_items_b.purchasing_item_flag%TYPE           -- �w���i��
   ,shippable_item_flag            mtl_system_items_b.shippable_item_flag%TYPE            -- �o�׉\
   ,customer_order_flag            mtl_system_items_b.customer_order_flag%TYPE            -- �ڋq��
   ,purchasing_enabled_flag        mtl_system_items_b.purchasing_enabled_flag%TYPE        -- �w���\
   ,internal_order_enabled_flag    mtl_system_items_b.internal_order_enabled_flag%TYPE    -- �Г�����
   ,so_transactions_flag           mtl_system_items_b.so_transactions_flag%TYPE           -- OE ����\
   ,reservable_type                mtl_system_items_b.reservable_type%TYPE                -- �\��\
  );
  --
-- 2009/08/10 Ver1.11 move start by Y.Kuboshima
  -- �ύX�K�p�i�ڒ��o�J�[�\��
  CURSOR update_item_cur(
    pd_apply_date        DATE )
  IS
    SELECT      xsibh.item_hst_id                                       -- �i�ڕύX����ID
               ,1                     AS  item_div                      -- �e�q�敪�i1:�e�i�ځj
               ,xoiv.inventory_item_id                                  -- Disc�i��ID
               ,xoiv.item_id                                            -- OPM�i��ID
               ,xoiv.parent_item_id                                     -- �e���iID
               ,xoiv.item_no                                            -- �i�ڃR�[�h
               ,xoiv.item_status      AS  b_item_status                 -- �ύX�O�i�ڃX�e�[�^�X
               ,xoiv.item_um                                            -- ��P��        �iOPM�i�ځj
               ,xoiv.num_of_cases                                       -- �P�[�X����      �iOPM�i�ځj
               ,xoiv.sales_div                                          -- ����Ώۋ敪    �iOPM�i�ځj
               ,xoiv.net                                                -- NET             �iOPM�i�ځj
               ,xoiv.unit                                               -- �d��            �iOPM�i�ځj
               ,xoiv.crowd_code_new                                     -- �V�E����Q�R�[�h�iOPM�i�ځj
               ,xoiv.price_new                                          -- �V�E�艿        �iOPM�i�ځj
               ,xoiv.opt_cost_new                                       -- �V�E�c�ƌ���    �iOPM�i�ځj
               ,xoiv.item_name_alt                                      -- �J�i��          �iOPM�i�ڃA�h�I���j
               ,xoiv.rate_class                                         -- ���敪          �iOPM�i�ڃA�h�I���j
               ,xoiv.palette_max_cs_qty                                 -- �z��            �iOPM�i�ڃA�h�I���j
               ,xoiv.palette_max_step_qty                               -- �i��            �iOPM�i�ڃA�h�I���j
               ,xoiv.nets                                               -- ���e��          �iDisc�i�ڃA�h�I���j
               ,xoiv.nets_uom_code                                      -- ���e�ʒP��      �iDisc�i�ڃA�h�I���j
               ,xoiv.inc_num                                            -- �������        �iDisc�i�ڃA�h�I���j
               ,xoiv.baracha_div                                        -- �o�����敪      �iDisc�i�ڃA�h�I���j
               ,xoiv.sp_supplier_code                                   -- ���X�d����    �iDisc�i�ڃA�h�I���j
               ,xsibh.apply_date                                        -- �K�p���i�K�p�J�n���j
               ,xsibh.apply_flag                                        -- �K�p�L��
               ,xsibh.item_status                                       -- �i�ڃX�e�[�^�X
               ,xsibh.policy_group                                      -- �Q�R�[�h�i����Q�R�[�h�j
               ,xsibh.fixed_price                                       -- �艿
               ,xsibh.discrete_cost                                     -- �c�ƌ���
               ,xsibh.first_apply_flag                                  -- ����K�p�t���O
               ,xoiv.purchasing_item_flag                               -- �w���i��
               ,xoiv.shippable_item_flag                                -- �o�׉\
               ,xoiv.customer_order_flag                                -- �ڋq��
               ,xoiv.purchasing_enabled_flag                            -- �w���\
               ,xoiv.internal_order_enabled_flag                        -- �Г�����
               ,xoiv.so_transactions_flag                               -- OE ����\
               ,xoiv.reservable_type                                    -- �\��\
    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc�i�ڕύX�����A�h�I��
               ,xxcmm_opmmtl_items_v      xoiv                          -- �i�ڃr���[
    WHERE       xsibh.apply_date       <= pd_apply_date                 -- �K�p��(�N�����t�őΏۂƂȂ�Ȃ��������邩��)
    AND         xsibh.apply_flag        = cv_no                         -- ���K�p
    AND         xoiv.item_no            = xsibh.item_code               -- �i�ڃR�[�h
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- �K�p�J�n��
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- �K�p�I����
    AND         xoiv.start_date_active <= gd_process_date               -- �K�p�J�n��
    AND         xoiv.end_date_active   >= gd_process_date               -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
    AND         xoiv.item_id            = xoiv.parent_item_id           -- �e�i��
    --
    UNION ALL
    --
    SELECT      xsibh.item_hst_id                                       -- �i�ڕύX����ID
               ,2                     AS  item_div                      -- �e�q�敪�i2:�q�i�ځj
               ,xoiv.inventory_item_id                                  -- Disc�i��ID
               ,xoiv.item_id                                            -- OPM�i��ID
               ,xoiv.parent_item_id                                     -- �e���iID
               ,xoiv.item_no                                            -- �i�ڃR�[�h
               ,xoiv.item_status      AS  b_item_status                 -- �ύX�O�i�ڃX�e�[�^�X
               ,xoiv.item_um                                            -- ��P��        �iOPM�i�ځj
               ,xoiv.num_of_cases                                       -- �P�[�X����      �iOPM�i�ځj
               ,xoiv.sales_div                                          -- ����Ώۋ敪    �iOPM�i�ځj
               ,xoiv.net                                                -- NET             �iOPM�i�ځj
               ,xoiv.unit                                               -- �d��            �iOPM�i�ځj
               ,xoiv.crowd_code_new                                     -- �V�E����Q�R�[�h�iOPM�i�ځj
               ,xoiv.price_new                                          -- �V�E�艿        �iOPM�i�ځj
               ,xoiv.opt_cost_new                                       -- �V�E�c�ƌ���    �iOPM�i�ځj
               ,xoiv.item_name_alt                                      -- �J�i��          �iOPM�i�ڃA�h�I���j
               ,xoiv.rate_class                                         -- ���敪          �iOPM�i�ڃA�h�I���j
               ,xoiv.palette_max_cs_qty                                 -- �z��            �iOPM�i�ڃA�h�I���j
               ,xoiv.palette_max_step_qty                               -- �i��            �iOPM�i�ڃA�h�I���j
               ,xoiv.nets                                               -- ���e��          �iDisc�i�ڃA�h�I���j
               ,xoiv.nets_uom_code                                      -- ���e�ʒP��      �iDisc�i�ڃA�h�I���j
               ,xoiv.inc_num                                            -- �������        �iDisc�i�ڃA�h�I���j
               ,xoiv.baracha_div                                        -- �o�����敪      �iDisc�i�ڃA�h�I���j
               ,xoiv.sp_supplier_code                                   -- ���X�d����    �iDisc�i�ڃA�h�I���j
               ,xsibh.apply_date                                        -- �K�p���i�K�p�J�n���j
               ,xsibh.apply_flag                                        -- �K�p�L��
               ,xsibh.item_status                                       -- �i�ڃX�e�[�^�X
               ,xsibh.policy_group                                      -- �Q�R�[�h�i����Q�R�[�h�j
               ,xsibh.fixed_price                                       -- �艿
               ,xsibh.discrete_cost                                     -- �c�ƌ���
               ,xsibh.first_apply_flag                                  -- ����K�p�t���O
               ,xoiv.purchasing_item_flag                               -- �w���i��
               ,xoiv.shippable_item_flag                                -- �o�׉\
               ,xoiv.customer_order_flag                                -- �ڋq��
               ,xoiv.purchasing_enabled_flag                            -- �w���\
               ,xoiv.internal_order_enabled_flag                        -- �Г�����
               ,xoiv.so_transactions_flag                               -- OE ����\
               ,xoiv.reservable_type                                    -- �\��\
    FROM        xxcmm_system_items_b_hst  xsibh                         -- Disc�i�ڕύX�����A�h�I��
               ,xxcmm_opmmtl_items_v      xoiv                          -- �i�ڃr���[
    WHERE       xsibh.apply_date       <= pd_apply_date                 -- �K�p��(�N�����t�őΏۂƂȂ�Ȃ��������邩��)
    AND         xsibh.apply_flag        = cv_no                         -- ���K�p
    AND         xoiv.item_no            = xsibh.item_code               -- �i�ڃR�[�h
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--    AND         xoiv.start_date_active <= TRUNC( SYSDATE )              -- �K�p�J�n��
--    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )              -- �K�p�I����
    AND         xoiv.start_date_active <= gd_process_date               -- �K�p�J�n��
    AND         xoiv.end_date_active   >= gd_process_date               -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
-- Ver1.1 2009/01/14 MOD �e�X�g�V�i���I 4-3
--    AND         xoiv.item_id           != xoiv.parent_item_id           -- �e�i��
    AND      (  xoiv.item_id           != xoiv.parent_item_id           -- �e�i�ڂłȂ�
             OR xoiv.parent_item_id    IS NULL )                        -- �e�i�ڂ����ݒ�
-- Ver1.1 MOD END
    ORDER BY    item_div
               ,apply_date
               ,first_apply_flag
               ,item_no;
--
  /**********************************************************************************
   * Procedure Name   : proc_comp_apply_update
   * Description      : �i�ڕύX�K�p�ςݏ��̍X�V
   **********************************************************************************/
  PROCEDURE proc_comp_apply_update(
    i_update_item_rec   IN     update_item_cur%ROWTYPE
   ,ov_errbuf           OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_COMP_APPLY_UPDATE'; -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_step                    VARCHAR2(10);
    --
    -- *** ���[�J���ϐ� ***
    lv_msg_token               VARCHAR2(100);
    lv_msg_errm                VARCHAR2(4000);
    --
    lv_policy_group            VARCHAR2(4);     -- ����Q�R�[�h
    ln_fixed_price             NUMBER;          -- �艿
    ln_discrete_cost           NUMBER;          -- �c�ƌ���
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- Disc�i�ڃA�h�I�����b�N�J�[�\��
    CURSOR xxcmm_item_lock_cur(
      pv_item_code    VARCHAR2 )
    IS
      SELECT    'x'
      FROM      xxcmm_system_items_b
      WHERE     item_code = pv_item_code
      FOR UPDATE NOWAIT;
    --
    -- Disc�i�ڕύX�������b�N�J�[�\��
    CURSOR xxcmm_item_hst_lock_cur(
      pn_item_hst_id    NUMBER )
    IS
      SELECT    'x'
      FROM      xxcmm_system_items_b_hst
      WHERE     item_hst_id = pn_item_hst_id
      FOR UPDATE NOWAIT;
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    data_update_err_expt            EXCEPTION;    -- �f�[�^�X�V�G���[
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
    --A-8 Disc�i�ڃA�h�I���̍X�V
    --==============================================================
    --==============================================================
    --A-8.1 Disc�i�ڃA�h�I���̃��b�N�擾
    --==============================================================
    lv_step := 'STEP-11010';
    lv_msg_token := cv_tkn_val_xxcmm_discitem;
    --
    OPEN   xxcmm_item_lock_cur( i_update_item_rec.item_no );
    CLOSE  xxcmm_item_lock_cur;
    --
    --==============================================================
    --A-8.2 Disc�i�ڃA�h�I���̍X�V
    --==============================================================
    BEGIN
      IF ( i_update_item_rec.parent_item_id IS NULL 
        OR i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
        --
        -- �e�i�ږ��ݒ莞�A�܂��́A�i�ڃX�e�[�^�X���c�̏ꍇ�͐e�i�ڏ�񂩂�X�V���Ȃ��B
        lv_step := 'STEP-11020';
        UPDATE      xxcmm_system_items_b    -- Disc�i�ڃA�h�I��
-- Ver1.5 2009/02/20 Mod �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--        SET         search_update_date     = i_update_item_rec.apply_date
                    -- �����ΏۍX�V��
        SET         search_update_date     = gd_process_date
-- End
                    -- �i�ڃX�e�[�^�X
                   ,item_status            = NVL( i_update_item_rec.item_status, item_status )
                    -- �i�ڃX�e�[�^�X�K�p��
                   ,item_status_apply_date = NVL2( i_update_item_rec.item_status, i_update_item_rec.apply_date
                                                                                , item_status_apply_date )
                    --
                   ,last_updated_by        = cn_last_updated_by
                   ,last_update_date       = cd_last_update_date
                   ,last_update_login      = cn_last_update_login
                   ,request_id             = cn_request_id
                   ,program_application_id = cn_program_application_id
                   ,program_id             = cn_program_id
                   ,program_update_date    = cd_program_update_date
                    --
        WHERE       item_code              = i_update_item_rec.item_no;
        --
      ELSE
        -- �e�i�ڐݒ莞�A���A�i�ڃX�e�[�^�X���c�ȊO�̏ꍇ�A
        -- �e�i�ڏ�񂩂���e�ʁA��������A�o�����敪�A�P�[�XJAN�A�{�[�������A�e��Q�A�o���Q�A
        --               �o���e��Q�A�u�����h�Q�A���X�d���� ��ݒ肷��
        --�i�e�i�ڂ̏ꍇ�������R�[�h�̒l���ݒ肳��邽�ߎ����X�V����Ȃ��B�j
        lv_step := 'STEP-11030';
        UPDATE      xxcmm_system_items_b    xsib    -- Disc�i�ڃA�h�I��
        SET       ( search_update_date              -- �����ΏۍX�V��
                   ,item_status                     -- �i�ڃX�e�[�^�X
                   ,item_status_apply_date          -- �i�ڃX�e�[�^�X�K�p��
                    --
                   ,nets                            -- ���e��
                   ,inc_num                         -- �������
                   ,baracha_div                     -- �o�����敪
                   ,case_jan_code                   -- �P�[�XJAN
                   ,bowl_inc_num                    -- �{�[������
                   ,vessel_group                    -- �e��Q
                   ,acnt_group                      -- �o���Q
                   ,acnt_vessel_group               -- �o���e��Q
                   ,brand_group                     -- �u�����h�Q
                   ,sp_supplier_code                -- ���X�d����
-- Ver1.7 2009/05/27 Add  �P�[�X���Z�������p�����ڂɒǉ��iT1_0906�j
                   ,case_conv_inc_num               -- �P�[�X���Z����
-- End
                    --
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                   ,request_id
                   ,program_application_id
                   ,program_id
                   ,program_update_date )
               =  ( SELECT
-- Ver1.5 2009/02/20 Mod �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--                                i_update_item_rec.apply_date
                                -- �����ΏۍX�V��
                                gd_process_date
-- End
                                -- �i�ڃX�e�[�^�X
                               ,NVL( i_update_item_rec.item_status, xsib.item_status )
                                -- �i�ڃX�e�[�^�X�K�p��
                               ,NVL2( i_update_item_rec.item_status, i_update_item_rec.apply_date
                                    , xsib.item_status_apply_date )
                               ,parent_xsib.nets                      -- ���e��
                               ,parent_xsib.inc_num                   -- �������
                               ,parent_xsib.baracha_div               -- �o�����敪
                               ,parent_xsib.case_jan_code             -- �P�[�XJAN
                               ,parent_xsib.bowl_inc_num              -- �{�[������
                               ,parent_xsib.vessel_group              -- �e��Q
                               ,parent_xsib.acnt_group                -- �o���Q
                               ,parent_xsib.acnt_vessel_group         -- �o���e��Q
                               ,parent_xsib.brand_group               -- �u�����h�Q
                               ,parent_xsib.sp_supplier_code          -- ���X�d����
-- Ver1.7 2009/05/27 Add  �P�[�X���Z�������p�����ڂɒǉ��iT1_0906�j
                               ,parent_xsib.case_conv_inc_num         -- �P�[�X���Z����
-- End
                               ,cn_last_updated_by
                               ,cd_last_update_date
                               ,cn_last_update_login
                               ,cn_request_id
                               ,cn_program_application_id
                               ,cn_program_id
                               ,cd_program_update_date
                    FROM        xxcmm_opmmtl_items_v    xoiv          -- �i�ڃr���[
                               ,ic_item_mst_b           iimb          -- OPM�i��
                               ,xxcmm_system_items_b    parent_xsib   -- Disc�i�ڃA�h�I��
                    WHERE       xoiv.item_no            = i_update_item_rec.item_no
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--                    AND         xoiv.start_date_active <= TRUNC( SYSDATE )
--                    AND         xoiv.end_date_active   >= TRUNC( SYSDATE )
                    AND         xoiv.start_date_active <= gd_process_date
                    AND         xoiv.end_date_active   >= gd_process_date
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
                    AND         iimb.item_id            = xoiv.parent_item_id
                    AND         parent_xsib.item_code   = iimb.item_no )
        WHERE       item_code = i_update_item_rec.item_no;
        --
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg_errm  := SQLERRM;
        lv_msg_token := cv_tkn_val_xxcmm_discitem;
        RAISE data_update_err_expt;  -- �X�V�G���[
    END;
    --
    --==============================================================
    --A-9 Disc�i�ڕύX�����A�h�I���̍X�V
    --==============================================================
    --==============================================================
    --A-9.1 Disc�i�ڕύX�����A�h�I���̃��b�N�擾
    --==============================================================
    lv_step := 'STEP-11030';
    lv_msg_token := cv_tkn_val_xxcmm_itemhst;
    --
    OPEN   xxcmm_item_hst_lock_cur( i_update_item_rec.item_hst_id );
    CLOSE  xxcmm_item_hst_lock_cur;
    --
    --==============================================================
    --A-9.2 Disc�i�ڕύX�����A�h�I���̍X�V
    --==============================================================
    lv_step := 'STEP-11040';
    BEGIN
      UPDATE      xxcmm_system_items_b_hst
      SET         apply_flag              =  cv_yes
                  --
                 ,last_updated_by         =  cn_last_updated_by
                 ,last_update_date        =  cd_last_update_date
                 ,last_update_login       =  cn_last_update_login
                 ,request_id              =  cn_request_id
                 ,program_application_id  =  cn_program_application_id
                 ,program_id              =  cn_program_id
                 ,program_update_date     =  cd_program_update_date
                  --
      WHERE       item_hst_id             =  i_update_item_rec.item_hst_id;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg_errm  := SQLERRM;
        lv_msg_token := cv_tkn_val_xxcmm_itemhst;
        RAISE data_update_err_expt;  -- �X�V�G���[
    END;
    --
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( xxcmm_item_lock_cur%ISOPEN ) THEN
        CLOSE  xxcmm_item_lock_cur;
      END IF;
      --
      -- �J�[�\���N���[�Y
      IF ( xxcmm_item_hst_lock_cur%ISOPEN ) THEN
        CLOSE  xxcmm_item_hst_lock_cur;
      END IF;
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00443            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN data_update_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00445            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_msg_errm                   -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END proc_comp_apply_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_item_update
   * Description      : �i�ڍX�V����(A-7)
   **********************************************************************************/
  PROCEDURE proc_item_update(
    in_item_id            IN     NUMBER             --   OPM�i��ID
   ,in_inventory_item_id  IN     NUMBER             --   Disc�i��ID
   ,iv_item_no            IN     VARCHAR2           --   �i�ڃR�[�h
   ,iv_policy_group       IN     VARCHAR2           --   ����Q�R�[�h
   ,in_fixed_price        IN     NUMBER             --   �艿
   ,in_discrete_cost      IN     NUMBER             --   �c�ƌ���
   ,in_organization_id    IN     NUMBER             --   Disc�i�ڌ����g�DID
   ,iv_apply_date         IN     VARCHAR2           --   �K�p��
   ,iv_parent_item        IN     VARCHAR2 DEFAULT NULL
                                                    --   �e�i�ڃR�[�h
   ,ov_errbuf             OUT    VARCHAR2           --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2           --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_ITEM_UPDATE'; -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cn_process_flag              CONSTANT NUMBER(1)    := 1;
    cn_group_id                  CONSTANT NUMBER       := 1000;
    cv_cost_element              CONSTANT VARCHAR2(10) := '����';            -- �����v�f
    cv_resource_code             CONSTANT VARCHAR2(10) := '�c�ƌ���';        -- �������v�f
    --
-- Ver1.6 2009/03/23 ADD  ��QNo39�Ή� �}�X�^��M����(OPM�i��.ATTRIBUTE30)�̐ݒ��ǉ�
    cv_date_format_rmd           CONSTANT VARCHAR2(10) := 'RRRR/MM/DD';      -- �}�X�^��M�����t�H�[�}�b�g
-- Ver1.6 ADD END
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    lv_msg_errm                  VARCHAR2(4000);
    ln_exsits_count              NUMBER;
    --
    ln_category_set_id           mtl_category_sets.category_set_id%TYPE;     -- �J�e�S���Z�b�gID
    ln_category_id               mtl_categories.category_id%TYPE;            -- �J�e�S��ID
    --
    -- ���R�[�h�^
    l_opm_item_rec               ic_item_mst_b%ROWTYPE;
    l_opmitem_category_rec       xxcmm_004common_pkg.opmitem_category_rtype;
    l_discitem_category_rec      xxcmm_004common_pkg.discitem_category_rtype;
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    data_rock_err_expt           EXCEPTION;    -- �f�[�^���o�G���[
    data_select_err_expt         EXCEPTION;    -- �f�[�^���o�G���[
    data_insert_err_expt         EXCEPTION;    -- �f�[�^�o�^�G���[
    data_update_err_expt         EXCEPTION;    -- �f�[�^�X�V�G���[
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
    --A-7.6-0 OPM�i�ړo�^���̒��o
    --==============================================================
    -- OPM�i�ڃ}�X�^�̍X�V��API���g�p 
    lv_step := 'STEP-10010';
    lv_msg_token := cv_tkn_val_opmitem;
    --
    BEGIN
      -- �S���ڎw�肪�K�v�Ȃ̂œo�^�f�[�^���擾����B
      -- �p�����鍀�ڂ͐e�i�ڂ���擾�i�e�i�ڎ����j
      SELECT      iimb.item_id
                 ,iimb.item_no
                 ,iimb.item_desc1
                 ,iimb.item_desc2
                 ,iimb.alt_itema
                 ,iimb.alt_itemb
                 ,iimb.item_um
                 ,iimb.dualum_ind
                 ,iimb.item_um2
                 ,iimb.deviation_lo
                 ,iimb.deviation_hi
                 ,iimb.level_code
                 ,iimb.lot_ctl
                 ,iimb.lot_indivisible
                 ,iimb.sublot_ctl
                 ,iimb.loct_ctl
                 ,iimb.noninv_ind
                 ,iimb.match_type
                 ,iimb.inactive_ind
                 ,iimb.inv_type
                 ,iimb.shelf_life
                 ,iimb.retest_interval
                 ,iimb.gl_class
                 ,iimb.inv_class
                 ,iimb.sales_class
                 ,iimb.ship_class
                 ,iimb.frt_class
                 ,iimb.price_class
                 ,iimb.storage_class
                 ,iimb.purch_class
                 ,iimb.tax_class
                 ,iimb.customs_class
                 ,iimb.alloc_class
                 ,iimb.planning_class
                 ,iimb.itemcost_class
                 ,iimb.cost_mthd_code
                 ,iimb.upc_code
                 ,iimb.grade_ctl
                 ,iimb.status_ctl
                 ,iimb.qc_grade
                 ,iimb.lot_status
                 ,iimb.bulk_id
                 ,iimb.pkg_id
                 ,iimb.qcitem_id
                 ,iimb.qchold_res_code
                 ,iimb.expaction_code
                 ,iimb.fill_qty
                 ,iimb.fill_um
                 ,iimb.expaction_interval
                 ,iimb.phantom_type
                 ,iimb.whse_item_id
                 ,iimb.experimental_ind
                 ,iimb.exported_date
                 ,iimb.trans_cnt
                 ,iimb.delete_mark
                 ,iimb.text_code
                 ,iimb.seq_dpnd_class
                 ,iimb.commodity_code
                 ,iimb.creation_date
                 ,iimb.created_by
                 ,cd_last_update_date               -- WHO�J�����i�X�V�����j
                 ,cn_last_updated_by                -- WHO�J�����i�X�V�ҁj
                 ,cn_last_update_login              -- WHO�J�����i�ŏI�X�V���O�C���j
                 ,cn_program_application_id         -- WHO�J�����i�A�v���P�[�V����ID�j
                 ,cn_program_id                     -- WHO�J�����i�v���O����ID�j
                 ,cd_program_update_date            -- WHO�J�����i�v���O�����ŏI�X�V�����j
                 ,cn_request_id                     -- WHO�J�����i�v��ID�j
                 ,iimb.attribute1
                 ,iimb.attribute2
                 ,iimb.attribute3
                 ,iimb.attribute4
                 ,iimb.attribute5
                 ,iimb.attribute6
                 ,iimb.attribute7
                 ,iimb.attribute8
                 ,iimb.attribute9
-- Ver1.6 2009/03/23 MOD  ��QNo37�Ή� �d��/�e�ρE�d�ʗe�ϋ敪�̐ݒ��ǉ�
--                 ,iimb.attribute10
                 ,parent_iimb.attribute10           -- �d�ʗe�ϋ敪(�e�i�ڂ���擾)
-- Ver1.6 MOD END
                 ,parent_iimb.attribute11           -- �P�[�X����(�e�i�ڂ���擾)
                 ,parent_iimb.attribute12           -- NET(�e�i�ڂ���擾)
                 ,iimb.attribute13
                 ,iimb.attribute14
                 ,iimb.attribute15
-- Ver1.6 2009/03/23 MOD  ��QNo37�Ή� �d��/�e�ρE�d�ʗe�ϋ敪�̐ݒ��ǉ�
--                 ,iimb.attribute16
                 ,parent_iimb.attribute16           -- �e��(�e�i�ڂ���擾)
-- Ver1.6 MOD END
                 ,iimb.attribute17
                 ,iimb.attribute18
                 ,iimb.attribute19
                 ,iimb.attribute20
                 ,parent_iimb.attribute21           -- JAN(�e�i�ڂ���擾)
                 ,parent_iimb.attribute22           -- ITF
                 ,iimb.attribute23
                 ,iimb.attribute24
                 ,parent_iimb.attribute25           -- �d��/�̐�(�e�i�ڂ���擾)
                 ,iimb.attribute26
                 ,iimb.attribute27
                 ,iimb.attribute28
                 ,iimb.attribute29
-- Ver1.6 2009/03/23 MOD  ��QNo39�Ή� �}�X�^��M����(OPM�i��.ATTRIBUTE30)�̐ݒ��ǉ�
--                 ,iimb.attribute30
                 ,TO_CHAR( SYSDATE, cv_date_format_rmd )
                                                    -- �}�X�^��M����
-- Ver1.6 MOD END
                 ,iimb.attribute_category
                 ,iimb.item_abccode
                 ,iimb.ont_pricing_qty_source
                 ,iimb.alloc_category_id
                 ,iimb.customs_category_id
                 ,iimb.frt_category_id
                 ,iimb.gl_category_id
                 ,iimb.inv_category_id
                 ,iimb.cost_category_id
                 ,iimb.planning_category_id
                 ,iimb.price_category_id
                 ,iimb.purch_category_id
                 ,iimb.sales_category_id
                 ,iimb.seq_category_id
                 ,iimb.ship_category_id
                 ,iimb.storage_category_id
                 ,iimb.tax_category_id
                 ,iimb.autolot_active_indicator
                 ,iimb.lot_prefix
                 ,iimb.lot_suffix
                 ,iimb.sublot_prefix
                 ,iimb.sublot_suffix
      INTO        l_opm_item_rec
      FROM        ic_item_mst_b       iimb
                 ,ic_item_mst_b       parent_iimb
                 ,xxcmn_item_mst_b    ximb
      WHERE       iimb.item_id            = in_item_id
      AND         ximb.item_id            = iimb.item_id
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--      AND         ximb.start_date_active <= TRUNC( SYSDATE )
--      AND         ximb.end_date_active   >= TRUNC( SYSDATE )
      AND         ximb.start_date_active <= gd_process_date
      AND         ximb.end_date_active   >= gd_process_date
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
      AND         parent_iimb.item_id     = ximb.parent_item_id
      FOR UPDATE OF iimb.item_id NOWAIT;
      --
    EXCEPTION
      -- *** ���b�N�G���[��O�n���h�� ***
      WHEN global_check_lock_expt THEN
        RAISE data_rock_err_expt;    -- ���b�N�G���[
        --
      WHEN OTHERS THEN
        lv_msg_errm  := SQLERRM;
        lv_msg_token := cv_tkn_val_opmitem;
        RAISE data_select_err_expt;  -- ���o�G���[
    END;
    --
    --==============================================================
    --A-7.2 �J�e�S���Z�b�gID�̎擾�i����Q�R�[�h�j
    --A-7.3 �J�e�S��ID�̎擾�i����Q�R�[�h�j
    --==============================================================
    IF ( iv_policy_group IS NOT NULL ) THEN
      --
      lv_step := 'STEP-10020';
      BEGIN
        -- ����Q�R�[�h �J�e�S���Z�b�gID,�J�e�S��ID�擾
        SELECT      mcs.category_set_id    -- �J�e�S���Z�b�gID
                   ,mc.category_id         -- �J�e�S��ID
        INTO        ln_category_set_id
                   ,ln_category_id
        FROM        mtl_categories       mc
                   ,mtl_category_sets    mcs
        WHERE       mcs.description = cv_categ_set_seisakugun
        AND         mc.structure_id = mcs.structure_id
        AND         mc.segment1     = iv_policy_group;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg_errm  := SQLERRM;
          lv_msg_token := cv_tkn_val_categ_policy_cd;
          RAISE data_select_err_expt;  -- ���o�G���[
      END;
      --
      -- OPM�i�ڃJ�e�S���X�V�p�p�����[�^�ݒ�
      l_opmitem_category_rec.item_id            := in_item_id;
      l_opmitem_category_rec.category_set_id    := ln_category_set_id;
      l_opmitem_category_rec.category_id        := ln_category_id;
      -- Disc�i�ڃJ�e�S���X�V�p�p�����[�^�ݒ�
      l_discitem_category_rec.inventory_item_id := in_inventory_item_id;
      l_discitem_category_rec.category_set_id   := ln_category_set_id;
      l_discitem_category_rec.category_id       := ln_category_id;
      --
      --==============================================================
      --A-7.4 �i�ڃJ�e�S�������̍X�V�i����Q�R�[�h�j
      --==============================================================
      -- OPM�i�ڃJ�e�S�����f
      lv_step := 'STEP-10030';
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec  =>  l_opmitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
       ,ov_errbuf            =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            =>  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_opm_item_categ;
        RAISE data_update_err_expt;
      END IF;
      --
      -- Disc�i�ڃJ�e�S�����f
      lv_step := 'STEP-10040';
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec  =>  l_discitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
       ,ov_errbuf            =>  lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           =>  lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            =>  lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_mtl_item_categ;
        RAISE data_update_err_expt;
      END IF;
      --
-- Ver1.8  2009/06/11  Add  ����Q�R�[�h���ύX���ꂽ�ꍇ�A�Q�R�[�h�ɂ����f
      --==============================================================
      --A-7.2 �J�e�S���Z�b�gID�̎擾�i�Q�R�[�h�j
      --A-7.3 �J�e�S��ID�̎擾�i�Q�R�[�h�j
      --==============================================================
      lv_step := 'STEP-10050';
      BEGIN
        -- �Q�R�[�h �J�e�S���Z�b�gID,�J�e�S��ID�擾
        SELECT      mcs.category_set_id    -- �J�e�S���Z�b�gID
                   ,mc.category_id         -- �J�e�S��ID
        INTO        ln_category_set_id
                   ,ln_category_id
        FROM        mtl_categories       mc
                   ,mtl_category_sets    mcs
        WHERE       mcs.description = cv_categ_set_gun_code
        AND         mc.structure_id = mcs.structure_id
        AND         mc.segment1     = iv_policy_group;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg_errm  := SQLERRM;
          lv_msg_token := cv_tkn_val_categ_gun_cd;
          RAISE data_select_err_expt;  -- ���o�G���[
      END;
      --
      -- OPM�i�ڃJ�e�S���X�V�p�p�����[�^�ݒ�
      l_opmitem_category_rec.item_id            := in_item_id;
      l_opmitem_category_rec.category_set_id    := ln_category_set_id;
      l_opmitem_category_rec.category_id        := ln_category_id;
      -- Disc�i�ڃJ�e�S���X�V�p�p�����[�^�ݒ�
      l_discitem_category_rec.inventory_item_id := in_inventory_item_id;
      l_discitem_category_rec.category_set_id   := ln_category_set_id;
      l_discitem_category_rec.category_id       := ln_category_id;
      --
      --==============================================================
      --A-7.4 �i�ڃJ�e�S�������̍X�V�i�Q�R�[�h�j
      --==============================================================
      -- OPM�i�ڃJ�e�S�����f
      lv_step := 'STEP-10060';
      xxcmm_004common_pkg.proc_opmitem_categ_ref(
        i_item_category_rec  =>  l_opmitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
       ,ov_errbuf            =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            =>  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_opm_item_categ;
        RAISE data_update_err_expt;
      END IF;
      --
      -- Disc�i�ڃJ�e�S�����f
      lv_step := 'STEP-10070';
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec  =>  l_discitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
       ,ov_errbuf            =>  lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           =>  lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            =>  lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        lv_msg_errm  := lv_errmsg;
        lv_msg_token := cv_tkn_val_categ_gun_cd;
        RAISE data_update_err_expt;
      END IF;
      --
-- End1.8
      --
      --==============================================================
      --A-7.6-0 OPM�i�ڍX�V�p����Q�̐ݒ�
      --==============================================================
      lv_step := 'STEP-10080';
      -- ���E�Q�R�[�h �� �V�E�Q�R�[�h
-- Ver1.9  2009/07/06  Mod  ��Q�Ή�(0000365)
--      l_opm_item_rec.attribute1 := l_opm_item_rec.attribute2;
      l_opm_item_rec.attribute1 := NVL( l_opm_item_rec.attribute2, iv_policy_group );
-- End1.9
      -- �V�E�Q�R�[�h
      l_opm_item_rec.attribute2 := iv_policy_group;
      -- �Q���ޓK�p�J�n��
      l_opm_item_rec.attribute3 := iv_apply_date;
    END IF;
    --
    -- �艿
    IF ( in_fixed_price IS NOT NULL ) THEN
      --==============================================================
      --A-7.6-0 OPM�i�ڍX�V�p�艿�̐ݒ�
      --==============================================================
      lv_step := 'STEP-10110';
      -- ���E�艿 �� �V�E�艿
-- Ver1.9  2009/07/06  Mod  ��Q�Ή�(0000365)
--      l_opm_item_rec.attribute4 := l_opm_item_rec.attribute5;
      l_opm_item_rec.attribute4 := NVL( l_opm_item_rec.attribute5, in_fixed_price );
-- End1.9
      -- �V�E�艿
      l_opm_item_rec.attribute5 := in_fixed_price;
      -- �艿�K�p�J�n��
      l_opm_item_rec.attribute6 := iv_apply_date;
    END IF;
    --
    --==============================================================
    --A-7.5 �c�ƌ����i�ۗ������j�̓o�^
    --  ����OIF�̓C���|�[�g���Ƀp�[�W���\
    --  �����́w�������̃p�[�W�x�R���J�����g�̎��s���K�v���ۂ��B
    --==============================================================
    IF ( in_discrete_cost IS NOT NULL ) THEN
      --
      lv_step := 'STEP-10210';
      SELECT      COUNT( cif.ROWID )
      INTO        ln_exsits_count
      FROM        cst_item_cst_dtls_interface    cif
      WHERE       cif.inventory_item_id = in_inventory_item_id
      AND         cif.organization_id   = in_organization_id
-- Ver1.4 2009/01/30 Add �����g�D�ύX�ɂ��C��
      AND         cif.process_flag      = cn_process_flag
      AND         cif.group_id          = cn_group_id
-- End
      AND         ROWNUM                = 1;
      --
      IF ( ln_exsits_count = 0 ) THEN
        -- �f�[�^���o�^�̏ꍇ�͐V�K�o�^
        lv_step := 'STEP-10220';
        BEGIN
          -- ����OIF�֓o�^
          INSERT INTO cst_item_cst_dtls_interface(
            inventory_item_id         -- �i��ID
           ,organization_id           -- �g�DID
           ,group_id                  -- �O���[�vID
           ,usage_rate_or_amount      -- �������z
           ,resource_code             -- �������v�f
           ,cost_element              -- �����v�f
           ,process_flag )            -- �v���Z�X�t���O
          VALUES(
            in_inventory_item_id
           ,in_organization_id
           ,cn_group_id
           ,in_discrete_cost
           ,cv_resource_code
           ,cv_cost_element
           ,cn_process_flag );
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_msg_errm  := SQLERRM;
            lv_msg_token := cv_tkn_val_disccost_if;
            RAISE data_insert_err_expt;  -- �o�^�G���[
        END;
      ELSE
        -- �f�[�^�o�^�ς݂̏ꍇ�͍X�V
        lv_step := 'STEP-10230';
        BEGIN
          UPDATE      cst_item_cst_dtls_interface                     -- ����OIF
          SET         usage_rate_or_amount = in_discrete_cost         -- �������z
          WHERE       inventory_item_id    = in_inventory_item_id     -- �i��ID
          AND         organization_id      = in_organization_id       -- �g�DID
-- Ver1.4 2009/01/30 Add �����g�D�ύX�ɂ��C��
          AND         process_flag         = cn_process_flag          -- �v���Z�X�t���O
          AND         group_id             = cn_group_id;             -- �O���[�vID
-- End
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_msg_errm  := SQLERRM;
            lv_msg_token := cv_tkn_val_disccost_if;
            RAISE data_update_err_expt;  -- �X�V�G���[
        END;
      END IF;
      --
      --==============================================================
      --A-7.6-0 OPM�i�ڍX�V�p�c�ƌ����̐ݒ�
      --==============================================================
      lv_step := 'STEP-10240';
      -- ���E�c�ƌ��� �� �V�E�c�ƌ���
-- Ver1.9  2009/07/06  Mod  ��Q�Ή�(0000365)
--      l_opm_item_rec.attribute7 := l_opm_item_rec.attribute8;
      l_opm_item_rec.attribute7 := NVL( l_opm_item_rec.attribute8, in_discrete_cost );
-- End1.9
      -- �V�E�c�ƌ���
      l_opm_item_rec.attribute8 := in_discrete_cost;
      -- �c�ƌ����K�p�J�n��
      l_opm_item_rec.attribute9 := iv_apply_date;
    END IF;
    --
    lv_step := 'STEP-10310';
    xxcmm_004common_pkg.upd_opm_item(
      i_opm_item_rec  =>  l_opm_item_rec         -- OPM�i�ڃ��R�[�h�^�C�v
     ,ov_errbuf       =>  lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      =>  lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      lv_msg_errm  := lv_errmsg;
      lv_msg_token := cv_tkn_val_opmitem;
      RAISE data_update_err_expt;
    END IF;
    --
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN data_rock_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00443            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_item_no                    -- �g�[�N���l2
                      );
      ELSE
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00447            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_parent_item            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_parent_item                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_item_code              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_item_no                    -- �g�[�N���l3
                      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^���o��O�n���h�� ***
    WHEN data_select_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        -- �i�ڕύX�K�p�ɂ��X�V
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00442            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_data_info              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_item_no                    -- �g�[�N���l2
                      );
      ELSE
        -- �e�i�ڕύX�ɂ��q�i�ڂւ̌p����
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00446            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_data_info              -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_parent_item            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_parent_item                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_item_code              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_item_no                    -- �g�[�N���l3
                      );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg || cv_msg_space|| lv_msg_errm;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�o�^��O�n���h�� ***
    WHEN data_insert_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        -- �i�ڕύX�K�p�ɂ��X�V
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00444            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_item_no                    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_msg_errm                   -- �g�[�N���l3
                      );
      ELSE
        -- �e�i�ڕύX�ɂ��q�i�ڂւ̌p����
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00448            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_parent_item            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_parent_item                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_item_code              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_item_no                    -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => lv_msg_errm                   -- �g�[�N���l4
                      );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN data_update_err_expt THEN
      --
      IF ( gv_inherit_kbn = cv_inherit_kbn_hst ) THEN
        -- �i�ڕύX�K�p�ɂ��X�V
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00445            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_item_no                    -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_msg_errm                   -- �g�[�N���l3
                      );
      ELSE
        -- �e�i�ڕύX�ɂ��q�i�ڂւ̌p����
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00449            -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_parent_item            -- �g�[�N���R�[�h2
                       ,iv_token_value2 => iv_parent_item                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_item_code              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => iv_item_no                    -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => lv_msg_errm                   -- �g�[�N���l4
                      );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END proc_item_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_parent_item_update
   * Description      : �e�i�ڕύX���̍X�V�A�e�i�ڕύX���̌p��(A-7)
   **********************************************************************************/
  PROCEDURE proc_parent_item_update(
    i_update_item_rec   IN     update_item_cur%ROWTYPE
   ,ov_errbuf           OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_PARENT_ITEM_UPDATE'; -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_step                    VARCHAR2(10);
    --
    -- *** ���[�J���ϐ� ***
    lv_msg_token               VARCHAR2(100);
    lv_msg_errm                VARCHAR2(4000);
    --
    lv_item_no                 ic_item_mst_b.item_no%TYPE;     -- �i�ڃR�[�h
    lv_policy_group            VARCHAR2(4);                    -- ����Q�R�[�h
    ln_fixed_price             NUMBER;                         -- �艿
    ln_discrete_cost           NUMBER;                         -- �c�ƌ���
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �q���i���o�J�[�\��
    CURSOR parent_item_cur(
      pn_item_id    NUMBER )
    IS
      SELECT      xoiv.item_id                                    -- OPM�i��ID
                 ,xoiv.item_no                                    -- �i�ڃR�[�h
                 ,xoiv.item_status                                -- �i�ڃX�e�[�^�X
                 ,xoiv.inventory_item_id                          -- Disc�i��ID
      FROM        xxcmm_opmmtl_items_v      xoiv                  -- �i�ڃr���[
      WHERE       xoiv.parent_item_id     = pn_item_id            -- �e���iID
      AND         xoiv.item_id           != xoiv.parent_item_id   -- �e�i�ڈȊO
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )      -- �K�p�J�n��
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE );     -- �K�p�I����
      AND         xoiv.start_date_active <= gd_process_date       -- �K�p�J�n��
      AND         xoiv.end_date_active   >= gd_process_date;      -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
    --
    -- Disc�i�ڃA�h�I�����b�N�J�[�\��
    CURSOR xxcmm_item_lock_cur(
      pv_item_code    VARCHAR2 )
    IS
      SELECT    'x'
      FROM      xxcmm_system_items_b
      WHERE     item_code = pv_item_code
      FOR UPDATE NOWAIT;
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    sub_proc_expt              EXCEPTION;
    data_update_err_expt       EXCEPTION;    -- �f�[�^�X�V�G���[
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
    --==============================================================
    --�e�i�ڂ̕ύX
    --  A-7 �e�i�ڕύX���̌p��
    --==============================================================
    -- �i�ڔ���
    -- �e�i�ځA���A����Q�R�[�h�A�艿�A�c�ƌ����̂����ꂩ�̕ύX
    -- �i�ڃX�e�[�^�X���c�̏ꍇ�͑ΏۊO�i�f�[�^�o�^����Ȃ��͂��j
    IF   ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id )
    AND  ( i_update_item_rec.policy_group  IS NOT NULL
        OR i_update_item_rec.fixed_price   IS NOT NULL
        OR i_update_item_rec.discrete_cost IS NOT NULL )
-- Ver1.7 2009/05/27 Mod  ���݂̃X�e�[�^�X���c���ɁA�ύX�\��̃X�e�[�^�X���u�����N�̑z��͂��Ă��Ȃ�������
--                        �c���A�܂��́A�c�ɕύX����ꍇ�A�o�^���̕ύX�������Ȃ��悤�C��
--    AND  ( NVL( i_update_item_rec.item_status, cn_itm_status_num_tmp )  -- �ύX�\��̃X�e�[�^�X
--                                           != cn_itm_status_no_use )    -- ���݂̃X�e�[�^�X���Q�Ƃ���K�v����
    -- �ύX�\��̃X�e�[�^�X���c�̏ꍇ
    -- �܂��́A�ύX�\��̃X�e�[�^�X�����ݒ�Ō��X�e�[�^�X���c�̏ꍇ�A�������Ȃ�
    AND  ( NVL( i_update_item_rec.item_status, i_update_item_rec.b_item_status )
                                             != cn_itm_status_no_use )
-- End
    THEN
      --
      -------------------
      -- �e�i�ڂւ̔��f
      -------------------
      lv_step := 'STEP-09010';
      proc_item_update(
        in_item_id            =>  i_update_item_rec.item_id              -- OPM�i��ID
       ,in_inventory_item_id  =>  i_update_item_rec.inventory_item_id    -- Disc�i��ID
       ,iv_item_no            =>  i_update_item_rec.item_no              -- �i�ڃR�[�h
       ,iv_policy_group       =>  i_update_item_rec.policy_group         -- ����Q�R�[�h
       ,in_fixed_price        =>  i_update_item_rec.fixed_price          -- �艿
       ,in_discrete_cost      =>  i_update_item_rec.discrete_cost        -- �c�ƌ���
       ,in_organization_id    =>  gn_cost_org_id                         -- Disc�i�ڌ����g�DID
       ,iv_apply_date         =>  TO_CHAR( i_update_item_rec.apply_date, cv_date_fmt_std ) 
                                                                         -- �K�p��
       ,ov_errbuf             =>  lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            =>  lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             =>  lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        RAISE sub_proc_expt;
      END IF;
      --
      --==============================================================
      --A-7 �e�i�ڕύX���̌p��
      --==============================================================
      gv_inherit_kbn := cv_inherit_kbn_inh;    -- �e�l�p�����敪�y'1'�F�e�i�ڕύX�ɂ��X�V�z
      --
      --==============================================================
      --A-7.1 �i�ڏ��̒��o
      --==============================================================
      lv_step := 'STEP-09020';
      <<child_item_loop>>
      FOR l_parent_item_rec IN parent_item_cur( i_update_item_rec.item_id ) LOOP
        -- ���b�Z�[�W�o�͗p�ɑޔ�
        lv_item_no := l_parent_item_rec.item_no;
        --
        IF ( l_parent_item_rec.item_status = cn_itm_status_num_tmp
          OR l_parent_item_rec.item_status IS NULL ) THEN
          -- ���̔Ԏ��ANULL��
          lv_step := 'STEP-09030';
          -- ����Q�R�[�h�F�q�i�ڂ̕i�ڃX�e�[�^�X���c�ȊO�̏ꍇ���f����
          lv_policy_group    := i_update_item_rec.policy_group;
          ln_fixed_price     := NULL;         -- �艿
          ln_discrete_cost   := NULL;         -- �c�ƌ���
          --
        ELSIF ( l_parent_item_rec.item_status = cn_itm_status_pre_reg ) THEN
          -- ���o�^��
          lv_step := 'STEP-09040';
          -- ����Q�R�[�h�F�q�i�ڂ̕i�ڃX�e�[�^�X���c�ȊO�̏ꍇ���f����
          lv_policy_group    := i_update_item_rec.policy_group;
          -- �艿        �F�q�i�ڂ̕i�ڃX�e�[�^�X�����o�^�ȍ~�c�ȑO�̏ꍇ���f����
          ln_fixed_price     := i_update_item_rec.fixed_price;
          ln_discrete_cost   := NULL;         -- �c�ƌ���
          --
        ELSIF ( l_parent_item_rec.item_status IN ( cn_itm_status_regist
                                                 , cn_itm_status_no_sch
                                                 , cn_itm_status_trn_only ) ) THEN
          -- �{�o�^�A�p�A�c�f��
          lv_step := 'STEP-09050';
          -- ����Q�R�[�h�F�q�i�ڂ̕i�ڃX�e�[�^�X���c�ȊO�̏ꍇ���f����
          lv_policy_group    := i_update_item_rec.policy_group;
          -- �艿        �F�q�i�ڂ̕i�ڃX�e�[�^�X�����o�^�ȍ~�c�ȑO�̏ꍇ���f����
          ln_fixed_price     := i_update_item_rec.fixed_price;
          -- �c�ƌ���    �F�q�i�ڂ̕i�ڃX�e�[�^�X���{�o�^�ȍ~�c�ȑO�̏ꍇ���f����
          ln_discrete_cost   := i_update_item_rec.discrete_cost;
          --
        ELSE
          -- �c��
          lv_step := 'STEP-09060';
          -- �Ȃɂ����Ȃ�
          lv_policy_group    := NULL;         -- ����Q�R�[�h
          ln_fixed_price     := NULL;         -- �艿
          ln_discrete_cost   := NULL;         -- �c�ƌ���
        END IF;
        --
        -- �ύX�K�p�����{���鍀�ڂ����݂��邩
        IF ( lv_policy_group  IS NOT NULL
          OR ln_fixed_price   IS NOT NULL
          OR ln_discrete_cost IS NOT NULL ) THEN
          -- 
          -------------------
          -- �q�i�ڂւ̓W�J
          -------------------
          lv_step := 'STEP-09070';
          proc_item_update(
            in_item_id            =>  l_parent_item_rec.item_id              -- OPM�i��ID
           ,in_inventory_item_id  =>  l_parent_item_rec.inventory_item_id    -- Disc�i��ID
           ,iv_item_no            =>  l_parent_item_rec.item_no              -- �i�ڃR�[�h
           ,iv_policy_group       =>  lv_policy_group                        -- ����Q�R�[�h
           ,in_fixed_price        =>  ln_fixed_price                         -- �艿
           ,in_discrete_cost      =>  ln_discrete_cost                       -- �c�ƌ���
           ,in_organization_id    =>  gn_cost_org_id                         -- Disc�i�ڌ����g�DID
           ,iv_apply_date         =>  TO_CHAR( i_update_item_rec.apply_date, cv_date_fmt_std ) 
                                                                             -- �K�p��
           ,iv_parent_item        =>  i_update_item_rec.item_no              -- �e�i�ڃR�[�h
           ,ov_errbuf             =>  lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode            =>  lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg             =>  lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            --
            RAISE sub_proc_expt;
          END IF;
          --
          --==============================================================
          --A-7.7 �q�i�ڎ���Disc�i�ڃA�h�I���̍X�V
          --==============================================================
          lv_step := 'STEP-09080';
          -- Disc�i�ڃA�h�I�����b�N
          lv_msg_token := cv_tkn_val_xxcmm_discitem;
          --
          OPEN   xxcmm_item_lock_cur( l_parent_item_rec.item_no );
          CLOSE  xxcmm_item_lock_cur;
          --
          lv_step := 'STEP-09090';
          BEGIN
            UPDATE      xxcmm_system_items_b    -- Disc�i�ڃA�h�I��
-- Ver1.5 2009/02/20 Mod �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--            SET         search_update_date     = i_update_item_rec.apply_date
                        -- �����ΏۍX�V��
            SET         search_update_date     = gd_process_date
-- End
                       ,last_updated_by        = cn_last_updated_by
                       ,last_update_date       = cd_last_update_date
                       ,last_update_login      = cn_last_update_login
                       ,request_id             = cn_request_id
                       ,program_application_id = cn_program_application_id
                       ,program_id             = cn_program_id
                       ,program_update_date    = cd_program_update_date
                        --
            WHERE       item_code              = l_parent_item_rec.item_no;
            --
          EXCEPTION
            WHEN OTHERS THEN
              lv_msg_errm  := SQLERRM;
              lv_msg_token := cv_tkn_val_xxcmm_discitem;
              RAISE data_update_err_expt;  -- �X�V�G���[
          END;
          --
        END IF;
      END LOOP child_item_loop;
      --
      gv_inherit_kbn := cv_inherit_kbn_hst;    -- �e�l�p�����敪�y'0'�F�������ɂ��X�V�z
    END IF;
    --
  EXCEPTION
--
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( xxcmm_item_lock_cur%ISOPEN ) THEN
        CLOSE  xxcmm_item_lock_cur;
      END IF;
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00447            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_parent_item            -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item_code              -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_item_no                    -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN data_update_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00449            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_parent_item            -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item_code              -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_item_no                    -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_err_msg                -- �g�[�N���R�[�h4
                     ,iv_token_value4 => lv_msg_errm                   -- �g�[�N���l4
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END proc_parent_item_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_inherit_parent
   * Description      : �e�i�ڏ��̌p��(A-6)
   **********************************************************************************/
  PROCEDURE proc_inherit_parent(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_INHERIT_PARENT';  -- �v���O������
    --
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
-- Ver1.6 2009/03/23 ADD  ��QNo37  �c����̃X�e�[�^�X�ύX��
    lv_msg_errm                  VARCHAR2(4000);
-- Ver1.6 ADD END
    --
    ln_exsits_count              NUMBER;
    ln_cmp_cost_index            NUMBER;
    --
    -- �o�^�l�m�F�p
    ln_fixed_price               NUMBER;          -- �艿
    ln_discrete_cost             NUMBER;          -- �c�ƌ���
    lv_policy_group              VARCHAR2(4);     -- ����Q�R�[�h
    -- �ύX�p(�e�l)
    ln_fixed_price_parent        NUMBER;          -- �艿
    ln_discrete_cost_parent      NUMBER;          -- �c�ƌ���
    lv_policy_group_parent       VARCHAR2(4);     -- ����Q�R�[�h
    --
-- Ver1.6 2009/03/23 ADD  ��QNo37  �c����̃X�e�[�^�X�ύX��
    ln_category_set_id           mtl_category_sets.category_set_id%TYPE;     -- �J�e�S���Z�b�gID
    ln_category_id               mtl_categories.category_id%TYPE;            -- �J�e�S��ID
-- Ver1.6 ADD END
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
-- Ver1.2 2009/01/27 MOD �W�������o�^���W�b�N�̏C��
--    -- �e�i�ڕW���������o�J�[�\��
--    CURSOR cnp_cost_cur(
--      pn_parent_item_id  NUMBER
--     ,pn_item_id         NUMBER
--     ,pd_apply_date      DATE )
--    IS
--      SELECT    ccmd2.cmpntcost_id
--               ,ccmd.item_id                  -- �i��ID
--               ,ccmd.calendar_code            -- �J�����_�R�[�h
--               ,ccmd.period_code              -- ���ԃR�[�h
--               ,ccmd.cost_cmpntcls_id         -- �����R���|�[�l���gID
--               ,ccmv.cost_cmpntcls_code       -- �����R���|�[�l���g�R�[�h
--               ,ccmd.cmpnt_cost               -- ����
--      FROM      cm_cmpt_dtl          ccmd     -- OPM�W������(�e-�����擾)
--               ,cm_cmpt_dtl          ccmd2    -- OPM�W������(�q-�����h�c�擾)
--               ,cm_cldr_dtl          cclr     -- OPM�����J�����_
--               ,cm_cmpt_mst_vl       ccmv     -- �����R���|�[�l���g
--               ,fnd_lookup_values_vl flv      -- �Q�ƃR�[�h�l
--      WHERE     ccmd.item_id             = pn_parent_item_id            -- �i�ځi�e�j
--      AND       ccmd2.item_id(+)         = pn_item_id                   -- �i�ځi�q�j
--      AND       cclr.start_date         <= pd_apply_date                -- �J�n��
--      AND       cclr.end_date           >= pd_apply_date                -- �I����
--      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- �Q�ƃ^�C�v
--      AND       flv.enabled_flag         = cv_yes                       -- �g�p�\
--      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- �����R���|�[�l���g�R�[�h
--      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id        -- �����R���|�[�l���gID
--      AND       ccmd.calendar_code       = cclr.calendar_code           -- �J�����_�R�[�h
--      AND       ccmd.period_code         = cclr.period_code             -- ���ԃR�[�h
--      AND       ccmd.whse_code           = cv_whse_code                 -- �q��
--      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code            -- �������@
--      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code        -- ���̓R�[�h
--      AND       ccmd.cost_cmpntcls_id    = ccmd2.cost_cmpntcls_id(+)    -- �����R���|�[�l���gID
--      AND       ccmd.calendar_code       = ccmd2.calendar_code(+)       -- �J�����_�R�[�h
--      AND       ccmd.period_code         = ccmd2.period_code(+)         -- ���ԃR�[�h
--      AND       ccmd.whse_code           = ccmd2.whse_code(+)           -- �q��
--      AND       ccmd.cost_mthd_code      = ccmd2.cost_mthd_code(+)      -- �������@
--      AND       ccmd.cost_analysis_code  = ccmd2.cost_analysis_code(+)  -- ���̓R�[�h
--      ORDER BY  ccmv.cost_cmpntcls_code;
    --
    -- �W�������w�b�_���o�J�[�\��
    CURSOR cnp_cost_hd_cur(
      pn_parent_item_id  NUMBER
     ,pd_apply_date      DATE )
    IS
      SELECT    DISTINCT
                ccmd.calendar_code            -- �J�����_�R�[�h
               ,ccmd.period_code              -- ���ԃR�[�h
      FROM      cm_cmpt_dtl          ccmd     -- OPM�W������(�e-�����擾)
               ,cm_cldr_dtl          cclr     -- OPM�����J�����_
               ,cm_cmpt_mst_vl       ccmv     -- �����R���|�[�l���g
               ,fnd_lookup_values_vl flv      -- �Q�ƃR�[�h�l
      WHERE     ccmd.item_id             = pn_parent_item_id            -- �i�ځi�e�j
      AND       cclr.end_date           >= pd_apply_date                -- �I����
      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- �Q�ƃ^�C�v
      AND       flv.enabled_flag         = cv_yes                       -- �g�p�\
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- �����R���|�[�l���g�R�[�h
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id        -- �����R���|�[�l���gID
      AND       ccmd.calendar_code       = cclr.calendar_code           -- �J�����_�R�[�h
      AND       ccmd.period_code         = cclr.period_code             -- ���ԃR�[�h
      AND       ccmd.whse_code           = cv_whse_code                 -- �q��
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code            -- �������@
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code        -- ���̓R�[�h
      ORDER BY  ccmd.calendar_code
               ,ccmd.period_code;
    --
    -- �W���������ג��o�J�[�\��
    CURSOR cnp_cost_dt_cur(
      pn_parent_item_id  NUMBER
     ,pn_item_id         NUMBER
     ,pv_calendar_code   VARCHAR2
     ,pv_period_code     VARCHAR2 )
-- Ver1.9  2009/07/06  Del  �g�p���Ă��Ȃ����ߍ폜
--     ,pd_apply_date      DATE )
-- End1.9
    IS
      SELECT    ccmd2.cmpntcost_id            -- �W������ID
               ,ccmd.item_id                  -- �i��ID
               ,ccmd.calendar_code            -- �J�����_�R�[�h
               ,ccmd.period_code              -- ���ԃR�[�h
               ,ccmd.cost_cmpntcls_id         -- �����R���|�[�l���gID
               ,ccmv.cost_cmpntcls_code       -- �����R���|�[�l���g�R�[�h
               ,ccmd.cmpnt_cost               -- ����
      FROM      cm_cmpt_dtl          ccmd     -- OPM�W������(�e-�����擾)
               ,cm_cmpt_dtl          ccmd2    -- OPM�W������(�q-�����h�c�擾)
               ,cm_cldr_dtl          cclr     -- OPM�����J�����_
               ,cm_cmpt_mst_vl       ccmv     -- �����R���|�[�l���g
               ,fnd_lookup_values_vl flv      -- �Q�ƃR�[�h�l
      WHERE     ccmd.item_id             = pn_parent_item_id            -- �i�ځi�e�j
      AND       ccmd2.item_id(+)         = pn_item_id                   -- �i�ځi�q�j
      AND       cclr.calendar_code       = pv_calendar_code             -- �J�����_�R�[�h
      AND       cclr.period_code         = pv_period_code               -- ���ԃR�[�h
      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- �Q�ƃ^�C�v
      AND       flv.enabled_flag         = cv_yes                       -- �g�p�\
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- �����R���|�[�l���g�R�[�h
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id        -- �����R���|�[�l���gID
      AND       ccmd.calendar_code       = cclr.calendar_code           -- �J�����_�R�[�h
      AND       ccmd.period_code         = cclr.period_code             -- ���ԃR�[�h
      AND       ccmd.whse_code           = cv_whse_code                 -- �q��
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code            -- �������@
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code        -- ���̓R�[�h
      AND       ccmd.cost_cmpntcls_id    = ccmd2.cost_cmpntcls_id(+)    -- �����R���|�[�l���gID
      AND       ccmd.calendar_code       = ccmd2.calendar_code(+)       -- �J�����_�R�[�h
      AND       ccmd.period_code         = ccmd2.period_code(+)         -- ���ԃR�[�h
      AND       ccmd.whse_code           = ccmd2.whse_code(+)           -- �q��
      AND       ccmd.cost_mthd_code      = ccmd2.cost_mthd_code(+)      -- �������@
      AND       ccmd.cost_analysis_code  = ccmd2.cost_analysis_code(+)  -- ���̓R�[�h
      ORDER BY  ccmv.cost_cmpntcls_code;
-- End �iVer1.2 2009/01/27 MOD �W�������o�^���W�b�N�̏C���j
    --
    -- ���R�[�h�^
    -- OPM�W�������p
    l_opm_cost_header_rec        xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab          xxcmm_004common_pkg.opm_cost_dist_ttype;
    --
-- Ver1.6 2009/03/23 ADD  ��QNo37  �c����̃X�e�[�^�X�ύX��
    l_opmitem_category_rec       xxcmm_004common_pkg.opmitem_category_rtype;
    l_discitem_category_rec      xxcmm_004common_pkg.discitem_category_rtype;
-- Ver1.6 ADD END
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    item_common_ins_expt         EXCEPTION;    -- �f�[�^�o�^�G���[(�i�ڋ���API)
    sub_proc_expt                EXCEPTION;
    --
-- Ver1.6 2009/03/23 ADD  ��QNo37  �c����̃X�e�[�^�X�ύX��
    data_select_err_expt         EXCEPTION;    -- �f�[�^���o�G���[
    data_update_err_expt         EXCEPTION;    -- �f�[�^�X�V�G���[
-- Ver1.6 ADD END
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
    --A-6 �e�i�ڏ��̌p��
    --==============================================================
    ------------------------
    -- �q�i�ڎ��̐e�l�p��
    ------------------------
    IF ( i_update_item_rec.parent_item_id IS NULL 
      OR i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
      -- �e�i�ڂ��ݒ肳��Ă��Ȃ��i���̔ԁj�ꍇ�A�n�o�l�X�V�Ȃ�
      -- �i�ڃX�e�[�^�X���c�̏ꍇ���n�o�l�X�V�Ȃ�
      NULL;
    ELSIF ( i_update_item_rec.item_id != i_update_item_rec.parent_item_id ) THEN
      --==============================================================
      --A-6 �e�i�ڂ��ݒ肳��Ă���ꍇ�A�e�i�ڏ����p������
      --==============================================================
      lv_step := 'STEP-08010';
      -- �c�ƌ����A�艿�A����Q�̓o�^�l�m�F
      SELECT      xoiv.opt_cost_new                                     -- �c�ƌ���
                 ,xoiv.price_new                                        -- �艿
                 ,xoiv.crowd_code_new                                   -- ����Q
      INTO        ln_discrete_cost
                 ,ln_fixed_price
                 ,lv_policy_group
      FROM        xxcmm_opmmtl_items_v      xoiv                        -- �i�ڃr���[
      WHERE       xoiv.item_id            = i_update_item_rec.item_id   -- �i��ID
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )            -- �K�p�J�n��
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE );           -- �K�p�I����
      AND         xoiv.start_date_active <= gd_process_date             -- �K�p�J�n��
      AND         xoiv.end_date_active   >= gd_process_date;            -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
      --
      IF ( lv_policy_group IS NULL
        OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
        --==============================================================
        --A-6.1-2 �e�i�ڂ̐���Q�̎擾
        --==============================================================
        lv_step := 'STEP-08020';
        SELECT      xoiv.crowd_code_new                                          -- ����Q�R�[�h
        INTO        lv_policy_group_parent
        FROM        xxcmm_opmmtl_items_v      xoiv                               -- �i�ڃr���[
        WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- �e�i��ID
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--        AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- �K�p�J�n��
--        AND         xoiv.end_date_active   >= TRUNC( SYSDATE );                  -- �K�p�I����
        AND         xoiv.start_date_active <= gd_process_date                    -- �K�p�J�n��
        AND         xoiv.end_date_active   >= gd_process_date;                   -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
        --
        IF ( lv_policy_group = lv_policy_group_parent ) THEN
          -- �ύX����Ă��Ȃ��ꍇ����Q�̍X�V�����Ȃ�
          lv_policy_group_parent := NULL;
        END IF;
      END IF;
      --
      --==============================================================
      --A-6.1 �i�ڃX�e�[�^�X���f���o�^�f�ȍ~�̏ꍇ
      --==============================================================
      IF ( i_update_item_rec.item_status > cn_itm_status_num_tmp ) THEN
        --
        IF ( ln_fixed_price IS NULL
          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
          --==============================================================
          --A-6.1-2 �e�i�ڂ̒艿�̎擾
          --==============================================================
          lv_step := 'STEP-08110';
          SELECT      xoiv.price_new                                               -- �艿
          INTO        ln_fixed_price_parent
          FROM        xxcmm_opmmtl_items_v      xoiv                               -- �i�ڃr���[
          WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- �e�i��ID
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--          AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- �K�p�J�n��
--          AND         xoiv.end_date_active   >= TRUNC( SYSDATE );                  -- �K�p�I����
          AND         xoiv.start_date_active <= gd_process_date                    -- �K�p�J�n��
          AND         xoiv.end_date_active   >= gd_process_date;                   -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
          --
          IF ( ln_fixed_price = ln_fixed_price_parent ) THEN
            -- �ύX����Ă��Ȃ��ꍇ�艿�̍X�V�����Ȃ�
            ln_fixed_price_parent := NULL;
          END IF;
        END IF;
        --
-- Ver1.9  2009/07/07  Add  �W�������̌p���͉��o�^���ɕύX
-- 2009/10/16 Ver1.13 modify start by Yutaka.Kuboshima
-- ���q�i�ڂւ̌p���������폜
-- �ːe�i�ڂ̎w�肪���o�^�����\�ɂȂ������߁A�e�i�ڂ����o�^���͕W��������ێ����Ă��Ȃ��̂ŁA
--   ����̎d�l�ł͕W��������0�~�Ōp������Ă��܂��B����ɁA�p���^�C�~���O��1�x�����Ȃ����߁A
--   �q�i�ڂ̕W��������0�~�̂܂܂ɂȂ��Ă��܂����ꂪ���邽�ߌp���������폜�B
        --
        -- �W�������o�^�ς݊m�F
--        lv_step := 'STEP-08210';
--
--        SELECT      COUNT( ccmd.ROWID )
--        INTO        ln_exsits_count
--        FROM        cm_cmpt_dtl    ccmd                          -- OPM�W������
--        WHERE       ccmd.item_id = i_update_item_rec.item_id     -- �i��ID
--        AND         ROWNUM = 1;
--        --
--        -- �Y���q�i�ڂɕW���������o�^����Ă���ꍇ�A�ŐV�Ȃ̂ŏ������Ȃ��B
--        -- �������A�ύX�O�X�e�[�^�X���c�̏ꍇ�A�ŐV�̕ۏ؂��Ȃ����ߍX�V����
--        IF ( ln_exsits_count = 0
--          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
--          --
--          --==============================================================
--          --A-6.2-5 �e�i�ڂ̕W�������̎擾
--          --==============================================================
--          -- �����w�b�_(�J�����_�R�[�h�A���ԃR�[�h)�̎擾
--          lv_step := 'STEP-08220';
--          <<cnp_cost_hd_loop>>
--          FOR l_cnp_cost_hd_rec IN cnp_cost_hd_cur( i_update_item_rec.parent_item_id
--                                                   ,i_update_item_rec.apply_date ) LOOP
--            -----------------
--            -- �����w�b�_
--            -----------------
--            lv_step := 'STEP-08230';
--            -- �J�����_�R�[�h
--            l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_rec.calendar_code;
--            -- ���ԃR�[�h
--            l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_rec.period_code;
--            -- �i��ID
--            l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
--            --
--            lv_step := 'STEP-08240';
--            ln_cmp_cost_index := 0;
--            <<cnp_cost_dt_loop>>
--            FOR l_cnp_cost_dt_rec IN cnp_cost_dt_cur( i_update_item_rec.parent_item_id
--                                                     ,i_update_item_rec.item_id
--                                                     ,l_cnp_cost_hd_rec.calendar_code
--                                                     ,l_cnp_cost_hd_rec.period_code ) LOOP
--              -----------------
--              -- ��������
--              -----------------
--              lv_step := 'STEP-08250';
--              ln_cmp_cost_index := ln_cmp_cost_index + 1;
--              --
--              -- ����ID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_dt_rec.cmpntcost_id;
--              -- �����R���|�[�l���gID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_dt_rec.cost_cmpntcls_id;
--              -- ����
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_dt_rec.cmpnt_cost;
--            --
--            END LOOP cnp_cost_dt_loop;
--            --
--            --==============================================================
--            --A-6.2-6 �W�������̓o�^�E�X�V
--            --==============================================================
--            lv_step := 'STEP-08260';
--            xxcmm_004common_pkg.proc_opmcost_ref(
--              i_cost_header_rec  =>  l_opm_cost_header_rec  -- �����w�b�_���R�[�h�^�C�v
--             ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- �������׃e�[�u���^�C�v
--             ,ov_errbuf          =>  lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
--             ,ov_retcode         =>  lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
--             ,ov_errmsg          =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--            );
--            --
--            IF ( lv_retcode = cv_status_error ) THEN
--              --
--              lv_msg_token := cv_tkn_val_opmcost;
--              RAISE item_common_ins_expt;
--            END IF;
--            --
--          END LOOP cnp_cost_hd_loop;
--          --
--        END IF;
-- End1.9
        --==============================================================
        --A-6.2-5 �e�i�ڂ̕W�������̎擾
        --==============================================================
        -- �����w�b�_(�J�����_�R�[�h�A���ԃR�[�h)�̎擾
        lv_step := 'STEP-08210';
        <<cnp_cost_hd_loop>>
        FOR l_cnp_cost_hd_rec IN cnp_cost_hd_cur( i_update_item_rec.parent_item_id
                                                 ,i_update_item_rec.apply_date ) LOOP
          -----------------
          -- �����w�b�_
          -----------------
          lv_step := 'STEP-08220';
          -- �J�����_�R�[�h
          l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_rec.calendar_code;
          -- ���ԃR�[�h
          l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_rec.period_code;
          -- �i��ID
          l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
          --
          lv_step := 'STEP-08230';
          ln_cmp_cost_index := 0;
          <<cnp_cost_dt_loop>>
          FOR l_cnp_cost_dt_rec IN cnp_cost_dt_cur( i_update_item_rec.parent_item_id
                                                   ,i_update_item_rec.item_id
                                                   ,l_cnp_cost_hd_rec.calendar_code
                                                   ,l_cnp_cost_hd_rec.period_code ) LOOP
            -----------------
            -- ��������
            -----------------
            lv_step := 'STEP-08240';
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            --
            -- ����ID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_dt_rec.cmpntcost_id;
            -- �����R���|�[�l���gID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_dt_rec.cost_cmpntcls_id;
            -- ����
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_dt_rec.cmpnt_cost;
          --
          END LOOP cnp_cost_dt_loop;
          --
          --==============================================================
          --A-6.2-6 �W�������̓o�^�E�X�V
          --==============================================================
          lv_step := 'STEP-08250';
          xxcmm_004common_pkg.proc_opmcost_ref(
            i_cost_header_rec  =>  l_opm_cost_header_rec  -- �����w�b�_���R�[�h�^�C�v
           ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- �������׃e�[�u���^�C�v
           ,ov_errbuf          =>  lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode         =>  lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg          =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            --
            lv_msg_token := cv_tkn_val_opmcost;
            RAISE item_common_ins_expt;
          END IF;
          --
        END LOOP cnp_cost_hd_loop;
-- 2009/10/16 Ver1.13 modify end by Yutaka.Kuboshima
      END IF;
      --
      --==============================================================
      --A-6.2 �i�ڃX�e�[�^�X���f�{�o�^�f�ȍ~�̏ꍇ
      --==============================================================
      IF ( i_update_item_rec.item_status > cn_itm_status_pre_reg ) THEN
        --
        IF ( ln_discrete_cost IS NULL
          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
          --==============================================================
          --A-6.2-2 �e�i�ډc�ƌ����̎擾
          --==============================================================
          lv_step := 'STEP-08310';
          SELECT      xoiv.opt_cost_new                                            -- �艿
          INTO        ln_discrete_cost_parent
          FROM        xxcmm_opmmtl_items_v      xoiv                               -- �i�ڃr���[
          WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- �e�i��ID
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--          AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- �K�p�J�n��
--          AND         xoiv.end_date_active   >= TRUNC( SYSDATE );                  -- �K�p�I����
          AND         xoiv.start_date_active <= gd_process_date                    -- �K�p�J�n��
          AND         xoiv.end_date_active   >= gd_process_date;                   -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
          --
          IF ( ln_discrete_cost = ln_discrete_cost_parent ) THEN
            -- �ύX����Ă��Ȃ��ꍇ�c�ƌ����̍X�V�����Ȃ�
            ln_discrete_cost_parent := NULL;
          END IF;
        END IF;
        --
-- Ver1.9  2009/07/07  Del  �W�������̌p���͉��o�^���ɕύX
--        -- �W�������o�^�ς݊m�F
--        lv_step := 'STEP-08050';
--        SELECT      COUNT( ccmd.ROWID )
--        INTO        ln_exsits_count
--        FROM        cm_cmpt_dtl    ccmd                          -- OPM�W������
--        WHERE       ccmd.item_id = i_update_item_rec.item_id     -- �i��ID
--        AND         ROWNUM = 1;
--        --
--        -- �Y���q�i�ڂɕW���������o�^����Ă���ꍇ�A�ŐV�Ȃ̂ŏ������Ȃ��B
--        -- �������A�ύX�O�X�e�[�^�X���c�̏ꍇ�A�ŐV�̕ۏ؂��Ȃ����ߍX�V����
--        IF ( ln_exsits_count = 0
--          OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
--          --
--          --==============================================================
--          --A-6.2-5 �e�i�ڂ̕W�������̎擾
--          --==============================================================
---- Ver1.2 2009/01/27 MOD �W�������o�^���W�b�N�̏C��
----          lv_step := 'STEP-08060';
----          ln_cmp_cost_index := 0;
----          <<cnp_cost_loop>>
----          FOR l_cnp_cost_rec IN cnp_cost_cur( i_update_item_rec.parent_item_id
----                                             ,i_update_item_rec.item_id
----                                             ,gd_apply_date ) LOOP
----            --
----            ln_cmp_cost_index := ln_cmp_cost_index + 1;
----            -- �����w�b�_
----            IF ( ln_cmp_cost_index = 1 ) THEN
----              -- �J�����_�R�[�h
----              l_opm_cost_header_rec.calendar_code     := l_cnp_cost_rec.calendar_code;
----              -- ���ԃR�[�h
----              l_opm_cost_header_rec.period_code       := l_cnp_cost_rec.period_code;
----              -- �i��ID
----              l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
----            END IF;
----            --
----            -- ��������
----            -- ����ID
----            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_rec.cmpntcost_id;
----            -- �����R���|�[�l���gID
----            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_rec.cost_cmpntcls_id;
----            -- ����
----            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_rec.cmpnt_cost;
----            --
----          END LOOP cnp_cost_loop;
----          --
----          --==============================================================
----          --A-6.2-6 �W�������̓o�^�E�X�V
----          --==============================================================
----          lv_step := 'STEP-08070';
----          xxcmm_004common_pkg.proc_opmcost_ref(
----            i_cost_header_rec  =>  l_opm_cost_header_rec  -- �����w�b�_���R�[�h�^�C�v
----           ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- �������׃e�[�u���^�C�v
----           ,ov_errbuf          =>  lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
----           ,ov_retcode         =>  lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
----           ,ov_errmsg          =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----          );
----          --
----          IF ( lv_retcode = cv_status_error ) THEN
----            --
----            lv_msg_token := cv_tkn_val_opmcost;
----            RAISE item_common_ins_expt;
----          END IF;
----
--          -- �����w�b�_(�J�����_�R�[�h�A���ԃR�[�h)�̎擾
--          lv_step := 'STEP-08060';
--          <<cnp_cost_hd_loop>>
--          FOR l_cnp_cost_hd_rec IN cnp_cost_hd_cur( i_update_item_rec.parent_item_id
--                                                   ,gd_apply_date ) LOOP
--            -----------------
--            -- �����w�b�_
--            -----------------
--            lv_step := 'STEP-08070';
--            -- �J�����_�R�[�h
--            l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_rec.calendar_code;
--            -- ���ԃR�[�h
--            l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_rec.period_code;
--            -- �i��ID
--            l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
--            --
--            -- �J�����_�A���Ԗ��Ɍ��������擾
--            --   2009/07/06 �L  �������ԁi�J�����_�j�̓o�^��z�肵�Ă������A
--            --                  �J�����_���ɖ��ׂ����������Ă��炸���݉����Ă��Ȃ��o�O�������Ǝv����B
--            --                  0000364�Ή��ŃR���|�[�l���g���������ɂȂ�\�����Ȃ��Ȃ������ߑΉ��͂Ȃ��B
--            lv_step := 'STEP-08080';
--            ln_cmp_cost_index := 0;
--            <<cnp_cost_dt_loop>>
--            FOR l_cnp_cost_dt_rec IN cnp_cost_dt_cur( i_update_item_rec.parent_item_id
--                                                     ,i_update_item_rec.item_id
--                                                     ,l_cnp_cost_hd_rec.calendar_code
--                                                     ,l_cnp_cost_hd_rec.period_code
--                                                     ,gd_apply_date ) LOOP
--              -----------------
--              -- ��������
--              -----------------
--              lv_step := 'STEP-08090';
--              ln_cmp_cost_index := ln_cmp_cost_index + 1;
--              --
--              -- ����ID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_cnp_cost_dt_rec.cmpntcost_id;
--              -- �����R���|�[�l���gID
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_cost_dt_rec.cost_cmpntcls_id;
--              -- ����
--              l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := l_cnp_cost_dt_rec.cmpnt_cost;
--            --
--            END LOOP cnp_cost_dt_loop;
--            --
--            --==============================================================
--            --A-6.2-6 �W�������̓o�^�E�X�V
--            --==============================================================
--            lv_step := 'STEP-08100';
--            xxcmm_004common_pkg.proc_opmcost_ref(
--              i_cost_header_rec  =>  l_opm_cost_header_rec  -- �����w�b�_���R�[�h�^�C�v
--             ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- �������׃e�[�u���^�C�v
--             ,ov_errbuf          =>  lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
--             ,ov_retcode         =>  lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
--             ,ov_errmsg          =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--            );
--            --
--            IF ( lv_retcode = cv_status_error ) THEN
--              --
--              lv_msg_token := cv_tkn_val_opmcost;
--              RAISE item_common_ins_expt;
--            END IF;
--            --
--          END LOOP cnp_cost_hd_loop;
--          --
---- End �iVer1.2 2009/01/27 MOD �W�������o�^���W�b�N�̏C���j
--        END IF;
-- End1.9
      END IF;
      --
-- Ver1.6 2009/03/23 MOD  ��QNo37�A39�Ή�  �c����̃X�e�[�^�X�ύX��
--      IF ( ln_fixed_price_parent   IS NOT NULL
--        OR ln_discrete_cost_parent IS NOT NULL
--        OR lv_policy_group_parent  IS NOT NULL ) THEN
      IF ( ln_fixed_price_parent   IS NOT NULL
        OR ln_discrete_cost_parent IS NOT NULL
        OR lv_policy_group_parent  IS NOT NULL
        OR i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
-- Ver1.6 MOD END
--
-- Ver1.6 2009/03/23 ADD  ��QNo37  �c����̃X�e�[�^�X�ύX��
--
        -- �c����̃X�e�[�^�X�ύX���A���A�{�Џ��i�敪���ύX����Ă���ꍇ�A
        -- �e�i�ڂ̖{�Џ��i�敪�𔽉f����B
        IF ( i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
          --
          lv_step := 'STEP-08410';
          BEGIN
            -- �{�Џ��i�敪 �J�e�S���Z�b�gID,�J�e�S��ID�擾
            -- �e�i�ڂƓ����ꍇ�m�t�k�k��ݒ�
            SELECT      DECODE( p_hon.p_hon_prd, c_hon.c_hon_prd, NULL
                                               , p_hon.category_set_id )    category_set_id
                       ,DECODE( p_hon.p_hon_prd, c_hon.c_hon_prd, NULL
                                               , p_hon.category_id )        category_id
            INTO        ln_category_set_id
                       ,ln_category_id
            FROM        -- �{�Џ��i�敪�p(�e�i��)
                      ( SELECT      mcsv_ho.category_set_id   category_set_id
                                   ,mcv_ho.category_id        category_id
                                   ,mcv_ho.segment1           p_hon_prd
                        FROM        gmi_item_categories       gic_ho
                                   ,mtl_category_sets_vl      mcsv_ho
                                   ,mtl_categories_vl         mcv_ho
                        WHERE       mcsv_ho.category_set_name = cv_categ_set_hon_prod
                        AND         gic_ho.category_set_id    = mcsv_ho.category_set_id
                        AND         gic_ho.category_id        = mcv_ho.category_id
                        AND         gic_ho.item_id            = i_update_item_rec.parent_item_id ) p_hon,
                        -- �{�Џ��i�敪�p(�q�i��)
                      ( SELECT      mcv_ho.segment1           c_hon_prd
                        FROM        gmi_item_categories       gic_ho
                                   ,mtl_category_sets_vl      mcsv_ho
                                   ,mtl_categories_vl         mcv_ho
                        WHERE       mcsv_ho.category_set_name = cv_categ_set_hon_prod
                        AND         gic_ho.category_set_id    = mcsv_ho.category_set_id
                        AND         gic_ho.category_id        = mcv_ho.category_id
                        AND         gic_ho.item_id            = i_update_item_rec.item_id ) c_hon;
            --
          EXCEPTION
            WHEN OTHERS THEN
              lv_msg_errm  := SQLERRM;
              lv_msg_token := cv_tkn_val_categ_prd_class;
              RAISE data_select_err_expt;  -- ���o�G���[
          END;
          --
          -- �e�i�ڂ̖{�Џ��i�敪�ƈقȂ�ꍇ���������{
          IF ( ln_category_set_id IS NOT NULL ) THEN
            -- OPM�i�ڃJ�e�S���X�V�p�p�����[�^�ݒ�
            l_opmitem_category_rec.item_id            := i_update_item_rec.item_id;
            l_opmitem_category_rec.category_set_id    := ln_category_set_id;
            l_opmitem_category_rec.category_id        := ln_category_id;
            -- Disc�i�ڃJ�e�S���X�V�p�p�����[�^�ݒ�
            l_discitem_category_rec.inventory_item_id := i_update_item_rec.inventory_item_id;
            l_discitem_category_rec.category_set_id   := ln_category_set_id;
            l_discitem_category_rec.category_id       := ln_category_id;
            --
            -- OPM�i�ڃJ�e�S�����f
            lv_step := 'STEP-08420';
            xxcmm_004common_pkg.proc_opmitem_categ_ref(
              i_item_category_rec  =>  l_opmitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
             ,ov_errbuf            =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode           =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg            =>  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              lv_msg_errm  := lv_errmsg;
              lv_msg_token := cv_tkn_val_opm_item_categ;
              RAISE data_update_err_expt;
            END IF;
            --
            -- Disc�i�ڃJ�e�S�����f
            lv_step := 'STEP-08430';
            xxcmm_004common_pkg.proc_discitem_categ_ref(
              i_item_category_rec  =>  l_discitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
             ,ov_errbuf            =>  lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode           =>  lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg            =>  lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              lv_msg_errm  := lv_errmsg;
              lv_msg_token := cv_tkn_val_mtl_item_categ;
              RAISE data_update_err_expt;
            END IF;
          END IF;
          --
        END IF;
        --
-- Ver1.6 ADD END
        --
        --==============================================================
        --A-6.2-3 �c�ƌ����̓o�^
        --A-6.2-4 OPM�i�ڍX�V
        --==============================================================
        lv_step := 'STEP-08510';
        proc_item_update(
          in_item_id            =>  i_update_item_rec.item_id              -- OPM�i��ID
         ,in_inventory_item_id  =>  i_update_item_rec.inventory_item_id    -- Disc�i��ID
         ,iv_item_no            =>  i_update_item_rec.item_no              -- �i�ڃR�[�h
         ,iv_policy_group       =>  lv_policy_group_parent                 -- ����Q�R�[�h
         ,in_fixed_price        =>  ln_fixed_price_parent                  -- �艿
         ,in_discrete_cost      =>  ln_discrete_cost_parent                -- �c�ƌ���
         ,in_organization_id    =>  gn_cost_org_id                         -- Disc�i�ڌ����g�DID
         ,iv_apply_date         =>  TO_CHAR( i_update_item_rec.apply_date, cv_date_fmt_std ) 
                                                                           -- �K�p��
         ,ov_errbuf             =>  lv_errbuf                              -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode            =>  lv_retcode                             -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg             =>  lv_errmsg                              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          --
          RAISE sub_proc_expt;
        END IF;
      END IF;
    END IF;
    --
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
    -- *** �f�[�^�o�^�G���[(�i�ڋ���API)��O�n���h�� ***
    WHEN item_common_ins_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00444            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_errmsg                     -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^���o��O�n���h�� ***
    WHEN data_select_err_expt THEN
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00442            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_data_info              -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                    );
      --
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg || cv_msg_space|| lv_msg_errm;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN data_update_err_expt THEN
      --
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00445            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_msg_errm                   -- �g�[�N���l3
                    );
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END proc_inherit_parent;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : �f�[�^�Ó����`�F�b�N
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,iv_item_status_name   IN     VARCHAR2
   ,ov_errbuf             OUT    VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode            OUT    VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg             OUT    VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'VALIDATE_ITEM';      -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_product_com             CONSTANT VARCHAR2(1)   := '1';                  -- ���i(1)
    cv_head_product_drink      CONSTANT VARCHAR2(1)   := '2';                  -- �h�����N(2)
    --
    cv_validate_info           CONSTANT VARCHAR2(20)  := '�i�ڃ`�F�b�N���';
    cv_item_name_alt           CONSTANT VARCHAR2(20)  := '�J�i';
    cv_sales_div               CONSTANT VARCHAR2(20)  := '����Ώ�';
    cv_parent_item             CONSTANT VARCHAR2(20)  := '�e���i�R�[�h';
    cv_fixed_price             CONSTANT VARCHAR2(20)  := '�艿';
    cv_num_of_cases            CONSTANT VARCHAR2(20)  := '�P�[�X����';
    cv_item_um                 CONSTANT VARCHAR2(20)  := '��P��';
    cv_rate_class              CONSTANT VARCHAR2(20)  := '���敪';
    cv_net                     CONSTANT VARCHAR2(20)  := '�m�d�s';
    cv_unit                    CONSTANT VARCHAR2(20)  := '�d��/�̐�';
    cv_nets                    CONSTANT VARCHAR2(20)  := '���e��';
    cv_nets_uom_code           CONSTANT VARCHAR2(20)  := '���e�ʒP��';
    cv_inc_num                 CONSTANT VARCHAR2(20)  := '�������';
    cv_baracha_div             CONSTANT VARCHAR2(20)  := '�o�����敪';
    cv_item_product            CONSTANT VARCHAR2(20)  := '���i���i�敪';
    cv_head_product            CONSTANT VARCHAR2(20)  := '�{�Џ��i�敪';
    cv_discrete_cost           CONSTANT VARCHAR2(20)  := '�c�ƌ���';
    cv_policy_group            CONSTANT VARCHAR2(20)  := '����Q';
    cv_opmcost                 CONSTANT VARCHAR2(20)  := '�W������';
    cv_sp_supplier_code        CONSTANT VARCHAR2(20)  := '���X�d����';
    cv_palette_max_cs_qty      CONSTANT VARCHAR2(20)  := '�z��';
    cv_palette_max_step_qty    CONSTANT VARCHAR2(20)  := '�i��';
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                    VARCHAR2(10);
    lv_msg_token               VARCHAR2(100);
    --
    ln_exists_cnt              NUMBER;
    lv_item_product            mtl_categories.segment1%TYPE;
    lv_head_product            mtl_categories.segment1%TYPE;
    --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    ln_cmpnt_cost_sum          cm_cmpt_dtl.cmpnt_cost%TYPE;
-- End1.9
--
-- 2009/10/16 Ver1.13 ��Q0001423 add start by Y.Kuboshima
    lv_parent_code             ic_item_mst_b.item_no%TYPE;            -- �e�i�ڃR�[�h
    ln_parent_status           xxcmm_system_items_b.item_status%TYPE; -- �e�i�ڃX�e�[�^�X
    lv_parent_status_name      fnd_lookup_values.meaning%TYPE;        -- �e�i�ڃX�e�[�^�X��
-- 2009/10/16 Ver1.13 ��Q0001423 add end by Y.Kuboshima
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    data_validate_expt         EXCEPTION;    -- �f�[�^�`�F�b�N�G���[
-- Ver1.5 �`�F�b�N�����ǉ�
    child_status_chk_expt      EXCEPTION;    -- �q�i�ڃX�e�[�^�X�`�F�b�N�G���[
    parent_status_chk_expt     EXCEPTION;    -- �e�i�ڃX�e�[�^�X�`�F�b�N�G���[
-- End
    --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    opm_cost_chk_expt          EXCEPTION;    -- �W������0�~�G���[
    disc_cost_chk_expt         EXCEPTION;    -- �c�ƌ����G���[
-- End1.9
    --
-- 2009/08/10 Ver1.11 ��Q0000862 add start by Y.Kuboshima
    cost_decimal_chk_expt      EXCEPTION;    -- �W�����������G���[
-- 2009/08/10 Ver1.11 ��Q0000862 add end by Y.Kuboshima
    --
-- 2009/10/16 Ver1.13 ��Q0001423 add start by Y.Kuboshima
    parent_st_regist_chk_expt  EXCEPTION;    -- �e�i�ږ{�o�^�X�e�[�^�X�`�F�b�N�G���[
-- 2009/10/16 Ver1.13 ��Q0001423 add start by Y.Kuboshima
    --
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
-- Ver1.5 �`�F�b�N�����ǉ�
    -- �e�i�ڂ̃X�e�[�^�X���c�ɕύX���A�q�i�ڂ̃X�e�[�^�X���S�Ăc�ł��邱��
    IF  ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id )
    AND ( i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
      --
      lv_step := 'STEP-07010';
      -- �q�i�ڂ̃X�e�[�^�X�`�F�b�N
      SELECT      COUNT( xoiv.item_id )
      INTO        ln_exists_cnt
      FROM        xxcmm_opmmtl_items_v      xoiv                                -- �i�ڃr���[
      WHERE       xoiv.parent_item_id     = i_update_item_rec.item_id           -- �e�i��ID
      AND         xoiv.item_id           != i_update_item_rec.item_id           -- �e�i�ڈȊO
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )                    -- �K�p�J�n��
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE )                    -- �K�p�I����
      AND         xoiv.start_date_active <= gd_process_date                     -- �K�p�J�n��
      AND         xoiv.end_date_active   >= gd_process_date                     -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
      AND         NVL( xoiv.item_status, cn_itm_status_num_tmp )
                                         != cn_itm_status_no_use                -- �c�ȊO
      AND         ROWNUM = 1;
      --
      IF ( ln_exists_cnt = 1 ) THEN
        RAISE child_status_chk_expt;
      END IF;
      --
    -- �q�i�ڂ̃X�e�[�^�X�ύX���A�e�i�ڂ̃X�e�[�^�X���c�łȂ�����
    --  ���̔ԁA���o�^���ɂ͎q�i�ڂ̍쐬�͂ł��Ȃ����߃`�F�b�N���Ȃ��B
    ELSIF ( i_update_item_rec.item_id != i_update_item_rec.parent_item_id )
    AND   ( i_update_item_rec.item_status != cn_itm_status_no_use ) THEN
      --
      lv_step := 'STEP-07020';
-- 2009/10/16 Ver1.13 ��Q0001423 modify start by Y.Kuboshima
--      -- �e�i�ڂ̃X�e�[�^�X�`�F�b�N
--      SELECT      COUNT( xoiv.item_id )
--      INTO        ln_exists_cnt
--      FROM        xxcmm_opmmtl_items_v      xoiv                                -- �i�ڃr���[
--      WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id    -- �e�i��
---- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
----      AND         xoiv.start_date_active <= TRUNC( SYSDATE )                    -- �K�p�J�n��
----      AND         xoiv.end_date_active   >= TRUNC( SYSDATE )                    -- �K�p�I����
--      AND         xoiv.start_date_active <= gd_process_date                     -- �K�p�J�n��
--      AND         xoiv.end_date_active   >= gd_process_date                     -- �K�p�I����
---- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
--      AND         xoiv.item_status        = cn_itm_status_no_use                -- �c�ȊO
--      AND         ROWNUM = 1;
--      --
--      IF ( ln_exists_cnt = 1 ) THEN
--        RAISE parent_status_chk_expt;
--      END IF;
      -- �{�o�^�ɃX�e�[�^�X�ύX���A�e�i�ڂ̃X�e�[�^�X���{�o�^�ȊO�̏ꍇ�̓G���[
      IF (i_update_item_rec.item_status = cn_itm_status_regist ) THEN
        BEGIN
          -- �e�i�ڃR�[�h�A�e�i�ڃX�e�[�^�X�擾
          SELECT xoiv.item_no
                ,xoiv.item_status
                ,flvv.meaning
          INTO   lv_parent_code
                ,ln_parent_status
                ,lv_parent_status_name
          FROM   xxcmm_opmmtl_items_v xoiv
                ,fnd_lookup_values_vl flvv
          WHERE  TO_CHAR(xoiv.item_status) = flvv.lookup_code
          AND    xoiv.item_id              = i_update_item_rec.parent_item_id    -- �e�i��
          AND    xoiv.start_date_active   <= gd_process_date                     -- �K�p�J�n��
          AND    xoiv.end_date_active     >= gd_process_date                     -- �K�p�I����
          AND    flvv.lookup_type          = cv_lookup_item_status
          AND    ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            lv_parent_code        := NULL;
            ln_parent_status      := -1;
            lv_parent_status_name := NULL;
        END;
        --
        -- �e�i�ڂ̃X�e�[�^�X�`�F�b�N
        -- �{�o�^�ȊO�̏ꍇ�̓G���[
        IF ( ln_parent_status <> cn_itm_status_regist ) THEN
          RAISE parent_st_regist_chk_expt;
        END IF;
      -- �{�o�^�ȊO�ɃX�e�[�^�X�ύX���A�e�i�ڂ̃X�e�[�^�X���c�̏ꍇ�̓G���[
      ELSE
        -- �e�i�ڂ̃X�e�[�^�X�`�F�b�N
        SELECT      COUNT( xoiv.item_id )
        INTO        ln_exists_cnt
        FROM        xxcmm_opmmtl_items_v      xoiv                                -- �i�ڃr���[
        WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id    -- �e�i��
        AND         xoiv.start_date_active <= gd_process_date                     -- �K�p�J�n��
        AND         xoiv.end_date_active   >= gd_process_date                     -- �K�p�I����
        AND         xoiv.item_status        = cn_itm_status_no_use                -- �c
        AND         ROWNUM = 1;
        --
        IF ( ln_exists_cnt = 1 ) THEN
          RAISE parent_status_chk_expt;
        END IF;
      END IF;
-- 2009/10/16 Ver1.13 ��Q0001423 modify end by Y.Kuboshima
    END IF;
-- End
    --
    -- �ύX�O�X�e�[�^�X��NULL�A���̔ԁA���o�^�A�c
    -- �ύX��X�e�[�^�X�����o�^�A�{�o�^�A�p�A�c�f�̏ꍇ�`�F�b�N����B
    lv_step := 'STEP-07100';
    IF  ( NVL( i_update_item_rec.b_item_status, cn_itm_status_num_tmp ) IN ( cn_itm_status_num_tmp      -- ���̔�
                                                                           , cn_itm_status_pre_reg      -- ���o�^
                                                                           , cn_itm_status_no_use ) )   -- �c
    AND ( i_update_item_rec.item_status IN ( cn_itm_status_pre_reg              -- ���o�^
                                           , cn_itm_status_regist               -- �{�o�^
                                           , cn_itm_status_no_sch               -- �p
                                           , cn_itm_status_trn_only ) ) THEN    -- �c�f
      --=====================================================================================
      -- �ύX�K�p���f���\���`�F�b�N
      -- �E���o�^�ȍ~�F�q�i�� �J�i�A����ΏہA�e���i �K�{
      --                      ���e���i���ݒ肳��Ă���Α����ڂ��ݒ肳��Ă���z��B
      -- �E���o�^�ȍ~�F�e�i�� �艿�i�ύX�K�p�j
      --                      �J�i�A����ΏہA�e���i
      --                      �P�[�X�����A��P�ʁA���i���i�敪
      --                      NET�A�d��/�̐ρA���e�ʁA���e�ʒP��
      --                      ��������A�{�Џ��i�敪�A�o�����敪
      -- �E�{�o�^�ȍ~�F�e�i�� �c�ƌ����A����Q�R�[�h�i�ύX�K�p�j
      --                      �W�������A���X�d����(���i�̏ꍇ�̂�)
      --                      �z��(�h�����N�̏ꍇ�̂�)�A�i��(�h�����N�̏ꍇ�̂�)
      --=====================================================================================
      -------------------------
      -- �`�F�b�N����
      -------------------------
      -- �J�i��
      lv_step := 'STEP-07110';
      IF ( i_update_item_rec.item_name_alt IS NULL ) THEN
        lv_msg_token := cv_item_name_alt;
        RAISE data_validate_expt;
      END IF;
      --
      -- ����Ώۋ敪
      lv_step := 'STEP-07120';
      IF ( i_update_item_rec.sales_div IS NULL ) THEN
        lv_msg_token := cv_sales_div;
        RAISE data_validate_expt;
      END IF;
      --
      -- �e�i��ID
      lv_step := 'STEP-07130';
      IF ( i_update_item_rec.parent_item_id IS NULL ) THEN
        lv_msg_token := cv_parent_item;
        RAISE data_validate_expt;
      END IF;
      --
      -- �e�i�ڂ̏ꍇ
      IF ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id ) THEN
        --
        lv_step := 'STEP-07210';
        BEGIN
          -- ���i���i�敪�̎擾
          SELECT      mcv.segment1             item_product                 -- ���i���i�敪
          INTO        lv_item_product                                       -- ���i���i�敪
          FROM        gmi_item_categories      gic                          -- OPM�i�ڃJ�e�S�������i���i���i�敪�j
                     ,mtl_category_sets_vl     mcsv                         -- �J�e�S���Z�b�g�r���[�i���i���i�敪�j
                     ,mtl_categories_vl        mcv                          -- �J�e�S���r���[�i���i���i�敪�j
          WHERE       mcsv.category_set_name = cv_categ_set_item_prod       -- ���i���i�敪
          AND         gic.item_id            = i_update_item_rec.item_id    -- �i��
          AND         gic.category_set_id    = mcsv.category_set_id         -- �J�e�S���Z�b�gID
          AND         gic.category_id        = mcv.category_id;             -- �J�e�S��ID
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_item_product := NULL;
        END;
        --
        lv_step := 'STEP-07220';
        BEGIN
          -- �{�Џ��i�敪
          SELECT      mcv.segment1             head_product                 -- �{�Џ��i�敪
          INTO        lv_head_product                                       -- �{�Џ��i�敪
          FROM        gmi_item_categories      gic                          -- OPM�i�ڃJ�e�S�������i�{�Џ��i�敪�j
                     ,mtl_category_sets_vl     mcsv                         -- �J�e�S���Z�b�g�r���[�i�{�Џ��i�敪�j
                     ,mtl_categories_vl        mcv                          -- �J�e�S���r���[�i�{�Џ��i�敪�j
          WHERE       mcsv.category_set_name = cv_categ_set_hon_prod        -- �{�Џ��i�敪
          AND         gic.item_id            = i_update_item_rec.item_id    -- �i��
          AND         gic.category_set_id    = mcsv.category_set_id         -- �J�e�S���Z�b�gID
          AND         gic.category_id        = mcv.category_id;             -- �J�e�S��ID
          --
        EXCEPTION
          WHEN OTHERS THEN
            lv_head_product := NULL;
        END;
        --
        -- �ύX�O�X�e�[�^�X�́ANULL�A���̔ԁA���o�^�A�c�̂�
        -- �ύX��X�e�[�^�X�́A���o�^�A�{�o�^�A�p�A�c�f�̂�
        --  �܂Ƃ�
        --    �ύX�O�X�e�[�^�X   �ύX��X�e�[�^�X   ���o�^   �{�o�^   ���l
        --    NULL               ���̔�               �~       �~     
        --    NULL               ���o�^               ��       �~     
        --    NULL               �{�o�^               ��       ��     
        --    NULL               �p                   ��       ��     
        --    NULL               �c�f                 ��       ��     
        --    ���̔�             ���o�^               ��       �~     
        --    ���̔�             �{�o�^               ��       ��     
        --    ���̔�             �p                   ��       ��     
        --    ���̔�             �c�f                 ��       ��     
        --    ���o�^             �{�o�^               �~       ��     ���o�^�`�F�b�N�����{���Ă��悢
        --    ���o�^             �p                   �~       ��     ���o�^�`�F�b�N�����{���Ă��悢
        --    ���o�^             �c�f                 �~       ��     ���o�^�`�F�b�N�����{���Ă��悢
        --    �{�o�^�ȍ~         �|                   �~       �~     
        --    �c                 �{�o�^               ��       ��     
        --    �c                 �p                   ��       ��     
        --    �c                 �c�f                 ��       ��     
        --
        -- �ύX�O�X�e�[�^�X���w���o�^�x�ȊO(NULL, ���̔�, �c)�̏ꍇ
        -- ���o�^���̃`�F�b�N�����{����B
-- Ver1.9  2009/07/06  Mod  �ύX�O�X�e�[�^�X��NULL���`�F�b�N����Ȃ����߁B
--        IF ( i_update_item_rec.b_item_status != cn_itm_status_pre_reg ) THEN
        IF ( NVL( i_update_item_rec.b_item_status, cn_itm_status_num_tmp ) != cn_itm_status_pre_reg ) THEN
-- End1.9
          --------------------------------------
          -- ���o�^�`�F�b�N
          --------------------------------------
          -- �艿
          lv_step := 'STEP-07310';
          IF (   i_update_item_rec.price_new   IS NULL
             AND i_update_item_rec.fixed_price IS NULL ) THEN
            lv_msg_token := cv_fixed_price;
            RAISE data_validate_expt;
          END IF;
          --
          -- �P�[�X����
          lv_step := 'STEP-07320';
          IF ( i_update_item_rec.num_of_cases IS NULL ) THEN
            lv_msg_token := cv_num_of_cases;
            RAISE data_validate_expt;
          END IF;
          --
          -- �P��
          lv_step := 'STEP-07330';
          IF ( i_update_item_rec.item_um IS NULL ) THEN
            lv_msg_token := cv_item_um;
            RAISE data_validate_expt;
          END IF;
          --
-- Ver1.3 2009/01/29 ADD ���敪��K�{���ڂɒǉ�
          -- ���敪
          lv_step := 'STEP-07340';
          IF ( i_update_item_rec.rate_class IS NULL ) THEN
            lv_msg_token := cv_rate_class;
            RAISE data_validate_expt;
          END IF;
-- End
          -- NET
          lv_step := 'STEP-07350';
          IF ( i_update_item_rec.net IS NULL ) THEN
            lv_msg_token := cv_net;
            RAISE data_validate_expt;
          END IF;
          --
          -- �d��/�̐�
          lv_step := 'STEP-07360';
          IF ( i_update_item_rec.unit IS NULL ) THEN
            lv_msg_token := cv_unit;
            RAISE data_validate_expt;
          END IF;
          --
          -- ���e��
          lv_step := 'STEP-07370';
          IF ( i_update_item_rec.nets IS NULL ) THEN
            lv_msg_token := cv_nets;
            RAISE data_validate_expt;
          END IF;
          --
          -- ���e�ʒP��
          lv_step := 'STEP-07380';
          IF ( i_update_item_rec.nets_uom_code IS NULL ) THEN
            lv_msg_token := cv_nets_uom_code;
            RAISE data_validate_expt;
          END IF;
          --
          -- �������
          lv_step := 'STEP-07390';
          IF ( i_update_item_rec.inc_num IS NULL ) THEN
            lv_msg_token := cv_inc_num;
            RAISE data_validate_expt;
          END IF;
          --
          -- �o�����敪
          lv_step := 'STEP-07400';
          IF ( i_update_item_rec.baracha_div IS NULL ) THEN
            lv_msg_token := cv_baracha_div;
            RAISE data_validate_expt;
          END IF;
          --
          -- ���i���i�敪
          lv_step := 'STEP-07410';
          IF ( lv_item_product IS NULL ) THEN
            lv_msg_token := cv_item_product;
            RAISE data_validate_expt;
          END IF;
          --
          -- �{�Џ��i�敪
          lv_step := 'STEP-07420';
          IF ( lv_head_product IS NULL ) THEN
            lv_msg_token := cv_head_product;
            RAISE data_validate_expt;
          END IF;
          --
        END IF;
        --
        -- �ύX��X�e�[�^�X���w���o�^�x�ȊO(�{�o�^, �p, �c�f)�̏ꍇ
        -- �{�o�^���̃`�F�b�N�����{����B
        IF ( i_update_item_rec.item_status != cn_itm_status_pre_reg ) THEN
          --------------------------------------
          -- �{�o�^�`�F�b�N
          --------------------------------------
          -- �c�ƌ���
          lv_step := 'STEP-07510';
          IF (   i_update_item_rec.opt_cost_new  IS NULL
             AND i_update_item_rec.discrete_cost IS NULL ) THEN
            lv_msg_token := cv_discrete_cost;
            RAISE data_validate_expt;
          END IF;
          --
          -- ����Q�R�[�h
          lv_step := 'STEP-07520';
          IF (   i_update_item_rec.crowd_code_new  IS NULL
             AND i_update_item_rec.policy_group    IS NULL ) THEN
            lv_msg_token := cv_policy_group;
            RAISE data_validate_expt;
          END IF;
          --
-- Ver1.9  2009/07/06  Del  ��Q�Ή�(0000364)
--          -- �W������
--          lv_step := 'STEP-07530';
--          SELECT    COUNT( ccmd.cmpntcost_id )
--          INTO      ln_exists_cnt
--          FROM      cm_cmpt_dtl                ccmd                          -- OPM�W������
--                   ,cm_cldr_dtl                cclr                          -- OPM�����J�����_
--                   ,cm_cmpt_mst_vl             ccmv                          -- �����R���|�[�l���g
--                   ,fnd_lookup_values_vl       flv                           -- �Q�ƃR�[�h�l
--          WHERE     ccmd.item_id             = i_update_item_rec.item_id     -- �i��ID
--          AND       cclr.start_date         <= i_update_item_rec.apply_date  -- �J�n��
--          AND       cclr.end_date           >= i_update_item_rec.apply_date  -- �I����
--          AND       flv.lookup_type          = cv_lookup_cost_cmpt           -- �Q�ƃ^�C�v
--          AND       flv.enabled_flag         = cv_yes                        -- �g�p�\
--          AND       ccmv.cost_cmpntcls_code  = flv.meaning                   -- �����R���|�[�l���g�R�[�h
--          AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id         -- �����R���|�[�l���gID
--          AND       ccmd.calendar_code       = cclr.calendar_code            -- �J�����_�R�[�h
--          AND       ccmd.period_code         = cclr.period_code              -- ���ԃR�[�h
--          AND       ccmd.whse_code           = cv_whse_code                  -- �q��
--          AND       ccmd.cost_mthd_code      = cv_cost_mthd_code             -- �������@
--          AND       ccmd.cost_analysis_code  = cv_cost_analysis_code         -- ���̓R�[�h
--          AND       ROWNUM                   = 1;
--          --
--          IF ( ln_exists_cnt = 0 ) THEN
--            lv_msg_token := cv_opmcost;
--            RAISE data_validate_expt;
--          END IF;
-- End1.9
          --
          -- ���i���i�敪 = �u���i�v�̏ꍇ�K�{
          -- ���X�d����
          lv_step := 'STEP-07540';
          IF  ( lv_item_product = cv_product_com ) 
          AND ( i_update_item_rec.sp_supplier_code IS NULL ) THEN
            lv_msg_token := cv_sp_supplier_code;
            RAISE data_validate_expt;
          END IF;
          --
          -- �{�Џ��i�敪 = �u�h�����N�v�̏ꍇ�K�{
          IF ( lv_head_product = cv_head_product_drink ) THEN
            -- �z��
            lv_step := 'STEP-07550';
            IF ( i_update_item_rec.palette_max_cs_qty IS NULL ) THEN
              lv_msg_token := cv_palette_max_cs_qty;
              RAISE data_validate_expt;
            END IF;
            --
            -- �i��
            lv_step := 'STEP-07560';
            IF ( i_update_item_rec.palette_max_step_qty IS NULL ) THEN
              lv_msg_token := cv_palette_max_step_qty;
              RAISE data_validate_expt;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
    --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    -- �e�i�ڂ̏ꍇ�A�W������������ɓo�^����Ă��邩
    -- �܂��A�c�ƌ����̗\��̏ꍇ
    IF  ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id ) THEN
      --
      -- �W�������v�̎擾
      SELECT    COUNT( ccmd.cmpntcost_id )
               ,SUM( ccmd.cmpnt_cost )
      INTO      ln_exists_cnt
               ,ln_cmpnt_cost_sum
      FROM      cm_cmpt_dtl                ccmd                          -- OPM�W������
               ,cm_cldr_dtl                cclr                          -- OPM�����J�����_
               ,cm_cmpt_mst_vl             ccmv                          -- �����R���|�[�l���g
               ,fnd_lookup_values_vl       flv                           -- �Q�ƃR�[�h�l
      WHERE     ccmd.item_id             = i_update_item_rec.item_id     -- �i��ID
      AND       cclr.start_date         <= i_update_item_rec.apply_date  -- �J�n��
      AND       cclr.end_date           >= i_update_item_rec.apply_date  -- �I����
      AND       flv.lookup_type          = cv_lookup_cost_cmpt           -- �Q�ƃ^�C�v
      AND       flv.enabled_flag         = cv_yes                        -- �g�p�\
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                   -- �����R���|�[�l���g�R�[�h
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id         -- �����R���|�[�l���gID
      AND       ccmd.calendar_code       = cclr.calendar_code            -- �J�����_�R�[�h
      AND       ccmd.period_code         = cclr.period_code              -- ���ԃR�[�h
      AND       ccmd.whse_code           = cv_whse_code                  -- �q��
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code             -- �������@
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code;        -- ���̓R�[�h
      --
      IF ( i_update_item_rec.item_status IN ( cn_itm_status_regist               -- �{�o�^
                                            , cn_itm_status_no_sch               -- �p
                                            , cn_itm_status_trn_only ) ) THEN    -- �c�f
        --
        -- �����R���|�[�l���g���o�^���̓G���[
        IF ( ln_exists_cnt = 0 ) THEN
          lv_msg_token := cv_opmcost;
          RAISE data_validate_expt;
        -- �W������ = 0 �̏ꍇ�G���[
        ELSIF ( ln_cmpnt_cost_sum = 0 ) THEN
          RAISE opm_cost_chk_expt;
-- 2009/08/10 Ver1.11 ��Q0000862 add start by Y.Kuboshima
        ELSE
          -- ���ޕi�ڂ̏ꍇ
          IF ( SUBSTRB( i_update_item_rec.item_no, 1, 1 ) IN ( cv_leaf_material, cv_drink_material )  ) THEN
            -- �W�������������_�O���ȏ�̏ꍇ
            IF ( ln_cmpnt_cost_sum <> TRUNC( ln_cmpnt_cost_sum, 2 ) ) THEN
              -- �W�������G���[
              RAISE cost_decimal_chk_expt;
            END IF;
          -- ���ޕi�ڈȊO�̏ꍇ
          ELSE
            -- �W�������������ȊO�̏ꍇ
            IF ( ln_cmpnt_cost_sum <> TRUNC( ln_cmpnt_cost_sum ) ) THEN
              -- �W�������G���[
              RAISE cost_decimal_chk_expt;
            END IF;
          END IF;
-- 2009/08/10 Ver1.11 ��Q0000862 add end by Y.Kuboshima
        END IF;
        --
      END IF;
      --
      IF ( i_update_item_rec.discrete_cost IS NOT NULL ) THEN
        -- �c�ƌ��� < �W������ �̏ꍇ�G���[
        IF ( i_update_item_rec.discrete_cost < ln_cmpnt_cost_sum ) THEN
          RAISE disc_cost_chk_expt;
        END IF;
      END IF;
      --
    END IF;
-- End1.9
    --
  EXCEPTION
--
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    -- *** �W������0�~�`�F�b�N��O�n���h�� ***
    WHEN opm_cost_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00432                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item_code                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �c�ƌ����`�F�b�N��O�n���h�� ***
    WHEN disc_cost_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00433                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_disc_cost                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => TO_CHAR( i_update_item_rec.discrete_cost )
                                                                               -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_opm_cost                       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => TO_CHAR( ln_cmpnt_cost_sum )          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item_code                      -- �g�[�N���R�[�h3
                     ,iv_token_value3 => i_update_item_rec.item_no             -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- End1.9
--
-- Ver1.5 �`�F�b�N�����ǉ�
    -- *** �q�i�ڃX�e�[�^�X�`�F�b�N��O�n���h�� ***
    WHEN child_status_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00436                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item_code                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_status                    -- �g�[�N���R�[�h2
                     ,iv_token_value2 => iv_item_status_name                   -- �g�[�N���l2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �e�i�ڃX�e�[�^�X�`�F�b�N��O�n���h�� ***
    WHEN parent_status_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00437                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item_code                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_status                    -- �g�[�N���R�[�h2
                     ,iv_token_value2 => iv_item_status_name                   -- �g�[�N���l2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- End
--
--
-- 2009/10/16 Ver1.13 ��Q0001423 add start by Y.Kuboshima
    -- *** �e�i�ږ{�o�^�X�e�[�^�X�`�F�b�N��O�n���h�� ***
    WHEN parent_st_regist_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00492                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item_code                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_parent_item                    -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_parent_code                        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item_status                    -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_parent_status_name                 -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- 2009/10/16 Ver1.13 ��Q0001423 add end by Y.Kuboshima
--
-- 2009/08/10 Ver1.11 ��Q0000862 add start by Y.Kuboshima
    -- *** �W�����������`�F�b�N��O�n���h�� ***
    WHEN cost_decimal_chk_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00491                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_opm_cost                       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => TO_CHAR( ln_cmpnt_cost_sum )          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code                      -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no             -- �g�[�N���l2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
-- 2009/08/10 Ver1.11 ��Q0000862 add end by Y.Kuboshima
--
    -- *** �f�[�^�`�F�b�N��O�n���h�� ***
    WHEN data_validate_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00450                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_data_info                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                          -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code                      -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_item_status                    -- �g�[�N���R�[�h3
                     ,iv_token_value3 => iv_item_status_name                   -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : proc_item_status_update
   * Description      : �i�ڃX�e�[�^�X���f����(A-5)
   **********************************************************************************/
  PROCEDURE proc_item_status_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2             --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_ITEM_STATUS_UPDATE'; -- �v���O������
-- 2009/09/11 Ver1.12 ��Q0000948 add start by Y.Kuboshima
    cv_uom_class_conv_to         CONSTANT VARCHAR2(10) := 'CS';
-- 2009/09/11 Ver1.12 ��Q0000948 add end by Y.Kuboshima
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cn_process_flag              CONSTANT NUMBER(1)    := 1;
    cv_tran_type_create          CONSTANT VARCHAR2(10) := 'CREATE';          -- �V�K�o�^
    cv_tran_type_update          CONSTANT VARCHAR2(10) := 'UPDATE';          -- �X�V
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    lv_msg_errm                  VARCHAR2(4000);
    --
    lv_transaction_type          mtl_system_items_interface.transaction_type%TYPE;

    ln_exsits_count              NUMBER;
    --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    ln_cmp_cost_index            NUMBER;
-- END1.9
-- 2009/12/24 Ver1.14 ��QE_�{�ғ�_00577 add start by Shigeto.Niki
    ln_location_control_code     mtl_system_items_interface.location_control_code%TYPE;
-- 2009/12/24 Ver1.14 ��QE_�{�ғ�_00577 add end by Shigeto.Niki
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �i�ڃX�e�[�^�X�֘A���擾�J�[�\��
    CURSOR item_status_info_cur(
      pv_item_status    VARCHAR2 )
    IS
      SELECT     flvv.lookup_code    AS item_status_code                 -- �i�ڃX�e�[�^�X
                ,flvv.meaning        AS item_status_name                 -- �i�ڃX�e�[�^�X��
                ,flvv.attribute6     AS returnable_flag                  -- �ԕi�\
                ,flvv.attribute7     AS stock_enabled_flag               -- �݌ɕۗL�\
                ,flvv.attribute8     AS mtl_transactions_enabled_flag    -- ����\
                ,flvv.attribute9     AS customer_order_enabled_flag      -- �ڋq�󒍉\
--                ,flvv.attribute10    AS rate_class                       -- ���敪
                ,flvv.attribute11    AS obsolete_class                   -- �p�~�敪
      FROM       fnd_lookup_values_vl    flvv
      WHERE      flvv.lookup_type = cv_lookup_item_status
      AND        flvv.lookup_code = pv_item_status;
      --
    -- OPM�i�ڃA�h�I�����b�N�J�[�\��
    CURSOR xxcmn_item_lock_cur(
      pn_item_id    NUMBER )
    IS
      SELECT      'x'
      FROM        xxcmn_item_mst_b
      WHERE       item_id            = pn_item_id
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--      AND         start_date_active <= TRUNC(SYSDATE)
--      AND         end_date_active   >= TRUNC(SYSDATE)
      AND         start_date_active <= gd_process_date
      AND         end_date_active   >= gd_process_date
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
      FOR UPDATE NOWAIT;
      --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    -- �W�������w�b�_���o�J�[�\��
    CURSOR cnp_cost_hd_par_cur(
      pd_apply_date      DATE )
    IS
      SELECT    cclr.calendar_code            -- �J�����_�R�[�h
               ,cclr.period_code              -- ���ԃR�[�h
      FROM      cm_cldr_dtl          cclr     -- OPM�����J�����_
      WHERE     cclr.start_date         <= pd_apply_date    -- �J�n��
      AND       cclr.end_date           >= pd_apply_date    -- �I����
      ORDER BY  cclr.calendar_code
               ,cclr.period_code;
    --
    -- �W���������ג��o�J�[�\��
    CURSOR cnp_noext_cost_dt_cur(
      pn_item_id         NUMBER
     ,pv_calendar_code   VARCHAR2
     ,pv_period_code     VARCHAR2 )
    IS
      SELECT    cclr.calendar_code            -- �J�����_�R�[�h
               ,cclr.period_code              -- ���ԃR�[�h
               ,ccmv.cost_cmpntcls_id         -- �����R���|�[�l���gID
               ,ccmv.cost_cmpntcls_code       -- �����R���|�[�l���g�R�[�h
      FROM      cm_cldr_dtl          cclr     -- OPM�����J�����_
               ,cm_cmpt_mst_vl       ccmv     -- �����R���|�[�l���g
               ,fnd_lookup_values_vl flv      -- �Q�ƃR�[�h�l
      WHERE     cclr.calendar_code       = pv_calendar_code             -- �J�����_�R�[�h
      AND       cclr.period_code         = pv_period_code               -- ���ԃR�[�h
      AND       flv.lookup_type          = cv_lookup_cost_cmpt          -- �Q�ƃ^�C�v
      AND       flv.enabled_flag         = cv_yes                       -- �g�p�\
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                  -- �����R���|�[�l���g�R�[�h
      AND NOT EXISTS(
                  SELECT    'x'
                  FROM      cm_cmpt_dtl    ccmd      -- OPM�W������
                  WHERE     ccmd.item_id             = pn_item_id               -- �i��
                  AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id    -- �����R���|�[�l���gID
                  AND       ccmd.calendar_code       = cclr.calendar_code       -- �J�����_�R�[�h
                  AND       ccmd.period_code         = cclr.period_code         -- ���ԃR�[�h
                  AND       ccmd.whse_code           = cv_whse_code             -- �q��
                  AND       ccmd.cost_mthd_code      = cv_cost_mthd_code        -- �������@
                  AND       ccmd.cost_analysis_code  = cv_cost_analysis_code    -- ���̓R�[�h
                )
      ORDER BY  ccmv.cost_cmpntcls_code;
    --
-- 2009/09/11 Ver1.12 ��Q0000948 add start by Y.Kuboshima
    -- ��P�ʒ��o�J�[�\��
    CURSOR units_of_measure_cur(
      pv_item_um IN VARCHAR2 )
    IS
      SELECT     flvv.attribute1              -- �P�ʊ��Z�쐬�t���O
      FROM       fnd_lookup_values_vl flvv
      WHERE      flvv.lookup_type  = cv_lookup_item_um
      AND        flvv.enabled_flag = cv_yes
      AND        flvv.meaning      = pv_item_um;
    --
    -- ��P�ʒ��o���R�[�h�^
    l_units_of_measure_rec       units_of_measure_cur%ROWTYPE;
-- 2009/09/11 Ver1.12 ��Q0000948 add end by Y.Kuboshima
    --
-- END1.9
    -- <�J�[�\����>���R�[�h�^
    l_item_status_info_rec       item_status_info_cur%ROWTYPE;
    --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
    -- OPM�W�������p
    l_opm_cost_header_rec        xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab          xxcmm_004common_pkg.opm_cost_dist_ttype;
-- END1.9
    --
-- 2009/09/11 Ver1.12 ��Q0000948 add start by Y.Kuboshima
    -- �P�ʊ��Z�p
    l_uom_class_conv_rec         xxcmm_004common_pkg.uom_class_conv_rtype;
-- 2009/09/11 Ver1.12 ��Q0000948 add end by Y.Kuboshima
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    sub_proc_expt                EXCEPTION;
    data_select_err_expt         EXCEPTION;    -- �f�[�^���o�G���[
    data_insert_err_expt         EXCEPTION;    -- �f�[�^�o�^�G���[
    data_update_err_expt         EXCEPTION;    -- �f�[�^�X�V�G���[
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
    --A-5 �i�ڃX�e�[�^�X��񔽉f
    --==============================================================
    lv_step := 'STEP-06010';
    -- �i�ڃX�e�[�^�X���擾
    OPEN  item_status_info_cur( TO_CHAR( i_update_item_rec.item_status ) );
    --
    lv_step := 'STEP-06020';
    FETCH item_status_info_cur INTO l_item_status_info_rec;
    --
    IF item_status_info_cur%NOTFOUND THEN
      CLOSE item_status_info_cur;
      lv_msg_token := cv_tkn_val_item_status;
      RAISE data_select_err_expt;  -- ���o�G���[
    END IF;
    --
    lv_step := 'STEP-06030';
    CLOSE item_status_info_cur;
    --
    --==============================================================
    -- �f�[�^�Ó����`�F�b�N
    --==============================================================
    lv_step := 'STEP-06040';
    validate_item(
      i_update_item_rec    =>  i_update_item_rec    -- �i�ڕύX�K�p���
     ,iv_item_status_name  =>  l_item_status_info_rec.item_status_name
                                                    -- �i�ڃX�e�[�^�X����
     ,ov_errbuf            =>  lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           =>  lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg            =>  lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    ELSE
      --==============================================================
      --A-5.2 OPM�i�ڃA�h�I���̃��b�N�擾
      --==============================================================
      -- OPM�i�ڃA�h�I�����b�N
      lv_step := 'STEP-06050';
      lv_msg_token := cv_tkn_val_xxcmn_opmitem;
      --
      OPEN  xxcmn_item_lock_cur( i_update_item_rec.item_id );
      CLOSE xxcmn_item_lock_cur;
      --
      --==============================================================
      --A-5.2 OPM�i�ڃA�h�I���̍X�V
      --==============================================================
      BEGIN
        IF ( i_update_item_rec.parent_item_id IS NULL 
          OR i_update_item_rec.item_status = cn_itm_status_no_use ) THEN
          --
          -- �e�i�ږ��ݒ莞�A�܂��́A�i�ڃX�e�[�^�X���c�̏ꍇ�͐e�i�ڏ�񂩂�X�V���Ȃ��B
          lv_step := 'STEP-06060';
          UPDATE      xxcmn_item_mst_b
                      -- �p�~�敪
          SET         obsolete_class          = l_item_status_info_rec.obsolete_class
                      -- �p�~��
                     ,obsolete_date           = DECODE( i_update_item_rec.item_status
                                                       ,cn_itm_status_no_use, i_update_item_rec.apply_date, NULL )
                     ,last_updated_by         = cn_last_updated_by
                     ,last_update_date        = cd_last_update_date
                     ,last_update_login       = cn_last_update_login
                     ,request_id              = cn_request_id
                     ,program_application_id  = cn_program_application_id
                     ,program_id              = cn_program_id
                     ,program_update_date     = cd_program_update_date
                      --
          WHERE       item_id                 = i_update_item_rec.item_id
-- Ver1.1 2009/01/14 MOD �e�X�g�V�i���I 5-6
--          AND         active_flag             = cv_yes
-- Ver1.1 End
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--          AND         start_date_active      <= TRUNC( SYSDATE )
--          AND         end_date_active        >= TRUNC( SYSDATE );
          AND         start_date_active      <= gd_process_date
          AND         end_date_active        >= gd_process_date;
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
          --
        ELSE
          -- �e�i�ڐݒ莞�A���A�i�ڃX�e�[�^�X���c�ȊO�̏ꍇ�A
          -- �e�i�ڏ�񂩂珤�i���ށA�z���A�i����ݒ肷��i�e�i�ڂ̏ꍇ�����X�V����Ȃ��B�j
          lv_step := 'STEP-06070';
          UPDATE      xxcmn_item_mst_b
          SET       ( obsolete_class           -- �p�~�敪
                     ,obsolete_date            -- �p�~��
                     ,product_class            -- ���i����
                     ,palette_max_cs_qty       -- �z��
                     ,palette_max_step_qty     -- �i��
                     ,last_updated_by
                     ,last_update_date
                     ,last_update_login
                     ,request_id
                     ,program_application_id
                     ,program_id
                     ,program_update_date )
                 = (  SELECT      -- �p�~�敪
                                  l_item_status_info_rec.obsolete_class
                                  -- �p�~��
                                 ,DECODE( i_update_item_rec.item_status
                                         ,cn_itm_status_no_use, i_update_item_rec.apply_date, NULL )
                                  -- ���i����
                                 ,ximb.product_class
                                  -- �z��
                                 ,ximb.palette_max_cs_qty
                                  -- �i��
                                 ,ximb.palette_max_step_qty
                                 ,cn_last_updated_by
                                 ,cd_last_update_date
                                 ,cn_last_update_login
                                 ,cn_request_id
                                 ,cn_program_application_id
                                 ,cn_program_id
                                 ,cd_program_update_date
                      FROM        xxcmn_item_mst_b    ximb
                      WHERE       ximb.item_id            = i_update_item_rec.parent_item_id
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--                      AND         ximb.start_date_active <= TRUNC( SYSDATE )
--                      AND         ximb.end_date_active   >= TRUNC( SYSDATE ) )
                      AND         ximb.start_date_active <= gd_process_date
                      AND         ximb.end_date_active   >= gd_process_date )
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
          WHERE       item_id                 = i_update_item_rec.item_id
-- Ver1.1 2009/01/14 MOD �e�X�g�V�i���I 5-6
--          AND         active_flag             = cv_yes
-- Ver1.1 End
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--          AND         start_date_active      <= TRUNC( SYSDATE )
--          AND         end_date_active        >= TRUNC( SYSDATE );
          AND         start_date_active      <= gd_process_date
          AND         end_date_active        >= gd_process_date;
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
          --
        END IF;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg_errm  := SQLERRM;
          lv_msg_token := cv_tkn_val_xxcmn_opmitem;
          RAISE data_update_err_expt;  -- �X�V�G���[
      END;
      --
      --==============================================================
      --A-5.3 �c�Ƒg�D�FZ99�ւ̕i�ڊ����m�F
      --==============================================================
      -- 20:���o�^�̏ꍇ�A[Z99]�ɑg�D����
      -- 30:�{�o�^ 40:�p 50:�c�f60:�c�̏ꍇ�ADisc�i�ڂ��X�V
      -- �c�Ƒg�D[Z99]�ɕi�ڂ��������̏ꍇ�A�i�ڊ��������{
      IF ( i_update_item_rec.item_status IN ( cn_itm_status_pre_reg         -- 20:���o�^
                                             ,cn_itm_status_regist          -- 30:�{�o�^
                                             ,cn_itm_status_no_sch          -- 40:�p
                                             ,cn_itm_status_trn_only        -- 50:�c�f
                                             ,cn_itm_status_no_use ) )      -- 60:�c
      THEN
        -- Disc�i�ڃ}�X�^�ɑ΂���X�V���ڂ͂��ׂđg�D���x���B
        -- �X�V��Z99�݂̂�OK�Ȃ̂��H
        --==============================================================
        --A-5.3 �c�Ƒg�D�FZ99�ւ̕i�ڊ����m�F
        --==============================================================
        lv_step := 'STEP-06080';
-- 2009/12/24 Ver1.14 ��QE_�{�ғ�_00577 modify start by Shigeto.Niki
        -- �c�Ƒg�D�ɕi�ڂ����蓖�����Ă��邩�擾
--        SELECT      COUNT( msib.ROWID )
--        INTO        ln_exsits_count
--        FROM        mtl_system_items_b    msib
--        WHERE       msib.inventory_item_id = i_update_item_rec.inventory_item_id
--        AND         msib.organization_id   = gn_bus_org_id
--        AND         ROWNUM                 = 1;
--        --
--        IF ( ln_exsits_count = 0 ) THEN
--          -- �c�Ƒg�D�ɕi�ڂ��������Ă��Ȃ��ꍇ�A�o�^
--          lv_step := 'STEP-06090';
--          lv_transaction_type := cv_tran_type_create;
--        ELSE
--          -- �c�Ƒg�D�ɕi�ڂ��������Ă���ꍇ�A�X�V
--          lv_step := 'STEP-06100';
--          lv_transaction_type := cv_tran_type_update;
--        END IF;
        --
        BEGIN 
          -- �c�Ƒg�D�̕ۊǒI�Ǘ����擾
          SELECT      msib.location_control_code
          INTO        ln_location_control_code
          FROM        mtl_system_items_b    msib
          WHERE       msib.inventory_item_id = i_update_item_rec.inventory_item_id
          AND         msib.organization_id   = gn_bus_org_id
          AND         ROWNUM                 = 1;
          -- �c�Ƒg�D�̕ۊǒI�Ǘ����擾�ł����ꍇ�A�X�V
          lv_step := 'STEP-06100';
          lv_transaction_type := cv_tran_type_update;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �c�Ƒg�D�̕ۊǒI�Ǘ����擾�ł��Ȃ��ꍇ�A�o�^
            lv_step := 'STEP-06090';
            lv_transaction_type := cv_tran_type_create;
            ln_location_control_code := cn_location_control_code_no;
            --
        END;
-- 2009/12/24 Ver1.14 ��QE_�{�ғ�_00577 modify end by Shigeto.Niki
        --==============================================================
        --A-5.4 Disc�i�ڃ}�X�^�C���^�t�F�[�X�o�^
        --==============================================================
        lv_step := 'STEP-06110';
        BEGIN
          -- �i��I/F�֓o�^
          INSERT INTO  mtl_system_items_interface(
            inventory_item_id                -- Disc�i��ID
           ,organization_id                  -- �g�D�iZ99�j
           ,purchasing_item_flag             -- �w���i��
           ,shippable_item_flag              -- �o�׉\
           ,customer_order_flag              -- �ڋq��
           ,purchasing_enabled_flag          -- �w���\
           ,customer_order_enabled_flag      -- �ڋq�󒍉\
           ,internal_order_enabled_flag      -- �Г�����
           ,so_transactions_flag             -- OE ����\
           ,mtl_transactions_enabled_flag    -- ����\
           ,reservable_type                  -- �\��\
           ,returnable_flag                  -- �ԕi�\
           ,stock_enabled_flag               -- �݌ɕۗL�\
-- Ver1.7  2009/04/03 Add Start ���b�g�Ǘ�(LOT_CONTROL_CODE)�ǉ�
           ,lot_control_code                 -- ���b�g�Ǘ�
-- Ver1.7  2009/04/03 Add End
-- Ver1.10 2009/07/15 Add  �ۊǒI�Ǘ�(LOCATION_CONTROL_CODE)�ǉ�
           ,location_control_code            -- �ۊǒI�Ǘ�
-- End1.10
           ,process_flag                     -- �v���Z�X�t���O
           ,transaction_type )               -- �����^�C�v
          VALUES(
            i_update_item_rec.inventory_item_id
           ,gn_bus_org_id
           ,i_update_item_rec.purchasing_item_flag
           ,i_update_item_rec.shippable_item_flag
           ,i_update_item_rec.customer_order_flag
           ,i_update_item_rec.purchasing_enabled_flag
           ,l_item_status_info_rec.customer_order_enabled_flag
           ,i_update_item_rec.internal_order_enabled_flag
           ,i_update_item_rec.so_transactions_flag
           ,l_item_status_info_rec.mtl_transactions_enabled_flag
           ,i_update_item_rec.reservable_type
           ,l_item_status_info_rec.returnable_flag
           ,l_item_status_info_rec.stock_enabled_flag
-- Ver1.7  2009/04/03 Add Start ���b�g�Ǘ�(LOT_CONTROL_CODE)�ǉ�
           ,cn_lot_control_code_no
-- Ver1.7  2009/04/03 Add End
-- Ver1.10 2009/07/15 Add  �ۊǒI�Ǘ�(LOCATION_CONTROL_CODE)�ǉ�
-- 2009/12/24 Ver1.14 ��QE_�{�ғ�_00577 add start by Shigeto.Niki
--           ,cn_location_control_code_no
           ,ln_location_control_code
-- 2009/12/24 Ver1.14 ��QE_�{�ғ�_00577 end start by Shigeto.Niki
-- End1.10
           ,cn_process_flag
           ,lv_transaction_type );
           --
        EXCEPTION
          WHEN OTHERS THEN
            lv_msg_errm  := SQLERRM;
            lv_msg_token := cv_tkn_val_discitem_if;
            RAISE data_insert_err_expt;  -- �o�^�G���[
        END;
      END IF;
      --
-- Ver1.9  2009/07/06  Add  ��Q�Ή�(0000364)
      -- �e�i�ڂ����o�^�`�c'�ɕύX���A�R���|�[�l���g�敪�̕s������o�^
        -- �{�o�^�`�c'�ɕύX����ꍇ�A�S�R���|�[�l���g���o�^����Ă���K�v������A
        -- �܂��A�W�������v > 0�~ �ł���K�v������B
      IF  ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id )
      AND ( i_update_item_rec.item_status >= cn_itm_status_pre_reg )
      AND ( i_update_item_rec.item_status <= cn_itm_status_trn_only ) THEN
        -- �����w�b�_(�J�����_�R�[�h�A���ԃR�[�h)�̎擾
        --  ���J�[�\���ɂ��Ă��邪�A�Ώۂ͂P���̂�
        lv_step := 'STEP-6210';
        <<cnp_cost_hd_par_loop>>
        FOR l_cnp_cost_hd_par_rec IN cnp_cost_hd_par_cur( i_update_item_rec.apply_date ) LOOP
          -----------------
          -- �����w�b�_
          -----------------
          lv_step := 'STEP-6220';
          -- �J�����_�R�[�h
          l_opm_cost_header_rec.calendar_code     := l_cnp_cost_hd_par_rec.calendar_code;
          -- ���ԃR�[�h
          l_opm_cost_header_rec.period_code       := l_cnp_cost_hd_par_rec.period_code;
          -- �i��ID
          l_opm_cost_header_rec.item_id           := i_update_item_rec.item_id;
          --
          -- �J�����_�A���Ԗ��Ɍ��������擾
          lv_step := 'STEP-6230';
          ln_cmp_cost_index := 0;
          --
          <<cnp_noext_cost_dt_loop>>
          FOR l_cnp_noext_cost_dt_rec IN cnp_noext_cost_dt_cur( i_update_item_rec.item_id
                                                               ,l_cnp_cost_hd_par_rec.calendar_code
                                                               ,l_cnp_cost_hd_par_rec.period_code ) LOOP
            -----------------
            -- ��������
            -----------------
            lv_step := 'STEP-6240';
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            --
            -- �����R���|�[�l���gID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_cnp_noext_cost_dt_rec.cost_cmpntcls_id;
            -- ����
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := 0;
          --
          END LOOP cnp_noext_cost_dt_loop;
          --
          --==============================================================
          -- �W�������o�^�i���o�^�R���|�[�l���g�̂O�~�ݒ�j
          --==============================================================
          lv_step := 'STEP-6250';
          xxcmm_004common_pkg.proc_opmcost_ref(
            i_cost_header_rec  =>  l_opm_cost_header_rec  -- �����w�b�_���R�[�h�^�C�v
           ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- �������׃e�[�u���^�C�v
           ,ov_errbuf          =>  lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode         =>  lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg          =>  lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            --
            lv_msg_token := cv_tkn_val_opmcost;
            lv_msg_errm  := lv_errmsg;
            RAISE data_insert_err_expt;
          END IF;
          --
        END LOOP cnp_cost_hd_par_loop;
      END IF;
-- End1.9
      --
-- 2009/09/11 Ver1.12 ��Q0000948 add start by Y.Kuboshima
      -- �P�ʊ��Z�����^�C�~���O��i�ڃX�e�[�^�X�ύX���ɕύX
      -- �P�ʊ��Z�쐬�t���O�擾
      OPEN units_of_measure_cur(i_update_item_rec.item_um);
      FETCH units_of_measure_cur INTO l_units_of_measure_rec;
      CLOSE units_of_measure_cur;
      -- �敪�Ԋ��Z�o�^����
      -- �P�ʊ��Z�쐬�t���O��'Y'�̏ꍇ���A�i�ڃX�e�[�^�X��'30'(�{�o�^)�̏ꍇ�A�P�ʊ��Z���쐬����
      IF  ( l_units_of_measure_rec.attribute1 = cv_yes ) 
        AND ( i_update_item_rec.item_status = cn_itm_status_regist)
      THEN
        --==============================================================
        --A-5.6 �敪�Ԋ��Z�̓o�^
        --==============================================================
        lv_step := 'STEP-05060';
        l_uom_class_conv_rec.inventory_item_id := i_update_item_rec.inventory_item_id;
        l_uom_class_conv_rec.from_uom_code     := i_update_item_rec.item_um;
        l_uom_class_conv_rec.to_uom_code       := cv_uom_class_conv_to;                   -- CS
        l_uom_class_conv_rec.conversion_rate   := i_update_item_rec.num_of_cases;
        --
        -- �敪�Ԋ��Z�o�^API
        lv_step := 'STEP-04030';
        xxcmm_004common_pkg.proc_uom_class_ref(
          i_uom_class_conv_rec  =>  l_uom_class_conv_rec  -- �敪�Ԋ��Z���f�p���R�[�h�^�C�v
         ,ov_errbuf             =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode            =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg             =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          --
          lv_msg_token := cv_tkn_val_uon_conv;
          RAISE data_insert_err_expt;
        END IF;
      END IF;
-- 2009/09/11 Ver1.12 ��Q0000948 add end by Y.Kuboshima
      --
    END IF;
    --
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^���o��O�n���h�� ***
    WHEN data_select_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00442            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_data_info              -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                    );
      ov_errmsg  := lv_errmsg;
      lv_errbuf  := lv_errmsg || cv_msg_space|| SQLERRM;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�o�^��O�n���h�� ***
    WHEN data_insert_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00444            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_msg_errm                   -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN data_update_err_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00445            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_msg_errm                   -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END proc_item_status_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_status_update
   * Description      : �i�ڃX�e�[�^�X�ύX
   **********************************************************************************/
  PROCEDURE proc_status_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_STATUS_UPDATE'; -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    sub_proc_expt                EXCEPTION;
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
    --A-5 �i�ڃX�e�[�^�X��񔽉f
    --==============================================================
    lv_step := 'STEP-05010';
    proc_item_status_update(
      i_update_item_rec   =>  i_update_item_rec     -- �i�ڃX�e�[�^�X���f���R�[�h
     ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-6 �e�i�ڏ��̌p��
    --==============================================================
    lv_step := 'STEP-05020';
    proc_inherit_parent(
      i_update_item_rec   =>  i_update_item_rec     -- �i�ڃX�e�[�^�X���f���R�[�h
     ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END proc_status_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_first_update
   * Description      : ����o�^�f�[�^����(A-4)
   **********************************************************************************/
  PROCEDURE proc_first_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_FIRST_UPDATE'; -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
-- 2009/09/11 Ver1.12 ��Q0000948 delete start by Y.Kuboshima
--    cv_uom_class_conv_from       CONSTANT VARCHAR2(10) := 'kg';
--    cv_uom_class_conv_to         CONSTANT VARCHAR2(10) := 'CS';
-- 2009/09/11 Ver1.12 ��Q0000948 delete end by Y.Kuboshima
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    ln_exsits_count              NUMBER;
    --
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �i�ڃJ�e�S���������o�J�[�\��(�{�А��i�敪�A���i���i�敪�A����Q)
    --                              �Q�R�[�h�A�o�����敪�A�}�[�P�p�Q�R�[�h 2009/06/11�ǉ�
    CURSOR opm_item_categ_cur(
      pn_item_id    NUMBER )
    IS
      SELECT      gic.item_id                  -- �i��ID
                 ,gic.category_set_id          -- �J�e�S���Z�b�gID
                 ,gic.category_id              -- �J�e�S��ID
      FROM        gmi_item_categories  gic     -- OPM�i�ڃJ�e�S������
                 ,mtl_category_sets    mcs     -- �J�e�S���Z�b�g
      WHERE       gic.item_id  = pn_item_id    -- �i��ID
-- Ver1.8  2009/06/11  Add  �Q�R�[�h�A�o�����敪�A�}�[�P�p�Q�R�[�h��ǉ�
--      AND         mcs.category_set_name IN ( cv_categ_set_seisakugun       -- ����Q�R�[�h
--                                            ,cv_categ_set_item_prod        -- ���i���i�敪
--                                            ,cv_categ_set_hon_prod )       -- �{�Џ��i�敪
      AND         mcs.category_set_name IN ( cv_categ_set_seisakugun       -- ����Q�R�[�h
                                            ,cv_categ_set_gun_code         -- �Q�R�[�h
                                            ,cv_categ_set_item_prod        -- ���i���i�敪
                                            ,cv_categ_set_hon_prod         -- �{�Џ��i�敪
                                            ,cv_categ_set_baracha_div      -- �o�����敪
                                            ,cv_categ_set_mark_pg          -- �}�[�P�p�Q�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001258 add start by Y.Kuboshima
                                            ,cv_categ_set_item_div         -- �i�ڋ敪
                                            ,cv_categ_set_inout_div        -- ���O�敪
                                            ,cv_categ_set_product_div      -- ���i�敪
                                            ,cv_categ_set_quality_div      -- �i���敪
                                            ,cv_categ_set_fact_pg          -- �H��Q�R�[�h
                                            ,cv_categ_set_acnt_pg )        -- �o�����p�Q�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001258 add end by Y.Kuboshima
--
-- End1.8
      AND         gic.category_set_id = mcs.category_set_id;
    --
    -- �i�ڃJ�e�S���������o�J�[�\��(�{�А��i�敪�A���i���i�敪)
    --                              �o�����敪�A�}�[�P�p�Q�R�[�h 2009/06/11�ǉ�
    CURSOR opm_item_categ_cur2(
      pn_item_id    NUMBER )
    IS
      SELECT      gic.item_id                  -- �i��ID
                 ,gic.category_set_id          -- �J�e�S���Z�b�gID
                 ,gic.category_id              -- �J�e�S��ID
      FROM        gmi_item_categories  gic     -- OPM�i�ڃJ�e�S������
                 ,mtl_category_sets    mcs     -- �J�e�S���Z�b�g
      WHERE       gic.item_id  = pn_item_id    -- �i��ID
-- Ver1.8  2009/06/11  Add  �o�����敪�A�}�[�P�p�Q�R�[�h��ǉ�
--      AND         mcs.category_set_name IN ( cv_categ_set_item_prod        -- ���i���i�敪
--                                            ,cv_categ_set_hon_prod )       -- �{�Џ��i�敪
      AND         mcs.category_set_name IN ( cv_categ_set_item_prod        -- ���i���i�敪
                                            ,cv_categ_set_hon_prod         -- �{�Џ��i�敪
                                            ,cv_categ_set_baracha_div      -- �o�����敪
                                            ,cv_categ_set_mark_pg          -- �}�[�P�p�Q�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001258 add start by Y.Kuboshima
                                            ,cv_categ_set_item_div         -- �i�ڋ敪
                                            ,cv_categ_set_inout_div        -- ���O�敪
                                            ,cv_categ_set_product_div      -- ���i�敪
                                            ,cv_categ_set_quality_div      -- �i���敪
                                            ,cv_categ_set_fact_pg          -- �H��Q�R�[�h
                                            ,cv_categ_set_acnt_pg )        -- �o�����p�Q�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001258 add end by Y.Kuboshima
--
-- End1.8
      AND         gic.category_set_id = mcs.category_set_id;
    --
    -- ���R�[�h�^
-- 2009/09/11 Ver1.12 ��Q0000948 delete start by Y.Kuboshima
--    -- �P�ʊ��Z�p
--    l_uom_class_conv_rec         xxcmm_004common_pkg.uom_class_conv_rtype;
-- 2009/09/11 Ver1.12 ��Q0000948 delete end by Y.Kuboshima
    -- Disc�i�ڃJ�e�S���p
    l_discitem_category_rec      xxcmm_004common_pkg.discitem_category_rtype;
    -- �i�ڃJ�e�S���������o�J�[�\���̃��R�[�h�^�C�v
    l_opm_item_categ_rec         opm_item_categ_cur%ROWTYPE;
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    item_common_ins_expt         EXCEPTION;    -- �f�[�^�o�^�G���[(�i�ڋ���API)
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
    --==============================================================
    --A-4 ����o�^�f�[�^����
    --==============================================================
    lv_step := 'STEP-04010';
-- 2009/09/11 Ver1.12 ��Q0000948 delete start by Y.Kuboshima
-- ���P�ʊ��Z�����^�C�~���O��i�ڃX�e�[�^�X�ύX���ɍs��
--
--    -- �敪�Ԋ��Z�o�^����
---- ��P�ʂ��u�{�v�̏ꍇ�A�P�ʊ��Z���s��
--    IF  ( i_update_item_rec.item_um = cv_uom_class_conv_from )
--    AND ( NVL( i_update_item_rec.num_of_cases, 0 ) > 0 ) THEN
--      --==============================================================
--      --A-4.1 �敪�Ԋ��Z�̓o�^
--      --==============================================================
--      lv_step := 'STEP-04020';
--      l_uom_class_conv_rec.inventory_item_id := i_update_item_rec.inventory_item_id;
--      l_uom_class_conv_rec.from_uom_code     := i_update_item_rec.item_um;
--      l_uom_class_conv_rec.to_uom_code       := cv_uom_class_conv_to;                   -- CS
--      l_uom_class_conv_rec.conversion_rate   := i_update_item_rec.num_of_cases;
--      --
--      -- �敪�Ԋ��Z�o�^API
--      lv_step := 'STEP-04030';
--      xxcmm_004common_pkg.proc_uom_class_ref(
--        i_uom_class_conv_rec  =>  l_uom_class_conv_rec  -- �敪�Ԋ��Z���f�p���R�[�h�^�C�v
--       ,ov_errbuf             =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
--       ,ov_retcode            =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
--       ,ov_errmsg             =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      --
--      IF ( lv_retcode = cv_status_error ) THEN
--        --
--        lv_msg_token := cv_tkn_val_uon_conv;
--        RAISE item_common_ins_expt;
--      END IF;
--    END IF;
-- 2009/09/11 Ver1.12 ��Q0000948 delete end by Y.Kuboshima
    --
    --==============================================================
    --A-4.3 �n�o�l�i�ڃJ�e�S���������擾
    --==============================================================
    -------------------------
    -- �e�i�ڂ̐���Q�ύX�m�F
    -------------------------
    IF ( i_update_item_rec.item_id = i_update_item_rec.parent_item_id ) THEN
      -- �e�i�ڂ̏ꍇ�A����Q�͕ύX�\�񂳂��̂ŏ������Ȃ�
      ln_exsits_count := 1;
    ELSE
      -- �q�i�ڂ̏ꍇ
      lv_step := 'STEP-04040';
      --==============================================================
      --A-4.2 �e�i�ڂ̐���Q�ύX�K�p���݃`�F�b�N
      --==============================================================
      SELECT      COUNT( xsibh.ROWID )
      INTO        ln_exsits_count
      FROM        xxcmm_system_items_b_hst  xsibh                              -- Disc�i�ڕύX�����A�h�I��
                 ,xxcmm_opmmtl_items_v      xoiv                               -- �i�ڃr���[
      WHERE       xoiv.item_id            = i_update_item_rec.parent_item_id   -- �e�i��ID
-- 2009/08/10 Ver1.11 ��Q0000894 modify start by Y.Kuboshima
--      AND         xoiv.start_date_active <= TRUNC( SYSDATE )                   -- �K�p�J�n��
--      AND         xoiv.end_date_active   >= TRUNC( SYSDATE )                   -- �K�p�I����
      AND         xoiv.start_date_active <= gd_process_date                    -- �K�p�J�n��
      AND         xoiv.end_date_active   >= gd_process_date                    -- �K�p�I����
-- 2009/08/10 Ver1.11 ��Q0000894 modify end by Y.Kuboshima
      AND         xsibh.item_code         = xoiv.item_no                       -- �i�ڃR�[�h
      AND         xsibh.apply_date       <= gd_apply_date                      -- �K�p��
-- Ver1.1 2009/01/16 MOD �e�X�g�V�i���I 4-5
--      AND         xsibh.apply_flag        = cv_no                              -- ���K�p
      AND         xsibh.request_id        = cn_request_id                      -- �����ύX�K�p�ł��邱��
-- End
      AND         xsibh.policy_group     IS NOT NULL                           -- ����Q
      AND         ROWNUM = 1;
      --
    END IF;
   --
    --==============================================================
    --A-4.3 �n�o�l�i�ڃJ�e�S���������擾
    --==============================================================
    IF ( ln_exsits_count = 0 ) THEN
      -- ����Q����J�[�\��
      lv_step := 'STEP-04050';
      OPEN opm_item_categ_cur( i_update_item_rec.item_id );
    ELSE
      -- ����Q�Ȃ��J�[�\��
      lv_step := 'STEP-04060';
      OPEN opm_item_categ_cur2( i_update_item_rec.item_id );
    END IF;
    --
    -- �i�ڃJ�e�S������(Disc)�o�^
    <<disc_categ_loop>>
    LOOP
      --
      IF ( ln_exsits_count = 0 ) THEN
        -- �t�F�b�`
        lv_step := 'STEP-04070';
        FETCH opm_item_categ_cur INTO l_opm_item_categ_rec;
        -- 
        IF (opm_item_categ_cur%NOTFOUND) THEN
          CLOSE opm_item_categ_cur;
          EXIT;
        END IF;
      ELSE
        -- �t�F�b�`
        lv_step := 'STEP-04080';
        FETCH opm_item_categ_cur2 INTO l_opm_item_categ_rec;
        --
        IF (opm_item_categ_cur2%NOTFOUND) THEN
          CLOSE opm_item_categ_cur2;
          EXIT;
        END IF;
      END IF;
      --
      lv_step := 'STEP-04090';
      l_discitem_category_rec.inventory_item_id := i_update_item_rec.inventory_item_id;    -- Disc�i��ID
      l_discitem_category_rec.category_set_id   := l_opm_item_categ_rec.category_set_id;   -- �J�e�S���Z�b�gID
      l_discitem_category_rec.category_id       := l_opm_item_categ_rec.category_id;       -- �J�e�S��ID
      --
      --==============================================================
      --A-4.4 �i�ڃJ�e�S�������̓o�^
      --==============================================================
      lv_step := 'STEP-04100';
      -- �i�ڃJ�e�S������(Disc)�o�^API
      xxcmm_004common_pkg.proc_discitem_categ_ref(
        i_item_category_rec  =>  l_discitem_category_rec    -- �i�ڃJ�e�S���������R�[�h�^�C�v
       ,ov_errbuf            =>  lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode           =>  lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg            =>  lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        IF ( ln_exsits_count = 0 ) THEN
          CLOSE opm_item_categ_cur;
        ELSE
          CLOSE opm_item_categ_cur2;
        END IF;
        --
        lv_msg_token := cv_tkn_val_mtl_item_categ;
        RAISE item_common_ins_expt;
      END IF;
      --
    END LOOP disc_categ_loop;
    --
  EXCEPTION
--
    -- *** �f�[�^�o�^�G���[(�i�ڋ���API)��O�n���h�� ***
    WHEN item_common_ins_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00444            -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token                  -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_item_code              -- �g�[�N���R�[�h2
                     ,iv_token_value2 => i_update_item_rec.item_no     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_err_msg                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => lv_errmsg                     -- �g�[�N���l3
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  --
  END proc_first_update;
--
  /**********************************************************************************
   * Procedure Name   : proc_apply_update
   * Description      : �i�ڕύX�K�p����
   **********************************************************************************/
  PROCEDURE proc_apply_update(
    i_update_item_rec     IN     update_item_cur%ROWTYPE
   ,ov_errbuf             OUT    VARCHAR2         --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2         --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_APPLY_UPDATE'; -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    sub_proc_expt                EXCEPTION;
    --
-- Ver1.7 2009/05/27 Add  ���݃X�e�[�^�X���u�c�v���̃`�F�b�N��ǉ�
    item_no_use_expt           EXCEPTION;    -- ���݂̕i�ڃX�e�[�^�X�u�c�v���̃`�F�b�N�G���[
-- End
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
    --�i�ڕύX�K�p����
    --==============================================================
    -- ����i�ړK�p����
    IF ( i_update_item_rec.first_apply_flag = cv_yes ) THEN
      --==============================================================
      --A-4 ����o�^�f�[�^����
      --==============================================================
      lv_step := 'STEP-03010';
      proc_first_update(
        i_update_item_rec   =>  i_update_item_rec     -- 
       ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg           =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        RAISE sub_proc_expt;
      END IF;
      --
    END IF;
    --
    ------------------------
    -- �i�ڃX�e�[�^�X���f
    ------------------------
    IF ( i_update_item_rec.item_status IS NOT NULL ) THEN
      --==============================================================
      --�i�ڃX�e�[�^�X�ύX
      --  A-5 �i�ڃX�e�[�^�X��񔽉f�i�i�ڃX�e�[�^�X�ύX�ɂ��X�V�j
      --  A-6 �e�i�ڏ��̌p��      �i�i�ڃX�e�[�^�X�ύX�ɔ����X�V�j
      --==============================================================
      lv_step := 'STEP-03020';
      proc_status_update(
        i_update_item_rec   =>  i_update_item_rec     -- �i�ڃX�e�[�^�X���f���R�[�h
       ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg           =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        --
        RAISE sub_proc_expt;
      END IF;
      --
-- Ver1.7 2009/05/27 Add  ���݃X�e�[�^�X���u�c�v�̏ꍇ�A�i�ڃX�e�[�^�X�ȊO�̕ύX�͕s��
    ELSE
      lv_step := 'STEP-3025';
      IF  ( i_update_item_rec.b_item_status = cn_itm_status_no_use ) THEN
        RAISE item_no_use_expt;
      END IF;
-- End
    --
    END IF;
    --
    --==============================================================
    --�e�i�ڂ̕ύX
    --  A-7 �e�i�ڕύX���̍X�V�A�q�i�ڂւ̌p��
    --==============================================================
    lv_step := 'STEP-03030';
    proc_parent_item_update(
      i_update_item_rec   =>  i_update_item_rec     -- �i�ڃX�e�[�^�X���f���R�[�h
     ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-8 Disc�i�ڃA�h�I���̍X�V
    --A-9 Disc�i�ڕύX�����A�h�I���̍X�V
    --==============================================================
    lv_step := 'STEP-03040';
    proc_comp_apply_update(
      i_update_item_rec   =>  i_update_item_rec     -- �i�ڃX�e�[�^�X���f���R�[�h
     ,ov_errbuf           =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode          =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg           =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- �X�V�����̃C���N�������g
    --==============================================================
    lv_step := 'STEP-03050';
    IF ( i_update_item_rec.item_status  IS NOT NULL ) THEN
      -- �X�e�[�^�X�X�V����
      gn_item_status_cnt := gn_item_status_cnt + 1;
    END IF;
    --
    lv_step := 'STEP-03060';
    IF ( i_update_item_rec.policy_group  IS NOT NULL ) THEN
      -- ����Q�X�V����
      gn_policy_group_cnt := gn_policy_group_cnt + 1;
    END IF;
    --
    lv_step := 'STEP-03070';
    IF ( i_update_item_rec.fixed_price   IS NOT NULL ) THEN
      -- �艿�X�V����
      gn_fixed_price_cnt := gn_fixed_price_cnt + 1;
    END IF;
    --
    lv_step := 'STEP-03080';
    IF ( i_update_item_rec.discrete_cost IS NOT NULL ) THEN
      -- �c�ƌ����X�V����
      gn_discrete_cost_cnt := gn_discrete_cost_cnt + 1;
    END IF;
    --
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --
-- Ver1.7 2009/05/27 Add  ���݃X�e�[�^�X���u�c�v�̏ꍇ�A�i�ڃX�e�[�^�X�ȊO�̕ύX�͕s��
    -- *** ���݂̕i�ڃX�e�[�^�X�`�F�b�N��O�n���h�� ***
    WHEN item_no_use_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00430                    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item_code                      -- �g�[�N���R�[�h1
                     ,iv_token_value1 => i_update_item_rec.item_no             -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
-- End
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END proc_apply_update;
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �i�ڕύX�K�p���[�v
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf             OUT    VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode            OUT    VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg             OUT    VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'LOOP_MAIN';          -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
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
    --A-3.�ύX�K�p�i�ڏ��̎擾
    --==============================================================
    lv_step := 'STEP-02010';
    <<apply_item_loop>>
    FOR l_update_item_rec IN update_item_cur( gd_apply_date ) LOOP
      --
      -- �i�ڕύX�K�p�P��������
      -- �q�i�ڂ���������ꍇ�A�ύX�K�p�����[���o�b�N���邽��
      lv_step := 'STEP-02020';
      SAVEPOINT hst_record_savepoint;
      --
      lv_step := 'STEP-02030';
      gn_target_cnt  := gn_target_cnt + 1;
      gv_inherit_kbn := cv_inherit_kbn_hst;          -- �e�l�p�����敪�y'0'�F�������ɂ��X�V�z
      -- 
      --==============================================================
      --�i�ڕύX�K�p����
      --  A-4 ����o�^�f�[�^����
      --  A-5 �i�ڃX�e�[�^�X��񔽉f
      --  A-6 �e�i�ڏ��̌p��
      --  A-7 �e�i�ڕύX���̌p��
      --  A-8 Disc�i�ڃA�h�I���̍X�V
      --  A-9 Disc�i�ڕύX�����A�h�I���̍X�V
      --==============================================================
      lv_step := 'STEP-02040';
      proc_apply_update(
        i_update_item_rec  =>  l_update_item_rec    -- �i�ڕύX�K�p���
       ,ov_errbuf          =>  lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         =>  lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          =>  lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_normal ) THEN
        -- �ύX�K�p�P�f�[�^���R�~�b�g
        lv_step := 'STEP-02050';
        COMMIT;
        --
        gn_normal_cnt := gn_normal_cnt + 1;    -- ���팏��
        --
      ELSE
        --
        lv_step := 'STEP-02060';
        ROLLBACK TO hst_record_savepoint;
        --
        gn_error_cnt  := gn_error_cnt  + 1;    -- �G���[����
        gn_warn_cnt   := gn_warn_cnt   + 1;    -- �X�L�b�v����
        --
        lv_step := 'STEP-02070';
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf
        );
        --
      END IF;
      --
    END LOOP apply_item_loop;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END loop_main;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : �������� (A-2)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_boot_flag          IN     VARCHAR2                                        -- ���̓p�����[�^.�N�����
   ,ov_errbuf             OUT    VARCHAR2                                        -- �G���[�E���b�Z�[�W
   ,ov_retcode            OUT    VARCHAR2                                        -- ���^�[���E�R�[�h
   ,ov_errmsg             OUT    VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'PROC_INIT';          -- �v���O������
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_param_boot_flag           CONSTANT VARCHAR2(10) := '�N�����';            -- �p�����[�^��
    cv_process_date              CONSTANT VARCHAR2(10) := '�Ɩ����t';            -- �Ɩ����t�擾���s��
    cv_process_date_next         CONSTANT VARCHAR2(10) := '���c�Ɠ�';            -- ���c�Ɠ��擾���s��
    cv_organization_info         CONSTANT VARCHAR2(20) := '�c�Ƒg�D���';        -- �c�Ƒg�D��񎸔s��
    --
-- 2009/09/11 Ver1.12 ��Q0001130 delete start by Y.Kuboshima
--    cv_bus_org_code              CONSTANT VARCHAR2(3)  := 'S01';                 -- �c�Ƒg�D �g�D�R�[�h
-- 2009/09/11 Ver1.12 ��Q0001130 delete end by Y.Kuboshima
    cv_bom_calendar_name         CONSTANT VARCHAR2(30) := '�V�X�e���ғ����J�����_';
--    cv_bom_calendar_name         CONSTANT VARCHAR2(30) := '�ɓ����ғ����J�����_';  -- ���������������H
                                                                                 -- �ғ����J�����_����
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_step                      VARCHAR2(10);
    lv_msg_token                 VARCHAR2(100);
    --
-- Ver1.5 2009/02/20 Del �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--    ld_process_date              DATE;                                           -- �Ɩ����t
--
    ld_apply_date                DATE;                                           -- ������
    --
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    get_param_expt               EXCEPTION;
    get_info_err_expt            EXCEPTION;                                      -- �f�[�^���o�G���[(�f�[�^����g�[�N���Ȃ�)
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
    get_profile_expt             EXCEPTION;                                      -- �v���t�@�C���擾�G���[
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
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
    --A-1.1 �p�����[�^�`�F�b�N
    --==============================================================
    lv_step := 'STEP-01010';
    IF ( iv_boot_flag IS NULL ) THEN
      lv_msg_token := cv_param_boot_flag;
      RAISE get_param_expt;
    END IF;
    --
    lv_step := 'STEP-01020';
    gv_boot_flag  :=  iv_boot_flag;            -- IN�p�����[�^���i�[
    --
    lv_step := 'STEP-01030';
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_param_boot_flag || cv_msg_part || gv_boot_flag
    );
    --
    --==============================================================
    --A-2 ��������
    --==============================================================
    --==============================================================
    --A-2.1 �Ɩ����t�̎擾
    --==============================================================
    lv_step := 'STEP-01040';
    -- �Ɩ����t�̎擾
-- Ver1.5 2009/02/20 Mod �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--    ld_process_date := xxccp_common_pkg2.get_process_date;
--    --
--    -- �擾�G���[��
--    IF ( ld_process_date IS NULL ) THEN
--
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- �擾�G���[��
    IF ( gd_process_date IS NULL ) THEN
-- End
      lv_msg_token := cv_process_date;
      RAISE get_info_err_expt;       -- �擾�G���[
    END IF;
    --
    --==============================================================
    --A-2.2 ���c�Ɠ��t�̎擾
    --==============================================================
    lv_step := 'STEP-01050';
    -- �p�����[�^.�N����ʂ���Ԃ̏ꍇ�A���c�Ɠ����擾
    IF ( gv_boot_flag = cv_boot_flag_online ) THEN
      lv_step := 'STEP-01060';
      -- �I�����C�����F�Ɩ����t���������ɐݒ�
-- Ver1.5 2009/02/20 Mod �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--      ld_apply_date := ld_process_date;
      ld_apply_date := gd_process_date;
-- End
    ELSE
      lv_step := 'STEP-01070';
      BEGIN
        -- ��ԃo�b�`���F���c�Ɠ����������ɐݒ�
        SELECT      MIN( bcd.calendar_date )    AS next_bus_date
        INTO        ld_apply_date
        FROM        bom_calendar_dates     bcd
                   ,bom_calendars          bc
        WHERE       bc.description    = cv_bom_calendar_name
        AND         bcd.calendar_code = bc.calendar_code
-- Ver1.5 2009/02/20 Mod �����ΏۍX�V���ɋƖ����t��ݒ肷��悤�C��
--        AND         bcd.calendar_date > ld_process_date
        AND         bcd.calendar_date > gd_process_date
-- End
        AND         bcd.calendar_date = bcd.next_date;
      EXCEPTION
        WHEN OTHERS THEN
          --���c�Ɠ�
          lv_msg_token := cv_process_date_next;
          RAISE get_info_err_expt;  -- �擾�G���[
      END;
    END IF;
    --
-- Ver1.1 2009/01/13 ADD �e�X�g�V�i���I 2-6
    -- �擾�G���[��
    IF ( ld_apply_date IS NULL ) THEN
      lv_msg_token := cv_process_date_next;
      RAISE get_info_err_expt;      -- �擾�G���[
    END IF;
-- Ver1.1 ADD END
    --
    lv_step := 'STEP-01080';
    gd_apply_date := ld_apply_date;
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
    --
    --==============================================================
    --A-2.3 �v���t�@�C���̎擾
    --==============================================================
    lv_step := 'STEP-1090';
    -- �݌ɑg�D�R�[�h�̎擾
    gv_bus_org_code := fnd_profile.value(cv_pro_org_code);
    IF (gv_bus_org_code IS NULL) THEN
      lv_msg_token := cv_tkn_val_org_code;
      RAISE get_profile_expt;
    END IF;
    --
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
    --
    --==============================================================
    --A-2.4 �c�Ƒg�D���̎擾
    --==============================================================
    lv_step := 'STEP-01100';
    BEGIN
      -- �c�Ƒg�DID,�����g�DID,�}�X�^�[�݌ɑg�DID�̎擾
      SELECT      mp.organization_id           -- �c�Ƒg�DID
                 ,mp.cost_organization_id      -- �����g�DID
                 ,mp.master_organization_id    -- �}�X�^�[�݌ɑg�DID
      INTO        gn_bus_org_id
                 ,gn_cost_org_id
                 ,gn_master_org_id
      FROM        mtl_parameters    mp
-- 2009/09/11 Ver1.12 ��Q0001130 modify start by Y.Kuboshima
--      WHERE       mp.organization_code = cv_bus_org_code;
      WHERE       mp.organization_code = gv_bus_org_code;
-- 2009/09/11 Ver1.12 ��Q0001130 modify end by Y.Kuboshima
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg_token := cv_organization_info;
        RAISE get_info_err_expt;  -- �擾�G���[
    END;
    --
  EXCEPTION
--
    -- *** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN get_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcmm_00440    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_param_name     -- �g�[�N���R�[�h1
                     ,iv_token_value1 => lv_msg_token          -- �g�[�N���l1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** �f�[�^���o�G���[�n���h���i�f�[�^����g�[�N���Ȃ��j ***
    WHEN get_info_err_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_name_xxcmm    -- ���W���[��������:XXCMN
                                                      ,cv_msg_xxcmm_00441    -- ���b�Z�[�W:APP-XXCMM1-00441
                                                      ,cv_tkn_data_info      -- �g�[�N���R�[�h1
                                                      ,lv_msg_token )        -- �g�[�N���l1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
-- 2009/09/11 Ver1.12 ��Q0001130 add start by Y.Kuboshima
    -- *** �v���t�@�C���擾�G���[�n���h�� ***
    WHEN get_profile_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB( xxcmn_common_pkg.get_msg( cv_appl_name_xxcmm    -- ���W���[��������:XXCMN
                                                      ,cv_msg_xxcmm_00002    -- ���b�Z�[�W:APP-XXCMM1-00002
                                                      ,cv_tkn_ng_profile     -- �g�[�N���R�[�h1
                                                      ,lv_msg_token )        -- �g�[�N���l1
                            ,1, 5000 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
-- 2009/09/11 Ver1.12 ��Q0001130 add end by Y.Kuboshima
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
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
    iv_boot_flag          IN     VARCHAR2                                        -- �N����ʁy1:�I�����C���A2�F��ԁz
   ,ov_errbuf             OUT    VARCHAR2                                        -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT    VARCHAR2                                        -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT    VARCHAR2                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'SUBMAIN';            -- �v���O������
    --
    -- ===============================
    -- �Œ胍�[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    lv_step                      VARCHAR2(10);
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    sub_proc_expt                EXCEPTION;
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
    gn_item_status_cnt   := 0;           -- �X�e�[�^�X�X�V����
    gn_policy_group_cnt  := 0;           -- ����Q�X�V����  �i�ύX�����x�[�X�j
    gn_fixed_price_cnt   := 0;           -- �艿�X�V����    �i�ύX�����x�[�X�j
    gn_discrete_cost_cnt := 0;           -- �c�ƌ����X�V�����i�ύX�����x�[�X�j
    --
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    --A-1 �p�����[�^�`�F�b�N
    --A-2 ��������
    --==============================================================
    lv_step := 'STEP-00010';
    proc_init(
      iv_boot_flag  =>  iv_boot_flag    -- �N����ʁy1:�I�����C���A2�F��ԁz
     ,ov_errbuf     =>  lv_errbuf       -- �G���[�E���b�Z�[�W
     ,ov_retcode    =>  lv_retcode      -- ���^�[���E�R�[�h
     ,ov_errmsg     =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �߂�l���ُ�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --�i�ڕύX�K�p���[�v
    --  A-3 �ύX�K�p�i�ڏ��̎擾
    --  A-4 ����o�^�f�[�^����
    --  A-5 �i�ڃX�e�[�^�X��񔽉f
    --  A-6 �e�i�ڏ��̌p��
    --  A-7 �e�i�ڕύX���̌p��
    --  A-8 Disc�i�ڃA�h�I���̍X�V
    --  A-9 Disc�i�ڕύX�����A�h�I���̍X�V
    --==============================================================
    lv_step := 'STEP-00020';
    loop_main(
      ov_errbuf   =>  lv_errbuf     -- �G���[�E���b�Z�[�W
     ,ov_retcode  =>  lv_retcode    -- ���^�[���E�R�[�h
     ,ov_errmsg   =>  lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �߂�l���ُ�̏ꍇ
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    -- �G���[�f�[�^���ݎ��͌x���I��
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
    --
    --
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
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
    errbuf                OUT    VARCHAR2                                        --   �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT    VARCHAR2                                        --   �G���[�R�[�h     #�Œ�#
   ,iv_boot_flag          IN     VARCHAR2                                        --   �N����ʁy1:�I�����C���A2�F��ԁz
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100) := 'MAIN';               -- �v���O������
    --
    cv_appl_name_xxccp           CONSTANT VARCHAR2(10)  := 'XXCCP';              -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- �Ώی������b�Z�[�W
    cv_success_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- �����������b�Z�[�W
    cv_error_rec_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- �G���[�������b�Z�[�W
    cv_skip_rec_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';   -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token                 CONSTANT VARCHAR2(10)  := 'COUNT';              -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- ����I�����b�Z�[�W
    cv_warn_msg                  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- �x���I�����b�Z�[�W
    cv_error_msg                 CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';   -- �G���[�I���S���[���o�b�N
    --
    cv_log                       CONSTANT VARCHAR2(100) := 'LOG';                -- ���O
    cv_output                    CONSTANT VARCHAR2(100) := 'OUTPUT';             -- �A�E�g�v�b�g
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                    VARCHAR2(5000);                                 -- �G���[�E���b�Z�[�W
    lv_retcode                   VARCHAR2(1);                                    -- ���^�[���E�R�[�h
    lv_errmsg                    VARCHAR2(5000);                                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code              VARCHAR2(100);                                  -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
    --
    ----------------------------------
    -- ���O�w�b�_�o��
    ----------------------------------
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  �Œ蕔 END   #############################
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_boot_flag  =>  iv_boot_flag          -- 1.�N����ʁy1:�I�����C���A2�F��ԁz
     ,ov_errbuf     =>  lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    =>  lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     =>  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = cv_status_error ) THEN
      -- �o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                -- ���[�U�[�E�G���[���b�Z�[�W
      );
      -- ���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                -- �G���[���b�Z�[�W
      );
    END IF;
    --
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    ----------------------------------
    -- ���O�t�b�^�o��
    ----------------------------------
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_tkn_val_target_cnt             -- �g�[�N���l1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- �g�[�N���R�[�h2
                   ,iv_token_value2  =>  TO_CHAR( gn_target_cnt )          -- �g�[�N���l2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- �i�ڃX�e�[�^�X�ύX�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_tkn_val_item_status_cnt        -- �g�[�N���l1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- �g�[�N���R�[�h2
                   ,iv_token_value2  =>  TO_CHAR( gn_item_status_cnt )     -- �g�[�N���l2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- ����Q�ύX�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_tkn_val_policy_group_cnt       -- �g�[�N���l1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- �g�[�N���R�[�h2
                   ,iv_token_value2  =>  TO_CHAR( gn_policy_group_cnt )    -- �g�[�N���l2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- �艿�ύX�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_tkn_val_fixed_price_cnt        -- �g�[�N���l1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- �g�[�N���R�[�h2
                   ,iv_token_value2  =>  TO_CHAR( gn_fixed_price_cnt )     -- �g�[�N���l2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- �c�ƌ��������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_tkn_val_disc_cost_cnt          -- �g�[�N���l1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- �g�[�N���R�[�h2
                   ,iv_token_value2  =>  TO_CHAR( gn_discrete_cost_cnt )   -- �g�[�N���l2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxcmm                -- �A�v���P�[�V�����Z�k��
                   ,iv_name          =>  cv_msg_xxcmm_00451                -- ���b�Z�[�W�R�[�h
                   ,iv_token_name1   =>  cv_tkn_data_name                  -- �g�[�N���R�[�h1
                   ,iv_token_value1  =>  cv_tkn_val_error_cnt              -- �g�[�N���l1
                   ,iv_token_name2   =>  cv_tkn_data_cnt                   -- �g�[�N���R�[�h2
                   ,iv_token_value2  =>  TO_CHAR( gn_warn_cnt )            -- �g�[�N���l2
                  );
    --
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
--    -- �Ώی����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_target_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_target_cnt )
--                  );
--    --
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
--    --
--    -- ���������o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_success_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
--                  );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
--    --
--    -- �G���[�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_error_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_error_cnt )
--                  );
--    fnd_file.put_line(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
--    --
--    -- �X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_skip_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_warn_cnt )
--                  );
--    --
--    fnd_file.put_line(
--      which  =>  FND_FILE.OUTPUT
--     ,buff   =>  gv_out_msg
--    );
--    fnd_file.put_line(
--       which  => FND_FILE.LOG
--      ,buff   => gv_out_msg
--    );
    --
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
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
                    iv_application  =>  cv_appl_name_xxccp
                   ,iv_name         =>  lv_message_code
                  );
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT
     ,buff   => gv_out_msg
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
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
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
  END main;
--
END XXCMM004A04C;
/
