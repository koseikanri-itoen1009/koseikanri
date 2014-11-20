CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A01C (body)
 * Description      : �[�i�f�[�^�̎捞���s��
 * MD.050           : HHT�[�i�f�[�^�捞 (MD050_COS_001_A01)
 * Version          : 1.25
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  dlv_data_receive       �[�i�f�[�^���o(A-1)
 *  data_check             �f�[�^�Ó����`�F�b�N(A-2)
 *  error_data_register    �G���[�f�[�^�o�^(A-3)
 *  header_data_register   �[�i�w�b�_�e�[�u���փf�[�^�o�^(A-4)
 *  lines_data_register    �[�i���׃e�[�u���փf�[�^�o�^(A-5)
 *  work_data_delete       ���[�N�e�[�u�����R�[�h�폜(A-6)
 *  table_lock             �e�[�u�����b�N(A-7)
 *  dlv_data_delete        �[�i�w�b�_�E���׃e�[�u�����R�[�h�폜(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/18    1.0   S.Miyakoshi      �V�K�쐬
 *  2009/02/03    1.1   S.Miyakoshi      [COS_003]�S�ݓXHHT�敪�ύX�ɑΉ�
 *                                       [COS_004]�G���[���X�g�ւ̘A�g�f�[�^�̕s������ɑΉ�
 *  2009/02/05    1.2   S.Miyakoshi      [COS_034]�i��ID�̒��o���ڂ�ύX
 *  2009/02/20    1.3   S.Miyakoshi      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/02/26    1.4   S.Miyakoshi      �]�ƈ��̗����Ǘ��Ή�(xxcos_rs_info_v)
 *  2009/04/03    1.5   T.Kitajima       [T1_0247]HHT�G���[���X�g�o�^�f�[�^�s���Ή�
 *                                       [T1_0256]�ۊǏꏊ�擾���@�C���Ή�
 *  2009/04/06    1.6   T.Kitajima       [T1_0329]TASK�o�^�G���[�Ή�
 *  2009/04/09    1.7   N.Maeda          [T1_0465]�ڋq���́A���_���̂̌�������ǉ�
 *  2009/04/10    1.8   T.Kitajima       [T1_0248]�S�ݓX�����ύX
 *  2009/04/10    1.9   N.Maeda          [T1_0257]���\�[�Xid�擾�e�[�u���ύX
 *  2009/04/14    1.10  T.Kitajima       [T1_0344]���ю҃R�[�h�A�[�i�҃R�[�h�`�F�b�N�d�l�ύX
 *  2009/04/20    1.11  T.Kitajima       [T1_0592]�S�ݓX��ʎ�ʃ`�F�b�N�폜
 *  2009/05/01    1.12  T.Kitajima       [T1_0268]CHAR���ڂ�TRIM�Ή�
 *  2009/05/15    1.13  N.Maeda          [T1_1007]�G���[�f�[�^�o�^�l(��No.(HHT))�̕ύX
 *  2009/05/15    1.14  N.Maeda          [T1_0752]�K��L�����o�^���ʊ֐��̈���(�K�����)���C��
 *                                       [T1_1011]�G���[���X�g�o�͗p���_���̂̎擾�����ύX
 *                                       [T1_0977]�]�ƈ��}�X�^�ƌڋq�}�X�^�̎擾����
 *  2009/09/01    1.15  N.Maeda          [0000929]���\�[�XID�擾�����ύX[���юҁ˔[�i��]
 *                                                H/C�Ó����`�F�b�N�̎��s�����C��
 *  2009/10/01    1.16  N.Maeda          [0001378]�G���[���X�g�o�^���o�^�����w��
 *  2009/10/30    1.17  M.Sano           [0001373]�Q��View�ύX[xxcos_rs_info_v �� xxcos_rs_info2_v]
 *  2009/11/25    1.18  N.Maeda          [E_�{�ғ�_00053] H/C�̐������`�F�b�N�폜
 *  2009/12/01    1.19  M.Sano           [E_�{�ғ�_00234] ���юҁA�[�i�҂̑Ó����`�F�b�N�C��
 *  2009/12/10    1.20  M.Sano           [E_�{�ғ�_00108] ���ʊ֐�����v���ԏ��擾���ُ�I�����̏����C��
 *  2010/01/18    1.21  M.Uehara         [E_�{�ғ�_01128] �J�[�h���敪�ݒ莞�̃J�[�h��Б��݃`�F�b�N�ǉ�
 *  2010/01/27    1.22  N.Maeda          [E_�{�ғ�_01321] �J�[�h��Ў擾�ϔz��ݒ�
 *  2010/01/27    1.23  N.Maeda          [E_�{�ғ�_01191] �����N�����[�h3(�[�i���[�N�p�[�W)��ǉ�
 *  2010/02/04    1.24  Y.Kuboshima      [E_T4_00195] ��v�J�����_��AR �� INV�ɏC��
 *  2011/02/03    1.25  Y.Kanami         [E_�{�ғ�_02624] �f�[�^�Ó����`�F�b�N�̌ڋq���擾���̏����ǉ�
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- �N�C�b�N�R�[�h�擾�G���[
  lookup_types_expt EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A01C';         -- �p�b�P�[�W��
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';                -- �A�v���P�[�V������
--
  -- �v���t�@�C��
  -- XXCOS:�[�i�f�[�^�捞�p�[�W�������Z�o�����
  cv_prf_purge_date  CONSTANT VARCHAR2(50)  := 'XXCOS1_DLV_PURGE_DATE';
  -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_orga_code   CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';
  -- XXCOS:MAX���t
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
--
  -- �G���[�R�[�h
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';     -- ���b�N�G���[
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';     -- �Ώۃf�[�^�����G���[
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';     -- �v���t�@�C���擾�G���[
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';     -- XXCOS:MAX���t
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';     -- �Q�ƃR�[�h�}�X�^
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10001';     -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_mst         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';     -- �}�X�^�`�F�b�N�G���[
  cv_msg_disagree    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10003';     -- ���ю҂̏������_�G���[
  cv_msg_belong      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10004';     -- �[�i�҂̏������_�G���[
  cv_msg_use         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10005';     -- ���ڎg�p�s�G���[
  cv_msg_status      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10006';     -- �ڋq�X�e�[�^�X�G���[
  cv_msg_base        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10008';     -- �ڋq�̔��㋒�_�R�[�h�G���[
  cv_msg_class       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10009';     -- ���͋敪�E�Ƒԏ����ސ������G���[
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--  cv_msg_period      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10010';     -- �[�i��AR��v���ԃG���[
  cv_msg_period      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10010';     -- �[�i���捞�Ώۊ��ԊO�G���[
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
  cv_msg_adjust      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10011';     -- �[�i�E�������t�������G���[
  cv_msg_future      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10012';     -- �[�i���������G���[
  cv_msg_scope       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10013';     -- �������͈̓G���[
  cv_msg_time        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10014';     -- ���Ԍ`���G���[
  cv_msg_object      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10015';     -- �i�ڔ���Ώۋ敪�G���[
  cv_msg_item        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10017';     -- �i�ڃX�e�[�^�X�G���[
  cv_msg_convert     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10018';     -- ����ʊ��Z�G���[
  cv_msg_vd          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10019';     -- VD���K�{�G���[
  cv_msg_colm        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10020';     -- �R����No�s��v�G���[
  cv_msg_hc          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10021';     -- H/C�s��v�G���[
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10022';     -- �f�[�^�ǉ��G���[���b�Z�[�W
  cv_msg_del         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10023';     -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_orga        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10024';     -- �݌ɑg�DID�擾�G���[
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10025';     -- �Ɩ��������擾�G���[
  cv_msg_del_h       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10026';     -- �w�b�_�폜����
  cv_msg_del_l       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10027';     -- ���׍폜����
  cv_msg_para        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10028';     -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_mode1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10029';     -- �[�i�W���[�i���捞���[�h
  cv_msg_mode2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10030';     -- �[�i�f�[�^�p�[�W�������[�h
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  cv_msg_mode3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13513';     -- �[�i���[�N�e�[�u���폜�������[�h
  cv_msg_mode3_comp  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13514';     -- �[�i���[�N�e�[�u���폜�m�F���b�Z�[�W
  cv_msg_wh_del_count CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13515';     -- �w�b�_���[�N�e�[�u���폜�������b�Z�[�W
  cv_msg_wl_del_count CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13516';     -- ���׃��[�N�e�[�u���폜�������b�Z�[�W
  cv_msg_no_del_target CONSTANT VARCHAR2(20) := 'APP-XXCOS1-13517';    -- ���[�N�e�[�u���폜�Ώۃf�[�^�Ȃ����b�Z�[�W
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
  cv_msg_head_tab    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10031';     -- �[�i�w�b�_�e�[�u��
  cv_msg_line_tab    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10032';     -- �[�i���׃e�[�u��
  cv_msg_headwk_tab  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10033';     -- �[�i�w�b�_���[�N�e�[�u��
  cv_msg_linewk_tab  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10034';     -- �[�i���׃��[�N�e�[�u��
  cv_msg_err_tab     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10035';     -- HHT�G���[���X�g���[���[�N�e�[�u��
  cv_msg_lock_table  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10036';     -- �[�i�w�b�_�e�[�u���y�є[�i���׃e�[�u��
  cv_msg_lock_work   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10037';     -- �w�b�_���[�N�e�[�u���y�і��׃��[�N�e�[�u��
  cv_msg_cus_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10038';     -- �ڋq�}�X�^
  cv_msg_cus_code    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10039';     -- �ڋq�R�[�h
  cv_msg_item_mst    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10040';     -- �i�ڃ}�X�^
  cv_msg_item_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10041';     -- �i�ڃR�[�h
  cv_msg_card        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10042';     -- �J�[�h���敪
  cv_msg_input       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10043';     -- ���͋敪
  cv_msg_tax         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10044';     -- ����ŋ敪
  cv_msg_depart      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10045';     -- �S�ݓX��ʎ��
  cv_msg_sale        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10046';     -- ����敪
  cv_msg_h_c         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10047';     -- H/C
  cv_msg_orga_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10048';     -- �݌ɑg�D�R�[�h
  cv_msg_purge_date  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10049';     -- �[�i�f�[�^�捞�p�[�W�������Z�o�����
  cv_msg_delivery    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10050';     -- �[�i�f�[�^
  cv_msg_return      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13501';     -- �ԕi�f�[�^
  cv_msg_tar_cnt_h   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13502';     -- �w�b�_�Ώی���
  cv_msg_tar_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13503';     -- ���בΏی���
  cv_msg_nor_cnt_h   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13504';     -- �w�b�_��������
  cv_msg_nor_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13505';     -- ���א�������
  cv_msg_keep_code   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13506';     -- �a����R�[�h
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13507';     -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cust_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13508';     -- �ڋq�X�e�[�^�X
  cv_msg_busi_low    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13509';     -- �Ƒԁi�����ށj
  cv_msg_item_st     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13510';     -- �i�ڃX�e�[�^�X
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
  cv_msg_emp_mst     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00051';     -- �]�ƈ��}�X�^
  cv_msg_paf_emp     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00173';     -- ���ю҃R�[�h
  cv_msg_dlv_emp     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00174';     -- �[�i�҃R�[�h
  cv_err_msg_get_resource_id  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13511'; --���\�[�XID�擾�G���[
--****************************** 2009/05/15 1.14 N.Maeda ADD END ********************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
  cv_msg_card_company CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13512';     -- �J�[�h��Ж��ݒ�G���[���b�Z�[�W
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
  -- �g�[�N��
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE';                -- �e�[�u����
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';               -- �e�[�u����
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';                 -- �N�C�b�N�R�[�h�^�C�v
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';              -- �v���t�@�C����
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';                -- ����
  cv_tkn_para1       CONSTANT VARCHAR2(20)  := 'PARAME1';              -- �p�����[�^
  cv_tkn_para2       CONSTANT VARCHAR2(20)  := 'PARAME2';              -- �������e
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';                    -- ���聁Y
  cv_tkn_no          CONSTANT VARCHAR2(1)   := 'N';                    -- ���聁N
  cv_default         CONSTANT VARCHAR2(1)   := '0';                    -- �f�t�H���g�l��0
  cv_hit             CONSTANT VARCHAR2(1)   := '1';                    -- �t���O����
  cv_daytime         CONSTANT VARCHAR2(1)   := '1';                    -- ���ԋN�����[�h��1
  cv_night           CONSTANT VARCHAR2(1)   := '2';                    -- ��ԋN�����[�h��2
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  cv_truncate        CONSTANT VARCHAR2(1)   := '3';                    -- �N�����[�h��3(�[�i���[�N�p�[�W)
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
  cv_depart          CONSTANT VARCHAR2(1)   := '1';                    -- �S�ݓX�pHHT�敪��1�F�S�ݓX
  cv_general         CONSTANT VARCHAR2(1)   := NULL;                   -- �S�ݓX�pHHT�敪��NULL�F��ʋ��_
--****************************** 2009/05/15 1.13 N.Maeda ADD START  *****************************--
  ct_order_no_ebs_0  CONSTANT xxcos_dlv_headers.order_no_ebs%TYPE := 0; -- ��No.(EBS) = 0
--****************************** 2009/05/15 1.13 N.Maeda ADD  END   *****************************--
--****************************** 2009/05/15 1.14 N.Maeda ADD START  *****************************--
  cv_shot_date_type  CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_date_type       CONSTANT VARCHAR2(25)  := 'YYYY/MM/DD HH24:MI:SS';
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  lv_time_type       CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  cv_spe_cha         CONSTANT VARCHAR2(1)   := ' ';
  cv_time_cha        CONSTANT VARCHAR2(1)   := ':';
--****************************** 2009/05/15 1.14 N.Maeda ADD  END   *****************************--
-- ******* 2009/10/01 N.Maeda ADD START ********* --
  cv_user_lang       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- ******* 2009/10/01 N.Maeda ADD  END  ********* --
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
  cv_card            CONSTANT VARCHAR2(1)   := '1';                    -- �J�[�h���敪��1:�J�[�h
  cv_cash            CONSTANT VARCHAR2(1)   := '0';                    -- �J�[�h���敪��0:����
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
--
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qck_typ_status  CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_STATUS_MST_001_A01';   -- �ڋq�X�e�[�^�X
  cv_qck_typ_a01     CONSTANT VARCHAR2(30)  := 'XXCOS_001_A01_%';                 -- �N�C�b�N�R�[�h�F�R�[�h
  cv_qck_typ_card    CONSTANT VARCHAR2(30)  := 'XXCOS1_CARD_SALE_CLASS';          -- �J�[�h���敪
  cv_qck_typ_input   CONSTANT VARCHAR2(30)  := 'XXCOS1_INPUT_CLASS';              -- ���͋敪
  cv_qck_typ_gyotai  CONSTANT VARCHAR2(30)  := 'XXCOS1_GYOTAI_SHO_MST_001_A01';   -- �Ƒԁi�����ށj
  cv_qck_typ_tax     CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';    -- ����ŋ敪
  cv_qck_typ_depart  CONSTANT VARCHAR2(30)  := 'XXCOS1_DEPARTMENT_SCREEN_CLASS';  -- �S�ݓX��ʎ��
  cv_qck_typ_item    CONSTANT VARCHAR2(30)  := 'XXCOS1_ITEM_STATUS_MST_001_A01';  -- �i�ڃX�e�[�^�X
  cv_qck_typ_sale    CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';               -- ����敪
  cv_qck_typ_hc      CONSTANT VARCHAR2(30)  := 'XXCOS1_HC_CLASS';                 -- H/C
  cv_qck_typ_cus     CONSTANT VARCHAR2(30)  := 'XXCOS1_CUS_CLASS_MST_001_A01';    -- �ڋq�敪
--
  --�t�H�[�}�b�g
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE�`��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �[�i�w�b�_���[�N�e�[�u���f�[�^�i�[�p�ϐ�
  TYPE g_rec_headwk_data IS RECORD
    (
      order_no_hht      xxcos_dlv_headers.order_no_hht%TYPE,            -- ��No.�iHHT)
      order_no_ebs      xxcos_dlv_headers.order_no_ebs%TYPE,            -- ��No.�iEBS�j
      base_code         xxcos_dlv_headers.base_code%TYPE,               -- ���_�R�[�h
      perform_code      xxcos_dlv_headers.performance_by_code%TYPE,     -- ���ю҃R�[�h
      dlv_by_code       xxcos_dlv_headers.dlv_by_code%TYPE,             -- �[�i�҃R�[�h
      hht_invoice_no    xxcos_dlv_headers.hht_invoice_no%TYPE,          -- HHT�`�[No.
      dlv_date          xxcos_dlv_headers.dlv_date%TYPE,                -- �[�i��
      inspect_date      xxcos_dlv_headers.inspect_date%TYPE,            -- ������
      sales_class       xxcos_dlv_headers.sales_classification%TYPE,    -- ���㕪�ދ敪
      sales_invoice     xxcos_dlv_headers.sales_invoice%TYPE,           -- ����`�[�敪
      card_class        xxcos_dlv_headers.card_sale_class%TYPE,         -- �J�[�h���敪
      dlv_time          xxcos_dlv_headers.dlv_time%TYPE,                -- ����
      change_time_100   xxcos_dlv_headers.change_out_time_100%TYPE,     -- ��K�؂ꎞ��100�~
      change_time_10    xxcos_dlv_headers.change_out_time_10%TYPE,      -- ��K�؂ꎞ��10�~
      cus_number        xxcos_dlv_headers.customer_number%TYPE,         -- �ڋq�R�[�h
      input_class       xxcos_dlv_headers.input_class%TYPE,             -- ���͋敪
      tax_class         xxcos_dlv_headers.consumption_tax_class%TYPE,   -- ����ŋ敪
      total_amount      xxcos_dlv_headers.total_amount%TYPE,            -- ���v���z
      sale_discount     xxcos_dlv_headers.sale_discount_amount%TYPE,    -- ����l���z
      sales_tax         xxcos_dlv_headers.sales_consumption_tax%TYPE,   -- �������Ŋz
      tax_include       xxcos_dlv_headers.tax_include%TYPE,             -- �ō����z
      keep_in_code      xxcos_dlv_headers.keep_in_code%TYPE,            -- �a����R�[�h
      depart_screen     xxcos_dlv_headers.department_screen_class%TYPE  -- �S�ݓX��ʎ��
    );
  TYPE g_tab_headwk_data IS TABLE OF g_rec_headwk_data INDEX BY PLS_INTEGER;
--
  -- �[�i���׃��[�N�e�[�u���f�[�^�i�[�p�ϐ�
  TYPE g_rec_linewk_data IS RECORD
    (
      order_no_hht      xxcos_dlv_lines.order_no_hht%TYPE,              -- ��No.�iHHT�j
      line_no_hht       xxcos_dlv_lines.line_no_hht%TYPE,               -- �sNo.�iHHT�j
      order_no_ebs      xxcos_dlv_lines.order_no_ebs%TYPE,              -- ��No.�iEBS�j
      line_num_ebs      xxcos_dlv_lines.line_number_ebs%TYPE,           -- ���הԍ�(EBS)
      item_code_self    xxcos_dlv_lines.item_code_self%TYPE,            -- �i���R�[�h�i���Ёj
      case_number       xxcos_dlv_lines.case_number%TYPE,               -- �P�[�X��
      quantity          xxcos_dlv_lines.quantity%TYPE,                  -- ����
      sale_class        xxcos_dlv_lines.sale_class%TYPE,                -- ����敪
      wholesale_unit    xxcos_dlv_lines.wholesale_unit_ploce%TYPE,      -- ���P��
      selling_price     xxcos_dlv_lines.selling_price%TYPE,             -- ���P��
      column_no         xxcos_dlv_lines.column_no%TYPE,                 -- �R����No.
      h_and_c           xxcos_dlv_lines.h_and_c%TYPE,                   -- H/C
      sold_out_class    xxcos_dlv_lines.sold_out_class%TYPE,            -- ���؋敪
      sold_out_time     xxcos_dlv_lines.sold_out_time%TYPE,             -- ���؎���
      cash_and_card     xxcos_dlv_lines.cash_and_card%TYPE              -- �����E�J�[�h���p�z
    );
  TYPE g_tab_linewk_data IS TABLE OF g_rec_linewk_data INDEX BY PLS_INTEGER;
--
  -- ���_�R�[�h�A�ڋq�R�[�h�̑Ó����`�F�b�N�F���o���ڊi�[�p�ϐ�
  TYPE g_rec_select_cus IS RECORD
    (
      customer_name   hz_cust_accounts.account_name%TYPE,              -- �ڋq����
      customer_id     hz_cust_accounts.cust_account_id%TYPE,           -- �ڋqID
      party_id        hz_cust_accounts.party_id%TYPE,                  -- �p�[�e�BID
      sale_base       xxcmm_cust_accounts.sale_base_code%TYPE,         -- ���㋒�_�R�[�h
      past_sale_base  xxcmm_cust_accounts.past_sale_base_code%TYPE,    -- �O�����㋒�_�R�[�h
      cus_status      hz_parties.duns_number_c%TYPE,                   -- �ڋq�X�e�[�^�X
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--      charge_person   jtf_rs_resource_extns.source_number%TYPE,        -- �S���c�ƈ�
--****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--      resource_id     jtf_rs_resource_extns.resource_id%TYPE,          -- ���\�[�XID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
      bus_low_type    xxcmm_cust_accounts.business_low_type%TYPE,      -- �Ƒԁi�����ށj
      base_name       hz_cust_accounts.account_name%TYPE,              -- ���_����
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--      dept_hht_div    xxcmm_cust_accounts.dept_hht_div%TYPE            -- �S�ݓX�pHHT�敪
      dept_hht_div    xxcmm_cust_accounts.dept_hht_div%TYPE,            -- �S�ݓX�pHHT�敪
--****************************** 2010/01/18 1.21 M.Uehara MOD END *******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--      base_perf       per_all_assignments_f.ass_attribute5%TYPE,       -- ���_�R�[�h�i���юҁj
--      base_dlv        per_all_assignments_f.ass_attribute5%TYPE        -- ���_�R�[�h�i�[�i�ҁj
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      card_company    xxcmm_cust_accounts.card_company%TYPE            -- �J�[�h���
--****************************** 2010/01/18 1.21 M.Uehara ADD END *******************************--
    );
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--  
--  TYPE g_tab_select_cus IS TABLE OF g_rec_select_cus INDEX BY VARCHAR2(9);
  TYPE g_tab_select_cus IS TABLE OF g_rec_select_cus INDEX BY VARCHAR2(15);
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  -- ���ю҃R�[�h�̑Ó����`�F�b�N�F���o���ڊi�[�p�ϐ�
  TYPE g_rec_select_perf IS RECORD
    (
      base_perf       per_all_assignments_f.ass_attribute5%TYPE        -- ���_�R�[�h�i���юҁj
    );
  TYPE g_tab_select_perf IS TABLE OF g_rec_select_perf INDEX BY VARCHAR2(30);
--
  -- �[�i�҃R�[�h�̑Ó����`�F�b�N�F���o���ڊi�[�p�ϐ�
  TYPE g_rec_select_dlv  IS RECORD
    (
      resource_id     jtf_rs_resource_extns.resource_id%TYPE,          -- ���\�[�XID
      base_dlv        per_all_assignments_f.ass_attribute5%TYPE        -- ���_�R�[�h�i�[�i�ҁj
    );
  TYPE g_tab_select_dlv IS TABLE OF g_rec_select_dlv INDEX BY VARCHAR2(30);
--
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  -- �i�ڃR�[�h�̑Ó����`�F�b�N�F���o���ڊi�[�p�ϐ�
  TYPE g_rec_select_item IS RECORD
    (
      item_id          mtl_system_items_b.inventory_item_id%TYPE,              -- �i��ID
      primary_measure  mtl_system_items_b.primary_unit_of_measure%TYPE,        -- ��P��
      in_case          ic_item_mst_b.attribute11%TYPE,                         -- �P�[�X����
      sale_object      ic_item_mst_b.attribute26%TYPE,                         -- ����Ώۋ敪
      item_status      xxcmm_system_items_b.item_status%TYPE                   -- �i�ڃX�e�[�^�X
    );
  TYPE g_tab_select_item IS TABLE OF g_rec_select_item INDEX BY VARCHAR2(7);
--
  -- VD�R�����}�X�^�Ƃ̐������`�F�b�N�F���o���ڊi�[�p�ϐ�
  TYPE g_rec_select_vd IS RECORD
    (
      column_no      xxcoi_mst_vd_column.column_no%TYPE,              -- �R����No.
      hot_cold       xxcoi_mst_vd_column.hot_cold%TYPE                -- H/C
    );
  TYPE g_tab_select_vd IS TABLE OF g_rec_select_vd INDEX BY VARCHAR2(18);
--
  -- �[�i�w�b�_�f�[�^�o�^�p�ϐ�
  TYPE g_tab_head_order_no_hht      IS TABLE OF xxcos_dlv_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.�iHHT)
  TYPE g_tab_head_order_no_ebs      IS TABLE OF xxcos_dlv_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.�iEBS�j
  TYPE g_tab_head_base_code         IS TABLE OF xxcos_dlv_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���_�R�[�h
  TYPE g_tab_head_perform_code      IS TABLE OF xxcos_dlv_headers.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���ю҃R�[�h
  TYPE g_tab_head_dlv_by_code       IS TABLE OF xxcos_dlv_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�҃R�[�h
  TYPE g_tab_head_hht_invoice_no    IS TABLE OF xxcos_dlv_headers.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT�`�[No.
  TYPE g_tab_head_dlv_date          IS TABLE OF xxcos_dlv_headers.dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i��
  TYPE g_tab_head_inspect_date      IS TABLE OF xxcos_dlv_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- ������
  TYPE g_tab_head_sales_class       IS TABLE OF xxcos_dlv_headers.sales_classification%TYPE
    INDEX BY PLS_INTEGER;   -- ���㕪�ދ敪
  TYPE g_tab_head_sales_invoice     IS TABLE OF xxcos_dlv_headers.sales_invoice%TYPE
    INDEX BY PLS_INTEGER;   -- ����`�[�敪
  TYPE g_tab_head_card_class        IS TABLE OF xxcos_dlv_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- �J�[�h���敪
  TYPE g_tab_head_dlv_time          IS TABLE OF xxcos_dlv_headers.dlv_time%TYPE
    INDEX BY PLS_INTEGER;   -- ����
  TYPE g_tab_head_change_time_100   IS TABLE OF xxcos_dlv_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;   -- ��K�؂ꎞ��100�~
  TYPE g_tab_head_change_time_10    IS TABLE OF xxcos_dlv_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;   -- ��K�؂ꎞ��10�~
  TYPE g_tab_head_cus_number        IS TABLE OF xxcos_dlv_headers.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�R�[�h
  TYPE g_tab_head_system_class      IS TABLE OF xxcos_dlv_headers.system_class%TYPE
    INDEX BY PLS_INTEGER;   -- �Ƒԋ敪
  TYPE g_tab_head_input_class       IS TABLE OF xxcos_dlv_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- ���͋敪
  TYPE g_tab_head_tax_class         IS TABLE OF xxcos_dlv_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����ŋ敪
  TYPE g_tab_head_total_amount      IS TABLE OF xxcos_dlv_headers.total_amount%TYPE
    INDEX BY PLS_INTEGER;   -- ���v���z
  TYPE g_tab_head_sale_discount     IS TABLE OF xxcos_dlv_headers.sale_discount_amount%TYPE
    INDEX BY PLS_INTEGER;   -- ����l���z
  TYPE g_tab_head_sales_tax         IS TABLE OF xxcos_dlv_headers.sales_consumption_tax%TYPE
    INDEX BY PLS_INTEGER;   -- �������Ŋz
  TYPE g_tab_head_tax_include       IS TABLE OF xxcos_dlv_headers.tax_include%TYPE
    INDEX BY PLS_INTEGER;   -- �ō����z
  TYPE g_tab_head_keep_in_code      IS TABLE OF xxcos_dlv_headers.keep_in_code%TYPE
    INDEX BY PLS_INTEGER;   -- �a����R�[�h
  TYPE g_tab_head_depart_screen     IS TABLE OF xxcos_dlv_headers.department_screen_class%TYPE
    INDEX BY PLS_INTEGER;   -- �S�ݓX��ʎ��
--
  -- �[�i���׃f�[�^�o�^�p�ϐ�
  TYPE g_tab_line_order_no_hht     IS TABLE OF xxcos_dlv_lines.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.�iHHT�j
  TYPE g_tab_line_line_no_hht      IS TABLE OF xxcos_dlv_lines.line_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- �sNo.�iHHT�j
  TYPE g_tab_line_order_no_ebs     IS TABLE OF xxcos_dlv_lines.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.�iEBS�j
  TYPE g_tab_line_line_num_ebs     IS TABLE OF xxcos_dlv_lines.line_number_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- ���הԍ�(EBS)
  TYPE g_tab_line_item_code_self   IS TABLE OF xxcos_dlv_lines.item_code_self%TYPE
    INDEX BY PLS_INTEGER;   -- �i���R�[�h�i���Ёj
  TYPE g_tab_line_content          IS TABLE OF xxcos_dlv_lines.content%TYPE
    INDEX BY PLS_INTEGER;   -- ����
  TYPE g_tab_line_item_id          IS TABLE OF xxcos_dlv_lines.inventory_item_id%TYPE
    INDEX BY PLS_INTEGER;   -- �i��ID
  TYPE g_tab_line_standard_unit    IS TABLE OF xxcos_dlv_lines.standard_unit%TYPE
    INDEX BY PLS_INTEGER;   -- ��P��
  TYPE g_tab_line_case_number      IS TABLE OF xxcos_dlv_lines.case_number%TYPE
    INDEX BY PLS_INTEGER;   -- �P�[�X��
  TYPE g_tab_line_quantity         IS TABLE OF xxcos_dlv_lines.quantity%TYPE
    INDEX BY PLS_INTEGER;   -- ����
  TYPE g_tab_line_sale_class       IS TABLE OF xxcos_dlv_lines.sale_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����敪
  TYPE g_tab_line_wholesale_unit   IS TABLE OF xxcos_dlv_lines.wholesale_unit_ploce%TYPE
    INDEX BY PLS_INTEGER;   -- ���P��
  TYPE g_tab_line_selling_price    IS TABLE OF xxcos_dlv_lines.selling_price%TYPE
    INDEX BY PLS_INTEGER;   -- ���P��
  TYPE g_tab_line_column_no        IS TABLE OF xxcos_dlv_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- �R����No.
  TYPE g_tab_line_h_and_c          IS TABLE OF xxcos_dlv_lines.h_and_c%TYPE
    INDEX BY PLS_INTEGER;   -- H/C
  TYPE g_tab_line_sold_out_class   IS TABLE OF xxcos_dlv_lines.sold_out_class%TYPE
    INDEX BY PLS_INTEGER;   -- ���؋敪
  TYPE g_tab_line_sold_out_time    IS TABLE OF xxcos_dlv_lines.sold_out_time%TYPE
    INDEX BY PLS_INTEGER;   -- ���؎���
  TYPE g_tab_line_replenish_num    IS TABLE OF xxcos_dlv_lines.replenish_number%TYPE
    INDEX BY PLS_INTEGER;   -- ��[��
  TYPE g_tab_line_cash_and_card    IS TABLE OF xxcos_dlv_lines.cash_and_card%TYPE
    INDEX BY PLS_INTEGER;   -- �����E�J�[�h���p�z
--
  -- �G���[�f�[�^�i�[�p�ϐ�
  TYPE g_tab_err_base_code           IS TABLE OF xxcos_rep_hht_err_list.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���_�R�[�h
  TYPE g_tab_err_base_name           IS TABLE OF xxcos_rep_hht_err_list.base_name%TYPE
    INDEX BY PLS_INTEGER;   -- ���_����
  TYPE g_tab_err_data_name           IS TABLE OF xxcos_rep_hht_err_list.data_name%TYPE
    INDEX BY PLS_INTEGER;   -- �f�[�^����
  TYPE g_tab_err_order_no_hht        IS TABLE OF xxcos_rep_hht_err_list.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��NO(HHT)
  TYPE g_tab_err_entry_number        IS TABLE OF xxcos_rep_hht_err_list.entry_number%TYPE
    INDEX BY PLS_INTEGER;   -- �`�[NO
  TYPE g_tab_err_line_no             IS TABLE OF xxcos_rep_hht_err_list.line_no%TYPE
    INDEX BY PLS_INTEGER;   -- �sNO
  TYPE g_tab_err_order_no_ebs        IS TABLE OF xxcos_rep_hht_err_list.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;   -- ��NO(EBS)
  TYPE g_tab_err_party_num           IS TABLE OF xxcos_rep_hht_err_list.party_num%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�R�[�h
  TYPE g_tab_err_customer_name       IS TABLE OF xxcos_rep_hht_err_list.customer_name%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq��
  TYPE g_tab_err_payment_dlv_date    IS TABLE OF xxcos_rep_hht_err_list.payment_dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- ����/�[�i��
  TYPE g_tab_err_perform_by_code     IS TABLE OF xxcos_rep_hht_err_list.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���ю҃R�[�h
  TYPE g_tab_err_item_code           IS TABLE OF xxcos_rep_hht_err_list.item_code%TYPE
    INDEX BY PLS_INTEGER;   -- �i�ڃR�[�h
  TYPE g_tab_err_error_message       IS TABLE OF xxcos_rep_hht_err_list.error_message%TYPE
    INDEX BY PLS_INTEGER;   -- �G���[���e
--
  -- �K��E�L�����ѓo�^�p�ϐ�
  TYPE g_tab_resource_id             IS TABLE OF jtf_rs_resource_extns.resource_id%TYPE
    INDEX BY PLS_INTEGER;   -- ���\�[�XID
  TYPE g_tab_party_id                IS TABLE OF hz_parties.party_id%TYPE
    INDEX BY PLS_INTEGER;   -- �p�[�e�BID
  TYPE g_tab_party_name              IS TABLE OF hz_parties.party_name%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq����
  TYPE g_tab_cus_status              IS TABLE OF hz_parties.duns_number_c%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�X�e�[�^�X
--
  -- �N�C�b�N�R�[�h�i�[�p
  -- �ڋq�X�e�[�^�X�i�[�p�ϐ�
  TYPE g_tab_qck_status   IS TABLE OF  hz_parties.duns_number_c%TYPE                  INDEX BY PLS_INTEGER;
  -- �J�[�h���敪�i�[�p�ϐ�
  TYPE g_tab_qck_card     IS TABLE OF  xxcos_dlv_headers.card_sale_class%TYPE         INDEX BY PLS_INTEGER;
  -- ���͋敪�i�g�p�\���ځj�i�[�p�ϐ�
  TYPE g_tab_qck_inp_able IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- ���͋敪�i�[�i�f�[�^�j�i�[�p�ϐ�
  TYPE g_tab_qck_inp_dlv  IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- ���͋敪�i�ԕi�f�[�^�j�i�[�p�ϐ�
  TYPE g_tab_qck_inp_ret  IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- ���͋敪�i�t��VD�[�i�E�����z��j�i�[�p�ϐ�
  TYPE g_tab_qck_inp_auto IS TABLE OF  xxcos_dlv_headers.input_class%TYPE             INDEX BY PLS_INTEGER;
  -- �Ƒԁi�����ށj�i�[�p�ϐ�
  TYPE g_tab_qck_busi     IS TABLE OF  xxcmm_cust_accounts.business_low_type%TYPE     INDEX BY PLS_INTEGER;
  -- ����ŋ敪�i�[�p�ϐ�
  TYPE g_tax_class IS RECORD
    (
      tax_cl   xxcos_dlv_headers.consumption_tax_class%TYPE              -- �ϊ��O�̏���ŋ敪
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
--      dff3     xxcos_dlv_headers.consumption_tax_class%TYPE               -- �ϊ���̏���ŋ敪
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
    );
  TYPE g_tab_qck_tax      IS TABLE OF  g_tax_class   INDEX BY PLS_INTEGER;
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  -- �S�ݓX��ʎ�ʊi�[�p�ϐ�
--  TYPE g_tab_qck_depart   IS TABLE OF  xxcos_dlv_headers.department_screen_class%TYPE INDEX BY PLS_INTEGER;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
  -- �i�ڃX�e�[�^�X�i�[�p�ϐ�
  TYPE g_tab_qck_item     IS TABLE OF  xxcmm_system_items_b.item_status%TYPE          INDEX BY PLS_INTEGER;
  -- ����敪�i�[�p�ϐ�
  TYPE g_tab_qck_sale     IS TABLE OF  xxcos_dlv_lines.sale_class%TYPE                INDEX BY PLS_INTEGER;
  -- H/C�i�[�p�ϐ�
  TYPE g_tab_qck_hc       IS TABLE OF  xxcos_dlv_lines.h_and_c%TYPE                   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �[�i�w�b�_�e�[�u���o�^�f�[�^
  gt_head_order_no_hht      g_tab_head_order_no_hht;        -- ��No.�iHHT�j
  gt_head_order_no_ebs      g_tab_head_order_no_ebs;        -- ��No.�iEBS�j
  gt_head_base_code         g_tab_head_base_code;           -- ���_�R�[�h
  gt_head_perform_code      g_tab_head_perform_code;        -- ���ю҃R�[�h
  gt_head_dlv_by_code       g_tab_head_dlv_by_code;         -- �[�i�҃R�[�h
  gt_head_hht_invoice_no    g_tab_head_hht_invoice_no;      -- HHT�`�[No.
  gt_head_dlv_date          g_tab_head_dlv_date;            -- �[�i��
  gt_head_inspect_date      g_tab_head_inspect_date;        -- ������
  gt_head_sales_class       g_tab_head_sales_class;         -- ���㕪�ދ敪
  gt_head_sales_invoice     g_tab_head_sales_invoice;       -- ����`�[�敪
  gt_head_card_class        g_tab_head_card_class;          -- �J�[�h���敪
  gt_head_dlv_time          g_tab_head_dlv_time;            -- ����
  gt_head_change_time_100   g_tab_head_change_time_100;     -- ��K�؂ꎞ��100�~
  gt_head_change_time_10    g_tab_head_change_time_10;      -- ��K�؂ꎞ��10�~
  gt_head_cus_number        g_tab_head_cus_number;          -- �ڋq�R�[�h
  gt_head_system_class      g_tab_head_system_class;        -- �Ƒԋ敪
  gt_head_input_class       g_tab_head_input_class;         -- ���͋敪
  gt_head_tax_class         g_tab_head_tax_class;           -- ����ŋ敪
  gt_head_total_amount      g_tab_head_total_amount;        -- ���v���z
  gt_head_sale_discount     g_tab_head_sale_discount;       -- ����l���z
  gt_head_sales_tax         g_tab_head_sales_tax;           -- �������Ŋz
  gt_head_tax_include       g_tab_head_tax_include;         -- �ō����z
  gt_head_keep_in_code      g_tab_head_keep_in_code;        -- �a����R�[�h
  gt_head_depart_screen     g_tab_head_depart_screen;       -- �S�ݓX��ʎ��
--
  -- �[�i���׃e�[�u���o�^�f�[�^
  gt_line_order_no_hht      g_tab_line_order_no_hht;        -- ��No.�iHHT�j
  gt_line_line_no_hht       g_tab_line_line_no_hht;         -- �sNo.�iHHT�j
  gt_line_order_no_ebs      g_tab_line_order_no_ebs;        -- ��No.�iEBS�j
  gt_line_line_num_ebs      g_tab_line_line_num_ebs;        -- ���הԍ�(EBS)
  gt_line_item_code_self    g_tab_line_item_code_self;      -- �i���R�[�h�i���Ёj
  gt_line_content           g_tab_line_content;             -- ����
  gt_line_item_id           g_tab_line_item_id;             -- �i��ID
  gt_line_standard_unit     g_tab_line_standard_unit;       -- ��P��
  gt_line_case_number       g_tab_line_case_number;         -- �P�[�X��
  gt_line_quantity          g_tab_line_quantity;            -- ����
  gt_line_sale_class        g_tab_line_sale_class;          -- ����敪
  gt_line_wholesale_unit    g_tab_line_wholesale_unit;      -- ���P��
  gt_line_selling_price     g_tab_line_selling_price;       -- ���P��
  gt_line_column_no         g_tab_line_column_no;           -- �R����No.
  gt_line_h_and_c           g_tab_line_h_and_c;             -- H/C
  gt_line_sold_out_class    g_tab_line_sold_out_class;      -- ���؋敪
  gt_line_sold_out_time     g_tab_line_sold_out_time;       -- ���؎���
  gt_line_replenish_num     g_tab_line_replenish_num;       -- ��[��
  gt_line_cash_and_card     g_tab_line_cash_and_card;       -- �����E�J�[�h���p�z
--
  -- HHT�G���[���X�g���[���[�N�e�[�u���o�^�f�[�^
  gt_err_base_code          g_tab_err_base_code;            -- ���_�R�[�h
  gt_err_base_name          g_tab_err_base_name;            -- ���_����
  gt_err_data_name          g_tab_err_data_name;            -- �f�[�^����
  gt_err_order_no_hht       g_tab_err_order_no_hht;         -- ��NO(HHT)
  gt_err_entry_number       g_tab_err_entry_number;         -- �`�[NO
  gt_err_line_no            g_tab_err_line_no;              -- �sNO
  gt_err_order_no_ebs       g_tab_err_order_no_ebs;         -- ��NO(EBS)
  gt_err_party_num          g_tab_err_party_num;            -- �ڋq�R�[�h
  gt_err_customer_name      g_tab_err_customer_name;        -- �ڋq��
  gt_err_payment_dlv_date   g_tab_err_payment_dlv_date;     -- ����/�[�i��
  gt_err_perform_by_code    g_tab_err_perform_by_code;      -- ���ю҃R�[�h
  gt_err_item_code          g_tab_err_item_code;            -- �i�ڃR�[�h
  gt_err_error_message      g_tab_err_error_message;        -- �G���[���e
--
  -- �K��E�L�����ѓo�^�p�ϐ�
  gt_resource_id            g_tab_resource_id;              -- ���\�[�XID
  gt_party_id               g_tab_party_id;                 -- �p�[�e�BID
  gt_party_name             g_tab_party_name;               -- �ڋq����
  gt_cus_status             g_tab_cus_status;               -- �ڋq�X�e�[�^�X
--
  gt_headers_work_data      g_tab_headwk_data;              -- �[�i�w�b�_���[�N�e�[�u�����o�f�[�^
  gt_lines_work_data        g_tab_linewk_data;              -- �[�i���׃��[�N�e�[�u�����o�f�[�^
  gt_select_cus             g_tab_select_cus;               -- ���_�R�[�h�A�ڋq�R�[�h�̑Ó����`�F�b�N�F���o����
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
  gt_select_perf            g_tab_select_perf;              -- ���ю҃R�[�h�̑Ó����`�F�b�N�F���o����
  gt_select_dlv             g_tab_select_dlv;               -- �[�i�҃R�[�h�̑Ó����`�F�b�N�F���o����
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
  gt_select_item            g_tab_select_item;              -- �i�ڃR�[�h�̑Ó����`�F�b�N�F���o����
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--  gt_select_vd              g_tab_select_vd;                -- VD�R�����}�X�^�Ƃ̐������`�F�b�N�F���o����
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
  gt_qck_status             g_tab_qck_status;               -- �ڋq�X�e�[�^�X
  gt_qck_card               g_tab_qck_card;                 -- �J�[�h���敪
  gt_qck_inp_able           g_tab_qck_inp_able;             -- ���͋敪�i�g�p�\���ځj
  gt_qck_inp_dlv            g_tab_qck_inp_dlv;              -- ���͋敪�i�[�i�f�[�^�j
  gt_qck_inp_ret            g_tab_qck_inp_ret;              -- ���͋敪�i�ԕi�f�[�^�j
  gt_qck_inp_auto           g_tab_qck_inp_auto;             -- ���͋敪�i�t��VD�[�i�E�����z��j
  gt_qck_busi               g_tab_qck_busi;                 -- �Ƒԁi�����ށj
  gt_qck_tax                g_tab_qck_tax;                  -- ����ŋ敪
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  gt_qck_depart             g_tab_qck_depart;               -- �S�ݓX��ʎ��
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
  gt_qck_item               g_tab_qck_item;                 -- �i�ڃX�e�[�^�X
  gt_qck_sale               g_tab_qck_sale;                 -- ����敪
  gt_qck_hc                 g_tab_qck_hc;                   -- H/C
  gn_purge_date             NUMBER;                         -- �p�[�W�������
  gn_orga_id                NUMBER;                         -- �݌ɑg�DID
  gd_max_date               DATE;                           -- MAX���t
  gd_process_date           DATE;                           -- �Ɩ�������
  gv_mode                   VARCHAR2(1);                    -- �N�����[�h
  gn_tar_cnt_h              NUMBER;                         -- �w�b�_�Ώی���
  gn_tar_cnt_l              NUMBER;                         -- ���בΏی���
  gn_nor_cnt_h              NUMBER;                         -- �w�b�_��������
  gn_nor_cnt_l              NUMBER;                         -- ���א�������
  gn_del_cnt_h              NUMBER;                         -- �w�b�_�폜����
  gn_del_cnt_l              NUMBER;                         -- ���׍폜����
  gv_tkn1                   VARCHAR2(50);                   -- �G���[���b�Z�[�W�p�g�[�N���P
  gv_tkn2                   VARCHAR2(50);                   -- �G���[���b�Z�[�W�p�g�[�N���Q
  gv_tkn3                   VARCHAR2(50);                   -- �G���[���b�Z�[�W�p�g�[�N���R
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
  gn_wh_del_count           NUMBER;                         -- �w�b�_���[�N�폜����
  gn_wl_del_count           NUMBER;                         -- ���׃��[�N�폜����
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
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
    --==============================================================
    -- �u�p�����[�^�o�̓��b�Z�[�W�v���o��
    --==============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    IF ( gv_mode = cv_daytime ) THEN      -- ���ԃ��[�h
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode1 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- ���b�Z�[�W���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
    ELSIF ( gv_mode = cv_night ) THEN   -- ��ԃ��[�h
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode2 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- ���b�Z�[�W���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
    ELSIF ( gv_mode = cv_truncate ) THEN    -- �N�����̏���
      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_mode3 );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
      -- ���b�Z�[�W���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg( cv_application,
                                             cv_msg_para,
                                             cv_tkn_para1,
                                             gv_mode,
                                             cv_tkn_para2,
                                             gv_tkn1
                                           )
      );
--
--****************************** 2010/01/27 1.23 N.Maeda  MOD END   *******************************--
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Procedure Name   : dlv_data_receive
   * Description      : �[�i�f�[�^���o(A-1)
   ***********************************************************************************/
  PROCEDURE dlv_data_receive(
    on_target_cnt     OUT NUMBER,           --   ���o�����i�w�b�_�j
    on_line_cnt       OUT NUMBER,           --   ���o�����i���ׁj
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_receive'; -- �v���O������
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
    lv_max_date      VARCHAR2(50);      -- MAX���t
    lv_orga_code     VARCHAR2(10);      -- �݌ɑg�D�R�[�h
    ld_process_date  DATE;              -- �Ɩ�������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- �[�i�w�b�_���[�N�e�[�u���f�[�^���o
    CURSOR get_headers_data_cur
    IS
--****************************** 2009/05/01 1.12 MOD START ******************************--
--      SELECT headers.order_no_hht             order_no_hht,             -- ��No.�iHHT)
--             headers.order_no_ebs             order_no_ebs,             -- ��No.�iEBS�j
--             headers.base_code                base_code,                -- ���_�R�[�h
--             headers.performance_by_code      performance_by_code,      -- ���ю҃R�[�h
--             headers.dlv_by_code              dlv_by_code,              -- �[�i�҃R�[�h
--             headers.hht_invoice_no           hht_invoice_no,           -- HHT�`�[No.
--             headers.dlv_date                 dlv_date,                 -- �[�i��
--             headers.inspect_date             inspect_date,             -- ������
--             headers.sales_classification     sales_classification,     -- ���㕪�ދ敪
--             headers.sales_invoice            sales_invoice,            -- ����`�[�敪
--             headers.card_sale_class          card_sale_class,          -- �J�[�h���敪
--             headers.dlv_time                 dlv_time,                 -- ����
--             headers.change_out_time_100      change_out_time_100,      -- ��K�؂ꎞ��100�~
--             headers.change_out_time_10       change_out_time_10,       -- ��K�؂ꎞ��10�~
--             headers.customer_number          customer_number,          -- �ڋq�R�[�h
--             headers.input_class              input_class,              -- ���͋敪
--             headers.consumption_tax_class    consumption_tax_class,    -- ����ŋ敪
--             headers.total_amount             total_amount,             -- ���v���z
--             headers.sale_discount_amount     sale_discount_amount,     -- ����l���z
--             headers.sales_consumption_tax    sales_consumption_tax,    -- �������Ŋz
--             headers.tax_include              tax_include,              -- �ō����z
--             headers.keep_in_code             keep_in_code,             -- �a����R�[�h
--             headers.department_screen_class  department_screen_class   -- �S�ݓX��ʎ��
--      FROM   xxcos_dlv_headers_work           headers                   -- �[�i�w�b�_���[�N�e�[�u��
--      ORDER BY order_no_hht
--      FOR UPDATE NOWAIT;
      SELECT headers.order_no_hht                    order_no_hht,             -- ��No.�iHHT)
             headers.order_no_ebs                    order_no_ebs,             -- ��No.�iEBS�j
             TRIM( headers.base_code )               base_code,                -- ���_�R�[�h
             TRIM( headers.performance_by_code )     performance_by_code,      -- ���ю҃R�[�h
             TRIM( headers.dlv_by_code )             dlv_by_code,              -- �[�i�҃R�[�h
             TRIM( headers.hht_invoice_no )          hht_invoice_no,           -- HHT�`�[No.
             headers.dlv_date                        dlv_date,                 -- �[�i��
             headers.inspect_date                    inspect_date,             -- ������
             TRIM( headers.sales_classification )    sales_classification,     -- ���㕪�ދ敪
             TRIM( headers.sales_invoice )           sales_invoice,            -- ����`�[�敪
             TRIM( headers.card_sale_class )         card_sale_class,          -- �J�[�h���敪
             TRIM( headers.dlv_time )                dlv_time,                 -- ����
             TRIM( headers.change_out_time_100 )     change_out_time_100,      -- ��K�؂ꎞ��100�~
             TRIM( headers.change_out_time_10 )      change_out_time_10,       -- ��K�؂ꎞ��10�~
             TRIM( headers.customer_number )         customer_number,          -- �ڋq�R�[�h
             TRIM( headers.input_class )             input_class,              -- ���͋敪
             TRIM( headers.consumption_tax_class )   consumption_tax_class,    -- ����ŋ敪
             headers.total_amount                    total_amount,             -- ���v���z
             headers.sale_discount_amount            sale_discount_amount,     -- ����l���z
             headers.sales_consumption_tax           sales_consumption_tax,    -- �������Ŋz
             headers.tax_include                     tax_include,              -- �ō����z
             TRIM( headers.keep_in_code )            keep_in_code,             -- �a����R�[�h
             TRIM( headers.department_screen_class ) department_screen_class   -- �S�ݓX��ʎ��
      FROM   xxcos_dlv_headers_work           headers                   -- �[�i�w�b�_���[�N�e�[�u��
      ORDER BY order_no_hht
      FOR UPDATE NOWAIT;
--****************************** 2009/05/01 1.12 MOD  END ******************************--
--
    -- �[�i���׃��[�N�e�[�u���f�[�^���o
    CURSOR get_lines_data_cur
    IS
--****************************** 2009/05/01 1.12 MOD START ******************************--
--      SELECT lines.order_no_hht           order_no_hht,           -- ��No.�iHHT�j
--             lines.line_no_hht            line_no_hht,            -- �sNo.�iHHT�j
--             lines.order_no_ebs           order_no_ebs,           -- ��No.�iEBS�j
--             lines.line_number_ebs        line_number_ebs,        -- ���הԍ�(EBS)
--             lines.item_code_self         item_code_self,         -- �i���R�[�h�i���Ёj
--             lines.case_number            case_number,            -- �P�[�X��
--             lines.quantity               quantity,               -- ����
--             lines.sale_class             sale_class,             -- ����敪
--             lines.wholesale_unit_ploce   wholesale_unit_ploce,   -- ���P��
--             lines.selling_price          selling_price,          -- ���P��
--             lines.column_no              column_no,              -- �R����No.
--             lines.h_and_c                h_and_c,                -- H/C
--             lines.sold_out_class         sold_out_class,         -- ���؋敪
--             lines.sold_out_time          sold_out_time,          -- ���؎���
--             lines.cash_and_card          cash_and_card           -- �����E�J�[�h���p�z
--      FROM   xxcos_dlv_lines_work         lines                   -- �[�i���׃��[�N�e�[�u��
--      ORDER BY order_no_hht, line_no_hht
--      FOR UPDATE NOWAIT;
      SELECT lines.order_no_hht           order_no_hht,           -- ��No.�iHHT�j
             lines.line_no_hht            line_no_hht,            -- �sNo.�iHHT�j
             lines.order_no_ebs           order_no_ebs,           -- ��No.�iEBS�j
             lines.line_number_ebs        line_number_ebs,        -- ���הԍ�(EBS)
             TRIM( lines.item_code_self ) item_code_self,         -- �i���R�[�h�i���Ёj
             lines.case_number            case_number,            -- �P�[�X��
             lines.quantity               quantity,               -- ����
             TRIM( lines.sale_class )     sale_class,             -- ����敪
             lines.wholesale_unit_ploce   wholesale_unit_ploce,   -- ���P��
             lines.selling_price          selling_price,          -- ���P��
             TRIM( lines.column_no )      column_no,              -- �R����No.
             TRIM( lines.h_and_c )        h_and_c,                -- H/C
             TRIM( lines.sold_out_class ) sold_out_class,         -- ���؋敪
             TRIM( lines.sold_out_time )  sold_out_time,          -- ���؎���
             lines.cash_and_card          cash_and_card           -- �����E�J�[�h���p�z
      FROM   xxcos_dlv_lines_work         lines                   -- �[�i���׃��[�N�e�[�u��
      ORDER BY order_no_hht, line_no_hht
      FOR UPDATE NOWAIT;
--****************************** 2009/05/01 1.12 MOD  END ******************************--
--
    -- �N�C�b�N�R�[�h�擾�F�ڋq�X�e�[�^�X
    CURSOR get_cus_status_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type = cv_qck_typ_status
      AND     look_val.lookup_code LIKE cv_qck_typ_a01
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type = cv_qck_typ_status
--      AND     look_val.lookup_code LIKE cv_qck_typ_a01
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F�J�[�h���敪
    CURSOR get_card_sales_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_card
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_card
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�g�p�\���ځj
    CURSOR get_input_enabled_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�[�i�f�[�^�j
    CURSOR get_input_dlv_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute3   = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute3   = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�ԕi�f�[�^�j
    CURSOR get_input_return_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute3   = cv_tkn_no;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute3   = cv_tkn_no;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�t��VD�[�i�E�����z��j
    CURSOR get_input_auto_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_input
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.attribute2   = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_input
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.attribute2   = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F�Ƒԁi�����ށj
    CURSOR get_gyotai_sho_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_gyotai
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_gyotai
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F����ŋ敪
    CURSOR get_tax_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
--              look_val.attribute3   attribute3
-- ********** 2009/09/01 1.15 N.Maeda DEL START ******** --
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_tax
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_tax
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--    -- �N�C�b�N�R�[�h�擾�F�S�ݓX��ʎ��
--    CURSOR get_depart_screen_cur
--    IS
--      SELECT  look_val.lookup_code  lookup_code
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_depart
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
--
    -- �N�C�b�N�R�[�h�擾�F�i�ڃX�e�[�^�X
    CURSOR get_item_status_cur
    IS
      SELECT  look_val.meaning      meaning
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_item
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_item
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�F����敪
    CURSOR get_sale_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_sale
      AND     look_val.attribute1   = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_sale
--      AND     look_val.attribute1   = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
    -- �N�C�b�N�R�[�h�擾�FH/C
    CURSOR get_hc_class_cur
    IS
      SELECT  look_val.lookup_code  lookup_code
-- ******* 2009/10/01 N.Maeda MOD START ********* --
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.language = cv_user_lang
      AND     look_val.lookup_type  = cv_qck_typ_hc
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.enabled_flag = cv_tkn_yes;
--
--      FROM    fnd_lookup_values     look_val,
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--      WHERE   appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
--      AND     types_tl.language = USERENV( 'LANG' )
--      AND     look_val.language = USERENV( 'LANG' )
--      AND     appl.language     = USERENV( 'LANG' )
--      AND     app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_typ_hc
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     look_val.enabled_flag = cv_tkn_yes;
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���o����������
    on_target_cnt :=0;
    on_line_cnt   :=0;
--
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOI:�݌ɑg�D�R�[�h)
    --==============================================================
    lv_orga_code := FND_PROFILE.VALUE( cv_prf_orga_code );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_orga_code IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga_code );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾(XXCOS:MAX���t)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==============================================================
    -- ���ʊ֐����݌ɑg�DID�擾���̌Ăяo��
    --==============================================================
    gn_orga_id := xxcoi_common_pkg.get_organization_id( lv_orga_code );
--
    -- �݌ɑg�DID�擾�G���[�̏ꍇ
    IF ( gn_orga_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_orga );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ���ʊ֐����Ɩ��������擾���̌Ăяo��
    --==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- �N�C�b�N�R�[�h�̎擾
    --==============================================================
    -- �N�C�b�N�R�[�h�擾�F�ڋq�X�e�[�^�X
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_cus_status_cur;
      -- �o���N�t�F�b�`
      FETCH get_cus_status_cur BULK COLLECT INTO gt_qck_status;
      -- �J�[�\��CLOSE
      CLOSE get_cus_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F�ڋq�X�e�[�^�X
        IF ( get_cus_status_cur%ISOPEN ) THEN
          CLOSE get_cus_status_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_status );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_cust_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F�J�[�h���敪
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_card_sales_cur;
      -- �o���N�t�F�b�`
      FETCH get_card_sales_cur BULK COLLECT INTO gt_qck_card;
      -- �J�[�\��CLOSE
      CLOSE get_card_sales_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F�J�[�h���敪
        IF ( get_card_sales_cur%ISOPEN ) THEN
          CLOSE get_card_sales_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_card );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_card );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�g�p�\���ځj
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_input_enabled_cur;
      -- �o���N�t�F�b�`
      FETCH get_input_enabled_cur BULK COLLECT INTO gt_qck_inp_able;
      -- �J�[�\��CLOSE
      CLOSE get_input_enabled_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F���͋敪�i�g�p�\���ځj
        IF ( get_input_enabled_cur%ISOPEN ) THEN
          CLOSE get_input_enabled_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�[�i�f�[�^�j
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_input_dlv_cur;
      -- �o���N�t�F�b�`
      FETCH get_input_dlv_cur BULK COLLECT INTO gt_qck_inp_dlv;
      -- �J�[�\��CLOSE
      CLOSE get_input_dlv_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F���͋敪�i�[�i�f�[�^�j
        IF ( get_input_dlv_cur%ISOPEN ) THEN
          CLOSE get_input_dlv_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�ԕi�f�[�^�j
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_input_return_cur;
      -- �o���N�t�F�b�`
      FETCH get_input_return_cur BULK COLLECT INTO gt_qck_inp_ret;
      -- �J�[�\��CLOSE
      CLOSE get_input_return_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F���͋敪�i�ԕi�f�[�^�j
        IF ( get_input_return_cur%ISOPEN ) THEN
          CLOSE get_input_return_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F���͋敪�i�t��VD�[�i�E�����z��j
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_input_auto_cur;
      -- �o���N�t�F�b�`
      FETCH get_input_auto_cur BULK COLLECT INTO gt_qck_inp_auto;
      -- �J�[�\��CLOSE
      CLOSE get_input_auto_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F���͋敪�i�t��VD�[�i�E�����z��j
        IF ( get_input_auto_cur%ISOPEN ) THEN
          CLOSE get_input_auto_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_input );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F�Ƒԁi�����ށj
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_gyotai_sho_cur;
      -- �o���N�t�F�b�`
      FETCH get_gyotai_sho_cur BULK COLLECT INTO gt_qck_busi;
      -- �J�[�\��CLOSE
      CLOSE get_gyotai_sho_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F�Ƒԁi�����ށj
        IF ( get_gyotai_sho_cur%ISOPEN ) THEN
          CLOSE get_gyotai_sho_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_gyotai );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_busi_low );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F����ŋ敪
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_tax_class_cur;
      -- �o���N�t�F�b�`
      FETCH get_tax_class_cur BULK COLLECT INTO gt_qck_tax;
      -- �J�[�\��CLOSE
      CLOSE get_tax_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F����ŋ敪
        IF ( get_tax_class_cur%ISOPEN ) THEN
          CLOSE get_tax_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_tax );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax );
--
        RAISE lookup_types_expt;
    END;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--    -- �N�C�b�N�R�[�h�擾�F�S�ݓX��ʎ��
--    BEGIN
--      -- �J�[�\��OPEN
--      OPEN  get_depart_screen_cur;
--      -- �o���N�t�F�b�`
--      FETCH get_depart_screen_cur BULK COLLECT INTO gt_qck_depart;
--      -- �J�[�\��CLOSE
--      CLOSE get_depart_screen_cur;
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F�S�ݓX��ʎ��
--        IF ( get_depart_screen_cur%ISOPEN ) THEN
--          CLOSE get_depart_screen_cur;
--        END IF;
----
--        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_depart );
--        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_depart );
----
--        RAISE lookup_types_expt;
--    END;
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
--
    -- �N�C�b�N�R�[�h�擾�F�i�ڃX�e�[�^�X
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_item_status_cur;
      -- �o���N�t�F�b�`
      FETCH get_item_status_cur BULK COLLECT INTO gt_qck_item;
      -- �J�[�\��CLOSE
      CLOSE get_item_status_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F�i�ڃX�e�[�^�X
        IF ( get_item_status_cur%ISOPEN ) THEN
          CLOSE get_item_status_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_item );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_st );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�F����敪
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_sale_class_cur;
      -- �o���N�t�F�b�`
      FETCH get_sale_class_cur BULK COLLECT INTO gt_qck_sale;
      -- �J�[�\��CLOSE
      CLOSE get_sale_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�F����敪
        IF ( get_sale_class_cur%ISOPEN ) THEN
          CLOSE get_sale_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_sale );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale );
--
        RAISE lookup_types_expt;
    END;
--
    -- �N�C�b�N�R�[�h�擾�FH/C
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_hc_class_cur;
      -- �o���N�t�F�b�`
      FETCH get_hc_class_cur BULK COLLECT INTO gt_qck_hc;
      -- �J�[�\��CLOSE
      CLOSE get_hc_class_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�N�C�b�N�R�[�h�擾�FH/C
        IF ( get_hc_class_cur%ISOPEN ) THEN
          CLOSE get_hc_class_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_typ_hc );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_h_c );
--
        RAISE lookup_types_expt;
    END;
--
    --==============================================================
    -- �[�i�w�b�_���[�N�e�[�u���f�[�^�擾
    --==============================================================
    BEGIN
--
      -- �J�[�\��OPEN
      OPEN  get_headers_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_headers_data_cur BULK COLLECT INTO gt_headers_work_data;
      -- ���o�����Z�b�g
      on_target_cnt := get_headers_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_headers_data_cur;
--
    EXCEPTION
--
      -- ���b�N�G���[
      WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
--
        -- �J�[�\��CLOSE�F�[�i�w�b�_���[�N�e�[�u���f�[�^�擾
        IF ( get_headers_data_cur%ISOPEN ) THEN
          CLOSE get_headers_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- �G���[�����i�f�[�^���o�G���[�j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- �[�i���׃��[�N�e�[�u���f�[�^�擾
    --==============================================================
    BEGIN
--
      -- �J�[�\��OPEN
      OPEN  get_lines_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_lines_data_cur BULK COLLECT INTO gt_lines_work_data;
      -- ���o�����Z�b�g
      on_line_cnt := get_lines_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_lines_data_cur;
--
    EXCEPTION
--
      -- ���b�N�G���[
      WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
--
        -- �J�[�\��CLOSE�F�[�i���׃��[�N�e�[�u���f�[�^�擾
        IF ( get_lines_data_cur%ISOPEN ) THEN
          CLOSE get_lines_data_cur;
        END IF;
--
        RAISE global_api_expt;
--
      -- �G���[�����i�f�[�^���o�G���[�j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_get, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
    WHEN lookup_types_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  gv_tkn1,
                                                                                cv_tkn_type,   gv_tkn2,
                                                                                cv_tkn_colmun, gv_tkn3 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_receive;
--
  /***********************************************************************************
   * Procedure Name   : data_check
   * Description      : �f�[�^�Ó����`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_line_cnt       IN  NUMBER,           --   ���������i���ו��j
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- �v���O������
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
    cv_month     CONSTANT VARCHAR2(5) := 'MONTH';
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--    cv_ar_class  CONSTANT VARCHAR2(2) := '02';
    cv_inv_class CONSTANT VARCHAR2(2) := '01';
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
    cv_open      CONSTANT VARCHAR2(4) := 'OPEN';
--***************************** 2009/04/10 1.8 T.Kitajima ADD START  *****************************--
    ct_hht_2     CONSTANT xxcmm_cust_accounts.dept_hht_div%TYPE          := '2';    -- �S�ݓX�pHHT�敪
    ct_disp_0    CONSTANT xxcos_dlv_headers.department_screen_class%TYPE := '0';    -- �S�ݓX��ʎ��
--***************************** 2009/04/10 1.8 T.Kitajima ADD START  *****************************--
--
    -- *** ���[�J���^   ***
    -- �[�i���׃f�[�^�ꎞ�i�[�p�ϐ�
    TYPE l_rec_line_temp IS RECORD
      (
        order_nol_hht        xxcos_dlv_lines.order_no_hht%TYPE,                 -- ��No.(HHT)
        line_no_hht          xxcos_dlv_lines.line_no_hht%TYPE,                  -- �sNo.(HHT)
        order_nol_ebs        xxcos_dlv_lines.order_no_ebs%TYPE,                 -- ��No.(EBS)
        line_number          xxcos_dlv_lines.line_number_ebs%TYPE,              -- ���הԍ�(EBS)
        item_code            xxcos_dlv_lines.item_code_self%TYPE,               -- �i���R�[�h(����)
        content              xxcos_dlv_lines.content%TYPE,                      -- ����
        item_id              xxcos_dlv_lines.inventory_item_id%TYPE,            -- �i��ID
        standard_unit        xxcos_dlv_lines.standard_unit%TYPE,                -- ��P��
        case_number          xxcos_dlv_lines.case_number%TYPE,                  -- �P�[�X��
        quantity             xxcos_dlv_lines.quantity%TYPE,                     -- ����
        sale_class           xxcos_dlv_lines.sale_class%TYPE,                   -- ����敪
        wholesale_price      xxcos_dlv_lines.wholesale_unit_ploce%TYPE,         -- ���P��
        selling_price        xxcos_dlv_lines.selling_price%TYPE,                -- ���P��
        column_no            xxcos_dlv_lines.column_no%TYPE,                    -- �R����No.
        h_and_c              xxcos_dlv_lines.h_and_c%TYPE,                      -- H/C
        sold_out_class       xxcos_dlv_lines.sold_out_class%TYPE,               -- ���؋敪
        sold_out_time        xxcos_dlv_lines.sold_out_time%TYPE,                -- ���؎���
        replenish_num        xxcos_dlv_lines.replenish_number%TYPE,             -- ��[��
        cash_and_card        xxcos_dlv_lines.cash_and_card%TYPE                 -- �����E�J�[�h���p�z
      );
    TYPE l_tab_line_temp IS TABLE OF l_rec_line_temp INDEX BY PLS_INTEGER;
--
    -- *** ���[�J���ϐ� ***
    lt_line_temp   l_tab_line_temp;       -- �[�i���׃f�[�^�ꎞ�i�[�p
--
    -- �[�i�w�b�_�f�[�^�ϐ�
    lt_order_noh_hht        xxcos_dlv_headers.order_no_hht%TYPE;               -- ��No.(HHT)
    lt_order_noh_ebs        xxcos_dlv_headers.order_no_ebs%TYPE;               -- ��No.(EBS)
    lt_base_code            xxcos_dlv_headers.base_code%TYPE;                  -- ���_�R�[�h
    lt_performance_code     xxcos_dlv_headers.performance_by_code%TYPE;        -- ���ю҃R�[�h
    lt_dlv_code             xxcos_dlv_headers.dlv_by_code%TYPE;                -- �[�i�҃R�[�h
    lt_hht_invoice_no       xxcos_dlv_headers.hht_invoice_no%TYPE;             -- HHT�`�[No.
    lt_dlv_date             xxcos_dlv_headers.dlv_date%TYPE;                   -- �[�i��
    lt_inspect_date         xxcos_dlv_headers.inspect_date%TYPE;               -- ������
    lt_sales_class          xxcos_dlv_headers.sales_classification%TYPE;       -- ���㕪�ދ敪
    lt_sales_invoice        xxcos_dlv_headers.sales_invoice%TYPE;              -- ����`�[�敪
    lt_card_sale_class      xxcos_dlv_headers.card_sale_class%TYPE;            -- �J�[�h���敪
    lt_dlv_time             xxcos_dlv_headers.dlv_time%TYPE;                   -- ����
    lt_change_out_100       xxcos_dlv_headers.change_out_time_100%TYPE;        -- ��K�؂ꎞ��100�~
    lt_change_out_10        xxcos_dlv_headers.change_out_time_10%TYPE;         -- ��K�؂ꎞ��10�~
    lt_customer_number      xxcos_dlv_headers.customer_number%TYPE;            -- �ڋq�R�[�h
    lt_system_class         xxcos_dlv_headers.system_class%TYPE;               -- �Ƒԋ敪
    lt_input_class          xxcos_dlv_headers.input_class%TYPE;                -- ���͋敪
    lt_tax_class            xxcos_dlv_headers.consumption_tax_class%TYPE;      -- ����ŋ敪
    lt_total_amount         xxcos_dlv_headers.total_amount%TYPE;               -- ���v���z
    lt_sale_discount        xxcos_dlv_headers.sale_discount_amount%TYPE;       -- ����l���z
    lt_sales_tax            xxcos_dlv_headers.sales_consumption_tax%TYPE;      -- �������Ŋz
    lt_tax_include          xxcos_dlv_headers.tax_include%TYPE;                -- �ō����z
    lt_keep_in_code         xxcos_dlv_headers.keep_in_code%TYPE;               -- �a����R�[�h
    lt_department_class     xxcos_dlv_headers.department_screen_class%TYPE;    -- �S�ݓX��ʎ��
--
    -- �[�i���׃f�[�^�ϐ�
    lt_order_nol_hht        xxcos_dlv_lines.order_no_hht%TYPE;                 -- ��No.(HHT)
    lt_line_no_hht          xxcos_dlv_lines.line_no_hht%TYPE;                  -- �sNo.(HHT)
    lt_order_nol_ebs        xxcos_dlv_lines.order_no_ebs%TYPE;                 -- ��No.(EBS)
    lt_line_number          xxcos_dlv_lines.line_number_ebs%TYPE;              -- ���הԍ�(EBS)
    lt_item_code            xxcos_dlv_lines.item_code_self%TYPE;               -- �i���R�[�h(����)
    lt_content              xxcos_dlv_lines.content%TYPE;                      -- ����
    lt_item_id              xxcos_dlv_lines.inventory_item_id%TYPE;            -- �i��ID
    lt_standard_unit        xxcos_dlv_lines.standard_unit%TYPE;                -- ��P��
    lt_case_number          xxcos_dlv_lines.case_number%TYPE;                  -- �P�[�X��
    lt_quantity             xxcos_dlv_lines.quantity%TYPE;                     -- ����
    lt_sale_class           xxcos_dlv_lines.sale_class%TYPE;                   -- ����敪
    lt_wholesale_price      xxcos_dlv_lines.wholesale_unit_ploce%TYPE;         -- ���P��
    lt_selling_price        xxcos_dlv_lines.selling_price%TYPE;                -- ���P��
    lt_column_no            xxcos_dlv_lines.column_no%TYPE;                    -- �R����No.
    lt_h_and_c              xxcos_dlv_lines.h_and_c%TYPE;                      -- H/C
    lt_sold_out_class       xxcos_dlv_lines.sold_out_class%TYPE;               -- ���؋敪
    lt_sold_out_time        xxcos_dlv_lines.sold_out_time%TYPE;                -- ���؎���
    lt_replenish_num        xxcos_dlv_lines.replenish_number%TYPE;             -- ��[��
    lt_cash_and_card        xxcos_dlv_lines.cash_and_card%TYPE;                -- �����E�J�[�h���p�z
--
    -- �G���[�f�[�^�ϐ�
    lt_base_name            xxcos_rep_hht_err_list.base_name%TYPE;             -- ���_����
    lt_data_name            xxcos_rep_hht_err_list.data_name%TYPE;             -- �f�[�^����
    lt_customer_name        xxcos_rep_hht_err_list.customer_name%TYPE;         -- �ڋq��
--
    lt_customer_id          hz_cust_accounts.cust_account_id%TYPE;             -- �ڋqID
    lt_party_id             hz_parties.party_id%TYPE;                          -- �p�[�e�BID
    lt_sale_base            xxcmm_cust_accounts.sale_base_code%TYPE;           -- ���㋒�_�R�[�h
    lt_past_sale_base       xxcmm_cust_accounts.past_sale_base_code%TYPE;      -- �O�����㋒�_�R�[�h
    lt_cus_status           hz_parties.duns_number_c%TYPE;                     -- �ڋq�X�e�[�^�X
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--    lt_charge_person        jtf_rs_resource_extns.source_number%TYPE;          -- �S���c�ƈ�
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
    lt_bus_low_type         xxcmm_cust_accounts.business_low_type%TYPE;        -- �Ƒԁi�����ށj
    lt_hht_class            xxcmm_cust_accounts.dept_hht_div%TYPE;             -- �S�ݓX�pHHT�敪
    lt_base_perf            per_all_assignments_f.ass_attribute5%TYPE;         -- ���_�R�[�h�i���юҁj
    lt_base_dlv             per_all_assignments_f.ass_attribute5%TYPE;         -- ���_�R�[�h�i�[�i�ҁj
    lt_in_case              ic_item_mst_b.attribute11%TYPE;                    -- �i�ڃ}�X�^�F�P�[�X����
    lt_sale_object          ic_item_mst_b.attribute26%TYPE;                    -- �i�ڃ}�X�^�F����Ώۋ敪
    lt_item_status          xxcmm_system_items_b.item_status%TYPE;             -- �i�ڃ}�X�^�F�i�ڃX�e�[�^�X
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
    lt_card_company         xxcmm_cust_accounts.card_company%TYPE;              -- �J�[�h���
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--    lt_vd_column            xxcoi_mst_vd_column.column_no%TYPE;                -- VD�R�����}�X�^�F�R����No.
--    lt_vd_hc                xxcoi_mst_vd_column.hot_cold%TYPE;                 -- VD�R�����}�X�^�FH/C
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
    lv_err_flag             VARCHAR2(1)  DEFAULT  '0';                         -- �G���[�t���O
    lv_err_flag_time        VARCHAR2(1)  DEFAULT  '0';                         -- �G���[�t���O�i���Ԍ`������j
    lv_bad_sale             VARCHAR2(1)  DEFAULT  '0';                         -- ����Ώۋ敪�F����s��
    ln_err_no               NUMBER  DEFAULT  '1';                              -- �G���[�z��i���o�[
    ln_line_cnt             NUMBER  DEFAULT  '1';                              -- ���׃`�F�b�N�ϔԍ�
    ln_temp_no              NUMBER  DEFAULT  '1';                              -- ���׈ꎞ�i�[�p�z��i���o�[
    ln_header_ok_no         NUMBER  DEFAULT  '1';                              -- ����l�z��i���o�[�i�w�b�_�j
    ln_line_ok_no           NUMBER  DEFAULT  '1';                              -- ����l�z��i���o�[�i���ׁj
    ld_process_date         DATE;                                              -- �J�����g���̗���
-- ******* 2009/10/01 N.Maeda MOD START ********* --
    lv_return_data          xxcos_rep_hht_err_list.data_name%TYPE;             -- �ԕi�f�[�^
--    lv_return_data          VARCHAR2(10);                                      -- �ԕi�f�[�^
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
-- ******************** 2009/11/25 1.18 N.Maeda DEL  START  ****************** --
--    lv_column_check         VARCHAR2(18);                                      -- �ڋqID�A�R����No.�̌��������l
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
    ln_time_char            NUMBER;                                            -- ���Ԃ̕�����`�F�b�N
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--    lv_status               VARCHAR2(5);                                       -- AR��v���ԃ`�F�b�N�F�X�e�[�^�X�̎��
--    ln_from_date            DATE;                                              -- AR��v���ԃ`�F�b�N�F��v�iFROM�j
--    ln_to_date              DATE;                                              -- AR��v���ԃ`�F�b�N�F��v�iTO�j
    lv_status               VARCHAR2(5);                                       -- INV��v���ԃ`�F�b�N�F�X�e�[�^�X�̎��
    ln_from_date            DATE;                                              -- INV��v���ԃ`�F�b�N�F��v�iFROM�j
    ln_to_date              DATE;                                              -- INV��v���ԃ`�F�b�N�F��v�iTO�j
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
    lt_resource_id          jtf_rs_resource_extns.resource_id%TYPE;            -- ���\�[�XID
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
    lv_tbl_key              VARCHAR2(20);                                      -- �Q�ƃe�[�u���̃L�[�l
    lv_time_fmt             CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami ADD START *****************************-- 
    lv_index_key            VARCHAR2(15);                                       -- �ڋq��񌟍�����KEY
--****************************** 2011/02/03 1.25 Y.Kanami ADD END *******************************--
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
    -- ���[�v�J�n�F�w�b�_��
    FOR ck_no IN 1..gn_tar_cnt_h LOOP
--
      -- �G���[�t���O������
      lv_err_flag := cv_default;
--
      -- �f�[�^�擾�F�w�b�_
      lt_order_noh_hht    := gt_headers_work_data(ck_no).order_no_hht;        -- ��No.�iHHT)
      lt_order_noh_ebs    := gt_headers_work_data(ck_no).order_no_ebs;        -- ��No.�iEBS�j
      lt_base_code        := gt_headers_work_data(ck_no).base_code;           -- ���_�R�[�h
      lt_performance_code := gt_headers_work_data(ck_no).perform_code;        -- ���ю҃R�[�h
      lt_dlv_code         := gt_headers_work_data(ck_no).dlv_by_code;         -- �[�i�҃R�[�h
      lt_hht_invoice_no   := gt_headers_work_data(ck_no).hht_invoice_no;      -- HHT�`�[No.
      lt_dlv_date         := gt_headers_work_data(ck_no).dlv_date;            -- �[�i��
      lt_inspect_date     := gt_headers_work_data(ck_no).inspect_date;        -- ������
      lt_sales_class      := gt_headers_work_data(ck_no).sales_class;         -- ���㕪�ދ敪
      lt_sales_invoice    := gt_headers_work_data(ck_no).sales_invoice;       -- ����`�[�敪
      lt_card_sale_class  := gt_headers_work_data(ck_no).card_class;          -- �J�[�h���敪
      lt_dlv_time         := gt_headers_work_data(ck_no).dlv_time;            -- ����
      lt_change_out_100   := gt_headers_work_data(ck_no).change_time_100;     -- ��K�؂ꎞ��100�~
      lt_change_out_10    := gt_headers_work_data(ck_no).change_time_10;      -- ��K�؂ꎞ��10�~
      lt_customer_number  := gt_headers_work_data(ck_no).cus_number;          -- �ڋq�R�[�h
      lt_input_class      := gt_headers_work_data(ck_no).input_class;         -- ���͋敪
      lt_tax_class        := gt_headers_work_data(ck_no).tax_class;           -- ����ŋ敪
      lt_total_amount     := gt_headers_work_data(ck_no).total_amount;        -- ���v���z
      lt_sale_discount    := gt_headers_work_data(ck_no).sale_discount;       -- ����l���z
      lt_sales_tax        := gt_headers_work_data(ck_no).sales_tax;           -- �������Ŋz
      lt_tax_include      := gt_headers_work_data(ck_no).tax_include;         -- �ō����z
      lt_keep_in_code     := gt_headers_work_data(ck_no).keep_in_code;        -- �a����R�[�h
      lt_department_class := gt_headers_work_data(ck_no).depart_screen;       -- �S�ݓX��ʎ��
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
      -- ������ --
      lt_base_name     := NULL;     -- ���_����
      lt_data_name     := NULL;     -- �f�[�^����
      lt_customer_name := NULL;     -- �ڋq��
      lt_bus_low_type  := NULL;     -- �Ƒԏ�����
  /*-----2009/02/03-----END-------------------------------------------------------------------------------*/
      --== �f�[�^���̔��� ==--
      -- �f�[�^���̎擾
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--      gv_tkn1 := xxccp_common_pkg.get_msg( cv_application, cv_msg_delivery );
--      lv_return_data := xxccp_common_pkg.get_msg( cv_application, cv_msg_return );
      gv_tkn1        := SUBSTRB(xxccp_common_pkg.get_msg( cv_application, cv_msg_delivery ),1,20);
      lv_return_data := SUBSTRB(xxccp_common_pkg.get_msg( cv_application, cv_msg_return ),1,20);
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--
      FOR i IN 1..gt_qck_inp_dlv.COUNT LOOP
        IF ( gt_qck_inp_dlv(i) = lt_input_class ) THEN
          lt_data_name := gv_tkn1;                -- �f�[�^���̃Z�b�g�F�[�i�f�[�^
          EXIT;
        END IF;
      END LOOP;
--
      FOR i IN 1..gt_qck_inp_ret.COUNT LOOP
        IF ( gt_qck_inp_ret(i) = lt_input_class ) THEN
          lt_data_name := lv_return_data;       -- �f�[�^���̃Z�b�g�F�ԕi�f�[�^
          EXIT;
        END IF;
      END LOOP;
--
      --==============================================================
      --���_�R�[�h�A�ڋq�R�[�h�̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
--
--****************************** 2009/05/15 1.14 N.Maeda DEL START ******************************--
--      BEGIN
--****************************** 2009/05/15 1.14 N.Maeda DEL  END  ******************************--
--
        --�ϐ��̏�����
        lt_customer_name   := NULL;
        lt_customer_id     := NULL;
        lt_party_id        := NULL;
        lt_sale_base       := NULL;
        lt_past_sale_base  := NULL;
        lt_cus_status      := NULL;
--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--        lt_charge_person   := NULL;
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
        lt_resource_id     := NULL;
        lt_bus_low_type    := NULL;
        lt_base_name       := NULL;
        lt_hht_class       := NULL;
        lt_base_perf       := NULL;
        lt_base_dlv        := NULL;
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
        lt_card_company    := NULL;
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
--
--****************************** 2011/02/03 1.25 Y.Kanami ADD START *****************************-- 
        -- �ڋq�}�X�^�f�[�^�`�F�b�N�pINDEX
        lv_index_key  :=  lt_customer_number||TO_CHAR(lt_dlv_date,'YYYYMM');
--****************************** 2011/02/03 1.25 Y.Kanami ADD END *******************************--
        --== �ڋq�}�X�^�f�[�^���o ==--
        -- ���Ɏ擾�ς݂̒l�ł��邩���m�F����B
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--      IF ( gt_select_cus.EXISTS(lt_customer_number) ) THEN
--        lt_customer_name  := SUBSTRB( gt_select_cus(lt_customer_number).customer_name, 1, 40 );   -- �ڋq����
--        lt_customer_id    := gt_select_cus(lt_customer_number).customer_id;     -- �ڋqID
--        lt_party_id       := gt_select_cus(lt_customer_number).party_id;        -- �p�[�e�BID
--        lt_sale_base      := gt_select_cus(lt_customer_number).sale_base;       -- ���㋒�_�R�[�h
--        lt_past_sale_base := gt_select_cus(lt_customer_number).past_sale_base;  -- �O�����㋒�_�R�[�h
--        lt_cus_status     := gt_select_cus(lt_customer_number).cus_status;      -- �ڋq�X�e�[�^�X
      IF ( gt_select_cus.EXISTS(lv_index_key) ) THEN
        lt_customer_name  := SUBSTRB( gt_select_cus(lv_index_key).customer_name, 1, 40 );   -- �ڋq����
        lt_customer_id    := gt_select_cus(lv_index_key).customer_id;     -- �ڋqID
        lt_party_id       := gt_select_cus(lv_index_key).party_id;        -- �p�[�e�BID
        lt_sale_base      := gt_select_cus(lv_index_key).sale_base;       -- ���㋒�_�R�[�h
        lt_past_sale_base := gt_select_cus(lv_index_key).past_sale_base;  -- �O�����㋒�_�R�[�h
        lt_cus_status     := gt_select_cus(lv_index_key).cus_status;      -- �ڋq�X�e�[�^�X
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--

--****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
--          lt_charge_person  := gt_select_cus(lt_customer_number).charge_person;   -- �S���c�ƈ�
--****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--        lt_resource_id    := gt_select_cus(lt_customer_number).resource_id;     -- ���\�[�XID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--        lt_bus_low_type   := gt_select_cus(lt_customer_number).bus_low_type;    -- �Ƒԁi�����ށj
--        lt_base_name      := SUBSTRB( gt_select_cus(lt_customer_number).base_name, 1, 30 );       -- ���_����
--        lt_hht_class      := gt_select_cus(lt_customer_number).dept_hht_div;    -- �S�ݓX�pHHT�敪
        lt_bus_low_type   := gt_select_cus(lv_index_key).bus_low_type;                  -- �Ƒԁi�����ށj
        lt_base_name      := SUBSTRB( gt_select_cus(lv_index_key).base_name, 1, 30 );   -- ���_����
        lt_hht_class      := gt_select_cus(lv_index_key).dept_hht_div;                  -- �S�ݓX�pHHT�敪
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--        lt_base_perf      := gt_select_cus(lt_customer_number).base_perf;       -- ���_�R�[�h�i���юҁj
--        lt_base_dlv       := gt_select_cus(lt_customer_number).base_dlv;        -- ���_�R�[�h�i�[�i�ҁj
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************--
--        lt_card_company   := gt_select_cus(lt_customer_number).card_company;    -- �J�[�h���
        lt_card_company   := gt_select_cus(lv_index_key).card_company;              -- �J�[�h���
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      ELSE
--****************************** 2009/05/15 1.14 N.Maeda MOD START ******************************--
--          SELECT SUBSTRB(parties.party_name,1,40)  party_name,                    -- �ڋq����
--                 cust.cust_account_id         cust_account_id,                    -- �ڋqID
--                 cust.party_id                party_id,                           -- �p�[�e�BID
--                 custadd.sale_base_code       sale_base_code,                     -- ���㋒�_�R�[�h
--                 custadd.past_sale_base_code  past_sale_base_code,                -- �O�����㋒�_�R�[�h
--                 parties.duns_number_c        customer_status,                    -- �ڋq�X�e�[�^�X
----****************************** 2009/04/10 1.9 N.Maeda MOD START ******************************--
----                 salesreps.employee_number    employee_number,                    -- �S���c�ƈ�
----                 salesreps.resource_id        resource_id,                        -- ���\�[�XID
--                 rivp.resource_id             resource_id,                        -- ���\�[�XID
----****************************** 2009/04/10 1.9 N.Maeda MOD END ******************************--
--                 custadd.business_low_type    business_low_type,                  -- �Ƒԁi�����ށj
--                 SUBSTRB(base.account_name,1,30)  account_name,                   -- ���_����
--                 baseadd.dept_hht_div         dept_hht_div,                       -- �S�ݓX�pHHT�敪
--                 rivp.base_code               base_code,                          -- ���_�R�[�h�i���юҁj
--                 rivd.base_code               base_code                           -- ���_�R�[�h�i�[�i�ҁj
--          INTO   lt_customer_name,
--                 lt_customer_id,
--                 lt_party_id,
--                 lt_sale_base,
--                 lt_past_sale_base,
--                 lt_cus_status,
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----                 lt_charge_person,
----****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--                 lt_resource_id,
--                 lt_bus_low_type,
--                 lt_base_name,
--                 lt_hht_class,
--                 lt_base_perf,
--                 lt_base_dlv
--          FROM   hz_cust_accounts     cust,                    -- �ڋq�}�X�^
--                 hz_cust_accounts     base,                    -- ���_�}�X�^
--                 hz_parties           parties,                 -- �p�[�e�B
--                 xxcmm_cust_accounts  custadd,                 -- �ڋq�ǉ����_�ڋq
--                 xxcmm_cust_accounts  baseadd,                 -- �ڋq�ǉ����_���_
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----                 xxcos_salesreps_v    salesreps,               -- �S���c�ƈ�view
----****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
--                 xxcos_rs_info_v      rivp,                    -- �c�ƈ����view�i���юҁj
--                 xxcos_rs_info_v      rivd,                    -- �c�ƈ����view�i�[�i�ҁj
--                 (
--                   SELECT  look_val.meaning      cus
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_typ_cus
--                   AND     look_val.attribute1   = cv_tkn_yes
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                 ) cust_class,   -- �ڋq�敪�i'10'(�ڋq) , '12'(��l)�j
--                 (
--                   SELECT  look_val.meaning      base
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_typ_cus
--                   AND     look_val.attribute2   = cv_tkn_yes
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                 ) base_class    -- �ڋq�敪�i'1'(���_)�j
--          WHERE  cust.customer_class_code = cust_class.cus       -- �ڋq�}�X�^.�ڋq�敪 = '10'(�ڋq) or '12'(��l)
--            AND  base.customer_class_code = base_class.base      -- ���_�}�X�^.�ڋq�敪 = '1'(���_)
--            AND  cust.account_number      = lt_customer_number   -- �ڋq�}�X�^.�ڋq�R�[�h=���o�����ڋq�R�[�h
--            AND  cust.party_id            = parties.party_id     -- �ڋq�}�X�^.�p�[�e�BID=�p�[�e�B.�p�[�e�BID
--            AND  cust.cust_account_id     = custadd.customer_id  -- �ڋq�}�X�^.�ڋqID=�ڋq�ǉ����.�ڋqID
----****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
--            AND  lt_base_code             = base.account_number  -- ���o�������_�R�[�h=���_�}�X�^.�ڋq�R�[�h
----            AND  custadd.sale_base_code   = base.account_number  -- �ڋq�ǉ����_�ڋq.���㋒�_=���_�}�X�^.�ڋq�R�[�h
----****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
--            AND  base.cust_account_id     = baseadd.customer_id  -- ���_�}�X�^.�ڋqID=�ڋq�ǉ����_���_.�ڋqID
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----            AND  (
----                    salesreps.account_number = lt_customer_number  -- �S���c�ƈ�view.�ڋq�ԍ� = ���o�����ڋq�R�[�h
----                  AND                                              -- �[�i���̓K�p�͈�
----                    lt_dlv_date >= NVL(salesreps.effective_start_date, gd_process_date)
----                  AND
----                    lt_dlv_date <= NVL(salesreps.effective_end_date, gd_max_date)
----                 )
----****************************** 2009/04/10 1.9 N.Maeda DEL END ******************************--
--            AND  (
--                    rivp.employee_number = lt_performance_code  -- �c�ƈ����view(���ю�).�ڋq�ԍ� = ���o�������ю�
--                  AND                                           -- �[�i���̓K�p�͈�
--                    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)
--                  AND
--                    lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
--                  AND
--                    lt_dlv_date >= rivp.per_effective_start_date
--                  AND
--                    lt_dlv_date <= rivp.per_effective_end_date
--                  AND
--                    lt_dlv_date >= rivp.paa_effective_start_date
--                  AND
--                    lt_dlv_date <= rivp.paa_effective_end_date
--                 )
--            AND  (
--                    rivd.employee_number = lt_dlv_code          -- �c�ƈ����view(�[�i��).�ڋq�ԍ� = ���o�����[�i��
--                  AND                                           -- �[�i���̓K�p�͈�
--                    lt_dlv_date >= NVL(rivd.effective_start_date, gd_process_date)
--                  AND
--                    lt_dlv_date <= NVL(rivd.effective_end_date, gd_max_date)
--                  AND
--                    lt_dlv_date >= rivd.per_effective_start_date
--                  AND
--                    lt_dlv_date <= rivd.per_effective_end_date
--                  AND
--                    lt_dlv_date >= rivd.paa_effective_start_date
--                  AND
--                    lt_dlv_date <= rivd.paa_effective_end_date
--                 );
----
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- �ڋq����
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- �ڋqID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- �p�[�e�BID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- ���㋒�_�R�[�h
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- �O�����㋒�_�R�[�h
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- �ڋq�X�e�[�^�X
----****************************** 2009/04/10 1.9 N.Maeda DEL START ******************************--
----          gt_select_cus(lt_customer_number).charge_person  := lt_charge_person;   -- �S���c�ƈ�
----****************************** 2009/04/10 1.9 N.Maeda DEL END ********************************--
----****************************** 2009/04/06 1.6 T.Kitajima ADD START ******************************--
--          gt_select_cus(lt_customer_number).resource_id    := lt_resource_id;     -- ���\�[�XID
----****************************** 2009/04/06 1.6 T.Kitajima ADD  END  ******************************--
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- �Ƒԁi�����ށj
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- ���_����
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- �S�ݓX�pHHT�敪
--          gt_select_cus(lt_customer_number).base_perf      := lt_base_perf;       -- ���_�R�[�h�i���юҁj
--          gt_select_cus(lt_customer_number).base_dlv       := lt_base_dlv;        -- ���_�R�[�h�i�[�i�ҁj
        BEGIN
          SELECT SUBSTRB(parties.party_name,1,40)  party_name,                    -- �ڋq����
                 cust.cust_account_id         cust_account_id,                    -- �ڋqID
                 cust.party_id                party_id,                           -- �p�[�e�BID
                 custadd.sale_base_code       sale_base_code,                     -- ���㋒�_�R�[�h
                 custadd.past_sale_base_code  past_sale_base_code,                -- �O�����㋒�_�R�[�h
                 parties.duns_number_c        customer_status,                    -- �ڋq�X�e�[�^�X
                 custadd.business_low_type    business_low_type,                  -- �Ƒԁi�����ށj
                 SUBSTRB(base.account_name,1,30)  account_name,                   -- ���_����
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--                 baseadd.dept_hht_div         dept_hht_div                        -- �S�ݓX�pHHT�敪
                 baseadd.dept_hht_div         dept_hht_div,                       -- �S�ݓX�pHHT�敪
                 custadd.card_company         card_company                        -- �J�[�h���
--****************************** 2010/01/18 1.21 M.Uehara MOD END   *******************************--
          INTO   lt_customer_name,
                 lt_customer_id,
                 lt_party_id,
                 lt_sale_base,
                 lt_past_sale_base,
                 lt_cus_status,
                 lt_bus_low_type,
                 lt_base_name,
--****************************** 2010/01/18 1.21 M.Uehara MOD START *******************************--
--                 lt_hht_class
                 lt_hht_class,
                 lt_card_company
--****************************** 2010/01/18 1.21 M.Uehara MOD END   *******************************--
          FROM   hz_cust_accounts     cust,                    -- �ڋq�}�X�^
                 hz_cust_accounts     base,                    -- ���_�}�X�^
                 hz_parties           parties,                 -- �p�[�e�B
                 xxcmm_cust_accounts  custadd,                 -- �ڋq�ǉ����_�ڋq
                 xxcmm_cust_accounts  baseadd,                 -- �ڋq�ǉ����_���_
                 (
                   SELECT  look_val.meaning      cus
-- ******* 2009/10/01 N.Maeda MOD START ********* --
                   FROM    fnd_lookup_values     look_val
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
                   WHERE     look_val.language = cv_user_lang
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.attribute1   = cv_tkn_yes
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                 ) cust_class,   -- �ڋq�敪�i'10'(�ڋq) , '12'(��l)�j
                 (
                   SELECT  look_val.meaning      base
-- ******* 2009/10/01 N.Maeda MOD START ********* --
                   FROM    fnd_lookup_values     look_val
--                   FROM    fnd_lookup_values     look_val,
--                           fnd_lookup_types_tl   types_tl,
--                           fnd_lookup_types      types,
--                           fnd_application_tl    appl,
--                           fnd_application       app
--                   WHERE   appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
--                   AND     types_tl.language = USERENV( 'LANG' )
--                   AND     look_val.language = USERENV( 'LANG' )
                   WHERE     look_val.language = cv_user_lang
--                   AND     appl.language     = USERENV( 'LANG' )
--                   AND     app.application_short_name = cv_application
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                   AND     look_val.lookup_type  = cv_qck_typ_cus
                   AND     look_val.attribute2   = cv_tkn_yes
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.enabled_flag = cv_tkn_yes
                 ) base_class    -- �ڋq�敪�i'1'(���_)�j
          WHERE  cust.customer_class_code = cust_class.cus       -- �ڋq�}�X�^.�ڋq�敪 = '10'(�ڋq) or '12'(��l)
            AND  base.customer_class_code = base_class.base      -- ���_�}�X�^.�ڋq�敪 = '1'(���_)
            AND  cust.account_number      = lt_customer_number   -- �ڋq�}�X�^.�ڋq�R�[�h=���o�����ڋq�R�[�h
            AND  cust.party_id            = parties.party_id     -- �ڋq�}�X�^.�p�[�e�BID=�p�[�e�B.�p�[�e�BID
            AND  cust.cust_account_id     = custadd.customer_id  -- �ڋq�}�X�^.�ڋqID=�ڋq�ǉ����.�ڋqID
            AND  lt_base_code             = base.account_number  -- ���o�������_�R�[�h=���_�}�X�^.�ڋq�R�[�h
            AND  base.cust_account_id     = baseadd.customer_id;  -- ���_�}�X�^.�ڋqID=�ڋq�ǉ����_���_.�ڋqID;
--
--        END IF;
--****************************** 2009/05/15 1.14 N.Maeda MOD  END  ******************************--
--
--
          --== �ڋq�X�e�[�^�X�`�F�b�N ==--
          FOR i IN 1..gt_qck_status.COUNT LOOP
            EXIT WHEN gt_qck_status(i) = lt_cus_status;
            IF ( i = gt_qck_status.COUNT ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_status );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== ���㋒�_�R�[�h�`�F�b�N ==--
          -- ���㋒�_�R�[�h�ƑO�����㋒�_�R�[�h�̎g�p����
          IF ( TRUNC( lt_dlv_date, cv_month ) < TRUNC( gd_process_date, cv_month ) ) THEN
            lt_sale_base := NVL( lt_past_sale_base, lt_sale_base );
          END IF;
--
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
        -- ��ʋ��_�̏ꍇ
--      IF ( lt_hht_class = cv_general ) THEN
--***************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
--        IF ( lt_hht_class IS NULL ) THEN
          IF ( lt_hht_class IS NULL ) 
            OR ( ( lt_hht_class = ct_hht_2 )
                 AND
                 (lt_department_class = ct_disp_0 )
               )
            THEN
--***************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
            -- ���㋒�_�R�[�h�Ó����`�F�b�N
            IF ( ( lt_sale_base != lt_base_code ) OR ( lt_base_code IS NULL ) ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_base );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                 -- ���_�R�[�h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);           -- �ڋq�R�[�h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);          -- ���ю҃R�[�h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_mst );
            gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                   cv_tkn_table,   gv_tkn1,
                                                   cv_tkn_colmun,  gv_tkn2 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
        END;
--
--****************************** 2011/02/03 1.25 Y.Kanami MOD START *****************************-- 
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
--        IF ( lv_err_flag <> cv_hit ) THEN
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- �ڋq����
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- �ڋqID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- �p�[�e�BID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- ���㋒�_�R�[�h
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- �O�����㋒�_�R�[�h
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- �ڋq�X�e�[�^�X
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- �Ƒԁi�����ށj
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- ���_����
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- �S�ݓX�pHHT�敪
----****************************** 2010/01/27 1.22 N.Maeda ADD START *******************************--
--          gt_select_cus(lt_customer_number).card_company   := lt_card_company;    -- �J�[�h���
----****************************** 2010/01/27 1.22 N.Maeda ADD START *******************************--
        IF ( lv_err_flag <> cv_hit ) THEN
          gt_select_cus(lv_index_key).customer_name  := lt_customer_name;   -- �ڋq����
          gt_select_cus(lv_index_key).customer_id    := lt_customer_id;     -- �ڋqID
          gt_select_cus(lv_index_key).party_id       := lt_party_id;        -- �p�[�e�BID
          gt_select_cus(lv_index_key).sale_base      := lt_sale_base;       -- ���㋒�_�R�[�h
          gt_select_cus(lv_index_key).past_sale_base := lt_past_sale_base;  -- �O�����㋒�_�R�[�h
          gt_select_cus(lv_index_key).cus_status     := lt_cus_status;      -- �ڋq�X�e�[�^�X
          gt_select_cus(lv_index_key).bus_low_type   := lt_bus_low_type;    -- �Ƒԁi�����ށj
          gt_select_cus(lv_index_key).base_name      := lt_base_name;       -- ���_����
          gt_select_cus(lv_index_key).dept_hht_div   := lt_hht_class;       -- �S�ݓX�pHHT�敪
          gt_select_cus(lv_index_key).card_company   := lt_card_company;    -- �J�[�h���
--****************************** 2011/02/03 1.25 Y.Kanami MOD END *******************************--
        END IF;
--
      END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--****************************** 2009/04/14 1.10 T.Kitajima MOD START ******************************--
--      --==============================================================
--      --���ю҃R�[�h�̑Ó����`�F�b�N�i�w�b�_���j
--      --==============================================================
--      IF ( lt_base_perf != lt_sale_base ) THEN
--        -- ���O�o��
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_disagree );
--        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--        ov_retcode := cv_status_warn;
--        -- �G���[�ϐ��֊i�[
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
--        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
--        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
--        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
--        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
--        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
--        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
--        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
--        ln_err_no := ln_err_no + 1;
--        -- �G���[�t���O�X�V
--        lv_err_flag := cv_hit;
--      END IF;
--      --==============================================================
--      --�[�i�҃R�[�h�̑Ó����`�F�b�N�i�w�b�_���j
--      --==============================================================
--      IF ( lt_base_dlv != lt_sale_base ) THEN
--        -- ���O�o��
--        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_belong );
--        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--        ov_retcode := cv_status_warn;
--        -- �G���[�ϐ��֊i�[
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
--        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
--        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
--        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
--        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
--        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
--        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
--        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
--        ln_err_no := ln_err_no + 1;
--        -- �G���[�t���O�X�V
--        lv_err_flag := cv_hit;
--      END IF;
--
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
      BEGIN
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
        -- ���ю҃R�[�h���o���ڃe�[�u���̃L�[�l���擾(���ю҃R�[�h,�[�i��)
        lv_tbl_key   := lt_performance_code || TO_CHAR(lt_dlv_date, lv_time_type);
        -- ���_�R�[�h�i���юҁj���擾
        lt_base_perf := NULL;
        IF ( gt_select_perf.EXISTS(lv_tbl_key) ) THEN
          lt_base_perf := gt_select_perf(lv_tbl_key).base_perf;  -- �[�i�R�[�h�i���юҁj
        ELSE
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
          SELECT rivp.base_code       base_code              -- ���_�R�[�h�i���юҁj
          INTO   lt_base_perf
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivp                   -- �c�ƈ����view�i���юҁj
          FROM   xxcos_rs_info2_v     rivp                   -- �c�ƈ����view�i���юҁj
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
          WHERE  rivp.employee_number = lt_performance_code  -- �c�ƈ����view(���ю�).�ڋq�ԍ� = ���o�������ю�
          AND    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)-- �[�i���̓K�p�͈�
          AND   lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
          AND   lt_dlv_date >= rivp.per_effective_start_date
          AND   lt_dlv_date <= rivp.per_effective_end_date
          AND   lt_dlv_date >= rivp.paa_effective_start_date
          AND   lt_dlv_date <= rivp.paa_effective_end_date;
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- �z��Ɋi�[
          gt_select_perf(lv_tbl_key).base_perf := lt_base_perf;  -- �[�i�R�[�h�i���юҁj
        END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--
        --��ʋ��_�̏ꍇ�̓`�F�b�N����B
        IF ( lt_hht_class IS NULL ) 
          OR ( ( lt_hht_class = ct_hht_2 )
            AND (lt_department_class = ct_disp_0 )
        )
        THEN
          --==============================================================
          --���ю҃R�[�h�̑Ó����`�F�b�N�i�w�b�_���j
          --==============================================================
          IF ( lt_base_perf != lt_sale_base ) THEN
            -- ���O�o��
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_disagree );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- ���O�o��
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_emp_mst );
        gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_paf_emp );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                             cv_tkn_table,   gv_tkn1,
                                             cv_tkn_colmun,  gv_tkn2 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END;
--
      BEGIN
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
        -- ���ю҃R�[�h���o���ڃe�[�u���̃L�[�l���擾(���ю҃R�[�h,�[�i��)
        lv_tbl_key   := lt_dlv_code || TO_CHAR(lt_dlv_date, lv_time_type);
        -- ���_�R�[�h�i�[�i�ҁj�A���\�[�XID���擾
        lt_resource_id := NULL;
        lt_base_dlv    := NULL;
        IF ( gt_select_dlv.EXISTS(lv_tbl_key) ) THEN
          lt_resource_id := gt_select_dlv(lv_tbl_key).resource_id;  -- ���\�[�XID
          lt_base_dlv    := gt_select_dlv(lv_tbl_key).base_dlv;     -- ���_�R�[�h�i�[�i�ҁj
        ELSE
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
          SELECT rivd.base_code       base_code                           -- ���_�R�[�h�i�[�i�ҁj
          INTO   lt_base_dlv
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivd                    -- �c�ƈ����view�i�[�i�ҁj
          FROM   xxcos_rs_info2_v     rivd                   -- �c�ƈ����view�i�[�i�ҁj
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
          WHERE  rivd.employee_number = lt_dlv_code          -- �c�ƈ����view(�[�i��).�ڋq�ԍ� = ���o�����[�i��
          AND    lt_dlv_date >= NVL(rivd.effective_start_date, gd_process_date)-- �[�i���̓K�p�͈�
          AND    lt_dlv_date <= NVL(rivd.effective_end_date, gd_max_date)
          AND    lt_dlv_date >= rivd.per_effective_start_date
          AND    lt_dlv_date <= rivd.per_effective_end_date
          AND    lt_dlv_date >= rivd.paa_effective_start_date
          AND    lt_dlv_date <= rivd.paa_effective_end_date;
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- SQL�ɂĎ擾�����ꍇ�A���ʂ�z��Ɋi�[
          gt_select_dlv(lv_tbl_key).resource_id := lt_resource_id; -- ���\�[�XID
          gt_select_dlv(lv_tbl_key).base_dlv    := lt_base_dlv;    -- ���_�R�[�h�i�[�i�ҁj
        END IF;
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
--
        --��ʋ��_�̏ꍇ�̓`�F�b�N����B
        IF ( lt_hht_class IS NULL ) 
        OR ( ( lt_hht_class = ct_hht_2 )
          AND (lt_department_class = ct_disp_0 ) ) THEN
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--
          --==============================================================
          --�[�i�҃R�[�h�̑Ó����`�F�b�N�i�w�b�_���j
          --==============================================================
          IF ( lt_base_dlv != lt_sale_base ) THEN
            -- ���O�o��
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_belong );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
        END IF;
--****************************** 2009/04/14 1.10 T.Kitajima MOD  END  ******************************--
--****************************** 2009/05/15 1.14 N.Maeda ADD START ******************************--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_emp_mst );
          gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_emp );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                 cv_tkn_table,   gv_tkn1,
                                                 cv_tkn_colmun,  gv_tkn2 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
      END;
--
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
      -- �[�i�҃R�[�h�Ó����`�F�b�N�p�z�������
      IF (lt_resource_id IS NULL ) THEN
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
        BEGIN
          SELECT rivp.resource_id     resource_id            -- ���\�[�XID
          INTO   lt_resource_id
-- ******* 2009/10/30 M.Sano  MOD START ********* --
--          FROM   xxcos_rs_info_v      rivp                   -- �c�ƈ����view�i�[�i�ҁj
          FROM   xxcos_rs_info2_v      rivp                  -- �c�ƈ����view�i�[�i�ҁj
-- ******* 2009/10/30 M.Sano  MOD  END  ********* --
-- ************* 2009/09/01 N.Maeda 1.15 MOD START ************** --
          WHERE  rivp.employee_number = lt_dlv_code
--          WHERE  rivp.employee_number = lt_performance_code  -- �c�ƈ����view(���ю�).�ڋq�ԍ� = ���o�������ю�
-- ************* 2009/09/01 N.Maeda 1.15 MOD START ************** --
          AND    lt_dlv_date >= NVL(rivp.effective_start_date, gd_process_date)-- �[�i���̓K�p�͈�
          AND   lt_dlv_date <= NVL(rivp.effective_end_date, gd_max_date)
          AND   lt_dlv_date >= rivp.per_effective_start_date
          AND   lt_dlv_date <= rivp.per_effective_end_date
          AND   lt_dlv_date >= rivp.paa_effective_start_date
          AND   lt_dlv_date <= rivp.paa_effective_end_date;
--****************************** 2009/12/01 1.19 M.Sano ADD START *******************************--
          -- �擾���ʂ�z��Ɋi�[
          gt_select_dlv(lt_dlv_code).resource_id := lt_resource_id; -- ���\�[�XID
--****************************** 2009/12/01 1.19 M.Sano ADD END   *******************************--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_err_msg_get_resource_id );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
        END;
--
--****************************** 2009/12/01 1.19 M.Sano DEL START *******************************--
--        IF ( lv_err_flag <> cv_hit ) THEN
--          gt_select_cus(lt_customer_number).customer_name  := lt_customer_name;   -- �ڋq����
--          gt_select_cus(lt_customer_number).customer_id    := lt_customer_id;     -- �ڋqID
--          gt_select_cus(lt_customer_number).party_id       := lt_party_id;        -- �p�[�e�BID
--          gt_select_cus(lt_customer_number).sale_base      := lt_sale_base;       -- ���㋒�_�R�[�h
--          gt_select_cus(lt_customer_number).past_sale_base := lt_past_sale_base;  -- �O�����㋒�_�R�[�h
--          gt_select_cus(lt_customer_number).cus_status     := lt_cus_status;      -- �ڋq�X�e�[�^�X
--          gt_select_cus(lt_customer_number).resource_id    := lt_resource_id;     -- ���\�[�XID
--          gt_select_cus(lt_customer_number).bus_low_type   := lt_bus_low_type;    -- �Ƒԁi�����ށj
--          gt_select_cus(lt_customer_number).base_name      := lt_base_name;       -- ���_����
--          gt_select_cus(lt_customer_number).dept_hht_div   := lt_hht_class;       -- �S�ݓX�pHHT�敪
--          gt_select_cus(lt_customer_number).base_perf      := lt_base_perf;       -- ���_�R�[�h�i���юҁj
--          gt_select_cus(lt_customer_number).base_dlv       := lt_base_dlv;        -- ���_�R�[�h�i�[�i�ҁj
--        END IF;
--****************************** 2009/12/01 1.19 M.Sano DEL END   *******************************--
--
      END IF;
--
--****************************** 2009/05/15 1.14 N.Maeda ADD  END  ******************************--
--
      --==============================================================
      --�J�[�h���敪�̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
      FOR i IN 1..gt_qck_card.COUNT LOOP
        EXIT WHEN gt_qck_card(i) = lt_card_sale_class;
        IF ( i = gt_qck_card.COUNT ) THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_card );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
        END IF;
      END LOOP;
--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
      --==============================================================
      --�J�[�h��Ѓ`�F�b�N�i�w�b�_���j
      --==============================================================
      IF ( lt_card_sale_class = cv_card AND lt_card_company IS NULL ) THEN
        -- ���O�o��
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_card_company );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END IF;
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
      --==============================================================
      --���͋敪�̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
      IF ( lt_data_name IS NULL ) THEN
        -- ���O�o��
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END IF;
--
      --== ���͋敪�E�Ƒԏ����ސ������`�F�b�N ==--
      FOR i IN 1..gt_qck_inp_auto.COUNT LOOP
        IF ( gt_qck_inp_auto(i) = lt_input_class ) THEN
          FOR j IN 1..gt_qck_busi.COUNT LOOP
            EXIT WHEN gt_qck_busi(j) = lt_bus_low_type;
            IF ( j = gt_qck_busi.COUNT ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_class );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
              gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
        END IF;
      END LOOP;
--
      --==============================================================
      --����ŋ敪�̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
--
      FOR i IN 1..gt_qck_tax.COUNT LOOP
        IF ( gt_qck_tax(i).tax_cl = lt_tax_class ) THEN
          EXIT;
        END IF;
        IF ( i = gt_qck_tax.COUNT ) THEN
          -- ���O�o��
          gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax );
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
        END IF;
      END LOOP;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL START  *****************************--
--  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
--      --== �S�ݓX�̏ꍇ�A�a����R�[�h�̃Z�b�g�E�S�ݓX��ʎ�ʂ̑Ó����`�F�b�N���s���܂��B ==--
----    IF ( lt_hht_class = cv_depart ) THEN
----****************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
----      IF ( lt_hht_class IS NOT NULL ) THEN
--      IF ( lt_hht_class IS NULL ) 
--        OR ( ( lt_hht_class = ct_hht_2 )
--             AND
--             (lt_department_class = ct_disp_0 )
--           )
--        THEN
----****************************** 2009/04/10 1.8 T.Kitajima MOD START  *****************************--
--  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
----
----****************************** 2009/04/03 1.5 T.Kitajima DEL START ******************************--
----        --==============================================================
----        -- �a����R�[�h�Ɍڋq�R�[�h���Z�b�g�i�w�b�_���j
----        --==============================================================
----        lt_keep_in_code := lt_customer_number;
----****************************** 2009/04/03 1.5 T.Kitajima DEL START ******************************--
--
--       --==============================================================
--        -- �S�ݓX��ʎ�ʂ̑Ó����`�F�b�N�i�w�b�_���j
--        --==============================================================
--        FOR i IN 1..gt_qck_depart.COUNT LOOP
--          EXIT WHEN gt_qck_depart(i) = lt_department_class;
--          IF ( i = gt_qck_depart.COUNT ) THEN
--            -- ���O�o��
--            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_depart );
--            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
--            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--            ov_retcode := cv_status_warn;
--            -- �G���[�ϐ��֊i�[
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
--            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
--            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
--            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--            gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
--            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
--            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
--            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--            gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
--            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
--            ln_err_no := ln_err_no + 1;
--            -- �G���[�t���O�X�V
--            lv_err_flag := cv_hit;
--          END IF;
--        END LOOP;
--
--      END IF;
--
--****************************** 2009/04/20 1.11 T.Kitajima DEL  END   *****************************--
      --==============================================================
      --�[�i���̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--      --== AR��v���ԃ`�F�b�N ==--
      --== INV��v���ԃ`�F�b�N ==--
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
      -- ���ʊ֐�����v���ԏ��擾��
      xxcos_common_pkg.get_account_period(
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--        cv_ar_class         -- 02:AR
        cv_inv_class        -- 01:INV
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
       ,lt_dlv_date         -- �[�i��
       ,lv_status           -- �X�e�[�^�X(OPEN or CLOSE)
       ,ln_from_date        -- ��v�iFROM�j
       ,ln_to_date          -- ��v�iTO�j
       ,lv_errbuf           -- �G���[�E���b�Z�[�W
       ,lv_retcode          -- ���^�[���E�R�[�h
       ,lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
        );
--****************************** 2009/12/10 1.20 M.Sano MOD START *******************************--
----
--      --�G���[�`�F�b�N
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      END IF;
--
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD START ****************************--
--      -- AR��v���Ԕ͈͊O�̏ꍇ
      -- INV��v���Ԕ͈͊O�̏ꍇ
--***************************** 2010/02/04 1.24 Y.Kuboshima MOD END ******************************--
--      IF ( lv_status != cv_open ) THEN
      IF ( lv_status != cv_open OR lv_retcode = cv_status_error ) THEN
--****************************** 2009/12/10 1.20 M.Sano MOD  END  *******************************--
        -- ���O�o��
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_period );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END IF;
--
      --== �[�i�E�������t�������`�F�b�N ==--
      IF ( lt_dlv_date > lt_inspect_date ) THEN
        -- ���O�o��
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_adjust );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END IF;
--
      --== �������`�F�b�N ==--
      IF ( lt_dlv_date > gd_process_date ) THEN
        -- ���O�o��
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_future );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END IF;
--
      --==============================================================
      --�������̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
      ld_process_date := LAST_DAY( ADD_MONTHS( gd_process_date, 1 ) );
      IF ( lt_inspect_date > ld_process_date ) THEN
        -- ���O�o��
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_scope );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
        -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--        gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
        gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
        gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
        gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--        gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
        gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
        gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--        gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
        gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
        gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--        gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
        gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
        gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
        gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
        gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
        gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
        gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
        ln_err_no := ln_err_no + 1;
        -- �G���[�t���O�X�V
        lv_err_flag := cv_hit;
      END IF;
--
      --==============================================================
      --���Ԃ̑Ó����`�F�b�N�i�w�b�_���j
      --==============================================================
      BEGIN
        -- �G���[�t���O�i���Ԍ`������j������
        lv_err_flag_time := cv_default;
--
        -- �����񂪊܂܂�Ă��邩
        ln_time_char := TO_NUMBER( lt_dlv_time );
--
        IF ( LENGTHB( lt_dlv_time ) = 4 ) THEN
          IF ( ( substr( lt_dlv_time, 1, 2 ) < 0 ) or ( 24 < substr( lt_dlv_time, 1, 2 ) ) ) THEN
            -- �G���[�t���O�i���Ԍ`������j�X�V
            lv_err_flag_time := cv_hit;
          END IF;
--
          IF ( ( substr( lt_dlv_time, 3 ) < 0 ) or ( 59 < substr( lt_dlv_time, 3 ) ) ) THEN
            -- �G���[�t���O�i���Ԍ`������j�X�V
            lv_err_flag_time := cv_hit;
          END IF;
--
          IF ( lv_err_flag_time = cv_hit ) THEN
            -- ���O�o��
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
            gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--
        ELSE
          -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_time );
          FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
          ov_retcode := cv_status_warn;
          -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--          gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
          gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
          gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
          gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--          gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
          gt_err_line_no(ln_err_no)          := NULL;                         -- �sNO
          gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--          gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
          gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
          gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--          gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
          gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
          gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
          gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
          gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
          gt_err_item_code(ln_err_no)        := NULL;                         -- �i�ڃR�[�h
          gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
          ln_err_no := ln_err_no + 1;
          -- �G���[�t���O�X�V
          lv_err_flag := cv_hit;
      END;
--
      -- ���[�v�J�n�F���ו�
      FOR line_no IN ln_line_cnt..in_line_cnt LOOP
--
        -- �f�[�^�擾�F����
        lt_order_nol_hht   := gt_lines_work_data(line_no).order_no_hht;          -- ��No.�iHHT�j
        lt_line_no_hht     := gt_lines_work_data(line_no).line_no_hht;           -- �sNo.�iHHT�j
        lt_order_nol_ebs   := gt_lines_work_data(line_no).order_no_ebs;          -- ��No.�iEBS�j
        lt_line_number     := gt_lines_work_data(line_no).line_num_ebs;          -- ���הԍ�(EBS)
        lt_item_code       := gt_lines_work_data(line_no).item_code_self;        -- �i���R�[�h�i���Ёj
        lt_case_number     := gt_lines_work_data(line_no).case_number;           -- �P�[�X��
        lt_quantity        := gt_lines_work_data(line_no).quantity;              -- ����
        lt_sale_class      := gt_lines_work_data(line_no).sale_class;            -- ����敪
        lt_wholesale_price := gt_lines_work_data(line_no).wholesale_unit;        -- ���P��
        lt_selling_price   := gt_lines_work_data(line_no).selling_price;         -- ���P��
        lt_column_no       := gt_lines_work_data(line_no).column_no;             -- �R����No.
        lt_h_and_c         := gt_lines_work_data(line_no).h_and_c;               -- H/C
        lt_sold_out_class  := gt_lines_work_data(line_no).sold_out_class;        -- ���؋敪
        lt_sold_out_time   := gt_lines_work_data(line_no).sold_out_time;         -- ���؎���
        lt_cash_and_card   := gt_lines_work_data(line_no).cash_and_card;         -- �����E�J�[�h���p�z
--
        -- ���ו����[�v�𔲂������
        EXIT WHEN lt_order_noh_hht != lt_order_nol_hht;
--
        --==============================================================
        --�i�ڃR�[�h�̑Ó����`�F�b�N�i���ו��j
        --==============================================================
        BEGIN
          --== �i�ڃ}�X�^�f�[�^���o ==--
          -- ���Ɏ擾�ς݂̕i�ڃR�[�h�ł��邩���m�F����B
          IF ( gt_select_item.EXISTS(lt_item_code) ) THEN
            lt_item_id       := gt_select_item(lt_item_code).item_id;          -- �i��ID
            lt_standard_unit := gt_select_item(lt_item_code).primary_measure;  -- ��P��
            lt_in_case       := gt_select_item(lt_item_code).in_case;          -- �P�[�X����
            lt_sale_object   := gt_select_item(lt_item_code).sale_object;      -- ����Ώۋ敪
            lt_item_status   := gt_select_item(lt_item_code).item_status;      -- �i�ڃX�e�[�^�X
          ELSE
  /*-----2009/02/03-----START-------------------------------------------------------------------------------*/
--          SELECT ic_item.item_id                   inventory_item_id,        -- �i��ID
            SELECT mtl_item.inventory_item_id        inventory_item_id,        -- �i��ID
  /*-----2009/02/03-----END---------------------------------------------------------------------------------*/
                   mtl_item.primary_unit_of_measure  primary_measure,          -- ��P��
                   ic_item.attribute11               attribute11,              -- �P�[�X����
                   ic_item.attribute26               attribute26,              -- ����Ώۋ敪
                   cmm_item.item_status              item_status               -- �i�ڃX�e�[�^�X
            INTO   lt_item_id,
                   lt_standard_unit,
                   lt_in_case,
                   lt_sale_object,
                   lt_item_status
            FROM   mtl_system_items_b    mtl_item,
                   ic_item_mst_b         ic_item,
                   xxcmm_system_items_b  cmm_item
            WHERE  mtl_item.segment1        = lt_item_code
              AND  mtl_item.organization_id = gn_orga_id
              AND  mtl_item.segment1        = ic_item.item_no
              AND  mtl_item.segment1        = cmm_item.item_code
              AND  ic_item.item_id          = cmm_item.item_id;
--
            gt_select_item(lt_item_code).item_id         := lt_item_id;         -- �i��ID
            gt_select_item(lt_item_code).primary_measure := lt_standard_unit;   -- ��P��
            gt_select_item(lt_item_code).in_case         := lt_in_case;         -- �P�[�X����
            gt_select_item(lt_item_code).sale_object     := lt_sale_object;     -- ����Ώۋ敪
            gt_select_item(lt_item_code).item_status     := lt_item_status;     -- �i�ڃX�e�[�^�X
--
          END IF;
--
          --== ����Ώۋ敪�`�F�b�N ==--
          IF ( lt_sale_object = lv_bad_sale ) THEN
            -- ���O�o��
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_object );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--
          --== �i�ڃX�e�[�^�X�`�F�b�N ==--
          FOR i IN 1..gt_qck_item.COUNT LOOP
            EXIT WHEN gt_qck_item(i) = lt_item_status;
            IF ( i = gt_qck_item.COUNT ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_item );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--              gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--              gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
              gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
              gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
          END LOOP;
--
          --== ��[���Z�o ==--
          lt_content       := lt_in_case;
          lt_case_number   := NVL( lt_case_number, 0 );
          lt_replenish_num := lt_in_case * lt_case_number + lt_quantity;
          IF ( lt_replenish_num = 0 ) THEN
            -- ���O�o��
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_convert );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_mst );
            gv_tkn2   := xxccp_common_pkg.get_msg( cv_application, cv_msg_item_code );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_mst,
                                                   cv_tkn_table,   gv_tkn1,
                                                   cv_tkn_colmun,  gv_tkn2 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
        END;
--
        --==============================================================
        --����敪�̑Ó����`�F�b�N�i���ו��j
        --==============================================================
        FOR i IN 1..gt_qck_sale.COUNT LOOP
          EXIT WHEN gt_qck_sale(i) = lt_sale_class;
          IF ( i = gt_qck_sale.COUNT ) THEN
            -- ���O�o��
            gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_sale );
            lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--            gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--            gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--            gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--            gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--            gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--            gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
        END LOOP;
--
--****************************** 2010/01/18 1.21 M.Uehara ADD START *******************************--
        --==============================================================
        --�J�[�h��Ѓ`�F�b�N�i���ו��j
        --==============================================================
          IF ( lt_card_sale_class <> cv_card AND (NVL(lt_cash_and_card ,0) <> 0)
                                             AND lt_card_company IS NULL ) THEN
            -- ���O�o��
          lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_card_company );
            FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
            ov_retcode := cv_status_warn;
            -- �G���[�ϐ��֊i�[
            gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
            gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
            gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
            gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
            gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
            gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
            gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
            gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
            gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
            gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
            gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
            gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
            gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
            ln_err_no := ln_err_no + 1;
            -- �G���[�t���O�X�V
            lv_err_flag := cv_hit;
          END IF;
--****************************** 2010/01/18 1.21 M.Uehara ADD END   *******************************--
        --==============================================================
        --�R����No.��H/C�̑Ó����`�F�b�N�i���ו��j
        --==============================================================
        FOR j IN 1..gt_qck_busi.COUNT LOOP
          IF ( gt_qck_busi(j) = lt_bus_low_type ) THEN
            --== �R����No.��H/C�̐ݒ�l�`�F�b�N ==--
            IF ( ( lt_column_no IS NULL ) OR ( lt_h_and_c IS NULL ) ) THEN
              -- ���O�o��
              lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_vd );
              FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
              ov_retcode := cv_status_warn;
              -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--              gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
              gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
              gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
              gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--              gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--              gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
              gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--              gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
              gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
              gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--              gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--              gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
              gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
              gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
              gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
              gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
              gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
              gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
              gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
              ln_err_no := ln_err_no + 1;
              -- �G���[�t���O�X�V
              lv_err_flag := cv_hit;
            END IF;
--
            --== H/C�̍��ڃ`�F�b�N ==--
            FOR i IN 1..gt_qck_hc.COUNT LOOP
              EXIT WHEN gt_qck_hc(i) = lt_h_and_c;
              IF ( i = gt_qck_hc.COUNT ) THEN
                -- ���O�o��
                gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_h_c );
                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_use, cv_tkn_colmun, gv_tkn1 );
                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
                ov_retcode := cv_status_warn;
                -- �G���[�ϐ��֊i�[
-- ******* 2009/10/01 N.Maeda MOD START ********* --
--                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
--                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
--                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
--                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
--                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
--                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
-- ******* 2009/10/01 N.Maeda MOD  END  ********* --
                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
                ln_err_no := ln_err_no + 1;
                -- �G���[�t���O�X�V
                lv_err_flag := cv_hit;
              END IF;
            END LOOP;
--
-- ******************** 2009/11/25 1.18 N.Maeda DEL START ******************** --
--            --== VD�R�����}�X�^�Ƃ̐������`�F�b�N ==--
--            BEGIN
--              lv_column_check := TO_CHAR( lt_customer_id ) || '_' || lt_column_no;
--              -- ���Ɏ擾�ς݂̒l�ł��邩���m�F����B
--              IF ( gt_select_vd.EXISTS(lv_column_check) ) THEN
--                lt_vd_column := gt_select_vd(lv_column_check).column_no;  -- �R����No.
--                lt_vd_hc     := gt_select_vd(lv_column_check).hot_cold;   -- H/C
--              ELSE
--                SELECT vd.column_no  column_no,      -- �R����No.
--                       vd.hot_cold   hot_cold        -- H/C
--                INTO   lt_vd_column,
--                       lt_vd_hc
--                FROM   xxcoi_mst_vd_column vd
--                WHERE  vd.customer_id = lt_customer_id
--                  AND  vd.column_no   = lt_column_no;
----
--                gt_select_vd(lv_column_check).column_no := lt_vd_column;  -- �R����No.
--                gt_select_vd(lv_column_check).hot_cold  := lt_vd_hc;      -- H/C
----
---- *********** 2009/09/01 N.Maeda 1.15 ADD START ************* --
--              END IF;
---- *********** 2009/09/01 N.Maeda 1.15 ADD  END  ************* --
----
--              -- H/C�̐������`�F�b�N
--              IF ( lt_h_and_c != lt_vd_hc ) THEN
--                -- ���O�o��
--                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_hc );
--                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--                ov_retcode := cv_status_warn;
--                -- �G���[�ϐ��֊i�[
---- ******* 2009/10/01 N.Maeda MOD START ********* --
----                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
--                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
--                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
--                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
----                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
----                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
--                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
----                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
--                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
--                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
----                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
----                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
--                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
--                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
---- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
--                ln_err_no := ln_err_no + 1;
--                -- �G���[�t���O�X�V
--                lv_err_flag := cv_hit;
--              END IF;
----
---- *********** 2009/09/01 N.Maeda 1.15 DEL START ************* --
----              END IF;
---- *********** 2009/09/01 N.Maeda 1.15 DEL  END  ************* --
----
--            EXCEPTION
--              WHEN NO_DATA_FOUND THEN
--                -- ���O�o��
--                lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_colm );
--                FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
--                ov_retcode := cv_status_warn;
--                -- �G���[�ϐ��֊i�[
---- ******* 2009/10/01 N.Maeda MOD START ********* --
----                gt_err_base_code(ln_err_no)        := lt_base_code;                 -- ���_�R�[�h
--                gt_err_base_name(ln_err_no)        := lt_base_name;                 -- ���_����
--                gt_err_data_name(ln_err_no)        := lt_data_name;                 -- �f�[�^����
--                gt_err_order_no_hht(ln_err_no)     := lt_order_noh_hht;             -- ��NO(HHT)
----                gt_err_entry_number(ln_err_no)     := lt_hht_invoice_no;            -- �`�[NO
----                gt_err_line_no(ln_err_no)          := lt_line_no_hht;               -- �sNO
--                gt_err_order_no_ebs(ln_err_no)     := lt_order_noh_ebs;             -- ��NO(EBS)
----                gt_err_party_num(ln_err_no)        := lt_customer_number;           -- �ڋq�R�[�h
--                gt_err_customer_name(ln_err_no)    := lt_customer_name;             -- �ڋq��
--                gt_err_payment_dlv_date(ln_err_no) := lt_dlv_date;                  -- ����/�[�i��
----                gt_err_perform_by_code(ln_err_no)  := lt_performance_code;          -- ���ю҃R�[�h
----                gt_err_item_code(ln_err_no)        := lt_item_code;                 -- �i�ڃR�[�h
--                gt_err_base_code(ln_err_no)        := SUBSTRB(lt_base_code,1,4);                  -- ���_�R�[�h
--                gt_err_entry_number(ln_err_no)     := SUBSTRB(lt_hht_invoice_no,1,12);            -- �`�[NO
--                gt_err_line_no(ln_err_no)          := SUBSTRB(lt_line_no_hht,1,2);                -- �sNO
--                gt_err_party_num(ln_err_no)        := SUBSTRB(lt_customer_number,1,9);            -- �ڋq�R�[�h
--                gt_err_perform_by_code(ln_err_no)  := SUBSTRB(lt_performance_code,1,5);           -- ���ю҃R�[�h
--                gt_err_item_code(ln_err_no)        := SUBSTRB(lt_item_code,1,7);                  -- �i�ڃR�[�h
---- ******* 2009/10/01 N.Maeda MOD  END  ********* --
--                gt_err_error_message(ln_err_no)    := SUBSTRB( lv_errmsg, 1, 60 );  -- �G���[���e
--                ln_err_no := ln_err_no + 1;
--                -- �G���[�t���O�X�V
--                lv_err_flag := cv_hit;
--            END;
-- ******************** 2009/11/25 1.18 N.Maeda DEL  END  ******************** --
--
          END IF;
        END LOOP;
--
        --==============================================================
        --�[�i�f�[�^�i���ׁj���ꎞ�i�[�p�ϐ���
        --==============================================================
        lt_line_temp(ln_temp_no).order_nol_hht   := lt_order_nol_hht;        -- ��No.�iHHT�j
        lt_line_temp(ln_temp_no).line_no_hht     := lt_line_no_hht;          -- �sNo.�iHHT�j
        lt_line_temp(ln_temp_no).order_nol_ebs   := lt_order_nol_ebs;        -- ��No.�iEBS�j
        lt_line_temp(ln_temp_no).line_number     := lt_line_number;          -- ���הԍ�(EBS)
        lt_line_temp(ln_temp_no).item_code       := lt_item_code;            -- �i���R�[�h�i���Ёj
        lt_line_temp(ln_temp_no).content         := lt_content;              -- ����
        lt_line_temp(ln_temp_no).item_id         := lt_item_id;              -- �i��ID
        lt_line_temp(ln_temp_no).standard_unit   := lt_standard_unit;        -- ��P��
        lt_line_temp(ln_temp_no).case_number     := lt_case_number;          -- �P�[�X��
        lt_line_temp(ln_temp_no).quantity        := lt_quantity;             -- ����
        lt_line_temp(ln_temp_no).sale_class      := lt_sale_class;           -- ����敪
        lt_line_temp(ln_temp_no).wholesale_price := lt_wholesale_price;      -- ���P��
        lt_line_temp(ln_temp_no).selling_price   := lt_selling_price;        -- ���P��
        lt_line_temp(ln_temp_no).column_no       := lt_column_no;            -- �R����No.
        lt_line_temp(ln_temp_no).h_and_c         := lt_h_and_c;              -- H/C
        lt_line_temp(ln_temp_no).sold_out_class  := lt_sold_out_class;       -- ���؋敪
        lt_line_temp(ln_temp_no).sold_out_time   := lt_sold_out_time;        -- ���؎���
        lt_line_temp(ln_temp_no).replenish_num   := lt_replenish_num;        -- ��[��
        lt_line_temp(ln_temp_no).cash_and_card   := lt_cash_and_card;        -- �����E�J�[�h���p�z
        ln_temp_no := ln_temp_no +1;
--
        -- ���׃`�F�b�N�ϔԍ��X�V
        ln_line_cnt := ln_line_cnt + 1;
--
      END LOOP;
--
      -- ����l�ϐ��փf�[�^���i�[
      IF ( lv_err_flag = cv_default ) THEN
        --==============================================================
        --�[�i�f�[�^�i�w�b�_�j��ϐ��֊i�[
        --==============================================================
        gt_head_order_no_hht(ln_header_ok_no)    := lt_order_noh_hht;        -- ��No.�iHHT�j
        gt_head_order_no_ebs(ln_header_ok_no)    := lt_order_noh_ebs;        -- ��No.�iEBS�j
        gt_head_base_code(ln_header_ok_no)       := lt_sale_base;            -- ���_�R�[�h
        gt_head_perform_code(ln_header_ok_no)    := lt_performance_code;     -- ���ю҃R�[�h
        gt_head_dlv_by_code(ln_header_ok_no)     := lt_dlv_code;             -- �[�i�҃R�[�h
        gt_head_hht_invoice_no(ln_header_ok_no)  := lt_hht_invoice_no;       -- HHT�`�[No.
        gt_head_dlv_date(ln_header_ok_no)        := lt_dlv_date;             -- �[�i��
        gt_head_inspect_date(ln_header_ok_no)    := lt_inspect_date;         -- ������
        gt_head_sales_class(ln_header_ok_no)     := lt_sales_class;          -- ���㕪�ދ敪
        gt_head_sales_invoice(ln_header_ok_no)   := lt_sales_invoice;        -- ����`�[�敪
        gt_head_card_class(ln_header_ok_no)      := lt_card_sale_class;      -- �J�[�h���敪
        gt_head_dlv_time(ln_header_ok_no)        := lt_dlv_time;             -- ����
        gt_head_change_time_100(ln_header_ok_no) := lt_change_out_100;       -- ��K�؂ꎞ��100�~
        gt_head_change_time_10(ln_header_ok_no)  := lt_change_out_10;        -- ��K�؂ꎞ��10�~
        gt_head_cus_number(ln_header_ok_no)      := lt_customer_number;      -- �ڋq�R�[�h
        gt_head_system_class(ln_header_ok_no)    := lt_bus_low_type;         -- �Ƒԋ敪
        gt_head_input_class(ln_header_ok_no)     := lt_input_class;          -- ���͋敪
        gt_head_tax_class(ln_header_ok_no)       := lt_tax_class;            -- ����ŋ敪
        gt_head_total_amount(ln_header_ok_no)    := lt_total_amount;         -- ���v���z
        gt_head_sale_discount(ln_header_ok_no)   := lt_sale_discount;        -- ����l���z
        gt_head_sales_tax(ln_header_ok_no)       := lt_sales_tax;            -- �������Ŋz
        gt_head_tax_include(ln_header_ok_no)     := lt_tax_include;          -- �ō����z
        gt_head_keep_in_code(ln_header_ok_no)    := lt_keep_in_code;         -- �a����R�[�h
        gt_head_depart_screen(ln_header_ok_no)   := lt_department_class;     -- �S�ݓX��ʎ��
        gt_resource_id(ln_header_ok_no)          := lt_resource_id;          -- ���\�[�XID
        gt_party_id(ln_header_ok_no)             := lt_party_id;             -- �p�[�e�BID
        gt_party_name(ln_header_ok_no)           := lt_customer_name;        -- �ڋq����
        gt_cus_status(ln_header_ok_no)           := lt_cus_status;           -- �ڋq�X�e�[�^�X
        ln_header_ok_no := ln_header_ok_no + 1;
--
        --==============================================================
        --�[�i�f�[�^�i���ׁj��ϐ��֊i�[
        --==============================================================
        FOR i IN 1..lt_line_temp.COUNT LOOP
          gt_line_order_no_hht(ln_line_ok_no)   := lt_line_temp(i).order_nol_hht;     -- ��No.�iHHT�j
          gt_line_line_no_hht(ln_line_ok_no)    := lt_line_temp(i).line_no_hht;       -- �sNo.�iHHT�j
          gt_line_order_no_ebs(ln_line_ok_no)   := lt_line_temp(i).order_nol_ebs;     -- ��No.�iEBS�j
          gt_line_line_num_ebs(ln_line_ok_no)   := lt_line_temp(i).line_number;       -- ���הԍ�(EBS)
          gt_line_item_code_self(ln_line_ok_no) := lt_line_temp(i).item_code;         -- �i���R�[�h�i���Ёj
          gt_line_content(ln_line_ok_no)        := lt_line_temp(i).content;           -- ����
          gt_line_item_id(ln_line_ok_no)        := lt_line_temp(i).item_id;           -- �i��ID
          gt_line_standard_unit(ln_line_ok_no)  := lt_line_temp(i).standard_unit;     -- ��P��
          gt_line_case_number(ln_line_ok_no)    := lt_line_temp(i).case_number;       -- �P�[�X��
          gt_line_quantity(ln_line_ok_no)       := lt_line_temp(i).quantity;          -- ����
          gt_line_sale_class(ln_line_ok_no)     := lt_line_temp(i).sale_class;        -- ����敪
          gt_line_wholesale_unit(ln_line_ok_no) := lt_line_temp(i).wholesale_price;   -- ���P��
          gt_line_selling_price(ln_line_ok_no)  := lt_line_temp(i).selling_price;     -- ���P��
          gt_line_column_no(ln_line_ok_no)      := lt_line_temp(i).column_no;         -- �R����No.
          gt_line_h_and_c(ln_line_ok_no)        := lt_line_temp(i).h_and_c;           -- H/C
          gt_line_sold_out_class(ln_line_ok_no) := lt_line_temp(i).sold_out_class;    -- ���؋敪
          gt_line_sold_out_time(ln_line_ok_no)  := lt_line_temp(i).sold_out_time;     -- ���؎���
          gt_line_replenish_num(ln_line_ok_no)  := lt_line_temp(i).replenish_num;     -- ��[��
          gt_line_cash_and_card(ln_line_ok_no)  := lt_line_temp(i).cash_and_card;     -- �����E�J�[�h���p�z
          ln_line_ok_no := ln_line_ok_no + 1;
        END LOOP;
      END IF;
--
      -- �[�i���׃f�[�^�ꎞ�i�[�p�ϐ���������
      lt_line_temp.DELETE;
      ln_temp_no := 1;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END data_check;
--
  /***********************************************************************************
   * Procedure Name   : error_data_register
   * Description      : �G���[�f�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE error_data_register(
    on_warn_cnt       OUT NUMBER,           --   �x������
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'error_data_register'; -- �v���O������
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
    -- �x������������
    on_warn_cnt := 0;
--
    --==============================================================
    -- HHT�G���[���X�g���[���[�N�e�[�u���փG���[�f�[�^�o�^
    --==============================================================
    -- �x�������Z�b�g
    on_warn_cnt := gt_err_base_code.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_warn_cnt
        INSERT INTO xxcos_rep_hht_err_list
          (
            record_id,
            base_code,
            base_name,
            origin_shipment,
            data_name,
            order_no_hht,
            invoice_invent_date,
            entry_number,
            line_no,
            order_no_ebs,
            party_num,
            customer_name,
            payment_dlv_date,
            payment_class_name,
            performance_by_code,
            item_code,
            error_message,
            report_group_id,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            xxcos_rep_hht_err_list_s01.NEXTVAL,          -- ���R�[�hID
            gt_err_base_code(i),                         -- ���_�R�[�h
            gt_err_base_name(i),                         -- ���_����
            NULL,                                        -- �o�ɑ��R�[�h
            gt_err_data_name(i),                         -- �f�[�^����
            gt_err_order_no_hht(i),                      -- ��NO�iHHT�j
            NULL,                                        -- �`�[/�I����
            gt_err_entry_number(i),                      -- �`�[NO
            gt_err_line_no(i),                           -- �sNO
--****************************** 2009/05/15 1.13 N.Maeda MOD START  *****************************--
            DECODE ( gt_err_order_no_ebs(i) ,            -- ��NO�iEBS�j
                     ct_order_no_ebs_0 , NULL ,
                     gt_err_order_no_ebs(i) ) ,
--            gt_err_order_no_ebs(i),                      -- ��NO�iEBS�j
--****************************** 2009/05/15 1.13 N.Maeda MOD  END   *****************************--
            gt_err_party_num(i),                         -- �ڋq�R�[�h
            gt_err_customer_name(i),                     -- �ڋq��
            gt_err_payment_dlv_date(i),                  -- ����/�[�i��
            NULL,                                        -- �����敪����
            gt_err_perform_by_code(i),                   -- ���ю҃R�[�h
            gt_err_item_code(i),                         -- �i�ڃR�[�h
            gt_err_error_message(i),                     -- �G���[���e
            NULL,                                        -- ���[�p�O���[�vID
            cn_created_by,                               -- �쐬��
            cd_creation_date,                            -- �쐬��
            cn_last_updated_by,                          -- �ŏI�X�V��
            cd_last_update_date,                         -- �ŏI�X�V��
            cn_last_update_login,                        -- �ŏI�X�V���O�C��
            cn_request_id,                               -- �v��ID
            cn_program_application_id,                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                               -- �R���J�����g�E�v���O����ID
            cd_program_update_date                       -- �v���O�����X�V��
          );
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_err_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END error_data_register;
--
  /***********************************************************************************
   * Procedure Name   : header_data_register
   * Description      : �[�i�w�b�_�e�[�u���փf�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE header_data_register(
    on_normal_cnt     OUT NUMBER,           --   �[�i�w�b�_�f�[�^�쐬����
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'header_data_register'; -- �v���O������
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
    cv_entry_class  VARCHAR2(1) DEFAULT '3';  -- �K��L�����o�^�FDFF12�i�o�^�敪�j
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
    -- �[�i�w�b�_�f�[�^�쐬����������
    on_normal_cnt := 0;
--
    --==============================================================
    -- �[�i�w�b�_�e�[�u���փf�[�^�o�^
    --==============================================================
    -- ���ʊ֐����K��L�����o�^��
    FOR i IN 1..gt_party_id.COUNT LOOP
--
      xxcos_task_pkg.task_entry(
        lv_errbuf                 -- �G���[�E���b�Z�[�W
       ,lv_retcode                -- ���^�[���E�R�[�h
       ,lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
       ,gt_resource_id(i)         -- ���\�[�XID
       ,gt_party_id(i)            -- �p�[�e�BID
       ,gt_party_name(i)          -- �p�[�e�B���́i�ڋq���́j
--****************************** 2009/05/15 1.14 N.Maeda MOD START  *****************************--
       ,TO_DATE(TO_CHAR( gt_head_dlv_date(i) , cv_shot_date_type)
                ||cv_spe_cha||SUBSTR(gt_head_dlv_time(i),1,2)
                ||cv_time_cha||SUBSTR(gt_head_dlv_time(i),3,2) , cv_date_type)
--       ,gt_head_dlv_date(i)       -- �K����� �� �[�i��
--****************************** 2009/05/15 1.14 N.Maeda MOD  END   *****************************--
       ,NULL                      -- �ڍד��e
       ,gt_head_total_amount(i)   -- ���v���z
       ,gt_head_input_class(i)    -- ���͋敪
       ,cv_entry_class            -- DFF12�i�o�^�敪�j�� 3
       ,gt_head_order_no_hht(i)   -- DFF13�i�o�^���\�[�X�ԍ��j�� ��No.�iHHT�j
       ,gt_cus_status(i)          -- DFF14�i�ڋq�X�e�[�^�X�j
      );
--
      --�G���[�`�F�b�N
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP;
--
--
    --== �f�[�^�o�^ ==--
    -- �[�i�w�b�_�f�[�^�쐬�����Z�b�g
    on_normal_cnt := gt_head_order_no_hht.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_normal_cnt
        INSERT INTO xxcos_dlv_headers
          (
            order_no_hht,
            digestion_ln_number,
            order_no_ebs,
            base_code,
            performance_by_code,
            dlv_by_code,
            hht_invoice_no,
            dlv_date,
            inspect_date,
            sales_classification,
            sales_invoice,
            card_sale_class,
            dlv_time,
            change_out_time_100,
            change_out_time_10,
            customer_number,
            system_class,
            input_class,
            consumption_tax_class,
            total_amount,
            sale_discount_amount,
            sales_consumption_tax,
            tax_include,
            keep_in_code,
            department_screen_class,
            red_black_flag,
            stock_forward_flag,
            stock_forward_date,
            results_forward_flag,
            results_forward_date,
            cancel_correct_class,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            gt_head_order_no_hht(i),                     -- ��No.�iHHT)
            cv_default,                                  -- �}��
            gt_head_order_no_ebs(i),                     -- ��No.�iEBS�j
            gt_head_base_code(i),                        -- ���_�R�[�h
            gt_head_perform_code(i),                     -- ���ю҃R�[�h
            gt_head_dlv_by_code(i),                      -- �[�i�҃R�[�h
            gt_head_hht_invoice_no(i),                   -- HHT�`�[No.
            gt_head_dlv_date(i),                         -- �[�i��
            gt_head_inspect_date(i),                     -- ������
            gt_head_sales_class(i),                      -- ���㕪�ދ敪
            gt_head_sales_invoice(i),                    -- ����`�[�敪
            gt_head_card_class(i),                       -- �J�[�h���敪
            gt_head_dlv_time(i),                         -- ����
            gt_head_change_time_100(i),                  -- ��K�؂ꎞ��100�~
            gt_head_change_time_10(i),                   -- ��K�؂ꎞ��10�~
            gt_head_cus_number(i),                       -- �ڋq�R�[�h
            gt_head_system_class(i),                     -- �Ƒԋ敪
            gt_head_input_class(i),                      -- ���͋敪
            gt_head_tax_class(i),                        -- ����ŋ敪
            gt_head_total_amount(i),                     -- ���v���z
            gt_head_sale_discount(i),                    -- ����l���z
            gt_head_sales_tax(i),                        -- �������Ŋz
            gt_head_tax_include(i),                      -- �ō����z
            gt_head_keep_in_code(i),                     -- �a����R�[�h
            gt_head_depart_screen(i),                    -- �S�ݓX��ʎ��
            cv_hit,                                      -- �ԍ��t���O
            cv_default,                                  -- ���o�ɓ]���σt���O
            NULL,                                        -- ���o�ɓ]���ϓ��t
            cv_default,                                  -- �̔����јA�g�ς݃t���O
            NULL,                                        -- �̔����јA�g�ςݓ��t
            NULL,                                        -- ����E�����敪
            cn_created_by,                               -- �쐬��
            cd_creation_date,                            -- �쐬��
            cn_last_updated_by,                          -- �ŏI�X�V��
            cd_last_update_date,                         -- �ŏI�X�V��
            cn_last_update_login,                        -- �ŏI�X�V���O�C��
            cn_request_id,                               -- �v��ID
            cn_program_application_id,                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                               -- �R���J�����g�E�v���O����ID
            cd_program_update_date                       -- �v���O�����X�V��
          );
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END header_data_register;
--
  /***********************************************************************************
   * Procedure Name   : lines_data_register
   * Description      : �[�i���׃e�[�u���փf�[�^�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE lines_data_register(
    on_normal_cnt     OUT NUMBER,           --   �[�i���׃f�[�^�쐬����
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lines_data_register'; -- �v���O������
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
    -- �[�i���׃f�[�^�쐬����������
    on_normal_cnt := 0;
--
    --==============================================================
    -- �[�i���׃e�[�u���փf�[�^�o�^
    --==============================================================
    -- �[�i���׃f�[�^�쐬�����Z�b�g
    on_normal_cnt := gt_line_order_no_hht.COUNT;
--
    BEGIN
--
      FORALL i IN 1..on_normal_cnt
        INSERT INTO xxcos_dlv_lines
          (
            order_no_hht,
            line_no_hht,
            digestion_ln_number,
            order_no_ebs,
            line_number_ebs,
            item_code_self,
            content,
            inventory_item_id,
            standard_unit,
            case_number,
            quantity,
            sale_class,
            wholesale_unit_ploce,
            selling_price,
            column_no,
            h_and_c,
            sold_out_class,
            sold_out_time,
            replenish_number,
            cash_and_card,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          )
        VALUES
          (
            gt_line_order_no_hht(i),                     -- ��No.�iHHT�j
            gt_line_line_no_hht(i),                      -- �sNo.�iHHT�j
            cv_default,                                  -- �}��
            gt_line_order_no_ebs(i),                     -- ��No.�iEBS�j
            gt_line_line_num_ebs(i),                     -- ���הԍ��iEBS�j
            gt_line_item_code_self(i),                   -- �i���R�[�h�i���Ёj
            gt_line_content(i),                          -- ����
            gt_line_item_id(i),                          -- �i��ID
            gt_line_standard_unit(i),                    -- ��P��
            gt_line_case_number(i),                      -- �P�[�X��
            gt_line_quantity(i),                         -- ����
            gt_line_sale_class(i),                       -- ����敪
            gt_line_wholesale_unit(i),                   -- ���P��
            gt_line_selling_price(i),                    -- ���P��
            gt_line_column_no(i),                        -- �R����No.
            gt_line_h_and_c(i),                          -- H/C
            gt_line_sold_out_class(i),                   -- ���؋敪
            gt_line_sold_out_time(i),                    -- ���؎���
            gt_line_replenish_num(i),                    -- ��[��
            gt_line_cash_and_card(i),                    -- �����E�J�[�h���p�z
            cn_created_by,                               -- �쐬��
            cd_creation_date,                            -- �쐬��
            cn_last_updated_by,                          -- �ŏI�X�V��
            cd_last_update_date,                         -- �ŏI�X�V��
            cn_last_update_login,                        -- �ŏI�X�V���O�C��
            cn_request_id,                               -- �v��ID
            cn_program_application_id,                   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                               -- �R���J�����g�E�v���O����ID
            cd_program_update_date                       -- �v���O�����X�V��
          );
--
    EXCEPTION
--
      -- �G���[�����i�f�[�^�ǉ��G���[�j
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_add, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END lines_data_register;
--
  /***********************************************************************************
   * Procedure Name   : work_data_delete
   * Description      : ���[�N�e�[�u�����R�[�h�폜(A-6)
   ***********************************************************************************/
  PROCEDURE work_data_delete(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'work_data_delete'; -- �v���O������
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
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
--
    -- �[�i�w�b�_���[�N�S�f�[�^���b�N
    CURSOR loc_headers_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_headers_work
    FOR UPDATE NOWAIT;
    -- �[�i���׃��[�N�S�f�[�^���b�N
    CURSOR loc_lines_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_lines_work
    FOR UPDATE NOWAIT;
--
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
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
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    --  �N�������敪3�̏ꍇ�r�����䏈�������{
    IF ( gv_mode = cv_truncate ) THEN
--
      -- �w�b�_���[�N�ɔr����������{
      BEGIN
--
        OPEN  loc_headers_cur;
        CLOSE loc_headers_cur;
--
      EXCEPTION
        WHEN lock_expt THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
        lv_errbuf  := lv_errmsg;
        -- �J�[�\��CLOSE
        IF ( loc_headers_cur%ISOPEN ) THEN
          CLOSE loc_headers_cur;
        END IF;
--
        RAISE global_api_expt;
      END;
--
      -- ���׃��[�N�ɔr����������{
      BEGIN
--
        OPEN  loc_lines_cur;
        CLOSE loc_lines_cur;
--
      EXCEPTION
        WHEN lock_expt THEN
          gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
          lv_errbuf  := lv_errmsg;
--
          -- �J�[�\��CLOSE
          IF ( loc_lines_cur%ISOPEN ) THEN
            CLOSE loc_lines_cur;
          END IF;
--
          RAISE global_api_expt;
      END;
--
    END IF;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
    --==============================================================
    -- �[�i�w�b�_���[�N�e�[�u���̃��R�[�h�폜
    --==============================================================
    BEGIN
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_dlv_headers_work';
      DELETE FROM xxcos_dlv_headers_work;
      gn_wh_del_count := SQL%ROWCOUNT;
--****************************** 2010/01/27 1.23 N.Maeda  MOD  END  *******************************--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_headwk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �[�i���׃��[�N�e�[�u���̃��R�[�h�폜
    --==============================================================
    BEGIN
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcos.xxcos_dlv_lines_work';
      DELETE FROM xxcos_dlv_lines_work;
      gn_wl_del_count := SQL%ROWCOUNT;
--****************************** 2010/01/27 1.23 N.Maeda  MOD  END  *******************************--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_linewk_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END work_data_delete;
--
  /***********************************************************************************
   * Procedure Name   : table_lock
   * Description      : �e�[�u�����b�N(A-7)
   ***********************************************************************************/
  PROCEDURE table_lock(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'table_lock'; -- �v���O������
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
    lv_purge_date    VARCHAR2(5);  -- �p�[�W�����Z�o���
    ld_process_date  DATE;         -- �Ɩ�������
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR headers_lock_cur
    IS
      SELECT head.creation_date  creation_date
      FROM   xxcos_dlv_headers   head
      WHERE  TRUNC( head.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
--
    CURSOR lines_lock_cur
    IS
      SELECT line.creation_date  creation_date
      FROM   xxcos_dlv_lines     line
      WHERE  TRUNC( line.creation_date ) < ( gd_process_date - gn_purge_date )
      FOR UPDATE NOWAIT;
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
    --==============================================================
    -- �v���t�@�C���̎擾(XXCOS:�[�i�f�[�^�捞�p�[�W�������Z�o�����)
    --==============================================================
    lv_purge_date := FND_PROFILE.VALUE( cv_prf_purge_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_purge_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_purge_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gn_purge_date := TO_NUMBER( lv_purge_date );
    END IF;
--
    --==============================================================
    -- ���ʊ֐����Ɩ��������擾���̌Ăяo��
    --==============================================================
     ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==============================================================
    -- �e�[�u�����b�N
    --==============================================================
    OPEN  headers_lock_cur;
    CLOSE headers_lock_cur;
--
    OPEN  lines_lock_cur;
    CLOSE lines_lock_cur;
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_table, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( headers_lock_cur%ISOPEN ) THEN
        CLOSE headers_lock_cur;
      END IF;
--
      IF ( lines_lock_cur%ISOPEN ) THEN
        CLOSE lines_lock_cur;
      END IF;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END table_lock;
--
  /***********************************************************************************
   * Procedure Name   : dlv_data_delete
   * Description      : �[�i�w�b�_�E���׃e�[�u�����R�[�h�폜(A-8)
   ***********************************************************************************/
  PROCEDURE dlv_data_delete(
    ov_errbuf         OUT VARCHAR2,         --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,         --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)         --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_delete'; -- �v���O������
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
    --==============================================================
    -- �[�i�w�b�_�e�[�u���̕s�v�f�[�^�폜
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_dlv_headers
      WHERE TRUNC( xxcos_dlv_headers.creation_date ) < ( gd_process_date - gn_purge_date );
--
      gn_del_cnt_h := SQL%ROWCOUNT;    -- �w�b�_�폜����
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_head_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- �[�i���׃e�[�u���̕s�v�f�[�^�폜
    --==============================================================
    BEGIN
--
      DELETE FROM xxcos_dlv_lines
      WHERE TRUNC( xxcos_dlv_lines.creation_date ) < ( gd_process_date - gn_purge_date );
--
      gn_del_cnt_l := SQL%ROWCOUNT;      -- ���׍폜����
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_line_tab );
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del, cv_tkn_table, gv_tkn1 );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    --==============================================================
    -- �폜�����o��
    --==============================================================
    -- �w�b�_����
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_h, cv_tkn_count, TO_CHAR( gn_del_cnt_h ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ���׌���
    gv_out_msg := xxccp_common_pkg.get_msg( cv_application, cv_msg_del_l, cv_tkn_count, TO_CHAR( gn_del_cnt_l ) );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_mode       IN  VARCHAR2,     --   �N�����[�h�i1:���� or 2:��ԁj
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_line_cnt   NUMBER;     -- ���o�����i�[�i���׃��[�N�e�[�u���j
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_tar_cnt_h  := 0;
    gn_tar_cnt_l  := 0;
    gn_nor_cnt_h  := 0;
    gn_nor_cnt_l  := 0;
    gn_del_cnt_h  := 0;
    gn_del_cnt_l  := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    gn_wh_del_count := 0;
    gn_wl_del_count := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-0)
    -- ===============================
    gv_mode := iv_mode;
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_errbuf   :=  lv_errbuf;
      ov_retcode  :=  lv_retcode;
      ov_errmsg   :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    IF ( gv_mode = cv_daytime ) THEN    -- ���ԋN�����̏���
--
      -- ============================================
      -- �[�i�f�[�^���o(A-1)
      -- ============================================
      dlv_data_receive(
        gn_tar_cnt_h,           -- �Ώی����i�[�i�w�b�_���[�N�e�[�u���j
        gn_tar_cnt_l,           -- �Ώی����i�[�i���׃��[�N�e�[�u���j
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
--
      -- �x�������i�Ώۃf�[�^�����G���[�j
      ELSIF ( gn_tar_cnt_h = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
        FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
        ov_retcode := cv_status_warn;
--
      END IF;
--
      --== �Ώۃf�[�^��1���ȏ゠��ꍇ�AA-2����A-6�̏������s���܂��B ==--
      IF ( gn_tar_cnt_h >= 1 ) THEN
        -- ============================================
        -- �f�[�^�Ó����`�F�b�N(A-2)
        -- ============================================
        data_check(
          gn_tar_cnt_l,           -- ���������i���ו��j
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_errbuf   :=  lv_errbuf;
          ov_retcode  :=  lv_retcode;
          ov_errmsg   :=  lv_errmsg;
        END IF;
--
        -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ============================================
        -- �G���[�f�[�^�o�^(A-3)
        -- ============================================
        -- �Ó����`�F�b�N�ŃG���[�ƂȂ����f�[�^�ɑ΂��Ĉȉ��̏������s���܂��B
        IF ( gt_err_base_code IS NOT NULL ) THEN
          error_data_register(
            gn_error_cnt,           -- �x������
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          --�G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- �[�i�w�b�_�e�[�u���փf�[�^�o�^(A-4)
        -- ============================================
        -- �Ó����`�F�b�N�ŃG���[�ƂȂ�Ȃ������f�[�^�ɑ΂��Ĉȉ��̏������s���B
        IF ( gt_head_order_no_hht IS NOT NULL ) THEN
          header_data_register(
            gn_nor_cnt_h,           -- �[�i�w�b�_�f�[�^�쐬����
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          --�G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- �[�i���׃e�[�u���փf�[�^�o�^(A-5)
        -- ============================================
        -- �Ó����̃`�F�b�N�ŃG���[�ƂȂ�Ȃ������f�[�^�ɑ΂��Ĉȉ��̏������s���B
        IF ( gt_line_order_no_hht IS NOT NULL ) THEN
          lines_data_register(
            gn_nor_cnt_l,           -- �[�i���׃f�[�^�쐬����
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          --�G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ============================================
        -- ���[�N�e�[�u�����R�[�h�폜(A-6)
        -- ============================================
        work_data_delete(
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        --�G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
--
    ELSIF ( gv_mode = cv_night ) THEN    -- ��ԋN�����̏���
--
      -- ============================================
      -- �e�[�u�����b�N(A-7)
      -- ============================================
      table_lock(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      -- ============================================
      -- �[�i�w�b�_�E���׃e�[�u�����R�[�h�폜(A-8)
      -- ============================================
      dlv_data_delete(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--****************************** 2010/01/27 1.23 N.Maeda  MOD START *******************************--
    ELSIF ( gv_mode = cv_truncate ) THEN    -- �N�����̏���
      -- ============================================
      -- ���[�N�e�[�u�����R�[�h�폜(A-6)
      -- ============================================
      work_data_delete(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      --�G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
--****************************** 2010/01/27 1.23 N.Maeda  MOD END   *******************************--
--
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_mode       IN  VARCHAR2       --   �N�����[�h�i1:���� or 2:��ԁj
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
       iv_mode     -- �N�����[�h
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ��������������
      gn_nor_cnt_h := 0;
      gn_nor_cnt_l := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
      gn_wh_del_count := 0;
      gn_wl_del_count := 0;
--****************************** 2010/01/27 1.23 N.Maeda  ADD  END  *******************************--
--
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
    -- ���ԋN�����̌����o��
    IF ( iv_mode = cv_daytime ) THEN
--
      --�w�b�_�Ώی����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tar_cnt_h
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_tar_cnt_h )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���בΏی����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tar_cnt_l
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_tar_cnt_l )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --�w�b�_���������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_nor_cnt_h
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_nor_cnt_h )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���א��������o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_nor_cnt_l
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_nor_cnt_l )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
      --�w�b�_���[�N�폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wh_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wh_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���׃��[�N�폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wl_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wl_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
      --�G���[�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    --
--****************************** 2010/01/27 1.23 N.Maeda  ADD START *******************************--
    ELSIF ( iv_mode = cv_truncate ) THEN
      --
      IF ( lv_retcode = cv_status_normal ) THEN
--
        --�폜�Ώۂ����݂��Ȃ��ꍇ
        IF ( gn_wh_del_count = 0 ) AND ( gn_wl_del_count = 0 ) THEN
          --���[�N�e�[�u���폜�Ώۃf�[�^�Ȃ����b�Z�[�W
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_no_del_target
                         )
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          
        ELSE
--
          --�S�폜���b�Z�[�W
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_mode3_comp
                         )
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        END IF;
      END IF;
      --
      --�w�b�_���[�N�폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wh_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wh_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      --
      --���׃��[�N�폜�����o��
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_wl_del_count
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_wl_del_count )
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
--
--****************************** 2010/01/27 1.23 N.Maeda  ADD END   *******************************--
    END IF;
--
    --�I�����b�Z�[�W
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
END XXCOS001A01C;
/
