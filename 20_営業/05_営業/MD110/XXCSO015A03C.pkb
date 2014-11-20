CREATE OR REPLACE PACKAGE BODY APPS.XXCSO015A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A03C(body)
 * Description      : SQL*Loader�ɂ���ĕ����f�[�^���[�N�e�[�u���i�A�h�I���j�Ɏ�荞�܂ꂽ
 *                      �����̏��𕨌��}�X�^�ɓo�^���܂��B
 * MD.050           : MD050_���̋@-EBS�C���^�t�F�[�X�F�iIN�j�����}�X�^���(IB)
 *                    2009/01/13 16:30
 * Version          : 1.17
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  get_item_instances     ������񒊏o (A-4)
 *  insert_item_instances  �����f�[�^�o�^���� (A-5)
 *  rock_item_instances    �������b�N���� (A-7)
 *  update_item_instances  �����f�[�^�X�V���� (A-8)
 *  update_in_work_data    ��ƃf�[�^�e�[�u���̕��������t���O�X�V���� (A-9)
 *  update_cust_or_party   �ڋq�A�h�I���}�X�^�ƃp�[�e�B�}�X�^�X�V���� (A-10)
 *  delete_in_item_data    �����f�[�^���[�N�e�[�u���폜���� (A-12)
 *  submain                ���C�������v���V�[�W��
 *                           (IN) �����}�X�^��񒊏o (A-2)
 *                           �Z�[�u�|�C���g�ݒ� (A-3)
 *                           �_���폜�X�V�`�F�b�N (A-6)
 *                           �A�g�ϐ��탁�b�Z�[�W�o�͏��� (A-11)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������ (A-13)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-20    1.0   kyo              �V�K�쐬
 *  2009-03-16    1.1   abe              �ύX�Ǘ��ԍ�I_E_108�̑Ή�
 *  2009-03-25    1.2   N.Yabuki         �yST��Q�Ή�147�z�����֘A���ύX�����e�[�u���o�^�s��
 *  2009-03-25    1.2   N.Yabuki         �yST��Q�Ή�150�z���g���̒S�����_���s��
 *  2009-04-13    1.3   K.Satomura       �yT1_0418�Ή��z�C���X�^���X�^�C�v�R�[�h�s��
 *  2009-04-17    1.4   K.Satomura       �yT1_0466�Ή��zA-6�̏������폜
 *  2009-04-27    1.5   K.Satomura       �yT1_0490�Ή��z�@����3��o�^�X�V�s��
 *  2009-05-01    1.6   Tomoko.Mori      T1_0897�Ή�
 *  2009-05-07    1.7   Tomoko.Mori      �yT1_0439�A0530�Ή��z
 *                                       ���̋@�̂݌ڋq�֘A���X�V�iT1_0439�j
 *                                       �ݒu�p�����R�[�h�s���G���[�`�F�b�N�iT1_0530�j
 *  2009-05-19    1.8   K.Satomura       �yT1_0959�Ή��z�����˗��ԍ����r�`�F�b�N�s��
 *                                       �yT1_1066�Ή��zT1_0530�Ή��̎��
 *  2009-05-26    1.9   M.Ohtsuki        �yT1_1141�Ή��z���������X�V�R��̑Ή�
 *  2009-05-28    1.10  M.Ohtsuki        �yT1_1203�Ή��z�挎�f�[�^�X�V��Q�̑Ή�
 *  2009-06-01    1.11  K.Satomura       �yT1_1107�Ή��z
 *  2009-06-04    1.12  K.Satomura       �yT1_1107�ďC���Ή��z
 *  2009-06-15    1.13  K.Satomura       �yT1_1239�Ή��z
 *  2009-07-10    1.14  K.Satomura       �����e�X�g��Q�Ή�(0000476)
 *  2009-08-28    1.15  K.Satomura       �����e�X�g��Q�Ή�(0001205)
 *  2009-08-28    1.16  M.Maruyama       �����e�X�g��Q�Ή�(0001192)
 *  2009-09-14    1.17  K.Satomura       �����e�X�g��Q�Ή�(0001335)
 *  2009-11-29    1.18  T.Maruyama       E_�{�ғ�_00120 �V��ȊO��EBS��IB�̋@��CD�𐳂Ƃ���
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSO015A03C';      -- �p�b�P�[�W��
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_tkn_number_02        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_03        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_04        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00092';  -- �g�DID�擾�G���[
  cv_tkn_number_05        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00093';  -- �g�DID���o�G���[
  cv_tkn_number_06        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00094';  -- �i��ID�擾�G���[
  cv_tkn_number_07        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00095';  -- �i��ID���o�G���[
  cv_tkn_number_08        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00163';  -- �X�e�[�^�XID�擾�G���[
  cv_tkn_number_09        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00164';  -- �X�e�[�^�XID���o�G���[
  cv_tkn_number_10        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- ����^�C�vID�擾�G���[
  cv_tkn_number_11        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- ����^�C�vID���o�G���[
  cv_tkn_number_12        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- �ǉ�����ID���o�G���[
  cv_tkn_number_13        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- INV�H��ԕi�q�֐�R�[�h�擾�G���[
  cv_tkn_number_14        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00242';  -- �ڋq�}�X�^���Ȃ��G���[
  cv_tkn_number_15        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- �ڋq�}�X�^��񒊏o�G���[
  cv_tkn_number_16        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^���o�G���[
  cv_tkn_number_17        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00051';  -- �������݃`�F�b�N�x��
  cv_tkn_number_18        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00556';  -- �����X�V�`�F�b�N�x��
  cv_tkn_number_19        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00105';  -- �C���X�g�[���x�[�X�}�X�^(�����}�X�^)���o�G���[
  cv_tkn_number_20        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00090';  -- ���[�X�敪�擾�G���[
  cv_tkn_number_21        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00091';  -- ���[�X�敪���o�G���[
  cv_tkn_number_22        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00193';  -- �������[�N�e�[�u���̋@���ԕs��
  cv_tkn_number_23        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00098';  -- �ڋq�}�X�^���擾�ł��Ȃ�
  cv_tkn_number_24        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00099';  -- �ڋq�}�X�^��񒊏o���s
  cv_tkn_number_25        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00165';  -- �f�[�^�o�^�A�X�V���s
  cv_tkn_number_26        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00052';  -- �_���폜�X�V�`�F�b�N�G���[
  cv_tkn_number_27        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00166';  -- ���b�N�G���[
  cv_tkn_number_28        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00104';  -- �C���X�^���X�p�[�e�B�擾�G���[
  cv_tkn_number_29        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00105';  -- �C���X�^���X�p�[�e�B�擾�G���[
  cv_tkn_number_30        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00167';  -- (IN)�����}�X�^���A�g�ϐ��탁�b�Z�[�W
  cv_tkn_number_31        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00119';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_tkn_number_32        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00518';  -- �f�[�^���o0�����b�Z�[�W
/*20090507_mori_T1_0439 START*/
  cv_tkn_number_33        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00569';  -- �ݒu�p�����R�[�h�s���G���[
/*20090507_mori_T1_0439 END*/
--
  -- �g�[�N���R�[�h
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_prof_nm          CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_task_nm          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_organization     CONSTANT VARCHAR2(20) := 'ORGANIZATION_CODE';
  cv_tkn_segment          CONSTANT VARCHAR2(20) := 'SEGMENT';
  cv_tkn_organization_id  CONSTANT VARCHAR2(20) := 'ORGANIZATION_ID';
  cv_tkn_status_name      CONSTANT VARCHAR2(20) := 'STATUS_NAME';
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  cv_tkn_attribute_name   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_attribute_code   CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_bukken           CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_slip_num         CONSTANT VARCHAR2(20) := 'SLIP_NUM';
  cv_tkn_slip_branch_num  CONSTANT VARCHAR2(20) := 'SLIP_BRANCH_NUM';
  cv_tkn_line_num         CONSTANT VARCHAR2(20) := 'LINE_NUM';
  cv_tkn_work_kbn         CONSTANT VARCHAR2(20) := 'WORK_KBN';
  cv_tkn_bukken1          CONSTANT VARCHAR2(20) := 'BUKKEN1';
  cv_tkn_bukken2          CONSTANT VARCHAR2(20) := 'BUKKEN2';
  cv_tkn_hazard_state1    CONSTANT VARCHAR2(20) := 'HAZARD_STATE1';
  cv_tkn_hazard_state2    CONSTANT VARCHAR2(20) := 'HAZARD_STATE2';
  cv_tkn_hazard_state3    CONSTANT VARCHAR2(20) := 'HAZARD_STATE3';
  cv_tkn_account_num1     CONSTANT VARCHAR2(20) := 'ACCOUNT_NUM1';
  cv_tkn_account_num2     CONSTANT VARCHAR2(20) := 'ACCOUNT_NUM2';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS';
  cv_tkn_partnership_name CONSTANT VARCHAR2(20) := 'PARTNERSHIP_NAME';
  cv_tkn_cust_status_info CONSTANT VARCHAR2(20) := 'CUST_STATUS_UP_INFO';
  cv_tkn_cnvs_date        CONSTANT VARCHAR2(20) := 'CNVS_DATE';
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_last_req_no      CONSTANT VARCHAR2(20) := 'LAST_REQ_NO';
  cv_tkn_req_no           CONSTANT VARCHAR2(20) := 'REQ_NO';
  cv_tkn_seq_no           CONSTANT VARCHAR2(20) := 'SEQ_NO';
--
  -- ��Ƌ敪
  cn_work_kbn1            CONSTANT NUMBER        := 1;                -- �V��ݒu
  cn_work_kbn2            CONSTANT NUMBER        := 2;                -- ����ݒu
  cn_work_kbn3            CONSTANT NUMBER        := 3;                -- �V����
  cn_work_kbn4            CONSTANT NUMBER        := 4;                -- ������
  cn_work_kbn5            CONSTANT NUMBER        := 5;                -- ���g
  cn_work_kbn6            CONSTANT NUMBER        := 6;                -- �X���ړ�
--
  cb_true                 CONSTANT BOOLEAN       := TRUE;
--
  cv_true                    CONSTANT VARCHAR2(10) := 'TRUE';    -- ���ʊ֐��߂�l����p
  cv_false                   CONSTANT VARCHAR2(10) := 'FALSE';   -- ���ʊ֐��߂�l����p
--
  cv_active               CONSTANT VARCHAR2(1)   := 'A';              -- ACTIVE
--
  cv_encoded_f            CONSTANT VARCHAR2(1)   := 'F';              -- FALSE   
/*20090507_mori_T1_0439 START*/
--
  cv_instance_type_vd     CONSTANT VARCHAR2(1) := '1';        -- �C���X�^���X�X�e�[�^�X�^�C�v�i���̋@�j
--
/*20090507_mori_T1_0439 END*/
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< �Ɩ��������t�擾���� >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< �v���t�@�C���l�擾���� >>';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := 'lv_inv_mst_org_code   = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_vld_org_code       = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_bukken_item        = ';
  cv_debug_msg9           CONSTANT VARCHAR2(200) := 'gv_withdraw_base_code    = ';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := 'gv_jyki_withdraw_base_code = ';
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< �J�[�\�����I�[�v�����܂��� >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< �J�[�\�����N���[�Y���܂��� >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< ��O�������ŃJ�[�\�����N���[�Y���܂��� >>';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gn_account_id          NUMBER;                                        -- ���g���_�A�J�E���gID
  gn_party_site_id       NUMBER;                                        -- ���g���_�p�[�e�B�T�C�gID
  gn_party_id            NUMBER;                                        -- ���g���_�p�[�e�BID
  gv_area_code           VARCHAR2(100);                                 -- ���g���_�n��R�[�h
  gn_jyki_account_id     NUMBER;                                        -- �Y����g���_�A�J�E���gID
  gn_jyki_party_site_id  NUMBER;                                        -- �Y����g���_�p�[�e�B�T�C�gID
  gn_jyki_party_id       NUMBER;                                        -- �Y����g���_�p�[�e�BID
  gv_jyki_area_code      VARCHAR2(100);                                 -- �Y����g���_�n��R�[�h
  gb_insert_process_flg   BOOLEAN;                                       -- �o�^�X�V�t���O�uTRUE(�o�^)�AFALSE(�X�V)�v
  gb_rollback_flg         BOOLEAN := FALSE;                              -- TRUE : ���[���o�b�N
  gb_cust_status_free_flg BOOLEAN := FALSE;                              -- �ڋq�X�e�[�^�X�u�x�~�v�X�V�t���O    
  gb_cust_status_appr_flg BOOLEAN := FALSE;                              -- �ڋq�X�e�[�^�X�u���F�ρv�X�V�t���O    
  gb_cust_cnv_upd_flg     BOOLEAN := FALSE;                              -- �ڋq�l�����X�V�t���O    
  gv_withdraw_base_code   VARCHAR2(100);                                 -- ���g���_�R�[�h
  gv_jyki_withdraw_base_code  VARCHAR2(100);                             -- �Y����g���_�R�[�h
  gt_inv_mst_org_id       mtl_parameters.organization_id%TYPE;           -- �g�DID
  gt_vld_org_id           mtl_parameters.organization_id%TYPE;           -- ���ؑg�DID
  gt_txn_type_id          csi_txn_types.transaction_type_id%TYPE;        -- ����^�C�vID
  gt_bukken_item_id       mtl_system_items_b.inventory_item_id%TYPE;     -- �����p�i��ID
  gt_instance_status_id_1 csi_instance_statuses.instance_status_id%TYPE; -- �ғ���
  gt_instance_status_id_2 csi_instance_statuses.instance_status_id%TYPE; -- �g�p��
  gt_instance_status_id_3 csi_instance_statuses.instance_status_id%TYPE; -- ������
  gt_instance_status_id_4 csi_instance_statuses.instance_status_id%TYPE; -- �p���葱��
  gt_instance_status_id_5 csi_instance_statuses.instance_status_id%TYPE; -- �p��������
  gt_instance_status_id_6 csi_instance_statuses.instance_status_id%TYPE; -- �����폜��
  -- ��v���ԃ`�F�b�N�p
  gv_chk_rslt               VARCHAR2(10);
  gv_chk_rslt_flag          VARCHAR2(1);
--
  -- �ǉ�����ID�i�[�p���R�[�h�^��`
  TYPE gr_ib_ext_attribs_id_rtype IS RECORD(
     count_no              NUMBER               -- �J�E���^�[No.
    ,chiku_cd              NUMBER               -- �n��R�[�h
    ,sagyougaisya_cd       NUMBER               -- ��Ɖ�ЃR�[�h
    ,jigyousyo_cd          NUMBER               -- ���Ə��R�[�h
    ,den_no                NUMBER               -- �ŏI��Ɠ`�[No.
    ,job_kbn               NUMBER               -- �ŏI��Ƌ敪
    ,sintyoku_kbn          NUMBER               -- �ŏI��Ɛi��
    ,yotei_dt              NUMBER               -- �ŏI��Ɗ����\���
    ,kanryo_dt             NUMBER               -- �ŏI��Ɗ�����
    ,sagyo_level           NUMBER               -- �ŏI�������e
    ,den_no2               NUMBER               -- �ŏI�ݒu�`�[No.
    ,job_kbn2              NUMBER               -- �ŏI�ݒu�敪
    ,sintyoku_kbn2         NUMBER               -- �ŏI�ݒu�i��
    ,jotai_kbn1            NUMBER               -- �@����1�i�ғ���ԁj
    ,jotai_kbn2            NUMBER               -- �@����2�i��ԏڍׁj
    ,jotai_kbn3            NUMBER               -- �@����3�i�p�����j
    ,nyuko_dt              NUMBER               -- ���ɓ�
    ,hikisakigaisya_cd     NUMBER               -- ���g��ЃR�[�h
    ,hikisakijigyosyo_cd   NUMBER               -- ���g���Ə��R�[�h
    ,setti_tanto           NUMBER               -- �ݒu��S���Җ�
    ,setti_tel1            NUMBER               -- �ݒu��tel1
    ,setti_tel2            NUMBER               -- �ݒu��tel2
    ,setti_tel3            NUMBER               -- �ݒu��tel3
    ,haikikessai_dt        NUMBER               -- �p�����ٓ�
    ,tenhai_tanto          NUMBER               -- �]���p���Ǝ�
    ,tenhai_den_no         NUMBER               -- �]���p���`�[��
    ,syoyu_cd              NUMBER               -- ���L��
    ,tenhai_flg            NUMBER               -- �]���p���󋵃t���O
    ,kanryo_kbn            NUMBER               -- �]�������敪
    ,sakujo_flg            NUMBER               -- �폜�t���O
    ,ven_kyaku_last        NUMBER               -- �ŏI�ڋq�R�[�h
    ,ven_tasya_cd01        NUMBER               -- ���ЃR�[�h�P
    ,ven_tasya_daisu01     NUMBER               -- ���Б䐔�P
    ,ven_tasya_cd02        NUMBER               -- ���ЃR�[�h�Q
    ,ven_tasya_daisu02     NUMBER               -- ���Б䐔�Q
    ,ven_tasya_cd03        NUMBER               -- ���ЃR�[�h�R
    ,ven_tasya_daisu03     NUMBER               -- ���Б䐔�R
    ,ven_tasya_cd04        NUMBER               -- ���ЃR�[�h�S
    ,ven_tasya_daisu04     NUMBER               -- ���Б䐔�S
    ,ven_tasya_cd05        NUMBER               -- ���ЃR�[�h�T
    ,ven_tasya_daisu05     NUMBER               -- ���Б䐔�T
    ,ven_haiki_flg         NUMBER               -- �p���t���O
    ,ven_sisan_kbn         NUMBER               -- ���Y�敪
    ,ven_kobai_ymd         NUMBER               -- �w�����t
    ,ven_kobai_kg          NUMBER               -- �w�����z
    ,safty_level           NUMBER               -- ���S�ݒu�
    ,lease_kbn             NUMBER               -- ���[�X�敪
    ,last_inst_cust_code   NUMBER               -- �挎���ݒu��ڋq�R�[�h
    ,last_jotai_kbn        NUMBER               -- �挎���@����
    ,last_year_month       NUMBER               -- �挎���N��
  );
  -- �ǉ�����ID�i�[�p���R�[�h�ϐ�
  gr_ext_attribs_id_rec   gr_ib_ext_attribs_id_rtype;
--
  -- ������񃌃R�[�h
  TYPE g_get_data_rtype IS RECORD(
      seq_no                      NUMBER          -- �V�[�P���X�ԍ�
     ,slip_no                     NUMBER          -- �`�[No.
     ,slip_branch_no              NUMBER          -- �`�[�}��
     ,line_number                 NUMBER          -- �s�ԍ�
     ,job_kbn                     NUMBER          -- ��Ƌ敪
     ,install_code1               VARCHAR2(10)    -- �����R�[�h�P�i�ݒu�p�j
     ,install_code2               VARCHAR2(10)    -- �����R�[�h�Q�i���g�p�j
     /* 2009.06.15 K.Satomura T1_1239�Ή� START */
     ,completion_kbn              NUMBER          -- �����敪
     /* 2009.06.15 K.Satomura T1_1239�Ή� END */
     ,safe_setting_standard       VARCHAR2(1)     -- ���S�ݒu�
     ,install_code                VARCHAR2(10)    -- �����R�[�h
     ,un_number                   VARCHAR2(14)    -- �@��
     ,install_number              VARCHAR2(14)    -- �@��
     ,machinery_kbn               NUMBER          -- �@��敪
     ,first_install_date          NUMBER          -- ����ݒu��
     ,counter_no                  NUMBER          -- �J�E���^�[No.
     ,division_code               VARCHAR2(6)     -- �n��R�[�h
     ,base_code                   VARCHAR2(4)     -- ���_�R�[�h
     ,job_company_code            VARCHAR2(6)     -- ��Ɖ�ЃR�[�h
     ,location_code               VARCHAR2(4)     -- ���Ə��R�[�h
     ,last_job_slip_no            NUMBER          -- �ŏI��Ɠ`�[No.
     ,last_job_kbn                NUMBER          -- �ŏI��Ƌ敪
     ,last_job_going              NUMBER          -- �ŏI��Ɛi��
     ,last_job_cmpltn_plan_date   NUMBER          -- �ŏI��Ɗ����\���
     ,last_job_cmpltn_date        NUMBER          -- �ŏI��Ɗ�����
     ,last_maintenance_contents   NUMBER          -- �ŏI�������e
     ,last_install_slip_no        NUMBER          -- �ŏI�ݒu�`�[No.
     ,last_install_kbn            NUMBER          -- �ŏI�ݒu�敪
     ,last_install_plan_date      NUMBER          -- �ŏI�ݒu�\���
     ,last_install_going          NUMBER          -- �ŏI�ݒu�i��
     ,machinery_status1           NUMBER          -- �@����1�i�ғ���ԁj
     ,machinery_status2           NUMBER          -- �@����2�i��ԏڍׁj
     ,machinery_status3           NUMBER          -- �@����3�i�p�����j
     ,stock_date                  NUMBER          -- ���ɓ�
     ,withdraw_company_code       VARCHAR2(6)     -- ���g��ЃR�[�h
     ,withdraw_location_code      VARCHAR2(4)     -- ���g���Ə��R�[�h
     ,resale_disposal_vendor      VARCHAR2(6)     -- �]���p���Ǝ�
     ,resale_disposal_slip_no     NUMBER          -- �]���p���`�[��
     ,owner_company_code          VARCHAR2(4)     -- ���L��
     ,resale_disposal_flag        NUMBER          -- �]���p���󋵃t���O
     ,resale_completion_kbn       NUMBER          -- �]�������敪
     ,delete_flag                 NUMBER          -- �폜�t���O
     ,creation_date_time          DATE            -- �쐬���������b
     ,update_date_time            DATE            -- �X�V���������b
     ,account_number1             VARCHAR2(9)     -- �ڋq�R�[�h�P�i�V�ݒu��
     ,account_number2             VARCHAR2(9)     -- �ڋq�R�[�h�Q�i���ݒu��
     ,po_number                   NUMBER          -- �����ԍ�
     ,po_line_number              NUMBER          -- �������הԍ�
     ,po_req_number               NUMBER          -- �����˗��ԍ�
     ,line_num                    NUMBER          -- �����˗����הԍ�
     ,instance_id                 NUMBER          -- �C���X�^���XID
     ,object_version1             NUMBER          -- �I�u�W�F�N�g�o�[�W�����ԍ�
     ,instance_status_id          NUMBER          -- �C���X�^���X�X�e�[�^�XID
     ,new_old_flg                 VARCHAR2(1)     -- �V�Ñ�t���O
     ,actual_work_date            NUMBER          -- ����Ɠ�
     /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
     ,ib_un_number                VARCHAR2(14)    -- �C���X�g�[���x�[�X�@��
     /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */
  );
--
  -- �H��ԕi�q�֐�R�[�h���R�[�h��`
  TYPE gr_mfg_fctory_code_rtype is RECORD(
     mfg_fctory_code              VARCHAR2(100)          -- INV�H��ԕi�q�֐�R�[�h
  );
--
  -- �H��ԕi�q�֐�R�[�h�e�[�u����`
  TYPE gt_mfg_fctory_code_ttype is TABLE OF gr_mfg_fctory_code_rtype INDEX BY BINARY_INTEGER;
  -- �H��ԕi�q�֐�R�[�h�e�[�u���ϐ�
  gt_mfg_fctory_code_tab  gt_mfg_fctory_code_ttype;
--  
  -- �ǉ������l�̃��R�[�h��`�ǉ������lID�A�ǉ������l�A�I�u�W�F�N�g�o�[�W�����ԍ���
  TYPE gr_csi_iea_values_rtype is RECORD(
     attribute_value_id          NUMBER                 -- �ǉ������lID
    ,attribute_value             VARCHAR2(240)          -- �ǉ������l
    ,object_version_number       NUMBER                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
  );
--  
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_expt        EXCEPTION;
  global_lock_expt        EXCEPTION;                                 -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     od_sysdate           OUT DATE                 -- �V�X�e�����t
    ,od_process_date      OUT NOCOPY DATE          -- �Ɩ��������t
    ,ov_errbuf            OUT NOCOPY VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
    -- �v���t�@�C����
--
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(�ғ���)�R�[�h
    cv_instance_status_1      CONSTANT VARCHAR2(1)   := '1';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(�g�p��)�R�[�h
    cv_instance_status_2      CONSTANT VARCHAR2(1)   := '2';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(������)�R�[�h
    cv_instance_status_3      CONSTANT VARCHAR2(1)   := '3';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(�p���葱��)�R�[�h
    cv_instance_status_4      CONSTANT VARCHAR2(1)   := '4';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(�p��������)�R�[�h
    cv_instance_status_5      CONSTANT VARCHAR2(1)   := '5';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X(�����폜��)�R�[�h
    cv_instance_status_6      CONSTANT VARCHAR2(1)   := '6';
    -- XXCSO:�݌Ƀ}�X�^�g�D
    cv_inv_mst_org_code       CONSTANT VARCHAR2(30)  := 'XXCSO1_INV_MST_ORG_CODE';
    -- XXCSO:���ؑg�D
    cv_vld_org_code           CONSTANT VARCHAR2(30)  := 'XXCSO1_VLD_ORG_CODE';
    -- XXCSO:�����p�i��
    cv_bukken_item            CONSTANT VARCHAR2(30)  := 'XXCSO1_BUKKEN_ITEM';
    -- XXCSO:�ɓ����ڋq��
--    cv_itoen_cust_name        CONSTANT VARCHAR2(30)  := 'XXCSO1_ITOEN_CUST_NAME';
    -- XXCSO:���g���_�敪
--    cv_withdraw_base_type     CONSTANT VARCHAR2(30)  := 'XXCSO1_WITHDRAW_BASE_TYPE';
    -- XXCSO:���g���_�R�[�h
    cv_withdraw_base_code     CONSTANT VARCHAR2(30)  := 'XXCSO1_WITHDRAW_BASE_CODE';
    -- XXCSO:�Y����g���_�R�[�h
    cv_jyki_withdraw_base_code  CONSTANT VARCHAR2(30)  := 'XXCSO1_JYKI_WTHDRW_BASE_CODE';
--
    -- �\�[�X�g�����U�N�V�����^�C�v
    cv_src_transaction_type   CONSTANT VARCHAR2(30)  := 'IB_UI';
    -- �H��ԕi�q�֐�R�[�h
    cv_xxcoi_mfg_fctory_type  CONSTANT VARCHAR2(30)  := 'XXCOI_MFG_FCTORY_CD';
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X�^�C�v�R�[�h
    cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
    -- ���o���e��(�݌Ƀ}�X�^�̑g�DID)
    cv_mtl_parameters_info    CONSTANT VARCHAR2(100) := '�݌Ƀ}�X�^�̑g�DID';
    -- ���o���e��(�݌Ƀ}�X�^�̌��ؑg�DID)
    cv_mtl_parameters_vld     CONSTANT VARCHAR2(100) := '�݌Ƀ}�X�^�̌��ؑg�DID';
    -- ���o���e��(�i�ڃ}�X�^�̕i��ID)
    cv_mtl_system_items_id    CONSTANT VARCHAR2(100) := '�i�ڃ}�X�^�̕i��ID';
    -- ���o���e��(�C���X�^���X�X�e�[�^�X�}�X�^�̃X�e�[�^�XID)
    cv_csi_instance_statuses  CONSTANT VARCHAR2(100) := '�C���X�^���X�X�e�[�^�X�}�X�^�̃X�e�[�^�XID';
    -- ���o���e��(����^�C�v�̎���^�C�vID)
    cv_csi_txn_types          CONSTANT VARCHAR2(100) := '����^�C�v�̎���^�C�vID';
    -- ���o���e��(�ݒu�@��g��������`���̒ǉ�����ID)
    cv_attribute_id_info      CONSTANT VARCHAR2(100) := '�ݒu�@��g��������`���̒ǉ�����ID';
    -- ���o���e��(�Q�ƃ^�C�v�̍H��ԕi�q�֐�R�[�h)
    cv_mfg_fctory_code_info   CONSTANT VARCHAR2(100) := '�Q�ƃ^�C�v�̍H��ԕi�q�֐�R�[�h';
    -- ���o���e��(�ɓ����̌ڋq�}�X�^���)
    cv_cust_acct_sites_info   CONSTANT VARCHAR2(100) := '���g���_�̌ڋq�}�X�^���';
    -- ���o���e��(�ɓ����̌ڋq�}�X�^���)
    cv_cust_acct_sites_info1  CONSTANT VARCHAR2(100) := '�Y����g���_�̌ڋq�}�X�^���';
    -- ���o���e��(�ڋq�R�[�h)
    cv_cust_account_number    CONSTANT VARCHAR2(100) := '�ڋq�R�[�h';
    -- �X�e�[�^�X��(�ғ���)
    cv_statuses_name01        CONSTANT VARCHAR2(100) := '�ғ���';
    -- �X�e�[�^�X��(�g�p��)
    cv_statuses_name02        CONSTANT VARCHAR2(100) := '�g�p��';
    -- �X�e�[�^�X��(������)
    cv_statuses_name03        CONSTANT VARCHAR2(100) := '������';
    -- �X�e�[�^�X��(�p���葱��)
    cv_statuses_name04        CONSTANT VARCHAR2(100) := '�p���葱��';
    -- �X�e�[�^�X��(�p��������)
    cv_statuses_name05        CONSTANT VARCHAR2(100) := '�p��������';
    -- �X�e�[�^�X��(�����폜��)
    cv_statuses_name06        CONSTANT VARCHAR2(100) := '�����폜��';
--
    -- �J�E���^�[No.
    cv_i_ext_count_no         CONSTANT VARCHAR2(100) := '�J�E���^�[No.';
    -- �n��R�[�h
    cv_i_ext_chiku_cd         CONSTANT VARCHAR2(100) := '�n��R�[�h';
    -- ��Ɖ�ЃR�[�h
    cv_i_ext_sagyougaisya_cd  CONSTANT VARCHAR2(100) := '��Ɖ�ЃR�[�h';
    -- ���Ə��R�[�h
    cv_i_ext_jigyousyo_cd     CONSTANT VARCHAR2(100) := '���Ə��R�[�h';
    -- �ŏI��Ɠ`�[No.
    cv_i_ext_den_no           CONSTANT VARCHAR2(100) := '�ŏI��Ɠ`�[No.';
    -- �ŏI��Ƌ敪
    cv_i_ext_job_kbn          CONSTANT VARCHAR2(100) := '�ŏI��Ƌ敪';
    -- �ŏI��Ɛi��
    cv_i_ext_sintyoku_kbn     CONSTANT VARCHAR2(100) := '�ŏI��Ɛi��';
    -- �ŏI��Ɗ����\���
    cv_i_ext_yotei_dt         CONSTANT VARCHAR2(100) := '�ŏI��Ɗ����\���';
    -- �ŏI��Ɗ�����
    cv_i_ext_kanryo_dt        CONSTANT VARCHAR2(100) := '�ŏI��Ɗ�����';
    -- �ŏI�������e
    cv_i_ext_sagyo_level      CONSTANT VARCHAR2(100) := '�ŏI�������e';
    -- �ŏI�ݒu�`�[No.
    cv_i_ext_den_no2          CONSTANT VARCHAR2(100) := '�ŏI�ݒu�`�[No.';
    -- �ŏI�ݒu�敪
    cv_i_ext_job_kbn2         CONSTANT VARCHAR2(100) := '�ŏI�ݒu�敪';
    -- �ŏI�ݒu�i��
    cv_i_ext_sintyoku_kbn2    CONSTANT VARCHAR2(100) := '�ŏI�ݒu�i��';
    -- �@����1�i�ғ���ԁj
    cv_i_ext_jotai_kbn1       CONSTANT VARCHAR2(100) := '�@����1�i�ғ���ԁj';
    -- �@����2�i��ԏڍׁj
    cv_i_ext_jotai_kbn2       CONSTANT VARCHAR2(100) := '�@����2�i��ԏڍׁj';
    -- �@����3�i�p�����j
    cv_i_ext_jotai_kbn3       CONSTANT VARCHAR2(100) := '�@����3�i�p�����j';
    -- ���ɓ�
    cv_i_ext_nyuko_dt         CONSTANT VARCHAR2(100) := '���ɓ�';
    -- ���g��ЃR�[�h
    cv_i_ext_hikisakicmy_cd   CONSTANT VARCHAR2(100) := '���g��ЃR�[�h';
    -- ���g���Ə��R�[�h
    cv_i_ext_hikisakilct_cd   CONSTANT VARCHAR2(100) := '���g���Ə��R�[�h';
    -- �ݒu��S���Җ�
    cv_i_ext_setti_tanto      CONSTANT VARCHAR2(100) := '�ݒu��S���Җ�';
    -- �ݒu��tel1
    cv_i_ext_setti_tel1       CONSTANT VARCHAR2(100) := '�ݒu��tel1';
    -- �ݒu��tel2
    cv_i_ext_setti_tel2       CONSTANT VARCHAR2(100) := '�ݒu��tel2';
    -- �ݒu��tel3
    cv_i_ext_setti_tel3       CONSTANT VARCHAR2(100) := '�ݒu��tel3';
    -- �p�����ٓ�
    cv_i_ext_haikikessai_dt   CONSTANT VARCHAR2(100) := '�p�����ٓ�';
    -- �]���p���Ǝ�
    cv_i_ext_tenhai_tanto     CONSTANT VARCHAR2(100) := '�]���p���Ǝ�';
    -- �]���p���`�[��
    cv_i_ext_tenhai_den_no    CONSTANT VARCHAR2(100) := '�]���p���`�[��';
    -- ���L��
    cv_i_ext_syoyu_cd         CONSTANT VARCHAR2(100) := '���L��';
    -- �]���p���󋵃t���O
    cv_i_ext_tenhai_flg       CONSTANT VARCHAR2(100) := '�]���p���󋵃t���O';
    -- �]�������敪
    cv_i_ext_kanryo_kbn       CONSTANT VARCHAR2(100) := '�]�������敪';
    -- �폜�t���O
    cv_i_ext_sakujo_flg       CONSTANT VARCHAR2(100) := '�폜�t���O';
    -- �ŏI�ڋq�R�[�h
    cv_i_ext_ven_kyaku_last   CONSTANT VARCHAR2(100) := '�ŏI�ڋq�R�[�h';
    -- ���ЃR�[�h�P
    cv_i_ext_ven_tasya_cd01   CONSTANT VARCHAR2(100) := '���ЃR�[�h�P';
    -- ���Б䐔�P
    cv_i_ext_ven_tasya_ds01   CONSTANT VARCHAR2(100) := '���Б䐔�P';
    -- ���ЃR�[�h�Q
    cv_i_ext_ven_tasya_cd02   CONSTANT VARCHAR2(100) := '���ЃR�[�h�Q';
    -- ���Б䐔�Q
    cv_i_ext_ven_tasya_ds02   CONSTANT VARCHAR2(100) := '���Б䐔�Q';
    -- ���ЃR�[�h�R
    cv_i_ext_ven_tasya_cd03   CONSTANT VARCHAR2(100) := '���ЃR�[�h�R';
    -- ���Б䐔�R
    cv_i_ext_ven_tasya_ds03   CONSTANT VARCHAR2(100) := '���Б䐔�R';
    -- ���ЃR�[�h�S
    cv_i_ext_ven_tasya_cd04   CONSTANT VARCHAR2(100) := '���ЃR�[�h�S';
    -- ���Б䐔�S
    cv_i_ext_ven_tasya_ds04   CONSTANT VARCHAR2(100) := '���Б䐔�S';
    -- ���ЃR�[�h�T
    cv_i_ext_ven_tasya_cd05   CONSTANT VARCHAR2(100) := '���ЃR�[�h�T';
    -- ���Б䐔�T
    cv_i_ext_ven_tasya_ds05   CONSTANT VARCHAR2(100) := '���Б䐔�T';
    -- �p���t���O
    cv_i_ext_ven_haiki_flg    CONSTANT VARCHAR2(100) := '�p���t���O';
    -- ���Y�敪
    cv_i_ext_ven_sisan_kbn    CONSTANT VARCHAR2(100) := '���Y�敪';
    -- �w�����t
    cv_i_ext_ven_kobai_ymd    CONSTANT VARCHAR2(100) := '�w�����t';
    -- �w�����z
    cv_i_ext_ven_kobai_kg     CONSTANT VARCHAR2(100) := '�w�����z';
    -- ���S�ݒu�
    cv_i_ext_safty_level      CONSTANT VARCHAR2(100) := '���S�ݒu�';
    -- ���[�X�敪
    cv_i_ext_lease_kbn        CONSTANT VARCHAR2(100) := '���[�X�敪';
    -- �挎���ݒu��ڋq�R�[�h
    cv_i_ext_last_inst_cust_code  CONSTANT VARCHAR2(100) := '�挎���ݒu��ڋq�R�[�h';
    -- �挎���@����
    cv_i_ext_last_jotai_kbn   CONSTANT VARCHAR2(100) := '�挎���@����';
    -- �挎���N��
    cv_i_ext_last_year_month  CONSTANT VARCHAR2(100) := '�挎���N��';
    -- �J�E���^�[No.
    cv_count_no               CONSTANT VARCHAR2(100) := 'COUNT_NO';
    -- �n��R�[�h
    cv_chiku_cd               CONSTANT VARCHAR2(100) := 'CHIKU_CD';
    -- ��Ɖ�ЃR�[�h
    cv_sagyougaisya_cd        CONSTANT VARCHAR2(100) := 'SAGYOUGAISYA_CD'; 
    -- ���Ə��R�[�h
    cv_jigyousyo_cd           CONSTANT VARCHAR2(100) := 'JIGYOUSYO_CD';
    -- �ŏI��Ɠ`�[No.
    cv_den_no                 CONSTANT VARCHAR2(100) := 'DEN_NO';
    -- �ŏI��Ƌ敪
    cv_job_kbn                CONSTANT VARCHAR2(100) := 'JOB_KBN';
    -- �ŏI��Ɛi��
    cv_sintyoku_kbn           CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN';
    -- �ŏI��Ɗ����\���
    cv_yotei_dt               CONSTANT VARCHAR2(100) := 'YOTEI_DT';
    -- �ŏI��Ɗ�����
    cv_kanryo_dt              CONSTANT VARCHAR2(100) := 'KANRYO_DT';
    -- �ŏI�������e
    cv_sagyo_level            CONSTANT VARCHAR2(100) := 'SAGYO_LEVEL';
    -- �ŏI�ݒu�`�[No.
    cv_den_no2                CONSTANT VARCHAR2(100) := 'DEN_NO2';
    -- �ŏI�ݒu�敪
    cv_job_kbn2               CONSTANT VARCHAR2(100) := 'JOB_KBN2';
    -- �ŏI�ݒu�i��
    cv_sintyoku_kbn2          CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN2';
    -- �@����1�i�ғ���ԁj
    cv_jotai_kbn1             CONSTANT VARCHAR2(100) := 'JOTAI_KBN1';
    -- �@����2�i��ԏڍׁj
    cv_jotai_kbn2             CONSTANT VARCHAR2(100) := 'JOTAI_KBN2';
    -- �@����2�i�p�����j
    cv_jotai_kbn3             CONSTANT VARCHAR2(100) := 'JOTAI_KBN3';
    -- ���ɓ�
    cv_nyuko_dt               CONSTANT VARCHAR2(100) := 'NYUKO_DT';
    -- ���g��ЃR�[�h
    cv_hikisakigaisya_cd      CONSTANT VARCHAR2(100) := 'HIKISAKIGAISYA_CD';
    -- ���g���Ə��R�[�h
    cv_hikisakijigyosyo_cd    CONSTANT VARCHAR2(100) := 'HIKISAKIJIGYOSYO_CD';
    -- �ݒu��S���Җ�
    cv_setti_tanto            CONSTANT VARCHAR2(100) := 'SETTI_TANTO';
    -- �ݒu��tel1
    cv_setti_tel1             CONSTANT VARCHAR2(100) := 'SETTI_TEL1';
    -- �ݒu��tel2
    cv_setti_tel2             CONSTANT VARCHAR2(100) := 'SETTI_TEL2';
    -- �ݒu��tel3
    cv_setti_tel3             CONSTANT VARCHAR2(100) := 'SETTI_TEL3';
    -- �p�����ٓ�
    cv_haikikessai_dt         CONSTANT VARCHAR2(100) := 'HAIKIKESSAI_DT';
    -- �]���p���Ǝ�
    cv_tenhai_tanto           CONSTANT VARCHAR2(100) := 'TENHAI_TANTO';
    -- �]���p���`�[��
    cv_tenhai_den_no          CONSTANT VARCHAR2(100) := 'TENHAI_DEN_NO';
    -- ���L��
    cv_syoyu_cd               CONSTANT VARCHAR2(100) := 'SYOYU_CD';
    -- �]���p���󋵃t���O
    cv_tenhai_flg             CONSTANT VARCHAR2(100) := 'TENHAI_FLG';
    -- �]�������敪
    cv_kanryo_kbn             CONSTANT VARCHAR2(100) := 'KANRYO_KBN';
    -- �폜�t���O
    cv_sakujo_flg             CONSTANT VARCHAR2(100) := 'SAKUJO_FLG';
    -- �ŏI�ڋq�R�[�h
    cv_ven_kyaku_last         CONSTANT VARCHAR2(100) := 'VEN_KYAKU_LAST';
    -- ���ЃR�[�h�P
    cv_ven_tasya_cd01         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD01';
    -- ���Б䐔�P
    cv_ven_tasya_daisu01      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU01';
    -- ���ЃR�[�h2
    cv_ven_tasya_cd02         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD02';
    -- ���Б䐔2
    cv_ven_tasya_daisu02      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU02';
    -- ���ЃR�[�h3
    cv_ven_tasya_cd03         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD03';
    -- ���Б䐔3
    cv_ven_tasya_daisu03      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU03';
    -- ���ЃR�[�h4
    cv_ven_tasya_cd04         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD04';
    -- ���Б䐔4
    cv_ven_tasya_daisu04      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU04';
    -- ���ЃR�[�h5
    cv_ven_tasya_cd05         CONSTANT VARCHAR2(100) := 'VEN_TASYA_CD05';
    -- ���Б䐔5
    cv_ven_tasya_daisu05      CONSTANT VARCHAR2(100) := 'VEN_TASYA_DAISU05';
    -- �p���t���O
    cv_ven_haiki_flg          CONSTANT VARCHAR2(100) := 'VEN_HAIKI_FLG';
    -- ���Y�敪
    cv_ven_sisan_kbn          CONSTANT VARCHAR2(100) := 'VEN_SISAN_KBN';
    -- �w�����t
    cv_ven_kobai_ymd          CONSTANT VARCHAR2(100) := 'VEN_KOBAI_YMD';
    -- �w�����z
    cv_ven_kobai_kg           CONSTANT VARCHAR2(100) := 'VEN_KOBAI_KG';
    -- ���S�ݒu�
    cv_safty_level            CONSTANT VARCHAR2(100) := 'SAFTY_LEVEL';
    -- ���[�X�敪
    cv_lease_kbn              CONSTANT VARCHAR2(100) := 'LEASE_KBN';
    -- �挎���ݒu��ڋq�R�[�h
    cv_last_inst_cust_code    CONSTANT VARCHAR2(100) := 'LAST_INST_CUST_CODE';
    -- �挎���@����
    cv_last_jotai_kbn         CONSTANT VARCHAR2(100) := 'LAST_JOTAI_KBN';
    -- �挎���N��
    cv_last_year_month        CONSTANT VARCHAR2(100) := 'LAST_YEAR_MONTH';
--
    -- INV�H��ԕi�q�֐�R�[�h
    cv_mfg_fctory_name        CONSTANT VARCHAR2(100) :='�uINV�H��ԕi�q�֐�R�[�h�v';
    
--
    -- *** ���[�J���ϐ� ***
    -- �Ɩ�������
    ld_process_date           DATE;
    -- �J�E���g��
    ln_cnt                    NUMBER;
    -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W�i�[�p
    lv_noprm_msg              VARCHAR2(5000);  
    -- �v���t�@�C���l�擾���s�� �g�[�N���l�i�[�p
    lv_tkn_value              VARCHAR2(1000);
    -- �o�^�p�g�D�R�[�h
    lv_inv_mst_org_code       VARCHAR2(100);
    -- �o�^�p���ؑg�D�R�[�h
    lv_vld_org_code           VARCHAR2(100);
    -- �o�^�p�Z�O�����g
    lv_bukken_item            VARCHAR2(100);
    -- �X�e�[�^�X��
    lv_status_name            VARCHAR2(100);
    -- �擾�f�[�^���b�Z�[�W�o�͗p
    lv_msg                    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_mfg_fctory_code_cur
    IS
      SELECT flvv.lookup_code mfg_fctory_code                         -- �R�[�h
      FROM   fnd_lookup_values_vl  flvv                               -- �Q�ƃ^�C�v
      WHERE  flvv.lookup_type      = cv_xxcoi_mfg_fctory_type
        AND  flvv.enabled_flag     = 'Y'
        AND  NVL(flvv.start_date_active, ld_process_date) <= ld_process_date
        AND  NVL(flvv.end_date_active,   ld_process_date) >= ld_process_date
      ;
    -- *** ���[�J���E���R�[�h ***
    l_mfg_fctory_code_rec      get_mfg_fctory_code_cur%ROWTYPE;

  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===========================
    -- �V�X�e�����t�擾���� 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- �擾�����V�X�e�����t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =================================
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o�� 
    -- =================================
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name           --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_01             --���b�Z�[�W�R�[�h
                      );
    --���b�Z�[�W�o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- =====================
    -- �Ɩ��������t�擾���� 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- �擾�����Ɩ��������t�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- �Ɩ��������t�擾�Ɏ��s�����ꍇ
    IF (od_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_02             --���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    ld_process_date :=TRUNC(od_process_date);
--
    -- =====================
    -- AR��v���ԃN���[�Y�`�F�b�N 
    -- =====================
    /* 2009.08.28 K.Satomura 0001205�Ή� START */
    --gv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
    --                   id_standard_date => ld_process_date
    --                 );
    --IF (gv_chk_rslt = cv_true) THEN
    --  gv_chk_rslt_flag := 'N';
    --ELSE
    --  gv_chk_rslt_flag := 'C';
    --END IF;
    /* 2009.08.28 K.Satomura 0001205�Ή� END */
    -- ====================
    -- �ϐ����������� 
    -- ====================
    lv_tkn_value := NULL;
--
    -- =======================
    -- �v���t�@�C���l�擾���� 
    -- =======================
    FND_PROFILE.GET(
                    cv_inv_mst_org_code
                   ,lv_inv_mst_org_code
                   ); -- �݌Ƀ}�X�^�g�D
    FND_PROFILE.GET(
                    cv_vld_org_code
                   ,lv_vld_org_code
                   ); -- ���ؑg�D
    FND_PROFILE.GET(
                    cv_bukken_item
                   ,lv_bukken_item
                   ); -- �����p�i��
    FND_PROFILE.GET(
                    cv_withdraw_base_code
                   ,gv_withdraw_base_code
                   ); -- ���g���_�R�[�h
    FND_PROFILE.GET(
                    cv_jyki_withdraw_base_code
                   ,gv_jyki_withdraw_base_code
                   ); -- �Y����g���_�R�[�h
    -- *** DEBUG_LOG ***
    -- �擾�����v���t�@�C���l�����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10)               ||
                 cv_debug_msg6  || lv_inv_mst_org_code   || CHR(10) ||
                 cv_debug_msg7  || lv_vld_org_code       || CHR(10) ||
                 cv_debug_msg8  || lv_bukken_item        || CHR(10) ||
                 cv_debug_msg9  || gv_withdraw_base_code || CHR(10) ||
                 cv_debug_msg10 || gv_jyki_withdraw_base_code || CHR(10) ||
                 ''
    );
--
    -- �v���t�@�C���l�擾�Ɏ��s�����ꍇ
    -- �݌Ƀ}�X�^�g�D�擾���s��
    IF (lv_inv_mst_org_code IS NULL) THEN
      lv_tkn_value := cv_inv_mst_org_code;
    -- ���ؑg�D�擾���s��
    ELSIF (lv_vld_org_code IS NULL) THEN
      lv_tkn_value := cv_vld_org_code;
    -- �����p�i��
    ELSIF (lv_bukken_item IS NULL) THEN
      lv_tkn_value := cv_bukken_item;
    END IF;
    -- �G���[���b�Z�[�W�擾
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_03             --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_nm               --�g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                 --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- ===========================
    -- �݌Ƀ}�X�^�̑g�DID�擾���� 
    -- ===========================
    BEGIN
      SELECT  mp.organization_id                                      -- �g�DID
      INTO    gt_inv_mst_org_id
      FROM    mtl_parameters  mp                                      -- �݌ɑg�D�}�X�^
      WHERE   mp.organization_code = lv_inv_mst_org_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_info       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_inv_mst_org_code          -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_info       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_inv_mst_org_code          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- �݌Ƀ}�X�^�̌��ؑg�DID�擾���� 
    -- ===============================
    BEGIN
      SELECT  mp.organization_id                                        -- �g�DID
      INTO    gt_vld_org_id
      FROM    mtl_parameters  mp                                        -- �݌ɑg�D�}�X�^
      WHERE   mp.organization_code = lv_vld_org_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_vld        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_vld_org_code              -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_parameters_vld        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_organization          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_vld_org_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- �����p�i��ID�擾���� 
    -- ====================
    BEGIN
      SELECT msib.inventory_item_id                                     -- �i��ID
      INTO   gt_bukken_item_id
      FROM   mtl_system_items_b msib                                    -- �i�ڃ}�X�^
      WHERE  msib.segment1 = lv_bukken_item
        AND  msib.organization_id = gt_inv_mst_org_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_06             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_system_items_id       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_segment               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_bukken_item               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_organization_id       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gt_inv_mst_org_id            -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_07             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mtl_system_items_id       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_segment               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_bukken_item               -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_organization_id       -- �g�[�N���R�[�h3
                       ,iv_token_value3 => gt_inv_mst_org_id            -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_errmsg                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--    
    -- =================================
    -- �C���X�^���X�X�e�[�^�XID�擾���� 
    -- =================================
    -- ������
    lv_status_name   := '';
    -- �u�ғ����v
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_1
                          ,ld_process_date);
      SELECT cis.instance_status_id                                     -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_1
      FROM   csi_instance_statuses cis                                  -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name01           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name01           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ������
    lv_status_name   := '';
    -- �u�g�p�v
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_2
                          ,ld_process_date);
      SELECT cis.instance_status_id                                     -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_2
      FROM   csi_instance_statuses cis                                  -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name02           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name02           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ������
    lv_status_name   := '';
    -- �u�������v
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_3
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_3
      FROM   csi_instance_statuses cis                                -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name03           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name03           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ������
    lv_status_name   := '';
    -- �u�p���葱���v
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_4
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_4
      FROM   csi_instance_statuses cis                                -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name04           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name04           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ������
    lv_status_name   := '';
    -- �u�p�������ρv
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_5
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_5
      FROM   csi_instance_statuses cis                                -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, ld_process_date))
    ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name05           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name05           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ������
    lv_status_name   := '';
    -- �u�����폜�ρv
    BEGIN
      lv_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_6
                          ,ld_process_date);
      SELECT cis.instance_status_id                                   -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_6
      FROM   csi_instance_statuses cis                                -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lv_status_name
        AND  ld_process_date 
               BETWEEN TRUNC(NVL(cis.start_date_active, ld_process_date)) 
                 AND TRUNC(NVL(cis.end_date_active, ld_process_date))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_08             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name06           -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_09             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_instance_statuses     -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_status_name           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_statuses_name06           -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- ����^�C�vID�擾���� 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id                                    -- �g�����U�N�V�����^�C�vID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                          -- ����^�C�v
      WHERE  ctt.source_transaction_type  = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_types             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_11             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_txn_types             -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_src_transaction_type      -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- �ǉ�����ID�擾���� 
    -- ====================
    -- ������
    gr_ext_attribs_id_rec := NULL;
--
    -- �ǉ�����ID(�J�E���^�[No.)
    gr_ext_attribs_id_rec.count_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_count_no
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.count_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_count_no            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_count_no                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�n��R�[�h)
    gr_ext_attribs_id_rec.chiku_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_chiku_cd
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.chiku_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_chiku_cd            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_chiku_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(��Ɖ�ЃR�[�h)
    gr_ext_attribs_id_rec.sagyougaisya_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                cv_sagyougaisya_cd
                                               ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sagyougaisya_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sagyougaisya_cd     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sagyougaisya_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Ə��R�[�h)
    gr_ext_attribs_id_rec.jigyousyo_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_jigyousyo_cd
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jigyousyo_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jigyousyo_cd        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jigyousyo_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɠ`�[No.)
    gr_ext_attribs_id_rec.den_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                       cv_den_no
                                      ,ld_process_date);
    IF (gr_ext_attribs_id_rec.den_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_den_no              -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_den_no                    -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ƌ敪)
    gr_ext_attribs_id_rec.job_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                        cv_job_kbn
                                       ,ld_process_date);
    IF (gr_ext_attribs_id_rec.job_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_job_kbn             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_job_kbn                   -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɛi��)
    gr_ext_attribs_id_rec.sintyoku_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_sintyoku_kbn
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sintyoku_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sintyoku_kbn        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sintyoku_kbn              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɗ����\���)
    gr_ext_attribs_id_rec.yotei_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_yotei_dt
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.yotei_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_yotei_dt            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_yotei_dt                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI��Ɗ�����)
    gr_ext_attribs_id_rec.kanryo_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_kanryo_dt
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.kanryo_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_kanryo_dt           -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_kanryo_dt                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�������e)
    gr_ext_attribs_id_rec.sagyo_level := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                            cv_sagyo_level
                                           ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sagyo_level IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sagyo_level         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sagyo_level               -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ŏI�ݒu�`�[No.
    gr_ext_attribs_id_rec.den_no2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                        cv_den_no2
                                       ,ld_process_date);
    IF (gr_ext_attribs_id_rec.den_no2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_den_no2             -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_den_no2                   -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�ݒu�敪)
    gr_ext_attribs_id_rec.job_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_job_kbn2
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.job_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_job_kbn2            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_job_kbn2                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�ݒu�i��)
    gr_ext_attribs_id_rec.sintyoku_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_sintyoku_kbn2
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sintyoku_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sintyoku_kbn2       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sintyoku_kbn2             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�@����1�i�ғ���ԁj)
    gr_ext_attribs_id_rec.jotai_kbn1 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn1
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn1 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn1          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jotai_kbn1                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�@����2�i��ԏڍׁj)
    gr_ext_attribs_id_rec.jotai_kbn2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn2
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn2          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jotai_kbn2                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�@����3�i�p�����j)
    gr_ext_attribs_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_jotai_kbn3
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.jotai_kbn3 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_jotai_kbn3          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_jotai_kbn3                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ɓ�)
    gr_ext_attribs_id_rec.nyuko_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_nyuko_dt
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.nyuko_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_nyuko_dt            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_nyuko_dt                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���g��ЃR�[�h)
    gr_ext_attribs_id_rec.hikisakigaisya_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                  cv_hikisakigaisya_cd
                                                 ,ld_process_date);
    IF (gr_ext_attribs_id_rec.hikisakigaisya_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_hikisakicmy_cd      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_hikisakigaisya_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���g���Ə��R�[�h)
    gr_ext_attribs_id_rec.hikisakijigyosyo_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                    cv_hikisakijigyosyo_cd
                                                   ,ld_process_date);
    IF (gr_ext_attribs_id_rec.hikisakijigyosyo_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_hikisakilct_cd      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_hikisakijigyosyo_cd       -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��S���Җ�)
    gr_ext_attribs_id_rec.setti_tanto := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tanto
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tanto IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tanto         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tanto               -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��tel1)
    gr_ext_attribs_id_rec.setti_tel1 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel1
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel1 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tel1          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tel1                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��tel2)
    gr_ext_attribs_id_rec.setti_tel2 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel2
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel2 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tel2          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tel2                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ݒu��tel3)
    gr_ext_attribs_id_rec.setti_tel3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_setti_tel3
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.setti_tel3 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_setti_tel3          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_setti_tel3                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�p�����ٓ�)
    gr_ext_attribs_id_rec.haikikessai_dt := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_haikikessai_dt
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.haikikessai_dt IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_haikikessai_dt      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_haikikessai_dt            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]���p���Ǝ�)
    gr_ext_attribs_id_rec.tenhai_tanto := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                             cv_tenhai_tanto
                                            ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_tanto IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_tenhai_tanto        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_tenhai_tanto              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]���p���`�[��)
    gr_ext_attribs_id_rec.tenhai_den_no := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_tenhai_den_no
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_den_no IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_tenhai_den_no       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_tenhai_den_no             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���L��)
    gr_ext_attribs_id_rec.syoyu_cd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                         cv_syoyu_cd
                                        ,ld_process_date);
    IF (gr_ext_attribs_id_rec.syoyu_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_syoyu_cd            -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_syoyu_cd                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]���p���󋵃t���O)
    gr_ext_attribs_id_rec.tenhai_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_tenhai_flg
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.tenhai_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_tenhai_flg          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_tenhai_flg                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�]�������敪)
    gr_ext_attribs_id_rec.kanryo_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_kanryo_kbn
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.kanryo_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_kanryo_kbn          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_kanryo_kbn                  -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�폜�t���O)
    gr_ext_attribs_id_rec.sakujo_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_sakujo_flg
                                          ,ld_process_date);
    IF (gr_ext_attribs_id_rec.sakujo_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_sakujo_flg          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_sakujo_flg                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�ŏI�ڋq�R�[�h)
    gr_ext_attribs_id_rec.ven_kyaku_last := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_kyaku_last
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kyaku_last IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_kyaku_last      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_kyaku_last            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h�P)
    gr_ext_attribs_id_rec.ven_tasya_cd01 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd01
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd01      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd01            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔�P)
    gr_ext_attribs_id_rec.ven_tasya_daisu01 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu01
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds01      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu01         -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h2)
    gr_ext_attribs_id_rec.ven_tasya_cd02 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd02
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd02 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd02      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd02                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔2)
    gr_ext_attribs_id_rec.ven_tasya_daisu02 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu02
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu02 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds02      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu02         -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h3)
    gr_ext_attribs_id_rec.ven_tasya_cd03 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd03
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd03 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd03      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd03            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔3)
    gr_ext_attribs_id_rec.ven_tasya_daisu03 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu03
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu03 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds03      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu03         -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h4)
    gr_ext_attribs_id_rec.ven_tasya_cd04 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd04
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd04 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd04      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd04                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔4)
    gr_ext_attribs_id_rec.ven_tasya_daisu04 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu04
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu04 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds04          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu04             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���ЃR�[�h5)
    gr_ext_attribs_id_rec.ven_tasya_cd05 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_cd05
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_cd05 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_cd05      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_cd05                -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Б䐔5)
    gr_ext_attribs_id_rec.ven_tasya_daisu05 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                               cv_ven_tasya_daisu05
                                              ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_tasya_daisu01 IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_tasya_ds05          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_tasya_daisu05             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�p���t���O)
    gr_ext_attribs_id_rec.ven_haiki_flg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_haiki_flg
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_haiki_flg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_haiki_flg       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_haiki_flg             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���Y�敪)
    gr_ext_attribs_id_rec.ven_sisan_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_sisan_kbn
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_sisan_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_sisan_kbn       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_sisan_kbn             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�w�����t)
    gr_ext_attribs_id_rec.ven_kobai_ymd := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_kobai_ymd
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kobai_ymd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_kobai_ymd       -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_kobai_ymd             -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�w�����z)
    gr_ext_attribs_id_rec.ven_kobai_kg := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                              cv_ven_kobai_kg
                                             ,ld_process_date);
    IF (gr_ext_attribs_id_rec.ven_kobai_kg IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_ven_kobai_kg        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_ven_kobai_kg              -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���S�ݒu�)
    gr_ext_attribs_id_rec.safty_level := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                            cv_safty_level
                                           ,ld_process_date);
    IF (gr_ext_attribs_id_rec.safty_level IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_safty_level         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_safty_level               -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(���[�X�敪)
    gr_ext_attribs_id_rec.lease_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_lease_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.lease_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_lease_kbn           -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_lease_kbn                 -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�挎���ݒu��ڋq�R�[�h)
    gr_ext_attribs_id_rec.last_inst_cust_code := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_inst_cust_code
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_inst_cust_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_last_inst_cust_code -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_last_inst_cust_code       -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�挎���@����)
    gr_ext_attribs_id_rec.last_jotai_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_jotai_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_jotai_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_last_jotai_kbn      -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_last_jotai_kbn            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ǉ�����ID(�挎���N��)
    gr_ext_attribs_id_rec.last_year_month := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_last_year_month
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.last_year_month IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_12             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_attribute_id_info         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_i_ext_last_year_month     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- �g�[�N���R�[�h3
                     ,iv_token_value3 => cv_last_year_month           -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �Q�ƃ^�C�v�uINV�H��ԕi�q�֐�R�[�h�v�擾 
    -- =========================================
    ln_cnt := 0;
    OPEN get_mfg_fctory_code_cur;
--
    <<get_data_loop>>
    LOOP
      BEGIN
        FETCH get_mfg_fctory_code_cur INTO l_mfg_fctory_code_rec;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mfg_fctory_code_info      -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END;
      EXIT WHEN get_mfg_fctory_code_cur%NOTFOUND
      OR get_mfg_fctory_code_cur%ROWCOUNT = 0;
      ln_cnt := ln_cnt + 1;
      gt_mfg_fctory_code_tab(ln_cnt).mfg_fctory_code := l_mfg_fctory_code_rec.mfg_fctory_code;
    END LOOP;
    CLOSE get_mfg_fctory_code_cur;
    IF (ln_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_13             -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_mfg_fctory_code_info      -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_lookup_type_name      -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_mfg_fctory_name           -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--    
    -- ===================
    -- ���g���_���擾 
    -- ===================
--
    IF (gv_withdraw_base_code IS NOT NULL) THEN
      BEGIN
        SELECT casv.cust_account_id                                     -- �A�J�E���gID
              ,casv.party_site_id                                       -- �p�[�e�B�T�C�gID
              ,casv.party_id                                            -- �p�[�e�BID
              ,casv.area_code                                           -- �n��R�[�h
        INTO   gn_account_id
              ,gn_party_site_id
              ,gn_party_id
              ,gv_area_code
        FROM   xxcso_cust_acct_sites_v casv                             -- �ڋq�}�X�^�T�C�g�r���[
        WHERE  casv.account_number    = gv_withdraw_base_code
          AND  casv.account_status    = cv_active
          AND  casv.acct_site_status  = cv_active
          AND  casv.party_status      = cv_active
          AND  casv.party_site_status = cv_active
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_14             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_acct_sites_info      -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_cust_account_number       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_base_value            -- �g�[�N���R�[�h3
                         ,iv_token_value3 => gv_withdraw_base_code        -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_15             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_acct_sites_info      -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_cust_account_number       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_base_value            -- �g�[�N���R�[�h3
                         ,iv_token_value3 => gv_withdraw_base_code        -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_errmsg                -- �g�[�N���R�[�h4
                         ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--    
    -- ===================
    -- �Y����g���_���擾 
    -- ===================
--
    IF (gv_jyki_withdraw_base_code IS NOT NULL) THEN
      BEGIN
        SELECT casv.cust_account_id                                     -- �A�J�E���gID
              ,casv.party_site_id                                       -- �p�[�e�B�T�C�gID
              ,casv.party_id                                            -- �p�[�e�BID
              ,casv.area_code                                           -- �n��R�[�h
        INTO   gn_jyki_account_id
              ,gn_jyki_party_site_id
              ,gn_jyki_party_id
              ,gv_jyki_area_code
        FROM   xxcso_cust_acct_sites_v casv                             -- �ڋq�}�X�^�T�C�g�r���[
        WHERE  casv.account_number    = gv_jyki_withdraw_base_code
          AND  casv.account_status    = cv_active
          AND  casv.acct_site_status  = cv_active
          AND  casv.party_status      = cv_active
          AND  casv.party_site_status = cv_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_14             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_acct_sites_info1     -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_cust_account_number       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_base_value            -- �g�[�N���R�[�h3
                         ,iv_token_value3 => gv_jyki_withdraw_base_code   -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_15             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_acct_sites_info1     -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_item                  -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_cust_account_number       -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_base_value            -- �g�[�N���R�[�h3
                         ,iv_token_value3 => gv_jyki_withdraw_base_code   -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_errmsg                -- �g�[�N���R�[�h4
                         ,iv_token_value4 => SQLERRM                      -- �g�[�N���l4
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
   * Procedure Name   : update_in_work_data
   * Description      : ��ƃf�[�^�e�[�u���̕����t���O�X�V���� (A-9)
   ***********************************************************************************/
  PROCEDURE update_in_work_data(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)�����}�X�^���
    ,id_process_date         IN     DATE                    -- �Ɩ��������t
    /* 2009.06.01 K.Satomura T1_1107�Ή� START */
    ,iv_skip_flag            IN     VARCHAR2                -- �X�L�b�v�t���O
    /* 2009.06.01 K.Satomura T1_1107�Ή� END */
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_in_work_data'; -- �v���O������
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
    cn_work_kbn5               CONSTANT NUMBER          := 5;                -- ���g
    cv_kbn1                    CONSTANT VARCHAR2(1)     := '1';
    cv_no                      CONSTANT VARCHAR2(1)     := 'N';
    cv_yes                     CONSTANT VARCHAR2(1)     := 'Y';
    cv_update_process          CONSTANT VARCHAR2(100)   := '�X�V';
    cv_in_work_info            CONSTANT VARCHAR2(100)   := '��ƃf�[�^�e�[�u��';
--
    -- *** ���[�J���ϐ� ***
    ln_seq_no                  NUMBER;                  -- �V�[�P���X�ԍ�
    ln_slip_num                NUMBER;                  -- �`�[No.
    ln_slip_branch_num         NUMBER;                  -- �`�[�}��
    ln_line_number             NUMBER;                  -- �s��
    ln_job_kbn                 NUMBER;                  -- ��Ƌ敪
    ln_rock_slip_num           NUMBER;                  -- ���b�N�p�`�[No.
    ln_rock_slip_branch_num    NUMBER;                  -- ���b�N�p�`�[�}��
    ln_rock_line_number        NUMBER;                  -- ���b�N�p�s��
    lv_install_code            VARCHAR2(10);            -- �����R�[�h
    lv_install_code1           VARCHAR2(10);            -- �����R�[�h�P
    lv_install_code2           VARCHAR2(10);            -- �����R�[�h�Q
    lv_account_num1            VARCHAR2(10);            -- �ڋq�R�[�h�P
    lv_account_num2            VARCHAR2(10);            -- �ڋq�R�[�h�Q
--
    -- *** ���[�J����O ***
    update_error_expt          EXCEPTION;
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �f�[�^�̊i�[
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_number        := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
--
    -- ��ƃf�[�^���o
    BEGIN
--
      SELECT xiwd.slip_no                                             -- �`�[No.
            ,xiwd.slip_branch_no                                      -- �`�[�}��
            ,xiwd.line_number                                         -- �s�ԍ�
      INTO   ln_rock_slip_num
            ,ln_rock_slip_branch_num
            ,ln_rock_line_number
      FROM   xxcso_in_work_data xiwd                                  -- ��ƃf�[�^
      WHERE  xiwd.seq_no         = ln_seq_no
        AND  xiwd.slip_no        = ln_slip_num
        AND  xiwd.slip_branch_no = ln_slip_branch_num
        AND  xiwd.line_number    = ln_line_number
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_in_work_info               -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_number)       -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_in_work_info               -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_number)       -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
    BEGIN
      /* 2009.06.01 K.Satomura T1_1107�Ή� START */
      IF (NVL(iv_skip_flag, cv_no) = cv_yes) THEN
        UPDATE xxcso_in_work_data xiw -- ��ƃf�[�^
        /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
        --SET    xiw.process_no_target_flag = cv_yes -- ��ƈ˗������ΏۊO�t���O
        SET    xiw.install1_process_no_target_flg = DECODE(lv_install_code
                                                          ,NVL(lv_install_code1, ' '), cv_yes
                                                          ,xiw.install1_process_no_target_flg
                                                          ) -- �����P��ƈ˗������ΏۊO�t���O
              ,xiw.install2_process_no_target_flg = DECODE(lv_install_code
                                                          ,NVL(lv_install_code2, ' '), cv_yes
                                                          ,xiw.install2_process_no_target_flg
                                                          ) -- �����Q��ƈ˗������ΏۊO�t���O
        /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
              ,xiw.last_updated_by        = cn_last_updated_by
              ,xiw.last_update_date       = cd_last_update_date
              ,xiw.last_update_login      = cn_last_update_login
              ,xiw.request_id             = cn_request_id
              ,xiw.program_application_id = cn_program_application_id
              ,xiw.program_id             = cn_program_id
              ,xiw.program_update_date    = cd_program_update_date
        WHERE  xiw.seq_no         = ln_seq_no
        AND    xiw.slip_no        = ln_slip_num
        AND    xiw.slip_branch_no = ln_slip_branch_num
        AND    xiw.line_number    = ln_line_number
        ;
        --
      ELSE
      /* 2009.06.01 K.Satomura T1_1107�Ή� END */
        -- �����f�[�^�̕����R�[�h����ƃf�[�^�̕����R�[�h�P�Ɠ���̏ꍇ��
        IF (lv_install_code = NVL(lv_install_code1, ' ')) THEN 
--
          -- ==========================================
          -- �����P�����σt���O���uY�D�A�g�ρv�ɍX�V 
          -- ==========================================
          UPDATE xxcso_in_work_data                                        -- ��ƃf�[�^
          SET    install1_processed_flag = cv_yes                         -- �����P�����σt���O
                /* 2009.06.01 K.Satomura T1_1107�Ή� START */
                ,install1_processed_date = id_process_date -- �����P�����ϓ�
                /* 2009.06.01 K.Satomura T1_1107�Ή� END */
                ,last_updated_by         = cn_last_updated_by
                ,last_update_date        = cd_last_update_date
                ,last_update_login       = cn_last_update_login
                ,request_id              = cn_request_id
                ,program_application_id  = cn_program_application_id
                ,program_id              = cn_program_id
                ,program_update_date     = cd_program_update_date
          WHERE  seq_no         = ln_seq_no
            AND  slip_no        = ln_slip_num
            AND  slip_branch_no = ln_slip_branch_num
            AND  line_number    = ln_line_number
          ;
--
        -- �����f�[�^�̕����R�[�h����ƃf�[�^�̕����R�[�h�Q�Ɠ���̏ꍇ��
        ELSE
--
          -- ==========================================
          -- �����Q�����σt���O���uY�D�A�g�ρv�ɍX�V 
          -- ==========================================
          -- ��Ƌ敪���u5.���g�v�̏ꍇ�̋x�~�����σt���O�̍X�V��'1'(�x�~)
          UPDATE xxcso_in_work_data                                          -- ��ƃf�[�^
          SET    install2_processed_flag = cv_yes                           -- �����Q�����σt���O
                ,suspend_processed_flag  = (CASE
                                              WHEN job_kbn = cn_work_kbn5 THEN -- �x�~�����σt���O
                                                cv_kbn1
                                              ELSE
                                                suspend_processed_flag
                                            END)
                /* 2009.06.01 K.Satomura T1_1107�Ή� START */
                ,install2_processed_date = id_process_date -- �����Q�����ϓ�
                /* 2009.06.01 K.Satomura T1_1107�Ή� END */
                ,last_updated_by         = cn_last_updated_by
                ,last_update_date        = cd_last_update_date
                ,last_update_login       = cn_last_update_login
                ,request_id              = cn_request_id
                ,program_application_id  = cn_program_application_id
                ,program_id              = cn_program_id
                ,program_update_date     = cd_program_update_date
          WHERE  seq_no         = ln_seq_no
            AND  slip_no        = ln_slip_num
            AND  slip_branch_no = ln_slip_branch_num
            AND  line_number    = ln_line_number
          ;
--
        END IF;
--
      /* 2009.06.01 K.Satomura T1_1107�Ή� START */
      END IF;
      /* 2009.06.01 K.Satomura T1_1107�Ή� END */
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_in_work_info               -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_update_process             -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                       ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                       ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                       ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                       ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2            -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2                -- �g�[�N���l9
                       ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10 => SQLERRM                       -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      -- �X�V���s���[���o�b�N�t���O�̐ݒ�B
      gb_rollback_flg := TRUE;
--      
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �X�V���s���[���o�b�N�t���O�̐ݒ�B
      gb_rollback_flg := TRUE;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_in_work_data;
--
  /**********************************************************************************
   * Procedure Name   : get_item_instances
   * Description      : ������񒊏o (A-4)
   ***********************************************************************************/
  PROCEDURE get_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype          -- (IN)�����}�X�^���
    ,id_process_date         IN     DATE                             -- �Ɩ��������t
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_instances'; -- �v���O������
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
    cn_jon_kbn_1             CONSTANT NUMBER := 1;  -- �V��ݒu
    cn_jon_kbn_2             CONSTANT NUMBER := 2;  -- ����ݒu
    cn_jon_kbn_3             CONSTANT NUMBER := 3;  -- �V����
    cn_jon_kbn_4             CONSTANT NUMBER := 4;  -- ������
    cn_jon_kbn_5             CONSTANT NUMBER := 5;  -- ���g
    /* 2009.05.18 K.Satomura T1_0959�Ή� START */
    cn_jon_kbn_6             CONSTANT NUMBER := 6;  -- �X���ړ�
    /* 2009.05.18 K.Satomura T1_0959�Ή� END */
    cv_flg_n                 CONSTANT VARCHAR2(1) := 'N';  -- �V�Ñ�t���O
    cv_flg_y                 CONSTANT VARCHAR2(1) := 'Y';  -- �V�Ñ�t���O
    cv_csi_item_instances    CONSTANT VARCHAR2(100) := '�C���X�g�[���x�[�X�}�X�^';  
--
    -- *** ���[�J���ϐ� ***
    ln_job_kbn               NUMBER;                    -- ��Ƌ敪
    lv_install_code          VARCHAR2(10);              -- �����R�[�h
    lv_install_code1         VARCHAR2(10);              -- �����R�[�h�P
    lv_install_code2         VARCHAR2(10);              -- �����R�[�h�Q
    lv_external_reference    VARCHAR2(10);              -- �O���Q��
    lv_new_old_flag          csi_item_instances.attribute5%type;  -- �V�Ñ�t���O
    lv_last_po_req_number    csi_item_instances.attribute6%type;  -- �ŏI�����˗��ԍ�
    lv_po_req_number         NUMBER;                    -- �����˗��ԍ�
--
    -- *** ���[�J����O ***
    skip_process_expt       EXCEPTION;
    /* 2009.05.18 K.Satomura T1_1066�Ή� START */
    --/*20090507_mori_T1_0530 START*/
    --shindai_chk_expt       EXCEPTION;
    --/*20090507_mori_T1_0530 END*/
    /* 2009.05.18 K.Satomura T1_1066�Ή� END */
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �f�[�^�̊i�[
    ln_job_kbn        := io_inst_base_data_rec.job_kbn;
    lv_install_code   := io_inst_base_data_rec.install_code;
    lv_install_code1  := io_inst_base_data_rec.install_code1;
    lv_install_code2  := io_inst_base_data_rec.install_code2;
    lv_po_req_number  := io_inst_base_data_rec.po_req_number;
--
    -- ������񒊏o
    BEGIN
      SELECT ciins.external_reference                                 -- �O���Q��
            ,ciins.instance_id                                        -- �C���X�^���XID
            ,ciins.object_version_number                              -- �I�u�W�F�N�g�o�[�W����
            ,ciins.instance_status_id                                 -- �C���X�^���X�X�e�[�^�XID
            ,ciins.attribute5                                         -- �V�Ñ�t���O
            ,ciins.attribute6                                         -- �ŏI�����˗��ԍ�
            /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
            ,ciins.attribute1                                         -- �@��CD
            /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */
      INTO   lv_external_reference
            ,io_inst_base_data_rec.instance_id
            ,io_inst_base_data_rec.object_version1
            ,io_inst_base_data_rec.instance_status_id
            ,lv_new_old_flag
            ,lv_last_po_req_number
            /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
            ,io_inst_base_data_rec.ib_un_number                       -- IB�@��CD
            /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */
      FROM   csi_item_instances ciins                                 -- �����}�X�^
      WHERE  ciins.external_reference = lv_install_code
      ;
      io_inst_base_data_rec.new_old_flg := SUBSTR(lv_new_old_flag, 1, 1);
      /* 2009.05.19 K.Satomur T1_0959,T1_1066�Ή� START */
      --/*20090507_mori_T1_0530 START*/
      ---- ��Ƌ敪���u�V��ݒu�v�A�u�V���ցv�A����ƃf�[�^�̕����R�[�h�P��
      ---- �����f�[�^�̕����R�[�h�ƈ�v�ł���A�V�Ñ�t���O��'Y'�ȊO�ł���ꍇ�A
      ---- ���ɑ��݂���V�Ñ�ȊO�̕������V��Ƃ��ĘA�g����Ă��邽�߁A�G���[�Ƃ���B
      --IF (
      --        (ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
      --    AND (lv_install_code = NVL(lv_install_code1, ' '))
      --    AND (NVL(io_inst_base_data_rec.new_old_flg, cv_flg_n) <> cv_flg_y)
      --   ) THEN
      --  RAISE shindai_chk_expt;
      --END IF;
      --/*20090507_mori_T1_0530 END*/
--
      --IF (lv_po_req_number < lv_last_po_req_number) THEN
      --  RAISE shindai_chk_expt;
      --END IF;
--
      IF (ln_job_kbn IN (cn_jon_kbn_1, cn_jon_kbn_2, cn_jon_kbn_3, cn_jon_kbn_4, cn_jon_kbn_5, cn_jon_kbn_6)) THEN
      -- ��Ƌ敪���P�F�V��ݒu�A�Q�F����ݒu�A�R�F�V���ցA�S�F�����ցA�T�F���g�A�U�F�X���ړ��̏ꍇ
        IF (lv_po_req_number < lv_last_po_req_number) THEN
          /* 2009.06.01 K.Satomura T1_1107�Ή� START */
          update_in_work_data(
             io_inst_base_data_rec => io_inst_base_data_rec -- (IN)�����}�X�^���
            ,id_process_date       => id_process_date       -- �Ɩ��������t
            ,iv_skip_flag          => cv_flg_y              -- �X�L�b�v�t���O
            ,ov_errbuf             => lv_errbuf             -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode            => lv_retcode            -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg             => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          --
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
          /* 2009.06.01 K.Satomura T1_1107�Ή� END */
          RAISE skip_process_expt;
          --
        END IF;
        --
      END IF;
      /* 2009.05.18 K.Satomura T1_0959,T1_1066�Ή� END */
      
      
      /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
      -----------------------------------------------------
      --�@��CD�̐ݒ�
      --1.�V�䕨�������ꕨ��CD��EBS�ɑ��݂��Ȃ��ꍇ
      --     ������̋@S����̕����}�X�^�̋@��CD���g�p
      --2.�V�䕨�������ꕨ��CD��EBS�ɑ��݂���ꍇ
      --     ������̋@S����̕����}�X�^�̋@��CD���g�p
      --3.��L�ȊO�̏ꍇ
      --     ���EBS�C���X�g�[���x�[�X�̋@��CD���g�p
      -----------------------------------------------------
      -- ��Ƌ敪���u�V��ݒu�v�A�u�V���ցv�A����ƃf�[�^�̕����R�[�h�P��
      -- �����f�[�^�̕����R�[�h�ƈ�v�ł���ꍇ
      IF ((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
               AND lv_install_code = NVL(lv_install_code1, ' ')) THEN
        --�P�[�X2
        NULL;
      ELSE
        --�P�[�X3
        io_inst_base_data_rec.un_number := io_inst_base_data_rec.ib_un_number;
      END IF;
      /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */

    EXCEPTION
    /* 2009.05.18 K.Satomura T1_1066�Ή� START */
    --/*20090507_mori_T1_0530 START*/
    --  -- �V��A�V�Ñ�ȊO�̕������V��ݒu�^�V���ւƂ��ĘA�g���ꂽ�ꍇ
    --  WHEN shindai_chk_expt THEN
    --    -- �G���[���b�Z�[�W�쐬
    --    lv_errmsg := xxccp_common_pkg.get_msg(
    --                    iv_application  => cv_app_name                            -- �A�v���P�[�V�����Z�k��
    --                   ,iv_name         => cv_tkn_number_33                       -- ���b�Z�[�W�R�[�h
    --                   ,iv_token_name1  => cv_tkn_slip_num                        -- �g�[�N���R�[�h1
    --                   ,iv_token_value1 => io_inst_base_data_rec.slip_no          -- �g�[�N���l1
    --                   ,iv_token_name2  => cv_tkn_slip_branch_num                 -- �g�[�N���R�[�h2
    --                   ,iv_token_value2 => io_inst_base_data_rec.slip_branch_no   -- �g�[�N���l2
    --                   ,iv_token_name3  => cv_tkn_line_num                        -- �g�[�N���R�[�h3
    --                   ,iv_token_value3 => io_inst_base_data_rec.line_number      -- �g�[�N���l3
    --                   ,iv_token_name4  => cv_tkn_work_kbn                        -- �g�[�N���R�[�h4
    --                   ,iv_token_value4 => io_inst_base_data_rec.job_kbn          -- �g�[�N���l4
    --                   ,iv_token_name5  => cv_tkn_bukken1                         -- �g�[�N���R�[�h5
    --                   ,iv_token_value5 => io_inst_base_data_rec.install_code1    -- �g�[�N���l5
    --                   ,iv_token_name6  => cv_tkn_account_num1                    -- �g�[�N���R�[�h6
    --                   ,iv_token_value6 => io_inst_base_data_rec.account_number1  -- �g�[�N���l6
    --                 );
    --    lv_errbuf := lv_errmsg;
    --    RAISE skip_process_expt;
    --/*20090507_mori_T1_0530 END*/
    /* 2009.05.18 K.Satomura T1_1066�Ή� END */
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        -- ��Ƌ敪���u�V��ݒu�v�A�u�V���ցv�A����ƃf�[�^�̕����R�[�h�P��
        -- �����f�[�^�̕����R�[�h�ƈ�v�ł���ꍇ
        IF ((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_3)
               AND lv_install_code = NVL(lv_install_code1, ' ')) THEN 
          -- �����̐V�K�o�^�t���O���uTRUE�v�ɐݒ�
          gb_insert_process_flg := TRUE;
--        
        ELSE
          -- �������݃`�F�b�N�x��
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_17             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_bukken                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => lv_install_code              -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
        END IF;
      -- �����X�V�`�F�b�N�x��
      WHEN skip_process_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_18             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_bukken                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_install_code              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_last_req_no           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_last_po_req_number        -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_req_no                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => lv_po_req_number             -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_19             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_csi_item_instances        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
  EXCEPTION
    -- *** �X�L�b�v������O�n���h�� ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : insert_item_instances
   * Description      : �����f�[�^�o�^���� (A-5)
   ***********************************************************************************/
  PROCEDURE insert_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)�����}�X�^���
    ,id_process_date         IN     DATE                    -- �Ɩ��������t
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_item_instances'; -- �v���O������
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
    cn_num0                  CONSTANT NUMBER        := 0;
    cn_num1                  CONSTANT NUMBER        := 1;
    cn_num2                  CONSTANT NUMBER        := 2;
    cn_num3                  CONSTANT NUMBER        := 3;
    cn_num4                  CONSTANT NUMBER        := 4;
    cn_num9                  CONSTANT NUMBER        := 9;
    cn_jon_kbn_1             CONSTANT NUMBER        := 1;                   -- �V��ݒu
    cn_jon_kbn_2             CONSTANT NUMBER        := 2;                   -- ����ݒu
    cn_jon_kbn_3             CONSTANT NUMBER        := 3;                   -- �V����
    cn_jon_kbn_4             CONSTANT NUMBER        := 4;                   -- ������
    cn_jon_kbn_5             CONSTANT NUMBER        := 5;                   -- ���g
    cn_api_version           CONSTANT NUMBER        := 1.0;
    cv_kbn0                  CONSTANT NUMBER        := '0';
    cv_kbn1                  CONSTANT VARCHAR2(1)   := '1'; 
    cv_kbn2                  CONSTANT VARCHAR2(1)   := '2'; 
    cv_lease_type_own        CONSTANT VARCHAR2(1)   := '1';                 -- ���Ѓ��[�X
    cv_unit_of_measure       CONSTANT VARCHAR2(10)  := '��';                -- �P�ʂ�
    cv_approved              CONSTANT VARCHAR2(10)  := 'APPROVED';          -- ���F�ς�
    cv_cust_mst_info         CONSTANT VARCHAR2(100) := '�ڋq�}�X�^���';    -- ���o���e
    cv_po_un_numbers_info    CONSTANT VARCHAR2(100) := '���A�ԍ��}�X�^(�@��R�[�h�}�X�^)���';    -- ���o���e
    cv_mfg_fctory_maker_nm   CONSTANT VARCHAR2(100) := '�Q�ƃ^�C�v�̃��[�J�[��';
    cv_xxcso_ib_info_h       CONSTANT VARCHAR2(100) := '�����֘A���ύX�����e�[�u��';    -- ���o���e
    cv_inst_base_insert      CONSTANT VARCHAR2(100) := '�C���X�g�[���x�[�X�}�X�^';
    cv_insert_process        CONSTANT VARCHAR2(100) := '�o�^';
    cv_machinery_status      CONSTANT VARCHAR2(100) := '�����f�[�^���[�N�e�[�u���̋@����'; 
    cv_owner_cmp_info        CONSTANT VARCHAR2(100) := '�Q�ƃ^�C�v�̖{��/�H��敪';
    cv_location_type_code    CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';    -- ���s���Ə��^�C�v
    cv_instance_usage_code   CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE'; -- �C���X�^���X�g�p�R�[�h
    cv_party_source_table    CONSTANT VARCHAR2(100) := 'HZ_PARTIES';        -- �p�[�e�B�\�[�X�e�[�u��
    cv_relatnsh_type_code    CONSTANT VARCHAR2(100) := 'OWNER';             -- �����[�V�����^�C�v
    cv_xxcso1_owner_company  CONSTANT VARCHAR2(100) := 'XXCSO1_OWNER_COMPANY';
    cv_xxcff_owner_company   CONSTANT VARCHAR2(100) := 'XXCFF_OWNER_COMPANY';
    cv_xxcso_csi_maker_code  CONSTANT VARCHAR2(100) := 'XXCSO_CSI_MAKER_CODE';
    cv_mfg_fctory_maker_cd   CONSTANT VARCHAR2(100) := '���[�J�[�R�[�h ';
    cv_flg_no                CONSTANT VARCHAR2(1) := 'N';                 -- �t���ONO
    cv_flg_yes               CONSTANT VARCHAR2(1) := 'Y';                 -- �t���OYES
--
    -- *** ���[�J���ϐ� ***
    ld_date                    DATE;                    -- �Ɩ��������t�i�[�p('yyyymmdd'�`��)
    /*2009.09.03 M.Maruyama 0001192�Ή� START*/
    ld_actual_work_date        DATE;                    -- ����Ɠ�('yyyymmdd'�`��)
    /*2009.09.03 M.Maruyama 0001192�Ή� END*/
    ld_install_date            DATE;                    -- ������
    ln_cnt                     NUMBER;                  -- �J�E���g��
    ln_seq_no                  NUMBER;                  -- �V�[�P���X�ԍ�
    ln_slip_num                NUMBER;                  -- �`�[No.
    ln_slip_branch_num         NUMBER;                  -- �`�[�}��
    ln_line_num                NUMBER;                  -- �s��
    ln_job_kbn                 NUMBER;                  -- ��Ƌ敪
    ln_instance_status_id      NUMBER;                  -- �C���X�^���X�X�e�[�^�XID
    ln_machinery_status1       NUMBER;                  -- �@����1�i�ғ���ԁj
    ln_machinery_status2       NUMBER;                  -- �@����2�i��ԏڍׁj
    ln_machinery_status3       NUMBER;                  -- �@����3�i�p�����j
    ln_account_id              NUMBER;                  -- �A�J�E���gID
    ln_party_site_id           NUMBER;                  -- �p�[�e�B�T�C�gID
    ln_party_id                NUMBER;                  -- �p�[�e�BID
    lv_area_code               VARCHAR2(100);           -- �n��R�[�h
    ln_delete_flag             NUMBER;                  -- �폜�t���O
    ln_machinery_kbn           NUMBER;                  -- �@��敪
    ln_validation_level        NUMBER;                  -- �o���f�[�V�������[�x��
    ln_loop_cnt                NUMBER;                  -- ���[�v�p�ϐ�
    lv_commit                  VARCHAR2(1);             -- �R�~�b�g�t���O
    lv_lease_type              VARCHAR2(240);           -- ���[�X�敪
    lv_install_code            VARCHAR2(10);            -- �����R�[�h
    lv_install_code1           VARCHAR2(10);            -- �����R�[�h�P
    lv_install_code2           VARCHAR2(10);            -- �����R�[�h�Q
    lv_account_num1            VARCHAR2(10);            -- �ڋq�R�[�h�P
    lv_account_num2            VARCHAR2(10);            -- �ڋq�R�[�h�Q
    lv_un_number               VARCHAR2(20);            -- �@��
    lv_install_number          VARCHAR2(20);            -- �@��
    lv_base_code               VARCHAR2(4);             -- ���_�R�[�h
    lv_install_name            VARCHAR2(30);            -- �ݒu�於
    /*20090325_yabuki_ST147 START*/
    --lv_install_address         VARCHAR2(540);           -- �ݒu��Z��
    lv_install_address         VARCHAR2(600);           -- �ݒu��Z��
    /*20090325_yabuki_ST147 END*/
    lv_owner_cmp_flag          VARCHAR2(1);             -- �{��/�H��t���O
    lv_owner_cmp_type          VARCHAR2(150);           -- �{��/�H��敪
    lv_owner_cmp_name          VARCHAR2(10);            -- �{��/�H��敪��
    lv_init_msg_list           VARCHAR2(2000);          -- ���b�Z�[�W���X�g
    lv_first_install_date      VARCHAR2(20);            -- ����ݒu��

    lv_manufacturer_name       xxcso_ib_info_h.manufacturer_name%type;     -- ���[�J�[��
    lv_manufacturer_code       po_un_numbers_b.attribute2%type;            -- ���[�J�[�R�[�h
    lv_age_type                po_un_numbers_b.attribute3%type;            -- �N��
    lv_hazard_class            po_hazard_classes_tl.hazard_class%type;      -- �@��敪�i�댯�x�敪�j

    -- API�߂�l�i�[�p
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
--
    -- API���o�̓��R�[�h�l�i�[�p
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
--
    -- *** ���[�J����O ***
    skip_process_expt          EXCEPTION;
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �f�[�^�̊i�[
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
    ld_date               := TRUNC(id_process_date);
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    ln_delete_flag        := io_inst_base_data_rec.delete_flag;
    ln_machinery_status1  := io_inst_base_data_rec.machinery_status1;
    ln_machinery_status2  := io_inst_base_data_rec.machinery_status2;
    ln_machinery_status3  := io_inst_base_data_rec.machinery_status3;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
    ln_machinery_kbn      := io_inst_base_data_rec.machinery_kbn;
    lv_un_number          := io_inst_base_data_rec.un_number;
    lv_install_number     := io_inst_base_data_rec.install_number;
    /*2009.09.03 M.Maruyama 0001192�Ή� START*/
    ld_actual_work_date   := TO_DATE(io_inst_base_data_rec.actual_work_date,'YYYY/MM/DD');
    /*2009.09.03 M.Maruyama 0001192�Ή� END*/
 --
    -- =================
    -- 1.���[�X�敪���o
    -- =================
--
    BEGIN
      SELECT   prlv.lease_type             lease_type                       -- ���[�X�敪
      INTO     lv_lease_type
      FROM     xxcso_requisition_lines_v   prlv                             -- �����˗����׏��r���[
              ,po_requisition_headers      prh                              -- �����˗��w�b�_�r���[
      WHERE    prh.segment1               = io_inst_base_data_rec.po_req_number
        AND    prh.authorization_status   = cv_approved
        AND    prlv.requisition_header_id = prh.requisition_header_id
        AND    prlv.line_num              = io_inst_base_data_rec.line_num
        AND    (ld_date BETWEEN(NVL(prlv.lookup_start_date, ld_date)) AND
                 TRUNC(NVL(prlv.lookup_end_date, ld_date)))
        AND    (ld_date BETWEEN(NVL(prlv.category_start_date, ld_date)) AND
                 TRUNC(NVL(prlv.category_end_date, ld_date)))
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���[�X�敪�Ȃ��x��
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_20              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_seq_no                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(ln_seq_no)            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_slip_num               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_slip_num)          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_line_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_line_num)          -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_work_kbn               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_job_kbn)           -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_21              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_seq_no                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(ln_seq_no)            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_slip_num               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_slip_num)          -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_line_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_line_num)          -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_work_kbn               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_job_kbn)           -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_errmsg                 -- �g�[�N���R�[�h8
                       ,iv_token_value8 => SQLERRM                       -- �g�[�N���l8
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--    
    lv_lease_type := SUBSTR(lv_lease_type, cn_num1, cn_num1);
    -- ========================
    -- 2.�@���Ԑ������`�F�b�N
    -- ========================
-- 
    -- �폜�t���O���u�X�F�_���폜�v�̏ꍇ
    IF (ln_delete_flag = cn_num9) THEN
      ln_instance_status_id := gt_instance_status_id_6;
    -- �@���ԂP���u�P�F�ғ����v�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num1) THEN
      ln_instance_status_id := gt_instance_status_id_1;
    -- �@���ԂP���u�Q�F�ؗ��v
    -- �@���ԂQ���u�O�F��񖳁v�܂��́u�P�F�����ρv
    -- �@���ԂR���u�O�F�\�薳���v�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status2 = cn_num0 OR ln_machinery_status2 = cn_num1)
             AND ln_machinery_status3  = cn_num0) THEN
      ln_instance_status_id := gt_instance_status_id_2;
    -- �@���ԂP���u�Q�F�ؗ��v
    -- �@���ԂQ���u�Q�F�����\��v�܂��́u�R�F�ۊǁv�܂��́u�X�F�̏ᒆ�v
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status2 = cn_num2 OR
                    /* 2009.07.10 K.Satomura �����e�X�g��Q�Ή�(0000476) START */
                    --ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num4)
                    ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num9)
                    /* 2009.07.10 K.Satomura �����e�X�g��Q�Ή�(0000476) END */
             AND ln_machinery_status3  = cn_num0) THEN
      ln_instance_status_id := gt_instance_status_id_3;
    -- �@���ԂP���u�Q�F�ؗ��v
    -- �@���ԂR���u�P�F�p���\��v�܂��́u�Q�D�p���\�����v�܂��́u�R�F�p�����ٍρv�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status3 = cn_num1 OR 
                    ln_machinery_status3 = cn_num2 OR ln_machinery_status3 = cn_num3)) THEN
      ln_instance_status_id := gt_instance_status_id_4;
    -- �@���ԂP���u�P�F�p���ρv�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num3) THEN
      ln_instance_status_id := gt_instance_status_id_5;
    -- �@���ԕs��
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_22              -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_machinery_status           -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_bukken                 -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_install_code               -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_hazard_state1          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => TO_CHAR(ln_machinery_status1) -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_hazard_state2          -- �g�[�N���R�[�h4
                     ,iv_token_value4 => TO_CHAR(ln_machinery_status2) -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_hazard_state3          -- �g�[�N���R�[�h5
                     ,iv_token_value5 => TO_CHAR(ln_machinery_status3) -- �g�[�N���l5
                   );
      lv_errbuf := lv_errmsg;
      RAISE skip_process_expt;
    END IF; 
--
    -- ============================
    -- 3.�ڋq�}�X�^�V�ݒu���񒊏o
    -- ============================
--
    BEGIN
      SELECT casv.cust_account_id                                     -- �A�J�E���gID
            ,casv.party_site_id                                       -- �p�[�e�B�T�C�gID
            ,casv.party_id                                            -- �p�[�e�BID
            ,casv.area_code                                           -- �n��R�[�h
      INTO   ln_account_id
            ,ln_party_site_id
            ,ln_party_id
            ,lv_area_code
      FROM   xxcso_cust_acct_sites_v casv                             -- �ڋq�}�X�^�T�C�g�r���[
      WHERE  casv.account_number    = lv_account_num1
        AND  casv.account_status    = cv_active
        AND  casv.acct_site_status  = cv_active
        AND  casv.party_status      = cv_active
        AND  casv.party_site_status = cv_active
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    -- ================================
    -- 4.���A�ԍ��}�X�^�r���[���o
    -- ================================
--
    BEGIN
      SELECT punv.attribute2                        -- ���[�J�[�R�[�h
            ,punv.attribute3                        -- �N��
            ,SUBSTRB(phcv.hazard_class,1,1)         -- �@��敪�i�댯�x�敪�j
      INTO   lv_manufacturer_code
            ,lv_age_type
            ,lv_hazard_class
      FROM   po_un_numbers_vl     punv               -- ���A�ԍ��}�X�^�r���[
            ,po_hazard_classes_vl phcv               -- �댯�x�敪�}�X�^�r���[
      WHERE  punv.un_number        = lv_un_number
        AND  punv.hazard_class_id  = phcv.hazard_class_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    -- ================================
    -- 5.�o�^�p�C���X�^���X���R�[�h�쐬
    -- ================================
--
    -- �������ҏW
    IF (io_inst_base_data_rec.actual_work_date IS NOT NULL) THEN
      ld_install_date := TO_DATE(io_inst_base_data_rec.actual_work_date, 'yyyy/mm/dd');
    END IF; 
    -- ����ݒu���ҏW
    IF (io_inst_base_data_rec.first_install_date IS NOT NULL) THEN 
      lv_first_install_date := TO_CHAR(TO_DATE(TO_CHAR(
        io_inst_base_data_rec.first_install_date),'yyyy/mm/dd'), 'yyyy/mm/dd hh24:mi:ss');
    END IF;
    l_instance_rec.external_reference         := lv_install_code;              -- �O���Q��
    l_instance_rec.inventory_item_id          := gt_bukken_item_id;            -- �݌ɕi��ID
    l_instance_rec.vld_organization_id        := gt_vld_org_id;                -- ���ؑg�DID
    l_instance_rec.inv_master_organization_id := gt_inv_mst_org_id;            -- �݌Ƀ}�X�^�[�g�DID
    l_instance_rec.quantity                   := cn_num1;                      -- ����
    l_instance_rec.unit_of_measure            := cv_unit_of_measure;           -- �P��
    l_instance_rec.instance_status_id         := ln_instance_status_id;        -- �C���X�^���X�X�e�[�^�XID
    /* 2009.04.13 K.Satomura T1_0418�Ή� START */
    --l_instance_rec.instance_type_code         := TO_CHAR(ln_machinery_kbn);    -- �C���X�^���X�^�C�v�R�[�h
    l_instance_rec.instance_type_code         := TO_CHAR(lv_hazard_class);    -- �C���X�^���X�^�C�v�R�[�h
    /* 2009.04.13 K.Satomura T1_0418�Ή� START */
    l_instance_rec.location_type_code         := cv_location_type_code;        -- ���s���Ə��^�C�v
    l_instance_rec.location_id                := ln_party_site_id;             -- ���s���Ə�ID
    l_instance_rec.install_date               := ld_install_date;              -- ������
    l_instance_rec.attribute1                 := lv_un_number;                 -- �@��(�R�[�h)
    l_instance_rec.attribute2                 := lv_install_number;            -- �@��
    l_instance_rec.attribute3                 := lv_first_install_date;        -- ����ݒu��
    l_instance_rec.attribute4                 := cv_flg_no;                    -- ��ƈ˗����t���O
    l_instance_rec.attribute6                 := io_inst_base_data_rec.po_req_number;  -- �ŏI�����˗��ԍ�
    l_instance_rec.instance_usage_code        := cv_instance_usage_code;       -- �C���X�^���X�g�p�R�[�h
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
--
    -- ==================================
    -- 6.�o�^�p�ݒu�@��g�������l���쐬
    -- ==================================
--
    -- �J�E���^�[No.
    ln_cnt := 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.count_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.counter_no;
--
    -- �n��R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.chiku_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_area_code;
--
    -- ��Ɖ�ЃR�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyougaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.job_company_code;
--
    -- ���Ə��R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jigyousyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.location_code;
--
    -- �ŏI��Ɠ`�[No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_slip_no;
--
    -- �ŏI��Ƌ敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_kbn;
--
    -- �ŏI��Ɛi��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_going;
--
    -- �ŏI��Ɗ����\���
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.yotei_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_cmpltn_plan_date;
--
    -- �ŏI��Ɗ�����
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_job_cmpltn_date;
--
    -- �ŏI�������e
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sagyo_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_maintenance_contents;
--
    -- �ŏI�ݒu�`�[No.
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.den_no2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_install_slip_no;
--
    -- �ŏI�ݒu�敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.job_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_install_kbn;
--
    -- �ŏI�ݒu�i��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sintyoku_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.last_install_going;
--
    -- �@����1�i�ғ���ԁj
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.machinery_status1;
--
    -- �@����2�i��ԏڍׁj
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.machinery_status2;
--
    -- �@����3�i�p�����j
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.jotai_kbn3;
    /* 2009.04.27 K.Satomura T1_0490�Ή� START */
    --l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.machinery_status3;
    /* 2009.04.27 K.Satomura T1_0490�Ή� END */
--
    -- ���ɓ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.nyuko_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.stock_date;
--
    -- ���g��ЃR�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakigaisya_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.withdraw_company_code;
--
    -- ���g���Ə��R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.hikisakijigyosyo_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.withdraw_location_code;
--
    -- �ݒu��S���Җ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �ݒu��tel1
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel1;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �ݒu��tel2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel2;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �ݒu��tel3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.setti_tel3;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �p�����ٓ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.haikikessai_dt;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �]���p���Ǝ�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_tanto;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_disposal_vendor;
--
    -- �]���p���`�[��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_den_no;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_disposal_slip_no;
--
    -- ���L��
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.syoyu_cd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.owner_company_code;
--
    -- �]���p���󋵃t���O
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.tenhai_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_disposal_flag;
--
    -- �]�������敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.kanryo_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.resale_completion_kbn;
--
    -- �폜�t���O
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.sakujo_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.delete_flag;
--
    -- �ŏI�ڋq�R�[�h
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kyaku_last;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���ЃR�[�h�P
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���Б䐔�P
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu01;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���ЃR�[�h2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���Б䐔2
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu02;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���ЃR�[�h3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���Б䐔3
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu03;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���ЃR�[�h4
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���Б䐔4
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu04;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���ЃR�[�h5
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_cd05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���Б䐔5
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_tasya_daisu05;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �p���t���O
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_haiki_flg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := cv_kbn0;
--
    -- ���Y�敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_sisan_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �w�����t
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_ymd;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- �w�����z
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.ven_kobai_kg;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
    -- ���S�ݒu�
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.safty_level;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := io_inst_base_data_rec.safe_setting_standard;
--
    -- ���[�X�敪
    ln_cnt := ln_cnt + 1;
    l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.lease_kbn;
    l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_lease_type;
--
    /*2009.09.03 M.Maruyama 0001192�Ή� START*/
    IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM')) THEN
--
      -- �挎���N��
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_year_month;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
--
      -- �挎���ݒu��ڋq�R�[�h
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_inst_cust_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := lv_account_num1;
--
      -- �挎���@����
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_jotai_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := ln_machinery_status1;
--    
    ELSE
    /*2009.09.03 M.Maruyama 0001192�Ή� END*/
      -- �挎���N��
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_year_month;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
      -- �挎���ݒu��ڋq�R�[�h
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_inst_cust_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
--
      -- �挎���@����
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id    := gr_ext_attribs_id_rec.last_jotai_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_value := '';
    /*2009.09.03 M.Maruyama 0001192�Ή� START*/
    END IF;
    /*2009.09.03 M.Maruyama 0001192�Ή� END*/
--
    -- ====================
    -- 7.�p�[�e�B�f�[�^�쐬
    -- ====================
--
    ln_cnt := 1;
    l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
    l_party_tab(ln_cnt).party_id                 := ln_party_id;
    l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
    l_party_tab(ln_cnt).CONTACT_FLAG             := cv_flg_no;
--
    -- ===============================
    -- 8.�p�[�e�B�A�J�E���g�f�[�^�쐬
    -- ===============================
--
    ln_cnt := 1;
    l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
    l_account_tab(ln_cnt).party_account_id       := ln_account_id;
    l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
--
    -- ===============================
    -- 9.������R�[�h�f�[�^�쐬
    -- ===============================
--
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;
--
    -- =================================
    -- 10.�W��API���A�����o�^�������s��
    -- =================================
--
    BEGIN
      CSI_ITEM_INSTANCE_PUB.create_item_instance(
         p_api_version           => cn_api_version
        ,p_commit                => lv_commit
        ,p_init_msg_list         => lv_init_msg_list
        ,p_validation_level      => ln_validation_level
        ,p_instance_rec          => l_instance_rec
        ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
        ,p_party_tbl             => l_party_tab
        ,p_account_tbl           => l_account_tab
        ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
        ,p_org_assignments_tbl   => l_org_assignments_tab
        ,p_asset_assignment_tbl  => l_asset_assignment_tab
        ,p_txn_rec               => l_txn_rec
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      -- ����I���łȂ��ꍇ
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE update_error_expt;
      END IF;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        IF (FND_MSG_PUB.Count_Msg > 0) THEN
          FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
            FND_MSG_PUB.Get(
               p_msg_index     => i
              ,p_encoded       => cv_encoded_f
              ,p_data          => lv_io_msg_data
              ,p_msg_index_out => ln_io_msg_count
            );
            lv_msg_data := lv_msg_data || lv_io_msg_data;
          END LOOP;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_inst_base_insert           -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_insert_process             -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                       ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                       ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                       ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                       ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10 => lv_msg_data                   -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--  
    -- ���^�[���X�e�[�^�X��[S]�ŁA���[�X�敪��[1.���Ѓ��[�X]�̏ꍇ
    IF (lv_lease_type = cv_lease_type_own) THEN 
      -- ========================================
      -- 11.�����֘A���ύX�����e�[�u���̓o�^����
      -- ========================================
--
      -- ���[�J�[���擾
      lv_manufacturer_name := xxcso_util_common_pkg.get_lookup_meaning(
                                cv_xxcso_csi_maker_code
                               ,lv_manufacturer_code
                               ,ld_date);
--
      IF (lv_manufacturer_name is null) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_13             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_mfg_fctory_maker_nm       -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_lookup_type_name      -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_mfg_fctory_maker_cd       -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      END IF;
--
      BEGIN
        /*2009.09.03 M.Maruyama 0001192�Ή� START*/
        --SELECT casv.sale_base_code                                        -- ���㋒�_�R�[�h
        SELECT (CASE
                WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                THEN casv.sale_base_code
                ELSE casv.past_sale_base_code
                END) sale_base_code                                  -- ���㋒�_�R�[�h
        /*2009.09.03 M.Maruyama 0001192�Ή� END*/
              ,casv.established_site_name                                 -- �ݒu�於
              ,casv.state || casv.city || casv.address1 || casv.address2  -- �ݒu��Z��
        INTO   lv_base_code
              ,lv_install_name
              ,lv_install_address
        FROM   xxcso_cust_acct_sites_v casv                               -- �ڋq�}�X�^�T�C�g�r���[
        WHERE  casv.account_number    = lv_account_num1
          AND  casv.account_status    = cv_active
          AND  casv.acct_site_status  = cv_active
          AND  casv.party_status      = cv_active
          AND  casv.party_site_status = cv_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                         ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
      BEGIN
        -- �{��/�H��t���O�̏�����
        lv_owner_cmp_flag := cv_kbn1;
        -- �{��/�H��t���O�̕ҏW
        <<mfg_fctory_loop>>
        FOR ln_loop_cnt IN 1..gt_mfg_fctory_code_tab.count LOOP
          IF (gt_mfg_fctory_code_tab(ln_loop_cnt).mfg_fctory_code = lv_base_code) THEN
            lv_owner_cmp_flag := cv_kbn2;
            EXIT;
          END IF;
        END LOOP mfg_fctory_loop;
  --
        -- �{��/�H��敪�̕ҏW
        lv_owner_cmp_name := xxcso_util_common_pkg.get_lookup_meaning(
                               cv_xxcso1_owner_company
                              ,lv_owner_cmp_flag
                              ,id_process_date);  
  --
        SELECT ffvv.flex_value                                         -- �l
        INTO   lv_owner_cmp_type
        FROM   fnd_flex_values_vl    ffvv                              -- �l�Z�b�g(�l)
              ,fnd_flex_value_sets   ffvs                              -- �l�Z�b�g
        WHERE  ffvv.flex_value_set_id   = ffvs.flex_value_set_id
          AND  ffvs.flex_value_set_name = cv_xxcff_owner_company
          AND  ffvv.enabled_flag        = cv_flg_yes
          AND  ld_date BETWEEN trunc(nvl(ffvv.start_date_active,ld_date))
                 AND trunc(nvl(ffvv.end_date_active,ld_date))
          AND  ffvv.flex_value_meaning  = lv_owner_cmp_name
        ;  
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_16             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_owner_cmp_info            -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_errmsg                -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
  --
      BEGIN
        -- �����֘A���ύX�����e�[�u���̓o�^
        INSERT INTO xxcso_ib_info_h(
           install_code                           -- �����R�[�h
          ,history_creation_date                  -- �����쐬��
          ,interface_flag                         -- �A�g�σt���O
          ,po_number                              -- �����ԍ�
          ,manufacturer_name                      -- ���[�J�[��
          ,age_type                               -- �N��
          ,un_number                              -- �@��
          ,install_number                         -- �@��
          ,quantity                               -- ����
          ,base_code                              -- ���_�R�[�h
          ,owner_company_type                     -- �{�Ё^�H��敪
          ,install_name                           -- �ݒu�於
          ,install_address                        -- �ݒu��Z��
          ,logical_delete_flag                    -- �_���폜�t���O
          ,account_number                         -- �ڋq�R�[�h
          ,created_by                             -- �쐬��
          ,creation_date                          -- �쐬��
          ,last_updated_by                        -- �ŏI�X�V��
          ,last_update_date                       -- �ŏI�X�V��
          ,last_update_login                      -- �ŏI�X�V���O�C��
          ,request_id                             -- �v��ID
          ,program_application_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                             -- �R���J�����g�E�v���O����ID PROGRAM_ID
          ,program_update_date                    -- �v���O�����X�V��
        )VALUES(
           lv_install_code1                       -- �����R�[�h
          ,ld_date                                -- �����쐬��
          ,cv_flg_no                              -- �A�g�σt���O
          ,io_inst_base_data_rec.po_number        -- �����ԍ�
          ,lv_manufacturer_name                   -- ���[�J�[��
          ,lv_age_type                            -- �N��
          ,lv_un_number                           -- �@��
          ,lv_install_number                      -- �@��
          ,cn_num1                                -- ����
          ,lv_base_code                           -- ���_�R�[�h
          ,lv_owner_cmp_type                      -- �{�Ё^�H��敪
          ,lv_install_name                        -- �ݒu�於
          ,lv_install_address                     -- �ݒu��Z��
          ,cv_flg_no                              -- �_���폜�t���O
          ,lv_account_num1                        -- �ڋq�R�[�h
          ,cn_created_by                          -- �쐬��
          ,SYSDATE                                -- �쐬��
          ,cn_last_updated_by                     -- �ŏI�X�V��
          ,SYSDATE                                -- �ŏI�X�V��
          ,cn_last_update_login                   -- �ŏI�X�V���O�C��
          ,cn_request_id                          -- �v��ID
          ,cn_program_application_id              -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                          -- �R���J�����g�E�v���O����ID PROGRAM_ID
          ,SYSDATE                                -- �v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                         ,iv_token_value1  => cv_xxcso_ib_info_h            -- �g�[�N���l1
                         ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                         ,iv_token_value2  => cv_insert_process             -- �g�[�N���l2
                         ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                         ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                         ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                         ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                         ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                         ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                         ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                         ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                         ,iv_token_value10 => SQLERRM                       -- �g�[�N���l10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v������O�n���h�� ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      -- �X�V���s���[���o�b�N�t���O�̐ݒ�B
      gb_rollback_flg := TRUE;
--      
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END insert_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : rock_item_instances
   * Description      : �������b�N���� (A-7)
   ***********************************************************************************/
  PROCEDURE rock_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)�����}�X�^���
    ,id_process_date         IN     DATE                    -- �Ɩ��������t
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rock_item_instances'; -- �v���O������
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
    cv_install_base_info       CONSTANT VARCHAR2(100)   := '�C���X�g�[���x�[�X�}�X�^(�����}�X�^)';
--
    -- *** ���[�J���ϐ� ***
    ln_seq_no                  NUMBER;                  -- �V�[�P���X�ԍ�
    ln_slip_num                NUMBER;                  -- �`�[No.
    ln_slip_branch_num         NUMBER;                  -- �`�[�}��
    ln_line_num                NUMBER;                  -- �s��
    ln_job_kbn                 NUMBER;                  -- ��Ƌ敪
    lv_install_code            VARCHAR2(10);            -- �����R�[�h
    lv_install_code1           VARCHAR2(10);            -- �����R�[�h�P
    lv_install_code2           VARCHAR2(10);            -- �����R�[�h�Q
    lv_account_num1            VARCHAR2(10);            -- �ڋq�R�[�h�P
    lv_account_num2            VARCHAR2(10);            -- �ڋq�R�[�h�Q
    lv_rock_install_code       VARCHAR2(10);            -- ���b�N�p�����R�[�h
--
    -- *** ���[�J����O ***
    skip_process_expt          EXCEPTION;
--    
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �f�[�^�̊i�[
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
--
    -- ������񒊏o
    BEGIN
      SELECT ciins.external_reference                                    -- �O���Q��
      INTO   lv_rock_install_code
      FROM   csi_item_instances ciins                                    -- �C���X�g�[���x�[�X�}�X�^
      WHERE  ciins.external_reference = lv_install_code
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_install_base_info          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      -- ���o�Ɏ��s�����ꍇ�̗�O
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_19             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_install_base_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
  EXCEPTION
    -- *** �X�L�b�v������O�n���h�� ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END rock_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : update_item_instances
   * Description      : �����f�[�^�X�V���� (A-8)
   ***********************************************************************************/
  PROCEDURE update_item_instances(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)�����}�X�^���
    ,id_process_date         IN     DATE                    -- �Ɩ��������t
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_item_instances'; -- �v���O������
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
    cn_num0                   CONSTANT NUMBER        := 0;
    cn_num1                   CONSTANT NUMBER        := 1;
    cn_num2                   CONSTANT NUMBER        := 2;
    cn_num3                   CONSTANT NUMBER        := 3;
    cn_num4                   CONSTANT NUMBER        := 4;
    cn_num9                   CONSTANT NUMBER        := 9;
    cn_jon_kbn_1              CONSTANT NUMBER        := 1;                   -- �V��ݒu
    cn_jon_kbn_2              CONSTANT NUMBER        := 2;                   -- ����ݒu
    cn_jon_kbn_3              CONSTANT NUMBER        := 3;                   -- �V����
    cn_jon_kbn_4              CONSTANT NUMBER        := 4;                   -- ������
    cn_jon_kbn_5              CONSTANT NUMBER        := 5;                   -- ���g
    /*20090528_Ohtsuki_T1_1203 START*/
    cn_job_kbn_6              CONSTANT NUMBER        := 6;                   -- �X���ړ�
    cn_job_kbn_8              CONSTANT NUMBER        := 8;                   -- ����
    cn_job_kbn_9              CONSTANT NUMBER        := 9;                   -- �o���C��
    cn_job_kbn_10             CONSTANT NUMBER        := 10;                  -- ����
    cn_job_kbn_15             CONSTANT NUMBER        := 15;                  -- �]��
    cn_job_kbn_16             CONSTANT NUMBER        := 16;                  -- �]��
    cn_job_kbn_17             CONSTANT NUMBER        := 17;                  -- �p������
    /*20090528_Ohtsuki_T1_1203 END*/
    cn_api_version            CONSTANT NUMBER        := 1.0;
    cv_kbn1                   CONSTANT VARCHAR2(1)   := '1'; 
    cv_kbn2                   CONSTANT VARCHAR2(1)   := '2'; 
    cv_cust_mst_info          CONSTANT VARCHAR2(100) := '�ڋq�}�X�^���';    -- ���o���e
    /*20090325_yabuki_ST150 START*/
    cv_cust_base_info          CONSTANT VARCHAR2(100) := '���g�O�ݒu��ڋq�̔��㋒�_���';    -- ���o���e
    /*20090325_yabuki_ST150 END*/
    cv_inst_party_info        CONSTANT VARCHAR2(100) := '�C���X�^���X�p�[�e�B���';      -- ���o���e
    cv_inst_account_info      CONSTANT VARCHAR2(100) := '�C���X�^���X�A�J�E���g���';    -- ���o���e
    cv_inst_base_insert       CONSTANT VARCHAR2(100) := '�C���X�g�[���x�[�X�}�X�^';
    cv_update_process         CONSTANT VARCHAR2(100) := '�X�V';
    cv_machinery_status       CONSTANT VARCHAR2(100) := '�����f�[�^���[�N�e�[�u���̋@����'; 
    cv_location_type_code     CONSTANT VARCHAR2(100) := 'HZ_PARTY_SITES';    -- ���s���Ə��^�C�v
    cv_instance_usage_code    CONSTANT VARCHAR2(100) := 'OUT_OF_ENTERPRISE'; -- �C���X�^���X�g�p�R�[�h
    cv_party_source_table     CONSTANT VARCHAR2(100) := 'HZ_PARTIES';        -- �p�[�e�B�\�[�X�e�[�u��
    cv_relatnsh_type_code     CONSTANT VARCHAR2(100) := 'OWNER';             -- �����[�V�����^�C�v
    cv_ex_count_no            CONSTANT VARCHAR2(100) := 'COUNT_NO';           
    cv_ex_chiku_cd            CONSTANT VARCHAR2(100) := 'CHIKU_CD';           
    cv_ex_sagyougaisya_cd     CONSTANT VARCHAR2(100) := 'SAGYOUGAISYA_CD';    
    cv_ex_jigyousyo_cd        CONSTANT VARCHAR2(100) := 'JIGYOUSYO_CD';       
    cv_ex_den_no              CONSTANT VARCHAR2(100) := 'DEN_NO';             
    cv_ex_job_kbn             CONSTANT VARCHAR2(100) := 'JOB_KBN';            
    cv_ex_sintyoku_kbn        CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN';       
    cv_ex_yotei_dt            CONSTANT VARCHAR2(100) := 'YOTEI_DT';           
    cv_ex_kanryo_dt           CONSTANT VARCHAR2(100) := 'KANRYO_DT';          
    cv_ex_sagyo_level         CONSTANT VARCHAR2(100) := 'SAGYO_LEVEL';        
    cv_ex_den_no2             CONSTANT VARCHAR2(100) := 'DEN_NO2';            
    cv_ex_job_kbn2            CONSTANT VARCHAR2(100) := 'JOB_KBN2';           
    cv_ex_sintyoku_kbn2       CONSTANT VARCHAR2(100) := 'SINTYOKU_KBN2';      
    cv_ex_jotai_kbn1          CONSTANT VARCHAR2(100) := 'JOTAI_KBN1';         
    cv_ex_jotai_kbn2          CONSTANT VARCHAR2(100) := 'JOTAI_KBN2';         
    cv_ex_nyuko_dt            CONSTANT VARCHAR2(100) := 'NYUKO_DT';           
    cv_ex_hikisakigaisya_cd   CONSTANT VARCHAR2(100) := 'HIKISAKIGAISYA_CD';  
    cv_ex_hikisakijigyosyo_cd CONSTANT VARCHAR2(100) := 'HIKISAKIJIGYOSYO_CD';
    cv_ex_setti_tenmei        CONSTANT VARCHAR2(100) := 'SETTI_TENMEI';       
    cv_ex_tenhai_tanto        CONSTANT VARCHAR2(100) := 'TENHAI_TANTO';       
    cv_ex_tenhai_den_no       CONSTANT VARCHAR2(100) := 'TENHAI_DEN_NO';      
    cv_ex_syoyu_cd            CONSTANT VARCHAR2(100) := 'SYOYU_CD';           
    cv_ex_tenhai_flg          CONSTANT VARCHAR2(100) := 'TENHAI_FLG';         
    cv_ex_kanryo_kbn          CONSTANT VARCHAR2(100) := 'KANRYO_KBN';         
    cv_ex_sakujo_flg          CONSTANT VARCHAR2(100) := 'SAKUJO_FLG';         
    cv_ex_ven_kyaku_last      CONSTANT VARCHAR2(100) := 'VEN_KYAKU_LAST';     
    cv_ex_ven_haiki_flg       CONSTANT VARCHAR2(100) := 'VEN_HAIKI_FLG';      
    cv_ex_safty_level         CONSTANT VARCHAR2(100) := 'SAFTY_LEVEL';        
    cv_ex_lease_kbn           CONSTANT VARCHAR2(100) := 'LEASE_KBN';          
    cv_ex_last_inst_cust_code CONSTANT VARCHAR2(100) := 'LAST_INST_CUST_CODE';
    cv_ex_last_jotai_kbn      CONSTANT VARCHAR2(100) := 'LAST_JOTAI_KBN';     
    cv_ex_last_year_month     CONSTANT VARCHAR2(100) := 'LAST_YEAR_MONTH';    
    cv_flg_no                 CONSTANT VARCHAR2(100) := 'N';                 -- �t���ONO
    cv_flg_yes                CONSTANT VARCHAR2(100) := 'Y';                 -- �t���OYES
    /* 2009.04.13 K.Satomura T1_0418�Ή� START */
    cv_po_un_numbers_info     CONSTANT VARCHAR2(100) := '���A�ԍ��}�X�^(�@��R�[�h�}�X�^)���';    -- ���o���e
    /* 2009.04.13 K.Satomura T1_0418�Ή� END */
    /* 2009.04.27 K.Satomura T1_0490�Ή� START */
    cv_ex_jotai_kbn3          CONSTANT VARCHAR2(100) := 'JOTAI_KBN3';
    /* 2009.04.27 K.Satomura T1_0490�Ή� END */
    /* 2009.06.01 K.Satomura T1_1107�Ή� START */
    ct_comp_kbn_comp         CONSTANT xxcso_in_work_data.completion_kbn%TYPE := 1;
    /* 2009.06.01 K.Satomura T1_1107�Ή� END */
    /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
    cv_day_zero              CONSTANT VARCHAR2(1) := '0';
    /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */

--
    -- *** ���[�J���ϐ� ***
    ld_date                    DATE;                    -- �Ɩ��������t�i�[�p('yyyymmdd'�`��)
    ld_actual_work_date        DATE;                    -- ����Ɠ�('yyyymmdd'�`��)
    ld_install_date            DATE;                    -- ������
    ln_cnt                     NUMBER;                  -- �J�E���g��
    ln_seq_no                  NUMBER;                  -- �V�[�P���X�ԍ�
    ln_slip_num                NUMBER;                  -- �`�[No.
    ln_slip_branch_num         NUMBER;                  -- �`�[�}��
    ln_line_num                NUMBER;                  -- �s��
    ln_job_kbn                 NUMBER;                  -- ��Ƌ敪
    ln_instance_status_id      NUMBER;                  -- �C���X�^���X�X�e�[�^�XID
    ln_machinery_status1       NUMBER;                  -- �@����1�i�ғ���ԁj
    ln_machinery_status1_wk    NUMBER;                  -- �@����1�i�ғ���ԁj
    ln_machinery_status2       NUMBER;                  -- �@����2�i��ԏڍׁj
    ln_machinery_status3       NUMBER;                  -- �@����3�i�p�����j
    ln_account_id              NUMBER;                  -- �A�J�E���gID
    ln_party_site_id           NUMBER;                  -- �p�[�e�B�T�C�gID
    ln_party_id                NUMBER;                  -- �p�[�e�BID
    lv_area_code               VARCHAR2(100);           -- �n��R�[�h
    ln_delete_flag             NUMBER;                  -- �폜�t���O
    ln_machinery_kbn           NUMBER;                  -- �@��敪
    ln_validation_level        NUMBER;                  -- �o���f�[�V�������[�x��
    ln_instance_id             NUMBER;                  -- �C���X�^���XID
    ln_instance_party_id       NUMBER;                  -- �C���X�^���X�p�[�e�BID
    ln_object_version_number2  NUMBER;                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ln_ip_account_id           NUMBER;                  -- �C���X�^���X�A�J�E���gID
    ln_object_version_number3  NUMBER;                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ln_loop_cnt                NUMBER;                  -- ���[�v�p�ϐ�
    lv_commit                  VARCHAR2(1);             -- �R�~�b�g�t���O
    lv_install_code            VARCHAR2(10);            -- �����R�[�h
    lv_install_code1           VARCHAR2(10);            -- �����R�[�h�P
    lv_install_code2           VARCHAR2(10);            -- �����R�[�h�Q
    lv_account_num             VARCHAR2(10);            -- �ڋq�R�[�h
    lv_account_num1            VARCHAR2(10);            -- �ڋq�R�[�h�P
    lv_account_num2            VARCHAR2(10);            -- �ڋq�R�[�h�Q
    lv_un_number               VARCHAR2(20);            -- �@��
    lv_install_number          VARCHAR2(20);            -- �@��
    lv_last_cust_num           VARCHAR2(10);            -- �ŏI�ڋq�R�[�h
    lv_init_msg_list           VARCHAR2(2000);          -- ���b�Z�[�W���X�g
    lv_last_inst_cust_code     VARCHAR2(10);            -- �挎���ݒu��ڋq�R�[�h
    ln_last_jotai_kbn          NUMBER;                  -- �挎���@����
    lv_last_year_month         VARCHAR2(10);            -- �挎���N��
    /*20090325_yabuki_ST150 START*/
    lt_sale_base_code          xxcso_cust_acct_sites_v.sale_base_code%TYPE;       -- ���㋒�_�R�[�h
    /*20090325_yabuki_ST150 END*/
    /*2009.09.03 M.Maruyama 0001192�Ή� START*/
    lt_past_sale_base_code     xxcso_cust_acct_sites_v.past_sale_base_code%TYPE;  -- �O�����㋒�_�R�[�h
    lt_sl_bs_cd_fr_bfr_mnth_dt xxcso_cust_acct_sites_v.past_sale_base_code%TYPE;  -- �O�����㋒�_�R�[�h(�挎���ڋq�R�[�h�p)
    ld_ib_install_date         DATE;                                              -- �ݒu��
    /*2009.09.03 M.Maruyama 0001192�Ή� END*/
    /* 2009.04.13 K.Satomura T1_0418�Ή� START */
    lv_hazard_class            po_hazard_classes_tl.hazard_class%type; -- �@��敪�i�댯�x�敪�j
    /* 2009.04.13 K.Satomura T1_0418�Ή� END */
    -- API�߂�l�i�[�p
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
--
    -- API���o�̓��R�[�h�l�i�[�p
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
    l_instance_id_lst          csi_datastructures_pub.id_tbl;
    l_ext_attrib_rec           csi_iea_values%ROWTYPE;
    l_ext_attrib_rec_wk        csi_iea_values%ROWTYPE;
--
    l_csi_iea_values_rec       gr_csi_iea_values_rtype;
    -- *** ���[�J����O ***
    skip_process_expt          EXCEPTION;
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �f�[�^�̊i�[
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
    ld_date               := TRUNC(id_process_date);
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    ln_delete_flag        := io_inst_base_data_rec.delete_flag;
    ln_machinery_status1  := io_inst_base_data_rec.machinery_status1;
    ln_machinery_status2  := io_inst_base_data_rec.machinery_status2;
    ln_machinery_status3  := io_inst_base_data_rec.machinery_status3;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
    ln_machinery_kbn      := io_inst_base_data_rec.machinery_kbn;
    lv_un_number          := io_inst_base_data_rec.un_number;
    lv_install_number     := io_inst_base_data_rec.install_number;
    ln_instance_id        := io_inst_base_data_rec.instance_id;
    ld_actual_work_date   := TO_DATE(io_inst_base_data_rec.actual_work_date,'YYYY/MM/DD');
--
    -- ========================
    -- 1.�@���Ԑ������`�F�b�N
    -- ========================
-- 
    -- �폜�t���O���u�X�F�_���폜�v�̏ꍇ
    IF (ln_delete_flag = cn_num9) THEN
      ln_instance_status_id := gt_instance_status_id_6;
    -- �@���ԂP���u�P�F�ғ����v�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num1) THEN
      ln_instance_status_id := gt_instance_status_id_1;
    -- �@���ԂP���u�Q�F�ؗ��v
    -- �@���ԂQ���u�O�F��񖳁v�܂��́u�P�F�����ρv
    -- �@���ԂR���u�O�F�\�薳���v�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status2 = cn_num0 OR ln_machinery_status2 = cn_num1)
             AND ln_machinery_status3  = cn_num0) THEN
      ln_instance_status_id := gt_instance_status_id_2;
    -- �@���ԂP���u�Q�F�ؗ��v
    -- �@���ԂQ���u�Q�F�����\��v�܂��́u�R�F�ۊǁv�܂��́u�X�F�̏ᒆ�v
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status2 = cn_num2 OR
                    /* 2009.07.10 K.Satomura �����e�X�g��Q�Ή�(0000476) START */
                    --ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num4)
                    ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num9)
                    /* 2009.07.10 K.Satomura �����e�X�g��Q�Ή�(0000476) END */
             AND ln_machinery_status3  = cn_num0) THEN
      ln_instance_status_id := gt_instance_status_id_3;
    -- �@���ԂP���u�Q�F�ؗ��v
    -- �@���ԂR���u�P�F�p���\��v�܂��́u�Q�D�p���\�����v�܂��́u�R�F�p�����ٍρv�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num2
             AND (ln_machinery_status3 = cn_num1 OR 
                    ln_machinery_status3 = cn_num2 OR ln_machinery_status3 = cn_num3)) THEN
      ln_instance_status_id := gt_instance_status_id_4;
    -- �@���ԂP���u�P�F�p���ρv�̏ꍇ
    ELSIF (ln_machinery_status1 = cn_num3) THEN
      ln_instance_status_id := gt_instance_status_id_5;
    -- �@���ԕs��
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_22              -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_machinery_status           -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_bukken                 -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_install_code               -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_hazard_state1          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => TO_CHAR(ln_machinery_status1) -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_hazard_state2          -- �g�[�N���R�[�h4
                     ,iv_token_value4 => TO_CHAR(ln_machinery_status2) -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_hazard_state3          -- �g�[�N���R�[�h5
                     ,iv_token_value5 => TO_CHAR(ln_machinery_status3) -- �g�[�N���l5
                   );
      lv_errbuf := lv_errmsg;
      RAISE skip_process_expt;
    END IF; 
--
    -- ===============
    -- 2.�ϐ��̏�����
    -- ===============
    ln_account_id     := cn_num0;
    ln_party_site_id  := cn_num0;
    ln_party_id       := cn_num0;
    lv_area_code      := NULL;
--
    -- 3.�ݒu�@��g�������l(�X�V�p)�f�[�^�쐬
--
    -- �J�E���^�[No.
    ln_cnt := 1;
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_count_no);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.counter_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ��Ɖ�ЃR�[�h
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sagyougaisya_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.job_company_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ���Ə��R�[�h
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jigyousyo_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.location_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI��Ɠ`�[No.
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_den_no);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_slip_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI��Ƌ敪
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_job_kbn);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI��Ɛi��
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sintyoku_kbn);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_going;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI��Ɗ����\���
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_yotei_dt);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_cmpltn_plan_date;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI��Ɗ�����
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_kanryo_dt);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_job_cmpltn_date;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI�������e
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sagyo_level);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_maintenance_contents;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI�ݒu�`�[No.
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_den_no2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_install_slip_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI�ݒu�敪
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_job_kbn2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_install_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �ŏI�ݒu�i��
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sintyoku_kbn2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.last_install_going;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �@����1�i�ғ���ԁj
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jotai_kbn1);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      ln_machinery_status1_wk := l_ext_attrib_rec.attribute_value;
    END IF;
--
    -- �@����2�i��ԏڍׁj
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jotai_kbn2);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status2;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    /* 2009.04.27 K.Satomura T1_0490�Ή� START */
    -- �@����3�i�p�����j
    l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_jotai_kbn3);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL) THEN
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status3;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
    /* 2009.04.27 K.Satomura T1_0490�Ή� END */
    -- ���ɓ�
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_nyuko_dt);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.stock_date;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ���g��ЃR�[�h
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_hikisakigaisya_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.withdraw_company_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ���g���Ə��R�[�h
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_hikisakijigyosyo_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.withdraw_location_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �]���p���Ǝ�
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_tenhai_tanto);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_disposal_vendor;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �]���p���`�[��
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_tenhai_den_no);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_disposal_slip_no;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ���L��
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_syoyu_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.owner_company_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �]���p���󋵃t���O
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_tenhai_flg);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_disposal_flag;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �]�������敪
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_kanryo_kbn);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.resale_completion_kbn;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- �폜�t���O
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_sakujo_flg);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.delete_flag;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ���S�ݒu�
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_safty_level);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.safe_setting_standard;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ============================
    -- 3.�ڋq��񒊏o
    -- ============================
--
    -- ��ƃf�[�^.����Ɠ��̔N�� = �Ɩ��������t�̑O���̔N��
    BEGIN
      SELECT casv.account_number                                      -- �ڋq�R�[�h
            ,casv.cust_account_id                                     -- �A�J�E���gID
            ,casv.party_site_id                                       -- �p�[�e�B�T�C�gID
            ,casv.party_id                                            -- �p�[�e�BID
            ,casv.area_code                                           -- �n��R�[�h
            /*20090325_yabuki_ST150 START*/
            ,casv.sale_base_code                                      -- ���㋒�_�R�[�h
            /*s_yabuki_ST150 END*/
            /*2009.09.03 M.Maruyama 0001192�Ή� START*/
            ,casv.past_sale_base_code                                 -- �O�����㋒�_�R�[�h
            ,ciis.install_date                                        -- �ݒu��
            /*2009.09.03 M.Maruyama 0001192�Ή� END*/
      INTO   lv_account_num
            ,ln_account_id
            ,ln_party_site_id
            ,ln_party_id
            ,lv_area_code
            /*20090325_yabuki_ST150 START*/
            ,lt_sale_base_code
            /*20090325_yabuki_ST150 END*/
            /*2009.09.03 M.Maruyama 0001192�Ή� START*/
            ,lt_past_sale_base_code
            ,ld_ib_install_date
            /*2009.09.03 M.Maruyama 0001192�Ή� END*/
      FROM   xxcso_cust_acct_sites_v casv                               -- �ڋq�}�X�^�T�C�g�r���[
            ,csi_item_instances      ciis                               -- �C���X�g�[���x�[�X�}�X�^
      WHERE  ciis.external_reference     = lv_install_code
        AND  ciis.owner_party_account_id = casv.cust_account_id
        AND  casv.account_status         = cv_active
        AND  casv.acct_site_status       = cv_active
        AND  casv.party_status           = cv_active
        AND  casv.party_site_status      = cv_active
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
      -- �挎���N���̎擾
      l_ext_attrib_rec_wk := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
      lv_last_year_month := l_ext_attrib_rec_wk.attribute_value;
--
    /*20090528_Ohtsuki_T1_1203 START*/
    -- ��Ƌ敪���y�X���ړ��z�y�����z�y�o���C���z�y�����z�y�]���z�y�]���z�y�p������z�ȊO�̏ꍇ
    IF (io_inst_base_data_rec.job_kbn  NOT IN 
         (cn_job_kbn_6,cn_job_kbn_8,cn_job_kbn_9,cn_job_kbn_10,cn_job_kbn_15,cn_job_kbn_16,cn_job_kbn_17)) THEN
    /*20090528_Ohtsuki_T1_1203 END*/
    
      -- �挎���N�����Ɩ��������t�̑O���̔N��
      IF (lv_last_year_month <> TO_NUMBER(TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM')) OR
          lv_last_year_month IS NULL) THEN
          
        -- ����Ɠ��̔N�����Ɩ��������t�̑O���̔N��
        IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM')) THEN
--
          /*2009.09.03 M.Maruyama 0001192�Ή� START*/
          -- ��ƃf�[�^�D��Ƌ敪���u�V��ݒu�v�u�V���ցv�u����ݒu�v�u�����ցv�̂����ꂩ�A
          --   �������t�@�C���D�����R�[�h����ƃf�[�^�D�����R�[�h�P
          IF ((io_inst_base_data_rec.job_kbn IN (cn_jon_kbn_1,cn_jon_kbn_2,cn_jon_kbn_3,cn_jon_kbn_4)) 
            AND (lv_install_code = lv_install_code1)) THEN
--
            -- �挎���N���̎擾
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- �挎���ݒu��ڋq�R�[�h(��ƃf�[�^.�ڋq�f�[�^1)
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_account_num1;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- �挎���@����(�����t�@�C��.�@����1 [�ғ���])
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
          -- ��ƃf�[�^�D��Ƌ敪���u�V���ցv�u�����ցv�u���g�v�̂����ꂩ�A
          --   ���� �����t�@�C���D�����R�[�h����ƃf�[�^�D�����R�[�h�Q
          ELSIF ((io_inst_base_data_rec.job_kbn IN (cn_jon_kbn_3,cn_jon_kbn_4,cn_jon_kbn_5))
               AND (lv_install_code = lv_install_code2)) THEN
--
            -- �@��敪�擾
            BEGIN
              SELECT SUBSTRB(phcv.hazard_class,1,1) -- �@��敪�i�댯�x�敪�j
              INTO   lv_hazard_class
              FROM   po_un_numbers_vl     punv               -- ���A�ԍ��}�X�^�r���[
                    ,po_hazard_classes_vl phcv               -- �댯�x�敪�}�X�^�r���[
              WHERE  punv.un_number        = lv_un_number
                AND  punv.hazard_class_id  = phcv.hazard_class_id
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�����݂��Ȃ��ꍇ
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_po_un_numbers_info         -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                               ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                               ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                               ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                               ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                               ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                               ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                               ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                               ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                               ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                               ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
                -- ���o�Ɏ��s�����ꍇ
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_po_un_numbers_info         -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                               ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                               ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                               ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                               ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                               ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                               ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                               ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                               ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                               ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                               ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                               ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                               ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
            END;
--
            -- �O�����㋒�_�R�[�h�擾
            BEGIN
              SELECT past_sale_base_code                                      -- �O�����㋒�_�R�[�h
              INTO   lt_sl_bs_cd_fr_bfr_mnth_dt
              FROM   xxcso_cust_acct_sites_v casv                               -- �ڋq�}�X�^�T�C�g�r���[
                    ,csi_item_instances      ciis                               -- �C���X�g�[���x�[�X�}�X�^
              WHERE  ciis.external_reference     = lv_install_code2
                AND  ciis.owner_party_account_id = casv.cust_account_id
                AND  casv.account_status         = cv_active
                AND  casv.acct_site_status       = cv_active
                AND  casv.party_status           = cv_active
                AND  casv.party_site_status      = cv_active
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- �f�[�^�����݂��Ȃ��ꍇ
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                               ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                               ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                               ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                               ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                               ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                               ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                               ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                               ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                               ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                               ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
                -- ���o�Ɏ��s�����ꍇ
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                               ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                               ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                               ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                               ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                               ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                               ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                               ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                               ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                               ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                               ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                               ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                               ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                               ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                               ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                               ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                               ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                               ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                               ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                             );
                lv_errbuf := lv_errmsg;
                RAISE skip_process_expt;
            END;
--
            -- �����t�@�C���D�@������Ƃɋ@��}�X�^��蓱�o�����@��敪��'1'�i���̋@�j�A
            -- ���v���t�@�C���uXXCSO:���g���_�R�[�h�v�̃T�C�g�l��NULL�ȊO
            IF ((lv_hazard_class = cv_kbn1) AND (gv_withdraw_base_code IS NOT NULL)) THEN
--
              -- �挎���N���̎擾
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���ݒu��ڋq�R�[�h(�v���t�@�C���uXXCSO:���g���_�R�[�h�v�̃T�C�g�l)
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := gv_withdraw_base_code;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���@����(�����t�@�C��.�@����1 [�ғ���])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            -- �����t�@�C���D�@������Ƃɋ@��}�X�^��蓱�o�����@��敪��'1'�i�Y��j�A
            --   ���v���t�@�C���uXXCSO:�Y����g���_�R�[�h�v�̃T�C�g�l��NULL�ȊO
            ELSIF ((lv_hazard_class <> cv_kbn1) AND (gv_jyki_withdraw_base_code IS NOT NULL)) THEN
--
              -- �挎���N���̎擾
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���ݒu��ڋq�R�[�h(�v���t�@�C���uXXCSO:�Y����g���_�R�[�h�v�̃T�C�g�l)
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := gv_jyki_withdraw_base_code;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���@����(�����t�@�C��.�@����1 [�ғ���])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            -- ��L�ȊO
            ELSE
--
              -- �挎���N���̎擾
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���ݒu��ڋq�R�[�h(��ƃf�[�^�D�ڋq�R�[�h�Q�����������Ɏ擾�����ڋq�}�X�^�̑O�����㋒�_�R�[�h)
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := lt_sl_bs_cd_fr_bfr_mnth_dt;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���@����(�����t�@�C��.�@����1 [�ғ���])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := io_inst_base_data_rec.machinery_status1;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            END IF;
          END IF;
        -- ����Ɠ��̔N�����Ɩ��������t�̔N��
        -- ELSIF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM') AND
        --       lv_last_year_month IS NOT NULL) THEN
        ELSIF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')) THEN
--
          -- �����}�X�^�D�挎���N�������ݒ�
          IF (lv_last_year_month IS NULL) THEN
            -- ��ƃf�[�^�D����Ɠ��̔N���������}�X�^�D�������i�ݒu���j�̔N��
            IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_ib_install_date,'YYYYMM')) THEN
              NULL;
            ELSE
          /*2009.09.03 M.Maruyama 0001192�Ή� END*/
--
              -- �挎���N���̎擾
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���ݒu��ڋq�R�[�h(�����}�X�^�ɕR�t���ڋq�R�[�h[�X�V�O�̏��])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_account_num;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
              -- �挎���@����(�����}�X�^.�@����1 [�ғ���])
              l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
              IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
                ln_cnt := ln_cnt + 1;
                l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
                l_ext_attrib_values_tab(ln_cnt).attribute_value       := ln_machinery_status1_wk;
                l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
                l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
              END IF;
--
            END IF;
          /*2009.09.03 M.Maruyama 0001192�Ή� START*/
          ELSE
--
            -- �挎���N���̎擾
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_year_month);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := TO_CHAR(ADD_MONTHS(ld_date , -1 ),'YYYYMM');
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- �挎���ݒu��ڋq�R�[�h(�����}�X�^�ɕR�t���ڋq�R�[�h[�X�V�O�̏��])
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_inst_cust_code);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_account_num;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
            -- �挎���@����(�����t�@�C��.�@����1 [�ғ���])
            l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_last_jotai_kbn);
            IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
              ln_cnt := ln_cnt + 1;
              l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
              l_ext_attrib_values_tab(ln_cnt).attribute_value       := ln_machinery_status1_wk;
              l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
              l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
            END IF;
--
          END IF;
          /*2009.09.03 M.Maruyama 0001192�Ή� END*/
        END IF;
--
      END IF;
--
    /*20090528_Ohtsuki_T1_1203 START*/
    END IF;
    /*20090528_Ohtsuki_T1_1203 END*/
    -- ��Ƌ敪���u�V��ݒu�v�A�u�V���ցv�A�u����ݒu�v�܂��́u�����ցv�A
    -- �������f�[�^�̕����R�[�h����ƃf�[�^�̕����R�[�h�P(�V�ݒu��)�Ɠ���̏ꍇ
    IF ((ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_2 OR
        ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4)
          AND lv_install_code = lv_install_code1) THEN
      -- ============================
      -- 3.�@�ڋq�}�X�^���(�X�V�p)���o
      -- ============================
--
      BEGIN
        SELECT casv.cust_account_id                                   -- �ڋq�A�J�E���gID
              ,casv.party_site_id                                     -- �p�[�e�B�T�C�gID
              ,casv.party_id                                          -- �p�[�e�BID
              ,casv.area_code                                         -- �n��R�[�h
        INTO   ln_account_id
              ,ln_party_site_id
              ,ln_party_id
              ,lv_area_code
       FROM   xxcso_cust_acct_sites_v casv                           -- �ڋq�}�X�^�T�C�g�r���[
        WHERE  casv.account_number    = lv_account_num1
          AND  casv.account_status    = cv_active
          AND  casv.acct_site_status  = cv_active
          AND  casv.party_status      = cv_active
          AND  casv.party_site_status = cv_active
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �f�[�^�����݂��Ȃ��ꍇ
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_24             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_mst_info              -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                         ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
      END;
--
    -- ��Ƌ敪���u�V���ցv�����́u�����ցv�����́u���g�v�A
    -- �������f�[�^�̕����R�[�h����ƃf�[�^�̕����R�[�h�Q(���ݒu��)�Ɠ���ł��邵�A
    ELSIF ((ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4 OR ln_job_kbn = cn_jon_kbn_5)
          AND lv_install_code = lv_install_code2) THEN
--
      -- =======================
      -- 3.�ŏI�ڋq�R�[�h���o
      -- =======================
--
      -- �ڋq�R�[�h
      lv_last_cust_num := lv_account_num;
      -- �A�J�E���gID
      ln_account_id    := ln_account_id;
      -- �p�[�e�B�T�C�gID
      ln_party_site_id := ln_party_site_id;
      -- �p�[�e�BID
      ln_party_id      := ln_party_id;
      -- �n��R�[�h
      lv_area_code     := lv_area_code;
--
      -- �ŏI�ڋq�R�[�h
      l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_ven_kyaku_last);
      IF (l_ext_attrib_rec.attribute_id IS NOT NULL)  THEN 
        ln_cnt := ln_cnt + 1;
        l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
        l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_last_cust_num;
        l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
        l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
      END IF;
--
      -- �@��敪���f1�f�ł��u���g���_�R�[�h�v��NOT NULL�̏ꍇ
      IF (io_inst_base_data_rec.machinery_kbn = cv_kbn1 AND
          gv_withdraw_base_code IS NOT NULL)THEN
        -- �A�J�E���gID�A�p�[�e�B�T�C�gID�A�p�[�e�BID�A�n��R�[�h�̐ݒ�
        ln_account_id     := gn_account_id;
        ln_party_site_id  := gn_party_site_id;
        ln_party_id       := gn_party_id;
        lv_area_code      := gv_area_code;
      -- �@��敪���f1�f�ȊO�ł��u�Y����g���_�R�[�h�v��NOT NULL�ł���ꍇ
      ELSIF (io_inst_base_data_rec.machinery_kbn <> cv_kbn1 AND
             gv_jyki_withdraw_base_code IS NOT NULL) THEN
        -- �A�J�E���gID�A�p�[�e�B�T�C�gID�A�p�[�e�BID�A�n��R�[�h�̐ݒ�
        ln_account_id     := gn_jyki_account_id;
        ln_party_site_id  := gn_jyki_party_site_id;
        ln_party_id       := gn_jyki_party_id;
        lv_area_code      := gv_jyki_area_code;
        --
      /*20090325_yabuki_ST150 START*/
      ELSE
        -- ============================
        -- 3.���g�O�ݒu��ڋq�̔��㋒�_��񒊏o
        -- ============================
        BEGIN
          SELECT casv.account_number                                      -- �ڋq�R�[�h
                ,casv.cust_account_id                                     -- �A�J�E���gID
                ,casv.party_site_id                                       -- �p�[�e�B�T�C�gID
                ,casv.party_id                                            -- �p�[�e�BID
                ,casv.area_code                                           -- �n��R�[�h
          INTO   lv_account_num
                ,ln_account_id
                ,ln_party_site_id
                ,ln_party_id
                ,lv_area_code
          FROM   xxcso_cust_acct_sites_v casv                             -- �ڋq�}�X�^�T�C�g�r���[
          /*2009.09.03 M.Maruyama 0001192�Ή� START*/
          --WHERE  casv.account_number    = lt_sale_base_code
          WHERE  casv.account_number    = (CASE
                                             WHEN TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ld_date,'YYYYMM')
                                             THEN lt_sale_base_code
                                             ELSE lt_past_sale_base_code
                                           END)
          /*2009.09.03 M.Maruyama 0001192�Ή� END*/
            AND  casv.account_status    = cv_active
            AND  casv.acct_site_status  = cv_active
            AND  casv.party_status      = cv_active
            AND  casv.party_site_status = cv_active
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- �f�[�^�����݂��Ȃ��ꍇ
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_cust_base_info             -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         );
            lv_errbuf := lv_errmsg;
            RAISE skip_process_expt;
            -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_cust_base_info             -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                         );
            lv_errbuf := lv_errmsg;
            RAISE skip_process_expt;
        END;
--
      /*20090325_yabuki_ST150 END*/
      END IF;
--
    END IF;
--
    -- �n��R�[�h
    l_ext_attrib_rec := XXCSO_IB_COMMON_PKG.get_ib_ext_attrib_info2(ln_instance_id, cv_ex_chiku_cd);
    IF (l_ext_attrib_rec.attribute_value_id IS NOT NULL)  THEN 
      ln_cnt := ln_cnt + 1;
      l_ext_attrib_values_tab(ln_cnt).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
      l_ext_attrib_values_tab(ln_cnt).attribute_value       := lv_area_code;
      l_ext_attrib_values_tab(ln_cnt).attribute_id          := l_ext_attrib_rec.attribute_id;
      l_ext_attrib_values_tab(ln_cnt).object_version_number := l_ext_attrib_rec.object_version_number;
    END IF;
--
    -- ================================
    -- 4.�C���X�^���X�p�[�e�B��񒊏o
    -- ================================
--
    BEGIN
--
      SELECT cip.instance_party_id                                      -- �C���X�^���X�p�[�e�BID
            ,cip.object_version_number                                  -- �I�u�W�F�N�g�o�[�W����
      INTO   ln_instance_party_id
            ,ln_object_version_number2
      FROM   csi_i_parties cip                                          -- �C���X�^���X�p�[�e�B
      WHERE  cip.instance_id  = io_inst_base_data_rec.instance_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_28             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_inst_party_info           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_29             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_inst_party_info           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    -- ================================
    -- 5.�C���X�^���X�A�J�E���g��񒊏o
    -- ================================
--
    BEGIN
--
      SELECT cipa.ip_account_id                                         -- �C���X�^���X�A�J�E���gID
            ,cipa.object_version_number                                 -- �I�u�W�F�N�g�o�[�W���� 
      INTO   ln_ip_account_id
            ,ln_object_version_number3
      FROM   csi_ip_accounts cipa
      WHERE  cipa.instance_party_id  = ln_instance_party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_28             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_inst_account_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_29             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_inst_account_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
    /* 2009.04.13 K.Satomura T1_0418�Ή� START*/
    -- ================================
    -- ���A�ԍ��}�X�^�r���[���o
    -- ================================
--
    BEGIN
      SELECT SUBSTRB(phcv.hazard_class,1,1) -- �@��敪�i�댯�x�敪�j
      INTO   lv_hazard_class
      FROM   po_un_numbers_vl     punv               -- ���A�ԍ��}�X�^�r���[
            ,po_hazard_classes_vl phcv               -- �댯�x�敪�}�X�^�r���[
      WHERE  punv.un_number        = lv_un_number
        AND  punv.hazard_class_id  = phcv.hazard_class_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_po_un_numbers_info         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
    /* 2009.04.13 K.Satomura T1_0418�Ή� END*/
--
    -- ================================
    -- 6.�C���X�^���X���R�[�h�쐬
    -- ================================
--
    -- �������ҏW
    IF (io_inst_base_data_rec.last_job_cmpltn_date IS NOT NULL) THEN
      /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
      IF  (io_inst_base_data_rec.last_job_cmpltn_date <> cv_day_zero) THEN
      /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */
        ld_install_date := TO_DATE(
                           TO_CHAR(io_inst_base_data_rec.last_job_cmpltn_date), 'yyyy/mm/dd');
      /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
      END IF;
      /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */                           
    END IF; 
    l_instance_rec.instance_id                := ln_instance_id;               -- �C���X�^���XID
    l_instance_rec.external_reference         := lv_install_code;              -- �O���Q��
    /* 2009.06.15 K.Satomura T1_1239�Ή� SATRT */
    IF (io_inst_base_data_rec.completion_kbn = ct_comp_kbn_comp) THEN
    /* 2009.06.15 K.Satomura T1_1239�Ή� END */
      l_instance_rec.inv_master_organization_id := gt_inv_mst_org_id;            -- �݌Ƀ}�X�^�[�g�DID
      l_instance_rec.instance_status_id         := ln_instance_status_id;        -- �C���X�^���X�X�e�[�^�XID
      /* 2009.04.13 K.Satomura T1_0418�Ή� START*/
      --l_instance_rec.instance_type_code         := TO_CHAR(ln_machinery_kbn);    -- �C���X�^���X�^�C�v�R�[�h
      l_instance_rec.instance_type_code         := TO_CHAR(lv_hazard_class);    -- �C���X�^���X�^�C�v�R�[�h
      /* 2009.04.13 K.Satomura T1_0418�Ή� END*/
      IF (ln_party_site_id IS NOT NULL) THEN
        l_instance_rec.location_type_code       := cv_location_type_code;        -- ���s���Ə��^�C�v
        l_instance_rec.location_id              := ln_party_site_id;             -- ���s���Ə�ID
      END IF;
      IF (ln_job_kbn = cn_jon_kbn_1 OR ln_job_kbn = cn_jon_kbn_2 OR
          ln_job_kbn = cn_jon_kbn_3 OR ln_job_kbn = cn_jon_kbn_4 OR
          ln_job_kbn = cn_jon_kbn_5) THEN
        /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� START */
        IF ld_install_date IS NOT NULL THEN
          l_instance_rec.install_date             := ld_install_date;              -- ������
        END IF;
        /* 2009.11.29 T.Maruyama E_�{�ғ�_00120�Ή� END */
      END IF;
      l_instance_rec.attribute1                 := lv_un_number;                 -- �@��(�R�[�h)
      l_instance_rec.attribute2                 := lv_install_number;            -- �@��
      /* 2009.05.26 M.Ohtsuki T1_1141�Ή� START*/
      IF (io_inst_base_data_rec.new_old_flg = cv_flg_yes) THEN                                        -- �V�Ñ�t���O��Y�̏ꍇ
        l_instance_rec.attribute3 := TO_CHAR(TO_DATE(TO_CHAR(
          io_inst_base_data_rec.first_install_date),'yyyy/mm/dd'), 'yyyy/mm/dd hh24:mi:ss'); -- ����ݒu��
      END IF;
      /* 2009.05.26 M.Ohtsuki T1_1141�Ή� END*/
      l_instance_rec.attribute4                 := cv_flg_no;                    -- ��ƈ˗����t���O
      l_instance_rec.attribute5                 := cv_flg_no;                    -- �V�Ñ�t���O
      IF (io_inst_base_data_rec.po_req_number IS NOT NULL AND
          io_inst_base_data_rec.po_req_number <> 0) THEN
        l_instance_rec.attribute6                 := io_inst_base_data_rec.po_req_number;  -- �ŏI�����˗��ԍ�
      END IF;
    /* 2009.06.15 K.Satomura T1_1239�Ή� SATRT */
    ELSE
      l_instance_rec.attribute4 := cv_flg_no; -- ��ƈ˗����t���O
      --
    END IF;
    /* 2009.06.15 K.Satomura T1_1239�Ή� END */
    l_instance_rec.object_version_number      := 
      io_inst_base_data_rec.object_version1;                                   -- �I�u�W�F�N�g�o�[�W�����ԍ�
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
--
    -- ====================
    -- 7.�p�[�e�B�f�[�^�쐬
    -- ====================
--
    IF (ln_party_id IS NOT NULL) THEN
      ln_cnt := 1;
      l_party_tab(ln_cnt).instance_party_id        := ln_instance_party_id;
      l_party_tab(ln_cnt).party_source_table       := cv_party_source_table;
      l_party_tab(ln_cnt).party_id                 := ln_party_id;
      l_party_tab(ln_cnt).relationship_type_code   := cv_relatnsh_type_code;
      l_party_tab(ln_cnt).contact_flag             := cv_flg_no;
      l_party_tab(ln_cnt).object_version_number    := ln_object_version_number2;
    END IF;
--
    -- ===============================
    -- 8.�p�[�e�B�A�J�E���g�f�[�^�쐬
    -- ===============================
--
    IF (ln_account_id IS NOT NULL) THEN
      ln_cnt := 1;
      l_account_tab(ln_cnt).ip_account_id          := ln_ip_account_id;
      l_account_tab(ln_cnt).instance_party_id      := ln_instance_party_id;
      l_account_tab(ln_cnt).parent_tbl_index       := cn_num1;
      l_account_tab(ln_cnt).party_account_id       := ln_account_id;
      l_account_tab(ln_cnt).relationship_type_code := cv_relatnsh_type_code;
      l_account_tab(ln_cnt).object_version_number  := ln_object_version_number3;
    END IF;
--
    -- ===============================
    -- 9.������R�[�h�f�[�^�쐬
    -- ===============================
--
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;
--
    -- =================================
    -- 10.�W��API���A�����X�V�������s��
    -- =================================
--
    BEGIN
--
      CSI_ITEM_INSTANCE_PUB.update_item_instance(
         p_api_version           => cn_api_version
        ,p_commit                => lv_commit
        ,p_init_msg_list         => lv_init_msg_list
        ,p_validation_level      => ln_validation_level
        ,p_instance_rec          => l_instance_rec
        ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
        ,p_party_tbl             => l_party_tab
        ,p_account_tbl           => l_account_tab
        ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
        ,p_org_assignments_tbl   => l_org_assignments_tab
        ,p_asset_assignment_tbl  => l_asset_assignment_tab
        ,p_txn_rec               => l_txn_rec
        ,x_instance_id_lst       => l_instance_id_lst
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      -- ����I���łȂ��ꍇ
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE update_error_expt;
      END IF;
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        IF (FND_MSG_PUB.Count_Msg > 0) THEN
          FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
            FND_MSG_PUB.Get(
               p_msg_index     => i
              ,p_encoded       => cv_encoded_f
              ,p_data          => lv_io_msg_data
              ,p_msg_index_out => ln_io_msg_count
            );
            lv_msg_data := lv_msg_data || lv_io_msg_data;
          END LOOP;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1  => cv_inst_base_insert           -- �g�[�N���l1
                       ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                       ,iv_token_value2  => cv_update_process             -- �g�[�N���l2
                       ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                       ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                       ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                       ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                       ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                       ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                       ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                       ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                       ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                       ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                       ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                       ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                       ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                       ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                       ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                       ,iv_token_value10 => lv_msg_data                   -- �g�[�N���l10
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--  
  EXCEPTION
    -- *** �X�L�b�v������O�n���h�� ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      -- �X�V���s���[���o�b�N�t���O�̐ݒ�B
      gb_rollback_flg := TRUE;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END update_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : update_cust_or_party
   * Description      : �ڋq�A�h�I���}�X�^�ƃp�[�e�B�}�X�^�X�V���� (A-10)
   ***********************************************************************************/
  PROCEDURE update_cust_or_party(
     io_inst_base_data_rec   IN OUT NOCOPY g_get_data_rtype -- (IN)�����}�X�^���
    ,id_process_date         IN     DATE                    -- �Ɩ��������t
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cust_or_party'; -- �v���O������
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
    cv_no                      CONSTANT  VARCHAR2(1)     := 'N';
    cv_yes                     CONSTANT  VARCHAR2(1)     := 'Y';
    cv_cust_status30           CONSTANT  VARCHAR2(30)    := '30';   -- ���F��
    cv_cust_status40           CONSTANT  VARCHAR2(30)    := '40';   -- �ڋq
    cv_cust_status50           CONSTANT  VARCHAR2(30)    := '50';   -- �x�~
    cv_business_low_type_24    CONSTANT  VARCHAR2(2)     := '24';   -- �t���T�[�r�X(����)VD
    cv_business_low_type_25    CONSTANT  VARCHAR2(2)     := '25';   -- �t���T�[�r�XVD
    cv_business_low_type_27    CONSTANT  VARCHAR2(2)     := '27';   -- (����)VD
    cv_update_process1         CONSTANT  VARCHAR2(100)   := '�X�V�i�ڋq�X�e�[�^�X�F�u50(�x�~)�v���u40(�ڋq)�v�j';
    cv_update_process2         CONSTANT  VARCHAR2(100)   := '�X�V�i�ڋq�X�e�[�^�X�F�u30(���F��)�v���u40(�ڋq)�v�j';
    cv_party_info              CONSTANT  VARCHAR2(100)   := '�p�[�e�B�}�X�^���';
    cv_hz_parties              CONSTANT  VARCHAR2(100)   := '�p�[�e�B�}�X�^';
    cv_party_name_info         CONSTANT  VARCHAR2(100)   := '�ڋq�}�X�^�T�C�g�r���[�̌ڋq��';
    cv_xxcmm_cust_accounts     CONSTANT  VARCHAR2(100)   := '�ڋq�A�h�I���}�X�^';
    cv_xca_business_low_type   CONSTANT  VARCHAR2(100)   := '�ڋq�A�h�I���}�X�^�̋Ƒԏ�����';
    cv_xca_cnvs_date           CONSTANT  VARCHAR2(100)   := '�ڋq�A�h�I���}�X�^�̌ڋq�l����';
    cv_up_cnvs_process         CONSTANT  VARCHAR2(100)   := '�X�V�i�ڋq�l�����j';
    /*20090507_mori_T1_0439 START*/
    cv_instance_type_code      CONSTANT  VARCHAR2(100)   := '�C���X�^���X�^�C�v�R�[�h';
    /*20090507_mori_T1_0439 END*/
    /* 2009.09.14 K.Satomura 0001335�Ή� START */
    ct_cust_cl_cd_round        CONSTANT hz_cust_accounts.customer_class_code%TYPE := '15'; -- �ڋq�敪=����
    cv_cust_class_code         CONSTANT VARCHAR2(100)    := '�ڋq�敪';
    /* 2009.09.14 K.Satomura 0001335�Ή� END */
--
    -- *** ���[�J���ϐ� ***
    ld_cnvs_date               DATE;                    -- �ڋq�l����
    ln_seq_no                  NUMBER;                  -- �V�[�P���X�ԍ�
    ln_slip_num                NUMBER;                  -- �`�[No.
    ln_slip_branch_num         NUMBER;                  -- �`�[�}��
    ln_line_num                NUMBER;                  -- �s��
    ln_job_kbn                 NUMBER;                  -- ��Ƌ敪
    ln_party_id                NUMBER;                  -- �p�[�e�BID
    ln_object_ver_num          NUMBER;                  -- �I�u�W�F�N�g�o�[�W����
    ln_count                   NUMBER;                  -- �擾�J�E���g
    ln_customer_id             NUMBER;                  -- �ڋqID 
    lv_install_code            VARCHAR2(10);            -- �����R�[�h
    lv_install_code1           VARCHAR2(10);            -- �����R�[�h�P
    lv_install_code2           VARCHAR2(10);            -- �����R�[�h�Q
    lv_account_num1            VARCHAR2(10);            -- �ڋq�R�[�h�P
    lv_account_num2            VARCHAR2(10);            -- �ڋq�R�[�h�Q
    lv_party_name              VARCHAR2(360);           -- �ڋq��
    lv_init_msg_list           VARCHAR2(2000);          -- ���b�Z�[�W���X�g
    lv_last_job_cmpltn_date    VARCHAR2(20);            -- �ŏI��Ɗ�����
    lb_goto_flg                BOOLEAN;                 -- ���������t���O
    ld_actual_work_date        DATE;                    -- ����Ɠ�
    /*20090507_mori_T1_0439 START*/
    lv_instance_type_code     csi_item_instances.instance_type_code%TYPE;       -- �C���X�^���X�^�C�v�R�[�h
    /*20090507_mori_T1_0439 END*/
    
--
    -- �߂�l�i�[�p
    ln_profile_id              NUMBER;                  -- �v���t�@�C��ID
    lv_return_status           VARCHAR2(10);            -- �߂�l�X�e�[�^�X
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;

--
    -- API���o�̓��R�[�h�l�i�[�p
    l_party_rec                hz_party_v2pub.party_rec_type;
    l_organization_rec         hz_party_v2pub.organization_rec_type;
--
    -- *** ���[�J����O ***
    skip_process_expt          EXCEPTION;
    update_error_expt          EXCEPTION;
    /*20090507_mori_T1_0439 START*/
    instance_type_expt         EXCEPTION;  -- �Ώە��������̋@�ȊO�ł���ꍇ
    /*20090507_mori_T1_0439 END*/
    /* 2009.09.14 K.Satomura 0001335�Ή� START */
    lt_customer_class_code     hz_cust_accounts.customer_class_code%TYPE;
    /* 2009.09.14 K.Satomura 0001335�Ή� END */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--  
    -- �f�[�^�̊i�[
    lv_init_msg_list      := fnd_api.g_true;
    ln_seq_no             := io_inst_base_data_rec.seq_no;
    ln_slip_num           := io_inst_base_data_rec.slip_no;
    ln_slip_branch_num    := io_inst_base_data_rec.slip_branch_no;
    ln_line_num           := io_inst_base_data_rec.line_number;
    ln_job_kbn            := io_inst_base_data_rec.job_kbn;
    lv_install_code       := io_inst_base_data_rec.install_code;
    lv_install_code1      := io_inst_base_data_rec.install_code1;
    lv_install_code2      := io_inst_base_data_rec.install_code2;
    lv_account_num1       := io_inst_base_data_rec.account_number1;
    lv_account_num2       := io_inst_base_data_rec.account_number2;
    ld_actual_work_date   := TO_DATE(io_inst_base_data_rec.actual_work_date,'YYYY/MM/DD');
    lb_goto_flg           := FALSE;
  /*20090507_mori_T1_0439 START*/
    -- �Ώە����̃C���X�^���X�^�C�v�R�[�h�擾
    BEGIN
      SELECT ciins.instance_type_code  instance_type_code             -- �C���X�^���X�^�C�v�R�[�h
      INTO   lv_instance_type_code                                    -- �C���X�^���X�^�C�v�R�[�h
      FROM   csi_item_instances ciins                                 -- �����}�X�^
      WHERE  ciins.external_reference = lv_install_code
      ;
--
      -- �Ώە��������̋@�ȊO�ł���ꍇ�A�ȍ~�̏������s��Ȃ�
      IF (lv_instance_type_code <> cv_instance_type_vd) THEN
        RAISE instance_type_expt;
      END IF;
      /* 2009.09.14 K.Satomura 0001335�Ή� START */
      BEGIN
        SELECT hca.customer_class_code customer_class_code -- �ڋq�敪
        INTO   lt_customer_class_code
        FROM   csi_item_instances cii -- �����}�X�^
              ,hz_cust_accounts   hca -- �ڋq�}�X�^
        WHERE  cii.external_reference     = lv_install_code
        AND    cii.owner_party_account_id = hca.cust_account_id
        ;
        --
        -- �ڋq�敪��15(����)�̏ꍇ�A�ȍ~�̏������s��Ȃ�
        IF (lt_customer_class_code = ct_cust_cl_cd_round) THEN
          RAISE instance_type_expt;
          --
        END IF;
        --
      EXCEPTION
        WHEN instance_type_expt THEN
          RAISE instance_type_expt;
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_19   -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm     -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_cust_class_code -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_bukken      -- �g�[�N���R�[�h2
                         ,iv_token_value2 => lv_install_code    -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_errmsg      -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM            -- �g�[�N���l3
                       );
          lv_errbuf := lv_errmsg;
          RAISE skip_process_expt;
          --
      END;
      /* 2009.09.14 K.Satomura 0001335�Ή� END */
    EXCEPTION
      WHEN instance_type_expt THEN
        RAISE instance_type_expt;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_19             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm               -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_instance_type_code        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => lv_install_code              -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_errmsg                -- �g�[�N���R�[�h3
                       ,iv_token_value3 => SQLERRM                      -- �g�[�N���l3
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
  /*20090507_mori_T1_0439 END*/
--
    /* 2009.08.28 K.Satomura 0001205�Ή� START */
    -- ==========================
    -- AR��v���ԃN���[�Y�`�F�b�N
    -- ==========================
    gv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
                      id_standard_date => ld_actual_work_date
                   );
    --
    IF (gv_chk_rslt = cv_true) THEN
      gv_chk_rslt_flag := 'N';
      --
    ELSE
      gv_chk_rslt_flag := 'C';
      --
    END IF;
    --
    /* 2009.08.28 K.Satomura 0001205�Ή� END */
    -- ��Ƌ敪���u1.�V��ݒu�v�A�u3.�V���ցv�A�u2. ����ݒu�v�A�܂��́u4.�����ցv�ŁA
    -- �����f�[�^�̕����R�[�h����ƃf�[�^�̕����R�[�h�P(�V�ݒu��)�Ɠ���̏ꍇ�A
    -- �ڋq�X�e�[�^�X�i�x�~���ڋq�j�X�V�̏������s���B
    IF((ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn2 OR
        ln_job_kbn = cn_work_kbn3 OR ln_job_kbn = cn_work_kbn4)
        AND lv_install_code = NVL(lv_install_code1, ' '))
    THEN
      -- 1.DUNS(�ڋq�X�e�[�^�X)�u'50'(�x�~)�v���u'40'(�ڋq)�v
      BEGIN
        -- �@�ڋq���̎擾
        SELECT xcav.party_name                                            -- �ڋq��
        INTO   lv_party_name
        FROM   xxcso_cust_accounts_v xcav                                 -- �ڋq�}�X�^�r���[
        WHERE  xcav.account_number = lv_account_num1
          AND  xcav.account_status = cv_active
          AND  xcav.party_status   = cv_active
        ;
      EXCEPTION
        -- �f�[�^�Ȃ��ꍇ�̗�O
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_party_name_info            -- �g�[�N���l1
                         ,iv_token_name2   => cv_tkn_seq_no                -- �g�[�N���R�[�h2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)           -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_party_name_info            -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                         ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
      BEGIN
        -- �A�p�[�e�BID���擾
        SELECT hp.party_id                                                 -- �p�[�e�BID
              ,hp.object_version_number                                    -- �I�u�W�F�N�g�o�[�W����
        INTO   ln_party_id
              ,ln_object_ver_num
        FROM   hz_cust_accounts hca                                        -- �ڋq�}�X�^
              ,hz_parties       hp                                         -- �p�[�e�B�}�X�^
        WHERE  hca.account_number = lv_account_num1
          AND  hca.party_id       = hp.party_id
          AND  hca.status         = cv_active
          AND  hp.status          = cv_active
          AND  hp.duns_number_c   = cv_cust_status50
        FOR UPDATE OF hp.party_id NOWAIT
        ;
--
      EXCEPTION
        -- �f�[�^�Ȃ��ꍇ�̗�O
        WHEN NO_DATA_FOUND THEN
          lb_goto_flg := TRUE;
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_hz_parties                 -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_party_info                 -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                         ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                         ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                         ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                         ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                         ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                         ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                         ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                         ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                         ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                         ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--

      -- ���������t���O���uFALSE�v(�u'50'(�x�~)�v���u'40'(�ڋq)�v�̌ڋq��񂪂���)
      IF (lb_goto_flg = FALSE) THEN
        -- �B�p�[�e�B���R�[�h�̍쐬
        l_party_rec.party_id := ln_party_id;                                 -- �p�[�e�BID
--
        -- �C�ڋq��񃌃R�[�h�̍쐬
        l_organization_rec.organization_name := lv_party_name;               -- �ڋq��
        l_organization_rec.duns_number_c     := cv_cust_status40;            -- �u40�D�ڋq�v
        l_organization_rec.party_rec         := l_party_rec;                 -- �p�[�e�B���R�[�h
--
        BEGIN
--
          -- �D�W��API���p�[�e�B�}�X�^���X�V����B
          hz_party_v2pub.update_organization(
             p_init_msg_list               => lv_init_msg_list
            ,p_organization_rec            => l_organization_rec
            ,p_party_object_version_number => ln_object_ver_num
            ,x_profile_id                  => ln_profile_id
            ,x_return_status               => lv_return_status
            ,x_msg_count                   => ln_msg_count
            ,x_msg_data                    => lv_msg_data
          );
        EXCEPTION
          -- *** OTHERS��O�n���h�� ***
          WHEN OTHERS THEN
            IF (FND_MSG_PUB.Count_Msg > 0) THEN
              FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
                FND_MSG_PUB.Get(
                   p_msg_index     => i
                  ,p_encoded       => cv_encoded_f
                  ,p_data          => lv_io_msg_data
                  ,p_msg_index_out => ln_io_msg_count
                );
                lv_msg_data := lv_msg_data || lv_io_msg_data;
              END LOOP;
            END IF;
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                           ,iv_token_value1  => cv_hz_parties                 -- �g�[�N���l1
                           ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                           ,iv_token_value2  => cv_update_process1            -- �g�[�N���l2
                           ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                           ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                           ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                           ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                           ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                           ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                           ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10 => lv_msg_data                   -- �g�[�N���l10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
            gv_chk_rslt_flag = 'N') THEN
          -- �ڋq�A�h�I���}�X�^�̃��b�N����
          BEGIN
--
            SELECT xca.cnvs_date                                             -- �ڋq�l����
            INTO   ld_cnvs_date
            FROM   xxcmm_cust_accounts    xca                                -- �ڋq�A�h�I���}�X�^
            WHERE  xca.customer_code = lv_account_num1
            FOR UPDATE NOWAIT
            ;
--
          EXCEPTION
            WHEN global_lock_expt THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_xxcmm_cust_accounts        -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_xca_cnvs_date              -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
          END;
--
          BEGIN
--
            UPDATE xxcmm_cust_accounts                                      -- �ڋq�A�h�I���}�X�^
            SET    past_customer_status   = cv_cust_status50,               -- �O���ڋq�X�e�[�^�X
                   last_updated_by        = cn_last_updated_by,
                   last_update_date       = cd_last_update_date,
                   last_update_login      = cn_last_update_login,
                   request_id             = cn_request_id,
                   program_application_id = cn_program_application_id,
                   program_id             = cn_program_id,
                   program_update_date    = cd_program_update_date
            WHERE  customer_code = lv_account_num1
            ;
          EXCEPTION
          -- *** OTHERS��O�n���h�� ***
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                           ,iv_token_value1  => cv_xxcmm_cust_accounts        -- �g�[�N���l1
                           ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                           ,iv_token_value2  => cv_up_cnvs_process            -- �g�[�N���l2
                           ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                           ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                           ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                           ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                           ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                           ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                           ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10 => SQLERRM                       -- �g�[�N���l10
                         );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          -- �ڋq�X�e�[�^�X�u�x�~�v�X�V�t���O���uTRUE�v�ɐݒ�
          gb_cust_status_free_flg := TRUE;
        END IF;
--
      END IF;  
    END IF;
-- 
    -- ��Ƌ敪���u1.�V��ݒu�v�܂��́u2.����ݒu�v�ꍇ
    IF (ln_job_kbn = cn_work_kbn1 OR ln_job_kbn = cn_work_kbn2) THEN
--
      -- 2.DUNS(�ڋq�X�e�[�^�X)�u'30'(���F��)�v���u'40'(�ڋq)�v
      BEGIN
        -- �@�Ƒԏ����ނ̃`�F�b�N
        SELECT COUNT(*)                                                    -- ����
        INTO   ln_count
        FROM   xxcso_cust_accounts_v xcav                                  -- �ڋq�}�X�^�r���[
        WHERE  xcav.account_number = lv_account_num1
          AND  xcav.account_status = cv_active
          AND  xcav.party_status   = cv_active
          AND  xcav.business_low_type IN ( cv_business_low_type_24
                                          ,cv_business_low_type_25
                                          ,cv_business_low_type_27)
        ;
      EXCEPTION
          -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                             ,iv_token_value1 => cv_xca_cnvs_date              -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                             ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                             ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                             ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                             ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                             ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                             ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                             ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                             ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                             ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                             ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                             ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                       );
          lv_errbuf := lv_errmsg;
          RAISE update_error_expt;
      END;
--
      -- �f�[�^������ꍇ
      IF(ln_count IS NOT NULL AND ln_count > 0) THEN
--
        -- �A�ڋq�l�����̃`�F�b�N
        BEGIN
--
          SELECT xca.cnvs_date                                             -- �ڋq�l����
                ,xca.customer_id                                           -- �ڋqID
          INTO   ld_cnvs_date
                ,ln_customer_id
          FROM   xxcmm_cust_accounts   xca                                 -- �ڋq�A�h�I���}�X�^
                ,hz_cust_accounts      hca                                 -- �ڋq�}�X�^
          WHERE  hca.account_number  = lv_account_num1
            AND  hca.cust_account_id = xca.customer_id
            AND  hca.status          = cv_active
          ;
--
        EXCEPTION
          -- �f�[�^�Ȃ��ꍇ�̗�O
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_xca_cnvs_date              -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
          -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                             ,iv_token_value1 => cv_xca_cnvs_date              -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                             ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                             ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                             ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                             ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                             ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                             ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                             ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                             ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                             ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                             ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                             ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        -- �ڋq�l�������ݒ肳��ĂȂ��ꍇ
        IF (ld_cnvs_date IS NULL) AND
           (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                gv_chk_rslt_flag = 'C') OR
            ((TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                      gv_chk_rslt_flag = 'N') OR
             (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(id_process_date ,'YYYYMM'))
            )
         THEN 
          -- �ڋq�A�h�I���}�X�^�̃��b�N����
          BEGIN
--
            SELECT xca.cnvs_date                                             -- �ڋq�l����
            INTO   ld_cnvs_date
            FROM   xxcmm_cust_accounts    xca                                -- �ڋq�A�h�I���}�X�^
            WHERE  xca.customer_code = lv_account_num1
            FOR UPDATE NOWAIT
            ;
--
          EXCEPTION
            WHEN global_lock_expt THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                             ,iv_token_value1 => cv_xxcmm_cust_accounts        -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                             ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                             ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                             ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                             ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                             ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                             ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                             ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                             ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                             ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
            -- ���o�Ɏ��s�����ꍇ
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                             ,iv_token_value1 => cv_xca_cnvs_date              -- �g�[�N���l1
                             ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                             ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                             ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                             ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                             ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                             ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                             ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                             ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                             ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                             ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                             ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                             ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                             ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                             ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                             ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                             ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                             ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                             ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          BEGIN
--
            -- ����Ɠ��̔N�����Ɩ��������t�̑O���̔N������AR��v���ԃ`�F�b�N�t���O���N���[�Y
            IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                gv_chk_rslt_flag = 'C') THEN
              UPDATE xxcmm_cust_accounts                                         -- �ڋq�A�h�I���}�X�^
              SET    cnvs_date = id_process_date,    -- �ڋq�l����
                     last_updated_by        = cn_last_updated_by,
                     last_update_date       = cd_last_update_date,
                     last_update_login      = cn_last_update_login,
                     request_id             = cn_request_id,
                     program_application_id = cn_program_application_id,
                     program_id             = cn_program_id,
                     program_update_date    = cd_program_update_date
              WHERE  customer_code = lv_account_num1
              ;
            -- ����Ɠ��̔N�����Ɩ��������t�̑O���̔N������AR��v���ԃ`�F�b�N�t���O���I�[�v���܂��͎���Ɠ��̔N�����Ɩ��������t�̔N��
            ELSIF ((TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                    gv_chk_rslt_flag = 'N') OR
                   (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(id_process_date ,'YYYYMM'))
                  ) THEN
              UPDATE xxcmm_cust_accounts                                         -- �ڋq�A�h�I���}�X�^
              SET    cnvs_date = ld_actual_work_date,    -- �ڋq�l����
                     last_updated_by        = cn_last_updated_by,
                     last_update_date       = cd_last_update_date,
                     last_update_login      = cn_last_update_login,
                     request_id             = cn_request_id,
                     program_application_id = cn_program_application_id,
                     program_id             = cn_program_id,
                     program_update_date    = cd_program_update_date
              WHERE  customer_code = lv_account_num1
              ;
            END IF;

          EXCEPTION
            -- *** OTHERS��O�n���h�� ***
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                             ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                             ,iv_token_value1  => cv_xxcmm_cust_accounts        -- �g�[�N���l1
                             ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                             ,iv_token_value2  => cv_up_cnvs_process            -- �g�[�N���l2
                             ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                             ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                             ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                             ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                             ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                             ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                             ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                             ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                             ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                             ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                             ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                             ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                             ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                             ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                             ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                             ,iv_token_value10 => SQLERRM                       -- �g�[�N���l10
                           );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          -- �ڋq�l�����X�V�t���O���uTRUE�v�ɐݒ�
          gb_cust_cnv_upd_flg := TRUE;
        END IF;
--
        BEGIN
          -- �B�ڋq���̎擾
          SELECT xcav.party_name                                                -- �ڋq��
          INTO   lv_party_name
          FROM   xxcso_cust_accounts_v xcav                                     -- �ڋq�}�X�^�r���[
          WHERE  xcav.account_number = lv_account_num1
            AND  xcav.account_status = cv_active
            AND  xcav.party_status   = cv_active
          ;
        EXCEPTION
          -- �f�[�^�Ȃ��ꍇ�̗�O
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_23              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_party_name_info            -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
--
          -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_party_name_info            -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        -- ���������t���O������
        lb_goto_flg             := FALSE;
--
        BEGIN
          -- �C�p�[�e�BID���擾
          SELECT hp.party_id                                                 -- �p�[�e�BID
                ,hp.object_version_number                                    -- �I�u�W�F�N�g�o�[�W����
          INTO   ln_party_id
                ,ln_object_ver_num
          FROM   hz_cust_accounts hca                                        -- �ڋq�}�X�^
                ,hz_parties       hp                                         -- �p�[�e�B�}�X�^
          WHERE  hca.account_number = lv_account_num1
            AND  hca.party_id       = hp.party_id
            AND  hca.status         = cv_active
            AND  hp.status          = cv_active
            AND  hp.duns_number_c   = cv_cust_status30
          FOR UPDATE OF hp.party_id NOWAIT
          ;
--
        EXCEPTION
          -- �f�[�^�Ȃ��ꍇ�̗�O
          WHEN NO_DATA_FOUND THEN
            -- ���������t���O���uTRUE�v�ɐݒ�
            lb_goto_flg := TRUE;
          -- ���b�N���s�����ꍇ�̗�O
          WHEN global_lock_expt THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_hz_parties                 -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
            -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_party_info                 -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                         );
            lv_errbuf := lv_errmsg;
            RAISE update_error_expt;
        END;
--
        -- ���������t���O���uFALSE�v�i�u'30'(���F��)�v���u'40'(�ڋq)�v�̌ڋq��񂪂���j
        IF (lb_goto_flg = FALSE) THEN
          -- �D�p�[�e�B���R�[�h�̍쐬
          l_party_rec.party_id := ln_party_id;                                 -- �p�[�e�BID
--
          -- �E�ڋq��񃌃R�[�h�̍쐬
          l_organization_rec.organization_name := lv_party_name;               -- �ڋq��
          l_organization_rec.duns_number_c     := cv_cust_status40;            -- �u40�D�ڋq�v
          l_organization_rec.party_rec         := l_party_rec;                 -- �p�[�e�B���R�[�h
--
          BEGIN
            -- �F�W��API���p�[�e�B�}�X�^���X�V����B
            hz_party_v2pub.update_organization(
               p_init_msg_list               => lv_init_msg_list
              ,p_organization_rec            => l_organization_rec
              ,p_party_object_version_number => ln_object_ver_num
              ,x_profile_id                  => ln_profile_id
              ,x_return_status               => lv_return_status
              ,x_msg_count                   => ln_msg_count
              ,x_msg_data                    => lv_msg_data
            );
          EXCEPTION
            -- *** OTHERS��O�n���h�� ***
            WHEN OTHERS THEN
              IF (FND_MSG_PUB.Count_Msg > 0) THEN
                FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
                  FND_MSG_PUB.Get(
                     p_msg_index     => i
                    ,p_encoded       => cv_encoded_f
                    ,p_data          => lv_io_msg_data
                    ,p_msg_index_out => ln_io_msg_count
                  );
                  lv_msg_data := lv_msg_data || lv_io_msg_data;
                END LOOP;
              END IF;
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                             ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                             ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                             ,iv_token_value1  => cv_hz_parties                 -- �g�[�N���l1
                             ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                             ,iv_token_value2  => cv_update_process2            -- �g�[�N���l2
                             ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                             ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                             ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                             ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                             ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                             ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                             ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                             ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                             ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                             ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                             ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                             ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                             ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                             ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                             ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                             ,iv_token_value10 => lv_msg_data                   -- �g�[�N���l10
                          );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
          END;
--
          IF (TO_CHAR(ld_actual_work_date,'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
              gv_chk_rslt_flag = 'N') THEN
            -- �ڋq�A�h�I���}�X�^�̃��b�N����
            BEGIN
--
              SELECT xca.cnvs_date                                             -- �ڋq�l����
              INTO   ld_cnvs_date
              FROM   xxcmm_cust_accounts    xca                                -- �ڋq�A�h�I���}�X�^
              WHERE  xca.customer_code = lv_account_num1
              FOR UPDATE NOWAIT
              ;
--
            EXCEPTION
              WHEN global_lock_expt THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_27              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_xxcmm_cust_accounts        -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           );
                lv_errbuf := lv_errmsg;
                RAISE update_error_expt;
            -- ���o�Ɏ��s�����ꍇ
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_24              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_xca_cnvs_date              -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                           ,iv_token_value2 => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                           ,iv_token_value3 => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                           ,iv_token_name4  => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                           ,iv_token_value4 => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                           ,iv_token_name5  => cv_tkn_line_num               -- �g�[�N���R�[�h5
                           ,iv_token_value5 => TO_CHAR(ln_line_num)          -- �g�[�N���l5
                           ,iv_token_name6  => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6 => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7  => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7 => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8  => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8 => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9  => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9 => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10 => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10=> SQLERRM                       -- �g�[�N���l10
                         );
              lv_errbuf := lv_errmsg;
              RAISE update_error_expt;
            END;
--
            BEGIN
--
              UPDATE xxcmm_cust_accounts                                      -- �ڋq�A�h�I���}�X�^
              SET    past_customer_status   = cv_cust_status30,               -- �O���ڋq�X�e�[�^�X
                     last_updated_by        = cn_last_updated_by,
                     last_update_date       = cd_last_update_date,
                     last_update_login      = cn_last_update_login,
                     request_id             = cn_request_id,
                     program_application_id = cn_program_application_id,
                     program_id             = cn_program_id,
                     program_update_date    = cd_program_update_date
              WHERE  customer_code = lv_account_num1
              ;
            EXCEPTION
            -- *** OTHERS��O�n���h�� ***
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                           ,iv_name          => cv_tkn_number_25              -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1   => cv_tkn_table                  -- �g�[�N���R�[�h1
                           ,iv_token_value1  => cv_xxcmm_cust_accounts        -- �g�[�N���l1
                           ,iv_token_name2   => cv_tkn_process                -- �g�[�N���R�[�h2
                           ,iv_token_value2  => cv_up_cnvs_process            -- �g�[�N���l2
                           ,iv_token_name3   => cv_tkn_seq_no                 -- �g�[�N���R�[�h3
                           ,iv_token_value3  => TO_CHAR(ln_seq_no)            -- �g�[�N���l3
                           ,iv_token_name4   => cv_tkn_slip_num               -- �g�[�N���R�[�h4
                           ,iv_token_value4  => TO_CHAR(ln_slip_num)          -- �g�[�N���l4
                           ,iv_token_name5   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h5
                           ,iv_token_value5  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l5
                           ,iv_token_name6   => cv_tkn_bukken1                -- �g�[�N���R�[�h6
                           ,iv_token_value6  => lv_install_code1              -- �g�[�N���l6
                           ,iv_token_name7   => cv_tkn_bukken2                -- �g�[�N���R�[�h7
                           ,iv_token_value7  => lv_install_code2              -- �g�[�N���l7
                           ,iv_token_name8   => cv_tkn_account_num1           -- �g�[�N���R�[�h8
                           ,iv_token_value8  => lv_account_num1               -- �g�[�N���l8
                           ,iv_token_name9   => cv_tkn_account_num2           -- �g�[�N���R�[�h9
                           ,iv_token_value9  => lv_account_num2               -- �g�[�N���l9
                           ,iv_token_name10  => cv_tkn_errmsg                 -- �g�[�N���R�[�h10
                           ,iv_token_value10 => SQLERRM                       -- �g�[�N���l10
                         );
                lv_errbuf := lv_errmsg;
                RAISE update_error_expt;
            END;
            -- �ڋq�X�e�[�^�X�u���F�ρv�X�V�t���O���uTRUE�v�ɐݒ�
            gb_cust_status_appr_flg  := TRUE;
          END IF;
--
        END IF;
--
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v������O�n���h�� ***
    WHEN skip_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** �X�V���s��O�n���h�� ***
    WHEN update_error_expt THEN
      -- �X�V���s���[���o�b�N�t���O�̐ݒ�B
      gb_rollback_flg := TRUE;
--      
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
  /*20090507_mori_T1_0439 START*/
--
    -- *** ���̋@�ȊO�X�L�b�v������O�n���h�� ***
    WHEN instance_type_expt THEN
      -- �����Ȃ�
      NULL;
  /*20090507_mori_T1_0439 END*/
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
  END update_cust_or_party;
--
--
   /**********************************************************************************
   * Procedure Name   : delete_in_item_data
   * Description      : �����f�[�^���[�N�e�[�u���폜����(A-12)
   ***********************************************************************************/
  PROCEDURE delete_in_item_data(
     ov_errbuf               OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_in_item_data';  -- �v���O������
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
    cv_no                    CONSTANT  VARCHAR2(1)    := 'N';
    cv_yes                   CONSTANT  VARCHAR2(1)    := 'Y';
    cv_table_name            CONSTANT  VARCHAR2(100)  := 'xxcso_in_item_data';
    /* 2009.06.01 K.Satomura T1_1107�Ή� START */
    ct_comp_kbn_comp         CONSTANT xxcso_in_work_data.completion_kbn%TYPE := 1;
    /* 2009.06.01 K.Satomura T1_1107�Ή� END */
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E��O ***
    delete_error_expt        EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- ==========================================
      -- �������[�N�e�[�u���폜���� 
      -- ==========================================
      DELETE FROM xxcso_in_item_data  xiid                -- �������[�N�e�[�u��
      WHERE  EXISTS
             (
               SELECT xiwd.slip_no
               FROM   xxcso_in_work_data xiwd
               WHERE  xiwd.install_code1 = xiid.install_code
               OR     xiwd.install_code2 = xiid.install_code
             )
      AND    NOT EXISTS
             (
               SELECT xiwd2.slip_no
               FROM   xxcso_in_work_data xiwd2
               WHERE  (
                        /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
                        (
                        /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
                              xiwd2.install_code1           = xiid.install_code
                          AND xiwd2.install1_processed_flag = cv_no
                          /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
                          AND xiwd2.install1_process_no_target_flg = cv_no
                        )
                          /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
                      )
               OR     (
                        /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
                        (
                        /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
                              xiwd2.install_code2           = xiid.install_code
                          AND xiwd2.install2_processed_flag = cv_no
                          /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
                          AND xiwd2.install2_process_no_target_flg = cv_no
                        )
                          /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
                      )
               /* 2009.06.01 K.Satomura T1_1107�Ή� START */
               -- �{�����ŏ����ΏۂƂȂ��ƃf�[�^�ɂ��ĕ����̏������s���Ă��邱��
               /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
               --AND    xiwd2.process_no_target_flag = cv_no
               /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
               AND    xiwd2.completion_kbn         = ct_comp_kbn_comp
               /* 2009.06.01 K.Satomura T1_1107�Ή� END */
             );
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_31             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_error_expt;
    END;
--
  EXCEPTION
--
    -- *** �f�[�^�X�V��O�n���h�� ***
    WHEN delete_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ������O�n���h�� ***
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
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_in_item_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cn_kbn1                   CONSTANT  NUMBER          := 1;
    cv_no                     CONSTANT  VARCHAR2(1)     := 'N';
    cv_yes                    CONSTANT  VARCHAR2(1)     := 'Y';
    cv_haihun                 CONSTANT  VARCHAR2(1)     := '-';
    cv_inst_base_info         CONSTANT  VARCHAR2(100)   := '(IN)�����}�X�^���';
    cv_update_process1        CONSTANT  VARCHAR2(100)   := '�u50(�x�~)�v���u40(�ڋq)�v';
    cv_update_process2        CONSTANT  VARCHAR2(100)   := '�u30(���F��)�v���u40(�ڋq)�v';
    /* 2009.06.15 K.Satomura T1_1239�Ή� START */
    cv_comp_kbn_comp          CONSTANT  VARCHAR2(100)   := '1'; -- �����敪������
    /* 2009.06.15 K.Satomura T1_1239�Ή� END */
--
    -- *** ���[�J���ϐ� ***
    ld_sysdate                DATE;                    -- �V�X�e�����t
    ld_process_date           DATE;                    -- �Ɩ�������
    ld_cnvs_date              DATE;                    -- �ڋq�l����
    ln_seq_no                 NUMBER;                  -- �V�[�P���X�ԍ�
    ln_slip_num               NUMBER;                  -- �`�[No.
    ln_slip_branch_num        NUMBER;                  -- �`�[�}��
    ln_line_num               NUMBER;                  -- �s��
    ln_job_kbn                NUMBER;                  -- ��Ƌ敪
    ln_instance_status_id     NUMBER;                  -- �C���X�^���X�X�e�[�^�XID
    lv_bukken_code            VARCHAR2(10);            -- �����R�[�h
    lv_install_code1          VARCHAR2(10);            -- �����R�[�h�P
    lv_install_code2          VARCHAR2(10);            -- �����R�[�h�Q
    lv_account_num1           VARCHAR2(10);            -- �ڋq�R�[�h�P
    lv_account_num2           VARCHAR2(10);            -- �ڋq�R�[�h�Q
    lv_cnvs_date              VARCHAR2(20);            -- �ڋq�l����
    lv_info                   VARCHAR2(5000);          -- �A�g���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_inst_base_data_cur
    IS
      SELECT   xciwd.seq_no                         seq_no                      -- �V�[�P���X�ԍ�.
              ,xciwd.slip_no                        slip_no                     -- �`�[No.
              ,xciwd.slip_branch_no                 slip_branch_no              -- �`�[�}��
              ,xciwd.line_number                    line_number                 -- �s�ԍ�
              ,xciwd.job_kbn                        job_kbn                     -- ��Ƌ敪
              ,xciwd.install_code1                  install_code1               -- �����R�[�h�P�i�ݒu�p�j
              ,xciwd.install_code2                  install_code2               -- �����R�[�h�Q�i���g�p�j
              /* 2009.06.15 K.Satomura T1_1239�Ή� START */
              ,xciwd.completion_kbn                 completion_kbn              -- �����敪
              /* 2009.06.15 K.Satomura T1_1239�Ή� END */
              ,xciwd.safe_setting_standard          safe_setting_standard       -- ���S�ݒu�
              ,xciid.install_code                   install_code                -- �����R�[�h
              ,xciid.un_number                      un_number                   -- �@��
              ,xciid.install_number                 install_number              -- �@��
              ,xciid.machinery_kbn                  machinery_kbn               -- �@��敪
              ,xciid.first_install_date             first_install_date          -- ����ݒu��
              ,xciid.counter_no                     counter_no                  -- �J�E���^�[No.
              ,xciid.division_code                  division_code               -- �n��R�[�h
              ,xciid.base_code                      base_code                   -- ���_�R�[�h
              ,xciid.job_company_code               job_company_code            -- ��Ɖ�ЃR�[�h
              ,xciid.location_code                  location_code               -- ���Ə��R�[�h
              ,xciid.last_job_slip_no               last_job_slip_no            -- �ŏI��Ɠ`�[No.
              ,xciid.last_job_kbn                   last_job_kbn                -- �ŏI��Ƌ敪
              ,xciid.last_job_going                 last_job_going              -- �ŏI��Ɛi��
              ,xciid.last_job_completion_plan_date  last_job_cmpltn_plan_date   -- �ŏI��Ɗ����\���
              ,xciid.last_job_completion_date       last_job_cmpltn_date        -- �ŏI��Ɗ�����
              ,xciid.last_maintenance_contents      last_maintenance_contents   -- �ŏI�������e
              ,xciid.last_install_slip_no           last_install_slip_no        -- �ŏI�ݒu�`�[No.
              ,xciid.last_install_kbn               last_install_kbn            -- �ŏI�ݒu�敪
              ,xciid.last_install_plan_date         last_install_plan_date      -- �ŏI�ݒu�\���
              ,xciid.last_install_going             last_install_going          -- �ŏI�ݒu�i��
              ,xciid.machinery_status1              machinery_status1           -- �@����1�i�ғ���ԁj
              ,xciid.machinery_status2              machinery_status2           -- �@����2�i��ԏڍׁj
              ,xciid.machinery_status3              machinery_status3           -- �@����3�i�p�����j
              ,xciid.stock_date                     stock_date                  -- ���ɓ�
              ,xciid.withdraw_company_code          withdraw_company_code       -- ���g��ЃR�[�h
              ,xciid.withdraw_location_code         withdraw_location_code      -- ���g���Ə��R�[�h
              ,xciid.resale_disposal_vendor         resale_disposal_vendor      -- �]���p���Ǝ�
              ,xciid.resale_disposal_slip_no        resale_disposal_slip_no     -- �]���p���`�[��
              ,xciid.owner_company_code             owner_company_code          -- ���L��
              ,xciid.resale_disposal_flag           resale_disposal_flag        -- �]���p���󋵃t���O
              ,xciid.resale_completion_kbn          resale_completion_kbn       -- �]�������敪
              ,xciid.delete_flag                    delete_flag                 -- �폜�t���O
              ,xciid.creation_date_time             creation_date_time          -- �쐬���������b
              ,xciid.update_date_time               update_date_time            -- �X�V���������b
              ,xciwd.account_number1                account_number1             -- �ڋq�R�[�h�P�i�V�ݒu��
              ,xciwd.account_number2                account_number2             -- �ڋq�R�[�h�Q�i���ݒu��
              ,xciwd.po_number                      po_number                   -- �����ԍ�
              ,xciwd.po_line_number                 po_line_number              -- �������הԍ�
              ,xciwd.po_req_number                  po_req_number               -- �����˗��ԍ�
              ,xciwd.line_num                       line_num                    -- �����˗����הԍ�
              ,xciwd.actual_work_date               actual_work_date            -- ����Ɠ�
      FROM     xxcso_in_work_data    xciwd
              ,xxcso_in_item_data    xciid
      /* 2009.06.15 K.Satomura T1_1239�Ή� START */
      --WHERE    xciwd.completion_kbn   = cn_kbn1
      --  AND    (
      WHERE    (
      /* 2009.06.15 K.Satomura T1_1239�Ή� END */
                 (
                       xciid.install_code                   = NVL(xciwd.install_code1, ' ')
                   AND xciwd.install1_processed_flag        = cv_no
                   /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
                   AND xciwd.install1_process_no_target_flg = cv_no
                   /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
                 )
               OR
                 (
                       xciid.install_code                   = NVL(xciwd.install_code2, ' ') 
                   AND xciwd.install2_processed_flag        = cv_no
                   /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
                   AND xciwd.install2_process_no_target_flg = cv_no
                   /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
                 )
               )
         /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� START */
         --/* 2009.06.01 K.Satomura T1_1107�Ή� START */
         --AND   xciwd.process_no_target_flag = cv_no
         --/* 2009.06.01 K.Satomura T1_1107�Ή� END */
         /* 2009.06.04 K.Satomura T1_1107�ďC���Ή� END */
      ORDER BY xciwd.actual_work_date
              ,xciwd.actual_work_time2
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_inst_base_data_rec   get_inst_base_data_cur%ROWTYPE;
    l_g_get_data_rec       g_get_data_rtype;
--
    -- *** ���[�J����O ***
    skip_process_expt       EXCEPTION;
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
--
    -- ================================
    -- A-1.�������� 
    -- ================================
--
    init(
       od_sysdate            => ld_sysdate          -- �V�X�e�����t
      ,od_process_date       => ld_process_date     -- �Ɩ��������t
      ,ov_errbuf             => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode            => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg             => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.(IN) �����}�X�^��񒊏o����
    -- ========================================
    -- �J�[�\���I�[�v��
    OPEN get_inst_base_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���I�[�v���������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn || CHR(10) ||
                 ''
    );
--
    <<get_inst_base_data_loop>>
    LOOP
--    
      BEGIN
        FETCH get_inst_base_data_cur INTO l_inst_base_data_rec;
--
      EXCEPTION
        WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_16             -- ���b�Z�[�W�R�[�h 
                       ,iv_token_name1  => cv_tkn_table                 -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_inst_base_info            -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg                -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                      );
        lv_errbuf  := lv_errmsg;  
        RAISE global_process_expt;
      END;
      BEGIN
        -- �����Ώی����i�[
        gn_target_cnt := get_inst_base_data_cur%ROWCOUNT;
--
        EXIT WHEN get_inst_base_data_cur%NOTFOUND
        OR  get_inst_base_data_cur%ROWCOUNT = 0;
--
        -- ������
        l_g_get_data_rec := NULL;
        -- �����R�[�h
        lv_bukken_code := l_inst_base_data_rec.install_code;
--
        -- ���R�[�h�̊i�[
        l_g_get_data_rec.seq_no                    := l_inst_base_data_rec.seq_no;
        l_g_get_data_rec.slip_no                   := l_inst_base_data_rec.slip_no;
        l_g_get_data_rec.slip_branch_no            := l_inst_base_data_rec.slip_branch_no;
        l_g_get_data_rec.line_number               := l_inst_base_data_rec.line_number;
        l_g_get_data_rec.job_kbn                   := l_inst_base_data_rec.job_kbn;
        l_g_get_data_rec.install_code1             := l_inst_base_data_rec.install_code1;
        l_g_get_data_rec.install_code2             := l_inst_base_data_rec.install_code2;
        l_g_get_data_rec.safe_setting_standard     := l_inst_base_data_rec.safe_setting_standard;
        l_g_get_data_rec.install_code              := l_inst_base_data_rec.install_code;
        l_g_get_data_rec.un_number                 := l_inst_base_data_rec.un_number;
        l_g_get_data_rec.install_number            := l_inst_base_data_rec.install_number;
        l_g_get_data_rec.machinery_kbn             := l_inst_base_data_rec.machinery_kbn;
        l_g_get_data_rec.first_install_date        := l_inst_base_data_rec.first_install_date;
        l_g_get_data_rec.counter_no                := l_inst_base_data_rec.counter_no;
        l_g_get_data_rec.division_code             := l_inst_base_data_rec.division_code;
        l_g_get_data_rec.base_code                 := l_inst_base_data_rec.base_code;
        l_g_get_data_rec.job_company_code          := l_inst_base_data_rec.job_company_code;
        l_g_get_data_rec.location_code             := l_inst_base_data_rec.location_code;
        l_g_get_data_rec.last_job_slip_no          := l_inst_base_data_rec.last_job_slip_no;
        l_g_get_data_rec.last_job_kbn              := l_inst_base_data_rec.last_job_kbn;
        l_g_get_data_rec.last_job_going            := l_inst_base_data_rec.last_job_going;
        l_g_get_data_rec.last_job_cmpltn_plan_date := l_inst_base_data_rec.last_job_cmpltn_plan_date;
        l_g_get_data_rec.last_job_cmpltn_date      := l_inst_base_data_rec.last_job_cmpltn_date;
        l_g_get_data_rec.last_maintenance_contents := l_inst_base_data_rec.last_maintenance_contents;
        l_g_get_data_rec.last_install_slip_no      := l_inst_base_data_rec.last_install_slip_no;
        l_g_get_data_rec.last_install_kbn          := l_inst_base_data_rec.last_install_kbn;
        l_g_get_data_rec.last_install_plan_date    := l_inst_base_data_rec.last_install_plan_date;
        l_g_get_data_rec.last_install_going        := l_inst_base_data_rec.last_install_going;
        l_g_get_data_rec.machinery_status1         := l_inst_base_data_rec.machinery_status1;
        l_g_get_data_rec.machinery_status2         := l_inst_base_data_rec.machinery_status2;
        l_g_get_data_rec.machinery_status3         := l_inst_base_data_rec.machinery_status3;
        l_g_get_data_rec.stock_date                := l_inst_base_data_rec.stock_date;
        l_g_get_data_rec.withdraw_company_code     := l_inst_base_data_rec.withdraw_company_code;
        l_g_get_data_rec.withdraw_location_code    := l_inst_base_data_rec.withdraw_location_code;
        l_g_get_data_rec.resale_disposal_vendor    := l_inst_base_data_rec.resale_disposal_vendor;
        l_g_get_data_rec.resale_disposal_slip_no   := l_inst_base_data_rec.resale_disposal_slip_no;
        l_g_get_data_rec.owner_company_code        := l_inst_base_data_rec.owner_company_code;
        l_g_get_data_rec.resale_disposal_flag      := l_inst_base_data_rec.resale_disposal_flag;
        l_g_get_data_rec.resale_completion_kbn     := l_inst_base_data_rec.resale_completion_kbn;
        l_g_get_data_rec.delete_flag               := l_inst_base_data_rec.delete_flag;
        l_g_get_data_rec.creation_date_time        := l_inst_base_data_rec.creation_date_time;
        l_g_get_data_rec.update_date_time          := l_inst_base_data_rec.update_date_time;
        l_g_get_data_rec.account_number1           := l_inst_base_data_rec.account_number1;
        l_g_get_data_rec.account_number2           := l_inst_base_data_rec.account_number2;
        l_g_get_data_rec.po_number                 := l_inst_base_data_rec.po_number;
        l_g_get_data_rec.po_line_number            := l_inst_base_data_rec.po_line_number;
        l_g_get_data_rec.po_req_number             := l_inst_base_data_rec.po_req_number;
        l_g_get_data_rec.line_num                  := l_inst_base_data_rec.line_num;
        l_g_get_data_rec.actual_work_date          := l_inst_base_data_rec.actual_work_date;
        /* 2009.06.15 K.Satomura T1_1239�Ή� START */
        l_g_get_data_rec.completion_kbn            := l_inst_base_data_rec.completion_kbn;
        /* 2009.06.15 K.Satomura T1_1239�Ή� END */
--
        -- ���b�Z�[�W�i�[�p
        ln_seq_no                     := l_inst_base_data_rec.seq_no;
        ln_slip_num                   := l_inst_base_data_rec.slip_no;
        ln_slip_branch_num            := l_inst_base_data_rec.slip_branch_no;
        ln_line_num                   := l_inst_base_data_rec.line_number;
        ln_job_kbn                    := l_inst_base_data_rec.job_kbn;
        lv_install_code1              := l_inst_base_data_rec.install_code1;
        lv_install_code2              := l_inst_base_data_rec.install_code2;
        lv_account_num1               := l_inst_base_data_rec.account_number1;
        lv_account_num2               := l_inst_base_data_rec.account_number2;
        lv_cnvs_date                  := TO_CHAR(l_inst_base_data_rec.last_job_cmpltn_date);
--
        -- ========================================
        -- A-3.(�X�V���s�p)�Z�[�u�|�C���g�ݒ�
        -- ========================================
        SAVEPOINT item_proc_up;
        -- ========================================
        -- A-4.������񒊏o����
        -- ========================================
        -- �o�^�X�V�t���O�̏�����
        gb_insert_process_flg   := FALSE;
        -- �ڋq�X�e�[�^�X�u�x�~�v�X�V�t���O�̏�����
        gb_cust_status_free_flg := FALSE;
        -- �ڋq�X�e�[�^�X�u���F�ρv�X�V�t���O�̏�����
        gb_cust_status_appr_flg := FALSE;
        -- �ڋq�l�����X�V�t���O�̏�����
        gb_cust_cnv_upd_flg     := FALSE;
--
        get_item_instances(
           io_inst_base_data_rec   => l_g_get_data_rec --(IN)�����}�X�^���
          ,id_process_date         => ld_process_date  -- �Ɩ��������t
          ,ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode              => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE skip_process_expt;
        END IF;
--
        IF (gb_insert_process_flg = TRUE) THEN
          -- ========================================
          -- A-5.�����f�[�^�o�^����
          -- ========================================
--
          insert_item_instances(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)�����}�X�^���
            ,id_process_date         => ld_process_date  -- �Ɩ��������t
            ,ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode              => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
--
        ELSE
          ln_instance_status_id := l_g_get_data_rec.instance_status_id; 
          -- ========================================
          -- A-6.�_���폜�X�V�`�F�b�N����
          -- ========================================
          /* 2009.04.17 K.Satomura T1_0466�Ή� START */
          --IF (ln_instance_status_id = gt_instance_status_id_6) THEN
          --  lv_errmsg := xxccp_common_pkg.get_msg(
          --                  iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
          --                 ,iv_name         => cv_tkn_number_26             -- ���b�Z�[�W�R�[�h
          --                 ,iv_token_name1  => cv_tkn_bukken                -- �g�[�N���R�[�h1
          --                 ,iv_token_value1 => lv_bukken_code               -- �g�[�N���l1
          --               );
          --  lv_errbuf := lv_errmsg;
          --  RAISE skip_process_expt;
          --END IF;
          /* 2009.04.17 K.Satomura T1_0466�Ή� END */
--
          -- ========================================
          -- A-7.�������b�N����
          -- ========================================
          rock_item_instances(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)�����}�X�^���
            ,id_process_date         => ld_process_date  -- �Ɩ��������t
            ,ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode              => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
--
          -- ========================================
          -- A-8.�����f�[�^�X�V����
          -- ========================================
--
          update_item_instances(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)�����}�X�^���
            ,id_process_date         => ld_process_date  -- �Ɩ��������t
            ,ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode              => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
--
        END IF;
--
        -- ========================================
        -- A-9.��ƃf�[�^�X�V����
        -- ========================================
--
        update_in_work_data(
           io_inst_base_data_rec   => l_g_get_data_rec --(IN)�����}�X�^���
          ,id_process_date         => ld_process_date  -- �Ɩ��������t
          /* 2009.06.01 K.Satomura T1_1107�Ή� START */
          ,iv_skip_flag            => cv_no            -- �X�L�b�v�t���O
          /* 2009.06.01 K.Satomura T1_1107�Ή� END */
          ,ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode              => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_sub_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_sub_retcode = cv_status_warn) THEN
          RAISE skip_process_expt;
        END IF;
--

        -- ====================================================
        -- A-10.�ڋq�A�h�I���}�X�^�ƃp�[�e�B�}�X�^�X�V����
        -- ====================================================
--
        /* 2009.06.15 K.Satomura T1_1239�Ή� START */
        IF (l_g_get_data_rec.completion_kbn = cv_comp_kbn_comp) THEN
        /* 2009.06.15 K.Satomura T1_1239�Ή� END */
          update_cust_or_party(
             io_inst_base_data_rec   => l_g_get_data_rec --(IN)�����}�X�^���
            ,id_process_date         => ld_process_date  -- �Ɩ��������t
            ,ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode              => lv_sub_retcode   -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE skip_process_expt;
          END IF;
        /* 2009.06.15 K.Satomura T1_1239�Ή� START */
        END IF;
        /* 2009.06.15 K.Satomura T1_1239�Ή� END */
--
        -- ===================================
        -- A-11.�A�g�ϐ��탁�b�Z�[�W�o�͏���
        -- ===================================
--
        IF (gb_cust_status_free_flg = TRUE ) THEN 
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name          => cv_tkn_number_30              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   => cv_tkn_partnership_name       -- �g�[�N���R�[�h1
                         ,iv_token_value1  => cv_inst_base_info             -- �g�[�N���l1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3   => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5   => cv_tkn_bukken1                -- �g�[�N���R�[�h5
                         ,iv_token_value5  => lv_install_code1              -- �g�[�N���l5
                         ,iv_token_name6   => cv_tkn_bukken2                -- �g�[�N���R�[�h6
                         ,iv_token_value6  => lv_install_code2              -- �g�[�N���l6
                         ,iv_token_name7   => cv_tkn_account_num1           -- �g�[�N���R�[�h7
                         ,iv_token_value7  => lv_account_num1               -- �g�[�N���l7
                         ,iv_token_name8   => cv_tkn_account_num2           -- �g�[�N���R�[�h8
                         ,iv_token_value8  => lv_account_num2               -- �g�[�N���l8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- �g�[�N���R�[�h9
                         ,iv_token_value9  => cv_update_process1            -- �g�[�N���l9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- �g�[�N���R�[�h10
                         ,iv_token_value10 => cv_haihun                     -- �g�[�N���l10
                    );
        ELSIF(gb_cust_status_appr_flg = TRUE) THEN 
          IF (gb_cust_cnv_upd_flg = FALSE) THEN
            lv_cnvs_date := cv_haihun;
          END IF;
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name          => cv_tkn_number_30              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   => cv_tkn_partnership_name       -- �g�[�N���R�[�h1
                         ,iv_token_value1  => cv_inst_base_info             -- �g�[�N���l1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3   => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5   => cv_tkn_bukken1                -- �g�[�N���R�[�h5
                         ,iv_token_value5  => lv_install_code1              -- �g�[�N���l5
                         ,iv_token_name6   => cv_tkn_bukken2                -- �g�[�N���R�[�h6
                         ,iv_token_value6  => lv_install_code2              -- �g�[�N���l6
                         ,iv_token_name7   => cv_tkn_account_num1           -- �g�[�N���R�[�h7
                         ,iv_token_value7  => lv_account_num1               -- �g�[�N���l7
                         ,iv_token_name8   => cv_tkn_account_num2           -- �g�[�N���R�[�h8
                         ,iv_token_value8  => lv_account_num2               -- �g�[�N���l8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- �g�[�N���R�[�h9
                         ,iv_token_value9  => cv_update_process2            -- �g�[�N���l9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- �g�[�N���R�[�h10
                         ,iv_token_value10 => lv_cnvs_date                  -- �g�[�N���l10
                    );
        ELSIF(gb_cust_cnv_upd_flg = TRUE) THEN
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name          => cv_tkn_number_30              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   => cv_tkn_partnership_name       -- �g�[�N���R�[�h1
                         ,iv_token_value1  => cv_inst_base_info             -- �g�[�N���l1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3   => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5   => cv_tkn_bukken1                -- �g�[�N���R�[�h5
                         ,iv_token_value5  => lv_install_code1              -- �g�[�N���l5
                         ,iv_token_name6   => cv_tkn_bukken2                -- �g�[�N���R�[�h6
                         ,iv_token_value6  => lv_install_code2              -- �g�[�N���l6
                         ,iv_token_name7   => cv_tkn_account_num1           -- �g�[�N���R�[�h7
                         ,iv_token_value7  => lv_account_num1               -- �g�[�N���l7
                         ,iv_token_name8   => cv_tkn_account_num2           -- �g�[�N���R�[�h8
                         ,iv_token_value8  => lv_account_num2               -- �g�[�N���l8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- �g�[�N���R�[�h9
                         ,iv_token_value9  => cv_haihun                     -- �g�[�N���l9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- �g�[�N���R�[�h10
                         ,iv_token_value10 => lv_cnvs_date                  -- �g�[�N���l10
                    );
                 
        ELSE
          lv_info := xxccp_common_pkg.get_msg(
                          iv_application   => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                         ,iv_name          => cv_tkn_number_30              -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1   => cv_tkn_partnership_name       -- �g�[�N���R�[�h1
                         ,iv_token_value1  => cv_inst_base_info             -- �g�[�N���l1
                         ,iv_token_name2   => cv_tkn_seq_no                 -- �g�[�N���R�[�h2
                         ,iv_token_value2  => TO_CHAR(ln_seq_no)            -- �g�[�N���l2
                         ,iv_token_name3   => cv_tkn_slip_num               -- �g�[�N���R�[�h3
                         ,iv_token_value3  => TO_CHAR(ln_slip_num)          -- �g�[�N���l3
                         ,iv_token_name4   => cv_tkn_slip_branch_num        -- �g�[�N���R�[�h4
                         ,iv_token_value4  => TO_CHAR(ln_slip_branch_num)   -- �g�[�N���l4
                         ,iv_token_name5   => cv_tkn_bukken1                -- �g�[�N���R�[�h5
                         ,iv_token_value5  => lv_install_code1              -- �g�[�N���l5
                         ,iv_token_name6   => cv_tkn_bukken2                -- �g�[�N���R�[�h6
                         ,iv_token_value6  => lv_install_code2              -- �g�[�N���l6
                         ,iv_token_name7   => cv_tkn_account_num1           -- �g�[�N���R�[�h7
                         ,iv_token_value7  => lv_account_num1               -- �g�[�N���l7
                         ,iv_token_name8   => cv_tkn_account_num2           -- �g�[�N���R�[�h8
                         ,iv_token_value8  => lv_account_num2               -- �g�[�N���l8
                         ,iv_token_name9   => cv_tkn_cust_status_info       -- �g�[�N���R�[�h9
                         ,iv_token_value9  => cv_haihun                     -- �g�[�N���l9
                         ,iv_token_name10  => cv_tkn_cnvs_date              -- �g�[�N���R�[�h10
                         ,iv_token_value10 => cv_haihun                     -- �g�[�N���l10
                    );
        END IF;
        -- ���b�Z�[�W�o��
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_info                                         -- ���[�U�E����A�g���b�Z�[�W
        );
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_info                                         -- ����A�g���b�Z�[�W
        );
        -- ���팏���J�E���g�A�b�v
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- *** �X�L�b�v��O�n���h�� ***
        WHEN skip_process_expt THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode   := cv_status_warn;
--
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf                  -- �G���[���b�Z�[�W
          );
          -- ���[���o�b�N
          IF gb_rollback_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT item_proc_up;          -- ROLLBACK
            gb_rollback_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg11|| CHR(10)
            );
          END IF;
--
        -- *** �X�L�b�v��OOTHERS�n���h�� ***
        WHEN OTHERS THEN
          gn_error_cnt := gn_error_cnt + 1;       -- �G���[�����J�E���g
          lv_retcode   := cv_status_warn;
--
          -- ���O�o��
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_errbuf  ||SQLERRM              -- �G���[���b�Z�[�W
          );
          -- ���[���o�b�N
          IF gb_rollback_flg = TRUE THEN
            ROLLBACK TO SAVEPOINT item_proc_up;          -- ROLLBACK
            gb_rollback_flg := FALSE;
            -- ���O�o��
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => CHR(10) ||cv_debug_msg11|| CHR(10)
            );
          END IF;
--
      END;
    END LOOP get_inst_base_data_loop;
--
    ov_retcode   := lv_retcode;
    -- �J�[�\���N���[�Y
    CLOSE get_inst_base_data_cur;
    -- *** DEBUG_LOG ***
    -- �J�[�\���N���[�Y�������Ƃ����O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- �����Ώی�����0���̏ꍇ
    IF (gn_target_cnt = 0) THEN
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_32             --���b�Z�[�W�R�[�h
                   );
      -- ���b�Z�[�W�o��
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- �G���[���b�Z�[�W
      );
--     
     ELSE 
      -- ======================================
      -- A-12.�����f�[�^���[�N�e�[�u���폜����
      -- ======================================
--
      delete_in_item_data(
         ov_errbuf               => lv_errbuf        -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode              => lv_retcode       -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg               => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--      
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_inst_base_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_inst_base_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_inst_base_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_inst_base_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_inst_base_data_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_inst_base_data_cur;
      -- *** DEBUG_LOG ***
      -- �J�[�\���N���[�Y�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT  NOCOPY  VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
      ov_errbuf   => lv_errbuf,           -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode  => lv_retcode,          -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
 --
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-13.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO015A03C;
/
