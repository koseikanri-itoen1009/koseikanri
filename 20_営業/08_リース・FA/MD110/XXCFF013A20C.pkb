CREATE OR REPLACE PACKAGE BODY XXCFF013A20C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A20C(body)
 * Description      : FA�A�h�I��IF
 * MD.050           : MD050_CFF_013_A20_FA�A�h�I��IF
 * Version          : 1.15
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                         ��������                             (A-1)
 *  get_profile_values           �v���t�@�C���l�擾                   (A-2)
 *  chk_period                   ��v���ԃ`�F�b�N                     (A-3)
 *  get_les_trn_add_data         ���[�X���(�ǉ�)�o�^�f�[�^���o       (A-4)
 *  proc_les_trn_add_data        ���[�X���(�ǉ�)�f�[�^����           (A-5)�`(A-10)
 *  get_deprn_method             ���p���@�擾                         (A-8)
 *  insert_les_trn_add_data      ���[�X���(�ǉ�)�o�^                 (A-9)
 *  update_ctrct_line_acct_flag  ���[�X�_�񖾍ח��� ��vIF�t���O�X�V  (A-10)
 *  get_les_trn_trnsf_data       ���[�X���(�U��)�o�^�f�[�^���o       (A-11)
 *  proc_les_trn_trnsf_data      ���[�X���(�U��)�f�[�^����           (A-12)�`(A-16)
 *  lock_trnsf_data              ���[�X���(�U��)�f�[�^���b�N����     (A-12)
 *  insert_les_trn_trnsf_data    ���[�X���(�U��)�o�^                 (A-15)
 *  update_trnsf_data_acct_flag  ���[�X�_�񖾍ח��� ��vIF�t���O�X�V  (A-16)
 *  get_deprn_ccid               �������p���CCID�擾               (A-25)
 *  get_les_trn_retire_data      ���[�X���(���)�o�^�f�[�^���o       (A-17)
 *  insert_les_trn_ritire_data   ���[�X���(���)�o�^                 (A-18)
 *  update_ritire_data_acct_flag ���[�X�_�񖾍ח��� ��vIF�t���O�X�V  (A-19)
 *  get_les_trns_data            FAOIF�o�^�f�[�^���o                  (A-20)
 *  insert_add_oif               �ǉ�OIF�o�^                          (A-21)
 *  insert_trnsf_oif             �U��OIF�o�^                          (A-22)
 *  insert_retire_oif            ���E���pOIF�o�^                      (A-23)
 *  update_les_trns_fa_if_flag   ���[�X��� FA�A�g�t���O�X�V          (A-24)
 *  update_lease_close_period    ���[�X�������ߊ��ԍX�V               (A-27)
 *  get_obj_hist_data            ���������擾                         (A-28)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS�n�ӊw        �V�K�쐬
 *  2008/02/23    1.1   SCS�n�ӊw        [��QCFF_047]�����p�f�[�^���o�����s��Ή�
 *  2009/04/23    1.2   SCS�E��S��      [��QT1_0759]
 *                                       �@���Y�J�e�S��CCID�擾�����ɂ�����ϗp�N���ɁA
 *                                         ���[�X���ԁi���[�X�_��̎x����/12�j��ݒ��ݒ肷��B
 *                                       �A���p���@���擾���ɁA���Y�J�e�S�����p��e�[�u���̌v�Z����
 *                                         ���擾���A�ǉ�OIF�̌v�Z�����֐ݒ肷��B
 *  2009/05/19    1.3   SCS�E��S��      [��QT1_0893]
 *                                       �@���[�X�@�l�ő䒠�Ō������p�̌v�Z���s���Ȃ��B
 *  2009/05/29    1.4   SCS���S��      [��QT1_0893]�ǋL
 *                                       �@���[�X���(�ǉ�)�o�^���̎��Ƌ��p����
 *                                         ���[�X�J�n����ݒ肷��B
 *  2009/06/16    1.5   SCS�����S��      [��QT1_1428]
 *                                       �@���Y�J�e�S��CCID�擾���W�b�N��
 *                                       �p�����[�^�F���Y����̒l��NULL�l�Œ�ɕύX
 *  2009/07/15    1.6   SCS�����L��      [�����e�X�g��Q0000417]
 *                                       ���E���pOIF�̍쐬�����̕ύX
 *  2009/08/31    1.7   SCS�n�ӊw        [�����e�X�g��Q0001058]
 *                                       �����e�X�g��Q0000417�̒ǉ��C��
 *  2012/01/16    1.8   SCSK����         [E_�{�ғ�_08123] ��񎞂�FA�A�g�̏����ɉ�����ǉ�
 *  2016/08/03    1.9   SCSK�s           [E_�{�ғ�_13658]���̋@�ϗp�N���ύX�Ή�
 *  2017/03/29    1.10  SCSK���H         [E_�{�ғ�_14030]�������p������_�֐U�ւ���
 *  2018/03/29    1.11  SCSK���         [E_�{�ғ�_14830]IFRS���[�X���Y�Ή�
 *  2018/09/07    1.12  SCSK���H         [E_�{�ғ�_14830]IFRS���[�X�ǉ��Ή�
 *  2019/05/24    1.13  SCSK���H         [E_�{�ғ�_15727]���̋@�̌������p��̋��_�U�֑Ή�
 *  2019/05/30    1.14  SCSK���H         [E_�{�ғ�_15727]�ǉ��Ή�
 *  2024/10/24    1.15  SCSK�Ԓn         [E_�{�ғ�_20229]���̋@���[�X��10�N���p�Ή�
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
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  --*** �p�x�`�F�b�N�G���[
  payment_type_expt         EXCEPTION;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N(�r�W�[)�G���[
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF013A20C'; -- �p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cmn   CONSTANT VARCHAR2(5) := 'XXCMN';
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP';
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_013a20_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --�v���t�@�C���擾�G���[
  cv_msg_013a20_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; --��v���ԃ`�F�b�N�G���[
  cv_msg_013a20_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --���b�N�G���[
  cv_msg_013a20_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00101'; --���p���@�擾�G���[
  cv_msg_013a20_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00153'; --���[�X���(�ǉ�)�쐬���b�Z�[�W
  cv_msg_013a20_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00154'; --���[�X���(�U��)�쐬���b�Z�[�W
  cv_msg_013a20_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00155'; --���[�X���(���)�쐬���b�Z�[�W
  cv_msg_013a20_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00156'; --FAOIF�쐬���b�Z�[�W
  cv_msg_013a20_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --�擾�Ώۃf�[�^����
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_msg_013a20_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00284'; --�p�x�w��`�F�b�N�G���[
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  cv_msg_013a20_m_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00285'; --�����������b�Z�[�W�iFIN���[�X�䒠�ǉ��j
--  cv_msg_013a20_m_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00286'; --�����������b�Z�[�W�iIFRS���[�X�䒠�ǉ��j
--  cv_msg_013a20_m_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00287'; --�����������b�Z�[�W�iFIN���[�X�䒠�U�ցj
--  cv_msg_013a20_m_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00288'; --�����������b�Z�[�W�iIFRS���[�X�䒠�U�ցj
--  cv_msg_013a20_m_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00289'; --�����������b�Z�[�W�iFIN���[�X�䒠���j
--  cv_msg_013a20_m_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00290'; --�����������b�Z�[�W�iIFRS���[�X�䒠���j
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_013a20_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:��ЃR�[�h_�{��
  cv_msg_013a20_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50077'; --XXCFF:��ЃR�[�h_���ǉ�v
  cv_msg_013a20_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; --XXCFF:����R�[�h_��������
  cv_msg_013a20_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50079'; --XXCFF:�ڋq�R�[�h_��`�Ȃ�
  cv_msg_013a20_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50080'; --XXCFF:��ƃR�[�h_��`�Ȃ�
  cv_msg_013a20_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50081'; --XXCFF:�\��1�R�[�h_��`�Ȃ�
  cv_msg_013a20_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50082'; --XXCFF:�\��2�R�[�h_��`�Ȃ�
  cv_msg_013a20_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50083'; --XXCFF:���Y�J�e�S��_���p���@
  cv_msg_013a20_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50084'; --XXCFF:�\���n_�\���Ȃ�
  cv_msg_013a20_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50085'; --XXCFF:���Ə�_��`�Ȃ�
  cv_msg_013a20_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50086'; --XXCFF:�ꏊ_��`�Ȃ�
  cv_msg_013a20_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50087'; --XXCFF: �����@_����
  cv_msg_013a20_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; --XXCFF: �����@_����
  cv_msg_013a20_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50094'; --���[�X�_�񖾍ח���
  cv_msg_013a20_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50095'; --XXCFF: �{�ЍH��敪_�{��
  cv_msg_013a20_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50096'; --XXCFF: �{�ЍH��敪_�H��
  cv_msg_013a20_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50097'; --���p���@
  cv_msg_013a20_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50098'; --�_�񖾍ד���ID
  cv_msg_013a20_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50099'; --���Y�J�e�S��CCID
  cv_msg_013a20_t_029 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50023'; --���[�X��������
  cv_msg_013a20_t_030 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50112'; --���[�X���
  cv_msg_013a20_t_031 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50142'; --���[�X����i�ǉ��j���
  cv_msg_013a20_t_032 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50143'; --���[�X����i�U�ցj���
  cv_msg_013a20_t_033 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50144'; --���[�X����i���j���
  cv_msg_013a20_t_034 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50145'; --FAOIF�A�g���
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_msg_013a20_t_035 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50287'; -- XXCFF:�䒠��_FIN���[�X�䒠
  cv_msg_013a20_t_036 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50324'; -- XXCFF:�䒠��_IFRS���[�X�䒠
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  cv_msg_013a20_t_037 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50329'; -- XXCFF:IFRS����ID
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  -- ***�g�[�N����
  -- �v���t�@�C����
  cv_tkn_prof     CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type  CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period   CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_info     CONSTANT VARCHAR2(20) := 'INFO';
  cv_tkn_get_data CONSTANT VARCHAR2(20) := 'GET_DATA';
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_tkn_ls_cls   CONSTANT VARCHAR2(20) := 'LEASE_CLASS';
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***�v���t�@�C��
--
  -- ��ЃR�[�h_�{��
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';
  -- ��ЃR�[�h_���ǉ�v
  cv_comp_cd_sagara       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_SAGARA';
  -- ����R�[�h_��������
  cv_dep_cd_chosei        CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';
  -- �ڋq�R�[�h_��`�Ȃ�
  cv_ptnr_cd_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_PTNR_CD_DAMMY';
  -- ��ƃR�[�h_��`�Ȃ�
  cv_busi_cd_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_BUSI_CD_DAMMY';
  -- �\��1�R�[�h_��`�Ȃ�
  cv_project_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_PROJECT_DAMMY';
  -- �\��2�R�[�h_��`�Ȃ�
  cv_future_dammy         CONSTANT VARCHAR2(30) := 'XXCFF1_FUTURE_DAMMY';
  -- ���Y�J�e�S��_���p���@
  cv_cat_dprn_lease       CONSTANT VARCHAR2(30) := 'XXCFF1_CAT_DPRN_LEASE';
  -- �\���n_�\���Ȃ�
  cv_dclr_place_no_report CONSTANT VARCHAR2(30) := 'XXCFF1_DCLR_PLACE_NO_REPORT';
  -- ���Ə�_��`�Ȃ�
  cv_mng_place_dammy      CONSTANT VARCHAR2(30) := 'XXCFF1_MNG_PLACE_DAMMY';
  -- �ꏊ_��`�Ȃ�
  cv_place_dammy          CONSTANT VARCHAR2(30) := 'XXCFF1_PLACE_DAMMY';
  -- �����@_����
  cv_prt_conv_cd_st       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ST';
  -- �����@_����
  cv_prt_conv_cd_ed       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';
  -- �{�ЍH��敪_�{��
  cv_own_comp_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_ITOEN';
  -- �{�ЍH��敪_�H��
  cv_own_comp_sagara      CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_SAGARA';
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  -- �䒠��_FIN���[�X�䒠
  cv_fin_lease_books      CONSTANT VARCHAR2(35) := 'XXCFF1_FIN_LEASE_BOOKS';
  -- �䒠��_IFRS���[�X�䒠
  cv_ifrs_lease_books     CONSTANT VARCHAR2(35) := 'XXCFF1_IFRS_LEASE_BOOKS';
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  -- XXCFF:IFRS����ID
  cv_set_of_books_id_ifrs CONSTANT VARCHAR2(35) := 'XXCFF1_IFRS_SET_OF_BKS_ID';
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  -- ***�t�@�C���o��
--
  -- ���b�Z�[�W�o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';
  -- ���O�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';
--
  -- ***�_��X�e�[�^�X
  -- �_��
  cv_ctrt_ctrt           CONSTANT VARCHAR2(3) := '202';
  -- ���ύX
  cv_ctrt_info_change    CONSTANT VARCHAR2(3) := '209';
-- 2016/08/03 Ver.1.9 Y.Koh ADD Start
  -- �ă��[�X
  cv_ctrt_re_lease       CONSTANT VARCHAR2(3) := '203';
-- 2016/08/03 Ver.1.9 Y.Koh ADD End
  -- ����
  cv_ctrt_manryo         CONSTANT VARCHAR2(3) := '204';
  -- ���r���(���ȓs��)
  cv_ctrt_cancel_jiko    CONSTANT VARCHAR2(3) := '206';
  -- ���r���(�ی��Ή�)
  cv_ctrt_cancel_hoken   CONSTANT VARCHAR2(3) := '207';
  -- ���r���(����)
  cv_ctrt_cancel_manryo  CONSTANT VARCHAR2(3) := '208';
--
  -- ***�����X�e�[�^�X
  -- �ړ�
  cv_obj_move        CONSTANT VARCHAR2(3) := '105';
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  -- �������ύX
  cv_obj_modify      CONSTANT VARCHAR2(3) := '106';
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 0000417 2009/07/10 ADD START --
  -- ����
  cv_obj_manryo         CONSTANT VARCHAR2(3) := '107';
  -- ���r���(���ȓs��)
  cv_obj_cancel_jiko    CONSTANT VARCHAR2(3) := '110';
  -- ���r���(�ی��Ή�)
  cv_obj_cancel_hoken   CONSTANT VARCHAR2(3) := '111';
  -- ���r���(����)
  cv_obj_cancel_manryo  CONSTANT VARCHAR2(3) := '112';
-- 0000417 2009/07/10 ADD END --
--
  -- ***���[�X���
  cv_lease_kind_fin  CONSTANT VARCHAR2(1) := '0';  -- Fin���[�X
  cv_lease_kind_lfin CONSTANT VARCHAR2(1) := '2';  -- ��Fin���[�X
--
  -- ***��vIF�t���O
  cv_if_yet  CONSTANT VARCHAR2(1) := '1';  -- �����M
  cv_if_aft  CONSTANT VARCHAR2(1) := '2';  -- �A�g��
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  cv_if_out  CONSTANT VARCHAR2(1) := '3';  -- �ΏۊO
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***���[�X�敪
  cv_original  CONSTANT VARCHAR2(1) := '1';  -- ���_��
-- 2016/08/03 Ver.1.9 Y.Koh ADD Start
  cv_re_lease  CONSTANT VARCHAR2(1) := '2';  -- �ă��[�X
-- 2016/08/03 Ver.1.9 Y.Koh ADD End
--
-- T1_0759 2009/04/23 ADD START --
  -- ***����
  cv_months  CONSTANT NUMBER(2) := 12;  
-- T1_0759 2009/04/23 ADD END   --
--
-- 2016/08/03 Ver.1.9 Y.Koh ADD Start
  -- ***���[�X���
  cv_lease_class_vd  CONSTANT VARCHAR2(2) := '11';  -- ���̋@
-- 2016/08/03 Ver.1.9 Y.Koh ADD End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--
  -- ***����^�C�v
  cv_transaction_type_2  CONSTANT VARCHAR2(1) := '2';  -- �U��
  cv_transaction_type_4  CONSTANT VARCHAR2(1) := '4';  -- ����U��
--
  -- ***�Q�ƃ^�C�v
  cv_xxcff1_lease_class_check CONSTANT VARCHAR2(30) := 'XXCFF1_LEASE_CLASS_CHECK';
--
  -- ***�t���O����p
  cv_flg_y               CONSTANT VARCHAR2(1) := 'Y';
  cv_flg_n               CONSTANT VARCHAR2(1) := 'N';
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  -- ���[�X����
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  cv_lease_cls_chk1      CONSTANT VARCHAR2(1) := '1';
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
  cv_lease_cls_chk2      CONSTANT VARCHAR2(1) := '2';  -- ���[�X���茋��
  -- �p�x
  cv_payment_type0       CONSTANT VARCHAR2(1) := '0';  -- �p�x�F�u���v
  cv_payment_type1       CONSTANT VARCHAR2(1) := '1';  -- �p�x�F�u�N�v
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_deprn_run_ttype             IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype        IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_histories.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_histories.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_contract_histories.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_history_num_ttype           IS TABLE OF xxcff_contract_histories.history_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_contract_headers.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype            IS TABLE OF xxcff_contract_histories.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_category_ttype        IS TABLE OF xxcff_contract_histories.asset_category%TYPE INDEX BY PLS_INTEGER;
  TYPE g_comments_ttype              IS TABLE OF xxcff_contract_headers.comments%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_years_ttype         IS TABLE OF xxcff_contract_headers.payment_years%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_date_ttype         IS TABLE OF xxcff_contract_headers.contract_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype         IS TABLE OF xxcff_contract_histories.original_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_quantity_ttype              IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_les_asset_acct_ttype        IS TABLE OF xxcff_lease_class_v.les_asset_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_acct_ttype            IS TABLE OF xxcff_lease_class_v.deprn_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_sub_acct_ttype        IS TABLE OF xxcff_lease_class_v.deprn_sub_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_category_ccid_ttype         IS TABLE OF fa_categories.category_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ccid_ttype         IS TABLE OF fa_locations.location_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_ccid_ttype            IS TABLE OF gl_code_combinations.code_combination_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_method_ttype          IS TABLE OF fa_category_book_defaults.deprn_method%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_number_ttype          IS TABLE OF fa_additions_b.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment_ttype               IS TABLE OF gl_code_combinations.segment1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_match_flag_ttype    IS TABLE OF xxcff_pay_planning.payment_match_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fa_transaction_id_ttype     IS TABLE OF xxcff_fa_transactions.fa_transaction_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_frequency_ttype     IS TABLE OF xxcff_contract_headers.payment_frequency%TYPE INDEX BY PLS_INTEGER;
  TYPE g_life_in_months_ttype        IS TABLE OF xxcff_contract_histories.life_in_months%TYPE INDEX BY PLS_INTEGER;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  TYPE g_segment2_ttype              IS TABLE OF gl_code_combinations.segment2%TYPE INDEX BY PLS_INTEGER;
  TYPE g_transaction_type_ttype      IS TABLE OF xxcff_fa_transactions.transaction_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_customer_code_ttype         IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_vd_cust_flag_ttype          IS TABLE OF xxcff_lease_class_v.vd_cust_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_dept_tran_flg_ttype         IS TABLE OF fnd_lookup_values.attribute1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment5_ttype              IS TABLE OF gl_code_combinations.segment5%TYPE INDEX BY PLS_INTEGER;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  TYPE g_lease_type_ttype            IS TABLE OF xxcff_contract_headers.lease_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_type_ttype          IS TABLE OF xxcff_contract_headers.payment_type%TYPE INDEX BY PLS_INTEGER;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  TYPE g_fin_coop_ttype              IS TABLE OF fnd_lookup_values.attribute4%TYPE INDEX BY PLS_INTEGER;
--  TYPE g_ifrs_coop_ttype             IS TABLE OF fnd_lookup_values.attribute5%TYPE INDEX BY PLS_INTEGER;
--  TYPE g_lease_cls_chk_ttype         IS TABLE OF fnd_lookup_values.attribute7%TYPE INDEX BY PLS_INTEGER;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
  TYPE g_fully_retired_ttype         IS TABLE OF fa_books.period_counter_fully_retired%TYPE INDEX BY PLS_INTEGER;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_deprn_run_tab                       g_deprn_run_ttype;
  g_book_type_code_tab                  g_book_type_code_ttype;
  g_contract_header_id_tab              g_contract_header_id_ttype;
  g_contract_line_id_tab                g_contract_line_id_ttype;
  g_object_header_id_tab                g_object_header_id_ttype;
  g_history_num_tab                     g_history_num_ttype;
  g_lease_class_tab                     g_lease_class_ttype;
  g_lease_kind_tab                      g_lease_kind_ttype;
  g_asset_category_tab                  g_asset_category_ttype;
  g_comments_tab                        g_comments_ttype;
  g_payment_years_tab                   g_payment_years_ttype;
  g_contract_date_tab                   g_contract_date_ttype;
  g_original_cost_tab                   g_original_cost_ttype;
  g_quantity_tab                        g_quantity_ttype;
  g_department_code_tab                 g_department_code_ttype;
  g_owner_company_tab                   g_owner_company_ttype;
  g_les_asset_acct_tab                  g_les_asset_acct_ttype;
  g_deprn_acct_tab                      g_deprn_acct_ttype;
  g_deprn_sub_acct_tab                  g_deprn_sub_acct_ttype;
  g_category_ccid_tab                   g_category_ccid_ttype;
  g_location_ccid_tab                   g_location_ccid_ttype;
  g_deprn_ccid_tab                      g_deprn_ccid_ttype;
  g_deprn_method_tab                    g_deprn_method_ttype;
  g_asset_number_tab                    g_asset_number_ttype;
  g_trnsf_from_comp_cd_tab              g_segment_ttype;
  g_trnsf_to_comp_cd_tab                g_segment_ttype;
  g_payment_match_flag_tab              g_payment_match_flag_ttype;
  g_fa_transaction_id_tab               g_fa_transaction_id_ttype;
  g_payment_frequency_tab               g_payment_frequency_ttype;
  g_life_in_months_tab                  g_life_in_months_ttype;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  g_trnsf_from_dep_cd_tab               g_segment2_ttype;
  g_transaction_type_tab                g_transaction_type_ttype;
  g_customer_code_tab                   g_customer_code_ttype;
  g_vd_cust_flag_tab                    g_vd_cust_flag_ttype;
  g_dept_tran_flg_tab                   g_dept_tran_flg_ttype;
  g_trnsf_from_cust_cd_tab              g_segment5_ttype;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  g_lease_type_tab                      g_lease_type_ttype;
  g_payment_type_tab                    g_payment_type_ttype;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  g_fin_coop_tab                        g_fin_coop_ttype;
--  g_ifrs_coop_tab                       g_ifrs_coop_ttype;
--  g_lease_cls_chk_tab                   g_lease_cls_chk_ttype;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
  g_fully_retired_tab                   g_fully_retired_ttype;
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
  -- ***��������
  -- ���[�X���(�ǉ�)�o�^�����ɂ����錏��
  gn_les_add_target_cnt    NUMBER;     -- �Ώی���
  gn_les_add_normal_cnt    NUMBER;     -- ���팏��
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  gn_les_add_ifrs_cnt      NUMBER;     -- ���팏��(IFRS)
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
  gn_les_add_error_cnt     NUMBER;     -- �G���[����
  -- ���[�X���(�U��)�o�^�����ɂ����錏��
  gn_les_trnsf_target_cnt  NUMBER;     -- �Ώی���
  gn_les_trnsf_normal_cnt  NUMBER;     -- ���팏��
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  gn_les_trnsf_ifrs_cnt    NUMBER;     -- ���팏��(IFRS)
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
  gn_les_trnsf_error_cnt   NUMBER;     -- �G���[����
  -- ���[�X���(���)�o�^�����ɂ����錏��
  gn_les_retire_target_cnt NUMBER;     -- �Ώی���
  gn_les_retire_normal_cnt NUMBER;     -- ���팏��
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--  gn_les_retire_ifrs_cnt   NUMBER;     -- ���팏��(IFRS)
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
  gn_les_retire_error_cnt  NUMBER;     -- �G���[����
  -- FAOIF�o�^�����ɂ����錏��
  gn_fa_oif_target_cnt     NUMBER;     -- �Ώی���
  gn_fa_oif_error_cnt      NUMBER;     -- �G���[����
  -- �ǉ�OIF�o�^����
  gn_add_oif_ins_cnt       NUMBER;
  -- �U��OIF�o�^����
  gn_trnsf_oif_ins_cnt     NUMBER;
  -- ���OIF�o�^����
  gn_retire_oif_ins_cnt    NUMBER;
--
  -- �����l���
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name VARCHAR2(100);
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  -- �p�����[�^�䒠��
  gv_book_type_code VARCHAR2(100);
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
  -- ���Y�J�e�S��CCID
  gt_category_id  fa_categories.category_id%TYPE;
  -- ���Ə�CCID
  gt_location_id  fa_locations.location_id%TYPE;
--
  -- ***�v���t�@�C���l
  -- ��ЃR�[�h_�{��
  gv_comp_cd_itoen         VARCHAR2(100);
  -- ��ЃR�[�h_���ǉ�v
  gv_comp_cd_sagara        VARCHAR2(100);
  -- ����R�[�h_��������
  gv_dep_cd_chosei         VARCHAR2(100);
  -- �ڋq�R�[�h_��`�Ȃ�
  gv_ptnr_cd_dammy         VARCHAR2(100);
  -- ��ƃR�[�h_��`�Ȃ�
  gv_busi_cd_dammy         VARCHAR2(100);
  -- �\��1�R�[�h_��`�Ȃ�
  gv_project_dammy         VARCHAR2(100);
  -- �\��2�R�[�h_��`�Ȃ�
  gv_future_dammy          VARCHAR2(100);
  -- ���Y�J�e�S��_���p���@
  gv_cat_dprn_lease        VARCHAR2(100);
  -- �\���n_�\���Ȃ�
  gv_dclr_place_no_report  VARCHAR2(100);
  -- ���Ə�_��`�Ȃ�
  gv_mng_place_dammy       VARCHAR2(100);
  -- �ꏊ_��`�Ȃ�
  gv_place_dammy           VARCHAR2(100);
  -- �����@_����
  gv_prt_conv_cd_st        VARCHAR2(100);
  -- �����@_����
  gv_prt_conv_cd_ed        VARCHAR2(100);
  -- �{�ЍH��敪_�{��
  gv_own_comp_itoen        VARCHAR2(100);
  -- �{�ЍH��敪_�H��
  gv_own_comp_sagara       VARCHAR2(100);
-- 2018/03/29 Ver1.11 Otsuka ADD Start
  -- �䒠��_FIN���[�X�䒠
  gv_fin_lease_books       VARCHAR2(100);
  -- �䒠��_IFRS���[�X�䒠
  gv_ifrs_lease_books      VARCHAR2(100);
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
  -- XXCFF:IFRS����ID
  gn_set_of_books_id_ifrs  NUMBER;
  -- ���[�X���菈��
  gv_lease_class_att7      VARCHAR2(1);
  -- ���[�X���
  gv_lease_kind            VARCHAR2(1);
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : �R���N�V�����폜
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�R���N�V���������z��̍폜
    g_deprn_run_tab.DELETE;
    g_book_type_code_tab.DELETE;
    g_contract_header_id_tab.DELETE;
    g_contract_line_id_tab.DELETE;
    g_object_header_id_tab.DELETE;
    g_history_num_tab.DELETE;
    g_lease_class_tab.DELETE;
    g_lease_kind_tab.DELETE;
    g_asset_category_tab.DELETE;
    g_comments_tab.DELETE;
    g_payment_years_tab.DELETE;
    g_contract_date_tab.DELETE;
    g_original_cost_tab.DELETE;
    g_quantity_tab.DELETE;
    g_department_code_tab.DELETE;
    g_owner_company_tab.DELETE;
    g_les_asset_acct_tab.DELETE;
    g_deprn_acct_tab.DELETE;
    g_deprn_sub_acct_tab.DELETE;
    g_category_ccid_tab.DELETE;
    g_location_ccid_tab.DELETE;
    g_deprn_ccid_tab.DELETE;
    g_deprn_method_tab.DELETE;
    g_asset_number_tab.DELETE;
    g_trnsf_from_comp_cd_tab.DELETE;
    g_trnsf_to_comp_cd_tab.DELETE;
    g_payment_match_flag_tab.DELETE;
    g_fa_transaction_id_tab.DELETE;
    g_payment_frequency_tab.DELETE;
    g_life_in_months_tab.DELETE;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    g_trnsf_from_dep_cd_tab.DELETE;
    g_transaction_type_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_trnsf_from_cust_cd_tab.DELETE;
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    g_lease_type_tab.DELETE;
    g_payment_type_tab.DELETE;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    g_fin_coop_tab.DELETE;
--    g_ifrs_coop_tab.DELETE;
--    g_lease_cls_chk_tab.DELETE;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
    g_fully_retired_tab.DELETE;
-- 2018/03/29 Ver1.11 Otsuka ADD End
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
  END delete_collections;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
  /**********************************************************************************
   * Procedure Name   : get_obj_hist_data
   * Description      : ���������擾 (A-28)
   ***********************************************************************************/
  PROCEDURE get_obj_hist_data(
     it_object_header_id  IN  xxcff_object_headers.object_header_id%TYPE    -- 1.����ID
    ,ot_m_owner_company   OUT xxcff_object_histories.m_owner_company%TYPE   -- 2.�ړ����{��/�H��
    ,ot_m_department_code OUT xxcff_object_histories.m_department_code%TYPE -- 3.�ړ����Ǘ�����
    ,ot_customer_code     OUT xxcff_object_histories.customer_code%TYPE     -- 4.�C���O���ڋq�R�[�h
    ,ov_errbuf            OUT VARCHAR2                                      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT VARCHAR2                                      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT VARCHAR2)                                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_obj_hist_data'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      --���[�X�����������擾�ł���ꍇ�̓��[�X���������̈ړ����Ǘ�����A�ړ����{�Ё^�H���ݒ肷��B
      BEGIN
        SELECT   xoh1.m_department_code  m_department_code  -- �ړ����Ǘ�����
                ,xoh1.m_owner_company    m_owner_company    -- �ړ����{�Ё^�H��
        INTO     ot_m_department_code
                ,ot_m_owner_company
        FROM     (SELECT xoh.m_department_code  m_department_code
                        ,xoh.m_owner_company    m_owner_company
                  FROM   xxcff_object_histories xoh
                  WHERE  xoh.object_header_id =  it_object_header_id
                  AND    xoh.accounting_date  >  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                  AND    xoh.object_status    =  cv_obj_move
                  ORDER BY xoh.creation_date ASC
                 ) xoh1
        WHERE    rownum = 1;
      --�Y���f�[�^�����݂��Ȃ��ꍇ��NULL��ݒ肷��B
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ot_m_department_code := NULL;
          ot_m_owner_company   := NULL;
      END;
--
      --���[�X�����������擾�ł���ꍇ�̓��[�X���������̌ڋq�R�[�h��ݒ肷��B
      BEGIN
        SELECT   xoh1.customer_code  customer_code  -- �ڋq�R�[�h
        INTO     ot_customer_code
        FROM     (SELECT xoh.customer_code  customer_code
                  FROM   xxcff_object_histories xoh
                  WHERE  xoh.object_header_id =  it_object_header_id
                  AND    xoh.accounting_date  <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
-- 2019/05/30 Ver.1.14 Y.Shoji MOD Start
                  AND    xoh.object_status    IN (cv_obj_move ,cv_obj_modify) -- 105:�ړ��A106�F���ύX
-- 2019/05/30 Ver.1.14 Y.Shoji MOD End
                  ORDER BY xoh.creation_date DESC
-- 2019/05/30 Ver.1.14 Y.Shoji ADD Start
                          ,xoh.object_status DESC -- �ړ��Ə��ύX�������̏ꍇ�A���ύX���擾
-- 2019/05/30 Ver.1.14 Y.Shoji ADD End
                 ) xoh1
        WHERE    rownum = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ot_customer_code := NULL;
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
  END get_obj_hist_data;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : update_lease_close_period
   * Description      : ���[�X�������ߊ��ԍX�V (A-27)
   ***********************************************************************************/
  PROCEDURE update_lease_close_period(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_lease_close_period'; -- �v���O������
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
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    lt_set_of_books_id xxcff_lease_closed_periods.set_of_books_id%TYPE;  -- ����ID
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    -- IFRS���[�X�䒠�̏ꍇ
    IF (gv_book_type_code = gv_ifrs_lease_books) THEN
      lt_set_of_books_id := gn_set_of_books_id_ifrs;
    -- IFRS���[�X�䒠�ȊO�̏ꍇ
    ELSE
      lt_set_of_books_id := g_init_rec.set_of_books_id;
    END IF;
--
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    UPDATE xxcff_lease_closed_periods
    SET
           period_name            = gv_period_name            -- ��v����
          ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             = cn_request_id             -- �v��ID
          ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
          ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
          ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
    WHERE
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--           set_of_books_id        = g_init_rec.set_of_books_id
           set_of_books_id        = lt_set_of_books_id
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
    ;
--
    -- ���C�������O�Ƀ��[�X�������ߊ��Ԃ̍X�V���m��
    COMMIT;
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
  END update_lease_close_period;
--
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : update_les_trns_fa_if_flag
   * Description      : ���[�X��� FA�A�g�t���O�X�V (A-24)
   ***********************************************************************************/
  PROCEDURE update_les_trns_fa_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_les_trns_fa_if_flag'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT
      UPDATE xxcff_fa_transactions
      SET
             fa_if_flag             = cv_if_aft                 -- FA�A�g�t���O 
            ,fa_if_date             = g_init_rec.process_date   -- �v���
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             fa_transaction_id      = g_fa_transaction_id_tab(ln_loop_cnt)
-- 2018/03/29 Ver1.11 Otsuka ADD Start
        AND  fa_if_flag             = cv_if_yet
-- 2018/03/29 Ver1.11 Otsuka ADD End
      ;
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
  END update_les_trns_fa_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_retire_oif
   * Description      : ���E���pOIF�o�^ (A-23)
   ***********************************************************************************/
  PROCEDURE insert_retire_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_retire_oif'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    INSERT INTO xx01_retire_oif(
      retire_oif_id                   -- RETIRE_OIF_ID
     ,book_type_code                  -- �䒠��
     ,asset_number                    -- ���Y�ԍ�
     ,created_by                      -- �쐬��
     ,creation_date                   -- �쐬��
     ,last_updated_by                 -- �ŏI�X�V��
     ,last_update_date                -- �ŏI�X�V��
     ,last_update_login               -- �ŏI�X�V۸޲�
     ,request_id                      -- ظ���ID
     ,program_application_id          -- ���ع����ID
     ,program_id                      -- ��۸���ID
     ,program_update_date             -- ��۸��эŏI�X�V��
     ,date_retired                    -- ������p��
     ,posting_flag                    -- �]�L�����׸�
     ,status                          -- �ð��
     ,cost_retired                    -- ������p�擾���i
     ,proceeds_of_sale                -- ���p���z
     ,cost_of_removal                 -- �P����p
     ,retirement_prorate_convention   -- ������p�N�x���p
    )
    SELECT
      xx01_retire_oif_s.NEXTVAL           -- ID
     ,xxcff_fa_trn.book_type_code         -- �䒠
     ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
     ,cn_created_by                       -- �쐬��ID
     ,cd_creation_date                    -- �쐬��
     ,cn_last_updated_by                  -- �ŏI�X�V��
     ,cd_last_update_date                 -- �ŏI�X�V��
     ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
     ,cn_request_id                       -- ���N�G�X�gID
     ,cn_program_application_id           -- �A�v���P�[�V����ID
     ,cn_program_id                       -- �v���O����ID
     ,cd_program_update_date              -- �v���O�����ŏI�X�V��
     ,xxcff_fa_trn.retirement_date        -- ������p��
     ,'Y'                                 -- �]�L�`�F�b�N�t���O
     ,'PENDING'                           -- �X�e�[�^�X
     ,xxcff_fa_trn.cost_retired           -- ������p�擾���i
     ,0                                   -- ���p���z
     ,0                                   -- �P����p
     ,xxcff_fa_trn.ret_prorate_convention -- ������p�N�x���p
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 3 -- ���
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ;
--
    -- ���OIF�o�^�����J�E���g
    gn_retire_oif_ins_cnt := SQL%ROWCOUNT;
--
-- T1_0893 2009/05/19 ADD START --
-- ���[�X���Y�䒠�̏ꍇ�̓��[�X�@�l�ł̃f�[�^���쐬����B
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--    INSERT INTO xx01_retire_oif(
--      retire_oif_id                   -- RETIRE_OIF_ID
--     ,book_type_code                  -- �䒠��
--     ,asset_number                    -- ���Y�ԍ�
--     ,created_by                      -- �쐬��
--     ,creation_date                   -- �쐬��
--     ,last_updated_by                 -- �ŏI�X�V��
--     ,last_update_date                -- �ŏI�X�V��
--     ,last_update_login               -- �ŏI�X�V۸޲�
--     ,request_id                      -- ظ���ID
--     ,program_application_id          -- ���ع����ID
--     ,program_id                      -- ��۸���ID
--     ,program_update_date             -- ��۸��эŏI�X�V��
--     ,date_retired                    -- ������p��
--     ,posting_flag                    -- �]�L�����׸�
--     ,status                          -- �ð��
--     ,cost_retired                    -- ������p�擾���i
--     ,proceeds_of_sale                -- ���p���z
--     ,cost_of_removal                 -- �P����p
--     ,retirement_prorate_convention   -- ������p�N�x���p
--    )
--    SELECT
--      xx01_retire_oif_s.NEXTVAL           -- ID
--     ,xlkv.book_type_code_tax             -- �䒠
--     ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
--     ,cn_created_by                       -- �쐬��ID
--     ,cd_creation_date                    -- �쐬��
--     ,cn_last_updated_by                  -- �ŏI�X�V��
--     ,cd_last_update_date                 -- �ŏI�X�V��
--     ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
--     ,cn_request_id                       -- ���N�G�X�gID
--     ,cn_program_application_id           -- �A�v���P�[�V����ID
--     ,cn_program_id                       -- �v���O����ID
--     ,cd_program_update_date              -- �v���O�����ŏI�X�V��
--     ,xxcff_fa_trn.retirement_date        -- ������p��
--     ,'Y'                                 -- �]�L�`�F�b�N�t���O
--     ,'PENDING'                           -- �X�e�[�^�X
--     ,xxcff_fa_trn.cost_retired           -- ������p�擾���i
--     ,0                                   -- ���p���z
--     ,0                                   -- �P����p
--     ,xxcff_fa_trn.ret_prorate_convention -- ������p�N�x���p
--    FROM
--          xxcff_fa_transactions  xxcff_fa_trn
--         ,xxcff_contract_lines   xxcff_co_line
--         ,xxcff_lease_kind_v     xlkv
--    WHERE
--          xxcff_fa_trn.period_name        = gv_period_name
--      AND xxcff_fa_trn.fa_if_flag         = cv_if_yet
--      AND xxcff_fa_trn.transaction_type   = 3                     -- ���
--      AND xxcff_fa_trn.contract_header_id = xxcff_co_line.contract_header_id
--      AND xxcff_fa_trn.contract_line_id   = xxcff_co_line.contract_line_id
--      AND xxcff_co_line.lease_kind        = xlkv.lease_kind_code  -- fin���[�X 
--      AND xlkv.lease_kind_code            = cv_lease_kind_fin     -- fin���[�X
--    ;
--
--    -- ���OIF�o�^�����J�E���g
--    gn_retire_oif_ins_cnt := gn_retire_oif_ins_cnt + SQL%ROWCOUNT;
    IF ( gv_book_type_code = gv_fin_lease_books ) THEN
      INSERT INTO xx01_retire_oif(
        retire_oif_id                   -- RETIRE_OIF_ID
       ,book_type_code                  -- �䒠��
       ,asset_number                    -- ���Y�ԍ�
       ,created_by                      -- �쐬��
       ,creation_date                   -- �쐬��
       ,last_updated_by                 -- �ŏI�X�V��
       ,last_update_date                -- �ŏI�X�V��
       ,last_update_login               -- �ŏI�X�V۸޲�
       ,request_id                      -- ظ���ID
       ,program_application_id          -- ���ع����ID
       ,program_id                      -- ��۸���ID
       ,program_update_date             -- ��۸��эŏI�X�V��
       ,date_retired                    -- ������p��
       ,posting_flag                    -- �]�L�����׸�
       ,status                          -- �ð��
       ,cost_retired                    -- ������p�擾���i
       ,proceeds_of_sale                -- ���p���z
       ,cost_of_removal                 -- �P����p
       ,retirement_prorate_convention   -- ������p�N�x���p
      )
      SELECT
        xx01_retire_oif_s.NEXTVAL           -- ID
       ,xlkv.book_type_code_tax             -- �䒠
       ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
       ,cn_created_by                       -- �쐬��ID
       ,cd_creation_date                    -- �쐬��
       ,cn_last_updated_by                  -- �ŏI�X�V��
       ,cd_last_update_date                 -- �ŏI�X�V��
       ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
       ,cn_request_id                       -- ���N�G�X�gID
       ,cn_program_application_id           -- �A�v���P�[�V����ID
       ,cn_program_id                       -- �v���O����ID
       ,cd_program_update_date              -- �v���O�����ŏI�X�V��
       ,xxcff_fa_trn.retirement_date        -- ������p��
       ,'Y'                                 -- �]�L�`�F�b�N�t���O
       ,'PENDING'                           -- �X�e�[�^�X
       ,xxcff_fa_trn.cost_retired           -- ������p�擾���i
       ,0                                   -- ���p���z
       ,0                                   -- �P����p
       ,xxcff_fa_trn.ret_prorate_convention -- ������p�N�x���p
      FROM
            xxcff_fa_transactions  xxcff_fa_trn
           ,xxcff_contract_lines   xxcff_co_line
           ,xxcff_lease_kind_v     xlkv
      WHERE
            xxcff_fa_trn.period_name        = gv_period_name
        AND xxcff_fa_trn.fa_if_flag         = cv_if_yet
        AND xxcff_fa_trn.transaction_type   = 3                     -- ���
        AND xxcff_fa_trn.book_type_code     = gv_book_type_code     -- FIN���[�X�䒠
        AND xxcff_fa_trn.contract_header_id = xxcff_co_line.contract_header_id
        AND xxcff_fa_trn.contract_line_id   = xxcff_co_line.contract_line_id
        AND xxcff_co_line.lease_kind        = xlkv.lease_kind_code  -- fin���[�X 
        AND xlkv.lease_kind_code            = cv_lease_kind_fin     -- fin���[�X
      ;
--
      -- ���OIF�o�^�����J�E���g
      gn_retire_oif_ins_cnt := gn_retire_oif_ins_cnt + SQL%ROWCOUNT;
--
    END IF;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
--
-- T1_0893 2009/05/19 ADD END   --
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
  END insert_retire_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_trnsf_oif
   * Description      : �U��OIF�o�^ (A-22)
   ***********************************************************************************/
  PROCEDURE insert_trnsf_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_trnsf_oif'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    INSERT INTO xx01_transfer_oif(
      transfer_oif_id           -- ID
     ,book_type_code            -- �䒠��
     ,asset_number              -- ���Y�ԍ�
     ,created_by                -- �쐬��
     ,creation_date             -- �쐬��
     ,last_updated_by           -- �ŏI�X�V��
     ,last_update_date          -- �ŏI�X�V��
     ,last_update_login         -- �ŏI�X�V���O�C��ID
     ,request_id                -- ���N�G�X�gID
     ,program_application_id    -- �A�v���P�[�V����ID
     ,program_id                -- �v���O����ID
     ,program_update_date       -- �v���O�����ŏI�X�V��
     ,transaction_date_entered  -- �U�֓�
     ,transaction_units         -- �P�ʕύX
     ,posting_flag              -- �]�L�`�F�b�N�t���O
     ,status                    -- �X�e�[�^�X
     ,segment1                  -- �������p���Z�O�����g-���
     ,segment2                  -- �������p���Z�O�����g-����
     ,segment3                  -- �������p���Z�O�����g-����Ȗ�
     ,segment4                  -- �������p���Z�O�����g-�⏕�Ȗ�
     ,segment5                  -- �������p���Z�O�����g-�ڋq
     ,segment6                  -- �������p���Z�O�����g-���
     ,segment7                  -- �������p���Z�O�����g-�\��1
     ,segment8                  -- �������p���Z�O�����g-�\��2
     ,loc_segment1              -- �\���n
     ,loc_segment2              -- �Ǘ�����
     ,loc_segment3              -- ���Ə�
     ,loc_segment4              -- �ꏊ
     ,loc_segment5              -- �{�ЍH��敪
    )
    SELECT
      xx01_transfer_oif_s.NEXTVAL         -- ID
     ,xxcff_fa_trn.book_type_code         -- �䒠
     ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
     ,cn_created_by                       -- �쐬��ID
     ,cd_creation_date                    -- �쐬��
     ,cn_last_updated_by                  -- �ŏI�X�V��
     ,cd_last_update_date                 -- �ŏI�X�V��
     ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
     ,cn_request_id                       -- ���N�G�X�gID
     ,cn_program_application_id           -- �A�v���P�[�V����ID
     ,cn_program_id                       -- �v���O����ID
     ,cd_program_update_date              -- �v���O�����ŏI�X�V��
     ,xxcff_fa_trn.transfer_date          -- �U�֓�
     ,xxcff_fa_trn.quantity               -- �P�ʕύX(����)
     ,'Y'                                 -- �]�L�`�F�b�N�t���O
     ,'PENDING'                           -- �X�e�[�^�X
     ,xxcff_fa_trn.dprn_company_code      -- �������p���Z�O�����g-���
     ,xxcff_fa_trn.dprn_department_code   -- �������p���Z�O�����g-����
     ,xxcff_fa_trn.dprn_account_code      -- �������p���Z�O�����g-����Ȗ�
     ,xxcff_fa_trn.dprn_sub_account_code  -- �������p���Z�O�����g-�⏕�Ȗ�
     ,xxcff_fa_trn.dprn_customer_code     -- �������p���Z�O�����g-�ڋq
     ,xxcff_fa_trn.dprn_enterprise_code   -- �������p���Z�O�����g-���
     ,xxcff_fa_trn.dprn_reserve_1         -- �������p���Z�O�����g-�\��1
     ,xxcff_fa_trn.dprn_reserve_2         -- �������p���Z�O�����g-�\��2
     ,xxcff_fa_trn.dclr_place             -- �\���n
     ,xxcff_fa_trn.department_code        -- �Ǘ�����
     ,xxcff_fa_trn.location_name          -- ���Ə�
     ,xxcff_fa_trn.location_place         -- �ꏊ
     ,xxcff_fa_trn.owner_company          -- �{�ЍH��敪
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--      AND xxcff_fa_trn.transaction_type = 2              -- �U��
      AND xxcff_fa_trn.transaction_type IN (cv_transaction_type_2 ,cv_transaction_type_4)              -- �U�ցA�C��
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ;
--
    -- �U��OIF�o�^�����J�E���g
    gn_trnsf_oif_ins_cnt := SQL%ROWCOUNT;
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
  END insert_trnsf_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_add_oif
   * Description      : �ǉ�OIF�o�^ (A-21)
   ***********************************************************************************/
  PROCEDURE insert_add_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_add_oif'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    INSERT INTO fa_mass_additions(
       mass_addition_id              -- ID
      ,description                   -- �E�v
      ,asset_category_id             -- ���Y�J�e�S��CCID
      ,book_type_code                -- �䒠
      ,date_placed_in_service        -- ���Ƌ��p��
      ,fixed_assets_cost             -- �擾���z
      ,payables_units                -- AP����
      ,fixed_assets_units            -- ���Y����
      ,expense_code_combination_id   -- �������p���CCID
      ,location_id                   -- ���Ə��t���b�N�X�t�B�[���hCCID
      ,last_update_date              -- �ŏI�X�V��
      ,last_updated_by               -- �ŏI�X�V��
      ,posting_status                -- �]�L�X�e�[�^�X
      ,queue_name                    -- �L���[��
      ,payables_cost                 -- ���Y�����擾���z
      ,depreciate_flag               -- ���p��v��t���O
      ,asset_type                    -- ���Y�^�C�v
      ,created_by                    -- �쐬��ID
      ,creation_date                 -- �쐬��
      ,last_update_login             -- �ŏI�X�V���O�C��ID
      ,attribute10                   -- ���[�X�_�񖾍ד���ID
      ,deprn_method_code             -- ���p���@
      ,life_in_months                -- �v�Z����
    )
    SELECT
      fa_mass_additions_s.NEXTVAL              -- ID
      ,xxcff_fa_trn.description                -- �E�v
      ,xxcff_fa_trn.category_id                -- ���Y�J�e�S��CCID
      ,xxcff_fa_trn.book_type_code             -- �䒠
      ,xxcff_fa_trn.date_placed_in_service     -- ���Ƌ��p��
      ,xxcff_fa_trn.original_cost              -- �擾���z
      ,xxcff_fa_trn.quantity                   -- AP����
      ,xxcff_fa_trn.quantity                   -- ���Y����
      ,xxcff_fa_trn.dprn_code_combination_id   -- �������p���CCID
      ,xxcff_fa_trn.location_id                -- ���Ə��t���b�N�X�t�B�[���hCCID
      ,cd_last_update_date                     -- �ŏI�X�V��
      ,cn_last_updated_by                      -- �ŏI�X�V��
      ,'POST'                                  -- �]�L�X�e�[�^�X
      ,'POST'                                  -- �L���[��
      ,xxcff_fa_trn.original_cost              -- ���Y�����擾���z
      ,'YES'                                   -- ���p��v��t���O
      ,'CAPITALIZED'                           -- ���Y�^�C�v
      ,cn_created_by                           -- �쐬��ID
      ,cd_creation_date                        -- �쐬��
      ,cn_last_update_login                    -- �ŏI�X�V���O�C��ID
      ,xxcff_fa_trn.contract_line_id           -- ���[�X�_�񖾍ד���ID
      ,xxcff_fa_trn.deprn_method               -- ���p���@
      ,xxcff_fa_trn.payment_frequency          -- �v�Z����(�x����)
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 1         -- �ǉ�
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ;
--
    -- �ǉ�OIF�o�^�����J�E���g
    gn_add_oif_ins_cnt := SQL%ROWCOUNT;
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
  END insert_add_oif;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trns_data
   * Description      : FAOIF�o�^�f�[�^���o (A-20)
   ***********************************************************************************/
  PROCEDURE get_les_trns_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trns_data'; -- �v���O������
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X����J�[�\��
    CURSOR les_trns_cur
    IS
      SELECT
             xxcff_fa_trn.fa_transaction_id  AS fa_transaction_id  -- ���[�X�������ID
      FROM
            xxcff_fa_transactions   xxcff_fa_trn    -- ���[�X���
      WHERE
            xxcff_fa_trn.period_name      = gv_period_name
        AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
        AND xxcff_fa_trn.book_type_code   = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
        FOR UPDATE OF xxcff_fa_trn.fa_transaction_id
        NOWAIT
      ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trns_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trns_cur
    BULK COLLECT INTO  g_fa_transaction_id_tab -- ���[�X�������ID
    ;
    -- �Ώی����J�E���g
    gn_fa_oif_target_cnt := g_fa_transaction_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trns_cur;
--
    IF ( gn_fa_oif_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_034) -- FAOIF�A�g���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_013a20_t_030) -- ���[�X���
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trns_data;
--
  /**********************************************************************************
   * Procedure Name   : update_ritire_data_acct_flag
   * Description      : ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-19)
   ***********************************************************************************/
  PROCEDURE update_ritire_data_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ritire_data_acct_flag'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      <<update_loop>>
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        UPDATE xxcff_contract_histories
        SET
               accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
              ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
              ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
              ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
              ,request_id             = cn_request_id             -- �v��ID
              ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
              ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
              ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE
               contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
          AND  history_num      = g_history_num_tab(ln_loop_cnt)
        ;
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
  END update_ritire_data_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_ritire_data
   * Description      : ���[�X���(���)�o�^ (A-18)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_ritire_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_ritire_data'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF (gn_les_retire_target_cnt > 0) THEN
--
      <<inert_loop>>
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      FOR ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT LOOP
-- 2018/03/29 Ver1.11 Otsuka MOD End
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- ���[�X�������ID
          ,contract_header_id                -- �_�����ID
          ,contract_line_id                  -- �_�񖾍ד���ID
          ,object_header_id                  -- ��������ID
          ,period_name                       -- ��v����
          ,transaction_type                  -- ����^�C�v
          ,book_type_code                    -- ���Y�䒠��
          ,asset_number                      -- ���Y�ԍ�
          ,lease_class                       -- ���[�X���
          ,department_code                   -- �Ǘ�����
          ,owner_company                     -- �{�ЍH��敪
          ,retirement_date                   -- ���p��
          ,cost_retired                      -- �����p�E�擾���i
          ,ret_prorate_convention            -- ���E���p�N�x���p
          ,fa_if_flag                        -- FA�A�g�t���O
          ,gl_if_flag                        -- GL�A�g�t���O
          ,created_by                        -- �쐬��
          ,creation_date                     -- �쐬��
          ,last_updated_by                   -- �ŏI�X�V��
          ,last_update_date                  -- �ŏI�X�V��
          ,last_update_login                 -- �ŏI�X�V۸޲�
          ,request_id                        -- �v��ID
          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,program_id                        -- �ݶ��ĥ��۸���ID
          ,program_update_date               -- ��۸��эX�V��
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL             -- ���[�X�������ID
          ,g_contract_header_id_tab(ln_loop_cnt)        -- �_�����ID
          ,g_contract_line_id_tab(ln_loop_cnt)          -- �_�񖾍ד���ID
          ,g_object_header_id_tab(ln_loop_cnt)          -- ��������ID
          ,gv_period_name                               -- ��v����
          ,3                                            -- ����^�C�v
          ,g_book_type_code_tab(ln_loop_cnt)            -- ���Y�䒠��
          ,g_asset_number_tab(ln_loop_cnt)              -- ���Y�ԍ�
          ,g_lease_class_tab(ln_loop_cnt)               -- ���[�X���
          ,g_department_code_tab(ln_loop_cnt)           -- �Ǘ�����
          ,g_owner_company_tab(ln_loop_cnt)             -- �{�ЍH��敪
          ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))  -- ���p��
          ,g_original_cost_tab(ln_loop_cnt)             -- �����p�E�擾���i
          ,DECODE(g_payment_match_flag_tab(ln_loop_cnt)
                    ,0 , gv_prt_conv_cd_st
                    ,1 , gv_prt_conv_cd_ed)             -- ���E���p�N�x���p
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--          ,cv_if_yet                                    -- FA�A�g�t���O
          ,DECODE(g_fully_retired_tab(ln_loop_cnt)
                    ,NULL ,cv_if_yet
                    ,cv_if_out)                         -- FA�A�g�t���O
-- 2018/03/29 Ver1.11 Otsuka MOD End
          ,cv_if_yet                                    -- GL�A�g�t���O
          ,cn_created_by                                -- �쐬��
          ,cd_creation_date                             -- �쐬��
          ,cn_last_updated_by                           -- �ŏI�X�V��
          ,cd_last_update_date                          -- �ŏI�X�V��
          ,cn_last_update_login                         -- �ŏI�X�V۸޲�
          ,cn_request_id                                -- �v��ID
          ,cn_program_application_id                    -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,cn_program_id                                -- �ݶ��ĥ��۸���ID
          ,cd_program_update_date                       -- ��۸��эX�V��
        );
--
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        -- ���������J�E���g
--        gn_les_retire_normal_cnt := SQL%ROWCOUNT;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        -- FIN���[�X�䒠�̏ꍇ
--        IF (g_book_type_code_tab(ln_loop_cnt) = gv_fin_lease_books) THEN
--          -- ���������J�E���g
--          gn_les_retire_normal_cnt := gn_les_retire_normal_cnt + 1;
--        -- IFRS���[�X�䒠�̏ꍇ
--        ELSE
--          gn_les_retire_ifrs_cnt := gn_les_retire_ifrs_cnt + 1;
--        END IF;
        -- ���������J�E���g
        gn_les_retire_normal_cnt := gn_les_retire_normal_cnt + 1;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
--
      END LOOP;
-- 2018/03/29 Ver1.11 Otsuka MOD End
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
  END insert_les_trn_ritire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_retire_data
   * Description      : ���[�X���(���)�o�^�f�[�^���o (A-17)
   ***********************************************************************************/
  PROCEDURE get_les_trn_retire_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_retire_data'; -- �v���O������
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���(���)�J�[�\��
    CURSOR les_trn_retire_cur
    IS
      SELECT
-- 2018/03/23 Ver.1.11 Otsuka ADD Start
             /*+
                LEADING(ctrct_hist)
                USE_NL(ctrct_hist ctrct_head obj_head)
                USE_NL(ctrct_hist faadds)
                INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02)
                INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK)
                INDEX(obj_head XXCFF_OBJECT_HEADERS_PK)
                INDEX(fb FA_BOOKS_U2)
              */
-- 2018/03/23 Ver.1.11 Otsuka ADD Start
             ctrct_hist.contract_header_id        AS contract_header_id  -- �_�����ID
            ,ctrct_hist.contract_line_id          AS contract_line_id    -- �_�񖾍ד���ID
            ,ctrct_hist.object_header_id          AS object_header_id    -- ��������ID
            ,ctrct_hist.history_num               AS history_num         -- �ύX����No
            ,ctrct_hist.original_cost             AS original_cost       -- �擾���i
            ,faadds.asset_number                  AS asset_number        -- ���Y�ԍ�
-- 2018/03/23 Ver.1.11 Otsuka MOD Start
            --,les_kind.book_type_code              AS book_type_code      -- ���Y�䒠��
            ,fb.book_type_code                    AS book_type_code      -- ���Y�䒠��
            ,fb.period_counter_fully_retired      AS fully_retired       -- �S�������p
-- 2018/03/23 Ver.1.11 Otsuka MOD Start
            ,NVL(pay_plan.payment_match_flag,1)   AS payment_match_flag  -- �ƍ��ς݃t���O
            ,obj_head.department_code             AS department_code     -- �Ǘ�����
            ,obj_head.owner_company               AS owner_company       -- �{�ЍH��敪
            ,ctrct_head.lease_class               AS lease_class         -- ���[�X���
      FROM
            xxcff_contract_histories  ctrct_hist    -- ���[�X�_�񖾍ח���
           ,xxcff_contract_headers    ctrct_head    -- ���[�X�_��
           ,xxcff_object_headers      obj_head      -- ���[�X����
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--           ,xxcff_lease_kind_v        les_kind      -- ���[�X��ރr���[
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
           ,fa_additions_b            faadds        -- ���Y�ڍ׏��
           ,xxcff_pay_planning        pay_plan      -- ���[�X�x���v��
-- 2018/03/23 Ver.1.11 Otsuka ADD Start
           ,fnd_lookup_values         flv           -- �Q�ƕ\
           ,fa_books                  fb            -- ���Y�䒠���
-- 2018/03/23 Ver.1.11 Otsuka ADD End
      WHERE
-- 0001058 2009/08/31 DEL START --
---- 0000417 2009/07/15 MOD START --
----            ctrct_hist.contract_status     IN ( cv_ctrt_manryo
----                                               ,cv_ctrt_cancel_jiko
----                                               ,cv_ctrt_cancel_hoken
----                                               ,cv_ctrt_cancel_manryo
----                                               )      -- ����,
----                                                      -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)
--              obj_head.object_status     IN ( cv_obj_manryo
--                                                  ,cv_obj_cancel_jiko
--                                                  ,cv_obj_cancel_hoken
--                                                  ,cv_obj_cancel_manryo
--                                                  )      -- ����,
--                                                         -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)
---- 0000417 2009/07/15 MOD END --
-- 0001058 2009/08/31 DEL END --
-- 0001058 2009/08/31 ADD START --
              ctrct_hist.contract_status     IN ( cv_ctrt_manryo
                                                 ,cv_ctrt_cancel_jiko
                                                 ,cv_ctrt_cancel_hoken
                                                 ,cv_ctrt_cancel_manryo
                                                 )      -- ����,
                                                      -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)
        AND   obj_head.object_status     IN ( cv_obj_manryo
                                             ,cv_obj_cancel_jiko
                                             ,cv_obj_cancel_hoken
                                             ,cv_obj_cancel_manryo
                                             )      -- ����,
                                                         -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)
-- 0001058 2009/08/31 ADD END --
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD Start
        AND ((ctrct_hist.cancellation_date IS NULL)                                             -- ���� = NULL (����or���r���(����)�̏ꍇ)
          OR (ctrct_hist.cancellation_date < LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM')) + 1)) -- ���� < ��v���ԍŏI�� + 1��
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD End
        AND ctrct_hist.accounting_if_flag   = cv_if_yet                               -- �����M
-- 2018/03/23 Ver.1.11 Otsuka MOD Start
--        AND ctrct_hist.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
--        AND ctrct_hist.contract_header_id   = ctrct_head.contract_header_id
--        AND ctrct_hist.object_header_id     = obj_head.object_header_id
--        AND ctrct_head.lease_type           = cv_original                             -- ���_��
--        AND ctrct_hist.contract_line_id     = faadds.attribute10
--        AND ctrct_hist.lease_kind           = les_kind.lease_kind_code
        AND ctrct_hist.contract_header_id   = ctrct_head.contract_header_id
        AND ctrct_hist.object_header_id     = obj_head.object_header_id
        AND faadds.attribute10              = TO_CHAR(ctrct_hist.contract_line_id)
        AND faadds.asset_id                 = fb.asset_id
        AND fb.date_ineffective             IS NULL                                    -- �ŐV
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        AND fb.book_type_code               IN (les_kind.book_type_code ,les_kind.book_type_code_ifrs)
--        AND ctrct_hist.lease_kind           = les_kind.lease_kind_code
        AND fb.book_type_code               = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
        AND ( ( ctrct_head.lease_type       = cv_original                              -- ���_��
            AND ctrct_hist.lease_kind       IN (cv_lease_kind_fin,cv_lease_kind_lfin)) -- Fin,��Fin
          OR  ( ctrct_head.lease_type       = cv_re_lease                              -- �ă��[�X
            AND flv.attribute7              = cv_lease_cls_chk2 ))                     -- ���[�X���茋�ʁF2
        AND ctrct_head.lease_class          = flv.lookup_code
        AND flv.lookup_type                 = cv_xxcff1_lease_class_check
        AND flv.language                    = USERENV('LANG')
        AND flv.enabled_flag                = cv_flg_y
        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2018/03/23 Ver.1.11 Otsuka MOD End
        AND ctrct_hist.contract_line_id     = pay_plan.contract_line_id(+)
        AND pay_plan.period_name(+)         = gv_period_name
        FOR UPDATE OF ctrct_hist.contract_header_id
        NOWAIT
      ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trn_retire_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trn_retire_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- �_�����ID
                      ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                      ,g_object_header_id_tab   -- ��������ID
                      ,g_history_num_tab        -- �ύX����No
                      ,g_original_cost_tab      -- �擾���i
                      ,g_asset_number_tab       -- ���Y�ԍ�
                      ,g_book_type_code_tab     -- ���Y�䒠��
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                      ,g_fully_retired_tab      -- �S�������p
-- 2018/03/29 Ver1.11 Otsuka ADD End
                      ,g_payment_match_flag_tab -- �ƍ��ς݃t���O
                      ,g_department_code_tab    -- �Ǘ�����
                      ,g_owner_company_tab      -- �{�ЍH��敪
                      ,g_lease_class_tab        -- ���[�X���
    ;
    -- �����Ώی���
    gn_les_retire_target_cnt := g_contract_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trn_retire_cur;
--
    IF ( gn_les_retire_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_033) -- ���[�X����i���j���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_013a20_t_023) -- ���[�X�_�񖾍ח���
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_retire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_ccid
   * Description      : �������p���CCID�擾 (A-25)
   ***********************************************************************************/
  PROCEDURE get_deprn_ccid(
     iot_segments  IN OUT fnd_flex_ext.segmentarray                     -- 1.�Z�O�����g�l�z��
    ,ot_deprn_ccid OUT    gl_code_combinations.code_combination_id%TYPE -- 2.�������p���CCID
    ,ov_errbuf     OUT    VARCHAR2                                      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT    VARCHAR2                                      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT    VARCHAR2)                                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_ccid'; -- �v���O������
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
    -- �֐����^�[���R�[�h
    lb_ret BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--    -- ����R�[�h�ݒ�
--    iot_segments(2) := gv_dep_cd_chosei;
--    -- �ڋq�R�[�h�ݒ�
--    iot_segments(5) := gv_ptnr_cd_dammy;
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
    -- ��ƃR�[�h�ݒ�
    iot_segments(6) := gv_busi_cd_dammy;
    -- �\��1�ݒ�
    iot_segments(7) := gv_project_dammy;
    -- �\��2�ݒ�
    iot_segments(8) := gv_future_dammy;
--
    -- CCID�擾�֐��Ăяo��
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => g_init_rec.gl_application_short_name -- �A�v���P�[�V�����Z�k��(GL)
                ,key_flex_code           => g_init_rec.id_flex_code              -- �L�[�t���b�N�X�R�[�h
                ,structure_number        => g_init_rec.chart_of_accounts_id      -- ����Ȗڑ̌n�ԍ�
                ,validation_date         => g_init_rec.process_date              -- ���t�`�F�b�N
                ,n_segments              => 8                                    -- �Z�O�����g��
                ,segments                => iot_segments                         -- �Z�O�����g�l�z��
                ,combination_id          => ot_deprn_ccid                        -- CCID
                );
    IF NOT lb_ret THEN
      lv_errmsg := fnd_flex_ext.get_message;
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
  END get_deprn_ccid;
--
  /**********************************************************************************
   * Procedure Name   : update_trnsf_data_acct_flag
   * Description      : ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-16)
   ***********************************************************************************/
  PROCEDURE update_trnsf_data_acct_flag(
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    in_loop_cnt   IN  NUMBER,       --   ���[�v�J�E���g
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trnsf_data_acct_flag'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���[�X���������X�V
    --==============================================================
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--    <<update_loop>>
--    FORALL ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT
--      UPDATE xxcff_object_histories
--      SET
--             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
--            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
--            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
--            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
--            ,request_id             = cn_request_id             -- �v��ID
--            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
--            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
--            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
--      WHERE
--            object_header_id     = g_object_header_id_tab(ln_loop_cnt)
--        AND object_status        =  cv_obj_move    -- �ړ�
--        AND accounting_if_flag   =  cv_if_yet      -- �����M
--        AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
--      ;
    UPDATE xxcff_object_histories
    SET
           accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
          ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             = cn_request_id             -- �v��ID
          ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
          ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
          ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
    WHERE
          object_header_id     = g_object_header_id_tab(in_loop_cnt)
      AND object_status        IN (cv_obj_move ,cv_obj_modify)    -- �ړ�,�������ύX
      AND accounting_if_flag   =  cv_if_yet      -- �����M
      AND accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
      AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
    ;
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
--
    --==============================================================
    --���[�X�_�񖾍ח����X�V
    --==============================================================
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--    <<update_loop>>
--    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
--      UPDATE xxcff_contract_histories
--      SET
--             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
--            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
--            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
--            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
--            ,request_id             = cn_request_id             -- �v��ID
--            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
--            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
--            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
--      WHERE
--             contract_line_id   = g_contract_line_id_tab(ln_loop_cnt)
--         AND contract_status    =  cv_ctrt_info_change  -- ���ύX
--         AND accounting_if_flag =  cv_if_yet            -- �����M
--         AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
--      ;
    UPDATE xxcff_contract_histories
    SET
           accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
          ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
          ,request_id             = cn_request_id             -- �v��ID
          ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
          ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
          ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
    WHERE
           contract_line_id   = g_contract_line_id_tab(in_loop_cnt)
       AND contract_status    =  cv_ctrt_info_change  -- ���ύX
       AND accounting_if_flag =  cv_if_yet            -- �����M
       AND accounting_date    >= TO_DATE(gv_period_name,'YYYY-MM')
       AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
    ;
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
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
  END update_trnsf_data_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_trnsf_data
   * Description      : ���[�X���(�U��)�o�^ (A-15)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_trnsf_data(
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    in_loop_cnt   IN  NUMBER,       --   ���[�v�J�E���g
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_trnsf_data'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF (gn_les_trnsf_target_cnt > 0) THEN
--
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--      <<inert_loop>>
--      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
--        INSERT INTO xxcff_fa_transactions (
--           fa_transaction_id                 -- ���[�X�������ID
--          ,contract_header_id                -- �_�����ID
--          ,contract_line_id                  -- �_�񖾍ד���ID
--          ,object_header_id                  -- ��������ID
--          ,period_name                       -- ��v����
--          ,transaction_type                  -- ����^�C�v
--          ,movement_type                     -- �ړ��^�C�v
--          ,book_type_code                    -- ���Y�䒠��
--          ,asset_number                      -- ���Y�ԍ�
--          ,lease_class                       -- ���[�X���
--          ,quantity                          -- ����
--          ,dprn_company_code                 -- ��F_��ЃR�[�h
--          ,dprn_department_code              -- ��F_����R�[�h
--          ,dprn_account_code                 -- ��F_����ȖڃR�[�h
--          ,dprn_sub_account_code             -- ��F_�⏕�ȖڃR�[�h
--          ,dprn_customer_code                -- ��F_�ڋq�R�[�h
--          ,dprn_enterprise_code              -- ��F_��ƃR�[�h
--          ,dprn_reserve_1                    -- ��F_�\��1
--          ,dprn_reserve_2                    -- ��F_�\��2
--          ,dclr_place                        -- �\���n
--          ,department_code                   -- �Ǘ�����R�[�h
--          ,location_name                     -- ���Ə�
--          ,location_place                    -- �ꏊ
--          ,owner_company                     -- �{�Ё^�H��
--          ,transfer_date                     -- �U�֓�
--          ,fa_if_flag                        -- FA�A�g�t���O
--          ,gl_if_flag                        -- GL�A�g�t���O
--          ,created_by                        -- �쐬��
--          ,creation_date                     -- �쐬��
--          ,last_updated_by                   -- �ŏI�X�V��
--          ,last_update_date                  -- �ŏI�X�V��
--          ,last_update_login                 -- �ŏI�X�V۸޲�
--          ,request_id                        -- �v��ID
--          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
--          ,program_id                        -- �ݶ��ĥ��۸���ID
--          ,program_update_date               -- ��۸��эX�V��
--        )
--        VALUES (
--           xxcff_fa_transactions_s1.NEXTVAL            -- ���[�X�������ID
--          ,g_contract_header_id_tab(ln_loop_cnt)       -- �_�����ID
--          ,g_contract_line_id_tab(ln_loop_cnt)         -- �_�񖾍ד���ID
--          ,g_object_header_id_tab(ln_loop_cnt)         -- ��������ID
--          ,gv_period_name                              -- ��v����
--          ,2                                           -- ����^�C�v
--          ,DECODE(g_trnsf_to_comp_cd_tab(ln_loop_cnt)
--                    ,gv_comp_cd_sagara , 1
--                    ,gv_comp_cd_itoen  , 2)            -- �ړ��^�C�v
--          ,g_book_type_code_tab(ln_loop_cnt)           -- ���Y�䒠��
--          ,g_asset_number_tab(ln_loop_cnt)             -- ���Y�ԍ�
--          ,g_lease_class_tab(ln_loop_cnt)              -- ���[�X���
--          ,g_quantity_tab(ln_loop_cnt)                 -- ����
--          ,g_trnsf_to_comp_cd_tab(ln_loop_cnt)         -- ��F_��ЃR�[�h
--          ,gv_dep_cd_chosei                            -- ��F_����R�[�h
--          ,g_deprn_acct_tab(ln_loop_cnt)               -- ��F_����ȖڃR�[�h
--          ,g_deprn_sub_acct_tab(ln_loop_cnt)           -- ��F_�⏕�ȖڃR�[�h
--          ,gv_ptnr_cd_dammy                            -- ��F_�ڋq�R�[�h
--          ,gv_busi_cd_dammy                            -- ��F_��ƃR�[�h
--          ,gv_project_dammy                            -- ��F_�\��1
--          ,gv_future_dammy                             -- ��F_�\��2
--          ,gv_dclr_place_no_report                     -- �\���n
--          ,g_department_code_tab(ln_loop_cnt)          -- �Ǘ�����R�[�h
--          ,gv_mng_place_dammy                          -- ���Ə�
--          ,gv_place_dammy                              -- �ꏊ
--          ,g_owner_company_tab(ln_loop_cnt)            -- �{�Ё^�H��
--          ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- �U�֓�
--          ,cv_if_yet                                   -- FA�A�g�t���O
--          ,cv_if_yet                                   -- GL�A�g�t���O
--          ,cn_created_by                               -- �쐬��
--          ,cd_creation_date                            -- �쐬��
--          ,cn_last_updated_by                          -- �ŏI�X�V��
--          ,cd_last_update_date                         -- �ŏI�X�V��
--          ,cn_last_update_login                        -- �ŏI�X�V۸޲�
--          ,cn_request_id                               -- �v��ID
--          ,cn_program_application_id                   -- �ݶ��ĥ��۸��ѥ���ع����ID
--          ,cn_program_id                               -- �ݶ��ĥ��۸���ID
--          ,cd_program_update_date                      -- ��۸��эX�V��
--        );
--
--      --���������J�E���g
--      gn_les_trnsf_normal_cnt := SQL%ROWCOUNT;
      INSERT INTO xxcff_fa_transactions (
         fa_transaction_id                 -- ���[�X�������ID
        ,contract_header_id                -- �_�����ID
        ,contract_line_id                  -- �_�񖾍ד���ID
        ,object_header_id                  -- ��������ID
        ,period_name                       -- ��v����
        ,transaction_type                  -- ����^�C�v
        ,movement_type                     -- �ړ��^�C�v
        ,book_type_code                    -- ���Y�䒠��
        ,asset_number                      -- ���Y�ԍ�
        ,lease_class                       -- ���[�X���
        ,quantity                          -- ����
        ,dprn_company_code                 -- ��F_��ЃR�[�h
        ,dprn_department_code              -- ��F_����R�[�h
        ,dprn_account_code                 -- ��F_����ȖڃR�[�h
        ,dprn_sub_account_code             -- ��F_�⏕�ȖڃR�[�h
        ,dprn_customer_code                -- ��F_�ڋq�R�[�h
        ,dprn_enterprise_code              -- ��F_��ƃR�[�h
        ,dprn_reserve_1                    -- ��F_�\��1
        ,dprn_reserve_2                    -- ��F_�\��2
        ,dclr_place                        -- �\���n
        ,department_code                   -- �Ǘ�����R�[�h
        ,location_name                     -- ���Ə�
        ,location_place                    -- �ꏊ
        ,owner_company                     -- �{�Ё^�H��
        ,transfer_date                     -- �U�֓�
        ,fa_if_flag                        -- FA�A�g�t���O
        ,gl_if_flag                        -- GL�A�g�t���O
        ,created_by                        -- �쐬��
        ,creation_date                     -- �쐬��
        ,last_updated_by                   -- �ŏI�X�V��
        ,last_update_date                  -- �ŏI�X�V��
        ,last_update_login                 -- �ŏI�X�V۸޲�
        ,request_id                        -- �v��ID
        ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,program_id                        -- �ݶ��ĥ��۸���ID
        ,program_update_date               -- ��۸��эX�V��
      )
      VALUES (
         xxcff_fa_transactions_s1.NEXTVAL            -- ���[�X�������ID
        ,g_contract_header_id_tab(in_loop_cnt)       -- �_�����ID
        ,g_contract_line_id_tab(in_loop_cnt)         -- �_�񖾍ד���ID
        ,g_object_header_id_tab(in_loop_cnt)         -- ��������ID
        ,gv_period_name                              -- ��v����
        ,g_transaction_type_tab(in_loop_cnt)         -- ����^�C�v
        ,DECODE(g_trnsf_to_comp_cd_tab(in_loop_cnt)
                  ,gv_comp_cd_sagara , 1
                  ,gv_comp_cd_itoen  , 2)            -- �ړ��^�C�v
        ,g_book_type_code_tab(in_loop_cnt)           -- ���Y�䒠��
        ,g_asset_number_tab(in_loop_cnt)             -- ���Y�ԍ�
        ,g_lease_class_tab(in_loop_cnt)              -- ���[�X���
        ,g_quantity_tab(in_loop_cnt)                 -- ����
        ,g_trnsf_to_comp_cd_tab(in_loop_cnt)         -- ��F_��ЃR�[�h
        ,DECODE(g_dept_tran_flg_tab(in_loop_cnt)
                  ,cv_flg_y , g_department_code_tab(in_loop_cnt)
                            , gv_dep_cd_chosei)
                                                     -- ��F_����R�[�h
        ,g_deprn_acct_tab(in_loop_cnt)               -- ��F_����ȖڃR�[�h
        ,g_deprn_sub_acct_tab(in_loop_cnt)           -- ��F_�⏕�ȖڃR�[�h
        ,DECODE(g_vd_cust_flag_tab(in_loop_cnt)
                  ,cv_flg_y , g_customer_code_tab(in_loop_cnt)
                            , gv_ptnr_cd_dammy)
                                                     -- ��F_�ڋq�R�[�h
        ,gv_busi_cd_dammy                            -- ��F_��ƃR�[�h
        ,gv_project_dammy                            -- ��F_�\��1
        ,gv_future_dammy                             -- ��F_�\��2
        ,gv_dclr_place_no_report                     -- �\���n
        ,g_department_code_tab(in_loop_cnt)          -- �Ǘ�����R�[�h
        ,gv_mng_place_dammy                          -- ���Ə�
        ,gv_place_dammy                              -- �ꏊ
        ,g_owner_company_tab(in_loop_cnt)            -- �{�Ё^�H��
        ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- �U�֓�
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        ,cv_if_yet                                   -- FA�A�g�t���O
        ,DECODE(g_fully_retired_tab(in_loop_cnt)
                  ,NULL ,cv_if_yet
                  ,cv_if_out)                        -- FA�A�g�t���O
-- 2018/03/29 Ver1.11 Otsuka MOD End
        ,cv_if_yet                                   -- GL�A�g�t���O
        ,cn_created_by                               -- �쐬��
        ,cd_creation_date                            -- �쐬��
        ,cn_last_updated_by                          -- �ŏI�X�V��
        ,cd_last_update_date                         -- �ŏI�X�V��
        ,cn_last_update_login                        -- �ŏI�X�V۸޲�
        ,cn_request_id                               -- �v��ID
        ,cn_program_application_id                   -- �ݶ��ĥ��۸��ѥ���ع����ID
        ,cn_program_id                               -- �ݶ��ĥ��۸���ID
        ,cd_program_update_date                      -- ��۸��эX�V��
      );
--
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      --���������J�E���g
--      gn_les_trnsf_normal_cnt := gn_les_trnsf_normal_cnt + 1;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--      -- FIN���[�X�䒠�̏ꍇ
--      IF (g_book_type_code_tab(in_loop_cnt) = gv_fin_lease_books) THEN
--        -- ���������J�E���g
--        gn_les_trnsf_normal_cnt := gn_les_trnsf_normal_cnt + 1;
--      -- IFRS���[�X�䒠�̏ꍇ
--      ELSE
--        gn_les_trnsf_ifrs_cnt := gn_les_trnsf_ifrs_cnt + 1;
--      END IF;
      --���������J�E���g
      gn_les_trnsf_normal_cnt := gn_les_trnsf_normal_cnt + 1;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
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
  END insert_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : lock_trnsf_data
   * Description      : ���[�X���(�U��)�f�[�^���b�N���� (A-12)
   ***********************************************************************************/
  PROCEDURE lock_trnsf_data(
    it_object_header_id IN xxcff_contract_histories.object_header_id%TYPE
   ,it_contract_line_id IN xxcff_contract_histories.contract_line_id%TYPE
   ,ov_errbuf           OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode          OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_trnsf_data'; -- �v���O������
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���b�N�p�J�[�\��(��������)
    CURSOR lock_obj_trnsf_data (in_object_header_id NUMBER)
    IS
      SELECT
             obj_hist.object_header_id     AS object_header_id  -- ��������ID
      FROM
            xxcff_object_histories    obj_hist      -- ���[�X��������
      WHERE
             obj_hist.object_header_id     =  in_object_header_id
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--         AND obj_hist.object_status        =  cv_obj_move    -- �ړ�
         AND obj_hist.object_status        IN (cv_obj_move ,cv_obj_modify)  -- �ړ�,�������ύX
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
         AND obj_hist.accounting_if_flag   =  cv_if_yet      -- �����M
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
         AND obj_hist.accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
         AND obj_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
         FOR UPDATE NOWAIT
         ;
--
    -- ���b�N�p�J�[�\��(�_�񖾍ח���)
    CURSOR lock_ctrct_trnsf_data (in_contract_line_id NUMBER)
    IS
      SELECT
             ctrct_hist.contract_line_id     AS contract_line_id  -- ��������ID
      FROM
            xxcff_contract_histories    ctrct_hist      -- ���[�X�_�񖾍ח���
      WHERE
             ctrct_hist.contract_line_id   =  in_contract_line_id
         AND ctrct_hist.contract_status    =  cv_ctrt_info_change  -- ���ύX
         AND ctrct_hist.accounting_if_flag =  cv_if_yet            -- �����M
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
         AND ctrct_hist.accounting_date    >= TO_DATE(gv_period_name,'YYYY-MM')
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
         AND ctrct_hist.accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
         FOR UPDATE NOWAIT
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�N�����˕��������f�[�^
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_obj_trnsf_data (it_object_header_id);
      -- �J�[�\���N���[�Y
      CLOSE lock_obj_trnsf_data;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_obj_trnsf_data%ISOPEN) THEN
          CLOSE lock_obj_trnsf_data;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_029) -- ���[�X��������
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�N�����ˌ_�񖾍ח����f�[�^
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_ctrct_trnsf_data (it_contract_line_id);
      -- �J�[�\���N���[�Y
      CLOSE lock_ctrct_trnsf_data;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_ctrct_trnsf_data%ISOPEN) THEN
          CLOSE lock_ctrct_trnsf_data;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_023) -- ���[�X�_�񖾍ח���
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_les_trn_trnsf_data�i���[�v���j
   * Description      : ���[�X���(�U��)�f�[�^���� (A-12)�`(A-16)
   ***********************************************************************************/
  PROCEDURE proc_les_trn_trnsf_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_les_trn_trnsf_data'; -- �v���O������
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
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    lt_m_owner_company    xxcff_object_histories.m_owner_company%TYPE;   -- �ړ����{��/�H��
    lt_m_department_code  xxcff_object_histories.m_department_code%TYPE; -- �ړ����Ǘ�����
    lt_customer_code      xxcff_object_histories.customer_code%TYPE;     -- �C���O�ڋq�R�[�h
    lv_trnsf_flg          VARCHAR2(1);                                   -- �U�֑Ώۃt���O
    lv_warnmsg            VARCHAR2(5000);                                -- �x�����b�Z�[�W
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����A
    --==============================================================
    <<proc_les_trn_trnsf_data>>
    FOR ln_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--      --==============================================================
--      --���o�Ώۃf�[�^���b�N (A-12)
--      --==============================================================
--      lock_trnsf_data(
--         it_object_header_id    => g_object_header_id_tab(ln_loop_cnt) -- ��������ID
--        ,it_contract_line_id    => g_contract_line_id_tab(ln_loop_cnt) -- �_�񖾍ד���ID
--        ,ov_errbuf              => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
--        ,ov_retcode             => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
--        ,ov_errmsg              => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
----
--      --==============================================================
--      --���Ə�CCID�擾 (A-13)
--      --==============================================================
--      xxcff_common1_pkg.chk_fa_location(
--         iv_segment2      => g_department_code_tab(ln_loop_cnt) -- �Ǘ�����
--        ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- �{�ЍH��敪
--        ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- ���Ə�CCID
--        ,ov_errbuf        => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� # 
--        ,ov_retcode       => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
--        ,ov_errmsg        => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
----
--      --==============================================================
--      --�������p���CCID�擾 (A-14)
--      --==============================================================
----
--      -- �Z�O�����g�l�z��ݒ�(SEG1:���)
--      g_segments_tab(1) :=  g_trnsf_to_comp_cd_tab(ln_loop_cnt);
----
--      -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�)
--      g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
--      -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
--      g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
----
--      -- �������p���CCID�擾
--      get_deprn_ccid(
--         iot_segments     => g_segments_tab                  -- �Z�O�����g�l�z��
--        ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- �������p���CCID
--        ,ov_errbuf        => lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� # 
--        ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
--        ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
----
--    END LOOP proc_les_trn_trnsf_data;
----
--    -- =========================================
--    -- ���[�X���(�U��)�o�^ (A-15)
--    -- =========================================
--    insert_les_trn_trnsf_data(
--       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
--      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
--      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    IF (lv_retcode <> cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
----
--    -- ==============================================
--    -- ���o�Ώۃf�[�^ ��vIF�t���O�X�V (A-16)
--    -- ==============================================
--    update_trnsf_data_acct_flag(
--       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
--      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
--      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--    );
--    IF (lv_retcode <> cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
      -- ���������擾
      get_obj_hist_data(
         it_object_header_id   => g_object_header_id_tab(ln_loop_cnt) -- 1.����ID
        ,ot_m_owner_company    => lt_m_owner_company                  -- 2.�ړ����{��/�H��
        ,ot_m_department_code  => lt_m_department_code                -- 3.�ړ����Ǘ�����
        ,ot_customer_code      => lt_customer_code                    -- 4.�ڋq�R�[�h
        ,ov_errbuf             => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode            => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg             => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �Y���̗��������݂���ꍇ
      g_department_code_tab(ln_loop_cnt) := NVL(lt_m_department_code ,g_department_code_tab(ln_loop_cnt));
      g_owner_company_tab(ln_loop_cnt)   := NVL(lt_m_owner_company   ,g_owner_company_tab(ln_loop_cnt));
      g_customer_code_tab(ln_loop_cnt)   := NVL(lt_customer_code     ,g_customer_code_tab(ln_loop_cnt));
--
      -- �Y���̈ړ����������݂���ꍇ
      IF ( lt_m_owner_company IS NOT NULL ) THEN
        -- �{�ЍH��敪���{�Ђ̏ꍇ
        IF g_owner_company_tab(ln_loop_cnt) = gv_own_comp_itoen THEN
          -- �U�֐��ЃR�[�h�ɖ{�ЃR�[�h�ݒ�
          g_trnsf_to_comp_cd_tab(ln_loop_cnt) := gv_comp_cd_itoen;
        -- �{�ЍH��敪���H��̏ꍇ
        ELSE
          -- �U�֐��ЃR�[�h�ɍH��R�[�h�ݒ�
          g_trnsf_to_comp_cd_tab(ln_loop_cnt) := gv_comp_cd_sagara;
        END IF;
      END IF;
--
      -- �U�֐��ЃR�[�h�ƐU�֌���ЃR�[�h���Ⴄ�ꍇ
      IF ( g_trnsf_to_comp_cd_tab(ln_loop_cnt) <> g_trnsf_from_comp_cd_tab(ln_loop_cnt) ) THEN
        -- ����^�C�v�ɐU�ւ�ݒ�
        g_transaction_type_tab(ln_loop_cnt) := cv_transaction_type_2;
        lv_trnsf_flg                        := cv_flg_y;
      -- ����U�փt���O��'Y'�̎�
      -- �Ǘ�����ƐU�֌��Ǘ����傪�Ⴄ�A�܂��́AVD�ڋq�t���O��'Y'�Ōڋq�R�[�h�ƐU�֌��ڋq�R�[�h���Ⴄ�ꍇ
      ELSIF ( g_dept_tran_flg_tab(ln_loop_cnt)     =  cv_flg_y
          AND ( g_department_code_tab(ln_loop_cnt) <> g_trnsf_from_dep_cd_tab(ln_loop_cnt)
            OR  ( g_vd_cust_flag_tab(ln_loop_cnt)   =  cv_flg_y
              AND g_customer_code_tab(ln_loop_cnt)  <> g_trnsf_from_cust_cd_tab(ln_loop_cnt) ) ) ) THEN
        -- ����^�C�v�ɕ���U�ւ�ݒ�
        g_transaction_type_tab(ln_loop_cnt) := cv_transaction_type_4;
        lv_trnsf_flg                        := cv_flg_y;
      -- ��L�ȊO�̏ꍇ
      ELSE
        lv_trnsf_flg                        := cv_flg_n;
      END IF;
--
      -- �Ώۂ̏ꍇ
      IF ( lv_trnsf_flg = cv_flg_y ) THEN
--
        -- �Ώی����J�E���g
        gn_les_trnsf_target_cnt := gn_les_trnsf_target_cnt + 1;
--
        --==============================================================
        --���o�Ώۃf�[�^���b�N (A-12)
        --==============================================================
        lock_trnsf_data(
           it_object_header_id    => g_object_header_id_tab(ln_loop_cnt) -- ��������ID
          ,it_contract_line_id    => g_contract_line_id_tab(ln_loop_cnt) -- �_�񖾍ד���ID
          ,ov_errbuf              => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode             => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg              => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        --���Ə�CCID�擾 (A-13)
        --==============================================================
        xxcff_common1_pkg.chk_fa_location(
           iv_segment2      => g_department_code_tab(ln_loop_cnt) -- �Ǘ�����
          ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- �{�ЍH��敪
          ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- ���Ə�CCID
          ,ov_errbuf        => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode       => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        --�������p���CCID�擾 (A-14)
        --==============================================================
--
        -- �Z�O�����g�l�z��ݒ�(SEG1:���)
        g_segments_tab(1) :=  g_trnsf_to_comp_cd_tab(ln_loop_cnt);
--
        -- �Z�O�����g�l�z��ݒ�(SEG2:����R�[�h)
        -- ����U�փt���O��'Y'�̎�
        IF ( g_dept_tran_flg_tab(ln_loop_cnt) = cv_flg_y ) THEN
          -- �Ǘ�����
          g_segments_tab(2) := g_department_code_tab(ln_loop_cnt);
        -- ����U�փt���O��'Y'�ȊO�̎�
        ELSE
          -- XXCFF: ����R�[�h_��������
          g_segments_tab(2) := gv_dep_cd_chosei;
        END IF;
--
        -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�)
        g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
        -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
        g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
--
        -- �Z�O�����g�l�z��ݒ�(SEG5:�ڋq�R�[�h)
        -- VD�ڋq�t���O��'Y'�̎�
        IF ( g_vd_cust_flag_tab(ln_loop_cnt) = cv_flg_y ) THEN
          -- �ڋq�R�[�h
          g_segments_tab(5) := g_customer_code_tab(ln_loop_cnt);
        -- VD�ڋq�t���O��'Y'�ȊO�̎�
        ELSE
          -- XXCFF: �ڋq�R�[�h_��`�Ȃ�
          g_segments_tab(5) := gv_ptnr_cd_dammy;
        END IF;
--
        -- �������p���CCID�擾
        get_deprn_ccid(
           iot_segments     => g_segments_tab                  -- �Z�O�����g�l�z��
          ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- �������p���CCID
          ,ov_errbuf        => lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- =========================================
        -- ���[�X���(�U��)�o�^ (A-15)
        -- =========================================
        insert_les_trn_trnsf_data(
           ln_loop_cnt       -- ���[�v�J�E���g
          ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ==============================================
        -- ���o�Ώۃf�[�^ ��vIF�t���O�X�V (A-16)
        -- ==============================================
        update_trnsf_data_acct_flag(
           ln_loop_cnt       -- ���[�v�J�E���g
          ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP proc_les_trn_trnsf_data;
--
    -- ���o������1���ȏ�ŁA�����Ώی�����0���̏ꍇ
    IF (  g_contract_header_id_tab.COUNT > 0 
      AND gn_les_trnsf_target_cnt        = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_032) -- ���[�X����i�U�ցj���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
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
  END proc_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_trnsf_data
   * Description      : ���[�X���(�U��)�o�^�f�[�^���o (A-11)
   ***********************************************************************************/
  PROCEDURE get_les_trn_trnsf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_trnsf_data'; -- �v���O������
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���(�U��)�J�[�\��
    CURSOR les_trn_trnsf_cur
    IS
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--      SELECT
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--      SELECT /*+ INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03) INDEX(faadds XXCFF_FA_ADDITIONS_B_N04) INDEX(fadist_hist FA_DISTRIBUTION_HISTORY_N2) INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) INDEX(les_class.FFV FND_FLEX_VALUES_U1) */
      SELECT
       /*+ USE_NL(les_class.ffvs les_class.ffv les_class.ffvt)
           INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03)
           INDEX(faadds XXCFF_FA_ADDITIONS_B_N04)
           INDEX(fadist_hist FA_DISTRIBUTION_HISTORY_N2) 
           INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
             ctrct_line.contract_header_id                      AS contract_header_id -- �_�����ID
            ,ctrct_line.contract_line_id                        AS contract_line_id   -- �_�񖾍ד���ID
            ,ctrct_line.object_header_id                        AS object_header_id   -- ��������ID
            ,ctrct_head.contract_date                           AS contract_date      -- ���[�X�_���
            ,obj_head.department_code                           AS department_code    -- �Ǘ�����
            ,obj_head.owner_company                             AS owner_company      -- �{�ЍH��敪
            ,1                                                  AS quantity           -- ����
            ,ctrct_head.lease_class                             AS lease_class        -- ���[�X���
            ,faadds.asset_number                                AS asset_number       -- ���Y�ԍ�
-- 2018/03/29 Ver1.11 Otsuka MOD Start
            --,les_kind.book_type_code                            AS book_type_code     -- ���Y�䒠��
            ,fadist_hist.book_type_code                         AS book_type_code     -- ���Y�䒠��
-- 2018/03/29 Ver1.11 Otsuka MOD End
            ,les_class.deprn_acct                               AS deprn_acct         -- �������p����
            ,les_class.deprn_sub_acct                           AS deprn_sub_acct     -- �������p�⏕����
            ,gcc.segment1                                       AS trnsf_from_comp_cd -- �U�֌���ЃR�[�h
            ,DECODE(obj_head.owner_company
                      ,gv_own_comp_itoen  , gv_comp_cd_itoen
                      ,gv_own_comp_sagara , gv_comp_cd_sagara)  AS trnsf_to_comp_cd   -- �U�֐��ЃR�[�h
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
            ,gcc.segment2                                       AS trnsf_from_dep_cd  -- �U�֌��Ǘ�����
            ,gcc.segment5                                       AS trnsf_from_cust_cd -- �U�֌��ڋq�R�[�h
            ,obj_head.customer_code                             AS customer_code      -- �U�֐�ڋq�R�[�h
            ,les_class.vd_cust_flag                             AS vd_cust_flag       -- VD�ڋq�t���O
            ,flv.attribute1                                     AS dept_tran_flg      -- ����U�փt���O
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
            ,NULL                                               AS location_ccid      -- ���Ə�CCID
            ,NULL                                               AS deprn_ccid         -- �������p���CCID
-- 2018/03/29 Ver1.11 Otsuka ADD Start
            ,fb.period_counter_fully_retired                    AS fully_retired      -- �S�������p
-- 2018/03/29 Ver1.11 Otsuka ADD End
      FROM
            xxcff_object_headers      obj_head      -- ���[�X����
           ,xxcff_contract_lines      ctrct_line    -- ���[�X�_�񖾍�
           ,xxcff_contract_headers    ctrct_head    -- ���[�X�_��
           ,fa_additions_b            faadds        -- ���Y�ڍ׏��
           ,fa_distribution_history   fadist_hist   -- ���Y�����������
           ,gl_code_combinations      gcc           -- GL�g����
           ,xxcff_lease_class_v       les_class     -- ���[�X��ʃr���[
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--           ,xxcff_lease_kind_v        les_kind      -- ���[�X��ރr���[
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
           ,fnd_lookup_values         flv           -- �Q�ƕ\
           ,fa_books                  fb            -- ���Y�䒠���
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
           ,( 
              SELECT  lse_trnsf_hist_data.object_header_id
-- 2016/08/03 Ver.1.9 Y.Koh DEL Start
--                     ,lse_trnsf_hist_data.contract_line_id
-- 2016/08/03 Ver.1.9 Y.Koh DEL End
              FROM (
-- 2019/05/24 Ver.1.13 Y.Shoji MOD Start
---- 2016/08/03 Ver.1.9 Y.Koh MOD Start
----                     SELECT
---- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
----                     SELECT /*+ INDEX(obj_hist XXCFF_OBJECT_HISTORIES_N02) INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03) INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */
--                     SELECT
--                            /*+ USE_NL(obj_hist ctrct_line ctrct_head)
--                                INDEX(obj_hist XXCFF_OBJECT_HISTORIES_N02)
--                                INDEX(ctrct_line XXCFF_CONTRACT_LINES_N03)
--                                INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */ 
---- 2017/03/29 Ver.1.10 Y.Shoji ADD End
---- 2016/08/03 Ver.1.9 Y.Koh MOD End
--                             obj_hist.object_header_id   AS object_header_id
---- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
----                            ,ctrct_line.contract_line_id AS contract_line_id
---- 2017/03/29 Ver.1.10 Y.Shoji DEL End
--                     FROM
--                           xxcff_object_histories  obj_hist    -- ���[�X��������
--                          ,xxcff_contract_lines    ctrct_line  -- ���[�X�_�񖾍�
--                          ,xxcff_contract_headers  ctrct_head  -- ���[�X�_��
---- 2018/03/29 Ver1.11 Otsuka ADD Start
--                          ,fnd_lookup_values         flv       -- �Q�ƕ\
---- 2018/03/29 Ver1.11 Otsuka ADD End
--                     WHERE 
--                           obj_hist.object_header_id   = ctrct_line.object_header_id
--                       AND ctrct_line.contract_status  IN ( cv_ctrt_ctrt
--                                                           ,cv_ctrt_manryo
---- 2016/08/03 Ver.1.9 Y.Koh ADD Start
--                                                           ,cv_ctrt_re_lease
---- 2016/08/03 Ver.1.9 Y.Koh ADD End
--                                                           ,cv_ctrt_cancel_jiko
--                                                           ,cv_ctrt_cancel_hoken
--                                                           ,cv_ctrt_cancel_manryo
--                                                           ) -- �_��
--                                                             -- ����
--                                                             -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)
---- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
----                       AND obj_hist.object_status        = cv_obj_move  -- �ړ�
--                       AND obj_hist.object_status        IN (cv_obj_move ,cv_obj_modify)  -- �ړ�,�������ύX
---- 2017/03/29 Ver.1.10 Y.Shoji MOD End
--                       AND obj_hist.accounting_if_flag   = cv_if_yet    -- �����M
---- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--                       AND obj_hist.accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
---- 2017/03/29 Ver.1.10 Y.Shoji ADD End
--                       AND obj_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
--                       AND ctrct_head.contract_header_id = ctrct_line.contract_header_id
---- 2016/08/03 Ver.1.9 Y.Koh MOD Start
----                       AND ctrct_head.lease_type         =  cv_original                            -- ���_��
----                       AND ctrct_line.lease_kind         IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
---- 2018/03/29 Ver1.11 Otsuka DEL Start
----                       AND ( ctrct_head.lease_type         =  cv_original                            -- ���_��
----                       OR    ctrct_head.lease_type         =  cv_re_lease                            -- �ă��[�X
----                       AND   ctrct_head.lease_class        =  cv_lease_class_vd                      -- ���̋@
----                       AND   ctrct_head.re_lease_times     <= 3 )                                    -- �ă��[�X��
---- 2016/08/03 Ver.1.9 Y.Koh MOD End
---- 2018/03/29 Ver1.11 Otsuka DEL End
--                       AND obj_hist.re_lease_times       = ctrct_head.re_lease_times
---- 2018/03/29 Ver1.11 Otsuka ADD Start
--                       AND (  ctrct_head.lease_type      =  cv_original                            -- ���_��
--                         OR   (ctrct_head.lease_type     =  cv_re_lease                            -- �ă��[�X
--                           AND ctrct_head.lease_class    =  cv_lease_class_vd                      -- ���̋@
--                           AND ctrct_head.re_lease_times <= 3 )                                    -- �ă��[�X��
--                         OR   (ctrct_head.lease_type     =  cv_re_lease                            -- �ă��[�X
--                           AND flv.attribute7            =  cv_lease_cls_chk2))                    -- ���[�X���茋�ʁF2
--                       AND  ctrct_head.lease_class       =  flv.lookup_code
--                       AND  flv.lookup_type              =  cv_xxcff1_lease_class_check
---- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
--                       AND   flv.attribute7              =  gv_lease_class_att7
---- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--                       AND  flv.language                 =  USERENV('LANG')
--                       AND  flv.enabled_flag             =  cv_flg_y
--                       AND  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
--                                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
---- 2018/03/29 Ver1.11 Otsuka ADD End
                     SELECT
                            obj_hist.object_header_id   AS object_header_id
                     FROM
                            xxcff_object_histories  obj_hist    -- ���[�X��������
                           ,fnd_lookup_values       flv         -- �Q�ƕ\
                     WHERE
                            obj_hist.object_status      IN (cv_obj_move ,cv_obj_modify)  -- �ړ�,�������ύX
                     AND    obj_hist.accounting_if_flag = cv_if_yet    -- �����M
                     AND    obj_hist.accounting_date    >= TO_DATE(gv_period_name,'YYYY-MM')
                     AND    obj_hist.accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                     AND    ( obj_hist.lease_type       =  cv_original                            -- ���_��
                       OR     ( obj_hist.lease_type     =  cv_re_lease                            -- �ă��[�X
                         AND    obj_hist.lease_class    =  cv_lease_class_vd                      -- ���̋@
-- Ver1.15 Mod Start
--                         AND    obj_hist.re_lease_times <= 3 )                                    -- �ă��[�X��
                         AND    obj_hist.re_lease_times <= 5 )                                    -- �ă��[�X��
-- Ver1.15 Mod End
                       OR     ( obj_hist.lease_type     =  cv_re_lease                            -- �ă��[�X
                         AND    flv.attribute7          =  cv_lease_cls_chk2))                    -- ���[�X���茋�ʁF2
                     AND    obj_hist.lease_class         =  flv.lookup_code
                     AND    flv.lookup_type              =  cv_xxcff1_lease_class_check
                     AND    flv.attribute7               =  gv_lease_class_att7
                     AND    flv.language                 =  USERENV('LANG')
                     AND    flv.enabled_flag             =  cv_flg_y
                     AND    LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2019/05/24 Ver.1.13 Y.Shoji MOD End
                     UNION ALL
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--                     SELECT
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     SELECT /*+ INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02) INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK) */
                     SELECT
                           /*+
                              LEADING(ctrct_hist)
                              INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02)
                              INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK)
                            */
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
                             ctrct_hist.object_header_id   AS object_header_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--                            ,ctrct_hist.contract_line_id   AS contract_line_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
                     FROM
                           xxcff_contract_headers    ctrct_head  -- ���[�X�_��
                          ,xxcff_contract_histories  ctrct_hist  -- ���[�X�_�񖾍ח���
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                          ,fnd_lookup_values         flv         -- �Q�ƕ\
-- 2018/03/29 Ver1.11 Otsuka ADD End
                     WHERE 
                           ctrct_head.contract_header_id   =  ctrct_hist.contract_header_id
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--                       AND ctrct_head.lease_type           =  cv_original                            -- ���_��
--                       AND ctrct_hist.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                       AND ( ctrct_head.lease_type           =  cv_original                            -- ���_��
--                       OR    ctrct_head.lease_type           =  cv_re_lease                            -- �ă��[�X
--                       AND   ctrct_head.lease_class          =  cv_lease_class_vd                      -- ���̋@
--                       AND   ctrct_head.re_lease_times       <= 3 )                                    -- �ă��[�X��
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
                       AND (   ctrct_head.lease_type       =  cv_original                           -- ���_��
                         OR   (ctrct_head.lease_type       =  cv_re_lease                           -- �ă��[�X
                           AND ctrct_head.lease_class      =  cv_lease_class_vd                     -- ���̋@
-- Ver1.15 Mod Start
--                           AND ctrct_head.re_lease_times   <= 3 )                                   -- �ă��[�X��
                           AND ctrct_head.re_lease_times   <= 5 )                                   -- �ă��[�X��
-- Ver1.15 Mod End
                         OR   (ctrct_head.lease_type       =  cv_re_lease                           -- �ă��[�X
                           AND flv.attribute7              =  cv_lease_cls_chk2))                   -- ���[�X���茋�ʁF2
                       AND   ctrct_head.lease_class        =  flv.lookup_code
                       AND   flv.lookup_type               =  cv_xxcff1_lease_class_check
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
                       AND   flv.attribute7                =  gv_lease_class_att7
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
                       AND   flv.language                  =  USERENV('LANG')
                       AND   flv.enabled_flag              =  cv_flg_y
                       AND   LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                                         AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2018/03/29 Ver1.11 Otsuka MOD End
                       AND ctrct_hist.contract_status      =  cv_ctrt_info_change                    -- ���ύX
                       AND ctrct_hist.accounting_if_flag   =  cv_if_yet                              -- �����M
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
                       AND ctrct_hist.accounting_date      >= TO_DATE(gv_period_name,'YYYY-MM')
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
                       AND ctrct_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                       ) lse_trnsf_hist_data -- �C�����C���r���[(�����ړ������E�_����ύX����)
              GROUP BY
                 lse_trnsf_hist_data.object_header_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--                ,lse_trnsf_hist_data.contract_line_id
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
            ) lse_trnsf_hist
      WHERE
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--            ctrct_line.contract_line_id     =  lse_trnsf_hist.contract_line_id
--        AND ctrct_line.object_header_id     =  lse_trnsf_hist.object_header_id
            ctrct_line.object_header_id     =  lse_trnsf_hist.object_header_id
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
        AND ctrct_line.object_header_id     =  obj_head.object_header_id
        AND ctrct_line.contract_header_id   =  ctrct_head.contract_header_id
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        AND ctrct_line.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
--        AND ctrct_line.lease_kind           =  les_kind.lease_kind_code
--        AND ctrct_head.lease_type           =  cv_original                            -- ���_��
--        AND ctrct_head.lease_class          =  les_class.lease_class_code
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--        AND ctrct_line.contract_line_id     =  faadds.attribute10
--        AND faadds.attribute10              =  TO_CHAR(ctrct_line.contract_line_id)
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
--        AND faadds.asset_id                 =  fadist_hist.asset_id
--        AND fadist_hist.book_type_code      =  les_kind.book_type_code
--        AND fadist_hist.date_ineffective    IS NULL
--        AND fadist_hist.code_combination_id =  gcc.code_combination_id
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--        AND DECODE(obj_head.owner_company
--                     ,gv_own_comp_itoen  , gv_comp_cd_itoen
--                     ,gv_own_comp_sagara , gv_comp_cd_sagara) <> gcc.segment1
--        AND obj_head.lease_class            =  flv.lookup_code
--        AND flv.lookup_type                 =  cv_xxcff1_lease_class_check
--        AND flv.language                    =  USERENV('LANG')
--        AND flv.enabled_flag                =  cv_flg_y
--        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
--                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2017/03/29 Ver.1.10 Y.Shoji MOD End
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--        AND ctrct_line.lease_kind           =  les_kind.lease_kind_code
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
        AND ctrct_head.lease_class          =  les_class.lease_class_code
        AND ( ctrct_line.lease_kind         IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
        AND   ctrct_head.lease_type         =  cv_original                            -- ���_��
        OR  (ctrct_head.lease_type          =  cv_re_lease                            -- �ă��[�X
        AND  flv.attribute7                 =  cv_lease_cls_chk2 ))                   -- ���[�X���茋�ʁF2
        AND obj_head.lease_class            =  flv.lookup_code
        AND flv.lookup_type                 =  cv_xxcff1_lease_class_check
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
        AND flv.attribute7                  =  gv_lease_class_att7
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
        AND flv.language                    =  USERENV('LANG')
        AND flv.enabled_flag                =  cv_flg_y
        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))) 
        AND faadds.attribute10              =  TO_CHAR(ctrct_line.contract_line_id)
        AND faadds.asset_id                 =  fb.asset_id
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        AND fb.book_type_code               IN (les_kind.book_type_code, les_kind.book_type_code_ifrs)
        AND fb.book_type_code               = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
        AND fb.date_ineffective             IS NULL
        AND fb.asset_id                     =  fadist_hist.asset_id
        AND fb.book_type_code               =  fadist_hist.book_type_code
        AND fadist_hist.date_ineffective    IS NULL
        AND fadist_hist.code_combination_id =  gcc.code_combination_id
-- 2018/03/29 Ver1.11 Otsuka MOD End
        ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trn_trnsf_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trn_trnsf_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- �_�����ID
                      ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                      ,g_object_header_id_tab   -- ��������ID
                      ,g_contract_date_tab      -- ���[�X�_���
                      ,g_department_code_tab    -- �Ǘ�����
                      ,g_owner_company_tab      -- �{�ЍH��敪
                      ,g_quantity_tab           -- ����
                      ,g_lease_class_tab        -- ���[�X���
                      ,g_asset_number_tab       -- ���Y�ԍ�
                      ,g_book_type_code_tab     -- ���Y�䒠��
                      ,g_deprn_acct_tab         -- �������p����
                      ,g_deprn_sub_acct_tab     -- �������p�⏕����
                      ,g_trnsf_from_comp_cd_tab -- �U�֌���ЃR�[�h
                      ,g_trnsf_to_comp_cd_tab   -- �U�֐��ЃR�[�h
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
                      ,g_trnsf_from_dep_cd_tab  -- �U�֌��Ǘ�����
                      ,g_trnsf_from_cust_cd_tab -- �U�֌��ڋq�R�[�h
                      ,g_customer_code_tab      -- �ڋq�R�[�h
                      ,g_vd_cust_flag_tab       -- VD�ڋq�t���O
                      ,g_dept_tran_flg_tab      -- ����U�փt���O
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
                      ,g_location_ccid_tab      -- ���Ə�CCID
                      ,g_deprn_ccid_tab         -- �������p���CCID
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                      ,g_fully_retired_tab      -- �S�������p
-- 2018/03/29 Ver1.11 Otsuka ADD End
    ;
-- 2017/03/29 Ver.1.10 Y.Shoji DEL Start
--    -- �Ώی����J�E���g
--    gn_les_trnsf_target_cnt := g_contract_header_id_tab.COUNT;
-- 2017/03/29 Ver.1.10 Y.Shoji DEL End
    -- �J�[�\���N���[�Y
    CLOSE les_trn_trnsf_cur;
--
-- 2017/03/29 Ver.1.10 Y.Shoji MOD Start
--    IF ( gn_les_trnsf_target_cnt = 0 ) THEN
    IF ( g_contract_header_id_tab.COUNT = 0 ) THEN
-- 2017/03/29 Ver.1.10 Y.Shoji MOD END
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_032) -- ���[�X����i�U�ցj���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : update_ctrct_line_acct_flag
   * Description      : ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-10)
   ***********************************************************************************/
  PROCEDURE update_ctrct_line_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ctrct_line_acct_flag'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���[�X���������X�V
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT
      UPDATE xxcff_object_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
            object_header_id     =  g_object_header_id_tab(ln_loop_cnt)
        AND object_status        =  cv_obj_move   -- �ړ�
        AND accounting_if_flag   =  cv_if_yet    -- �����M
        AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
--
    --==============================================================
    --���[�X�_�񖾍ח����X�V
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE xxcff_contract_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             contract_line_id       =  g_contract_line_id_tab(ln_loop_cnt)
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--         AND contract_status    IN (cv_ctrt_ctrt,cv_ctrt_info_change)  -- �_��,���ύX
         AND contract_status    IN (cv_ctrt_ctrt, cv_ctrt_re_lease ,cv_ctrt_info_change)  -- �_��,�ă��[�X,���ύX
-- 2018/03/29 Ver1.11 Otsuka MOD 
         AND accounting_if_flag =  cv_if_yet                           -- �����M
         AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
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
  END update_ctrct_line_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_add_data
   * Description      : ���[�X���(�ǉ�)�o�^ (A-9)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_add_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_add_data'; -- �v���O������
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
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    lt_deprn_method          fa_category_book_defaults.deprn_method%TYPE;     -- ���p���@
--    lt_life_in_months        fa_category_book_defaults.life_in_months%TYPE;   -- �v�Z��
--    -- ���b�Z�[�W�p������(�_�񖾍ד���ID)
--    lv_str_ctrt_line_id VARCHAR2(50);
--    -- ���b�Z�[�W�p������(���Y�J�e�S��CCID)
--    lv_str_cat_ccid     VARCHAR2(50);
--    -- �G���[�L�[���
--    lv_error_key        VARCHAR2(5000);
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    IF (gn_les_add_target_cnt > 0) THEN
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
--        INSERT INTO xxcff_fa_transactions (
--           fa_transaction_id                 -- ���[�X�������ID
--          ,contract_header_id                -- �_�����ID
--          ,contract_line_id                  -- �_�񖾍ד���ID
--          ,object_header_id                  -- ��������ID
--          ,period_name                       -- ��v����
--          ,transaction_type                  -- ����^�C�v
--          ,book_type_code                    -- ���Y�䒠��
--          ,description                       -- �E�v
--          ,category_id                       -- ���Y�J�e�S��CCID
--          ,asset_category                    -- ���Y���
--          ,asset_account                     -- ���Y����
--          ,deprn_account                     -- ���p�Ȗ�
--          ,lease_class                       -- ���[�X���
--          ,dprn_code_combination_id          -- �������p���CCID
--          ,location_id                       -- ���Ə�CCID
--          ,department_code                   -- �Ǘ�����R�[�h
--          ,owner_company                     -- �{�ЍH��敪
--          ,date_placed_in_service            -- ���Ƌ��p��
--          ,original_cost                     -- �擾���z
--          ,quantity                          -- ����
--          ,deprn_method                      -- ���p���@
--          ,payment_frequency                 -- �v�Z����(�x����)
--          ,fa_if_flag                        -- FA�A�g�t���O
--          ,gl_if_flag                        -- GL�A�g�t���O
--          ,created_by                        -- �쐬��
--          ,creation_date                     -- �쐬��
--          ,last_updated_by                   -- �ŏI�X�V��
--          ,last_update_date                  -- �ŏI�X�V��
--          ,last_update_login                 -- �ŏI�X�V۸޲�
--          ,request_id                        -- �v��ID
--          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
--          ,program_id                        -- �ݶ��ĥ��۸���ID
--          ,program_update_date               -- ��۸��эX�V��
--        )
--        VALUES (
--           xxcff_fa_transactions_s1.NEXTVAL       -- ���[�X�������ID
--          ,g_contract_header_id_tab(ln_loop_cnt)  -- �_�����ID
--          ,g_contract_line_id_tab(ln_loop_cnt)    -- �_�񖾍ד���ID
--          ,g_object_header_id_tab(ln_loop_cnt)    -- ��������ID
--          ,gv_period_name                         -- ��v����
--          ,1                                      -- ����^�C�v(�ǉ�)
--          ,g_book_type_code_tab(ln_loop_cnt)      -- ���Y�䒠��
--          ,g_comments_tab(ln_loop_cnt)            -- �E�v
--          ,g_category_ccid_tab(ln_loop_cnt)       -- ���Y�J�e�S��CCID
--          ,g_asset_category_tab(ln_loop_cnt)      -- ���Y���
--          ,g_les_asset_acct_tab(ln_loop_cnt)      -- ���Y����
--          ,g_deprn_acct_tab(ln_loop_cnt)          -- ���p�Ȗ�
--          ,g_lease_class_tab(ln_loop_cnt)         -- ���[�X���
--          ,g_deprn_ccid_tab(ln_loop_cnt)          -- �������p���CCID
--          ,g_location_ccid_tab(ln_loop_cnt)       -- ���Ə�CCID
--          ,g_department_code_tab(ln_loop_cnt)     -- �Ǘ�����R�[�h
--          ,g_owner_company_tab(ln_loop_cnt)       -- �{�ЍH��敪
--          ,g_contract_date_tab(ln_loop_cnt)       -- ���Ƌ��p��
--          ,g_original_cost_tab(ln_loop_cnt)       -- �擾���z
--          ,g_quantity_tab(ln_loop_cnt)            -- ����
--          ,g_deprn_method_tab(ln_loop_cnt)        -- ���p���@
--          ,g_payment_frequency_tab(ln_loop_cnt)   -- �v�Z����(�x����)
--          ,cv_if_yet                              -- FA�A�g�t���O
--          ,cv_if_yet                              -- GL�A�g�t���O
--          ,cn_created_by                          -- �쐬��
--          ,cd_creation_date                       -- �쐬��
--          ,cn_last_updated_by                     -- �ŏI�X�V��
--          ,cd_last_update_date                    -- �ŏI�X�V��
--          ,cn_last_update_login                   -- �ŏI�X�V۸޲�
--          ,cn_request_id                          -- �v��ID
--          ,cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
--          ,cn_program_id                          -- �ݶ��ĥ��۸���ID
--          ,cd_program_update_date                 -- ��۸��эX�V��
--        );
----
--       --���������J�E���g
--       gn_les_add_normal_cnt := SQL%ROWCOUNT;
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--      <<inert_loop>>
--      FOR ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT LOOP
--        -- ���{��A�g�̏ꍇ
--        IF (g_fin_coop_tab(ln_loop_cnt) = cv_flg_y) THEN
--          BEGIN
--            SELECT
--               cat_deflt.deprn_method   AS deprn_method     -- ���p���@
--              ,cat_deflt.life_in_months AS life_in_months   -- �v�Z����
--            INTO
--               lt_deprn_method                     -- ���p���@
--              ,lt_life_in_months                   -- �v�Z����
--            FROM
--              fa_categories_b            cat       -- ���Y�J�e�S���}�X�^
--             ,fa_category_book_defaults  cat_deflt -- ���Y�J�e�S�����p�
--            WHERE
--                 cat.category_id           = g_category_ccid_tab(ln_loop_cnt)
--            AND  cat.category_id           = cat_deflt.category_id
--            AND  cat_deflt.book_type_code  = gv_fin_lease_books
--            AND  cat_deflt.start_dpis     <= g_contract_date_tab(ln_loop_cnt)
--            AND  NVL(cat_deflt.end_dpis,
--                    g_contract_date_tab(ln_loop_cnt))  >= g_contract_date_tab(ln_loop_cnt)
--            ;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              --���b�Z�[�W�p������擾
--              lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                                      ,cv_msg_013a20_t_027) -- �g�[�N��(�_�񖾍ד���ID)
--                                                                      ,1
--                                                                      ,5000);
--              lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                                  ,cv_msg_013a20_t_028) -- �g�[�N��(���Y�J�e�S��CCID)
--                                                                  ,1
--                                                                  ,5000);
--              --�G���[�L�[���쐬(�����񌋍�)
--              lv_error_key :=         lv_str_ctrt_line_id ||'='|| g_contract_line_id_tab(ln_loop_cnt)
--                        ||','|| lv_str_cat_ccid     ||'='|| g_category_ccid_tab(ln_loop_cnt);
----
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                            ,cv_msg_013a20_m_013  -- ���p���@�擾�G���[
--                                                            ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
--                                                            ,cv_msg_013a20_t_026  -- ���p���@
--                                                            ,cv_tkn_info          -- �g�[�N��'INFO'
--                                                            ,lv_error_key)        -- �G���[�L�[���
--                                                            ,1
--                                                            ,5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--          END;
----
--          INSERT INTO xxcff_fa_transactions (
--             fa_transaction_id                 -- ���[�X�������ID
--            ,contract_header_id                -- �_�����ID
--            ,contract_line_id                  -- �_�񖾍ד���ID
--            ,object_header_id                  -- ��������ID
--            ,period_name                       -- ��v����
--            ,transaction_type                  -- ����^�C�v
--            ,book_type_code                    -- ���Y�䒠��
--            ,description                       -- �E�v
--            ,category_id                       -- ���Y�J�e�S��CCID
--            ,asset_category                    -- ���Y���
--            ,asset_account                     -- ���Y����
--            ,deprn_account                     -- ���p�Ȗ�
--            ,lease_class                       -- ���[�X���
--            ,dprn_code_combination_id          -- �������p���CCID
--            ,location_id                       -- ���Ə�CCID
--            ,department_code                   -- �Ǘ�����R�[�h
--            ,owner_company                     -- �{�ЍH��敪
--            ,date_placed_in_service            -- ���Ƌ��p��
--            ,original_cost                     -- �擾���z
--            ,quantity                          -- ����
--            ,deprn_method                      -- ���p���@
--            ,payment_frequency                 -- �v�Z����(�x����)
--            ,fa_if_flag                        -- FA�A�g�t���O
--            ,gl_if_flag                        -- GL�A�g�t���O
--            ,created_by                        -- �쐬��
--            ,creation_date                     -- �쐬��
--            ,last_updated_by                   -- �ŏI�X�V��
--            ,last_update_date                  -- �ŏI�X�V��
--            ,last_update_login                 -- �ŏI�X�V۸޲�
--            ,request_id                        -- �v��ID
--            ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
--            ,program_id                        -- �ݶ��ĥ��۸���ID
--            ,program_update_date               -- ��۸��эX�V��
--          )
--          VALUES (
--             xxcff_fa_transactions_s1.NEXTVAL       -- ���[�X�������ID
--            ,g_contract_header_id_tab(ln_loop_cnt)  -- �_�����ID
--            ,g_contract_line_id_tab(ln_loop_cnt)    -- �_�񖾍ד���ID
--            ,g_object_header_id_tab(ln_loop_cnt)    -- ��������ID
--            ,gv_period_name                         -- ��v����
--            ,1                                      -- ����^�C�v(�ǉ�)
--            ,gv_fin_lease_books                     -- FIN���[�X�䒠
--            ,g_comments_tab(ln_loop_cnt)            -- �E�v
--            ,g_category_ccid_tab(ln_loop_cnt)       -- ���Y�J�e�S��CCID
--            ,g_asset_category_tab(ln_loop_cnt)      -- ���Y���
--            ,g_les_asset_acct_tab(ln_loop_cnt)      -- ���Y����
--            ,g_deprn_acct_tab(ln_loop_cnt)          -- ���p�Ȗ�
--            ,g_lease_class_tab(ln_loop_cnt)         -- ���[�X���
--            ,g_deprn_ccid_tab(ln_loop_cnt)          -- �������p���CCID
--            ,g_location_ccid_tab(ln_loop_cnt)       -- ���Ə�CCID
--            ,g_department_code_tab(ln_loop_cnt)     -- �Ǘ�����R�[�h
--            ,g_owner_company_tab(ln_loop_cnt)       -- �{�ЍH��敪
--            ,g_contract_date_tab(ln_loop_cnt)       -- ���Ƌ��p��
--            ,g_original_cost_tab(ln_loop_cnt)       -- �擾���z
--            ,g_quantity_tab(ln_loop_cnt)            -- ����
--            ,lt_deprn_method                        -- ���p���@
--            ,lt_life_in_months                      -- �v�Z����
--            ,cv_if_yet                              -- FA�A�g�t���O
--            ,cv_if_yet                              -- GL�A�g�t���O
--            ,cn_created_by                          -- �쐬��
--            ,cd_creation_date                       -- �쐬��
--            ,cn_last_updated_by                     -- �ŏI�X�V��
--            ,cd_last_update_date                    -- �ŏI�X�V��
--            ,cn_last_update_login                   -- �ŏI�X�V۸޲�
--            ,cn_request_id                          -- �v��ID
--            ,cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
--            ,cn_program_id                          -- �ݶ��ĥ��۸���ID
--            ,cd_program_update_date                 -- ��۸��эX�V��
--          );
--            --���������J�E���g
--            gn_les_add_normal_cnt := gn_les_add_normal_cnt + 1;
--        END IF;
----
--        -- IFRS�A�g�̏ꍇ
--        IF (g_ifrs_coop_tab(ln_loop_cnt) = cv_flg_y) THEN
--          BEGIN
--            SELECT
--               cat_deflt.deprn_method   AS deprn_method     -- ���p���@
--              ,cat_deflt.life_in_months AS life_in_months   -- �v�Z����
--            INTO
--               lt_deprn_method                     -- ���p���@
--              ,lt_life_in_months                   -- �v�Z����
--            FROM
--              fa_categories_b            cat       -- ���Y�J�e�S���}�X�^
--             ,fa_category_book_defaults  cat_deflt -- ���Y�J�e�S�����p�
--            WHERE
--                 cat.category_id           = g_category_ccid_tab(ln_loop_cnt)
--            AND  cat.category_id           = cat_deflt.category_id
--            AND  cat_deflt.book_type_code  = gv_ifrs_lease_books
--            AND  cat_deflt.start_dpis     <= g_contract_date_tab(ln_loop_cnt)
--            AND  NVL(cat_deflt.end_dpis,
--                    g_contract_date_tab(ln_loop_cnt))  >= g_contract_date_tab(ln_loop_cnt)
--            ;
--          EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--              --���b�Z�[�W�p������擾
--              lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                                ,cv_msg_013a20_t_027) -- �g�[�N��(�_�񖾍ד���ID)
--                                                                ,1
--                                                                ,5000);
--              lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                            ,cv_msg_013a20_t_028) -- �g�[�N��(���Y�J�e�S��CCID)
--                                                            ,1
--                                                            ,5000);
--              --�G���[�L�[���쐬(�����񌋍�)
--              lv_error_key :=         lv_str_ctrt_line_id ||'='|| g_contract_line_id_tab(ln_loop_cnt)
--                        ||','|| lv_str_cat_ccid     ||'='|| g_category_ccid_tab(ln_loop_cnt);
----
--              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
--                                                      ,cv_msg_013a20_m_013  -- ���p���@�擾�G���[
--                                                      ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
--                                                      ,cv_msg_013a20_t_026  -- ���p���@
--                                                      ,cv_tkn_info          -- �g�[�N��'INFO'
--                                                      ,lv_error_key)        -- �G���[�L�[���
--                                                      ,1
--                                                      ,5000);
--              lv_errbuf := lv_errmsg;
--              RAISE global_api_expt;
--          END;
----
--          INSERT INTO xxcff_fa_transactions (
--             fa_transaction_id                 -- ���[�X�������ID
--            ,contract_header_id                -- �_�����ID
--            ,contract_line_id                  -- �_�񖾍ד���ID
--            ,object_header_id                  -- ��������ID
--            ,period_name                       -- ��v����
--            ,transaction_type                  -- ����^�C�v
--            ,book_type_code                    -- ���Y�䒠��
--            ,description                       -- �E�v
--            ,category_id                       -- ���Y�J�e�S��CCID
--            ,asset_category                    -- ���Y���
--            ,asset_account                     -- ���Y����
--            ,deprn_account                     -- ���p�Ȗ�
--            ,lease_class                       -- ���[�X���
--            ,dprn_code_combination_id          -- �������p���CCID
--            ,location_id                       -- ���Ə�CCID
--            ,department_code                   -- �Ǘ�����R�[�h
--            ,owner_company                     -- �{�ЍH��敪
--            ,date_placed_in_service            -- ���Ƌ��p��
--            ,original_cost                     -- �擾���z
--            ,quantity                          -- ����
--            ,deprn_method                      -- ���p���@
--            ,payment_frequency                 -- �v�Z����(�x����)
--            ,fa_if_flag                        -- FA�A�g�t���O
--            ,gl_if_flag                        -- GL�A�g�t���O
--            ,created_by                        -- �쐬��
--            ,creation_date                     -- �쐬��
--            ,last_updated_by                   -- �ŏI�X�V��
--            ,last_update_date                  -- �ŏI�X�V��
--            ,last_update_login                 -- �ŏI�X�V۸޲�
--            ,request_id                        -- �v��ID
--            ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
--            ,program_id                        -- �ݶ��ĥ��۸���ID
--            ,program_update_date               -- ��۸��эX�V��
--          )
--          VALUES (
--             xxcff_fa_transactions_s1.NEXTVAL       -- ���[�X�������ID
--            ,g_contract_header_id_tab(ln_loop_cnt)  -- �_�����ID
--            ,g_contract_line_id_tab(ln_loop_cnt)    -- �_�񖾍ד���ID
--            ,g_object_header_id_tab(ln_loop_cnt)    -- ��������ID
--            ,gv_period_name                         -- ��v����
--            ,1                                      -- ����^�C�v(�ǉ�)
--            ,gv_ifrs_lease_books                    -- IFRS���[�X�䒠
--            ,g_comments_tab(ln_loop_cnt)            -- �E�v
--            ,g_category_ccid_tab(ln_loop_cnt)       -- ���Y�J�e�S��CCID
--            ,g_asset_category_tab(ln_loop_cnt)      -- ���Y���
--            ,g_les_asset_acct_tab(ln_loop_cnt)      -- ���Y����
--            ,g_deprn_acct_tab(ln_loop_cnt)          -- ���p�Ȗ�
--            ,g_lease_class_tab(ln_loop_cnt)         -- ���[�X���
--            ,g_deprn_ccid_tab(ln_loop_cnt)          -- �������p���CCID
--            ,g_location_ccid_tab(ln_loop_cnt)       -- ���Ə�CCID
--            ,g_department_code_tab(ln_loop_cnt)     -- �Ǘ�����R�[�h
--            ,g_owner_company_tab(ln_loop_cnt)       -- �{�ЍH��敪
--            ,g_contract_date_tab(ln_loop_cnt)       -- ���Ƌ��p��
--            ,g_original_cost_tab(ln_loop_cnt)       -- �擾���z
--            ,g_quantity_tab(ln_loop_cnt)            -- ����
--            ,lt_deprn_method                        -- ���p���@
--            ,lt_life_in_months                      -- �v�Z����
--            ,cv_if_yet                              -- FA�A�g�t���O
--            ,cv_if_yet                              -- GL�A�g�t���O
--            ,cn_created_by                          -- �쐬��
--            ,cd_creation_date                       -- �쐬��
--            ,cn_last_updated_by                     -- �ŏI�X�V��
--            ,cd_last_update_date                    -- �ŏI�X�V��
--            ,cn_last_update_login                   -- �ŏI�X�V۸޲�
--            ,cn_request_id                          -- �v��ID
--            ,cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
--            ,cn_program_id                          -- �ݶ��ĥ��۸���ID
--            ,cd_program_update_date                 -- ��۸��эX�V��
--          );
--          --���������J�E���g
--          gn_les_add_ifrs_cnt := gn_les_add_ifrs_cnt + 1;
--        END IF;
--      END LOOP;
---- 2018/03/29 Ver1.11 Otsuka MOD End
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- ���[�X�������ID
          ,contract_header_id                -- �_�����ID
          ,contract_line_id                  -- �_�񖾍ד���ID
          ,object_header_id                  -- ��������ID
          ,period_name                       -- ��v����
          ,transaction_type                  -- ����^�C�v
          ,book_type_code                    -- ���Y�䒠��
          ,description                       -- �E�v
          ,category_id                       -- ���Y�J�e�S��CCID
          ,asset_category                    -- ���Y���
          ,asset_account                     -- ���Y����
          ,deprn_account                     -- ���p�Ȗ�
          ,lease_class                       -- ���[�X���
          ,dprn_code_combination_id          -- �������p���CCID
          ,location_id                       -- ���Ə�CCID
          ,department_code                   -- �Ǘ�����R�[�h
          ,owner_company                     -- �{�ЍH��敪
          ,date_placed_in_service            -- ���Ƌ��p��
          ,original_cost                     -- �擾���z
          ,quantity                          -- ����
          ,deprn_method                      -- ���p���@
          ,payment_frequency                 -- �v�Z����(�x����)
          ,fa_if_flag                        -- FA�A�g�t���O
          ,gl_if_flag                        -- GL�A�g�t���O
          ,created_by                        -- �쐬��
          ,creation_date                     -- �쐬��
          ,last_updated_by                   -- �ŏI�X�V��
          ,last_update_date                  -- �ŏI�X�V��
          ,last_update_login                 -- �ŏI�X�V۸޲�
          ,request_id                        -- �v��ID
          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,program_id                        -- �ݶ��ĥ��۸���ID
          ,program_update_date               -- ��۸��эX�V��
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL       -- ���[�X�������ID
          ,g_contract_header_id_tab(ln_loop_cnt)  -- �_�����ID
          ,g_contract_line_id_tab(ln_loop_cnt)    -- �_�񖾍ד���ID
          ,g_object_header_id_tab(ln_loop_cnt)    -- ��������ID
          ,gv_period_name                         -- ��v����
          ,1                                      -- ����^�C�v(�ǉ�)
          ,gv_book_type_code                      -- ���Y�䒠��
          ,g_comments_tab(ln_loop_cnt)            -- �E�v
          ,g_category_ccid_tab(ln_loop_cnt)       -- ���Y�J�e�S��CCID
          ,g_asset_category_tab(ln_loop_cnt)      -- ���Y���
          ,g_les_asset_acct_tab(ln_loop_cnt)      -- ���Y����
          ,g_deprn_acct_tab(ln_loop_cnt)          -- ���p�Ȗ�
          ,g_lease_class_tab(ln_loop_cnt)         -- ���[�X���
          ,g_deprn_ccid_tab(ln_loop_cnt)          -- �������p���CCID
          ,g_location_ccid_tab(ln_loop_cnt)       -- ���Ə�CCID
          ,g_department_code_tab(ln_loop_cnt)     -- �Ǘ�����R�[�h
          ,g_owner_company_tab(ln_loop_cnt)       -- �{�ЍH��敪
          ,g_contract_date_tab(ln_loop_cnt)       -- ���Ƌ��p��
          ,g_original_cost_tab(ln_loop_cnt)       -- �擾���z
          ,g_quantity_tab(ln_loop_cnt)            -- ����
          ,g_deprn_method_tab(ln_loop_cnt)        -- ���p���@
          ,g_payment_frequency_tab(ln_loop_cnt)   -- �v�Z����(�x����)
          ,cv_if_yet                              -- FA�A�g�t���O
          ,cv_if_yet                              -- GL�A�g�t���O
          ,cn_created_by                          -- �쐬��
          ,cd_creation_date                       -- �쐬��
          ,cn_last_updated_by                     -- �ŏI�X�V��
          ,cd_last_update_date                    -- �ŏI�X�V��
          ,cn_last_update_login                   -- �ŏI�X�V۸޲�
          ,cn_request_id                          -- �v��ID
          ,cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,cn_program_id                          -- �ݶ��ĥ��۸���ID
          ,cd_program_update_date                 -- ��۸��эX�V��
        );
--
       --���������J�E���g
       gn_les_add_normal_cnt := SQL%ROWCOUNT;
--
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
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
  END insert_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_method
   * Description      : ���p���@�擾 (A-8)
   ***********************************************************************************/
  PROCEDURE get_deprn_method(
     it_contract_line_id   IN  xxcff_contract_histories.contract_line_id%TYPE  -- 1.�_�񖾍�ID
    ,it_category_ccid      IN  fa_categories.category_id%TYPE                  -- 2.���Y�J�e�S��CCID
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    ,it_lease_kind         IN  xxcff_contract_histories.lease_kind%TYPE        -- 3.���[�X���
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
    ,it_contract_date      IN  xxcff_contract_headers.contract_date%TYPE       -- 4.���[�X�_���
    ,ot_deprn_method       OUT fa_category_book_defaults.deprn_method%TYPE     -- 5.���p���@
-- T1_0759 2009/04/23 ADD START --
    ,ot_life_in_months     OUT fa_category_book_defaults.life_in_months%TYPE   -- 6.�v�Z����
-- T1_0759 2009/04/23 ADD END   --
    ,ov_errbuf             OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode            OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg             OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_method'; -- �v���O������
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
    -- ���b�Z�[�W�p������(�_�񖾍ד���ID)
    lv_str_ctrt_line_id VARCHAR2(50);
    -- ���b�Z�[�W�p������(���Y�J�e�S��CCID)
    lv_str_cat_ccid     VARCHAR2(50);
    -- �G���[�L�[���
    lv_error_key        VARCHAR2(5000);
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    -- ���Y�䒠��
--    lt_book_type_code xxcff_lease_kind_v.book_type_code%TYPE;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      SELECT
             cat_deflt.deprn_method   AS deprn_method     -- ���p���@
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,les_kind.book_type_code  AS book_type_code   -- ���Y�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- T1_0759 2009/04/23 ADD START --
            ,cat_deflt.life_in_months AS life_in_months   -- �v�Z����
-- T1_0759 2009/04/23 ADD END   --
      INTO
             ot_deprn_method                     -- ���p���@
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,lt_book_type_code                   -- ���Y�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- T1_0759 2009/04/23 ADD START --
            ,ot_life_in_months                   -- �v�Z����
-- T1_0759 2009/04/23 ADD END   --
      FROM
             fa_categories_b            cat       -- ���Y�J�e�S���}�X�^
            ,fa_category_book_defaults  cat_deflt -- ���Y�J�e�S�����p�
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,xxcff_lease_kind_v         les_kind  -- ���[�X��ރr���[
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
      WHERE
             cat.category_id           = it_category_ccid
        AND  cat.category_id           = cat_deflt.category_id
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        AND  cat_deflt.book_type_code  = les_kind.book_type_code
--        AND  les_kind.lease_kind_code  = it_lease_kind
        AND  cat_deflt.book_type_code  = gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
        AND  cat_deflt.start_dpis     <= it_contract_date
        AND  NVL(cat_deflt.end_dpis,
                   it_contract_date)  >= it_contract_date
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --���b�Z�[�W�p������擾
        lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                                ,cv_msg_013a20_t_027) -- �g�[�N��(�_�񖾍ד���ID)
                                                                ,1
                                                                ,5000);
        lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                            ,cv_msg_013a20_t_028) -- �g�[�N��(���Y�J�e�S��CCID)
                                                            ,1
                                                            ,5000);
        --�G���[�L�[���쐬(�����񌋍�)
        lv_error_key :=         lv_str_ctrt_line_id ||'='|| it_contract_line_id
                        ||','|| lv_str_cat_ccid     ||'='|| it_category_ccid;
--
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_013a20_m_013  -- ���p���@�擾�G���[
                                                      ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
                                                      ,cv_msg_013a20_t_026  -- ���p���@
                                                      ,cv_tkn_info          -- �g�[�N��'INFO'
                                                      ,lv_error_key)        -- �G���[�L�[���
                                                      ,1
                                                      ,5000);
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
  END get_deprn_method;
--
  /**********************************************************************************
   * Procedure Name   : proc_les_trn_add_data�i���[�v���j
   * Description      : ���[�X���(�ǉ�)�f�[�^���� (A-5)�`(A-10)
   ***********************************************************************************/
  PROCEDURE proc_les_trn_add_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_les_trn_add_data'; -- �v���O������
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
-- T1_0759 2009/04/23 ADD START --
    ln_lease_period  NUMBER(4);
-- T1_0759 2009/04/23 ADD END   --
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
    lt_m_owner_company    xxcff_object_histories.m_owner_company%TYPE;   -- �ړ����{��/�H��
    lt_m_department_code  xxcff_object_histories.m_department_code%TYPE; -- �ړ����Ǘ�����
    lt_customer_code      xxcff_object_histories.customer_code%TYPE;     -- �C���O�ڋq�R�[�h
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    lv_lease_class VARCHAR2(2);    -- ���[�X���
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    lt_life_in_months   fa_category_book_defaults.life_in_months%TYPE;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����@
    --==============================================================
    <<les_trn_add_loop>>
    FOR ln_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
      --==============================================================
      --���Y�J�e�S��CCID�擾 (A-5)
      --==============================================================
-- T1_0759 2009/04/23 ADD START --
      --���[�X���Ԃ��Z�o����
-- 2016/08/03 Ver.1.9 Y.Koh MOD Start
--      ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--      IF (g_lease_class_tab(ln_loop_cnt) = cv_lease_class_vd) THEN
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--      --���[�X�敪���f�ă��[�X�f�ł��A���[�X���ʌ��ʂ�'2'�ł���ꍇ�́A�p�x���m�F���A
--      -- �u�N�v�w��̏ꍇ�̓G���[�Ƃ���B
--      IF  ( g_lease_type_tab(ln_loop_cnt) = cv_re_lease
--        AND g_lease_cls_chk_tab(ln_loop_cnt) = cv_lease_cls_chk2 ) THEN
--        AND gv_lease_class_att7 = cv_lease_cls_chk2 ) THEN
--        --�u���v�w��̏ꍇ
--        IF (g_payment_type_tab(ln_loop_cnt) = cv_payment_type0 ) THEN
--          ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
--        --�u�N�v�w��̏ꍇ�G���[
--        ELSE
--          lv_lease_class := g_lease_class_tab(ln_loop_cnt);
--          RAISE payment_type_expt;
--        END IF;
--      -- ���_��Ŏ��̋@�̏ꍇ
--      ELSIF (g_lease_class_tab(ln_loop_cnt) = cv_lease_class_vd) THEN
      -- ���̋@�̏ꍇ
      IF (g_lease_class_tab(ln_loop_cnt) = cv_lease_class_vd) THEN
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
        ln_lease_period := 8;
      -- ���̋@�ȊO�̏ꍇ
      ELSE
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--        ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
        -- �x���񐔂�N���Ŏ擾�A����؂�Ȃ��ꍇ�؂�グ
        ln_lease_period := CEIL(g_payment_frequency_tab(ln_loop_cnt)  / cv_months);
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
      END IF;
-- 2016/08/03 Ver.1.9 Y.Koh MOD End
-- T1_0759 2009/04/23 ADD END   --
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => g_asset_category_tab(ln_loop_cnt) -- ���Y���
-- T1_1428 MOD START 2009/06/16 Ver1.5 by Yuuki Nakamura
--      ,iv_segment3      => g_les_asset_acct_tab(ln_loop_cnt) -- ���Y����
        ,iv_segment3      => NULL                              -- ���Y����
-- T1_1428 MOD END 2009/06/16 Ver1.5 by Yuuki Nakamura
        ,iv_segment4      => g_deprn_acct_tab(ln_loop_cnt)     -- ���p�Ȗ�
-- T1_0759 2009/04/23 MOD START --
--      ,iv_segment5      => g_life_in_months_tab(ln_loop_cnt) -- �ϗp�N��
        ,iv_segment5      => ln_lease_period                   -- ���[�X����
-- T1_0759 2009/04/23 MOD END   --
        ,iv_segment7      => g_lease_class_tab(ln_loop_cnt)    -- ���[�X���
        ,on_category_id   => g_category_ccid_tab(ln_loop_cnt)  -- ���Y�J�e�S��CCID
        ,ov_errbuf        => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --���Ə�CCID�擾 (A-6)
      --==============================================================
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
      -- ���������擾
      get_obj_hist_data(
         it_object_header_id   => g_object_header_id_tab(ln_loop_cnt) -- 1.����ID
        ,ot_m_owner_company    => lt_m_owner_company                  -- 2.�ړ����{��/�H��
        ,ot_m_department_code  => lt_m_department_code                -- 3.�ړ����Ǘ�����
        ,ot_customer_code      => lt_customer_code                    -- 4.�ڋq�R�[�h
        ,ov_errbuf             => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode            => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg             => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      -- �Y���̗��������݂���ꍇ
      g_department_code_tab(ln_loop_cnt) := NVL(lt_m_department_code ,g_department_code_tab(ln_loop_cnt));
      g_owner_company_tab(ln_loop_cnt)   := NVL(lt_m_owner_company   ,g_owner_company_tab(ln_loop_cnt));
      g_customer_code_tab(ln_loop_cnt)   := NVL(lt_customer_code     ,g_customer_code_tab(ln_loop_cnt));
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      xxcff_common1_pkg.chk_fa_location(
         iv_segment2      => g_department_code_tab(ln_loop_cnt) -- �Ǘ�����
        ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- �{�ЍH��敪
        ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- ���Ə�CCID
        ,ov_errbuf        => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�������p���CCID�擾 (A-7)
      --==============================================================
--
      -- �Z�O�����g�l�z��ݒ�(SEG1:���)
      IF g_owner_company_tab(ln_loop_cnt) = gv_own_comp_itoen THEN
        -- �{�ЃR�[�h�ݒ�
        g_segments_tab(1) := gv_comp_cd_itoen;
      ELSE
        -- �H��R�[�h�ݒ�
        g_segments_tab(1) := gv_comp_cd_sagara;
      END IF;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
      -- �Z�O�����g�l�z��ݒ�(SEG2:����R�[�h)
      -- ����U�փt���O��'Y'�̎�
      IF ( g_dept_tran_flg_tab(ln_loop_cnt) = cv_flg_y ) THEN
        -- �Ǘ�����
        g_segments_tab(2) := g_department_code_tab(ln_loop_cnt);
      -- ����U�փt���O��'Y'�ȊO�̎�
      ELSE
        -- XXCFF: ����R�[�h_��������
        g_segments_tab(2) := gv_dep_cd_chosei;
      END IF;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�)
      g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
      -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
      g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
      -- �Z�O�����g�l�z��ݒ�(SEG5:�ڋq�R�[�h)
      -- VD�ڋq�t���O��'Y'�̎�
      IF ( g_vd_cust_flag_tab(ln_loop_cnt) = cv_flg_y ) THEN
        -- �ڋq�R�[�h
        g_segments_tab(5) := g_customer_code_tab(ln_loop_cnt);
      -- VD�ڋq�t���O��'Y'�ȊO�̎�
      ELSE
        -- XXCFF: �ڋq�R�[�h_��`�Ȃ�
        g_segments_tab(5) := gv_ptnr_cd_dammy;
      END IF;
--
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      -- �������p���CCID�擾
      get_deprn_ccid(
         iot_segments     => g_segments_tab                  -- �Z�O�����g�l�z��
        ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- �������p���CCID
        ,ov_errbuf        => lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --���p���@�擾 (A-8)
      --==============================================================
-- 2018/03/29 Ver1.11 Otsuka DEL Start
--      get_deprn_method(
--         it_contract_line_id  => g_contract_line_id_tab(ln_loop_cnt)  -- �_�񖾍ד���ID
--        ,it_category_ccid     => g_category_ccid_tab(ln_loop_cnt)     -- ���Y�J�e�S��CCID
--        ,it_lease_kind        => g_lease_kind_tab(ln_loop_cnt)        -- ���[�X���
--        ,it_contract_date     => g_contract_date_tab(ln_loop_cnt)     -- ���[�X�_���
--        ,ot_deprn_method      => g_deprn_method_tab(ln_loop_cnt)      -- ���p���@
-- T1_0759 2009/04/23 ADD START --
--        ,ot_life_in_months    => g_payment_frequency_tab(ln_loop_cnt) -- �v�Z����
-- T1_0759 2009/04/23 ADD END   --
--        ,ov_errbuf            => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
--        ,ov_retcode           => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
--        ,ov_errmsg            => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      IF (lv_retcode <> ov_retcode) THEN
--        RAISE global_api_expt;
--      END IF;
-- 2018/03/29 Ver1.11 Otsuka DEL End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      get_deprn_method(
         it_contract_line_id  => g_contract_line_id_tab(ln_loop_cnt)  -- �_�񖾍ד���ID
        ,it_category_ccid     => g_category_ccid_tab(ln_loop_cnt)     -- ���Y�J�e�S��CCID
        ,it_contract_date     => g_contract_date_tab(ln_loop_cnt)     -- ���[�X�_���
        ,ot_deprn_method      => g_deprn_method_tab(ln_loop_cnt)      -- ���p���@
        ,ot_life_in_months    => lt_life_in_months                    -- �v�Z����
        ,ov_errbuf            => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode           => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    -- IFRS�䒠�ȊO�̏ꍇ
    IF ( gv_book_type_code <> gv_ifrs_lease_books ) THEN
      g_payment_frequency_tab(ln_loop_cnt) := lt_life_in_months;
    END IF;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
    END LOOP les_trn_add_loop;
--
    -- =========================================
    -- ���[�X���(�ǉ�)�o�^ (A-9)
    -- =========================================
    insert_les_trn_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =========================================
    -- ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-10)
    -- =========================================
    update_ctrct_line_acct_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    -- *** �p�x�`�F�b�N�G���[�n���h�� ***
    WHEN payment_type_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_019  -- �p�x�w��`�F�b�N�G���[
                                                    ,cv_tkn_ls_cls        -- �g�[�N��'LEASE_CLASS'
                                                    ,lv_lease_class )     -- ���[�X���
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- 2018/03/29 Ver1.11 Otsuka ADD End
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
  END proc_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_add_data
   * Description      : ���[�X���(�ǉ�)�o�^�f�[�^���o (A-4)
   ***********************************************************************************/
  PROCEDURE get_les_trn_add_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_add_data'; -- �v���O������
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���(�ǉ�)�J�[�\��
    CURSOR les_trn_add_cur
    IS
      SELECT
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--             /*+ LEADING(ctrct_hist ctrct_head obj_head)
--                 USE_NL(ctrct_hist ctrct_head obj_head les_class.ffvs les_class.ffv les_class.ffvt) */
             /*+ LEADING(ctrct_hist ctrct_head)
                 USE_NL(ctrct_hist ctrct_head obj_head)
                 USE_NL(obj_head les_class.ffvs les_class.ffv les_class.ffvt)
                 INDEX(ctrct_hist XXCFF_CONTRACT_HISTORIES_N02)
                 INDEX(ctrct_head XXCFF_CONTRACT_HEADERS_PK)
                 INDEX(obj_head XXCFF_OBJECT_HEADERS_PK)
                 INDEX(les_class.ffv FND_FLEX_VALUES_N1) */
-- 2018/03/29 Ver1.11 Otsuka MOD End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
             ctrct_hist.contract_header_id AS contract_header_id  -- �_�����ID
            ,ctrct_hist.contract_line_id   AS contract_line_id    -- �_�񖾍ד���ID
            ,obj_head.object_header_id     AS object_header_id    -- ��������ID
            ,ctrct_hist.history_num        AS history_num         -- �ύX����No
            ,ctrct_head.lease_class        AS lease_class         -- ���[�X���
            ,ctrct_hist.lease_kind         AS lease_kind          -- ���[�X���
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,les_kind.book_type_code       AS book_type_code      -- ���Y�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
            ,ctrct_hist.asset_category     AS asset_category      -- ���Y���
            ,ctrct_head.comments           AS comments            -- ����
            ,ctrct_head.payment_years      AS payment_years       -- �N��(���[�X����)
            ,ctrct_hist.life_in_months     AS life_in_months      -- �@��ϗp�N��
-- T1_0893 2009/05/29 MOD START --
--          ,ctrct_head.contract_date      AS contract_date       -- ���[�X�_���
            ,ctrct_head.lease_start_date   AS contract_date       -- ���[�X�J�n��
-- T1_0893 2009/05/29 MOD END   --
            ,ctrct_hist.original_cost      AS original_cost       -- �擾���i
            ,1                             AS quantity            -- ����
            ,obj_head.department_code      AS department_code     -- �Ǘ�����
            ,obj_head.owner_company        AS owner_company       -- �{�ЍH��敪
            ,les_class.les_asset_acct      AS les_asset_acct      -- ���Y����
            ,les_class.deprn_acct          AS deprn_acct          -- �������p����
            ,les_class.deprn_sub_acct      AS deprn_sub_acct      -- �������p�⏕����
            ,ctrct_head.payment_frequency  AS payment_frequency   -- �x����
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
            ,obj_head.customer_code        AS customer_code       -- �ڋq�R�[�h
            ,les_class.vd_cust_flag        AS vd_cust_flag        -- VD�ڋq�t���O
            ,flv.attribute1                AS dept_tran_flg       -- ����U�փt���O
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
            ,NULL                          AS category_ccid       -- ���Y�J�e�S��CCID
            ,NULL                          AS location_ccid       -- ���Ə�CCID
            ,NULL                          AS deprn_ccid          -- �������p���CCID
            ,NULL                          AS deprn_method        -- ���p���@
-- 2018/03/29 Ver1.11 Otsuka ADD Start
            ,ctrct_head.lease_type         AS lease_type          -- ���[�X�^�C�v
            ,ctrct_head.payment_type       AS payment_type        -- �p�x(0:�u���v�A1:�u�N�v�j
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--            ,flv.attribute4                AS fin_coop            -- ���{��A�g
--            ,flv.attribute5                AS ifrs_coop           -- IFRS�A�g
--            ,flv.attribute7                AS lease_cls_chk       -- ���[�X���ʌ���
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
      FROM
            xxcff_contract_histories  ctrct_hist
           ,xxcff_contract_headers    ctrct_head
           ,xxcff_object_headers      obj_head
           ,xxcff_lease_class_v       les_class
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--           ,xxcff_lease_kind_v        les_kind
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
           ,fnd_lookup_values         flv           -- �Q�ƕ\
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
      WHERE
            ctrct_hist.object_header_id   =   obj_head.object_header_id
        AND ctrct_head.lease_class        =   les_class.lease_class_code
        AND ctrct_hist.contract_header_id =   ctrct_head.contract_header_id
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--        AND ctrct_hist.contract_status    =   cv_ctrt_ctrt                            -- �_��
--        AND ctrct_hist.lease_kind         IN  (cv_lease_kind_fin, cv_lease_kind_lfin) -- Fin,��Fin
--        AND ctrct_hist.lease_kind         =   les_kind.lease_kind_code
--        AND ctrct_hist.accounting_if_flag =   cv_if_yet                               -- �����M
--        AND ctrct_head.first_payment_date <=  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
---- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
--        AND obj_head.lease_class          =   flv.lookup_code
--        AND flv.lookup_type               =   cv_xxcff1_lease_class_check
--        AND flv.language                  =   USERENV('LANG')
--        AND flv.enabled_flag              =   cv_flg_y
--        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
--                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
---- 2017/03/29 Ver.1.10 Y.Shoji ADD End
        AND ctrct_hist.accounting_if_flag =  cv_if_yet                                -- �����M
        AND ctrct_head.first_payment_date <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
        AND obj_head.lease_class          =  flv.lookup_code
        AND flv.lookup_type               =  cv_xxcff1_lease_class_check
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
        AND flv.attribute7                = gv_lease_class_att7                       -- ���[�X���菈��
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Emd
        AND flv.language                  =  USERENV('LANG')
        AND flv.enabled_flag              =  cv_flg_y
        AND LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
                                                        AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')))
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--        AND ctrct_hist.lease_kind         =  les_kind.lease_kind_code
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
        AND (  (ctrct_hist.contract_status  =  cv_ctrt_ctrt                               -- �_��
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--            AND ctrct_hist.lease_kind       IN (cv_lease_kind_fin, cv_lease_kind_lfin)) -- Fin,��Fin
            AND ctrct_hist.lease_kind       = gv_lease_kind)                            -- ���[�X���
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
          OR  ( ctrct_hist.contract_status  =  cv_ctrt_re_lease                         -- �ă��[�X
            AND flv.attribute7              =  cv_lease_cls_chk2 ))                     -- ���[�X���茋�ʁF'2'
-- 2018/03/29 Ver1.11 Otsuka MOD End
        FOR UPDATE OF ctrct_hist.contract_header_id
        NOWAIT
      ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trn_add_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trn_add_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- �_�����ID
                      ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                      ,g_object_header_id_tab   -- ��������ID
                      ,g_history_num_tab        -- �ύX����No
                      ,g_lease_class_tab        -- ���[�X���
                      ,g_lease_kind_tab         -- ���[�X���
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--                      ,g_book_type_code_tab     -- ���Y�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
                      ,g_asset_category_tab     -- ���Y���
                      ,g_comments_tab           -- ����
                      ,g_payment_years_tab      -- �N��(���[�X����)
                      ,g_life_in_months_tab     -- �@��ϗp�N��
                      ,g_contract_date_tab      -- ���[�X�_���
                      ,g_original_cost_tab      -- �擾���i
                      ,g_quantity_tab           -- ����
                      ,g_department_code_tab    -- �Ǘ�����
                      ,g_owner_company_tab      -- �{�ЍH��敪
                      ,g_les_asset_acct_tab     -- ���Y����
                      ,g_deprn_acct_tab         -- �������p����
                      ,g_deprn_sub_acct_tab     -- �������p�⏕����
                      ,g_payment_frequency_tab  -- �x����
-- 2017/03/29 Ver.1.10 Y.Shoji ADD Start
                      ,g_customer_code_tab      -- �ڋq�R�[�h
                      ,g_vd_cust_flag_tab       -- VD�ڋq�t���O
                      ,g_dept_tran_flg_tab      -- ����U�փt���O
-- 2017/03/29 Ver.1.10 Y.Shoji ADD End
                      ,g_category_ccid_tab      -- ���Y�J�e�S��CCID
                      ,g_location_ccid_tab      -- ���Ə�CCID
                      ,g_deprn_ccid_tab         -- �������p���CCID
                      ,g_deprn_method_tab       -- �������p���@
-- 2018/03/29 Ver1.11 Otsuka ADD Start
                      ,g_lease_type_tab         -- ���[�X�敪
                      ,g_payment_type_tab       -- �p�x(0:�u���v�A1:�u�N�v�j
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--                      ,g_fin_coop_tab           -- ���{��A�g
--                      ,g_ifrs_coop_tab          -- IFRS�A�g
--                      ,g_lease_cls_chk_tab      -- ���[�X���ʌ���
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End

    ;
    --�Ώی����J�E���g
    gn_les_add_target_cnt := g_contract_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trn_add_cur;
--
    IF ( gn_les_add_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_031) -- ���[�X����i�ǉ��j���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_013a20_t_023) -- ���[�X�_�񖾍ח���
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
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
    -- ���Y�䒠��
    lv_book_type_code VARCHAR(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_cur
    IS
      SELECT
             fdp.deprn_run        AS deprn_run      -- �������p���s�t���O
            ,fdp.book_type_code   AS book_type_code -- ���Y�䒠��
        FROM
             fa_deprn_periods     fdp   -- �������p����
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--            ,xxcff_lease_kind_v   xlk   -- ���[�X��ރr���[
--       WHERE
--             xlk.lease_kind_code IN (cv_lease_kind_fin, cv_lease_kind_lfin)
---- 2018/03/29 Ver1.11 Otsuka MOD Start
----         AND fdp.book_type_code  =  xlk.book_type_code
--         AND (fdp.book_type_code  =  xlk.book_type_code
--          OR  fdp.book_type_code  =  xlk.book_type_code_ifrs )
---- 2018/03/29 Ver1.11 Otsuka MOD Start
         WHERE
             fdp.book_type_code  =  gv_book_type_code
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
         AND fdp.period_name     =  gv_period_name
           ;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �J�[�\���I�[�v��
    OPEN period_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- �������p���s�t���O
                      ,g_book_type_code_tab -- ���Y�䒠��
    ;
    -- �J�[�\���N���[�Y
    CLOSE period_cur;
--
    -- ��v���Ԃ̎擾�������[�����˃G���[
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- �������p�����s����Ă���˃G���[
      IF g_deprn_run_tab(ln_loop_cnt) = 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
  EXCEPTION
--
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type       -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- ���Y�䒠��
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
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
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- XXCFF:��ЃR�[�h_�{��
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:��ЃR�[�h_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:��ЃR�[�h_���ǉ�v
    gv_comp_cd_sagara := FND_PROFILE.VALUE(cv_comp_cd_sagara);
    IF (gv_comp_cd_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:��ЃR�[�h_���ǉ�v
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:����R�[�h_��������
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:����R�[�h_��������
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�ڋq�R�[�h_��`�Ȃ�
    gv_ptnr_cd_dammy := FND_PROFILE.VALUE(cv_ptnr_cd_dammy);
    IF (gv_ptnr_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_013) -- XXCFF:�ڋq�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:��ƃR�[�h_��`�Ȃ�
    gv_busi_cd_dammy := FND_PROFILE.VALUE(cv_busi_cd_dammy);
    IF (gv_busi_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_014) -- XXCFF:��ƃR�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�\��1�R�[�h_��`�Ȃ�
    gv_project_dammy := FND_PROFILE.VALUE(cv_project_dammy);
    IF (gv_project_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_015) -- XXCFF:�\��1�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�\��2�R�[�h_��`�Ȃ�
    gv_future_dammy := FND_PROFILE.VALUE(cv_future_dammy);
    IF (gv_future_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:�\��2�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:���Y�J�e�S��_���p���@
    gv_cat_dprn_lease := FND_PROFILE.VALUE(cv_cat_dprn_lease);
    IF (gv_cat_dprn_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:���Y�J�e�S��_���p���@
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�\���n_�\���Ȃ�
    gv_dclr_place_no_report := FND_PROFILE.VALUE(cv_dclr_place_no_report);
    IF (gv_dclr_place_no_report IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_018) -- XXCFF:�\���n_�\���Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:���Ə�_�\���Ȃ�
    gv_mng_place_dammy := FND_PROFILE.VALUE(cv_mng_place_dammy);
    IF (gv_mng_place_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_019) -- XXCFF:���Ə�_�\���Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�ꏊ_�\���Ȃ�
    gv_place_dammy := FND_PROFILE.VALUE(cv_place_dammy);
    IF (gv_place_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_020) -- XXCFF:�ꏊ_�\���Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�����@_����
    gv_prt_conv_cd_st := FND_PROFILE.VALUE(cv_prt_conv_cd_st);
    IF (gv_prt_conv_cd_st IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_021) -- XXCFF:�����@_����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�����@_����
    gv_prt_conv_cd_ed := FND_PROFILE.VALUE(cv_prt_conv_cd_ed);
    IF (gv_prt_conv_cd_ed IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_022) -- XXCFF:�����@_����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�{�ЍH��敪_�{��
    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_own_comp_itoen);
    IF (gv_own_comp_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_024) -- XXCFF:�{�ЍH��敪_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�{�ЍH��敪_�H��
    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_own_comp_sagara);
    IF (gv_own_comp_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_025) -- XXCFF:�{�ЍH��敪_�H��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2018/03/29 Ver1.11 Otsuka ADD Start
    -- XXCFF:�䒠��_FIN���[�X�䒠
    gv_fin_lease_books := FND_PROFILE.VALUE(cv_fin_lease_books);
    IF (gv_fin_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_035) -- XXCFF:�䒠��_FIN���[�X�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠��_IFRS���[�X�䒠
    gv_ifrs_lease_books := FND_PROFILE.VALUE(cv_ifrs_lease_books);
    IF (gv_ifrs_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_036) -- XXCFF:�䒠��_IFRS���[�X�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2018/03/29 Ver1.11 Otsuka ADD End
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    -- XXCFF:IFRS����ID
    gn_set_of_books_id_ifrs := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_books_id_ifrs));
    IF (gn_set_of_books_id_ifrs IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_037) -- XXCFF:IFRS����ID
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- IFRS���[�X�䒠�̏ꍇ
    IF ( gv_book_type_code = gv_ifrs_lease_books ) THEN
      -- ���[�X���菈��=2
      gv_lease_class_att7 := cv_lease_cls_chk2;
      -- ���[�X���=Fin���[�X
      gv_lease_kind := cv_lease_kind_fin;
    -- FIN���[�X�䒠�̏ꍇ
    ELSIF ( gv_book_type_code = gv_fin_lease_books ) THEN
      -- ���[�X���菈��=1
      gv_lease_class_att7 := cv_lease_cls_chk1;
      -- ���[�X���=Fin���[�X
      gv_lease_kind := cv_lease_kind_fin;
    -- ��L�ȊO�̏ꍇ
    ELSE
      -- ���[�X���菈��=1
      gv_lease_class_att7 := cv_lease_cls_chk1;
      -- ���[�X���=Op���[�X
      gv_lease_kind := cv_lease_kind_lfin;
    END IF;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
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
  END get_profile_values;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    iv_book_type_code IN VARCHAR2,    -- 2.�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt            := 0;
    gn_normal_cnt            := 0;
    gn_error_cnt             := 0;
    gn_warn_cnt              := 0;
    gn_les_add_target_cnt    := 0;
    gn_les_add_normal_cnt    := 0;
    gn_les_add_error_cnt     := 0;
    gn_les_trnsf_target_cnt  := 0;
    gn_les_trnsf_normal_cnt  := 0;
    gn_les_trnsf_error_cnt   := 0;
    gn_les_retire_target_cnt := 0;
    gn_les_retire_normal_cnt := 0;
    gn_les_retire_error_cnt  := 0;
    gn_fa_oif_target_cnt     := 0;
    gn_fa_oif_error_cnt      := 0;
    gn_add_oif_ins_cnt       := 0;
    gn_trnsf_oif_ins_cnt     := 0;
    gn_retire_oif_ins_cnt    := 0;
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    gn_les_add_ifrs_cnt      := 0;
--    gn_les_trnsf_ifrs_cnt    := 0;
--    gn_les_retire_ifrs_cnt   := 0;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
    -- IN�p�����[�^(�䒠��)���O���[�o���ϐ��ɐݒ�
    gv_book_type_code := iv_book_type_code;
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD Start
--
    -- ==============================================
    -- ���[�X�������ߊ��ԍX�V (A-27)
    -- ==============================================
    update_lease_close_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
-- 2012/01/16 Ver.1.8 A.Shirakawa ADD End
--
    -- =========================================
    -- ���[�X���(�ǉ�)�o�^�f�[�^���o (A-4)
    -- =========================================
    get_les_trn_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�ǉ�)�f�[�^���� (A-5)�`(A-10)
    -- =========================================
    proc_les_trn_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�U��)�o�^�f�[�^���o (A-11)
    -- =========================================
    get_les_trn_trnsf_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�U��)�f�[�^���� (A-12)�`(A-16)
    -- =========================================
    proc_les_trn_trnsf_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(���)�o�^�f�[�^���o (A-17)
    -- =========================================
    get_les_trn_retire_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(���)�o�^ (A-18)
    -- =========================================
    insert_les_trn_ritire_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-19)
    -- ==============================================
    update_ritire_data_acct_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- FAOIF�o�^�f�[�^���o (A-20)
    -- =========================================
    get_les_trns_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �ǉ�OIF�o�^ (A-21)
    -- =========================================
    insert_add_oif(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �U��OIF�o�^ (A-22)
    -- =========================================
    insert_trnsf_oif(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���E���pOIF�o�^ (A-23)
    -- =========================================
    insert_retire_oif(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ���[�X��� FA�A�g�t���O�X�V (A-24)
    -- ==============================================
    update_les_trns_fa_if_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
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
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--    iv_period_name IN  VARCHAR2       -- 1.��v���Ԗ�
    iv_period_name    IN  VARCHAR2,   -- 1.��v���Ԗ�
    iv_book_type_code IN  VARCHAR2    -- 2.�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
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
       iv_period_name    -- 1.��v���Ԗ�
-- 2018/09/07 Ver.1.12 Y.Shoji ADD Start
      ,iv_book_type_code -- 2.�䒠��
-- 2018/09/07 Ver.1.12 Y.Shoji ADD End
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
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
--
    --===============================================================
    --�G���[���̏o�͌����ݒ�
    --===============================================================
    IF (lv_retcode <> cv_status_normal) THEN
      -- �����������[���ɃN���A����
      gn_les_add_normal_cnt    := 0;
      gn_les_trnsf_normal_cnt  := 0;
      gn_les_retire_normal_cnt := 0;
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--      gn_les_add_ifrs_cnt      := 0;
--      gn_les_trnsf_ifrs_cnt    := 0;
--      gn_les_retire_ifrs_cnt   := 0;
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
      gn_add_oif_ins_cnt       := 0;
      gn_trnsf_oif_ins_cnt     := 0;
      gn_retire_oif_ins_cnt    := 0;
      -- �G���[�����ɑΏی�����ݒ肷��
      gn_les_add_error_cnt    := gn_les_add_target_cnt;
      gn_les_trnsf_error_cnt  := gn_les_trnsf_target_cnt;
      gn_les_retire_error_cnt := gn_les_retire_target_cnt;
      gn_fa_oif_error_cnt     := gn_fa_oif_target_cnt;
    END IF;
--
    --===============================================================
    --���[�X���(�ǉ�)�o�^�����ɂ����錏���o��
    --===============================================================
    --���[�X���(�ǉ�)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_014
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_021
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    --
--    --���������o��(IFRS)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_022
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_les_add_ifrs_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --���[�X���(�U��)�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X���(�U��)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_015
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_023
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    --
--    --���������o��(IFRS)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_024
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_ifrs_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --���[�X���(���)�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X���(���)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_016
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
-- 2018/03/29 Ver1.11 Otsuka MOD Start
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_025
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
-- 2018/03/29 Ver1.11 Otsuka MOD End
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2018/03/29 Ver1.11 Otsuka ADD Start
-- 2018/09/07 Ver.1.12 Y.Shoji DEL Start
--    --
--    --���������o��(IFRS)
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_msg_kbn_cff
--                    ,iv_name         => cv_msg_013a20_m_026
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_les_retire_ifrs_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
-- 2018/09/07 Ver.1.12 Y.Shoji DEL End
-- 2018/03/29 Ver1.11 Otsuka ADD End
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --FAOIF�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --FAOIF�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_017
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fa_oif_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_add_oif_ins_cnt + gn_trnsf_oif_ins_cnt + gn_retire_oif_ins_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_fa_oif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
       which  => FND_FILE.OUTPUT
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
END XXCFF013A20C;
/
