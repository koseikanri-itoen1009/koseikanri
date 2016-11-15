CREATE OR REPLACE PACKAGE BODY APPS.XXCOS013A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS013A03C (body)
 * Description      : �̔����я����d������쐬���A��ʉ�vOIF�ɘA�g���鏈��
 * MD.050           : GL�ւ̔̔����уf�[�^�A�g MD050_COS_013_A03
 * Version          : 1.17
 * Program List
 * ----------------------------------------------------------------------------------------
 *  Name                   Description
 * ----------------------------------------------------------------------------------------
 *  roundup                �؏�֐�
 *  init                   ��������(A-1)
 *  get_data               �̔����уf�[�^�擾(A-2)
 *  edit_work_data         ��ʉ�vOIF�W�񏈗�(A-3)
 *  edit_gl_data           ��ʉ�vOIF�d��쐬(A-4)
 *  insert_gl_data         ��ʉ�vOIF�o�^����(A-5)
 *  upd_data               �̔����уw�b�_�X�V����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�I������A-7���܂�)
 *
 * Change Record
 * ------------- -------------------------------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- -------------------------------------------------------------------------
 *  2008/12/01    1.0   R.HAN            �V�K�쐬
 *  2009/02/17    1.1   R.HAN            get_msg�̃p�b�P�[�W���C��
 *  2009/02/23    1.2   R.HAN            �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/23    1.3   R.HAN            [COS_115]�ŃR�[�h�̌���������ǉ�
 *  2009/03/26    1.4   T.Kitajima       [T1_0106]�x�������Ή�
 *  2009/04/30    1.5   T.Miyata         [T1_0891]�ŏI�s��[/]�t�^
 *  2009/05/13    1.6   T.Kitajima       [T1_0764]OIF�A�g�s���f�[�^�C��
 *  2009/07/06    1.7   T.Tominaga       [0000235]�Ώۃf�[�^�������b�Z�[�W�̃g�[�N���폜
 *  2009/08/25    1.8   M.Sano           [0001166]CCID�擾�֐��̓��̓p�����[�^��ύX
 *  2009/09/14    1.9   K.Atsushiba      [0001177]PT�Ή�
 *                                       [0001360]BULK�����ɂ��PGA�̈�s���Ή�
 *                                       [0001330]�p�t�H�[�}���X�Ή�
 *  2009/10/07    1.10  N.Maeda          [0001321]�����Ώێ擾�����C���A(���[�j���O�f�[�^('W')�A�������f�[�^('N'))
 *                                                �A�g�t���O�X�V�����ǉ�(���[�j���O�G���[('W')�A�����ΏۊO('S'))
 *  2009/11/17    1.11  M.Sano           [E_T4_00213]OIF�ɃZ�b�g����ŃR�[�h�̃Z�b�g���@�C��
 *                                       [E_T4_00216]�ԕi,�ԕi�C���Ή�
 *  2009/12/29    1.12  N.Maeda          [E_�{�ғ�_00697] �����������������˔[�i���ɕύX
 *  2010/03/01    1.13  K.Aatsushiba     [E_�{�ғ�_01399] ��l�̔���l�����Ή�
 *  2012/08/15    1.14  T.Osawa          [E_�{�ғ�_09922] �d�q����̑Ή�
 *  2012/11/13    1.15  K.Nakamura       [E_�{�ғ�_02459] �p�t�H�[�}���X�Ή�
 *  2016/09/23    1.16  N.Koyama         [E_�{�ғ�_13874] �`�[���͎Ґݒ荀�ڕύX
 *  2016/10/25    1.17  N.Koyama         [E_�{�ғ�_13874] �`�[���͎Ґݒ荀�ڕύX(�đΉ�)
 *                                                        Ver.1.6�̑Ή��͊��S�߂��ł���A���������폜�ׁ̈A�C�������Ȃ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START  ###############################
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
--
--#######################  �Œ�O���[�o���萔�錾�� END   ################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START ################################
--
  gv_out_msg       VARCHAR2(2000);            -- �o�̓��b�Z�[�W
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--#######################  �Œ�O���[�o���ϐ��錾�� END   ###############################
--
--##########################  �Œ苤�ʗ�O�錾�� START  #################################
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
--##########################  �Œ苤�ʗ�O�錾�� END   ###############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);       -- ���b�N�G���[
  global_proc_date_err_expt EXCEPTION;         -- �Ɩ����t�擾��O
  global_select_data_expt   EXCEPTION;         -- �f�[�^�擾��O
  global_insert_data_expt   EXCEPTION;         -- �o�^������O
  global_update_data_expt   EXCEPTION;         -- �X�V������O
  global_get_profile_expt   EXCEPTION;         -- �v���t�@�C���擾��O
  global_no_data_expt       EXCEPTION;         -- �Ώۃf�[�^�O���G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_xxccp_short_nm         CONSTANT VARCHAR2(10) := 'XXCCP';            -- ���ʗ̈�Z�k�A�v����
  cv_xxcos_short_nm         CONSTANT VARCHAR2(10) := 'XXCOS';            -- �̕��A�v���P�[�V�����Z�k��
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOS013A03C';     -- �p�b�P�[�W��
--***************************** 2012/11/13 1.15 K.Nakamura DEL START *****************************--
--  cv_no_para_msg            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
--***************************** 2012/11/13 1.15 K.Nakamura DEL END   *****************************--
  cv_process_date_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- �Ɩ����t�擾�G���[
  cv_pro_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- �v���t�@�C���擾�G���[
  cv_data_get_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013'; -- �f�[�^���o�G���[���b�Z�[�W
  cv_no_data_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- �Ώۃf�[�^�������b�Z�[�W
  cv_table_lock_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001'; -- ���b�N�G���[���b�Z�[�W�i�̔�����TB�j
  cv_data_insert_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010'; -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_data_update_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_card_sale_cls_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12851'; -- �J�[�h���敪�擾�G���[
  cv_tax_cls_msg            CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12852'; -- ����ŋ敪�擾�G���[
  cv_jour_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12853'; -- �d��p�^�[���擾�G���[
  cv_tkn_sales_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12854'; -- �̔����уw�b�_
  cv_tkn_gloif_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12855'; -- ��ʉ�vOIF
  cv_enter_dr_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12856'; -- �ؕ�
  cv_enter_cr_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12857'; -- �ݕ�
  cv_cash_msg               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12858'; -- ����(����Ȗڗp)
  cv_vd_msg                 CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12859'; -- VD������������(����Ȗڗp)
  cv_tax_msg                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12860'; -- �������œ�(����Ȗڗp)
  cv_source_nm_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12861'; -- �̔�����(�d��\�[�X��)
  cv_tkn_ccid_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12863'; -- ����Ȗڑg�����}�X�^
  cv_ccid_nodata_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12864'; -- CCID�擾�o���Ȃ��G���[
  cv_full_vd                CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12866'; -- �t��VD����
  cv_vd_xiaoka              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12867'; -- �t��VD�i�����j����
  cv_full_vd_cash           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12868'; -- �t��VD����
  cv_full_vd_card           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12869'; -- �t��VD�J�[�h
  cv_vd_xiaoka_cash         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12870'; -- �t��VD(����)����
  cv_vd_xiaoka_card         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12871'; -- �t��VD(����)�J�[�h
  cv_om_sales               CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12872'; -- OM�A�g����
  cv_cust_cls_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12873'; -- ��l
  cv_cust_cash              CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12874'; -- ��l����
  cv_cust_cash_sale         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12875'; -- ��l��������
  cv_pro_bks_id             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12876'; -- ��v����ID
  cv_pro_bks_nm             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12877'; -- ��v���떼��
  cv_var_elec_item_cd       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12878'; -- �ϓ��d�C��(�i�ڃR�[�h)
  cv_pro_company_cd         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12879'; -- ��ЃR�[�h
  cv_pro_org_cd             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12880'; -- �݌ɑg�D�R�[�h
  cv_org_id_get_msg         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12881'; -- �݌ɑg�DID
  cv_cust_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12882'; -- �ڋq�敪�擾�G���[
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
  cv_skip_data_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12885'; -- �X�L�b�v�f�[�^
  cv_prof_bulk_msg          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12886';  -- ���ʃZ�b�g�擾�����i�o���N�j
  cv_prof_journal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12887';  -- �d��o�b�`�쐬����
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  cv_sales_exp_h_nomal      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12888';
  cv_sales_exp_h_warn       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12889';
  cv_sales_exp_h_elig       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12890';
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  cv_acnt_title_err_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12891'; -- ����Ȗڎ擾�G���[
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
/* 2010/03/01 Ver1.13 Add Start */
  cv_pf_discount_item_code       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-12892'; -- �l���i��
/* 2010/03/01 Ver1.13 Add End */
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
  cv_param_err_msg          CONSTANT  VARCHAR2(20) := 'APP-XXCOS1-00019'; -- �p�����[�^�w��G���[���b�Z�[�W
  cv_param_msg              CONSTANT  VARCHAR2(20) := 'APP-XXCOS1-12893'; -- �p�����[�^�o�̓��b�Z�[�W
  cv_pro_start_months       CONSTANT  VARCHAR2(20) := 'APP-XXCOS1-12894'; -- GL�ւ̔̔����уf�[�^�A�g�ΏۊJ�n��
  cv_param_name             CONSTANT  VARCHAR2(20) := 'APP-XXCOS1-12895'; -- �p�����[�^��(�N�����[�h)
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
--
  -- �g�[�N��
  cv_tkn_pro                CONSTANT  VARCHAR2(20) := 'PROFILE';         -- �v���t�@�C��
  cv_tkn_tbl                CONSTANT  VARCHAR2(20) := 'TABLE';           -- �e�[�u������
  cv_tkn_tbl_nm             CONSTANT  VARCHAR2(20) := 'TABLE_NAME';      -- �e�[�u������
  cv_tkn_lookup_type        CONSTANT  VARCHAR2(20) := 'LOOKUP_TYPE';     -- �Q�ƃ^�C�v
  cv_tkn_lookup_code        CONSTANT  VARCHAR2(20) := 'LOOKUP_CODE';     -- �N�C�b�N�R�[�h
  cv_tkn_lookup_dff3        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE3';      -- �Q�ƃ^�C�v��DFF3
  cv_tkn_lookup_dff4        CONSTANT  VARCHAR2(20) := 'ATTRIBUTE4';      -- �Q�ƃ^�C�v��DFF4
  cv_tkn_segment1           CONSTANT  VARCHAR2(20) := 'SEGMENT1';        -- ��ЃR�[�h
  cv_tkn_segment2           CONSTANT  VARCHAR2(20) := 'SEGMENT2';        -- ����R�[�h
  cv_tkn_segment3           CONSTANT  VARCHAR2(20) := 'SEGMENT3';        -- ����ȖڃR�[�h
  cv_tkn_segment4           CONSTANT  VARCHAR2(20) := 'SEGMENT4';        -- �⏕�ȖڃR�[�h
  cv_tkn_segment5           CONSTANT  VARCHAR2(20) := 'SEGMENT5';        -- �ڋq�R�[�h
  cv_tkn_segment6           CONSTANT  VARCHAR2(20) := 'SEGMENT6';        -- ��ƃR�[�h
  cv_tkn_segment7           CONSTANT  VARCHAR2(20) := 'SEGMENT7';        -- ���Ƌ敪�R�[�h
  cv_tkn_segment8           CONSTANT  VARCHAR2(20) := 'SEGMENT8';        -- �\��
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
  cv_tkn_segment9           CONSTANT  VARCHAR2(20) := 'SEGMENT9';        --
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
  cv_tkn_header_from        CONSTANT  VARCHAR2(20) := 'HEADER_FROM';      -- �̔����уw�b�_ID(FROM)
  cv_tkn_header_to          CONSTANT  VARCHAR2(20) := 'HEADER_TO';        -- �̔����уw�b�_ID(TO)
  cv_tkn_count              CONSTANT  VARCHAR2(20) := 'HEADER_COUNT';     -- �̔����уw�b�_����
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
  cv_tkn_in_param           CONSTANT  VARCHAR2(20) := 'IN_PARAM';        -- �p�����[�^��
  cv_tkn_param1             CONSTANT  VARCHAR2(20) := 'PARAM1';          -- �p�����[�^1
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
  cv_blank                  CONSTANT VARCHAR2(1)   := '';                -- �u�����N
  cv_tkn_key_data           CONSTANT VARCHAR2(20)  := 'KEY_DATA';        -- �L�[����
--
  -- �t���O�E�敪�萔
  cv_y_flag                 CONSTANT  VARCHAR2(1)  := 'Y';               -- �t���O�l:Y
  cv_n_flag                 CONSTANT  VARCHAR2(1)  := 'N';               -- �t���O�l:N
  cv_card_class             CONSTANT  VARCHAR2(1)  := '1';               -- �J�[�h����敪�F�J�[�h= 1
  cv_cash_class             CONSTANT  VARCHAR2(1)  := '0';               -- �J�[�h����敪�F����= 0
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  cv_w_flag                 CONSTANT  VARCHAR2(1)  := 'W';               -- �t���O�l:W(�x��)
  cv_s_flag                 CONSTANT  VARCHAR2(1)  := 'S';               -- �t���O�l:S(�ΏۊO)
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  cv_dic_return             CONSTANT  VARCHAR2(1)  := '2';               -- �[�i�`�[�敪:�ԕi
  cv_dic_return_correction  CONSTANT  VARCHAR2(1)  := '4';               -- �[�i�`�[�敪:�ԕi����
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
  cv_months                 CONSTANT  VARCHAR2(2)  := 'MM';              -- �����t�H�[�}�b�gMM
  cv_mode1                  CONSTANT  VARCHAR2(1)  := '1';               -- GL�ւ̔̔����уf�[�^�A�g�N�����[�h:�������[�h
  cv_mode2                  CONSTANT  VARCHAR2(1)  := '2';               -- GL�ւ̔̔����уf�[�^�A�g�N�����[�h:�ΏۊO�X�V���[�h
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
--
  -- �N�C�b�N�R�[�h�^�C�v
  ct_qct_gyotai_sho         CONSTANT  VARCHAR2(50) := 'XXCOS1_GYOTAI_SHO_MST_013_A03';  -- �Ƒԏ����ޓ���}�X�^
  ct_qct_sale_class         CONSTANT  VARCHAR2(50) := 'XXCOS1_SALE_CLASS_MST_013_A03';  -- ����敪����}�X�^
  ct_qct_dlv_slp_cls        CONSTANT  VARCHAR2(50) := 'XXCOS1_DLV_SLP_CLS_MST_013_A03'; -- �[�i�`�[�敪����}�X�^
  ct_qct_card_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_CARD_SALE_CLASS';         -- �J�[�h���敪����}�X�^
  ct_qct_jour_cls           CONSTANT  VARCHAR2(50) := 'XXCOS1_JOUR_CLS_MST_013_A03';    -- GL�d�����}�X�^
  ct_qct_tax_cls            CONSTANT  VARCHAR2(50) := 'XXCOS1_CONSUMPTION_TAX_CLASS';   -- ����ŋ敪����}�X�^
  ct_cust_cls_cd            CONSTANT  VARCHAR2(50) := 'XXCOS1_CUS_CLASS_MST_013_A03';   -- �ڋq�敪����}�X�^
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  ct_qct_acnt_title_cd      CONSTANT  VARCHAR2(50) := 'XXCOS1_ACNT_TITLE_MST_013_A03';  --����Ȗړ���}�X�^
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
  -- �N�C�b�N�R�[�h
  ct_qcc_code               CONSTANT  VARCHAR2(50) := 'XXCOS_013_A03%';                 -- �N�C�b�N�R�[�h
  ct_attribute_y            CONSTANT  VARCHAR2(1)  := 'Y';                              -- DFF�l'Y'
  ct_enabled_yes            CONSTANT  VARCHAR2(1)  := 'Y';                              -- �g�p�\�t���O�萔:�L��
--
  -- ��ʉ�vOIF�e�[�u���ɐݒ肷��Œ�l
  ct_status                CONSTANT  VARCHAR2(3)   := 'NEW';                            -- �X�e�[�^�X
  ct_currency_code         CONSTANT  VARCHAR2(3)   := 'JPY';                            -- �ʉ݃R�[�h
  ct_actual_flag           CONSTANT  VARCHAR2(1)   := 'A';                              -- �c���^�C�v
  ct_segment5              CONSTANT  VARCHAR2(10)  := '000000000';                      -- �ڋq�R�[�h(�����E��������)
  ct_group_id              CONSTANT  NUMBER        := 9000000003;                       -- �O���[�vID
  ct_underbar              CONSTANT  VARCHAR2(1)   := '_';                              -- ���ڋ�؂�p
  ct_date_format_non_sep   CONSTANT  VARCHAR2(20)  := 'YYYYMMDD';                       -- ���t�t�H�}�b�g
  ct_vd_xiaoka_cd          CONSTANT  VARCHAR2(20)  := '24';                             -- �t��VD�i�����j
  ct_full_vd_cd            CONSTANT  VARCHAR2(20)  := '25';                             -- �t��VD
  ct_round_rule_up         CONSTANT  VARCHAR2(10)  := 'UP';                             -- �؂�グ
  ct_round_rule_down       CONSTANT  VARCHAR2(10)  := 'DOWN';                           -- �؂艺��
  ct_round_rule_nearest    CONSTANT  VARCHAR2(10)  := 'NEAREST';                        -- �l�̌ܓ�
  ct_percent               CONSTANT  NUMBER        := 100;                              -- 100
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  ct_tax_code_null         CONSTANT  VARCHAR2(10)  := '0000';                           -- �ŋ��R�[�h(0000)
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--****************************** 2009/09/14 1.9 Atsushiba     ADD START ******************************--
--
  -- ���̑�
  ct_lang                  CONSTANT  fnd_lookup_values.language%TYPE := USERENV('LANG'); -- ����R�[�h
  cv_exists_flag           CONSTANT  VARCHAR2(1)   := '1';                               -- EXISTS���\���p 
  cn_bulk_collect_count    NUMBER;                            -- ���ʃZ�b�g�擾����
  cn_journal_batch_count   NUMBER;                            -- �d��o�b�`�쐬����
  cn_commit_exec_flag      NUMBER DEFAULT 0;     -- �R�~�b�g���s�t���O(0:�����s,1:���s����)
--***************************** 2012/11/13 1.15 K.Nakamura DEL START *****************************--
---- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
--  gn_last_flag             NUMBER DEFAULT 0;
---- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--***************************** 2012/11/13 1.15 K.Nakamura DEL END   *****************************--
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �̔����у��[�N�e�[�u����`
--****************************** 2009/05/12 1.6 T.KItajima MOD START ******************************--
--  TYPE gr_sales_exp_rec IS RECORD(
--      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
--    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- �[�i�`�[�ԍ�
--    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- �[�i�`�[�敪
--    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- �Ƒԏ�����
--    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- �[�i��
--    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- ������
--    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- �ڋq�y�[�i��z
--    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- �ŋ��R�[�h
--    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- ����ŗ�
--    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����敪
--    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- ���ьv��҃R�[�h
--    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- ���㋒�_�R�[�h
--    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- �J�[�h����敪
--    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- ����敪
--    , goods_prod_cls            xxcos_good_prod_class_v.goods_prod_class_code%TYPE  -- �i�ڋ敪�R�[�h�i���i�E���i�j
--    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- �{�̋��z
--    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- ����ŋ��z
--    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- �����E�J�[�h���p�z
--    , customer_cls_code         hz_cust_accounts.customer_class_code%TYPE           -- �ڋq�敪
--    , gccs_segment3             gl_code_combinations.segment3%TYPE                  -- ���㊨��ȖڃR�[�h
--    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- �ŋ�����ȖڃR�[�h
--    , bill_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- �ŋ��|�[������
--    , xseh_rowid                ROWID                                               -- ROWID
--  );
--  -- �d��p�^�[�����[�N�e�[�u����`
--  TYPE gr_jour_cls_rec IS RECORD(
--      dlv_invoice_class         fnd_lookup_values.attribute1%TYPE                   -- �[�i�`�[�敪
--    , card_sale_class           fnd_lookup_values.attribute2%TYPE                   -- �J�[�h����敪
--    , goods_prod_cls            fnd_lookup_values.attribute3%TYPE                   -- �i�ڋ敪�R�[�h�i���i�E���i�j
--    , segment3                  fnd_lookup_values.attribute4%TYPE                   -- ����ȖڃR�[�h
--    , line_type                 fnd_lookup_values.attribute5%TYPE                   -- ���C���^�C�v
--    , jour_category             fnd_lookup_values.attribute6%TYPE                   -- �d��J�e�S��
--    , segment2                  fnd_lookup_values.attribute7%TYPE                   -- ����R�[�h
--    , jour_pattern              fnd_lookup_values.meaning%TYPE                      -- �d��p�^�[��
--    , gl_segment3_nm            fnd_lookup_values.description%TYPE                  -- ����Ȗږ�
--    , segment4                  fnd_lookup_values.attribute8%TYPE                   -- �⏕����ȖڃR�[�h
--    , segment5                  fnd_lookup_values.attribute9%TYPE                   -- �ڋq�R�[�h
--    , segment6                  fnd_lookup_values.attribute10%TYPE                  -- ��ƃR�[�h
--    , segment7                  fnd_lookup_values.attribute11%TYPE                  -- �\���P
--    , segment8                  fnd_lookup_values.attribute12%TYPE                  -- �\���Q
--  );
--
  TYPE gr_sales_exp_rec IS RECORD(
      sales_exp_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE    -- �̔����уw�b�_ID
    , dlv_invoice_number        xxcos_sales_exp_headers.dlv_invoice_number%TYPE     -- �[�i�`�[�ԍ�
    , dlv_invoice_class         xxcos_sales_exp_headers.dlv_invoice_class%TYPE      -- �[�i�`�[�敪
    , cust_gyotai_sho           xxcos_sales_exp_headers.cust_gyotai_sho%TYPE        -- �Ƒԏ�����
    , delivery_date             xxcos_sales_exp_headers.delivery_date%TYPE          -- �[�i��
    , inspect_date              xxcos_sales_exp_headers.inspect_date%TYPE           -- ������
    , ship_to_customer_code     xxcos_sales_exp_headers.ship_to_customer_code%TYPE  -- �ڋq�y�[�i��z
    , tax_code                  xxcos_sales_exp_headers.tax_code%TYPE               -- �ŋ��R�[�h
    , tax_rate                  xxcos_sales_exp_headers.tax_rate%TYPE               -- ����ŗ�
    , consumption_tax_class     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- ����敪
    , results_employee_code     xxcos_sales_exp_headers.results_employee_code%TYPE  -- ���ьv��҃R�[�h
    , sales_base_code           xxcos_sales_exp_headers.sales_base_code%TYPE        -- ���㋒�_�R�[�h
    , card_sale_class           xxcos_sales_exp_headers.card_sale_class%TYPE        -- �J�[�h����敪
    , sales_class               xxcos_sales_exp_lines.sales_class%TYPE              -- ����敪
    , pure_amount               xxcos_sales_exp_lines.pure_amount%TYPE              -- �{�̋��z
    , tax_amount                xxcos_sales_exp_lines.tax_amount%TYPE               -- ����ŋ��z
    , cash_and_card             xxcos_sales_exp_lines.cash_and_card%TYPE            -- �����E�J�[�h���p�z
    , red_black_flag            xxcos_sales_exp_lines.cash_and_card%TYPE            -- �ԍ��t���O
    , customer_cls_code         hz_cust_accounts.customer_class_code%TYPE           -- �ڋq�敪
    , gcct_segment3             gl_code_combinations.segment3%TYPE                  -- �ŋ�����ȖڃR�[�h
    , bill_tax_round            xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE     -- �ŋ��|�[������
    , xseh_rowid                ROWID                                               -- ROWID
/* 2010/03/01 Ver1.13 Add Start */
    , item_code                 xxcos_sales_exp_lines.item_code%TYPE                -- �i�ڃR�[�h
/* 2010/03/01 Ver1.13 Add End */
  );
--
  -- �d��p�^�[�����[�N�e�[�u����`
  TYPE gr_jour_cls_rec IS RECORD(
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
--      red_black_flag            fnd_lookup_values.attribute1%TYPE                   -- �ԍ��t���O
      dlv_invoice_class         fnd_lookup_values.attribute1%TYPE                   -- �[�i�`�[�ԍ�
    , red_black_flag            fnd_lookup_values.attribute12%TYPE                  -- �ԍ��t���O
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
    , card_sale_class           fnd_lookup_values.attribute2%TYPE                   -- �J�[�h����敪
    , segment3                  fnd_lookup_values.attribute3%TYPE                   -- ����ȖڃR�[�h
    , line_type                 fnd_lookup_values.attribute4%TYPE                   -- ���C���^�C�v
    , jour_category             fnd_lookup_values.attribute5%TYPE                   -- �d��J�e�S��
    , jour_pattern              fnd_lookup_values.meaning%TYPE                      -- �d��p�^�[��
    , gl_segment3_nm            fnd_lookup_values.description%TYPE                  -- ����Ȗږ�
    , segment4                  fnd_lookup_values.attribute6%TYPE                   -- �⏕����ȖڃR�[�h
    , segment5                  fnd_lookup_values.attribute7%TYPE                   -- �ڋq�R�[�h
    , segment6                  fnd_lookup_values.attribute8%TYPE                   -- ��ƃR�[�h
    , segment7                  fnd_lookup_values.attribute9%TYPE                   -- �\���P
    , segment8                  fnd_lookup_values.attribute10%TYPE                  -- �\���Q
    , segment2                  fnd_lookup_values.attribute2%TYPE                   -- ���_�R�[�h
/* 2010/03/01 Ver1.13 Add Start */
    , discount_class            fnd_lookup_values.attribute13%TYPE                  -- �l���敪
/* 2010/03/01 Ver1.13 Add End */
  );
--
--****************************** 2009/05/12 1.6 T.KItajima MOD  END  ******************************--
--
  -- CCID���[�N�e�[�u����`
  TYPE gr_select_ccid IS RECORD(
      code_combination_id       gl_code_combinations.code_combination_id%TYPE       -- CCID
  );
--
  -- ���[�N�e�[�u���^��`
  TYPE g_sales_exp_ttype  IS TABLE OF gr_sales_exp_rec     INDEX BY BINARY_INTEGER;
  gt_sales_exp_tbl                    g_sales_exp_ttype;                            -- �̔����уf�[�^
  gt_sales_card_tbl                   g_sales_exp_ttype;                            -- �̔����уJ�[�h�f�[�^
--
  TYPE g_sales_h_ttype    IS TABLE OF ROWID                INDEX BY BINARY_INTEGER;
  gt_sales_h_tbl                      g_sales_h_ttype;                              -- �̔����уt���O�X�V�p
  gt_sales_h_tbl2                     g_sales_h_ttype;                              -- �̔����уt���O�X�V�p
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  gt_sales_h_tbl_work_w               g_sales_h_ttype;                              -- �̔����уt���O�X�V�p(�x���f�[�^���[�N)
  gt_sales_h_tbl_w                    g_sales_h_ttype;                              -- �̔����уt���O�X�V�p(�x���f�[�^)
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
  TYPE g_jour_cls_ttype   IS TABLE OF gr_jour_cls_rec      INDEX BY BINARY_INTEGER;
  gt_jour_cls_tbl                     g_jour_cls_ttype;                             -- �d��p�^�[��
--
  TYPE g_gl_oif_ttype     IS TABLE OF gl_interface%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_gl_interface_tbl                 g_gl_oif_ttype;                               -- ��ʉ�vOIF
  gt_gl_interface_tbl2                g_gl_oif_ttype;                               -- ��ʉ�vOIF
--
  TYPE g_sel_ccid_ttype   IS TABLE OF gr_select_ccid       INDEX BY VARCHAR2( 200 );
  gt_sel_ccid_tbl                     g_sel_ccid_ttype;                             -- CCID
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
  gt_sales_exp_wk_tbl                 g_sales_exp_ttype;                            -- �̔����уf�[�^(��Ɨp)
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
  gt_sales_exp_evacu_tbl              g_sales_exp_ttype;                            -- �̔����уf�[�^(�ޔ�p)
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
  --
  TYPE g_sales_header_ttype IS TABLE OF NUMBER INDEX BY VARCHAR(100);
  gt_sales_header_tbl                 g_sales_header_ttype;
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
  -- ===============================
  -- ���[�U�[��`�O���[�o�����R�[�h
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�����擾
  gd_process_date                     DATE;                                         -- �Ɩ����t
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
  gd_from_date                        DATE;                                         -- �擾�����ƂȂ���t(From)
  gv_mode                             VARCHAR2(1);                                  -- �N�����[�h
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
  gv_company_code                     VARCHAR2(30);                                 -- ��ЃR�[�h
  gv_set_bks_id                       VARCHAR2(30);                                 -- ��v����ID
  gv_set_bks_nm                       VARCHAR2(30);                                 -- ��v���떼��
  gv_org_cd                           VARCHAR2(30);                                 -- �݌ɑg�D�R�[�h
  gv_org_id                           VARCHAR2(30);                                 -- �݌ɑg�DID
  gv_var_elec_item_cd                 VARCHAR2(30);                                 -- �ϓ��d�C��(�i�ڃR�[�h)
  gt_cust_cls_cd                      hz_cust_accounts.customer_class_code%TYPE;    -- �ڋq�敪�i��l�j
  gt_card_sale_cls                    fnd_lookup_values.lookup_code%TYPE;           -- �J�[�h����敪
  gt_no_tax_cls                       fnd_lookup_values.attribute3%TYPE;            -- ����敪
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
  gt_segment3_cash                    fnd_lookup_values.attribute4%TYPE;            --����Ȗ�(����)
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
/* 2010/03/01 Ver1.13 Add Start */
  gt_discount_item_code               fnd_profile_option_values.profile_option_value%TYPE;      -- �l���i��
/* 2010/03/01 Ver1.13 Add End */
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
  CURSOR sales_data_cur
  IS
    SELECT
          /*+ LEADING(xseh)
              INDEX(xseh xxcos_sales_exp_headers_n05 )
              USE_NL(xseh xsel msib )
              USE_NL(xseh hca avta gcct )
              USE_NL(xseh xchv)
              INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u2)
              INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u2)
              INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u2)
              INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u2)
           */
           xseh.sales_exp_header_id          sales_exp_header_id      -- �̔����уw�b�_ID
         , xseh.dlv_invoice_number           dlv_invoice_number       -- �[�i�`�[�ԍ�
         , xseh.dlv_invoice_class            dlv_invoice_class        -- �[�i�`�[�敪
         , xseh.cust_gyotai_sho              cust_gyotai_sho          -- �Ƒԏ�����
         , xseh.delivery_date                delivery_date            -- �[�i��
         , xseh.inspect_date                 inspect_date             -- ������
         , xseh.ship_to_customer_code        ship_to_customer_code    -- �ڋq�y�[�i��z
         , xseh.tax_code                     tax_code                 -- �ŋ��R�[�h
         , xseh.tax_rate                     tax_rate                 -- ����ŗ�
         , xseh.consumption_tax_class        consumption_tax_class    -- ����敪
         , xseh.results_employee_code        results_employee_code    -- ���ьv��҃R�[�h
         , xseh.sales_base_code              sales_base_code          -- ���㋒�_�R�[�h
         , NVL( xseh.card_sale_class, cv_cash_class )
                                             card_sale_class          -- �J�[�h����敪
         , xsel.sales_class                  sales_class              -- ����敪
         , xsel.pure_amount                  pure_amount              -- �{�̋��z
         , xsel.tax_amount                   tax_amount               -- ����ŋ��z
         , NVL( xsel.cash_and_card, 0 )      cash_and_card            -- �����E�J�[�h���p�z
         , xsel.red_black_flag               red_black_flag           -- �ԍ��t���O
         , hca.customer_class_code           customer_cls_code        -- �ڋq�敪
         , gcct.segment3                     gcct_segment3            -- �ŋ�����ȖڃR�[�h
         , xchv.bill_tax_round_rule          tax_round_rule           -- �ŋ��|�[������
         , xseh.rowid                        xseh_rowid               -- ROWID
/* 2010/03/01 Ver1.13 Add Start */
         , xsel.item_code                    item_code                -- �i�ڃR�[�h
/* 2010/03/01 Ver1.13 Add End */
    FROM
           xxcos_sales_exp_headers           xseh                     -- �̔����уw�b�_�e�[�u��
         , xxcos_sales_exp_lines             xsel                     -- �̔����і��׃e�[�u��
         , mtl_system_items_b                msib                     -- �i�ڃ}�X�^
         , gl_code_combinations              gcct                     -- ����Ȗڑg�����}�X�^�iTAX�p�j
         , ar_vat_tax_all_b                  avta                     -- �ŋ��}�X�^
         , hz_cust_accounts                  hca                      -- �ڋq�敪
         , xxcos_cust_hierarchy_v            xchv                     -- �ڋq�K�w�r���[
    WHERE
        xseh.sales_exp_header_id             = xsel.sales_exp_header_id
    AND xseh.dlv_invoice_number              = xsel.dlv_invoice_number
-- ***************** 2009/10/07 1.10 N.Maeda MOD START ***************** --
--    AND xseh.gl_interface_flag               = cv_n_flag
    AND ( xseh.gl_interface_flag             = cv_n_flag
          OR xseh.gl_interface_flag          = cv_w_flag )
-- ***************** 2009/10/07 1.10 N.Maeda MOD  END  ***************** --
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    AND xseh.delivery_date                   >= gd_from_date
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
---- ***************** 2009/12/29 1.12 N.Maeda MOD START ***************** --
----    AND xseh.inspect_date                   <= gd_process_date
    AND xseh.delivery_date                   <= gd_process_date
---- ***************** 2009/12/29 1.12 N.Maeda MOD  END  ***************** --
    AND xsel.item_code                      <> gv_var_elec_item_cd
    AND hca.account_number                   = xseh.ship_to_customer_code
    AND xchv.ship_account_number             = xseh.ship_to_customer_code
    AND ( EXISTS (
          SELECT /*+ USE_NL(flvl1) */
              cv_exists_flag                 exists_flag
          FROM
              fnd_lookup_values              flvl1
          WHERE
              flvl1.lookup_type              = ct_qct_gyotai_sho
          AND flvl1.lookup_code              LIKE ct_qcc_code
          AND flvl1.meaning                  = xseh.cust_gyotai_sho
          AND flvl1.attribute1               = ct_attribute_y
          AND flvl1.enabled_flag             = ct_enabled_yes
          AND flvl1.language                 = ct_lang
          AND gd_process_date BETWEEN        NVL( flvl1.start_date_active, gd_process_date )
                              AND            NVL( flvl1.end_date_active,   gd_process_date )
          )
          OR hca.customer_class_code          = gt_cust_cls_cd
        )
    AND NOT EXISTS (
        SELECT /*+ USE_NL(flvl2) */
            cv_exists_flag                   exists_flag
        FROM
            fnd_lookup_values                flvl2
        WHERE
            flvl2.lookup_type                = ct_qct_sale_class
        AND flvl2.lookup_code                LIKE ct_qcc_code
        AND flvl2.meaning                    = xsel.sales_class
        AND flvl2.attribute1                 = ct_attribute_y
        AND flvl2.enabled_flag               = ct_enabled_yes
        AND flvl2.language                   = ct_lang
        AND gd_process_date BETWEEN          NVL( flvl2.start_date_active, gd_process_date )
                            AND              NVL( flvl2.end_date_active,   gd_process_date )
        )
    AND EXISTS (
        SELECT /*+ USE_NL(flvl3) */
            cv_exists_flag                   exists_flag
        FROM
            fnd_lookup_values                flvl3
        WHERE
            flvl3.lookup_type                = ct_qct_dlv_slp_cls
        AND flvl3.lookup_code                LIKE ct_qcc_code
        AND flvl3.meaning                    = xseh.dlv_invoice_class
--******************************* 2009/11/17 1.11 M.Sano DEL START *******************************--
--        AND flvl3.attribute1                 = ct_attribute_y
--******************************* 2009/11/17 1.11 M.Sano DEL END   *******************************--
        AND flvl3.enabled_flag               = ct_enabled_yes
        AND flvl3.language                   = ct_lang
        AND gd_process_date BETWEEN          NVL( flvl3.start_date_active, gd_process_date )
                            AND              NVL( flvl3.end_date_active,   gd_process_date )
        )
    AND msib.organization_id                 = gv_org_id
    AND xsel.item_code                       = msib.segment1
    AND avta.tax_code                        = xseh.tax_code
    AND gcct.code_combination_id             = avta.tax_account_id
    AND avta.set_of_books_id                 = TO_NUMBER( gv_set_bks_id )
    AND avta.enabled_flag                    = ct_enabled_yes
/* 2010/03/01 Ver1.13 Mod Start */
    ORDER BY  xseh.sales_exp_header_id
             ,xsel.red_black_flag;
--    ORDER BY xseh.sales_exp_header_id;
/* 2010/03/01 Ver1.13 Mod End */
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
  /**********************************************************************************
   * Procedure Name   : roundup
   * Description      : �؏�֐�
   ***********************************************************************************/
  FUNCTION roundup(in_number IN NUMBER, in_place IN INTEGER := 0)
  RETURN NUMBER
  IS
    ln_base NUMBER;
  BEGIN
    IF (in_number = 0) 
      OR (in_number IS NULL) 
    THEN
      RETURN 0;
    END IF;
--
    ln_base := 10 ** in_place ;
    RETURN CEIL( ABS( in_number ) * ln_base ) / ln_base * SIGN( in_number );
  END;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--      ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
      iv_mode       IN  VARCHAR2     --   �N�����[�h
    , ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
    , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'init';             -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾�� END     ########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    ct_pro_bks_id            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';
                                                                      -- ��v����ID
    ct_pro_bks_nm            CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_NAME';
                                                                      -- ��v���떼��
    ct_pro_org_cd            CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
                                                                      -- XXCOI:�݌ɑg�D�R�[�h
    ct_pro_company_cd        CONSTANT VARCHAR2(30) := 'XXCOI1_COMPANY_CODE';
                                                                      -- XXCOI:��ЃR�[�h
    ct_var_elec_item_cd      CONSTANT VARCHAR2(30) := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
                                                                      -- XXCOS:�ϓ��d�C��(�i�ڃR�[�h)
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda MOD START ***************** --
--    ct_bulk_collect_count    CONSTANT VARCHAR2(30) := 'XXCOS1_BULK_COLLECT_COUNT';  -- ���ʃZ�b�g�擾�����i�o���N�j
    ct_bulk_collect_count    CONSTANT VARCHAR2(30) := 'XXCOS1_GL_BULK_COLLECT_COUNT';  -- ���ʃZ�b�g�擾�����i�o���N�j
-- ***************** 2009/10/07 1.10 N.Maeda MOD  END  ***************** --
    ct_journal_batch_count   CONSTANT VARCHAR2(30) := 'XXCOS1_JOURNAL_BATCH_COUNT'; -- �d��o�b�`�쐬����
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
/* 2010/03/01 Ver1.13 Add Start */
    ct_discount_item_cd      CONSTANT VARCHAR2(30) := 'XXCOS1_DISCOUNT_ITEM_CODE';    -- XXCOS:����l���i��
/* 2010/03/01 Ver1.13 Add End */
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    ct_013a03_start_months   CONSTANT VARCHAR2(30) := 'XXCOS1_013A03_START_MONTHS';   -- XXCOS:GL�ւ̔̔����уf�[�^�A�g�ΏۊJ�n��
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
--
    -- *** ���[�J���ϐ� ***
    lv_profile_name          VARCHAR2(50);                           -- �v���t�@�C����
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
    lv_tmp                   VARCHAR2(100);
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    lv_param_name            VARCHAR2(50);                           -- �p�����[�^��
    lv_013a03_start_months   NUMBER;                                 -- XXCOS:GL�ւ̔̔����уf�[�^�A�g�ΏۊJ�n��
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
--
    -- *** ���[�J����O ***
    non_lookup_value_expt    EXCEPTION;                               -- LOOKUP�擾�G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--##################  �Œ�X�e�[�^�X�������� END     ###################
--
    --==============================================================
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�o��
    -- �R���J�����g���̓p�����[�^�o��
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--                      iv_application => cv_xxccp_short_nm
--                    , iv_name        => cv_no_para_msg
                      iv_application  => cv_xxcos_short_nm
                    , iv_name         => cv_param_msg
                    , iv_token_name1  => cv_tkn_param1
                    , iv_token_value1 => iv_mode
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
                  );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => cv_blank
    );
    --===================================================
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--    -- �R���J�����g���̓p�����[�^�Ȃ����O�o��
    -- �R���J�����g���̓p�����[�^�o��
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
    --===================================================
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_blank
    );
--
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    --==================================
    -- �p�����[�^�̃`�F�b�N
    --==================================
    IF ( iv_mode IS NULL ) OR
       ( iv_mode NOT IN ( cv_mode1, cv_mode2 ) )
    THEN
      lv_param_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_param_name                   -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_param_err_msg
                     , iv_token_name1  => cv_tkn_in_param
                     , iv_token_value1 => lv_param_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ����t�擾�G���[�̏ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_xxcos_short_nm, cv_process_date_msg );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    -- ===============================
    -- �v���t�@�C���擾�FGL�ւ̔̔����уf�[�^�A�g�ΏۊJ�n��
    -- ===============================
    BEGIN
      lv_013a03_start_months := TO_NUMBER(FND_PROFILE.VALUE( ct_013a03_start_months )) * -1;
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_pro_start_months             -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( lv_013a03_start_months IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_pro_start_months             -- ���b�Z�[�WID
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_short_nm
                     , iv_name         => cv_pro_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => lv_profile_name
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- GL�ւ̔̔����уf�[�^�A�g�ΏۊJ�n���t�擾
    --==================================
    gd_from_date := TRUNC(ADD_MONTHS(gd_process_date, lv_013a03_start_months), cv_months);
--
    -- �p�����[�^�ϐ��ݒ�
    gv_mode := iv_mode;
--
    -- �N�����[�h��1�̏ꍇ�̂�
    IF ( gv_mode = cv_mode1 ) THEN
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
--
      -- ===============================
      -- �v���t�@�C���擾�F��v����ID
      -- ===============================
      gv_set_bks_id := FND_PROFILE.VALUE( ct_pro_bks_id );
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      IF ( gv_set_bks_id IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_pro_bks_id                   -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ===============================
      -- �v���t�@�C���擾�F��v���떼��
      -- ===============================
      gv_set_bks_nm := FND_PROFILE.VALUE( ct_pro_bks_nm );
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      IF ( gv_set_bks_nm IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_pro_bks_nm                   -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ===============================
      -- �v���t�@�C���擾�F�݌ɑg�D�R�[�h
      -- ===============================
      gv_org_cd := FND_PROFILE.VALUE( ct_pro_org_cd );
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      IF ( gv_org_cd IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_pro_org_cd                   -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ===============================
      -- �݌ɑg�DID�擾
      -- ===============================
      gv_org_id := xxcoi_common_pkg.get_organization_id( gv_org_cd );
      -- �݌ɑg�DID�擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gv_org_id IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_short_nm
                       , iv_name        => cv_org_id_get_msg
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      -----------------------------------------------------------------------
--
      --==================================
      -- XXCOI:��ЃR�[�h
      --==================================
      gv_company_code := FND_PROFILE.VALUE( ct_pro_company_cd );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gv_company_code IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_pro_company_cd               -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- XXCOS:�ϓ��d�C��(�i�ڃR�[�h)�擾
      --==================================
      gv_var_elec_item_cd := FND_PROFILE.VALUE( ct_var_elec_item_cd );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gv_var_elec_item_cd IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_var_elec_item_cd             -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      --==================================
      -- 5.�N�C�b�N�R�[�h�擾
      --==================================
      -- �J�[�h����敪=����:0
      BEGIN
        SELECT flvl.lookup_code
        INTO   gt_card_sale_cls
        FROM   fnd_lookup_values           flvl
        WHERE  flvl.lookup_type            = ct_qct_card_cls
          AND  flvl.attribute3             = ct_attribute_y
          AND  flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--          AND  flvl.language               = USERENV( 'LANG' )
          AND  flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
          AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                               AND         NVL( flvl.end_date_active,   gd_process_date );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_xxcos_short_nm
                         , iv_name          => cv_card_sale_cls_msg
                         , iv_token_name1   => cv_tkn_lookup_type
                         , iv_token_value1  => ct_qct_card_cls
                         , iv_token_name2   => cv_tkn_lookup_dff3
                         , iv_token_value2  => ct_attribute_y
                       );
          lv_errbuf := lv_errmsg;
          RAISE non_lookup_value_expt;
      END;
--
      -- ����ŋ敪=��ې�:4
      BEGIN
        SELECT flvl.attribute3
        INTO   gt_no_tax_cls
        FROM   fnd_lookup_values           flvl
        WHERE  flvl.lookup_type            = ct_qct_tax_cls
          AND  flvl.attribute4             = ct_attribute_y
          AND  flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--          AND  flvl.language               = USERENV( 'LANG' )
          AND  flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
          AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                               AND         NVL( flvl.end_date_active,   gd_process_date );
  --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_tax_cls_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => ct_qct_tax_cls
                        , iv_token_name2   => cv_tkn_lookup_dff4
                        , iv_token_value2  => ct_attribute_y
                       );
          lv_errbuf := lv_errmsg;
          RAISE non_lookup_value_expt;
      END;
--
      -- �ڋq�敪=��l:12
      BEGIN
        SELECT flvl.meaning
        INTO   gt_cust_cls_cd
        FROM   fnd_lookup_values           flvl
        WHERE  flvl.lookup_type            = ct_cust_cls_cd
          AND  flvl.lookup_code            LIKE ct_qcc_code
          AND  flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--          AND  flvl.language               = USERENV( 'LANG' )
          AND  flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
          AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                               AND         NVL( flvl.end_date_active,   gd_process_date );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_cust_err_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => ct_cust_cls_cd
                       );
          lv_errbuf := lv_errmsg;
          RAISE non_lookup_value_expt;
      END;
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
      --==================================
      -- XXCOI:���ʃZ�b�g�擾����
      --==================================
      lv_tmp := FND_PROFILE.VALUE( ct_bulk_collect_count );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( lv_tmp IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_prof_bulk_msg                -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      cn_bulk_collect_count := TO_NUMBER(lv_tmp);
--
      --==================================
      -- XXCOI:�d��o�b�`�쐬����
      --==================================
      lv_tmp := FND_PROFILE.VALUE( ct_journal_batch_count );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( lv_tmp IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_prof_journal_msg               -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      cn_journal_batch_count := TO_NUMBER(lv_tmp);
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
--
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
      -- ����Ȗ�=����
      BEGIN
        SELECT flvl.meaning
        INTO   gt_segment3_cash
        FROM   fnd_lookup_values           flvl
        WHERE  flvl.lookup_type            = ct_qct_acnt_title_cd
          AND  flvl.lookup_code            LIKE ct_qcc_code
          AND  flvl.enabled_flag           = ct_enabled_yes
          AND  flvl.language               = ct_lang
          AND  gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                               AND         NVL( flvl.end_date_active,   gd_process_date );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �N�C�b�N�R�[�h�擾�o���Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_xxcos_short_nm
                        , iv_name          => cv_acnt_title_err_msg
                        , iv_token_name1   => cv_tkn_lookup_type
                        , iv_token_value1  => ct_qct_acnt_title_cd
                       );
          lv_errbuf := lv_errmsg;
          RAISE non_lookup_value_expt;
      END;
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
/* 2010/03/01 Ver1.13 Add Start */
      --==================================
      -- XXCOS:�l���i��
      --==================================
      gt_discount_item_code := FND_PROFILE.VALUE( ct_discount_item_cd );
--
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      IF ( gt_discount_item_code IS NULL ) THEN
        lv_profile_name := xxccp_common_pkg.get_msg(
           iv_application => cv_xxcos_short_nm                -- �A�v���P�[�V�����Z�k��
          ,iv_name        => cv_pf_discount_item_code         -- ���b�Z�[�WID
        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_pro_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => lv_profile_name
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
/* 2010/03/01 Ver1.13 Add End */
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    END IF;
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
--
  EXCEPTION
--
-- �N�C�b�N�R�[�h�擾�G���[
    WHEN non_lookup_value_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
--##################################  �Œ��O�������� END ####################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'get_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_table_name VARCHAR2(255);            -- �e�[�u����
--
    -- *** ���[�J���E�J�[�\�� (�̔����уf�[�^���o)***
--****************************** 2009/05/13 1.6 MOD START ******************************--
--    CURSOR sales_data_cur
--    IS
--      SELECT
--             xseh.sales_exp_header_id          sales_exp_header_id      -- �̔����уw�b�_ID
--           , xseh.dlv_invoice_number           dlv_invoice_number       -- �[�i�`�[�ԍ�
--           , xseh.dlv_invoice_class            dlv_invoice_class        -- �[�i�`�[�敪
--           , xseh.cust_gyotai_sho              cust_gyotai_sho          -- �Ƒԏ�����
--           , xseh.delivery_date                delivery_date            -- �[�i��
--           , xseh.inspect_date                 inspect_date             -- ������
--           , xseh.ship_to_customer_code        ship_to_customer_code    -- �ڋq�y�[�i��z
--           , xseh.tax_code                     tax_code                 -- �ŋ��R�[�h
--           , xseh.tax_rate                     tax_rate                 -- ����ŗ�
--           , xseh.consumption_tax_class        consumption_tax_class    -- ����敪
--           , xseh.results_employee_code        results_employee_code    -- ���ьv��҃R�[�h
--           , xseh.sales_base_code              sales_base_code          -- ���㋒�_�R�[�h
--           , NVL( xseh.card_sale_class, cv_cash_class )
--                                               card_sale_class          -- �J�[�h����敪
--           , xsel.sales_class                  sales_class              -- ����敪
--           , xgpc.goods_prod_class_code        goods_prod_cls           -- �i�ڋ敪�R�[�h�i���i�E���i�j
--           , xsel.pure_amount                  pure_amount              -- �{�̋��z
--           , xsel.tax_amount                   tax_amount               -- ����ŋ��z
--           , NVL( xsel.cash_and_card, 0 )      cash_and_card            -- �����E�J�[�h���p�z
--           , hca.customer_class_code           customer_cls_code        -- �ڋq�敪
--           , gcc.segment3                      gccs_segment3            -- ���㊨��ȖڃR�[�h
--           , gcct.segment3                     gcct_segment3            -- �ŋ�����ȖڃR�[�h
--           , xchv.bill_tax_round_rule          tax_round_rule           -- �ŋ��|�[������
--           , xseh.rowid                        xseh_rowid               -- ROWID
--      FROM
--             xxcos_sales_exp_headers           xseh                     -- �̔����уw�b�_�e�[�u��
--           , xxcos_sales_exp_lines             xsel                     -- �̔����і��׃e�[�u��
--           , mtl_system_items_b                msib                     -- �i�ڃ}�X�^
--           , gl_code_combinations              gcc                      -- ����Ȗڑg�����}�X�^
--           , gl_code_combinations              gcct                     -- ����Ȗڑg�����}�X�^�iTAX�p�j
--           , ar_vat_tax_all_b                  avta                     -- �ŋ��}�X�^
--           , xxcos_good_prod_class_v           xgpc                     -- �i�ڋ敪View
--           , hz_cust_accounts                  hca                      -- �ڋq�敪
--           , xxcos_cust_hierarchy_v            xchv                     -- �ڋq�K�w�r���[
--      WHERE
--          xseh.sales_exp_header_id             = xsel.sales_exp_header_id
--      AND xseh.dlv_invoice_number              = xsel.dlv_invoice_number
--      AND xseh.gl_interface_flag               = cv_n_flag
--      AND xseh.inspect_date                   <= gd_process_date
--      AND xsel.item_code                      <> gv_var_elec_item_cd
--      AND hca.account_number                   = xseh.ship_to_customer_code
--      AND xchv.ship_account_number             = xseh.ship_to_customer_code
--      AND ( xseh.cust_gyotai_sho                 IN (
--            SELECT
--                flvl.meaning                   meaning
--            FROM
--                fnd_lookup_values              flvl
--            WHERE
--                flvl.lookup_type               = ct_qct_gyotai_sho
--            AND flvl.lookup_code               LIKE ct_qcc_code
--            AND flvl.attribute1                = ct_attribute_y
--            AND flvl.enabled_flag              = ct_enabled_yes
--            AND flvl.language                  = USERENV( 'LANG' )
--            AND gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
--                                AND            NVL( flvl.end_date_active,   gd_process_date )
--            )
--            OR hca.customer_class_code          = gt_cust_cls_cd
--          )
--      AND xsel.sales_class                     NOT IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_sale_class
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND xseh.dlv_invoice_class               IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_dlv_slp_cls
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND msib.organization_id                 = gv_org_id
--      AND xsel.item_code                       = msib.segment1
--      AND avta.tax_code                        = xseh.tax_code
--      AND gcct.code_combination_id             = avta.tax_account_id
--      AND avta.set_of_books_id                 = TO_NUMBER( gv_set_bks_id )
--      AND avta.enabled_flag                    = ct_enabled_yes
--      AND gd_process_date BETWEEN              NVL( avta.start_date, gd_process_date )
--                          AND                  NVL( avta.end_date,   gd_process_date )
--      AND gcc.code_combination_id              = msib.sales_account
--      AND xgpc.segment1                        = xsel.item_code
--      ORDER BY xseh.dlv_invoice_number
--             , xseh.dlv_invoice_class
--             , NVL( xseh.card_sale_class, cv_cash_class )
--             , xsel.item_code
--             , gcc.segment3
--             , xseh.tax_code
--    FOR UPDATE OF  xseh.sales_exp_header_id
--    NOWAIT;
--
--****************************** 2009/09/14 1.9 Atsushiba  Del START ******************************--
--    CURSOR sales_data_cur
--    IS
--      SELECT
--            /*+ LEADING(xseh)
--                INDEX(xseh xxcos_sales_exp_headers_n05 )
--                USE_NL(xseh xsel msib )
--                USE_NL(xseh hca avta gcct )
--                USE_NL(xseh xchv)
--             */
--             xseh.sales_exp_header_id          sales_exp_header_id      -- �̔����уw�b�_ID
--           , xseh.dlv_invoice_number           dlv_invoice_number       -- �[�i�`�[�ԍ�
--           , xseh.dlv_invoice_class            dlv_invoice_class        -- �[�i�`�[�敪
--           , xseh.cust_gyotai_sho              cust_gyotai_sho          -- �Ƒԏ�����
--           , xseh.delivery_date                delivery_date            -- �[�i��
--           , xseh.inspect_date                 inspect_date             -- ������
--           , xseh.ship_to_customer_code        ship_to_customer_code    -- �ڋq�y�[�i��z
--           , xseh.tax_code                     tax_code                 -- �ŋ��R�[�h
--           , xseh.tax_rate                     tax_rate                 -- ����ŗ�
--           , xseh.consumption_tax_class        consumption_tax_class    -- ����敪
--           , xseh.results_employee_code        results_employee_code    -- ���ьv��҃R�[�h
--           , xseh.sales_base_code              sales_base_code          -- ���㋒�_�R�[�h
--           , NVL( xseh.card_sale_class, cv_cash_class )
--                                               card_sale_class          -- �J�[�h����敪
--           , xsel.sales_class                  sales_class              -- ����敪
--           , xsel.pure_amount                  pure_amount              -- �{�̋��z
--           , xsel.tax_amount                   tax_amount               -- ����ŋ��z
--           , NVL( xsel.cash_and_card, 0 )      cash_and_card            -- �����E�J�[�h���p�z
--           , xsel.red_black_flag               red_black_flag           -- �ԍ��t���O
--           , hca.customer_class_code           customer_cls_code        -- �ڋq�敪
--           , gcct.segment3                     gcct_segment3            -- �ŋ�����ȖڃR�[�h
--           , xchv.bill_tax_round_rule          tax_round_rule           -- �ŋ��|�[������
--           , xseh.rowid                        xseh_rowid               -- ROWID
--      FROM
--             xxcos_sales_exp_headers           xseh                     -- �̔����уw�b�_�e�[�u��
--           , xxcos_sales_exp_lines             xsel                     -- �̔����і��׃e�[�u��
--           , mtl_system_items_b                msib                     -- �i�ڃ}�X�^
--           , gl_code_combinations              gcct                     -- ����Ȗڑg�����}�X�^�iTAX�p�j
--           , ar_vat_tax_all_b                  avta                     -- �ŋ��}�X�^
--           , hz_cust_accounts                  hca                      -- �ڋq�敪
--           , xxcos_cust_hierarchy_v            xchv                     -- �ڋq�K�w�r���[
--      WHERE
--          xseh.sales_exp_header_id             = xsel.sales_exp_header_id
--      AND xseh.dlv_invoice_number              = xsel.dlv_invoice_number
--      AND xseh.gl_interface_flag               = cv_n_flag
--      AND xseh.inspect_date                   <= gd_process_date
--      AND xsel.item_code                      <> gv_var_elec_item_cd
--      AND hca.account_number                   = xseh.ship_to_customer_code
--      AND xchv.ship_account_number             = xseh.ship_to_customer_code
--      AND ( xseh.cust_gyotai_sho                 IN (
--            SELECT
--                flvl.meaning                   meaning
--            FROM
--                fnd_lookup_values              flvl
--            WHERE
--                flvl.lookup_type               = ct_qct_gyotai_sho
--            AND flvl.lookup_code               LIKE ct_qcc_code
--            AND flvl.attribute1                = ct_attribute_y
--            AND flvl.enabled_flag              = ct_enabled_yes
--            AND flvl.language                  = USERENV( 'LANG' )
--            AND gd_process_date BETWEEN        NVL( flvl.start_date_active, gd_process_date )
--                                AND            NVL( flvl.end_date_active,   gd_process_date )
--            )
--            OR hca.customer_class_code          = gt_cust_cls_cd
--          )
--      AND xsel.sales_class                     NOT IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_sale_class
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND xseh.dlv_invoice_class               IN (
--          SELECT
--              flvl.meaning                     meaning
--          FROM
--              fnd_lookup_values                flvl
--          WHERE
--              flvl.lookup_type                 = ct_qct_dlv_slp_cls
--          AND flvl.lookup_code                 LIKE ct_qcc_code
--          AND flvl.attribute1                  = ct_attribute_y
--          AND flvl.enabled_flag                = ct_enabled_yes
--          AND flvl.language                    = USERENV( 'LANG' )
--          AND gd_process_date BETWEEN          NVL( flvl.start_date_active, gd_process_date )
--                              AND              NVL( flvl.end_date_active,   gd_process_date )
--          )
--      AND msib.organization_id                 = gv_org_id
--      AND xsel.item_code                       = msib.segment1
--      AND avta.tax_code                        = xseh.tax_code
--      AND gcct.code_combination_id             = avta.tax_account_id
--      AND avta.set_of_books_id                 = TO_NUMBER( gv_set_bks_id )
--      AND avta.enabled_flag                    = ct_enabled_yes
--      ORDER BY xseh.sales_exp_header_id
--    FOR UPDATE OF  xseh.sales_exp_header_id
--    NOWAIT;
----****************************** 2009/05/13 1.6 MOD  END  ******************************--
--****************************** 2009/09/14 1.9 Atsushiba  DEL END ******************************--
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN  sales_data_cur;
--****************************** 2009/09/14 1.9 Atsushiba  DEL START ******************************--
--    FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_tbl;
----
--    -- �Ώۏ�������
--    gn_target_cnt   := gt_sales_exp_tbl.COUNT;
----
--    -- �J�[�\���N���[�Y
--    CLOSE sales_data_cur;
--****************************** 2009/09/14 1.9 Atsushiba  DEL END ******************************--
--
  EXCEPTION
--****************************** 2009/09/14 1.9 Atsushiba  DEL START ******************************--
--    -- ���b�N�G���[
--    WHEN lock_expt THEN
----      lv_table_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
--                         , iv_name        => cv_tkn_sales_msg                -- ���b�Z�[�WID
--                       );
--      lv_errmsg     := xxccp_common_pkg.get_msg(
--                           iv_application   => cv_xxcos_short_nm
--                         , iv_name          => cv_table_lock_msg
--                         , iv_token_name1   => cv_tkn_tbl
--                         , iv_token_value1  => lv_table_name
--                       );
--      lv_errbuf     := lv_errmsg;
--      ov_errmsg     := lv_errmsg;
--      ov_errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode    := cv_status_error;
--****************************** 2009/09/14 1.9 Atsushiba  DEL END ******************************--
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_nm
                      , iv_name         => cv_data_get_msg
                    );
      lv_errbuf  := lv_errmsg;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /***********************************************************************************
   * Procedure Name   : edit_gl_data
   * Description      : ��ʉ�vOIF�d��쐬(A-4)
   ***********************************************************************************/
  PROCEDURE edit_gl_data(
      ov_errbuf         OUT VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , in_gl_idx         IN  NUMBER           -- GL OIF �f�[�^�C���f�b�N�X
    , in_sale_idx       IN  NUMBER           -- �̔����уf�[�^�C���f�b�N�X
    , iv_card_flg       IN  VARCHAR2         -- �d��t���O
    , in_card_idx       IN  NUMBER           -- �J�[�h�f�[�^�C���f�b�N�X
    , in_jcls_idx       IN  NUMBER           -- �d��p�^�[���C���f�b�N�X
    , iv_gl_segment3    IN  VARCHAR2         -- ����ȖڃR�[�h
    , in_entered_dr     IN  NUMBER           -- �ؕ����z
    , in_entered_cr     IN  NUMBER           -- �ݕ����z
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_gl_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                  -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_user_je_source_name  VARCHAR2(225);    -- �̔�����(�d��\�[�X��)
    lv_ccid_idx             VARCHAR2(225);    -- �Z�O�����g�P0�W�̌����iCCID�C���f�b�N�X�p�j
    lv_tbl_nm               VARCHAR2(225);    -- ����Ȗڑg�����}�X�^�e�[�u��
    lv_vd_nm                VARCHAR2(225);    -- �d��
    lv_detail               VARCHAR2(225);    -- ���דE�v
    lv_om_sales             VARCHAR2(225);    -- OM�A�g����
--****************************** 209/05/13 1.6 T.Kitajima ADD START ******************************--
    lv_section_code         VARCHAR2(225);    -- ����R�[�h
    lv_category_name        VARCHAR2(225);    -- �d��J�e�S����
--****************************** 209/05/13 1.6 T.Kitajima ADD  END  ******************************--
--
    -- *** ���[�J����O ***
    non_ccid_expt           EXCEPTION;        -- CCID�擾�o���Ȃ��G���[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_ccid                 gl_code_combinations.code_combination_id%TYPE;
                                              -- CCID
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
    --  ��ʉ�vOIF�d��쐬(A-4)
    --==============================================================
--
    -- ������擾
    -- �P�D�d��\�[�X��
    lv_user_je_source_name := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                , iv_name              => cv_source_nm_msg        -- ���b�Z�[�WID
                              );
--
    -- �Q�DOM�A�g����
    lv_om_sales            := xxccp_common_pkg.get_msg(
                                  iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                , iv_name              => cv_om_sales             -- ���b�Z�[�WID
                              );
--
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    -- �R�D��l�̏ꍇ�A�d�󖼁A���דE�v�擾
--    IF ( iv_card_flg = cv_y_flag ) THEN
--      -- ���������J�[�h���R�[�h�̏ꍇ
--      IF ( gt_sales_card_tbl ( in_card_idx ).customer_cls_code = gt_cust_cls_cd ) THEN
--        -- �d��:��l��������
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_cust_cash_sale       -- ���b�Z�[�WID
--                                );
--        -- ���דE�v�F��l����
--        lv_detail            := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_cust_cash            -- ���b�Z�[�WID
--                                );
--      END IF;
----
--      -- �S�D�t��VD�i�����j����̏ꍇ�A�d�󖼁A���דE�v�擾
--      IF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho = ct_full_vd_cd ) THEN
--        -- �t��VD
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_full_vd              -- ���b�Z�[�WID
--                                );
--        -- �t��VD�J�[�h
--        lv_detail          := xxccp_common_pkg.get_msg(
--                                  iv_application       => cv_xxcos_short_nm          -- �A�v���P�[�V�����Z�k��
--                                , iv_name              => cv_full_vd_card            -- ���b�Z�[�WID
--                              );
--      ELSIF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho = ct_vd_xiaoka_cd ) THEN
--        -- �t��VD�i�����j����
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_vd_xiaoka            -- ���b�Z�[�WID
--                                );
--        -- �t��VD�i�����j�J�[�h
--        lv_detail          := xxccp_common_pkg.get_msg(
--                                  iv_application       => cv_xxcos_short_nm         -- �A�v���P�[�V�����Z�k��
--                                , iv_name              => cv_vd_xiaoka_card         -- ���b�Z�[�WID
--                            );
--      END IF;
--    ELSE
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd ) THEN
--        -- �d��:��l��������
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_cust_cash_sale       -- ���b�Z�[�WID
--                                );
--        -- ���דE�v�F��l����
--        lv_detail            := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_cust_cash            -- ���b�Z�[�WID
--                                );
--      END IF;
----
--      -- �S�D�t��VD�i�����j����̏ꍇ�A�d�󖼁A���דE�v�擾
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho = ct_full_vd_cd ) THEN
--        -- �t��VD
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_full_vd              -- ���b�Z�[�WID
--                                );
--        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
--        -- �J�[�h����̏ꍇ�F�t��VD�J�[�h
--        lv_detail          := xxccp_common_pkg.get_msg(
--                                  iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                , iv_name              => cv_full_vd_card         -- ���b�Z�[�WID
--                              );
--        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
--          -- ��������̏ꍇ�F�t��VD����
--          lv_detail          := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_full_vd_cash         -- ���b�Z�[�WID
--                              );
--        END IF;
--      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho = ct_vd_xiaoka_cd ) THEN
--        -- �t��VD�i�����j����
--        lv_vd_nm             := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_vd_xiaoka            -- ���b�Z�[�WID
--                                );
--        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
--          -- �J�[�h����̏ꍇ�F�t��VD�i�����j�J�[�h
--          lv_detail          := xxccp_common_pkg.get_msg(
--                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                  , iv_name              => cv_vd_xiaoka_card       -- ���b�Z�[�WID
--                              );
--        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
--          -- ��������̏ꍇ�F�t��VD�i�����j����
--            lv_detail          := xxccp_common_pkg.get_msg(
--                                      iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
--                                    , iv_name              => cv_vd_xiaoka_cash       -- ���b�Z�[�WID
--                                );
--        END IF;
--      END IF;
--    END IF;
--
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--    --�d��J�e�S����
--    --��l�ڋq AND �{�̎d�� AND �t��VD�ȊO AND �t��VD�i�����j�ȊO AND ����
--    IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
    --�d��J�e�S����
    --�[�i�`�[�敪�F�ԕi or �ԕi����
    IF ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return            ) OR
       ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return_correction )
    THEN
      lv_category_name  := xxccp_common_pkg.get_msg(
                              iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                            , iv_name              => cv_cust_cash_sale       -- ���b�Z�[�WID
                           );
    --��l�ڋq AND �{�̎d�� AND �t��VD�ȊO AND �t��VD�i�����j�ȊO AND ����
    ELSIF
       ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
       ( iv_card_flg                                        = cv_n_flag       ) AND
       ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_full_vd_cd   ) AND
       ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_vd_xiaoka_cd ) AND
       ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class   = cv_cash_class   )
    THEN
        -- �d��:��l��������
      lv_category_name  := xxccp_common_pkg.get_msg(
                              iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                            , iv_name              => cv_cust_cash_sale       -- ���b�Z�[�WID
                           );
    --���p�J�[�h�A�J�[�h�A�t��VD�A�t��VD�i�����j�͂�����
    ELSE
      lv_category_name  := gt_jour_cls_tbl( in_jcls_idx ).jour_category;
    END IF;
--
    --�d��
    --���p�J�[�h�d��(���p�ŏ�l�͖����O��)
    IF ( iv_card_flg = cv_y_flag  ) THEN
      --�t��VD
      IF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        lv_vd_nm        := xxccp_common_pkg.get_msg(
                               iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                             , iv_name              => cv_full_vd              -- ���b�Z�[�WID
                           );
      --�t��VD�i�����j
      ELSIF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        lv_vd_nm        := xxccp_common_pkg.get_msg(
                               iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                             , iv_name              => cv_vd_xiaoka            -- ���b�Z�[�WID
                           );
      END IF;
    --�{�̎d��
    ELSE
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--      --��l�ڋq�Ō����̂݁B���t��VD�A�t��VD�i�����j�ł͖����B
--      --�J�[�h�ŏ�l�͖����O��
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
      --�[�i�`�[�敪�F�ԕi or �ԕi����
      IF ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return            ) OR
         ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return_correction )
      THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_cust_cash_sale       -- ���b�Z�[�WID
                                );
      --��l�ڋq�Ō����̂݁B���t��VD�A�t��VD�i�����j�ł͖����B
      --�J�[�h�ŏ�l�͖����O��
      ELSIF
         ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_full_vd_cd   ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_vd_xiaoka_cd ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class   = cv_cash_class   )
      THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_cust_cash_sale       -- ���b�Z�[�WID
                                );
      --�t��VD
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_full_vd              -- ���b�Z�[�WID
                                );
      --�t��VD�i�����j
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        lv_vd_nm             := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_vd_xiaoka            -- ���b�Z�[�WID
                                );
      END IF;
    END IF;
--
    --�d�󖾍דE�v
    --���p�J�[�h�d��
    IF ( iv_card_flg = cv_y_flag  ) THEN
      --�t��VD�J�[�h
      IF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_full_vd_card         -- ���b�Z�[�WID
                                );
      --�t��VD�i�����j�J�[�h
      ELSIF ( gt_sales_card_tbl ( in_card_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_vd_xiaoka_card       -- ���b�Z�[�WID
                                );
      END IF;
    --�{�̎d��
    ELSE
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--      --��l�ڋq�Ō����̂݁B���t��VD�A�t��VD�i�����j�ł͖����B
--      --�J�[�h�ŏ�l�͖����O��
--      IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
      --�[�i�`�[�敪�F�ԕi or �ԕi����
      IF ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return            ) OR
         ( gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_class = cv_dic_return_correction )
      THEN
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_cust_cash            -- ���b�Z�[�WID
                                );
      --��l�ڋq�Ō����̂݁B���t��VD�A�t��VD�i�����j�ł͖����B
      --�J�[�h�ŏ�l�͖����O��
      ELSIF 
         ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd  ) AND
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_full_vd_cd   ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  != ct_vd_xiaoka_cd ) AND
         ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class   = cv_cash_class   )
      THEN
        -- ���דE�v�F��l����
        lv_detail            := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_cust_cash            -- ���b�Z�[�WID
                                );
      --�t��VD
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_full_vd_cd ) THEN
        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
          -- �J�[�h����̏ꍇ�F�t��VD�J�[�h
          lv_detail          := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_full_vd_card         -- ���b�Z�[�WID
                                );
        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
          -- ��������̏ꍇ�F�t��VD����
          lv_detail          := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_full_vd_cash         -- ���b�Z�[�WID
                              );
        END IF;
      --�t��VD�i�����j
      ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).cust_gyotai_sho  = ct_vd_xiaoka_cd ) THEN
        IF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_card_class ) THEN
          -- �J�[�h����̏ꍇ�F�t��VD�i�����j�J�[�h
          lv_detail          := xxccp_common_pkg.get_msg(
                                    iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                  , iv_name              => cv_vd_xiaoka_card       -- ���b�Z�[�WID
                              );
        ELSIF ( gt_sales_exp_tbl ( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
          -- ��������̏ꍇ�F�t��VD�i�����j����
            lv_detail          := xxccp_common_pkg.get_msg(
                                      iv_application       => cv_xxcos_short_nm       -- �A�v���P�[�V�����Z�k��
                                    , iv_name              => cv_vd_xiaoka_cash       -- ���b�Z�[�WID
                                );
        END IF;
      END IF;
    END IF;
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--****************************** 2009/05/13 1.6 T.Kitajima ADD START ******************************--
    --���_�R�[�h
    lv_section_code := NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2, gt_sales_exp_tbl( in_sale_idx ).sales_base_code);
--****************************** 2009/05/13 1.6 T.Kitajima ADD  END  ******************************--
--
    -- ����ȖڃZ�O�����g�P����Z�O�����g�W���CCID�擾
    lv_ccid_idx            :=   gv_company_code
                                                               -- �Z�O�����g�P(��ЃR�[�h)
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--                             || NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                                                               -- �Z�O�����g�Q�i����R�[�h�j
--                                     gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
--                                                               -- �Z�O�����g�Q(�̔����т̔��㋒�_�R�[�h)
                             || lv_section_code                  -- �Z�O�����g�Q(���_�R�[�h)
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
                             || iv_gl_segment3
                                                               -- �Z�O�����g�R(����ȖڃR�[�h)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment4
                                                               -- �Z�O�����g�S(�⏕�ȖڃR�[�h:�����̂ݐݒ�)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment5
                                                               -- �Z�O�����g�T(�ڋq�R�[�h)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment6
                                                               -- �Z�O�����g�U(��ƃR�[�h)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment7
                                                               -- �Z�O�����g�V(�\��)
                             || gt_jour_cls_tbl( in_jcls_idx ).segment8;
                                                               -- �Z�O�����g�W(�\��)
--
    -- CCID�̑��݃`�F�b�N-->���݂��Ă���ꍇ�A�擾�K�v���Ȃ�
    IF ( gt_sel_ccid_tbl.EXISTS(  lv_ccid_idx ) ) THEN
      lt_ccid := gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id;
    ELSE
      -- CCID�擾���ʊ֐����CCID���擾����
      lt_ccid := xxcok_common_pkg.get_code_combination_id_f (
--****************************** 2009/08/25 1.8 M.Sano     MOD START ******************************--
--                     gd_process_date
                     gt_sales_exp_tbl( in_sale_idx ).delivery_date
--****************************** 2009/08/25 1.8 M.Sano     MOD  END  ******************************--
                   , gv_company_code
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--                   , NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                          gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
                   , lv_section_code
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
                   , iv_gl_segment3
                   , gt_jour_cls_tbl( in_jcls_idx ).segment4
                   , gt_jour_cls_tbl( in_jcls_idx ).segment5
                   , gt_jour_cls_tbl( in_jcls_idx ).segment6
                   , gt_jour_cls_tbl( in_jcls_idx ).segment7
                   , gt_jour_cls_tbl( in_jcls_idx ).segment8
                 );
      IF ( lt_ccid IS NULL ) THEN
        -- CCID���擾�ł��Ȃ��ꍇ
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application       => cv_xxcos_short_nm
                        , iv_name              => cv_ccid_nodata_msg
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--                        , iv_token_name1       => cv_tkn_segment1
--                        , iv_token_value1      => gv_company_code
--                        , iv_token_name2       => cv_tkn_segment2
--                        , iv_token_value2      => NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                                                       gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
--                        , iv_token_name3       => cv_tkn_segment3
--                        , iv_token_value3      => iv_gl_segment3
--                        , iv_token_name4       => cv_tkn_segment4
--                        , iv_token_value4      => gt_jour_cls_tbl( in_jcls_idx ).segment4
--                        , iv_token_name5       => cv_tkn_segment5
--                        , iv_token_value5      => gt_jour_cls_tbl( in_jcls_idx ).segment5
--                        , iv_token_name6       => cv_tkn_segment6
--                        , iv_token_value6      => gt_jour_cls_tbl( in_jcls_idx ).segment6
--                        , iv_token_name7       => cv_tkn_segment7
--                        , iv_token_value7      => gt_jour_cls_tbl( in_jcls_idx ).segment7
--                        , iv_token_name8       => cv_tkn_segment8
--                        , iv_token_value8      => gt_jour_cls_tbl( in_jcls_idx ).segment8
                        , iv_token_name1       => cv_tkn_segment1
                        , iv_token_value1      => gt_sales_exp_tbl( in_sale_idx ).dlv_invoice_number
                        , iv_token_name2       => cv_tkn_segment2
                        , iv_token_value2      => gv_company_code
                        , iv_token_name3       => cv_tkn_segment3
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--                        , iv_token_value3      => NVL( gt_jour_cls_tbl( in_jcls_idx ).segment2,
--                                                       gt_sales_exp_tbl( in_sale_idx ).sales_base_code )
                        , iv_token_value3      => lv_section_code
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
                        , iv_token_name4       => cv_tkn_segment4
                        , iv_token_value4      => iv_gl_segment3
                        , iv_token_name5       => cv_tkn_segment5
                        , iv_token_value5      => gt_jour_cls_tbl( in_jcls_idx ).segment4
                        , iv_token_name6       => cv_tkn_segment6
                        , iv_token_value6      => gt_jour_cls_tbl( in_jcls_idx ).segment5
                        , iv_token_name7       => cv_tkn_segment7
                        , iv_token_value7      => gt_jour_cls_tbl( in_jcls_idx ).segment6
                        , iv_token_name8       => cv_tkn_segment8
                        , iv_token_value8      => gt_jour_cls_tbl( in_jcls_idx ).segment7
                        , iv_token_name9       => cv_tkn_segment9
                        , iv_token_value9      => gt_jour_cls_tbl( in_jcls_idx ).segment8
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
                      );
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--****************************** 2009/08/25 1.8 M.Sano     ADD START ******************************--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
--****************************** 2009/08/25 1.8 M.Sano     ADD  END  ******************************--
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
        lv_errbuf  := lv_errmsg;
        RAISE non_ccid_expt;
      END IF;
--
      -- �擾����CCID�����[�N�e�[�u���ɐݒ肷��
      gt_sel_ccid_tbl( lv_ccid_idx ).code_combination_id := lt_ccid;
--
    END IF;
--
    -- ��ʉ�vOIF�̒l�Z�b�g
    gt_gl_interface_tbl( in_gl_idx ).status                := ct_status;
                                                              -- �X�e�[�^�X
    gt_gl_interface_tbl( in_gl_idx ).set_of_books_id       := gv_set_bks_id;
                                                              -- ��v����ID
    gt_gl_interface_tbl( in_gl_idx ).currency_code         := ct_currency_code;
                                                              -- �ʉ݃R�[�h
    gt_gl_interface_tbl( in_gl_idx ).actual_flag           := ct_actual_flag;
                                                              -- �c���^�C�v
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    IF ( gt_sales_exp_tbl ( in_sale_idx ).customer_cls_code = gt_cust_cls_cd ) THEN
--      gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := lv_vd_nm;
--                                                              -- �d��J�e�S����
--    ELSE
--      gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := gt_jour_cls_tbl( in_jcls_idx ).jour_category;
--                                                              -- �d��J�e�S����
--    END IF;
    gt_gl_interface_tbl( in_gl_idx ).user_je_category_name := lv_category_name;
--****************************** 2009/05/13 1.6 T.Kitajima MOD  MOD  ******************************--
    gt_gl_interface_tbl( in_gl_idx ).user_je_source_name   := lv_user_je_source_name;
                                                              -- �d��\�[�X��
    gt_gl_interface_tbl( in_gl_idx ).code_combination_id   := lt_ccid;
                                                              -- CCID
    gt_gl_interface_tbl( in_gl_idx ).entered_dr            := in_entered_dr;
                                                              -- �ؕ����z
    gt_gl_interface_tbl( in_gl_idx ).entered_cr            := in_entered_cr;
                                                              -- �ݕ����z
    gt_gl_interface_tbl( in_gl_idx ).reference1            := TO_CHAR( gd_process_date , ct_date_format_non_sep )
                                                              || ct_underbar
                                                              || lv_om_sales;
                                                              -- ���t�@�����X1�i�o�b�`���j
    gt_gl_interface_tbl( in_gl_idx ).reference2            := TO_CHAR( gd_process_date , ct_date_format_non_sep )
                                                              || ct_underbar
                                                              || lv_om_sales;
                                                              -- ���t�@�����X2�i�o�b�`�E�v�j
--
    IF ( iv_card_flg = cv_y_flag ) THEN
    -- ���������J�[�h���R�[�h�̏ꍇ
      gt_gl_interface_tbl( in_gl_idx ).accounting_date     := gt_sales_card_tbl ( in_card_idx ).delivery_date;
                                                              -- �L����
      gt_gl_interface_tbl( in_gl_idx ).reference4          :=    gt_sales_card_tbl ( in_card_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_card_tbl ( in_card_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- ���t�@�����X4�i�d�󖼁j
      gt_gl_interface_tbl( in_gl_idx ).reference5          :=    gt_sales_card_tbl ( in_card_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_card_tbl ( in_card_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- ���t�@�����X5�i�d�󖼓E�v�j
      gt_gl_interface_tbl( in_gl_idx ).attribute1          := gt_sales_card_tbl ( in_card_idx ).tax_code;
                                                              -- ����1�i����ŃR�[�h�j
      gt_gl_interface_tbl( in_gl_idx ).attribute3          := gt_sales_card_tbl ( in_card_idx ).dlv_invoice_number;
                                                              -- ����3�i�`�[�ԍ��j
      gt_gl_interface_tbl( in_gl_idx ).attribute4          := gt_sales_card_tbl ( in_card_idx ).sales_base_code;
                                                              -- ����4�i�N�[����j
      gt_gl_interface_tbl( in_gl_idx ).attribute5          := gt_sales_card_tbl ( in_card_idx ).results_employee_code;
                                                              -- ����5�i���[�UID�j
--****************************** 2012/08/15 1.14 T.Osawa ADD START ******************************--
      gt_gl_interface_tbl( in_gl_idx ).attribute8          := gt_sales_card_tbl ( in_card_idx ).sales_exp_header_id;
                                                              -- ����8�i�̔����уw�b�_ID�j
--****************************** 2012/08/15 1.14 T.Osawa ADD  END  ******************************--
    ELSE
      gt_gl_interface_tbl( in_gl_idx ).accounting_date     := gt_sales_exp_tbl ( in_sale_idx ).delivery_date;
                                                              -- �L����
      gt_gl_interface_tbl( in_gl_idx ).reference4          := gt_sales_exp_tbl ( in_sale_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- ���t�@�����X4�i�d�󖼁j
      gt_gl_interface_tbl( in_gl_idx ).reference5          := gt_sales_exp_tbl ( in_sale_idx ).sales_base_code
                                                              || ct_underbar
                                                              || gt_sales_exp_tbl ( in_sale_idx ).dlv_invoice_number
                                                              || ct_underbar
                                                              || lv_vd_nm;
                                                              -- ���t�@�����X5�i�d�󖼓E�v�j
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
--      gt_gl_interface_tbl( in_gl_idx ).attribute1          := gt_sales_exp_tbl( in_sale_idx ).tax_code;
--                                                              -- ����1�i����ŃR�[�h�j
      IF ( iv_gl_segment3 = gt_segment3_cash ) THEN
        gt_gl_interface_tbl( in_gl_idx ).attribute1        := ct_tax_code_null;
      ELSE
        gt_gl_interface_tbl( in_gl_idx ).attribute1        := gt_sales_exp_tbl( in_sale_idx ).tax_code;
      END IF;
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
      gt_gl_interface_tbl( in_gl_idx ).attribute3          := gt_sales_exp_tbl( in_sale_idx ).dlv_invoice_number;
                                                              -- ����3�i�`�[�ԍ��j
      gt_gl_interface_tbl( in_gl_idx ).attribute4          := gt_sales_exp_tbl( in_sale_idx ).sales_base_code;
                                                              -- ����4�i�N�[����j
      gt_gl_interface_tbl( in_gl_idx ).attribute5          := gt_sales_exp_tbl( in_sale_idx ).results_employee_code;
                                                              -- ����5�i���[�UID�j
      IF ( gt_sales_exp_tbl( in_sale_idx ).card_sale_class = cv_cash_class ) THEN
        gt_gl_interface_tbl( in_gl_idx ).jgzz_recon_ref    := gt_sales_exp_tbl( in_sale_idx ).ship_to_customer_code;
                                                              -- �����Q��(��������̂�)
      END IF;
--****************************** 2012/08/15 1.14 T.Osawa ADD START ******************************--
      gt_gl_interface_tbl( in_gl_idx ).attribute8          := gt_sales_exp_tbl ( in_sale_idx ).sales_exp_header_id;
                                                              -- ����8�i�̔����уw�b�_ID�j
--****************************** 2012/08/15 1.14 T.Osawa ADD  END  ******************************--
    END IF;
--
    gt_gl_interface_tbl( in_gl_idx ).reference10           := lv_detail;
                                                              -- ���t�@�����X10�i�d�󖾍דE�v�j
    gt_gl_interface_tbl( in_gl_idx ).group_id              := ct_group_id;
                                                              -- �O���[�vID
    gt_gl_interface_tbl( in_gl_idx ).context               := gv_set_bks_nm;
                                                              -- �R���e�L�X�g
    gt_gl_interface_tbl( in_gl_idx ).created_by            := cn_created_by;
                                                              -- �V�K�쐬��
    gt_gl_interface_tbl( in_gl_idx ).date_created          := cd_creation_date;
                                                              -- �V�K�쐬��
    gt_gl_interface_tbl( in_gl_idx ).request_id            := cn_request_id;
                                                              -- �v��ID
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN non_ccid_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--      ov_retcode := cv_status_error;
      ov_retcode := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
--
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
  END edit_gl_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_work_data
   * Description      : ��ʉ�vOIF�W�񏈗�(A-3)
   ***********************************************************************************/
  PROCEDURE edit_work_data(
      ov_errbuf     OUT VARCHAR2            -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode    OUT VARCHAR2            -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg     OUT VARCHAR2 )          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'edit_work_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    ln_pure_amount     NUMBER DEFAULT 0;                                   -- �J�[�h���R�[�h�̖{�̋��z
    ln_tax_amount      NUMBER DEFAULT 0;                                   -- �J�[�h���R�[�h�̏���ŋ��z
    ln_gl_tax          NUMBER DEFAULT 0;                                   -- �W������ŋ��z
    ln_gl_amount       NUMBER DEFAULT 0;                                   -- �W�����z
    ln_gl_tax_card     NUMBER DEFAULT 0;                                   -- �W������ŋ��z(�J�[�h���R�[�h)
    ln_gl_amount_card  NUMBER DEFAULT 0;                                   -- �W�����z(�J�[�h���R�[�h)
    ln_gl_total        NUMBER DEFAULT 0;                                   -- �W���GL�ɋL�����z
    ln_gl_total_card   NUMBER DEFAULT 0;                                   -- �W���GL�ɋL�����z(�J�[�h���R�[�h)
    ln_entered_dr      NUMBER DEFAULT 0;                                   -- GL�ɋL�����z->�ؕ��s
    ln_entered_cr      NUMBER DEFAULT 0;                                   -- GL�ɋL�����z->�ݕ��s
    lt_gl_segment3     fnd_lookup_values.attribute4%TYPE;                  -- ����ȖڃR�[�h
--
    -- �C���f�b�N�X
    ln_card_idx        NUMBER DEFAULT 0;                                   -- �J�[�h���R�[�h�̃C���f�b�N�X
    ln_gl_idx          NUMBER DEFAULT 0;                                   -- GL OIF�̃C���f�b�N�X
    ln_card_pt         NUMBER DEFAULT 1;                                   -- �J�[�h���R�[�h�̌��|�C���g
    lv_ccid_idx        VARCHAR2(225);                                      -- CCID �̃C���f�b�N�X
    ln_card_jour       NUMBER DEFAULT 1;                                   -- �J�[�h���R�[�h�d��p
--******************************* 2009/03/26 1.4 T.Kitajima ADD START ****************************
    ln_index_work      NUMBER;
    ln_sale_idx        NUMBER;
    ln_index           NUMBER;
    sale_idx           NUMBER;
--******************************* 2009/03/26 1.4 T.Kitajima ADD  END  ****************************
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    ln_warn_ind        NUMBER;                                             -- �x���f�[�^index�p
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
/* 2010/03/01 Ver1.13 Add Start */
    ln_gl_discount_amount     NUMBER DEFAULT 0;       -- �l���̖{�̋��z
    ln_gl_discount_tax        NUMBER DEFAULT 0;       -- �l���̐Ŋz
/* 2010/03/01 Ver1.13 Add End */
--
    -- �W�v�L�[(�̔�����)
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    lt_invoice_number  xxcos_sales_exp_headers.dlv_invoice_number%TYPE;    -- �W�v�L�[�F�[�i�`�[�ԍ�
--    lt_invoice_class   xxcos_sales_exp_headers.dlv_invoice_class%TYPE;     -- �W�v�L�[�F�[�i�`�[�敪
--    lt_card_sale_class xxcos_sales_exp_headers.card_sale_class%TYPE;       -- �W�v�L�[�F�J�[�h����敪
--    lt_goods_prod_cls  xxcos_good_prod_class_v.goods_prod_class_code%TYPE; -- �W�v�L�[�F�i�ڋ敪�R�[�h�i���i�E���i�j
--    lt_gccs_segment3   gl_code_combinations.segment3%TYPE;                 -- �W�v�L�[�F���㊨��ȖڃR�[�h
--    lt_tax_code        xxcos_sales_exp_headers.tax_code%TYPE;              -- �W�v�L�[�F�ŋ��R�[�h
    lt_sales_exp_header_id  xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �W�v�L�[�F�̔����уw�b�_
--
    --�d��p�^�[���p
    lt_card_sale_class      xxcos_sales_exp_headers.card_sale_class%TYPE;     -- �J�[�h����敪
    lt_red_black_flag       xxcos_sales_exp_lines.red_black_flag%TYPE;        -- �ԍ��t���O
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    lt_dlv_invoice_class    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;   -- �[�i�`�[�敪
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
    lv_sum_flag        VARCHAR2(1);                                        -- �W�v�t���O
    lv_sum_card_flag   VARCHAR2(1);                                        -- �J�[�h�W�v�t���O
--
    -- �W�v�L�[(���������J�[�h���R�[�h)
 --****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    lt_invoice_number_card  xxcos_sales_exp_headers.dlv_invoice_number%TYPE;-- �W�v�L�[�F�[�i�`�[�ԍ�
--    lt_invoice_class_card   xxcos_sales_exp_headers.dlv_invoice_class%TYPE; -- �W�v�L�[�F�[�i�`�[�敪
--    lt_goods_prod_cls_card  xxcos_good_prod_class_v.goods_prod_class_code%TYPE;
--                                                                            -- �W�v�L�[�F�i�ڋ敪�i���i�E���i�j
--    lt_gccs_segment3_card   gl_code_combinations.segment3%TYPE;             -- �W�v�L�[�F���㊨��ȖڃR�[�h
--    lt_tax_code_card        xxcos_sales_exp_headers.tax_code%TYPE;          -- �W�v�L�[�F�ŋ��R�[�h
    lt_sales_exp_header_id_card  xxcos_sales_exp_headers.sales_exp_header_id%TYPE; -- �W�v�L�[�F�̔����уw�b�_
--
    --�d��p�^�[���p
    lt_red_black_flag_card       xxcos_sales_exp_lines.red_black_flag%TYPE;        -- �ԍ��t���O
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    lt_dlv_invoice_class_card    xxcos_sales_exp_headers.dlv_invoice_class%TYPE;    -- �[�i�`�[�敪
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--
    -- GL OIF�ɐݒ肷��l
    lv_enter_dr_msg    VARCHAR2(225);                                      -- �ؕ�
    lv_enter_cr_msg    VARCHAR2(225);                                      -- �ݕ�
    lv_cash_msg        VARCHAR2(225);                                      -- ����(����Ȗڗp)
    lv_vd_msg          VARCHAR2(225);                                      -- VD������������(����Ȗڗp)
    lv_tax_msg         VARCHAR2(225);                                      -- �������œ�(����Ȗڗp)
    lv_err_code        VARCHAR2(1);
--
--
--****************************** 2009/05/13 1.6 T.Kitajima ADD START ******************************--
    lnsale_idx_plus    NUMBER;                                             -- �̔����уf�[�^�����חp
--****************************** 2009/05/13 1.6 T.Kitajima ADD  END  ******************************--
--
    -- *** ���[�J���E�J�[�\�� �i�d��p�^�[���j***
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    CURSOR jour_cls_cur
--    IS
--      SELECT
--             flvl.attribute1              dlv_invoice_class                -- �[�i�`�[�敪
--           , flvl.attribute2              card_sale_class                  -- �J�[�h����敪
--           , flvl.attribute3              goods_prod_cls                   -- �i�ڋ敪�R�[�h�i���i�E���i�j
--           , flvl.attribute4              gl_segment3                      -- ����ȖڃR�[�h
--           , flvl.attribute5              gl_line_type                     -- ���C���^�C�v
--           , flvl.attribute6              gl_jour_category                 -- �d��J�e�S��
--           , flvl.attribute7              gl_segment2                      -- ����R�[�h
--           , flvl.meaning                 gl_jour_pattern                  -- �d��p�^�[��
--           , flvl.description             gl_segment3_nm                   -- ����Ȗږ�
--           , flvl.attribute8              gl_segment4                      -- �⏕����ȖڃR�[�h
--           , flvl.attribute9              gl_segment5                      -- �ڋq�R�[�h
--           , flvl.attribute10             gl_segment6                      -- ��ƃR�[�h
--           , flvl.attribute11             gl_segment7                      -- �\���P
--           , flvl.attribute12             gl_segment8                      -- �\���Q
--      FROM
--              fnd_lookup_values           flvl
--      WHERE
--              flvl.lookup_type            = ct_qct_jour_cls
--        AND   flvl.lookup_code            LIKE ct_qcc_code
--        AND   flvl.enabled_flag           = ct_enabled_yes
--        AND   flvl.language               = USERENV( 'LANG' )
--        AND   gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
--                              AND         NVL( flvl.end_date_active,   gd_process_date )
--      ;
    CURSOR jour_cls_cur
    IS
      SELECT
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--             flvl.attribute1              red_black_flag                   -- �ԍ��t���O
             flvl.attribute1              dlv_invoice_class                -- �[�i�`�[�敪
           , flvl.attribute12             red_black_flag                   -- �ԍ��t���O
--******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
           , flvl.attribute2              card_sale_class                  -- �J�[�h����敪
           , flvl.attribute3              gl_segment3                      -- ����ȖڃR�[�h
           , flvl.attribute4              gl_line_type                     -- ���C���^�C�v
           , flvl.attribute5              gl_jour_category                 -- �d��J�e�S��
           , flvl.meaning                 gl_jour_pattern                  -- �d��p�^�[��
           , flvl.description             gl_segment3_nm                   -- ����Ȗږ�
           , flvl.attribute6              gl_segment4                      -- �⏕����ȖڃR�[�h
           , flvl.attribute7              gl_segment5                      -- �ڋq�R�[�h
           , flvl.attribute8              gl_segment6                      -- ��ƃR�[�h
           , flvl.attribute9              gl_segment7                      -- �\���P
           , flvl.attribute10             gl_segment8                      -- �\���Q
           , flvl.attribute11             gl_segment2                      -- ���_�R�[�h
/* 2010/03/01 Ver1.13 Add Start */
           , flvl.attribute13             discount_class                   -- �l���敪
/* 2010/03/01 Ver1.13 Mod Start */
      FROM
              fnd_lookup_values           flvl
      WHERE
              flvl.lookup_type            = ct_qct_jour_cls
        AND   flvl.lookup_code            LIKE ct_qcc_code
        AND   flvl.enabled_flag           = ct_enabled_yes
--****************************** 2009/09/14 1.9 Atsushiba     MOD START ******************************--
--        AND   flvl.language               = USERENV( 'LANG' )
        AND   flvl.language               = ct_lang
--****************************** 2009/09/14 1.9 Atsushiba     MOD END   ******************************--
        AND   gd_process_date BETWEEN     NVL( flvl.start_date_active, gd_process_date )
                              AND         NVL( flvl.end_date_active,   gd_process_date )
      ;
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    non_jour_cls_expt         EXCEPTION;                                   -- �d��p�^�[���Ȃ�
    edit_gl_expt              EXCEPTION;                                   -- ��ʉ�v�쐬�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --=====================================
    -- 0.�S�p������擾
    --=====================================
    -- �ؕ�
    lv_enter_dr_msg  := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                          , iv_name        => cv_enter_dr_msg              -- ���b�Z�[�WID(�ؕ�)
                        );
--
    -- �ݕ�
    lv_enter_cr_msg  := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                          , iv_name        => cv_enter_cr_msg              -- ���b�Z�[�WID(�ݕ�)
                        );
--
    -- ����
    lv_cash_msg      := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                          , iv_name        => cv_cash_msg                  -- ���b�Z�[�WID(����)
                        );
--
    -- VD������������
    lv_vd_msg        := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_nm            -- �A�v���P�[�V�����Z�k��
                          , iv_name        => cv_vd_msg                    -- ���b�Z�[�WID(VD������������)
                        );
--
    --�������œ�
    lv_tax_msg        := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_short_nm           -- �A�v���P�[�V�����Z�k��
                           , iv_name        => cv_tax_msg                  -- ���b�Z�[�WID(�������œ�)
                         );
--
    --=====================================
    -- 1.�d��p�^�[���̎擾
    --=====================================
--
    -- �J�[�\���I�[�v��
    BEGIN
      OPEN  jour_cls_cur;
      FETCH jour_cls_cur BULK COLLECT INTO gt_jour_cls_tbl;
    EXCEPTION
    -- �d��p�^�[���擾���s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_nm
                         , iv_name         => cv_jour_nodata_msg
                         , iv_token_name1  => cv_tkn_lookup_type
                         , iv_token_value1 => ct_qct_jour_cls
                       );
        lv_errbuf := lv_errmsg;
        RAISE non_jour_cls_expt;
    END;
    -- �d��p�^�[���擾���s�����ꍇ
    IF ( gt_jour_cls_tbl.COUNT = 0 ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_nm
                       , iv_name         => cv_jour_nodata_msg
                       , iv_token_name1  => cv_tkn_lookup_type
                       , iv_token_value1 => ct_qct_jour_cls
                     );
      lv_errbuf := lv_errmsg;
      RAISE non_jour_cls_expt;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE jour_cls_cur;
--
    -- ���o���ꂽ�̔����ѕ��p�f�[�^�̕ҏW
    <<gt_sales_exp_tbl_loop>>
    FOR sale_idx IN 1 .. gn_target_cnt LOOP
      --=====================================================================
      -- 2.�����E�J�[�h���p�f�[�^����ɁA�J�[�h����f�[�^���쐬���鏈��
      --=====================================================================
--****************************** 2009/05/13 1.6 MOD START ******************************--
--      -- �����E�J�[�h���p�̏ꍇ-->�J�[�h����敪=����:0 ���� �����J�[�h���p�z>0
--      IF ( ( gt_sales_exp_tbl( sale_idx ).card_sale_class =  gt_card_sale_cls
--        AND  gt_sales_exp_tbl( sale_idx ).cash_and_card > 0 ) )   THEN
      -- �����E�J�[�h���p�̏ꍇ-->�J�[�h����敪=����:0 ���� �����J�[�h���p�z!=0
      IF ( ( gt_sales_exp_tbl( sale_idx ).card_sale_class =  gt_card_sale_cls
        AND  gt_sales_exp_tbl( sale_idx ).cash_and_card != 0 ) )   THEN
--****************************** 2009/05/13 1.6 MOD  END  ******************************--
--
--****************************** 2009/05/13 1.6 MOD START ******************************--
--        -- �J�[�h���R�[�h�̖{�̋��z
--        ln_pure_amount := gt_sales_exp_tbl( sale_idx ).cash_and_card
--                        / ( 1 + gt_sales_exp_tbl( sale_idx ).tax_rate/ct_percent );
--
--        -- �[������
--        IF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_up ) THEN
--          -- �؂�グ�̏ꍇ
--          ln_pure_amount := CEIL( ln_pure_amount );
--
--        ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_down ) THEN
--          -- �؂艺���̏ꍇ
--          ln_pure_amount := TRUNC( ln_pure_amount );
--
--        ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_nearest ) THEN
--          -- �l�̌ܓ��̏ꍇ
--          ln_pure_amount := ROUND( ln_pure_amount );
--        END IF;
--
--        -- �ېł̏ꍇ�A�J�[�h���R�[�h�̏���Ŋz���Z�o����
--        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_tax_amount := gt_sales_exp_tbl( sale_idx ).cash_and_card - ln_pure_amount;
--        ELSE
--          ln_tax_amount := 0;
--        END IF;
--
        -- �J�[�h���R�[�h�̖{�̋��z
        ln_pure_amount := gt_sales_exp_tbl( sale_idx ).cash_and_card;
--
        --�W�v��Ɍv�Z����̂łƂ肠����0�~
        ln_tax_amount := 0;
--****************************** 2009/05/13 1.6 MOD  END  ******************************--
--
        --==============================================================
        --�̔����уJ�[�h���[�N�e�[�u���ւ̃J�[�h���R�[�h�o�^
        --==============================================================
        ln_card_idx := ln_card_idx + 1;
--
        gt_sales_card_tbl( ln_card_idx ).sales_exp_header_id   := gt_sales_exp_tbl( sale_idx ).sales_exp_header_id;
                                                                                  -- �̔����уw�b�_ID
        gt_sales_card_tbl( ln_card_idx ).dlv_invoice_number    := gt_sales_exp_tbl( sale_idx ).dlv_invoice_number;
                                                                                  -- �[�i�`�[�ԍ�
        gt_sales_card_tbl( ln_card_idx ).delivery_date         := gt_sales_exp_tbl( sale_idx ).delivery_date;
                                                                                  -- �[�i��
        gt_sales_card_tbl( ln_card_idx ).inspect_date          := gt_sales_exp_tbl( sale_idx ).inspect_date;
                                                                                  -- ������
        gt_sales_card_tbl( ln_card_idx ).ship_to_customer_code := gt_sales_exp_tbl( sale_idx ).ship_to_customer_code;
                                                                                  -- �ڋq�y�[�i��z
        gt_sales_card_tbl( ln_card_idx ).cust_gyotai_sho       := gt_sales_exp_tbl( sale_idx ).cust_gyotai_sho;
                                                                                  -- �Ƒԏ�����
        gt_sales_card_tbl( ln_card_idx ).results_employee_code := gt_sales_exp_tbl( sale_idx ).results_employee_code;
                                                                                  -- ���ьv��҃R�[�h
        gt_sales_card_tbl( ln_card_idx ).sales_base_code       := gt_sales_exp_tbl( sale_idx ).sales_base_code;
                                                                                  -- ���㋒�_�R�[�h
        gt_sales_card_tbl( ln_card_idx ).card_sale_class       := cv_card_class;
                                                                                  -- �J�[�h����敪�i�P�F�J�[�h�j
        gt_sales_card_tbl( ln_card_idx ).dlv_invoice_class     := gt_sales_exp_tbl( sale_idx ).dlv_invoice_class;
                                                                                  -- �[�i�`�[�敪
--****************************** 2009/05/13 1.6 DEL START ******************************--
--       gt_sales_card_tbl( ln_card_idx ).goods_prod_cls        := gt_sales_exp_tbl( sale_idx ).goods_prod_cls;
--                                                                                  -- �i�ڃR�[�h
--****************************** 2009/05/13 1.6 DEL START ******************************--
        gt_sales_card_tbl( ln_card_idx ).pure_amount           := ln_pure_amount;
                                                                                  -- �{�̋��z
        gt_sales_card_tbl( ln_card_idx ).tax_amount            := ln_tax_amount;
                                                                                  -- ����ŋ��z
        gt_sales_card_tbl( ln_card_idx ).tax_rate              := gt_sales_exp_tbl( sale_idx ).tax_rate;
                                                                                  -- ����ŗ�
        gt_sales_card_tbl( ln_card_idx ).consumption_tax_class := gt_sales_exp_tbl( sale_idx ).consumption_tax_class;
                                                                                  -- ����敪
        gt_sales_card_tbl( ln_card_idx ).tax_code              := gt_sales_exp_tbl( sale_idx ).tax_code;
                                                                                  -- �ŋ��R�[�h
        gt_sales_card_tbl( ln_card_idx ).customer_cls_code     :=  gt_sales_exp_tbl( sale_idx ).customer_cls_code;
                                                                                  -- �ڋq�敪
        gt_sales_card_tbl( ln_card_idx ).sales_class           := gt_sales_exp_tbl( sale_idx ).sales_class;
                                                                                  -- ����敪
--****************************** 2009/05/13 1.6 DEL START ******************************--
--        gt_sales_card_tbl( ln_card_idx ).gccs_segment3         := gt_sales_exp_tbl( sale_idx ). gccs_segment3;
                                                                                  -- ���㊨��ȖڃR�[�h
--****************************** 2009/05/13 1.6 DEL START ******************************--
        gt_sales_card_tbl( ln_card_idx ).gcct_segment3         := gt_sales_exp_tbl( sale_idx ).gcct_segment3;
                                                                                  -- �ŋ�����ȖڃR�[�h
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
        gt_sales_card_tbl( ln_card_idx ).red_black_flag        := gt_sales_exp_tbl( sale_idx ).red_black_flag;
                                                                                  -- �ԍ��t���O
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
      END IF;
--
    END LOOP gt_sales_exp_tbl_loop;                                               -- �̔����ѕ��p�f�[�^�ҏW�I��
--
    -- �W��L�[�̒l�Z�b�g
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--    lt_invoice_number   := gt_sales_exp_tbl( 1 ).dlv_invoice_number;
--    lt_invoice_class    := gt_sales_exp_tbl( 1 ).dlv_invoice_class;
--    lt_card_sale_class  := gt_sales_exp_tbl( 1 ).card_sale_class;
--    lt_goods_prod_cls   := gt_sales_exp_tbl( 1 ).goods_prod_cls;
--    lt_gccs_segment3    := gt_sales_exp_tbl( 1 ).gccs_segment3;
--    lt_tax_code         := gt_sales_exp_tbl( 1 ).tax_code;
    lt_sales_exp_header_id  := gt_sales_exp_tbl( 1 ).sales_exp_header_id; --�̔����уw�b�_
    --�d��p�^�[���p
    lt_red_black_flag       := gt_sales_exp_tbl( 1 ).red_black_flag;      --�ԍ��t���O
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
    lt_dlv_invoice_class    := gt_sales_exp_tbl( 1 ).dlv_invoice_class;     --�[�i�`�[�敪
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
    lt_card_sale_class      := gt_sales_exp_tbl( 1 ).card_sale_class;     --�J�[�h����敪
    lv_sum_flag             := cv_y_flag;                                 --OIF�o�̓t���O
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--****************************** 2009/03/26 1.4 T.Kitajima ADD START ******************************--
    --�X�L�b�v����������
    gn_warn_cnt := 0;
    -- INDEX�ۑ�
    ln_index_work := 1;
    ln_sale_idx   := 1;
    lv_err_code   := cv_status_normal;
--
--****************************** 2009/03/26 1.4 T.Kitajima ADD  END  ******************************--
--
    --�f�[�^�̏W��
    <<gt_sales_exp_tbl_loop>>
    FOR sale_idx IN 1 .. gn_target_cnt LOOP
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--      --=====================================
--      --�R.GL��ʉ�vOIF�f�[�^�̏W��
--      --=====================================
--      IF (  lt_invoice_number   = gt_sales_exp_tbl( sale_idx ).dlv_invoice_number
--        AND lt_invoice_class    = gt_sales_exp_tbl( sale_idx ).dlv_invoice_class
--        AND lt_card_sale_class  = gt_sales_exp_tbl( sale_idx ).card_sale_class
--        AND lt_goods_prod_cls   = gt_sales_exp_tbl( sale_idx ).goods_prod_cls
--        AND lt_gccs_segment3    = gt_sales_exp_tbl( sale_idx ).gccs_segment3
--        AND lt_tax_code         = gt_sales_exp_tbl( sale_idx ).tax_code
--         ) THEN
----
--        -- �W�񂷂�t���O�����ݒ�
--        lv_sum_flag      := cv_y_flag;
--        lv_sum_card_flag := cv_y_flag;
----
----        -- �{�̋��z���W�񂷂�
--        ln_gl_amount := ln_gl_amount + gt_sales_exp_tbl( sale_idx ).pure_amount;
----
--        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
--        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_gl_tax := ln_gl_tax + gt_sales_exp_tbl( sale_idx ).tax_amount;
--        END IF;
----
--        -- �J�[�h���R�[�h�̏ꍇ�A��L�Q�Ő��������J�[�h���R�[�h���W��
--        IF ( lt_card_sale_class = cv_card_class ) THEN
--          <<gt_sales_card_tbl_loop>>
--          FOR i IN ln_card_pt .. gt_sales_card_tbl.COUNT LOOP
--            IF (  lt_invoice_number = gt_sales_card_tbl( i ).dlv_invoice_number
--              AND lt_invoice_class  = gt_sales_card_tbl( i ).dlv_invoice_class
--              AND lt_goods_prod_cls = gt_sales_card_tbl( i ).goods_prod_cls
--              AND lt_gccs_segment3  = gt_sales_card_tbl( i ).gccs_segment3
--              AND lt_tax_code       = gt_sales_card_tbl( i ).tax_code
--            ) THEN
--              -- �{�̋��z���W�񂷂�
--              ln_gl_amount   := ln_gl_amount + gt_sales_card_tbl( i ).pure_amount;
--              -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
--              IF ( gt_sales_card_tbl( ln_card_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--                ln_gl_tax := ln_gl_tax + gt_sales_card_tbl( i ).tax_amount;
--              END IF;
--              ln_card_pt := ln_card_pt + 1;
--            END IF;
--          END LOOP gt_sales_card_tbl_loop;
--        ELSIF ( sale_idx = gn_target_cnt AND ln_card_pt <= gt_sales_card_tbl.COUNT) THEN
--          -- ���������J�[�h���R�[�h�����̏W��
--
--          -- �W��L�[�̒l�Z�b�g
--          lt_invoice_number_card := gt_sales_card_tbl( ln_card_pt ).dlv_invoice_number;
--          lt_invoice_class_card  := gt_sales_card_tbl( ln_card_pt ).dlv_invoice_class;
--          lt_goods_prod_cls_card := gt_sales_card_tbl( ln_card_pt ).goods_prod_cls;
--          lt_gccs_segment3_card  := gt_sales_card_tbl( ln_card_pt ).gccs_segment3;
--          lt_tax_code_card       := gt_sales_card_tbl( ln_card_pt ).tax_code;
----
--          -- ���������J�[�h���R�[�h�����̏W��J�n
--          FOR i IN ln_card_pt .. gt_sales_card_tbl.COUNT LOOP
--            IF (  lt_invoice_number_card = gt_sales_card_tbl( i ).dlv_invoice_number
--              AND lt_invoice_class_card  = gt_sales_card_tbl( i ).dlv_invoice_class
--              AND lt_goods_prod_cls_card = gt_sales_card_tbl( i ).goods_prod_cls
--              AND lt_gccs_segment3_card  = gt_sales_card_tbl( i ).gccs_segment3
--              AND lt_tax_code_card       = gt_sales_card_tbl( i ).tax_code
--            ) THEN
--              -- �{�̋��z���W�񂷂�
--              ln_gl_amount_card := ln_gl_amount_card + gt_sales_card_tbl( i ).pure_amount;
--              -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
--              IF ( gt_sales_card_tbl( ln_card_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--                ln_gl_tax_card  := ln_gl_tax_card + gt_sales_card_tbl( i ).tax_amount;
--              END IF;
--              -- �J�[�h���R�[�h�̌��|�C���g���J�E���g����
--              ln_card_pt := ln_card_pt + 1;
--            END IF;
--
--          END LOOP gt_sales_card_tbl_loop;
----
--          -- �W��t���O�fN'��ݒ�
--          lv_sum_card_flag := cv_n_flag;
--        END IF;
--      ELSE
--        lv_sum_flag := cv_n_flag;
--      END IF;
--
--      -- �Ō�̃��R�[�h�ɂȂ�ƏW��t���O�fN'��ݒ�
--      IF ( sale_idx = gn_target_cnt ) THEN
--        lv_sum_flag := cv_n_flag;
--      END IF;
--
      -- �̔����уw�b�_�X�V�̂��߁FROWID�̐ݒ�
      gt_sales_h_tbl( sale_idx )            := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      gt_sales_h_tbl_work_w( sale_idx )     := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
      --=====================================
      --�R.GL��ʉ�vOIF�f�[�^�̏W��
      --=====================================
      --�����ׂ̃C���f�b�N�X�l���擾
      lnsale_idx_plus := sale_idx + 1;
      --���ݍs���Ōォ
      IF sale_idx = gn_target_cnt THEN
        --OIF�o��
        lv_sum_flag := cv_n_flag;
      --�W��L�[�ɑ��Ⴀ�邩�B
/* 2010/03/01 Ver1.13 Mod Start */
      ELSIF  (     ( lt_sales_exp_header_id  <> gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id )
               OR ( ( lt_sales_exp_header_id = gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id )
                    AND (lt_red_black_flag <> gt_sales_exp_tbl( lnsale_idx_plus ).red_black_flag)
                  )
             )
      THEN
--      ELSIF  (    lt_sales_exp_header_id  <> gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id ) THEN
/* 2010/03/01 Ver1.13 Mod Start */
        --OIF�o��
        lv_sum_flag := cv_n_flag;
      END IF;
--
/* 2010/03/01 Ver1.13 Add Start */
      IF (  gt_sales_exp_tbl( sale_idx ).item_code = gt_discount_item_code ) THEN
        -- �i�ڃR�[�h������l�����̏ꍇ
        -- �{�̋��z���W�񂷂�
        ln_gl_discount_amount := ln_gl_discount_amount + gt_sales_exp_tbl( sale_idx ).pure_amount;
  --
        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_gl_discount_tax := ln_gl_discount_tax + gt_sales_exp_tbl( sale_idx ).tax_amount;
        END IF;
      ELSE
        -- �i�ڃR�[�h������l�����łȂ��ꍇ
/* 2010/03/01 Ver1.13 Add End */
        -- �{�̋��z���W�񂷂�
        ln_gl_amount := ln_gl_amount + gt_sales_exp_tbl( sale_idx ).pure_amount;
--
        -- �ېł̏ꍇ�A����Ŋz���W�񂷂�
        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
          ln_gl_tax := ln_gl_tax + gt_sales_exp_tbl( sale_idx ).tax_amount;
        END IF;
/* 2010/03/01 Ver1.13 Add Start */
      END IF;
/* 2010/03/01 Ver1.13 Add End */
--
      --OIF�o�͂����p�J�[�h�f�[�^������΁A���p�J�[�h���W��
      IF (lv_sum_flag = cv_n_flag AND ln_card_pt <= gt_sales_card_tbl.COUNT) THEN
        -- ���������J�[�h���R�[�h�����̏W��
        lt_sales_exp_header_id_card := gt_sales_exp_tbl( sale_idx ).sales_exp_header_id;   --�̔����уw�b�_ID
        --�d��p�^�[���p
        lt_red_black_flag_card      := gt_sales_exp_tbl( sale_idx ).red_black_flag;        --�ԍ��t���O
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
        lt_dlv_invoice_class_card   := gt_sales_exp_tbl( sale_idx ).dlv_invoice_class;     --�[�i�`�[�敪
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
--
        -- ���������J�[�h���R�[�h�����̏W��J�n
        FOR i IN ln_card_pt .. gt_sales_card_tbl.COUNT LOOP
          IF (  lt_sales_exp_header_id_card = gt_sales_card_tbl( i ).sales_exp_header_id ) THEN
            -- �{�̋��z���W�񂷂�
            ln_gl_amount_card := ln_gl_amount_card + gt_sales_card_tbl( i ).pure_amount;
            -- �J�[�h���R�[�h�̌��|�C���g���J�E���g����
            ln_card_pt := ln_card_pt + 1;
          END IF;
--
        END LOOP gt_sales_card_tbl_loop;
        --
        --�J�[�h����Ŋz�Z�o
        ln_gl_tax_card   := ln_gl_amount_card * gt_sales_exp_tbl( sale_idx ).tax_rate / 
                              ( ct_percent + gt_sales_exp_tbl( sale_idx ).tax_rate );
       -- �[������
       IF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_up ) THEN
         -- �؂�グ�̏ꍇ
         ln_gl_tax_card   := roundup( ln_gl_tax_card );

       ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_down ) THEN
         -- �؂艺���̏ꍇ
         ln_gl_tax_card   := TRUNC( ln_gl_tax_card );

       ELSIF ( gt_sales_exp_tbl( sale_idx ).bill_tax_round = ct_round_rule_nearest ) THEN
         -- �l�̌ܓ��̏ꍇ
         ln_gl_tax_card   := ROUND( ln_gl_tax_card );
       END IF;
        --�J�[�h�{��(�Ŕ�)���z�Z�o
        ln_gl_amount_card := ln_gl_amount_card - ln_gl_tax_card;
--
      END IF;
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--
      -- -- �W��t���O�fN'�̏ꍇ�A���LOIF�d��ҏW�������s��
--****************************** 2009/05/13 1.6 T.Kitajima MOD START ******************************--
--      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
      IF ( lv_sum_flag = cv_n_flag) THEN
--****************************** 2009/05/13 1.6 T.Kitajima MOD  END  ******************************--
--
        -- �d��p�^�[�����GL OIF�̎d���ҏW����
        <<gt_jour_cls_tbl_loop>>
        FOR jcls_idx IN 1 .. gt_jour_cls_tbl.COUNT LOOP
--
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--          IF ( (    gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_invoice_class
--                AND gt_jour_cls_tbl( jcls_idx ).card_sale_class   = lt_card_sale_class
--                AND gt_jour_cls_tbl( jcls_idx ).goods_prod_cls    = lt_goods_prod_cls
--                )
--            OR (    gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_invoice_number_card
--                AND gt_jour_cls_tbl( jcls_idx ).card_sale_class   = cv_card_class
--                AND gt_jour_cls_tbl( jcls_idx ).goods_prod_cls    = lt_goods_prod_cls_card
--                )
--              ) THEN
--            -- �����EVD������������̏ꍇ
--            IF (   gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_cash_msg
--                OR gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_vd_msg ) THEN
--              IF ( ln_gl_amount_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
--                ln_gl_total_card := ln_gl_tax_card + ln_gl_amount_card;         -- ���z
--              END IF;
--              ln_gl_total        := ln_gl_tax + ln_gl_amount;                   -- ���z
--              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;       -- ����ȖڃR�[�h
--            -- �������œ��̏ꍇ
--            ELSIF ( gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm = lv_tax_msg ) THEN
--              IF ( ln_gl_amount_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
--                ln_gl_total_card := ln_gl_tax_card;                             -- ���z
--              END IF;
--              ln_gl_total        := ln_gl_tax;                                  -- ���z
--              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3; -- ����ȖڃR�[�h
--              -- ���i����Ə��i����̏ꍇ
--            ELSE
--              IF ( ln_gl_amount_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
--                ln_gl_total_card := ln_gl_amount_card;                           -- ���z
--              END IF;
--              ln_gl_total        := ln_gl_amount;                               -- ���z
--              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gccs_segment3; --����ȖڃR�[�h
--            END IF;
--
          --�����d���p�f�[�^
          IF (      gt_jour_cls_tbl( jcls_idx ).red_black_flag  = lt_red_black_flag
                AND gt_jour_cls_tbl( jcls_idx ).card_sale_class = lt_card_sale_class
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
                AND gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_dlv_invoice_class
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
/* 2010/03/01 Ver1.13 Add Start */
                AND gt_jour_cls_tbl( jcls_idx ).discount_class = cv_n_flag
/* 2010/03/01 Ver1.13 Add End */
             )
          THEN
            -- �����EVD������������̏ꍇ
            IF (    gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm  = lv_cash_msg
                 OR gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm  = lv_vd_msg
               )
            THEN
              ln_gl_total_card   := 0;                                                                          -- �J�[�h���z
              ln_gl_total        := abs( ( ln_gl_amount + ln_gl_tax ) - (ln_gl_tax_card + ln_gl_amount_card) ); -- �������z
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                        -- ����ȖڃR�[�h
            -- �������œ��̏ꍇ
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm = lv_tax_msg ) THEN
              ln_gl_total_card   := 0;                                                                      -- �J�[�h���z
              ln_gl_total        := abs( ln_gl_tax - ln_gl_tax_card );                                      -- �������z
              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3;                             -- ����ȖڃR�[�h
            -- ���i����Ə��i����̏ꍇ
            ELSE
              ln_gl_total_card   := 0;                                                                      -- �J�[�h���z
              ln_gl_total        := abs( ln_gl_amount - ln_gl_amount_card );                                -- �������z
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                   -- ����ȖڃR�[�h
            END IF;
          --���p�J�[�h�d���p�f�[�^
          ELSIF  (     gt_jour_cls_tbl( jcls_idx ).red_black_flag    = lt_red_black_flag_card
                   AND gt_jour_cls_tbl( jcls_idx ).card_sale_class   = cv_card_class
--******************************* 2009/11/17 1.11 M.Sano ADD START *******************************--
                   AND gt_jour_cls_tbl( jcls_idx ).dlv_invoice_class = lt_dlv_invoice_class
--******************************* 2009/11/17 1.11 M.Sano ADD  END  *******************************--
/* 2010/03/01 Ver1.13 Add Start */
                AND gt_jour_cls_tbl( jcls_idx ).discount_class = cv_n_flag
/* 2010/03/01 Ver1.13 Add End */
                 )
          THEN
            -- �����EVD������������̏ꍇ
            IF (    gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_cash_msg
                 OR gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm    = lv_vd_msg
               )
            THEN
              ln_gl_total_card   := abs( ln_gl_tax_card + ln_gl_amount_card );                              -- �J�[�h���z
              ln_gl_total        := 0 ;                                                                     -- �������z
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                   -- ����ȖڃR�[�h
            -- �������œ��̏ꍇ
            ELSIF ( gt_jour_cls_tbl( jcls_idx ).gl_segment3_nm = lv_tax_msg ) THEN
              ln_gl_total_card   := abs( ln_gl_tax_card );                                                  -- �J�[�h���z
              ln_gl_total        := 0 ;                                                                     -- �������z
              lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3;                             -- ����ȖڃR�[�h
            -- ���i����Ə��i����̏ꍇ
            ELSE
              ln_gl_total_card   := abs( ln_gl_amount_card );                                               -- �J�[�h���z
              ln_gl_total        := 0;                                                                      -- �������z
              lt_gl_segment3     := gt_jour_cls_tbl( jcls_idx ).segment3;                                   -- ����ȖڃR�[�h
            END IF;
          END IF;   -- �ؕ��E�ݕ��s����GL OIF�f�[�^�쐬�I��
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
--
          ln_card_jour := ln_card_pt - 1;
          IF (  gt_jour_cls_tbl( jcls_idx ).line_type = lv_enter_dr_msg ) THEN
            -- �ؕ��s
--
            --===========================================
            --A-4.GL��ʉ�vOIF�f�[�^�쐬�������Ăяo��
            --===========================================
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total > 0 AND lv_sum_flag = cv_n_flag ) THEN
              --���z���������Ă���ꍇ�o�͂���
            IF ( ln_gl_total != 0) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              --�̔����ь��f�[�^�̏W��
              ln_gl_idx := ln_gl_idx + 1;
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- �G���[�E���b�Z�[�W
                          , ov_retcode                => lv_retcode       -- ���^�[���E�R�[�h
                          , ov_errmsg                 => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF �f�[�^�C���f�b�N�X
                          , in_sale_idx               => sale_idx         -- �̔����уf�[�^�C���f�b�N�X
                          , iv_card_flg               => cv_n_flag        -- �̔����уf�[�^�d��
                          , in_card_idx               => NULL             -- �J�[�h�f�[�^�C���f�b�N�X
                          , in_jcls_idx               => jcls_idx         -- �d��p�^�[���C���f�b�N�X
                          , iv_gl_segment3            => lt_gl_segment3   -- ����ȖڃR�[�h
                          , in_entered_dr             => ln_gl_total      -- �ؕ����z
                          , in_entered_cr             => NULL             -- �ݕ����z
                        );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total := 0;
            END IF;
--
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
              --���z���������Ă���ꍇ�o�͂���
            IF ( ln_gl_total_card != 0 ) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              --���������J�[�h���R�[�h�����̏W��f�[�^
              ln_gl_idx  := ln_gl_idx  + 1;
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- �G���[�E���b�Z�[�W
                          , ov_retcode                => lv_retcode       -- ���^�[���E�R�[�h
                          , ov_errmsg                 => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF �f�[�^�C���f�b�N�X
                          , in_sale_idx               => sale_idx         -- �̔����уf�[�^�C���f�b�N�X
                          , iv_card_flg               => cv_y_flag        -- ���������J�[�h�f�[�^�d��t���O
                          , in_card_idx               => ln_card_jour     -- �J�[�h�f�[�^�C���f�b�N�X
                          , in_jcls_idx               => jcls_idx         -- �d��p�^�[���C���f�b�N�X
                          , iv_gl_segment3            => lt_gl_segment3   -- ����ȖڃR�[�h
                          , in_entered_dr             => ln_gl_total_card -- �ؕ����z
                          , in_entered_cr             => NULL             -- �ݕ����z
                          );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total_card := 0;
            END IF;
--
          ELSIF ( gt_jour_cls_tbl( jcls_idx ).line_type = lv_enter_cr_msg ) THEN
            -- �ݕ��s
--
              --===========================================
              --A-4.GL��ʉ�vOIF�f�[�^�쐬�������Ăяo��
              --===========================================
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total > 0 AND lv_sum_flag = cv_n_flag ) THEN
            --���z���������Ă���ꍇ�o�͂���
            IF ( ln_gl_total != 0 ) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              --�̔����уf�[�^�̏W��
              ln_gl_idx := ln_gl_idx + 1;
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- �G���[�E���b�Z�[�W
                          , ov_retcode                => lv_retcode       -- ���^�[���E�R�[�h
                          , ov_errmsg                 => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF �f�[�^�C���f�b�N�X
                          , in_sale_idx               => sale_idx         -- �̔����уf�[�^�C���f�b�N�X
                          , iv_card_flg               => cv_n_flag        -- �̔����уf�[�^�d��
                          , in_card_idx               => NULL             -- �J�[�h�f�[�^�C���f�b�N�X
                          , in_jcls_idx               => jcls_idx         -- �d��p�^�[���C���f�b�N�X
                          , iv_gl_segment3            => lt_gl_segment3   -- ����ȖڃR�[�h
                          , in_entered_dr             => NULL             -- �ؕ����z
                          , in_entered_cr             => ln_gl_total      -- �ݕ����z
                        );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total := 0;
            END IF;
--
--******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
--              IF ( ln_gl_total_card > 0 AND lv_sum_card_flag = cv_n_flag ) THEN
            --���z���������Ă���ꍇ�o�͂���
            IF ( ln_gl_total_card != 0 ) THEN
--******************************* 2009/05/13 1.6 T.Kitajima MOD  END *******************************--
              ln_gl_idx  := ln_gl_idx  + 1;
              --���������J�[�h���R�[�h�����̏W��f�[�^
              edit_gl_data(
                            ov_errbuf                 => lv_errbuf        -- �G���[�E���b�Z�[�W
                          , ov_retcode                => lv_retcode       -- ���^�[���E�R�[�h
                          , ov_errmsg                 => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
                          , in_gl_idx                 => ln_gl_idx        -- GL OIF �f�[�^�C���f�b�N�X
                          , in_sale_idx               => sale_idx         -- �̔����уf�[�^�C���f�b�N�X
                          , iv_card_flg               => cv_y_flag        -- ���������J�[�h�f�[�^�d��t���O
                          , in_card_idx               => ln_card_jour     -- �J�[�h�f�[�^�C���f�b�N�X
                          , in_jcls_idx               => jcls_idx         -- �d��p�^�[���C���f�b�N�X
                          , iv_gl_segment3            => lt_gl_segment3   -- ����ȖڃR�[�h
                          , in_entered_dr             => NULL             -- �ؕ����z
                          , in_entered_cr             => ln_gl_total_card -- �ݕ����z
                          );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE edit_gl_expt;
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_err_code := cv_status_warn;
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
              END IF;
              ln_gl_total_card := 0;
            END IF;
--
          ELSE    -- �ؕ��s�Ƒݕ��s�ł͂Ȃ��ꍇ�A�G���[
            lv_errmsg    := xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcos_short_nm
                              , iv_name         => cv_jour_nodata_msg
                              , iv_token_name1  => cv_tkn_lookup_type
                              , iv_token_value1 => ct_qct_jour_cls
                   );
            lv_errbuf := lv_errmsg;
            RAISE non_jour_cls_expt;
          END IF;
--
--******************************* 2009/05/13 1.6 T.Kitajima DEL START *******************************--
--          END IF;                                                       -- �ؕ��E�ݕ��s����GL OIF�f�[�^�쐬�I��
--******************************* 2009/05/13 1.6 T.Kitajima DEL  END  *******************************--
        END LOOP gt_jour_cls_tbl_loop;                                  -- �d��p�^�[�����f�[�^�쐬�����I��
--
/* 2010/03/01 Ver1.13 Mod Start */
        -- =============================
        -- �l���d��쐬
        -- =============================
        IF ( ln_gl_discount_amount != 0 ) THEN
          -- �l�����z���[���łȂ��ꍇ
          <<discount_jour_loop>>
          FOR ln_idx IN 1..gt_jour_cls_tbl.COUNT LOOP
            IF ( ( gt_jour_cls_tbl( ln_idx ).red_black_flag          = lt_red_black_flag )       -- �ԍ��t���O
                   AND ( gt_jour_cls_tbl( ln_idx ).dlv_invoice_class = lt_dlv_invoice_class )    -- �[�i�`�[�t���O
                   AND ( gt_jour_cls_tbl( ln_idx ).discount_class    = cv_y_flag )               -- �l���敪
               )
            THEN
--
              -- �����̏ꍇ
              IF ( gt_jour_cls_tbl( ln_idx ).gl_segment3_nm  = lv_cash_msg ) THEN
                ln_gl_total_card   := 0;                                                                          -- �J�[�h���z
                ln_gl_total        := abs(  ln_gl_discount_amount + ln_gl_discount_tax ); -- �������z
                lt_gl_segment3     := gt_jour_cls_tbl( ln_idx ).segment3;                                        -- ����ȖڃR�[�h
              -- �������œ��̏ꍇ
              ELSIF ( gt_jour_cls_tbl( ln_idx ).gl_segment3_nm = lv_tax_msg ) THEN
                ln_gl_total_card   := 0;                                                                      -- �J�[�h���z
                ln_gl_total        := abs( ln_gl_discount_tax );                                      -- �������z
                lt_gl_segment3     := gt_sales_exp_tbl( sale_idx ).gcct_segment3;                             -- ����ȖڃR�[�h
              -- �l���i�ڂ̏ꍇ
              ELSE
                ln_gl_total_card   := 0;                                                                      -- �J�[�h���z
                ln_gl_total        := abs( ln_gl_discount_amount);                                -- �������z
                lt_gl_segment3     := gt_jour_cls_tbl( ln_idx ).segment3;                                   -- ����ȖڃR�[�h
              END IF;
  --
              IF (  gt_jour_cls_tbl( ln_idx ).line_type = lv_enter_dr_msg ) THEN
                -- �ؕ��s
                -- GL-OIF�̃C���f�b�N�X���J�E���g�A�b�v
                ln_gl_idx := ln_gl_idx + 1;
                --
                edit_gl_data(
                              ov_errbuf                 => lv_errbuf        -- �G���[�E���b�Z�[�W
                            , ov_retcode                => lv_retcode       -- ���^�[���E�R�[�h
                            , ov_errmsg                 => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
                            , in_gl_idx                 => ln_gl_idx        -- GL OIF �f�[�^�C���f�b�N�X
                            , in_sale_idx               => sale_idx         -- �̔����уf�[�^�C���f�b�N�X
                            , iv_card_flg               => cv_n_flag        -- �̔����уf�[�^�d��
                            , in_card_idx               => NULL             -- �J�[�h�f�[�^�C���f�b�N�X
                            , in_jcls_idx               => ln_idx           -- �d��p�^�[���C���f�b�N�X
                            , iv_gl_segment3            => lt_gl_segment3   -- ����ȖڃR�[�h
                            , in_entered_dr             => ln_gl_total      -- �ؕ����z
                            , in_entered_cr             => NULL             -- �ݕ����z
                          );
                ln_gl_total := 0;
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE edit_gl_expt;
                ELSIF ( lv_retcode = cv_status_warn ) THEN
                  lv_err_code := cv_status_warn;
                END IF;
              ELSIF ( gt_jour_cls_tbl( ln_idx ).line_type = lv_enter_cr_msg ) THEN
                -- �ݕ��s
                ln_gl_idx := ln_gl_idx + 1;
                edit_gl_data(
                              ov_errbuf                 => lv_errbuf        -- �G���[�E���b�Z�[�W
                            , ov_retcode                => lv_retcode       -- ���^�[���E�R�[�h
                            , ov_errmsg                 => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W
                            , in_gl_idx                 => ln_gl_idx        -- GL OIF �f�[�^�C���f�b�N�X
                            , in_sale_idx               => sale_idx         -- �̔����уf�[�^�C���f�b�N�X
                            , iv_card_flg               => cv_n_flag        -- �̔����уf�[�^�d��
                            , in_card_idx               => NULL             -- �J�[�h�f�[�^�C���f�b�N�X
                            , in_jcls_idx               => ln_idx           -- �d��p�^�[���C���f�b�N�X
                            , iv_gl_segment3            => lt_gl_segment3   -- ����ȖڃR�[�h
                            , in_entered_dr             => NULL             -- �ؕ����z
                            , in_entered_cr             => ln_gl_total      -- �ݕ����z
                          );
                ln_gl_total := 0;
                IF ( lv_retcode = cv_status_error ) THEN
                  RAISE edit_gl_expt;
                ELSIF ( lv_retcode = cv_status_warn ) THEN
                  lv_err_code := cv_status_warn;
                END IF;
              ELSE    -- �ؕ��s�Ƒݕ��s�ł͂Ȃ��ꍇ�A�G���[
                lv_errmsg    := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_xxcos_short_nm
                                  , iv_name         => cv_jour_nodata_msg
                                  , iv_token_name1  => cv_tkn_lookup_type
                                  , iv_token_value1 => ct_qct_jour_cls
                       );
                lv_errbuf := lv_errmsg;
                RAISE non_jour_cls_expt;
              END IF;
            END IF;
            --
          END LOOP discount_jour_loop;
        END IF;
/* 2010/03/01 Ver1.13 Mod Start */
--
/* 2010/03/01 Ver1.13 Del Start */
--        IF sale_idx < gn_target_cnt THEN
--          -- �W��L�[�ƏW����z�̃��Z�b�g
----******************************* 2009/05/13 1.6 T.Kitajima MOD START *******************************--
----          lt_invoice_number   := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_number;
----          lt_invoice_class    := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_class;
----          lt_card_sale_class  := gt_sales_exp_tbl( lnsale_idx_plus ).card_sale_class;
----          lt_goods_prod_cls   := gt_sales_exp_tbl( lnsale_idx_plus ).goods_prod_cls;
----          lt_gccs_segment3    := gt_sales_exp_tbl( lnsale_idx_plus ).gccs_segment3;
----          lt_tax_code         := gt_sales_exp_tbl( lnsale_idx_plus ).tax_code;
--          lt_sales_exp_header_id  := gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id; --�̔����уw�b�_
--          --�d��p�^�[���p
--          lt_red_black_flag       := gt_sales_exp_tbl( lnsale_idx_plus ).red_black_flag;      --�ԍ��t���O
----******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--          lt_dlv_invoice_class    := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_class;   --�[�i�`�[�敪
----******************************* 2009/11/17 1.11 M.Sano MOD  END  *******************************--
--          lt_card_sale_class      := gt_sales_exp_tbl( lnsale_idx_plus ).card_sale_class;     --�J�[�h����敪
--          lv_sum_flag             := cv_y_flag;                                               --OIF�o�̓t���O
----******************************* 2009/05/13 1.6 T.Kitajima MOD  END  *******************************--
--          ln_gl_amount := 0;
--          ln_gl_tax    := 0;
--          ln_gl_amount_card := 0;
--          ln_gl_tax_card    := 0;
--        END IF;
/* 2010/03/01 Ver1.13 Del End */
--
        --���[�v����A-4���������[�j���O�������ꍇ
/* 2010/03/01 Ver1.13 Add Start */
        IF ( ( sale_idx = gn_target_cnt ) OR (lt_sales_exp_header_id  <> gt_sales_exp_tbl(sale_idx + 1).sales_exp_header_id ) ) THEN
/* 2010/03/01 Ver1.13 Add End */
        IF ( lv_err_code = cv_status_warn ) THEN
          gt_gl_interface_tbl.DELETE(ln_index_work,ln_gl_idx);
          gt_sales_h_tbl.DELETE(ln_sale_idx,sale_idx);
          IF ln_index_work = 1 THEN
            gn_warn_cnt := ln_gl_idx;
          ELSE
            gn_warn_cnt   := gn_warn_cnt + ( ln_gl_idx - ln_index_work ) + 1;
          END IF;
          lv_err_code   := cv_status_normal;
          ov_retcode    := cv_status_warn;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        ELSE
          gt_sales_h_tbl_work_w.DELETE(ln_sale_idx,sale_idx);
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
        END IF;
--
        ln_index_work := ln_gl_idx + 1;
/* 2010/03/01 Ver1.13 Add Start */
          ln_sale_idx   := sale_idx + 1;
        END IF;
--
        IF sale_idx < gn_target_cnt THEN
          lt_sales_exp_header_id  := gt_sales_exp_tbl( lnsale_idx_plus ).sales_exp_header_id; --�̔����уw�b�_
          --�d��p�^�[���p
          lt_red_black_flag       := gt_sales_exp_tbl( lnsale_idx_plus ).red_black_flag;      --�ԍ��t���O
          lt_dlv_invoice_class    := gt_sales_exp_tbl( lnsale_idx_plus ).dlv_invoice_class;   --�[�i�`�[�敪
          lt_card_sale_class      := gt_sales_exp_tbl( lnsale_idx_plus ).card_sale_class;     --�J�[�h����敪
          lv_sum_flag             := cv_y_flag;                                               --OIF�o�̓t���O
          ln_gl_amount := 0;
          ln_gl_tax    := 0;
          ln_gl_amount_card := 0;
          ln_gl_tax_card    := 0;
          ln_gl_discount_amount := 0;
          ln_gl_discount_tax    := 0;
        END IF;
/* 2010/03/01 Ver1.13 Add End */
/* 2010/03/01 Ver1.13 Del Start */
--        ln_sale_idx   := sale_idx + 1;
/* 2010/03/01 Ver1.13 Del End */
--
      END IF;                                                           -- �W��L�[����GL OIF�f�[�^�̏W��I��
--
--******************************* 2009/05/13 1.6 T.Kitajima DEL START *******************************--
--      -- �̔����уw�b�_�X�V�̂��߁FROWID�̐ݒ�
--      gt_sales_h_tbl( sale_idx )            := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
----******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
--
--      IF ( lv_sum_flag = cv_n_flag OR lv_sum_card_flag = cv_n_flag ) THEN
--        -- �W��L�[�ƏW����z�̃��Z�b�g
--        lt_invoice_number   := gt_sales_exp_tbl( sale_idx ).dlv_invoice_number;
--        lt_invoice_class    := gt_sales_exp_tbl( sale_idx ).dlv_invoice_class;
--        lt_card_sale_class  := gt_sales_exp_tbl( sale_idx ).card_sale_class;
--        lt_goods_prod_cls   := gt_sales_exp_tbl( sale_idx ).goods_prod_cls;
--        lt_gccs_segment3    := gt_sales_exp_tbl( sale_idx ).gccs_segment3;
--        lt_tax_code         := gt_sales_exp_tbl( sale_idx ).tax_code;
----
--        ln_gl_amount        := gt_sales_exp_tbl( sale_idx ).pure_amount;
--        IF ( gt_sales_exp_tbl( sale_idx ).consumption_tax_class != gt_no_tax_cls ) THEN
--          ln_gl_tax         := gt_sales_exp_tbl( sale_idx ).tax_amount;
--        END IF;
--
--
----******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
--        --���[�v����A-4���������[�j���O�������ꍇ
--        IF ( lv_err_code = cv_status_warn ) THEN
--          gt_gl_interface_tbl.DELETE(ln_index_work,ln_gl_idx);
--          gt_sales_h_tbl.DELETE(ln_sale_idx,sale_idx);
--          IF ln_index_work = 1 THEN
--            gn_warn_cnt := ln_gl_idx;
--          ELSE
--            gn_warn_cnt   := gn_warn_cnt + ( ln_gl_idx - ln_index_work ) + 1;
--          END IF;
--          lv_err_code   := cv_status_normal;
--          ov_retcode    := cv_status_warn;
--        END IF;
----
--        ln_index_work := ln_gl_idx + 1;
--        ln_sale_idx   := sale_idx + 1;
----******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
----
--      END IF;
--******************************* 2009/05/13 1.6 T.Kitajima DEL  END  *******************************--
--
--******************************** 2009/03/26 1.4 T.Kitajima DEL START *****************************
--      -- �̔����уw�b�_�X�V�̂��߁FROWID�̐ݒ�
--      gt_sales_h_tbl( sale_idx )            := gt_sales_exp_tbl( sale_idx ).xseh_rowid;
--******************************** 2009/03/26 1.4 T.Kitajima DEL  END  *****************************
--
    END LOOP gt_sales_exp_tbl_loop;                                     -- �̔����уf�[�^���[�v�I��
--******************************** 2009/03/26 1.4 T.Kitajima ADD START *****************************
    --�R���N�V�����̓���ւ�
    ln_index := 1;
    FOR i IN 1 .. ln_gl_idx LOOP
      IF ( gt_gl_interface_tbl.EXISTS(i) ) THEN
        gt_gl_interface_tbl2(ln_index) := gt_gl_interface_tbl(i);
        ln_index := ln_index + 1;
      END IF;
    END LOOP;
--
    ln_index := 1;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    ln_warn_ind := 1;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
    FOR i IN 1 .. gn_target_cnt LOOP
      IF ( gt_sales_h_tbl.EXISTS(i) ) THEN
        gt_sales_h_tbl2(ln_index) := gt_sales_h_tbl(i);
        ln_index := ln_index + 1;
      END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      IF ( gt_sales_h_tbl_work_w.EXISTS(i) ) THEN
        gt_sales_h_tbl_w( ln_warn_ind )  := gt_sales_h_tbl_work_w(i);
        ln_warn_ind := ln_warn_ind + 1;
        gt_sales_h_tbl_work_w.DELETE(i);
      END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
    END LOOP;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    gt_sales_h_tbl_work_w.DELETE;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--******************************** 2009/03/26 1.4 T.Kitajima ADD  END  *****************************
--
  EXCEPTION
    WHEN non_jour_cls_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN edit_gl_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( jour_cls_cur%ISOPEN ) THEN
        CLOSE jour_cls_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_work_data;
--
  /***********************************************************************************
   * Procedure Name   : insert_gl_data
   * Description      : ��ʉ�vOIF�o�^����(A-5)
   ***********************************************************************************/
  PROCEDURE insert_gl_data(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_gl_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
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
    --==============================================================
    -- ��ʉ�vOIF�e�[�u���փf�[�^�o�^
    --==============================================================
    BEGIN
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--      FORALL i IN 1..gt_gl_interface_tbl.COUNT
      FORALL i IN 1..gt_gl_interface_tbl2.COUNT
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
        INSERT INTO
          gl_interface
        VALUES
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--          gt_gl_interface_tbl(i)
          gt_gl_interface_tbl2(i)
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
        ;
    EXCEPTION
      WHEN OTHERS THEN
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
        lv_errbuf := SQLERRM;
--******************************* 2009/11/17 1.11 M.Sano MOD  END   *******************************--
        RAISE global_insert_data_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      -- �o�^�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      lv_tbl_nm  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm               -- �A�v���Z�k��
                      , iv_name              => cv_tkn_gloif_msg                -- ���b�Z�[�WID
                    );
      ov_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application       => cv_xxcos_short_nm
                      , iv_name              => cv_data_insert_msg
                      , iv_token_name1       => cv_tkn_tbl_nm
                      , iv_token_value1      => lv_tbl_nm
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => cv_blank
                    );
--******************************* 2009/11/17 1.11 M.Sano MOD START *******************************--
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
--******************************* 2009/11/17 1.11 M.Sano MOD  END   *******************************--
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
  END insert_gl_data;
--
  /***********************************************************************************
   * Procedure Name   : upd_data
   * Description      : �̔����уw�b�_�X�V����(A-6)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf         OUT VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2 )        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'upd_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �̔����уw�b�_�X�V����
    --==============================================================
--
    -- �����Ώۃf�[�^�̃C���^�t�F�[�X�σt���O���ꊇ�X�V����
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
---- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
--    IF ( gn_last_flag = 0 ) THEN
---- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
    -- �N�����[�h��1�̏ꍇ
    IF ( gv_mode = cv_mode1 ) THEN
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      IF ( gt_sales_h_tbl2.COUNT > 0 ) THEN
          -- ����f�[�^�X�V
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
        BEGIN
          <<update_interface_flag>>
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--      FORALL i IN gt_sales_h_tbl.FIRST..gt_sales_h_tbl.LAST
          FORALL i IN gt_sales_h_tbl2.FIRST..gt_sales_h_tbl2.LAST
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
            UPDATE
              xxcos_sales_exp_headers      xseh
            SET
              xseh.gl_interface_flag      = cv_y_flag,                           -- GL�C���^�t�F�[�X�σt���O
              xseh.last_updated_by        = cn_last_updated_by,                  -- �ŏI�X�V��
              xseh.last_update_date       = cd_last_update_date,                 -- �ŏI�X�V��
              xseh.last_update_login      = cn_last_update_login,                -- �ŏI�X�V���O�C��
              xseh.request_id             = cn_request_id,                       -- �v��ID
              xseh.program_application_id = cn_program_application_id,           -- �R���J�����g�E�v���O�����E�A�v��ID
              xseh.program_id             = cn_program_id,                       -- �R���J�����g�E�v���O����ID
              xseh.program_update_date    = cd_program_update_date               -- �v���O�����X�V��
            WHERE
--******************************** 2009/03/26 1.4 T.Kitajima MOD START *****************************
--          xseh.rowid                  = gt_sales_h_tbl( i );                 -- �̔�����ROWID
              xseh.rowid                  = gt_sales_h_tbl2( i );                 -- �̔�����ROWID
--******************************** 2009/03/26 1.4 T.Kitajima MOD  END  *****************************
--
          EXCEPTION
            WHEN OTHERS THEN
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
              lv_tbl_nm    := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_xxcos_short_nm
                                , iv_name         => cv_sales_exp_h_nomal
                             );
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
              RAISE global_update_data_expt;
          END;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        IF ( gt_sales_h_tbl_w.COUNT > 0 ) THEN
          -- �x���f�[�^�X�V
          BEGIN
            FORALL w IN gt_sales_h_tbl_w.FIRST..gt_sales_h_tbl_w.LAST
              UPDATE
                xxcos_sales_exp_headers      xseh
              SET
                xseh.gl_interface_flag      = cv_w_flag,                           -- GL�C���^�t�F�[�X�σt���O
                xseh.last_updated_by        = cn_last_updated_by,                  -- �ŏI�X�V��
                xseh.last_update_date       = cd_last_update_date,                 -- �ŏI�X�V��
                xseh.last_update_login      = cn_last_update_login,                -- �ŏI�X�V���O�C��
                xseh.request_id             = cn_request_id,                       -- �v��ID
                xseh.program_application_id = cn_program_application_id,           -- �R���J�����g�E�v���O�����E�A�v��ID
                xseh.program_id             = cn_program_id,                       -- �R���J�����g�E�v���O����ID
                xseh.program_update_date    = cd_program_update_date               -- �v���O�����X�V��
              WHERE
                xseh.rowid                  = gt_sales_h_tbl_w(w)
                ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_tbl_nm    := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_xxcos_short_nm
                                , iv_name         => cv_sales_exp_h_warn
                             );
              RAISE global_update_data_expt;
          END;
        END IF;
--
    ELSE
        -- �ΏۊO�f�[�^�X�V
      BEGIN
        UPDATE
          xxcos_sales_exp_headers      xseh
        SET
          xseh.gl_interface_flag      = cv_s_flag,                           -- GL�C���^�t�F�[�X�σt���O
          xseh.last_updated_by        = cn_last_updated_by,                  -- �ŏI�X�V��
          xseh.last_update_date       = cd_last_update_date,                 -- �ŏI�X�V��
          xseh.last_update_login      = cn_last_update_login,                -- �ŏI�X�V���O�C��
          xseh.request_id             = cn_request_id,                       -- �v��ID
          xseh.program_application_id = cn_program_application_id,           -- �R���J�����g�E�v���O�����E�A�v��ID
          xseh.program_id             = cn_program_id,                       -- �R���J�����g�E�v���O����ID
          xseh.program_update_date    = cd_program_update_date             -- �v���O�����X�V��
        WHERE
          xseh.gl_interface_flag      = cv_n_flag
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
        AND
          xseh.delivery_date          >= gd_from_date
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
        AND
-- ***************** 2009/12/29 1.12 N.Maeda MOD START ***************** --
--          xseh.inspect_date           <= gd_process_date
          xseh.delivery_date          <= gd_process_date
-- ***************** 2009/12/29 1.12 N.Maeda MOD  END  ***************** --
          ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_tbl_nm    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_xxcos_short_nm
                            , iv_name         => cv_sales_exp_h_elig
                         );
          RAISE global_update_data_expt;
      END;
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
      -- �����o��
      gn_target_cnt := SQL%ROWCOUNT;
      gn_normal_cnt := gn_target_cnt;
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
--      END IF;
    END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_update_data_expt THEN
      -- �X�V�Ɏ��s�����ꍇ
      -- �G���[�����ݒ�
      gn_error_cnt := gn_target_cnt;
-- ***************** 2009/10/07 1.10 N.Maeda DEL START ***************** --
--      lv_tbl_nm    := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_xxcos_short_nm
--                        , iv_name         => cv_tkn_sales_msg
--                     );
-- ***************** 2009/10/07 1.10 N.Maeda DEL  END  ***************** --
      ov_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_data_update_msg
                        , iv_token_name1  => cv_tkn_tbl_nm
                        , iv_token_value1 => lv_tbl_nm
                        , iv_token_name2  => cv_tkn_key_data
                        , iv_token_value2 => cv_blank
                      );
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode   := cv_status_error;
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : �T�u���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
  (
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--      ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
      iv_mode      IN  VARCHAR2             --   �N�����[�h
    , ov_errbuf    OUT VARCHAR2             --   �G���[�E���b�Z�[�W           --# �Œ� #
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
    , ov_retcode   OUT VARCHAR2             --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg    OUT VARCHAR2 )           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);              -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);                 -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);              -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_tbl_nm VARCHAR2(255);                -- �e�[�u����
    lv_retcode_tmp VARCHAR2(1);
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
--
    ln_pre_header_id       xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- �̔����уw�b�_ID
    ln_lock_header_id      xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- �̔����уw�b�_ID
    ln_header_id_wk        xxcos_sales_exp_headers.sales_exp_header_id%TYPE;    -- �̔����уw�b�_ID
-- ***************** 2016/10/25 1.17 N.Koyama ADD START ***************** --
    lt_dlv_by_code         xxcos_sales_exp_headers.dlv_by_code%TYPE;            -- �[�i��
-- ***************** 2016/10/25 1.17 N.Koyama ADD END    ***************** --
    ln_sales_idx           NUMBER DEFAULT 1;
    ln_target_wk_cnt       NUMBER DEFAULT 0;
    ln_fetch_end_flag      NUMBER DEFAULT 0;     -- 0:�p���A1:�I��
    ln_warn_wk_cnt         NUMBER DEFAULT 0;
    lv_table_name          VARCHAR2(100);
--
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
    ln_last_dara_count     NUMBER DEFAULT 0;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt    := 0;                  -- �Ώی���
    gn_normal_cnt    := 0;                  -- ���팏��
    gn_error_cnt     := 0;                  -- �G���[����
--****************************** 2009/07/06 1.7 T.Tominaga ADL START ******************************
    gn_warn_cnt      := 0;                  --�X�L�b�v����
--****************************** 2009/07/06 1.7 T.Tominaga ADL END   ******************************
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--        ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        iv_mode    => iv_mode               -- �N�����[�h
      , ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
      , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
    -- �N�����[�h��1�̏ꍇ�̂�
    IF ( gv_mode = cv_mode1 ) THEN
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
      -- ===============================
      -- A-2.�f�[�^�擾
      -- ===============================
      get_data(
          ov_errbuf  => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg  => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
--****************************** 2009/09/14 1.9 Atsushiba  MOD START ******************************--
--
      -- ������
      gt_sales_exp_tbl.DELETE;
      lv_retcode_tmp := cv_status_normal;
      <<bulk_loop>>
      LOOP
        -- ������
        gt_sales_exp_wk_tbl.DELETE;
        ln_pre_header_id := NULL;
-- ***************** 2016/10/25 1.17 N.Koyama ADD START ***************** --
--        ln_lock_header_id := NULL;
        ln_lock_header_id := 99999999999999999999;
-- ***************** 2016/10/25 1.17 N.Koyama ADD END   ***************** --
        --
        -- �f�[�^�擾
        FETCH sales_data_cur BULK COLLECT INTO gt_sales_exp_wk_tbl LIMIT cn_bulk_collect_count;
        -- 
        EXIT WHEN ln_fetch_end_flag = 1;
--
        -- �f�[�^�L���`�F�b�N
        IF ( sales_data_cur%NOTFOUND ) THEN
          ln_fetch_end_flag := 1;
        END IF;
        --
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
        IF ( ln_fetch_end_flag = 1 ) AND ( gt_sales_exp_wk_tbl.COUNT = 0 ) THEN
            gt_sales_exp_wk_tbl := gt_sales_exp_evacu_tbl;
            gt_sales_exp_evacu_tbl.DELETE;
            gn_target_cnt       := gn_target_cnt - gt_sales_exp_wk_tbl.COUNT;
            ln_target_wk_cnt    := ln_target_wk_cnt - gt_sales_exp_wk_tbl.COUNT;
        END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
        <<journal_loop>>
        FOR ln_idx IN 1..gt_sales_exp_wk_tbl.COUNT LOOP
-- 
          -- �̔�����ID�̌�������l�ȏォ�̔�����ID���u���C�N
          -- �܂��́A�t�F�b�`�Ǎ��I�����z��̍Ō�
          IF ( ( gt_sales_header_tbl.COUNT >= cn_journal_batch_count
                 AND ln_pre_header_id <> gt_sales_exp_wk_tbl(ln_idx).sales_exp_header_id)
               OR ( ln_fetch_end_flag = 1 AND ln_idx = gt_sales_exp_wk_tbl.COUNT )
             )
          THEN
            --
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
            ln_last_dara_count := 0;
            gt_sales_exp_evacu_tbl.DELETE;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
            -- �t�F�b�`�Ǎ��I�����z��̍Ō�̏ꍇ
            IF ( ln_fetch_end_flag = 1 AND ln_idx = gt_sales_exp_wk_tbl.COUNT ) THEN
              gn_target_cnt := gn_target_cnt + 1;
              gt_sales_exp_tbl(ln_sales_idx) := gt_sales_exp_wk_tbl(ln_idx);
            END IF;
            --
            BEGIN
              -- �����Ώۃf�[�^�����b�N
              <<lock_loop>>
              FOR ln_lock_ind IN 1..gt_sales_exp_tbl.COUNT LOOP
                IF (ln_lock_header_id <> gt_sales_exp_tbl(ln_lock_ind).sales_exp_header_id) THEN
                  SELECT  xseh.sales_exp_header_id
-- ***************** 2016/10/25 1.17 N.Koyama ADD START ***************** --
                         ,xseh.dlv_by_code dlv_by_code
-- ***************** 2016/10/25 1.17 N.Koyama ADD END   ***************** --
                  INTO    ln_header_id_wk
-- ***************** 2016/10/25 1.17 N.Koyama ADD START ***************** --
                         ,lt_dlv_by_code
-- ***************** 2016/10/25 1.17 N.Koyama ADD END   ***************** --
                  FROM    xxcos_sales_exp_headers xseh
                  WHERE   xseh.sales_exp_header_id = gt_sales_exp_tbl(ln_lock_ind).sales_exp_header_id
                  FOR UPDATE OF  xseh.sales_exp_header_id
                  NOWAIT;
                END IF;
                --
                ln_lock_header_id := gt_sales_exp_tbl(ln_lock_ind).sales_exp_header_id;
-- ***************** 2016/10/25 1.17 N.Koyama ADD START ***************** --
                gt_sales_exp_tbl(ln_lock_ind).results_employee_code := lt_dlv_by_code;
-- ***************** 2009/10/25 1.17 N.Koyama ADD END   ***************** --
              END LOOP lock_loop;
              --
              -- ===============================
              -- A-3.��ʉ�vOIF�W�񏈗� (A-4 �����̌ďo���܂�)
              -- ===============================
              edit_work_data(
                   ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
                 , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
                 , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode = cv_status_error ) THEN
                gn_error_cnt := 1;
                RAISE global_process_expt;
              ELSIF ( lv_retcode = cv_status_warn ) THEN
                lv_retcode_tmp := cv_status_warn;
              END IF;
--
              -- ===============================
              -- A-5.��ʉ�vOIF�f�[�^�o�^����
              -- ===============================
              insert_gl_data(
                    ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
                  , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
                  , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
                );
              IF ( lv_retcode = cv_status_error ) THEN
                gn_error_cnt := 1;
                RAISE global_insert_data_expt;
              END IF;
--
              -- ===============================
              -- A-6.�̔����уf�[�^�̍X�V����
              -- ===============================
              upd_data(
                  ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
                , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
                , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
                );
              IF ( lv_retcode = cv_status_error ) THEN
                gn_error_cnt := 1;
                RAISE global_update_data_expt;
              END IF;
              --
              -- ���폈�������ݒ�
              gn_normal_cnt := gn_normal_cnt + gt_gl_interface_tbl2.COUNT;
              --
              -- �x�������ݒ�
              ln_warn_wk_cnt := ln_warn_wk_cnt + gn_warn_cnt;
              --
              -- �R�~�b�g
              COMMIT;
              cn_commit_exec_flag := 1;
              --
            EXCEPTION
              -- ���b�N�G���[
              WHEN lock_expt THEN
                -- ���b�N�G���[���b�Z�[�W
                lv_table_name := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
                    , iv_name        => cv_tkn_sales_msg);                -- ���b�Z�[�WID
                lv_errmsg     := xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_short_nm
                    , iv_name          => cv_table_lock_msg
                    , iv_token_name1   => cv_tkn_tbl
                    , iv_token_value1  => lv_table_name);
                -- ���b�Z�[�W�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
                --
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => cv_blank
                );
                --
                -- �X�L�b�v���b�Z�[�W
                lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_xxcos_short_nm
                    , iv_name          => cv_skip_data_msg
                    , iv_token_name1   => cv_tkn_header_from           -- �w�b�_(FROM)
                    , iv_token_value1  => TO_CHAR(gt_sales_exp_tbl(1).sales_exp_header_id)
                    , iv_token_name2   => cv_tkn_header_to             -- �w�b�_(TO)
                    , iv_token_value2  => TO_CHAR(gt_sales_exp_tbl(gt_sales_exp_tbl.COUNT).sales_exp_header_id)
                    , iv_token_name3   => cv_tkn_count                 -- �w�b�_����
                    , iv_token_value3  => TO_CHAR(gt_sales_header_tbl.COUNT)
                    );
                -- ���b�Z�[�W�o��
                -- ��s�o��
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => cv_blank
                );
                --
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.LOG
                  ,buff   => lv_errmsg
                );
--
                lv_retcode_tmp := cv_status_warn;
                -- �X�L�b�v����
                ln_warn_wk_cnt := ln_warn_wk_cnt + gt_sales_exp_tbl.COUNT;
            END;
            --
            -- ������
            gt_sales_header_tbl.DELETE;    -- �̔����уw�b�_ID�����p
            gt_sales_card_tbl.DELETE;      -- �J�[�h�f�[�^�p
            gt_sales_exp_tbl.DELETE;       -- �̔����уf�[�^�p
            gt_sales_h_tbl.DELETE;         -- AR�A�g�t���O�X�V�p
            gt_sales_h_tbl2.DELETE;        -- AR�A�g�t���O�X�V�p
            gt_gl_interface_tbl.DELETE;    -- GL-OIF�f�[�^�ҏW�p
            gt_gl_interface_tbl2.DELETE;   -- GL-OIF�o�^�p
            ln_sales_idx := 1;
            gn_target_cnt := 0;
            gn_warn_cnt := 0;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
            gt_sales_h_tbl_w.DELETE;       -- �̔����уf�[�^�p(�x��)
            gt_sales_h_tbl_work_w.DELETE;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--
          END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
          IF ( cn_bulk_collect_count = gt_sales_exp_wk_tbl.COUNT ) THEN
            ln_last_dara_count := ln_last_dara_count + 1;
            gt_sales_exp_evacu_tbl( ln_last_dara_count ) := gt_sales_exp_wk_tbl(ln_idx);
          END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
          gt_sales_exp_tbl(ln_sales_idx) := gt_sales_exp_wk_tbl(ln_idx);
          ln_sales_idx := ln_sales_idx + 1;
          gt_sales_header_tbl(TO_CHAR(gt_sales_exp_wk_tbl(ln_idx).sales_exp_header_id)) := NULL;
          ln_target_wk_cnt := ln_target_wk_cnt + 1;
          gn_target_cnt := gn_target_cnt + 1;
          ln_pre_header_id := gt_sales_exp_wk_tbl(ln_idx).sales_exp_header_id;
        END LOOP journal_loop;
        --
      END LOOP bulk_loop;
      --
      gn_target_cnt := ln_target_wk_cnt;
      gn_warn_cnt   := ln_warn_wk_cnt;
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--      gn_last_flag := 1;
    -- �N�����[�h��2�̏ꍇ�̂�
    ELSIF ( gv_mode = cv_mode2 ) THEN
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
      -- ===============================
      -- A-6.�̔����уf�[�^�̍X�V����
      -- ===============================
      upd_data(
          ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
        , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
        , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
              );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_update_data_expt;
      END IF;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    END IF;
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
    --
    IF ((gn_warn_cnt > 0 )
        OR ( lv_retcode_tmp = cv_status_warn )) THEN
      -- �x���I��
      ov_retcode := cv_status_warn;
    END IF;
    --
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    -- �N�����[�h��1�̏ꍇ�̂�
    IF ( gv_mode = cv_mode1 ) THEN
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
      --
      IF ( gn_target_cnt = 0 ) THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_nm
                        , iv_name         => cv_no_data_msg);
        lv_errbuf  := lv_errmsg;
        lv_retcode := cv_status_warn;
        RAISE global_no_data_expt;
      END IF;
      --
      lv_retcode := lv_retcode_tmp;
--***************************** 2012/11/13 1.15 K.Nakamura ADD START *****************************--
    END IF;
--***************************** 2012/11/13 1.15 K.Nakamura ADD END   *****************************--
  --
--
--    -- �̔����я�񒊏o��0�����́A���o���R�[�h�Ȃ��ŏI��
--    IF ( gn_target_cnt > 0 ) THEN
----
--    -- ===============================
--    -- A-3.��ʉ�vOIF�W�񏈗� (A-4 �����̌ďo���܂�)
--    -- ===============================
--        edit_work_data(
--             ov_errbuf  => lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
--           , ov_retcode => lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
--           , ov_errmsg  => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--        );
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        ELSE
--          lv_retcode_tmp := lv_retcode;
--        END IF;
--
--      -- ===============================
--      -- A-5.��ʉ�vOIF�f�[�^�o�^����
--      -- ===============================
--      insert_gl_data(
--            ov_errbuf       => lv_errbuf     -- �G���[�E���b�Z�[�W
--          , ov_retcode      => lv_retcode    -- ���^�[���E�R�[�h
--          , ov_errmsg       => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W
--        );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_insert_data_expt;
--      END IF;
----
--      -- ===============================
--      -- A-6.�̔����уf�[�^�̍X�V����
--      -- ===============================
--      upd_data(
--          ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
--        , ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
--        , ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
--        );
--      IF ( lv_retcode = cv_status_error ) THEN
--        gn_error_cnt := gn_target_cnt;
--        RAISE global_update_data_expt;
--      END IF;
----
--      -- ���팏���ݒ�
----      gn_normal_cnt      := gt_gl_interface_tbl.COUNT;
--      gn_normal_cnt      := gt_gl_interface_tbl2.COUNT;
--      IF ( lv_retcode_tmp = cv_status_warn ) THEN
--        ov_retcode := lv_retcode_tmp;
--      END IF;
--
--    ELSIF ( gn_target_cnt = 0 ) THEN
--      -- �Ώۃf�[�^�������b�Z�[�W
----****************************** 2009/07/06 1.7 T.Tominaga DEL START ******************************
----      lv_tbl_nm  := xxccp_common_pkg.get_msg(
----                        iv_application => cv_xxcos_short_nm               -- �A�v���P�[�V�����Z�k��
----                      , iv_name        => cv_tkn_sales_msg                -- ���b�Z�[�WID
----                    );
----****************************** 2009/07/06 1.7 T.Tominaga DEL END   ******************************
--      lv_errmsg  := xxccp_common_pkg.get_msg(
--                        iv_application  => cv_xxcos_short_nm
--                      , iv_name         => cv_no_data_msg
----****************************** 2009/07/06 1.7 T.Tominaga DEL START ******************************
----                      , iv_token_name1  => cv_tkn_tbl_nm
----                      , iv_token_value1 => lv_tbl_nm
----****************************** 2009/07/06 1.7 T.Tominaga DEL END   ******************************
--                    );
--      lv_errbuf  := lv_errmsg;
--      lv_retcode := cv_status_warn;
--      RAISE global_no_data_expt;
--    ELSE
--      RAISE global_select_data_expt;
--    END IF;
--****************************** 2009/09/14 1.9 Atsushiba  MOD END ******************************--
--
  EXCEPTION
    -- *** �Ώۃf�[�^�Ȃ� ***
    WHEN global_no_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
    -- *** �f�[�^�擾��O ***
    WHEN global_select_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �o�^������O ***
    WHEN global_insert_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �X�V������O ***
    WHEN global_update_data_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
-- ***************** 2009/10/07 1.10 N.Maeda ADD START ***************** --
      gn_target_cnt := ln_target_wk_cnt;
      gn_warn_cnt   := ln_warn_wk_cnt;
-- ***************** 2009/10/07 1.10 N.Maeda ADD  END  ***************** --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
      -- �J�[�\���N���[�Y
      IF ( sales_data_cur%ISOPEN ) THEN
        CLOSE sales_data_cur;
      END IF;
--****************************** 2009/09/14 1.9 Atsushiba  ADD END ******************************--
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
      errbuf      OUT VARCHAR2               -- �G���[�E���b�Z�[�W  --# �Œ� #
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--    , retcode     OUT VARCHAR2 )             -- ���^�[���E�R�[�h    --# �Œ� #
    , retcode     OUT VARCHAR2               -- ���^�[���E�R�[�h    --# �Œ� #
    , iv_mode     IN  VARCHAR2 )             -- �N�����[�h
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(20)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
    cv_error_part_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ�������b�Z�[�W
--****************************** 2009/09/14 1.9 Atsushiba  ADD START ******************************--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);       -- �I�����b�Z�[�W�R�[�h
    lv_sum_rec_msg     VARCHAR2(100);       -- �W�񌏐����b�Z�[�W
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode => lv_retcode
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
--***************************** 2012/11/13 1.15 K.Nakamura MOD START *****************************--
--        ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
        iv_mode    => iv_mode                -- �N�����[�h
      , ov_errbuf  => lv_errbuf              -- �G���[�E���b�Z�[�W           --# �Œ� #
--***************************** 2012/11/13 1.15 K.Nakamura MOD END   *****************************--
      , ov_retcode => lv_retcode             -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg  => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error OR lv_retcode = cv_status_warn) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                --�G���[���b�Z�[�W
      );
    END IF;
--
    -- ===============================
    -- A-7.�I������
    -- ===============================
    --��s�}��
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxccp_short_nm
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
--****************************** 2009/09/14 1.9 Atsushiba  MOD START ******************************--
      IF ( cn_commit_exec_flag = 1 ) THEN
        -- �R�~�b�g���s����̏ꍇ
        lv_message_code := cv_error_part_msg;
      ELSE
        -- �R�~�b�g�����s�̏ꍇ
        lv_message_code := cv_error_msg;
      END IF;
--      lv_message_code := cv_error_msg;
--****************************** 2009/09/14 1.9 Atsushiba  MOD END ******************************--

    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_xxccp_short_nm
                    , iv_name        => lv_message_code
                  );
    FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
--
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
END XXCOS013A03C;
/
