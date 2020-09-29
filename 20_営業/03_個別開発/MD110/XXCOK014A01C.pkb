CREATE OR REPLACE PACKAGE BODY XXCOK014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A01C(body)
 * Description      : �̔����я��E�萔���v�Z��������̔̔��萔���v�Z����
 * MD.050           : �����ʔ̎�̋��v�Z���� MD050_COK_014_A01
 * Version          : 3.20
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_operating_day_f  �ғ����擾                                   (A-16)
 *  get_tax_rate         ����ŃR�[�h�E�ŗ��擾                       (A-17)
 *  update_xcbi          �̎�v�Z�όڋq���f�[�^�̍X�V               (A-15)
 *  update_xsel          �̔����јA�g���ʂ̍X�V                       (A-12)
 *  insert_xbce          �̎�����G���[�e�[�u���ւ̓o�^               (A-11)
 *  insert_xcbs          �����ʔ̎�̋��e�[�u���ւ̓o�^               (A-10)
 *  set_xcbs_data        �����ʔ̎�̋����̐ݒ�                     (A-9)
 *  sales_result_loop1   �̔����т̎擾�E�����ʏ���                   (A-8)
 *  sales_result_loop2   �̔����т̎擾�E�e��敪�ʏ���               (A-8)
 *  sales_result_loop3   �̔����т̎擾�E�ꗥ����                     (A-8)
 *  sales_result_loop4   �̔����т̎擾�E��z����                     (A-8)
 *  sales_result_loop5   �̔����т̎擾�E�d�C���i�Œ�^�ϓ��j         (A-8)
 *  sales_result_loop6   �̔����т̎擾�E�����l����                   (A-8)
 *  delete_xbce          �̎�����G���[�̍폜����                     (A-7)
 *  delete_xcbs          �����ʔ̎�̋��f�[�^�̍폜�i���m����z�j     (A-3)
 *  insert_xt0c          �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^     (A-6)
 *  get_cust_subdata     �����ʔ̎�̋��v�Z���t���̓��o             (A-5)
 *  cust_loop            �ڋq��񃋁[�v                               (A-4)
 *  purge_xcbi           �̎�v�Z�όڋq���f�[�^�̍폜�i�ێ����ԊO�j (A-14)
 *  purge_xcbs           �����ʔ̎�̋��f�[�^�̍폜�i�ێ����ԊO�j     (A-2)
 *  init                 ��������                                     (A-1)
 *  submain              ���C�������v���V�[�W��
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/08    1.0   K.Ezaki          �V�K�쐬
 *  2009/02/13    1.1   K.Ezaki          ��QCOK_039 �x���������ݒ�ڋq�X�L�b�v
 *  2009/02/17    1.2   K.Ezaki          ��QCOK_040 �t���x���_�[�T�C�g�Œ�C��
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_060 �ꗥ�����v�Z���ʗݐ�
 *  2009/02/26    1.3   K.Ezaki          ��QCOK_061 �ꗥ������z�v�Z
 *  2009/02/25    1.3   K.Ezaki          ��QCOK_062 ��z�������ߗ��E���ߊz���ݒ�
 *  2009/03/13    1.4   T.Taniguchi      ��QT1_0036 �̔����я��J�[�\����`�̏����ǉ�
 *  2009/03/25    1.5   S.Kayahara       �ŏI�s�ɃX���b�V���ǉ�
 *  2009/04/14    1.6   K.Yamaguchi      [��QT1_0523] �̔����т̔�����z�i�ō��j�擾���@�s���Ή�
 *  2009/04/20    1.7   K.Yamaguchi      [��QT1_0688] �̎�����}�X�^�̗L�����𔻒肵�Ȃ��悤�ɏC��
 *  2009/05/20    1.8   K.Yamaguchi      [��QT1_0686] ���b�Z�[�W�C��
 *  2009/06/01    2.0   K.Yamaguchi      [��QT1_0620][��QT1_0823][��QT1_1124][��QT1_1303]
 *                                       [��QT1_1400][��QT1_1402][��QT1_1422]
 *                                       �C������ɂ��č쐬
 *  2009/06/26    2.1   M.Hiruta         [��Q0000269] �p�t�H�[�}���X�����コ���邽��SQL���C��
 *  2009/07/08    2.2   M.Hiruta         [��Q0000009] �����ʔ̎�̋��v�Z�ΏۊO�̔̔����т����O����悤�ɏC��
 *                                                     �������߂�h�����߁A�d�C���i�Œ�/�ϓ��j�̊��ߊz���C��
 *  2009/07/16    2.3   K.Yamaguchi      [��Q0000756] �p�t�H�[�}���X�����コ���邽��SQL���C��
 *  2009/07/28    2.4   K.Yamaguchi      [��Q0000879] �p�t�H�[�}���X�����コ���邽�߃e�[�u����ǉ�
 *  2009/08/06    3.0   K.Yamaguchi      [��Q0000940] �p�t�H�[�}���X�����コ���邽��SQL���C���E�C�������̍폜
 *  2009/10/02    3.1   K.Yamaguchi      [�d�l�ύXI_E_566] �[�iVD�E����VD�������Ώۂɒǉ�
 *  2009/10/19    3.2   K.Yamaguchi      [��QE_T3_00631] ����ŃR�[�h�擾���@��ύX
 *  2009/10/27    3.3   K.Yamaguchi      [��QE_T4_00094] ���������̏ꍇ��AR�A�g���s���悤�ɏC��
 *  2009/11/09    3.4   K.Yamaguchi      [�d�l�ύXI_E_633] �����l���̑ΏۂƂȂ��݌ɕi�ڂ��擾�ł���悤�ɕύX
 *  2009/12/10    3.5   K.Yamaguchi      [E_�{�ғ�_00363] �x�����ŉc�Ɠ����l������Ă��Ȃ��_���C��
 *  2009/12/21    3.6   K.Yamaguchi      [E_�{�ғ�_00460] ��z�����E�d�C���݂̂̏ꍇ�ɔ�����z���Z�b�g
 *  2010/02/03    3.7   K.Yamaguchi      [E_�{�ғ�_XXXXX] �ڋq�g�p�ړI�ŃX�e�[�^�X����ǉ�
 *  2010/02/19    3.8   S.Moriyama       [E_�{�ғ�_01446] �S���c�ƈ����擾�ł��Ȃ������ꍇ�x���Ƃ���
 *  2010/03/16    3.9   K.Yamaguchi      [E_�{�ғ�_01896] �v�Z�Ώیڋq�̔��ʂ��A�̔����т̑��ݗL������ڋq�X�e�[�^�X�ɕύX
 *                                       [E_�{�ғ�_01870] ���㋒�_�E�S���c�ƈ�����ߓ��P�ʂŌŒ艻
 *  2010/04/06    3.10  K.Yamaguchi      [E_�{�ғ�_01896] [E_�{�ғ�_01870] �����߂��Ή�
 *                                                        �N�C�b�N�R�[�h�擾���̗L�����Q�ƕ��@�s��
 *  2010/05/26    3.11  K.Yamaguchi      [E_�{�ғ�_02855] �p�t�H�[�}���X�Ή� �̔����т̍X�V���@��ύX
 *  2010/12/13    3.12  S.Niki           [E_�{�ғ�_01844] �̔����т̒��o�����ɓo�^�Ɩ����t��ǉ�
 *                                       [E_�{�ғ�_01896] �v�Z�Ώیڋq�̔��ʂ��A�̔����т̑��ݗL���ɍ����߂�
 *  2011/04/01    3.13  M.Watanabe       [E_�{�ғ�_06757] �̔����тɂĕϓ��d�C��݂̂̏ꍇ�ł��d�C���̌v�Z�ΏۂƂ���
 *  2012/02/23    3.14  S.Niki           [E_�{�ғ�_09144] ������z�i�ō��j�ɕϓ��d�C������Z���Ȃ��悤�C��
 *  2012/09/14    3.15  S.Niki           [E_�{�ғ�_08751] �p�t�H�[�}���X���P�Ή�
 *  2012/10/01    3.16  K.Kiriu          [E_�{�ғ�_10133] �p�t�H�[�}���X���P�Ή�(�q���g��Œ艻)
 *  2012/10/18    3.17  K.Kiriu          [E_�{�ғ�_10133] �p�t�H�[�}���X���P�ǉ��Ή�(�q���g��Œ艻)
 *  2018/12/26    3.18  E.Yazaki         [E_�{�ғ�_15349] �y�c�ƁE�ʁz�d����CD����
 *  2019/07/16    3.19  K.Nara           [E_�{�ғ�_15472] �y���ŗ��Ή�
 *  2020/08/21    3.20  N.Abe            [E_�{�ғ�_15904] ���̋@BM�v�Z�Ŕ����Ή�
 *****************************************************************************************/
  --==================================================
  -- �O���[�o���萔
  --==================================================
  -- �p�b�P�[�W��
  cv_pkg_name                      CONSTANT VARCHAR2(20)    := 'XXCOK014A01C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cok           CONSTANT VARCHAR2(10)    := 'XXCOK';
  cv_appl_short_name_ccp           CONSTANT VARCHAR2(10)    := 'XXCCP';
  cv_appl_short_name_gl            CONSTANT VARCHAR2(10)    := 'SQLGL';
  cv_appl_short_name_ar            CONSTANT VARCHAR2(10)    := 'AR';
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal                 CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn                   CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error                  CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  -- WHO�J����
  cn_created_by                    CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by               CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login             CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id                    CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id        CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id                    CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- ����
  cv_lang                          CONSTANT VARCHAR2(50)    := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90000                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';        -- �Ώی���
  cv_msg_ccp_90001                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';        -- ��������
  cv_msg_ccp_90002                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';        -- �G���[����
  cv_msg_ccp_90003                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';        -- �G���[����
  cv_msg_ccp_90004                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';        -- ����I��
  cv_msg_ccp_90005                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';        -- �x���I��
  cv_msg_ccp_90006                 CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
  cv_msg_cok_00003                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';
  cv_msg_cok_00022                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00022';
  cv_msg_cok_00028                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
  cv_msg_cok_00105                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00105';
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
  cv_msg_cok_00044                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00044';
  cv_msg_cok_00051                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00051';
  cv_msg_cok_00080                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00080';
  cv_msg_cok_00081                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00081';
  cv_msg_cok_00086                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00086';
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD START
  cv_msg_cok_00104                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00104';
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD END
  cv_msg_cok_10398                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10398';
  cv_msg_cok_10401                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10401';
  cv_msg_cok_10402                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10402';
  cv_msg_cok_10404                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10404';
  cv_msg_cok_10405                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10405';
  cv_msg_cok_10426                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10426';
  cv_msg_cok_10427                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10427';
  cv_msg_cok_10454                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10454';
  cv_msg_cok_10455                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10455';
  cv_msg_cok_10456                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10456';
  cv_msg_cok_00103                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00103';
  cv_msg_cok_10457                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10457';
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  cv_msg_cok_10494                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10494';
  cv_msg_cok_10495                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10495';
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  cv_msg_cok_10562                 CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10562';
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
  -- �g�[�N��
  cv_tkn_close_date                CONSTANT VARCHAR2(30)    := 'CLOSE_DATE';
  cv_tkn_container_type            CONSTANT VARCHAR2(30)    := 'CONTAINER_TYPE';
  cv_tkn_count                     CONSTANT VARCHAR2(30)    := 'COUNT';
  cv_tkn_cust_code                 CONSTANT VARCHAR2(30)    := 'CUST_CODE';
  cv_tkn_dept_code                 CONSTANT VARCHAR2(30)    := 'DEPT_CODE';
  cv_tkn_pay_date                  CONSTANT VARCHAR2(30)    := 'PAY_DATE';
  cv_tkn_proc_date                 CONSTANT VARCHAR2(30)    := 'PROC_DATE';
  cv_tkn_proc_type                 CONSTANT VARCHAR2(30)    := 'PROC_TYPE';
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  cv_tkn_proc_flag                 CONSTANT VARCHAR2(30)    := 'PROC_FLAG';  -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  cv_tkn_profile                   CONSTANT VARCHAR2(30)    := 'PROFILE';
  cv_tkn_sales_amt                 CONSTANT VARCHAR2(30)    := 'SALES_AMT';
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD START
  cv_tkn_tax_div                   CONSTANT VARCHAR2(30)    := 'TAX_DIV';
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD END
  cv_tkn_vendor_code               CONSTANT VARCHAR2(30)    := 'VENDOR_CODE';
  cv_tkn_business_date             CONSTANT VARCHAR2(30)    := 'BUSINESS_DATE';
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
  cv_tkn_base_code                 CONSTANT VARCHAR2(30)    := 'BASE_CODE';
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  cv_tkn_data_name                 CONSTANT VARCHAR2(20)    := 'DATA_NAME';
  --
  cv_tkn_val_purge_xcbi_cnt        CONSTANT VARCHAR2(50)    := '�̎�v�Z�όڋq���f�[�^�폜����  �F ';
  cv_tkn_val_purge_xcbs_cnt        CONSTANT VARCHAR2(50)    := '�����ʔ̎�̋��f�[�^�폜����  �F ';
  cv_tkn_val_insert_xt0c_cnt       CONSTANT VARCHAR2(50)    := '�v�Z�ڋq���ꎞ�\�쐬����  �F ';
  cv_tkn_val_insert_xcbs_cnt       CONSTANT VARCHAR2(50)    := '�̎�̋��v�Z��������  �F ';
  cv_tkn_val_update_xsel_cnt       CONSTANT VARCHAR2(50)    := '�̔����і��׍X�V����  �F ';
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  -- �Z�p���[�^
  cv_msg_part                      CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                      CONSTANT VARCHAR2(3)     := '.';
  -- �v���t�@�C���E�I�v�V������
  cv_profile_name_01               CONSTANT VARCHAR2(50)    := 'ORG_ID';                            -- MO: �c�ƒP��
  cv_profile_name_02               CONSTANT VARCHAR2(50)    := 'GL_SET_OF_BKS_ID';                  -- ��v����ID
  cv_profile_name_03               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_FROM';     -- XXCOK:�̎�̋��v�Z�������ԁiFrom�j
  cv_profile_name_04               CONSTANT VARCHAR2(50)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';       -- XXCOK:�̎�̋��v�Z�������ԁiTo�j
  cv_profile_name_05               CONSTANT VARCHAR2(50)    := 'XXCOK1_SALES_RETENTION_PERIOD';     -- XXCOK:�̎�̋����ێ�����
  cv_profile_name_06               CONSTANT VARCHAR2(50)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';      -- �d�C���i�ϓ��j�i�ڃR�[�h
  cv_profile_name_07               CONSTANT VARCHAR2(50)    := 'XXCOK1_VENDOR_DUMMY_CODE';          -- �d����_�~�[�R�[�h
  cv_profile_name_08               CONSTANT VARCHAR2(50)    := 'XXCOK1_INSTANTLY_TERM_NAME';        -- �x������_��������
  cv_profile_name_09               CONSTANT VARCHAR2(50)    := 'XXCOK1_DEFAULT_TERM_NAME';          -- �x������_�f�t�H���g
  cv_profile_name_10               CONSTANT VARCHAR2(50)    := 'XXCOK1_ORG_CODE_SALES';             -- �݌ɑg�D�R�[�h_�c�Ƒg�D
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  cv_profile_name_11               CONSTANT VARCHAR2(50)    := 'XXCOK1_XSEL_DATA_LOCK';             -- �̔����і��׃f�[�^���b�N
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  -- �Q�ƃ^�C�v��
  cv_lookup_type_01                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_DISTRICT_PARA_MST';       -- �̎�̋��v�Z���s�敪
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi DELETE START
--  cv_lookup_type_02                CONSTANT VARCHAR2(30)    := 'XXCOK1_CONSUMPTION_TAX_CLASS';      -- ����ŋ敪
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi DELETE END
  cv_lookup_type_03                CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_SHO';             -- �Ƒԁi�����ށj
  cv_lookup_type_04                CONSTANT VARCHAR2(30)    := 'XXCMM_ITM_YOKIGUN';                 -- �e��Q
  cv_lookup_type_05                CONSTANT VARCHAR2(30)    := 'XXCOS1_NO_INV_ITEM_CODE';           -- ��݌ɕi��
  cv_lookup_type_06                CONSTANT VARCHAR2(30)    := 'XXCMM_CUST_GYOTAI_CHU';             -- �Ƒԁi�����ށj
  cv_lookup_type_07                CONSTANT VARCHAR2(30)    := 'XXCOK1_CALC_SALES_CLASS';           -- �̎�v�Z�Ώ۔���敪
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
  cv_lookup_type_08                CONSTANT VARCHAR2(30)    := 'XXCOK1_BM_TARGET_CUST_STATUS';      -- �̎�v�Z�Ώیڋq�X�e�[�^�X
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
  -- �L���t���O
  cv_enable                        CONSTANT VARCHAR2(1)     := 'Y';
-- 2009/11/09 Ver.3.4 [�d�l�ύXI_E_633] SCS K.Yamaguchi ADD START
  cv_disable                       CONSTANT VARCHAR2(1)     := 'N';
-- 2009/11/09 Ver.3.4 [�d�l�ύXI_E_633] SCS K.Yamaguchi ADD END
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  cv_vendor_dummy_on             CONSTANT VARCHAR2(1)  := '1';
  cv_vendor_dummy_off            CONSTANT VARCHAR2(1)  := '0';
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
  -- ���ʊ֐����b�Z�[�W�o�͋敪
  cv_which_log                     CONSTANT VARCHAR2(10)    := 'LOG';
  -- �����t�H�[�}�b�g
  cv_format_fxrrrrmmdd             CONSTANT VARCHAR2(50)    := 'FXRRRR/MM/DD';
  -- �����ʔ̎�̋��e�[�u���A�g�X�e�[�^�X
  cv_xcbs_if_status_no             CONSTANT VARCHAR2(1)     := '0'; -- ������
  cv_xcbs_if_status_yes            CONSTANT VARCHAR2(1)     := '1'; -- ������
  cv_xcbs_if_status_off            CONSTANT VARCHAR2(1)     := '2'; -- �s�v
  -- �ڋq�g�p�ړI
  cv_site_use_code_ship            CONSTANT VARCHAR2(10)    := 'SHIP_TO'; -- �o�א�
  cv_site_use_code_bill            CONSTANT VARCHAR2(10)    := 'BILL_TO'; -- ������
  -- �x����
  cv_month_type1                   CONSTANT VARCHAR2(2)     := '40'; -- ����
  cv_month_type2                   CONSTANT VARCHAR2(2)     := '50'; -- ����
  -- �T�C�g
  cv_site_type1                    CONSTANT VARCHAR2(2)     := '00'; -- ����
  cv_site_type2                    CONSTANT VARCHAR2(2)     := '01'; -- ����
  -- �_��Ǘ��X�e�[�^�X
  cv_xcm_status_result             CONSTANT VARCHAR2(1)     := '1'; -- �m��
  -- �����ʔ̎�̋��e�[�u�����z�m��X�e�[�^�X
  cv_xcbs_temp                     CONSTANT VARCHAR2(1)     := '0'; -- ���m��
  cv_xcbs_fix                      CONSTANT VARCHAR2(1)     := '1'; -- �m��
  -- �萔���v�Z�C���^�[�t�F�[�X�σt���O
  cv_xsel_if_flag_yes              CONSTANT VARCHAR2(1)     := 'Y'; -- ������
  cv_xsel_if_flag_no               CONSTANT VARCHAR2(1)     := 'N'; -- ������
  -- �ڋq�敪
  cv_customer_class_customer       CONSTANT VARCHAR2(2)     := '10'; -- �ڋq
  -- �Ƒԁi�����ށj
  cv_gyotai_sho_24                 CONSTANT VARCHAR2(2)     := '24'; -- �t���T�[�r�XVD�i�����j
  cv_gyotai_sho_25                 CONSTANT VARCHAR2(2)     := '25'; -- �t���T�[�r�XVD
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi ADD START
  cv_gyotai_sho_26                 CONSTANT VARCHAR2(2)     := '26'; -- �[�iVD
  cv_gyotai_sho_27                 CONSTANT VARCHAR2(2)     := '27'; -- ����VD
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi ADD END
  -- �Ƒԁi�����ށj
  cv_gyotai_tyu_vd                 CONSTANT VARCHAR2(2)     := '11'; -- VD
  -- �c�Ɠ��擾�֐��E�����敪
  cn_proc_type_before              CONSTANT NUMBER          := 1;  -- �O
  cn_proc_type_after               CONSTANT NUMBER          := 2;  -- ��
  -- �e��敪�R�[�h
  cv_container_code_others         CONSTANT VARCHAR2(4)     := '9999';   -- ���̑�
  -- �v�Z����
  cv_calc_type_sales_price         CONSTANT VARCHAR2(2)     := '10';  -- �����ʏ���
  cv_calc_type_container           CONSTANT VARCHAR2(2)     := '20';  -- �e��敪�ʏ���
  cv_calc_type_uniform_rate        CONSTANT VARCHAR2(2)     := '30';  -- �ꗥ����
  cv_calc_type_flat_rate           CONSTANT VARCHAR2(2)     := '40';  -- ��z
  cv_calc_type_electricity_cost    CONSTANT VARCHAR2(2)     := '50';  -- �d�C���i�Œ�^�ϓ��j
  -- �[�������敪
  cv_tax_rounding_rule_nearest     CONSTANT VARCHAR2(10)    :=  'NEAREST'; -- �l�̌ܓ�
  cv_tax_rounding_rule_up          CONSTANT VARCHAR2(10)    :=  'UP';      -- �؂�グ
  cv_tax_rounding_rule_down        CONSTANT VARCHAR2(10)    :=  'DOWN';    -- �؂�̂�
-- 2010/02/03 Ver.3.7 [E_�{�ғ�_XXXXX] SCS K.Yamaguchi ADD START
  -- �ڋq�}�X�^�L���X�e�[�^�X
  cv_cust_status_available         CONSTANT VARCHAR2(1)     := 'A';  -- �L��
-- 2010/02/03 Ver.3.7 [E_�{�ғ�_XXXXX] SCS K.Yamaguchi ADD END
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD START
  -- �ŃR�[�h�_�~�[
  ct_tax_code_dummy                CONSTANT ar_vat_tax_b.tax_code%TYPE := NULL;
  ct_tax_rate_dummy                CONSTANT ar_vat_tax_b.tax_rate%TYPE := NULL;
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  -- �����ʔ̎�̋��v�Z�����N���t���O
  cv_bm_proc_flag_1                CONSTANT VARCHAR2(1)     := '1';  -- �f�[�^�p�[�W����
  cv_bm_proc_flag_2                CONSTANT VARCHAR2(1)     := '2';  -- �v�Z�Ώیڋq�ꎞ�\�쐬
  cv_bm_proc_flag_3                CONSTANT VARCHAR2(1)     := '3';  -- �̎�̋��v�Z����
  cv_bm_proc_flag_4                CONSTANT VARCHAR2(1)     := '4';  -- �̔����эX�V����
  cv_bm_proc_flag_5                CONSTANT VARCHAR2(1)     := '5';  -- �v�Z�Ώیڋq�ꎞ�\�폜
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
-- Ver.3.19 SCSK K.Nara ADD START
  cv_tax_div_no_tax                CONSTANT VARCHAR2(2)     := '4';  -- ��ې�
-- Ver.3.19 SCSK K.Nara ADD END
  --==================================================
  -- �O���[�o���ϐ�
  --==================================================
  -- �J�E���^
  gn_target_cnt                    NUMBER        DEFAULT 0;      -- �Ώی���
  gn_normal_cnt                    NUMBER        DEFAULT 0;      -- ���팏��
  gn_error_cnt                     NUMBER        DEFAULT 0;      -- �ُ팏��
  gn_skip_cnt                      NUMBER        DEFAULT 0;      -- �X�L�b�v����
  gn_contract_err_cnt              NUMBER        DEFAULT 0;      -- �̎�����G���[����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  gn_vendor_err_cnt                NUMBER        DEFAULT 0;      -- �x����s������
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  gn_purge_xcbi_cnt                NUMBER        DEFAULT 0;      -- �̎�v�Z�όڋq���f�[�^�폜����
  gn_purge_xcbs_cnt                NUMBER        DEFAULT 0;      -- �����ʔ̎�̋��f�[�^�폜����
  gn_insert_xt0c_cnt               NUMBER        DEFAULT 0;      -- �v�Z�ڋq���ꎞ�\�쐬����
  gn_insert_xcbs_cnt               NUMBER        DEFAULT 0;      -- �̎�̋��v�Z��������
  gn_update_xsel_cnt               NUMBER        DEFAULT 0;      -- �̔����і��׍X�V����
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  -- ���̓p�����[�^
  gv_param_proc_date               VARCHAR2(10)  DEFAULT NULL;   -- �Ɩ����t
  gv_param_proc_type               VARCHAR2(10)  DEFAULT NULL;   -- �����敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  gv_param_proc_flag               VARCHAR2(10)  DEFAULT NULL;   -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  -- ���������擾�l
  gd_process_date                  DATE          DEFAULT NULL;   -- �Ɩ��������t
  gn_org_id                        NUMBER        DEFAULT NULL;   -- �c�ƒP��ID
  gn_set_of_books_id               NUMBER        DEFAULT NULL;   -- ��v����ID
  gn_bm_support_period_from        NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋��v�Z�������ԁiFrom�j
  gn_bm_support_period_to          NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋��v�Z�������ԁiTo�j
  gn_sales_retention_period        NUMBER        DEFAULT NULL;   -- XXCOK:�̎�̋����ێ�����
  gv_elec_change_item_code         VARCHAR2(7)   DEFAULT NULL;   -- �d�C���i�ϓ��j�i�ڃR�[�h
  gv_vendor_dummy_code             VARCHAR2(9)   DEFAULT NULL;   -- �d����_�~�[�R�[�h
  gv_instantly_term_name           VARCHAR2(8)   DEFAULT NULL;   -- �x������_��������
  gv_default_term_name             VARCHAR2(8)   DEFAULT NULL;   -- �x������_�f�t�H���g
  gv_organization_code             VARCHAR2(10)  DEFAULT NULL;   -- �݌ɑg�D�R�[�h_�c�Ƒg�D
  gt_calendar_code                 mtl_parameters.calendar_code%TYPE DEFAULT NULL; -- �݌ɑg�D�R�[�h_�c�Ƒg�D-�J�����_�R�[�h
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  gv_xsel_data_lock                VARCHAR2(1)   DEFAULT NULL;   -- �̎�̋�_�̔����і��׃��b�N
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  --==================================================
  -- ���ʗ�O
  --==================================================
  --*** ���������ʗ�O ***
  global_process_expt              EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt                  EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt           EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --*** ���b�N�擾�G���[ ***
  resource_busy_expt               EXCEPTION;
  PRAGMA EXCEPTION_INIT( resource_busy_expt, -54 );
  --==================================================
  -- �O���[�o����O
  --==================================================
  --*** �G���[�I�� ***
  error_proc_expt                  EXCEPTION;
  --*** �x���X�L�b�v ***
  warning_skip_expt                EXCEPTION;
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
  -- �ڋq���
  CURSOR get_cust_data_cur IS
    SELECT /*+ ORDERED */
           ship_hca.account_number                     AS ship_cust_code             -- �y�o�א�z�ڋq�R�[�h
         , gyotai_chu_flvv.lookup_code                 AS ship_gyotai_tyu            -- �y�o�א�z�Ƒԁi�����ށj
         , ship_xca.business_low_type                  AS ship_gyotai_sho            -- �y�o�א�z�Ƒԁi�����ށj
         , ship_xca.delivery_chain_code                AS ship_delivery_chain_code   -- �y�o�א�z�[�i��`�F�[���R�[�h
         , bill_hca.account_number                     AS bill_cust_code             -- �y������z�ڋq�R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT ( CASE
                              WHEN (   (xcm.close_day_code       IS NULL)
                                    OR (xcm.transfer_day_code    IS NULL)
                                    OR (xcm.transfer_month_code  IS NULL)
                                   )
                              THEN
                                gv_default_term_name
                              ELSE
                                   xcm.close_day_code
                                || '_'
                                || xcm.transfer_day_code
                                || '_'
                                || ( CASE
                                       WHEN xcm.transfer_month_code = cv_month_type1 THEN
                                         cv_site_type1
                                       ELSE
                                         cv_site_type2
                                     END
                                   )
                            END
                          )
                   FROM xxcso_contract_managements  xcm
                   WHERE xcm.contract_management_id = ( SELECT MAX( xcm2.contract_management_id )
                                                        FROM xxcso_contract_managements  xcm2
                                                        WHERE xcm2.install_account_id = ship_hca.cust_account_id
                                                          AND xcm2.status             = cv_xcm_status_result
                                                      )
                 )
               ELSE
                 ( SELECT rtv.name
                   FROM ra_terms_vl  rtv
                   WHERE rtv.term_id = bill_hcsu.payment_term_id
                 )
             END
           )                                           AS term_name1                 -- �x������
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 NULL
               ELSE
                 ( SELECT rtv.name
                   FROM ra_terms_vl  rtv
                   WHERE rtv.term_id = TO_NUMBER( bill_hcsu.attribute2 )
                 )
             END
           )                                           AS term_name2                 -- ��2�x������
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 NULL
               ELSE
                 ( SELECT rtv.name
                   FROM ra_terms_vl  rtv
                   WHERE rtv.term_id = TO_NUMBER( bill_hcsu.attribute3 )
                 )
             END
           )                                           AS term_name3                 -- ��3�x������
         , (CASE
              WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                gn_bm_support_period_to
              ELSE
                TO_NUMBER( bill_hcsu.attribute8 )
            END
           )                                           AS settle_amount_cycle        -- ���z�m��T�C�N��
         , bill_xca.tax_div                            AS tax_div                    -- ����ŋ敪
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi REPAIR START
--         , bill_avtb.tax_code                          AS tax_code                   -- �ŋ��R�[�h
--         , bill_avtb.tax_rate                          AS tax_rate                   -- �ŗ�
         , ct_tax_code_dummy                           AS tax_code                   -- �ŋ��R�[�h�i�_�~�[�lNULL�j
         , ct_tax_rate_dummy                           AS tax_rate                   -- �ŗ��i�_�~�[�lNULL�j
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi REPAIR END
         , bill_hcsu.tax_rounding_rule                 AS tax_rounding_rule          -- �[�������敪
         , ( CASE
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN gyotai_chu_flvv.lookup_code = cv_gyotai_tyu_vd THEN
               WHEN ship_xca.business_low_type IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) THEN
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
                 ship_xca.contractor_supplier_code
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN (     ( gyotai_chu_flvv.lookup_code   <> cv_gyotai_tyu_vd )
--                      AND ( ship_xca.receiv_discount_rate IS NOT NULL         )
--                    )
               WHEN (     ( ship_xca.business_low_type    NOT IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) )
                      AND ( ship_xca.receiv_discount_rate IS NOT NULL                                   )
                    )
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
               THEN
                 gv_vendor_dummy_code
               ELSE
                 NULL
             END
           )                                           AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.vendor_site_code
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.contractor_supplier_code
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT  pvs.attribute4
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.contractor_supplier_code
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
         , ( CASE
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN gyotai_chu_flvv.lookup_code = cv_gyotai_tyu_vd THEN
               WHEN ship_xca.business_low_type IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) THEN
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
                 ship_xca.bm_pay_supplier_code1
               ELSE
                 NULL
             END
           )                                           AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.vendor_site_code
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code1
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.attribute4
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code1
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
         , ( CASE
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--               WHEN gyotai_chu_flvv.lookup_code = cv_gyotai_tyu_vd THEN
               WHEN ship_xca.business_low_type IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 ) THEN
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
                 ship_xca.bm_pay_supplier_code2
               ELSE
                 NULL
             END
           )                                           AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.vendor_site_code
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code2
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
         , ( CASE
               WHEN ship_xca.business_low_type = cv_gyotai_sho_25 THEN
                 ( SELECT pvs.attribute4
                   FROM po_vendors       pv
                      , po_vendor_sites  pvs
                   WHERE pv.segment1        = ship_xca.bm_pay_supplier_code2
                     AND pvs.vendor_id      = pv.vendor_id
                 )
               ELSE
                 NULL
             END
           )                                           AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
         , ship_xca.receiv_discount_rate               AS receiv_discount_rate       -- �����l����
         , ( CASE
               WHEN ship_xcbi.last_fix_closing_date IS NOT NULL THEN
                 ship_xcbi.last_fix_closing_date + 1
               ELSE
                 NULL
               END
           )                                           AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
         , ship_xca.sale_base_code                     AS sale_base_code             -- ���㋒�_�R�[�h
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
         , proc_flvv.attribute1                        AS proc_type                  -- ���s�敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    FROM fnd_lookup_values_vl      proc_flvv
       , hz_locations              ship_hl
       , hz_party_sites            ship_hps
       , hz_cust_acct_sites        ship_hcas
       , hz_cust_accounts          ship_hca
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
       , hz_parties                ship_hp
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
       , xxcmm_cust_accounts       ship_xca
       , hz_cust_site_uses         ship_hcsu
       , xxcok_cust_bm_info        ship_xcbi
       , hz_cust_site_uses         bill_hcsu
       , hz_cust_acct_sites        bill_hcas
       , hz_cust_accounts          bill_hca
       , xxcmm_cust_accounts       bill_xca
       , fnd_lookup_values_vl      gyotai_sho_flvv
       , fnd_lookup_values_vl      gyotai_chu_flvv
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi DELETE START
--       , fnd_lookup_values_vl      tax_flvv
--       , ar_vat_tax_b              bill_avtb
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi DELETE END
    WHERE proc_flvv.lookup_type        = cv_lookup_type_01
      AND proc_flvv.attribute1         = gv_param_proc_type
      AND proc_flvv.enabled_flag       = cv_enable
      AND gd_process_date        BETWEEN NVL( proc_flvv.start_date_active, gd_process_date )
                                     AND NVL( proc_flvv.end_date_active  , gd_process_date )
      AND ship_hl.address3          LIKE proc_flvv.lookup_code || '%'
      AND ship_hps.location_id         = ship_hl.location_id
      AND ship_hcas.party_site_id      = ship_hps.party_site_id
      AND ship_hca.cust_account_id     = ship_hcas.cust_account_id
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--      AND EXISTS ( SELECT
--                          'X'
--                   FROM xxcos_sales_exp_headers  xseh
--                   WHERE xseh.ship_to_customer_code  = ship_hca.account_number
--                     AND ROWNUM = 1
--          )
      AND ship_hca.party_id            = ship_hp.party_id
      AND ship_hp.duns_number_c IN (
            SELECT flvv.lookup_code
            FROM fnd_lookup_values_vl  flvv
            WHERE flvv.lookup_type             = cv_lookup_type_08
              AND flvv.enabled_flag            = cv_enable
-- 2010/04/06 Ver.3.10 [E_�{�ғ�_01896] [E_�{�ғ�_01870] SCS K.Yamaguchi REPAIR START
--              AND flvv.start_date_active BETWEEN NVL( flvv.start_date_active, gd_process_date )
--                                             AND NVL( flvv.end_date_active  , gd_process_date )
              AND gd_process_date        BETWEEN NVL( flvv.start_date_active, gd_process_date )
                                             AND NVL( flvv.end_date_active  , gd_process_date )
-- 2010/04/06 Ver.3.10 [E_�{�ғ�_01896] [E_�{�ғ�_01870] SCS K.Yamaguchi REPAIR END
          )
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
      AND ship_xca.customer_id         = ship_hca.cust_account_id
      AND ship_hca.customer_class_code = cv_customer_class_customer
      AND ship_hca.account_number      = ship_xcbi.cust_code(+)
      AND ship_hcsu.cust_acct_site_id  = ship_hcas.cust_acct_site_id
      AND ship_hcsu.site_use_code      = cv_site_use_code_ship
      AND bill_hcsu.site_use_id        = ship_hcsu.bill_to_site_use_id
      AND bill_hcsu.site_use_code      = cv_site_use_code_bill
-- 2010/02/03 Ver.3.7 [E_�{�ғ�_XXXXX] SCS K.Yamaguchi ADD START
      AND ship_hcsu.status             = cv_cust_status_available
      AND bill_hcsu.status             = cv_cust_status_available
-- 2010/02/03 Ver.3.7 [E_�{�ғ�_XXXXX] SCS K.Yamaguchi ADD END
      AND bill_hcas.cust_acct_site_id  = bill_hcsu.cust_acct_site_id
      AND bill_hca.cust_account_id     = bill_hcas.cust_account_id
      AND bill_xca.customer_id         = bill_hca.cust_account_id
      AND gyotai_sho_flvv.lookup_type  = cv_lookup_type_03
      AND gyotai_sho_flvv.enabled_flag = cv_enable
      AND gd_process_date        BETWEEN NVL( gyotai_sho_flvv.start_date_active, gd_process_date )
                                     AND NVL( gyotai_sho_flvv.end_date_active  , gd_process_date )
      AND gyotai_sho_flvv.lookup_code  = ship_xca.business_low_type
      AND gyotai_chu_flvv.lookup_type  = cv_lookup_type_06
      AND gyotai_chu_flvv.enabled_flag = cv_enable
      AND gd_process_date        BETWEEN NVL( gyotai_chu_flvv.start_date_active, gd_process_date )
                                     AND NVL( gyotai_chu_flvv.end_date_active  , gd_process_date )
      AND gyotai_chu_flvv.lookup_code  = gyotai_sho_flvv.attribute1
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--      AND (    ( gyotai_sho_flvv.lookup_code IN( cv_gyotai_sho_24, cv_gyotai_sho_25 ) )
--            OR ( gyotai_chu_flvv.lookup_code <> cv_gyotai_tyu_vd                      )
--          )
      AND (    ( gyotai_sho_flvv.lookup_code IN(   cv_gyotai_sho_24
                                                 , cv_gyotai_sho_25
                                                 , cv_gyotai_sho_26
                                                 , cv_gyotai_sho_27
                                               )                     )
            OR ( gyotai_chu_flvv.lookup_code <> cv_gyotai_tyu_vd     )
          )
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi DELETE START
--      AND tax_flvv.lookup_type         = cv_lookup_type_02
--      AND tax_flvv.lookup_code         = bill_xca.tax_div
--      AND tax_flvv.enabled_flag        = cv_enable
--      AND gd_process_date        BETWEEN NVL( tax_flvv.start_date_active, gd_process_date )
--                                     AND NVL( tax_flvv.end_date_active  , gd_process_date )
--      AND bill_avtb.tax_code           = tax_flvv.attribute1
--      AND bill_avtb.validate_flag      = cv_enable
--      AND gd_process_date        BETWEEN NVL( bill_avtb.start_date, gd_process_date )
--                                     AND NVL( bill_avtb.end_date  , gd_process_date )
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi DELETE END
  ;
  -- �̔����я��E�����ʏ���
  CURSOR get_sales_data_cur1 IS
    SELECT xbc.sales_base_code                                     AS base_code                -- ���_�R�[�h
         , xbc.results_employee_code                               AS emp_code                 -- �S���҃R�[�h
         , xbc.ship_to_customer_code                               AS ship_cust_code           -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                     AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                     AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                      AS bill_cust_code           -- �ڋq�y������z
         , xbc.period_year                                         AS period_year              -- ��v�N�x
         , xbc.ship_delivery_chain_code                            AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                         AS delivery_ym              -- �[�i���N��
         , SUM( xbc.dlv_qty )                                      AS dlv_qty                  -- �[�i����
         , xbc.dlv_uom_code                                        AS dlv_uom_code             -- �[�i�P��
         , SUM( xbc.amount_inc_tax )                               AS amount_inc_tax           -- ������z�i�ō��j
-- Ver.3.20 N.Abe ADD START
        ,  SUM( xbc.pure_amount )                                  AS amount_no_tax            -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
         , xbc.container_code                                      AS container_code           -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                      AS dlv_unit_price           -- �������z
         , xbc.tax_div                                             AS tax_div                  -- ����ŋ敪
         , xbc.tax_code                                            AS tax_code                 -- �ŋ��R�[�h
         , xbc.tax_rate                                            AS tax_rate                 -- ����ŗ�
         , xbc.tax_rounding_rule                                   AS tax_rounding_rule        -- �[�������敪
         , xbc.term_name                                           AS term_name                -- �x������
         , xbc.closing_date                                        AS closing_date             -- ���ߓ�
         , xbc.expect_payment_date                                 AS expect_payment_date      -- �x���\���
         , xbc.calc_target_period_from                             AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                               AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                           AS calc_type                -- �v�Z����
         , xbc.bm1_vendor_code                                     AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                 AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                             AS bm1_pct                  -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                             AS bm1_amt                  -- �y�a�l�P�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm1_pct / 100 )  AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
--         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm1_amt )               AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm1_tax_kbn = '1' THEN
               ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm1_pct / 100 )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN xbc.bm1_tax_kbn = '2' THEN
               CASE
                 WHEN SUM( xbc.pure_amount ) * xbc.bm1_pct >= 0 THEN
                   CEIL( SUM( xbc.pure_amount ) * xbc.bm1_pct / 100 )
                 WHEN SUM( xbc.pure_amount ) * xbc.bm1_pct < 0 THEN
                   FLOOR( SUM( xbc.pure_amount ) * xbc.bm1_pct / 100 )
               END
           END                                                     AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z_��
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm1_tax_kbn = '1' THEN
               ROUND( SUM( xbc.dlv_qty ) * xbc.bm1_amt )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN xbc.bm1_tax_kbn = '2' THEN
               CASE
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm1_amt >= 0 THEN
                   CEIL( SUM( xbc.dlv_qty ) * xbc.bm1_amt )
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm1_amt < 0 THEN
                   FLOOR( SUM( xbc.dlv_qty ) * xbc.bm1_amt )
               END
           END                                                     AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                    AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
-- Ver.3.20 N.Abe ADD START
         , NULL                                                    AS bm1_electric_amt_no_tax  -- �y�a�l�P�z�d�C��(�Ŕ�)
-- Ver.3.20 N.Abe ADD END 
         , xbc.bm2_vendor_code                                     AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                 AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                             AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                             AS bm2_amt                  -- �y�a�l�Q�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm2_pct / 100 )  AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
--         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm2_amt )               AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm2_tax_kbn = '1' THEN
               ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm2_pct / 100 )
             -- BM2�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN xbc.bm2_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.pure_amount ) * xbc.bm2_pct >= 0 THEN
                   CEIL( SUM( xbc.pure_amount ) * xbc.bm2_pct / 100 )
                 WHEN SUM( xbc.pure_amount ) * xbc.bm2_pct < 0 THEN
                   FLOOR( SUM( xbc.pure_amount ) * xbc.bm2_pct / 100 )
               END
           END                                                     AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z_��
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm2_tax_kbn = '1' THEN
               ROUND( SUM( xbc.dlv_qty ) * xbc.bm2_amt )
             -- BM2�ŋ敪 = '2':�Ŕ��A����'3'(��ې�)
             WHEN xbc.bm2_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm2_amt >= 0 THEN
                   CEIL( SUM( xbc.dlv_qty ) * xbc.bm2_amt )
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm2_amt < 0 THEN
                   FLOOR( SUM( xbc.dlv_qty ) * xbc.bm2_amt )
               END
           END                                                     AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                    AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                     AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                 AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                             AS bm3_pct                  -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                             AS bm3_amt                  -- �y�a�l�R�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm3_pct / 100 )  AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
--         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm3_amt )               AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm3_tax_kbn = '1' THEN
               ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm3_pct / 100 )
             -- BM3�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN xbc.bm3_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.pure_amount ) * xbc.bm3_pct >= 0 THEN
                   CEIL( SUM( xbc.pure_amount ) * xbc.bm3_pct / 100 )
                 WHEN SUM( xbc.pure_amount ) * xbc.bm3_pct < 0 THEN
                   FLOOR( SUM( xbc.pure_amount ) * xbc.bm3_pct / 100 )
               END
           END                                                     AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z_��
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm3_tax_kbn = '1' THEN
               ROUND( SUM( xbc.dlv_qty ) * xbc.bm3_amt )
             -- BM3�ŋ敪 = '2':�Ŕ��A����'3'(��ې�)
             WHEN xbc.bm3_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm3_amt >= 0 THEN
                   CEIL( SUM( xbc.dlv_qty ) * xbc.bm3_amt )
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm3_amt < 0 THEN
                   FLOOR( SUM( xbc.dlv_qty ) * xbc.bm3_amt )
               END
           END                                                     AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                    AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                           AS item_code                -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                     AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
         , xbc.vendor_dummy_flag                                   AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
         , xbc.bm1_tax_kbn                                         AS bm1_tax_kbn              -- BM1�ŋ敪
         , xbc.bm2_tax_kbn                                         AS bm2_tax_kbn              -- BM2�ŋ敪
         , xbc.bm3_tax_kbn                                         AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
    FROM ( SELECT xse.sales_base_code                                                              AS sales_base_code          -- ���㋒�_�R�[�h
                , NVL2( xmbc.calc_type, xse.results_employee_code              , NULL )            AS results_employee_code    -- ���ьv��҃R�[�h
                , xse.ship_to_customer_code                                                        AS ship_to_customer_code    -- �y�o�א�z�ڋq�R�[�h
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho                    , NULL )            AS ship_gyotai_sho          -- �y�o�א�z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu                    , NULL )            AS ship_gyotai_tyu          -- �y�o�א�z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.bill_cust_code                     , NULL )            AS bill_cust_code           -- �y������z�ڋq�R�[�h
                , NVL2( xmbc.calc_type, xse.period_year                        , NULL )            AS period_year              -- ��v�N�x
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code           , NULL )            AS ship_delivery_chain_code -- �y�o�א�z�[�i��`�F�[���R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--                , NVL2( xmbc.calc_type, TO_CHAR( xse.delivery_date, 'RRRRMM' ) , NULL )            AS delivery_ym              -- �[�i�N��
                , NVL2( xmbc.calc_type, TO_CHAR( xse.closing_date, 'RRRRMM' )  , NULL )            AS delivery_ym              -- �[�i�N��
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
                , NVL2( xmbc.calc_type, xse.dlv_qty                            , NULL )            AS dlv_qty                  -- �[�i����
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                       , NULL )            AS dlv_uom_code             -- �[�i�P��
                , xse.pure_amount + xse.tax_amount                                                 AS amount_inc_tax           -- ������z�i�ō��j
-- Ver.3.20 N.Abe ADD START
                , xse.pure_amount                                                                  AS pure_amount              -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
                , NVL2( xmbc.calc_type, NULL, NVL( flv1.attribute1, cv_container_code_others ) )   AS container_code           -- �e��敪�R�[�h
                , xse.dlv_unit_price                                                               AS dlv_unit_price           -- �������z
                , NVL2( xmbc.calc_type, xse.tax_div                            , NULL )            AS tax_div                  -- ����ŋ敪
                , NVL2( xmbc.calc_type, xse.tax_code                           , NULL )            AS tax_code                 -- �ŋ��R�[�h
                , NVL2( xmbc.calc_type, xse.tax_rate                           , NULL )            AS tax_rate                 -- ����ŗ�
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule                  , NULL )            AS tax_rounding_rule        -- �[�������敪
                , NVL2( xmbc.calc_type, xse.term_name                          , NULL )            AS term_name                -- �x������
                , xse.closing_date                                                                 AS closing_date             -- ���ߓ�
                , NVL2( xmbc.calc_type, xse.expect_payment_date                , NULL )            AS expect_payment_date      -- �x���\���
                , NVL2( xmbc.calc_type, xse.calc_target_period_from            , NULL )            AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to              , NULL )            AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                                   AS calc_type                -- �v�Z����
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code                    , NULL )            AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code               , NULL )            AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type                , NULL )            AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                           , NULL )            AS bm1_pct                  -- �y�a�l�P�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                           , NULL )            AS bm1_amt                  -- �y�a�l�P�zBM���z
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code                    , NULL )            AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code               , NULL )            AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type                , NULL )            AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                           , NULL )            AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                           , NULL )            AS bm2_amt                  -- �y�a�l�Q�zBM���z
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code                    , NULL )            AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code               , NULL )            AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type                , NULL )            AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                           , NULL )            AS bm3_pct                  -- �y�a�l�R�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                           , NULL )            AS bm3_amt                  -- �y�a�l�R�zBM���z
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                                      AS item_code                -- �G���[�i�ڃR�[�h
                , xse.amount_fix_date                                                              AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
                , xse.vendor_dummy_flag                                                            AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
                , NVL( xmbc.bm1_tax_kbn, '1' )                                                     AS bm1_tax_kbn              -- BM1�ŋ敪
                , NVL( xmbc.bm2_tax_kbn, '1' )                                                     AS bm2_tax_kbn              -- BM2�ŋ敪
                , NVL( xmbc.bm3_tax_kbn, '1' )                                                     AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--           FROM ( SELECT /*+ LEADING(xt0c xcbi xseh xsel xsim) USE_NL(xsel xsim) */
           FROM ( SELECT /*+
                           LEADING(xt0c xcbi hca xca)
                           USE_NL(xt0c xcbi xseh xsel xsim)
                           INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
                         */
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--                         xseh.sales_base_code                   AS sales_base_code             -- ���㋒�_�R�[�h
--                       , xseh.results_employee_code             AS results_employee_code       -- ���ьv��҃R�[�h
                         CASE
                           WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                             xca.sale_base_code
                           ELSE
                             xca.past_sale_base_code
                         END                                    AS sales_base_code             -- ���㋒�_�R�[�h
                       , xt0c.emp_code                          AS results_employee_code       -- ���ьv��҃R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
                       , xseh.ship_to_customer_code             AS ship_to_customer_code       -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_sho                   AS ship_gyotai_sho             -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_tyu                   AS ship_gyotai_tyu             -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.bill_cust_code                    AS bill_cust_code              -- �y������z�ڋq�R�[�h
                       , xt0c.period_year                       AS period_year                 -- ��v�N�x
                       , xt0c.ship_delivery_chain_code          AS ship_delivery_chain_code    -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xseh.delivery_date                     AS delivery_date               -- �[�i��
                       , xsel.dlv_qty                           AS dlv_qty                     -- �[�i����
                       , xsel.dlv_uom_code                      AS dlv_uom_code                -- �[�i�P��
                       , xsel.pure_amount                       AS pure_amount                 -- �{�̋��z 
                       , xsel.tax_amount                        AS tax_amount                  -- ����ŋ��z
                       , xsel.dlv_unit_price                    AS dlv_unit_price              -- �������z
                       , xt0c.tax_div                           AS tax_div                     -- ����ŋ敪
-- Ver.3.19 SCSK K.Nara MOD START
--                       , xt0c.tax_code                          AS tax_code                    -- �ŋ��R�[�h
--                       , xt0c.tax_rate                          AS tax_rate                    -- ����ŗ�
                       , CASE 
                           WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
                             xt0c.tax_code
                           ELSE 
                             NVL(xsel.tax_code, xseh.tax_code)
                         END                                    AS tax_code                    -- �ŋ��R�[�h
                       , CASE 
                           WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
                             xt0c.tax_rate
                           ELSE 
                             NVL(xsel.tax_rate, xseh.tax_rate)
                         END                                    AS tax_rate                    -- ����ŗ�
-- Ver.3.19 SCSK K.Nara MOD END
                       , xt0c.tax_rounding_rule                 AS tax_rounding_rule           -- �[�������敪
                       , xt0c.term_name                         AS term_name                   -- �x������
                       , xt0c.closing_date                      AS closing_date                -- ���ߓ�
                       , xt0c.expect_payment_date               AS expect_payment_date         -- �x���\���
                       , xt0c.calc_target_period_from           AS calc_target_period_from     -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to             AS calc_target_period_to       -- �v�Z�Ώۊ���(TO)
                       , xt0c.bm1_vendor_code                   AS bm1_vendor_code             -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code              AS bm1_vendor_site_code        -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type               AS bm1_bm_payment_type         -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code                   AS bm2_vendor_code             -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code              AS bm2_vendor_site_code        -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type               AS bm2_bm_payment_type         -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code                   AS bm3_vendor_code             -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code              AS bm3_vendor_site_code        -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type               AS bm3_bm_payment_type         -- �y�a�l�R�zBM�x���敪
                       , xsel.item_code                         AS item_code                   -- �݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date                   AS amount_fix_date             -- ���z�m���
                       , xsim.vessel_group                      AS vessel_group                -- �e��Q�R�[�h
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
                       , xt0c.vendor_dummy_flag                 AS vendor_dummy_flag           -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
                  FROM xxcmm_system_items_b        xsim  -- Disc�i�ڃA�h�I��
                     , xxcos_sales_exp_lines       xsel  -- �̔����і���
                     , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--                     , xxcok_tmp_014a01c_custdata  xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcok_wk_014a01c_custdata   xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
                     , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
                     , hz_cust_accounts            hca
                     , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--                  WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- �Ƒԁi�����ށj�FVD
                  WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
                    AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
                    AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
                    AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND EXISTS ( SELECT 'X'
                                 FROM xxcok_mst_bm_contract xmbc2 -- �̎�����}�X�^
                                 WHERE xmbc2.calc_type                = cv_calc_type_sales_price      -- �v�Z�����F�����ʏ���
                                   AND xmbc2.cust_code                = xseh.ship_to_customer_code
                                   AND xmbc2.calc_target_flag         = cv_enable
                                   AND xmbc2.container_type_code     IS NULL
                                   AND ROWNUM = 1
                        )
                    AND xsim.item_code              = xsel.item_code
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
                    AND xt0c.ship_cust_code         = hca.account_number
                    AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
                    AND EXISTS ( SELECT 'X'
                                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                  AND ROWNUM = 1
                        )
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values flv -- ��݌ɕi��
                                     WHERE flv.lookup_type         = cv_lookup_type_05 -- �Q�ƃ^�C�v�F��݌ɕi��
                                       AND flv.lookup_code         = xsel.item_code
                                       AND flv.language            = cv_lang
                                       AND flv.enabled_flag        = cv_enable
                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                 AND NVL( flv.end_date_active  , gd_process_date )
                                       AND ROWNUM = 1
                        )
                )                           xse   -- �̔����я��
              , fnd_lookup_values           flv1  -- �e��Q
              , xxcok_mst_bm_contract       xmbc  -- �̎�����}�X�^
           WHERE flv1.lookup_type(+)         = cv_lookup_type_04                         -- �Q�ƃ^�C�v�F�e��Q
             AND flv1.lookup_code(+)         = xse.vessel_group
             AND flv1.language(+)            = cv_lang
             AND flv1.enabled_flag(+)        = cv_enable
             AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                           AND NVL( flv1.end_date_active  , gd_process_date )
             AND xmbc.calc_type(+)           = cv_calc_type_sales_price                  -- �v�Z�����F�����ʏ���
             AND xmbc.cust_code(+)           = xse.ship_to_customer_code
             AND xmbc.calc_target_flag(+)    = cv_enable
             AND xmbc.selling_price(+)       = xse.dlv_unit_price
         ) xbc -- �̔����я��E�����ʏ���
    GROUP BY xbc.sales_base_code
           , xbc.results_employee_code
           , xbc.ship_to_customer_code
           , xbc.ship_gyotai_sho
           , xbc.ship_gyotai_tyu
           , xbc.bill_cust_code
           , xbc.period_year
           , xbc.ship_delivery_chain_code
           , xbc.delivery_ym
           , xbc.dlv_uom_code
           , xbc.container_code
           , xbc.dlv_unit_price
           , xbc.tax_div
           , xbc.tax_code
           , xbc.tax_rate
           , xbc.tax_rounding_rule
           , xbc.term_name
           , xbc.closing_date
           , xbc.expect_payment_date
           , xbc.calc_target_period_from
           , xbc.calc_target_period_to
           , xbc.calc_type
           , xbc.bm1_vendor_code
           , xbc.bm1_vendor_site_code
           , xbc.bm1_bm_payment_type
           , xbc.bm1_pct
           , xbc.bm1_amt
           , xbc.bm2_vendor_code
           , xbc.bm2_vendor_site_code
           , xbc.bm2_bm_payment_type
           , xbc.bm2_pct
           , xbc.bm2_amt
           , xbc.bm3_vendor_code
           , xbc.bm3_vendor_site_code
           , xbc.bm3_bm_payment_type
           , xbc.bm3_pct
           , xbc.bm3_amt
           , xbc.item_code
           , xbc.amount_fix_date
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
           , xbc.vendor_dummy_flag
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
           , xbc.bm1_tax_kbn
           , xbc.bm2_tax_kbn
           , xbc.bm3_tax_kbn
-- Ver.3.20 N.Abe ADD END
  ;
  -- �̔����я��E�e��敪�ʏ���
  CURSOR get_sales_data_cur2 IS
    SELECT xbc.sales_base_code                                     AS base_code                -- ���_�R�[�h
         , xbc.results_employee_code                               AS emp_code                 -- �S���҃R�[�h
         , xbc.ship_to_customer_code                               AS ship_cust_code           -- �ڋq�y�[�i��z
         , xbc.ship_gyotai_sho                                     AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.ship_gyotai_tyu                                     AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xbc.bill_cust_code                                      AS bill_cust_code           -- �ڋq�y������z
         , xbc.period_year                                         AS period_year              -- ��v�N�x
         , xbc.ship_delivery_chain_code                            AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
         , xbc.delivery_ym                                         AS delivery_ym              -- �[�i���N��
         , SUM( xbc.dlv_qty )                                      AS dlv_qty                  -- �[�i����
         , xbc.dlv_uom_code                                        AS dlv_uom_code             -- �[�i�P��
         , SUM( xbc.amount_inc_tax )                               AS amount_inc_tax           -- ������z�i�ō��j
-- Ver.3.20 N.Abe ADD START
        ,  SUM( xbc.pure_amount )                                  AS amount_no_tax            -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
         , xbc.container_code                                      AS container_code           -- �e��敪�R�[�h
         , xbc.dlv_unit_price                                      AS dlv_unit_price           -- �������z
         , xbc.tax_div                                             AS tax_div                  -- ����ŋ敪
         , xbc.tax_code                                            AS tax_code                 -- �ŋ��R�[�h
         , xbc.tax_rate                                            AS tax_rate                 -- ����ŗ�
         , xbc.tax_rounding_rule                                   AS tax_rounding_rule        -- �[�������敪
         , xbc.term_name                                           AS term_name                -- �x������
         , xbc.closing_date                                        AS closing_date             -- ���ߓ�
         , xbc.expect_payment_date                                 AS expect_payment_date      -- �x���\���
         , xbc.calc_target_period_from                             AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
         , xbc.calc_target_period_to                               AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
         , xbc.calc_type                                           AS calc_type                -- �v�Z����
         , xbc.bm1_vendor_code                                     AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
         , xbc.bm1_vendor_site_code                                AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xbc.bm1_bm_payment_type                                 AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
         , xbc.bm1_pct                                             AS bm1_pct                  -- �y�a�l�P�zBM��(%)
         , xbc.bm1_amt                                             AS bm1_amt                  -- �y�a�l�P�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm1_pct / 100 )  AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
--         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm1_amt )               AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm1_tax_kbn = '1' THEN
               ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm1_pct / 100 )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN xbc.bm1_tax_kbn = '2' THEN
               CASE
                 WHEN SUM( xbc.pure_amount ) * xbc.bm1_pct >= 0 THEN
                   CEIL( SUM( xbc.pure_amount ) * xbc.bm1_pct / 100 )
                 WHEN SUM( xbc.pure_amount ) * xbc.bm1_pct < 0 THEN
                   FLOOR( SUM( xbc.pure_amount ) * xbc.bm1_pct / 100 )
               END
           END                                                     AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z_��
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm1_tax_kbn = '1' THEN
               ROUND( SUM( xbc.dlv_qty ) * xbc.bm1_amt )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN xbc.bm1_tax_kbn = '2' THEN
               CASE
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm1_amt >= 0 THEN
                   CEIL( SUM( xbc.dlv_qty ) * xbc.bm1_amt )
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm1_amt < 0 THEN
                   FLOOR( SUM( xbc.dlv_qty ) * xbc.bm1_amt )
               END
           END                                                     AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                    AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
-- Ver.3.20 N.Abe ADD START
         , NULL                                                    AS bm1_electric_amt_no_tax  -- �y�a�l�P�z�d�C��(�Ŕ�)
-- Ver.3.20 N.Abe ADD END 
         , xbc.bm2_vendor_code                                     AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
         , xbc.bm2_vendor_site_code                                AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xbc.bm2_bm_payment_type                                 AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
         , xbc.bm2_pct                                             AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
         , xbc.bm2_amt                                             AS bm2_amt                  -- �y�a�l�Q�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm2_pct / 100 )  AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
--         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm2_amt )               AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm2_tax_kbn = '1' THEN
               ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm2_pct / 100 )
             -- BM2�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN xbc.bm2_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.pure_amount ) * xbc.bm2_pct >= 0 THEN
                   CEIL( SUM( xbc.pure_amount ) * xbc.bm2_pct / 100 )
                 WHEN SUM( xbc.pure_amount ) * xbc.bm2_pct < 0 THEN
                   FLOOR( SUM( xbc.pure_amount ) * xbc.bm2_pct / 100 )
               END
           END                                                     AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z_��
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm2_tax_kbn = '1' THEN
               ROUND( SUM( xbc.dlv_qty ) * xbc.bm2_amt )
             -- BM2�ŋ敪 = '2':�Ŕ��A����'3'(��ې�)
             WHEN xbc.bm2_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm2_amt >= 0 THEN
                   CEIL( SUM( xbc.dlv_qty ) * xbc.bm2_amt )
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm2_amt < 0 THEN
                   FLOOR( SUM( xbc.dlv_qty ) * xbc.bm2_amt )
               END
           END                                                     AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                    AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
         , xbc.bm3_vendor_code                                     AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
         , xbc.bm3_vendor_site_code                                AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xbc.bm3_bm_payment_type                                 AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
         , xbc.bm3_pct                                             AS bm3_pct                  -- �y�a�l�R�zBM��(%)
         , xbc.bm3_amt                                             AS bm3_amt                  -- �y�a�l�R�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm3_pct / 100 )  AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
--         , ROUND( SUM( xbc.dlv_qty ) * xbc.bm3_amt )               AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm3_tax_kbn = '1' THEN
               ROUND( SUM( xbc.amount_inc_tax ) * xbc.bm3_pct / 100 )
             -- BM3�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN xbc.bm3_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.pure_amount ) * xbc.bm3_pct >= 0 THEN
                   CEIL( SUM( xbc.pure_amount ) * xbc.bm3_pct / 100 )
                 WHEN SUM( xbc.pure_amount ) * xbc.bm3_pct < 0 THEN
                   FLOOR( SUM( xbc.pure_amount ) * xbc.bm3_pct / 100 )
               END
           END                                                     AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z_��
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN xbc.bm3_tax_kbn = '1' THEN
               ROUND( SUM( xbc.dlv_qty ) * xbc.bm3_amt )
             -- BM3�ŋ敪 = '2':�Ŕ��A����'3'(��ې�)
             WHEN xbc.bm3_tax_kbn IN ('2', '3') THEN
               CASE
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm3_amt >= 0 THEN
                   CEIL( SUM( xbc.dlv_qty ) * xbc.bm3_amt )
                 WHEN SUM( xbc.dlv_qty ) * xbc.bm3_amt < 0 THEN
                   FLOOR( SUM( xbc.dlv_qty ) * xbc.bm3_amt )
               END
           END                                                     AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                    AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
         , xbc.item_code                                           AS item_code                -- �G���[�i�ڃR�[�h
         , xbc.amount_fix_date                                     AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
         , xbc.vendor_dummy_flag                                   AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
         , xbc.bm1_tax_kbn                                         AS bm1_tax_kbn              -- BM1�ŋ敪
         , xbc.bm2_tax_kbn                                         AS bm2_tax_kbn              -- BM2�ŋ敪
         , xbc.bm3_tax_kbn                                         AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
    FROM ( SELECT xse.sales_base_code                                                              AS sales_base_code          -- ���㋒�_�R�[�h
                , NVL2( xmbc.calc_type, xse.results_employee_code              , NULL )            AS results_employee_code    -- ���ьv��҃R�[�h
                , xse.ship_to_customer_code                                                        AS ship_to_customer_code    -- �y�o�א�z�ڋq�R�[�h
                , NVL2( xmbc.calc_type, xse.ship_gyotai_sho                    , NULL )            AS ship_gyotai_sho          -- �y�o�א�z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.ship_gyotai_tyu                    , NULL )            AS ship_gyotai_tyu          -- �y�o�א�z�Ƒԁi�����ށj
                , NVL2( xmbc.calc_type, xse.bill_cust_code                     , NULL )            AS bill_cust_code           -- �y������z�ڋq�R�[�h
                , NVL2( xmbc.calc_type, xse.period_year                        , NULL )            AS period_year              -- ��v�N�x
                , NVL2( xmbc.calc_type, xse.ship_delivery_chain_code           , NULL )            AS ship_delivery_chain_code -- �y�o�א�z�[�i��`�F�[���R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--                , NVL2( xmbc.calc_type, TO_CHAR( xse.delivery_date, 'RRRRMM' ) , NULL )            AS delivery_ym              -- �[�i�N��
                , NVL2( xmbc.calc_type, TO_CHAR( xse.closing_date, 'RRRRMM' )  , NULL )            AS delivery_ym              -- �[�i�N��
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
                , NVL2( xmbc.calc_type, xse.dlv_qty                            , NULL )            AS dlv_qty                  -- �[�i����
                , NVL2( xmbc.calc_type, xse.dlv_uom_code                       , NULL )            AS dlv_uom_code             -- �[�i�P��
                , xse.pure_amount + xse.tax_amount                                                 AS amount_inc_tax           -- ������z�i�ō��j
-- Ver.3.20 N.Abe ADD START
                , xse.pure_amount                                                                  AS pure_amount              -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
                , NVL( xse.attribute1, cv_container_code_others )                                  AS container_code           -- �e��敪�R�[�h
                , NVL2( xmbc.calc_type, NULL, xse.dlv_unit_price )                                 AS dlv_unit_price           -- �������z
                , NVL2( xmbc.calc_type, xse.tax_div                            , NULL )            AS tax_div                  -- ����ŋ敪
                , NVL2( xmbc.calc_type, xse.tax_code                           , NULL )            AS tax_code                 -- �ŋ��R�[�h
                , NVL2( xmbc.calc_type, xse.tax_rate                           , NULL )            AS tax_rate                 -- ����ŗ�
                , NVL2( xmbc.calc_type, xse.tax_rounding_rule                  , NULL )            AS tax_rounding_rule        -- �[�������敪
                , NVL2( xmbc.calc_type, xse.term_name                          , NULL )            AS term_name                -- �x������
                , xse.closing_date                                                                 AS closing_date             -- ���ߓ�
                , NVL2( xmbc.calc_type, xse.expect_payment_date                , NULL )            AS expect_payment_date      -- �x���\���
                , NVL2( xmbc.calc_type, xse.calc_target_period_from            , NULL )            AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
                , NVL2( xmbc.calc_type, xse.calc_target_period_to              , NULL )            AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
                , xmbc.calc_type                                                                   AS calc_type                -- �v�Z����
                , NVL2( xmbc.calc_type, xse.bm1_vendor_code                    , NULL )            AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_vendor_site_code               , NULL )            AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm1_bm_payment_type                , NULL )            AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm1_pct                           , NULL )            AS bm1_pct                  -- �y�a�l�P�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm1_amt                           , NULL )            AS bm1_amt                  -- �y�a�l�P�zBM���z
                , NVL2( xmbc.calc_type, xse.bm2_vendor_code                    , NULL )            AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_vendor_site_code               , NULL )            AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm2_bm_payment_type                , NULL )            AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm2_pct                           , NULL )            AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm2_amt                           , NULL )            AS bm2_amt                  -- �y�a�l�Q�zBM���z
                , NVL2( xmbc.calc_type, xse.bm3_vendor_code                    , NULL )            AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_vendor_site_code               , NULL )            AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
                , NVL2( xmbc.calc_type, xse.bm3_bm_payment_type                , NULL )            AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
                , NVL2( xmbc.calc_type, xmbc.bm3_pct                           , NULL )            AS bm3_pct                  -- �y�a�l�R�zBM��(%)
                , NVL2( xmbc.calc_type, xmbc.bm3_amt                           , NULL )            AS bm3_amt                  -- �y�a�l�R�zBM���z
                , NVL2( xmbc.calc_type, NULL, xse.item_code )                                      AS item_code                -- �G���[�i�ڃR�[�h
                , xse.amount_fix_date                                                              AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
                , xse.vendor_dummy_flag                                                            AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
                , NVL( xmbc.bm1_tax_kbn, '1' )                                                     AS bm1_tax_kbn              -- BM1�ŋ敪
                , NVL( xmbc.bm2_tax_kbn, '1' )                                                     AS bm2_tax_kbn              -- BM2�ŋ敪
                , NVL( xmbc.bm3_tax_kbn, '1' )                                                     AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--           FROM ( SELECT /*+ LEADING(xt0c xcbi xseh xsel xsim) USE_NL(xsel xsim) */
           FROM ( SELECT /*+
                           LEADING(xt0c xcbi hca xca)
                           USE_NL(xt0c xcbi xseh xsel xsim)
                           INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
                         */
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--                         xseh.sales_base_code               AS sales_base_code                 -- ���㋒�_�R�[�h
--                       , xseh.results_employee_code         AS results_employee_code           -- ���ьv��҃R�[�h
                         CASE
                           WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                             xca.sale_base_code
                           ELSE
                             xca.past_sale_base_code
                         END                                AS sales_base_code                 -- ���㋒�_�R�[�h
                       , xt0c.emp_code                      AS results_employee_code           -- ���ьv��҃R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
                       , xseh.ship_to_customer_code         AS ship_to_customer_code           -- �y�o�א�z�ڋq�R�[�h
                       , xt0c.ship_gyotai_sho               AS ship_gyotai_sho                 -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.ship_gyotai_tyu               AS ship_gyotai_tyu                 -- �y�o�א�z�Ƒԁi�����ށj
                       , xt0c.bill_cust_code                AS bill_cust_code                  -- �y������z�ڋq�R�[�h
                       , xt0c.period_year                   AS period_year                     -- ��v�N�x
                       , xt0c.ship_delivery_chain_code      AS ship_delivery_chain_code        -- �y�o�א�z�[�i��`�F�[���R�[�h
                       , xseh.delivery_date                 AS delivery_date                   -- �[�i��
                       , xsel.dlv_qty                       AS dlv_qty                         -- �[�i����
                       , xsel.dlv_uom_code                  AS dlv_uom_code                    -- �[�i�P��
                       , xsel.pure_amount                   AS pure_amount                     -- �{�̋��z
                       , xsel.tax_amount                    AS tax_amount                      -- ����ŋ��z
                       , xsel.dlv_unit_price                AS dlv_unit_price                  -- �������z
                       , xt0c.tax_div                       AS tax_div                         -- ����ŋ敪
-- Ver.3.19 SCSK K.Nara MOD START
--                       , xt0c.tax_code                      AS tax_code                        -- �ŋ��R�[�h
--                       , xt0c.tax_rate                      AS tax_rate                        -- ����ŗ�
                       , CASE 
                           WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
                             xt0c.tax_code
                           ELSE 
                             NVL(xsel.tax_code, xseh.tax_code)
                         END                                    AS tax_code                    -- �ŋ��R�[�h
                       , CASE 
                           WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
                             xt0c.tax_rate
                           ELSE 
                             NVL(xsel.tax_rate, xseh.tax_rate)
                         END                                    AS tax_rate                    -- ����ŗ�
-- Ver.3.19 SCSK K.Nara MOD END
                       , xt0c.tax_rounding_rule             AS tax_rounding_rule               -- �[�������敪
                       , xt0c.term_name                     AS term_name                       -- �x������
                       , xt0c.closing_date                  AS closing_date                    -- ���ߓ�
                       , xt0c.expect_payment_date           AS expect_payment_date             -- �x���\���
                       , xt0c.calc_target_period_from       AS calc_target_period_from         -- �v�Z�Ώۊ���(FROM)
                       , xt0c.calc_target_period_to         AS calc_target_period_to           -- �v�Z�Ώۊ���(TO)
                       , xt0c.bm1_vendor_code               AS bm1_vendor_code                 -- �y�a�l�P�z�d����R�[�h
                       , xt0c.bm1_vendor_site_code          AS bm1_vendor_site_code            -- �y�a�l�P�z�d����T�C�g�R�[�h
                       , xt0c.bm1_bm_payment_type           AS bm1_bm_payment_type             -- �y�a�l�P�zBM�x���敪
                       , xt0c.bm2_vendor_code               AS bm2_vendor_code                 -- �y�a�l�Q�z�d����R�[�h
                       , xt0c.bm2_vendor_site_code          AS bm2_vendor_site_code            -- �y�a�l�Q�z�d����T�C�g�R�[�h
                       , xt0c.bm2_bm_payment_type           AS bm2_bm_payment_type             -- �y�a�l�Q�zBM�x���敪
                       , xt0c.bm3_vendor_code               AS bm3_vendor_code                 -- �y�a�l�R�z�d����R�[�h
                       , xt0c.bm3_vendor_site_code          AS bm3_vendor_site_code            -- �y�a�l�R�z�d����T�C�g�R�[�h
                       , xt0c.bm3_bm_payment_type           AS bm3_bm_payment_type             -- �y�a�l�R�zBM�x���敪
                       , xsel.item_code                     AS item_code                       -- �݌ɕi�ڃR�[�h
                       , xt0c.amount_fix_date               AS amount_fix_date                 -- ���z�m���
                       , flv1.attribute1                    AS attribute1                      -- �e��敪�R�[�h
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
                       , xt0c.vendor_dummy_flag             AS vendor_dummy_flag               -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
                  FROM xxcmm_system_items_b        xsim  -- Disc�i�ڃA�h�I��
                     , xxcos_sales_exp_lines       xsel  -- �̔����і���
                     , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--                     , xxcok_tmp_014a01c_custdata  xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                     , xxcok_wk_014a01c_custdata  xt0c   -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
                     , fnd_lookup_values           flv1  -- �e��Q
                     , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
                     , hz_cust_accounts            hca
                     , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--                  WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- �Ƒԁi�����ށj�FVD
                  WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
                    AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
                    AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
                    AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND EXISTS ( SELECT 'X'
                                 FROM xxcok_mst_bm_contract xmbc2 -- �̎�����}�X�^
                                 WHERE xmbc2.calc_type         = cv_calc_type_container        -- �v�Z�����F�e��敪�ʏ���
                                   AND xmbc2.cust_code         = xseh.ship_to_customer_code
                                   AND xmbc2.calc_target_flag  = cv_enable
                                   AND xmbc2.selling_price    IS NULL
                                   AND ROWNUM = 1
                        )
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
                    AND xt0c.ship_cust_code         = hca.account_number
                    AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
                    AND EXISTS ( SELECT 'X'
                                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                   AND ROWNUM = 1
                        )
                    AND NOT EXISTS ( SELECT 'X'
                                     FROM fnd_lookup_values flv -- ��݌ɕi��
                                     WHERE flv.lookup_type         = cv_lookup_type_05  -- �Q�ƃ^�C�v�F��݌ɕi��
                                       AND flv.lookup_code         = xsel.item_code
                                       AND flv.language            = cv_lang
                                       AND flv.enabled_flag        = cv_enable
                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                 AND NVL( flv.end_date_active  , gd_process_date )
                                       AND ROWNUM = 1
                        )
                    AND xsim.item_code              = xsel.item_code
                    AND flv1.lookup_type(+)         = cv_lookup_type_04                         -- �Q�ƃ^�C�v�F�e��Q
                    AND flv1.lookup_code(+)         = xsim.vessel_group
                    AND flv1.language(+)            = cv_lang
                    AND flv1.enabled_flag(+)        = cv_enable
                    AND gd_process_date       BETWEEN NVL( flv1.start_date_active, gd_process_date )
                                                  AND NVL( flv1.end_date_active  , gd_process_date )
                )                           xse   -- �̔����я��
              , xxcok_mst_bm_contract       xmbc  -- �̎�����}�X�^
           WHERE xmbc.calc_type(+)           = cv_calc_type_container                    -- �v�Z�����F�e��敪�ʏ���
             AND xmbc.cust_code(+)           = xse.ship_to_customer_code
             AND xmbc.calc_target_flag(+)    = cv_enable
             AND xmbc.container_type_code(+) = NVL( xse.attribute1, cv_container_code_others )
         ) xbc -- �̔����я��E�e��敪�ʏ���
    GROUP BY  xbc.sales_base_code
            , xbc.results_employee_code
            , xbc.ship_to_customer_code
            , xbc.ship_gyotai_sho
            , xbc.ship_gyotai_tyu
            , xbc.bill_cust_code
            , xbc.period_year
            , xbc.ship_delivery_chain_code
            , xbc.delivery_ym
            , xbc.dlv_uom_code
            , xbc.container_code
            , xbc.dlv_unit_price
            , xbc.tax_div
            , xbc.tax_code
            , xbc.tax_rate
            , xbc.tax_rounding_rule
            , xbc.term_name
            , xbc.closing_date
            , xbc.expect_payment_date
            , xbc.calc_target_period_from
            , xbc.calc_target_period_to
            , xbc.calc_type
            , xbc.bm1_vendor_code
            , xbc.bm1_vendor_site_code
            , xbc.bm1_bm_payment_type
            , xbc.bm1_pct
            , xbc.bm1_amt
            , xbc.bm2_vendor_code
            , xbc.bm2_vendor_site_code
            , xbc.bm2_bm_payment_type
            , xbc.bm2_pct
            , xbc.bm2_amt
            , xbc.bm3_vendor_code
            , xbc.bm3_vendor_site_code
            , xbc.bm3_bm_payment_type
            , xbc.bm3_pct
            , xbc.bm3_amt
            , xbc.item_code
            , xbc.amount_fix_date
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
            , xbc.vendor_dummy_flag
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
            , xbc.bm1_tax_kbn
            , xbc.bm2_tax_kbn
            , xbc.bm3_tax_kbn
-- Ver.3.20 N.Abe ADD END
  ;
  -- �̔����я��E�ꗥ����
  CURSOR get_sales_data_cur3 IS
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--    SELECT /*+ LEADING(xt0c xmbc xcbi xseh xsel) */
    SELECT /*+
             LEADING(xt0c xcbi xmbc xseh xsel)
             USE_NL(xt0c xcbi xmbc xseh xsel)
             INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
           */
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--           xseh.sales_base_code                                                    AS base_code                -- ���_�R�[�h
--         , xseh.results_employee_code                                              AS emp_code                 -- �S���҃R�[�h
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                                                     AS base_code                -- ���_�R�[�h
         , xt0c.emp_code                                                           AS emp_code                 -- �S���҃R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
         , xseh.ship_to_customer_code                                              AS ship_cust_code           -- �ڋq�y�[�i��z
         , xt0c.ship_gyotai_sho                                                    AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.ship_gyotai_tyu                                                    AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.bill_cust_code                                                     AS bill_cust_code           -- �ڋq�y������z
         , xt0c.period_year                                                        AS period_year              -- ��v�N�x
         , xt0c.ship_delivery_chain_code                                           AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )                                 AS delivery_ym              -- �[�i���N��
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' )                                  AS delivery_ym              -- �[�i���N��
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
         , SUM( xsel.dlv_qty )                                                     AS dlv_qty                  -- �[�i����
         , xsel.dlv_uom_code                                                       AS dlv_uom_code             -- �[�i�P��
         , SUM( xsel.pure_amount + xsel.tax_amount )                               AS amount_inc_tax           -- ������z�i�ō��j
-- Ver.3.20 N.Abe ADD START
        ,  SUM( xsel.pure_amount )                                                 AS amount_no_tax            -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
         , NULL                                                                    AS container_code           -- �e��敪�R�[�h
         , NULL                                                                    AS dlv_unit_price           -- �������z
         , xt0c.tax_div                                                            AS tax_div                  -- ����ŋ敪
-- Ver.3.19 SCSK K.Nara MOD START
--         , xt0c.tax_code                                                           AS tax_code                 -- �ŋ��R�[�h
--         , xt0c.tax_rate                                                           AS tax_rate                 -- ����ŗ�
         , CASE 
             WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
               xt0c.tax_code
             ELSE 
               NVL(xsel.tax_code, xseh.tax_code)
           END                                                                     AS tax_code                 -- �ŋ��R�[�h
         , CASE 
             WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
               xt0c.tax_rate
             ELSE 
               NVL(xsel.tax_rate, xseh.tax_rate)
           END                                                                     AS tax_rate                 -- ����ŗ�
-- Ver.3.19 SCSK K.Nara MOD END
         , xt0c.tax_rounding_rule                                                  AS tax_rounding_rule        -- �[�������敪
         , xt0c.term_name                                                          AS term_name                -- �x������
         , xt0c.closing_date                                                       AS closing_date             -- ���ߓ�
         , xt0c.expect_payment_date                                                AS expect_payment_date      -- �x���\���
         , xt0c.calc_target_period_from                                            AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
         , xt0c.calc_target_period_to                                              AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
         , xmbc.calc_type                                                          AS calc_type                -- �v�Z����
         , xt0c.bm1_vendor_code                                                    AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
         , xt0c.bm1_vendor_site_code                                               AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xt0c.bm1_bm_payment_type                                                AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
         , xmbc.bm1_pct                                                            AS bm1_pct                  -- �y�a�l�P�zBM��(%)
         , xmbc.bm1_amt                                                            AS bm1_amt                  -- �y�a�l�P�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm1_pct / 100 ) AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
--         , TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm1_amt )                             AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm1_tax_kbn, '1' ) = '1' THEN
               TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm1_pct / 100 )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN NVL( xmbc.bm1_tax_kbn, '1' ) = '2' THEN
               CASE
                 WHEN SUM( xsel.pure_amount ) * xmbc.bm1_pct >= 0 THEN
                   CEIL( SUM( xsel.pure_amount ) * xmbc.bm1_pct / 100 )
                 WHEN SUM( xsel.pure_amount ) * xmbc.bm1_pct < 0 THEN
                   FLOOR( SUM( xsel.pure_amount ) * xmbc.bm1_pct / 100 )
               END
           END                                                                     AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z_��
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm1_tax_kbn, '1' ) = '1' THEN
               TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm1_amt )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN NVL( xmbc.bm1_tax_kbn, '1' ) = '2' THEN
               CASE
                 WHEN SUM( xsel.dlv_qty ) * xmbc.bm1_amt >= 0 THEN
                   CEIL( SUM( xsel.dlv_qty ) * xmbc.bm1_amt )
                 WHEN SUM( xsel.dlv_qty ) * xmbc.bm1_amt < 0 THEN
                   FLOOR( SUM( xsel.dlv_qty ) * xmbc.bm1_amt )
               END
           END                                                                     AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                                    AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
-- Ver.3.20 N.Abe ADD START
         , NULL                                                                    AS bm1_electric_amt_no_tax  -- �y�a�l�P�z�d�C��(�Ŕ�)
-- Ver.3.20 N.Abe ADD END
         , xt0c.bm2_vendor_code                                                    AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
         , xt0c.bm2_vendor_site_code                                               AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xt0c.bm2_bm_payment_type                                                AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
         , xmbc.bm2_pct                                                            AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
         , xmbc.bm2_amt                                                            AS bm2_amt                  -- �y�a�l�Q�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm2_pct / 100 ) AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
--         , TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm2_amt )                             AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm2_tax_kbn, '1' ) = '1' THEN
               TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm2_pct / 100 )
             -- BM2�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN NVL( xmbc.bm2_tax_kbn, '1' ) IN ('2', '3') THEN
               CASE
                 WHEN SUM( xsel.pure_amount ) * xmbc.bm2_pct >= 0 THEN
                   CEIL( SUM( xsel.pure_amount ) * xmbc.bm2_pct / 100 )
                 WHEN SUM( xsel.pure_amount ) * xmbc.bm2_pct < 0 THEN
                   FLOOR( SUM( xsel.pure_amount ) * xmbc.bm2_pct / 100 )
               END
           END                                                                     AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z_��
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm2_tax_kbn, '1' ) = '1' THEN
               TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm2_amt )
             -- BM2�ŋ敪 = '2':�Ŕ��A����'3'(��ې�)
             WHEN NVL( xmbc.bm2_tax_kbn, '1' ) IN ('2', '3') THEN
               CASE
                 WHEN SUM( xsel.dlv_qty ) * xmbc.bm2_amt >= 0 THEN
                   CEIL( SUM( xsel.dlv_qty ) * xmbc.bm2_amt )
                 WHEN SUM( xsel.dlv_qty ) * xmbc.bm2_amt < 0 THEN
                   FLOOR( SUM( xsel.dlv_qty ) * xmbc.bm2_amt )
               END
           END                                                                     AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                                    AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
         , xt0c.bm3_vendor_code                                                    AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
         , xt0c.bm3_vendor_site_code                                               AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xt0c.bm3_bm_payment_type                                                AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
         , xmbc.bm3_pct                                                            AS bm3_pct                  -- �y�a�l�R�zBM��(%)
         , xmbc.bm3_amt                                                            AS bm3_amt                  -- �y�a�l�R�zBM���z
-- Ver.3.20 N.Abe MOD START
--         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm3_pct / 100 ) AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
--         , TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm3_amt )                             AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm3_tax_kbn, '1' ) = '1' THEN
               TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xmbc.bm3_pct / 100 )
             -- BM3�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN NVL( xmbc.bm3_tax_kbn, '1' ) IN ('2', '3') THEN
               CASE
                 WHEN SUM( xsel.pure_amount ) * xmbc.bm3_pct >= 0 THEN
                   CEIL( SUM( xsel.pure_amount ) * xmbc.bm3_pct / 100 )
                 WHEN SUM( xsel.pure_amount ) * xmbc.bm3_pct < 0 THEN
                   FLOOR( SUM( xsel.pure_amount ) * xmbc.bm3_pct / 100 )
               END
           END                                                                     AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z_��
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm3_tax_kbn, '1' ) = '1' THEN
               TRUNC( SUM( xsel.dlv_qty ) * xmbc.bm3_amt )
             -- BM3�ŋ敪 = '2':�Ŕ��A����'3'(��ې�)
             WHEN NVL( xmbc.bm3_tax_kbn, '1' ) IN ('2', '3') THEN
               CASE
                 WHEN SUM( xsel.dlv_qty ) * xmbc.bm3_amt >= 0 THEN
                   CEIL( SUM( xsel.dlv_qty ) * xmbc.bm3_amt )
                 WHEN SUM( xsel.dlv_qty ) * xmbc.bm3_amt < 0 THEN
                   FLOOR( SUM( xsel.dlv_qty ) * xmbc.bm3_amt )
               END
           END                                                                     AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z_�z
-- Ver.3.20 N.Abe MOD END 
         , NULL                                                                    AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
         , NULL                                                                    AS item_code                -- �G���[�i�ڃR�[�h
         , xt0c.amount_fix_date                                                    AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
         , xt0c.vendor_dummy_flag                                                  AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
         , NVL( xmbc.bm1_tax_kbn, '1' )                                            AS bm1_tax_kbn              -- BM1�ŋ敪
         , NVL( xmbc.bm2_tax_kbn, '1' )                                            AS bm2_tax_kbn              -- BM2�ŋ敪
         , NVL( xmbc.bm3_tax_kbn, '1' )                                            AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
    FROM xxcok_mst_bm_contract       xmbc  -- �̎�����}�X�^
       , xxcos_sales_exp_lines       xsel  -- �̔����і���
       , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--       , xxcok_tmp_014a01c_custdata  xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
       , xxcok_wk_014a01c_custdata  xt0c   -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
       , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
       , hz_cust_accounts            hca
       , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--    WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- �Ƒԁi�����ށj�FVD
    WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
      AND EXISTS ( SELECT 'X'
                   FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                   WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                     AND flv.lookup_code         = xsel.sales_class
                     AND flv.language            = cv_lang
                     AND flv.enabled_flag        = cv_enable
                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                               AND NVL( flv.end_date_active  , gd_process_date )
                     AND ROWNUM = 1
          )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- ��݌ɕi��
                       WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = cv_lang
                         AND flv.enabled_flag        = cv_enable
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
                         AND ROWNUM = 1
          )
      AND xmbc.calc_type              = cv_calc_type_uniform_rate                 -- �v�Z�����F�ꗥ����
      AND xmbc.cust_code              = xt0c.ship_cust_code
      AND xmbc.cust_code              = xseh.ship_to_customer_code
      AND xmbc.calc_target_flag       = cv_enable
      AND xmbc.container_type_code    IS NULL
      AND xmbc.selling_price          IS NULL
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--    GROUP BY xseh.sales_base_code
--           , xseh.results_employee_code
    GROUP BY CASE
               WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                 xca.sale_base_code
               ELSE
                 xca.past_sale_base_code
             END
           , xt0c.emp_code
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
           , xseh.ship_to_customer_code
           , xt0c.ship_gyotai_sho
           , xt0c.ship_gyotai_tyu
           , xt0c.bill_cust_code
           , xt0c.period_year
           , xt0c.ship_delivery_chain_code
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--           , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
           , TO_CHAR( xt0c.closing_date, 'RRRRMM' )
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
           , xsel.dlv_uom_code
           , xt0c.tax_div
-- Ver.3.19 SCSK K.Nara MOD START
--           , xt0c.tax_code
--           , xt0c.tax_rate
           , CASE 
               WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
                 xt0c.tax_code
               ELSE 
                 NVL(xsel.tax_code, xseh.tax_code)
             END
           , CASE 
               WHEN ( xt0c.tax_div = cv_tax_div_no_tax OR xt0c.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
                 xt0c.tax_rate
               ELSE 
                 NVL(xsel.tax_rate, xseh.tax_rate)
             END
-- Ver.3.19 SCSK K.Nara MOD END
           , xt0c.tax_rounding_rule
           , xt0c.term_name
           , xt0c.closing_date
           , xt0c.expect_payment_date
           , xt0c.calc_target_period_from
           , xt0c.calc_target_period_to
           , xmbc.calc_type
           , xt0c.bm1_vendor_code
           , xt0c.bm1_vendor_site_code
           , xt0c.bm1_bm_payment_type
           , xmbc.bm1_pct
           , xmbc.bm1_amt
           , xt0c.bm2_vendor_code
           , xt0c.bm2_vendor_site_code
           , xt0c.bm2_bm_payment_type
           , xmbc.bm2_pct
           , xmbc.bm2_amt
           , xt0c.bm3_vendor_code
           , xt0c.bm3_vendor_site_code
           , xt0c.bm3_bm_payment_type
           , xmbc.bm3_pct
           , xmbc.bm3_amt
           , xt0c.amount_fix_date
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
           , xt0c.vendor_dummy_flag
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
           , NVL( xmbc.bm1_tax_kbn, '1' )
           , NVL( xmbc.bm2_tax_kbn, '1' )
           , NVL( xmbc.bm3_tax_kbn, '1' )
-- Ver.3.20 N.Abe ADD END
  ;
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--  -- �̔����я��E��z����
--  CURSOR get_sales_data_cur4 IS
--    SELECT xseh.sales_base_code          AS base_code                -- ���_�R�[�h
--         , xseh.results_employee_code    AS emp_code                 -- �S���҃R�[�h
--         , xbc.ship_to_customer_code     AS ship_cust_code           -- �ڋq�y�[�i��z
--         , xbc.ship_gyotai_sho           AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--         , xbc.ship_gyotai_tyu           AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--         , xbc.bill_cust_code            AS bill_cust_code           -- �ڋq�y������z
--         , xbc.period_year               AS period_year              -- ��v�N�x
--         , xbc.ship_delivery_chain_code  AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
--         , xbc.delivery_ym               AS delivery_ym              -- �[�i���N��
--         , xbc.dlv_qty                   AS dlv_qty                  -- �[�i����
--         , xbc.dlv_uom_code              AS dlv_uom_code             -- �[�i�P��
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR START
----         , xbc.amount_inc_tax            AS amount_inc_tax           -- ������z�i�ō��j
--         , CASE
--             WHEN NOT EXISTS ( SELECT 'X'
--                               FROM xxcok_mst_bm_contract     xmbc
--                               WHERE xmbc.cust_code               = xbc.ship_to_customer_code
--                                 AND xmbc.calc_target_flag        = cv_enable
--                                 AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                    , cv_calc_type_container
--                                                                    , cv_calc_type_uniform_rate
--                                                                    )
--                  )
--             THEN
--               xbc.amount_inc_tax
--             ELSE
--               0
--           END                           AS amount_inc_tax           -- ������z�i�ō��j
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR END
--         , xbc.container_code            AS container_code           -- �e��敪�R�[�h
--         , xbc.dlv_unit_price            AS dlv_unit_price           -- �������z
--         , xbc.tax_div                   AS tax_div                  -- ����ŋ敪
--         , xbc.tax_code                  AS tax_code                 -- �ŋ��R�[�h
--         , xbc.tax_rate                  AS tax_rate                 -- ����ŗ�
--         , xbc.tax_rounding_rule         AS tax_rounding_rule        -- �[�������敪
--         , xbc.term_name                 AS term_name                -- �x������
--         , xbc.closing_date              AS closing_date             -- ���ߓ�
--         , xbc.expect_payment_date       AS expect_payment_date      -- �x���\���
--         , xbc.calc_target_period_from   AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
--         , xbc.calc_target_period_to     AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
--         , xbc.calc_type                 AS calc_type                -- �v�Z����
--         , xbc.bm1_vendor_code           AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
--         , xbc.bm1_vendor_site_code      AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
--         , xbc.bm1_bm_payment_type       AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
--         , xbc.bm1_pct                   AS bm1_pct                  -- �y�a�l�P�zBM��(%)
--         , xbc.bm1_amt                   AS bm1_amt                  -- �y�a�l�P�zBM���z
--         , NULL                          AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
--         , TRUNC( xbc.bm1_amt )          AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
--         , NULL                          AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
--         , xbc.bm2_vendor_code           AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
--         , xbc.bm2_vendor_site_code      AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
--         , xbc.bm2_bm_payment_type       AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
--         , xbc.bm2_pct                   AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
--         , xbc.bm2_amt                   AS bm2_amt                  -- �y�a�l�Q�zBM���z
--         , NULL                          AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
--         , TRUNC( xbc.bm2_amt )          AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
--         , NULL                          AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
--         , xbc.bm3_vendor_code           AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
--         , xbc.bm3_vendor_site_code      AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
--         , xbc.bm3_bm_payment_type       AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
--         , xbc.bm3_pct                   AS bm3_pct                  -- �y�a�l�R�zBM��(%)
--         , xbc.bm3_amt                   AS bm3_amt                  -- �y�a�l�R�zBM���z
--         , NULL                          AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
--         , TRUNC( xbc.bm3_amt )          AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
--         , NULL                          AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
--         , xbc.item_code                 AS item_code                -- �G���[�i�ڃR�[�h
--         , xbc.amount_fix_date           AS amount_fix_date          -- ���z�m���
--    FROM ( SELECT /*+ LEADING(xt0c xmbc xcbi xseh xsel) */
--                  MAX( xseh.sales_exp_header_id )           AS sales_exp_header_id      -- �̔����уw�b�_ID
--                , NULL                                      AS sales_base_code          -- ���㋒�_�R�[�h
--                , NULL                                      AS results_employee_code    -- ���ьv��҃R�[�h
--                , xseh.ship_to_customer_code                AS ship_to_customer_code    -- �y�o�א�z�ڋq�R�[�h
--                , xt0c.ship_gyotai_sho                      AS ship_gyotai_sho          -- �y�o�א�z�Ƒԁi�����ށj
--                , xt0c.ship_gyotai_tyu                      AS ship_gyotai_tyu          -- �y�o�א�z�Ƒԁi�����ށj
--                , xt0c.bill_cust_code                       AS bill_cust_code           -- �y������z�ڋq�R�[�h
--                , xt0c.period_year                          AS period_year              -- ��v�N�x
--                , xt0c.ship_delivery_chain_code             AS ship_delivery_chain_code -- �y�o�א�z�[�i��`�F�[���R�[�h
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR START
----                , TO_CHAR( xseh.delivery_date, 'RRRRMM' )   AS delivery_ym              -- �[�i�N��
--                , TO_CHAR( xt0c.closing_date, 'RRRRMM' )    AS delivery_ym              -- �[�i�N��
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR END
--                , NULL                                      AS dlv_qty                  -- �[�i����
--                , NULL                                      AS dlv_uom_code             -- �[�i�P��
--                , SUM( xsel.pure_amount + xsel.tax_amount ) AS amount_inc_tax           -- ������z�i�ō��j
--                , NULL                                      AS container_code           -- �e��敪�R�[�h
--                , NULL                                      AS dlv_unit_price           -- �������z
--                , xt0c.tax_div                              AS tax_div                  -- ����ŋ敪
--                , xt0c.tax_code                             AS tax_code                 -- �ŋ��R�[�h
--                , xt0c.tax_rate                             AS tax_rate                 -- ����ŗ�
--                , xt0c.tax_rounding_rule                    AS tax_rounding_rule        -- �[�������敪
--                , xt0c.term_name                            AS term_name                -- �x������
--                , xt0c.closing_date                         AS closing_date             -- ���ߓ�
--                , xt0c.expect_payment_date                  AS expect_payment_date      -- �x���\���
--                , xt0c.calc_target_period_from              AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
--                , xt0c.calc_target_period_to                AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
--                , xmbc.calc_type                            AS calc_type                -- �v�Z����
--                , xt0c.bm1_vendor_code                      AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
--                , xt0c.bm1_vendor_site_code                 AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
--                , xt0c.bm1_bm_payment_type                  AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
--                , NULL                                      AS bm1_pct                  -- �y�a�l�P�zBM��(%)
--                , xmbc.bm1_amt                              AS bm1_amt                  -- �y�a�l�P�zBM���z
--                , xt0c.bm2_vendor_code                      AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
--                , xt0c.bm2_vendor_site_code                 AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
--                , xt0c.bm2_bm_payment_type                  AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
--                , NULL                                      AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
--                , xmbc.bm2_amt                              AS bm2_amt                  -- �y�a�l�Q�zBM���z
--                , xt0c.bm3_vendor_code                      AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
--                , xt0c.bm3_vendor_site_code                 AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
--                , xt0c.bm3_bm_payment_type                  AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
--                , NULL                                      AS bm3_pct                  -- �y�a�l�R�zBM��(%)
--                , xmbc.bm3_amt                              AS bm3_amt                  -- �y�a�l�R�zBM���z
--                , NULL                                      AS item_code                -- �G���[�i�ڃR�[�h
--                , xt0c.amount_fix_date                      AS amount_fix_date          -- ���z�m���
--           FROM xxcok_mst_bm_contract       xmbc  -- �̎�����}�X�^
--              , xxcos_sales_exp_lines       xsel  -- �̔����і���
--              , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
--              , xxcok_tmp_014a01c_custdata  xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
--              , xxcok_cust_bm_info          xcbi
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
----           WHERE xt0c.ship_gyotai_tyu        = cv_gyotai_tyu_vd                          -- �Ƒԁi�����ށj�FVD
--           WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
--             AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
--             AND xseh.delivery_date         <= xt0c.closing_date
--             AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--             AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--             AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--             AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--             AND EXISTS ( SELECT  'X'
--                          FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
--                          WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
--                            AND flv.lookup_code         = xsel.sales_class
--                            AND flv.language            = cv_lang
--                            AND flv.enabled_flag        = cv_enable
--                            AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                      AND NVL( flv.end_date_active  , gd_process_date )
--                            AND ROWNUM = 1
--                 )
--             AND NOT EXISTS ( SELECT 'X'
--                              FROM fnd_lookup_values flv -- ��݌ɕi��
--                              WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
--                                AND flv.lookup_code         = xsel.item_code
--                                AND flv.language            = cv_lang
--                                AND flv.enabled_flag        = cv_enable
--                                AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                          AND NVL( flv.end_date_active  , gd_process_date )
--                                AND ROWNUM = 1
--                 )
--             AND xmbc.calc_type              = cv_calc_type_flat_rate                    -- �v�Z�����F��z����
--             AND xmbc.cust_code              = xt0c.ship_cust_code
--             AND xmbc.cust_code              = xseh.ship_to_customer_code
--             AND xmbc.calc_target_flag       = cv_enable
--             AND xmbc.container_type_code   IS NULL
--             AND xmbc.selling_price         IS NULL
--           GROUP BY xseh.ship_to_customer_code
--                  , xt0c.ship_gyotai_sho
--                  , xt0c.ship_gyotai_tyu
--                  , xt0c.bill_cust_code
--                  , xt0c.period_year
--                  , xt0c.ship_delivery_chain_code
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi DELETE START
----                  , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi DELETE END
--                  , xt0c.tax_div
--                  , xt0c.tax_code
--                  , xt0c.tax_rate
--                  , xt0c.tax_rounding_rule
--                  , xt0c.term_name
--                  , xt0c.closing_date
--                  , xt0c.expect_payment_date
--                  , xt0c.calc_target_period_from
--                  , xt0c.calc_target_period_to
--                  , xmbc.calc_type
--                  , xt0c.bm1_vendor_code
--                  , xt0c.bm1_vendor_site_code
--                  , xt0c.bm1_bm_payment_type
--                  , xmbc.bm1_amt
--                  , xt0c.bm2_vendor_code
--                  , xt0c.bm2_vendor_site_code
--                  , xt0c.bm2_bm_payment_type
--                  , xmbc.bm2_amt
--                  , xt0c.bm3_vendor_code
--                  , xt0c.bm3_vendor_site_code
--                  , xt0c.bm3_bm_payment_type
--                  , xmbc.bm3_amt
--                  , xt0c.amount_fix_date
--         )                           xbc   -- �̔����я��E��z����
--       , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
--    WHERE xseh.sales_exp_header_id = xbc.sales_exp_header_id
--  ;
  -- �̔����я��E��z����
  CURSOR get_sales_data_cur4 IS
    SELECT /*+
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--             LEADING( xt0c hca xca xcbi xmbc )
             LEADING(xt0c hca xca xcbi xmbc)
             USE_NL(xt0c xcbi xmbc xseh xsel )
             INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
           */
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                    AS base_code                -- ���_�R�[�h
         , xt0c.emp_code                          AS emp_code                 -- �S���҃R�[�h
         , xt0c.ship_cust_code                    AS ship_cust_code           -- �ڋq�y�[�i��z
         , xt0c.ship_gyotai_sho                   AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.ship_gyotai_tyu                   AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.bill_cust_code                    AS bill_cust_code           -- �ڋq�y������z
         , xt0c.period_year                       AS period_year              -- ��v�N�x
         , xt0c.ship_delivery_chain_code          AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) AS delivery_ym              -- �[�i���N��
         , NULL                                   AS dlv_qty                  -- �[�i����
         , NULL                                   AS dlv_uom_code             -- �[�i�P��
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
--         , CASE
--             WHEN EXISTS ( SELECT 'X'
--                           FROM xxcok_mst_bm_contract     xmbc
--                           WHERE xmbc.cust_code               = xt0c.ship_cust_code
--                             AND xmbc.calc_target_flag        = cv_enable
--                             AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                , cv_calc_type_container
--                                                                , cv_calc_type_uniform_rate
--                                                                )
--                             AND ROWNUM = 1
--                  )
--             THEN
--               0
--             ELSE
--               NVL( ( SELECT SUM( xsel.pure_amount + xsel.tax_amount )
--                      FROM xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
--                         , xxcos_sales_exp_lines       xsel  -- �̔����і���
--                      WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--                        AND xseh.delivery_date         <= xt0c.closing_date
--                        AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--                        AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--                        AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--                        AND EXISTS ( SELECT  'X'
--                                     FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
--                                     WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
--                                       AND flv.lookup_code         = xsel.sales_class
--                                       AND flv.language            = cv_lang
--                                       AND flv.enabled_flag        = cv_enable
--                                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active  , gd_process_date )
--                                       AND ROWNUM = 1
--                            )
--                        AND NOT EXISTS ( SELECT 'X'
--                                         FROM fnd_lookup_values flv -- ��݌ɕi��
--                                         WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
--                                           AND flv.lookup_code         = xsel.item_code
--                                           AND flv.language            = cv_lang
--                                           AND flv.enabled_flag        = cv_enable
--                                           AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                     AND NVL( flv.end_date_active  , gd_process_date )
--                                           AND ROWNUM = 1
--                            )
--               ), 0 )
--           END                           AS amount_inc_tax           -- ������z�i�ō��j
         , SUM(
             CASE
               WHEN EXISTS ( SELECT 'X'
                             FROM xxcok_mst_bm_contract     xmbc
                             WHERE xmbc.cust_code               = xt0c.ship_cust_code
                               AND xmbc.calc_target_flag        = cv_enable
                               AND xmbc.calc_type              IN ( cv_calc_type_sales_price
                                                                  , cv_calc_type_container
                                                                  , cv_calc_type_uniform_rate
                                                                  )
                               AND ROWNUM = 1
                    )
               THEN
                 0
               ELSE
                 NVL( xsel.pure_amount + xsel.tax_amount, 0 )
             END
           )                             AS amount_inc_tax           -- ������z�i�ō��j
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
-- Ver.3.20 N.Abe ADD START
         , SUM(
             CASE
               WHEN EXISTS ( SELECT 'X'
                             FROM xxcok_mst_bm_contract     xmbc
                             WHERE xmbc.cust_code               = xt0c.ship_cust_code
                               AND xmbc.calc_target_flag        = cv_enable
                               AND xmbc.calc_type              IN ( cv_calc_type_sales_price
                                                                  , cv_calc_type_container
                                                                  , cv_calc_type_uniform_rate
                                                                  )
                               AND ROWNUM = 1
                    )
               THEN
                 0
               ELSE
                 NVL( xsel.pure_amount, 0 )
             END
           )                             AS amount_no_tax            -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
         , NULL                          AS container_code           -- �e��敪�R�[�h
         , NULL                          AS dlv_unit_price           -- �������z
         , xt0c.tax_div                  AS tax_div                  -- ����ŋ敪
         , xt0c.tax_code                 AS tax_code                 -- �ŋ��R�[�h
         , xt0c.tax_rate                 AS tax_rate                 -- ����ŗ�
         , xt0c.tax_rounding_rule        AS tax_rounding_rule        -- �[�������敪
         , xt0c.term_name                AS term_name                -- �x������
         , xt0c.closing_date             AS closing_date             -- ���ߓ�
         , xt0c.expect_payment_date      AS expect_payment_date      -- �x���\���
         , xt0c.calc_target_period_from  AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
         , xt0c.calc_target_period_to    AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
         , xmbc.calc_type                AS calc_type                -- �v�Z����
         , xt0c.bm1_vendor_code          AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
         , xt0c.bm1_vendor_site_code     AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xt0c.bm1_bm_payment_type      AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
         , NULL                          AS bm1_pct                  -- �y�a�l�P�zBM��(%)
         , xmbc.bm1_amt                  AS bm1_amt                  -- �y�a�l�P�zBM���z
         , NULL                          AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
-- Ver.3.20 N.Abe MOD START
--         , TRUNC( xmbc.bm1_amt )         AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM1�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm1_tax_kbn, '1' ) = '1' THEN
               TRUNC( xmbc.bm1_amt )
             -- BM1�ŋ敪 = '2'(�Ŕ�)
             WHEN NVL( xmbc.bm1_tax_kbn, '1' ) = '2' THEN
               CASE
                 WHEN xmbc.bm1_amt >= 0 THEN
                   CEIL( xmbc.bm1_amt )
                 WHEN xmbc.bm1_amt < 0 THEN
                   FLOOR( xmbc.bm1_amt )
               END
           END                           AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
-- Ver.3.20 N.Abe MOD END
         , NULL                          AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
-- Ver.3.20 N.Abe ADD START
         , NULL                          AS bm1_electric_amt_no_tax  -- �y�a�l�P�z�d�C��(�Ŕ�)
-- Ver.3.20 N.Abe ADD END
         , xt0c.bm2_vendor_code          AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
         , xt0c.bm2_vendor_site_code     AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , xt0c.bm2_bm_payment_type      AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
         , NULL                          AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
         , xmbc.bm2_amt                  AS bm2_amt                  -- �y�a�l�Q�zBM���z
         , NULL                          AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
-- Ver.3.20 N.Abe MOD START
--         , TRUNC( xmbc.bm2_amt )         AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM2�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm2_tax_kbn, '1' ) = '1' THEN
               TRUNC( xmbc.bm2_amt )
             -- BM2�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN NVL( xmbc.bm2_tax_kbn, '1' ) IN ('2', '3') THEN
               CASE
                 WHEN xmbc.bm2_amt >= 0 THEN
                   CEIL( xmbc.bm2_amt )
                 WHEN xmbc.bm2_amt < 0 THEN
                   FLOOR( xmbc.bm2_amt )
               END
           END                           AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
-- Ver.3.20 N.Abe MOD END
         , NULL                          AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
         , xt0c.bm3_vendor_code          AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
         , xt0c.bm3_vendor_site_code     AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
         , xt0c.bm3_bm_payment_type      AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
         , NULL                          AS bm3_pct                  -- �y�a�l�R�zBM��(%)
         , xmbc.bm3_amt                  AS bm3_amt                  -- �y�a�l�R�zBM���z
         , NULL                          AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
-- Ver.3.20 N.Abe MOD START
--         , TRUNC( xmbc.bm3_amt )         AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , CASE
             -- BM3�ŋ敪 = '1'(�ō�)
             WHEN NVL( xmbc.bm3_tax_kbn, '1' ) = '1' THEN
               TRUNC( xmbc.bm3_amt )
             -- BM3�ŋ敪 = '2'(�Ŕ�)�A����'3'(��ې�)
             WHEN NVL( xmbc.bm3_tax_kbn, '1' ) IN ('2', '3') THEN
               CASE
                 WHEN xmbc.bm3_amt >= 0 THEN
                   CEIL( xmbc.bm3_amt )
                 WHEN xmbc.bm3_amt < 0 THEN
                   FLOOR( xmbc.bm3_amt )
               END
           END                           AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
-- Ver.3.20 N.Abe MOD END
         , NULL                          AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
         , NULL                          AS item_code                -- �G���[�i�ڃR�[�h
         , xt0c.amount_fix_date          AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
         , xt0c.vendor_dummy_flag        AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
         , NVL( xmbc.bm1_tax_kbn, '1' )  AS bm1_tax_kbn              -- BM1�ŋ敪
         , NVL( xmbc.bm2_tax_kbn, '1' )  AS bm2_tax_kbn              -- BM2�ŋ敪
         , NVL( xmbc.bm3_tax_kbn, '1' )  AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--    FROM xxcok_tmp_014a01c_custdata      xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
    FROM xxcok_wk_014a01c_custdata       xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
       , xxcok_mst_bm_contract           xmbc  -- �̎�����}�X�^
       , xxcok_cust_bm_info              xcbi
       , hz_cust_accounts                hca
       , xxcmm_cust_accounts             xca
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
       , xxcos_sales_exp_headers         xseh  -- �̔����уw�b�_
       , xxcos_sales_exp_lines           xsel  -- �̔����і���
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
    WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      AND xt0c.ship_cust_code         = xmbc.cust_code
      AND xmbc.calc_type              = cv_calc_type_flat_rate                    -- �v�Z�����F��z����
      AND xmbc.calc_target_flag       = cv_enable
      AND xmbc.container_type_code   IS NULL
      AND xmbc.selling_price         IS NULL
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      AND EXISTS ( SELECT  'X'
                   FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                   WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                     AND flv.lookup_code         = xsel.sales_class
                     AND flv.language            = cv_lang
                     AND flv.enabled_flag        = cv_enable
                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                               AND NVL( flv.end_date_active  , gd_process_date )
                     AND ROWNUM = 1
         )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- ��݌ɕi��
                       WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = cv_lang
                         AND flv.enabled_flag        = cv_enable
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
                         AND ROWNUM = 1
          )
GROUP BY CASE
           WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
             xca.sale_base_code
           ELSE
             xca.past_sale_base_code
         END                                    -- ���_�R�[�h
       , xt0c.emp_code                          -- �S���҃R�[�h
       , xt0c.ship_cust_code                    -- �ڋq�y�[�i��z
       , xt0c.ship_gyotai_sho                   -- �ڋq�y�[�i��z�Ƒԁi�����ށj
       , xt0c.ship_gyotai_tyu                   -- �ڋq�y�[�i��z�Ƒԁi�����ށj
       , xt0c.bill_cust_code                    -- �ڋq�y������z
       , xt0c.period_year                       -- ��v�N�x
       , xt0c.ship_delivery_chain_code          -- �`�F�[���X�R�[�h
       , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) -- �[�i���N��
       , xt0c.tax_div                           -- ����ŋ敪
       , xt0c.tax_code                          -- �ŋ��R�[�h
       , xt0c.tax_rate                          -- ����ŗ�
       , xt0c.tax_rounding_rule                 -- �[�������敪
       , xt0c.term_name                         -- �x������
       , xt0c.closing_date                      -- ���ߓ�
       , xt0c.expect_payment_date               -- �x���\���
       , xt0c.calc_target_period_from           -- �v�Z�Ώۊ���(FROM)
       , xt0c.calc_target_period_to             -- �v�Z�Ώۊ���(TO)
       , xmbc.calc_type                         -- �v�Z����
       , xt0c.bm1_vendor_code                   -- �y�a�l�P�z�d����R�[�h
       , xt0c.bm1_vendor_site_code              -- �y�a�l�P�z�d����T�C�g�R�[�h
       , xt0c.bm1_bm_payment_type               -- �y�a�l�P�zBM�x���敪
       , xmbc.bm1_amt                           -- �y�a�l�P�zBM���z
       , TRUNC( xmbc.bm1_amt )                  -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
       , xt0c.bm2_vendor_code                   -- �y�a�l�Q�z�d����R�[�h
       , xt0c.bm2_vendor_site_code              -- �y�a�l�Q�z�d����T�C�g�R�[�h
       , xt0c.bm2_bm_payment_type               -- �y�a�l�Q�zBM�x���敪
       , xmbc.bm2_amt                           -- �y�a�l�Q�zBM���z
       , TRUNC( xmbc.bm2_amt )                  -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
       , xt0c.bm3_vendor_code                   -- �y�a�l�R�z�d����R�[�h
       , xt0c.bm3_vendor_site_code              -- �y�a�l�R�z�d����T�C�g�R�[�h
       , xt0c.bm3_bm_payment_type               -- �y�a�l�R�zBM�x���敪
       , xmbc.bm3_amt                           -- �y�a�l�R�zBM���z
       , TRUNC( xmbc.bm3_amt )                  -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
       , xt0c.amount_fix_date                   -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
       , xt0c.vendor_dummy_flag                 -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
       , NVL( xmbc.bm1_tax_kbn, '1' )           -- BM1�ŋ敪
       , NVL( xmbc.bm2_tax_kbn, '1' )           -- BM2�ŋ敪
       , NVL( xmbc.bm3_tax_kbn, '1' )           -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
  ;
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
-- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR START
--  -- �̔����я��E�d�C���i�Œ�^�ϓ��j
--  CURSOR get_sales_data_cur5 IS
--    SELECT xbc.base_code                                                  AS base_code                  -- ���_�R�[�h
--         , xbc.emp_code                                                   AS emp_code                   -- �S���҃R�[�h
--         , xbc.ship_cust_code                                             AS ship_cust_code             -- �ڋq�y�[�i��z
--         , xbc.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--         , xbc.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--         , xbc.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
--         , xbc.period_year                                                AS period_year                -- ��v�N�x
--         , xbc.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
--         , xbc.delivery_ym                                                AS delivery_ym                -- �[�i���N��
--         , xbc.dlv_qty                                                    AS dlv_qty                    -- �[�i����
--         , xbc.dlv_uom_code                                               AS dlv_uom_code               -- �[�i�P��
--         , xbc.amount_inc_tax                                             AS amount_inc_tax             -- ������z�i�ō��j
--         , xbc.container_code                                             AS container_code             -- �e��敪�R�[�h
--         , xbc.dlv_unit_price                                             AS dlv_unit_price             -- �������z
--         , xbc.tax_div                                                    AS tax_div                    -- ����ŋ敪
--         , xbc.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
--         , xbc.tax_rate                                                   AS tax_rate                   -- ����ŗ�
--         , xbc.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
--         , xbc.term_name                                                  AS term_name                  -- �x������
--         , xbc.closing_date                                               AS closing_date               -- ���ߓ�
--         , xbc.expect_payment_date                                        AS expect_payment_date        -- �x���\���
--         , xbc.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
--         , xbc.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
--         , xbc.calc_type                                                  AS calc_type                  -- �v�Z����
--         , xbc.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
--         , xbc.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
--         , xbc.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
--         , NULL                                                           AS bm1_pct                    -- �y�a�l�P�zBM��(%)
--         , NULL                                                           AS bm1_amt                    -- �y�a�l�P�zBM���z
--         , NULL                                                           AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
--         , NULL                                                           AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
--         , TRUNC( SUM( xbc.bm1_amt ) )                                    AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
--         , xbc.bm2_vendor_code                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
--         , xbc.bm2_vendor_site_code                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
--         , xbc.bm2_bm_payment_type                                        AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
--         , NULL                                                           AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
--         , NULL                                                           AS bm2_amt                    -- �y�a�l�Q�zBM���z
--         , NULL                                                           AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
--         , NULL                                                           AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
--         , NULL                                                           AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
--         , xbc.bm3_vendor_code                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
--         , xbc.bm3_vendor_site_code                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
--         , xbc.bm3_bm_payment_type                                        AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
--         , NULL                                                           AS bm3_pct                    -- �y�a�l�R�zBM��(%)
--         , NULL                                                           AS bm3_amt                    -- �y�a�l�R�zBM���z
--         , NULL                                                           AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
--         , NULL                                                           AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
--         , NULL                                                           AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
--         , xbc.item_code                                                  AS item_code                  -- �G���[�i�ڃR�[�h
--         , xbc.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
--    FROM ( -- �d�C���i�Œ�j
--           SELECT /*+ LEADING(xses xseh) */
--                  xseh.sales_base_code                                            AS base_code                  -- ���_�R�[�h
--                , xseh.results_employee_code                                      AS emp_code                   -- �S���҃R�[�h
--                , xses.ship_to_customer_code                                      AS ship_cust_code             -- �ڋq�y�[�i��z
--                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--                , xses.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
--                , xses.period_year                                                AS period_year                -- ��v�N�x
--                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
--                , xses.delivery_ym                                                AS delivery_ym                -- �[�i���N��
--                , NULL                                                            AS dlv_qty                    -- �[�i����
--                , NULL                                                            AS dlv_uom_code               -- �[�i�P��
--                , 0                                                               AS amount_inc_tax             -- ������z(�ō�)
--                , NULL                                                            AS container_code             -- �e��敪�R�[�h
--                , NULL                                                            AS dlv_unit_price             -- �������z
--                , xses.tax_div                                                    AS tax_div                    -- ����ŋ敪
--                , xses.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
--                , xses.tax_rate                                                   AS tax_rate                   -- ����ŗ�
--                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
--                , xses.term_name                                                  AS term_name                  -- �x������
--                , xses.closing_date                                               AS closing_date               -- ���ߓ�
--                , xses.expect_payment_date                                        AS expect_payment_date        -- �x���\���
--                , xses.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
--                , xses.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
--                , xses.calc_type                                                  AS calc_type                  -- �v�Z����
--                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
--                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
--                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
--                , NULL                                                            AS bm1_pct                    -- �y�a�l�P�zBM��(%)
--                , xses.bm1_amt                                                    AS bm1_amt                    -- �y�a�l�P�zBM���z
--                , NULL                                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
--                , NULL                                                            AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
--                , NULL                                                            AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
--                , NULL                                                            AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
--                , NULL                                                            AS bm2_amt                    -- �y�a�l�Q�zBM���z
--                , NULL                                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
--                , NULL                                                            AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
--                , NULL                                                            AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
--                , NULL                                                            AS bm3_pct                    -- �y�a�l�R�zBM��(%)
--                , NULL                                                            AS bm3_amt                    -- �y�a�l�R�zBM���z
--                , NULL                                                            AS item_code                  -- �G���[�i�ڃR�[�h
--                , xses.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
--           FROM ( SELECT /*+ LEADING(xt0c xmbc xcbi xseh xsel ) */
--                         MAX( xseh.sales_exp_header_id )            AS sales_exp_header_id           -- �̔����уw�b�_ID
--                       , xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
--                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
--                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
--                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
--                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
--                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
--                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
--                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
--                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
--                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
--                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
--                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
--                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
--                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
--                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
--                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
--                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
--                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
--                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
--                       , xt0c.term_name                             AS term_name                     -- �x������
--                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
--                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
--                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
--                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
--                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
--                       , NULL                                       AS sales_base_code               -- ���㋒�_�R�[�h
--                       , NULL                                       AS results_employee_code         -- ���ьv��҃R�[�h
--                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
--                       , NULL                                       AS dlv_qty                       -- �[�i����
--                       , NULL                                       AS dlv_uom_code                  -- �[�i�P��
--                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- ������z�i�ō��j
--                       , NULL                                       AS container_code                -- �e��敪�R�[�h
--                       , NULL                                       AS dlv_unit_price                -- �������z
--                       , NULL                                       AS item_code                     -- �݌ɕi�ڃR�[�h
--                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
--                       , xmbc.calc_type                             AS calc_type                     -- �v�Z����
--                       , xmbc.bm1_amt                               AS bm1_amt                       -- �y�a�l�P�zBM���z
--                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
--                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
--                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
--                     , xxcok_mst_bm_contract         xmbc       -- �̎�����}�X�^
--                     , xxcok_cust_bm_info            xcbi
--                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--                    AND xseh.delivery_date         <= xt0c.closing_date
--                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--                    AND EXISTS ( SELECT 'X'
--                                 FROM fnd_lookup_values    flv
--                                 WHERE flv.lookup_type             = cv_lookup_type_07  -- �̎�v�Z�Ώ۔���敪
--                                   AND flv.lookup_code             = xsel.sales_class
--                                   AND flv.language                = USERENV( 'LANG' )
--                                   AND flv.enabled_flag            = cv_enable
--                                   AND gd_process_date       BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active,   gd_process_date )
--                                   AND ROWNUM = 1
--                        )
--                    AND NOT EXISTS ( SELECT 'X'
--                                     FROM fnd_lookup_values             flv2       -- ��݌ɕi��
--                                     WHERE flv2.lookup_code         = xsel.item_code
--                                       AND flv2.lookup_type         = cv_lookup_type_05
--                                       AND flv2.language            = USERENV( 'LANG' )
--                                       AND flv2.enabled_flag        = cv_enable
--                                       AND gd_process_date       BETWEEN NVL( flv2.start_date_active, gd_process_date )
--                                                                     AND NVL( flv2.end_date_active,   gd_process_date )
--                                       AND ROWNUM = 1
--                        )
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
----                    AND xt0c.ship_gyotai_tyu              = cv_gyotai_tyu_vd
--                    AND xt0c.ship_gyotai_sho             IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
--                    AND xmbc.calc_type                    = cv_calc_type_electricity_cost
--                    AND xmbc.cust_code                    = xseh.ship_to_customer_code
--                    AND xmbc.cust_code                    = xt0c.ship_cust_code
--                    AND xmbc.calc_target_flag             = cv_enable
--                    AND xmbc.container_type_code         IS NULL
--                    AND xmbc.selling_price               IS NULL
--                  GROUP BY xseh.ship_to_customer_code
--                         , xt0c.ship_gyotai_tyu
--                         , xt0c.ship_gyotai_sho
--                         , xt0c.ship_delivery_chain_code
--                         , xt0c.bill_cust_code
--                         , xt0c.bm1_vendor_code
--                         , xt0c.bm1_vendor_site_code
--                         , xt0c.bm1_bm_payment_type
--                         , xt0c.bm2_vendor_code
--                         , xt0c.bm2_vendor_site_code
--                         , xt0c.bm2_bm_payment_type
--                         , xt0c.bm3_vendor_code
--                         , xt0c.bm3_vendor_site_code
--                         , xt0c.bm3_bm_payment_type
--                         , xt0c.tax_div
--                         , xt0c.tax_code
--                         , xt0c.tax_rate
--                         , xt0c.tax_rounding_rule
--                         , xt0c.receiv_discount_rate
--                         , xt0c.term_name
--                         , xt0c.closing_date
--                         , xt0c.expect_payment_date
--                         , xt0c.period_year
--                         , xt0c.calc_target_period_from
--                         , xt0c.calc_target_period_to
--                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
--                         , xt0c.amount_fix_date
--                         , xmbc.calc_type
--                         , xmbc.bm1_amt
--                )                           xses      -- �C�����C���r���[�E�̔����я��i�ڋq�T�}���j
--              , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
--           WHERE xseh.sales_exp_header_id = xses.sales_exp_header_id
--           UNION ALL
--           -- �d�C���i�ϓ��j
--           SELECT xses.sales_base_code                                            AS base_code                  -- ���_�R�[�h
--                , xses.results_employee_code                                      AS emp_code                   -- �S���҃R�[�h
--                , xses.ship_to_customer_code                                      AS ship_cust_code             -- �ڋq�y�[�i��z
--                , xses.ship_gyotai_sho                                            AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--                , xses.ship_gyotai_tyu                                            AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--                , xses.bill_cust_code                                             AS bill_cust_code             -- �ڋq�y������z
--                , xses.period_year                                                AS period_year                -- ��v�N�x
--                , xses.ship_delivery_chain_code                                   AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
--                , xses.delivery_ym                                                AS delivery_ym                -- �[�i���N��
--                , NULL                                                            AS dlv_qty                    -- �[�i����
--                , NULL                                                            AS dlv_uom_code               -- �[�i�P��
--                , 0                                                               AS amount_inc_tax             -- ������z(�ō�)
--                , NULL                                                            AS container_code             -- �e��敪�R�[�h
--                , NULL                                                            AS dlv_unit_price             -- �������z
--                , xses.tax_div                                                    AS tax_div                    -- ����ŋ敪
--                , xses.tax_code                                                   AS tax_code                   -- �ŋ��R�[�h
--                , xses.tax_rate                                                   AS tax_rate                   -- ����ŗ�
--                , xses.tax_rounding_rule                                          AS tax_rounding_rule          -- �[�������敪
--                , xses.term_name                                                  AS term_name                  -- �x������
--                , xses.closing_date                                               AS closing_date               -- ���ߓ�
--                , xses.expect_payment_date                                        AS expect_payment_date        -- �x���\���
--                , xses.calc_target_period_from                                    AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
--                , xses.calc_target_period_to                                      AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
--                , cv_calc_type_electricity_cost                                   AS calc_type                  -- �v�Z����
--                , xses.bm1_vendor_code                                            AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
--                , xses.bm1_vendor_site_code                                       AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
--                , xses.bm1_bm_payment_type                                        AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
--                , NULL                                                            AS bm1_pct                    -- �y�a�l�P�zBM��(%)
--                , xses.amount_inc_tax                                             AS bm1_amt                    -- �y�a�l�P�zBM���z
--                , NULL                                                            AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
--                , NULL                                                            AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
--                , NULL                                                            AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
--                , NULL                                                            AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
--                , NULL                                                            AS bm2_amt                    -- �y�a�l�Q�zBM���z
--                , NULL                                                            AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
--                , NULL                                                            AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
--                , NULL                                                            AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
--                , NULL                                                            AS bm3_pct                    -- �y�a�l�R�zBM��(%)
--                , NULL                                                            AS bm3_amt                    -- �y�a�l�R�zBM���z
--                , NULL                                                            AS item_code                  -- �G���[�i�ڃR�[�h
--                , xses.amount_fix_date                                            AS amount_fix_date            -- ���z�m���
--           FROM ( SELECT xseh.ship_to_customer_code                 AS ship_to_customer_code         -- �y�o�א�z�ڋq�R�[�h
--                       , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu               -- �y�o�א�z�Ƒԁi�����ށj
--                       , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho               -- �y�o�א�z�Ƒԁi�����ށj
--                       , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code      -- �y�o�א�z�[�i��`�F�[���R�[�h
--                       , xt0c.bill_cust_code                        AS bill_cust_code                -- �y������z�ڋq�R�[�h
--                       , xt0c.bm1_vendor_code                       AS bm1_vendor_code               -- �y�a�l�P�z�d����R�[�h
--                       , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code          -- �y�a�l�P�z�d����T�C�g�R�[�h
--                       , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type           -- �y�a�l�P�zBM�x���敪
--                       , xt0c.bm2_vendor_code                       AS bm2_vendor_code               -- �y�a�l�Q�z�d����R�[�h
--                       , xt0c.bm2_vendor_site_code                  AS bm2_vendor_site_code          -- �y�a�l�Q�z�d����T�C�g�R�[�h
--                       , xt0c.bm2_bm_payment_type                   AS bm2_bm_payment_type           -- �y�a�l�Q�zBM�x���敪
--                       , xt0c.bm3_vendor_code                       AS bm3_vendor_code               -- �y�a�l�R�z�d����R�[�h
--                       , xt0c.bm3_vendor_site_code                  AS bm3_vendor_site_code          -- �y�a�l�R�z�d����T�C�g�R�[�h
--                       , xt0c.bm3_bm_payment_type                   AS bm3_bm_payment_type           -- �y�a�l�R�zBM�x���敪
--                       , xt0c.tax_div                               AS tax_div                       -- ����ŋ敪
--                       , xt0c.tax_code                              AS tax_code                      -- �ŋ��R�[�h
--                       , xt0c.tax_rate                              AS tax_rate                      -- ����ŗ�
--                       , xt0c.tax_rounding_rule                     AS tax_rounding_rule             -- �[�������敪
--                       , xt0c.receiv_discount_rate                  AS receiv_discount_rate          -- �����l����
--                       , xt0c.term_name                             AS term_name                     -- �x������
--                       , xt0c.closing_date                          AS closing_date                  -- ���ߓ�
--                       , xt0c.expect_payment_date                   AS expect_payment_date           -- �x���\���
--                       , xt0c.period_year                           AS period_year                   -- ��v�N�x
--                       , xt0c.calc_target_period_from               AS calc_target_period_from       -- �v�Z�Ώۊ���(FROM)
--                       , xt0c.calc_target_period_to                 AS calc_target_period_to         -- �v�Z�Ώۊ���(TO)
--                       , xseh.sales_base_code                       AS sales_base_code               -- ���㋒�_�R�[�h
--                       , xseh.results_employee_code                 AS results_employee_code         -- ���ьv��҃R�[�h
--                       , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                   -- �[�i�N��
--                       , NULL                                       AS dlv_qty                       -- �[�i����
--                       , NULL                                       AS dlv_uom_code                  -- �[�i�P��
--                       , SUM( xsel.pure_amount + xsel.tax_amount )  AS amount_inc_tax                -- ������z�i�ō��j
--                       , NULL                                       AS container_code                -- �e��敪�R�[�h
--                       , NULL                                       AS dlv_unit_price                -- �������z
--                       , NULL                                       AS item_code                     -- �݌ɕi�ڃR�[�h
--                       , xt0c.amount_fix_date                       AS amount_fix_date               -- ���z�m���
--                  FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
--                     , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
--                     , xxcos_sales_exp_lines         xsel       -- �̔����і���
--                     , xxcmm_system_items_b          xsim       -- Disc�i�ڃA�h�I��
--                     , xxcok_cust_bm_info            xcbi
--                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--                    AND xseh.delivery_date         <= xt0c.closing_date
--                    AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--                    AND EXISTS ( SELECT 'X'
--                                 FROM fnd_lookup_values    flv
--                                 WHERE flv.lookup_type             = cv_lookup_type_07  -- �̎�v�Z�Ώ۔���敪
--                                   AND flv.lookup_code             = xsel.sales_class
--                                   AND flv.language                = USERENV( 'LANG' )
--                                   AND flv.enabled_flag            = cv_enable
--                                   AND gd_process_date       BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                 AND NVL( flv.end_date_active,   gd_process_date )
--                                   AND ROWNUM = 1
--                        )
--                    AND xsim.item_code              = xsel.item_code
--                    AND xsel.item_code              = gv_elec_change_item_code
--                  GROUP BY xseh.ship_to_customer_code
--                         , xt0c.ship_gyotai_tyu
--                         , xt0c.ship_gyotai_sho
--                         , xt0c.ship_delivery_chain_code
--                         , xt0c.bill_cust_code
--                         , xt0c.bm1_vendor_code
--                         , xt0c.bm1_vendor_site_code
--                         , xt0c.bm1_bm_payment_type
--                         , xt0c.bm2_vendor_code
--                         , xt0c.bm2_vendor_site_code
--                         , xt0c.bm2_bm_payment_type
--                         , xt0c.bm3_vendor_code
--                         , xt0c.bm3_vendor_site_code
--                         , xt0c.bm3_bm_payment_type
--                         , xt0c.tax_div
--                         , xt0c.tax_code
--                         , xt0c.tax_rate
--                         , xt0c.tax_rounding_rule
--                         , xt0c.receiv_discount_rate
--                         , xt0c.term_name
--                         , xt0c.closing_date
--                         , xt0c.expect_payment_date
--                         , xt0c.period_year
--                         , xt0c.calc_target_period_from
--                         , xt0c.calc_target_period_to
--                         , xseh.sales_base_code
--                         , xseh.results_employee_code
--                         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
--                         , xt0c.amount_fix_date
--                )                           xses      -- �C�����C���r���[�E�̔����я��i�ڋq�T�}���j
--         )                        xbc
--    GROUP BY xbc.base_code
--           , xbc.emp_code
--           , xbc.ship_cust_code
--           , xbc.ship_gyotai_sho
--           , xbc.ship_gyotai_tyu
--           , xbc.bill_cust_code
--           , xbc.period_year
--           , xbc.ship_delivery_chain_code
--           , xbc.delivery_ym
--           , xbc.dlv_qty
--           , xbc.dlv_uom_code
--           , xbc.amount_inc_tax
--           , xbc.container_code
--           , xbc.dlv_unit_price
--           , xbc.tax_div
--           , xbc.tax_code
--           , xbc.tax_rate
--           , xbc.tax_rounding_rule
--           , xbc.term_name
--           , xbc.closing_date
--           , xbc.expect_payment_date
--           , xbc.calc_target_period_from
--           , xbc.calc_target_period_to
--           , xbc.calc_type
--           , xbc.bm1_vendor_code
--           , xbc.bm1_vendor_site_code
--           , xbc.bm1_bm_payment_type
--           , xbc.bm1_pct
--           , xbc.bm1_amt
--           , xbc.bm2_vendor_code
--           , xbc.bm2_vendor_site_code
--           , xbc.bm2_bm_payment_type
--           , xbc.bm2_pct
--           , xbc.bm2_amt
--           , xbc.bm3_vendor_code
--           , xbc.bm3_vendor_site_code
--           , xbc.bm3_bm_payment_type
--           , xbc.bm3_pct
--           , xbc.bm3_amt
--           , xbc.item_code
--           , xbc.amount_fix_date
--  ;
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--  -- �̔����я��E�d�C��
--  CURSOR get_sales_data_cur5 IS
--    SELECT xses.base_code                    AS base_code                  -- ���_�R�[�h
--         , xses.emp_code                     AS emp_code                   -- �S���҃R�[�h
--         , xses.ship_cust_code               AS ship_cust_code             -- �ڋq�y�[�i��z
--         , xses.ship_gyotai_sho              AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--         , xses.ship_gyotai_tyu              AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi�����ށj
--         , xses.bill_cust_code               AS bill_cust_code             -- �ڋq�y������z
--         , xses.period_year                  AS period_year                -- ��v�N�x
--         , xses.ship_delivery_chain_code     AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
--         , xses.delivery_ym                  AS delivery_ym                -- �[�i���N��
--         , xses.dlv_qty                      AS dlv_qty                    -- �[�i����
--         , xses.dlv_uom_code                 AS dlv_uom_code               -- �[�i�P��
--         , xses.amount_inc_tax               AS amount_inc_tax             -- ������z(�ō�)
--         , xses.container_code               AS container_code             -- �e��敪�R�[�h
--         , xses.dlv_unit_price               AS dlv_unit_price             -- �������z
--         , xses.tax_div                      AS tax_div                    -- ����ŋ敪
--         , xses.tax_code                     AS tax_code                   -- �ŋ��R�[�h
--         , xses.tax_rate                     AS tax_rate                   -- ����ŗ�
--         , xses.tax_rounding_rule            AS tax_rounding_rule          -- �[�������敪
--         , xses.term_name                    AS term_name                  -- �x������
--         , xses.closing_date                 AS closing_date               -- ���ߓ�
--         , xses.expect_payment_date          AS expect_payment_date        -- �x���\���
--         , xses.calc_target_period_from      AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
--         , xses.calc_target_period_to        AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
--         , xses.calc_type                    AS calc_type                  -- �v�Z����
--         , xses.bm1_vendor_code              AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
--         , xses.bm1_vendor_site_code         AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
--         , xses.bm1_bm_payment_type          AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
--         , xses.bm1_pct                      AS bm1_pct                    -- �y�a�l�P�zBM��(%)
--         , NULL                              AS bm1_amt                    -- �y�a�l�P�zBM���z
--         , NULL                              AS bm1_cond_bm_tax_pct        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
--         , NULL                              AS bm1_cond_bm_amt_tax        -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
--         , xses.bm1_amt -- �ϓ��d�C��
--         + NVL( ( SELECT xmbc.bm1_amt
--                  FROM xxcok_mst_bm_contract     xmbc
--                  WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- �v�Z�����F�d�C��
--                    AND xmbc.cust_code               = xses.ship_cust_code
--                    AND xmbc.calc_target_flag        = cv_enable
--                )       -- �Œ�d�C��
--                , 0
--           )                                 AS bm1_electric_amt_tax       -- �y�a�l�P�z�d�C��(�ō�)
--         , xses.bm2_vendor_code              AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
--         , xses.bm2_vendor_site_code         AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
--         , xses.bm2_bm_payment_type          AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
--         , xses.bm2_pct                      AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
--         , xses.bm2_amt                      AS bm2_amt                    -- �y�a�l�Q�zBM���z
--         , NULL                              AS bm2_cond_bm_tax_pct        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
--         , NULL                              AS bm2_cond_bm_amt_tax        -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
--         , NULL                              AS bm2_electric_amt_tax       -- �y�a�l�Q�z�d�C��(�ō�)
--         , xses.bm3_vendor_code              AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
--         , xses.bm3_vendor_site_code         AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
--         , xses.bm3_bm_payment_type          AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
--         , xses.bm3_pct                      AS bm3_pct                    -- �y�a�l�R�zBM��(%)
--         , xses.bm3_amt                      AS bm3_amt                    -- �y�a�l�R�zBM���z
--         , NULL                              AS bm3_cond_bm_tax_pct        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
--         , NULL                              AS bm3_cond_bm_amt_tax        -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
--         , NULL                              AS bm3_electric_amt_tax       -- �y�a�l�R�z�d�C��(�ō�)
--         , xses.item_code                    AS item_code                  -- �G���[�i�ڃR�[�h
--         , xses.amount_fix_date              AS amount_fix_date            -- ���z�m���
--    FROM ( SELECT /*+
--                    LEADING( xt0c, xcbi )
--                    INDEX( xcbi XXCOK_CUST_BM_INFO_U01 )
--                  */
--                  CASE
--                    WHEN   TRUNC( xt0c.closing_date, 'MM' )
--                         = TRUNC( gd_process_date  , 'MM' )
--                    THEN
--                      xca.sale_base_code
--                    ELSE
--                      xca.past_sale_base_code
--                  END                                        AS base_code                  -- ���_�R�[�h
---- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama REPAIR START
----                , xxcok_common_pkg.get_sales_staff_code_f(
----                    xseh.ship_to_customer_code
----                  , xt0c.closing_date
----                  )                                          AS emp_code                   -- �S���҃R�[�h
--                , xt0c.emp_code                              AS emp_code                   -- �S���҃R�[�h
---- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama REPAIR END
--                , xseh.ship_to_customer_code                 AS ship_cust_code             -- �ڋq�y�[�i��z
--                , xt0c.ship_gyotai_sho                       AS ship_gyotai_sho            -- �ڋq�y�[�i��z�Ƒԁi������
--                , xt0c.ship_gyotai_tyu                       AS ship_gyotai_tyu            -- �ڋq�y�[�i��z�Ƒԁi������
--                , xt0c.bill_cust_code                        AS bill_cust_code             -- �ڋq�y������z
--                , xt0c.period_year                           AS period_year                -- ��v�N�x
--                , xt0c.ship_delivery_chain_code              AS ship_delivery_chain_code   -- �`�F�[���X�R�[�h
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR START
----                , TO_CHAR( xseh.delivery_date, 'RRRRMM' )    AS delivery_ym                -- �[�i���N��
--                , TO_CHAR( xt0c.closing_date, 'RRRRMM' )     AS delivery_ym                -- �[�i���N��
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR END
--                , NULL                                       AS dlv_qty                    -- �[�i����
--                , NULL                                       AS dlv_uom_code               -- �[�i�P��
--                , SUM( CASE
--                         WHEN EXISTS ( SELECT 'X'
--                                       FROM xxcok_mst_bm_contract     xmbc
--                                       WHERE xmbc.cust_code               = xt0c.ship_cust_code
--                                         AND xmbc.calc_target_flag        = cv_enable
--                                         AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                            , cv_calc_type_container
--                                                                            , cv_calc_type_uniform_rate
--                                                                            , cv_calc_type_flat_rate
--                                                                            )
--                                         AND ROWNUM = 1
--                              )
--                         THEN
--                           0
--                         WHEN EXISTS ( SELECT 'X'
--                                       FROM fnd_lookup_values flv -- ��݌ɕi��
--                                       WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
--                                         AND flv.lookup_code         = xsel.item_code
--                                         AND flv.language            = cv_lang
--                                         AND flv.enabled_flag        = cv_enable
--                                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                                   AND NVL( flv.end_date_active  , gd_process_date )
--                                         AND ROWNUM = 1
--                             )
--                         THEN
--                           0
--                         ELSE
--                           xsel.pure_amount + xsel.tax_amount
--                       END
--                  )                                          AS amount_inc_tax             -- ������z(�ō�)
--                , NULL                                       AS container_code             -- �e��敪�R�[�h
--                , NULL                                       AS dlv_unit_price             -- �������z
--                , xt0c.tax_div                               AS tax_div                    -- ����ŋ敪
--                , xt0c.tax_code                              AS tax_code                   -- �ŋ��R�[�h
--                , xt0c.tax_rate                              AS tax_rate                   -- ����ŗ�
--                , xt0c.tax_rounding_rule                     AS tax_rounding_rule          -- �[�������敪
--                , xt0c.term_name                             AS term_name                  -- �x������
--                , xt0c.closing_date                          AS closing_date               -- ���ߓ�
--                , xt0c.expect_payment_date                   AS expect_payment_date        -- �x���\���
--                , xt0c.calc_target_period_from               AS calc_target_period_from    -- �v�Z�Ώۊ���(FROM)
--                , xt0c.calc_target_period_to                 AS calc_target_period_to      -- �v�Z�Ώۊ���(TO)
--                , cv_calc_type_electricity_cost              AS calc_type                  -- �v�Z����
--                , xt0c.bm1_vendor_code                       AS bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
--                , xt0c.bm1_vendor_site_code                  AS bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
--                , xt0c.bm1_bm_payment_type                   AS bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
--                , NULL                                       AS bm1_pct                    -- �y�a�l�P�zBM��(%)
--                , SUM( CASE
--                         WHEN xsel.item_code = gv_elec_change_item_code THEN
--                           xsel.pure_amount + xsel.tax_amount
--                         ELSE
--                           0
--                       END
--                  )                                          AS bm1_amt                    -- �y�a�l�P�zBM���z
--                , NULL                                       AS bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
--                , NULL                                       AS bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
--                , NULL                                       AS bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
--                , NULL                                       AS bm2_pct                    -- �y�a�l�Q�zBM��(%)
--                , NULL                                       AS bm2_amt                    -- �y�a�l�Q�zBM���z
--                , NULL                                       AS bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
--                , NULL                                       AS bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
--                , NULL                                       AS bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
--                , NULL                                       AS bm3_pct                    -- �y�a�l�R�zBM��(%)
--                , NULL                                       AS bm3_amt                    -- �y�a�l�R�zBM���z
--                , NULL                                       AS item_code                  -- �G���[�i�ڃR�[�h
--                , xt0c.amount_fix_date                       AS amount_fix_date            -- ���z�m���
--           FROM xxcok_tmp_014a01c_custdata    xt0c       -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
--              , xxcos_sales_exp_headers       xseh       -- �̔����уw�b�_
--              , xxcos_sales_exp_lines         xsel       -- �̔����і���
--              , xxcok_cust_bm_info            xcbi
--              , hz_cust_accounts              hca
--              , xxcmm_cust_accounts           xca
--           WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
--             AND xseh.delivery_date         <= xt0c.closing_date
--             AND xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )
--             AND xt0c.ship_cust_code         = xcbi.cust_code(+)
--             AND xt0c.ship_cust_code         = hca.account_number
--             AND hca.cust_account_id         = xca.customer_id
--             AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
--             AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
--             AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
--             AND EXISTS ( SELECT 'X'
--                          FROM fnd_lookup_values    flv
--                          WHERE flv.lookup_type             = cv_lookup_type_07  -- �̎�v�Z�Ώ۔���敪
--                            AND flv.lookup_code             = xsel.sales_class
--                            AND flv.language                = USERENV( 'LANG' )
--                            AND flv.enabled_flag            = cv_enable
--                            AND gd_process_date       BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                          AND NVL( flv.end_date_active,   gd_process_date )
--                            AND ROWNUM = 1
--                 )
--             AND (    ( EXISTS ( SELECT 'X'
--                                 FROM xxcos_sales_exp_headers   xseh2
--                                    , xxcos_sales_exp_lines     xsel2
--                                 WHERE xseh2.sales_exp_header_id    = xsel2.sales_exp_header_id
--                                   AND xseh2.ship_to_customer_code  = xt0c.ship_cust_code
--                                   AND xseh2.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh2.delivery_date )
--                                   AND xsel2.to_calculate_fees_flag = cv_xsel_if_flag_no
--                                   AND xsel2.item_code              = gv_elec_change_item_code -- �ϓ��d�C��
--                                   AND ROWNUM = 1
--                        )
--                      )
--                   OR ( EXISTS ( SELECT 'X'
--                                 FROM xxcok_mst_bm_contract     xmbc
--                                 WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- �v�Z�����F�d�C��
--                                   AND xmbc.cust_code               = xt0c.ship_cust_code
--                                   AND xmbc.calc_target_flag        = cv_enable
--                                   AND ROWNUM = 1
--                        )
--                      )
--                 )
--           GROUP BY CASE
--                      WHEN   TRUNC( xt0c.closing_date, 'MM' )
--                           = TRUNC( gd_process_date  , 'MM' )
--                      THEN
--                        xca.sale_base_code
--                      ELSE
--                        xca.past_sale_base_code
--                    END
---- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
--                  , xt0c.emp_code
---- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
--                  , xseh.ship_to_customer_code
--                  , xt0c.ship_gyotai_sho
--                  , xt0c.ship_gyotai_tyu
--                  , xt0c.bill_cust_code
--                  , xt0c.period_year
--                  , xt0c.ship_delivery_chain_code
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi DELETE START
----                  , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
---- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi DELETE END
--                  , xt0c.tax_div
--                  , xt0c.tax_code
--                  , xt0c.tax_rate
--                  , xt0c.tax_rounding_rule
--                  , xt0c.term_name
--                  , xt0c.closing_date
--                  , xt0c.expect_payment_date
--                  , xt0c.calc_target_period_from
--                  , xt0c.calc_target_period_to
--                  , xt0c.bm1_vendor_code
--                  , xt0c.bm1_vendor_site_code
--                  , xt0c.bm1_bm_payment_type
--                  , xt0c.amount_fix_date
--         ) xses
--  ;
  -- �̔����я��E�d�C��
  CURSOR get_sales_data_cur5 IS
    SELECT /*+
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--             LEADING( xt0c hca xca xcbi xmbc )
             LEADING( xt0c hca xca xcbi xseh xsel )
             USE_NL( xt0c hca xca xcbi xseh xsel )
             INDEX( xseh XXCOS_SALES_EXP_HEADERS_N08 )
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
           */
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                    AS base_code                -- ���_�R�[�h
         , xt0c.emp_code                          AS emp_code                 -- �S���҃R�[�h
         , xt0c.ship_cust_code                    AS ship_cust_code           -- �ڋq�y�[�i��z
         , xt0c.ship_gyotai_sho                   AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.ship_gyotai_tyu                   AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.bill_cust_code                    AS bill_cust_code           -- �ڋq�y������z
         , xt0c.period_year                       AS period_year              -- ��v�N�x
         , xt0c.ship_delivery_chain_code          AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) AS delivery_ym              -- �[�i���N��
         , NULL                                   AS dlv_qty                  -- �[�i����
         , NULL                                   AS dlv_uom_code             -- �[�i�P��
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
-- 2012/02/23 Ver.3.14 [E_�{�ғ�_09144] SCSK S.Niki REPAIR START
         , CASE
             WHEN EXISTS ( SELECT 'X'
                           FROM xxcok_mst_bm_contract     xmbc   -- �̎�����}�X�^
                           WHERE xmbc.cust_code               = xt0c.ship_cust_code
                             AND xmbc.calc_target_flag        = cv_enable
                             AND xmbc.calc_type              IN ( cv_calc_type_sales_price    -- �����ʏ���
                                                                , cv_calc_type_container      -- �e��敪�ʏ���
                                                                , cv_calc_type_uniform_rate   -- �ꗥ����
                                                                , cv_calc_type_flat_rate      -- ��z
                                                                )
                             AND ROWNUM = 1
                  )
             THEN
               0
             ELSE
               ( SELECT NVL( SUM( xsel.pure_amount + xsel.tax_amount ), 0 )
                 FROM xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
                    , xxcos_sales_exp_lines       xsel  -- �̔����і���
                 WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                   AND xseh.delivery_date         <= xt0c.closing_date
                   AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                   AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                   AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                   AND EXISTS ( SELECT  'X'
                                FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                  AND flv.lookup_code         = xsel.sales_class
                                  AND flv.language            = cv_lang
                                  AND flv.enabled_flag        = cv_enable
                                  AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                            AND NVL( flv.end_date_active  , gd_process_date )
                                  AND ROWNUM = 1
                       )
                   AND NOT EXISTS ( SELECT 'X'
                                    FROM fnd_lookup_values flv -- ��݌ɕi��
                                    WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
                                      AND flv.lookup_code         = xsel.item_code
                                      AND flv.language            = cv_lang
                                      AND flv.enabled_flag        = cv_enable
                                      AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                AND NVL( flv.end_date_active  , gd_process_date )
                                      AND ROWNUM = 1
                       )
               )
           END                           AS amount_inc_tax           -- ������z�i�ō��j
--        , SUM(
--            CASE
--              WHEN EXISTS ( SELECT 'X'
--                            FROM xxcok_mst_bm_contract     xmbc
--                            WHERE xmbc.cust_code               = xt0c.ship_cust_code
--                              AND xmbc.calc_target_flag        = cv_enable
--                              AND xmbc.calc_type              IN ( cv_calc_type_sales_price
--                                                                 , cv_calc_type_container
--                                                                 , cv_calc_type_uniform_rate
--                                                                 , cv_calc_type_flat_rate
--                                                                 )
--                              AND ROWNUM = 1
--                   )
--              THEN
--                0
--              ELSE
--                NVL( xsel.pure_amount + xsel.tax_amount, 0 )
--            END
--          )                             AS amount_inc_tax           -- ������z�i�ō��j
-- 2012/02/23 Ver.3.14 [E_�{�ғ�_09144] SCSK S.Niki REPAIR END
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
-- Ver.3.20 N.Abe ADD START
         , CASE
             WHEN EXISTS ( SELECT 'X'
                           FROM xxcok_mst_bm_contract     xmbc   -- �̎�����}�X�^
                           WHERE xmbc.cust_code               = xt0c.ship_cust_code
                             AND xmbc.calc_target_flag        = cv_enable
                             AND xmbc.calc_type              IN ( cv_calc_type_sales_price    -- �����ʏ���
                                                                , cv_calc_type_container      -- �e��敪�ʏ���
                                                                , cv_calc_type_uniform_rate   -- �ꗥ����
                                                                , cv_calc_type_flat_rate      -- ��z
                                                                )
                             AND ROWNUM = 1
                  )
             THEN
               0
             ELSE
               ( SELECT NVL( SUM( xsel.pure_amount ), 0 )
                 FROM xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
                    , xxcos_sales_exp_lines       xsel  -- �̔����і���
                 WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                   AND xseh.delivery_date         <= xt0c.closing_date
                   AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                   AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                   AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                   AND EXISTS ( SELECT  'X'
                                FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                  AND flv.lookup_code         = xsel.sales_class
                                  AND flv.language            = cv_lang
                                  AND flv.enabled_flag        = cv_enable
                                  AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                            AND NVL( flv.end_date_active  , gd_process_date )
                                  AND ROWNUM = 1
                       )
                   AND NOT EXISTS ( SELECT 'X'
                                    FROM fnd_lookup_values flv -- ��݌ɕi��
                                    WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
                                      AND flv.lookup_code         = xsel.item_code
                                      AND flv.language            = cv_lang
                                      AND flv.enabled_flag        = cv_enable
                                      AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                                AND NVL( flv.end_date_active  , gd_process_date )
                                      AND ROWNUM = 1
                       )
               )
           END                           AS amount_no_tax            -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
         , NULL                          AS container_code           -- �e��敪�R�[�h
         , NULL                          AS dlv_unit_price           -- �������z
         , xt0c.tax_div                  AS tax_div                  -- ����ŋ敪
         , xt0c.tax_code                 AS tax_code                 -- �ŋ��R�[�h
         , xt0c.tax_rate                 AS tax_rate                 -- ����ŗ�
         , xt0c.tax_rounding_rule        AS tax_rounding_rule        -- �[�������敪
         , xt0c.term_name                AS term_name                -- �x������
         , xt0c.closing_date             AS closing_date             -- ���ߓ�
         , xt0c.expect_payment_date      AS expect_payment_date      -- �x���\���
         , xt0c.calc_target_period_from  AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
         , xt0c.calc_target_period_to    AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
         , cv_calc_type_electricity_cost AS calc_type                -- �v�Z����
         , xt0c.bm1_vendor_code          AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
         , xt0c.bm1_vendor_site_code     AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
         , xt0c.bm1_bm_payment_type      AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
         , NULL                          AS bm1_pct                  -- �y�a�l�P�zBM��(%)
         , NULL                          AS bm1_amt                  -- �y�a�l�P�zBM���z
         , NULL                          AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , NULL                          AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NVL( ( SELECT SUM( xsel.pure_amount + xsel.tax_amount )  -- �ϓ��d�C��
                  FROM xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
                     , xxcos_sales_exp_lines       xsel  -- �̔����і���
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
                    AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND EXISTS ( SELECT  'X'
                                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                   AND ROWNUM = 1
                        )
                    AND xsel.item_code              = gv_elec_change_item_code
                )
              , 0
           )
         + NVL( ( SELECT xmbc.bm1_amt       -- �Œ�d�C��
                  FROM xxcok_mst_bm_contract     xmbc
-- 2011/03/23 Ver.3.13 [E_�{�ғ�_06757] SCS M.Watanabe ADD START
                      ,xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_
                      ,xxcos_sales_exp_lines     xsel  -- �̔����і���
-- 2011/03/23 Ver.3.13 [E_�{�ғ�_06757] SCS M.Watanabe ADD END
                  WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- �v�Z�����F�d�C��
                    AND xmbc.cust_code               = xt0c.ship_cust_code
                    AND xmbc.calc_target_flag        = cv_enable
-- 2011/04/01 Ver.3.13 [E_�{�ғ�_06757] SCS M.Watanabe ADD START
                    AND xseh.ship_to_customer_code   = xmbc.cust_code
                    AND xseh.delivery_date          <= xt0c.closing_date
                    AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND xseh.business_date          <= gd_process_date
                    AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
                    AND EXISTS ( SELECT  'X'
                                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                        )
                    AND xsel.item_code              <> gv_elec_change_item_code
                    AND ROWNUM = 1
-- 2011/04/01 Ver.3.13 [E_�{�ғ�_06757] SCS M.Watanabe ADD END
                )
              , 0
           )                             AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
-- Ver.3.20 N.Abe ADD START
         , NVL( ( SELECT SUM( xsel.pure_amount )  -- �ϓ��d�C��
                  FROM xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
                     , xxcos_sales_exp_lines       xsel  -- �̔����і���
                  WHERE xseh.ship_to_customer_code  = xt0c.ship_cust_code
                    AND xseh.delivery_date         <= xt0c.closing_date
                    AND xseh.business_date         <= gd_process_date
                    AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                    AND EXISTS ( SELECT  'X'
                                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                                   AND ROWNUM = 1
                        )
                    AND xsel.item_code              = gv_elec_change_item_code
                )
              , 0
           )
         + NVL( ( SELECT xmbc.bm1_amt       -- �Œ�d�C��
                  FROM xxcok_mst_bm_contract     xmbc
                      ,xxcos_sales_exp_headers   xseh  -- �̔����уw�b�_
                      ,xxcos_sales_exp_lines     xsel  -- �̔����і���
                  WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- �v�Z�����F�d�C��
                    AND xmbc.cust_code               = xt0c.ship_cust_code
                    AND xmbc.calc_target_flag        = cv_enable
                    AND xseh.ship_to_customer_code   = xmbc.cust_code
                    AND xseh.delivery_date          <= xt0c.closing_date
                    AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                    AND xseh.business_date          <= gd_process_date
                    AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
                    AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
                    AND EXISTS ( SELECT  'X'
                                 FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                                 WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                                   AND flv.lookup_code         = xsel.sales_class
                                   AND flv.language            = cv_lang
                                   AND flv.enabled_flag        = cv_enable
                                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                             AND NVL( flv.end_date_active  , gd_process_date )
                        )
                    AND xsel.item_code              <> gv_elec_change_item_code
                    AND ROWNUM = 1
                )
              , 0
           )                             AS bm1_electric_amt_no_tax  -- �y�a�l�P�z�d�C��(�Ŕ�)
-- Ver.3.20 N.Abe ADD END
         , NULL                          AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
         , NULL                          AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , NULL                          AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
         , NULL                          AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
         , NULL                          AS bm2_amt                  -- �y�a�l�Q�zBM���z
         , NULL                          AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , NULL                          AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                          AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
         , NULL                          AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
         , NULL                          AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
         , NULL                          AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
         , NULL                          AS bm3_pct                  -- �y�a�l�R�zBM��(%)
         , NULL                          AS bm3_amt                  -- �y�a�l�R�zBM���z
         , NULL                          AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , NULL                          AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                          AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
         , NULL                          AS item_code                -- �G���[�i�ڃR�[�h
         , xt0c.amount_fix_date          AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
         , xt0c.vendor_dummy_flag        AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
         ,NVL( xmbc.bm1_tax_kbn, '1' )   AS bm1_tax_kbn              -- BM1�ŋ敪
         ,'1'                            AS bm2_tax_kbn              -- BM2�ŋ敪
         ,'1'                            AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--    FROM xxcok_tmp_014a01c_custdata      xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
    FROM xxcok_wk_014a01c_custdata       xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
       , xxcok_cust_bm_info              xcbi
       , hz_cust_accounts                hca
       , xxcmm_cust_accounts             xca
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
       , xxcos_sales_exp_headers         xseh  -- �̔����уw�b�_
       , xxcos_sales_exp_lines           xsel  -- �̔����і���
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
-- Ver.3.20 N.Abe ADD START
       , xxcok_mst_bm_contract           xmbc  -- �̎�����}�X�^
-- Ver.3.20 N.Abe ADD END
    WHERE xt0c.ship_gyotai_sho       IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      AND EXISTS ( SELECT  'X'
                   FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                   WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                     AND flv.lookup_code         = xsel.sales_class
                     AND flv.language            = cv_lang
                     AND flv.enabled_flag        = cv_enable
                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                               AND NVL( flv.end_date_active  , gd_process_date )
                     AND ROWNUM = 1
          )
--
-- 2011/03/23 Ver.3.13 [E_�{�ғ�_06757] SCS M.Watanabe DEL START
--      AND NOT EXISTS ( SELECT 'X'
--                       FROM fnd_lookup_values flv -- ��݌ɕi��
--                       WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
--                         AND flv.lookup_code         = xsel.item_code
--                         AND flv.language            = cv_lang
--                         AND flv.enabled_flag        = cv_enable
--                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
--                                                   AND NVL( flv.end_date_active  , gd_process_date )
--                              AND ROWNUM = 1
--          )
-- 2011/03/23 Ver.3.13 [E_�{�ғ�_06757] SCS M.Watanabe DEL END
--
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
      AND (    ( EXISTS ( SELECT 'X'
                          FROM xxcos_sales_exp_headers   xseh
                             , xxcos_sales_exp_lines     xsel
                          WHERE xseh.sales_exp_header_id    = xsel.sales_exp_header_id
                            AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
                            AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
                            AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
                            AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                            AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
                            AND xsel.item_code              = gv_elec_change_item_code -- �ϓ��d�C��
                            AND ROWNUM = 1
                 )
               )
            OR ( EXISTS ( SELECT 'X'
                          FROM xxcok_mst_bm_contract     xmbc
                          WHERE xmbc.calc_type               = cv_calc_type_electricity_cost  -- �v�Z�����F�d�C��
                            AND xmbc.cust_code               = xt0c.ship_cust_code
                            AND xmbc.calc_target_flag        = cv_enable
                            AND ROWNUM = 1
                 )
               )
          )
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR START
-- Ver.3.20 N.Abe ADD START
      AND xmbc.calc_type(+)           = cv_calc_type_electricity_cost  -- �v�Z�����F�d�C��
      AND xmbc.cust_code(+)           = xt0c.ship_cust_code
      AND xmbc.calc_target_flag(+)    = cv_enable
-- Ver.3.20 N.Abe ADD END
    GROUP BY CASE
               WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                 xca.sale_base_code
               ELSE
                 xca.past_sale_base_code
             END                                    -- ���_�R�[�h
           , xt0c.emp_code                          -- �S���҃R�[�h
           , xt0c.ship_cust_code                    -- �ڋq�y�[�i��z
           , xt0c.ship_gyotai_sho                   -- �ڋq�y�[�i��z�Ƒԁi�����ށj
           , xt0c.ship_gyotai_tyu                   -- �ڋq�y�[�i��z�Ƒԁi�����ށj
           , xt0c.bill_cust_code                    -- �ڋq�y������z
           , xt0c.period_year                       -- ��v�N�x
           , xt0c.ship_delivery_chain_code          -- �`�F�[���X�R�[�h
           , TO_CHAR( xt0c.closing_date, 'RRRRMM' ) -- �[�i���N��
           , xt0c.tax_div                           -- ����ŋ敪
           , xt0c.tax_code                          -- �ŋ��R�[�h
           , xt0c.tax_rate                          -- ����ŗ�
           , xt0c.tax_rounding_rule                 -- �[�������敪
           , xt0c.term_name                         -- �x������
           , xt0c.closing_date                      -- ���ߓ�
           , xt0c.expect_payment_date               -- �x���\���
           , xt0c.calc_target_period_from           -- �v�Z�Ώۊ���(FROM)
           , xt0c.calc_target_period_to             -- �v�Z�Ώۊ���(TO)
           , xt0c.bm1_vendor_code                   -- �y�a�l�P�z�d����R�[�h
           , xt0c.bm1_vendor_site_code              -- �y�a�l�P�z�d����T�C�g�R�[�h
           , xt0c.bm1_bm_payment_type               -- �y�a�l�P�zBM�x���敪
           , xcbi.last_fix_delivery_date            -- �O��m��̔[�i��
           , xt0c.amount_fix_date                   -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
           , xt0c.vendor_dummy_flag                 -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01896] SCS S.Niki REPAIR END
-- Ver.3.20 N.Abe ADD START
           , NVL( xmbc.bm1_tax_kbn, '1' )           -- BM1�ŋ敪
-- Ver.3.20 N.Abe ADD END
  ;
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
-- 2009/12/21 Ver.3.6 [E_�{�ғ�_00460] SCS K.Yamaguchi REPAIR END
  -- �̔����я��E�����l����
  CURSOR get_sales_data_cur6 IS
-- 2012/10/18 Ver.3.17 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--    SELECT /*+ LEADING(xt0c xcbi xseh xsel) */
    SELECT /*+
             LEADING( xt0c xcbi xseh xsel hca xca )
             USE_NL( xt0c xcbi xseh xsel hca xca )
             INDEX( xseh XXCOS_SALES_EXP_HEADERS_N08 )
           */
-- 2012/10/18 Ver.3.17 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--           xseh.sales_base_code                                                                  AS base_code                -- ���_�R�[�h
--         , xseh.results_employee_code                                                            AS emp_code                 -- �S���҃R�[�h
           CASE
             WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
               xca.sale_base_code
             ELSE
               xca.past_sale_base_code
           END                                                                                   AS base_code                -- ���_�R�[�h
         , xt0c.emp_code                                                                         AS emp_code                 -- �S���҃R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
         , xseh.ship_to_customer_code                                                            AS ship_cust_code           -- �ڋq�y�[�i��z
         , xt0c.ship_gyotai_sho                                                                  AS ship_gyotai_sho          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.ship_gyotai_tyu                                                                  AS ship_gyotai_tyu          -- �ڋq�y�[�i��z�Ƒԁi�����ށj
         , xt0c.bill_cust_code                                                                   AS bill_cust_code           -- �ڋq�y������z
         , xt0c.period_year                                                                      AS period_year              -- ��v�N�x
         , xt0c.ship_delivery_chain_code                                                         AS ship_delivery_chain_code -- �`�F�[���X�R�[�h
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--         , TO_CHAR( xseh.delivery_date, 'RRRRMM' )                                               AS delivery_ym              -- �[�i���N��
         , TO_CHAR( xt0c.closing_date, 'RRRRMM' )                                                AS delivery_ym              -- �[�i���N��
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
         , NULL                                                                                  AS dlv_qty                  -- �[�i����
         , NULL                                                                                  AS dlv_uom_code             -- �[�i�P��
         , SUM( xsel.pure_amount + xsel.tax_amount )                                             AS amount_inc_tax           -- ������z�i�ō��j
-- Ver.3.20 N.Abe ADD START
         , SUM( xsel.pure_amount )                                                               AS amount_no_tax            -- ������z�i�Ŕ��j
-- Ver.3.20 N.Abe ADD END
         , NULL                                                                                  AS container_code           -- �e��敪�R�[�h
         , NULL                                                                                  AS dlv_unit_price           -- �������z
         , xt0c.tax_div                                                                          AS tax_div                  -- ����ŋ敪
-- Ver.3.19 SCSK K.Nara MOD START
--         , xt0c.tax_code                                                                         AS tax_code                 -- �ŋ��R�[�h
--         , xt0c.tax_rate                                                                         AS tax_rate                 -- ����ŗ�
         , CASE xt0c.tax_div
             WHEN cv_tax_div_no_tax THEN
               xt0c.tax_code
             ELSE 
               NVL(xsel.tax_code, xseh.tax_code)
           END                                                                                   AS tax_code                 -- �ŋ��R�[�h
         , CASE xt0c.tax_div
             WHEN cv_tax_div_no_tax THEN
               xt0c.tax_rate
             ELSE 
               NVL(xsel.tax_rate, xseh.tax_rate)
           END                                                                                   AS tax_rate                 -- ����ŗ�
-- Ver.3.19 SCSK K.Nara MOD END
         , xt0c.tax_rounding_rule                                                                AS tax_rounding_rule        -- �[�������敪
         , xt0c.term_name                                                                        AS term_name                -- �x������
         , xt0c.closing_date                                                                     AS closing_date             -- ���ߓ�
         , xt0c.expect_payment_date                                                              AS expect_payment_date      -- �x���\���
         , xt0c.calc_target_period_from                                                          AS calc_target_period_from  -- �v�Z�Ώۊ���(FROM)
         , xt0c.calc_target_period_to                                                            AS calc_target_period_to    -- �v�Z�Ώۊ���(TO)
         , '30'                                                                                  AS calc_type                -- �v�Z����
         , xt0c.bm1_vendor_code                                                                  AS bm1_vendor_code          -- �y�a�l�P�z�d����R�[�h
         , xt0c.bm1_vendor_site_code                                                             AS bm1_vendor_site_code     -- �y�a�l�P�z�d����T�C�g�R�[�h
         , NULL                                                                                  AS bm1_bm_payment_type      -- �y�a�l�P�zBM�x���敪
         , xt0c.receiv_discount_rate                                                             AS bm1_pct                  -- �y�a�l�P�zBM��(%)
         , NULL                                                                                  AS bm1_amt                  -- �y�a�l�P�zBM���z
         , TRUNC( SUM( xsel.pure_amount + xsel.tax_amount ) * xt0c.receiv_discount_rate / 100 )  AS bm1_cond_bm_tax_pct      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_��
         , NULL                                                                                  AS bm1_cond_bm_amt_tax      -- �y�a�l�P�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                                                  AS bm1_electric_amt_tax     -- �y�a�l�P�z�d�C��(�ō�)
-- Ver.3.20 N.Abe ADD START
         , NULL                                                                                  AS bm1_electric_amt_no_tax  -- �y�a�l�P�z�d�C��(�Ŕ�)
-- Ver.3.20 N.Abe ADD END
         , NULL                                                                                  AS bm2_vendor_code          -- �y�a�l�Q�z�d����R�[�h
         , NULL                                                                                  AS bm2_vendor_site_code     -- �y�a�l�Q�z�d����T�C�g�R�[�h
         , NULL                                                                                  AS bm2_bm_payment_type      -- �y�a�l�Q�zBM�x���敪
         , NULL                                                                                  AS bm2_pct                  -- �y�a�l�Q�zBM��(%)
         , NULL                                                                                  AS bm2_amt                  -- �y�a�l�Q�zBM���z
         , NULL                                                                                  AS bm2_cond_bm_tax_pct      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_��
         , NULL                                                                                  AS bm2_cond_bm_amt_tax      -- �y�a�l�Q�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                                                  AS bm2_electric_amt_tax     -- �y�a�l�Q�z�d�C��(�ō�)
         , NULL                                                                                  AS bm3_vendor_code          -- �y�a�l�R�z�d����R�[�h
         , NULL                                                                                  AS bm3_vendor_site_code     -- �y�a�l�R�z�d����T�C�g�R�[�h
         , NULL                                                                                  AS bm3_bm_payment_type      -- �y�a�l�R�zBM�x���敪
         , NULL                                                                                  AS bm3_pct                  -- �y�a�l�R�zBM��(%)
         , NULL                                                                                  AS bm3_amt                  -- �y�a�l�R�zBM���z
         , NULL                                                                                  AS bm3_cond_bm_tax_pct      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_��
         , NULL                                                                                  AS bm3_cond_bm_amt_tax      -- �y�a�l�R�z�����ʎ萔���z(�ō�)_�z
         , NULL                                                                                  AS bm3_electric_amt_tax     -- �y�a�l�R�z�d�C��(�ō�)
         , NULL                                                                                  AS item_code                -- �G���[�i�ڃR�[�h
         , xt0c.amount_fix_date                                                                  AS amount_fix_date          -- ���z�m���
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
         , xt0c.vendor_dummy_flag                                                                AS vendor_dummy_flag        -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
         , '1'                                                                                   AS bm1_tax_kbn              -- BM1�ŋ敪
         , '1'                                                                                   AS bm2_tax_kbn              -- BM2�ŋ敪
         , '1'                                                                                   AS bm3_tax_kbn              -- BM3�ŋ敪
-- Ver.3.20 N.Abe ADD START
    FROM xxcos_sales_exp_lines       xsel  -- �̔����і���
       , xxcos_sales_exp_headers     xseh  -- �̔����уw�b�_
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--       , xxcok_tmp_014a01c_custdata  xt0c  -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
       , xxcok_wk_014a01c_custdata  xt0c   -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
       , xxcok_cust_bm_info          xcbi
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
       , hz_cust_accounts            hca
       , xxcmm_cust_accounts         xca
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--    WHERE xt0c.ship_gyotai_tyu       <> cv_gyotai_tyu_vd                          -- �Ƒԁi�����ށj�FVD
    WHERE xt0c.ship_gyotai_sho   NOT IN ( cv_gyotai_sho_25, cv_gyotai_sho_24 )    -- �Ƒԁi�����ށj�F�t���T�[�r�XVD�E�t���T�[�r�X�i�����jVD
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
      AND xseh.ship_to_customer_code  = xt0c.ship_cust_code
      AND xseh.delivery_date         <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
      AND xseh.business_date         <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
      AND xt0c.ship_cust_code         = xcbi.cust_code(+)
      AND xseh.delivery_date         >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
      AND xseh.sales_exp_header_id    = xsel.sales_exp_header_id
      AND xsel.to_calculate_fees_flag = cv_xsel_if_flag_no
      AND xt0c.receiv_discount_rate  IS NOT NULL
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD START
      AND xt0c.ship_cust_code         = hca.account_number
      AND hca.cust_account_id         = xca.customer_id
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi ADD END
      AND EXISTS (  SELECT 'X'
                    FROM fnd_lookup_values flv -- �̎�v�Z�Ώ۔���敪
                    WHERE flv.lookup_type         = cv_lookup_type_07             -- �Q�ƃ^�C�v�F�̎�v�Z�Ώ۔���敪
                      AND flv.lookup_code         = xsel.sales_class
                      AND flv.language            = cv_lang
                      AND flv.enabled_flag        = cv_enable
                      AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                      AND ROWNUM = 1
          )
      AND NOT EXISTS ( SELECT 'X'
                       FROM fnd_lookup_values flv -- ��݌ɕi��
                       WHERE flv.lookup_type         = cv_lookup_type_05         -- �Q�ƃ^�C�v�F��݌ɕi��
                         AND flv.lookup_code         = xsel.item_code
                         AND flv.language            = cv_lang
                         AND flv.enabled_flag        = cv_enable
                         AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active  , gd_process_date )
-- 2009/11/09 Ver.3.4 [�d�l�ύXI_E_633] SCS K.Yamaguchi ADD START
                         AND flv.attribute2          = cv_disable
-- 2009/11/09 Ver.3.4 [�d�l�ύXI_E_633] SCS K.Yamaguchi ADD END
                         AND ROWNUM = 1
          )
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--    GROUP BY xseh.sales_base_code
--           , xseh.results_employee_code
    GROUP BY CASE
               WHEN TRUNC( xt0c.closing_date, 'MM' ) = TRUNC( gd_process_date, 'MM' ) THEN
                 xca.sale_base_code
               ELSE
                 xca.past_sale_base_code
             END
           , xt0c.emp_code
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
           , xseh.ship_to_customer_code
           , xt0c.ship_gyotai_sho
           , xt0c.ship_gyotai_tyu
           , xt0c.bill_cust_code
           , xt0c.period_year
           , xt0c.ship_delivery_chain_code
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR START
--           , TO_CHAR( xseh.delivery_date, 'RRRRMM' )
           , TO_CHAR( xt0c.closing_date, 'RRRRMM' )
-- 2010/03/16 Ver.3.9 [E_�{�ғ�_01896] SCS K.Yamaguchi REPAIR END
           , xt0c.tax_div
-- Ver.3.19 SCSK K.Nara MOD START
--           , xt0c.tax_code
--           , xt0c.tax_rate
           , CASE xt0c.tax_div
               WHEN cv_tax_div_no_tax THEN
                 xt0c.tax_code
               ELSE 
                 NVL(xsel.tax_code, xseh.tax_code)
             END
           , CASE xt0c.tax_div
               WHEN cv_tax_div_no_tax THEN
                 xt0c.tax_rate
               ELSE 
                 NVL(xsel.tax_rate, xseh.tax_rate)
             END
-- Ver.3.19 SCSK K.Nara MOD END
           , xt0c.tax_rounding_rule
           , xt0c.term_name
           , xt0c.closing_date
           , xt0c.expect_payment_date
           , xt0c.calc_target_period_from
           , xt0c.calc_target_period_to
           , xt0c.bm1_vendor_code
           , xt0c.bm1_vendor_site_code
           , xt0c.receiv_discount_rate
           , xt0c.amount_fix_date
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
           , xt0c.vendor_dummy_flag
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
  ;
  --==================================================
  -- �O���[�o���^�C�v
  --==================================================
  TYPE get_sales_data_rtype        IS RECORD (
    base_code                      VARCHAR2(4)
  , emp_code                       VARCHAR2(5)
  , ship_cust_code                 VARCHAR2(9)
  , ship_gyotai_sho                VARCHAR2(2)
  , ship_gyotai_tyu                VARCHAR2(2)
  , bill_cust_code                 VARCHAR2(9)
  , period_year                    NUMBER
  , ship_delivery_chain_code       VARCHAR2(9)
  , delivery_ym                    VARCHAR2(6)
  , dlv_qty                        NUMBER
  , dlv_uom_code                   VARCHAR2(3)
  , amount_inc_tax                 NUMBER
-- Ver.3.20 N.Abe ADD START
  , amount_no_tax                  NUMBER
-- Ver.3.20 N.Abe ADD END
  , container_code                 VARCHAR2(4)
  , dlv_unit_price                 NUMBER
  , tax_div                        VARCHAR2(1)
  , tax_code                       VARCHAR2(50)
  , tax_rate                       NUMBER
  , tax_rounding_rule              VARCHAR2(30)
  , term_name                      VARCHAR2(8)
  , closing_date                   DATE
  , expect_payment_date            DATE
  , calc_target_period_from        DATE
  , calc_target_period_to          DATE
  , calc_type                      VARCHAR2(2)
  , bm1_vendor_code                VARCHAR2(9)
  , bm1_vendor_site_code           VARCHAR2(10)
  , bm1_bm_payment_type            VARCHAR2(1)
  , bm1_pct                        NUMBER
  , bm1_amt                        NUMBER
  , bm1_cond_bm_tax_pct            NUMBER
  , bm1_cond_bm_amt_tax            NUMBER
  , bm1_electric_amt_tax           NUMBER
-- Ver.3.20 N.Abe ADD START
  , bm1_electric_amt_no_tax        NUMBER
-- Ver.3.20 N.Abe ADD END
  , bm2_vendor_code                VARCHAR2(9)
  , bm2_vendor_site_code           VARCHAR2(10)
  , bm2_bm_payment_type            VARCHAR2(1)
  , bm2_pct                        NUMBER
  , bm2_amt                        NUMBER
  , bm2_cond_bm_tax_pct            NUMBER
  , bm2_cond_bm_amt_tax            NUMBER
  , bm2_electric_amt_tax           NUMBER
  , bm3_vendor_code                VARCHAR2(9)
  , bm3_vendor_site_code           VARCHAR2(10)
  , bm3_bm_payment_type            VARCHAR2(1)
  , bm3_pct                        NUMBER
  , bm3_amt                        NUMBER
  , bm3_cond_bm_tax_pct            NUMBER
  , bm3_cond_bm_amt_tax            NUMBER
  , bm3_electric_amt_tax           NUMBER
  , item_code                      VARCHAR2(7)
  , amount_fix_date                DATE
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  , vendor_dummy_flag              VARCHAR2(1)
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
-- Ver.3.20 N.Abe ADD START
  , bm1_tax_kbn                    VARCHAR2(1)
  , bm2_tax_kbn                    VARCHAR2(1)
  , bm3_tax_kbn                    VARCHAR2(1)
-- Ver.3.20 N.Abe ADD END
  );
  TYPE xcbs_data_ttype             IS TABLE OF xxcok_cond_bm_support%ROWTYPE INDEX BY BINARY_INTEGER;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  TYPE vendor_dummy_flag_ttype     IS TABLE OF xxcok_wk_014a01c_custdata.vendor_dummy_flag%TYPE INDEX BY BINARY_INTEGER;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
--
  /**********************************************************************************
   * Procedure Name   : get_operating_day_f
   * Description      : �ғ����擾(A-16)
   ***********************************************************************************/
  FUNCTION get_operating_day_f(
    id_proc_date                   IN DATE             -- ������
  , in_days                        IN NUMBER           -- ����
  , in_proc_type                   IN NUMBER           -- �����敪
  )
  RETURN DATE
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_operating_day_f';   -- �v���O������
    --==================================================
    -- ���[�J���萔
    --==================================================
    lt_calendar_date               bom_calendar_dates.calendar_date%TYPE;
  --
  BEGIN
    SELECT bcd2.calendar_date
    INTO lt_calendar_date
    FROM ( SELECT CASE
                    WHEN bcd.seq_num IS NOT NULL   THEN
                      bcd.seq_num + in_days
                    WHEN bcd.seq_num IS NULL
                     AND in_days > 0               THEN
                      bcd.prior_seq_num + in_days
                    WHEN bcd.seq_num IS NULL
                     AND in_days < 0               THEN
                      bcd.next_seq_num + in_days
                    WHEN bcd.seq_num IS NULL
                     AND in_days = 0
                     AND in_proc_type = 1          THEN
                      bcd.prior_seq_num
                    WHEN bcd.seq_num IS NULL
                     AND in_days = 0
                     AND in_proc_type = 2          THEN
                      bcd.next_seq_num
                  END                   AS seq_num
            FROM bom_calendar_dates bcd
            WHERE bcd.calendar_code  = gt_calendar_code
              AND bcd.calendar_date  = id_proc_date
         )                      bcd1
       , bom_calendar_dates     bcd2
    WHERE bcd2.calendar_code  = gt_calendar_code
      AND bcd2.seq_num        = bcd1.seq_num
    ;
    RETURN lt_calendar_date;
--
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(
        -20000, cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM
      );
--
  END get_operating_day_f;
--
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD START
  /**********************************************************************************
   * Procedure Name   : get_tax_rate
   * Description      : ����ŃR�[�h�E�ŗ��擾
   ***********************************************************************************/
  PROCEDURE get_tax_rate(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , it_tax_div                     IN  xxcmm_cust_accounts.tax_div%TYPE  -- ����ŋ敪
  , id_target_date                 IN  DATE                              -- ���
  , ot_tax_code                    OUT ar_vat_tax_b.tax_code%TYPE        -- �ŋ��R�[�h
  , ot_tax_rate                    OUT ar_vat_tax_b.tax_rate%TYPE        -- �ŗ�
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_tax_rate';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lt_tax_code                    ar_vat_tax_b.tax_code%TYPE DEFAULT NULL;     -- �ŋ��R�[�h
    lt_tax_rate                    ar_vat_tax_b.tax_rate%TYPE DEFAULT NULL;     -- �ŗ�
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ����ŃR�[�h�E�ŗ��擾
    --==================================================
    SELECT xtv.tax_code       AS tax_code
         , xtv.tax_rate       AS tax_rate
    INTO lt_tax_code
       , lt_tax_rate
    FROM xxcos_tax_v     xtv
    WHERE xtv.set_of_books_id      = gn_set_of_books_id
      AND xtv.tax_class            = it_tax_div
      AND id_target_date     BETWEEN NVL( xtv.start_date_active, id_target_date )
                                 AND NVL( xtv.end_date_active  , id_target_date )
    ;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf    := NULL;
    ov_errmsg    := NULL;
    ov_retcode   := lv_end_retcode;
    ot_tax_code  := lt_tax_code;
    ot_tax_rate  := lt_tax_rate;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00104
                    , iv_token_name1          => cv_tkn_tax_div
                    , iv_token_value1         => it_tax_div
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tax_rate;
--
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD END
  /**********************************************************************************
   * Procedure Name   : update_xcbi
   * Description      : �̎�v�Z�όڋq���f�[�^�̍X�V(A-15)
   ***********************************************************************************/
  PROCEDURE update_xcbi(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xcbi';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- �G���[�����O�o�͗p�ޔ�ϐ�
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--    lt_ship_cust_code              xxcok_tmp_014a01c_custdata.ship_cust_code%TYPE DEFAULT NULL;
    lt_ship_cust_code              xxcok_wk_014a01c_custdata.ship_cust_code%TYPE DEFAULT NULL;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbi_update_lock_cur
    IS
      SELECT xcbi.cust_bm_info_id       AS cust_bm_info_id            -- �̎�v�Z�όڋq���ID
           , xt0c.ship_cust_code        AS ship_cust_code             -- �ڋq�R�[�h
           , xt0c.calc_target_period_to AS calc_target_period_to      -- ���ߓ�
           , ( SELECT COUNT( 'X' )
               FROM xxcok_bm_contract_err xbce
               WHERE xbce.cust_code = xt0c.ship_cust_code
                 AND ROWNUM = 1
             )                          AS error_count                -- �̎�����G���[�`�F�b�N
      FROM xxcok_cust_bm_info           xcbi               -- �̎�̋��v�Z�όڋq���e�[�u��
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--         , xxcok_tmp_014a01c_custdata   xt0c               -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
         , xxcok_wk_014a01c_custdata   xt0c                -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
      WHERE xcbi.cust_code(+)           = xt0c.ship_cust_code
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
        AND xt0c.proc_type              = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
        AND xt0c.amount_fix_date        = gd_process_date
      FOR UPDATE OF xcbi.cust_bm_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�̋��v�Z�όڋq���f�[�^�X�V���[�v
    --==================================================
    << xcbi_update_lock_loop >>
    FOR xcbi_update_lock_rec IN xcbi_update_lock_cur LOOP
      lt_ship_cust_code := xcbi_update_lock_rec.ship_cust_code;
      --==================================================
      -- �̎�̋��v�Z�όڋq���f�[�^�X�V
      --==================================================
      IF( xcbi_update_lock_rec.cust_bm_info_id IS NOT NULL ) THEN
        UPDATE xxcok_cust_bm_info       xcbi
        SET xcbi.last_fix_closing_date  = xcbi_update_lock_rec.calc_target_period_to
          , xcbi.last_fix_delivery_date = CASE
                                            WHEN xcbi_update_lock_rec.error_count = 0 THEN
                                              ADD_MONTHS( TRUNC( xcbi_update_lock_rec.calc_target_period_to, 'MM' ), -1 )
                                            ELSE
                                              xcbi.last_fix_delivery_date
                                          END
          , xcbi.last_updated_by        = cn_last_updated_by
          , xcbi.last_update_date       = SYSDATE
          , xcbi.last_update_login      = cn_last_update_login
          , xcbi.request_id             = cn_request_id
          , xcbi.program_application_id = cn_program_application_id
          , xcbi.program_id             = cn_program_id
          , xcbi.program_update_date    = SYSDATE
        WHERE xcbi.cust_bm_info_id      = xcbi_update_lock_rec.cust_bm_info_id
        ;
      --==================================================
      --�̎�̋��v�Z�όڋq���f�[�^�o�^
      --==================================================
      ELSE
        INSERT INTO xxcok_cust_bm_info(
          cust_bm_info_id                                   -- �̎�v�Z�όڋq���ID
        , cust_code                                         -- �ڋq�R�[�h
        , last_fix_closing_date                             -- �ŏI�m����ߓ�
        , last_fix_delivery_date                            -- �ŏI�m��[�i��
        , created_by                                        -- �쐬��
        , creation_date                                     -- �쐬��
        , last_updated_by                                   -- �ŏI�X�V��
        , last_update_date                                  -- �ŏI�X�V��
        , last_update_login                                 -- �ŏI�X�V���O�C��
        , request_id                                        -- �v��ID
        , program_application_id                            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                                        -- �R���J�����g�E�v���O����ID
        , program_update_date                               -- �v���O�����X�V��
        )
        VALUES(
          xxcok_cust_bm_info_s01.NEXTVAL                    -- cust_bm_info_id
        , xcbi_update_lock_rec.ship_cust_code               -- cust_code
        , xcbi_update_lock_rec.calc_target_period_to        -- last_fix_closing_date
        , CASE
            WHEN xcbi_update_lock_rec.error_count = 0 THEN
              ADD_MONTHS( TRUNC( xcbi_update_lock_rec.calc_target_period_to, 'MM' ), -1 )
            ELSE
              NULL
          END                                               -- last_fix_delivery_date
        , cn_created_by                                     -- created_by
        , SYSDATE                                           -- creation_date
        , cn_last_updated_by                                -- last_updated_by
        , SYSDATE                                           -- last_update_date
        , cn_last_update_login                              -- last_update_login
        , cn_request_id                                     -- request_id
        , cn_program_application_id                         -- program_application_id
        , cn_program_id                                     -- program_id
        , SYSDATE                                           -- program_update_date
        );
      END IF;
    END LOOP xcbi_update_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00103
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xcbi;
--
  /**********************************************************************************
   * Procedure Name   : update_xsel
   * Description      : �̔����јA�g���ʂ̍X�V(A-12)
   ***********************************************************************************/
  PROCEDURE update_xsel(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'update_xsel';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- �G���[�����O�o�͗p�ޔ�ϐ�
    lt_sales_exp_line_id           xxcos_sales_exp_lines.sales_exp_line_id%TYPE DEFAULT NULL;
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xsel_update_lock_cur
    IS
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--      SELECT xsel.sales_exp_line_id    AS sales_exp_line_id    -- �̔����і���ID
      SELECT /*+
               LEADING(xt0c xcbi)
               USE_NL(xt0c xcbi xseh xsel)
               INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
             */
             xsel.sales_exp_line_id    AS sales_exp_line_id    -- �̔����і���ID
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--      FROM xxcok_tmp_014a01c_custdata xt0c            -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
      FROM xxcok_wk_014a01c_custdata xt0c             -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
         , xxcos_sales_exp_headers    xseh            -- �̔����уw�b�_�[�e�[�u��
         , xxcos_sales_exp_lines      xsel            -- �̔����і��׃e�[�u��
         , xxcok_cust_bm_info         xcbi
      WHERE xseh.ship_to_customer_code   = xt0c.ship_cust_code
        AND xseh.delivery_date          <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
        AND xseh.business_date          <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
        AND xt0c.amount_fix_date         = gd_process_date
        AND xt0c.ship_cust_code          = xcbi.cust_code(+)
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
        AND xt0c.proc_type               = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
        AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
        AND xseh.sales_exp_header_id     = xsel.sales_exp_header_id
        AND xsel.to_calculate_fees_flag  = cv_xsel_if_flag_no
        AND NOT EXISTS ( SELECT 'X'
                         FROM xxcok_bm_contract_err xbce
                         WHERE xbce.cust_code           = xseh.ship_to_customer_code
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki MOD START
--                           AND xbce.item_code           = xsel.item_code
--                           AND xbce.selling_price       = xsel.dlv_unit_price
                           AND NVL ( xbce.item_code, xsel.item_code )           = xsel.item_code
                           AND NVL ( xbce.selling_price,xsel. dlv_unit_price)   = xsel.dlv_unit_price
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki MOD END
                           AND ROWNUM = 1
            )
      FOR UPDATE OF xsel.sales_exp_line_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
-- 2010/05/26 Ver.3.11 [E_�{�ғ�_02855] SCS K.Yamaguchi REPAIR START
--    --==================================================
--    -- �̔����јA�g���ʍX�V���[�v
--    --==================================================
--    << xsel_update_lock_loop >>
--    FOR xsel_update_lock_rec IN xsel_update_lock_cur LOOP
--      lt_sales_exp_line_id := xsel_update_lock_rec.sales_exp_line_id;
--      --==================================================
--      -- �̔����јA�g���ʃf�[�^�X�V
--      --==================================================
--      UPDATE xxcos_sales_exp_lines      xsel
--      SET xsel.to_calculate_fees_flag = cv_xsel_if_flag_yes   -- �萔���v�Z�C���^�[�t�F�[�X�σt���O
--        , xsel.last_updated_by        = cn_last_updated_by
--        , xsel.last_update_date       = SYSDATE
--        , xsel.last_update_login      = cn_last_update_login
--        , xsel.request_id             = cn_request_id
--        , xsel.program_application_id = cn_program_application_id
--        , xsel.program_id             = cn_program_id
--        , xsel.program_update_date    = SYSDATE
--      WHERE xsel.sales_exp_line_id = xsel_update_lock_rec.sales_exp_line_id
--      ;
--    END LOOP xsel_update_lock_loop;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    --�v���t�@�C���uXXCOK1:�̎�̋�_�̔����і��׃��b�N�v��'N'�ȊO�̂Ƃ����b�N���擾
    IF ( gv_xsel_data_lock <> cv_disable ) THEN
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      --==================================================
      -- �̔����у��b�N�擾
      --==================================================
      OPEN  xsel_update_lock_cur;
      CLOSE xsel_update_lock_cur;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    END IF;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �̔����јA�g���ʃf�[�^�X�V
    --==================================================
    UPDATE xxcos_sales_exp_lines      xsel
    SET xsel.to_calculate_fees_flag = cv_xsel_if_flag_yes   -- �萔���v�Z�C���^�[�t�F�[�X�σt���O
      , xsel.last_updated_by        = cn_last_updated_by
      , xsel.last_update_date       = SYSDATE
      , xsel.last_update_login      = cn_last_update_login
      , xsel.request_id             = cn_request_id
      , xsel.program_application_id = cn_program_application_id
      , xsel.program_id             = cn_program_id
      , xsel.program_update_date    = SYSDATE
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR START
--    WHERE EXISTS ( SELECT 'X'
    WHERE EXISTS ( SELECT /*+
                            LEADING(xt0c xcbi)
                            USE_NL(xt0c xcbi xseh xsel2) 
                            INDEX(xseh XXCOS_SALES_EXP_HEADERS_N08)
                          */
                          'X'
-- 2012/10/01 Ver.3.16 [E_�{�ғ�_10133] SCSK K.Kiriu REPAIR END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--                   FROM xxcok_tmp_014a01c_custdata xt0c            -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
                   FROM xxcok_wk_014a01c_custdata xt0c             -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
                      , xxcos_sales_exp_headers    xseh            -- �̔����уw�b�_�[�e�[�u��
                      , xxcos_sales_exp_lines      xsel2           -- �̔����і��׃e�[�u��
                      , xxcok_cust_bm_info         xcbi
                   WHERE xseh.ship_to_customer_code   = xt0c.ship_cust_code
                     AND xseh.delivery_date          <= xt0c.closing_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD START
                     AND xseh.business_date          <= gd_process_date
-- 2010/12/13 Ver.3.12 [E_�{�ғ�_01844] SCS S.Niki ADD END
                     AND xt0c.amount_fix_date         = gd_process_date
                     AND xt0c.ship_cust_code          = xcbi.cust_code(+)
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
                     AND xt0c.proc_type               = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
                     AND xseh.delivery_date          >= NVL( xcbi.last_fix_delivery_date, xseh.delivery_date )
                     AND xseh.sales_exp_header_id     = xsel2.sales_exp_header_id
                     AND xsel2.to_calculate_fees_flag = cv_xsel_if_flag_no
                     AND NOT EXISTS ( SELECT 'X'
                                      FROM xxcok_bm_contract_err xbce
                                      WHERE xbce.cust_code           = xseh.ship_to_customer_code
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki MOD START
--                                        AND xbce.item_code           = xsel2.item_code
--                                        AND xbce.selling_price       = xsel2.dlv_unit_price
                                          AND NVL ( xbce.item_code, xsel2.item_code )           = xsel2.item_code
                                          AND NVL ( xbce.selling_price, xsel2.dlv_unit_price )  = xsel2.dlv_unit_price
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki MOD END
                                        AND ROWNUM = 1
                         )
                     AND xsel2.sales_exp_line_id = xsel.sales_exp_line_id
          )
    ;
-- 2010/05/26 Ver.3.11 [E_�{�ғ�_02855] SCS K.Yamaguchi REPAIR END
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    -- �����J�E���g
    gn_target_cnt      := SQL%ROWCOUNT;
    gn_update_xsel_cnt := SQL%ROWCOUNT;
    gn_normal_cnt      := SQL%ROWCOUNT;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00081
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_xsel;
--
  /**********************************************************************************
   * Procedure Name   : insert_xbce
   * Description      : �̎�����G���[�e�[�u���ւ̓o�^(A-11)
   ***********************************************************************************/
  PROCEDURE insert_xbce(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_sales_data_rec           IN  get_sales_data_rtype  -- �̔����я�񃌃R�[�h
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbce';      -- �v���O������
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    lv_bm_contract_err             CONSTANT VARCHAR2(4)  := '1'          ;      -- 1:�̎�}�X�^
    lv_bm_vendor_err               CONSTANT VARCHAR2(4)  := '2'          ;      -- 2:BM�x����s��
    lv_err_counted_flg_on          CONSTANT VARCHAR2(1)  := '0'          ;      -- 0:���o�^
    lv_err_counted_flg_off         CONSTANT VARCHAR2(1)  := '1'          ;      -- 0:�o�^��
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    ln_err_dup_cnt                 NUMBER         DEFAULT 0;                    -- �d����_�~�[�o�^�ό���
    lv_err_counted_flg             VARCHAR2(1)    DEFAULT NULL;                 -- �o�^�σG���[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�����G���[�e�[�u���ւ̓o�^
    --==================================================
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  -- �o�^�σG���[�t���O������
    lv_err_counted_flg := lv_err_counted_flg_off;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    IF( i_get_sales_data_rec.calc_type IS NULL ) THEN
      INSERT INTO xxcok_bm_contract_err (
        base_code              -- ���_�R�[�h
      , cust_code              -- �ڋq�R�[�h
      , item_code              -- �i�ڃR�[�h
      , container_type_code    -- �e��敪�R�[�h
      , selling_price          -- ����
      , selling_amt_tax        -- ������z(�ō�)
      , closing_date           -- ���ߓ�
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki MOD START
      , err_kbn                -- �G���[�敪
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki MOD END
      , created_by             -- �쐬��
      , creation_date          -- �쐬��
      , last_updated_by        -- �ŏI�X�V��
      , last_update_date       -- �ŏI�X�V��
      , last_update_login      -- �ŏI�X�V���O�C��
      , request_id             -- �v��ID
      , program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id             -- �R���J�����g�E�v���O����ID
      , program_update_date    -- �v���O�����X�V��
      )
      VALUES (
        i_get_sales_data_rec.base_code           -- ���_�R�[�h
      , i_get_sales_data_rec.ship_cust_code      -- �ڋq�R�[�h
      , i_get_sales_data_rec.item_code           -- �i�ڃR�[�h
      , i_get_sales_data_rec.container_code      -- �e��敪�R�[�h
      , i_get_sales_data_rec.dlv_unit_price      -- ����
      , i_get_sales_data_rec.amount_inc_tax      -- ������z(�ō�)
      , i_get_sales_data_rec.closing_date        -- ���ߓ�
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , lv_bm_contract_err                       -- �G���[�敪
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      , cn_created_by                            -- �쐬��
      , SYSDATE                                  -- �쐬��
      , cn_last_updated_by                       -- �ŏI�X�V��
      , SYSDATE                                  -- �ŏI�X�V��
      , cn_last_update_login                     -- �ŏI�X�V���O�C��
      , cn_request_id                            -- �v��ID
      , cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                            -- �R���J�����g�E�v���O����ID
      , SYSDATE                                  -- �v���O�����X�V��
      );
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      -- �����J�E���g
      gn_target_cnt      := gn_target_cnt + 1;
      gn_error_cnt       := gn_error_cnt + 1;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      gn_contract_err_cnt := gn_contract_err_cnt + 1;
      lv_end_retcode := cv_status_warn;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  -- �o�^�σG���[�t���O�ݒ�
      lv_err_counted_flg := lv_err_counted_flg_on;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    END IF;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    --==================================================
    -- �d����_�~�[�̏ꍇ�G���[�o�^�ς݂��̊m�F
    --==================================================
  -- �d����_�~�[�o�^�ό���������
    ln_err_dup_cnt := 0;
  -- �d����_�~�[�����擾
    SELECT COUNT(base_code)  err_dup_cnt
    INTO   ln_err_dup_cnt
    FROM   xxcok_bm_contract_err       xbce
    WHERE  i_get_sales_data_rec.base_code         = xbce.base_code
    AND    i_get_sales_data_rec.ship_cust_code    = xbce.cust_code
    AND    i_get_sales_data_rec.closing_date      = closing_date
    AND    xbce.err_kbn = lv_bm_vendor_err
    AND    i_get_sales_data_rec.vendor_dummy_flag = cv_vendor_dummy_on
    ;
    --==================================================
    -- �̎�����G���[�e�[�u���ւ̓o�^�i2:BM�x����s���j
    --==================================================
    IF ( NVL( i_get_sales_data_rec.vendor_dummy_flag ,cv_vendor_dummy_off )  = cv_vendor_dummy_on
        AND (ln_err_dup_cnt = 0 )
       ) THEN
      INSERT INTO xxcok_bm_contract_err (
        base_code              -- ���_�R�[�h
      , cust_code              -- �ڋq�R�[�h
      , item_code              -- �i�ڃR�[�h
      , container_type_code    -- �e��敪�R�[�h
      , selling_price          -- ����
      , selling_amt_tax        -- ������z(�ō�)
      , closing_date           -- ���ߓ�
      , err_kbn                -- �G���[�敪
      , created_by             -- �쐬��
      , creation_date          -- �쐬��
      , last_updated_by        -- �ŏI�X�V��
      , last_update_date       -- �ŏI�X�V��
      , last_update_login      -- �ŏI�X�V���O�C��
      , request_id             -- �v��ID
      , program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , program_id             -- �R���J�����g�E�v���O����ID
      , program_update_date    -- �v���O�����X�V��
      )
      VALUES (
        i_get_sales_data_rec.base_code           -- ���_�R�[�h
      , i_get_sales_data_rec.ship_cust_code      -- �ڋq�R�[�h
      , NULL                                     -- �i�ڃR�[�h
      , NULL                                     -- �e��敪�R�[�h
      , NULL                                     -- ����
      , NULL                                     -- ������z(�ō�)
      , i_get_sales_data_rec.closing_date        -- ���ߓ�
      , lv_bm_vendor_err                         -- �G���[�敪
      , cn_created_by                            -- �쐬��
      , SYSDATE                                  -- �쐬��
      , cn_last_updated_by                       -- �ŏI�X�V��
      , SYSDATE                                  -- �ŏI�X�V��
      , cn_last_update_login                     -- �ŏI�X�V���O�C��
      , cn_request_id                            -- �v��ID
      , cn_program_application_id                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      , cn_program_id                            -- �R���J�����g�E�v���O����ID
      , SYSDATE                                  -- �v���O�����X�V��
      );
      gn_error_cnt       := gn_error_cnt + 1;
      gn_vendor_err_cnt  := gn_vendor_err_cnt + 1;
      lv_end_retcode := cv_status_warn;
    END IF;
    -- �Ώی����J�E���g
    IF ( NVL( i_get_sales_data_rec.vendor_dummy_flag ,cv_vendor_dummy_off )  = cv_vendor_dummy_on
        AND (lv_err_counted_flg = lv_err_counted_flg_off )
       ) THEN
      gn_target_cnt      := gn_target_cnt + 1;
    END IF;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbce;
--
  /**********************************************************************************
   * Procedure Name   : insert_xcbs
   * Description      : �����ʔ̎�̋��e�[�u���ւ̓o�^(A-10)
   ***********************************************************************************/
  PROCEDURE insert_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_sales_data_rec           IN  get_sales_data_rtype      -- �̔����я�񃌃R�[�h
  , i_xcbs_data_tab                IN  xcbs_data_ttype           -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  , i_vendor_dummy_flag_tab        IN  vendor_dummy_flag_ttype   -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xcbs';      -- �v���O������
    cn_index_1                     CONSTANT NUMBER       := 1;                  -- BM1_����
    cn_index_2                     CONSTANT NUMBER       := 2;                  -- BM2_����
    cn_index_3                     CONSTANT NUMBER       := 3;                  -- BM3_����
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_fix_status                  xxcok_cond_bm_support.amt_fix_status%TYPE;   -- ���z�m��X�e�[�^�X
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ���z�m��X�e�[�^�X����
    --==================================================
    IF( i_get_sales_data_rec.amount_fix_date = gd_process_date ) THEN
      lv_fix_status := cv_xcbs_fix;
    ELSE
      lv_fix_status := cv_xcbs_temp;
    END IF;
    --==================================================
    -- ���[�v������BM1����BM3�܂ł�3���R�[�h��o�^
    --==================================================
    << insert_xcbs_loop >>
    FOR i IN cn_index_1 .. cn_index_3 LOOP
      --==================================================
      -- �o�^�����m�F
      --==================================================
      IF(     ( i_xcbs_data_tab( i ).supplier_code IS NOT NULL )
          AND (    ( i_xcbs_data_tab( i ).cond_bm_amt_tax       IS NOT NULL ) -- VDBM(�ō�)
                OR ( i_xcbs_data_tab( i ).electric_amt_tax      IS NOT NULL ) -- �d�C��(�ō�)
                OR ( i_xcbs_data_tab( i ).csh_rcpt_discount_amt IS NOT NULL ) -- �����l���z
              )
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
          AND ( NVL( i_vendor_dummy_flag_tab( i ), cv_vendor_dummy_off )  = cv_vendor_dummy_off )
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      ) THEN
        --==================================================
        -- �����ʔ̎�̋��v�Z���ʂ������ʔ̎�̋��e�[�u���ɓo�^
        --==================================================
        INSERT INTO xxcok_cond_bm_support (
          cond_bm_support_id        -- �����ʔ̎�̋�ID
        , base_code                 -- ���_�R�[�h
        , emp_code                  -- �S���҃R�[�h
        , delivery_cust_code        -- �ڋq�y�[�i��z
        , demand_to_cust_code       -- �ڋq�y������z
        , acctg_year                -- ��v�N�x
        , chain_store_code          -- �`�F�[���X�R�[�h
        , supplier_code             -- �d����R�[�h
        , supplier_site_code        -- �d����T�C�g�R�[�h
        , calc_type                 -- �v�Z����
        , delivery_date             -- �[�i���N��
        , delivery_qty              -- �[�i����
        , delivery_unit_type        -- �[�i�P��
        , selling_amt_tax           -- ������z(�ō�)
-- Ver.3.20 N.Abe ADD START
        , selling_amt_no_tax        -- ������z(�Ŕ�)
-- Ver.3.20 N.Abe ADD END
        , rebate_rate               -- ���ߗ�
        , rebate_amt                -- ���ߊz
        , container_type_code       -- �e��敪�R�[�h
        , selling_price             -- �������z
        , cond_bm_amt_tax           -- �����ʎ萔���z(�ō�)
        , cond_bm_amt_no_tax        -- �����ʎ萔���z(�Ŕ�)
        , cond_tax_amt              -- �����ʏ���Ŋz
        , electric_amt_tax          -- �d�C��(�ō�)
        , electric_amt_no_tax       -- �d�C��(�Ŕ�)
        , electric_tax_amt          -- �d�C������Ŋz
        , csh_rcpt_discount_amt     -- �����l���z
        , csh_rcpt_discount_amt_tax -- �����l������Ŋz
        , consumption_tax_class     -- ����ŋ敪
        , tax_code                  -- �ŋ��R�[�h
        , tax_rate                  -- ����ŗ�
        , term_code                 -- �x������
        , closing_date              -- ���ߓ�
        , expect_payment_date       -- �x���\���
        , calc_target_period_from   -- �v�Z�Ώۊ���(FROM)
        , calc_target_period_to     -- �v�Z�Ώۊ���(TO)
        , cond_bm_interface_status  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
        , cond_bm_interface_date    -- �A�g��(�����ʔ̎�̋�)
        , bm_interface_status       -- �A�g�X�e�[�^�X(�̎�c��)
        , bm_interface_date         -- �A�g��(�̎�c��)
        , ar_interface_status       -- �A�g�X�e�[�^�X(AR)
        , ar_interface_date         -- �A�g��(AR)
        , amt_fix_status            -- ���z�m��X�e�[�^�X
        , created_by                -- �쐬��
        , creation_date             -- �쐬��
        , last_updated_by           -- �ŏI�X�V��
        , last_update_date          -- �ŏI�X�V��
        , last_update_login         -- �ŏI�X�V���O�C��
        , request_id                -- �v��ID
        , program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                -- �R���J�����g�E�v���O����ID
        , program_update_date       -- �v���O�����X�V��
        )
        VALUES (
          xxcok_cond_bm_support_s01.NEXTVAL                   -- �����ʔ̎�̋�ID
        , i_xcbs_data_tab( i ).base_code                 -- ���_�R�[�h
        , i_xcbs_data_tab( i ).emp_code                  -- �S���҃R�[�h
        , i_xcbs_data_tab( i ).delivery_cust_code        -- �ڋq�y�[�i��z
        , i_xcbs_data_tab( i ).demand_to_cust_code       -- �ڋq�y������z
        , i_xcbs_data_tab( i ).acctg_year                -- ��v�N�x
        , i_xcbs_data_tab( i ).chain_store_code          -- �`�F�[���X�R�[�h
        , i_xcbs_data_tab( i ).supplier_code             -- �d����R�[�h
        , i_xcbs_data_tab( i ).supplier_site_code        -- �d����T�C�g�R�[�h
        , i_xcbs_data_tab( i ).calc_type                 -- �v�Z����
        , i_xcbs_data_tab( i ).delivery_date             -- �[�i���N��
        , i_xcbs_data_tab( i ).delivery_qty              -- �[�i����
        , i_xcbs_data_tab( i ).delivery_unit_type        -- �[�i�P��
        , i_xcbs_data_tab( i ).selling_amt_tax           -- ������z(�ō�)
-- Ver.3.20 N.Abe ADD START
        , i_xcbs_data_tab( i ).selling_amt_no_tax        -- ������z(�ō�)
-- Ver.3.20 N.Abe ADD END
        , i_xcbs_data_tab( i ).rebate_rate               -- ���ߗ�
        , i_xcbs_data_tab( i ).rebate_amt                -- ���ߊz
        , i_xcbs_data_tab( i ).container_type_code       -- �e��敪�R�[�h
        , i_xcbs_data_tab( i ).selling_price             -- �������z
        , i_xcbs_data_tab( i ).cond_bm_amt_tax           -- �����ʎ萔���z(�ō�)
        , i_xcbs_data_tab( i ).cond_bm_amt_no_tax        -- �����ʎ萔���z(�Ŕ�)
        , i_xcbs_data_tab( i ).cond_tax_amt              -- �����ʏ���Ŋz
        , i_xcbs_data_tab( i ).electric_amt_tax          -- �d�C��(�ō�)
        , i_xcbs_data_tab( i ).electric_amt_no_tax       -- �d�C��(�Ŕ�)
        , i_xcbs_data_tab( i ).electric_tax_amt          -- �d�C������Ŋz
        , i_xcbs_data_tab( i ).csh_rcpt_discount_amt     -- �����l���z
        , i_xcbs_data_tab( i ).csh_rcpt_discount_amt_tax -- �����l������Ŋz
        , i_xcbs_data_tab( i ).consumption_tax_class     -- ����ŋ敪
        , i_xcbs_data_tab( i ).tax_code                  -- �ŋ��R�[�h
        , i_xcbs_data_tab( i ).tax_rate                  -- ����ŗ�
        , i_xcbs_data_tab( i ).term_code                 -- �x������
        , i_xcbs_data_tab( i ).closing_date              -- ���ߓ�
        , i_xcbs_data_tab( i ).expect_payment_date       -- �x���\���
        , i_xcbs_data_tab( i ).calc_target_period_from   -- �v�Z�Ώۊ���(FROM)
        , i_xcbs_data_tab( i ).calc_target_period_to     -- �v�Z�Ώۊ���(TO)
        , i_xcbs_data_tab( i ).cond_bm_interface_status  -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
        , i_xcbs_data_tab( i ).cond_bm_interface_date    -- �A�g��(�����ʔ̎�̋�)
        , i_xcbs_data_tab( i ).bm_interface_status       -- �A�g�X�e�[�^�X(�̎�c��)
        , i_xcbs_data_tab( i ).bm_interface_date         -- �A�g��(�̎�c��)
        , i_xcbs_data_tab( i ).ar_interface_status       -- �A�g�X�e�[�^�X(AR)
        , i_xcbs_data_tab( i ).ar_interface_date         -- �A�g��(AR)
        , lv_fix_status                                  -- ���z�m��X�e�[�^�X
        , cn_created_by                                       -- �쐬��
        , SYSDATE                                             -- �쐬��
        , cn_last_updated_by                                  -- �ŏI�X�V��
        , SYSDATE                                             -- �ŏI�X�V��
        , cn_last_update_login                                -- �ŏI�X�V���O�C��
        , cn_request_id                                       -- �v��ID
        , cn_program_application_id                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , cn_program_id                                       -- �R���J�����g�E�v���O����ID
        , SYSDATE                                             -- �v���O�����X�V��
        );
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      -- �����J�E���g
      gn_insert_xcbs_cnt := gn_insert_xcbs_cnt + 1;
      gn_target_cnt      := gn_target_cnt + 1;
      gn_normal_cnt      := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      END IF;
    END LOOP insert_xcbs_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END insert_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : set_xcbs_data
   * Description      : �����ʔ̎�̋����̐ݒ�(A-9)
   ***********************************************************************************/
  PROCEDURE set_xcbs_data(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_sales_data_rec           IN  get_sales_data_rtype  -- �̔����я�񃌃R�[�h
  , o_xcbs_data_tab                OUT xcbs_data_ttype       -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
  , o_vendor_dummy_flag_tab        OUT vendor_dummy_flag_ttype --�d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'set_xcbs_data';    -- �v���O������
    cn_index_1                     CONSTANT NUMBER       := 1;                  -- BM1_����
    cn_index_2                     CONSTANT NUMBER       := 2;                  -- BM2_����
    cn_index_3                     CONSTANT NUMBER       := 3;                  -- BM3_����
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
    ln_bm1_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM1_�����l���z(�Ŕ�)_�ꎞ�i�[
    ln_bm2_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM2_�����l���z(�Ŕ�)_�ꎞ�i�[
    ln_bm3_rcpt_discount_amt_notax NUMBER         DEFAULT NULL;                 -- BM3_�����l���z(�Ŕ�)_�ꎞ�i�[
--
-- Ver.3.20 N.Abe ADD START
    ln_bm1_amt_tax                 NUMBER         DEFAULT NULL;                 -- �yBM1�zVDBM(�ō�)_�ꎞ�i�[
    ln_bm2_amt_tax                 NUMBER         DEFAULT NULL;                 -- �yBM2�zVDBM(�ō�)_�ꎞ�i�[
    ln_bm3_amt_tax                 NUMBER         DEFAULT NULL;                 -- �yBM3�zVDBM(�ō�)_�ꎞ�i�[
    ln_bm1_amt_no_tax              NUMBER         DEFAULT NULL;                 -- �yBM1�zVDBM(�Ŕ�)_�ꎞ�i�[
    ln_bm2_amt_no_tax              NUMBER         DEFAULT NULL;                 -- �yBM2�zVDBM(�Ŕ�)_�ꎞ�i�[
    ln_bm3_amt_no_tax              NUMBER         DEFAULT NULL;                 -- �yBM3�zVDBM(�Ŕ�)_�ꎞ�i�[
    ln_bm1_elect_amt_tax           NUMBER         DEFAULT NULL;                 -- �yBM1�z�d�C��(�ō�)_�ꎞ�i�[
    ln_bm1_elect_amt_no_tax        NUMBER         DEFAULT NULL;                 -- �yBM1�z�d�C��(�Ŕ�)_�ꎞ�i�[
-- Ver.3.20 N.Abe ADD END
--
    -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)_�ꎞ�i�[
    lv_cond_bm_interface_status    xxcok_cond_bm_support.cond_bm_interface_status%TYPE DEFAULT NULL;
    -- �A�g�X�e�[�^�X(�̎�c��)_�ꎞ�i�[
    lv_bm_interface_status         xxcok_cond_bm_support.bm_interface_status%TYPE      DEFAULT NULL;
    -- �A�g�X�e�[�^�X(AR)_�ꎞ�i�[
    lv_ar_interface_status         xxcok_cond_bm_support.ar_interface_status%TYPE      DEFAULT NULL;
--
    l_xcbs_data_tab                     xcbs_data_ttype;                             -- �����ʔ̎�̋��e�[�u���^�C�v
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab             vendor_dummy_flag_ttype;                     -- �d����_�~�[�t���O�^�C�v
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ������
    --==================================================
    l_xcbs_data_tab( cn_index_1 ) := NULL;
    l_xcbs_data_tab( cn_index_2 ) := NULL;
    l_xcbs_data_tab( cn_index_3 ) := NULL;
-- Ver.3.20 N.Abe ADD START
    --==================================================
    -- �d�C�����o���̒[�������i���o���ɒ������Ȃ����߁j
    -- �ō��ː؂�̂�
    -- �Ŕ��ː؂�グ
    --==================================================
    -- BM1�ŋ敪 = '1'�i�ō��j
    IF ( i_get_sales_data_rec.bm1_tax_kbn = '1' ) THEN 
      -- �yBM1�z�d�C��(�ō�)
      ln_bm1_elect_amt_tax      := TRUNC( i_get_sales_data_rec.bm1_electric_amt_tax );
    -- BM1�ŋ敪 = '2'�i�Ŕ��j
    ELSIF ( i_get_sales_data_rec.bm1_tax_kbn = '2' ) THEN
      -- �yBM1�z�d�C��(�Ŕ�)
      IF( i_get_sales_data_rec.bm1_electric_amt_no_tax >= 0 ) THEN
        ln_bm1_elect_amt_no_tax := CEIL( i_get_sales_data_rec.bm1_electric_amt_no_tax );
      ELSIF( i_get_sales_data_rec.bm1_electric_amt_no_tax < 0 ) THEN
        ln_bm1_elect_amt_no_tax := FLOOR( i_get_sales_data_rec.bm1_electric_amt_no_tax );
      END IF;
    END IF;
-- Ver.3.20 N.Abe ADD END
    --==================================================
    -- 1.�̔����я��̋Ƒ�(������)�� '25':�t���T�[�r�XVD�̏ꍇ�AVDBM(�ō�)��ݒ肵�܂��B
    --==================================================
    IF( i_get_sales_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      -- �̔����я��� BM1 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
-- Ver.3.20 N.Abe DEL START
--        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
-- Ver.3.20 N.Abe DEL END
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := NULL;
      -- �̔����я��� BM1 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
-- Ver.3.20 N.Abe DEL START
--        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
-- Ver.3.20 N.Abe DEL END
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
      -- �̔����я��� BM2 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
-- Ver.3.20 N.Abe DEL START
--        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
-- Ver.3.20 N.Abe DEL END
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := NULL;
      -- �̔����я��� BM2 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
-- Ver.3.20 N.Abe DEL START
--        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
-- Ver.3.20 N.Abe DEL END
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
      -- �̔����я��� BM3 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
-- Ver.3.20 N.Abe DEL START
--        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
-- Ver.3.20 N.Abe DEL END
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := NULL;
      -- �̔����я��� BM3 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
-- Ver.3.20 N.Abe DEL START
--        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
-- Ver.3.20 N.Abe DEL END
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := NULL;
      END IF;
--
-- Ver.3.20 N.Abe ADD START
      -- **************
      -- �ō���
      -- **************
      -- BM1�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm1_tax_kbn = '1' ) THEN
        -- �̔����я��� BM1 BM��(%)�� NULL�ȊO �̏ꍇ
        IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
          -- �yBM1�zVDBM(�ō�)
          ln_bm1_amt_tax      := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
          -- �yBM1�zVDBM(�Ŕ�)
          ln_bm1_amt_no_tax   := ln_bm1_amt_tax / ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        -- �̔����я��� BM1 BM���z�� NULL �ȊO�̏ꍇ
        ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
          -- �yBM1�zVDBM(�ō�)
          ln_bm1_amt_tax      := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
          -- �yBM1�zVDBM(�Ŕ�)
          ln_bm1_amt_no_tax   := ln_bm1_amt_tax / ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        END IF;
      END IF;
--
      -- BM2�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm2_tax_kbn = '1' ) THEN
        -- �̔����я��� BM2 BM��(%)�� NULL�ȊO �̏ꍇ
        IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
          -- �yBM2�zVDBM(�ō�)
          ln_bm2_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
          -- �yBM2�zVDBM(�Ŕ�)
          ln_bm2_amt_no_tax    := ln_bm2_amt_tax / ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        -- �̔����я��� BM2 BM���z�� NULL �ȊO�̏ꍇ
        ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
          -- �yBM2�zVDBM(�ō�)
          ln_bm2_amt_tax       := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
          -- �yBM2�zVDBM(�Ŕ�)
          ln_bm2_amt_no_tax    := ln_bm2_amt_tax / ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        END IF;
      END IF;
--
      -- BM3�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm3_tax_kbn = '1' ) THEN
        -- �̔����я��� BM3 BM��(%)�� NULL�ȊO �̏ꍇ
        IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
          -- �yBM3�zVDBM(�ō�)
          ln_bm3_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
          -- �yBM3�zVDBM(�Ŕ�)
          ln_bm3_amt_no_tax    := ln_bm3_amt_tax / ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        -- �̔����я��� BM3 BM���z�� NULL �ȊO�̏ꍇ
        ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
          -- �yBM3�zVDBM(�ō�)
          ln_bm3_amt_tax       := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
          -- �yBM3�zVDBM(�Ŕ�)
          ln_bm3_amt_no_tax    := ln_bm3_amt_tax / ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        END IF;
      END IF;
--
      -- **************
      -- �Ŕ����A��ې�
      -- **************
      -- BM1�ŋ敪 = '2'�i�Ŕ��j
      IF ( i_get_sales_data_rec.bm1_tax_kbn = '2' ) THEN
        -- �̔����я��� BM1 BM��(%)�� NULL�ȊO �̏ꍇ
        IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
          -- �yBM1�zVDBM(�Ŕ�)
          ln_bm1_amt_no_tax    := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
          -- �yBM1�zVDBM(�ō�)
          ln_bm1_amt_tax       := ln_bm1_amt_no_tax * ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        -- �̔����я��� BM1 BM���z�� NULL �ȊO�̏ꍇ
        ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
          -- �yBM1�zVDBM(�Ŕ�)
          ln_bm1_amt_no_tax    := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
          -- �yBM1�zVDBM(�ō�)
          ln_bm1_amt_tax       := ln_bm1_amt_no_tax * ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        END IF;
      END IF;
--
      -- BM2�ŋ敪 IN ( '2'�i�Ŕ��j�A'3'�i��ېŁj�j
      IF ( i_get_sales_data_rec.bm2_tax_kbn IN ( '2', '3' ) ) THEN
        -- �̔����я��� BM2 BM��(%)�� NULL�ȊO �̏ꍇ
        IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
          -- �yBM2�zVDBM(�Ŕ�)
          ln_bm2_amt_no_tax    := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
          -- �yBM2�zVDBM(�ō�)
          ln_bm2_amt_tax       := ln_bm2_amt_no_tax * ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        -- �̔����я��� BM2 BM���z�� NULL �ȊO�̏ꍇ
        ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
          -- �yBM2�zVDBM(�Ŕ�)
          ln_bm2_amt_no_tax    := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
          -- �yBM2�zVDBM(�ō�)
          ln_bm2_amt_tax       := ln_bm2_amt_no_tax * ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        END IF;
      END IF;
--
      -- BM3�ŋ敪 IN ( '2'�i�Ŕ��j�A'3'�i��ېŁj�j
      IF ( i_get_sales_data_rec.bm3_tax_kbn IN ( '2', '3' ) ) THEN
        -- �̔����я��� BM3 BM��(%)�� NULL�ȊO �̏ꍇ
        IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
          -- �yBM3�zVDBM(�Ŕ�)
          ln_bm3_amt_no_tax    := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
          -- �yBM3�zVDBM(�ō�)
          ln_bm3_amt_tax       := ln_bm3_amt_no_tax * ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        -- �̔����я��� BM3 BM���z�� NULL �ȊO�̏ꍇ
        ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
          -- �yBM3�zVDBM(�Ŕ�)
          ln_bm3_amt_no_tax    := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
          -- �yBM3�zVDBM(�ō�)
          ln_bm3_amt_tax       := ln_bm3_amt_no_tax * ( 1 + i_get_sales_data_rec.tax_rate / 100 );
        END IF;
      END IF;
-- Ver.3.20 N.Abe ADD END
    --==================================================
    -- 2.�̔����я��̋Ƒ�(������)�� '25':�t���T�[�r�XVD�ȊO�̏ꍇ�A�����l���z(�ō�)��ݒ肵�܂��B
    --==================================================
    ELSIF( i_get_sales_data_rec.ship_gyotai_sho <> cv_gyotai_sho_25 ) THEN
      -- �̔����я��� BM1 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm1_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm1_cond_bm_tax_pct;
      -- �̔����я��� BM1 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm1_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm1_cond_bm_amt_tax;
      END IF;
--
      -- �̔����я��� BM2 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm2_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm2_cond_bm_tax_pct;
      -- �̔����я��� BM2 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm2_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm2_cond_bm_amt_tax;
      END IF;
--
      -- �̔����я��� BM3 BM��(%)�� NULL�ȊO �̏ꍇ
      IF( i_get_sales_data_rec.bm3_pct IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm3_cond_bm_tax_pct;
      -- �̔����я��� BM3 BM���z�� NULL �ȊO�̏ꍇ
      ELSIF( i_get_sales_data_rec.bm3_amt IS NOT NULL ) THEN
        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax       := NULL;
        l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt := i_get_sales_data_rec.bm3_cond_bm_amt_tax;
      END IF;
    END IF;
    --==================================================
    -- 3.�eVDBM(�ō�)�A�����l���z(�ō�)�A�d�C���� NULL �ȊO�̏ꍇ�A�Ŕ����z����я���Ŋz���Z�o���܂��B
    --==================================================
-- Ver.3.20 N.Abe DEL START
--    -- BM1 VDBM(�Ŕ�)�̐ݒ�
--    IF( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax IS NOT NULL ) THEN
--      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax
--        := l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
--    END IF;
-- Ver.3.20 N.Abe DEL END
    -- BM1 �����l���z(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm1_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 )  );
    END IF;
-- Ver.3.20 N.Abe MOD START
    --BM1�ŋ敪 = '1'�i�ō��j
    IF ( i_get_sales_data_rec.bm1_tax_kbn = '1' ) THEN
      -- BM1 �d�C��(�Ŕ�)�̐ݒ�
      IF( ln_bm1_elect_amt_tax IS NOT NULL ) THEN
        ln_bm1_elect_amt_no_tax := ln_bm1_elect_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
      END IF;
    --BM1�ŋ敪 = '2'�i�Ŕ��j
    ELSIF ( i_get_sales_data_rec.bm1_tax_kbn = '2' ) THEN
      -- BM1 �d�C��(�ō�)�̐ݒ�
      IF( ln_bm1_elect_amt_no_tax IS NOT NULL ) THEN
        ln_bm1_elect_amt_tax    := ln_bm1_elect_amt_no_tax * ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
      END IF;
    END IF;
-- Ver.3.20 N.Abe MOD END
-- Ver.3.20 N.Abe DEL START
--    -- BM2 VDBM(�Ŕ�)�̐ݒ�
--    IF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax IS NOT NULL ) THEN
--      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax
--        := l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
--    END IF;
-- Ver.3.20 N.Abe DEL END
    -- BM2 �����l���z(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm2_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM2 �d�C��(�Ŕ�)�̐ݒ�
    IF( i_get_sales_data_rec.bm2_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm2_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
-- Ver.3.20 N.Abe DEL START
--    -- BM3 VDBM(�Ŕ�)�̐ݒ�
--    IF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax IS NOT NULL ) THEN
--      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax
--        := l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate/ 100 ) );
--    END IF;
-- Ver.3.20 N.Abe DEL END
    -- BM3 �����l���z(�Ŕ�)�̐ݒ�
    IF( l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt IS NOT NULL ) THEN
      ln_bm3_rcpt_discount_amt_notax
        := l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
    -- BM3 �d�C��(�Ŕ�)�̐ݒ�
    IF( i_get_sales_data_rec.bm3_electric_amt_tax IS NOT NULL ) THEN
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax
        := i_get_sales_data_rec.bm3_electric_amt_tax / ( 1 + ( i_get_sales_data_rec.tax_rate / 100 ) );
    END IF;
--
    --==================================================
    -- �[�������敪�ɂ��擾�l�̒[�������iBM�ŋ敪:�ō��j
    --==================================================
    -- �̔����я��̒[�������敪�� 'NEAREST':�l�̌ܓ��̏ꍇ�A�����_�ȉ��̒[�����l�̌ܓ����܂��B
    IF( i_get_sales_data_rec.tax_rounding_rule = cv_tax_rounding_rule_nearest ) THEN
-- Ver.3.20 N.Abe DEL START
--      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
-- Ver.3.20 N.Abe DEL END
      ln_bm1_rcpt_discount_amt_notax                    := ROUND( ln_bm1_rcpt_discount_amt_notax );
-- Ver.3.20 N.Abe DEL START
--      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
--      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
-- Ver.3.20 N.Abe DEL END
      ln_bm2_rcpt_discount_amt_notax                    := ROUND( ln_bm2_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
-- Ver.3.20 N.Abe DEL START
--      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := ROUND( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
-- Ver.3.20 N.Abe DEL END
      ln_bm3_rcpt_discount_amt_notax                    := ROUND( ln_bm3_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax := ROUND( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
--
-- Ver.3.20 N.Abe ADD START
      -- BM1�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm1_tax_kbn = '1' ) THEN
        ln_bm1_amt_no_tax       := ROUND( ln_bm1_amt_no_tax );        -- �yBM1�zVDBM(�Ŕ�)
        ln_bm1_elect_amt_no_tax := ROUND( ln_bm1_elect_amt_no_tax );  -- �yBM1�z�d�C��(�Ŕ�)
      END IF;
      -- BM2�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm2_tax_kbn = '1' ) THEN
        ln_bm2_amt_no_tax       := ROUND( ln_bm2_amt_no_tax );        -- �yBM2�zVDBM(�Ŕ�)
      END IF;
      -- BM3�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm3_tax_kbn = '1' ) THEN
        ln_bm3_amt_no_tax       := ROUND( ln_bm3_amt_no_tax );        -- �yBM3�zVDBM(�Ŕ�)
      END IF;
-- Ver.3.20 N.Abe ADD END
    -- �̔����я��̒[�������敪�� 'UP':�؂�グ�̏ꍇ�A�����_�ȉ��̒[����؂�グ���܂��B
    ELSIF ( i_get_sales_data_rec.tax_rounding_rule = cv_tax_rounding_rule_up ) THEN
-- Ver.3.20 N.Abe DEL START
--      IF( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax > 0 )    THEN
--        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
--      ELSIF ( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax < 0 ) THEN
--        l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
--      END IF;
-- Ver.3.20 N.Abe DEL END
      IF( ln_bm1_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm1_rcpt_discount_amt_notax  := CEIL( ln_bm1_rcpt_discount_amt_notax );
      ELSIF( ln_bm1_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm1_rcpt_discount_amt_notax  := FLOOR( ln_bm1_rcpt_discount_amt_notax );
      END IF;
-- Ver.3.20 N.Abe DEL START
--      IF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax > 0 )    THEN
--        l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
--      ELSIF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax < 0 ) THEN
--        l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
--      END IF;
--      IF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax > 0 )    THEN
--        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
--      ELSIF( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax < 0 ) THEN
--        l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
--      END IF;
-- Ver.3.20 N.Abe DEL END
      IF( ln_bm2_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm2_rcpt_discount_amt_notax  := CEIL( ln_bm2_rcpt_discount_amt_notax );
      ELSIF ( ln_bm2_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm2_rcpt_discount_amt_notax  := FLOOR( ln_bm2_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      ELSIF( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
      END IF;
-- Ver.3.20 N.Abe DEL START
--      IF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax > 0 )    THEN
--        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
--      ELSIF( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax < 0 ) THEN
--        l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
--      END IF;
-- Ver.3.20 N.Abe DEL END
      IF( ln_bm3_rcpt_discount_amt_notax > 0 )    THEN
        ln_bm3_rcpt_discount_amt_notax  := CEIL( ln_bm3_rcpt_discount_amt_notax );
      ELSIF( ln_bm3_rcpt_discount_amt_notax < 0 ) THEN
        ln_bm3_rcpt_discount_amt_notax  := FLOOR( ln_bm3_rcpt_discount_amt_notax );
      END IF;
      IF( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax > 0 )    THEN
        l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax  := CEIL( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
      ELSIF ( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax < 0 ) THEN
        l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax  := FLOOR( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
      END IF;
-- Ver.3.20 N.Abe ADD START
      -- BM1�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm1_tax_kbn = '1' ) THEN
        -- �yBM1�zVDBM(�Ŕ�)
        IF( ln_bm1_amt_no_tax >= 0 )    THEN
          ln_bm1_amt_no_tax  := CEIL( ln_bm1_amt_no_tax );
        ELSIF ( ln_bm1_amt_no_tax < 0 ) THEN
          ln_bm1_amt_no_tax  := FLOOR( ln_bm1_amt_no_tax );
        END IF;
        -- �yBM1�z�d�C��(�Ŕ�)
        IF( i_get_sales_data_rec.bm1_electric_amt_no_tax >= 0 )    THEN
          ln_bm1_elect_amt_no_tax  := CEIL( ln_bm1_elect_amt_no_tax );
        ELSIF( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax < 0 ) THEN
          ln_bm1_elect_amt_no_tax  := FLOOR( ln_bm1_elect_amt_no_tax );
        END IF;
      END IF;
--
      -- BM2�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm2_tax_kbn = '1' ) THEN
        -- �yBM2�zVDBM(�Ŕ�)
        IF( ln_bm2_amt_no_tax >= 0 )    THEN
          ln_bm2_amt_no_tax  := CEIL( ln_bm2_amt_no_tax );
        ELSIF( ln_bm2_amt_no_tax < 0 ) THEN
          ln_bm2_amt_no_tax  := FLOOR( ln_bm2_amt_no_tax );
        END IF;
      END IF;
--
      -- BM3�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm3_tax_kbn = '1' ) THEN
        -- �yBM3�zVDBM(�Ŕ�)
        IF( ln_bm3_amt_no_tax >= 0 )    THEN
          ln_bm3_amt_no_tax  := CEIL( ln_bm3_amt_no_tax );
        ELSIF( ln_bm3_amt_no_tax < 0 ) THEN
          ln_bm3_amt_no_tax  := FLOOR( ln_bm3_amt_no_tax );
        END IF;
      END IF;
-- Ver.3.20 N.Abe ADD END
    -- ��L�ȊO�̏ꍇ�A'DOWN':�؂�̂Ă��ݒ肳��Ă��邱�ƂƂ��A�����_�ȉ��̒[����؂�̂Ă��܂��B
    ELSE
-- Ver.3.20 N.Abe DEL START
--      l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax );
-- Ver.3.20 N.Abe DEL END
      ln_bm1_rcpt_discount_amt_notax                    := TRUNC( ln_bm1_rcpt_discount_amt_notax );
-- Ver.3.20 N.Abe DEL START
--      l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax );
--      l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax );
-- Ver.3.20 N.Abe DEL END
      ln_bm2_rcpt_discount_amt_notax                    := TRUNC( ln_bm2_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax );
-- Ver.3.20 N.Abe DEL START
--      l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := TRUNC( l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax );
-- Ver.3.20 N.Abe DEL END
      ln_bm3_rcpt_discount_amt_notax                    := TRUNC( ln_bm3_rcpt_discount_amt_notax );
      l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax := TRUNC( l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax );
--
-- Ver.3.20 N.Abe ADD START
      -- BM1�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm1_tax_kbn = '1' ) THEN
        ln_bm1_amt_no_tax       := TRUNC( ln_bm1_amt_no_tax );             -- �yBM1�zVDBM(�Ŕ�)
        ln_bm1_elect_amt_no_tax := TRUNC( ln_bm1_elect_amt_no_tax );  -- �yBM1�z�d�C��(�Ŕ�)
      END IF;
      -- BM2�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm2_tax_kbn = '1' ) THEN
        ln_bm2_amt_no_tax       := TRUNC( ln_bm2_amt_no_tax );             -- �yBM2�zVDBM(�Ŕ�)
      END IF;
      -- BM3�ŋ敪 = '1'�i�ō��j
      IF ( i_get_sales_data_rec.bm3_tax_kbn = '1' ) THEN
        ln_bm3_amt_no_tax       := TRUNC( ln_bm3_amt_no_tax );             -- �yBM3�zVDBM(�Ŕ�)
      END IF;
-- Ver.3.20 N.Abe ADD END
    END IF;
-- Ver.3.20 N.Abe ADD START
    --==================================================
    -- �擾�l�̒[�������iBM�ŋ敪:�Ŕ��A��ېŁj
    --==================================================
    -- BM1�ŋ敪 = '2'�i�Ŕ��j
    IF ( i_get_sales_data_rec.bm1_tax_kbn = '2' ) THEN
      -- �yBM1�zVDBM(�ō�)
      IF( ln_bm1_amt_tax >= 0 ) THEN
        ln_bm1_amt_tax  := CEIL( ln_bm1_amt_tax );
      ELSIF( ln_bm1_amt_tax < 0 ) THEN
        ln_bm1_amt_tax  := FLOOR( ln_bm1_amt_tax );
      END IF;
--
      -- �yBM1�z�d�C��(�ō�)
      IF( ln_bm1_elect_amt_tax >= 0 ) THEN
        ln_bm1_elect_amt_tax := CEIL( ln_bm1_elect_amt_tax );
      ELSIF( ln_bm1_elect_amt_tax < 0 ) THEN
        ln_bm1_elect_amt_tax := FLOOR( ln_bm1_elect_amt_tax );
      END IF;
    END IF;
--
    -- BM2�ŋ敪 IN ( '2', '3' )�i�Ŕ��A��ېŁj
    IF ( i_get_sales_data_rec.bm2_tax_kbn IN ( '2', '3') ) THEN
      -- �yBM2�zVDBM(�ō�)
      IF( ln_bm2_amt_tax >= 0 ) THEN
        ln_bm2_amt_tax  := CEIL( ln_bm2_amt_tax );
      ELSIF( ln_bm2_amt_tax < 0 ) THEN
        ln_bm2_amt_tax  := FLOOR( ln_bm2_amt_tax );
      END IF;
    END IF;
--
    -- BM3�ŋ敪 IN ( '2', '3' )�i�Ŕ��A��ېŁj
    IF ( i_get_sales_data_rec.bm3_tax_kbn IN ( '2', '3') ) THEN
      -- �yBM3�zVDBM(�ō�)
      IF( ln_bm3_amt_tax >= 0 ) THEN
        ln_bm3_amt_tax  := CEIL( ln_bm3_amt_tax );
      ELSIF( ln_bm3_amt_tax < 0 ) THEN
        ln_bm3_amt_tax  := FLOOR( ln_bm3_amt_tax );
      END IF;
    END IF;
    --==================================================
    -- �v�Z�����l��ϐ��Ɋi�[
    --==================================================
    -- VDBM(�ō�)
    l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax     := ln_bm1_amt_tax;
    l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax     := ln_bm2_amt_tax;
    l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax     := ln_bm3_amt_tax;
    -- VDBM(�Ŕ�)
    l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax  := ln_bm1_amt_no_tax;
    l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax  := ln_bm2_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax  := ln_bm3_amt_no_tax;
    -- �d�C��(�ō�)
    l_xcbs_data_tab( cn_index_1 ).electric_amt_tax    := ln_bm1_elect_amt_tax;
    -- �d�C��(�Ŕ�)
    l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax := ln_bm1_elect_amt_no_tax;
-- Ver.3.20 N.Abe ADD END
    --==================================================
    -- ����Ŋz�Z�o
    --==================================================
    -- ����Ŋz
    l_xcbs_data_tab( cn_index_1 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_1 ).cond_bm_amt_no_tax;
    l_xcbs_data_tab( cn_index_2 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_2 ).cond_bm_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).cond_tax_amt
      := l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_tax - l_xcbs_data_tab( cn_index_3 ).cond_bm_amt_no_tax;
    -- �����l������Ŋz
    l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_1 ).csh_rcpt_discount_amt - ln_bm1_rcpt_discount_amt_notax;
    l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_2 ).csh_rcpt_discount_amt - ln_bm2_rcpt_discount_amt_notax;
    l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt_tax
      := l_xcbs_data_tab( cn_index_3 ).csh_rcpt_discount_amt - ln_bm3_rcpt_discount_amt_notax;
    -- �d�C������Ŋz
-- Ver.3.20 N.Abe MOD END
--    l_xcbs_data_tab( cn_index_1 ).electric_tax_amt
--      := i_get_sales_data_rec.bm1_electric_amt_tax - l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax;
    l_xcbs_data_tab( cn_index_1 ).electric_tax_amt
      := l_xcbs_data_tab( cn_index_1 ).electric_amt_tax - l_xcbs_data_tab( cn_index_1 ).electric_amt_no_tax;
-- Ver.3.20 N.Abe MOD END
    l_xcbs_data_tab( cn_index_2 ).electric_tax_amt
      := i_get_sales_data_rec.bm2_electric_amt_tax - l_xcbs_data_tab( cn_index_2 ).electric_amt_no_tax;
    l_xcbs_data_tab( cn_index_3 ).electric_tax_amt
      := i_get_sales_data_rec.bm3_electric_amt_tax - l_xcbs_data_tab( cn_index_3 ).electric_amt_no_tax;
    --==================================================
    -- 4.�e�A�g�X�e�[�^�X
    --==================================================
-- 2009/10/27 Ver.3.3 [��QE_T4_00094] SCS K.Yamaguchi REPAIR START
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi ADD START
--    -- �x����������������
--    IF( i_get_sales_data_rec.term_name = gv_instantly_term_name ) THEN
--      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
--      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- �̎�c��       �s�v
--      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi ADD END
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
----    IF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
----        AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
----    ) THEN
--    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v���Ȃ�
--    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
--           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
--    ) THEN
---- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v���Ȃ�
    IF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
    ) THEN
-- 2009/10/27 Ver.3.3 [��QE_T4_00094] SCS K.Yamaguchi REPAIR END
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
      lv_bm_interface_status      := cv_xcbs_if_status_no;     -- �̎�c��       ������
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v����
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  = cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date  = gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_no;     -- �����ʔ̎�̋� ������
      lv_bm_interface_status      := cv_xcbs_if_status_no;     -- �̎�c��       ������
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�ȊO�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v���Ȃ�
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho <> cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date <> gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- �̎�c��       �s�v
      lv_ar_interface_status      := cv_xcbs_if_status_off;    -- AR             �s�v
    -- �̔����я��̋Ƒ�(������)�� '25'�F�t���T�[�r�XVD�A���Ɩ����t���̔����я��̌v�Z�Ώۊ���(TO)�ƈ�v����
    ELSIF(     ( i_get_sales_data_rec.ship_gyotai_sho  <> cv_gyotai_sho_25 )
           AND ( i_get_sales_data_rec.amount_fix_date   = gd_process_date  )
    ) THEN
      lv_cond_bm_interface_status := cv_xcbs_if_status_off;    -- �����ʔ̎�̋� �s�v
      lv_bm_interface_status      := cv_xcbs_if_status_off;    -- �̎�c��       �s�v
      lv_ar_interface_status      := cv_xcbs_if_status_no;     -- AR             ������
    END IF;
    --==================================================
    -- ���̑��l�ݒ�
    --==================================================
    -- �d����R�[�h
    l_xcbs_data_tab( cn_index_1 ).supplier_code := i_get_sales_data_rec.bm1_vendor_code;
    l_xcbs_data_tab( cn_index_2 ).supplier_code := i_get_sales_data_rec.bm2_vendor_code;
    l_xcbs_data_tab( cn_index_3 ).supplier_code := i_get_sales_data_rec.bm3_vendor_code;
    -- �d����T�C�g�R�[�h
    l_xcbs_data_tab( cn_index_1 ).supplier_site_code := i_get_sales_data_rec.bm1_vendor_site_code;
    l_xcbs_data_tab( cn_index_2 ).supplier_site_code := i_get_sales_data_rec.bm2_vendor_site_code;
    l_xcbs_data_tab( cn_index_3 ).supplier_site_code := i_get_sales_data_rec.bm3_vendor_site_code;
    -- BM��(%)
    l_xcbs_data_tab( cn_index_1 ).rebate_rate := i_get_sales_data_rec.bm1_pct;
    l_xcbs_data_tab( cn_index_2 ).rebate_rate := i_get_sales_data_rec.bm2_pct;
    l_xcbs_data_tab( cn_index_3 ).rebate_rate := i_get_sales_data_rec.bm3_pct;
    -- BM���z
    l_xcbs_data_tab( cn_index_1 ).rebate_amt := i_get_sales_data_rec.bm1_amt;
    l_xcbs_data_tab( cn_index_2 ).rebate_amt := i_get_sales_data_rec.bm2_amt;
    l_xcbs_data_tab( cn_index_3 ).rebate_amt := i_get_sales_data_rec.bm3_amt;
    -- �d�C��(�ō�)
-- Ver.3.20 N.Abe DEL START
--    l_xcbs_data_tab( cn_index_1 ).electric_amt_tax := i_get_sales_data_rec.bm1_electric_amt_tax;
-- Ver.3.20 N.Abe DEL END
    l_xcbs_data_tab( cn_index_2 ).electric_amt_tax := i_get_sales_data_rec.bm2_electric_amt_tax;
    l_xcbs_data_tab( cn_index_3 ).electric_amt_tax := i_get_sales_data_rec.bm3_electric_amt_tax;
    --==================================================
    -- 5.�擾�������e�������ʔ̎�̋����ɐݒ肵�܂��B
    --==================================================
    << set_xcbs_data_loop >>
    FOR i IN cn_index_1 .. cn_index_3 LOOP
      -- ���ʍ��ڂ����[�v�Őݒ�
      l_xcbs_data_tab( i ).base_code                 := i_get_sales_data_rec.base_code;                 -- ���_�R�[�h
      l_xcbs_data_tab( i ).emp_code                  := i_get_sales_data_rec.emp_code;                  -- �S���҃R�[�h
      l_xcbs_data_tab( i ).delivery_cust_code        := i_get_sales_data_rec.ship_cust_code;            -- �ڋq�y�[�i��z
      l_xcbs_data_tab( i ).demand_to_cust_code       := i_get_sales_data_rec.bill_cust_code;            -- �ڋq�y������z
      l_xcbs_data_tab( i ).acctg_year                := i_get_sales_data_rec.period_year;               -- ��v�N�x
      l_xcbs_data_tab( i ).chain_store_code          := i_get_sales_data_rec.ship_delivery_chain_code;  -- �`�F�[���X�R�[�h
      l_xcbs_data_tab( i ).calc_type                 := i_get_sales_data_rec.calc_type;                 -- �v�Z����
      l_xcbs_data_tab( i ).delivery_date             := i_get_sales_data_rec.delivery_ym;               -- �[�i���N��
      l_xcbs_data_tab( i ).delivery_qty              := i_get_sales_data_rec.dlv_qty;                   -- �[�i����
      l_xcbs_data_tab( i ).delivery_unit_type        := i_get_sales_data_rec.dlv_uom_code;              -- �[�i�P��
      l_xcbs_data_tab( i ).selling_amt_tax           := i_get_sales_data_rec.amount_inc_tax;            -- ������z(�ō�)
-- Ver.3.20 N.Abe ADD START
      l_xcbs_data_tab( i ).selling_amt_no_tax        := i_get_sales_data_rec.amount_no_tax;             -- ������z(�Ŕ�)
-- Ver.3.20 N.Abe ADD END
      l_xcbs_data_tab( i ).container_type_code       := i_get_sales_data_rec.container_code;            -- �e��敪�R�[�h
      l_xcbs_data_tab( i ).selling_price             := i_get_sales_data_rec.dlv_unit_price;            -- �������z
      l_xcbs_data_tab( i ).consumption_tax_class     := i_get_sales_data_rec.tax_div;                   -- ����ŋ敪
      l_xcbs_data_tab( i ).tax_code                  := i_get_sales_data_rec.tax_code;                  -- �ŋ��R�[�h
      l_xcbs_data_tab( i ).tax_rate                  := i_get_sales_data_rec.tax_rate;                  -- ����ŗ�
      l_xcbs_data_tab( i ).term_code                 := i_get_sales_data_rec.term_name;                 -- �x������
      l_xcbs_data_tab( i ).closing_date              := i_get_sales_data_rec.closing_date;              -- ���ߓ�
      l_xcbs_data_tab( i ).expect_payment_date       := i_get_sales_data_rec.expect_payment_date;       -- �x���\���
      l_xcbs_data_tab( i ).calc_target_period_from   := i_get_sales_data_rec.calc_target_period_from;   -- �v�Z�Ώۊ���(FROM)
      l_xcbs_data_tab( i ).calc_target_period_to     := i_get_sales_data_rec.calc_target_period_to;     -- �v�Z�Ώۊ���(TO)
      l_xcbs_data_tab( i ).cond_bm_interface_status  := lv_cond_bm_interface_status;                    -- �A�g�X�e�[�^�X(�����ʔ̎�̋�)
      l_xcbs_data_tab( i ).cond_bm_interface_date    := NULL;                                           -- �A�g��(�����ʔ̎�̋�)
      l_xcbs_data_tab( i ).bm_interface_status       := lv_bm_interface_status;                         -- �A�g�X�e�[�^�X(�̎�c��)
      l_xcbs_data_tab( i ).bm_interface_date         := NULL;                                           -- �A�g��(�̎�c��)
      l_xcbs_data_tab( i ).ar_interface_status       := lv_ar_interface_status;                         -- �A�g�X�e�[�^�X(AR)
      l_xcbs_data_tab( i ).ar_interface_date         := NULL;                                           -- �A�g��(AR)
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      l_vendor_dummy_flag_tab( i )                   := i_get_sales_data_rec.vendor_dummy_flag;         -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    END LOOP set_xcbs_data_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    o_xcbs_data_tab := l_xcbs_data_tab;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    o_vendor_dummy_flag_tab := l_vendor_dummy_flag_tab;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END set_xcbs_data;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop1
   * Description      : �̔����т̎擾�E�����ʏ���(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop1(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop1';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab        vendor_dummy_flag_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur1;
    << get_sales_data_loop1 >>
    LOOP
      FETCH get_sales_data_cur1 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur1%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , o_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , i_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop1;
    CLOSE get_sales_data_cur1;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop1;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop2
   * Description      : �̔����т̎擾�E�e��敪�ʏ���(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop2(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop2';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab        vendor_dummy_flag_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur2;
    << get_sales_data_loop2 >>
    LOOP
      FETCH get_sales_data_cur2 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur2%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , o_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , i_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec         -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop2;
    CLOSE get_sales_data_cur2;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop2;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop3
   * Description      : �̔����т̎擾�E�ꗥ����(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop3(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop3';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab        vendor_dummy_flag_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur3;
    << get_sales_data_loop3 >>
    LOOP
      FETCH get_sales_data_cur3 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur3%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , o_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , i_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop3;
    CLOSE get_sales_data_cur3;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop3;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop4
   * Description      : �̔����т̎擾�E��z����(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop4(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop4';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab        vendor_dummy_flag_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur4;
    << get_sales_data_loop4 >>
    LOOP
      FETCH get_sales_data_cur4 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur4%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , o_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , i_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop4;
    CLOSE get_sales_data_cur4;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop4;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop5
   * Description      : �̔����т̎擾�E�d�C���i�Œ�^�ϓ��j(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop5(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop5';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab        vendor_dummy_flag_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur5;
    << get_sales_data_loop5 >>
    LOOP
      FETCH get_sales_data_cur5 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur5%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , o_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , i_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec         -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop5;
    CLOSE get_sales_data_cur5;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop5;
--
  /**********************************************************************************
   * Procedure Name   : sales_result_loop6
   * Description      : �̔����т̎擾�E�����l����(A-8)
   ***********************************************************************************/
  PROCEDURE sales_result_loop6(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'sales_result_loop6';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    l_xcbs_data_tab                xcbs_data_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    l_vendor_dummy_flag_tab        vendor_dummy_flag_ttype;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    l_get_sales_data_rec           get_sales_data_rtype;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    OPEN get_sales_data_cur6;
    << get_sales_data_loop6 >>
    LOOP
      FETCH get_sales_data_cur6 INTO l_get_sales_data_rec;
      EXIT WHEN get_sales_data_cur6%NOTFOUND;
      --==================================================
      -- �����ʔ̎�̋����̐ݒ�
      --==================================================
      set_xcbs_data(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , o_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , o_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �����ʔ̎�̋��e�[�u���ւ̓o�^
      --==================================================
      insert_xcbs(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      , i_xcbs_data_tab             => l_xcbs_data_tab            -- �����ʔ̎�̋����
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
      , i_vendor_dummy_flag_tab     => l_vendor_dummy_flag_tab    -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�����G���[�e�[�u���ւ̓o�^
      --==================================================
      insert_xbce(
        ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
      , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
      , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      , i_get_sales_data_rec        => l_get_sales_data_rec       -- �̔����я�񃌃R�[�h
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
    END LOOP get_sales_data_loop6;
    CLOSE get_sales_data_cur6;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END sales_result_loop6;
--
  /**********************************************************************************
   * Procedure Name   : delete_xbce
   * Description      : �̎�����G���[�̍폜����(A-7)
   ***********************************************************************************/
  PROCEDURE delete_xbce(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xbce';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- ���O�o�͗p�ޔ�����
    lt_cust_code                   xxcok_bm_contract_err.cust_code%TYPE DEFAULT NULL;
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xbce_delete_lock_cur
    IS
      SELECT xbce.cust_code                AS cust_code  -- �ڋq�R�[�h
      FROM xxcok_bm_contract_err      xbce               -- �̎�����G���[�e�[�u��
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--         , xxcok_tmp_014a01c_custdata xt0c               -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
         , xxcok_wk_014a01c_custdata xt0c                -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
      WHERE xbce.cust_code  = xt0c.ship_cust_code
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      AND   xt0c.proc_type  = gv_param_proc_type
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      FOR UPDATE OF xbce.cust_code NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �̎�����G���[�폜���[�v
    --==================================================
    << xbce_delete_lock_loop >>
    FOR xbce_delete_lock_rec IN xbce_delete_lock_cur LOOP
      --==================================================
      -- �̎�����G���[�f�[�^�폜
      --==================================================
      lt_cust_code := xbce_delete_lock_rec.cust_code;
      DELETE
      FROM xxcok_bm_contract_err   xbce
      WHERE xbce.cust_code = xbce_delete_lock_rec.cust_code
      ;
    END LOOP xbce_delete_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- ���b�N�擾�G���[
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00080
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END delete_xbce;
--
  /**********************************************************************************
   * Procedure Name   : delete_xcbs
   * Description      : �����ʔ̎�̋��f�[�^�̍폜�i���m����z�j(A-3)
   ***********************************************************************************/
  PROCEDURE delete_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'delete_xcbs';      -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    -- ���O�o�͗p�ޔ�����
    lt_cond_bm_support_id          xxcok_cond_bm_support.cond_bm_support_id%TYPE DEFAULT NULL;
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbs_delete_lock_cur
    IS
      SELECT /*+ LEADING(flv hl) */
             xcbs.cond_bm_support_id    AS cond_bm_support_id  -- �����ʔ̎�̋�ID
           , xcbs.delivery_cust_code    AS delivery_cust_code  -- �ڋq�y�[�i��z
           , xcbs.closing_date          AS closing_date        -- ���ߓ�
      FROM xxcok_cond_bm_support      xcbs               -- �����ʔ̎�̋��e�[�u��
         , hz_cust_accounts        hca                -- �ڋq�}�X�^
         , hz_cust_acct_sites_all  hcas               -- �ڋq�T�C�g�}�X�^
         , hz_parties              hp                 -- �p�[�e�B�}�X�^
         , hz_party_sites          hps                -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations            hl                 -- �ڋq���ݒn�}�X�^
         , fnd_lookup_values       flv                -- �̎�̋��v�Z���s�敪
      WHERE xcbs.delivery_cust_code          = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.attribute1                   = gv_param_proc_type
        AND flv.language                     = cv_lang
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND hl.address3                   LIKE flv.lookup_code || '%'
        AND xcbs.amt_fix_status    = cv_xcbs_temp -- ���m��
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �����ʔ̎�̋��폜���[�v
    --==================================================
    << xcbs_delete_lock_loop >>
    FOR xcbs_delete_lock_rec IN xcbs_delete_lock_cur LOOP
      --==================================================
      -- �����ʔ̎�̋��f�[�^�폜
      --==================================================
      DELETE
      FROM xxcok_cond_bm_support   xcbs
      WHERE xcbs.cond_bm_support_id = xcbs_delete_lock_rec.cond_bm_support_id
      ;
    END LOOP xcbs_delete_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END delete_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : insert_xt0c
   * Description      : �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^(A-6)
   ***********************************************************************************/
  PROCEDURE insert_xt0c(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_cust_data_rec            IN  get_cust_data_cur%ROWTYPE  -- �ڋq��񃌃R�[�h
  , iv_term_name                   IN  VARCHAR2                   -- �x������
  , id_close_date                  IN  DATE                       -- ���ߓ�
  , id_expect_payment_date         IN  DATE                       -- �x���\���
  , in_period_year                 IN  NUMBER                     -- ��v�N�x
  , id_amount_fix_date             IN  DATE                       -- ���z�m���
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--  , it_emp_code                    IN  xxcok_tmp_014a01c_custdata.emp_code%TYPE -- �S���҃R�[�h
  , it_emp_code                    IN  xxcok_wk_014a01c_custdata.emp_code%TYPE -- �S���҃R�[�h
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xt0c';      -- �v���O������
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    cv_xxcok1_dummy_vendor_code    CONSTANT VARCHAR2(30) := 'XXCOK1_DUMMY_VENDOR_CODE';      -- �_�~�[�d����R�[�h
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_expect_payment_date         DATE           DEFAULT NULL;                 -- �x���\���
    ld_calc_target_period_from     DATE           DEFAULT NULL;                 -- �v�Z�Ώۊ���(FROM)
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �x���\���
    --==================================================
    IF ( i_get_cust_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      ld_expect_payment_date := id_expect_payment_date;
    ELSE
      ld_expect_payment_date := id_close_date;
    END IF;
    --==================================================
    -- �v�Z�Ώۊ���(FROM)
    --==================================================
    IF ( i_get_cust_data_rec.calc_target_period_from IS NOT NULL ) THEN
      ld_calc_target_period_from := i_get_cust_data_rec.calc_target_period_from;
    ELSIF( iv_term_name = gv_instantly_term_name ) THEN
      ld_calc_target_period_from := id_close_date;
    ELSE
      ld_calc_target_period_from := ADD_MONTHS( id_close_date, -1 ) + 1;
    END IF;
    --==================================================
    -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^
    --==================================================
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--    INSERT INTO xxcok_tmp_014a01c_custdata (
    INSERT INTO xxcok_wk_014a01c_custdata (
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
      ship_cust_code              -- �y�o�א�z�ڋq�R�[�h
    , ship_gyotai_tyu             -- �y�o�א�z�Ƒԁi�����ށj
    , ship_gyotai_sho             -- �y�o�א�z�Ƒԁi�����ށj
    , ship_delivery_chain_code    -- �y�o�א�z�[�i��`�F�[���R�[�h
    , bill_cust_code              -- �y������z�ڋq�R�[�h
    , bm1_vendor_code             -- �y�a�l�P�z�d����R�[�h
    , bm1_vendor_site_code        -- �y�a�l�P�z�d����T�C�g�R�[�h
    , bm1_bm_payment_type         -- �y�a�l�P�zBM�x���敪
    , bm2_vendor_code             -- �y�a�l�Q�z�d����R�[�h
    , bm2_vendor_site_code        -- �y�a�l�Q�z�d����T�C�g�R�[�h
    , bm2_bm_payment_type         -- �y�a�l�Q�zBM�x���敪
    , bm3_vendor_code             -- �y�a�l�R�z�d����R�[�h
    , bm3_vendor_site_code        -- �y�a�l�R�z�d����T�C�g�R�[�h
    , bm3_bm_payment_type         -- �y�a�l�R�zBM�x���敪
    , tax_div                     -- ����ŋ敪
    , tax_code                    -- �ŋ��R�[�h
    , tax_rate                    -- �ŗ�
    , tax_rounding_rule           -- �[�������敪
    , receiv_discount_rate        -- �����l����
    , term_name                   -- �x������
    , closing_date                -- ���ߓ�
    , expect_payment_date         -- �x���\���
    , period_year                 -- ��v�N�x
    , calc_target_period_from     -- �v�Z�Ώۊ���(FROM)
    , calc_target_period_to       -- �v�Z�Ώۊ���(TO)
    , amount_fix_date             -- ���z�m���
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
    , emp_code                    -- �S���҃R�[�h
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    , proc_type                   -- ���s�敪
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    , vendor_dummy_flag           -- �d����_�~�[�t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    , created_by                  -- �쐬��
    , creation_date               -- �쐬��
    , last_updated_by             -- �ŏI�X�V��
    , last_update_date            -- �ŏI�X�V��
    , last_update_login           -- �ŏI�X�V���O�C��
    , request_id                  -- �v��ID
    , program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , program_id                  -- �R���J�����g�E�v���O����ID
    , program_update_date         -- �v���O�����X�V��
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    )
    VALUES (
      i_get_cust_data_rec.ship_cust_code             -- �y�o�א�z�ڋq�R�[�h
    , i_get_cust_data_rec.ship_gyotai_tyu            -- �y�o�א�z�Ƒԁi�����ށj
    , i_get_cust_data_rec.ship_gyotai_sho            -- �y�o�א�z�Ƒԁi�����ށj
    , i_get_cust_data_rec.ship_delivery_chain_code   -- �y�o�א�z�[�i��`�F�[���R�[�h
    , i_get_cust_data_rec.bill_cust_code             -- �y������z�ڋq�R�[�h
    , i_get_cust_data_rec.bm1_vendor_code            -- �y�a�l�P�z�d����R�[�h
    , i_get_cust_data_rec.bm1_vendor_site_code       -- �y�a�l�P�z�d����T�C�g�R�[�h
    , i_get_cust_data_rec.bm1_bm_payment_type        -- �y�a�l�P�zBM�x���敪
    , i_get_cust_data_rec.bm2_vendor_code            -- �y�a�l�Q�z�d����R�[�h
    , i_get_cust_data_rec.bm2_vendor_site_code       -- �y�a�l�Q�z�d����T�C�g�R�[�h
    , i_get_cust_data_rec.bm2_bm_payment_type        -- �y�a�l�Q�zBM�x���敪
    , i_get_cust_data_rec.bm3_vendor_code            -- �y�a�l�R�z�d����R�[�h
    , i_get_cust_data_rec.bm3_vendor_site_code       -- �y�a�l�R�z�d����T�C�g�R�[�h
    , i_get_cust_data_rec.bm3_bm_payment_type        -- �y�a�l�R�zBM�x���敪
    , i_get_cust_data_rec.tax_div                    -- ����ŋ敪
    , i_get_cust_data_rec.tax_code                   -- �ŋ��R�[�h
    , i_get_cust_data_rec.tax_rate                   -- �ŗ�
    , i_get_cust_data_rec.tax_rounding_rule          -- �[�������敪
    , i_get_cust_data_rec.receiv_discount_rate       -- �����l����
    , iv_term_name                                   -- �x������
    , id_close_date                                  -- ���ߓ�
    , ld_expect_payment_date                         -- �x���\���
    , in_period_year                                 -- ��v�N�x
    , ld_calc_target_period_from                     -- �v�Z�Ώۊ���(FROM)
    , id_close_date                                  -- �v�Z�Ώۊ���(TO)
    , id_amount_fix_date                             -- ���z�m���
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
    , it_emp_code                                    -- �S���҃R�[�h
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    , i_get_cust_data_rec.proc_type                  -- ���s�敪
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    , CASE
        WHEN EXISTS ( SELECT 'X'
                      FROM fnd_lookup_values     flv   -- �_�~�[�d����R�[�h
                      WHERE flv.lookup_code  in ( i_get_cust_data_rec.bm1_vendor_code,
                                                  i_get_cust_data_rec.bm2_vendor_code,
                                                  i_get_cust_data_rec.bm3_vendor_code
                                                 )
                      AND   flv.lookup_type  = cv_xxcok1_dummy_vendor_code
                      AND   flv.language     = cv_lang
                      AND   flv.enabled_flag = cv_enable
                      AND   gd_process_date    BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                   AND NVL( flv.end_date_active,   gd_process_date )
                    )
        THEN
          cv_vendor_dummy_on
        ELSE
          cv_vendor_dummy_off
      END                                            -- �_�~�[�d���攻��t���O
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    , cn_created_by                                  -- �쐬��
    , SYSDATE                                        -- �쐬��
    , cn_last_updated_by                             -- �ŏI�X�V��
    , SYSDATE                                        -- �ŏI�X�V��
    , cn_last_update_login                           -- �ŏI�X�V���O�C��
    , cn_request_id                                  -- �v��ID
    , cn_program_application_id                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    , cn_program_id                                  -- �R���J�����g�E�v���O����ID
    , SYSDATE                                        -- �v���O�����X�V��
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    );
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
END insert_xt0c;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_subdata
   * Description      : �����ʔ̎�̋��v�Z���t���̓��o(A-5)
   ***********************************************************************************/
  PROCEDURE get_cust_subdata(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , i_get_cust_data_rec            IN  get_cust_data_cur%ROWTYPE  -- �ڋq��񃌃R�[�h
  , ov_term_name                   OUT VARCHAR2                   -- �x������
  , od_close_date                  OUT DATE                       -- ���ߓ�
  , od_expect_payment_date         OUT DATE                       -- �x���\���
  , od_bm_support_period_from      OUT DATE                       -- �����ʔ̎�̋��v�Z�J�n��
  , od_bm_support_period_to        OUT DATE                       -- �����ʔ̎�̋��v�Z�I����
  , on_period_year                 OUT NUMBER                     -- ��v�N�x
  , od_amount_fix_date             OUT DATE                       -- ���z�m���
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'get_cust_subdata';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_tmp_bm_support_period_from  DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n��(��)
    ld_tmp_bm_support_period_to    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I����(��)
    ld_close_date1                 DATE           DEFAULT NULL;                 -- ���ߓ��i�x�������j
    ld_pay_date1                   DATE           DEFAULT NULL;                 -- �x�����i�x�������j
    ld_expect_payment_date1        DATE           DEFAULT NULL;                 -- �x���\����i�x�������j
    ld_close_date2                 DATE           DEFAULT NULL;                 -- ���ߓ��i��2�x�������j
    ld_pay_date2                   DATE           DEFAULT NULL;                 -- �x�����i��2�x�������j
    ld_expect_payment_date2        DATE           DEFAULT NULL;                 -- �x���\����i��2�x�������j
    ld_close_date3                 DATE           DEFAULT NULL;                 -- ���ߓ��i��3�x�������j
    ld_pay_date3                   DATE           DEFAULT NULL;                 -- �x�����i��3�x�������j
    ld_expect_payment_date3        DATE           DEFAULT NULL;                 -- �x���\����i��3�x�������j
    ld_bm_support_period_from_1    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n���i�x�������j
    ld_bm_support_period_to_1      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I�����i�x�������j
    ld_bm_support_period_from_2    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n���i��2�x�������j
    ld_bm_support_period_to_2      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I�����i��2�x�������j
    ld_bm_support_period_from_3    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n���i��3�x�������j
    ld_bm_support_period_to_3      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I�����i��3�x�������j
    lv_fix_term_name               VARCHAR2(10)   DEFAULT NULL;                 -- �x������
    ld_fix_close_date              DATE           DEFAULT NULL;                 -- ���ߓ�
    ld_fix_expect_payment_date     DATE           DEFAULT NULL;                 -- �x���\���
    ld_fix_bm_support_period_from  DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n��
    ld_fix_bm_support_period_to    DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I����
    ln_period_year                 NUMBER         DEFAULT NULL;                 -- ��v�N�x
    ld_amount_fix_date             DATE           DEFAULT NULL;                 -- ���z�m���
    lv_period_name                 gl_periods.period_name%TYPE DEFAULT NULL;    -- ��v���Ԗ�
    lv_closing_status              gl_period_statuses.closing_status%TYPE DEFAULT NULL;                 -- �X�e�[�^�X
    --==================================================
    -- ���[�J����O
    --==================================================
    skip_proc_expt                 EXCEPTION; -- �v�Z�ΏۊO�X�L�b�v
    get_close_date_expt            EXCEPTION; -- ���߁E�x�����擾�֐��G���[
    get_operating_day_expt         EXCEPTION; -- �c�Ɠ��擾�֐��G���[
    get_acctg_calendar_expt        EXCEPTION; -- ��v�J�����_�擾�֐��G���[
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ������������
    --==================================================
    IF(    ( i_get_cust_data_rec.term_name1 = gv_instantly_term_name )
        OR ( i_get_cust_data_rec.term_name2 = gv_instantly_term_name )
        OR ( i_get_cust_data_rec.term_name3 = gv_instantly_term_name )
    ) THEN
      lv_fix_term_name              := gv_instantly_term_name;
      ld_fix_close_date             := gd_process_date;
      ld_fix_expect_payment_date    := gd_process_date;
      ld_fix_bm_support_period_from := gd_process_date;
      ld_fix_bm_support_period_to   := gd_process_date;
      ld_amount_fix_date            := gd_process_date;
    ELSE
      --==================================================
      -- �����ʔ̎�̋��v�Z�J�n��(��)�擾
      --==================================================
      IF( i_get_cust_data_rec.settle_amount_cycle IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      ld_tmp_bm_support_period_from :=
        get_operating_day_f(
          id_proc_date             => gd_process_date                               -- IN DATE   ������
        , in_days                  => -1 * i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
        , in_proc_type             => cn_proc_type_before                           -- IN NUMBER �����敪
        );
      IF( ld_tmp_bm_support_period_from IS NULL ) THEN
        RAISE get_operating_day_expt;
      END IF;
      --==================================================
      -- �x������
      --==================================================
      IF( i_get_cust_data_rec.term_name1 IS NOT NULL ) THEN
        --==================================================
        -- ���ߎx�����擾�i�x�������j
        --==================================================
        xxcok_common_pkg.get_close_date_p(
          ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
        , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          ���^�[���R�[�h
        , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
        , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
        , iv_pay_cond                => i_get_cust_data_rec.term_name1    -- IN  VARCHAR2          �x������(IN)
        , od_close_date              => ld_close_date1                    -- OUT DATE              ���ߓ�(OUT)
        , od_pay_date                => ld_pay_date1                      -- OUT DATE              �x����(OUT)
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE get_close_date_expt;
        END IF;
        --==================================================
        -- �x���\����擾�i�x�������j
        --==================================================
        ld_expect_payment_date1 :=
          get_operating_day_f(
            id_proc_date             => ld_pay_date1                             -- IN DATE   ������
          , in_days                  => 0                                        -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_expect_payment_date1 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
        --==================================================
        -- �����ʔ̎�̋��v�Z�J�n�E�I��������i�x�������j
        --==================================================
        ld_bm_support_period_to_1   :=
          get_operating_day_f(
            id_proc_date             => ld_close_date1                           -- IN DATE   ������
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_bm_support_period_to_1 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--        IF( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd ) THEN
        IF(    ( i_get_cust_data_rec.ship_gyotai_sho IN ( cv_gyotai_sho_26, cv_gyotai_sho_27 ) )
            OR ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd                       )
         ) THEN
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
          ld_bm_support_period_from_1 := ld_bm_support_period_to_1;
        ELSE
          ld_bm_support_period_from_1 :=
            get_operating_day_f(
              id_proc_date             => ld_close_date1                           -- IN DATE   ������
            , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER ����
            , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
            );
          IF( ld_bm_support_period_from_1 IS NULL ) THEN
            RAISE get_operating_day_expt;
          END IF;
        END IF;
      ELSE
        ld_bm_support_period_from_1 := NULL;
        ld_bm_support_period_to_1   := NULL;
      END IF;
      --==================================================
      -- �x����������i�x�������j
      --==================================================
      IF( gd_process_date BETWEEN ld_bm_support_period_from_1
                              AND ld_bm_support_period_to_1  ) THEN
        lv_fix_term_name              := i_get_cust_data_rec.term_name1;
        ld_fix_close_date             := ld_close_date1;
-- 2009/12/10 Ver.3.5 [E_�{�ғ�_00363] SCS K.Yamaguchi REPAIR START
--        ld_fix_expect_payment_date    := ld_pay_date1;
        ld_fix_expect_payment_date    := ld_expect_payment_date1;
-- 2009/12/10 Ver.3.5 [E_�{�ғ�_00363] SCS K.Yamaguchi REPAIR END
        ld_fix_bm_support_period_from := ld_bm_support_period_from_1;
        ld_fix_bm_support_period_to   := ld_bm_support_period_to_1;
      END IF;
      --==================================================
      -- ��2�x������
      -- �i��1�j�x�������Ōv�Z�ΏۊO�̏ꍇ�̂�
      --==================================================
      IF(     ( lv_fix_term_name IS NULL )
          AND ( i_get_cust_data_rec.term_name2 IS NOT NULL )
      ) THEN
        --==================================================
        -- ���ߎx�����擾�i��2�x�������j
        --==================================================
        xxcok_common_pkg.get_close_date_p(
          ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
        , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          ���^�[���R�[�h
        , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
        , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
        , iv_pay_cond                => i_get_cust_data_rec.term_name2    -- IN  VARCHAR2          �x������(IN)
        , od_close_date              => ld_close_date2                    -- OUT DATE              ���ߓ�(OUT)
        , od_pay_date                => ld_pay_date2                      -- OUT DATE              �x����(OUT)
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE get_close_date_expt;
        END IF;
        --==================================================
        -- �x���\����擾�i��2�x�������j
        --==================================================
        ld_expect_payment_date2 :=
          get_operating_day_f(
            id_proc_date             => ld_pay_date2                             -- IN DATE   ������
          , in_days                  => 0                                        -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_expect_payment_date2 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
        --==================================================
        -- �����ʔ̎�̋��v�Z�J�n�E�I��������i��2�x�������j
        --==================================================
        ld_bm_support_period_to_2   :=
          get_operating_day_f(
            id_proc_date             => ld_close_date2                           -- IN DATE   ������
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_bm_support_period_to_2 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--        IF( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd ) THEN
        IF(    ( i_get_cust_data_rec.ship_gyotai_sho IN ( cv_gyotai_sho_26, cv_gyotai_sho_27 ) )
            OR ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd                       )
         ) THEN
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
          ld_bm_support_period_from_2 := ld_bm_support_period_to_2;
        ELSE
          ld_bm_support_period_from_2 := 
            get_operating_day_f(
              id_proc_date             => ld_close_date2                           -- IN DATE   ������
            , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER ����
            , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
            );
          IF( ld_bm_support_period_from_2 IS NULL ) THEN
            RAISE get_operating_day_expt;
          END IF;
        END IF;
      ELSE
        ld_bm_support_period_from_2 := NULL;
        ld_bm_support_period_to_2   := NULL;
      END IF;
      --==================================================
      -- �x����������i��2�x�������j
      --==================================================
      IF( gd_process_date BETWEEN ld_bm_support_period_from_2
                              AND ld_bm_support_period_to_2  ) THEN
        lv_fix_term_name              := i_get_cust_data_rec.term_name2;
        ld_fix_close_date             := ld_close_date2;
-- 2009/12/10 Ver.3.5 [E_�{�ғ�_00363] SCS K.Yamaguchi REPAIR START
--        ld_fix_expect_payment_date    := ld_pay_date2;
        ld_fix_expect_payment_date    := ld_expect_payment_date2;
-- 2009/12/10 Ver.3.5 [E_�{�ғ�_00363] SCS K.Yamaguchi REPAIR END
        ld_fix_bm_support_period_from := ld_bm_support_period_from_2;
        ld_fix_bm_support_period_to   := ld_bm_support_period_to_2;
      END IF;
      --==================================================
      -- ��3�x������
      -- �i��1�j�x�������E��2�x�������Ōv�Z�ΏۊO�̏ꍇ�̂�
      --==================================================
      IF(     ( lv_fix_term_name IS NULL )
          AND ( i_get_cust_data_rec.term_name3 IS NOT NULL )
      ) THEN
        --==================================================
        -- ���ߎx�����擾�i��3�x�������j
        --==================================================
        xxcok_common_pkg.get_close_date_p(
          ov_errbuf                  => lv_errbuf                         -- OUT VARCHAR2          ���O�ɏo�͂���G���[�E���b�Z�[�W
        , ov_retcode                 => lv_retcode                        -- OUT VARCHAR2          ���^�[���R�[�h
        , ov_errmsg                  => lv_errmsg                         -- OUT VARCHAR2          ���[�U�[�Ɍ�����G���[�E���b�Z�[�W
        , id_proc_date               => ld_tmp_bm_support_period_from     -- IN  DATE DEFAULT NULL ������(�Ώۓ�)
        , iv_pay_cond                => i_get_cust_data_rec.term_name3    -- IN  VARCHAR2          �x������(IN)
        , od_close_date              => ld_close_date3                    -- OUT DATE              ���ߓ�(OUT)
        , od_pay_date                => ld_pay_date3                      -- OUT DATE              �x����(OUT)
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE get_close_date_expt;
        END IF;
        --==================================================
        -- �x���\����擾�i��3�x�������j
        --==================================================
        ld_expect_payment_date3 :=
          get_operating_day_f(
            id_proc_date             => ld_pay_date3                             -- IN DATE   ������
          , in_days                  => 0                                        -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_expect_payment_date3 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
        --==================================================
        -- �����ʔ̎�̋��v�Z�J�n�E�I��������i��3�x�������j
        --==================================================
        ld_bm_support_period_to_3   :=
          get_operating_day_f(
            id_proc_date             => ld_close_date3                           -- IN DATE   ������
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_bm_support_period_to_3 IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR START
--        IF( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd ) THEN
        IF(    ( i_get_cust_data_rec.ship_gyotai_sho IN ( cv_gyotai_sho_26, cv_gyotai_sho_27 ) )
            OR ( i_get_cust_data_rec.ship_gyotai_tyu <> cv_gyotai_tyu_vd                       )
         ) THEN
-- 2009/10/02 Ver.3.1 [�d�l�ύXI_E_566] SCS K.Yamaguchi REPAIR END
          ld_bm_support_period_from_3 := ld_bm_support_period_to_3;
        ELSE
          ld_bm_support_period_from_3 := 
            get_operating_day_f(
              id_proc_date             => ld_close_date3                           -- IN DATE   ������
            , in_days                  => ABS( gn_bm_support_period_from )         -- IN NUMBER ����
            , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
            );
          IF( ld_bm_support_period_from_3 IS NULL ) THEN
            RAISE get_operating_day_expt;
          END IF;
        END IF;
      ELSE
        ld_bm_support_period_from_3 := NULL;
        ld_bm_support_period_to_3   := NULL;
      END IF;
      --==================================================
      -- �x����������i��3�x�������j
      --==================================================
      IF( gd_process_date BETWEEN ld_bm_support_period_from_3
                              AND ld_bm_support_period_to_3  ) THEN
        lv_fix_term_name              := i_get_cust_data_rec.term_name3;
        ld_fix_close_date             := ld_close_date3;
-- 2009/12/10 Ver.3.5 [E_�{�ғ�_00363] SCS K.Yamaguchi REPAIR START
--        ld_fix_expect_payment_date    := ld_pay_date3;
        ld_fix_expect_payment_date    := ld_expect_payment_date3;
-- 2009/12/10 Ver.3.5 [E_�{�ғ�_00363] SCS K.Yamaguchi REPAIR END
        ld_fix_bm_support_period_from := ld_bm_support_period_from_3;
        ld_fix_bm_support_period_to   := ld_bm_support_period_to_3;
      END IF;
      --==================================================
      -- �x����������
      -- ���ׂĂ̎x�������Ōv�Z�ΏۊO�̏ꍇ
      --==================================================
      IF( lv_fix_term_name IS NULL ) THEN
        lv_fix_term_name              := NULL;
        ld_fix_close_date             := NULL;
        ld_fix_expect_payment_date    := NULL;
        ld_fix_bm_support_period_from := NULL;
        ld_fix_bm_support_period_to   := NULL;
        ld_amount_fix_date            := NULL;
        RAISE skip_proc_expt;
      END IF;
      --==================================================
      -- ���z�m����擾
      --==================================================
      IF( lv_fix_term_name IS NOT NULL ) THEN
        ld_amount_fix_date := 
          get_operating_day_f(
            id_proc_date             => ld_fix_close_date                        -- IN DATE   ������
          , in_days                  => i_get_cust_data_rec.settle_amount_cycle  -- IN NUMBER ����
          , in_proc_type             => cn_proc_type_before                      -- IN NUMBER �����敪
          );
        IF( ld_amount_fix_date IS NULL ) THEN
          RAISE get_operating_day_expt;
        END IF;
      END IF;
    END IF;
-- 2010/05/26 Ver.3.11 [E_�{�ғ�_02855] SCS K.Yamaguchi DELETE START
--fnd_file.put_line(
--  FND_FILE.LOG
--,           '"' || i_get_cust_data_rec.ship_cust_code || '"'
--  || ',' || '"' || i_get_cust_data_rec.term_name1     || '"'
--  || ',' || '"' || ld_pay_date1                       || '"'
--  || ',' || '"' || ld_close_date1                     || '"'
--  || ',' || '"' || ld_bm_support_period_from_1        || '"'
--  || ',' || '"' || ld_bm_support_period_to_1          || '"'
--  || ',' || '"' || i_get_cust_data_rec.term_name2     || '"'
--  || ',' || '"' || ld_pay_date2                       || '"'
--  || ',' || '"' || ld_close_date2                     || '"'
--  || ',' || '"' || ld_bm_support_period_from_2        || '"'
--  || ',' || '"' || ld_bm_support_period_to_2          || '"'
--  || ',' || '"' || i_get_cust_data_rec.term_name3     || '"'
--  || ',' || '"' || ld_pay_date3                       || '"'
--  || ',' || '"' || ld_close_date3                     || '"'
--  || ',' || '"' || ld_bm_support_period_from_3        || '"'
--  || ',' || '"' || ld_bm_support_period_to_3          || '"'
--  || ',' || '"' || ld_amount_fix_date                 || '"'
--); -- For Debug
-- 2010/05/26 Ver.3.11 [E_�{�ғ�_02855] SCS K.Yamaguchi DELETE END
    --==================================================
    -- ��v���Ԏ擾
    --==================================================
    IF( i_get_cust_data_rec.ship_gyotai_sho = cv_gyotai_sho_25 ) THEN
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                        -- OUT VARCHAR2     �G���[�o�b�t�@
      , ov_retcode                => lv_retcode                       -- OUT VARCHAR2     ���^�[���R�[�h
      , ov_errmsg                 => lv_errmsg                        -- OUT VARCHAR2     �G���[���b�Z�[�W
      , in_set_of_books_id        => gn_set_of_books_id               -- IN  NUMBER       ��v����ID
      , iv_application_short_name => cv_appl_short_name_gl            -- IN  VARCHAR2     �A�v���P�[�V�����Z�k��
      , id_object_date            => ld_fix_expect_payment_date       -- IN  DATE         �Ώۓ�
      , on_period_year            => ln_period_year                   -- OUT NUMBER       ��v�N�x
      , ov_period_name            => lv_period_name                   -- OUT VARCHAR2     ��v���Ԗ�
      , ov_closing_status         => lv_closing_status                -- OUT VARCHAR2     �X�e�[�^�X
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_acctg_calendar_expt;
      END IF;
    ELSE
      xxcok_common_pkg.get_acctg_calendar_p(
        ov_errbuf                 => lv_errbuf                        -- OUT VARCHAR2     �G���[�o�b�t�@
      , ov_retcode                => lv_retcode                       -- OUT VARCHAR2     ���^�[���R�[�h
      , ov_errmsg                 => lv_errmsg                        -- OUT VARCHAR2     �G���[���b�Z�[�W
      , in_set_of_books_id        => gn_set_of_books_id               -- IN  NUMBER       ��v����ID
      , iv_application_short_name => cv_appl_short_name_ar            -- IN  VARCHAR2     �A�v���P�[�V�����Z�k��
      , id_object_date            => ld_fix_close_date                -- IN  DATE         �Ώۓ�
      , on_period_year            => ln_period_year                   -- OUT NUMBER       ��v�N�x
      , ov_period_name            => lv_period_name                   -- OUT VARCHAR2     ��v���Ԗ�
      , ov_closing_status         => lv_closing_status                -- OUT VARCHAR2     �X�e�[�^�X
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE get_acctg_calendar_expt;
      END IF;
    END IF;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_term_name              := lv_fix_term_name;
    od_close_date             := ld_fix_close_date;
    od_expect_payment_date    := ld_fix_expect_payment_date;
    od_bm_support_period_from := ld_fix_bm_support_period_from;
    od_bm_support_period_to   := ld_fix_bm_support_period_to;
    on_period_year            := ln_period_year;
    od_amount_fix_date        := ld_amount_fix_date;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �v�Z�ΏۊO�X�L�b�v ***
    WHEN skip_proc_expt THEN
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errbuf  := NULL;
      ov_errmsg  := NULL;
      ov_retcode := cv_status_normal;
    -- *** ���߁E�x�����擾�֐��G���[ ***
    WHEN get_close_date_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10454
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** �c�Ɠ��擾�֐��G���[ ***
    WHEN get_operating_day_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10455
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** ��v�J�����_�擾�֐��G���[ ***
    WHEN get_acctg_calendar_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_10456
                    , iv_token_name1          => cv_tkn_cust_code
                    , iv_token_value1         => i_get_cust_data_rec.ship_cust_code
                    , iv_token_name2          => cv_tkn_proc_date
                    , iv_token_value2         => ld_fix_expect_payment_date
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_term_name              := NULL;
      od_close_date             := NULL;
      od_expect_payment_date    := NULL;
      od_bm_support_period_from := NULL;
      od_bm_support_period_to   := NULL;
      on_period_year            := NULL;
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_cust_subdata;
--
  /**********************************************************************************
   * Procedure Name   : cust_loop
   * Description      : �ڋq��񃋁[�v(A-4)
   ***********************************************************************************/
  PROCEDURE cust_loop(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'cust_loop';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    lv_term_name                   VARCHAR2(5000) DEFAULT NULL;                 -- �x������
    ld_close_date                  DATE           DEFAULT NULL;                 -- ���ߓ�
    ld_expect_payment_date         DATE           DEFAULT NULL;                 -- �x���\���
    ld_bm_support_period_from      DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�J�n��
    ld_bm_support_period_to        DATE           DEFAULT NULL;                 -- �����ʔ̎�̋��v�Z�I����
    ln_period_year                 NUMBER         DEFAULT NULL;                 -- ��v�N�x
    ld_amount_fix_date             DATE           DEFAULT NULL;                 -- ���z�m���
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--    lt_emp_code                    xxcok_tmp_014a01c_custdata.emp_code%TYPE;    -- �S���҃R�[�h
    lt_emp_code                    xxcok_wk_014a01c_custdata.emp_code%TYPE;     -- �S���҃R�[�h
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
    -- ���O�o�͗p�ޔ�����
    lt_ship_cust_code              hz_cust_accounts.account_number      %TYPE DEFAULT NULL;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �ڋq���̎擾
    --==================================================
    << cust_data_loop >>
    FOR get_cust_data_rec IN get_cust_data_cur LOOP
      lt_ship_cust_code := get_cust_data_rec.ship_cust_code;
      gn_target_cnt := gn_target_cnt + 1;
      DECLARE
        normal_skip_expt           EXCEPTION; -- �����X�L�b�v
      BEGIN
        --==================================================
        -- �����ʔ̎�̋��v�Z���t���̓��o
        --==================================================
        get_cust_subdata(
          ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
        , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
        , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
        , i_get_cust_data_rec         => get_cust_data_rec          -- �ڋq��񃌃R�[�h
        , ov_term_name                => lv_term_name               -- �x������
        , od_close_date               => ld_close_date              -- ���ߓ�
        , od_expect_payment_date      => ld_expect_payment_date     -- �x���\���
        , od_bm_support_period_from   => ld_bm_support_period_from  -- �����ʔ̎�̋��v�Z�J�n��
        , od_bm_support_period_to     => ld_bm_support_period_to    -- �����ʔ̎�̋��v�Z�I����
        , on_period_year              => ln_period_year             -- ��v�N�x
        , od_amount_fix_date          => ld_amount_fix_date         -- ���z�m���
        );
        IF( lv_retcode = cv_status_error ) THEN
          lv_end_retcode := cv_status_error;
          RAISE global_process_expt;
        ELSIF( lv_retcode = cv_status_warn ) THEN
          RAISE warning_skip_expt;
        END IF;
        --==================================================
        -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�ւ̓o�^
        --==================================================
        IF( gd_process_date BETWEEN ld_bm_support_period_from AND ld_bm_support_period_to ) THEN
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
          --==================================================
          -- �S���c�ƈ��`�F�b�N
          --==================================================
          lt_emp_code := xxcok_common_pkg.get_sales_staff_code_f(
                             iv_customer_code => get_cust_data_rec.ship_cust_code
                           , id_proc_date     => ld_close_date
                         );
          IF ( lt_emp_code IS NULL ) THEN
            lv_outmsg  := xxccp_common_pkg.get_msg(
                            iv_application          => cv_appl_short_name_cok
                          , iv_name                 => cv_msg_cok_00105
                          , iv_token_name1          => cv_tkn_cust_code
                          , iv_token_value1         => get_cust_data_rec.ship_cust_code
                          , iv_token_name2          => cv_tkn_base_code
                          , iv_token_value2         => get_cust_data_rec.sale_base_code
                          );
            lb_retcode := xxcok_common_pkg.put_message_f(
                            in_which                => FND_FILE.OUTPUT
                          , iv_message              => lv_outmsg
                          , in_new_line             => 0
                          );
            RAISE warning_skip_expt;
          END IF;
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD START
          --==================================================
          -- �ŃR�[�h�E�ŗ��擾
          --==================================================
          get_tax_rate(
            ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , it_tax_div                  => get_cust_data_rec.tax_div  -- ����ŋ敪
          , id_target_date              => ld_close_date              -- ����i���ߓ��j
          , ot_tax_code                 => get_cust_data_rec.tax_code -- �ŋ��R�[�h
          , ot_tax_rate                 => get_cust_data_rec.tax_rate -- �ŗ�
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE warning_skip_expt;
          END IF;
-- 2009/10/19 Ver.3.2 [��QE_T3_00631] SCS K.Yamaguchi ADD END
          --==================================================
          -- �����ʔ̎�̋��v�Z�ڋq���ꎞ�\�o�^
          --==================================================
          insert_xt0c(
            ov_errbuf                   => lv_errbuf                  -- �G���[�E���b�Z�[�W
          , ov_retcode                  => lv_retcode                 -- ���^�[���E�R�[�h
          , ov_errmsg                   => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
          , i_get_cust_data_rec         => get_cust_data_rec          -- �ڋq��񃌃R�[�h
          , iv_term_name                => lv_term_name               -- �x������
          , id_close_date               => ld_close_date              -- ���ߓ�
          , id_expect_payment_date      => ld_expect_payment_date     -- �x���\���
          , in_period_year              => ln_period_year             -- ��v�N�x
          , id_amount_fix_date          => ld_amount_fix_date         -- ���z�m���
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD START
          , it_emp_code                 => lt_emp_code                -- �S���҃R�[�h
-- 2010/02/19 Ver.3.8 [��QE_�{�ғ�_01446] SCS S.Moriyama ADD END
          );
          IF( lv_retcode = cv_status_error ) THEN
            lv_end_retcode := cv_status_error;
            RAISE global_process_expt;
          ELSIF( lv_retcode = cv_status_warn ) THEN
            RAISE warning_skip_expt;
          END IF;
        ELSE
          RAISE normal_skip_expt;
        END IF;
        --==================================================
        -- ���팏���J�E���g
        --==================================================
        gn_normal_cnt := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
        -- �����J�E���g
        gn_insert_xt0c_cnt := gn_insert_xt0c_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      EXCEPTION
        WHEN normal_skip_expt THEN
          --==================================================
          -- �X�L�b�v�����J�E���g
          --==================================================
          gn_skip_cnt := gn_skip_cnt + 1;
        WHEN warning_skip_expt THEN
          --==================================================
          -- �ُ팏���J�E���g
          --==================================================
          gn_error_cnt := gn_error_cnt + 1;
          --==================================================
          -- �X�e�[�^�X�ݒ�
          --==================================================
          lv_end_retcode := cv_status_warn;
      END;
    END LOOP cust_data_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END cust_loop;
--
  /**********************************************************************************
   * Procedure Name   : purge_xcbi
   * Description      : �̎�v�Z�όڋq���f�[�^�̍폜�i�ێ����ԊO�j(A-14)
   ***********************************************************************************/
  PROCEDURE purge_xcbi(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xcbi';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_start_date                  DATE           DEFAULT NULL;                 -- �Ɩ���������
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbi_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT /*+ LEADING(flv hl hps hcas hca xcbi) */
             xcbi.cust_bm_info_id       AS cust_bm_info_id
      FROM xxcok_cust_bm_info      xcbi               -- �̎�̋��v�Z�όڋq���e�[�u��
         , hz_cust_accounts        hca                -- �ڋq�}�X�^
         , hz_cust_acct_sites_all  hcas               -- �ڋq�T�C�g�}�X�^
         , hz_parties              hp                 -- �p�[�e�B�}�X�^
         , hz_party_sites          hps                -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations            hl                 -- �ڋq���ݒn�}�X�^
         , fnd_lookup_values       flv                -- �̎�̋��v�Z���s�敪
      WHERE xcbi.cust_code                   = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.attribute1                   = gv_param_proc_type
        AND flv.language                     = cv_lang
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND hl.address3                   LIKE flv.lookup_code || '%'
        AND xcbi.last_fix_closing_date       < id_target_date
      FOR UPDATE OF xcbi.cust_bm_info_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �������擾
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- �̎�̋��v�Z�όڋq���폜���[�v
    --==================================================
    << xcbs_parge_lock_loop >>
    FOR xcbi_parge_lock_rec IN xcbi_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- �̎�̋��v�Z�όڋq���f�[�^�폜
      --==================================================
      BEGIN
        DELETE
        FROM xxcok_cust_bm_info      xcbi
        WHERE xcbi.cust_bm_info_id = xcbi_parge_lock_rec.cust_bm_info_id
        ;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
        -- �����J�E���g
        gn_target_cnt     := gn_target_cnt + 1;
        gn_purge_xcbi_cnt := gn_purge_xcbi_cnt + 1;
        gn_normal_cnt     := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      EXCEPTION
        WHEN OTHERS THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10457
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
      END;
    END LOOP xcbi_parge_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00103
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END purge_xcbi;
--
  /**********************************************************************************
   * Procedure Name   : purge_xcbs
   * Description      : �����ʔ̎�̋��f�[�^�̍폜�i�ێ����ԊO�j(A-2)
   ***********************************************************************************/
  PROCEDURE purge_xcbs(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'purge_xcbs';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
    ld_start_date                  DATE           DEFAULT NULL;                 -- �Ɩ���������
    --==================================================
    -- ���[�J���J�[�\��
    --==================================================
    CURSOR xcbs_parge_lock_cur(
      id_target_date               IN  DATE
    )
    IS
      SELECT /*+ LEADING(flv hl) */
             xcbs.cond_bm_support_id    AS cond_bm_support_id
      FROM xxcok_cond_bm_support   xcbs               -- �����ʔ̎�̋��e�[�u��
         , hz_cust_accounts        hca                -- �ڋq�}�X�^
         , hz_cust_acct_sites_all  hcas               -- �ڋq�T�C�g�}�X�^
         , hz_parties              hp                 -- �p�[�e�B�}�X�^
         , hz_party_sites          hps                -- �p�[�e�B�T�C�g�}�X�^
         , hz_locations            hl                 -- �ڋq���ݒn�}�X�^
         , fnd_lookup_values       flv                -- �̎�̋��v�Z���s�敪
      WHERE xcbs.delivery_cust_code          = hca.account_number
        AND hca.cust_account_id              = hcas.cust_account_id
        AND hca.party_id                     = hp.party_id
        AND hp.party_id                      = hps.party_id
        AND hcas.party_site_id               = hps.party_site_id
        AND hps.location_id                  = hl.location_id
        AND hcas.org_id                      = gn_org_id
        AND flv.lookup_type                  = cv_lookup_type_01
        AND flv.attribute1                   = gv_param_proc_type
        AND flv.language                     = cv_lang
        AND gd_process_date            BETWEEN NVL( flv.start_date_active, gd_process_date )
                                           AND NVL( flv.end_date_active  , gd_process_date )
        AND flv.enabled_flag                 = cv_enable
        AND hl.address3                   LIKE flv.lookup_code || '%'
        AND xcbs.closing_date                < id_target_date
        AND xcbs.cond_bm_interface_status   <> cv_xcbs_if_status_no
        AND xcbs.bm_interface_status        <> cv_xcbs_if_status_no
        AND xcbs.ar_interface_status        <> cv_xcbs_if_status_no
        AND NOT EXISTS ( SELECT 'X'
                         FROM xxcok_backmargin_balance      xbb
                         WHERE xbb.base_code                = xcbs.base_code
                           AND xbb.cust_code                = xcbs.delivery_cust_code
                           AND xbb.supplier_code            = xcbs.supplier_code
                           AND xbb.supplier_site_code       = xcbs.supplier_site_code
                           AND xbb.closing_date             = xcbs.closing_date
                           AND xbb.expect_payment_date      = xcbs.expect_payment_date
                           AND ROWNUM = 1
            )
      FOR UPDATE OF xcbs.cond_bm_support_id NOWAIT
    ;
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �������擾
    --==================================================
    ld_start_date := ADD_MONTHS( TRUNC( gd_process_date, 'MM' ), - gn_sales_retention_period );
    --==================================================
    -- �����ʔ̎�̋��폜���[�v
    --==================================================
    << xcbs_parge_lock_loop >>
    FOR xcbs_parge_lock_rec IN xcbs_parge_lock_cur( ld_start_date ) LOOP
      --==================================================
      -- �����ʔ̎�̋��f�[�^�폜
      --==================================================
      BEGIN
        DELETE
        FROM xxcok_cond_bm_support   xcbs
        WHERE xcbs.cond_bm_support_id = xcbs_parge_lock_rec.cond_bm_support_id
        ;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
        -- �����J�E���g
        gn_target_cnt     := gn_target_cnt + 1;
        gn_purge_xcbs_cnt := gn_purge_xcbs_cnt + 1;
        gn_normal_cnt     := gn_normal_cnt + 1;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      EXCEPTION
        WHEN OTHERS THEN
          lv_outmsg  := xxccp_common_pkg.get_msg(
                          iv_application          => cv_appl_short_name_cok
                        , iv_name                 => cv_msg_cok_10398
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which                => FND_FILE.OUTPUT
                        , iv_message              => lv_outmsg
                        , in_new_line             => 0
                        );
          RAISE error_proc_expt;
      END;
    END LOOP xcbs_parge_lock_loop;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    --*** ���b�N�擾�G���[ ***
    WHEN resource_busy_expt THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00051
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END purge_xcbs;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_proc_date                   IN  VARCHAR2        -- �Ɩ����t
  , iv_proc_type                   IN  VARCHAR2        -- ���s�敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  , iv_proc_flag                   IN  VARCHAR2        -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'init';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- �v���O�������͍��ڂ��o��
    --==================================================
    -- �Ɩ����t
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00022
                  , iv_token_name1          => cv_tkn_business_date
                  , iv_token_value1         => iv_proc_date
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg         -- ���b�Z�[�W
                  , in_new_line             => 0                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 0
                  );
    -- �����敪
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_00044
                  , iv_token_name1          => cv_tkn_proc_type
                  , iv_token_value1         => iv_proc_type
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg          -- ���b�Z�[�W
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--                  , in_new_line             => 1                  -- ���s
                  , in_new_line             => 0                  -- ���s
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD START
--                  , in_new_line             => 1
                  , in_new_line             => 0
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki MOD END
                  );
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    -- �N���t���O
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application          => cv_appl_short_name_cok
                  , iv_name                 => cv_msg_cok_10494
                  , iv_token_name1          => cv_tkn_proc_flag
                  , iv_token_value1         => iv_proc_flag
                  );
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    in_which                => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message              => lv_outmsg          -- ���b�Z�[�W
                  , in_new_line             => 1                  -- ���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                => FND_FILE.LOG
                  , iv_message              => lv_outmsg
                  , in_new_line             => 1
                  );
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �v���O�������͍��ڂ��O���[�o���ϐ��֊i�[
    --==================================================
    gv_param_proc_date := iv_proc_date;
    gv_param_proc_type := iv_proc_type;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    gv_param_proc_flag := iv_proc_flag;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �Ɩ��������t�擾
    --==================================================
    IF( gv_param_proc_date IS NOT NULL ) THEN
      gd_process_date := TO_DATE( gv_param_proc_date, cv_format_fxrrrrmmdd );
    ELSE
      gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
      IF( gd_process_date IS NULL ) THEN
        lv_outmsg  := xxccp_common_pkg.get_msg(
                        iv_application          => cv_appl_short_name_cok
                      , iv_name                 => cv_msg_cok_00028
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which                => FND_FILE.OUTPUT
                      , iv_message              => lv_outmsg
                      , in_new_line             => 0
                      );
        RAISE error_proc_expt;
      END IF;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(MO: �c�ƒP��)
    --==================================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_01 ) );
    IF( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_01
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(��v����ID)
    --==================================================
    gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_02 ) );
    IF( gn_set_of_books_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_02
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋��v�Z�������ԁiFrom�j)
    --==================================================
    gn_bm_support_period_from := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_03 ) );
    IF( gn_bm_support_period_from IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_03
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋��v�Z�������ԁiTo�j)
    --==================================================
    gn_bm_support_period_to := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_04 ) );
    IF( gn_bm_support_period_to IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_04
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(XXCOK:�̎�̋����ێ�����)
    --==================================================
    gn_sales_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_05 ) );
    IF( gn_sales_retention_period IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_05
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d�C���i�ϓ��j�i�ڃR�[�h)
    --==================================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_profile_name_06 );
    IF( gv_elec_change_item_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_06
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�d����_�~�[�R�[�h)
    --==================================================
    gv_vendor_dummy_code := FND_PROFILE.VALUE( cv_profile_name_07 );
    IF( gv_vendor_dummy_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_07
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x������_��������)
    --==================================================
    gv_instantly_term_name := FND_PROFILE.VALUE( cv_profile_name_08 );
    IF( gv_instantly_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_08
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�x������_�f�t�H���g)
    --==================================================
    gv_default_term_name := FND_PROFILE.VALUE( cv_profile_name_09 );
    IF( gv_default_term_name IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_09
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
    --==================================================
    -- �v���t�@�C���擾(�݌ɑg�D�R�[�h_�c�Ƒg�D)
    --==================================================
    gv_organization_code := FND_PROFILE.VALUE( cv_profile_name_10 );
    IF( gv_organization_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_10
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    --==================================================
    -- �v���t�@�C���擾(�̎�̋�_�̔����і��׃��b�N)
    --==================================================
    gv_xsel_data_lock := FND_PROFILE.VALUE( cv_profile_name_11 );
    IF( gv_xsel_data_lock IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appl_short_name_cok
                    , iv_name                 => cv_msg_cok_00003
                    , iv_token_name1          => cv_tkn_profile
                    , iv_token_value1         => cv_profile_name_11
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_outmsg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �ғ����J�����_�R�[�h�擾
    --==================================================
    SELECT mp.calendar_code     AS calendar_code        -- �J�����_�[�R�[�h
    INTO gt_calendar_code
    FROM mtl_parameters       mp
    WHERE mp.organization_code = gv_organization_code
    ;
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** �G���[�I�� ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                     OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_proc_date                   IN  VARCHAR2        -- �Ɩ����t
  , iv_proc_type                   IN  VARCHAR2        -- ���s�敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  , iv_proc_flag                   IN  VARCHAR2        -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'submain';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �X�e�[�^�X������
    --==================================================
    lv_end_retcode := cv_status_normal;
    --==================================================
    -- ��������(A-1)
    --==================================================
    init(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_proc_date            => iv_proc_date          -- �Ɩ����t
    , iv_proc_type            => iv_proc_type          -- �����敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    , iv_proc_flag            => iv_proc_flag          -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    );
    IF( lv_retcode = cv_status_error ) THEN
      lv_end_retcode := cv_status_error;
      RAISE global_process_expt;
    END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    --==================================================
    -- �N���t���O�F1�̏ꍇ�́A�f�[�^�p�[�W���������s
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_1 ) THEN
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      --==================================================
      -- �����ʔ̎�̋��f�[�^�̍폜�i�ێ����ԊO�j(A-2)
      --==================================================
      purge_xcbs(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�v�Z�όڋq���f�[�^�̍폜�i�ێ����ԊO�j(A-14)
      --==================================================
      purge_xcbi(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �p�[�W�����̊m��
      --==================================================
      COMMIT;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    END IF;
    --==================================================
    -- �N���t���O�F3�̏ꍇ�́A�̎�̋��v�Z���������s
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_3 ) THEN
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      --==================================================
      -- �����ʔ̎�̋��f�[�^�̍폜�i���m����z�j(A-3)
      --==================================================
      delete_xcbs(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    END IF;
--
    --==================================================
    -- �N���t���O�F5�̏ꍇ�́A�v�Z�Ώیڋq�ꎞ�\�폜(A-19)�����s
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_5 ) THEN
      --�g�����P�[�g�����{
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcok.xxcok_wk_014a01c_custdata';
    END IF;
--
    --==================================================
    -- �N���t���O�F2�̏ꍇ�́A�v�Z�Ώیڋq�ꎞ�\�쐬�����s
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_2 ) THEN
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      --==================================================
      -- �ڋq��񃋁[�v(A-4)
      --==================================================
      cust_loop(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    END IF;
    --==================================================
    -- �N���t���O�F3�̏ꍇ�́A�̎�̋��v�Z���������s
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_3 ) THEN
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      --==================================================
      -- �̎�����G���[�̍폜����(A-7)
      --==================================================
      delete_xbce(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̔����у��[�v(A-8)
      --==================================================
      sales_result_loop1(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- �̔����у��[�v(A-8)
      --==================================================
      sales_result_loop2(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- �̔����у��[�v(A-8)
      --==================================================
      sales_result_loop3(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- �̔����у��[�v(A-8)
      --==================================================
      sales_result_loop4(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- �̔����у��[�v(A-8)
      --==================================================
      sales_result_loop5(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
      --==================================================
      -- �̔����у��[�v(A-8)
      --==================================================
      sales_result_loop6(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      ELSIF( lv_retcode = cv_status_warn ) THEN
        lv_end_retcode := cv_status_warn;
      END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    END IF;
    --==================================================
    -- �N���t���O�F4�̏ꍇ�́A�̔����эX�V���������s
    --==================================================
    IF ( gv_param_proc_flag = cv_bm_proc_flag_4 ) THEN
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
      --==================================================
      -- �̔����јA�g���ʂ̍X�V(A-12)
      --==================================================
      update_xsel(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
      --==================================================
      -- �̎�v�Z�όڋq���f�[�^�̍X�V(A-15)
      --==================================================
      update_xcbi(
        ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
      , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
      , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF( lv_retcode = cv_status_error ) THEN
        lv_end_retcode := cv_status_error;
        RAISE global_process_expt;
      END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    END IF;
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �o�̓p�����[�^�ݒ�
    --==================================================
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    ov_retcode := lv_end_retcode;
--
  EXCEPTION
    -- *** ���������ʗ�O ***
    WHEN global_process_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := lv_end_retcode;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_proc_date                   IN  VARCHAR2        -- �Ɩ����t
  , iv_proc_type                   IN  VARCHAR2        -- ���s�敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
  , iv_proc_flag                   IN  VARCHAR2        -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
  )
  IS
    --==================================================
    -- ���[�J���萔
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'main';             -- �v���O������
    --==================================================
    -- ���[�J���ϐ�
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- �G���[�E���b�Z�[�W
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- ���^�[���E�R�[�h
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- �o�͗p���b�Z�[�W
    lv_message_code                VARCHAR2(100)  DEFAULT NULL;                 -- �I�����b�Z�[�W�R�[�h
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- ���b�Z�[�W�o�͊֐��߂�l
--
  BEGIN
    --==================================================
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    --==================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode              => lv_retcode
    , ov_errbuf               => lv_errbuf
    , ov_errmsg               => lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT    -- �o�͋敪
                  , iv_message               => NULL               -- ���b�Z�[�W
                  , in_new_line              => 1                  -- ���s
                  );
    --==================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    --==================================================
    submain(
      ov_errbuf               => lv_errbuf             -- �G���[�E���b�Z�[�W
    , ov_retcode              => lv_retcode            -- ���^�[���E�R�[�h
    , ov_errmsg               => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W
    , iv_proc_date            => iv_proc_date          -- �Ɩ����t
    , iv_proc_type            => iv_proc_type          -- ���s�敪
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    , iv_proc_flag            => iv_proc_flag          -- �N���t���O
-- 2012/06/15 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    );
    --==================================================
    -- �̎�����G���[���b�Z�[�W�o��
    --==================================================
    IF( gn_contract_err_cnt > 0 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application           => cv_appl_short_name_cok
                    , iv_name                  => cv_msg_cok_10401
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT
                    , iv_message               => lv_outmsg
                    , in_new_line              => 1
                    );
    END IF;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD START
    --==================================================
    -- �x����s���G���[���b�Z�[�W�o��
    --==================================================
    IF( gn_vendor_err_cnt > 0 ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application           => cv_appl_short_name_cok
                    , iv_name                  => cv_msg_cok_10562
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT
                    , iv_message               => lv_outmsg
                    , in_new_line              => 1
                    );
    END IF;
-- 2018/12/26 Ver.3.18 [E_�{�ғ�_15349] SCSK E.Yazaki ADD END
    --==================================================
    -- �G���[�o��
    --==================================================
    IF( lv_retcode <> cv_status_normal ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.OUTPUT     -- �o�͋敪
                    , iv_message               => lv_errmsg           -- ���b�Z�[�W
                    , in_new_line              => 1                   -- ���s
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                 => FND_FILE.LOG
                    , iv_message               => lv_errbuf
                    , in_new_line              => 0
                    );
    END IF;
    --==================================================
    -- �Ώی����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90000
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- ���������o��(�G���[�����̏ꍇ�A��������:0�� �G���[����:1��  �Ώی���0���̏ꍇ�A��������:0��)
    --==================================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
      -- �G���[�����̏ꍇ�A����������0�����o��
      gn_purge_xcbi_cnt  := 0;  -- �̎�v�Z�όڋq���f�[�^�폜����
      gn_purge_xcbs_cnt  := 0;  -- �����ʔ̎�̋��f�[�^�폜����
      gn_insert_xt0c_cnt := 0;  -- �v�Z�ڋq���ꎞ�\�쐬����
      gn_insert_xcbs_cnt := 0;  -- �̎�̋��v�Z��������
      gn_update_xsel_cnt := 0;  -- �̔����і��׍X�V����
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    ELSE
      IF( gn_target_cnt = 0 ) THEN
        gn_normal_cnt := 0;
      END IF;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90001
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�L�b�v�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �G���[�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => cv_msg_ccp_90002
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD START
    --==================================================
    -- �̎�v�Z�όڋq���f�[�^�폜�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_purge_xcbi_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_purge_xcbi_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �����ʔ̎�̋��f�[�^�폜�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_purge_xcbs_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_purge_xcbs_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �v�Z�ڋq���ꎞ�\�쐬�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_insert_xt0c_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_insert_xt0c_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �̎�̋��v�Z���������o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_insert_xcbs_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_insert_xcbs_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �̔����і��׍X�V�����o��
    --==================================================
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_cok
                  , iv_name                  => cv_msg_cok_10495
                  , iv_token_name1           => cv_tkn_data_name
                  , iv_token_value1          => cv_tkn_val_update_xsel_cnt
                  , iv_token_name2           => cv_tkn_count
                  , iv_token_value2          => TO_CHAR( gn_update_xsel_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 1
                  );
-- 2012/06/19 Ver.3.15 [E_�{�ғ�_08751] SCSK S.Niki ADD END
    --==================================================
    -- �����I�����b�Z�[�W�o��
    --==================================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSE
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    lv_outmsg  := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appl_short_name_ccp
                  , iv_name                  => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_outmsg
                  , in_new_line              => 0
                  );
    --==================================================
    -- �X�e�[�^�X�Z�b�g
    --==================================================
    retcode := lv_retcode;
    --==================================================
    -- �I���X�e�[�^�X�G���[���A���[���o�b�N
    --==================================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** ���ʊ֐�OTHERS��O ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK014A01C;
/
