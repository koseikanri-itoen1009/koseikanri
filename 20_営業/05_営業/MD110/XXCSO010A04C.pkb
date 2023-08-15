CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO010A04C(body)
 * Description      : �����̔��@�ݒu�_����o�^/�X�V��ʁA�_�񏑌�����ʂ���
 *                    �����̔��@�ݒu�_�񏑂𒠕[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_010_A04_�����̔��@�ݒu�_��PDF�t�@�C���쐬
 *
 * Version          : 1.19
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_contract_data      �f�[�^�擾(A-2)
 *  insert_data            ���[�N�e�[�u���o��(A-3)
 *  act_svf                SVF�N��(A-4)
 *  exec_submit_req        �o���o�͗v�����s����(A-5)
 *  func_wait_for_request  �R���J�����g�I���ҋ@����(A-6)
 *  delete_data            ���[�N�e�[�u���f�[�^�폜(A-7)
 *  submain                ���C�������v���V�[�W��
 *                           SVF�N��API�G���[�`�F�b�N(A-8)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-9)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-03    1.0   Kichi.Cho        �V�K�쐬
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF�N��API���ߍ���
 *  2009-03-06    1.1   Abe.Daisuke     �y�ۑ�No71�z�����ʏ����A�ꗥ�����E�e��ʏ����̉�ʓ��͐���̕ύX�Ή�
 *  2009-03-13    1.1   Mio.Maruyama    �y��Q052,055,056�z���o�����ύX�E�e�[�u���T�C�Y�ύX
 *  2009-04-27    1.2   Kazuo.Satomura   �V�X�e���e�X�g��Q�Ή�(T1_0705,T1_0778)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897�Ή�
 *  2009-09-14    1.4   Mio.Maruyama     0001355�Ή�
 *  2009-10-15    1.5   Daisuke.Abe      0001536,0001537�Ή�
 *  2009-11-12    1.6   Kazuo.Satomura   I_E_658�Ή�
 *  2009-11-30    1.7   T.Maruyama       E_�{�ғ�_00193�Ή�
 *  2010-03-02    1.8   K.Hosoi          E_�{�ғ�_01678�Ή�
 *  2010-08-03    1.9   H.Sasaki         E_�{�ғ�_00822�Ή�
 *  2014-02-03    1.10  S.Niki           E_�{�ғ�_11397�Ή�
 *  2015-02-16    1.11  K.Nakatsu        E_�{�ғ�_12565�Ή�
 *  2015-06-25    1.12  Y.Shoji          E_�{�ғ�_13019�Ή�
 *  2018-11-15    1.13  E.Yazaki         E_�{�ғ�_15367�Ή�
 *  2020-05-07    1.14  N.Abe            E_�{�ғ�_15904�Ή��i�O�őΉ��j
 *  2020-08-07    1.15  N.Abe            E_�{�ғ�_15904�Ή��i�O�őΉ��j16�p�^�[����
 *  2020-12-03    1.16  K.Kanada         E_�{�ғ�_15904�Ή��i�O�őΉ��j�������e�ҏW�A�p�^�[���C��
 *  2021-01-12    1.17  K.Kanada         E_�{�ғ�_15904�Ή��i�O�őΉ��s��j�������e�ҏW�i�藦�E��z�j
 *  2023-06-02    1.18  T.Okuyama        E_�{�ғ�_19179�Ή� �C���{�C�X�Ή�
 *  2023-07-26    1.19  T.Okuyama        E_�{�ғ�_19179�Ή� �C���{�C�X�Ή� �o�^�ԍ��擾�v��
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
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
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCSO010A04C';      -- �p�b�P�[�W��
  cv_app_name           CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
  cv_svf_name           CONSTANT VARCHAR2(100) := 'XXCSO010A04';       -- �p�b�P�[�W��
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- �p�����[�^NULL�G���[
  cv_tkn_number_02      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00416';  -- �_�񏑔ԍ�
  cv_tkn_number_03      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00413';  -- �����̔��@�ݒu�_��ID�`�F�b�N�G���[
  cv_tkn_number_04      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00414';  -- �����̔��@�ݒu�_�񏑏��擾�G���[
  cv_tkn_number_05      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00415';  -- �����̔��@�ݒu�_�񏑏�񕡐����݃G���[
  cv_tkn_number_06      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00417';  -- API�G���[���b�Z�[�W
  cv_tkn_number_07      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00418';  -- �f�[�^�ǉ��G���[���b�Z�[�W
  cv_tkn_number_08      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00419';  -- �f�[�^�폜�G���[���b�Z�[�W
  cv_tkn_number_09      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00496';  -- �p�����[�^�o��
  cv_tkn_number_10      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- �f�[�^�擾�G���[
  cv_tkn_number_11      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- ���b�N�G���[���b�Z�[�W
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  START  */
  cv_tkn_number_12      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00736';  -- �o���O���Œ蕔�擾�G���[���b�Z�[�W
  cv_tkn_number_13      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00737';  -- ���s���������R�[�h�擾�G���[���b�Z�[�W
  cv_tkn_number_14      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00738';  -- �ݒu���^�����s���敪�擾�G���[���b�Z�[�W
  cv_tkn_number_15      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_16      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00741';  -- �R���J�����g���́i�ݒu���^���j
  cv_tkn_number_17      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00742';  -- �R���J�����g���́i�d�C��j
  cv_tkn_number_18      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00743';  -- �R���J�����g���́i�Љ�萔���j
  cv_tkn_number_19      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00310';  -- �R���J�����g�N���G���[���b�Z�[�W
  cv_tkn_number_20      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00744';  -- �R���J�����g�ҋ@���Ԍo�߃G���[���b�Z�[�W
  cv_tkn_number_21      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00745';  -- �R���J�����g�ҋ@���탁�b�Z�[�W
  cv_tkn_number_22      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00746';  -- �R���J�����g�ҋ@�x�����b�Z�[�W
  cv_tkn_number_23      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00747';  -- �R���J�����g�ҋ@�G���[���b�Z�[�W
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END    */
--
  -- �g�[�N���R�[�h
  cv_tkn_param_nm       CONSTANT VARCHAR2(30) := 'PARAM_NAME';
  cv_tkn_val            CONSTANT VARCHAR2(30) := 'VALUE';
  cv_tkn_con_mng_id     CONSTANT VARCHAR2(30) := 'CONTRACT_MANAGEMENT_ID';
  cv_tkn_contract_num   CONSTANT VARCHAR2(30) := 'CONTRACT_NUMBER';
  cv_tkn_err_msg        CONSTANT VARCHAR2(30) := 'ERR_MSG';
  cv_tkn_tbl            CONSTANT VARCHAR2(30) := 'TABLE';
  cv_tkn_api_nm         CONSTANT VARCHAR2(30) := 'API_NAME';
  cv_tkn_request_id     CONSTANT VARCHAR2(30) := 'REQUEST_ID';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  START  */
  cv_tkn_prof_name      CONSTANT VARCHAR2(30) := 'PROF_NAME';
  cv_tkn_conc           CONSTANT VARCHAR2(30) := 'CONC';
  cv_tkn_concmsg        CONSTANT VARCHAR2(30) := 'CONCMSG';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END    */
--
  -- ���t����
  cv_flag_1             CONSTANT VARCHAR2(1)  := '1';             -- ����A-2-1
  cv_flag_2             CONSTANT VARCHAR2(1)  := '2';             -- ����A-2-2
  -- �L��
  cv_enabled_flag       CONSTANT VARCHAR2(1)  := 'Y';
  -- �A�N�e�B�u
  cv_active_status      CONSTANT VARCHAR2(1)  := 'A';
  --
/* 2014/02/03 Ver1.10 S.Niki ADD START */
  -- �ő�s��
  cn_max_line           CONSTANT NUMBER       := 17;
/* 2014/02/03 Ver1.10 S.Niki ADD END */
-- == 2010/08/03 V1.9 Added START ===============================================================
  cv_lkup_kozatype      CONSTANT VARCHAR2(30) :=  'XXCSO1_KOZA_TYPE';                 --  �Q�ƃ^�C�v�F�������
  cv_space              CONSTANT VARCHAR2(1)  :=  ' ';                                --  ���p�X�y�[�X
  cv_msg_xxcso_00470    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00470';                 --  �f�[�^�擾�G���[
  cv_msg_xxcso_00604    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00604';                 --  �_�񏑏o�͓���^���b�Z�[�W
  cv_msg_xxcso_00605    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00605';                 --  �̔��萔���A���i�����ʁj���b�Z�[�W
  cv_msg_xxcso_00606    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00606';                 --  �̔��萔���A���i�e��ʁj���b�Z�[�W
  cv_tkn_xxcso_00470_01 CONSTANT VARCHAR2(30) :=  'ACTION';                           --  APP-XXCSO1-00470�̃g�[�N��
  cv_tkn_xxcso_00470_02 CONSTANT VARCHAR2(30) :=  'KEY_NAME';                         --  APP-XXCSO1-00470�̃g�[�N��
  cv_tkn_xxcso_00470_03 CONSTANT VARCHAR2(30) :=  'KEY_ID';                           --  APP-XXCSO1-00470�̃g�[�N��
  cv_cnst_message       CONSTANT VARCHAR2(10) :=  '���b�Z�[�W';                       --  �g�[�N���l
  cv_cnst_item_name     CONSTANT VARCHAR2(12) :=  'MESSAGE_NAME';                     --  �g�[�N���l
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
  -- SP�ꌈ�x���敪�i�ݒu���^���j
  cv_is_type_no         CONSTANT VARCHAR2(1)   := '0';                              -- ��
  cv_is_type_yes        CONSTANT VARCHAR2(1)   := '1';                              -- �L
  -- SP�ꌈ�x�������i�ݒu���^���j
  cv_is_pay_type_yearly CONSTANT VARCHAR2(1)   := '1';                              -- 1�N�����̏ꍇ
  cv_is_pay_type_single CONSTANT VARCHAR2(1)   := '2';                              -- ���z�����̏ꍇ
  -- SP�ꌈ�x���敪�i�Љ�萔���j
  cv_ic_type_no         CONSTANT VARCHAR2(1)   := '0';                              -- ��
  cv_ic_type_yes        CONSTANT VARCHAR2(1)   := '1';                              -- �L
  -- SP�ꌈ�x�������i�Љ�萔���j
  cv_ic_pay_type_single CONSTANT VARCHAR2(1)   := '1';                              -- ����ɉ����Ȃ��ꊇ�x���̏ꍇ
  cv_ic_pay_type_per_sp CONSTANT VARCHAR2(1)   := '2';                              -- �̔����z�ɑ΂��道�̏ꍇ
  cv_ic_pay_type_per_p  CONSTANT VARCHAR2(1)   := '3';                              -- 1�{�ɂ����~�̏ꍇ
  -- SP�ꌈ�d�C��敪
  cv_electric_type_no   CONSTANT VARCHAR2(1)   := '0';                              -- �Ȃ�
  cv_electric_type_fix  CONSTANT VARCHAR2(1)   := '1';                              -- ��z
  cv_electric_type_var  CONSTANT VARCHAR2(1)   := '2';                              -- �ϓ�
  -- SP�ꌈ�x�������i�d�C��j
  cv_e_pay_type_cont    CONSTANT VARCHAR2(1)   := '1';                              -- �_���
  cv_e_pay_type_other   CONSTANT VARCHAR2(1)   := '2';                              -- �_���ȊO
  -- �O��(�N�C�b�N�R�[�h)
  cv_lkup_preamble_type CONSTANT VARCHAR2(100) := 'XXCSO1_MEMORANDUM_PREAMBLE';     -- �o���O��
  cv_lkup_preamble_code CONSTANT VARCHAR2(1)   := '1';                              -- �o���O���R�[�h
  -- �n��Ǘ����_�R�[�h
  cv_lkup_sp_mgr_type   CONSTANT VARCHAR2(100) := 'XXCSO1_SP_MGR_BASE_CD';          -- SP�ꌈ�Ǘ����_
  cv_lkup_sp_mgr_memo   CONSTANT VARCHAR2(100) := 'Y';                              -- SP�ꌈ�Ǘ����_�R�[�hDFF1�i�o���g�p�敪�j
  -- �r�o�ꌈ�U���萔�����S�敪
  cv_lkup_trns_fee_type CONSTANT VARCHAR2(100) := 'XXCSO1_SP_TRANSFER_FEE_TYPE';
  -- �����{��������
  cv_lkup_e_vice_org    CONSTANT VARCHAR2(100) := 'XXCSO1_E_VICE_ORG';
  -- ���s���������R�[�h
  cv_lkup_org_boss_code CONSTANT VARCHAR2(100) := 'XXCSO1_ORG_BOSS_CODE';
  -- �ݒu���^���^�Љ�萔��
  cv_lkup_is_ic_appv_cls CONSTANT VARCHAR2(100) := 'XXCSO1_IS_IC_APPV_CLASS';
  -- ���s���������R�[�h
  cv_e_vice_org_cd      CONSTANT VARCHAR2(1)   := '1';
  -- �ݒu���^�����s���敪�擾�R�[�h
  cv_appv_cls_br_mgr    CONSTANT VARCHAR2(1)   := '1'; -- �x�X��
  cv_appv_cls_areamgr   CONSTANT VARCHAR2(1)   := '2'; -- �n��{����
  -- �o���o�̓t���O
  cn_is_memo_no         CONSTANT NUMBER        := 0;                              -- �o���i�ݒu���^���j����
  cn_is_memo_yes        CONSTANT NUMBER        := 1;                              -- �o���i�ݒu���^���j�L��
  cn_ic_memo_no         CONSTANT NUMBER        := 0;                              -- �o���i�Љ�萔���j����
  cn_ic_memo_single     CONSTANT NUMBER        := 1;                              -- �o���i�Љ�萔���j�L��|����ɉ����Ȃ��ꊇ�x���̏ꍇ
  cn_ic_memo_per_sp     CONSTANT NUMBER        := 2;                              -- �o���i�Љ�萔���j�L��|�̔����z�ɑ΂��道�̏ꍇ
  cn_ic_memo_per_p      CONSTANT NUMBER        := 3;                              -- �o���i�Љ�萔���j�L��|1�{�ɂ����~�̏ꍇ
  cn_e_memo_no          CONSTANT NUMBER        := 0;                              -- �o���i�d�C��j�����|�d�C��Ȃ�
  cn_e_memo_cont        CONSTANT NUMBER        := 1;                              -- �o���i�d�C��j�����|�x�����������_���
  cn_e_memo_o_fix       CONSTANT NUMBER        := 2;                              -- �o���i�d�C��j�L��|��z
  cn_e_memo_o_var       CONSTANT NUMBER        := 3;                              -- �o���i�d�C��j�L��|�ϓ�
  -- �v���t�@�C����
  cv_interval           CONSTANT VARCHAR2(30)  := 'XXCSO1_INTERVAL_XXCSO010A04C'; -- XXCSO:�ҋ@�Ԋu�i�o���o�́j
  cv_max_wait           CONSTANT VARCHAR2(30)  := 'XXCSO1_MAX_WAIT_XXCSO010A04C'; -- XXCSO:�ő�ҋ@���ԁi�o���o�́j
--  Ver1.18 T.Okuyama Add Start
  cv_t_number           CONSTANT VARCHAR2(30)  := 'XXCMM1_INVOICE_T_NO';          -- XXCMM:�K�i���������s���Ǝғo�^�ԍ�
  cv_t_flag             CONSTANT VARCHAR2(1)   := 'T';                            -- T�t���O
  cv_t_none             CONSTANT VARCHAR2(1)   := ' ';                            -- �o�^�ԍ��Ȃ�
--  Ver1.18 T.Okuyama Add End
  -- �o���o�̓R���J�����g��
  cv_xxcso010a06        CONSTANT VARCHAR2(20)  := 'XXCSO010A06C';                 -- �o���o��
  -- �o�����[�敪
  cv_memo_inst          CONSTANT VARCHAR2(1)   := '1';
  cv_memo_intro_fix     CONSTANT VARCHAR2(1)   := '2';
  cv_memo_intro_price   CONSTANT VARCHAR2(1)   := '3';
  cv_memo_intro_piece   CONSTANT VARCHAR2(1)   := '4';
  cv_memo_elec_fix      CONSTANT VARCHAR2(1)   := '5';
  cv_memo_elec_change   CONSTANT VARCHAR2(1)   := '6';
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal  CONSTANT VARCHAR2(6)   := 'NORMAL';  -- '����'
  cv_dev_status_warn    CONSTANT VARCHAR2(7)   := 'WARNING'; -- '�x��'
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
/* 2018/11/15 Ver1.13 E.Yazaki ADD START */
  -- �����t�H�[�}�b�g
  cv_format_yyyymmdd_date        CONSTANT VARCHAR2(50)    := 'YYYY"�N"MM"��"DD"��"';
/* 2018/11/15 Ver1.13 E.Yazaki ADD END */
--  Ver1.16 K.Kanada Add Start
  cv_lkup_condition_contents     CONSTANT VARCHAR2(30) :=  'XXCSO1_CONDITION_CONTENTS';  -- �Q�ƃ^�C�v�F���̋@�ݒu�_�񏑏������e�Œ蕶
  cv_lkup_elect_tax_kbn          CONSTANT VARCHAR2(30) :=  'XXCSO1_ELECTRIC_TAX_KBN';    -- �Q�ƃ^�C�v�F�d�C��p�ŋ敪
  cv_null               CONSTANT VARCHAR2(1)   := NULL ;
  cv_contents_msg_max   CONSTANT NUMBER        := 14 ;
  cv_msg_xxcso_00911    CONSTANT VARCHAR2(30) :=  'APP-XXCSO1-00912';                 --  �̔��萔���A���i�e��ʁj���b�Z�[�W
--  Ver1.16 K.Kanada Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- �����̔��@�ݒu�_��ID
  gt_contract_number    xxcso_contract_managements.contract_number%TYPE;             -- �_�񏑔ԍ�
-- == 2010/08/03 V1.9 Added START ===============================================================
  gt_contract_date_ptn  fnd_new_messages.message_text%TYPE;                           --  �_�񏑏o�͓���^
  gt_terms_note_price   fnd_new_messages.message_text%TYPE;                           --  �̔��萔���A���i�����ʁj
  gt_terms_note_ves     fnd_new_messages.message_text%TYPE;                           --  �̔��萔���A���i�e��ʁj
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
  -- �o���o�͗v�����s�֘A
  gn_interval           VARCHAR2(30);
  gn_max_wait           VARCHAR2(30);
  gn_req_cnt            NUMBER;
  gv_retcode            VARCHAR2(1);
  gv_memo_inst          VARCHAR2(1);
  gv_memo_intro         VARCHAR2(1);
  gv_memo_elec          VARCHAR2(1);
  -- �o���̔��s��ʏo�͗p����
  gv_conc_des_inst      VARCHAR2(100);
  gv_conc_des_intro     VARCHAR2(100);
  gv_conc_des_electric  VARCHAR2(100);
  -- �O���Œ蕔
  gv_install_supp_pre   VARCHAR2(300);
  gv_intro_chg_pre1     VARCHAR2(300);
  gv_intro_chg_pre2     VARCHAR2(300);
  gv_electric_pre1      VARCHAR2(300);
  gv_electric_pre2      VARCHAR2(300);
  gv_electric_pre3      VARCHAR2(300);
  gv_electric_pre4      VARCHAR2(300);
  -- �{�����E��
  gt_gen_mgr_pos_code   fnd_lookup_values.attribute1%TYPE;
  -- �����{�����i���В��j�������_�i�V�j
  gt_e_vice_pres_base   fnd_lookup_values.attribute2%TYPE;
  -- �����{�����i���В��j���i�R�[�h�i�V�j
  gt_e_vice_pres_qual   fnd_lookup_values.attribute3%TYPE;
  -- �ݒu���^�����s����������
  gn_is_amt_branch      NUMBER;       -- �x�X���i�ݒu���^�����z����j
  gn_is_amt_areamgr     NUMBER;       -- �n��c�Ɩ{�����i�ݒu���^�����z����j
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--  Ver1.18 T.Okuyama Add Start
  gv_t_number           VARCHAR2(14);                              -- �o�^�ԍ�
--  Ver1.18 T.Okuyama Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �����̔��@�ݒu�_�񏑒��[���[�N�e�[�u�� �f�[�^�i�[�p���R�[�h�^��`
  TYPE g_rep_cont_data_rtype IS RECORD(
    install_location              xxcso_rep_auto_sale_cont.install_location%TYPE,              -- �ݒu���P�[�V����
    contract_number               xxcso_rep_auto_sale_cont.contract_number%TYPE,               -- �_�񏑔ԍ�
    contract_name                 xxcso_rep_auto_sale_cont.contract_name%TYPE,                 -- �_��Җ�
    contract_period               xxcso_rep_auto_sale_cont.contract_period%TYPE,               -- �_�����
    cancellation_offer_code       xxcso_rep_auto_sale_cont.cancellation_offer_code%TYPE,       -- �_������\���o
    other_content                 xxcso_rep_auto_sale_cont.other_content%TYPE,                 -- ���񎖍�
    sales_charge_details_delivery xxcso_rep_auto_sale_cont.sales_charge_details_delivery%TYPE, -- �萔�����׏����t�於
    delivery_address              xxcso_rep_auto_sale_cont.delivery_address%TYPE,              -- ���t��Z��
    install_name                  xxcso_rep_auto_sale_cont.install_name%TYPE,                  -- �ݒu�於
    install_address               xxcso_rep_auto_sale_cont.install_address%TYPE,               -- �ݒu��Z��
    install_date                  xxcso_rep_auto_sale_cont.install_date%TYPE,                  -- �ݒu��
    bank_name                     xxcso_rep_auto_sale_cont.bank_name%TYPE,                     -- ���Z�@�֖�
    blanches_name                 xxcso_rep_auto_sale_cont.blanches_name%TYPE,                 -- �x�X��
    account_number                xxcso_rep_auto_sale_cont.account_number%TYPE,                -- �ڋq�R�[�h
    bank_account_number           xxcso_rep_auto_sale_cont.bank_account_number%TYPE,           -- �����ԍ�
    bank_account_name_kana        xxcso_rep_auto_sale_cont.bank_account_name_kana%TYPE,        -- �������`�J�i
    publish_base_code             xxcso_rep_auto_sale_cont.publish_base_code%TYPE,             -- �S�����_
    publish_base_name             xxcso_rep_auto_sale_cont.publish_base_name%TYPE,             -- �S�����_��
    contract_effect_date          xxcso_rep_auto_sale_cont.contract_effect_date%TYPE,          -- �_�񏑔�����
    issue_belonging_address       xxcso_rep_auto_sale_cont.issue_belonging_address%TYPE,       -- ���s�������Z��
    issue_belonging_name          xxcso_rep_auto_sale_cont.issue_belonging_name%TYPE,          -- ���s��������
    issue_belonging_boss_position xxcso_rep_auto_sale_cont.issue_belonging_boss_position%TYPE, -- ���s���������E�ʖ�
    issue_belonging_boss          xxcso_rep_auto_sale_cont.issue_belonging_boss%TYPE,          -- ���s����������
    close_day_code                xxcso_rep_auto_sale_cont.close_day_code%TYPE,                -- ����
    transfer_month_code           xxcso_rep_auto_sale_cont.transfer_month_code%TYPE,           -- ������
    transfer_day_code             xxcso_rep_auto_sale_cont.transfer_day_code%TYPE,             -- ������
    exchange_condition            xxcso_rep_auto_sale_cont.exchange_condition%TYPE,            -- �������
    condition_contents_1          xxcso_rep_auto_sale_cont.condition_contents_1%TYPE,          -- �������e1
    condition_contents_2          xxcso_rep_auto_sale_cont.condition_contents_2%TYPE,          -- �������e2
    condition_contents_3          xxcso_rep_auto_sale_cont.condition_contents_3%TYPE,          -- �������e3
    condition_contents_4          xxcso_rep_auto_sale_cont.condition_contents_4%TYPE,          -- �������e4
    condition_contents_5          xxcso_rep_auto_sale_cont.condition_contents_5%TYPE,          -- �������e5
    condition_contents_6          xxcso_rep_auto_sale_cont.condition_contents_6%TYPE,          -- �������e6
    condition_contents_7          xxcso_rep_auto_sale_cont.condition_contents_7%TYPE,          -- �������e7
    condition_contents_8          xxcso_rep_auto_sale_cont.condition_contents_8%TYPE,          -- �������e8
    condition_contents_9          xxcso_rep_auto_sale_cont.condition_contents_9%TYPE,          -- �������e9
    condition_contents_10         xxcso_rep_auto_sale_cont.condition_contents_10%TYPE,         -- �������e10
    condition_contents_11         xxcso_rep_auto_sale_cont.condition_contents_11%TYPE,         -- �������e11
    condition_contents_12         xxcso_rep_auto_sale_cont.condition_contents_12%TYPE,         -- �������e12
/* 2014/02/03 Ver1.10 S.Niki ADD START */
    condition_contents_13         xxcso_rep_auto_sale_cont.condition_contents_13%TYPE,         -- �������e13
    condition_contents_14         xxcso_rep_auto_sale_cont.condition_contents_14%TYPE,         -- �������e14
    condition_contents_15         xxcso_rep_auto_sale_cont.condition_contents_15%TYPE,         -- �������e15
    condition_contents_16         xxcso_rep_auto_sale_cont.condition_contents_16%TYPE,         -- �������e16
    condition_contents_17         xxcso_rep_auto_sale_cont.condition_contents_17%TYPE,         -- �������e17
/* 2014/02/03 Ver1.10 S.Niki ADD END */
    install_support_amt           xxcso_rep_auto_sale_cont.install_support_amt%TYPE,           -- �ݒu���^��
    electricity_information       xxcso_rep_auto_sale_cont.electricity_information%TYPE,       -- �d�C����
    transfer_commission_info      xxcso_rep_auto_sale_cont.transfer_commission_info%TYPE,      -- �U�荞�ݎ萔�����
    electricity_amount            xxcso_sp_decision_headers.electricity_amount%TYPE,           -- �d�C��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    tax_type_name                 xxcso_rep_auto_sale_cont.tax_type_name%TYPE,                 -- �ŋ敪��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--  Ver1.18 T.Okuyama Add Start
    bm1_t_no                      xxcso_rep_auto_sale_cont.bm1_invoice_t_no%TYPE,              -- �o�^�ԍ��i���t��j
--  Ver1.18 T.Okuyama Add End
    condition_contents_flag       BOOLEAN,                                              -- �̔��萔�����L���t���O
    install_support_amt_flag      BOOLEAN,                                              -- �ݒu���^���L���t���O
    electricity_information_flag  BOOLEAN                                              -- �d�C����L���t���O
-- 2020/05/07 Ver1.14 N.Abe ADD START
   ,bm_tax_kbn                    xxcso_rep_auto_sale_cont.bm_tax_kbn%TYPE                     -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
  );
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
  -- �o�����[���[�N�e�[�u�� �f�[�^�i�[�p���R�[�h�^��`
  TYPE g_rep_memo_data_rtype IS RECORD(
    contract_number               xxcso_rep_memorandum.contract_number%TYPE,
    contract_other_custs_id       xxcso_rep_memorandum.contract_other_custs_id%TYPE,
    contract_name                 xxcso_rep_memorandum.contract_name%TYPE,
    contract_effect_date          xxcso_rep_memorandum.contract_effect_date%TYPE,
    install_name                  xxcso_rep_memorandum.install_name%TYPE,
    install_address               xxcso_rep_memorandum.install_address%TYPE,
    tax_type_name                 xxcso_rep_memorandum.tax_type_name%TYPE,
    install_supp_amt              xxcso_rep_memorandum.install_supp_amt%TYPE,
    install_supp_payment_date     xxcso_rep_memorandum.install_supp_payment_date%TYPE,
    install_supp_bk_chg_bearer    xxcso_rep_memorandum.install_supp_bk_chg_bearer%TYPE,
    install_supp_bk_number        xxcso_rep_memorandum.install_supp_bk_number%TYPE,
    install_supp_bk_name          xxcso_rep_memorandum.install_supp_bk_name%TYPE,
    install_supp_branch_number    xxcso_rep_memorandum.install_supp_branch_number%TYPE,
    install_supp_branch_name      xxcso_rep_memorandum.install_supp_branch_name%TYPE,
    install_supp_bk_acct_type     xxcso_rep_memorandum.install_supp_bk_acct_type%TYPE,
    install_supp_bk_acct_number   xxcso_rep_memorandum.install_supp_bk_acct_number%TYPE,
    install_supp_bk_acct_name_alt xxcso_rep_memorandum.install_supp_bk_acct_name_alt%TYPE,
    install_supp_bk_acct_name     xxcso_rep_memorandum.install_supp_bk_acct_name%TYPE,
    install_supp_org_addr         xxcso_rep_memorandum.install_supp_org_addr%TYPE,
    install_supp_org_name         xxcso_rep_memorandum.install_supp_org_name%TYPE,
    install_supp_org_boss_pos     xxcso_rep_memorandum.install_supp_org_boss_pos%TYPE,
    install_supp_org_boss         xxcso_rep_memorandum.install_supp_org_boss%TYPE,
    install_supp_preamble         xxcso_rep_memorandum.install_supp_preamble%TYPE,
    intro_chg_amt                 xxcso_rep_memorandum.intro_chg_amt%TYPE,
    intro_chg_payment_date        xxcso_rep_memorandum.intro_chg_payment_date%TYPE,
    intro_chg_closing_date        xxcso_rep_memorandum.intro_chg_closing_date%TYPE,
    intro_chg_trans_month         xxcso_rep_memorandum.intro_chg_trans_month%TYPE,
    intro_chg_trans_date          xxcso_rep_memorandum.intro_chg_trans_date%TYPE,
    intro_chg_trans_name          xxcso_rep_memorandum.intro_chg_trans_name%TYPE,
    intro_chg_trans_name_alt      xxcso_rep_memorandum.intro_chg_trans_name_alt%TYPE,
    intro_chg_bk_chg_bearer       xxcso_rep_memorandum.intro_chg_bk_chg_bearer%TYPE,
    intro_chg_bk_number           xxcso_rep_memorandum.intro_chg_bk_number%TYPE,
    intro_chg_bk_name             xxcso_rep_memorandum.intro_chg_bk_name%TYPE,
    intro_chg_branch_number       xxcso_rep_memorandum.intro_chg_branch_number%TYPE,
    intro_chg_branch_name         xxcso_rep_memorandum.intro_chg_branch_name%TYPE,
    intro_chg_bk_acct_type        xxcso_rep_memorandum.intro_chg_bk_acct_type%TYPE,
    intro_chg_bk_acct_number      xxcso_rep_memorandum.intro_chg_bk_acct_number%TYPE,
    intro_chg_bk_acct_name_alt    xxcso_rep_memorandum.intro_chg_bk_acct_name_alt%TYPE,
    intro_chg_bk_acct_name        xxcso_rep_memorandum.intro_chg_bk_acct_name%TYPE,
    intro_chg_org_addr            xxcso_rep_memorandum.intro_chg_org_addr%TYPE,
    intro_chg_org_name            xxcso_rep_memorandum.intro_chg_org_name%TYPE,
    intro_chg_org_boss_pos        xxcso_rep_memorandum.intro_chg_org_boss_pos%TYPE,
    intro_chg_org_boss            xxcso_rep_memorandum.intro_chg_org_boss%TYPE,
    intro_chg_preamble            xxcso_rep_memorandum.intro_chg_preamble%TYPE,
    electric_amt                  xxcso_rep_memorandum.electric_amt%TYPE,
    electric_closing_date         xxcso_rep_memorandum.electric_closing_date%TYPE,
    electric_trans_month          xxcso_rep_memorandum.electric_trans_month%TYPE,
    electric_trans_date           xxcso_rep_memorandum.electric_trans_date%TYPE,
    electric_trans_name           xxcso_rep_memorandum.electric_trans_name%TYPE,
    electric_trans_name_alt       xxcso_rep_memorandum.electric_trans_name_alt%TYPE,
    electric_bk_chg_bearer        xxcso_rep_memorandum.electric_bk_chg_bearer%TYPE,
    electric_bk_number            xxcso_rep_memorandum.electric_bk_number%TYPE,
    electric_bk_name              xxcso_rep_memorandum.electric_bk_name%TYPE,
    electric_branch_number        xxcso_rep_memorandum.electric_branch_number%TYPE,
    electric_branch_name          xxcso_rep_memorandum.electric_branch_name%TYPE,
    electric_bk_acct_type         xxcso_rep_memorandum.electric_bk_acct_type%TYPE,
    electric_bk_acct_number       xxcso_rep_memorandum.electric_bk_acct_number%TYPE,
    electric_bk_acct_name_alt     xxcso_rep_memorandum.electric_bk_acct_name_alt%TYPE,
    electric_bk_acct_name         xxcso_rep_memorandum.electric_bk_acct_name%TYPE,
    electric_org_addr             xxcso_rep_memorandum.electric_org_addr%TYPE,
    electric_org_name             xxcso_rep_memorandum.electric_org_name%TYPE,
    electric_org_boss_pos         xxcso_rep_memorandum.electric_org_boss_pos%TYPE,
    electric_org_boss             xxcso_rep_memorandum.electric_org_boss%TYPE,
    electric_preamble             xxcso_rep_memorandum.electric_preamble%TYPE,
    install_supp_memo_flg         NUMBER,
    intro_chg_memo_flg            NUMBER,
    electric_memo_flg             NUMBER
  );
  --�o���o�͗v��ID
  TYPE g_org_request_rtype IS RECORD(
    request_id                    fnd_concurrent_requests.request_id%TYPE
  );
  TYPE g_org_request_ttype IS TABLE OF g_org_request_rtype INDEX BY PLS_INTEGER;
  g_org_request  g_org_request_ttype;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--  Ver1.16 K.Kanada Add Start
  TYPE g_contents_msg_ttype IS TABLE OF VARCHAR2(240) INDEX BY PLS_INTEGER;           -- �������e�Œ蕶�p�e�[�u���^�ϐ�
  g_contents_msg  g_contents_msg_ttype;
--  Ver1.16 K.Kanada Add End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ot_status           OUT NOCOPY VARCHAR2       -- �X�e�[�^�X
    ,ot_cooperate_flag   OUT NOCOPY VARCHAR2       -- �}�X�^�A�g�t���O
    ,ov_errbuf           OUT NOCOPY VARCHAR2       -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2       -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���萔 ***
    cv_con_mng_id        CONSTANT VARCHAR2(100)   := '�����̔��@�ݒu�_��ID';
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(5000);
-- == 2010/08/03 V1.9 Added START ===============================================================
    lv_err_key          VARCHAR2(30);
-- == 2010/08/03 V1.9 Added END   ===============================================================
--  Ver1.16 K.Kanada Add Start
    ln_loop_cnt          NUMBER ;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR condition_contents_cur
    IS
      SELECT flvv.description
      FROM   fnd_lookup_values_vl  flvv               -- �Q�ƃ^�C�v�e�[�u��
      WHERE  flvv.lookup_type  = cv_lkup_condition_contents
      AND    flvv.enabled_flag = cv_enabled_flag
      ORDER BY flvv.lookup_code
      ;
--  Ver1.16 K.Kanada Add End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================================
    -- �p�����[�^�K�{�`�F�b�N(�����̔��@�ݒu�_��ID)
    -- ===================================================
    IF (gt_con_mng_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_01         -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================
    -- �N���p�����[�^���b�Z�[�W�o��
    -- ===========================
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name            --�A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_09       --���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_param_nm        --�g�[�N���R�[�h1
                ,iv_token_value1 => cv_con_mng_id          --�g�[�N���l1
                ,iv_token_name2  => cv_tkn_val             --�g�[�N���R�[�h2
                ,iv_token_value2 => TO_CHAR(gt_con_mng_id) --�g�[�N���l2
              );
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>'' || CHR(10) || lv_msg
    );
--
    -- ===================================================
    -- �_�񏑔ԍ��A�X�e�[�^�X�A�}�X�^�A�g�t���O���擾
    -- ===================================================
    BEGIN
      SELECT xcm.contract_number contract_number
            ,xcm.status status
            ,xcm.cooperate_flag cooperate_flag
      INTO   gt_contract_number
            ,ot_status
            ,ot_cooperate_flag
      FROM   xxcso_contract_managements xcm
      WHERE  xcm.contract_management_id = gt_con_mng_id;
--
    -- ===========================
    -- �_�񏑔ԍ����b�Z�[�W�o��
    -- ===========================
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                ,iv_name         => cv_tkn_number_02             -- ���b�Z�[�W�R�[�h
                ,iv_token_name1  => cv_tkn_contract_num          -- �g�[�N���R�[�h1
                ,iv_token_value1 => gt_contract_number           -- �g�[�N���l1
              );
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   =>'' || CHR(10) || lv_msg
    );
--
    EXCEPTION
      -- �f�[�^���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_con_mng_id          -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gt_con_mng_id)     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
--
-- == 2010/08/03 V1.9 Added START ===============================================================
    BEGIN
      -- ===========================
      -- �_�񏑏o�͓���^
      -- ===========================
      lv_err_key  :=  cv_msg_xxcso_00604;
      --
      SELECT  fnm.message_text      message_text                  --  ���s�e�L�X�g���b�Z�[�W
      INTO    gt_contract_date_ptn                                --  �_�񏑏o�͓���^
      FROM    fnd_new_messages      fnm                           --  ���b�Z�[�W
            , fnd_application       fa                            --  �A�v���P�[�V����
      WHERE   fnm.application_id          =   fa.application_id
      AND     fnm.message_name            =   cv_msg_xxcso_00604
      AND     fnm.language_code           =   USERENV('LANG')
      AND     fa.application_short_name   =   cv_app_name;
      -- ===========================
      -- �̔��萔���A���i�����ʁj
      -- ===========================
      lv_err_key  :=  cv_msg_xxcso_00605;
      --
      SELECT  fnm.message_text      message_text                  --  ���s�e�L�X�g���b�Z�[�W
      INTO    gt_terms_note_price                                 --  �̔��萔���A���i�����ʁj
      FROM    fnd_new_messages      fnm                           --  ���b�Z�[�W
            , fnd_application       fa                            --  �A�v���P�[�V����
      WHERE   fnm.application_id          =   fa.application_id
      AND     fnm.message_name            =   cv_msg_xxcso_00605
      AND     fnm.language_code           =   USERENV('LANG')
      AND     fa.application_short_name   =   cv_app_name;
      -- ===========================
      -- �̔��萔���A���i�e��ʁj
      -- ===========================
      lv_err_key  :=  cv_msg_xxcso_00606;
      --
      SELECT  fnm.message_text      message_text                  --  ���s�e�L�X�g���b�Z�[�W
      INTO    gt_terms_note_ves                                   --  �̔��萔���A���i�e��ʁj
      FROM    fnd_new_messages      fnm                           --  ���b�Z�[�W
            , fnd_application       fa                            --  �A�v���P�[�V����
      WHERE   fnm.application_id          =   fa.application_id
      AND     fnm.message_name            =   cv_msg_xxcso_00606
      AND     fnm.language_code           =   USERENV('LANG')
      AND     fa.application_short_name   =   cv_app_name;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_app_name                -- �A�v���P�[�V�����Z�k��
                        , iv_name           =>  cv_msg_xxcso_00470           -- ���b�Z�[�W�R�[�h
                        , iv_token_name1    =>  cv_tkn_xxcso_00470_01
                        , iv_token_value1   =>  cv_cnst_message
                        , iv_token_name2    =>  cv_tkn_xxcso_00470_02
                        , iv_token_value2   =>  cv_cnst_item_name
                        , iv_token_name3    =>  cv_tkn_xxcso_00470_03
                        , iv_token_value3   =>  lv_err_key
                      );
        lv_errbuf :=  lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- ===================================================
    -- �O���Œ蕔�擾
    -- ===================================================
    BEGIN
      SELECT
        flvv.attribute1 || flvv.attribute2 install_supp_pre    -- �O���Œ蕔�i�ݒu���^���j
       ,flvv.attribute1 || flvv.attribute3 intro_chg_pre1      -- �O���Œ蕔1�i�Љ�萔���j
       ,flvv.attribute1 || flvv.attribute4 intro_chg_pre2      -- �O���Œ蕔2�i�Љ�萔���j
       ,flvv.attribute1 || flvv.attribute5 electric_pre1       -- �O���Œ蕔1�i�d�C��j
       ,flvv.attribute6                    electric_pre2       -- �O���Œ蕔2�i�d�C��j
       ,flvv.attribute7 || flvv.attribute9 electric_pre3       -- �O���Œ蕔3�i�d�C��j
       ,flvv.attribute8 || flvv.attribute9 electric_pre4       -- �O���Œ蕔4�i�d�C��j
      INTO
        gv_install_supp_pre                          -- �O���Œ蕔�i�ݒu���^���j
       ,gv_intro_chg_pre1                            -- �O���Œ蕔1�i�Љ�萔���j
       ,gv_intro_chg_pre2                            -- �O���Œ蕔2�i�Љ�萔���j
       ,gv_electric_pre1                             -- �O���Œ蕔1�i�d�C��j
       ,gv_electric_pre2                             -- �O���Œ蕔2�i�d�C��j
       ,gv_electric_pre3                             -- �O���Œ蕔3�i�d�C��j
       ,gv_electric_pre4                             -- �O���Œ蕔4�i�d�C��j
      FROM  fnd_lookup_values_vl  flvv               -- �Q�ƃ^�C�v�e�[�u��
      WHERE flvv.lookup_type  = cv_lkup_preamble_type
      AND   flvv.lookup_code  = cv_lkup_preamble_code
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- �A�v���P�[�V�����Z�k��
                        ,iv_name           => cv_tkn_number_12           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1    => cv_tkn_contract_num        -- �g�[�N���FCONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- �_�񏑔ԍ�
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ===================================================
    -- ���s���������R�[�h�擾
    -- ===================================================
    BEGIN
      SELECT
            flvv.attribute1  gen_mgr_pos_code            -- �{�����E��
           ,flvv.attribute2  e_vice_pres_base            -- �����{�����������_
           ,flvv.attribute3  e_vice_pres_qual            -- �����{�������i�R�[�h
      INTO
            gt_gen_mgr_pos_code                          -- �{�����E��
           ,gt_e_vice_pres_base                          -- �����{�����������_
           ,gt_e_vice_pres_qual                          -- �����{�������i�R�[�h
      FROM  fnd_lookup_values_vl flvv                    -- �Q�ƃ^�C�v�e�[�u��
      WHERE flvv.lookup_type  = cv_lkup_org_boss_code
      AND   flvv.lookup_code  = cv_e_vice_org_cd
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- �A�v���P�[�V�����Z�k��
                        ,iv_name           => cv_tkn_number_13           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1    => cv_tkn_contract_num        -- �g�[�N���FCONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- �_�񏑔ԍ�
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ===================================================
    -- �ݒu���^�����z����擾
    -- ===================================================
    -- �x�X��
    BEGIN
      SELECT
        flvv.attribute3  is_amt_branch             -- �x�X���i�ݒu���^�����z����j
      INTO
        gn_is_amt_branch                           -- �x�X���i�ݒu���^�����z����j
      FROM  fnd_lookup_values_vl flvv              -- �Q�ƃ^�C�v�e�[�u��
      WHERE flvv.lookup_type  = cv_lkup_is_ic_appv_cls
      AND   flvv.lookup_code  = cv_appv_cls_br_mgr
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- �A�v���P�[�V�����Z�k��
                        ,iv_name           => cv_tkn_number_14           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1    => cv_tkn_contract_num        -- �g�[�N���FCONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- �_�񏑔ԍ�
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �n��c�Ɩ{����
    BEGIN
      SELECT
        flvv.attribute3  is_amt_areamgr             -- �n��c�Ɩ{�����i�ݒu���^�����z����j
      INTO
        gn_is_amt_areamgr                           -- �n��c�Ɩ{�����i�ݒu���^�����z����j
      FROM  fnd_lookup_values_vl flvv               -- �Q�ƃ^�C�v�e�[�u��
      WHERE flvv.lookup_type  = cv_lkup_is_ic_appv_cls
      AND   flvv.lookup_code  = cv_appv_cls_areamgr
      AND   flvv.enabled_flag = cv_enabled_flag
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application    => cv_app_name                -- �A�v���P�[�V�����Z�k��
                        ,iv_name           => cv_tkn_number_14           -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1    => cv_tkn_contract_num        -- �g�[�N���FCONTRACT_NUMBER
                        ,iv_token_value1   => gt_contract_number         -- �_�񏑔ԍ�
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
    END;
--
--  Ver1.16 K.Kanada Add Start
    -- ===================================================
    -- �������e�Œ蕶�擾
    -- ===================================================
    ln_loop_cnt := 0 ;
    << condition_contents_get_loop >>
    FOR lt_condition_contents_rec IN condition_contents_cur LOOP
      ln_loop_cnt := ln_loop_cnt + 1 ;
      g_contents_msg(ln_loop_cnt) := lt_condition_contents_rec.description ;
    END LOOP condition_contents_get_loop ;
    -- �v���t�@�C���l�`�F�b�N
    IF ( ln_loop_cnt <> cv_contents_msg_max ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcso_00911  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--  Ver1.16 K.Kanada Add End
--
    -- ===================================================
    -- �v���t�@�C���擾
    -- ===================================================
    -- XXCSO:�ҋ@�Ԋu�i�o���o�́j
    gn_interval := TO_NUMBER(FND_PROFILE.VALUE( cv_interval ));
    -- �v���t�@�C���l�`�F�b�N
    IF ( gn_interval IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_15  -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_name  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_interval       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- XXCOS:�ő�ҋ@���ԁi�o���o�́j
    gn_max_wait := TO_NUMBER(FND_PROFILE.VALUE( cv_max_wait ));
    -- �v���t�@�C���l�`�F�b�N
    IF ( gn_max_wait IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_15  -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_name  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_max_wait       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--  Ver1.18 T.Okuyama Add Start
    -- �K�i���������s���Ǝғo�^�ԍ��i���Ёj�擾
    gv_t_number := FND_PROFILE.VALUE(cv_t_number);
    -- �v���t�@�C���l�`�F�b�N
    IF ( gv_t_number IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_15  -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_prof_name  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_t_number       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--  Ver1.18 T.Okuyama Add End
    -- ===================================================
    -- �o���̔��s��ʏo�͗p���̂̎擾
    -- ===================================================
    --�ݒu���^��
    gv_conc_des_inst     := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_16      -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_contract_num   -- �g�[�N���R�[�h1
                              ,iv_token_value1 => gt_contract_number    -- �g�[�N���l1
                            );
    --�d�C��
    gv_conc_des_electric := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_17      -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_contract_num   -- �g�[�N���R�[�h1
                              ,iv_token_value1 => gt_contract_number    -- �g�[�N���l1
                            );
    --�Љ�萔��
    gv_conc_des_intro    := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name           -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_18      -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_contract_num   -- �g�[�N���R�[�h1
                              ,iv_token_value1 => gt_contract_number    -- �g�[�N���l1
                            );
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
  EXCEPTION
    -- *** ������O�n���h�� ***
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
   * Procedure Name   : get_contract_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_contract_data(
     iv_process_flag       IN         VARCHAR2               -- �����t���O
    ,o_rep_cont_data_rec   OUT NOCOPY g_rep_cont_data_rtype  -- �_�񏑃f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ,o_rep_memo_data_rec   OUT NOCOPY g_rep_memo_data_rtype  -- �o���f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    ,ov_errbuf             OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode            OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg             OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_contract_data';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �󎆕\���t���O
    cv_stamp_show_1          CONSTANT VARCHAR2(1)   := '1';  -- �\��
    cv_stamp_show_0          CONSTANT VARCHAR2(1)   := '0';  -- ��\��
    -- �ݒu���P�[�V����
    cv_i_location_type_2     CONSTANT VARCHAR2(1)   := '2';  -- ���O
    cv_i_location_type_3     CONSTANT VARCHAR2(1)   := '3';  -- �H��
    -- �d�C��敪
    cv_electricity_type_1    CONSTANT VARCHAR2(1)   := '1';
    cv_electricity_type_2    CONSTANT VARCHAR2(1)   := '2';
    -- �U���萔�����S�敪
    cv_bank_trans_fee_div_1  CONSTANT VARCHAR2(1)   := 'S';
    cv_bank_trans_fee_div_2  CONSTANT VARCHAR2(1)   := 'I';
    -- ��������敪
    cv_cond_b_type_1         CONSTANT VARCHAR2(1)   := '1';  -- �����ʏ���
    cv_cond_b_type_2         CONSTANT VARCHAR2(1)   := '2';  -- �����ʏ����i��t���o�^�p�j
    cv_cond_b_type_3         CONSTANT VARCHAR2(1)   := '3';  -- �ꗥ�E�e��ʏ���
    cv_cond_b_type_4         CONSTANT VARCHAR2(1)   := '4';  -- �ꗥ�E�e��ʏ����i��t���o�^�p�j
    -- SP�ꌈ�ڋq�敪
    cv_sp_d_cust_class_3     CONSTANT VARCHAR2(1)   := '3';  -- �a�l�P
    -- ���t�敪
    cv_delivery_div_1        CONSTANT VARCHAR2(1)   := '1';  -- �a�l�P
    -- �E�ʃR�[�h
    cv_p_code_002            CONSTANT VARCHAR2(3)   := '002';
    cv_p_code_003            CONSTANT VARCHAR2(3)   := '003';
    -- �r�o�ꌈ�e��ʎ������(�N�C�b�N�R�[�h)
    cv_lkup_container_type   CONSTANT VARCHAR2(100) := 'XXCSO1_SP_RULE_BOTTLE';
    -- ���^�C�v(�N�C�b�N�R�[�h)
    cv_lkup_months_type      CONSTANT VARCHAR2(100) := 'XXCSO1_MONTHS_TYPE';
    -- �����̔��@�ݒu�_�񏑌_��ҕ������e(�N�C�b�N�R�[�h)
    cv_lkup_contract_nm_con  CONSTANT VARCHAR2(100) := 'XXCSO1_CONTRACT_NM_CONTENT';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- SP�ꌈ�ŋ敪(�N�C�b�N�R�[�h)
    cv_lkup_sp_tax_type      CONSTANT VARCHAR2(100) := 'XXCSO1_SP_TAX_DIVISION';  -- SP�ꌈ�ŋ敪
    cv_in_tax                CONSTANT VARCHAR2(1)   := '1';                       -- �ō�
    cv_ex_tax                CONSTANT VARCHAR2(1)   := '2';                       -- �Ŕ�
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    -- �ȉ��]��
    cv_cond_conts_space      CONSTANT VARCHAR2(8)   := '�ȉ��]��';
    -- �藦
    cv_tei_rate              CONSTANT VARCHAR2(10)  := '�藦�i�z�j';
    -- ������
    cv_uri_rate              CONSTANT VARCHAR2(6)   := '������';
    -- �e���
    cv_youki_rate            CONSTANT VARCHAR2(6)   := '�e���';
    -- �r�o�ꌈ���׃e�[�u��
    cv_sp_decision_lines     CONSTANT VARCHAR2(100) := '�r�o�ꌈ���׃e�[�u��';
    -- �X�փ}�[�N
    cv_post_mark             CONSTANT VARCHAR2(2)   := '��';
    /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
    -- �a�l�x�����@�E���׏�
    cv_csh_pymnt             CONSTANT VARCHAR2(1)   := '4';  -- �����x��
    /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
    -- *** ���[�J���ϐ� ***
    lv_cond_business_type    VARCHAR2(1);       -- ��������敪
    ld_sysdate               DATE;              -- �Ɩ����t
    lv_cond_conts_tmp        xxcso_rep_auto_sale_cont.condition_contents_1%TYPE;    -- �������e1
    ln_lines_cnt             NUMBER;            -- ���׌���
    ln_bm1_bm_rate           NUMBER;            -- �a�l�P�a�l��
    ln_bm1_bm_amount         NUMBER;            -- �a�l�P�a�l���z
    lb_bm1_bm_rate           BOOLEAN;           -- �a�l�P�a�l���ɂ��藦���f�t���O
    lb_bm1_bm_amount         BOOLEAN;           -- �a�l�P�a�l���z�ɂ��藦���f�t���O
    lb_bm1_bm                BOOLEAN;           -- �̔��萔���L���t���O(TRUE:�L,FALSE:��)
    /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 START */
    ln_work_cnt              NUMBER;            -- ��z���f�������J�E���g�p
    ln_work_cnt_ritu         NUMBER;            -- �����f�������J�E���g�p
    ln_work_cnt_gaku         NUMBER;            -- �z���f�������J�E���g�p
    /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 END */
-- == 2010/08/03 V1.9 Added START ===============================================================
    lv_condition_content_type VARCHAR2(1);      --  �S�e��ꗥ�敪
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    lt_install_supp_amt      xxcso_sp_decision_headers.install_support_amt%TYPE;
    lt_area_mgr_base_cd      xxcmm_hierarchy_dept_all_v.cur_dpt_cd%TYPE;
    lt_a_mgr_boss_org_ad     xxcso_rep_memorandum.intro_chg_org_addr%TYPE;
    lt_a_mgr_boss_org_nm     xxcso_locations_v2.location_name%TYPE;
    lt_a_mgr_boss_pos        xxcso_employees_v2.position_name_new%TYPE;
    lt_a_mgr_boss            xxcso_employees_v2.full_name%TYPE;
    lt_e_vice_pres_org_ad    xxcso_rep_memorandum.install_supp_org_addr%TYPE;
    lt_e_vice_pres_org_nm    fnd_lookup_values_vl.meaning%TYPE;
    lt_e_vice_pres_pos       xxcso_employees_v2.position_name_new%TYPE;
    lt_e_vice_pres           xxcso_employees_v2.full_name%TYPE;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
    -- *** ���[�J���E�J�[�\�� *** 
    CURSOR l_sales_charge_cur
    IS
      SELECT xsdh.sp_decision_header_id sp_decision_header_id        -- �r�o�ꌈ�w�b�_�h�c
            ,xsdl.sp_decision_line_id sp_decision_line_id           -- �r�o�ꌈ���ׂh�c
            ,xcm.close_day_code close_day_code                      -- ���ߓ�
            ,(SELECT flvv_month.meaning                             -- ���e
              FROM   fnd_lookup_values_vl flvv_month                -- �Q�ƃ^�C�v�e�[�u��
              WHERE  flvv_month.lookup_type = cv_lkup_months_type
                AND  TRUNC(SYSDATE) BETWEEN TRUNC(flvv_month.start_date_active)
                                    AND TRUNC(NVL(flvv_month.end_date_active, SYSDATE))
                AND  flvv_month.enabled_flag = cv_enabled_flag
                AND  xcm.transfer_month_code = flvv_month.lookup_code
                AND  ROWNUM = 1
              ) transfer_month_code                                 -- ������
            ,xcm.transfer_day_code transfer_day_code                -- ������
            ,xsdh.condition_business_type condition_business_type   -- ��������敪
            ,xsdl.sp_container_type sp_container_type               -- �r�o�e��敪
            ,xsdl.fixed_price fixed_price                           -- �艿
            ,xsdl.sales_price sales_price                           -- ����
            ,xsdl.bm1_bm_rate bm1_bm_rate                           -- �a�l�P�a�l��
            ,xsdl.bm1_bm_amount bm1_bm_amount                       -- �a�l�P�a�l���z
-- == 2010/08/03 V1.9 Modified START ===============================================================
--            ,(CASE
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
--                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
--                 '�̔����i ' || TO_CHAR(xsdl.sales_price)
--                             || '�~�̂Ƃ��A�P�{�ɂ��̔����i�� '
--                             || TO_CHAR(xsdl.bm1_bm_rate) || '%���x����'
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
--                       AND (xsdl.bm1_bm_amount IS NOT NULL AND xsdl.bm1_bm_amount <> '0')) THEN
--                 '�̔����i ' || TO_CHAR(xsdl.sales_price)
--                             || '�~�̂Ƃ��A�P�{�ɂ� '
--                             || TO_CHAR(xsdl.bm1_bm_amount) || '�~���x����'
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--                       AND (xsdl.bm1_bm_rate IS NOT NULL AND xsdl.bm1_bm_rate <> '0')) THEN
--                 '�̔��e�킪 ' || flvv.meaning
--                               || '�̂Ƃ��A�P�{�ɂ������� '
--                               || TO_CHAR(xsdl.bm1_bm_rate) || '%���x����'
--               WHEN ((xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--                       AND (xsdl.bm1_bm_amount IS NOT NULL  AND xsdl.bm1_bm_amount <> '0')) THEN
--                 '�̔��e�킪 ' || flvv.meaning
--                               || '�̂Ƃ��A�P�{�ɂ� '
--                               || TO_CHAR(xsdl.bm1_bm_amount) || '�~���x����'
--              END) condition_contents                               -- �������e
--  Ver1.16 K.Kanada Add+Els Start
--            , CASE
--                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
--                        AND (xsdl.bm1_bm_rate IS NOT NULL)
--                        AND (xsdl.bm1_bm_rate <> '0')
--                      )
--                THEN      '�̔����i '
--                      ||  TO_CHAR(xsdl.sales_price)
--                      ||  '�~�̏��i�ɂ��A�̔����z�ɑ΂��A'
--                      ||  TO_CHAR(xsdl.bm1_bm_rate)
--                      ||  '%�Ƃ���B'
--                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2))
--                        AND (xsdl.bm1_bm_amount IS NOT NULL)
--                        AND (xsdl.bm1_bm_amount <> '0')
--                      )
--                THEN      '�̔����i '
--                      ||  TO_CHAR(xsdl.sales_price)
--                      ||  '�~�̏��i�ɂ��A�P�{������ '
--                      ||  TO_CHAR(xsdl.bm1_bm_amount)
--                      ||  '�~�Ƃ���B'
--                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--                        AND (xsdl.bm1_bm_rate IS NOT NULL)
--                        AND (xsdl.bm1_bm_rate <> '0')
--                      )
--                THEN      flvv.meaning
--                      ||  '���i�ɂ��A�̔����z�ɑ΂��A'
--                      ||  TO_CHAR(xsdl.bm1_bm_rate)
--                      ||  '%�Ƃ���B'
--                WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--                        AND (xsdl.bm1_bm_amount IS NOT NULL)
--                        AND (xsdl.bm1_bm_amount <> '0')
--                      )
--                THEN      flvv.meaning
--                      ||  '���i�ɂ��A�P�{������ '
--                      ||  TO_CHAR(xsdl.bm1_bm_amount)
--                      ||  '�~�Ƃ���B'
--              END                                 condition_contents                          --  �������e
            ,flvv.meaning                 container_type_name       -- �e��敪��
--  Ver1.16 K.Kanada Add+Els End
            , CASE  WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                            AND (xsdl.bm1_bm_rate IS NOT NULL)
                            AND (xsdl.bm1_bm_rate <> 0)
                            AND (NVL(xsdh.all_container_type, '*') = '1')
                          )
                    THEN    '1'       --  �S�e��ꗥ�i���[�g�j
                    WHEN  (     (xsdh.condition_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
                            AND (xsdl.bm1_bm_amount IS NOT NULL)
                            AND (xsdl.bm1_bm_amount <> 0)
                            AND (NVL(xsdh.all_container_type, '*') = '1')
                          )
                    THEN    '2'       --  �S�e��ꗥ�i���i�j
                    ELSE    '0'       --  �S�e��ꗥ�ȊO
              END                                 condition_content_type                      --  �S�e��ꗥ�敪
-- == 2010/08/03 V1.9 Modified END   ===============================================================
       FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
             ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
             ,xxcso_sp_decision_lines    xsdl     -- �r�o�ꌈ���׃e�[�u��
             ,(SELECT  flv.meaning
                       ,flv.lookup_code
                       /* 2009.04.27 K.Satomura T1_0778�Ή� START */
                       ,flv.attribute4
                       /* 2009.04.27 K.Satomura T1_0778�Ή� END */
                 FROM  fnd_lookup_values_vl flv
                WHERE  flv.lookup_type = cv_lkup_container_type
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flv.start_date_active)
                  AND  TRUNC(NVL(flv.end_date_active, ld_sysdate))
                  AND  flv.enabled_flag = cv_enabled_flag
              )  flvv    -- �Q�ƃ^�C�v
       WHERE  xcm.contract_management_id = gt_con_mng_id
         AND  xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
         AND  xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
         AND  xsdh.condition_business_type
                IN (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
       /* 2009.04.27 K.Satomura T1_0778�Ή� START */
         --AND  xsdl.sp_container_type = flvv.lookup_code(+);
         AND  xsdl.sp_container_type = flvv.lookup_code(+)
       ORDER BY DECODE(xsdh.condition_business_type
                      ,cv_cond_b_type_1 ,xsdl.sp_decision_line_id
                      ,cv_cond_b_type_2 ,xsdl.sp_decision_line_id
                      ,cv_cond_b_type_3 ,flvv.attribute4
                      ,cv_cond_b_type_4 ,flvv.attribute4
                      )
       ;
       /* 2009.04.27 K.Satomura T1_0778�Ή� END */

--
    -- *** ���[�J���E���R�[�h *** 
    l_sales_charge_rec  l_sales_charge_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t
    ld_sysdate := TRUNC(xxcso_util_common_pkg.get_online_sysdate);  -- ���ʊ֐��ɂ��Ɩ����t���i�[
--
    -- �����t���O
    -- �X�e�[�^�X���쐬���̏ꍇ�A�܂��̓X�e�[�^�X���m��ρA���}�X�^�A�g�t���O�����A�g�̏ꍇ
    IF (iv_process_flag = cv_flag_1) THEN
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10)
             || '���� �_��֘A���F�X�e�[�^�X���쐬���A�܂��̓X�e�[�^�X���m��ρA���}�X�^�A�g�t���O�����A�g ����'
      );
--
      -- ===========================
      -- �_��֘A���擾�iA-2-1-1�j
      -- ===========================
      BEGIN
        SELECT (CASE
                  WHEN (SUBSTR(xcav.establishment_location, 2, 1)
                          IN (cv_i_location_type_2, cv_i_location_type_3)) THEN
                    cv_stamp_show_1
                  ELSE cv_stamp_show_0
                END) install_location                              -- �ݒu���P�[�V����
              ,xcm.contract_number   contract_number               -- �_�񏑔ԍ�
              /* 2009.09.14 M.Maruyama 0001355�Ή� START */
              --,((SELECT xcc.contract_name 
              ,SUBSTRB(((SELECT SUBSTRB(xcc.contract_name, 1, 100)
                 FROM   xxcso_contract_customers xcc   -- �_���e�[�u��
                 WHERE  xcc.contract_customer_id = xcm.contract_customer_id
                   AND  ROWNUM = 1
               --) || flvv_con.attr) contract_name               -- �_�񏑖�
               ) || flvv_con.attr), 1, 660) contract_name         -- �_�񏑖�
              /* 2009.09.14 M.Maruyama 0001355�Ή� END */
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--              ,xsdh.contract_year_date contract_period             -- �_�����
              ,CASE xsdh.contract_year_date
                 WHEN 0 THEN 1
                 ELSE xsdh.contract_year_date
               END contract_period                                   -- �_�����
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
              ,xcm.cancellation_offer_code cancellation_offer_code -- �_������\���o
              ,xsdh.other_content other_content                    -- ���񎖍�
              ,xd.payment_name sales_charge_details_delivery       -- �x���於
              /* 2009.10.15 D.Abe 0001536,0001537�Ή� START */
              --,(NVL2(xd.post_code, cv_post_mark || xd.post_code || ' ', '') || xd.prefectures || xd.city_ward
              ,(NVL2(xd.post_code, cv_post_mark || xd.post_code || ' ', '')
              /* 2009.10.15 D.Abe 0001536,0001537�Ή� END */
                             || xd.address_1 || xd.address_2) delivery_address  -- ���t��Z��
              ,xcm.install_party_name install_name                 -- �ݒu��ڋq��
              ,(NVL2(xcm.install_postal_code, cv_post_mark || xcm.install_postal_code || ' ', '')
                           || xcm.install_state || xcm.install_city
                           || xcm.install_address1 || xcm.install_address2) install_address  -- �ݒu��Z��
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--              ,(SUBSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                 , 1, INSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
              ,TO_CHAR(xcm.install_date, cv_format_yyyymmdd_date
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                ) install_date                                     -- �ݒu��
              /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
              --,xba.bank_name bank_name                             -- ��s��
              --,xba.branch_name blanches_name                       -- �x�X��
              --,xba.bank_account_number bank_account_number         -- �����ԍ�
              --,xba.bank_account_name_kana bank_account_name_kana   -- �������`�J�i
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
                          , xba.bank_name)
                ) bank_name                                        -- ��s��
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
                          , xba.branch_name)
                ) blanches_name                                    -- �x�X��
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
-- == 2010/08/03 V1.9 Modified START ===============================================================
--                          , xba.bank_account_number)
                          , flv.bank_acct_type_name || cv_space || xba.bank_account_number)
-- == 2010/08/03 V1.9 Modified END   ===============================================================
                ) bank_account_number                              -- �����ԍ�
              ,(DECODE(xd.belling_details_div
                          , cv_csh_pymnt, NULL
                          , xba.bank_account_name_kana)
                ) bank_account_name_kana                          -- �������`�J�i
              /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
              ,xcm.install_account_number account_number           -- �ݒu��ڋq�R�[�h
              ,xcm.publish_dept_code publish_base_code             -- �S�������R�[�h
              ,xlv2.location_name publish_base_name                -- �S�����_��
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
--                ) contract_effect_date                             -- �_�񏑔�����
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--              , NVL(SUBSTR(   TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                            , 1
--                            , INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1
              ,NVL(TO_CHAR(xcm.contract_effect_date, cv_format_yyyymmdd_date
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                    ), gt_contract_date_ptn
                )     contract_effect_date                             -- �_�񏑔�����
-- == 2010/08/03 V1.9 Modified END   ===============================================================
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '')
                    || xlv2.address_line1) issue_belonging_address      -- �Z��
              ,xlv2.location_name issue_belonging_name             -- ���s��������
              ,xsdh.install_support_amt install_support_amt        -- ����ݒu���^��
              ,xsdh.electricity_amount electricity_amount          -- �d�C��
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,(DECODE(xsdh.electricity_type
--                          , cv_electricity_type_1,  '���z ��z '|| xsdh.electricity_amount || '�~'
--                          , cv_electricity_type_2, '�̔��@�Ɋւ��d�C��́A����ɂĉ����x����'
--                          , '')
--                ) electricity_information                          -- �d�C����
--              ,(DECODE(xd.bank_transfer_fee_charge_div
--                          , cv_bank_trans_fee_div_1,  '�U�荞�ݎ萔���͍b�̕��S�Ƃ���'
--                          , cv_bank_trans_fee_div_2, '�U�荞�ݎ萔���͉��̕��S�Ƃ���'
--                          , '�U�荞�ݎ萔���͔����v���܂���')
--                ) transfer_commission_info                         -- �U�荞�ݎ萔�����
              , ( DECODE( xsdh.electricity_type
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--                            , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~�i�ō��j�Ƃ���B'
-- 2020/05/07 Ver1.14 N.Abe MOD START
--                            , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~�i'|| flv_tax.tax_type_name ||'�j�Ƃ���B'
                            , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~�i'|| flv_tax2.tax_kbn_name ||'�j�Ƃ���B'
-- 2020/05/07 Ver1.14 N.Abe MOD END
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
                            , cv_electricity_type_2, '�̔��@�Ɋւ��d�C��́A����ɂĉ����x�����B'
                            , ''
                  )
                )       electricity_information                          -- �d�C����
              , ( DECODE( xd.bank_transfer_fee_charge_div
                            , cv_bank_trans_fee_div_1, '�b�̕��S�Ƃ���B'
                            , cv_bank_trans_fee_div_2, '���̕��S�Ƃ���B'
                            , '�����v���܂���B'
                  )
                )       transfer_commission_info                         -- �U�荞�ݎ萔�����
-- == 2010/08/03 V1.9 Modified END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,flv_tax.tax_type_name                    tax_type_name                 -- �ŋ敪��
              ,xcm.contract_number                      contract_number               -- �_�񏑔ԍ�
              ,xcoc.contract_other_custs_id             contract_other_custs_id       -- �_���ȊOID
              ,xcc.contract_name                        contract_name2                -- �_��Җ�2
              ,xcm.contract_effect_date                 contract_effect_date2         -- �_�񏑔�����2
              ,flv_tax.tax_type_name2                   tax_type_name2                -- �ŋ敪��2
              ,CASE xsdh.install_supp_payment_type
                 WHEN cv_is_pay_type_single THEN xsdh.install_supp_amt
                 WHEN cv_is_pay_type_yearly THEN xsdh.install_supp_this_time
                 ELSE NULL
               END                                      install_supp_amt              -- �ݒu���^��
              ,xsdh.install_supp_payment_date           install_supp_payment_date     -- �x�������i�ݒu���^���j
              ,flv_is_fee.bk_chg_bearer_nm              install_supp_bk_chg_bearer    -- �U���萔�����S�i�ݒu���^���j
              ,xcoc.install_supp_bk_number              install_supp_bk_number        -- ��s�ԍ��i�ݒu���^���j
              ,abb1.bank_name                           install_supp_bk_name          -- ���Z�@�֖��i�ݒu���^���j
              ,xcoc.install_supp_branch_number          install_supp_branch_number    -- �x�X�ԍ��i�ݒu���^���j
              ,abb1.bank_branch_name                    install_supp_branch_name      -- �x�X���i�ݒu���^���j
              ,flv_is_koza.bk_acct_type                 install_supp_bk_acct_type     -- ������ʁi�ݒu���^���j
              ,xcoc.install_supp_bk_acct_number         install_supp_bk_acct_number   -- �����ԍ��i�ݒu���^���j
              ,xcoc.install_supp_bk_acct_name_alt       install_supp_bk_acct_name_alt -- �������`�J�i�i�ݒu���^���j
              ,xcoc.install_supp_bk_acct_name           install_supp_bk_acct_name     -- �������`�����i�ݒu���^���j
              ,xcc.contract_name || gv_install_supp_pre install_supp_preamble         -- �O���i�ݒu���^���j
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN xsdh.intro_chg_amt
                 WHEN cv_ic_pay_type_per_sp THEN xsdh.intro_chg_per_sales_price
                 WHEN cv_ic_pay_type_per_p  THEN xsdh.intro_chg_per_piece
                 ELSE NULL
               END                                      intro_chg_amt                 -- �Љ�萔��
              ,xsdh.intro_chg_payment_date              intro_chg_payment_date        -- �x�������i�Љ�萔���j
              ,xsdh.intro_chg_closing_date              intro_chg_closing_date        -- �����i�Љ�萔���j
              ,flv_ic_mon.trans_month_name              intro_chg_trans_month         -- �U�����i�Љ�萔���j
              ,xsdh.intro_chg_trans_date                intro_chg_trans_date          -- �U�����i�Љ�萔���j
              ,xsdh.intro_chg_trans_name                intro_chg_trans_name          -- �_���ȊO���i�Љ�萔���j
              ,xsdh.intro_chg_trans_name_alt            intro_chg_trans_alt           -- �_���ȊO���J�i�i�Љ�萔���j
              ,flv_ic_fee.bk_chg_bearer_nm              intro_chg_bk_chg_bearer       -- �U���萔�����S�i�Љ�萔���j
              ,xcoc.intro_chg_bk_number                 intro_chg_bk_number           -- ��s�ԍ��i�Љ�萔���j
              ,abb2.bank_name                           intro_chg_bk_name             -- ���Z�@�֖��i�Љ�萔���j
              ,xcoc.intro_chg_branch_number             intro_chg_branch_number       -- �x�X�ԍ��i�Љ�萔���j
              ,abb2.bank_branch_name                    intro_chg_branch_name         -- �x�X���i�Љ�萔���j
              ,flv_ic_koza.bk_acct_type                 intro_chg_bk_acct_type        -- ������ʁi�Љ�萔���j
              ,xcoc.intro_chg_bk_acct_number            intro_chg_bk_acct_number      -- �����ԍ��i�Љ�萔���j
              ,xcoc.intro_chg_bk_acct_name_alt          intro_chg_bk_acct_name_alt    -- �������`�J�i�i�Љ�萔���j
              ,xcoc.intro_chg_bk_acct_name              intro_chg_bk_acct_name        -- �������`�����i�Љ�萔���j
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre1
                 WHEN cv_ic_pay_type_per_sp THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 WHEN cv_ic_pay_type_per_p  THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 ELSE NULL
               END                                      intro_chg_preamble            -- �O���i�Љ�萔���j
              ,xsdh.electricity_amount                  electric_amt                  -- �d�C��2
              ,xsdh.electric_closing_date               electric_closing_date         -- �����i�d�C��j
              ,flv_e_mon.trans_month_name               electric_trans_month          -- �U�����i�d�C��j
              ,xsdh.electric_trans_date                 electric_trans_date           -- �U�����i�d�C��j
              ,xsdh.electric_trans_name                 electric_trans_name           -- �_���ȊO���i�d�C��j
              ,xsdh.electric_trans_name_alt             electric_trans_name_alt       -- �_���ȊO���J�i�i�d�C��j
              ,flv_e_fee.bk_chg_bearer_nm               electric_bk_chg_bearer        -- �U���萔�����S�i�d�C��j
              ,xcoc.electric_bk_number                  electric_bk_number            -- ��s�ԍ��i�d�C��j
              ,abb3.bank_name                           electric_bk_name              -- ���Z�@�֖��i�d�C��j
              ,xcoc.electric_branch_number              electric_branch_number        -- �x�X�ԍ��i�d�C��j
              ,abb3.bank_branch_name                    electric_branch_name          -- �x�X���i�d�C��j
              ,flv_e_koza.bk_acct_type                  electric_bk_acct_type         -- ������ʁi�d�C��j
              ,xcoc.electric_bk_acct_number             electric_bk_acct_number       -- �����ԍ��i�d�C��j
              ,xcoc.electric_bk_acct_name_alt           electric_bk_acct_name_alt     -- �������`�J�i�i�d�C��j
              ,xcoc.electric_bk_acct_name               electric_bk_acct_name         -- �������`�����i�d�C��j
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_fix THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"�N"MM"��"DD"��"', 'nls_calendar = ''Japanese Imperial''')
                        || TO_CHAR(xcm.contract_effect_date, cv_format_yyyymmdd_date)
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                        || gv_electric_pre3
                 WHEN cv_electric_type_var THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"�N"MM"��"DD"��"', 'nls_calendar = ''Japanese Imperial''')
                        || TO_CHAR(xcm.contract_effect_date, cv_format_yyyymmdd_date)
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                        || gv_electric_pre4
                 ELSE NULL
               END                                      electric_preamble             -- �O���i�d�C��j
              ,CASE xsdh.install_supp_type
                 WHEN cv_is_type_no  THEN cn_is_memo_no
                 WHEN cv_is_type_yes THEN cn_is_memo_yes
               END                                      install_supp_memo_flg         -- �o���i�ݒu���^���j�o�̓t���O
              ,CASE xsdh.intro_chg_type
                 WHEN cv_ic_type_no  THEN cn_ic_memo_no
                 WHEN cv_ic_type_yes THEN
                   CASE xsdh.intro_chg_payment_type
                     WHEN cv_ic_pay_type_single THEN cn_ic_memo_single
                     WHEN cv_ic_pay_type_per_sp THEN cn_ic_memo_per_sp
                     WHEN cv_ic_pay_type_per_p  THEN cn_ic_memo_per_p
                   END
               END                                      intro_chg_memo_flg            -- �o���i�Љ�萔���j�o�̓t���O
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_no  THEN cn_e_memo_no
                 WHEN cv_electric_type_fix THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_fix
                     ELSE                          cn_e_memo_cont
                   END
                 WHEN cv_electric_type_var THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_var
                     ELSE                          cn_e_memo_cont
                   END
               END                                      electric_memo_flg             -- �o���i�d�C��j�o�̓t���O
              ,xsdh.install_supp_amt                    install_supp_amt2             -- �ݒu���^�����z�i���s����񕪊�p�j
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
-- 2020/05/07 Ver1.14 N.Abe ADD START
              ,NVL( xd.bm_tax_kbn, '1' )                bm_tax_kbn                    -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
--  Ver1.19 T.Okuyama Mod Start
--  Ver1.18 T.Okuyama Add Start
--              ,CASE WHEN ((NVL(xd.invoice_t_flag, cv_t_none) = cv_t_flag) AND (xd.invoice_t_no IS NOT NULL)) THEN
--                 xd.invoice_t_flag || xd.invoice_t_no
--               ELSE
--                 NULL
--               END                                      bm1_t_no                      -- �o�^�ԍ��i���t��j
              ,CASE WHEN pvs.vendor_id IS NULL     AND ((NVL(xd.invoice_t_flag, cv_t_none) = cv_t_flag) AND (xd.invoice_t_no IS NOT NULL)) THEN
                      xd.invoice_t_flag || xd.invoice_t_no
                    WHEN pvs.vendor_id IS NOT NULL AND ((NVL(pvs.attribute8, cv_t_none) = cv_t_flag) AND (pvs.attribute9 IS NOT NULL)) THEN
                      pvs.attribute8 || pvs.attribute9
                    ELSE
                      NULL
               END                                      bm1_t_no                      -- �o�^�ԍ��i���t��j
--  Ver1.18 T.Okuyama Add End
--  Ver1.19 T.Okuyama Mod End
        INTO   o_rep_cont_data_rec.install_location              -- �ݒu���P�[�V����
              ,o_rep_cont_data_rec.contract_number               -- �_�񏑔ԍ�
              ,o_rep_cont_data_rec.contract_name                 -- �_��Җ�
              ,o_rep_cont_data_rec.contract_period               -- �_�����
              ,o_rep_cont_data_rec.cancellation_offer_code       -- �_������\���o
              ,o_rep_cont_data_rec.other_content                 -- ���񎖍�
              ,o_rep_cont_data_rec.sales_charge_details_delivery -- �萔�����׏����t�於
              ,o_rep_cont_data_rec.delivery_address              -- ���t��Z��
              ,o_rep_cont_data_rec.install_name                  -- �ݒu�於
              ,o_rep_cont_data_rec.install_address               -- �ݒu��Z��
              ,o_rep_cont_data_rec.install_date                  -- �ݒu��
              ,o_rep_cont_data_rec.bank_name                     -- ���Z�@�֖�
              ,o_rep_cont_data_rec.blanches_name                 -- �x�X��
              ,o_rep_cont_data_rec.bank_account_number           -- �����ԍ�
              ,o_rep_cont_data_rec.bank_account_name_kana        -- �������`�J�i
              ,o_rep_cont_data_rec.account_number                -- �ڋq�R�[�h
              ,o_rep_cont_data_rec.publish_base_code             -- �S�����_
              ,o_rep_cont_data_rec.publish_base_name             -- �S�����_��
              ,o_rep_cont_data_rec.contract_effect_date          -- �_�񏑔�����
              ,o_rep_cont_data_rec.issue_belonging_address       -- ���s�������Z��
              ,o_rep_cont_data_rec.issue_belonging_name          -- ���s��������
              ,o_rep_cont_data_rec.install_support_amt           -- �ݒu���^��
              ,o_rep_cont_data_rec.electricity_amount            -- �d�C��
              ,o_rep_cont_data_rec.electricity_information       -- �d�C����
              ,o_rep_cont_data_rec.transfer_commission_info      -- �U�荞�ݎ萔�����
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,o_rep_cont_data_rec.tax_type_name                 -- �ŋ敪��
              ,o_rep_memo_data_rec.contract_number               -- �_�񏑔ԍ�
              ,o_rep_memo_data_rec.contract_other_custs_id       -- �_���ȊOID
              ,o_rep_memo_data_rec.contract_name                 -- �_��Җ�2
              ,o_rep_memo_data_rec.contract_effect_date          -- �_�񏑔�����2
              ,o_rep_memo_data_rec.tax_type_name                 -- �ŋ敪��2
              ,o_rep_memo_data_rec.install_supp_amt              -- �ݒu���^��
              ,o_rep_memo_data_rec.install_supp_payment_date     -- �x�������i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_chg_bearer    -- �U���萔�����S�i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_number        -- ��s�ԍ��i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_name          -- ���Z�@�֖��i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_branch_number    -- �x�X�ԍ��i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_branch_name      -- �x�X���i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_type     -- ������ʁi�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_number   -- �����ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_name_alt -- �������`�J�i�i�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_name     -- �������`�����i�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_preamble         -- �O���i�ݒu���^���j
              ,o_rep_memo_data_rec.intro_chg_amt                 -- �Љ�萔��
              ,o_rep_memo_data_rec.intro_chg_payment_date        -- �x�������i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_closing_date        -- �����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_month         -- �U�����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_date          -- �U�����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_name          -- �_���ȊO���i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_name_alt      -- �_���ȊO���J�i�i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_chg_bearer       -- �U���萔�����S�i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_number           -- ��s�ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_name             -- ���Z�@�֖��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_branch_number       -- �x�X�ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_branch_name         -- �x�X���i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_type        -- ������ʁi�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_number      -- �����ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name_alt    -- �������`�J�i�i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name        -- �������`�����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_preamble            -- �O���i�Љ�萔���j
              ,o_rep_memo_data_rec.electric_amt                  -- �d�C��2
              ,o_rep_memo_data_rec.electric_closing_date         -- �����i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_month          -- �U�����i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_date           -- �U�����i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_name           -- �_���ȊO���i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_name_alt       -- �_���ȊO���J�i�i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_chg_bearer        -- �U���萔�����S�i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_number            -- ��s�ԍ��i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_name              -- ���Z�@�֖��i�d�C��j
              ,o_rep_memo_data_rec.electric_branch_number        -- �x�X�ԍ��i�d�C��j
              ,o_rep_memo_data_rec.electric_branch_name          -- �x�X���i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_type         -- ������ʁi�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_number       -- �����ԍ��i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_name_alt     -- �������`�J�i�i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_name         -- �������`�����i�d�C��j
              ,o_rep_memo_data_rec.electric_preamble             -- �O���i�d�C��j
              ,o_rep_memo_data_rec.install_supp_memo_flg         -- �o���i�ݒu���^���j�o�̓t���O
              ,o_rep_memo_data_rec.intro_chg_memo_flg            -- �o���i�Љ�萔���j�o�̓t���O
              ,o_rep_memo_data_rec.electric_memo_flg             -- �o���i�d�C��j�o�̓t���O
              ,lt_install_supp_amt                               -- �ݒu���^�����z�i���s����񕪊�p�j
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
-- 2020/05/07 Ver1.14 N.Abe ADD START
              ,o_rep_cont_data_rec.bm_tax_kbn                    -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
--
--  Ver1.18 T.Okuyama Add Start
              ,o_rep_cont_data_rec.bm1_t_no                      -- �o�^�ԍ��i���t��j
--  Ver1.18 T.Okuyama Add End
        FROM   xxcso_cust_accounts_v      xcav     -- �ڋq�}�X�^�r���[
              ,xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
              ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
              ,xxcso_destinations         xd       -- ���t��e�[�u��
              ,xxcso_bank_accounts        xba      -- ��s�����A�h�I���}�X�^
              ,xxcso_locations_v2         xlv2     -- ���Ə��}�X�^�i�ŐV�j�r���[
--  Ver1.19 T.Okuyama Add Start
              ,po_vendor_sites            pvs      -- �d����T�C�g�}�X�^
--  Ver1.19 T.Okuyama Add End
              ,(SELECT (flvv.attribute1 || flvv.attribute2) attr
                FROM   fnd_lookup_values_vl flvv -- �Q�ƃ^�C�v
                WHERE
                       flvv.lookup_type = cv_lkup_contract_nm_con
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flvv.start_date_active)
                                         AND TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                  AND  flvv.enabled_flag = cv_enabled_flag
                  AND  ROWNUM = 1
               ) flvv_con
-- == 2010/08/03 V1.9 Added START ===============================================================
              , ( SELECT  flvv.lookup_code    lookup_code
                        , flvv.meaning        bank_acct_type_name
                  FROM    fnd_lookup_values_vl    flvv
                  WHERE   flvv.lookup_type              =   cv_lkup_kozatype
                  AND     flvv.enabled_flag             =   cv_enabled_flag
                  AND     TRUNC(ld_sysdate)   BETWEEN TRUNC(flvv.start_date_active)
                                              AND     TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                )                         flv       --  ������ʖ��擾
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_koza -- ������ʁi�ݒu���^���j
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_koza -- ������ʁi�Љ�萔���j
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_koza -- ������ʁi�d�C��j
              ,( SELECT flvv.lookup_code    tax_type
                       ,flvv.meaning        tax_type_name
                       ,flvv.description    tax_type_name2
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_sp_tax_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_tax   -- �ŋ敪���擾
-- 2020/05/07 Ver1.14 N.Abe ADD START
              ,( SELECT flvv.lookup_code    tax_kbn
                       ,flvv.description    tax_kbn_name
                 FROM   fnd_lookup_values_vl    flvv
--  Ver1.16 K.Kanada Mod Start
--                 WHERE  flvv.lookup_type              =   cv_lkup_sp_tax_type
                 WHERE  flvv.lookup_type              =   cv_lkup_elect_tax_kbn
--  Ver1.16 K.Kanada Mod End
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_tax2  -- BM�ŋ敪���擾
-- 2020/05/07 Ver1.14 N.Abe ADD END
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_fee -- �r�o�ꌈ�U���萔�����S�敪�i�ݒu���^���j
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_fee -- �r�o�ꌈ�U���萔�����S�敪�i�Љ�萔���j
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_fee -- �r�o�ꌈ�U���萔�����S�敪�i�d�C��j
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_mon  -- �U�����i�Љ�萔���j
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_mon  -- �U�����i�d�C��j
              ,xxcso_contract_other_custs xcoc      -- �_���ȊO�e�[�u��
              ,ap_bank_branches           abb1      -- ��s�x�X�}�X�^1
              ,ap_bank_branches           abb2      -- ��s�x�X�}�X�^2
              ,ap_bank_branches           abb3      -- ��s�x�X�}�X�^3
              ,xxcso_contract_customers   xcc       -- �_���e�[�u��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.install_account_number = xcav.account_number
          AND  xcav.account_status = cv_active_status
          AND  xcav.party_status = cv_active_status
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          AND  xd.contract_management_id(+) = xcm.contract_management_id
          AND  xd.delivery_div(+) = cv_delivery_div_1
          AND  xd.delivery_id = xba.delivery_id(+)
--  Ver1.19 T.Okuyama Add Start
          AND  pvs.vendor_id(+)             = xd.supplier_id
--  Ver1.19 T.Okuyama Add End
          AND  xlv2.dept_code = xcm.publish_dept_code
-- == 2010/08/03 V1.9 Added START ===============================================================
        AND     xba.bank_account_type       =   flv.lookup_code(+)
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          AND  xcm.contract_other_custs_id    = xcoc.contract_other_custs_id(+)
          AND  flv_tax.tax_type(+)            = NVL2(xsdh.tax_type, xsdh.tax_type, cv_in_tax)
-- 2020/05/07 Ver1.14 N.Abe ADD START
          AND  flv_tax2.tax_kbn(+)            = NVL( xd.bm_tax_kbn, '1' )
-- 2020/05/07 Ver1.14 N.Abe ADD END
          AND  abb1.bank_number(+)            = xcoc.install_supp_bk_number
          AND  abb1.bank_num(+)               = xcoc.install_supp_branch_number
          AND  abb2.bank_number(+)            = xcoc.intro_chg_bk_number
          AND  abb2.bank_num(+)               = xcoc.intro_chg_branch_number
          AND  abb3.bank_number(+)            = xcoc.electric_bk_number
          AND  abb3.bank_num(+)               = xcoc.electric_branch_number
          AND  xcc.contract_customer_id       = xcm.contract_customer_id
          AND  flv_is_fee.bk_chg_bearer_cd(+) = xcoc.install_supp_bk_chg_bearer
          AND  flv_ic_fee.bk_chg_bearer_cd(+) = xcoc.intro_chg_bk_chg_bearer
          AND  flv_e_fee.bk_chg_bearer_cd(+)  = xcoc.electric_bk_chg_bearer
          AND  flv_ic_mon.trans_month_code(+) = xsdh.intro_chg_trans_month
          AND  flv_e_mon.trans_month_code(+)  = xsdh.electric_trans_month
          AND  flv_is_koza.bk_acct_type_cd(+) = xcoc.install_supp_bk_acct_type
          AND  flv_ic_koza.bk_acct_type_cd(+) = xcoc.intro_chg_bk_acct_type
          AND  flv_e_koza.bk_acct_type_cd(+)  = xcoc.electric_bk_acct_type
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        ;
--
        /* 2009.11.12 K.Satomura I_E_658�Ή� START */
        --SELECT  (CASE
        --          WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
        --               xev2.position_name_old
        --          ELSE xev2.position_name_new
        --        END) issue_belonging_boss_position                 -- ���s���������E�ʖ�
        --        ,xev2.full_name issue_belonging_boss               -- ����
        --INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- ���s���������E�ʖ�
        --        ,o_rep_cont_data_rec.issue_belonging_boss          -- ����
        --FROM   xxcso_employees_v2         xev2     -- �]�ƈ��}�X�^�i�ŐV�j�r���[
        --WHERE  ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
        --           AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
        --       OR
        --        (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
        --           AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
        --       )
        --AND ROWNUM = 1;
        /* 2009.11.12 K.Satomura I_E_658�Ή� END */
--
      EXCEPTION
        -- ���o���ʂ������̏ꍇ
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_05             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number           -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
        -- �����ȊO�̃G���[�̏ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04             -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number           -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    -- �X�e�[�^�X���m��ρA���}�X�^�A�g�t���O���A�g�ς̏ꍇ
    ELSE
      -- ===========================
      -- �_��֘A���擾�iA-2-2-1�j
      -- ===========================
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '���� �_��֘A���F�X�e�[�^�X���m��ρA���}�X�^�A�g�t���O���A�g�� ����'
      );
--
      BEGIN
        SELECT (CASE
                  WHEN (SUBSTR(xcasv.establishment_location, 2, 1)
                          IN (cv_i_location_type_2, cv_i_location_type_3)) THEN
                    cv_stamp_show_1
                  ELSE cv_stamp_show_0
                END) install_location                                  -- �ݒu���P�[�V����
              ,xcm.contract_number   contract_number                   -- �_�񏑔ԍ�
              /* 2009.09.14 M.Maruyama 0001355�Ή� START */
              --,((SELECT xcc.contract_name 
              ,SUBSTRB(((SELECT SUBSTRB(xcc.contract_name, 1, 100)
                 FROM   xxcso_contract_customers xcc  -- �_���e�[�u��
                 WHERE  xcc.contract_customer_id = xcm.contract_customer_id
                   AND  ROWNUM = 1
               --) || flvv_con.attr) contract_name                     -- �_�񏑖�
               ) || flvv_con.attr), 1, 660) contract_name              -- �_�񏑖�
              /* 2009.09.14 M.Maruyama 0001355�Ή� END */
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--              ,xsdh.contract_year_date contract_period             -- �_�����
              ,CASE xsdh.contract_year_date
                 WHEN 0 THEN 1
                 ELSE xsdh.contract_year_date
               END contract_period                                   -- �_�����
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
              ,xcm.cancellation_offer_code cancellation_offer_code     -- �_������\���o
              ,xsdh.other_content other_content                        -- ���񎖍�
              /* 2009.10.15 D.Abe 0001536,0001537�Ή� START */
              --,pv.vendor_name sales_charge_details_delivery            -- �x���於
              --,NVL2(pvs.zip, cv_post_mark || pvs.zip || ' ', '') || pvs.state || pvs.city
              ,pvs.attribute1 sales_charge_details_delivery            -- �x���於
              ,NVL2(pvs.zip, cv_post_mark || pvs.zip || ' ', '')
              /* 2009.10.15 D.Abe 0001536,0001537�Ή� END */
                          || pvs.address_line1 || pvs.address_line2 delivery_address -- ���t��Z��
              ,xcasv.party_name install_name                           -- �ݒu��ڋq��
              ,NVL2(xcasv.postal_code, cv_post_mark || xcasv.postal_code || ' ', '') || xcasv.state || xcasv.city
                      || xcasv.address1 || xcasv.address2 install_address -- �ݒu��Z��
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--              ,(SUBSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                 , 1, INSTR(TO_CHAR(xcm.install_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
              ,TO_CHAR(xcm.install_date, cv_format_yyyymmdd_date
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                ) install_date                                         -- �ݒu��
              /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
              --,xbav.bank_name bank_name                                -- ��s��
              --,xbav.bank_branch_name blanches_name                     -- �x�X��
              --,xbav.bank_account_num bank_account_number               -- �����ԍ�
              --,xbav.account_holder_name_alt bank_account_name_kana     -- �������`�J�i
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
                          , xbav.bank_name)
                ) bank_name                                            -- ��s��
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
                          , xbav.bank_branch_name)
                ) blanches_name                                        -- �x�X��
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
-- == 2010/08/03 V1.9 Modified START ===============================================================
--                          , xbav.bank_account_num)
                          , flv.bank_acct_type_name || cv_space || xbav.bank_account_num)
-- == 2010/08/03 V1.9 Modified END   ===============================================================
                ) bank_account_number                                  -- �����ԍ�
              ,(DECODE(pvs.attribute4
                          , cv_csh_pymnt, NULL
                          , xbav.account_holder_name_alt)
                ) bank_account_name_kana                               -- �������`�J�i
              /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
              ,xcm.install_account_number account_number               -- �ݒu��ڋq�R�[�h
              ,xcm.publish_dept_code publish_base_code                 -- �S�������R�[�h
              ,xlv2.location_name publish_base_name                    -- �S�����_��
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,(SUBSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                 , 1, INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1)
--                ) contract_effect_date                                 -- �_�񏑔�����
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--              , NVL(SUBSTR(   TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial''')
--                            , 1
--                            , INSTR(TO_CHAR(xcm.contract_effect_date, 'eedl', 'nls_calendar=''japanese imperial'''), ' ') -1
              ,NVL(TO_CHAR(xcm.contract_effect_date, cv_format_yyyymmdd_date
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                    ), gt_contract_date_ptn
                )     contract_effect_date                             -- �_�񏑔�����
-- == 2010/08/03 V1.9 Modified END   ===============================================================
              ,(NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '') 
                  || xlv2.address_line1) issue_belonging_address       -- �Z��
              ,xlv2.location_name issue_belonging_name                 -- ���s��������
              ,xsdh.install_support_amt install_support_amt            -- ����ݒu���^��
              ,xsdh.electricity_amount electricity_amount              -- �d�C��
-- == 2010/08/03 V1.9 Modified START ===============================================================
--              ,DECODE(xsdh.electricity_type
--                      , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~'
--                      , cv_electricity_type_2, '�̔��@�Ɋւ��d�C��́A����ɂĉ����x����'
--                      , '') electricity_information                   -- �d�C����
--              ,DECODE(pvs.bank_charge_bearer
--                      , cv_bank_trans_fee_div_1, '�U�荞�ݎ萔���͍b�̕��S�Ƃ���'
--                      , cv_bank_trans_fee_div_2, '�U�荞�ݎ萔���͉��̕��S�Ƃ���'
--                      , '�U�荞�ݎ萔���͔����v���܂���') transfer_commission_info -- �U�荞�ݎ萔�����
              , DECODE(xsdh.electricity_type
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--                        , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~�i�ō��j�Ƃ���B'
-- 2020/05/07 Ver1.14 N.Abe MOD START
--                        , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~�i'|| flv_tax.tax_type_name ||'�j�Ƃ���B'
                        , cv_electricity_type_1, '���z ��z '|| xsdh.electricity_amount || '�~�i'|| flv_tax2.tax_kbn_name ||'�j�Ƃ���B'
-- 2020/05/07 Ver1.14 N.Abe MOD END
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
                        , cv_electricity_type_2, '�̔��@�Ɋւ��d�C��́A����ɂĉ����x�����B'
                        , ''
                )     electricity_information                     --  �d�C����
              , DECODE(pvs.bank_charge_bearer
                        , cv_bank_trans_fee_div_1, '�b�̕��S�Ƃ���B'
                        , cv_bank_trans_fee_div_2, '���̕��S�Ƃ���B'
                        , '�����v���܂���B'
                )     transfer_commission_info                    --  �U�荞�ݎ萔�����
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,flv_tax.tax_type_name                    tax_type_name                 -- �ŋ敪��
              ,xcm.contract_number                      contract_number               -- �_�񏑔ԍ�
              ,xcoc.contract_other_custs_id             contract_other_custs_id       -- �_���ȊOID
              ,xcc.contract_name                        contract_name2                -- �_��Җ�2
              ,xcm.contract_effect_date                 contract_effect_date2         -- �_�񏑔�����2
              ,flv_tax.tax_type_name2                   tax_type_name2                -- �ŋ敪��2
              ,CASE xsdh.install_supp_payment_type
                 WHEN cv_is_pay_type_single THEN xsdh.install_supp_amt
                 WHEN cv_is_pay_type_yearly THEN xsdh.install_supp_this_time
                 ELSE NULL
               END                                      install_supp_amt              -- �ݒu���^��
              ,xsdh.install_supp_payment_date           install_supp_payment_date     -- �x�������i�ݒu���^���j
              ,flv_is_fee.bk_chg_bearer_nm              install_supp_bk_chg_bearer    -- �U���萔�����S�i�ݒu���^���j
              ,xcoc.install_supp_bk_number              install_supp_bk_number        -- ��s�ԍ��i�ݒu���^���j
              ,abb1.bank_name                           install_supp_bk_name          -- ���Z�@�֖��i�ݒu���^���j
              ,xcoc.install_supp_branch_number          install_supp_branch_number    -- �x�X�ԍ��i�ݒu���^���j
              ,abb1.bank_branch_name                    install_supp_branch_name      -- �x�X���i�ݒu���^���j
              ,flv_is_koza.bk_acct_type                 install_supp_bk_acct_type     -- ������ʁi�ݒu���^���j
              ,xcoc.install_supp_bk_acct_number         install_supp_bk_acct_number   -- �����ԍ��i�ݒu���^���j
              ,xcoc.install_supp_bk_acct_name_alt       install_supp_bk_acct_name_alt -- �������`�J�i�i�ݒu���^���j
              ,xcoc.install_supp_bk_acct_name           install_supp_bk_acct_name     -- �������`�����i�ݒu���^���j
              ,xcc.contract_name || gv_install_supp_pre install_supp_preamble         -- �O���i�ݒu���^���j
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN xsdh.intro_chg_amt
                 WHEN cv_ic_pay_type_per_sp THEN xsdh.intro_chg_per_sales_price
                 WHEN cv_ic_pay_type_per_p  THEN xsdh.intro_chg_per_piece
                 ELSE NULL
               END                                      intro_chg_amt                 -- �Љ�萔��
              ,xsdh.intro_chg_payment_date              intro_chg_payment_date        -- �x�������i�Љ�萔���j
              ,xsdh.intro_chg_closing_date              intro_chg_closing_date        -- �����i�Љ�萔���j
              ,flv_ic_mon.trans_month_name              intro_chg_trans_month         -- �U�����i�Љ�萔���j
              ,xsdh.intro_chg_trans_date                intro_chg_trans_date          -- �U�����i�Љ�萔���j
              ,xsdh.intro_chg_trans_name                intro_chg_trans_name          -- �_���ȊO���i�Љ�萔���j
              ,xsdh.intro_chg_trans_name_alt            intro_chg_trans_alt           -- �_���ȊO���J�i�i�Љ�萔���j
              ,flv_ic_fee.bk_chg_bearer_nm              intro_chg_bk_chg_bearer       -- �U���萔�����S�i�Љ�萔���j
              ,xcoc.intro_chg_bk_number                 intro_chg_bk_number           -- ��s�ԍ��i�Љ�萔���j
              ,abb2.bank_name                           intro_chg_bk_name             -- ���Z�@�֖��i�Љ�萔���j
              ,xcoc.intro_chg_branch_number             intro_chg_branch_number       -- �x�X�ԍ��i�Љ�萔���j
              ,abb2.bank_branch_name                    intro_chg_branch_name         -- �x�X���i�Љ�萔���j
              ,flv_ic_koza.bk_acct_type                 intro_chg_bk_acct_type        -- ������ʁi�Љ�萔���j
              ,xcoc.intro_chg_bk_acct_number            intro_chg_bk_acct_number      -- �����ԍ��i�Љ�萔���j
              ,xcoc.intro_chg_bk_acct_name_alt          intro_chg_bk_acct_name_alt    -- �������`�J�i�i�Љ�萔���j
              ,xcoc.intro_chg_bk_acct_name              intro_chg_bk_acct_name        -- �������`�����i�Љ�萔���j
              ,CASE xsdh.intro_chg_payment_type
                 WHEN cv_ic_pay_type_single THEN
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre1
                 WHEN cv_ic_pay_type_per_sp THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 WHEN cv_ic_pay_type_per_p  THEN 
                   xsdh.intro_chg_trans_name || gv_intro_chg_pre2
                 ELSE NULL
               END                                      intro_chg_preamble            -- �O���i�Љ�萔���j
              ,xsdh.electricity_amount                  electric_amt                  -- �d�C��2
              ,xsdh.electric_closing_date               electric_closing_date         -- �����i�d�C��j
              ,flv_e_mon.trans_month_name               electric_trans_month          -- �U�����i�d�C��j
              ,xsdh.electric_trans_date                 electric_trans_date           -- �U�����i�d�C��j
              ,xsdh.electric_trans_name                 electric_trans_name           -- �_���ȊO���i�d�C��j
              ,xsdh.electric_trans_name_alt             electric_trans_name_alt       -- �_���ȊO���J�i�i�d�C��j
              ,flv_e_fee.bk_chg_bearer_nm               electric_bk_chg_bearer        -- �U���萔�����S�i�d�C��j
              ,xcoc.electric_bk_number                  electric_bk_number            -- ��s�ԍ��i�d�C��j
              ,abb3.bank_name                           electric_bk_name              -- ���Z�@�֖��i�d�C��j
              ,xcoc.electric_branch_number              electric_branch_number        -- �x�X�ԍ��i�d�C��j
              ,abb3.bank_branch_name                    electric_branch_name          -- �x�X���i�d�C��j
              ,flv_e_koza.bk_acct_type                  electric_bk_acct_type         -- ������ʁi�d�C��j
              ,xcoc.electric_bk_acct_number             electric_bk_acct_number       -- �����ԍ��i�d�C��j
              ,xcoc.electric_bk_acct_name_alt           electric_bk_acct_name_alt     -- �������`�J�i�i�d�C��j
              ,xcoc.electric_bk_acct_name               electric_bk_acct_name         -- �������`�����i�d�C��j
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_fix THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"�N"MM"��"DD"��"', 'nls_calendar = ''Japanese Imperial''')
                        || TO_CHAR(xcm.contract_effect_date, cv_format_yyyymmdd_date)
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                        || gv_electric_pre3
                 WHEN cv_electric_type_var THEN
                   xsdh.electric_trans_name
                        || gv_electric_pre1 || xcc.contract_name
                        || gv_electric_pre2
/* 2018/11/15 Ver1.13 E.Yazaki MOD START */
--                        || TO_CHAR(xcm.contract_effect_date, 'EEYY"�N"MM"��"DD"��"', 'nls_calendar = ''Japanese Imperial''')
                        || TO_CHAR(xcm.contract_effect_date, cv_format_yyyymmdd_date)
/* 2018/11/15 Ver1.13 E.Yazaki MOD END */
                        || gv_electric_pre4
                 ELSE NULL
               END                                      electric_preamble             -- �O���i�d�C��j
              ,CASE xsdh.install_supp_type
                 WHEN cv_is_type_no  THEN cn_is_memo_no
                 WHEN cv_is_type_yes THEN cn_is_memo_yes
               END                                      install_supp_memo_flg         -- �o���i�ݒu���^���j�o�̓t���O
              ,CASE xsdh.intro_chg_type
                 WHEN cv_ic_type_no  THEN cn_ic_memo_no
                 WHEN cv_ic_type_yes THEN
                   CASE xsdh.intro_chg_payment_type
                     WHEN cv_ic_pay_type_single THEN cn_ic_memo_single
                     WHEN cv_ic_pay_type_per_sp THEN cn_ic_memo_per_sp
                     WHEN cv_ic_pay_type_per_p  THEN cn_ic_memo_per_p
                   END
               END                                      intro_chg_memo_flg            -- �o���i�Љ�萔���j�o�̓t���O
              ,CASE xsdh.electricity_type
                 WHEN cv_electric_type_no  THEN cn_e_memo_no
                 WHEN cv_electric_type_fix THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_fix
                     ELSE                          cn_e_memo_cont
                   END
                 WHEN cv_electric_type_var THEN
                   CASE xsdh.electric_payment_type
                     WHEN cv_e_pay_type_cont  THEN cn_e_memo_cont
                     WHEN cv_e_pay_type_other THEN cn_e_memo_o_var
                     ELSE                          cn_e_memo_cont
                   END
               END                                      electric_memo_flg             -- �o���i�d�C��j�o�̓t���O
              ,xsdh.install_supp_amt                    install_supp_amt2             -- �ݒu���^�����z�i���s����񕪊�p�j
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
-- 2020/05/07 Ver1.14 N.Abe ADD START
              ,NVL( xd.bm_tax_kbn, '1' )                bm_tax_kbn                    -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
--
--  Ver1.18 T.Okuyama Add Start
              ,CASE WHEN ((NVL(pvs.attribute8, cv_t_none) = cv_t_flag) AND (pvs.attribute9 IS NOT NULL)) THEN
                 pvs.attribute8 || pvs.attribute9
               ELSE
                 NULL
               END                                      bm1_t_no                      -- �o�^�ԍ��i���t��j
--  Ver1.18 T.Okuyama Add End
-- == 2010/08/03 V1.9 Modified END   ===============================================================
        INTO   o_rep_cont_data_rec.install_location              -- �ݒu���P�[�V����
              ,o_rep_cont_data_rec.contract_number               -- �_�񏑔ԍ�
              ,o_rep_cont_data_rec.contract_name                 -- �_��Җ�
              ,o_rep_cont_data_rec.contract_period               -- �_�����
              ,o_rep_cont_data_rec.cancellation_offer_code       -- �_������\���o
              ,o_rep_cont_data_rec.other_content                 -- ���񎖍�
              ,o_rep_cont_data_rec.sales_charge_details_delivery -- �萔�����׏����t�於
              ,o_rep_cont_data_rec.delivery_address              -- ���t��Z��
              ,o_rep_cont_data_rec.install_name                  -- �ݒu�於
              ,o_rep_cont_data_rec.install_address               -- �ݒu��Z��
              ,o_rep_cont_data_rec.install_date                  -- �ݒu��
              ,o_rep_cont_data_rec.bank_name                     -- ���Z�@�֖�
              ,o_rep_cont_data_rec.blanches_name                 -- �x�X��
              ,o_rep_cont_data_rec.bank_account_number           -- �����ԍ�
              ,o_rep_cont_data_rec.bank_account_name_kana        -- �������`�J�i
              ,o_rep_cont_data_rec.account_number                -- �ڋq�R�[�h
              ,o_rep_cont_data_rec.publish_base_code             -- �S�����_
              ,o_rep_cont_data_rec.publish_base_name             -- �S�����_��
              ,o_rep_cont_data_rec.contract_effect_date          -- �_�񏑔�����
              ,o_rep_cont_data_rec.issue_belonging_address       -- ���s�������Z��
              ,o_rep_cont_data_rec.issue_belonging_name          -- ���s��������
              ,o_rep_cont_data_rec.install_support_amt           -- �ݒu���^��
              ,o_rep_cont_data_rec.electricity_amount            -- �d�C��
              ,o_rep_cont_data_rec.electricity_information       -- �d�C����
              ,o_rep_cont_data_rec.transfer_commission_info      -- �U�荞�ݎ萔�����
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,o_rep_cont_data_rec.tax_type_name                 -- �ŋ敪��
              ,o_rep_memo_data_rec.contract_number               -- �_�񏑔ԍ�
              ,o_rep_memo_data_rec.contract_other_custs_id       -- �_���ȊOID
              ,o_rep_memo_data_rec.contract_name                 -- �_��Җ�
              ,o_rep_memo_data_rec.contract_effect_date          -- �_�񏑔�����2
              ,o_rep_memo_data_rec.tax_type_name                 -- �ŋ敪��2
              ,o_rep_memo_data_rec.install_supp_amt              -- �ݒu���^��
              ,o_rep_memo_data_rec.install_supp_payment_date     -- �x�������i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_chg_bearer    -- �U���萔�����S�i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_number        -- ��s�ԍ��i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_name          -- ���Z�@�֖��i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_branch_number    -- �x�X�ԍ��i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_branch_name      -- �x�X���i�ݒu���^���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_type     -- ������ʁi�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_number   -- �����ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_name_alt -- �������`�J�i�i�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_bk_acct_name     -- �������`�����i�Љ�萔���j
              ,o_rep_memo_data_rec.install_supp_preamble         -- �O���i�ݒu���^���j
              ,o_rep_memo_data_rec.intro_chg_amt                 -- �Љ�萔��
              ,o_rep_memo_data_rec.intro_chg_payment_date        -- �x�������i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_closing_date        -- �����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_month         -- �U�����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_date          -- �U�����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_name          -- �_���ȊO���i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_trans_name_alt      -- �_���ȊO���J�i�i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_chg_bearer       -- �U���萔�����S�i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_number           -- ��s�ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_name             -- ���Z�@�֖��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_branch_number       -- �x�X�ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_branch_name         -- �x�X���i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_type        -- ������ʁi�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_number      -- �����ԍ��i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name_alt    -- �������`�J�i�i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_bk_acct_name        -- �������`�����i�Љ�萔���j
              ,o_rep_memo_data_rec.intro_chg_preamble            -- �O���i�Љ�萔���j
              ,o_rep_memo_data_rec.electric_amt                  -- �d�C��2
              ,o_rep_memo_data_rec.electric_closing_date         -- �����i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_month          -- �U�����i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_date           -- �U�����i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_name           -- �_���ȊO���i�d�C��j
              ,o_rep_memo_data_rec.electric_trans_name_alt       -- �_���ȊO���J�i�i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_chg_bearer        -- �U���萔�����S�i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_number            -- ��s�ԍ��i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_name              -- ���Z�@�֖��i�d�C��j
              ,o_rep_memo_data_rec.electric_branch_number        -- �x�X�ԍ��i�d�C��j
              ,o_rep_memo_data_rec.electric_branch_name          -- �x�X���i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_type         -- ������ʁi�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_number       -- �����ԍ��i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_name_alt     -- �������`�J�i�i�d�C��j
              ,o_rep_memo_data_rec.electric_bk_acct_name         -- �������`�����i�d�C��j
              ,o_rep_memo_data_rec.electric_preamble             -- �O���i�d�C��j
              ,o_rep_memo_data_rec.install_supp_memo_flg         -- �o���i�ݒu���^���j�o�̓t���O
              ,o_rep_memo_data_rec.intro_chg_memo_flg            -- �o���i�Љ�萔���j�o�̓t���O
              ,o_rep_memo_data_rec.electric_memo_flg             -- �o���i�d�C��j�o�̓t���O
              ,lt_install_supp_amt                               -- �ݒu���^�����z�i���s����񕪊�p�j
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
-- 2020/05/07 Ver1.14 N.Abe ADD START
              ,o_rep_cont_data_rec.bm_tax_kbn                    -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
--
--  Ver1.18 T.Okuyama Add Start
              ,o_rep_cont_data_rec.bm1_t_no                      -- �o�^�ԍ��i���t��j
--  Ver1.18 T.Okuyama Add End
        FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
              ,xxcso_cust_acct_sites_v    xcasv    -- �ڋq�}�X�^�T�C�g�r���[
              ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
              /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
              --,xxcso_sp_decision_custs    xsdc     -- �r�o�ꌈ�ڋq�e�[�u��
              ,xxcso_destinations         xd       -- ���t��e�[�u��
              /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
              ,xxcso_bank_accts_v         xbav     -- ��s�����}�X�^�i�ŐV�j�r���[
              ,xxcso_locations_v2         xlv2     -- ���Ə��}�X�^�i�ŐV�j�r���[
              ,(SELECT (flvv.attribute1 || flvv.attribute2) attr
                FROM   fnd_lookup_values_vl flvv -- �Q�ƃ^�C�v
                WHERE
                       flvv.lookup_type = cv_lkup_contract_nm_con
                  AND  TRUNC(ld_sysdate) BETWEEN TRUNC(flvv.start_date_active)
                                         AND TRUNC(NVL(flvv.end_date_active,ld_sysdate))
                  AND  flvv.enabled_flag = cv_enabled_flag
                  AND  ROWNUM = 1
               ) flvv_con
               /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
               --,po_vendors pv                      -- �d����}�X�^
               /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
               ,po_vendor_sites pvs                -- �d����T�C�g�}�X�^
-- == 2010/08/03 V1.9 Added START ===============================================================
              , ( SELECT  flvv.lookup_code    lookup_code
                        , flvv.meaning        bank_acct_type_name
                  FROM    fnd_lookup_values_vl    flvv
                  WHERE   flvv.lookup_type              =   cv_lkup_kozatype
                  AND     flvv.enabled_flag             =   cv_enabled_flag
                  AND     TRUNC(ld_sysdate)   BETWEEN TRUNC(flvv.start_date_active)
                                              AND     TRUNC(NVL(flvv.end_date_active, ld_sysdate))
                )                         flv       --  ������ʖ��擾
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_koza -- ������ʁi�ݒu���^���j
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_koza -- ������ʁi�Љ�萔���j
              ,( SELECT flvv.lookup_code    bk_acct_type_cd
                       ,flvv.meaning        bk_acct_type
                 FROM   fnd_lookup_values_vl    flvv
                 WHERE  flvv.lookup_type              =   cv_lkup_kozatype
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_koza -- ������ʁi�d�C��j
              , ( SELECT  flvv.lookup_code    tax_type
                        , flvv.meaning        tax_type_name
                        , flvv.description    tax_type_name2
                  FROM    fnd_lookup_values_vl    flvv
                  WHERE   flvv.lookup_type              =   cv_lkup_sp_tax_type
                  AND     flvv.enabled_flag             =   cv_enabled_flag
                  AND     TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                              AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
                )                         flv_tax   -- �ŋ敪���擾
-- 2020/05/07 Ver1.14 N.Abe ADD START
              ,( SELECT flvv.lookup_code    tax_kbn
                       ,flvv.description    tax_kbn_name
                 FROM   fnd_lookup_values_vl    flvv
--  Ver1.16 K.Kanada Mod Start
--                 WHERE  flvv.lookup_type              =   cv_lkup_sp_tax_type
                 WHERE  flvv.lookup_type              =   cv_lkup_elect_tax_kbn
--  Ver1.16 K.Kanada Mod End
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_tax2  -- BM�ŋ敪���擾
-- 2020/05/07 Ver1.14 N.Abe ADD END
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_is_fee -- �r�o�ꌈ�U���萔�����S�敪�i�ݒu���^���j
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_fee -- �r�o�ꌈ�U���萔�����S�敪�i�Љ�萔���j
              ,(SELECT  flvv.lookup_code    bk_chg_bearer_cd
                       ,flvv.attribute1     bk_chg_bearer_nm
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_trns_fee_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_fee -- �r�o�ꌈ�U���萔�����S�敪�i�d�C��j
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_ic_mon  -- �U�����i�Љ�萔���j
              ,(SELECT  flvv.lookup_code    trans_month_code
                       ,flvv.meaning        trans_month_name
                FROM    fnd_lookup_values_vl    flvv
                WHERE   flvv.lookup_type              =   cv_lkup_months_type
                 AND    flvv.enabled_flag             =   cv_enabled_flag
                 AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                            AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
               )                         flv_e_mon  -- �U�����i�d�C��j
              ,xxcso_contract_other_custs xcoc      -- �_���ȊO�e�[�u��
              ,ap_bank_branches           abb1      -- ��s�x�X�}�X�^1
              ,ap_bank_branches           abb2      -- ��s�x�X�}�X�^2
              ,ap_bank_branches           abb3      -- ��s�x�X�}�X�^3
              ,xxcso_contract_customers   xcc       -- �_���e�[�u��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        WHERE  xcm.contract_management_id = gt_con_mng_id
          AND  xcm.sp_decision_header_id = xsdh.sp_decision_header_id
          /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
          --AND  xsdc.sp_decision_header_id = xsdh.sp_decision_header_id
          --AND  xsdc.sp_decision_customer_class = cv_sp_d_cust_class_3
          /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
          AND  xcm.install_account_id = xcasv.cust_account_id
          /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
          --AND  xsdc.customer_id = xbav.vendor_id(+)
          /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
          AND  xlv2.dept_code = xcm.publish_dept_code
          /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� START */
          AND  xd.supplier_id               = xbav.vendor_id(+)
          AND  xd.contract_management_id(+) = xcm.contract_management_id
          AND  xd.delivery_div(+)           = cv_delivery_div_1
          AND  pvs.vendor_id(+)             = xd.supplier_id
-- == 2010/08/03 V1.9 Added START ===============================================================
        AND   xbav.bank_account_type        =   flv.lookup_code(+)
-- == 2010/08/03 V1.9 Added END   ===============================================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          AND  xcm.contract_other_custs_id    = xcoc.contract_other_custs_id(+)
          AND  flv_tax.tax_type(+)            = NVL2(xsdh.tax_type, xsdh.tax_type, cv_in_tax)
-- 2020/05/07 Ver1.14 N.Abe ADD START
          AND  flv_tax2.tax_kbn(+)            = NVL( xd.bm_tax_kbn, '1' )
-- 2020/05/07 Ver1.14 N.Abe ADD END
          AND  abb1.bank_number(+)            = xcoc.install_supp_bk_number
          AND  abb1.bank_num(+)               = xcoc.install_supp_branch_number
          AND  abb2.bank_number(+)            = xcoc.intro_chg_bk_number
          AND  abb2.bank_num(+)               = xcoc.intro_chg_branch_number
          AND  abb3.bank_number(+)            = xcoc.electric_bk_number
          AND  abb3.bank_num(+)               = xcoc.electric_branch_number
          AND  xcc.contract_customer_id       = xcm.contract_customer_id
          AND  flv_is_fee.bk_chg_bearer_cd(+) = xcoc.install_supp_bk_chg_bearer
          AND  flv_ic_fee.bk_chg_bearer_cd(+) = xcoc.intro_chg_bk_chg_bearer
          AND  flv_e_fee.bk_chg_bearer_cd(+)  = xcoc.electric_bk_chg_bearer
          AND  flv_ic_mon.trans_month_code(+) = xsdh.intro_chg_trans_month
          AND  flv_e_mon.trans_month_code(+)  = xsdh.electric_trans_month
          AND  flv_is_koza.bk_acct_type_cd(+) = xcoc.install_supp_bk_acct_type
          AND  flv_ic_koza.bk_acct_type_cd(+) = xcoc.intro_chg_bk_acct_type
          AND  flv_e_koza.bk_acct_type_cd(+)  = xcoc.electric_bk_acct_type
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
        ;
          --AND  pv.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num)
          --AND  pvs.vendor_id(+) = NVL(xsdc.customer_id,fnd_api.g_miss_num);
          /* 2010.03.02 K.Hosoi E_�{�ғ�_01678�Ή� END */
--
        /* 2009.11.12 K.Satomura I_E_658�Ή� START */
        --SELECT  (CASE
        --          WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
        --               xev2.position_name_old
        --          ELSE xev2.position_name_new
        --        END)  issue_belonging_boss_position                -- ���s���������E�ʖ�
        --        ,xev2.full_name issue_belonging_boss               -- ����
        --INTO    o_rep_cont_data_rec.issue_belonging_boss_position  -- ���s���������E�ʖ�
        --        ,o_rep_cont_data_rec.issue_belonging_boss          -- ����
        --FROM    xxcso_employees_v2         xev2     -- �]�ƈ��}�X�^�i�ŐV�j�r���[
        --WHERE   ((TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
        --           AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code)
        --       OR
        --        (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
        --           AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
        --           AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code)
        --       )
        --AND ROWNUM = 1;
        /* 2009.11.12 K.Satomura I_E_658�Ή� END */
--
      EXCEPTION
        -- ���o���ʂ������̏ꍇ
        WHEN TOO_MANY_ROWS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_05           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
        -- �����ȊO�̃G���[�̏ꍇ
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
--
    /* 2009.11.12 K.Satomura I_E_658�Ή� START */
    -- =================================
    -- ���s���E�ʖ��擾
    -- =================================
    BEGIN
      SELECT (
               CASE
                 WHEN (TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate) THEN
                   xev2.position_name_old
                 ELSE
                   xev2.position_name_new
               END
             ) issue_belonging_boss_position     -- ���s���������E�ʖ�
            ,xev2.full_name issue_belonging_boss -- ����
      INTO   o_rep_cont_data_rec.issue_belonging_boss_position -- ���s���������E�ʖ�
            ,o_rep_cont_data_rec.issue_belonging_boss          -- ����
      FROM   xxcso_employees_v2 xev2 -- �]�ƈ��}�X�^�i�ŐV�j�r���[
      WHERE  (
               (
                     TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) <= ld_sysdate
                 AND xev2.position_code_new IN (cv_p_code_002, cv_p_code_003)
                 AND xev2.work_base_code_new = o_rep_cont_data_rec.publish_base_code
               )
             OR
               (
                     TRUNC(NVL(TO_DATE(xev2.issue_date, 'YYYY/MM/DD'), ld_sysdate)) > ld_sysdate
                 AND xev2.position_code_old IN (cv_p_code_002, cv_p_code_003)
                 AND xev2.work_base_code_old = o_rep_cont_data_rec.publish_base_code
               )
             )
      AND    ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        o_rep_cont_data_rec.issue_belonging_boss_position := NULL;
        o_rep_cont_data_rec.issue_belonging_boss          := NULL;
        --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                     );
        --
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
        --
    END;
    --
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- �ݒu�於
    o_rep_memo_data_rec.install_address  := o_rep_cont_data_rec.install_address;
    -- �ݒu��Z��
    o_rep_memo_data_rec.install_name     := o_rep_cont_data_rec.install_name;
    -- �n��Ǘ����_�擾
    BEGIN
      SELECT
        xhda_c.cur_dpt_cd AS area_mgr_base_code   -- �n��Ǘ����_�R�[�h
/* 2015/06/25 Ver1.12 Y.Shoji ADD START */
       ,SUBSTR(xhda_a.dpt3_name, 1, LENGTH(xhda_a.dpt3_name) -1 ) AS a_mgr_boss_org_nm  -- ���s��������(L3�K�w�̖�����"�v"������������)
/* 2015/06/25 Ver1.12 Y.Shoji ADD END */
      INTO
        lt_area_mgr_base_cd                       -- �n��Ǘ����_�R�[�h
/* 2015/06/25 Ver1.12 Y.Shoji ADD START */
       ,lt_a_mgr_boss_org_nm                      -- ���s��������(L3�K�w�̖�����"�v"������������)
/* 2015/06/25 Ver1.12 Y.Shoji ADD END */
      FROM xxcmm_hierarchy_dept_all_v xhda_a
      ,(SELECT
          xhda_b.cur_dpt_cd  AS cur_dpt_cd
         ,xhda_b.dpt3_cd     AS dpt3_cd
        FROM xxcmm_hierarchy_dept_all_v xhda_b    -- �S����K�w�r���[
        WHERE EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values   flv
                      WHERE  flv.lookup_type     = cv_lkup_sp_mgr_type
                        AND  flv.language        = 'JA'
                        AND  flv.attribute1      = cv_lkup_sp_mgr_memo
                        AND  ld_sysdate  BETWEEN NVL(flv.start_date_active ,ld_sysdate)
                                             AND NVL(flv.end_date_active   ,ld_sysdate)
                        AND  flv.enabled_flag    = cv_enabled_flag
                        AND  xhda_b.cur_dpt_cd   = flv.lookup_code
                     )
      ) xhda_c
      WHERE xhda_a.dpt3_cd    = xhda_c.dpt3_cd
      AND   xhda_a.cur_dpt_lv = 5
      AND   xhda_a.cur_dpt_cd = o_rep_cont_data_rec.publish_base_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_area_mgr_base_cd  := NULL;
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
    -- �n��c�Ɩ{�������擾
    IF ( lt_area_mgr_base_cd IS NOT NULL) THEN
      BEGIN
        SELECT NVL2(xlv2.zip, cv_post_mark || xlv2.zip || ' ', '') || xlv2.address_line1  mgr_boss_org_ad -- ���s�������Z��
/* 2015/06/25 Ver1.12 Y.Shoji DEL START */
--              ,xlv2.location_name                                                         mgr_boss_org_nm -- ���s��������
/* 2015/06/25 Ver1.12 Y.Shoji DEL END */
              ,xev2.position_name_new                                                     mgr_boss_pos    -- ���s���������E�ʖ�
              ,xev2.full_name                                                             mgr_boss        -- ����
        INTO   lt_a_mgr_boss_org_ad                                                         -- ���s�������Z��
/* 2015/06/25 Ver1.12 Y.Shoji DEL START */
--              ,lt_a_mgr_boss_org_nm                                                         -- ���s��������
/* 2015/06/25 Ver1.12 Y.Shoji DEL END */
              ,lt_a_mgr_boss_pos                                                            -- ���s���������E�ʖ�
              ,lt_a_mgr_boss                                                                -- ����
        FROM   per_all_people_f        papf                                                 -- �]�ƈ��}�X�^
              ,per_all_assignments_f   paaf                                                 -- �A�T�C�����g�}�X�^
              ,per_periods_of_service  ppos                                                 -- �]�ƈ��T�[�r�X���ԃ}�X�^
              ,xxcso_employees_v2      xev2                                                 -- �]�ƈ��}�X�^�i�ŐV�j�r��
              ,xxcso_locations_v2      xlv2                                                 -- ���Ə��}�X�^�i�ŐV�j�r���[
        WHERE  papf.person_id             = paaf.person_id
        AND    paaf.period_of_service_id  = ppos.period_of_service_id
        AND    papf.effective_start_date  = ppos.date_start
        AND    papf.effective_start_date <= ld_sysdate
        AND    papf.effective_end_date   >= ld_sysdate
        AND    paaf.effective_start_date <= ld_sysdate
        AND    paaf.effective_end_date   >= ld_sysdate
        AND    ppos.actual_termination_date IS NULL
        AND    papf.attribute11           = gt_gen_mgr_pos_code
        AND    EXISTS (SELECT 'X'
                       FROM   fnd_lookup_values  flv
                       WHERE  flv.lookup_type  = cv_lkup_sp_mgr_type
                       AND    flv.language     = 'JA'
                       AND    flv.attribute1   = cv_lkup_sp_mgr_memo
                       AND    TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flv.start_date_active ,ld_sysdate))
                                                  AND     TRUNC(NVL(flv.end_date_active   ,ld_sysdate))
                       AND    flv.enabled_flag = cv_enabled_flag
                       AND    flv.lookup_code  = paaf.ass_attribute5
                      )
        AND    paaf.ass_attribute5  = lt_area_mgr_base_cd
        AND    xev2.employee_number = papf.employee_number
        AND    xlv2.dept_code       = lt_area_mgr_base_cd;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                         ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg || SQLERRM;
          RAISE global_process_expt;
      END;
    END IF;
    -- �����{�����i���В��j���擾
    BEGIN
      SELECT NVL2(flv_e_vice_org.zip, cv_post_mark || flv_e_vice_org.zip || ' ', '')
               || flv_e_vice_org.address_line1                                  vice_pres_org_ad  -- ���s�������Z��
            ,flv_e_vice_org.location_name                                       vice_pres_org_nm  -- ���s��������
/* 2015/06/25 Ver1.12 Y.Shoji MOD START */
--            ,xev2.position_name_new                                             vice_pres_pos     -- ���s���������E�ʖ�
            ,flv_e_vice_org.position_name_new                                   vice_pres_pos     -- ���s���������E�ʖ�
/* 2015/06/25 Ver1.12 Y.Shoji MOD END */
            ,xev2.full_name                                                     vice_pres         -- ����
      INTO   lt_e_vice_pres_org_ad                                                        -- ���s�������Z��
            ,lt_e_vice_pres_org_nm                                                        -- ���s��������
            ,lt_e_vice_pres_pos                                                           -- ���s���������E�ʖ�
            ,lt_e_vice_pres                                                               -- ����
      FROM   xxcso_employees_v2 xev2                                                      -- �]�ƈ��}�X�^�i�ŐV�j�r��
            ,(SELECT  flvv.lookup_code        dept_code
                     ,flvv.meaning            location_name
                     ,flvv.attribute1         zip
                     ,flvv.attribute2         address_line1
/* 2015/06/25 Ver1.12 Y.Shoji ADD START */
                     ,flvv.description        position_name_new        -- ���s���������E�ʖ�
/* 2015/06/25 Ver1.12 Y.Shoji ADD END */
                FROM  fnd_lookup_values_vl    flvv
                WHERE flvv.lookup_type      = cv_lkup_e_vice_org
                 AND  flvv.enabled_flag     = cv_enabled_flag
                 AND  TRUNC(ld_sysdate)   BETWEEN TRUNC(NVL(flvv.start_date_active ,ld_sysdate))
                                          AND     TRUNC(NVL(flvv.end_date_active   ,ld_sysdate))
             ) flv_e_vice_org                                                             -- �����{��������
      WHERE xev2.work_base_code_new         = gt_e_vice_pres_base
      AND   xev2.qualify_code_new           = gt_e_vice_pres_qual
      AND   flv_e_vice_org.dept_code        = gt_e_vice_pres_base
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_contract_num        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => gt_contract_number         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_process_expt;
    END;
    -- ���s���������E�ʁA���s�����������i�ݒu���^���j
    IF (lt_install_supp_amt < gn_is_amt_branch) THEN
      o_rep_memo_data_rec.install_supp_org_addr     := o_rep_cont_data_rec.issue_belonging_address;
/* 2015/06/25 Ver1.12 Y.Shoji MOD START */
--      o_rep_memo_data_rec.install_supp_org_name     := o_rep_cont_data_rec.issue_belonging_name;
      -- �S�p�X�y�[�X6�����ɂ��󎚈ʒu�̒���
      o_rep_memo_data_rec.install_supp_org_name     := LPAD('�@', 12, '�@') || o_rep_cont_data_rec.issue_belonging_name;
/* 2015/06/25 Ver1.12 Y.Shoji MOD END */
      o_rep_memo_data_rec.install_supp_org_boss_pos := o_rep_cont_data_rec.issue_belonging_boss_position;
      o_rep_memo_data_rec.install_supp_org_boss     := o_rep_cont_data_rec.issue_belonging_boss;
    ELSIF (lt_install_supp_amt < gn_is_amt_areamgr) THEN
      o_rep_memo_data_rec.install_supp_org_addr     := lt_a_mgr_boss_org_ad;
/* 2015/06/25 Ver1.12 Y.Shoji MOD START */
--      o_rep_memo_data_rec.install_supp_org_name     := lt_a_mgr_boss_org_nm;
      -- �S�p�X�y�[�X6�����ɂ��󎚈ʒu�̒���
      o_rep_memo_data_rec.install_supp_org_name     := LPAD('�@', 12, '�@') || lt_a_mgr_boss_org_nm;
/* 2015/06/25 Ver1.12 Y.Shoji MOD END */
      o_rep_memo_data_rec.install_supp_org_boss_pos := lt_a_mgr_boss_pos;
      o_rep_memo_data_rec.install_supp_org_boss     := lt_a_mgr_boss;
    ELSE
      o_rep_memo_data_rec.install_supp_org_addr     := lt_e_vice_pres_org_ad;
      o_rep_memo_data_rec.install_supp_org_name     := lt_e_vice_pres_org_nm;
      o_rep_memo_data_rec.install_supp_org_boss_pos := lt_e_vice_pres_pos;
      o_rep_memo_data_rec.install_supp_org_boss     := lt_e_vice_pres;
    END IF;
    -- ���s���������E�ʁA���s�����������i�Љ�萔���j
    o_rep_memo_data_rec.intro_chg_org_addr          := lt_a_mgr_boss_org_ad;
    o_rep_memo_data_rec.intro_chg_org_name          := lt_a_mgr_boss_org_nm;
    o_rep_memo_data_rec.intro_chg_org_boss_pos      := lt_a_mgr_boss_pos;
    o_rep_memo_data_rec.intro_chg_org_boss          := lt_a_mgr_boss;
    -- ���s���������E�ʁA���s�����������i�d�C��j
    o_rep_memo_data_rec.electric_org_addr           := o_rep_cont_data_rec.issue_belonging_address;
    o_rep_memo_data_rec.electric_org_name           := o_rep_cont_data_rec.issue_belonging_name;
    o_rep_memo_data_rec.electric_org_boss_pos       := o_rep_cont_data_rec.issue_belonging_boss_position;
    o_rep_memo_data_rec.electric_org_boss           := o_rep_cont_data_rec.issue_belonging_boss;
    --
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    /* 2009.11.12 K.Satomura I_E_658�Ή� END */
    -- =================================
    -- �̔��萔�����擾�iA-2-1,2 -2�j
    -- =================================
    BEGIN
--
      -- �ϐ�������
      ln_lines_cnt             := 0;               -- ���׌���
      ln_bm1_bm_rate           := 0;               -- �a�l�P�a�l��
      ln_bm1_bm_amount         := 0;               -- �a�l�P�a�l���z
-- == 2010/08/03 V1.9 Added START ===============================================================
--      lb_bm1_bm_rate           := TRUE;            -- �a�l�P�a�l���ɂ��藦���f�t���O
--      lb_bm1_bm_amount         := TRUE;            -- �a�l�P�a�l���z�ɂ��藦���f�t���O
      lb_bm1_bm_rate           := FALSE;           -- �a�l�P�a�l���ɂ��藦���f�t���O
      lb_bm1_bm_amount         := FALSE;           -- �a�l�P�a�l���z�ɂ��藦���f�t���O
-- == 2010/08/03 V1.9 Added END   ===============================================================
      lb_bm1_bm                := FALSE;           -- �̔��萔���L���t���O(TRUE:�L,FALSE:��)
--
      -- �r�o�ꌈ���׃J�[�\���I�[�v��
      OPEN l_sales_charge_cur;
--
      <<sales_charge_loop>>
      LOOP
        FETCH l_sales_charge_cur INTO l_sales_charge_rec;
--
        EXIT WHEN l_sales_charge_cur%NOTFOUND
          OR l_sales_charge_cur%ROWCOUNT = 0;
--
        -- �a�l�P�a�l���A���z�A��������敪�A���ߓ��A�������A������
        IF (ln_lines_cnt = 0) THEN
          -- ��������敪
          lv_cond_business_type := l_sales_charge_rec.condition_business_type;
          -- �����
          IF (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
            o_rep_cont_data_rec.exchange_condition := cv_uri_rate;
          -- �e���
          ELSIF (lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)) THEN
            o_rep_cont_data_rec.exchange_condition := cv_youki_rate;
          END IF;
          --
-- == 2010/08/03 V1.9 Added START ===============================================================
          lv_condition_content_type :=  l_sales_charge_rec.condition_content_type;        --  �S�e��ꗥ�敪
-- == 2010/08/03 V1.9 Added END   ===============================================================
--
          /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 START */
          ---- �a�l�P�a�l���A���z
          --IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
          --  lb_bm1_bm_rate := FALSE;
          --ELSE
          --  ln_bm1_bm_rate := l_sales_charge_rec.bm1_bm_rate;
          --END IF;
          --IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
          --  lb_bm1_bm_amount := FALSE;
          --ELSE
          --  ln_bm1_bm_amount := l_sales_charge_rec.bm1_bm_amount;
          --END IF;
          /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 END */
--
          -- ���ߓ�
          o_rep_cont_data_rec.close_day_code := l_sales_charge_rec.close_day_code;
          -- ������
          o_rep_cont_data_rec.transfer_month_code := l_sales_charge_rec.transfer_month_code;
          -- ������
          o_rep_cont_data_rec.transfer_day_code := l_sales_charge_rec.transfer_day_code;
        ELSE
          /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 START */
          NULL;
          ---- �a�l�P�a�l��
          --IF (lb_bm1_bm_rate = TRUE) THEN
          --  IF (l_sales_charge_rec.bm1_bm_rate IS NULL) THEN
          --    lb_bm1_bm_rate := FALSE;
          --  ELSIF (ln_bm1_bm_rate <> l_sales_charge_rec.bm1_bm_rate) THEN
          ----    lb_bm1_bm_rate := FALSE;
          --  END IF;
          --END IF;
          ---- �a�l�P�a�l���z
          --IF (lb_bm1_bm_amount = TRUE) THEN
          --  IF (l_sales_charge_rec.bm1_bm_amount IS NULL) THEN
          --    lb_bm1_bm_amount := FALSE;
          --  ELSIF (ln_bm1_bm_amount <> l_sales_charge_rec.bm1_bm_amount) THEN
          --    lb_bm1_bm_amount := FALSE;
          --  END IF;
          --END IF;
          /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 END */
        END IF;
         
        
        -- �̔��萔���L���`�F�b�N
        IF ((l_sales_charge_rec.bm1_bm_rate IS NOT NULL AND
              l_sales_charge_rec.bm1_bm_rate <> '0') OR
             (l_sales_charge_rec.bm1_bm_amount IS  NOT NULL AND
              l_sales_charge_rec.bm1_bm_amount <> '0')
            ) THEN
--
--  Ver1.16 K.Kanada Mod Start
          -- ===================================================
          -- �������e�̕����ҏW�@�i���ꗥ�����͇A�őΉ��j
          -- ===================================================
          --
          lv_cond_conts_tmp := g_contents_msg(1) ;      -- �Œ蕶��
          --
          -- �����ʏ���
          IF (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
            -- �z
            IF (l_sales_charge_rec.bm1_bm_amount IS NOT NULL AND l_sales_charge_rec.bm1_bm_amount <> '0') THEN
              -- �ō�
              IF    o_rep_cont_data_rec.bm_tax_kbn = cv_in_tax THEN
                lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(11) ;
              -- �Ŕ�
              ELSIF o_rep_cont_data_rec.bm_tax_kbn = cv_ex_tax THEN
                lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(12) ;
              END IF ;
            END IF ;
          END IF ;
          --
          -- �����ʏ���
          IF    (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
            lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(2)
                                 || TO_CHAR(l_sales_charge_rec.sales_price) || g_contents_msg(3) ;  -- (2)�{�����{(3)
          -- �e��ʏ���
          ELSIF (lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)) THEN
            lv_cond_conts_tmp := lv_cond_conts_tmp || l_sales_charge_rec.container_type_name
                                 || g_contents_msg(4) ;                                             -- �e��敪���{(4)
          END IF ;
          --
          -- �e��ʏ���
          IF (lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)) THEN
            -- ��
            IF (l_sales_charge_rec.bm1_bm_rate IS NOT NULL AND l_sales_charge_rec.bm1_bm_rate <> '0') THEN
              -- �ō�
              IF    o_rep_cont_data_rec.bm_tax_kbn = cv_in_tax THEN
                lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(11) ;
              -- �Ŕ�
              ELSIF o_rep_cont_data_rec.bm_tax_kbn = cv_ex_tax THEN
                lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(12) ;
              END IF ;
            END IF ;
          END IF ;
          --
          -- �z
          IF    (l_sales_charge_rec.bm1_bm_amount IS NOT NULL AND l_sales_charge_rec.bm1_bm_amount <> '0') THEN
            lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(7)
                                 || TO_CHAR(l_sales_charge_rec.bm1_bm_amount) || g_contents_msg(8) ;  -- (7)�{BM1�z�{(8)
          -- ��
          ELSIF (l_sales_charge_rec.bm1_bm_rate   IS NOT NULL AND l_sales_charge_rec.bm1_bm_rate   <> '0') THEN
            lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(9)
                                 || TO_CHAR(l_sales_charge_rec.bm1_bm_rate)   || g_contents_msg(10) ; -- (9)�{BM1���{(10)
          END IF ;
          --
          -- �����ʏ���
          IF (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
            -- ��
            IF (l_sales_charge_rec.bm1_bm_rate IS NOT NULL AND l_sales_charge_rec.bm1_bm_rate <> '0') THEN
              -- �ō�
              IF    o_rep_cont_data_rec.bm_tax_kbn = cv_in_tax THEN
                lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(13) ;
              -- �Ŕ�
              ELSIF o_rep_cont_data_rec.bm_tax_kbn = cv_ex_tax THEN
                lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(14) ;
              END IF ;
            END IF ;
          END IF ;
          --
          -- �������e�Z�b�g
          IF (o_rep_cont_data_rec.condition_contents_1 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_1  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_2  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_3  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_4  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_5  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_6  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_7  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_8  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_9  := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_10 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_11 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_12 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_13 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_13 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_14 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_14 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_15 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_15 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_16 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_16 := lv_cond_conts_tmp ;
          ELSIF (o_rep_cont_data_rec.condition_contents_17 IS NULL) THEN
            o_rep_cont_data_rec.condition_contents_17 := lv_cond_conts_tmp ;
          END IF;
--          -- �������e�Z�b�g
--          IF (o_rep_cont_data_rec.condition_contents_1 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_1 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_2 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_3 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_4 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_5 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_6 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_7 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_8 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_9 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_10 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_11 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_12 := l_sales_charge_rec.condition_contents;
--/* 2014/02/03 Ver1.10 S.Niki ADD START */
--          ELSIF (o_rep_cont_data_rec.condition_contents_13 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_13 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_14 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_14 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_15 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_15 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_16 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_16 := l_sales_charge_rec.condition_contents;
--          ELSIF (o_rep_cont_data_rec.condition_contents_17 IS NULL) THEN
--            o_rep_cont_data_rec.condition_contents_17 := l_sales_charge_rec.condition_contents;
--/* 2014/02/03 Ver1.10 S.Niki ADD END */
--          END IF;
--  Ver1.16 K.Kanada Mod End
          lb_bm1_bm := TRUE;
--
          -- �����v�Z
          ln_lines_cnt := ln_lines_cnt + 1;
        ELSIF (lb_bm1_bm = TRUE) THEN
          lb_bm1_bm := TRUE;
        ELSE
          lb_bm1_bm := FALSE;
        END IF;
--
      END LOOP sales_charge_loop;
--
      -- �J�[�\���E�N���[�Y
      CLOSE l_sales_charge_cur;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�̔��萔����񌏐��F' || ln_lines_cnt || '��'
      );
--
-- == 2010/08/03 V1.9 Modified START ===============================================================
--      -- ���׌�����1���𒴂���ꍇ
--      IF (ln_lines_cnt > 1) THEN
      IF  (     (     ln_lines_cnt  >  1
                  OR  lv_condition_content_type <> '0'
                )
            AND lv_cond_business_type IN(cv_cond_b_type_3, cv_cond_b_type_4)
          )
      THEN
        --  ���ׂQ���ȏ�܂��́A�S�e��ꗥ�A����������u�e��ʁv�̏ꍇ
-- == 2010/08/03 V1.9 Modified END   ===============================================================
--
        /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 START */
        -- �a�l�P�a�l�� �藦���f
        -- ZERO�����NULL�łȂ��l�̎�ސ�
        -- 0������Y�������̂��ߒ�z�łȂ�
        -- 1�������z
        -- 2���ȏ㥥����������̂��ߒ�z�łȂ�
        ln_work_cnt := 0;
        ln_work_cnt_ritu := 0;
        SELECT count(*)
        INTO   ln_work_cnt
        FROM   (
                 SELECT distinct xsdl.bm1_bm_rate
                 FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
                       ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
                       ,xxcso_sp_decision_lines    xsdl     -- �r�o�ꌈ���׃e�[�u��
                 WHERE  xcm.contract_management_id = gt_con_mng_id
                 AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
                 AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
                 AND    xsdh.condition_business_type  IN 
                        (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
                 AND    (    (xsdl.bm1_bm_rate IS NOT NULL) 
                         AND (xsdl.bm1_bm_rate <> 0) )
        );
--
        ln_work_cnt_ritu := ln_work_cnt;
--
        IF ln_work_cnt = 1 THEN
          lb_bm1_bm_rate := TRUE;
          --���̒l���擾
          SELECT distinct xsdl.bm1_bm_rate
          INTO   ln_bm1_bm_rate
          FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
                ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
                ,xxcso_sp_decision_lines    xsdl     -- �r�o�ꌈ���׃e�[�u��
          WHERE  xcm.contract_management_id = gt_con_mng_id
          AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
          AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
          AND    xsdh.condition_business_type  IN 
                 (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
          AND    (    (xsdl.bm1_bm_rate IS NOT NULL) 
                  AND (xsdl.bm1_bm_rate <> 0) );
        ELSE
          lb_bm1_bm_rate := FALSE;
        END IF;
--
        -- �a�l�P�a�l���z �藦���f
        ln_work_cnt := 0;
        ln_work_cnt_gaku := 0;
        SELECT count(*)
        INTO   ln_work_cnt
        FROM   (
                 SELECT distinct xsdl.bm1_bm_amount
                 FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
                       ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
                       ,xxcso_sp_decision_lines    xsdl     -- �r�o�ꌈ���׃e�[�u��
                 WHERE  xcm.contract_management_id = gt_con_mng_id
                 AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
                 AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
                 AND    xsdh.condition_business_type  IN 
                        (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
                 AND    (    (xsdl.bm1_bm_amount IS NOT NULL) 
                         AND (xsdl.bm1_bm_amount <> 0) )
        );
--
        ln_work_cnt_gaku := ln_work_cnt;
--
        IF ln_work_cnt = 1 THEN
          lb_bm1_bm_amount := TRUE;
          --���z�̒l���擾
          SELECT distinct xsdl.bm1_bm_amount
          INTO   ln_bm1_bm_amount
          FROM   xxcso_contract_managements xcm      -- �_��Ǘ��e�[�u��
                ,xxcso_sp_decision_headers  xsdh     -- �r�o�ꌈ�w�b�_�e�[�u��
                ,xxcso_sp_decision_lines    xsdl     -- �r�o�ꌈ���׃e�[�u��
          WHERE  xcm.contract_management_id = gt_con_mng_id
          AND    xcm.sp_decision_header_id  = xsdh.sp_decision_header_id
          AND    xsdh.sp_decision_header_id = xsdl.sp_decision_header_id
          AND    xsdh.condition_business_type  IN 
                 (cv_cond_b_type_1, cv_cond_b_type_2, cv_cond_b_type_3, cv_cond_b_type_4)
          AND    (    (xsdl.bm1_bm_amount IS NOT NULL) 
                  AND (xsdl.bm1_bm_amount <> 0) );
        ELSE
          lb_bm1_bm_amount := FALSE;
        END IF;
        
        --���������͊z�̂ǂ��炩�������P��ނ̏ꍇ�����藦�Ƃ���
        IF ((ln_work_cnt_ritu = 1) AND (ln_work_cnt_gaku = 0))
        OR ((ln_work_cnt_ritu = 0) AND (ln_work_cnt_gaku = 1)) THEN
          NULL;
        ELSE
          lb_bm1_bm_rate := FALSE;
          lb_bm1_bm_amount := FALSE;
        END IF;
        /* 2009.11.30 T.Maruyama E_�{�ғ�_00193 END */
        
        
-- == 2010/08/03 V1.9 Modified START ===============================================================
--        -- �e��ʁA�藦�̏ꍇ
--        IF ((lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4))
--               AND (lb_bm1_bm_rate OR lb_bm1_bm_amount)) THEN
        IF  (     lb_bm1_bm_rate
              OR  lb_bm1_bm_amount
              OR  lv_condition_content_type <> '0'
            )
        THEN
--  Ver1.16 K.Kanada Mod Start
--          --  �S�e��ꗥ�A�܂��́A�藦
---- == 2010/08/03 V1.9 Modified END   ===============================================================
--          -- �a�l�P�a�l��
---- == 2010/08/03 V1.9 Modified START ===============================================================
----          IF (lb_bm1_bm_rate) THEN
----            lv_cond_conts_tmp := '�̔����z�ɂ��A�P�{ ' || ln_bm1_bm_rate || '%���x����';
----          -- �a�l�P�a�l���z
----          ELSE
----            lv_cond_conts_tmp := '�̔����z�ɂ��A�P�{ ' || ln_bm1_bm_amount || '�~���x����';
----          END IF;
--          IF  (     lb_bm1_bm_rate
--                OR  lv_condition_content_type = '1'
--              )
--          THEN
--            lv_cond_conts_tmp := '�̔����z�ɑ΂��A' || ln_bm1_bm_rate || '%�Ƃ���B';
--          -- �a�l�P�a�l���z
--          ELSE
--            lv_cond_conts_tmp := '�̔����ʂɑ΂��A�P�{������ ' || ln_bm1_bm_amount || '�~�Ƃ���B';
--          END IF;
---- == 2010/08/03 V1.9 Modified END   ===============================================================
          -- ===================================================
          -- �������e�̕����ҏW�A�i���ꗥ�����j
          -- ===================================================
          --
          lv_cond_conts_tmp := g_contents_msg(1) ;      -- �Œ蕶��
          --
--  Ver1.17 K.Kanada Mod Start
--          -- �z
--          IF    (l_sales_charge_rec.bm1_bm_amount IS NOT NULL AND l_sales_charge_rec.bm1_bm_amount <> '0') THEN
--            lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(5)       || g_contents_msg(7)
--                                 || TO_CHAR(l_sales_charge_rec.bm1_bm_amount) || g_contents_msg(8) ;  -- (5)�{(7)�{BM1�z�{(8)
--          -- ��
--          ELSIF (l_sales_charge_rec.bm1_bm_rate   IS NOT NULL AND l_sales_charge_rec.bm1_bm_rate   <> '0') THEN
          -- �z
          IF    (ln_bm1_bm_amount IS NOT NULL AND ln_bm1_bm_amount <> '0') THEN
            lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(5)       || g_contents_msg(7)
                                 || TO_CHAR(ln_bm1_bm_amount) || g_contents_msg(8) ;  -- (5)�{(7)�{BM1�z�{(8)
          -- ��
          ELSIF (ln_bm1_bm_rate IS NOT NULL AND ln_bm1_bm_rate <> '0') THEN
--  Ver1.17 K.Kanada Mod End
            -- �ō�
            IF    o_rep_cont_data_rec.bm_tax_kbn = cv_in_tax THEN
              lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(11) ;
            -- �Ŕ�
            ELSIF o_rep_cont_data_rec.bm_tax_kbn = cv_ex_tax THEN
              lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(12) ;
            END IF ;
            -- ��
            lv_cond_conts_tmp := lv_cond_conts_tmp || g_contents_msg(6)     || g_contents_msg(9)
--  Ver1.17 K.Kanada Mod Start
--                                 || TO_CHAR(l_sales_charge_rec.bm1_bm_rate) || g_contents_msg(10) ; -- (6)�{(9)�{BM1���{(10)
                                 || TO_CHAR(ln_bm1_bm_rate) || g_contents_msg(10) ; -- (6)�{(9)�{BM1���{(10)
--  Ver1.17 K.Kanada Mod End
          END IF ;
--  Ver1.16 K.Kanada Mod End
          --
          -- ��������i�藦�j
          o_rep_cont_data_rec.exchange_condition := cv_tei_rate;
          -- �������e�Z�b�g
          o_rep_cont_data_rec.condition_contents_1 := lv_cond_conts_tmp;
          o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;   -- �ȉ��]��
          o_rep_cont_data_rec.condition_contents_3 := NULL;
          o_rep_cont_data_rec.condition_contents_4 := NULL;
          o_rep_cont_data_rec.condition_contents_5 := NULL;
          o_rep_cont_data_rec.condition_contents_6 := NULL;
          o_rep_cont_data_rec.condition_contents_7 := NULL;
          o_rep_cont_data_rec.condition_contents_8 := NULL;
          o_rep_cont_data_rec.condition_contents_9 := NULL;
          o_rep_cont_data_rec.condition_contents_10 := NULL;
          o_rep_cont_data_rec.condition_contents_11 := NULL;
          o_rep_cont_data_rec.condition_contents_12 := NULL;
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          o_rep_cont_data_rec.condition_contents_13 := NULL;
          o_rep_cont_data_rec.condition_contents_14 := NULL;
          o_rep_cont_data_rec.condition_contents_15 := NULL;
          o_rep_cont_data_rec.condition_contents_16 := NULL;
          o_rep_cont_data_rec.condition_contents_17 := NULL;
/* 2014/02/03 Ver1.10 S.Niki ADD END */
--
-- == 2010/08/03 V1.9 Modified START ===============================================================
          -- ���O�o��
--          fnd_file.put_line(
--             which  => FND_FILE.LOG
--            ,buff   => '' || CHR(10) || '�̔��萔����񂪗e��ʁA�藦�ł��B'
--          );
          IF  (lv_condition_content_type <> '0')  THEN
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => '' || CHR(10) || '�̔��萔����񂪗e��ʁA�S�e��ꗥ�ł��B'
            );
          ELSE
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => '' || CHR(10) || '�̔��萔����񂪗e��ʁA�藦�ł��B'
            );
          END IF;
-- == 2010/08/03 V1.9 Modified END   ===============================================================
--
-- == 2010/08/03 V1.9 Deleted START ===============================================================
--        ELSE
--          -- �������e��12���ɖ����Ȃ��ꍇ�A�ŏI�s�Ɂu�ȉ��]���v���Z�b�g
--          IF (ln_lines_cnt < 12) THEN
--          -- �������e�Z�b�g
--            IF (o_rep_cont_data_rec.condition_contents_2 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_2 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_3 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_3 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_4 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_4 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_5 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_5 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_6 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_6 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_7 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_7 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_8 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_8 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_9 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_9 := cv_cond_conts_space;    -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_10 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_10 := cv_cond_conts_space;   -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_11 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_11 := cv_cond_conts_space;   -- �ȉ��]��
--            ELSIF (o_rep_cont_data_rec.condition_contents_12 IS NULL) THEN
--              o_rep_cont_data_rec.condition_contents_12 := cv_cond_conts_space;   -- �ȉ��]��
--            END IF;
--          END IF;
-- == 2010/08/03 V1.9 Deleted END   ===============================================================
        END IF;
        --
      END IF;
-- == 2010/08/03 V1.9 Added START ===============================================================
/* 2014/02/03 Ver1.10 S.Niki MOD START */
--      --  �������e��12���ɖ����Ȃ��ꍇ�A�̔��萔���A���Ɓu�ȉ��]���v���Z�b�g
--      IF  (ln_lines_cnt < 12) THEN
      --  �������e���ő�s�ɖ����Ȃ��ꍇ�A�̔��萔���A���Ɓu�ȉ��]���v���Z�b�g
      IF  (ln_lines_cnt < cn_max_line) THEN
/* 2014/02/03 Ver1.10 S.Niki MOD END */
        IF    (lv_cond_business_type IN (cv_cond_b_type_1, cv_cond_b_type_2)) THEN
          --  �����
          IF    (o_rep_cont_data_rec.condition_contents_2   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_2  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_3  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_3   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_3  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_4  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_4   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_4  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_5  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_5   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_5  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_6  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_6   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_6  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_7  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_7   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_7  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_8  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_8   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_8  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_9  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_9   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_9  :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_10 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_10  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_10 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_11 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_11  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_11 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_12 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_12  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_12 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
/* 2014/02/03 Ver1.10 S.Niki ADD START */
            o_rep_cont_data_rec.condition_contents_13 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_13  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_13 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_14 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_14  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_14 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_15 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_15  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_15 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_16 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_16  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_16 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
            o_rep_cont_data_rec.condition_contents_17 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_17  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_17 :=  gt_terms_note_price;      --  �̔��萔���A���i�����ʁj
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          END IF;
          --
        ELSIF (     lv_cond_business_type IN (cv_cond_b_type_3, cv_cond_b_type_4)
                AND lv_condition_content_type = '0'
                AND NOT(lb_bm1_bm_rate)
                AND NOT(lb_bm1_bm_amount)
              )
        THEN
          --  �e��ʁi�S�e��ꗥ�ȊO�A���A�藦�ȊO�j
          IF    (o_rep_cont_data_rec.condition_contents_2   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_2  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_3  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_3   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_3  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_4  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_4   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_4  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_5  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_5   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_5  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_6  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_6   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_6  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_7  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_7   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_7  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_8  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_8   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_8  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_9  :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_9   IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_9  :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_10 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_10  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_10 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_11 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_11  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_11 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_12 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_12  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_12 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
/* 2014/02/03 Ver1.10 S.Niki ADD START */
            o_rep_cont_data_rec.condition_contents_13 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_13  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_13 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_14 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_14  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_14 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_15 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_15  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_15 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_16 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_16  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_16 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
            o_rep_cont_data_rec.condition_contents_17 :=  cv_cond_conts_space;      --  �ȉ��]��
          ELSIF (o_rep_cont_data_rec.condition_contents_17  IS NULL)  THEN
            o_rep_cont_data_rec.condition_contents_17 :=  gt_terms_note_ves;        --  �̔��萔���A���i�e��ʁj
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          END IF;
        END IF;
      END IF;
-- == 2010/08/03 V1.9 Added END   ===============================================================
--
      -- �̔��萔���L���̐ݒ�
        o_rep_cont_data_rec.condition_contents_flag := lb_bm1_bm;
      -- �ݒu���^���L��
      /* 2009.04.27 K.Satomura T1_0705�Ή� START */
      --IF (o_rep_cont_data_rec.install_support_amt IS NOT NULL) THEN
      IF ((o_rep_cont_data_rec.install_support_amt IS NOT NULL)
        AND (o_rep_cont_data_rec.install_support_amt <> 0))
      THEN
      /* 2009.04.27 K.Satomura T1_0705�Ή� END */
        o_rep_cont_data_rec.install_support_amt_flag := TRUE;
      -- �ݒu���^������
      ELSE
        o_rep_cont_data_rec.install_support_amt_flag := FALSE;
      END IF;
      -- �d�C����L��
      IF (o_rep_cont_data_rec.electricity_amount IS NOT NULL) THEN
        o_rep_cont_data_rec.electricity_information_flag := TRUE;
      -- �d�C���񖳂�
      ELSE
        o_rep_cont_data_rec.electricity_information_flag := FALSE;
      END IF;
--
    EXCEPTION
      -- ���o�Ɏ��s�����ꍇ�̌㏈��
      WHEN OTHERS THEN
        -- �J�[�\���E�N���[�Y
        IF (l_sales_charge_cur%ISOPEN) THEN
          CLOSE l_sales_charge_cur;
        END IF;
--
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10             -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_tbl                   -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_sp_decision_lines         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_err_msg               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
    -- *** ������O�n���h�� ***
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
  END get_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_data
   * Description      : ���[�N�e�[�u���ɓo�^(A-3)
   ***********************************************************************************/
  PROCEDURE insert_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- �_�񏑃f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ,i_rep_memo_data_rec    IN         g_rep_memo_data_rtype  -- �o���f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_data';     -- �v���O������
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
    cv_tbl_nm            CONSTANT VARCHAR2(100) := '�����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    cv_memo_tbl_nm       CONSTANT VARCHAR2(100) := '�o�����[���[�N�e�[�u��';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- CSV�o�͏��� 
    -- ======================
    BEGIN
      -- ���[�N�e�[�u���ɓo�^
      INSERT INTO xxcso_rep_auto_sale_cont
        (  install_location                 -- �ݒu���P�[�V����
          ,contract_number                  -- �_�񏑔ԍ�
          ,contract_name                    -- �_��Җ�
          ,contract_period                  -- �_�����
          ,cancellation_offer_code          -- �_������\���o
          ,other_content                    -- ���񎖍�
          ,sales_charge_details_delivery    -- �萔�����׏����t�於
          ,delivery_address                 -- ���t��Z��
          ,install_name                     -- �ݒu�於
          ,install_address                  -- �ݒu��Z��
          ,install_date                     -- �ݒu��
          ,bank_name                        -- ���Z�@�֖�
          ,blanches_name                    -- �x�X��
          ,account_number                   -- �ڋq�R�[�h
          ,bank_account_number              -- �����ԍ�
          ,bank_account_name_kana           -- �������`�J�i
          ,publish_base_code                -- �S�����_
          ,publish_base_name                -- �S�����_��
          ,contract_effect_date             -- �_�񏑔�����
          ,issue_belonging_address          -- ���s�������Z��
          ,issue_belonging_name             -- ���s��������
          ,issue_belonging_boss_position    -- ���s���������E�ʖ�
          ,issue_belonging_boss             -- ���s����������
          ,close_day_code                   -- ����
          ,transfer_month_code              -- ������
          ,transfer_day_code                -- ������
          ,exchange_condition               -- �������
          ,condition_contents_1             -- �������e1
          ,condition_contents_2             -- �������e2
          ,condition_contents_3             -- �������e3
          ,condition_contents_4             -- �������e4
          ,condition_contents_5             -- �������e5
          ,condition_contents_6             -- �������e6
          ,condition_contents_7             -- �������e7
          ,condition_contents_8             -- �������e8
          ,condition_contents_9             -- �������e9
          ,condition_contents_10            -- �������e10
          ,condition_contents_11            -- �������e11
          ,condition_contents_12            -- �������e12
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          ,condition_contents_13            -- �������e13
          ,condition_contents_14            -- �������e14
          ,condition_contents_15            -- �������e15
          ,condition_contents_16            -- �������e16
          ,condition_contents_17            -- �������e17
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          ,install_support_amt              -- �ݒu���^��
          ,electricity_information          -- �d�C����
          ,transfer_commission_info         -- �U�荞�ݎ萔�����
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          ,tax_type_name                    -- �ŋ敪��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
          ,created_by                       -- �쐬��
          ,creation_date                    -- �쐬��
          ,last_updated_by                  -- �ŏI�X�V��
          ,last_update_date                 -- �ŏI�X�V��
          ,last_update_login                -- �ŏI�X�V���O�C��
          ,request_id                       -- �v��id
          ,program_application_id           -- �A�v���P�[�V����id
          ,program_id                       -- �v���O����id
          ,program_update_date              -- �v���O�����X�V��
-- 2020/05/07 Ver1.14 N.Abe ADD START
          ,bm_tax_kbn                       -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
--  Ver1.18 T.Okuyama Add Start
          ,bm1_invoice_t_no                 -- �o�^�ԍ��i���t��j
          ,invoice_t_no                     -- �o�^�ԍ��i���s���j
--  Ver1.18 T.Okuyama Add End
        )
      VALUES
        (  i_rep_cont_data_rec.install_location                 -- �ݒu���P�[�V����
          ,i_rep_cont_data_rec.contract_number                  -- �_�񏑔ԍ�
          ,i_rep_cont_data_rec.contract_name                    -- �_��Җ�
          ,i_rep_cont_data_rec.contract_period                  -- �_�����
          ,i_rep_cont_data_rec.cancellation_offer_code          -- �_������\���o
          ,i_rep_cont_data_rec.other_content                    -- ���񎖍�
          ,i_rep_cont_data_rec.sales_charge_details_delivery    -- �萔�����׏����t�於
          ,i_rep_cont_data_rec.delivery_address                 -- ���t��Z��
          ,i_rep_cont_data_rec.install_name                     -- �ݒu�於
          ,i_rep_cont_data_rec.install_address                  -- �ݒu��Z��
          ,i_rep_cont_data_rec.install_date                     -- �ݒu��
          ,i_rep_cont_data_rec.bank_name                        -- ���Z�@�֖�
          ,i_rep_cont_data_rec.blanches_name                    -- �x�X��
          ,i_rep_cont_data_rec.account_number                   -- �ڋq�R�[�h
          ,i_rep_cont_data_rec.bank_account_number              -- �����ԍ�
          ,i_rep_cont_data_rec.bank_account_name_kana           -- �������`�J�i
          ,i_rep_cont_data_rec.publish_base_code                -- �S�����_
          ,i_rep_cont_data_rec.publish_base_name                -- �S�����_��
          ,i_rep_cont_data_rec.contract_effect_date             -- �_�񏑔�����
          ,i_rep_cont_data_rec.issue_belonging_address          -- ���s�������Z��
          ,i_rep_cont_data_rec.issue_belonging_name             -- ���s��������
          ,i_rep_cont_data_rec.issue_belonging_boss_position    -- ���s���������E�ʖ�
          ,i_rep_cont_data_rec.issue_belonging_boss             -- ���s����������
          ,i_rep_cont_data_rec.close_day_code                   -- ����
          ,i_rep_cont_data_rec.transfer_month_code              -- ������
          ,i_rep_cont_data_rec.transfer_day_code                -- ������
          ,i_rep_cont_data_rec.exchange_condition               -- �������
          ,i_rep_cont_data_rec.condition_contents_1             -- �������e1
          ,i_rep_cont_data_rec.condition_contents_2             -- �������e2
          ,i_rep_cont_data_rec.condition_contents_3             -- �������e3
          ,i_rep_cont_data_rec.condition_contents_4             -- �������e4
          ,i_rep_cont_data_rec.condition_contents_5             -- �������e5
          ,i_rep_cont_data_rec.condition_contents_6             -- �������e6
          ,i_rep_cont_data_rec.condition_contents_7             -- �������e7
          ,i_rep_cont_data_rec.condition_contents_8             -- �������e8
          ,i_rep_cont_data_rec.condition_contents_9             -- �������e9
          ,i_rep_cont_data_rec.condition_contents_10            -- �������e10
          ,i_rep_cont_data_rec.condition_contents_11            -- �������e11
          ,i_rep_cont_data_rec.condition_contents_12            -- �������e12
/* 2014/02/03 Ver1.10 S.Niki ADD START */
          ,i_rep_cont_data_rec.condition_contents_13            -- �������e13
          ,i_rep_cont_data_rec.condition_contents_14            -- �������e14
          ,i_rep_cont_data_rec.condition_contents_15            -- �������e15
          ,i_rep_cont_data_rec.condition_contents_16            -- �������e16
          ,i_rep_cont_data_rec.condition_contents_17            -- �������e17
/* 2014/02/03 Ver1.10 S.Niki ADD END */
          ,i_rep_cont_data_rec.install_support_amt              -- �ݒu���^��
          ,i_rep_cont_data_rec.electricity_information          -- �d�C����
          ,i_rep_cont_data_rec.transfer_commission_info         -- �U�荞�ݎ萔�����
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
          ,i_rep_cont_data_rec.tax_type_name                    -- �ŋ敪��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
          ,cn_created_by                                        -- �쐬��
          ,cd_creation_date                                     -- �쐬��
          ,cn_last_updated_by                                   -- �ŏI�X�V��
          ,cd_last_update_date                                  -- �ŏI�X�V��
          ,cn_last_update_login                                 -- �ŏI�X�V���O�C��
          ,cn_request_id                                        -- �v���h�c
          ,cn_program_application_id                            -- �ݶ�����۸��ѱ��ع����
          ,cn_program_id                                        -- �ݶ�����۸��тh�c
          ,cd_program_update_date                               -- ��۸��эX�V��
-- 2020/05/07 Ver1.14 N.Abe ADD START
          ,i_rep_cont_data_rec.bm_tax_kbn                       -- BM�ŋ敪
-- 2020/05/07 Ver1.14 N.Abe ADD END
--  Ver1.18 T.Okuyama Add Start
          ,i_rep_cont_data_rec.bm1_t_no                         -- �o�^�ԍ��i���t��j
          ,gv_t_number                                          -- �o�^�ԍ��i���s���j
--  Ver1.18 T.Okuyama Add End
        );
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�_�񏑃f�[�^�����[�N�e�[�u���ɓo�^���܂����B'
      );
--
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_07                     --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                 ,iv_token_name3  => cv_tkn_contract_num                  --�g�[�N���R�[�h3
                 ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --�g�[�N���l3
                 ,iv_token_name4  => cv_tkn_request_id                    --�g�[�N���R�[�h3
                 ,iv_token_value4 => cn_request_id                        --�g�[�N���l3
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- �o�����[���[�N�e�[�u���o��
    BEGIN
      -- ���[�N�e�[�u���ɓo�^
      INSERT INTO xxcso_rep_memorandum(
               contract_number               -- �_�񏑔ԍ�
              ,contract_other_custs_id       -- �_���ȊOID
              ,contract_name                 -- �_��Җ�
              ,contract_effect_date          -- �_�񏑔�����
              ,install_name                  -- �ݒu�於
              ,install_address               -- �ݒu��Z��
              ,tax_type_name                 -- �ŋ敪��
              ,install_supp_amt              -- �ݒu���^��
              ,install_supp_payment_date     -- �x�������i�ݒu���^���j
              ,install_supp_bk_chg_bearer    -- �U���萔�����S�i�ݒu���^���j
              ,install_supp_bk_number        -- ��s�ԍ��i�ݒu���^���j
              ,install_supp_bk_name          -- ���Z�@�֖��i�ݒu���^���j
              ,install_supp_branch_number    -- �x�X�ԍ��i�ݒu���^���j
              ,install_supp_branch_name      -- �x�X���i�ݒu���^���j
              ,install_supp_bk_acct_type     -- ������ʁi�ݒu���^���j
              ,install_supp_bk_acct_number   -- �����ԍ��i�ݒu���^���j
              ,install_supp_bk_acct_name_alt -- �������`�J�i�i�ݒu���^���j
              ,install_supp_bk_acct_name     -- �������`�����i�ݒu���^���j
              ,install_supp_org_addr         -- ���s�������Z���i�ݒu���^���j
              ,install_supp_org_name         -- ���s���������i�ݒu���^���j
              ,install_supp_org_boss_pos     -- ���s���������E�ʖ��i�ݒu���^���j
              ,install_supp_org_boss         -- ���s�����������i�ݒu���^���j
              ,install_supp_preamble         -- �O���i�ݒu���^���j
              ,intro_chg_amt                 -- �Љ�萔��
              ,intro_chg_payment_date        -- �x�������i�Љ�萔���j
              ,intro_chg_closing_date        -- �����i�Љ�萔���j
              ,intro_chg_trans_month         -- �U�����i�Љ�萔���j
              ,intro_chg_trans_date          -- �U�����i�Љ�萔���j
              ,intro_chg_trans_name          -- �_���ȊO���i�Љ�萔���j
              ,intro_chg_trans_name_alt      -- �_���ȊO���J�i�i�Љ�萔���j
              ,intro_chg_bk_chg_bearer       -- �U���萔�����S�i�Љ�萔���j
              ,intro_chg_bk_number           -- ��s�ԍ��i�Љ�萔���j
              ,intro_chg_bk_name             -- ���Z�@�֖��i�Љ�萔���j
              ,intro_chg_branch_number       -- �x�X�ԍ��i�Љ�萔���j
              ,intro_chg_branch_name         -- �x�X���i�Љ�萔���j
              ,intro_chg_bk_acct_type        -- ������ʁi�Љ�萔���j
              ,intro_chg_bk_acct_number      -- �����ԍ��i�Љ�萔���j
              ,intro_chg_bk_acct_name_alt    -- �������`�J�i�i�Љ�萔���j
              ,intro_chg_bk_acct_name        -- �������`�����i�Љ�萔���j
              ,intro_chg_org_addr            -- ���s�������Z���i�Љ�萔���j
              ,intro_chg_org_name            -- ���s���������i�Љ�萔���j
              ,intro_chg_org_boss_pos        -- ���s���������E�ʖ��i�Љ�萔���j
              ,intro_chg_org_boss            -- ���s�����������i�Љ�萔���j
              ,intro_chg_preamble            -- �O���i�Љ�萔���j
              ,electric_amt                  -- �d�C��
              ,electric_closing_date         -- �����i�d�C��j
              ,electric_trans_month          -- �U�����i�d�C��j
              ,electric_trans_date           -- �U�����i�d�C��j
              ,electric_trans_name           -- �_���ȊO���i�d�C��j
              ,electric_trans_name_alt       -- �_���ȊO���J�i�i�d�C��j
              ,electric_bk_chg_bearer        -- �U���萔�����S�i�d�C��j
              ,electric_bk_number            -- ��s�ԍ��i�d�C��j
              ,electric_bk_name              -- ���Z�@�֖��i�d�C��j
              ,electric_branch_number        -- �x�X�ԍ��i�d�C��j
              ,electric_branch_name          -- �x�X���i�d�C��j
              ,electric_bk_acct_type         -- ������ʁi�d�C��j
              ,electric_bk_acct_number       -- �����ԍ��i�d�C��j
              ,electric_bk_acct_name_alt     -- �������`�J�i�i�d�C��j
              ,electric_bk_acct_name         -- �������`�����i�d�C��j
              ,electric_org_addr             -- ���s�������Z���i�d�C��j
              ,electric_org_name             -- ���s���������i�d�C��j
              ,electric_org_boss_pos         -- ���s���������E�ʖ��i�d�C��j
              ,electric_org_boss             -- ���s�����������i�d�C��j
              ,electric_preamble             -- �O���i�d�C��j
              ,created_by                    -- �쐬��
              ,creation_date                 -- �쐬��
              ,last_updated_by               -- �ŏI�X�V��
              ,last_update_date              -- �ŏI�X�V��
              ,last_update_login             -- �ŏI�X�V���O�C��
              ,request_id                    -- �v��ID
              ,program_application_id        -- �R���J�����g�v���O�����A�v���P�[�V����ID
              ,program_id                    -- �R���J�����g�v���O����ID
              ,program_update_date           -- �v���O�����X�V��
--  Ver1.18 T.Okuyama Add Start
              ,invoice_t_no                  -- �o�^�ԍ��i���s���j
--  Ver1.18 T.Okuyama Add End
      ) VALUES (
               i_rep_memo_data_rec.contract_number               -- �_�񏑔ԍ�
              ,i_rep_memo_data_rec.contract_other_custs_id       -- �_���ȊOID
              ,i_rep_memo_data_rec.contract_name                 -- �_��Җ�
              ,i_rep_memo_data_rec.contract_effect_date          -- �_�񏑔�����
              ,i_rep_memo_data_rec.install_name                  -- �ݒu�於
              ,i_rep_memo_data_rec.install_address               -- �ݒu��Z��
              ,i_rep_memo_data_rec.tax_type_name                 -- �ŋ敪��
              ,i_rep_memo_data_rec.install_supp_amt              -- �ݒu���^��
              ,i_rep_memo_data_rec.install_supp_payment_date     -- �x�������i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_chg_bearer    -- �U���萔�����S�i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_number        -- ��s�ԍ��i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_name          -- ���Z�@�֖��i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_branch_number    -- �x�X�ԍ��i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_branch_name      -- �x�X���i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_acct_type     -- ������ʁi�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_acct_number   -- �����ԍ��i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_acct_name_alt -- �������`�J�i�i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_bk_acct_name     -- �������`�����i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_org_addr         -- ���s�������Z���i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_org_name         -- ���s���������i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_org_boss_pos     -- ���s���������E�ʖ��i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_org_boss         -- ���s�����������i�ݒu���^���j
              ,i_rep_memo_data_rec.install_supp_preamble         -- �O���i�ݒu���^���j
              ,i_rep_memo_data_rec.intro_chg_amt                 -- �Љ�萔��
              ,i_rep_memo_data_rec.intro_chg_payment_date        -- �x�������i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_closing_date        -- �����i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_trans_month         -- �U�����i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_trans_date          -- �U�����i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_trans_name          -- �_���ȊO���i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_trans_name_alt      -- �_���ȊO���J�i�i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_chg_bearer       -- �U���萔�����S�i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_number           -- ��s�ԍ��i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_name             -- ���Z�@�֖��i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_branch_number       -- �x�X�ԍ��i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_branch_name         -- �x�X���i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_acct_type        -- ������ʁi�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_acct_number      -- �����ԍ��i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_acct_name_alt    -- �������`�J�i�i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_bk_acct_name        -- �������`�����i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_org_addr            -- ���s�������Z���i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_org_name            -- ���s���������i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_org_boss_pos        -- ���s���������E�ʖ��i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_org_boss            -- ���s�����������i�Љ�萔���j
              ,i_rep_memo_data_rec.intro_chg_preamble            -- �O���i�Љ�萔���j
              ,i_rep_memo_data_rec.electric_amt                  -- �d�C��
              ,i_rep_memo_data_rec.electric_closing_date         -- �����i�d�C��j
              ,i_rep_memo_data_rec.electric_trans_month          -- �U�����i�d�C��j
              ,i_rep_memo_data_rec.electric_trans_date           -- �U�����i�d�C��j
              ,i_rep_memo_data_rec.electric_trans_name           -- �_���ȊO���i�d�C��j
              ,i_rep_memo_data_rec.electric_trans_name_alt       -- �_���ȊO���J�i�i�d�C��j
              ,i_rep_memo_data_rec.electric_bk_chg_bearer        -- �U���萔�����S�i�d�C��j
              ,i_rep_memo_data_rec.electric_bk_number            -- ��s�ԍ��i�d�C��j
              ,i_rep_memo_data_rec.electric_bk_name              -- ���Z�@�֖��i�d�C��j
              ,i_rep_memo_data_rec.electric_branch_number        -- �x�X�ԍ��i�d�C��j
              ,i_rep_memo_data_rec.electric_branch_name          -- �x�X���i�d�C��j
              ,i_rep_memo_data_rec.electric_bk_acct_type         -- ������ʁi�d�C��j
              ,i_rep_memo_data_rec.electric_bk_acct_number       -- �����ԍ��i�d�C��j
              ,i_rep_memo_data_rec.electric_bk_acct_name_alt     -- �������`�J�i�i�d�C��j
              ,i_rep_memo_data_rec.electric_bk_acct_name         -- �������`�����i�d�C��j
              ,i_rep_memo_data_rec.electric_org_addr             -- ���s�������Z���i�d�C��j
              ,i_rep_memo_data_rec.electric_org_name             -- ���s���������i�d�C��j
              ,i_rep_memo_data_rec.electric_org_boss_pos         -- ���s���������E�ʖ��i�d�C��j
              ,i_rep_memo_data_rec.electric_org_boss             -- ���s�����������i�d�C��j
              ,i_rep_memo_data_rec.electric_preamble             -- �O���i�d�C��j
              ,cn_created_by                                     -- �쐬��
              ,cd_creation_date                                  -- �쐬��
              ,cn_last_updated_by                                -- �ŏI�X�V��
              ,cd_last_update_date                               -- �ŏI�X�V��
              ,cn_last_update_login                              -- �ŏI�X�V���O�C��
              ,cn_request_id                                     -- �v��ID
              ,cn_program_application_id                         -- �R���J�����g�v���O�����A�v���P�[�V����ID
              ,cn_program_id                                     -- �R���J�����g�v���O����ID
              ,cd_program_update_date                            -- �v���O�����X�V��
--  Ver1.18 T.Okuyama Add Start
              ,gv_t_number                                       -- �o�^�ԍ��i���s���j
--  Ver1.18 T.Okuyama Add End
      );
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�o���f�[�^�����[�N�e�[�u���ɓo�^���܂����B'
      );
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_07                     --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_memo_tbl_nm                       --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                 ,iv_token_name3  => cv_tkn_contract_num                  --�g�[�N���R�[�h3
                 ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --�g�[�N���l3
                 ,iv_token_name4  => cv_tkn_request_id                    --�g�[�N���R�[�h3
                 ,iv_token_value4 => cn_request_id                        --�g�[�N���l3
                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  EXCEPTION
--
    -- *** ������O�n���h�� ***
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_data;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N��(A-4)
   ***********************************************************************************/
  PROCEDURE act_svf(
     iv_svf_form_nm         IN  VARCHAR2                 -- �t�H�[���l���t�@�C����
    ,iv_svf_query_nm        IN  VARCHAR2                 -- �N�G���[�l���t�@�C����
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'act_svf';     -- �v���O������
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
    cv_tkn_api_nm_svf  CONSTANT  VARCHAR2(20) := 'SVF�N��';
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- SVF�N������ 
    -- ======================
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                       || TO_CHAR (cd_creation_date, 'YYYYMMDD')
                       || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
     ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
     ,iv_file_id      => lv_file_id            -- ���[ID
     ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
     ,iv_frm_file     => iv_svf_form_nm        -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => iv_svf_query_nm       -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
     ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
     );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_06        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_api_nm           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --�g�[�N���l1
                );
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--      lv_errbuf := lv_errmsg || SQLERRM;
--      RAISE global_api_expt;
--    END IF;
--
--      -- ���O�o��
--      fnd_file.put_line(
--         which  => FND_FILE.LOG
--        ,buff   => '' || CHR(10) || '�����̔��@�ݒu�_��PDF���o�͂��܂����B'
--      );
      lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      -- ���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      gv_retcode := cv_status_error;
    ELSE
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '�����̔��@�ݒu�_��PDF���o�͂��܂����B'
      );
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END act_svf;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
--
  /**********************************************************************************
   * Procedure Name   : exec_submit_req
   * Description      : �o���o�͗v�����s����(A-5)
   ***********************************************************************************/
  PROCEDURE exec_submit_req(
    iv_report_type              IN  VARCHAR2, -- ���[�敪
    iv_conc_description         IN  VARCHAR2, -- �R���J�����g�E�v
    iv_contract_number          IN  VARCHAR2, -- �_�񏑔ԍ�
    in_req_cnt                  IN  NUMBER,   -- �v�����s��
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_submit_req'; -- �v���O������
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_momo_conc  CONSTANT VARCHAR2(8)   := '�o���o��';        -- �G���[���b�Z�[�W�g�[�N��
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
    -- �R���J�����g���s
    --==============================================================
    g_org_request(in_req_cnt).request_id := fnd_request.submit_request(
                                               application => cv_app_name            -- �A�v���P�[�V�����Z�k��
                                              ,program     => cv_xxcso010a06         -- �R���J�����g�v���O������
                                              ,description => iv_conc_description    -- �E�v
                                              ,start_time  => NULL                   -- �J�n����
                                              ,sub_request => FALSE                  -- �T�u�v��
                                              ,argument1   => iv_report_type         -- ���[�敪
                                              ,argument2   => iv_contract_number     -- �_�񏑔ԍ�
                                              ,argument3   => TO_CHAR(cn_request_id) -- ���s���v��ID
                      );
    -- ����ȊO�̏ꍇ
    IF ( g_org_request(in_req_cnt).request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name        -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_19   -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_conc        -- �g�[�N���R�[�h�P
                     , iv_token_value1 => cv_momo_conc       -- �o���o��
                     , iv_token_name2  => cv_tkn_concmsg     -- �g�[�N���R�[�h�Q
                     , iv_token_value2 => TO_CHAR(g_org_request(in_req_cnt).request_id) -- �߂�l
                   );
      lv_errbuf := lv_errmsg;
      -- ���O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000)
      );
      --�P�s���s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- �e�R���J�����g�p���^�[���R�[�h
      gv_retcode := cv_status_error;
    END IF;
--
    -- �R�~�b�g���s
    COMMIT;
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
  END exec_submit_req;
--
  /**********************************************************************************
   * Procedure Name   : func_wait_for_request
   * Description      : �R���J�����g�I���ҋ@����(A-6)
   ***********************************************************************************/
  PROCEDURE func_wait_for_request(
    ig_org_request_id           IN  g_org_request_ttype,   -- �v��ID
    ov_errbuf                   OUT VARCHAR2,              -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2,              -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2)              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'func_wait_for_request'; -- �v���O������
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_momo_conc  CONSTANT VARCHAR2(8)   := '�o���o��';              -- �G���[���b�Z�[�W�g�[�N��
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
    lb_wait_request           BOOLEAN        DEFAULT TRUE;
    lv_phase                  VARCHAR2(50)   DEFAULT NULL;
    lv_status                 VARCHAR2(50)   DEFAULT NULL;
    lv_dev_phase              VARCHAR2(50)   DEFAULT NULL;
    lv_dev_status             VARCHAR2(50)   DEFAULT NULL;
    lv_message                VARCHAR2(5000) DEFAULT NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    <<wait_req>>
    FOR i IN ig_org_request_id.FIRST..ig_org_request_id.LAST LOOP
      -- ����ɔ��s�ł������̂̂�
      IF ( ig_org_request_id(i).request_id <> 0 ) THEN
        --==============================================================
        -- �R���J�����g�v���ҋ@
        --==============================================================
        lb_wait_request := fnd_concurrent.wait_for_request(
                              request_id => ig_org_request_id(i).request_id -- �v��ID
                             ,interval   => gn_interval                     -- �R���J�����g�Ď��Ԋu
                             ,max_wait   => gn_max_wait                     -- �R���J�����g�Ď��ő厞��
                             ,phase      => lv_phase                        -- �v���t�F�[�Y
                             ,status     => lv_status                       -- �v���X�e�[�^�X
                             ,dev_phase  => lv_dev_phase                    -- �v���t�F�[�Y�R�[�h
                             ,dev_status => lv_dev_status                   -- �v���X�e�[�^�X�R�[�h
                             ,message    => lv_message                      -- �������b�Z�[�W
                           );
        -- �߂�l��FALSE�̏ꍇ
        IF ( lb_wait_request = FALSE ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_tkn_number_20
                         ,iv_token_name1  => cv_tkn_conc
                         ,iv_token_value1 => cv_momo_conc
                         ,iv_token_name2  => cv_tkn_request_id
                         ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                       );
          lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
          -- �e�R���J�����g�p���^�[���R�[�h
          gv_retcode := cv_status_error;
        ELSE
          -- ����I�����b�Z�[�W�o��
          IF ( lv_dev_status = cv_dev_status_normal ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_tkn_number_21
                           ,iv_token_name1  => cv_tkn_conc
                           ,iv_token_value1 => cv_momo_conc
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
          -- �x���I�����b�Z�[�W�o��
          ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_tkn_number_22
                           ,iv_token_name1  => cv_tkn_conc
                           ,iv_token_value1 => cv_momo_conc
                           ,iv_token_name2  => cv_tkn_request_id
                           ,iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := lv_errmsg;
            -- �e�R���J�����g�p���^�[���R�[�h�i���ɃG���[�̏ꍇ�͂��̂܂܁j
            IF ( gv_retcode = cv_status_normal ) THEN
              gv_retcode := cv_status_warn;
            END IF;
          -- �G���[�I�����b�Z�[�W�o��
          ELSE
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name
                           , iv_name         => cv_tkn_number_23
                           , iv_token_name1  => cv_tkn_conc
                           , iv_token_value1 => cv_momo_conc
                           , iv_token_name2  => cv_tkn_request_id
                           , iv_token_value2 => TO_CHAR(ig_org_request_id(i).request_id)
                         );
            lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
            -- �e�R���J�����g�p���^�[���R�[�h
            gv_retcode := cv_status_error;
          END IF;
        END IF;
        -- ���O�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf
        );
        --�P�s���s
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
      END IF;
    END LOOP wait_req;
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
  END func_wait_for_request;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_data(
     i_rep_cont_data_rec    IN         g_rep_cont_data_rtype  -- �_�񏑃f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ,i_rep_memo_data_rec    IN         g_rep_memo_data_rtype  -- �o���f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    ,ov_errbuf              OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'delete_data';     -- �v���O������
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
    cv_tbl_nm         CONSTANT VARCHAR2(100) := '�����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    cv_memo_tbl_nm    CONSTANT VARCHAR2(100) := '�o�����[���[�N�e�[�u��';
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    -- *** ���[�J���ϐ� ***
    lt_con_mng_id         xxcso_contract_managements.contract_management_id%TYPE;      -- �����̔��@�ݒu�_��ID
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    lt_reqest_id          xxcso_rep_memorandum.request_id%TYPE;                        -- �v��ID�i���b�N�p�_�~�[�j
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==========================
    -- ���b�N�̊m�F
    -- ==========================
    BEGIN
--
      SELECT xrasc.request_id  request_id
      INTO   lt_con_mng_id
      FROM   xxcso_rep_auto_sale_cont xrasc         -- �����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��
      WHERE  xrasc.request_id = cn_request_id
        AND  ROWNUM = 1
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_11        --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl              --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tbl_nm               --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg          --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ==========================
    -- ���[�N�e�[�u���f�[�^�폜
    -- ==========================
    BEGIN
--
      DELETE FROM xxcso_rep_auto_sale_cont xrasc -- �����̔��@�ݒu�_�񏑒��[���[�N�e�[�u��
      WHERE xrasc.request_id = cn_request_id;
--
      -- ���O�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '���[�N�e�[�u���̌_�񏑃f�[�^���폜���܂����B'
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_08                     --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_tbl_nm                            --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                   ,iv_token_name3  => cv_tkn_contract_num                  --�g�[�N���R�[�h3
                   ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --�g�[�N���l3
                   ,iv_token_name4  => cv_tkn_request_id                    --�g�[�N���R�[�h3
                   ,iv_token_value4 => cn_request_id                        --�g�[�N���l3
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- ==========================
    -- �o�����[���[�N�e�[�u�� ���b�N�̊m�F
    -- ==========================
    BEGIN
      SELECT xrm.request_id  request_id
      INTO   lt_reqest_id
      FROM   xxcso_rep_memorandum xrm                                       -- �o�����[���[�N�e�[�u��
      WHERE  xrm.request_id = cn_request_id
      AND    ROWNUM = 1
      FOR UPDATE NOWAIT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_11                     --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_memo_tbl_nm                       --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ==========================
    -- �o�����[���[�N�e�[�u���f�[�^ �폜
    -- ==========================
    BEGIN
      DELETE FROM xxcso_rep_memorandum xrm                                  -- �o�����[���[�N�e�[�u��
      WHERE xrm.request_id = cn_request_id;
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '' || CHR(10) || '���[�N�e�[�u���̊o���f�[�^���폜���܂����B'
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name                          --�A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_tkn_number_08                     --���b�Z�[�W�R�[�h
                   ,iv_token_name1  => cv_tkn_tbl                           --�g�[�N���R�[�h1
                   ,iv_token_value1 => cv_memo_tbl_nm                       --�g�[�N���l1
                   ,iv_token_name2  => cv_tkn_err_msg                       --�g�[�N���R�[�h2
                   ,iv_token_value2 => SQLERRM                              --�g�[�N���l2
                   ,iv_token_name3  => cv_tkn_contract_num                  --�g�[�N���R�[�h3
                   ,iv_token_value3 => i_rep_cont_data_rec.contract_number  --�g�[�N���l3
                   ,iv_token_name4  => cv_tkn_request_id                    --�g�[�N���R�[�h3
                   ,iv_token_value4 => cn_request_id                        --�g�[�N���l3
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
  EXCEPTION
--
    -- *** ������O�n���h�� ***
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
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
    cv_status_0           CONSTANT VARCHAR2(1) := '0';  -- �쐬��
    cv_status_1           CONSTANT VARCHAR2(1) := '1';  -- �m���
    cv_cooperate_flag_0   CONSTANT VARCHAR2(1) := '0';  -- ���A�g
    cv_cooperate_flag_1   CONSTANT VARCHAR2(1) := '1';  -- �A�g��
--
    -- *** ���[�J���ϐ� ***
    lv_process_flag       VARCHAR2(1);                                     -- �����t���O
    lt_status             xxcso_contract_managements.status%TYPE;          -- �X�e�[�^�X
    lt_cooperate_flag     xxcso_contract_managements.cooperate_flag%TYPE;  -- �}�X�^�A�g�t���O
    lv_svf_form_nm        VARCHAR2(20);                                    -- �t�H�[���l���t�@�C����
    lv_svf_query_nm       VARCHAR2(20);                                    -- �N�G���[�l���t�@�C����
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf         VARCHAR2(5000);                                  -- �G���[�E���b�Z�[�W
    lv_retcode_svf        VARCHAR2(1);                                     -- ���^�[���E�R�[�h
    lv_errmsg_svf         VARCHAR2(5000);                                  -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver1.16  K.Kanada Add S
    lv_msg_layout_ptn     VARCHAR2(200);                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
-- Ver1.16  K.Kanada Add E
--
    -- *** ���[�J���E���R�[�h ***
    l_rep_cont_data_rec   g_rep_cont_data_rtype;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    l_rep_memo_data_rec   g_rep_memo_data_rtype;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
    -- *** ���[�J����O ***
    init_expt   EXCEPTION;  -- ����������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�E���^�̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- �o�����[�֘A�ϐ�������
    gn_req_cnt    := 0;
    gv_memo_inst  := NULL;
    gv_memo_intro := NULL;
    gv_memo_elec  := NULL;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD END   */
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
      ot_status         => lt_status           -- �X�e�[�^�X
     ,ot_cooperate_flag => lt_cooperate_flag   -- �}�X�^�A�g�t���O
     ,ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg         => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE init_expt;
    END IF;
    -- �������������̏ꍇ�A�Ώی����J�E���g
    gn_target_cnt := gn_target_cnt + 1;
--
    -- ==============================================================================================
    -- �����t���O = 1 �X�e�[�^�X���쐬���̏ꍇ�A�܂��̓X�e�[�^�X���m��ρA���}�X�^�A�g�t���O�����A�g�̏ꍇ
    -- �����t���O = 2 �X�e�[�^�X���X�e�[�^�X���m��ρA���}�X�^�A�g�t���O���A�g�ς̏ꍇ
    --===============================================================================================
    IF ((lt_status = cv_status_0)
        OR ((lt_status = cv_status_1) AND (lt_cooperate_flag = cv_cooperate_flag_0))) THEN
      lv_process_flag := cv_flag_1;
    ELSIF ((lt_status = cv_status_1) AND (lt_cooperate_flag = cv_cooperate_flag_1)) THEN
      lv_process_flag := cv_flag_2;
    END IF;
--
    -- ========================================
    -- A-2.�f�[�^�擾
    -- ========================================
    get_contract_data(
      iv_process_flag     => lv_process_flag      -- �����t���O
     ,o_rep_cont_data_rec => l_rep_cont_data_rec  -- �_�񏑃f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
     ,o_rep_memo_data_rec => l_rep_memo_data_rec  -- �o���f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
     ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.���[�N�e�[�u���ɓo�^
    -- ========================================
    insert_data(
      i_rep_cont_data_rec    => l_rep_cont_data_rec    -- �_�񏑃f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
     ,i_rep_memo_data_rec    => l_rep_memo_data_rec    -- �o���f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
     ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================================================================
    -- �t�H�[���l���t�@�C�����A�N�G���[�l���t�@�C����
    -- ���[�o�̓p�^�[���i�W��ށj
    --===============================================================================================
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--      ,buff   => '' || CHR(10) || '<< ���[�o�̓p�^�[�� >>'
      ,buff   => '' || CHR(10) || '<< �����̔��@�ݒu�_�񒠕[�o�̓p�^�[�� >>'
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
    );
--
-- Ver1.16  K.Kanada Mod S
--    -- �@ �̔��萔���L��A���ݒu���^���L��A���d�C��L��A���ō��̏ꍇ�@����
--    -- �H �̔��萔���L��A���ݒu���^���L��A���d�C��L��A���ŕʂ̏ꍇ
--    IF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
--          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
----          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
--          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S01.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S01.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�@ �̔��萔���L��A���ݒu���^���L��A���d�C��L��'
--          ,buff   => '�@ �̔��萔���L��A���ݒu���^���L��A���d�C��L��A���ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
----
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S09.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S09.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�H �̔��萔���L��A���ݒu���^���L��A���d�C��L��A���ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
--    -- �A �̔��萔���L��A���ݒu���^���L��A���d�C�㖳���̏ꍇ
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
----          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
----          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
--            AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S02.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S02.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�A �̔��萔���L��A���ݒu���^���L��A���d�C�㖳��'
--          ,buff   => '�A �̔��萔���L��A���ݒu���^���L��A���d�C�㖳���A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S10.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S10.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�I �̔��萔���L��A���ݒu���^���L��A���d�C�㖳���A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    -- �B �̔��萔���L��A���ݒu���^�������A���d�C��L��̏ꍇ
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
--          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
----          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
--          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S03.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S03.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�B �̔��萔���L��A���ݒu���^�������A���d�C��L��'
--          ,buff   => '�B �̔��萔���L��A���ݒu���^�������A���d�C��L��A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S11.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S11.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�J �̔��萔���L��A���ݒu���^�������A���d�C��L��A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    -- �C �̔��萔���L��A���ݒu���^�������A���d�C�㖳���̏ꍇ
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
----          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
----          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
--          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S04.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S04.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�C �̔��萔���L��A���ݒu���^�������A���d�C�㖳��'
--          ,buff   => '�C �̔��萔���L��A���ݒu���^�������A���d�C�㖳���A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S12.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S12.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�K �̔��萔���L��A���ݒu���^�������A���d�C�㖳���A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    -- �D �̔��萔�������A���ݒu���^���L��A���d�C��L��̏ꍇ
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
--          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
----          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
--          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S05.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S05.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�D �̔��萔�������A���ݒu���^���L��A���d�C��L��'
--          ,buff   => '�D �̔��萔�������A���ݒu���^���L��A���d�C��L��A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S13.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S13.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�L �̔��萔�������A���ݒu���^���L��A���d�C��L��A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    -- �E �̔��萔�������A���ݒu���^���L��A���d�C�㖳���̏ꍇ
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
----          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)
----          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
--          AND (l_rep_cont_data_rec.install_support_amt_flag = TRUE)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S06.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S06.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�E �̔��萔�������A���ݒu���^���L��A���d�C�㖳��'
--          ,buff   => '�E �̔��萔�������A���ݒu���^���L��A���d�C�㖳���A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S14.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S14.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�M �̔��萔�������A���ݒu���^���L��A���d�C�㖳���A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    -- �F �̔��萔�������A���ݒu���^�������A���d�C��L��̏ꍇ
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
--          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
----          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)) THEN
--          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
--          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S07.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S07.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�F �̔��萔�������A���ݒu���^�������A���d�C��L��'
--          ,buff   => '�F �̔��萔�������A���ݒu���^�������A���d�C��L��A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S15.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S15.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�N �̔��萔�������A���ݒu���^�������A���d�C��L��A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    -- �G �̔��萔�������A���ݒu���^�������A���d�C�㖳���̏ꍇ
--    ELSIF ((l_rep_cont_data_rec.condition_contents_flag = FALSE)
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
----          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)
----          AND (l_rep_cont_data_rec.electricity_information_flag = FALSE)) THEN
--          AND (l_rep_cont_data_rec.install_support_amt_flag = FALSE)) THEN
--/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ō�
--      IF (l_rep_cont_data_rec.bm_tax_kbn = '1') THEN
---- 2020/08/07 Ver1.15 N.Abe ADD END
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S08.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S08.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
---- 2020/08/07 Ver1.15 N.Abe MOD START
----          ,buff   => '�G �̔��萔�������A���ݒu���^�������A���d�C�㖳��'
--          ,buff   => '�G �̔��萔�������A���ݒu���^�������A���d�C�㖳���A�ō�'
---- 2020/08/07 Ver1.15 N.Abe MOD END
--        );
---- 2020/08/07 Ver1.15 N.Abe ADD START
--      -- BM�ŋ敪�F�ŕ�
--      ELSE
--        -- �t�H�[���l���t�@�C����
--        lv_svf_form_nm  := cv_svf_name || 'S16.xml';
--        -- �N�G���[�l���t�@�C����
--        lv_svf_query_nm := cv_svf_name || 'S16.vrq';
----
--        -- ���O�o��
--        fnd_file.put_line(
--           which  => FND_FILE.LOG
--          ,buff   => '�O �̔��萔�������A���ݒu���^�������A���d�C�㖳���A�ŕ�'
--        );
--      END IF;
---- 2020/08/07 Ver1.15 N.Abe ADD END
----
--    END IF;
--
    -- �@�B �̔��萔���L��A�d�C��L�� �̏ꍇ
    IF ((l_rep_cont_data_rec.condition_contents_flag = TRUE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)) THEN
      -- BM1�ŋ敪�F�Ŕ�
      IF (l_rep_cont_data_rec.bm_tax_kbn = '2') THEN
        lv_svf_form_nm    := cv_svf_name || 'S01.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S01.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�@ �̔��萔���L��A�d�C��L��ABM1�ŋ敪�F�Ŕ�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      -- BM1�ŋ敪�F�ō���������NULL
      ELSE
        lv_svf_form_nm    := cv_svf_name || 'S03.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S03.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�B �̔��萔���L��A�d�C��L��ABM1�ŋ敪�F�ō�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      END IF;
--
    -- �A�C �̔��萔���L��A�d�C�㖳�� �̏ꍇ
    ELSIF (   (l_rep_cont_data_rec.condition_contents_flag = TRUE) ) THEN
      -- BM1�ŋ敪�F�Ŕ�
      IF (l_rep_cont_data_rec.bm_tax_kbn = '2') THEN
        lv_svf_form_nm    := cv_svf_name || 'S02.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S02.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�A �̔��萔���L��A�d�C�㖳���ABM1�ŋ敪�F�Ŕ�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      -- BM1�ŋ敪�F�ō���������NULL
      ELSE
        lv_svf_form_nm    := cv_svf_name || 'S04.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S04.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�C �̔��萔���L��A�d�C�㖳���ABM1�ŋ敪�F�ō�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      END IF;
--
    -- �D�F �̔��萔�������A�d�C��L�� �̏ꍇ
    ELSIF (   (l_rep_cont_data_rec.condition_contents_flag = FALSE)
          AND (l_rep_cont_data_rec.electricity_information_flag = TRUE)
          AND (l_rep_memo_data_rec.electric_memo_flg = cn_e_memo_cont)  ) THEN
      -- BM1�ŋ敪�F�Ŕ�
      IF (l_rep_cont_data_rec.bm_tax_kbn = '2') THEN
        lv_svf_form_nm    := cv_svf_name || 'S05.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S05.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�D �̔��萔�������A�d�C��L��ABM1�ŋ敪�F�Ŕ�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      -- BM1�ŋ敪�F�ō���������NULL
      ELSE
        lv_svf_form_nm    := cv_svf_name || 'S07.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S07.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�F �̔��萔�������A�d�C��L��ABM1�ŋ敪�F�ō�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      END IF;
--
    -- �E�G �̔��萔�������A�d�C�㖳�� �̏ꍇ
    ELSIF (   (l_rep_cont_data_rec.condition_contents_flag = FALSE) ) THEN
      -- BM1�ŋ敪�F�Ŕ�
      IF (l_rep_cont_data_rec.bm_tax_kbn = '2') THEN
        lv_svf_form_nm    := cv_svf_name || 'S06.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S06.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�E �̔��萔�������A�d�C�㖳���ABM1�ŋ敪�F�Ŕ�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      -- BM1�ŋ敪�F�ō���������NULL
      ELSE
        lv_svf_form_nm    := cv_svf_name || 'S08.xml';   -- �t�H�[���l���t�@�C����
        lv_svf_query_nm   := cv_svf_name || 'S08.vrq';   -- �N�G���[�l���t�@�C����
        lv_msg_layout_ptn := '�G �̔��萔�������A�d�C�㖳���ABM1�ŋ敪�F�ō�';  -- ���O�o�͎�<< ���[�o�̓p�^�[�� >>
      END IF;
    END IF;
--
    -- ���O�o��<< ���[�o�̓p�^�[�� >>
    fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => lv_msg_layout_ptn
    );
-- Ver1.16  K.Kanada Mod E
--
    -- ���O�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '�t�H�[���l���F' || lv_svf_form_nm || '�A�N�G���[�l���F' || lv_svf_query_nm
    );
--
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    -- �o���i�ݒu���^���j
    IF ( l_rep_memo_data_rec.install_supp_memo_flg = cn_is_memo_yes ) THEN
      gv_memo_inst  := cv_memo_inst;
    END IF;
    -- �o���i�Љ�萔���j
    IF    ( l_rep_memo_data_rec.intro_chg_memo_flg = cn_ic_memo_single ) THEN
      gv_memo_intro := cv_memo_intro_fix;
    ELSIF ( l_rep_memo_data_rec.intro_chg_memo_flg = cn_ic_memo_per_sp ) THEN
      gv_memo_intro := cv_memo_intro_price;
    ELSIF ( l_rep_memo_data_rec.intro_chg_memo_flg = cn_ic_memo_per_p ) THEN
      gv_memo_intro := cv_memo_intro_piece;
    END IF;
    -- �o���i�d�C��j
    IF    (l_rep_memo_data_rec.electric_memo_flg   = cn_e_memo_o_fix ) THEN
      gv_memo_elec := cv_memo_elec_fix;
    ELSIF (l_rep_memo_data_rec.electric_memo_flg   = cn_e_memo_o_var ) THEN
      gv_memo_elec := cv_memo_elec_change;
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    -- ========================================
    -- A-4.SVF�N��
    -- ========================================
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '<< �����̔��@�ݒu�_�񒠕[ - SVF�N�� >>'
    );
    -- �_�񏑒��[�o��
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
    act_svf(
       iv_svf_form_nm  => lv_svf_form_nm
      ,iv_svf_query_nm => lv_svf_query_nm
      ,ov_errbuf       => lv_errbuf_svf                 -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode      => lv_retcode_svf                -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg       => lv_errmsg_svf                 -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
    ------------------------------
    -- �o�����[�i�ݒu���^���j�o��
    ------------------------------
    IF ( gv_memo_inst IS NOT NULL ) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '<< �o�����[�i�ݒu���^���j - SVF�N�� >>'
      );
      gn_req_cnt := gn_req_cnt + 1;
      --�o�����s(
      exec_submit_req(
         iv_report_type       => gv_memo_inst                         --���[�敪
        ,iv_conc_description  => gv_conc_des_inst                     --�R���J�����g�E�v
        ,iv_contract_number   => l_rep_cont_data_rec.contract_number  --�_�񏑔ԍ�
        ,in_req_cnt           => gn_req_cnt                           --���s�R���J�����g��
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
    ------------------------------
    --�o�����[�i�Љ�萔���j�o��
    ------------------------------
    IF ( gv_memo_intro IS NOT NULL ) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '<< �o�����[�i�Љ�萔���j - SVF�N�� >>'
      );
      gn_req_cnt := gn_req_cnt + 1;
      --�o�����s
      exec_submit_req(
         iv_report_type       => gv_memo_intro                        -- ���[�敪
        ,iv_conc_description  => gv_conc_des_intro                    -- �R���J�����g�E�v
        ,iv_contract_number   => l_rep_cont_data_rec.contract_number  -- �_�񏑔ԍ�
        ,in_req_cnt           => gn_req_cnt                           -- ���s�R���J�����g��
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );    END IF;
    ------------------------------
    --�o�����[�i�d�C��j�o��
    ------------------------------
    IF ( gv_memo_elec IS NOT NULL ) THEN
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '<< �o�����[�i�d�C��j - SVF�N�� >>'
      );
      gn_req_cnt := gn_req_cnt + 1;
      --�o�����s(
      exec_submit_req(
         iv_report_type       => gv_memo_elec                         -- ���[�敪
        ,iv_conc_description  => gv_conc_des_electric                 -- �R���J�����g�E�v
        ,iv_contract_number   => l_rep_cont_data_rec.contract_number  -- �_�񏑔ԍ�
        ,in_req_cnt           => gn_req_cnt
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
    ------------------------------
    -- �o���o�̓R���J�����g�ҋ@
    ------------------------------
    IF ( g_org_request.COUNT <> 0 ) THEN
      --���s�����o���o�͂�ҋ@����
      func_wait_for_request(
         ig_org_request_id    => g_org_request
        ,ov_errbuf            => lv_errbuf_svf
        ,ov_retcode           => lv_retcode_svf
        ,ov_errmsg            => lv_errmsg_svf
      );
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
--
    -- ========================================
    -- A-7.���[�N�e�[�u���f�[�^�폜
    -- ========================================
    delete_data(
       i_rep_cont_data_rec  => l_rep_cont_data_rec      -- �_�񏑃f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD START */
      ,i_rep_memo_data_rec  => l_rep_memo_data_rec      -- �o���f�[�^
/* 2015/02/13 Ver1.11 K.Nakatsu ADD  END  */
      ,ov_errbuf            => lv_errbuf                -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode           => lv_retcode               -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg            => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-8.SVF�N��API�G���[�`�F�b�N
    -- ========================================
/* 2015/02/13 Ver1.11 K.Nakatsu MOD START */
--    IF (lv_retcode_svf = cv_status_error) THEN
--      lv_errmsg := lv_errmsg_svf;
--      lv_errbuf := lv_errbuf_svf;
--      RAISE global_process_expt;
--    END IF;
--
--    -- ���������J�E���g
--    gn_normal_cnt := gn_normal_cnt + 1;
    IF ( gv_retcode <> cv_status_normal ) THEN
      -- SVF�֐��̖߂�l��ݒ�
      ov_retcode := gv_retcode;
    ELSE
      -- ���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
    END IF;
/* 2015/02/13 Ver1.11 K.Nakatsu MOD  END  */
--
  EXCEPTION
    -- *** ����������O�n���h�� ***
    WHEN init_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ��������O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf               OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode              OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
    ,in_contract_mng_id   IN         NUMBER      -- �����̔��@�ݒu�_��ID
  )
--
-- ###########################  �Œ蕔 START   ###########################
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
-- ###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  �Œ蕔 END   #############################
--
    -- *** ���̓p�����[�^���Z�b�g(�����̔��@�ݒu�_��ID)
    gt_con_mng_id := in_contract_mng_id;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
--       fnd_file.put_line(
--          which  => FND_FILE.LOG
--         ,buff   => '' || CHR(10) ||lv_errmsg                  -- ���[�U�[�E�G���[���b�Z�[�W
--       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => '' || CHR(10)
                   ||cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf    -- �G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-9.�I������ 
    -- =======================
    -- ��s�̏o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''               -- ��s
    );
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO010A04C;
/
